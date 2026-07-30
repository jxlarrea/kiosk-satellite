import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart' show Uint8Buffer;

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
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSub;
  Timer? _reconnectDebounce;
  final _subs = <StreamSubscription>[];

  /// Serialises enable/disable/reconnect so a settings burst cannot
  /// interleave two connection attempts.
  Future<void> _transition = Future.value();

  String _deviceId = '';
  int? _lastBattery;
  bool? _lastCharging;
  int? _lastCpu;
  int? _lastCpuTemp;
  int? _lastRamFreeMb;
  int? _lastRamTotalMb;
  List<Map<String, Object?>> _cameraViews = const [];
  Set<String> _publishedCameraViewIds = {};

  /// The dashboard view select's options: navigation paths
  /// ("url_path/view-route", or a bare "url_path" for a dashboard whose
  /// view list cannot be read). Refreshed from HA and persisted so the
  /// entity survives a restart that comes up before HA does.
  List<String> _dashboardViews = const [];

  /// Guards concurrent refreshes (bring-up, page loads, and the poll
  /// timer can all ask at once).
  bool _refreshingDashboardViews = false;

  /// Mirrored from bus events so the true value survives disconnects: the
  /// initial publish after (re)connecting must report the state the device
  /// is actually in, not a hardcoded default — a screensaver already on
  /// screen when the broker link comes up was previously reported OFF until
  /// the next transition.
  bool _screensaverActive = false;

  // Retained device metadata for discovery, read once via getDeviceInfo.
  Map<String, Object?> _deviceInfo = const {};

  /// Whether this device has an ambient light sensor (read at connect).
  bool _lightSensorPresent = false;

  /// Whether this device has a usable camera (read at connect, like the
  /// light sensor). A ROM without a camera HAL gets no camera entities at
  /// all, whatever the camera settings say.
  bool _cameraPresent = true;

  bool get _cameraEntitiesWanted =>
      _settings.get(defs.cameraEnabled) && _cameraPresent;

  /// Rate limiting for the illuminance publishes: the recorder does not need
  /// every damped native event, but big swings (lights on) should land now.
  double? _lastLuxPublished;
  DateTime _lastLuxPublishedAt = DateTime.fromMillisecondsSinceEpoch(0);

  String get _base => 'kiosksatellite/$_deviceId';
  String get _availabilityTopic => '$_base/availability';
  String get _prefix {
    final p = _settings.get(defs.mqttDiscoveryPrefix).trim();
    return p.isEmpty ? 'homeassistant' : p;
  }

  @override
  Future<void> init() async {
    _subs.add(bus.on<SettingChanged>().listen(_onSettingChanged));
    _subs.add(bus.on<ScreenStateChanged>().listen(
        (e) => _publish('$_base/screen/state', e.on ? 'ON' : 'OFF')));
    _subs.add(bus.on<BrightnessChanged>().listen((e) => _publish(
        '$_base/brightness/state',
        (e.level.clamp(0.0, 1.0) * 255).round().toString())));
    _subs.add(bus.on<PageChanged>().listen((e) {
      _publish('$_base/url/state', e.url);
      _publishDashboardViewState(e.url);
      // A full load means HA may have just come up (login, reload): a good
      // moment to learn the view list. Slightly deferred so the frontend
      // has a hass to answer with.
      Timer(const Duration(seconds: 5), () {
        if (_connected) unawaited(_refreshDashboardViews());
      });
    }));
    // SPA navigations (view switches) never hit PageChanged; this keeps
    // the url sensor and the dashboard view select honest between loads.
    _subs.add(bus.on<UrlChanged>().listen((e) {
      _publish('$_base/url/state', e.url);
      _publishDashboardViewState(e.url);
    }));
    _subs.add(bus.on<ScreensaverStateChanged>().listen((e) {
      _screensaverActive = e.active;
      _publish('$_base/screensaver/state', e.active ? 'ON' : 'OFF');
    }));
    // Covers every path the volume moves: an MQTT command, the hardware
    // rocker, another app (the platform side broadcasts them all).
    _subs.add(bus.on<VolumeChanged>().listen((_) => _publishVolume()));
    // The updater already throttles progress to whole percents.
    _subs.add(
        bus.on<UpdateStateChanged>().listen((_) => _publishUpdateState()));
    _subs.add(bus.on<CameraConfigurationChanged>().listen((_) async {
      await _refreshCameraViews();
      if (_connected) await _publishDiscovery();
    }));
    _subs.add(bus.on<CameraViewStateChanged>().listen(_publishCameraViewState));
    // Every capture the device camera manager makes (interval, the HA
    // button, the remote admin) lands on the camera entity. Retained, so
    // the entity has a picture right after an HA restart. The timestamp
    // rides along: the camera entity's own state never moves (a still
    // camera is forever "idle"), so the Last snapshot sensor is how HA can
    // see, and automate on, frame freshness.
    _subs.add(bus.on<CameraSnapshotTaken>().listen((e) {
      _publishBytes('$_base/camera_snapshot/image', e.jpeg);
      _publish('$_base/camera_snapshot/at',
          DateTime.now().toUtc().toIso8601String());
    }));
    _subs.add(bus.on<NextAlarmChanged>().listen((_) => _publishNextAlarm()));
    _subs.add(bus.on<AmbientDisplayChanged>().listen(
        (e) => _publishScreenAvailability(ambient: e.on)));
    // The native side damps flicker; this only guards the recorder's disk:
    // at most one publish per 15s, unless the level swung hard (lights on).
    _subs.add(bus.on<LightLevelChanged>().listen((e) {
      if (!_lightSensorPresent) return;
      final last = _lastLuxPublished;
      final delta = last == null ? double.infinity : (e.lux - last).abs();
      final elapsed = DateTime.now().difference(_lastLuxPublishedAt);
      if (elapsed.inSeconds < 15 && delta < 50 && delta < (last ?? 0) * 0.5) {
        return;
      }
      _lastLuxPublished = e.lux;
      _lastLuxPublishedAt = DateTime.now();
      _publish('$_base/illuminance/state', e.lux.round().toString());
    }));

    await _refreshCameraViews();
    try {
      final views = jsonDecode(_settings.internal('mqtt_dashboard_views'));
      if (views is List) {
        _dashboardViews = [
          for (final v in views)
            if (v is String && v.isNotEmpty) v,
        ];
      }
    } catch (_) {}
    try {
      final persisted = jsonDecode(_settings.internal('mqtt_camera_view_ids'));
      if (persisted is List) {
        _publishedCameraViewIds = {
          for (final id in persisted)
            if (id is String) id,
        };
      }
    } catch (_) {}

    commands.register(
      Command(
        name: 'mqttValidate',
        description:
            'Open a throwaway connection to the configured broker and '
            'report whether it accepts these settings. Reports the live '
            'connection instead when MQTT is already running.',
        handler: (_) async => _validate(),
      ),
    );

    if (_settings.get(defs.mqttEnabled)) {
      _transition = _transition.then((_) => _connect());
    }
  }

  /// A one-shot credentials check, on its own client id so it never knocks
  /// the running session off a broker that allows a single session per user.
  /// While MQTT is on and up, the live connection is the honest answer.
  Future<CommandResult> _validate() async {
    final host = _settings.get(defs.mqttHost).trim();
    if (host.isEmpty) return const CommandResult.fail('No broker set.');
    final port = _settings.get(defs.mqttPort).toInt();
    if (_connected) {
      return CommandResult.ok({'connected': true, 'host': host, 'port': port});
    }
    final probe = MqttServerClient.withPort(
      host,
      'kiosksatellite_probe_${DateTime.now().millisecondsSinceEpoch}',
      port,
    );
    probe.secure = _settings.get(defs.mqttTls);
    probe.autoReconnect = false;
    probe.keepAlivePeriod = 10;
    probe.connectTimeoutPeriod = 8000;
    probe.setProtocolV311();
    probe.logging(on: false);
    probe.connectionMessage = MqttConnectMessage().startClean();
    final username = _settings.get(defs.mqttUsername).trim();
    final password = _settings.get(defs.mqttPassword);
    try {
      await probe.connect(
        username.isEmpty ? null : username,
        password.isEmpty ? null : password,
      );
      final state = probe.connectionStatus?.state;
      if (state != MqttConnectionState.connected) {
        return CommandResult.fail(
          _validationError(probe.connectionStatus?.returnCode),
        );
      }
      return CommandResult.ok({'connected': true, 'host': host, 'port': port});
    } catch (e) {
      log.warn(name, 'validation against $host:$port failed: $e');
      return CommandResult.fail(_connectException(e, host, port));
    } finally {
      probe.disconnect();
    }
  }

  String _validationError(MqttConnectReturnCode? code) => switch (code) {
    MqttConnectReturnCode.badUsernameOrPassword =>
      'The broker rejected the username or password.',
    MqttConnectReturnCode.notAuthorized =>
      'The broker refused this client. Check its access control rules.',
    MqttConnectReturnCode.identifierRejected =>
      'The broker rejected the client id.',
    MqttConnectReturnCode.brokerUnavailable => 'The broker is unavailable.',
    MqttConnectReturnCode.unacceptedProtocolVersion =>
      'The broker does not accept MQTT 3.1.1.',
    _ => 'The broker refused the connection.',
  };

  String _connectException(Object error, String host, int port) {
    final text = '$error';
    if (text.contains('SocketException') || text.contains('timed out')) {
      return 'Could not reach $host:$port.';
    }
    if (text.contains('HandshakeException') ||
        text.contains('CertificateException')) {
      return 'TLS handshake failed. Check the Use TLS setting and the '
          "broker's certificate.";
    }
    return 'Could not connect to $host:$port.';
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
            'screensaver_brightness': (
              () => _settings.get(defs.screensaverBrightnessEnabled),
              (on) => _settings.set(defs.screensaverBrightnessEnabled, on),
            ),
          };

  static const _switchSettingKeys = [
    'kiosk.enabled',
    'ha.kiosk_mode',
    'screen.keep_on',
    'remote.enabled',
    'screensaver.brightness_enabled',
  ];

  /// The setting-backed dropdowns: object id → (definition, entity name,
  /// icon). HA shows the definition's display labels; state publishes are
  /// mapped to labels and incoming commands mapped back to the stored value,
  /// so the stored vocabulary never leaks into the HA UI. The HA-kiosk one
  /// deliberately sits NEXT TO its switch: the switch stays the simple
  /// toggle, the select is where a plugin/css strategy can actually be
  /// picked from Home Assistant.
  static const _settingSelects =
      <String, (defs.SettingDef<String>, String, String)>{
    'screensaver_mode': (
      defs.screensaverMode,
      'Screensaver mode',
      'mdi:monitor-shimmer',
    ),
    'screensaver_clock_style': (
      defs.screensaverClockStyle,
      'Clock style',
      'mdi:clock-digital',
    ),
    'ha_kiosk_method': (
      defs.haKioskMode,
      'HA kiosk method',
      'mdi:page-layout-header',
    ),
  };

  bool _isSelectSettingKey(String key) =>
      _settingSelects.values.any((s) => s.$1.key == key);

  void _publishSettingSwitchStates() {
    _settingSwitches.forEach((objectId, actions) =>
        _publish('$_base/$objectId/state', actions.$1() ? 'ON' : 'OFF'));
  }

  void _publishSettingSelectStates() {
    _settingSelects.forEach((objectId, entry) {
      final (def, _, _) = entry;
      final value = _settings.get(def);
      _publish('$_base/$objectId/state', def.optionLabels?[value] ?? value);
    });
  }

  void _publishScreensaverBrightnessLevel() {
    final level = _settings.get(defs.screensaverBrightnessLevel).toDouble();
    _publish('$_base/screensaver_brightness_level/state',
        (level.clamp(0.0, 1.0) * 100).round().toString());
  }

  void _publishAssistantVolume() {
    final pct = _settings.get(defs.assistantVolume).toDouble();
    _publish('$_base/assistant_volume/state',
        pct.clamp(0.0, 100.0).round().toString());
  }

  void _publishMediaVolume() {
    final pct = _settings.get(defs.mediaVolume).toDouble();
    _publish(
        '$_base/media_volume/state', pct.clamp(0.0, 100.0).round().toString());
  }

  /// The remote admin's address as a sensor, so a dashboard can deep-link
  /// straight into a device's admin from Home Assistant. 'disabled' when the
  /// remote admin is off.
  Future<void> _publishAdminUrl() async {
    if (!_settings.get(defs.remoteEnabled)) {
      _publish('$_base/admin_url/state', 'disabled');
      return;
    }
    final info = await commands.execute('getDeviceInfo', const {});
    final ip = info.ok && info.data is Map
        ? (info.data as Map)['ip'] as String?
        : null;
    if (ip == null || ip.isEmpty) return;
    final port = _settings.get(defs.remotePort).toInt();
    _publish('$_base/admin_url/state', 'http://$ip:$port');
  }

  Future<void> _publishVolume() async {
    final volume = await commands.execute('getVolume', const {});
    if (volume.ok) _publish('$_base/volume/state', '${volume.data}');
  }

  void _onSettingChanged(SettingChanged e) {
    if (e.key == defs.deviceName.key) {
      // The HA device is named after the kiosk; keep them in step.
      if (_connected) unawaited(_publishDiscovery());
      return;
    }
    if (_switchSettingKeys.contains(e.key) || _isSelectSettingKey(e.key)) {
      // Whatever surface flipped it (device UI, remote admin, MQTT itself),
      // the switch in HA reflects it. Both flavors publish together:
      // ha.kiosk_mode is switch- AND select-backed, and the others are
      // cheap retained no-ops.
      _publishSettingSwitchStates();
      _publishSettingSelectStates();
      if (e.key == defs.remoteEnabled.key) {
        // The admin URL sensor and the device page's "Visit" link
        // (configuration_url in the discovery device block) both follow it.
        unawaited(_publishAdminUrl());
        if (_connected) unawaited(_publishDiscovery());
      }
      return;
    }
    if (e.key == defs.screensaverBrightnessLevel.key) {
      _publishScreensaverBrightnessLevel();
      return;
    }
    if (e.key == defs.assistantVolume.key) {
      // Whatever surface moved it (device UI, remote admin, MQTT itself),
      // the HA slider reflects it.
      _publishAssistantVolume();
      return;
    }
    if (e.key == defs.mediaVolume.key) {
      // Same, plus the Sendspin server's commands land on this fader.
      _publishMediaVolume();
      return;
    }
    if (e.key == defs.remotePort.key) {
      unawaited(_publishAdminUrl());
      if (_connected) unawaited(_publishDiscovery());
      return;
    }
    if (e.key == defs.cameraEnabled.key) {
      if (!_connected) return;
      if (e.value == true && _cameraPresent) {
        unawaited(_publishDiscovery().then(
            (_) => commands.execute('takeCameraSnapshot', const {})));
      } else if (e.value == true) {
        // Enabled on a camera-less device: nothing to publish.
        return;
      } else {
        // Retract the entities and drop the retained frame: a disabled
        // camera should leave neither a dead entity nor a stale picture
        // parked on the broker.
        _publish('$_prefix/camera/ks_$_deviceId/device_camera/config', '');
        _publish('$_prefix/button/ks_$_deviceId/take_snapshot/config', '');
        _publish('$_prefix/sensor/ks_$_deviceId/last_snapshot/config', '');
        _publishBytes('$_base/camera_snapshot/image', const []);
        _publish('$_base/camera_snapshot/at', '');
      }
      return;
    }
    if (e.key == defs.mqttDeviceId.key) {
      // The echo of our own lazy generation changes nothing; a genuinely
      // different id (a restored backup, whose whole point is keeping the
      // HA device) falls through and reconnects under it.
      if ('${e.value}' == _deviceId) return;
    } else if (!e.key.startsWith('mqtt.')) {
      return;
    }
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
    // The per-install identity every topic hangs off. Re-read on EVERY
    // connect and minted only here, lazily: an eager init-time id on a
    // freshly set-up device gets replaced moments later by a restored
    // backup's id — and a cached copy then publishes a ghost HA device
    // (with retained configs that outlive it) under an id nothing will
    // ever use again.
    _deviceId = _settings.get(defs.mqttDeviceId);
    if (_deviceId.isEmpty) {
      final rng = Random.secure();
      _deviceId = List.generate(8, (_) => rng.nextInt(16).toRadixString(16))
          .join();
      await _settings.set(defs.mqttDeviceId, _deviceId);
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
      // Tear the client down like the exception branch does: left alive
      // with autoReconnect on, it would hammer a refusing broker (bad
      // credentials, ACL) on its own timer forever.
      client.autoReconnect = false;
      client.disconnect();
      _client = null;
      return;
    }

    _updatesSub = client.updates?.listen(_onMessage);
    for (final topic in [
      '$_base/screen/set',
      '$_base/brightness/set',
      '$_base/screensaver/set',
      '$_base/volume/set',
      '$_base/reload/set',
      '$_base/clear_cache/set',
      '$_base/restart/set',
      '$_base/bring_to_front/set',
      '$_base/update/set',
      '$_base/screensaver_brightness_level/set',
      '$_base/assistant_volume/set',
      '$_base/media_volume/set',
      '$_base/camera/view/set',
      '$_base/camera/close/set',
      '$_base/camera_snapshot/set',
      '$_base/dashboard_view/set',
      for (final objectId in _settingSwitches.keys) '$_base/$objectId/set',
      for (final objectId in _settingSelects.keys) '$_base/$objectId/set',
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
    // Hardware without a light sensor gets no illuminance entity at all: an
    // absent row beats a permanently unavailable one.
    final light = await commands.execute('getLightLevel', const {});
    _lightSensorPresent =
        light.ok && light.data is Map && (light.data as Map)['present'] == true;
    // Same rule for the camera: no hardware, no entities.
    final cam = await commands.execute('hasDeviceCamera', const {});
    _cameraPresent = !(cam.ok && cam.data == false);
    _publish(_availabilityTopic, 'online');
    await _publishDiscovery();
    await _publishInitialStates();
    // A fresh frame for the camera entity on every connect, so it never
    // shows a picture older than the link. Detached: a capture takes a
    // moment and the bring-up should not wait on the sensor.
    if (_cameraEntitiesWanted) {
      unawaited(commands.execute('takeCameraSnapshot', const {}));
    }
    // Learn the view list once the link is up; republishes discovery on
    // its own when the list moved.
    unawaited(_refreshDashboardViews());
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
        const Duration(seconds: 60), (_) => _pollStats());
    await _pollStats();
  }

  Future<void> _disconnect({required bool clearDiscovery}) async {
    _pollTimer?.cancel();
    _pollTimer = null;
    await _updatesSub?.cancel();
    _updatesSub = null;
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
      } else if (topic == '$_base/volume/set') {
        log.info(name, 'command $topic = $text');
        final percent = num.tryParse(text);
        if (percent == null) continue;
        // setVolume publishes VolumeChanged, whose listener republishes
        // the state — but the granular stream may land on the same step
        // it already had (no system broadcast); publish here regardless
        // so the HA slider always settles on the real value.
        await commands.execute('setVolume', {'percent': percent});
        await _publishVolume();
      } else if (topic == '$_base/reload/set') {
        log.info(name, 'command $topic');
        await commands.execute('reload', const {});
      } else if (topic == '$_base/clear_cache/set') {
        log.info(name, 'command $topic');
        await commands.execute('clearWebCache', const {});
      } else if (topic == '$_base/bring_to_front/set') {
        // Return from another app to the dashboard (issue #84): the button
        // face of the same bringToFront the REST automation recipe uses.
        log.info(name, 'command $topic');
        final result = await commands.execute('bringToFront', const {});
        if (result.data == false) {
          // Cannot come forward without the "Display over other apps"
          // grant; all MQTT can do is say why nothing moved.
          log.warn(name, 'bringToFront needs the overlay grant');
        }
      } else if (topic == '$_base/restart/set') {
        // The process dies mid-restart; the broker's will flips the device
        // offline and the relaunch brings everything back on its own.
        log.info(name, 'command $topic');
        final result = await commands.execute('restartApp', const {});
        if (!result.ok) {
          // Missing overlay grant: the command already sent the grant
          // screen to the device; all MQTT can do is say why nothing moved.
          log.warn(name, 'restartApp over MQTT refused: ${result.error}');
        }
      } else if (topic == '$_base/screensaver_brightness_level/set') {
        log.info(name, 'command $topic = $text');
        final percent = num.tryParse(text);
        if (percent == null) continue;
        await _settings.set(defs.screensaverBrightnessLevel,
            percent.clamp(0, 100) / 100);
      } else if (topic == '$_base/assistant_volume/set') {
        log.info(name, 'command $topic = $text');
        final percent = num.tryParse(text);
        if (percent == null) continue;
        await _settings.set(defs.assistantVolume, percent.clamp(0, 100));
      } else if (topic == '$_base/media_volume/set') {
        log.info(name, 'command $topic = $text');
        final percent = num.tryParse(text);
        if (percent == null) continue;
        await _settings.set(defs.mediaVolume, percent.clamp(0, 100));
      } else if (topic == '$_base/update/set') {
        log.info(name, 'command $topic');
        final result = await commands.execute('installUpdate', const {});
        if (!result.ok) {
          // Nothing started (no update, or one already running): republish
          // so HA's "installing" spinner does not sit on a lie.
          log.warn(name, 'installUpdate over MQTT failed: ${result.error}');
          await _publishUpdateState();
        }
      } else if (topic == '$_base/camera/view/set') {
        if (payload.header?.retain == true) {
          log.warn(name, 'ignored retained camera view command');
          continue;
        }
        log.info(name, 'camera view command');
        final result = await commands.execute('showCameraView', {
          'viewId': text,
        });
        if (!result.ok) {
          log.warn(name, 'showCameraView over MQTT failed: ${result.error}');
          await _publishCurrentCameraViewState();
        }
      } else if (topic == '$_base/dashboard_view/set') {
        if (payload.header?.retain == true) {
          log.warn(name, 'ignored retained dashboard view command');
          continue;
        }
        log.info(name, 'command $topic = $text');
        final result = await commands.execute('haNavigate', {'path': text});
        if (!result.ok) {
          log.warn(name, 'haNavigate over MQTT failed: ${result.error}');
        } else {
          // Optimistic; the URL change event corrects it if the SPA lands
          // somewhere else (redirect, auth bounce).
          _publish('$_base/dashboard_view/state', text);
        }
      } else if (topic == '$_base/camera_snapshot/set') {
        if (payload.header?.retain == true) {
          log.warn(name, 'ignored retained snapshot command');
          continue;
        }
        log.info(name, 'snapshot command');
        final result = await commands.execute('takeCameraSnapshot', const {});
        if (!result.ok) {
          log.warn(name, 'takeCameraSnapshot over MQTT failed: '
              '${result.error}');
        }
      } else if (topic == '$_base/camera/close/set') {
        if (payload.header?.retain == true) {
          log.warn(name, 'ignored retained camera close command');
          continue;
        }
        log.info(name, 'camera close command');
        await commands.execute('hideCameraView', const {});
      } else {
        for (final entry in _settingSwitches.entries) {
          if (topic != '$_base/${entry.key}/set') continue;
          log.info(name, 'command $topic = $text');
          await entry.value.$2(text == 'ON');
          break;
        }
        for (final entry in _settingSelects.entries) {
          if (topic != '$_base/${entry.key}/set') continue;
          log.info(name, 'command $topic = $text');
          final (def, _, _) = entry.value;
          // HA sends the display label; the stored value is accepted too
          // so automations outside HA can use the raw vocabulary.
          String? value;
          for (final option in def.options ?? const <String>[]) {
            if (text == option || text == (def.optionLabels?[option] ?? '')) {
              value = option;
              break;
            }
          }
          if (value == null) {
            // Republish the truth so the HA dropdown snaps back instead of
            // sitting on a choice that never landed.
            log.warn(name, 'unknown option "$text" for ${def.key}');
            _publishSettingSelectStates();
          } else {
            await _settings.set(def, value);
          }
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

  /// Binary sibling of [_publish], for the camera entity's JPEG frames.
  void _publishBytes(String topic, List<int> bytes) {
    final client = _client;
    if (client == null || !_connected) return;
    try {
      client.publishMessage(
          topic, MqttQos.atLeastOnce, Uint8Buffer()..addAll(bytes),
          retain: true);
    } catch (e) {
      log.warn(name, 'publish to $topic failed: $e');
    }
  }

  /// The next alarm, or 'None' when there is not one. Home Assistant reads
  /// an empty payload as "no change", so the absence has to be said out loud
  /// for the sensor to clear; 'None' is what its timestamp device class
  /// treats as unknown.
  Future<void> _publishNextAlarm() async {
    final result = await commands.execute('getNextAlarm', const {});
    final data = result.ok ? result.data : null;
    if (data is Map) {
      _publish('$_base/next_alarm/state', '${data['at']}');
      _publish(
        '$_base/next_alarm/attributes',
        jsonEncode({
          'local_time': data['local'],
          'package': data['package'],
        }),
      );
    } else {
      _publish('$_base/next_alarm/state', 'None');
      _publish('$_base/next_alarm/attributes', jsonEncode(const {}));
    }
  }

  /// Withdraw the screen entity on a device whose panel stays lit through a
  /// screen-off. Retained, so Home Assistant knows before the app is even
  /// running again.
  void _publishScreenAvailability({required bool ambient}) =>
      _publish('$_base/screen/available', ambient ? 'offline' : 'online');

  Future<void> _publishInitialStates() async {
    final ambient = await commands.execute('getAmbientDisplay', const {});
    _publishScreenAvailability(ambient: ambient.ok && ambient.data == true);
    final on = await commands.execute('isScreenOn', const {});
    if (on.ok) _publish('$_base/screen/state', on.data == true ? 'ON' : 'OFF');
    await _publishNextAlarm();
    final brightness = await commands.execute('getBrightness', const {});
    final level = brightness.data;
    if (brightness.ok && level is num) {
      _publish('$_base/brightness/state',
          (level.clamp(0.0, 1.0) * 255).round().toString());
    }
    _publish('$_base/screensaver/state', _screensaverActive ? 'ON' : 'OFF');
    _publishSettingSwitchStates();
    _publishSettingSelectStates();
    _publishScreensaverBrightnessLevel();
    _publishAssistantVolume();
    _publishMediaVolume();
    await _publishAdminUrl();
    await _publishVolume();
    await _publishUpdateState();
    await _publishCurrentCameraViewState();
    if (_lightSensorPresent) {
      final light = await commands.execute('getLightLevel', const {});
      final lux = light.ok && light.data is Map
          ? ((light.data as Map)['lux'] as num?)
          : null;
      if (lux != null) {
        _lastLuxPublished = lux.toDouble();
        _lastLuxPublishedAt = DateTime.now();
        _publish('$_base/illuminance/state', lux.round().toString());
      }
    }
  }

  /// The HA update entity's whole world in one JSON payload: versions, the
  /// release page, and the download progress while an install runs.
  Future<void> _publishUpdateState() async {
    final result = await commands.execute('getUpdateStatus', const {});
    final data = result.data;
    if (!result.ok || data is! Map) return;
    final current = data['currentVersion'] as String?;
    if (current == null || current.isEmpty) return;
    final latest = data['availableVersion'] as String? ?? current;
    final notes = (data['availableNotes'] as String? ?? '').trim();
    final progress = data['progress'] as num?;
    _publish(
        '$_base/update/state',
        jsonEncode({
          'installed_version': current,
          'latest_version': latest,
          'title': 'Kiosk Satellite',
          if (data['releaseUrl'] is String) 'release_url': data['releaseUrl'],
          // HA renders the summary as markdown but caps the payload; the
          // full notes stay one tap away behind the release link.
          if (notes.isNotEmpty)
            'release_summary': notes.length > 255
                ? '${notes.substring(0, 252)}...'
                : notes,
          'in_progress': progress != null,
          if (progress != null)
            'update_percentage': (progress.clamp(0, 1) * 100).round(),
        }));
  }

  /// Minute ticks since the last dashboard view refresh; every fifth poll
  /// re-reads the list so an added or removed dashboard shows up in the
  /// select within a few minutes with no page load needed.
  int _viewRefreshTicks = 0;

  Future<void> _pollStats() async {
    if (!_connected) return;
    // Unconditionally, unlike everything below: proving the device alive is
    // this timestamp's whole job, so "nothing changed" is not a reason to
    // skip it (issue #75).
    _publish(
        '$_base/last_seen/state', DateTime.now().toUtc().toIso8601String());
    if (++_viewRefreshTicks >= 5) {
      _viewRefreshTicks = 0;
      unawaited(_refreshDashboardViews());
    }
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
    final temp = (data['temp'] as num?)?.round();
    if (temp != null && temp != _lastCpuTemp) {
      _lastCpuTemp = temp;
      _publish('$_base/cpu_temp/state', '$temp');
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
        '$_prefix/sensor/ks_$_deviceId/cpu_temp/config',
        '$_prefix/sensor/ks_$_deviceId/ram_free/config',
        '$_prefix/sensor/ks_$_deviceId/ram_total/config',
        '$_prefix/sensor/ks_$_deviceId/last_seen/config',
        '$_prefix/switch/ks_$_deviceId/screensaver/config',
        '$_prefix/button/ks_$_deviceId/reload/config',
        '$_prefix/button/ks_$_deviceId/clear_cache/config',
        '$_prefix/button/ks_$_deviceId/restart/config',
        '$_prefix/button/ks_$_deviceId/bring_to_front/config',
        '$_prefix/update/ks_$_deviceId/update/config',
        // Always in the retraction list even though it is published
        // conditionally: a config export moved to sensor-less hardware must
        // still clean the entity up.
        '$_prefix/sensor/ks_$_deviceId/illuminance/config',
        '$_prefix/select/ks_$_deviceId/dashboard_view/config',
        '$_prefix/sensor/ks_$_deviceId/admin_url/config',
        '$_prefix/number/ks_$_deviceId/screensaver_brightness_level/config',
        '$_prefix/number/ks_$_deviceId/assistant_volume/config',
        '$_prefix/number/ks_$_deviceId/media_volume/config',
        '$_prefix/sensor/ks_$_deviceId/active_camera_view/config',
        '$_prefix/button/ks_$_deviceId/close_camera_view/config',
        // Conditional like illuminance: published only with the camera
        // enabled, always retracted so turning it off cleans up.
        '$_prefix/camera/ks_$_deviceId/device_camera/config',
        '$_prefix/button/ks_$_deviceId/take_snapshot/config',
        '$_prefix/sensor/ks_$_deviceId/last_snapshot/config',
        for (final id in {
          ..._publishedCameraViewIds,
          for (final view in _cameraViews) '${view['id']}',
        })
          '$_prefix/button/ks_$_deviceId/camera_view_$id/config',
        for (final objectId in _settingSwitches.keys)
          '$_prefix/switch/ks_$_deviceId/$objectId/config',
        for (final objectId in _settingSelects.keys)
          '$_prefix/select/ks_$_deviceId/$objectId/config',
      ];

  /// Config topics of entities that shipped in earlier builds under another
  /// component and moved since (the screensaver was a binary_sensor before
  /// it grew a command side). Retracted on every discovery publish so an
  /// upgraded device does not leave a dead twin behind in HA.
  List<String> _legacyDiscoveryTopics() => [
        '$_prefix/binary_sensor/ks_$_deviceId/screensaver/config',
      ];

  Future<void> _publishDiscovery() async {
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
      // The HA device page's "Visit" link: straight into this tablet's
      // remote admin. Only offered while the remote admin is actually on.
      if (_settings.get(defs.remoteEnabled) &&
          _deviceInfo['ip'] is String &&
          (_deviceInfo['ip'] as String).isNotEmpty)
        'configuration_url':
            'http://${_deviceInfo['ip']}:${_settings.get(defs.remotePort).toInt()}',
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

    Map<String, Object?> settingSelect(
            String objectId, (defs.SettingDef<String>, String, String) entry) {
      final (def, entityName, icon) = entry;
      return {
        ...common(objectId, entityName),
        'state_topic': '$_base/$objectId/state',
        'command_topic': '$_base/$objectId/set',
        // The dropdown shows the display labels; the payload contract is
        // that state matches one of these exactly, so both sides publish
        // labels and the command handler maps back to the stored value.
        'options': [
          for (final option in def.options ?? const <String>[])
            def.optionLabels?[option] ?? option,
        ],
        'icon': icon,
        'entity_category': 'config',
      };
    }

    final configs = <String, Map<String, Object?>>{
      '$_prefix/light/ks_$_deviceId/screen/config': {
        ...common('screen', 'Screen'),
        // Available only while the app is online AND this device can
        // actually power its panel off. On one with an always-on display,
        // lockNow leaves a dim clock burning and the entity would be
        // reporting an off screen nobody can see is off (issue #51), so it
        // withdraws instead of lying.
        'availability': [
          {'topic': _availabilityTopic},
          {'topic': '$_base/screen/available'},
        ],
        'availability_mode': 'all',
        'state_topic': '$_base/screen/state',
        'command_topic': '$_base/screen/set',
        'brightness_state_topic': '$_base/brightness/state',
        'brightness_command_topic': '$_base/brightness/set',
        'brightness_scale': 255,
        'icon': 'mdi:tablet',
      }..remove('availability_topic'),
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
      '$_prefix/sensor/ks_$_deviceId/cpu_temp/config': {
        ...common('cpu_temp', 'CPU temperature'),
        'state_topic': '$_base/cpu_temp/state',
        'device_class': 'temperature',
        'unit_of_measurement': '°C',
        'state_class': 'measurement',
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
      // When the device last reported in (issue #75): republished every
      // stats tick whether or not anything changed, retained so it stays
      // readable across an HA restart. Deliberately no availability topic —
      // the timestamp exists to be read after the device has dropped, which
      // is exactly when an availability-gated entity would hide it.
      '$_prefix/sensor/ks_$_deviceId/last_seen/config': {
        ...common('last_seen', 'Last seen'),
        'state_topic': '$_base/last_seen/state',
        'device_class': 'timestamp',
        'icon': 'mdi:clock-check-outline',
        'entity_category': 'diagnostic',
      }..remove('availability_topic'),
      if (_lightSensorPresent)
        '$_prefix/sensor/ks_$_deviceId/illuminance/config': {
          ...common('illuminance', 'Ambient light'),
          'state_topic': '$_base/illuminance/state',
          'device_class': 'illuminance',
          'unit_of_measurement': 'lx',
          'state_class': 'measurement',
        },
      // The device's own alarm clock (issue #42), so a wake-up automation
      // can run off the alarm someone set on the tablet itself. A timestamp
      // sensor: Home Assistant renders it as a time and templates can do
      // arithmetic on it.
      '$_prefix/sensor/ks_$_deviceId/next_alarm/config': {
        ...common('next_alarm', 'Next alarm'),
        'state_topic': '$_base/next_alarm/state',
        'json_attributes_topic': '$_base/next_alarm/attributes',
        'device_class': 'timestamp',
        'icon': 'mdi:alarm',
      },
      '$_prefix/sensor/ks_$_deviceId/admin_url/config': {
        ...common('admin_url', 'Remote admin'),
        'state_topic': '$_base/admin_url/state',
        'icon': 'mdi:remote-desktop',
        'entity_category': 'diagnostic',
      },
      '$_prefix/sensor/ks_$_deviceId/active_camera_view/config': {
        ...common('active_camera_view', 'Active camera view'),
        'state_topic': '$_base/camera/view/state',
        'json_attributes_topic': '$_base/camera/view/attributes',
        'icon': 'mdi:cctv',
      },
      '$_prefix/button/ks_$_deviceId/close_camera_view/config': {
        ...common('close_camera_view', 'Close camera view'),
        'command_topic': '$_base/camera/close/set',
        'payload_press': 'CLOSE',
        'icon': 'mdi:close-box-outline',
      },
      // The device's own camera (discussion #72): a still camera fed by
      // retained JPEG publishes — the interval snapshots and the button
      // below. Nothing streams; the entity always shows the last frame.
      if (_cameraEntitiesWanted) ...{
        '$_prefix/camera/ks_$_deviceId/device_camera/config': {
          ...common('device_camera', 'Camera'),
          'topic': '$_base/camera_snapshot/image',
        },
        '$_prefix/button/ks_$_deviceId/take_snapshot/config': {
          ...common('take_snapshot', 'Take camera snapshot'),
          'command_topic': '$_base/camera_snapshot/set',
          'payload_press': 'SNAPSHOT',
          'icon': 'mdi:camera-iris',
        },
        // When the last frame was captured. The camera entity's state is
        // permanently "idle" (nothing streams), so freshness lives here.
        '$_prefix/sensor/ks_$_deviceId/last_snapshot/config': {
          ...common('last_snapshot', 'Last camera snapshot'),
          'state_topic': '$_base/camera_snapshot/at',
          'device_class': 'timestamp',
          'icon': 'mdi:camera-timer',
        },
      },
      for (final view in _cameraViews)
        '$_prefix/button/ks_$_deviceId/camera_view_${view['id']}/config': {
          ...common(
            'camera_view_${view['id']}',
            'Show ${view['name']}',
          ),
          'command_topic': '$_base/camera/view/set',
          'payload_press': '${view['id']}',
          'icon': 'mdi:cctv',
        },
      // Published only once a view list has been learned from HA; an
      // empty options array would render a useless dropdown. The retraction
      // for a list gone empty rides _discoveryTopics like everything else.
      if (_dashboardViews.isNotEmpty)
        '$_prefix/select/ks_$_deviceId/dashboard_view/config': {
          ...common('dashboard_view', 'Dashboard view'),
          'state_topic': '$_base/dashboard_view/state',
          'command_topic': '$_base/dashboard_view/set',
          'options': _dashboardViews,
          'icon': 'mdi:view-dashboard-outline',
        },
      '$_prefix/switch/ks_$_deviceId/screensaver/config': {
        ...common('screensaver', 'Screensaver'),
        'state_topic': '$_base/screensaver/state',
        'command_topic': '$_base/screensaver/set',
        'icon': 'mdi:sleep',
      },
      '$_prefix/number/ks_$_deviceId/volume/config': {
        ...common('volume', 'Volume'),
        'state_topic': '$_base/volume/state',
        'command_topic': '$_base/volume/set',
        'min': 0,
        'max': 100,
        'step': 1,
        'unit_of_measurement': '%',
        'mode': 'slider',
        'icon': 'mdi:volume-high',
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
      '$_prefix/button/ks_$_deviceId/restart/config': {
        ...common('restart', 'Restart app'),
        'command_topic': '$_base/restart/set',
        'device_class': 'restart',
        'entity_category': 'config',
      },
      '$_prefix/button/ks_$_deviceId/bring_to_front/config': {
        ...common('bring_to_front', 'Bring to front'),
        'command_topic': '$_base/bring_to_front/set',
        'icon': 'mdi:flip-to-front',
      },
      '$_prefix/update/ks_$_deviceId/update/config': {
        ...common('update', 'Update'),
        'state_topic': '$_base/update/state',
        'command_topic': '$_base/update/set',
        'payload_install': 'install',
        'device_class': 'firmware',
      },
      '$_prefix/number/ks_$_deviceId/screensaver_brightness_level/config': {
        ...common(
            'screensaver_brightness_level', 'Screensaver brightness level'),
        'state_topic': '$_base/screensaver_brightness_level/state',
        'command_topic': '$_base/screensaver_brightness_level/set',
        'min': 0,
        'max': 100,
        'step': 5,
        'unit_of_measurement': '%',
        'mode': 'slider',
        'icon': 'mdi:brightness-6',
        'entity_category': 'config',
      },
      '$_prefix/number/ks_$_deviceId/assistant_volume/config': {
        ...common('assistant_volume', 'Assistant volume'),
        'state_topic': '$_base/assistant_volume/state',
        'command_topic': '$_base/assistant_volume/set',
        'min': 0,
        'max': 100,
        'step': 5,
        'unit_of_measurement': '%',
        'mode': 'slider',
        'icon': 'mdi:account-voice',
        'entity_category': 'config',
      },
      '$_prefix/number/ks_$_deviceId/media_volume/config': {
        ...common('media_volume', 'Media volume'),
        'state_topic': '$_base/media_volume/state',
        'command_topic': '$_base/media_volume/set',
        'min': 0,
        'max': 100,
        'step': 5,
        'unit_of_measurement': '%',
        'mode': 'slider',
        'icon': 'mdi:music-note',
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
      '$_prefix/switch/ks_$_deviceId/screensaver_brightness/config':
          settingSwitch('screensaver_brightness', 'Screensaver brightness',
              'mdi:brightness-4'),
      for (final entry in _settingSelects.entries)
        '$_prefix/select/ks_$_deviceId/${entry.key}/config':
            settingSelect(entry.key, entry.value),
    };
    for (final topic in _legacyDiscoveryTopics()) {
      _publish(topic, '');
    }
    // Self-correcting: a camera config published before the presence probe
    // answered (or before the feature was turned off) is retracted on the
    // next discovery pass instead of lingering as a dead entity.
    if (!_cameraEntitiesWanted) {
      _publish('$_prefix/camera/ks_$_deviceId/device_camera/config', '');
      _publish('$_prefix/button/ks_$_deviceId/take_snapshot/config', '');
      _publish('$_prefix/sensor/ks_$_deviceId/last_snapshot/config', '');
    }
    final currentIds = {
      for (final view in _cameraViews) '${view['id']}',
    };
    for (final staleId in _publishedCameraViewIds.difference(currentIds)) {
      _publish(
        '$_prefix/button/ks_$_deviceId/camera_view_$staleId/config',
        '',
      );
    }
    configs.forEach((topic, config) => _publish(topic, jsonEncode(config)));
    _publishedCameraViewIds = currentIds;
    await _settings.setInternal(
      'mqtt_camera_view_ids',
      jsonEncode(currentIds.toList()),
    );
  }

  /// (Re)learn the dashboard view list from HA and republish discovery
  /// when it changed, so the select's dropdown follows dashboards being
  /// added and removed. A failed read keeps the last known list — HA being
  /// unreachable does not mean the dashboards are gone.
  Future<void> _refreshDashboardViews() async {
    if (_refreshingDashboardViews) return;
    _refreshingDashboardViews = true;
    try {
      final result = await commands.execute('haListDashboards', const {});
      final data = result.data;
      if (!result.ok || data is! List) return;
      final options = <String>[];
      for (final d in data) {
        if (d is! Map) continue;
        final urlPath = '${d['url_path'] ?? ''}';
        if (urlPath.isEmpty) continue;
        final views = await commands.execute('haListDashboardViews', {
          'url_path': urlPath,
        });
        final viewData = views.ok ? views.data : null;
        if (viewData is List && viewData.isNotEmpty) {
          for (final v in viewData) {
            if (v is Map) options.add('$urlPath/${v['route']}');
          }
        } else {
          // A dashboard whose config cannot be read (auto-generated
          // strategy dashboards) still navigates by its bare path.
          options.add(urlPath);
        }
      }
      if (options.isEmpty || jsonEncode(options) == jsonEncode(_dashboardViews)) {
        return;
      }
      _dashboardViews = options;
      await _settings.setInternal(
        'mqtt_dashboard_views',
        jsonEncode(options),
      );
      if (_connected) await _publishDiscovery();
    } finally {
      _refreshingDashboardViews = false;
    }
  }

  /// Map the on-screen URL to a select option and publish it. A page that
  /// is no dashboard view at all (settings, an external site) keeps the
  /// last state — a select can only speak in its own options.
  void _publishDashboardViewState(String url) {
    final match = matchDashboardView(url, _dashboardViews);
    if (match == null) return;
    _publish('$_base/dashboard_view/state', match);
  }

  /// The select option a URL corresponds to, or null when it is none of
  /// them. A bare dashboard url renders that dashboard's first view, so it
  /// maps to the first option under that url_path. Origin-agnostic on
  /// purpose: with the secure context proxy on, the page lives on a
  /// loopback origin and only the path is trustworthy.
  @visibleForTesting
  static String? matchDashboardView(String url, List<String> options) {
    if (options.isEmpty) return null;
    final path =
        Uri.tryParse(url)?.path.replaceAll(RegExp(r'^/+|/+$'), '') ?? '';
    if (path.isEmpty) return null;
    if (options.contains(path)) return path;
    if (path.contains('/')) return null;
    final first = options.firstWhere(
      (o) => o.startsWith('$path/'),
      orElse: () => '',
    );
    return first.isEmpty ? null : first;
  }

  Future<void> _refreshCameraViews() async {
    final result = await commands.execute('cameraGetConfig', const {});
    final data = result.data;
    if (!result.ok || data is! Map || data['views'] is! List) {
      _cameraViews = const [];
      return;
    }
    _cameraViews = [
      for (final view in data['views'] as List)
        // A view with no cameras (the empty default every install starts
        // with) has nothing to select: keep it out of the HA options.
        if (view is Map && (view['cameraIds'] as List?)?.isNotEmpty == true)
          view.cast<String, Object?>(),
    ];
  }

  void _publishCameraViewState(CameraViewStateChanged event) {
    _publish('$_base/camera/view/state', event.viewName ?? 'none');
    _publish(
      '$_base/camera/view/attributes',
      jsonEncode(event.toJson()),
    );
  }

  Future<void> _publishCurrentCameraViewState() async {
    final result = await commands.execute('cameraStatus', const {});
    final data = result.data;
    if (!result.ok || data is! Map) return;
    _publish(
      '$_base/camera/view/state',
      data['viewName'] is String ? '${data['viewName']}' : 'none',
    );
    _publish('$_base/camera/view/attributes', jsonEncode(data));
  }
}
