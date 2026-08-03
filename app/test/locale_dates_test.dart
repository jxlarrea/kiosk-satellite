import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:kiosk_satellite/core/locale_dates.dart';

void main() {
  // A Sunday, matching the example in issue #108.
  final sunday = DateTime(2026, 8, 2);

  test('dates default to English formatting', () {
    expect(fullDate(sunday), 'Sunday, August 2');
    expect(shortDate(sunday), 'Sun, Aug 2');
    expect(longDate(sunday), 'August 2, 2026');
  });

  test('dates follow a non-English locale, names and order both', () async {
    await initializeDateFormatting('nl');
    await Intl.withLocale('nl', () async {
      expect(fullDate(sunday), 'zondag 2 augustus');
      expect(shortDate(sunday), 'zo 2 aug');
      expect(longDate(sunday), '2 augustus 2026');
    });
  });

  test('an unknown locale falls back to English instead of throwing', () {
    Intl.withLocale('xx_XX', () {
      expect(fullDate(sunday), 'Sunday, August 2');
    });
  });
}
