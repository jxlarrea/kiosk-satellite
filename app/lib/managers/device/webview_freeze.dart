import 'package:flutter/services.dart';

/// Native visibility switch for the dashboard WebView (see WebViewFreeze.kt):
/// INVISIBLE stops Chromium compositing under the screensaver while the page
/// keeps ordinary hidden-document behavior — timers throttled but running,
/// events delivered, the websocket still consumed. Matched by URL prefix so
/// the screensaver's own media WebView and rotation overlays are never
/// touched.
class WebViewFreeze {
  static const _channel = MethodChannel('kiosk_satellite/webview_freeze');

  /// Returns how many WebViews were switched. 0 means the dashboard view was
  /// not found (no Activity, mid-rebuild, or the page not loaded yet) — the
  /// caller decides whether to retry.
  static Future<int> setHidden({
    required bool hidden,
    required String urlPrefix,
  }) async {
    try {
      return await _channel.invokeMethod<int>('setHidden', {
            'hidden': hidden,
            'urlPrefix': urlPrefix,
          }) ??
          0;
    } catch (_) {
      // MissingPluginException while the Activity is destroyed, or any
      // platform failure: nothing was switched.
      return 0;
    }
  }

  /// Suppress or restore the dashboard's native scrollbars — the carousel
  /// hides them around a drag, where drift and the parked preview's widened
  /// content extent awaken bars over an animation that is not a scroll.
  static Future<int> setScrollBars({
    required bool hidden,
    required String urlPrefix,
  }) async {
    try {
      return await _channel.invokeMethod<int>('setScrollBars', {
            'hidden': hidden,
            'urlPrefix': urlPrefix,
          }) ??
          0;
    } catch (_) {
      return 0;
    }
  }
}
