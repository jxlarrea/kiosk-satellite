import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/managers/sendspin/lyrics.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/lyrics_view.dart';
import 'package:kiosk_satellite/ui/photo_frames.dart';
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:kiosk_satellite/ui/sendspin_player_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppContainer c;
  final saver = find.byKey(const ValueKey('screensaver-pane'));
  final player = find.byKey(const ValueKey('now-playing-pane'));
  final play = find.byIcon(Icons.pause_circle_filled_rounded);

  Future<void> boot(
    WidgetTester tester, {
    Size size = const Size(1280, 800),
    bool split = true,
    String mode = 'clock',
    bool controls = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.mode': mode,
      'ks.sendspin.fullscreen': true,
      'ks.sendspin.fullscreen_split': split,
      'ks.sendspin.fullscreen_controls': controls,
      'ks.sendspin.local_player_name':
          'A very long speaker name for the kitchen display',
    });
    c = AppContainer();
    await c.settings.init();
    await c.screensaver.init();
    c.sendspin.artworkFetcher = (_) async => base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4AWMAAQAABQABDQottAAAAABJRU5ErkJggg==',
    );
    c.sendspin.nowPlaying.value = {
      'title': 'A long song title that needs to fit inside the player panel',
      'artist': 'Artist',
      'album': 'Album',
      'artworkUrl': 'cover',
      'playing': true,
      'durationMs': 200000,
      'positionMs': 30000,
      'volume': 50,
    };
    c.sendspin.fullscreenActive.value = true;
    c.bus.publish(const SendspinNowPlayingChanged(active: true, playing: true));
    await tester.pump();
    await c.screensaver.start();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Listener(
            onPointerDown: (_) =>
                c.bus.publish(const ActivityDetected(source: 'touch')),
            child: Stack(children: [ScreensaverOverlay(container: c)]),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  for (final size in [
    const Size(1280, 800),
    const Size(800, 480),
    const Size(1024, 600),
    const Size(1920, 1080),
    const Size(800, 1280),
    const Size(360, 800),
  ]) {
    testWidgets('both panels and controls fit at $size', (tester) async {
      await boot(tester, size: size);
      final saverRect = tester.getRect(saver);
      final playerRect = tester.getRect(player);
      expect(saverRect.overlaps(playerRect), isFalse);
      if (size.width > size.height) {
        expect(saverRect.right, playerRect.left);
        expect(saverRect.width, greaterThan(playerRect.width));
      } else {
        expect(saverRect.bottom, playerRect.top);
        expect(saverRect.width, size.width);
      }
      expect(
        MediaQuery.sizeOf(tester.element(find.byType(SendspinFullscreenView))),
        playerRect.size,
      );
      for (final icon in [
        Icons.skip_previous_rounded,
        Icons.pause_circle_filled_rounded,
        Icons.skip_next_rounded,
        Icons.close,
      ]) {
        final rect = tester.getRect(find.byIcon(icon));
        expect(playerRect.contains(rect.topLeft), isTrue);
        expect(playerRect.contains(rect.bottomRight), isTrue);
      }
      expect(tester.getSize(play).width, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await c.screensaver.dispose();
    });
  }

  testWidgets('the toggle applies live and persists', (tester) async {
    await boot(tester, split: false);
    expect(saver, findsNothing);
    expect(tester.getSize(player), const Size(1280, 800));
    await c.settings.set(defs.sendspinFullscreenSplit, true);
    await tester.pump();
    await tester.pump();
    expect(saver, findsOneWidget);
    expect(tester.getSize(player).width, lessThan(640));
    final reopened = AppContainer();
    await reopened.settings.init();
    expect(reopened.settings.get(defs.sendspinFullscreenSplit), isTrue);
    await c.settings.set(defs.sendspinFullscreenSplit, false);
    await tester.pump();
    await tester.pump();
    expect(saver, findsNothing);
    expect(tester.getSize(player), const Size(1280, 800));
    await tester.pumpWidget(const SizedBox());
    await c.screensaver.dispose();
  });

  testWidgets('small screens retain the full screen player', (tester) async {
    await boot(tester, size: const Size(640, 480));
    expect(saver, findsNothing);
    expect(tester.getSize(player), const Size(640, 480));
    expect(
      tester
          .widget<SendspinFullscreenView>(find.byType(SendspinFullscreenView))
          .alongsideScreensaver,
      isFalse,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await c.screensaver.dispose();
  });

  testWidgets('photo fill override only applies to the shared screensaver', (
    tester,
  ) async {
    await boot(tester);
    String fill(String fallback) => PhotoFillOverride.resolve(
      tester.element(find.byType(ClockScreensaver)),
      fallback,
    );
    expect(fill('off'), 'always');
    for (final choice in ['off', 'smart', 'always', 'default']) {
      await c.settings.set(defs.sendspinFullscreenPhotoFill, choice);
      await tester.pump();
      await tester.pump();
      for (final fallback in ['off', 'smart', 'always']) {
        expect(fill(fallback), choice == 'default' ? fallback : choice);
      }
    }
    await c.settings.set(defs.sendspinFullscreenPhotoFill, 'always');
    c.sendspin.fullscreenActive.value = false;
    await tester.pump();
    await tester.pump();
    expect(fill('off'), 'off');
    expect(fill('smart'), 'smart');
    await tester.pumpWidget(const SizedBox());
    await c.screensaver.dispose();
  });

  testWidgets('playback ending expands the existing screensaver', (
    tester,
  ) async {
    await boot(tester);
    final state = tester.state(find.byType(ClockScreensaver));
    c.sendspin.fullscreenActive.value = false;
    c.bus.publish(const SendspinNowPlayingChanged(active: false));
    await tester.pump();
    expect(player, findsNothing);
    expect(tester.getSize(saver), const Size(1280, 800));
    expect(tester.state(find.byType(ClockScreensaver)), same(state));
    await tester.pumpWidget(const SizedBox());
    await c.screensaver.dispose();
  });

  testWidgets('photo edge taps stay inside the screensaver panel', (
    tester,
  ) async {
    await boot(tester, mode: 'gallery');
    final steps = <int>[];
    c.screensaver.attachSlides((direction) async => steps.add(direction));
    final saverRect = tester.getRect(saver);
    await tester.tapAt(Offset(saverRect.right - 10, saverRect.center.dy));
    await tester.pump();
    expect(steps, [1]);
    expect(c.screensaver.isActive, isTrue);
    await tester.tapAt(tester.getRect(player).center);
    await tester.pump();
    expect(steps, [1]);
    expect(c.screensaver.isActive, isTrue);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(c.screensaver.isActive, isFalse);
    await tester.pumpWidget(const SizedBox());
    await c.screensaver.dispose();
  });

  testWidgets('lyrics remain available in a short player panel', (
    tester,
  ) async {
    await boot(tester, size: const Size(800, 480));
    c.sendspin.lyrics.value = const [
      LyricLine(Duration.zero, 'The first line'),
      LyricLine(Duration(seconds: 40), 'The next line'),
    ];
    await c.settings.set(defs.sendspinLyrics, true);
    await tester.pump();
    expect(find.byType(LyricsView), findsOneWidget);
    expect(play, findsOneWidget);
    expect(tester.takeException(), isNull);
    await c.settings.set(defs.sendspinLyrics, false);
    await tester.pump();
    expect(find.byType(LyricsView), findsNothing);
    expect(
      find.text('A long song title that needs to fit inside the player panel'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await c.screensaver.dispose();
  });

  testWidgets('controls off keeps tap to dismiss across both panels', (
    tester,
  ) async {
    await boot(tester, controls: false);
    expect(play, findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    await tester.tapAt(tester.getRect(player).center);
    await tester.pump();
    expect(c.screensaver.isActive, isFalse);
    await tester.pumpWidget(const SizedBox());
    await c.screensaver.dispose();
  });
}
