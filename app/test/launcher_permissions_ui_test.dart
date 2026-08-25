import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The App Launcher page's Required system permissions group (issue #317):
/// there while Return automatically is on, gone while it is off, and gone
/// with the launcher itself, however the auto-return switch is stored.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> open(WidgetTester tester, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.local:8123',
      'ks.ha.token': 'token',
      ...prefs,
    });
    final container = AppContainer();
    await container.settings.init();
    container.homeAssistant.connectionOk.value = true;
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(container: container)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('App Launcher'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Finder heading() => find.text('Required system permissions');

  testWidgets('shows the group with its two grants while auto-return is on', (
    tester,
  ) async {
    await open(tester, {
      'ks.launcher.enabled': true,
      'ks.launcher.auto_return': true,
    });
    expect(heading(), findsOneWidget);
    expect(find.text('Display over other apps'), findsOneWidget);
    expect(find.text('Unrestricted battery'), findsOneWidget);
  });

  testWidgets('hides the group while auto-return is off', (tester) async {
    await open(tester, {
      'ks.launcher.enabled': true,
      'ks.launcher.auto_return': false,
    });
    expect(heading(), findsNothing);
  });

  testWidgets('hides the group with the launcher, whatever auto-return says', (
    tester,
  ) async {
    await open(tester, {
      'ks.launcher.enabled': false,
      'ks.launcher.auto_return': true,
    });
    expect(heading(), findsNothing);
  });

  testWidgets('flipping the switch on the page shows the group', (
    tester,
  ) async {
    await open(tester, {
      'ks.launcher.enabled': true,
      'ks.launcher.auto_return': false,
    });
    expect(heading(), findsNothing);
    await tester.tap(find.text('Return automatically'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(heading(), findsOneWidget);
  });
}
