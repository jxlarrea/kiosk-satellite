import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/sendspin/ma_remote_player.dart';
import 'package:kiosk_satellite/managers/sendspin/music_assistant_api.dart';

Map<String, Object?> _song({String title = 'Take Five'}) => {
  'title': title,
  'artist': 'The Dave Brubeck Quartet',
  'album': 'Time Out',
  'image_url': 'https://example.com/track.jpg',
  'duration': 324,
};

Map<String, Object?> _queue({bool streamMetadata = true}) => {
  'queue_id': 'p1',
  'active': true,
  'state': 'playing',
  'elapsed_time': 12,
  'shuffle_enabled': true,
  'repeat_mode': 'all',
  'items': 3,
  'current_item': {
    'queue_item_id': 'radio-item',
    'name': 'Jazz Radio',
    'media_item': {
      'media_type': 'radio',
      'uri': 'library://radio/26',
      'name': 'Jazz Radio',
    },
    'image': {
      'path': 'https://example.com/station.jpg',
      'remotely_accessible': true,
    },
    if (streamMetadata) 'streamdetails': {'stream_metadata': _song()},
  },
};

Map<String, Object?> _player({Map<String, Object?>? song}) => {
  'player_id': 'p1',
  'active_source': 'p1',
  'available': true,
  'playback_state': 'playing',
  'volume_level': 30,
  'current_media': {'uri': 'library://radio/26', ...song ?? _song()},
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

  test('radio stream metadata supplies song details and retains the queue', () {
    final snap = queueTrackSnapshot(_queue())!;
    expect(snap['title'], 'Take Five');
    expect(snap['artist'], 'The Dave Brubeck Quartet');
    expect(snap['album'], 'Time Out');
    expect(snap['artworkUrl'], 'https://example.com/track.jpg');
    expect(snap['durationMs'], 324000);
    expect(snap['mediaType'], 'radio');
    expect(snap['mediaUri'], 'library://radio/26');
    expect(snap['queueItemId'], 'radio-item');
    expect(snap['shuffle'], isTrue);
    expect(snap['repeat'], 'all');
    expect(snap['queueLength'], 3);
  });

  test('missing or blank stream details fall back to the station', () {
    for (final metadata in [
      null,
      <String, Object?>{},
      {'title': ' ', 'artist': '', 'image_url': ''},
    ]) {
      final queue = _queue();
      (queue['current_item'] as Map)['streamdetails'] = {
        'stream_metadata': metadata,
      };
      final snap = queueTrackSnapshot(queue)!;
      expect(snap['title'], 'Jazz Radio');
      expect(snap['artist'], isNull);
      expect(snap['artworkUrl'], 'https://example.com/station.jpg');
    }
  });

  test('partial song metadata does not reuse fields from an older song', () {
    final queue = _queue();
    (queue['current_item'] as Map)['streamdetails'] = {
      'stream_metadata': {'title': 'New song'},
    };
    final snap = queueTrackSnapshot(queue, currentMedia: _song())!;
    expect(snap['title'], 'New song');
    expect(snap['artist'], isNull);
    expect(snap['album'], isNull);
    expect(snap['artworkUrl'], 'https://example.com/station.jpg');
  });

  test(
    'player events update radio songs when the queue has no stream metadata',
    () {
      final queue = _queue(streamMetadata: false);
      remote.publishQueue(queue);
      remote.handleEvent('queue_time_updated', 'p1', 50);
      final before = emitted.last!;
      update(_player());
      expect(emitted.last!['title'], 'Take Five');
      expect(emitted.last!['artist'], 'The Dave Brubeck Quartet');
      expect(emitted.last!['artworkUrl'], 'https://example.com/track.jpg');
      expect(emitted.last!['positionMs'], 50000);
      expect(emitted.last!['receivedAt'], before['receivedAt']);
      expect(emitted.last!['timeFresh'], isFalse);
      expect(remote.hasQueue, isTrue);
      expect(remote.hasFavorites, isTrue);
      expect(emitted.last!['supportedCommands'], MaRemotePlayer.commands);
      update(_player(song: _song(title: 'Blue Rondo a la Turk')));
      expect(emitted.last!['title'], 'Blue Rondo a la Turk');
      remote.publishQueue(queue);
      expect(emitted.last!['title'], 'Blue Rondo a la Turk');
      expect(emitted.last!['timeFresh'], isTrue);
    },
  );

  test('queue song updates beat older cached player metadata', () {
    remote.publishQueue(_queue(streamMetadata: false));
    update(_player());
    final queue = _queue();
    (queue['current_item'] as Map)['streamdetails'] = {
      'stream_metadata': _song(title: 'Blue Rondo a la Turk'),
    };
    remote.handleEvent('queue_updated', 'p1', queue);
    expect(emitted.last!['title'], 'Blue Rondo a la Turk');
  });

  test(
    'cleared player metadata restores the station without stale artwork',
    () {
      remote.publishQueue(_queue(streamMetadata: false));
      update(_player());
      update(_player(song: {'title': 'New song'}));
      expect(emitted.last!['artist'], isNull);
      expect(emitted.last!['artworkUrl'], 'https://example.com/station.jpg');
      update({..._player(), 'current_media': null});
      expect(emitted.last!['title'], 'Jazz Radio');
      expect(emitted.last!['artist'], isNull);
    },
  );

  for (final mismatch in [
    {'uri': 'library://radio/27'},
    {'queue_item_id': 'previous-item'},
    {'source_id': 'another-queue'},
  ]) {
    test(
      'unmatched player metadata stays out of the radio queue: $mismatch',
      () {
        remote.publishQueue(_queue(streamMetadata: false));
        update(_player(song: {..._song(), ...mismatch}));
        expect(emitted.last!['title'], 'Jazz Radio');
        expect(emitted.last!['artist'], isNull);
      },
    );
  }

  test('queue item identity supports resolved radio URLs', () {
    remote.publishQueue(_queue(streamMetadata: false));
    update(
      _player(
        song: {
          ..._song(),
          'uri': 'https://example.com/radio.mp3',
          'source_id': 'p1',
          'queue_item_id': 'radio-item',
        },
      ),
    );
    expect(emitted.last!['title'], 'Take Five');
  });

  test('changing stations does not reuse the previous song', () {
    remote.publishQueue(_queue(streamMetadata: false));
    update(_player());
    final queue = _queue(streamMetadata: false);
    final item = queue['current_item'] as Map;
    item['queue_item_id'] = 'new-station';
    (item['media_item'] as Map).addAll(<String, String>{
      'uri': 'library://radio/27',
      'name': 'Other station',
    });
    remote.publishQueue(queue);
    expect(emitted.last!['title'], 'Other station');
    expect(emitted.last!['artist'], isNull);
  });

  test('ordinary queued tracks retain their metadata during player events', () {
    final queue = _queue(streamMetadata: false);
    (queue['current_item'] as Map)['media_item'] = {
      'media_type': 'track',
      'name': 'Queued track',
      'artists': [
        {'name': 'Queue artist'},
      ],
    };
    remote.publishQueue(queue);
    update(_player());
    expect(emitted.last!['title'], 'Queued track');
    expect(emitted.last!['artist'], 'Queue artist');
  });
}
