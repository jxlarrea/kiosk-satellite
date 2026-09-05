import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// One kiosk on the network, as it announced itself.
class FleetDevice {
  const FleetDevice({
    required this.id,
    required this.name,
    required this.version,
    required this.address,
    required this.port,
    this.self = false,
  });

  final String id;
  final String name;
  final String version;
  final String address;
  final int port;

  /// Whether this is the device the list was read from.
  final bool self;

  /// Where its remote admin answers.
  String get url => 'http://$address:$port';

  static FleetDevice? fromMap(Map<Object?, Object?>? raw, {bool self = false}) {
    if (raw == null) return null;
    final address = '${raw['address'] ?? ''}';
    final port = raw['port'];
    if (port is! num) return null;
    return FleetDevice(
      id: '${raw['id'] ?? ''}',
      name: '${raw['name'] ?? ''}',
      version: '${raw['version'] ?? ''}',
      address: address,
      port: port.toInt(),
      self: self,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'address': address,
    'port': port,
    'url': url,
    'self': self,
  };
}

/// The kiosks on this network, for the remote admin's kiosk switcher.
///
/// While the remote admin server is up (remote management on, with a
/// password) and Find other kiosks is on, the native `FleetDiscovery`
/// announces this device over mDNS and listens for the others. Every
/// change to the set of peers is published as [FleetChanged], which the
/// remote admin page hears over its socket, and the `fleet` command
/// answers the list on demand: this device first, then the others by
/// name.
///
/// The condition mirrors the remote manager's own, since what is
/// announced is the admin server's address and port: a kiosk that does
/// not serve the admin has nothing to be listed under.
class FleetManager extends Manager {
  FleetManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  static const _methods = MethodChannel('kiosk_satellite/fleet');
  static const _stream = EventChannel('kiosk_satellite/fleet_stream');

  @override
  String get name => 'fleet';

  /// Whether this device should be announcing and listening right now.
  bool get enabled =>
      _settings.get(defs.remoteEnabled) &&
      _settings.get(defs.remotePassword).isNotEmpty &&
      _settings.get(defs.remoteFleetDiscovery);

  /// Whether the native discovery is running.
  bool get running => _sub != null;

  /// The list as last heard: this device first, the rest by name.
  List<FleetDevice> get devices => List.unmodifiable(_devices);
  List<FleetDevice> _devices = const [];

  StreamSubscription<Object?>? _sub;
  final _subs = <StreamSubscription<Object?>>[];

  @override
  Future<void> init() async {
    commands.register(
      Command(
        name: 'fleet',
        description:
            'The kiosks on this network with their remote admin on, as '
            'heard over mDNS: this device first, then the others by name, '
            'each with its name, address, admin port, version and url.',
        quiet: true,
        handler: (_) async {
          if (running) await _refresh();
          return CommandResult.ok({
            'enabled': enabled,
            'devices': [for (final d in _devices) d.toJson()],
          });
        },
      ),
    );

    _subs.add(
      bus.on<SettingChanged>().listen((e) {
        if (e.key == defs.remoteEnabled.key ||
            e.key == defs.remotePassword.key ||
            e.key == defs.remotePort.key ||
            e.key == defs.remoteFleetDiscovery.key ||
            e.key == defs.deviceName.key) {
          _sync();
        }
      }),
    );
    // A network coming back is when the others need telling again: the
    // announcements they missed while it was down are gone.
    _subs.add(
      bus.on<NetworkStateChanged>().listen((e) {
        if (e.up && running) {
          _methods.invokeMethod<void>('nudge').catchError((_) {});
        }
      }),
    );
    await _sync();
  }

  Future<void> _sync() async {
    if (enabled) {
      await _start();
    } else if (running) {
      await _stop();
    }
  }

  Future<void> _start() async {
    final args = {
      'name': _settings.get(defs.deviceName),
      'port': _settings.get(defs.remotePort).toInt(),
    };
    try {
      await _methods.invokeMethod<void>('start', args);
      if (!running) {
        _sub = _stream.receiveBroadcastStream().listen(
          _onSnapshot,
          onError: (Object e) => log.warn(name, 'discovery stream: $e'),
        );
        _warnedDeaf = false;
        log.info(
          name,
          'announcing on :${args['port']} and listening for other kiosks',
        );
      }
    } on MissingPluginException {
      // No bridge (tests, a desktop run): nothing to discover with.
    } catch (e) {
      log.warn(name, 'could not start discovery: $e');
    }
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _methods.invokeMethod<void>('stop');
    } on MissingPluginException {
      // As above.
    } catch (e) {
      log.warn(name, 'could not stop discovery: $e');
    }
    _apply(const []);
    log.info(name, 'stopped');
  }

  Future<void> _refresh() async {
    try {
      final snap = await _methods.invokeMethod<Map<Object?, Object?>>(
        'snapshot',
      );
      if (snap != null) _onSnapshot(snap);
    } catch (_) {}
  }

  /// Said once per run: the socket could not have the mDNS port, so this
  /// kiosk announces but hears nobody.
  bool _warnedDeaf = false;

  void _onSnapshot(Object? raw) {
    if (raw is! Map) return;
    if (raw['listening'] == false && running && !_warnedDeaf) {
      _warnedDeaf = true;
      log.warn(
        name,
        'port 5353 is taken on this device, so other kiosks will not be '
        'heard; this one still announces itself',
      );
    }
    final self = FleetDevice.fromMap(
      (raw['self'] as Map?)?.cast<Object?, Object?>(),
      self: true,
    );
    final peers = <FleetDevice>[];
    for (final p in (raw['peers'] as List? ?? const [])) {
      if (p is! Map) continue;
      final d = FleetDevice.fromMap(p.cast<Object?, Object?>());
      if (d != null) peers.add(d);
    }
    peers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _apply([?self, ...peers]);
  }

  void _apply(List<FleetDevice> list) {
    final before = [for (final d in _devices) d.toJson()];
    final after = [for (final d in list) d.toJson()];
    _devices = list;
    if (_same(before, after)) return;
    final others = list.where((d) => !d.self).length;
    log.info(
      name,
      '$others other kiosk${others == 1 ? '' : 's'} on the network',
    );
    bus.publish(FleetChanged(devices: after));
  }

  static bool _same(
    List<Map<String, Object?>> a,
    List<Map<String, Object?>> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (x.length != y.length) return false;
      for (final k in x.keys) {
        if (x[k] != y[k]) return false;
      }
    }
    return true;
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    if (running) await _stop();
  }
}
