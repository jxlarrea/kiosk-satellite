import 'dart:async';
import 'dart:io';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Locale-aware date strings for every date the app shows (issue #108).
///
/// The clock screensaver and the Immich metadata rows used to compose dates
/// from hardcoded English name arrays, so a Dutch device read
/// "Sunday, August 1" where it expected "zondag 1 augustus". These helpers
/// format through CLDR data in the app's language instead, which localizes
/// the names AND the word order in one move.
///
/// Points every DateFormat and NumberFormat built without a locale at the
/// app's [language] (a picker tag such as "nl" or "zh-CN"), so dates, day
/// names and numbers read in the language the interface uses, not the
/// Android one. Called once settings load and on every language change.
///
/// The CLDR data for every locale ships compiled into intl. Loading it only
/// fills its tables, runs synchronously and happens once.
void applyAppDateLanguage(String language) {
  unawaited(initializeDateFormatting());
  Intl.defaultLocale = appDateLocale(language, Platform.localeName);
}

/// The intl locale for the app's [language]. When the Android locale
/// [device] speaks the same language, its region is kept, so English on a
/// British device still writes "Sunday 2 August". The language always comes
/// from the app.
String appDateLocale(String language, String device) {
  final app = Intl.canonicalizedLocale(language);
  final base = app.split('_').first;
  final local = Intl.canonicalizedLocale(device);
  if (app == base &&
      local.split('_').first == base &&
      DateFormat.localeExists(local)) {
    return local;
  }
  if (DateFormat.localeExists(app)) return app;
  if (DateFormat.localeExists(base)) return base;
  return 'en_US';
}

/// The first day of the week in the date locale, 0 = Sunday: Monday for
/// English on a British device, Sunday on an American one. Material's own
/// value reads the same CLDR data but only for the bare app language.
int localeFirstWeekday() {
  try {
    // CLDR counts from Monday.
    return (DateFormat().dateSymbols.FIRSTDAYOFWEEK + 1) % 7;
  } catch (_) {
    return 0;
  }
}

/// A 12-hour time in the date locale, even in a language that writes 24
/// hours by default: "4:05 PM", "4:05 p. m.", or "下午4:05" with the period
/// first where the language puts it there. [short] drops the minutes:
/// "4 PM".
DateFormat twelveHourFormat({bool short = false}) {
  final periodFirst = const {
    'zh',
    'ja',
    'ko',
  }.contains(Intl.getCurrentLocale().split(RegExp('[_-]')).first);
  if (short) return DateFormat(periodFirst ? 'ah时' : 'h a');
  return DateFormat(periodFirst ? 'ah:mm' : 'h:mm a');
}

/// "Sunday, August 2" / "zondag 2 augustus" (the clock screensaver).
String fullDate(DateTime date) =>
    _safe((locale) => DateFormat.MMMMEEEEd(locale), date);

/// "Sun, Aug 2" / "zo 2 aug" (the compact clock variant).
String shortDate(DateTime date) =>
    _safe((locale) => DateFormat.MMMEd(locale), date);

/// "Sunday" / "zondag" (the Up next widget's later days).
String weekdayName(DateTime date) =>
    _safe((locale) => DateFormat.EEEE(locale), date);

/// "Sun" / "zo" (the Weather forecast widget's rows).
String shortWeekdayName(DateTime date) =>
    _safe((locale) => DateFormat.E(locale), date);

/// "August 2, 2026" / "2 augustus 2026" (Immich photo metadata).
String longDate(DateTime date) =>
    _safe((locale) => DateFormat.yMMMMd(locale), date);

/// "Sun, Aug 2 2:32:05 PM" / "zo 2 aug 14:32:05" (wake word activations,
/// where the seconds tell two close triggers apart).
String shortDateTime(DateTime date) =>
    _safe((locale) => DateFormat.MMMEd(locale).add_jms(), date);

String _safe(DateFormat Function(String?) make, DateTime date) {
  try {
    return make(null).format(date); // null reads Intl.defaultLocale
  } catch (_) {
    return make('en_US').format(date);
  }
}
