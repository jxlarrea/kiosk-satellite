import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/home_assistant/home_assistant_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hold mode (issue #266): the ha.hold_mode setting pins the current view.
/// The screensaver half (no start, dismiss on engage) runs against a real
/// ScreensaverManager; the HomeAssistantManager half covers the
/// behind-the-cover return gate and the auto-release clock, with one
/// "minute" shrunk to 10ms via the injectable unit.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('screensaver under hold', () {
    late EventBus bus;
    late SettingsManager settings;
    late ScreensaverManager saver;

    Future<void> build(Map<String, Object> initial) async {
      SharedPreferences.setMockInitialValues(initial);
      bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      saver = ScreensaverManager(bus, commands, log, settings);
      await saver.init();
    }

    test('hold refuses every start, commanded ones included', () async {
      await build({
        'ks.screensaver.enabled': true,
        'ks.screensaver.mode': 'black',
        'ks.ha.hold_mode': true,
      });
      await saver.start();
      expect(
        saver.isActive,
        isFalse,
        reason: '"keep this view on screen" beats a commanded start',
      );
    });

    test('engaging hold dismisses a showing screensaver', () async {
      await build({
        'ks.screensaver.enabled': true,
        'ks.screensaver.mode': 'black',
      });
      await saver.start();
      expect(saver.isActive, isTrue);
      await settings.set(defs.haHoldMode, true);
      await pumpEventQueue();
      expect(
        saver.isActive,
        isFalse,
        reason: 'a showing screensaver is never the view being pinned',
      );
    });

    test('releasing the hold lets the screensaver start again', () async {
      await build({
        'ks.screensaver.enabled': true,
        'ks.screensaver.mode': 'black',
        'ks.ha.hold_mode': true,
      });
      await settings.set(defs.haHoldMode, false);
      await pumpEventQueue();
      await saver.start();
      expect(saver.isActive, isTrue);
    });
  });

  group('home assistant manager under hold', () {
    late EventBus bus;
    late SettingsManager settings;
    late List<String> evalCalls;

    Future<void> build(Map<String, Object> initial) async {
      SharedPreferences.setMockInitialValues({
        'ks.ha.url': 'http://ha.test:8123',
        'ks.ha.token': 'token',
        'ks.browser.start_url': 'http://ha.test:8123/lovelace/home',
        ...initial,
      });
      bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      evalCalls = [];
      commands.register(
        Command(
          name: 'evalJs',
          description: 'stub',
          handler: (p) async {
            evalCalls.add('${p['code']}');
            return const CommandResult.ok('navigated');
          },
        ),
      );
      final ha = HomeAssistantManager(
        bus,
        commands,
        log,
        settings,
        holdReleaseUnit: const Duration(milliseconds: 10),
      );
      await ha.init();
    }

    test('no behind-the-cover return while hold is on', () async {
      await build({'ks.ha.return_home_enabled': true, 'ks.ha.hold_mode': true});
      bus.publish(const ScreensaverStateChanged(active: true));
      await pumpEventQueue();
      expect(
        evalCalls,
        isEmpty,
        reason: 'the pinned view must survive a screensaver edge too',
      );
    });

    test('the auto-release clock turns hold off by itself', () async {
      await build({'ks.ha.hold_release_minutes': 15});
      await settings.set(defs.haHoldMode, true);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(settings.get(defs.haHoldMode), isFalse);
    });

    test('at 0 (the default) the hold never releases itself', () async {
      await build({});
      await settings.set(defs.haHoldMode, true);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(settings.get(defs.haHoldMode), isTrue);
    });

    test('a hold that survived a restart still gets its clock', () async {
      // The setting persists on purpose; init itself must arm the release.
      await build({'ks.ha.hold_mode': true, 'ks.ha.hold_release_minutes': 15});
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(settings.get(defs.haHoldMode), isFalse);
    });

    test('moving the slider mid-hold restarts the countdown', () async {
      await build({});
      await settings.set(defs.haHoldMode, true);
      await settings.set(defs.haHoldReleaseMinutes, 15);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(settings.get(defs.haHoldMode), isFalse);
    });
  });
}
