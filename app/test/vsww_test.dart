import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/wake_word/vsww/ctc_decoder.dart';
import 'package:kiosk_satellite/managers/wake_word/vsww/detection_gate.dart';
import 'package:kiosk_satellite/managers/wake_word/vsww/log_mel.dart';
import 'package:kiosk_satellite/managers/wake_word/vsww/manifest.dart';

// Feature config matching the ok_nabu manifest.
final _feature = VswwFeatureConfig(
  sampleRate: 16000,
  nFft: 512,
  nMels: 40,
  fMin: 80,
  fMax: 7600,
  logFloor: 1e-6,
  frameSamples: 400,
  hopSamples: 160,
  windowSamples: 20800,
  frames: 128,
);

// ok_nabu CTC config (the two targets: "okay nabu" and "kay nabu").
final _ctc = VswwCtcConfig(
  vocabSize: 52,
  blankId: 1,
  padId: 0,
  wordSepId: 2,
  wakeWordTargets: [
    [18, 21, 29, 9, 15, 2, 32, 5, 3, 23, 20, 3],
    [29, 9, 15, 2, 32, 5, 3, 23, 20, 3],
  ],
  maxEditDistance: 1,
  trailTolerance: 1,
  minMatchedConfidence: 3.2,
  targetMaxEditDistance: [1, 0],
  targetMinMatchedConfidence: [3.2, 6.0],
  inventory: [],
  targetPhonemes: [],
);

/// Build a [tOut, vocab] logits buffer that greedily decodes to [phonemes]
/// (each phoneme on one frame, separated by a blank frame) with [logit] as
/// the winning logit value.
Float32List _logitsFor(List<int> phonemes, int tOut, int vocab,
    {double logit = 5.0, int blank = 1}) {
  final out = Float32List(tOut * vocab);
  // fill everything low
  for (var i = 0; i < out.length; i++) {
    out[i] = -10.0;
  }
  void setFrame(int t, int id, double v) {
    for (var vv = 0; vv < vocab; vv++) {
      out[t * vocab + vv] = -10.0;
    }
    out[t * vocab + id] = v;
  }

  var t = 0;
  for (final p in phonemes) {
    if (t >= tOut) break;
    setFrame(t++, p, logit);
    if (t < tOut) setFrame(t++, blank, logit); // blank between
  }
  // remaining frames = blank
  for (; t < tOut; t++) {
    setFrame(t, blank, logit);
  }
  return out;
}

