import 'package:permission_handler/permission_handler.dart';

/// What came of asking for a permission.
enum PermissionOutcome {
  granted,

  /// Refused, but askable again. Android's first "Don't allow".
  declined,

  /// Refused with no way left to ask: Android promotes a permission to this
  /// after the second refusal, and from then on `request()` returns instantly
  /// without ever showing a dialog. Only the OS settings screen can undo it,
  /// so anything that hits this must say so and offer to open it — otherwise a
  /// stray tap silently and permanently disables a feature.
  blocked,
}

/// Ask for [permission], and report which of the three answers we got.
///
/// Requested lazily, at the point of use, rather than all at once at launch:
/// a kiosk that opens with a stack of system dialogs teaches its owner to tap
/// through them.
///
/// Both users of the microphone come through here — the WebView, when a page
/// calls getUserMedia, and the native wake-word engine. That matters more than
/// it looks: the whole point of the Voice Satellite handoff is that the card
/// *stops* calling getUserMedia, so the WebView's request is exactly the one
/// that no longer fires. An engine that relied on the browser to have asked
/// first would open its microphone into a permission that was never granted.
Future<PermissionOutcome> requestOsPermission(Permission permission) async {
  final status = await permission.status;
  if (status.isGranted) return PermissionOutcome.granted;

  // Deliberately not trusting `status.isPermanentlyDenied` to route us here.
  // Android cannot report "blocked" from a cold check: a never-asked permission
  // and a twice-refused one look identical to it, so the status reads `denied`
  // for both. Asking is the only way to find out, and asking a blocked
  // permission is free — the OS returns immediately without a dialog.
  final result = await permission.request();
  if (result.isGranted) return PermissionOutcome.granted;
  if (result.isPermanentlyDenied) return PermissionOutcome.blocked;

  // Still refused, and Android will not commit either way. `shouldShowRationale`
  // is the one honest signal there is, and only *after* a request: true means
  // the user said no and the OS is still willing to ask; false, having just
  // asked, means it will never show that dialog again.
  //
  // Measured on the device, which is the only place this shows up: with the
  // permission set to denied+USER_FIXED — what Android does after the second
  // "Don't allow" — request() returns plain `denied`, not `permanentlyDenied`.
  // Believing that would have us promise "retry to be asked again" forever
  // while never offering the settings screen that is the actual way back.
  final canAskAgain = await permission.shouldShowRequestRationale;
  return canAskAgain ? PermissionOutcome.declined : PermissionOutcome.blocked;
}

/// [requestOsPermission] for callers that only care whether they may proceed.
Future<bool> ensureOsPermission(Permission permission) async =>
    await requestOsPermission(permission) == PermissionOutcome.granted;

/// Open this app's page in the OS settings, the only way back from
/// [PermissionOutcome.blocked].
Future<bool> openOsAppSettings() => openAppSettings();
