import 'dart:convert';
import 'dart:math' show max;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';

/// Whether [bytes] are an SVG document rather than a bitmap. A radio
/// station's logo often is (issue #1496), and Music Assistant passes an SVG
/// through its image proxy unchanged, even when asked for a JPEG.
bool isSvgArtwork(Uint8List bytes) {
  final head = utf8
      .decode(bytes.take(512).toList(), allowMalformed: true)
      .trimLeft()
      .toLowerCase();
  return (head.startsWith('<svg') ||
          head.startsWith('<?xml') ||
          head.startsWith('<!--') ||
          head.startsWith('<!doctype')) &&
      head.contains('<svg');
}

/// An SVG cover drawn into a [size] x [size] PNG, so every surface that
/// decodes covers as bitmaps can show it: the floating player, the full
/// screen view, the queue, the media notification and the remote admin.
/// The logo keeps its shape, centered on a transparent square, so a cover
/// crop never cuts it. Null when the SVG cannot be drawn.
Future<Uint8List?> svgArtworkToPng(Uint8List bytes, {int size = 512}) async {
  final PictureInfo info;
  try {
    info = await vg.loadPicture(SvgBytesLoader(bytes), null);
  } catch (_) {
    return null;
  }
  ui.Picture? scaled;
  ui.Image? image;
  try {
    final width = info.size.width;
    final height = info.size.height;
    if (!(width > 0 && height > 0)) return null;
    final scale = size / max(width, height);
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder)
      ..translate((size - width * scale) / 2, (size - height * scale) / 2)
      ..scale(scale)
      ..drawPicture(info.picture);
    scaled = recorder.endRecording();
    image = await scaled.toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } catch (_) {
    return null;
  } finally {
    image?.dispose();
    scaled?.dispose();
    info.picture.dispose();
  }
}
