import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/kiosk_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fade in and out (screensaver.fade): which views fade, the backlight
/// waiting for the fade in, the wait for the dashboard before the fade
/// out, and the overlay's opacity through both.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ScreensaverManager saver;
  late List<double> brightness;
  late List<String> order;
  late Future<void> Function() dashboardFrame;

  Future<void> build([Map<String, Object> extra = const {}]) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
      'ks.screensaver.fade': true,
      ...extra,
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    brightness = [];
    order = [];
    dashboardFrame = () async {};
    commands
      ..register(
        Command(
          name: 'getBrightness',
          description: 'Read brightness',
          handler: (_) async => const CommandResult.ok(0.8),
        ),
      )
      ..register(
        Command(
          name: 'setBrightness',
          description: 'Record brightness',
          handler: (p) async {
            brightness.add((p['level'] as num).toDouble());
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'unfreezeRendering',
          description: 'Record the thaw',
          handler: (_) async {
            order.add('thaw');
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'awaitDashboardFrame',
          description: 'The page draws',
          handler: (_) async {
            order.add('frame asked');
            await dashboardFrame();
            return const CommandResult.ok();
          },
        ),
      );
    saver = ScreensaverManager(bus, commands, log, settings);
    await saver.init();
  }

  test('only the views Flutter draws fade, and only with the setting on', () {
    fakeAsync((async) {
      build();
      async.flushMicrotasks();
      for (final view in ['clock', 'black', 'immich', 'weather_mood']) {
        expect(saver.fadesView(view), isTrue, reason: view);
      }
      for (final view in ['media', 'website', 'camera', 'dashboard', null]) {
        expect(saver.fadesView(view), isFalse, reason: '$view');
      }
      build({'ks.screensaver.fade': false});
      async.flushMicrotasks();
      expect(saver.fadesView('clock'), isFalse);
    });
  });

  test('the fade ends before the browser pauses the dashboard', () {
    // BrowserManager._scheduleFreezeSync waits one second.
    expect(
      ScreensaverManager.fadeDuration,
      lessThan(const Duration(seconds: 1)),
    );
  });

  test('the backlight drops once the fade in is over', () {
    fakeAsync((async) {
      build({'ks.screensaver.mode': 'black'});
      async.flushMicrotasks();
      saver.start();
      async.flushMicrotasks();
      expect(saver.activeView.value, 'black');
      expect(brightness, isEmpty);
      async.elapse(ScreensaverManager.fadeDuration);
      expect(brightness, [0]);
    });
  });

  test('without the setting the backlight drops at once', () {
    fakeAsync((async) {
      build({'ks.screensaver.mode': 'black', 'ks.screensaver.fade': false});
      async.flushMicrotasks();
      saver.start();
      async.flushMicrotasks();
      expect(brightness, [0]);
    });
  });

  test('a dismissal inside the fade in never dims', () {
    fakeAsync((async) {
      build({'ks.screensaver.mode': 'black'});
      async.flushMicrotasks();
      saver.start();
      async.flushMicrotasks();
      saver.stop();
      async.elapse(const Duration(seconds: 1));
      expect(brightness.where((level) => level == 0), isEmpty);
    });
  });

  test('a dismissal asks the page for a frame after the thaw', () {
    fakeAsync((async) {
      build();
      async.flushMicrotasks();
      saver.start();
      async.flushMicrotasks();
      saver.stop();
      async.flushMicrotasks();
      expect(order, ['thaw', 'frame asked']);
      expect(saver.activeView.value, isNull);
      expect(saver.fadeOutAfter, isNotNull);
      async.elapse(const Duration(seconds: 1));
    });
  });

  test('a page that never draws holds the fade out 400 ms at most', () {
    fakeAsync((async) {
      build();
      async.flushMicrotasks();
      dashboardFrame = () => Future<void>.delayed(const Duration(minutes: 1));
      saver.start();
      async.flushMicrotasks();
      saver.stop();
      async.flushMicrotasks();
      var done = false;
      saver.fadeOutAfter!.whenComplete(() => done = true);
      async.elapse(const Duration(milliseconds: 399));
      expect(done, isFalse);
      async.elapse(const Duration(milliseconds: 2));
      expect(done, isTrue);
      async.elapse(const Duration(minutes: 1));
    });
  });

  test('a view that cannot fade leaves nothing to wait for', () {
    fakeAsync((async) {
      build({'ks.screensaver.mode': 'website'});
      async.flushMicrotasks();
      saver.start();
      async.flushMicrotasks();
      saver.stop();
      async.flushMicrotasks();
      expect(order, ['thaw']);
      expect(saver.fadeOutAfter, isNull);
    });
  });

  group('plugin screensavers fade through a picture of the screen', () {
    const mode = 'plugin:hello-world:dvd';

    test('the views that take it', () {
      fakeAsync((async) {
        build();
        async.flushMicrotasks();
        expect(saver.shotFades(mode), isTrue);
        expect(saver.opacityFades(mode), isFalse);
        expect(saver.fadesView(mode), isTrue);
        expect(saver.shotFades('clock'), isFalse);
        expect(saver.shotFades('website'), isFalse);
      });
    });

    testWidgets('a start hands the dashboard picture over and waits for '
        'the view, a dismissal hands over the screensaver', (tester) async {
      await tester.runAsync(() async {
        await build({'ks.screensaver.mode': mode});
        var reads = 0;
        saver.captureScreen = () {
          reads++;
          return createTestImage(width: 4, height: 4);
        };
        await saver.start();
        expect(saver.activeView.value, mode);
        expect(reads, 1);
        final shot = saver.fadeInShot;
        expect(shot, isNotNull);
        var drawn = false;
        unawaited(saver.fadeInAfter!.whenComplete(() => drawn = true));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(drawn, isFalse);
        saver.viewDrawn();
        await Future<void>.delayed(Duration.zero);
        expect(drawn, isTrue);

        await saver.stop();
        expect(reads, 2);
        expect(saver.fadeOutShot, isNotNull);
        expect(saver.fadeOutAfter, isNotNull);
        expect(order, ['thaw', 'frame asked']);
        // A start drops what the overlay never took.
        await saver.start();
        expect(saver.fadeOutShot, isNull);
        await saver.stop();
      });
    });

    testWidgets('no picture, no fade', (tester) async {
      await tester.runAsync(() async {
        await build({'ks.screensaver.mode': mode});
        saver.captureScreen = () async => null;
        await saver.start();
        expect(saver.fadeInShot, isNull);
        expect(saver.fadeInAfter, isNull);
        await saver.stop();
        expect(saver.fadeOutShot, isNull);
      });
    });

    testWidgets('the overlay holds the dashboard picture until the view '
        'draws, then fades it out', (tester) async {
      await tester.runAsync(() async {
        await build({'ks.screensaver.mode': mode});
        saver.captureScreen = () => createTestImage(width: 4, height: 4);
      });
      await tester.pumpWidget(
        MaterialApp(
          home: ScreensaverFade(
            screensaver: saver,
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.runAsync(saver.start);
      await tester.pump();
      final picture = find.byType(RawImage);
      expect(picture, findsOneWidget);
      double opacity() => tester
          .widget<FadeTransition>(
            find
                .ancestor(of: picture, matching: find.byType(FadeTransition))
                .first,
          )
          .opacity
          .value;
      await tester.pump(const Duration(milliseconds: 500));
      expect(opacity(), 1);
      saver.viewDrawn();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(), closeTo(0.5, 0.01));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.byType(RawImage), findsNothing);
      // The screensaver under the picture shows at full opacity.
      expect(
        tester
            .widget<FadeTransition>(
              find
                  .descendant(
                    of: find.byType(ScreensaverFade),
                    matching: find.byType(FadeTransition),
                  )
                  .first,
            )
            .opacity
            .value,
        1,
      );
      await tester.runAsync(saver.stop);
      await tester.pump();
    });
  });

  group('overlay', () {
    double opacityOf(WidgetTester tester, Finder child) => tester
        .widget<FadeTransition>(
          find.ancestor(of: child, matching: find.byType(FadeTransition)).first,
        )
        .opacity
        .value;

    Widget host() => MaterialApp(
      home: ScreensaverFade(
        screensaver: saver,
        child: ValueListenableBuilder<String?>(
          valueListenable: saver.activeView,
          builder: (context, view, _) => view == null
              ? const SizedBox.shrink()
              : const ColoredBox(key: Key('saver'), color: Colors.red),
        ),
      ),
    );

    testWidgets('fades in from clear and out over the last frame', (
      tester,
    ) async {
      await tester.runAsync(build);
      await tester.pumpWidget(host());
      final content = find.byKey(const Key('saver'));

      await tester.runAsync(saver.start);
      await tester.pump();
      expect(opacityOf(tester, content), 0);
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacityOf(tester, content), closeTo(0.5, 0.01));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 1));
      expect(opacityOf(tester, content), 1);

      await tester.runAsync(saver.stop);
      await tester.pump();
      // The live view is gone and its last frame stands in for it.
      expect(content, findsNothing);
      final last = find.byType(RawImage);
      expect(last, findsOneWidget);
      // Let the manager's wait for the page finish, then fade.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacityOf(tester, last), closeTo(0.5, 0.01));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 1));
      // The frame after the fade ends drops the picture.
      await tester.pump();
      expect(find.byType(RawImage), findsNothing);
    });

    testWidgets('a view that cannot fade cuts both ways', (tester) async {
      await tester.runAsync(() => build({'ks.screensaver.mode': 'website'}));
      await tester.pumpWidget(host());
      await tester.runAsync(saver.start);
      await tester.pump();
      expect(opacityOf(tester, find.byKey(const Key('saver'))), 1);
      await tester.runAsync(saver.stop);
      await tester.pump();
      expect(find.byType(RawImage), findsNothing);
      expect(find.byKey(const Key('saver')), findsNothing);
    });
  });
}
