import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/sendspin/music_assistant_api.dart';
import 'package:kiosk_satellite/managers/sendspin/plugin_ma_socket.dart';

/// The Music Assistant connection plugins share: the app signs in, keeps
/// the admin surface off it and filters the events every client hears.
void main() {
  late HttpServer server;
  late List<WebSocket> served;
  late List<Map> received;
  late List<Map> auths;
  late MaPluginSocket socket;
  late List<(String, String, Map<String, Object?>)> emitted;
  late String token;

  setUp(() async {
    served = [];
    received = [];
    auths = [];
    emitted = [];
    token = 'good';
    // A Music Assistant that introduces itself, signs in and runs a few
    // commands.
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      served.add(ws);
      ws.add(
        jsonEncode({
          'server_id': 'abc123',
          'server_version': '2.10.2',
          'schema_version': 32,
          'name': 'Home',
        }),
      );
      ws.listen((raw) {
        final msg = jsonDecode(raw as String) as Map;
        final id = msg['message_id'];
        void result(Object? value) =>
            ws.add(jsonEncode({'message_id': id, 'result': value}));
        void error(int code, String details) => ws.add(
          jsonEncode({
            'message_id': id,
            'error_code': code,
            'details': details,
          }),
        );
        if (msg['command'] == 'auth') {
          auths.add(msg['args'] as Map);
          if ((msg['args'] as Map)['token'] == 'good') {
            result({
              'authenticated': true,
              'user': {
                'username': 'kiosk',
                'preferences': {
                  'discover.rows': {
                    'hidden': ['library://folder/in_progress'],
                  },
                },
              },
            });
          } else {
            error(23, 'Invalid token');
          }
          return;
        }
        received.add(msg);
        switch (msg['command']) {
          case 'players/all':
            result([
              {'player_id': 'p1', 'name': 'Kitchen'},
            ]);
          case 'music/library/remove_item':
            error(22, 'Insufficient permissions');
          case 'music/tracks/library_items':
            // A large list arrives in slices.
            ws.add(
              jsonEncode({
                'message_id': id,
                'partial': true,
                'result': [1, 2],
              }),
            );
            result([3]);
          case 'music/search':
            result('x' * 600000);
          case 'player_queues/slow':
            break;
        }
      });
    });
    socket = MaPluginSocket(
      baseUrl: () => 'http://127.0.0.1:${server.port}',
      token: () => token,
      log: Logger(),
      idleClose: const Duration(milliseconds: 200),
      callTimeout: const Duration(seconds: 2),
    )..emit = (owner, key, payload) => emitted.add((owner, key, payload));
  });

  tearDown(() async {
    socket.dispose();
    await server.close(force: true);
  });

  Future<void> settle([int ms = 100]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  /// Music Assistant pushes an event at the newest client.
  void push(String event, String objectId, Object? data) => served.last.add(
    jsonEncode({'event': event, 'object_id': objectId, 'data': data}),
  );

  test('signs in with the locale it is given and none by default', () async {
    await socket.call('a', 'players/all', const {});
    expect(auths.single.containsKey('locale'), isFalse);

    var language = 'de';
    final localized = MaPluginSocket(
      baseUrl: () => 'http://127.0.0.1:${server.port}',
      token: () => token,
      log: Logger(),
      callTimeout: const Duration(seconds: 2),
      locale: () => language,
    );
    addTearDown(localized.dispose);
    await localized.call('a', 'players/all', const {});
    expect(auths.last, {'token': 'good', 'locale': 'de'});

    // A language change reaches the server on the next sign-in.
    language = 'uk_UA';
    localized.restart();
    await localized.call('a', 'players/all', const {});
    expect(auths.last['locale'], 'uk_UA');
  });

  test('app languages map to the locales Music Assistant ships', () {
    expect(musicAssistantLocale('en'), 'en');
    expect(musicAssistantLocale('de'), 'de');
    expect(musicAssistantLocale('ru'), 'ru_RU');
    expect(musicAssistantLocale('uk'), 'uk_UA');
    expect(musicAssistantLocale('zh-CN'), 'zh_CN');
  });

  test(
    'a call returns the result, joins a sliced one and keeps errors',
    () async {
      expect(await socket.call('a', 'players/all', const {}), {
        'ok': true,
        'result': [
          {'player_id': 'p1', 'name': 'Kitchen'},
        ],
      });
      expect(socket.serverInfo['server_id'], 'abc123');
      // The user's preferences come with the sign-in, for the library.
      expect(socket.userPreferences['discover.rows'], {
        'hidden': ['library://folder/in_progress'],
      });
      expect(
        await socket.call('a', 'music/tracks/library_items', {'limit': 3}),
        {
          'ok': true,
          'result': [1, 2, 3],
        },
      );
      expect((received.last['args'] as Map)['limit'], 3);
      expect(await socket.call('a', 'music/library/remove_item', const {}), {
        'ok': false,
        'error': {'code': '22', 'message': 'Insufficient permissions'},
      });
      expect(
        ((await socket.call('a', 'music/search', const {}))['error']
            as Map)['code'],
        'too_large',
      );
    },
  );

  test('the admin surface never reaches the server', () async {
    for (final command in [
      'auth',
      'auth/token/create',
      'auth/users',
      'config/providers/get',
      'config/core/save',
      'players/remove',
      'players/create_group_player',
      'logging/get',
      'tasks/list',
      'sendspin/pair_web_player',
      'Players/all',
      '../players/all',
    ]) {
      final result = await socket.call('a', command, const {});
      expect((result['error'] as Map)['code'], 'not_allowed', reason: command);
    }
    expect(received, isEmpty);
    expect(socket.connected, false);
    for (final command in [
      'info',
      'providers',
      'players/cmd/volume_set',
      'player_queues/play_media',
      'music/favorites/add_item',
      'metadata/get_track_lyrics',
    ]) {
      expect(MaPluginSocket.allowedCommand(command), true, reason: command);
    }
  });

  test('a wrong token is reported as such', () async {
    token = 'bad';
    final result = await socket.call('a', 'players/all', const {});
    expect((result['error'] as Map)['code'], 'auth_invalid');
    expect(received, isEmpty);
  });

  test('without an address or token nothing connects', () async {
    token = '';
    final result = await socket.call('a', 'players/all', const {});
    expect((result['error'] as Map)['code'], 'not_configured');
    expect(served, isEmpty);
  });

  test('a subscription hears only the events and object it names', () async {
    expect(
      await socket.subscribe('a', 'queue', {
        'events': ['queue_updated'],
        'objectId': 'q1',
      }),
      {'ok': true},
    );
    expect(
      await socket.subscribe('b', 'players', {
        'events': ['player_updated', 'player_added'],
      }),
      {'ok': true},
    );
    push('queue_updated', 'q1', {'shuffle': true});
    push('queue_updated', 'q2', {'shuffle': false});
    push('player_updated', 'p1', {'volume_level': 20});
    push('media_item_added', 'x', null);
    await settle();
    expect(emitted.map((e) => (e.$1, e.$2)), [
      ('a', 'queue'),
      ('b', 'players'),
    ]);
    expect(emitted.first.$3, {
      'type': 'event',
      'event': 'queue_updated',
      'objectId': 'q1',
      'data': {'shuffle': true},
    });
    expect(emitted.last.$3, {
      'type': 'event',
      'event': 'player_updated',
      'objectId': 'p1',
      'data': {'volume_level': 20},
    });
    emitted.clear();
    socket.unsubscribe('a', 'queue');
    push('queue_updated', 'q1', {'shuffle': false});
    push('player_updated', 'p1', {'x' * 70000: 1});
    await settle();
    expect(emitted.single.$2, 'players');
    expect(emitted.single.$3, {
      'type': 'too_large',
      'event': 'player_updated',
      'objectId': 'p1',
    });
  });

  test('a filter must name events, and a plugin holds at most 16', () async {
    for (final filter in [
      <String, Object?>{},
      {'events': <String>[]},
      {
        'events': ['Queue Updated'],
      },
      {
        'events': ['queue_updated'],
        'objectId': 4,
      },
      {
        'events': ['queue_updated'],
        'other': true,
      },
      {'events': List.filled(17, 'queue_updated')},
    ]) {
      final result = await socket.subscribe('a', 'k', filter);
      expect((result['error'] as Map)['code'], 'invalid_message');
    }
    for (var i = 0; i < 16; i++) {
      expect(
        (await socket.subscribe('a', 's$i', {
          'events': ['player_updated'],
        }))['ok'],
        true,
      );
    }
    final full = await socket.subscribe('a', 'one_more', {
      'events': ['player_updated'],
    });
    expect((full['error'] as Map)['code'], 'too_many');
    final taken = await socket.subscribe('a', 's0', {
      'events': ['player_updated'],
    });
    expect((taken['error'] as Map)['code'], 'in_use');
    expect(
      (await socket.subscribe('b', 's0', {
        'events': ['player_updated'],
      }))['ok'],
      true,
    );
  });

  test("a session's end releases its subscriptions and calls", () async {
    await socket.subscribe('a', 'k', {
      'events': ['player_updated'],
    });
    await socket.subscribe('b', 'k', {
      'events': ['player_updated'],
    });
    final pending = socket.call('a', 'player_queues/slow', const {});
    await settle();
    socket.release('a');
    expect(((await pending)['error'] as Map)['code'], 'session_ended');
    push('player_updated', 'p1', null);
    await settle();
    expect(emitted.map((e) => e.$1), ['b']);
  });

  test('a lost connection comes back and says so', () async {
    await socket.subscribe('a', 'k', {
      'events': ['player_updated'],
    });
    await served.single.close();
    await settle(1500);
    expect(emitted.map((e) => e.$3['type']), ['disconnected', 'reconnected']);
    expect(served, hasLength(2));
    emitted.clear();
    push('player_updated', 'p1', null);
    await settle();
    expect(emitted.single.$3['type'], 'event');
  });

  test('a server that closes during sign-in is tried again', () async {
    await socket.subscribe('a', 'k', {
      'events': ['player_updated'],
    });
    // The next connection is dropped before it answers the sign-in.
    final port = server.port;
    await server.close(force: true);
    var refused = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    server.listen((request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      served.add(ws);
      if (refused++ == 0) {
        await ws.close();
        return;
      }
      ws.listen((raw) {
        final msg = jsonDecode(raw as String) as Map;
        ws.add(jsonEncode({'message_id': msg['message_id'], 'result': true}));
      });
    });
    // The first connection outlived its server. Dropping it starts the
    // retries.
    await served.first.close();
    await settle(4000);
    expect(refused, 2);
    expect(emitted.map((e) => e.$3['type']), ['disconnected', 'reconnected']);
  });

  test('the connection closes when idle and opens on the next call', () async {
    await socket.call('a', 'players/all', const {});
    expect(socket.connected, true);
    await settle(400);
    expect(socket.connected, false);
    expect((await socket.call('a', 'players/all', const {}))['ok'], true);
    expect(served, hasLength(2));
  });

  test('a changed address or token starts over', () async {
    await socket.subscribe('a', 'k', {
      'events': ['player_updated'],
    });
    socket.restart();
    await settle(300);
    expect(served, hasLength(2));
    expect(emitted.map((e) => e.$3['type']), ['disconnected', 'reconnected']);
  });
}
