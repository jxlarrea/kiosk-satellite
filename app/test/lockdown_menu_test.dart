import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/js_api/js_api_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/kiosk_drawer.dart';
import 'package:kiosk_satellite/ui/kiosk_screen.dart';
import 'package:kiosk_satellite/ui/lockdown_shield.dart';
import 'package:kiosk_satellite/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const backgroundChannel = MethodChannel('kiosk_satellite/background');
  const lockChannel = MethodChannel('kiosk_satellite/kiosk_lock');

  setUpAll(() async {
    final font = FontLoader('Rubik')
      ..addFont(rootBundle.load('assets/fonts/Rubik.ttf'));
    await font.load();
  });

  for (final restricted in [false, true]) {
    testWidgets(
      'Lockdown menu opt-in and activation (restricted=$restricted)',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'ks.kiosk.enabled': restricted,
          'ks.kiosk.pin': '1234',
          'ks.kiosk.allow_drawer': true,
          // Leave Lockdown as the only available quick action.
          for (final setting in defs.allSettings)
            if (setting.key.startsWith('kiosk.allow_') &&
                setting.key != defs.kioskAllowDrawer.key &&
                setting.key != defs.kioskAllowLockdown.key)
              'ks.${setting.key}': false,
        });
        final container = AppContainer();
        await container.settings.init();
        container.device.appVersion = 'test';
        container.jsApi = JsApiManager(
          container.bus,
          container.commands,
          container.log,
          container.device.appVersion,
        );
        // Keep the real screen mounted without creating a native WebView.
        final activityAttached = Completer<bool>();
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          backgroundChannel,
          (call) async => call.method == 'isActivityAttached'
              ? activityAttached.future
              : null,
        );
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          lockChannel,
          (_) async => null,
        );
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          activityAttached.complete(true);
          await tester.pumpAndSettle();
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

        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(Brightness.light),
            navigatorObservers: [kioskRouteObserver],
            home: KioskScreen(container: container),
          ),
        );
        expect(find.text('Lockdown Mode'), findsNothing);
        expect(container.settings.get(defs.lockdownEnabled), isFalse);
        expect(defs.lockdownMenu.dependsOn, isNull);

        await container.settings.set(defs.lockdownMenu, true);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        expect(
          tester.widget<KioskDrawer>(find.byType(KioskDrawer)).restricted,
          restricted,
        );
        expect(find.text('Lockdown Mode').hitTestable(), findsOneWidget);

        await container.settings.set(defs.kioskAllowLockdown, false);
        await tester.pumpAndSettle();
        expect(
          find.text('Lockdown Mode'),
          restricted ? findsNothing : findsOneWidget,
        );
        await container.settings.set(defs.kioskAllowLockdown, true);
        await tester.pumpAndSettle();

        await container.settings.set(defs.lockdownMenu, false);
        await tester.pumpAndSettle();
        expect(find.text('Lockdown Mode'), findsNothing);
        await container.settings.set(defs.lockdownMenu, true);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Lockdown Mode'));
        await tester.tap(find.text('Lockdown Mode'));
        await tester.pumpAndSettle();
        expect(container.settings.get(defs.lockdownEnabled), isTrue);
        expect(find.byType(LockdownShield), findsOneWidget);
        expect(find.text('Lockdown Mode').hitTestable(), findsNothing);
        expect(container.settings.get(defs.kioskEnabled), restricted);
        expect(container.settings.get(defs.kioskPin), '1234');
        expect(container.settings.get(defs.lockdownExitGesture), 'taps7');
        expect(tester.takeException(), isNull);

        await container.settings.set(defs.lockdownEnabled, false);
        await tester.pumpAndSettle();
        expect(find.byType(LockdownShield), findsNothing);
      },
    );
  }
}
