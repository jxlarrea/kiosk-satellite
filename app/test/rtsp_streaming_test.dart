import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:kiosk_satellite/managers/audio/mic_hub.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/device_camera/device_camera_manager.dart';
import 'package:kiosk_satellite/managers/motion/motion_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late SettingsManager settings;
  late MotionManager motion;
  late EventBus bus;
  final configurations = <Map>[];
  Map? stream;
  MockStreamHandlerEventSink? sink;
  late CommandRegistry commands;
  final pauses = <bool>[];

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> demand(bool value) async {
    await messenger.handlePlatformMessage(
      'kiosk_satellite/camera/rtsp',
      const StandardMethodCodec().encodeMethodCall(MethodCall('demand', value)),
      (_) {},
    );
    await settle();
  }

  setUp(() async {
    configurations.clear();
    stream = null;
    sink = null;
    pauses.clear();
    messenger.setMockMethodCallHandler(
      const MethodChannel('kiosk_satellite/motion/control'),
      (call) async {
        if (call.method == 'setPaused') {
          pauses.add((call.arguments as Map)['paused'] as bool);
        }
        return null;
      },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (_) async => 1,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('kiosk_satellite/camera/rtsp'),
      (call) async {
        if (call.method == 'configure') {
          configurations.add(call.arguments as Map);
        }
        return {'listening': true};
      },
    );
    messenger.setMockStreamHandler(
      const EventChannel('kiosk_satellite/motion'),
      MockStreamHandler.inline(
        onListen: (args, events) {
          stream = args as Map;
          sink = events;
        },
        onCancel: (_) {
          stream = null;
          sink = null;
        },
      ),
    );
    SharedPreferences.setMockInitialValues({
      'ks.camera.enabled': true,
      'ks.camera.rtsp.enabled': true,
    });
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    motion = MotionManager(
      bus,
      commands,
      log,
      settings,
      selfLightQuiet: Duration.zero,
    );
    await motion.init();
    await settle();
  });

  tearDown(() async {
    await motion.dispose();
    await settings.dispose();
    await bus.dispose();
  });

  Future<void> detectors(int mask) async {
    await settings.set(defs.screensaverEnabled, true);
    await settings.set(defs.motionSensor, mask & 1 != 0);
    await settings.set(defs.screensaverDismissOnFace, mask & 2 != 0);
    await settings.set(defs.screensaverPostponeOnFace, mask & 2 != 0);
    await settings.set(
      defs.gestureMappings,
      jsonEncode([
        if (mask & 4 != 0)
          {
            'id': 'hand',
            'trigger': {'type': 'fingers', 'fingers': 5},
            'action': {'type': 'screensaver_stop'},
          },
      ]),
    );
    await settle();
  }

  for (var mask = 0; mask < 8; mask++) {
    test(
      'detector combination $mask survives viewer joins and departures',
      () async {
        await detectors(mask);
        for (var cycle = 0; cycle < 2; cycle++) {
          await demand(true);
          expect(stream?['rtsp'], true);
          expect(stream?['motion'], mask & 1 != 0);
          expect(stream?['faces'], mask & 2 != 0);
          expect(stream?['fingers'], mask & 4 != 0);
          await demand(false);
          if (mask == 0) {
            expect(stream, isNull);
          } else {
            expect(stream?['rtsp'], false);
            expect(stream?['motion'], mask & 1 != 0);
            expect(stream?['faces'], mask & 2 != 0);
            expect(stream?['fingers'], mask & 4 != 0);
          }
        }
      },
    );
  }

  test(
    'native motion, face and hand events still reach consumers across RTSP transitions',
    () async {
      await detectors(7);
      final events = <AppEvent>[];
      final subscription = bus.stream.listen(events.add);
      for (final viewing in [true, false, true]) {
        await demand(viewing);
        events.clear();
        sink!.success({'motion': true});
        sink!.success({'face': 0.5});
        sink!.success({'palms': 1, 'fingers': 5});
        await settle();
        expect(events.whereType<MotionDetected>(), hasLength(1));
        expect(events.whereType<FaceDetected>(), hasLength(1));
        expect(events.whereType<PalmDetected>().single.fingers, 5);
      }
      await subscription.cancel();
    },
  );

  test(
    'screen sleep and gesture suppression retain RTSP and restore detection on wake',
    () async {
      await detectors(7);
      await demand(true);
      bus.publish(const ScreenStateChanged(on: false));
      await settle();
      expect(stream?['rtsp'], true);
      expect(stream?['motion'], true);
      // The motion sensor keeps analysis open, including the face leg.
      expect(stream?['faces'], true);
      expect(stream?['fingers'], false);
      bus.publish(const ScreenStateChanged(on: true));
      await settle();
      expect(stream?['faces'], true);
      expect(stream?['fingers'], true);
      await settings.set(defs.lockdownEnabled, true);
      await settle();
      expect(stream?['rtsp'], true);
      expect(stream?['motion'], true);
      expect(stream?['faces'], true);
      expect(stream?['fingers'], false);
      await settings.set(defs.lockdownEnabled, false);
      await settle();
      expect(stream?['fingers'], true);
    },
  );

  test(
    'snapshot privacy and viewer changes preserve manual capture and all detectors',
    () async {
      var captures = 0;
      final published = <CameraSnapshotTaken>[];
      messenger.setMockMethodCallHandler(
        const MethodChannel('kiosk_satellite/camera'),
        (call) async {
          if (call.method == 'hasCamera') return true;
          if (call.method == 'facings') return ['front'];
          if (call.method == 'snapshot') {
            captures++;
            return Uint8List.fromList([1, 2, 3]);
          }
          return null;
        },
      );
      final camera = DeviceCameraManager(bus, commands, Logger(), settings);
      await camera.init();
      final subscription = bus.on<CameraSnapshotTaken>().listen(published.add);
      try {
        await detectors(7);
        await settings.set(defs.cameraDisableDetectionSnapshots, true);
        for (final viewing in [false, true, false]) {
          await demand(viewing);
          final before = captures;
          bus.publish(const MotionDetected());
          bus.publish(const FaceDetected());
          bus.publish(const PalmDetected(hands: 1, fingers: 5));
          await settle();
          expect(captures, before);
          expect((await commands.execute('takeCameraSnapshot', {})).ok, true);
          await settle();
          expect(captures, before + 1);
          expect(stream?['motion'], true);
          expect(stream?['faces'], true);
          expect(stream?['fingers'], true);
        }
        expect(published, hasLength(3));
      } finally {
        await camera.dispose();
        await subscription.cancel();
        messenger.setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/camera'),
          null,
        );
      }
    },
  );

  test(
    'voice turns pause detection without interrupting RTSP and resume after a rebind',
    () async {
      await detectors(7);
      await demand(true);
      bus.publish(const WakeWordDetected(model: 'test', phrase: 'test'));
      await settle();
      expect(pauses, [true]);
      expect(stream?['rtsp'], true);
      await settings.set(defs.motionSensitivity, 80);
      await settle();
      expect(stream?['paused'], true);
      expect(stream?['rtsp'], true);
      final faces = <FaceDetected>[];
      final subscription = bus.on<FaceDetected>().listen(faces.add);
      sink!.success({'face': 0.5});
      await settle();
      expect(faces, isEmpty);
      bus.publish(const WakeWordStateChanged(active: true, listening: true));
      await settle();
      expect(pauses.last, false);
      sink!.success({'face': 0.5});
      await settle();
      expect(faces, hasLength(1));
      expect(stream?['rtsp'], true);
      await subscription.cancel();
    },
  );

  test(
    'Activity replacement restores detectors and accepts fresh viewer demand',
    () async {
      await detectors(7);
      await demand(true);
      sink!.error(code: 'detached', message: 'Activity replaced');
      await settle();
      expect(stream, isNull);
      bus.publish(const ActivityAttached());
      await settle();
      expect(stream?['motion'], true);
      expect(stream?['faces'], true);
      expect(stream?['fingers'], true);
      expect(stream?['rtsp'], false);
      await demand(true);
      expect(stream?['rtsp'], true);
      expect(stream?['fingers'], true);
    },
  );

  test(
    'camera revocation while dark recovers detection and RTSP on wake',
    () async {
      await detectors(7);
      await demand(true);
      bus.publish(const ScreenStateChanged(on: false));
      await settle();
      sink!.error(code: 'camera', message: 'Camera revoked');
      await settle();
      expect(stream, isNull);
      bus.publish(const ScreenStateChanged(on: true));
      await settle();
      expect(stream?['rtsp'], true);
      expect(stream?['motion'], true);
      expect(stream?['faces'], true);
      expect(stream?['fingers'], true);
    },
  );

  test(
    'audio is opt in and stays captured through mute and Lockdown Mode',
    () async {
      final hub = MicHub.instance;
      final previous = hub.opener;
      var opens = 0;
      final mic = StreamController<Uint8List>();
      hub.opener = () {
        opens++;
        return mic.stream;
      };
      Future<void> audioDemand(bool value) async {
        await messenger.handlePlatformMessage(
          'kiosk_satellite/camera/rtsp',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('audioDemand', value),
          ),
          (_) {},
        );
        await settle();
      }

      try {
        expect(configurations.last['audio'], false);
        await audioDemand(true);
        expect(opens, 0);
        await settings.set(defs.cameraRtspAudio, true);
        await settle();
        await audioDemand(true);
        expect(opens, 1);
        bus.publish(
          const WakeWordStateChanged(
            active: true,
            listening: false,
            muted: true,
          ),
        );
        await settings.set(defs.lockdownEnabled, true);
        await settle();
        expect(hub.capturing, true);
        await audioDemand(false);
        expect(hub.capturing, false);
      } finally {
        await audioDemand(false);
        hub.opener = previous;
        await mic.close();
      }
    },
  );

  test(
    'listener is idle until demand and releases the camera after the last viewer',
    () async {
      expect(configurations.last['enabled'], true);
      expect(stream, isNull);
      await demand(true);
      expect(stream?['rtsp'], true);
      expect(stream?['motion'], false);
      expect(stream?['faces'], false);
      expect(stream?['fingers'], false);
      bus.publish(const ScreenStateChanged(on: false));
      await settle();
      expect(stream?['rtsp'], true);
      await demand(false);
      expect(stream, isNull);
    },
  );

  test(
    'motion rate stays independent and survives the last viewer leaving',
    () async {
      await settings.set(defs.motionSensor, true);
      await settle();
      await demand(true);
      expect(stream?['fps'], 2.0);
      expect(stream?['motion'], true);
      expect(stream?['rtsp'], true);
      await demand(false);
      expect(stream?['motion'], true);
      expect(stream?['rtsp'], false);
    },
  );

  test(
    'streaming leaves dismiss-only analysis idle until the screensaver starts',
    () async {
      await settings.set(defs.screensaverDismissOnMotion, true);
      await settle();
      await demand(true);
      expect(stream?['motion'], false);
      bus.publish(const ScreensaverStateChanged(active: true));
      await settle();
      expect(stream?['motion'], true);
      expect(stream?['rtsp'], true);
    },
  );

  test(
    'camera master stops streaming and stale demand cannot reopen it',
    () async {
      await demand(true);
      await settings.set(defs.cameraEnabled, false);
      await settle();
      expect(configurations.last['enabled'], false);
      expect(stream, isNull);
      await demand(true);
      expect(stream, isNull);
    },
  );

  test('subpage gates controls and keeps credentials secret', () async {
    await settings.set(defs.cameraRtspEnabled, false);
    expect(settings.visible(defs.cameraRtspEnabled), true);
    expect(settings.visible(defs.cameraRtspPort), false);
    await settings.set(defs.cameraRtspEnabled, true);
    expect(settings.visible(defs.cameraRtspPort), true);
    expect(settings.visible(defs.cameraRtspUsername), false);
    await settings.set(defs.cameraRtspAuth, true);
    expect(settings.visible(defs.cameraRtspUsername), true);
    expect(defs.cameraRtspPassword.secret, true);
    expect(
      defs.allSettings.indexOf(defs.cameraRtspEnabled),
      greaterThan(defs.allSettings.indexOf(defs.motionStartDelay)),
    );
    expect(defs.validateRtspPort(8554), isNull);
    expect(defs.validateRtspPort(8554.5), isNotNull);
    expect(defs.validateRtspPort(65536), isNotNull);
    expect(defs.validateRtspUsername('bad:user'), isNotNull);
  });
}
