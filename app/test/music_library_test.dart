import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/analytics/usage_counters.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/music_library/ha_library_source.dart';
import 'package:kiosk_satellite/managers/music_library/library_model.dart';
import 'package:kiosk_satellite/managers/music_library/ma_library_source.dart';
import 'package:kiosk_satellite/managers/music_library/music_requests.dart';
import 'package:kiosk_satellite/managers/music_library/sonos_library_source.dart';
import 'package:kiosk_satellite/managers/sendspin/music_assistant_api.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/music_library_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A Music Assistant answering from canned results, recording each call.
/// An answer that is a function is handed the call's arguments.
class _FakeMa {
  final calls = <(String, Map<String, Object?>)>[];
  final answers = <String, Object?>{};

  Future<Map<String, Object?>> call(
    String command,
    Map<String, Object?> args,
  ) async {
    calls.add((command, args));
    if (!answers.containsKey(command)) {
      return {
        'ok': false,
        'error': {'code': 'unknown', 'message': 'no $command'},
      };
    }
    final answer = answers[command];
    return {
      'ok': true,
      'result': answer is Object? Function(Map<String, Object?>)
          ? answer(args)
          : answer,
    };
  }
}

Map<String, Object?> _track(String id, String name, {int duration = 200}) => {
  'media_type': 'track',
  'item_id': id,
  'provider': 'library',
  'uri': 'library://track/$id',
  'name': name,
  'duration': duration,
  'artists': [
    {'name': 'Juniper Lane', 'uri': 'library://artist/1', 'item_id': '1'},
  ],
  'image': {'path': 'x', 'proxy_id': 'p$id'},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Music Assistant source', () {
    MaLibrarySource source(_FakeMa ma, {String own = 'up-own'}) =>
        MaLibrarySource(
          call: ma.call,
          webBase: () => 'https://ma.local',
          ownQueueId: () async => own,
        );

    test('lists entries with their covers through the image proxy', () async {
      final ma = _FakeMa()
        ..answers['music/tracks/library_items'] = [
          _track('1', 'Tidelines'),
          {'media_type': 'mystery', 'name': 'skipped'},
        ];
      final page = await source(
        ma,
      ).list(const LibraryCategory('tracks', LibraryKind.track));
      expect(page.items, hasLength(1));
      final item = page.items.single;
      expect(item.title, 'Tidelines');
      expect(item.subtitle, 'Juniper Lane');
      expect(item.durationMs, 200000);
      expect(item.art, 'https://ma.local/imageproxy/p1?size=256&fmt=jpg');
      expect(page.more, isFalse);
    });

    test(
      'builds Discover from the library when nothing is recommended',
      () async {
        final ma = _FakeMa()
          ..answers['music/recommendations'] = [
            {'name': 'In progress', 'items': <Object>[]},
          ]
          ..answers['music/recently_played_items'] = [_track('1', 'One')]
          ..answers['music/playlists/library_items'] = <Object>[]
          ..answers['music/tracks/library_items'] = [_track('2', 'Two')];
        final shelves = await source(ma).discover();
        expect(shelves.map((s) => s.key), ['recent', 'added']);
      },
    );

    Map<String, Object?> row(String id, {bool on = true}) => {
      'item_id': id,
      'provider': 'recommendations',
      'name': id,
      'uri': 'library://folder/$id',
      'media_type': 'folder',
      'items': <Object>[],
      'enabled_by_default': on,
    };

    test(
      'Discover loads each recommendation row on its own, hidden rows left out',
      () async {
        final ma = _FakeMa()
          ..answers['music/recommendations'] = [
            row('recently_added_albums'),
            row('random_artists', on: false),
            row('recently_played'),
            row('in_progress'),
          ]
          ..answers['music/recommendations/items'] = (args) => switch (args) {
            {'item_id': 'in_progress'} => <Object>[],
            {'item_id': final String id} => [_track(id, id)],
            _ => null,
          };
        final shelves = await source(ma).discover();
        // In progress is empty, so Recently played leads.
        expect(shelves.map((s) => s.title), [
          'recently_played',
          'recently_added_albums',
        ]);
        expect(shelves.first.items.single.title, 'recently_played');
        final asked = [
          for (final (command, args) in ma.calls)
            if (command == 'music/recommendations/items') args,
        ];
        expect(asked, hasLength(3));
        expect(asked.first, {
          'provider': 'recommendations',
          'item_id': 'in_progress',
        });
      },
    );

    test('Discover follows the layout saved in Music Assistant', () {
      final folders = [
        row('in_progress'),
        row('recently_played'),
        row('recently_added_albums'),
        row('random_artists', on: false),
        row('forgotten_tracks', on: false),
      ];
      List<String?> ids(Map<String, Object?> preferences) => [
        for (final f in MaLibrarySource.discoverRows(folders, preferences))
          (f['item_id'] ?? f['uri']) as String?,
      ];
      // Browse by genre comes last unless moved.
      expect(ids(const {}), [
        'in_progress',
        'recently_played',
        'recently_added_albums',
        'genres',
      ]);
      expect(
        ids({
          'discover.rows': {
            'hidden': ['genres'],
          },
        }),
        ['in_progress', 'recently_played', 'recently_added_albums'],
      );
      expect(
        ids({
          'discover.rows': {
            'hidden': ['library://folder/in_progress'],
            'shown': ['library://folder/random_artists'],
            'order': [
              'players',
              'library://folder/random_artists',
              'library://folder/recently_added_albums',
              'library://folder/recently_played',
            ],
          },
        }),
        [
          'random_artists',
          'genres',
          'recently_added_albums',
          'recently_played',
        ],
      );
      // Older pages saved a position and an enabled flag per row.
      expect(
        ids({
          'discoverRowSettings': {
            'library://folder/recently_added_albums': {
              'position': 0,
              'enabled': true,
            },
            'library://folder/recently_played': {
              'position': 1,
              'enabled': false,
            },
          },
        }),
        // In progress, unsaved, goes where it has no row before it: first.
        ['in_progress', 'recently_added_albums', 'genres'],
      );
    });

    Map<String, Object?> genre(String id, String name) => {
      'media_type': 'genre',
      'item_id': id,
      'provider': 'library',
      'uri': 'library://genre/$id',
      'name': name,
    };

    test(
      'Browse by genre offers the eight genres with the most music',
      () async {
        final ma = _FakeMa()
          ..answers['music/recommendations'] = <Object>[]
          ..answers['music/genres/library_items'] = [
            for (var i = 1; i <= 10; i++) genre('$i', 'Genre $i'),
          ]
          ..answers['music/genres/media_counts'] = {
            '3': {'track': 9, 'album': 1},
            '7': {'track': 4},
          };
        final shelves = await source(ma).discover();
        final genres = shelves.single;
        expect(genres.key, 'genres');
        expect(genres.items.map((g) => g.title), [
          'Genre 3',
          'Genre 7',
          'Genre 1',
          'Genre 2',
          'Genre 4',
          'Genre 5',
          'Genre 6',
          'Genre 8',
        ]);
        expect(genres.items.first.kind, LibraryKind.genre);
        expect(genres.items.first.expandable, isTrue);
      },
    );

    test("a genre opens on Music Assistant's rows, else its tracks", () async {
      final ma = _FakeMa()
        ..answers['music/genres/overview'] = [
          {
            'item_id': 'genre_artist',
            'name': 'Artists',
            'items': [
              {
                'media_type': 'artist',
                'item_id': '1',
                'provider': 'library',
                'uri': 'library://artist/1',
                'name': 'Juniper Lane',
              },
            ],
          },
          {'item_id': 'genre_album', 'name': 'Albums', 'items': <Object>[]},
        ];
      final item = LibraryItem(
        id: 'library://genre/15',
        kind: LibraryKind.genre,
        title: 'Dance',
        raw: genre('15', 'Dance'),
      );
      final detail = await source(ma).open(item);
      expect(detail.shelves.map((s) => s.title), ['Artists']);
      expect(detail.tracks, isEmpty);
      expect(ma.calls.single.$2, {
        'item_id': '15',
        'provider_instance_id_or_domain': 'library',
      });

      ma.answers['music/genres/overview'] = <Object>[];
      ma.answers['music/genres/tracks'] = [_track('4', 'Four')];
      final tracks = await source(ma).open(item);
      expect(tracks.tracks.single.title, 'Four');
    });

    test('the Browse root shows each provider with its logo', () async {
      final ma = _FakeMa()
        ..answers['music/browse'] = [
          {
            'media_type': 'folder',
            'name': 'Spotify',
            'path': 'spotify--x://',
            'provider': 'spotify',
            'uri': 'spotify--x://',
          },
          {
            'media_type': 'folder',
            'name': 'Ambient Sounds',
            'path': 'ambient_sounds://',
            'provider': 'ambient_sounds',
            'uri': 'ambient_sounds://',
          },
        ]
        ..answers['providers/manifests'] = [
          {
            'domain': 'spotify',
            'icon_images': ['default', 'monochrome'],
          },
          {
            'domain': 'ambient_sounds',
            'icon_images': ['default', 'dark'],
          },
        ]
        ..answers['providers/icon'] = (args) =>
            'data:image/svg+xml;base64,${args['provider']}-${args['variant']}';
      final s = source(ma);
      final page = await s.browse(null);
      expect(page.items.map((i) => (i.art, i.artDark)), [
        ('data:image/svg+xml;base64,spotify-default', null),
        (
          'data:image/svg+xml;base64,ambient_sounds-default',
          'data:image/svg+xml;base64,ambient_sounds-dark',
        ),
      ]);
      // The logos are asked for once.
      await s.browse(null);
      expect(ma.calls.where((c) => c.$1 == 'providers/icon'), hasLength(3));
      expect(
        ma.calls.where((c) => c.$1 == 'providers/manifests'),
        hasLength(1),
      );
    });

    test('lists in the order picked, artists only on an album', () async {
      final ma = _FakeMa()
        ..answers['music/artists/library_items'] = <Object>[]
        ..answers['music/playlists/library_items'] = <Object>[];
      final s = source(ma);
      const artists = LibraryCategory('artists', LibraryKind.artist);
      const playlists = LibraryCategory('playlists', LibraryKind.playlist);
      await s.list(playlists);
      await s.list(playlists, sort: LibrarySort.recentlyPlayed);
      await s.list(playlists, sort: LibrarySort.mostPlayed, albumArtists: true);
      await s.list(artists, sort: LibrarySort.nameDesc, albumArtists: true);
      await s.list(artists, sort: LibrarySort.recentlyAdded);
      expect(
        [for (final (_, args) in ma.calls) args['order_by']],
        [
          'sort_name',
          'last_played_desc',
          'play_count_desc',
          'sort_name_desc',
          'timestamp_added_desc',
        ],
      );
      expect(
        [for (final (_, args) in ma.calls) args['album_artists_only']],
        [null, null, null, true, null],
      );
    });

    test('a track tapped in a playlist plays the playlist from it', () async {
      final ma = _FakeMa()..answers['player_queues/play_media'] = null;
      final playlist = LibraryItem(
        id: 'library://playlist/5',
        kind: LibraryKind.playlist,
        title: 'Night Shift',
      );
      final track = LibraryItem(
        id: 'library://track/7',
        kind: LibraryKind.track,
        title: 'Tidelines',
        raw: _track('7', 'Tidelines'),
      );
      final error = await source(
        ma,
      ).play(track, PlayMode.replace, pick: 'ma:living', within: playlist);
      expect(error, isNull);
      final (command, args) = ma.calls.single;
      expect(command, 'player_queues/play_media');
      expect(args['queue_id'], 'living');
      expect(args['media'], 'library://playlist/5');
      expect(args['start_item'], '7');
      expect(args['option'], 'replace');
    });

    test('plays on this device through its own queue', () async {
      final ma = _FakeMa()..answers['player_queues/play_media'] = null;
      final item = LibraryItem(
        id: 'library://album/3',
        kind: LibraryKind.album,
        title: 'Glass Harbor',
      );
      expect(await source(ma).play(item, PlayMode.add, pick: ''), isNull);
      expect(ma.calls.single.$2['queue_id'], 'up-own');
      expect(ma.calls.single.$2['option'], 'add');
      expect(
        await source(ma, own: '').play(item, PlayMode.add, pick: ''),
        'no_speaker',
      );
    });

    test('needs a Music Assistant speaker, or this device', () {
      final s = source(_FakeMa());
      expect(s.needsSpeaker(''), isFalse);
      expect(s.needsSpeaker('ma:x'), isFalse);
      expect(s.needsSpeaker('ha:media_player.x'), isTrue);
    });
  });

  group('Home Assistant source', () {
    test('hides the picture and speech sources at the root', () async {
      final sent = <Map<String, Object?>>[];
      final source = HaLibrarySource(
        baseUrl: () => 'https://ha.local',
        request: (command) async {
          sent.add(command);
          if (command['type'] == 'get_states') {
            return [
              {
                'entity_id': 'media_player.kitchen',
                'attributes': {'supported_features': 4194304 | 2097152},
              },
            ];
          }
          return {
            'title': 'Root',
            'children': [
              {
                'title': 'Radio Browser',
                'media_class': 'app',
                'media_content_id': 'media-source://radio_browser',
                'media_content_type': 'app',
                'can_expand': true,
                'thumbnail': '/api/brands/integration/radio_browser/logo.png',
              },
              {
                'title': 'Camera',
                'media_class': 'app',
                'media_content_id': 'media-source://camera',
                'can_expand': true,
              },
            ],
          };
        },
      );
      await expectLater(source.browse(null), throwsA(isA<LibraryError>()));
      await source.follow('ha:media_player.kitchen');
      expect(source.hasSearch, isTrue);
      final page = await source.browse(null);
      expect(page.items.map((i) => i.title), ['Radio Browser']);
      expect(
        page.items.single.art,
        'https://ha.local/api/brands/integration/radio_browser/logo.png',
      );
      expect(page.items.single.kind, LibraryKind.folder);
    });

    test('plays with the queue mode the speaker supports', () async {
      final sent = <Map<String, Object?>>[];
      final source = HaLibrarySource(
        baseUrl: () => '',
        request: (command) async {
          sent.add(command);
          if (command['type'] == 'get_states') {
            return [
              {
                'entity_id': 'media_player.kitchen',
                'attributes': {'supported_features': 2097152},
              },
            ];
          }
          return null;
        },
      );
      await source.follow('ha:media_player.kitchen');
      final item = LibraryItem(
        id: 'media-source://radio_browser/x',
        kind: LibraryKind.radio,
        title: 'Coastline FM',
        raw: const {
          'media_content_id': 'media-source://radio_browser/x',
          'media_content_type': 'audio/mpeg',
        },
      );
      expect(
        await source.play(item, PlayMode.next, pick: 'ha:media_player.kitchen'),
        isNull,
      );
      final call = sent.last;
      expect(call['service'], 'play_media');
      expect((call['service_data'] as Map)['enqueue'], 'next');
      expect(await source.play(item, PlayMode.next, pick: ''), 'no_speaker');
    });
  });

  group('Sonos source', () {
    test('reads favorites, their kind from the metadata they carry', () {
      const didl =
          '<DIDL-Lite><item id="FV:2/7" parentID="FV:2" restricted="false">'
          '<dc:title>Hit List</dc:title>'
          '<upnp:class>object.itemobject.item.sonos-favorite</upnp:class>'
          '<res protocolInfo="x-sonosapi-radio:*:*:*">'
          'x-sonosapi-radio:sonos%3a2997?sid=303&amp;flags=0</res>'
          '<upnp:albumArtURI>/getaa?s=1</upnp:albumArtURI>'
          '<r:type>instantPlay</r:type><r:description>Sonos Radio</r:description>'
          '<r:resMD>&lt;DIDL-Lite&gt;&lt;item&gt;&lt;upnp:class&gt;'
          'object.item.audioItem.audioBroadcast&lt;/upnp:class&gt;'
          '&lt;/item&gt;&lt;/DIDL-Lite&gt;</r:resMD></item>'
          '<item id="FV:2/1" parentID="FV:2" restricted="false">'
          '<dc:title>Discover</dc:title><res></res><r:type>shortcut</r:type>'
          '</item></DIDL-Lite>';
      final items = SonosLibrarySource.parseEntries(
        didl,
        baseUrl: 'http://10.0.0.2:1400',
      );
      expect(items, hasLength(2));
      final hit = items.first;
      expect(hit.kind, LibraryKind.radio);
      expect(hit.subtitle, 'Sonos Radio');
      expect(hit.art, 'http://10.0.0.2:1400/getaa?s=1');
      expect(hit.playable, isTrue);
      expect(hit.expandable, isFalse);
      expect(
        (hit.raw! as Map)['uri'],
        'x-sonosapi-radio:sonos%3a2997?sid=303&flags=0',
      );
      expect(
        SonosLibrarySource.isStream((hit.raw! as Map)['uri'] as String),
        isTrue,
      );
      // A shortcut has nothing to play.
      expect(items.last.playable, isFalse);
    });
  });

  group('music by voice', () {
    LibraryItem item(String title, LibraryKind kind, [String by = '']) =>
        LibraryItem(id: title, kind: kind, title: title, subtitle: by);

    test('an exact title wins, an artist over a track of that name', () {
      final best = MusicRequests.bestMatch([
        LibraryShelf(
          key: 'tracks',
          items: [
            item('Punisher', LibraryKind.track, 'Phoebe Bridgers'),
            item('Punisher (Live)', LibraryKind.track, 'Phoebe Bridgers'),
          ],
        ),
        LibraryShelf(
          key: 'albums',
          items: [item('Punisher', LibraryKind.album, 'Phoebe Bridgers')],
        ),
      ], query: 'punisher')!;
      expect(best.item.kind, LibraryKind.album);
      expect(best.others.single.kind, LibraryKind.track);
    });

    test('with an artist named, other bands of that name stay out', () {
      final best = MusicRequests.bestMatch(
        [
          LibraryShelf(
            key: 'artists',
            items: [
              item('Punisher', LibraryKind.artist),
              item('Punisher', LibraryKind.artist),
            ],
          ),
          LibraryShelf(
            key: 'albums',
            items: [item('Punisher', LibraryKind.album, 'Phoebe Bridgers')],
          ),
          LibraryShelf(
            key: 'tracks',
            items: [item('Punisher', LibraryKind.track, 'Phoebe Bridgers')],
          ),
        ],
        query: 'Punisher',
        artist: 'Phoebe Bridgers',
      )!;
      expect(best.item.kind, LibraryKind.album);
      expect(best.others.map((o) => o.kind), [LibraryKind.track]);
    });

    test('a track in the library wins over a stranger of that name', () {
      final best = MusicRequests.bestMatch([
        LibraryShelf(key: 'artists', items: [item('Sola', LibraryKind.artist)]),
        LibraryShelf(
          key: 'tracks',
          items: [
            LibraryItem(
              id: 'library://track/9',
              kind: LibraryKind.track,
              title: 'Sola',
              subtitle: 'Hillkidd',
              inLibrary: true,
            ),
          ],
        ),
      ], query: 'Sola')!;
      expect(best.item.kind, LibraryKind.track);
      expect(best.item.inLibrary, isTrue);
    });

    test('a name heard as one word finds it written as two', () {
      final best = MusicRequests.bestMatch([
        LibraryShelf(
          key: 'artists',
          items: [item('Nightshift', LibraryKind.artist)],
        ),
        LibraryShelf(
          key: 'tracks',
          items: [
            LibraryItem(
              id: 'library://track/3',
              kind: LibraryKind.track,
              title: 'Night Shift',
              subtitle: 'Lucy Dacus',
              inLibrary: true,
            ),
          ],
        ),
      ], query: 'Nightshift')!;
      expect(best.item.title, 'Night Shift');
    });

    test('the kind and the artist narrow it down', () {
      final shelves = [
        LibraryShelf(
          key: 'tracks',
          items: [
            item('Blouse', LibraryKind.track, 'Someone Else'),
            item('Blouse', LibraryKind.track, 'Clairo'),
          ],
        ),
        LibraryShelf(
          key: 'albums',
          items: [item('Blouse', LibraryKind.album, 'Clairo')],
        ),
      ];
      final track = MusicRequests.bestMatch(
        shelves,
        query: 'Blouse',
        kind: 'track',
        artist: 'clairo',
      )!;
      expect(track.item.kind, LibraryKind.track);
      expect(track.item.subtitle, 'Clairo');
      expect(
        MusicRequests.bestMatch(shelves, query: 'x', kind: 'radio'),
        isNull,
      );
    });

    test('a genre with no title match takes the first track', () {
      final best = MusicRequests.bestMatch([
        LibraryShelf(
          key: 'playlists',
          items: [item('Chill Mix', LibraryKind.playlist)],
        ),
        LibraryShelf(
          key: 'tracks',
          items: [item('Lanterns', LibraryKind.track)],
        ),
      ], query: 'jazz')!;
      expect(best.item.title, 'Lanterns');
    });

    test('play lands on the speaker this kiosk follows', () async {
      SharedPreferences.setMockInitialValues({
        'ks.ha.url': '',
        'ks.ha.token': '',
        'ks.sendspin.ma_url': 'ma.local:8095',
        'ks.sendspin.ma_token': 'token',
        'ks.sendspin.client_id': 'tablet',
        'ks.sendspin.player_source': 'ma',
        'ks.sendspin.player': 'ma:kitchen',
        'ks.sendspin.player_name': 'Kitchen',
      });
      final c = AppContainer();
      await c.settings.init();
      final source = _VoiceSource();
      c.musicLibrary.sourceFactory = (_) => source;
      await c.musicLibrary.init();
      final r = await c.musicLibrary.requests.handle({
        'action': 'play',
        'query': 'Punisher',
        'artist': 'Phoebe Bridgers',
        'mode': 'next',
      });
      expect(r['ok'], isTrue, reason: '$r');
      expect(r['result'], 'playing_next');
      expect(r['title'], 'Punisher');
      expect(r['speaker'], 'Kitchen');
      expect(source.played.single, ('Punisher', PlayMode.next, 'ma:kitchen'));
      final none = await c.musicLibrary.requests.handle({
        'action': 'play',
        'query': 'Nothing like it',
        'kind': 'radio',
      });
      expect(none['ok'], isFalse);
      expect(none['error'], 'nothing_found');
      // Both requests count for usage analytics, the Play next that went
      // through as a queue add.
      final counts = UsageCounters.read(c.settings);
      expect(counts['library_voice_requests'], 2);
      expect(counts['library_queue_adds'], 1);
    });
  });

  test('a genre gets an icon from its name, a note when nothing fits', () {
    expect(genreIcon('Hip-Hop'), Icons.mic_rounded);
    expect(genreIcon('Classical'), Icons.piano_rounded);
    expect(genreIcon('Composer'), Icons.piano_rounded);
    expect(genreIcon('Dance'), Icons.celebration_rounded);
    expect(genreIcon('Synthpop'), Icons.graphic_eq_rounded);
    expect(genreIcon('Indie Rock'), Icons.bolt_rounded);
    expect(genreIcon('Folk'), Icons.mic_external_on_rounded);
    expect(genreIcon('Acoustic'), Icons.waves_rounded);
    expect(genreIcon('Country'), Icons.music_note_rounded);
    expect(genreIcon('K-Pop'), Icons.auto_awesome_rounded);
    expect(genreIcon('Unknown'), Icons.music_note_rounded);
  });

  test('a translated genre gets its icon from the English sort name', () {
    LibraryItem genre(String title, [Object? raw]) => LibraryItem(
      id: 'library://genre/1',
      kind: LibraryKind.genre,
      title: title,
      raw: raw,
    );
    expect(
      genreIconFor(genre('Elektronisch', const {'sort_name': 'electronic'})),
      Icons.graphic_eq_rounded,
    );
    expect(genreIconFor(genre('Electronic')), Icons.graphic_eq_rounded);
    expect(
      genreIconFor(genre('Hip-Hop', const {'sort_name': ''})),
      Icons.mic_rounded,
    );
  });

  group('the overlay', () {
    final album = LibraryItem(
      id: 'library://album/1',
      kind: LibraryKind.album,
      title: 'Glass Harbor',
      subtitle: 'Juniper Lane',
      expandable: true,
      raw: const {'year': 2024},
    );

    Future<AppContainer> container({
      LibrarySource? source,
      int textScale = 100,
      bool ha = false,
    }) async {
      SharedPreferences.setMockInitialValues({
        'ks.library.text_scale': textScale,
        'ks.ha.url': ha ? 'http://ha.local:8123' : '',
        'ks.ha.token': ha ? 'token' : '',
        'ks.sendspin.ma_url': 'ma.local:8095',
        'ks.sendspin.ma_token': 'token',
        'ks.sendspin.client_id': 'tablet',
        // Now Playing on, so the player bar draws its every button.
        'ks.sendspin.fullscreen': true,
      });
      final c = AppContainer();
      await c.settings.init();
      c.musicLibrary.sourceFactory = (_) => source ?? _FakeSource(album);
      // No test reaches a real Music Assistant.
      c.sendspin.apiFactory = ({required baseUrl, required token}) =>
          _QueueApi();
      await c.musicLibrary.init();
      return c;
    }

    for (final (name, size) in [
      ('a tablet', const Size(1280, 800)),
      ('a tablet in portrait', const Size(753, 1205)),
      ('an Echo Show 5', const Size(960, 480)),
      ('an Echo Show 5 at 1.22x', const Size(788, 394)),
      ('a phone', const Size(390, 844)),
    ]) {
      testWidgets('Discover and an album draw on $name', (tester) async {
        final c = await container();
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        c.musicLibrary.visible.value = true;
        // A track playing, so the player bar draws every control.
        c.sendspin.nowPlaying.value = {
          'title': 'A long track title that goes on for a while',
          'artist': 'Juniper Lane',
          'playing': true,
          'durationMs': 200000,
          'positionMs': 60000,
          'receivedAt': DateTime.now().millisecondsSinceEpoch,
          'shuffle': false,
          'repeat': 'off',
          'supportedCommands': const <String>[],
        };
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(children: [MusicLibraryOverlay(container: c)]),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        expect(find.text('Glass Harbor'), findsWidgets);
        // A shelf that mixes kinds says what each entry is.
        expect(find.text('Track · Juniper Lane'), findsOneWidget);
        expect(find.text('Album · Juniper Lane'), findsOneWidget);
        // Below the fold on a short screen, so not built there.
        if (size.height >= 600) {
          expect(find.text('Browse by genre'), findsOneWidget);
          // A long word shrinks to fit its tile instead of breaking.
          double fontSize(String text) =>
              tester.widget<Text>(find.text(text).first).style!.fontSize!;
          expect(fontSize('Elektronisch'), lessThan(fontSize('Folk')));
        }
        await tester.tap(find.text('Glass Harbor').first);
        await tester.pump(const Duration(milliseconds: 100));
        // The album loads after the frame that asked for it.
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: 'album on $name');
        expect(find.text('Track 1'), findsOneWidget);
        // Back steps out of the album before it closes the library.
        expect(c.musicLibrary.backHandler?.call(), isTrue);
        await tester.pump(const Duration(milliseconds: 100));
        expect(c.musicLibrary.backHandler?.call(), isFalse);
        c.musicLibrary.visible.value = false;
        c.sendspin.nowPlaying.value = null;
        await tester.pump();
      });
    }

    for (final (name, size) in [
      ('a tablet', const Size(1280, 800)),
      ('a phone', const Size(390, 844)),
    ]) {
      testWidgets('a list sorts and keeps its order on $name', (tester) async {
        final source = _FakeSource(album);
        final c = await container(source: source);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        c.musicLibrary.visible.value = true;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(children: [MusicLibraryOverlay(container: c)]),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Sort'), findsNothing);
        if (size.width < 600) {
          await tester.tap(find.text('Library'));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text('Artists').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Artists').first);
        await tester.pumpAndSettle();
        expect(source.listed.last, ('artists', LibrarySort.name, false));

        await tester.tap(find.byTooltip('Sort'));
        await tester.pumpAndSettle();
        expect(find.text('Album artists only'), findsOneWidget);
        await tester.tap(find.text('Recently played'));
        await tester.pumpAndSettle();
        expect(source.listed.last, (
          'artists',
          LibrarySort.recentlyPlayed,
          false,
        ));

        await tester.tap(find.byTooltip('Sort'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Album artists only'));
        await tester.pumpAndSettle();
        expect(source.listed.last, (
          'artists',
          LibrarySort.recentlyPlayed,
          true,
        ));
        expect(tester.takeException(), isNull);

        // Albums keeps its own order and has no album artist filter.
        await tester.ensureVisible(find.text('Albums').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Albums').first);
        await tester.pumpAndSettle();
        expect(source.listed.last, ('albums', LibrarySort.name, false));
        await tester.tap(find.byTooltip('Sort'));
        await tester.pumpAndSettle();
        expect(find.text('Album artists only'), findsNothing);
        await tester.tap(find.text('Z to A'));
        await tester.pumpAndSettle();
        expect(source.listed.last, ('albums', LibrarySort.nameDesc, false));
        expect(
          c.musicLibrary.sortFor(
            source,
            const LibraryCategory('artists', LibraryKind.artist),
          ),
          LibrarySort.recentlyPlayed,
        );
        c.musicLibrary.visible.value = false;
        await tester.pump();
      });
    }

    for (final (name, size) in [
      ('a tablet', const Size(1280, 800)),
      ('a tablet in portrait', const Size(753, 1205)),
      ('an Echo Show 5', const Size(960, 480)),
      ('a phone', const Size(390, 844)),
    ]) {
      for (final scale in [50, 200]) {
        testWidgets('text at $scale% fits on $name', (tester) async {
          final c = await container(textScale: scale);
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          c.musicLibrary.visible.value = true;
          c.sendspin.nowPlaying.value = {
            'title': 'A long track title that goes on for a while',
            'artist': 'Juniper Lane',
            'playing': true,
            'durationMs': 200000,
            'positionMs': 60000,
            'receivedAt': DateTime.now().millisecondsSinceEpoch,
            'shuffle': false,
            'repeat': 'off',
            'supportedCommands': const <String>[],
          };
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Stack(children: [MusicLibraryOverlay(container: c)]),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull, reason: 'Discover');
          // The Albums grid.
          c.musicLibrary.opening = (query: null, category: 'albums');
          c.musicLibrary.reopened.value++;
          await tester.pump(const Duration(milliseconds: 200));
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull, reason: 'Albums');
          expect(find.text('Glass Harbor'), findsWidgets);
          // An album.
          await tester.tap(find.text('Glass Harbor').first);
          await tester.pump(const Duration(milliseconds: 200));
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull, reason: 'the album');
          // The Speakers sheet, a route of its own.
          c.musicLibrary.backHandler?.call();
          await tester.pumpAndSettle();
          await tester.tap(find.bySemanticsLabel(RegExp(r'^Speakers: ')).first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Speakers');
          await tester.tapAt(const Offset(4, 4));
          await tester.pumpAndSettle();
          // The sort menu.
          await tester.tap(find.byTooltip('Sort'));
          await tester.pumpAndSettle();
          expect(find.text('Most played'), findsOneWidget);
          expect(tester.takeException(), isNull, reason: 'the sort menu');
          await tester.tapAt(const Offset(4, 4));
          await tester.pumpAndSettle();
          // The queue.
          await tester.tap(find.byTooltip('Show queue').first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'the queue');
          c.musicLibrary.visible.value = false;
          c.sendspin.nowPlaying.value = null;
          await tester.pump(const Duration(seconds: 1));
        });
      }
    }

    testWidgets('a play shows what it starts until the player reports it', (
      tester,
    ) async {
      final c = await container();
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      c.musicLibrary.visible.value = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(children: [MusicLibraryOverlay(container: c)]),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      c.musicLibrary.pick.value = 'ma:living';
      // Queuing changes nothing that plays: no wait.
      await c.musicLibrary.play(album, PlayMode.add);
      expect(c.musicLibrary.starting.value, isNull);
      await c.musicLibrary.play(album, PlayMode.replace);
      expect(c.musicLibrary.starting.value, album);
      await tester.pump();
      // The bar names it at once, and the cover spins.
      expect(find.text('Loading…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      // The player's report ends the wait.
      c.sendspin.nowPlaying.value = {
        'title': 'Glass Harbor',
        'artist': 'Juniper Lane',
        'playing': true,
      };
      expect(c.musicLibrary.starting.value, isNull);
      await tester.pump();
      expect(find.text('Loading…'), findsNothing);
      // A player that never reports lets go after a while.
      await c.musicLibrary.play(album, PlayMode.now);
      expect(c.musicLibrary.starting.value, album);
      // Two plays by their source, one queue add, for usage analytics.
      final counts = UsageCounters.read(c.settings);
      expect(counts['library_queue_adds'], 1);
      expect(
        counts.entries
            .where((e) => e.key.startsWith('library_plays_'))
            .map((e) => e.value),
        [2],
      );
      await tester.pump(const Duration(seconds: 16));
      expect(c.musicLibrary.starting.value, isNull);
      c.musicLibrary.visible.value = false;
      c.sendspin.nowPlaying.value = null;
      await tester.pump(const Duration(seconds: 7));
    });

    // Each layout draws the source its own way: a box over the side
    // navigation, a button atop the rail and a pill in the header.
    for (final (name, size, picker) in [
      ('a tablet', const Size(1280, 800), find.text('Source')),
      ('an Echo Show 5', const Size(960, 480), find.byTooltip('Source')),
      ('a phone', const Size(390, 844), find.text('Music Assistant')),
    ]) {
      testWidgets('Show source selection hides the picker on $name', (
        tester,
      ) async {
        final c = await container(ha: true);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        c.musicLibrary.visible.value = true;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(children: [MusicLibraryOverlay(container: c)]),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(picker.first);
        await tester.pumpAndSettle();
        expect(find.byType(SimpleDialog), findsOneWidget);
        await tester.tap(find.text('Home Assistant').last);
        await tester.pumpAndSettle();
        expect(c.settings.get(defs.librarySource), 'ha');
        // Turned off while the library is open, as from the remote admin.
        await c.settings.set(defs.librarySourcePicker, false);
        await tester.pumpAndSettle();
        expect(find.text('Source'), findsNothing);
        expect(find.byTooltip('Source'), findsNothing);
        expect(find.text('Home Assistant'), findsNothing);
        c.musicLibrary.visible.value = false;
        await tester.pump();
      });
    }

    // The speaker pill sits in the header on a tablet and an Echo Show 5
    // and in the row under it on a phone.
    for (final (name, size) in [
      ('a tablet', const Size(1280, 800)),
      ('an Echo Show 5', const Size(960, 480)),
      ('a phone', const Size(390, 844)),
    ]) {
      testWidgets('Show speaker selection pill hides the pill on $name', (
        tester,
      ) async {
        final c = await container(ha: true);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        c.musicLibrary.visible.value = true;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(children: [MusicLibraryOverlay(container: c)]),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.speaker_outlined), findsOneWidget);
        // Turned off while the library is open, as from the remote admin.
        await c.settings.set(defs.librarySpeakerPill, false);
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.speaker_outlined), findsNothing);
        // With the source picker off too the phone drops the empty row.
        await c.settings.set(defs.librarySourcePicker, false);
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.speaker_outlined), findsNothing);
        expect(tester.takeException(), isNull);
        c.musicLibrary.visible.value = false;
        await tester.pump();
      });
    }

    testWidgets('each grid density step changes the tile size', (tester) async {
      final source = _FakeSource(album);
      final c = await container(source: source);
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      c.musicLibrary.visible.value = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(children: [MusicLibraryOverlay(container: c)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Albums').first);
      await tester.pumpAndSettle();
      // Changed while the list is open, as from the remote admin.
      Future<double> tile(String density) async {
        await c.settings.set(defs.libraryGridDensity, density);
        await tester.pumpAndSettle();
        return tester.getSize(find.byType(LibraryArt).first).width;
      }

      final standard = await tile('standard');
      final compact = await tile('compact');
      final comfortable = await tile('comfortable');
      expect(compact, lessThan(standard));
      expect(comfortable, greaterThan(standard));
      c.musicLibrary.visible.value = false;
      await tester.pump();
    });

    for (final (name, close) in [
      (
        'a screensaver starts',
        (AppContainer c) {
          c.screensaver.activeView.value = 'clock';
        },
      ),
      (
        'the library closes',
        (AppContainer c) {
          c.musicLibrary.visible.value = false;
        },
      ),
    ]) {
      testWidgets('the Speakers sheet goes when $name', (tester) async {
        final c = await container();
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        c.musicLibrary.visible.value = true;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(children: [MusicLibraryOverlay(container: c)]),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.bySemanticsLabel(RegExp(r'^Speakers: ')));
        await tester.pumpAndSettle();
        expect(find.text('Speakers'), findsOneWidget);
        close(c);
        await tester.pumpAndSettle();
        expect(find.text('Speakers'), findsNothing);
        c.screensaver.activeView.value = null;
        c.musicLibrary.visible.value = false;
        await tester.pump();
      });
    }

    for (final (name, size) in [
      ('a tablet', const Size(1280, 800)),
      ('a phone', const Size(390, 844)),
    ]) {
      testWidgets('the queue opens, reorders and removes on $name', (
        tester,
      ) async {
        final c = await container();
        final api = _QueueApi();
        c.sendspin.apiFactory = ({required baseUrl, required token}) => api;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        c.musicLibrary.visible.value = true;
        c.sendspin.nowPlaying.value = {
          'title': 'Track A',
          'artist': 'Juniper Lane',
          'playing': false,
          'durationMs': 200000,
          'positionMs': 0,
        };
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(children: [MusicLibraryOverlay(container: c)]),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byTooltip('Show queue'));
        await tester.pumpAndSettle();
        expect(find.text('Queue'), findsOneWidget);
        expect(find.text('Track B'), findsOneWidget);
        expect(find.text('Track D'), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Swipe a row away: Music Assistant deletes it.
        await tester.drag(find.text('Track C'), const Offset(-600, 0));
        await tester.pumpAndSettle();
        expect(api.calls, contains('player_queues/delete_item'));
        expect(
          api.args['player_queues/delete_item'],
          containsPair('item_id_or_index', 'c'),
        );
        // Clear asks first.
        await tester.tap(find.text('Clear').first);
        await tester.pumpAndSettle();
        expect(find.text('Clear the queue?'), findsOneWidget);
        await tester.tap(find.text('Clear').last);
        await tester.pumpAndSettle();
        expect(api.calls, contains('player_queues/clear'));
        c.musicLibrary.visible.value = false;
        c.sendspin.nowPlaying.value = null;
        await tester.pump(const Duration(seconds: 1));
      });
    }

    testWidgets('with nothing playing the bar shows the queue to resume', (
      tester,
    ) async {
      final c = await container();
      final api = _QueueApi();
      c.sendspin.apiFactory = ({required baseUrl, required token}) => api;
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      c.musicLibrary.visible.value = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(children: [MusicLibraryOverlay(container: c)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nothing playing'), findsNothing);
      expect(find.text('Track A'), findsOneWidget);
      // Play resumes the queue on its current track, with a ring around
      // the button until the player reports it.
      final before = tester.getRect(find.byTooltip('Play').last);
      final next = tester.getRect(find.byTooltip('Next track').last);
      await tester.tap(find.byTooltip('Play').last);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The ring takes no room: nothing around the button moves.
      expect(tester.getRect(find.byTooltip('Play').last), before);
      expect(tester.getRect(find.byTooltip('Next track').last), next);
      await tester.pumpAndSettle();
      expect(api.calls, contains('player_queues/play_index'));
      expect(api.args['player_queues/play_index'], containsPair('index', 'a'));
      c.musicLibrary.visible.value = false;
      await tester.pump(const Duration(seconds: 1));
    });
  });
}

