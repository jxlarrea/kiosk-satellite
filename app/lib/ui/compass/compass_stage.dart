import 'dart:async';
import 'dart:developer' show Timeline;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../managers/navigation/compass_layout.dart';
import 'compass_controller.dart';

/// How far a finger travels before the swipe decides which way it goes.
const _decideDistance = 24.0;

/// How long the swipe waits on the page to say whether a touch is its own
/// (a slider, a map) before leaving the touch to the page.
const _hintWait = Duration(milliseconds: 180);

/// The size the views shrink to while a Zoom swipe is in motion.
const _zoomScale = 0.75;

/// Past this share of the screen a release commits; a flick commits from
/// much less.
const _commitShare = 0.3;
const _flickSpeed = 500.0;

/// The unit step on the grid each move goes.
Offset _moveVector(CompassMove move) => switch (move) {
  CompassMove.up => const Offset(0, -1),
  CompassMove.down => const Offset(0, 1),
  CompassMove.left => const Offset(-1, 0),
  CompassMove.right => const Offset(1, 0),
};

/// The page's answer about one touch (compass_page_script.dart).
class CompassPageHint {
  const CompassPageHint({
    required this.sideways,
    required this.vertical,
    required this.top,
    required this.bottom,
  });

  factory CompassPageHint.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    return CompassPageHint(
      sideways: map['h'] == true,
      vertical: map['v'] == true,
      top: map['top'] != false,
      bottom: map['bottom'] != false,
    );
  }

  /// The page owns a sideways drag here.
  final bool sideways;

  /// The page owns an up or down drag here.
  final bool vertical;

  /// Every scroller under the finger is at its top, or at its bottom.
  final bool top;
  final bool bottom;
}

/// Reads Compass swipes off the raw pointer stream and drives the stage.
///
/// A [Listener] never joins the gesture arena, so the WebView and every
/// page drawn over it keep their touches exactly as before: a drag
/// recognizer here would hold each touch back from the platform view until
/// the finger lifts. The swipe is decided from the travel alone, after
/// [_decideDistance], and stands down whenever something under the finger
/// owns that drag: a Flutter scrollable that scrolled (heard through its
/// scroll notifications), or a slider, map or scroller in the page (heard
/// from the page probe).
class CompassGestureLayer extends StatefulWidget {
  const CompassGestureLayer({
    super.key,
    required this.controller,
    required this.child,
  });

  final CompassController controller;
  final Widget child;

  @override
  State<CompassGestureLayer> createState() => _CompassGestureLayerState();
}

