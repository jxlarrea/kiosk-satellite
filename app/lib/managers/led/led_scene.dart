import 'dart:math' as math;

/// What the status lights show, and how it moves (LedManager picks one at a
/// time). Rendered for any number of lights by [renderLedFrame], so a new
/// device needs no new effects.
enum LedEffect {
  /// Every light in [LedScene.color].
  solid,

  /// The whole row fades slowly in and out.
  breathe,

  /// The whole row fades quickly in and out.
  pulse,

  /// [LedScene.color] with an arc of [LedScene.accent] standing still.
  arc,

  /// A dim [LedScene.color] with an arc of [LedScene.accent] going round.
  spin,

  /// [LedScene.color] at full with an arc of [LedScene.accent] going round.
  orbit,

  /// [LedScene.color] and [LedScene.accent] alternating and stepping round.
  chase,

  /// The row fades between [LedScene.color] and [LedScene.accent].
  blend,

  /// Lit up to [LedScene.fraction] of the row, the rest dark.
  countdown,

  /// Two quick swells and a rest, like a heartbeat.
  heartbeat,

  /// One soft crest of light travelling round.
  wave,

  /// Every light rising and falling slowly at its own pace.
  shimmer,

  /// Lights flashing at random over a dim glow.
  sparkle,

  /// A bright head with a long fading tail going round.
  comet,

  /// Blocks of two lights stepping round, like a theater sign.
  marquee,

  /// Two lights leaving the first light in opposite directions, meeting
  /// across the row and coming back.
  sweep,

  /// Three evenly spaced blades turning.
  fan,

  /// The row filling up light by light, then emptying in the same order.
  fill,

  /// Two lights going round in opposite directions, crossing twice a turn.
  twinOrbit,

  /// One light swinging back and forth around the first light.
  pendulum,

  /// Every light wavering like a flame.
  flicker,

  /// The colors spread around the row and turning.
  rotate,

  /// The whole row moving slowly through the colors.
  cycle,

  /// The colors drifting slowly across the row.
  drift,
}

/// One color as 0xRRGGBB.
typedef Rgb = int;

class LedScene {
  const LedScene({
    required this.name,
    required this.effect,
    required this.color,
    this.accent,
    this.brightness = 1,
    this.fraction = 1,
    this.palette,
  });

  /// What it is for, for the log and the remote admin: `voice_listening`.
  final String name;
  final LedEffect effect;
  final Rgb color;
  final Rgb? accent;

  /// 0..1, applied to every light.
  final double brightness;

  /// For [LedEffect.countdown]: the share of the row still lit.
  final double fraction;

  /// The colors of a look that has its own, such as a rainbow, in place of
  /// [color]. Null for a single color.
  final List<Rgb>? palette;

  /// Whether the frame changes over time at a steady pace.
  bool get animated => switch (effect) {
    LedEffect.solid || LedEffect.arc || LedEffect.countdown => false,
    _ => true,
  };

  @override
  bool operator ==(Object other) =>
      other is LedScene &&
      other.name == name &&
      other.effect == effect &&
      other.color == color &&
      other.accent == accent &&
      other.brightness == brightness &&
      other.fraction == fraction &&
      _sameColors(other.palette, palette);

  @override
  int get hashCode => Object.hash(
    name,
    effect,
    color,
    accent,
    brightness,
    fraction,
    palette == null ? null : Object.hashAll(palette!),
  );
}

