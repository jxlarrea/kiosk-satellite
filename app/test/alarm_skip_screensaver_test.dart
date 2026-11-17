import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/alarms/alarm_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/alarm_ring_overlay.dart';
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:kiosk_satellite/ui/weather_mood_information.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Skip before an alarm (issue #1479): the Clock and Weather Mood
/// screensavers put a button under their clock while the alarm manager
/// offers the next ring, take it away when it stops offering, and leave it
/// out while an alarm rings on them. It fits from a Smart Clock sized
/// panel up.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppContainer> container(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.local:8123',
      'ks.ha.token': 'token',
      'ks.alarms.clock_24h': false,
      ...prefs,
    });
    final c = AppContainer();
    await c.settings.init();
    return c;
  }

  final at = DateTime(2026, 10, 2, 7);
  AlarmStatus offering() => AlarmStatus(skip: (ids: const ['a'], at: at));

  Finder skip() => find.byType(AlarmSkipButton);

  for (final size in const [Size(1280, 800), Size(800, 480), Size(600, 360)]) {
    testWidgets('the Clock screensaver shows and drops Skip at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = await container({
        'ks.screensaver.mode': 'clock',
        'ks.screensaver.clock_show_date': true,
      });
      await tester.pumpWidget(
        MaterialApp(home: ClockScreensaver(container: c)),
      );
      expect(skip(), findsNothing);
      c.alarms.status.value = offering();
      await tester.pump();
      expect(skip(), findsOneWidget);
      expect(find.text('Skip 7:00 AM alarm'), findsOneWidget);
      final box = tester.getRect(skip());
      expect(box.bottom, lessThanOrEqualTo(size.height));
      expect(box.top, greaterThan(0));
      c.alarms.status.value = const AlarmStatus();
      await tester.pump();
      expect(skip(), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Skip offered before the face starts still goes away', (
    tester,
  ) async {
    final c = await container({'ks.screensaver.mode': 'clock'});
    c.alarms.status.value = offering();
    await tester.pumpWidget(MaterialApp(home: ClockScreensaver(container: c)));
    expect(skip(), findsOneWidget);
    c.alarms.status.value = const AlarmStatus();
    await tester.pump();
    expect(skip(), findsNothing);
    await tester.pumpWidget(const SizedBox());
    final readings = WeatherMoodReadings()..update({'state': 'sunny'});
    c.alarms.status.value = offering();
    await tester.pumpWidget(
      MaterialApp(
        home: WeatherMoodInformation(container: c, readings: readings),
      ),
    );
    expect(skip(), findsOneWidget);
    c.alarms.status.value = const AlarmStatus();
    await tester.pump();
    expect(skip(), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a ringing takeover shows Snooze and Stop, not Skip', (
    tester,
  ) async {
    final c = await container({'ks.screensaver.mode': 'clock'});
    c.alarms.status.value = offering();
    c.screensaver.alarmTakeover.value = 'ringing';
    await tester.pumpWidget(MaterialApp(home: ClockScreensaver(container: c)));
    expect(skip(), findsNothing);
    expect(find.byType(AlarmTakeoverControls), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the Weather Mood clock shows Skip and lets it be touched', (
    tester,
  ) async {
    final c = await container({
      'ks.screensaver.mode': 'weather_mood',
      'ks.screensaver.weather_bar': false,
    });
    final readings = WeatherMoodReadings()..update({'state': 'sunny'});
    await tester.pumpWidget(
      MaterialApp(
        home: WeatherMoodInformation(container: c, readings: readings),
      ),
    );
    expect(skip(), findsNothing);
    c.alarms.status.value = offering();
    await tester.pump();
    expect(skip(), findsOneWidget);
    final ignore = tester.widget<IgnorePointer>(
      find.ancestor(of: skip(), matching: find.byType(IgnorePointer)).last,
    );
    expect(ignore.ignoring, isFalse);
    // With its clock off, Skip still shows.
    await c.settings.set(defs.screensaverWeatherClock, false);
    await tester.pumpWidget(
      MaterialApp(
        home: WeatherMoodInformation(container: c, readings: readings),
      ),
    );
    expect(skip(), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('the setting defaults to 10 minutes and offers Off', () {
    expect(defs.alarmsSkipMinutes.defaultValue, '10');
    expect(defs.alarmsSkipMinutes.options, contains('0'));
  });
}
