import 'dart:math';

/// The dimming factor adaptive brightness applies to every brightness
/// setting (issue #343): 1.0 in a bright room, [floor] in a dark one, and
/// in between a line on the log of the light level, because the eye judges
/// light on a log scale (a linear map parks the panel at the floor for the
/// whole 0..50 lx evening and then jumps).
///
/// Pure: the screen manager owns the sensor stream, the ceiling every
/// setting supplies, and the write discipline; this is only the shape.
class AdaptiveCurve {
  const AdaptiveCurve({
    required this.floor,
    required this.darkLux,
    required this.brightLux,
  });

  /// The factor at and below [darkLux], as a share of the setting (0..1).
  final double floor;

  /// The light level at or below which the panel is fully dimmed.
  final double darkLux;

  /// The light level at or above which the panel shows the setting as is.
  final double brightLux;

  /// The factor for a light reading, in [floor]..1.
  double factor(double lux) {
    final f = floor.clamp(0.0, 1.0);
    // A light sensor reports 0 in a dark room and log(0) is not a number;
    // and a curve whose ends crossed (the sliders let them) is a step.
    final dark = max(darkLux, 0.01);
    final bright = max(brightLux, 0.01);
    if (bright <= dark) return lux >= bright ? 1.0 : f;
    if (lux <= dark) return f;
    if (lux >= bright) return 1.0;
    final t = (log(lux) - log(dark)) / (log(bright) - log(dark));
    return f + (1 - f) * t;
  }
}
