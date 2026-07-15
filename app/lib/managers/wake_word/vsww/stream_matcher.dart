import 'dart:math' as math;
import 'dart:typed_data';

import 'ctc_decoder.dart';
import 'manifest.dart';

/// Cross-window streaming matcher, ported from `ctc-decoder.js`
/// (enableStreamMatch / streamUpdate / streamAnalyze).
///
/// Stitches per-frame argmax phonemes across successive inference windows —
/// sampled `lag` frames behind the window edge, where emissions have enough
/// right-context to stabilize — into a rolling buffer, then runs the same
/// edit-distance matcher over the collapsed sequence. Catches wake words that
/// straddle a single 1.3 s window (e.g. "okay … nabu" with a pause).
class StreamMatcher {
  StreamMatcher(this.manifest, this._decoder)
      : _frameMs = manifest.windowMs / manifest.tOut,
        _lag = _clamp(math.max(4, manifest.runtime.streamLagFrames),
            manifest.tOut - 2),
        _frameSamples =
            (manifest.feature.windowSamples / manifest.tOut).round() {
    _bufFrames = math.max(manifest.tOut,
        (manifest.runtime.streamBufferMs / _frameMs).round());
  }

  final VswwManifest manifest;
  final CtcDecoder _decoder;
  final double _frameMs;
  final int _lag;
  final int _frameSamples;
  late final int _bufFrames;

  final List<int> _ids = [];
  final List<double> _logits = [];
  int _sampleAcc = 0;
  bool _bootstrapped = false;
  bool _dirtySinceAnalyze = false;
  int _matchStreak = 0;
  MatchResult _lastVerdict = MatchResult.miss;

  static int _clamp(int v, int hi) => v < 0 ? 0 : (v > hi ? hi : v);

  void reset() {
    _ids.clear();
    _logits.clear();
    _sampleAcc = 0;
    _bootstrapped = false;
    _dirtySinceAnalyze = false;
    _matchStreak = 0;
    _lastVerdict = MatchResult.miss;
  }

  /// Feed one inference window's logits [tOut, vocab] plus the number of new
  /// audio samples since the previous update.
  void update(Float32List logits, int newSamples, int tOut, int vocab) {
    final blank = manifest.ctc.blankId;
    final pad = manifest.ctc.padId;

    int argAt(int t) {
      final off = t * vocab;
      var best = 0;
      var bestVal = logits[off];
      for (var v = 1; v < vocab; v++) {
        if (logits[off + v] > bestVal) {
          bestVal = logits[off + v];
          best = v;
        }
      }
      return best;
    }

    double logitAt(int t, int id) => logits[t * vocab + id];

    void push(int t) {
      final id = argAt(t);
      _ids.add(id);
      _logits.add(logitAt(t, id));
      if (id != blank && id != pad) _dirtySinceAnalyze = true;
    }

    final edge = tOut - _lag; // frames before this are stable
    if (!_bootstrapped) {
      for (var t = 0; t < edge; t++) {
        push(t);
      }
      _bootstrapped = true;
    } else {
      _sampleAcc += newSamples;
      var newFrames = _sampleAcc ~/ _frameSamples;
      _sampleAcc -= newFrames * _frameSamples;
      if (newFrames > edge) newFrames = edge;
      for (var t = edge - newFrames; t < edge; t++) {
        if (t >= 0) push(t);
      }
    }

    // trim to buffer length from the front
    final overflow = _ids.length - _bufFrames;
    if (overflow > 0) {
      _ids.removeRange(0, overflow);
      _logits.removeRange(0, overflow);
    }
  }

  /// Run the matcher over the current stitched buffer.
  MatchResult analyze() {
    // Throttle: nothing new and last time was a miss → reuse.
    if (!_dirtySinceAnalyze && !_lastVerdict.matched) return _lastVerdict;
    _dirtySinceAnalyze = false;

    // Collapse consecutive duplicates, drop blank/pad, average logits.
    final blank = manifest.ctc.blankId;
    final pad = manifest.ctc.padId;
    final ids = <int>[];
    final conf = <double>[];
    var i = 0;
    while (i < _ids.length) {
      final tok = _ids[i];
      var j = i;
      var sum = 0.0;
      while (j < _ids.length && _ids[j] == tok) {
        sum += _logits[j];
        j++;
      }
      if (tok != blank && tok != pad) {
        ids.add(tok);
        conf.add(sum / (j - i));
      }
      i = j;
    }

    final result = _decoder.match(CtcDecode(ids, conf));
    if (result.matched) {
      _matchStreak++;
      if (_matchStreak >= 4) {
        // one utterance shouldn't re-fire after cooldown
        _ids.clear();
        _logits.clear();
        _matchStreak = 0;
      }
    } else {
      _matchStreak = 0;
    }
    _lastVerdict = result;
    return result;
  }
}