class _CompassGestureLayerState extends State<CompassGestureLayer>
    with TickerProviderStateMixin {
  CompassController get ctrl => widget.controller;

  // Made while mounted, never lazily: a first use in dispose would look
  // up a deactivated ancestor.
  late final AnimationController _anim;

  /// Runs while the finger drags: the drawn position eases toward the
  /// finger every frame. Touches reach Flutter through the platform view's
  /// dispatch, slower and less even than the display refreshes, and a
  /// position set per touch event leaps a few dozen pixels at a time.
  late final Ticker _follow;
  Duration _lastTick = Duration.zero;

  /// Where the finger has the swipe, 0 to 1. What is drawn follows it.
  double _fingerP = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this);
    _follow = createTicker(_onFollow);
  }

  final Set<int> _down = {};
  int? _pointer;
  Offset _start = Offset.zero;
  DateTime _downAt = DateTime.now();
  VelocityTracker? _velocity;
  bool _gaveUp = false;
  bool _scrolledH = false;
  bool _scrolledV = false;

  /// The swipe being dragged or settling, null while none is.
  CompassStageModel? _model;
  bool _settling = false;
  double _extent = 1;
  Timer? _landingShot;

  // Frame timings of the swipe in hand, logged when it ends: how long the
  // snapshot took to arrive and how the frames held up while it moved.
  final Stopwatch _clock = Stopwatch();
  int _captureMs = -1;

  /// The engine clock (microseconds) when the stage started and stopped
  /// moving: frames between the two are the ones the eye follows.
  int _motionFrom = 0;
  int _motionTo = 0;
  final List<FrameTiming> _timings = [];
  void _onTimings(List<FrameTiming> timings) => _timings.addAll(timings);

  @override
  void dispose() {
    _landingShot?.cancel();
    _follow.dispose();
    _anim.dispose();
    _end();
    super.dispose();
  }

  void _onFollow(Duration elapsed) {
    final model = _model;
    if (model == null || _settling) return;
    final dt = (elapsed - _lastTick).inMicroseconds / 1000;
    _lastTick = elapsed;
    if (!model.ready) return;
    // Frame-time adaptive: a long frame closes more of the gap, so a
    // stall never turns into visible lag.
    final k = math.min(1.0, dt / 16 * 0.5);
    var p = model.progress + (_fingerP - model.progress) * k;
    if ((_fingerP - p).abs() < 0.0005) p = _fingerP;
    model.update(progress: p, scale: _scaleFor(model, p));
  }

  // ── Pointer stream ──────────────────────────────────────────────────

  void _onDown(PointerDownEvent e) {
    _down.add(e.pointer);
    if (_down.length > 1) {
      // A second finger is a pinch or a two-finger gesture, never a swipe.
      _gaveUp = true;
      if (_model != null && !_settling) unawaited(_cancel());
      return;
    }
    _pointer = null;
    if (_model != null || !ctrl.swipeReady) return;
    _pointer = e.pointer;
    _start = e.position;
    _downAt = DateTime.now();
    _gaveUp = false;
    _scrolledH = false;
    _scrolledV = false;
    ctrl.clearPageHint();
    _velocity = VelocityTracker.withKind(e.kind)
      ..addPosition(e.timeStamp, e.position);
  }

  void _onMove(PointerMoveEvent e) {
    if (e.pointer != _pointer || _gaveUp) return;
    _velocity?.addPosition(e.timeStamp, e.position);
    final model = _model;
    if (model == null) {
      _decide(e.position);
    } else if (!_settling) {
      _drag(model, e.position);
    }
  }

  void _onUp(PointerUpEvent e) {
    _down.remove(e.pointer);
    if (e.pointer != _pointer) return;
    _pointer = null;
    final model = _model;
    if (model == null || _settling || _gaveUp) return;
    final velocity = _velocity?.getVelocity().pixelsPerSecond ?? Offset.zero;
    final v =
        velocity.dx * -_moveVector(model.move).dx +
        velocity.dy * -_moveVector(model.move).dy;
    final commit =
        _fingerP > _commitShare || (v > _flickSpeed && _fingerP > 0.04);
    unawaited(commit ? _commit() : _cancel());
  }

  void _onCancel(PointerCancelEvent e) {
    _down.remove(e.pointer);
    if (e.pointer != _pointer) return;
    _pointer = null;
    if (_model != null && !_settling) unawaited(_cancel());
  }

  /// A Flutter page under the finger moved its own scroll: that drag is
  /// the page's. A scroll held at its edge reports overscroll instead,
  /// which leaves the swipe free to take it.
  bool _onScroll(ScrollNotification n) {
    if (_pointer != null && _model == null && n is ScrollUpdateNotification) {
      if (n.dragDetails != null && (n.scrollDelta ?? 0) != 0) {
        if (n.metrics.axis == Axis.horizontal) {
          _scrolledH = true;
        } else {
          _scrolledV = true;
        }
      }
    }
    return false;
  }

  // ── Deciding ────────────────────────────────────────────────────────

  void _decide(Offset at) {
    final d = at - _start;
    if (d.distance < _decideDistance) return;
    final CompassMove move;
    final bool sideways;
    if (d.dx.abs() > d.dy.abs() * 2) {
      sideways = true;
      move = d.dx < 0 ? CompassMove.right : CompassMove.left;
    } else if (d.dy.abs() > d.dx.abs() * 2) {
      sideways = false;
      move = d.dy < 0 ? CompassMove.down : CompassMove.up;
    } else {
      _gaveUp = true;
      return;
    }
    if (sideways ? _scrolledH : _scrolledV) {
      _gaveUp = true;
      return;
    }
    if (ctrl.currentView.isDashboard) {
      final hint = ctrl.pageHintSince(_downAt);
      if (hint == null) {
        // The page has not answered yet: wait for it a little, then leave
        // the touch alone. No answer at all means the finger is on a card
        // drawn over the page, not on the page.
        if (DateTime.now().difference(_downAt) > _hintWait) _gaveUp = true;
        return;
      }
      final owned = sideways ? hint.sideways : hint.vertical;
      final edge = switch (move) {
        CompassMove.up => hint.top,
        CompassMove.down => hint.bottom,
        _ => true,
      };
      if (owned || !edge) {
        _gaveUp = true;
        return;
      }
    }
    final from = ctrl.current.value;
    final target = ctrl.layout.step(from, move, available: ctrl.available);
    if (target == null) {
      _gaveUp = true;
      return;
    }
    _claim(from, move, target, sideways, at);
  }

  void _claim(
    CompassSlot from,
    CompassMove move,
    CompassSlot target,
    bool sideways,
    Offset at,
  ) {
    final size = MediaQuery.sizeOf(context);
    _extent = sideways ? size.width : size.height;
    final layout = ctrl.layout;
    final zoom = ctrl.zoom;
    final tiles = <CompassTile>[];
    CompassTile tile(CompassView view, Offset at, {bool shot = true}) =>
        CompassTile(
          view: view,
          dx: at.dx.round(),
          dy: at.dy.round(),
          label: compassViewLabel(context, ctrl.c, view),
          icon: compassViewIcon(view),
          // A clone: the cache may let its copy go while the swipe still
          // draws this one.
          image: shot ? ctrl.shotOf(view)?.clone() : null,
        );
    final here = ctrl.currentView;
    // The view in hand draws from the capture below, never a stale shot.
    tiles.add(tile(here, Offset.zero, shot: false));
    // The whole cross where it really lies around the view in hand, not
    // only its own neighbors: from the view below the center, the views
    // either side of the center come into sight as well. A view that
    // cannot show leaves its place empty. A slide draws the target alone.
    Offset place(CompassSlot slot) => Offset(
      (slot.grid.x - from.grid.x).toDouble(),
      (slot.grid.y - from.grid.y).toDouble(),
    );
    for (final slot in layout.slots) {
      if (slot == from) continue;
      final view = layout.viewAt(slot);
      if (view == null) continue;
      final isTarget = slot == target;
      if (!isTarget && (!zoom || !ctrl.available(view))) continue;
      tiles.add(tile(view, place(slot)));
    }
    final model = CompassStageModel(
      from: from,
      move: move,
      target: target,
      travel: place(target),
      tiles: tiles,
      zoom: zoom,
    );
    _model = model;
    ctrl.stage.value = model;
    _clock
      ..reset()
      ..start();
    _captureMs = -1;
    _timings.clear();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final width = math.min(size.width * ratio, 1280).round();
    unawaited(
      ctrl.capture(here, width: width).then((image) {
        if (_model != model || !mounted) {
          image?.dispose();
          return;
        }
        if (image == null) {
          // No capture on this device: the swipe still switches views on
          // release, it just has nothing to draw.
          model.noSnapshot = true;
          return;
        }
        model.tiles.first.image = image;
        _captureMs = _clock.elapsedMilliseconds;
        // The first frame matches the live screen exactly; the follow
        // ticker then eases it out to the finger, so the hand-off from the
        // live view to the stage never jumps.
        model.update(progress: 0, scale: 1);
        model.markReady();
        _motionFrom = Timeline.now;
        _motionTo = 0;
        _coverPlaneAfterPaint(model);
      }),
    );
    _drag(model, at);
    _lastTick = Duration.zero;
    if (!_follow.isActive) unawaited(_follow.start());
  }

  void _drag(CompassStageModel model, Offset at) {
    final d = at - _start;
    final v = _moveVector(model.move);
    _fingerP = ((-d.dx * v.dx - d.dy * v.dy) / _extent).clamp(0.0, 1.0);
  }

  /// Once the stage has painted over everything, the dashboard leaves the
  /// frame. A platform view anywhere under a moving Flutter frame makes
  /// every frame wait on Android's own UI thread (hybrid composition), and
  /// the page under it keeps drawing its cameras for nobody.
  void _coverPlaneAfterPaint(CompassStageModel model) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_model == model && model.ready) unawaited(ctrl.coverPlane(true));
    });
  }

  /// The dashboard back in the frame before the stage lifts, given a
  /// moment to draw again so the reveal never shows an empty frame.
  Future<void> _uncoverPlane() async {
    if (!ctrl.planeCovered.value) return;
    await ctrl.settlePlane();
    // The view draws its first frame after it is shown again.
    if (!ctrl.planeCovered.value) await _frames(3);
  }

  double _scaleFor(CompassStageModel model, double p) {
    if (!model.zoom) return 1;
    final t = Curves.easeOut.transform((p / 0.2).clamp(0.0, 1.0));
    return ui.lerpDouble(1, _zoomScale, t)!;
  }

  // ── Settling ────────────────────────────────────────────────────────

  Future<void> _commit() async {
    final model = _model;
    if (model == null) return;
    _settling = true;
    _follow.stop();
    if (!model.ready) {
      // No snapshot to draw: switch straight away.
      await ctrl.show(model.target);
      _end();
      return;
    }
    {
      await _tween(
        model,
        progress: 1,
        scale: model.zoom ? _zoomScale : 1,
        duration: Duration(milliseconds: model.zoom ? 260 : 240),
        curve: Curves.easeOutCubic,
      );
      if (model.zoom) {
        await _tween(
          model,
          progress: 1,
          scale: 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
        );
      }
    }
    _motionTo = Timeline.now;
    // Only now, under a still full-screen frame of the target: the view
    // building or the page moving mid-slide would cost the motion frames.
    await ctrl
        .show(model.target)
        .timeout(const Duration(seconds: 2), onTimeout: () {});
    await _uncoverPlane();
    // A page move lands a beat after the navigation call returns.
    if (ctrl.layout.viewAt(model.target)?.isDashboard == true) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    if (model.ready) {
      await _tween(
        model,
        opacity: 0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    }
    _end();
    _scheduleLandingShot(model.target);
  }

  Future<void> _cancel() async {
    final model = _model;
    if (model == null) return;
    _settling = true;
    _follow.stop();
    if (model.ready) {
      await _tween(
        model,
        progress: 0,
        scale: 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
      _motionTo = Timeline.now;
      await _uncoverPlane();
    }
    _end();
  }

  Future<void> _tween(
    CompassStageModel model, {
    double? progress,
    double? scale,
    double? opacity,
    required Duration duration,
    required Curve curve,
  }) async {
    final p0 = model.progress, s0 = model.scale, o0 = model.opacity;
    void tick() {
      final t = curve.transform(_anim.value);
      model.update(
        progress: progress == null ? null : ui.lerpDouble(p0, progress, t),
        scale: scale == null ? null : ui.lerpDouble(s0, scale, t),
        opacity: opacity == null ? null : ui.lerpDouble(o0, opacity, t),
      );
    }

    _anim.duration = duration;
    _anim.addListener(tick);
    try {
      await _anim.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Disposed mid-swipe.
    } finally {
      _anim.removeListener(tick);
    }
  }

  Future<void> _frames(int count) async {
    for (var i = 0; i < count; i++) {
      final done = Completer<void>();
      SchedulerBinding.instance.addPostFrameCallback((_) => done.complete());
      SchedulerBinding.instance.scheduleFrame();
      await done.future;
    }
  }

  void _end() {
    final model = _model;
    _model = null;
    _settling = false;
    if (model == null) return;
    _report(model);
    _follow.stop();
    if (ctrl.stage.value == model) ctrl.stage.value = null;
    unawaited(ctrl.settlePlane());
    for (final tile in model.tiles) {
      tile.image?.dispose();
      tile.image = null;
    }
    model.dispose();
  }

  /// One log line per swipe: the snapshot's wait and the frames drawn
  /// while it moved. Timings arrive in batches, so the line waits for the
  /// last of them.
  void _report(CompassStageModel model) {
    final total = _clock.elapsedMilliseconds;
    final capture = _captureMs;
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
      final all = [..._timings];
      _timings.clear();
      final to = _motionTo == 0 ? 1 << 62 : _motionTo;
      final frames = [
        for (final f in all)
          if (f.timestampInMicroseconds(ui.FramePhase.vsyncStart) >=
                  _motionFrom &&
              f.timestampInMicroseconds(ui.FramePhase.vsyncStart) <= to)
            f,
      ];
      if (frames.isEmpty) {
        ctrl.c.log.info(
          'compass',
          'swipe: ${all.length} frames, none in motion',
        );
        return;
      }
      final motionMs = (to == 1 << 62 ? 0 : to - _motionFrom) ~/ 1000;
      double ms(Duration d) => d.inMicroseconds / 1000;
      final build = frames.map((f) => ms(f.buildDuration)).toList();
      final raster = frames.map((f) => ms(f.rasterDuration)).toList();
      final span = frames.map((f) => ms(f.totalSpan)).toList();
      double avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;
      double max(List<double> v) => v.reduce(math.max);
      String f1(double v) => v.toStringAsFixed(1);
      final slow = span.where((v) => v > 16.7).length;
      ctrl.c.log.info(
        'compass',
        'swipe ${model.from}->${model.target} '
            '${model.progress > 0.5 ? 'landed' : 'went back'} in ${total}ms, '
            'snapshot ${capture}ms, moving ${motionMs}ms in ${frames.length} '
            'frames (${all.length} in all), '
            'build ${f1(avg(build))}/${f1(max(build))}ms, '
            'raster ${f1(avg(raster))}/${f1(max(raster))}ms, '
            'over 16.7ms $slow',
      );
    });
  }

  /// A fresh snapshot of the view just landed on, for the next swipe that
  /// passes it, once it has settled and only while nobody is touching.
  void _scheduleLandingShot(CompassSlot slot) {
    _landingShot?.cancel();
    _landingShot = Timer(const Duration(milliseconds: 800), () {
      if (!mounted || _down.isNotEmpty || _model != null) return;
      if (ctrl.current.value != slot || !ctrl.swipeReady) return;
      final view = ctrl.currentView;
      final size = MediaQuery.sizeOf(context);
      final ratio = MediaQuery.devicePixelRatioOf(context);
      final width = math.min(size.width * ratio, 1280).round();
      unawaited(
        ctrl.capture(view, width: width).then((image) => image?.dispose()),
      );
    });
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Listener(
          onPointerDown: _onDown,
          onPointerMove: _onMove,
          onPointerUp: _onUp,
          onPointerCancel: _onCancel,
          child: widget.child,
        ),
      );
}

