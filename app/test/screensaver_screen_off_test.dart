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
  late List<Object> onCalls;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    // Local captures, not the outer variables: a stale timer from an
    // earlier test's manager firing mid-test must record into ITS OWN
    // lists, never the current test's.
    final off = <Map<String, Object?>>[];
    final on = <Object>[];
    offCalls = off;
    onCalls = on;
    commands
      ..register(
        Command(
          name: 'screenOff',
          description: 'recorder',
          handler: (p) async {
            off.add(p);
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'screenOn',
          description: 'recorder',
          handler: (_) async {
            on.add(true);
            return const CommandResult.ok();
          },
        ),
      );
    saver = ScreensaverManager(
      bus,
      commands,
      log,
      settings,
      screenOffUnit: const Duration(milliseconds: 10),
    );
    await saver.init();
  }

  test(
    'the timer powers the panel off quietly and the session survives',
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
      expect(
        saver.isActive,
        isTrue,
        reason:
            'the session must stay active behind the dark panel: that '
            'is what routes every dismiss source through stop()',
      );

      // The dark panel is the resting state; nothing keeps counting down.
      bus.publish(const ScreenStateChanged(on: false));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(offCalls, hasLength(1), reason: 'no second power-off while dark');
    },
  );

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
    final before = onCalls.length;
    saver.notifyActivity('motion');
    await pumpEventQueue();
    expect(saver.isActive, isFalse);
    expect(
      onCalls.length,
      greaterThan(before),
      reason: 'stop() must poke the panel back on',
    );
  });

  test(
    'the ESPHome dismiss lights the panel even with no session up',
    () async {
      await build({'ks.screensaver.enabled': true});
      final result = await commands.execute('stopScreensaver', const {});
      expect(result.ok, isTrue);
      expect(
        onCalls.length,
        greaterThan(0),
        reason:
            'the dismiss button means "bring the dashboard back", and '
            'half of that is the screen',
      );
    },
  );

  test('an app-sourced mid-session wake keeps the session, with a fresh '
      'countdown', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
      'ks.screensaver.screen_off_minutes': 5,
    });
    await saver.start();
    // The panel goes dark by other hands before the timer fires: nothing
    // left to count down for.
    bus.publish(const ScreenStateChanged(on: false));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(offCalls, isEmpty);

    // An automation switching the panel on (the ESPHome Screen switch: source
    // app) wants the screensaver it left showing — a photo frame's morning
    // switch-on — so the session survives and earns a fresh countdown.
    bus.publish(const ScreenStateChanged(on: true, source: 'app'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(saver.isActive, isTrue);
    expect(offCalls, hasLength(1));
  });

  test(
    'a system wake (power button, double-tap) dismisses to the dashboard',
    () async {
      await build({
        'ks.screensaver.enabled': true,
        'ks.screensaver.mode': 'black',
        'ks.screensaver.screen_off_minutes': 5,
      });
      await saver.start();
      bus.publish(const ScreenStateChanged(on: false));
      await pumpEventQueue();

      // A person waking the panel is activity like a touch: the session ends
      // and the dashboard is what they see.
      final before = onCalls.length;
      bus.publish(const ScreenStateChanged(on: true));
      await pumpEventQueue();
      expect(saver.isActive, isFalse);
      expect(onCalls.length, greaterThan(before));
    },
  );

  test('a system wake with no session up restarts the idle clock '
      '(issue #348)', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
      'ks.screensaver.timeout_seconds': 1,
    });
    // The OS timed the panel out and a person pressed the power button
    // 600ms into the idle countdown. Without the reset the screensaver
    // would start at the 1s mark, on the dashboard they just woke.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    bus.publish(const ScreenStateChanged(on: false));
    bus.publish(const ScreenStateChanged(on: true));
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(
      saver.isActive,
      isFalse,
      reason: 'the wake restarted the idle clock',
    );
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(
      saver.isActive,
      isTrue,
      reason: 'a full idle period after the wake starts the screensaver',
    );
  });

  test('an app wake with no session up leaves the idle clock alone', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
      'ks.screensaver.timeout_seconds': 1,
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
    bus.publish(const ScreenStateChanged(on: true, source: 'app'));
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(
      saver.isActive,
      isTrue,
      reason: 'an automation lighting the panel is not a person at it',
    );
  });

  test('under lockdown a system wake leaves the screensaver up', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
      'ks.screensaver.screen_off_minutes': 5,
      'ks.lockdown.enabled': true,
      'ks.lockdown.allow_screensaver': true,
    });
    await saver.start();
    expect(saver.isActive, isTrue);
    bus.publish(const ScreenStateChanged(on: false));
    await pumpEventQueue();

    // Lockdown keeps its screen locked here exactly like it does for
    // motion: the wake lights the panel, the screensaver stays.
    bus.publish(const ScreenStateChanged(on: true));
    await pumpEventQueue();
    expect(saver.isActive, isTrue);
  });

  test(
    'moving the slider under a running session re-arms the countdown',
    () async {
      await build({
        'ks.screensaver.enabled': true,
        'ks.screensaver.mode': 'black',
        'ks.screensaver.screen_off_minutes': 60,
      });
      await saver.start();
      await settings.set(defs.screensaverScreenOffMinutes, 5);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        offCalls,
        hasLength(1),
        reason: 'the shorter value must take over the running countdown',
      );
    },
  );
}
