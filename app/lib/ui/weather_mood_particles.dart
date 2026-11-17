import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'weather_mood_scene.dart';

class _Particle {
  _Particle(double Function() random)
    : x = random(),
      y = random(),
      depth = random(),
      phase = random() * math.pi * 2,
      variation = random(),
      drift = random();
  final double x, y, depth, phase, variation, drift;
}

class _MoteCycle {
  double cycle = double.nan;
  double cellX = 0, cellY = 0, velocityX = 0, velocityY = 0;

  void update(int index, double next) {
    if (cycle == next) return;
    cycle = next;
    final heading = weatherMoodRandom(index * 3.7 + next * 5.3) * math.pi * 2;
    final speed = 1.5 + weatherMoodRandom(index * 8.1 + next * 2.9) * 3;
    cellX = weatherMoodRandom(index * 7.3 + next * 3.1);
    cellY = weatherMoodRandom(index * 5.9 + next * 4.7);
    velocityX = math.cos(heading) * speed;
    velocityY = math.sin(heading) * speed;
  }
}

class _GlassCycle {
  double cycle = double.nan;
  double seed = 0,
      x = 0,
      y = 0,
      radius = 0,
      slideChance = 0,
      slideStart = 0,
      aspect = 0;
  int shape = 0;
  final beadAt = List<double>.filled(4, 0);
  final beadSize = List<double>.filled(4, 0);

  void update(int index, double next, double period, int shapeCount) {
    if (cycle == next) return;
    cycle = next;
    seed = index * 7.13 + next * 13.7;
    x = weatherMoodRandom(seed + 1);
    y = weatherMoodRandom(seed + 2);
    radius = 2.6 + math.pow(weatherMoodRandom(seed + 3), 1.8) * 10.5;
    slideChance = weatherMoodRandom(seed + 4);
    slideStart = 1.2 + weatherMoodRandom(seed + 5) * period * .4;
    shape = (weatherMoodRandom(seed + 6) * shapeCount).floor();
    aspect = .86 + weatherMoodRandom(seed + 7) * .28;
    for (var i = 0; i < 4; i++) {
      beadAt[i] = weatherMoodRandom(seed + 20 + i);
      beadSize[i] = weatherMoodRandom(seed + 30 + i);
    }
  }
}

/// Deterministic fields keep the approved spacing, speeds and depth layers.
class WeatherMoodParticles {
  WeatherMoodParticles() {
    var seed = 9127;
    double random() {
      seed = (seed * 1664525 + 1013904223) & 0xffffffff;
      return seed / 4294967296;
    }

    List<_Particle> field(int count) =>
        List.generate(count, (_) => _Particle(random));
    _rain = field(620);
    _snow = field(180);
    _motes = field(32);
    _nearRain = field(30);
    _nearSnow = field(24);
    _rain.addAll(field(650));
    _nearRain.addAll(field(24));
    _hail = field(240);
    _wind = field(80);
    _nearHail = field(32);
    _stars = field(700);
    _glass = field(140);
    _moteCycles = List.generate(_motes.length, (_) => _MoteCycle());
    _glassCycles = List.generate(_glass.length, (_) => _GlassCycle());
  }
  late final List<_Particle> _rain,
      _snow,
      _motes,
      _nearRain,
      _nearSnow,
      _hail,
      _wind,
      _nearHail;
  late final List<_Particle> _stars, _glass;
  late final List<_MoteCycle> _moteCycles;
  late final List<_GlassCycle> _glassCycles;
  Float32List _starTransforms = Float32List(0), _starRects = Float32List(0);
  Int32List _starColors = Int32List(0);
  Int32List _starRgb = Int32List(0);
  Float64List _starCenters = Float64List(0);
  ui.Size _starGeometrySize = ui.Size.zero;
  final _starPaint = ui.Paint()..filterQuality = ui.FilterQuality.low;
  Float32List _rainPositions = Float32List(0),
      _rainTextureCoordinates = Float32List(0);
  Int32List _rainColors = Int32List(0);
  Uint16List _rainIndices = Uint16List(0);
  ui.ImageShader? _rainShader;
  final _rainPaint = ui.Paint()..filterQuality = ui.FilterQuality.low;
  final _stroke = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round;
  final _sprites = <ui.Image>[];
  // Snow, hail, close rain and drops on the glass share one texture, so each
  // frame draws all of them in a single call.
  ui.Image? _atlas;
  ui.ImageShader? _atlasShader;
  final _atlasPaint = ui.Paint()..filterQuality = ui.FilterQuality.low;
  final _batch = _SpriteBatch();

  int _boltId = -1;
  double _boltWidth = 0;
  List<ui.Path> _bolts = [];

