import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show PlatformDispatcher;

import '../../core/command_registry.dart';
import '../../core/event_bus.dart';
import '../../core/events.dart';
import '../../core/logging.dart';
import '../device/ip_addresses.dart';
import '../mqtt/dashboard_views.dart';
import '../mqtt/interaction_stamp.dart';
import '../sendspin/music_assistant_api.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// The kiosk entities served over the ESPHome native API: the full MQTT
/// catalog, one entity at a time, so the MQTT integration can sunset. This
/// is the Dart half of the pair with the native EntityHub: it owns WHAT
/// exists, what values mean and what commands do; the native side owns the
/// wire. Sources and command handlers are the exact ones the MQTT entities
/// use, so both surfaces agree while they coexist.
///
/// Entity object ids and names are permanent API: names become Home
/// Assistant entity ids (`sensor.<device>_battery`) and survive in users'
/// automations, and both mirror the MQTT catalog so a migrating automation
/// only swaps the device half of the id. Never rename one casually.
///
/// The one deliberate absence: a second camera. The ESPHome camera
/// protocol has no entity key in its image request, so one camera exists
/// per device - the device camera when present and enabled, else the
/// screenshot camera.
class EspEntitySurface {
  EspEntitySurface(this.bus, this.commands, this.log, this._settings);

  final EventBus bus;
  final CommandRegistry commands;
  final Logger log;
  final SettingsManager _settings;

  static const _pollInterval = Duration(seconds: 60);

  /// Sends one entity's fresh value to the native hub; set while attached.
  Future<void> Function(String objectId, Object? value)? _push;

  /// Sends a camera frame to sessions with an outstanding request.
  Future<void> Function(Uint8List jpeg)? _pushImage;

  final List<StreamSubscription<Object?>> _subs = [];
  Timer? _poll;
  Timer? _motionOff;

  /// Coalesces the ACL broadcast flurry one connection makes into a single
  /// read of the link count.
  Timer? _btNudge;

  // Learned at build time; commands and states need them afterwards.
  List<Map<String, Object?>> _cameraViews = const [];
  List<String> _dashboardViews = const [];
  bool _deviceCameraIsTheCamera = false;
  bool _screensaverActive = false;

  /// Whether the Voice Satellite entities are in this run's catalog, so a
  /// push never names an entity Home Assistant was never told about.
  bool _voiceSatellite = false;

  /// Coalesces the burst of wake-word state changes one voice turn makes
  /// into a single read of the page's engine state.
  Timer? _vsNudge;

  /// Uptime anchors last pushed, so a poll only republishes when the
  /// start moment genuinely moved (same 5-second tolerance as MQTT:
  /// second-to-second jitter in "now minus uptime" is not a restart).
  final Map<String, DateTime?> _lastAnchor = {};

  /// The Last interaction sensor's stamp (issue #241). Persisted like the
  /// last lux reading: with no broker to retain it, the store is what keeps
  /// a restarted device from reading idle-since-boot.
  late final _interaction = InteractionStamp((stamp) {
    final iso = stamp.toIso8601String();
    _send('last_interaction', iso);
    _settings.setInternal('esphome_last_interaction', iso);
  });

  /// Settings-backed switches: objectId -> (name, icon, definition).
  /// Mirrors the MQTT _settingSwitches map, entity ids and all.
  static final _settingSwitches =
      <String, (String, String, defs.SettingDef<bool>)>{
        'kiosk': ('Kiosk mode', 'mdi:lock-outline', defs.kioskEnabled),
        'lockdown': ('Lockdown mode', 'mdi:shield-lock', defs.lockdownEnabled),
        'ha_kiosk': ('HA kiosk mode', 'mdi:dock-top', defs.haKioskMode),
        'keep_screen_on': (
          'Keep screen on',
          'mdi:lightbulb-on-outline',
          defs.keepScreenOn,
        ),
        'remote': (
          'Remote management',
          'mdi:remote-desktop',
          defs.remoteEnabled,
        ),
        'screensaver_brightness': (
          'Screensaver brightness',
          'mdi:brightness-4',
          defs.screensaverBrightnessEnabled,
        ),
        'screensaver': ('Screensaver', 'mdi:sleep', defs.screensaverEnabled),
        'hold_mode': ('Hold mode', 'mdi:pause-circle-outline', defs.haHoldMode),
        'camera_enabled': (
          'Camera enabled',
          'mdi:camera-outline',
          defs.cameraEnabled,
        ),
        'screensaver_motion': (
          'Screensaver motion detection',
          'mdi:motion-sensor',
          defs.screensaverDismissOnMotion,
        ),
        'screensaver_face': (
          'Screensaver face detection',
          'mdi:face-recognition',
          defs.screensaverDismissOnFace,
        ),
      };

  /// Settings-backed selects: objectId -> (name, icon, definition). The
  /// options are the definitions' display labels, the stored value maps
  /// through them, matching the MQTT contract.
  static final _settingSelects =
      <String, (String, String, defs.SettingDef<String>)>{
        'screensaver_mode': (
          'Screensaver mode',
          'mdi:monitor-shimmer',
          defs.screensaverMode,
        ),
        'screensaver_clock_style': (
          'Clock style',
          'mdi:clock-digital',
          defs.screensaverClockStyle,
        ),
        // Front/back camera pick (issue #296): catalog-gated below on the
        // device actually having both facings, like the camera switches
        // are gated on the hardware existing at all.
        'camera_device': (
          'Camera facing',
          'mdi:camera-flip-outline',
          defs.cameraDevice,
        ),
      };

  /// Settings-backed numbers shown as 0-100 percent sliders:
  /// objectId -> (name, icon, definition, stored 0..1 instead of 0..100).
  static final _settingNumbers =
      <String, (String, String, defs.SettingDef<num>, bool)>{
        'screensaver_brightness_level': (
          'Screensaver brightness level',
          'mdi:brightness-6',
          defs.screensaverBrightnessLevel,
          true,
        ),
        'assistant_volume': (
          'Assistant volume',
          'mdi:account-voice',
          defs.assistantVolume,
          false,
        ),
        'media_volume': (
          'Media volume',
          'mdi:music-note',
          defs.mediaVolume,
          false,
        ),
      };

