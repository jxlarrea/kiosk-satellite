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
///
/// The "Motion sensor" leg (Camera section) is the third and least gated:
/// motion as its own MQTT binary_sensor, independent of the screensaver
/// features. It ignores even the screen-on gate above, and a truly
/// powered-off panel is its headline use: an already-open session now
/// survives screen-off because the background listening service carries the
/// camera foreground type (WakeWordService), the exemption newer Android
/// gates on — without it the OS revokes within seconds of the panel going
/// dark (measured on Android 16). Not every vendor honors the exemption:
/// One UI 11 (issue #271) suspends the session seconds after screen-off
/// regardless, and silently, so the native side runs a frame watchdog that
/// reports the suspension as a stream error. On such hardware motion
/// through a truly dark panel simply cannot work, and the Black screensaver
/// is the answer. What no version allows is *opening* the camera under a
/// dark panel, so binds are the fragile edge, not open sessions: a
/// revocation is reported as a stream error and [_onCameraLost] rebinds on
/// the next screen-on, and a bind that happened while the panel was off is
/// treated as suspect and restarted on wake (see [_boundBlind]). The cost
/// warning lives on its setting too.
class MotionManager extends Manager {
  MotionManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    this._selfLightQuiet = const Duration(milliseconds: 2500),
    this._retryFloor = const Duration(seconds: 5),
  });

  final SettingsManager _settings;

  /// How long motion ticks are suppressed after the app relights the room
  /// itself (screensaver transitions, screen power, brightness). The
  /// native analyzer rejects lighting-shaped change, but the transition
  /// plus the AE resettle that follows it takes a few analyzed frames to
  /// look like lighting again; this window covers them. Injectable for
  /// tests only.
  final Duration _selfLightQuiet;

  /// Motion ticks before this instant are the app's own light change
  /// bouncing off the room, not a body.
  DateTime _quietUntil = DateTime.fromMillisecondsSinceEpoch(0);

  void _selfLit() {
    _quietUntil = DateTime.now().add(_selfLightQuiet);
  }

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

  /// Whether the standalone MQTT sensor wants the camera: whenever it is
  /// on. No screensaver or screen-state gates (see the class comment).
  bool get _sensorEnabled =>
      _settings.get(defs.motionSensor) && _settings.get(defs.cameraEnabled);

  StreamSubscription<void>? _camera;
  bool _screensaverActive = false;
  bool _screenOn = true;
  bool _starting = false;

  /// Set when the camera was bound while the panel was off. Opening the
  /// camera under a dark panel is refused even where an already-open
  /// session survives it: One UI rejects the connect with "disabled by
  /// policy" and CameraX parks the session in PENDING_OPEN — no error, no
  /// frames, and nothing ever heals it, because no availability callback
  /// follows a policy reject (measured on a Tab S8 / Android 16 when a
  /// relaunch raced a screen-off). Older Android opens fine. Either way
  /// the session is suspect until a frame proves otherwise, so the wake
  /// listener restarts it and a motion tick clears the suspicion.
  bool _boundBlind = false;

  /// Rebind backoff after the OS revokes the camera out from under a live
  /// session — the panel powering off does it within seconds on versions
  /// that revoke at all (see the class comment; the camera foreground
  /// service type is the exemption), and another app taking the sensor
  /// does it too. The native side reports the revocation as a stream
  /// error; this schedules the rebind.
  Timer? _retry;
  late Duration _retryDelay = _retryFloor;

  /// First rebind delay; doubles per consecutive failure up to the
  /// ceiling. Injectable for tests only.
  final Duration _retryFloor;
  static const _retryCeiling = Duration(seconds: 60);

  /// The screensaver schedule's motion override, null when none holds.
  bool? _schedulePolicy;

  @override
  Future<void> init() async {
    // Every branch below is the app relighting the room with its own
    // display: the change the camera is about to see is self-inflicted
    // (see _selfLightQuiet), the loop being a screensaver whose own dark
    // background reads as motion and dismisses it instantly.
    bus.on<ScreensaverStateChanged>().listen((e) {
      _selfLit();
      _screensaverActive = e.active;
      _sync();
    });
    bus.on<BrightnessChanged>().listen((_) => _selfLit());
    // A slideshow swapping to a very differently lit photo relights the
    // room mid-session just like the transitions above. The duty-cycle
    // cost is bounded: at the default slide interval the gate covers a
    // fraction of each hold, and touch dismissal is never gated.
    bus.on<ScreensaverSlideChanged>().listen((_) => _selfLit());
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
      _selfLit();
      _screenOn = e.on;
      if (e.on && _boundBlind) {
        _boundBlind = false;
        log.info(name, 'camera was bound under a dark panel; restarting it');
        _stop();
      }
      _sync();
    });
    // A tuning change (fps / sensitivity / the Camera section's camera pick)
    // restarts the stream so the native analyzer picks up the new arguments;
    // turning the feature on prompts for the camera up front so the first dim
    // can start it without a pause.
    bus.on<SettingChanged>().listen((e) {
      final isGate = e.key == defs.screensaverDismissOnMotion.key ||
          e.key == defs.screensaverPostponeOnMotion.key ||
          e.key == defs.motionSensor.key ||
          e.key == defs.screensaverEnabled.key ||
          e.key == defs.cameraEnabled.key;
      // MQTT-side only (it lives in the HA discovery config): no reason to
      // restart the camera over it.
      if (e.key == defs.motionSensorOffDelay.key) return;
      if (!isGate &&
          !e.key.startsWith('motion.') &&
          e.key != defs.cameraDevice.key &&
          // The pre-bound snapshot capture is sized at bind time; a new
          // resolution needs a rebind to take effect mid-screensaver.
          e.key != defs.cameraSnapshotResolution.key) {
        return;
      }
      if (isGate && (enabled || _postponeEnabled || _sensorEnabled)) {
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

    if (enabled || _postponeEnabled || _sensorEnabled) {
      unawaited(_ensurePermission());
    }

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
  /// them (screen on), and the sensor leg always.
  bool get _shouldRun =>
      _sensorEnabled ||
      (_screensaverActive ? enabled : _postponeEnabled && _screenOn);

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
      final startDelay =
          _settings.get(defs.motionStartDelay).toInt().clamp(0, 15);
      _boundBlind = !_screenOn;
      log.info(
        name,
        'camera on (fps=$fps sensitivity=$sensitivity cam=$camera'
        '${startDelay > 0 ? ' delay=${startDelay}s' : ''}'
        '${_boundBlind ? ', panel off: restart on wake unless frames flow' : ''})',
      );
      _camera = NativeMotion.stream(
        fps: fps,
        sensitivity: sensitivity,
        camera: camera,
        snapshotWidth: snapW,
        snapshotHeight: snapH,
        startDelayMs: startDelay * 1000,
      ).listen(
        (_) {
          // Frames flowing again: the session is healthy, forget any
          // accumulated rebind backoff and any blind-bind suspicion.
          _retryDelay = _retryFloor;
          _boundBlind = false;
          if (DateTime.now().isBefore(_quietUntil)) {
            log.debug(name, 'motion suppressed (own light change)');
            return;
          }
          log.debug(name, 'motion');
          bus.publish(const MotionDetected());
        },
        onError: (Object e) {
          log.warn(name, 'camera error: $e');
          _onCameraLost();
        },
      );
    } finally {
      _starting = false;
    }
  }

  /// The stream died under us (the native side reported the OS revoking
  /// the camera). Tear the dead subscription down and rebind when a
  /// rebind can work: on a timer with backoff while the screen is on
  /// (another app may still hold the sensor), or on the next screen-on
  /// when the panel is off — rebinding under a dark panel is refused the
  /// same way the eviction happened, so the ScreenStateChanged listener
  /// owns that case.
  void _onCameraLost() {
    final dead = _camera;
    if (dead == null) return;
    _camera = null;
    unawaited(dead.cancel());
    if (!_shouldRun) return;
    if (!_screenOn) {
      log.info(name, 'camera revoked with the screen off; rebinding on wake');
      return;
    }
    final delay = _retryDelay;
    final doubled = _retryDelay * 2;
    _retryDelay = doubled > _retryCeiling ? _retryCeiling : doubled;
    log.info(name, 'rebinding the camera in ${delay.inSeconds}s');
    _retry?.cancel();
    _retry = Timer(delay, () {
      _retry = null;
      _sync();
    });
  }

  void _stop() {
    _retry?.cancel();
    _retry = null;
    _retryDelay = _retryFloor;
    _boundBlind = false;
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
