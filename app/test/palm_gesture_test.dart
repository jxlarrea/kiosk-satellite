import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/motion/motion_manager.dart';
import 'package:kiosk_satellite/managers/motion/native_motion.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The hand leg of the motion camera (the Show fingers gesture): a hand
/// mapping runs the camera whenever the screen is on, asks the native
/// side for hands and their fingers, and relays its reports as
/// [PalmDetected]; the
/// gesture gates (Lockdown Mode, kiosk Disable Gestures) keep the camera
/// unbound. The camera plugin is mocked at the EventChannel, as in
/// face_detection_test.dart.
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
  late SettingsManager settings;
  late MotionManager motion;

  Future<void> build(Map<String, Object> initial) async {
    listens = 0;
    lastArgs = null;
    sink = null;
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
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

  const palmMapping =
      '[{"id":"p1","trigger":{"type":"fingers","fingers":2},'
      '"action":{"type":"screensaver"}}]';
  const clapMapping =
      '[{"id":"c1","trigger":{"type":"claps","claps":2},'
      '"action":{"type":"screensaver"}}]';

  const handOnly = {
    'ks.gestures.mappings': palmMapping,
    'ks.camera.enabled': true,
  };

  test('a hand mapping runs the camera with the screen on, asking for '
      'hands and nothing else', () async {
    await build(handOnly);
    await pump();
    expect(motion.palmEnabled, isTrue);
    expect(listens, 1);
    expect(lastArgs?['fingers'], isTrue);
    expect(lastArgs?['faces'], isFalse);
    expect(lastArgs?['motion'], isFalse);

    // A dark panel: nobody raises a hand at it.
    bus.publish(const ScreenStateChanged(on: false));
    await pump();
    expect(sink, isNull);
    bus.publish(const ScreenStateChanged(on: true));
    await pump();
    expect(listens, 2);
  });

  test('no hand mapping, no camera; adding one starts it, removing it '
      'stops it', () async {
    await build({
      'ks.gestures.mappings': clapMapping,
      'ks.camera.enabled': true,
    });
    await pump();
    expect(motion.palmEnabled, isFalse);
    expect(listens, 0);

    await settings.setFromJson(defs.gestureMappings.key, palmMapping);
    await pump();
    expect(listens, 1);
    expect(lastArgs?['fingers'], isTrue);

    await settings.setFromJson(defs.gestureMappings.key, clapMapping);
    await pump();
    expect(sink, isNull);
  });

  test('the camera master switch gates it', () async {
    await build({'ks.gestures.mappings': palmMapping});
    await pump();
    expect(motion.palmEnabled, isFalse);
    expect(listens, 0);
  });

  test('a hand report becomes PalmDetected with its hand and finger counts; '
      'a null tick stays motion', () async {
    await build(handOnly);
    await pump();
    final palms = <PalmDetected>[];
    final motions = <MotionDetected>[];
    bus.on<PalmDetected>().listen(palms.add);
    bus.on<MotionDetected>().listen(motions.add);

    sink!.success({'palms': 1, 'fingers': 2});
    await pump();
    expect(palms, hasLength(1));
    expect(palms.single.hands, 1);
    expect(palms.single.fingers, 2);

    sink!.success({'palms': 0, 'fingers': -1});
    await pump();
    expect(palms, hasLength(2));
    expect(palms.last.hands, 0);
    expect(palms.last.fingers, isNull);
    expect(motions, isEmpty);

    sink!.success(null);
    await pump();
    expect(motions, hasLength(1));
  });

  test(
    'Lockdown Mode and kiosk Disable Gestures keep the camera unbound',
    () async {
      await build({...handOnly, 'ks.lockdown.enabled': true});
      await pump();
      expect(motion.palmEnabled, isFalse);
      expect(listens, 0);

      await settings.set(defs.lockdownEnabled, false);
      await pump();
      expect(listens, 1);

      await settings.set(defs.kioskEnabled, true);
      await settings.set(defs.kioskDisableGestures, true);
      await pump();
      expect(sink, isNull);
    },
  );

  test('the sensor leg holding the camera restarts it with hands when a '
      'mapping appears', () async {
    await build({
      'ks.gestures.mappings': clapMapping,
      'ks.camera.enabled': true,
      'ks.motion.sensor': true,
    });
    await pump();
    expect(listens, 1);
    expect(lastArgs?['fingers'], isFalse);

    await settings.setFromJson(defs.gestureMappings.key, palmMapping);
    await pump();
    expect(listens, 2);
    expect(lastArgs?['fingers'], isTrue);
    expect(lastArgs?['motion'], isTrue, reason: 'the sensor still wants ticks');
  });

  test('the wire parses hands and fingers', () {
    expect(NativeMotionTick.fromNative({'palms': 2, 'fingers': 5}).palms, 2);
    expect(NativeMotionTick.fromNative({'palms': 2, 'fingers': 5}).fingers, 5);
    expect(NativeMotionTick.fromNative({'face': 0.3}).isPalms, isFalse);
    expect(NativeMotionTick.fromNative(null).isPalms, isFalse);
  });
}
