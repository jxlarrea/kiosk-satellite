/// microWakeWord's audio frontend: 16 kHz PCM in, 40 log-mel-ish features per
/// 10 ms out.
///
/// A port of Voice Satellite's `micro-frontend-js`, which is itself a port of
/// TFLite Micro's `micro_features` frontend (window -> int16 KissFFT ->
/// filterbank -> noise reduction -> PCAN auto-gain -> log scale). It is
/// fixed-point end to end and must be *bit-exact*: the models are trained on
/// these exact integers, so a one-off rounding difference does not degrade
/// gracefully, it just makes detection quietly worse.
///
/// Ported against golden vectors dumped from the JS reference rather than by
/// eye. The traps, all of which the goldens cover:
///
///  - JS bitwise operators coerce to **32-bit** and wrap; Dart ints are
///    64-bit and do not. Every such site masks explicitly ([_i32], [_u32]).
///    `sround` depends on this wrap: the butterfly products exceed int32.
///  - `Math.floor(a / b)` floors toward -infinity. Dart's `~/` truncates
///    toward zero. They differ for negative numerators, and the PCAN gain
///    LUT's `a2` coefficient is negative. See [_floorDiv].
///  - `Math.fround` has no Dart equivalent; [_fround] round-trips through a
///    Float32List, which is exact. The tables are built in float32 in C, and
///    a single ULP moves a filterbank channel boundary.
///  - Typed-list stores truncate the same way in both languages, so
///    Int16List assignment reproduces C's int16 wrap for free.
library;

import 'dart:math' as math;
import 'dart:typed_data';

const int kSampleRate = 16000;
const int kWindowSizeMs = 30;
const int kStepSizeMs = 10;
const int kFeatureSize = 40;
const double kFilterbankLowHz = 125.0;
const double kFilterbankHighHz = 7500.0;
const int kNoiseReductionBits = 14;
const int kNoiseReductionSmoothingBits = 10;

/// C casts float to int directly (truncation), not round-to-nearest:
/// 0.025 * 16384 = 409.6 stores as 409.
final int kNoiseReductionEvenSmoothing = (0.025 * (1 << kNoiseReductionBits)).truncate();
final int kNoiseReductionOddSmoothing = (0.06 * (1 << kNoiseReductionBits)).truncate();
final int kNoiseReductionMinSignal = (0.05 * (1 << kNoiseReductionBits)).truncate();

const int kPcanSnrBits = 12;
const int kPcanOutputBits = 6;
const int kPcanGainBits = 21;
const double kPcanStrength = 0.95;
const double kPcanOffset = 80.0;
const int kWideDynamicBits = 32;
const int kLogSegmentsLog2 = 7;
const int kLogScaleLog2 = 16;
const int kLogScale = 65536;
const int kLogCoeff = 45426;
const double kFloat32Scale = 0.0390625;
const int kFrontendWindowBits = 12;

const int kWindowSize = (kWindowSizeMs * kSampleRate) ~/ 1000; // 480
const int kStepSize = (kStepSizeMs * kSampleRate) ~/ 1000; // 160
final int kFftSize = 1 << (math.log(kWindowSize) / math.ln2).ceil(); // 512
final int kSpectrumSize = kFftSize ~/ 2 + 1; // 257
final int kInputCorrectionBits =
    _mostSignificantBit32(kFftSize) - 1 - (kFrontendWindowBits ~/ 2);
final int kSnrShift = kPcanGainBits - kInputCorrectionBits - kPcanSnrBits;

// ── 32-bit / rounding primitives ───────────────────────────────────────

final Float32List _f32 = Float32List(1);

/// JS `Math.fround`: round a double to the nearest float32 and back.
double _fround(double x) {
  _f32[0] = x;
  return _f32[0];
}

/// JS `x | 0`: coerce to signed 32-bit (wrapping).
int _i32(int x) => x.toSigned(32);

/// JS `x >>> 0`: coerce to unsigned 32-bit.
int _u32(int x) => x & 0xFFFFFFFF;

/// JS `Math.floor(a / b)`, which floors toward -infinity.
///
/// Not `a ~/ b`: that truncates toward zero, so the two disagree whenever the
/// numerator is negative. Division is done in double, matching JS, where every
/// one of these values is a double; the reference keeps them under 2^53.
int _floorDiv(num a, num b) => (a / b).floor();

