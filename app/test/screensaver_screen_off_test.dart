import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Turn screen off after" (Screensaver): once a session has run that long
/// the panel truly powers off (screenOff, quiet mode), the session stays
/// active behind the dark panel, and every dismiss source lights it back up
/// through stop()'s screenOn. One "minute" is shrunk to 10ms via the
/// injectable unit; the screenOff/screenOn registry commands are recorded
/// here instead of reaching a screen manager.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late SettingsManager settings;
  late ScreensaverManager saver;
  late List<Map<String, Object?>> offCalls;
  late int onCalls;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    offCalls = [];
    onCalls = 0;
    commands
      ..register(Command(
        name: 'screenOff',
        description: 'recorder',
        handler: (p) async {
          offCalls.add(p);
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'screenOn',
        description: 'recorder',
        handler: (_) async {
          onCalls++;
          return const CommandResult.ok();
        },
      ));
    saver = ScreensaverManager(bus, commands, log, settings,
        screenOffUnit: const Duration(milliseconds: 10));
    await saver.init();
  }

  test('the timer powers the panel off quietly and the session survives',
      () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
      'ks.screensaver.screen_off_minutes': 5,
    });
    await saver.start();
    expect(offCalls, isEmpty, reason: 'the countdown has not elapsed yet');

    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(offCalls, hasLength(1));
    // A timer firing overnight must never raise the device admin grant
    // screen; quiet mode is what asks for that.
    expect(offCalls.single['prompt'], isFalse);
    expect(saver.isActive, isTrue,
        reason: 'the session must stay active behind the dark panel: that '
            'is what routes every dismiss source through stop()');

    // The dark panel is the resting state; nothing keeps counting down.
    bus.publish(const ScreenStateChanged(on: false));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(offCalls, hasLength(1), reason: 'no second power-off while dark');
  });

  test('at 0 (the default) the panel is never powered off', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
    });
    await saver.start();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(offCalls, isEmpty);
  });

  test('dismissing from a dark panel lights it back up', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
      'ks.screensaver.screen_off_minutes': 5,
    });
    await saver.start();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    bus.publish(const ScreenStateChanged(on: false));
    await pumpEventQueue();

    // Any dismiss source lands here: motion and the wake word both call
    // stop() (via notifyActivity and the WakeWordDetected listener).
    final before = onCalls;
    saver.notifyActivity('motion');
    await pumpEventQueue();
    expect(saver.isActive, isFalse);
    expect(onCalls, greaterThan(before),
        reason: 'stop() must poke the panel back on');
  });

  test('the MQTT dismiss lights the panel even with no session up',
      () async {
    await build({'ks.screensaver.enabled': true});
    final result = await commands.execute('stopScreensaver', const {});
    expect(result.ok, isTrue);
    expect(onCalls, greaterThan(0),
        reason: 'the dismiss button means "bring the dashboard back", and '
            'half of that is the screen');
  });

  test('a mid-session wake gets a fresh countdown', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
      'ks.screensaver.screen_off_minutes': 5,
    });
    await saver.start();
    // The panel goes dark by other hands (power button) before the timer
    // fires: nothing left to count down for.
    bus.publish(const ScreenStateChanged(on: false));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(offCalls, isEmpty);

    // A power-button wake dismisses nothing — the screensaver is still up,
    // so it earns its own fresh countdown.
    bus.publish(const ScreenStateChanged(on: true));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(offCalls, hasLength(1));
  });

  test('moving the slider under a running session re-arms the countdown',
      () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
      'ks.screensaver.screen_off_minutes': 60,
    });
    await saver.start();
    await settings.set(defs.screensaverScreenOffMinutes, 5);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(offCalls, hasLength(1),
        reason: 'the shorter value must take over the running countdown');
  });
}
