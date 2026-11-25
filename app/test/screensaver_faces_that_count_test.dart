import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faces that count (Screensaver > Face Detection): with Face Recognition
/// on Ground Control, only a recognized face, or one of the chosen people,
/// dismisses or postpones the screensaver. Checked on the postpone leg: a
/// face that counts at 3 s keeps the 5 s screensaver away.
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
  late ScreensaverManager saver;

  Future<void> build(Map<String, Object> extra) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.enabled': true,
      'ks.screensaver.timeout_seconds': 5,
      'ks.screensaver.dismiss_on_motion': false,
      'ks.screensaver.dismiss_on_face': true,
      'ks.screensaver.postpone_on_face': true,
      'ks.camera.enabled': true,
      'ks.ground_control.enabled': true,
      'ks.vision_match.enabled': true,
      'ks.vision_match.face_detection': true,
      'ks.vision_match.face_recognition': true,
      ...extra,
    });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    saver = ScreensaverManager(bus, commands, log, settings);
  }

  /// Whether a face at 3 s, with [inView] recognized, kept the screensaver
  /// away past its 5 s timeout.
  bool postponed(FakeAsync async, FaceInViewChanged? inView) {
    async.flushMicrotasks();
    saver.init();
    async.flushMicrotasks();
    async.elapse(const Duration(seconds: 3));
    if (inView != null) bus.publish(inView);
    bus.publish(const FaceDetected());
    async.flushMicrotasks();
    async.elapse(const Duration(seconds: 3));
    async.flushMicrotasks();
    return !saver.isActive;
  }

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
  const chosenAna = '[{"id":"ana","name":"Ana"}]';

  test('Anyone: any face counts', () {
    fakeAsync((async) {
      build({'ks.screensaver.face_who': 'anyone'});
      expect(postponed(async, null), isTrue);
    });
  });

  test('Recognized people: a face nobody named does not count', () {
    fakeAsync((async) {
      build({'ks.screensaver.face_who': 'recognized'});
      expect(postponed(async, null), isFalse);
    });
  });

  test('Recognized people: a named face counts', () {
    fakeAsync((async) {
      build({'ks.screensaver.face_who': 'recognized'});
      expect(postponed(async, leo), isTrue);
    });
  });

  test('Chosen people: only a chosen face counts', () {
    fakeAsync((async) {
      build({
        'ks.screensaver.face_who': 'people',
        'ks.screensaver.face_people': chosenAna,
      });
      expect(postponed(async, leo), isFalse);
    });
    fakeAsync((async) {
      build({
        'ks.screensaver.face_who': 'people',
        'ks.screensaver.face_people': chosenAna,
      });
      expect(postponed(async, ana), isTrue);
    });
  });

  test(
    'a chosen person in view counts even with someone else at the kiosk',
    () {
      fakeAsync((async) {
        build({
          'ks.screensaver.face_who': 'people',
          'ks.screensaver.face_people': chosenAna,
        });
        const both = FaceInViewChanged(
          id: 'leo',
          name: 'Leo',
          people: [(id: 'leo', name: 'Leo'), (id: 'ana', name: 'Ana')],
        );
        expect(postponed(async, both), isTrue);
      });
    },
  );

  test('with Face Recognition off the setting is hidden and anyone counts', () {
    fakeAsync((async) {
      build({
        'ks.vision_match.face_recognition': false,
        'ks.screensaver.face_who': 'people',
        'ks.screensaver.face_people': chosenAna,
      });
      expect(postponed(async, null), isTrue);
    });
  });
}
