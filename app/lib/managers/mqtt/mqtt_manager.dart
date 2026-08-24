import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' show Random;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../device/wifi_mac.dart';
import '../sendspin/music_assistant_api.dart';
import '../settings/definitions.dart' as defs;
import 'dashboard_views.dart' as shared;
import '../settings/settings_manager.dart';
import 'interaction_stamp.dart';
import 'mqtt_link.dart';

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
///  - sensor "Battery" and binary_sensor "Charging", polled once a minute;
///    charging flips also push the moment the cable changes (issue #205).
///  - sensor "Current page": the URL the kiosk is showing (diagnostic).
///  - switch "Screensaver active": whether the screensaver is up right
///    now; ON/OFF forces it on screen or dismisses it. The master
///    enable/disable lives in the "Screensaver" setting switch (issue
///    #152).
class MqttManager extends Manager with WidgetsBindingObserver {
  MqttManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'mqtt';

  MqttLink? _link;
  Timer? _pollTimer;
  StreamSubscription<MqttInbound>? _updatesSub;
  Timer? _reconnectDebounce;
  final _subs = <StreamSubscription>[];

  /// The broker answered MQTT 3.1.1 after refusing 5: remember for the rest
  /// of this run so every reconnect does not pay a doomed 5 attempt first.
  bool _legacyBroker = false;

  /// Builds the protocol links. Swapped in tests; production always hands
  /// back the real ones.
  @visibleForTesting
  MqttLink Function({required bool legacy}) linkFactory = ({required legacy}) =>
      legacy ? Mqtt311Link() : Mqtt5Link();

  /// The connect flow, for the protocol-ladder tests.
  @visibleForTesting
  Future<void> connectForTest() => _connect();

  /// How long the broker sits on the will before marking this device
  /// offline (MQTT 5 only). Covers the once-a-minute radio naps of issue
  /// #184 with room to spare; a genuinely dead device is offline within
  /// the same margin.
  static const _willDelaySeconds = 90;

  /// Retry for a connect that failed outright (broker unreachable). The
  /// package's auto-reconnect only arms once a connection has succeeded,
  /// and the solicited disconnect() in the failure path disarms it anyway,
  /// so without this a device that boots before its network is up has no
  /// MQTT until an app restart (the offline-boot bug from the
  /// wifi-resilience review). Backoff doubles 5s → 60s; a network-available
  /// event short-circuits the wait.
  Timer? _retryTimer;
  Duration _retryDelay = const Duration(seconds: 5);

  /// Serialises enable/disable/reconnect so a settings burst cannot
  /// interleave two connection attempts.
  Future<void> _transition = Future.value();

  String _deviceId = '';
  int? _lastBattery;
  bool? _lastCharging;
  int? _lastCpu;
  int? _lastCpuTemp;

  /// The foreground package last published ('unknown' when none), so the
  /// sensor only publishes on change; the nudge timer batches the lifecycle
  /// flurries around an app launch into one read.
  String _lastForeground = '';
  String _lastBtNearby = '';
  Timer? _foregroundNudge;
  int? _lastRamFreeMb;
  int? _lastRamTotalMb;

  /// State plus attributes last published per IP sensor, so the minute poll
  /// only publishes when an address actually moved.
  final _lastIpPayload = <String, String>{};

  /// The start moments last published per uptime sensor (null when the last
  /// publish was 'None'), so rounding jitter in the now-minus-seconds
  /// arithmetic never republishes an anchor that has not really moved.
  final _lastAnchor = <String, DateTime?>{};
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

  /// The lens facings the camera hardware offers (read at connect).
  /// Optimistic like [_cameraPresent]: assume both until a probe answers
  /// with a real list, so a probe hiccup (no Activity yet) never retracts
  /// the facing select on hardware that has the choice.
  List<String> _cameraFacings = const ['front', 'back'];

  /// The facing select only exists where there is a choice to make: a
  /// single-camera device (Echo Show 5: front only) gets no dropdown,
  /// matching the settings surfaces (issue #296).
  bool get _cameraFacingWanted =>
      _cameraPresent &&
      _cameraFacings.contains('front') &&
      _cameraFacings.contains('back');

  /// Whether this device can read a CPU temperature at all; probed at
  /// bring-up, revived by any later successful reading (issue #138).
  bool _cpuTempPresent = true;

  /// Whether Android will tell this app about its Bluetooth links at all;
  /// probed at bring-up and revived by any later answer, so granting the
  /// Nearby devices permission brings the sensor with it (issue #281).
  bool _btConnectionsPresent = false;

  /// The connected-device count and name list last published, so the minute
  /// poll only costs the recorder a row when something actually connected
  /// or dropped.
  int? _lastBtConnected;
  String _lastBtDevices = '';

  /// Coalesces the ACL broadcast flurry one connection makes into a single
  /// read of the link count.
  Timer? _btNudge;

  /// Rate limiting for the illuminance publishes: the recorder does not need
  /// every damped native event, but big swings (lights on) should land now.
  double? _lastLuxPublished;
  DateTime _lastLuxPublishedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// The Last interaction sensor's stamp (issue #241). Retained on the
  /// broker, so the value survives app restarts the way the other
  /// retained states do.
  late final _interaction = InteractionStamp(
    (stamp) =>
        _publish('$_base/last_interaction/state', stamp.toIso8601String()),
  );

  String get _base => 'kiosksatellite/$_deviceId';
  String get _availabilityTopic => '$_base/availability';

  /// The native side's Wi-Fi hold, shared with the keep-alive service (see
  /// WifiLockHolder in the Android sources).
  static const _background = MethodChannel('kiosk_satellite/background');
  String get _prefix {
    final p = _settings.get(defs.mqttDiscoveryPrefix).trim();
    return p.isEmpty ? 'homeassistant' : p;
  }

