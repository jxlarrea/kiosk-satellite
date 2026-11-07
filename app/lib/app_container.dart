import 'dart:async';

import 'core/command_registry.dart';
import 'core/event_bus.dart';
import 'core/events.dart';
import 'core/headless.dart';
import 'core/locale_dates.dart';
import 'core/logging.dart';
import 'core/manager.dart';
import 'managers/plugins/plugin_camera.dart';
import 'managers/plugins/plugin_manager.dart';
import 'managers/plugins/plugin_host_api.dart';
import 'managers/shizuku/shizuku_manager.dart';
import 'managers/assist_pipeline/assist_pipeline_manager.dart';
import 'managers/audio/audio_routing_manager.dart';
import 'managers/audio/noise_level_manager.dart';
import 'managers/browser/browser_manager.dart';
import 'managers/camera/camera_manager.dart';
import 'managers/device/device_manager.dart';
import 'managers/device_camera/device_camera_manager.dart';
import 'managers/btproxy/bt_proxy_manager.dart';
import 'managers/airplay/airplay_manager.dart';
import 'managers/dlna/dlna_manager.dart';
import 'managers/dlna/headless_dlna_player.dart';
import 'managers/files/files_manager.dart';
import 'managers/gestures/gesture_mappings.dart' show pluginActionNames;
import 'managers/gestures/gestures_manager.dart';
import 'managers/gestures/hardware_buttons.dart';
import 'managers/glance/glance_manager.dart';
import 'managers/home_assistant/home_assistant_manager.dart';
import 'managers/home_assistant/plugin_ha_socket.dart';
import 'managers/sendspin/plugin_ma_socket.dart';
import 'managers/js_api/js_api_manager.dart';
import 'managers/js_api/page_ha_socket.dart';
import 'managers/js_api/page_state_manager.dart';
import 'managers/kiosk/drawer_items.dart';
import 'managers/kiosk/kiosk_manager.dart';
import 'managers/launcher/app_launcher_manager.dart';
import 'managers/launcher/home_launcher_manager.dart';
import 'managers/led/led_manager.dart';
import 'managers/motion/motion_entity_manager.dart';
import 'managers/motion/motion_manager.dart';
import 'managers/motion/onvif_events_manager.dart';
import 'managers/notifications/notification_manager.dart';
import 'managers/fleet/fleet_manager.dart';
import 'managers/fleet/fleet_sync_manager.dart';
import 'managers/intercom/intercom_manager.dart';
import 'managers/alarms/alarm_manager.dart';
import 'managers/calendar/calendar_manager.dart';
import 'managers/music_library/music_library_manager.dart';
import 'managers/analytics/analytics_manager.dart';
import 'managers/analytics/usage_counters.dart';
import 'managers/broadcasts/event_broadcast_manager.dart';
import 'managers/location/location_manager.dart';
import 'managers/screensaver/celestial_location.dart';
import 'managers/person/person_sensor_manager.dart';
import 'managers/proximity/proximity_manager.dart';
import 'managers/proxy/proxy_manager.dart';
import 'managers/remote/remote_manager.dart';
import 'managers/screen/adaptive_light_manager.dart';
import 'managers/screen/screen_manager.dart';
import 'managers/screensaver/immich_manager.dart';
import 'managers/screensaver/screensaver_manager.dart';
import 'managers/sendspin/sendspin_manager.dart';
import 'managers/service/service_manager.dart';
import 'managers/sound/sound_manager.dart';
import 'managers/settings/echo_defaults.dart';
import 'managers/settings/echo_image_settings.dart';
import 'managers/settings/headless_settings.dart';
import 'managers/settings/provisioning.dart';
import 'managers/settings/settings_manager.dart';
import 'managers/update/android_update_policy_manager.dart';
import 'managers/update/system_update_manager.dart';
import 'managers/update/update_manager.dart';
import 'managers/voice/voice_manager.dart';
import 'managers/voice/voice_requests_manager.dart';
import 'managers/voice_timers/voice_timer_manager.dart';
import 'managers/wake_word/wake_word_manager.dart';