class _QueueApi extends MusicAssistantApi {
  _QueueApi() : super(baseUrl: 'ma.local', token: 't');

  final calls = <String>[];
  final args = <String, Map<String, Object?>>{};

  @override
  Future<MusicAssistantResult> call(
    String command, {
    Map<String, Object?> args = const {},
    Duration timeout = const Duration(seconds: 15),
  }) async {
    calls.add(command);
    this.args[command] = args;
    Map<String, Object?> item(String id) => {
      'queue_item_id': id,
      'duration': 200,
      'media_item': {
        'name': 'Track ${id.toUpperCase()}',
        'artists': [
          {'name': 'Juniper Lane'},
        ],
      },
    };
    final Object? result = switch (command) {
      'player_queues/get_active_queue' => {
        'queue_id': 'q1',
        'current_index': 0,
        'items': 4,
        'current_item': {'queue_item_id': 'a'},
      },
      'player_queues/items' => [
        for (final id in ['a', 'b', 'c', 'd']) item(id),
      ],
      _ => null,
    };
    return MusicAssistantResult.success(result, const {});
  }
}

class _FakeSource extends LibrarySource {
  _FakeSource(this.album);

  final LibraryItem album;

  @override
  String get key => 'ma';

  @override
  bool get hasDiscover => true;

