import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
      expect(tester.binding.hasScheduledFrame, isTrue);
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
      pending['new']!.complete(png);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final art = tester.widget<Image>(find.byKey(const ValueKey('new')));
      pending['old']!.complete(Uint8List.fromList(png));
      await tester.pump();
      expect(
        tester.widget<Image>(find.byKey(const ValueKey('new'))),
        same(art),
      );
      expect(find.byKey(const ValueKey('old')), findsNothing);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(ImageFiltered), findsOneWidget);
      expect(art.image, isA<ResizeImage>());
      await tester.pumpWidget(const SizedBox());
    },
  );
}