  Future<void> load() async {
    const colors = [
      [
        ui.Color(0xFFF8FBFF),
        ui.Color(0xD9F0F6FF),
        ui.Color(0x66E6F0FF),
        ui.Color(0x00E6F0FF),
      ],
      [
        ui.Color(0xCCECF5FF),
        ui.Color(0xADECF5FF),
        ui.Color(0x4DE1EEFA),
        ui.Color(0x00E1EEFA),
      ],
      [
        ui.Color(0xFFFFFFFF),
        ui.Color(0xF0FBFCFD),
        ui.Color(0xB8E6EBF0),
        ui.Color(0x00EEF1F5),
      ],
      [
        ui.Color(0xF2FFFFFF),
        ui.Color(0xB8FFFFFF),
        ui.Color(0x42F8FAFC),
        ui.Color(0x00F8FAFC),
      ],
    ];
    const stops = [
      [0.0, .28, .6, 1.0],
      [0.0, .25, .55, 1.0],
      [0.0, .55, .8, 1.0],
      [0.0, .3, .65, 1.0],
    ];
    for (var i = 0; i < 4; i++) {
      final recorder = ui.PictureRecorder();
      final target = ui.Canvas(recorder);
      target.drawRect(
        const ui.Rect.fromLTWH(0, 0, 96, 96),
        ui.Paint()
          ..shader = ui.Gradient.radial(
            const ui.Offset(48, 48),
            48,
            colors[i],
            stops[i],
          ),
      );
      final picture = recorder.endRecording();
      try {
        _sprites.add(await picture.toImage(96, 96));
      } finally {
        picture.dispose();
      }
    }

    final drop = await _pixels(64, 64, (u, v) => _glassDrop(0, u, v));
    final shapes = [
      for (var i = 0; i < _dropShapes.length; i++)
        await _pixels(64, 64, (u, v) => _glassDrop(i, u, v)),
    ];
    final trail = await _pixels(24, 96, _glassTrail);
    // A plain Gaussian with no core, for motes seen out of focus.
    final mote = await _pixels(64, 64, (u, v) {
      final x = (u - .5) * 2, y = (v - .5) * 2;
      final a = math.exp(-(x * x + y * y) / (2 * .3 * .3));
      return [a, a, a, a];
    });
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    for (var i = 0; i < 4; i++) {
      canvas.drawImage(_sprites[i], ui.Offset(i * 96.0, 0), ui.Paint());
    }
    canvas.drawImage(drop, _dropCell.topLeft, ui.Paint());
    canvas.drawImage(trail, _trailCell.topLeft, ui.Paint());
    for (var i = 0; i < shapes.length; i++) {
      canvas.drawImage(shapes[i], _shapeCell(i).topLeft, ui.Paint());
      shapes[i].dispose();
    }
    canvas.drawImage(mote, _moteCell.topLeft, ui.Paint());
    drop.dispose();
    trail.dispose();
    mote.dispose();
    final atlasPicture = recorder.endRecording();
    try {
      _atlas = await atlasPicture.toImage(512, 164);
    } finally {
      atlasPicture.dispose();
    }
    _atlasShader = ui.ImageShader(
      _atlas!,
      ui.TileMode.clamp,
      ui.TileMode.clamp,
      Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
      filterQuality: ui.FilterQuality.low,
    );
    _atlasPaint.shader = _atlasShader;
    await _loadRain();
  }

  static const _dropCell = ui.Rect.fromLTWH(388, 0, 64, 64);
  static const _trailCell = ui.Rect.fromLTWH(460, 0, 24, 96);
  static const _moteCell = ui.Rect.fromLTWH(416, 100, 64, 64);
  static ui.Rect _shapeCell(int i) =>
      ui.Rect.fromLTWH(4 + i * 68.0, 100, 64, 64);

  /// Soft lobes (center x, center y, radius x, radius y) that merge into
  /// the outline of each drop shape, in a box from -1 to 1.
  static const _dropShapes = <List<List<double>>>[
    [
      [0, 0, .9, .9],
    ],
    [
      [0, .06, .94, .74],
    ],
    // Fuller at the bottom where water gathers, narrowing toward the top.
    [
      [0, .14, .76, .8],
      [0, -.3, .46, .5],
    ],
    // Two drops that just ran together.
    [
      [-.24, .06, .66, .68],
      [.42, .16, .46, .48],
    ],
    [
      [.04, 0, .7, .92],
    ],
    [
      [-.1, .08, .8, .76],
      [.46, -.34, .3, .32],
    ],
  ];

