import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_repository.dart';

void main() {
  test(
    'update checks compare versions and package digests without offering downgrades',
    () {
      final installed = {'id': 'hello', 'version': '1.9.0', 'sha256': 'old'};
      Map preview(String version, [String hash = 'new', String id = 'hello']) =>
          {
            'manifest': {'id': id, 'version': version},
            'sha256': hash,
          };
      expect(PluginRepository.hasUpdate(preview('1.10.0'), installed), isTrue);
      expect(PluginRepository.hasUpdate(preview('1.8.0'), installed), isFalse);
      expect(
        PluginRepository.hasUpdate(preview('1.9.0', 'old'), installed),
        isFalse,
      );
      expect(PluginRepository.hasUpdate(preview('1.9.0'), installed), isTrue);
      expect(
        () => PluginRepository.hasUpdate(
          preview('2.0.0', 'new', 'other'),
          installed,
        ),
        throwsFormatException,
      );
      expect(
        PluginRepository.compareVersions('1.0.0', '1.0.0-rc.1'),
        greaterThan(0),
      );
      expect(
        PluginRepository.compareVersions('1.0.0-rc.10', '1.0.0-rc.2'),
        greaterThan(0),
      );
      expect(
        PluginRepository.compareVersions('1.0.0-alpha', '1.0.0-beta'),
        lessThan(0),
      );
    },
  );
  const url = 'https://github.com/example/hello';
  final ref = 'a' * 40;
  final bytes = utf8.encode('test package bytes');
  late List<Uri> requests;
  late Map<String, Object?> manifest;
  late Map<String, Object?> release;
  late PluginRepository repository;
  late String readme;
  late String checksum;
  late int status;
  late bool wrongBytes;
  Map<String, Object?> asset(String name, int size) => {
    'name': name,
    'state': 'uploaded',
    'size': size,
    'browser_download_url': '$url/releases/download/v1.0.0/$name',
  };
  List<Map<String, Object?>> assets() =>
      release['assets'] as List<Map<String, Object?>>;
  setUp(() {
    requests = [];
    readme = '# Hello\nReviewed README';
    checksum = '${sha256.convert(bytes)}  hello-1.0.0.zip\n';
    status = 200;
    wrongBytes = false;
    manifest = {
      'schemaVersion': 1,
      'id': 'hello',
      'version': '1.0.0',
      'capabilities': ['overlay'],
    };
    release = {
      'tag_name': 'v1.0.0',
      'draft': false,
      'prerelease': false,
      'target_commitish': 'main',
      'assets': [
        asset('kiosk-satellite-plugin.json', 100),
        asset('hello-1.0.0.zip', bytes.length),
        asset('hello-1.0.0.zip.sha256', 100),
      ],
    };
    repository = PluginRepository(
      client: MockClient((request) async {
        requests.add(request.url);
        if (status != 200) return http.Response('failure', status);
        if (request.url.path == '/repos/example/hello/releases/latest') {
          return http.Response(jsonEncode(release), 200);
        }
        if (request.url.path ==
            '/repos/example/hello/commits/refs/tags/v1.0.0') {
          expect(request.headers['Accept'], 'application/vnd.github.sha');
          return http.Response(ref, 200);
        }
        if (request.url.path.endsWith('/kiosk-satellite-plugin.json')) {
          return http.Response(jsonEncode(manifest), 200);
        }
        if (request.url.path.endsWith('.sha256')) {
          return http.Response(checksum, 200);
        }
        if (request.url.toString() ==
            'https://raw.githubusercontent.com/example/hello/$ref/README.md') {
          return http.Response(readme, 200);
        }
        if (request.url.toString() ==
            '$url/releases/download/v1.0.0/hello-1.0.0.zip') {
          return http.Response.bytes(wrongBytes ? [0] : bytes, 200);
        }
        fail('Unexpected request: ${request.url}');
      }),
    );
  });
  tearDown(() => repository.close());

  test(
    'accepts canonical repository URLs and rejects paths and other origins',
    () {
      expect(
        PluginRepository.repositoryUrl(
          ' https://github.com/Example/Hello.git/ ',
        ).toString(),
        url,
      );
      for (final input in [
        'http://github.com/example/hello',
        'https://evil.test/example/hello',
        'https://github.com@example.com/x/y',
        '$url/tree/main',
        '$url?ref=x',
        '$url#readme',
        'https://github.com:444/example/hello',
        'https://github.com/example/..',
      ]) {
        expect(
          () => PluginRepository.repositoryUrl(input),
          throwsFormatException,
          reason: input,
        );
      }
    },
  );
  test(
    'discovers a stable release and pins README to its tag commit before downloading code',
    () async {
      final preview = await repository.preview(url);
      expect(requests, hasLength(5));
      expect(requests.first.path, '/repos/example/hello/releases/latest');
      expect(requests.any((u) => u.path.endsWith('.zip')), isFalse);
      expect(requests.any((u) => u.path.contains('/main/')), isFalse);
      expect(preview['readme'], readme);
      expect(preview['ref'], ref);
      expect(preview['releaseTag'], 'v1.0.0');
      (preview['manifest'] as Map)['version'] = '9.9.9';
      release['tag_name'] = 'v9.9.9';
      manifest['version'] = '9.9.9';
      checksum = 'changed after review';
      final args = await repository.installArguments(
        preview['previewId'] as String,
        trusted: true,
      );
      expect(
        requests.last.toString(),
        '$url/releases/download/v1.0.0/hello-1.0.0.zip',
      );
      expect(
        jsonDecode(args['expectedManifest'] as String)['version'],
        '1.0.0',
      );
      final source = jsonDecode(args['source'] as String);
      expect(source['repository'], url);
      expect(source['releaseTag'], 'v1.0.0');
      expect(source['ref'], ref);
      expect(args['bytes'], bytes);
    },
  );
  test('requires trust and a valid preview before downloading', () async {
    final preview = await repository.preview(url);
    final count = requests.length;
    await expectLater(
      repository.installArguments(
        preview['previewId'] as String,
        trusted: false,
      ),
      throwsStateError,
    );
    await expectLater(
      repository.installArguments('invented-token', trusted: true),
      throwsStateError,
    );
    expect(requests, hasLength(count));
  });
  test(
    'rejects a package whose checksum differs from the reviewed checksum',
    () async {
      final preview = await repository.preview(url);
      wrongBytes = true;
      await expectLater(
        repository.installArguments(
          preview['previewId'] as String,
          trusted: true,
        ),
        throwsFormatException,
      );
    },
  );
  test('rejects draft and prerelease responses', () async {
    release['draft'] = true;
    await expectLater(repository.preview(url), throwsFormatException);
    release['draft'] = false;
    release['prerelease'] = true;
    await expectLater(repository.preview(url), throwsFormatException);
    expect(requests.every((u) => u.path.endsWith('/releases/latest')), isTrue);
  });
  test('rejects missing and duplicate release assets', () async {
    assets().removeLast();
    await expectLater(repository.preview(url), throwsFormatException);
    assets().add(asset('hello-1.0.0.zip.sha256', 100));
    assets().add(asset('kiosk-satellite-plugin.json', 100));
    await expectLater(repository.preview(url), throwsFormatException);
  });
  test(
    'rejects unuploaded and oversized release assets before downloading them',
    () async {
      assets().first['state'] = 'new';
      await expectLater(repository.preview(url), throwsFormatException);
      assets().first['state'] = 'uploaded';
      assets().first['size'] = 32 * 1024 + 1;
      await expectLater(repository.preview(url), throwsFormatException);
      expect(
        requests.every((u) => u.path.endsWith('/releases/latest')),
        isTrue,
      );
      assets().first['size'] = 100;
      assets()[1]['size'] = PluginRepository.maxPackageBytes + 1;
      await expectLater(repository.preview(url), throwsFormatException);
      expect(requests.any((u) => u.path.endsWith('.zip')), isFalse);
    },
  );
  test('rejects asset URLs from another repository or release', () async {
    for (final download in [
      'https://evil.test/package',
      'https://github.com/other/hello/releases/download/v1.0.0/kiosk-satellite-plugin.json',
      '$url/releases/download/v2.0.0/kiosk-satellite-plugin.json',
      '$url/releases/download/V1.0.0/kiosk-satellite-plugin.json',
      '$url/releases/download/v1.0.0/kiosk-satellite-plugin.json?x=y',
    ]) {
      assets().first['browser_download_url'] = download;
      await expectLater(repository.preview(url), throwsFormatException);
    }
    expect(requests.every((u) => u.path.endsWith('/releases/latest')), isTrue);
  });
  test(
    'rejects malformed checksums and checksums naming another package',
    () async {
      for (final invalid in [
        'not a checksum',
        '${sha256.convert(bytes)}',
        '${sha256.convert(bytes)}  other.zip',
        '${sha256.convert(bytes)}  hello-1.0.0.zip\nextra',
      ]) {
        checksum = invalid;
        await expectLater(repository.preview(url), throwsFormatException);
      }
    },
  );
  test('rejects unsafe tags and manifest package names', () async {
    release['tag_name'] = '../../outside';
    await expectLater(repository.preview(url), throwsFormatException);
    release['tag_name'] = 'v1.0.0';
    manifest['id'] = '../outside';
    await expectLater(repository.preview(url), throwsFormatException);
    manifest['id'] = 'hello';
    manifest['version'] = '1.0.0/extra';
    await expectLater(repository.preview(url), throwsFormatException);
  });
  test('enforces manifest and README response size limits', () async {
    manifest['description'] = 'x' * (32 * 1024);
    await expectLater(repository.preview(url), throwsFormatException);
    manifest.remove('description');
    readme = 'x' * (128 * 1024 + 1);
    await expectLater(repository.preview(url), throwsFormatException);
  });
  test('reports unavailable stable releases and rate limiting', () async {
    for (final code in [404, 403, 429]) {
      status = code;
      await expectLater(repository.preview(url), throwsStateError);
    }
  });
  test('caps retained previews so stale tokens cannot install', () async {
    final first = await repository.preview(url);
    for (var i = 0; i < 8; i++) {
      await repository.preview(url);
    }
    await expectLater(
      repository.installArguments(first['previewId'] as String, trusted: true),
      throwsStateError,
    );
  });
  test(
    'rejects redirects outside GitHub before contacting their destination',
    () async {
      repository.close();
      repository = PluginRepository(
        client: MockClient((request) async {
          requests.add(request.url);
          return http.Response(
            '',
            302,
            headers: {'location': 'http://192.168.1.1/private'},
          );
        }),
      );
      await expectLater(repository.preview(url), throwsFormatException);
      expect(requests, hasLength(1));
    },
  );
  test('enforces streamed response limits without Content-Length', () async {
    repository.close();
    repository = PluginRepository(
      client: MockClient.streaming(
        (request, _) async => http.StreamedResponse(
          Stream.fromIterable([
            List.filled(128 * 1024, 65),
            [65],
          ]),
          200,
        ),
      ),
    );
    await expectLater(repository.preview(url), throwsFormatException);
  });
}
