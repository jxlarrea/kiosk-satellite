import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/app_locales.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings_en.dart';
import 'package:kiosk_satellite/l10n/messages.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_manager.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_repository.dart';
import 'package:kiosk_satellite/ui/plugin_settings.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RejectedRepository extends PluginRepository {
  int requests = 0;
  @override
  Future<Map<String, Object?>> preview(String input) async {
    requests++;
    throw StateError(
      'GitHub denied the request or its request limit was reached. Try again later.',
    );
  }
}

class _Spanish extends UiStringsEn {
  @override
  String get pluginErrorGithubLimited =>
      'GitHub rechazó la solicitud. Inténtalo más tarde.';
  @override
  String pluginErrorAndroidApi(String version) =>
      'El plugin necesita la API $version de Android';
  @override
  String launcherErrorListDetail(String error) =>
      'No se pudo obtener la lista: $error';
  @override
  String pluginErrorAssetPublisher(String name) =>
      'GitHub Actions debe publicar $name';
}

class _Delegate extends LocalizationsDelegate<UiStrings> {
  const _Delegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<UiStrings> load(Locale locale) => SynchronousFuture(_Spanish());
  @override
  bool shouldReload(_Delegate old) => false;
}

Widget app(Widget child) => MaterialApp(
  locale: const Locale('es'),
  supportedLocales: const [Locale('en'), Locale('es')],
  localizationsDelegates: const [_Delegate(), ...appLocalizationsDelegates],
  home: Scaffold(body: child),
);
void main() {
  testWidgets(
    'known plugin errors translate without changing file names or diagnostics',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(
        pluginError(
          context,
          'FormatException: Release asset <original>.zip must be published by GitHub Actions. Manually uploaded files are not supported.',
        ),
        'GitHub Actions debe publicar <original>.zip',
      );
      expect(
        pluginError(
          context,
          'PlatformException(plugin_error, Plugin needs Android API 35, null, null)',
        ),
        'PlatformException(plugin_error, El plugin necesita la API 35 de Android, null, null)',
      );
      for (final raw in [
        'Bad state: Community failure',
        'Invalid arbitrary field',
        'PlatformException(code, original, {errno: 32}, null)',
      ]) {
        expect(pluginError(context, raw), raw);
        expect(launcherError(context, raw), raw);
      }
    },
  );
  testWidgets(
    'native app picker localizes a failed list without changing saved apps',
    (tester) async {
      SharedPreferences.setMockInitialValues({'ks.launcher.enabled': true});
      final c = AppContainer();
      await c.settings.init();
      var requests = 0;
      c.commands.register(
        Command(
          name: 'installedApps',
          description: 'fixture',
          handler: (_) async {
            requests++;
            return const CommandResult.fail(
              'could not list apps: E_VENDOR <details>',
            );
          },
        ),
      );
      addTearDown(() async {
        await c.settings.dispose();
        await c.bus.dispose();
        await c.log.dispose();
      });
      await tester.pumpWidget(
        app(
          CategorySettingsScreen(
            container: c,
            title: 'Launcher',
            category: 'Launcher',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final row = find.text('Apps');
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(
        find.text('No se pudo obtener la lista: E_VENDOR <details>'),
        findsOneWidget,
      );
      expect(requests, 1);
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'native plugin repository rate limit uses Spanish and never installs',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final c = AppContainer();
      await c.settings.init();
      final methods = <String>[];
      final repository = _RejectedRepository();
      final plugins = PluginManager(
        c.bus,
        c.commands,
        c.log,
        repository: repository,
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(PluginManager.channel, (call) async {
        methods.add(call.method);
        return {'plugins': <Object?>[], 'enabled': true};
      });
      await plugins.init();
      plugins.stopUpdateChecks();
      await plugins.refresh();
      addTearDown(() async {
        messenger.setMockMethodCallHandler(PluginManager.channel, null);
        await plugins.dispose();
        await c.settings.dispose();
        await c.bus.dispose();
        await c.log.dispose();
      });
      await tester.pumpWidget(
        app(
          SingleChildScrollView(
            child: PluginSettingsPanel(plugins: plugins, onOpen: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final add = find.text('Add plugin');
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.enterText(
        find.byType(TextField),
        'https://github.com/example/example',
      );
      await tester.tap(find.text('Preview'));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        find.text('GitHub rechazó la solicitud. Inténtalo más tarde.'),
        findsOneWidget,
      );
      expect(repository.requests, 1);
      expect(methods.where((m) => m.contains('install')), isEmpty);
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
