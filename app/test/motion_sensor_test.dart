import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/motion/motion_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The standalone motion sensor leg: "Motion sensor" (Camera > Motion
/// Detection) runs the camera on its own, with no screensaver switches and
/// no screen-state gate, feeding the MQTT binary_sensor. The camera plugin
/// is mocked at the EventChannel, so a test can see the stream being
/// listened to (the camera "running") and push motion ticks through it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var listens = 0;
  MockStreamHandlerEventSink? sink;

  setUpAll(() {
    // Camera permission granted, so _start reaches the stream.
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
          sink = events;
        },
        onCancel: (arguments) => sink = null,
      ),
    );
  });

  late EventBus bus;
  late SettingsManager settings;
  late MotionManager motion;

  Future<void> build(
    Map<String, Object> initial, {
    Duration selfLightQuiet = const Duration(milliseconds: 2500),
    Duration retryFloor = const Duration(milliseconds: 100),
  }) async {
    listens = 0;
    sink = null;
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    motion = MotionManager(bus, commands, log, settings,
        selfLightQuiet: selfLightQuiet, retryFloor: retryFloor);
    await motion.init();
  }

  /// Lets the channel plumbing (mock stream listen/cancel, event delivery)
  /// and the bus deliver.
  Future<void> pump() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('the sensor leg runs the camera alone, screen off included', () async {
    await build({
      'ks.camera.enabled': true,
      'ks.motion.sensor': true,
      // Deliberately no screensaver switches: the sensor stands alone.
      // Zero quiet window: this test's tick follows a screen-state event,
      // and the self-light gate has its own test below.
    }, selfLightQuiet: Duration.zero);
    await pump();
    expect(listens, 1, reason: 'the camera must run for the sensor');
    // The screensaver legs stay off: the sensor toggle is not a third
    // way into dismiss/postpone.
    expect(motion.enabled, isFalse);

    // A dark panel is the sensor's headline use (motion wakes it via an
    // HA automation), so the screen going off must NOT stop the camera.
    bus.publish(const ScreenStateChanged(on: false));
    await pump();
    expect(sink, isNotNull, reason: 'screen off must not stop the camera');

    // A native motion tick surfaces as the bus event MQTT publishes.
    var detected = 0;
    bus.on<MotionDetected>().listen((_) => detected++);
    sink!.success(null);
    await pump();
    expect(detected, 1);
  });

  test('without the toggle (or the camera master) nothing runs', () async {
    await build({'ks.camera.enabled': true});
    await pump();
    expect(listens, 0);

    await build({'ks.motion.sensor': true});
    await pump();
    expect(listens, 0,
        reason: 'a disabled camera means no camera feature runs');
  });

  test('own light changes (screensaver transitions) suppress motion ticks',
      () async {
    await build(
      {'ks.camera.enabled': true, 'ks.motion.sensor': true},
      selfLightQuiet: const Duration(milliseconds: 200),
    );
    await pump();
    expect(listens, 1);
    var detected = 0;
    bus.on<MotionDetected>().listen((_) => detected++);

    // The screensaver starting relights the room with the app's own
    // display; the tick the camera then produces is that light bouncing
    // back (plus the AE resettle), not a body. Unsuppressed, it dismisses
    // the screensaver the instant it starts, forever.
    bus.publish(const ScreensaverStateChanged(active: true));
    await pump();
    sink!.success(null);
    await pump();
    expect(detected, 0, reason: 'the transition must not read as motion');

    // Past the quiet window the same tick is a body again.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    sink!.success(null);
    await pump();
    expect(detected, 1);

    // A slideshow swapping photos mid-session relights the room the same
    // way (a dark-to-bright Immich slide) and gates the same way.
    bus.publish(const ScreensaverSlideChanged());
    await pump();
    sink!.success(null);
    await pump();
    expect(detected, 1, reason: 'the slide swap must not read as motion');
  });

  test('a camera revoked mid-session (stream error) is rebound after the '
      'backoff', () async {
    await build({
      'ks.camera.enabled': true,
      'ks.motion.sensor': true,
    });
    await pump();
    expect(listens, 1);

    // The OS revoking the camera (the panel powering off, another app
    // taking the sensor) surfaces as a stream error from the native side.
    sink!.error(code: 'camera', message: 'camera revoked by the OS (error 6)');
    await pump();
    expect(sink, isNull, reason: 'the dead session must be torn down');
    expect(listens, 1, reason: 'no immediate rebind: the revoker may still '
        'hold the camera');

    await Future<void>.delayed(const Duration(milliseconds: 150));
    await pump();
    expect(listens, 2, reason: 'the backoff timer must rebind');
  });

  test('revoked with the screen off, the rebind waits for the screen',
      () async {
    await build({
      'ks.camera.enabled': true,
      'ks.motion.sensor': true,
    });
    await pump();
    expect(listens, 1);

    // The panel powers off; five seconds later the OS revokes the camera
    // (measured on Android 16). Rebinding under a dark panel would be
    // refused the same way, so nothing should be scheduled.
    bus.publish(const ScreenStateChanged(on: false));
    await pump();
    sink!.error(code: 'camera', message: 'camera revoked by the OS (error 6)');
    await pump();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await pump();
    expect(listens, 1, reason: 'no rebind attempts against a dark panel');

    // The screen coming back is the moment a rebind can work.
    bus.publish(const ScreenStateChanged(on: true));
    await pump();
    expect(listens, 2, reason: 'screen on must rebind the sensor camera');
  });

  test('a camera bound under a dark panel is restarted on wake', () async {
    await build({'ks.camera.enabled': true});
    await pump();
    expect(listens, 0);

    // The panel is already off when the sensor comes on (a relaunch racing
    // a screen-off does the same): the bind happens blind. One UI rejects
    // that open with "disabled by policy" and CameraX parks the session
    // with no error and no frames, so the app cannot tell a dead bind
    // from a quiet room.
    bus.publish(const ScreenStateChanged(on: false));
    await pump();
    await settings.set(defs.motionSensor, true);
    await pump();
    expect(listens, 1, reason: 'the sensor leg binds even under a dark panel');

    // No frame arrived while the panel was off, so the session is suspect
    // and the wake must restart it.
    bus.publish(const ScreenStateChanged(on: true));
    await pump();
    expect(listens, 2, reason: 'a blind bind must be restarted on wake');
  });

  test('a motion tick clears the blind-bind suspicion', () async {
    await build({'ks.camera.enabled': true}, selfLightQuiet: Duration.zero);
    await pump();
    bus.publish(const ScreenStateChanged(on: false));
    await pump();
    await settings.set(defs.motionSensor, true);
    await pump();
    expect(listens, 1);

    // Older Android opens the camera fine under a dark panel; a motion
    // tick is the proof the session is live, so the wake must leave it
    // alone instead of blipping a working sensor.
    sink!.success(null);
    await pump();
    bus.publish(const ScreenStateChanged(on: true));
    await pump();
    expect(listens, 1, reason: 'a session that framed while off is healthy');
  });

  test('the off_delay is MQTT-side only: changing it never restarts the '
      'camera', () async {
    await build({
      'ks.camera.enabled': true,
      'ks.motion.sensor': true,
    });
    await pump();
    expect(listens, 1);

    await settings.set(defs.motionSensorOffDelay, 120);
    await pump();
    expect(listens, 1,
        reason: 'off_delay lives in the HA discovery config, not the '
            'camera session');

    // A real tuning change by contrast does restart the stream.
    await settings.set(defs.motionFps, 5);
    await pump();
    expect(listens, 2);
  });
}
