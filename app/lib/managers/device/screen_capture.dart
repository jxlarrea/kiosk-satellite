import 'package:flutter/services.dart';

/// What the display is actually showing — WebView, menus, screensaver and
/// all — captured natively via PixelCopy on a background thread (see
/// ScreenCapture.kt). Null when there is no live Activity window (the app is
/// backgrounded), on Android < 8, or when the platform declines; callers
/// fall back to the WebView's own main-thread, page-only capture.
class ScreenCapture {
  static const _channel = MethodChannel('kiosk_satellite/screen_capture');

  static Future<Uint8List?> capture({int width = 720, int quality = 60}) async {
    try {
      return await _channel.invokeMethod<Uint8List>('capture', {
        'width': width,
        'quality': quality,
      });
    } catch (_) {
      // MissingPluginException while the Activity is destroyed, or any
      // platform failure: not an error, just "no window to capture".
      return null;
    }
  }
}
