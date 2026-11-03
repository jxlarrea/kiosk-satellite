import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/locale_dates.dart';
import '../../core/manager.dart';
import '../device/device_details.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'photo_metadata.dart';

/// One entry of the Immich screensaver playlist.
class ImmichAsset {
  const ImmichAsset({
    required this.id,
    required this.isVideo,
    this.aspect,
    this.durationSeconds,
  });

  final String id;
  final bool isVideo;

  /// A video's length from the listing, or null for a photo or when the
  /// server did not say. With the stream's size it says how much of the
  /// video the player would buffer at once.
  final double? durationSeconds;

  /// Width over height as the photo will appear, from the server's EXIF,
  /// or null when the server did not say. Known up front, it lets the
  /// playlist be arranged into pairs without downloading anything.
  final double? aspect;
}

/// One person or tag picked by name for a filter (issue #345). This is
/// what the setting stores, so both UIs can show the names without asking
/// the server again, the same shape the launcher keeps its apps in.
class ImmichNamed {
  const ImmichNamed({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, String> toJson() => {'id': id, 'name': name};
}

/// The `[{id, name}]` list a filter setting holds. Anything malformed reads
/// as empty: a filter that cannot be parsed must not take the slideshow
/// down with it.
List<ImmichNamed> decodeImmichNamed(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map && '${item['id'] ?? ''}'.isNotEmpty)
          ImmichNamed(id: '${item['id']}', name: '${item['name'] ?? ''}'),
    ];
  } catch (_) {
    return const [];
  }
}

/// Whether any filter narrows the playlist beyond the chosen source, so an
/// empty playlist can say which of the two to look at.
bool immichFiltersActive(SettingsManager settings) =>
    decodeImmichNamed(settings.get(defs.screensaverImmichPeople)).isNotEmpty ||
    decodeImmichNamed(
      settings.get(defs.screensaverImmichExcludePeople),
    ).isNotEmpty ||
    decodeImmichNamed(settings.get(defs.screensaverImmichTags)).isNotEmpty ||
    decodeImmichNamed(
      settings.get(defs.screensaverImmichExcludeTags),
    ).isNotEmpty ||
    settings.get(defs.screensaverImmichFavoritesOnly) ||
    immichTakenAfter(settings) != null ||
    immichTakenBefore(settings) != null;

/// The oldest capture date the Taken within filter admits, or null for no
/// limit. A rolling window is computed at listing time, so a playlist
/// refreshed tonight moves along with it; Since and Timeframe read the
/// From date instead and stay where they were put (issue #383).
DateTime? immichTakenAfter(SettingsManager settings, {DateTime? now}) {
  final within = settings.get(defs.screensaverImmichTakenWithin);
  if (within == defs.immichTakenSince || within == defs.immichTakenRange) {
    return _immichDay(settings.get(defs.screensaverImmichTakenFrom));
  }
  final days = int.tryParse(within);
  if (days == null || days <= 0) return null;
  return (now ?? DateTime.now()).toUtc().subtract(Duration(days: days));
}

/// The newest capture date admitted, or null for no limit. Only Timeframe
/// sets one, and the To day counts whole: a photo taken that afternoon is
/// in, which is what picking the day means (issue #383).
DateTime? immichTakenBefore(SettingsManager settings) {
  if (settings.get(defs.screensaverImmichTakenWithin) !=
      defs.immichTakenRange) {
    return null;
  }
  final day = _immichDay(settings.get(defs.screensaverImmichTakenTo));
  return day?.add(const Duration(days: 1, microseconds: -1));
}