  @override
  Future<void> init() async {
    _subs.add(bus.on<SettingChanged>().listen(_onSettingChanged));
    // The Foreground app sensor's fast path: apps opening or the kiosk
    // returning publish within seconds, the stats poll covers switches
    // that happen entirely behind other apps.
    _subs.add(bus.on<AppLaunched>().listen((_) => _nudgeForegroundApp()));
    if (Platform.isAndroid) WidgetsBinding.instance.addObserver(this);
    _subs.add(
      bus.on<ScreenStateChanged>().listen(
        (e) => _publish('$_base/screen/state', e.on ? 'ON' : 'OFF'),
      ),
    );
    _subs.add(
      bus.on<BrightnessChanged>().listen(
        (e) => _publish(
          '$_base/brightness/state',
          (e.level.clamp(0.0, 1.0) * 255).round().toString(),
        ),
      ),
    );
    _subs.add(
      bus.on<PageChanged>().listen((e) {
        _publish('$_base/url/state', e.url);
        _publishDashboardViewState(e.url);
        // A full load means HA may have just come up (login, reload): a good
        // moment to learn the view list. Slightly deferred so the frontend
        // has a hass to answer with.
        Timer(const Duration(seconds: 5), () {
          if (_connected) unawaited(_refreshDashboardViews());
        });
      }),
    );
    // SPA navigations (view switches) never hit PageChanged; this keeps
    // the url sensor and the dashboard view select honest between loads.
    _subs.add(
      bus.on<UrlChanged>().listen((e) {
        _publish('$_base/url/state', e.url);
        _publishDashboardViewState(e.url);
      }),
    );
    _subs.add(
      bus.on<ScreensaverStateChanged>().listen((e) {
        _screensaverActive = e.active;
        _publish('$_base/screensaver_active/state', e.active ? 'ON' : 'OFF');
      }),
    );
    // Covers every path the volume moves: an MQTT command, the hardware
    // rocker, another app (the platform side broadcasts them all).
    _subs.add(bus.on<VolumeChanged>().listen((_) => _publishVolume()));
    // Bluetooth links move between polls: a lock Home Assistant connects to
    // through the proxy is gone again within half a minute (issue #281).
    // One connection fires several broadcasts, so the read is coalesced.
    _subs.add(
      bus.on<BluetoothLinksChanged>().listen((_) {
        _btNudge?.cancel();
        _btNudge = Timer(
          const Duration(milliseconds: 700),
          () => unawaited(_publishBluetoothConnections()),
        );
      }),
    );
    // The updater already throttles progress to whole percents.
    _subs.add(
      bus.on<UpdateStateChanged>().listen((_) => _publishUpdateState()),
    );
    _subs.add(
      bus.on<CameraConfigurationChanged>().listen((_) async {
        await _refreshCameraViews();
        if (_connected) await _publishDiscovery();
      }),
    );
    _subs.add(bus.on<CameraViewStateChanged>().listen(_publishCameraViewState));
    // Every capture the device camera manager makes (interval, the HA
    // button, the remote admin) lands on the camera entity. Retained, so
    // the entity has a picture right after an HA restart. The timestamp
    // rides along: the camera entity's own state never moves (a still
    // camera is forever "idle"), so the Last snapshot sensor is how HA can
    // see, and automate on, frame freshness.
    _subs.add(
      bus.on<CameraSnapshotTaken>().listen((e) {
        _publishBytes('$_base/camera_snapshot/image', e.jpeg);
        _publish(
          '$_base/camera_snapshot/at',
          DateTime.now().toUtc().toIso8601String(),
        );
      }),
    );
    _subs.add(
      bus.on<MotionDetected>().listen((_) {
        if (!_settings.get(defs.motionSensor)) return;
        // Never retained: a retained ON replayed on an HA restart or broker
        // reconnect would read as fresh motion and restart the off_delay.
        // The OFF side is HA's job entirely (off_delay in the discovery
        // config); the app only ever reports motion, not its absence.
        _publish('$_base/motion/state', 'ON', retain: false);
      }),
    );
    _subs.add(bus.on<NextAlarmChanged>().listen((_) => _publishNextAlarm()));
    // The network returned from an outage: if the initial connect had
    // failed and the retry timer is sitting out its backoff, go now.
    // A live-but-disconnected client is the package's business — its
    // auto-reconnect already retries every few seconds.
    _subs.add(
      bus.on<NetworkStateChanged>().listen((e) {
        if (e.up && _link == null && _retryTimer != null) _retryNow();
        // Addresses change exactly at these transitions, and the minute poll
        // would leave the IP sensors stale for up to a minute. Deferred a
        // moment so DHCP has settled by the time we look.
        if (_connected) {
          Timer(const Duration(seconds: 3), () {
            if (_connected) unawaited(_publishIpAddresses());
          });
        }
      }),
    );
    _subs.add(
      bus.on<AmbientDisplayChanged>().listen(
        (e) => _publishScreenAvailability(ambient: e.on),
      ),
    );
    // Charging flips push immediately; the minute poll left the entity
    // trailing the cable by up to a minute (issue #205).
    _subs.add(
      bus.on<PowerChanged>().listen((e) {
        if (e.charging == _lastCharging) return;
        _lastCharging = e.charging;
        _publish('$_base/charging/state', e.charging ? 'ON' : 'OFF');
      }),
    );
    // The native side damps flicker; this only guards the recorder's disk:
    // at most one publish per 15s, unless the level swung hard (lights on).
    _subs.add(
      bus.on<LightLevelChanged>().listen((e) {
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
      }),
    );
    // Touches and spoken turns stamp the Last interaction sensor (issue
    // #241), so automations can tell an idle kiosk from one in use. Motion
    // deliberately does not count: someone walking past is exactly what an
    // idle automation wants to keep ignoring.
    _subs.add(
      bus.on<ActivityDetected>().listen((e) {
        if (e.source == 'touch') _interaction.mark();
      }),
    );
    _subs.add(bus.on<WakeWordDetected>().listen((_) => _interaction.mark()));
    _subs.add(
      bus.on<VoiceInteractionChanged>().listen((e) {
        if (InteractionStamp.countsAsVoice(e)) _interaction.mark();
      }),
    );

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
    final username = _settings.get(defs.mqttUsername).trim();
    final password = _settings.get(defs.mqttPassword);
    final config = MqttLinkConfig(
      host: host,
      port: port,
      tls: _settings.get(defs.mqttTls),
      clientId: 'kiosksatellite_probe_${DateTime.now().millisecondsSinceEpoch}',
      username: username.isEmpty ? null : username,
      password: password.isEmpty ? null : password,
      keepAliveSeconds: 10,
      connectTimeoutMs: 8000,
    );
    // The same protocol ladder the live connection walks: 5 first, 3.1.1
    // for brokers that never learned it.
    MqttLinkError? error;
    for (final probe in [Mqtt5Link(), Mqtt311Link()]) {
      error = await probe.connect(config);
      if (error == null) {
        probe.disconnect();
        return CommandResult.ok({
          'connected': true,
          'host': host,
          'port': port,
        });
      }
    }
    log.warn(name, 'validation against $host:$port failed: $error');
    return CommandResult.fail('$error');
  }

  @override
  Future<void> dispose() async {
    if (Platform.isAndroid) WidgetsBinding.instance.removeObserver(this);
    _foregroundNudge?.cancel();
    _btNudge?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    _interaction.dispose();
    _reconnectDebounce?.cancel();
    await _disconnect(clearDiscovery: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.resumed) {
      _nudgeForegroundApp();
    }
  }

  /// Re-read the foreground app shortly after something moved (a launch, a
  /// pause, a return). The delay lets the usage event land first.
  void _nudgeForegroundApp() {
    _foregroundNudge?.cancel();
    _foregroundNudge = Timer(const Duration(seconds: 3), () {
      unawaited(_publishForegroundApp());
    });
  }

  /// Which app is on screen (issue #192): the package name as the state
  /// (stable, what automations match on), the human label in attributes.
  /// 'unknown' when nothing can be vouched for (no Usage access grant
  /// while another app is up).
  Future<void> _publishForegroundApp() async {
    if (!_connected) return;
    final result = await commands.execute('foregroundApp', const {});
    final data = result.data;
    if (!result.ok || data is! Map) return;
    final pkg = data['package'] as String?;
    final key = pkg ?? 'unknown';
    if (key == _lastForeground) return;
    _lastForeground = key;
    _publish('$_base/foreground_app/state', key);
    _publish(
      '$_base/foreground_app/attributes',
      jsonEncode({'label': pkg == null ? null : '${data['label'] ?? pkg}'}),
    );
  }

  /// The Bluetooth proxy's nearby-device inventory (count as the state, the
  /// identified list as attributes), so a dashboard can show what each room
  /// hears without opening the app. Top of the list by recency, capped: the
  /// attribute JSON rides the same connection as everything else and a busy
  /// street of rotating addresses could otherwise grow it without bound.
  Future<void> _publishBtProxyNearby() async {
    if (!_connected) return;
    if (!_settings.get(defs.btproxyEnabled)) return;
    final result = await commands.execute('btProxyNearby', const {});
    final data = result.data;
    if (!result.ok || data is! Map) return;
    final devices = (data['devices'] as List? ?? const []).take(40).toList();
    final payload = jsonEncode({'devices': devices});
    if (payload == _lastBtNearby) return;
    _lastBtNearby = payload;
    _publish(
      '$_base/btproxy_nearby/state',
      '${data['count'] ?? devices.length}',
    );
    _publish('$_base/btproxy_nearby/attributes', payload);
  }

  /// The Bluetooth devices the kiosk itself is linked to (issue #281): the
  /// count as the state, their names as attributes, so a dashboard can show
  /// whether the room's speaker is still on the panel. Counts every link the
  /// device holds, including any the Bluetooth proxy has open, which is what
  /// "connections" means from the adapter's side.
  Future<void> _publishBluetoothConnections() async {
    if (!_connected) return;
    if (!_settings.get(defs.btproxyEnabled)) return;
    final result = await commands.execute('getBluetoothConnections', const {});
    final data = result.data;
    if (!result.ok || data is! Map) return;
    final connected = (data['connected'] as num?)?.toInt();
    if (connected == null) return;
    if (!_btConnectionsPresent) {
      // The bring-up probe was refused (the grant landed later): the sensor
      // exists after all.
      _btConnectionsPresent = true;
      unawaited(_publishDiscovery());
    }
    final devices = jsonEncode({
      'devices': [
        for (final name in data['devices'] as List? ?? const []) '$name',
      ],
    });
    if (connected == _lastBtConnected && devices == _lastBtDevices) return;
    _lastBtConnected = connected;
    _lastBtDevices = devices;
    _publish('$_base/bt_devices_connected/state', '$connected');
    _publish('$_base/bt_devices_connected/attributes', devices);
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
    'lockdown': (
      () => _settings.get(defs.lockdownEnabled),
      (on) => _settings.set(defs.lockdownEnabled, on),
    ),
    'ha_kiosk': (
      () => _settings.get(defs.haKioskMode),
      (on) => _settings.set(defs.haKioskMode, on),
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
    // The master enable/disable, same as the Screensaver toggle in
    // the settings UI (issue #152). Kept under the object id the
    // start/stop switch used to hold, so existing automations that
    // flip switch.*_screensaver now control the master toggle the
    // way that entity always claimed to.
    'screensaver': (
      () => _settings.get(defs.screensaverEnabled),
      (on) => _settings.set(defs.screensaverEnabled, on),
    ),
    // Hold mode (issue #266): pin the current view. The switch IS
    // the setting, so an automation can say "hold for media
    // playback" and see the state either way.
    'hold_mode': (
      () => _settings.get(defs.haHoldMode),
      (on) => _settings.set(defs.haHoldMode, on),
    ),
    // The camera master toggle (discussion #155): an automation
    // with a wider motion sensor can keep the camera, and its 10%
    // CPU cost, off until someone is near, then arm camera motion
    // detection for the final approach.
    'camera_enabled': (
      () => _settings.get(defs.cameraEnabled),
      (on) => _settings.set(defs.cameraEnabled, on),
    ),
    // Dismiss on motion, under the name the feature goes by. Rides
    // the same automations as the camera switch above: arm the
    // approach detection only while somebody could be approaching.
    'screensaver_motion': (
      () => _settings.get(defs.screensaverDismissOnMotion),
      (on) => _settings.set(defs.screensaverDismissOnMotion, on),
    ),
  };

  static const _switchSettingKeys = [
    'kiosk.enabled',
    'lockdown.enabled',
    'ha.kiosk_mode',
    'screen.keep_on',
    'remote.enabled',
    'screensaver.brightness_enabled',
    'screensaver.enabled',
    'ha.hold_mode',
    'camera.enabled',
    'screensaver.dismiss_on_motion',
  ];

  /// The setting-backed dropdowns: object id → (definition, entity name,
  /// icon). HA shows the definition's display labels; state publishes are
  /// mapped to labels and incoming commands mapped back to the stored value,
  /// so the stored vocabulary never leaks into the HA UI.
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
        // Front/back camera pick (issue #296): rides the hardware like the
        // camera switches, not the enable toggle, so an automation can set
        // the facing first and switch the camera on after. Discovery is
        // gated on the device actually having both facings.
        'camera_device': (
          defs.cameraDevice,
          'Camera facing',
          'mdi:camera-flip-outline',
        ),
      };

