import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/navigation/compass_layout.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/compass/compass_controller.dart';
import 'package:kiosk_satellite/ui/compass/compass_settings.dart';
import 'package:kiosk_satellite/ui/kiosk_drawer.dart';
import 'package:kiosk_satellite/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Compass navigation's settings rows and its Menu view.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final font = FontLoader('Rubik')
      ..addFont(rootBundle.load('assets/fonts/Rubik.ttf'));
    await font.load();
  });

  Future<AppContainer> boot(WidgetTester tester, Size size) async {
    SharedPreferences.setMockInitialValues({});
    final container = AppContainer();
    await container.settings.init();
    container.device.appVersion = 'test';
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await container.settings.dispose();
      await container.bus.dispose();
      await container.log.dispose();
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return container;
  }

  Widget app(Widget child) => MaterialApp(
    theme: buildTheme(Brightness.dark),
    home: Scaffold(body: child),
  );

  group('the Quick Controls view', () {
    for (final size in const [
      Size(1280, 800),
      Size(787, 393),
      Size(390, 844),
    ]) {
      testWidgets('lays its tiles out at ${size.width.toInt()} wide', (
        tester,
      ) async {
        final container = await boot(tester, size);
        await tester.pumpWidget(
          app(
            KioskDrawer(
              container: container,
              tiles: true,
              onClose: () {},
              onSettings: () {},
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Exit Application'), findsOneWidget);
        // The Dashboard entry is the center's job here.
        expect(find.text('Dashboard'), findsNothing);
      });
    }

    testWidgets('a locked kiosk shows Settings behind the PIN', (tester) async {
      final container = await boot(tester, const Size(1280, 800));
      var unlocks = 0;
      await tester.pumpWidget(
        app(
          KioskDrawer(
            container: container,
            tiles: true,
            restricted: true,
            onClose: () {},
            onSettings: () {},
            onUnlock: () => unlocks++,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Exit Application'), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      await tester.tap(find.text('Settings'));
      expect(unlocks, 1);
    });
  });

  group('the layout editor', () {
    testWidgets('draws the map on a roomy pane', (tester) async {
      final container = await boot(tester, const Size(1200, 900));
      await container.settings.setFromJson(
        defs.navCompassLayout.key,
        const CompassLayout(
          right: [CompassView('calendar'), CompassView('alarms')],
        ).encode(),
      );
      await tester.pumpWidget(
        app(
          SingleChildScrollView(
            child: CompassLayoutEditor(container: container, onChanged: () {}),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Quick Controls'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      // A full right side offers no Add; up, down and left each offer one.
      expect(find.text('Add'), findsNWidgets(3));

      // Picking a view brings up what can be done with it.
      await tester.tap(find.text('Alarms'));
      await tester.pump();
      expect(find.text('Right, second view'), findsOneWidget);
      expect(find.text('Move in'), findsOneWidget);
      expect(find.text('Move out'), findsNothing);
      await tester.tap(find.text('Move in'));
      await tester.pump();
      final moved = CompassLayout.decode(
        container.settings.get(defs.navCompassLayout),
      );
      expect(moved.right.map((v) => v.kind), ['alarms', 'calendar']);
    });

    testWidgets('lists the sides on a narrow pane', (tester) async {
      final container = await boot(tester, const Size(380, 1600));
      await tester.pumpWidget(
        app(
          SingleChildScrollView(
            child: CompassLayoutEditor(container: container, onChanged: () {}),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Add view'), findsNWidgets(4));
    });

    testWidgets('a kind already placed cannot be added again', (tester) async {
      final container = await boot(tester, const Size(1200, 1200));
      await container.settings.setFromJson(
        defs.navCompassLayout.key,
        const CompassLayout(right: [CompassView('calendar')]).encode(),
      );
      await tester.pumpWidget(
        app(
          SingleChildScrollView(
            child: CompassLayoutEditor(container: container, onChanged: () {}),
          ),
        ),
      );
      await tester.pump();
      // The Add above the center.
      await tester.tap(find.text('Add').first);
      await tester.pumpAndSettle();
      // Home Assistant in the center, the calendar and the default Menu.
      expect(find.text('Already placed'), findsNWidgets(3));
      final calendar = tester.widget<RadioListTile<String>>(
        find.widgetWithText(RadioListTile<String>, 'Calendar'),
      );
      expect(calendar.enabled, isFalse);
      final dashboard = tester.widget<RadioListTile<String>>(
        find.widgetWithText(RadioListTile<String>, 'Home Assistant dashboard'),
      );
      // The home dashboard holds the center.
      expect(dashboard.enabled, isFalse);
      final alarms = tester.widget<RadioListTile<String>>(
        find.widgetWithText(RadioListTile<String>, 'Alarms'),
      );
      expect(alarms.enabled, isTrue);
    });
  });

  group('a locked kiosk', () {
    testWidgets('skips the views its Allowed Actions leave out', (
      tester,
    ) async {
      final container = await boot(tester, const Size(1280, 800));
      await container.settings.setFromJson(defs.navStyle.key, 'compass');
      await container.settings.setFromJson(
        defs.navCompassLayout.key,
        const CompassLayout(
          right: [CompassView('calendar'), CompassView('alarms')],
        ).encode(),
      );
      final compass = CompassController(container)..start();
      final layout = compass.layout;
      CompassSlot? right(CompassSlot from) =>
          layout.step(from, CompassMove.right, available: compass.available);

      // Unlocked: everything is reachable.
      expect(right(CompassSlot.center), const CompassSlot(CompassArm.right, 0));

      await container.settings.setFromJson(defs.kioskEnabled.key, true);
      await container.settings.setFromJson(defs.kioskAllowCalendar.key, false);
      await container.settings.setFromJson(defs.kioskAllowAlarms.key, true);
      // Calendar is not allowed: the swipe goes on to Alarms.
      expect(right(CompassSlot.center), const CompassSlot(CompassArm.right, 1));
      await container.settings.setFromJson(defs.kioskAllowAlarms.key, false);
      expect(right(CompassSlot.center), isNull);
      // The dashboard is the kiosk itself and always shows.
      expect(compass.available(CompassView.home), isTrue);

      // The Menu follows the quick menu's switch, and the exit gesture's
      // unlock opens it whatever that says.
      await container.settings.setFromJson(defs.kioskAllowDrawer.key, false);
      expect(compass.available(CompassView.menu), isFalse);
      compass.menuUnlocked.value = true;
      expect(compass.available(CompassView.menu), isTrue);
      // Disposed in the test: its start timer must not outlive it.
      compass.dispose();
    });
  });

  testWidgets('the style cards switch the navigation style', (tester) async {
    final container = await boot(tester, const Size(1200, 800));
    await tester.pumpWidget(
      app(CompassStyleRow(container: container, onChanged: () {})),
    );
    await tester.pump();
    expect(container.settings.get(defs.navStyle), 'classic');
    await tester.tap(find.text('Compass'));
    await tester.pump();
    expect(container.settings.get(defs.navStyle), 'compass');
  });

  group('camera views', () {
    Future<AppContainer> withCameras(List<Map<String, Object?>> views) async {
      SharedPreferences.setMockInitialValues({
        'ks.camera.config': jsonEncode({
          'version': 1,
          'servers': [
            {'id': 's1', 'name': 'Go2RTC', 'baseUrl': 'http://go2rtc.local'},
          ],
          'cameras': [
            {
              'id': 'cam1',
              'name': 'Door',
              'kind': 'go2rtc',
              'serverId': 's1',
              'streamName': 'door',
            },
          ],
          'views': views,
        }),
      });
      final container = AppContainer();
      await container.settings.init();
      await container.camera.init();
      addTearDown(() async {
        await container.camera.dispose();
        await container.settings.dispose();
        await container.bus.dispose();
        await container.log.dispose();
      });
      return container;
    }

    test('only views with cameras can be placed', () async {
      final container = await withCameras([
        {'id': 'default', 'name': 'Default', 'cameraIds': <String>[]},
        {
          'id': 'door',
          'name': 'Door',
          'cameraIds': ['cam1'],
        },
      ]);
      expect([for (final v in compassCameraViews(container)) v.id], ['door']);
      expect(compassKindConfigurable(container, 'camera'), isTrue);
    });

    test('an empty camera view leaves the kind unavailable', () async {
      final container = await withCameras([
        {'id': 'default', 'name': 'Default', 'cameraIds': <String>[]},
      ]);
      expect(compassCameraViews(container), isEmpty);
      expect(compassKindConfigurable(container, 'camera'), isFalse);
    });
  });
}
