import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/wake_word/pcm16.dart';

void main() {
  test('aligned and unaligned PCM16LE preserve signed sample boundaries', () {
    const expected = [-32768, -1, 0, 1, 32767];
    for (final offset in [0, 1, 2, 3]) {
      final bytes = Uint8List(offset + expected.length * 2 + 2);
      final data = ByteData.sublistView(bytes);
      for (var i = 0; i < expected.length; i++) {
        data.setInt16(offset + i * 2, expected[i], Endian.little);
      }
      final slice = Uint8List.sublistView(bytes, offset);
      expect(pcm16Samples(slice, 0, expected.length * 2), expected);
    }
  });

  test('takeBytes preserves split samples and multiple chunks', () {
    final pending = BytesBuilder(copy: false);
    final wire = Uint8List.fromList([0, 128, 255, 127, 255, 255, 1, 0]);
    final decoded = <int>[];
    for (final slice in [
      wire.sublist(0, 1),
      wire.sublist(1, 5),
      wire.sublist(5)
    ]) {
      pending.add(slice);
      final buf = pending.takeBytes();
      final end = buf.length - buf.length % 4;
      decoded.addAll(pcm16Samples(buf, 0, end));
      if (end < buf.length) pending.add(Uint8List.sublistView(buf, end));
    }
    expect(decoded, [-32768, 32767, -1, 1]);
    expect(pending.length, 0);
  });

  test('rejects partial samples', () {
    expect(() => pcm16Samples(Uint8List(3), 0, 3), throwsArgumentError);
  });
}
