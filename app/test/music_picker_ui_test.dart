import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/music_library/library_model.dart';
import 'package:kiosk_satellite/managers/music_library/music_pick.dart';
import 'package:kiosk_satellite/ui/music_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The music picker on a tablet, an Echo Show 5 and a phone: it lists the
/// source's music, picks an entry or a random draw, opens an album to
/// pick its whole or one track, and answers the pick with the speaker.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppContainer> container() async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': '',
      'ks.ha.token': '',
      'ks.sendspin.ma_url': 'ma.local:8095',
      'ks.sendspin.ma_token': 'token',
      'ks.sendspin.client_id': 'tablet',
      'ks.sendspin.enabled': true,
      'ks.device.name': 'Hallway',
    });
    final c = AppContainer();
    await c.settings.init();
    c.musicLibrary.sourceFactory = (_) => _Source();
    await c.musicLibrary.init();
    return c;
  }

  for (final (name, size) in [
    ('a tablet', const Size(1280, 800)),
    ('an Echo Show 5', const Size(960, 480)),
    ('a phone', const Size(390, 844)),
  ]) {
    testWidgets('a playlist, shuffled, on $name', (tester) async {
      final c = await container();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      MusicPick? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    result = await showMusicPicker(context, c),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.text('Choose music'), findsOneWidget);
      expect(find.text('Sunday Morning'), findsOneWidget);
      expect(find.text('Hallway'), findsOneWidget);
      await tester.tap(find.text('Sunday Morning'));
      await tester.pump();
      // The footer says what is picked, and Shuffle turns on for it.
      expect(find.text('Sunday Morning'), findsNWidgets(2));
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      expect(result?.item?.id, 'library://playlist/7');
      expect(result?.shuffle, isTrue);
      expect(result?.speaker, '');
      expect(result?.speakerName, 'Hallway');
    });

    testWidgets('an album opened, one track picked, on $name', (tester) async {
      final c = await container();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      MusicPick? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    result = await showMusicPicker(context, c),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Albums').first);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byTooltip('Open Glass Harbor'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.text('Whole album'), findsOneWidget);
      await tester.tap(find.text('Tidelines'));
      await tester.pump();
      // One track has nothing to shuffle.
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      expect(result?.item?.title, 'Tidelines');
      expect(result?.canShuffle, isFalse);
    });

    testWidgets('a random draw on $name', (tester) async {
      final c = await container();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      MusicPick? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    result = await showMusicPicker(context, c),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Random').first);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Any playlist'));
      await tester.pump();
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      expect(result?.random, RandomPick.playlists);
      expect(result?.item, isNull);
    });
  }
}

class _Source extends LibrarySource {
  @override
  String get key => 'ma';

  @override
  bool get hasSearch => true;

  @override
  bool get hasFavorites => true;

  @override
  bool needsSpeaker(String pick) => false;

  /// New objects on every read, the way Music Assistant's source builds
  /// them: the picker must match its lists by key.
  @override
  List<LibraryCategory> get categories => [
    for (final (key, kind) in const [
      ('playlists', LibraryKind.playlist),
      ('albums', LibraryKind.album),
      ('tracks', LibraryKind.track),
    ])
      LibraryCategory(key, kind),
  ];

  @override
  Future<LibraryPage> list(
    LibraryCategory category, {
    int offset = 0,
    bool favorites = false,
    LibrarySort? sort,
    bool albumArtists = false,
  }) async => LibraryPage(
    items: [
      if (category.key == 'playlists')
        const LibraryItem(
          id: 'library://playlist/7',
          kind: LibraryKind.playlist,
          title: 'Sunday Morning',
          subtitle: '38 tracks',
          expandable: true,
        ),
      if (category.key == 'albums')
        const LibraryItem(
          id: 'library://album/1',
          kind: LibraryKind.album,
          title: 'Glass Harbor',
          subtitle: 'Juniper Lane',
          expandable: true,
        ),
    ],
  );

  @override
  Future<LibraryDetail> open(LibraryItem item) async => LibraryDetail(
    item: item,
    tracks: const [
      LibraryItem(
        id: 'library://track/1',
        kind: LibraryKind.track,
        title: 'Harbor Lights',
        durationMs: 222000,
      ),
      LibraryItem(
        id: 'library://track/3',
        kind: LibraryKind.track,
        title: 'Tidelines',
        durationMs: 198000,
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
