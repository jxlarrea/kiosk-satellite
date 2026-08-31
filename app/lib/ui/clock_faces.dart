import 'dart:math';

import 'package:flutter/material.dart';

/// The non-digital clock screensaver faces (issue #56): the split-flap Flip
/// Clock and the Roller Clock, whose oversized cropped digits roll upward as
/// time advances. Both are driven by the same minute tick as the digital
/// face — [ClockScreensaver] passes the current time in and each face
/// animates only the digits that changed.
///
/// The font family for a `screensaver.clock_font` value (issue #391).
/// Besides Rubik and two bundled faces (Nunito, the rounded Apple StandBy
/// look, and DSEG14, the LCD option, neither a look any system font has),
/// the options are Android's own generic families, which
/// the engine resolves through the platform font manager (fonts.xml
/// aliases every Android ships, though what each maps to varies by ROM —
/// AOSP serves Noto Serif for serif, Dancing Script for cursive; Fire OS
/// substitutes Amazon's faces). Null is the platform default (Roboto on
/// stock Android), and an alias a ROM lacks falls back there too, so a
/// stale stored value can never break the clock; anything unknown keeps
/// Rubik, the original face.
/// The digital face's time weight for a `screensaver.clock_font` value.
/// The face is w300 by design, but Nunito exists to be the Apple StandBy
/// look, whose digits are heavy: at w300 it read as a thin clock that
/// happened to be rounded. Nunito is a variable font, so w700 is a real
/// cut of the axis, not a synthetic bold.
FontWeight clockFontWeight(String font) =>
    font == 'nunito' ? FontWeight.w700 : FontWeight.w300;

String? clockFontFamily(String font) => switch (font) {
  'nunito' => 'Nunito',
  'system' => null,
  'serif' => 'serif',
  'condensed' => 'sans-serif-condensed',
  'monospace' => 'monospace',
  'casual' => 'casual',
  'cursive' => 'cursive',
  'lcd' => 'DSEG14',
  _ => 'Rubik',
};

/// A split-flap clock: two rounded cards (hours, minutes) with a hinge line
/// across the middle. A changing card animates the classic two-phase flip —
/// the top half of the old value folds down over the hinge, then the bottom
/// half of the new value unfolds from it.
///
/// [backdropColor] is the wall behind the cards — the hinge gap paints it,
/// so the split shows the background rather than a derived grey (the shade
/// the wall used to take read as an unwanted gradient on OLED panels,
/// issue #391).
class FlipClockFace extends StatelessWidget {
  const FlipClockFace({
    super.key,
    required this.now,
    required this.use24h,
    required this.digitColor,
    required this.cardColor,
    required this.backdropColor,
    required this.scale,
    required this.fontFamily,
  });

  final DateTime now;
  final bool use24h;
  final Color digitColor;
  final Color cardColor;
  final Color backdropColor;
  final double scale;
  final String? fontFamily;

  String get _hours {
    final h = use24h ? now.hour : (now.hour % 12 == 0 ? 12 : now.hour % 12);
    return use24h ? h.toString().padLeft(2, '0') : h.toString();
  }

  String get _minutes => now.minute.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Noticeably taller than wide, as the reference cards are.
    final cardH = (min(size.height * 0.72, size.width * 0.46) * scale).clamp(
      60.0,
      2000.0,
    );
    final cardW = cardH * 0.84;
    final gap = cardH * 0.08;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FlipCard(
          value: _hours,
          width: cardW,
          height: cardH,
          digitColor: digitColor,
          cardColor: cardColor,
          backdropColor: backdropColor,
          fontFamily: fontFamily,
        ),
        SizedBox(width: gap),
        _FlipCard(
          value: _minutes,
          width: cardW,
          height: cardH,
          digitColor: digitColor,
          cardColor: cardColor,
          backdropColor: backdropColor,
          fontFamily: fontFamily,
        ),
      ],
    );
  }
}

class _FlipCard extends StatefulWidget {
  const _FlipCard({
    required this.value,
    required this.width,
    required this.height,
    required this.digitColor,
    required this.cardColor,
    required this.backdropColor,
    required this.fontFamily,
  });

  final String value;
  final double width;
  final double height;
  final Color digitColor;
  final Color cardColor;
  final Color backdropColor;
  final String? fontFamily;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  String _previous = '';