/// Composition root. Construction does no work; [init] brings managers up in
/// dependency-safe order (settings first, remote last so everything it
/// administers already exists).
class AppContainer {
  AppContainer() {
    settings = SettingsManager(bus, commands, log);
    device = DeviceManager(bus, commands, log, settings);
    screen = ScreenManager(bus, commands, log, settings);
    service = ServiceManager(bus, commands, log, settings);
    proxy = ProxyManager(bus, commands, log, settings);
    browser = BrowserManager(bus, commands, log, settings);
    // Constructed before camera, which streams Home Assistant camera
    // entities through its WebRTC signaling (issue #124). Construction
    // order only; init order below is unchanged.
    homeAssistant = HomeAssistantManager(bus, commands, log, settings);
    camera = CameraManager(bus, commands, log, settings, homeAssistant);
    // After homeAssistant: it watches the light sensor entity through it.
    adaptiveLight = AdaptiveLightManager(
      bus,
      commands,
      log,
      settings,
      homeAssistant,
    );
    // Composition-root wiring, not a manager-to-manager reference: every
    // page load funnels through BrowserManager.loadUrl, and the proxy is
    // the one that knows whether the URL must move to the loopback origin.
    browser.urlMapper = proxy.mapUrl;
    kiosk = KioskManager(bus, commands, log, settings);
    launcher = AppLauncherManager(bus, commands, log, settings);
    homeLauncher = HomeLauncherManager(bus, commands, log, settings);
    gestures = GesturesManager(bus, commands, log, settings);
    screensaver = ScreensaverManager(
      bus,
      commands,
      log,
      settings,
      // The reading the Clock screensaver's Night mode decides by.
      lightReading: () => device.hasLightSensor ? device.lightLux : null,
    );
    immich = ImmichManager(bus, commands, log, settings);
    // Before motion: its init runs the legacy motion-camera migration the
    // motion manager's gate reads.
    deviceCamera = DeviceCameraManager(bus, commands, log, settings);
    motion = MotionManager(bus, commands, log, settings);
    // It watches the motion sensor entity through homeAssistant.
    motionEntity = MotionEntityManager(
      bus,
      commands,
      log,
      settings,
      homeAssistant,
    );
    proximity = ProximityManager(bus, commands, log, settings);
    location = LocationManager(bus, commands, log, settings);
    celestial = CelestialLocator(
      bus,
      commands,
      log,
      settings,
      location,
      homeAssistant,
    );
    analytics = AnalyticsManager(bus, commands, log, settings);
    personSensor = PersonSensorManager(bus, commands, log, settings);
    // It watches its Home Assistant source through homeAssistant.
    onvifEvents = OnvifEventsManager(
      bus,
      commands,
      log,
      settings,
      homeAssistant,
    );
    // The Portal turns its own screen on for someone it sees, and only the
    // person sensor's log tail can tell that wake from the power button.
    screensaver.systemWakeSource = personSensor.wakeSource;
    // Before wakeWord: its init seeds the mic selector the engine reads at
    // start, and its SettingChanged subscription must run before wakeWord's
    // restart re-opens capture.
    audio = AudioRoutingManager(bus, commands, log, settings);
    wakeWord = WakeWordManager(bus, commands, log, settings);
    noiseLevel = NoiseLevelManager(bus, commands, log);
    // After wakeWord: the native pipeline transport consumes the engine's
    // in-process audio stream through it (issue-free: one consumer per
    // turn, negotiated by Voice Satellite).
    pipeline = AssistPipelineManager(bus, commands, log, settings, wakeWord);
    sendspin = SendspinManager(bus, commands, log, settings);
    dlna = DlnaManager(bus, commands, log, settings);
    airplay = AirPlayManager(bus, commands, log, settings);
    btProxy = BtProxyManager(bus, commands, log, settings);
    // Composition-root wiring: the gesture actions tell Home Assistant
    // which kiosk ran them (issue #1259) by the device its ESPHome server
    // is adopted as.
    gestures.kioskDeviceId = () async =>
        homeAssistant.esphomeDeviceId(await btProxy.identityMac());
    // Composition-root wiring: the opaque full-screen overlays report their
    // visibility so the dashboard WebView stops compositing underneath
    // them. The settings route reports from the UI, where its transition
    // timing lives; these two have clean manager-side edges.
    camera.activeViewId.addListener(
      () => browser.setCovered(
        'camera view',
        covered: camera.activeViewId.value != null,
      ),
    );
    void syncDlnaCover() =>
        browser.setCovered('dlna', covered: dlna.coversScreen);
    dlna.media.addListener(syncDlnaCover);
    dlna.transportState.addListener(syncDlnaCover);
    dlna.pending.addListener(syncDlnaCover);
    files = FilesManager(bus, commands, log);
    sound = SoundManager(bus, commands, log, settings: settings);
    voiceTimers = VoiceTimerManager(bus, commands, log);
    voice = VoiceManager(bus, commands, log, settings, btProxy, wakeWord);
    notifications = NotificationManager(bus, commands, log, settings);
    update = UpdateManager(
      bus,
      commands,
      log,
      useShizuku: () => settings.get(shizukuInstallUpdates),
      customSource: () => settings.get(updateSource) == 'custom'
          ? settings.get(updateSourceUrl).trim()
          : null,
    );
    systemUpdate = SystemUpdateManager(bus, commands, log);
    androidUpdates = AndroidUpdatePolicyManager(bus, commands, log, settings);
    // After homeAssistant: it reads states through it for the fallback.
    glance = GlanceManager(bus, commands, log, settings, homeAssistant);
    shizuku = ShizukuManager(bus, commands, log);
    plugins = PluginManager(bus, commands, log)
      ..appVersion = (() => device.appVersion)
      ..voice = PluginVoiceFeed(
        view: voice.view,
        level: voice.level,
        settings: settings,
      )
      ..screensaverModes = PluginScreensaverModes(
        read: () => screensaver.modeState,
        hold: screensaver.setModeOverride,
        release: screensaver.clearModeOverride,
      )
      ..screensaverFeed = PluginScreensaverFeed(
        view: screensaver.activeView,
        night: screensaver.clockNight,
        nowPlaying: () => screensaver.nowPlayingShown,
        nowPlayingShared: () => screensaver.nowPlayingShared,
        settings: settings,
        setTint: screensaver.setPluginTint,
        clearTint: screensaver.clearPluginTint,
      )
      ..camera = PluginCamera(
        motion: motion,
        commands: commands,
        settings: settings,
        log: log,
      )
      ..runAction = gestures.runPluginSettingAction;
    pluginActionNames = plugins.actionNames;
    // A snapshot binding the camera mid-scan would take it from the scanner.
    deviceCamera.scannerActive = () => motion.scannerHeld;
    settings.pluginScreensavers = () => plugins.screensaverOptions;
    screensaver.pluginTouch = plugins.screensaverTouch;
    settings.pluginVoiceSkins = () => plugins.voiceSkinOptions;
    remote = RemoteManager(bus, commands, log, settings);
    fleet = FleetManager(bus, commands, log, settings);
    fleetSync = FleetSyncManager(bus, commands, log, settings)
      ..plugins = plugins;
    plugins.fleetManaged = (id) =>
        fleetSync.following && fleetSync.syncedPlugins.containsKey(id);
    plugins.onActivity = (name) =>
        unawaited(UsageCounters.bump(settings, name));
    // A removed plugin's rows leave the drawer menu's list, so a reinstall
    // starts fresh like any new plugin action (issue #1194).
    plugins.onRemoved = (id) {
      final items = DrawerItems.decode(settings.get(uiDrawerItems));
      final pruned = items.withoutPlugin(id);
      if (pruned.encode() != items.encode()) {
        unawaited(settings.set(uiDrawerItems, pruned.encode()));
      }
    };
    intercom = IntercomManager(bus, commands, log, settings);
    alarms = AlarmManager(bus, commands, log, settings)
      ..screensaverModeOverride = () => screensaver.modeOverride.value;
    calendar = CalendarManager(bus, commands, log, settings);
    musicLibrary = MusicLibraryManager(
      bus,
      commands,
      log,
      settings,
      nowPlaying: sendspin.nowPlaying,
      playerArtwork: sendspin.loadArtwork,
    );
    // The library is opaque and full screen too, and so are the calendar
    // and Now Playing when it does not share the screen.
    musicLibrary.visible.addListener(
      () => browser.setCovered(
        'music library',
        covered: musicLibrary.visible.value,
      ),
    );
    calendar.visible.addListener(
      () => browser.setCovered('calendar', covered: calendar.visible.value),
    );
    screensaver.nowPlayingCovers.addListener(
      () => browser.setCovered(
        'now playing',
        covered: screensaver.nowPlayingCovers.value,
      ),
    );
    intercom.videoOnScreen.addListener(
      () => browser.setCovered(
        'intercom video',
        covered: intercom.videoOnScreen.value,
      ),
    );
    voiceRequests = VoiceRequestsManager(bus, commands, log, settings);
    // It follows what the managers above are doing, through the bus and
    // the media players' own states.
    leds = LedManager(
      bus,
      commands,
      log,
      settings,
      sendspin.localPlaying,
      dlna.transportState,
    );
    broadcasts = EventBroadcastManager(bus, commands, log);
    // Composition-root wiring: it reads the state other managers own and
    // reports it to pages (kioskSatellite.getTheme / getKioskState).
    pageState = PageStateManager(
      bus,
      commands,
      log,
      settings,
      dashboardDark: homeAssistant.dashboardDark,
      kioskLocked: () => kiosk.locked,
      lockdownActive: () => kiosk.lockdownActive,
      screensaverActive: () => screensaver.isActive,
      screensaverView: screensaver.activeView,
      cameraView: camera.activeViewId,
      mediaSummary: () => sendspin.mediaSummary,
    );
  }

