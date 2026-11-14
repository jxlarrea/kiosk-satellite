import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_directory.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_manager.dart';
import 'package:kiosk_satellite/ui/plugin_directory.dart';
import 'package:kiosk_satellite/ui/plugin_settings.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Browse plugins sits first on the Plugin Manager page and lists Community
/// Plugins. Mirrored on the remote (plugin_directory_remote_ui_test.py).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('Browse plugins opens from the Plugin Manager page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      PluginManager.channel,
      (call) async => {'enabled': true, 'plugins': <Object?>[]},
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(PluginManager.channel, null),
    );
    final container = AppContainer();
    await container.settings.init();
    container.plugins.enabled.value = true;
    tester.view.physicalSize = const Size(500, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(container: container)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Plugin Manager').first);
    await settle(tester);
    final browse = find.text('Browse plugins');
    expect(browse, findsOneWidget);
    expect(
      tester.getTopLeft(browse).dy,
      lessThan(tester.getTopLeft(find.text('Add plugin')).dy),
    );
    await tester.tap(browse);
    await settle(tester);
    expect(find.text('Search plugins'), findsOneWidget);
    expect(find.text('Submit your plugin'), findsOneWidget);
  });

  testWidgets('lists plugins by popularity and filters them', (tester) async {
    final body = jsonEncode({
      'schemaVersion': 1,
      'plugins': [
        for (final (id, name, downloads) in [
          ('quiet', 'Quiet Clock', 2),
          ('weather', 'Weather Mood', 40),
        ])
          {
            'id': id,
            'name': name,
            'description': '$name for the kiosk.',
            'author': 'Alice',
            'owner': id == 'weather' ? 'weather-labs' : 'alice',
            'version': '1.0.0',
            'repository': 'https://github.com/alice/$id',
            'stars': 1,
            'downloads': downloads,
            'status': 'ok',
          },
      ],
    });
    final plugins = PluginManager(
      EventBus(),
      CommandRegistry(Logger()),
      Logger(),
      directory: PluginDirectory(
        clientFactory: () => MockClient((_) async => http.Response(body, 200)),
        cacheFile: () async => null,
      ),
    );
    plugins.installed.value = [
      {
        'id': 'quiet',
        'name': 'Quiet Clock',
        'version': '1.0.0',
        'source': {'repository': 'https://github.com/alice/quiet'},
      },
    ];
    // The list arrives before the page opens, the way a second visit finds it.
    await tester.runAsync(() => plugins.directory.read());
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PluginDirectoryPanel(plugins: plugins, onOpen: (_) {}),
          ),
        ),
      ),
    );
    await settle(tester);
    expect(
      tester.getTopLeft(find.text('Weather Mood')).dy,
      lessThan(tester.getTopLeft(find.text('Quiet Clock')).dy),
    );
    expect(find.text('Installed'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'weather');
    await settle(tester);
    expect(find.text('Quiet Clock'), findsNothing);
    expect(find.text('Weather Mood'), findsOneWidget);
    // The GitHub owner and the plugin ID match too.
    await tester.enterText(find.byType(TextField), 'weather-labs');
    await settle(tester);
    expect(find.text('Weather Mood'), findsOneWidget);
    expect(find.text('Quiet Clock'), findsNothing);
    await tester.enterText(find.byType(TextField), 'quiet');
    await settle(tester);
    expect(find.text('Quiet Clock'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'nothing like this');
    await settle(tester);
    expect(find.text('No plugins match your search.'), findsOneWidget);
  });

  testWidgets('holds back a release that needs a newer Kiosk Satellite', (
    tester,
  ) async {
    final body = jsonEncode({
      'schemaVersion': 1,
      'plugins': [
        for (final (id, name, version) in [
          ('newer', 'Newer Clock', '1.0.0'),
          ('quiet', 'Quiet Clock', '1.1.0'),
        ])
          {
            'id': id,
            'name': name,
            'author': 'Alice',
            'version': version,
            'minAppVersion': '2026.10.40',
            'repository': 'https://github.com/alice/$id',
            'status': 'ok',
          },
      ],
    });
    final plugins = PluginManager(
      EventBus(),
      CommandRegistry(Logger()),
      Logger(),
      directory: PluginDirectory(
        clientFactory: () => MockClient((_) async => http.Response(body, 200)),
        cacheFile: () async => null,
      ),
    )..appVersion = (() => '2026.10.39');
    plugins.installed.value = [
      {
        'id': 'quiet',
        'name': 'Quiet Clock',
        'version': '1.0.0',
        'source': {'repository': 'https://github.com/alice/quiet'},
      },
    ];
    await tester.runAsync(() => plugins.directory.read());
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PluginDirectoryPanel(plugins: plugins, onOpen: (_) {}),
          ),
        ),
      ),
    );
    await settle(tester);
    expect(
      find.text('Needs Kiosk Satellite 2026.10.40 or newer'),
      findsNWidgets(2),
    );
    expect(find.byTooltip('Install'), findsNothing);
    expect(find.text('Update'), findsNothing);
    expect(find.text('Installed'), findsOneWidget);
  });

  testWidgets('pages a long list and sorts it', (tester) async {
    final body = jsonEncode({
      'schemaVersion': 1,
      'plugins': [
        for (var i = 0; i < 45; i++)
          {
            'id': 'plugin-$i',
            'name': 'Plugin ${i.toString().padLeft(2, '0')}',
            'author': 'Alice',
            'version': '1.0.0',
            'repository': 'https://github.com/alice/plugin-$i',
            'stars': i,
            'downloads': 45 - i,
            'status': 'ok',
          },
      ],
    });
    final plugins = PluginManager(
      EventBus(),
      CommandRegistry(Logger()),
      Logger(),
      directory: PluginDirectory(
        clientFactory: () => MockClient((_) async => http.Response(body, 200)),
        cacheFile: () async => null,
      ),
    );
    await tester.runAsync(() => plugins.directory.read());
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PluginDirectoryPanel(plugins: plugins, onOpen: (_) {}),
          ),
        ),
      ),
    );
    await settle(tester);
    // Ten rows a page unless picked otherwise, most downloads first.
    expect(find.text('Page 1 of 5'), findsOneWidget);
    expect(find.text('Plugin 00'), findsOneWidget);
    expect(find.text('Plugin 10'), findsNothing);
    await tester.tap(find.byTooltip('Next page'));
    await settle(tester);
    expect(find.text('Page 2 of 5'), findsOneWidget);
    expect(find.text('Plugin 10'), findsOneWidget);
    expect(find.text('Plugin 00'), findsNothing);
    // A new page size starts at its first page.
    await tester.tap(find.byType(DropdownButton<int>));
    await settle(tester);
    await tester.tap(find.text('20 per page').last);
    await settle(tester);
    expect(find.text('Page 1 of 3'), findsOneWidget);
    expect(find.text('Plugin 19'), findsOneWidget);
    // A new order starts at its first page.
    await tester.tap(find.byTooltip('Next page'));
    await settle(tester);
    await tester.tap(find.text('Most downloads'));
    await settle(tester);
    await tester.tap(find.text('Most stars').last);
    await settle(tester);
    expect(find.text('Page 1 of 3'), findsOneWidget);
    expect(find.text('Plugin 44'), findsOneWidget);
    expect(find.text('Plugin 00'), findsNothing);
  });

  for (final (name, size) in [
    ('phone', const Size(390, 844)),
    ('tablet', const Size(1280, 800)),
  ]) {
    testWidgets('the install review lays out on a $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final preview = <String, Object?>{
        'manifest': {
          'name': 'Google Photos Screensaver',
          'author': 'Coffmad',
          'version': '1.2.0',
          'license': 'Apache-2.0',
          'description': 'Shows photos from shared albums. ' * 4,
        },
        'installedVersion': '1.1.0',
        'readme': '# Title\n\n${'A long README paragraph. ' * 200}',
        'readmeBaseUrl': 'https://raw.githubusercontent.com/a/b/c/',
        'compatible': false,
        'compatibilityError': 'Plugin needs Android API 99',
        'listed': true,
      };
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      unawaited(showPluginPreview(context, preview));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('by Coffmad'), findsOneWidget);
      expect(find.text('1.1.0 → 1.2.0'), findsOneWidget);
      expect(find.text('Listed in Community Plugins'), findsOneWidget);
      expect(find.text('Plugin needs Android API 99'), findsOneWidget);
      // An incompatible plugin cannot be installed.
      final install = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Trust and update'),
      );
      expect(install.onPressed, isNull);
    });
  }

  testWidgets('an update review shows the release notes above the README', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    Map<String, Object?> preview({String? installed, String notes = ''}) => {
      'manifest': {
        'name': 'Hello World',
        'author': 'Example',
        'version': '1.2.0',
        'license': 'MIT',
      },
      'installedVersion': ?installed,
      'releaseNotes': notes,
      'readme': 'The README text.',
      'readmeBaseUrl': 'https://raw.githubusercontent.com/a/b/c/',
      'compatible': true,
      'listed': true,
    };
    const notes = '### Fixed\n- The clock no longer drifts.';
    final section = find.byKey(const ValueKey('plugin-release-notes'));

    unawaited(
      showPluginPreview(context, preview(installed: '1.1.0', notes: notes)),
    );
    await settle(tester);
    expect(find.text('RELEASE NOTES'), findsOneWidget);
    expect(
      find.descendant(of: section, matching: find.text('Fixed')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('RELEASE NOTES')).dy,
      lessThan(tester.getTopLeft(find.text('README')).dy),
    );
    expect(
      tester.getBottomLeft(section).dy,
      lessThan(tester.getTopLeft(find.text('README')).dy),
    );
    await tester.tap(find.text('Cancel'));
    await settle(tester);

    // A release without notes and a first install show the README alone.
    for (final data in [preview(installed: '1.1.0'), preview(notes: notes)]) {
      unawaited(showPluginPreview(context, data));
      await settle(tester);
      expect(find.text('README'), findsOneWidget);
      expect(find.text('The README text.'), findsOneWidget);
      expect(find.text('RELEASE NOTES'), findsNothing);
      expect(section, findsNothing);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
    }
  });
}
