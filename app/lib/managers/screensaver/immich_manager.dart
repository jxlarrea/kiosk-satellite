import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/locale_dates.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'screensaver_widgets.dart';

/// One entry of the Immich screensaver playlist.
class ImmichAsset {
  const ImmichAsset({required this.id, required this.isVideo, this.aspect});

  final String id;
  final bool isVideo;

  /// Width over height as the photo will appear, from the server's EXIF,
  /// or null when the server did not say. Known up front, it lets the
  /// playlist be arranged into pairs without downloading anything.
  final double? aspect;
}

/// The metadata overlay's lines and the setting that carries each, in the
/// order they are drawn (issue #268). The panel, the corner bookkeeping and
/// the detail lookup all read the same map, so a line that is off is a line
/// nobody works for.
/// `camera` (the model) and `settings` (the exposure) are the two halves of
/// one line and share a toggle.
const immichMetadataFields = <String, defs.SettingDef<bool>>{
  'album': defs.screensaverImmichMetadataAlbum,
  'date': defs.screensaverImmichMetadataDate,
  'camera': defs.screensaverImmichMetadataCamera,
  'settings': defs.screensaverImmichMetadataCamera,
  'location': defs.screensaverImmichMetadataLocation,
};

/// Whether one metadata line is on. Lines the overlay itself is off for
/// never count.
bool immichMetadataFieldOn(SettingsManager settings, String field) =>
    settings.get(defs.screensaverImmichMetadata) &&
    settings.get(immichMetadataFields[field]!);

/// Whether the overlay has anything left to say: the master toggle on and
/// at least one line kept. With every line off the panel stands down
/// entirely rather than claiming a corner for an empty block.
bool immichMetadataVisible(SettingsManager settings) =>
    settings.get(defs.screensaverImmichMetadata) &&
    immichMetadataFields.values.any((def) => settings.get(def));

/// The corner the single-photo metadata panel settles in: its configured
/// corner, or the first free one when a corner widget owns that (the panel
/// steps aside rather than stacking). Null when the overlay is off, or on
/// the (unlikely) fully claimed screen where the panel stands down.
///
/// Shared by the panel itself and the At a Glance row, which narrows and
/// wraps when this lands in a bottom corner so the two never overlap.
String? immichMetadataCorner(SettingsManager settings) {
  if (!immichMetadataVisible(settings)) return null;
  final claimed = {
    for (final w in decodeScreensaverWidgets(
      settings.get(defs.screensaverWidgets),
    ))
      if (screensaverWidgetAllowedOnMode(w.type, 'immich')) w.position,
  };
  final preferred = settings.get(defs.screensaverImmichMetadataPosition);
  return [
    preferred,
    ...defs.cornerOptions,
  ].where((corner) => !claimed.contains(corner)).firstOrNull;
}

/// An aspect ratio (width over height) counts as portrait below this. Not
/// 1.0: a square photo pairs badly, reading as two small pictures rather
/// than one full screen.
const _portraitAspect = 0.95;

/// A screen this wide (or wider) has room for two portrait photos. Narrower
/// panels would halve into slivers, which is worse than the empty sides the
/// pairing exists to avoid.
const _pairableScreenAspect = 1.2;

/// Whether a photo of this shape (width over height, null when the decoder
/// could not say) is portrait. An unmeasurable photo never pairs.
bool immichPortraitPhoto(double? aspect) =>
    aspect != null && aspect < _portraitAspect;

/// Whether a panel of this shape has room for a pair.
bool immichPairableScreen(double screenAspect) =>
    screenAspect >= _pairableScreenAspect;

/// Whether two consecutive photos should share the screen: both portrait,
/// on a landscape panel.
bool immichPairsPortrait({
  required double screenAspect,
  required double? first,
  required double? second,
}) =>
    immichPairableScreen(screenAspect) &&
    immichPortraitPhoto(first) &&
    immichPortraitPhoto(second);

/// The shape a photo will appear in, from an Immich `exifInfo` block:
/// width over height, with the axes swapped when the orientation tag says
/// the picture is turned a quarter circle (a portrait phone photo is
/// commonly stored as a landscape frame plus that tag). Null when the
/// server reported no usable dimensions.
double? exifAspect(Object? exifInfo) {
  if (exifInfo is! Map) return null;
  final width = (exifInfo['exifImageWidth'] as num?)?.toDouble();
  final height = (exifInfo['exifImageHeight'] as num?)?.toDouble();
  if (width == null || height == null || width <= 0 || height <= 0) {
    return null;
  }
  // Immich passes the tag through as the string exiftool read, so "6" and
  // 6 both turn up depending on the version.
  final orientation = int.tryParse('${exifInfo['orientation'] ?? ''}') ?? 1;
  final turned = orientation >= 5 && orientation <= 8;
  return turned ? height / width : width / height;
}

