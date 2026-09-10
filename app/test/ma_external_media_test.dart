import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/sendspin/ma_remote_player.dart';

Map<String, Object?> _player({
  String state = 'playing',
  String title = 'Hey Jude',
}) => {
  'player_id': 'p1',
  'available': true,
  'playback_state': state,
  'active_source': 'spotify_connect',
  'current_media': {
    'uri': 'spotify_connect://audio_source/p1',
    'title': title,
    'artist': 'The Beatles',
    'album': 'The Beatles 1967-1970',
    'image_url': 'https://example.com/cover.jpg',
    'duration': 431,
  },
  'elapsed_time': 12,
  'volume_level': 35,
  'volume_muted': false,
  'source_list': [
    {
      'id': 'spotify_connect',
      'can_play_pause': true,
      'can_next_previous': true,
      'can_seek': false,
    },
  ],
};

Map<String, Object?> _queue() => {
  'queue_id': 'q1',
  'state': 'playing',
  'active': true,
  'elapsed_time': 42,
  'current_item': {'name': 'Queued track', 'duration': 200},
};

void main() {
  late MaRemotePlayer remote;
  late List<Map<String, Object?>?> emitted;

  setUp(() {
    emitted = [];
    remote = MaRemotePlayer(
      baseUrl: 'http://ma.local',
      token: 'test',
      playerId: 'p1',
      onSnapshot: emitted.add,
      log: Logger(),
    );
  });
  tearDown(() => remote.stop());

  void update(Map<String, Object?> player) =>
      remote.handleEvent('player_updated', 'p1', player);

  test('playing metadata appears without a queue and tracks player events', () {
    remote.publishQueue(null);
    update(_player());
    final snap = emitted.last!;
    expect(snap['title'], 'Hey Jude');
    expect(snap['artist'], 'The Beatles');
    expect(snap['album'], 'The Beatles 1967-1970');
    expect(snap['artworkUrl'], 'https://example.com/cover.jpg');
    expect(snap['durationMs'], 431000);
    expect(snap['positionMs'], 12000);
    expect(snap['playing'], isTrue);
    expect(snap['volume'], 35);
    expect(snap['supportedCommands'], [
      'stop',
      'play',
      'pause',
      'next',
      'previous',
      'volume',
    ]);
    expect(remote.hasQueue, isFalse);
    expect(remote.hasFavorites, isFalse);
    expect(remote.queueEmpty, isFalse);
    expect(remote.lyricsSynced, isTrue);
    update(_player(title: 'Yesterday'));
    expect(emitted.last!['title'], 'Yesterday');
    update(_player(state: 'paused', title: 'Yesterday'));
    expect(emitted.last!['playing'], isFalse);
    update(_player(state: 'idle'));
    expect(emitted.last, isNull);
    expect(remote.queueEmpty, isTrue);
  });

  test(
    'external playback replaces an old queue and ignores its time events',
    () {
      remote.publishQueue(_queue());
      update(_player());
      expect(emitted.last!['title'], 'Hey Jude');
      remote.handleEvent('queue_time_updated', 'q1', 99);
      expect(emitted.last!['positionMs'], 12000);
      remote.handleEvent('queue_updated', 'q1', _queue());
      expect(emitted.last!['title'], 'Hey Jude');
      remote.publishQueue(null);
      remote.handleEvent('queue_updated', 'q1', _queue());
      expect(emitted.last!['title'], 'Hey Jude');
      update({..._player(), 'active_source': 'q1'});
      remote.publishQueue(_queue());
      expect(emitted.last!['title'], 'Queued track');
      expect(emitted.last!['supportedCommands'], MaRemotePlayer.commands);
      expect(remote.hasQueue, isTrue);
      expect(remote.hasFavorites, isTrue);
    },
  );

  test('inactive queues cannot replace player metadata', () {
    update({..._player(), 'active_source': 'q1'});
    remote.publishQueue({..._queue(), 'active': false});
    expect(emitted.last!['title'], 'Hey Jude');
    expect(remote.hasQueue, isFalse);
  });

  for (final source in ['p1', 'leader']) {
    test('a group member keeps its resolved queue (source: $source)', () {
      update({..._player(), 'active_source': source, 'synced_to': 'leader'});
      remote.publishQueue(_queue());
      expect(emitted.last!['title'], 'Queued track');
      expect(remote.hasQueue, isTrue);
    });
  }

  test('queue volume events preserve the position timestamp', () {
    remote.publishQueue(_queue());
    final before = emitted.last!;
    remote.handleEvent('queue_time_updated', 'q1', 50);
    final timed = emitted.last!;
    update({..._player(), 'active_source': 'q1', 'volume_level': 40});
    expect(emitted.last!['title'], before['title']);
    expect(emitted.last!['positionMs'], 50000);
    expect(emitted.last!['receivedAt'], timed['receivedAt']);
    expect(emitted.last!['volume'], 40);
  });

  test('missing metadata or unavailable players stay hidden', () {
    update(_player(title: ''));
    expect(emitted.last, isNull);
    update({..._player(), 'current_media': null});
    expect(emitted.last, isNull);
    update({..._player(), 'available': false});
    expect(emitted.last, isNull);
  });

  test(
    'external position uses its timestamp and does not advance paused audio',
    () {
      final player = {
        ..._player(),
        'elapsed_time_last_updated':
            DateTime.now().millisecondsSinceEpoch / 1000 - 20,
      };
      update(player);
      expect(emitted.last!['positionMs'], closeTo(32000, 1000));
      update({...player, 'playback_state': 'paused'});
      expect(emitted.last!['positionMs'], 12000);
      update({...player, 'elapsed_time': 500});
      expect(emitted.last!['positionMs'], 431000);
    },
  );

  test('media position and legacy player state are supported', () {
    final player = _player()
      ..remove('elapsed_time')
      ..remove('playback_state');
    (player['current_media'] as Map)['elapsed_time'] = 8;
    update({...player, 'state': 'playing'});
    expect(emitted.last!['playing'], isTrue);
    expect(emitted.last!['positionMs'], 8000);
    (player['current_media'] as Map).remove('elapsed_time');
    update({...player, 'state': 'playing'});
    expect(remote.lyricsSynced, isFalse);
  });

  for (final queueFails in [false, true]) {
    test(
      'initial socket refresh reads player metadata (queue error: $queueFails)',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        WebSocket? socket;
        final ready = Completer<void>();
        server.listen((request) async {
          socket = await WebSocketTransformer.upgrade(request);
          socket!.listen((message) {
            final call = jsonDecode(message as String) as Map;
            final command = call['command'];
            socket!.add(
              jsonEncode({
                'message_id': call['message_id'],
                if (command == 'player_queues/get_active_queue' && queueFails)
                  'error_code': 1
                else
                  'result': command == 'players/get' ? _player() : null,
              }),
            );
          });
        });
        await remote.stop();
        remote = MaRemotePlayer(
          baseUrl: 'http://127.0.0.1:${server.port}',
          token: 'test',
          playerId: 'p1',
          log: Logger(),
          onSnapshot: (snap) {
            emitted.add(snap);
            if (snap != null && !ready.isCompleted) ready.complete();
          },
        );
        try {
          remote.start();
          await ready.future.timeout(const Duration(seconds: 5));
          expect(emitted.last!['title'], 'Hey Jude');
          expect(remote.hasQueue, isFalse);
        } finally {
          await remote.stop();
          await socket?.close();
          await server.close(force: true);
        }
      },
    );
  }
}
