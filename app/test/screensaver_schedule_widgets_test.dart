import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The schedule's per-entry widgets override: widgets on the day entry, a
/// bare screen on the night one. The manager only publishes the policy —
/// the UI layer watches [ScreensaverManager.scheduleWidgets] and mounts or
/// unmounts the corner overlays from it. Registry commands the screensaver
/// calls (setBrightness, keepScreenAwake, ...) are absent here and fail
/// soft.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScreensaverManager saver;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    saver = ScreensaverManager(bus, commands, log, settings);
  }

  test('a widgets:false entry withholds them for its session', () async {
    await build({
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"clock","widgets":false}]',
    });
    expect(saver.scheduleWidgets.value, isNull);
    await saver.start();
    await pumpEventQueue();
    expect(saver.scheduleWidgets.value, isFalse);
    // Between sessions the override lapses: nothing is showing to hide.
    await saver.stop();
    await pumpEventQueue();
    expect(saver.scheduleWidgets.value, isNull);
  });

  test('a widgets:true entry says so explicitly', () async {
    await build({
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"clock","widgets":true}]',
    });
    await saver.start();
    await pumpEventQueue();
    expect(saver.scheduleWidgets.value, isTrue);
  });

  test('an entry without the field follows the Widgets group', () async {
    await build({
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule': '[{"at":"00:00","mode":"clock"}]',
    });
    await saver.start();
    await pumpEventQueue();
    expect(saver.scheduleWidgets.value, isNull);
  });

  test('the glance override rides alongside, independently', () async {
    await build({
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"black","widgets":true,"glance":false}]',
    });
    await saver.start();
    await pumpEventQueue();
    expect(saver.scheduleWidgets.value, isTrue);
    expect(saver.scheduleGlance.value, isFalse);
    await saver.stop();
    await pumpEventQueue();
    expect(saver.scheduleGlance.value, isNull);
  });

  test('a schedule that is switched off overrides nothing', () async {
    await build({
      'ks.screensaver.schedule_enabled': false,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"clock","widgets":false}]',
    });
    await saver.start();
    await pumpEventQueue();
    expect(saver.scheduleWidgets.value, isNull);
    expect(saver.scheduleGlance.value, isNull);
  });
}
