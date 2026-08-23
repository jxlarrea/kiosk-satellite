import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/immich_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immich connection validation against a local fake server (issue #222):
/// a key that can list albums and search assets but not fetch previews
/// must fail at the Validate button naming asset.view, not pass and then
/// show "could not reach the server" at night.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The test binding stubs every HttpClient to answer 400 without any
  // network; these tests talk to a real loopback server instead.
  setUpAll(() => HttpOverrides.global = null);

  late HttpServer server;
  late SettingsManager settings;
  late CommandRegistry commands;
  late ImmichManager immich;

  /// What the fake server answers per area; the test flips these.
  /// [thumbnailStatuses] is per asset id, so a library whose newest asset
  /// has no preview yet can be described exactly (issue #285).
  var thumbnailStatuses = <String, int>{'asset-1': 200};
  var assetIds = <String>['asset-1'];
  var libraryEmpty = false;

  /// Every thumbnail path the server was asked for, newest-first order
  /// preserved, so a test can assert the probe moved on.
  final probed = <String>[];

  setUp(() async {
    thumbnailStatuses = {'asset-1': 200};
    assetIds = ['asset-1'];
    libraryEmpty = false;
    probed.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      final path = request.uri.path;
      final response = request.response;
      if (path == '/api/albums') {
        response.headers.contentType = ContentType.json;
        response.write('[]');
      } else if (path == '/api/search/metadata') {
        response.headers.contentType = ContentType.json;
        response.write(
          jsonEncode({
            'assets': {
              'items': libraryEmpty
                  ? []
                  : [
                      for (final id in assetIds) {'id': id, 'type': 'IMAGE'},
                    ],
              'nextPage': null,
            },
          }),
        );
      } else if (path.startsWith('/api/assets/') &&
          path.endsWith('/thumbnail')) {
        probed.add(path);
        final id = path.split('/')[3];
        final status = thumbnailStatuses[id] ?? 200;
        response.statusCode = status;
        response.headers.contentType = status == 200
            ? ContentType('image', 'jpeg')
            : ContentType.json;
        response.write(
          status == 200
              ? 'jpegbytes'
              : jsonEncode({
                  'message': status == 404
                      ? 'Asset media not found'
                      : 'Not found or no asset.view access',
                }),
        );
      } else {
        response.statusCode = 404;
      }
      response.close();
    });

    SharedPreferences.setMockInitialValues({
      'ks.screensaver.immich_url': 'http://127.0.0.1:${server.port}',
      'ks.screensaver.immich_api_key': 'test-key',
      // The local cache calls path_provider, which has no test host.
      'ks.screensaver.immich_cache': false,
    });
    final bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    immich = ImmichManager(bus, commands, log, settings);
    await immich.init();
  });

  tearDown(() => server.close(force: true));

  test('a key that cannot fetch previews fails validation by name', () async {
    thumbnailStatuses['asset-1'] = 403;
    final result = await commands.execute('immichValidate', const {});
    expect(result.ok, isFalse);
    // The message must name the missing Immich scope, not read as a
    // reachability problem: the server answered, it just said no.
    expect(result.error, 'The API key is missing the asset.view permission.');
    expect(settings.get(defs.screensaverImmichValidated), isFalse);
  });

  test('a key with all three scopes validates', () async {
    final result = await commands.execute('immichValidate', const {});
    expect(result.error, isNull);
    expect(result.ok, isTrue);
    expect(settings.get(defs.screensaverImmichValidated), isTrue);
  });

  test('an empty library still validates (nothing to preview)', () async {
    libraryEmpty = true;
    final result = await commands.execute('immichValidate', const {});
    expect(result.ok, isTrue);
  });

  test('an asset with no preview yet does not fail validation', () async {
    // The newest asset in a library taking phone backups is routinely
    // still being processed: Immich answers 404 "Asset media not found",
    // which says nothing about the key (issue #285). The probe moves on.
    assetIds = ['asset-1', 'asset-2'];
    thumbnailStatuses = {'asset-1': 404, 'asset-2': 200};
    final result = await commands.execute('immichValidate', const {});
    expect(result.ok, isTrue);
    expect(settings.get(defs.screensaverImmichValidated), isTrue);
    expect(probed, [
      '/api/assets/asset-1/thumbnail',
      '/api/assets/asset-2/thumbnail',
    ]);
  });

  test('a library with no previews at all still validates', () async {
    assetIds = ['asset-1', 'asset-2'];
    thumbnailStatuses = {'asset-1': 404, 'asset-2': 404};
    final result = await commands.execute('immichValidate', const {});
    expect(result.ok, isTrue);
    expect(settings.get(defs.screensaverImmichValidated), isTrue);
  });

  test('a rejected key still fails behind a preview-less asset', () async {
    // A 404 is skipped, a 403 is not: the probe exists to catch a key
    // without asset.view, and one unprocessed asset ahead of it must not
    // hide that.
    assetIds = ['asset-1', 'asset-2'];
    thumbnailStatuses = {'asset-1': 404, 'asset-2': 403};
    final result = await commands.execute('immichValidate', const {});
    expect(result.ok, isFalse);
    expect(result.error, 'The API key is missing the asset.view permission.');
  });

  test('a transport failure reads as could-not-reach', () async {
    await server.close(force: true);
    final result = await commands.execute('immichValidate', const {});
    expect(result.ok, isFalse);
    expect(result.error, startsWith('Could not reach'));
  });

  test('a fetch error names the endpoint for the app log', () async {
    thumbnailStatuses['asset-1'] = 403;
    // The screensaver logs the exception's toString on every failed
    // fetch; it must identify the endpoint and status so the cause is
    // visible without instrumenting a reverse proxy.
    try {
      await immich.imageBytes(const ImmichAsset(id: 'asset-1', isVideo: false));
      fail('expected a 403 to throw');
    } catch (e) {
      expect('$e', contains('403'));
      expect('$e', contains('/api/assets/asset-1/thumbnail'));
    }
  });
}
