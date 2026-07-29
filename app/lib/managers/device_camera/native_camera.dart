import 'package:flutter/services.dart';

/// Dart side of the native snapshot bridge (`DeviceCamera.kt`).
///
/// One call, one JPEG. The native side shares the camera with the motion
/// detector: while motion holds the sensor the snapshot rides its session,
/// otherwise the camera is opened, read once, and released.
class NativeCamera {
  static const _channel = MethodChannel('kiosk_satellite/camera');

  /// A JPEG still from [camera] ('front' or 'back'). Throws a
  /// [PlatformException] when the capture fails, or a
  /// [MissingPluginException] when no Activity is attached (the cached
  /// engine outlives the Activity; there is no camera without one).
  static Future<Uint8List?> snapshot({required String camera}) =>
      _channel.invokeMethod<Uint8List>('snapshot', {'camera': camera});
}
