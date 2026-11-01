import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart' show rootBundle;

import '../../core/headless.dart';
import '../../core/command_registry.dart';
import '../../core/event_bus.dart';
import '../../core/events.dart';
import '../../core/logging.dart';
import '../device/ip_addresses.dart';
import '../intercom/intercom_sensors.dart';
import 'dashboard_views.dart';
import '../home_assistant/custom_pages.dart';
import 'interaction_stamp.dart';
import '../sendspin/music_assistant_api.dart';
import '../screensaver/screensaver_manager.dart'
    show currentScreensaverScheduleEntry;
import '../settings/definitions.dart' as defs;
import '../sendspin/sendspin_manager.dart' show SendspinManager;
import '../settings/settings_manager.dart';
import 'countdown_stamp.dart';
import 'lux_limiter.dart';

/// The kiosk entities served over the ESPHome native API. This is the
/// Dart half of the pair with the native EntityHub: it owns WHAT exists,
/// what values mean and what commands do; the native side owns the wire.
/// Sources and command handlers are the ones every other surface (the
/// remote admin, the JS API, gestures) uses, so all of them agree.
///
/// Entity object ids and names are permanent API: names become Home
/// Assistant entity ids (`sensor.<device>_battery`) and survive in users'
/// automations, and they carry over from the retired MQTT catalog so an
/// automation written against it only swaps the device half of the id.
/// Never rename one casually.
///
/// Two cameras ride the ESPHome camera protocol: the Screenshot camera on
/// every device (the display itself, the frame the remote admin shows) and
/// the device camera where the hardware exists. The image request names
/// no camera, so a fetch of either asks both and each answers on its own
/// key; the frames are cheap enough that a screenshot fetch refreshing the
/// camera preview alongside is no cost worth a second protocol.
/// One settings-backed number entity: its range and the setting behind it.
typedef _SettingNumber = ({
  String name,
  String icon,
  defs.SettingDef<num> def,
  bool fraction,
  num min,
  num max,
  num step,
  String unit,
  String? deviceClass,
  int mode,
});

class EspEntitySurface {
  EspEntitySurface(
    this.bus,
    this.commands,
    this.log,
    this._settings, {
    this.onCatalogChanged,
  });

  final EventBus bus;
  final CommandRegistry commands;
  final Logger log;
  final SettingsManager _settings;

  /// Called when the served catalog no longer matches what a fresh
  /// [build] would lay out (the dashboard view list moved). The ESPHome
  /// protocol lists entities once per connection, so only the manager's
  /// restart can tell Home Assistant; the surface never restarts itself.
  final void Function()? onCatalogChanged;

  static const _pollInterval = Duration(seconds: 60);

  /// The media text sensors: object id, name and icon, keyed into the
  /// media summary by the id's tail.
  static const _mediaSensors = [
    ('media_state', 'Media state', 'mdi:play-pause'),
    ('media_title', 'Media title', 'mdi:music-note'),
    ('media_artist', 'Media artist', 'mdi:account-music'),
    ('media_source', 'Media source', 'mdi:speaker'),
  ];

  /// The group used on Home Assistant's device page, before the entity type.
  static String categoryLabel(Map<String, Object?> entity) {
    if (entity['category'] == 1) return 'Configuration';
    if (entity['category'] == 2) return 'Diagnostics';
    return switch (entity['type']) {
      'sensor' || 'text_sensor' || 'binary_sensor' || 'camera' => 'Sensor',
      _ => 'Control',
    };
  }

  /// Sends one entity's fresh value to the native hub; set while attached.
  Future<void> Function(String objectId, Object? value)? _push;

  /// Sends one camera's frame to sessions with an outstanding request.
  Future<void> Function(String objectId, Uint8List jpeg)? _pushImage;

  /// The frame served while the device camera is off: a fetch that got
  /// no answer left Home Assistant's card on a broken image after its
  /// proxy timed out, and the camera's own state cannot say "off" (an
  /// ESPHome camera reads idle while connected). Loaded once, on demand.
  static const _cameraOffAsset = 'assets/camera/camera_off.jpg';
  Uint8List? _cameraOffFrame;

  final List<StreamSubscription<Object?>> _subs = [];
  Timer? _poll;
  Timer? _motionOff;

  /// Coalesces the ACL broadcast flurry one connection makes into a single
  /// read of the link count.
  Timer? _btNudge;

  // Learned at build time; commands and states need them afterwards.
  List<Map<String, Object?>> _cameraViews = const [];
  List<String> _dashboardViews = const [];

  /// Coalesces the page's dashboard-change reports (a create fires
  /// several, a reconnect one) into a single re-read, after the frontend
  /// has refreshed its own registry.
  Timer? _viewsNudge;
  bool _refreshingDashboardViews = false;

  /// The persisted dashboard view list, so a read serves the next start.
  /// The key predates the ESPHome surface and stays for the cache already
  /// stored on every device.
  static const _dashboardViewsKey = 'mqtt_dashboard_views';
  bool _deviceCameraPresent = false;
  bool _screensaverActive = false;

  /// Whether the Now Playing view has something to show, mirrored from
  /// the Sendspin manager's event: with a session up, that is the view on
  /// screen.
  bool _nowPlayingActive = false;

  bool get _nowPlayingShown =>
      _screensaverActive &&
      _nowPlayingActive &&
      _settings.get(defs.sendspinFullscreen) &&
      currentScreensaverScheduleEntry(_settings)?['now_playing'] != false;

  /// Whether the Voice Satellite entities are in this run's catalog, so a
  /// push never names an entity Home Assistant was never told about.
  bool _voiceSatellite = false;

  /// Whether the catalog served lists the Restart device button (issue
  /// #528); the manager compares later Shizuku reports against it.
  bool get rebootButtonListed => _rebootListed;
  bool _rebootListed = false;

  /// Whether the LED Control idle light and its effect are in this run's
  /// catalog.
  bool _ledIdleListed = false;

  /// Coalesces the burst of wake-word state changes one voice turn makes
  /// into a single read of the page's engine state.
  Timer? _vsNudge;

  /// Uptime anchors last pushed, so a poll only republishes when the
  /// start moment genuinely moved (a 5-second tolerance:
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

  /// The Next screensaver sensor (issue #406). The manager's due moment,
  /// throttled the way Last interaction is so a stream of touches, each
  /// nudging the moment a few seconds, does not land a recorder row apiece.
  late final _countdown = CountdownStamp(
    (due) => _send('next_screensaver', due?.toUtc().toIso8601String()),
  );
  DateTime? _idleDue;

  /// The Ambient light sensor (issue #521). The native damper already
  /// holds readings to one every 2 seconds; this bucket lets a real
  /// transition through untouched and collapses a driver flapping between
  /// two values to one recorder row per half minute.
  late final _lux = LuxLimiter((lux) => _send('illuminance', lux));

  /// The Ambient noise sensor (issue #910), through the same bucket. The
  /// meter already holds it to one reading per 5 seconds and 2 dB moves,
  /// but a TV's dialogue clears that all evening.
  late final _noise = LuxLimiter((dbfs) => _send('ambient_noise', dbfs));

  void _sendNoise(int? dbfs) {
    if (dbfs != null) {
      _noise.offer(dbfs);
    } else {
      _noise.reset();
      unawaited(_send('ambient_noise', null));
    }
  }

  /// Unknown while the screensaver shows: a clock still running under a
  /// commanded session is not a moment anyone wants to trigger on.
  void _sendCountdown() => _countdown.set(_screensaverActive ? null : _idleDue);

  /// Settings-backed switches: objectId -> (name, icon, definition).
  /// Entity ids are the ones the retired MQTT catalog used.
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
        // Not gated on the light sensor: a Home Assistant entity can
        // drive it instead (issue #911).
        'adaptive_brightness': (
          'Adaptive brightness',
          'mdi:brightness-auto',
          defs.adaptiveBrightness,
        ),
        'screensaver': ('Screensaver', 'mdi:sleep', defs.screensaverEnabled),
        'screensaver_schedule': (
          'Screensaver schedule',
          'mdi:calendar-clock',
          defs.screensaverScheduleEnabled,
        ),
        'hold_mode': ('Hold mode', 'mdi:pause-circle-outline', defs.haHoldMode),
        // Rotation alone, unlike Hold mode: the screensaver and screen off
        // still run while it is off (issue #1247).
        'dashboard_rotation': (
          'Dashboard rotation',
          'mdi:view-carousel-outline',
          defs.haRotationEnabled,
        ),
        'camera_enabled': (
          'Camera enabled',
          'mdi:camera-outline',
          defs.cameraEnabled,
        ),
        'rtsp_streaming': (
          'RTSP Streaming',
          'mdi:video-wireless-outline',
          defs.cameraRtspEnabled,
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
        'screensaver_proximity': (
          'Screensaver proximity detection',
          'mdi:radar',
          defs.screensaverDismissOnProximity,
        ),
        // The intercom's master switch; its state sensors and the answer
        // mode exist only while it is on.
        'intercom_enabled': (
          'Intercom enabled',
          'mdi:phone-in-talk-outline',
          defs.intercomEnabled,
        ),
        // Native Voice Satellite. Every one starts with vs_, the name too,
        // since Home Assistant builds the entity id from the name. Listed
        // only on the native runtime with Voice Satellite on.
        'vs_mute': ('VS Mute', 'mdi:microphone-off', defs.voiceMute),
        'vs_wake_sound': (
          'VS Chimes',
          'mdi:bell-ring-outline',
          defs.voiceWakeSound,
        ),
        'vs_stop_word': (
          'VS Stop word',
          'mdi:hand-back-left-outline',
          defs.voiceStopWord,
        ),
        'vs_noise_gate': (
          'VS Noise gate',
          'mdi:volume-off',
          defs.voiceNoiseGate,
        ),
        'vs_mute_timers': (
          'VS Mute timers',
          'mdi:timer-off-outline',
          defs.voiceMuteTimers,
        ),
      };

  /// Settings-backed selects: objectId -> (name, icon, definition). The
  /// options are the definitions' display labels, the stored value maps
  /// through them.
  static final _settingSelects =
      <String, (String, String, defs.SettingDef<String>)>{
        // The dashboard's light/dark pin (discussion #351): Auto, Light or
        // Dark, so a sun automation can drive every kiosk and a person can
        // override it by hand.
        'theme': ('Theme', 'mdi:theme-light-dark', defs.haTheme),
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
        // Catalog-gated below on the intercom being on, like its sensors.
        'intercom_answer_mode': (
          'Intercom answer mode',
          'mdi:phone-ring-outline',
          defs.intercomAnswerMode,
        ),
        // Catalog-gated below with the LED Control Idle light.
        'led_idle_effect': (
          'LED Control Idle Effect',
          'mdi:led-on',
          defs.ledIdleStyle,
        ),
        'vs_wake_word_engine': (
          'VS Wake word engine',
          'mdi:account-voice',
          defs.voiceWakeWordEngine,
        ),
        'vs_wake_word_sensitivity': (
          'VS Wake word sensitivity',
          'mdi:ear-hearing',
          defs.voiceWakeWordSensitivity,
        ),
      };

