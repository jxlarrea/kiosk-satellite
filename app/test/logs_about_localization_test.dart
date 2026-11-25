import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/app_locales.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings_en.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:kiosk_satellite/ui/web_console_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Messages extends UiStringsEn {
  @override
  String settingsMadeBy(String heart, String author) => '$author con $heart';
  @override
  String get settingsBuyCoffee => 'Invítame a un café';
  @override
  String get aboutAttribution => 'Créditos';
  @override
  String get aboutVersion => 'Versión de la aplicación';
  @override
  String get logsErrors => 'Errores y fallos';
  @override
  String get logsInfo => 'Información y depuración';
  @override
  String get logsInput => 'Ejecutar JavaScript en la página';
  @override
  String get logsCopyLog => 'Copiar registro';
  @override
  String get commonRefresh => 'Actualizar';
  @override
  String get logsWebConsole => 'Consola web';
  @override
  String logsReadFailed(String error) => 'No se pudo leer Logcat: $error';
}

class _Delegate extends LocalizationsDelegate<UiStrings> {
  const _Delegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<UiStrings> load(Locale locale) => SynchronousFuture(
    locale.languageCode == 'es' ? _Messages() : UiStringsEn(),
  );
  @override
  bool shouldReload(_Delegate old) => false;
}

