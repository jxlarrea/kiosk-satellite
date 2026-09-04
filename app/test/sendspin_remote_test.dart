import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/sendspin/lrclib.dart';
import 'package:kiosk_satellite/managers/sendspin/ma_remote_player.dart';
import 'package:kiosk_satellite/managers/sendspin/music_assistant_api.dart';
import 'package:kiosk_satellite/managers/sendspin/sendspin_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Now Playing surface following a remote Music Assistant player
/// (issue #265): the queue parser both sources share, the follower's
/// show/hide rules, and the manager's routing between the local Sendspin
/// player and the followed one.

Map<String, Object?> _queue({
  String state = 'playing',
  String? title = 'After Midnight',
  double elapsed = 12.5,
  double? measuredAt,
}) => {
  'queue_id': 'q1',
  'state': state,
  'elapsed_time': elapsed,
  'elapsed_time_last_updated': ?measuredAt,
  'current_item': {
    'name': 'Phoenix - After Midnight',
    'duration': 188,
    if (title != null)
      'media_item': {
        'name': title,
        'duration': 188,
        'artists': [
          {'name': 'Phoenix'},
          {'name': 'Clairo'},
        ],
        'album': {'name': 'After Midnight'},
      },
    'image': {
      'path': 'https://img.example/cover.jpg',
      'remotely_accessible': true,
      'proxy_id': 'abc',
    },
  },
};

class _FakeApi extends MusicAssistantApi {
  _FakeApi(this.players) : super(baseUrl: 'ma.local', token: 't');

  final List<Object?> players;

  @override
  Future<MusicAssistantResult> call(
    String command, {
    Map<String, Object?> args = const {},
    Duration timeout = const Duration(seconds: 15),
  }) async => MusicAssistantResult.success(players, const {});

  @override
  Future<String?> fetchLyrics({
    required String title,
    required String artist,
    String album = '',
  }) async => null;

  @override
  Future<Map<String, Object?>?> fetchActiveQueueTrack({
    required String playerId,
  }) async => null;
}

/// A Music Assistant with lyrics for every track, counting the asks.
class _LyricsApi extends _FakeApi {
  _LyricsApi() : super(const []);

  static int asks = 0;

  @override
  Future<String?> fetchLyrics({
    required String title,
    required String artist,
    String album = '',
  }) async {
    asks++;
    return '[00:01.00] from music assistant';
  }
}

/// LRCLIB as a test sees it: answering, empty-handed, or down.
class _FakeLrclib extends LrclibApi {
  _FakeLrclib(this.mode);

  final String mode;
  static int asks = 0;

  @override
  Future<String?> fetchSyncedLyrics({
    required String title,
    required String artist,
    int? durationSeconds,
  }) async {
    asks++;
    return switch (mode) {
      'found' => '[00:01.00] from lrclib',
      'missing' => null,
      _ => throw const LrclibUnreachable('no route'),
    };
  }
}

class _FakeRemote extends MaRemotePlayer {
  _FakeRemote({
    required super.baseUrl,
    required super.token,
    required super.playerId,
    required super.onSnapshot,
    required super.log,
    super.label,
  });

  final sent = <String>[];
  bool stopped = false;
  bool revealed = false;

  @override
  void start() {}

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  void reveal() {
    revealed = true;
  }

