import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/kit.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('schedule editor saves and reopens each Now Playing override', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule':
          '[{"at":"19:00","mode":"clock","brightness":0.2,"motion":false}]',
    });
    final c = AppContainer();
    await c.settings.init();
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: SubpageSettingsScreen(
          container: c,
          category: 'Screensaver',
          subpage: 'Scheduled Screensavers',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.descendant(
      of: find.widgetWithText(
        LabeledField,
        'Show Now Playing next to the screensaver',
      ),
      matching: find.byType(DropdownButtonFormField<String>),
    );
    var previous = 'default';
    for (final choice in ['Off', 'On', 'Default']) {
      await tester.tap(find.widgetWithText(ListTile, '19:00'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      expect(
        tester.widget<DropdownButtonFormField<String>>(field).initialValue,
        previous,
      );
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text(choice).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final entry =
          (jsonDecode(c.settings.get(defs.screensaverSchedule)) as List).single
              as Map;
      expect(entry['now_playing'], choice == 'Default' ? null : choice == 'On');
      expect(entry['brightness'], 0.2);
      expect(entry['motion'], false);
      if (choice != 'Default') {
        expect(
          find.textContaining('Now Playing ${choice.toLowerCase()}'),
          findsOneWidget,
        );
      } else {
        expect(entry.containsKey('now_playing'), isFalse);
      }
      previous = choice.toLowerCase();
    }
    await tester.pumpWidget(const SizedBox());
  });
}
