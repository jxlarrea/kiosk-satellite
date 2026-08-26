import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/camera/models.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:kiosk_satellite/ui/settings_search.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Camera views row on the Camera Streams screensaver page: its dialog
/// lists the views with cameras, and Save writes the chosen ids in order.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppContainer container;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> open(WidgetTester tester) async {
    final config = const CameraConfiguration(
      cameras: [
        CameraSource(id: 'c1', name: 'Door', kind: 'ha', entityId: 'camera.d'),
        CameraSource(id: 'c2', name: 'Yard', kind: 'ha', entityId: 'camera.y'),
      ],
      views: [
        CameraViewConfig(id: 'default', name: 'Default', cameraIds: []),
        CameraViewConfig(
          id: 'multi',
          name: 'Multiple',
          cameraIds: ['c1', 'c2'],
        ),
        CameraViewConfig(id: 'door', name: 'Door only', cameraIds: ['c1']),
      ],
    ).encode();
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.local:8123',
      'ks.ha.token': 'token',
      'ks.screensaver.mode': 'camera',
      'ks.camera.config': config,
    });
    container = AppContainer();
    await container.settings.init();
    await container.camera.init();
    container.homeAssistant.connectionOk.value = true;
    tester.view.physicalSize = const Size(500, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(container: container)),
    );
    await settle(tester);
    await tester.tap(find.text('Screensaver').first);
    await settle(tester);
    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w is SearchLandingTarget &&
            w.id == 'sub:Camera Streams screensaver',
      ),
    );
    await settle(tester);
  }

  testWidgets('picking views in the dialog saves them in order', (
    tester,
  ) async {
    await open(tester);
    expect(find.text(screensaverCameraViews.title), findsOneWidget);
    await tester.tap(find.text(screensaverCameraViews.title));
    await settle(tester);

    // The empty Default view is not offered: nothing to show.
    expect(find.text('Default'), findsNothing);
    expect(find.text('Multiple'), findsOneWidget);
    expect(find.text('Door only'), findsOneWidget);

    await tester.tap(find.text('Multiple'));
    await settle(tester);
    await tester.tap(find.text('Door only'));
    await settle(tester);
    expect(find.text('Position 1 · 2 cameras'), findsOneWidget);
    expect(find.text('Position 2 · 1 camera'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(
      decodeCameraViewIds(container.settings.get(screensaverCameraViews)),
      ['multi', 'door'],
    );
    // The row now names what it shows.
    expect(find.text('Multiple, Door only'), findsOneWidget);
  });

  testWidgets('Cancel leaves the setting alone', (tester) async {
    await open(tester);
    await tester.tap(find.text(screensaverCameraViews.title));
    await settle(tester);
    await tester.tap(find.text('Multiple'));
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(container.settings.get(screensaverCameraViews), '[]');
  });
}
