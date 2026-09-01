import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/sendspin/ma_remote_player.dart';
import 'package:kiosk_satellite/managers/sendspin/music_assistant_api.dart';
import 'package:kiosk_satellite/managers/sendspin/sendspin_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/sendspin_player_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A Music Assistant that answers the few commands the view needs: one
/// queue, one track, and a favorite flag the commands flip.
class _FakeApi extends MusicAssistantApi {
  _FakeApi() : super(baseUrl: 'ma.local', token: 't');

  static bool favorite = false;
  static final calls = <String>[];
  static final args = <Map<String, Object?>>[];

  @override
  Future<MusicAssistantResult> call(
    String command, {
    Map<String, Object?> args = const {},
    Duration timeout = const Duration(seconds: 15),
  }) async {
    calls.add(command);
    _FakeApi.args.add(args);
    final Object result = switch (command) {
      'player_queues/get_active_queue' => {
        'queue_id': 'q1',
        'current_index': 3,
        'current_item': {
          'queue_item_id': 'item-a',
          'media_item': {'uri': 'library://track/1', 'name': 'Song'},
        },
      },
      'music/item_by_uri' => {
        'favorite': favorite,
        'item_id': '1',
        'media_type': 'track',
        'provider': 'library',
      },
      'music/favorites/add_item' => favorite = true,
      'music/favorites/remove_item' => favorite = false,
      'player_queues/items' => [
        {
          'queue_item_id': 'item-a',
          'index': 0,
          'name': 'A - Song',
          'duration': 100,
          'media_item': {
            'name': 'Song',
            'artists': [
              {'name': 'A'},
            ],
          },
        },
        {
          'queue_item_id': 'item-b',
          'index': 0,
          'name': 'B - Next',
          'duration': 250,
          'media_item': {
            'name': 'Next',
            'artists': [
              {'name': 'B'},
            ],
          },
        },
      ],
      _ => const [],
    };
    return MusicAssistantResult.success(result, const {});
  }

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

  @override
  void start() {}

  @override
  Future<void> stop() async {}
}

