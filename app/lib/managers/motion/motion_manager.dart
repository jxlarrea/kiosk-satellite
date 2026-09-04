import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../../core/permissions.dart';
import '../device_camera/native_camera.dart' show snapshotResolution;
import '../gestures/gesture_mappings.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'native_motion.dart';
import 'vision_support.dart';

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
/// motion as its own Home Assistant binary sensor, independent of the screensaver
/// features. It ignores even the screen-on gate above, and a truly
/// powered-off panel is its headline use: an already-open session now
/// survives screen-off because the Kiosk Satellite Service carries the
/// camera foreground type while the camera is enabled, the exemption newer
/// Android gates on — without it the OS revokes within seconds of the panel
/// going dark (measured on Android 16). Not every vendor honors the exemption:
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
///
/// The "Raise a hand" gesture is the fourth leg, and the one that is not
/// about the screensaver at all: while any gesture mapping wants a raised
/// hand, the camera runs whenever the screen is on, screensaver or not,
/// and the native palm detector reports hands held up; the gestures
/// manager turns those into the mapped action. It follows the gates the
/// other gestures follow (Lockdown Mode, kiosk mode's Disable Gestures),
/// so a locked screen does not even bind the camera for it.
///
/// All of it pauses for a voice interaction: from the wake word until
/// Voice Satellite resumes wake detection, the camera stays bound but
/// the native side emits nothing and runs no model, and anything still
/// in flight is dropped here. Someone talking at the satellite is not
/// the motion a screensaver wakes for, a face it should dismiss for, or
/// a hand showing fingers, and the turn wants the cores the detectors
/// would take. The pause is bounded (see [_pauseCeiling]) so a page that
/// never resumes wake detection cannot leave the camera blind.
class MotionManager extends Manager {
  MotionManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    this._selfLightQuiet = const Duration(milliseconds: 2500),
    this._retryFloor = const Duration(seconds: 5),
    this._pauseCeiling = const Duration(minutes: 3),
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
      (_schedulePolicy ?? _settings.get(defs.screensaverDismissOnMotion)) &&
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

  /// Whether the standalone motion sensor wants the camera: whenever it is
  /// on. No screensaver or screen-state gates (see the class comment).
  bool get _sensorEnabled =>
      _settings.get(defs.motionSensor) && _settings.get(defs.cameraEnabled);

  /// The face leg (issue #304): "Dismiss on face" rides the same session
  /// under the same gates as Dismiss on motion (screensaver showing, camera
  /// on, the schedule's per-entry override standing in for the switch),
  /// plus one of its own: Dismiss on motion takes precedence. With motion
  /// effectively on, the face leg is idle, which the settings pages say
  /// under the switch.
  bool get faceEnabled =>
      _vision.faces &&
      !enabled &&
      (_faceSchedulePolicy ?? _settings.get(defs.screensaverDismissOnFace)) &&
      _settings.get(defs.cameraEnabled);

  /// The postpone counterpart, with Postpone on motion's rules: rides on
  /// Dismiss on face (never a second way in), runs between screensavers
  /// with the screen lit, raw switches rather than the session-scoped
  /// schedule overrides, and the same precedence: Dismiss on motion on
  /// means the face legs are idle, this one included.
  bool get _postponeFaceEnabled =>
      _vision.faces &&
      _settings.get(defs.screensaverPostponeOnFace) &&
      _settings.get(defs.screensaverDismissOnFace) &&
      !_settings.get(defs.screensaverDismissOnMotion) &&
      _settings.get(defs.screensaverEnabled) &&
      _settings.get(defs.cameraEnabled);

  /// The hand leg: a gesture mapping wants a raised hand, the camera is
  /// on, and gestures are not suppressed (Lockdown Mode, kiosk mode's
  /// Disable Gestures). Screen-on is applied where the leg is consulted,
  /// like the postpone legs: nobody raises a hand at a dark panel.
  bool get palmEnabled =>
      _vision.hands &&
      hasFingersTrigger(
        decodeGestureMappings(_settings.get(defs.gestureMappings)),
      ) &&
      _settings.get(defs.cameraEnabled) &&
      !_settings.get(defs.lockdownEnabled) &&
      !(_settings.get(defs.kioskEnabled) &&
          _settings.get(defs.kioskDisableGestures));

