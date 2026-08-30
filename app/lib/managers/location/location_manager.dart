import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// What the device has for a GPS receiver, from the native
/// `LocationSensor.kt` bridge: whether there is one, and why not when there
/// is none.
///
/// Unknown counts as supported: a missing answer (no bridge, as in tests)
/// must never switch a feature off on a device that has the receiver.
class LocationSupport {
  const LocationSupport({required this.supported, this.hint});

  static const unknown = LocationSupport(supported: true);

  final bool supported;

  /// Why [supported] is false, in a sentence fit for a settings row.
  final String? hint;

  Map<String, Object?> toJson() => {
    'supported': supported,
    if (hint != null) 'hint': hint,
  };
}

/// One GPS fix, as the receiver reported it.
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.time,
    this.accuracy,
    this.altitude,
    this.speed,
  });

  final double latitude;
  final double longitude;
  final DateTime time;
  final double? accuracy;
  final double? altitude;
  final double? speed;

  /// A fix from the native map, or the persisted one; null for a map with
  /// no coordinates in it.
  static LocationFix? fromMap(Map<Object?, Object?>? raw) {
    if (raw == null) return null;
    final lat = raw['latitude'];
    final lon = raw['longitude'];
    if (lat is! num || lon is! num) return null;
    final time = raw['time'];
    return LocationFix(
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      time: time is num
          ? DateTime.fromMillisecondsSinceEpoch(time.toInt(), isUtc: true)
          : DateTime.now().toUtc(),
      accuracy: (raw['accuracy'] as num?)?.toDouble(),
      altitude: (raw['altitude'] as num?)?.toDouble(),
      speed: (raw['speed'] as num?)?.toDouble(),
    );
  }

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'time': time.millisecondsSinceEpoch,
    if (accuracy != null) 'accuracy': accuracy,
    if (altitude != null) 'altitude': altitude,
    if (speed != null) 'speed': speed,
  };

  LocationChanged toEvent() => LocationChanged(
    latitude: latitude,
    longitude: longitude,
    time: time,
    accuracy: accuracy,
    altitude: altitude,
    speed: speed,
  );
}

