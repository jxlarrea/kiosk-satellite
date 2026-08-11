// Synthetic 16 kHz mono PCM16 signals for the clap detector tests: claps as
// short decaying white-noise bursts, thuds as low-frequency sine bursts, and
// ambience as quiet noise. Deterministic (seeded Random) so a failure
// reproduces.
import 'dart:math';
import 'dart:typed_data';

const sampleRate = 16000;

/// Doubles (full scale 1.0) to little-endian PCM16 bytes.
Uint8List pcmOf(List<double> samples) {
  final out = Uint8List(samples.length * 2);
  final data = ByteData.sublistView(out);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i] * 32767).round().clamp(-32768, 32767);
    data.setInt16(i * 2, v, Endian.little);
  }
  return out;
}

/// Quiet ambient noise, the room the detector calibrates against.
List<double> ambience(int ms, Random rng, {double amp = 0.001}) => [
  for (var i = 0; i < sampleRate * ms ~/ 1000; i++)
    (rng.nextDouble() * 2 - 1) * amp,
];

/// A clap: 20 ms of white noise with a hard attack and exponential decay.
List<double> clap(Random rng, {double amp = 0.5}) => [
  for (var i = 0; i < sampleRate * 20 ~/ 1000; i++)
    (rng.nextDouble() * 2 - 1) * amp * exp(-i / (sampleRate * 0.006)),
];

/// A low-frequency thud: a 200 Hz sine burst with a 5 ms attack ramp, loud
/// but with almost no high-frequency content. Must not read as a clap.
List<double> thud(int ms, {double amp = 0.5, double freq = 200}) {
  final n = sampleRate * ms ~/ 1000;
  final ramp = sampleRate * 5 ~/ 1000;
  return [
    for (var i = 0; i < n; i++)
      sin(2 * pi * freq * i / sampleRate) *
          amp *
          (i < ramp ? i / ramp : 1.0) *
          (i > n - ramp ? (n - i) / ramp : 1.0),
  ];
}

/// Sustained loudness (music, an alarm): constant-level noise.
List<double> sustained(int ms, Random rng, {double amp = 0.3}) => [
  for (var i = 0; i < sampleRate * ms ~/ 1000; i++)
    (rng.nextDouble() * 2 - 1) * amp,
];

/// A full scene: ambience to settle the floor, [count] claps [gapMs] apart,
/// then a tail long enough to close the sequence.
List<double> clapScene(
  int count,
  Random rng, {
  int warmupMs = 700,
  int gapMs = 300,
  int tailMs = 900,
}) {
  final out = <double>[...ambience(warmupMs, rng)];
  for (var i = 0; i < count; i++) {
    if (i > 0) out.addAll(ambience(gapMs, rng));
    out.addAll(clap(rng));
  }
  out.addAll(ambience(tailMs, rng));
  return out;
}
