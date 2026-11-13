import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:math' show Random;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../device/wifi_mac.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'ble_identity.dart';
import 'esp_entities.dart';
import 'node_name.dart';
import 'oui_cache.dart';

/// Runs the native Bluetooth proxy (an ESPHome-compatible API server plus
/// BLE scanner, see android btproxy/) and owns its policy: the enable
/// setting, the encryption key's lifecycle, and restarting on settings
/// changes. The native side only executes.
///
/// The key is generated here, once, and stored in settings so it survives
/// reinstalls via export/import: Home Assistant keeps it in its config
/// entry, and a key that silently changed would take the proxy offline
/// until the user re-entered it.
/// Whether the platform can scan for Bluetooth LE at all. Android binds
/// its GATT service only on builds that declare the Bluetooth LE feature;
/// without it every scan fails the instant it starts, whatever the scan
/// settings, permissions or retries (issue #326, a Facebook Portal on
/// Android 9; the same missing declaration on a LineageOS Echo Show). The
/// manager keeps the proxy switch off on such a build, and both settings
/// surfaces render it disabled with [hint].
///
/// Unknown counts as supported: a missing answer (no bridge, as in tests)
/// must never switch the proxy off on a device that can scan.
class BleSupport {
  const BleSupport({required this.supported, this.hint});

  static const unknown = BleSupport(supported: true);

  final bool supported;

  /// Why [supported] is false, in a sentence fit for a settings row.
  final String? hint;

  Map<String, Object?> toJson() => {
    'supported': supported,
    if (hint != null) 'hint': hint,
  };
}

/// [fields] as Home Assistant's event data takes them: strings as plain
/// data, everything else as a data template, which Home Assistant renders
/// into a number, a boolean, a list or None. Those values are literals
/// with no template markup, so no text a user spoke can be run as one.
({Map<String, String> data, Map<String, String> typed}) haEventFields(
  Map<String, Object?> fields,
) {
  final data = <String, String>{};
  final typed = <String, String>{};
  fields.forEach((key, value) {
    switch (value) {
      case String():
        data[key] = value;
      case null:
        typed[key] = 'None';
      case bool():
        typed[key] = value ? 'True' : 'False';
      case num() when value.isFinite:
        typed[key] = '$value';
      case List() when value.every((v) => v is String || v is num):
        typed[key] = jsonEncode(value);
      default:
        data[key] = '$value';
    }
  });
  return (data: data, typed: typed);
}

class BtProxyManager extends Manager {
  BtProxyManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  static const _channel = MethodChannel('kiosk_satellite/bluetooth_proxy');

  StreamSubscription<SettingChanged>? _settingsSub;
  StreamSubscription<ShizukuStateChanged>? _shizukuSub;
  StreamSubscription<DeviceOwnerChanged>? _ownerSub;
  StreamSubscription<HaEventRequested>? _eventSub;
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

  /// The platform's answer on Bluetooth LE, asked once per process. Null
  /// until the bridge has answered; the sync getters below are for UI code
  /// and read false until then, so a row is never disabled on a guess.
  BleSupport? _bleSupport;

  bool get bleKnownUnsupported => _bleSupport?.supported == false;

  /// The reason to show under the disabled proxy switch.
  String? get bleHint => _bleSupport?.hint;

  /// The node name the running server came up under, so writing it back
  /// into settings does not bounce the server (as with [_liveKey]).
  String _liveNodeName = '';

  /// The web page port the running server reports (see [_webserverPort]),
  /// so a remote admin settings change that leaves it as it is does not
  /// restart the server.
  int _liveWebserverPort = 0;

  /// The real Wi-Fi address the running server reports, or null for the
  /// generated identity.
  String? _liveMac;
  late final EspEntitySurface _entities = EspEntitySurface(
    bus,
    commands,
    log,
    _settings,
    // The dashboard view list moved after the catalog was served (learned
    // late because Home Assistant was unreachable at start, or a dashboard
    // added since): only a restart re-lists the entities (issue #362).
    onCatalogChanged: _scheduleRestart,
  );

