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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late SettingsManager settings;
  late MotionManager motion;
  late EventBus bus;
  final configurations = <Map>[];
  Map? stream;

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
        onListen: (args, events) => stream = args as Map,
        onCancel: (_) => stream = null,
      ),
    );
    SharedPreferences.setMockInitialValues({
      'ks.camera.enabled': true,
      'ks.camera.rtsp.enabled': true,
    });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    motion = MotionManager(bus, commands, log, settings);
    await motion.init();
    await settle();
  });

  tearDown(() async {
    await motion.dispose();
    await bus.dispose();
  });

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
