import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/browser_manager.dart';
import 'package:kiosk_satellite/managers/browser/dashboard_state.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'URLs preserve origin and encoded paths while removing sensitive components',
    () {
      expect(
        DashboardState.url(
          'https://user:password@ha.test:8123/a%2Fb/%E2%98%83?auth=secret#token',
        ),
        'https://ha.test:8123/a%2Fb/%E2%98%83',
      );
      expect(
        DashboardState.url('http://[::1]:18123/lovelace/main?x=1'),
        'http://[::1]:18123/lovelace/main',
      );
      for (final value in [
        null,
        true,
        '',
        'relative/path',
        '//ha.test/path',
        'about:blank',
        'javascript:alert(1)',
        'file:///private',
        'https://ha.test:bad/',
        'https://ha.test:99999/',
        'x' * 8193,
      ]) {
        expect(DashboardState.url(value), isNull, reason: '$value');
      }
      expect(
        DashboardState.fromUrls(
          homeAssistantUrl: '',
          startUrl: '',
          currentUrl: 'https://ha.test',
        )['currentPath'],
        '/',
      );
    },
  );

  test(
    'dashboard read follows saved settings and main WebView navigation without changing them',
    () async {
      SharedPreferences.setMockInitialValues({
        'ks.ha.url': 'https://user:secret@ha.test:8123?token=hidden',
        'ks.browser.start_url': 'https://ha.test:8123/dashboard/main?kiosk=1',
      });
      final bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      final settings = SettingsManager(bus, commands, log);
      await settings.init();
      final savedBase = settings.get(defs.haUrl);
      final savedStart = settings.get(defs.startUrl);
      final browser = BrowserManager(bus, commands, log, settings);
      await browser.init();
      addTearDown(() async {
        await browser.dispose();
        await bus.dispose();
      });
      Future<Map> read() async =>
          (await commands.execute('getDashboardState', {})).data as Map;
      expect(await read(), {
        'homeAssistantUrl': 'https://ha.test:8123',
        'startUrl': 'https://ha.test:8123/dashboard/main',
        'currentUrl': null,
        'currentPath': null,
      });
      browser.onPageLoaded('http://127.0.0.1:18123/dashboard/main?secret=one');
      browser.onUrlChanged('http://127.0.0.1:18123/dashboard/kitchen#secret');
      browser.showLinkOverlay('https://overlay.test/private');
      expect(
        (await read())['currentUrl'],
        'http://127.0.0.1:18123/dashboard/kitchen',
      );
      expect((await read())['currentPath'], '/dashboard/kitchen');
      expect(settings.get(defs.haUrl), savedBase);
      expect(settings.get(defs.startUrl), savedStart);
      await settings.set(defs.startUrl, 'https://other.test/panel?token=two');
      expect((await read())['startUrl'], 'https://other.test/panel');
      browser.onUrlChanged('about:blank');
      expect((await read())['currentUrl'], isNull);
      expect((await read())['currentPath'], isNull);
    },
  );
}
