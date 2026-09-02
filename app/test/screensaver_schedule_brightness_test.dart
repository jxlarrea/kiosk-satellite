import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A schedule entry's brightness is optional (issue #411): the editors
/// write one only while the entry's Screensaver brightness switch is on.
/// Without one the entry follows the Screensaver brightness switch outside
/// the schedule, which may itself be off, leaving the panel to the device
/// (or adaptive brightness) the way the main screensaver does.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScreensaverManager saver;
  late List<double> levels;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
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
          name: 'getBrightness',
          description: 'recorder',
          handler: (_) async => const CommandResult.ok(0.8),
        ),
      );
    saver = ScreensaverManager(bus, commands, log, settings);
    await saver.init();
  }

  test('an entry with its own brightness applies it', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
      'ks.screensaver.brightness_enabled': false,
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"clock","brightness":0.3}]',
    });
    await saver.start();
    expect(levels, [0.3]);
  });

  test('an entry without one leaves the panel alone while the global switch '
      'is off', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
      'ks.screensaver.brightness_enabled': false,
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule': '[{"at":"00:00","mode":"clock"}]',
    });
    await saver.start();
    expect(levels, isEmpty);
    await saver.stop();
    expect(levels, isEmpty, reason: 'nothing was dimmed, nothing to restore');
  });

  test('an entry without one follows the global level while the switch is '
      'on', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
      'ks.screensaver.brightness_enabled': true,
      'ks.screensaver.brightness_level': 0.15,
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule': '[{"at":"00:00","mode":"clock"}]',
    });
    await saver.start();
    expect(levels, [0.15]);
    await saver.stop();
    expect(levels, [0.15, 0.8], reason: 'restored to the saved level');
  });

  test('a Dim entry without one uses the Dim level', () async {
    await build({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
      'ks.screensaver.dim_level': 0.1,
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule': '[{"at":"00:00","mode":"dim"}]',
    });
    await saver.start();
    expect(levels, [0.1]);
  });
}