void main() {
  late AppContainer container;
  late ValueNotifier<Locale> language;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = AppContainer();
    container.device.appVersion = '2026.9.59-RAW';
    container.device.buildNumber = '258';
    container.device.packageName = 'me.jxl.kiosk_satellite';
    await container.settings.init();
    language = ValueNotifier(const Locale('es'));
  });
  tearDown(() async {
    language.dispose();
    await container.settings.dispose();
    await container.bus.dispose();
    await container.log.dispose();
  });
  Widget app(Widget child) => ValueListenableBuilder<Locale>(
    valueListenable: language,
    builder: (_, locale, _) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('es')],
      localizationsDelegates: const [_Delegate(), ...appLocalizationsDelegates],
      home: child,
    ),
  );
  Widget page(String category) => CategorySettingsScreen(
    container: container,
    title: category,
    category: category,
  );

  for (final tag in [
    'fr',
    if (UiStrings.supportedLocales.contains(const Locale('de'))) 'de',
    'it',
    'nl',
    'uk',
  ]) {
    final credit = {
      'de': 'Dee-san',
      'fr': 'Limoniak',
      'it': 'spita90',
      'nl': 'rononline',
      'uk': 'kdinya',
    }[tag]!;
    final title = lookupUiStrings(Locale(tag)).aboutLocalizationCredits;
    testWidgets(
      '$tag credits opens by language and follows live locale changes',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        language.value = Locale(tag);
        await tester.pumpWidget(
          ValueListenableBuilder<Locale>(
            valueListenable: language,
            builder: (_, locale, _) => MaterialApp(
              locale: locale,
              supportedLocales: UiStrings.supportedLocales,
              localizationsDelegates: appLocalizationsDelegates,
              home: page('About'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final entry = find.text(title);
        final tile = tester.widget<ListTile>(
          find.ancestor(of: entry, matching: find.byType(ListTile)),
        );
        // The row wears its hint in the page's language, like every other
        // page entry.
        expect(
          (tile.subtitle! as Text).data,
          lookupUiStrings(Locale(tag)).aboutLocalizationCreditsHint,
        );
        final notice = find.text(
          lookupUiStrings(Locale(tag)).aboutLicenseSummary,
        );
        expect(
          tester.getTopLeft(entry).dy,
          lessThan(tester.getTopLeft(notice).dy),
        );
        await tester.ensureVisible(entry);
        await tester.pumpAndSettle();
        await tester.tap(entry);
        await tester.pumpAndSettle();
        for (final name in ['English', 'Español', 'Français']) {
          expect(find.text(name), findsOneWidget);
        }
        expect(find.text(credit), findsNWidgets(2));
        expect(find.byIcon(Icons.favorite), findsOneWidget);
        expect(
          find.text(lookupUiStrings(Locale(tag)).settingsBuyCoffee),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        language.value = const Locale('en');
        await tester.pumpAndSettle();
        expect(find.text('Localization Credits'), findsOneWidget);
        expect(find.text('Buy me a coffee'), findsOneWidget);
        expect(find.text(credit), findsNWidgets(2));
        language.value = Locale(tag);
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        final profile = find.widgetWithText(TextButton, credit);
        await tester.ensureVisible(profile);
        await tester.pumpAndSettle();
        await tester.tap(profile);
        await tester.pumpAndSettle();
        expect(
          container.browser.overlayUrl.value,
          'https://github.com/$credit',
        );
        expect(find.text(credit), findsNothing);
        expect(find.text(title), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('About preserves attribution and links at narrow widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(page('About')));
    await tester.pumpAndSettle();
    expect(find.text('Créditos'), findsOneWidget);
    expect(find.text('Xavier Larrea'), findsNWidgets(2));
    expect(find.text('CC BY-NC-ND 4.0'), findsOneWidget);
    final author = find.text('Xavier Larrea').last;
    final heart = find.byIcon(Icons.favorite);
    await tester.ensureVisible(author);
    expect(tester.getTopLeft(author).dx, lessThan(tester.getTopLeft(heart).dx));
    expect(find.text('Invítame a un café'), findsOneWidget);
    await tester.tap(author);
    expect(container.browser.overlayUrl.value, 'https://github.com/jxlarrea');
    await tester.tap(find.text('Invítame a un café'));
    expect(
      container.browser.overlayUrl.value,
      'https://buymeacoffee.com/jxlarrea',
    );
    expect(container.browser.overlayDismissible.value, isTrue);
    language.value = const Locale('en');
    await tester.pumpAndSettle();
    expect(find.text('Attribution'), findsOneWidget);
    expect(find.text('Buy me a coffee'), findsOneWidget);
    expect(tester.getTopLeft(heart).dx, lessThan(tester.getTopLeft(author).dx));
    expect(find.text('Xavier Larrea'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Logcat keeps filters and original copied lines across locale changes',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const raw =
          '09-17 12:01:02.000 E/Raw: Original error\n'
          '  original stack trace\n09-17 12:01:03.000 I/Raw: Original info';
      var reads = 0;
      container.commands.register(
        Command(
          name: 'getLogcat',
          description: '',
          handler: (_) async {
            reads++;
            return CommandResult.ok(raw);
          },
        ),
      );
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(app(page('Logs')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logcat'));
      await tester.pumpAndSettle();
      expect(reads, 1);
      expect(find.text('  original stack trace'), findsOneWidget);
      expect(
        find.text('09-17 12:01:03.000 I/Raw: Original info'),
        findsNothing,
      );
      await tester.tap(find.text('Información y depuración'));
      await tester.pumpAndSettle();
      language.value = const Locale('en');
      await tester.pumpAndSettle();
      expect(
        find.text('09-17 12:01:03.000 I/Raw: Original info'),
        findsOneWidget,
      );
      expect(reads, 1);
      await tester.tap(find.byTooltip('Copy log'));
      await tester.pumpAndSettle();
      expect(copied, raw);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Logcat failure translates again while retaining technical detail',
    (tester) async {
      container.commands.register(
        Command(
          name: 'getLogcat',
          description: '',
          handler: (_) async => CommandResult.fail('RAW_ERROR'),
        ),
      );
      await tester.pumpWidget(app(page('Logs')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logcat'));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo leer Logcat: RAW_ERROR'), findsOneWidget);
      language.value = const Locale('en');
      await tester.pumpAndSettle();
      expect(find.text('Could not read logcat: RAW_ERROR'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Docked console keeps typed JavaScript and raw output on language changes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      container.browser.onConsoleMessage('log', '<b>Original result</b>');
      await tester.pumpWidget(
        app(
          Scaffold(
            body: WebConsolePanel(browser: container.browser, onClose: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      const code = 'window.rawName = "Keep this value"';
      await tester.enterText(find.byType(TextField), code);
      language.value = const Locale('en');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        code,
      );
      expect(
        find.textContaining('<b>Original result</b>', findRichText: true),
        findsOneWidget,
      );
      language.value = const Locale('es');
      await tester.pumpAndSettle();
      expect(find.text('Consola web'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.hintText,
        'Ejecutar JavaScript en la página',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
