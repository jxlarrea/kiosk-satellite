import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/device/device_details.dart';

/// The one gate every battery consumer reads through (issue #367): the
/// sentinel Android answers for a battery the kernel does not expose never
/// becomes a percent, and the real range stays intact.
void main() {
  test('the valid range passes through untouched', () {
    for (final v in [0, 1, 50, 100]) {
      expect(batteryPercent(v), v, reason: '$v');
    }
    expect(batteryPercent(73.0), 73);
  });

  test('sentinels and out-of-range values read as no battery', () {
    // BatteryManager.getIntProperty for an unsupported property: MIN_VALUE
    // on targets from Android 9, 0 before (which the range cannot tell
    // from a flat battery, so the native presence flag covers that case).
    expect(batteryPercent(-2147483648), isNull);
    // The plugin's own sentinel.
    expect(batteryPercent(-1), isNull);
    expect(batteryPercent(101), isNull);
    expect(batteryPercent(null), isNull);
    expect(batteryPercent('50'), isNull);
  });
}
