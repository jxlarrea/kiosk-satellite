import 'dart:isolate';

/// Hold a chunk's score messages until all of its processing has finished.
/// Timing includes PCM conversion, the frontend, every active model and the
/// detection gates. Disabled telemetry does no per-chunk allocation or timing.
class ChunkTelemetry {
  ChunkTelemetry(this._port);
  final SendPort _port;
  final _watch = Stopwatch();
  final List<Map<String, Object?>> _messages = [];
  bool _enabled = false;

  void begin(bool enabled) {
    _enabled = enabled;
    if (enabled) {
      _watch
        ..reset()
        ..start();
    }
  }

  void add(Map<String, Object?> message) => _messages.add(message);

  void end() {
    if (!_enabled) return;
    _watch.stop();
    final elapsed = _watch.elapsedMicroseconds;
    for (final message in _messages) {
      message['chunkLatencyUs'] = elapsed;
      _port.send(message);
    }
    _messages.clear();
  }
}
