import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/voice/voice_match_enroll.dart';
import 'package:kiosk_satellite/ui/voice_match_enroll_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Voice Match enrollment screen goes through every phase without an
/// error and fits from a Smart Clock sized panel up, in portrait too.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const start = VoiceMatchEnrollment(
    personId: 'p1',
    name: 'Mia',
    color: '#8A6516',
    targetS: 45,
  );

  for (final size in const [
    Size(1280, 800),
    Size(960, 480),
    Size(600, 360),
    Size(800, 1280),
  ]) {
    testWidgets('reads, warns, saves and closes at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final c = AppContainer();
      await c.settings.init();
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(children: [VoiceMatchEnrollOverlay(container: c)]),
        ),
      );
      final e = c.voice.enrollment;

      e.value = start;
      await tester.pump();
      expect(find.text('Enrolling Mia'), findsOneWidget);
      expect(find.text('Getting ready…'), findsOneWidget);

      // Every progress event moves the meter and the text along.
      var s = start.copyWith(phase: EnrollPhase.recording);
      for (var i = 1; i <= 30; i++) {
        s = s.copyWith(speechS: i * 0.5, level: -30.0 + (i % 5));
        e.value = s;
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }
      expect(find.text('15 of 45 s'), findsOneWidget);
      expect(find.text('Getting ready…'), findsNothing);

      e.value = s.copyWith(otherVoices: 1, otherVoiceAt: DateTime.now());
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Another voice is talking. That part is left out.'),
        findsOneWidget,
      );

      e.value = s.copyWith(phase: EnrollPhase.saving, speechS: 45);
      await tester.pump();
      expect(find.text('Saving…'), findsOneWidget);

      e.value = s.copyWith(phase: EnrollPhase.saved, addedS: 45.2);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Mia is enrolled'), findsOneWidget);
      expect(find.text('45 s of speech added.'), findsOneWidget);

      e.value = null;
      await tester.pump();
      expect(find.text('Mia is enrolled'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
