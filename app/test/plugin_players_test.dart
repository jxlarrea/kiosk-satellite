import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/music_library/library_model.dart';
import 'package:kiosk_satellite/managers/music_library/plugin_library_source.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_players.dart';
import 'package:kiosk_satellite/managers/sendspin/plugin_player.dart';
import 'package:kiosk_satellite/managers/sendspin/remote_player.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart';

void main() {
  tearDown(() {
    PluginPlayers.published.value = const {};
    PluginPlayers.states.clear();
  });

  group('picks', () {
    test('a plugin pick parses and stores as it came', () {
      final source = PlayerSource.parse('plugin:radio/archive');
      expect(source.kind, PlayerSourceKind.plugin);
      expect(source.id, 'radio/archive');
      expect(source.value, 'plugin:radio/archive');
    });

    test('the plugin id and key come apart at the first slash', () {
      expect(PluginPlayers.parse('plugin:radio/archive'), ('radio', 'archive'));
      expect(PluginPlayers.parse('plugin:radio'), isNull);
      expect(PluginPlayers.parse('plugin:/archive'), isNull);
      expect(PluginPlayers.parse('airplay'), isNull);
    });

    test('a plugin publishing again replaces only its own players', () {
      PluginPlayers.setPlugin('a', 's1', 'Radio', [
        {'key': 'one', 'title': 'One', 'library': true},
      ]);
      PluginPlayers.setPlugin('b', 's2', 'Other', [
        {'key': 'two', 'title': 'Two'},
      ]);
      PluginPlayers.setPlugin('a', 's3', 'Radio', const []);
      expect(PluginPlayers.published.value.keys, ['plugin:b/two']);
      expect(PluginPlayers.published.value['plugin:b/two']!.name, 'Other: Two');
    });

    test('Sendspin rows hide while a plugin player is the pick', () {
      const wanted = {
        'ne': ['session:*', 'airplay'],
        'neStartsWith': 'plugin:',
      };
      expect(sendspinEnabled.alsoDependsSatisfiedBy(''), isTrue);
      expect(sendspinEnabled.alsoDependsSatisfiedBy('airplay'), isFalse);
      expect(
        sendspinEnabled.alsoDependsSatisfiedBy('plugin:radio/archive'),
        isFalse,
      );
      expect(sendspinEnabled.alsoDependsOnValue, wanted);
    });
  });

  group('Now Playing', () {
    const pick = 'plugin:radio/archive';

    test('idle shows nothing', () {
      expect(PluginRemotePlayer.snapshotFrom(pick, {'state': 'idle'}), isNull);
      expect(PluginRemotePlayer.snapshotFrom(pick, null), isNull);
    });

    test('a playing track shows its actions and the device volume', () {
      final snap = PluginRemotePlayer.snapshotFrom(pick, {
        'state': 'playing',
        'title': 'Song',
        'artist': 'Band',
        'durationMs': 180000,
        'positionMs': 1000,
        'actions': ['play', 'pause', 'seek'],
        'repeat': 'all',
      })!;
      expect(snap['title'], 'Song');
      expect(snap['playing'], isTrue);
      expect(snap['repeat'], 'all');
      expect(snap['supportedCommands'], ['play', 'pause', 'seek', 'volume']);
      expect(snap.containsKey('stream'), isFalse);
    });

    test('a stream drops seek and a display-only player keeps volume', () {
      final snap = PluginRemotePlayer.snapshotFrom(pick, {
        'state': 'buffering',
        'actions': ['seek'],
      })!;
      expect(snap['playing'], isTrue);
      expect(snap['supportedCommands'], ['volume']);
      expect(snap['stream'], isTrue);
    });

    test('artwork sent as bytes reads back by pick', () {
      final snap = PluginRemotePlayer.snapshotFrom(pick, {
        'state': 'paused',
        'artworkId': 3,
        'artworkUrl': 'https://example.com/a.jpg',
      })!;
      expect(snap['artworkUrl'], 'plugin-art:$pick#3');
      expect(PluginRemotePlayer.artworkPick('${snap['artworkUrl']}'), pick);
      expect(PluginRemotePlayer.artworkId('${snap['artworkUrl']}'), 3);
      final url = PluginRemotePlayer.snapshotFrom(pick, {
        'state': 'paused',
        'artworkUrl': 'https://example.com/a.jpg',
      })!;
      expect(url['artworkUrl'], 'https://example.com/a.jpg');
    });

    test('the queue lists played rows above the current one', () {
      final queue = PluginRemotePlayer.queueFrom({
        'items': [
          {'id': 'a', 'title': 'A', 'subtitle': 'X'},
          {'id': 'b', 'title': 'B', 'durationMs': 1000},
          {'id': 'c', 'title': 'C'},
        ],
        'current': 1,
      })!;
      expect(queue.upNext, 1);
      expect(queue.items[0]['played'], isTrue);
      expect(queue.items[0]['artist'], 'X');
      expect(queue.items[1]['current'], isTrue);
      expect(queue.items[1]['durationMs'], 1000);
      expect(queue.items[2]['played'], isFalse);
    });
  });

  group('library', () {
    const pick = 'plugin:radio/archive';

    test('items, shelves and pages read the bridge shape', () {
      final item = PluginLibrarySource.itemFrom({
        'id': 'x',
        'kind': 'album',
        'title': 'Album',
        'subtitle': 'Band',
        'artworkUrl': 'https://example.com/c.jpg',
        'browsable': true,
      })!;
      expect(item.kind, LibraryKind.album);
      expect(item.expandable, isTrue);
      expect(item.art, 'https://example.com/c.jpg');
      expect(PluginLibrarySource.itemFrom({'title': 'no id'}), isNull);
      final shelves = PluginLibrarySource.shelvesFrom([
        {
          'title': 'Featured',
          'items': [
            {'id': 'x'},
            {'title': 'dropped'},
          ],
        },
      ]);
      expect(shelves.single.title, 'Featured');
      expect(shelves.single.items, hasLength(1));
    });

    test('browse gathers every page', () async {
      final asked = <int>[];
      final source = PluginLibrarySource(
        pick,
        request: (op, args) async {
          final offset = args['offset'] as int;
          asked.add(offset);
          return {
            'items': [
              for (var i = 0; i < 2; i++) {'id': '${offset + i}'},
            ],
            'more': offset < 4,
          };
        },
      );
      final page = await source.browse(null);
      expect(asked, [0, 2, 4]);
      expect(page.items.map((i) => i.id), ['0', '1', '2', '3', '4', '5']);
    });

    test('a play needs the plugin player picked and names the mode', () async {
      final sent = <Map<String, Object?>>[];
      final source = PluginLibrarySource(
        pick,
        request: (op, args) async {
          sent.add({'op': op, ...args});
          return null;
        },
      );
      const track = LibraryItem(id: 't', kind: LibraryKind.track, title: 'T');
      const album = LibraryItem(id: 'a', kind: LibraryKind.album, title: 'A');
      expect(source.needsSpeaker(''), isTrue);
      expect(source.needsSpeaker(pick), isFalse);
      expect(
        await source.play(track, PlayMode.next, pick: 'airplay'),
        'no_speaker',
      );
      expect(
        await source.play(track, PlayMode.radio, pick: pick, within: album),
        isNull,
      );
      expect(sent.single, {
        'op': 'play',
        'item': 't',
        'mode': 'replace',
        'within': 'a',
      });
    });

    test('a failed request reads as a library error', () async {
      final source = PluginLibrarySource(
        pick,
        request: (op, args) async =>
            throw const PluginPlayerError('Archive is down'),
      );
      await expectLater(
        source.search('x'),
        throwsA(
          isA<LibraryError>().having(
            (e) => e.message,
            'message',
            'Archive is down',
          ),
        ),
      );
    });
  });
}
