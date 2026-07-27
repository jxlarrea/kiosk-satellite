import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/clock_faces.dart';

void main() {
  group('flipBackdrop', () {
    test('a bright card gets a darker backdrop', () {
      final card = const Color(0xFFF5F5F5);
      final bg = flipBackdrop(card);
      expect(bg.computeLuminance(), lessThan(card.computeLuminance()));
    });

    test('a dark card gets a lighter backdrop', () {
      final card = const Color(0xFF1A1A2E);
      final bg = flipBackdrop(card);
      expect(bg.computeLuminance(), greaterThan(card.computeLuminance()));
    });

    test('extremes stay in range', () {
      expect(flipBackdrop(const Color(0xFFFFFFFF)).computeLuminance(),
          lessThan(1.0));
      expect(flipBackdrop(const Color(0xFF000000)).computeLuminance(),
          greaterThan(0.0));
    });
  });
  group('rollerProgress', () {
    test('minute and hour digits reflect elapsed fraction of their period',
        () {
      final p = rollerProgress(DateTime(2026, 7, 27, 9, 52, 30), true);
      // Hour tens: '0' holds from 00:00 to 10:00 in 24h mode.
      expect(p[0], closeTo((9 * 3600 + 52 * 60 + 30) / (10 * 3600), 1e-9));
      // Hour ones: 52m30s into its hour.
      expect(p[1], closeTo((52 * 60 + 30) / 3600, 1e-9));
      // Minute tens: 2m30s into its ten minutes.
      expect(p[2], closeTo((2 * 60 + 30) / 600, 1e-9));
      // Minute ones: half a minute in.
      expect(p[3], closeTo(0.5, 1e-9));
    });

    test('a digit that just changed starts at zero', () {
      final p = rollerProgress(DateTime(2026, 7, 27, 10, 0, 0), true);
      expect(p, everyElement(closeTo(0, 1e-9)));
    });

    test('a digit about to change approaches one', () {
      final p = rollerProgress(DateTime(2026, 7, 27, 9, 59, 59), true);
      // The coarsest wheel here is the minute-ones digit, whose last whole
      // second sits at 59/60.
      for (final v in p) {
        expect(v, greaterThan(0.98));
        expect(v, lessThan(1.0));
      }
    });

    test('24h hour tens knows its irregular late-night period', () {
      // '2' holds from 20:00 to 00:00 — a 4 hour period, not 10.
      final p = rollerProgress(DateTime(2026, 7, 27, 23, 0, 0), true);
      expect(p[0], closeTo(3 / 4, 1e-9));
    });

    test('12h hour tens follows the display digit, not the raw hour', () {
      // Displayed 09: its tens digit '0' has held since 01:00 and flips to
      // '1' at 10:00 — a 9 hour period, 8 hours in.
      final p = rollerProgress(DateTime(2026, 7, 27, 9, 0, 0), false);
      expect(p[0], closeTo(8 / 9, 1e-9));
      // 11:59 PM: the tens '1' holds through midnight (12 AM keeps it), so
      // it is nowhere near a change.
      final q = rollerProgress(DateTime(2026, 7, 27, 23, 59, 0), false);
      expect(q[0], lessThan(0.9));
    });
  });
}
