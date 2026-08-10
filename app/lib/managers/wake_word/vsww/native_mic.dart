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
  static String source = 'voice_communication';
  static num gainDb = 0;
  static bool agc = false;

  /// 1-based channel of a multichannel microphone to capture; 0 lets the
  /// platform downmix (which averages every channel together).
  static num channel = 0;

  Stream<Uint8List> stream() => _channel
      .receiveBroadcastStream({
        if (deviceSelector.isNotEmpty) 'device': deviceSelector,
        'source': source,
        'gainDb': gainDb,
        'agc': agc,
        'channel': channel,
      })
      .map((e) => e as Uint8List);
}
