import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'assist_art.dart';

/// The Jarvis skin's indicator: a holographic HUD reactor. Rings of
/// segmented arcs, dashes and dial ticks turn at their own speeds around a
/// glowing core, a ring of blocks pushes out with the voice, and a scanner
/// sweeps it while the assistant thinks. Every ring is a path built once
/// in a 1000 unit artboard and drawn rotated, and the blocks' circuit
/// texture is an image drawn once, so a frame costs a couple of dozen draws
/// and no blur.
class JarvisArt extends StatefulWidget {
  const JarvisArt({
    super.key,
    required this.mode,
    required this.reactive,
    required this.level,
    required this.clock,
    this.compact = false,
    this.countdown,
    this.box,
  });

  final ArtMode mode;

  /// Listening or speaking with the reactive bar on: the blocks and the
  /// core follow [level]. Otherwise they run the mode's own animation.
  final bool reactive;
  final ValueListenable<double> level;
  final ArtClock clock;

  /// Docked over the conversation's bubble: the reactor fills its box,
  /// without the spokes and the lens flare that reach past it.
  final bool compact;

  /// 1 down to 0 as a docked conversation ends: the outer ring unwinds
  /// with it.
  final ValueListenable<double>? countdown;

  /// Full screen, where the reactor goes, out to the blocks' full stretch
  /// ([jarvisReactor]). Null fills the widget.
  final Rect? box;

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

  /// The blocks' circuit texture, drawn at [px] square.
  ui.Image? _texture;
  ui.Image texture(int px) {
    if (_texture?.width != px) {
      _texture?.dispose();
      _texture = _JarvisPainter.bake(px);
    }
    return _texture!;
  }

  @override
  void dispose() {
    _texture?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(size: Size.infinite, painter: _JarvisPainter(this)),
  );
}

/// How far the blocks reach at full stretch, past the outer ring.
const jarvisReach = 1.1;

