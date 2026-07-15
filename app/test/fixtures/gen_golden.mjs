// Golden vectors for the Dart port of the microWakeWord fixed-point frontend.
//
// Dumps both the derived tables (built once from float math that Dart lacks
// primitives for: Math.fround, Math.log1p) and the feature frames for a
// deterministic input. The tables matter on their own: a 1-ulp difference in
// freqToMel can shift a filterbank channel boundary, which no amount of
// staring at final features would explain.
//
// The input is generated from an LCG the Dart test reproduces exactly, so it
// does not need storing: integers and power-of-two divisions only.
import { createJsMicroFrontend, roundBankers } from '/home/jxlarrea/repos/voice-satellite-card-integration/src/wake-word/micro-frontend-js/index.js';

const N = 8000; // 0.5 s @ 16 kHz
const input = new Float64Array(N);
let seed = 12345 >>> 0;
function next() {
  seed = (Math.imul(seed, 1103515245) + 12345) >>> 0;
  return seed;
}
for (let i = 0; i < N; i++) {
  // Pseudo-random int16-valued floats: exact in both languages.
  input[i] = ((next() % 65536) - 32768) / 32768;
}

const fe = await createJsMicroFrontend();
const shared = fe._shared;

const frames = [];
for (let off = 0; off < N; off += 160) {
  for (const f of fe.feed(input.subarray(off, off + 160))) {
    frames.push(Array.from(f));
  }
}

const fb = shared.filterbank;
const plan = shared.fftPlan;
const out = {
  meta: { samples: N, frames: frames.length, featureSize: frames[0]?.length ?? 0 },
  windowCoefficients: Array.from(shared.windowCoefficients),
  filterbank: {
    channelFrequencyStarts: Array.from(fb.channelFrequencyStarts ?? []),
    channelWeightStarts: Array.from(fb.channelWeightStarts ?? []),
    channelWidths: Array.from(fb.channelWidths ?? []),
    weights: Array.from(fb.weights ?? []),
    unweights: Array.from(fb.unweights ?? []),
    startIndex: fb.startIndex,
    endIndex: fb.endIndex,
  },
  fftPlan: {
    nfftReal: plan.nfftReal,
    ncfft: plan.ncfft,
    factors: Array.from(plan.factors ?? []),
    twCos: Array.from(plan.twCos ?? []),
    twSin: Array.from(plan.twSin ?? []),
    stCos: Array.from(plan.stCos ?? []),
    stSin: Array.from(plan.stSin ?? []),
  },
  // buildGainLut returns { lut, base }, not a bare array.
  gainLut: Array.from(shared.gainLut.lut),
  frames,
  // roundBankers drives feature quantization, and zero_point is -128 so
  // negative half-values are routine: exactly where JS Math.round (half toward
  // +inf) and Dart .round() (half away from zero) disagree.
  roundBankers: [-3.5, -2.5, -1.5, -0.5, 0, 0.5, 1.5, 2.5, 3.5, 2.4, 2.6, -2.4, -2.6, 127.5, -128.5]
    .map((x) => [x, roundBankers(x)]),
};
console.log(JSON.stringify(out));