  /// Probes the hardware and Home Assistant, then lays out the catalog.
  /// The set is fixed for one server run; the manager restarts the server
  /// on the settings that change it.
  Future<List<Map<String, Object?>>> build() async {
    final light = await commands.execute('getLightLevel', const {});
    final lightSensorPresent =
        light.ok && light.data is Map && (light.data as Map)['present'] == true;
    final cam = await commands.execute('hasDeviceCamera', const {});
    final cameraPresent = !(cam.ok && cam.data == false);
    // The facing select only exists where there is a choice: single-camera
    // hardware (Echo Show 5) gets none. An empty answer means the probe
    // could not look yet, and optimism matches hasDeviceCamera above.
    final facings = await commands.execute('getCameraFacings', const {});
    final facingList = facings.ok && facings.data is List
        ? [for (final f in facings.data as List) '$f']
        : const <String>[];
    final bothFacings =
        facingList.isEmpty ||
        (facingList.contains('front') && facingList.contains('back'));
    final stats = await commands.execute('getStats', const {});
    final cpuTempPresent =
        stats.ok && stats.data is Map && (stats.data as Map)['temp'] != null;
    // Bluetooth connections ride the proxy's master switch, and only exist
    // where Android answers at all: with no adapter, or no Nearby devices
    // grant on Android 12+, the sensor could never report anything but
    // unknown (issue #281).
    final bt = _settings.get(defs.btproxyEnabled)
        ? await commands.execute('getBluetoothConnections', const {})
        : null;
    final btConnectionsReadable =
        bt != null &&
        bt.ok &&
        bt.data is Map &&
        (bt.data as Map)['connected'] != null;
    final cameraWanted = cameraPresent && _settings.get(defs.cameraEnabled);
    _deviceCameraIsTheCamera = cameraWanted;
    // The Voice Satellite controls exist where a satellite is bound: the
    // setup wizard and the settings page both record the binding here, and
    // a kiosk with none has no engine to start (issue #288). Reading the
    // page instead would make the catalog depend on what was on screen the
    // moment the server started.
    _voiceSatellite = _settings.get(defs.haSatelliteEntity).trim().isNotEmpty;
    await _refreshCameraViews();
    await _refreshDashboardViews();

    Map<String, Object?> button(
      String id,
      String name,
      String icon, {
      String deviceClass = '',
    }) => {
      'type': 'button',
      'objectId': id,
      'name': name,
      'icon': icon,
      'deviceClass': deviceClass,
    };
    Map<String, Object?> diagnostic(
      String id,
      String name, {
      String icon = '',
      String deviceClass = '',
      String unit = '',
      int stateClass = 0,
      String type = 'sensor',
    }) => {
      'type': type,
      'objectId': id,
      'name': name,
      'icon': icon,
      'deviceClass': deviceClass,
      'unit': unit,
      'stateClass': stateClass,
      'category': 2,
    };

    return [
      // ── Controls ─────────────────────────────────────────────────────
      {
        'type': 'light',
        'objectId': 'screen',
        'name': 'Screen',
        'icon': 'mdi:tablet',
      },
      {
        'type': 'switch',
        'objectId': 'screensaver_active',
        'name': 'Screensaver active',
        'icon': 'mdi:sleep',
      },
      {
        'type': 'number',
        'objectId': 'volume',
        'name': 'Volume',
        'icon': 'mdi:volume-high',
        'min': 0,
        'max': 100,
        'step': 1,
        'unit': '%',
        'mode': 2,
      },
      if (_voiceSatellite)
        {
          'type': 'switch',
          'objectId': 'voice_satellite',
          'name': 'Voice Satellite',
          'icon': 'mdi:account-voice',
        },
      button(
        'postpone_screensaver',
        'Postpone screensaver',
        'mdi:timer-refresh-outline',
      ),
      button(
        'screensaver_next_slide',
        'Screensaver next slide',
        'mdi:skip-next',
      ),
      button(
        'screensaver_previous_slide',
        'Screensaver previous slide',
        'mdi:skip-previous',
      ),
      button('reload', 'Reload page', 'mdi:refresh'),
      button('load_start_url', 'Go to dashboard', 'mdi:view-dashboard'),
      button('clear_cache', 'Clear cache', 'mdi:broom'),
      button('restart', 'Restart app', '', deviceClass: 'restart'),
      button('bring_to_front', 'Bring to front', 'mdi:flip-to-front'),
      if (_settings.get(defs.launcherEnabled))
        button('open_launcher', 'Open app launcher', 'mdi:apps'),
      // Only with a Music Assistant server address configured, exactly like
      // the kiosk menu entry: a button that can only fail is worse than no
      // button.
      if (musicAssistantWebUrl(_settings.get(defs.sendspinMaUrl)) != null)
        button(
          'show_music_assistant',
          'Show Music Assistant',
          'mdi:music-box-multiple',
        ),
      if (_cameraViews.isNotEmpty) ...[
        {
          'type': 'select',
          'objectId': 'camera_view',
          'name': 'Camera view',
          'icon': 'mdi:cctv',
          'options': [
            'Closed',
            for (final view in _cameraViews) '${view['name']}',
          ],
        },
        // One press-to-show button per view too, exactly like MQTT: the
        // select is the compact form, the buttons are what dashboards and
        // scripts press.
        for (final view in _cameraViews)
          button(
            'camera_view_${view['id']}',
            'Show ${view['name']}',
            'mdi:cctv',
          ),
        button(
          'close_camera_view',
          'Close camera view',
          'mdi:close-box-outline',
        ),
        {
          'type': 'text_sensor',
          'objectId': 'active_camera_view',
          'name': 'Active camera view',
          'icon': 'mdi:cctv',
        },
      ],
      if (_dashboardViews.isNotEmpty)
        {
          'type': 'select',
          'objectId': 'dashboard_view',
          'name': 'Dashboard view',
          'icon': 'mdi:view-dashboard-outline',
          'options': _dashboardViews,
        },
      {
        'type': 'update',
        'objectId': 'update',
        'name': 'Update',
        'deviceClass': 'firmware',
      },
      // The one camera slot the protocol allows: the device camera when
      // it exists and is enabled, else the screenshot camera.
      if (cameraWanted)
        {'type': 'camera', 'objectId': 'device_camera', 'name': 'Camera'}
      else
        {'type': 'camera', 'objectId': 'screenshot', 'name': 'Screenshot'},
      if (cameraWanted) ...[
        button('take_snapshot', 'Take camera snapshot', 'mdi:camera-iris'),
        {
          'type': 'text_sensor',
          'objectId': 'last_snapshot',
          'name': 'Last camera snapshot',
          'icon': 'mdi:camera-timer',
          'deviceClass': 'timestamp',
        },
      ],
      button('take_screenshot', 'Take screenshot', 'mdi:monitor-screenshot'),
      {
        'type': 'text_sensor',
        'objectId': 'last_screenshot',
        'name': 'Last screenshot',
        'icon': 'mdi:monitor-screenshot',
        'deviceClass': 'timestamp',
      },
      if (lightSensorPresent)
        {
          'type': 'sensor',
          'objectId': 'illuminance',
          'name': 'Ambient light',
          'deviceClass': 'illuminance',
          'unit': 'lx',
          'stateClass': 1,
        },
      if (_settings.get(defs.motionSensor) && cameraWanted)
        {
          'type': 'binary_sensor',
          'objectId': 'motion',
          'name': 'Motion',
          'deviceClass': 'motion',
        },
      {
        'type': 'text_sensor',
        'objectId': 'next_alarm',
        'name': 'Next alarm',
        'icon': 'mdi:alarm',
        'deviceClass': 'timestamp',
      },
      // When the user last touched the screen or spoke to the device
      // (issue #241), so automations can tell an idle kiosk from one in
      // use with plain timestamp arithmetic.
      {
        'type': 'text_sensor',
        'objectId': 'last_interaction',
        'name': 'Last interaction',
        'icon': 'mdi:gesture-tap',
        'deviceClass': 'timestamp',
      },
      // ── Config ───────────────────────────────────────────────────────
      for (final e in _settingNumbers.entries)
        {
          'type': 'number',
          'objectId': e.key,
          'name': e.value.$1,
          'icon': e.value.$2,
          'min': 0,
          'max': 100,
          'step': 5,
          'unit': '%',
          'mode': 2,
          'category': 1,
        },
      {
        'type': 'text',
        'objectId': 'clock_background',
        'name': 'Clock background',
        'icon': 'mdi:image-frame',
        'category': 1,
      },
      for (final e in _settingSwitches.entries)
        if (cameraPresent ||
            (e.key != 'camera_enabled' &&
                e.key != 'screensaver_motion' &&
                e.key != 'screensaver_face'))
          {
            'type': 'switch',
            'objectId': e.key,
            'name': e.value.$1,
            'icon': e.value.$2,
            'category': 1,
          },
      if (_voiceSatellite)
        {
          'type': 'switch',
          'objectId': 'voice_satellite_auto_start',
          'name': 'Voice Satellite auto start',
          'icon': 'mdi:play-circle-outline',
          'category': 1,
        },
      for (final e in _settingSelects.entries)
        if (e.key != 'camera_device' || (cameraPresent && bothFacings))
          {
            'type': 'select',
            'objectId': e.key,
            'name': e.value.$1,
            'icon': e.value.$2,
            'options': [
              for (final option in e.value.$3.options ?? const <String>[])
                e.value.$3.optionLabels?[option] ?? option,
            ],
            'category': 1,
          },
      // ── Diagnostics ──────────────────────────────────────────────────
      diagnostic(
        'battery',
        'Battery',
        deviceClass: 'battery',
        unit: '%',
        stateClass: 1,
      ),
      diagnostic(
        'charging',
        'Charging',
        deviceClass: 'battery_charging',
        type: 'binary_sensor',
      ),
      diagnostic(
        'cpu',
        'CPU usage',
        icon: 'mdi:chip',
        unit: '%',
        stateClass: 1,
      ),
      if (cpuTempPresent)
        diagnostic(
          'cpu_temp',
          'CPU temperature',
          deviceClass: 'temperature',
          unit: '°C',
          stateClass: 1,
        ),
      diagnostic(
        'ram_free',
        'RAM available',
        icon: 'mdi:memory',
        deviceClass: 'data_size',
        unit: 'MB',
        stateClass: 1,
      ),
      diagnostic(
        'ram_total',
        'RAM total',
        icon: 'mdi:memory',
        deviceClass: 'data_size',
        unit: 'MB',
      ),
      diagnostic('url', 'Current page', icon: 'mdi:web', type: 'text_sensor'),
      diagnostic(
        'foreground_app',
        'Foreground app',
        icon: 'mdi:application-outline',
        type: 'text_sensor',
      ),
      if (_settings.get(defs.btproxyEnabled))
        // state_class matters beyond statistics here: without it (or a
        // unit) Home Assistant treats the sensor as non-numeric, so the
        // count renders as the raw "13.0" string and history shows no
        // graph.
        diagnostic(
          'btproxy_nearby',
          'Bluetooth devices nearby',
          icon: 'mdi:bluetooth-audio',
          stateClass: 1,
        ),
      if (_settings.get(defs.btproxyEnabled) &&
          _settings.get(defs.btproxyConnections))
        // The ceiling the connected-devices count runs into, where the
        // user will look before filing "my fifth device won't connect":
        // the budget is a hard Android-stack limit per proxy, two on
        // Android 11 and below and three above it, and Home Assistant
        // spreads extra devices across other proxies only if there are
        // other proxies. A number rather than the "1 of 3" this used to
        // read, so a dashboard can compare it against the live count.
        diagnostic(
          'bt_max_connections',
          'Bluetooth max connections',
          icon: 'mdi:bluetooth-settings',
          stateClass: 1,
        ),
      if (btConnectionsReadable)
        // The kiosk's own Bluetooth links: the speaker, keyboard or headset
        // paired with it, plus any BLE connection the proxy is holding, so
        // "is the speaker still on it" is answerable from Home Assistant
        // (issue #281). Deliberately separate from the proxy's slot count
        // above, which is a budget rather than an inventory.
        diagnostic(
          'bt_devices_connected',
          'Bluetooth devices connected',
          icon: 'mdi:bluetooth-connect',
          stateClass: 1,
        ),
      // The MQTT twins of the four that follow carry their detail as
      // attributes on the Device and IP sensors; the ESPHome protocol has
      // no attributes to hang anything off, so each is its own text sensor
      // here and both integrations answer the same questions (issue #213).
      diagnostic(
        'device_info',
        'Device',
        icon: 'mdi:information-outline',
        type: 'text_sensor',
      ),
      diagnostic(
        'android_version',
        'Android version',
        icon: 'mdi:android',
        type: 'text_sensor',
      ),
      diagnostic(
        'android_build',
        'Android build',
        icon: 'mdi:cellphone-cog',
        type: 'text_sensor',
      ),
      diagnostic(
        'ipv4_address',
        'IPv4 address',
        icon: 'mdi:ip-network',
        type: 'text_sensor',
      ),
      diagnostic(
        'ipv4_interfaces',
        'IPv4 addresses by interface',
        icon: 'mdi:lan',
        type: 'text_sensor',
      ),
      diagnostic(
        'ipv6_address',
        'IPv6 address',
        icon: 'mdi:ip-network-outline',
        type: 'text_sensor',
      ),
      diagnostic(
        'ipv6_interfaces',
        'IPv6 addresses by interface',
        icon: 'mdi:lan-connect',
        type: 'text_sensor',
      ),
      // Timestamps like their MQTT twins: the recorder logs the moments
      // the anchors move (a restart, a reconnect) and Home Assistant
      // renders the ticking "n hours ago" on its own, instead of a
      // seconds counter churning the recorder every poll.
      diagnostic(
        'app_uptime',
        'App uptime',
        icon: 'mdi:timer-outline',
        deviceClass: 'timestamp',
        type: 'text_sensor',
      ),
      diagnostic(
        'network_uptime',
        'Network uptime',
        icon: 'mdi:timer-sync-outline',
        deviceClass: 'timestamp',
        type: 'text_sensor',
      ),
      diagnostic(
        'last_seen',
        'Last seen',
        icon: 'mdi:clock-check-outline',
        deviceClass: 'timestamp',
        type: 'text_sensor',
      ),
      // Strictly redundant over ESPHome (a lost connection makes every
      // entity unavailable), but automations written against the MQTT
      // sensor check for 'on', and 'unavailable' satisfies their
      // "not on" branch the same way 'off' did.
      diagnostic(
        'connectivity',
        'Connectivity',
        deviceClass: 'connectivity',
        type: 'binary_sensor',
      ),
      diagnostic(
        'admin_url',
        'Remote admin',
        icon: 'mdi:remote-desktop',
        type: 'text_sensor',
      ),
    ];
  }

