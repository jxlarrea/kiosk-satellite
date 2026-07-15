import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/wake_word/oww/oww_gate.dart';

/// openWakeWord's gate: raw per-frame probabilities (no averaging), a
/// high-confidence bypass, and a frame-windowed borderline confirmation.
void main() {
  // Voice Satellite's wake default at "Moderately sensitive".
  OwwGate gate({double cutoff = 0.5}) => OwwGate(cutoff: cutoff);

  test('at or below the cutoff never fires', () {
    final g = gate();
    expect(g.update(0.5, 0), isNull, reason: 'strictly greater than cutoff');
    expect(g.update(0.1, 80), isNull);
  });

  test('a confident score fires immediately, with no averaging', () {
    final g = gate();
    // cutoff 0.5 + 0.25 = 0.75, but the floor is 0.80.
    expect(g.bypassThreshold, 0.80);
    expect(g.update(0.99, 0), OwwTrigger.immediate,
        reason: 'a single frame is enough; oww does not average');
  });

  test('the bypass floor applies to low cutoffs', () {
    // "Very sensitive" drops the cutoff to 0.4; cutoff + 0.25 = 0.65, but a
    // score that low must still confirm rather than bypass.
    final g = gate(cutoff: 0.4);
    expect(g.bypassThreshold, 0.80);
    expect(g.update(0.70, 0), isNull);
  });

  test('the bypass tracks a raised cutoff', () {
    // "Slightly sensitive" raises it to 0.6: 0.6 + 0.25 = 0.85 > the 0.80 floor.
    final g = gate(cutoff: 0.6);
    expect(g.bypassThreshold, closeTo(0.85, 1e-9));
    expect(g.update(0.82, 0), isNull, reason: 'below bypass: must confirm');
  });

  test('a borderline score parks, then confirms on an adjacent frame', () {
    final g = gate();
    expect(g.update(0.6, 0), isNull, reason: 'first sighting parks');
    expect(g.update(0.6, 80), OwwTrigger.confirmed);
  });

  test('a borderline confirmation expires after the frame window', () {
    final g = gate();
    expect(g.update(0.6, 0), isNull);
    for (var i = 1; i <= 8; i++) {
      g.update(0.1, i * 80); // quiet frames still advance the frame counter
    }
    // The parked sighting is now 9 frames old: too far to count as adjacent.
    expect(g.update(0.6, 9 * 80), isNull, reason: 'stale, re-parks instead');
    expect(g.update(0.6, 10 * 80), OwwTrigger.confirmed);
  });

  test('cooldown stops one utterance cascading', () {
    final g = gate();
    expect(g.update(0.99, 0), OwwTrigger.immediate);
    expect(g.update(0.99, 500), isNull, reason: 'inside the cooldown');
    expect(g.update(0.99, 2500), OwwTrigger.immediate);
  });

  test('a borderline hit inside the cooldown does not park', () {
    final g = gate();
    expect(g.update(0.99, 0), OwwTrigger.immediate);
    // Two borderline hits during the cooldown must not confirm the moment it
    // expires: that would let the tail of one utterance fire a second turn.
    expect(g.update(0.6, 100), isNull);
    expect(g.update(0.6, 180), isNull);
    expect(g.update(0.6, 2500), isNull, reason: 'parks fresh after cooldown');
    expect(g.update(0.6, 2580), OwwTrigger.confirmed);
  });

  test('reset drops accumulated state', () {
    final g = gate();
    expect(g.update(0.6, 0), isNull);
    g.reset();
    expect(g.update(0.6, 80), isNull, reason: 'no stale sighting to confirm');
  });
}