  static Future<ui.Image> _pixels(
    int width,
    int height,
    List<double> Function(double u, double v) shade,
  ) {
    final pixels = Uint8List(width * height * 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final color = shade((x + .5) / width, (y + .5) / height);
        final i = (y * width + x) * 4;
        for (var c = 0; c < 4; c++) {
          pixels[i + c] = (color[c].clamp(0.0, 1.0) * 255).round();
        }
      }
    }
    final result = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      result.complete,
    );
    return result.future;
  }

  /// A water bead seen against the sky, as premultiplied RGBA: a darker rim
  /// that is strongest along the top, light gathered in the lower half and a
  /// bright highlight. The sprite is white, so the scene can tint the light.
  /// Shape [shape] merges the lobes of [_dropShapes] with a slightly uneven
  /// outline, and its shading follows the merged surface.
  static List<double> _glassDrop(int shape, double u, double v) {
    final lobes = _dropShapes[shape];
    // Dome height at a point: 1 at a lobe's center, 0 on the outline. Lobes
    // join smoothly so merged drops read as one surface.
    double height(double x, double y) {
      var sum = 0.0;
      for (var i = 0; i < lobes.length; i++) {
        final l = lobes[i];
        final dx = (x - l[0]) / l[2], dy = (y - l[1]) / l[3];
        final angle = math.atan2(dy, dx);
        final wobble =
            1 +
            (shape == 0 ? .015 : .05) * math.sin(3 * angle + shape * 1.7 + i) +
            (shape == 0 ? .01 : .03) * math.sin(5 * angle + shape * 2.9);
        final rho = math.sqrt(dx * dx + dy * dy) / wobble;
        sum += math.exp(8 * (1 - rho * rho));
      }
      return math.log(sum) / 8;
    }

    final x = (u - .5) * 2, y = (v - .5) * 2;
    // Supersample the outline so every shape keeps a clean edge.
    var inside = 0;
    for (var sy = 0; sy < 4; sy++) {
      for (var sx = 0; sx < 4; sx++) {
        if (height(x + (sx - 1.5) / 128, y + (sy - 1.5) / 128) > 0) inside++;
      }
    }
    if (inside == 0) return const [0, 0, 0, 0];
    final edge = inside / 16;
    final r = math.sqrt(1 - height(x, y).clamp(0.0, 1.0));
    double smooth(double a, double b, double t) {
      final k = ((t - a) / (b - a)).clamp(0.0, 1.0);
      return k * k * (3 - 2 * k);
    }

    final main = lobes.first;
    double spot(double cx, double cy, double size) {
      final dx = x - (main[0] + cx * main[2]),
          dy = y - (main[1] + cy * main[3]);
      final scale = math.min(main[2], main[3]);
      return math.exp(-(dx * dx + dy * dy) / (2 * size * size * scale * scale));
    }

    final rim = smooth(.5, 1, r) * (.46 - .26 * smooth(-1, 1, y));
    final glow = smooth(.15, .85, y) * smooth(1, .62, r) * .38;
    final light =
        (.06 + glow + spot(-.36, -.44, .14) * .95 + spot(.3, .6, .1) * .3)
            .clamp(0.0, 1.0);
    final alpha = (light + rim * (1 - light)) * edge;
    return [light * edge, light * edge, light * edge, alpha];
  }

  /// The wet path a sliding drop leaves: a faint light core between darker
  /// edges that fades out toward the top, where the drop started.
  static List<double> _glassTrail(double u, double v) {
    final x = (u - .5) * 2;
    final across = 1 - x.abs();
    if (across <= 0) return const [0, 0, 0, 0];
    final along = v * v * (3 - 2 * v);
    final light = math.exp(-x * x / .08) * .16 * along;
    final dark =
        math.exp(-(x.abs() - .62) * (x.abs() - .62) / .03) * .2 * along;
    final edge = math.min(1.0, across * 6);
    final alpha = (light + dark * (1 - light)) * edge;
    return [light * edge, light * edge, light * edge, alpha];
  }

  Future<void> _loadRain() async {
    // A shared streak texture lets all distant rain use one draw call.
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const rect = ui.Rect.fromLTWH(0, 0, 32, 128);
    canvas.drawRect(
      rect,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset.zero,
          const ui.Offset(0, 128),
          const [
            ui.Color(0x00C0D4E3),
            ui.Color(0xB3D3E4F0),
            ui.Color(0xFFE2EEF5),
          ],
          [0, .7, 1],
        ),
    );
    canvas.drawRect(
      rect,
      ui.Paint()
        ..blendMode = ui.BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          ui.Offset.zero,
          const ui.Offset(32, 0),
          const [
            ui.Color(0x00FFFFFF),
            ui.Color(0xFFFFFFFF),
            ui.Color(0xFFFFFFFF),
            ui.Color(0x00FFFFFF),
          ],
          [0, .3, .7, 1],
        ),
    );
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(32, 128);
      _sprites.add(image);
      _rainShader = ui.ImageShader(
        image,
        ui.TileMode.clamp,
        ui.TileMode.clamp,
        Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
        filterQuality: ui.FilterQuality.low,
      );
      _rainPaint.shader = _rainShader;
    } finally {
      picture.dispose();
    }
  }

  void dispose() {
    _atlasPaint.shader = null;
    _atlasShader?.dispose();
    _atlasShader = null;
    _atlas?.dispose();
    _atlas = null;
    _rainPaint.shader = null;
    _rainShader?.dispose();
    _rainShader = null;
    for (final image in _sprites) {
      image.dispose();
    }
    _sprites.clear();
  }

  void _sprite(
    int image,
    double x,
    double y,
    double width,
    double height,
    double angle,
    double opacity,
  ) {
    _batch.add(
      ui.Rect.fromLTWH(image * 96.0, 0, 96, 96),
      x,
      y,
      width,
      height,
      angle,
      ((opacity.clamp(0.0, 1.0) * 255).round() << 24) | 0xFFFFFF,
    );
  }

  /// Batch the small star sprites instead of evaluating random star cells at
  /// every screen pixel. Only the brighter subset twinkles.
  void paintStars(
    ui.Canvas canvas,
    ui.Size size,
    double night,
    double time, {
    double twilight = 0,
  }) {
    if (night < .001 || _sprites.length < 4) return;
    // The moon sits where weather_mood_sky.frag puts the light, and no star
    // shines in front of it.
    final moonX = .84 * size.width,
        moonY = (1 - (.76 + (.28 - .76) * twilight)) * size.height,
        moonClear = .052 * size.height;
    final scale = size.height / 720;
    final count = (440 * size.aspectRatio / (1280 / 720)).round().clamp(
      1,
      _stars.length,
    );
    if (_starColors.length != count || _starGeometrySize != size) {
      _starTransforms = Float32List(count * 4);
      _starRects = Float32List(count * 4);
      _starColors = Int32List(count);
      _starRgb = Int32List(count);
      _starCenters = Float64List(count * 2);
      _starGeometrySize = size;
      for (var i = 0; i < count; i++) {
        final p = _stars[i];
        final radius = (.45 + math.pow(p.depth, 3) * .65) * scale;
        final red = (166 + 89 * p.drift).round(),
            green = (204 + 36 * p.drift).round(),
            blue = (255 - 51 * p.drift).round();
        _starRects[i * 4 + 2] = 96;
        _starRects[i * 4 + 3] = 96;
        _starTransforms[i * 4] = radius / 48;
        _starTransforms[i * 4 + 1] = 0;
        _starTransforms[i * 4 + 2] = p.x * size.width - radius;
        _starTransforms[i * 4 + 3] = p.y * size.height - radius;
        _starRgb[i] = (red << 16) | (green << 8) | blue;
        _starCenters[i * 2] = p.x * size.width;
        _starCenters[i * 2 + 1] = p.y * size.height;
      }
    }
    for (var i = 0; i < count; i++) {
      final p = _stars[i];
      final twinkle = p.depth > .65
          ? .70 + .30 * math.sin(time * (.65 + p.variation * 1.1) + p.phase)
          : 1.0;
      final dx = _starCenters[i * 2] - moonX,
          dy = _starCenters[i * 2 + 1] - moonY;
      final hidden = dx * dx + dy * dy < moonClear * moonClear;
      final alpha = hidden
          ? 0
          : (night * (.5 + p.depth * .85) * twinkle * 255).round().clamp(
              0,
              255,
            );
      _starColors[i] = (alpha << 24) | _starRgb[i];
    }
    canvas.drawRawAtlas(
      _sprites[0],
      _starTransforms,
      _starRects,
      _starColors,
      ui.BlendMode.modulate,
      ui.Offset.zero & size,
      _starPaint,
    );
  }

  void paint(
    ui.Canvas canvas,
    ui.Size size,
    List<double> values,
    double t,
    double windTime,
    WeatherMoodLightning lightning, {
    double twilight = 0,
  }) {
    final scale = size.height / 720, width = size.width / scale;
    const height = 720.0;
    canvas.save();
    canvas.scale(scale);
    _batch.clear();
    _lightning(canvas, width, lightning);
    final windStrength = values[5],
        downpour = values[6],
        rainStrength = values[2],
        snowStrength = values[4],
        hailStrength = values[8];
    final windTravel = windTime * 95;
    final gust = math.sin(t * .17) * .022 + math.sin(t * .39) * .012;
    if (rainStrength > .002) {
      // Lighter falling rain leaves room for the drops on the glass.
      final count = (250 * math.min(1.4, width / 1280) * (1 + downpour * .90))
          .round();
      if (_rainColors.length != count * 4) {
        _rainPositions = Float32List(count * 8);
        _rainTextureCoordinates = Float32List(count * 8);
        _rainColors = Int32List(count * 4);
        _rainIndices = Uint16List(count * 6);
        for (var i = 0; i < count; i++) {
          _rainTextureCoordinates.setRange(i * 8, i * 8 + 8, [
            0,
            0,
            32,
            0,
            0,
            128,
            32,
            128,
          ]);
          final v = i * 4;
          _rainIndices.setRange(i * 6, i * 6 + 6, [
            v,
            v + 1,
            v + 2,
            v + 1,
            v + 3,
            v + 2,
          ]);
        }
      }
      for (var i = 0; i < count; i++) {
        final p = _rain[i];
        final depth = p.depth * p.depth;
        final speed =
            (430 + depth * 880 + p.variation * 110) * (1 + downpour * .18);
        final length =
            (5 + depth * 31 + p.variation * 6) * (1 + downpour * .35);
        final tilt =
            -.12 -
            windStrength * .48 +
            gust * (1 + windStrength * 2) +
            (p.drift - .5) * .035;
        final y = (p.y * (height + 140) + t * speed) % (height + 140) - 70;
        final x =
            (p.x * (width + 300) + y * tilt + t * (5 + depth * 8)) %
                (width + 300) -
            150;
        final opacity =
            (rainStrength *
                    (.16 + depth * .40) *
                    (.65 + p.variation * .35) *
                    (1 + downpour * .22))
                .clamp(0.0, 1.0);
        final halfWidth = (.55 + depth * 1.15) * .7;
        final dx = halfWidth / math.sqrt(1 + tilt * tilt), dy = -tilt * dx;
        final tx = x - tilt * length, ty = y - length;
        final at = i * 8;
        _rainPositions[at] = tx - dx;
        _rainPositions[at + 1] = ty - dy;
        _rainPositions[at + 2] = tx + dx;
        _rainPositions[at + 3] = ty + dy;
        _rainPositions[at + 4] = x - dx;
        _rainPositions[at + 5] = y - dy;
        _rainPositions[at + 6] = x + dx;
        _rainPositions[at + 7] = y + dy;
        final color = ((opacity * 255).round() << 24) | 0xFFFFFF;
        _rainColors.fillRange(i * 4, i * 4 + 4, color);
      }
      if (_rainShader != null) {
        final mesh = ui.Vertices.raw(
          ui.VertexMode.triangles,
          _rainPositions,
          textureCoordinates: _rainTextureCoordinates,
          colors: _rainColors,
          indices: _rainIndices,
        );
        canvas.drawVertices(mesh, ui.BlendMode.modulate, _rainPaint);
        mesh.dispose();
      }
      final countNear =
          (12 * math.min(1.4, width / 1280) * (1 + downpour * .75)).round();
      for (final p in _nearRain.take(countNear)) {
        final length = 65 + p.depth * 95,
            breadth = 7 + p.depth * 12,
            speed = 1050 + p.depth * 950;
        final tilt =
            -.12 -
            windStrength * .48 +
            gust * (1 + windStrength * 2) +
            (p.drift - .5) * .035;
        final y = (p.y * (height + 360) + t * speed) % (height + 360) - 180;
        final x =
            (p.x * (width + 360) + y * tilt + t * 14) % (width + 360) - 180;
        _sprite(
          1,
          x,
          y,
          breadth,
          length,
          -math.atan(tilt),
          rainStrength * (.18 + p.variation * .24) * .65,
        );
      }
    }
    if (snowStrength > .002) {
      for (final p in _snow.take((145 * math.min(1.2, width / 1280)).round())) {
        final radius = .8 + math.pow(p.depth, 2.8) * 4.7,
            speed = 13 + p.depth * 39 + p.variation * 12;
        final y = (p.y * (height + 70) + t * speed) % (height + 70) - 35;
        final flutter =
            math.sin(t * (.30 + p.drift * .5) + p.phase) * (8 + p.depth * 20);
        final sway = math.sin(t * .13 + p.phase) * 17;
        final x =
            (p.x * (width + 110) +
                    t * (4 + p.drift * 8) +
                    flutter +
                    sway -
                    windTravel * (.3 + p.depth)) %
                (width + 110) -
            55;
        _sprite(
          0,
          x,
          y,
          radius * 2,
          radius * 1.6,
          math.sin(t * .5 + p.phase) * .4,
          snowStrength * (.28 + p.depth * .57),
        );
      }
      for (final p in _nearSnow.take(
        (16 * math.min(1.4, width / 1280)).round(),
      )) {
        final radius = 10 + p.depth * 15,
            y =
                (p.y * (height + 150) + t * (110 + p.depth * 110)) %
                    (height + 150) -
                75;
        final flutter =
            math.sin(t * (.22 + p.drift * .25) + p.phase) * (28 + p.depth * 24);
        final x =
            (p.x * (width + 180) +
                    t * (7 + p.drift * 13) +
                    flutter -
                    windTravel * (.8 + p.depth)) %
                (width + 180) -
            90;
        _sprite(
          1,
          x,
          y,
          radius * 2,
          radius * 1.66,
          p.phase + math.sin(t * .25) * .4,
          snowStrength * (.28 + p.variation * .30) * .65,
        );
      }
    }
    if (hailStrength > .002) {
      for (final p in _hail.take((160 * math.min(1.4, width / 1280)).round())) {
        final radius = 1.2 + p.depth * p.depth * 4,
            speed = 640 + p.depth * 1050;
        final y = (p.y * (height + 80) + t * speed) % (height + 80) - 40;
        final x =
            (p.x * (width + 180) -
                    y * (.025 + windStrength * .16) -
                    windTravel * .25) %
                (width + 180) -
            90;
        _sprite(
          2,
          x,
          y,
          radius * 2,
          radius * 2.24,
          p.phase + t * (.7 + p.variation),
          hailStrength * (.47 + p.depth * .40),
        );
      }
      for (final p in _nearHail.take(
        (19 * math.min(1.4, width / 1280)).round(),
      )) {
        final radius = 8 + p.depth * 13,
            y =
                (p.y * (height + 180) + t * (1250 + p.depth * 1100)) %
                    (height + 180) -
                90;
        final x =
            (p.x * (width + 200) -
                    y * (.04 + windStrength * .18) -
                    windTravel * .4) %
                (width + 200) -
            100;
        _sprite(
          3,
          x,
          y,
          radius * 2,
          radius * 3,
          .05 + windStrength * .18,
          hailStrength * (.20 + p.variation * .22),
        );
      }
    }
    final air =
        windStrength *
        (1 - rainStrength) *
        (1 - snowStrength) *
        (1 - hailStrength);
    _stroke.shader = null;
    if (air > .002) {
      for (final p in _wind.take((52 * math.min(1.4, width / 1280)).round())) {
        final x =
            (p.x * (width + 140) - windTravel * (1.7 + p.depth * 2.5)) %
                (width + 140) -
            70;
        final y =
            (p.y * height + math.sin(t * .42 + p.phase) * (8 + p.depth * 15)) %
            height;
        _stroke
          ..color = ui.Color.fromRGBO(
            227,
            232,
            224,
            air * (.06 + p.variation * .10),
          )
          ..strokeWidth = .6 + p.depth;
        canvas.drawLine(
          ui.Offset(x, y),
          ui.Offset(x + 3 + p.depth * 7, y - 1),
          _stroke,
        );
      }
    }
    final clear =
        (1 - values[1]) *
        math.max(0, 1 - values[0] / .065) *
        (1 - rainStrength) *
        (1 - snowStrength) *
        (1 - values[3]);
    if (clear > .002) {
      // Every mote owns one cell of an even grid and reappears somewhere
      // inside it, so motes stay spread out instead of clumping.
      // A few motes out of the generated field keep the sky uncluttered.
      final count = _motes.length * 3 ~/ 8;
      final columns = math.max(1, math.sqrt(count * width / height).round());
      final rows = (count / columns).ceil();
      final cellWidth = width / columns, cellHeight = height / rows;
      final sunX = width * .84, sunY = height * (.24 + .48 * twilight);
      for (var i = 0; i < count; i++) {
        final p = _motes[i];
        // Each mote glows for a few seconds, fades out, rests unseen and
        // appears again somewhere else. Cycles are staggered per mote.
        final period = 10 + p.drift * 10;
        final cycle = t / period + p.phase / (math.pi * 2);
        final k = cycle.floorToDouble(), age = cycle - k;
        final state = _moteCycles[i]..update(i, k);
        double smooth(double a, double b, double v) {
          final s = ((v - a) / (b - a)).clamp(0.0, 1.0);
          return s * s * (3 - 2 * s);
        }

        final blink = smooth(0, .18, age) * (1 - smooth(.6, .8, age));
        if (blink <= 0) continue;
        final seconds = age * period;
        // Each appearance drifts its own way, so the field as a whole never
        // slides toward one side.
        final x =
            (i % columns + .15 + state.cellX * .7) * cellWidth +
            state.velocityX * seconds +
            math.sin(t * .19 + p.phase) * 9;
        final y =
            (i ~/ columns + .15 + state.cellY * .7) * cellHeight +
            state.velocityY * seconds +
            math.sin(t * .23 + p.phase) * 8;
        // The sun's glare outshines motes that drift close to it. Matches
        // the sun position in the sky shader, lower at dawn and dusk.
        final light =
            1 -
            math.exp(-(math.pow(x - sunX, 2) + math.pow(y - sunY, 2)) / 14000);
        final alpha = clear * (.2 + p.variation * .2) * light * blink;
        // Blurred specks rather than flat dots. The Gaussian fades out well
        // inside its bounds, so the quad is larger than the mote.
        final size = (3.2 + p.depth * 1.6) * 4.4;
        _batch.add(
          _moteCell,
          x,
          y,
          size,
          size,
          0,
          ((alpha.clamp(0.0, 1.0) * 255).round() << 24) | 0xFFE9B5,
        );
      }
    }
    _paintGlass(width, values, t, windStrength, lightning);
    final atlas = _atlasShader;
    if (atlas != null && _batch.isNotEmpty) {
      final mesh = _batch.vertices();
      canvas.drawVertices(mesh, ui.BlendMode.modulate, _atlasPaint);
      mesh.dispose();
    }
    canvas.restore();
  }

  /// Rain collects on the glass in front of the scene. Each slot repeats a
  /// deterministic life: a drop lands, rests, and larger ones may slide down
  /// and leave a wet trail with a few small beads before the next one lands.
  void _paintGlass(
    double width,
    List<double> values,
    double t,
    double wind,
    WeatherMoodLightning lightning,
  ) {
    final rain = values[2], downpour = values[6];
    if (rain <= .002) return;
    const height = 720.0;
    final intensity = rain * (.55 + .45 * downpour);
    // Drops pass on what they refract: dimmer at night, and bright white for
    // an instant when lightning strikes.
    final night = values[1];
    final flash = lightning.strength.clamp(0.0, 1.0);
    int channel(double day, double dark) =>
        (day +
                (dark - day) * night +
                (255 - day - (dark - day) * night) * flash)
            .round()
            .clamp(0, 255);
    final tint =
        (channel(240, 190) << 16) |
        (channel(246, 200) << 8) |
        channel(255, 222);
    final opacity = math.min(1.0, rain * 1.4) * .9;
    final slots = (_glass.length * math.min(1.2, width / 1280)).round().clamp(
      0,
      _glass.length,
    );
    int color(double alpha) =>
        ((alpha.clamp(0.0, 1.0) * 255).round() << 24) | tint;
    for (var i = 0; i < slots; i++) {
      final p = _glass[i];
      // Slots join in order of their variation as the rain gets heavier.
      final presence = ((intensity - p.variation * .95) * 10).clamp(0.0, 1.0);
      if (presence <= 0) continue;
      final period = 7 + p.drift * 9;
      final cycle = t + p.phase / (math.pi * 2) * period;
      final k = (cycle / period).floorToDouble();
      final age = cycle - k * period;
      final state = _glassCycles[i]..update(i, k, period, _dropShapes.length);
      final seed = state.seed;
      final x0 = state.x * (width + 40) - 20;
      final y0 = state.y * (height - 40) + 10;
      var radius = state.radius;
      final slides = radius > 7 && state.slideChance < .45 + .35 * downpour;
      final slideStart = state.slideStart;
      final pop = math.min(1.0, age / .12);
      final life =
          presence *
          opacity *
          math.min(1.0, age / .06) *
          ((period - age) / 1.2).clamp(0.0, 1.0);
      var x = x0, y = y0, stretch = 1.0;
      if (slides && age > slideStart) {
        final s = age - slideStart;
        final distance = 38 * s + 60 * s * s;
        radius *= math.max(.72, 1 - distance / 900);
        y = y0 + distance;
        x =
            x0 +
            distance * wind * .12 +
            math.sin(s * 2.3 + seed) * 1.4 * math.min(1.0, s);
        stretch = 1 + math.min(.5, (38 + 120 * s) / 420);
        final trailAlpha = life * .85;
        final trailWidth = radius * 1.1;
        final top = y0 - radius * .4, bottom = y - radius * .3;
        if (bottom > top + 2) {
          _batch.segment(
            _trailCell,
            x0,
            top,
            x,
            bottom,
            trailWidth,
            color(trailAlpha),
          );
        }
        // Small beads stay behind where the drop has already passed.
        for (var j = 0; j < 4; j++) {
          final at = (j + .35 + state.beadAt[j] * .5) * 34;
          if (y0 + at > y - radius * 1.5) break;
          final along = at / math.max(1, y - y0);
          final bead = radius * (.2 + state.beadSize[j] * .14);
          _batch.add(
            _dropCell,
            x0 + (x - x0) * along,
            y0 + at,
            bead * 2,
            bead * 2,
            0,
            color(life * .9),
          );
        }
        if (y - radius * 2 > height) continue;
      }
      final size = radius * 2 * (.7 + .3 * pop);
      // Resting drops vary in outline and proportion. Sliding ones round
      // out as they run.
      final shape = state.shape;
      final aspect = state.aspect;
      _batch.add(
        stretch > 1 ? _shapeCell(4) : _shapeCell(shape),
        x,
        y,
        size * aspect / math.sqrt(stretch),
        size / aspect * stretch,
        0,
        color(life),
      );
    }
  }

  List<ui.Offset> _path(
    ui.Offset start,
    ui.Offset end,
    double amplitude,
    int steps,
    double seed,
  ) {
    var points = [start, end];
    for (var level = 0; level < steps; level++) {
      final next = [points.first];
      for (var i = 1; i < points.length; i++) {
        final a = points[i - 1], b = points[i];
        next.add(
          ui.Offset(
            (a.dx + b.dx) / 2 +
                (weatherMoodRandom(seed + level * 113 + i * 7) - .5) *
                    amplitude,
            (a.dy + b.dy) / 2 +
                (weatherMoodRandom(seed + level * 31 + i) - .5) *
                    amplitude *
                    .14,
          ),
        );
        next.add(b);
      }
      points = next;
      amplitude *= .52;
    }
    return points;
  }

  void _lightning(ui.Canvas canvas, double width, WeatherMoodLightning event) {
    if (event.strength < .005) return;
    const height = 720.0;
    if (_boltId != event.id || _boltWidth != width) {
      final start = ui.Offset(event.x * width, event.y * height);
      final end = ui.Offset(
        start.dx + (weatherMoodRandom(event.id + 81.0) - .5) * width * .35,
        height * (.76 + weatherMoodRandom(event.id + 88.0) * .30),
      );
      final points = _path(start, end, height * .34, 6, event.id * 117.0 + 9);
      final paths = [points];
      for (var i = 0; i < 5; i++) {
        final from =
            points[12 + (weatherMoodRandom(event.id + i * 11.0) * 34).floor()];
        final side = weatherMoodRandom(event.id + i + 9.0) > .5 ? 1 : -1;
        final to = ui.Offset(
          from.dx +
              side *
                  height *
                  (.09 + weatherMoodRandom(event.id + i + 31.0) * .24),
          from.dy +
              height * (.09 + weatherMoodRandom(event.id + i + 71.0) * .23),
        );
        paths.add(_path(from, to, height * .12, 4, event.id + i * 39.0));
      }
      _bolts = paths
          .map((points) => ui.Path()..addPolygon(points, false))
          .toList();
      _boltId = event.id;
      _boltWidth = width;
    }
    // Additive, like light. Screen looks the same over storm clouds, but
    // Impeller copies the whole screen for every screen blended draw on
    // OpenGL ES, which dropped a strike to a few frames per second.
    _stroke
      ..blendMode = ui.BlendMode.plus
      ..strokeJoin = ui.StrokeJoin.round;
    final glow = ui.Gradient.linear(
      ui.Offset.zero,
      const ui.Offset(0, height),
      const [
        ui.Color(0x008170FF),
        ui.Color(0xFF8B85FF),
        ui.Color(0xFF6C9AFF),
        ui.Color(0x596C9AFF),
      ],
      [0, .12, .72, 1],
    );
    void trace(
      ui.Path path,
      double width,
      double alpha,
      ui.Color color, [
      ui.Shader? shader,
    ]) {
      _stroke
        ..strokeWidth = width
        ..color = color.withValues(alpha: alpha * event.strength)
        ..shader = shader;
      canvas.drawPath(path, _stroke);
    }

    trace(_bolts.first, 19, .15, const ui.Color(0xFFFFFFFF), glow);
    trace(_bolts.first, 8, .31, const ui.Color(0xFFFFFFFF), glow);
    trace(_bolts.first, 3.4, .88, const ui.Color(0xFFB3C7FF));
    trace(_bolts.first, 1.45, 1, const ui.Color(0xFFF8FAFF));
    for (final path in _bolts.skip(1)) {
      trace(path, 6, .13, const ui.Color(0xFFFFFFFF), glow);
      trace(path, 1.4, .61, const ui.Color(0xFFAAC3FF));
      trace(path, .6, .86, const ui.Color(0xFFE9F1FF));
    }
    _stroke
      ..blendMode = ui.BlendMode.srcOver
      ..shader = null;
  }
}

