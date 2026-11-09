import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/kiosk/kiosk_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lockdown Mode (discussion #143): one remote-only toggle that makes the
/// screen untouchable without touching the persisted kiosk settings. The
/// shield itself is UI; what is testable headless is the derivations: the
/// exit gesture tap count, the screensaver's refusal to run under
/// lockdown, and the setting's registration.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('exit gesture tap counts', () {
    test('each variant maps to its count; none disables', () {
      expect(KioskManager.gestureTapCount('taps5'), 5);
      expect(KioskManager.gestureTapCount('taps7'), 7);
      expect(KioskManager.gestureTapCount('taps5hold'), 5);
      expect(KioskManager.gestureTapCount('taps7hold'), 7);
      expect(KioskManager.gestureTapCount('none'), 0);
    });
  });

  group('setting registration', () {
    test('lockdown.enabled is declared, off by default, own category', () {
      expect(defs.allSettings, contains(defs.lockdownEnabled));
      expect(defs.lockdownEnabled.defaultValue, false);
      expect(defs.lockdownEnabled.category, 'Lockdown');
      expect(defs.lockdownEnabled.hidden, false);
    });

    test('lockdown.blackout is declared, off by default, gates on the '
        'toggle', () {
      expect(defs.allSettings, contains(defs.lockdownBlackout));
      expect(defs.lockdownBlackout.defaultValue, false);
      expect(defs.lockdownBlackout.dependsOn, defs.lockdownEnabled.key);
    });

    test('lockdown.allow_screensaver is declared, off by default, gates '
        'on the toggle', () {
      expect(defs.allSettings, contains(defs.lockdownAllowScreensaver));
      expect(defs.lockdownAllowScreensaver.defaultValue, false);
      expect(defs.lockdownAllowScreensaver.dependsOn, defs.lockdownEnabled.key);
    });

    test('lockdown.exit_gesture mirrors the kiosk options and gates on '
        'the toggle', () {
      expect(defs.allSettings, contains(defs.lockdownExitGesture));
      expect(defs.lockdownExitGesture.options, defs.kioskExitGesture.options);
      expect(defs.lockdownExitGesture.dependsOn, defs.lockdownEnabled.key);
    });
  });

  group('unlock automatically after (issue #1367)', () {
    late SettingsManager settings;
    late KioskManager kiosk;
    KioskManager? built;

    test('the setting is a 0 to 10 minute slider, off by default and not '
        'gated on the toggle', () {
      expect(defs.allSettings, contains(defs.lockdownAutoUnlockMinutes));
      expect(defs.lockdownAutoUnlockMinutes.defaultValue, 0);
      expect(defs.lockdownAutoUnlockMinutes.min, 0);
      expect(defs.lockdownAutoUnlockMinutes.max, 10);
      expect(defs.lockdownAutoUnlockMinutes.step, 1);
      expect(defs.lockdownAutoUnlockMinutes.dependsOn, isNull);
    });

    Future<void> build(Map<String, Object> initial) async {
      SharedPreferences.setMockInitialValues(initial);
      final bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      commands.register(
        Command(
          name: 'bringToFront',
          description: 'test stub',
          handler: (_) async => const CommandResult.ok(true),
        ),
      );
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      kiosk = KioskManager(bus, commands, log, settings);
      await kiosk.init();
      built = kiosk;
    }

    tearDown(() async {
      await built?.dispose();
      built = null;
    });

    test('a menu lock lifts after the set minutes', () async {
      await build({'ks.lockdown.auto_unlock_minutes': 2});
      fakeAsync((async) {
        kiosk.lockFromMenu();
        async.flushMicrotasks();
        expect(settings.get(defs.lockdownEnabled), isTrue);
        async.elapse(const Duration(minutes: 1, seconds: 59));
        expect(settings.get(defs.lockdownEnabled), isTrue);
        async.elapse(const Duration(seconds: 2));
        expect(settings.get(defs.lockdownEnabled), isFalse);
      });
    });

    test('0 keeps a menu lock on', () async {
      await build({});
      fakeAsync((async) {
        kiosk.lockFromMenu();
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 30));
        expect(settings.get(defs.lockdownEnabled), isTrue);
      });
    });

    test('a lock from the setting itself never times out', () async {
      await build({'ks.lockdown.auto_unlock_minutes': 1});
      fakeAsync((async) {
        settings.set(defs.lockdownEnabled, true);
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 5));
        expect(settings.get(defs.lockdownEnabled), isTrue);
      });
    });

    test(
      'an early unlock cancels the timer, so a later remote lock holds',
      () async {
        await build({'ks.lockdown.auto_unlock_minutes': 2});
        fakeAsync((async) {
          kiosk.lockFromMenu();
          async.flushMicrotasks();
          async.elapse(const Duration(minutes: 1));
          settings.set(defs.lockdownEnabled, false);
          async.flushMicrotasks();
          settings.set(defs.lockdownEnabled, true);
          async.flushMicrotasks();
          async.elapse(const Duration(minutes: 5));
          expect(settings.get(defs.lockdownEnabled), isTrue);
        });
      },
    );
  });

  group('foreground watchdog under lockdown', () {
    late EventBus bus;
    late CommandRegistry commands;
    late SettingsManager settings;
    late KioskManager kiosk;
    late int reclaims;
    late bool screenOn;

    Future<void> build(Map<String, Object> initial) async {
      SharedPreferences.setMockInitialValues(initial);
      bus = EventBus();
      final log = Logger();
      commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      kiosk = KioskManager(bus, commands, log, settings);
      await kiosk.init();
      reclaims = 0;
      screenOn = true;
      commands.register(
        Command(
          name: 'bringToFront',
          description: 'test stub',
          handler: (_) async {
            reclaims++;
            return const CommandResult.ok(true);
          },
        ),
      );
      commands.register(
        Command(
          name: 'isScreenOn',
          description: 'test stub',
          handler: (_) async => CommandResult.ok(screenOn),
        ),
      );
      // The watchdog rechecks the binding's lifecycle before acting; make
      // it agree the app is genuinely backgrounded.
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
    }

    tearDown(() async {
      await kiosk.dispose();
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
    });

    test('a pause while lockdown holds pulls the app back', () async {
      await build({'ks.lockdown.enabled': true});
      kiosk.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(reclaims, 1);
    });

    test('a return without the input focus stands the reclaim down', () async {
      await build({'ks.lockdown.enabled': true});
      kiosk.didChangeAppLifecycleState(AppLifecycleState.paused);
      // Android reports an Activity resumed under a focus-holding window
      // as inactive, never resumed (issue #560). Pulling an app forward
      // that is already on screen would relaunch its Activity for nothing.
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );
      kiosk.didChangeAppLifecycleState(AppLifecycleState.inactive);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(reclaims, 0);
    });

    test(
      'a reclaim that fires on an app back without focus does nothing',
      () async {
        await build({'ks.lockdown.enabled': true});
        kiosk.didChangeAppLifecycleState(AppLifecycleState.paused);
        // The timer's own recheck, with no lifecycle event reaching this
        // observer in between.
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await Future<void>.delayed(const Duration(milliseconds: 1300));
        expect(reclaims, 0);
      },
    );

    test('a pause without lockdown or kiosk is left alone', () async {
      await build({});
      kiosk.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(reclaims, 0);
    });

    test('kiosk mode with Disable home reclaims too', () async {
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
      kiosk.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(reclaims, 1);
    });

    test('kiosk mode without Disable home does not', () async {
      await build({'ks.kiosk.enabled': true});
      kiosk.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(reclaims, 0);
    });

    test('an open menu stands the kiosk reclaim down', () async {
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
      kiosk.menuBusy = true;
      kiosk.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(reclaims, 0);
    });

    test('a sanctioned app launch stands the kiosk reclaim down', () async {
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
      bus.publish(const AppLaunched(package: 'com.example.app'));
      await pumpEventQueue();
      kiosk.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(reclaims, 0);
    });

    test(
      'Android Settings opened by the app is sanctioned too (issue #417)',
      () async {
        await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
        TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('kiosk_satellite/background'),
              (call) async => call.method == 'openSystemSettings' ? true : null,
            );
        addTearDown(() {
          TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
              .setMockMethodCallHandler(
                const MethodChannel('kiosk_satellite/background'),
                null,
              );
        });
        expect(
          (await commands.execute('openSystemSettings', const {})).ok,
          true,
        );
        kiosk.didChangeAppLifecycleState(AppLifecycleState.paused);
        await Future<void>.delayed(const Duration(milliseconds: 1300));
        expect(reclaims, 0);
      },
    );

    test('a dark panel holds the reclaim fire (issue #291)', () async {
      await build({'ks.lockdown.enabled': true});
      screenOn = false;
      kiosk.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(reclaims, 0);
    });

    test('the relit screen resumes the watch', () async {
      await build({'ks.lockdown.enabled': true});
      screenOn = false;
      kiosk.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(reclaims, 0);
      screenOn = true;
      bus.publish(const ScreenStateChanged(on: true));
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(reclaims, 1);
    });

    test('a screen-off under plain kiosk mode is not an escape', () async {
      await build({'ks.kiosk.enabled': true, 'ks.kiosk.disable_home': true});
      screenOn = false;
      kiosk.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(reclaims, 0);
    });

    test('resuming inside the grace period disarms it', () async {
      await build({'ks.lockdown.enabled': true});
      kiosk.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      kiosk.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(reclaims, 0);
    });
  });

  group('screensaver under lockdown', () {
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

    test('start() refuses while lockdown holds', () async {
      await build({'ks.lockdown.enabled': true});
      await saver.start();
      expect(saver.isActive, false);
    });

    test('the opt-in lets the screensaver run under lockdown', () async {
      await build({
        'ks.lockdown.enabled': true,
        'ks.lockdown.allow_screensaver': true,
      });
      await saver.start();
      expect(saver.isActive, true);
    });

    test('with the opt-in, lockdown flipping on leaves the screensaver '
        'alone; revoking it mid-lockdown stops it', () async {
      await build({'ks.lockdown.allow_screensaver': true});
      await saver.start();
      expect(saver.isActive, true);
      await settings.set(defs.lockdownEnabled, true);
      await pumpEventQueue();
      expect(saver.isActive, true);
      await settings.set(defs.lockdownAllowScreensaver, false);
      await pumpEventQueue();
      expect(saver.isActive, false);
      await saver.start();
      expect(saver.isActive, false);
    });

    test('motion never dismisses the screensaver while locked', () async {
      await build({
        'ks.lockdown.enabled': true,
        'ks.lockdown.allow_screensaver': true,
        'ks.screensaver.dismiss_on_motion': true,
      });
      await saver.start();
      expect(saver.isActive, true);
      bus.publish(const MotionDetected());
      await pumpEventQueue();
      expect(saver.isActive, true);
    });

    test('an active screensaver stops when lockdown flips on, and the '
        'screensaver runs again after it lifts', () async {
      await build({});
      await saver.start();
      expect(saver.isActive, true);
      await settings.set(defs.lockdownEnabled, true);
      await pumpEventQueue();
      expect(saver.isActive, false);
      // Still refused while the mode holds.
      await saver.start();
      expect(saver.isActive, false);
      await settings.set(defs.lockdownEnabled, false);
      await pumpEventQueue();
      await saver.start();
      expect(saver.isActive, true);
    });
  });
}