/// JS `Math.clz32`.
int _clz32(int value) {
  var x = _u32(value);
  if (x == 0) return 32;
  var n = 0;
  if (x <= 0x0000FFFF) {
    n += 16;
    x <<= 16;
  }
  if (x <= 0x00FFFFFF) {
    n += 8;
    x <<= 8;
  }
  if (x <= 0x0FFFFFFF) {
    n += 4;
    x <<= 4;
  }
  if (x <= 0x3FFFFFFF) {
    n += 2;
    x <<= 2;
  }
  if (x <= 0x7FFFFFFF) n += 1;
  return n;
}

int _mostSignificantBit32(int value) {
  if (value == 0) return 0;
  return 32 - _clz32(_u32(value));
}

/// C `log1pf`'s job, in double. Dart has no log1p, and `log(1 + x)` loses
/// accuracy as x approaches 0; the correction term recovers it. Every caller
/// rounds to float32 afterwards, which is what the goldens pin.
double _log1p(double x) {
  final u = 1.0 + x;
  if (u == 1.0) return x;
  return math.log(u) * (x / (u - 1.0));
}

/// C: `1127.0f * log1pf(freq / 700.0f)`, all float32.
double _freqToMel(double freq) =>
    _fround(1127.0 * _fround(_log1p(_fround(freq / 700.0))));

/// Banker's rounding (half to even), matching numpy's np.round and the JS
/// reference. Used to quantize features into a model's int8 input tensor.
///
/// Cannot be Dart's `.round()`: that rounds halves *away from zero*, while JS
/// `Math.round` rounds them toward +infinity, and the two disagree on every
/// negative half. Zero-point is -128, so negative values are the common case,
/// not an edge case. `(x + 0.5).floor()` reproduces Math.round; the parity
/// check then pulls halves to even.
int roundBankers(double x) {
  final r = (x + 0.5).floor();
  final frac = x - x.floorToDouble();
  if (frac == 0.5 && (r & 1) == 1) return r - 1;
  return r;
}

int _floatToInt16(double value) {
  var scaled = value * 32768.0;
  if (scaled > 32767) scaled = 32767;
  if (scaled < -32768) scaled = -32768;
  return _i32(scaled.truncate());
}

/// `sround(x) = (x + (1 << 14)) >> 15`, from KissFFT's _kiss_fft_guts.h.
///
/// The int32 coercion is load-bearing rather than defensive: butterfly
/// products reach ~2^31 and C wraps them in SAMPPROD.
int _sround(int x) => _i32(x + 16384) >> 15;

/// `C_FIXDIV(x, 2)`. Not x/2: rounds differently (+1 on odd values).
int _cFixdiv2(int x) => _sround(x * 16383);

/// `C_FIXDIV(x, 4)`, used by the radix-4 butterflies.
int _cFixdiv4(int x) => _sround(x * 8191);

// ── Derived tables (built once) ────────────────────────────────────────

class FftPlan {
  FftPlan(this.nfftReal, this.ncfft, this.twCos, this.twSin, this.stCos,
      this.stSin, this.factors, this.tmpR, this.tmpI, this.srcR, this.srcI);

  final int nfftReal;
  final int ncfft;
  final Int16List twCos;
  final Int16List twSin;
  final Int16List stCos;
  final Int16List stSin;
  final List<int> factors;
  final Int16List tmpR;
  final Int16List tmpI;
  final Int16List srcR;
  final Int16List srcI;
}

class FilterbankState {
  FilterbankState(this.startIndex, this.endIndex, this.channelFrequencyStarts,
      this.channelWeightStarts, this.channelWidths, this.weights, this.unweights);

  final int startIndex;
  final int endIndex;
  final Int16List channelFrequencyStarts;
  final Int16List channelWeightStarts;
  final Int16List channelWidths;
  final Int16List weights;
  final Int16List unweights;
}

class MicroFrontendTables {
  MicroFrontendTables(this.windowCoefficients, this.filterbank, this.fftPlan,
      this.gainLut);

  final Int16List windowCoefficients;
  final FilterbankState filterbank;
  final FftPlan fftPlan;
  final Int16List gainLut;
}

MicroFrontendTables? _shared;

MicroFrontendTables sharedTables() => _shared ??= MicroFrontendTables(
      _buildWindowCoefficients(),
      _buildFilterbankState(),
      _buildFftPlan(kFftSize),
      _buildGainLut(),
    );

