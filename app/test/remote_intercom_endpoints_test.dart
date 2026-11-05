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
import 'package:web_socket_channel/web_socket_channel.dart';

/// The intercom's routes on the remote server: the public identity, a call
/// and its signals relayed with the bearer and the real address, the audio
/// socket gated by intercomVerify and handed over whole, and the two
/// commands only the kiosk screen may run.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => HttpOverrides.global = null);

  late SettingsManager settings;
  late RemoteManager remote;
  late CommandRegistry commands;
  late int port;
  late List<(String, Map<String, Object?>)> executed;
  var verifyOk = true;

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
    verifyOk = true;
    for (final name in [
      'intercomIdentity',
      'intercomIncoming',
      'intercomSignal',
      'intercomAnswer',
      'intercomDecline',
      'intercomHangup',
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
    commands.register(
      Command(
        name: 'intercomVerify',
        description: 'stub',
        handler: (p) async {
          executed.add(('intercomVerify', p));
          return verifyOk
              ? const CommandResult.ok()
              : const CommandResult.fail('refused');
        },
      ),
    );
    commands.register(
      Command(
        name: 'intercomAttachSocket',
        description: 'stub',
        handler: (p) async {
          executed.add(('intercomAttachSocket', p));
          final ch = p['channel'] as WebSocketChannel;
          ch.stream.listen((raw) => ch.sink.add(raw));
          return const CommandResult.ok();
        },
      ),
    );
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    remote = RemoteManager(bus, commands, log, settings);
    await remote.init();
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

  test(
    'encrypted intercom refuses legacy plaintext calls without changing admin',
    () async {
      // This test exercises the route gate, not native certificate loading.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ks.intercom.tls', true);
      final (identity, _) = await call('GET', '/api/intercom/identity');
      expect(identity, 200);
      final (incoming, _) = await call(
        'POST',
        '/api/intercom/call',
        body: {'call': 'c'},
      );
      expect(incoming, 426);
      final (signal, _) = await call(
        'POST',
        '/api/intercom/call/c',
        body: {'action': 'answer'},
      );
      expect(signal, 426);
      final (audio, _) = await call('GET', '/api/intercom/audio/c');
      expect(audio, 426);
      expect(executed.where((e) => e.$1 == 'intercomIncoming'), isEmpty);
      expect(await login(), isNotEmpty);
      expect(settings.get(defs.remoteTls), false);
    },
  );

  test('identity is public and rate limited per client', () async {
    final (s1, b1) = await call('GET', '/api/intercom/identity');
    expect(s1, 200);
    expect(b1['from'], 'intercomIdentity');
    final (s2, _) = await call('GET', '/api/intercom/identity');
    expect(s2, 429);
  });

  test('a call is relayed with its bearer and the real address', () async {
    final (s, b) = await call(
      'POST',
      '/api/intercom/call',
      body: {
        'call': 'c1',
        'kind': 'call',
        'from': {'id': 'kitchen', 'address': '10.0.0.1'},
      },
      token: 'tok-1',
    );
    expect(s, 200);
    expect(b['call'], 'c1');
    final (_, p) = executed.firstWhere((e) => e.$1 == 'intercomIncoming');
    expect(p['call'], 'c1');
    expect(p['token'], 'tok-1');
    expect(p['address'], '127.0.0.1');
    // The manager's answer code comes through.
    executed.clear();
  });

  test('a signal names its call from the path', () async {
    final (s, _) = await call(
      'POST',
      '/api/intercom/call/c9',
      body: {'action': 'answer'},
      token: 'tok-2',
    );
    expect(s, 200);
    final (_, p) = executed.firstWhere((e) => e.$1 == 'intercomSignal');
    expect(p['call'], 'c9');
    expect(p['action'], 'answer');
    expect(p['token'], 'tok-2');
  });

  test('the audio socket is refused without a good token', () async {
    verifyOk = false;
    final (s, _) = await call('GET', '/api/intercom/audio/c1?token=bad');
    expect(s, 403);
    final (_, p) = executed.firstWhere((e) => e.$1 == 'intercomVerify');
    expect(p['call'], 'c1');
    expect(p['token'], 'bad');
  });

  test(
    'the audio socket is handed over whole, binary frames and all',
    () async {
      final ws = await WebSocket.connect(
        'ws://127.0.0.1:$port/api/intercom/audio/c1?token=good',
      );
      final echoes = <Object?>[];
      final done = ws.listen(echoes.add);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final (_, p) = executed.firstWhere((e) => e.$1 == 'intercomAttachSocket');
      expect(p['call'], 'c1');
      expect(p['channel'], isA<WebSocketChannel>());
      ws.add([1, 2, 3, 4]);
      ws.add('{"type":"talk","on":true}');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(echoes, hasLength(2));
      expect(echoes.first, [1, 2, 3, 4]);
      expect(echoes.last, '{"type":"talk","on":true}');
      await done.cancel();
      await ws.close();
    },
  );

  test('answering and declining are refused over the wire', () async {
    final token = await login();
    for (final name in [
      'intercomAnswer',
      'intercomDecline',
      'intercomVideoCall',
      'intercomSwitchCamera',
      'intercomCamera',
    ]) {
      final (s, _) = await call('POST', '/api/commands/$name', token: token);
      expect(s, 403, reason: name);
    }
    final (s, _) = await call(
      'POST',
      '/api/commands/intercomHangup',
      token: token,
    );
    expect(s, 200);
  });
}
