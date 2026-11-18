import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/sendspin/svg_artwork.dart';

/// A wide logo, blue on a transparent background, the way a radio
/// station's logo is often served (issue #1496).
final _wideLogo = Uint8List.fromList(
  utf8.encode(
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 100">'
    '<rect width="200" height="100" fill="#0078a9"/></svg>',
  ),
);

Future<ui.Image> _decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  return (await codec.getNextFrame()).image;
}

Future<List<int>> _pixel(ui.Image image, int x, int y) async {
  final data = (await image.toByteData())!;
  final i = (y * image.width + x) * 4;
  return [for (var c = 0; c < 4; c++) data.getUint8(i + c)];
}

void main() {
  test('recognizes an SVG document and leaves bitmaps alone', () {
    expect(isSvgArtwork(_wideLogo), isTrue);
    expect(
      isSvgArtwork(
        Uint8List.fromList(utf8.encode('  <svg viewBox="0 0 1 1"/>')),
      ),
      isTrue,
    );
    // A PNG and a JPEG signature.
    expect(
      isSvgArtwork(
        Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 13, 10, 26, 10]),
      ),
      isFalse,
    );
    expect(isSvgArtwork(Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0])), isFalse);
    // XML that is not an SVG.
    expect(
      isSvgArtwork(
        Uint8List.fromList(utf8.encode('<?xml version="1.0"?><a/>')),
      ),
      isFalse,
    );
  });

  test('draws an SVG logo into a square PNG, centered and uncropped', () async {
    final png = await svgArtworkToPng(_wideLogo, size: 64);
    expect(png, isNotNull);
    final image = await _decode(png!);
    expect([image.width, image.height], [64, 64]);
    // The 2:1 logo fills the width and the middle half of the height.
    expect(await _pixel(image, 32, 32), [0x00, 0x78, 0xa9, 0xff]);
    expect(await _pixel(image, 1, 32), [0x00, 0x78, 0xa9, 0xff]);
    expect((await _pixel(image, 32, 4))[3], 0);
    expect((await _pixel(image, 32, 60))[3], 0);
  });

  test('an SVG that cannot be drawn gives null', () async {
    final broken = Uint8List.fromList(utf8.encode('<svg><path d="'));
    expect(await svgArtworkToPng(broken, size: 64), isNull);
  });
}
