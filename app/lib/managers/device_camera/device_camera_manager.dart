import 'dart:async';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../../core/permissions.dart';
import '../settings/definitions.dart' as defs;
import '../motion/vision_support.dart';
import '../settings/settings_manager.dart';
import 'native_camera.dart';

/// The device's own camera as a Home Assistant feature (discussion #72).
///
/// Deliberately granular: the master switch ([defs.cameraEnabled]) is the
/// whole feature's gate, so a kiosk that does not need the camera never
/// spends a CPU cycle or a degree of heat on it. With it on, this manager
/// captures stills — on demand (the `takeCameraSnapshot` command, reachable
/// from the ESPHome "Take snapshot" button and the remote admin) and on a timer
/// ([defs.cameraSnapshots]) — and publishes each as [CameraSnapshotTaken]
/// for the ESPHome camera entity to relay.
///
/// Nothing is held open between captures: the native side
/// (`DeviceCamera.kt`) opens the camera, takes one frame, and releases it —
/// or rides the motion detector's already-open session when the screensaver
/// has motion detection running. Livestreaming will grow out of this same
/// manager.
class DeviceCameraManager extends Manager {
  DeviceCameraManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'device_camera';

  Timer? _timer;
  bool _capturing = false;

  /// The last motion tick (any tick, not just ones that shot): the gap
  /// since it is what defines a new motion session.
  DateTime? _lastMotionTick;

  /// Probed once, lazily. Null until the first ask.
  bool? _present;

  bool get enabled => _settings.get(defs.cameraEnabled);

  /// Whether this device has a usable camera at all. Hardware whose ROM
  /// ships no camera HAL (LineageOS ports on Echo Shows) has none, and
  /// both settings surfaces warn instead of offering switches that can
  /// only fail. Unknown (no Activity attached) counts as present, so a
  /// probe hiccup never false-alarms.
  Future<bool> cameraPresent() async {
    if (_present != null) return _present!;
    try {
      return _present = await NativeCamera.hasCamera();
    } catch (_) {
      return true;
    }
  }

  /// True once the probe has answered "no camera". Synchronous, for UI
  /// code deciding what to render; false while the answer is unknown.
  bool get cameraKnownAbsent => _present == false;

  /// The lens facings this device actually has, or null before the probe
  /// answers. A single-camera device (Echo Show 5: front only) should not
  /// be offered a Front/Back picker.
  List<String>? _facings;
  List<String>? get knownFacings => _facings;

  Future<List<String>> cameraFacings() async {
    if (_facings != null) return _facings!;
    try {
      return _facings = await NativeCamera.facings();
    } catch (_) {
      return const [];
    }
  }

  /// The camera master switch as the rest of the app should read it: on
  /// AND backed by real hardware. A stored "on" on a camera-less device
  /// counts as off everywhere.
  bool get effectiveEnabled => enabled && _present != false;

  /// Whether the vision runtimes behind face detection and the Show
  /// fingers gesture can load on this device (issue #331: not on Android
  /// 7). Null until the bridge has answered; the sync getters below are
  /// for UI code and read false until then, so a row is never disabled
  /// on a guess.
  VisionSupport? _vision;

  Future<VisionSupport> visionSupport() async =>
      _vision ??= await VisionSupport.probe();

  bool get facesKnownUnsupported => _vision?.faces == false;
  bool get handsKnownUnsupported => _vision?.hands == false;

  /// The reason to show under a disabled face or hand row.
  String? get visionHint => _vision?.hint;

  @override
  Future<void> init() async {
    await _migrateLegacyMotionCamera();

    // Probe early so the settings surfaces and the ESPHome catalog have the
    // answer by the time they ask. Unawaited: with no Activity yet the
    // probe simply resolves later, on the first ask that finds one.
    unawaited(cameraPresent());
    unawaited(cameraFacings());
    unawaited(visionSupport());

    bus.on<SettingChanged>().listen((e) {
      if (!e.key.startsWith('camera.')) return;
      // Turning the feature on asks for the camera up front, like motion
      // detection used to, so the first capture does not stall on a prompt.
      if (e.key == defs.cameraEnabled.key && e.value == true) {
        unawaited(_ensurePermission());
      }
      // The facing flipped (settings UI, remote admin, the HA select):
      // refresh the retained frame so the camera entity shows what the
      // new camera sees, not the last frame from the old one (issue
      // #296). Settled, not immediate: motion detection restarts on this
      // same change, and a capture fired into that rebind loses the race.
      if (e.key == defs.cameraDevice.key && enabled) {
        unawaited(_settledSnapshot('facing-change'));
      }
      _syncTimer();
    });

    // Motion refreshes the picture: the tick that wakes the screensaver is
    // someone stepping up to the kiosk, which is exactly the moment worth
    // having on the Home Assistant camera. One snapshot per motion session,
    // mirroring the motion sensor entity: a tick only counts as an arrival if
    // the sensor's Clear after window has passed without motion. Someone
    // staying in frame keeps the sensor on Detected and updates nothing —
    // without the session gate, the always-on sensor leg turned sustained
    // motion into a JPEG hose.
    bus.on<MotionDetected>().listen((_) {
      if (!enabled) return;
      final now = DateTime.now();
      final last = _lastMotionTick;
      _lastMotionTick = now;
      final clear = Duration(
        seconds: _settings.get(defs.motionSensorOffDelay).toInt().clamp(1, 300),
      );
      if (last != null && now.difference(last) < clear) return;
      unawaited(_settledSnapshot('motion'));
    });

    commands.register(
      Command(
        name: 'hasDeviceCamera',
        description: 'Whether this device has a usable camera.',
        handler: (_) async => CommandResult.ok(await cameraPresent()),
      ),
    );

    commands.register(
      Command(
        name: 'getCameraFacings',
        description:
            "The camera facings this device has, e.g. ['front'] on "
            'single-camera hardware. The remote admin hides the '
            'front/back picker when there is no choice to make.',
        handler: (_) async => CommandResult.ok(await cameraFacings()),
      ),
    );

    commands.register(
      Command(
        name: 'getVisionSupport',
        description:
            'Whether face detection and hand gestures can run on this '
            'device ({faces, hands, hint}); the remote admin disables '
            'their rows with the hint where they cannot.',
        handler: (_) async =>
            CommandResult.ok((await visionSupport()).toJson()),
      ),
    );

    commands.register(
      Command(
        name: 'takeCameraSnapshot',
        description:
            'Capture a still from the device camera and publish it to the '
            'Home Assistant camera entity.',
        handler: (_) => _snapshot(),
      ),
    );

    _syncTimer();
  }

