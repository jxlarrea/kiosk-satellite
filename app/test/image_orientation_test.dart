import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/image_orientation.dart';

/// A phone stores a portrait photo as a landscape frame plus a "turn me"
/// tag. Reading that tag is what tells a portrait photo from a landscape
/// one when only the header has been read.
void main() {
  /// A JPEG header carrying an EXIF block whose IFD0 holds [orientation],
  /// in [little] or big endian, followed by an empty start-of-scan.
  Uint8List jpeg(int orientation, {bool little = true}) {
    final tiff = BytesBuilder();
    final endian = little ? Endian.little : Endian.big;
    void u16(BytesBuilder b, int v) {
      final d = ByteData(2)..setUint16(0, v, endian);
      b.add(d.buffer.asUint8List());
    }

    void u32(BytesBuilder b, int v) {
      final d = ByteData(4)..setUint32(0, v, endian);
      b.add(d.buffer.asUint8List());
    }

    tiff.add(little ? [0x49, 0x49] : [0x4D, 0x4D]);
    u16(tiff, 42);
    u32(tiff, 8); // IFD0 right after the header
    u16(tiff, 1); // one entry
    u16(tiff, 0x0112); // orientation
    u16(tiff, 3); // SHORT
    u32(tiff, 1); // count
    u16(tiff, orientation);
    u16(tiff, 0); // padding of the 4-byte value field
    u32(tiff, 0); // no next IFD

    final exif = BytesBuilder()
      ..add([0x45, 0x78, 0x69, 0x66, 0x00, 0x00]) // "Exif\0\0"
      ..add(tiff.toBytes());
    final payload = exif.toBytes();

    final out = BytesBuilder()..add([0xFF, 0xD8]); // SOI
    final length = payload.length + 2;
    out
      ..add([0xFF, 0xE1, (length >> 8) & 0xFF, length & 0xFF])
      ..add(payload)
      ..add([0xFF, 0xDA]); // start of scan
    return out.toBytes();
  }

  test('reads the orientation tag, either byte order', () {
    expect(jpegOrientation(jpeg(6)), 6);
    expect(jpegOrientation(jpeg(8, little: false)), 8);
    expect(jpegOrientation(jpeg(1)), 1);
  });

  test('quarter turns swap the axes, the others do not', () {
    for (final o in [5, 6, 7, 8]) {
      expect(orientationSwapsAxes(o), isTrue, reason: '$o');
    }
    for (final o in [1, 2, 3, 4]) {
      expect(orientationSwapsAxes(o), isFalse, reason: '$o');
    }
  });

  test('anything without a readable tag reads as unrotated', () {
    // Not a JPEG, a bare JPEG with no EXIF, empty, and a truncated segment.
    expect(jpegOrientation(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47])), 1);
    expect(
      jpegOrientation(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xDA])),
      1,
    );
    expect(jpegOrientation(Uint8List(0)), 1);
    final truncated = jpeg(6).sublist(0, 12);
    expect(jpegOrientation(truncated), 1);
  });

  test('a nonsense orientation value reads as unrotated', () {
    expect(jpegOrientation(jpeg(42)), 1);
  });
}
