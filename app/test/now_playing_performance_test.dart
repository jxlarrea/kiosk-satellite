import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/ui/sendspin_player_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppContainer c;
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4AWMAAQAABQABDQottAAAAABJRU5ErkJggg==',
  );

  /// How far the floating card's artist line has scrolled.
  double marqueeOffset(WidgetTester tester) {
    final transform = tester.widget<Transform>(
      find
          .ancestor(
            of: find.textContaining('Long artist name').first,
            matching: find.byType(Transform),
          )
          .first,
    );
    return -transform.transform.getTranslation().x;
  }

  Future<void> boot(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    c = AppContainer();
    await c.settings.init();
    c.sendspin.nowPlaying.value = {
      'title': 'Song',
      'artist': 'Artist',
      'playing': true,
      'durationMs': 200000,
      'positionMs': 30000,
      'receivedAt': DateTime.now().millisecondsSinceEpoch,
    };
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('position updates and progress ticks preserve static widgets', (
    tester,
  ) async {
    await boot(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SendspinFullscreenView(container: c)),
      ),
    );
    await tester.pump();
    final title = tester.widget(find.text('Song'));
    final play = tester.widget(
      find.widgetWithIcon(IconButton, Icons.pause_circle_filled_rounded),
    );
    final slider = tester.widget<Slider>(find.byType(Slider));
    c.sendspin.nowPlaying.value = {
      ...c.sendspin.nowPlaying.value!,
      'positionMs': 60000,
    };
    await tester.pump();
    expect(tester.widget(find.text('Song')), same(title));
    expect(
      tester.widget(
        find.widgetWithIcon(IconButton, Icons.pause_circle_filled_rounded),
      ),
      same(play),
    );
    expect(
      tester.widget<Slider>(find.byType(Slider)).value,
      greaterThan(slider.value),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget(
        find.widgetWithIcon(IconButton, Icons.pause_circle_filled_rounded),
      ),
      same(play),
    );
    c.sendspin.nowPlaying.value = {
      ...c.sendspin.nowPlaying.value!,
      'playing': false,
    };
    await tester.pump();
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the marquee holds without frames and steps whole pixels after', (
    tester,
  ) async {
    await boot(tester);
    tester.view.devicePixelRatio = 2;
    c.sendspin.nowPlaying.value = {
      ...c.sendspin.nowPlaying.value!,
      'artist': List.filled(20, 'Long artist name').join(' '),
    };
    final ticking = ValueNotifier(true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: ticking,
            builder: (context, on, child) =>
                TickerMode(enabled: on, child: child!),
            child: Stack(children: [SendspinPlayerOverlay(container: c)]),
          ),
        ),
      ),
    );
    await tester.pump();
    // The hold: the text stays put and nothing asks for a frame, apart
    // from the progress bar's once a second.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(marqueeOffset(tester), 0);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.binding.hasScheduledFrame, isFalse);
    // Then it scrolls, a physical pixel at a time.
    await tester.pump(const Duration(milliseconds: 1100));
    final moved = marqueeOffset(tester);
    expect(moved, greaterThan(10));
    expect(moved * 2, (moved * 2).roundToDouble());
    // Muted tickers stop it at the start.
    ticking.value = false;
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(marqueeOffset(tester), 0);
    ticking.value = true;
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(marqueeOffset(tester), greaterThan(0));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'covered floating player stops frames and defers artwork until visible',
    (tester) async {
      await boot(tester);
      c.sendspin.nowPlaying.value = {
        ...c.sendspin.nowPlaying.value!,
        'artist': List.filled(20, 'Long artist name').join(' '),
      };
      final loads = <String>[];
      c.sendspin.artworkFetcher = (url) async {
        loads.add(url);
        return png;
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(children: [SendspinPlayerOverlay(container: c)]),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Song'), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
      expect(marqueeOffset(tester), greaterThan(0));
      c.screensaver.activeView.value = 'clock';
      await tester.pump();
      c.sendspin.nowPlaying.value = {
        ...c.sendspin.nowPlaying.value!,
        'title': 'Next',
        'artworkUrl': 'next',
      };
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Next'), findsNothing);
      expect(loads, isEmpty);
      expect(tester.binding.hasScheduledFrame, isFalse);
      c.screensaver.activeView.value = null;
      await tester.pump();
      await tester.pump();
      expect(find.text('Next'), findsWidgets);
      expect(loads, ['next']);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'late artwork cannot replace a newer track and blur is isolated',
    (tester) async {
      await boot(tester);
      // A cover the engine can decode.
      final cover = (await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 32, 32),
          Paint()..color = const Color(0xFF3366CC),
        );
        final image = await recorder.endRecording().toImage(32, 32);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return data!.buffer.asUint8List();
      }))!;
      final pending = <String, Completer<Uint8List?>>{};
      c.sendspin.artworkFetcher = (url) =>
          (pending[url] = Completer<Uint8List?>()).future;
      c.sendspin.nowPlaying.value = {
        ...c.sendspin.nowPlaying.value!,
        'artworkUrl': 'old',
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SendspinFullscreenView(container: c)),
        ),
      );
      c.sendspin.nowPlaying.value = {
        ...c.sendspin.nowPlaying.value!,
        'title': 'Next',
        'artworkUrl': 'new',
      };
      await tester.pump();
      pending['new']!.complete(cover);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final art = tester.widget(find.byKey(const ValueKey('new')));
      pending['old']!.complete(Uint8List.fromList(png));
      await tester.pump();
      expect(tester.widget(find.byKey(const ValueKey('new'))), same(art));
      expect(find.byKey(const ValueKey('old')), findsNothing);
      // The cover is blurred once into a small image, never by a filter
      // that would run again every frame.
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
      // The decode runs for real, its steps resume in the test's clock.
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      final backdrop = tester.widget<RawImage>(
        find.descendant(
          of: find.byKey(const ValueKey('new')),
          matching: find.byType(RawImage),
        ),
      );
      expect(backdrop.image, isNotNull);
      expect(backdrop.image!.width, 160);
      expect(backdrop.fit, BoxFit.cover);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
