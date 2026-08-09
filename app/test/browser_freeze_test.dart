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
    bus.publish(const ScreensaverViewChanged(view: 'clock'));
    bus.publish(const ScreensaverStateChanged(active: true));
    // Past the paint delay: the freeze timer fires into a browser with no
    // page loaded and must leave the state alone.
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(browser.renderingFrozen, isFalse);
    bus.publish(const ScreensaverStateChanged(active: false));
    await pumpEventQueue();
    expect(browser.renderingFrozen, isFalse);
  });

  test('the screensaver alone does not freeze with the setting off',
      () async {
    await build({});
    bus.publish(const ScreensaverViewChanged(view: 'clock'));
    bus.publish(const ScreensaverStateChanged(active: true));
    await pumpEventQueue();
    expect(browser.renderingFrozen, isFalse);
  });

  // The native visibility switch, mocked at the platform channel: what the
  // Dart side actually asks of it per screensaver mode (issue #82).
  group('with a dashboard loaded', () {
    const channel = MethodChannel('kiosk_satellite/webview_freeze');
    late List<MethodCall> calls;

    setUp(() {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return 1;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('dim shows no overlay and leaves the dashboard rendering', () async {
      await build({'ks.browser.freeze_on_screensaver': true});
      browser.onPageLoaded('http://ha.local:8123/lovelace/0');
      bus.publish(const ScreensaverViewChanged(view: null));
      bus.publish(const ScreensaverStateChanged(active: true));
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(browser.renderingFrozen, isFalse);
      expect(calls, isEmpty);
    });

    test('a covering mode freezes after the paint delay; a mid-session '
        'flip to dim thaws immediately', () async {
      await build({'ks.browser.freeze_on_screensaver': true});
      browser.onPageLoaded('http://ha.local:8123/lovelace/0');
      bus.publish(const ScreensaverViewChanged(view: 'clock'));
      bus.publish(const ScreensaverStateChanged(active: true));
      await pumpEventQueue();
      // Not yet: the overlay gets a beat to paint first.
      expect(browser.renderingFrozen, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(browser.renderingFrozen, isTrue);
      expect(calls.last.arguments['hidden'], isTrue);

      // A schedule boundary swaps the clock for dim: the dashboard is the
      // display now, so it must come back without the paint delay.
      bus.publish(const ScreensaverViewChanged(view: null));
      await pumpEventQueue();
      expect(browser.renderingFrozen, isFalse);
      expect(calls.last.arguments['hidden'], isFalse);
    });

    test('an overlay page freezes the dashboard, and dismissing it thaws '
        'without the paint delay', () async {
      await build({});
      browser.onPageLoaded('http://ha.local:8123/lovelace/0');
      browser.showLinkOverlay('https://music.local:8095/');
      await pumpEventQueue();
      // The overlay gets the same beat to paint as a screensaver does.
      expect(browser.renderingFrozen, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(browser.renderingFrozen, isTrue);

      browser.dismissOverlay();
      await pumpEventQueue();
      expect(browser.renderingFrozen, isFalse);
      expect(calls.last.arguments['hidden'], isFalse);
    });

    test('an overlay on the dashboard origin leaves it rendering (the '
        'native side cannot tell the two views apart)', () async {
      await build({});
      browser.onPageLoaded('http://ha.local:8123/lovelace/0');
      browser.showLinkOverlay('http://ha.local:8123/map');
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(browser.renderingFrozen, isFalse);
      expect(calls, isEmpty);
    });
  });
}