  /// The user-defined actions served next to the entities, as Home
  /// Assistant `esphome.<device>_<name>` actions. Entity commands can only
  /// set one value on one entity; an action is the only way for Home
  /// Assistant to hand this device a payload, which is what a notification
  /// is (issue #269).
  ///
  /// Every argument is required on the Home Assistant side - its action
  /// schema marks them all so, and the ESPHome protocol has no optional
  /// arguments - so each one has a value that means "as you were": an
  /// empty title is no title, a negative duration is the default one.
  /// Argument names and order are permanent API, like entity object ids:
  /// values arrive positionally on the wire and land in users'
  /// automations by name.
  List<Map<String, Object?>> buildServices() => const [
    {
      'name': 'notification',
      'args': [
        {'name': 'message', 'type': 'string'},
        {'name': 'title', 'type': 'string'},
        {'name': 'duration', 'type': 'int'},
        {'name': 'type', 'type': 'string'},
        {'name': 'chime', 'type': 'bool'},
        {'name': 'scale', 'type': 'float'},
        {'name': 'icon', 'type': 'string'},
        {'name': 'chime_file', 'type': 'string'},
        {'name': 'volume', 'type': 'float'},
      ],
    },
  ];

  /// An action call from Home Assistant landed (via the native hub).
  Future<void> handleService(String name, Map<String, Object?> args) async {
    switch (name) {
      case 'notification':
        await commands.execute('showNotification', {
          'message': '${args['message'] ?? ''}',
          'title': '${args['title'] ?? ''}',
          // The action cannot leave a number out, so its own "unset" is
          // anything negative; showNotification reads it the same way.
          'duration': args['duration'] ?? -1,
          'type': '${args['type'] ?? ''}',
          'chime': args['chime'] ?? true,
          // Same "unset" story as the duration: 0 is what a caller who
          // does not care sends, and it means the ordinary size.
          'scale': args['scale'] ?? 0,
          // Empty is how the action says "no icon of my own", the same
          // way an empty title says "no title".
          'icon': '${args['icon'] ?? ''}',
          // A file name in the sounds folder; empty means the sound picked
          // in Settings, and 0 its volume: the two the action cannot leave
          // out (issue #320).
          'chime_file': '${args['chime_file'] ?? ''}',
          'volume': args['volume'] ?? 0,
        });
      default:
        log.warn('esphome', 'unknown action $name');
    }
  }

