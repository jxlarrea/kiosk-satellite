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

  group('the app language picks the date locale', () {
    setUpAll(initializeDateFormatting);
    tearDown(() => Intl.defaultLocale = null);

    test('the app language wins over the Android one', () {
      expect(appDateLocale('nl', 'en_US'), 'nl');
      expect(appDateLocale('en', 'de_DE'), 'en');
      expect(appDateLocale('zh-CN', 'en_US'), 'zh_CN');
    });

    test('a device in the same language keeps its region', () {
      expect(appDateLocale('en', 'en_GB'), 'en_GB');
      expect(appDateLocale('es', 'es_MX'), 'es_MX');
      // A regional app language is already specific.
      expect(appDateLocale('zh-CN', 'zh_TW'), 'zh_CN');
    });

    test('a device language the app does not offer keeps the dates', () {
      expect(appDateLocale('en', 'cs_CZ'), 'cs');
      expect(appDateLocale('en', 'it_IT'), 'it');
      expect(appDateLocale('de', 'pt_BR'), 'pt_BR');
      // Chinese is offered, so a Taiwanese device keeps the app language.
      expect(appDateLocale('en', 'zh_TW'), 'en');
    });

    test('a Czech device with an English interface writes Czech dates', () {
      applyAppDateLanguage('en');
      expect(
        Intl.withLocale(appDateLocale('en', 'cs_CZ'), () => fullDate(sunday)),
        'neděle 2. srpna',
      );
    });

    test('an unknown device locale falls back to the app language', () {
      expect(appDateLocale('fr', 'fr_XX'), 'fr');
      expect(appDateLocale('xx', 'en_US'), 'en_US');
    });

    test('applying a language sets the default for every format', () {
      applyAppDateLanguage('nl');
      expect(Intl.defaultLocale, startsWith('nl'));
      expect(fullDate(sunday), 'zondag 2 augustus');
      applyAppDateLanguage('de');
      expect(Intl.defaultLocale, startsWith('de'));
      expect(fullDate(sunday), 'Sonntag, 2. August');
    });

    test('the week starts where the date locale starts it', () {
      Intl.defaultLocale = appDateLocale('en', 'en_US');
      expect(localeFirstWeekday(), 0);
      // The region decides it for English.
      Intl.defaultLocale = appDateLocale('en', 'en_GB');
      expect(localeFirstWeekday(), 1);
      Intl.defaultLocale = appDateLocale('es', 'en_US');
      expect(localeFirstWeekday(), 1);
    });
  });
}
