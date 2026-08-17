import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'ble_identity.dart';

/// Runs the native Bluetooth proxy (an ESPHome-compatible API server plus
/// BLE scanner, see android btproxy/) and owns its policy: the enable
/// setting, the encryption key's lifecycle, and restarting on settings
/// changes. The native side only executes.
///
/// The key is generated here, once, and stored in settings so it survives
/// reinstalls via export/import: Home Assistant keeps it in its config
/// entry, and a key that silently changed would take the proxy offline
/// until the user re-entered it.
class BtProxyManager extends Manager {
  BtProxyManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  static const _channel = MethodChannel('kiosk_satellite/bluetooth_proxy');

  StreamSubscription<SettingChanged>? _settingsSub;
  Timer? _restartDebounce;
  Future<void> _transition = Future.value();
  String _appVersion = '0';
  String _liveKey = '';
  bool _running = false;

  // The OUI vendor cache: prefix "AA:BB:CC" to vendor name, '' for a
  // registry miss. Persisted so each prefix is looked up once per install,
  // ever; a home's radio horizon holds a few dozen prefixes at most.
  Map<String, String> _ouiCache = {};
  final List<String> _ouiQueue = [];
  Timer? _ouiTimer;

  @override
  String get name => 'btproxy';

  @override
  Future<void> init() async {
    _settingsSub = bus.on<SettingChanged>().listen((e) {
      if (!e.key.startsWith('btproxy.') && e.key != defs.deviceName.key) {
        return;
      }
      // The first start writes the generated key into settings; restarting
      // on our own write would bounce the server (and HA's session) for a
      // value the running server already has.
      if (e.key == defs.btproxyKey.key &&
          _settings.get(defs.btproxyKey).trim() == _liveKey) {
        return;
      }
      _restartDebounce?.cancel();
      _restartDebounce = Timer(const Duration(milliseconds: 500), () {
        _transition = _transition.then((_) => _restart());
      });
    });
    commands.register(
      Command(
        name: 'btProxyStatus',
        description:
            'Bluetooth proxy state: running, scanning, counters, recent log',
        handler: (_) async {
          try {
            final status = await _channel.invokeMethod<Map>('status');
            return CommandResult.ok(
                Map<String, Object?>.from(status ?? const {}));
          } catch (e) {
            return CommandResult.fail('$e');
          }
        },
      ),
    );
    commands.register(
      Command(
        name: 'btProxyNearby',
        description:
            'Nearby Bluetooth devices the proxy hears, with best-effort '
            'identification (name, vendor, class, RSSI, last seen)',
        handler: (_) async {
          final devices = await refreshNearby();
          return CommandResult.ok({
            'count': devices.length,
            'devices': [for (final d in devices) d.toJson()],
          });
        },
      ),
    );
    _ouiCache = _loadOuiCache();
    final version = await commands.execute('getDeviceInfo', const {});
    _appVersion =
        ((version.data as Map?)?['appVersion'] as String?) ?? '0';
    if (_settings.get(defs.btproxyEnabled)) {
      _transition = _transition.then((_) => _start());
    }
  }

  /// Pulls the native tracker's inventory and classifies it. Queues online
  /// OUI lookups for still-anonymous hardware when the user opted in; those
  /// resolve into later refreshes through the cache.
  Future<List<NearbyDevice>> refreshNearby() async {
    List<dynamic> raw;
    try {
      raw = await _channel.invokeMethod<List<dynamic>>('nearby') ?? const [];
    } catch (_) {
      return const [];
    }
    final lookupEnabled = _settings.get(defs.btproxyMacLookup);
    final devices = <NearbyDevice>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final address = '${entry['address'] ?? ''}';
      String? ouiVendor;
      if (hasRealOui(address)) {
        ouiVendor = _ouiCache[ouiOf(address)];
        if (ouiVendor != null && ouiVendor.isEmpty) ouiVendor = null;
      }
      final device = classify(entry, ouiVendor: ouiVendor);
      if (lookupEnabled &&
          device.vendor == null &&
          hasRealOui(address) &&
          !_ouiCache.containsKey(ouiOf(address))) {
        _queueOuiLookup(ouiOf(address));
      }
      devices.add(device);
    }
    return devices;
  }

  Map<String, String> _loadOuiCache() {
    try {
      final stored = _settings.internal('btproxy_oui_cache');
      if (stored.isEmpty) return {};
      return Map<String, String>.from(jsonDecode(stored) as Map);
    } catch (_) {
      return {};
    }
  }

  void _queueOuiLookup(String oui) {
    if (_ouiQueue.contains(oui)) return;
    _ouiQueue.add(oui);
    _ouiTimer ??= Timer.periodic(
      // Under api.macvendors.com's free-tier rate limit, with margin.
      const Duration(seconds: 3),
      (_) => _drainOuiQueue(),
    );
  }

  Future<void> _drainOuiQueue() async {
    if (_ouiQueue.isEmpty) {
      _ouiTimer?.cancel();
      _ouiTimer = null;
      return;
    }
    if (!_settings.get(defs.btproxyMacLookup)) {
      _ouiQueue.clear();
      return;
    }
    final oui = _ouiQueue.removeAt(0);
    try {
      final response = await http
          .get(Uri.parse('https://api.macvendors.com/$oui'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        _ouiCache[oui] = response.body.trim();
      } else if (response.statusCode == 404) {
        // A registry miss is an answer too: cache it so the prefix is
        // never asked about again.
        _ouiCache[oui] = '';
      } else {
        return; // rate limited or server trouble: drop, retry on a later pass
      }
      await _settings.setInternal('btproxy_oui_cache', jsonEncode(_ouiCache));
    } catch (e) {
      log.warn(name, 'OUI lookup failed for $oui: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _restartDebounce?.cancel();
    _ouiTimer?.cancel();
    _ouiTimer = null;
    await _settingsSub?.cancel();
    _settingsSub = null;
    await _stop();
  }

  Future<void> _restart() async {
    await _stop();
    if (_settings.get(defs.btproxyEnabled)) await _start();
  }

  Future<void> _start() async {
    var key = _settings.get(defs.btproxyKey).trim();
    if (key.isEmpty) {
      key = _generateKey();
      _liveKey = key;
      await _settings.set(defs.btproxyKey, key);
    }
    _liveKey = key;
    final friendly = _settings.get(defs.deviceName).trim();
    final port =
        int.tryParse(_settings.get(defs.btproxyPort).trim()) ?? 6053;
    try {
      await _channel.invokeMethod('start', {
        'friendlyName': friendly.isEmpty ? 'Kiosk Satellite' : friendly,
        'psk': key,
        'port': port,
        'projectVersion': _appVersion,
      });
      _running = true;
      log.info(name, 'started (port $port)');
    } catch (e) {
      // Not-Android hosts (tests) and denied permissions land here; the
      // toggle stays on so enabling works once the grant exists.
      log.warn(name, 'failed to start: $e');
    }
  }

  Future<void> _stop() async {
    if (!_running) return;
    _running = false;
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }

  /// 32 random bytes, base64: exactly the shape ESPHome's own key generator
  /// produces and aioesphomeapi validates.
  String _generateKey() {
    final rng = Random.secure();
    return base64Encode(List<int>.generate(32, (_) => rng.nextInt(256)));
  }
}
