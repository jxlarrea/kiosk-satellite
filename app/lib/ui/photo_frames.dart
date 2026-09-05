import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Fill the screen, the one rule every photo mode follows.
///
/// [fill] is the mode's setting: 'off' never crops, 'always' always does,
/// and 'smart' crops only a photo already shaped close to the frame it is
/// given. "Close enough" caps the crop at roughly a quarter along one axis
/// (a 1.45x ratio mismatch). it admits the common cases (4:3 or 16:9
/// camera frames on a 16:10 panel, either orientation, and a portrait shot
/// in a portrait half) while shapes a crop would gut keep their full
/// frame. True means cover-fit; false means the photo keeps its frame,
/// over a blurred copy of itself unless [fill] is 'off'.
///
/// A null [aspect] is a shape that could not be read: Smart keeps the
/// frame rather than guessing at a crop, while Always still covers, since
/// the whole point of it is that no photo is ever framed.
bool photoCovers(String fill, double? aspect, double frameAspect) {
  if (fill == 'off') return false;
  if (fill == 'always') return true;
  if (aspect == null || aspect <= 0 || frameAspect <= 0) return false;
  return max(aspect / frameAspect, frameAspect / aspect) <= 1.45;
}

Future<double?> photoAspect(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  try {
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final width = descriptor.width;
    final height = descriptor.height;
    descriptor.dispose();
    // ImageDescriptor reports the display dimensions, including EXIF rotation.
    return width / height;
  } catch (_) {
    return null;
  } finally {
    buffer.dispose();
  }
}

/// Decode for the visible fit, including the largest animation scale.
int photoDecodeWidth(Size frame, double? aspect, String fill, bool zoom) {
  var width = frame.width;
  if (aspect != null && aspect > 0 && frame.height > 0) {
    width = photoCovers(fill, aspect, frame.width / frame.height)
        ? max(frame.width, frame.height * aspect)
        : min(frame.width, frame.height * aspect);
  }
  width *= zoom ? 1.1 : 1;
  // Forced cropping of an extreme panorama must not create an enormous
  // off-screen bitmap. Ordinary screen-sized photos stay below this cap.
  if (aspect != null && aspect > 0) {
    width = min(width, sqrt((8 << 20) * aspect));
  }
  return max(1, width.floor());
}

class PhotoPreparationCancelled implements Exception {}

/// One decoded photo with a small separate image for a blurred backdrop.
class PreparedPhoto {
  PreparedPhoto(this.image, this.background, this.aspect);

  final ImageProvider image;
  final ImageProvider? background;
  final double? aspect;

  static Future<PreparedPhoto> prepare(
    Uint8List bytes, {
    required BuildContext context,
    required Size frame,
    required String fill,
    required bool zoom,
    required bool Function() valid,
    double? aspect,
    Future<void> Function()? beforeDecode,
  }) async {
    aspect ??= await photoAspect(bytes);
    if (!context.mounted || !valid()) throw PhotoPreparationCancelled();
    await beforeDecode?.call();
    if (!context.mounted || !valid()) throw PhotoPreparationCancelled();
    final source = MemoryImage(bytes);
    final image = ResizeImage(
      source,
      width: photoDecodeWidth(frame, aspect, fill, zoom),
    );
    final background =
        fill != 'off' && !photoCovers(fill, aspect, frame.width / frame.height)
        ? ResizeImage(
            source,
            width: 256,
            height: 256,
            policy: ResizeImagePolicy.fit,
          )
        : null;
    final photo = PreparedPhoto(image, background, aspect);
    try {
      Object? error;
      await Future.wait([
        precacheImage(image, context, onError: (e, _) => error = e),
        if (background != null)
          precacheImage(background, context, onError: (e, _) => error = e),
      ]);
      if (error != null) throw error!;
      if (!context.mounted || !valid()) throw PhotoPreparationCancelled();
      return photo;
    } catch (_) {
      photo.dispose();
      rethrow;
    }
  }

  void dispose() {
    unawaited(image.evict());
    if (background != null) unawaited(background!.evict());
  }
}

/// Keeps only the next prepared slide. A manual step can consume its pending
/// preparation too. Replacing a warm-up releases its result when it finishes.
class SlidePreloader<T> {
  SlidePreloader(this.dispose);
  final void Function(T) dispose;
  _Preparation<T>? _next;

  Future<T> take(Object key, Future<T> Function(bool Function()) load) {
    final next = _next;
    if (next != null && next.key == key) {
      _next = null;
      return next.future;
    }
    clear();
    return load(() => true);
  }

  void warm(Object key, Future<T> Function(bool Function()) load) {
    if (_next?.key == key) return;
    clear();
    final next = _Preparation<T>(key);
    _next = next;
    next.future = Future.sync(() => load(() => !next.cancelled));
    // Failures retry through the normal display path.
    unawaited(
      next.future.then<void>(
        (_) {},
        onError: (Object _) {
          if (identical(_next, next)) _next = null;
        },
      ),
    );
  }

  void clear() {
    final next = _next;
    _next = null;
    if (next == null) return;
    next.cancelled = true;
    unawaited(next.future.then<void>(dispose, onError: (Object _) {}));
  }
}

class _Preparation<T> {
  _Preparation(this.key);
  final Object key;
  bool cancelled = false;
  late Future<T> future;
}

/// A slide keeps its remaining hold when the panel turns off.
class PausableTimer {
  PausableTimer(
    this._remaining,
    this._callback, {
    bool paused = false,
    Stopwatch? stopwatch,
  }) : _elapsed = stopwatch ?? Stopwatch() {
    if (!paused) resume();
  }
  Duration _remaining;
  final void Function() _callback;
  final Stopwatch _elapsed;
  Timer? _timer;
  bool _cancelled = false;

  bool get isActive => !_cancelled;

  void pause() {
    if (_timer == null) return;
    _timer!.cancel();
    _timer = null;
    _elapsed.stop();
    _remaining -= _elapsed.elapsed;
  }

  void resume() {
    if (_cancelled || _timer != null) return;
    _elapsed.reset();
    _elapsed.start();
    _timer = Timer(_remaining, () {
      _cancelled = true;
      _timer = null;
      _elapsed.stop();
      _callback();
    });
  }

  void cancel() {
    _cancelled = true;
    _timer?.cancel();
    _timer = null;
    _elapsed.stop();
  }
}
