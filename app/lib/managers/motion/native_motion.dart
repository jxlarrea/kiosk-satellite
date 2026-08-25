import 'package:flutter/services.dart';

/// Dart side of the native camera motion detector (`CameraMotion.kt`).
///
/// Listening starts the camera and binds the analyzer; each event is a motion
/// tick or a face sighting (the native side does the frame-diffing and the
/// face inference, and rate-limits each to 1/s). Cancelling the subscription
/// unbinds the camera and frees it. Tuning changes re-listen with fresh
/// arguments.
class NativeMotion {
  static const _channel = EventChannel('kiosk_satellite/motion');

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
        })
        .map(NativeMotionTick.fromNative);
  }
}

/// One event off the native stream: a motion tick, or a face sighting
/// carrying the face's width as a fraction of the frame's longer side.
class NativeMotionTick {
  const NativeMotionTick._(this.faceWidth);

  final double? faceWidth;

  bool get isFace => faceWidth != null;

  /// Anything that is not a face sighting is a motion tick, which keeps the
  /// wire compatible with the original null events.
  static NativeMotionTick fromNative(Object? raw) {
    if (raw is Map) {
      final face = raw['face'];
      if (face is num) return NativeMotionTick._(face.toDouble());
    }
    return const NativeMotionTick._(null);
  }
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
