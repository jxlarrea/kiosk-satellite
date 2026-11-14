import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web Browsing shows Custom user agent between Ignore SSL errors and the
/// URL Filter (issue #1425), where the remote admin draws it too.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the field follows Ignore SSL errors', (tester) async {
    SharedPreferences.setMockInitialValues({});
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
    final field = find.text(browserUserAgent.title);
    expect(field, findsOneWidget);
    // A multiline field shows its description on the row.
    expect(find.text(browserUserAgent.description), findsOneWidget);
    final y = tester.getTopLeft(field).dy;
    expect(
      y,
      greaterThan(tester.getTopLeft(find.text(ignoreSslErrors.title)).dy),
    );
    expect(y, lessThan(tester.getTopLeft(find.text('URL Filter')).dy));

    // The editor has room for a long user agent.
    await tester.tap(field);
    await tester.pumpAndSettle();
    final editor = tester.widget<TextField>(find.byType(TextField).last);
    expect(editor.minLines, 6);
    expect(editor.maxLines, 14);
  });
}