Int16List _buildWindowCoefficients() {
  final coefficients = Int16List(kWindowSize);
  final arg = _fround((math.pi * 2.0) / kWindowSize);
  for (var i = 0; i < kWindowSize; i++) {
    final phase = _fround(arg * _fround(i + 0.5));
    final c = _fround(math.cos(phase));
    final v = _fround(0.5 - _fround(0.5 * c));
    coefficients[i] = (_fround(v * (1 << kFrontendWindowBits)) + 0.5).floor();
  }
  return coefficients;
}

FilterbankState _buildFilterbankState() {
  const numChannelsPlusOne = kFeatureSize + 1;
  const indexAlignment = 4 ~/ 2; // 4 bytes / sizeof(int16)
  final centerMelFreqs = Float32List(numChannelsPlusOne);
  final actualChannelStarts = Int16List(numChannelsPlusOne);
  final actualChannelWidths = Int16List(numChannelsPlusOne);
  final channelFrequencyStarts = Int16List(numChannelsPlusOne);
  final channelWeightStarts = Int16List(numChannelsPlusOne);
  final channelWidths = Int16List(numChannelsPlusOne);

  final melLow = _freqToMel(kFilterbankLowHz);
  final melHigh = _freqToMel(kFilterbankHighHz);
  // mel_span must round to float32 *before* the divide, or high channels drift
  // by a few ULP and their bin boundaries move. Divisor is num_channels_plus_1
  // (41), not 40: a naming quirk in C's CalculateCenterFrequencies.
  final melSpan = _fround(melHigh - melLow);
  final melSpacing = _fround(melSpan / numChannelsPlusOne);

  for (var i = 0; i < numChannelsPlusOne; i++) {
    centerMelFreqs[i] = _fround(melLow + _fround(melSpacing * (i + 1)));
  }

  final hzPerSbin = _fround((0.5 * kSampleRate) / (kSpectrumSize - 1));
  final startIndex = _fround(1.5 + kFilterbankLowHz / hzPerSbin).truncate();
  var channelFreqIndexStart = startIndex;
  var weightIndexStart = 0;
  var needsZeros = false;

  for (var chan = 0; chan < numChannelsPlusOne; chan++) {
    var freqIndex = channelFreqIndexStart;
    while (_freqToMel(_fround(freqIndex * hzPerSbin)) <= centerMelFreqs[chan]) {
      freqIndex++;
    }

    final width = freqIndex - channelFreqIndexStart;
    actualChannelStarts[chan] = channelFreqIndexStart;
    actualChannelWidths[chan] = width;

    if (width == 0) {
      channelFrequencyStarts[chan] = 0;
      channelWeightStarts[chan] = 0;
      channelWidths[chan] = 4;
      if (!needsZeros) {
        needsZeros = true;
        for (var j = 0; j < chan; j++) {
          channelWeightStarts[j] += 4;
        }
        weightIndexStart += 4;
      }
    } else {
      final alignedStart = (channelFreqIndexStart / indexAlignment).floor() * indexAlignment;
      final alignedWidth = channelFreqIndexStart - alignedStart + width;
      final paddedWidth = (((alignedWidth - 1) / 4).floor() + 1) * 4;
      channelFrequencyStarts[chan] = alignedStart;
      channelWeightStarts[chan] = weightIndexStart;
      channelWidths[chan] = paddedWidth;
      weightIndexStart += paddedWidth;
    }

    channelFreqIndexStart = freqIndex;
  }

  final weights = Int16List(weightIndexStart);
  final unweights = Int16List(weightIndexStart);
  var endIndex = 0;

  for (var chan = 0; chan < numChannelsPlusOne; chan++) {
    var frequency = actualChannelStarts[chan];
    final numFrequencies = actualChannelWidths[chan];
    final frequencyOffset = frequency - channelFrequencyStarts[chan];
    final weightStart = channelWeightStarts[chan];
    final denom = chan == 0 ? melLow : centerMelFreqs[chan - 1];

    for (var j = 0; j < numFrequencies; j++, frequency++) {
      final melFreq = _freqToMel(_fround(frequency * hzPerSbin));
      final num = _fround(centerMelFreqs[chan] - melFreq);
      final den = _fround(centerMelFreqs[chan] - denom);
      final weight = _fround(num / den);
      final weightIndex = weightStart + frequencyOffset + j;
      weights[weightIndex] =
          (_fround(weight * (1 << kFrontendWindowBits)) + 0.5).floor();
      unweights[weightIndex] =
          (_fround(_fround(1.0 - weight) * (1 << kFrontendWindowBits)) + 0.5)
              .floor();
    }

    if (frequency > endIndex) endIndex = frequency;
  }

  return FilterbankState(startIndex, endIndex, channelFrequencyStarts,
      channelWeightStarts, channelWidths, weights, unweights);
}

