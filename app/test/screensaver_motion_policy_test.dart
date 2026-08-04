import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/motion/motion_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The schedule's per-entry motion override (issue #89): the screensaver
/// announces the active entry's policy, and the motion manager's gate
/// prefers it over the "Dismiss on motion" switch. Registry commands the
/// screensaver calls (setBrightness, keepScreenAwake, ...) are absent here
/// and fail soft; the mocked camera permission below answers denied, so the
/// camera itself never starts.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Where a test leaves motion enabled under an active screensaver, the
  // manager asks for the camera permission: answer "denied" so the camera
  // path stops there instead of reaching the (absent) camera plugin.
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => switch (call.method) {
        'checkPermissionStatus' => 0,
        'requestPermissions' => <dynamic, dynamic>{},
        'shouldShowRequestPermissionRationale' => true,
        _ => null,
      },
    );
  });

  late EventBus bus;
  late CommandRegistry commands;
  late ScreensaverManager saver;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    saver = ScreensaverManager(bus, commands, log, settings);
    final motion = MotionManager(bus, commands, log, settings);
    await motion.init();
  }

  test('a session under a motion:false entry announces the override and '
      'clears it on stop', () async {
    await build({
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"black","motion":false}]',
      'ks.screensaver.dismiss_on_motion': true,
      'ks.camera.enabled': true,
    });
    final published = <bool?>[];
    bus
        .on<ScreensaverMotionPolicyChanged>()
        .listen((e) => published.add(e.dismissOnMotion));

    await saver.start();
    await pumpEventQueue();
    expect(published, [false]);
    // The switch says watch, the entry says do not: the entry wins.
    final enabled = await commands.execute('getMotionEnabled', const {});
    expect(enabled.data, isFalse);

    await saver.stop();
    await pumpEventQueue();
    expect(published, [false, null]);
    final after = await commands.execute('getMotionEnabled', const {});
    expect(after.data, isTrue);
  });

  test('a motion:true entry enables detection over a switched-off setting',
      () async {
    await build({
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule':
          '[{"at":"00:00","mode":"clock","motion":true}]',
      'ks.screensaver.dismiss_on_motion': false,
      'ks.camera.enabled': true,
    });
    await saver.start();
    await pumpEventQueue();
    final enabled = await commands.execute('getMotionEnabled', const {});
    expect(enabled.data, isTrue);
  });

  test('an entry without the field follows the switch', () async {
    await build({
      'ks.screensaver.schedule_enabled': true,
      'ks.screensaver.schedule': '[{"at":"00:00","mode":"black"}]',
      'ks.screensaver.dismiss_on_motion': false,
      'ks.camera.enabled': true,
    });
    final published = <bool?>[];
    bus
        .on<ScreensaverMotionPolicyChanged>()
        .listen((e) => published.add(e.dismissOnMotion));
    await saver.start();
    await pumpEventQueue();
    // No override to announce, and the switch (off) stays in charge.
    expect(published, isEmpty);
    final enabled = await commands.execute('getMotionEnabled', const {});
    expect(enabled.data, isFalse);
  });

  test('motion postpones the screensaver between sessions (discussion #126)',
      () {
    fakeAsync((async) {
      build({
        'ks.screensaver.enabled': true,
        'ks.screensaver.timeout_seconds': 5,
        'ks.screensaver.postpone_on_motion': true,
        'ks.camera.enabled': true,
      });
      async.flushMicrotasks();
      saver.init(); // arms the idle timer and the motion listener
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 3));
      bus.publish(const MotionDetected());
      async.flushMicrotasks();
      // 6s in: past the original 5s deadline, but the motion at 3s reset
      // the clock, so nothing has started.
      async.elapse(const Duration(seconds: 3));
      async.flushMicrotasks();
      expect(saver.isActive, isFalse,
          reason: 'motion must have reset the idle clock');
      // A full quiet timeout after the motion: the screensaver starts.
      async.elapse(const Duration(seconds: 3));
      async.flushMicrotasks();
      expect(saver.isActive, isTrue);
    });
  });

  test('without the toggle, motion between sessions changes nothing', () {
    fakeAsync((async) {
      build({
        'ks.screensaver.enabled': true,
        'ks.screensaver.timeout_seconds': 5,
        'ks.screensaver.postpone_on_motion': false,
        'ks.camera.enabled': true,
      });
      async.flushMicrotasks();
      saver.init();
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 3));
      bus.publish(const MotionDetected());
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      async.flushMicrotasks();
      // 6s in: the 5s deadline fired on schedule; the motion was ignored.
      expect(saver.isActive, isTrue);
    });
  });
}
