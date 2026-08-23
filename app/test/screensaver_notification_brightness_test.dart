import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A notification over a dimmed screensaver (issue #278).
///
/// Kiosks run their screensaver at a few percent brightness, which is
/// exactly dark enough that a message arriving on it cannot be read. While
/// a card is up the session borrows back the brightness it saved when it
/// started, and gives it back when the last card goes: the overlay itself
/// never moves, so the clock or the photo stays where it was.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late SettingsManager settings;
  late ScreensaverManager saver;
  late List<double> levels;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    final applied = <double>[];
    levels = applied;
    commands
      ..register(
        Command(
          name: 'setBrightness',
          description: 'recorder',
          handler: (p) async {
            applied.add((p['level']! as num).toDouble());
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          // The level the session saves and returns to: the kiosk's own
          // brightness before any dimming.
          name: 'getBrightness',
          description: 'recorder',
          handler: (_) async => const CommandResult.ok(0.8),
        ),
      );
    saver = ScreensaverManager(bus, commands, log, settings);
    await saver.init();
  }

  Future<void> notifications(int count) async {
    bus.publish(NotificationsChanged(count: count));
    await pumpEventQueue();
  }

  test('a notification lifts a dimmed content mode, and the last one lets '
      'it back down', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
      'ks.screensaver.brightness_enabled': true,
      'ks.screensaver.brightness_level': 0.05,
    });
    await saver.start();
    expect(levels, [0.05]);

    await notifications(1);
    expect(levels.last, 0.8, reason: 'the level the session saved');
    // A second card changes nothing: it is already readable.
    await notifications(2);
    expect(levels, [0.05, 0.8]);

    await notifications(0);
    expect(levels.last, 0.05, reason: 'back to the screensaver level');
    // The clock is still the clock; only the backlight moved.
    expect(saver.activeView.value, 'clock');
    expect(saver.isActive, isTrue);
  });

  test('the black screensaver lights up for one too', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
    });
    await saver.start();
    expect(levels, [0]);

    await notifications(1);
    expect(levels.last, 0.8);
    expect(saver.activeView.value, 'black',
        reason: 'the black overlay stays: the card is drawn over it');

    await notifications(0);
    expect(levels.last, 0);
  });

  test('Dim, which shows no overlay, lifts the backlight the same way',
      () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'dim',
      'ks.screensaver.dim_level': 0.02,
    });
    await saver.start();
    expect(levels, [0.02]);
    await notifications(1);
    expect(levels.last, 0.8);
    await notifications(0);
    expect(levels.last, 0.02);
  });

  test('turned off, a notification leaves the darkness alone', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
      'ks.screensaver.brightness_enabled': true,
      'ks.screensaver.brightness_level': 0.05,
      'ks.screensaver.notification_brightness': false,
    });
    await saver.start();
    await notifications(1);
    expect(levels, [0.05], reason: 'nothing more was applied');
  });

  test('with no screensaver showing, a notification changes no brightness',
      () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
      'ks.screensaver.brightness_enabled': true,
    });
    await notifications(1);
    await notifications(0);
    expect(levels, isEmpty);
  });

  test('an undimmed screensaver is left alone as well', () async {
    // Content mode with the separate brightness off: the session never
    // dimmed anything, so there is nothing to lift or to restore.
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
    });
    await saver.start();
    await notifications(1);
    await notifications(0);
    expect(levels, isEmpty);
  });

  test('the setting is one of the app settings, on by default', () {
    expect(defs.allSettings, contains(defs.screensaverNotificationBrightness));
    expect(defs.screensaverNotificationBrightness.defaultValue, isTrue);
  });
}
