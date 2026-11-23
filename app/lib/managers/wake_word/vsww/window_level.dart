import 'dart:math' as math;
import 'dart:typed_data';

/// RMS of the loudest [span] samples in a row of a ring window whose oldest
/// sample is at [head], placed on a [step] sample grid.
///
/// The silence veto reads this next to the whole window's RMS. A short wake
/// word said close to a quiet microphone fills only part of the window, so
/// the window's RMS counts the quiet around it too. Speech across the room
/// is just as quiet in its loudest stretch as anywhere else. When [span]
/// covers the whole window this is the window's RMS.
double loudestRms(Float32List ring, int head, int span, {int step = 160}) {
  final n = ring.length;
  if (n == 0) return 0;
  final blocks = n ~/ step;
  final per = math.min(span ~/ step, blocks);
  if (per <= 0 || per >= blocks) {
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      sum += ring[i] * ring[i];
    }
    return math.sqrt(sum / n);
  }
  // A window that is not a whole number of steps leaves its oldest samples
  // out, so the newest ones always count.
  var idx = (head + n - blocks * step) % n;
  final sums = Float64List(blocks);
  for (var b = 0; b < blocks; b++) {
    var s = 0.0;
    for (var i = 0; i < step; i++) {
      final v = ring[idx];
      s += v * v;
      if (++idx == n) idx = 0;
    }
    sums[b] = s;
  }
  var run = 0.0;
  for (var b = 0; b < per; b++) {
    run += sums[b];
  }
  var best = run;
  for (var b = per; b < blocks; b++) {
    run += sums[b] - sums[b - per];
    if (run > best) best = run;
  }
  return math.sqrt(math.max(0.0, best) / (per * step));
}
