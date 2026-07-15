import 'dart:math' as math;
import 'dart:typed_data';

import 'manifest.dart';

/// Result of greedy CTC decoding: the collapsed phoneme ids and a per-phoneme
/// confidence (mean raw logit of the frame-run that emitted it).
class CtcDecode {
  CtcDecode(this.ids, this.confidence, [this.endFrames = const []]);
  final List<int> ids;
  final List<double> confidence;

  /// Index of the last raw frame in each collapsed token's run, in whatever
  /// timeline the logits came from (an inference window for [CtcDecoder.decode],
  /// the stitched buffer for [StreamMatcher.analyze]). Lets a caller recover
  /// *when* a matched wake word ended, which the collapsed [ids] alone cannot
  /// say. Empty when the caller does not need alignment.
  final List<int> endFrames;
}

/// Result of matching a decode against the manifest's wake-word targets.
class MatchResult {
  const MatchResult({
    required this.matched,
    required this.targetIndex,
    required this.editDistance,
    required this.matchedConfidence,
    required this.gateThreshold,
    this.endFrame = -1,
  });

  static const miss = MatchResult(
    matched: false,
    targetIndex: -1,
    editDistance: 1 << 30,
    matchedConfidence: double.negativeInfinity,
    gateThreshold: double.negativeInfinity,
  );

  final bool matched;
  final int targetIndex;
  final int editDistance;

  /// Raw frame index where the matched wake word ends, in the decode's own
  /// timeline. Note this is the end of the *matched region*, not of speech: in
  /// a one-shot phrase ("okay nabu turn off the lights") the trailing command
  /// keeps emitting phonemes, so the last non-blank frame is far later. -1 when
  /// unmatched or when the decode carried no alignment.
  final int endFrame;

  /// Mean raw-logit confidence over the matched window (drives the
  /// high-confidence bypass).
  final double matchedConfidence;
  final double gateThreshold;
}

/// Greedy CTC decode + phoneme matching, ported from Voice Satellite's
/// `ctc-decoder.js` (greedyDecodeWithConfidence + acceptedMatch + editDistance).
class CtcDecoder {
  CtcDecoder(this.ctc);

  final VswwCtcConfig ctc;

  /// Greedy decode of raw logits, shape [tOut, vocab] row-major.
  CtcDecode decode(Float32List logits, int tOut, int vocab) {
    final argId = List<int>.filled(tOut, 0);
    final argLogit = Float64List(tOut);
    for (var t = 0; t < tOut; t++) {
      final off = t * vocab;
      var best = 0;
      var bestVal = logits[off];
      for (var v = 1; v < vocab; v++) {
        final x = logits[off + v];
        if (x > bestVal) {
          bestVal = x;
          best = v;
        }
      }
      argId[t] = best;
      argLogit[t] = bestVal;
    }

    final ids = <int>[];
    final conf = <double>[];
    final endFrames = <int>[];
    var i = 0;
    while (i < tOut) {
      final tok = argId[i];
      var j = i;
      var sum = 0.0;
      while (j < tOut && argId[j] == tok) {
        sum += argLogit[j];
        j++;
      }
      if (tok != ctc.blankId && tok != ctc.padId) {
        ids.add(tok);
        conf.add(sum / (j - i));
        endFrames.add(j - 1);
      }
      i = j;
    }
    return CtcDecode(ids, conf, endFrames);
  }

  /// Best accepted match of [decode] against all wake-word targets, or
  /// [MatchResult.miss].
  MatchResult match(CtcDecode decode) {
    final ids = decode.ids;
    final conf = decode.confidence;
    final endFrames = decode.endFrames;
    final len = ids.length;
    MatchResult best = MatchResult.miss;

    double meanConf(int start, int winLen) {
      if (winLen <= 0) return double.negativeInfinity;
      var s = 0.0;
      for (var k = start; k < start + winLen; k++) {
        s += conf[k];
      }
      return s / winLen;
    }

    void consider(int ti, int start, int winLen, int ed) {
      final gate = ctc.minConfidenceFor(ti);
      final mc = meanConf(start, winLen);
      if (mc < gate) return; // confidence gate
      // prefer lower edit distance, then higher confidence
      if (!best.matched ||
          ed < best.editDistance ||
          (ed == best.editDistance && mc > best.matchedConfidence)) {
        final last = start + winLen - 1;
        best = MatchResult(
          matched: true,
          targetIndex: ti,
          editDistance: ed,
          matchedConfidence: mc,
          gateThreshold: gate,
          endFrame: last < endFrames.length ? endFrames[last] : -1,
        );
      }
    }

    for (var ti = 0; ti < ctc.wakeWordTargets.length; ti++) {
      final target = ctc.wakeWordTargets[ti];
      final tlen = target.length;
      if (tlen == 0 || len < tlen) continue;
      final maxEd = ctc.maxEditFor(ti);

      // 1) exact substring fast path (ed = 0)
      for (var start = 0; start + tlen <= len; start++) {
        var exact = true;
        for (var k = 0; k < tlen; k++) {
          if (ids[start + k] != target[k]) {
            exact = false;
            break;
          }
        }
        if (exact && _trailOk(start, tlen, len)) {
          consider(ti, start, tlen, 0);
        }
      }

      // 2) fuzzy path (asymmetric window winLen = tlen .. tlen+maxEd)
      if (maxEd > 0) {
        for (var winLen = tlen; winLen <= tlen + maxEd; winLen++) {
          if (winLen > len) break;
          final startMax = len - winLen;
          final startMin = ctc.trailTolerance >= 0
              ? math.max(0, len - winLen - ctc.trailTolerance)
              : 0;
          for (var start = startMin; start <= startMax; start++) {
            final ed = _editDistance(ids, start, winLen, target);
            if (ed <= maxEd) consider(ti, start, winLen, ed);
          }
        }
      }
    }
    return best;
  }

  bool _trailOk(int start, int winLen, int len) {
    if (ctc.trailTolerance < 0) return true;
    return (len - (start + winLen)) <= ctc.trailTolerance;
  }

  /// Modified Levenshtein: any edit involving the word-separator token costs 2
  /// (ported from ctc-decoder.js editDistance). [hay] window is
  /// ids[hayStart .. hayStart+hayLen).
  int _editDistance(List<int> hay, int hayStart, int hayLen, List<int> target) {
    final sep = ctc.wordSepId;
    int cost(int t) => t == sep ? 2 : 1;
    final m = target.length;
    var prev = List<int>.filled(m + 1, 0);
    var curr = List<int>.filled(m + 1, 0);
    for (var j = 0; j <= m; j++) {
      prev[j] = j == 0 ? 0 : prev[j - 1] + cost(target[j - 1]);
    }
    for (var i = 1; i <= hayLen; i++) {
      final hi = hay[hayStart + i - 1];
      curr[0] = prev[0] + cost(hi);
      for (var j = 1; j <= m; j++) {
        final tj = target[j - 1];
        int subCost;
        if (hi == tj) {
          subCost = 0;
        } else if (hi == sep || tj == sep) {
          subCost = 2;
        } else {
          subCost = 1;
        }
        final ins = curr[j - 1] + cost(tj);
        final del = prev[j] + cost(hi);
        final sub = prev[j - 1] + subCost;
        var best = ins;
        if (del < best) best = del;
        if (sub < best) best = sub;
        curr[j] = best;
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[m];
  }
}