  /// The settings key older builds kept the OUI vendor cache under.
  static const _legacyOuiKey = 'btproxy_oui_cache';

  // The OUI vendor cache, in a file of its own (see OuiCache). Loaded on
  // first use: the Nearby devices commands also work while the proxy is
  // off. A while after init it loads anyway, so the copy older builds left
  // in the settings store leaves it on every device, whether or not the
  // list is ever opened, without adding to the start.
  Future<OuiCache>? _ouiCacheLoad;
  Timer? _ouiMigration;
  Future<OuiCache> _ouiCache() => _ouiCacheLoad ??= _loadOuiCache();
  final List<String> _ouiQueue = [];
  Timer? _ouiTimer;

  @override
  String get name => 'esphome';

  /// Where the voice assistant's messages from Home Assistant land (the
  /// native voice satellite): a kind ("subscribed", "response", "event",
  /// "timer", "announce", "setConfiguration") and its fields.
  void Function(String kind, Map<String, Object?> fields)? onVoice;

  /// Answers Home Assistant's wake word configuration request: the
  /// external wake words it offers in, `{available, active, maxActive}` out.
  Future<Map<String, Object?>> Function(List<Map<Object?, Object?>> external)?
  onVoiceConfiguration;

  /// Whether the running server serves the voice assistant.
  bool get voiceServing => _running && _voiceLive;
  bool _voiceLive = false;

  /// Ask Home Assistant to run a pipeline, or stop the running one. False
  /// with no Home Assistant session subscribed.
  Future<bool> voiceRequest({
    required bool start,
    String conversationId = '',
    int flags = 0,
    String wakeWordPhrase = '',
  }) async {
    if (!voiceServing) return false;
    try {
      return await _channel.invokeMethod<bool>('voiceRequest', {
            'start': start,
            'conversationId': conversationId,
            'flags': flags,
            'wakeWordPhrase': wakeWordPhrase,
          }) ==
          true;
    } catch (_) {
      return false;
    }
  }

  /// One chunk of microphone audio for the running pipeline.
  Future<bool> voiceAudio(Uint8List pcm, {bool end = false}) async {
    if (!voiceServing) return false;
    try {
      return await _channel.invokeMethod<bool>('voiceAudio', {
            'pcm': pcm,
            'end': end,
          }) ==
          true;
    } catch (_) {
      return false;
    }
  }

  /// An announcement or a spoken answer finished playing.
  Future<bool> voiceAnnounceFinished({bool success = true}) async {
    if (!voiceServing) return false;
    try {
      return await _channel.invokeMethod<bool>('voiceAnnounceFinished', {
            'success': success,
          }) ==
          true;
    } catch (_) {
      return false;
    }
  }

  /// Whether a Home Assistant session is subscribed to the voice assistant.
  Future<bool> voiceSubscribed() async {
    if (!voiceServing) return false;
    try {
      return await _channel.invokeMethod<bool>('voiceSubscribed') == true;
    } catch (_) {
      return false;
    }
  }

  /// The MAC the running server reports, Home Assistant's key for this
  /// device; empty while stopped.
  Future<String> identityMac() async {
    try {
      final status = await _channel.invokeMethod<Map>('status');
      return '${status?['mac'] ?? ''}';
    } catch (_) {
      return '';
    }
  }

  /// Whether this start should serve the voice assistant: the native
  /// runtime with Voice Satellite enabled.
  bool get _voiceWanted =>
      _settings.get(defs.voiceRuntime) == 'native' &&
      _settings.get(defs.voiceEnabled);

