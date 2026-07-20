import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// Ready-made Home Assistant entities over MQTT discovery (issue #11).
///
/// A thin protocol adapter, exactly like the JS API and the remote REST/WS
/// API: commands arriving on MQTT route through the [CommandRegistry], state
/// leaves as retained topics fed by the same bus events every other surface
/// consumes. Nothing here talks to another manager directly.
///
/// Multi-device by construction: every topic and unique_id hangs off a
/// per-install random id (persisted in [defs.mqttDeviceId]), so any number
/// of tablets can share one broker and one Home Assistant instance without
/// colliding, each grouped under its own HA device.
///
/// Entities (per device):
///  - light "Screen": on/off is real display power (screenOn / device-admin
///    screenOff), brightness is the panel backlight. When the screen-off
///    grant is missing the command fails and the true state is republished,
///    so the HA toggle snaps back instead of lying.
///  - sensor "Battery" and binary_sensor "Charging", polled once a minute.
///  - sensor "Current page": the URL the kiosk is showing (diagnostic).
///  - binary_sensor "Screensaver": whether the screensaver is up.
class MqttManager extends Manager {
  MqttManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'mqtt';

  MqttServerClient? _client;
  Timer? _pollTimer;
  Timer? _reconnectDebounce;
  final _subs = <StreamSubscription>[];

  /// Serialises enable/disable/reconnect so a settings burst cannot
  /// interleave two connection attempts.
  Future<void> _transition = Future.value();

  String _deviceId = '';
  int? _lastBattery;
  bool? _lastCharging;
  int? _lastCpu;
  int? _lastRamFreeMb;
  int? _lastRamTotalMb;

  /// Mirrored from bus events so the true value survives disconnects: the
  /// initial publish after (re)connecting must report the state the device
  /// is actually in, not a hardcoded default — a screensaver already on
  /// screen when the broker link comes up was previously reported OFF until
  /// the next transition.
  bool _screensaverActive = false;

  // Retained device metadata for discovery, read once via getDeviceInfo.
  Map<String, Object?> _deviceInfo = const {};

  String get _base => 'kiosksatellite/$_deviceId';
  String get _availabilityTopic => '$_base/availability';
  String get _prefix {
    final p = _settings.get(defs.mqttDiscoveryPrefix).trim();
    return p.isEmpty ? 'homeassistant' : p;
  }

  @override
  Future<void> init() async {
    // The per-install identity every topic hangs off. Generated once;
    // surviving restarts is what keeps the HA device stable.
    _deviceId = _settings.get(defs.mqttDeviceId);
    if (_deviceId.isEmpty) {
      final rng = Random.secure();
      _deviceId = List.generate(8, (_) => rng.nextInt(16).toRadixString(16))
          .join();
      await _settings.set(defs.mqttDeviceId, _deviceId);
    }

    _subs.add(bus.on<SettingChanged>().listen(_onSettingChanged));
    _subs.add(bus.on<ScreenStateChanged>().listen(
        (e) => _publish('$_base/screen/state', e.on ? 'ON' : 'OFF')));
    _subs.add(bus.on<BrightnessChanged>().listen((e) => _publish(
        '$_base/brightness/state',
        (e.level.clamp(0.0, 1.0) * 255).round().toString())));
    _subs.add(bus.on<PageChanged>().listen(
        (e) => _publish('$_base/url/state', e.url)));
    _subs.add(bus.on<ScreensaverStateChanged>().listen((e) {
      _screensaverActive = e.active;
      _publish('$_base/screensaver/state', e.active ? 'ON' : 'OFF');
    }));

    if (_settings.get(defs.mqttEnabled)) {
      _transition = _transition.then((_) => _connect());
    }
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _reconnectDebounce?.cancel();
    await _disconnect(clearDiscovery: false);
  }

  /// The setting-backed switches: object id → (setting read, apply). The
  /// HA-kiosk one is a select underneath ('off'/'auto'/'plugin'/'css'); its
  /// switch reads "anything but off" and writes auto/off, leaving a
  /// hand-picked plugin/css choice alone until someone actually flips it.
  Map<String, (bool Function(), Future<void> Function(bool))>
      get _settingSwitches => {
            'kiosk': (
              () => _settings.get(defs.kioskEnabled),
              (on) => _settings.set(defs.kioskEnabled, on),
            ),
            'ha_kiosk': (
              () => _settings.get(defs.haKioskMode) != 'off',
              (on) => _settings.set(defs.haKioskMode, on ? 'auto' : 'off'),
            ),
            'keep_screen_on': (
              () => _settings.get(defs.keepScreenOn),
              (on) => _settings.set(defs.keepScreenOn, on),
            ),
            'remote': (
              () => _settings.get(defs.remoteEnabled),
              (on) => _settings.set(defs.remoteEnabled, on),
            ),
          };