/// The full screen reactor's square, out to the blocks' full stretch,
/// centered over the chat's column (the screen less [inset]). It sits at
/// the top and leaves [chat] under it, so the text never crosses the
/// reactor, even with the blocks pushed all the way out. With no chat it
/// takes the whole screen, centered.
Rect jarvisReactor(Size size, EdgeInsets inset, {double chat = 0}) {
  final area = inset.deflateRect(Offset.zero & size);
  if (chat <= 0) {
    final side = math.max(0.0, math.min(area.width, size.height) * 0.92);
    return Rect.fromCenter(
      center: Offset(area.center.dx, size.height / 2),
      width: side,
      height: side,
    );
  }
  final wanted = math.min(area.width * 0.9, size.height * 0.56);
  final fits = size.height - 24 - 16 - chat;
  final side = math.max(
    0.0,
    math.max(math.min(area.width, size.height) * 0.3, math.min(wanted, fits)),
  );
  return Rect.fromCenter(
    center: Offset(area.center.dx, 24 + side / 2),
    width: side,
    height: side,
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
  static const _blockRest = 140.0;
  static const _blockSpan = 1000 * jarvisReach - _blockInner - _blockRest;

  /// The texture's reach, past the blocks' tips and their rims.
  static const _textureReach = 1300.0;
  static const _blockSweep = 20.0;

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

  /// The thin rings over the blocks, the GIFs' many concentric lines.
  static final _circles = () {
    final path = Path();
    for (final r in const <double>[625, 660, 705, 750, 860, 900, 1020, 1065]) {
      path.addOval(_circle(r));
    }
    return path;
  }();

  /// Lit arcs on some of those rings, turning against the blocks.
  static final _ringArcs = () {
    final random = math.Random(1937);
    final path = Path();
    for (final r in const <double>[660, 750, 900, 1065]) {
      for (var i = 0; i < 3; i++) {
        path.addArc(
          _circle(r),
          _rad(random.nextDouble() * 360),
          _rad(15 + random.nextDouble() * 50),
        );
      }
    }
    return path;
  }();

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

  /// A regular octagon, flat sides up and down, as the GIFs' core.
  static Path _octagon(double r) => Path()
    ..addPolygon([
      for (var i = 0; i < 8; i++)
        Offset(
          r * math.cos(_rad(22.5 + 45 * i)),
          r * math.sin(_rad(22.5 + 45 * i)),
        ),
    ], true);

  static final _coreRings = [_octagon(150), _octagon(178), _octagon(210)];

  static Offset _polar(double r, double degrees) =>
      Offset(r * math.cos(_rad(degrees)), r * math.sin(_rad(degrees)));

  /// The blocks' motherboard: traces running out with jogs, pads at their
  /// ends, chips and specks, scattered over the blocks' ring from a fixed
  /// seed.
  static final _circuit = () {
    final random = math.Random(9370);
    final traces = Path();
    final pads = Path();
    final chips = Path();
    final specks = Path();
    for (var i = 0; i < 420; i++) {
      var degrees = random.nextDouble() * 360;
      final r0 = 610 + random.nextDouble() * 590;
      var r = math.min(1240.0, r0 + 25 + random.nextDouble() * 90);
      traces
        ..moveTo(_polar(r0, degrees).dx, _polar(r0, degrees).dy)
        ..lineTo(_polar(r, degrees).dx, _polar(r, degrees).dy);
      if (random.nextDouble() < 0.6) {
        final jog = (random.nextDouble() - 0.5) * 8;
        traces.arcTo(_circle(r), _rad(degrees), _rad(jog), false);
        degrees += jog;
        r = math.min(1245.0, r + 20 + random.nextDouble() * 50);
        final end = _polar(r, degrees);
        traces.lineTo(end.dx, end.dy);
      }
      pads.addOval(Rect.fromCircle(center: _polar(r, degrees), radius: 7));
      if (random.nextDouble() < 0.4) {
        pads.addOval(Rect.fromCircle(center: _polar(r0, degrees), radius: 5));
      }
    }
    for (var i = 0; i < 110; i++) {
      final degrees = random.nextDouble() * 360;
      final c = _polar(640 + random.nextDouble() * 560, degrees);
      final out = Offset(math.cos(_rad(degrees)), math.sin(_rad(degrees)));
      final along = Offset(-out.dy, out.dx);
      chips.addPolygon([
        c + out * 10 + along * 17,
        c + out * 10 - along * 17,
        c - out * 10 - along * 17,
        c - out * 10 + along * 17,
      ], true);
    }
    for (var i = 0; i < 800; i++) {
      specks.addOval(
        Rect.fromCircle(
          center: _polar(
            600 + random.nextDouble() * 645,
            random.nextDouble() * 360,
          ),
          radius: 2.5,
        ),
      );
    }
    return (traces, pads, chips, specks);
  }();

  /// The blocks' fill as an image of [px] square out to [_textureReach]:
  /// dark at the ring's inner edge, lit toward the reach of a loud voice,
  /// with the circuit over it. Past a block's rest length it fades, so a
  /// stretched block's tip goes soft and a block at rest stays solid. A block drawn with it shows the texture
  /// under its own shape, so the blocks need no clipping.
  static ui.Image bake(int px) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(px / (2 * _textureReach))
      ..translate(_textureReach, _textureReach);
    const tip = 1000 * jarvisReach;
    canvas.saveLayer(null, Paint());
    canvas.drawCircle(
      Offset.zero,
      _textureReach,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          tip,
          [
            _tealDeep.withValues(alpha: 0.7),
            _tealDeep.withValues(alpha: 0.7),
            _teal.withValues(alpha: 0.9),
            const Color(0xFF1C8C99),
          ],
          [0, _blockInner / tip, (_blockInner + _blockRest) / tip, 1],
        ),
    );
    final rest = _blockInner + _blockRest + 10;
    final (traces, pads, chips, specks) = _circuit;
    canvas
      ..drawPath(specks, Paint()..color = const Color(0x4D7FE9F2))
      ..drawPath(traces, _stroke(const Color(0x8C3FC4D0), 5))
      ..drawPath(chips, Paint()..color = const Color(0xFF06262C))
      ..drawPath(chips, _stroke(const Color(0x993FC4D0), 3))
      ..drawPath(pads, Paint()..color = const Color(0xB35BD8E2));
    canvas.drawCircle(
      Offset.zero,
      _textureReach,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.radial(
          Offset.zero,
          tip,
          const [Color(0xFF000000), Color(0xFF000000), Color(0x1F000000)],
          [0, rest / tip, 1],
        ),
    );
    canvas.restore();
    final picture = recorder.endRecording();
    final image = picture.toImageSync(px, px);
    picture.dispose();
    return image;
  }

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
    // The box holds the blocks at full stretch: the outer ring sits well
    // inside it.
    final box = w.box ?? Offset.zero & size;
    final radius = math.min(box.width, box.height) / 2 / jarvisReach;
    if (radius <= 0) return;
    final scale = radius / 1000;
    final center = box.center;
    final a = state._bright;
    // Thicker on a small reactor, where a hairline would vanish.
    final k = (150 / radius).clamp(1.0, 3.0);
    final angles = state._angles;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    // Docked over the dashboard, it sits on a disc of the bubble's dark.
    if (compact) {
      canvas.drawCircle(
        Offset.zero,
        1000 * jarvisReach + 20,
        Paint()..color = const Color(0xF002090E),
      );
    }

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

    // The blocks, each a thick arc from the ring's inner edge out filled
    // with the circuit, with a lit rim that rides its outer edge. The
    // texture turns with them, and the rings cross over them.
    final px = radius * 2 * jarvisReach >= 400 ? 1024 : 512;
    final s = 2 * _textureReach / px;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..color = Color.fromRGBO(0, 0, 0, a)
      ..shader = ImageShader(
        state.texture(px),
        TileMode.clamp,
        TileMode.clamp,
        Float64List.fromList([
          s, 0, 0, 0, //
          0, s, 0, 0,
          0, 0, 1, 0,
          -_textureReach, -_textureReach, 0, 1,
        ]),
        filterQuality: FilterQuality.low,
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
            // The rim softens as the block stretches.
            _cyan.withValues(alpha: (1 - 0.8 * state._reach[i]) * a),
            8 * k,
          ),
        );
      }
    });

    if (!compact) {
      canvas.drawPath(
        _spokes,
        _stroke(_cyan.withValues(alpha: 0.35 * a), 2 * k),
      );
    }
    final (thin, thick, lit) = _band;
    _rotated(canvas, angles[3], () {
      canvas.drawPath(thin, _stroke(_cyan.withValues(alpha: 0.35 * a), 4 * k));
      canvas.drawPath(thick, _stroke(_teal.withValues(alpha: a), 14 * k));
      canvas.drawPath(lit, _stroke(_cyan.withValues(alpha: 0.9 * a), 6 * k));
    });
    _rotated(canvas, angles[2], () {
      canvas.drawPath(
        _ticks,
        _stroke(_cyan.withValues(alpha: 0.55 * a), 3 * k),
      );
    });
    _rotated(canvas, angles[1], () {
      canvas.drawPath(
        _dashRing,
        _stroke(_cyan.withValues(alpha: 0.5 * a), 5 * k),
      );
    });
    _rotated(canvas, angles[4], () {
      canvas.drawPath(
        _dotRing,
        _stroke(_cyan.withValues(alpha: 0.45 * a), 4 * k),
      );
      _lit(canvas, _outerArcs, 18 * k, 0.85 * a);
    });
    canvas.drawCircle(
      Offset.zero,
      940,
      _stroke(_cyan.withValues(alpha: 0.25 * a), 3 * k),
    );
    canvas.drawPath(
      _circles,
      _stroke(_cyan.withValues(alpha: 0.3 * a), 2.5 * k),
    );
    _rotated(canvas, -angles[0] * 0.6, () {
      _lit(canvas, _ringArcs, 5 * k, 0.75 * a);
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

    // The core: octagons, the middle one turning, and its light.
    for (final (i, width) in const [7.0, 3.0, 9.0].indexed) {
      _rotated(
        canvas,
        i == 1 ? angles[2] * 3 : 0,
        () => _lit(canvas, _coreRings[i], width * k, 0.9 * a),
      );
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
    canvas.drawPath(
      _octagon(core),
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
        _stroke(_cyan.withValues(alpha: 0.2 * a), 10 * k),
      );
      if (left > 0) {
        canvas.drawArc(
          _circle(1000),
          -math.pi / 2,
          2 * math.pi * left,
          false,
          _stroke(_cyan.withValues(alpha: a), 10 * k)
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    canvas.restore();
    ArtCost.paint(watch);
  }

  @override
  bool shouldRepaint(_JarvisPainter old) => true;
}