  @override
  void didUpdateWidget(_FlipCard old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _previous = old.value;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _face(String value) {
    return Container(
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(widget.height * 0.09),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontFamily: widget.fontFamily,
          color: widget.digitColor,
          fontSize: widget.height * 0.66,
          fontWeight: FontWeight.w400,
          fontFeatures: const [FontFeature.tabularFigures()],
          height: 1.0,
        ),
      ),
    );
  }

  /// The top or bottom half of a card face, clipped without moving the
  /// glyphs: the half is what the flap shows, not a re-layout.
  Widget _half(String value, {required bool top}) {
    return ClipRect(
      child: Align(
        alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
        heightFactor: 0.5,
        child: _face(value),
      ),
    );
  }

  Matrix4 _fold(double angle) => Matrix4.identity()
    ..setEntry(3, 2, 0.0015)
    ..rotateX(angle);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeIn.transform(_controller.value);
        final animating = _controller.isAnimating && _previous.isNotEmpty;
        final old = animating ? _previous : widget.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // The static halves underneath: new value on top, old below —
            // what the flap progressively reveals and covers.
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _half(widget.value, top: true),
                _half(old, top: false),
              ],
            ),
            // Phase 1: the old top half folds down to the hinge.
            if (animating && t < 0.5)
              Positioned(
                top: 0,
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: _fold(t * pi),
                  child: _half(_previous, top: true),
                ),
              ),
            // Phase 2: the new bottom half unfolds from the hinge.
            if (animating && t >= 0.5)
              Positioned(
                bottom: 0,
                child: Transform(
                  alignment: Alignment.topCenter,
                  transform: _fold((1 - t) * -pi),
                  child: _half(widget.value, top: false),
                ),
              ),
            // The hinge gap across the middle, painted the wall's own
            // color so the split shows the background through the card.
            Container(
              width: widget.width,
              height: max(widget.height * 0.008, 1.5),
              color: widget.backdropColor,
            ),
          ],
        );
      },
    );
  }
}

/// The two-character display hour, zero padded (the reference face pads
/// even in 12-hour mode: "02 58").
String _displayHour(int hour, bool use24h) {
  final h = use24h ? hour : (hour % 12 == 0 ? 12 : hour % 12);
  return h.toString().padLeft(2, '0');
}

/// Each roller digit's progress through its own period, 0 just after it
/// changed to 1 as it is about to. This is what places the digits at
/// different heights: a digit drifts upward across its whole period, so
/// its height IS the time — the minute-ones digit climbs over its minute,
/// the hour-ones over its hour, and one about to change sits cropped
/// against the top edge with its successor waiting below.
///
/// Kept a pure function of the wall time so it is testable and so a
/// rebuild at any moment lands every digit exactly where it belongs (no
/// accumulated animation state to drift).
List<double> rollerProgress(DateTime now, bool use24h) {
  // Milliseconds included: the face renders per frame, and whole seconds
  // would make the drift tick visibly instead of gliding.
  final frac = now.millisecond / 1000;
  final sec = now.minute * 60 + now.second + frac;
  // The hour-tens digit has an irregular period (in 24h it holds for 10,
  // 10 and 4 hours; 12h is lumpier still), so walk the hour wheel to find
  // its last and next change instead of assuming one.
  String h1(int hour) => _displayHour((hour + 24) % 24, use24h)[0];
  bool changesAt(int hour) => h1(hour) != h1(hour - 1);
  var back = 0;
  while (back < 24 && !changesAt(now.hour - back)) {
    back++;
  }
  var ahead = 1;
  while (ahead < 24 && !changesAt(now.hour + ahead)) {
    ahead++;
  }
  final h1Period = (back + ahead) * 3600;
  return [
    (back * 3600 + sec) / h1Period,
    sec / 3600,
    (now.minute % 10 * 60 + now.second + frac) / 600,
    (now.second + frac) / 60,
  ];
}

/// The Roller Clock: four oversized digits side by side, cropped at their
/// columns' edges so the glyphs run into each other, each column rolling
/// upward — the old digit slides up and out while the next one rises from
/// the bottom. Digit heights come from [rollerProgress], as on the Lenovo
/// Smart Clock 2 face this mirrors.
///
/// Self-ticking: the drift must glide, not step once a second, so the face
/// runs its own repaint ticker and reads the wall clock every frame instead
/// of leaning on [ClockScreensaver]'s coarser timer. Each glyph sits behind
/// a RepaintBoundary, so the per-frame work is recompositing four cached
/// layers at new offsets, not re-rasterising text.
class RollerClockFace extends StatefulWidget {
  const RollerClockFace({
    super.key,
    required this.use24h,
    required this.digitColor,
    required this.scale,
    required this.fontFamily,
  });