  @override
  bool get hasSearch => true;

  @override
  bool needsSpeaker(String pick) => false;

  @override
  List<LibraryCategory> get categories => const [
    LibraryCategory('albums', LibraryKind.album),
    LibraryCategory('tracks', LibraryKind.track),
    LibraryCategory('artists', LibraryKind.artist),
  ];

  @override
  List<LibrarySort> get sorts => LibrarySort.values;

  @override
  bool get hasAlbumArtists => true;

  /// Each list asked for: the category, the order and album artists only.
  final listed = <(String, LibrarySort?, bool)>[];

  @override
  Future<LibraryPage> list(
    LibraryCategory category, {
    int offset = 0,
    bool favorites = false,
    LibrarySort? sort,
    bool albumArtists = false,
  }) async {
    listed.add((category.key, sort, albumArtists));
    return LibraryPage(items: [album]);
  }

  @override
  Future<List<LibraryShelf>> discover() async => [
    LibraryShelf(key: 'recent', items: [album]),
    LibraryShelf(
      title: 'From the server',
      items: [
        album,
        const LibraryItem(
          id: 'library://track/9',
          kind: LibraryKind.track,
          title: 'Tidelines',
          subtitle: 'Juniper Lane',
        ),
      ],
    ),
    LibraryShelf(
      key: 'genres',
      items: [
        for (final name in ['Dance', 'Electronic', 'Folk', 'Jazz'])
          LibraryItem(
            id: 'library://genre/$name',
            kind: LibraryKind.genre,
            title: name,
            expandable: true,
          ),

        // A translated name with one long word.
        const LibraryItem(
          id: 'library://genre/electronic_de',
          kind: LibraryKind.genre,
          title: 'Elektronisch',
          expandable: true,
          raw: {'sort_name': 'electronic'},
        ),
      ],
    ),
  ];