  /// Settings-backed numbers: objectId -> the entity's range and the
  /// setting behind it. `fraction` marks a setting stored 0..1 behind a
  /// 0-100 slider.
  static final _settingNumbers = <String, _SettingNumber>{
    'screensaver_brightness_level': _percent(
      'Screensaver brightness level',
      'mdi:brightness-6',
      defs.screensaverBrightnessLevel,
      fraction: true,
    ),
    // The idle timeout in seconds (issue #516): an automation can cut it
    // short at night and stretch it back by day. A box rather than a
    // slider: the range is wide and a second matters at the low end. 0
    // keeps the idle clock off, the same as on the settings page.
    'screensaver_timeout': (
      name: 'Screensaver timeout',
      icon: 'mdi:timer-outline',
      def: defs.screensaverTimeoutSeconds,
      fraction: false,
      min: 0,
      max: 86400,
      step: 1,
      unit: 's',
      deviceClass: 'duration',
      mode: 1,
    ),
    // Turn screen off after, in minutes (issue #960): an automation can
    // keep a bedroom panel lit by day and let it go dark at night. A write
    // under a running screensaver restarts the countdown, unless the active
    // schedule entry carries its own minutes.
    'screensaver_screen_off_after': (
      name: 'Screensaver screen off after',
      icon: 'mdi:monitor-off',
      def: defs.screensaverScreenOffMinutes,
      fraction: false,
      min: 0,
      max: 60,
      step: 1,
      unit: 'min',
      deviceClass: 'duration',
      mode: 2,
    ),
    'assistant_volume': _percent(
      'Assistant volume',
      'mdi:account-voice',
      defs.assistantVolume,
    ),
    'media_volume': _percent(
      'Media volume',
      'mdi:music-note',
      defs.mediaVolume,
    ),
    // Catalog-gated below on the intercom being on, like its answer mode
    // (issue #869).
    'intercom_volume': _percent(
      'Intercom volume',
      'mdi:phone-in-talk-outline',
      defs.intercomVolume,
    ),
    // The fine-tune sliders next to the sensitivity select (issue #1224):
    // an automation can lower them while the TV plays and raise them back
    // after. Both belong to the device, so each kiosk has its own.
    'vs_wake_word_fine_tune': (
      name: 'VS Wake word fine-tune',
      icon: 'mdi:tune-vertical',
      def: defs.voiceWakeWordFineTune,
      fraction: false,
      min: -10,
      max: 10,
      step: 1,
      unit: '',
      deviceClass: null,
      mode: 2,
    ),
    'vs_stop_word_fine_tune': (
      name: 'VS Stop word fine-tune',
      icon: 'mdi:tune-vertical',
      def: defs.voiceStopWordFineTune,
      fraction: false,
      min: -10,
      max: 10,
      step: 1,
      unit: '',
      deviceClass: null,
      mode: 2,
    ),
    'vs_answer_linger': (
      name: 'VS Answer linger',
      icon: 'mdi:timer-outline',
      def: defs.voiceAnswerLinger,
      fraction: false,
      min: 0,
      max: 15,
      step: 1,
      unit: 's',
      deviceClass: 'duration',
      mode: 2,
    ),
    'vs_announcement_linger': (
      name: 'VS Announcement linger',
      icon: 'mdi:timer-outline',
      def: defs.voiceAnnouncementLinger,
      fraction: false,
      min: 1,
      max: 60,
      step: 1,
      unit: 's',
      deviceClass: 'duration',
      mode: 2,
    ),
  };

  /// A 0-100 percent slider in 5% steps.
  static _SettingNumber _percent(
    String name,
    String icon,
    defs.SettingDef<num> def, {
    bool fraction = false,
  }) => (
    name: name,
    icon: icon,
    def: def,
    fraction: fraction,
    min: 0,
    max: 100,
    step: 5,
    unit: '%',
    deviceClass: null,
    mode: 2,
  );

