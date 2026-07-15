/// microWakeWord's detection gate: turns a stream of per-inference
/// probabilities into wake events.
///
/// Mirrors Voice Satellite's browser gate (`micro-inference.js`) so a wake word
/// behaves the same whoever is running it:
///
///  - a sliding-window **mean** over the last `slidingWindowSize`
///    probabilities must exceed the model's cutoff (this is also what ESPHome
///    does, and what the manifest's `probability_cutoff` is calibrated for);
///  - a warmup of [warmupFrames] inferences is discarded, because the model's
///    internal streaming state may still be warm from a previous detection;
///  - a cooldown stops one utterance cascading into several triggers;
///  - borderline means (within [borderlineConfirmMargin] of the cutoff) must
///    happen twice inside [borderlineConfirmWindowMs] before they count. A
///    single marginal spike from e.g. TV speech is not enough.
///
/// Unlike vsWakeWord's gate this reports no wake-word *end*: a window
/// classifier only knows the wake word occurred somewhere in the recent
/// window, which is why the engine trims pre-roll to the detection instant
/// instead (see WakeWordEngine.startAudioStream).
library;

/// How a trigger cleared the gate. Diagnostic only.
enum MwwTrigger { immediate, confirmed }

class MwwGate {
  MwwGate({
    required this.cutoff,
    required this.slidingWindowSize,
    this.warmupFrames = 100,
    this.cooldownMs = 2000,
    this.borderlineConfirmMargin = 0.03,
    this.borderlineConfirmWindowMs = 750,
  }) : _probBuffer = List<double>.filled(slidingWindowSize, 0);

  /// Model's `probability_cutoff`, already scaled by the card's sensitivity.
  final double cutoff;
  final int slidingWindowSize;
  final int warmupFrames;
  final int cooldownMs;
  final double borderlineConfirmMargin;
  final int borderlineConfirmWindowMs;

  final List<double> _probBuffer;
  int _probIndex = 0;
  int _probCount = 0;
  double _probSum = 0;
  int _framesProcessed = 0;
  int _lastTriggerMs = -1 << 40;

  bool _pendingConfirm = false;
  int _pendingConfirmAtMs = 0;

  /// Mean over the filled part of the window. Diagnostic.
  double get windowMean => _probCount > 0 ? _probSum / _probCount : 0;

  /// Feed one inference result. [nowMs] is a monotonic clock.
  /// Returns how it triggered, or null.
  MwwTrigger? update(double probability, int nowMs) {
    _framesProcessed++;
    // Discard warmup: state left over from a previous detection has to flush
    // through before the probabilities mean anything.
    if (_framesProcessed <= warmupFrames) return null;

    if (_probCount >= slidingWindowSize) {
      _probSum -= _probBuffer[_probIndex]; // drop the value being overwritten
    }
    _probBuffer[_probIndex] = probability;
    _probSum += probability;
    _probIndex = (_probIndex + 1) % slidingWindowSize;
    if (_probCount < slidingWindowSize) _probCount++;

    if (_probCount < slidingWindowSize) return null;
    if (nowMs - _lastTriggerMs <= cooldownMs) return null;

    final mean = _probSum / slidingWindowSize;
    final trigger = _classify(mean, nowMs);
    if (trigger != null) _lastTriggerMs = nowMs;
    return trigger;
  }

  MwwTrigger? _classify(double mean, int nowMs) {
    if (mean <= cutoff) {
      _clearPending();
      return null;
    }
    if (mean >= cutoff + borderlineConfirmMargin) {
      _clearPending();
      return MwwTrigger.immediate;
    }
    // Borderline: only counts as a second sighting soon after the first.
    if (_pendingConfirm) {
      final fresh = (nowMs - _pendingConfirmAtMs) <= borderlineConfirmWindowMs;
      _clearPending();
      return fresh ? MwwTrigger.confirmed : null;
    }
    _pendingConfirm = true;
    _pendingConfirmAtMs = nowMs;
    return null;
  }

  void _clearPending() {
    _pendingConfirm = false;
    _pendingConfirmAtMs = 0;
  }

  /// Drop everything the detector has accumulated. Used when re-arming after a
  /// turn, so speech from the turn just handled cannot fire a stale detection.
  void reset() {
    for (var i = 0; i < _probBuffer.length; i++) {
      _probBuffer[i] = 0;
    }
    _probIndex = 0;
    _probCount = 0;
    _probSum = 0;
    _framesProcessed = 0;
    _clearPending();
  }
}
