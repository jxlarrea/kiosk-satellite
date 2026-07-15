/// openWakeWord's detection gate.
///
/// Mirrors Voice Satellite's browser gate (`oww/backend.js`) so a wake word
/// behaves the same whoever runs it. It is a third distinct shape, and the
/// differences are calibration rather than accident:
///
///  - **No averaging.** The card runs openWakeWord with `slidingWindow: 1`, so
///    each inference frame's probability is judged on its own. (microWakeWord
///    means over 5 frames; vsWakeWord counts hits on raw logits.)
///  - **High-confidence bypass:** at or above `max(cutoff + 0.25, 0.80)` a
///    single frame fires immediately, so confident hits feel responsive.
///  - **Borderline confirmation:** anything above the cutoff but below that
///    needs a second hit, deliberately measured in *frames* rather than
///    wall-clock, so replay/catch-up processing still counts adjacent audio as
///    adjacent.
///  - A cooldown stops one utterance cascading into several triggers.
library;

/// How a trigger cleared the gate. Diagnostic only.
enum OwwTrigger { immediate, confirmed }

class OwwGate {
  OwwGate({
    required this.cutoff,
    this.cooldownMs = 2000,
    this.borderlineConfirmMargin = 0.03,
    this.bypassMargin = 0.25,
    this.bypassMinScore = 0.80,
    this.confirmMinFrames = 1,
    this.confirmWindowFrames = 8,
  });

  /// Absolute cutoff, resolved by the card from its Sensitivity setting.
  final double cutoff;
  final int cooldownMs;
  final double borderlineConfirmMargin;

  /// Scores at or above `max(cutoff + bypassMargin, bypassMinScore)` skip
  /// confirmation.
  final double bypassMargin;
  final double bypassMinScore;

  /// Frames that must pass between the parked hit and the confirming one, and
  /// the window it must arrive in (each frame is ~80 ms of audio).
  final int confirmMinFrames;
  final int confirmWindowFrames;

  int _frame = 0;
  int _lastTriggerMs = -1 << 40;
  bool _pendingConfirm = false;
  int _pendingConfirmFrame = 0;
  double _latestScore = 0;

  /// The most recent probability. Diagnostic.
  double get latestScore => _latestScore;

  /// The score at or above which a single frame fires without confirmation.
  double get bypassThreshold =>
      (cutoff + bypassMargin) > bypassMinScore ? cutoff + bypassMargin : bypassMinScore;

  /// Feed one inference result. [nowMs] is a monotonic clock.
  OwwTrigger? update(double probability, int nowMs) {
    _frame++;
    _latestScore = probability;

    if (probability <= cutoff) {
      _clearPending();
      return null;
    }
    if (nowMs - _lastTriggerMs <= cooldownMs) {
      // Inside the cooldown: do not park a candidate either, or the first
      // frame after it expires would confirm against a stale sighting.
      _clearPending();
      return null;
    }

    if (probability >= bypassThreshold) {
      _clearPending();
      _lastTriggerMs = nowMs;
      return OwwTrigger.immediate;
    }

    if (_pendingConfirm) {
      final age = _frame - _pendingConfirmFrame;
      if (age >= confirmMinFrames && age <= confirmWindowFrames) {
        _clearPending();
        _lastTriggerMs = nowMs;
        return OwwTrigger.confirmed;
      }
      if (age > confirmWindowFrames) {
        // Too late to count as adjacent evidence: drop it and park this hit
        // as the new first sighting.
        _pendingConfirmFrame = _frame;
        return null;
      }
      return null; // same frame; wait for the next
    }

    _pendingConfirm = true;
    _pendingConfirmFrame = _frame;
    return null;
  }

  void _clearPending() {
    _pendingConfirm = false;
    _pendingConfirmFrame = 0;
  }

  /// Drop accumulated state when re-arming after a turn.
  void reset() {
    _frame = 0;
    _clearPending();
    _latestScore = 0;
  }
}
