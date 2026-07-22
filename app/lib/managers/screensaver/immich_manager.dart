import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// One entry of the Immich screensaver playlist.
class ImmichAsset {
  const ImmichAsset({required this.id, required this.isVideo});

  final String id;
  final bool isVideo;
}

/// The Immich Media screensaver's server side: connection validation, album
/// listing, the asset playlist, and the local image cache.
///
/// The API surface is deliberately small — albums, a paged metadata search
/// for the playlist, and the per-asset content endpoints. Images are fetched
/// as Immich's `preview` thumbnails (screen-sized, a few hundred KB) rather
/// than originals, which can be 50 MB RAWs a tablet has no business
/// decoding. Videos stream from the `video/playback` endpoint and are never
/// cached: the cache cap counts items, and a single long video would blow
/// through any byte budget the count implies.
class ImmichManager extends Manager {
  ImmichManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'immich';

  /// Never grows past this many playlist entries, however large the library:
  /// ids are small, but an unbounded list on a 1 GB tablet is a leak with
  /// extra steps.
  static const _maxPlaylist = 10000;

  String get _base {
    var url = _settings.get(defs.screensaverImmichUrl).trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Map<String, String> get _headers => {
    'x-api-key': _settings.get(defs.screensaverImmichApiKey),
  };

  bool get configured =>
      _base.isNotEmpty &&
      _settings.get(defs.screensaverImmichApiKey).isNotEmpty;

  @override
  Future<void> init() async {
    bus.on<SettingChanged>().listen((e) {
      // A changed server or key invalidates the validation — and with it
      // every dependent row, until the user validates again. NOT during an
      // import: the backup's validated flag arrives together with the very
      // credentials it validated, and resetting after the fact forced a
      // pointless re-validate on every restored device.
      if ((e.key == defs.screensaverImmichUrl.key ||
              e.key == defs.screensaverImmichApiKey.key) &&
          !_settings.importing) {
        if (_settings.get(defs.screensaverImmichValidated)) {
          unawaited(_settings.set(defs.screensaverImmichValidated, false));
        }
      }
      // A lowered cap prunes immediately. Writes evict too, but a fully
      // cached playlist never writes again, and "oldest deleted once the
      // cache is full" must hold even then.
      if (e.key == defs.screensaverImmichCacheMax.key) {
        unawaited(_evict());
      }
    });

    commands.register(
      Command(
        name: 'immichValidate',
        description:
            'Validate the configured Immich server and API key, and mark '
            'the connection validated on success. Checks the two calls the '
            'screensaver actually needs: album listing and asset search.',
        handler: (_) async {
          final error = await _validate();
          await _settings.set(defs.screensaverImmichValidated, error == null);
          if (error != null) return CommandResult.fail(error);
          return const CommandResult.ok();
        },
      ),
    );

    commands.register(
      Command(
        name: 'immichAlbums',
        description:
            'The Immich albums, alphabetical: [{id, name, count}]. The '
            '"All media" choice is the UIs\' own first entry, not an album.',
        handler: (_) async {
          try {
            final albums = await _albums();
            return CommandResult.ok(albums);
          } catch (e) {
            return CommandResult.fail(_readableError(e));
          }
        },
      ),
    );

    commands.register(
      Command(
        name: 'immichCacheStats',
        description: 'Local Immich cache usage: {items, bytes}',
        handler: (_) async => CommandResult.ok(await cacheStats()),
      ),
    );

    commands.register(
      Command(
        name: 'immichClearCache',
        description: 'Delete every locally cached Immich item',
        handler: (_) async {
          final dir = await _cacheDir();
          if (await dir.exists()) await dir.delete(recursive: true);
          return const CommandResult.ok();
        },
      ),
    );
  }

  /// Null when the connection works, a user-readable reason when it does not.
  Future<String?> _validate() async {
    if (_base.isEmpty) return 'Enter the server address first.';
    if (_settings.get(defs.screensaverImmichApiKey).isEmpty) {
      return 'Enter an API key first.';
    }
    if (Uri.tryParse(_base)?.host.isEmpty ?? true) {
      return 'The server address is not a valid URL.';
    }
    try {
      // Both calls the screensaver depends on, so a key that can list albums
      // but not read assets fails here at the button, not at 2am.
      await _albums();
      await _search(page: 1, size: 1);
      return null;
    } catch (e) {
      return _readableError(e);
    }
  }

  String _readableError(Object e) {
    if (e is _ApiException) {
      if (e.status == 401) return 'The API key was rejected.';
      if (e.status == 403) {
        return 'The API key is missing a permission: ${e.message}';
      }
      return 'The server answered ${e.status}: ${e.message}';
    }
    if (e is SocketException || e is TimeoutException) {
      return 'Could not reach $_base';
    }
    return 'Could not talk to the server: $e';
  }

  Future<List<Map<String, Object?>>> _albums() async {
    final response = await http
        .get(Uri.parse('$_base/api/albums'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _throwUnlessOk(response);
    final list = jsonDecode(response.body) as List;
    final albums = [
      for (final album in list.cast<Map<String, dynamic>>())
        {
          'id': album['id'],
          'name': album['albumName'] ?? '',
          'count': album['assetCount'] ?? 0,
        },
    ];
    albums.sort(
      (a, b) => '${a['name']}'.toLowerCase().compareTo(
        '${b['name']}'.toLowerCase(),
      ),
    );
    return albums;
  }

  Future<Map<String, dynamic>> _search({
    required int page,
    required int size,
    String? albumId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_base/api/search/metadata'),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'page': page,
            'size': size,
            'withExif': false,
            if (albumId != null && albumId.isNotEmpty) 'albumIds': [albumId],
          }),
        )
        .timeout(const Duration(seconds: 20));
    _throwUnlessOk(response);
    return (jsonDecode(response.body) as Map<String, dynamic>)['assets']
        as Map<String, dynamic>;
  }

  void _throwUnlessOk(http.Response response) {
    if (response.statusCode == 200) return;
    String message = response.reasonPhrase ?? '';
    try {
      message = (jsonDecode(response.body) as Map)['message'] as String;
    } catch (_) {}
    throw _ApiException(response.statusCode, message);
  }

  /// The playlist: every image and video of the configured source, in the
  /// server's order (newest first). The view shuffles if asked to.
  Future<List<ImmichAsset>> listAssets() async {
    final albumId = _settings.get(defs.screensaverImmichAlbum);
    final assets = <ImmichAsset>[];
    var page = 1;
    while (assets.length < _maxPlaylist) {
      final result = await _search(page: page, size: 500, albumId: albumId);
      for (final item in (result['items'] as List).cast<Map>()) {
        assets.add(
          ImmichAsset(
            id: item['id'] as String,
            isVideo: item['type'] == 'VIDEO',
          ),
        );
      }
      final next = result['nextPage'];
      if (next == null) break;
      page = next is num ? next.toInt() : int.tryParse('$next') ?? page + 1;
    }
    return assets;
  }

  /// The streaming URL and headers for a video asset — playback goes
  /// straight to the player, disk never involved.
  Uri videoUri(ImmichAsset asset) =>
      Uri.parse('$_base/api/assets/${asset.id}/video/playback');

  Map<String, String> get videoHeaders => _headers;

  Uri _imageUri(ImmichAsset asset) =>
      Uri.parse('$_base/api/assets/${asset.id}/thumbnail?size=preview');

  /// An image, from the cache when enabled and present, from the server
  /// otherwise. Returns the bytes either way; disk is an implementation
  /// detail of the cache, not the contract.
  Future<Uint8List> imageBytes(ImmichAsset asset) async {
    final caching = _settings.get(defs.screensaverImmichCache);
    File? cached;
    if (caching) {
      cached = File('${(await _cacheDir()).path}/${asset.id}.img');
      if (await cached.exists()) {
        // Touch so eviction's "oldest" means least-recently-shown, not
        // first-ever-downloaded.
        unawaited(
          cached.setLastModified(DateTime.now()).catchError((_) {}),
        );
        return cached.readAsBytes();
      }
    }
    final response = await http
        .get(_imageUri(asset), headers: _headers)
        .timeout(const Duration(seconds: 30));
    _throwUnlessOk(response);
    final bytes = response.bodyBytes;
    if (caching && cached != null) {
      try {
        // Write-then-rename so a torn download never poses as a cache hit.
        final part = File('${cached.path}.part');
        await part.writeAsBytes(bytes, flush: true);
        await part.rename(cached.path);
        unawaited(_evict());
      } catch (e) {
        log.warn(name, 'cache write failed: $e');
      }
    }
    return bytes;
  }

  /// Per-asset details for the metadata overlay, in display-ready lines.
  /// Small in-memory cache: a looping playlist re-shows the same assets, and
  /// the answers never change mid-session.
  final _details = <String, Map<String, String>>{};

  /// The metadata overlay's lines for [asset]: any of `album`, `date`,
  /// `camera`, `settings` (focal length / aperture / ISO) and `location`,
  /// absent when the asset does not carry them. Errors return what is known
  /// (possibly nothing): the overlay is decoration, and a failed lookup must
  /// never disturb the slideshow.
  Future<Map<String, String>> assetDetails(ImmichAsset asset) async {
    final cached = _details[asset.id];
    if (cached != null) return cached;
    final out = <String, String>{};
    try {
      final response = await http
          .get(Uri.parse('$_base/api/assets/${asset.id}'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      _throwUnlessOk(response);
      final detail = jsonDecode(response.body) as Map<String, dynamic>;
      final exif = (detail['exifInfo'] as Map<String, dynamic>?) ?? const {};

      final when =
          exif['dateTimeOriginal'] ?? detail['localDateTime'] ?? '';
      final date = DateTime.tryParse('$when');
      if (date != null) out['date'] = _formatDate(date);

      final make = '${exif['make'] ?? ''}'.trim();
      final model = '${exif['model'] ?? ''}'.trim();
      if (model.isNotEmpty) {
        // Some vendors bake the make into the model ("Canon EOS R5").
        out['camera'] = model.startsWith(make) ? model : '$make $model'.trim();
      }
      final shot = <String>[
        if (exif['focalLength'] is num)
          '${_trimNum(exif['focalLength'] as num)}mm',
        if (exif['fNumber'] is num) 'f/${_trimNum(exif['fNumber'] as num)}',
        if (exif['iso'] is num) 'ISO ${(exif['iso'] as num).toInt()}',
      ];
      if (shot.isNotEmpty) out['settings'] = shot.join('  ');

      final location = <String>[
        for (final key in ['city', 'state', 'country'])
          if ('${exif[key] ?? ''}'.trim().isNotEmpty) '${exif[key]}'.trim(),
      ];
      if (location.isNotEmpty) out['location'] = location.join(', ');

      // The album line: the configured album when one is selected, else the
      // first album the asset belongs to (if any) — its own request, and
      // only worth making in whole-library mode.
      final configured = _settings.get(defs.screensaverImmichAlbumName);
      if (_settings.get(defs.screensaverImmichAlbum).isNotEmpty &&
          configured.isNotEmpty) {
        out['album'] = configured;
      } else {
        final albums = await http
            .get(
              Uri.parse('$_base/api/albums?assetId=${asset.id}'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 10));
        if (albums.statusCode == 200) {
          final list = jsonDecode(albums.body) as List;
          if (list.isNotEmpty) {
            out['album'] = '${(list.first as Map)['albumName'] ?? ''}';
          }
        }
      }
    } catch (e) {
      log.debug(name, 'asset details failed (${asset.id}): $e');
      return out; // uncached, so a transient failure retries next loop
    }
    if (_details.length > 300) _details.clear();
    _details[asset.id] = out;
    return out;
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];

  static String _formatDate(DateTime date) =>
      '${_months[date.month - 1]} ${date.day}, ${date.year}';

  /// 6.0 → "6", 1.7 → "1.7": EXIF numbers read like camera markings.
  static String _trimNum(num value) => value == value.toInt()
      ? '${value.toInt()}'
      : value.toStringAsFixed(1);

  Directory? _cacheDirMemo;

  Future<Directory> _cacheDir() async {
    if (_cacheDirMemo != null) return _cacheDirMemo!;
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/immich_cache');
    await dir.create(recursive: true);
    return _cacheDirMemo = dir;
  }

  Future<List<File>> _cacheFiles() async {
    final dir = await _cacheDir();
    if (!await dir.exists()) return const [];
    return [
      await for (final entry in dir.list())
        if (entry is File && entry.path.endsWith('.img')) entry,
    ];
  }

  Future<Map<String, Object?>> cacheStats() async {
    var bytes = 0;
    final files = await _cacheFiles();
    for (final file in files) {
      try {
        bytes += await file.length();
      } catch (_) {}
    }
    return {'items': files.length, 'bytes': bytes};
  }

  /// Drop the oldest items until the cache fits the configured cap.
  Future<void> _evict() async {
    final max = _settings.get(defs.screensaverImmichCacheMax).toInt();
    if (max <= 0) return;
    final files = await _cacheFiles();
    if (files.length <= max) return;
    final dated = <(File, DateTime)>[];
    for (final file in files) {
      try {
        dated.add((file, (await file.stat()).modified));
      } catch (_) {}
    }
    dated.sort((a, b) => a.$2.compareTo(b.$2));
    for (final (file, _) in dated.take(dated.length - max)) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
}

class _ApiException implements Exception {
  const _ApiException(this.status, this.message);

  final int status;
  final String message;

  @override
  String toString() => 'HTTP $status: $message';
}
