import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/app_locales.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:kiosk_satellite/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings > Ground Control has a page per feature after Connection: Voice
/// Match and Vision Match.
void main() {
  Future<AppContainer> containerFor(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = AppContainer();
    await container.settings.init();
    // Address shows with Ground Control on, Enable Voice Match with Voice
    // Satellite on too.
    await container.settings.set(defs.groundControlEnabled, true);
    await container.settings.set(defs.voiceEnabled, true);
    await container.settings.set(defs.cameraEnabled, true);
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

  testWidgets('the feature pages follow Connection, with their summaries', (
    tester,
  ) async {
    final container = await containerFor(tester);
    await tester.pumpWidget(app(container));
    await tester.pumpAndSettle();

    double top(String text) => tester.getTopLeft(find.text(text).first).dy;
    for (final text in [
      'Address',
      'Voice Match',
      'Recognition, Trimming and Isolation',
      'Vision Match',
      'Face recognition, detection, hand gestures and presence detection',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(top('Voice Match'), greaterThan(top('Address')));
    expect(top('Vision Match'), greaterThan(top('Voice Match')));
    expect(find.text('Coming soon'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  Future<void> opens(WidgetTester tester, String page, String first) async {
    final container = await containerFor(tester);
    await tester.pumpWidget(app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text(page).first);
    await tester.pumpAndSettle();
    final screen = tester.widget<SubpageSettingsScreen>(
      find.byType(SubpageSettingsScreen),
    );
    expect(screen.category, 'Ground Control');
    expect(screen.subpage, page);
    expect(find.text(first), findsWidgets);
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'Voice Match opens its page under Ground Control',
    (tester) async => opens(tester, 'Voice Match', 'Enable Voice Match'),
  );

  testWidgets(
    'Vision Match opens its page under Ground Control',
    (tester) async => opens(tester, 'Vision Match', 'Enable Vision Match'),
  );

  testWidgets('each Vision Match feature has its own group and switch', (
    tester,
  ) async {
    final container = await containerFor(tester);
    await container.settings.set(defs.visionMatchEnabled, true);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: appSupportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        theme: buildTheme(Brightness.light),
        home: SubpageSettingsScreen(
          container: container,
          category: 'Ground Control',
          subpage: 'Vision Match',
        ),
      ),
    );
    await tester.pumpAndSettle();
    double top(String text) => tester.getTopLeft(find.text(text).first).dy;
    for (final text in [
      'Enable Vision Match',
      'Face Detection, Hand Gestures and Face Recognition. Needs Ground '
          'Control.',
      'Face Detection',
      'Enable Face Detection',
      'Run face detection on Ground Control. Disable to run on-device.',
      'Hand Gestures',
      'Enable Hand Gestures',
      'Run palm and fingers gestures detection on Ground Control. Disable to '
          'run on-device.',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(top('Face Detection'), greaterThan(top('Enable Vision Match')));
    expect(top('Hand Gestures'), greaterThan(top('Enable Face Detection')));
    // Used in other settings is the last group on the page.
    expect(
      top('Used in other settings'),
      greaterThan(top('Enable Hand Gestures')),
    );
    expect(container.settings.get(defs.visionMatchFaceDetection), isTrue);
    expect(container.settings.get(defs.visionMatchHandGestures), isTrue);
    expect(tester.takeException(), isNull);
  });
}
