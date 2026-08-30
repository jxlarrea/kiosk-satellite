import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screen/screen_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// Screen on against a panel that ignores the wake lock: the manager must
/// notice the panel stayed dark, try the Activity route, and end with the
/// logical state matching the panel rather than the request.
class _NoopWakelock extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}

  @override
  Future<bool> get enabled async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('kiosk_satellite/background');

  /// The fake panel: whether it is lit, and which routes light it.
  late bool interactive;
  late bool wakeLockLights;
  late bool activityLights;
  late String activityOutcome;
  late String? keyguardOutcome;
  late bool keyguardStays;
  late List<String> calls;
  late List<ScreenStateChanged> events;
  late Logger log;
  late CommandRegistry commands;
  late ScreenManager screen;

  Future<void> build({
    bool lit = false,
    bool wakeLock = false,
    bool activity = false,
    String outcome = 'started',
    String? keyguard,
    bool keyguardRefuses = false,
  }) async {
    keyguardStays = keyguardRefuses;
    interactive = lit;
    wakeLockLights = wakeLock;
    activityLights = activity;
    activityOutcome = outcome;
    keyguardOutcome = keyguard;
    calls = [];
    events = [];
    wakelockPlusPlatformInstance = _NoopWakelock();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'isScreenInteractive':
              return interactive;
            case 'wakeScreen':
              if (interactive) return false;
              if (wakeLockLights) interactive = true;
              return true;
            case 'wakeScreenViaActivity':
              if (activityOutcome == 'started' && activityLights) {
                interactive = true;
              }
              return activityOutcome;
            case 'dismissKeyguard':
              return keyguardOutcome;
            case 'keyguardLocked':
              return keyguardStays;
            case 'ambientDisplaySetting':
              return -1;
            default:
              return null;
          }
        });
    final bus = EventBus();
    log = Logger();
    commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    bus.on<ScreenStateChanged>().listen(events.add);
    screen = ScreenManager(
      bus,
      commands,
      log,
      settings,
      wakeSettle: const Duration(milliseconds: 10),
      activitySettle: const Duration(milliseconds: 10),
    );
    await screen.init();
  }

  /// Let both settle delays and the bus deliveries run.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 60));

  Iterable<String> warnings() => log.recent
      .where((e) => e.tag == 'screen' && e.level == LogLevel.warn)
      .map((e) => e.message);

  test('a wake lock that lights the panel is the whole story', () async {
    await build(wakeLock: true, keyguard: 'not_locked');
    expect(screen.isScreenOn, isFalse, reason: 'seeded from the dark panel');
    await screen.screenOn();
    await settle();
    expect(calls, isNot(contains('wakeScreenViaActivity')));
    expect(screen.isScreenOn, isTrue);
    expect(warnings(), isEmpty);
    // The lock screen is checked once the panel is known lit, never before.
    expect(calls, contains('dismissKeyguard'));
    expect(
      calls.indexOf('isScreenInteractive', 1),
      lessThan(calls.indexOf('dismissKeyguard')),
    );
  });

  test('a panel lit on an unsecured lock screen has it dismissed', () async {
    await build(wakeLock: true, keyguard: 'started');
    await screen.screenOn();
    await settle();
    expect(calls, contains('dismissKeyguard'));
    expect(warnings(), isEmpty);
    expect(
      log.recent.map((e) => e.message),
      contains('the panel lit on the lock screen; dismissing it'),
    );
    expect(screen.isScreenOn, isTrue);
  });

  test('a dismissal that went through is verified quietly', () async {
    await build(wakeLock: true, keyguard: 'started');
    await screen.screenOn();
    await settle();
    expect(calls, contains('keyguardLocked'));
    expect(warnings(), isEmpty);
  });

  test('a lock screen that refused to go is named, with the fix', () async {
    await build(wakeLock: true, keyguard: 'started', keyguardRefuses: true);
    await screen.screenOn();
    await settle();
    expect(warnings(), hasLength(1));
    expect(warnings().first, contains('refused to go'));
    expect(warnings().first, contains('locksettings set-disabled true'));
  });

  test('a secured lock screen is named, not fought', () async {
    await build(wakeLock: true, keyguard: 'secure');
    await screen.screenOn();
    await settle();
    expect(warnings(), [
      'the panel lit on a secured lock screen; the kiosk stays behind it '
          'until the device is unlocked',
    ]);
    // The panel is lit, whatever is on it.
    expect(screen.isScreenOn, isTrue);
  });

  test('a lock screen the activity route lit is checked too', () async {
    await build(activity: true, keyguard: 'started');
    await screen.screenOn();
    await settle();
    expect(
      calls.indexOf('wakeScreenViaActivity'),
      lessThan(calls.indexOf('dismissKeyguard')),
    );
    expect(
      log.recent.map((e) => e.message),
      contains('the panel lit on the lock screen; dismissing it'),
    );
  });

  test('a panel that stayed dark never asks about the lock screen', () async {
    await build(keyguard: 'started');
    await screen.screenOn();
    await settle();
    expect(calls, isNot(contains('dismissKeyguard')));
  });

  test(
    'a panel the wake lock left dark goes through the activity route',
    () async {
      await build(activity: true);
      await screen.screenOn();
      await settle();
      expect(calls, contains('wakeScreenViaActivity'));
      expect(
        calls.indexOf('wakeScreen'),
        lessThan(calls.indexOf('wakeScreenViaActivity')),
      );
      expect(screen.isScreenOn, isTrue);
      expect(warnings(), [
        'the wake lock did not light the panel; trying the activity route',
      ]);
      expect(
        log.recent.map((e) => e.message),
        contains('the activity route lit the panel'),
      );
      // The optimistic on stands; nothing took it back.
      expect(events.map((e) => e.on), [true]);
    },
  );

  test(
    'dark after both routes: the flag follows the panel, not the request',
    () async {
      await build();
      await screen.screenOn();
      await settle();
      expect(screen.isScreenOn, isFalse);
      expect(warnings().last, 'the panel stayed dark after both wake routes');
      final last = events.last;
      expect(last.on, isFalse);
      expect(last.source, 'probe');
    },
  );

  test(
    'a missing overlay grant is named, and the flag comes back down',
    () async {
      await build(outcome: 'no_overlay_grant');
      await screen.screenOn();
      await settle();
      expect(screen.isScreenOn, isFalse);
      expect(
        warnings().last,
        'the activity route needs the Display over other apps permission; '
        'the panel stays dark',
      );
    },
  );

  test('the command\'s activity path skips the wake lock', () async {
    await build(activity: true);
    final result = await commands.execute('screenOn', {'path': 'activity'});
    expect(result.ok, isTrue);
    await settle();
    expect(calls, isNot(contains('wakeScreen')));
    expect(calls, contains('wakeScreenViaActivity'));
    expect(screen.isScreenOn, isTrue);
    expect(warnings(), isEmpty);
  });

  test('a lit panel needs no confirmation at all', () async {
    await build(lit: true);
    await screen.screenOn();
    await settle();
    expect(calls.where((c) => c == 'wakeScreenViaActivity'), isEmpty);
    expect(screen.isScreenOn, isTrue);
    expect(warnings(), isEmpty);
  });
}