  static const _switchSettingKeys = [
    'kiosk.enabled',
    'ha.kiosk_mode',
    'screen.keep_on',
    'remote.enabled',
  ];

  void _publishSettingSwitchStates() {
    _settingSwitches.forEach((objectId, actions) =>
        _publish('$_base/$objectId/state', actions.$1() ? 'ON' : 'OFF'));
  }

  void _onSettingChanged(SettingChanged e) {
    if (e.key == defs.deviceName.key) {
      // The HA device is named after the kiosk; keep them in step.
      if (_connected) _publishDiscovery();
      return;
    }
    if (_switchSettingKeys.contains(e.key)) {
      // Whatever surface flipped it (device UI, remote admin, MQTT itself),
      // the switch in HA reflects it.
      _publishSettingSwitchStates();
      return;
    }
    if (!e.key.startsWith('mqtt.') || e.key == defs.mqttDeviceId.key) return;
    // Debounced: the settings UI fires one change per keystroke-commit and
    // a fresh TCP connection per field would hammer the broker.
    _reconnectDebounce?.cancel();
    _reconnectDebounce = Timer(const Duration(seconds: 1), () {
      _transition = _transition.then((_) async {
        await _disconnect(
            clearDiscovery: !_settings.get(defs.mqttEnabled));
        if (_settings.get(defs.mqttEnabled)) await _connect();
      });
    });
  }

  bool get _connected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> _connect() async {
    final host = _settings.get(defs.mqttHost).trim();
    if (host.isEmpty) {
      log.warn(name, 'enabled but no broker host set; not connecting');
      return;
    }
    final port = _settings.get(defs.mqttPort).toInt();
    final client = MqttServerClient.withPort(
        host, 'kiosksatellite_$_deviceId', port);
    client.secure = _settings.get(defs.mqttTls);
    client.keepAlivePeriod = 30;
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;
    client.setProtocolV311();
    client.logging(on: false);
    // The will is what makes `availability` honest: the broker flips this
    // device to offline the moment the connection dies, however it dies.
    client.connectionMessage = MqttConnectMessage()
        .withWillTopic(_availabilityTopic)
        .withWillMessage('offline')
        .withWillRetain()
        .withWillQos(MqttQos.atLeastOnce)
        .startClean();
    client.onConnected = _onConnected;
    client.onAutoReconnected = _onConnected;
    client.onDisconnected =
        () => log.warn(name, 'disconnected from $host:$port');
    _client = client;

    final username = _settings.get(defs.mqttUsername).trim();
    final password = _settings.get(defs.mqttPassword);
    try {
      await client.connect(
        username.isEmpty ? null : username,
        password.isEmpty ? null : password,
      );
    } catch (e) {
      log.warn(name, 'connect to $host:$port failed: $e');
      client.disconnect();
      return;
    }
    if (!_connected) {
      log.warn(name,
          'connect to $host:$port refused: ${client.connectionStatus}');
      return;
    }

    client.updates?.listen(_onMessage);
    for (final topic in [
      '$_base/screen/set',
      '$_base/brightness/set',
      '$_base/screensaver/set',
      '$_base/reload/set',
      '$_base/clear_cache/set',
      for (final objectId in _settingSwitches.keys) '$_base/$objectId/set',
    ]) {
      client.subscribe(topic, MqttQos.atLeastOnce);
    }
  }

  DateTime _lastBringUp = DateTime.fromMillisecondsSinceEpoch(0);
  bool _bringingUp = false;
  final _reconnectTimes = <DateTime>[];

