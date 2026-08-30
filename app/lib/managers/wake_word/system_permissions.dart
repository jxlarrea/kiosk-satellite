import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/permissions.dart';
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
    required this.bluetooth,
    required this.bluetoothPair,
    required this.bluetoothNeedsLocation,
    required this.locationServicesOn,
    required this.deviceAdmin,
    required this.writeSettings,
    required this.allFiles,
    required this.usageAccess,
    this.overlayRequestable = true,
    this.batteryRequestable = true,
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

  /// Whether the proxy can actually scan on this Android: the "Nearby
  /// devices" pair (granted at install below 12) AND the location gate.
  /// Location gates scanning on EVERY version: 11 and older tie scan
  /// results to it outright (issue #240), and on 12+ the app deliberately
  /// scans without the neverForLocation flag, because that flag makes
  /// Android strip iBeacon and Eddystone frames, the exact traffic a
  /// presence setup needs relayed (issue #246); the un-flagged scan then
  /// needs the location permission and services just like old Android.
  final bool bluetooth;

  /// The 12+ runtime pair alone, for the row that shows it separately
  /// from the location half. Reads true below 12 (install-time grants).
  final bool bluetoothPair;

  /// Kept true on every version now that location gates all scanning;
  /// remote admin pages built from this payload choose the row wording
  /// with it.
  final bool bluetoothNeedsLocation;

  /// The system-wide location switch, so the rows can tell "permission
  /// missing" from "switch off".
  final bool locationServicesOn;

  /// The device admin grant behind the real "Screen off" (lockNow).
  final bool deviceAdmin;

  /// "Modify system settings": writing the panel's real brightness. Without
  /// it brightness falls back to an app-window override that the system
  /// value (and everything mirroring it) never sees.
  final bool writeSettings;

  /// "All files access": the File Manager's shared-storage root. A settings
  /// screen on Android 11+, the legacy storage dialog before that (issue
  /// #175); without it the manager still works on the app's own folder.
  final bool allFiles;

  /// "Usage access": naming whichever app is on screen, for the MQTT
  /// Foreground app sensor (issue #192). Without it the sensor still knows
  /// when Kiosk Satellite itself is frontmost, just never who else is.
  final bool usageAccess;

  /// Whether the device has a settings screen for the overlay grant and
  /// the battery exemption at all. Some ROMs ship without one (a LineageOS
  /// build on an Echo Show was reported with no "Display over other apps"
  /// anywhere); such a grant is shown with the adb command that gives it
  /// instead of a button, and never blocks the setup wizard.
  final bool overlayRequestable;
  final bool batteryRequestable;

  static const _brightnessChannel = MethodChannel('kiosk_satellite/brightness');
  static const _backgroundChannel = MethodChannel('kiosk_satellite/background');

  static Future<bool> _hasAllFilesAccess() async {
    try {
      return await _backgroundChannel.invokeMethod<bool>('hasAllFilesAccess') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _hasUsageAccess() async {
    try {
      return await _backgroundChannel.invokeMethod<bool>('hasUsageAccess') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static int? _sdkInt;

  /// Below Android 12 there are no runtime Bluetooth permissions: the pair
  /// is granted at install and only the location gate applies (issue #240,
  /// a Fire tablet scanning "actively" and hearing nothing). On 12+ both
  /// halves are real; see [bluetooth].
  static Future<bool> legacyBluetooth() async {
    try {
      _sdkInt ??= (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    } catch (_) {
      return false; // not Android (tests): keep the modern reading
    }
    return _sdkInt! < 31;
  }

  static Future<bool> _bluetoothPairSatisfied() async {
    if (await legacyBluetooth()) return true; // install-time grants
    return await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted;
  }

  static Future<bool> _locationGateSatisfied() async =>
      await Permission.locationWhenInUse.isGranted &&
      (await Permission.location.serviceStatus).isEnabled;

  /// Ask for whatever [bluetooth] needs on this Android, returning whether
  /// scanning is actually unblocked. On 12+ one dialog covers the pair
  /// (they share the "Nearby devices" group; the second request returns
  /// silently), then the location dialog; below 12 the pair is granted at
  /// install and only location is asked. When the location permission is
  /// held but the system-wide location switch is off, the OS location
  /// settings screen is opened, the only place that can flip it.
  static Future<bool> requestBluetooth() async {
    if (!await legacyBluetooth()) {
      final scan = await ensureOsPermission(Permission.bluetoothScan);
      final connect = await ensureOsPermission(Permission.bluetoothConnect);
      if (!scan || !connect) return false;
    }
    return requestLocation();
  }

  /// The location half on its own: the grant, then the OS location
  /// settings screen when the permission is held but the system-wide
  /// switch is off, the only place that can flip it. What the Bluetooth
  /// proxy needs after its pair, and all the location sensors need
  /// (issue #363). Returns whether a position can actually be read.
  static Future<bool> requestLocation() async {
    if (!await ensureOsPermission(Permission.locationWhenInUse)) {
      return false;
    }
    if ((await Permission.location.serviceStatus).isEnabled) return true;
    try {
      await _backgroundChannel.invokeMethod('openLocationSettings');
    } catch (_) {}
    return false;
  }

  static Future<bool> _canWriteSettings() async {
    try {
      return await _brightnessChannel.invokeMethod<bool>('canWrite') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<SystemPermissions> read() async => SystemPermissions(
    microphone: await Permission.microphone.isGranted,
    microphoneBlocked: await Permission.microphone.isPermanentlyDenied,
    displayOverOtherApps: await BackgroundListening.canBringToFront(),
    notification: await Permission.notification.isGranted,
    batteryUnrestricted: await BackgroundListening.isBatteryUnrestricted(),
    camera: await Permission.camera.isGranted,
    location: await Permission.locationWhenInUse.isGranted,
    bluetooth:
        await _bluetoothPairSatisfied() && await _locationGateSatisfied(),
    bluetoothPair: await _bluetoothPairSatisfied(),
    bluetoothNeedsLocation: true,
    locationServicesOn: (await Permission.location.serviceStatus).isEnabled,
    deviceAdmin: await BackgroundListening.isScreenOffAvailable(),
    writeSettings: await _canWriteSettings(),
    allFiles: await _hasAllFilesAccess(),
    usageAccess: await _hasUsageAccess(),
    overlayRequestable: await BackgroundListening.canRequestBringToFront(),
    batteryRequestable:
        await BackgroundListening.canRequestBatteryUnrestricted(),
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
    bluetooth: false,
    bluetoothPair: false,
    bluetoothNeedsLocation: false,
    locationServicesOn: true,
    deviceAdmin: false,
    writeSettings: false,
    allFiles: false,
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
    'bluetooth': bluetooth,
    'bluetoothPair': bluetoothPair,
    'bluetoothNeedsLocation': bluetoothNeedsLocation,
    'locationServicesOn': locationServicesOn,
    'deviceAdmin': deviceAdmin,
    'writeSettings': writeSettings,
    'allFiles': allFiles,
    'usageAccess': usageAccess,
    'overlayRequestable': overlayRequestable,
    'batteryRequestable': batteryRequestable,
  };
}
