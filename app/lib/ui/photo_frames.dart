import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'resized_image.dart';

/// Overrides photo filling in a shared screensaver panel without changing
/// the saved preference of any slideshow. Null keeps the slideshow's choice.
class PhotoFillOverride extends InheritedWidget {
  const PhotoFillOverride({
    super.key,
    required this.fill,
    required super.child,
  });

  final String? fill;

  static String? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PhotoFillOverride>()?.fill;

  static String resolve(BuildContext context, String fallback) =>
      of(context) ?? fallback;

  @override
  bool updateShouldNotify(PhotoFillOverride oldWidget) =>
      fill != oldWidget.fill;
}

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

/// Where a cover-fit photo sits in its frame so the faces in it stay in
/// view (issue #1552).
///
/// [crop] is the alignment to give the cover-fit image. [focus] is where
/// the faces land in the frame, as an alignment of the frame itself, which
/// is the point a Ken Burns zoom holds still so it never pushes them out.
typedef PhotoFraming = ({Alignment crop, Alignment focus});

/// Faces shorter than this share of the tallest one are people in the
/// background, and do not move the crop.
const _backgroundFace = 0.4;

/// The share of the crop window above the faces' center along a cropped
/// height: a little above the middle, where a portrait puts the eyes.
const _faceHeight = 0.4;

/// Whether a photo of [aspect] that covers a frame of [frameAspect] loses
/// any of itself to the crop: a shape a hair from the frame's shows whole
/// either way, and has nothing to frame.
bool photoCropped(double? aspect, double frameAspect) =>
    aspect != null &&
    aspect > 0 &&
    frameAspect > 0 &&
    (aspect / frameAspect - 1).abs() >= 0.01;

/// The framing that keeps [faces] (fractions of the photo, 0 to 1 across
/// and down) in view when a photo of [aspect] covers a frame of
/// [frameAspect], or null when the centered crop stands: no faces, a shape
/// that could not be read or nothing cropped.
///
/// Only the cropped axis moves. A crop across centers the window on the
/// faces. A crop down puts them a little above the middle and, for a group
/// too tall for the window, keeps the top of it, since a cut chin reads
/// better than a cut forehead. Each face is grown to roughly the head and
/// shoulders around it first, so the crop does not stop at the eyebrows.
PhotoFraming? photoFraming(
  List<Rect> faces,
  double? aspect,
  double frameAspect,
) {
  if (faces.isEmpty || !photoCropped(aspect, frameAspect)) return null;
  final ratio = aspect! / frameAspect;
  final tallest = faces.map((f) => f.height).reduce(max);
  final kept = [
    for (final f in faces)
      if (f.height >= tallest * _backgroundFace) f,
  ];
  final heads = kept.reduce((a, b) => a.expandToInclude(b));
  final shoulders = kept
      .map(
        (f) => Rect.fromLTRB(
          f.left - f.width * 0.3,
          f.top - f.height * 0.5,
          f.right + f.width * 0.3,
          f.bottom + f.height * 0.7,
        ),
      )
      .reduce((a, b) => a.expandToInclude(b))
      .intersect(const Rect.fromLTRB(0, 0, 1, 1));
  final center = heads.center;
  if (ratio > 1) {
    // Wider than the frame: the sides are cut, the window spans 1/ratio.
    final span = 1 / ratio;
    final start = _cropStart(
      shoulders.left,
      shoulders.right,
      center.dx,
      span,
      at: 0.5,
      keepStart: false,
    );
    return (
      crop: Alignment(_alignmentOf(start, span), 0),
      focus: Alignment(
        _frameAlignment(center.dx, start, span),
        center.dy * 2 - 1,
      ),
    );
  }
  // Taller than the frame: the top and bottom are cut.
  final span = ratio;
  final start = _cropStart(
    shoulders.top,
    shoulders.bottom,
    center.dy,
    span,
    at: _faceHeight,
    keepStart: true,
  );
  return (
    crop: Alignment(0, _alignmentOf(start, span)),
    focus: Alignment(
      center.dx * 2 - 1,
      _frameAlignment(center.dy, start, span),
    ),
  );
}

/// Where a window of [span] starts along one axis of the photo, so the
/// faces' [center] sits [at] its length, moved as little as needed to keep
/// the padded faces from [lo] to [hi] whole. Faces too long for the window
/// keep their start with [keepStart], or stay centered without it.
double _cropStart(
  double lo,
  double hi,
  double center,
  double span, {
  required double at,
  required bool keepStart,
}) {
  final double start;
  if (hi - lo > span) {
    start = keepStart ? lo : (lo + hi - span) / 2;
  } else {
    start = (center - span * at).clamp(hi - span, lo);
  }
  return start.clamp(0.0, 1.0 - span);
}

/// The alignment that puts a window of [span] starting at [start] in view:
/// -1 shows the start of the photo, 1 its end.
double _alignmentOf(double start, double span) =>
    span >= 1 ? 0 : (start / (1 - span) * 2 - 1).clamp(-1.0, 1.0);

/// Where [at] (a fraction of the photo) lands across the frame showing the
/// window from [start], as an alignment of the frame.
double _frameAlignment(double at, double start, double span) =>
    ((at - start) / span * 2 - 1).clamp(-1.0, 1.0);

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
    final image = resizedMemoryImage(
      bytes,
      width: photoDecodeWidth(frame, aspect, fill, zoom),
    );
    final background =
        fill != 'off' && !photoCovers(fill, aspect, frame.width / frame.height)
        ? resizedMemoryImage(
            bytes,
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
  }) : total = _remaining,
       _elapsed = stopwatch ?? Stopwatch() {
    if (!paused) resume();
  }

  /// The whole hold, for a progress bar that fills as it runs out.
  final Duration total;
  Duration _remaining;
  final void Function() _callback;
  final Stopwatch _elapsed;
  Timer? _timer;
  bool _cancelled = false;

  bool get isActive => !_cancelled;

  /// Whether the hold is counting down right now: started, not paused,
  /// not fired and not cancelled.
  bool get isRunning => _timer != null;

  /// How much of the hold has run, from 0 to 1. It stands still while the
  /// timer is paused and stays where it was when the timer is cancelled.
  double get progress {
    if (total <= Duration.zero) return 1;
    var left = _remaining;
    if (_timer != null) left -= _elapsed.elapsed;
    final done = 1 - left.inMicroseconds / total.inMicroseconds;
    return done.clamp(0.0, 1.0);
  }

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
      _remaining = Duration.zero;
      _callback();
    });
  }

  void cancel() {
    pause();
    _cancelled = true;
  }
}
