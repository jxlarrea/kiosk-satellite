import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/js_api/js_api_manager.dart';
import 'package:kiosk_satellite/ui/kiosk_screen.dart';
import 'package:kiosk_satellite/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const backgroundChannel = MethodChannel('kiosk_satellite/background');
  const lockChannel = MethodChannel('kiosk_satellite/kiosk_lock');

  setUpAll(() async {
    // Use the app's font metrics for the fixed-width drawer.
    final font = FontLoader('Rubik')
      ..addFont(rootBundle.load('assets/fonts/Rubik.ttf'));
    await font.load();
  });

  testWidgets('startup and route changes synchronize navigation capture', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = AppContainer();
    await container.settings.init();
    container.device.appVersion = 'test';
    container.jsApi = JsApiManager(
      container.bus,
      container.commands,
      container.log,
      container.device.appVersion,
    );
    final captures = <bool>[];
    // Hold the native Activity handshake so the real screen can mount
    // without creating an Android WebView in the widget test.
    final activityAttached = Completer<bool>();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      backgroundChannel,
      (call) async =>
          call.method == 'isActivityAttached' ? activityAttached.future : null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(lockChannel, (
      call,
    ) async {
      if (call.method == 'navCapture') captures.add(call.arguments as bool);
      return null;
    });
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      activityAttached.complete(true);
      await tester.pump();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        backgroundChannel,
        null,
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        lockChannel,
        null,
      );
      await container.settings.dispose();
      await container.bus.dispose();
      await container.log.dispose();
    });

    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        navigatorKey: navigator,
        navigatorObservers: [kioskRouteObserver],
        home: KioskScreen(container: container),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(captures, [false]);

    unawaited(
      showDialog<void>(
        context: navigator.currentContext!,
        builder: (_) => const AlertDialog(content: Text('Covering dialog')),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(captures, [false, true]);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(captures, [false, true, false]);
  });
}
