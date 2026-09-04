import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/sendspin/ha_remote_player.dart';
import 'package:kiosk_satellite/managers/sendspin/remote_player.dart';

void main() {
  group('PlayerSource', () {
    test('parses every prefix and the bare legacy form', () {
      expect(PlayerSource.parse('').kind, PlayerSourceKind.local);
      expect(PlayerSource.parse('  ').isLocal, isTrue);
      final ma = PlayerSource.parse('ma:abc');
      expect(ma.kind, PlayerSourceKind.musicAssistant);
      expect(ma.id, 'abc');
      expect(ma.value, 'ma:abc');
      final ha = PlayerSource.parse('ha:media_player.office');
      expect(ha.kind, PlayerSourceKind.homeAssistant);
      expect(ha.id, 'media_player.office');
      final sonos = PlayerSource.parse('sonos:RINCON_1');
      expect(sonos.kind, PlayerSourceKind.sonos);
      expect(sonos.id, 'RINCON_1');
      // A Music Assistant id stored before the prefix existed.
      final legacy = PlayerSource.parse('52232930f0e3');
      expect(legacy.kind, PlayerSourceKind.musicAssistant);
      expect(legacy.id, '52232930f0e3');
    });
  });

  group('HaRemotePlayer.snapshotFrom', () {
    const base = 'http://ha.local:8123';

    test('maps a playing entity to the Now Playing map', () {
      final snap = HaRemotePlayer.snapshotFrom(
        state: 'playing',
        attributes: {
          'media_title': 'Brother Sun',
          'media_artist': "The Porter's Gate",
          'media_album_name': 'Neighbor Songs',
          'media_duration': 198,
          'media_position': 10,
          'media_position_updated_at': DateTime.now()
              .toUtc()
              .subtract(const Duration(seconds: 5))
              .toIso8601String(),
          'entity_picture': '/api/media_player_proxy/media_player.office?x=1',
          'shuffle': true,
          'volume_level': 0.62,
          'is_volume_muted': false,
          'repeat': 'all',
          // play, pause, next, previous, seek, volume set, shuffle,
          // repeat set.
          'supported_features': 16384 | 1 | 32 | 16 | 2 | 4 | 32768 | 262144,
        },
        baseUrl: base,
      );
      expect(snap, isNotNull);
      expect(snap!['title'], 'Brother Sun');
      expect(snap['artist'], "The Porter's Gate");
      expect(snap['album'], 'Neighbor Songs');
      expect(snap['durationMs'], 198000);
      // The stamp is five seconds old, so the position moved on.
      expect(snap['positionMs'], greaterThanOrEqualTo(14900));
      expect(snap['positionMs'], lessThan(16500));
      expect(snap['playing'], isTrue);
      expect(snap['shuffle'], isTrue);
      expect(snap['repeat'], 'all');
      expect(snap['supportedCommands'], contains('repeat'));
      expect(snap['volume'], 62);
      expect(snap['muted'], isFalse);
      expect(
        snap['artworkUrl'],
        '$base/api/media_player_proxy/media_player.office?x=1',
      );
      expect(
        snap['supportedCommands'],
        containsAll([
          'play',
          'pause',
          'next',
          'previous',
          'seek',
          'shuffle',
          'volume',
        ]),
      );
      expect(snap['supportedCommands'], isNot(contains('stop')));
    });

    test('a paused entity keeps its reported position', () {
      final snap = HaRemotePlayer.snapshotFrom(
        state: 'paused',
        attributes: {
          'media_title': 'Song',
          'media_position': 42,
          'media_position_updated_at': DateTime.now()
              .toUtc()
              .subtract(const Duration(seconds: 30))
              .toIso8601String(),
          'supported_features': 1,
        },
        baseUrl: base,
      );
      expect(snap!['playing'], isFalse);
      expect(snap['positionMs'], 42000);
    });

    test('an idle entity shows nothing until playback was seen', () {
      final attrs = {'media_title': 'Last song', 'supported_features': 1};
      expect(
        HaRemotePlayer.snapshotFrom(
          state: 'idle',
          attributes: attrs,
          baseUrl: base,
        ),
        isNull,
      );
      expect(
        HaRemotePlayer.snapshotFrom(
          state: 'idle',
          attributes: attrs,
          baseUrl: base,
          sawPlayback: true,
        ),
        isNotNull,
      );
      // Off and unavailable never show, whatever was seen.
      expect(
        HaRemotePlayer.snapshotFrom(
          state: 'off',
          attributes: attrs,
          baseUrl: base,
          sawPlayback: true,
        ),
        isNull,
      );
    });

    test('no title is nothing to show', () {
      expect(
        HaRemotePlayer.snapshotFrom(
          state: 'playing',
          attributes: {'supported_features': 1},
          baseUrl: base,
        ),
        isNull,
      );
    });
  });

  group('HaRemotePlayer entity events', () {
    test('merges the full state and later diffs', () {
      final snapshots = <Map<String, Object?>?>[];
      final player = HaRemotePlayer(
        baseUrl: 'http://ha.local:8123',
        token: 't',
        entityId: 'media_player.office',
        onSnapshot: snapshots.add,
        log: Logger(),
      );
      player.handleEntityEvent({
        'a': {
          'media_player.office': {
            's': 'playing',
            'a': {
              'media_title': 'One',
              'media_artist': 'A',
              'supported_features': 1,
              'volume_level': 0.5,
            },
          },
        },
      });
      expect(snapshots.last!['title'], 'One');
      expect(snapshots.last!['volume'], 50);
      // A diff carries only what changed: the artist survives, the
      // removed attribute goes, the state flips.
      player.handleEntityEvent({
        'c': {
          'media_player.office': {
            '+': {
              's': 'paused',
              'a': {'media_title': 'Two'},
            },
            '-': {
              'a': ['volume_level'],
            },
          },
        },
      });
      expect(snapshots.last!['title'], 'Two');
      expect(snapshots.last!['artist'], 'A');
      expect(snapshots.last!['playing'], isFalse);
      expect(snapshots.last!.containsKey('volume'), isFalse);
      // Events for another entity are ignored.
      player.handleEntityEvent({
        'c': {
          'media_player.other': {
            '+': {'s': 'playing'},
          },
        },
      });
      expect(snapshots.last!['playing'], isFalse);
      // An idle state after playback keeps the card, paused.
      player.handleEntityEvent({
        'c': {
          'media_player.office': {
            '+': {'s': 'idle'},
          },
        },
      });
      expect(snapshots.last, isNotNull);
      expect(player.queueEmpty, isFalse);
    });

    test('has no queue and synced lyrics', () {
      final player = HaRemotePlayer(
        baseUrl: 'http://ha.local:8123',
        token: 't',
        entityId: 'media_player.office',
        onSnapshot: (_) {},
        log: Logger(),
      );
      expect(player.hasQueue, isFalse);
      expect(player.lyricsSynced, isTrue);
      expect(player.playerId, 'media_player.office');
    });
  });
}
