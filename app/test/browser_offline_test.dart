import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/browser_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The offline state the kiosk screen draws its notice from: which loads
/// count as failed, and what clears the flag again. A false negative here is
/// Chromium's error page on the wall; a false positive is the notice covering
/// a perfectly good dashboard.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BrowserManager browser;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({
      'ks.browser.start_url': 'http://192.168.1.10:8123/lovelace/home',
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    browser = BrowserManager(bus, commands, log, settings);
    await browser.init();
  }

  tearDown(() async => browser.dispose());

  test('a fresh manager is not in the failed state', () async {
    await build();
    expect(browser.loadFailed.value, isFalse);
  });

  test('a failed load raises the flag, and the error page it commits '
      'does not lower it again', () async {
    await build();
    await browser.onLoadError('net::ERR_ADDRESS_UNREACHABLE');
    expect(browser.loadFailed.value, isTrue);
    // Chromium follows the error with an onLoadStop for its own error page:
    // the flag has to survive it, or the notice would flash and vanish.
    browser.onPageLoaded('http://192.168.1.10:8123/lovelace/home');
    expect(browser.loadFailed.value, isTrue);
    expect(browser.lastErrorDescription, 'net::ERR_ADDRESS_UNREACHABLE');
  });

  test('a load that finishes clean lowers it', () async {
    await build();
    await browser.onLoadError('net::ERR_NAME_NOT_RESOLVED');
    browser.onPageLoaded('http://192.168.1.10:8123/lovelace/home');
    // The retry succeeds: an onLoadStop with no error before it.
    browser.onPageLoaded('http://192.168.1.10:8123/lovelace/home');
    expect(browser.loadFailed.value, isFalse);
  });

  test('a main-frame server error counts as a failed load', () async {
    await build();
    // The secure context proxy answers 502 with an empty body while Home
    // Assistant is unreachable — a blank screen, not a page.
    await browser.onHttpError(502);
    expect(browser.loadFailed.value, isTrue);
    browser.onPageLoaded('http://127.0.0.1:18123/lovelace/home');
    expect(browser.loadFailed.value, isTrue);
    expect(browser.lastErrorDescription, 'HTTP 502');
    browser.onPageLoaded('http://127.0.0.1:18123/lovelace/home');
    expect(browser.loadFailed.value, isFalse);
  });
}
