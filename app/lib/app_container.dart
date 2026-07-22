import 'core/command_registry.dart';
import 'core/event_bus.dart';
import 'core/logging.dart';
import 'core/manager.dart';
import 'managers/audio/audio_routing_manager.dart';
import 'managers/browser/browser_manager.dart';
import 'managers/device/device_manager.dart';
import 'managers/dlna/dlna_manager.dart';
import 'managers/home_assistant/home_assistant_manager.dart';
import 'managers/js_api/js_api_manager.dart';
import 'managers/kiosk/kiosk_manager.dart';
import 'managers/motion/motion_manager.dart';
import 'managers/mqtt/mqtt_manager.dart';
import 'managers/proxy/proxy_manager.dart';
import 'managers/remote/remote_manager.dart';
import 'managers/screen/screen_manager.dart';
import 'managers/screensaver/immich_manager.dart';
import 'managers/screensaver/screensaver_manager.dart';
import 'managers/sendspin/sendspin_manager.dart';
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
    proxy = ProxyManager(bus, commands, log, settings);
    browser = BrowserManager(bus, commands, log, settings);
    // Composition-root wiring, not a manager-to-manager reference: every
    // page load funnels through BrowserManager.loadUrl, and the proxy is
    // the one that knows whether the URL must move to the loopback origin.
    browser.urlMapper = proxy.mapUrl;
    kiosk = KioskManager(bus, commands, log, settings);
    screensaver = ScreensaverManager(bus, commands, log, settings);
    immich = ImmichManager(bus, commands, log, settings);
    motion = MotionManager(bus, commands, log, settings);
    homeAssistant = HomeAssistantManager(bus, commands, log, settings);
    // Before wakeWord: its init seeds the mic selector the engine reads at
    // start, and its SettingChanged subscription must run before wakeWord's
    // restart re-opens capture.
    audio = AudioRoutingManager(bus, commands, log, settings);
    wakeWord = WakeWordManager(bus, commands, log, settings);
    mqtt = MqttManager(bus, commands, log, settings);
    sendspin = SendspinManager(bus, commands, log, settings);
    dlna = DlnaManager(bus, commands, log, settings);
    sound = SoundManager(bus, commands, log);
    update = UpdateManager(bus, commands, log);
    remote = RemoteManager(bus, commands, log, settings);
  }

  final bus = EventBus();
  final log = Logger();
  late final commands = CommandRegistry(log);

  late final SettingsManager settings;
  late final DeviceManager device;
  late final ScreenManager screen;
  late final ProxyManager proxy;
  late final BrowserManager browser;
  late final KioskManager kiosk;
  late final ScreensaverManager screensaver;
  late final ImmichManager immich;
  late final MotionManager motion;
  late final HomeAssistantManager homeAssistant;
  late final AudioRoutingManager audio;
  late final WakeWordManager wakeWord;
  late final MqttManager mqtt;
  late final SendspinManager sendspin;
  late final DlnaManager dlna;
  late final SoundManager sound;
  late final UpdateManager update;
  late final RemoteManager remote;

  /// Built after [device.init] so it can carry the app version.
  late final JsApiManager jsApi;

  List<Manager> get _ordered => [
        settings,
        device,
        screen,
        proxy,
        browser,
        jsApi,
        kiosk,
        screensaver,
        immich,
        motion,
        homeAssistant,
        audio,
        wakeWord,
        mqtt,
        sendspin,
        dlna,
        sound,
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
