import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/app_locales.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings.dart';
import 'package:kiosk_satellite/l10n/messages.dart';
import 'package:kiosk_satellite/main.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/ui/kit.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The catalogs the picker offers. gen-l10n also needs a base fallback such
/// as zh next to zh-CN, but that fallback is not a choice.
List<String> pickerLanguageTags() => [
  for (final locale in UiStrings.supportedLocales)
    if (locale.countryCode != null ||
        !UiStrings.supportedLocales.any(
          (other) =>
              other.languageCode == locale.languageCode &&
              other.countryCode != null,
        ))
      locale.toLanguageTag(),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'language is first in User Interface and only offers bundled catalogs',
    () {
      final group = allSettings
          .where(
            (def) =>
                def.category == 'Device' && def.section == 'User Interface',
          )
          .toList();
      expect(group.first, uiLanguage);
      expect(uiLanguage.perDevice, isTrue);
      expect(uiLanguage.options, unorderedEquals(pickerLanguageTags()));
      expect(uiLanguage.optionLabels!['es'], 'Español');
      expect(uiLanguage.optionLabels!['de'], 'Deutsch');
      expect(uiLanguage.optionLabels!['fr'], 'Français');
      expect(uiLanguage.optionLabels!['nl'], 'Nederlands');
      expect(uiLanguage.optionLabels!['pl'], 'Polski');
      expect(uiLanguage.optionLabels!['ru'], 'Русский');
      expect(uiLanguage.optionLabels!['uk'], 'Українська');
      expect(uiLanguage.optionLabels!['zh-CN'], '简体中文');
      expect(appLocaleForLanguage('nl'), const Locale('nl'));
      expect(appLocaleForLanguage('pl'), const Locale('pl'));
      expect(appLocaleForLanguage('ru'), const Locale('ru'));
      expect(appLocaleForLanguage('uk'), const Locale('uk'));
      expect(appLocaleForLanguage('zh-CN'), const Locale('zh', 'CN'));
      expect(appLocaleForLanguage('de'), const Locale('de'));
      expect(appLocaleForLanguage('fr'), const Locale('fr'));
      expect(appLocaleForLanguage('es'), const Locale('es'));
      expect(uiLanguage.defaultValue, 'en');
      expect(appLocaleForLanguage('system'), const Locale('en'));
      expect(appLocaleForLanguage('not-installed'), const Locale('en'));
    },
  );

  for (final saved in ['system', 'es']) {
    test(
      'saved language $saved migrates without overwriting an explicit choice',
      () async {
        SharedPreferences.setMockInitialValues({'ks.ui.language': saved});
        final container = AppContainer();
        try {
          await container.settings.init();
          final expected = saved == 'system' ? 'en' : saved;
          expect(container.settings.get(uiLanguage), expected);
          expect(
            (await SharedPreferences.getInstance()).getString('ks.ui.language'),
            expected,
          );
        } finally {
          await container.settings.dispose();
          await container.bus.dispose();
          await container.log.dispose();
        }
      },
    );
  }

  for (final deviceLocale in const [
    Locale('ja', 'JP'),
    Locale('ko', 'KR'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hant',
      countryCode: 'TW',
    ),
    Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hant',
      countryCode: 'HK',
    ),
  ]) {
    testWidgets(
      'language changes preserve $deviceLocale glyphs on an open route',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final container = AppContainer();
        await container.settings.init();
        tester.platformDispatcher.localesTestValue = [deviceLocale];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        const background = MethodChannel('kiosk_satellite/background');
        messenger.setMockMethodCallHandler(background, (call) async {
          if (call.method == 'serviceStatus') {
            return <String, Object?>{
              'running': true,
              'foreground': true,
              'types': ['specialUse'],
              'uptimeMs': 5000,
            };
          }
          return true;
        });
        const info = MethodChannel('dev.fluttercommunity.plus/device_info');
        messenger.setMockMethodCallHandler(
          info,
          (call) async => throw PlatformException(code: 'test'),
        );
        addTearDown(() async {
          messenger.setMockMethodCallHandler(background, null);
          messenger.setMockMethodCallHandler(info, null);
          await container.settings.dispose();
          await container.bus.dispose();
          await container.log.dispose();
        });
        await tester.pumpWidget(KioskSatelliteApp(container: container));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        late BuildContext routeContext;
        navigator.push(
          MaterialPageRoute<void>(
            builder: (context) {
              routeContext = context;
              return Scaffold(
                body: Column(
                  children: [
                    Text(l10n(context).commonNext),
                    const Text('骨 直 令'),
                    SettingTile(
                      container: container,
                      def: uiLanguage,
                      onChanged: () {},
                    ),
                  ],
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();
        void expectLanguage(String language, Locale glyphLocale) {
          final label = language == 'es' ? 'Siguiente' : 'Next';
          expect(find.text(label), findsOneWidget);
          expect(l10n(routeContext).localeName, language);
          expect(Localizations.localeOf(routeContext), glyphLocale);
          for (final text in [label, '骨 直 令']) {
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(
                of: find.text(text),
                matching: find.byType(RichText),
              ),
            );
            expect(paragraph.locale, glyphLocale);
          }
          expect(
            MaterialLocalizations.of(routeContext).cancelButtonLabel,
            language == 'es' ? 'Cancelar' : 'Cancel',
          );
          expect(
            CupertinoLocalizations.of(routeContext).copyButtonLabel,
            language == 'es' ? 'Copiar' : 'Copy',
          );
          expect(Directionality.of(routeContext), TextDirection.ltr);
        }

        expectLanguage('en', deviceLocale);
        final row = tester.widget<DropdownRow<String>>(
          find.byType(DropdownRow<String>),
        );
        row.onChanged!('es');
        await tester.pumpAndSettle();
        expectLanguage('es', deviceLocale);
        expect(container.settings.get(uiLanguage), 'es');
        expect(
          (await SharedPreferences.getInstance()).getString('ks.ui.language'),
          'es',
        );
        expect(
          await container.settings.setFromJson(
            'ui.language',
            'en',
            source: 'remote',
          ),
          isTrue,
        );
        await tester.pumpAndSettle();
        expectLanguage('en', deviceLocale);
        expect(
          await container.settings.setFromJson('ui.language', 'unavailable'),
          isFalse,
        );
        expect(container.settings.get(uiLanguage), 'en');
        expect(
          await container.settings.setFromJson('ui.language', 'system'),
          isFalse,
        );
        await tester.pumpAndSettle();
        expectLanguage('en', deviceLocale);
        tester.platformDispatcher.localesTestValue = [const Locale('es', 'EC')];
        await tester.pumpAndSettle();
        expectLanguage('en', const Locale('en'));
        await container.settings.setFromJson(
          'ui.language',
          'es',
          source: 'remote',
        );
        await tester.pumpAndSettle();
        expectLanguage('es', const Locale('es'));
        tester.platformDispatcher.localesTestValue = [deviceLocale];
        await tester.pumpAndSettle();
        expectLanguage('es', deviceLocale);
        final definition = container.settings.describe().firstWhere(
          (def) => def['key'] == 'ui.language',
        );
        expect(definition['options'], unorderedEquals(pickerLanguageTags()));
        expect((definition['optionLabels'] as Map)['es'], 'Español');
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
