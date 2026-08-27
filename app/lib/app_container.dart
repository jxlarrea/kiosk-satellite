import 'core/command_registry.dart';
import 'core/event_bus.dart';
import 'core/logging.dart';
import 'core/manager.dart';
import 'managers/assist_pipeline/assist_pipeline_manager.dart';
import 'managers/audio/audio_routing_manager.dart';
import 'managers/browser/browser_manager.dart';
import 'managers/camera/camera_manager.dart';
import 'managers/device/device_manager.dart';
import 'managers/device_camera/device_camera_manager.dart';
import 'managers/btproxy/bt_proxy_manager.dart';
import 'managers/dlna/dlna_manager.dart';
import 'managers/files/files_manager.dart';
import 'managers/gestures/gestures_manager.dart';
import 'managers/glance/glance_manager.dart';
import 'managers/home_assistant/home_assistant_manager.dart';
import 'managers/js_api/js_api_manager.dart';
import 'managers/kiosk/kiosk_manager.dart';
import 'managers/launcher/app_launcher_manager.dart';
import 'managers/motion/motion_manager.dart';
import 'managers/notifications/notification_manager.dart';
import 'managers/mqtt/mqtt_manager.dart';
import 'managers/proxy/proxy_manager.dart';
import 'managers/remote/remote_manager.dart';
import 'managers/screen/screen_manager.dart';
import 'managers/screensaver/immich_manager.dart';
import 'managers/screensaver/screensaver_manager.dart';
import 'managers/sendspin/sendspin_manager.dart';
import 'managers/service/service_manager.dart';
import 'managers/sound/sound_manager.dart';
import 'managers/settings/provisioning.dart';
import 'managers/settings/settings_manager.dart';
import 'managers/update/update_manager.dart';
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
    // Composition-root wiring, not a manager-to-manager reference: every
    // page load funnels through BrowserManager.loadUrl, and the proxy is
    // the one that knows whether the URL must move to the loopback origin.
    browser.urlMapper = proxy.mapUrl;
    kiosk = KioskManager(bus, commands, log, settings);
    launcher = AppLauncherManager(bus, commands, log, settings);
    gestures = GesturesManager(bus, commands, log, settings);
    screensaver = ScreensaverManager(bus, commands, log, settings);
    immich = ImmichManager(bus, commands, log, settings);
    // Before motion: its init runs the legacy motion-camera migration the
    // motion manager's gate reads.
    deviceCamera = DeviceCameraManager(bus, commands, log, settings);
    motion = MotionManager(bus, commands, log, settings);
    // Before wakeWord: its init seeds the mic selector the engine reads at
    // start, and its SettingChanged subscription must run before wakeWord's
    // restart re-opens capture.
    audio = AudioRoutingManager(bus, commands, log, settings);
    wakeWord = WakeWordManager(bus, commands, log, settings);
    // After wakeWord: the native pipeline transport consumes the engine's
    // in-process audio stream through it (issue-free: one consumer per
    // turn, negotiated by Voice Satellite).
    pipeline = AssistPipelineManager(bus, commands, log, settings, wakeWord);
    mqtt = MqttManager(bus, commands, log, settings);
    sendspin = SendspinManager(bus, commands, log, settings);
    dlna = DlnaManager(bus, commands, log, settings);
    btProxy = BtProxyManager(bus, commands, log, settings);
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
    sound = SoundManager(bus, commands, log);
    notifications = NotificationManager(bus, commands, log, settings);
    update = UpdateManager(bus, commands, log);
    // After homeAssistant: it reads states through it for the fallback.
    glance = GlanceManager(bus, commands, log, settings, homeAssistant);
    remote = RemoteManager(bus, commands, log, settings);
  }

  final bus = EventBus();
  final log = Logger();
  // The device's own UI executes through this handle; every manager
  // re-scopes it under its own name.
  late final commands = CommandRegistry(log).as('ui');

  late final SettingsManager settings;
  late final DeviceManager device;
  late final ScreenManager screen;
  late final ServiceManager service;
  late final ProxyManager proxy;
  late final BrowserManager browser;
  late final CameraManager camera;
  late final KioskManager kiosk;
  late final AppLauncherManager launcher;
  late final GesturesManager gestures;
  late final ScreensaverManager screensaver;
  late final ImmichManager immich;
  late final DeviceCameraManager deviceCamera;
  late final MotionManager motion;
  late final HomeAssistantManager homeAssistant;
  late final AudioRoutingManager audio;
  late final WakeWordManager wakeWord;
  late final AssistPipelineManager pipeline;
  late final MqttManager mqtt;
  late final SendspinManager sendspin;
  late final DlnaManager dlna;
  late final BtProxyManager btProxy;
  late final FilesManager files;
  late final GlanceManager glance;
  late final SoundManager sound;
  late final NotificationManager notifications;
  late final UpdateManager update;
  late final RemoteManager remote;

  /// Built after [device.init] so it can carry the app version.
  late final JsApiManager jsApi;

  List<Manager> get _ordered => [
    settings,
    device,
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
    screensaver,
    immich,
    deviceCamera,
    motion,
    homeAssistant,
    audio,
    // After kiosk (it relays GestureDetected) and after audio: gestures may
    // open the shared microphone for clap detection at init, and the capture
    // selector and tuning must be seeded first. Commands resolve at execute
    // time, so running late costs nothing.
    gestures,
    wakeWord,
    pipeline,
    mqtt,
    sendspin,
    dlna,
    btProxy,
    files,
    glance,
    sound,
    notifications,
    update,
    remote,
  ];

  Future<void> init() async {
    await settings.init();
    // Apply any adb/MDM intent provisioning before other managers read
    // their settings; the channel also handles pushes while running.
    await ProvisioningChannel(settings, log).init();
    await device.init();
    jsApi = JsApiManager(bus, commands, log, device.appVersion);
    for (final manager in _ordered.skip(2)) {
      await manager.init();
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
