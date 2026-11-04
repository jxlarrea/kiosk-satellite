import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/voice/assist_view.dart';
import 'package:kiosk_satellite/ui/assist/assist_overlay.dart';
import 'package:kiosk_satellite/ui/assist/assist_skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppContainer c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    c = AppContainer();
    await c.settings.init();
    await c.settings.set(defs.voiceSkin, 'kiosk-satellite');
  });

  tearDown(() async {
    await c.settings.dispose();
  });

  Future<void> show(WidgetTester tester, AssistView view) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AssistOverlay(container: c)),
      ),
    );
    c.voice.view.value = view;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> hide(WidgetTester tester) async {
    c.voice.view.value = AssistView.hidden;
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets('the command drops its line breaks and stays on one line', (
    tester,
  ) async {
    await show(
      tester,
      const AssistView(
        phase: AssistPhase.thinking,
        command: ' What is the\nlocal   weather?\n',
      ),
    );

    final command = tester.widget<Text>(
      find.text('What is the local weather?'),
    );
    expect(command.maxLines, 1);
    expect(command.overflow, TextOverflow.ellipsis);
    await hide(tester);
  });

  testWidgets('the command takes the whole width of the chat', (tester) async {
    // 20 glyphs of the test font at 32 px: past the message cap of 578 and
    // inside the chat's 680.
    final command = 'x' * 20;
    await show(
      tester,
      AssistView(phase: AssistPhase.thinking, command: command),
    );

    final width = tester.getSize(find.text(command)).width;
    expect(width, greaterThan(578));
    expect(width, lessThanOrEqualTo(680));
    await hide(tester);
  });

  testWidgets('a docked command drops its line breaks and still wraps', (
    tester,
  ) async {
    await show(
      tester,
      const AssistView(
        phase: AssistPhase.listening,
        docked: true,
        command: 'What is the local weather?\n',
      ),
    );

    final command = tester.widget<Text>(
      find.text('What is the local weather?'),
    );
    expect(command.maxLines, isNull);
    await hide(tester);
  });

  testWidgets('above 100% the command and tool grow slower than the answer', (
    tester,
  ) async {
    final skin = assistSkinById('kiosk-satellite');
    await c.settings.set(defs.voiceTextScale, 200);
    await show(
      tester,
      const AssistView(
        phase: AssistPhase.speaking,
        command: 'Command',
        tools: ['Tool'],
        answer: 'Answer',
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    double size(String text) =>
        tester.widget<Text>(find.text(text)).style!.fontSize!;
    expect(size('Command'), skin.userSize * 1.5);
    expect(size('Tool'), skin.toolSize * 1.5);
    expect(size('Answer'), skin.answerSize * 2);
    await hide(tester);
  });

  test('at 100% and below the lines follow the answer', () {
    expect(secondaryTextScale(0.5), 0.5);
    expect(secondaryTextScale(1), 1);
    expect(secondaryTextScale(1.25), 1.125);
    expect(secondaryTextScale(2), 1.5);
  });
}
