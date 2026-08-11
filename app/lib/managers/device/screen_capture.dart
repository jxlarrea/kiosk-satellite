import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// A generated stand-in for the one thing no capture can show: a panel that
/// is truly powered off. With the display dark nothing composites frames,
/// so PixelCopy either fails outright (Android 11) or hands back a
/// half-drawn page (Android 16), and the WebView fallback is no better.
/// This says what the display actually shows.
Future<Uint8List> screenOffPlaceholder({int width = 1280}) async {
  // Match the panel's aspect so the admin's preview box keeps its shape;
  // 16:10 landscape when the size is unreadable.
  final size = ui.PlatformDispatcher.instance.implicitView?.physicalSize;
  final aspect = (size != null && size.width > 0 && size.height > 0)
      ? size.height / size.width
      : 10 / 16;
  final w = (width > 0 ? width : 1280).toDouble();
  final h = (w * aspect).roundToDouble();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w, h),
    Paint()..color = const Color(0xFF101014),
  );
  final text = TextPainter(
    text: TextSpan(
      text: 'Screen off',
      style: TextStyle(color: const Color(0x99FFFFFF), fontSize: w / 18),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  text.paint(canvas, Offset((w - text.width) / 2, (h - text.height) / 2));
  final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

/// What the display is actually showing — WebView, menus, screensaver and
/// all — captured natively via PixelCopy on a background thread (see
/// ScreenCapture.kt). Null when there is no live Activity window (the app is
/// backgrounded), on Android < 8, or when the platform declines; callers
/// fall back to the WebView's own main-thread, page-only capture.
class ScreenCapture {
  static const _channel = MethodChannel('kiosk_satellite/screen_capture');

  static Future<Uint8List?> capture({
    int width = 1280,
    int quality = 80,
  }) async {
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
