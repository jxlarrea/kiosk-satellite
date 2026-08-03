import 'dart:io';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Locale-aware date strings for every date the app shows (issue #108).
///
/// The clock screensaver and the Immich metadata rows used to compose dates
/// from hardcoded English name arrays, so a Dutch device read
/// "Sunday, August 1" where it expected "zondag 1 augustus". These helpers
/// format through CLDR data in the device's locale instead, which localizes
/// the names AND the word order in one move.
///
/// Only the device's own locale is loaded (not the full CLDR set): these
/// run on low-RAM kiosks, and en_US is compiled into intl as the fallback.
Future<void> initLocaleDates() async {
  final locale = Intl.canonicalizedLocale(Platform.localeName);
  try {
    await initializeDateFormatting(locale);
    Intl.defaultLocale = locale;
  } catch (_) {
    // No CLDR data for this locale: stay on the en_US built-ins rather
    // than fail startup over a date string.
  }
}

/// "Sunday, August 2" / "zondag 2 augustus" (the clock screensaver).
String fullDate(DateTime date) =>
    _safe((locale) => DateFormat.MMMMEEEEd(locale), date);

/// "Sun, Aug 2" / "zo 2 aug" (the compact clock variant).
String shortDate(DateTime date) =>
    _safe((locale) => DateFormat.MMMEd(locale), date);

/// "August 2, 2026" / "2 augustus 2026" (Immich photo metadata).
String longDate(DateTime date) =>
    _safe((locale) => DateFormat.yMMMMd(locale), date);

String _safe(DateFormat Function(String?) make, DateTime date) {
  try {
    return make(null).format(date); // null reads Intl.defaultLocale
  } catch (_) {
    return make('en_US').format(date);
  }
}
