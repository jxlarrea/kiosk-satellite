import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/managers/navigation/compass_layout.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/compass/compass_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enable timers off with the Timers view in the Compass layout (issue
/// #1508). The view refuses to open then: a Timers center gives way to
/// the dashboard instead of being asked for every second and a half, and a
/// Timers side on screen goes back to the center.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const right = CompassSlot(CompassArm.right);

  // Real time: the container's bus lives outside any fake clock, and
  // Compass checks a view 1.5 seconds after it asked for it.
  Future<void> wait(int seconds) =>
      Future<void>.delayed(Duration(seconds: seconds));

  Future<(AppContainer, CompassController, List<String>)> setUpCompass(
    Map<String, Object?> layout,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final c = AppContainer();
    await c.settings.init();
    c.device.appVersion = 'test';
    await c.voiceTimers.init();
    final opened = <String>[];
    c.log.stream.listen((e) {
      if (e.tag == 'command' && e.message.startsWith('openTimers')) {
        opened.add(e.message);
      }
    });
    c.commands.register(
      Command(
        name: 'openAlarms',
        description: 'openAlarms',
        handler: (_) async {
          c.alarms.visible.value = true;
          return const CommandResult.ok();
        },
      ),
    );
    c.commands.register(
      Command(
        name: 'hideAlarms',
        description: 'hideAlarms',
        handler: (_) async {
          c.alarms.visible.value = false;
          return const CommandResult.ok();
        },
      ),
    );
    await c.settings.setFromJson(defs.navCompassLayout.key, jsonEncode(layout));
    await c.settings.setFromJson(defs.navStyle.key, 'compass');
    final compass = CompassController(c)..start();
    addTearDown(() async {
      compass.dispose();
      await c.voiceTimers.dispose();
      await c.settings.dispose();
      await c.bus.dispose();
      await c.log.dispose();
    });
    return (c, compass, opened);
  }

  test('a Timers center gives way to the dashboard and comes back', () async {
    final (c, compass, opened) = await setUpCompass({
      'center': {'kind': 'timers'},
      'left': [
        {'kind': 'menu'},
      ],
    });
    {
      unawaited(compass.goCenter());
      await wait(2);
      expect(compass.currentView.kind, 'timers');
      expect(c.voiceTimers.visible.value, isTrue);

      await c.settings.set(defs.timersEnabled, false);
      await wait(2);
      expect(compass.current.value, CompassSlot.center);
      expect(compass.currentView.isDashboard, isTrue);
      expect(c.voiceTimers.visible.value, isFalse);
      // Nothing keeps asking for the view.
      opened.clear();
      await wait(5);
      expect(opened, isEmpty);

      await c.settings.set(defs.timersEnabled, true);
      await wait(2);
      expect(compass.currentView.kind, 'timers');
      expect(c.voiceTimers.visible.value, isTrue);
    }
  });

  test('a Timers side on screen goes back to the center', () async {
    final (c, compass, opened) = await setUpCompass({
      'center': {'kind': 'alarms'},
      'right': [
        {'kind': 'timers'},
      ],
      'left': [
        {'kind': 'menu'},
      ],
    });
    {
      unawaited(compass.show(right));
      await wait(2);
      expect(c.voiceTimers.visible.value, isTrue);

      await c.settings.set(defs.timersEnabled, false);
      await wait(2);
      expect(compass.current.value, CompassSlot.center);
      expect(c.alarms.visible.value, isTrue);
      expect(c.voiceTimers.visible.value, isFalse);
      // A swipe skips it.
      expect(compass.available(compass.layout.viewAt(right)!), isFalse);
      opened.clear();
      await wait(5);
      expect(opened, isEmpty);
    }
  });
}