  @override
  Future<LibraryDetail> open(LibraryItem item) async => LibraryDetail(
    item: item,
    year: 2024,
    tracks: [
      for (var i = 1; i <= 12; i++)
        LibraryItem(
          id: 't$i',
          kind: LibraryKind.track,
          title: 'Track $i',
          subtitle: 'Juniper Lane',
          durationMs: 200000,
        ),
    ],
  );

  @override
  Future<String?> play(
    LibraryItem item,
    PlayMode mode, {
    required String pick,
    LibraryItem? within,
  }) async => null;
}

class _VoiceSource extends LibrarySource {
  final played = <(String, PlayMode, String)>[];

  @override
  String get key => 'ma';

  @override
  bool get hasSearch => true;

  @override
  Future<List<LibraryShelf>> search(String query) async => [
    LibraryShelf(
      key: 'tracks',
      items: [
        LibraryItem(
          id: 'library://track/1',
          kind: LibraryKind.track,
          title: 'Punisher',
          subtitle: 'Phoebe Bridgers',
        ),
      ],
    ),
  ];

  @override
  Future<LibraryDetail> open(LibraryItem item) async =>
      LibraryDetail(item: item);

  @override
  Future<String?> play(
    LibraryItem item,
    PlayMode mode, {
    required String pick,
    LibraryItem? within,
  }) async {
    played.add((item.title, mode, pick));
    return null;
  }
}
