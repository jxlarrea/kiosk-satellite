/// Spots near misses in one wake word's score stream, inside the compute
/// isolate, so wake word diagnostics can keep them without the per-inference
/// telemetry the tester uses.
///
/// A near miss is an episode: the score climbs to [ratio] of the threshold,
/// peaks, and falls back without the detector firing. One report per episode,
/// carrying its peak, so a word that almost made it is one entry rather than
/// a run of them. The same 75% line the tester's log calls notable.
///
/// Deliberately a leaf with no imports: the compute isolates depend on it.
library;

class NearMissTracker {
  NearMissTracker({this.ratio = 0.75});

  final double ratio;

  bool _open = false;
  double _peak = 0;
  double _threshold = 0;
  Map<String, Object?> _detail = const {};

  /// Feed one scored inference. [detail] is asked for only when the score
  /// sets a new peak, so costly extras (vsWakeWord's phoneme string) are
  /// built a handful of times per episode, not per inference. Returns the
  /// report when an episode has just ended without firing.
  Map<String, Object?>? update({
    required double score,
    required double threshold,
    required bool fired,
    Map<String, Object?> Function()? detail,
  }) {
    if (fired) {
      // An activation, not a miss.
      _open = false;
      return null;
    }
    final valid = score.isFinite && threshold.isFinite && threshold > 0;
    if (valid && score >= threshold * ratio) {
      if (!_open || score > _peak) {
        _peak = score;
        _threshold = threshold;
        _detail = detail?.call() ?? const {};
      }
      _open = true;
      return null;
    }
    if (!_open) return null;
    _open = false;
    return {..._detail, 'score': _peak, 'threshold': _threshold};
  }

  /// Forget an open episode: the detector was re-armed after a voice turn.
  void reset() => _open = false;
}
