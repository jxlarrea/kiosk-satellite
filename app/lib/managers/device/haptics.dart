import 'package:flutter/services.dart';

/// The vibration motor, for the dashboard's button-haptics setting.
///
/// Two fire-and-forget kinds: [tap] for a completed press on something
/// button-shaped and [tick] for a slider crossing a step, each at the
/// strength the setting asks for (HapticsBridge.kt maps them onto the
/// platform's tuned effects, a tick always one level softer than a tap).
/// The bridge drives the vibrator directly, so the system's own
/// touch-vibration setting cannot silently veto the feature. Whether a
/// motor exists at all is probed once and cached, so devices without one
/// (most Fire tablets, Echo Shows) pay nothing per tap — the check makes
/// every later call a synchronous no-op.
class Haptics {
  Haptics._();

  static const _channel = MethodChannel('kiosk_satellite/haptics');

  /// null until the first buzz resolves the probe; false off Android.
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

  /// A short native click for a button press. Never throws, never blocks.
  static void tap({String strength = 'medium'}) => _play('tap', strength);

  /// A softer tick for a slider step. Never throws, never blocks.
  static void tick({String strength = 'medium'}) => _play('tick', strength);

  static void _play(String kind, String strength) {
    final args = {'kind': kind, 'strength': strength};
    if (_hasVibrator == false) return;
    if (_hasVibrator == null) {
      // First buzz pays the probe; it still lands if a motor exists.
      _resolve().then((has) {
        if (has) _channel.invokeMethod<void>('tap', args).catchError((_) {});
      });
      return;
    }
    _channel.invokeMethod<void>('tap', args).catchError((_) {});
  }
}
