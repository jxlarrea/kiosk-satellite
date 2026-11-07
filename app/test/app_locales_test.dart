import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/app_locales.dart';

/// Issue #551: the resolved locale drives which CJK fallback face the engine
/// draws with, so a device locale has to survive resolution instead of being
/// collapsed to en_US or to a bare language.
void main() {
  test('rendering follows the UI unless the primary device locale is CJK', () {
    const spanish = Locale('es');
    expect(appRenderingLocale(spanish, []), spanish);
    expect(
      appRenderingLocale(spanish, const [
        Locale('en', 'US'),
        Locale('ja', 'JP'),
      ]),
      spanish,
    );
    // A future CJK interface language must retain its own character shapes.
    const japanese = Locale('ja', 'JP');
    expect(appRenderingLocale(japanese, const [Locale('zh', 'CN')]), japanese);
  });

  Future<Locale> resolve(WidgetTester tester, Locale device) async {
    tester.platformDispatcher.localesTestValue = [device];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    late Locale seen;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: Builder(
          builder: (context) {
            seen = Localizations.localeOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return seen;
  }

  testWidgets('Japanese device keeps ja_JP', (tester) async {
    expect(
      await resolve(tester, const Locale('ja', 'JP')),
      const Locale('ja', 'JP'),
    );
  });

  testWidgets('Korean device keeps ko_KR', (tester) async {
    expect(
      await resolve(tester, const Locale('ko', 'KR')),
      const Locale('ko', 'KR'),
    );
  });

  testWidgets('Traditional Chinese keeps its script', (tester) async {
    final tw = await resolve(
      tester,
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      ),
    );
    expect(tw.scriptCode, 'Hant');
    expect(tw.countryCode, 'TW');
    final hk = await resolve(
      tester,
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'HK',
      ),
    );
    expect(hk.scriptCode, 'Hant');
    expect(hk.countryCode, 'HK');
  });

  testWidgets('Simplified Chinese with a script resolves to Hans', (
    tester,
  ) async {
    final cn = await resolve(
      tester,
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'CN',
      ),
    );
    expect(cn.languageCode, 'zh');
    expect(cn.scriptCode ?? cn.countryCode, isNotNull);
  });

  testWidgets('Other languages fall back to English as before', (tester) async {
    expect(await resolve(tester, const Locale('it', 'IT')), const Locale('en'));
    expect(await resolve(tester, const Locale('sv')), const Locale('en'));
  });

  testWidgets('the app language wins over a CJK rendering locale', (
    tester,
  ) async {
    // English interface on a Chinese device: the root renders as zh for
    // its glyphs, but numbers and dates must stay English.
    tester.platformDispatcher.localesTestValue = [const Locale('zh', 'CN')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    const ui = Locale('en');
    late Locale rendering;
    late String name;
    late String tag;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsForUiLocale(ui),
        supportedLocales: appSupportedLocales,
        locale: appRenderingLocale(ui, const [Locale('zh', 'CN')]),
        home: Builder(
          builder: (context) {
            rendering = Localizations.localeOf(context);
            name = appLocaleName(context);
            tag = appLanguageTag(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(rendering.languageCode, 'zh');
    expect(name, 'en');
    expect(tag, 'en');
  });

  testWidgets('a regional app language reads as a tag', (tester) async {
    const ui = Locale('zh', 'CN');
    late String tag;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsForUiLocale(ui),
        supportedLocales: appSupportedLocales,
        locale: ui,
        home: Builder(
          builder: (context) {
            tag = appLanguageTag(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tag, 'zh-CN');
  });
}