  /// Starts serving values: initial snapshot, change events, slow poll.
  void attach(
    Future<void> Function(String, Object?) push,
    Future<void> Function(Uint8List) pushImage,
  ) {
    _push = push;
    _pushImage = pushImage;
    _subs.add(
      bus.on<ScreensaverStateChanged>().listen((e) {
        _screensaverActive = e.active;
        _send('screensaver_active', e.active);
      }),
    );
    _subs.add(bus.on<ScreenStateChanged>().listen((_) => _sendScreen()));
    // Addresses change exactly at these transitions, and the minute poll
    // would leave the IP sensors stale until it comes round. Deferred a
    // moment so DHCP has settled by the time we look, like the MQTT twin.
    _subs.add(
      bus.on<NetworkStateChanged>().listen((_) {
        Timer(const Duration(seconds: 3), _sendIpAddresses);
      }),
    );
    // A link coming up or going down, rather than the minute poll: a lock
    // Home Assistant holds for half a minute would otherwise never show
    // (issue #281). Coalesced, since one connection fires several
    // broadcasts and the count is the same for all of them.
    _subs.add(
      bus.on<BluetoothLinksChanged>().listen((_) {
        _btNudge?.cancel();
        _btNudge = Timer(
          const Duration(milliseconds: 700),
          () => unawaited(_sendBluetooth()),
        );
      }),
    );
    _subs.add(bus.on<BrightnessChanged>().listen((_) => _sendScreen()));
    _subs.add(bus.on<VolumeChanged>().listen((_) => _sendVolume()));
    _subs.add(
      bus.on<UrlChanged>().listen((e) {
        _send('url', e.url);
        final match = matchDashboardView(e.url, _dashboardViews);
        if (match != null) _send('dashboard_view', match);
      }),
    );
    _subs.add(bus.on<PageChanged>().listen((e) => _send('url', e.url)));
    _subs.add(bus.on<UpdateStateChanged>().listen((_) => _sendUpdateState()));
    _subs.add(bus.on<NextAlarmChanged>().listen((_) => _sendNextAlarm()));
    _subs.add(
      bus.on<PowerChanged>().listen((e) => _send('charging', e.charging)),
    );
    _subs.add(
      bus.on<LightLevelChanged>().listen((e) {
        _send('illuminance', e.lux.round());
        // The MQTT twin never shows "unknown" because the broker retains
        // its last value across restarts; with no broker, this store plays
        // that role. Some drivers (the Echo Show's) emit nothing at
        // registration, so a restart in a stable dark room would otherwise
        // read unknown until the light physically changes.
        _settings.setInternal('esphome_last_lux', '${e.lux.round()}');
      }),
    );
    _subs.add(
      bus.on<CameraViewStateChanged>().listen((e) {
        _send('active_camera_view', e.viewName ?? 'none');
        _send('camera_view', e.viewName ?? 'Closed');
      }),
    );
    _subs.add(
      bus.on<CameraSnapshotTaken>().listen((e) {
        if (_deviceCameraIsTheCamera) {
          _sendImage(e.jpeg);
          _send('last_snapshot', DateTime.now().toUtc().toIso8601String());
        }
      }),
    );
    _subs.add(
      bus.on<MotionDetected>().listen((_) {
        if (!_settings.get(defs.motionSensor)) return;
        _send('motion', true);
        _motionOff?.cancel();
        final delay = _settings.get(defs.motionSensorOffDelay).toInt();
        _motionOff = Timer(Duration(seconds: delay.clamp(1, 300)), () {
          _send('motion', false);
        });
      }),
    );
    // Touches and spoken turns stamp the Last interaction sensor (issue
    // #241). Motion deliberately does not count: someone walking past is
    // exactly what an idle automation wants to keep ignoring.
    _subs.add(
      bus.on<ActivityDetected>().listen((e) {
        if (e.source == 'touch') _interaction.mark();
      }),
    );
    _subs.add(bus.on<WakeWordDetected>().listen((_) => _interaction.mark()));
    // Voice Satellite starting or stopping moves the wake-word handoff, so
    // this is the moment the engine switch is wrong; a voice turn moves it
    // several times, hence the coalescing.
    if (_voiceSatellite) {
      _subs.add(
        bus.on<WakeWordStateChanged>().listen((_) {
          _vsNudge?.cancel();
          _vsNudge = Timer(
            const Duration(milliseconds: 700),
            () => unawaited(_sendVoiceSatellite()),
          );
        }),
      );
    }
    _subs.add(
      bus.on<VoiceInteractionChanged>().listen((e) {
        if (InteractionStamp.countsAsVoice(e)) _interaction.mark();
      }),
    );
    _subs.add(bus.on<SettingChanged>().listen(_onSettingChanged));
    _poll = Timer.periodic(_pollInterval, (_) => _refresh());
    _sendInitial();
  }

