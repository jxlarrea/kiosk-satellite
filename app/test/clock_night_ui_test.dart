import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/managers/glance/glance_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/clock_faces.dart';
import 'package:kiosk_satellite/ui/glance_row.dart';
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Clock screensaver's Night mode (issue #391): the settings page
/// gates the group on the ambient light sensor the same way adaptive
/// brightness does, and the overlay swaps the digit color, the flip cards
/// and the corner widgets with the room's light, live off the sensor
/// events.
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
      expect(find.text('Night card color'), findsNothing);
    });

    testWidgets('the card color needs the switch AND the Flip style', (
      tester,
    ) async {
      await open(tester, {
        'ks.screensaver.clock_night': true,
        'ks.screensaver.clock_style': 'flip',
      });
      await tab(tester, 'Screensaver');
      await tab(tester, 'Clock screensaver');
      expect(find.text('Night card color'), findsOneWidget);
    });

    testWidgets('no cards on the other faces, so no card color', (
      tester,
    ) async {
      await open(tester, {
        'ks.screensaver.clock_night': true,
        'ks.screensaver.clock_style': 'roller',
      });
      await tab(tester, 'Screensaver');
      await tab(tester, 'Clock screensaver');
      expect(find.text('Night color'), findsOneWidget);
      expect(find.text('Night card color'), findsNothing);
    });
  });

  group('definition gates', () {
    // The card color is the first row with two gates; the schema carries
    // both to the remote admin, and visible() wants both to hold.
    test('describe() carries the second gate', () async {
      final container = await makeContainer({});
      final row = container.settings.describe().singleWhere(
        (r) => r['key'] == defs.screensaverClockNightCardColor.key,
      );
      expect(row['dependsOn'], defs.screensaverClockNight.key);
      expect(row['alsoDependsOn'], defs.screensaverClockStyle.key);
      expect(row['alsoDependsOnValue'], 'flip');
    });

    test('visible() wants both gates', () async {
      final def = defs.screensaverClockNightCardColor;
      var container = await makeContainer({
        'ks.screensaver.clock_night': true,
        'ks.screensaver.clock_style': 'flip',
      });
      expect(container.settings.visible(def), isTrue);
      container = await makeContainer({
        'ks.screensaver.clock_night': true,
        'ks.screensaver.clock_style': 'digital',
      });
      expect(container.settings.visible(def), isFalse);
      container = await makeContainer({
        'ks.screensaver.clock_night': false,
        'ks.screensaver.clock_style': 'flip',
      });
      expect(container.settings.visible(def), isFalse);
      // The first gate's own chain still counts: Night mode gates on the
      // Clock mode, so another mode hides the row with the whole group.
      container = await makeContainer({
        'ks.screensaver.mode': 'black',
        'ks.screensaver.clock_night': true,
        'ks.screensaver.clock_style': 'flip',
      });
      expect(container.settings.visible(def), isFalse);
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
      // The overlay, not the face alone: the Night decision lives there so
      // the corner widgets riding over the face can share it.
      container.screensaver.activeView.value = 'clock';
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(children: [ScreensaverOverlay(container: container)]),
        ),
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

    testWidgets('the flip cards take the night card color in the dark', (
      tester,
    ) async {
      await pumpClock(
        tester,
        prefs: {
          'ks.screensaver.clock_style': 'flip',
          // A daylight card that would glow on the night's black wall.
          'ks.screensaver.flip_bg_color': '240,240,240',
          'ks.screensaver.clock_night_card_color': '40,10,10',
        },
        lux: 2,
      );
      expect(
        tester.widget<FlipClockFace>(find.byType(FlipClockFace)).cardColor,
        const Color(0xFF280A0A),
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('in the light the flip cards keep their own color', (
      tester,
    ) async {
      await pumpClock(
        tester,
        prefs: {
          'ks.screensaver.clock_style': 'flip',
          'ks.screensaver.flip_bg_color': '240,240,240',
          'ks.screensaver.clock_night_card_color': '40,10,10',
        },
        lux: 200,
      );
      expect(
        tester.widget<FlipClockFace>(find.byType(FlipClockFace)).cardColor,
        const Color(0xFFF0F0F0),
      );
      await tester.pumpWidget(const SizedBox());
    });
  });

  // The At a Glance row under the clock (issue #425): the night color used
  // to reach the floating text alone, through the row's tint, so the chip
  // style stayed a white pill beside the dimmed digits.
  group('glance chips', () {
    const day = Color(0xB31C1C1E);

    Future<AppContainer> pumpChips(
      WidgetTester tester, {
      required double lux,
      bool textOnly = false,
    }) async {
      final container = await makeContainer({
        'ks.screensaver.clock_night': true,
        'ks.screensaver.clock_show_date': false,
        'ks.screensaver.glance_text_only': textOnly,
      }, lux: lux);
      container.glance.entities.value = const [
        GlanceEntity(entityId: 'light.desk', name: 'Desk', state: 'on'),
      ];
      container.screensaver.activeView.value = 'clock';
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(children: [ScreensaverOverlay(container: container)]),
        ),
      );
      return container;
    }

    ShapeDecoration pill(WidgetTester tester) => tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(GlanceRow),
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<ShapeDecoration>()
        .single;

    Color? valueColor(WidgetTester tester) =>
        tester.widget<Text>(find.text('On')).style?.color;

    testWidgets('a dark room draws the chips in the night color', (
      tester,
    ) async {
      await pumpChips(tester, lux: 2);
      final deco = pill(tester);
      // The pill, its edge and the text all in the one color: a wash of
      // it behind, the color itself in front, no state accent lighting
      // the circle of an entity that is on.
      expect(deco.color, nightRed.withValues(alpha: 0.16));
      expect(
        (deco.shape as StadiumBorder).side.color,
        nightRed.withValues(alpha: 0.4),
      );
      expect(valueColor(tester), nightRed);
      final circles = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(GlanceRow),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.shape == BoxShape.circle);
      expect(circles.single.color, nightRed.withValues(alpha: 0.28));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('in the light the chips keep their own palette', (
      tester,
    ) async {
      await pumpChips(tester, lux: 50);
      expect(pill(tester).color, day);
      expect(valueColor(tester), Colors.white);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the floating text takes it as before', (tester) async {
      await pumpChips(tester, lux: 2, textOnly: true);
      expect(valueColor(tester), nightRed);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('corner widgets', () {
    // The battery widget renders off the device_details channel alone, so
    // it is the one corner widget a test can put on screen.
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('kiosk_satellite/device_details'),
            (call) async => switch (call.method) {
              'battery' => {'present': true, 'level': 80},
              'plugged' => false,
              _ => null,
            },
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('kiosk_satellite/device_details'),
            null,
          );
    });

    Color? batteryColor(WidgetTester tester) => tester
        .widget<Icon>(
          find.descendant(
            of: find.byType(BatteryWidgetOverlay),
            matching: find.byType(Icon),
          ),
        )
        .color;

    Future<AppContainer> pumpWithBattery(
      WidgetTester tester, {
      required double lux,
      String view = 'clock',
    }) async {
      final container = await makeContainer({
        'ks.screensaver.clock_night': true,
        'ks.screensaver.clock_show_date': false,
        'ks.screensaver.widgets':
            '[{"position":"top_right","type":"battery",'
            '"config":{"color":"250,250,250","percent":true}}]',
      }, lux: lux);
      container.screensaver.activeView.value = view;
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(children: [ScreensaverOverlay(container: container)]),
        ),
      );
      // The battery read answers asynchronously.
      await tester.pump();
      await tester.pump();
      return container;
    }

    testWidgets('a widget over the clock takes the night color', (
      tester,
    ) async {
      await pumpWithBattery(tester, lux: 2);
      expect(batteryColor(tester), nightRed);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('and keeps its own in the light', (tester) async {
      await pumpWithBattery(tester, lux: 200);
      expect(batteryColor(tester), const Color(0xFFFAFAFA));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Night mode is the clock\'s: over Black the widget keeps '
        'its own color', (tester) async {
      await pumpWithBattery(tester, lux: 2, view: 'black');
      expect(batteryColor(tester), const Color(0xFFFAFAFA));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
