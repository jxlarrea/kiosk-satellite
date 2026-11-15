import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/browser_manager.dart';
import 'package:kiosk_satellite/managers/browser/page_fullscreen_script.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records the scripts the dashboard was asked to run.
class _Controller extends Fake implements PlatformInAppWebViewController {
  final List<String> scripts = [];

  @override
  int getViewId() => 1;

  @override
  Future<dynamic> evaluateJavascript({
    required String source,
    ContentWorld? contentWorld,
  }) async {
    scripts.add(source);
    return null;
  }
}

/// An element of the dashboard in fullscreen is drawn above every Kiosk
/// Satellite surface (issue #1461), so the kiosk takes the page out of
/// fullscreen whenever it shows something of its own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const freezeChannel = MethodChannel('kiosk_satellite/webview_freeze');
  late EventBus bus;
  late BrowserManager browser;
  late _Controller platform;
  late InAppWebViewController controller;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(freezeChannel, (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    browser = BrowserManager(bus, commands, log, settings);
    await browser.init();
    platform = _Controller();
    controller = InAppWebViewController.fromPlatform(platform: platform);
    browser.attach(controller);
    browser.onPageLoaded('http://ha.local:8123/lovelace/0');
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(freezeChannel, null);
    await browser.dispose();
  });

  int exits() =>
      platform.scripts.where((s) => s == exitPageFullscreenJs).length;

  test('the screensaver starting takes the page out of fullscreen', () async {
    browser.onPageFullscreen(controller, fullscreen: true);
    expect(browser.pageFullscreen.value, isTrue);
    bus.publish(const ScreensaverStateChanged(active: true));
    await pumpEventQueue();
    expect(exits(), 1);
  });

  test('a cover over the dashboard takes the page out of fullscreen', () async {
    browser.onPageFullscreen(controller, fullscreen: true);
    browser.setCovered('camera view', covered: true);
    await pumpEventQueue();
    expect(exits(), 1);
  });

  test('fullscreen asked for under the screensaver ends at once', () async {
    bus.publish(const ScreensaverStateChanged(active: true));
    await pumpEventQueue();
    browser.onPageFullscreen(controller, fullscreen: true);
    await pumpEventQueue();
    expect(exits(), 1);
  });

  test('back leaves fullscreen only while the page is in it', () async {
    expect(browser.exitPageFullscreen('back'), isFalse);
    browser.onPageFullscreen(controller, fullscreen: true);
    expect(browser.exitPageFullscreen('back'), isTrue);
    browser.onPageFullscreen(controller, fullscreen: false);
    expect(browser.pageFullscreen.value, isFalse);
    expect(browser.exitPageFullscreen('back'), isFalse);
    await pumpEventQueue();
    expect(exits(), 1);
  });

  test('a WebView that is not the dashboard is ignored', () async {
    final other = InAppWebViewController.fromPlatform(platform: _Controller());
    browser.onPageFullscreen(other, fullscreen: true);
    expect(browser.pageFullscreen.value, isFalse);
  });

  test('a new WebView starts out of fullscreen', () async {
    browser.onPageFullscreen(controller, fullscreen: true);
    final next = _Controller();
    browser.attach(InAppWebViewController.fromPlatform(platform: next));
    expect(browser.pageFullscreen.value, isFalse);
  });
}