  final bool use24h;
  final Color digitColor;
  final double scale;
  final String? fontFamily;

  @override
  State<RollerClockFace> createState() => _RollerClockFaceState();
}

class _RollerClockFaceState extends State<RollerClockFace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _ticker,
      builder: (context, _) => _build(context, size, DateTime.now()),
    );
  }

  Widget _build(BuildContext context, Size size, DateTime now) {
    final digits =
        _displayHour(now.hour, widget.use24h) +
        now.minute.toString().padLeft(2, '0');
    final progress = rollerProgress(now, widget.use24h);
    final digitColor = widget.digitColor;
    final scale = widget.scale;
    // The glyphs are meant to bleed past their columns: the column is
    // narrower than the glyph, and the row narrower than four glyphs. The
    // column is the full display height (times the size setting), so the
    // travel crops digits against the screen edges themselves.
    final colH = (size.height * scale).clamp(80.0, 4000.0);
    // Larger than the column on purpose: the reference's digits fill the
    // panel, with the crop doing the framing.
    final fontSize = colH * 1.05;
    final colW = min(fontSize * 0.46, size.width / 4.2);
    // How far a digit travels across its period: a fresh digit sits cropped
    // against the bottom edge, one about to change against the top, as on
    // the reference.
    final travel = colH * 0.38;
    // A thin seam of background between the columns: the glyphs are cropped
    // hard at their column edges, and the gap is what reads as the digit
    // separation where neighbouring glyphs would otherwise touch.
    final seam = max(2.0, colH * 0.012);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) SizedBox(width: seam),
          _RollingDigit(
            digit: digits[i],
            dy: travel * (0.5 - progress[i]),
            exitDy: -travel / 2,
            width: colW,
            height: colH,
            fontSize: fontSize,
            color: digitColor,
            fontFamily: widget.fontFamily,
          ),
        ],
      ],
    );
  }
}

class _RollingDigit extends StatefulWidget {
  const _RollingDigit({
    required this.digit,
    required this.dy,
    required this.exitDy,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.color,
    required this.fontFamily,
  });

  final String digit;

  /// Resting vertical offset from the column centre, from the digit's
  /// progress through its period (fresh sits low, expiring sits high).
  final double dy;

  /// Where an expiring digit rests when its replacement arrives — the top
  /// of the travel — so the exit slide starts from where it was drawn.
  final double exitDy;

  final double width;
  final double height;
  final double fontSize;
  final Color color;
  final String? fontFamily;

  @override
  State<_RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<_RollingDigit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  String _previous = '';

  @override
  void didUpdateWidget(_RollingDigit old) {
    super.didUpdateWidget(old);
    if (old.digit != widget.digit) {
      _previous = old.digit;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _glyph(String d) {
    // OverflowBox: the glyph is bigger than the column on purpose — the
    // column crops its sides against its neighbours and its ends against
    // the screen edges. BOTH axes must be unbounded: with only the width
    // freed, the Text overflowed its height-constrained box and clipped
    // ITSELF (TextOverflow.clip), and since that clip travels with the
    // drift transform it squared digits off in mid-air at a height that
    // followed each digit's progress (issue #68). Unbounded, the paragraph
    // never overflows and the only clip left is the column's own.
    // The RepaintBoundary keeps the per-frame drift a compositor move
    // rather than a text re-rasterisation.
    return OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: RepaintBoundary(
        child: Text(
          d,
          style: TextStyle(
            fontFamily: widget.fontFamily,
            color: widget.color,
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w800,
            fontVariations: const [FontVariation('wght', 800)],
            height: 1.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeInOutCubic.transform(_controller.value);
            final rolling = _controller.isAnimating && _previous.isNotEmpty;
            if (!rolling) {
              return Transform.translate(
                offset: Offset(0, widget.dy),
                child: Center(child: _glyph(widget.digit)),
              );
            }
            return Stack(
              children: [
                // The expiring digit exits upward from the top of its
                // travel; the new one rises to the bottom of its own.
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(0, widget.exitDy - widget.height * t),
                    child: Center(child: _glyph(_previous)),
                  ),
                ),
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(0, widget.dy + widget.height * (1 - t)),
                    child: Center(child: _glyph(widget.digit)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
