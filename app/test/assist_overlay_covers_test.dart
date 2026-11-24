import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/voice/assist_view.dart';
import 'package:kiosk_satellite/ui/assist/assist_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppContainer c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    c = AppContainer();
    await c.settings.init();
  });

  tearDown(() async {
    await c.settings.dispose();
  });

  Future<void> pumpOverlay(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AssistOverlay(container: c)),
      ),
    );
  }

  testWidgets('an opaque skin covers the screen once it has faded in', (
    tester,
  ) async {
    await c.settings.set(defs.voiceSkin, 'google-home');
    await pumpOverlay(tester);
    expect(c.voice.covers.value, isFalse);

    c.voice.view.value = const AssistView(phase: AssistPhase.listening);
    await tester.pump();
    // Mid fade the screen still shows through.
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.voice.covers.value, isFalse);
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.voice.covers.value, isTrue);

    // The words fade out first while it still covers. The report that it
    // no longer covers goes out as the fade out starts, not when it ends.
    c.voice.view.value = AssistView.hidden;
    await tester.pump();
    expect(c.voice.covers.value, isTrue);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(c.voice.covers.value, isFalse);
    await tester.pump(const Duration(milliseconds: 500));
    expect(c.voice.covers.value, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  double wordsOpacity(WidgetTester tester) =>
      tester.widget<FadeTransition>(find.byKey(assistWordsKey)).opacity.value;

  testWidgets('a covering hide fades the words before the overlay', (
    tester,
  ) async {
    await c.settings.set(defs.voiceSkin, 'google-home');
    await pumpOverlay(tester);
    c.voice.view.value = const AssistView(
      phase: AssistPhase.speaking,
      command: 'What is the capital of France?',
      answer: 'The capital of France is Paris.',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.voice.covers.value, isTrue);

    c.voice.view.value = AssistView.hidden;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Mid way: the words are going, the overlay is still fully up.
    final overlay = tester.widget<AnimatedOpacity>(
      find
          .descendant(
            of: find.byType(AssistOverlay),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(overlay.opacity, 1);
    expect(wordsOpacity(tester), lessThan(1));
    expect(c.voice.covers.value, isTrue);

    // The words are gone, then the overlay fades out.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(wordsOpacity(tester), 0);
    expect(c.voice.covers.value, isFalse);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('The capital of France is Paris.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a turn during the words fade shows its words at once', (
    tester,
  ) async {
    await c.settings.set(defs.voiceSkin, 'google-home');
    await pumpOverlay(tester);
    c.voice.view.value = const AssistView(
      phase: AssistPhase.speaking,
      answer: 'The capital of France is Paris.',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    c.voice.view.value = AssistView.hidden;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    c.voice.view.value = const AssistView(phase: AssistPhase.listening);
    await tester.pump();
    expect(wordsOpacity(tester), 1);
    expect(c.voice.covers.value, isTrue);
    // The abandoned hide does not come back to take the new turn down.
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.voice.covers.value, isTrue);
    expect(wordsOpacity(tester), 1);
    c.voice.view.value = AssistView.hidden;
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a hide that never covered fades out at once', (tester) async {
    await c.settings.set(defs.voiceSkin, 'google-home');
    await pumpOverlay(tester);
    c.voice.view.value = const AssistView(
      phase: AssistPhase.speaking,
      answer: 'Docked answer.',
      docked: true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.voice.covers.value, isFalse);
    c.voice.view.value = AssistView.hidden;
    await tester.pump();
    final overlay = tester.widget<AnimatedOpacity>(
      find
          .descendant(
            of: find.byType(AssistOverlay),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(overlay.opacity, 0);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a docked bubble and a see-through backdrop do not cover', (
    tester,
  ) async {
    await c.settings.set(defs.voiceSkin, 'google-home');
    await pumpOverlay(tester);

    c.voice.view.value = const AssistView(
      phase: AssistPhase.listening,
      docked: true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.voice.covers.value, isFalse);
    c.voice.view.value = AssistView.hidden;
    await tester.pump(const Duration(milliseconds: 500));

    // A blurred skin shows the screen through its backdrop until the
    // blurred capture lands, which the test harness never provides.
    await c.settings.set(defs.voiceSkin, 'default');
    c.voice.view.value = const AssistView(phase: AssistPhase.listening);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.voice.covers.value, isFalse);

    // Lowering an opaque skin's backdrop opacity lets the screen through.
    await c.settings.set(defs.voiceSkin, 'google-home');
    await c.settings.set(defs.voiceBackgroundOpacity, 60);
    await tester.pump();
    expect(c.voice.covers.value, isFalse);
    await c.settings.set(defs.voiceBackgroundOpacity, 100);
    await tester.pump();
    expect(c.voice.covers.value, isTrue);
    c.voice.view.value = AssistView.hidden;
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
