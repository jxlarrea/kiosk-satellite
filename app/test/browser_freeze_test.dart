import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/browser_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The screensaver rendering freeze (browser.freeze_on_screensaver): the
/// state machinery that does not need a live WebView. The native visibility
/// switch itself (WebViewFreeze) is platform-channel work covered by the
/// on-device pass.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late SettingsManager settings;
  late BrowserManager browser;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    browser = BrowserManager(bus, commands, log, settings);
    await browser.init();
  }

  test('enabling the freeze turns on Keep connected in the background',
      () async {
    await build({'ks.browser.disable_suspend': false});
    expect(settings.get(defs.disableSuspend), isFalse);
    await settings.set(defs.freezeOnScreensaver, true);
    await pumpEventQueue();
    expect(settings.get(defs.disableSuspend), isTrue);
  });

  test('disabling the freeze leaves Keep connected alone', () async {
    await build({
      'ks.browser.disable_suspend': false,
      'ks.browser.freeze_on_screensaver': true,
    });
    await settings.set(defs.freezeOnScreensaver, false);
    await pumpEventQueue();
    expect(settings.get(defs.disableSuspend), isFalse);
  });

  test('an already-on Keep connected is not re-set (no rebuild churn)',
      () async {
    await build({});
    var suspendChanges = 0;
    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.disableSuspend.key) suspendChanges++;
    });
    await settings.set(defs.freezeOnScreensaver, true);
    await pumpEventQueue();
    expect(settings.get(defs.disableSuspend), isTrue);
    expect(suspendChanges, 0);
  });

  test('screensaver events without a WebView never mark the page frozen',
      () async {
    await build({'ks.browser.freeze_on_screensaver': true});
    bus.publish(const ScreensaverStateChanged(active: true));
    await pumpEventQueue();
    expect(browser.renderingFrozen, isFalse);
    bus.publish(const ScreensaverStateChanged(active: false));
    await pumpEventQueue();
    expect(browser.renderingFrozen, isFalse);
  });

  test('the screensaver alone does not freeze with the setting off',
      () async {
    await build({});
    bus.publish(const ScreensaverStateChanged(active: true));
    await pumpEventQueue();
    expect(browser.renderingFrozen, isFalse);
  });
}
