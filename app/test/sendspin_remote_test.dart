import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
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

    Future<void> build({String player = 'p1', bool enabled = true}) async {
      SharedPreferences.setMockInitialValues({
        'ks.${defs.deviceName.key}': 'Wall Tablet',
        'ks.${defs.sendspinEnabled.key}': enabled,
        'ks.${defs.sendspinClientId.key}': 'abc123',
        'ks.${defs.sendspinMaUrl.key}': 'ma.local',
        'ks.${defs.sendspinMaToken.key}': 'token',
        'ks.${defs.sendspinMaPlayer.key}': player,
        'ks.${defs.sendspinMaPlayerName.key}': 'Kitchen',
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

    test('clearing the pick returns the card to the local player', () async {
      await build();
      fake!.onSnapshot({'title': 'Song', 'playing': true});
      final started = fake!;

      await settings.set(defs.sendspinMaPlayer, '');
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
      // Gone with a remote player picked: the lyrics rows, the enable
      // switch, and every local-audio row riding it transitively.
      expect(settings.visible(defs.sendspinLyrics), isFalse);
      expect(settings.visible(defs.sendspinLyricsOffset), isFalse);
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

      await settings.set(defs.sendspinMaPlayer, '');
      // The manager recomputes the surface flag over the async bus.
      await Future<void>.delayed(Duration.zero);
      expect(settings.visible(defs.sendspinLyrics), isTrue);
      expect(settings.visible(defs.sendspinLyricsOffset), isTrue);
      expect(settings.visible(defs.sendspinEnabled), isTrue);
      expect(settings.visible(defs.sendspinServer), isTrue);
      expect(settings.get(defs.sendspinPlayerActive), isTrue);
      expect(settings.visible(defs.sendspinShowPlayer), isTrue);
    });

    test('the surface flag clears when neither mode is on', () async {
      await build(enabled: false);
      expect(settings.get(defs.sendspinPlayerActive), isTrue);

      await settings.set(defs.sendspinMaPlayer, '');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(settings.get(defs.sendspinPlayerActive), isFalse);
      expect(settings.visible(defs.sendspinShowPlayer), isFalse);
    });

    test('maPlayers lists, filters and sorts the server players', () async {
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
      final result = await sendspin.commands.execute('maPlayers', const {});
      expect(result.ok, isTrue);
      final players = (result.data as List).cast<Map>();
      expect(players.map((p) => p['name']), ['Attic', 'Kitchen']);
      expect(players.first['available'], isFalse);
    });
  });
}
