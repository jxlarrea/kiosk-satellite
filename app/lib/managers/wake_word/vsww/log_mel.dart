import 'dart:math' as math;
import 'dart:typed_data';

import 'manifest.dart';

/// Log-mel feature extractor for `vs-wake-word-ctc-v1`, ported bit-close from
/// Voice Satellite's `inference.js:_extractLogMel`.
///
/// Contract (from the manifest / port spec):
///  - input: Float32 mono 16 kHz, [-1, 1], no pre-emphasis or normalization.
///  - framing: `frameSamples` (400) windowed by a **symmetric Hann** (divisor
///    n-1 = 399), zero-padded to `nFft` (512); hop `hopSamples` (160);
///    `frames` (128) frames over a `windowSamples` (20800) window.
///  - FFT: unnormalized real 512-pt, power spectrum re^2+im^2 over 257 bins.
///  - mel: 40 triangular filters, HTK mel points, Slaney (area) normalization,
///    bin edges floor((nFft+1)*hz/sr).
///  - output: natural log(max(energy, logFloor)), row-major frame-major
///    [frames*mels], fed as ONNX input [1, frames, mels].
///
/// All heavy accumulation is in `double` (Dart doubles are 64-bit), matching
/// the JS Float64 power/mel math. Window and filter coefficients are quantized
/// to float32 first (as JS stores them) before double accumulation.
class LogMelExtractor {
  LogMelExtractor(this.feature)
      : _fft = _Fft(feature.nFft),
        _window = _makeHannWindow(feature.frameSamples),
        _filters = _makeMelFilterbank(feature) {
    _halfBins = feature.nFft ~/ 2 + 1; // 257 for nFft 512
  }

  final VswwFeatureConfig feature;
  final _Fft _fft;
  final Float32List _window; // length frameSamples, symmetric Hann
  final List<_MelFilter> _filters; // length nMels
  late final int _halfBins;

  // Reused scratch + the persistent feature buffer for incremental extraction.
  late final Float32List _featBuf =
      Float32List(feature.frames * feature.nMels);
  late final Float64List _re = Float64List(feature.nFft);
  late final Float64List _im = Float64List(feature.nFft);
  late final Float64List _power = Float64List(_halfBins);
  bool _primed = false;

  /// Extract [frames * nMels] log-mel features from a full window of
  /// [windowSamples] float samples (time order). Returns the internal feature
  /// buffer (valid until the next call).
  ///
  /// [newSamples] enables the incremental fast path: the window slides by a
  /// whole number of hops between calls, so only the trailing
  /// `newSamples / hopSamples` frames are new — the rest are shifted down. Old
  /// frame j (float32) becomes new frame j - newFrames, which is *bit-identical*
  /// to recomputing it (same audio, same math). Pass -1 (default) or a
  /// non-hop-aligned value to force a full recompute (e.g. the first window).
  Float32List extract(Float32List window, {int newSamples = -1}) {
    final frames = feature.frames;
    final mels = feature.nMels;
    final hop = feature.hopSamples;

    int newFrames;
    if (!_primed || newSamples < 0 || newSamples % hop != 0) {
      newFrames = frames; // full recompute
    } else {
      newFrames = newSamples ~/ hop;
      if (newFrames > frames) newFrames = frames;
    }

    if (newFrames >= frames) {
      for (var f = 0; f < frames; f++) {
        _computeFrame(window, f);
      }
    } else {
      // shift the retained frames down by newFrames, then recompute the tail
      final shift = newFrames * mels;
      _featBuf.setRange(0, frames * mels - shift, _featBuf, shift);
      for (var f = frames - newFrames; f < frames; f++) {
        _computeFrame(window, f);
      }
    }
    _primed = true;
    return _featBuf;
  }

  void _computeFrame(Float32List window, int f) {
    final frameLen = feature.frameSamples;
    final nFft = feature.nFft;
    final mels = feature.nMels;
    final base = f * feature.hopSamples;
    for (var i = 0; i < frameLen; i++) {
      _re[i] = window[base + i] * _window[i];
    }
    for (var i = frameLen; i < nFft; i++) {
      _re[i] = 0.0;
    }
    for (var i = 0; i < nFft; i++) {
      _im[i] = 0.0;
    }
    _fft.forward(_re, _im);
    for (var k = 0; k < _halfBins; k++) {
      _power[k] = _re[k] * _re[k] + _im[k] * _im[k];
    }
    for (var m = 0; m < mels; m++) {
      final filt = _filters[m];
      var energy = 0.0;
      for (var k = filt.lo; k < filt.hi; k++) {
        energy += filt.coeff[k - filt.lo] * _power[k];
      }
      final v = energy > feature.logFloor ? energy : feature.logFloor;
      _featBuf[f * mels + m] = math.log(v);
    }
  }

