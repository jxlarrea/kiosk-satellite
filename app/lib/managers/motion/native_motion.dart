import 'package:flutter/services.dart';

/// Dart side of the native camera motion detector (`CameraMotion.kt`).
///
/// Listening starts the camera and binds the analyzer; each event is a motion
/// tick, a face sighting or a raised-hand report (the native side does the
/// frame-diffing and the inference, and rate-limits the first two to 1/s).
/// Cancelling the subscription unbinds the camera and frees it. Tuning
/// changes re-listen with fresh arguments.
class NativeMotion {
  static const _channel = EventChannel('kiosk_satellite/motion');
  static const _control = MethodChannel('kiosk_satellite/motion/control');

  /// Idle (or wake) the analysis of a running session without a rebind:
  /// the camera stays open and the motion grid keeps its baseline, but
  /// no tick, sighting or hand report is emitted and no model runs.
  /// Used for the span of a voice interaction. Throws where the plugin
  /// is missing (tests without a mock); callers treat that as best
  /// effort.
  static Future<void> setPaused(bool paused) =>
      _control.invokeMethod<void>('setPaused', {'paused': paused});

  /// Open the camera preview window on a running session (discussion
  /// #371): for the next [duration] the native side also encodes the
  /// analyzed frames as small JPEGs and emits them as preview ticks
  /// (see [NativeMotionTick.previewJpeg]), paced to about ten a second
  /// and by their own encoding cost. A no-op without a session. Throws
  /// where the plugin is missing; callers treat that as best effort.
  static Future<void> showPreview(Duration duration) => _control
      .invokeMethod<void>('showPreview', {'ms': duration.inMilliseconds});

  static Stream<NativeMotionTick> stream({
    required double fps,
    required int sensitivity,
    required String camera,
    required int snapshotWidth,
    required int snapshotHeight,
    int startDelayMs = 0,
    bool motion = true,
    bool faces = false,
    double faceMinWidth = 0.1,
    bool fingers = false,
    bool paused = false,
    bool preview = false,
  }) {
    return _channel
        .receiveBroadcastStream(<String, Object?>{
          'fps': fps,
          'sensitivity': sensitivity,
          'camera': camera,
          // For the snapshot capture use case pre-bound into this session, so
          // a frame taken mid-screensaver matches the configured resolution.
          'snapshotWidth': snapshotWidth,
          'snapshotHeight': snapshotHeight,
          // Extra blindness after the stream starts, for cameras that move as
          // they open (discussion #159). Applied natively so the analyzer keeps
          // tracking frames without letting the movement train its noise model.
          'startDelayMs': startDelayMs,
          // Which legs want events (issue #304): motion ticks, face
          // sightings, or both. The frame analysis runs regardless (its
          // exposure-hunt watchdog guards the CPU either way); only the
          // emissions are gated.
          'motion': motion,
          'faces': faces,
          // Smallest face worth reporting, as a fraction of the frame's
          // longer side; see [faceMinWidthFor].
          'faceMinWidth': faceMinWidth,
          // Hands (the Show fingers gesture): found, confirmed and counted
          // natively, reported as a hand count and a finger count.
          'fingers': fingers,
          // Whether a voice interaction is running as the session starts
          // (see [setPaused]): the flag rides the bind too, so a session
          // rebound mid-turn, on a native side recreated with the
          // Activity, starts idle like the one it replaces.
          'paused': paused,
          // The camera preview (discussion #371) may be asked for on this
          // session (see [showPreview]): the analysis stream is sized up
          // for it, since its frames are what the preview is made of.
          'preview': preview,
        })
        .map(NativeMotionTick.fromNative);
  }
}

/// One event off the native stream: a motion tick, a face sighting
/// carrying the face's width as a fraction of the frame's longer side, or
/// a hand report carrying the hand count (0 when the hand has gone) and
/// the fingers shown.
class NativeMotionTick {
  const NativeMotionTick._(
    this.faceWidth,
    this.palms,
    this.fingers, {
    this.preview,
  });

  /// Extended fingers on the largest hand, when the landmark stage judged
  /// it (null otherwise).
  final int? fingers;

  final double? faceWidth;
  final int? palms;

  /// A camera preview frame (see [NativeMotion.showPreview]).
  final FacePreviewFrame? preview;

  bool get isFace => faceWidth != null;
  bool get isPalms => palms != null;
  bool get isPreview => preview != null;

  /// Anything that is not a face sighting, a hand report or a preview
  /// frame is a motion tick, which keeps the wire compatible with the
  /// original null events.
  static NativeMotionTick fromNative(Object? raw) {
    if (raw is Map) {
      final face = raw['face'];
      if (face is num) {
        return NativeMotionTick._(face.toDouble(), null, null);
      }
      final palms = raw['palms'];
      if (palms is num) {
        final fingers = raw['fingers'];
        return NativeMotionTick._(
          null,
          palms.toInt(),
          fingers is num && fingers >= 0 ? fingers.toInt() : null,
        );
      }
      final preview = raw['preview'];
      if (preview is Uint8List) {
        final rotation = raw['rotation'];
        return NativeMotionTick._(
          null,
          null,
          null,
          preview: FacePreviewFrame(
            jpeg: preview,
            rotation: rotation is num ? rotation.toInt() : 0,
            mirror: raw['mirror'] == true,
          ),
        );
      }
    }
    return const NativeMotionTick._(null, null, null);
  }
}

/// One frame of the camera preview (discussion #371), as the native side
/// hands it over: a JPEG of the analysis frame in sensor orientation,
/// the rotation that turns it upright on this display (the frame's
/// rotationDegrees, a multiple of 90) and whether it should be mirrored,
/// which it is for a front camera so the view reads like a mirror to the
/// person in it.
class FacePreviewFrame {
  const FacePreviewFrame({
    required this.jpeg,
    required this.rotation,
    required this.mirror,
  });

  final Uint8List jpeg;
  final int rotation;
  final bool mirror;
}

/// The Face sensitivity slider (1..100) as the minimum face width the
/// native detector reports, relative to the frame's longer side.
///
/// The slider is read as a distance: 1 means only a face right at the
/// screen (about 0.3 m), 100 means as far as the detector can see (about
/// 2.5 m), linear in between. A face about 15 cm wide seen through a
/// typical 80-degree front camera spans 0.15 / (2 d tan 40) of the frame,
/// roughly 0.09 / d, which is what the mapping returns. Beyond roughly two
/// meters the detector's own reach (faces of a dozen pixels in its 192
/// pixel input) is the limit, not the slider.
double faceMinWidthFor(int sensitivity) {
  final s = sensitivity.clamp(1, 100);
  final meters = 0.3 + (s - 1) / 99 * 2.2;
  return 0.09 / meters;
}
