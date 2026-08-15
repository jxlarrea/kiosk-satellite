import 'package:flutter/services.dart';

/// The system tap sound, for the dashboard's tap-sound setting.
///
/// Two fire-and-forget kinds, the audible twins of [Haptics]: [tap] plays
/// the platform's own touch-sound click for a completed press on
/// something button-shaped, [tick] plays it quieter for a slider crossing
/// a step. TapSoundBridge.kt plays the sample from its own SoundPool, so
/// the system's "touch sounds" setting cannot silently veto the feature,
/// and the click is the exact sound the app's Flutter buttons make.
/// Every device has a speaker, so unlike the vibrator there is nothing to
/// probe; each call is one message and never blocks or throws.
///
/// [volume] is 0..1 of the sample's full scale, read per event from the
/// volume setting by the caller (like the vibration strength), so the
/// slider applies to the very next tap. A tick stays its fixed fraction
/// of the given volume; the bridge applies that.
class TapSound {
  TapSound._();

  static const _channel = MethodChannel('kiosk_satellite/tap_sound');

  /// The full click for a button press.
  static void tap({double volume = 1}) => _play('tap', volume);

  /// The quieter click for a slider step.
  static void tick({double volume = 1}) => _play('tick', volume);

  static void _play(String kind, double volume) {
    if (volume <= 0) return;
    _channel
        .invokeMethod<void>('play', {'kind': kind, 'volume': volume})
        .catchError((_) {});
  }
}
