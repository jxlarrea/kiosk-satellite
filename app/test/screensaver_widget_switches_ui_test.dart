import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_widgets.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Widgets page's switches: Enable screensaver widgets heads the card,
/// and each row in the list has its own switch beside the delete button.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<AppContainer> openWidgets(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
      'ks.screensaver.widgets':
          '[{"position":"top_left","type":"battery","config":{}}]',
    });
    final container = AppContainer();
    await container.settings.init();
    tester.view.physicalSize = const Size(500, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(container: container)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Screensaver').first);
    await settle(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Widgets'));
    await settle(tester);
    return container;
  }

  Finder rowSwitch() => find.descendant(
    of: find.widgetWithText(ListTile, 'Battery'),
    matching: find.byType(Switch),
  );

  testWidgets('the master switch comes first, on by default', (tester) async {
    final container = await openWidgets(tester);
    final master = find.text('Enable screensaver widgets');
    expect(master, findsOneWidget);
    expect(
      tester.getTopLeft(master).dy,
      lessThan(tester.getTopLeft(find.text('Battery')).dy),
    );
    expect(container.settings.get(screensaverWidgetsEnabled), isTrue);
  });

  testWidgets('a row switch turns its widget off and back on', (tester) async {
    final container = await openWidgets(tester);
    expect(activeScreensaverWidgets(container.settings), hasLength(1));

    await tester.tap(rowSwitch());
    await settle(tester);
    expect(activeScreensaverWidgets(container.settings), isEmpty);
    expect(tester.widget<Switch>(rowSwitch()).value, isFalse);
    // Still in the list, and its dialog did not open.
    expect(find.widgetWithText(ListTile, 'Battery'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(rowSwitch());
    await settle(tester);
    expect(activeScreensaverWidgets(container.settings), hasLength(1));
  });

  testWidgets('editing a widget that is off leaves it off', (tester) async {
    final container = await openWidgets(tester);
    await tester.tap(rowSwitch());
    await settle(tester);

    await tester.tap(find.text('Battery'));
    await settle(tester);
    await tester.tap(find.text('Save'));
    await settle(tester);

    final widgets = decodeScreensaverWidgets(
      container.settings.get(screensaverWidgets),
    );
    expect(widgets.single.enabled, isFalse);
  });
}