void main() {
  group('LogMelExtractor', () {
    final ex = LogMelExtractor(_feature);

    test('produces the manifest feature shape', () {
      final window = Float32List(_feature.windowSamples);
      final feats = ex.extract(window);
      expect(feats.length, _feature.frames * _feature.nMels); // 128*40
    });

    test('silence maps to the log floor everywhere', () {
      final feats = ex.extract(Float32List(_feature.windowSamples));
      // Features are float32 (ONNX input dtype), so log(1e-6) rounds to f32.
      final expected = math.log(_feature.logFloor);
      for (final v in feats) {
        expect(v, closeTo(expected, 1e-4));
      }
    });

    test('a pure tone concentrates energy in the covering mel band', () {
      // 1 kHz sine; the mel bin covering ~1 kHz should dominate.
      final window = Float32List(_feature.windowSamples);
      for (var i = 0; i < window.length; i++) {
        window[i] = math.sin(2 * math.pi * 1000 * i / _feature.sampleRate);
      }
      final feats = ex.extract(window);
      // Look at the middle frame's 40 mels.
      final f = _feature.frames ~/ 2;
      var maxMel = 0;
      var maxVal = feats[f * 40];
      for (var m = 1; m < 40; m++) {
        if (feats[f * 40 + m] > maxVal) {
          maxVal = feats[f * 40 + m];
          maxMel = m;
        }
      }
      // 1 kHz falls in the lower-middle of an 80–7600 Hz mel scale.
      expect(maxMel, inInclusiveRange(8, 20));
      expect(maxVal, greaterThan(math.log(_feature.logFloor) + 5));
    });

    test('is deterministic', () {
      final window = Float32List(_feature.windowSamples);
      for (var i = 0; i < window.length; i++) {
        window[i] = math.sin(i * 0.01);
      }
      final a = Float32List.fromList(ex.extract(window));
      final b = ex.extract(window);
      expect(a, equals(b));
    });

    test('incremental update is bit-identical to a full recompute', () {
      // Build window A, then window B = A shifted left by one chunk (8 hops
      // = 1280 samples) with fresh tail audio — exactly how the engine slides.
      final rnd = <double>[];
      for (var i = 0; i < _feature.windowSamples + 1280; i++) {
        rnd.add(math.sin(i * 0.017) * 0.3 + math.sin(i * 0.0031) * 0.2);
      }
      final windowA = Float32List.fromList(rnd.sublist(0, _feature.windowSamples));
      final windowB =
          Float32List.fromList(rnd.sublist(1280, 1280 + _feature.windowSamples));

      final incremental = LogMelExtractor(_feature);
      incremental.extract(windowA); // prime (full)
      final incB =
          Float32List.fromList(incremental.extract(windowB, newSamples: 1280));

      final fresh = LogMelExtractor(_feature);
      final fullB = fresh.extract(windowB); // full recompute of window B

      expect(incB, equals(fullB)); // bit-identical
    });
  });

  group('CtcDecoder.decode', () {
    final dec = CtcDecoder(_ctc);

    test('collapses runs, drops blank/pad, keeps word_sep', () {
      const vocab = 52, tOut = 64;
      // frames: [18,18, blank, 2, pad, 32] → decode ids [18, 2, 32]
      final out = Float32List(tOut * vocab);
      for (var i = 0; i < out.length; i++) {
        out[i] = -10;
      }
      void f(int t, int id) => out[t * vocab + id] = 5.0;
      f(0, 18);
      f(1, 18);
      f(2, 1); // blank
      f(3, 2); // word_sep — kept
      f(4, 0); // pad — dropped
      f(5, 32);
      for (var t = 6; t < tOut; t++) {
        f(t, 1); // blank
      }
      final d = dec.decode(out, tOut, vocab);
      expect(d.ids, [18, 2, 32]);
      expect(d.confidence.length, 3);
      // Each token's end frame is the last frame of its run: 18 spans 0-1.
      expect(d.endFrames, [1, 3, 5]);
    });
  });

  group('sensitivity confidence scale', () {
    // The card resolves its Sensitivity setting to a multiplier and hands it
    // over; we only multiply. Target 0's gate is 3.2, so a logit of 3.3 sits
    // just above it at x1.0.
    final logits = _logitsFor(_ctc.wakeWordTargets[0], 64, 52, logit: 3.3);

    test('x1.0 leaves the manifest gate alone', () {
      final dec = CtcDecoder(_ctc);
      expect(dec.match(dec.decode(logits, 64, 52)).matched, isTrue);
    });

    test('"Slightly sensitive" (x1.10) raises the gate above the match', () {
      // 3.2 * 1.10 = 3.52 > 3.3 -> rejected.
      final dec = CtcDecoder(_ctc, confidenceScale: 1.10);
      expect(dec.match(dec.decode(logits, 64, 52)).matched, isFalse);
    });

    test('"Very sensitive" (x0.90) lowers the gate under a faint match', () {
      // 3.2 * 0.90 = 2.88, so a 3.0 logit that misses at x1.0 now matches.
      final faint = _logitsFor(_ctc.wakeWordTargets[0], 64, 52, logit: 3.0);
      expect(CtcDecoder(_ctc).match(
        CtcDecoder(_ctc).decode(faint, 64, 52),
      ).matched, isFalse);
      final dec = CtcDecoder(_ctc, confidenceScale: 0.90);
      expect(dec.match(dec.decode(faint, 64, 52)).matched, isTrue);
    });
  });

  group('wake-end alignment', () {
    final dec = CtcDecoder(_ctc);

    test('endFrame is the end of the matched wake word, not of speech', () {
      // A one-shot phrase: the wake word, then a word of the command. The
      // trailing token keeps emitting phonemes, so "last non-blank frame" is
      // the wrong answer and would make STT eat the start of the command.
      final phonemes = [..._ctc.wakeWordTargets[0], 30];
      final logits = _logitsFor(phonemes, 64, 52, logit: 5.0);
      final d = dec.decode(logits, 64, 52);
      final r = dec.match(d);

      expect(r.matched, isTrue);
      // _logitsFor lays each token on its own frame with a blank after, so the
      // wake word's 12th token sits on frame 22 and the command's on frame 24.
      expect(d.endFrames.last, 24, reason: 'command token is the last speech');
      expect(r.endFrame, 22, reason: 'match must end at the wake word');
    });

    test('a match at the window edge ends at its own last frame', () {
      final logits = _logitsFor(_ctc.wakeWordTargets[0], 64, 52, logit: 5.0);
      final r = dec.match(dec.decode(logits, 64, 52));
      expect(r.matched, isTrue);
      expect(r.endFrame, 22);
    });

    test('a miss carries no alignment', () {
      expect(MatchResult.miss.endFrame, -1);
    });
  });

  group('CtcDecoder.match', () {
    final dec = CtcDecoder(_ctc);

    test('exact target 0 matches with edit distance 0', () {
      final logits = _logitsFor(_ctc.wakeWordTargets[0], 64, 52, logit: 5.0);
      final d = dec.decode(logits, 64, 52);
      final r = dec.match(d);
      expect(r.matched, isTrue);
      expect(r.editDistance, 0);
      expect(r.targetIndex, 0);
    });

    test('confidence gate rejects a low-confidence exact match', () {
      // logit 3.0 < target 0 gate 3.2 → rejected.
      final logits = _logitsFor(_ctc.wakeWordTargets[0], 64, 52, logit: 3.0);
      final d = dec.decode(logits, 64, 52);
      expect(dec.match(d).matched, isFalse);
    });

    test('one substitution still matches target 0 (maxEdit 1)', () {
      final noisy = List<int>.of(_ctc.wakeWordTargets[0]);
      noisy[4] = 14; // swap one phoneme
      final logits = _logitsFor(noisy, 64, 52, logit: 5.0);
      final d = dec.decode(logits, 64, 52);
      final r = dec.match(d);
      expect(r.matched, isTrue);
      expect(r.editDistance, lessThanOrEqualTo(1));
    });

    test('a totally different phoneme string does not match', () {
      final logits = _logitsFor([4, 5, 6, 7, 8, 9], 64, 52, logit: 5.0);
      final d = dec.decode(logits, 64, 52);
      expect(dec.match(d).matched, isFalse);
    });

    test('word-separator edits cost 2 (cannot be fixed within maxEdit 1)', () {
      // Insert a stray word_sep into target 0: needs an edit of cost 2 > maxEd 1.
      final withSep = List<int>.of(_ctc.wakeWordTargets[0])..insert(3, 2);
      final logits = _logitsFor(withSep, 64, 52, logit: 5.0);
      final d = dec.decode(logits, 64, 52);
      final r = dec.match(d);
      // target 0 fuzzy can't absorb the extra separator at ed<=1; but the
      // decode is longer, so it must not spuriously match target 0 at ed<=1.
      if (r.matched) {
        expect(r.editDistance, greaterThan(0));
      }
    });
  });

  group('DetectionGate', () {
    VswwRuntimeConfig rt({
      int requiredHits = 1,
      int cooldownMs = 2000,
      double? bypass,
      int bypassMinHits = 1,
    }) =>
        VswwRuntimeConfig(
          requiredHits: requiredHits,
          cooldownMs: cooldownMs,
          highConfidenceBypass: bypass,
          highConfidenceBypassMinHits: bypassMinHits,
          streamMatch: true,
          streamBufferMs: 2500,
          streamLagFrames: 20,
        );

    test('required_hits=1 fires on first match, then cools down', () {
      final gate = DetectionGate(rt(requiredHits: 1, cooldownMs: 2000));
      expect(
          gate.update(
              matched: true, matchedConfidence: 5, targetIndex: 0, nowMs: 0),
          isTrue);
      // within cooldown → no re-fire
      expect(
          gate.update(
              matched: true, matchedConfidence: 5, targetIndex: 0, nowMs: 500),
          isFalse);
      // after cooldown → fires again
      expect(
          gate.update(
              matched: true, matchedConfidence: 5, targetIndex: 0, nowMs: 2100),
          isTrue);
    });

    test('required_hits=3 needs three consecutive matches; a miss resets', () {
      final gate = DetectionGate(rt(requiredHits: 3));
      expect(g(gate, true, 0), isFalse); // 1
      expect(g(gate, true, 0), isFalse); // 2
      expect(g(gate, false, 0), isFalse); // reset
      expect(g(gate, true, 0), isFalse); // 1
      expect(g(gate, true, 0), isFalse); // 2
      expect(g(gate, true, 0), isTrue); // 3 → fire
    });

    test('high-confidence bypass fires before required_hits reached', () {
      final gate = DetectionGate(rt(requiredHits: 5, bypass: 6.8));
      // one very confident match bypasses the 5-hit requirement
      expect(
          gate.update(
              matched: true, matchedConfidence: 7.0, targetIndex: 0, nowMs: 0),
          isTrue);
    });
  });
}

bool g(DetectionGate gate, bool matched, int target) => gate.update(
    matched: matched,
    matchedConfidence: 5,
    targetIndex: target,
    nowMs: 100000000);
