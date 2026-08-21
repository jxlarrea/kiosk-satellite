import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/browser_manager.dart';
import 'package:kiosk_satellite/managers/browser/ha_session_script.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sharing the dashboard's Home Assistant session with the external
/// WebViews (discussion #225): which origins qualify, and the seed script
/// they get.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const session =
      '{"access_token":"abc","refresh_token":"ref","clientId":'
      '"http://127.0.0.1:18123/","expires":1,"hassUrl":'
      '"http://127.0.0.1:18123"}';

  late BrowserManager browser;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({
      'ks.browser.start_url': 'http://127.0.0.1:18123/lovelace/home',
      'ks.ha.url': 'http://192.168.1.10:8123',
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    browser = BrowserManager(bus, commands, log, settings);
    await browser.init();
  }

  group('isHomeAssistantOrigin', () {
    test('the base URL origin qualifies, proxied dashboard or not', () async {
      await build();
      // The dashboard runs on loopback (secure context proxy), so the real
      // host is not the dashboard origin — but it is still this HA.
      expect(
        browser.isDashboardOrigin(Uri.parse('http://192.168.1.10:8123/x')),
        isFalse,
      );
      expect(
        browser.isHomeAssistantOrigin(Uri.parse('http://192.168.1.10:8123/x')),
        isTrue,
      );
      expect(
        browser.isHomeAssistantOrigin(Uri.parse('http://127.0.0.1:18123/x')),
        isTrue,
      );
    });

    test('anywhere else is not', () async {
      await build();
      expect(
        browser.isHomeAssistantOrigin(Uri.parse('https://my.sonnen.de/')),
        isFalse,
      );
      // Same host, another port: another server.
      expect(
        browser.isHomeAssistantOrigin(Uri.parse('http://192.168.1.10:8095/')),
        isFalse,
      );
      // Same host over https: not the origin the session belongs to.
      expect(
        browser.isHomeAssistantOrigin(Uri.parse('https://192.168.1.10:8123/')),
        isFalse,
      );
    });
  });

  group('buildHaSessionScript', () {
    test('carries the session over with hassUrl on the target origin', () {
      final script = buildHaSessionScript(
        tokens: session,
        url: 'http://192.168.1.10:8123/lovelace/clock',
      );
      expect(script, isNotNull);
      // The seeded value is a JSON string inside the script; recover it.
      final start =
          script!.indexOf('"hassTokens", ') + '"hassTokens", '.length;
      final end = script.indexOf(');', start);
      final seeded =
          jsonDecode(jsonDecode(script.substring(start, end)) as String)
              as Map<String, dynamic>;
      expect(seeded['access_token'], 'abc');
      expect(seeded['refresh_token'], 'ref');
      // The client the refresh token was minted for is preserved: Home
      // Assistant matches it on refresh.
      expect(seeded['clientId'], 'http://127.0.0.1:18123/');
      // The address the frontend will talk to is the page's own origin,
      // never the loopback proxy the dashboard uses.
      expect(seeded['hassUrl'], 'http://192.168.1.10:8123');
    });

    test('never overwrites a session the page already has', () {
      final script = buildHaSessionScript(
        tokens: session,
        url: 'http://192.168.1.10:8123/',
      );
      expect(script, contains('if (!localStorage.getItem("hassTokens"))'));
    });

    test('nothing to share, nothing injected', () {
      expect(buildHaSessionScript(tokens: null, url: 'http://a:8123/'), isNull);
      expect(buildHaSessionScript(tokens: '   ', url: 'http://a:8123/'), isNull);
      expect(
        buildHaSessionScript(tokens: 'not json', url: 'http://a:8123/'),
        isNull,
      );
      // A stored value without an access token signs nobody in.
      expect(
        buildHaSessionScript(tokens: '{"expires":1}', url: 'http://a:8123/'),
        isNull,
      );
    });
  });

  group('buildHaAutoLoginScript', () {
    test('seeds a session built from the long-lived token', () {
      final script = buildHaAutoLoginScript(token: '  llat-token  ');
      expect(script, isNotNull);
      // The token lands JSON-encoded, trimmed of the paste's whitespace.
      expect(script, contains('access_token: "llat-token"'));
      // The origin fields come from the page itself, so the seed stays
      // correct under the loopback proxy and the frontend's own-origin
      // check passes.
      expect(
        script,
        contains('hassUrl: location.protocol + "//" + location.host'),
      );
      expect(
        script,
        contains('clientId: location.protocol + "//" + location.host + "/"'),
      );
      // Far-future expiry: the frontend must never try the refresh flow
      // it has no refresh token for.
      expect(script, contains('expires: Date.now() + 315360000000'));
    });

    test('never overwrites a session the page already has', () {
      final script = buildHaAutoLoginScript(token: 'llat');
      expect(script, contains('if (!localStorage.getItem("hassTokens"))'));
    });

    test('no token, nothing injected', () {
      expect(buildHaAutoLoginScript(token: null), isNull);
      expect(buildHaAutoLoginScript(token: '   '), isNull);
    });
  });
}
