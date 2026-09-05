import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/browser_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EventBus bus;
  late BrowserManager browser;
  late SettingsManager settings;
  const channel = MethodChannel('kiosk_satellite/webview_freeze');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    messenger.setMockMethodCallHandler(channel, (_) async => 1);
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    browser = BrowserManager(bus, commands, log, settings);
    await browser.init();
  });

  Future<void> publish(AppEvent event) async {
    bus.publish(event);
    await Future<void>.delayed(Duration.zero);
  }

  tearDown(() async {
    await browser.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'defaults on and follows coverage independently of rendering pause',
    () async {
      expect(settings.get(defs.pauseDashboardCameras), isTrue);
      await settings.set(defs.freezeOnScreensaver, false);
      await publish(const ScreensaverStateChanged(active: true));
      expect(browser.dashboardCameraStreamsPaused, isFalse);
      await publish(const ScreensaverViewChanged(view: 'clock'));
      expect(browser.dashboardCameraStreamsPaused, isTrue);
      await publish(const ScreensaverStateChanged(active: false));
      expect(browser.dashboardCameraStreamsPaused, isFalse);
    },
  );

  test(
    'live toggles and screensaver mode changes restore camera streams',
    () async {
      await publish(const ScreensaverViewChanged(view: 'clock'));
      await publish(const ScreensaverStateChanged(active: true));
      await settings.set(defs.pauseDashboardCameras, false);
      expect(browser.dashboardCameraStreamsPaused, isFalse);
      await settings.set(defs.pauseDashboardCameras, true);
      expect(browser.dashboardCameraStreamsPaused, isTrue);
      await publish(const ScreensaverViewChanged(view: null));
      expect(browser.dashboardCameraStreamsPaused, isFalse);
      await publish(const ScreenStateChanged(on: false));
      expect(browser.dashboardCameraStreamsPaused, isTrue);
      await publish(const ScreenStateChanged(on: true));
      expect(browser.dashboardCameraStreamsPaused, isFalse);
    },
  );

  test(
    'a website screensaver on HA origin can pause only the dashboard cameras',
    () async {
      await settings.set(defs.haUrl, 'http://ha.local:8123');
      await settings.set(
        defs.screensaverWebsiteUrl,
        'http://ha.local:8123/clock',
      );
      await publish(const ScreensaverViewChanged(view: 'website'));
      await publish(const ScreensaverStateChanged(active: true));
      expect(browser.dashboardCameraStreamsPaused, isTrue);
    },
  );

  test(
    'settings and camera feature overlays alone do not suspend dashboard streams',
    () {
      browser.setCovered('camera view', covered: true);
      expect(browser.dashboardCameraStreamsPaused, isFalse);
      browser.setCovered('settings', covered: true);
      expect(browser.dashboardCameraStreamsPaused, isFalse);
    },
  );
}