/// The Now Playing group: the full-screen view's media controls and the
/// launch-on-play switch. With the transport up a tap is a button press
/// and the close button is the way out; launch on play brings the view up
/// the moment playback starts instead of at the idle timeout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('definitions', () {
    test('the rows form the Now Playing group under Music Assistant', () {
      for (final def in [
        defs.sendspinFullscreen,
        defs.sendspinFullscreenControls,
        defs.sendspinFullscreenOnPlay,
        defs.sendspinFullscreenMotion,
      ]) {
        expect(def.category, 'Sendspin');
        expect(def.section, 'Now Playing');
      }
      // The group renders as one card only while its defs sit together.
      final keys = defs.allSettings.map((d) => d.key).toList();
      final first = keys.indexOf(defs.sendspinFullscreen.key);
      expect(keys[first + 1], defs.sendspinFullscreenControls.key);
      expect(keys[first + 2], defs.sendspinFullscreenQueue.key);
      expect(keys[first + 3], defs.sendspinFullscreenOnPlay.key);
      expect(keys[first + 4], defs.sendspinFullscreenMotion.key);
      expect(defs.sendspinFullscreenQueue.section, 'Now Playing');
      expect(defs.sendspinFullscreenQueue.defaultValue, isFalse);
      expect(
        defs.sendspinFullscreenQueue.dependsOn,
        'sendspin.fullscreen_controls',
      );
    });

    test('controls default on, launch on play off, both behind the view', () {
      expect(defs.sendspinFullscreenControls.defaultValue, isTrue);
      expect(defs.sendspinFullscreenOnPlay.defaultValue, isFalse);
      expect(defs.sendspinFullscreenControls.dependsOn, 'sendspin.fullscreen');
      expect(defs.sendspinFullscreenOnPlay.dependsOn, 'sendspin.fullscreen');
    });
  });

  group('screensaver manager', () {
    late EventBus bus;
    late ScreensaverManager saver;

    Future<void> build(Map<String, Object> extra) async {
      SharedPreferences.setMockInitialValues({
        'ks.screensaver.mode': 'clock',
        'ks.sendspin.fullscreen': true,
        ...extra,
      });
      bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      final settings = SettingsManager(bus, commands, log);
      await settings.init();
      saver = ScreensaverManager(bus, commands, log, settings);
      await saver.init();
    }

    Future<void> showNowPlaying() async {
      bus.publish(const SendspinNowPlayingChanged(active: true, playing: true));
      await pumpEventQueue();
      await saver.start();
      await pumpEventQueue();
      expect(saver.isActive, isTrue);
    }

    test('with controls up a touch does not dismiss', () async {
      await build({});
      await showNowPlaying();
      saver.notifyActivity('touch');
      saver.notifyActivity('touch_page');
      saver.notifyActivity('key');
      await pumpEventQueue();
      expect(saver.isActive, isTrue);
    });

    test('the close button and every other source still dismiss', () async {
      await build({});
      await showNowPlaying();
      saver.notifyActivity('close');
      await pumpEventQueue();
      expect(saver.isActive, isFalse);

      await showNowPlaying();
      saver.notifyActivity('screen on');
      await pumpEventQueue();
      expect(saver.isActive, isFalse);
    });

    test('without controls a touch dismisses as before', () async {
      await build({'ks.sendspin.fullscreen_controls': false});
      await showNowPlaying();
      saver.notifyActivity('touch');
      await pumpEventQueue();
      expect(saver.isActive, isFalse);
    });

    test('the regular screensaver keeps its touch dismissal', () async {
      // Music stopped mid-session: the slot shows the clock again and a
      // tap must take it down, controls setting or not.
      await build({});
      await showNowPlaying();
      bus.publish(const SendspinNowPlayingChanged(active: false));
      await pumpEventQueue();
      saver.notifyActivity('touch');
      await pumpEventQueue();
      expect(saver.isActive, isFalse);
    });

    test('launch on play starts the session when playback starts', () async {
      await build({'ks.sendspin.fullscreen_on_play': true});
      expect(saver.isActive, isFalse);
      bus.publish(const SendspinNowPlayingChanged(active: true, playing: true));
      await pumpEventQueue();
      expect(saver.isActive, isTrue);
      expect(saver.activeView.value, 'clock');
    });

    test('off by default: playback waits for the idle timeout', () async {
      await build({});
      bus.publish(const SendspinNowPlayingChanged(active: true, playing: true));
      await pumpEventQueue();
      expect(saver.isActive, isFalse);
    });

    test('launch on play needs the Now Playing view itself', () async {
      await build({
        'ks.sendspin.fullscreen': false,
        'ks.sendspin.fullscreen_on_play': true,
      });
      bus.publish(const SendspinNowPlayingChanged(active: true, playing: true));
      await pumpEventQueue();
      expect(saver.isActive, isFalse);
    });

    test('playback stopping never launches anything', () async {
      await build({'ks.sendspin.fullscreen_on_play': true});
      bus.publish(const SendspinNowPlayingChanged(active: false));
      await pumpEventQueue();
      expect(saver.isActive, isFalse);
    });

    test('the remote snapshot carries the queue shuffle state', () {
      final snap = queueTrackSnapshot({
        'shuffle_enabled': true,
        'current_item': {'name': 'Song', 'duration': 100},
      });
      expect(snap?['shuffle'], isTrue);
    });

    test(
      'a paused track appearing under the controls does not launch',
      () async {
        // The hold publishes active without playing: the view has
        // something to show, but nothing started.
        await build({'ks.sendspin.fullscreen_on_play': true});
        bus.publish(const SendspinNowPlayingChanged(active: true));
        await pumpEventQueue();
        expect(saver.isActive, isFalse);
      },
    );
  });

  group('paused hold', () {
    // A pause under the controls keeps the view (paused, with its play
    // button) as long as the floating card keeps its paused look; a track
    // going away, the controls going off or the hold running out gives
    // the regular screensaver back. Driven through the remote follower,
    // whose snapshots land on the same path as the local player's.
    const channel = MethodChannel('kiosk_satellite/sendspin');
    late EventBus bus;
    late SettingsManager settings;
    late SendspinManager sendspin;
    late CommandRegistry commands;
    late List<SendspinNowPlayingChanged> events;
    _FakeRemote? fake;

    Future<void> build({Map<String, Object> extra = const {}}) async {
      SharedPreferences.setMockInitialValues({
        'ks.sendspin.ma_url': 'ma.local',
        'ks.sendspin.ma_token': 'token',
        'ks.sendspin.ma_player': 'p1',
        'ks.sendspin.ma_player_name': 'Kitchen',
        'ks.sendspin.fullscreen': true,
        ...extra,
      });
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async => null);
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      bus = EventBus();
      final log = Logger();
      commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      sendspin = SendspinManager(bus, commands, log, settings);
      sendspin.apiFactory = ({required baseUrl, required token}) => _FakeApi();
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
      events = [];
      bus.on<SendspinNowPlayingChanged>().listen(events.add);
      await sendspin.init();
      await Future<void>.delayed(Duration.zero);
      addTearDown(sendspin.dispose);
    }

    test(
      'the local player watches its queue for shuffle set elsewhere',
      () async {
        // Local mode with a server configured: the follower class is
        // pointed at this device's own player as a watcher.
        await build(
          extra: {
            'ks.sendspin.ma_player': '',
            'ks.sendspin.enabled': true,
            'ks.sendspin.client_id': 'abc123',
          },
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(fake, isNotNull);
        expect(fake!.playerId, 'abc123');
        expect(fake!.label, 'queue watcher');
        fake!.onSnapshot({'title': 'Song', 'playing': true, 'shuffle': true});
        final status = await commands.execute('sendspinStatus', const {});
        expect((status.data as Map)['shuffle'], isTrue);
        // The watcher never puts a card up: that is the local stream's job.
        expect(sendspin.nowPlaying.value, isNull);
      },
    );

    test('a pause under the controls keeps the view', () async {
      await build();
      fake!.onSnapshot({'title': 'Song', 'playing': true});
      expect(sendspin.fullscreenActive.value, isTrue);
      fake!.onSnapshot({'title': 'Song', 'playing': false});
      await pumpEventQueue();
      expect(sendspin.fullscreenActive.value, isTrue);
      expect(events.last.active, isTrue);
      expect(events.last.playing, isFalse);
      // The track going away ends it.
      fake!.onSnapshot(null);
      await pumpEventQueue();
      expect(sendspin.fullscreenActive.value, isFalse);
    });

    test('without the controls a pause gives the screensaver back', () async {
      await build(extra: {'ks.sendspin.fullscreen_controls': false});
      fake!.onSnapshot({'title': 'Song', 'playing': true});
      fake!.onSnapshot({'title': 'Song', 'playing': false});
      await pumpEventQueue();
      expect(sendspin.fullscreenActive.value, isFalse);
    });

    test('switching the controls off drops a held pause', () async {
      await build();
      fake!.onSnapshot({'title': 'Song', 'playing': true});
      fake!.onSnapshot({'title': 'Song', 'playing': false});
      await settings.set(defs.sendspinFullscreenControls, false);
      await pumpEventQueue();
      expect(sendspin.fullscreenActive.value, isFalse);
    });

    test(
      'a track appearing paused is not held: nothing was paused here',
      () async {
        await build();
        fake!.onSnapshot({'title': 'Song', 'playing': false});
        await pumpEventQueue();
        expect(sendspin.fullscreenActive.value, isFalse);
      },
    );

    test('the hold runs out with the card\'s paused timeout', () {
      fakeAsync((async) {
        build(extra: {'ks.sendspin.paused_hide_minutes': 1});
        async.flushMicrotasks();
        fake!.onSnapshot({'title': 'Song', 'playing': true});
        fake!.onSnapshot({'title': 'Song', 'playing': false});
        async.flushMicrotasks();
        expect(sendspin.fullscreenActive.value, isTrue);
        async.elapse(const Duration(seconds: 61));
        expect(sendspin.fullscreenActive.value, isFalse);
        expect(events.last.active, isFalse);
      });
    });
  });

  group('view', () {
    const channel = MethodChannel('kiosk_satellite/sendspin');
    late AppContainer container;
    late List<MethodCall> calls;

    Future<void> pump(
      WidgetTester tester, {
      Map<String, Object> settings = const {},
      Size size = const Size(1280, 800),
      List<String>? supported,
    }) async {
      SharedPreferences.setMockInitialValues({
        'ks.sendspin.fullscreen': true,
        ...settings,
      });
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      calls = [];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      container = AppContainer();
      await container.settings.init();
      _FakeApi.favorite = false;
      _FakeApi.calls.clear();
      _FakeApi.args.clear();
      container.sendspin.apiFactory = ({required baseUrl, required token}) =>
          _FakeApi();
      // The manager's own listeners (the track-change lookups) come
      // with init; nothing native starts, the player is off.
      await container.sendspin.init();
      addTearDown(container.sendspin.dispose);
      container.sendspin.nowPlaying.value = {
        'title': 'Song',
        'artist': 'Artist',
        'durationMs': 200000,
        'positionMs': 30000,
        'receivedAt': DateTime.now().millisecondsSinceEpoch,
        'playing': true,
        'supportedCommands': ?supported,
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SendspinFullscreenView(container: container)),
        ),
      );
      await tester.pump();
    }

    testWidgets('controls on: transport, bar, times and the close button', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('3:20'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the buttons send the group transport commands', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byIcon(Icons.pause_circle_filled_rounded));
      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pump();
      expect(calls.map((c) => c.arguments['command']).toList(), [
        'pause',
        'next',
      ]);
    });

    testWidgets('dragging the bar seeks with the position in ms', (
      tester,
    ) async {
      await pump(tester);
      final slider = find.byType(Slider);
      final box = tester.getRect(slider);
      // From the current thumb to three quarters along the bar.
      await tester.tapAt(Offset(box.left + box.width * 0.75, box.center.dy));
      await tester.pump();
      final seek = calls.singleWhere((c) => c.arguments['command'] == 'seek');
      final ms = seek.arguments['value'] as int;
      expect(ms, inInclusiveRange(140000, 160000));
      // The bar shows the target before the server reports back.
      expect(find.textContaining(RegExp(r'^2:[2-3]\d$')), findsOneWidget);
    });

    testWidgets('a server without seek gets a bar with no thumb', (
      tester,
    ) async {
      await pump(tester, supported: ['play', 'pause', 'next', 'previous']);
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNull);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
    });

    testWidgets('the shuffle toggle sends shuffle, then unshuffle', (
      tester,
    ) async {
      await pump(tester);
      Color? shuffleColor() => tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.shuffle_rounded),
              matching: find.byType(IconButton),
            ),
          )
          .color;
      expect(shuffleColor(), Colors.white38);
      await tester.tap(find.byIcon(Icons.shuffle_rounded));
      await tester.pump();
      expect(calls.last.arguments['command'], 'shuffle');
      // Lit at once, on the press, ahead of the server's word.
      expect(shuffleColor(), Colors.white);
      // The server reports it on; the next press turns it off.
      container.sendspin.nowPlaying.value = {
        ...container.sendspin.nowPlaying.value!,
        'shuffle': true,
      };
      await tester.pump();
      await tester.tap(find.byIcon(Icons.shuffle_rounded));
      await tester.pump();
      expect(calls.last.arguments['command'], 'unshuffle');
    });

    testWidgets('the lyrics toggle flips the setting', (tester) async {
      await pump(tester);
      expect(find.byIcon(Icons.lyrics_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.lyrics_outlined));
      await tester.pump();
      expect(container.settings.get(defs.sendspinLyrics), isTrue);
      expect(find.byIcon(Icons.lyrics_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.lyrics_rounded));
      await tester.pump();
      expect(container.settings.get(defs.sendspinLyrics), isFalse);
    });

    // A server, a token and the player identity the local player minted
    // at its first start: what the queue lookups are keyed on.
    const ma = {
      'ks.sendspin.ma_url': 'https://ma.local:8095',
      'ks.sendspin.ma_token': 'token',
      'ks.sendspin.client_id': 'abc123',
    };

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('without a Music Assistant server the heart and queue '
        'stay out', (tester) async {
      await pump(tester);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
      expect(find.byIcon(Icons.queue_music_rounded), findsNothing);
      // The transport is still centered: blanks stand in for them.
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
    });

    testWidgets('the heart reads the favorite and flips it', (tester) async {
      await pump(tester, settings: ma);
      await settle(tester);
      expect(_FakeApi.calls, contains('music/item_by_uri'));
      Color? heartColor(IconData icon) => tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byIcon(icon),
              matching: find.byType(IconButton),
            ),
          )
          .color;
      expect(heartColor(Icons.favorite_border_rounded), Colors.white38);
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await settle(tester);
      expect(_FakeApi.calls, contains('music/favorites/add_item'));
      expect(heartColor(Icons.favorite_rounded), Colors.white);
      await tester.tap(find.byIcon(Icons.favorite_rounded));
      await settle(tester);
      expect(_FakeApi.calls, contains('music/favorites/remove_item'));
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('the queue button opens the panel and persists it', (
      tester,
    ) async {
      await pump(tester, settings: {...ma, 'ks.sendspin.lyrics': true});
      await settle(tester);
      await tester.tap(find.byIcon(Icons.queue_music_rounded));
      await settle(tester);
      expect(container.settings.get(defs.sendspinFullscreenQueue), isTrue);
      // One slot: the queue took the lyrics down with it.
      expect(container.settings.get(defs.sendspinLyrics), isFalse);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('4:10'), findsOneWidget);
      // The playing row is the lit one: Music Assistant's own per-item
      // index is always zero, so the identity is the item id.
      // The rows, not the cover's own title, which says 'Song' too.
      FontWeight? weight(String text) => tester
          .widget<Text>(
            find.descendant(
              of: find.byType(ListView),
              matching: find.text(text),
            ),
          )
          .style
          ?.fontWeight;
      expect(weight('Song'), FontWeight.w700);
      expect(weight('Next'), FontWeight.w500);
      // A row jumps the queue there, by item id.
      await tester.tap(
        find.descendant(of: find.byType(ListView), matching: find.text('Next')),
      );
      await settle(tester);
      final play = _FakeApi.calls.indexOf('player_queues/play_index');
      expect(play, isNonNegative);
      expect(_FakeApi.args[play]['index'], 'item-b');
      // The lyrics button hands the slot back.
      await tester.tap(find.byIcon(Icons.lyrics_outlined));
      await settle(tester);
      expect(container.settings.get(defs.sendspinFullscreenQueue), isFalse);
      expect(container.settings.get(defs.sendspinLyrics), isTrue);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('a persisted queue setting opens the panel at once', (
      tester,
    ) async {
      await pump(
        tester,
        settings: {...ma, 'ks.sendspin.fullscreen_queue': true},
      );
      await settle(tester);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('a followed player keeps the lyrics toggle out', (
      tester,
    ) async {
      await pump(tester, settings: {'ks.sendspin.ma_player': 'p1'});
      expect(find.byIcon(Icons.lyrics_outlined), findsNothing);
      expect(find.byIcon(Icons.lyrics_rounded), findsNothing);
      // The transport is still there and still centered: the blank
      // stands in for the toggle.
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
    });

    testWidgets('controls off: the plain view, no close button', (
      tester,
    ) async {
      await pump(tester, settings: {'ks.sendspin.fullscreen_controls': false});
      expect(find.byType(Slider), findsNothing);
      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('the close button dismisses through the manager', (
      tester,
    ) async {
      await pump(tester);
      final dismissed = <String>[];
      container.bus.on<ScreensaverStateChanged>().listen((e) {
        if (!e.active) dismissed.add('stopped');
      });
      container.bus.publish(
        const SendspinNowPlayingChanged(active: true, playing: true),
      );
      await container.screensaver.start();
      await tester.pump();
      expect(container.screensaver.isActive, isTrue);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(container.screensaver.isActive, isFalse);
    });

    testWidgets('fits the Echo Show with the At a Glance row too', (
      tester,
    ) async {
      await pump(
        tester,
        size: const Size(960, 480),
        settings: {'ks.screensaver.glance_now_playing': true},
      );
      expect(find.byType(Slider), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits a portrait phone', (tester) async {
      await pump(tester, size: const Size(480, 960));
      expect(find.byType(Slider), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
