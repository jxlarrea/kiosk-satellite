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

/// The remote admin server's lifecycle, after a report of it staying down
/// once "Remote management" had been switched off and on again.
///
/// The silent-failure case below is the confirmed one: enabled with no admin
/// password meant no server, no log line and no notice, so the switch read
/// "on" and nothing served. The off-and-on case is a plain regression guard —
/// it does NOT reproduce a wedge, and no test here has shown one; _stop()
/// releasing the server before a forced close is hardening, not a proven fix.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The binding stubs every HttpClient; this test talks to a real loopback
  // server of its own.
  setUpAll(() => HttpOverrides.global = null);

  late SettingsManager settings;
  late RemoteManager remote;
  late int port;

  setUp(() async {
    // A free port, released again so the manager can claim it.
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    port = probe.port;
    await probe.close();

    SharedPreferences.setMockInitialValues({
      // Configured, so the setup-mode allowance is not what keeps it up.
      'ks.browser.start_url': 'http://ha.local:8123/lovelace/0',
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

  tearDown(() async => settings.set(defs.remoteEnabled, false));

  Future<bool> listening() async {
    try {
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The settings listener drives the server, and it is asynchronous.
  Future<void> settle() async {
    for (var i = 0; i < 40; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  test('it comes back after being turned off and on again', () async {
    expect(await listening(), isTrue, reason: 'server should start');
    expect(remote.stoppedReason.value, isNull);

    // A client mid-request, exactly what disabling from the remote admin
    // leaves behind: the connection asking for the shutdown is still open.
    final held = await Socket.connect(InternetAddress.loopbackIPv4, port);
    held.write('GET /api/info HTTP/1.1\r\nHost: localhost\r\n\r\n');
    await held.flush();

    await settings.set(defs.remoteEnabled, false);
    await settle();
    expect(await listening(), isFalse, reason: 'server should stop');

    held.destroy();

    // The step the report says failed on the device.
    await settings.set(defs.remoteEnabled, true);
    await settle();
    expect(
      await listening(),
      isTrue,
      reason: 'turning it back on must serve again',
    );
    expect(remote.stoppedReason.value, isNull);
  });

  test('turning it off leaves the admin password alone', () async {
    // The reported sequence: the server was serving, the switch went off,
    // and turning it back on did nothing. That only happens if the password
    // went with it, so this pins the password across the whole round trip.
    expect(await listening(), isTrue);
    expect(settings.get(defs.remotePassword), 'secret');

    await settings.set(defs.remoteEnabled, false);
    await settle();
    expect(
      settings.get(defs.remotePassword),
      'secret',
      reason: 'disabling must not clear the password',
    );

    await settings.set(defs.remoteEnabled, true);
    await settle();
    expect(settings.get(defs.remotePassword), 'secret');
    expect(await listening(), isTrue, reason: 'and it serves again');
  });

  test('it says why it is not running instead of failing silently', () async {
    // Enabled with no password is the case that produced no log line, no
    // notice, and a switch that read "on".
    await settings.set(defs.remotePassword, '');
    await settle();
    expect(await listening(), isFalse);
    expect(remote.stoppedReason.value, contains('admin password'));

    await settings.set(defs.remotePassword, 'secret');
    await settle();
    expect(await listening(), isTrue);
    expect(remote.stoppedReason.value, isNull);
  });

  test('setting the onboarding password answers, and keeps serving', () async {
    // Setup mode: no start URL, no password, the server up for the wizard.
    await settings.set(defs.remoteEnabled, false);
    await settle();
    SharedPreferences.setMockInitialValues({'ks.remote.port': port});
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    remote = RemoteManager(bus, commands, log, settings);
    await remote.init();
    await settle();
    expect(await listening(), isTrue);

    // The first page shows the service's grants before any password
    // exists: the two setup-only endpoints answer, without a token.
    Future<int> get(String path, {String? bearer}) async {
      final c = HttpClient();
      final r = await c.getUrl(Uri.parse('http://127.0.0.1:$port/$path'));
      if (bearer != null) r.headers.set('Authorization', 'Bearer $bearer');
      final out = await r.close();
      await out.drain<void>();
      c.close();
      return out.statusCode;
    }

    expect(await get('api/setup/grants'), 200);

    // The wizard's first step, over the wire. Setting the password used to
    // restart the server under this very request, so the reply was lost
    // and the next press was refused as "setup already done".
    final client = HttpClient();
    final req = await client.postUrl(
      Uri.parse('http://127.0.0.1:$port/api/setup/password'),
    );
    req.headers.contentType = ContentType.json;
    req.write('{"password":"letmein"}');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    client.close();
    expect(res.statusCode, 200);
    expect(body, contains('token'));
    expect(settings.get(defs.remotePassword), 'letmein');
    await settle();
    expect(await listening(), isTrue);

    // Changing it from the wizard's Welcome step after a Back: refused
    // without the session, done with it.
    final token = (jsonDecode(body) as Map)['token'] as String;
    Future<int> change(String? bearer) async {
      final c = HttpClient();
      final r = await c.postUrl(
        Uri.parse('http://127.0.0.1:$port/api/setup/password'),
      );
      r.headers.contentType = ContentType.json;
      if (bearer != null) r.headers.set('Authorization', 'Bearer $bearer');
      r.write('{"password":"changed1"}');
      final out = await r.close();
      await out.drain<void>();
      c.close();
      return out.statusCode;
    }

    expect(await change(null), 403);
    expect(settings.get(defs.remotePassword), 'letmein');
    // With a password in place the window is closed: the page logs in and
    // uses the gated commands like everything else.
    expect(await get('api/setup/grants'), 403);
    expect(await change(token), 200);
    expect(settings.get(defs.remotePassword), 'changed1');
  });
}
