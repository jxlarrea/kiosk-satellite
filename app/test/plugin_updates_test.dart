import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_directory.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_manager.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_repository.dart';
import 'package:kiosk_satellite/ui/plugin_settings.dart';

const listedRepo = 'https://github.com/example/listed';
const unlistedRepo = 'https://github.com/example/unlisted';
const digest =
    '0000000000000000000000000000000000000000000000000000000000000000';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late PluginManager plugins;
  late EventBus bus;
  late List<Map<String, Object?>> installed;
  late List<MethodCall> calls;
  late List<Uri> requests;
  late bool masterEnabled;
  late String listedVersion;
  late String? listedMinApp;
  late String unlistedVersion;
  late int githubStatus;
  late int directoryStatus;
  late List<String> topics;

  Map<String, Object?> plugin(String id, String version, String? repository) =>
      {
        'id': id,
        'name': id.toUpperCase(),
        'version': version,
        'sha256': 'installed',
        'enabled': true,
        'running': true,
        'source': ?(repository == null ? null : {'repository': repository}),
      };

  String index() => jsonEncode({
    'schemaVersion': 1,
    'generated': '2026-11-06T06:00:00Z',
    'plugins': [
      {
        'id': 'listed',
        'status': 'ok',
        'repository': listedRepo,
        'name': 'Listed',
        'description': 'A listed plugin',
        'author': 'example',
        'version': listedVersion,
        'tag': 'v$listedVersion',
        'sha256': digest,
        'minAppVersion': ?listedMinApp,
      },
    ],
  });

  http.Response github(http.Request request) {
    requests.add(request.url);
    if (githubStatus != 200) return http.Response('failure', githubStatus);
    final package = 'unlisted-$unlistedVersion.zip';
    Map<String, Object?> asset(String name) => {
      'name': name,
      'state': 'uploaded',
      'uploader': {
        'id': 41898282,
        'login': 'github-actions[bot]',
        'type': 'Bot',
      },
      'digest': 'sha256:$digest',
      'size': 100,
      'browser_download_url':
          '$unlistedRepo/releases/download/v$unlistedVersion/$name',
    };
    if (request.url.path == '/repos/example/unlisted/releases/latest') {
      return http.Response(
        jsonEncode({
          'tag_name': 'v$unlistedVersion',
          'draft': false,
          'prerelease': false,
          'assets': [
            asset('kiosk-satellite-plugin.json'),
            asset(package),
            asset('$package.sha256'),
          ],
        }),
        200,
      );
    }
    if (request.url.path.endsWith('/kiosk-satellite-plugin.json')) {
      return http.Response(
        jsonEncode({
          'schemaVersion': 1,
          'id': 'unlisted',
          'version': unlistedVersion,
        }),
        200,
      );
    }
    fail('Unexpected request: ${request.url}');
  }

  setUp(() async {
    bus = EventBus();
    final log = Logger();
    calls = [];
    requests = [];
    masterEnabled = true;
    listedVersion = '1.2.0';
    listedMinApp = null;
    unlistedVersion = '1.0.0';
    githubStatus = 200;
    directoryStatus = 200;
    topics = [];
    bus.on<RemoteStatusChanged>().listen((e) => topics.add(e.topic));
    installed = [plugin('listed', '1.0.0', listedRepo)];
    plugins = PluginManager(
      bus,
      CommandRegistry(log),
      log,
      repository: PluginRepository(
        client: MockClient((request) async => github(request)),
      ),
      directory: PluginDirectory(
        cacheFile: () async => null,
        clientFactory: () =>
            MockClient((_) async => http.Response(index(), directoryStatus)),
      ),
    )..appVersion = () => '2026.11.9';
    messenger.setMockMethodCallHandler(PluginManager.channel, (call) async {
      calls.add(call);
      if (call.method == 'setEnabled') {
        masterEnabled = (call.arguments as Map)['enabled'] == true;
      }
      if (call.method == 'validateManifest') return <String, Object?>{};
      return {'enabled': masterEnabled, 'plugins': installed};
    });
    await plugins.init();
    await plugins.refresh();
  });

  tearDown(() async {
    await plugins.dispose();
    messenger.setMockMethodCallHandler(PluginManager.channel, null);
  });

  test('a newer listed release shows and installs nothing', () async {
    await plugins.checkUpdates();
    expect(plugins.updates.value, {'listed': '1.2.0'});
    expect(plugins.pendingUpdates, [
      {'id': 'listed', 'name': 'LISTED', 'version': '1.2.0'},
    ]);
    expect(requests, isEmpty, reason: 'the list answers for a listed plugin');
    expect(calls.map((c) => c.method), isNot(contains('install')));
    final state = await plugins.getState();
    expect((state['plugins'] as List).single['updateVersion'], '1.2.0');
    await Future<void>.delayed(Duration.zero);
    expect(topics, contains('plugin-updates'));
  });

  testWidgets('Plugin Manager shows the new version on the row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PluginSettingsPanel(plugins: plugins, onOpen: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    const hint = 'example/listed · 1.0.0';
    expect(find.text(hint), findsOneWidget);
    await tester.runAsync(plugins.checkUpdates);
    await tester.pumpAndSettle();
    expect(find.text('$hint · New version: 1.2.0'), findsOneWidget);
    installed = [
      {...plugin('listed', '1.2.0', listedRepo), 'sha256': digest},
    ];
    await tester.runAsync(plugins.refresh);
    await tester.pumpAndSettle();
    expect(find.text('example/listed · 1.2.0'), findsOneWidget);
  });

  test('an unlisted repository plugin costs one GitHub API read', () async {
    installed = [plugin('unlisted', '1.0.0', unlistedRepo)];
    await plugins.refresh();
    unlistedVersion = '2.0.0';
    await plugins.checkUpdates();
    expect(plugins.updates.value, {'unlisted': '2.0.0'});
    expect(requests.where((u) => u.host == 'api.github.com'), hasLength(1));
    expect(requests.where((u) => u.path.endsWith('README.md')), isEmpty);
  });

  test('installing the release takes the plugin off the list', () async {
    await plugins.checkUpdates();
    topics.clear();
    installed = [
      {...plugin('listed', '1.2.0', listedRepo), 'sha256': digest},
    ];
    await plugins.refresh();
    expect(plugins.updates.value, isEmpty);
    await Future<void>.delayed(Duration.zero);
    expect(topics, contains('plugin-updates'));
  });

  test(
    'a republished release of the same version counts as an update',
    () async {
      listedVersion = '1.0.0';
      await plugins.checkUpdates();
      expect(plugins.updates.value, {'listed': '1.0.0'});
    },
  );

  test('a release that needs a newer app is not offered', () async {
    listedMinApp = '2026.12.1';
    await plugins.checkUpdates();
    expect(plugins.updates.value, isEmpty);
  });

  test('ZIP and fleet plugins are not checked', () async {
    installed = [
      plugin('zip', '1.0.0', null),
      plugin('listed', '1.0.0', listedRepo),
    ];
    plugins.fleetManaged = (id) => id == 'listed';
    await plugins.refresh();
    await plugins.checkUpdates();
    expect(plugins.updates.value, isEmpty);
    expect(requests, isEmpty);
  });

  test('a failed read keeps what was known', () async {
    installed = [plugin('unlisted', '1.0.0', unlistedRepo)];
    await plugins.refresh();
    unlistedVersion = '2.0.0';
    await plugins.checkUpdates();
    githubStatus = 503;
    await plugins.checkUpdates();
    expect(plugins.updates.value, {'unlisted': '2.0.0'});
  });

  test('an unreachable list skips the round', () async {
    directoryStatus = 503;
    await plugins.checkUpdates();
    expect(plugins.updates.value, isEmpty);
    expect(requests, isEmpty);
  });

  test(
    'switching Plugin Manager off clears the list until it is back',
    () async {
      await plugins.checkUpdates();
      await plugins.setEnabled(false);
      expect(plugins.updates.value, isEmpty);
      await plugins.setEnabled(true);
      expect(plugins.updates.value, {'listed': '1.2.0'});
    },
  );

  test('the check does nothing with Plugin Manager off', () async {
    await plugins.setEnabled(false);
    await plugins.checkUpdates();
    expect(requests, isEmpty);
    expect(plugins.updates.value, isEmpty);
  });
}
