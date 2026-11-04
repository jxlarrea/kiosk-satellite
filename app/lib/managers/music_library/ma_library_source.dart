import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../sendspin/music_assistant_api.dart' show queueImageUrl;
import 'library_model.dart';

/// Music Assistant's library: recommendations, search across every
/// provider, the library lists, each provider's own tree and playback
/// into a player's queue.
class MaLibrarySource extends LibrarySource {
  MaLibrarySource({
    required this.call,
    required this.webBase,
    required this.ownQueueId,
    this.preferences = _noPreferences,
  });

  /// One Music Assistant command, answered `{ok, result}` or `{ok: false,
  /// error: {code, message}}`.
  final Future<Map<String, Object?>> Function(
    String command,
    Map<String, Object?> args,
  )
  call;

  /// Music Assistant's web address, which serves the image proxy.
  final String? Function() webBase;

  /// The queue of this device's own player, for a play with no speaker
  /// picked. Empty when Music Assistant does not know it.
  final Future<String> Function() ownQueueId;

  /// The preferences of the token's user, read once a call has signed in.
  /// Discover follows the layout Music Assistant's own page saved there.
  final Map<String, Object?> Function() preferences;

  static Map<String, Object?> _noPreferences() => const {};

  static const pageSize = 60;

  static const _lists = {
    'artists': LibraryKind.artist,
    'albums': LibraryKind.album,
    'tracks': LibraryKind.track,
    'playlists': LibraryKind.playlist,
    'radios': LibraryKind.radio,
    'podcasts': LibraryKind.podcast,
    'audiobooks': LibraryKind.audiobook,
  };

  @override
  String get key => 'ma';

  @override
  bool get hasDiscover => true;

  @override
  bool get hasSearch => true;

  @override
  bool get hasBrowse => true;

  @override
  bool get hasRadioMode => true;

  @override
  bool get hasFavorites => true;

  @override
  List<LibrarySort> get sorts => LibrarySort.values;

  @override
  bool get hasAlbumArtists => true;

  @override
  List<LibraryCategory> get categories => [
    for (final e in _lists.entries) LibraryCategory(e.key, e.value),
  ];

  /// This device's own player is a Music Assistant player too.
  @override
  bool needsSpeaker(String pick) => !(pick.isEmpty || pick.startsWith('ma:'));

  Future<Object?> _call(String command, [Map<String, Object?>? args]) async {
    final res = await call(command, args ?? const {});
    if (res['ok'] == true) return res['result'];
    final error = res['error'];
    final message = error is Map ? '${error['message'] ?? error['code']}' : '';
    throw LibraryError(
      message.isEmpty ? 'Music Assistant did not answer' : message,
    );
  }

  Future<List<Map>> _list(String command, [Map<String, Object?>? args]) async {
    final result = await _call(command, args);
    return result is List ? result.whereType<Map>().toList() : const [];
  }

  @override
  Future<List<LibraryShelf>> discover() async {
    final shelves = <LibraryShelf>[];
    // The server's own recommendations first, the rows its Discover page
    // shows in the order it shows them, the ones that have anything in
    // them. The listing names the rows and each row's items come on
    // their own, the way Music Assistant's page loads them.
    try {
      final rows = discoverRows(
        await _list('music/recommendations'),
        preferences(),
      );
      final filled = await Future.wait([
        for (final row in rows) row == genresRow ? _genres() : _rowItems(row),
      ]);
      for (final (i, row) in rows.indexed) {
        if (filled[i].isEmpty) continue;
        shelves.add(
          row == genresRow
              ? LibraryShelf(key: 'genres', items: filled[i])
              : LibraryShelf(title: '${row['name'] ?? ''}', items: filled[i]),
        );
      }
    } on LibraryError {
      // An older server without recommendations: the shelves below.
    }
    if (shelves.isNotEmpty) return shelves;
    // Built from the library when the server recommends nothing.
    Future<LibraryShelf> shelf(
      String key,
      String command,
      Map<String, Object?> args,
    ) async {
      try {
        return LibraryShelf(
          key: key,
          items: _items(await _call(command, args)),
        );
      } on LibraryError {
        return LibraryShelf(key: key, items: const []);
      }
    }

    final built = await Future.wait([
      shelf('recent', 'music/recently_played_items', {'limit': 20}),
      shelf('playlists', 'music/playlists/library_items', {
        'limit': 20,
        'order_by': 'last_played_desc',
      }),
      shelf('added', 'music/tracks/library_items', {
        'limit': 20,
        'order_by': 'timestamp_added_desc',
      }),
      shelf('radio', 'music/radios/library_items', {'limit': 20}),
    ]);
    return [
      for (final s in built)
        if (s.items.isNotEmpty) s,
    ];
  }