/// "YYYY-MM-DD" as the start of that day, UTC. Empty or malformed reads as
/// no bound: a filter that cannot be parsed must not empty the frame.
DateTime? _immichDay(String value) {
  if (value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return DateTime.utc(parsed.year, parsed.month, parsed.day);
}

/// The metadata overlay's lines and the setting that carries each, in the
/// order they are drawn (issue #268). The panel, the corner bookkeeping and
/// the detail lookup all read the same map, so a line that is off is a line
/// nobody works for. The panel is shared with the EXIF modes, so the map
/// lives with theirs in photo_metadata.dart.
final immichMetadataFields = photoMetadataDefs['immich']!.fields;

/// Whether one metadata line is on. Lines the overlay itself is off for
/// never count.
bool immichMetadataFieldOn(SettingsManager settings, String field) =>
    photoMetadataFieldOn(settings, 'immich', field);

/// Whether the overlay has anything left to say: the master toggle on and
/// at least one line kept.
bool immichMetadataVisible(SettingsManager settings) =>
    photoMetadataVisible(settings, 'immich');

/// Whether the overlay draws anything at all: the panel, the caption or
/// both, which is when the slide's details are worth fetching.
bool immichMetadataShown(SettingsManager settings) =>
    photoMetadataShown(settings, 'immich');

/// The corner the single-photo metadata panel settles in. See
/// [photoMetadataCorner].
String? immichMetadataCorner(SettingsManager settings) =>
    photoMetadataCorner(settings, 'immich');

/// An aspect ratio (width over height) counts as portrait below this. Not
/// 1.0: a square photo pairs badly, reading as two small pictures rather
/// than one full screen.
const _portraitAspect = 0.95;

/// A screen this wide (or wider) has room for two portrait photos. Narrower
/// panels would halve into slivers, which is worse than the empty sides the
/// pairing exists to avoid.
const _pairableScreenAspect = 1.2;

/// The mirror image for a portrait panel: a photo counts as landscape
/// above this (the square band excluded for the same reason), and a screen
/// this tall (or taller) has room for two landscape photos one above the
/// other (issue #644).
const _landscapeAspect = 1 / _portraitAspect;
const _stackableScreenAspect = 1 / _pairableScreenAspect;

/// Whether a photo of this shape (width over height, null when the decoder
/// could not say) is portrait. An unmeasurable photo never pairs.
bool immichPortraitPhoto(double? aspect) =>
    aspect != null && aspect < _portraitAspect;

/// Whether a photo of this shape is landscape, square excluded.
bool immichLandscapePhoto(double? aspect) =>
    aspect != null && aspect > _landscapeAspect;

/// Whether a panel of this shape has room for a pair.
bool immichPairableScreen(double screenAspect) =>
    screenAspect >= _pairableScreenAspect;

/// Whether a panel of this shape has room for two landscape photos stacked.
bool immichStackableScreen(double screenAspect) =>
    screenAspect > 0 && screenAspect <= _stackableScreenAspect;

/// How two photos share a screen: side by side (two portrait photos on a
/// landscape panel) or one above the other (two landscape photos on a
/// portrait panel).
enum ImmichPairing { sideBySide, stacked }

/// The pairing a panel of this shape gets, with "Pair portrait photos" and
/// "Pair landscape photos" as given, or null when neither applies: the
/// panel decides which of the two can fill it, and a squarish one takes
/// neither, since two halves of it would be slivers either way.
ImmichPairing? immichPairingFor(
  double screenAspect, {
  required bool portrait,
  required bool landscape,
}) {
  if (portrait && immichPairableScreen(screenAspect)) {
    return ImmichPairing.sideBySide;
  }
  if (landscape && immichStackableScreen(screenAspect)) {
    return ImmichPairing.stacked;
  }
  return null;
}

/// Whether a photo of this shape takes part in [pairing].
bool immichPairPhoto(ImmichPairing pairing, double? aspect) =>
    switch (pairing) {
      ImmichPairing.sideBySide => immichPortraitPhoto(aspect),
      ImmichPairing.stacked => immichLandscapePhoto(aspect),
    };

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

/// Whether two consecutive photos should share the screen one above the
/// other: both landscape, on a portrait panel.
bool immichPairsLandscape({
  required double screenAspect,
  required double? first,
  required double? second,
}) =>
    immichStackableScreen(screenAspect) &&
    immichLandscapePhoto(first) &&
    immichLandscapePhoto(second);

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

/// [assets] reordered so every photo that pairs on this panel is followed
/// by the photo that will share the screen with it: portrait photos on a
/// landscape panel, landscape photos on a portrait one when [landscape]
/// asks for it.
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
  bool portrait = true,
  bool landscape = false,
}) {
  final pairing = immichPairingFor(
    screenAspect,
    portrait: portrait,
    landscape: landscape,
  );
  if (pairing == null) return assets;
  bool pairs(ImmichAsset a) => !a.isVideo && immichPairPhoto(pairing, a.aspect);
  final remaining = [...assets];
  final out = <ImmichAsset>[];
  while (remaining.isNotEmpty) {
    final asset = remaining.removeAt(0);
    out.add(asset);
    if (!pairs(asset)) continue;
    // The next pairable photo anywhere ahead, pulled back to sit beside
    // this one. None left means this photo shows on its own, which is the
    // honest answer at the tail of the playlist.
    final partner = remaining.indexWhere(pairs);
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

  /// Wall clock for the playlist's age and the warm-up lead.
  DateTime Function() clock = DateTime.now;

  /// The playlist as the server last answered it, kept between sessions so
  /// a start does not wait on the listing: on a large library that is
  /// seconds of paged searches behind a black screen. Ids only, and capped
  /// by [_maxPlaylist]. An empty answer is never kept, so an album that
  /// gets its first photos is seen on the next start.
  List<ImmichAsset>? _playlist;
  DateTime? _playlistAt;
  Future<List<ImmichAsset>>? _playlistRefresh;

  /// How old the kept playlist may get before a start refreshes it in the
  /// background for the one after: the session in hand still starts on the
  /// kept list. New uploads show within this plus one session.
  static const playlistTtl = Duration(minutes: 10);

  /// The next session, readied ahead of the idle clock (issue #659): the
  /// order it will run in and the bytes of its first photo, so the start
  /// pays only the decode. One photo, a preview of a few hundred KB, which
  /// a 1 GB device can afford to hold between sessions.
  List<ImmichAsset>? _warmOrder;
  (String, Uint8List)? _warmImage;
  Future<void>? _warming;
  Timer? _warmTimer;

  /// How long before the idle clock fires the warm-up starts. Long enough
  /// for a listing and a preview fetch on a slow link; a shorter idle
  /// timeout warms as soon as the clock arms.
  @visibleForTesting
  Duration warmLead = const Duration(seconds: 15);

  /// The order sessions walk the playlist in, and the entries that had
  /// their turn in this lap of it (issue #699). Every session used to
  /// shuffle the whole playlist again and start at the top, so a frame that
  /// goes in and out of the screensaver all day drew from the pool with
  /// replacement and brought photos back long before the rest had shown.
  /// A start now leads with the entries this lap has not reached, and the
  /// next lap, shuffled again, begins once every entry had its turn.
  List<ImmichAsset>? _deck;
  List<ImmichAsset>? _deckSource;
  Set<String> _deckIds = const {};
  final _shown = <String>{};
  final _random = Random();

  /// The settings whose change makes the kept playlist and the warm start
  /// wrong. The rest (transition, fill, metadata, cache size) leave the
  /// listing and its order alone.
  static final _playlistKeys = {
    defs.screensaverImmichUrl.key,
    defs.screensaverImmichApiKey.key,
    defs.screensaverImmichValidated.key,
    defs.screensaverImmichAlbum.key,
    defs.screensaverImmichAlbumName.key,
    defs.screensaverImmichPhotosOnly.key,
    defs.screensaverImmichShuffle.key,
    defs.screensaverImmichPairPortrait.key,
    defs.screensaverImmichPairLandscape.key,
    defs.screensaverImmichPeople.key,
    defs.screensaverImmichExcludePeople.key,
    defs.screensaverImmichTags.key,
    defs.screensaverImmichExcludeTags.key,
    defs.screensaverImmichFavoritesOnly.key,
    defs.screensaverImmichTakenWithin.key,
    defs.screensaverImmichTakenFrom.key,
    defs.screensaverImmichTakenTo.key,
  };

  @override
  Future<void> init() async {
    bus.on<ScreensaverCountdownChanged>().listen(_onCountdown);
    bus.on<SettingChanged>().listen((e) {
      if (_playlistKeys.contains(e.key)) {
        _forgetPlaylist();
        _forgetDeck();
      }
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
      // Turning the cache off deletes what it kept, so the space comes
      // back without a separate clear step (issue #895).
      if (e.key == defs.screensaverImmichCache.key &&
          !_settings.get(defs.screensaverImmichCache)) {
        unawaited(_clearCache());
      }
      // A one-album pick from an older install or backup arrives as a bare
      // id with its name in a setting of its own, in either order.
      if (e.key == defs.screensaverImmichAlbum.key ||
          e.key == defs.screensaverImmichAlbumName.key) {
        unawaited(_migrateAlbums());
      }
    });
    await _migrateAlbums();
    // Copies left from before the cache was turned off, on an install
    // that predates deleting them with the toggle.
    if (!_settings.get(defs.screensaverImmichCache)) {
      unawaited(_clearCache());
    }

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
        name: 'immichPeople',
        description:
            'The named people Immich recognizes, alphabetical: '
            '[{id, name, hidden}]. Unnamed face clusters are left out, since '
            'the filters pick by name. People hidden in Immich come along '
            'with hidden: true, since the filters still work on them.',
        handler: (_) async {
          try {
            return CommandResult.ok(await _people());
          } catch (e) {
            return CommandResult.fail(readableError(e));
          }
        },
      ),
    );

    commands.register(
      Command(
        name: 'immichTags',
        description:
            'The Immich tags, alphabetical by full path: [{id, name}].',
        handler: (_) async {
          try {
            return CommandResult.ok(await _tags());
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
          await _clearCache();
          return const CommandResult.ok();
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _warmTimer?.cancel();
    _warmTimer = null;
  }

  void _forgetPlaylist() {
    _playlist = null;
    _playlistAt = null;
    _warmOrder = null;
    _warmImage = null;
  }

  /// A different pool or order: the lap starts over on the next listing.
  /// A fresh listing of the same settings keeps it, so a retry after an
  /// outage does not bring back what already showed.
  void _forgetDeck() {
    _deck = null;
    _deckSource = null;
    _deckIds = const {};
    _shown.clear();
  }

  /// The idle clock moved. With the Immich slideshow due, get the next
  /// session ready [warmLead] ahead of it; a clock that is closer than that
  /// or already past warms right away. Any other mode due drops what was
  /// readied, so a device switched to the clock does not keep a photo in
  /// memory for nothing.
  void _onCountdown(ScreensaverCountdownChanged e) {
    _warmTimer?.cancel();
    _warmTimer = null;
    final due = e.due;
    if (due == null) return;
    if (e.mode != 'immich') {
      _warmOrder = null;
      _warmImage = null;
      return;
    }
    final wait = due.difference(clock()) - warmLead;
    if (wait <= Duration.zero) {
      unawaited(warmUp());
    } else {
      _warmTimer = Timer(wait, () {
        _warmTimer = null;
        unawaited(warmUp());
      });
    }
  }

  /// Ready the next session: the playlist (listed if not kept), its start
  /// order and the first photo's bytes. Idempotent while a readied start is
  /// waiting. Never throws: a warm-up that fails leaves the start to the
  /// slideshow's own path, which reports the failure.
  Future<void> warmUp() {
    if (!configured || !_settings.get(defs.screensaverImmichValidated)) {
      return Future.value();
    }
    return _warming ??= _warm().whenComplete(() => _warming = null);
  }

  Future<void> _warm() async {
    try {
      final order = _warmOrder ?? await _startOrder();
      if (order.isEmpty) return;
      _warmOrder = order;
      final first = order.first;
      if (first.isVideo || _warmImage?.$1 == first.id) return;
      final bytes = await imageBytes(first);
      // The settings may have moved while the fetch ran; a start readied
      // for the old ones was dropped, and this photo goes with it.
      if (!identical(_warmOrder, order)) return;
      _warmImage = (first.id, bytes);
      log.debug(
        name,
        'warm-up ready: ${order.length} assets, first ${first.id}',
      );
    } catch (e) {
      log.debug(name, 'warm-up skipped: $e');
    }
  }

  /// The playlist in the order the next session runs it: the readied start
  /// when one is waiting, else the kept playlist (listed when there is
  /// none), shuffled when the setting says so, with the entries this lap
  /// has not shown yet first. The readied start is consumed: the session
  /// after this one gets its own. [fresh] drops the kept playlist and the
  /// readied start first and lists again.
  Future<List<ImmichAsset>> startOrder({bool fresh = false}) {
    if (fresh) _forgetPlaylist();
    final warm = _warmOrder;
    _warmOrder = null;
    if (warm != null) return Future.value(warm);
    return _startOrder();
  }

  Future<List<ImmichAsset>> _startOrder() async {
    final deck = _dealt(await playlist());
    return [
      for (final a in deck)
        if (!_shown.contains(a.id)) a,
      for (final a in deck)
        if (_shown.contains(a.id)) a,
    ];
  }

  /// The deck for [assets], kept while the listing is the same one. A new
  /// listing keeps the lap's order and progress: entries the server no
  /// longer lists leave, and new uploads land at random places in it when
  /// shuffling, so they do not wait for the end of the lap.
  List<ImmichAsset> _dealt(List<ImmichAsset> assets) {
    final deck = _deck;
    if (deck != null && identical(_deckSource, assets)) return deck;
    final shuffle = _settings.get(defs.screensaverImmichShuffle);
    final List<ImmichAsset> next;
    if (!shuffle) {
      next = assets;
    } else if (deck == null) {
      next = [...assets]..shuffle(_random);
    } else {
      final listed = {for (final a in assets) a.id: a};
      next = [for (final a in deck) ?listed[a.id]];
      for (final a in assets) {
        if (_deckIds.contains(a.id)) continue;
        next.insert(_random.nextInt(next.length + 1), a);
      }
    }
    _deck = next;
    _deckSource = assets;
    _deckIds = {for (final a in next) a.id};
    _shown.retainAll(_deckIds);
    return next;
  }

  /// [asset] had its turn in this lap: shown, or passed over because it
  /// could not be. Once every entry had one the next lap starts, shuffled
  /// again when the setting says so.
  void markShown(ImmichAsset asset) {
    final deck = _deck;
    if (deck == null || !_deckIds.contains(asset.id)) return;
    if (!_shown.add(asset.id)) return;
    // A start readied before this showed would lead with it again.
    if (_warmOrder != null) {
      _warmOrder = null;
      _warmImage = null;
    }
    if (_shown.length < _deckIds.length) return;
    _shown.clear();
    if (_settings.get(defs.screensaverImmichShuffle)) {
      _deck = [...deck]..shuffle(_random);
    }
  }

  /// The kept playlist, listed from the server when there is none. A kept
  /// list older than [playlistTtl] is answered as it is and refreshed in
  /// the background for the next start.
  Future<List<ImmichAsset>> playlist() {
    final kept = _playlist;
    final at = _playlistAt;
    if (kept != null && at != null) {
      if (clock().difference(at) > playlistTtl) {
        unawaited(_refreshPlaylist().catchError((_) => const <ImmichAsset>[]));
      }
      return Future.value(kept);
    }
    return _refreshPlaylist();
  }

  Future<List<ImmichAsset>> _refreshPlaylist() =>
      _playlistRefresh ??= () async {
        try {
          final assets = await listAssets();
          if (assets.isNotEmpty) {
            _playlist = List.unmodifiable(assets);
            _playlistAt = clock();
          }
          return assets;
        } finally {
          _playlistRefresh = null;
        }
      }();

  /// The chosen albums, none meaning the whole library.
  List<ImmichNamed> get _albumPicks =>
      decodeImmichNamed(_settings.get(defs.screensaverImmichAlbum));

  /// Fold the shape older installs stored, one bare album id plus its name
  /// in immich_album_name, into the [{id, name}] list. The write runs the
  /// normalizer, which makes the list; the name is filled here, since only
  /// this side knows the setting it shipped in.
  Future<void> _migrateAlbums() async {
    final raw = _settings.get(defs.screensaverImmichAlbum);
    if (raw.trim().isNotEmpty && !raw.trim().startsWith('[')) {
      await _settings.set(defs.screensaverImmichAlbum, raw);
      return; // the change comes back through the listener for the name
    }
    final picks = _albumPicks;
    final legacyName = _settings.get(defs.screensaverImmichAlbumName);
    if (picks.length == 1 &&
        picks.single.name.isEmpty &&
        legacyName.isNotEmpty) {
      await _settings.set(
        defs.screensaverImmichAlbum,
        jsonEncode([ImmichNamed(id: picks.single.id, name: legacyName)]),
      );
    }
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
      final picks = await _dropMissingAlbums(await _albums());
      final found = await _search(
        page: 1,
        size: _probeAssets,
        albumId: picks.firstOrNull?.id,
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

  /// The album picks the server still lists, with the rest removed from
  /// the setting. The search answers 400 for an album id the server does
  /// not know (issue #514), and a server rebuilt from scratch knows none
  /// of the old ids, so probing with a stale pick failed the Validate
  /// button forever, and the button is what unlocks the row where the
  /// pick could have been changed.
  Future<List<ImmichNamed>> _dropMissingAlbums(
    List<Map<String, Object?>> albums,
  ) async {
    final known = {for (final album in albums) '${album['id']}'};
    final picks = _albumPicks;
    final kept = [
      for (final pick in picks)
        if (known.contains(pick.id)) pick,
    ];
    if (kept.length == picks.length) return picks;
    final gone = [
      for (final pick in picks)
        if (!known.contains(pick.id)) pick.name.isEmpty ? pick.id : pick.name,
    ];
    log.warn(
      name,
      'validate: dropped albums the server no longer lists: '
      '${gone.join(', ')}',
    );
    await _settings.set(
      defs.screensaverImmichAlbum,
      jsonEncode([for (final pick in kept) pick.toJson()]),
    );
    return kept;
  }

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

  /// Every named person, alphabetical. Immich pages this endpoint on newer
  /// servers and answers the lot on older ones; both shapes are read.
  /// Unnamed clusters are skipped: a filter picked by name has nothing to
  /// show for them, and skipping them keeps the hidden ones (mostly
  /// background faces) out of the picker.
  ///
  /// People hidden in Immich come along, marked `hidden` so the pickers can
  /// say so (issue #382). Hiding a person only takes them out of Immich's
  /// own listings: their faces stay on the assets, so both filters keep
  /// working on them, and a person hidden after being picked no longer
  /// vanishes from the filter the next time the row is saved.
  Future<List<Map<String, Object?>>> _people() async {
    final people = <Map<String, Object?>>[];
    for (var page = 1; page <= _maxPeoplePages; page++) {
      final response = await http
          .get(
            Uri.parse('$_base/api/people?withHidden=true&page=$page&size=1000'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      _throwUnlessOk(response, scope: 'person.read');
      final decoded = jsonDecode(response.body);
      final list = decoded is Map ? decoded['people'] : decoded;
      for (final person in (list as List? ?? const []).cast<Map>()) {
        final name = '${person['name'] ?? ''}'.trim();
        if (name.isEmpty) continue;
        people.add({
          'id': person['id'],
          'name': name,
          if (person['isHidden'] == true) 'hidden': true,
        });
      }
      if (decoded is! Map || decoded['hasNextPage'] != true) break;
    }
    people.sort(
      (a, b) =>
          '${a['name']}'.toLowerCase().compareTo('${b['name']}'.toLowerCase()),
    );
    return people;
  }

  /// The people listing stops after this many pages of a thousand; a
  /// library naming more people than that is not a photo frame's problem.
  static const _maxPeoplePages = 20;

  /// Every tag, alphabetical by full path ("Family/Kids"), which is what
  /// Immich shows in its own tag picker and what tells two "Kids" apart.
  Future<List<Map<String, Object?>>> _tags() async {
    final response = await http
        .get(Uri.parse('$_base/api/tags'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _throwUnlessOk(response, scope: 'tag.read');
    final tags = [
      for (final tag in (jsonDecode(response.body) as List).cast<Map>())
        {'id': tag['id'], 'name': '${tag['value'] ?? tag['name'] ?? ''}'},
    ];
    tags.sort(
      (a, b) =>
          '${a['name']}'.toLowerCase().compareTo('${b['name']}'.toLowerCase()),
    );
    return tags;
  }

  /// One page of the metadata search. The filters are the search's own
  /// fields, sent one person and one tag at a time: Immich reads a list of
  /// several as "all of them in the same photo", and a frame set to show
  /// the kids wants either of them. [withPeople] asks for each asset's
  /// people, which the exclusion filter reads.
  ///
  /// Archived media never shows (issue #681): Immich keeps it out of the
  /// timeline, and a frame should respect that. `visibility` is how
  /// Immich asks for it today and `isArchived` is how older servers did.
  /// Each generation drops the field it does not know, so both go along.
  Future<Map<String, dynamic>> _search({
    required int page,
    required int size,
    String? albumId,
    bool withExif = false,
    String? personId,
    String? tagId,
    bool favorite = false,
    DateTime? takenAfter,
    DateTime? takenBefore,
    bool withPeople = false,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_base/api/search/metadata'),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'page': page,
            'size': size,
            'withExif': withExif,
            'visibility': 'timeline',
            'isArchived': false,
            if (withPeople) 'withPeople': true,
            if (albumId != null && albumId.isNotEmpty) 'albumIds': [albumId],
            if (personId != null) 'personIds': [personId],
            if (tagId != null) 'tagIds': [tagId],
            if (favorite) 'isFavorite': true,
            if (takenAfter != null) 'takenAfter': takenAfter.toIso8601String(),
            if (takenBefore != null)
              'takenBefore': takenBefore.toIso8601String(),
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

  /// The playlist: every image and video of the configured source that
  /// passes the filters, in the server's order (newest first). The view
  /// shuffles if asked to.
  ///
  /// "Photos only" drops the videos here, at the source: motion/live photos
  /// often land in Immich as short video assets, and a two-second clip
  /// between stills makes the whole slideshow feel broken (issue #32).
  ///
  /// Several albums, people or tags mean "any of these", so the search runs
  /// once per album, person and tag combination and the answers are merged
  /// by id, then put back in newest-first order since each run was sorted
  /// on its own. Excluded people cannot be asked of the server on this API,
  /// so every asset comes back with its people and the ones carrying an
  /// excluded person are dropped here (issue #345). Excluded tags cannot be
  /// asked of it either, and an asset's tags do not come back with a
  /// search, so the assets carrying each excluded tag are listed first and
  /// dropped by id (issue #645). Exclusion wins over every other filter.
  Future<List<ImmichAsset>> listAssets() async {
    final albums = _albumPicks;
    final photosOnly = _settings.get(defs.screensaverImmichPhotosOnly);
    // The EXIF comes along only when something wants it: pairing photos
    // needs every photo's shape up front to arrange the playlist, and it
    // is the one feature that does.
    final withExif =
        _settings.get(defs.screensaverImmichPairPortrait) ||
        _settings.get(defs.screensaverImmichPairLandscape);
    final people = decodeImmichNamed(
      _settings.get(defs.screensaverImmichPeople),
    );
    final excluded = {
      for (final p in decodeImmichNamed(
        _settings.get(defs.screensaverImmichExcludePeople),
      ))
        p.id,
    };
    final tags = decodeImmichNamed(_settings.get(defs.screensaverImmichTags));
    final excludedTags = decodeImmichNamed(
      _settings.get(defs.screensaverImmichExcludeTags),
    );
    final favorite = _settings.get(defs.screensaverImmichFavoritesOnly);
    final takenAfter = immichTakenAfter(_settings);
    final takenBefore = immichTakenBefore(_settings);
    final hiddenByTag = await _assetsTagged(
      excludedTags,
      favorite: favorite,
      takenAfter: takenAfter,
      takenBefore: takenBefore,
    );
    final albumIds = albums.isEmpty
        ? <String?>[null]
        : <String?>[for (final a in albums) a.id];
    final personIds = people.isEmpty
        ? <String?>[null]
        : <String?>[for (final p in people) p.id];
    final tagIds = tags.isEmpty
        ? <String?>[null]
        : <String?>[for (final t in tags) t.id];

    final assets = <ImmichAsset>[];
    final created = <String, String>{};
    for (final albumId in albumIds) {
      for (final personId in personIds) {
        for (final tagId in tagIds) {
          var page = 1;
          while (assets.length < _maxPlaylist) {
            final result = await _search(
              page: page,
              size: 500,
              albumId: albumId,
              withExif: withExif,
              personId: personId,
              tagId: tagId,
              favorite: favorite,
              takenAfter: takenAfter,
              takenBefore: takenBefore,
              withPeople: excluded.isNotEmpty,
            );
            for (final item in (result['items'] as List).cast<Map>()) {
              final id = item['id'] as String;
              if (created.containsKey(id)) continue;
              if (hiddenByTag.contains(id)) continue;
              if (_isArchived(item)) continue;
              final isVideo = item['type'] == 'VIDEO';
              if (photosOnly && isVideo) continue;
              if (excluded.isNotEmpty &&
                  _carriesAnyOf(item['people'], excluded)) {
                continue;
              }
              created[id] = '${item['fileCreatedAt'] ?? ''}';
              assets.add(
                ImmichAsset(
                  id: id,
                  isVideo: isVideo,
                  aspect: isVideo ? null : exifAspect(item['exifInfo']),
                  durationSeconds: isVideo
                      ? immichDurationSeconds(item['duration'])
                      : null,
                ),
              );
            }
            final next = result['nextPage'];
            if (next == null) break;
            page = next is num
                ? next.toInt()
                : int.tryParse('$next') ?? page + 1;
          }
        }
      }
    }
    if (albumIds.length * personIds.length * tagIds.length > 1) {
      // ISO 8601 timestamps sort as strings; the server's own order is
      // newest first, and the merge should read the same way.
      assets.sort((a, b) => created[b.id]!.compareTo(created[a.id]!));
    }
    return assets;
  }

  /// The ids of every asset carrying any of [tags]: one search per tag,
  /// which Immich answers for the tag and its children alike, so excluding
  /// a parent tag covers the whole branch. The searches take the same
  /// favorite and date window as the playlist's own, since an asset outside
  /// it is never shown anyway. The album, people and tag picks are OR-ed
  /// combinations that cannot narrow a single search, and exclusion has to
  /// win over all of them regardless.
  Future<Set<String>> _assetsTagged(
    List<ImmichNamed> tags, {
    required bool favorite,
    DateTime? takenAfter,
    DateTime? takenBefore,
  }) async {
    final ids = <String>{};
    for (final tag in tags) {
      var page = 1;
      for (var pages = 0; pages < _maxExcludedPages; pages++) {
        final result = await _search(
          page: page,
          size: 500,
          tagId: tag.id,
          favorite: favorite,
          takenAfter: takenAfter,
          takenBefore: takenBefore,
        );
        for (final item in (result['items'] as List).cast<Map>()) {
          ids.add(item['id'] as String);
        }
        final next = result['nextPage'];
        if (next == null) break;
        page = next is num ? next.toInt() : int.tryParse('$next') ?? page + 1;
        if (pages == _maxExcludedPages - 1) {
          log.warn(
            name,
            'excluded tag "${tag.name}" has more assets than the '
            '${_maxExcludedPages * 500} the exclusion reads, so the rest '
            'may still show',
          );
        }
      }
    }
    return ids;
  }

  /// Pages of five hundred an excluded tag's listing stops after. That is
  /// the playlist's own ceiling, and a tag meant to hide a few unsuitable
  /// photos never comes close.
  static const _maxExcludedPages = 20;

  /// Whether a search answer marks the asset as archived, in either
  /// generation's field, for a server that ignored the search's own ask.
  static bool _isArchived(Map item) =>
      item['visibility'] == 'archive' || item['isArchived'] == true;

  /// Whether an asset's `people` list (present with `withPeople`) names
  /// anyone in [ids].
  static bool _carriesAnyOf(Object? people, Set<String> ids) {
    if (people is! List) return false;
    for (final person in people) {
      if (person is Map && ids.contains('${person['id']}')) return true;
    }
    return false;
  }

  /// The streaming URL and headers for a video asset — playback goes
  /// straight to the player, disk never involved.
  Uri videoUri(ImmichAsset asset) =>
      Uri.parse('$_base/api/assets/${asset.id}/video/playback');

  /// The Java heap ceiling to judge videos against; a test sets it.
  @visibleForTesting
  int? javaHeapMaxOverride;
  Future<int?>? _javaHeapMax;

  final _videoFits = <String, bool>{};

  /// Whether this device can afford to play [asset]. The video player
  /// buffers up to fifty seconds of the stream into Java byte arrays, and
  /// on an Echo Show the whole Java heap is 80 MB: one long phone video
  /// ran the heap into the wall and killed the app, for every Immich user
  /// who ever hit one (the crash landed on whatever thread allocated
  /// next, the microphone reader most often). A HEAD on the playback
  /// stream gives its exact size, the listing gave its length, and a
  /// video whose first fifty seconds would not fit the budget is skipped
  /// rather than played. Answered once per video per session; a server
  /// that states no size, or a platform with no heap figure, gets the
  /// benefit of the doubt.
  Future<int?> _videoBytes(ImmichAsset asset) async {
    try {
      return await _videoBytesOf(videoUri(asset), _headers);
    } catch (e) {
      log.warn(name, 'video size unknown for ${asset.id}: $e');
      return null;
    }
  }

  Future<bool> videoFits(ImmichAsset asset) async {
    final known = _videoFits[asset.id];
    if (known != null) return known;
    final heapMax =
        javaHeapMaxOverride ??
        await (_javaHeapMax ??= DeviceDetails.javaHeapMax());
    if (heapMax == null || heapMax <= 0) return true;
    final bytes = await _videoBytes(asset);
    if (bytes == null) return true;
    final fits = immichVideoFits(
      bytes: bytes,
      durationSeconds: asset.durationSeconds,
      heapMax: heapMax,
    );
    _videoFits[asset.id] = fits;
    final mb =
        (immichVideoBufferBytes(bytes, asset.durationSeconds) / (1024 * 1024))
            .round();
    final budgetMb = (immichVideoBudget(heapMax) / (1024 * 1024)).round();
    log.info(
      name,
      fits
          ? 'video ${asset.id}: ~$mb MB buffered of a $budgetMb MB budget'
          : 'video ${asset.id} skipped: ~$mb MB of buffering would not fit '
                'the $budgetMb MB budget this device\'s Java heap allows',
    );
    return fits;
  }

  Map<String, String> get videoHeaders => _headers;

  Uri _imageUri(ImmichAsset asset) =>
      Uri.parse('$_base/api/assets/${asset.id}/thumbnail?size=preview');

  /// An image, from the cache when enabled and present, from the server
  /// otherwise. Returns the bytes either way; disk is an implementation
  /// detail of the cache, not the contract.
  final _imageRequests = <(String, String, String), Future<Uint8List>>{};

  Future<Uint8List> imageBytes(ImmichAsset asset) {
    final warm = _warmImage;
    if (warm != null && warm.$1 == asset.id) {
      _warmImage = null;
      return Future.value(warm.$2);
    }
    final key = (_base, _settings.get(defs.screensaverImmichApiKey), asset.id);
    return _imageRequests.putIfAbsent(key, () async {
      try {
        return await _readImage(asset, _imageUri(asset), _headers);
      } finally {
        _imageRequests.remove(key);
      }
    });
  }

  Future<Uint8List> _readImage(
    ImmichAsset asset,
    Uri uri,
    Map<String, String> headers,
  ) async {
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
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 30));
    _throwUnlessOk(response, scope: 'asset.view');
    final bytes = response.bodyBytes;
    // Checked again: the cache may have been turned off and cleared while
    // this download ran.
    if (cached != null && _settings.get(defs.screensaverImmichCache)) {
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
  int _detailsGeneration = 0;
  Object? _detailsScope;
  final _detailRequests = <(int, String), Future<Map<String, String>>>{};

  Future<Map<String, String>> assetDetails(ImmichAsset asset) {
    // Read settings here too: their event can arrive after a caller requests
    // details for the newly selected connection or metadata configuration.
    final scope = (
      _base,
      _settings.get(defs.screensaverImmichApiKey),
      _settings.get(defs.screensaverImmichMetadata),
      _settings.get(defs.screensaverImmichMetadataAlbum),
      _settings.get(defs.screensaverImmichAlbum),
      _settings.get(defs.screensaverImmichAlbumName),
    );
    if (scope != _detailsScope) {
      _detailsScope = scope;
      _detailsGeneration++;
      _details.clear();
    }
    final generation = _detailsGeneration;
    final key = (generation, asset.id);
    return _detailRequests.putIfAbsent(key, () async {
      try {
        return await _readDetails(asset, generation);
      } finally {
        _detailRequests.remove(key);
      }
    });
  }

  Future<Map<String, String>> _readDetails(
    ImmichAsset asset,
    int generation,
  ) async {
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

      final camera = photoCameraLine(
        '${exif['make'] ?? ''}',
        '${exif['model'] ?? ''}',
      );
      if (camera != null) out['camera'] = camera;
      final shot = photoExposureLine(
        focalLength: exif['focalLength'] is num
            ? exif['focalLength'] as num
            : null,
        fNumber: exif['fNumber'] is num ? exif['fNumber'] as num : null,
        iso: exif['iso'] is num ? exif['iso'] as num : null,
      );
      if (shot != null) out['settings'] = shot;

      final location = <String>[
        for (final key in ['city', 'state', 'country'])
          if ('${exif[key] ?? ''}'.trim().isNotEmpty) '${exif[key]}'.trim(),
      ];
      if (location.isNotEmpty) out['location'] = location.join(', ');

      // The caption (issue #1290) rides in the same response, so turning
      // it on costs no request of its own.
      final description = '${exif['description'] ?? ''}'.trim();
      if (description.isNotEmpty) out['description'] = description;

      // The album line: the one configured album when exactly one is
      // picked, else the album the asset belongs to, its own request, with
      // a picked album preferred over any other it is also in. Turned off,
      // the line costs nothing at all: the extra request is never made.
      if (immichMetadataFieldOn(_settings, 'album')) {
        final picks = _albumPicks;
        if (picks.length == 1 && picks.single.name.isNotEmpty) {
          out['album'] = picks.single.name;
        } else {
          final albums = await http
              .get(
                Uri.parse('$_base/api/albums?assetId=${asset.id}'),
                headers: _headers,
              )
              .timeout(const Duration(seconds: 10));
          if (albums.statusCode == 200) {
            final list = (jsonDecode(albums.body) as List).cast<Map>();
            final picked = {for (final p in picks) p.id};
            final album = list.firstWhere(
              (a) => picked.contains('${a['id']}'),
              orElse: () => list.isEmpty ? const {} : list.first,
            );
            if (album.isNotEmpty) {
              out['album'] = '${album['albumName'] ?? ''}';
            }
          }
        }
      }
    } catch (e) {
      log.debug(name, 'asset details failed (${asset.id}): $e');
      return out; // uncached, so a transient failure retries next loop
    }
    if (_details.length > 300) _details.clear();
    if (generation == _detailsGeneration) _details[asset.id] = out;
    return out;
  }

  // Localized via the device locale (issue #108): "August 2, 2026" on an
  // American device, "2 augustus 2026" on a Dutch one.
  static String _formatDate(DateTime date) => longDate(date);

  Directory? _cacheDirMemo;

  Future<Directory> _cacheDir() async {
    if (_cacheDirMemo != null) return _cacheDirMemo!;
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/immich_cache');
    await dir.create(recursive: true);
    return _cacheDirMemo = dir;
  }

  /// Delete every cached item. The memo goes too, so the next write
  /// creates the folder again instead of failing on the deleted one.
  Future<void> _clearCache() async {
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory('${support.path}/immich_cache');
      _cacheDirMemo = null;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        log.info(name, 'local cache cleared');
      }
    } catch (e) {
      log.warn(name, 'cache clear failed: $e');
    }
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

/// The stream's total size in bytes. Asked with a one byte range: the
/// 206 answer's Content-Range carries the total and costs one byte,
/// where a HEAD comes back through the Dart HTTP client with its length
/// zeroed. A server that ignores the range answers 200 with the length
/// in Content-Length, and the body is dropped unread either way. Null
/// when the server did not say.
Future<int?> _videoBytesOf(Uri uri, Map<String, String> headers) async {
  final client = http.Client();
  try {
    final request = http.Request('GET', uri)
      ..headers.addAll(headers)
      ..headers['range'] = 'bytes=0-0';
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 10));
    final total = immichContentRangeTotal(response.headers['content-range']);
    if (total != null) return total;
    if (response.statusCode == 200) {
      final length = int.tryParse(response.headers['content-length'] ?? '');
      if (length != null && length > 0) return length;
    }
    return null;
  } finally {
    client.close();
  }
}

/// The total behind a Content-Range header ("bytes 0-0/7567107"), or null
/// when absent, unknown ("*") or not a positive number.
int? immichContentRangeTotal(String? header) {
  if (header == null) return null;
  final slash = header.lastIndexOf('/');
  if (slash < 0) return null;
  final total = int.tryParse(header.substring(slash + 1).trim());
  return total != null && total > 0 ? total : null;
}

/// The window the video player buffers ahead: ExoPlayer's default of fifty
/// seconds, which it fills as fast as the network delivers.
const immichVideoBufferWindowSeconds = 50;

/// The share of the Java heap a video's buffering may take. The rest is
/// the app's own Java side, and the headroom the crash reports showed it
/// needs.
const immichVideoHeapShare = 0.4;

/// A video's length in seconds from Immich's listing: a count of
/// milliseconds from Immich 3, hours:minutes:seconds.fraction from the
/// releases before it; null when absent or unreadable.
double? immichDurationSeconds(Object? raw) {
  if (raw is num) return raw > 0 ? raw / 1000 : null;
  if (raw is! String || raw.isEmpty) return null;
  final parts = raw.split(':');
  if (parts.length < 2 || parts.length > 3) return null;
  var seconds = 0.0;
  for (final part in parts) {
    final value = double.tryParse(part.trim());
    if (value == null) return null;
    seconds = seconds * 60 + value;
  }
  return seconds > 0 ? seconds : null;
}

/// How many bytes of a [bytes]-long stream the player buffers at once: the
/// whole stream when it is shorter than the window, else the window's
/// share of it, assuming a steady bitrate. No length known means the
/// whole stream, the cautious reading.
double immichVideoBufferBytes(int bytes, double? durationSeconds) {
  if (durationSeconds == null ||
      durationSeconds <= immichVideoBufferWindowSeconds) {
    return bytes.toDouble();
  }
  return bytes * immichVideoBufferWindowSeconds / durationSeconds;
}

/// Heaps this small (an Echo Show's 80 MB) carry the whole app in the
/// other sixty percent already; with the camera, the Bluetooth proxy and
/// the wake word on, a forty percent video ran them into GC thrash and
/// finalizer timeouts. They get a quarter instead.
const immichSmallHeapBytes = 96 * 1024 * 1024;
const immichSmallHeapShare = 0.25;

double immichVideoBudget(int heapMax) =>
    heapMax *
    (heapMax <= immichSmallHeapBytes
        ? immichSmallHeapShare
        : immichVideoHeapShare);

/// Whether a video's buffering fits the heap budget.
bool immichVideoFits({
  required int bytes,
  required double? durationSeconds,
  required int heapMax,
}) =>
    immichVideoBufferBytes(bytes, durationSeconds) <=
    immichVideoBudget(heapMax);
