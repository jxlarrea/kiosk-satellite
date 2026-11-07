import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/generated/ui_strings.dart';
import '../l10n/messages.dart';

/// English is the default until automatic language selection is offered.
Locale appLocaleForLanguage(String language) {
  for (final locale in UiStrings.supportedLocales) {
    if (locale.toLanguageTag() == language) return locale;
  }
  return const Locale('en');
}

/// The app's language as an intl locale name ("en", "zh_CN"), for numbers
/// and dates built from a context. Use this rather than
/// Localizations.localeOf, which returns the rendering locale: on a Chinese
/// device with an English interface that is zh, not en.
String appLocaleName(BuildContext context) => l10n(context).localeName;

/// The app's language as a BCP 47 tag ("en", "zh-CN").
String appLanguageTag(BuildContext context) =>
    appLocaleName(context).replaceAll('_', '-');

/// Preserve regional CJK glyphs when the interface uses a non-CJK language.
/// Rubik falls back to system fonts for CJK text, including device-language
/// dates and media titles. Those fonts use the paragraph locale to select
/// regional character shapes (#551, #601). The HA WebView is independent.
Locale appRenderingLocale(Locale uiLocale, List<Locale> deviceLocales) {
  const cjk = {'ja', 'ko', 'zh'};
  if (!cjk.contains(uiLocale.languageCode) &&
      deviceLocales.isNotEmpty &&
      cjk.contains(deviceLocales.first.languageCode)) {
    return basicLocaleListResolution([
      deviceLocales.first,
    ], appSupportedLocales);
  }
  return uiLocale;
}

/// Defaults for widgets that follow the inherited locale.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  MessageDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// The root app chooses messages separately from the rendering locale.
/// Bind all resources to the selected language so Flutter controls and text
/// direction follow it too. Reload even when the CJK rendering locale stays
/// the same during a live language change.
List<LocalizationsDelegate<dynamic>> appLocalizationsForUiLocale(
  Locale locale,
) => [
  _UiLocaleDelegate<UiStrings>(const MessageDelegate(), locale),
  _UiLocaleDelegate<MaterialLocalizations>(
    GlobalMaterialLocalizations.delegate,
    locale,
  ),
  _UiLocaleDelegate<WidgetsLocalizations>(
    GlobalWidgetsLocalizations.delegate,
    locale,
  ),
  _UiLocaleDelegate<CupertinoLocalizations>(
    GlobalCupertinoLocalizations.delegate,
    locale,
  ),
];

class _UiLocaleDelegate<T> extends LocalizationsDelegate<T> {
  const _UiLocaleDelegate(this.delegate, this.uiLocale);

  final LocalizationsDelegate<T> delegate;
  final Locale uiLocale;

  @override
  bool isSupported(Locale locale) => delegate.isSupported(uiLocale);

  @override
  Future<T> load(Locale locale) => delegate.load(uiLocale);

  @override
  bool shouldReload(_UiLocaleDelegate<T> old) =>
      uiLocale != old.uiLocale || delegate.shouldReload(old.delegate);
}

/// Language-only entries catch generic device locales, the region and script
/// entries keep an exact match so zh-Hant-TW is not collapsed to zh. English
/// comes first: Flutter falls back to the first entry for a language the app
/// does not ship, and the generated list sorts alphabetically, which would
/// hand an Italian device a German interface.
final List<Locale> appSupportedLocales = [
  const Locale('en'),
  for (final locale in UiStrings.supportedLocales)
    if (locale.languageCode != 'en') locale,
  const Locale('ja'),
  const Locale('ja', 'JP'),
  const Locale('ko'),
  const Locale('ko', 'KR'),
  const Locale('zh'),
  const Locale('zh', 'CN'),
  const Locale('zh', 'TW'),
  const Locale('zh', 'HK'),
  const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  const Locale.fromSubtags(
    languageCode: 'zh',
    scriptCode: 'Hant',
    countryCode: 'TW',
  ),
  const Locale.fromSubtags(
    languageCode: 'zh',
    scriptCode: 'Hant',
    countryCode: 'HK',
  ),
];
