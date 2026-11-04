import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An alarm ringing on a dimmed screensaver (the Clock or Weather Mood
/// takeover) lifts it to the level it had before it dimmed, the voice
/// overlay's rule, and hands the dimming back when it lets go. The sunrise
/// before it leaves the screensaver's level alone: its own ramp owns the
/// panel through the alarm brightness override.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CommandRegistry commands;
  late ScreensaverManager saver;
  late List<double> levels;
  late EventBus bus;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'weather_mood',
      'ks.screensaver.brightness_enabled': true,
      'ks.screensaver.brightness_level': 0.0,
      'ks.sendspin.fullscreen': true,
    });
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    levels = [];
    commands
      ..register(
        Command(
          name: 'getBrightness',
          description: '',
          handler: (_) async => const CommandResult.ok(0.8),
        ),
      )
      ..register(
        Command(
          name: 'setBrightness',
          description: '',
          handler: (p) async {
            levels.add((p['level'] as num).toDouble());
            return const CommandResult.ok();
          },
        ),
      );
    for (final name in ['screenOn', 'keepScreenAwake', 'unfreezeRendering']) {
      commands.register(
        Command(
          name: name,
          description: '',
          handler: (_) async => const CommandResult.ok(),
        ),
      );
    }
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    saver = ScreensaverManager(bus, commands, log, settings);
    await saver.init();
    addTearDown(() async {
      await saver.dispose();
      await settings.dispose();
      await bus.dispose();
    });
    await saver.start();
    await pumpEventQueue();
    expect(levels.last, 0.0);
  }

  test('a ringing alarm lights a dark screensaver until it lets go', () async {
    await build();
    await commands.execute('alarmTakeover', {'phase': 'sunrise'});
    expect(levels.last, 0.0);
    await commands.execute('alarmTakeover', {'phase': 'ringing'});
    expect(saver.alarmTakeover.value, 'ringing');
    expect(levels.last, 0.8);
    await commands.execute('alarmTakeover', {'phase': null});
    expect(saver.isActive, isTrue);
    expect(levels.last, 0.0);
  });

  test('Now Playing stays behind a ringing alarm and its music', () async {
    await build();
    await commands.execute('alarmTakeover', {'phase': 'ringing'});
    bus.publish(const SendspinNowPlayingChanged(active: true, playing: true));
    await pumpEventQueue();
    expect(saver.nowPlayingShown, isFalse);
    expect(saver.nowPlayingShowing, isFalse);
    // Once the alarm lets go, music that plays on shows again.
    await commands.execute('alarmTakeover', {'phase': null});
    await pumpEventQueue();
    expect(saver.nowPlayingShowing, isTrue);
  });
}