  final bus = EventBus();
  final log = Logger();
  // The device's own UI executes through this handle; every manager
  // re-scopes it under its own name.
  late final commands = CommandRegistry(log).as('ui');

  late final SettingsManager settings;
  late final DeviceManager device;
  late final AdaptiveLightManager adaptiveLight;
  late final ScreenManager screen;
  late final ServiceManager service;
  late final ProxyManager proxy;
  late final BrowserManager browser;
  late final CameraManager camera;
  late final KioskManager kiosk;
  late final AppLauncherManager launcher;
  late final HomeLauncherManager homeLauncher;
  late final GesturesManager gestures;
  late final ScreensaverManager screensaver;
  late final ImmichManager immich;
  late final DeviceCameraManager deviceCamera;
  late final MotionManager motion;
  late final MotionEntityManager motionEntity;
  late final ProximityManager proximity;
  late final LocationManager location;
  late final CelestialLocator celestial;
  late final AnalyticsManager analytics;
  late final PersonSensorManager personSensor;
  late final OnvifEventsManager onvifEvents;
  late final HomeAssistantManager homeAssistant;
  late final AudioRoutingManager audio;
  late final EventBroadcastManager broadcasts;
  late final WakeWordManager wakeWord;
  late final NoiseLevelManager noiseLevel;
  late final AssistPipelineManager pipeline;
  late final SendspinManager sendspin;
  late final DlnaManager dlna;
  late final AirPlayManager airplay;
  late final BtProxyManager btProxy;
  late final FilesManager files;
  late final GlanceManager glance;
  late final SoundManager sound;
  late final VoiceTimerManager voiceTimers;
  late final VoiceManager voice;
  late final NotificationManager notifications;
  late final UpdateManager update;
  late final SystemUpdateManager systemUpdate;
  late final AndroidUpdatePolicyManager androidUpdates;
  late final ShizukuManager shizuku;
  late final PluginManager plugins;
  late final RemoteManager remote;
  late final FleetManager fleet;
  late final FleetSyncManager fleetSync;
  late final IntercomManager intercom;
  late final AlarmManager alarms;
  late final CalendarManager calendar;
  late final MusicLibraryManager musicLibrary;
  late final VoiceRequestsManager voiceRequests;
  late final LedManager leds;
  late final PageStateManager pageState;

