import 'dart:typed_data';

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
