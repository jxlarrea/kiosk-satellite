import 'dart:async';

import 'package:permission_handler/permission_handler.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../../core/permissions.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'native_motion.dart';

/// Camera-based motion detection.
///
/// The optimisation that keeps this off the CPU is deciding *when* to look, not
/// just how: the camera runs only while the screensaver is showing. That is the
/// only moment motion matters on a kiosk — someone approaching a dimmed screen —
/// so during normal use the camera is not bound at all. The native side
/// ([native_motion.dart] → `CameraMotion.kt`) does the frame-diffing on the YUV
/// luminance plane at a configurable low frame rate and emits a rate-limited
/// tick; here we translate that to [MotionDetected], which the screensaver
/// consumes to wake (when "dismiss on motion" is on) and the JS API / remote
/// admin observe.
class MotionManager extends Manager {
  MotionManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'motion';

  bool get enabled => _settings.get(defs.motionEnabled);

  StreamSubscription<void>? _camera;
  bool _screensaverActive = false;
  bool _starting = false;

  @override
  Future<void> init() async {
    bus.on<ScreensaverStateChanged>().listen((e) {
      _screensaverActive = e.active;
      _sync();
    });
    // A tuning change (fps / sensitivity / camera) restarts the stream so the
    // native analyzer picks up the new arguments; toggling detection on prompts
    // for the camera up front so the first dim can start it without a pause.
    bus.on<SettingChanged>().listen((e) {
      if (!e.key.startsWith('motion.')) return;
      if (e.key == defs.motionEnabled.key && enabled) {
        unawaited(_ensurePermission());
      }
      _stop();
      _sync();
    });

    commands.register(Command(
      name: 'getMotionEnabled',
      description: 'Whether camera motion detection is enabled',
      handler: (_) async => CommandResult.ok(enabled),
    ));

    if (enabled) unawaited(_ensurePermission());
  }

  void _sync() {
    final shouldRun = enabled && _screensaverActive;
    if (shouldRun) {
      unawaited(_start());
    } else {
      _stop();
    }
  }

  Future<void> _start() async {
    if (_camera != null || _starting) return;
    _starting = true;
    try {
      if (!await _ensurePermission()) {
        log.warn(name, 'camera permission not granted; motion detection idle');
        return;
      }
      // State may have flipped while awaiting the permission check.
      if (!(enabled && _screensaverActive) || _camera != null) return;
      final fps = _settings.get(defs.motionFps).toDouble().clamp(0.5, 30.0);
      final sensitivity =
          _settings.get(defs.motionSensitivity).toInt().clamp(1, 100);
      final camera = _settings.get(defs.motionCamera);
      log.info(name, 'camera on (fps=$fps sensitivity=$sensitivity cam=$camera)');
      _camera = NativeMotion.stream(
        fps: fps,
        sensitivity: sensitivity,
        camera: camera,
      ).listen(
        (_) {
          log.debug(name, 'motion');
          bus.publish(const MotionDetected());
        },
        onError: (Object e) => log.warn(name, 'camera error: $e'),
      );
    } finally {
      _starting = false;
    }
  }

  void _stop() {
    if (_camera == null) return;
    _camera!.cancel();
    _camera = null;
    log.info(name, 'camera off');
  }

  Future<bool> _ensurePermission() async {
    if (await Permission.camera.isGranted) return true;
    return await ensureOsPermission(Permission.camera);
  }

  @override
  Future<void> dispose() async {
    _stop();
  }
}
