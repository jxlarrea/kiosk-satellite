import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/managers/navigation/compass_layout.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/voice_timers/voice_timer_manager.dart';
import 'package:kiosk_satellite/ui/compass/compass_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Return to center with the Timers view on a side of the Compass layout.
// A view that opened by itself, for a timer that started or finished or
// from Home Assistant, never went back to the center: the countdown only
// started on a touch (issue #1575).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const right = CompassSlot(CompassArm.right);

  VoiceTimer timer(String id, {bool finished = false}) => VoiceTimer(
    id: id,
    name: id,
    totalSeconds: finished ? 0 : 600,
    startedAt: 0,
    active: !finished,
    finished: finished,
  );

  void withCompass(
    void Function(FakeAsync async, AppContainer c, CompassController compass)
    body,
  ) {
    fakeAsync((async) {
      SharedPreferences.setMockInitialValues({});
      final c = AppContainer();
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
      stand('openTimers', c.voiceTimers.visible, true);
      stand('hideTimers', c.voiceTimers.visible, false);
      late CompassController compass;
      () async {
        await c.settings.init();
        await c.settings.setFromJson(
          defs.navCompassLayout.key,
          jsonEncode({
            'center': {'kind': 'alarms'},
            'right': [
              {'kind': 'timers'},
            ],
          }),
        );
        await c.settings.setFromJson(defs.navCompassReturnMinutes.key, 1);
        await c.settings.setFromJson(defs.navStyle.key, 'compass');
        compass = CompassController(c)..start();
        compass.behindAnotherApp = () async => false;
      }();
      async.flushMicrotasks();
      // The center opens a second after the start. The last touch is long
      // gone by the time anything below happens.
      async.elapse(const Duration(minutes: 5));
      expect(c.alarms.visible.value, isTrue);
      expect(compass.current.value, CompassSlot.center);

      body(async, c, compass);

      compass.dispose();
      c.settings.dispose();
      c.bus.dispose();
      c.log.dispose();
      async.flushMicrotasks();
    });
  }

  // The view comes up on its own, the way VoiceTimerManager opens it.
  void timerOpensView(AppContainer c, List<VoiceTimer> timers) {
    c.voiceTimers.timers.value = timers;
    c.voiceTimers.visible.value = true;
  }

  void expectBackAfterAMinute(
    FakeAsync async,
    AppContainer c,
    CompassController compass,
  ) {
    async.elapse(const Duration(seconds: 59));
    expect(compass.current.value, right);
    expect(c.voiceTimers.visible.value, isTrue);
    async.elapse(const Duration(seconds: 2));
    expect(compass.current.value, CompassSlot.center);
    expect(c.voiceTimers.visible.value, isFalse);
    expect(c.alarms.visible.value, isTrue);
  }

  test('a view opened by a timer starting goes back', () {
    withCompass((async, c, compass) {
      timerOpensView(c, [timer('pasta')]);
      async.elapse(const Duration(seconds: 1));
      expect(compass.current.value, right);
      expectBackAfterAMinute(async, c, compass);
    });
  });

  test('a view opened by Home Assistant goes back', () {
    withCompass((async, c, compass) {
      // ks://timers, ESPHome or a gesture, with nobody at the screen.
      c.commands.execute('openTimers', const {});
      async.elapse(const Duration(seconds: 1));
      expect(compass.current.value, right);
      expectBackAfterAMinute(async, c, compass);
    });
  });

  test('a timer cancelled on the view counts from the cancel', () {
    withCompass((async, c, compass) {
      timerOpensView(c, [timer('pasta')]);
      async.elapse(const Duration(seconds: 50));
      // Cancelled by voice, or by another kiosk sharing it.
      c.voiceTimers.timers.value = const [];
      expectBackAfterAMinute(async, c, compass);
    });
  });

  test('a timer started on the view counts from the start', () {
    withCompass((async, c, compass) {
      compass.show(right);
      async.elapse(const Duration(seconds: 1));
      expect(compass.current.value, right);
      async.elapse(const Duration(seconds: 50));
      // Started from the remote admin or shared by another kiosk.
      c.voiceTimers.timers.value = [timer('tea')];
      expectBackAfterAMinute(async, c, compass);
    });
  });

  test('the shared heartbeat does not hold the view up', () {
    withCompass((async, c, compass) {
      timerOpensView(c, [timer('pasta')]);
      async.elapse(const Duration(seconds: 30));
      // The same timers, sent again.
      c.voiceTimers.timers.value = [timer('pasta')];
      async.elapse(const Duration(seconds: 31));
      expect(compass.current.value, CompassSlot.center);
    });
  });

  test('a finished timer keeps the view while it rings', () {
    withCompass((async, c, compass) {
      c.voiceTimers.alerts.value = [timer('pasta', finished: true)];
      c.voiceTimers.visible.value = true;
      async.elapse(const Duration(seconds: 1));
      expect(compass.current.value, right);
      async.elapse(const Duration(minutes: 3));
      expect(compass.current.value, right);
      expect(c.voiceTimers.visible.value, isTrue);

      // Dismissed by voice or by Dismiss after: back a minute later.
      c.voiceTimers.alerts.value = const [];
      expectBackAfterAMinute(async, c, compass);
    });
  });

  test('a hidden alert does not hold the view', () {
    withCompass((async, c, compass) {
      c.voiceTimers.alertHidden.value = true;
      c.voiceTimers.alerts.value = [timer('pasta', finished: true)];
      c.voiceTimers.timers.value = [timer('tea')];
      c.voiceTimers.visible.value = true;
      async.elapse(const Duration(seconds: 1));
      expect(compass.current.value, right);
      expectBackAfterAMinute(async, c, compass);
    });
  });

  test('a touch still restarts the countdown', () {
    withCompass((async, c, compass) {
      timerOpensView(c, [timer('pasta')]);
      async.elapse(const Duration(seconds: 40));
      c.bus.publish(const ActivityDetected(source: 'touch'));
      expectBackAfterAMinute(async, c, compass);
    });
  });
}
