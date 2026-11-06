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

  static bool hasUpdate(Map preview, Map installed) {
    final manifest = preview['manifest'] as Map;
    if (manifest['id'] != installed['id']) {
      throw const FormatException(
        'The repository release belongs to a different plugin.',
      );
    }
    final comparison = compareVersions(
      '${manifest['version']}',
      '${installed['version']}',
    );
    return comparison > 0 ||
        (comparison == 0 && preview['sha256'] != installed['sha256']);
  }

  static int compareVersions(String a, String b) {
    final first = a.split('-');
    final second = b.split('-');
    final coreA = first.first.split('.');
    final coreB = second.first.split('.');
    for (var i = 0; i < 3; i++) {
      final comparison = BigInt.parse(
        coreA[i],
      ).compareTo(BigInt.parse(coreB[i]));
      if (comparison != 0) return comparison;
    }
    if (first.length == 1 || second.length == 1) {
      return (first.length == 1 ? 1 : 0) - (second.length == 1 ? 1 : 0);
    }
    final preA = first.skip(1).join('-').split('.');
    final preB = second.skip(1).join('-').split('.');
    for (var i = 0; i < preA.length && i < preB.length; i++) {
      final numberA = BigInt.tryParse(preA[i]);
      final numberB = BigInt.tryParse(preB[i]);
      final comparison = numberA != null && numberB != null
          ? numberA.compareTo(numberB)
          : numberA != null
          ? -1
          : numberB != null
          ? 1
          : preA[i].compareTo(preB[i]);
      if (comparison != 0) return comparison;
    }
    return preA.length.compareTo(preB.length);
  }

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

  Future<Uint8List> _get(Uri uri, int limit, {String? accept}) async {
    final abort = Completer<void>();
    final timer = Timer(const Duration(seconds: 30), abort.complete);
    try {
      return await _read(
        uri,
        limit,
        abort.future,
        accept,
      ).timeout(const Duration(seconds: 31));
    } finally {
      timer.cancel();
    }
  }

  Future<Uint8List> _read(
    Uri uri,
    int limit,
    Future<void> abort,
    String? accept,
  ) async {
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
      if (accept != null) request.headers['Accept'] = accept;
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
            'Public repository, stable release, kiosk-satellite-plugin.json, README.md or release asset was not found.',
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

  /// The latest stable release of [repository] and its manifest. Costs one
  /// GitHub API request.
  Future<_Release> _latestRelease(Uri repository) async {
    final release = jsonDecode(
      utf8.decode(
        await _get(
          Uri.https(
            'api.github.com',
            '/repos${repository.path}/releases/latest',
          ),
          128 * 1024,
        ),
      ),
    );
    if (release is! Map ||
        release['draft'] != false ||
        release['prerelease'] != false ||
        release['assets'] is! List) {
      throw const FormatException(
        'GitHub did not return a published stable release',
      );
    }
    final tag = release['tag_name'];
    if (tag is! String ||
        !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,150}$').hasMatch(tag)) {
      throw const FormatException('Invalid release tag');
    }
    final assets = release['assets'] as List;
    Uri assetUrl(String name, int limit) {
      final matches = assets
          .whereType<Map>()
          .where((a) => a['name'] == name)
          .toList();
      if (matches.length != 1 || matches.single['state'] != 'uploaded') {
        throw FormatException('Release needs exactly one uploaded $name asset');
      }
      final asset = matches.single;
      final uploader = asset['uploader'];
      if (uploader is! Map ||
          uploader['id'] != 41898282 ||
          uploader['login'] != 'github-actions[bot]' ||
          uploader['type'] != 'Bot') {
        throw FormatException(
          'Release asset $name must be published by GitHub Actions. '
          'Manually uploaded files are not supported.',
        );
      }

      if (asset['size'] is! int ||
          (asset['size'] as int) <= 0 ||
          (asset['size'] as int) > limit) {
        throw FormatException(
          'Release asset $name exceeds the size limit or is empty',
        );
      }
      // Repository names ignore case, but tag and asset names must match exactly.
      final actual = Uri.tryParse(
        asset['browser_download_url'] as String? ?? '',
      );
      if (actual == null ||
          actual.scheme != 'https' ||
          actual.host != 'github.com' ||
          actual.userInfo.isNotEmpty ||
          actual.hasPort ||
          actual.hasQuery ||
          actual.hasFragment ||
          actual.pathSegments.length != 6 ||
          '/${actual.pathSegments.take(2).join('/')}'.toLowerCase() !=
              repository.path ||
          actual.pathSegments.skip(2).join('/') !=
              'releases/download/$tag/$name') {
        throw FormatException('Invalid release URL for $name');
      }
      return actual;
    }

    const manifestName = 'kiosk-satellite-plugin.json';
    final manifest = jsonDecode(
      utf8.decode(await _get(assetUrl(manifestName, 32 * 1024), 32 * 1024)),
    );
    if (manifest is! Map || manifest['schemaVersion'] != 1) {
      throw const FormatException(
        'Invalid kiosk-satellite-plugin.json manifest',
      );
    }
    final id = manifest['id'];
    final version = manifest['version'];
    if (id is! String ||
        id.length > 64 ||
        !RegExp(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$').hasMatch(id) ||
        version is! String ||
        version.length > 40 ||
        !RegExp(
          r'^[0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9.-]+)?$',
        ).hasMatch(version)) {
      throw const FormatException('Invalid plugin ID or version');
    }
    return _Release(tag, assets, manifest, assetUrl);
  }

  /// The manifest and package digest of the latest release of [url], for
  /// the update check. Unlike [preview] this reads no package checksum or
  /// README and leaves no install approval behind.
  Future<({Map manifest, String? sha256})> latestRelease(String url) async {
    final release = await _latestRelease(repositoryUrl(url));
    final package = release.packageName;
    final digest = release.assets
        .whereType<Map>()
        .where((a) => a['name'] == package)
        .firstOrNull?['digest'];
    return (
      manifest: release.manifest,
      sha256: digest is String && digest.startsWith('sha256:')
          ? digest.substring('sha256:'.length)
          : null,
    );
  }

  Future<Map<String, Object?>> preview(String url) async {
    final repository = repositoryUrl(url);
    final release = await _latestRelease(repository);
    final tag = release.tag;
    final assets = release.assets;
    final manifest = release.manifest;
    final assetUrl = release.assetUrl;
    final packageName = release.packageName;
    final downloadUrl = assetUrl(packageName, maxPackageBytes);
    final checksumUrl = assetUrl('$packageName.sha256', 1024);
    final checksum = RegExp(
      r'^([a-f0-9]{64}) [ *](.+)$',
    ).firstMatch(utf8.decode(await _get(checksumUrl, 1024)).trim());
    if (checksum == null || checksum.group(2) != packageName) {
      throw const FormatException(
        'Invalid release checksum or package filename',
      );
    }
    final digest = checksum.group(1)!;
    final packageAsset = assets.whereType<Map>().singleWhere(
      (a) => a['name'] == packageName,
    );
    if (packageAsset['digest'] != 'sha256:$digest') {
      throw const FormatException(
        'The release checksum must match GitHub asset SHA-256 digest',
      );
    }

    // The README is read by tag, not by the tag's commit: looking up the
    // commit costs a GitHub API request, and a person without a GitHub login
    // gets 60 of those an hour per network. The package stays pinned by its
    // SHA-256, so only the README depends on the tag.
    final base = Uri.https(
      'raw.githubusercontent.com',
      '${repository.path}/refs/tags/$tag/',
    );
    final readme = utf8.decode(
      await _get(base.resolve('README.md'), 128 * 1024),
    );
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
      'manifest': manifest,
      'releaseTag': tag,
      'readme': readme,
      'readmeBaseUrl': base.toString(),
      'sha256': digest,
      'downloadUrl': downloadUrl.toString(),
    };
    // Keep a private deep copy. UI or command callers cannot alter approval data.
    _previews[token] = _Preview(
      Map<String, Object?>.from(jsonDecode(jsonEncode(data)) as Map),
    );
    return data;
  }

  /// The package of a release already installed, fetched again by its tag
  /// and accepted only with the SHA-256 it was installed with. A fleet
  /// leader uses it for plugins installed before packages were kept.
  Future<Uint8List> downloadRelease({
    required String repository,
    required String tag,
    required String id,
    required String version,
    required String digest,
  }) async {
    final repo = repositoryUrl(repository);
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,150}$').hasMatch(tag) ||
        !RegExp(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$').hasMatch(id) ||
        !RegExp(
          r'^[0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9.-]+)?$',
        ).hasMatch(version)) {
      throw const FormatException('Invalid plugin release');
    }
    final bytes = await _get(
      Uri.https(
        'github.com',
        '${repo.path}/releases/download/$tag/$id-$version.zip',
      ),
      maxPackageBytes,
    );
    if (sha256.convert(bytes).toString() != digest) {
      throw const FormatException(
        'The release package no longer matches the installed plugin',
      );
    }
    return bytes;
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
        for (final key in [
          'repository',
          'releaseTag',
          'readme',
          'readmeBaseUrl',
        ])
          key: data[key],
      }),
    };
  }

  void close() {
    _previews.clear();
    _client.close();
  }
}

class _Release {
  const _Release(this.tag, this.assets, this.manifest, this.assetUrl);
  final String tag;
  final List assets;
  final Map manifest;

  /// A checked download URL for the named asset, up to a size limit.
  final Uri Function(String name, int limit) assetUrl;

  String get packageName => '${manifest['id']}-${manifest['version']}.zip';
}

class _Preview {
  _Preview(this.data);
  final Map<String, Object?> data;
  final created = DateTime.now();
  bool get expired =>
      DateTime.now().difference(created) > const Duration(minutes: 15);
}
