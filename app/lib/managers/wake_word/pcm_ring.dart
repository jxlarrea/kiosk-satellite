import 'dart:typed_data';

import 'pcm16.dart';

/// The last few seconds of what the wake word engine heard, as 16 kHz mono
/// PCM16. Backs the tester's "play the last 10 seconds" and the clip saved
/// with each activation while diagnostics is on.
///
/// A fixed ring: adding a chunk is one or two copies, never an allocation,
/// so leaving it on costs next to nothing per 80 ms chunk.
class PcmRing {
  PcmRing(this.capacity) : _data = Int16List(capacity);

  /// How many samples the ring holds.
  final int capacity;

  final Int16List _data;
  int _write = 0;
  int _length = 0;

  /// Samples currently held, up to [capacity].
  int get length => _length;

  /// Append little-endian PCM16 [bytes]. A trailing odd byte is dropped.
  void add(Uint8List bytes) {
    final count = bytes.length ~/ 2;
    if (count == 0) return;
    final samples = pcm16Samples(bytes, 0, count * 2);
    // Only the newest [capacity] samples of an oversized chunk can survive.
    final skip = count > capacity ? count - capacity : 0;
    var remaining = count - skip;
    var from = skip;
    while (remaining > 0) {
      final run = remaining < capacity - _write ? remaining : capacity - _write;
      _data.setRange(_write, _write + run, samples, from);
      _write = (_write + run) % capacity;
      from += run;
      remaining -= run;
    }
    _length = (_length + count - skip).clamp(0, capacity);
  }

  /// A copy of the newest [samples] samples (fewer when the ring holds less),
  /// oldest first, as little-endian PCM16 bytes.
  Uint8List last(int samples) {
    final n = samples < _length ? samples : _length;
    final out = Int16List(n);
    final start = (_write - n + capacity) % capacity;
    final head = n < capacity - start ? n : capacity - start;
    out.setRange(0, head, _data, start);
    if (head < n) out.setRange(head, n, _data, 0);
    return Uint8List.view(out.buffer);
  }

  void clear() {
    _write = 0;
    _length = 0;
  }
}
