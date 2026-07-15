import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/wake_word/mww/mww_gate.dart';

/// The microWakeWord gate, mirroring Voice Satellite's browser behaviour:
/// sliding-window mean vs cutoff, warmup discard, cooldown, and the
/// two-sightings rule for borderline means.
void main() {
  // ok_nabu's manifest: probability_cutoff 0.85, sliding_window_size 5.
  MwwGate gate({double cutoff = 0.85, int window = 5, int warmup = 0}) =>
      MwwGate(cutoff: cutoff, slidingWindowSize: window, warmupFrames: warmup);

  /// Feed the same probability n times, returning the FIRST verdict that
  /// fired. Not the last: a trigger starts its own cooldown, so every frame
  /// after it in the same burst correctly returns null.
  MwwTrigger? feed(MwwGate g, double p, int n, {int startMs = 0, int stepMs = 30}) {
    MwwTrigger? first;
    for (var i = 0; i < n; i++) {
      final v = g.update(p, startMs + i * stepMs);
      first ??= v;
    }
    return first;
  }

  test('needs a full window before it can fire', () {
    final g = gate();
    // Four confident frames are not enough: the mean is over 5.
    expect(feed(g, 0.99, 4), isNull);
    expect(g.update(0.99, 120), MwwTrigger.immediate);
  });

  test('a mean at or below the cutoff never fires', () {
    final g = gate();
    expect(feed(g, 0.85, 20), isNull, reason: 'strictly greater than cutoff');
    expect(feed(g, 0.5, 20), isNull);
  });

  test('warmup frames are discarded', () {
    final g = gate(warmup: 100);
    // Confident from the first frame, but the model state may still be warm.
    expect(feed(g, 0.99, 100), isNull);
    expect(feed(g, 0.99, 5, startMs: 3000), MwwTrigger.immediate);
  });

  test('cooldown stops one utterance cascading', () {
    final g = gate();
    expect(feed(g, 0.99, 5), MwwTrigger.immediate);
    // Still shouting a moment later: no second trigger inside the cooldown.
    expect(feed(g, 0.99, 5, startMs: 200), isNull);
    // Past it, it can fire again.
    expect(feed(g, 0.99, 5, startMs: 2500), MwwTrigger.immediate);
  });

  test('a lone borderline mean is parked, not fired', () {
    final g = gate();
    // 0.86 is above the 0.85 cutoff but inside the 0.03 confirm margin.
    expect(feed(g, 0.86, 5), isNull);
  });

  test('a borderline mean fires on a second sighting in the window', () {
    final g = gate();
    expect(feed(g, 0.86, 5), isNull, reason: 'first sighting parks');
    expect(g.update(0.86, 100), MwwTrigger.confirmed);
  });

  test('a borderline mean expires if the second sighting is late', () {
    final g = gate();
    expect(feed(g, 0.86, 5), isNull);
    // 750ms confirm window has passed: the stale sighting is dropped, and the
    // reference does NOT re-park on that same frame.
    expect(g.update(0.86, 1000), isNull, reason: 'stale first sighting drops');
    expect(g.update(0.86, 1030), isNull, reason: 're-parks');
    expect(g.update(0.86, 1060), MwwTrigger.confirmed);
  });

  test('a confident mean skips the confirm dance entirely', () {
    final g = gate();
    // cutoff + margin = 0.88; at or above fires immediately.
    expect(feed(g, 0.88, 5), MwwTrigger.immediate);
  });

  test('reset drops accumulated state', () {
    final g = gate();
    feed(g, 0.99, 4);
    g.reset();
    // The window is empty again, so four more frames still cannot fire.
    expect(feed(g, 0.99, 4, startMs: 5000), isNull);
  });
}