  /// Built after [device.init] so it can carry the app version.
  late final JsApiManager jsApi;

  List<Manager> get _ordered => [
    settings,
    device,
    // Before the managers whose events it mirrors start publishing them.
    broadcasts,
    // After device, whose sensor it reads, and before screen, which starts
    // adaptive brightness from its reading.
    adaptiveLight,
    screen,
    service,
    proxy,
    browser,
    camera,
    jsApi,
    kiosk,
    // After kiosk: it listens for the AppLaunched its launchApp emits,
    // and its bringToFront/screenOn calls resolve at execute time.
    launcher,
    // Same placement logic: its role relays arrive as bus events KioskManager
    // forwards, and its acquire path invokes the kiosk_lock channel.
    homeLauncher,
    screensaver,
    immich,
    deviceCamera,
    motion,
    // After screensaver, which takes its motion.
    motionEntity,
    proximity,
    location,
    celestial,
    // After device (its info feeds every report) and settings; its first
    // report waits minutes anyway.
    analytics,
    personSensor,
    // After personSensor: its init asks for the current presence.
    onvifEvents,
    homeAssistant,
    audio,
    // After kiosk (it relays GestureDetected) and after audio: gestures may
    // open the shared microphone for clap detection at init, and the capture
    // selector and tuning must be seeded first. Commands resolve at execute
    // time, so running late costs nothing.
    gestures,
    wakeWord,
    // After wakeWord: it seeds from the engine's state. Before btProxy,
    // whose first refresh reads the level.
    noiseLevel,
    pipeline,
    sendspin,
    dlna,
    // After sendspin: the surfaces it drives follow an AirPlay session.
    airplay,
    // Before btProxy, whose first catalog lists the LED Control Idle
    // entities only once ledStatus says there are lights, and before the
    // remote admin's first request reads its hidden settings. It follows
    // the other managers through the bus, so starting before them costs
    // nothing.
    leds,
    // Before btProxy too: its first catalog lists the Firmware entity only
    // once getSystemUpdateStatus says the image updates itself.
    systemUpdate,
    // Before remote, whose first request reads the rows it hides on a
    // device that is not the device owner.
    androidUpdates,
    btProxy,
    files,
    glance,
    sound,
    voiceTimers,
    // After the ESPHome server (its voice link), the wake word engine it
    // configures, and the sound and timer managers it plays and shows
    // through.
    voice,
    notifications,
    update,
    shizuku,
    plugins,
    remote,
    // After remote: it announces the admin server the remote manager runs.
    fleet,
    // After fleet: it reads this kiosk's id and the others from it.
    fleetSync,
    // After fleet too: the roster is the switcher's list. After sound: it
    // chimes through it.
    intercom,
    // Its first check can ring at once, and a ring reaches for the
    // screen, the screensaver, the kiosk and the wake word's stop word.
    alarms,
    // Nothing reaches Home Assistant until a screen watches some days.
    calendar,
    // Nothing connects until the library opens. Its plays go through the
    // Sendspin manager's commands.
    musicLibrary,
    // After intercom and alarms: it runs their commands.
    voiceRequests,
    // Last: it reads the state every manager above keeps.
    pageState,
  ];

