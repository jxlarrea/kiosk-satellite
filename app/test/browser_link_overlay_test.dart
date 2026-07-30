import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/browser_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// External links over the dashboard (issue #86): the origin test that
/// decides main-WebView navigation vs the overlay, and the dismissible
/// overlay state the kiosk screen renders from.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CommandRegistry commands;
  late BrowserManager browser;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({
      'ks.browser.start_url': 'http://192.168.1.10:8123/lovelace/home',
    });
    final bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    browser = BrowserManager(bus, commands, log, settings);
    await browser.init();
  }

  group('isDashboardOrigin', () {
    test('the start URL origin is the dashboard', () async {
      await build();
      expect(
        browser.isDashboardOrigin(
          Uri.parse('http://192.168.1.10:8123/config/dashboard'),
        ),
        isTrue,
      );
    });

    test('the loaded page origin counts too (secure context proxy)',
        () async {
      await build();
      browser.onPageLoaded('http://127.0.0.1:18123/lovelace/home');
      expect(
        browser.isDashboardOrigin(Uri.parse('http://127.0.0.1:18123/other')),
        isTrue,
      );
      // The raw start origin stays recognized alongside the proxied one.
      expect(
        browser.isDashboardOrigin(Uri.parse('http://192.168.1.10:8123/x')),
        isTrue,
      );
    });

    test('other hosts, and the same host on another port, are external',
        () async {
      await build();
      expect(
        browser.isDashboardOrigin(Uri.parse('https://example.com/page')),
        isFalse,
      );
      expect(
        browser.isDashboardOrigin(Uri.parse('http://192.168.1.10:2323/')),
        isFalse,
      );
      expect(
        browser.isDashboardOrigin(Uri.parse('https://192.168.1.10:8123/')),
        isFalse,
      );
    });
  });

  group('overlay state', () {
    test('a link overlay is dismissible, a rotation overlay is not',
        () async {
      await build();
      browser.showLinkOverlay('https://example.com/doorbell');
      expect(browser.overlayUrl.value, 'https://example.com/doorbell');
      expect(browser.overlayDismissible.value, isTrue);

      await commands
          .execute('showOverlayPage', {'url': 'https://example.com/weather'});
      expect(browser.overlayUrl.value, 'https://example.com/weather');
      expect(browser.overlayDismissible.value, isFalse);
    });

    test('dismissal clears both, from every path', () async {
      await build();
      browser.showLinkOverlay('https://example.com/a');
      browser.dismissOverlay();
      expect(browser.overlayUrl.value, isNull);
      expect(browser.overlayDismissible.value, isFalse);

      browser.showLinkOverlay('https://example.com/b');
      await commands.execute('hideOverlayPage', const {});
      expect(browser.overlayUrl.value, isNull);
      expect(browser.overlayDismissible.value, isFalse);
    });
  });
}