/// [assets] reordered so every portrait photo is followed by the portrait
/// photo that will share the screen with it.
///
/// Pairing at display time can only look at the next entry, so a portrait
/// photo between two landscape ones would never find a partner however many
/// other portrait shots the album holds. Here the whole playlist is known,
/// so each portrait photo reaches forward for the next one and brings it
/// back to sit beside it. Everything else keeps its order, and no photo is
/// shown twice or dropped: this is a reordering, nothing more.
///
/// A photo whose shape the server did not report stays where it is and
/// takes its chances with the display-time check, which measures the file
/// itself.
List<ImmichAsset> arrangeImmichPairs(
  List<ImmichAsset> assets, {
  required double screenAspect,
}) {
  if (!immichPairableScreen(screenAspect)) return assets;
  final remaining = [...assets];
  final out = <ImmichAsset>[];
  while (remaining.isNotEmpty) {
    final asset = remaining.removeAt(0);
    out.add(asset);
    if (asset.isVideo || !immichPortraitPhoto(asset.aspect)) continue;
    // The next portrait photo anywhere ahead, pulled back to sit beside
    // this one. None left means this photo shows on its own, which is the
    // honest answer at the tail of the playlist.
    final partner = remaining.indexWhere(
      (a) => !a.isVideo && immichPortraitPhoto(a.aspect),
    );
    if (partner >= 0) out.add(remaining.removeAt(partner));
  }
  return out;
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
      // Turning the album line back on has to re-look-up: the cached
      // details were gathered while the line was off, so they carry no
      // album and would keep the row empty until the app restarts.
      if (e.key == defs.screensaverImmichMetadataAlbum.key ||
          e.key == defs.screensaverImmichMetadata.key) {
        _details.clear();
      }
    });

    commands.register(
      Command(
        name: 'immichValidate',
        description:
            'Validate the configured Immich server and API key, and mark '
            'the connection validated on success. Checks the calls the '
            'screensaver actually needs: album listing, asset search, and '
            'one preview fetch.',
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
            return CommandResult.fail(readableError(e));
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
      // Every call the screensaver depends on, so a key that can list
      // albums but not read assets, or search them but not fetch their
      // previews (Immich's asset.view is a separate permission from
      // asset.download, issue #222), fails here at the button, not at 2am.
      await _albums();
      final albumId = _settings.get(defs.screensaverImmichAlbum);
      final found = await _search(
        page: 1,
        size: _probeAssets,
        albumId: albumId,
      );
      final items = ((found['items'] as List?) ?? const []).cast<Map>();
      // Several assets, not one: the search answers newest first, and the
      // newest asset in a library taking phone backups is routinely the one
      // Immich has not generated a preview for yet. One 200 proves the key
      // may view previews, which is all this probe is here to establish.
      _ApiException? lastMissing;
      for (final item in items) {
        final id = '${item['id']}';
        final response = await http
            .get(
              _imageUri(ImmichAsset(id: id, isVideo: false)),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 30));
        try {
          _throwUnlessOk(response, scope: 'asset.view');
          return null;
        } on _ApiException catch (e) {
          // A 404 is the server saying this one asset has no preview file
          // (still processing, generation failed, external library not
          // scanned, file offline) — a per-asset condition that says
          // nothing about the key, so try the next asset (issue #285).
          // Anything else is about the credentials and fails the button.
          if (e.status != 404) rethrow;
          lastMissing = e;
          log.warn(name, 'validate: preview probe skipped ($e)');
        }
      }
      // Every asset tried came back without a preview. The screensaver
      // would have nothing to show, but the connection itself is sound, so
      // this passes with the reason in the log rather than blocking every
      // setting below the button on the server's processing queue.
      if (lastMissing != null) {
        log.warn(
          name,
          'validate: no asset had a preview to fetch; passing on '
          'albums and search alone',
        );
      }
      return null;
    } catch (e) {
      log.warn(name, 'validate failed: $e');
      return readableError(e);
    }
  }

  /// How many assets the validation preview probe may try before giving up
  /// on finding one with a preview.
  static const _probeAssets = 5;

  /// [e] as a message a settings page or the screensaver can show. An HTTP
  /// rejection and an unreachable host are different problems (issue #222):
  /// only genuine transport failures read as "could not reach".
  String readableError(Object e) {
    if (e is _ApiException) {
      if (e.status == 401) return 'The API key was rejected.';
      if (e.status == 403) {
        if (e.scope != null) {
          return 'The API key is missing the ${e.scope} permission.';
        }
        return 'The API key is missing a permission: ${e.message}';
      }
      return 'The server answered ${e.status}: ${e.message}';
    }
    if (e is SocketException || e is TimeoutException) {
      return 'Could not reach $_base.';
    }
    return 'Could not talk to the server: $e';
  }

  Future<List<Map<String, Object?>>> _albums() async {
    // Two calls, not one: /api/albums returns only the key owner's own
    // albums, and albums shared WITH the user come from the same endpoint
    // with ?shared=true (discussion #109). An album can appear in both
    // (owned and shared out), so the merge dedupes by id.
    final responses = await Future.wait([
      http
          .get(Uri.parse('$_base/api/albums'), headers: _headers)
          .timeout(const Duration(seconds: 10)),
      http
          .get(Uri.parse('$_base/api/albums?shared=true'), headers: _headers)
          .timeout(const Duration(seconds: 10)),
    ]);
    final merged = <String, Map<String, Object?>>{};
    for (final response in responses) {
      _throwUnlessOk(response, scope: 'album.read');
      final list = jsonDecode(response.body) as List;
      for (final album in list.cast<Map<String, dynamic>>()) {
        merged['${album['id']}'] = {
          'id': album['id'],
          'name': album['albumName'] ?? '',
          'count': album['assetCount'] ?? 0,
        };
      }
    }
    final albums = merged.values.toList();
    albums.sort(
      (a, b) =>
          '${a['name']}'.toLowerCase().compareTo('${b['name']}'.toLowerCase()),
    );
    return albums;
  }

  Future<Map<String, dynamic>> _search({
    required int page,
    required int size,
    String? albumId,
    bool withExif = false,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_base/api/search/metadata'),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'page': page,
            'size': size,
            'withExif': withExif,
            if (albumId != null && albumId.isNotEmpty) 'albumIds': [albumId],
          }),
        )
        .timeout(const Duration(seconds: 20));
    _throwUnlessOk(response, scope: 'asset.read');
    return (jsonDecode(response.body) as Map<String, dynamic>)['assets']
        as Map<String, dynamic>;
  }

  /// [scope] is the Immich permission the endpoint checks, so a 403 can
  /// name what the key is missing instead of parroting the server's
  /// generic denial (issue #222).
  void _throwUnlessOk(http.Response response, {String? scope}) {
    if (response.statusCode == 200) return;
    String message = response.reasonPhrase ?? '';
    try {
      message = (jsonDecode(response.body) as Map)['message'] as String;
    } catch (_) {}
    throw _ApiException(
      response.statusCode,
      message,
      path: response.request?.url.path,
      scope: scope,
    );
  }

  /// The playlist: every image and video of the configured source, in the
  /// server's order (newest first). The view shuffles if asked to.
  ///
  /// "Photos only" drops the videos here, at the source: motion/live photos
  /// often land in Immich as short video assets, and a two-second clip
  /// between stills makes the whole slideshow feel broken (issue #32).
  Future<List<ImmichAsset>> listAssets() async {
    final albumId = _settings.get(defs.screensaverImmichAlbum);
    final photosOnly = _settings.get(defs.screensaverImmichPhotosOnly);
    // The EXIF comes along only when something wants it: pairing portrait
    // photos needs every photo's shape up front to arrange the playlist,
    // and it is the one feature that does.
    final withExif = _settings.get(defs.screensaverImmichPairPortrait);
    final assets = <ImmichAsset>[];
    var page = 1;
    while (assets.length < _maxPlaylist) {
      final result = await _search(
        page: page,
        size: 500,
        albumId: albumId,
        withExif: withExif,
      );
      for (final item in (result['items'] as List).cast<Map>()) {
        final isVideo = item['type'] == 'VIDEO';
        if (photosOnly && isVideo) continue;
        assets.add(
          ImmichAsset(
            id: item['id'] as String,
            isVideo: isVideo,
            aspect: isVideo ? null : exifAspect(item['exifInfo']),
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
        unawaited(cached.setLastModified(DateTime.now()).catchError((_) {}));
        return cached.readAsBytes();
      }
    }
    final response = await http
        .get(_imageUri(asset), headers: _headers)
        .timeout(const Duration(seconds: 30));
    _throwUnlessOk(response, scope: 'asset.view');
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
      _throwUnlessOk(response, scope: 'asset.read');
      final detail = jsonDecode(response.body) as Map<String, dynamic>;
      final exif = (detail['exifInfo'] as Map<String, dynamic>?) ?? const {};

      final when = exif['dateTimeOriginal'] ?? detail['localDateTime'] ?? '';
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
      // only worth making in whole-library mode. Turned off, the line costs
      // nothing at all: the extra request is never made.
      final configured = _settings.get(defs.screensaverImmichAlbumName);
      if (immichMetadataFieldOn(_settings, 'album')) {
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
      }
    } catch (e) {
      log.debug(name, 'asset details failed (${asset.id}): $e');
      return out; // uncached, so a transient failure retries next loop
    }
    if (_details.length > 300) _details.clear();
    _details[asset.id] = out;
    return out;
  }

  // Localized via the device locale (issue #108): "August 2, 2026" on an
  // American device, "2 augustus 2026" on a Dutch one.
  static String _formatDate(DateTime date) => longDate(date);

  /// 6.0 → "6", 1.7 → "1.7": EXIF numbers read like camera markings.
  static String _trimNum(num value) =>
      value == value.toInt() ? '${value.toInt()}' : value.toStringAsFixed(1);

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
  const _ApiException(this.status, this.message, {this.path, this.scope});

  final int status;
  final String message;

  /// The endpoint that answered, so a logged failure identifies itself
  /// without instrumenting a reverse proxy (issue #222).
  final String? path;

  /// The Immich permission the endpoint checks, when known.
  final String? scope;

  @override
  String toString() =>
      'HTTP $status${path == null ? '' : ' on $path'}: $message';
}