  /// A recommendation row's items. A server older than 2.10 sends them
  /// in the listing.
  Future<List<LibraryItem>> _rowItems(Map row) async {
    final inline = _items(row['items']);
    if (inline.isNotEmpty) return inline;
    try {
      return _items(
        await _call('music/recommendations/items', {
          'provider': '${row['provider'] ?? ''}',
          'item_id': '${row['item_id'] ?? ''}',
        }),
      );
    } on LibraryError {
      return const [];
    }
  }

  /// The eight genres Music Assistant's Discover page offers under Browse
  /// by genre: the ones with the most music in the library.
  Future<List<LibraryItem>> _genres() async {
    try {
      final all = await _list('music/genres/library_items', {
        'hide_empty': true,
        'limit': 500,
      });
      if (all.isEmpty) return const [];
      Map counts = const {};
      try {
        final answer = await _call('music/genres/media_counts', {
          'genre_ids': [for (final g in all) '${g['item_id']}'],
        });
        if (answer is Map) counts = answer;
      } on LibraryError {
        // Without counts the genres keep the server's order, by name.
      }
      num total(Map g) => switch (counts['${g['item_id']}']) {
        final Map c => c.values.whereType<num>().fold<num>(0, (a, b) => a + b),
        _ => 0,
      };
      // A stable sort, so equal counts stay in the server's order.
      final ranked = [for (final (i, g) in all.indexed) (i, g)]
        ..sort((a, b) {
          final byCount = total(b.$2).compareTo(total(a.$2));
          return byCount != 0 ? byCount : a.$1.compareTo(b.$1);
        });
      return _items([for (final (_, g) in ranked.take(8)) g]);
    } on LibraryError {
      return const [];
    }
  }

  /// Stands for Browse by genre among the recommendation rows: Music
  /// Assistant's page draws it itself and saves it as `genres`.
  @visibleForTesting
  static const genresRow = <String, Object?>{'uri': 'genres'};

  /// The recommendation rows Music Assistant's Discover page shows, in
  /// its order, resolved the way the page resolves them: In progress and
  /// Recently played first, the rest as the server lists them and Browse
  /// by genre last, then the user's saved `discover.rows` on top. A row
  /// the server marks off by default stays hidden until the user showed
  /// it.
  @visibleForTesting
  static List<Map> discoverRows(
    List<Map> folders,
    Map<String, Object?> preferences,
  ) {
    final byId = <String, Map>{
      for (final f in folders)
        if ('${f['uri'] ?? ''}' case final uri when uri.isNotEmpty) uri: f,
      'genres': genresRow,
    };
    final available = <String>[
      for (final id in const [
        'library://folder/in_progress',
        'library://folder/recently_played',
      ])
        if (byId.containsKey(id)) id,
    ];
    for (final id in byId.keys) {
      if (!available.contains(id)) available.add(id);
    }
    List<String> strings(Object? v) => [
      if (v is List)
        for (final x in v)
          if (x is String) x,
    ];
    var hidden = <String>[];
    var shown = <String>[];
    var order = <String>[];
    final saved = preferences['discover.rows'];
    if (saved is Map) {
      hidden = strings(saved['hidden']);
      shown = strings(saved['shown']);
      order = strings(saved['order']);
    } else if (preferences['discoverRowSettings'] case final Map legacy) {
      // Written by Music Assistant's older pages: a position and an
      // enabled flag for each row.
      final rows = [
        for (final e in legacy.entries)
          if (e.value case {'position': final num position})
            (id: '${e.key}', position: position, on: e.value['enabled']),
      ]..sort((a, b) => a.position.compareTo(b.position));
      order = [for (final r in rows) r.id];
      hidden = [
        for (final r in rows)
          if (r.on == false) r.id,
      ];
    }
    final hiddenSet = {
      ...hidden,
      for (final id in available)
        if (byId[id]!['enabled_by_default'] == false && !shown.contains(id)) id,
    };
    return [
      for (final id in _mergeOrder(order, available))
        if (!hiddenSet.contains(id)) byId[id]!,
    ];
  }