FftPlan _buildFftPlan(int nfftReal) {
  final ncfft = nfftReal >> 1; // 256 for N=512

  final twCos = Int16List(ncfft);
  final twSin = Int16List(ncfft);
  for (var i = 0; i < ncfft; i++) {
    final phase = (-2.0 * math.pi * i) / ncfft;
    twCos[i] = (0.5 + 32767 * math.cos(phase)).floor();
    twSin[i] = (0.5 + 32767 * math.sin(phase)).floor();
  }

  final superCount = ncfft >> 1;
  final stCos = Int16List(superCount);
  final stSin = Int16List(superCount);
  for (var i = 0; i < superCount; i++) {
    final phase = -math.pi * ((i + 1) / ncfft + 0.5);
    stCos[i] = (0.5 + 32767 * math.cos(phase)).floor();
    stSin[i] = (0.5 + 32767 * math.sin(phase)).floor();
  }

  // Radix-4 + radix-2, matching C kf_factor's order. ncfft=256 -> [4,64,4,16,4,4,4,1].
  final factors = <int>[];
  var n = ncfft;
  var p = 4;
  final floorSqrt = math.sqrt(n).floor();
  while (n > 1) {
    while (n % p != 0) {
      if (p == 4) {
        p = 2;
      } else if (p == 2) {
        p = 3;
      } else {
        p += 2;
      }
      if (p > floorSqrt) p = n;
    }
    n = n ~/ p;
    factors.addAll([p, n]);
  }

  return FftPlan(nfftReal, ncfft, twCos, twSin, stCos, stSin, factors,
      Int16List(ncfft), Int16List(ncfft), Int16List(ncfft), Int16List(ncfft));
}

Int16List _buildGainLut() {
  // C uses a pointer trick: lut[0], lut[1] hold y for x=0 and x=1 (the
  // "x <= 2" branch), then shifts the pointer back by 6 before the interval
  // writes, so interval 2's y0 lands at lut[2] and is shared with that
  // branch's lut[2] read. Indices 5, 9, 13 ... stay unused. Replicated by
  // writing at 4*interval - 6.
  final lut = Int16List((4 * kWideDynamicBits) + 4);
  final inputBits = kNoiseReductionSmoothingBits - kInputCorrectionBits;

  lut[0] = _pcanGainLookup(inputBits, 0);
  lut[1] = _pcanGainLookup(inputBits, 1);

  for (var interval = 2; interval <= kWideDynamicBits; interval++) {
    final x0 = 1 << (interval - 1);
    final x1 = x0 + (x0 >> 1);
    final x2 = interval == kWideDynamicBits ? x0 + (x0 - 1) : 2 * x0;

    final y0 = _pcanGainLookup(inputBits, x0);
    final y1 = _pcanGainLookup(inputBits, x1);
    final y2 = _pcanGainLookup(inputBits, x2);

    final diff1 = y1 - y0;
    final diff2 = y2 - y0;
    final a1 = (4 * diff1) - diff2;
    final a2 = diff2 - a1;
    final offset = (4 * interval) - 6;
    lut[offset + 0] = y0;
    lut[offset + 1] = a1;
    lut[offset + 2] = a2;
  }

  return lut;
}

int _pcanGainLookup(int inputBits, int x) {
  final xAsFloat = _fround(x / (1 << inputBits));
  final sum = _fround(xAsFloat + kPcanOffset);
  final powVal = _fround(math.pow(sum, -kPcanStrength).toDouble());
  final gain = _fround((1 << kPcanGainBits) * powVal);
  if (gain > 0x7fff) return 0x7fff;
  return (gain + 0.5).floor();
}

int _wideDynamicFunction(int x, Int16List lut) {
  if (x <= 2) return lut[x];

  final interval = _mostSignificantBit32(_u32(x));
  final offset = (4 * interval) - 6;
  final frac = _u32(
      ((interval < 11) ? _i32(x << (11 - interval)) : (_u32(x) >> (interval - 11))) &
          0x3ff);

  var result = _floorDiv(lut[offset + 2] * frac, 32);
  result += _i32(lut[offset + 1] << 5);
  result *= frac;
  result = _floorDiv(result + (1 << 14), 1 << 15);
  result += lut[offset + 0];
  return result;
}