  bool _isSelectSettingKey(String key) =>
      _settingSelects.values.any((s) => s.$1.key == key);

  void _publishSettingSwitchStates() {
    _settingSwitches.forEach(
      (objectId, actions) =>
          _publish('$_base/$objectId/state', actions.$1() ? 'ON' : 'OFF'),
    );
  }

  /// The camera master toggle flipped (any surface: device UI, remote
  /// admin, the MQTT switch): publish or retract the camera entities.
  void _syncCameraEntities(Object? enabled) {
    if (!_connected) return;
    if (enabled == true && _cameraPresent) {
      unawaited(
        _publishDiscovery().then(
          (_) => commands.execute('takeCameraSnapshot', const {}),
        ),
      );
    } else if (enabled == true) {
      // Enabled on a camera-less device: nothing to publish.
      return;
    } else {
      // Retract the entities and drop the retained frame: a disabled
      // camera should leave neither a dead entity nor a stale picture
      // parked on the broker. The motion sensor rides the camera master
      // switch too, so it goes with them.
      _publish('$_prefix/camera/ks_$_deviceId/device_camera/config', '');
      _publish('$_prefix/button/ks_$_deviceId/take_snapshot/config', '');
      _publish('$_prefix/sensor/ks_$_deviceId/last_snapshot/config', '');
      _publish('$_prefix/binary_sensor/ks_$_deviceId/motion/config', '');
      _publishBytes('$_base/camera_snapshot/image', const []);
      _publish('$_base/camera_snapshot/at', '');
    }
  }

  void _publishSettingSelectStates() {
    _settingSelects.forEach((objectId, entry) {
      final (def, _, _) = entry;
      final value = _settings.get(def);
      _publish('$_base/$objectId/state', def.optionLabels?[value] ?? value);
    });
  }

  /// The Clock screensaver's background photo path (issue #150). Plain
  /// pass-through of the setting: whatever picked the photo (the device
  /// picker, an MQTT write), the HA text box shows the same path.
  void _publishClockBackground() {
    _publish(
      '$_base/clock_background/state',
      _settings.get(defs.screensaverClockBackground),
    );
  }

  void _publishScreensaverBrightnessLevel() {
    final level = _settings.get(defs.screensaverBrightnessLevel).toDouble();
    _publish(
      '$_base/screensaver_brightness_level/state',
      (level.clamp(0.0, 1.0) * 100).round().toString(),
    );
  }

  void _publishAssistantVolume() {
    final pct = _settings.get(defs.assistantVolume).toDouble();
    _publish(
      '$_base/assistant_volume/state',
      pct.clamp(0.0, 100.0).round().toString(),
    );
  }

