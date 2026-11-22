import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/ground_control_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings > Ground Control: while connected, the rows under the Ground
/// Control app row give its version, its architecture and whether it runs
/// on the CPU or with CUDA.
void main() {
  late AppContainer c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    c = AppContainer();
    await c.settings.init();
    await c.settings.set(defs.groundControlEnabled, true);
    c.groundControl
      ..status = 'connected'
      ..baseUrl = 'http://192.168.1.10:10900'
      ..version = '2026.11.10'
      ..install = {
        'install': 'docker',
        'arch': 'amd64',
        'cuda': '12.9',
        'onGpu': true,
      };
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GroundControlStatusRow(container: c)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a connected Ground Control on the GPU', (tester) async {
    await pump(tester);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('2026.11.10'), findsOneWidget);
    expect(find.text('Architecture'), findsOneWidget);
    expect(find.text('amd64'), findsOneWidget);
    expect(find.text('Runs on'), findsOneWidget);
    expect(find.text('CUDA'), findsOneWidget);
    expect(find.text('CPU'), findsNothing);
  });

  testWidgets('the CUDA image without a usable GPU runs on the CPU', (
    tester,
  ) async {
    c.groundControl.install = {
      'install': 'docker',
      'arch': 'aarch64',
      'cuda': '12.9',
      'onGpu': false,
    };
    await pump(tester);
    expect(find.text('aarch64'), findsOneWidget);
    expect(find.text('CPU'), findsOneWidget);
    expect(find.text('CUDA'), findsNothing);
  });

  testWidgets('an older Ground Control only gives its version', (tester) async {
    c.groundControl.install = const {};
    await pump(tester);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('2026.11.10'), findsOneWidget);
    expect(find.text('Architecture'), findsNothing);
    expect(find.text('Runs on'), findsNothing);
  });

  testWidgets('nothing shows while Ground Control is away', (tester) async {
    c.groundControl.status = 'unreachable';
    await pump(tester);
    expect(find.text('Not reachable'), findsOneWidget);
    expect(find.text('Version'), findsNothing);
    expect(find.text('Architecture'), findsNothing);
    expect(find.text('Runs on'), findsNothing);
  });
}
