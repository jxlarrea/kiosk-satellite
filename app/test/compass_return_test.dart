import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
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
}