int _pcanShrink(int x) {
  if (x < (2 << kPcanSnrBits)) {
    return _floorDiv(x * x, 1 << (2 + (2 * kPcanSnrBits) - kPcanOutputBits));
  }
  return _floorDiv(x, 1 << (kPcanSnrBits - kPcanOutputBits)) - (1 << kPcanOutputBits);
}

int _log2FractionPart(int x, int log2x) {
  var frac = _i32(x - (1 << log2x));
  if (log2x < kLogScaleLog2) {
    frac = _i32(frac << (kLogScaleLog2 - log2x));
  } else {
    frac = _u32(frac) >> (log2x - kLogScaleLog2);
  }

  final baseSeg = _u32(frac) >> (kLogScaleLog2 - kLogSegmentsLog2);
  final segUnit = (1 << kLogScaleLog2) >> kLogSegmentsLog2;
  final c0 = kLogLut[baseSeg];
  final c1 = kLogLut[baseSeg + 1];
  final segBase = segUnit * baseSeg;
  final relPos = _floorDiv((c1 - c0) * (frac - segBase), 1 << kLogScaleLog2);
  return frac + c0 + relPos;
}

int _logScale(int x) {
  final integer = _mostSignificantBit32(_u32(x)) - 1;
  final fraction = _log2FractionPart(_u32(x), integer);
  final log2 = _i32(integer << kLogScaleLog2) + fraction;
  const round = kLogScale ~/ 2;
  final loge = _floorDiv((kLogCoeff * log2) + round, 1 << kLogScaleLog2);
  return _floorDiv(_i32(loge << 6) + round, 1 << kLogScaleLog2);
}

// ── KissFFT (int16 fixed point) ────────────────────────────────────────

void _kissFftComplex(
    Int16List srcR, Int16List srcI, Int16List dstR, Int16List dstI, FftPlan plan) {
  _kfWork(dstR, dstI, 0, srcR, srcI, 0, 1, 1, plan.factors, 0, plan.twCos,
      plan.twSin);
}

void _kfWork(Int16List dR, Int16List dI, int dof, Int16List sR, Int16List sI,
    int sof, int fstride, int inStride, List<int> factors, int fi,
    Int16List twCos, Int16List twSin) {
  final p = factors[fi];
  final m = factors[fi + 1];
  final foutBeg = dof;
  if (m == 1) {
    for (var i = 0; i < p; i++) {
      dR[dof + i] = sR[sof + i * fstride * inStride];
      dI[dof + i] = sI[sof + i * fstride * inStride];
    }
  } else {
    var s = sof;
    var d = dof;
    for (var k = 0; k < p; k++) {
      _kfWork(dR, dI, d, sR, sI, s, fstride * p, inStride, factors, fi + 2,
          twCos, twSin);
      s += fstride * inStride;
      d += m;
    }
  }
  if (p == 2) {
    _kfBfly2(dR, dI, foutBeg, fstride, m, twCos, twSin);
  } else if (p == 4) {
    _kfBfly4(dR, dI, foutBeg, fstride, m, twCos, twSin);
  }
  // Radix-3/5 unused for N=512.
}

void _kfBfly2(Int16List R, Int16List I, int fout, int fstride, int m,
    Int16List twCos, Int16List twSin) {
  for (var k = 0; k < m; k++) {
    final a = fout + k;
    final b = a + m;
    R[a] = _cFixdiv2(R[a]);
    I[a] = _cFixdiv2(I[a]);
    R[b] = _cFixdiv2(R[b]);
    I[b] = _cFixdiv2(I[b]);
    final tIdx = fstride * k;
    final wr = twCos[tIdx];
    final wi = twSin[tIdx];
    final br = R[b], bi = I[b];
    final tr = _sround(br * wr - bi * wi);
    final ti = _sround(br * wi + bi * wr);
    final ar = R[a], ai = I[a];
    R[b] = ar - tr;
    I[b] = ai - ti;
    R[a] = ar + tr;
    I[a] = ai + ti;
  }
}

