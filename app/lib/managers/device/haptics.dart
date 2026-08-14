import 'package:flutter/services.dart';

/// The vibration motor, for the dashboard's button-haptics setting.
///
/// One method that matters: [tap], a fire-and-forget native click
/// (HapticsBridge.kt drives the vibrator directly, so the system's own
/// touch-vibration setting cannot silently veto the feature). Whether a
/// motor exists at all is probed once and cached, so devices without one
/// (most Fire tablets, Echo Shows) pay nothing per tap — the check makes
/// every later [tap] a synchronous no-op.
class Haptics {
  Haptics._();

  static const _channel = MethodChannel('kiosk_satellite/haptics');

  /// null until the first [tap] resolves the probe; false off Android.
  static bool? _hasVibrator;
  static Future<bool>? _probe;

  static Future<bool> _resolve() => _probe ??= () async {
    try {
      _hasVibrator = await _channel.invokeMethod<bool>('hasVibrator') == true;
    } catch (_) {
      _hasVibrator = false;
    }
    return _hasVibrator!;
  }();

  /// A short native click. Never throws, never blocks the caller.
  static void tap() {
    if (_hasVibrator == false) return;
    if (_hasVibrator == null) {
      // First tap pays the probe; the buzz still lands if a motor exists.
      _resolve().then((has) {
        if (has) _channel.invokeMethod<void>('tap').catchError((_) {});
      });
      return;
    }
    _channel.invokeMethod<void>('tap').catchError((_) {});
  }
}