  void detach() {
    _push = null;
    _pushImage = null;
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _poll?.cancel();
    _poll = null;
    _motionOff?.cancel();
    _motionOff = null;
    _btNudge?.cancel();
    _btNudge = null;
    _vsNudge?.cancel();
    _vsNudge = null;
    _interaction.dispose();
  }

  /// A command from Home Assistant landed (via the native hub). State
  /// echoes ride the ordinary change events the acted-on managers publish,
  /// so HA sees the real outcome, not an optimistic assumption.
  Future<void> handleCommand(String objectId, Object? value) async {
    final settingSwitch = _settingSwitches[objectId];
    if (settingSwitch != null) {
      await _settings.set(settingSwitch.$3, value == true);
      return;
    }
    final settingSelect = _settingSelects[objectId];
    if (settingSelect != null) {
      final def = settingSelect.$3;
      // HA sends the display label; accept the stored value too so
      // automations outside HA can use the raw vocabulary.
      final text = '$value';
      String? stored;
      for (final option in def.options ?? const <String>[]) {
        if (option == text || def.optionLabels?[option] == text) {
          stored = option;
          break;
        }
      }
      if (stored != null) await _settings.set(def, stored);
      return;
    }
    final settingNumber = _settingNumbers[objectId];
    if (settingNumber != null) {
      final percent = ((value as num?) ?? 0).clamp(0, 100);
      await _settings.set(
        settingNumber.$3,
        settingNumber.$4 ? percent / 100.0 : percent,
      );
      return;
    }
    switch (objectId) {
      case 'screen':
        final map = value is Map ? value : const {};
        final on = map['on'];
        if (on == true) await commands.execute('screenOn', const {});
        if (on == false) {
          await commands.execute('screenOff', {'prompt': false});
        }
        final brightness = map['brightness'];
        if (brightness is num) {
          await commands.execute('setBrightness', {
            'level': brightness.clamp(0.0, 1.0),
          });
        }
      case 'screensaver_active':
        await commands.execute(
          value == true ? 'startScreensaver' : 'stopScreensaver',
          const {},
        );
      case 'volume':
        await commands.execute('setVolume', {
          'percent': ((value as num?) ?? 0),
        });
      case 'voice_satellite':
        await commands.execute('vsEngine', {
          'action': value == true ? 'start' : 'stop',
        });
        // Starting is a next-frame affair in the page, and a start with no
        // session behind it silently does nothing: re-read rather than
        // echo the request (issue #288).
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        await _sendVoiceSatellite();
      case 'voice_satellite_auto_start':
        await commands.execute('vsSetBrowserSettings', {
          'settings': {'auto_start': value == true},
        });
        await _sendVoiceSatellite();
      case 'postpone_screensaver':
        await commands.execute('postponeScreensaver', const {});
      // A slideshow mode steps its deck; every other mode, and no
      // screensaver at all, makes these a no-op by design.
      case 'screensaver_next_slide':
        await commands.execute('nextScreensaverSlide', const {});
      case 'screensaver_previous_slide':
        await commands.execute('previousScreensaverSlide', const {});
      case 'reload':
        await commands.execute('reload', const {});
      case 'load_start_url':
        await commands.execute('loadStartUrl', const {});
      case 'clear_cache':
        await commands.execute('clearWebCache', const {});
      case 'restart':
        await commands.execute('restartApp', const {});
      case 'bring_to_front':
        await commands.execute('bringToFront', const {});
      case 'open_launcher':
        await commands.execute('showAppLauncher', const {});
      case 'show_music_assistant':
        await commands.execute('showMusicAssistant', const {});
      case 'camera_view':
        if ('$value' == 'Closed') {
          await commands.execute('hideCameraView', const {});
        } else {
          final view = _cameraViews.firstWhere(
            (v) => '${v['name']}' == '$value',
            orElse: () => const {},
          );
          if (view.isNotEmpty) {
            await commands.execute('showCameraView', {
              'viewId': '${view['id']}',
            });
          }
        }
      case 'close_camera_view':
        await commands.execute('hideCameraView', const {});
      case String id when id.startsWith('camera_view_'):
        await commands.execute('showCameraView', {
          'viewId': id.substring('camera_view_'.length),
        });
      case 'dashboard_view':
        await commands.execute('haNavigate', {'path': '$value'});
      case 'update':
        if ('$value' == 'install') {
          await commands.execute('installUpdate', const {});
        }
      case 'clock_background':
        await _settings.set(defs.screensaverClockBackground, '$value'.trim());
        _send('clock_background', '$value'.trim());
      case 'device_camera':
        // A frame request from Home Assistant; the capture event pushes
        // the image.
        await commands.execute('takeCameraSnapshot', const {});
      case 'take_snapshot':
        await commands.execute('takeCameraSnapshot', const {});
      case 'screenshot':
      case 'take_screenshot':
        await _takeScreenshot();
      default:
        log.warn('esphome', 'entity command for unknown id $objectId');
    }
  }

