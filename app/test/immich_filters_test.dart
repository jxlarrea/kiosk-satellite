import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/immich_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Immich screensaver's filters (issue #345) against a local fake
/// server: each one has to reach the metadata search as the field Immich
/// reads, the people and tag filters have to mean "any of these", and an
/// excluded person has to drop the photos they are in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The test binding stubs every HttpClient to answer 400 without any
  // network; these tests talk to a real loopback server instead.
  setUpAll(() => HttpOverrides.global = null);

  late HttpServer server;
  late SettingsManager settings;
  late CommandRegistry commands;
  late ImmichManager immich;

  /// Every search body the server received, in order.
  final searches = <Map<String, dynamic>>[];

  /// The library: id, with the people in each photo. A search answers the
  /// assets matching its personIds (all of them), tagIds, isFavorite and
  /// takenAfter, newest first by the index in this list.
  var library = <Map<String, Object?>>[
    {
      'id': 'a',
      'people': <String>['alice'],
      'tags': <String>['t1'],
      'albums': <String>['alb1'],
    },
    {
      'id': 'b',
      'people': <String>['bob'],
      'tags': <String>[],
      'albums': <String>['alb2'],
    },
    {
      'id': 'c',
      'people': <String>['alice', 'bob'],
      'tags': <String>['t2'],
      'albums': <String>['alb1', 'alb2'],
    },
    {
      'id': 'd',
      'people': <String>[],
      'tags': <String>[],
      'albums': <String>[],
      'favorite': true,
    },
  ];
  var peopleStatus = 200;
  var peoplePages = <List<Map<String, Object?>>>[
    [
      {'id': 'bob', 'name': 'Bob'},
      {'id': 'alice', 'name': 'Alice'},
      {'id': 'x', 'name': ''},
      {'id': 'hidden', 'name': 'Hidden', 'isHidden': true},
    ],
  ];

  setUp(() async {
    searches.clear();
    peopleStatus = 200;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path;
      final response = request.response;
      response.headers.contentType = ContentType.json;
      if (path == '/api/search/metadata') {
        final body =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        searches.add(body);
        final wantAlbums = (body['albumIds'] as List?)?.cast<String>();
        final wantPeople = (body['personIds'] as List?)?.cast<String>();
        final wantTags = (body['tagIds'] as List?)?.cast<String>();
        final after = body['takenAfter'] == null
            ? null
            : DateTime.parse(body['takenAfter'] as String);
        final items = <Map<String, Object?>>[];
        var index = 0;
        for (final asset in library) {
          final people = (asset['people'] as List).cast<String>();
          final tags = (asset['tags'] as List).cast<String>();
          final albums = ((asset['albums'] as List?) ?? const [])
              .cast<String>();
          final taken =
              (asset['taken'] as DateTime?) ?? DateTime.utc(2026, 1, 1);
          final matches =
              (wantAlbums == null || wantAlbums.every(albums.contains)) &&
              (wantPeople == null || wantPeople.every(people.contains)) &&
              (wantTags == null || wantTags.every(tags.contains)) &&
              (body['isFavorite'] != true || asset['favorite'] == true) &&
              (after == null || taken.isAfter(after));
          if (matches) {
            items.add({
              'id': asset['id'],
              'type': 'IMAGE',
              'fileCreatedAt':
                  '2026-01-${(30 - index).toString().padLeft(2, '0')}T00:00:00.000Z',
              if (body['withPeople'] == true)
                'people': [
                  for (final id in people) {'id': id, 'name': id},
                ],
            });
          }
          index++;
        }
        response.write(
          jsonEncode({
            'assets': {'items': items, 'nextPage': null},
          }),
        );
      } else if (path == '/api/people') {
        response.statusCode = peopleStatus;
        if (peopleStatus != 200) {
          response.write(jsonEncode({'message': 'Forbidden'}));
        } else {
          final page = int.parse(request.uri.queryParameters['page'] ?? '1');
          response.write(
            jsonEncode({
              'people': peoplePages[page - 1],
              'total': 4,
              'hasNextPage': page < peoplePages.length,
            }),
          );
        }
      } else if (path == '/api/albums' &&
          request.uri.queryParameters['assetId'] != null) {
        final id = request.uri.queryParameters['assetId'];
        final asset = library.firstWhere((a) => a['id'] == id);
        response.write(
          jsonEncode([
            for (final album in (asset['albums'] as List).cast<String>())
              {'id': album, 'albumName': 'Album $album'},
          ]),
        );
      } else if (path.startsWith('/api/assets/')) {
        response.write(jsonEncode({'id': path.split('/')[3], 'exifInfo': {}}));
      } else if (path == '/api/tags') {
        response.write(
          jsonEncode([
            {'id': 't2', 'name': 'Kids', 'value': 'Family/Kids'},
            {'id': 't1', 'name': 'Family', 'value': 'Family'},
          ]),
        );
      } else {
        response.statusCode = 404;
      }
      await response.close();
    });

    SharedPreferences.setMockInitialValues({
      'ks.screensaver.immich_url': 'http://127.0.0.1:${server.port}',
      'ks.screensaver.immich_api_key': 'test-key',
      'ks.screensaver.immich_cache': false,
    });
    final bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    immich = ImmichManager(bus, commands, log, settings);
    await immich.init();
  });

  tearDown(() => server.close(force: true));

  List<String> ids(List<ImmichAsset> assets) => [for (final a in assets) a.id];

  test('no filter is one plain search, nothing extra in the body', () async {
    expect(ids(await immich.listAssets()), ['a', 'b', 'c', 'd']);
    expect(searches, hasLength(1));
    expect(searches.single.keys, isNot(contains('personIds')));
    expect(searches.single.keys, isNot(contains('tagIds')));
    expect(searches.single.keys, isNot(contains('isFavorite')));
    expect(searches.single.keys, isNot(contains('takenAfter')));
    expect(searches.single.keys, isNot(contains('withPeople')));
  });

  test('several albums mean any of them: one search each, merged', () async {
    await settings.set(
      defs.screensaverImmichAlbum,
      jsonEncode([
        {'id': 'alb1', 'name': 'One'},
        {'id': 'alb2', 'name': 'Two'},
      ]),
    );
    // A list of albumIds is read strictly by the fake server, as the
    // people list is by Immich; the union has to come out either way.
    expect(ids(await immich.listAssets()), ['a', 'b', 'c']);
    expect(searches.map((s) => s['albumIds']), [
      ['alb1'],
      ['alb2'],
    ]);
  });

  test('a bare album id from an older install becomes a named pick', () async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.immich_url': 'http://127.0.0.1:${server.port}',
      'ks.screensaver.immich_api_key': 'test-key',
      'ks.screensaver.immich_cache': false,
      'ks.screensaver.immich_album': 'alb2',
      'ks.screensaver.immich_album_name': 'Two',
    });
    final bus = EventBus();
    final log = Logger();
    final registry = CommandRegistry(log);
    final old = SettingsManager(bus, registry, log);
    await old.init();
    final manager = ImmichManager(bus, registry, log, old);
    await manager.init();
    // The listener that fills the name runs off the bus.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(jsonDecode(old.get(defs.screensaverImmichAlbum)), [
      {'id': 'alb2', 'name': 'Two'},
    ]);
    expect(ids(await manager.listAssets()), ['b', 'c']);
  });

  test('a one-album import with its name arriving second is named', () async {
    await settings.import({
      'screensaver.immich_album': 'alb1',
      'screensaver.immich_album_name': 'One',
    });
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(jsonDecode(settings.get(defs.screensaverImmichAlbum)), [
      {'id': 'alb1', 'name': 'One'},
    ]);
  });

  test('the metadata album line prefers a picked album', () async {
    await settings.set(defs.screensaverImmichMetadata, true);
    // Two picks: the line has to come from the server's answer, with the
    // picked album winning over another the asset is also in.
    await settings.set(
      defs.screensaverImmichAlbum,
      jsonEncode([
        {'id': 'alb2', 'name': 'Two'},
        {'id': 'zzz', 'name': 'Other'},
      ]),
    );
    final details = await immich.assetDetails(
      const ImmichAsset(id: 'c', isVideo: false),
    );
    expect(details['album'], 'Album alb2');
    // One pick: its stored name, no request needed.
    await settings.set(
      defs.screensaverImmichAlbum,
      jsonEncode([
        {'id': 'alb1', 'name': 'One'},
      ]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final single = await immich.assetDetails(
      const ImmichAsset(id: 'c', isVideo: false),
    );
    expect(single['album'], 'One');
  });

  test('people means any of them: one search each, merged by id', () async {
    await settings.set(
      defs.screensaverImmichPeople,
      jsonEncode([
        {'id': 'alice', 'name': 'Alice'},
        {'id': 'bob', 'name': 'Bob'},
      ]),
    );
    final assets = await immich.listAssets();
    // Immich reads two personIds as "both in the photo", which would be c
    // alone; the frame wants a or b or c, shown once each, newest first.
    expect(ids(assets), ['a', 'b', 'c']);
    expect(searches.map((s) => s['personIds']), [
      ['alice'],
      ['bob'],
    ]);
  });

  test('excluded people are dropped from the answer', () async {
    await settings.set(
      defs.screensaverImmichExcludePeople,
      jsonEncode([
        {'id': 'bob', 'name': 'Bob'},
      ]),
    );
    expect(ids(await immich.listAssets()), ['a', 'd']);
    // The API cannot exclude, so every asset comes back with its people.
    expect(searches.single['withPeople'], isTrue);
    expect(searches.single.keys, isNot(contains('personIds')));
  });

  test('tags combine with people, still any of each', () async {
    await settings.set(
      defs.screensaverImmichPeople,
      jsonEncode([
        {'id': 'alice', 'name': 'Alice'},
      ]),
    );
    await settings.set(
      defs.screensaverImmichTags,
      jsonEncode([
        {'id': 't1', 'name': 'Family'},
        {'id': 't2', 'name': 'Family/Kids'},
      ]),
    );
    expect(ids(await immich.listAssets()), ['a', 'c']);
    expect(searches, hasLength(2));
    expect(searches.map((s) => s['tagIds']), [
      ['t1'],
      ['t2'],
    ]);
    expect(
      searches.every((s) => s['personIds'].toString() == '[alice]'),
      isTrue,
    );
  });

  test('favorites only is the search\'s own flag', () async {
    await settings.set(defs.screensaverImmichFavoritesOnly, true);
    expect(ids(await immich.listAssets()), ['d']);
    expect(searches.single['isFavorite'], isTrue);
  });

  test('taken within sends the cutoff and the server keeps the rest', () async {
    library = [
      {
        'id': 'old',
        'people': <String>[],
        'tags': <String>[],
        'taken': DateTime.now().toUtc().subtract(const Duration(days: 400)),
      },
      {
        'id': 'new',
        'people': <String>[],
        'tags': <String>[],
        'taken': DateTime.now().toUtc().subtract(const Duration(days: 10)),
      },
    ];
    await settings.set(defs.screensaverImmichTakenWithin, '365');
    expect(ids(await immich.listAssets()), ['new']);
    final sent = DateTime.parse(searches.single['takenAfter'] as String);
    final expected = DateTime.now().toUtc().subtract(const Duration(days: 365));
    expect(sent.difference(expected).inMinutes.abs(), lessThan(5));
    expect(immichFiltersActive(settings), isTrue);
  });

  test('the "Taken within" choices all read as a day count', () {
    for (final option in defs.immichTakenWithinOptions) {
      expect(defs.immichTakenWithinLabels, contains(option));
      if (option.isEmpty) continue;
      expect(int.parse(option), greaterThan(0));
    }
    expect(immichTakenAfter(settings), isNull);
    expect(immichFiltersActive(settings), isFalse);
  });

  test('immichPeople lists named, unhidden people alphabetically', () async {
    final result = await commands.execute('immichPeople', const {});
    expect(result.ok, isTrue);
    expect(result.data, [
      {'id': 'alice', 'name': 'Alice'},
      {'id': 'bob', 'name': 'Bob'},
    ]);
  });

  test('immichPeople follows the server\'s pages', () async {
    peoplePages = [
      [
        {'id': 'zed', 'name': 'Zed'},
      ],
      [
        {'id': 'amy', 'name': 'Amy'},
      ],
    ];
    final result = await commands.execute('immichPeople', const {});
    expect(result.data, [
      {'id': 'amy', 'name': 'Amy'},
      {'id': 'zed', 'name': 'Zed'},
    ]);
  });

  test('immichPeople names the person.read permission when denied', () async {
    peopleStatus = 403;
    final result = await commands.execute('immichPeople', const {});
    expect(result.ok, isFalse);
    expect(result.error, 'The API key is missing the person.read permission.');
  });

  test('immichTags lists tags by their full path', () async {
    final result = await commands.execute('immichTags', const {});
    expect(result.ok, isTrue);
    expect(result.data, [
      {'id': 't1', 'name': 'Family'},
      {'id': 't2', 'name': 'Family/Kids'},
    ]);
  });

  test('a malformed filter setting reads as no filter', () {
    expect(decodeImmichNamed('not json'), isEmpty);
    expect(decodeImmichNamed('{"id": "x"}'), isEmpty);
    expect(
      decodeImmichNamed('[{"id": "x", "name": "X"}, {"name": "no id"}, 3]'),
      hasLength(1),
    );
  });
}
