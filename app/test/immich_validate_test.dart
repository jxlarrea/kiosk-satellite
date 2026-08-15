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
  var thumbnailStatus = 200;
  var libraryEmpty = false;

  setUp(() async {
    thumbnailStatus = 200;
    libraryEmpty = false;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      final path = request.uri.path;
      final response = request.response;
      if (path == '/api/albums') {
        response.headers.contentType = ContentType.json;
        response.write('[]');
      } else if (path == '/api/search/metadata') {
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode({
          'assets': {
            'items': libraryEmpty
                ? []
                : [
                    {'id': 'asset-1', 'type': 'IMAGE'},
                  ],
            'nextPage': null,
          },
        }));
      } else if (path == '/api/assets/asset-1/thumbnail') {
        response.statusCode = thumbnailStatus;
        response.headers.contentType = thumbnailStatus == 200
            ? ContentType('image', 'jpeg')
            : ContentType.json;
        response.write(thumbnailStatus == 200
            ? 'jpegbytes'
            : jsonEncode({'message': 'Not found or no asset.view access'}));
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
    thumbnailStatus = 403;
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

  test('a transport failure reads as could-not-reach', () async {
    await server.close(force: true);
    final result = await commands.execute('immichValidate', const {});
    expect(result.ok, isFalse);
    expect(result.error, startsWith('Could not reach'));
  });

  test('a fetch error names the endpoint for the app log', () async {
    thumbnailStatus = 403;
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