void _kfBfly4(Int16List R, Int16List I, int fout, int fstride, int m,
    Int16List twCos, Int16List twSin) {
  final m2 = 2 * m;
  final m3 = 3 * m;
  for (var k = 0; k < m; k++) {
    final p0 = fout + k;
    final p1 = p0 + m;
    final p2 = p0 + m2;
    final p3 = p0 + m3;
    R[p0] = _cFixdiv4(R[p0]);
    I[p0] = _cFixdiv4(I[p0]);
    R[p1] = _cFixdiv4(R[p1]);
    I[p1] = _cFixdiv4(I[p1]);
    R[p2] = _cFixdiv4(R[p2]);
    I[p2] = _cFixdiv4(I[p2]);
    R[p3] = _cFixdiv4(R[p3]);
    I[p3] = _cFixdiv4(I[p3]);
    final t1 = fstride * k;
    final t2 = fstride * 2 * k;
    final t3 = fstride * 3 * k;
    final w1r = twCos[t1], w1i = twSin[t1];
    final w2r = twCos[t2], w2i = twSin[t2];
    final w3r = twCos[t3], w3i = twSin[t3];
    final r1 = R[p1], i1 = I[p1];
    final s0r = _sround(r1 * w1r - i1 * w1i);
    final s0i = _sround(r1 * w1i + i1 * w1r);
    final r2 = R[p2], i2 = I[p2];
    final s1r = _sround(r2 * w2r - i2 * w2i);
    final s1i = _sround(r2 * w2i + i2 * w2r);
    final r3 = R[p3], i3 = I[p3];
    final s2r = _sround(r3 * w3r - i3 * w3i);
    final s2i = _sround(r3 * w3i + i3 * w3r);
    final p0r = R[p0], p0i = I[p0];
    final s5r = p0r - s1r, s5i = p0i - s1i;
    R[p0] = p0r + s1r;
    I[p0] = p0i + s1i;
    final s3r = s0r + s2r, s3i = s0i + s2i;
    final s4r = s0r - s2r, s4i = s0i - s2i;
    R[p2] = R[p0] - s3r;
    I[p2] = I[p0] - s3i;
    R[p0] = R[p0] + s3r;
    I[p0] = I[p0] + s3i;
    R[p1] = s5r + s4i;
    I[p1] = s5i - s4r;
    R[p3] = s5r - s4i;
    I[p3] = s5i + s4r;
  }
}

void _kissFftr(Int16List timedata, Int16List outR, Int16List outI, FftPlan plan) {
  final ncfft = plan.ncfft;
  final tmpR = plan.tmpR;
  final tmpI = plan.tmpI;
  final srcR = plan.srcR;
  final srcI = plan.srcI;

  // Pack real input as complex: cpx[k] = (time[2k], time[2k+1]), matching C's
  // reinterpret_cast.
  for (var k = 0; k < ncfft; k++) {
    srcR[k] = timedata[2 * k];
    srcI[k] = timedata[2 * k + 1];
  }

  _kissFftComplex(srcR, srcI, tmpR, tmpI, plan);

  final tdcR = _cFixdiv2(tmpR[0]);
  final tdcI = _cFixdiv2(tmpI[0]);
  outR[0] = tdcR + tdcI;
  outI[0] = 0;
  outR[ncfft] = tdcR - tdcI;
  outI[ncfft] = 0;

  for (var k = 1; k <= ncfft >> 1; k++) {
    final fpkRRaw = tmpR[k];
    final fpkIRaw = tmpI[k];
    final fpnkRRaw = tmpR[ncfft - k];
    // int16 negation wraps
    final fpnkIneg = ((-tmpI[ncfft - k]) << 16) >> 16;
    final fpkR = _cFixdiv2(fpkRRaw);
    final fpkI = _cFixdiv2(fpkIRaw);
    final fpnkR = _cFixdiv2(fpnkRRaw);
    final fpnkI = _cFixdiv2(fpnkIneg);
    final f1kR = fpkR + fpnkR;
    final f1kI = fpkI + fpnkI;
    final f2kR = fpkR - fpnkR;
    final f2kI = fpkI - fpnkI;
    final stR = plan.stCos[k - 1];
    final stI = plan.stSin[k - 1];
    final twR = _sround(f2kR * stR - f2kI * stI);
    final twI = _sround(f2kR * stI + f2kI * stR);
    outR[k] = (f1kR + twR) >> 1;
    outI[k] = (f1kI + twI) >> 1;
    outR[ncfft - k] = (f1kR - twR) >> 1;
    outI[ncfft - k] = (twI - f1kI) >> 1;
  }
}

// ── The frontend ───────────────────────────────────────────────────────

/// Stateful: keeps the sample window, the noise estimate, and PCAN gain state
/// across calls, exactly like the C frontend. One per audio stream.
class MicroFrontend {
  MicroFrontend() : _tables = sharedTables();