  /// Runs on connect AND auto-reconnect, deliberately NOT inline: doing the
  /// bring-up (retained publishes, subscriptions' worth of traffic) inside
  /// the client's connection callback can wedge the still-settling
  /// connection, which drops it, which reconnects, which runs the callback
  /// again — a storm of reconnects every few dozen milliseconds (seen on
  /// both test devices). Deferring off the callback and throttling makes a
  /// reconnect cycle nearly free, so even a flapping network cannot amplify.
  void _onConnected() {
    // Storm breaker on top of the deferral below: if the connection is
    // genuinely cycling (broker kicking us, network flapping), stop feeding
    // it — tear down and try again fresh in 30 seconds.
    final now = DateTime.now();
    _reconnectTimes.add(now);
    _reconnectTimes.removeWhere((t) => now.difference(t).inSeconds > 30);
    if (_reconnectTimes.length > 10) {
      log.warn(name, 'MQTT reconnect storm; backing off for 30 seconds');
      _reconnectTimes.clear();
      _transition = _transition.then((_) async {
        await _disconnect(clearDiscovery: false);
        await Future<void>.delayed(const Duration(seconds: 30));
        if (_settings.get(defs.mqttEnabled)) await _connect();
      });
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 500), () async {
      if (!_connected || _bringingUp) return;
      if (DateTime.now().difference(_lastBringUp).inSeconds < 2) return;
      _bringingUp = true;
      _lastBringUp = DateTime.now();
      try {
        await _bringUp();
      } finally {
        _bringingUp = false;
      }
    });
  }

  Future<void> _bringUp() async {
    log.info(name, 'connected as kiosksatellite_$_deviceId');
    if (_deviceInfo.isEmpty) {
      final info = await commands.execute('getDeviceInfo', const {});
      if (info.ok && info.data is Map) {
        _deviceInfo = (info.data as Map).cast<String, Object?>();
      }
    }
    _publish(_availabilityTopic, 'online');
    _publishDiscovery();
    await _publishInitialStates();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
        const Duration(seconds: 60), (_) => _pollStats());
    await _pollStats();
  }

  Future<void> _disconnect({required bool clearDiscovery}) async {
    _pollTimer?.cancel();
    _pollTimer = null;
    final client = _client;
    _client = null;
    if (client == null) return;
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      if (clearDiscovery) {
        // Feature turned off: retract the entities. An empty retained
        // config payload is how HA discovery removes a device cleanly.
        for (final topic in _discoveryTopics()) {
          client.publishMessage(topic, MqttQos.atLeastOnce,
              MqttClientPayloadBuilder().payload!,
              retain: true);
        }
      }
      // A graceful disconnect never fires the will; say goodbye ourselves.
      client.publishMessage(
          _availabilityTopic,
          MqttQos.atLeastOnce,
          (MqttClientPayloadBuilder()..addUTF8String('offline')).payload!,
          retain: true);
    }
    client.autoReconnect = false;
    client.disconnect();
  }

  // ── Incoming commands ───────────────────────────────────────────────

  Future<void> _onMessage(List<MqttReceivedMessage<MqttMessage>> batch) async {
    for (final received in batch) {
      final payload = received.payload;
      if (payload is! MqttPublishMessage) continue;
      final text = MqttPublishPayload.bytesToStringAsString(
          payload.payload.message);
      final topic = received.topic;
      if (topic == '$_base/screen/set') {
        log.info(name, 'command $topic = $text');
        if (text == 'ON') {
          await commands.execute('screenOn', const {});
        } else {
          final result = await commands.execute('screenOff', const {});
          if (!result.ok) {
            // No device-admin grant: nothing happened. Republish the truth
            // so the HA toggle snaps back instead of showing a lie.
            log.warn(name, 'screenOff over MQTT failed: ${result.error}');
            final on = await commands.execute('isScreenOn', const {});
            _publish('$_base/screen/state',
                on.ok && on.data == false ? 'OFF' : 'ON');
          }
        }
      } else if (topic == '$_base/brightness/set') {
        log.info(name, 'command $topic = $text');
        final raw = int.tryParse(text);
        if (raw == null) continue;
        await commands.execute(
            'setBrightness', {'level': (raw.clamp(0, 255)) / 255});
      } else if (topic == '$_base/screensaver/set') {
        log.info(name, 'command $topic = $text');
        await commands.execute(
            text == 'ON' ? 'startScreensaver' : 'stopScreensaver', const {});
      } else if (topic == '$_base/reload/set') {
        log.info(name, 'command $topic');
        await commands.execute('reload', const {});
      } else if (topic == '$_base/clear_cache/set') {
        log.info(name, 'command $topic');
        await commands.execute('clearWebCache', const {});
      } else {
        for (final entry in _settingSwitches.entries) {
          if (topic != '$_base/${entry.key}/set') continue;
          log.info(name, 'command $topic = $text');
          await entry.value.$2(text == 'ON');
          break;
        }
      }
    }
  }

  // ── Outgoing state ──────────────────────────────────────────────────

  void _publish(String topic, String payload) {
    final client = _client;
    if (client == null || !_connected) return;
    try {
      client.publishMessage(topic, MqttQos.atLeastOnce,
          (MqttClientPayloadBuilder()..addUTF8String(payload)).payload!,
          retain: true);
    } catch (e) {
      log.warn(name, 'publish to $topic failed: $e');
    }
  }

  Future<void> _publishInitialStates() async {
    final on = await commands.execute('isScreenOn', const {});
    if (on.ok) _publish('$_base/screen/state', on.data == true ? 'ON' : 'OFF');
    final brightness = await commands.execute('getBrightness', const {});
    final level = brightness.data;
    if (brightness.ok && level is num) {
      _publish('$_base/brightness/state',
          (level.clamp(0.0, 1.0) * 255).round().toString());
    }
    _publish('$_base/screensaver/state', _screensaverActive ? 'ON' : 'OFF');
    _publishSettingSwitchStates();
  }

  Future<void> _pollStats() async {
    if (!_connected) return;
    final result = await commands.execute('getStats', const {});
    final data = result.data;
    if (!result.ok || data is! Map) return;
    final battery = (data['battery'] as num?)?.toInt();
    final charging = data['charging'] == true;
    final cpu = (data['cpu'] as num?)?.round();
    if (battery != null && battery != _lastBattery) {
      _lastBattery = battery;
      _publish('$_base/battery/state', '$battery');
    }
    if (charging != _lastCharging) {
      _lastCharging = charging;
      _publish('$_base/charging/state', charging ? 'ON' : 'OFF');
    }
    if (cpu != null && cpu != _lastCpu) {
      _lastCpu = cpu;
      _publish('$_base/cpu/state', '$cpu');
    }
    // RAM rides the same tick from the fuller details read; once a minute
    // is nothing, and it saves a second platform channel.
    final details = await commands.execute('getDeviceDetails', const {});
    final ram = details.ok && details.data is Map
        ? ((details.data as Map)['ram'] as Map?)
        : null;
    if (ram != null) {
      final freeMb = ((ram['free'] as num?) ?? 0) ~/ (1024 * 1024);
      final totalMb = ((ram['total'] as num?) ?? 0) ~/ (1024 * 1024);
      if (freeMb > 0 && freeMb != _lastRamFreeMb) {
        _lastRamFreeMb = freeMb;
        _publish('$_base/ram_free/state', '$freeMb');
      }
      if (totalMb > 0 && totalMb != _lastRamTotalMb) {
        _lastRamTotalMb = totalMb;
        _publish('$_base/ram_total/state', '$totalMb');
      }
    }
  }

  // ── Discovery ───────────────────────────────────────────────────────

  List<String> _discoveryTopics() => [
        '$_prefix/light/ks_$_deviceId/screen/config',
        '$_prefix/sensor/ks_$_deviceId/battery/config',
        '$_prefix/binary_sensor/ks_$_deviceId/charging/config',
        '$_prefix/sensor/ks_$_deviceId/url/config',
        '$_prefix/sensor/ks_$_deviceId/cpu/config',
        '$_prefix/sensor/ks_$_deviceId/ram_free/config',
        '$_prefix/sensor/ks_$_deviceId/ram_total/config',
        '$_prefix/switch/ks_$_deviceId/screensaver/config',
        '$_prefix/button/ks_$_deviceId/reload/config',
        '$_prefix/button/ks_$_deviceId/clear_cache/config',
        for (final objectId in _settingSwitches.keys)
          '$_prefix/switch/ks_$_deviceId/$objectId/config',
      ];

  /// Config topics of entities that shipped in earlier builds under another
  /// component and moved since (the screensaver was a binary_sensor before
  /// it grew a command side). Retracted on every discovery publish so an
  /// upgraded device does not leave a dead twin behind in HA.
  List<String> _legacyDiscoveryTopics() => [
        '$_prefix/binary_sensor/ks_$_deviceId/screensaver/config',
      ];

  void _publishDiscovery() {
    final configuredName = _settings.get(defs.deviceName).trim();
    final model = _deviceInfo['model'];
    final deviceBlock = {
      'identifiers': ['ks_$_deviceId'],
      'name': configuredName.isEmpty
          ? (model is String && model.isNotEmpty
              ? model
              : 'Kiosk Satellite')
          : configuredName,
      'manufacturer': 'Kiosk Satellite',
      if (model is String && model.isNotEmpty) 'model': model,
      if (_deviceInfo['appVersion'] is String)
        'sw_version': _deviceInfo['appVersion'],
    };
    final origin = {
      'name': 'Kiosk Satellite',
      if (_deviceInfo['appVersion'] is String)
        'sw': _deviceInfo['appVersion'],
      'url': 'https://github.com/jxlarrea/kiosk-satellite',
    };
    Map<String, Object?> common(String objectId, String entityName) => {
          'unique_id': 'ks_${_deviceId}_$objectId',
          'name': entityName,
          'availability_topic': _availabilityTopic,
          'device': deviceBlock,
          'origin': origin,
        };

    Map<String, Object?> settingSwitch(String objectId, String entityName,
            String icon) =>
        {
          ...common(objectId, entityName),
          'state_topic': '$_base/$objectId/state',
          'command_topic': '$_base/$objectId/set',
          'icon': icon,
          'entity_category': 'config',
        };

    final configs = <String, Map<String, Object?>>{
      '$_prefix/light/ks_$_deviceId/screen/config': {
        ...common('screen', 'Screen'),
        'state_topic': '$_base/screen/state',
        'command_topic': '$_base/screen/set',
        'brightness_state_topic': '$_base/brightness/state',
        'brightness_command_topic': '$_base/brightness/set',
        'brightness_scale': 255,
        'icon': 'mdi:tablet',
      },
      '$_prefix/sensor/ks_$_deviceId/battery/config': {
        ...common('battery', 'Battery'),
        'state_topic': '$_base/battery/state',
        'device_class': 'battery',
        'unit_of_measurement': '%',
        'state_class': 'measurement',
        'entity_category': 'diagnostic',
      },
      '$_prefix/binary_sensor/ks_$_deviceId/charging/config': {
        ...common('charging', 'Charging'),
        'state_topic': '$_base/charging/state',
        'device_class': 'battery_charging',
        'entity_category': 'diagnostic',
      },
      '$_prefix/sensor/ks_$_deviceId/url/config': {
        ...common('url', 'Current page'),
        'state_topic': '$_base/url/state',
        'icon': 'mdi:web',
        'entity_category': 'diagnostic',
      },
      '$_prefix/sensor/ks_$_deviceId/cpu/config': {
        ...common('cpu', 'CPU usage'),
        'state_topic': '$_base/cpu/state',
        'unit_of_measurement': '%',
        'state_class': 'measurement',
        'icon': 'mdi:chip',
        'entity_category': 'diagnostic',
      },
      '$_prefix/sensor/ks_$_deviceId/ram_free/config': {
        ...common('ram_free', 'RAM available'),
        'state_topic': '$_base/ram_free/state',
        'device_class': 'data_size',
        'unit_of_measurement': 'MB',
        'state_class': 'measurement',
        'icon': 'mdi:memory',
        'entity_category': 'diagnostic',
      },
      '$_prefix/sensor/ks_$_deviceId/ram_total/config': {
        ...common('ram_total', 'RAM total'),
        'state_topic': '$_base/ram_total/state',
        'device_class': 'data_size',
        'unit_of_measurement': 'MB',
        'icon': 'mdi:memory',
        'entity_category': 'diagnostic',
      },
      '$_prefix/switch/ks_$_deviceId/screensaver/config': {
        ...common('screensaver', 'Screensaver'),
        'state_topic': '$_base/screensaver/state',
        'command_topic': '$_base/screensaver/set',
        'icon': 'mdi:sleep',
      },
      '$_prefix/button/ks_$_deviceId/reload/config': {
        ...common('reload', 'Reload page'),
        'command_topic': '$_base/reload/set',
        'icon': 'mdi:refresh',
      },
      '$_prefix/button/ks_$_deviceId/clear_cache/config': {
        ...common('clear_cache', 'Clear cache'),
        'command_topic': '$_base/clear_cache/set',
        'icon': 'mdi:broom',
        'entity_category': 'config',
      },
      '$_prefix/switch/ks_$_deviceId/kiosk/config':
          settingSwitch('kiosk', 'Kiosk mode', 'mdi:lock-outline'),
      '$_prefix/switch/ks_$_deviceId/ha_kiosk/config':
          settingSwitch('ha_kiosk', 'HA kiosk mode', 'mdi:dock-top'),
      '$_prefix/switch/ks_$_deviceId/keep_screen_on/config': settingSwitch(
          'keep_screen_on', 'Keep screen on', 'mdi:lightbulb-on-outline'),
      '$_prefix/switch/ks_$_deviceId/remote/config': settingSwitch(
          'remote', 'Remote management', 'mdi:remote-desktop'),
    };
    for (final topic in _legacyDiscoveryTopics()) {
      _publish(topic, '');
    }
    configs.forEach((topic, config) => _publish(topic, jsonEncode(config)));
  }
}
