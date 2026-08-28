import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/screen/adaptive_brightness.dart';

/// The adaptive brightness curve (issue #343): the factor every brightness
/// setting is multiplied by, from the room's light.
void main() {
  const curve = AdaptiveCurve(floor: 0.2, darkLux: 5, brightLux: 500);

  test('the floor at and below the dark point, 1 at and above the bright '
      'one', () {
    expect(curve.factor(0), 0.2);
    expect(curve.factor(5), 0.2);
    expect(curve.factor(500), 1.0);
    expect(curve.factor(5000), 1.0);
  });

  test('log interpolated between them: the geometric midpoint is halfway', () {
    // sqrt(5 * 500) = 50 lx sits halfway up the log scale.
    expect(curve.factor(50), closeTo(0.6, 0.001));
    // A linear map would put 50 lx at 9% of the way; the log one keeps
    // the evening range (10..50 lx) usable instead of parked at the floor.
    expect(curve.factor(10), greaterThan(0.3));
    expect(curve.factor(250), lessThan(0.95));
  });

  test('monotonic', () {
    var last = -1.0;
    for (var lux = 0.0; lux <= 1000; lux += 7) {
      final f = curve.factor(lux);
      expect(f, greaterThanOrEqualTo(last));
      last = f;
    }
  });

  test('a floor outside 0..1 is clamped', () {
    expect(
      const AdaptiveCurve(floor: 1.5, darkLux: 5, brightLux: 500).factor(1),
      1.0,
    );
    expect(
      const AdaptiveCurve(floor: -1, darkLux: 5, brightLux: 500).factor(1),
      0.0,
    );
  });

  test('crossed or equal ends become a step at the bright point', () {
    const crossed = AdaptiveCurve(floor: 0.2, darkLux: 500, brightLux: 5);
    expect(crossed.factor(4), 0.2);
    expect(crossed.factor(5), 1.0);
    const equal = AdaptiveCurve(floor: 0.2, darkLux: 50, brightLux: 50);
    expect(equal.factor(49), 0.2);
    expect(equal.factor(50), 1.0);
  });

  test('a zero dark point does not produce NaN', () {
    const zero = AdaptiveCurve(floor: 0.2, darkLux: 0, brightLux: 500);
    expect(zero.factor(0), 0.2);
    expect(zero.factor(1).isNaN, isFalse);
    expect(zero.factor(1), greaterThan(0.2));
  });
}
