import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/ui/kiosk_drawer.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The device's Timers page with Enable timers (issue #1508): off, the page
/// is the switch alone, the timers list and the Voice timers group
/// included. The remote's twin is in timers.js.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppContainer> open(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.local:8123',
      'ks.ha.token': 'token',
      'ks.voice.runtime': 'native',
      'ks.voice.enabled': true,
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
    await tester.tap(find.text('Timers').first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    return container;
  }

  testWidgets('the switch heads the page and takes the rest with it', (
    tester,
  ) async {
    final container = await open(tester);
    expect(find.text('Enable timers'), findsOneWidget);
    expect(find.text('Share timers'), findsOneWidget);
    expect(find.text('Timer sound'), findsOneWidget);
    expect(find.text('Manage timers using Voice Satellite'), findsOneWidget);
    final switchTop = tester.getTopLeft(find.text('Enable timers')).dy;
    expect(
      switchTop,
      lessThan(
        tester.getTopLeft(find.text('Show Timers view when a timer starts')).dy,
      ),
    );

    await tester.tap(find.text('Enable timers'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(container.settings.get(timersEnabled), isFalse);
    expect(find.text('Enable timers'), findsOneWidget);
    expect(find.text('Share timers'), findsNothing);
    expect(find.text('Timer sound'), findsNothing);
    expect(find.text('Show Timers view when a timer starts'), findsNothing);
    expect(find.text('Manage timers using Voice Satellite'), findsNothing);

    await tester.tap(find.text('Enable timers'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.text('Share timers'), findsOneWidget);
    expect(find.text('Manage timers using Voice Satellite'), findsOneWidget);
  });

  testWidgets('the drawer leaves the Timers row out, locked or not', (
    tester,
  ) async {
    final container = await open(tester);
    for (final restricted in [false, true]) {
      expect(
        KioskDrawer.visibleItems(container, restricted: restricted),
        contains('timers'),
      );
    }
    await container.settings.set(timersEnabled, false);
    for (final restricted in [false, true]) {
      expect(
        KioskDrawer.visibleItems(container, restricted: restricted),
        isNot(contains('timers')),
      );
    }
  });
}
