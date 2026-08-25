import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The screensaver stands down while another app is in front: the idle
/// clock stops, a running session ends (brightness is device-wide, so a
/// dim under someone using Chrome dims Chrome), and the clock restarts
/// from the return. A dark panel pauses the Activity the same way and is
/// told apart through isScreenOn, so a screen-off leaves the session be.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late SettingsManager settings;
  late ScreensaverManager saver;
  late List<String> executed;
  late bool screenOn;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    final calls = <String>[];
    executed = calls;
    screenOn = true;
    for (final name in ['screenOn', 'keepScreenAwake', 'setBrightness']) {
      commands.register(
        Command(
          name: name,
          description: 'recorder',
          handler: (_) async {
            calls.add(name);
            return const CommandResult.ok();
          },
        ),
      );
    }
    commands.register(
      Command(
        name: 'getBrightness',
        description: 'stub',
        handler: (_) async => const CommandResult.ok(0.8),
      ),
    );
    commands.register(
      Command(
        name: 'isScreenOn',
        description: 'stub',
        handler: (_) async => CommandResult.ok(screenOn),
      ),
    );
    saver = ScreensaverManager(
      bus,
      commands,
      log,
      settings,
      pauseProbeDelay: const Duration(milliseconds: 10),
    );
    await saver.init();
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 60));

  const dimOneSecond = {
    'ks.screensaver.enabled': true,
    'ks.screensaver.mode': 'dim',
    'ks.screensaver.timeout_seconds': 1,
  };

  test(
    'the idle clock does not start a screensaver behind another app',
    () async {
      await build(dimOneSecond);
      saver.didChangeAppLifecycleState(AppLifecycleState.paused);
      await settle();
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(saver.isActive, isFalse);
      expect(executed, isNot(contains('setBrightness')));
    },
  );

  test('a running screensaver ends when another app comes up', () async {
    await build(dimOneSecond);
    await saver.start();
    expect(saver.isActive, isTrue);
    saver.didChangeAppLifecycleState(AppLifecycleState.paused);
    await settle();
    expect(
      saver.isActive,
      isFalse,
      reason: 'the other app must get the brightness back',
    );
  });

  test('a commanded start is refused behind another app', () async {
    await build(dimOneSecond);
    saver.didChangeAppLifecycleState(AppLifecycleState.paused);
    await settle();
    await saver.start();
    expect(saver.isActive, isFalse);
  });

  test('the clock starts over from the return', () async {
    await build(dimOneSecond);
    saver.didChangeAppLifecycleState(AppLifecycleState.paused);
    await settle();
    saver.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(saver.isActive, isTrue);
  });

  test('a dark panel is not another app: the session stays', () async {
    await build(dimOneSecond);
    await saver.start();
    screenOn = false;
    saver.didChangeAppLifecycleState(AppLifecycleState.paused);
    await settle();
    expect(saver.isActive, isTrue);
  });

  test('a pause that resumes before the probe changes nothing', () async {
    await build(dimOneSecond);
    saver.didChangeAppLifecycleState(AppLifecycleState.paused);
    saver.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await settle();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(
      saver.isActive,
      isTrue,
      reason: 'the original idle clock was never held',
    );
  });
}