  // ── Window ──────────────────────────────────────────────────────────
  static Float32List _makeHannWindow(int n) {
    final w = Float32List(n);
    for (var i = 0; i < n; i++) {
      w[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1));
    }
    return w;
  }

  // ── Mel filterbank ──────────────────────────────────────────────────
  static double _hzToMel(double hz) => 2595.0 * _log10(1 + hz / 700.0);
  static double _melToHz(double mel) => 700.0 * (math.pow(10, mel / 2595.0) - 1);
  static double _log10(double x) => math.log(x) / math.ln10;

  static List<_MelFilter> _makeMelFilterbank(VswwFeatureConfig f) {
    final nMels = f.nMels;
    final nFft = f.nFft;
    final sr = f.sampleRate;
    final half = nFft ~/ 2; // 256
    final melMin = _hzToMel(f.fMin);
    final melMax = _hzToMel(f.fMax);
    final points = nMels + 2;
    final hz = List<double>.filled(points, 0);
    final bins = List<int>.filled(points, 0);
    for (var i = 0; i < points; i++) {
      final mel = melMin + (i / (nMels + 1)) * (melMax - melMin);
      hz[i] = _melToHz(mel);
      var b = ((nFft + 1) * hz[i] / sr).floor();
      if (b < 0) b = 0;
      if (b > half) b = half;
      bins[i] = b;
    }

    final filters = <_MelFilter>[];
    for (var m = 1; m <= nMels; m++) {
      final left = bins[m - 1];
      var center = bins[m];
      var right = bins[m + 1];
      if (center <= left) center = left + 1;
      if (right <= center) right = center + 1;
      // Full-length coefficients (float32, as JS stores), then trimmed to
      // the nonzero band [lo, hi).
      final full = Float32List(half + 1);
      for (var k = left; k < center; k++) {
        full[k] = (k - left) / math.max(1, center - left);
      }
      for (var k = center; k < right; k++) {
        full[k] = (right - k) / math.max(1, right - center);
      }
      final enorm = 2.0 / math.max(1e-6, hz[m + 1] - hz[m - 1]);
      for (var k = 0; k <= half; k++) {
        full[k] = full[k] * enorm;
      }
      // trim to nonzero band
      final lo = left;
      final hi = math.min(right, half + 1);
      final coeff = Float32List(hi - lo);
      for (var k = lo; k < hi; k++) {
        coeff[k - lo] = full[k];
      }
      filters.add(_MelFilter(lo, hi, coeff));
    }
    return filters;
  }
}

class _MelFilter {
  _MelFilter(this.lo, this.hi, this.coeff);
  final int lo;
  final int hi; // exclusive
  final Float32List coeff; // length hi-lo
}

/// Minimal unnormalized radix-2 real FFT, sign exp(-2πi k/N), matching the
/// JS `FFT` class (no 1/N scaling). Size must be a power of two.
class _Fft {
  _Fft(this.n)
      : _cos = Float64List(n),
        _sin = Float64List(n),
        _rev = Uint32List(n) {
    for (var i = 0; i < n; i++) {
      _cos[i] = math.cos(-2 * math.pi * i / n);
      _sin[i] = math.sin(-2 * math.pi * i / n);
    }
    var bits = 0;
    while ((1 << bits) < n) {
      bits++;
    }
    for (var i = 0; i < n; i++) {
      var x = i;
      var r = 0;
      for (var b = 0; b < bits; b++) {
        r = (r << 1) | (x & 1);
        x >>= 1;
      }
      _rev[i] = r;
    }
  }

  final int n;
  final Float64List _cos;
  final Float64List _sin;
  final Uint32List _rev;

  /// In-place forward DFT of complex arrays re/im (length n).
  void forward(Float64List re, Float64List im) {
    // bit-reversal permutation
    for (var i = 0; i < n; i++) {
      final j = _rev[i];
      if (j > i) {
        var t = re[i];
        re[i] = re[j];
        re[j] = t;
        t = im[i];
        im[i] = im[j];
        im[j] = t;
      }
    }
    for (var size = 2; size <= n; size <<= 1) {
      final half = size >> 1;
      final step = n ~/ size;
      for (var i = 0; i < n; i += size) {
        var k = 0;
        for (var j = i; j < i + half; j++) {
          final tw = k;
          final cr = _cos[tw];
          final ci = _sin[tw];
          final l = j + half;
          final xr = re[l] * cr - im[l] * ci;
          final xi = re[l] * ci + im[l] * cr;
          re[l] = re[j] - xr;
          im[l] = im[j] - xi;
          re[j] += xr;
          im[j] += xi;
          k += step;
        }
      }
    }
  }
}
