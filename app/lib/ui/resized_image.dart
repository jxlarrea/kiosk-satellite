import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Decoding images smaller than they are stored, without Impeller's GPU
/// downscale on OpenGL ES.
///
/// Impeller shrinks a decoded image by attaching the uploaded texture to a
/// framebuffer on its IO thread. On the Mali-T720 OpenGL ES driver that
/// attachment can come up incomplete while the main thread re-creates the
/// window surface for a hybrid composition WebView, and Impeller then
/// aborts the process. Where that can happen, these helpers have Android
/// scale the image to its drawn size first, so Flutter only uploads it.
/// Everywhere else they are the plain Flutter calls.
class GpuResize {
  GpuResize._();

  static const _channel = MethodChannel('kiosk_satellite/image');

  /// Whether Impeller may downscale on the GPU through OpenGL ES here. Safe
  /// until [init] answers on Android, the plain Flutter path elsewhere.
  static bool risky = !kIsWeb && Platform.isAndroid;

  static Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      risky = await _channel.invokeMethod<bool>('gpuResizeRisky') ?? true;
    } catch (_) {
      risky = true;
    }
  }

  /// Android's upright decode of [bytes] at exactly [width] x [height], or
  /// null when Android declines (animated images, unknown formats).
  static Future<Map<Object?, Object?>?> _downscale(
    Uint8List bytes,
    int width,
    int height, {
    required int sourceWidth,
    required int sourceHeight,
    bool png = false,
  }) async {
    try {
      return await _channel.invokeMethod<Map<Object?, Object?>>('downscale', {
        'bytes': bytes,
        'width': width,
        'height': height,
        // Flutter's upright size, which Android must read the same.
        'sourceWidth': sourceWidth,
        'sourceHeight': sourceHeight,
        'png': png,
      });
    } catch (_) {
      return null;
    }
  }
}

/// [MemoryImage] decoded at a smaller size, as [ResizeImage] would decode
/// it. The sizing rules are [ResizeImage]'s.
ImageProvider resizedMemoryImage(
  Uint8List bytes, {
  int? width,
  int? height,
  ResizeImagePolicy policy = ResizeImagePolicy.exact,
  bool allowUpscaling = false,
}) {
  final memory = MemoryImage(bytes);
  if (width == null && height == null) return memory;
  if (!GpuResize.risky) {
    return ResizeImage(
      memory,
      width: width,
      height: height,
      policy: policy,
      allowUpscaling: allowUpscaling,
    );
  }
  return _CpuResizedImage(bytes, width, height, policy, allowUpscaling);
}