  /// Probes the hardware and Home Assistant, then lays out the catalog.
  /// The set is fixed for one server run; the manager restarts the server
  /// on the settings that change it.
  Future<List<Map<String, Object?>>> build({
    bool includeExcluded = false,
  }) async {
    final light = await commands.execute('getLightLevel', const {});
    final lightSensorPresent =
        light.ok && light.data is Map && (light.data as Map)['present'] == true;
    final cam = await commands.execute('hasDeviceCamera', const {});
    final cameraPresent = !(cam.ok && cam.data == false);
    final sys = await commands.execute('getSystemUpdateStatus', const {});
    final systemUpdate =
        sys.ok && sys.data is Map && (sys.data as Map)['supported'] == true;
    // The proximity switch is the one pessimistic entity: rare hardware,
    // so it exists only once the probe has said there is a sensor.
    final prox = await commands.execute('getProximitySupport', const {});
    final proximityPresent =
        prox.ok && prox.data is Map && (prox.data as Map)['supported'] != false;
    // The location sensors are opt-in and follow the receiver the same
    // pessimistic way: listed only with Report location on, on a device
    // the probe has said has a GPS receiver (issue #363).
    final loc = _settings.get(defs.locationEnabled)
        ? await commands.execute('getLocationSupport', const {})
        : null;
    final locationPresent =
        loc != null &&
        loc.ok &&
        loc.data is Map &&
        (loc.data as Map)['supported'] != false;
    // The Person sensor exists only while the Person Sensor switch is on,
    // on a device whose probe has said it has a person sensor of its own
    // (discussion #353, issue #734); the switch re-registers the device, a
    // setup-time choice like Report location.
    final person = _settings.get(defs.personSensorEnabled)
        ? await commands.execute('getPersonSensorSupport', const {})
        : null;
    final personPresent =
        person != null &&
        person.ok &&
        person.data is Map &&
        (person.data as Map)['supported'] != false;
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
    // CPU usage only where a load source is readable, and CPU clock only
    // where cpufreq is. A device with neither used to get the clock position
    // passed off as load (issue #824).
    final cpuUsagePresent =
        stats.ok && stats.data is Map && (stats.data as Map)['cpu'] != null;
    final cpuClockPresent =
        stats.ok &&
        stats.data is Map &&
        (stats.data as Map)['cpuClock'] != null;
    final batteryTempPresent =
        stats.ok &&
        stats.data is Map &&
        (stats.data as Map)['batteryTemp'] != null;
    // A device without a battery gets no Battery sensor (issue #367): the
    // one gate every consumer reads through answers null for a mains-
    // powered box, and an entity that could only ever show a sentinel is
    // worse than none. Charging stays: the box still says it is plugged.
    final batteryPresent =
        stats.ok && stats.data is Map && (stats.data as Map)['battery'] != null;
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
    // The camera entities follow the hardware, not the Camera enabled
    // switch: an automation that arms the camera only while someone is
    // home flips that switch all day, and a catalog that changed with it
    // would restart the server (and drop every entity) on each flip
    // (issue #339). Off, the camera answers a "Camera off" frame and the
    // motion sensor reads unknown.
    _deviceCameraPresent = cameraPresent;
    // The Voice Satellite controls exist where a satellite is bound: the
    // setup wizard and the settings page both record the binding here, and
    // a kiosk with none has no engine to start (issue #288). Reading the
    // page instead would make the catalog depend on what was on screen the
    // moment the server started.
    _voiceSatellite =
        _settings.get(defs.haSatelliteEntity).trim().isNotEmpty &&
        _settings.get(defs.voiceRuntime) == 'dashboard';
    // The Restart device button exists only where a restart can land
    // (issue #528): device owner, or a granted Shizuku connection. Asked at
    // build like the hardware probes; the manager restarts the server when
    // a later Shizuku report changes the answer.
    final reboot = await commands.execute('getDeviceRebootSupport', const {});
    _rebootListed =
        reboot.ok &&
        reboot.data is Map &&
        (reboot.data as Map)['supported'] == true;
    // The LED Control idle entities exist where the LED Control page works:
    // on a device with lights, which is the only place the LED manager
    // registers ledStatus, and with Enable LED Control on.
    final leds = await commands.execute('ledStatus', const {});
    _ledIdleListed = leds.ok && _settings.get(defs.ledEnabled);
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

    final intercomOn = _settings.get(defs.intercomEnabled);
    final catalog = <Map<String, Object?>>[
      // ── Controls ─────────────────────────────────────────────────────
      {
        'type': 'light',
        'objectId': 'screen',
        'name': 'Screen',
        'icon': 'mdi:tablet',
      },
      // The LED Control Idle group: its switch, brightness and color. A
      // configuration entity, beside the effect select.
      if (_ledIdleListed)
        {
          'type': 'light',
          'objectId': 'led_idle',
          'name': 'LED Control Idle',
          'icon': 'mdi:led-on',
          'colorCapable': true,
          'category': 1,
        },
      {
        'type': 'switch',
        'objectId': 'screensaver_active',
        'name': 'Screensaver active',
        'icon': 'mdi:sleep',
      },
      // The full-screen Now Playing view: on while it is on screen, and a
      // turn-on brings it up the way the kiosk menu entry does (a paused
      // track opens paused). Only with the view enabled, like the menu
      // entry: a switch that can only fail is worse than no switch.
      if (_settings.get(defs.sendspinPlayerActive) &&
          _settings.get(defs.sendspinFullscreen))
        {
          'type': 'switch',
          'objectId': 'now_playing',
          'name': 'Now Playing',
          'icon': 'mdi:album',
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
      // The turn in Home Assistant's assist_satellite states, for Assist
      // turns and realtime conversations alike. A realtime conversation
      // runs no pipeline, so the satellite entity Home Assistant keeps
      // stays idle through it. Never beside the switch above, which only
      // the dashboard runtime lists.
      if (_voiceNative) ...[
        {
          'type': 'text_sensor',
          'objectId': 'voice_satellite_state',
          'name': 'Voice Satellite',
          'icon': 'mdi:account-voice',
        },
        // The timers on the kiosk, running or paused, and when the next
        // running one ends. ESPHome has no attributes, so the list itself
        // is the vs_list_timers action's answer.
        {
          'type': 'sensor',
          'objectId': 'vs_timers',
          'name': 'VS Timers',
          'icon': 'mdi:timer-outline',
          'accuracyDecimals': 0,
        },
        {
          'type': 'text_sensor',
          'objectId': 'vs_next_timer',
          'name': 'VS Next timer',
          'icon': 'mdi:timer-sand',
          'deviceClass': 'timestamp',
        },
      ],
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
      // The blanket form of the notification_dismiss action (issue
      // #321): a leak acknowledged on one display clears the rest.
      button(
        'notifications_dismiss_all',
        'Notifications dismiss all',
        'mdi:bell-off-outline',
      ),
      button('reload', 'Reload page', 'mdi:refresh'),
      button('load_start_url', 'Go to dashboard', 'mdi:view-dashboard'),
      button('clear_cache', 'Clear cache', 'mdi:broom'),
      button('restart', 'Restart app', '', deviceClass: 'restart'),
      if (_rebootListed)
        button('restart_device', 'Restart device', 'mdi:power-cycle'),
      button('bring_to_front', 'Bring to front', 'mdi:flip-to-front'),
      button('alarm_stop', 'Stop alarm', 'mdi:alarm-off'),
      button('alarm_snooze', 'Snooze alarm', 'mdi:alarm-snooze'),
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
      // Only with something to browse, as the kiosk menu entry.
      if (_musicLibrarySource)
        button(
          'show_music_library',
          'Show Music Library',
          'mdi:playlist-music',
        ),
      // The followed player, opt-in from the Media Player page (issue
      // #741): whichever player the surfaces follow, the local Sendspin
      // player, one elsewhere or another app's media session. Buttons
      // and sensors rather than a media_player, which in ESPHome carries
      // no track and no skip.
      if (_settings.get(defs.sendspinEsphomeEntities)) ...[
        button('media_play', 'Media play', 'mdi:play'),
        button('media_pause', 'Media pause', 'mdi:pause'),
        button('media_next', 'Media next', 'mdi:skip-next'),
        button('media_previous', 'Media previous', 'mdi:skip-previous'),
        for (final (id, name, icon) in _mediaSensors)
          {'type': 'text_sensor', 'objectId': id, 'name': name, 'icon': icon},
      ],
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
        // One press-to-show button per view too: the
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
      // The calendar's view, Closed while it is not up: the select both
      // shows which view is up and opens or closes it.
      {
        'type': 'select',
        'objectId': 'calendar_view',
        'name': 'Calendar view',
        'icon': 'mdi:calendar-month',
        'options': [for (final (label, _) in _calendarViews) label],
      },
      if (_dashboardViews.isNotEmpty) ...[
        {
          'type': 'select',
          'objectId': 'dashboard_view',
          'name': 'Dashboard view',
          'icon': 'mdi:view-dashboard-outline',
          'options': _dashboardViews,
        },
        // The start URL as a select (discussion #427): the dashboard the
        // kiosk comes back to after a restart and on Go to dashboard, so
        // an automation can move it for the night and a crash lands on
        // the right page. Same option list as the view select.
        {
          'type': 'select',
          'objectId': 'default_dashboard',
          'name': 'Default dashboard',
          'icon': 'mdi:view-dashboard-edit-outline',
          'options': _dashboardViews,
          'category': 1,
        },
      ],
      {
        'type': 'update',
        'objectId': 'update',
        'name': 'Update',
        'deviceClass': 'firmware',
      },
      // The system image's own releases, where its updater reports them.
      if (systemUpdate)
        {
          'type': 'update',
          'objectId': 'firmware',
          'name': 'Firmware',
          'deviceClass': 'firmware',
        },
      // The display as a still camera, on every device: what the remote
      // admin's preview shows, fed by the Take screenshot button and by a
      // fetch from Home Assistant.
      {'type': 'camera', 'objectId': 'screenshot', 'name': 'Screenshot'},
      if (cameraPresent) ...[
        {'type': 'camera', 'objectId': 'device_camera', 'name': 'Camera'},
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
      // Home Assistant's sound pressure class takes dB and dBA only. This
      // is a level off the microphone, not a calibrated meter, so it
      // carries no class.
      {
        'type': 'sensor',
        'objectId': 'ambient_noise',
        'name': 'Ambient noise',
        'icon': 'mdi:ear-hearing',
        'unit': 'dBFS',
        'stateClass': 1,
      },
      // Listed with the camera and unknown while the Motion sensor
      // setting or the camera is off, so neither switch re-lists the
      // catalog.
      if (cameraPresent)
        {
          'type': 'binary_sensor',
          'objectId': 'motion',
          'name': 'Motion',
          'deviceClass': 'motion',
        },
      // Someone in view of the device's own person sensor (discussion
      // #353): occupancy, since it reports people at any angle, not a
      // face turned to the screen.
      if (personPresent)
        {
          'type': 'binary_sensor',
          'objectId': 'person',
          'name': 'Person',
          'deviceClass': 'occupancy',
        },
      // The GPS position (issue #363). Six decimals is about a tenth of
      // a meter; the default of none would round a coordinate to a whole
      // degree. Latitude and longitude carry no state class on purpose:
      // a long-term mean of a position is nothing.
      if (locationPresent) ...[
        {
          'type': 'sensor',
          'objectId': 'gps_latitude',
          'name': 'GPS latitude',
          'icon': 'mdi:latitude',
          'unit': '°',
          'accuracyDecimals': 6,
        },
        {
          'type': 'sensor',
          'objectId': 'gps_longitude',
          'name': 'GPS longitude',
          'icon': 'mdi:longitude',
          'unit': '°',
          'accuracyDecimals': 6,
        },
        {
          'type': 'sensor',
          'objectId': 'gps_accuracy',
          'name': 'GPS accuracy',
          'icon': 'mdi:crosshairs-gps',
          'deviceClass': 'distance',
          'unit': 'm',
          'stateClass': 1,
        },
        {
          'type': 'sensor',
          'objectId': 'altitude',
          'name': 'Altitude',
          'icon': 'mdi:altimeter',
          'deviceClass': 'distance',
          'unit': 'm',
          'stateClass': 1,
        },
        {
          'type': 'sensor',
          'objectId': 'speed',
          'name': 'Speed',
          'deviceClass': 'speed',
          'unit': 'm/s',
          'stateClass': 1,
          'accuracyDecimals': 1,
        },
        {
          'type': 'text_sensor',
          'objectId': 'last_location_fix',
          'name': 'Last location fix',
          'icon': 'mdi:map-marker-check-outline',
          'deviceClass': 'timestamp',
        },
      ],
      {
        'type': 'text_sensor',
        'objectId': 'next_alarm',
        'name': 'Next alarm',
        'icon': 'mdi:alarm',
        'deviceClass': 'timestamp',
      },
      // The kiosk's own alarms: ringing, and until when a snooze holds one
      // off. A morning routine is an automation on Alarm ringing turning
      // off.
      {
        'type': 'binary_sensor',
        'objectId': 'alarm_ringing',
        'name': 'Alarm ringing',
        'icon': 'mdi:alarm-bell',
      },
      {
        'type': 'text_sensor',
        'objectId': 'alarm_snoozed_until',
        'name': 'Alarm snoozed until',
        'icon': 'mdi:alarm-snooze',
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
      // When the idle clock will start the screensaver (issue #406): one
      // timestamp Home Assistant can trigger on, rather than a seconds
      // countdown churning the recorder. Unknown while nothing counts down.
      {
        'type': 'text_sensor',
        'objectId': 'next_screensaver',
        'name': 'Next screensaver',
        'icon': 'mdi:timer-sand',
        'deviceClass': 'timestamp',
      },
      // ── Config ───────────────────────────────────────────────────────
      for (final e in _settingNumbers.entries)
        if ((e.key != 'intercom_volume' || intercomOn) &&
            (!e.key.startsWith('vs_') || _voiceNative))
          {
            'type': 'number',
            'objectId': e.key,
            'name': e.value.name,
            'icon': e.value.icon,
            if (e.value.deviceClass != null) 'deviceClass': e.value.deviceClass,
            'min': e.value.min,
            'max': e.value.max,
            'step': e.value.step,
            'unit': e.value.unit,
            'mode': e.value.mode,
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
        if ((cameraPresent ||
                (e.key != 'camera_enabled' &&
                    e.key != 'rtsp_streaming' &&
                    e.key != 'screensaver_motion' &&
                    e.key != 'screensaver_face')) &&
            (proximityPresent || e.key != 'screensaver_proximity') &&
            (!e.key.startsWith('vs_') || _voiceNative))
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
      // The intercom: its state, the other kiosk's name, Do not disturb as
      // a switch (the answer mode's third choice) and the answer mode as a
      // select below. The emulation has no event entity, so the state
      // sensor carries the story, missed included, for a minute.
      if (intercomOn) ...[
        {
          'type': 'text_sensor',
          'objectId': 'intercom',
          'name': 'Intercom',
          'icon': 'mdi:phone-in-talk-outline',
        },
        {
          'type': 'text_sensor',
          'objectId': 'intercom_kiosk',
          'name': 'Intercom kiosk',
          'icon': 'mdi:tablet',
        },
        {
          'type': 'switch',
          'objectId': 'intercom_do_not_disturb',
          'name': 'Intercom do not disturb',
          'icon': 'mdi:bell-off-outline',
          'category': 1,
        },
      ],
      for (final e in _settingSelects.entries)
        if ((e.key != 'camera_device' || (cameraPresent && bothFacings)) &&
            (e.key != 'intercom_answer_mode' || intercomOn) &&
            (e.key != 'led_idle_effect' || _ledIdleListed) &&
            (!e.key.startsWith('vs_') || _voiceNative))
          {
            'type': 'select',
            'objectId': e.key,
            'name': e.value.$1,
            'icon': e.value.$2,
            'options': [
              for (final option in _settings.optionsFor(e.value.$3))
                e.value.$3.optionLabels?[option] ?? option,
            ],
            'category': 1,
          },
      // ── Diagnostics ──────────────────────────────────────────────────
      if (batteryPresent)
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
      if (cpuUsagePresent)
        diagnostic(
          'cpu',
          'CPU usage',
          icon: 'mdi:chip',
          unit: '%',
          stateClass: 1,
        ),
      if (cpuClockPresent)
        diagnostic(
          'cpu_clock',
          'CPU clock',
          deviceClass: 'frequency',
          icon: 'mdi:speedometer',
          unit: 'MHz',
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
      // A tenth of a degree, as BatteryManager reports it.
      if (batteryTempPresent)
        {
          ...diagnostic(
            'battery_temp',
            'Battery temperature',
            deviceClass: 'temperature',
            unit: '°C',
            stateClass: 1,
          ),
          'accuracyDecimals': 1,
        },
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
      diagnostic(
        'storage_free',
        'Internal storage free',
        icon: 'mdi:harddisk',
        deviceClass: 'data_size',
        unit: 'MiB',
        stateClass: 1,
      ),
      diagnostic(
        'storage_total',
        'Internal storage total',
        icon: 'mdi:harddisk',
        deviceClass: 'data_size',
        unit: 'MiB',
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
      // The retired MQTT twins of the four that follow carried their detail
      // as attributes on the Device and IP sensors; the ESPHome protocol has
      // no attributes to hang anything off, so each is its own text sensor
      // here and both integrations answer the same questions (issue #213).
      diagnostic(
        'device_info',
        'Device',
        icon: 'mdi:information-outline',
        type: 'text_sensor',
      ),
      // What the panel shows, as a share of full: with adaptive brightness
      // on, the Screen light reads Maximum brightness rather than the
      // dimmed panel, and this is where the dimmed panel is readable.
      diagnostic(
        'panel_brightness',
        'Panel brightness',
        icon: 'mdi:brightness-percent',
        unit: '%',
        stateClass: 1,
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
      // The release the kiosk is running, as a sensor a fleet can be
      // sorted by: the Update entity only says whether a newer one exists,
      // and the device registry's sw_version cannot be read from a
      // template or a trigger (issue #381).
      diagnostic(
        'app_version',
        'App version',
        icon: 'mdi:tag-outline',
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
      // Timestamps, not counters: the recorder logs the moments
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
      // entity unavailable), but automations written against the retired
      // MQTT sensor check for 'on', and 'unavailable' satisfies their
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
    final pluginEntities = await commands.execute(
      'getPluginEntities',
      const {},
    );
    if (pluginEntities.ok && pluginEntities.data is List) {
      catalog.addAll(
        (pluginEntities.data as List).whereType<Map>().map(
          (e) => Map<String, Object?>.from(e),
        ),
      );
    }
    if (Headless.active) {
      catalog.removeWhere((e) => _headlessDrops('${e['objectId']}'));
    }
    if (includeExcluded) return catalog;
    final excluded = defs.decodeEspHomeExcludedEntities(
      _settings.get(defs.esphomeExcludedEntities),
    );
    return catalog
        .where((entity) => !excluded.contains(entity['objectId']))
        .toList();
  }

  /// The entities that show, light or navigate something, which a device
  /// without a screen leaves out, and the settings entities whose setting
  /// it hides.
  /// Whether the Music Library has a source to browse: Music Assistant,
  /// Home Assistant or a known Sonos speaker, as its kiosk menu entry asks.
  bool get _musicLibrarySource {
    bool set(defs.SettingDef<String> d) => _settings.get(d).trim().isNotEmpty;
    final sonos = _settings.get(defs.sendspinSonosHosts).trim();
    return (set(defs.sendspinMaUrl) && set(defs.sendspinMaToken)) ||
        (set(defs.haUrl) && set(defs.haToken)) ||
        (sonos.isNotEmpty && sonos != '{}');
  }

  static const _headlessDropped = {
    'screen',
    'screensaver_active',
    'now_playing',
    'postpone_screensaver',
    'screensaver_next_slide',
    'screensaver_previous_slide',
    'notifications_dismiss_all',
    'reload',
    'load_start_url',
    'clear_cache',
    'bring_to_front',
    'open_launcher',
    'show_music_assistant',
    'show_music_library',
    'close_camera_view',
    'active_camera_view',
    'calendar_view',
    'dashboard_view',
    'default_dashboard',
    'screenshot',
    'take_screenshot',
    'last_screenshot',
    'last_interaction',
    'next_screensaver',
    'clock_background',
    'panel_brightness',
    'url',
  };

  /// The Calendar view select's options and the views they open, Closed
  /// first (no view).
  static const _calendarViews = <(String, String?)>[
    ('Closed', null),
    ('Day', 'day'),
    ('Week', 'week'),
    ('Month', 'month'),
    ('Schedule', 'schedule'),
  ];

  static String _calendarViewLabel(String? view) => _calendarViews
      .firstWhere((v) => v.$2 == view, orElse: () => _calendarViews.first)
      .$1;

  static bool _headlessDrops(String objectId) {
    if (_headlessDropped.contains(objectId) ||
        objectId.startsWith('camera_view')) {
      return true;
    }
    final def =
        _settingSwitches[objectId]?.$3 ??
        _settingSelects[objectId]?.$3 ??
        _settingNumbers[objectId]?.def;
    return def != null && defs.deviceHiddenKeys.contains(def.key);
  }

  String? _excludedValue;
  Set<String> _excludedIds = {};

  bool _isExcluded(String objectId) {
    final value = _settings.get(defs.esphomeExcludedEntities);
    if (value != _excludedValue) {
      _excludedValue = value;
      _excludedIds = defs.decodeEspHomeExcludedEntities(value);
    }
    return _excludedIds.contains(objectId);
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
  /// Whether the kiosk serves native Voice Satellite: its vs_ entities
  /// and actions exist only then.
  bool get _voiceNative =>
      _settings.get(defs.voiceRuntime) == 'native' &&
      _settings.get(defs.voiceEnabled);

  List<Map<String, Object?>> buildServices() => [
    ..._services,
    if (_voiceNative) ..._voiceServices,
  ];

  /// Native Voice Satellite's actions: `esphome.<kiosk>_vs_wake` and friends.
  static const _voiceServices = <Map<String, Object?>>[
    // Start listening as if the wake word in that slot fired: slot 2 runs
    // Assistant 2. 0 counts as slot 1 (an action cannot leave it out).
    {
      'name': 'vs_wake',
      'supportsResponse': true,
      'args': [
        {'name': 'slot', 'type': 'int'},
      ],
    },
    // Ends the turn on screen as a double tap does: listening, thinking or
    // speaking, a lingering answer or a ringing timer.
    {'name': 'vs_cancel', 'supportsResponse': true, 'args': []},
    // Sends a prompt to the assistant and shows the answer and results on
    // this kiosk. Actions cannot leave a field out, so speaking is opt in
    // (false is the silent show), pipeline 0 counts as 1 and duration 0
    // keeps the answer up until it is dismissed.
    {
      'name': 'vs_show',
      'supportsResponse': true,
      'args': [
        {'name': 'prompt', 'type': 'string'},
        {'name': 'speak', 'type': 'bool'},
        {'name': 'pipeline', 'type': 'int'},
        {'name': 'duration', 'type': 'int'},
      ],
    },
    // Starts a voice timer on this kiosk through Home Assistant's timer
    // intent, so it lives in Home Assistant like a spoken one.
    {
      'name': 'vs_start_timer',
      'supportsResponse': true,
      'args': [
        {'name': 'name', 'type': 'string'},
        {'name': 'hours', 'type': 'int'},
        {'name': 'minutes', 'type': 'int'},
        {'name': 'seconds', 'type': 'int'},
      ],
    },
    // The timers on this kiosk, as an automation reads them through
    // response_variable: the list the VS Timers sensor counts.
    {'name': 'vs_list_timers', 'supportsResponse': true, 'args': []},
    // Change one of those timers by its timer_id, or the kiosk's only one
    // when the id is empty. They go through Home Assistant's timer intents.
    {
      'name': 'vs_pause_timer',
      'supportsResponse': true,
      'args': [
        {'name': 'timer_id', 'type': 'string'},
      ],
    },
    {
      'name': 'vs_resume_timer',
      'supportsResponse': true,
      'args': [
        {'name': 'timer_id', 'type': 'string'},
      ],
    },
    {
      'name': 'vs_cancel_timer',
      'supportsResponse': true,
      'args': [
        {'name': 'timer_id', 'type': 'string'},
      ],
    },
    {
      'name': 'vs_add_time',
      'supportsResponse': true,
      'args': [
        {'name': 'timer_id', 'type': 'string'},
        {'name': 'hours', 'type': 'int'},
        {'name': 'minutes', 'type': 'int'},
        {'name': 'seconds', 'type': 'int'},
      ],
    },
    {
      'name': 'vs_remove_time',
      'supportsResponse': true,
      'args': [
        {'name': 'timer_id', 'type': 'string'},
        {'name': 'hours', 'type': 'int'},
        {'name': 'minutes', 'type': 'int'},
        {'name': 'seconds', 'type': 'int'},
      ],
    },
  ];

  static const _services = <Map<String, Object?>>[
    {
      'name': 'notification',
      // Answers with the kiosk's id for the card ({"id": 7}), which an
      // automation reads through response_variable and can hand to
      // notification_dismiss (issue #321).
      'supportsResponse': true,
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
        // A picture under the text: a URL, or a path on the Home
        // Assistant server; empty for none (issue #341).
        {'name': 'image', 'type': 'string'},
      ],
    },
    // Takes down the card with the id the notification action answered
    // with, or clears the screen when the id is 0 (issue #321), which is
    // the value an action, unable to leave an argument out, sends for
    // "all of them".
    {
      'name': 'notification_dismiss',
      'args': [
        {'name': 'id', 'type': 'int'},
      ],
    },
    // The players the Now Playing surfaces can follow, as an automation
    // reads them through response_variable: every source's list, the
    // names and ids media_player_set takes, and the current pick.
    {'name': 'media_player_list', 'supportsResponse': true, 'args': []},
    // Follow a player: the source and the player by name or id, the way
    // the Media Player page picks one. The device source puts this
    // device back on its own player and needs no player.
    {
      'name': 'media_player_set',
      'supportsResponse': true,
      'args': [
        {'name': 'source', 'type': 'string'},
        {'name': 'player', 'type': 'string'},
      ],
    },
    {
      'name': 'launch_app',
      // Acknowledge the launch so failures reach the calling automation.
      'supportsResponse': true,
      'args': [
        {'name': 'package_name', 'type': 'string'},
      ],
    },
    // An announcement on this kiosk: a message Home Assistant speaks or
    // an audio URL, with a chime first (the Announcements page under
    // ESPHome). Each kiosk is addressed through its own device.
    {
      'name': 'announce',
      'supportsResponse': true,
      'args': [
        {'name': 'message', 'type': 'string'},
        {'name': 'url', 'type': 'string'},
        // A share of the master volume for this one announcement; 0 keeps
        // the media volume (the action cannot leave a number out).
        {'name': 'volume', 'type': 'float'},
        // Plays it that many times, a short pause between; 0 is once.
        {'name': 'repeat', 'type': 'int'},
        // Seconds between plays; 0 is the default 0.6.
        {'name': 'repeat_pause', 'type': 'float'},
        {'name': 'chime', 'type': 'bool'},
        {'name': 'chime_file', 'type': 'string'},
        {'name': 'tts_engine', 'type': 'string'},
        {'name': 'tts_language', 'type': 'string'},
        {'name': 'tts_voice', 'type': 'string'},
        {'name': 'audio_only', 'type': 'bool'},
      ],
    },
    // Stops the announcement playing on this kiosk, if any, and one
    // still fetching its audio. Answers whether one was playing.
    {'name': 'announce_stop', 'supportsResponse': true, 'args': []},
    // Rings another kiosk from this one, the way the kiosk menu's Call a
    // kiosk sheet does, so a dashboard button or an automation can put a
    // call through (issue #549). The kiosk goes by its name or address:
    // its id is nothing Home Assistant sees.
    {
      'name': 'intercom_call',
      'supportsResponse': true,
      'args': [
        {'name': 'kiosk', 'type': 'string'},
      ],
    },
    // Ends the call, cancels one still ringing or closes an announcement.
    // Answers so "no call" reaches the automation as an error.
    {'name': 'intercom_hangup', 'supportsResponse': true, 'args': []},
    // Answer or decline the call ringing here, so a headless kiosk or one
    // out of reach can be picked up from Home Assistant (issue #943).
    // Answers so "nothing is ringing" reaches the automation as an error.
    {'name': 'intercom_answer', 'supportsResponse': true, 'args': []},
    {'name': 'intercom_decline', 'supportsResponse': true, 'args': []},
    // A web page over the dashboard, the surface a tapped dashboard link
    // or the Music Assistant entry gets: the dashboard stays alive under
    // it and the wake word keeps listening. Answers so a bad URL reaches
    // the automation as an error.
    {
      'name': 'open_url',
      'supportsResponse': true,
      'args': [
        {'name': 'url', 'type': 'string'},
        // Hold mode for the page's stay: on with the page, off when it
        // goes, whichever way it goes. A hold already on is left alone.
        {'name': 'hold_mode', 'type': 'bool'},
      ],
    },
    // Drops that page, whoever put it up; nothing up is not an error.
    {'name': 'close_url', 'supportsResponse': true, 'args': []},
    // A shell command line through Shizuku, as adb shell would run it.
    // Answers with exit_code, stdout and stderr; a command that ran and
    // failed is still a success, and only one that could not run (no
    // Shizuku, no grant) is an error. timeout is in seconds, 0 is 10 and
    // 25 is the most, since Home Assistant stops waiting at 30.
    {
      'name': 'shizuku_command',
      'supportsResponse': true,
      'args': [
        {'name': 'command', 'type': 'string'},
        {'name': 'timeout', 'type': 'int'},
      ],
    },
    {
      'name': 'set_brightness',
      'supportsResponse': true,
      'args': [
        {'name': 'brightness', 'type': 'float'},
      ],
    },
    {
      'name': 'set_screensaver_brightness',
      'supportsResponse': true,
      'args': [
        {'name': 'brightness', 'type': 'float'},
      ],
    },
  ];

  /// An action call from Home Assistant landed (via the native hub). The
  /// map returned is the action's response data (an action declared with
  /// supportsResponse), null for none.
  Future<Map<String, Object?>?> handleService(
    String name,
    Map<String, Object?> args,
  ) async {
    switch (name) {
      case 'vs_wake':
        final slot = (args['slot'] as num?)?.toInt() ?? 1;
        final result = await commands.execute('voiceWake', {
          'slot': slot < 1 ? 1 : slot,
        });
        if (!result.ok) throw StateError(result.error ?? 'not started');
        return const {};
      case 'vs_cancel':
        final result = await commands.execute('voiceCancel', const {});
        if (!result.ok) throw StateError(result.error ?? 'not cancelled');
        return const {};
      case 'vs_show':
        final result = await commands.execute('voiceShow', {
          'prompt': args['prompt'] ?? '',
          'speak': args['speak'] == true,
          'pipeline': args['pipeline'] ?? 1,
          'duration': args['duration'] ?? 0,
        });
        if (!result.ok) throw StateError(result.error ?? 'not shown');
        return const {};
      case 'vs_start_timer':
        final result = await commands.execute('voiceStartTimer', {
          'name': args['name'] ?? '',
          'hours': args['hours'] ?? 0,
          'minutes': args['minutes'] ?? 0,
          'seconds': args['seconds'] ?? 0,
        });
        if (!result.ok) throw StateError(result.error ?? 'timer not started');
        return const {};
      case 'vs_pause_timer':
      case 'vs_resume_timer':
      case 'vs_cancel_timer':
      case 'vs_add_time':
      case 'vs_remove_time':
        final result = await commands.execute('voiceTimerControl', {
          'timer_id': args['timer_id'] ?? '',
          'action': switch (name) {
            'vs_pause_timer' => 'pause',
            'vs_resume_timer' => 'resume',
            'vs_cancel_timer' => 'cancel',
            'vs_add_time' => 'add',
            _ => 'remove',
          },
          'hours': args['hours'] ?? 0,
          'minutes': args['minutes'] ?? 0,
          'seconds': args['seconds'] ?? 0,
        });
        if (!result.ok) throw StateError(result.error ?? 'timer not changed');
        return const {};
      case 'vs_list_timers':
        final result = await commands.execute('voiceTimers', const {});
        if (!result.ok) throw StateError(result.error ?? 'refused');
        return {'timers': (result.data as Map?)?['timers'] ?? const []};
      case 'set_brightness':
      case 'set_screensaver_brightness':
        final brightness = args['brightness'];
        if (brightness is! num ||
            !brightness.isFinite ||
            brightness < 0 ||
            brightness > 100) {
          throw StateError('brightness must be a percentage from 0 to 100');
        }
        if (_settings.get(defs.adaptiveBrightness)) {
          throw StateError('Turn off adaptive brightness to set brightness');
        }
        if (name == 'set_screensaver_brightness') {
          await _settings.set(
            defs.screensaverBrightnessLevel,
            brightness / 100.0,
            source: 'esphome',
          );
          return const {};
        }
        final result = await commands.execute('setBrightness', {
          'level': brightness / 100.0,
        });
        if (!result.ok) throw StateError(result.error ?? 'brightness not set');
        return const {};
      case 'notification':
        final result = await commands.execute('showNotification', {
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
          'image': '${args['image'] ?? ''}',
        });
        if (!result.ok) throw StateError(result.error ?? 'refused');
        // {"id": n}: what the automation reads through response_variable.
        return (result.data as Map?)?.cast<String, Object?>();
      case 'notification_dismiss':
        await commands.execute('dismissNotification', {'id': args['id'] ?? 0});
        return null;
      case 'media_player_list':
        final listed = await commands.execute('mediaPlayers', const {});
        if (!listed.ok) throw StateError(listed.error ?? 'refused');
        final data = (listed.data as Map?) ?? const {};
        final players = [
          for (final p in (data['players'] as List? ?? const []))
            if (p is Map)
              {
                'source': SendspinManager.sourceLabel('${p['group'] ?? ''}'),
                'name': '${p['name'] ?? ''}',
                'id': '${p['id'] ?? ''}'.replaceFirst(RegExp(r'^[a-z]+:'), ''),
                'available': p['available'] != false,
              },
        ];
        final pick = _settings.get(defs.sendspinPlayer);
        return {
          'players': players,
          'current': {
            'source': SendspinManager.sourceLabel(
              _settings.get(defs.sendspinPlayerSource),
            ),
            'id': pick.replaceFirst(RegExp(r'^[a-z]+:'), ''),
            'name': _settings.get(defs.sendspinPlayerName),
          },
          'notes': data['notes'] ?? const {},
        };
      case 'media_player_set':
        final result = await commands.execute('mediaPlayerSet', {
          'source': '${args['source'] ?? ''}',
          'player': '${args['player'] ?? ''}',
        });
        if (!result.ok) throw StateError(result.error ?? 'refused');
        return (result.data as Map?)?.cast<String, Object?>();
      case 'launch_app':
        final result = await commands.execute('launchApp', {
          'package': '${args['package_name'] ?? ''}',
        });
        if (!result.ok) throw StateError(result.error ?? 'refused');
        return const {};
      case 'announce':
        final result = await commands.execute('announce', {
          'message': '${args['message'] ?? ''}',
          'url': '${args['url'] ?? ''}',
          'volume': args['volume'] ?? 0,
          'repeat': args['repeat'] ?? 0,
          'repeat_pause': args['repeat_pause'] ?? 0,
          if (args['chime'] != null) 'chime': args['chime'],
          'chime_file': '${args['chime_file'] ?? ''}',
          'tts_engine': '${args['tts_engine'] ?? ''}',
          'tts_language': '${args['tts_language'] ?? ''}',
          'tts_voice': '${args['tts_voice'] ?? ''}',
          'audio_only': args['audio_only'] ?? false,
        });
        if (!result.ok) throw StateError(result.error ?? 'refused');
        final data = result.data;
        return data is Map ? data.cast<String, Object?>() : const {};
      case 'announce_stop':
        final result = await commands.execute('announceStop', const {});
        if (!result.ok) throw StateError(result.error ?? 'refused');
        final data = result.data;
        return data is Map ? data.cast<String, Object?>() : const {};
      case 'intercom_call':
        final result = await commands.execute('intercomCall', {
          'kiosk': '${args['kiosk'] ?? ''}',
        });
        if (!result.ok) throw StateError(result.error ?? 'refused');
        final data = result.data;
        return data is Map ? data.cast<String, Object?>() : const {};
      case 'intercom_hangup':
        final result = await commands.execute('intercomHangup', const {});
        if (!result.ok) throw StateError(result.error ?? 'refused');
        return const {};
      case 'intercom_answer':
        final result = await commands.execute('intercomAnswer', const {});
        if (!result.ok) throw StateError(result.error ?? 'refused');
        return const {};
      case 'intercom_decline':
        final result = await commands.execute('intercomDecline', const {});
        if (!result.ok) throw StateError(result.error ?? 'refused');
        return const {};
      case 'open_url':
        final url = '${args['url'] ?? ''}'.trim();
        final uri = Uri.tryParse(url);
        if (url.isEmpty ||
            uri == null ||
            !(uri.scheme == 'http' || uri.scheme == 'https') ||
            uri.host.isEmpty) {
          throw StateError('url must be an http or https address');
        }
        // The page is meant to be seen: a kiosk asleep or on its
        // screensaver would load it behind a black screen. Both are
        // best effort, since a panel that refuses to wake still shows
        // the page the moment it does.
        await commands.execute('stopScreensaver', const {});
        await commands.execute('screenOn', const {});
        final result = await commands.execute('showLinkPage', {
          'url': url,
          'hold': args['hold_mode'] == true,
        });
        if (!result.ok) throw StateError(result.error ?? 'refused');
        return const {};
      case 'close_url':
        final result = await commands.execute('hideOverlayPage', const {});
        if (!result.ok) throw StateError(result.error ?? 'refused');
        return const {};
      case 'shizuku_command':
        final result = await commands.execute('runShizukuCommand', {
          'command': '${args['command'] ?? ''}',
          'timeout': args['timeout'] ?? 0,
        });
        if (!result.ok) throw StateError(result.error ?? 'refused');
        return fitCommandResponse((result.data as Map).cast<String, Object?>());
      default:
        log.warn('esphome', 'unknown action $name');
        return null;
    }
  }

  /// Starts serving values: initial snapshot, change events, slow poll.
  void attach(
    Future<void> Function(String, Object?) push,
    Future<void> Function(String, Uint8List) pushImage,
  ) {
    _push = push;
    _pushImage = pushImage;
    _subs.add(
      bus.on<PluginEntityCatalogChanged>().listen(
        (_) => onCatalogChanged?.call(),
      ),
    );
    _subs.add(
      bus.on<PluginEntityStateChanged>().listen(
        (e) => _send(e.objectId, e.value),
      ),
    );
    // Every attach faces a fresh native hub with no values: the anchors
    // must go out again even when they did not move, or the uptime
    // sensors sit on "unknown" until the app itself restarts.
    _lastAnchor.clear();
    _subs.add(
      bus.on<ScreensaverStateChanged>().listen((e) {
        _screensaverActive = e.active;
        _send('screensaver_active', e.active);
        _send('now_playing', _nowPlayingShown);
        _sendCountdown();
      }),
    );
    _subs.add(
      bus.on<ScreensaverViewChanged>().listen((_) {
        _send('now_playing', _nowPlayingShown);
      }),
    );
    _subs.add(
      bus.on<ScreensaverCountdownChanged>().listen((e) {
        _idleDue = e.due;
        _sendCountdown();
      }),
    );
    _subs.add(
      bus.on<SendspinNowPlayingChanged>().listen((e) {
        _nowPlayingActive = e.active;
        _send('now_playing', _nowPlayingShown);
      }),
    );
    _subs.add(
      bus.on<MediaSummaryChanged>().listen((e) => _sendMedia(e.summary)),
    );
    _subs.add(bus.on<ScreenStateChanged>().listen((_) => _sendScreen()));
    // Addresses change exactly at these transitions, and the minute poll
    // would leave the IP sensors and the admin URL stale until it comes
    // round. Deferred a moment so DHCP has settled by the time we look.
    _subs.add(
      bus.on<NetworkStateChanged>().listen((_) {
        Timer(const Duration(seconds: 3), () {
          _sendIpAddresses();
          _sendAdminUrl();
        });
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
    _subs.add(
      bus.on<BrightnessChanged>().listen((e) {
        _sendScreen();
        _send('panel_brightness', (e.panel.clamp(0.0, 1.0) * 100).round());
      }),
    );
    _subs.add(bus.on<VolumeChanged>().listen((_) => _sendVolume()));
    _subs.add(
      bus.on<UrlChanged>().listen((e) {
        _send('url', e.url);
        final match = matchDashboardView(e.url, _dashboardViews);
        if (match != null) _send('dashboard_view', match);
      }),
    );
    _subs.add(bus.on<PageChanged>().listen((e) => _send('url', e.url)));
    // The dashboard set may have moved, or the page's connection is back
    // after an outage: the only moments the list is re-read. Never on a
    // timer, since a changed list re-registers the device (issue #362).
    _subs.add(
      bus.on<HaDashboardsChanged>().listen((_) {
        _viewsNudge?.cancel();
        _viewsNudge = Timer(
          const Duration(seconds: 3),
          () => unawaited(relearnDashboardViews()),
        );
      }),
    );
    _subs.add(bus.on<UpdateStateChanged>().listen((_) => _sendUpdateState()));
    _subs.add(
      bus.on<SystemUpdateStateChanged>().listen((_) => _sendFirmwareState()),
    );
    _subs.add(bus.on<NextAlarmChanged>().listen((_) => _sendNextAlarm()));
    _subs.add(bus.on<AlarmStateChanged>().listen((e) => _sendAlarm(e.status)));
    _subs.add(
      bus.on<PowerChanged>().listen((e) => _send('charging', e.charging)),
    );
    _subs.add(
      // The device manager persists each reading (esphome_last_lux) and
      // seeds getLightLevel from it after a restart, so a driver that
      // emits nothing at registration (the Echo Show's) leaves the entity
      // on the last known value rather than unknown.
      bus.on<LightLevelChanged>().listen((e) => _lux.offer(e.lux.round())),
    );
    _subs.add(bus.on<NoiseLevelChanged>().listen((e) => _sendNoise(e.dbfs)));
    _subs.add(bus.on<LocationChanged>().listen(_sendLocation));
    _subs.add(
      bus.on<PersonSensorChanged>().listen((e) => _sendPerson(e.present)),
    );
    _subs.add(
      bus.on<CalendarViewChanged>().listen(
        (e) => _send('calendar_view', _calendarViewLabel(e.view)),
      ),
    );
    _subs.add(
      bus.on<CameraViewStateChanged>().listen((e) {
        _send('active_camera_view', e.viewName ?? 'none');
        _send('camera_view', e.viewName ?? 'Closed');
      }),
    );
    _subs.add(
      bus.on<CameraSnapshotTaken>().listen((e) {
        if (_deviceCameraPresent) {
          _sendImage('device_camera', e.jpeg);
          _stamp('last_snapshot');
        }
      }),
    );
    // The remote admin's overview captured the screen: the same picture
    // reaches the Screenshot camera and Last screenshot moves, as it does
    // for the Take screenshot button.
    _subs.add(
      bus.on<ScreenshotTaken>().listen((e) {
        _sendImage('screenshot', e.jpeg);
        _stamp('last_screenshot');
      }),
    );
    _subs.add(
      bus.on<MotionDetected>().listen((_) {
        if (!_motionActive) return;
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
    _subs.add(
      bus.on<VoiceSatelliteStateChanged>().listen((e) {
        if (_voiceNative) _send('voice_satellite_state', e.state);
      }),
    );
    _subs.add(
      bus.on<VoiceTimersChanged>().listen((e) {
        if (_voiceNative) unawaited(_sendTimers(e.timers));
      }),
    );
    // A person waking the panel by hand counts too (issue #348); see the
    // ScreenStateChanged listener below for why only the OS-reported wake
    // qualifies.
    _subs.add(
      bus.on<ScreenStateChanged>().listen((e) {
        if (e.on && e.source == 'system') _interaction.mark();
      }),
    );
    _subs.add(
      bus.on<IntercomStateChanged>().listen((e) => _sendIntercom(e.status)),
    );
    _subs.add(bus.on<SettingChanged>().listen(_onSettingChanged));
    _poll = Timer.periodic(_pollInterval, (_) => _refresh());
    _sendInitial();
  }

  /// VS Timers counts the timers still counting or paused, and VS Next
  /// timer is the soonest end among the running ones, unknown when none
  /// runs.
  Future<void> _sendTimers(List<Map<String, Object?>> timers) async {
    final pending = timers.where((t) => t['finished'] != true);
    final ends = [
      for (final t in pending)
        if (t['ends_at'] is String) t['ends_at'] as String,
    ]..sort();
    await _send('vs_timers', pending.length);
    await _send('vs_next_timer', ends.isEmpty ? null : ends.first);
  }

  /// The intercom's three sensors from one status shape. See
  /// [intercomSensors].
  Future<void> _sendIntercom(Map<String, Object?> status) async {
    if (!_settings.get(defs.intercomEnabled)) return;
    final sensors = intercomSensors(status);
    await _send('intercom', sensors['state']);
    await _send('intercom_kiosk', sensors['kiosk']);
    await _send('intercom_do_not_disturb', sensors['dnd']);
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
    _viewsNudge?.cancel();
    _viewsNudge = null;
    _interaction.dispose();
    _countdown.dispose();
    _lux.reset();
    _noise.reset();
  }

  /// A command from Home Assistant landed (via the native hub). State
  /// echoes ride the ordinary change events the acted-on managers publish,
  /// so HA sees the real outcome, not an optimistic assumption.
  Future<void> handleCommand(String objectId, Object? value) async {
    if (_isExcluded(objectId)) return;
    if (objectId.startsWith('plugin_')) {
      await commands.execute('pluginEntityCommand', {
        'objectId': objectId,
        'value': value,
      });
      return;
    }
    // Logged under its own source, so a setting flipped from Home
    // Assistant reads as such in the log instead of looking like the app's
    // own doing.
    log.info('esphome', 'command $objectId = $value');
    final settingSwitch = _settingSwitches[objectId];
    if (settingSwitch != null) {
      await _settings.set(settingSwitch.$3, value == true, source: 'esphome');
      return;
    }
    final settingSelect = _settingSelects[objectId];
    if (settingSelect != null) {
      final def = settingSelect.$3;
      // HA sends the display label; accept the stored value too so
      // automations outside HA can use the raw vocabulary.
      final text = '$value';
      String? stored;
      for (final option in _settings.optionsFor(def)) {
        if (option == text || def.optionLabels?[option] == text) {
          stored = option;
          break;
        }
      }
      if (stored != null) await _settings.set(def, stored, source: 'esphome');
      return;
    }
    final settingNumber = _settingNumbers[objectId];
    if (settingNumber != null) {
      final clamped = ((value as num?) ?? 0).clamp(
        settingNumber.min,
        settingNumber.max,
      );
      await _settings.set(
        settingNumber.def,
        settingNumber.fraction ? clamped / 100.0 : clamped,
        source: 'esphome',
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
      case 'led_idle':
        final map = value is Map ? value : const {};
        final on = map['on'];
        if (on is bool) {
          await _settings.set(defs.ledIdleEnabled, on, source: 'esphome');
        }
        final brightness = map['brightness'];
        if (brightness is num) {
          // The setting moves in 5% steps from 5%, so a light dimmed all
          // the way down still shows.
          final def = defs.ledIdleBrightness;
          final step = def.step ?? 1;
          await _settings.set(
            def,
            ((brightness * 100 / step).round() * step).clamp(
              def.min ?? 0,
              def.max ?? 100,
            ),
            source: 'esphome',
          );
        }
        final rgb = [map['red'], map['green'], map['blue']];
        if (rgb.every((c) => c is num)) {
          await _settings.set(
            defs.ledIdleLightColor,
            rgb.map((c) => ((c as num) * 255).round().clamp(0, 255)).join(','),
            source: 'esphome',
          );
        }
        // A command that changed nothing gets its answer too.
        await _sendLedIdle();
      case 'screensaver_active':
        await commands.execute(
          value == true ? 'startScreensaver' : 'stopScreensaver',
          const {},
        );
      case 'now_playing':
        if (value == true) {
          await commands.execute('showNowPlaying', const {});
        } else if (_nowPlayingShown) {
          // Off means the view, not whatever screensaver may follow it.
          await commands.execute('stopScreensaver', const {});
        }
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
      case 'intercom_do_not_disturb':
        await commands.execute('intercomSetDnd', {'on': value == true});
      case 'postpone_screensaver':
        await commands.execute('postponeScreensaver', const {});
      // A slideshow mode steps its deck; every other mode, and no
      // screensaver at all, makes these a no-op by design.
      case 'screensaver_next_slide':
        await commands.execute('nextScreensaverSlide', const {});
      case 'screensaver_previous_slide':
        await commands.execute('previousScreensaverSlide', const {});
      case 'notifications_dismiss_all':
        await commands.execute('dismissNotification', const {});
      case 'media_play' || 'media_pause' || 'media_next' || 'media_previous':
        await commands.execute('sendspinControl', {
          'command': objectId.substring('media_'.length),
        });
      case 'reload':
        await commands.execute('reload', const {});
      case 'alarm_stop':
        await commands.execute('alarmStop', const {'source': 'esphome'});
      case 'alarm_snooze':
        await commands.execute('alarmSnooze', const {'source': 'esphome'});
      case 'load_start_url':
        await commands.execute('loadStartUrl', const {});
      case 'clear_cache':
        await commands.execute('clearWebCache', const {});
      case 'restart':
        await commands.execute('restartApp', const {});
      case 'restart_device':
        await commands.execute('rebootDevice', const {});
      case 'bring_to_front':
        await commands.execute('bringToFront', const {});
      case 'open_launcher':
        await commands.execute('showAppLauncher', const {});
      case 'show_music_assistant':
        await commands.execute('showMusicAssistant', const {});
      case 'show_music_library':
        await commands.execute('openMusicLibrary', const {});
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
      case 'calendar_view':
        final view = _calendarViews
            .where((v) => v.$1 == '$value')
            .map((v) => v.$2)
            .firstOrNull;
        if (view == null) {
          await commands.execute('hideCalendar', const {});
        } else {
          await commands.execute('openCalendar', {'view': view});
        }
      case 'close_camera_view':
        await commands.execute('hideCameraView', const {});
      case String id when id.startsWith('camera_view_'):
        await commands.execute('showCameraView', {
          'viewId': id.substring('camera_view_'.length),
        });
      case 'dashboard_view':
        await commands.execute('haNavigate', {'path': '$value'});
      case 'default_dashboard':
        await _setDefaultDashboard('$value');
      case 'update':
        // Home Assistant sends "check" for homeassistant.update_entity
        // and "install" for update.install. A check queries the release
        // source right away, the same as tapping the version line in the
        // remote admin (issue #635); a changed result republishes the
        // entity through UpdateStateChanged.
        if ('$value' == 'install') {
          await commands.execute('installUpdate', const {});
        } else if ('$value' == 'check') {
          await commands.execute('checkUpdateNow', const {});
        }
      case 'firmware':
        // The same two commands for the image. A check waits for GitHub
        // and a change republishes the entity through
        // SystemUpdateStateChanged.
        if ('$value' == 'install') {
          await commands.execute('installSystemUpdate', const {});
        } else if ('$value' == 'check') {
          await commands.execute('checkSystemUpdateNow', const {});
        }
      case 'clock_background':
        // Through the validator (issue #464): the 255 character cap and
        // the URL shape. A rejected write echoes the stored value so the
        // entity snaps back instead of showing a value the clock never
        // took.
        await _settings.setFromJson(
          defs.screensaverClockBackground.key,
          '$value'.trim(),
          source: 'esphome',
        );
        _send(
          'clock_background',
          _settings.get(defs.screensaverClockBackground),
        );
      case 'device_camera':
        // A frame request from Home Assistant; the capture event pushes
        // the image. Off, the "Camera off" frame answers instead.
        if (_settings.get(defs.cameraEnabled)) {
          await commands.execute('takeCameraSnapshot', const {});
        } else {
          await _sendCameraOff();
        }
      case 'take_snapshot':
        await commands.execute('takeCameraSnapshot', const {});
      case 'screenshot':
        // A frame request from Home Assistant, which the keyless camera
        // request also raises on every Camera fetch: the display is
        // captured for the entity, and nothing else moves.
        await _takeScreenshot(stamp: false);
      case 'take_screenshot':
        await _takeScreenshot(stamp: true);
      default:
        log.warn('esphome', 'entity command for unknown id $objectId');
    }
  }

  /// Captures the display for the Screenshot camera. Only the Take
  /// screenshot button stamps Last screenshot: the stamp means "when the
  /// button last captured", and a camera fetch,
  /// which Home Assistant issues on its own whenever a preview refreshes,
  /// must not move it.
  Future<void> _takeScreenshot({required bool stamp}) async {
    final size = PlatformDispatcher.instance.implicitView?.physicalSize;
    final portrait = size != null && size.height > size.width;
    final result = await commands.execute('screenshot', {
      'width': portrait ? 1080 : 1920,
    });
    final jpeg = result.data;
    if (result.ok && jpeg is String) {
      _sendImage('screenshot', base64Decode(jpeg));
      if (stamp) await _stamp('last_screenshot');
    } else {
      log.warn('esphome', 'screenshot failed: ${result.error}');
    }
  }

  /// The Motion sensor reads a value only while both the camera and the
  /// setting are on; otherwise it is listed but unknown.
  bool get _motionActive =>
      _settings.get(defs.cameraEnabled) && _settings.get(defs.motionSensor);

  /// The sensor's resting value: clear while it can read, unknown when
  /// it cannot. Any pulse in flight ends here.
  Future<void> _sendMotionState() async {
    _motionOff?.cancel();
    await _send('motion', _motionActive ? false : null);
  }

  Future<void> _sendCameraOff() async {
    try {
      final frame = _cameraOffFrame ??= (await rootBundle.load(
        _cameraOffAsset,
      )).buffer.asUint8List();
      await _sendImage('device_camera', frame);
    } catch (e) {
      log.warn('esphome', 'camera off frame unavailable: $e');
    }
  }

  /// Stamps a capture timestamp now and keeps it: the retired MQTT twin
  /// never read unknown after a restart because the broker retained its last
  /// value, and with no broker the settings store plays that role, so the
  /// sensor reseeds at the next attach instead of sitting on unknown until
  /// the next capture.
  Future<void> _stamp(String objectId) async {
    final iso = DateTime.now().toUtc().toIso8601String();
    _settings.setInternal('esphome_$objectId', iso);
    await _send(objectId, iso);
  }

  void _onSettingChanged(SettingChanged e) {
    if (e.key == defs.cameraEnabled.key || e.key == defs.motionSensor.key) {
      _sendMotionState();
    }
    if (e.key == defs.startUrl.key) {
      _sendDefaultDashboard();
      return;
    }
    if (e.key == defs.haCustomPages.key) {
      unawaited(_followCustomPages());
      return;
    }
    if (e.key == defs.ledIdleEnabled.key ||
        e.key == defs.ledIdleBrightness.key ||
        e.key == defs.ledIdleLightColor.key) {
      unawaited(_sendLedIdle());
      return;
    }
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
      if (entry.value.def.key == e.key) {
        final raw = (e.value as num?) ?? 0;
        _send(
          entry.key,
          (entry.value.fraction ? raw.toDouble() * 100 : raw).round(),
        );
        return;
      }
    }
    if (e.key == defs.screensaverClockBackground.key) {
      _send('clock_background', '${e.value}');
    }
    if (e.key == defs.remoteEnabled.key ||
        e.key == defs.remotePort.key ||
        e.key == defs.remoteTls.key) {
      _sendAdminUrl();
    }
  }

  Future<void> _sendMedia(Map<String, String> summary) async {
    if (!_settings.get(defs.sendspinEsphomeEntities)) return;
    for (final (id, _, _) in _mediaSensors) {
      await _send(id, summary[id.substring('media_'.length)] ?? '');
    }
  }

  Future<void> _send(String objectId, Object? value) async {
    if (_isExcluded(objectId)) return;
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

  Future<void> _sendImage(String objectId, Uint8List jpeg) async {
    if (_isExcluded(objectId)) return;
    try {
      await _pushImage?.call(objectId, jpeg);
    } catch (_) {}
  }

  Future<void> _sendInitial() async {
    final pluginEntities = await commands.execute(
      'getPluginEntities',
      const {},
    );
    if (pluginEntities.ok && pluginEntities.data is List) {
      for (final entity in (pluginEntities.data as List).whereType<Map>()) {
        if (entity['type'] == 'button') continue;
        await _send('${entity['objectId']}', entity['state']);
      }
    }
    await _refresh();
    final noise = await commands.execute('getNoiseLevel', const {});
    _sendNoise(
      noise.ok && noise.data is Map
          ? ((noise.data as Map)['dbfs'] as num?)?.toInt()
          : null,
    );
    await _sendScreen();
    await _sendLedIdle();
    await _sendPanelBrightness();
    await _sendVolume();
    await _sendUpdateState();
    await _sendFirmwareState();
    await _sendNextAlarm();
    final alarm = await commands.execute('alarmsStatus', const {});
    if (alarm.ok && alarm.data is Map) {
      await _sendAlarm((alarm.data as Map).cast<String, Object?>());
    }
    await _sendLastLocation();
    await _sendPersonState();
    // Both states are seeded from the managers rather than assumed off:
    // a screensaver session, and a Now Playing view launched by playback,
    // may well be up before the server starts (an app start with music
    // already playing brings the view up two seconds ahead of it).
    final saver = await commands.execute('isScreensaverActive', const {});
    if (saver.ok && saver.data is bool) _screensaverActive = saver.data as bool;
    // The idle clock is usually already running when the server comes up.
    final due = await commands.execute('getScreensaverDue', const {});
    _idleDue = due.ok && due.data is String
        ? DateTime.tryParse(due.data as String)
        : null;
    _sendCountdown();
    final player = await commands.execute('sendspinStatus', const {});
    if (player.ok && player.data is Map) {
      _nowPlayingActive = (player.data as Map)['fullscreenActive'] == true;
    }
    await _send('screensaver_active', _screensaverActive);
    await _send('now_playing', _nowPlayingShown);
    final media = await commands.execute('mediaPlayerState', const {});
    if (media.ok && media.data is Map) {
      await _sendMedia({
        for (final e in (media.data as Map).entries)
          '${e.key}': '${e.value ?? ''}',
      });
    }
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
      final raw = _settings.get(entry.value.def);
      await _send(
        entry.key,
        (entry.value.fraction ? raw.toDouble() * 100 : raw).round(),
      );
    }
    await _send(
      'clock_background',
      _settings.get(defs.screensaverClockBackground),
    );
    if (_voiceNative) {
      final voice = await commands.execute('voiceStatus', const {});
      final state = voice.ok && voice.data is Map
          ? (voice.data as Map)['state']
          : null;
      await _send('voice_satellite_state', '${state ?? 'idle'}');
      final timers = await commands.execute('voiceTimers', const {});
      await _sendTimers([
        if (timers.ok && timers.data is Map)
          for (final t in ((timers.data as Map)['timers'] as List? ?? const []))
            if (t is Map) t.cast<String, Object?>(),
      ]);
    }
    if (_settings.get(defs.intercomEnabled)) {
      final intercom = await commands.execute('intercomStatus', const {});
      if (intercom.ok && intercom.data is Map) {
        await _sendIntercom((intercom.data as Map).cast<String, Object?>());
      }
    }
    // A broker would have retained these; here they need an
    // explicit first value or the selects sit on "unknown" until the
    // first change. No camera view is open at server start, and the
    // dashboard select derives from the page currently showing.
    await _send('camera_view', 'Closed');
    await _send('active_camera_view', 'none');
    final calendar = await commands.execute('calendarStatus', const {});
    await _send(
      'calendar_view',
      _calendarViewLabel(
        calendar.ok && calendar.data is Map
            ? (calendar.data as Map)['view'] as String?
            : null,
      ),
    );
    await _sendDefaultDashboard();
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
    // The capture stamps from before the restart, the way a broker would
    // have retained them; unknown only until the first capture ever.
    for (final stamp in [
      'last_screenshot',
      if (_deviceCameraPresent) 'last_snapshot',
    ]) {
      final kept = _settings.internal('esphome_$stamp');
      if (kept.isNotEmpty) await _send(stamp, kept);
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
    await _sendMotionState();
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
    final status = await commands.execute('esphomeStatus', const {});
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

  Future<void> _sendPanelBrightness() async {
    final panel = await commands.execute('getBrightness', const {
      'panel': true,
    });
    final level = (panel.data as num?)?.toDouble();
    if (level == null) return;
    await _send('panel_brightness', (level.clamp(0.0, 1.0) * 100).round());
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

  /// The Idle group's switch, brightness and "r,g,b" color as the LED
  /// Control Idle light.
  Future<void> _sendLedIdle() async {
    if (!_ledIdleListed) return;
    final color = _settings.get(defs.ledIdleLightColor).split(',');
    final channels = [
      for (final c in color) (int.tryParse(c.trim()) ?? 255).clamp(0, 255),
    ];
    await _send('led_idle', {
      'on': _settings.get(defs.ledIdleEnabled),
      'brightness': (_settings.get(defs.ledIdleBrightness) / 100).clamp(
        0.0,
        1.0,
      ),
      if (channels.length == 3) ...{
        'red': channels[0] / 255,
        'green': channels[1] / 255,
        'blue': channels[2] / 255,
      },
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
      'summary': _fitNotes(notes),
      'url': data['releaseUrl'] is String ? data['releaseUrl'] : '',
      // UpdateStateResponse's progress field is a 0-100 percentage; the
      // manager's notifier is a 0..1 fraction.
      if (progress != null)
        'progress': progress.toDouble().clamp(0.0, 1.0) * 100,
      'inProgress': progress != null,
    });
  }

  /// The system image on the Firmware entity, the twin of
  /// [_sendUpdateState]. Progress covers the whole update, both slots of
  /// the Echo Dot. A newer image that installs by hand shows as the latest
  /// version, with its guide as the release page, while the image's own
  /// updater has nothing newer to install.
  Future<void> _sendFirmwareState() async {
    final result = await commands.execute('getSystemUpdateStatus', const {});
    final data = result.data;
    if (!result.ok || data is! Map || data['supported'] != true) return;
    final current = data['currentVersion'] as String?;
    if (current == null || current.isEmpty) return;
    final progress = data['progress'] as num?;
    final busy = const {
      'downloading',
      'verifying',
      'installing',
    }.contains(data['state']);
    final available = data['availableVersion'] as String?;
    final manual = available == null && !busy
        ? data['manualVersion'] as String?
        : null;
    final manualUrl = data['manualUrl'] as String? ?? '';
    final notes = manual != null
        ? 'Version $manual is a new image that installs by hand, not as an '
              'update. Follow the [guide]($manualUrl).\n\n'
              '${(data['manualNotes'] as String? ?? '').trim()}'
        : (data['availableNotes'] as String? ?? '').trim();
    await _send('firmware', {
      'current': current,
      'latest': available ?? manual ?? current,
      'title': data['title'] is String ? data['title'] : 'Firmware',
      'summary': _fitNotes(notes.trim()),
      'url': manual != null
          ? manualUrl
          : data['releaseUrl'] is String
          ? data['releaseUrl']
          : '',
      if (progress != null) 'progress': progress.toDouble() * 100,
      'inProgress': busy,
    });
  }

  /// Home Assistant serves the update entity's summary in full as its
  /// release notes, so the notes go whole. A device many versions behind
  /// gets every missed release joined, which can outgrow the API's 64 KB
  /// frame, so long notes stop at the last whole release that fits.
  static const _maxNotesBytes = 30 * 1024;

  static String _fitNotes(String notes) {
    final bytes = utf8.encode(notes);
    if (bytes.length <= _maxNotesBytes) return notes;
    const more = '\n\nThe rest of the notes are on the GitHub releases page.';
    var cut = utf8.decode(
      bytes.sublist(0, _maxNotesBytes - more.length),
      allowMalformed: true,
    );
    // A cut inside a multi-byte character decodes to a replacement mark.
    if (cut.endsWith('�')) cut = cut.substring(0, cut.length - 1);
    // Each missed release opens with "# Version" (UpdateManager's
    // _combinedNotes). Failing that, stop at a line end.
    var end = cut.lastIndexOf('\n\n# Version ');
    if (end <= 0) end = cut.lastIndexOf('\n');
    if (end > 0) cut = cut.substring(0, end);
    return '${cut.trimRight()}$more';
  }

  /// The person sensor's state onto the Person binary sensor.
  Future<void> _sendPerson(bool present) async {
    if (!_settings.get(defs.personSensorEnabled)) return;
    await _send('person', present);
  }

  /// The sensor's current state at attach, so the entity reads a value
  /// rather than unknown until the next change: clear while the sensor
  /// is being read and nobody is there, unknown while it cannot be read
  /// (the grant missing, say).
  Future<void> _sendPersonState() async {
    if (!_settings.get(defs.personSensorEnabled)) return;
    final result = await commands.execute('getPersonSensor', const {});
    if (!result.ok || result.data is! Map) return;
    final status = result.data as Map;
    await _send(
      'person',
      status['running'] == true ? status['present'] == true : null,
    );
  }

  /// A fix from the receiver, onto the six location sensors at once.
  Future<void> _sendLocation(LocationChanged e) async {
    if (!_settings.get(defs.locationEnabled)) return;
    await _send('gps_latitude', e.latitude);
    await _send('gps_longitude', e.longitude);
    await _send('gps_accuracy', e.accuracy?.round());
    await _send('altitude', e.altitude?.round());
    await _send('speed', e.speed);
    await _send('last_location_fix', e.time.toUtc().toIso8601String());
  }

  /// The last fix the location manager holds, from this run or the last
  /// one, so the sensors read a position at attach rather than unknown
  /// until the next fix (the broker-retention role).
  Future<void> _sendLastLocation() async {
    if (!_settings.get(defs.locationEnabled)) return;
    final result = await commands.execute('getLocation', const {});
    final fix = result.ok && result.data is Map
        ? (result.data as Map)['fix']
        : null;
    if (fix is! Map) return;
    final lat = fix['latitude'];
    final lon = fix['longitude'];
    final time = fix['time'];
    if (lat is! num || lon is! num) return;
    await _sendLocation(
      LocationChanged(
        latitude: lat.toDouble(),
        longitude: lon.toDouble(),
        time: time is num
            ? DateTime.fromMillisecondsSinceEpoch(time.toInt(), isUtc: true)
            : DateTime.now().toUtc(),
        accuracy: (fix['accuracy'] as num?)?.toDouble(),
        altitude: (fix['altitude'] as num?)?.toDouble(),
        speed: (fix['speed'] as num?)?.toDouble(),
      ),
    );
  }

  Future<void> _sendNextAlarm() async {
    final result = await commands.execute('getNextAlarm', const {});
    final data = result.ok ? result.data : null;
    await _send('next_alarm', data is Map ? '${data['at']}' : null);
  }

  Future<void> _sendAlarm(Map<String, Object?> status) async {
    await _send('alarm_ringing', status['phase'] == 'ringing');
    await _send('alarm_snoozed_until', status['snoozedUntil']);
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
      '${_settings.get(defs.remoteTls) ? 'https' : 'http'}://$ip:${_settings.get(defs.remotePort).toInt()}',
    );
  }

  /// The address sensors, summarized down to the routable address leading the IPv6 one and the scope
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
  /// while the process lives. The retired MQTT twin carried the version and
  /// the build as attributes on one sensor; here they are entities of their
  /// own (issue #213).
  Future<void> _sendDeviceInfo() async {
    final info = await commands.execute('getDeviceInfo', const {});
    final data = info.ok && info.data is Map ? info.data as Map : const {};
    final model = '${data['model'] ?? ''}';
    if (model.isNotEmpty) await _send('device_info', model);
    final version = '${data['osVersion'] ?? ''}';
    if (version.isNotEmpty) await _send('android_version', version);
    final appVersion = '${data['appVersion'] ?? ''}';
    if (appVersion.isNotEmpty) await _send('app_version', appVersion);
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

  /// The dashboard/view option list for this server run: the persisted
  /// list from the last successful read when there is one, else a live
  /// read. The persisted list first, on purpose: a server that starts
  /// before the network is up cannot ask Home Assistant, and a select
  /// left out of the catalog for that stayed out until the next restart,
  /// which raced the same way (issue #362). A stale list is corrected by
  /// the re-reads that follow, with a restart only when it moved.
  Future<void> _refreshDashboardViews() async {
    final remembered = _rememberedDashboardViews();
    if (remembered.isNotEmpty) {
      _dashboardViews = _withCustomPages(remembered);
      return;
    }
    final learned = await _learnDashboardViews();
    if (learned.isEmpty) {
      _dashboardViews = _withCustomPages(const []);
      return;
    }
    _dashboardViews = learned;
    await _settings.setInternal(_dashboardViewsKey, jsonEncode(learned));
  }

  /// [views] with the custom pages as they are in the settings now, last.
  /// They are added here rather than learned with the views because the
  /// list they come from is the kiosk's own: the re-read that learns the
  /// views needs the Home Assistant page on screen and cannot run while a
  /// custom page is showing.
  List<String> _withCustomPages(List<String> views) => [
    for (final v in views)
      if (!isCustomPagePath(v)) v,
    for (final p in parseCustomPages(_settings.get(defs.haCustomPages)))
      p.navPath,
  ];

  /// A page added, changed or removed: the selects' options follow at
  /// once, re-registering the device only when the list really moved.
  Future<void> _followCustomPages() async {
    final next = _withCustomPages(_dashboardViews);
    if (jsonEncode(next) == jsonEncode(_dashboardViews)) return;
    _dashboardViews = next;
    if (next.any((v) => !isCustomPagePath(v))) {
      await _settings.setInternal(_dashboardViewsKey, jsonEncode(next));
    }
    if (_push == null) return;
    log.info('esphome', 'custom pages changed; re-listing entities');
    onCatalogChanged?.call();
  }

  List<String> _rememberedDashboardViews() {
    try {
      final cached = jsonDecode(_settings.internal(_dashboardViewsKey));
      if (cached is List) {
        return [
          for (final v in cached)
            if (v is String && v.isNotEmpty) v,
        ];
      }
    } catch (_) {}
    return const [];
  }

  /// The Default dashboard select's state: the option the start URL points
  /// at, a bare dashboard URL reading as its first view like the view
  /// select does. Nothing is sent for a start URL outside the list (a
  /// page on another host), which leaves the select on unknown rather
  /// than claiming a dashboard the kiosk does not open.
  Future<void> _sendDefaultDashboard() async {
    final match = matchDashboardView(
      _settings.get(defs.startUrl),
      _dashboardViews,
    );
    if (match != null) await _send('default_dashboard', match);
  }

  /// Writes the start URL for a view path, and only that: the page stays
  /// where it is, and the new default is what the next restart, crash
  /// recovery or Go to dashboard press lands on. The Dashboard view select
  /// is the one that moves the page. The Home Assistant base URL is the
  /// origin, since the device's picker stores that origin too, whatever
  /// host the page itself is served from.
  Future<void> _setDefaultDashboard(String path) async {
    if (!_dashboardViews.contains(path)) {
      log.warn('esphome', 'default_dashboard: unknown option $path');
      return;
    }
    final base = _haBaseUrl();
    if (base.isEmpty) {
      log.warn('esphome', 'default_dashboard: no Home Assistant URL');
      return;
    }
    await _settings.set(
      defs.startUrl,
      viewPathUrl(base, path),
      source: 'esphome',
    );
  }

  /// The Home Assistant origin the start URL is built on, as the manager
  /// derives it from the base URL setting: scheme, host and port only.
  String _haBaseUrl() {
    final url = _settings.get(defs.haUrl).trim();
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      return uri.hasPort
          ? '${uri.scheme}://${uri.host}:${uri.port}'
          : '${uri.scheme}://${uri.host}';
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// One read of the dashboard view list from Home Assistant. Empty when
  /// any part of it failed: a websocket
  /// that is down says nothing about the dashboards, so the caller keeps
  /// what it had rather than downgrading the select (issue #214).
  ///
  /// [pageOnly] takes the page's registry or nothing. The websocket list
  /// orders and names the default differently, and a re-read that could
  /// flip between the two sources would re-register the device for a
  /// list that had not really changed.
  Future<List<String>> _learnDashboardViews({bool pageOnly = false}) async {
    final options = <String>[];
    final dashboards = await commands.execute('haListDashboards', {
      if (pageOnly) 'source': 'page',
    });
    if (!dashboards.ok || dashboards.data is! List) return const [];
    for (final d in dashboards.data as List) {
      if (d is! Map) continue;
      final urlPath = '${d['url_path'] ?? ''}';
      // The custom pages join after the read (see _withCustomPages).
      if (urlPath.isEmpty || urlPath == customPagesDashboardPath) continue;
      final views = await commands.execute('haListDashboardViews', {
        'url_path': urlPath,
      });
      if (!views.ok) return const [];
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
    return options.isEmpty ? options : _withCustomPages(options);
  }

  /// Re-reads the list while serving, when the page reports the dashboard
  /// set moved or its connection came back, and asks the manager for a
  /// restart when it changed: the select that was missing because Home
  /// Assistant was unreachable at start appears once it answers, and an
  /// added or removed dashboard reaches the dropdown without a toggle. An
  /// unchanged list never restarts anything, since the restart makes
  /// every entity unavailable for a couple of seconds.
  Future<void> relearnDashboardViews() async {
    if (_push == null || _refreshingDashboardViews) return;
    _refreshingDashboardViews = true;
    try {
      final learned = await _learnDashboardViews(pageOnly: true);
      if (learned.isEmpty ||
          jsonEncode(learned) == jsonEncode(_dashboardViews)) {
        return;
      }
      _dashboardViews = learned;
      await _settings.setInternal(_dashboardViewsKey, jsonEncode(learned));
      log.info('esphome', 'dashboard view list changed; re-listing entities');
      onCatalogChanged?.call();
    } finally {
      _refreshingDashboardViews = false;
    }
  }

  /// The slow-moving values, refreshed on the poll cadence.
  Future<void> _refresh() async {
    final stats = await commands.execute('getStats', const {});
    final data = stats.data;
    if (stats.ok && data is Map) {
      final battery = (data['battery'] as num?)?.toInt();
      if (battery != null) await _send('battery', battery);
      await _send('charging', data['charging'] == true);
      final cpu = (data['cpu'] as num?)?.round();
      if (cpu != null) await _send('cpu', cpu);
      final cpuClock = (data['cpuClock'] as num?)?.round();
      if (cpuClock != null) await _send('cpu_clock', cpuClock);
      final temp = data['temp'] as num?;
      if (temp != null) await _send('cpu_temp', temp.round());
      final batteryTemp = data['batteryTemp'] as num?;
      if (batteryTemp != null) {
        await _send('battery_temp', (batteryTemp * 10).round() / 10);
      }
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
    final storage = details.ok && details.data is Map
        ? ((details.data as Map)['storage'] as Map?)
        : null;
    final storageFree = storage?['free'] as num?;
    final storageTotal = storage?['total'] as num?;
    await _send(
      'storage_free',
      storageFree != null && storageFree >= 0
          ? storageFree ~/ (1024 * 1024)
          : null,
    );
    await _send(
      'storage_total',
      storageTotal != null && storageTotal > 0
          ? storageTotal ~/ (1024 * 1024)
          : null,
    );
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
    // No reading at all, not even a remembered one (first run): nothing
    // to send. The device manager already answers with the last known
    // value where there is one.
    lux ??= int.tryParse(_settings.internal('esphome_last_lux'));
    if (lux != null) _lux.offer(lux.round());
    await _sendIpAddresses();
    // A start with no address yet skips the admin URL, and nothing else
    // would send it once one turns up (issue #1251).
    await _sendAdminUrl();
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
    // Every completed poll IS a sighting.
    await _send('last_seen', DateTime.now().toUtc().toIso8601String());
  }
}

/// A command's answer cut to fit one ESPHome frame, which holds at most
/// 64 KB: stdout and stderr can each be 32 KB and JSON escaping grows
/// them further. stderr keeps its head and stdout gives up the rest, with
/// truncated set whenever anything was cut.
Map<String, Object?> fitCommandResponse(
  Map<String, Object?> response, {
  int limit = 48000,
}) {
  int size(Map<String, Object?> value) => utf8.encode(jsonEncode(value)).length;
  var fitted = Map<String, Object?>.of(response);
  final stderr = '${fitted['stderr'] ?? ''}';
  if (stderr.length > 4096) {
    fitted = {
      ...fitted,
      'stderr': stderr.substring(0, 4096),
      'truncated': true,
    };
  }
  final stdout = '${fitted['stdout'] ?? ''}';
  if (size(fitted) <= limit) return fitted;
  // The longest head of stdout that fits. Escaping makes the byte cost of
  // a character anywhere from 1 to 6, so search rather than estimate.
  Map<String, Object?> cut(int length) => {
    ...fitted,
    'stdout': stdout.substring(0, length),
    'truncated': true,
  };
  var low = 0, high = stdout.length;
  while (low < high) {
    final mid = (low + high + 1) ~/ 2;
    if (size(cut(mid)) <= limit) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }
  return cut(low);
}