/// The swipe on screen: the snapshots and stand-ins of the views, over
/// everything Compass shows, while a swipe moves. Nothing here takes a
/// touch; the finger keeps talking to whatever it went down on.
class CompassStageView extends StatelessWidget {
  const CompassStageView({super.key, required this.controller});

  final CompassController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<CompassStageModel?>(
        valueListenable: controller.stage,
        builder: (context, model, _) {
          if (model == null) return const SizedBox.shrink();
          final scheme = Theme.of(context).colorScheme;
          final dark = Theme.of(context).brightness == Brightness.dark;
          return Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _StagePainter(
                    model: model,
                    layout: controller.layout,
                    available: controller.available,
                    showPosition: controller.showPosition,
                    colors: _StageColors(
                      ground: dark
                          ? const Color(0xFF060607)
                          : Color.lerp(scheme.surface, Colors.black, 0.42)!,
                      card: scheme.surfaceContainer,
                      ink: scheme.onSurfaceVariant,
                      dot: scheme.outline,
                      here: scheme.secondary,
                      ring: scheme.onSecondaryContainer,
                    ),
                    textDirection: Directionality.of(context),
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          );
        },
      );
}

class _StageColors {
  const _StageColors({
    required this.ground,
    required this.card,
    required this.ink,
    required this.dot,
    required this.here,
    required this.ring,
  });

