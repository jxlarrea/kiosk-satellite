import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/browser_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #216, the underlying misconfiguration: the dashboard picker stores
/// an absolute start URL built from the HA base URL at pick time, so a later
/// base URL change (IP moved to a domain) left the WebView loading the
/// dashboard from the old origin forever. The browser now rewrites the start
/// URL's origin whenever the base URL changes off it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BrowserManager browser;
  late SettingsManager settings;

  Future<void> build(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    browser = BrowserManager(bus, commands, log, settings);
    await browser.init();
  }

  tearDown(() async => browser.dispose());

  test('start URL follows the base URL off the old origin', () async {
    await build({
      'ks.ha.url': 'https://192.168.1.50:8123',
      'ks.browser.start_url': 'https://192.168.1.50:8123/lovelace/home?kiosk',
    });
    await settings.set(defs.haUrl, 'https://ha.example.com:8123');
    await pumpEventQueue();
    expect(
      settings.get(defs.startUrl),
      'https://ha.example.com:8123/lovelace/home?kiosk',
    );
  });

  test('a start URL on some other host stays put', () async {
    await build({
      'ks.ha.url': 'https://192.168.1.50:8123',
      'ks.browser.start_url': 'https://grafana.local:3000/d/kiosk',
    });
    await settings.set(defs.haUrl, 'https://ha.example.com:8123');
    await pumpEventQueue();
    expect(settings.get(defs.startUrl), 'https://grafana.local:3000/d/kiosk');
  });

  test('first-time setup (no previous base URL) rewrites nothing', () async {
    await build({
      'ks.browser.start_url': 'https://192.168.1.50:8123/lovelace/home',
    });
    await settings.set(defs.haUrl, 'https://ha.example.com:8123');
    await pumpEventQueue();
    expect(
      settings.get(defs.startUrl),
      'https://192.168.1.50:8123/lovelace/home',
    );
  });

  test('a same-origin reformat (trailing slash) rewrites nothing', () async {
    await build({
      'ks.ha.url': 'https://ha.example.com:8123',
      'ks.browser.start_url': 'https://ha.example.com:8123/lovelace/home',
    });
    await settings.set(defs.haUrl, 'https://ha.example.com:8123/');
    await pumpEventQueue();
    expect(
      settings.get(defs.startUrl),
      'https://ha.example.com:8123/lovelace/home',
    );
  });
}