  /// What the running native stream was asked to emit, so a change in
  /// any (the screensaver starting under a face-only setup while the
  /// sensor leg already holds the camera, a schedule boundary flipping the
  /// motion override, a hand mapping added) restarts the stream with
  /// fresh arguments.
  bool _streamMotion = true;
  bool _streamFaces = false;
  bool _streamPreview = false;
  bool _streamPalms = false;

  bool get _wantMotion => enabled || _postponeEnabled || _sensorEnabled;
  bool get _wantFaces =>
      _screensaverActive ? faceEnabled : _postponeFaceEnabled;

  /// The camera preview (discussion #371): the latest frame the native
  /// side handed over while a preview is showing, null otherwise. The
  /// kiosk screen's FacePreviewOverlay draws it; frames are JPEGs in
  /// sensor orientation with their rotation and mirroring alongside
  /// (see [FacePreviewFrame]).
  final facePreview = ValueNotifier<FacePreviewFrame?>(null);

  /// Whether a session should ask for the preview: the switch, on a
  /// session that looks for faces (the only thing that can open the
  /// window). The native side sizes its analysis stream up for it.
  bool get _wantPreview => _wantFaces && _settings.get(defs.facePreview);

  /// The hold that keeps the camera bound through a preview: a face
  /// dismisses the screensaver, and without Postpone on face the session
  /// would end with it, frames and all. While it runs, [_shouldRun] is
  /// true and [_sync] leaves the session alone (a restart would close
  /// the camera mid-preview); when it ends, [_sync] settles the camera
  /// the way the session's end would have.
  Timer? _previewHold;
  bool get _previewHolding => _previewHold != null;
  bool get _wantPalms => palmEnabled && _screenOn;

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
  /// listener restarts it and a motion tick clears the suspicion. The
  /// restart itself can be refused the same way when it races the app's
  /// own return to the foreground (One UI 11, issue #349), and that
  /// refusal is just as silent; the native frame watchdog catches it (no
  /// frames for ten seconds under a lit panel) and reports a stream
  /// error, which [_onCameraLost] answers with the backoff rebind.
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

  /// A voice interaction is running (see the class comment). Mirrors the
  /// wake-word manager's suspended state, entered a beat earlier on the
  /// detection itself.
  bool _voiceTurn = false;
  Timer? _pauseTimer;

  /// The longest a turn may hold the camera idle. The wake-word manager
  /// self-heals a page that never resumes it, but only for turns it
  /// started; a page-suspended one that dies mid-turn would otherwise
  /// leave motion, faces and hands off until the next config push.
  /// Injectable for tests only.
  final Duration _pauseCeiling;

  /// The screensaver schedule's motion override, null when none holds.
  bool? _schedulePolicy;

  /// The same for the face override (issue #304).
  bool? _faceSchedulePolicy;

  /// Whether the face and hand runtimes can load here at all (issue
  /// #331: not on Android 7). Unknown reads as supported; the answer
  /// folds into [faceEnabled], [_postponeFaceEnabled] and [palmEnabled],
  /// so a device without a runtime never binds the camera for a leg
  /// that cannot see, and never prompts for the camera over it either.
  VisionSupport _vision = VisionSupport.unknown;
  bool _warnedFaces = false;
  bool _warnedHands = false;