bool _sameColors(List<Rgb>? a, List<Rgb>? b) {
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The moment of [effect] that stands for it on lights that cannot
/// animate (LedDevice.animates): a pulse at its brightest, an arc where it
/// starts, a fade at its accent.
Duration ledStillPose(LedEffect effect) => switch (effect) {
  LedEffect.breathe => const Duration(milliseconds: 1500),
  LedEffect.pulse => const Duration(milliseconds: 600),
  LedEffect.blend => const Duration(milliseconds: 700),
  LedEffect.heartbeat => const Duration(milliseconds: 90),
  LedEffect.sweep => const Duration(milliseconds: 500),
  LedEffect.fill => const Duration(milliseconds: 1600),
  LedEffect.twinOrbit => const Duration(milliseconds: 500),
  _ => Duration.zero,
};

/// "r,g,b" as stored by the color settings, or [fallback] when unreadable.
Rgb parseRgb(String value, {Rgb fallback = 0xFFFFFF}) {
  final parts = value.split(',');
  if (parts.length != 3) return fallback;
  final c = [for (final p in parts) int.tryParse(p.trim())];
  if (c.any((v) => v == null)) return fallback;
  int ch(int v) => v.clamp(0, 255);
  return (ch(c[0]!) << 16) | (ch(c[1]!) << 8) | ch(c[2]!);
}

Rgb _scale(Rgb c, double f) {
  final k = f.clamp(0.0, 1.0);
  int ch(int shift) => (((c >> shift) & 0xFF) * k).round();
  return (ch(16) << 16) | (ch(8) << 8) | ch(0);
}

Rgb _mix(Rgb a, Rgb b, double t) {
  final k = t.clamp(0.0, 1.0);
  int ch(int shift) {
    final x = (a >> shift) & 0xFF;
    final y = (b >> shift) & 0xFF;
    return (x + (y - x) * k).round();
  }

  return (ch(16) << 16) | (ch(8) << 8) | ch(0);
}

/// 0..1 and back over [period], starting dark.
double _wave(Duration t, Duration period) =>
    0.5 -
    0.5 * math.cos(2 * math.pi * t.inMicroseconds / period.inMicroseconds);

/// [colors] as a loop: 0 and 1 are the first color, blending through the
/// rest in between.
Rgb _cyclic(List<Rgb> colors, double x) {
  if (colors.length == 1) return colors.first;
  final at = (x % 1) * colors.length;
  final i = at.floor() % colors.length;
  return _mix(colors[i], colors[(i + 1) % colors.length], at - at.floor());
}

/// [colors] as a line: 0 is the first color and 1 the last.
Rgb _linear(List<Rgb> colors, double x) {
  if (colors.length == 1) return colors.first;
  final at = x.clamp(0.0, 1.0) * (colors.length - 1);
  final i = math.min(at.floor(), colors.length - 2);
  return _mix(colors[i], colors[i + 1], at - i);
}

Rgb _add(Rgb a, Rgb b) {
  int ch(int shift) =>
      math.min(255, ((a >> shift) & 0xFF) + ((b >> shift) & 0xFF));
  return (ch(16) << 16) | (ch(8) << 8) | ch(0);
}

/// A soft light at [at] (in lights, any number, wrapping round the row),
/// added to what [frame] already shows.
void _dot(List<Rgb> frame, double at, Rgb color, double width) {
  final n = frame.length;
  if (n == 0) return;
  final center = at % n;
  for (var i = 0; i < n; i++) {
    final d = (i - center).abs();
    final apart = math.min(d, n - d);
    if (apart >= width) continue;
    final f = 1 - apart / width;
    frame[i] = _add(frame[i], _scale(color, f * f));
  }
}

/// A bell around [center], [width] wide, peaking at 1.
double _bump(double x, double center, double width) {
  final d = (x - center) / width;
  return math.exp(-d * d);
}

/// The same well-mixed 32 bits for the same [x], so random-looking
/// effects stay a function of time.
int _hash(int x) {
  var h = (x * 0x9E3779B1) & 0xFFFFFFFF;
  h ^= h >> 15;
  h = (h * 0x2C1B3C6D) & 0xFFFFFFFF;
  h ^= h >> 12;
  h = (h * 0x297A2D39) & 0xFFFFFFFF;
  h ^= h >> 15;
  return h;
}

/// Light [i] of a sparkle at [ms]: each light gets a 1.6 s turn of its
/// own, flashes in half of them at a random moment and fades back to a
/// dim glow.
Rgb _spark(List<Rgb> colors, int i, double ms) {
  const turn = 1600.0;
  final offset = (_hash(i + 31) & 0xFFFF) / 0xFFFF * turn;
  final local = ms + offset;
  final h = _hash(i * 7919 + (local ~/ turn));
  final color = _cyclic(colors, ((h >> 17) & 0xFF) / 256);
  var f = 0.15;
  if (h.isOdd) {
    final at = ((h >> 1) & 0xFFFF) / 0xFFFF * (turn - 500);
    final since = local % turn - at;
    if (since >= 0 && since < 500) {
      f = math.max(f, since < 30 ? since / 30 : math.exp(-(since - 30) / 120));
    }
  }
  return _scale(color, f);
}

/// One frame of [scene] at [t] since it started, [pixels] lights long.
List<Rgb> renderLedFrame(
  LedScene scene, {
  required int pixels,
  Duration t = Duration.zero,
}) {
  final accent = scene.accent ?? scene.color;
  // An arc covers a quarter of the row, at least one light.
  final arcLength = math.max(1, (pixels / 4).round());
  final colors = scene.palette ?? [scene.color];
  // The colors laid once around the row, light by light.
  Rgb around(int i) => _cyclic(colors, i / math.max(1, pixels));
  final ms = t.inMicroseconds / 1000;
  final List<Rgb> frame;
  switch (scene.effect) {
    case LedEffect.solid:
      frame = List.filled(pixels, scene.color);
    case LedEffect.breathe:
      final f = 0.15 + 0.85 * _wave(t, const Duration(milliseconds: 3000));
      frame = [for (var i = 0; i < pixels; i++) _scale(around(i), f)];
    case LedEffect.pulse:
      final f = 0.2 + 0.8 * _wave(t, const Duration(milliseconds: 1200));
      frame = [for (var i = 0; i < pixels; i++) _scale(around(i), f)];
    case LedEffect.arc:
      frame = [
        for (var i = 0; i < pixels; i++) i < arcLength ? accent : scene.color,
      ];
    case LedEffect.spin || LedEffect.orbit:
      // One turn a second, the arc's tail fading into the base behind its
      // head. Spin dims the base so the arc stands out on its own.
      final base = scene.effect == LedEffect.spin
          ? _scale(scene.color, 0.3)
          : scene.color;
      final head = (t.inMilliseconds % 1000) / 1000 * pixels;
      frame = [
        for (var i = 0; i < pixels; i++)
          () {
            final behind = (head - i) % pixels;
            if (behind < arcLength) {
              return _mix(accent, base, behind / arcLength);
            }
            return base;
          }(),
      ];

    case LedEffect.chase:
      final step = t.inMilliseconds ~/ 150;
      frame = [
        for (var i = 0; i < pixels; i++)
          (i + step).isEven ? scene.color : accent,
      ];
    case LedEffect.blend:
      final f = _wave(t, const Duration(milliseconds: 1400));
      frame = List.filled(pixels, _mix(scene.color, accent, f));
    case LedEffect.countdown:
      final lit = scene.fraction.clamp(0.0, 1.0) * pixels;
      frame = [
        for (var i = 0; i < pixels; i++)
          i < lit.floor()
              ? scene.color
              : i == lit.floor()
              ? _scale(scene.color, lit - lit.floor())
              : 0,
      ];
    case LedEffect.heartbeat:
      final x = ms % 1200;
      final f = math.max(_bump(x, 90, 55), 0.7 * _bump(x, 330, 65));
      frame = [
        for (var i = 0; i < pixels; i++) _scale(around(i), 0.08 + 0.92 * f),
      ];
    case LedEffect.wave:
      final phase = ms / 2500;
      frame = [
        for (var i = 0; i < pixels; i++)
          () {
            final c = 0.5 + 0.5 * math.cos(2 * math.pi * (i / pixels - phase));
            return _scale(_linear(colors, c), 0.15 + 0.85 * c * c);
          }(),
      ];
    case LedEffect.shimmer:
      final s = ms / 1000;
      frame = [
        for (var i = 0; i < pixels; i++)
          () {
            final h = _hash(i + 101);
            final pace = 0.15 + 0.25 * (h & 0xFFFF) / 0xFFFF;
            final start = (h >> 16) / 0xFFFF;
            final f = 0.5 + 0.5 * math.sin(2 * math.pi * (s * pace + start));
            return _scale(_cyclic(colors, start + s * 0.02), 0.3 + 0.7 * f);
          }(),
      ];
    case LedEffect.sparkle:
      frame = [for (var i = 0; i < pixels; i++) _spark(colors, i, ms)];
    case LedEffect.comet:
      final head = ms / 1600 * pixels;
      final tail = pixels * 0.6;
      frame = [
        for (var i = 0; i < pixels; i++)
          () {
            final behind = (head - i) % pixels;
            // The light just ahead fades in as the head reaches it, so the
            // head moves smoothly instead of jumping a light at a time.
            if (behind > pixels - 1) {
              return _scale(_cyclic(colors, ms / 6000), behind - (pixels - 1));
            }
            if (behind >= tail) return 0;
            final f = math.pow(1 - behind / tail, 2.2).toDouble();
            return _scale(
              _cyclic(colors, ms / 6000 - behind / pixels * 0.3),
              f,
            );
          }(),
      ];
    case LedEffect.marquee:
      final step = ms ~/ 250;
      frame = [
        for (var i = 0; i < pixels; i++)
          () {
            final block = (i + step) ~/ 2;
            if (colors.length > 1) return colors[block % colors.length];
            return block.isEven ? colors.first : 0;
          }(),
      ];
    case LedEffect.sweep:
      final reach =
          pixels / 2 * (0.5 - 0.5 * math.cos(2 * math.pi * ms / 2000));
      frame = List.filled(pixels, 0);
      _dot(frame, reach, _linear(colors, reach / (pixels / 2)), 1.5);
      _dot(frame, -reach, _linear(colors, reach / (pixels / 2)), 1.5);
    case LedEffect.fan:
      final phase = ms / 2400;
      frame = [
        for (var i = 0; i < pixels; i++)
          () {
            final x = (i / pixels - phase) * 3;
            final blade = x.floor();
            final f = math.pow(0.5 + 0.5 * math.cos(2 * math.pi * x), 4);
            return _scale(_cyclic(colors, (blade % 3) / 3), f.toDouble());
          }(),
      ];
    case LedEffect.fill:
      final u = ms % 3200 / 3200;
      frame = [
        for (var i = 0; i < pixels; i++)
          () {
            final double f;
            if (u < 0.45) {
              f = (u / 0.45 * pixels - i).clamp(0.0, 1.0);
            } else if (u < 0.55) {
              f = 1;
            } else {
              f = 1 - ((u - 0.55) / 0.45 * pixels - i).clamp(0.0, 1.0);
            }
            return _scale(
              _linear(colors, pixels < 2 ? 0 : i / (pixels - 1)),
              f,
            );
          }(),
      ];
    case LedEffect.twinOrbit:
      final at = ms / 2000 * pixels;
      frame = List.filled(pixels, 0);
      _dot(frame, at, colors.first, 1.3);
      _dot(frame, pixels / 2 - at, colors[1 % colors.length], 1.3);
    case LedEffect.pendulum:
      final at = pixels / 4 * math.sin(2 * math.pi * ms / 1800);
      frame = List.filled(pixels, 0);
      _dot(frame, at, _linear(colors, 0.5 + at / (pixels / 2)), 1.6);
    case LedEffect.flicker:
      final s = ms / 1000;
      final sway = 0.85 + 0.15 * math.sin(2 * math.pi * 0.6 * s);
      frame = [
        for (var i = 0; i < pixels; i++)
          () {
            final h = _hash(i + 7);
            final a = (h & 0xFF) / 255;
            final b = ((h >> 8) & 0xFF) / 255;
            final c = ((h >> 16) & 0xFF) / 255;
            final heat =
                (math.sin(2 * math.pi * (3.1 * s + a)) +
                        math.sin(2 * math.pi * (5.3 * s + b)) +
                        math.sin(2 * math.pi * (8.9 * s + c))) /
                    6 +
                0.5;
            return _scale(_linear(colors, heat), sway * (0.55 + 0.45 * heat));
          }(),
      ];
    case LedEffect.rotate:
      frame = [
        for (var i = 0; i < pixels; i++)
          _cyclic(colors, i / pixels + ms / 4000),
      ];
    case LedEffect.cycle:
      frame = List.filled(pixels, _cyclic(colors, ms / 10000));
    case LedEffect.drift:
      final s = ms / 1000;
      frame = [
        for (var i = 0; i < pixels; i++)
          () {
            final p = i / pixels;
            final x =
                p * 0.6 + s / 25 + 0.08 * math.sin(2 * math.pi * (s / 9 + p));
            final f = 0.5 + 0.5 * math.sin(2 * math.pi * (s / 7 + 2 * p));
            return _scale(_cyclic(colors, x), 0.55 + 0.45 * f);
          }(),
      ];
  }
  if (scene.brightness >= 1) return frame;
  return [for (final c in frame) _scale(c, scene.brightness)];
}

/// How an idle look moves and, for the looks with colors of their own, the
/// colors. The rest use the Idle group's color.
typedef LedLook = ({LedEffect effect, List<Rgb>? palette});

/// Every value of the Idle group's Effect setting (led.idle.style), in its
/// order.
const Map<String, LedLook> ledIdleLooks = {
  'solid': (effect: LedEffect.solid, palette: null),
  'breathe': (effect: LedEffect.breathe, palette: null),
  'pulse': (effect: LedEffect.pulse, palette: null),
  'heartbeat': (effect: LedEffect.heartbeat, palette: null),
  'wave': (effect: LedEffect.wave, palette: null),
  'shimmer': (effect: LedEffect.shimmer, palette: null),
  'sparkle': (effect: LedEffect.sparkle, palette: null),
  'flicker': (effect: LedEffect.flicker, palette: null),
  'comet': (effect: LedEffect.comet, palette: null),
  'marquee': (effect: LedEffect.marquee, palette: null),
  'sweep': (effect: LedEffect.sweep, palette: null),
  'fan': (effect: LedEffect.fan, palette: null),
  'fill': (effect: LedEffect.fill, palette: null),
  'twin_orbit': (effect: LedEffect.twinOrbit, palette: null),
  'pendulum': (effect: LedEffect.pendulum, palette: null),
  'rainbow': (effect: LedEffect.rotate, palette: _rainbow),
  'color_cycle': (effect: LedEffect.cycle, palette: _rainbow),
  'rainbow_comet': (effect: LedEffect.comet, palette: _rainbow),
  'rainbow_sparkle': (effect: LedEffect.sparkle, palette: _rainbow),
  'candlelight': (effect: LedEffect.flicker, palette: [0xFF8A2A]),
  'campfire': (effect: LedEffect.flicker, palette: _campfire),
  'lava': (effect: LedEffect.drift, palette: _lava),
  'northern_lights': (effect: LedEffect.drift, palette: _northernLights),
  'sunset': (effect: LedEffect.drift, palette: _sunset),
  'ocean': (effect: LedEffect.wave, palette: _ocean),
  'frost': (effect: LedEffect.shimmer, palette: _frost),
  'forest': (effect: LedEffect.shimmer, palette: _forest),
  'candy_cane': (effect: LedEffect.marquee, palette: [0xFF0000, 0xFFFFFF]),
  'holiday': (effect: LedEffect.marquee, palette: [0xFF0000, 0x00B000]),
  'neon': (effect: LedEffect.twinOrbit, palette: [0xFF00C8, 0x00F0FF]),
};

const _rainbow = [
  0xFF0000,
  0xFF7F00,
  0xFFFF00,
  0x00FF00,
  0x00FFFF,
  0x0000FF,
  0x8B00FF,
];

/// Embers to flame tips: a flicker runs from the first to the last.
const _campfire = [0x8B1A00, 0xE04000, 0xFF7A10, 0xFFC060];

const _lava = [0x5A0000, 0xC81E00, 0xFF5500, 0xFF9A00];

const _northernLights = [0x00E676, 0x00BFA5, 0x2962FF, 0x7C4DFF, 0x00C853];

const _sunset = [0xFF5E3A, 0xFF2A68, 0xB0287D, 0x5B2A86, 0xFFA03A];

/// The deep water between crests to the foam on top.
const _ocean = [0x001A66, 0x0057B8, 0x00A6D6, 0xB8F4FF];

const _frost = [0xDDF4FF, 0x9ED8FF, 0x4AA8FF, 0xFFFFFF];

const _forest = [0x0B6623, 0x2E8B22, 0x6BBF3A, 0x9ACD32, 0x1F5F3F];
