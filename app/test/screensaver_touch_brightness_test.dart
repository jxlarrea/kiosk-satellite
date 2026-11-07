import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Brighten for touch interactions: a touch the screensaver keeps, on a
/// card drawn over it or the first tap of a double tap, lifts its dimming
/// to the level it saved, and the dimming comes back that many seconds
/// after the last such touch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScreensaverManager saver;
  late List<double> levels;
  late DateTime now;

  void build(FakeAsync async, Map<String, Object> initial) {
    SharedPreferences.setMockInitialValues(initial);
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    settings.init();
    async.flushMicrotasks();
    levels = [];
    commands
      ..register(
        Command(
          name: 'setBrightness',
          description: 'recorder',
          handler: (p) async {
            levels.add((p['level']! as num).toDouble());
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'getBrightness',
          description: 'recorder',
          handler: (_) async => const CommandResult.ok(0.8),
        ),
      );
    saver = ScreensaverManager(bus, commands, log, settings);
    now = DateTime(2026, 11, 7, 12);
    saver.clock = () => now;
    saver.init();
    async.flushMicrotasks();
    saver.start();
    async.flushMicrotasks();
  }

  void wait(FakeAsync async, int seconds) {
    now = now.add(Duration(seconds: seconds));
    async.elapse(Duration(seconds: seconds));
  }

  // A touch on something over the screensaver: marked on its way down,
  // then reported by the kiosk screen.
  void controlTouch(FakeAsync async) {
    saver.markControlTouch();
    saver.notifyActivity('touch');
    async.flushMicrotasks();
  }

  const dimmedClock = {
    'ks.screensaver.enabled': true,
    'ks.screensaver.mode': 'clock',
    'ks.screensaver.brightness_enabled': true,
    'ks.screensaver.brightness_level': 0.05,
  };

  test('a kept touch lifts the dimming until 5 s after the last one', () {
    fakeAsync((async) {
      build(async, dimmedClock);
      expect(levels, [0.05]);

      controlTouch(async);
      expect(levels, [0.05, 0.8]);
      wait(async, 3);
      // Another touch while lifted sets nothing and starts the 5 s again.
      controlTouch(async);
      expect(levels, [0.05, 0.8]);
      wait(async, 4);
      async.flushMicrotasks();
      expect(levels, [0.05, 0.8]);
      wait(async, 1);
      async.flushMicrotasks();
      expect(levels, [0.05, 0.8, 0.05]);
      expect(saver.isActive, isTrue);
      expect(saver.activeView.value, 'clock');
      saver.dispose();
    });
  });

  test('the first tap of a double tap lifts it too', () {
    fakeAsync((async) {
      build(async, {
        ...dimmedClock,
        'ks.screensaver.mode': 'website',
        'ks.screensaver.website_double_tap': true,
      });
      saver.notifyActivity('touch');
      async.flushMicrotasks();
      expect(saver.isActive, isTrue);
      expect(levels.last, 0.8);
      saver.dispose();
    });
  });

  test('a touch that dismisses the screensaver leaves no lift behind', () {
    fakeAsync((async) {
      build(async, dimmedClock);
      controlTouch(async);
      expect(levels.last, 0.8);
      wait(async, 1);
      saver.notifyActivity('touch');
      async.flushMicrotasks();
      expect(saver.isActive, isFalse);
      final after = levels.length;
      wait(async, 10);
      async.flushMicrotasks();
      expect(levels.length, after, reason: 'the lift ended with the session');
      saver.dispose();
    });
  });

  test('0 turns it off', () {
    fakeAsync((async) {
      build(async, {
        ...dimmedClock,
        'ks.screensaver.touch_brightness_seconds': 0,
      });
      controlTouch(async);
      expect(levels, [0.05]);
      saver.dispose();
    });
  });

  test('an undimmed screensaver is left alone', () {
    fakeAsync((async) {
      build(async, {
        'ks.screensaver.enabled': true,
        'ks.screensaver.mode': 'clock',
      });
      controlTouch(async);
      wait(async, 6);
      async.flushMicrotasks();
      expect(levels, isEmpty);
      saver.dispose();
    });
  });

  test('the setting is one of the app settings, 5 s by default', () {
    expect(defs.allSettings, contains(defs.screensaverTouchBrightnessSeconds));
    expect(defs.screensaverTouchBrightnessSeconds.defaultValue, 5);
    expect(defs.screensaverTouchBrightnessSeconds.min, 0);
    expect(defs.screensaverTouchBrightnessSeconds.max, 15);
  });
}