  /// One-time carry-over from before the Camera section existed: motion
  /// detection used to own the camera choice, so a device that had it on
  /// keeps working after the update (camera enabled, same camera) instead
  /// of silently going dark.
  Future<void> _migrateLegacyMotionCamera() async {
    if (_settings.internal('camera.migrated').isNotEmpty) return;
    if (_settings.get(defs.screensaverDismissOnMotion)) {
      await _settings.set(defs.cameraEnabled, true);
      final legacy = _settings.get(defs.motionCamera);
      if (legacy != _settings.get(defs.cameraDevice)) {
        await _settings.set(defs.cameraDevice, legacy);
      }
      log.info(
        name,
        'migrated motion detection to the Camera section '
        '(camera on, $legacy)',
      );
    }
    await _settings.setInternal('camera.migrated', '1');
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (!enabled || !_settings.get(defs.cameraSnapshots)) return;
    final seconds = _settings
        .get(defs.cameraSnapshotInterval)
        .toInt()
        .clamp(5, 300);
    log.info(name, 'continuous snapshots every ${seconds}s');
    _timer = Timer.periodic(
      Duration(seconds: seconds),
      (_) => unawaited(_snapshot()),
    );
    // The first frame should not be a whole interval away.
    unawaited(_snapshot());
  }

  /// One capture after a second's grace, for triggers that race a camera
  /// session teardown. The motion tick that triggers a snapshot also
  /// dismisses the screensaver, which tears the motion camera session down
  /// within milliseconds — a capture fired immediately always loses that
  /// race ("Camera is closed"). So wait the teardown out and take one
  /// clean frame on the idle open-capture-close path; whoever tripped the
  /// motion is still in front of the kiosk a second later. A facing change
  /// rides the same grace: motion detection rebinds onto the new camera at
  /// the same moment.
  Future<void> _settledSnapshot(String why) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    final result = await _snapshot();
    if (!result.ok) log.warn(name, '$why snapshot failed: ${result.error}');
  }

  Future<CommandResult> _snapshot() async {
    if (!enabled) {
      return const CommandResult.fail(
        'The camera is disabled in the Camera settings.',
      );
    }
    // Timer ticks and entity button presses can overlap a capture still in
    // flight; the native side would refuse anyway, this keeps it quiet.
    if (_capturing) {
      return const CommandResult.fail('A snapshot is already in progress.');
    }
    if (!await Permission.camera.isGranted) {
      log.warn(name, 'camera permission not granted; snapshot skipped');
      return const CommandResult.fail('Camera permission not granted.');
    }
    _capturing = true;
    try {
      final (width, height) = snapshotResolution(
        _settings.get(defs.cameraSnapshotResolution),
      );
      // The native side carries its own watchdog; this one backstops it so
      // a wedged platform call can never pin _capturing until app restart.
      final jpeg = await NativeCamera.snapshot(
        camera: _settings.get(defs.cameraDevice),
        width: width,
        height: height,
      ).timeout(const Duration(seconds: 30));
      if (jpeg == null || jpeg.isEmpty) {
        return const CommandResult.fail('The camera returned no image.');
      }
      bus.publish(CameraSnapshotTaken(jpeg: jpeg));
      return CommandResult.ok({'bytes': jpeg.length});
    } on TimeoutException {
      log.warn(name, 'snapshot timed out');
      return const CommandResult.fail('The camera did not answer in time.');
    } on PlatformException catch (e) {
      log.warn(name, 'snapshot failed: ${e.message}');
      return CommandResult.fail('Snapshot failed: ${e.message}');
    } on MissingPluginException {
      // The cached engine outlives the Activity; without one there is no
      // camera to open (and no screen anybody is pointing it at).
      log.warn(name, 'snapshot unavailable: no Activity attached');
      return const CommandResult.fail(
        'The camera is unavailable while the app is in the background.',
      );
    } finally {
      _capturing = false;
    }
  }

  Future<bool> _ensurePermission() async {
    if (await Permission.camera.isGranted) return true;
    return await ensureOsPermission(Permission.camera);
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
  }
}
