import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/ha_http_overrides.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #216: with "Ignore SSL errors" enabled, dart:io requests (wake-word
/// model downloads, the sound relay) still failed certificate verification
/// whenever the URL named a host other than the configured HA host, e.g. the
/// old IP the dashboard still loads from after the HA URL moved to a domain.
/// The dart-side policy must agree with the WebView, which proceeds on any
/// SSL error under that setting.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<HaHttpOverrides> build(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    return HaHttpOverrides(settings);
  }

  setUp(() => HaHttpOverrides.sawSelfSigned = false);

  test('configured HA host is exempt and flags sawSelfSigned', () async {
    final overrides = await build({
      'ks.ha.url': 'https://ha.example.com:8123',
    });
    expect(overrides.allowBadCertificate('ha.example.com'), isTrue);
    expect(HaHttpOverrides.sawSelfSigned, isTrue);
  });

  test('other hosts still verify by default', () async {
    final overrides = await build({
      'ks.ha.url': 'https://ha.example.com:8123',
    });
    expect(overrides.allowBadCertificate('192.168.1.50'), isFalse);
    expect(HaHttpOverrides.sawSelfSigned, isFalse);
  });

  test('Ignore SSL errors accepts any host, like the WebView', () async {
    final overrides = await build({
      'ks.ha.url': 'https://ha.example.com:8123',
      'ks.browser.ignore_ssl_errors': true,
    });
    expect(overrides.allowBadCertificate('192.168.1.50'), isTrue);
    // The blanket opt-in is not the same as having seen a self-signed
    // certificate on the configured HA host.
    expect(HaHttpOverrides.sawSelfSigned, isFalse);
  });

  test('Immich host is exempt without the blanket opt-in', () async {
    final overrides = await build({
      'ks.ha.url': 'https://ha.example.com:8123',
      'ks.screensaver.immich_url': 'https://immich.local:2283',
    });
    expect(overrides.allowBadCertificate('immich.local'), isTrue);
  });
}
