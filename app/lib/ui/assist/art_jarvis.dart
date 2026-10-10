import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'assist_art.dart';

/// The Jarvis skin's indicator: a holographic HUD reactor. Rings of
/// segmented arcs, dashes and dial ticks turn at their own speeds around a
/// glowing core, a ring of blocks pushes out with the voice, and a scanner
/// sweeps it while the assistant thinks. Every ring is a path built once
/// in a 1000 unit artboard and drawn rotated, so a frame costs a couple of
/// dozen draws and no blur.
class JarvisArt extends StatefulWidget {
  const JarvisArt({
    super.key,
    required this.mode,
    required this.reactive,
    required this.level,
    required this.clock,
    this.compact = false,
    this.countdown,
    this.inset = EdgeInsets.zero,
  });

  final ArtMode mode;

  /// Listening or speaking with the reactive bar on: the blocks and the
  /// core follow [level]. Otherwise they run the mode's own animation.
  final bool reactive;
  final ValueListenable<double> level;
  final ArtClock clock;

  /// Docked beside the conversation's text: only the rings that still
  /// read at that size, drawn thicker.
  final bool compact;

  /// 1 down to 0 as a docked conversation ends: the outer ring unwinds
  /// with it.
  final ValueListenable<double>? countdown;

  /// Full screen, the room a result panel takes beside the chat: the
  /// reactor centers over the chat's column instead.
  final EdgeInsets inset;

  @override
  State<JarvisArt> createState() => _JarvisArtState();
}

class _JarvisArtState extends State<JarvisArt> {
  /// Each block's reach as drawn (0 at rest, 1 at full), eased toward its
  /// target every frame so a change of mode glides instead of jumping.
  final _reach = List<double>.filled(_JarvisPainter.blocks, 0);

  /// The rings' angles, stepped by their speeds: a speed change then
  /// speeds a ring up rather than jumping it.
  final _angles = List<double>.filled(6, 0);
  double _speed = 1;
  double _glow = 0.6;
  double _scan = 0;
  double _bright = 0.7;
  double _last = -1;

  /// The loudest recent level while listening and while speaking, each
  /// decaying, as the Voice Only mark scales them.
  double _micPeak = 0;
  double _playPeak = 0;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(size: Size.infinite, painter: _JarvisPainter(this)),
  );
}

const _cyan = Color(0xFF4EE6F0);
const _cyanBright = Color(0xFFA6F8FF);
const _teal = Color(0xFF0F5560);
const _tealDeep = Color(0xFF0A3A44);

class _JarvisPainter extends CustomPainter {
  _JarvisPainter(this.state)
    : super(
        repaint: Listenable.merge([
          state.widget.level,
          state.widget.clock,
          state.widget.countdown,
        ]),
      );

  final _JarvisArtState state;
  JarvisArt get w => state.widget;

  static const blocks = 12;

  /// The blocks' ring: from its inner edge out by its rest depth, and how
  /// much further a loud voice pushes it.
  static const _blockInner = 600.0;
  static const _blockRest = 90.0;
  static const _blockSpan = 280.0;
  static const _blockSweep = 20.0;
  static const _blockOuter = _blockInner + _blockRest + _blockSpan;

  /// Each block's own wobble (Hz and phase), so a voice moves them as an
  /// equalizer rather than in step.
  static const _rates = [
    2.3,
    3.1,
    1.7,
    2.7,
    3.5,
    1.9,
    2.9,
    2.1,
    3.3,
    1.6,
    2.5,
    3.0,
  ];

  /// Ring speeds in radians a second, as the GIFs turn them: the segmented
  /// rings one way, the dashes and the data band the other.
  static const _speeds = [0.35, -0.22, 0.12, -0.08, 0.05, -0.5];

