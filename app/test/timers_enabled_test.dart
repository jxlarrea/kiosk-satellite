import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enable timers (issue #1508): off, the Timers page is the switch alone and
/// the timer rows elsewhere go with it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsManager settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final log = Logger();
    settings = SettingsManager(EventBus(), CommandRegistry(log), log);
    await settings.init();
    // Every row that has a switch of its own shows, so only the master
    // switch can hide them.
    await settings.set(defs.voiceRuntime, 'native');
    await settings.set(defs.voiceEnabled, true);
    await settings.set(defs.voiceTimerPills, true);
    await settings.set(defs.voiceTimerSpeak, true);
    await settings.set(defs.voiceTimersShare, true);
    await settings.set(defs.ledEnabled, true);
  });

  final timerRows = [
    for (final def in defs.allSettings)
      if (def.category == 'Timers' &&
          !def.hidden &&
          def.key != defs.timersEnabled.key)
        def,
    defs.kioskAllowTimers,
    defs.ledTimersEnabled,
  ];

  test('is on by default', () {
    expect(settings.get(defs.timersEnabled), isTrue);
  });

  test('off hides every timer row, and on brings them back', () async {
    final shown = {
      for (final def in timerRows)
        if (settings.visible(def)) def.key,
    };
    // The rows gated on something else than these switches, such as the
    // language under a picked engine, may be hidden either way.
    expect(shown, contains(defs.voiceTimerPills.key));
    expect(shown, contains(defs.voiceChimeTimer.key));
    expect(shown, contains(defs.voiceTimersReceive.key));
    await settings.set(defs.timersEnabled, false);
    expect(settings.visible(defs.timersEnabled), isTrue);
    expect([
      for (final def in timerRows)
        if (settings.visible(def)) def.key,
    ], isEmpty);
    await settings.set(defs.timersEnabled, true);
    expect({
      for (final def in timerRows)
        if (settings.visible(def)) def.key,
    }, shown);
  });
}
