import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../device/wifi_mac.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'ble_identity.dart';
import 'esp_entities.dart';
import 'node_name.dart';

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

  /// Why the last start failed, or null while healthy. Surfaced on the
  /// ESPHome settings pages: a server that silently fails to start looks
  /// exactly like a working one there otherwise (issue #240, a bind
  /// conflict on one of two identical tablets).
  String? _startError;

  /// The node name the running server came up under, so writing it back
  /// into settings does not bounce the server (as with [_liveKey]).
  String _liveNodeName = '';
  late final EspEntitySurface _entities =
      EspEntitySurface(bus, commands, log, _settings);

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
    // Entity commands from Home Assistant, relayed by the native hub.
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'entityCommand' && call.arguments is Map) {
        final args = call.arguments as Map;
        await _entities.handleCommand('${args['objectId']}', args['value']);
      }
      if (call.method == 'serviceCall' && call.arguments is Map) {
        final payload = call.arguments as Map;
        await _entities.handleService(
          '${payload['name']}',
          (payload['args'] as Map?)?.cast<String, Object?>() ?? const {},
        );
      }
      return null;
    });
    // Settings that shape the entity CATALOG (not just a value): flipping
    // one changes which entities exist, and only a server restart re-lists
    // them to Home Assistant.
    const catalogKeys = {
      'camera.enabled',
      'launcher.enabled',
      'motion.sensor',
      // The Show Music Assistant button exists only while a server address
      // is configured.
      'sendspin.ma_url',
      // The Voice Satellite switches exist only with a satellite bound.
      'ha.satellite_entity',
    };
    _settingsSub = bus.on<SettingChanged>().listen((e) {
      if (!e.key.startsWith('btproxy.') &&
          !e.key.startsWith('esphome.') &&
          !catalogKeys.contains(e.key) &&
          e.key != defs.deviceName.key) {
        return;
      }
      // UI-only keys: the sort order and the OUI lookup live entirely on
      // the Dart side and are read live. Restarting the native proxy for
      // them drops Home Assistant's session for nothing (it cost .71 its
      // only reconnect of an otherwise unbroken nine-hour soak).
      if (e.key == defs.btproxyNearbySort.key ||
          e.key == defs.btproxyMacLookup.key) {
        return;
      }
      // The first start writes the generated key into settings; restarting
      // on our own write would bounce the server (and HA's session) for a
      // value the running server already has.
      if (e.key == defs.btproxyKey.key &&
          _settings.get(defs.btproxyKey).trim() == _liveKey) {
        return;
      }
      // Same story for the node name the first start writes back.
      if (e.key == defs.esphomeNodeName.key &&
          esphomeNodeSlug(_settings.get(defs.esphomeNodeName)) ==
              _liveNodeName) {
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
          // The real-MAC identity, for the settings pages: with the
          // setting on, no address here means the platform would not
          // reveal one and the generated identity stayed in use — a silent
          // no-op unless the page says so (issue #252). The source says
          // whether it was read or typed in (issue #300); the pages offer
          // the field only while the hardware read failed.
          final identity = await wifiMacIdentity(_settings);
          try {
            final status = await _channel.invokeMethod<Map>('status');
            return CommandResult.ok({
              ...Map<String, Object?>.from(status ?? const {}),
              if (_startError != null) 'startError': _startError,
              'realMac': ?identity.mac,
              'realMacSource': identity.source.name,
            });
          } catch (e) {
            if (_startError != null) {
              return CommandResult.ok(
                  {'running': false, 'startError': _startError});
            }
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
    commands.register(
      Command(
        name: 'btProxyAdapterOn',
        description: "Whether the device's Bluetooth adapter is turned on",
        handler: (_) async {
          try {
            final on = await _channel.invokeMethod<bool>('adapterOn');
            return CommandResult.ok({'on': on == true});
          } catch (e) {
            return CommandResult.fail('$e');
          }
        },
      ),
    );
    _ouiCache = _loadOuiCache();
    final version = await commands.execute('getDeviceInfo', const {});
    _appVersion =
        ((version.data as Map?)?['appVersion'] as String?) ?? '0';
    if (_settings.get(defs.esphomeEnabled)) {
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

  /// The node name to serve under: what the user set, or on a brand-new
  /// install a slug of the device name, so Home Assistant's action names
  /// read like the kiosk. Empty leaves the native generated identity,
  /// which is what every install that already has an entry keeps.
  String _nodeName({required bool firstEver}) {
    final chosen = esphomeNodeSlug(_settings.get(defs.esphomeNodeName));
    if (chosen.isNotEmpty) return chosen;
    return firstEver ? esphomeNodeSlug(_settings.get(defs.deviceName)) : '';
  }

  Future<void> _restart() async {
    await _stop();
    if (_settings.get(defs.esphomeEnabled)) await _start();
  }

  Future<void> _start() async {
    var key = _settings.get(defs.btproxyKey).trim();
    // Read before the key is generated below: an empty key is what says
    // this install has never announced itself, which is what decides
    // whether the node name may be taken from the device name.
    final firstEver = key.isEmpty;
    if (key.isEmpty) {
      key = _generateKey();
      _liveKey = key;
      await _settings.set(defs.btproxyKey, key);
    } else if (!_validKey(key)) {
      // A hand-typed key ("a single word as a test", issue #239) cannot
      // work: the ESPHome protocol's key is the base64 form of 32 random
      // bytes, nothing else survives the native require(). Failing here
      // with a recovery hint beats a dead server whose only symptom is
      // Home Assistant's generic "unable to connect".
      _startError =
          'the encryption key is not valid; it must be the base64 form of '
          '32 random bytes. Clear the field to generate a fresh key.';
      log.warn(name, 'failed to start: invalid encryption key');
      return;
    }
    _liveKey = key;
    final friendly = _settings.get(defs.deviceName).trim();
    final node = _nodeName(firstEver: firstEver);
    final port =
        int.tryParse(_settings.get(defs.btproxyPort).trim()) ?? 6053;
    // Null while the setting is off or the platform hides the address; the
    // native side then keeps its synthetic identity (issue #252).
    final realMac = await adoptedWifiMac(_settings);
    try {
      final resolved = await _channel.invokeMethod<String>('start', {
        'friendlyName': friendly.isEmpty ? 'Kiosk Satellite' : friendly,
        'psk': key,
        'port': port,
        'projectVersion': _appVersion,
        'bluetoothProxy': _settings.get(defs.btproxyEnabled),
        'connections': _settings.get(defs.btproxyConnections),
        'minConnectRssi': int.tryParse(
                _settings.get(defs.btproxyMinConnectRssi)) ??
            0,
        'entities': _settings.get(defs.esphomeEntities)
            ? await _entities.build()
            : const <Map<String, Object?>>[],
        // The actions ride the entity surface's toggle: they are served in
        // the same listing and land on the same Home Assistant device.
        'services': _settings.get(defs.esphomeEntities)
            ? _entities.buildServices()
            : const <Map<String, Object?>>[],
        'macOverride': ?realMac,
        // Empty leaves the generated kiosk-satellite-<id> identity in
        // place; the native side answers with whichever it used.
        'nodeName': node,
      });
      _running = true;
      _startError = null;
      // Whatever name the server came up under is written back, so the
      // settings row shows the real one instead of a placeholder and the
      // next start reads it from there. Identical writes are ignored by
      // the settings store; the listener above skips the rest.
      final live = esphomeNodeSlug(resolved ?? '');
      if (live.isNotEmpty) {
        _liveNodeName = live;
        await _settings.set(defs.esphomeNodeName, live);
      }
      if (_settings.get(defs.esphomeEntities)) {
        _entities.attach(
          (objectId, value) => _channel.invokeMethod(
              'entityState', {'objectId': objectId, 'value': value}),
          (jpeg) => _channel.invokeMethod('cameraImage', {'jpeg': jpeg}),
        );
      }
      log.info(name, 'started (port $port)');
    } catch (e) {
      // Not-Android hosts (tests) and denied permissions land here; the
      // toggle stays on so enabling works once the grant exists.
      _startError = e is PlatformException ? (e.message ?? '$e') : '$e';
      log.warn(name, 'failed to start: $e');
    }
  }

  Future<void> _stop() async {
    _startError = null;
    if (!_running) return;
    _running = false;
    _entities.detach();
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

  static bool _validKey(String key) {
    try {
      return base64Decode(key).length == 32;
    } catch (_) {
      return false;
    }
  }
}
