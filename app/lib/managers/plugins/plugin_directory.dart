import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../update/update_http_client.dart';
import 'plugin_repository.dart';

/// Why Browse plugins has no list to show, as the person reads it.
class PluginDirectoryError implements Exception {
  const PluginDirectoryError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Community Plugins: the list kiosksatellite.com builds twice a day from
/// the plugins repository, with each plugin's latest release, stars,
/// downloads and active installs. Installing still goes through the
/// repository preview, so the list only decides what Browse plugins shows.
class PluginDirectory {
  PluginDirectory({
    http.Client Function()? clientFactory,
    Future<File?> Function()? cacheFile,
    Uri? url,
    DateTime Function()? now,
  }) : _clientFactory = clientFactory ?? createStrictHttpClient,
       _cacheFile = cacheFile ?? _defaultCacheFile,
       url = url ?? defaultUrl,
       _now = now ?? DateTime.now;

  /// A build can point at a test server with --dart-define.
  static final defaultUrl = Uri.parse(
    const String.fromEnvironment(
      'KS_PLUGIN_DIRECTORY_URL',
      defaultValue: 'https://kiosksatellite.com/plugins/index.json',
    ),
  );
  static const maxBytes = 2 * 1024 * 1024;

  /// The list changes twice a day, so a page opened again within the hour
  /// reads the copy it already has.
  static const freshFor = Duration(hours: 1);

  final http.Client Function() _clientFactory;
  final Future<File?> Function() _cacheFile;
  final DateTime Function() _now;
  final Uri url;
  Map<String, Object?>? _data;
  DateTime? _fetched;
  Future<Map<String, Object?>>? _reading;

