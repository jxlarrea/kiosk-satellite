import 'core/command_registry.dart';
import 'core/event_bus.dart';
import 'core/logging.dart';
import 'core/manager.dart';
import 'managers/browser/browser_manager.dart';
import 'managers/device/device_manager.dart';
import 'managers/home_assistant/home_assistant_manager.dart';
import 'managers/js_api/js_api_manager.dart';
import 'managers/kiosk/kiosk_manager.dart';
import 'managers/motion/motion_manager.dart';
import 'managers/remote/remote_manager.dart';
import 'managers/screen/screen_manager.dart';
import 'managers/screensaver/screensaver_manager.dart';
import 'managers/settings/provisioning.dart';
import 'managers/settings/settings_manager.dart';
import 'managers/wake_word/wake_word_manager.dart';

/// Composition root. Construction does no work; [init] brings managers up in
/// dependency-safe order (settings first, remote last so everything it
/// administers already exists).
class AppContainer {
  AppContainer() {
    settings = SettingsManager(bus, commands, log);
    device = DeviceManager(bus, commands, log, settings);
    screen = ScreenManager(bus, commands, log, settings);
    browser = BrowserManager(bus, commands, log, settings);
    kiosk = KioskManager(bus, commands, log, settings);
    screensaver = ScreensaverManager(bus, commands, log, settings);
    motion = MotionManager(bus, commands, log, settings);
    homeAssistant = HomeAssistantManager(bus, commands, log, settings);
    wakeWord = WakeWordManager(bus, commands, log, settings);
    remote = RemoteManager(bus, commands, log, settings);
  }

  final bus = EventBus();
  final log = Logger();
  late final commands = CommandRegistry(log);

  late final SettingsManager settings;
  late final DeviceManager device;
  late final ScreenManager screen;
  late final BrowserManager browser;
  late final KioskManager kiosk;
  late final ScreensaverManager screensaver;
  late final MotionManager motion;
  late final HomeAssistantManager homeAssistant;
  late final WakeWordManager wakeWord;
  late final RemoteManager remote;

  /// Built after [device.init] so it can carry the app version.
  late final JsApiManager jsApi;

  List<Manager> get _ordered => [
        settings,
        device,
        screen,
        browser,
        jsApi,
        kiosk,
        screensaver,
        motion,
        homeAssistant,
        wakeWord,
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
