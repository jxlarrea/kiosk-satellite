import 'dart:typed_data';

/// The microphone the native pipeline transport draws from.
///
/// [WakeWordManager] in production (the engine already holds the mic for
/// wake detection, and its stream opens with the pre-roll the turn needs);
/// a test double everywhere else.
abstract class NativeAudioSource {
  /// Open the in-process audio stream. Chunks are 16 kHz mono PCM16 LE;
  /// `preRoll` marks replayed already-captured audio flushed at open.
  /// False when there is nothing to stream from (engine not running).
  Future<bool> openNativeAudioStream(
      void Function(Uint8List pcm, bool preRoll) onChunk);

  Future<void> closeNativeAudioStream();
}