  Future<void> _takeScreenshot() async {
    final size = PlatformDispatcher.instance.implicitView?.physicalSize;
    final portrait = size != null && size.height > size.width;
    final result = await commands.execute('screenshot', {
      'width': portrait ? 1080 : 1920,
    });
    final jpeg = result.data;
    if (result.ok && jpeg is String) {
      if (!_deviceCameraIsTheCamera) _sendImage(base64Decode(jpeg));
      await _send('last_screenshot', DateTime.now().toUtc().toIso8601String());
    } else {
      log.warn('esphome', 'screenshot failed: ${result.error}');
    }
  }

  void _onSettingChanged(SettingChanged e) {
    for (final entry in _settingSwitches.entries) {
      if (entry.value.$3.key == e.key) {
        _send(entry.key, e.value == true);
        return;
      }
    }
    for (final entry in _settingSelects.entries) {
      final def = entry.value.$3;
      if (def.key == e.key) {
        final stored = '${e.value}';
        _send(entry.key, def.optionLabels?[stored] ?? stored);
        return;
      }
    }
    for (final entry in _settingNumbers.entries) {
      if (entry.value.$3.key == e.key) {
        final raw = (e.value as num?) ?? 0;
        _send(entry.key, (entry.value.$4 ? raw.toDouble() * 100 : raw).round());
        return;
      }
    }
    if (e.key == defs.screensaverClockBackground.key) {
      _send('clock_background', '${e.value}');
    }
    if (e.key == defs.remoteEnabled.key || e.key == defs.remotePort.key) {
      _sendAdminUrl();
    }
  }

  Future<void> _send(String objectId, Object? value) async {
    try {
      await _push?.call(objectId, value);
    } catch (_) {}
  }

  Future<void> _sendAnchor(String objectId, DateTime? start) async {
    final known = _lastAnchor.containsKey(objectId);
    final last = _lastAnchor[objectId];
    if (start == null) {
      if (known && last == null) return;
      _lastAnchor[objectId] = null;
      await _send(objectId, null);
      return;
    }
    if (last != null &&
        start.difference(last).abs() < const Duration(seconds: 5)) {
      return;
    }
    _lastAnchor[objectId] = start;
    await _send(objectId, start.toIso8601String());
  }

  Future<void> _sendImage(Uint8List jpeg) async {
    try {
      await _pushImage?.call(jpeg);
    } catch (_) {}
  }