  final MicroFrontendTables _tables;

  final Int16List _input = Int16List(kWindowSize);
  int _inputUsed = 0;
  final Int16List _windowed = Int16List(kWindowSize);
  late final Int16List _fftTime = Int16List(kFftSize);
  late final Int16List _fftOutR = Int16List(kSpectrumSize);
  late final Int16List _fftOutI = Int16List(kSpectrumSize);
  final Float64List _filterbankWork = Float64List(kFeatureSize + 1);
  final Uint32List _noiseEstimate = Uint32List(kFeatureSize);
  final Float64List _signal = Float64List(kFeatureSize);

  /// Reusable frame buffers handed out by [_processWindow], grown to the most
  /// frames one [feed] call has produced, and the reusable results list.
  final List<Float32List> _frames = [];
  int _framesUsed = 0;
  final List<Float32List> _results = [];

  MicroFrontendTables get tables => _tables;

  /// Feed float samples in [-1, 1]; returns one 40-feature frame per completed
  /// 10 ms step (so usually 1 per 160 samples, 0 while the first window fills).
  ///
  /// The returned list and the frames in it are owned by the frontend and
  /// reused by the next [feed] call: copy anything kept across calls.
  List<Float32List> feed(List<double> samples) {
    if (samples.isEmpty) return const [];
    _framesUsed = 0;
    _results.clear();
    var offset = 0;

    while (offset < samples.length) {
      final writable =
          math.min(samples.length - offset, kWindowSize - _inputUsed);
      for (var i = 0; i < writable; i++) {
        _input[_inputUsed + i] = _floatToInt16(samples[offset + i]);
      }
      _inputUsed += writable;
      offset += writable;

      if (_inputUsed < kWindowSize) continue;

      _results.add(_processWindow());
      _input.setRange(0, kWindowSize - kStepSize, _input, kStepSize);
      _inputUsed -= kStepSize;
    }

    return _results;
  }

  void reset() {
    _input.fillRange(0, _input.length, 0);
    _windowed.fillRange(0, _windowed.length, 0);
    _fftTime.fillRange(0, _fftTime.length, 0);
    _fftOutR.fillRange(0, _fftOutR.length, 0);
    _fftOutI.fillRange(0, _fftOutI.length, 0);
    _filterbankWork.fillRange(0, _filterbankWork.length, 0);
    _noiseEstimate.fillRange(0, _noiseEstimate.length, 0);
    _inputUsed = 0;
  }

  Float32List _processWindow() {
    final windowCoefficients = _tables.windowCoefficients;
    final filterbank = _tables.filterbank;
    final fftPlan = _tables.fftPlan;

    var maxAbs = 0;
    for (var i = 0; i < kWindowSize; i++) {
      final value = _i32(_input[i] * windowCoefficients[i]) >> kFrontendWindowBits;
      _windowed[i] = value;
      final absValue = value < 0 ? -value : value;
      if (absValue > maxAbs) maxAbs = absValue;
    }

    final inputShift = 15 - _mostSignificantBit32(_u32(maxAbs));

    // C: fft_input[i] = (int16_t)((uint16_t)input[i] << input_scale_shift).
    // Zero-extend to uint16 first, then shift; the Int16List store wraps.
    for (var i = 0; i < kWindowSize; i++) {
      final uVal = _windowed[i] & 0xFFFF;
      _fftTime[i] = (uVal << inputShift) & 0xFFFF;
    }
    for (var i = kWindowSize; i < kFftSize; i++) {
      _fftTime[i] = 0;
    }

    _kissFftr(_fftTime, _fftOutR, _fftOutI, fftPlan);

    var weightAccumulator = 0.0;
    var unweightAccumulator = 0.0;

    for (var channel = 0; channel <= kFeatureSize; channel++) {
      final freqStart = filterbank.channelFrequencyStarts[channel];
      final weightStart = filterbank.channelWeightStarts[channel];
      final width = filterbank.channelWidths[channel];

      for (var j = 0; j < width; j++) {
        final bin = freqStart + j;
        final real = _fftOutR[bin];
        final imag = _fftOutI[bin];
        // C: uint32 mag = real*real + imag*imag, int16s widened to int32,
        // wrapping on overflow.
        final magnitude = _u32(real * real + imag * imag);
        weightAccumulator += filterbank.weights[weightStart + j] * magnitude;
        unweightAccumulator += filterbank.unweights[weightStart + j] * magnitude;
      }

      _filterbankWork[channel] = weightAccumulator;
      weightAccumulator = unweightAccumulator;
      unweightAccumulator = 0;
    }

    for (var i = 0; i < kFeatureSize; i++) {
      // C uses an integer Sqrt64 with rounding; sqrt + round matches for every
      // input we can reach (the weighted sums stay far below 2^53).
      final sqrtValue = math.sqrt(_filterbankWork[i + 1]).round();
      _signal[i] = (_u32(sqrtValue) >> inputShift).toDouble();
    }

    _applyNoiseReduction();
    _applyPcan();

    // Pre-quantization float features; each model applies its own
    // (scale, zero_point) on the way into its input tensor, so two models with
    // different quantization can share one feature stream. The buffer comes
    // from the reusable ring (see [feed]) and is fully overwritten below.
    if (_framesUsed == _frames.length) _frames.add(Float32List(kFeatureSize));
    final feature = _frames[_framesUsed++];
    for (var i = 0; i < kFeatureSize; i++) {
      final corrected = (_signal[i] * (1 << kInputCorrectionBits)).toInt();
      final logged = corrected > 1 ? _logScale(corrected) : 0;
      final clamped = logged < 0xFFFF ? logged : 0xFFFF;
      feature[i] = _fround(clamped * kFloat32Scale);
    }

    return feature;
  }

