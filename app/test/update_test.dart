import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/update/update_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The update notice can sit on the drawer for half a day (the periodic check
/// runs twice a day) and stays up until someone acts on it, so the release it
/// names is not necessarily the newest one by the time the download starts.
/// These cover what the install does about that.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const installer = MethodChannel('kiosk_satellite/installer');
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Directory cache;
  late UpdateManager update;
  late List<String> installed;

  /// A GitHub release payload, as the latest-release endpoint returns it.
  String release(String tag) => jsonEncode({
        'tag_name': 'v$tag',
        'html_url': 'https://github.com/jxlarrea/kiosk-satellite/'
            'releases/tag/v$tag',
        'body': 'Notes for $tag',
        'assets': [
          {
            'name': 'kiosk-satellite-$tag.apk',
            'browser_download_url': 'https://example.invalid/$tag.apk',
          },
        ],
      });

  bool isReleaseQuery(http.BaseRequest request) =>
      request.url.host == 'api.github.com';

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('ks_update_test');
    installed = [];
    messenger.setMockMethodCallHandler(
      pathProvider,
      (call) async =>
          call.method == 'getTemporaryDirectory' ? cache.path : null,
    );
    messenger.setMockMethodCallHandler(installer, (call) async {
      if (call.method != 'installApk') return null;
      installed.add((call.arguments as Map)['path'] as String);
      return 'silent';
    });
    PackageInfo.setMockInitialValues(
      appName: 'Kiosk Satellite',
      packageName: 'me.jxl.kiosk_satellite',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final log = Logger();
    update = UpdateManager(EventBus(), CommandRegistry(log), log);
  });

  tearDown(() async {
    await update.dispose();
    messenger.setMockMethodCallHandler(pathProvider, null);
    messenger.setMockMethodCallHandler(installer, null);
    if (await cache.exists()) await cache.delete(recursive: true);
  });

  /// Runs the check that raises the notice, with GitHub offering [tag].
  Future<void> notice(String tag) async {
    update.clientFactory = () => MockClient(
        (request) async => http.Response(release(tag), 200));
    await update.init();
    expect(await update.check(), isTrue);
    expect(update.available.value?.version, tag);
  }

  test('the install downloads the release cut after the notice', () async {
    await notice('1.1.0');
    final asked = <String>[];
    update.clientFactory = () => MockClient((request) async {
          asked.add(request.url.toString());
          return isReleaseQuery(request)
              ? http.Response(release('1.2.0'), 200)
              : http.Response.bytes(List.filled(2048, 7), 200);
        });

    expect(await update.downloadAndInstall(), isNull);

    // The notice named 1.1.0; nothing ever asks for that APK.
    expect(asked, isNot(contains('https://example.invalid/1.1.0.apk')));
    expect(asked, contains('https://example.invalid/1.2.0.apk'));
    expect(installed, hasLength(1));
    expect(await File(installed.single).length(), 2048);
    // Everything reading the notice (drawer, remote admin, the Home
    // Assistant update entity) follows the version actually being installed.
    expect(update.available.value?.version, '1.2.0');
    expect(update.progress.value, isNull);
  });

  test('an unreachable GitHub still installs the known release', () async {
    await notice('1.1.0');
    final asked = <String>[];
    update.clientFactory = () => MockClient((request) async {
          asked.add(request.url.toString());
          return isReleaseQuery(request)
              ? http.Response('rate limited', 403)
              : http.Response.bytes(List.filled(64, 7), 200);
        });

    expect(await update.downloadAndInstall(), isNull);

    expect(asked, contains('https://example.invalid/1.1.0.apk'));
    expect(installed, hasLength(1));
    expect(update.available.value?.version, '1.1.0');
  });

  test('a release pulled since the notice installs nothing', () async {
    await notice('1.1.0');
    final asked = <String>[];
    update.clientFactory = () => MockClient((request) async {
          asked.add(request.url.toString());
          return isReleaseQuery(request)
              ? http.Response(release('1.0.0'), 200)
              : http.Response.bytes(List.filled(64, 7), 200);
        });

    expect(await update.downloadAndInstall(), contains('Already up to date'));

    expect(asked.any((url) => url.endsWith('.apk')), isFalse);
    expect(installed, isEmpty);
    // The notice clears, so nothing keeps offering the release that is gone.
    expect(update.available.value, isNull);
    expect(update.progress.value, isNull);
  });
}
