import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/device_camera/device_camera_manager.dart';
import 'package:kiosk_satellite/managers/device_camera/native_camera.dart';
import 'package:kiosk_satellite/managers/motion/motion_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Camera permission answers "denied": snapshot attempts stop there with a
  // countable warn instead of reaching the (absent) camera plugin.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async => switch (call.method) {
            'checkPermissionStatus' => 0,
            _ => null,
          },
        );
  });

  late EventBus bus;
  late CommandRegistry commands;
  late Logger log;
  late SettingsManager settings;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
  }

  DeviceCameraManager camera() =>
      DeviceCameraManager(bus, commands, log, settings);

  test(
    'camera defaults: off, front, 480p, no snapshots, 60s interval',
    () async {
      await build({});
      expect(settings.get(defs.cameraEnabled), isFalse);
      expect(settings.get(defs.cameraDevice), 'front');
      expect(settings.get(defs.cameraSnapshotResolution), '480');
      expect(settings.get(defs.cameraDisableDetectionSnapshots), isFalse);
      expect(settings.get(defs.cameraSnapshots), isFalse);
      expect(settings.get(defs.cameraSnapshotInterval), 60);
    },
  );

  test('each resolution tier maps to its 4:3 capture target', () {
    expect(snapshotResolution('480'), (640, 480));
    expect(snapshotResolution('720'), (960, 720));
    expect(snapshotResolution('1080'), (1440, 1080));
    // An unknown stored value (a retired tier, a hand-edited import) must
    // fall back to the default tier, not crash the capture path.
    expect(snapshotResolution('1440'), (640, 480));
    expect(snapshotResolution('nonsense'), (640, 480));
  });

  test('migration: a device using motion detection keeps it working', () async {
    await build({
      'ks.screensaver.dismiss_on_motion': true,
      'ks.motion.camera': 'back',
    });
    await camera().init();
    // The camera turns on and carries the old camera pick over, so motion
    // detection survives the update to the Camera section.
    expect(settings.get(defs.cameraEnabled), isTrue);
    expect(settings.get(defs.cameraDevice), 'back');
  });

  test('migration runs once: later user choices are not overridden', () async {
    await build({
      'ks.screensaver.dismiss_on_motion': true,
      'ks.motion.camera': 'back',
    });
    await camera().init();
    // The user later disables the camera and flips to front...
    await settings.set(defs.cameraEnabled, false);
    await settings.set(defs.cameraDevice, 'front');
    // ...and a restart (fresh managers, same store) must not re-migrate
    // over that.
    bus = EventBus();
    log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    await camera().init();
    expect(settings.get(defs.cameraEnabled), isFalse);
    expect(settings.get(defs.cameraDevice), 'front');
  });

  test('migration is a no-op without motion detection', () async {
    await build({'ks.motion.camera': 'back'});
    await camera().init();
    expect(settings.get(defs.cameraEnabled), isFalse);
    expect(settings.get(defs.cameraDevice), 'front');
  });

  test('motion detection requires BOTH its switch and the camera', () async {
    await build({'ks.screensaver.dismiss_on_motion': true});
    final motion = MotionManager(bus, commands, log, settings);
    // Camera master switch off: the dismiss switch alone is not enough.
    expect(motion.enabled, isFalse);
    await settings.set(defs.cameraEnabled, true);
    expect(motion.enabled, isTrue);
    await settings.set(defs.screensaverDismissOnMotion, false);
    expect(motion.enabled, isFalse);
  });

  test('importing a pre-Camera backup enables the camera for motion', () async {
    // A configured device (start URL set) restoring an old backup that
    // carries motion detection but predates the camera master switch.
    await build({'ks.browser.start_url': 'http://ha.local:8123'});
    final result = await commands.execute('importConfig', {
      'config': {
        'kind': 'kiosk-satellite-config',
        'version': 1,
        'settings': {
          'screensaver.dismiss_on_motion': true,
          'motion.camera': 'back',
        },
      },
    });
    expect(result.ok, isTrue);
    expect(settings.get(defs.cameraEnabled), isTrue);
    expect(settings.get(defs.cameraDevice), 'back');
  });

  test('motion snapshots fire once per session, not once per tick', () async {
    await build({'ks.camera.enabled': true, 'ks.motion.sensor': true});
    await camera().init();
    // A burst of ticks: someone staying in frame. Only the first is an
    // arrival; the rest land inside the Clear after window and must not
    // refresh the published snapshot (the sensor leg keeps the camera
    // on permanently, so per-tick snapshots would publish forever).
    bus.publish(const MotionDetected());
    bus.publish(const MotionDetected());
    bus.publish(const MotionDetected());
    // Past the capture's deliberate 1s delay; the denied permission then
    // fails each attempt with one warn, which is the countable trace.
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    final attempts = log.recent
        .where((e) => e.message.contains('motion snapshot failed'))
        .length;
    expect(attempts, 1);
  });

  test('a facing change refreshes the frame once the rebind settles', () async {
    await build({'ks.camera.enabled': true});
    await camera().init();
    await settings.set(defs.cameraDevice, 'back');
    // Past the capture's deliberate 1s delay; the denied permission then
    // fails the attempt with one warn, which is the countable trace.
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    final attempts = log.recent
        .where((e) => e.message.contains('facing-change snapshot failed'))
        .length;
    expect(attempts, 1);
  });

  test('a facing change with the camera off captures nothing', () async {
    await build({});
    await camera().init();
    await settings.set(defs.cameraDevice, 'back');
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    expect(
      log.recent.any(
        (e) => e.message.contains('facing-change snapshot failed'),
      ),
      isFalse,
    );
  });

  group('detection snapshot privacy', () {
    late int captures;
    late List<CameraSnapshotTaken> published;
    Completer<Uint8List>? pendingImage;
    Completer<int>? pendingPermission;

    setUp(() {
      captures = 0;
      published = [];
      pendingImage = null;
      pendingPermission = null;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (call) async => call.method == 'checkPermissionStatus'
            ? await (pendingPermission?.future ?? Future.value(1))
            : null,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('kiosk_satellite/camera'),
        (call) async {
          switch (call.method) {
            case 'hasCamera':
              return true;
            case 'facings':
              return ['front', 'back'];
            case 'snapshot':
              captures++;
              return await (pendingImage?.future ??
                  Future.value(Uint8List.fromList([1, 2, 3])));
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('kiosk_satellite/camera'),
            null,
          );
    });

    Future<void> start([Map<String, Object> initial = const {}]) async {
      await build({'ks.camera.enabled': true, ...initial});
      bus.on<CameraSnapshotTaken>().listen(published.add);
      final manager = camera();
      await manager.init();
      addTearDown(() async {
        await manager.dispose();
        await settings.dispose();
        await bus.dispose();
      });
    }

    testWidgets('detections stay available without capturing images', (
      tester,
    ) async {
      await start({'ks.camera.disable_detection_snapshots': true});
      final detections = <AppEvent>[];
      bus.stream.listen(detections.add);
      const events = [
        MotionDetected(),
        FaceDetected(),
        PersonSensorChanged(present: true),
        PalmDetected(hands: 1, fingers: 3),
      ];
      for (final event in events) {
        bus.publish(event);
      }
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(detections, containsAllInOrder(events));
      expect(captures, 0);
      expect(published, isEmpty);
    });

    testWidgets('enabling the switch skips a queued detection capture', (
      tester,
    ) async {
      await start();
      bus.publish(const MotionDetected());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await settings.set(defs.cameraDisableDetectionSnapshots, true);
      await tester.pump(const Duration(seconds: 1));
      expect(captures, 0);
      expect(published, isEmpty);
    });

    testWidgets('permission replies cannot bypass the switch', (tester) async {
      await start();
      pendingPermission = Completer<int>();
      bus.publish(const MotionDetected());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await settings.set(defs.cameraDisableDetectionSnapshots, true);
      pendingPermission!.complete(1);
      await tester.pump();
      expect(captures, 0);
      expect(published, isEmpty);
    });

    testWidgets('an in-flight detection image is withheld', (tester) async {
      await start();
      pendingImage = Completer<Uint8List>();
      bus.publish(const MotionDetected());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(captures, 1);
      await settings.set(defs.cameraDisableDetectionSnapshots, true);
      pendingImage!.complete(Uint8List.fromList([1, 2, 3]));
      await tester.pump();
      expect(published, isEmpty);

      // The discarded result must release the capture for manual requests.
      pendingImage = null;
      expect((await commands.execute('takeCameraSnapshot', {})).ok, isTrue);
      await tester.pump();
      expect(published, hasLength(1));
    });

    testWidgets('manual requests and the continuous schedule keep working', (
      tester,
    ) async {
      await start({
        'ks.camera.snapshots': true,
        'ks.camera.snapshot_interval': 5,
      });
      await tester.pump();
      expect(captures, 1);
      await tester.pump(const Duration(seconds: 2));
      await settings.set(defs.cameraDisableDetectionSnapshots, true);
      await tester.pump();
      expect(captures, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(captures, 2);
      expect((await commands.execute('takeCameraSnapshot', {})).ok, isTrue);
      await tester.pump();
      expect(captures, 3);
      expect(published, hasLength(3));
      await settings.set(defs.cameraSnapshots, false);
      await tester.pump();
    });

    testWidgets('turning the switch off restores detection snapshots', (
      tester,
    ) async {
      await start({'ks.camera.disable_detection_snapshots': true});
      bus.publish(const MotionDetected());
      await tester.pump();
      await settings.set(defs.cameraDisableDetectionSnapshots, false);
      bus.publish(const MotionDetected());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(captures, 1);
      expect(published, hasLength(1));
    });
  });

  test('importing a new backup leaves its camera choice alone', () async {
    await build({'ks.browser.start_url': 'http://ha.local:8123'});
    final result = await commands.execute('importConfig', {
      'config': {
        'kind': 'kiosk-satellite-config',
        'version': 1,
        'settings': {
          'screensaver.dismiss_on_motion': true,
          // The backup explicitly carries the camera off: the user turned
          // it off after the dismiss switch, and the shim must not undo it.
          'camera.enabled': false,
        },
      },
    });
    expect(result.ok, isTrue);
    expect(settings.get(defs.cameraEnabled), isFalse);
  });
}
