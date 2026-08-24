import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/remote/remote_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The hand-typed Wi-Fi MAC address (issue #300): what the field accepts,
/// the form it stores, and how a refusal reaches the remote admin page.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('normalizeMacAddress', () {
    test('accepts the usual spellings and stores one form', () {
      for (final raw in [
        '80:30:49:cd:d6:5f',
        '80-30-49-CD-D6-5F',
        '8030.49cd.d65f',
        '803049CDD65F',
        '  80:30:49:CD:D6:5F  ',
      ]) {
        expect(defs.normalizeMacAddress(raw), '80:30:49:CD:D6:5F', reason: raw);
      }
    });

    test('a locally-administered address passes', () {
      // Randomized per-network addresses are locally administered and are
      // exactly what the router sees.
      expect(
        defs.normalizeMacAddress('DA:1B:2C:3D:4E:5F'),
        'DA:1B:2C:3D:4E:5F',
      );
    });

    test('refuses what could never be an interface address', () {
      for (final raw in [
        '',
        'not a mac',
        '80:30:49:CD:D6',
        '80:30:49:CD:D6:5F:00',
        'G0:30:49:CD:D6:5F',
        '00:00:00:00:00:00',
        '02:00:00:00:00:00',
        '01:00:5E:00:00:01',
        'FF:FF:FF:FF:FF:FF',
      ]) {
        expect(defs.normalizeMacAddress(raw), isNull, reason: raw);
      }
    });
  });

  group('the setting', () {
    Future<SettingsManager> settingsWith(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      final bus = EventBus();
      final log = Logger();
      final settings = SettingsManager(bus, CommandRegistry(log), log);
      await settings.init();
      return settings;
    }

    test('empty clears, and is not an error', () {
      expect(defs.validateMacAddress(''), isNull);
      expect(defs.validateMacAddress('   '), isNull);
    });

    test('a write stores the canonical form', () async {
      final settings = await settingsWith({});
      expect(
        await settings.setFromJson(
          defs.esphomeMacOverride.key,
          '80-30-49-cd-d6-5f',
        ),
        isTrue,
      );
      expect(settings.get(defs.esphomeMacOverride), '80:30:49:CD:D6:5F');
    });

    test('a write that is not an address is refused with a reason', () async {
      final settings = await settingsWith({});
      expect(
        await settings.setFromJson(defs.esphomeMacOverride.key, 'kitchen'),
        isFalse,
      );
      expect(settings.get(defs.esphomeMacOverride), isEmpty);
      expect(defs.validateMacAddress('kitchen'), contains('AA:BB:CC:DD:EE:FF'));
    });
  });

  group('the remote API', () {
    setUpAll(() => HttpOverrides.global = null);

    late SettingsManager settings;
    late RemoteManager remote;
    late int port;

    setUp(() async {
      final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      port = probe.port;
      await probe.close();
      SharedPreferences.setMockInitialValues({
        'ks.remote.enabled': true,
        'ks.remote.password': 'secret',
        'ks.remote.port': port,
      });
      final bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      remote = RemoteManager(bus, commands, log, settings);
      await remote.init();
    });

    tearDown(() async {
      await settings.set(defs.remoteEnabled, false);
      await remote.dispose();
    });

    Future<Map> call(
      String method,
      String path,
      Object body, {
      String? token,
    }) async {
      final client = HttpClient();
      final request = await client.openUrl(
        method,
        Uri.parse('http://127.0.0.1:$port$path'),
      );
      if (token != null) request.headers.set('Authorization', 'Bearer $token');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close();
      return jsonDecode(await utf8.decodeStream(response)) as Map;
    }

    test('a refused value comes back with the validator\'s words', () async {
      final login = await call('POST', '/api/login', {'password': 'secret'});
      final token = login['token'] as String;
      final out = await call('PATCH', '/api/settings', {
        defs.esphomeMacOverride.key: 'kitchen',
      }, token: token);
      expect(out['ok'], isFalse);
      expect(out['rejected'], [defs.esphomeMacOverride.key]);
      expect(
        (out['errors'] as Map)[defs.esphomeMacOverride.key],
        contains('AA:BB:CC:DD:EE:FF'),
      );
      expect(settings.get(defs.esphomeMacOverride), isEmpty);
    });
  });
}