/// The device's GPS position for Home Assistant (issue #363): a tablet
/// that travels, in an RV say, is the one receiver that is always on and
/// always in the vehicle.
///
/// Watches the receiver only while Report location is on, under an ESPHome
/// server that serves entities, since those sensors are the only consumer.
/// Each fix is published as [LocationChanged] for the ESPHome surface and
/// kept as [last], persisted so the sensors have a position right after a
/// restart rather than after the first cold fix.
///
/// Where the device has no receiver, the switch is kept off in the setting
/// itself (at boot and whenever something turns it on: the remote API, a
/// settings import), so every reader of the switch agrees, and both
/// settings pages render it disabled with the reason. A missing location
/// grant does not switch anything off: the stream fails, the reason shows
/// under the switch, and the manager tries again every minute so the grant
/// landing on the permission row is all it takes.
class LocationManager extends Manager {
  LocationManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    this.retryInterval = const Duration(minutes: 1),
  });

  final SettingsManager _settings;

  /// How long after a failed start the next attempt waits. Injectable for
  /// tests only.
  final Duration retryInterval;

  static const _methods = MethodChannel('kiosk_satellite/location');
  static const _stream = EventChannel('kiosk_satellite/location_stream');

  /// Where the last fix lives between runs.
  static const _lastFixKey = 'esphome_last_location';

  @override
  String get name => 'location';

  LocationSupport? _support;

  bool get locationKnownUnsupported => _support?.supported == false;

  /// Why the switch is disabled, once known.
  String? get locationHint => _support?.hint;

  /// Whether fixes should be flowing right now.
  bool get enabled =>
      _settings.get(defs.esphomeEnabled) &&
      _settings.get(defs.esphomeEntities) &&
      _settings.get(defs.locationEnabled) &&
      !locationKnownUnsupported;

  /// The most recent fix, from this run or the last one; null before the
  /// first ever.
  LocationFix? get last => _last;
  LocationFix? _last;

  /// Whether the receiver is being watched.
  bool get streaming => _sub != null;

  /// Why the receiver is not being watched while it should be, null while
  /// it is or while nothing wants it.
  String? get error => _error;
  String? _error;

  StreamSubscription<Object?>? _sub;
  Timer? _retry;

  @override
  Future<void> init() async {
    _last = LocationFix.fromMap(_readPersisted());
    bus.on<SettingChanged>().listen((e) {
      if (e.key != defs.locationEnabled.key &&
          e.key != defs.locationInterval.key &&
          e.key != defs.esphomeEnabled.key &&
          e.key != defs.esphomeEntities.key) {
        return;
      }
      // The switch turned on where there is no receiver (the settings
      // page never offers it, but the remote API and a settings import
      // can): back off, and the write lands here again as false.
      if (e.key == defs.locationEnabled.key &&
          locationKnownUnsupported &&
          _settings.get(defs.locationEnabled)) {
        unawaited(_guardSupport());
        return;
      }
      // A new interval means a new request to the receiver.
      if (e.key == defs.locationInterval.key) _stop();
      _sync();
    });

    commands.register(
      Command(
        name: 'getLocationSupport',
        description:
            'Whether the device has a GPS receiver, and why not when it '
            'has none',
        handler: (_) async =>
            CommandResult.ok((await locationSupport()).toJson()),
      ),
    );
    commands.register(
      Command(
        name: 'getLocation',
        description:
            'The last GPS fix, whether fixes are being read, and why not '
            'when they are not',
        handler: (_) async => CommandResult.ok(status()),
      ),
    );

    await _guardSupport();
    _sync();
  }

  /// The native answer, asked once. A failed or missing ask is not cached,
  /// so a bridge that was not ready gets asked again.
  Future<LocationSupport> locationSupport() async {
    if (_support case final known?) return known;
    try {
      final raw = await _methods.invokeMethod<Map<Object?, Object?>>('support');
      if (raw == null) return LocationSupport.unknown;
      return _support = LocationSupport(
        supported: raw['supported'] != false,
        hint: raw['hint'] as String?,
      );
    } catch (_) {
      return LocationSupport.unknown;
    }
  }

  /// What the settings pages show under the switch.
  Map<String, Object?> status() => {
    'enabled': enabled,
    'streaming': streaming,
    if (_error != null) 'error': _error,
    if (_last != null) 'fix': _last!.toJson(),
  };

  /// Re-checks whether the receiver should be watched: the permission rows
  /// call it after a grant so a stream refused for the missing grant comes
  /// up without waiting for the retry.
  void sync() => _sync();

  /// Keeps the switch off where there is no receiver: at boot, and whenever
  /// something turns it on.
  Future<void> _guardSupport() async {
    final support = await locationSupport();
    if (support.supported || !_settings.get(defs.locationEnabled)) return;
    await _settings.set(defs.locationEnabled, false);
    final why = support.hint ?? 'Not available on this device.';
    log.warn(
      name,
      'Report location kept off: ${why[0].toLowerCase()}${why.substring(1)}',
    );
  }

  Map<Object?, Object?>? _readPersisted() {
    final raw = _settings.internal(_lastFixKey);
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  void _sync() {
    if (!enabled) {
      _stop();
      _error = null;
      return;
    }
    _start();
  }

  Future<void> _start() async {
    if (_sub != null) return;
    _retry?.cancel();
    _retry = null;
    final interval = _settings.get(defs.locationInterval).toInt();
    log.info(name, 'reading GPS fixes every ${interval}s');
    _sub = _stream
        .receiveBroadcastStream({'intervalMs': interval * 1000})
        .listen(
          (raw) {
            final fix = LocationFix.fromMap(raw is Map ? raw : null);
            if (fix == null) return;
            _error = null;
            _accept(fix);
          },
          onError: (Object e) {
            final code = e is PlatformException ? e.code : '';
            _error = switch (code) {
              'denied' => 'Location permission not granted.',
              'absent' => 'No GPS receiver.',
              _ =>
                'GPS unavailable: ${e is PlatformException ? e.message ?? code : e}',
            };
            log.warn(name, 'GPS stream failed: $_error');
            _stop();
            _retry = Timer(retryInterval, _sync);
          },
        );
    // The receiver's last fix, so the sensors read a position before the
    // first cold fix of this run, which can take minutes.
    try {
      final seed = LocationFix.fromMap(
        await _methods.invokeMethod<Map<Object?, Object?>>('last'),
      );
      if (seed != null && (_last == null || seed.time.isAfter(_last!.time))) {
        _accept(seed);
      }
    } catch (_) {}
  }

  void _accept(LocationFix fix) {
    _last = fix;
    unawaited(_settings.setInternal(_lastFixKey, jsonEncode(fix.toJson())));
    log.debug(
      name,
      'fix ${fix.latitude.toStringAsFixed(5)}, '
      '${fix.longitude.toStringAsFixed(5)}'
      '${fix.accuracy == null ? '' : ' (±${fix.accuracy!.round()} m)'}',
    );
    bus.publish(fix.toEvent());
  }

  void _stop() {
    _retry?.cancel();
    _retry = null;
    if (_sub == null) return;
    unawaited(_sub!.cancel());
    _sub = null;
    log.info(name, 'GPS off');
  }

  @override
  Future<void> dispose() async {
    _stop();
  }
}
