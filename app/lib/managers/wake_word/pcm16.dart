import 'dart:math' as math;
import 'dart:typed_data';

/// Wrap PCM16LE [pcm] in a WAV header, so a player or a browser can open it.
Uint8List pcm16Wav(Uint8List pcm, {int sampleRate = 16000}) {
  final length = pcm.length & ~1;
  final out = Uint8List(44 + length);
  final header = ByteData.sublistView(out, 0, 44);
  void tag(int offset, String value) =>
      out.setRange(offset, offset + 4, value.codeUnits);
  tag(0, 'RIFF');
  header.setUint32(4, 36 + length, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  header
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  tag(36, 'data');
  header.setUint32(40, length, Endian.little);
  out.setRange(44, 44 + length, pcm);
  return out;
}

/// Peak and RMS of PCM16LE [pcm] in dBFS, plus how many samples hit full
/// scale. What decides whether a microphone is too quiet or clipping.
({double peakDb, double rmsDb, int clipped}) pcm16Levels(Uint8List pcm) {
  final samples = pcm16Samples(pcm, 0, pcm.length & ~1);
  if (samples.isEmpty) {
    return (
      peakDb: double.negativeInfinity,
      rmsDb: double.negativeInfinity,
      clipped: 0,
    );
  }
  var peak = 0;
  var sum = 0.0;
  var clipped = 0;
  for (final s in samples) {
    final a = s < 0 ? -s : s;
    if (a > peak) peak = a;
    if (a >= 32767) clipped++;
    sum += s * s;
  }
  double db(double v) =>
      v <= 0 ? double.negativeInfinity : 20 * math.log(v) / math.ln10;
  return (
    peakDb: db(peak / 32768),
    rmsDb: db(math.sqrt(sum / samples.length) / 32768),
    clipped: clipped,
  );
}

/// View PCM16LE without a copy when alignment and host byte order permit it.
/// Platform messages and partial chunks can start at an odd buffer offset.
Int16List pcm16Samples(Uint8List bytes, int start, int end) {
  final view = Uint8List.sublistView(bytes, start, end);
  if (view.length.isOdd) throw ArgumentError('PCM16 requires whole samples');
  if (Endian.host == Endian.little && view.offsetInBytes.isEven) {
    return Int16List.sublistView(view);
  }
  final data = ByteData.sublistView(view);
  final samples = Int16List(view.length ~/ 2);
  for (var i = 0; i < samples.length; i++) {
    samples[i] = data.getInt16(i * 2, Endian.little);
  }
  return samples;
}
