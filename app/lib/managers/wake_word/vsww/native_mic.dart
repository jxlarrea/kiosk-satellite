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

  Stream<Uint8List> stream() => _channel
      .receiveBroadcastStream(
        deviceSelector.isEmpty ? null : {'device': deviceSelector},
      )
      .map((e) => e as Uint8List);
}