  static Paint _stroke(Color color, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = color;

  static Rect _circle(double r) =>
      Rect.fromCircle(center: Offset.zero, radius: r);

  static double _rad(double degrees) => degrees * math.pi / 180;

  static Path _arcs(double r, List<(double, double)> spans) {
    final path = Path();
    for (final (start, sweep) in spans) {
      path.addArc(_circle(r), _rad(start), _rad(sweep));
    }
    return path;
  }

  /// Even dashes around a ring: [n] of them, each [fill] of its slot.
  static Path _dashes(double r, int n, double fill) =>
      _arcs(r, [for (var i = 0; i < n; i++) (360 / n * i, 360 / n * fill)]);

  /// The dial: a tick every 3 degrees, every tenth one longer.
  static final _ticks = () {
    final path = Path();
    for (var i = 0; i < 120; i++) {
      final a = _rad(i * 3.0);
      final (inner, outer) = i % 10 == 0 ? (360.0, 408.0) : (380.0, 400.0);
      path
        ..moveTo(inner * math.cos(a), inner * math.sin(a))
        ..lineTo(outer * math.cos(a), outer * math.sin(a));
    }
    return path;
  }();

  /// The data band: short arcs scattered between the dial and the blocks,
  /// the GIFs' circuitry, from a fixed seed so it never reshuffles.
  static final _band = () {
    final random = math.Random(937);
    final thin = Path();
    final thick = Path();
    final lit = Path();
    for (var i = 0; i < 220; i++) {
      final r = 430 + random.nextDouble() * 140;
      final start = random.nextDouble() * 360;
      final sweep = 1.5 + random.nextDouble() * 10;
      final pick = random.nextDouble();
      (pick < 0.55
              ? thin
              : pick < 0.9
              ? thick
              : lit)
          .addArc(_circle(r), _rad(start), _rad(sweep));
    }
    return (thin, thick, lit);
  }();

  static final _innerSegments = _arcs(300, [
    for (var i = 0; i < 6; i++) (i * 60.0, 46.0),
  ]);
  static final _midArcs = _arcs(575, const [
    (10, 110),
    (150, 70),
    (250, 40),
    (305, 25),
  ]);
  static final _dashRing = _dashes(800, 72, 0.5);
  static final _dotRing = _dashes(985, 180, 0.25);
  static final _outerArcs = _arcs(940, const [(200, 64), (20, 38), (95, 12)]);
  static final _spokes = () {
    final path = Path();
    for (final degrees in const <double>[-28, 64, 152, 197, 242, 331]) {
      final a = _rad(degrees);
      path
        ..moveTo(330 * math.cos(a), 330 * math.sin(a))
        ..lineTo(1060 * math.cos(a), 1060 * math.sin(a));
    }
    return path;
  }();

  /// The level against its source's recent peak: a peak decays to half in
  /// about two seconds, and the gain stops at 4x so room noise stays low.
  double _scaled(double dt) {
    final l = w.level.value.clamp(0.0, 1.0);
    final decay = math.exp(-0.35 * dt);
    final speaking = w.mode == ArtMode.speaking;
    final peak = math.max(
      l,
      (speaking ? state._playPeak : state._micPeak) * decay,
    );
    if (speaking) {
      state._playPeak = peak;
    } else {
      state._micPeak = peak;
    }
    return (l * math.min(4.0, 0.9 / math.max(peak, 0.1))).clamp(0.0, 1.0);
  }

  double _blockTarget(int i, double t, double l) {
    final angle = 2 * math.pi * i / blocks;
    switch (w.mode) {
      case ArtMode.idle:
        return 0;
      case ArtMode.thinking:
        // A highlight chasing around the ring.
        final c = math.max(0.0, math.cos(angle - 5 * t));
        return 0.1 + 0.55 * math.pow(c, 6);
      case ArtMode.listening || ArtMode.speaking when w.reactive:
        final wobble =
            0.6 + 0.4 * math.sin(2 * math.pi * _rates[i] * t + i * 1.7);
        final breath = 0.05 * (1 + math.sin(2 * math.pi * t / 2.4 + i * 0.5));
        return (breath + l * wobble * 1.25).clamp(0.0, 1.0);
      case ArtMode.speaking:
        return 0.15 +
            0.45 *
                (0.5 +
                    0.5 * math.sin(2 * math.pi * _rates[i] / 2 * t + i * 1.7));
      case ArtMode.listening:
        return 0.08 + 0.06 * math.sin(2 * math.pi * t / 2.4 + i * 0.5);
    }
  }

  void _step(double t, double dt, double l) {
    final ease = 1 - math.exp(-14 * dt);
    final (speed, glow, scan, bright) = switch (w.mode) {
      ArtMode.idle => (0.35, 0.45, 0.0, 0.6),
      ArtMode.thinking => (
        4.0,
        0.7 + 0.25 * math.sin(2 * math.pi * t / 0.6),
        1.0,
        1.0,
      ),
      ArtMode.speaking => (
        1.4,
        w.reactive ? 0.75 + 0.5 * l : 0.8 + 0.15 * math.sin(2 * math.pi * t),
        0.0,
        1.0,
      ),
      ArtMode.listening => (
        1.0,
        w.reactive
            ? 0.65 + 0.55 * l
            : 0.65 + 0.1 * math.sin(2 * math.pi * t / 2.4),
        0.0,
        1.0,
      ),
    };
    state._speed += (speed - state._speed) * (1 - math.exp(-3 * dt));
    state._glow += (glow - state._glow) * ease;
    state._scan += (scan - state._scan) * (1 - math.exp(-6 * dt));
    state._bright += (bright - state._bright) * (1 - math.exp(-4 * dt));
    for (var i = 0; i < state._angles.length; i++) {
      state._angles[i] += _speeds[i] * state._speed * dt;
    }
    final reach = state._reach;
    final follow = 1 - math.exp(-18 * dt);
    for (var i = 0; i < blocks; i++) {
      reach[i] += (_blockTarget(i, t, l) - reach[i]) * follow;
    }
  }

  void _rotated(Canvas canvas, double angle, void Function() draw) {
    canvas.save();
    canvas.rotate(angle);
    draw();
    canvas.restore();
  }

  /// A bright line with a wider faint copy under it: a glow without a blur.
  void _lit(Canvas canvas, Path path, double width, double alpha) {
    canvas.drawPath(
      path,
      _stroke(_cyan.withValues(alpha: 0.16 * alpha), width * 3),
    );
    canvas.drawPath(path, _stroke(_cyan.withValues(alpha: alpha), width));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final watch = Stopwatch()..start();
    final t = w.clock.seconds;
    final dt = state._last < 0 ? 0.0 : (t - state._last).clamp(0.0, 0.1);
    state._last = t;
    final l = w.reactive ? _scaled(dt) : 0.0;
    _step(t, dt, l);
    final compact = w.compact;
    // Full screen, it sits high, clear of the chat under it.
    final reach = compact ? 1000.0 : 1080.0;
    final area = w.inset.deflateRect(Offset.zero & size);
    final radius = math.min(area.width, size.height) / 2;
    final scale = (compact ? radius : radius * 0.66) / reach;
    if (scale <= 0) return;
    final center = compact
        ? size.center(Offset.zero)
        : Offset(area.center.dx, size.height * 0.38);
    final a = state._bright;
    // Thicker in the bubble, where a hairline would vanish.
    final k = compact ? 2.6 : 1.0;
    final angles = state._angles;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    // The halo: the dark blue light the core throws over the rings.
    canvas.drawCircle(
      Offset.zero,
      700,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          700,
          [
            const Color(0xFF1A6E86).withValues(alpha: 0.55 * a),
            const Color(0xFF0B3646).withValues(alpha: 0.3 * a),
            const Color(0x00000000),
          ],
          const [0, 0.5, 1],
        ),
    );

    if (!compact) {
      canvas.drawPath(_spokes, _stroke(_cyan.withValues(alpha: 0.35 * a), 2));
      final (thin, thick, lit) = _band;
      _rotated(canvas, angles[3], () {
        canvas.drawPath(thin, _stroke(_cyan.withValues(alpha: 0.35 * a), 4));
        canvas.drawPath(thick, _stroke(_teal.withValues(alpha: a), 14));
        canvas.drawPath(lit, _stroke(_cyan.withValues(alpha: 0.9 * a), 6));
      });
      _rotated(canvas, angles[2], () {
        canvas.drawPath(_ticks, _stroke(_cyan.withValues(alpha: 0.55 * a), 3));
      });
      _rotated(canvas, angles[1], () {
        canvas.drawPath(
          _dashRing,
          _stroke(_cyan.withValues(alpha: 0.5 * a), 5),
        );
      });
      _rotated(canvas, angles[4], () {
        canvas.drawPath(
          _dotRing,
          _stroke(_cyan.withValues(alpha: 0.45 * a), 4),
        );
        _lit(canvas, _outerArcs, 18, 0.85 * a);
      });
      canvas.drawCircle(
        Offset.zero,
        940,
        _stroke(_cyan.withValues(alpha: 0.25 * a), 3),
      );
    }

    // The blocks, each a thick arc from the ring's inner edge out, with a
    // lit rim that rides its outer edge.
    // Dark at the ring's inner edge, lit toward the reach of a loud voice.
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..shader = ui.Gradient.radial(
        Offset.zero,
        _blockOuter,
        [
          _tealDeep.withValues(alpha: 0.7 * a),
          _tealDeep.withValues(alpha: 0.7 * a),
          _teal.withValues(alpha: 0.9 * a),
          const Color(0xFF1C8C99).withValues(alpha: a),
        ],
        [
          0,
          _blockInner / _blockOuter,
          (_blockInner + _blockRest) / _blockOuter,
          1,
        ],
      );
    _rotated(canvas, angles[4] * 2, () {
      final sweep = _rad(_blockSweep);
      for (var i = 0; i < blocks; i++) {
        final depth = _blockRest + _blockSpan * state._reach[i];
        final start = _rad(360.0 / blocks * i) - sweep / 2;
        final mid = _blockInner + depth / 2;
        canvas.drawArc(
          _circle(mid),
          start,
          sweep,
          false,
          fill..strokeWidth = depth,
        );
        canvas.drawArc(
          _circle(_blockInner + depth),
          start,
          sweep,
          false,
          _stroke(
            _cyan.withValues(alpha: (0.6 + 0.4 * state._reach[i]) * a),
            8 * k,
          ),
        );
      }
    });

    _rotated(canvas, angles[0], () => _lit(canvas, _midArcs, 9 * k, 0.9 * a));
    _rotated(canvas, angles[5], () {
      _lit(canvas, _innerSegments, 26 * k, 0.95 * a);
    });

    // The scanner: a bright edge leading a fading wedge, while thinking.
    if (state._scan > 0.01) {
      canvas.save();
      canvas.rotate(t * 3);
      canvas.drawCircle(
        Offset.zero,
        compact ? 1000 : 880,
        Paint()
          ..shader = SweepGradient(
            colors: [
              const Color(0x00000000),
              const Color(0x00000000),
              _cyan.withValues(alpha: 0.32 * state._scan),
            ],
            stops: const [0, 0.75, 1],
          ).createShader(_circle(1000)),
      );
      canvas.restore();
    }

    // The core's rings, and its light.
    for (final (r, width) in const [(150.0, 7.0), (178.0, 3.0), (210.0, 9.0)]) {
      _lit(canvas, Path()..addOval(_circle(r)), width * k, 0.9 * a);
    }
    final glow = state._glow.clamp(0.0, 1.4);
    canvas.drawCircle(
      Offset.zero,
      460,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          460,
          [
            _cyan.withValues(alpha: 0.4 * math.min(1, glow)),
            const Color(0x00000000),
          ],
          const [0, 1],
        ),
    );
    final core = 230 * (0.85 + 0.3 * glow);
    canvas.drawCircle(
      Offset.zero,
      core,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          core,
          [
            Colors.white.withValues(alpha: math.min(1, glow)),
            _cyanBright.withValues(alpha: 0.85 * math.min(1, glow)),
            _cyan.withValues(alpha: 0.3 * glow),
            const Color(0x00000000),
          ],
          const [0, 0.18, 0.5, 1],
        ),
    );
    if (!compact) {
      // The lens flare across it.
      canvas.save();
      canvas.scale(1, 0.035);
      canvas.drawCircle(
        Offset.zero,
        520 * (0.8 + 0.4 * glow),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            520 * (0.8 + 0.4 * glow),
            [
              Colors.white.withValues(alpha: 0.75 * math.min(1, glow)),
              _cyan.withValues(alpha: 0.3 * glow),
              const Color(0x00000000),
            ],
            const [0, 0.35, 1],
          ),
      );
      canvas.restore();
    }

    // Docked, the outer ring unwinds as the conversation ends.
    final countdown = w.countdown;
    if (countdown != null) {
      final left = countdown.value.clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset.zero,
        1000,
        _stroke(_cyan.withValues(alpha: 0.2 * a), 30),
      );
      if (left > 0) {
        canvas.drawArc(
          _circle(1000),
          -math.pi / 2,
          2 * math.pi * left,
          false,
          _stroke(_cyan.withValues(alpha: a), 30)..strokeCap = StrokeCap.round,
        );
      }
    }
    canvas.restore();
    ArtCost.paint(watch);
  }

  @override
  bool shouldRepaint(_JarvisPainter old) => true;
}
