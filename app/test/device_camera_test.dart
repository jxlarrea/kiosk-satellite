import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/device_camera/device_camera_manager.dart';
import 'package:kiosk_satellite/managers/device_camera/native_camera.dart';
import 'package:kiosk_satellite/managers/motion/motion_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('camera defaults: off, front, medium, no snapshots, 60s interval',
      () async {
    await build({});
    expect(settings.get(defs.cameraEnabled), isFalse);
    expect(settings.get(defs.cameraDevice), 'front');
    expect(settings.get(defs.cameraSnapshotResolution), 'medium');
    expect(settings.get(defs.cameraSnapshots), isFalse);
    expect(settings.get(defs.cameraSnapshotInterval), 60);
  });

  test('each resolution tier maps to its capture target', () {
    expect(snapshotResolution('low'), (640, 480));
    expect(snapshotResolution('medium'), (1280, 960));
    expect(snapshotResolution('high'), (1920, 1440));
    // An unknown stored value (a downgrade, a hand-edited import) must
    // fall back to the default tier, not crash the capture path.
    expect(snapshotResolution('nonsense'), (1280, 960));
  });

  test('migration: a device using motion detection keeps it working',
      () async {
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

  test('migration runs once: later user choices are not overridden',
      () async {
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

  test('importing a pre-Camera backup enables the camera for motion',
      () async {
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
