import 'package:flutter/services.dart';

/// Dart side of the native snapshot bridge (`DeviceCamera.kt`).
///
/// One call, one JPEG. The native side shares the camera with the motion
/// detector: while motion holds the sensor the snapshot rides its session,
/// otherwise the camera is opened, read once, and released.
class NativeCamera {
  static const _channel = MethodChannel('kiosk_satellite/camera');

  /// A JPEG still from [camera] ('front' or 'back'), aimed at
  /// [width]x[height] (CameraX lands on the nearest size the hardware
  /// offers). Throws a [PlatformException] when the capture fails, or a
  /// [MissingPluginException] when no Activity is attached (the cached
  /// engine outlives the Activity; there is no camera without one).
  static Future<Uint8List?> snapshot({
    required String camera,
    required int width,
    required int height,
  }) =>
      _channel.invokeMethod<Uint8List>('snapshot', {
        'camera': camera,
        'width': width,
        'height': height,
      });
}

/// The capture target for a snapshot-resolution setting value (the tier's
/// height; see the definition for why these exact 4:3 sizes). One mapping
/// for every path that captures — the ephemeral snapshot and the capture
/// use case pre-bound into the motion session — so the output is identical
/// whichever way a frame is taken. Unknown values (a downgrade, an edited
/// import) fall back to the default tier.
(int, int) snapshotResolution(String value) => switch (value) {
      '480' => (640, 480),
      '1080' => (1440, 1080),
      '1440' => (1920, 1440),
      _ => (960, 720),
    };
