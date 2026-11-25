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

/// Detect faces (Screensaver > Face Detection > Ground Control Face
/// Recognition): with Face Recognition
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

  test(
    'Chosen people with nobody chosen: a face nobody named does not count',
    () {
      fakeAsync((async) {
        build({'ks.screensaver.face_who': 'people'});
        expect(postponed(async, null), isFalse);
      });
    },
  );

  test('Chosen people with nobody chosen: anyone recognized counts', () {
    fakeAsync((async) {
      build({'ks.screensaver.face_who': 'people'});
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

  /// A sighting at 3 s with nobody named, then [inView] named [after]
  /// later with no sighting since: whether that kept the 5 s screensaver
  /// away at 5.5 s.
  bool namedLater(FakeAsync async, FaceInViewChanged inView, Duration after) {
    async.flushMicrotasks();
    saver.init();
    async.flushMicrotasks();
    async.elapse(const Duration(seconds: 3));
    bus.publish(const FaceDetected());
    async.flushMicrotasks();
    async.elapse(after);
    bus.publish(inView);
    async.flushMicrotasks();
    async.elapse(
      const Duration(milliseconds: 5500) - const Duration(seconds: 3) - after,
    );
    async.flushMicrotasks();
    return !saver.isActive;
  }

  test('a name that follows a sighting counts without the next sighting', () {
    fakeAsync((async) {
      build({'ks.screensaver.face_who': 'people'});
      expect(namedLater(async, ana, const Duration(milliseconds: 250)), isTrue);
    });
  });

  test('a name for someone not chosen does not count', () {
    fakeAsync((async) {
      build({
        'ks.screensaver.face_who': 'people',
        'ks.screensaver.face_people': chosenAna,
      });
      expect(
        namedLater(async, leo, const Duration(milliseconds: 250)),
        isFalse,
      );
    });
  });

  test('a name long after the last sighting waits for the next one', () {
    fakeAsync((async) {
      build({'ks.screensaver.face_who': 'people'});
      expect(namedLater(async, ana, const Duration(seconds: 2)), isFalse);
    });
  });

  test('a name with no sighting before it does nothing by itself', () {
    fakeAsync((async) {
      build({'ks.screensaver.face_who': 'people'});
      async.flushMicrotasks();
      saver.init();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      bus.publish(ana);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      async.flushMicrotasks();
      expect(saver.isActive, isTrue);
    });
  });
}
