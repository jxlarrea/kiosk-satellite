import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/app_locales.dart';
import 'package:kiosk_satellite/ui/alarms_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The alarm details page on every screen shape: Repeat reads on one line
/// and its seven day discs all fit. A tablet in portrait used to keep the
/// two columns, which squeezed Repeat to a letter per line and pushed the
/// last disc off the edge.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  for (final (name, size) in [
    ('a Tab S8 in portrait', const Size(800, 1280)),
    ('a tablet in portrait', const Size(753, 1205)),
    ('a tablet in landscape', const Size(1280, 800)),
    ('an Echo Show 5', const Size(960, 480)),
    ('a phone', const Size(390, 844)),
  ]) {
    testWidgets('the details fit on $name', (tester) async {
      SharedPreferences.setMockInitialValues({
        'ks.alarms.list': jsonEncode([
          {
            'id': 'a',
            'time': '23:50',
            'days': [0, 1, 2, 3, 4, 5, 6],
            'label': 'Gym',
            'on': true,
          },
        ]),
      });
      final container = AppContainer();
      await tester.runAsync(() async {
        await container.settings.init();
        await container.alarms.init();
      });
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: appSupportedLocales,
          home: Scaffold(
            body: Stack(children: [AlarmsOverlay(container: container)]),
          ),
        ),
      );
      container.alarms.visible.value = true;
      await settle(tester);
      await tester.tap(find.textContaining('Gym').first);
      await settle(tester);

      // The test font draws every letter a full em wide, so the big time
      // and long values overflow here where they fit on a device. Only
      // Repeat's line is checked, by its geometry.
      tester.takeException();
      final repeat = tester.getRect(find.text('Repeat'));
      // One line of 18 point text.
      expect(repeat.height, lessThan(30), reason: '$repeat');
      expect(repeat.width, greaterThan(40), reason: '$repeat');
      final discs = find.descendant(
        of: find.byType(DayDiscs),
        matching: find.byType(InkResponse),
      );
      expect(discs, findsNWidgets(7));
      for (final disc in discs.evaluate()) {
        final r = tester.getRect(find.byWidget(disc.widget));
        expect(r.right, lessThanOrEqualTo(size.width), reason: '$r');
      }
      container.alarms.visible.value = false;
      await settle(tester);
      tester.takeException();
      await tester.runAsync(container.alarms.dispose);
    });
  }
}
