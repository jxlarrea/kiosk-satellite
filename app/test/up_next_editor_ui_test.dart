import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The device editor's Show all-day events switch (issue #1312): a widget
/// saved before the switch existed reads as on through the type's defaults,
/// and turning it off saves all_day false.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('Show all-day events reads a missing key as on and saves off', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.local:8123',
      'ks.ha.token': 'token',
      'ks.screensaver.widgets': jsonEncode([
        {
          'position': 'top_right',
          'type': 'calendar',
          'config': {'count': 2, 'days': 1, 'dots': false},
        },
      ]),
    });
    final container = AppContainer();
    await container.settings.init();
    container.homeAssistant.connectionOk.value = true;
    // Tall enough that a page renders whole: off-screen rows do not exist.
    tester.view.physicalSize = const Size(500, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(container: container)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Screensaver').first);
    await settle(tester);
    await tester.tap(find.text('Widgets').first);
    await settle(tester);
    await tester.tap(find.text('Up next').first);
    await settle(tester);

    final row = find.widgetWithText(SwitchListTile, 'Show all-day events');
    expect(tester.widget<SwitchListTile>(row).value, isTrue);
    await tester.tap(row);
    await settle(tester);
    expect(tester.widget<SwitchListTile>(row).value, isFalse);

    await tester.tap(find.text('Save').last);
    await settle(tester);
    final saved =
        jsonDecode(container.settings.get(defs.screensaverWidgets)) as List;
    expect((saved.single as Map)['config']['all_day'], isFalse);
  });
}
