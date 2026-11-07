import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/voice/assist_view.dart';
import 'package:kiosk_satellite/ui/assist/assist_overlay.dart';
import 'package:kiosk_satellite/ui/assist/assist_art.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppContainer c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
    });
    c = AppContainer();
    await c.settings.init();
  });

  tearDown(() async {
    await c.settings.dispose();
  });

  // The kiosk screen reports every touch after whatever it landed on, and
  // a screensaver sits under the overlay.
  var now = DateTime(2026, 11, 7);

  Future<void> pumpOverScreensaver(WidgetTester tester) async {
    c.screensaver.clock = () => now;
    await c.screensaver.start(force: true);
    expect(c.screensaver.isActive, isTrue);
    await tester.pumpWidget(
      MaterialApp(
        home: Listener(
          onPointerDown: (_) => c.screensaver.notifyActivity('touch'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Listener(
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
              AssistOverlay(container: c),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('touches on the docked bubble leave the screensaver up', (
    tester,
  ) async {
    await c.settings.set(defs.voiceSkin, 'google-home');
    await pumpOverScreensaver(tester);
    c.voice.view.value = const AssistView(
      phase: AssistPhase.speaking,
      answer: 'It is sunny.',
      docked: true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final bubble = tester.getCenter(find.byType(DockedBarLayer));
    // Apart, so neither is a double tap, which would end the turn.
    await tester.tapAt(bubble);
    await tester.pump(const Duration(milliseconds: 400));
    now = now.add(const Duration(seconds: 1));
    await tester.tapAt(bubble);
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.screensaver.isActive, isTrue);

    // A touch beside it is on the screensaver.
    now = now.add(const Duration(seconds: 1));
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(c.screensaver.isActive, isFalse);
    c.voice.view.value = AssistView.hidden;
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox.shrink());
    await c.screensaver.dispose();
  });

  testWidgets('a touch on the full screen overlay leaves the screensaver up', (
    tester,
  ) async {
    await c.settings.set(defs.voiceSkin, 'google-home');
    await pumpOverScreensaver(tester);
    c.voice.view.value = const AssistView(phase: AssistPhase.listening);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.screensaver.isActive, isTrue);
    c.voice.view.value = AssistView.hidden;
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox.shrink());
    await c.screensaver.dispose();
  });
}
