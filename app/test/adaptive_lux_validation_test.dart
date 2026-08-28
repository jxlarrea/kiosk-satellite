import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two ends of the adaptive brightness curve validate against each
/// other (issue #343): Dark room stays below Bright room, through the
/// cross validator the settings manager runs with the other settings in
/// view, and a batch moving both ends is judged against itself.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsManager settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'ks.screen.adaptive_dark_lux': 5,
      'ks.screen.adaptive_bright_lux': 300,
    });
    final bus = EventBus();
    final log = Logger();
    settings = SettingsManager(bus, CommandRegistry(log), log);
    await settings.init();
  });

  test('a dark level at or above the bright one is refused, with the bright '
      'value in the message', () async {
    expect(
      settings.validate(defs.adaptiveDarkLux, 300),
      'Dark room must be below Bright room (300 lx)',
    );
    expect(settings.validate(defs.adaptiveDarkLux, 400), isNotNull);
    expect(settings.validate(defs.adaptiveDarkLux, 299), isNull);
    expect(await settings.setFromJson(defs.adaptiveDarkLux.key, 400), isFalse);
    expect(settings.get(defs.adaptiveDarkLux), 5);
  });

  test('a bright level at or below the dark one is refused', () async {
    expect(
      settings.validate(defs.adaptiveBrightLux, 5),
      'Bright room must be above Dark room (5 lx)',
    );
    expect(settings.validate(defs.adaptiveBrightLux, 6), isNull);
    expect(await settings.setFromJson(defs.adaptiveBrightLux.key, 4), isFalse);
    expect(settings.get(defs.adaptiveBrightLux), 300);
  });

  test('the own validator speaks first', () {
    expect(
      settings.validate(defs.adaptiveDarkLux, 0),
      'Enter a light level above 0 lx',
    );
  });

  test('a batch moving both ends past the old positions passes, judged '
      'against itself', () async {
    final batch = {
      defs.adaptiveDarkLux.key: 400,
      defs.adaptiveBrightLux.key: 500,
    };
    for (final entry in batch.entries) {
      expect(
        await settings.setFromJson(entry.key, entry.value, batch: batch),
        isTrue,
        reason: entry.key,
      );
    }
    expect(settings.get(defs.adaptiveDarkLux), 400);
    expect(settings.get(defs.adaptiveBrightLux), 500);
    // And a batch that crosses itself is refused as one.
    final crossed = {
      defs.adaptiveDarkLux.key: 600,
      defs.adaptiveBrightLux.key: 550,
    };
    for (final entry in crossed.entries) {
      expect(
        await settings.setFromJson(entry.key, entry.value, batch: crossed),
        isFalse,
        reason: entry.key,
      );
    }
  });

  test('an import is a batch too', () async {
    expect(
      await settings.import({
        'screen.adaptive_dark_lux': 1000,
        'screen.adaptive_bright_lux': 2000,
      }),
      2,
    );
    expect(settings.get(defs.adaptiveDarkLux), 1000);
  });
}
