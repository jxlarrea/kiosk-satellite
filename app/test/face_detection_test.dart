import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/motion/motion_manager.dart';
import 'package:kiosk_satellite/managers/motion/native_motion.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The face leg (issue #304): "Dismiss on face" rides the motion camera
/// session during the screensaver, asks the native side for face
/// sightings, and yields to Dismiss on motion whenever that is on. The
/// camera plugin is mocked at the EventChannel so a test can see what the
/// stream was asked for and push sightings through it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var listens = 0;
  Map<Object?, Object?>? lastArgs;
  MockStreamHandlerEventSink? sink;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async => switch (call.method) {
            'checkPermissionStatus' => 1,
            _ => null,
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('kiosk_satellite/motion'),
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              listens++;
              lastArgs = arguments as Map<Object?, Object?>?;
              sink = events;
            },
            onCancel: (arguments) => sink = null,
          ),
        );
  });

  late EventBus bus;
  late CommandRegistry commands;
  late SettingsManager settings;
  late MotionManager motion;

  Future<void> build(Map<String, Object> initial) async {
    listens = 0;
    lastArgs = null;
    sink = null;
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    // Zero quiet window: the ticks below follow a screensaver start, and
    // the self-light gate has its own test in motion_sensor_test.dart.
    motion = MotionManager(
      bus,
      commands,
      log,
      settings,
      selfLightQuiet: Duration.zero,
    );
    await motion.init();
  }

  /// Lets the channel plumbing (mock stream listen/cancel, event delivery)
  /// and the bus deliver; pumpEventQueue alone is not enough for the mock
  /// stream's sink.
  Future<void> pump() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  const faceOnly = {
    'ks.screensaver.dismiss_on_face': true,
    'ks.screensaver.dismiss_on_motion': false,
    'ks.camera.enabled': true,
  };

  test('the face leg runs the camera during the screensaver only, asking '
      'for faces and not motion', () async {
    await build(faceOnly);
    expect(listens, 0, reason: 'nothing to look at between screensavers');
    expect(motion.faceEnabled, isTrue);

    bus.publish(const ScreensaverStateChanged(active: true));
    await pump();
    expect(listens, 1);
    expect(lastArgs?['faces'], isTrue);
    expect(lastArgs?['motion'], isFalse);
    expect(lastArgs?['faceMinWidth'], faceMinWidthFor(50));

    bus.publish(const ScreensaverStateChanged(active: false));
    await pump();
    expect(sink, isNull, reason: 'the camera is released with the session');
  });

  test(
    'a face sighting becomes FaceDetected; a null tick stays motion',
    () async {
      await build(faceOnly);
      bus.publish(const ScreensaverStateChanged(active: true));
      await pump();
      final faces = <FaceDetected>[];
      final motions = <MotionDetected>[];
      bus.on<FaceDetected>().listen(faces.add);
      bus.on<MotionDetected>().listen(motions.add);

      sink!.success({'face': 0.31});
      await pump();
      expect(faces, hasLength(1));
      expect(motions, isEmpty);

      sink!.success(null);
      await pump();
      expect(faces, hasLength(1));
      expect(motions, hasLength(1));
    },
  );

  test('Dismiss on motion takes precedence: the face leg is idle and the '
      'stream asks for motion only', () async {
    await build({...faceOnly, 'ks.screensaver.dismiss_on_motion': true});
    expect(motion.faceEnabled, isFalse);
    final answer = await commands.execute('getFaceEnabled', const {});
    expect(answer.data, isFalse);

    bus.publish(const ScreensaverStateChanged(active: true));
    await pump();
    expect(listens, 1);
    expect(lastArgs?['faces'], isFalse);
    expect(lastArgs?['motion'], isTrue);
  });

  test('turning Dismiss on motion off mid-session hands the camera to the '
      'face leg', () async {
    await build({...faceOnly, 'ks.screensaver.dismiss_on_motion': true});
    bus.publish(const ScreensaverStateChanged(active: true));
    await pump();
    expect(lastArgs?['faces'], isFalse);

    await settings.set(defs.screensaverDismissOnMotion, false);
    await pump();
    expect(listens, 2, reason: 'a fresh listen with fresh arguments');
    expect(lastArgs?['faces'], isTrue);
    expect(lastArgs?['motion'], isFalse);
  });

  test('the sensor leg holding the camera restarts it with faces when the '
      'screensaver starts', () async {
    await build({...faceOnly, 'ks.motion.sensor': true});
    await pump();
    expect(listens, 1);
    expect(lastArgs?['faces'], isFalse);
    expect(lastArgs?['motion'], isTrue);

    bus.publish(const ScreensaverStateChanged(active: true));
    await pump();
    expect(listens, 2);
    expect(lastArgs?['faces'], isTrue);
    expect(lastArgs?['motion'], isTrue, reason: 'the sensor still wants ticks');

    bus.publish(const ScreensaverStateChanged(active: false));
    await pump();
    expect(listens, 3);
    expect(lastArgs?['faces'], isFalse);
    expect(sink, isNotNull, reason: 'the sensor leg keeps the camera');
  });

  test('Postpone on face runs the camera between screensavers, screen on, '
      'asking for faces only', () async {
    await build({
      ...faceOnly,
      'ks.screensaver.postpone_on_face': true,
      'ks.screensaver.enabled': true,
    });
    await pump();
    expect(listens, 1, reason: 'the postpone leg wants the camera');
    expect(lastArgs?['faces'], isTrue);
    expect(lastArgs?['motion'], isFalse);

    // A dark panel has no screensaver worth holding back.
    bus.publish(const ScreenStateChanged(on: false));
    await pump();
    expect(sink, isNull);
    bus.publish(const ScreenStateChanged(on: true));
    await pump();
    expect(listens, 2);
  });

  test('Postpone on face never acts on its own, and yields to Dismiss on '
      'motion like the dismiss leg', () async {
    await build({
      'ks.screensaver.postpone_on_face': true,
      'ks.screensaver.dismiss_on_face': false,
      'ks.screensaver.dismiss_on_motion': false,
      'ks.screensaver.enabled': true,
      'ks.camera.enabled': true,
    });
    await pump();
    expect(listens, 0, reason: 'hidden under an off Dismiss on face');

    await build({
      ...faceOnly,
      'ks.screensaver.postpone_on_face': true,
      'ks.screensaver.dismiss_on_motion': true,
      'ks.screensaver.enabled': true,
    });
    await pump();
    expect(listens, 0, reason: 'motion takes precedence between sessions');
  });

  test('without the camera master nothing runs', () async {
    await build({...faceOnly, 'ks.camera.enabled': false});
    expect(motion.faceEnabled, isFalse);
    bus.publish(const ScreensaverStateChanged(active: true));
    await pump();
    expect(listens, 0);
  });

  test('the sensitivity slider maps to a minimum face width that shrinks '
      'with distance', () {
    expect(faceMinWidthFor(1), closeTo(0.30, 0.01));
    expect(faceMinWidthFor(100), closeTo(0.036, 0.002));
    expect(faceMinWidthFor(50), lessThan(faceMinWidthFor(1)));
    expect(faceMinWidthFor(50), greaterThan(faceMinWidthFor(100)));
    expect(faceMinWidthFor(-5), faceMinWidthFor(1));
    expect(faceMinWidthFor(500), faceMinWidthFor(100));
  });

  test('a sensitivity change restarts the stream with the new width', () async {
    await build(faceOnly);
    bus.publish(const ScreensaverStateChanged(active: true));
    await pump();
    await settings.set(defs.faceSensitivity, 90);
    await pump();
    expect(listens, 2);
    expect(lastArgs?['faceMinWidth'], faceMinWidthFor(90));
  });

  group('with the screensaver manager', () {
    late ScreensaverManager saver;

    Future<void> buildAll(Map<String, Object> initial) async {
      await build(initial);
      saver = ScreensaverManager(bus, commands, Logger(), settings);
    }

    test(
      'a schedule entry with face:true arms the leg over a switched-off '
      'setting, and face:false with motion:true hands it to motion',
      () async {
        await buildAll({
          'ks.screensaver.schedule_enabled': true,
          'ks.screensaver.schedule':
              '[{"at":"00:00","mode":"clock","face":true,"motion":false}]',
          'ks.screensaver.dismiss_on_face': false,
          'ks.screensaver.dismiss_on_motion': true,
          'ks.camera.enabled': true,
        });
        final published = <(bool?, bool?)>[];
        bus.on<ScreensaverMotionPolicyChanged>().listen(
          (e) => published.add((e.dismissOnMotion, e.dismissOnFace)),
        );
        await saver.start();
        await pump();
        expect(published, [(false, true)]);
        // The switches say motion; the entry says faces: the entry wins.
        expect(motion.faceEnabled, isTrue);
        expect(lastArgs?['faces'], isTrue);
        expect(lastArgs?['motion'], isFalse);

        await saver.stop();
        await pump();
        expect(published, [(false, true), (null, null)]);
        expect(motion.faceEnabled, isFalse);
      },
    );

    test('a face wakes the screensaver under Dismiss on face, and is '
        'ignored while Dismiss on motion takes precedence', () async {
      await buildAll({
        'ks.screensaver.dismiss_on_face': true,
        'ks.screensaver.dismiss_on_motion': false,
        'ks.camera.enabled': true,
      });
      await saver.init();
      await saver.start();
      await pump();
      expect(saver.isActive, isTrue);

      bus.publish(const FaceDetected());
      await pump();
      expect(saver.isActive, isFalse, reason: 'the face dismissed it');

      await settings.set(defs.screensaverDismissOnMotion, true);
      await saver.start();
      await pump();
      bus.publish(const FaceDetected());
      await pump();
      expect(saver.isActive, isTrue, reason: 'motion owns the wake-up');
    });

    test('a face postpones the screensaver between sessions under Postpone '
        'on face, and not without it', () {
      fakeAsync((async) {
        buildAll({
          'ks.screensaver.enabled': true,
          'ks.screensaver.timeout_seconds': 5,
          'ks.screensaver.dismiss_on_face': true,
          'ks.screensaver.postpone_on_face': true,
          'ks.screensaver.dismiss_on_motion': false,
          'ks.camera.enabled': true,
        });
        async.flushMicrotasks();
        saver.init();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 3));
        bus.publish(const FaceDetected());
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        async.flushMicrotasks();
        expect(
          saver.isActive,
          isFalse,
          reason: 'the face at 3s must have reset the idle clock',
        );
        async.elapse(const Duration(seconds: 3));
        async.flushMicrotasks();
        expect(saver.isActive, isTrue);
      });
      fakeAsync((async) {
        buildAll({
          'ks.screensaver.enabled': true,
          'ks.screensaver.timeout_seconds': 5,
          'ks.screensaver.dismiss_on_face': true,
          'ks.screensaver.postpone_on_face': false,
          'ks.camera.enabled': true,
        });
        async.flushMicrotasks();
        saver.init();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        bus.publish(const FaceDetected());
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        async.flushMicrotasks();
        expect(saver.isActive, isTrue, reason: 'no postpone leg without it');
      });
    });

    test('a face never dismisses or postpones with the postpone switch off '
        'between sessions', () async {
      await buildAll({
        'ks.screensaver.dismiss_on_face': true,
        'ks.screensaver.dismiss_on_motion': false,
        'ks.camera.enabled': true,
      });
      await saver.init();
      await pump();
      expect(saver.isActive, isFalse);
      bus.publish(const FaceDetected());
      await pump();
      expect(saver.isActive, isFalse);
    });
  });
}
