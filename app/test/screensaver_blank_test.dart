import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EventBus bus;
  late SettingsManager settings;
  late ScreensaverManager saver;
  late List<double> brightness;
  late List<String> power;

  Future<void> build([Map<String, Object> extra = const {}]) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
      'ks.screensaver.screen_off_minutes': 1,
      'ks.screensaver.screen_off_black': true,
      ...extra,
    });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    brightness = [];
    power = [];
    commands.register(
      Command(
        name: 'getBrightness',
        description: 'Read brightness',
        handler: (_) async => const CommandResult.ok(0.8),
      ),
    );
    commands.register(
      Command(
        name: 'setBrightness',
        description: 'Record brightness',
        handler: (p) async {
          brightness.add((p['level'] as num).toDouble());
          return const CommandResult.ok();
        },
      ),
    );
    for (final name in ['screenOff', 'screenOn']) {
      commands.register(
        Command(
          name: name,
          description: 'Record power changes',
          handler: (_) async {
            power.add(name);
            return const CommandResult.ok();
          },
        ),
      );
    }
    saver = ScreensaverManager(bus, commands, log, settings);
    await saver.init();
    await saver.start();
  }

  test(
    'blanking saves brightness without powering off and touch restores it',
    () {
      fakeAsync((async) {
        build();
        async.flushMicrotasks();
        expect(saver.activeView.value, 'clock');
        async.elapse(const Duration(minutes: 1));
        expect(saver.activeView.value, 'blank');
        expect(brightness.last, 0);
        expect(power, isEmpty);
        expect(saver.isActive, isTrue);
        saver.notifyActivity('touch');
        async.flushMicrotasks();
        expect(saver.activeView.value, isNull);
        expect(brightness.last, 0.8);
        expect(settings.get(defs.screensaverMode), 'clock');
        saver.dispose();
      });
    },
  );

  // Touch under Wake to screensaver (issue #954): the first touch on the
  // black screen brings the screensaver back, its lift is not a second
  // touch, and the next touch opens the dashboard.
  test('touch picked brings the screensaver back over the black screen', () {
    fakeAsync((async) {
      final start = DateTime(2026, 10, 11, 12);
      build({'ks.screensaver.screen_off_wake_to_screensaver': '["touch"]'});
      async.flushMicrotasks();
      saver.clock = () => start.add(async.elapsed);
      async.elapse(const Duration(minutes: 1));
      expect(saver.activeView.value, 'blank');

      saver.notifyActivity('touch');
      async.flushMicrotasks();
      expect(saver.isActive, isTrue);
      expect(saver.activeView.value, 'clock');
      expect(brightness.last, 0.8);

      // The waking finger lifts, and a second finger of the same gesture
      // lands right behind it.
      async.elapse(const Duration(milliseconds: 50));
      saver.notifyActivity('touch');
      async.elapse(const Duration(milliseconds: 100));
      saver.notifyActivity('tap');
      saver.notifyActivity('touch_page');
      async.flushMicrotasks();
      expect(saver.isActive, isTrue);
      expect(saver.activeView.value, 'clock');

      // The countdown starts over from the wake.
      async.elapse(const Duration(seconds: 60));
      expect(saver.activeView.value, 'blank');
      saver.notifyActivity('touch');
      async.flushMicrotasks();
      expect(saver.activeView.value, 'clock');

      // A second touch opens the dashboard.
      async.elapse(const Duration(seconds: 2));
      saver.notifyActivity('touch');
      async.flushMicrotasks();
      expect(saver.isActive, isFalse);
      saver.dispose();
    });
  });

  // The same beside Now Playing (issue #1446), where the screensaver's
  // pane reports each finger ahead of the kiosk screen.
  test('touch wakes a black screen beside Now Playing the same way', () {
    fakeAsync((async) {
      final start = DateTime(2026, 11, 14, 12);
      build({
        'ks.screensaver.screen_off_wake_to_screensaver': '["touch"]',
        'ks.sendspin.fullscreen': true,
        'ks.sendspin.fullscreen_split': true,
      });
      async.flushMicrotasks();
      saver.clock = () => start.add(async.elapsed);
      bus.publish(const SendspinNowPlayingChanged(active: true, playing: true));
      async.flushMicrotasks();
      saver.setNowPlayingShared(true);
      async.flushMicrotasks();
      expect(saver.nowPlayingShared, isTrue);
      async.elapse(const Duration(minutes: 1));
      expect(saver.activeView.value, 'blank');

      // Blanked, the view has no pane to report from: the kiosk screen
      // hears the waking finger alone.
      saver.notifyActivity('touch');
      async.elapse(const Duration(milliseconds: 100));
      saver.notifyActivity('tap');
      async.flushMicrotasks();
      expect(saver.isActive, isTrue);
      expect(saver.activeView.value, 'clock');
      // The layout comes back and reports itself again.
      saver.setNowPlayingShared(true);
      async.flushMicrotasks();
      expect(saver.nowPlayingShared, isTrue);

      // A second touch opens the dashboard.
      async.elapse(const Duration(seconds: 2));
      saver.notifyActivity('pane_touch');
      saver.notifyActivity('touch');
      async.flushMicrotasks();
      expect(saver.isActive, isFalse);
      saver.dispose();
    });
  });

  test('the old switch on still lets touch open the dashboard', () {
    fakeAsync((async) {
      build({'ks.screensaver.screen_off_wake_to_screensaver': true});
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 1));
      expect(saver.activeView.value, 'blank');
      saver.notifyActivity('touch');
      async.flushMicrotasks();
      expect(saver.isActive, isFalse);
      saver.dispose();
    });
  });

  test(
    'notifications, music and brightness changes leave the screen blank',
    () {
      fakeAsync((async) {
        build({'ks.sendspin.fullscreen': true});
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 1));
        bus.publish(const NotificationsChanged(count: 1));
        bus.publish(
          const SendspinNowPlayingChanged(active: true, playing: true),
        );
        settings.set(defs.screensaverBrightnessEnabled, true);
        settings.set(defs.screensaverBrightnessLevel, 0.5);
        async.flushMicrotasks();
        expect(saver.activeView.value, 'blank');
        expect(brightness.every((level) => level == 0), isTrue);
        expect(saver.nowPlayingShowing, isFalse);
        expect(power, isEmpty);
        saver.notifyActivity('touch');
        async.flushMicrotasks();
        expect(saver.isActive, isFalse);
        expect(brightness.last, 0.8);
        saver.dispose();
      });
    },
  );

  for (final (kind, event) in [
    ('motion', const MotionDetected()),
    ('face', const FaceDetected()),
    ('proximity', const ProximityDetected()),
    ('person', const PersonDetected()),
  ]) {
    for (final wakeToSaver in [false, true]) {
      test('$kind wakes blank screen, wake to screensaver $wakeToSaver', () {
        fakeAsync((async) {
          build({
            'ks.screensaver.dismiss_on_$kind': true,
            'ks.screensaver.dismiss_on_${kind}_screen_off_only': true,
            'ks.screensaver.screen_off_wake_to_screensaver': wakeToSaver,
          });
          async.flushMicrotasks();
          bus.publish(event);
          async.flushMicrotasks();
          expect(saver.activeView.value, 'clock');
          async.elapse(const Duration(minutes: 1));
          expect(saver.activeView.value, 'blank');
          bus.publish(event);
          async.flushMicrotasks();
          expect(saver.isActive, wakeToSaver);
          expect(saver.activeView.value, wakeToSaver ? 'clock' : null);
          expect(brightness.last, 0.8);
          if (wakeToSaver) {
            async.elapse(const Duration(minutes: 1));
            expect(saver.activeView.value, 'blank');
            expect(power, isEmpty);
          }
          saver.dispose();
        });
      });
    }
  }

  test('toggle is hidden at zero and retained for schedule overrides', () {
    fakeAsync((async) {
      build({
        'ks.screensaver.screen_off_minutes': 0,
        'ks.screensaver.schedule_enabled': true,
        'ks.screensaver.schedule':
            '[{"at":"00:00","mode":"clock","screen_off":2}]',
      });
      async.flushMicrotasks();
      expect(settings.visible(defs.screensaverScreenOffBlack), isFalse);
      async.elapse(const Duration(minutes: 1));
      expect(saver.activeView.value, 'clock');
      async.elapse(const Duration(minutes: 1));
      expect(saver.activeView.value, 'blank');
      expect(power, isEmpty);
      settings.set(defs.screensaverScreenOffMinutes, 3);
      async.flushMicrotasks();
      expect(settings.visible(defs.screensaverScreenOffBlack), isTrue);
      settings.set(defs.screensaverScreenOffBlack, false);
      async.flushMicrotasks();
      expect(saver.activeView.value, 'clock');
      expect(brightness.last, 0.8);
      async.elapse(const Duration(minutes: 2));
      expect(power, ['screenOff']);
      saver.dispose();
    });
  });

  test(
    'schedule changes stay blank and wake restores the current brightness',
    () {
      fakeAsync((async) {
        build({
          'ks.screensaver.brightness_enabled': true,
          'ks.screensaver.brightness_level': 0.2,
          'ks.screensaver.dismiss_on_motion': true,
          'ks.screensaver.screen_off_wake_to_screensaver': true,
        });
        async.flushMicrotasks();
        expect(brightness.last, 0.2);
        async.elapse(const Duration(minutes: 1));
        settings.set(
          defs.screensaverSchedule,
          '[{"at":"00:00","mode":"clock","brightness":0.4,"screen_off":2}]',
        );
        settings.set(defs.screensaverScheduleEnabled, true);
        async.flushMicrotasks();
        expect(saver.activeView.value, 'blank');
        expect(brightness.last, 0);
        bus.publish(const MotionDetected());
        async.flushMicrotasks();
        expect(saver.activeView.value, 'clock');
        expect(brightness.last, 0.4);
        saver.notifyActivity('touch');
        async.flushMicrotasks();
        expect(brightness.last, 0.8);
        saver.dispose();
      });
    },
  );

  testWidgets('blank cover hides the normal screensaver and accepts a tap', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.mode': 'black',
      'ks.screensaver.widgets_enabled': true,
      'ks.screensaver.glance_enabled': true,
      'ks.sendspin.fullscreen': true,
    });
    final container = AppContainer();
    await container.settings.init();
    await container.screensaver.start();
    container.screensaver.activeView.value = 'blank';
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            const Text('A notification'),
            ScreensaverOverlay(container: container),
            ScreensaverBlankOverlay(container: container),
          ],
        ),
      ),
    );
    final cover = find.descendant(
      of: find.byType(ScreensaverBlankOverlay),
      matching: find.byType(ColoredBox),
    );
    expect(cover, findsOneWidget);
    final box = tester.widget<ColoredBox>(cover);
    expect(box.color, Colors.black);
    expect(box.child, isNull);
    expect(tester.getSize(cover), const Size(800, 600));
    expect(find.text('A notification').hitTestable(), findsNothing);
    await tester.tapAt(const Offset(400, 300));
    await tester.pump();
    expect(container.screensaver.isActive, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await container.screensaver.dispose();
  });
}