  void _applyNoiseReduction() {
    const nrBitsPow = 1 << kNoiseReductionBits; // 2^14
    const smBitsPow = 1 << kNoiseReductionSmoothingBits; // 2^10
    for (var i = 0; i < kFeatureSize; i++) {
      final smoothing = (i & 1) == 0
          ? kNoiseReductionEvenSmoothing
          : kNoiseReductionOddSmoothing;
      final oneMinus = nrBitsPow - smoothing;
      // C: uint32 signal_scaled_up = signal[i] << smoothing_bits, wrapping
      // once signal[i] > 2^22.
      final signalScaledUp = _u32((_signal[i] * smBitsPow).toInt());
      final estSum = signalScaledUp * smoothing + _noiseEstimate[i] * oneMinus;
      final estimate = _u32(_floorDiv(estSum, nrBitsPow));
      _noiseEstimate[i] = estimate;
      final estClamped = estimate > signalScaledUp ? signalScaledUp : estimate;
      final floorVal =
          _u32(_floorDiv(_signal[i] * kNoiseReductionMinSignal, nrBitsPow));
      final subtracted = _u32(_floorDiv(signalScaledUp - estClamped, smBitsPow));
      _signal[i] = (subtracted > floorVal ? subtracted : floorVal).toDouble();
    }
  }

  void _applyPcan() {
    for (var i = 0; i < kFeatureSize; i++) {
      final gain = _wideDynamicFunction(_noiseEstimate[i], _tables.gainLut);
      final snr = _floorDiv(_signal[i] * gain, 1 << kSnrShift);
      _signal[i] = _pcanShrink(snr).toDouble();
    }
  }
}

/// TFLite Micro's log lookup table (`log_lut.c`).
const List<int> kLogLut = <int>[
  0, 224, 442, 654, 861, 1063, 1259, 1450, 1636, 1817, 1992, 2163, 2329, 2490,
  2646, 2797, 2944, 3087, 3224, 3358, 3487, 3611, 3732, 3848, 3960, 4068, 4172,
  4272, 4368, 4460, 4549, 4633, 4714, 4791, 4864, 4934, 5001, 5063, 5123, 5178,
  5231, 5280, 5326, 5368, 5408, 5444, 5477, 5507, 5533, 5557, 5578, 5595, 5610,
  5622, 5631, 5637, 5640, 5641, 5638, 5633, 5626, 5615, 5602, 5586, 5568, 5547,
  5524, 5498, 5470, 5439, 5406, 5370, 5332, 5291, 5249, 5203, 5156, 5106, 5054,
  5000, 4944, 4885, 4825, 4762, 4697, 4630, 4561, 4490, 4416, 4341, 4264, 4184,
  4103, 4020, 3935, 3848, 3759, 3668, 3575, 3481, 3384, 3286, 3186, 3084, 2981,
  2875, 2768, 2659, 2549, 2437, 2323, 2207, 2090, 1971, 1851, 1729, 1605, 1480,
  1353, 1224, 1094, 963, 830, 695, 559, 421, 282, 142, 0, 0,
];