  /// One log line per leg, the first time a setting asks for a leg the
  /// device cannot run: the switch is disabled on both settings
  /// surfaces, but a value written from Home Assistant or an import
  /// lands here with no UI to say so.
  void _warnUnsupported() {
    final hint = _vision.hint ?? 'Not available on this device.';
    final cameraOn = _settings.get(defs.cameraEnabled);
    if (!_vision.faces &&
        !_warnedFaces &&
        cameraOn &&
        _settings.get(defs.screensaverDismissOnFace)) {
      _warnedFaces = true;
      log.warn(
        name,
        'face detection cannot run here ($hint) so Dismiss on face '
        'stays idle',
      );
    }
    if (!_vision.hands &&
        !_warnedHands &&
        cameraOn &&
        hasFingersTrigger(
          decodeGestureMappings(_settings.get(defs.gestureMappings)),
        )) {
      _warnedHands = true;
      log.warn(
        name,
        'hand detection cannot run here ($hint) so Show fingers '
        'gestures stay idle',
      );
    }
  }

  @override
  Future<void> init() async {
    // Asked once, at init: the bridge answers within the same tick, long
    // before the first bind. A bind that raced it restarts with fresh
    // flags below; the native detectors survive the runtime failing to
    // load in that window (FaceDetector.kt), so the race is a log line,
    // not a crash.
    unawaited(
      VisionSupport.probe().then((v) {
        final changed = v.faces != _vision.faces || v.hands != _vision.hands;
        _vision = v;
        _warnUnsupported();
        if (changed) _sync();
      }),
    );
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
      _faceSchedulePolicy = e.dismissOnFace;
      _sync();
    });
    // A face woke the screen: show what the camera saw, for the
    // configured span, on the session that saw it. Published ahead of
    // the screensaver's stop, so the hold is up before the stop's
    // ScreensaverStateChanged runs [_sync].
    bus.on<FaceDismissedScreensaver>().listen((_) => _showPreview());
    // A voice interaction: idle the camera's analysis for its span. The
    // detection comes first (the page suspends wake detection a bridge
    // round trip later), the page's resume ends it.
    bus.on<WakeWordDetected>().listen((_) => _setVoiceTurn(true));
    bus.on<WakeWordStateChanged>().listen((e) => _setVoiceTurn(!e.active));
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
      final isGate =
          e.key == defs.screensaverDismissOnMotion.key ||
          e.key == defs.screensaverPostponeOnMotion.key ||
          e.key == defs.screensaverDismissOnFace.key ||
          e.key == defs.screensaverPostponeOnFace.key ||
          e.key == defs.motionSensor.key ||
          e.key == defs.screensaverEnabled.key ||
          e.key == defs.cameraEnabled.key ||
          // The hand leg's gates: the mappings themselves and the
          // gesture suppressions.
          e.key == defs.gestureMappings.key ||
          e.key == defs.lockdownEnabled.key ||
          e.key == defs.kioskEnabled.key ||
          e.key == defs.kioskDisableGestures.key;
      // Entity-side only (the ESPHome sensor times its own clear): no
      // reason to restart the camera over it.
      if (e.key == defs.motionSensorOffDelay.key) return;
      // The preview's look and span are read when a preview shows; only
      // the switch itself changes what the session is bound with.
      if (e.key == defs.facePreviewSeconds.key ||
          e.key == defs.facePreviewScale.key ||
          e.key == defs.facePreviewPosition.key) {
        return;
      }
      if (!isGate &&
          !e.key.startsWith('motion.') &&
          !e.key.startsWith('face.') &&
          e.key != defs.cameraDevice.key &&
          // The pre-bound snapshot capture is sized at bind time; a new
          // resolution needs a rebind to take effect mid-screensaver.
          e.key != defs.cameraSnapshotResolution.key) {
        return;
      }
      if (isGate &&
          (enabled ||
              _postponeEnabled ||
              _sensorEnabled ||
              faceEnabled ||
              _postponeFaceEnabled ||
              palmEnabled)) {
        unawaited(_ensurePermission());
      }
      _stop();
      _sync();
    });

    commands.register(
      Command(
        name: 'getMotionEnabled',
        description: 'Whether camera motion detection is enabled',
        handler: (_) async => CommandResult.ok(enabled),
      ),
    );
    commands.register(
      Command(
        name: 'getFaceEnabled',
        description:
            'Whether camera face detection is enabled (off while Dismiss on '
            'motion takes precedence)',
        handler: (_) async => CommandResult.ok(faceEnabled),
      ),
    );

    if (enabled ||
        _postponeEnabled ||
        _sensorEnabled ||
        faceEnabled ||
        _postponeFaceEnabled ||
        palmEnabled) {
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

  /// Enter or leave the voice-interaction pause (see the class comment).
  /// The camera is not unbound: a rebind costs seconds and the turn is
  /// short, so the native side is told to idle instead. A tracked hand
  /// is reported gone so the gestures manager re-arms, and the hand has
  /// to come up again after the turn to count. Resuming counts as the
  /// app relighting the room: the turn's overlay leaving is a screen
  /// change the camera sees.
  void _setVoiceTurn(bool on) {
    if (on == _voiceTurn) return;
    _voiceTurn = on;
    _pauseTimer?.cancel();
    _pauseTimer = null;
    if (on) {
      _pauseTimer = Timer(_pauseCeiling, () {
        _pauseTimer = null;
        if (!_voiceTurn) return;
        log.warn(
          name,
          'voice interaction never ended after ${_pauseCeiling.inMinutes} '
          'minutes; resuming the camera',
        );
        _setVoiceTurn(false);
      });
    } else {
      _selfLit();
    }
    if (_camera != null) {
      log.info(name, on ? 'paused for a voice interaction' : 'resumed');
      unawaited(
        NativeMotion.setPaused(on).catchError((Object e) {
          log.debug(name, 'setPaused($on) failed: $e');
        }),
      );
      if (on && _streamPalms) {
        bus.publish(const PalmDetected(hands: 0, fingers: null));
      }
    }
  }

  /// Whether the camera should be running right now: dismiss-on-motion or
  /// dismiss-on-face wants it during a screensaver session, either
  /// postpone leg between them (screen on), the hand leg whenever the
  /// screen is on, and the sensor leg always.
  bool get _shouldRun =>
      _sensorEnabled ||
      _wantPalms ||
      _previewHolding ||
      (_screensaverActive
          ? enabled || faceEnabled
          : (_postponeEnabled || _postponeFaceEnabled) && _screenOn);

  void _sync() {
    _warnUnsupported();
    if (!_shouldRun) {
      _stop();
      return;
    }
    // A preview in progress keeps the session it is drawn from as it
    // is; the hold's end runs this again and settles it.
    if (_previewHolding && _camera != null) return;
    // A session already up but asked for the wrong things restarts: the
    // native side takes its emission flags at bind time.
    if (_camera != null &&
        (_streamMotion != _wantMotion ||
            _streamFaces != _wantFaces ||
            _streamPalms != _wantPalms ||
            _streamPreview != _wantPreview)) {
      log.info(
        name,
        'camera restarting (motion=$_wantMotion faces=$_wantFaces '
        'palms=$_wantPalms)',
      );
      _stop();
    }
    unawaited(_start());
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
      final sensitivity = _settings
          .get(defs.motionSensitivity)
          .toInt()
          .clamp(1, 100);
      final camera = _settings.get(defs.cameraDevice);
      final (snapW, snapH) = snapshotResolution(
        _settings.get(defs.cameraSnapshotResolution),
      );
      final startDelay = _settings
          .get(defs.motionStartDelay)
          .toInt()
          .clamp(0, 15);
      final motion = _wantMotion;
      final faces = _wantFaces;
      final palms = _wantPalms;
      final preview = _wantPreview;
      final faceMinWidth = faceMinWidthFor(
        _settings.get(defs.faceSensitivity).toInt(),
      );
      _streamMotion = motion;
      _streamFaces = faces;
      _streamPalms = palms;
      _streamPreview = preview;
      _boundBlind = !_screenOn;
      log.info(
        name,
        'camera on (fps=$fps sensitivity=$sensitivity cam=$camera'
        '${startDelay > 0 ? ' delay=${startDelay}s' : ''}'
        '${faces ? ' faces>=${(faceMinWidth * 100).round()}%' : ''}'
        '${palms ? ' hands' : ''}'
        '${preview ? ' preview' : ''}'
        '${motion ? '' : ' motion off'}'
        '${_boundBlind ? ', panel off: restart on wake unless frames flow' : ''})',
      );
      _camera =
          NativeMotion.stream(
            fps: fps,
            sensitivity: sensitivity,
            camera: camera,
            snapshotWidth: snapW,
            snapshotHeight: snapH,
            startDelayMs: startDelay * 1000,
            motion: motion,
            faces: faces,
            faceMinWidth: faceMinWidth,
            fingers: palms,
            paused: _voiceTurn,
            preview: preview,
          ).listen(
            (tick) {
              // Frames flowing again: the session is healthy, forget any
              // accumulated rebind backoff and any blind-bind suspicion.
              _retryDelay = _retryFloor;
              _boundBlind = false;
              // The native side emits nothing during a voice interaction;
              // this catches what was already on its way across.
              if (_voiceTurn) {
                log.debug(name, 'dropped (voice interaction)');
                return;
              }
              // A preview frame goes straight to the overlay, and only
              // while a preview is being shown: the native window and
              // the hold are armed together, but a frame already on its
              // way across when the hold ends is not worth drawing.
              if (tick.isPreview) {
                if (_previewHolding) facePreview.value = tick.preview;
                return;
              }
              // A face is not a lighting change, so the self-light quiet
              // window below does not apply to it.
              if (tick.isFace) {
                log.debug(
                  name,
                  'face (${(tick.faceWidth! * 100).round()}% of the frame)',
                );
                bus.publish(const FaceDetected());
                return;
              }
              // Hands are not a lighting change either. A count of 0 is the
              // hand gone, which the gestures manager needs to re-arm.
              if (tick.isPalms) {
                if (tick.palms! > 0) {
                  log.debug(
                    name,
                    '${tick.palms} hand${tick.palms == 1 ? '' : 's'}, '
                    '${tick.fingers ?? '?'} finger(s)',
                  );
                }
                bus.publish(
                  PalmDetected(hands: tick.palms!, fingers: tick.fingers),
                );
                return;
              }
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
    // A session torn down under a preview (the camera switched off, a
    // tuning change) takes the preview with it: its frames are gone.
    _endPreview();
    if (_camera == null) return;
    _camera!.cancel();
    _camera = null;
    log.info(name, 'camera off');
  }

  /// Show the camera preview (discussion #371) on the running session:
  /// hold the camera for the configured span, ask the native side to
  /// emit frames for it, and drop it all when the span ends.
  void _showPreview() {
    if (!_settings.get(defs.facePreview)) return;
    if (_camera == null || !_streamPreview) {
      // A face can only come off a session, so this is a session bound
      // before the switch was flipped (the flip restarts it, so once).
      log.debug(name, 'no preview: the session was not bound for one');
      return;
    }
    final span = Duration(
      seconds: _settings.get(defs.facePreviewSeconds).toInt().clamp(3, 10),
    );
    log.info(name, 'camera preview for ${span.inSeconds}s');
    _previewHold?.cancel();
    _previewHold = Timer(span, () {
      _previewHold = null;
      facePreview.value = null;
      _sync();
    });
    unawaited(
      NativeMotion.showPreview(span).catchError((Object e) {
        log.debug(name, 'showPreview failed: $e');
      }),
    );
  }

  void _endPreview() {
    if (_previewHold == null) return;
    _previewHold!.cancel();
    _previewHold = null;
    facePreview.value = null;
  }

  Future<bool> _ensurePermission() async {
    if (await Permission.camera.isGranted) return true;
    return await ensureOsPermission(Permission.camera);
  }

  @override
  Future<void> dispose() async {
    _pauseTimer?.cancel();
    _stop();
    facePreview.dispose();
  }
}