  @override
  Future<void> init() async {
    _ouiMigration = Timer(
      const Duration(minutes: 1),
      () => unawaited(_ouiCache()),
    );
    // Keep scanning with the screen off needs Android 13's data type
    // filters. Below that the switch could do nothing, so neither UI shows
    // it. Settled before any page renders.
    if (Platform.isAndroid) {
      try {
        final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
        if (sdk < 33) defs.deviceHiddenKeys.add(defs.btproxyScreenOffScan.key);
      } catch (_) {}
    }
    commands.register(
      Command(
        name: 'getEspHomeEntities',
        description:
            'List available kiosk entities, including excluded entities.',
        quiet: true,
        handler: (_) async {
          final catalog = await EspEntitySurface(
            bus,
            commands,
            log,
            _settings,
          ).build(includeExcluded: true);
          return CommandResult.ok([
            for (final entity in catalog)
              {
                ...entity,
                'categoryLabel': EspEntitySurface.categoryLabel(entity),
              },
          ]);
        },
      ),
    );
    // Entity commands from Home Assistant, relayed by the native hub.
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'entityCommand' && call.arguments is Map) {
        final args = call.arguments as Map;
        await _entities.handleCommand('${args['objectId']}', args['value']);
      }
      if (call.method == 'voice' && call.arguments is Map) {
        final args = (call.arguments as Map).cast<String, Object?>();
        onVoice?.call('${args['kind']}', args);
        return null;
      }
      if (call.method == 'voiceConfiguration' && call.arguments is Map) {
        final external = ((call.arguments as Map)['external'] as List?) ?? [];
        final answer = onVoiceConfiguration;
        if (answer == null) return const <String, Object?>{};
        return answer([for (final e in external) e as Map<Object?, Object?>]);
      }
      if (call.method == 'serviceCall' && call.arguments is Map) {
        final payload = call.arguments as Map;
        // The action's answer, as JSON, rides back as this call's result:
        // the native side sends it to Home Assistant as the response data
        // an automation reads through response_variable.
        final response = await _entities.handleService(
          '${payload['name']}',
          (payload['args'] as Map?)?.cast<String, Object?>() ?? const {},
        );
        return response == null ? null : jsonEncode(response);
      }
      return null;
    });
    // Settings that shape the entity CATALOG (not just a value): flipping
    // one changes which entities exist, and only a server restart re-lists
    // them to Home Assistant. Setup-time choices only: a switch an
    // automation flips through the day (Camera enabled, the Motion
    // sensor) must never be here, since the restart drops every entity
    // for a couple of seconds (issue #339). The camera entities follow
    // the hardware instead and read unknown while off.
    const catalogKeys = {
      'launcher.enabled',
      // The Show Music Assistant button exists only while a server address
      // is configured.
      'sendspin.ma_url',
      // The Voice Satellite switches exist only with a satellite bound.
      'ha.satellite_entity',
      // The location sensors exist only while Report location is on: a
      // setup-time choice, made knowing it re-registers the device
      // (issue #363).
      'location.enabled',
      // The Person sensor exists only while the Person Sensor switch is
      // on, the same way (issue #734).
      'person.sensor',
      // The intercom entities exist only while the intercom is on.
      'intercom.enabled',
      // The LED Control Idle light and effect exist only while LED Control
      // is on.
      'led.enabled',
      // The followed player's buttons and sensors, opt-in from the Media
      // Player page (issue #741).
      'sendspin.esphome_entities',
      // The voice assistant, and its vs_ entities and actions, exist only
      // on the native runtime with Voice Satellite on; the engine decides
      // which wake words Home Assistant's selects offer, which it asks for
      // once per connection.
      'voice.runtime',
      'voice.enabled',
      'voice.wake_word_engine',
    };
    // The remote admin server's settings, which decide the web page port
    // reported to Home Assistant (the device page's Visit link).
    const remoteKeys = {
      'remote.enabled',
      'remote.port',
      'remote.password',
      'remote.tls',
    };
    // The Restart device button follows the Shizuku connection on a kiosk
    // that is not the device owner (issue #528): a grant made after the
    // catalog was served, or a Shizuku that stopped, changes what exists,
    // and only a restart re-lists it. Asked rather than assumed, so a
    // device owner's catalog never restarts over Shizuku.
    // Only the device owner can read the real Wi-Fi address. Becoming it
    // after the server started (an Echo image's installer) moves the
    // server to the real address once, and the adoption keeps it there.
    _ownerSub = bus.on<DeviceOwnerChanged>().listen((_) async {
      if (!_running || !_settings.get(defs.esphomeRealMac)) return;
      final mac = await adoptedWifiMac(_settings);
      if (_running && mac != null && mac != _liveMac) _scheduleRestart();
    });
    _shizukuSub = bus.on<ShizukuStateChanged>().listen((_) async {
      if (!_running) return;
      final support = await commands.execute(
        'getDeviceRebootSupport',
        const {},
      );
      final listed =
          support.ok &&
          support.data is Map &&
          (support.data as Map)['supported'] == true;
      if (_running && listed != _entities.rebootButtonListed) {
        _scheduleRestart();
      }
    });
    // Timer and alarm events for Home Assistant's bus (issue #765). With
    // the server off there is no one to tell.
    _eventSub = bus.on<HaEventRequested>().listen((e) async {
      if (!_running) return;
      final fields = haEventFields(e.data);
      try {
        await _channel.invokeMethod<bool>('fireEvent', {
          'name': 'esphome.${e.name}',
          'data': fields.data,
          'typed': fields.typed,
        });
      } catch (err) {
        log.warn(name, 'event ${e.name} not sent: $err');
      }
    });
    _settingsSub = bus.on<SettingChanged>().listen((e) {
      // Real MAC turned off: forget the adopted address, so turning it
      // back on reads the hardware again (issue #736). Falls through to
      // the restart below, which runs after the debounce and so after
      // the adoption is gone.
      if (e.key == defs.esphomeRealMac.key &&
          !_settings.get(defs.esphomeRealMac)) {
        unawaited(forgetAdoptedWifiMac(_settings));
      }
      // The switch turned on where scanning cannot work (the settings
      // page never offers it, but the remote API and a settings import
      // can): back off, and the write lands here again as false.
      if (e.key == defs.btproxyEnabled.key &&
          bleKnownUnsupported &&
          _settings.get(defs.btproxyEnabled)) {
        unawaited(_guardBleSupport());
        return;
      }
      if (!e.key.startsWith('btproxy.') &&
          !e.key.startsWith('esphome.') &&
          !catalogKeys.contains(e.key) &&
          !remoteKeys.contains(e.key) &&
          e.key != defs.deviceName.key) {
        return;
      }
      // Only the reported port matters here, and Home Assistant reads it
      // at connect, so a change to it is worth the reconnect; a password
      // changed while the page stays served is not.
      if (remoteKeys.contains(e.key) &&
          _webserverPort() == _liveWebserverPort) {
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
      // The scan intensity reaches the running scanner directly: a scan
      // session restart is milliseconds, a server restart drops Home
      // Assistant's session.
      if (e.key == defs.btproxyScanDuty.key) {
        if (_running) unawaited(_pushScanDuty());
        return;
      }
      if (e.key == defs.btproxyScreenOffScan.key) {
        if (_running) unawaited(_pushScreenOffScan());
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
      _scheduleRestart();
    });
    commands.register(
      Command(
        name: 'esphomeStatus',
        description:
            'ESPHome server state: running, start error, and the Bluetooth '
            'proxy underneath it (scanning, counters, connections, recent log)',
        // Polled by the ESPHome settings pages: a log line per read is a
        // metronome, not information (#272).
        quiet: true,
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
              return CommandResult.ok({
                'running': false,
                'startError': _startError,
              });
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
        name: 'bluetoothAdapterOn',
        description: "Whether the device's Bluetooth adapter is turned on",
        quiet: true,
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
    commands.register(
      Command(
        name: 'getBleSupport',
        description:
            'Whether this device can scan for Bluetooth LE at all, and why '
            'not when it cannot',
        quiet: true,
        handler: (_) async => CommandResult.ok((await bleSupport()).toJson()),
      ),
    );
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
    final ouiCache = await _ouiCache();
    final devices = <NearbyDevice>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final address = '${entry['address'] ?? ''}';
      String? ouiVendor;
      if (hasRealOui(address)) {
        ouiVendor = ouiCache.name(ouiOf(address));
      }
      final device = classify(entry, ouiVendor: ouiVendor);
      if (lookupEnabled &&
          device.vendor == null &&
          hasRealOui(address) &&
          !ouiCache.knows(ouiOf(address))) {
        _queueOuiLookup(ouiOf(address));
      }
      devices.add(device);
    }
    return devices;
  }

  Future<OuiCache> _loadOuiCache() async {
    File? file;
    try {
      final dir = await getApplicationSupportDirectory();
      file = File('${dir.path}/btproxy_oui_cache.json');
    } catch (_) {}
    final cache = OuiCache(file);
    final legacy = _settings.internal(_legacyOuiKey);
    try {
      await cache.load(legacy: legacy);
      if (legacy.isNotEmpty) {
        await _settings.setInternal(_legacyOuiKey, '');
        log.info(
          name,
          'OUI cache moved out of the settings store: '
          '${cache.nameCount} names kept, ${legacy.length} characters freed',
        );
      }
    } catch (e) {
      log.warn(name, 'OUI cache load failed: $e');
    }
    return cache;
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
      final cache = await _ouiCache();
      if (response.statusCode == 200) {
        await cache.putName(oui, response.body.trim());
      } else if (response.statusCode == 404) {
        // A registry miss is an answer too: remembered for the session so
        // the prefix is not asked about again. Never saved, see OuiCache.
        cache.putMiss(oui);
      }
      // Anything else is a rate limit or server trouble: drop, retry on a
      // later pass.
    } catch (e) {
      log.warn(name, 'OUI lookup failed for $oui: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _restartDebounce?.cancel();
    _ouiTimer?.cancel();
    _ouiTimer = null;
    _ouiMigration?.cancel();
    _ouiMigration = null;
    await _settingsSub?.cancel();
    _settingsSub = null;
    await _shizukuSub?.cancel();
    _shizukuSub = null;
    await _ownerSub?.cancel();
    _ownerSub = null;
    await _eventSub?.cancel();
    _eventSub = null;
    await _stop();
  }

  /// The node name to serve under: what the user set, or on a brand-new
  /// install the device name under a `ks-` prefix, so Home Assistant's
  /// action names read like the kiosk. Empty leaves the native generated
  /// identity, which is what every install that already has an entry
  /// keeps.
  String _nodeName({required bool firstEver}) {
    final chosen = esphomeNodeSlug(_settings.get(defs.esphomeNodeName));
    if (chosen.isNotEmpty) return chosen;
    return firstEver
        ? esphomeNodeFromDeviceName(_settings.get(defs.deviceName))
        : '';
  }

  /// One restart for a burst of changes, queued behind whatever
  /// transition is under way.
  void _scheduleRestart() {
    _restartDebounce?.cancel();
    _restartDebounce = Timer(const Duration(milliseconds: 500), () {
      _transition = _transition.then((_) => _restart());
    });
  }

  Future<void> _restart() async {
    await _stop();
    if (_settings.get(defs.esphomeEnabled)) await _start();
  }

  /// The native answer on Bluetooth LE, asked once. A failed or missing
  /// ask is not cached, so a bridge that was not ready gets asked again.
  Future<BleSupport> bleSupport() async {
    if (_bleSupport case final known?) return known;
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'bleSupport',
      );
      if (raw == null) return BleSupport.unknown;
      return _bleSupport = BleSupport(
        supported: raw['supported'] != false,
        hint: raw['hint'] as String?,
      );
    } catch (_) {
      return BleSupport.unknown;
    }
  }

  /// Keeps the proxy switch off where scanning cannot work: at boot, and
  /// whenever something turns it on. Off in the setting rather than only
  /// in effect, so every reader of the switch (the entity catalogs, the
  /// service reasons, the permission rows) agrees
  /// without a second flag, and the server starts with no proxy for Home
  /// Assistant to see.
  Future<void> _guardBleSupport() async {
    final support = await bleSupport();
    if (support.supported || !_settings.get(defs.btproxyEnabled)) return;
    await _settings.set(defs.btproxyEnabled, false);
    final why = support.hint ?? 'Not available on this device.';
    log.warn(
      name,
      'Bluetooth proxy kept off: ${why[0].toLowerCase()}${why.substring(1)}',
    );
  }

  /// The port Home Assistant is told the kiosk's web page is on, which it
  /// turns into the Visit link on the ESPHome device page: the remote admin
  /// page's port while that server is meant to serve (switched on with a
  /// password set, the same rule the remote manager runs on), else 0 for
  /// no link at all.
  int _webserverPort() {
    if (!_settings.get(defs.remoteEnabled) ||
        _settings.get(defs.remoteTls) ||
        _settings.get(defs.remotePassword).isEmpty) {
      return 0;
    }
    return _settings.get(defs.remotePort).toInt();
  }

  /// Check BLE support before the server first advertises its capabilities.
  /// The app version is also needed only when the server starts.
  Future<void> _ensureStartPrereqs() async {
    await _guardBleSupport();
    if (_appVersion == '0') {
      final version = await commands.execute('getDeviceInfo', const {});
      _appVersion = ((version.data as Map?)?['appVersion'] as String?) ?? '0';
    }
  }

  Future<void> _start() async {
    await _ensureStartPrereqs();
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
    final port = int.tryParse(_settings.get(defs.btproxyPort).trim()) ?? 6053;
    // Null while the setting is off or the platform hides the address; the
    // native side then keeps its synthetic identity (issue #252).
    final realMac = await adoptedWifiMac(_settings);
    final webserverPort = _webserverPort();
    try {
      final resolved = await _channel.invokeMethod<String>('start', {
        'friendlyName': friendly.isEmpty ? 'Kiosk Satellite' : friendly,
        'psk': key,
        'port': port,
        'projectVersion': _appVersion,
        'bluetoothProxy': _settings.get(defs.btproxyEnabled),
        'connections': _settings.get(defs.btproxyConnections),
        'scanDuty': _settings.get(defs.btproxyScanDuty),
        'screenOffScan': _settings.get(defs.btproxyScreenOffScan),
        'minConnectRssi':
            int.tryParse(_settings.get(defs.btproxyMinConnectRssi)) ?? 0,
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
        // The remote admin page's port, for the Visit link on the device
        // page in Home Assistant; 0 keeps the field, and the link, off.
        'webserverPort': webserverPort,
        // The Assist satellite: Home Assistant creates it on this device.
        'voice': _voiceWanted,
      });
      _voiceLive = _voiceWanted;
      _running = true;
      _startError = null;
      _liveWebserverPort = webserverPort;
      _liveMac = realMac;
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
          (objectId, value) => _channel.invokeMethod('entityState', {
            'objectId': objectId,
            'value': value,
          }),
          (objectId, jpeg) => _channel.invokeMethod('cameraImage', {
            'objectId': objectId,
            'jpeg': jpeg,
          }),
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

  Future<void> _pushScanDuty() async {
    try {
      await _channel.invokeMethod('scanDuty', {
        'duty': _settings.get(defs.btproxyScanDuty),
      });
    } catch (e) {
      log.warn(name, 'scan intensity not applied: $e');
    }
  }

  Future<void> _pushScreenOffScan() async {
    try {
      await _channel.invokeMethod('screenOffScan', {
        'enabled': _settings.get(defs.btproxyScreenOffScan),
      });
    } catch (e) {
      log.warn(name, 'screen-off scanning not applied: $e');
    }
  }

  Future<void> _stop() async {
    _startError = null;
    if (!_running) return;
    _running = false;
    _voiceLive = false;
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
