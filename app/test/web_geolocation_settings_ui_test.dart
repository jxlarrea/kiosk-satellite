import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web Browsing closes with the HTML5 Geolocation group (issue #1383): its
/// switch after the URL Filter, and the Location grant under it while the
/// switch is on, as on the remote (settings.js, updateWebGeolocationRows).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppContainer> open(WidgetTester tester, {required bool on}) async {
    SharedPreferences.setMockInitialValues({
      // Past the one-time drop of a value stored before the row existed.
      'ks.internal.web.geolocation_off.migrated': '1',
      'ks.web.geolocation': on,
    });
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('kiosk_satellite/location'),
      (call) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('kiosk_satellite/location'),
        null,
      ),
    );
    final container = AppContainer();
    await container.settings.init();
    tester.view.physicalSize = const Size(500, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(container: container)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Web Browsing').first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    return container;
  }

  testWidgets('the group follows the URL Filter and starts without a grant', (
    tester,
  ) async {
    await open(tester, on: false);
    final heading = find.text('HTML5 Geolocation');
    expect(heading, findsOneWidget);
    expect(find.text(webGeolocation.title), findsOneWidget);
    expect(
      tester.getTopLeft(heading).dy,
      greaterThan(tester.getTopLeft(find.text('URL Filter')).dy),
    );
    expect(find.text('Required system permissions'), findsNothing);
  });

  testWidgets('the Location grant shows while the switch is on', (
    tester,
  ) async {
    final c = await open(tester, on: true);
    final heading = find.text('Required system permissions');
    expect(heading, findsOneWidget);
    expect(
      tester.getTopLeft(heading).dy,
      greaterThan(tester.getTopLeft(find.text(webGeolocation.title)).dy),
    );
    expect(
      find.text('Without this pages cannot read the device location.'),
      findsOneWidget,
    );
    // Turned off from the remote, the grant leaves with it.
    await c.settings.set(webGeolocation, false);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(heading, findsNothing);
  });
}
