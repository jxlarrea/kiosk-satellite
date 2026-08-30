import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/motion/motion_manager.dart';
import 'package:kiosk_satellite/managers/motion/native_motion.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/face_preview_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The camera preview overlay (discussion #371): draws the frame the
/// motion manager holds in the configured corner at the configured
/// size, white-rimmed and round, and nothing at all without one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A 4x2 PNG drawn here: enough of a picture to decode and size.
  late Uint8List png;

  late SettingsManager settings;
  late MotionManager motion;

  Future<Uint8List> paintPng(WidgetTester tester) async {
    final bytes = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        const ui.Rect.fromLTWH(0, 0, 4, 2),
        ui.Paint()..color = const ui.Color(0xFF3366AA),
      );
      final image = await recorder.endRecording().toImage(4, 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    return bytes!;
  }

  /// Hands the overlay a frame and lets it decode: image decoding runs
  /// outside the test's fake async zone, so it needs runAsync.
  Future<void> push(WidgetTester tester, FacePreviewFrame? frame) async {
    await tester.runAsync(() async {
      motion.facePreview.value = frame;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
  }

  Future<void> build(
    WidgetTester tester, {
    Map<String, Object> initial = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initial);
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    motion = MotionManager(bus, commands, log, settings);
    png = await paintPng(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            const SizedBox.expand(),
            FacePreviewOverlay(motion: motion, settings: settings),
          ],
        ),
      ),
    );
  }

  /// The rimmed circle: the picture's clip sits inside the rim.
  Finder circle() => find.ancestor(
    of: find.byType(ClipOval),
    matching: find.byType(Container),
  );

  Alignment alignmentOf(WidgetTester tester) =>
      tester
              .widget<Align>(
                find.descendant(
                  of: find.byType(FacePreviewOverlay),
                  matching: find.byType(Align),
                ),
              )
              .alignment
          as Alignment;

  testWidgets('nothing is drawn without a frame', (tester) async {
    await build(tester);
    expect(find.byType(ClipOval), findsNothing);
  });

  testWidgets(
    'a frame draws the round white-rimmed preview in the default corner, '
    'top right, at the base size',
    (tester) async {
      await build(tester);
      await push(
        tester,
        FacePreviewFrame(jpeg: png, rotation: 0, mirror: false),
      );
      expect(find.byType(ClipOval), findsOneWidget);
      expect(alignmentOf(tester), Alignment.topRight);
      final decoration =
          tester.widget<Container>(circle()).decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.border!.top.color, FacePreviewOverlay.rimColor);
      expect(decoration.border!.top.width, FacePreviewOverlay.rim);
      expect(tester.getSize(circle()).width, FacePreviewOverlay.baseDiameter);
      // The taps under it are the dashboard's.
      expect(
        find.ancestor(
          of: find.byType(ClipOval),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );
    },
  );

  testWidgets('the position and scaling settings place and size it', (
    tester,
  ) async {
    await build(
      tester,
      initial: {
        'ks.face.preview_position': 'bottom_left',
        'ks.face.preview_scale': 150,
      },
    );
    await push(tester, FacePreviewFrame(jpeg: png, rotation: 90, mirror: true));
    expect(alignmentOf(tester), Alignment.bottomLeft);
    expect(
      tester.getSize(circle()).width,
      FacePreviewOverlay.baseDiameter * 1.5,
    );
    // Turned upright by the frame's rotation and mirrored for the front
    // camera.
    expect(tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns, 1);
    expect(
      tester
          .widget<Transform>(
            find.descendant(
              of: find.byType(ClipOval),
              matching: find.byType(Transform),
            ),
          )
          .transform,
      Transform.flip(flipX: true, child: const SizedBox()).transform,
    );
  });

  testWidgets('clearing the frame takes the preview away', (tester) async {
    await build(tester);
    await push(tester, FacePreviewFrame(jpeg: png, rotation: 0, mirror: false));
    expect(find.byType(ClipOval), findsOneWidget);
    await push(tester, null);
    expect(find.byType(ClipOval), findsNothing);
  });

  testWidgets('the settings defaults are the ones the discussion asked for', (
    tester,
  ) async {
    expect(defs.facePreview.defaultValue, isFalse);
    expect(defs.facePreviewSeconds.defaultValue, 5);
    expect(defs.facePreviewScale.defaultValue, 100);
    expect(defs.facePreviewPosition.defaultValue, 'top_right');
  });
}
