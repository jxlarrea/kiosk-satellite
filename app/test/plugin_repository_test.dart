import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_repository.dart';

void main() {
  const url = 'https://github.com/example/hello';
  final ref = 'a' * 40;
  final bytes = utf8.encode('test package bytes');
  late List<Uri> requests;
  late Map<String, Object?> descriptor;
  late PluginRepository repository;
  late String readme;
  late int status;
  late bool wrongBytes;
  setUp(() {
    requests = [];
    readme = '# Hello\nReviewed README';
    status = 200;
    wrongBytes = false;
    descriptor = {
      'schemaVersion': 1,
      'manifest': {
        'id': 'hello',
        'version': '1.0.0',
        'capabilities': ['overlay'],
      },
      'download': {
        'tag': 'v1.0.0',
        'asset': 'hello-1.0.0.zip',
        'sha256': sha256.convert(bytes).toString(),
      },
    };
    repository = PluginRepository(
      client: MockClient((request) async {
        requests.add(request.url);
        if (status != 200) return http.Response('failure', status);
        if (request.url.host == 'api.github.com') {
          return http.Response(
            jsonEncode([
              {'sha': ref},
            ]),
            200,
          );
        }
        if (request.url.path.endsWith('kiosk-plugin.json')) {
          return http.Response(jsonEncode(descriptor), 200);
        }
        if (request.url.path.endsWith('README.md')) {
          return http.Response(readme, 200);
        }
        return http.Response.bytes(wrongBytes ? [0] : bytes, 200);
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
    'pins README and manifest to one commit and installs only the reviewed release',
    () async {
      final preview = await repository.preview(url);
      expect(requests, hasLength(3));
      expect(requests.skip(1).every((u) => u.path.contains('/$ref/')), isTrue);
      expect(preview['readme'], readme);
      expect(requests.any((u) => u.path.contains('/releases/')), isFalse);
      (preview['manifest'] as Map)['version'] = '9.9.9';
      descriptor['download'] = {'tag': 'v9.9.9'};
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
      expect(jsonDecode(args['source'] as String)['repository'], url);
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
    'rejects a release whose checksum differs from the reviewed checksum',
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
  test('rejects unsafe release names and oversized repository files', () async {
    (descriptor['download'] as Map)['asset'] = '../../outside.zip';
    await expectLater(repository.preview(url), throwsFormatException);
    (descriptor['download'] as Map)['asset'] = 'hello.zip';
    readme = 'x' * (128 * 1024 + 1);
    await expectLater(repository.preview(url), throwsFormatException);
  });
  test('reports unavailable repositories and rate limiting', () async {
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
