import 'package:permission_handler/permission_handler.dart';

import '../device/device_details.dart';
import 'background_listening.dart';

/// The OS grants native wake-word detection needs, read in one place.
///
/// Read once and rendered twice: the device's settings screen and the remote
/// admin show the same rows about the same device, and neither may decide for
/// itself what "granted" means.
///
/// Only the device can *give* these — they are Android dialogs and settings
/// screens — so the remote admin shows them and says where to go. That is not a
/// gap: a permission granted from another room would not be much of a
/// permission.
class SystemPermissions {
  const SystemPermissions({
    required this.microphone,
    required this.microphoneBlocked,
    required this.displayOverOtherApps,
    required this.notification,
    required this.batteryUnrestricted,
    required this.camera,
    required this.location,
    required this.usageAccess,
  });

  /// Nothing listens without this one, foreground or not.
  final bool microphone;

  /// Refused for good: Android will not ask again, so only its settings screen
  /// can undo it.
  final bool microphoneBlocked;

  /// Whether we may come forward on a detection from behind another app.
  final bool displayOverOtherApps;

  /// Whether the device may say, on screen, that it is listening.
  final bool notification;

  /// Whether Android will leave the background listener running.
  final bool batteryUnrestricted;

  /// Motion detection, and any page that asks for a camera.
  final bool camera;

  /// Only a page ever wants this (geolocation). Nothing native here uses it.
  final bool location;

  /// "Usage access", the special grant needed to ask which app is in front.
  /// Nothing depends on it; it buys one diagnostic field.
  final bool usageAccess;

  static Future<SystemPermissions> read() async => SystemPermissions(
        microphone: await Permission.microphone.isGranted,
        microphoneBlocked: await Permission.microphone.isPermanentlyDenied,
        displayOverOtherApps: await BackgroundListening.canBringToFront(),
        notification: await Permission.notification.isGranted,
        batteryUnrestricted: await BackgroundListening.isBatteryUnrestricted(),
        camera: await Permission.camera.isGranted,
        location: await Permission.locationWhenInUse.isGranted,
        usageAccess: (await DeviceDetails.read()).hasUsageAccess,
      );

  /// Nothing we could not read. A platform without these channels answers
  /// everything false, which would draw as a wall of red rather than an honest
  /// "not applicable"; callers use [unknown] to tell the two apart.
  static const unknown = SystemPermissions(
    microphone: false,
    microphoneBlocked: false,
    displayOverOtherApps: false,
    notification: false,
    batteryUnrestricted: false,
    camera: false,
    location: false,
    usageAccess: false,
  );

  Map<String, Object?> toJson() => {
        'microphone': microphone,
        'microphoneBlocked': microphoneBlocked,
        'displayOverOtherApps': displayOverOtherApps,
        'notification': notification,
        'batteryUnrestricted': batteryUnrestricted,
        'camera': camera,
        'location': location,
        'usageAccess': usageAccess,
      };
}
