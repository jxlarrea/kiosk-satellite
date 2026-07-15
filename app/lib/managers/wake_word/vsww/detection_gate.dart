import 'manifest.dart';

/// Counter-mode detection gate, ported from `backend.js` `_gateCounter` +
/// cooldown. Consumes one per-chunk verdict (matched?/confidence/target) and
/// decides whether a wake word fired, applying consecutive-hit counting,
/// the high-confidence bypass, and the cooldown.
///
/// This is a persistent per-keyword state machine: feed it one result per
/// 80 ms audio chunk, in order.
class DetectionGate {
  DetectionGate(this.runtime);

  final VswwRuntimeConfig runtime;

  int _hits = 0;
  int _lastTargetIndex = -1;
  int _lastTriggerAtMs = -1 << 30;

  void reset() {
    _hits = 0;
    _lastTargetIndex = -1;
  }

  /// Update with a chunk verdict. Returns true on a fresh detection.
  ///  - [matched]: per-window OR stream match this chunk.
  ///  - [matchedConfidence]: mean raw logit over the matched window.
  ///  - [targetIndex]: which wake-word target matched (for streak grouping).
  ///  - [nowMs]: monotonic clock in ms (for the cooldown).
  bool update({
    required bool matched,
    required double matchedConfidence,
    required int targetIndex,
    required int nowMs,
  }) {
    if (!matched) {
      // Any sub-cutoff chunk breaks the consecutive streak.
      _hits = 0;
      _lastTargetIndex = -1;
      return false;
    }

    // consecutive matched windows of the same target group increment hits
    final nextHits = (targetIndex == _lastTargetIndex) ? _hits + 1 : 1;
    _hits = nextHits;
    _lastTargetIndex = targetIndex;

    var trigger = false;
    final bypass = runtime.highConfidenceBypass;
    if (bypass != null &&
        matchedConfidence >= bypass &&
        nextHits >= runtime.highConfidenceBypassMinHits) {
      trigger = true;
    } else if (nextHits >= runtime.requiredHits) {
      trigger = true;
    }

    if (!trigger) return false;

    // fire, then reset the counter
    _hits = 0;
    _lastTargetIndex = -1;
    if ((nowMs - _lastTriggerAtMs) < runtime.cooldownMs) return false;
    _lastTriggerAtMs = nowMs;
    return true;
  }
}
