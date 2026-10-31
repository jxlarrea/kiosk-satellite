import 'package:flutter/services.dart';

/// Dart side of the native 16 kHz mono PCM16 microphone stream (Android
/// `MicRecorder`, EventChannel `kiosk_satellite/mic`).
///
/// Listening starts capture; cancelling the subscription stops it and releases
/// the mic. Each event is a chunk of little-endian 16-bit PCM bytes.
class NativeMic {
  static const _channel = EventChannel('kiosk_satellite/mic');

  /// The user's capture device as an AudioRouting selector
  /// ("type|address|name", empty = Android routes). Set by AudioRoutingManager
  /// at startup and on setting changes; read when a stream opens, so it must
  /// be current before the engine (re)starts.
  static String deviceSelector = '';

  /// The capture tuning from Microphone settings, set alongside
  /// [deviceSelector] and read at the same moment: the platform applies all
  /// of it when the session opens, so changing any of them needs a restart.
  static num gainDb = 0;

  /// The Android capture source: 'mic' (the raw microphone) or
  /// 'voice_communication' (the call path).
  static String captureMode = 'mic';

  /// WebRTC's echo canceller over the capture, fed what the kiosk plays.
  static bool softwareEchoCancellation = true;

  /// WebRTC's noise suppressor over the capture.
  static bool noiseSuppression = false;

  /// 1-based channel of a multichannel microphone to capture; 0 lets the
  /// platform downmix (which averages every channel together).
  static num channel = 0;

  /// 'auto' asks for 16 kHz mono and lets the platform convert; 'hardware'
  /// opens 48 kHz stereo, the only format some sound cards record in, and
  /// the native side converts. Either way this stream is 16 kHz mono.
  static String captureFormat = 'auto';

  /// Where the capture's warnings go (a format that failed, a read that
  /// stalled), so they reach the app log and not only logcat. Set by
  /// AudioRoutingManager with the other capture settings.
  static void Function(String warning)? onWarning;

  static const _levels = MethodChannel('kiosk_satellite/mic_levels');

  /// How loud the last [length] of the microphone was, in dBFS per 20 ms,
  /// oldest first, measured before the noise suppressor. Null where the
  /// platform does not keep them or the microphone has not delivered.
  static Future<List<double>?> recentLevels(Duration length) async {
    try {
      final r = await _levels.invokeMethod<List<Object?>>('recent', {
        'ms': length.inMilliseconds,
      });
      if (r == null || r.isEmpty) return null;
      return [for (final v in r) (v as num).toDouble()];
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Stream<Uint8List> stream() => _channel
      .receiveBroadcastStream({
        if (deviceSelector.isNotEmpty) 'device': deviceSelector,
        'source': captureMode,
        'gainDb': gainDb,
        'softwareAec': softwareEchoCancellation,
        'noiseSuppression': noiseSuppression,
        'channel': channel,
        'format': captureFormat,
      })
      // Besides PCM the platform sends the capture's warnings (a format
      // that failed, a read that stalled), so they reach the app log.
      .where((e) {
        if (e is! Map) return true;
        final warning = e['warning'];
        if (warning is String) onWarning?.call(warning);
        return false;
      })
      .map((e) => e as Uint8List);
}
