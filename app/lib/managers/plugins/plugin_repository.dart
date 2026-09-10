import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Public GitHub repositories with a reviewed, checksum-pinned release package.
class PluginRepository {
  PluginRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final _previews = <String, _Preview>{};
  static const maxPackageBytes = 4 * 1024 * 1024;

  static Uri repositoryUrl(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.toLowerCase() != 'github.com' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'Enter a public https://github.com/owner/repository URL',
      );
    }
    var path = uri.path.replaceFirst(RegExp(r'/$'), '');
    path = path.replaceFirst(RegExp(r'\.git$'), '');
    if (!RegExp(
          r'^/[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+$',
        ).hasMatch(path) ||
        path.split('/').last == '.' ||
        path.split('/').last == '..') {
      throw const FormatException(
        'Use the repository URL without a file or branch path',
      );
    }
    return Uri.https('github.com', path.toLowerCase());
  }

  Future<Uint8List> _get(Uri uri, int limit) async {
    final abort = Completer<void>();
    final timer = Timer(const Duration(seconds: 30), abort.complete);
    try {
      return await _read(
        uri,
        limit,
        abort.future,
      ).timeout(const Duration(seconds: 31));
    } finally {
      timer.cancel();
    }
  }

  Future<Uint8List> _read(Uri uri, int limit, Future<void> abort) async {
    for (var redirects = 0; redirects <= 5; redirects++) {
      if (uri.scheme != 'https' ||
          uri.userInfo.isNotEmpty ||
          uri.hasPort ||
          !{
            'github.com',
            'api.github.com',
            'raw.githubusercontent.com',
            'release-assets.githubusercontent.com',
            'objects.githubusercontent.com',
          }.contains(uri.host)) {
        throw const FormatException(
          'Plugin download redirected outside GitHub',
        );
      }
      final request = http.AbortableRequest('GET', uri, abortTrigger: abort)
        ..followRedirects = false;
      request.headers['User-Agent'] = 'Kiosk-Satellite-Plugins';
      final response = await _client.send(request);
      if ({301, 302, 303, 307, 308}.contains(response.statusCode)) {
        await response.stream.listen((_) {}).cancel();
        final location = response.headers['location'];
        if (location == null) {
          throw const FormatException('Invalid GitHub redirect');
        }
        uri = uri.resolve(location);
        continue;
      }
      if (response.statusCode != 200) {
        await response.stream.listen((_) {}).cancel();
        throw StateError(switch (response.statusCode) {
          404 =>
            'Repository, kiosk-plugin.json, README.md or release asset was not found. The repository must be public.',
          403 || 429 =>
            'GitHub denied the request or its request limit was reached. Try again later.',
          _ => 'GitHub request failed (${response.statusCode})',
        });
      }
      if ((response.contentLength ?? 0) > limit) {
        await response.stream.listen((_) {}).cancel();
        throw const FormatException('Repository file exceeds the size limit');
      }
      final data = BytesBuilder(copy: false);
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 15),
      )) {
        if (data.length + chunk.length > limit) {
          throw const FormatException('Repository file exceeds the size limit');
        }
        data.add(chunk);
      }
      return data.takeBytes();
    }
    throw const FormatException('Too many GitHub redirects');
  }

  Future<Map<String, Object?>> preview(String url) async {
    final repository = repositoryUrl(url);
    final commits = jsonDecode(
      utf8.decode(
        await _get(
          Uri.https('api.github.com', '/repos${repository.path}/commits', {
            'per_page': '1',
          }),
          128 * 1024,
        ),
      ),
    );
    final ref = commits is List && commits.isNotEmpty
        ? (commits.first as Map)['sha']
        : null;
    if (ref is! String || !RegExp(r'^[a-f0-9]{40}$').hasMatch(ref)) {
      throw const FormatException(
        'GitHub did not return a repository revision',
      );
    }
    final base = Uri.https(
      'raw.githubusercontent.com',
      '${repository.path}/$ref/',
    );
    final files = await Future.wait([
      _get(base.resolve('kiosk-plugin.json'), 32 * 1024),
      _get(base.resolve('README.md'), 128 * 1024),
    ]);
    final descriptor = jsonDecode(utf8.decode(files[0]));
    if (descriptor is! Map ||
        descriptor['schemaVersion'] != 1 ||
        descriptor['manifest'] is! Map ||
        descriptor['download'] is! Map) {
      throw const FormatException(
        'Invalid kiosk-plugin.json repository manifest',
      );
    }
    final download = descriptor['download'] as Map;
    final tag = download['tag'];
    final asset = download['asset'];
    final digest = download['sha256'];
    final safeName = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,150}$');
    if (tag is! String ||
        !safeName.hasMatch(tag) ||
        asset is! String ||
        !safeName.hasMatch(asset) ||
        !asset.endsWith('.zip') ||
        digest is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(digest)) {
      throw const FormatException('Invalid release tag, ZIP asset or SHA-256');
    }
    final readme = utf8.decode(files[1]);
    final token = base64Url.encode(
      List<int>.generate(24, (_) => Random.secure().nextInt(256)),
    );
    _previews.removeWhere((_, p) => p.expired);
    while (_previews.length >= 8) {
      _previews.remove(_previews.keys.first);
    }
    final data = <String, Object?>{
      'previewId': token,
      'repository': repository.toString(),
      'ref': ref,
      'manifest': descriptor['manifest'],
      'readme': readme,
      'readmeBaseUrl': base.toString(),
      'sha256': digest,
      'downloadUrl': repository
          .resolve('${repository.path}/releases/download/$tag/$asset')
          .toString(),
    };
    // Keep a private deep copy. UI or command callers cannot alter approval data.
    _previews[token] = _Preview(
      Map<String, Object?>.from(jsonDecode(jsonEncode(data)) as Map),
    );
    return data;
  }

  Future<Map<String, Object?>> installArguments(
    String token, {
    required bool trusted,
  }) async {
    if (!trusted) throw StateError('Confirm that you trust the plugin author');
    final preview = _previews[token];
    if (preview == null || preview.expired) {
      throw StateError(
        'This preview expired. Preview the repository again before installing.',
      );
    }
    final data = preview.data;
    final bytes = await _get(
      Uri.parse(data['downloadUrl'] as String),
      maxPackageBytes,
    );
    if (sha256.convert(bytes).toString() != data['sha256']) {
      throw const FormatException(
        'Package SHA-256 does not match the reviewed release',
      );
    }
    return {
      'bytes': bytes,
      'trusted': true,
      'sha256': data['sha256'],
      'expectedManifest': jsonEncode(data['manifest']),
      'source': jsonEncode({
        for (final key in ['repository', 'ref', 'readme', 'readmeBaseUrl'])
          key: data[key],
      }),
    };
  }

  void close() {
    _previews.clear();
    _client.close();
  }
}

class _Preview {
  _Preview(this.data);
  final Map<String, Object?> data;
  final created = DateTime.now();
  bool get expired =>
      DateTime.now().difference(created) > const Duration(minutes: 15);
}
