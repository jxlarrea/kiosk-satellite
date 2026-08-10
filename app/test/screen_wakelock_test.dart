import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screen/screen_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// The boot-time wakelock race (issue #167): when the app starts at boot the
/// managers initialize on the cached engine before the Activity exists, so
/// the initial "Keep screen on" apply throws "wakelock requires a foreground
/// activity". The manager must retry when the app reaches the foreground,
/// not leave the screen to time out until the setting is toggled by hand.
class _FakeWakelock extends WakelockPlusPlatformInterface {
  /// Whether an Activity is "attached": toggles fail without one, exactly
  /// like wakelock_plus on a headless engine.
  bool activityAttached = false;

  bool? lastToggle;
  int toggleCalls = 0;

  @override
  Future<void> toggle({required bool enable}) async {
    toggleCalls++;
    if (!activityAttached) {
      throw PlatformException(
          code: 'wakelock',
          message: 'wakelock requires a foreground activity');
    }
    lastToggle = enable;
  }

  @override
  Future<bool> get enabled async => lastToggle ?? false;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeWakelock wakelock;
  late ScreenManager screen;

  Future<void> build(Map<String, Object> initial) async {
    wakelock = _FakeWakelock();
    // Not via WakelockPlusPlatformInterface.instance: WakelockPlus snapshots
    // that into this variable on first use and never re-reads it.
    wakelockPlusPlatformInstance = wakelock;
    SharedPreferences.setMockInitialValues(initial);
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    screen = ScreenManager(bus, commands, log, settings);
    await screen.init();
  }

  Future<void> resume() async {
    // Through inactive first: the test binding sits on resumed between
    // tests, and an unchanged state notifies no observer.
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    // Let the unawaited reapply run.
    await Future<void>.delayed(Duration.zero);
  }

  tearDown(() => screen.dispose());

  test('a boot-time apply that failed without an Activity is retried on '
      'the resume that means one exists', () async {
    await build({'ks.screen.keep_on': true});
    // Headless init: the apply threw and nothing holds the screen.
    expect(wakelock.toggleCalls, 1);
    expect(wakelock.lastToggle, isNull);

    wakelock.activityAttached = true;
    await resume();
    expect(wakelock.lastToggle, isTrue);
  });

  test('a resume with the setting off reapplies the disable, keeping the '
      'window flag off on a rebuilt Activity', () async {
    await build({'ks.screen.keep_on': false});
    wakelock.activityAttached = true;
    await resume();
    expect(wakelock.lastToggle, isFalse);
  });

  test('every resume reapplies, so a recreated Activity window gets the '
      'flag back even though the first apply succeeded', () async {
    wakelock = _FakeWakelock()..activityAttached = true;
    wakelockPlusPlatformInstance = wakelock;
    SharedPreferences.setMockInitialValues({'ks.screen.keep_on': true});
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    screen = ScreenManager(bus, commands, log, settings);
    await screen.init();
    expect(wakelock.lastToggle, isTrue);

    // The recreated Activity's fresh window starts without the flag; the
    // fake mirrors that by forgetting the last toggle.
    wakelock.lastToggle = null;
    await resume();
    expect(wakelock.lastToggle, isTrue);
  });
}
