import 'dart:convert';

/// The volumes adaptive volume can turn (issue #1450), in the order a
/// curve point stores them.
enum VolumeChannel { assistant, media, intercom }

/// One point of the adaptive volume curve: a room noise level in dBFS and
/// the share of its own slider each volume plays at there, 0 to 1.
class VolumePoint {
  const VolumePoint(this.noise, this.assistant, this.media, this.intercom);

  final double noise;
  final double assistant;
  final double media;
  final double intercom;

  double level(VolumeChannel channel) => switch (channel) {
    VolumeChannel.assistant => assistant,
    VolumeChannel.media => media,
    VolumeChannel.intercom => intercom,
  };

  VolumePoint withNoise(double value) =>
      VolumePoint(value, assistant, media, intercom);

  VolumePoint withLevel(VolumeChannel channel, double value) => VolumePoint(
    noise,
    channel == VolumeChannel.assistant ? value : assistant,
    channel == VolumeChannel.media ? value : media,
    channel == VolumeChannel.intercom ? value : intercom,
  );

  @override
  bool operator ==(Object other) =>
      other is VolumePoint &&
      other.noise == noise &&
      other.assistant == assistant &&
      other.media == media &&
      other.intercom == intercom;

  @override
  int get hashCode => Object.hash(noise, assistant, media, intercom);
}

/// What one point may be set to without crossing its neighbors: its noise
/// level strictly between theirs, each volume from the previous point's to
/// the next one's.
typedef VolumePointBounds = ({
  double noiseLo,
  double noiseHi,
  Map<VolumeChannel, double> levelLo,
  Map<VolumeChannel, double> levelHi,
});

/// The adaptive volume curve (issue #1450): four points from a quiet room
/// to a loud one. Between two points each volume moves in a straight line
/// over the noise level, which is already a log scale. Below the first
/// point and above the last the volume stays where that point put it.
///
/// Stored as one setting, a JSON list of `[noise, assistant, media,
/// intercom]` rows with the volumes in percent, so a point's four values
/// are written together and a half-written curve never exists. Mirrored on
/// the remote (adaptive_volume_curve.js).
class AdaptiveVolumeCurve {
  const AdaptiveVolumeCurve(this.points);

  final List<VolumePoint> points;

  static const pointCount = 4;

  /// The range a noise level can take: the bottom of 16-bit audio to full
  /// scale.
  static const minNoise = -96.0;
  static const maxNoise = 0.0;

  /// How close two neighbors' noise levels may come, in dB.
  static const noiseGap = 1.0;

  /// A quiet room at half the slider, a loud one at all of it, and a
  /// straight line between: about half a dB of volume per dB of noise.
  static const defaults = AdaptiveVolumeCurve([
    VolumePoint(-60, 0.5, 0.5, 0.5),
    VolumePoint(-50, 0.67, 0.67, 0.67),
    VolumePoint(-40, 0.83, 0.83, 0.83),
    VolumePoint(-30, 1, 1, 1),
  ]);

  /// [defaults] as the setting stores it.
  static const defaultJson =
      '[[-60,50,50,50],[-50,67,67,67],[-40,83,83,83],[-30,100,100,100]]';

  /// The curve a stored value describes, or the default one when the value
  /// is not a curve.
  static AdaptiveVolumeCurve parse(Object? value) =>
      _decode(value)?.curve ?? defaults;

  /// Why [value] is not a curve, or null when it is one. The setting's
  /// validator.
  static String? check(Object? value) {
    final decoded = _decode(value);
    return decoded == null
        ? 'The volume curve needs four points'
        : decoded.error;
  }

  static ({AdaptiveVolumeCurve curve, String? error})? _decode(Object? value) {
    Object? raw = value;
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        return null;
      }
    }
    if (raw is! List || raw.length != pointCount) return null;
    final points = <VolumePoint>[];
    for (final row in raw) {
      if (row is! List || row.length != 4) return null;
      final numbers = <double>[];
      for (final cell in row) {
        if (cell is! num || !cell.isFinite) return null;
        numbers.add(cell.toDouble());
      }
      points.add(
        VolumePoint(
          numbers[0],
          numbers[1] / 100,
          numbers[2] / 100,
          numbers[3] / 100,
        ),
      );
    }
    final curve = AdaptiveVolumeCurve(points);
    return (curve: curve, error: curve._error());
  }

  String? _error() {
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.noise < minNoise || p.noise > maxNoise) {
        return 'Enter room noise levels from -96 to 0 dBFS';
      }
      for (final channel in VolumeChannel.values) {
        final level = p.level(channel);
        if (level < 0 || level > 1) return 'Enter volumes from 0 to 100';
      }
      if (i == 0) continue;
      final before = points[i - 1];
      if (p.noise - before.noise < noiseGap - 1e-9) {
        return 'Room noise levels must rise from one point to the next';
      }
      for (final channel in VolumeChannel.values) {
        if (p.level(channel) < before.level(channel) - 1e-9) {
          return 'Volumes must not fall from one point to the next';
        }
      }
    }
    return null;
  }

  /// The stored form: whole dB and whole percent.
  String encode() => jsonEncode([
    for (final p in points)
      [
        p.noise.round(),
        (p.assistant * 100).round(),
        (p.media * 100).round(),
        (p.intercom * 100).round(),
      ],
  ]);

  /// The share of its slider [channel] plays at in a room at [noise] dBFS.
  double levelAt(VolumeChannel channel, double noise) {
    if (noise <= points.first.noise) return points.first.level(channel);
    for (var i = 1; i < points.length; i++) {
      final hi = points[i];
      if (noise > hi.noise) continue;
      final lo = points[i - 1];
      final t = (noise - lo.noise) / (hi.noise - lo.noise);
      return lo.level(channel) + (hi.level(channel) - lo.level(channel)) * t;
    }
    return points.last.level(channel);
  }

  /// What point [index] may be set to. [gap] keeps its noise level that
  /// far from its neighbors', and from the ends of the range.
  VolumePointBounds bounds(int index, {double gap = noiseGap}) {
    final before = index > 0 ? points[index - 1] : null;
    final after = index < points.length - 1 ? points[index + 1] : null;
    return (
      noiseLo: before == null ? minNoise : before.noise + gap,
      noiseHi: after == null ? maxNoise : after.noise - gap,
      levelLo: {
        for (final channel in VolumeChannel.values)
          channel: before?.level(channel) ?? 0.0,
      },
      levelHi: {
        for (final channel in VolumeChannel.values)
          channel: after?.level(channel) ?? 1.0,
      },
    );
  }

  /// The curve with point [index] replaced.
  AdaptiveVolumeCurve withPoint(int index, VolumePoint point) =>
      AdaptiveVolumeCurve([...points]..[index] = point);

  /// [want] pulled inside what point [index] may be set to.
  VolumePoint clamp(int index, VolumePoint want, {double gap = noiseGap}) {
    final b = bounds(index, gap: gap);
    var point = b.noiseLo <= b.noiseHi
        ? want.withNoise(want.noise.clamp(b.noiseLo, b.noiseHi).toDouble())
        : want.withNoise(points[index].noise);
    for (final channel in VolumeChannel.values) {
      final lo = b.levelLo[channel]!;
      final hi = b.levelHi[channel]!;
      point = point.withLevel(
        channel,
        want.level(channel).clamp(lo, hi).toDouble(),
      );
    }
    return point;
  }
}
