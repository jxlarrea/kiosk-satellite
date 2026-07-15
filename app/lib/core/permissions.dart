import 'package:permission_handler/permission_handler.dart';

/// Hold [permission], asking the user for it if that is still possible.
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
Future<bool> ensureOsPermission(Permission permission) async {
  var status = await permission.status;
  if (status.isGranted) return true;
  // Nothing left to ask: only the OS settings can undo this.
  if (status.isPermanentlyDenied) return false;
  status = await permission.request();
  return status.isGranted;
}
