import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/device_camera/device_camera_manager.dart';
import 'package:kiosk_satellite/managers/motion/motion_manager.dart';
import 'package:kiosk_satellite/managers/motion/vision_support.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The vision runtimes' floor (issue #331): on Android 7 neither LiteRT
/// (face detection) nor MediaPipe (Show fingers) can load, and the first
/// face run used to take the process down. The native side now answers
/// `visionSupport` over the background bridge; the motion manager keeps
/// the legs off, logs why once, and the camera manager relays the answer
/// to the settings surfaces.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var listens = 0;
  Map<Object?, Object?>? lastArgs;
  Map<String, Object?>? nativeAnswer;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/background'),
          (call) async => switch (call.method) {
            'visionSupport' => nativeAnswer,
            _ => null,
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/motion/control'),
          (call) async => null,
        );
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
            },
            onCancel: (arguments) {},
          ),
        );
  });

  late EventBus bus;
  late CommandRegistry commands;
  late Logger log;
  late SettingsManager settings;
  late MotionManager motion;

  Future<void> build(Map<String, Object> initial) async {
    VisionSupport.reset();
    listens = 0;
    lastArgs = null;
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    log = Logger();
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
  }

  Future<void> pump() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Iterable<String> warnings() => log.recent
      .where((e) => e.level == LogLevel.warn && e.tag == 'motion')
      .map((e) => e.message);

  const android7 = {
    'faces': false,
    'hands': false,
    'hint': 'Not available on this Android version.',
  };

  const faceOnly = {
    'ks.screensaver.dismiss_on_face': true,
    'ks.screensaver.dismiss_on_motion': false,
    'ks.camera.enabled': true,
  };

  const palmMapping =
      '[{"id":"p1","trigger":{"type":"fingers","fingers":2},'
      '"action":{"type":"screensaver"}}]';

  test('Android 7: the face leg stays idle, the camera never binds for '
      'it, and the log says why once', () async {
    nativeAnswer = android7;
    await build(faceOnly);
    await pump();
    expect(motion.faceEnabled, isFalse);
    expect(
      warnings(),
      contains(
        'face detection cannot run here (Not available on this Android '
        'version.) so Dismiss on face stays idle',
      ),
    );

    bus.publish(const ScreensaverStateChanged(active: true));
    await pump();
    expect(listens, 0, reason: 'no leg wants the camera');
    bus.publish(const ScreensaverStateChanged(active: false));
    bus.publish(const ScreensaverStateChanged(active: true));
    await pump();
    expect(warnings().length, 1, reason: 'one line, not one per sync');
  });

  test('Android 7: a Show fingers mapping does not bind the camera; the '
      'other legs are untouched', () async {
    nativeAnswer = android7;
    await build({
      'ks.gestures.mappings': palmMapping,
      'ks.camera.enabled': true,
      'ks.screensaver.dismiss_on_motion': true,
    });
    await pump();
    expect(motion.palmEnabled, isFalse);
    expect(listens, 0);
    expect(
      warnings(),
      contains(
        'hand detection cannot run here (Not available on this Android '
        'version.) so Show fingers gestures stay idle',
      ),
    );

    // Dismiss on motion needs no runtime: the screensaver still binds
    // the camera, asking for motion alone.
    bus.publish(const ScreensaverStateChanged(active: true));
    await pump();
    expect(listens, 1);
    expect(lastArgs?['motion'], isTrue);
    expect(lastArgs?['faces'], isFalse);
    expect(lastArgs?['fingers'], isFalse);
  });

  test('Android 8 and newer: both legs run as before', () async {
    nativeAnswer = {'faces': true, 'hands': true};
    await build({...faceOnly, 'ks.gestures.mappings': palmMapping});
    await pump();
    expect(motion.faceEnabled, isTrue);
    expect(motion.palmEnabled, isTrue);
    expect(listens, 1, reason: 'the hand leg binds with the screen on');
    expect(lastArgs?['fingers'], isTrue);
    expect(warnings(), isEmpty);
  });

  test('no native answer counts as supported, and is asked again', () async {
    nativeAnswer = null;
    await build(faceOnly);
    await pump();
    expect(motion.faceEnabled, isTrue);
    bus.publish(const ScreensaverStateChanged(active: true));
    await pump();
    expect(listens, 1);
    expect(lastArgs?['faces'], isTrue);
    expect(warnings(), isEmpty);
  });

  test('the camera manager relays the answer to the settings surfaces '
      'and the remote admin', () async {
    nativeAnswer = android7;
    await build({});
    final camera = DeviceCameraManager(bus, commands, log, settings);
    await camera.init();
    await pump();
    expect(camera.facesKnownUnsupported, isTrue);
    expect(camera.handsKnownUnsupported, isTrue);
    expect(camera.visionHint, 'Not available on this Android version.');
    final answer = await commands.execute('getVisionSupport', const {});
    expect(answer.ok, isTrue);
    expect(answer.data, {
      'faces': false,
      'hands': false,
      'hint': 'Not available on this Android version.',
    });
  });

  test(
    'the camera manager never disables a row on an unknown answer',
    () async {
      nativeAnswer = null;
      await build({});
      final camera = DeviceCameraManager(bus, commands, log, settings);
      await camera.init();
      await pump();
      expect(camera.facesKnownUnsupported, isFalse);
      expect(camera.handsKnownUnsupported, isFalse);
      expect(camera.visionHint, isNull);
      final answer = await commands.execute('getVisionSupport', const {});
      expect(answer.data, {'faces': true, 'hands': true});
    },
  );
}
