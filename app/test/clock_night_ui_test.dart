import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Clock screensaver's Night mode (issue #391): the settings page
/// gates the group on the ambient light sensor the same way adaptive
/// brightness does, and the face itself swaps the digit color with the
/// room's light, live off the sensor events.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const noSensor = 'No ambient light sensor on this device.';
  const nightRed = Color(0xFF822222);

  Future<AppContainer> makeContainer(
    Map<String, Object> prefs, {
    bool sensor = true,
    double? lux,
  }) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.local:8123',
      'ks.ha.token': 'token',
      'ks.screensaver.mode': 'clock',
      ...prefs,
    });
    final container = AppContainer();
    await container.settings.init();
    container.device.hasLightSensor = sensor;
    container.device.lightLux = lux;
    return container;
  }

  group('settings page', () {
    Future<AppContainer> open(
      WidgetTester tester,
      Map<String, Object> prefs, {
      bool sensor = true,
    }) async {
      final container = await makeContainer(prefs, sensor: sensor, lux: 12);
      container.homeAssistant.connectionOk.value = true;
      // Tall enough that a page renders whole: off-screen rows do not exist.
      tester.view.physicalSize = const Size(500, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(container: container)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      return container;
    }

    Future<void> tab(WidgetTester tester, String title) async {
      await tester.tap(find.text(title).first);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    testWidgets('without the sensor the switch is disabled with the reason', (
      tester,
    ) async {
      await open(tester, {}, sensor: false);
      await tab(tester, 'Screensaver');
      await tab(tester, 'Clock screensaver');
      expect(find.text('Night mode'), findsWidgets);
      expect(find.text(noSensor), findsOneWidget);
    });

    testWidgets('the switch reveals the light level and the color', (
      tester,
    ) async {
      await open(tester, {'ks.screensaver.clock_night': true});
      await tab(tester, 'Screensaver');
      await tab(tester, 'Clock screensaver');
      expect(find.text(noSensor), findsNothing);
      expect(find.text('Light level'), findsOneWidget);
      expect(find.text('5 lx'), findsOneWidget);
      expect(find.text('Night color'), findsOneWidget);
    });

    testWidgets('off, the group is just the switch', (tester) async {
      await open(tester, {});
      await tab(tester, 'Screensaver');
      await tab(tester, 'Clock screensaver');
      expect(find.text('Light level'), findsNothing);
      expect(find.text('Night color'), findsNothing);
    });
  });

  group('clock face', () {
    Color? digitColor(WidgetTester tester) {
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        if ((t.data ?? '').contains(':')) return t.style?.color;
      }
      return null;
    }

    Future<AppContainer> pumpClock(
      WidgetTester tester, {
      Map<String, Object> prefs = const {},
      bool sensor = true,
      double? lux,
    }) async {
      final container = await makeContainer(
        {
          'ks.screensaver.clock_night': true,
          // The date renders through the locale machinery, which is not the
          // subject here.
          'ks.screensaver.clock_show_date': false,
          ...prefs,
        },
        sensor: sensor,
        lux: lux,
      );
      await tester.pumpWidget(
        MaterialApp(home: ClockScreensaver(container: container)),
      );
      return container;
    }

    testWidgets('a dark room turns the digits to the night color', (
      tester,
    ) async {
      await pumpClock(tester, lux: 2);
      expect(digitColor(tester), nightRed);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a dark room also takes the backdrop, black over whatever '
        'the lit face uses', (tester) async {
      await pumpClock(
        tester,
        // The inverted e-ink pair: white wall, dark digits.
        prefs: {'ks.screensaver.clock_bg_color': '255,255,255'},
        lux: 2,
      );
      final box = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(ClockScreensaver),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(box.color, const Color(0xFF000000));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('light turns them back, live off the sensor event', (
      tester,
    ) async {
      final container = await pumpClock(tester, lux: 2);
      expect(digitColor(tester), nightRed);
      // The bus delivers asynchronously: one pump for the microtask, one
      // for the frame the setState asks for.
      Future<void> settle() async {
        await tester.pump();
        await tester.pump();
      }

      container.device.lightLux = 50;
      container.bus.publish(const LightLevelChanged(lux: 50));
      await settle();
      expect(digitColor(tester), const Color(0xFFFAFAFA));
      // ...and dark brings the color right back.
      container.device.lightLux = 1;
      container.bus.publish(const LightLevelChanged(lux: 1));
      await settle();
      expect(digitColor(tester), nightRed);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a dark room means nothing without the sensor', (tester) async {
      await pumpClock(tester, sensor: false, lux: 2);
      expect(digitColor(tester), const Color(0xFFFAFAFA));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with the switch off the digits keep their color', (
      tester,
    ) async {
      await pumpClock(
        tester,
        prefs: {'ks.screensaver.clock_night': false},
        lux: 2,
      );
      expect(digitColor(tester), const Color(0xFFFAFAFA));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
