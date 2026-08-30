import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/ui/kit.dart';
import 'package:kiosk_satellite/ui/setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Kiosk Satellite Service on the setup wizard's Connect page: the
/// service is what every install rides on, so it is introduced where the
/// kiosk is born, right under the Home Assistant URL and token.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppContainer container;

  /// What the OS answers about the service's grants; the gate on the
  /// Welcome page's Next reads these.
  var batteryUnrestricted = true;
  var overlay = true;
  var overlayRequestable = true;

  Future<void> boot() async {
    SharedPreferences.setMockInitialValues({});
    container = AppContainer();
    await container.settings.init();
    // The native service, answering as a running one.
    const channel = MethodChannel('kiosk_satellite/background');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'serviceStatus':
              return <String, Object?>{
                'running': true,
                'foreground': true,
                'types': ['specialUse'],
                'uptimeMs': 5000,
              };
            case 'isBatteryUnrestricted':
              return batteryUnrestricted;
            case 'canBringToFront':
              return overlay;
            case 'canRequestBringToFront':
              return overlayRequestable;
            case 'canRequestBatteryUnrestricted':
              return true;
            case 'hasAllFilesAccess':
            case 'hasUsageAccess':
              return true;
          }
          return null;
        });
    // permission_handler's channel: everything granted, services on.
    const perms = MethodChannel('flutter.baseflow.com/permissions/methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(perms, (call) async {
          if (call.method == 'checkServiceStatus') return 1;
          if (call.method == 'checkPermissionStatus') return 1;
          return null;
        });
    const brightness = MethodChannel('kiosk_satellite/brightness');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(brightness, (call) async => true);
    // device_info_plus (the Android version check behind the Bluetooth
    // rows): an unmocked channel hangs a widget test rather than throwing,
    // so answer with the failure the read already treats as "not Android".
    const info = MethodChannel('dev.fluttercommunity.plus/device_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          info,
          (call) async => throw PlatformException(code: 'test'),
        );
    addTearDown(() {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, null);
      messenger.setMockMethodCallHandler(perms, null);
      messenger.setMockMethodCallHandler(brightness, null);
      messenger.setMockMethodCallHandler(info, null);
    });
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('the Welcome page carries the service under Restore', (
    tester,
  ) async {
    await boot();
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SetupScreen(container: container)),
    );
    await settle(tester);

    expect(find.text('Welcome'), findsWidgets);
    // The three groups, titled.
    expect(find.text('Remote administration'), findsWidgets);
    expect(find.text('Restore backup'), findsOneWidget);
    expect(find.text('Recommended Service Permissions'), findsOneWidget);
    // Below the restore card, the last thing on the page.
    final restore = tester.getTopLeft(
      find.text('Restore from configuration file'),
    );
    final service = tester.getTopLeft(find.text('Kiosk Satellite Service'));
    expect(service.dy, greaterThan(restore.dy));
    // The ask, then the three grants it needs on every install. No status
    // row and no wake-lock switch: the service runs regardless, and the
    // lock is on by default.
    expect(find.text('Unrestricted battery'), findsOneWidget);
    expect(find.text('Display over other apps'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Service'), findsNothing);
    expect(find.text(serviceCpuAwake.title), findsNothing);

    // Remote administration is on by default and wants a password; off
    // it goes for the hop to the next page.
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    await tester.tap(find.byType(SwitchListTile));
    await settle(tester);
    // Not on the Connect page.
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Connect to Home Assistant'), findsOneWidget);
    expect(find.text('Kiosk Satellite Service'), findsNothing);
  });

  testWidgets('the Welcome page names the device first, from the model', (
    tester,
  ) async {
    await boot();
    container.device.model = 'Amazon KFTUWI';
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SetupScreen(container: container)),
    );
    await settle(tester);

    // Above Remote administration (the rail names that group too, so the
    // heading is the anchor), seeded with the model. No heading of its
    // own: the field's label is enough.
    final field = find.widgetWithText(TextField, 'Amazon KFTUWI');
    expect(field, findsOneWidget);
    final device = tester.getTopLeft(field);
    final remote = tester.getTopLeft(
      find.widgetWithText(SectionHeading, 'Remote administration'),
    );
    expect(device.dy, lessThan(remote.dy));

    // What is typed is what the ESPHome node name and the MQTT device are
    // built from, so Next stores it, remote administration on or off.
    await tester.enterText(field, ' Kitchen Tablet ');
    await tester.tap(find.byType(SwitchListTile));
    await settle(tester);
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Connect to Home Assistant'), findsOneWidget);
    expect(container.settings.get(deviceName), 'Kitchen Tablet');

    // Back again: the stored name stands, not the model.
    await tester.tap(find.text('Back'));
    await settle(tester);
    expect(find.widgetWithText(TextField, 'Kitchen Tablet'), findsOneWidget);
  });

  testWidgets('a missing grant never blocks the first page', (tester) async {
    batteryUnrestricted = false;
    addTearDown(() => batteryUnrestricted = true);
    await boot();
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SetupScreen(container: container)),
    );
    await settle(tester);
    await tester.tap(find.byType(SwitchListTile));
    await settle(tester);
    // The row says so; the wizard goes on regardless. The service needs
    // none of these to run, they only help it survive the screen off.
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Connect to Home Assistant'), findsOneWidget);
  });

  testWidgets('a grant the device has no screen for never blocks', (
    tester,
  ) async {
    overlay = false;
    overlayRequestable = false;
    addTearDown(() {
      overlay = true;
      overlayRequestable = true;
    });
    await boot();
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SetupScreen(container: container)),
    );
    await settle(tester);
    // The row says how to grant it over adb, and offers no button.
    expect(find.textContaining('SYSTEM_ALERT_WINDOW allow'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await settle(tester);
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Connect to Home Assistant'), findsOneWidget);
  });
}
