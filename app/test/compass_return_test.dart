import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/managers/navigation/compass_layout.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/compass/compass_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Return to center waits while another app is in front: opening the center
// brought the kiosk back over an app opened from the Menu a minute after
// the last touch (issue #1453).
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  const menu = CompassSlot(CompassArm.left);

  Future<(AppContainer, CompassController)> setUpCompass() async {
    SharedPreferences.setMockInitialValues({});
    final c = AppContainer();
    await c.settings.init();
    c.device.appVersion = 'test';
    void stand(String name, ValueNotifier<bool> page, bool up) {
      c.commands.register(
        Command(
          name: name,
          description: name,
          handler: (_) async {
            page.value = up;
            return const CommandResult.ok();
          },
        ),
      );
    }

    stand('openAlarms', c.alarms.visible, true);
    stand('hideAlarms', c.alarms.visible, false);
    await c.settings.setFromJson(
      defs.navCompassLayout.key,
      jsonEncode({
        'center': {'kind': 'alarms'},
        'left': [
          {'kind': 'menu'},
        ],
      }),
    );
    await c.settings.setFromJson(defs.navCompassReturnMinutes.key, 1);
    await c.settings.setFromJson(defs.navStyle.key, 'compass');
    final compass = CompassController(c)..start();
    addTearDown(() async {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      compass.dispose();
      await c.settings.dispose();
      await c.bus.dispose();
      await c.log.dispose();
    });
    return (c, compass);
  }

  test('goes to the center a minute after the last touch', () async {
    final (c, compass) = await setUpCompass();
    compass.behindAnotherApp = () async => false;
    fakeAsync((async) {
      compass.show(menu);
      async.flushMicrotasks();
      expect(compass.menuVisible.value, isTrue);

      async.elapse(const Duration(seconds: 59));
      expect(compass.current.value, menu);
      async.elapse(const Duration(seconds: 2));
      expect(compass.current.value, CompassSlot.center);
      expect(c.alarms.visible.value, isTrue);
      expect(compass.menuVisible.value, isFalse);
    });
  });

  test('stays on the view while another app is in front', () async {
    final (c, compass) = await setUpCompass();
    var away = true;
    compass.behindAnotherApp = () async => away;
    fakeAsync((async) {
      compass.show(menu);
      async.flushMicrotasks();

      // An app opened from the Menu: the kiosk stops behind it.
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      async.elapse(const Duration(minutes: 3));
      expect(compass.current.value, menu);
      expect(c.alarms.visible.value, isFalse);

      // Return after brings the kiosk back: the countdown starts there.
      away = false;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      async.elapse(const Duration(seconds: 59));
      expect(compass.current.value, menu);
      async.elapse(const Duration(seconds: 2));
      expect(compass.current.value, CompassSlot.center);
      expect(c.alarms.visible.value, isTrue);
    });
  });

  test('time spent in another app does not count', () async {
    final (_, compass) = await setUpCompass();
    compass.behindAnotherApp = () async => false;
    fakeAsync((async) {
      compass.show(menu);
      async.flushMicrotasks();

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      async.elapse(const Duration(seconds: 40));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      // A minute from the last touch, but only 30 seconds back on screen.
      async.elapse(const Duration(seconds: 30));
      expect(compass.current.value, menu);
      async.elapse(const Duration(seconds: 31));
      expect(compass.current.value, CompassSlot.center);
    });
  });

  // Now Playing that takes the screensaver's place is the screensaver.
  // With the view in the layout, Return to center closed it a minute
  // later, and it came back after the screensaver's idle time, over and
  // over (issue #1557).
  group('Now Playing', () {
    const side = CompassSlot(CompassArm.right);

    // Everything is built inside the fake clock: the screensaver hears of
    // the music over the bus, which delivers in the zone it was built in.
    void withNowPlaying(
      void Function(
        FakeAsync async,
        AppContainer c,
        CompassController compass,
        List<String> hides,
      )
      body,
    ) {
      fakeAsync((async) {
        SharedPreferences.setMockInitialValues({
          'ks.ha.url': '',
          'ks.ha.token': '',
          'ks.screensaver.mode': 'clock',
          'ks.sendspin.fullscreen': true,
          'ks.sendspin.fullscreen_on_play': false,
        });
        final c = AppContainer();
        c.device.appVersion = 'test';
        final hides = <String>[];
        c.commands
          ..register(
            Command(
              name: 'openAlarms',
              description: 'stub',
              handler: (_) async {
                c.alarms.visible.value = true;
                return const CommandResult.ok();
              },
            ),
          )
          ..register(
            Command(
              name: 'hideAlarms',
              description: 'stub',
              handler: (_) async {
                c.alarms.visible.value = false;
                return const CommandResult.ok();
              },
            ),
          )
          ..register(
            Command(
              name: 'hideNowPlaying',
              description: 'stub',
              handler: (_) async {
                hides.add('hideNowPlaying');
                await c.screensaver.stop();
                return const CommandResult.ok();
              },
            ),
          );
        late CompassController compass;
        () async {
          await c.settings.init();
          await c.screensaver.init();
          await c.settings.setFromJson(
            defs.navCompassLayout.key,
            jsonEncode({
              'center': {'kind': 'alarms'},
              'right': [
                {'kind': 'now_playing'},
              ],
            }),
          );
          await c.settings.setFromJson(defs.navCompassReturnMinutes.key, 1);
          await c.settings.setFromJson(defs.navStyle.key, 'compass');
          compass = CompassController(c)..start();
          compass.behindAnotherApp = () async => false;
        }();
        async.flushMicrotasks();
        // The center opens a second after the start.
        async.elapse(const Duration(seconds: 2));
        expect(c.alarms.visible.value, isTrue);

        body(async, c, compass, hides);

        compass.dispose();
        c.screensaver.dispose();
        c.settings.dispose();
        c.bus.dispose();
        c.log.dispose();
        async.flushMicrotasks();
      });
    }

    test('in the screensaver\'s place stays up', () {
      withNowPlaying((async, c, compass, hides) {
        // Music plays and the idle clock starts the screensaver.
        c.bus.publish(
          const SendspinNowPlayingChanged(active: true, playing: true),
        );
        async.flushMicrotasks();
        c.screensaver.start();
        async.elapse(const Duration(seconds: 1));
        expect(c.screensaver.nowPlayingShown, isTrue);
        expect(compass.current.value, side);

        async.elapse(const Duration(minutes: 3));
        expect(hides, isEmpty);
        expect(c.screensaver.nowPlayingShown, isTrue);
      });
    });

    test('opened by hand goes back to the center', () {
      withNowPlaying((async, c, compass, hides) {
        c.bus.publish(
          const SendspinNowPlayingChanged(active: true, playing: true),
        );
        async.flushMicrotasks();
        // What the swipe, the Menu and the floating player run.
        c.screensaver.start(forNowPlaying: true, byHand: true);
        async.flushMicrotasks();
        compass.show(side);
        async.elapse(const Duration(seconds: 1));
        expect(c.screensaver.nowPlayingShown, isTrue);
        expect(compass.current.value, side);

        async.elapse(const Duration(seconds: 61));
        expect(hides, ['hideNowPlaying']);
        expect(compass.current.value, CompassSlot.center);
        expect(c.alarms.visible.value, isTrue);
      });
    });
  });
}
