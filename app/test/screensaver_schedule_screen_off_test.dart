import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A schedule entry's own "Turn screen off after" (issue #437): present,
/// it is the countdown for that entry's hours, 0 keeping the panel on even
/// over a set slider outside the schedule; absent, the entry follows that
/// slider. One "minute" is shrunk to 10ms via the injectable unit and the
/// screenOff command is recorded here instead of reaching a screen manager.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late SettingsManager settings;
  late ScreensaverManager saver;
  late List<Map<String, Object?>> offCalls;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    // A local capture, so a stale timer from an earlier test's manager
    // records into its own list, never the current test's.
    final off = <Map<String, Object?>>[];
    offCalls = off;
    commands.register(
      Command(
        name: 'screenOff',
        description: 'recorder',
        handler: (p) async {
          off.add(p);
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

  test('an entry with its own minutes powers the panel off over a slider '
      'at 0', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
      'ks.screensaver.screen_off_minutes': 0,
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"black","screen_off":5}]',
    });
    await saver.start();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(offCalls, hasLength(1));
    expect(offCalls.single['prompt'], isFalse);
    expect(saver.isActive, isTrue);
  });

  test('an entry at 0 keeps the panel on over a set slider', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
      'ks.screensaver.screen_off_minutes': 5,
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"clock","screen_off":0}]',
    });
    await saver.start();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(offCalls, isEmpty);
  });

  test('an entry without its own follows the slider', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
      'ks.screensaver.screen_off_minutes': 5,
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule': '[{"at":"00:00","mode":"black"}]',
    });
    await saver.start();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(offCalls, hasLength(1));
  });

  test('a schedule switched off overrides nothing', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
      'ks.screensaver.screen_off_minutes': 0,
      'ks.screensaver.schedule_enabled': false,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"black","screen_off":5}]',
    });
    await saver.start();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(offCalls, isEmpty);
  });

  test(
    'editing the entry under a running session re-arms the countdown',
    () async {
      await build({
        'ks.screensaver.enabled': true,
        'ks.screensaver.mode': 'clock',
        'ks.screensaver.screen_off_minutes': 0,
        'ks.screensaver.schedule_enabled': true,
        'ks.screensaver.schedule': '[{"at":"00:00","mode":"black"}]',
      });
      await saver.start();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(offCalls, isEmpty, reason: 'nothing counts down at 0');
      await settings.set(
        defs.screensaverSchedule,
        '[{"at":"00:00","mode":"black","screen_off":5}]',
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(offCalls, hasLength(1), reason: 'the edit is a live preview');
    },
  );

  test(
    'the slider moving under an entry with its own changes nothing',
    () async {
      await build({
        'ks.screensaver.enabled': true,
        'ks.screensaver.mode': 'clock',
        'ks.screensaver.screen_off_minutes': 0,
        'ks.screensaver.schedule_enabled': true,
        'ks.screensaver.schedule':
            '[{"at":"00:00","mode":"clock","screen_off":0}]',
      });
      await saver.start();
      await settings.set(defs.screensaverScreenOffMinutes, 5);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(offCalls, isEmpty, reason: 'the entry says never');
    },
  );

  test(
    'a reapply that leaves the minutes alone keeps the running countdown',
    () async {
      await build({
        'ks.screensaver.enabled': true,
        'ks.screensaver.mode': 'clock',
        'ks.screensaver.screen_off_minutes': 0,
        'ks.screensaver.schedule_enabled': true,
        'ks.screensaver.schedule':
            '[{"at":"00:00","mode":"black","screen_off":5}]',
      });
      await saver.start();
      // Half-way through, a notification comes and goes: the visuals are
      // reapplied twice, the clock must not start over either time.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      bus.publish(const NotificationsChanged(count: 1));
      await pumpEventQueue();
      bus.publish(const NotificationsChanged(count: 0));
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(offCalls, hasLength(1), reason: 'the original countdown ran out');
    },
  );

  test('a dark panel is left alone by a live edit', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
      'ks.screensaver.screen_off_minutes': 0,
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"black","screen_off":5}]',
    });
    await saver.start();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(offCalls, hasLength(1));
    bus.publish(const ScreenStateChanged(on: false));
    await pumpEventQueue();
    await settings.set(
      defs.screensaverSchedule,
      '[{"at":"00:00","mode":"black","screen_off":10}]',
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(offCalls, hasLength(1), reason: 'no second power-off while dark');
  });
}
