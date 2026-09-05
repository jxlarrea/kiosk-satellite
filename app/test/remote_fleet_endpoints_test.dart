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

/// The fleet endpoints on the remote server: the public three a kiosk with
/// no token here may call, the fleet token a leader holds (good only for
/// the fleet endpoints and the update commands, only while it names this
/// kiosk's leader) and the two commands the remote admin must never run
/// (accepting or declining is done on the kiosk).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => HttpOverrides.global = null);

  late SettingsManager settings;
  late RemoteManager remote;
  late CommandRegistry commands;
  late int port;
  late List<(String, Map<String, Object?>)> executed;

  setUp(() async {
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    port = probe.port;
    await probe.close();
    SharedPreferences.setMockInitialValues({
      'ks.browser.start_url': 'http://ha.local:8123/lovelace/0',
      'ks.remote.enabled': true,
      'ks.remote.password': 'secret',
      'ks.remote.port': port,
    });
    final bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    executed = [];
    // The fleet sync manager's commands, stubbed: this test is about the
    // server's routing and gate, not the manager.
    for (final name in [
      'fleetIdentity',
      'fleetInviteReceived',
      'fleetInvitePoll',
      'fleetFollowerStatus',
      'fleetApply',
      'fleetLeaderLeft',
      'fleetAccept',
      'fleetDecline',
      'getUpdateStatus',
      'getDeviceInfo',
      'getBrightness',
      'isScreenOn',
      'isScreensaverActive',
      'getCameraViewState',
    ]) {
      commands.register(
        Command(
          name: name,
          description: 'stub',
          handler: (p) async {
            executed.add((name, p));
            return CommandResult.ok({'from': name, ...p});
          },
        ),
      );
    }
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    remote = RemoteManager(bus, commands, log, settings);
    await remote.init();
    // The server starts off the settings listener.
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  });

  tearDown(() async {
    await settings.set(defs.remoteEnabled, false);
    await remote.dispose();
  });

  Future<(int, Map<String, Object?>)> call(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? token,
  }) async {
    final client = HttpClient();
    try {
      final req = await client.openUrl(
        method,
        Uri.parse('http://127.0.0.1:$port$path'),
      );
      if (token != null) req.headers.set('authorization', 'Bearer $token');
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(body));
      }
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      Object? decoded;
      try {
        decoded = jsonDecode(text);
      } catch (_) {
        decoded = {'raw': text};
      }
      return (
        res.statusCode,
        decoded is Map ? decoded.cast<String, Object?>() : {'raw': decoded},
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<String> login() async {
    final (_, body) = await call(
      'POST',
      '/api/login',
      body: {'password': 'secret'},
    );
    return body['token'] as String;
  }

  Future<String> fleetToken(String leader) async {
    final r = await commands.execute('issueFleetToken', {'leader': leader});
    return r.data as String;
  }

  test('identity and the invitation poll need no token', () async {
    final (s1, b1) = await call('GET', '/api/fleet/identity');
    expect(s1, 200);
    expect(b1['from'], 'fleetIdentity');
    final (s2, b2) = await call('GET', '/api/fleet/invite/abc123');
    expect(s2, 200);
    expect(b2['invite'], 'abc123');
  });

  test(
    'an invitation carries the address it came from and is rate limited',
    () async {
      final (s1, b1) = await call(
        'POST',
        '/api/fleet/invite',
        body: {
          'invite': 'n1',
          'leader': {'id': 'lead', 'port': 2324, 'address': '10.0.0.99'},
        },
      );
      expect(s1, 200);
      expect(b1['ok'], isTrue);
      final (_, params) = executed.singleWhere(
        (e) => e.$1 == 'fleetInviteReceived',
      );
      expect(params['address'], '127.0.0.1');
      expect(params['invite'], 'n1');
      final (s2, _) = await call(
        'POST',
        '/api/fleet/invite',
        body: {
          'invite': 'n2',
          'leader': {'id': 'lead'},
        },
      );
      expect(s2, 429);
    },
  );

  test('the follower endpoints need a token', () async {
    expect((await call('GET', '/api/fleet/status')).$1, 401);
    expect((await call('POST', '/api/fleet/apply', body: {})).$1, 401);
    expect((await call('POST', '/api/fleet/leave')).$1, 401);
  });

  test("a fleet token works only while it names this kiosk's leader", () async {
    final token = await fleetToken('lead');
    // Following nobody: refused.
    expect((await call('GET', '/api/fleet/status', token: token)).$1, 403);
    await settings.set(
      defs.fleetLeaderInfo,
      jsonEncode({'id': 'lead', 'name': 'Living Room'}),
    );
    final (s, b) = await call('GET', '/api/fleet/status', token: token);
    expect(s, 200);
    expect(b['from'], 'fleetFollowerStatus');
    // Another leader's token: refused.
    final other = await fleetToken('someone');
    expect((await call('GET', '/api/fleet/status', token: other)).$1, 403);
    // Leaving revokes it.
    await settings.set(defs.fleetLeaderInfo, '');
    expect((await call('GET', '/api/fleet/status', token: token)).$1, 403);
  });

  test(
    'a fleet token opens the fleet endpoints and the update commands, nothing else',
    () async {
      await settings.set(
        defs.fleetLeaderInfo,
        jsonEncode({'id': 'lead', 'name': 'Living Room'}),
      );
      final token = await fleetToken('lead');
      final (s1, b1) = await call(
        'POST',
        '/api/fleet/apply',
        body: {'revision': '3', 'version': '1', 'settings': {}},
        token: token,
      );
      expect(s1, 200);
      expect(b1['ok'], isTrue);
      expect((b1['data'] as Map)['revision'], '3');
      final (s2, _) = await call(
        'POST',
        '/api/commands/getUpdateStatus',
        body: {},
        token: token,
      );
      expect(s2, 200);
      expect((await call('GET', '/api/settings', token: token)).$1, 403);
      expect((await call('GET', '/api/info', token: token)).$1, 403);
      expect(
        (await call(
          'POST',
          '/api/commands/getDeviceInfo',
          body: {},
          token: token,
        )).$1,
        403,
      );
      final (s3, _) = await call('POST', '/api/fleet/leave', token: token);
      expect(s3, 200);
      expect(executed.any((e) => e.$1 == 'fleetLeaderLeft'), isTrue);
    },
  );

  test('an admin token still opens everything', () async {
    final token = await login();
    expect((await call('GET', '/api/settings', token: token)).$1, 200);
    final (s, _) = await call('GET', '/api/fleet/status', token: token);
    expect(s, 200);
  });

  test(
    'accepting and declining are answered on the kiosk, never here',
    () async {
      final token = await login();
      for (final name in ['fleetAccept', 'fleetDecline']) {
        final (s, b) = await call(
          'POST',
          '/api/commands/$name',
          body: {},
          token: token,
        );
        expect(s, 403, reason: name);
        expect(b['error'], contains('kiosk'));
      }
      expect(executed.where((e) => e.$1 == 'fleetAccept'), isEmpty);
    },
  );
}