/// [ui.instantiateImageCodec] with a target size, without the GPU downscale
/// on OpenGL ES. Either target may be null, as there.
Future<ui.Codec> instantiateResizedCodec(
  Uint8List bytes, {
  int? targetWidth,
  int? targetHeight,
}) async {
  if (!GpuResize.risky || (targetWidth == null && targetHeight == null)) {
    return ui.instantiateImageCodec(
      bytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }
  return _decode(bytes, (w, h) => (targetWidth, targetHeight));
}

/// Premultiplied RGBA of [bytes] at exactly [width] x [height], as
/// `toByteData(format: ImageByteFormat.rawRgba)` would give it, or null to
/// let the caller decode and read it back with Flutter. Only answers where
/// [GpuResize.risky]: that read back goes through a framebuffer.
Future<Uint8List?> cpuRgba(Uint8List bytes, int width, int height) async {
  if (!GpuResize.risky) return null;
  final (sourceWidth, sourceHeight) = await _uprightSize(bytes);
  final result = await GpuResize._downscale(
    bytes,
    width,
    height,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );
  final pixels = result?['pixels'];
  return pixels is Uint8List ? pixels : null;
}

/// A PNG of [bytes] fitted inside [box] x [box], or null to let the caller
/// encode it with Flutter. Only answers where [GpuResize.risky]: Flutter's
/// own PNG encode reads the texture back through a framebuffer.
Future<Uint8List?> cpuPngThumbnail(Uint8List bytes, int box) async {
  if (!GpuResize.risky) return null;
  final (width, height) = await _uprightSize(bytes);
  final scale = box / (width > height ? width : height);
  final target = scale >= 1
      ? (width, height)
      : (
          (width * scale).round().clamp(1, width),
          (height * scale).round().clamp(1, height),
        );
  final result = await GpuResize._downscale(
    bytes,
    target.$1,
    target.$2,
    sourceWidth: width,
    sourceHeight: height,
    png: true,
  );
  final png = result?['png'];
  return png is Uint8List ? png : null;
}

/// The upright size Flutter's codec reports for [bytes].
Future<(int, int)> _uprightSize(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  try {
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final size = (descriptor.width, descriptor.height);
    descriptor.dispose();
    return size;
  } finally {
    buffer.dispose();
  }
}

bool _isJpeg(Uint8List bytes) =>
    bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;

/// The smallest size the JPEG decoder produces by itself that covers
/// [width] x [height], or null when none comes close enough.
///
/// libjpeg-turbo scales by n/8 and sizes each side as `ceil(side * n / 8)`.
/// Skia picks n by rounding the scale it is asked for to the nearest eighth,
/// so asking for exactly that size gets it, upright or not. A size more
/// than twice the target's pixels (just above an eighth) would cost memory
/// for nothing, so that one is left to Android.
@visibleForTesting
(int, int)? jpegEighthSize(
  int sourceWidth,
  int sourceHeight,
  int width,
  int height,
) {
  // Below 16 pixels the rounding up could push Skia to the next eighth.
  if (sourceWidth < 16 || sourceHeight < 16) return null;
  for (var n = 1; n <= 8; n++) {
    final w = (sourceWidth * n + 7) ~/ 8;
    final h = (sourceHeight * n + 7) ~/ 8;
    if (w < width || h < height) continue;
    if (n == 8) return (sourceWidth, sourceHeight);
    return w * h <= 2 * width * height ? (w, h) : null;
  }
  return null;
}

/// The size [ResizeImage] asks the codec for, with the codec's own way of
/// filling in a missing side.
@visibleForTesting
(int, int) resolvedTargetSize(
  int intrinsicWidth,
  int intrinsicHeight,
  int? width,
  int? height,
  ResizeImagePolicy policy,
  bool allowUpscaling,
) {
  int? targetWidth;
  int? targetHeight;
  switch (policy) {
    case ResizeImagePolicy.exact:
      targetWidth = width;
      targetHeight = height;
      if (!allowUpscaling) {
        if (targetWidth != null && targetWidth > intrinsicWidth) {
          targetWidth = intrinsicWidth;
        }
        if (targetHeight != null && targetHeight > intrinsicHeight) {
          targetHeight = intrinsicHeight;
        }
      }
    case ResizeImagePolicy.fit:
      final aspectRatio = intrinsicWidth / intrinsicHeight;
      final maxWidth = width ?? intrinsicWidth;
      final maxHeight = height ?? intrinsicHeight;
      var fitWidth = intrinsicWidth;
      var fitHeight = intrinsicHeight;
      if (fitWidth > maxWidth) {
        fitWidth = maxWidth;
        fitHeight = fitWidth ~/ aspectRatio;
      }
      if (fitHeight > maxHeight) {
        fitHeight = maxHeight;
        fitWidth = (fitHeight * aspectRatio).floor();
      }
      if (allowUpscaling) {
        if (width == null) {
          fitHeight = height!;
          fitWidth = (fitHeight * aspectRatio).floor();
        } else if (height == null) {
          fitWidth = width;
          fitHeight = fitWidth ~/ aspectRatio;
        } else {
          fitWidth = [
            maxWidth,
            (maxHeight * aspectRatio).floor(),
          ].reduce((a, b) => a < b ? a : b);
          fitHeight = [
            maxHeight,
            maxWidth ~/ aspectRatio,
          ].reduce((a, b) => a < b ? a : b);
        }
      }
      targetWidth = fitWidth;
      targetHeight = fitHeight;
  }
  return _complete(intrinsicWidth, intrinsicHeight, targetWidth, targetHeight);
}

// ImageDescriptor.instantiateCodec's rules for a missing or invalid side.
(int, int) _complete(
  int width,
  int height,
  int? targetWidth,
  int? targetHeight,
) {
  if (targetWidth != null && targetWidth <= 0) targetWidth = null;
  if (targetHeight != null && targetHeight <= 0) targetHeight = null;
  if (targetWidth == null && targetHeight == null) return (width, height);
  if (targetWidth == null) {
    return ((targetHeight! * (width / height)).round(), targetHeight);
  }
  if (targetHeight == null) {
    return (targetWidth, targetWidth ~/ (width / height));
  }
  return (targetWidth, targetHeight);
}

/// Decodes [bytes] at the size [target] picks from the upright intrinsic
/// size: as is when that is the stored size, at the JPEG decoder's own
/// scale when one covers it, through Android otherwise, and through
/// Flutter's own resize only when Android declines.
Future<ui.Codec> _decode(
  Uint8List bytes,
  (int?, int?) Function(int width, int height) target,
) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final ui.ImageDescriptor descriptor;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
  } finally {
    buffer.dispose();
  }
  final (requestedWidth, requestedHeight) = target(
    descriptor.width,
    descriptor.height,
  );
  final (width, height) = _complete(
    descriptor.width,
    descriptor.height,
    requestedWidth,
    requestedHeight,
  );
  if (width == descriptor.width && height == descriptor.height) {
    return descriptor.instantiateCodec();
  }
  // A JPEG decodes at an eighth of its size, so asking for exactly that
  // size leaves Impeller nothing to resize, and the widget scales the rest
  // when it draws. This costs no more than Flutter's own decode did.
  final eighth = _isJpeg(bytes)
      ? jpegEighthSize(descriptor.width, descriptor.height, width, height)
      : null;
  if (eighth != null) {
    return descriptor.instantiateCodec(
      targetWidth: eighth.$1,
      targetHeight: eighth.$2,
    );
  }
  final scaled =
      width < descriptor.width && height <= descriptor.height ||
          width <= descriptor.width && height < descriptor.height
      ? await GpuResize._downscale(
          bytes,
          width,
          height,
          sourceWidth: descriptor.width,
          sourceHeight: descriptor.height,
        )
      : null;
  final pixels = scaled?['pixels'];
  if (pixels is! Uint8List) {
    return descriptor.instantiateCodec(
      targetWidth: width,
      targetHeight: height,
    );
  }
  descriptor.dispose();
  final rawBuffer = await ui.ImmutableBuffer.fromUint8List(pixels);
  try {
    return await ui.ImageDescriptor.raw(
      rawBuffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    ).instantiateCodec();
  } finally {
    rawBuffer.dispose();
  }
}

class _CpuResizedImage extends ImageProvider<_CpuResizedImage> {
  const _CpuResizedImage(
    this.bytes,
    this.width,
    this.height,
    this.policy,
    this.allowUpscaling,
  );

  final Uint8List bytes;
  final int? width;
  final int? height;
  final ResizeImagePolicy policy;
  final bool allowUpscaling;

  @override
  Future<_CpuResizedImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_CpuResizedImage>(this);

  @override
  ImageStreamCompleter loadImage(
    _CpuResizedImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _decode(bytes, (w, h) {
      final (tw, th) = resolvedTargetSize(
        w,
        h,
        width,
        height,
        policy,
        allowUpscaling,
      );
      return (tw, th);
    }),
    scale: 1.0,
    debugLabel: kReleaseMode
        ? null
        : 'CpuResizedImage(${describeIdentity(bytes)})',
  );

  @override
  bool operator ==(Object other) =>
      other is _CpuResizedImage &&
      identical(other.bytes, bytes) &&
      other.width == width &&
      other.height == height &&
      other.policy == policy &&
      other.allowUpscaling == allowUpscaling;

  @override
  int get hashCode => Object.hash(
    identityHashCode(bytes),
    width,
    height,
    policy,
    allowUpscaling,
  );
}