  final Color ground;
  final Color card;
  final Color ink;
  final Color dot;
  final Color here;
  final Color ring;
}

/// One picture per frame: a few image draws and rounded rectangles, no
/// layers, blurs or shaders, which is what keeps it smooth on an Echo
/// Show 5.
class _StagePainter extends CustomPainter {
  _StagePainter({
    required this.model,
    required this.layout,
    required this.available,
    required this.showPosition,
    required this.colors,
    required this.textDirection,
  }) : super(repaint: model);

  final CompassStageModel model;
  final CompassLayout layout;
  final bool Function(CompassView view) available;
  final bool showPosition;
  final _StageColors colors;
  final TextDirection textDirection;

  static final _labels = Expando<(TextPainter, TextPainter, double)>();

  @override
  void paint(Canvas canvas, Size size) {
    if (!model.ready) return;
    final s = model.scale;
    final gap = model.zoom ? size.shortestSide * 0.035 : 0.0;
    final pitch = Offset(size.width * s + gap, size.height * s + gap);
    // The whole cross slides by the target's place, which is more than one
    // step when a view between could not show.
    final travel = model.travel;
    final base =
        size.center(Offset.zero) -
        Offset(travel.dx * pitch.dx, travel.dy * pitch.dy) * model.progress;
    final alpha = model.opacity.clamp(0.0, 1.0);
    final screen = Offset.zero & size;
    // Under the tiles only while it shows between them. Once a view fills
    // the screen again (at rest, landed or fading out over the live view)
    // it is left out: faded along with the snapshot, it would darken the
    // live view for the length of the fade, a dark flash on every landing.
    final settled =
        s > 0.999 && (model.progress < 0.001 || model.progress > 0.999);
    if (!settled) {
      canvas.drawRect(
        screen,
        Paint()..color = colors.ground.withValues(alpha: alpha),
      );
    }
    final radius = model.zoom
        ? size.shortestSide * 0.04 * ((1 - s) / (1 - _zoomScale)).clamp(0, 1)
        : 0.0;
    final targetKey = layout.viewAt(model.target)?.key;
    for (final tile in model.tiles) {
      final center = base + Offset(tile.dx * pitch.dx, tile.dy * pitch.dy);
      final rect = Rect.fromCenter(
        center: center,
        width: size.width * s,
        height: size.height * s,
      );
      if (!rect.overlaps(screen)) continue;
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      final image = tile.image;
      if (image != null) {
        if (radius > 0.5) {
          canvas.save();
          canvas.clipRRect(rrect);
        }
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          rect,
          Paint()
            ..filterQuality = FilterQuality.low
            ..color = Color.fromRGBO(0, 0, 0, alpha),
        );
        if (radius > 0.5) canvas.restore();
      } else {
        _placeholder(canvas, tile, rrect, alpha);
      }
      // The views around dim a little, so the one in hand reads first.
      final isHere = tile.dx == 0 && tile.dy == 0;
      final isTarget = tile.view.key == targetKey && !isHere;
      final dim = isHere
          ? 0.28 * model.progress
          : isTarget
          ? 0.28 * (1 - model.progress)
          : 0.28;
      if (dim > 0.01 && model.zoom) {
        canvas.drawRRect(
          rrect,
          Paint()..color = Colors.black.withValues(alpha: dim * alpha),
        );
      }
    }
    if (showPosition && alpha > 0.5) _position(canvas, size, alpha);
  }

  /// A view never seen yet: its glyph and name on a card, until a visit
  /// leaves a snapshot behind.
  void _placeholder(Canvas canvas, CompassTile tile, RRect rrect, double a) {
    canvas.drawRRect(rrect, Paint()..color = colors.card.withValues(alpha: a));
    final rect = rrect.outerRect;
    final cached = _labels[tile];
    final unit = rect.shortestSide;
    final TextPainter icon;
    final TextPainter label;
    if (cached != null && (cached.$3 - unit).abs() < 1) {
      icon = cached.$1;
      label = cached.$2;
    } else {
      icon = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(tile.icon.codePoint),
          style: TextStyle(
            fontFamily: tile.icon.fontFamily,
            package: tile.icon.fontPackage,
            fontSize: unit * 0.16,
            color: colors.ink,
          ),
        ),
        textDirection: textDirection,
      )..layout();
      label = TextPainter(
        text: TextSpan(
          text: tile.label,
          style: TextStyle(
            fontSize: unit * 0.055,
            fontWeight: FontWeight.w600,
            color: colors.ink,
          ),
        ),
        textDirection: textDirection,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: rect.width * 0.8);
      _labels[tile] = (icon, label, unit);
    }
    final total = icon.height + unit * 0.03 + label.height;
    final top = rect.center.dy - total / 2;
    // The glyph and name leave as the stage starts to fade, rather than
    // fading through a layer of their own.
    if (a < 0.99) return;
    icon.paint(canvas, Offset(rect.center.dx - icon.width / 2, top));
    label.paint(
      canvas,
      Offset(rect.center.dx - label.width / 2, top + icon.height + unit * 0.03),
    );
  }

  /// The little map in the corner: a dot per view that can show, the one
  /// in hand marked.
  void _position(Canvas canvas, Size size, double a) {
    final slots = [
      for (final slot in layout.slots)
        if (layout.viewAt(slot) case final view? when available(view)) slot,
    ];
    if (slots.length < 2) return;
    final xs = slots.map((s) => s.grid.x);
    final ys = slots.map((s) => s.grid.y);
    final minX = xs.reduce(math.min), maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min), maxY = ys.reduce(math.max);
    final unit = (size.shortestSide * 0.014).clamp(5.0, 9.0);
    final step = unit * 1.7;
    final pad = unit * 1.3;
    final w = (maxX - minX) * step + unit + pad * 2;
    final h = (maxY - minY) * step + unit + pad * 2;
    final inset = size.shortestSide * 0.03;
    final box = Rect.fromLTWH(size.width - inset - w, inset, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(pad + unit / 2)),
      Paint()..color = Colors.black.withValues(alpha: 0.55 * a),
    );
    final here = model.progress < 0.5 ? model.from : model.target;
    for (final slot in slots) {
      final c = Offset(
        box.left + pad + unit / 2 + (slot.grid.x - minX) * step,
        box.top + pad + unit / 2 + (slot.grid.y - minY) * step,
      );
      final on = slot == here;
      canvas.drawCircle(
        c,
        unit / 2,
        Paint()..color = (on ? colors.here : colors.dot).withValues(alpha: a),
      );
      if (on) {
        canvas.drawCircle(
          c,
          unit / 2 + 1.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = colors.ring.withValues(alpha: a),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StagePainter old) =>
      old.model != model || old.colors.ground != colors.ground;
}