  static Future<File?> _defaultCacheFile() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}/plugin_directory.json');
    } catch (_) {
      return null;
    }
  }

  /// The listed plugins, newest copy first: a fresh download, then the copy
  /// kept from the last one. `error` says why a kept copy is shown. Throws
  /// only when there is no copy at all.
  Future<Map<String, Object?>> read({bool refresh = false}) {
    final fetched = _fetched;
    if (!refresh &&
        _data != null &&
        fetched != null &&
        _now().difference(fetched) < freshFor) {
      return Future.value(_result());
    }
    return _reading ??= _read().whenComplete(() => _reading = null);
  }

  /// Whether the list has [repository]: null when it cannot be read.
  Future<bool?> lists(String repository) async =>
      (await lookup(repository))?.listed;

  /// Whether the list has [repository], and the icon it shows for it.
  /// Null when the list cannot be read.
  Future<({bool listed, String? icon})?> lookup(String repository) async {
    try {
      final key = PluginRepository.repositoryUrl(repository).toString();
      final data = await read().timeout(const Duration(seconds: 8));
      final entry = (data['plugins'] as List)
          .cast<Map>()
          .where((p) => p['repositoryKey'] == key)
          .firstOrNull;
      return (listed: entry != null, icon: entry?['icon'] as String?);
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?> _result({String? error}) => {
    ..._data!,
    'fetchedAt': _fetched?.toUtc().toIso8601String(),
    'error': ?error,
  };

  Future<Map<String, Object?>> _read() async {
    try {
      final body = await _download();
      final data = parse(jsonDecode(utf8.decode(body)), origin: url);
      _data = data;
      _fetched = _now();
      unawaited(_save(body));
      return _result();
    } catch (error) {
      _data ??= await _load();
      if (_data == null) throw PluginDirectoryError(_describe(error));
      return _result(error: _describe(error));
    }
  }

  static String _describe(Object error) => switch (error) {
    SocketException() || TimeoutException() || http.ClientException() =>
      'Could not reach Community Plugins. Check the internet connection.',
    _ => 'Could not load Community Plugins. Try again later.',
  };

  Future<Uint8List> _download() async {
    final client = _clientFactory();
    try {
      final request = http.Request('GET', url)
        ..headers['User-Agent'] = 'Kiosk-Satellite-Plugins'
        ..headers['Accept'] = 'application/json';
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        await response.stream.listen((_) {}).cancel();
        throw StateError('Community Plugins answered ${response.statusCode}');
      }
      final data = BytesBuilder(copy: false);
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 15),
      )) {
        if (data.length + chunk.length > maxBytes) {
          throw const FormatException('The plugin list is too large');
        }
        data.add(chunk);
      }
      return data.takeBytes();
    } finally {
      client.close();
    }
  }

  Future<void> _save(Uint8List body) async {
    try {
      final file = await _cacheFile();
      if (file == null) return;
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsBytes(body, flush: true);
      await temporary.rename(file.path);
      await file.setLastModified(_now());
    } catch (_) {}
  }

  Future<Map<String, Object?>?> _load() async {
    try {
      final file = await _cacheFile();
      if (file == null || !await file.exists()) return null;
      final data = parse(jsonDecode(await file.readAsString()), origin: url);
      _fetched = await file.lastModified();
      return data;
    } catch (_) {
      return null;
    }
  }

  /// The plugins the list holds that pass the checks KS would run on them
  /// anyway, ready to show. Anything else in an entry is left out.
  ///
  /// An icon shows only from the server the list came from ([origin]).
  static Map<String, Object?> parse(Object? json, {Uri? origin}) {
    if (json is! Map ||
        json['schemaVersion'] != 1 ||
        json['plugins'] is! List) {
      throw const FormatException('Community Plugins sent an unknown format');
    }
    final plugins = <Map<String, Object?>>[];
    final seen = <String>{};
    for (final raw in (json['plugins'] as List).take(2000)) {
      final entry = _entry(raw, origin);
      if (entry != null && seen.add(entry['id'] as String)) plugins.add(entry);
    }
    return {
      'generated': json['generated'] is String ? json['generated'] : null,
      'plugins': plugins,
    };
  }

  static Map<String, Object?>? _entry(Object? raw, Uri? origin) {
    if (raw is! Map || raw['status'] != 'ok') return null;
    String? text(String key, int limit) {
      final value = raw[key];
      return value is String && value.trim().isNotEmpty && value.length <= limit
          ? value
          : null;
    }

    int count(String key) {
      final value = raw[key];
      return value is int && value >= 0 ? value : 0;
    }

    final id = text('id', 64);
    final name = text('name', 80);
    final version = text('version', 40);
    final repository = text('repository', 200);
    if (id == null ||
        name == null ||
        version == null ||
        repository == null ||
        !RegExp(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$').hasMatch(id) ||
        !RegExp(
          r'^[0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9.-]+)?$',
        ).hasMatch(version)) {
      return null;
    }
    final Uri key;
    try {
      key = PluginRepository.repositoryUrl(repository);
    } on FormatException {
      return null;
    }
    // The icon the list server publishes from the plugin's own package. An
    // address elsewhere never decides where the kiosk fetches a picture.
    final icon = Uri.tryParse(text('icon', 300) ?? '');
    final installs = raw['installs'];
    final capabilities = raw['capabilities'];
    final sha256 = text('sha256', 64);
    final minAppVersion = text('minAppVersion', 20);
    return {
      'id': id,
      'name': name,
      'description': text('description', 1000) ?? '',
      'author': text('author', 120) ?? '',
      'license': text('license', 120) ?? '',
      'version': version,
      'released': text('released', 40),
      'added': text('added', 40),
      'repository': repository,
      'repositoryKey': key.toString(),
      'owner': text('owner', 100),
      'icon':
          icon != null &&
              origin != null &&
              icon.scheme == origin.scheme &&
              icon.host == origin.host &&
              icon.port == origin.port &&
              icon.path.endsWith('.png')
          ? icon.toString()
          : null,
      'stars': count('stars'),
      'downloads': count('downloads'),
      'installs': installs is int && installs >= 0 ? installs : null,
      'minAndroidSdk': raw['minAndroidSdk'] is int ? raw['minAndroidSdk'] : 24,
      'minAppVersion':
          minAppVersion != null && appVersionPattern.hasMatch(minAppVersion)
          ? minAppVersion
          : null,
      'capabilities': capabilities is List
          ? [
              for (final c in capabilities.take(20))
                if (c is String && c.length <= 40) c,
            ]
          : const <String>[],
      'sha256': sha256 != null && RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256)
          ? sha256
          : null,
    };
  }

  /// A Kiosk Satellite release, the way a manifest's minAppVersion names it.
  static final appVersionPattern = RegExp(
    r'^[0-9]{4}\.(?:[1-9]|1[0-2])\.(?:0|[1-9][0-9]{0,3})$',
  );

  /// Whether the running release [current], such as 2026.10.39 or a build
  /// of it, is [required] or newer. A version that is not a release, such
  /// as a local build's, never holds a plugin back. PluginManifest.kt
  /// decides the same way at install.
  static bool appVersionAtLeast(String current, String required) {
    final running = RegExp(
      r'^([0-9]+)\.([0-9]+)\.([0-9]+)',
    ).firstMatch(current);
    if (running == null) return true;
    final needed = required.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      final part = int.parse(running.group(i + 1)!);
      if (part != needed[i]) return part > needed[i];
    }
    return true;
  }

  /// A release read from GitHub in the shape of a list entry, so
  /// [installStatus] can judge a plugin the list does not carry.
  static Map<String, Object?> releaseEntry(
    Map manifest, {
    required String repository,
    String? sha256,
  }) {
    final minAppVersion = manifest['minAppVersion'];
    return {
      'id': manifest['id'],
      'version': manifest['version'],
      'repositoryKey': PluginRepository.repositoryUrl(repository).toString(),
      'sha256': sha256,
      'minAppVersion':
          minAppVersion is String && appVersionPattern.hasMatch(minAppVersion)
          ? minAppVersion
          : null,
    };
  }

  /// How a listed plugin stands against the installed one with its ID:
  /// installed from this repository, and whether the list knows a newer
  /// release. A plugin with the same ID from elsewhere counts as installed
  /// but never offers that update. A release that needs a newer
  /// [appVersion] is neither offered to install nor as an update, and
  /// `needsAppVersion` names the release it needs.
  static Map<String, Object?> installStatus(
    Map<String, Object?> entry,
    Map<String, Object?>? plugin, {
    String appVersion = '',
  }) {
    final required = entry['minAppVersion'];
    final needs = required is String && !appVersionAtLeast(appVersion, required)
        ? required
        : null;
    if (plugin == null) {
      return {'installed': false, 'needsAppVersion': ?needs};
    }
    final source = plugin['source'];
    String? repository;
    try {
      repository = source is Map && source['repository'] is String
          ? PluginRepository.repositoryUrl(
              source['repository'] as String,
            ).toString()
          : null;
    } on FormatException {
      repository = null;
    }
    final same = repository == entry['repositoryKey'];
    var update = false;
    if (same) {
      try {
        final comparison = PluginRepository.compareVersions(
          '${entry['version']}',
          '${plugin['version']}',
        );
        update =
            comparison > 0 ||
            (comparison == 0 &&
                entry['sha256'] != null &&
                plugin['sha256'] != null &&
                entry['sha256'] != plugin['sha256']);
      } catch (_) {}
    }
    return {
      'installed': true,
      'installedVersion': plugin['version'],
      'sameSource': same,
      'updateAvailable': update && needs == null,
      if (update) 'needsAppVersion': ?needs,
    };
  }
}
