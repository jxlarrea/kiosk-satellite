import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/music_library/library_model.dart';
import 'package:kiosk_satellite/managers/music_library/music_library_manager.dart';
import 'package:kiosk_satellite/managers/music_library/music_pick.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A saved pick played for an owner: the speaker is lent the followed
/// player, set up, played and confirmed playing, and everything is put
/// back after, or at once when it does not play.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MusicLibraryManager lib;
  late _Source source;
  late List<(String, Map<String, Object?>)> handoff;
  late ValueNotifier<Map<String, Object?>?> nowPlaying;

  const playlist = LibraryItem(
    id: 'library://playlist/7',
    kind: LibraryKind.playlist,
    title: 'Sunday Morning',
  );
  const pick = MusicPick(
    source: 'ma',
    item: playlist,
    shuffle: true,
    speaker: 'ma:kitchen',
    speakerName: 'Kitchen',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'ks.sendspin.ma_url': 'http://ma.local:8095',
      'ks.sendspin.ma_token': 'token',
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    handoff = [];
    for (final name in ['mediaBorrow', 'mediaReturn']) {
      commands.register(
        Command(
          name: name,
          description: 'stub',
          handler: (p) async {
            handoff.add((name, p));
            return const CommandResult.ok();
          },
        ),
      );
    }
    nowPlaying = ValueNotifier(null);
    source = _Source(onPlay: () => nowPlaying.value = {'playing': true});
    lib = MusicLibraryManager(
      bus,
      commands,
      log,
      settings,
      nowPlaying: nowPlaying,
    )..sourceFactory = (_) => source;
  });

  test('it lends the speaker, sets it up, plays and puts it back', () async {
    final error = await lib.startPick(
      pick,
      owner: 'alarm',
      volume: 70,
      repeat: true,
    );
    expect(error, isNull);
    expect(handoff.single.$1, 'mediaBorrow');
    expect(handoff.single.$2, {
      'owner': 'alarm',
      'player': 'ma:kitchen',
      'name': 'Kitchen',
    });
    expect(source.calls, [
      'state ma:kitchen',
      'modes ma:kitchen shuffle true repeat all',
      'volume ma:kitchen 70',
      'play library://playlist/7 replace ma:kitchen',
    ]);
    expect(lib.pickPlaying('alarm'), isTrue);
    await lib.endPick('alarm');
    expect(source.calls.skip(4), [
      'clear ma:kitchen',
      'modes ma:kitchen shuffle false repeat off',
      'volume ma:kitchen 25',
    ]);
    expect(handoff.last.$1, 'mediaReturn');
    expect(lib.pickPlaying('alarm'), isFalse);
  });

  test('a speaker that never plays puts everything back and fails', () async {
    source.onPlay = () {};
    final error = await lib.startPick(
      pick,
      owner: 'alarm',
      confirm: const Duration(milliseconds: 50),
    );
    expect(error, contains('did not start'));
    expect(source.calls, contains('clear ma:kitchen'));
    expect(handoff.map((h) => h.$1), ['mediaBorrow', 'mediaReturn']);
    expect(lib.pickPlaying('alarm'), isFalse);
  });

  test('a refused play on this device is tried again', () async {
    source.failPlays = 1;
    final here = pick.copyWith(speaker: '', speakerName: 'Hallway');
    final error = await lib.startPick(here, owner: 'alarm');
    expect(error, isNull);
    expect(source.calls.where((c) => c.startsWith('play')), hasLength(2));
  });

  test('a refused play on another speaker fails at once', () async {
    source.failPlays = 1;
    final error = await lib.startPick(pick, owner: 'alarm');
    expect(error, 'player unavailable');
    expect(source.calls.where((c) => c.startsWith('play')), hasLength(1));
    expect(handoff.last.$1, 'mediaReturn');
  });

  test('a random pick draws from its list as it plays', () async {
    const random = MusicPick(
      source: 'ma',
      random: RandomPick.albums,
      speaker: 'ma:kitchen',
    );
    expect(await lib.startPick(random, owner: 'alarm'), isNull);
    expect(source.calls, contains('random albums'));
    expect(source.calls, contains('play library://album/1 replace ma:kitchen'));
  });

  test('the random picks a source offers follow its lists', () {
    expect(MusicLibraryManager.randomPicks(source), [
      RandomPick.tracks,
      RandomPick.favorites,
      RandomPick.playlists,
      RandomPick.albums,
    ]);
  });
  test('an eased in pick starts quiet and rises to its volume', () async {
    final error = await lib.startPick(
      pick,
      owner: 'alarm',
      volume: 60,
      ease: const Duration(milliseconds: 2500),
    );
    expect(error, isNull);
    expect(source.calls, contains('volume ma:kitchen 2'));
    expect(source.calls, isNot(contains('volume ma:kitchen 60')));
    await Future<void>.delayed(const Duration(milliseconds: 3600));
    final levels = [
      for (final c in source.calls)
        if (c.startsWith('volume ')) int.parse(c.split(' ').last),
    ];
    expect(levels.first, 2);
    expect(levels.last, 60);
    expect(levels.length, greaterThan(2));
    // The ramp ends with the pick.
    await lib.endPick('alarm');
    final after = source.calls.length;
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(source.calls.length, after);
  });
  test('an end while the start comes up leaves nothing playing', () async {
    // The speaker answers only after the end: what it started is undone.
    source.onPlay = () {};
    final starting = lib.startPick(
      pick,
      owner: 'alarm',
      volume: 60,
      ease: const Duration(seconds: 2),
      confirm: const Duration(milliseconds: 300),
    );
    await pumpEventQueue();
    await lib.endPick('alarm');
    nowPlaying.value = {'playing': true};
    expect(await starting, 'replaced');
    expect(lib.pickPlaying('alarm'), isFalse);
    expect(handoff.last.$1, 'mediaReturn');
    final after = source.calls.length;
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    // No ramp left behind.
    expect(source.calls.length, after);
  });

  test('a newer start for the same owner keeps the speaker', () async {
    source.onPlay = () {};
    final first = lib.startPick(
      pick,
      owner: 'alarm',
      confirm: const Duration(milliseconds: 400),
    );
    await pumpEventQueue();
    source.onPlay = () => nowPlaying.value = {'playing': true};
    final second = await lib.startPick(pick, owner: 'alarm');
    expect(second, isNull);
    expect(await first, 'replaced');
    expect(lib.pickPlaying('alarm'), isTrue);
    expect(handoff.last.$1, 'mediaBorrow');
  });
  test('the end waits for the player to drop the track', () async {
    expect(await lib.startPick(pick, owner: 'alarm'), isNull);
    nowPlaying.value = {'playing': true, 'title': 'Harbor Lights'};
    final ending = lib.endPick('alarm');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // Still waiting: the player shows the track and nothing went back.
    expect(handoff.last.$1, 'mediaBorrow');
    nowPlaying.value = null;
    await ending;
    expect(handoff.last.$1, 'mediaReturn');
    expect(source.calls, contains('clear ma:kitchen'));
  });
}

