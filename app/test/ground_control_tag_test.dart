import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/ground_control_tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The GC tag on settings outside Ground Control that only work with it,
/// and the value Vision Match > Used in other settings shows for them.
void main() {
  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: UiStrings.localizationsDelegates,
    supportedLocales: UiStrings.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets(
    'a Ground Control setting gets the tag, which says what it means',
    (tester) async {
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => Column(
              children: [
                settingTitle(context, defs.lockdownFaceRelock),
                settingTitle(context, defs.screensaverDismissOnFace),
                // In the Ground Control Vision Match group too.
                settingTitle(context, defs.screensaverFaceWho),
              ],
            ),
          ),
        ),
      );
      expect(find.text('GC'), findsNWidgets(2));
      expect(find.byType(GroundControlTag), findsNWidgets(2));
      await tester.tap(find.byType(GroundControlTag).first);
      await tester.pumpAndSettle();
      expect(find.text('A Ground Control setting'), findsOneWidget);
      expect(find.textContaining('Face Recognition'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('Used in other settings shows the option and the chosen people', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.face_who': 'people',
      'ks.screensaver.face_people':
          '[{"id":"ana","name":"Ana"},{"id":"leo","name":"Leo"}]',
      'ks.lockdown.face_relock': false,
    });
    final bus = EventBus();
    final log = Logger();
    final settings = SettingsManager(bus, CommandRegistry(log), log);
    await settings.init();
    late String who;
    late String preview;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            who = groundControlValueText(
              context,
              settings,
              defs.screensaverFaceWho,
            );
            preview = groundControlValueText(
              context,
              settings,
              defs.lockdownFaceRelock,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    expect(who, 'Chosen people: Ana, Leo');
    expect(preview, 'Off');
  });
}