  @override
  Future<bool> control(String command) async {
    sent.add(command);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('queueTrackSnapshot', () {
    test('parses a queue dict into Sendspin metadata keys', () {
      final snap = queueTrackSnapshot(
        _queue(measuredAt: 1700000000),
        webBase: 'https://ma.local:8095',
      );
      expect(snap, isNotNull);
      expect(snap!['title'], 'After Midnight');
      expect(snap['artist'], 'Phoenix/Clairo');
      expect(snap['album'], 'After Midnight');
      expect(snap['durationMs'], 188000);
      expect(snap['positionMs'], 12500);
      expect(snap['positionAtMs'], 1700000000000);
      expect(snap['state'], 'playing');
      // Remotely accessible artwork is used as-is, not proxied.
      expect(snap['artworkUrl'], 'https://img.example/cover.jpg');
    });

    test('proxies artwork that is not remotely accessible', () {
      final queue = _queue();
      ((queue['current_item'] as Map)['image'] as Map)['remotely_accessible'] =
          false;
      final snap = queueTrackSnapshot(queue, webBase: 'https://ma.local:8095');
      expect(
        snap!['artworkUrl'],
        'https://ma.local:8095/imageproxy/abc?size=512&fmt=jpg',
      );
    });

    test('no queue, no item, or no name is no snapshot', () {
      expect(queueTrackSnapshot(null), isNull);
      expect(queueTrackSnapshot({'state': 'playing'}), isNull);
      final queue = _queue(title: null);
      (queue['current_item'] as Map)['name'] = '';
      expect(queueTrackSnapshot(queue), isNull);
    });
  });

  group('musicAssistantWebUrl', () {
    test('lands on the picked player through the fragment', () {
      expect(
        musicAssistantWebUrl('https://ma.local:8095', player: 'Kitchen Sonos'),
        'https://ma.local:8095/#/?player=Kitchen%20Sonos',
      );
    });

    test('no player keeps the plain address', () {
      expect(
        musicAssistantWebUrl('https://ma.local:8095', player: ''),
        'https://ma.local:8095',
      );
      expect(
        musicAssistantWebUrl('https://ma.local:8095'),
        'https://ma.local:8095',
      );
    });

    test('the landing player is whoever the kiosk represents', () {
      // A followed remote player wins.
      expect(
        maLandingPlayer(
          remotePlayerName: 'Kitchen',
          localPlayerName: 'Wall Tablet',
          localPlayerEnabled: true,
        ),
        'Kitchen',
      );
      // Otherwise this device's own player, while it exists to select.
      expect(
        maLandingPlayer(
          remotePlayerName: '',
          localPlayerName: 'Wall Tablet',
          localPlayerEnabled: true,
        ),
        'Wall Tablet',
      );
      expect(
        maLandingPlayer(
          remotePlayerName: '',
          localPlayerName: 'Wall Tablet',
          localPlayerEnabled: false,
        ),
        '',
      );
    });
  });

  group('MaRemotePlayer show/hide rules', () {
    late List<Map<String, Object?>?> emitted;
    late MaRemotePlayer remote;

    setUp(() {
      emitted = [];
      remote = MaRemotePlayer(
        baseUrl: 'ma.local',
        token: 't',
        playerId: 'p1',
        onSnapshot: emitted.add,
        log: Logger(),
      );
    });

    test('a playing queue is a playing card with the full command set', () {
      remote.publishQueue(_queue());
      expect(emitted, hasLength(1));
      final snap = emitted.single!;
      expect(snap['playing'], isTrue);
      expect(snap['title'], 'After Midnight');
      expect(snap['supportedCommands'], MaRemotePlayer.commands);
      // Transport-state bookkeeping stays out of the published card.
      expect(snap.containsKey('state'), isFalse);
      expect(snap.containsKey('positionAtMs'), isFalse);
      expect(snap['receivedAt'], isNotNull);
    });

    test('an idle queue at startup stays off screen', () {
      remote.publishQueue(_queue(state: 'idle'));
      expect(emitted, [null]);
    });

    test('idle after playback is the paused card (pause maps to stop)', () {
      remote.publishQueue(_queue());
      remote.publishQueue(_queue(state: 'idle'));
      expect(emitted, hasLength(2));
      expect(emitted.last!['playing'], isFalse);
      expect(emitted.last!['title'], 'After Midnight');
    });

    test('a paused queue shows paused without prior playback', () {
      remote.publishQueue(_queue(state: 'paused'));
      expect(emitted.single!['playing'], isFalse);
    });

    test('queue events route by the followed queue id', () {
      remote.publishQueue(_queue());
      remote.handleEvent('queue_updated', 'q1', _queue(state: 'paused'));
      expect(emitted.last!['playing'], isFalse);
      // Another queue's event is not ours.
      remote.handleEvent('queue_updated', 'q2', _queue());
      expect(emitted.last!['playing'], isFalse);
    });

    test('queue_time_updated moves the position without a round trip', () {
      remote.publishQueue(_queue());
      remote.handleEvent('queue_time_updated', 'q1', 42.0);
      expect(emitted.last!['positionMs'], 42000);
    });

    test('the arrival time is the extrapolation base, not the stamp', () {
      // The dict's elapsed time is live when serialized; its stamp marks
      // the player's last report, which can be far back. Basing on the
      // stamp counted that gap twice.
      final measuredAt = DateTime.now().millisecondsSinceEpoch / 1000.0 - 20;
      remote.publishQueue(_queue(measuredAt: measuredAt));
      final receivedAt = emitted.single!['receivedAt'] as int;
      expect(
        (DateTime.now().millisecondsSinceEpoch - receivedAt).abs(),
        lessThan(5000),
      );
      expect(emitted.single!.containsKey('positionAtMs'), isFalse);
    });

    test('a wildly skewed stamp changes nothing either', () {
      remote.publishQueue(_queue(measuredAt: 1000.0));
      final receivedAt = emitted.single!['receivedAt'] as int;
      expect(
        (DateTime.now().millisecondsSinceEpoch - receivedAt).abs(),
        lessThan(5000),
      );
    });
  });

  group('SendspinManager remote routing', () {
    const channel = MethodChannel('kiosk_satellite/sendspin');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    late EventBus bus;
    late SettingsManager settings;
    late SendspinManager sendspin;
    late List<MethodCall> nativeCalls;
    _FakeRemote? fake;

    Future<void> build({String player = 'ma:p1', bool enabled = true}) async {
      SharedPreferences.setMockInitialValues({
        'ks.${defs.deviceName.key}': 'Wall Tablet',
        'ks.${defs.sendspinEnabled.key}': enabled,
        'ks.${defs.sendspinClientId.key}': 'abc123',
        'ks.${defs.sendspinMaUrl.key}': 'ma.local',
        'ks.${defs.sendspinMaToken.key}': 'token',
        'ks.${defs.sendspinPlayer.key}': player,
        if (player.isNotEmpty) 'ks.${defs.sendspinPlayerSource.key}': 'ma',
        'ks.${defs.sendspinPlayerName.key}': 'Kitchen',
        'ks.${defs.sendspinLyrics.key}': true,
      });
      nativeCalls = [];
      messenger.setMockMethodCallHandler(channel, (call) async {
        nativeCalls.add(call);
        return null;
      });
      bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      sendspin = SendspinManager(bus, commands, log, settings);
      // Lyrics lookups must never open a real socket in a test.
      sendspin.apiFactory = ({required baseUrl, required token}) =>
          _FakeApi(const []);
      fake = null;
      sendspin.remoteFactory =
          ({
            required baseUrl,
            required token,
            required playerId,
            required onSnapshot,
            required log,
            String label = 'remote player',
          }) => fake = _FakeRemote(
            baseUrl: baseUrl,
            token: token,
            playerId: playerId,
            onSnapshot: onSnapshot,
            log: log,
            label: label,
          );
      await sendspin.init();
      await Future<void>.delayed(Duration.zero);
    }

    tearDown(() async {
      await sendspin.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });

    test('a picked player builds the follower and feeds the card', () async {
      await build();
      expect(fake, isNotNull);
      expect(fake!.playerId, 'p1');

      fake!.onSnapshot({'title': 'Song', 'playing': true});
      expect(sendspin.nowPlaying.value?['title'], 'Song');
      expect(sendspin.nowPlaying.value?['playing'], isTrue);
    });

    test('transport goes to the follower, not the native player', () async {
      await build();
      expect(await sendspin.control('pause'), isTrue);
      expect(fake!.sent, ['pause']);
      expect(nativeCalls.map((c) => c.method), isNot(contains('control')));
    });

    test('local metadata stays off screen while following', () async {
      await build();
      await messenger.handlePlatformMessage(
        'kiosk_satellite/sendspin',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('metadataChanged', {'title': 'Local Song'}),
        ),
        (_) {},
      );
      await messenger.handlePlatformMessage(
        'kiosk_satellite/sendspin',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('playingChanged', {'playing': true}),
        ),
        (_) {},
      );
      expect(sendspin.nowPlaying.value, isNull);
      expect(sendspin.lyrics.value, isEmpty);
    });

    group('lyrics source', () {
      Future<void> play(
        String lrclib, {
        Map<String, Object> prefs = const {},
      }) async {
        await build();
        _LyricsApi.asks = 0;
        _FakeLrclib.asks = 0;
        sendspin.apiFactory = ({required baseUrl, required token}) =>
            _LyricsApi();
        sendspin.lrclibFactory = () => _FakeLrclib(lrclib);
        for (final e in prefs.entries) {
          final def = defs.allSettings.firstWhere((d) => d.key == e.key);
          await settings.set(def, e.value);
        }
        fake!.onSnapshot({'title': 'Song', 'artist': 'A', 'playing': true});
        await pumpEventQueue();
      }

      test('LRCLIB by default, Music Assistant left alone', () async {
        await play('found');
        expect(sendspin.lyrics.value, isNotEmpty);
        expect(sendspin.lyrics.value.first.text, 'from lrclib');
        expect(_FakeLrclib.asks, 1);
        expect(_LyricsApi.asks, 0);
      });

      test('LRCLIB unreachable falls back to Music Assistant', () async {
        await play('down');
        expect(sendspin.lyrics.value.first.text, 'from music assistant');
        expect(_LyricsApi.asks, 1);
      });

      test('a track LRCLIB lacks is not retried on Music Assistant', () async {
        await play('missing');
        expect(sendspin.lyrics.value, isEmpty);
        expect(_LyricsApi.asks, 0);
      });

      test(
        'the fallback switched off leaves an unreachable LRCLIB empty',
        () async {
          await play('down', prefs: {'sendspin.lyrics_fallback_ma': false});
          expect(sendspin.lyrics.value, isEmpty);
          expect(_LyricsApi.asks, 0);
        },
      );

      test('Music Assistant as the source never asks LRCLIB', () async {
        await play('found', prefs: {'sendspin.lyrics_source': 'ma'});
        expect(sendspin.lyrics.value.first.text, 'from music assistant');
        expect(_FakeLrclib.asks, 0);
      });

      test('Enable lyrics off takes them away everywhere', () async {
        await play('found', prefs: {'sendspin.lyrics_enabled': false});
        expect(sendspin.lyricsAvailable, isFalse);
        expect(sendspin.lyrics.value, isEmpty);
        expect(_FakeLrclib.asks, 0);
      });
    });

    test('clearing the pick returns the card to the local player', () async {
      await build();
      fake!.onSnapshot({'title': 'Song', 'playing': true});
      final started = fake!;

      await settings.set(defs.sendspinPlayer, '');
      await Future<void>.delayed(Duration.zero);
      expect(started.stopped, isTrue);
      expect(sendspin.nowPlaying.value, isNull);

      // Local playback owns the card again.
      await messenger.handlePlatformMessage(
        'kiosk_satellite/sendspin',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('metadataChanged', {'title': 'Local Song'}),
        ),
        (_) {},
      );
      await messenger.handlePlatformMessage(
        'kiosk_satellite/sendspin',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('playingChanged', {'playing': true}),
        ),
        (_) {},
      );
      expect(sendspin.nowPlaying.value?['title'], 'Local Song');
    });

    test('no pick means no follower, and the local player runs', () async {
      await build(player: '');
      // What the factory built here is the local player's queue watcher
      // (a server is configured), not a follower of another player.
      expect(fake?.label, 'queue watcher');
      expect(fake?.playerId, 'abc123');
      expect(nativeCalls.map((c) => c.method), contains('start'));
      // The registered name is remembered for the shortcut's landing.
      expect(settings.get(defs.sendspinLocalPlayerName), 'Wall Tablet');
    });

    test('a picked player keeps the local player offline', () async {
      await build();
      // The device is a remote control in this mode: the local client
      // never starts, so Music Assistant shows this device offline.
      expect(nativeCalls.map((c) => c.method), isNot(contains('start')));
    });

    test('the follower runs without the local player enabled', () async {
      await build(enabled: false);
      expect(fake, isNotNull);
      expect(nativeCalls.map((c) => c.method), isNot(contains('start')));
    });

    test('the reveal asks the follower, not Music Assistant', () async {
      await build();
      bus.publish(const SendspinShowPlayerRequested());
      await Future<void>.delayed(Duration.zero);
      expect(fake!.revealed, isTrue);
    });

    test('the local-player rows leave the settings while following', () async {
      await build();
      // Gone with a remote player picked: the enable switch and every
      // local-audio row riding it transitively. Lyrics stay: a followed
      // player's position is read closely enough to sing along with.
      expect(settings.visible(defs.sendspinLyrics), isTrue);
      expect(settings.visible(defs.sendspinEnabled), isFalse);
      expect(settings.visible(defs.sendspinServer), isFalse);
      expect(settings.visible(defs.sendspinCodec), isFalse);
      expect(settings.visible(defs.sendspinSyncOffset), isFalse);
      expect(settings.visible(defs.sendspinDuckPercent), isFalse);
      // The card rows stay: they are what the mode is for.
      expect(settings.get(defs.sendspinPlayerActive), isTrue);
      expect(settings.visible(defs.sendspinShowPlayer), isTrue);
      expect(settings.visible(defs.sendspinPlayerShortcut), isTrue);
      expect(settings.visible(defs.sendspinFullscreen), isTrue);
      expect(settings.visible(defs.sendspinDismissKeepsPlaying), isTrue);

      // Back to this device: the source pick clears the player pick too.
      await settings.set(defs.sendspinPlayerSource, '');
      // The manager recomputes the surface flag over the async bus.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(settings.get(defs.sendspinPlayer), '');
      expect(settings.visible(defs.sendspinLyrics), isTrue);
      expect(settings.visible(defs.sendspinEnabled), isTrue);
      expect(settings.visible(defs.sendspinServer), isTrue);
      expect(settings.get(defs.sendspinPlayerActive), isTrue);
      expect(settings.visible(defs.sendspinShowPlayer), isTrue);
    });

    test('the surface flag clears when neither mode is on', () async {
      await build(enabled: false);
      expect(settings.get(defs.sendspinPlayerActive), isTrue);

      await settings.set(defs.sendspinPlayerSource, '');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(settings.get(defs.sendspinPlayerActive), isFalse);
      expect(settings.visible(defs.sendspinShowPlayer), isFalse);
    });

    test('mediaPlayerSet follows a player by name or id, per source', () async {
      await build();
      sendspin.apiFactory = ({required baseUrl, required token}) => _FakeApi([
        {
          'player_id': 'b',
          'display_name': 'Kitchen',
          'available': true,
          'enabled': true,
        },
        {
          'player_id': 'a',
          'display_name': 'Attic',
          'available': false,
          'enabled': true,
        },
      ]);
      // By name, case aside, and the readable source spelling.
      var result = await sendspin.commands.execute('mediaPlayerSet', {
        'source': 'Music Assistant',
        'player': 'kitchen',
      });
      expect(result.ok, isTrue);
      expect(result.data, {
        'source': 'music_assistant',
        'id': 'b',
        'name': 'Kitchen',
      });
      expect(settings.get(defs.sendspinPlayerSource), 'ma');
      expect(settings.get(defs.sendspinPlayer), 'ma:b');
      expect(settings.get(defs.sendspinPlayerName), 'Kitchen');
      expect(settings.get(defs.sendspinPlayerActive), isTrue);
      // By id, bare or prefixed.
      result = await sendspin.commands.execute('mediaPlayerSet', {
        'source': 'ma',
        'player': 'a',
      });
      expect(result.ok, isTrue);
      expect(settings.get(defs.sendspinPlayer), 'ma:a');
      result = await sendspin.commands.execute('mediaPlayerSet', {
        'source': 'ma',
        'player': 'ma:b',
      });
      expect(settings.get(defs.sendspinPlayer), 'ma:b');
      // Nobody of that name, and a source nobody knows: refused, and the
      // pick stays.
      result = await sendspin.commands.execute('mediaPlayerSet', {
        'source': 'ma',
        'player': 'Garage',
      });
      expect(result.ok, isFalse);
      expect(settings.get(defs.sendspinPlayer), 'ma:b');
      result = await sendspin.commands.execute('mediaPlayerSet', {
        'source': 'spotify',
        'player': 'Kitchen',
      });
      expect(result.ok, isFalse);
      // The device source puts this device back on its own player.
      result = await sendspin.commands.execute('mediaPlayerSet', {
        'source': 'device',
        'player': '',
      });
      expect(result.ok, isTrue);
      expect(settings.get(defs.sendspinPlayerSource), '');
      expect(settings.get(defs.sendspinPlayer), '');
      expect(settings.get(defs.sendspinPlayerName), '');
    });

    test('the source and player helpers behind the actions', () {
      expect(SendspinManager.sourceKey('Home Assistant'), 'ha');
      expect(SendspinManager.sourceKey('home-assistant'), 'ha');
      expect(SendspinManager.sourceKey('musicassistant'), 'ma');
      expect(SendspinManager.sourceKey('SONOS'), 'sonos');
      expect(SendspinManager.sourceKey('This device'), '');
      expect(SendspinManager.sourceKey('spotify'), isNull);
      expect(SendspinManager.sourceLabel('ha'), 'home_assistant');
      expect(SendspinManager.sourceLabel(''), 'device');
      final rows = <Map>[
        {'id': 'sonos:RINCON_1', 'name': 'Office', 'available': false},
        {'id': 'sonos:RINCON_2', 'name': 'Office', 'available': true},
        {'id': 'sonos:RINCON_3', 'name': 'Hall'},
      ];
      // A shared name goes to the available one; an id matches bare or
      // prefixed.
      expect(
        SendspinManager.pickPlayer(rows, 'office')!['id'],
        'sonos:RINCON_2',
      );
      expect(
        SendspinManager.pickPlayer(rows, 'RINCON_1')!['id'],
        'sonos:RINCON_1',
      );
      expect(
        SendspinManager.pickPlayer(rows, 'sonos:RINCON_3')!['name'],
        'Hall',
      );
      expect(SendspinManager.pickPlayer(rows, 'Garage'), isNull);
    });

    test('mediaPlayers lists, filters and sorts the server players', () async {
      await build();
      sendspin.apiFactory = ({required baseUrl, required token}) => _FakeApi([
        {
          'player_id': 'b',
          'display_name': 'Kitchen',
          'available': true,
          'enabled': true,
        },
        {
          'player_id': 'a',
          'display_name': 'Attic',
          'available': false,
          'enabled': true,
        },
        {'player_id': 'x', 'display_name': 'Disabled', 'enabled': false},
        // This device itself: its raw Sendspin identity and a universal
        // player wrapping it (the client id embedded in the wrapper's id).
        // "This device" already is that choice.
        {'player_id': 'abc123', 'display_name': 'Me', 'available': true},
        {'player_id': 'upabc123', 'display_name': 'Me Too', 'available': true},
      ]);
      final result = await sendspin.commands.execute('mediaPlayers', const {});
      expect(result.ok, isTrue);
      final data = result.data as Map;
      final players = (data['players'] as List).cast<Map>();
      expect(players.map((p) => p['name']), ['Attic', 'Kitchen']);
      expect(players.map((p) => p['id']), ['ma:a', 'ma:b']);
      expect(players.every((p) => p['group'] == 'ma'), isTrue);
      expect(players.first['available'], isFalse);
      // No Home Assistant connection here: its group says so instead of
      // hiding.
      expect((data['notes'] as Map)['ha'], isNotNull);
    });

    test('forgetting the picked Sonos room clears the pick', () async {
      await build(player: 'sonos:RINCON_A');
      await settings.set(defs.sendspinPlayerSource, 'sonos');
      await settings.set(defs.sendspinPlayerName, 'Office');
      // Nothing listens at the loopback address, so the household read
      // fails at once and the room is forgotten on its own.
      await settings.set(
        defs.sendspinSonosHosts,
        '{"RINCON_A":{"host":"127.0.0.1","name":"Office"},'
        '"RINCON_B":{"host":"127.0.0.2","name":"Kitchen"}}',
      );
      final kept = await sendspin.commands.execute('sonosForget', {
        'id': 'RINCON_B',
      });
      expect(kept.ok, isTrue);
      // Another room going leaves the pick alone.
      expect(settings.get(defs.sendspinPlayer), 'sonos:RINCON_A');
      expect(settings.get(defs.sendspinPlayerName), 'Office');
      final result = await sendspin.commands.execute('sonosForget', {
        'id': 'RINCON_A',
      });
      expect(result.ok, isTrue);
      expect(result.data, isEmpty);
      expect(settings.get(defs.sendspinSonosHosts), '{}');
      expect(settings.get(defs.sendspinPlayer), '');
      expect(settings.get(defs.sendspinPlayerName), '');
      expect(settings.get(defs.sendspinPlayerSource), 'sonos');
    });
  });
}
