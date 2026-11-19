import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/app_locales.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:kiosk_satellite/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings > Ground Control lists its features after Connection: Voice
/// Match opens its page under Voice Satellite, Vision Match is coming.
void main() {
  Future<AppContainer> containerFor(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = AppContainer();
    await container.settings.init();
    // Address shows with Ground Control on, Enable Voice Match with Voice
    // Satellite on too.
    await container.settings.set(defs.groundControlEnabled, true);
    await container.settings.set(defs.voiceEnabled, true);
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await container.settings.dispose();
      await container.bus.dispose();
      await container.log.dispose();
      tester.view.reset();
    });
    return container;
  }

  Widget app(AppContainer container) => MaterialApp(
    locale: const Locale('en'),
    supportedLocales: appSupportedLocales,
    localizationsDelegates: appLocalizationsDelegates,
    theme: buildTheme(Brightness.light),
    home: CategorySettingsScreen(
      container: container,
      title: 'Ground Control',
      category: 'Ground Control',
    ),
  );

  testWidgets('Features follow Connection, with Voice Match and Vision Match', (
    tester,
  ) async {
    final container = await containerFor(tester);
    await tester.pumpWidget(app(container));
    await tester.pumpAndSettle();

    double top(String text) => tester.getTopLeft(find.text(text).first).dy;
    for (final text in [
      'Address',
      'Features',
      'Voice Match',
      'Vision Match',
      'Coming soon',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(top('Features'), greaterThan(top('Address')));
    expect(top('Voice Match'), greaterThan(top('Features')));
    expect(top('Vision Match'), greaterThan(top('Voice Match')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Voice Match opens the Ground Control Voice Match page', (
    tester,
  ) async {
    final container = await containerFor(tester);
    await tester.pumpWidget(app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voice Match').first);
    await tester.pumpAndSettle();
    final page = tester.widget<SubpageSettingsScreen>(
      find.byType(SubpageSettingsScreen),
    );
    expect(page.category, 'Voice Satellite');
    expect(page.subpage, 'Ground Control Voice Match');
    expect(find.text('Enable Voice Match'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