/// Collects textured quads so a whole layer of sprites draws in one call.
class _SpriteBatch {
  Float32List _positions = Float32List(0), _coordinates = Float32List(0);
  Int32List _colors = Int32List(0);
  Uint16List _indices = Uint16List(0);
  int _count = 0;

  bool get isNotEmpty => _count > 0;

  void clear() => _count = 0;

  /// Adds a [width] by [height] quad centered on [x], [y] and rotated by
  /// [angle], textured with [source] from the atlas.
  void add(
    ui.Rect source,
    double x,
    double y,
    double width,
    double height,
    double angle,
    int color,
  ) {
    final c = math.cos(angle), s = math.sin(angle);
    final ax = c * width / 2, ay = s * width / 2;
    final bx = -s * height / 2, by = c * height / 2;
    _quad(
      source,
      x - ax - bx,
      y - ay - by,
      x + ax - bx,
      y + ay - by,
      x - ax + bx,
      y - ay + by,
      x + ax + bx,
      y + ay + by,
      color,
    );
  }

  /// Adds a quad of [width] stretched from ([x0], [y0]) at the top of
  /// [source] to ([x1], [y1]) at its bottom.
  void segment(
    ui.Rect source,
    double x0,
    double y0,
    double x1,
    double y1,
    double width,
    int color,
  ) {
    final dx = x1 - x0, dy = y1 - y0;
    final length = math.sqrt(dx * dx + dy * dy);
    final nx = -dy / length * width / 2, ny = dx / length * width / 2;
    _quad(
      source,
      x0 + nx,
      y0 + ny,
      x0 - nx,
      y0 - ny,
      x1 + nx,
      y1 + ny,
      x1 - nx,
      y1 - ny,
      color,
    );
  }