  Future<void> _sendInitial() async {
    await _refresh();
    await _sendScreen();
    await _sendVolume();
    await _sendUpdateState();
    await _sendNextAlarm();
    await _sendAdminUrl();
    await _send('screensaver_active', _screensaverActive);
    await _sendDeviceInfo();
    // Settings-backed entities all report their stored values.
    for (final entry in _settingSwitches.entries) {
      await _send(entry.key, _settings.get(entry.value.$3));
    }
    for (final entry in _settingSelects.entries) {
      final def = entry.value.$3;
      final stored = _settings.get(def);
      await _send(entry.key, def.optionLabels?[stored] ?? stored);
    }
    for (final entry in _settingNumbers.entries) {
      final raw = _settings.get(entry.value.$3);
      await _send(
        entry.key,
        (entry.value.$4 ? raw.toDouble() * 100 : raw).round(),
      );
    }
    await _send(
      'clock_background',
      _settings.get(defs.screensaverClockBackground),
    );
    // MQTT inherits these from broker retention; here they need an
    // explicit first value or the selects sit on "unknown" until the
    // first change. No camera view is open at server start, and the
    // dashboard select derives from the page currently showing.
    await _send('camera_view', 'Closed');
    await _send('active_camera_view', 'none');
    // The server (re)started: that IS a fresh sighting, and readable
    // connectivity is by definition on.
    await _send('last_seen', DateTime.now().toUtc().toIso8601String());
    await _send('connectivity', true);
    // The freshest stamp this run has seen, else the persisted one from
    // before the restart; without either the sensor reads unknown until
    // the first real touch.
    final lastInteraction =
        _interaction.latest?.toIso8601String() ??
        _settings.internal('esphome_last_interaction');
    if (lastInteraction.isNotEmpty) {
      await _send('last_interaction', lastInteraction);
    }
    final href = await commands.execute('evalJs', {'code': 'location.href'});
    // WebView eval results come back JSON-encoded; a string wears quotes.
    var url = href.ok ? '${href.data ?? ''}' : '';
    if (url.length >= 2 && url.startsWith('"') && url.endsWith('"')) {
      url = url.substring(1, url.length - 1);
    }
    if (url.startsWith('http')) {
      await _send('url', url);
      final match = matchDashboardView(url, _dashboardViews);
      if (match != null) await _send('dashboard_view', match);
    }
    await _send('motion', false);
  }

  /// The kiosk's own Bluetooth links, and the proxy's connection budget
  /// with them: the budget only moves when the proxy restarts, but it
  /// rides the same read, and a link event is the moment someone is
  /// looking at both numbers.
  Future<void> _sendBluetooth() async {
    if (!_settings.get(defs.btproxyEnabled)) return;
    final bt = await commands.execute('getBluetoothConnections', const {});
    final connected = bt.ok && bt.data is Map
        ? (bt.data as Map)['connected']
        : null;
    if (connected is num) {
      await _send('bt_devices_connected', connected.toInt());
    }
    if (!_settings.get(defs.btproxyConnections)) return;
    final status = await commands.execute('btProxyStatus', const {});
    final data = status.ok && status.data is Map
        ? status.data as Map
        : const {};
    final slots = (data['connectionSlots'] as num?)?.toInt() ?? 0;
    if (slots > 0) await _send('bt_max_connections', slots);
  }

  /// The Voice Satellite engine switch and its auto-start twin, read from
  /// the page hook the settings screen uses. Nothing is pushed when the
  /// hook does not answer: the page may be mid-load or showing something
  /// other than the dashboard, and last known beats a wrong answer.
  Future<void> _sendVoiceSatellite() async {
    if (!_voiceSatellite) return;
    final result = await commands.execute('vsEngineState', const {});
    final data = result.data;
    if (!result.ok || data is! Map) return;
    final engine = data['engine'];
    if (engine is Map) {
      await _send('voice_satellite', engine['running'] == true);
    }
    final config = data['config'];
    if (config is Map && config['auto_start'] != null) {
      await _send('voice_satellite_auto_start', config['auto_start'] == true);
    }
  }

  Future<void> _sendScreen() async {
    final on = await commands.execute('isScreenOn', const {});
    final brightness = await commands.execute('getBrightness', const {});
    final level = (brightness.data as num?)?.toDouble();
    await _send('screen', {
      'on': on.ok ? on.data == true : true,
      if (level != null) 'brightness': level.clamp(0.0, 1.0),
    });
  }

  Future<void> _sendVolume() async {
    final result = await commands.execute('getVolume', const {});
    final percent = (result.data as num?)?.toInt();
    if (result.ok && percent != null) await _send('volume', percent);
  }

  Future<void> _sendUpdateState() async {
    final result = await commands.execute('getUpdateStatus', const {});
    final data = result.data;
    if (!result.ok || data is! Map) return;
    final current = data['currentVersion'] as String?;
    if (current == null || current.isEmpty) return;
    final progress = data['progress'] as num?;
    final notes = (data['availableNotes'] as String? ?? '').trim();
    await _send('update', {
      'current': current,
      'latest': data['availableVersion'] as String? ?? current,
      'title': 'Kiosk Satellite',
      'summary': notes.length > 250 ? notes.substring(0, 250) : notes,
      'url': data['releaseUrl'] is String ? data['releaseUrl'] : '',
      if (progress != null) 'progress': progress.toDouble(),
      'inProgress': progress != null,
    });
  }

  Future<void> _sendNextAlarm() async {
    final result = await commands.execute('getNextAlarm', const {});
    final data = result.ok ? result.data : null;
    await _send('next_alarm', data is Map ? '${data['at']}' : null);
  }

  Future<void> _sendAdminUrl() async {
    if (!_settings.get(defs.remoteEnabled)) {
      await _send('admin_url', 'disabled');
      return;
    }
    final info = await commands.execute('getDeviceInfo', const {});
    final ip = info.ok && info.data is Map
        ? (info.data as Map)['ip'] as String?
        : null;
    if (ip == null || ip.isEmpty) return;
    await _send(
      'admin_url',
      'http://$ip:${_settings.get(defs.remotePort).toInt()}',
    );
  }

