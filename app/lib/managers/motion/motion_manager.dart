import 'dart:async';

import 'package:permission_handler/permission_handler.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../../core/permissions.dart';
import '../device_camera/native_camera.dart' show snapshotResolution;
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
///
/// "Postpone on motion" (discussion #126) is the deliberate exception to that
/// optimisation: opted in, the camera ALSO runs while the screensaver is away,
/// so nearby movement can keep resetting the idle timer and the screensaver
/// never starts over someone actually using the room. The cost warning lives
/// on the setting; the one gate kept here regardless is the screen being on —
/// a panel someone turned off has no screensaver to postpone, and a camera
/// burning CPU behind a dark screen would be the worst version of the trade.
class MotionManager extends Manager {
  MotionManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'motion';

  /// Motion detection needs the screensaver's "dismiss on motion" switch AND
  /// the Camera section's master switch: the camera choice lives there, and a
  /// disabled camera means no camera feature runs, this one included. The
  /// dismiss switch keeps its value while the camera is off, so re-enabling
  /// the camera brings motion detection back without re-setup. An active
  /// schedule entry's motion override (issue #89) stands in for the dismiss
  /// switch while it holds — a Black entry overnight can keep the camera off
  /// entirely.
  bool get enabled =>
      (_schedulePolicy ??
          _settings.get(defs.screensaverDismissOnMotion)) &&
      _settings.get(defs.cameraEnabled);

  /// Whether the postpone leg wants the camera: between screensavers, with
  /// the screen actually lit, on a device whose screensaver can start at
  /// all. Rides on Dismiss on motion — the postpone switch is an extension
  /// of it (hidden and inert without it), never a second way to turn
  /// motion detection on. The raw switch, not [_schedulePolicy]: schedule
  /// overrides are session-scoped and this leg runs between sessions.
  bool get _postponeEnabled =>
      _settings.get(defs.screensaverPostponeOnMotion) &&
      _settings.get(defs.screensaverDismissOnMotion) &&
      _settings.get(defs.screensaverEnabled) &&
      _settings.get(defs.cameraEnabled);

  StreamSubscription<void>? _camera;
  bool _screensaverActive = false;
  bool _screenOn = true;
  bool _starting = false;

  /// The screensaver schedule's motion override, null when none holds.
  bool? _schedulePolicy;

  @override
  Future<void> init() async {
    bus.on<ScreensaverStateChanged>().listen((e) {
      _screensaverActive = e.active;
      _sync();
    });
    // Session start publishes the policy before the active event above, and
    // boundary crossings mid-session publish on their own — either way the
    // camera starts or stops to match within a tick.
    bus.on<ScreensaverMotionPolicyChanged>().listen((e) {
      _schedulePolicy = e.dismissOnMotion;
      _sync();
    });
    // The postpone leg follows the panel: a screen someone turned off has
    // no screensaver worth holding back, so the camera goes with it.
    bus.on<ScreenStateChanged>().listen((e) {
      _screenOn = e.on;
      _sync();
    });
    // A tuning change (fps / sensitivity / the Camera section's camera pick)
    // restarts the stream so the native analyzer picks up the new arguments;
    // turning the feature on prompts for the camera up front so the first dim
    // can start it without a pause.
    bus.on<SettingChanged>().listen((e) {
      final isGate = e.key == defs.screensaverDismissOnMotion.key ||
          e.key == defs.screensaverPostponeOnMotion.key ||
          e.key == defs.screensaverEnabled.key ||
          e.key == defs.cameraEnabled.key;
      if (!isGate &&
          !e.key.startsWith('motion.') &&
          e.key != defs.cameraDevice.key &&
          // The pre-bound snapshot capture is sized at bind time; a new
          // resolution needs a rebind to take effect mid-screensaver.
          e.key != defs.cameraSnapshotResolution.key) {
        return;
      }
      if (isGate && (enabled || _postponeEnabled)) {
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

    if (enabled || _postponeEnabled) unawaited(_ensurePermission());

    // Seed the panel state from reality (a device that boots with its
    // screen already off must not bind the camera) and let the postpone
    // leg start if it is due. Best-effort: a failure leaves the default
    // and the next ScreenStateChanged corrects it.
    final on = await commands.execute('isScreenOn', const {});
    if (on.ok && on.data is bool) _screenOn = on.data as bool;
    _sync();
  }

  /// Whether the camera should be running right now: dismiss-on-motion
  /// wants it during a screensaver session, postpone-on-motion between
  /// them (screen on). Both on means it simply never stops.
  bool get _shouldRun => _screensaverActive
      ? enabled
      : _postponeEnabled && _screenOn;

  void _sync() {
    if (_shouldRun) {
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
      if (!_shouldRun || _camera != null) return;
      final fps = _settings.get(defs.motionFps).toDouble().clamp(0.5, 30.0);
      final sensitivity =
          _settings.get(defs.motionSensitivity).toInt().clamp(1, 100);
      final camera = _settings.get(defs.cameraDevice);
      final (snapW, snapH) =
          snapshotResolution(_settings.get(defs.cameraSnapshotResolution));
      log.info(name, 'camera on (fps=$fps sensitivity=$sensitivity cam=$camera)');
      _camera = NativeMotion.stream(
        fps: fps,
        sensitivity: sensitivity,
        camera: camera,
        snapshotWidth: snapW,
        snapshotHeight: snapH,
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
