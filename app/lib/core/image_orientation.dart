/// The EXIF orientation of a JPEG, which decides whether its stored width
/// and height mean what they say.
///
/// A phone photographs in one sensor orientation and records how the
/// picture should be turned in an EXIF tag rather than rotating the pixels,
/// so a photo taken in portrait is commonly stored 4032x3024 with
/// orientation 6. The renderer turns it and shows a portrait photo, while
/// the header alone reads landscape. Anything measuring a photo's shape
/// (fill the screen, pairing portrait photos) has to account for that or it
/// judges those photos backwards.
library;

import 'dart:typed_data';

/// The EXIF orientation value 1..8, defaulting to 1 (no rotation) for
/// anything that is not a JPEG, carries no EXIF, or is malformed. Reading
/// stops at the first IFD0 orientation tag; this is a few hundred bytes of
/// scanning, not a decode.
int jpegOrientation(Uint8List bytes) {
  try {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return 1;
    final data = ByteData.sublistView(bytes);
    var offset = 2;
    while (offset + 4 <= bytes.length) {
      if (bytes[offset] != 0xFF) return 1; // out of step with the markers
      final marker = bytes[offset + 1];
      // Standalone markers carry no length; start of scan means the
      // metadata is behind us.
      if (marker == 0xD8 || marker == 0x01 || (marker >= 0xD0 &&
          marker <= 0xD7)) {
        offset += 2;
        continue;
      }
      if (marker == 0xDA || marker == 0xD9) return 1;
      final length = data.getUint16(offset + 2);
      if (length < 2) return 1;
      final segment = offset + 4;
      final end = segment + length - 2;
      if (end > bytes.length) return 1;
      if (marker == 0xE1 &&
          end - segment > 6 &&
          bytes[segment] == 0x45 && // E
          bytes[segment + 1] == 0x78 && // x
          bytes[segment + 2] == 0x69 && // i
          bytes[segment + 3] == 0x66 && // f
          bytes[segment + 4] == 0x00) {
        return _orientationInTiff(data, segment + 6, end);
      }
      offset = end;
    }
  } catch (_) {
    // A truncated or malformed header is not worth a failure: treat it as
    // an unrotated photo, exactly as before this existed.
  }
  return 1;
}

/// The orientation tag inside the TIFF block an EXIF segment wraps.
/// [start] is the TIFF header (the byte-order mark), [end] the segment end.
int _orientationInTiff(ByteData data, int start, int end) {
  if (start + 8 > end) return 1;
  final little = data.getUint16(start) == 0x4949;
  final endian = little ? Endian.little : Endian.big;
  if (!little && data.getUint16(start) != 0x4D4D) return 1;
  if (data.getUint16(start + 2, endian) != 42) return 1;
  final ifd = start + data.getUint32(start + 4, endian);
  if (ifd + 2 > end) return 1;
  final count = data.getUint16(ifd, endian);
  for (var i = 0; i < count; i++) {
    final entry = ifd + 2 + i * 12;
    if (entry + 12 > end) return 1;
    if (data.getUint16(entry, endian) == 0x0112) {
      final value = data.getUint16(entry + 8, endian);
      return value >= 1 && value <= 8 ? value : 1;
    }
  }
  return 1;
}

/// Whether [orientation] turns the photo a quarter circle, so its stored
/// width and height swap places on screen.
bool orientationSwapsAxes(int orientation) => orientation >= 5 &&
    orientation <= 8;
