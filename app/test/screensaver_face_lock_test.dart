import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screensaver > Face Detection > Ground Control Vision Match > Only chosen
/// people dismiss it: nothing at the kiosk but a chosen face ends the
/// screensaver, while Kiosk Satellite and Home Assistant still can.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async => switch (call.method) {
            'checkPermissionStatus' => 0,
            'requestPermissions' => <dynamic, dynamic>{},
            _ => null,
          },
        );
  });

  late EventBus bus;
  late CommandRegistry commands;
  late SettingsManager settings;
  late ScreensaverManager saver;

  const ana = FaceInViewChanged(
    id: 'ana',
    name: 'Ana',
    people: [(id: 'ana', name: 'Ana')],
  );
  const leo = FaceInViewChanged(
    id: 'leo',
    name: 'Leo',
    people: [(id: 'leo', name: 'Leo')],
  );

  /// A screensaver up after its 5 s timeout, with Ana chosen.
  void up(FakeAsync async, {bool lock = true, bool motion = true}) {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.enabled': true,
      'ks.screensaver.timeout_seconds': 5,
      // Dismiss on motion takes precedence over faces without the lock.
      'ks.screensaver.dismiss_on_motion': motion,
      'ks.screensaver.dismiss_on_face': true,
      'ks.screensaver.dismiss_on_proximity': true,
      'ks.camera.enabled': true,
      'ks.ground_control.enabled': true,
      'ks.vision_match.enabled': true,
      'ks.vision_match.face_detection': true,
      'ks.vision_match.face_recognition': true,
      'ks.screensaver.face_who': 'people',
      'ks.screensaver.face_people': '[{"id":"ana","name":"Ana"}]',
      'ks.screensaver.face_lock': lock,
    });
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    settings.init();
    async.flushMicrotasks();
    saver = ScreensaverManager(bus, commands, log, settings);
    saver.init();
    async.flushMicrotasks();
    async.elapse(const Duration(seconds: 6));
    async.flushMicrotasks();
    expect(saver.isActive, isTrue);
  }

  void face(FakeAsync async, FaceInViewChanged who) {
    bus.publish(who);
    bus.publish(const FaceDetected());
    async.flushMicrotasks();
  }

  test('nothing at the kiosk but a chosen face ends it', () {
    fakeAsync((async) {
      up(async);
      expect(saver.faceLocked.value, isTrue);
      for (final source in [
        'touch',
        'pane_touch',
        'tap',
        'screensaver_touch',
        'key',
        'close',
        'motion',
        'proximity',
        'person',
      ]) {
        saver.notifyActivity(source);
        async.flushMicrotasks();
        expect(saver.isActive, isTrue, reason: source);
      }
      bus.publish(const MotionDetected());
      async.flushMicrotasks();
      expect(saver.isActive, isTrue);
      // Leo was not chosen.
      face(async, leo);
      expect(saver.isActive, isTrue);
      // Ana was, and her face counts even with Dismiss on motion on.
      face(async, ana);
      expect(saver.isActive, isFalse);
      expect(saver.faceLocked.value, isFalse);
    });
  });

  test('Kiosk Satellite and Home Assistant still end it', () {
    fakeAsync((async) {
      up(async);
      commands.execute('stopScreensaver', const {});
      async.flushMicrotasks();
      expect(saver.isActive, isFalse);
    });
    fakeAsync((async) {
      up(async);
      // Postpone, as Home Assistant and the APIs send it.
      commands.execute('postponeScreensaver', const {});
      async.flushMicrotasks();
      expect(saver.isActive, isFalse);
    });
  });

  test('off, a touch ends it as before', () {
    fakeAsync((async) {
      up(async, lock: false);
      expect(saver.faceLocked.value, isFalse);
      saver.notifyActivity('touch');
      async.flushMicrotasks();
      expect(saver.isActive, isFalse);
    });
  });

  test('only on Chosen people', () {
    fakeAsync((async) {
      up(async);
      settings.set(defs.screensaverFaceWho, 'anyone');
      async.flushMicrotasks();
      expect(saver.faceLocked.value, isFalse);
      saver.notifyActivity('touch');
      async.flushMicrotasks();
      expect(saver.isActive, isFalse);
    });
  });
}
