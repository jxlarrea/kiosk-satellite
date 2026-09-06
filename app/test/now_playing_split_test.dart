import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
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
  late List<double> brightness;
  final saver = find.byKey(const ValueKey('screensaver-pane'));
  final player = find.byKey(const ValueKey('now-playing-pane'));
  final play = find.byIcon(Icons.pause_circle_filled_rounded);

  Future<void> boot(
    WidgetTester tester, {
    Size size = const Size(1280, 800),
    bool split = true,
    String mode = 'clock',
    bool controls = true,
    Map<String, Object> prefs = const {},
    DateTime Function()? scheduleClock,
  }) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.mode': mode,
      'ks.sendspin.fullscreen': true,
      'ks.sendspin.fullscreen_split': split,
      'ks.sendspin.fullscreen_controls': controls,
      'ks.sendspin.local_player_name':
          'A very long speaker name for the kitchen display',
      ...prefs,
    });
    c = AppContainer();
    await c.settings.init();
    brightness = [];
    c.commands.register(
      Command(
        name: 'getBrightness',
        description: 'test brightness',
        handler: (_) async => const CommandResult.ok(0.8),
      ),
    );
    c.commands.register(
      Command(
        name: 'setBrightness',
        description: 'test brightness',
        handler: (params) async {
          brightness.add((params['level'] as num).toDouble());
          return const CommandResult.ok();
        },
      ),
    );
    c.screensaver.clock = scheduleClock ?? tester.binding.clock.now;
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
      ]) {
        final rect = tester.getRect(find.byIcon(icon));
        expect(playerRect.contains(rect.topLeft), isTrue);
        expect(playerRect.contains(rect.bottomRight), isTrue);
      }
      expect(find.byIcon(Icons.close), findsNothing);
      expect(c.screensaver.nowPlayingShared, isTrue);
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
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tapAt(saverRect.center);
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

  testWidgets('controls off still dismisses through the screensaver panel', (
    tester,
  ) async {
    await boot(tester, controls: false);
    expect(play, findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    await tester.tapAt(tester.getRect(player).center);
    await tester.pump();
    expect(c.screensaver.isActive, isTrue);
    await tester.tapAt(tester.getRect(saver).center);
    await tester.pump();
    expect(c.screensaver.isActive, isFalse);
    await tester.pumpWidget(const SizedBox());
    await c.screensaver.dispose();
  });
  for (final doubleTap in [false, true]) {
    testWidgets(
      'shared view dismisses with one screensaver tap with double tap $doubleTap',
      (tester) async {
        await boot(
          tester,
          prefs: {'ks.sendspin.fullscreen_double_tap': doubleTap},
        );
        expect(find.byIcon(Icons.close), findsNothing);
        await tester.tapAt(tester.getRect(player).center);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tapAt(tester.getRect(player).center);
        await tester.pump();
        expect(c.screensaver.isActive, isTrue);
        await tester.tapAt(tester.getRect(saver).center);
        await tester.pump();
        expect(c.screensaver.isActive, isFalse);
        await tester.pumpWidget(const SizedBox());
        await c.screensaver.dispose();
      },
    );
  }

  for (final doubleTap in [false, true]) {
    testWidgets(
      'small-screen fallback retains standalone dismissal with double tap $doubleTap',
      (tester) async {
        await boot(
          tester,
          size: const Size(640, 480),
          prefs: {'ks.sendspin.fullscreen_double_tap': doubleTap},
        );
        expect(c.screensaver.nowPlayingShared, isFalse);
        expect(
          find.byIcon(Icons.close),
          doubleTap ? findsNothing : findsOneWidget,
        );
        if (doubleTap) {
          await tester.tapAt(tester.getRect(player).center);
          await tester.pump(const Duration(milliseconds: 200));
          expect(c.screensaver.isActive, isTrue);
          await tester.tapAt(tester.getRect(player).center);
        } else {
          await tester.tap(find.byIcon(Icons.close));
        }
        await tester.pump();
        expect(c.screensaver.isActive, isFalse);
        await tester.pumpWidget(const SizedBox());
        await c.screensaver.dispose();
      },
    );
  }

  for (final (key, event) in <(String, AppEvent)>[
    ('motion', const MotionDetected()),
    ('face', const FaceDetected()),
    ('person', const PersonDetected()),
    ('proximity', const ProximityDetected()),
  ]) {
    testWidgets('shared view follows the screensaver $key dismissal switch', (
      tester,
    ) async {
      await boot(
        tester,
        prefs: {
          'ks.screensaver.dismiss_on_motion': false,
          'ks.screensaver.dismiss_on_$key': true,
          'ks.sendspin.fullscreen_motion': false,
        },
      );
      c.bus.publish(event);
      await tester.pump();
      expect(c.screensaver.isActive, isFalse);
      await tester.pumpWidget(const SizedBox());
      await c.screensaver.dispose();
    });
  }

  testWidgets(
    'shared brightness follows the screensaver and restores on dismissal',
    (tester) async {
      await boot(
        tester,
        prefs: {
          'ks.screensaver.brightness_enabled': true,
          'ks.screensaver.brightness_level': 0.2,
        },
      );
      expect(brightness.last, 0.2);
      await c.settings.set(defs.screensaverBrightnessLevel, 0.3);
      await tester.pump();
      expect(brightness.last, 0.3);
      tester.view.physicalSize = const Size(640, 480);
      await tester.pump();
      await tester.pump();
      expect(c.screensaver.nowPlayingShared, isFalse);
      expect(brightness.last, 0.8);
      expect(find.byIcon(Icons.close), findsOneWidget);
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pump();
      await tester.pump();
      expect(c.screensaver.nowPlayingShared, isTrue);
      expect(brightness.last, 0.3);
      expect(find.byIcon(Icons.close), findsNothing);
      await tester.tapAt(tester.getRect(saver).center);
      await tester.pump();
      expect(brightness.last, 0.8);
      await tester.pumpWidget(const SizedBox());
      await c.screensaver.dispose();
    },
  );

  testWidgets('shared brightness honors the active schedule', (tester) async {
    await boot(
      tester,
      prefs: {
        'ks.screensaver.brightness_enabled': true,
        'ks.screensaver.brightness_level': 0.2,
        'ks.screensaver.schedule_enabled': true,
        'ks.screensaver.schedule':
            '[{"at":"00:00","mode":"clock","brightness":0.1}]',
      },
    );
    expect(brightness.last, 0.1);
    await c.settings.set(defs.screensaverBrightnessLevel, 0.3);
    await tester.pump();
    expect(brightness.last, 0.1);
    await tester.pumpWidget(const SizedBox());
    await c.screensaver.dispose();
  });

  testWidgets(
    'shared brightness override applies live and ends with Now Playing',
    (tester) async {
      await boot(
        tester,
        prefs: {
          'ks.screensaver.brightness_enabled': true,
          'ks.screensaver.brightness_level': 0.2,
        },
      );
      expect(brightness.last, 0.2);
      await c.settings.set(defs.sendspinFullscreenOverrideBrightness, true);
      await tester.pump();
      expect(brightness.last, 0.8);
      expect(c.screensaver.nowPlayingShared, isTrue);
      expect(find.byIcon(Icons.close), findsNothing);
      await c.settings.set(defs.screensaverBrightnessLevel, 0.3);
      await tester.pump();
      expect(brightness.last, 0.8);
      await c.settings.set(defs.sendspinFullscreenOverrideBrightness, false);
      await tester.pump();
      expect(brightness.last, 0.3);
      await c.settings.set(defs.sendspinFullscreenOverrideBrightness, true);
      await tester.pump();
      c.sendspin.fullscreenActive.value = false;
      c.bus.publish(const SendspinNowPlayingChanged(active: false));
      await tester.pump();
      await tester.pump();
      expect(player, findsNothing);
      expect(brightness.last, 0.3);
      await tester.tapAt(tester.getRect(saver).center);
      await tester.pump();
      expect(brightness.last, 0.8);
      await tester.pumpWidget(const SizedBox());
      await c.screensaver.dispose();
    },
  );

  for (final (mode, level) in [('dim', 0.1), ('black', 0.0), ('clock', 0.15)]) {
    testWidgets(
      'shared override keeps normal brightness over $mode and scheduled dimming',
      (tester) async {
        await boot(
          tester,
          mode: mode,
          prefs: {
            'ks.sendspin.fullscreen_override_brightness': true,
            'ks.screensaver.dim_level': 0.1,
            if (mode == 'clock') ...{
              'ks.screensaver.schedule_enabled': true,
              'ks.screensaver.schedule':
                  '[{"at":"00:00","mode":"clock","brightness":0.15}]',
            },
          },
        );
        expect(c.screensaver.nowPlayingShared, isTrue);
        expect(brightness.last, 0.8);
        await c.settings.set(defs.sendspinFullscreenOverrideBrightness, false);
        await tester.pump();
        expect(brightness.last, level);
        await tester.tapAt(tester.getRect(saver).center);
        await tester.pump();
        expect(brightness.last, 0.8);
        await tester.pumpWidget(const SizedBox());
        await c.screensaver.dispose();
      },
    );
  }

  for (final (mode, level) in [('dim', 0.1), ('black', 0.0)]) {
    testWidgets('$mode keeps its brightness alongside the player', (
      tester,
    ) async {
      await boot(tester, mode: mode, prefs: {'ks.screensaver.dim_level': 0.1});
      expect(player, findsOneWidget);
      expect(saver, findsOneWidget);
      expect(brightness.last, level);
      await tester.tapAt(tester.getRect(saver).center);
      await tester.pump();
      expect(brightness.last, 0.8);
      await tester.pumpWidget(const SizedBox());
      await c.screensaver.dispose();
    });
  }
  for (final split in [false, true]) {
    for (final scheduled in <bool?>[null, false, true]) {
      testWidgets(
        'scheduled Now Playing $scheduled overrides global split $split',
        (tester) async {
          await boot(
            tester,
            split: split,
            prefs: {
              'ks.screensaver.schedule_enabled': true,
              'ks.screensaver.schedule': jsonEncode([
                {'at': '00:00', 'mode': 'clock', 'now_playing': ?scheduled},
              ]),
              'ks.sendspin.fullscreen_override_brightness': true,
              'ks.screensaver.brightness_enabled': true,
              'ks.screensaver.brightness_level': 0.2,
            },
          );
          if (scheduled == false) {
            expect(player, findsNothing);
            expect(tester.getSize(saver), const Size(1280, 800));
            expect(brightness.last, 0.2);
            await tester.tapAt(tester.getRect(saver).center);
            await tester.pump();
            expect(c.screensaver.isActive, isFalse);
          } else {
            expect(player, findsOneWidget);
            expect(saver, (scheduled ?? split) ? findsOneWidget : findsNothing);
            expect(brightness.last, 0.8);
          }
          await tester.pumpWidget(const SizedBox());
          await c.screensaver.dispose();
        },
      );
    }
  }

  testWidgets(
    'schedule changes hide Now Playing live and restore the global layout',
    (tester) async {
      await boot(tester, prefs: {'ks.screensaver.schedule_enabled': true});
      final clockState = tester.state(find.byType(ClockScreensaver));
      await c.settings.set(
        defs.screensaverSchedule,
        '[{"at":"00:00","mode":"clock","now_playing":false}]',
      );
      await tester.pump();
      await tester.pump();
      expect(player, findsNothing);
      expect(tester.state(find.byType(ClockScreensaver)), same(clockState));
      await c.settings.set(defs.screensaverScheduleEnabled, false);
      await tester.pump();
      await tester.pump();
      expect(player, findsOneWidget);
      expect(saver, findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await c.screensaver.dispose();
    },
  );

  testWidgets(
    'schedule boundaries update Now Playing with the same screensaver mode',
    (tester) async {
      var now = DateTime(2026, 9, 6, 11, 59, 50);
      await boot(
        tester,
        scheduleClock: () => now,
        prefs: {
          'ks.screensaver.schedule_enabled': true,
          'ks.screensaver.schedule':
              '[{"at":"00:00","mode":"clock","now_playing":true},'
              '{"at":"12:00","mode":"clock","now_playing":false}]',
        },
      );
      expect(player, findsOneWidget);
      final clockState = tester.state(find.byType(ClockScreensaver));
      now = DateTime(2026, 9, 6, 12, 0, 10);
      await tester.pump(const Duration(seconds: 20));
      await tester.pump();
      expect(player, findsNothing);
      expect(tester.state(find.byType(ClockScreensaver)), same(clockState));
      now = DateTime(2026, 9, 7, 0, 0, 10);
      await tester.pump(const Duration(seconds: 20));
      await tester.pump();
      expect(player, findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await c.screensaver.dispose();
    },
  );
}
