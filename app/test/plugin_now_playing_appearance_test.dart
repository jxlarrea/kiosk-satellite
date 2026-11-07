import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_host_api.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A plugin drawn over the screensaver reads `nowPlaying` to step aside for
/// the player (issue #1335). The real manager feeds the host API here, so
/// these cover what the player does to the flag and not just the field.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EventBus bus;
  late CommandRegistry commands;
  late ScreensaverManager saver;
  late PluginHostApi api;
  late List<Map<String, Object?>> events;

  Future<void> build(
    String mode, {
    bool playerEnabled = true,
    bool dark = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': mode,
      'ks.screensaver.clock_night': dark,
      'ks.sendspin.fullscreen': playerEnabled,
    });
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    for (final name in [
      'setBrightness',
      'screenOn',
      'keepScreenAwake',
      'unfreezeRendering',
      'leaveScreensaver',
    ]) {
      commands.register(
        Command(
          name: name,
          description: '',
          handler: (_) async => const CommandResult.ok(),
        ),
      );
    }
    commands.register(
      Command(
        name: 'getBrightness',
        description: '',
        handler: (_) async => const CommandResult.ok(0.8),
      ),
    );
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    saver = ScreensaverManager(
      bus,
      commands,
      log,
      settings,
      lightReading: () => 0,
    );
    await saver.init();
    events = [];
    api = PluginHostApi(
      commands,
      bus,
      (event) async => events.add(event),
      screensaver: PluginScreensaverFeed(
        view: saver.activeView,
        night: saver.clockNight,
        nowPlaying: () => saver.nowPlayingShown,
        nowPlayingShared: () => saver.nowPlayingShared,
        settings: settings,
      ),
    );
    const session = {'id': 'agenda', 'session': 'one'};
    api
      ..open({
        ...session,
        'capabilities': ['host.read'],
      })
      ..subscription({
        ...session,
        'event': 'screensaver.appearance',
        'subscribed': true,
      });
    addTearDown(() async {
      await api.dispose();
      await saver.dispose();
      await settings.dispose();
      await bus.dispose();
    });
    await saver.start();
    await pumpEventQueue();
  }

  Future<Map> appearance() async {
    final result = await api.execute({
      'id': 'agenda',
      'session': 'one',
      'command': 'getScreensaverAppearance',
      'arguments': const <String, Object?>{},
    });
    return result['data'] as Map;
  }

  /// Lets the batched event go out and returns [field] from each one the
  /// plugin received.
  Future<List<Object?>> delivered([String field = 'nowPlaying']) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final values = [
      for (final event in events)
        if (event['event'] == 'screensaver.appearance')
          (event['payload'] as Map)[field],
    ];
    events.clear();
    return values;
  }

  /// The layout the screensaver overlay reports once it has drawn.
  Future<void> layout({required bool shared}) async {
    saver.setNowPlayingShared(shared);
    await pumpEventQueue();
  }

  Future<void> player({required bool active, required bool playing}) async {
    bus.publish(SendspinNowPlayingChanged(active: active, playing: playing));
    await pumpEventQueue();
  }

  for (final mode in ['clock', 'photos']) {
    test('the player opening and closing over $mode is an event', () async {
      await build(mode);
      await delivered();
      expect(await appearance(), containsPair('nowPlaying', false));

      await player(active: true, playing: true);
      expect(await delivered(), [true]);
      expect(await appearance(), containsPair('view', mode));
      expect(await appearance(), containsPair('nowPlaying', true));

      // The same state reported again is not news.
      await player(active: true, playing: true);
      expect(await delivered(), isEmpty);

      await player(active: false, playing: false);
      expect(await delivered(), [false]);
      expect(await appearance(), containsPair('view', mode));
      expect(await appearance(), containsPair('nowPlaying', false));
    });
  }

  test('a paused player that stays on screen still counts', () async {
    await build('clock');
    await player(active: true, playing: true);
    await delivered();

    await player(active: true, playing: false);
    expect(await delivered(), isEmpty);
    expect(await appearance(), containsPair('nowPlaying', true));
  });

  for (final mode in ['clock', 'photos', 'dim']) {
    test('a shared layout over $mode counts and is an event', () async {
      await build(mode);
      await player(active: true, playing: true);
      await delivered();
      expect(await appearance(), containsPair('nowPlayingShared', false));

      await layout(shared: true);
      expect(await delivered('nowPlayingShared'), [true]);
      expect(await appearance(), containsPair('nowPlaying', true));

      // A rotation can leave no room to share.
      await layout(shared: false);
      expect(await delivered('nowPlayingShared'), [false]);
      expect(await appearance(), containsPair('nowPlaying', true));
    });
  }

  test('a shared layout ends with the player', () async {
    await build('clock');
    await player(active: true, playing: true);
    await layout(shared: true);
    await delivered();

    await player(active: false, playing: false);
    expect(await delivered('nowPlayingShared'), [false]);
    expect(await appearance(), containsPair('nowPlaying', false));
  });

  test('Night mode stays on beside a shared player', () async {
    await build('clock', dark: true);
    await delivered();
    expect(await appearance(), containsPair('night', true));

    // A player that fills the screen hides the face.
    await player(active: true, playing: true);
    expect(await delivered('night'), [false]);

    await layout(shared: true);
    expect(await delivered('night'), [true]);
    expect(await appearance(), containsPair('textColor', 0xFF822222));

    await layout(shared: false);
    expect(await delivered('night'), [false]);
  });

  test('a plugin still hears screensaver.view', () async {
    await build('clock');
    api.subscription({
      'id': 'agenda',
      'session': 'one',
      'event': 'screensaver.view',
      'subscribed': true,
    });
    events.clear();

    await player(active: true, playing: true);
    await layout(shared: true);
    await delivered();
    await saver.stop();
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(
      events.where((e) => e['event'] == 'screensaver.view').last['payload'],
      containsPair('view', null),
    );
  });

  test('music with the player turned off does not count', () async {
    await build('clock', playerEnabled: false);
    await delivered();

    await player(active: true, playing: true);
    expect(await delivered(), isEmpty);
    expect(await appearance(), containsPair('view', 'clock'));
    expect(await appearance(), containsPair('nowPlaying', false));
  });

  test('a player launched by playback counts', () async {
    await build('clock');
    await saver.stop();
    await pumpEventQueue();
    await delivered();

    await player(active: true, playing: true);
    await pumpEventQueue();
    expect(await delivered(), [true]);
  });

  test('an alarm over the player clears it until the alarm lets go', () async {
    await build('clock');
    await player(active: true, playing: true);
    await delivered();

    await commands.execute('alarmTakeover', {'phase': 'ringing'});
    await pumpEventQueue();
    expect(await delivered(), [false]);

    await commands.execute('alarmTakeover', {'phase': null});
    await pumpEventQueue();
    expect(await delivered(), [true]);
  });

  test('the screensaver closing under the player clears it', () async {
    await build('clock');
    await player(active: true, playing: true);
    await delivered();

    await saver.stop();
    await pumpEventQueue();
    expect(await delivered(), [false]);
    expect(await appearance(), containsPair('view', null));
  });
}
