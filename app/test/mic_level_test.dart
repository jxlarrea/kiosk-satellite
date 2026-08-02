import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/mic_level_meter.dart';

void main() {
  group('micLevelFraction', () {
    test('silence and the -60 dBFS floor render dark', () {
      expect(micLevelFraction(0), 0);
      expect(micLevelFraction(0.001), closeTo(0, 0.001));
    });

    test('-6 dBFS and above fill the meter', () {
      expect(micLevelFraction(0.5), closeTo(1, 0.001));
      expect(micLevelFraction(1.0), 1);
    });

    test('the 0.05 RMS gain target tops out the green segments', () {
      // The gain hint tells users to aim for ~0.05 RMS; that must land
      // exactly at the last green segment so "top of the green" is true.
      final lit = (micLevelFraction(0.05) * micMeterSegments).round();
      expect(lit, 15);
    });

    test('monotonic in rms', () {
      var prev = -1.0;
      for (final rms in [0.0, 0.002, 0.01, 0.05, 0.1, 0.3, 0.6]) {
        final f = micLevelFraction(rms);
        expect(f, greaterThanOrEqualTo(prev));
        prev = f;
      }
    });
  });
}
