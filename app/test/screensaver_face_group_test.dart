import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/ui/ground_control_settings.dart';
import 'package:kiosk_satellite/ui/ground_control_tag.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screensaver > Face Detection > Ground Control Vision Match: its own
/// group, there only with Face Recognition on Ground Control, with Detect
/// faces as a dropdown and People, Voice Match's picker, on Chosen people.
void main() {
  Future<void> open(WidgetTester tester, Map<String, Object> extra) async {
    SharedPreferences.setMockInitialValues({
      'ks.camera.enabled': true,
      'ks.ground_control.enabled': true,
      'ks.vision_match.enabled': true,
      'ks.vision_match.face_detection': true,
      'ks.screensaver.dismiss_on_face': true,
      ...extra,
    });
    final c = AppContainer();
    await c.settings.init();
    tester.view.physicalSize = const Size(1280, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: SubpageSettingsScreen(
          container: c,
          category: 'Screensaver',
          subpage: 'Face Detection',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('with Face Recognition on: the group, the dropdown and People', (
    tester,
  ) async {
    await open(tester, {
      'ks.vision_match.face_recognition': true,
      'ks.screensaver.face_who': 'people',
    });
    expect(find.text('Ground Control Vision Match'), findsOneWidget);
    expect(find.text('Detect faces'), findsOneWidget);
    expect(find.text('Chosen people'), findsWidgets);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(VoiceMatchPeopleRow), findsOneWidget);
    // The rows carry the GC tag, in the group as everywhere else.
    expect(
      find.descendant(
        of: find.byType(VoiceMatchPeopleRow),
        matching: find.byType(GroundControlTag),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Anyone hides People', (tester) async {
    await open(tester, {'ks.vision_match.face_recognition': true});
    expect(find.text('Detect faces'), findsOneWidget);
    expect(find.byType(VoiceMatchPeopleRow), findsNothing);
  });

  testWidgets('without Face Recognition the group is not there', (
    tester,
  ) async {
    await open(tester, {
      'ks.vision_match.face_recognition': false,
      'ks.screensaver.face_who': 'people',
    });
    expect(find.text('Ground Control Vision Match'), findsNothing);
    expect(find.text('Detect faces'), findsNothing);
    expect(find.byType(VoiceMatchPeopleRow), findsNothing);
  });
}
