import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/screensaver/immich_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => HttpOverrides.global = null);
  late HttpServer server;
  late AppContainer c;
  late void Function(HttpRequest) respond;
  var imageRequests = 0;
  var detailRequests = 0;
  const asset = ImmichAsset(id: 'one', isVideo: false);

  setUp(() async {
    imageRequests = detailRequests = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((r) {
      if (r.uri.path.endsWith('/thumbnail')) {
        imageRequests++;
      } else {
        detailRequests++;
      }
      respond(r);
    });
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.immich_url': 'http://127.0.0.1:${server.port}',
      'ks.screensaver.immich_api_key': 'old',
      'ks.screensaver.immich_cache': false,
      'ks.screensaver.immich_metadata_album': false,
    });
    c = AppContainer();
    await c.settings.init();
    await c.immich.init();
  });
  tearDown(() async {
    await c.immich.dispose();
    await server.close(force: true);
  });

  test(
    'concurrent image and metadata consumers each share one request',
    () async {
      respond = (r) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        if (r.uri.path.endsWith('/thumbnail')) {
          r.response.add([1, 2, 3]);
        } else {
          r.response.write(
            jsonEncode({
              'exifInfo': {'model': 'Camera'},
            }),
          );
        }
        await r.response.close();
      };
      final images = await Future.wait(
        List.generate(4, (_) => c.immich.imageBytes(asset)),
      );
      expect(imageRequests, 1);
      expect(images.every((image) => identical(image, images.first)), isTrue);
      final details = await Future.wait(
        List.generate(4, (_) => c.immich.assetDetails(asset)),
      );
      expect(detailRequests, 1);
      expect(details.first['camera'], 'Camera');
    },
  );

  test('failed image requests are shared and can be retried', () async {
    var fail = true;
    respond = (r) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      r.response.statusCode = fail ? 503 : 200;
      r.response.add([1, 2]);
      await r.response.close();
    };
    final first = c.immich.imageBytes(asset);
    final second = c.immich.imageBytes(asset);
    await Future.wait([
      expectLater(first, throwsException),
      expectLater(second, throwsException),
    ]);
    expect(imageRequests, 1);
    fail = false;
    expect(await c.immich.imageBytes(asset), [1, 2]);
    expect(imageRequests, 2);
  });

  test(
    'an old metadata response cannot repopulate a changed connection cache',
    () async {
      final arrived = Completer<void>();
      final release = Completer<void>();
      respond = (r) async {
        final key = r.headers.value('x-api-key');
        if (key == 'old') {
          arrived.complete();
          await release.future;
        }
        r.response.write(
          jsonEncode({
            'exifInfo': {'model': key},
          }),
        );
        await r.response.close();
      };
      final old = c.immich.assetDetails(asset);
      await arrived.future;
      await c.settings.set(defs.screensaverImmichApiKey, 'new');
      expect((await c.immich.assetDetails(asset))['camera'], 'new');
      release.complete();
      await old;
      expect((await c.immich.assetDetails(asset))['camera'], 'new');
      expect(detailRequests, 2);
    },
  );
}