  void _publishMediaVolume() {
    final pct = _settings.get(defs.mediaVolume).toDouble();
    _publish(
      '$_base/media_volume/state',
      pct.clamp(0.0, 100.0).round().toString(),
    );
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
    if (e.key == defs.esphomeRealMac.key) {
      // The discovery device block's connections entry follows the real-MAC
      // identity setting (issue #252).
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
      // Switch-backed since discussion #155, but the camera entities still
      // ride the master toggle the way they always did.
      if (e.key == defs.cameraEnabled.key) _syncCameraEntities(e.value);
      return;
    }
    if (e.key == defs.screensaverBrightnessLevel.key) {
      _publishScreensaverBrightnessLevel();
      return;
    }
    if (e.key == defs.screensaverClockBackground.key) {
      // Whatever surface set it (device picker, MQTT itself), the HA text
      // box reflects it.
      _publishClockBackground();
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
    if (e.key == defs.launcherEnabled.key) {
      // The Open app launcher button follows the master switch: published
      // when it goes on, retracted when it goes off (the dispatch side is
      // gated too — showAppLauncher refuses while disabled).
      if (_connected) unawaited(_publishDiscovery());
      return;
    }
    if (e.key == defs.sendspinMaUrl.key) {
      // The Show Music Assistant button follows the server address:
      // published once one is set, retracted when it is cleared.
      if (_connected) unawaited(_publishDiscovery());
      return;
    }
    if (e.key == defs.btproxyEnabled.key) {
      // The nearby-devices and connected-devices sensors follow the
      // proxy's master switch, same shape as the launcher button above.
      _lastBtNearby = '';
      _lastBtConnected = null;
      _lastBtDevices = '';
      if (_connected) {
        unawaited(_publishDiscovery());
        // Switched on: read the links now rather than at the next minute
        // tick, since that read is also what revives the sensor when the
        // bring-up probe ran with the proxy off.
        unawaited(_publishBluetoothConnections());
      }
      return;
    }
    if (e.key == defs.motionSensor.key ||
        e.key == defs.motionSensorOffDelay.key) {
      if (!_connected) return;
      if (_settings.get(defs.motionSensor) && _cameraEntitiesWanted) {
        // On, or a new off_delay: (re)publish the config. The state topic
        // needs no seeding — it is non-retained by design, and HA holds
        // the sensor at its restored state until the next motion tick.
        unawaited(_publishDiscovery());
      } else {
        _publish('$_prefix/binary_sensor/ks_$_deviceId/motion/config', '');
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
        await _disconnect(clearDiscovery: !_settings.get(defs.mqttEnabled));
        if (_settings.get(defs.mqttEnabled)) await _connect();
      });
    });
  }

  bool get _connected => _link?.connected ?? false;

  Future<void> _connect() async {
    // Whatever drove this attempt (init, a settings change, the retry
    // itself), a pending retry timer is now redundant.
    _retryTimer?.cancel();
    _retryTimer = null;
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
      _deviceId = List.generate(
        8,
        (_) => rng.nextInt(16).toRadixString(16),
      ).join();
      await _settings.set(defs.mqttDeviceId, _deviceId);
    }
    final port = _settings.get(defs.mqttPort).toInt();
    final username = _settings.get(defs.mqttUsername).trim();
    final password = _settings.get(defs.mqttPassword);
    final config = MqttLinkConfig(
      host: host,
      port: port,
      tls: _settings.get(defs.mqttTls),
      clientId: 'kiosksatellite_$_deviceId',
      username: username.isEmpty ? null : username,
      password: password.isEmpty ? null : password,
      keepAliveSeconds: 30,
      // Without this the client pings every 30s but never checks for the
      // answer, so a half-open socket (wifi flap, AP reboot) is only
      // noticed when a TCP write hard-fails — minutes, sometimes never.
      // With it, a missed PINGRESP forces a disconnect, which
      // auto-reconnect repairs. Two ping cycles, not one: with the screen
      // off some Wi-Fi radios (Lenovo M10 Plus, issue #184) delay traffic
      // past a single 30s window without the connection being dead at all.
      noResponseSeconds: 65,
      autoReconnect: true,
      // The will is what makes `availability` honest: the broker flips
      // this device to offline when the connection dies, however it dies —
      // but only after the delay (MQTT 5), so the reconnect dance of a
      // napping screen-off radio never shows in Home Assistant at all.
      willTopic: _availabilityTopic,
      willPayload: 'offline',
      willDelaySeconds: _willDelaySeconds,
    );

    var link = linkFactory(legacy: _legacyBroker);
    void wire(MqttLink l) {
      l.onConnected = _onConnected;
      l.onDisconnected = () => log.warn(name, 'disconnected from $host:$port');
    }

    wire(link);
    _link = link;
    var error = await link.connect(config);
    if (error != null && !_legacyBroker) {
      // Whatever felled the 5 attempt, give 3.1.1 one shot: a pre-5 broker
      // may answer a 5 CONNECT with a refusal or just hang up on it.
      log.info(name, 'MQTT 5 connect failed ($error); trying MQTT 3.1.1');
      final legacy = linkFactory(legacy: true);
      wire(legacy);
      final legacyError = await legacy.connect(config);
      if (legacyError == null) {
        _legacyBroker = true;
        _link = legacy;
        link = legacy;
        error = null;
        log.info(name, 'broker speaks MQTT 3.1.1 only; staying on it');
      } else {
        error = legacyError;
      }
    }
    if (error != null) {
      _link = null;
      log.warn(name, 'connect to $host:$port failed: $error');
      // A network-shaped failure owns its retry (the solicited teardown in
      // the link disarms the package's auto-reconnect); a broker that
      // answered and refused (credentials, ACL) is not hammered.
      if (error.retryable) _scheduleRetry();
      return;
    }
    _retryDelay = const Duration(seconds: 5);

    // Hold the Wi-Fi radio awake for the connection's lifetime (issue
    // #184): with the screen off, radio power saving delays or drops
    // traffic and the keepalive dance flaps the entities. Held across
    // auto-reconnects on purpose — the radio matters most exactly while
    // the session struggles. Best-effort: off Android there is nothing
    // to hold.
    unawaited(
      _background
          .invokeMethod('setWifiLockHeld', {'held': true})
          .catchError((_) {}),
    );

    _updatesSub = link.messages.listen((m) => _onMessage([m]));
    for (final topic in [
      '$_base/screen/set',
      '$_base/brightness/set',
      '$_base/screensaver_active/set',
      '$_base/postpone_screensaver/set',
      '$_base/volume/set',
      '$_base/reload/set',
      '$_base/load_start_url/set',
      '$_base/clear_cache/set',
      '$_base/restart/set',
      '$_base/bring_to_front/set',
      '$_base/open_launcher/set',
      '$_base/show_music_assistant/set',
      '$_base/update/set',
      '$_base/screensaver_brightness_level/set',
      '$_base/clock_background/set',
      '$_base/assistant_volume/set',
      '$_base/media_volume/set',
      '$_base/camera/view/set',
      '$_base/camera/view/select',
      '$_base/camera/close/set',
      '$_base/camera_snapshot/set',
      '$_base/screenshot/set',
      '$_base/dashboard_view/set',
      for (final objectId in _settingSwitches.keys) '$_base/$objectId/set',
      for (final objectId in _settingSelects.keys) '$_base/$objectId/set',
    ]) {
      link.subscribe(topic);
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, _retryNow);
    log.info(name, 'retrying in ${_retryDelay.inSeconds}s');
    final doubled = _retryDelay * 2;
    _retryDelay = doubled > const Duration(seconds: 60)
        ? const Duration(seconds: 60)
        : doubled;
  }

  void _retryNow() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _transition = _transition.then((_) async {
      // Re-check inside the serialized transition: a settings change or
      // disable may have run (and connected, or torn down) meanwhile.
      if (_link != null || !_settings.get(defs.mqttEnabled)) return;
      await _connect();
    });
  }

  DateTime _lastBringUp = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastBringUpSnapshot = DateTime.fromMillisecondsSinceEpoch(0);
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
    log.info(
      name,
      'connected as kiosksatellite_$_deviceId'
      ' (${_link?.protocolName ?? 'MQTT'})',
    );
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
    // And the lens facings, for the facing select: only a real, non-empty
    // answer is adopted — an empty list means the probe could not look
    // (no Activity), not that the hardware has one camera.
    final facings = await commands.execute('getCameraFacings', const {});
    if (facings.ok &&
        facings.data is List &&
        (facings.data as List).isNotEmpty) {
      _cameraFacings = [for (final f in facings.data as List) '$f'];
    }
    // And for CPU temperature: some OEM SELinux policies deny apps the
    // thermal sysfs outright (issue #138, Lenovo), and an entity that can
    // never report is worse than none. One-way in the other direction: a
    // later poll that does read a temperature revives the entity (the
    // probe can miss a device sitting under the 20°C plausibility floor
    // in a cold room).
    final stats = await commands.execute('getStats', const {});
    _cpuTempPresent =
        stats.ok && stats.data is Map && (stats.data as Map)['temp'] != null;
    // And for the Bluetooth links: they ride the proxy's master switch, and
    // a device with no adapter, or one whose Nearby devices grant is missing
    // on Android 12+, gets no sensor rather than one stuck on unknown
    // (issue #281).
    final bt = _settings.get(defs.btproxyEnabled)
        ? await commands.execute('getBluetoothConnections', const {})
        : null;
    _btConnectionsPresent =
        bt != null &&
        bt.ok &&
        bt.data is Map &&
        (bt.data as Map)['connected'] != null;
    _publish(_availabilityTopic, 'online');
    await _publishDiscovery();
    await _publishInitialStates();
    // A fresh frame for the camera entity on every connect, so it never
    // shows a picture older than the link. Detached: a capture takes a
    // moment and the bring-up should not wait on the sensor. Throttled
    // across reconnects (issue #207): if the snapshot publish itself is
    // what felled the link (a broker packet cap, a flap mid-transfer),
    // snapshotting again on every reconnect turns one drop into a loop.
    final now = DateTime.now();
    if (_cameraEntitiesWanted &&
        now.difference(_lastBringUpSnapshot) > const Duration(minutes: 5)) {
      _lastBringUpSnapshot = now;
      unawaited(commands.execute('takeCameraSnapshot', const {}));
    }
    // Learn the view list once the link is up; republishes discovery on
    // its own when the list moved.
    unawaited(_refreshDashboardViews());
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _pollStats(),
    );
    await _pollStats();
  }

  Future<void> _disconnect({required bool clearDiscovery}) async {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryDelay = const Duration(seconds: 5);
    _pollTimer?.cancel();
    _pollTimer = null;
    await _updatesSub?.cancel();
    _updatesSub = null;
    final link = _link;
    _link = null;
    if (link == null) return;
    if (link.connected) {
      if (clearDiscovery) {
        // Feature turned off: retract the entities. An empty retained
        // config payload is how HA discovery removes a device cleanly.
        for (final topic in _discoveryTopics()) {
          link.publishEmpty(topic);
        }
      }
      // The last honest "alive at" this session can leave behind: the
      // goodbye moment. A hard death (power cut, crash) cannot stamp
      // this, so there Last seen keeps the connect-time state and the
      // drop shows as the availability transition instead.
      link.publishString(
        '$_base/last_seen/state',
        DateTime.now().toUtc().toIso8601String(),
        retain: true,
      );
      // A graceful disconnect never fires the will; say goodbye ourselves.
      link.publishString(_availabilityTopic, 'offline', retain: true);
    }
    link.disconnect();
    // The feature is off (or the manager is going down): let the radio
    // sleep again unless another holder still needs it.
    unawaited(
      _background
          .invokeMethod('setWifiLockHeld', {'held': false})
          .catchError((_) {}),
    );
  }

  // ── Incoming commands ───────────────────────────────────────────────

  Future<void> _onMessage(List<MqttInbound> batch) async {
    for (final received in batch) {
      final text = received.text;
      final topic = received.topic;
      // Every subscription here is a /set command topic, and commands are
      // imperative: a payload delivered with the retain flag is the broker
      // replaying a stored press at (re)subscribe time, which resubscribe-
      // on-reconnect turns into "again on every network flap" (a retained
      // reload would reload the page on each one). Live publishes arrive
      // with the flag clear even when sent retained, so dropping these
      // loses nothing. One guard here instead of the old per-topic ones,
      // which missed the riskiest topics (reload, restart, clear_cache).
      if (received.retained) {
        log.warn(name, 'ignored retained command on $topic');
        continue;
      }
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
            _publish(
              '$_base/screen/state',
              on.ok && on.data == false ? 'OFF' : 'ON',
            );
          }
        }
      } else if (topic == '$_base/brightness/set') {
        log.info(name, 'command $topic = $text');
        final raw = int.tryParse(text);
        if (raw == null) continue;
        await commands.execute('setBrightness', {
          'level': (raw.clamp(0, 255)) / 255,
        });
      } else if (topic == '$_base/screensaver_active/set') {
        log.info(name, 'command $topic = $text');
        await commands.execute(
          text == 'ON' ? 'startScreensaver' : 'stopScreensaver',
          const {},
        );
      } else if (topic == '$_base/postpone_screensaver/set') {
        // External activity (issue #129): an automation presses this off
        // any HA sensor — a door contact, a motion sensor across the room —
        // and the idle timer resets as if someone had touched the screen,
        // dismissing the screensaver first when one is showing.
        log.info(name, 'command $topic');
        await commands.execute('postponeScreensaver', const {});
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
      } else if (topic == '$_base/load_start_url/set') {
        // Back to the device's own dashboard (discussion #110): navigates
        // to the Start URL, unlike reload which re-shows the current page.
        log.info(name, 'command $topic');
        final result = await commands.execute('loadStartUrl', const {});
        if (!result.ok) {
          log.warn(name, 'loadStartUrl over MQTT failed: ${result.error}');
        }
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
      } else if (topic == '$_base/open_launcher/set') {
        // The app launcher overlay (issue #114). The command wakes the
        // screen and pulls the kiosk forward first, so the launcher lands
        // on a visible dashboard — which is exactly why the retained-replay
        // guard above must never weaken.
        log.info(name, 'command $topic');
        final result = await commands.execute('showAppLauncher', const {});
        if (!result.ok) {
          log.warn(name, 'showAppLauncher over MQTT failed: ${result.error}');
        }
      } else if (topic == '$_base/show_music_assistant/set') {
        // The Music Assistant web interface over the dashboard — the HA
        // button face of the kiosk menu entry. The command wakes the screen
        // and pulls the kiosk forward first, same as a camera view.
        log.info(name, 'command $topic');
        final result = await commands.execute('showMusicAssistant', const {});
        if (!result.ok) {
          log.warn(
            name,
            'showMusicAssistant over MQTT failed: ${result.error}',
          );
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
        await _settings.set(
          defs.screensaverBrightnessLevel,
          percent.clamp(0, 100) / 100,
        );
      } else if (topic == '$_base/clock_background/set') {
        // A device-local file path, overwriting the photo picked on the
        // device (issue #150); empty clears the background. Not validated
        // here: the renderer already fails soft on a missing file, and a
        // path published before the file lands should start showing the
        // moment it does.
        log.info(name, 'command $topic = $text');
        await _settings.set(defs.screensaverClockBackground, text.trim());
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
        log.info(name, 'camera view command');
        final result = await commands.execute('showCameraView', {
          'viewId': text,
        });
        if (!result.ok) {
          log.warn(name, 'showCameraView over MQTT failed: ${result.error}');
          await _publishCurrentCameraViewState();
        }
      } else if (topic == '$_base/camera/view/select') {
        // The Camera view select speaks in view names; "Closed" closes.
        // Not "None": Home Assistant's MQTT entities treat that literal
        // payload as reserved and blank the select to unknown. "Closed"
        // wins over a view someone actually named Closed, so the close
        // action is always reachable ("None" is honored too, for scripts
        // publishing raw payloads).
        log.info(name, 'camera view select = $text');
        if (text == 'Closed' || text == 'None') {
          await commands.execute('hideCameraView', const {});
        } else {
          final view = _cameraViews.firstWhere(
            (candidate) => '${candidate['name']}' == text,
            orElse: () => const {},
          );
          final result = view.isEmpty
              ? const CommandResult.fail('unknown view')
              : await commands.execute('showCameraView', {
                  'viewId': '${view['id']}',
                });
          if (!result.ok) {
            // A stale option (view renamed or deleted before HA caught
            // up): put the truth back so the select does not sit on it.
            log.warn(
              name,
              'camera view select "$text" failed: ${result.error}',
            );
            await _publishCurrentCameraViewState();
          }
        }
      } else if (topic == '$_base/dashboard_view/set') {
        log.info(name, 'command $topic = $text');
        final result = await commands.execute('haNavigate', {'path': text});
        final outcome = result.ok ? '${result.data}' : '';
        if (!result.ok) {
          log.warn(name, 'haNavigate over MQTT failed: ${result.error}');
        } else if (outcome == 'navigated' || outcome == 'already') {
          // Optimistic; the URL change event corrects it if the SPA lands
          // somewhere else (redirect, auth bounce).
          _publish('$_base/dashboard_view/state', text);
        } else {
          // The page never moved (an off-origin site on screen, an eval
          // failure): echoing the command would lie to the select, and the
          // silence hid exactly this case in issue #214's logs.
          log.warn(name, 'haNavigate did not move the page: $outcome');
        }
      } else if (topic == '$_base/camera_snapshot/set') {
        log.info(name, 'snapshot command');
        final result = await commands.execute('takeCameraSnapshot', const {});
        if (!result.ok) {
          log.warn(
            name,
            'takeCameraSnapshot over MQTT failed: '
            '${result.error}',
          );
        }
      } else if (topic == '$_base/screenshot/set') {
        log.info(name, 'screenshot command');
        // Capped near 1080p (1920 wide in landscape, 1080 in portrait): a
        // troubleshooting picture, not an archive, and an uncapped panel
        // frame would sit on the broker as a multi-megabyte retained
        // payload. The capture scales natively, so the full frame is never
        // allocated (issue #168).
        final size = PlatformDispatcher.instance.implicitView?.physicalSize;
        final portrait = size != null && size.height > size.width;
        final result = await commands.execute('screenshot', {
          'width': portrait ? 1080 : 1920,
        });
        final jpeg = result.data;
        if (result.ok && jpeg is String) {
          _publishBytes('$_base/screenshot/image', base64Decode(jpeg));
          _publish(
            '$_base/screenshot/at',
            DateTime.now().toUtc().toIso8601String(),
          );
        } else {
          log.warn(name, 'screenshot over MQTT failed: ${result.error}');
        }
      } else if (topic == '$_base/camera/close/set') {
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

  void _publish(String topic, String payload, {bool retain = true}) {
    final link = _link;
    if (link == null || !_connected) return;
    try {
      link.publishString(topic, payload, retain: retain);
    } catch (e) {
      log.warn(name, 'publish to $topic failed: $e');
    }
  }

  /// Binary sibling of [_publish], for the camera entity's JPEG frames.
  void _publishBytes(String topic, List<int> bytes) {
    final link = _link;
    if (link == null || !_connected) return;
    // A broker that advertised a packet size cap (MQTT 5) answers an
    // oversize publish by dropping the whole connection (issue #207); a
    // skipped frame with a log line beats a killed link. The margin
    // covers the topic and the fixed header and properties around it.
    final max = link.brokerMaximumPacketSize;
    if (max != null && bytes.length + topic.length + 64 > max) {
      log.warn(
        name,
        'not publishing ${bytes.length} bytes to $topic: '
        'the broker caps MQTT packets at $max bytes. Lower the camera '
        'snapshot resolution or raise the broker limit.',
      );
      return;
    }
    try {
      link.publishBytes(topic, bytes, retain: true);
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
        jsonEncode({'local_time': data['local'], 'package': data['package']}),
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
    // When the device last came online (issue #75, reshaped with #213):
    // one retained timestamp per broker connect instead of one a minute.
    // A constant state costs the recorder nothing, every reconnect is a
    // real event worth a row, and the graceful-goodbye stamp in
    // _disconnect covers "alive until" for everything but a hard death.
    _publish(
      '$_base/last_seen/state',
      DateTime.now().toUtc().toIso8601String(),
    );
    // Interactions stamped while the link was down never left the device;
    // the freshest one this run has seen beats the broker's retained copy.
    final lastInteraction = _interaction.latest;
    if (lastInteraction != null) {
      _publish(
        '$_base/last_interaction/state',
        lastInteraction.toIso8601String(),
      );
    }
    final ambient = await commands.execute('getAmbientDisplay', const {});
    _publishScreenAvailability(ambient: ambient.ok && ambient.data == true);
    final on = await commands.execute('isScreenOn', const {});
    if (on.ok) _publish('$_base/screen/state', on.data == true ? 'ON' : 'OFF');
    await _publishNextAlarm();
    final brightness = await commands.execute('getBrightness', const {});
    final level = brightness.data;
    if (brightness.ok && level is num) {
      _publish(
        '$_base/brightness/state',
        (level.clamp(0.0, 1.0) * 255).round().toString(),
      );
    }
    _publish(
      '$_base/screensaver_active/state',
      _screensaverActive ? 'ON' : 'OFF',
    );
    _publishSettingSwitchStates();
    _publishSettingSelectStates();
    _publishClockBackground();
    _publishScreensaverBrightnessLevel();
    _publishAssistantVolume();
    _publishMediaVolume();
    await _publishAdminUrl();
    await _publishVolume();
    await _publishUpdateState();
    await _publishCurrentCameraViewState();
    // Fresh link, fresh answer: the retained state may be from before a
    // reinstall or a long outage, so republish regardless of the dedupe.
    _lastForeground = '';
    await _publishForegroundApp();
    await _publishDeviceIdentity();
    // Fresh link, fresh answer, like the foreground app above.
    _lastBtConnected = null;
    _lastBtDevices = '';
    await _publishBluetoothConnections();
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

  /// The Device identity sensor (issue #213): the model as the state, the
  /// Android version and OEM build in attributes. Published once per
  /// bring-up; none of it changes while the process lives.
  Future<void> _publishDeviceIdentity() async {
    final model = _deviceInfo['model'];
    if (model is! String || model.isEmpty) return;
    final details = await commands.execute('getDeviceDetails', const {});
    final build = details.ok && details.data is Map
        ? (details.data as Map)['androidBuild']
        : null;
    _publish('$_base/device_info/state', model);
    _publish(
      '$_base/device_info/attributes',
      jsonEncode({'android_version': _deviceInfo['osVersion'], 'build': build}),
    );
  }

  /// The IP address sensors (issue #213): the primary address as the state,
  /// every other address in `other_addresses`, and all of them keyed by
  /// interface in `interfaces` so an automation can tell the wired NIC from
  /// the wireless one. Checked by the minute poll and on network
  /// transitions, published only on change.
  Future<void> _publishIpAddresses() async {
    final result = await commands.execute('getIpAddresses', const {});
    final data = result.data;
    if (!result.ok || data is! Map) return;
    _publishAddressFamily('ipv4_address', data['ipv4'], preferGlobal: false);
    _publishAddressFamily('ipv6_address', data['ipv6'], preferGlobal: true);
  }

  void _publishAddressFamily(
    String objectId,
    Object? raw, {
    required bool preferGlobal,
  }) {
    final byInterface = <String, List<String>>{
      if (raw is Map)
        for (final entry in raw.entries)
          if (entry.value is List)
            '${entry.key}': [
              // Dart reports IPv6 addresses with their scope id suffix
              // ("fd42::1%9", "fe80::1%wlan0"); the interface is already
              // named by the key, so the suffix is only noise in HA.
              for (final a in entry.value as List) '$a'.split('%').first,
            ],
    };
    final all = [for (final addresses in byInterface.values) ...addresses];
    // IPv6 interfaces list the link-local fe80:: address before the global
    // one; the routable address is the interesting one, so it wins the
    // state slot and link-local only leads when it is all there is.
    var main = all.isEmpty ? '' : all.first;
    if (preferGlobal) {
      main = all.firstWhere((a) => !a.startsWith('fe80'), orElse: () => main);
    }
    final attrs = jsonEncode({
      'other_addresses': [
        for (final address in all)
          if (address != main) address,
      ],
      'interfaces': byInterface,
    });
    if (_lastIpPayload[objectId] == '$main $attrs') return;
    _lastIpPayload[objectId] = '$main $attrs';
    // An empty state (no address of this family at all) reads as unknown
    // in Home Assistant, which is the honest answer.
    _publish('$_base/$objectId/state', main);
    _publish('$_base/$objectId/attributes', attrs);
  }

  /// Publishes a start-moment timestamp only when it genuinely moved. The
  /// anchor is re-derived every tick as now minus an uptime, which wobbles
  /// by a second of rounding either way; anything under the tolerance is
  /// the same moment restated (and would put a recorder row a minute into
  /// Home Assistant's database forever), anything over it is a real
  /// restart or reconnect. Null (no network) publishes 'None', the unknown
  /// a timestamp device class expects, once per transition.
  void _publishAnchor(String objectId, DateTime? start) {
    final known = _lastAnchor.containsKey(objectId);
    final last = _lastAnchor[objectId];
    if (start == null) {
      if (known && last == null) return;
      _lastAnchor[objectId] = null;
      _publish('$_base/$objectId/state', 'None');
      return;
    }
    if (last != null &&
        start.difference(last).abs() < const Duration(seconds: 5)) {
      return;
    }
    _lastAnchor[objectId] = start;
    _publish('$_base/$objectId/state', start.toIso8601String());
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
      }),
    );
  }

  /// Minute ticks since the last dashboard view refresh; every fifth poll
  /// re-reads the list so an added or removed dashboard shows up in the
  /// select within a few minutes with no page load needed.
  int _viewRefreshTicks = 0;

  Future<void> _pollStats() async {
    if (!_connected) return;
    if (++_viewRefreshTicks >= 5) {
      _viewRefreshTicks = 0;
      unawaited(_refreshDashboardViews());
    }
    unawaited(_publishForegroundApp());
    unawaited(_publishIpAddresses());
    unawaited(_publishBtProxyNearby());
    unawaited(_publishBluetoothConnections());
    // Timestamp anchors, not counters: each tick re-derives when the app
    // and the network came up and republishes only when an anchor actually
    // moved (a restart, a reconnect), so the recorder logs those moments
    // instead of a new row every minute. Home Assistant renders the
    // ticking "n hours ago" on its own.
    final up = await commands.execute('getUptime', const {});
    if (up.ok && up.data is Map) {
      final uptime = up.data as Map;
      final now = DateTime.now().toUtc();
      final app = (uptime['app'] as num?)?.toInt();
      if (app != null) {
        _publishAnchor('app_uptime', now.subtract(Duration(seconds: app)));
      }
      final network = (uptime['network'] as num?)?.toInt();
      _publishAnchor(
        'network_uptime',
        network == null ? null : now.subtract(Duration(seconds: network)),
      );
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
    if (temp != null && !_cpuTempPresent) {
      // The bring-up probe read nothing (a device sitting under the
      // plausibility floor in a cold room) but the sensor works after
      // all: revive the entity.
      _cpuTempPresent = true;
      unawaited(_publishDiscovery());
    }
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
    '$_prefix/sensor/ks_$_deviceId/last_interaction/config',
    '$_prefix/binary_sensor/ks_$_deviceId/connectivity/config',
    '$_prefix/sensor/ks_$_deviceId/foreground_app/config',
    '$_prefix/sensor/ks_$_deviceId/btproxy_nearby/config',
    '$_prefix/sensor/ks_$_deviceId/bt_devices_connected/config',
    '$_prefix/sensor/ks_$_deviceId/device_info/config',
    '$_prefix/sensor/ks_$_deviceId/ipv4_address/config',
    '$_prefix/sensor/ks_$_deviceId/ipv6_address/config',
    '$_prefix/sensor/ks_$_deviceId/app_uptime/config',
    '$_prefix/sensor/ks_$_deviceId/network_uptime/config',
    '$_prefix/switch/ks_$_deviceId/screensaver_active/config',
    '$_prefix/button/ks_$_deviceId/postpone_screensaver/config',
    '$_prefix/button/ks_$_deviceId/reload/config',
    '$_prefix/button/ks_$_deviceId/load_start_url/config',
    '$_prefix/button/ks_$_deviceId/clear_cache/config',
    '$_prefix/button/ks_$_deviceId/restart/config',
    '$_prefix/button/ks_$_deviceId/bring_to_front/config',
    '$_prefix/button/ks_$_deviceId/open_launcher/config',
    '$_prefix/button/ks_$_deviceId/show_music_assistant/config',
    '$_prefix/update/ks_$_deviceId/update/config',
    // Always in the retraction list even though it is published
    // conditionally: a config export moved to sensor-less hardware must
    // still clean the entity up.
    '$_prefix/sensor/ks_$_deviceId/illuminance/config',
    // Conditional too (motion sensor toggle + camera enabled).
    '$_prefix/binary_sensor/ks_$_deviceId/motion/config',
    '$_prefix/select/ks_$_deviceId/dashboard_view/config',
    '$_prefix/sensor/ks_$_deviceId/admin_url/config',
    '$_prefix/text/ks_$_deviceId/clock_background/config',
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
    '$_prefix/camera/ks_$_deviceId/screenshot/config',
    '$_prefix/button/ks_$_deviceId/take_screenshot/config',
    '$_prefix/sensor/ks_$_deviceId/last_screenshot/config',
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
    // HA kiosk mode had a strategy select next to its switch while the
    // hiding could be delegated to the kiosk-mode resource. It is one
    // switch now, so the dropdown has to go rather than linger as a
    // dead entity.
    '$_prefix/select/ks_$_deviceId/ha_kiosk_method/config',
  ];

  Future<void> _publishDiscovery() async {
    // One-time migrations: Home Assistant only re-reads entity_category
    // (and other registration-time fields) when an entity is registered
    // anew — a config update on the same topic leaves an upgraded
    // device's entity parked in its old area forever. Retract the moved
    // entities once, right before the fresh configs below re-register
    // them; HA restores entity ids and customizations on the re-add.
    // Bump the generation and grow the list when another entity moves:
    //  1: the screensaver switch became the setting-backed master toggle
    //     and moved to Configuration (issue #152).
    //  2: the Clear cache and Restart app buttons moved from
    //     Configuration to Controls.
    //  3: the App uptime and Network uptime sensors turned from duration
    //     counters into timestamp anchors (issue #213) — device_class and
    //     unit are registration-time fields.
    const migrationGeneration = 3;
    final migrated =
        int.tryParse(_settings.internal('mqtt_discovery_generation')) ??
        // The flag generation 1 shipped under, mapped so those
        // devices skip only what they already did.
        (_settings.internal('mqtt_screensaver_switch_migrated') == '1' ? 1 : 0);
    if (_connected && migrated < migrationGeneration) {
      if (migrated < 1) {
        _publish('$_prefix/switch/ks_$_deviceId/screensaver/config', '');
      }
      if (migrated < 2) {
        _publish('$_prefix/button/ks_$_deviceId/clear_cache/config', '');
        _publish('$_prefix/button/ks_$_deviceId/restart/config', '');
      }
      if (migrated < 3) {
        _publish('$_prefix/sensor/ks_$_deviceId/app_uptime/config', '');
        _publish('$_prefix/sensor/ks_$_deviceId/network_uptime/config', '');
      }
      await _settings.setInternal(
        'mqtt_discovery_generation',
        '$migrationGeneration',
      );
      await _settings.setInternal('mqtt_screensaver_switch_migrated', '');
    }
    final configuredName = _settings.get(defs.deviceName).trim();
    final model = _deviceInfo['model'];
    // The adopted real Wi-Fi MAC (issue #252): as a connections entry it
    // merges this device with the ESPHome device and with the entries
    // router integrations register for the same hardware. Absent while the
    // setting is off or the platform hides the address.
    final realMac = await adoptedWifiMac(_settings);
    final deviceBlock = {
      'identifiers': ['ks_$_deviceId'],
      if (realMac != null)
        'connections': [
          ['mac', realMac.toLowerCase()],
        ],
      'name': configuredName.isEmpty
          ? (model is String && model.isNotEmpty ? model : 'Kiosk Satellite')
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
      if (_deviceInfo['appVersion'] is String) 'sw': _deviceInfo['appVersion'],
      'url': 'https://github.com/jxlarrea/kiosk-satellite',
    };
    Map<String, Object?> common(String objectId, String entityName) => {
      'unique_id': 'ks_${_deviceId}_$objectId',
      'name': entityName,
      'availability_topic': _availabilityTopic,
      'device': deviceBlock,
      'origin': origin,
    };

    Map<String, Object?> settingSwitch(
      String objectId,
      String entityName,
      String icon,
    ) => {
      ...common(objectId, entityName),
      'state_topic': '$_base/$objectId/state',
      'command_topic': '$_base/$objectId/set',
      'icon': icon,
      'entity_category': 'config',
    };

    Map<String, Object?> settingSelect(
      String objectId,
      (defs.SettingDef<String>, String, String) entry,
    ) {
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
      // Conditional like illuminance: a device that cannot read any
      // thermal sensor (issue #138) gets no entity rather than a
      // permanently unknown one.
      if (_cpuTempPresent)
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
      // The availability topic reread as a state (issue #217): ON while
      // the device holds its broker session, OFF the moment the will
      // fires or the app says goodbye. Zero extra traffic — nothing new
      // is ever published — and it gives automations and history a
      // stable online/offline entity instead of triggering on some other
      // entity's unavailability (which can have its own causes: the
      // Screen light withdraws on ambient displays, camera entities are
      // retracted with the camera toggle). Deliberately not gated by the
      // availability it displays: its whole job is to be readable, and
      // OFF, while the device is gone.
      '$_prefix/binary_sensor/ks_$_deviceId/connectivity/config': {
        ...common('connectivity', 'Connectivity'),
        'state_topic': _availabilityTopic,
        'payload_on': 'online',
        'payload_off': 'offline',
        'device_class': 'connectivity',
        'entity_category': 'diagnostic',
      }..remove('availability_topic'),
      // When the device last came online (issue #75, reshaped with #213):
      // stamped once per broker connect and once more on a graceful
      // goodbye, not every minute — a constant state costs the recorder
      // nothing. Retained so it stays readable across an HA restart, and
      // deliberately no availability topic — the timestamp exists to be
      // read after the device has dropped, which is exactly when an
      // availability-gated entity would hide it.
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
      // The standalone motion sensor (Camera > Motion Detection). The app
      // only publishes ON ticks; off_delay makes HA clear the sensor after
      // quiet, so there is no OFF publishing or timer anywhere in the app.
      if (_settings.get(defs.motionSensor) && _cameraEntitiesWanted)
        '$_prefix/binary_sensor/ks_$_deviceId/motion/config': {
          ...common('motion', 'Motion'),
          'state_topic': '$_base/motion/state',
          'device_class': 'motion',
          'off_delay': _settings
              .get(defs.motionSensorOffDelay)
              .toInt()
              .clamp(1, 300),
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
      // When the user last touched the screen or spoke to the device
      // (issue #241): an idle kiosk is one whose stamp is old, which a
      // template can read directly (now() minus the state) instead of the
      // app guessing an idle threshold for everyone. Throttled to one
      // publish a minute under a continuous stream of touches, with the
      // final touch always stamped accurately.
      '$_prefix/sensor/ks_$_deviceId/last_interaction/config': {
        ...common('last_interaction', 'Last interaction'),
        'state_topic': '$_base/last_interaction/state',
        'device_class': 'timestamp',
        'icon': 'mdi:gesture-tap',
      },
      '$_prefix/sensor/ks_$_deviceId/admin_url/config': {
        ...common('admin_url', 'Remote admin'),
        'state_topic': '$_base/admin_url/state',
        'icon': 'mdi:remote-desktop',
        'entity_category': 'diagnostic',
      },
      // Which app is on screen (issue #192), so an automation can notice
      // the kiosk left behind another app. Naming other apps needs the
      // Usage access grant; without it the state only moves between
      // Kiosk Satellite and Unknown.
      '$_prefix/sensor/ks_$_deviceId/foreground_app/config': {
        ...common('foreground_app', 'Foreground app'),
        'state_topic': '$_base/foreground_app/state',
        'json_attributes_topic': '$_base/foreground_app/attributes',
        'icon': 'mdi:application-outline',
        'entity_category': 'diagnostic',
      },
      // What the Bluetooth proxy hears, identified as far as honesty
      // allows: the count as the state, the device list (name, vendor,
      // RSSI, last seen) as attributes for dashboards and templates.
      if (_settings.get(defs.btproxyEnabled))
        '$_prefix/sensor/ks_$_deviceId/btproxy_nearby/config': {
          ...common('btproxy_nearby', 'Bluetooth devices nearby'),
          'state_topic': '$_base/btproxy_nearby/state',
          'json_attributes_topic': '$_base/btproxy_nearby/attributes',
          'icon': 'mdi:bluetooth-audio',
          'entity_category': 'diagnostic',
        },
      // The kiosk's own Bluetooth links (issue #281), separate from the
      // proxy's nearby inventory above: how many devices it is connected to
      // right now, with their names as attributes.
      if (_btConnectionsPresent && _settings.get(defs.btproxyEnabled))
        '$_prefix/sensor/ks_$_deviceId/bt_devices_connected/config': {
          ...common('bt_devices_connected', 'Bluetooth devices connected'),
          'state_topic': '$_base/bt_devices_connected/state',
          'json_attributes_topic': '$_base/bt_devices_connected/attributes',
          'icon': 'mdi:bluetooth-connect',
          'state_class': 'measurement',
          'entity_category': 'diagnostic',
        },
      // The hardware identity and addresses the remote admin's Device page
      // shows, as diagnostic sensors (issue #213), so dashboards and
      // scripts can read them without opening the admin.
      '$_prefix/sensor/ks_$_deviceId/device_info/config': {
        ...common('device_info', 'Device'),
        'state_topic': '$_base/device_info/state',
        'json_attributes_topic': '$_base/device_info/attributes',
        'icon': 'mdi:information-outline',
        'entity_category': 'diagnostic',
      },
      '$_prefix/sensor/ks_$_deviceId/ipv4_address/config': {
        ...common('ipv4_address', 'IPv4 address'),
        'state_topic': '$_base/ipv4_address/state',
        'json_attributes_topic': '$_base/ipv4_address/attributes',
        'icon': 'mdi:ip-network',
        'entity_category': 'diagnostic',
      },
      '$_prefix/sensor/ks_$_deviceId/ipv6_address/config': {
        ...common('ipv6_address', 'IPv6 address'),
        'state_topic': '$_base/ipv6_address/state',
        'json_attributes_topic': '$_base/ipv6_address/attributes',
        'icon': 'mdi:ip-network-outline',
        'entity_category': 'diagnostic',
      },
      // Timestamps of when the app and the network came up, not second
      // counters: the state only moves on a real restart or reconnect, so
      // the recorder logs those moments and nothing else, and HA renders
      // the ticking "n hours ago" itself (issue #213).
      '$_prefix/sensor/ks_$_deviceId/app_uptime/config': {
        ...common('app_uptime', 'App uptime'),
        'state_topic': '$_base/app_uptime/state',
        'device_class': 'timestamp',
        'icon': 'mdi:timer-outline',
        'entity_category': 'diagnostic',
      },
      '$_prefix/sensor/ks_$_deviceId/network_uptime/config': {
        ...common('network_uptime', 'Network uptime'),
        'state_topic': '$_base/network_uptime/state',
        'device_class': 'timestamp',
        'icon': 'mdi:timer-sync-outline',
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
      // The screen as Home Assistant can see it (issue #168): a still
      // camera fed only by the button beside it, for checking on a panel
      // that is not in the same building. Same shape as the device camera
      // below — retained frame, timestamp sensor for freshness — but it
      // needs no camera hardware, so it is always published.
      '$_prefix/camera/ks_$_deviceId/screenshot/config': {
        ...common('screenshot', 'Screenshot'),
        'topic': '$_base/screenshot/image',
      },
      '$_prefix/button/ks_$_deviceId/take_screenshot/config': {
        ...common('take_screenshot', 'Take screenshot'),
        'command_topic': '$_base/screenshot/set',
        'payload_press': 'SCREENSHOT',
        'icon': 'mdi:monitor-screenshot',
      },
      '$_prefix/sensor/ks_$_deviceId/last_screenshot/config': {
        ...common('last_screenshot', 'Last screenshot'),
        'state_topic': '$_base/screenshot/at',
        'device_class': 'timestamp',
        'icon': 'mdi:monitor-screenshot',
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
          ...common('camera_view_${view['id']}', 'Show ${view['name']}'),
          'command_topic': '$_base/camera/view/set',
          'payload_press': '${view['id']}',
          'icon': 'mdi:cctv',
        },
      // Every view in one control: pick a view to show it, Closed to
      // close. Only published once a view exists — a select holding
      // nothing but Closed is noise. Options are view names (unique by
      // construction); the config republish on every camera configuration
      // change keeps them current through renames.
      if (_cameraViews.isNotEmpty)
        '$_prefix/select/ks_$_deviceId/camera_view/config': {
          ...common('camera_view', 'Camera view'),
          'state_topic': '$_base/camera/view/selected',
          'command_topic': '$_base/camera/view/select',
          'options': [
            'Closed',
            for (final view in _cameraViews) '${view['name']}',
          ],
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
      // Whether a screensaver is on screen right now; ON/OFF forces it up
      // or dismisses it. The master enable/disable is the "Screensaver"
      // setting switch below (issue #152).
      '$_prefix/switch/ks_$_deviceId/screensaver_active/config': {
        ...common('screensaver_active', 'Screensaver active'),
        'state_topic': '$_base/screensaver_active/state',
        'command_topic': '$_base/screensaver_active/set',
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
      '$_prefix/button/ks_$_deviceId/postpone_screensaver/config': {
        ...common('postpone_screensaver', 'Postpone screensaver'),
        'command_topic': '$_base/postpone_screensaver/set',
        'icon': 'mdi:timer-refresh-outline',
      },
      '$_prefix/button/ks_$_deviceId/reload/config': {
        ...common('reload', 'Reload page'),
        'command_topic': '$_base/reload/set',
        'icon': 'mdi:refresh',
      },
      '$_prefix/button/ks_$_deviceId/load_start_url/config': {
        ...common('load_start_url', 'Go to dashboard'),
        'command_topic': '$_base/load_start_url/set',
        'icon': 'mdi:view-dashboard',
      },
      '$_prefix/button/ks_$_deviceId/clear_cache/config': {
        ...common('clear_cache', 'Clear cache'),
        'command_topic': '$_base/clear_cache/set',
        'icon': 'mdi:broom',
      },
      '$_prefix/button/ks_$_deviceId/restart/config': {
        ...common('restart', 'Restart app'),
        'command_topic': '$_base/restart/set',
        'device_class': 'restart',
      },
      '$_prefix/button/ks_$_deviceId/bring_to_front/config': {
        ...common('bring_to_front', 'Bring to front'),
        'command_topic': '$_base/bring_to_front/set',
        'icon': 'mdi:flip-to-front',
      },
      // Only while the launcher is enabled: a disabled launcher leaves no
      // button in HA (retraction below, and in _discoveryTopics).
      if (_settings.get(defs.launcherEnabled))
        '$_prefix/button/ks_$_deviceId/open_launcher/config': {
          ...common('open_launcher', 'Open app launcher'),
          'command_topic': '$_base/open_launcher/set',
          'icon': 'mdi:apps',
        },
      // Only with a Music Assistant server address configured, exactly like
      // the kiosk menu entry (retraction below, and in _discoveryTopics).
      if (musicAssistantWebUrl(_settings.get(defs.sendspinMaUrl)) != null)
        '$_prefix/button/ks_$_deviceId/show_music_assistant/config': {
          ...common('show_music_assistant', 'Show Music Assistant'),
          'command_topic': '$_base/show_music_assistant/set',
          'icon': 'mdi:music-box-multiple',
        },
      '$_prefix/update/ks_$_deviceId/update/config': {
        ...common('update', 'Update'),
        'state_topic': '$_base/update/state',
        'command_topic': '$_base/update/set',
        'payload_install': 'install',
        'device_class': 'firmware',
      },
      // The Clock screensaver's background photo as a settable path
      // (issue #150): automations rotate it among images already on the
      // device. Writes land on the same setting the device picker uses.
      '$_prefix/text/ks_$_deviceId/clock_background/config': {
        ...common('clock_background', 'Clock background'),
        'state_topic': '$_base/clock_background/state',
        'command_topic': '$_base/clock_background/set',
        'icon': 'mdi:image-frame',
        'entity_category': 'config',
      },
      '$_prefix/number/ks_$_deviceId/screensaver_brightness_level/config': {
        ...common(
          'screensaver_brightness_level',
          'Screensaver brightness level',
        ),
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
      '$_prefix/switch/ks_$_deviceId/kiosk/config': settingSwitch(
        'kiosk',
        'Kiosk mode',
        'mdi:lock-outline',
      ),
      '$_prefix/switch/ks_$_deviceId/lockdown/config': settingSwitch(
        'lockdown',
        'Lockdown mode',
        'mdi:shield-lock',
      ),
      '$_prefix/switch/ks_$_deviceId/ha_kiosk/config': settingSwitch(
        'ha_kiosk',
        'HA kiosk mode',
        'mdi:dock-top',
      ),
      '$_prefix/switch/ks_$_deviceId/keep_screen_on/config': settingSwitch(
        'keep_screen_on',
        'Keep screen on',
        'mdi:lightbulb-on-outline',
      ),
      '$_prefix/switch/ks_$_deviceId/remote/config': settingSwitch(
        'remote',
        'Remote management',
        'mdi:remote-desktop',
      ),
      '$_prefix/switch/ks_$_deviceId/screensaver_brightness/config':
          settingSwitch(
            'screensaver_brightness',
            'Screensaver brightness',
            'mdi:brightness-4',
          ),
      '$_prefix/switch/ks_$_deviceId/screensaver/config': settingSwitch(
        'screensaver',
        'Screensaver',
        'mdi:sleep',
      ),
      '$_prefix/switch/ks_$_deviceId/hold_mode/config': settingSwitch(
        'hold_mode',
        'Hold mode',
        'mdi:pause-circle-outline',
      ),
      // Camera-dependent controls (discussion #155): only on hardware
      // that can actually run them, retracted below otherwise. Unlike
      // the camera entities they do NOT ride the enable toggle — the
      // switch is the way to flip that toggle remotely.
      if (_cameraPresent) ...{
        '$_prefix/switch/ks_$_deviceId/camera_enabled/config': settingSwitch(
          'camera_enabled',
          'Camera enabled',
          'mdi:camera-outline',
        ),
        '$_prefix/switch/ks_$_deviceId/screensaver_motion/config':
            settingSwitch(
              'screensaver_motion',
              'Screensaver motion detection',
              'mdi:motion-sensor',
            ),
      },
      for (final entry in _settingSelects.entries)
        if (entry.key != 'camera_device' || _cameraFacingWanted)
          '$_prefix/select/ks_$_deviceId/${entry.key}/config': settingSelect(
            entry.key,
            entry.value,
          ),
    };
    for (final topic in _legacyDiscoveryTopics()) {
      _publish(topic, '');
    }
    // Same for the app launcher's button while the launcher is off.
    if (!_settings.get(defs.launcherEnabled)) {
      _publish('$_prefix/button/ks_$_deviceId/open_launcher/config', '');
    }
    // And the Music Assistant button while no server address is set.
    if (musicAssistantWebUrl(_settings.get(defs.sendspinMaUrl)) == null) {
      _publish('$_prefix/button/ks_$_deviceId/show_music_assistant/config', '');
    }
    // A CPU temperature config from an older build (or an optimistic
    // default) is retracted once the probe has said this device cannot
    // read one, instead of lingering as a dead entity.
    if (!_cpuTempPresent) {
      _publish('$_prefix/sensor/ks_$_deviceId/cpu_temp/config', '');
    }
    // Same for the Bluetooth links, off with the proxy switch or on a
    // device that will not report them.
    if (!_btConnectionsPresent || !_settings.get(defs.btproxyEnabled)) {
      _publish('$_prefix/sensor/ks_$_deviceId/bt_devices_connected/config', '');
    }
    // Self-correcting: a camera config published before the presence probe
    // answered (or before the feature was turned off) is retracted on the
    // next discovery pass instead of lingering as a dead entity.
    if (!_cameraEntitiesWanted) {
      _publish('$_prefix/camera/ks_$_deviceId/device_camera/config', '');
      _publish('$_prefix/button/ks_$_deviceId/take_snapshot/config', '');
      _publish('$_prefix/sensor/ks_$_deviceId/last_snapshot/config', '');
    }
    // The camera-dependent switches follow the hardware, not the toggle:
    // a config restored onto camera-less hardware cleans them up here.
    if (!_cameraPresent) {
      _publish('$_prefix/switch/ks_$_deviceId/camera_enabled/config', '');
      _publish('$_prefix/switch/ks_$_deviceId/screensaver_motion/config', '');
    }
    // Same self-correction for the facing select on single-camera hardware:
    // a config from an optimistic pass (or a restored backup) is retracted
    // once the facings probe has said there is no choice to offer.
    if (!_cameraFacingWanted) {
      _publish('$_prefix/select/ks_$_deviceId/camera_device/config', '');
    }
    final currentIds = {for (final view in _cameraViews) '${view['id']}'};
    for (final staleId in _publishedCameraViewIds.difference(currentIds)) {
      _publish('$_prefix/button/ks_$_deviceId/camera_view_$staleId/config', '');
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
        // A FAILED read (websocket down, HA restarting) says nothing about
        // the dashboard: abort and keep the last known list. Falling back
        // to the bare path here downgraded the whole select to viewless
        // options — and persisted the downgrade — whenever a refresh ran
        // inside a websocket outage, leaving retained "dashboard/view"
        // states invalid in HA (issue #214).
        if (!views.ok) return;
        final viewData = views.data;
        if (viewData is List && viewData.isNotEmpty) {
          for (final v in viewData) {
            if (v is Map) options.add('$urlPath/${v['route']}');
          }
        } else {
          // A dashboard that genuinely holds no view list (auto-generated
          // strategy dashboards) still navigates by its bare path.
          options.add(urlPath);
        }
      }
      if (options.isEmpty ||
          jsonEncode(options) == jsonEncode(_dashboardViews)) {
        return;
      }
      _dashboardViews = options;
      await _settings.setInternal('mqtt_dashboard_views', jsonEncode(options));
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

  /// The select option a URL corresponds to; shared with the ESPHome
  /// entity surface (dashboard_views.dart) so both selects agree.
  @visibleForTesting
  static String? matchDashboardView(String url, List<String> options) =>
      shared.matchDashboardView(url, options);

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
    // The select's mirror of the same state: its vocabulary is its own
    // options. The empty state is "Closed", never "None" — Home Assistant
    // reserves that payload and would blank the select to unknown.
    _publish('$_base/camera/view/selected', event.viewName ?? 'Closed');
    _publish('$_base/camera/view/attributes', jsonEncode(event.toJson()));
  }

  Future<void> _publishCurrentCameraViewState() async {
    final result = await commands.execute('cameraStatus', const {});
    final data = result.data;
    if (!result.ok || data is! Map) return;
    final viewName = data['viewName'] is String ? '${data['viewName']}' : null;
    _publish('$_base/camera/view/state', viewName ?? 'none');
    _publish('$_base/camera/view/selected', viewName ?? 'Closed');
    _publish('$_base/camera/view/attributes', jsonEncode(data));
  }
}
