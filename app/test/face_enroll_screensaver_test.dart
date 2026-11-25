import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/ground_control/face_enroll.dart';
import 'package:kiosk_satellite/managers/motion/motion_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A face capture started from Ground Control while the screensaver is up:
/// the screensaver goes, with its dimmed brightness, and stays away until
/// the capture ends.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('kiosk_satellite/motion/control'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => switch (call.method) {
        'checkPermissionStatus' => 1,
        _ => null,
      },
    );
    messenger.setMockStreamHandler(
      const EventChannel('kiosk_satellite/motion'),
      MockStreamHandler.inline(onListen: (arguments, events) {}),
    );
  });

  test('a face capture dismisses and holds the screensaver until it '
      'ends', () async {
    SharedPreferences.setMockInitialValues({
      'ks.camera.enabled': true,
      'ks.ground_control.enabled': true,
      'ks.vision_match.enabled': true,
      'ks.vision_match.face_detection': true,
      'ks.vision_match.face_recognition': true,
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final calls = <String>[];
    for (final name in ['holdScreensaver', 'stopScreensaver', 'bringToFront']) {
      commands.register(
        Command(
          name: name,
          description: name,
          handler: (p) async {
            calls.add(
              name == 'holdScreensaver'
                  ? '$name ${p['holder']} ${p['held']}'
                  : name,
            );
            return const CommandResult.ok();
          },
        ),
      );
    }
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    final motion = MotionManager(bus, commands, log, settings);
    await motion.init();

    // A Ground Control that takes the socket and closes it when told: the
    // capture then ends as lost.
    final hangUp = Completer<void>();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((_) {});
      await hangUp.future;
      await socket.close();
    });
    addTearDown(() => server.close(force: true));
    bus.publish(GroundControlServiceChanged('http://127.0.0.1:${server.port}'));
    await Future<void>.delayed(Duration.zero);

    bus.publish(const FaceEnrollRequested(personId: 'p1', name: 'Mia'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(calls, [
      'holdScreensaver face_enroll true',
      'stopScreensaver',
      'bringToFront',
    ]);
    expect(motion.faceEnrollment.value?.active, isTrue);

    hangUp.complete();

    for (var i = 0; i < 100 && motion.faceEnrollment.value!.active; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(motion.faceEnrollment.value?.phase, FaceEnrollPhase.failed);
    expect(calls.last, 'holdScreensaver face_enroll false');
    await motion.dispose();
  });
}
