import 'package:flutter/services.dart';

/// Retires the failed platform view before Flutter creates its replacement.
class WebViewRecovery {
  static const _channel = MethodChannel('kiosk_satellite/webview_recovery');

  static Future<void> prepare(int viewId) async {
    try {
      await _channel
          .invokeMethod<void>('prepare', {'viewId': viewId})
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // Other platforms and a detached Android Activity still rebuild.
    }
  }
}