  Future<void> init() async {
    await settings.init();
    // Dates and numbers follow the app's language, not Android's. First on
    // the bus, so a language change lands before any listener formats.
    applyAppDateLanguage(settings.get(uiLanguage));
    bus.on<SettingChanged>().listen((e) {
      if (e.key == uiLanguage.key) {
        applyAppDateLanguage(settings.get(uiLanguage));
      }
    });
    // An Echo image's first start: before the provisioning below, which
    // may override it, and before any manager reads its settings.
    await EchoDefaults(settings, log).apply();
    // Apply any adb/MDM intent provisioning before other managers read
    // their settings; the channel also handles pushes while running.
    await ProvisioningChannel(settings, log).init();
    // A device without a screen hides and pins the display settings before
    // any manager reads them.
    if (Headless.active) await HeadlessSettings(settings, bus, log).init();
    // The Echo images pin their own few settings on every start.
    await EchoImageSettings(settings, bus, log).init();
    await device.init();
    jsApi = JsApiManager(bus, commands, log, device.appVersion)
      ..haSockets = PageHaSockets(
        baseUrl: () => homeAssistant.baseUrl,
        token: () => settings.get(haToken),
        allowed: () async =>
            settings.get(haCustomPagesSocket) &&
            browser.isCustomPage(await browser.liveUrl()),
        log: log,
        onOpen: () =>
            unawaited(UsageCounters.bump(settings, 'custom_page_ha_sockets')),
      );
    plugins.haSocket = HaPluginSocket(
      baseUrl: () => homeAssistant.baseUrl,
      token: () => settings.get(haToken),
      log: log,
    );
    plugins.maSocket = MaPluginSocket(
      baseUrl: () => settings.get(sendspinMaUrl),
      token: () => settings.get(sendspinMaToken),
      log: log,
    );
    // Switched off: the sockets open now close, and the page's reconnects
    // hear no.
    bus.on<SettingChanged>().listen((e) {
      if (e.key == haCustomPagesSocket.key && e.value != true) {
        jsApi.haSockets?.closeAll('setting off', notify: true);
      }
      if (e.key == haUrl.key || e.key == haToken.key) {
        plugins.haSocket?.restart();
      }
      if (e.key == sendspinMaUrl.key || e.key == sendspinMaToken.key) {
        plugins.maSocket?.restart();
      }
    });
    for (final manager in _ordered.skip(2)) {
      await manager.init();
    }
    if (Headless.active) {
      // Without a screen there is no DLNA overlay to own the player, and
      // the buttons reach the app through their own service.
      HeadlessDlnaPlayer(dlna, device.mediaGain, log).start();
      await HardwareButtons(
        bus: bus,
        commands: commands,
        log: log,
        settings: settings,
        alarms: alarms,
        intercom: intercom,
        voice: voice,
        voiceTimers: voiceTimers,
        sendspin: sendspin,
      ).start();
    }
    log.info('app', 'all managers initialized');
  }

  Future<void> dispose() async {
    for (final manager in _ordered.reversed) {
      await manager.dispose();
    }
    await log.dispose();
    await bus.dispose();
  }
}
