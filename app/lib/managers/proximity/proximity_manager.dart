import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// What the device has for a proximity sensor, from the native
/// `ProximitySensor.kt` bridge: whether there is one, its name and maker
/// (shown under the switch, because the name is what tells a hover sensor
/// from a phone's call-only "palm" sensor), and why not when there is
/// none.
///
/// Unknown counts as supported: a missing answer (no bridge, as in tests)
/// must never switch a feature off on a device that has the sensor.
class ProximitySupport {
  const ProximitySupport({
    required this.supported,
    this.name,
    this.vendor,
    this.hint,
  });

  static const unknown = ProximitySupport(supported: true);

  final bool supported;

  /// The sensor's name as Android reports it ("Palm Proximity Sensor
  /// version 2", "STK3310 Proximity"), null while unknown.
  final String? name;

  /// The sensor's maker, null while unknown.
  final String? vendor;

  /// Why [supported] is false, in a sentence fit for a settings row.
  final String? hint;

  Map<String, Object?> toJson() => {
    'supported': supported,
    if (name != null) 'name': name,
    if (vendor != null) 'vendor': vendor,
    if (hint != null) 'hint': hint,
  };
}

/// Proximity-sensor detection for the screensaver: Motion Detection's two
/// legs on the device's proximity sensor instead of the camera.
///
/// "Dismiss on proximity" watches the sensor while the screensaver is
/// showing and publishes [ProximityDetected] when something comes close,
/// which the screensaver consumes to wake. "Postpone screensaver on
/// proximity" extends it the way the camera's postpone leg does: the
/// sensor is also watched between screensavers, with the screen on, so
/// someone standing at the panel keeps resetting the idle timer. The
/// sensor costs nothing worth gating, so the only gates are the switches,
/// the screensaver being enabled at all for the postpone leg, and the
/// screen being on (a dark panel has no screensaver to postpone).
///
/// The native side reports near/far transitions, with the resting state
/// at registration flagged so it is never taken for an approach. A near
/// that holds (someone standing there) republishes every few seconds so
/// the postpone leg keeps holding the screensaver off.
///
/// Where the device has no sensor, the switch is kept off in the setting
/// itself (at boot and whenever something turns it on: the remote API, a
/// settings import), so every reader of the switch agrees, and both
/// settings pages render it disabled with the reason.
class ProximityManager extends Manager {
  ProximityManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    this.holdInterval = const Duration(seconds: 5),
  });

  final SettingsManager _settings;

  /// How often a held near republishes. Injectable for tests only.
  final Duration holdInterval;

  static const _methods = MethodChannel('kiosk_satellite/proximity_sensor');
  static const _stream = EventChannel(
    'kiosk_satellite/proximity_sensor_stream',
  );

  @override
  String get name => 'proximity';

  /// The native answer, null until the bridge has answered; the sync
  /// getters below are for UI code and read as supported until then, so a
  /// row is never disabled on a guess.
  ProximitySupport? _support;

  bool get proximityKnownUnsupported => _support?.supported == false;

  /// The sensor's name, once known and where there is one.
  String? get sensorName => _support?.name;

  /// The sensor's maker, once known and where there is one.
  String? get sensorVendor => _support?.vendor;

  /// Why the switch is disabled, once known.
  String? get proximityHint => _support?.hint;

  /// The active schedule entry's override (issue #437): true/false wins
  /// over the switch for the entry's hours, null between sessions and for
  /// entries without one.
  bool? _schedulePolicy;

  /// The dismiss leg's gate: the switch (or the schedule's override of
  /// it), on a device with a sensor.
  bool get enabled =>
      (_schedulePolicy ?? _settings.get(defs.screensaverDismissOnProximity)) &&
      !proximityKnownUnsupported;

  /// The postpone leg's gate: rides on Dismiss on proximity (the postpone
  /// switch is an extension of it, hidden and inert without it), on a
  /// device whose screensaver can start at all.
  bool get _postponeEnabled =>
      enabled &&
      _settings.get(defs.screensaverPostponeOnProximity) &&
      _settings.get(defs.screensaverEnabled);

  StreamSubscription<Object?>? _sub;
  Timer? _hold;
  bool _screensaverActive = false;
  bool _screenOn = true;

  /// Whether the sensor should be watched right now.
  bool get _shouldRun =>
      _screensaverActive ? enabled : _postponeEnabled && _screenOn;

  @override
  Future<void> init() async {
    bus.on<ScreensaverStateChanged>().listen((e) {
      _screensaverActive = e.active;
      _sync();
    });
    bus.on<ScreenStateChanged>().listen((e) {
      _screenOn = e.on;
      _sync();
    });
    // Session start publishes the policy before the active event above,
    // and boundary crossings mid-session publish on their own; either way
    // the sensor starts or stops to match within a tick.
    bus.on<ScreensaverMotionPolicyChanged>().listen((e) {
      _schedulePolicy = e.dismissOnProximity;
      _sync();
    });
    bus.on<SettingChanged>().listen((e) {
      if (e.key != defs.screensaverDismissOnProximity.key &&
          e.key != defs.screensaverPostponeOnProximity.key &&
          e.key != defs.screensaverEnabled.key) {
        return;
      }
      // The switch turned on where there is no sensor (the settings page
      // never offers it, but the remote API and a settings import can):
      // back off, and the write lands here again as false.
      if (e.key == defs.screensaverDismissOnProximity.key &&
          proximityKnownUnsupported &&
          _settings.get(defs.screensaverDismissOnProximity)) {
        unawaited(_guardSupport());
        return;
      }
      _sync();
    });

    commands.register(
      Command(
        name: 'getProximitySupport',
        description:
            'Whether the device has a proximity sensor, its name and maker, '
            'and why not when it has none',
        handler: (_) async =>
            CommandResult.ok((await proximitySupport()).toJson()),
      ),
    );
    commands.register(
      Command(
        name: 'getProximityEnabled',
        description: 'Whether proximity sensor detection is enabled',
        handler: (_) async => CommandResult.ok(enabled),
      ),
    );

    await _guardSupport();

    // Seed the panel state from reality (a device that boots with its
    // screen already off must not watch for a screensaver to postpone)
    // and let the postpone leg start if it is due. Best-effort: a failure
    // leaves the default and the next ScreenStateChanged corrects it.
    final on = await commands.execute('isScreenOn', const {});
    if (on.ok && on.data is bool) _screenOn = on.data as bool;
    _sync();
  }

  /// The native answer, asked once. A failed or missing ask is not cached,
  /// so a bridge that was not ready gets asked again.
  Future<ProximitySupport> proximitySupport() async {
    if (_support case final known?) return known;
    try {
      final raw = await _methods.invokeMethod<Map<Object?, Object?>>('support');
      if (raw == null) return ProximitySupport.unknown;
      return _support = ProximitySupport(
        supported: raw['supported'] != false,
        name: raw['name'] as String?,
        vendor: raw['vendor'] as String?,
        hint: raw['hint'] as String?,
      );
    } catch (_) {
      return ProximitySupport.unknown;
    }
  }

  /// Keeps the switch off where there is no sensor: at boot, and whenever
  /// something turns it on.
  Future<void> _guardSupport() async {
    final support = await proximitySupport();
    if (support.supported ||
        !_settings.get(defs.screensaverDismissOnProximity)) {
      return;
    }
    await _settings.set(defs.screensaverDismissOnProximity, false);
    final why = support.hint ?? 'Not available on this device.';
    log.warn(
      name,
      'Dismiss on proximity kept off: '
      '${why[0].toLowerCase()}${why.substring(1)}',
    );
  }

  void _sync() {
    if (!_shouldRun) {
      _stop();
      return;
    }
    _start();
  }

  void _start() {
    if (_sub != null) return;
    log.info(
      name,
      'sensor on${sensorName != null ? ' ($sensorName)' : ''}'
      '${_screensaverActive ? '' : ', between screensavers'}',
    );
    _sub = _stream.receiveBroadcastStream().listen(
      (raw) {
        if (raw is! Map) return;
        final near = raw['near'] == true;
        if (raw['initial'] == true) {
          // The resting state at registration: something already on the
          // sensor is not an approach, and a far is nothing at all.
          log.debug(name, 'resting ${near ? 'near' : 'far'}');
          return;
        }
        _hold?.cancel();
        _hold = null;
        if (!near) {
          log.debug(name, 'far');
          return;
        }
        log.debug(name, 'near');
        bus.publish(const ProximityDetected());
        _hold = Timer.periodic(holdInterval, (_) {
          log.debug(name, 'still near');
          // Held: postpones the next screensaver, never dismisses one that
          // started with the thing already close.
          bus.publish(const ProximityDetected(held: true));
        });
      },
      onError: (Object e) {
        log.warn(name, 'sensor stream failed: $e');
        _stop();
      },
    );
  }

  void _stop() {
    _hold?.cancel();
    _hold = null;
    if (_sub == null) return;
    unawaited(_sub!.cancel());
    _sub = null;
    log.info(name, 'sensor off');
  }

  @override
  Future<void> dispose() async {
    _stop();
  }
}