  /// The saved order with every row it does not name put right after the
  /// nearest row before it in [available], as Music Assistant merges it.
  static List<String> _mergeOrder(List<String> saved, List<String> available) {
    final have = available.toSet();
    final order = <String>[];
    for (final id in saved) {
      if (have.contains(id) && !order.contains(id)) order.add(id);
    }
    for (final (i, id) in available.indexed) {
      if (order.contains(id)) continue;
      var at = 0;
      for (var j = i - 1; j >= 0; j--) {
        final before = order.indexOf(available[j]);
        if (before >= 0) {
          at = before + 1;
          break;
        }
      }
      order.insert(at, id);
    }
    return order;
  }

  @override
  Future<List<LibraryShelf>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final result = await _call('music/search', {
      'search_query': q,
      'media_types': const [
        'artist',
        'album',
        'track',
        'playlist',
        'radio',
        'podcast',
        'audiobook',
      ],
      'limit': 20,
    });
    if (result is! Map) return const [];
    return [
      for (final key in const [
        'tracks',
        'artists',
        'albums',
        'playlists',
        'radio',
        'podcasts',
        'audiobooks',
      ])
        if (_items(result[key]) case final items when items.isNotEmpty)
          LibraryShelf(key: key, items: items),
    ];
  }

  @override
  Future<LibraryPage> list(
    LibraryCategory category, {
    int offset = 0,
    bool favorites = false,
    LibrarySort? sort,
    bool albumArtists = false,
  }) async {
    final rows = await _list('music/${category.key}/library_items', {
      'limit': pageSize,
      'offset': offset,
      // order_by, which sort_field and sort_direction replace from 2.11,
      // is what 2.10 knows. Both take it.
      'order_by': switch (sort) {
        LibrarySort.nameDesc => 'sort_name_desc',
        LibrarySort.recentlyPlayed => 'last_played_desc',
        LibrarySort.recentlyAdded => 'timestamp_added_desc',
        LibrarySort.mostPlayed => 'play_count_desc',
        _ => 'sort_name',
      },
      if (favorites) 'favorite': true,
      if (albumArtists && category.key == 'artists') 'album_artists_only': true,
    });
    return LibraryPage(items: _items(rows), more: rows.length >= pageSize);
  }

  @override
  Future<LibraryPage> browse(LibraryItem? folder) async {
    final path = folder == null ? null : (folder.raw as Map?)?['path'];
    final rows = [
      for (final r in await _list('music/browse', {'path': ?path}))
        if (r['name'] != '..' && r['path'] != 'root') r,
    ];
    if (folder != null) return LibraryPage(items: _items(rows));
    // The root lists the providers, each with its logo as Music
    // Assistant's own Browse page draws it.
    final logos = await Future.wait([
      for (final r in rows) _providerLogo('${r['provider'] ?? ''}'),
    ]);
    return LibraryPage(
      items: [
        for (final (i, r) in rows.indexed)
          ?_item(r, logo: logos[i].light, logoDark: logos[i].dark),
      ],
    );
  }

  /// Each provider's logo as data URIs: the default one and, where the
  /// provider has one, a version for dark backgrounds.
  final _logos = <String, Future<({String? light, String? dark})>>{};
  Future<Map<String, List<String>>>? _logoVariants;

  Future<({String? light, String? dark})> _providerLogo(String domain) {
    if (domain.isEmpty) return Future.value((light: null, dark: null));
    return _logos.putIfAbsent(domain, () async {
      final variants = await (_logoVariants ??= _loadLogoVariants());
      Future<String?> icon(String variant) async {
        if (!(variants[domain]?.contains(variant) ?? false)) return null;
        try {
          final uri = await _call('providers/icon', {
            'provider': domain,
            'variant': variant,
          });
          return uri is String && uri.startsWith('data:') ? uri : null;
        } on LibraryError {
          return null;
        }
      }

      final both = await Future.wait([icon('default'), icon('dark')]);
      return (light: both[0], dark: both[1]);
    });
  }

  /// The logo versions each provider ships, by domain.
  Future<Map<String, List<String>>> _loadLogoVariants() async {
    try {
      return {
        for (final m in await _list('providers/manifests'))
          '${m['domain'] ?? ''}': [
            for (final v in (m['icon_images'] as List? ?? const [])) '$v',
          ],
      };
    } on LibraryError {
      _logoVariants = null;
      return const {};
    }
  }

  Map<String, Object?> _ref(LibraryItem item) {
    final raw = item.raw as Map? ?? const {};
    return {
      'item_id': '${raw['item_id'] ?? ''}',
      'provider_instance_id_or_domain': '${raw['provider'] ?? ''}',
    };
  }

  @override
  Future<LibraryDetail> open(LibraryItem item) async {
    final raw = item.raw as Map? ?? const {};
    switch (item.kind) {
      case LibraryKind.album:
        final tracks = _items(
          await _call('music/albums/album_tracks', _ref(item)),
        );
        return LibraryDetail(
          item: item,
          year: raw['year'] is int ? raw['year'] as int : null,
          tracks: tracks,
        );
      case LibraryKind.playlist:
        return LibraryDetail(
          item: item,
          tracks: _items(
            await _call('music/playlists/playlist_tracks', _ref(item)),
          ),
        );
      case LibraryKind.podcast:
        return LibraryDetail(
          item: item,
          tracks: _items(
            await _call('music/podcasts/podcast_episodes', _ref(item)),
          ),
        );
      case LibraryKind.artist:
        final results = await Future.wait([
          _call('music/artists/artist_tracks', _ref(item)),
          _call('music/artists/artist_albums', _ref(item)),
        ]);
        final albums = _items(results[1]);
        return LibraryDetail(
          item: item,
          tracks: _items(results[0]).take(10).toList(),
          shelves: [
            if (albums.isNotEmpty) LibraryShelf(key: 'albums', items: albums),
          ],
        );
      case LibraryKind.genre:
        // The rows Music Assistant's genre page shows, else its tracks.
        final shelves = [
          for (final folder in await _list('music/genres/overview', _ref(item)))
            if (_items(folder['items']) case final items when items.isNotEmpty)
              LibraryShelf(title: '${folder['name'] ?? ''}', items: items),
        ];
        return LibraryDetail(
          item: item,
          shelves: shelves,
          tracks: shelves.isNotEmpty
              ? const []
              : _items(
                  await _call('music/genres/tracks', {
                    'item_id': '${raw['item_id'] ?? ''}',
                  }),
                ),
        );
      case LibraryKind.folder:
        return LibraryDetail(item: item, tracks: (await browse(item)).items);
      default:
        return LibraryDetail(item: item);
    }
  }

  @override
  Future<String?> play(
    LibraryItem item,
    PlayMode mode, {
    required String pick,
    LibraryItem? within,
  }) async {
    final queue = await _queueOf(pick);
    if (queue.isEmpty) return 'no_speaker';
    // A track tapped inside an album or playlist plays the rest of it
    // from there.
    final inside = within != null && item.kind == LibraryKind.track;
    try {
      await _call('player_queues/play_media', {
        'queue_id': queue,
        'media': inside ? within.id : item.id,
        'option': switch (mode) {
          PlayMode.replace || PlayMode.radio => 'replace',
          PlayMode.now => 'play',
          PlayMode.next => 'next',
          PlayMode.add => 'add',
        },
        'radio_mode': mode == PlayMode.radio,
        if (inside) 'start_item': (item.raw as Map?)?['item_id'],
      });
      return null;
    } on LibraryError catch (e) {
      return e.message;
    }
  }

  /// The queue a pick plays into: a Music Assistant player's own, or this
  /// device's player's. Its id names the player too.
  Future<String> _queueOf(String pick) async => pick.startsWith('ma:')
      ? pick.substring(3)
      : pick.isEmpty
      ? await ownQueueId()
      : '';

  /// The whole list drawn from, by the server's own random order.
  @override
  Future<LibraryItem?> randomItem(
    LibraryCategory category, {
    bool favorites = false,
  }) async {
    final rows = await _list('music/${category.key}/library_items', {
      'limit': 1,
      'offset': 0,
      'order_by': 'random',
      if (favorites) 'favorite': true,
    });
    final items = _items(rows);
    if (items.isNotEmpty) return items.first;
    return super.randomItem(category, favorites: favorites);
  }

  @override
  Future<SpeakerState?> speakerState(String pick) async {
    final queue = await _queueOf(pick);
    if (queue.isEmpty) return null;
    try {
      final results = await Future.wait([
        _call('player_queues/get', {'queue_id': queue}),
        _call('players/get', {'player_id': queue}),
      ]);
      final q = results[0], p = results[1];
      final volume = p is Map ? p['volume_level'] : null;
      return SpeakerState(
        volume: volume is num ? volume.round() : null,
        shuffle: q is Map && q['shuffle_enabled'] is bool
            ? q['shuffle_enabled'] as bool
            : null,
        repeat: q is Map && q['repeat_mode'] is String
            ? q['repeat_mode'] as String
            : null,
      );
    } on LibraryError {
      return null;
    }
  }

  @override
  Future<bool> setPlayModes(
    String pick, {
    bool? shuffle,
    String? repeat,
  }) async {
    final queue = await _queueOf(pick);
    if (queue.isEmpty) return false;
    try {
      if (shuffle != null) {
        await _call('player_queues/shuffle', {
          'queue_id': queue,
          'shuffle_enabled': shuffle,
        });
      }
      if (repeat != null) {
        await _call('player_queues/repeat', {
          'queue_id': queue,
          'repeat_mode': repeat,
        });
      }
      return true;
    } on LibraryError {
      return false;
    }
  }

  @override
  Future<bool> setSpeakerVolume(String pick, int percent) async {
    final queue = await _queueOf(pick);
    if (queue.isEmpty) return false;
    try {
      await _call('players/cmd/volume_set', {
        'player_id': queue,
        'volume_level': percent.clamp(0, 100),
      });
      return true;
    } on LibraryError {
      return false;
    }
  }

  @override
  Future<bool> stopSpeaker(String pick) async {
    final queue = await _queueOf(pick);
    if (queue.isEmpty) return false;
    try {
      await _call('player_queues/stop', {'queue_id': queue});
      return true;
    } on LibraryError {
      return false;
    }
  }

  @override
  Future<bool> clearSpeaker(String pick) async {
    final queue = await _queueOf(pick);
    if (queue.isEmpty) return false;
    try {
      await _call('player_queues/clear', {'queue_id': queue});
      return true;
    } on LibraryError {
      return stopSpeaker(pick);
    }
  }

  @override
  Future<bool> setFavorite(LibraryItem item, bool favorite) async {
    try {
      if (favorite) {
        await _call('music/favorites/add_item', {'item': item.id});
        return true;
      }
      // Taking it out needs the library's own copy.
      final copy = await _call('music/item_by_uri', {'uri': item.id});
      if (copy is! Map) return false;
      await _call('music/favorites/remove_item', {
        'media_type': copy['media_type'],
        'library_item_id': copy['item_id'],
      });
      return true;
    } on LibraryError {
      return false;
    }
  }

  List<LibraryItem> _items(Object? rows) => [
    if (rows is Iterable)
      for (final row in rows.whereType<Map>()) ?_item(row),
  ];

  LibraryItem? _item(Map m, {String? logo, String? logoDark}) {
    final kind = switch ('${m['media_type'] ?? ''}') {
      'artist' => LibraryKind.artist,
      'album' => LibraryKind.album,
      'track' => LibraryKind.track,
      'playlist' => LibraryKind.playlist,
      'radio' => LibraryKind.radio,
      'podcast' => LibraryKind.podcast,
      'podcast_episode' => LibraryKind.episode,
      'audiobook' => LibraryKind.audiobook,
      'genre' => LibraryKind.genre,
      'folder' => LibraryKind.folder,
      _ => null,
    };
    if (kind == null) return null;
    final names = [
      for (final a in (m['artists'] as List? ?? const []).whereType<Map>())
        '${a['name'] ?? ''}',
    ].where((n) => n.isNotEmpty);
    final owner = '${m['owner'] ?? ''}';
    final duration = m['duration'];
    return LibraryItem(
      id: '${m['uri'] ?? ''}',
      kind: kind,
      title: '${m['name'] ?? ''}',
      subtitle: switch (kind) {
        LibraryKind.track || LibraryKind.album => names.join(', '),
        LibraryKind.playlist => owner,
        LibraryKind.audiobook => [
          for (final a in (m['authors'] as List? ?? const [])) '$a',
        ].join(', '),
        LibraryKind.podcast => '${m['publisher'] ?? ''}',
        _ => '',
      },
      art: _art(m) ?? logo,
      artDark: logoDark,
      playable: kind == LibraryKind.folder ? m['is_playable'] == true : true,
      expandable: switch (kind) {
        LibraryKind.artist ||
        LibraryKind.album ||
        LibraryKind.playlist ||
        LibraryKind.podcast ||
        LibraryKind.genre ||
        LibraryKind.folder => true,
        _ => false,
      },
      durationMs: duration is num && duration > 0
          ? (duration * 1000).round()
          : null,
      favorite: m['favorite'] == true,
      inLibrary: '${m['provider'] ?? ''}' == 'library',
      raw: m,
    );
  }

  String? _art(Map m) {
    final base = webBase();
    final metadata = m['metadata'];
    return queueImageUrl(m['image'], base, size: 256) ??
        (metadata is Map
            ? queueImageUrl(metadata['images'], base, size: 256)
            : null) ??
        (m['album'] is Map
            ? queueImageUrl((m['album'] as Map)['image'], base, size: 256)
            : null);
  }
}
