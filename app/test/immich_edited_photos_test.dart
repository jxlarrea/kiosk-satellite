import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/screensaver/immich_manager.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

/// Photos edited in Immich's editor show as edited: the edited preview is
/// asked for, its shape comes from the asset rather than the camera EXIF
/// and a new edit is downloaded again instead of read from the cache
/// (issue #1401).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('immichAspect', () {
    test('the asset size wins over the camera EXIF', () {
      // A landscape shot turned to portrait in the editor: the EXIF still
      // describes the camera frame, the asset describes the edit.
      expect(
        immichAspect({
          'width': 1440,
          'height': 1913,
          'exifInfo': {'exifImageWidth': 4032, 'exifImageHeight': 3024},
        }),
        closeTo(1440 / 1913, 0.001),
      );
    });

    test('servers without an asset size fall back to the EXIF', () {
      expect(
        immichAspect({
          'width': null,
          'exifInfo': {
            'exifImageWidth': 4032,
            'exifImageHeight': 3024,
            'orientation': '6',
          },
        }),
        closeTo(3 / 4, 0.001),
      );
      expect(immichAspect({'width': 0, 'height': 0}), isNull);
    });
  });

  group('immichEdit', () {
    test('an edited photo is named by its thumbhash, safe for a file', () {
      expect(immichEdit({'isEdited': true, 'thumbhash': 'ab+c/d=='}), 'ab-c_d');
    });

    test('an unedited photo has no edit, whatever its thumbhash', () {
      expect(immichEdit({'isEdited': false, 'thumbhash': 'abc'}), isNull);
      expect(immichEdit({'thumbhash': 'abc'}), isNull);
      expect(immichEdit({'isEdited': true, 'thumbhash': null}), isNull);
    });
  });

  group('image requests', () {
    setUpAll(() => HttpOverrides.global = null);
    late HttpServer server;
    late AppContainer c;
    late Directory support;
    late PathProviderPlatform oldPaths;
    final requests = <Uri>[];

    setUp(() async {
      requests.clear();
      support = await Directory.systemTemp.createTemp('immich_edited_test');
      oldPaths = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _SupportPath(support.path);
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((r) async {
        requests.add(r.uri);
        r.response.add([requests.length]);
        await r.response.close();
      });
      SharedPreferences.setMockInitialValues({
        'ks.screensaver.immich_url': 'http://127.0.0.1:${server.port}',
        'ks.screensaver.immich_api_key': 'key',
        'ks.screensaver.immich_cache': true,
      });
      c = AppContainer();
      await c.settings.init();
      await c.immich.init();
    });

    tearDown(() async {
      // Each download starts a cache eviction in the background. Let it
      // finish before its folder is deleted.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await c.immich.dispose();
      await server.close(force: true);
      PathProviderPlatform.instance = oldPaths;
      await support.delete(recursive: true);
    });

    test('the edited preview is asked for', () async {
      await c.immich.imageBytes(const ImmichAsset(id: 'a', isVideo: false));
      expect(requests.single.path, '/api/assets/a/thumbnail');
      expect(requests.single.queryParameters, {
        'size': 'preview',
        'edited': 'true',
      });
    });

    test('a new edit is downloaded again, the same edit is not', () async {
      const plain = ImmichAsset(id: 'a', isVideo: false);
      const first = ImmichAsset(id: 'a', isVideo: false, edit: 'one');
      const second = ImmichAsset(id: 'a', isVideo: false, edit: 'two');

      expect(await c.immich.imageBytes(plain), [1]);
      expect(await c.immich.imageBytes(plain), [1]);
      expect(await c.immich.imageBytes(first), [2]);
      expect(await c.immich.imageBytes(first), [2]);
      expect(await c.immich.imageBytes(second), [3]);
      expect(requests, hasLength(3));

      final names = Directory(
        '${support.path}/immich_cache',
      ).listSync().map((f) => f.uri.pathSegments.last).toSet();
      expect(names, {'a.img', 'a_one.img', 'a_two.img'});
    });
  });
}
