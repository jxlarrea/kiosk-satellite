import 'dart:async';
import 'dart:typed_data';

import '../wake_word/vsww/native_mic.dart';

/// The one native microphone capture, shared by every consumer.
///
/// MicRecorder is single-client: a second EventChannel listen while capture
/// runs is silently ignored, so two Dart subscribers opening [NativeMic]
/// directly would leave one of them deaf with no error. This hub owns the
/// single native subscription and fans the PCM chunks out: the wake-word
/// engine is one subscriber, the clap detector another, and whichever of them
/// is around keeps the capture open. Reference counting is the broadcast
/// controller's: the native stream opens with the first listener and closes
/// with the last, so a Voice Satellite device pays nothing extra for claps
/// and a clapper-only device never opens a second capture.
class MicHub {
  MicHub._();

  static final MicHub instance = MicHub._();

  /// Opens the underlying native capture; swapped in tests.
  Stream<Uint8List> Function() opener = () => NativeMic().stream();

  StreamController<Uint8List>? _out;
  StreamSubscription<Uint8List>? _native;

  /// Whether the native capture is currently open.
  bool get capturing => _native != null;

  /// 16 kHz mono PCM16 chunks, shared. Listening opens the native capture if
  /// this is the first subscriber; cancelling closes it if it was the last.
  /// A capture failure surfaces as a stream error to every subscriber.
  Stream<Uint8List> stream() {
    _out ??= StreamController<Uint8List>.broadcast(
      onListen: _open,
      onCancel: _close,
    );
    return _out!.stream;
  }

  void _open() {
    _native = opener().listen(
      (chunk) => _out?.add(chunk),
      onError: (Object e) => _out?.addError(e),
    );
  }

  Future<void> _close() async {
    final sub = _native;
    _native = null;
    await sub?.cancel();
  }

  /// Reopen the native capture without disturbing subscribers.
  ///
  /// Capture settings (device, source, gain, AGC, channel) are fixed when the
  /// session opens, so a change needs a fresh open. With a single consumer
  /// that came free — its stop/start was the reopen — but with the capture
  /// shared, one consumer's restart no longer closes the stream, so the
  /// settings change itself must bounce it. No-op while nothing is capturing.
  Future<void> bounce() async {
    if (_native == null) return;
    await _close();
    _open();
  }
}
