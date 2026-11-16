import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/managers/voice/voice_manager.dart';
import 'package:kiosk_satellite/ui/kit.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:kiosk_satellite/ui/volume_curve_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Adaptive volume page on the device (issue #1450): the switch with
/// the room's level under it, a switch per volume and the curve as one
/// editor with a chip and a dialog per point.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const curve =
      '[[-58,40,60,80],[-50,55,70,85],[-41,75,86,96],[-30,100,100,100]]';
  const holds =
      'The reading holds while this device plays. Changes in the room during '
      'playback are not used.';
  const needsWake =
      'If there is no reading, turn on adaptive volume or wake word detection '
      'and check that the microphone is not muted.';

  Future<AppContainer> open(
    WidgetTester tester,
    Map<String, Object> prefs,
  ) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.local:8123',
      'ks.ha.token': 'token',
      'ks.audio.adaptive_volume_curve': curve,
      ...prefs,
    });
    final container = AppContainer();
    await container.settings.init();
    await container.adaptiveVolume.init();
    container.homeAssistant.connectionOk.value = true;
    // Tall enough that a page renders whole: off-screen rows do not exist.
    tester.view.physicalSize = const Size(500, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(container: container)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    return container;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> tab(WidgetTester tester, String title) async {
    await tester.tap(find.text(title).first);
    await settle(tester);
  }

  Future<void> page(WidgetTester tester) async {
    await tab(tester, 'Screen & Audio');
    await tab(tester, 'Adaptive volume');
  }

  testWidgets('the page has an entry row under the volume sliders', (
    tester,
  ) async {
    await open(tester, {});
    await tab(tester, 'Screen & Audio');
    expect(find.text('Adaptive volume'), findsOneWidget);
    expect(
      find.text('Follow the room noise with the microphone'),
      findsOneWidget,
    );
    // The page's own rows stay on the page.
    expect(find.text('Enable adaptive volume'), findsNothing);
  });

  testWidgets('off, the page is the switch and the room reading', (
    tester,
  ) async {
    await open(tester, {});
    await page(tester);
    expect(find.text('Enable adaptive volume'), findsOneWidget);
    expect(find.text('Room noise'), findsOneWidget);
    expect(find.text('No reading yet'), findsOneWidget);
    expect(find.text(holds), findsOneWidget);
    expect(find.text(needsWake), findsOneWidget);
    expect(find.text('Volumes'), findsNothing);
    expect(find.byType(VolumeCurveEditor), findsNothing);
  });

  testWidgets('the room reading is live', (tester) async {
    final container = await open(tester, {});
    await page(tester);
    container.bus.publish(const NoiseWindowMeasured(-48.2));
    await settle(tester);
    expect(find.text('-48 dBFS'), findsOneWidget);
    expect(find.text('No reading yet'), findsNothing);
    expect(find.text(needsWake), findsNothing);
  });

  testWidgets('on, a switch per volume and the curve as one editor', (
    tester,
  ) async {
    await open(tester, {
      'ks.audio.adaptive_volume': true,
      'ks.intercom.enabled': true,
    });
    await page(tester);
    expect(find.text('Volumes'), findsOneWidget);
    // Each volume's switch, and the key above the chart for the one that
    // follows the room by default.
    expect(find.text('Assistant'), findsNWidgets(2));
    expect(find.text('Media'), findsOneWidget);
    expect(find.text('Intercom'), findsOneWidget);
    expect(find.text('Volume curve'), findsOneWidget);
    expect(find.byType(VolumeCurveEditor), findsOneWidget);
    // A chip per point: its noise level over the assistant's volume.
    expect(find.text('-58 dBFS'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('-30 dBFS'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('the Intercom switch needs the intercom', (tester) async {
    await open(tester, {'ks.audio.adaptive_volume': true});
    await page(tester);
    expect(find.text('Media'), findsOneWidget);
    expect(find.text('Intercom'), findsNothing);
  });

  testWidgets('a volume that follows the room joins the chips', (tester) async {
    final container = await open(tester, {
      'ks.audio.adaptive_volume': true,
      'ks.intercom.enabled': true,
    });
    await page(tester);
    await container.settings.set(adaptiveVolumeMedia, true);
    await container.settings.set(adaptiveVolumeIntercom, true);
    await settle(tester);
    expect(find.text('40% · 60% · 80%'), findsOneWidget);
    expect(find.text('55% · 70% · 85%'), findsOneWidget);
    expect(find.text('Media'), findsNWidgets(2));
    expect(find.text('Intercom'), findsNWidgets(2));
  });

  testWidgets('a chip opens its point for typed values and writes them', (
    tester,
  ) async {
    final container = await open(tester, {
      'ks.audio.adaptive_volume': true,
      'ks.audio.adaptive_volume_media': true,
    });
    await page(tester);
    await tester.tap(find.text('-50 dBFS'));
    await tester.pumpAndSettle();
    expect(find.text('Point 2'), findsOneWidget);
    expect(find.text('Room noise (dBFS)'), findsOneWidget);
    expect(find.text('Assistant (%)'), findsOneWidget);
    expect(find.text('Media (%)'), findsOneWidget);
    // The intercom does not follow the room, so it has no field.
    expect(find.text('Intercom (%)'), findsNothing);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '-52');
    await tester.enterText(fields.at(1), '50');
    await tester.enterText(fields.at(2), '65');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Point 2'), findsNothing);
    // The intercom's volume on that point stays as it was.
    expect(
      container.settings.get(adaptiveVolumeCurve),
      '[[-58,40,60,80],[-52,50,65,85],[-41,75,86,96],[-30,100,100,100]]',
    );
    expect(find.text('-52 dBFS'), findsOneWidget);
    expect(find.text('50% · 65%'), findsOneWidget);
  });

  testWidgets('a value past a neighbor is refused in the dialog', (
    tester,
  ) async {
    final container = await open(tester, {
      'ks.audio.adaptive_volume': true,
      'ks.audio.adaptive_volume_media': true,
    });
    await page(tester);
    await tester.tap(find.text('-50 dBFS'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '-40');
    await tester.enterText(fields.at(1), '55');
    await tester.enterText(fields.at(2), '95');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a room noise level between -57 and -42 dBFS'),
      findsOne,
    );
    expect(find.text('Enter a volume from 60% to 86%'), findsOne);
    // The assistant's value was fine and carries no error.
    expect(find.text('Enter a volume from 40% to 75%'), findsNothing);
    expect(find.text('Point 2'), findsOneWidget);
    expect(container.settings.get(adaptiveVolumeCurve), curve);
  });

  testWidgets('the first and last points are bounded by the range', (
    tester,
  ) async {
    await open(tester, {'ks.audio.adaptive_volume': true});
    await page(tester);
    await tester.tap(find.text('-58 dBFS'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '-120');
    await tester.enterText(find.byType(TextField).at(1), '70');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a room noise level between -96 and -51 dBFS'),
      findsOne,
    );
    expect(find.text('Enter a volume from 0% to 55%'), findsOne);
  });

  testWidgets('dragging a ring moves its point and that volume', (
    tester,
  ) async {
    final container = await open(tester, {'ks.audio.adaptive_volume': true});
    await page(tester);
    final chart = find.descendant(
      of: find.byType(VolumeCurveEditor),
      matching: find.byType(CustomPaint),
    );
    // The chart is the tall one: the key's line samples are 10 high.
    final box = tester
        .renderObjectList<RenderBox>(chart)
        .firstWhere((b) => b.size.height > 100);
    final origin = box.localToGlobal(Offset.zero);
    // The plot inside the axis labels, from -70 to -20 dBFS.
    final plot = Rect.fromLTRB(
      origin.dx + 40,
      origin.dy + 14,
      origin.dx + box.size.width - 10,
      origin.dy + box.size.height - 26,
    );
    Offset at(double noise, double level) => Offset(
      plot.left + (noise + 70) / 50 * plot.width,
      plot.bottom - level * plot.height,
    );
    // Point 2 sits at -50 dBFS and 55%. Down to 45% and left to -54.
    final gesture = await tester.startGesture(at(-50, 0.55));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(at(-52, 0.5));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(at(-54, 0.45));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      container.settings.get(adaptiveVolumeCurve),
      '[[-58,40,60,80],[-54,45,70,85],[-41,75,86,96],[-30,100,100,100]]',
    );
  });

  testWidgets('a ring dragged past its neighbor stops at it', (tester) async {
    final container = await open(tester, {'ks.audio.adaptive_volume': true});
    await page(tester);
    final chart = find.descendant(
      of: find.byType(VolumeCurveEditor),
      matching: find.byType(CustomPaint),
    );
    final box = tester
        .renderObjectList<RenderBox>(chart)
        .firstWhere((b) => b.size.height > 100);
    final origin = box.localToGlobal(Offset.zero);
    final plot = Rect.fromLTRB(
      origin.dx + 40,
      origin.dy + 14,
      origin.dx + box.size.width - 10,
      origin.dy + box.size.height - 26,
    );
    Offset at(double noise, double level) => Offset(
      plot.left + (noise + 70) / 50 * plot.width,
      plot.bottom - level * plot.height,
    );
    final gesture = await tester.startGesture(at(-50, 0.55));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(at(-45, 0.8));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(at(-25, 1));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();
    // One dB short of point 3's noise level, and at its volume.
    expect(
      container.settings.get(adaptiveVolumeCurve),
      '[[-58,40,60,80],[-42,75,70,85],[-41,75,86,96],[-30,100,100,100]]',
    );
  });

  testWidgets('a curve written elsewhere (the remote admin) redraws', (
    tester,
  ) async {
    final container = await open(tester, {'ks.audio.adaptive_volume': true});
    await page(tester);
    await container.settings.setFromJson(
      'audio.adaptive_volume_curve',
      '[[-62,30,60,80],[-50,55,70,85],[-41,75,86,96],[-30,100,100,100]]',
      source: 'remote admin',
    );
    await settle(tester);
    expect(find.text('-62 dBFS'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
  });

  group('Test volume', () {
    /// The commands the two buttons ran, with their parameters.
    late List<(String, Map<String, Object?>)> ran;

    void fakeCommands(AppContainer container, {bool ok = true}) {
      ran = [];
      for (final name in ['voiceTestAnnouncement', 'announce']) {
        container.commands.register(
          Command(
            name: name,
            description: 'test',
            handler: (p) async {
              ran.add((name, p));
              return ok
                  ? const CommandResult.ok()
                  : const CommandResult.fail('no');
            },
          ),
        );
      }
    }

    FilledButton button(WidgetTester tester, String row) => tester.widget(
      find.descendant(
        of: find.ancestor(
          of: find.text(row),
          matching: find.byType(SettingsRow),
        ),
        matching: find.byType(FilledButton),
      ),
    );

    testWidgets('off, there is no Test volume group', (tester) async {
      await open(tester, {});
      await page(tester);
      expect(find.text('Test volume'), findsNothing);
      expect(find.text('Test Assistant volume'), findsNothing);
    });

    testWidgets('a button waits for its feature to be set up', (tester) async {
      await open(tester, {
        'ks.audio.adaptive_volume': true,
        'ks.voice.enabled': false,
        'ks.esphome.enabled': false,
      });
      await page(tester);
      expect(find.text('Test volume'), findsOneWidget);
      expect(find.text('Test Assistant volume'), findsOneWidget);
      expect(find.text('Test Media volume'), findsOneWidget);
      expect(button(tester, 'Test Assistant volume').onPressed, isNull);
      expect(button(tester, 'Test Media volume').onPressed, isNull);
    });

    testWidgets('set up, each button plays its announcement', (tester) async {
      final container = await open(tester, {
        'ks.audio.adaptive_volume': true,
        'ks.voice.enabled': true,
        'ks.esphome.enabled': true,
        'ks.announcements.enabled': true,
      });
      fakeCommands(container);
      container.voice.homeAssistant.value = const VoiceHaState(
        subscribed: true,
        satelliteEntity: 'assist_satellite.kitchen',
      );
      await page(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Test').first);
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Test').last);
      await settle(tester);
      const message = 'This is how loud an announcement plays right now.';
      expect(ran.map((r) => r.$1), ['voiceTestAnnouncement', 'announce']);
      expect(ran.first.$2, {'message': message});
      // Audio only: Settings stay on screen for the next try.
      expect(ran.last.$2, {'message': message, 'audio_only': true});
    });

    testWidgets('a failed test says so on its button for a moment', (
      tester,
    ) async {
      final container = await open(tester, {
        'ks.audio.adaptive_volume': true,
        'ks.esphome.enabled': true,
        'ks.announcements.enabled': true,
      });
      fakeCommands(container, ok: false);
      await page(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Test').last);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.widgetWithText(FilledButton, 'Failed'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.widgetWithText(FilledButton, 'Failed'), findsNothing);
    });
  });
}
