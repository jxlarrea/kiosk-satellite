import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The device settings mirror the remote admin's adaptive brightness rows
/// (issue #343): Default brightness stands down with the reason while the
/// switch is on, the screensaver's brightness sliders carry the
/// bright-room hint, the page shows the live reading, and a device without
/// the sensor gets a disabled switch with the reason.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const owns = 'Adaptive brightness is on.';
  const hint =
      'Level in a bright room. Adaptive brightness dims it from there.';
  const noSensor = 'No ambient light sensor on this device.';

  Future<AppContainer> open(
    WidgetTester tester,
    Map<String, Object> prefs, {
    bool sensor = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.local:8123',
      'ks.ha.token': 'token',
      'ks.screen.set_brightness_on_launch': true,
      'ks.screensaver.brightness_enabled': true,
      ...prefs,
    });
    final container = AppContainer();
    await container.settings.init();
    container.homeAssistant.connectionOk.value = true;
    container.device.hasLightSensor = sensor;
    container.device.lightLux = 12;
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

  testWidgets('Default brightness stands down with the reason while the '
      'switch is on', (tester) async {
    await open(tester, {'ks.screen.adaptive_brightness': true});
    await tab(tester, 'Screen & Audio');
    expect(find.text('Default brightness'), findsOneWidget);
    expect(find.text(owns), findsOneWidget);
  });

  testWidgets('Default brightness is an ordinary slider with the switch off', (
    tester,
  ) async {
    await open(tester, {'ks.screen.adaptive_brightness': false});
    await tab(tester, 'Screen & Audio');
    expect(find.text('Default brightness'), findsOneWidget);
    expect(find.text(owns), findsNothing);
  });

  testWidgets('the screensaver brightness slider carries the bright-room '
      'hint while the switch is on', (tester) async {
    await open(tester, {'ks.screen.adaptive_brightness': true});
    await tab(tester, 'Screensaver');
    expect(find.text('Brightness level'), findsOneWidget);
    expect(find.text(hint), findsOneWidget);
  });

  testWidgets('the Dim level carries it too, beside its own warning', (
    tester,
  ) async {
    await open(tester, {
      'ks.screen.adaptive_brightness': true,
      'ks.screensaver.mode': 'dim',
    });
    await tab(tester, 'Screensaver');
    expect(find.text('Dim level'), findsOneWidget);
    expect(find.text(hint), findsNWidgets(2));
  });

  testWidgets('no hints with the switch off', (tester) async {
    await open(tester, {'ks.screen.adaptive_brightness': false});
    await tab(tester, 'Screensaver');
    expect(find.text(hint), findsNothing);
  });

  testWidgets('a flip made elsewhere (the remote admin) refreshes the page', (
    tester,
  ) async {
    final container = await open(tester, {
      'ks.screen.adaptive_brightness': false,
    });
    await tab(tester, 'Screen & Audio');
    expect(find.text(owns), findsNothing);
    await container.settings.setFromJson(
      'screen.adaptive_brightness',
      true,
      source: 'remote admin',
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.text(owns), findsOneWidget);
  });

  testWidgets('the page shows the live reading under the switch', (
    tester,
  ) async {
    await open(tester, {'ks.screen.adaptive_brightness': true});
    await tab(tester, 'Screen & Audio');
    await tab(tester, 'Adaptive brightness');
    expect(find.text('Ambient light'), findsOneWidget);
    expect(find.text('12 lx (last known)'), findsOneWidget);
    expect(find.text('Minimum brightness'), findsOneWidget);
    expect(find.text('Dark room (lx)'), findsOneWidget);
  });

  testWidgets('without the sensor the switch is disabled with the reason, '
      'and Default brightness keeps working', (tester) async {
    await open(tester, {'ks.screen.adaptive_brightness': true}, sensor: false);
    await tab(tester, 'Screen & Audio');
    expect(find.text(owns), findsNothing);
    await tab(tester, 'Adaptive brightness');
    expect(find.text(noSensor), findsOneWidget);
  });
}