class _Source extends LibrarySource {
  _Source({required this.onPlay});

  void Function() onPlay;
  int failPlays = 0;
  final calls = <String>[];

  @override
  String get key => 'ma';

  @override
  bool get hasFavorites => true;

  @override
  List<LibraryCategory> get categories => const [
    LibraryCategory('albums', LibraryKind.album),
    LibraryCategory('tracks', LibraryKind.track),
    LibraryCategory('playlists', LibraryKind.playlist),
  ];

  @override
  Future<LibraryItem?> randomItem(
    LibraryCategory category, {
    bool favorites = false,
  }) async {
    calls.add('random ${category.key}');
    return const LibraryItem(
      id: 'library://album/1',
      kind: LibraryKind.album,
      title: 'Glass Harbor',
    );
  }

  @override
  Future<LibraryDetail> open(LibraryItem item) async =>
      LibraryDetail(item: item);

  @override
  Future<SpeakerState?> speakerState(String pick) async {
    calls.add('state $pick');
    return const SpeakerState(volume: 25, shuffle: false, repeat: 'off');
  }

  @override
  Future<bool> setPlayModes(
    String pick, {
    bool? shuffle,
    String? repeat,
  }) async {
    calls.add('modes $pick shuffle $shuffle repeat $repeat');
    return true;
  }

  @override
  Future<bool> setSpeakerVolume(String pick, int percent) async {
    calls.add('volume $pick $percent');
    return true;
  }

  @override
  Future<bool> stopSpeaker(String pick) async {
    calls.add('stop $pick');
    return true;
  }

  @override
  Future<bool> clearSpeaker(String pick) async {
    calls.add('clear $pick');
    return true;
  }

  @override
  Future<String?> play(
    LibraryItem item,
    PlayMode mode, {
    required String pick,
    LibraryItem? within,
  }) async {
    calls.add('play ${item.id} ${mode.name} $pick');
    if (failPlays > 0) {
      failPlays--;
      return 'player unavailable';
    }
    onPlay();
    return null;
  }
}
