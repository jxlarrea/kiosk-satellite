import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/camera/models.dart';
import 'package:kiosk_satellite/ui/camera_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Delete unused cameras in Settings > Camera Streams > Cameras (issue
/// #1467): the row shows only while a camera is in no view, counts them and
/// deletes them after a confirmation, leaving the cameras views hold.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppContainer container;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> open(WidgetTester tester, List<String> viewCameras) async {
    final config = CameraConfiguration(
      cameras: const [
        CameraSource(id: 'c1', name: 'Door', kind: 'ha', entityId: 'camera.d'),
        CameraSource(id: 'c2', name: 'Yard', kind: 'ha', entityId: 'camera.y'),
        CameraSource(id: 'c3', name: 'Old', kind: 'ha', entityId: 'camera.o'),
      ],
      views: [
        CameraViewConfig(
          id: CameraViewConfig.defaultId,
          name: 'Default',
          cameraIds: viewCameras,
        ),
      ],
    ).encode();
    SharedPreferences.setMockInitialValues({'ks.camera.config': config});
    container = AppContainer();
    await container.settings.init();
    await container.camera.init();
    tester.view.physicalSize = const Size(600, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CameraSettingsPanel(container: container),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('the row counts the cameras no view holds and deletes them', (
    tester,
  ) async {
    await open(tester, const ['c1']);
    expect(find.text('Delete unused cameras'), findsOneWidget);
    expect(find.text('2 cameras are not in any view.'), findsOneWidget);

    // Cancel keeps every camera.
    await tester.tap(find.text('Delete unused cameras'));
    await settle(tester);
    expect(find.text('Delete unused cameras?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(container.camera.config.cameras, hasLength(3));

    await tester.tap(find.text('Delete unused cameras'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);
    expect(container.camera.config.cameras.map((camera) => camera.id), ['c1']);
    expect(find.text('Delete unused cameras'), findsNothing);
  });

  testWidgets('one unused camera reads in the singular', (tester) async {
    await open(tester, const ['c1', 'c2']);
    expect(find.text('1 camera is not in any view.'), findsOneWidget);
  });

  testWidgets('the row stays away while every camera is in a view', (
    tester,
  ) async {
    await open(tester, const ['c1', 'c2', 'c3']);
    expect(find.text('Delete unused cameras'), findsNothing);
  });
}
