import 'package:flutter/services.dart';

/// Dart side of the native camera motion detector (`CameraMotion.kt`).
///
/// Listening starts the camera and binds the analyzer; each event is a motion
/// tick (the native side does the frame-diffing and rate-limits to 1/s).
/// Cancelling the subscription unbinds the camera and frees it. Tuning changes
/// re-listen with fresh arguments.
class NativeMotion {
  static const _channel = EventChannel('kiosk_satellite/motion');

  static Stream<void> stream({
    required double fps,
    required int sensitivity,
    required String camera,
    required int snapshotWidth,
    required int snapshotHeight,
  }) {
    return _channel.receiveBroadcastStream(<String, Object?>{
      'fps': fps,
      'sensitivity': sensitivity,
      'camera': camera,
      // For the snapshot capture use case pre-bound into this session, so
      // a frame taken mid-screensaver matches the configured resolution.
      'snapshotWidth': snapshotWidth,
      'snapshotHeight': snapshotHeight,
    }).map((_) {});
  }
}