  /// Corners in order: top left, top right, bottom left, bottom right.
  void _quad(
    ui.Rect source,
    double x0,
    double y0,
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
    int color,
  ) {
    if (_count * 4 + 4 > 65535) return;
    _reserve(_count + 1);
    final at = _count * 8;
    _positions
      ..[at] = x0
      ..[at + 1] = y0
      ..[at + 2] = x1
      ..[at + 3] = y1
      ..[at + 4] = x2
      ..[at + 5] = y2
      ..[at + 6] = x3
      ..[at + 7] = y3;
    _coordinates
      ..[at] = source.left
      ..[at + 1] = source.top
      ..[at + 2] = source.right
      ..[at + 3] = source.top
      ..[at + 4] = source.left
      ..[at + 5] = source.bottom
      ..[at + 6] = source.right
      ..[at + 7] = source.bottom;
    _colors.fillRange(_count * 4, _count * 4 + 4, color);
    _count++;
  }

  void _reserve(int quads) {
    if (_colors.length >= quads * 4) return;
    final capacity = math.max(quads, _colors.length ~/ 4 * 2 + 64);
    _positions = Float32List(capacity * 8)..setAll(0, _positions);
    _coordinates = Float32List(capacity * 8)..setAll(0, _coordinates);
    _colors = Int32List(capacity * 4)..setAll(0, _colors);
    _indices = Uint16List(capacity * 6);
    for (var i = 0; i < capacity; i++) {
      final v = i * 4;
      _indices.setAll(i * 6, [v, v + 1, v + 2, v + 1, v + 3, v + 2]);
    }
  }

  ui.Vertices vertices() => ui.Vertices.raw(
    ui.VertexMode.triangles,
    Float32List.sublistView(_positions, 0, _count * 8),
    textureCoordinates: Float32List.sublistView(_coordinates, 0, _count * 8),
    colors: Int32List.sublistView(_colors, 0, _count * 4),
    indices: Uint16List.sublistView(_indices, 0, _count * 6),
  );
}