  /// The address sensors, summarized exactly as the MQTT ones summarize
  /// them, down to the routable address leading the IPv6 one and the scope
  /// suffix coming off. The per-interface line is what stands in for the
  /// attributes this protocol cannot carry (issue #213).
  Future<void> _sendIpAddresses() async {
    final ips = await commands.execute('getIpAddresses', const {});
    if (!ips.ok || ips.data is! Map) return;
    for (final (family, objectId, preferGlobal) in [
      ('ipv4', 'ipv4_address', false),
      ('ipv6', 'ipv6_address', true),
    ]) {
      final summary = summarizeIpFamily(
        (ips.data as Map)[family],
        preferGlobal: preferGlobal,
      );
      if (summary.primary.isEmpty) continue;
      await _send(objectId, summary.primary);
      await _send('${family}_interfaces', summary.oneLine);
    }
  }

  /// The device's identity, sent once per bring-up: none of it changes
  /// while the process lives. The MQTT twin carries the version and the
  /// build as attributes on one sensor; here they are entities of their
  /// own (issue #213).
  Future<void> _sendDeviceInfo() async {
    final info = await commands.execute('getDeviceInfo', const {});
    final data = info.ok && info.data is Map ? info.data as Map : const {};
    final model = '${data['model'] ?? ''}';
    if (model.isNotEmpty) await _send('device_info', model);
    final version = '${data['osVersion'] ?? ''}';
    if (version.isNotEmpty) await _send('android_version', version);
    final details = await commands.execute('getDeviceDetails', const {});
    final build = details.ok && details.data is Map
        ? '${(details.data as Map)['androidBuild'] ?? ''}'
        : '';
    if (build.isNotEmpty) await _send('android_build', build);
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
        if (view is Map && (view['cameraIds'] as List?)?.isNotEmpty == true)
          view.cast<String, Object?>(),
    ];
  }

  /// The dashboard/view option list, learned once per server run: first
  /// from the crawl the MQTT select uses, else its persisted cache, so an
  /// MQTT-less install still gets the select once HA has answered once.
  Future<void> _refreshDashboardViews() async {
    final options = <String>[];
    final dashboards = await commands.execute('haListDashboards', const {});
    if (dashboards.ok && dashboards.data is List) {
      for (final d in dashboards.data as List) {
        if (d is! Map) continue;
        final urlPath = '${d['url_path'] ?? ''}';
        if (urlPath.isEmpty) continue;
        final views = await commands.execute('haListDashboardViews', {
          'url_path': urlPath,
        });
        if (!views.ok) {
          options.clear();
          break;
        }
        final viewData = views.data;
        if (viewData is List && viewData.isNotEmpty) {
          for (final v in viewData) {
            if (v is Map) options.add('$urlPath/${v['route']}');
          }
        } else {
          options.add(urlPath);
        }
      }
    }
    if (options.isNotEmpty) {
      _dashboardViews = options;
      return;
    }
    try {
      final cached = jsonDecode(_settings.internal('mqtt_dashboard_views'));
      if (cached is List) {
        _dashboardViews = [
          for (final v in cached)
            if (v is String && v.isNotEmpty) v,
        ];
      }
    } catch (_) {
      _dashboardViews = const [];
    }
  }

  /// The slow-moving values, refreshed on the poll cadence (matching the
  /// MQTT sensors so both surfaces agree while they coexist).
  Future<void> _refresh() async {
    final stats = await commands.execute('getStats', const {});
    final data = stats.data;
    if (stats.ok && data is Map) {
      final battery = (data['battery'] as num?)?.toInt();
      if (battery != null) await _send('battery', battery);
      await _send('charging', data['charging'] == true);
      final cpu = (data['cpu'] as num?)?.round();
      if (cpu != null) await _send('cpu', cpu);
      final temp = data['temp'] as num?;
      if (temp != null) await _send('cpu_temp', temp.round());
    }
    final details = await commands.execute('getDeviceDetails', const {});
    final ram = details.ok && details.data is Map
        ? ((details.data as Map)['ram'] as Map?)
        : null;
    if (ram != null) {
      final freeMb = ((ram['free'] as num?) ?? 0) ~/ (1024 * 1024);
      final totalMb = ((ram['total'] as num?) ?? 0) ~/ (1024 * 1024);
      if (freeMb > 0) await _send('ram_free', freeMb);
      if (totalMb > 0) await _send('ram_total', totalMb);
    }
    final up = await commands.execute('getUptime', const {});
    if (up.ok && up.data is Map) {
      final uptime = up.data as Map;
      final now = DateTime.now().toUtc();
      final app = (uptime['app'] as num?)?.toInt();
      if (app != null) {
        await _sendAnchor('app_uptime', now.subtract(Duration(seconds: app)));
      }
      final network = (uptime['network'] as num?)?.toInt();
      await _sendAnchor(
        'network_uptime',
        network == null ? null : now.subtract(Duration(seconds: network)),
      );
    }
    final light = await commands.execute('getLightLevel', const {});
    var lux = light.ok && light.data is Map
        ? ((light.data as Map)['lux'] as num?)
        : null;
    // No live reading yet: fall back to the persisted last one, the same
    // last-known-value semantics broker retention gives the MQTT twin.
    lux ??= int.tryParse(_settings.internal('esphome_last_lux'));
    if (lux != null) await _send('illuminance', lux.round());
    await _sendIpAddresses();
    final foreground = await commands.execute('foregroundApp', const {});
    if (foreground.ok && foreground.data is Map) {
      final pkg = (foreground.data as Map)['package'] as String?;
      await _send('foreground_app', pkg ?? 'unknown');
    }
    if (_settings.get(defs.btproxyEnabled)) {
      await _sendBluetooth();
      final nearby = await commands.execute('btProxyNearby', const {});
      final count = nearby.ok && nearby.data is Map
          ? (nearby.data as Map)['count']
          : null;
      if (count is num) await _send('btproxy_nearby', count.toInt());
    }
    await _sendVoiceSatellite();
    // Every completed poll IS a sighting, like the MQTT twin.
    await _send('last_seen', DateTime.now().toUtc().toIso8601String());
  }
}
