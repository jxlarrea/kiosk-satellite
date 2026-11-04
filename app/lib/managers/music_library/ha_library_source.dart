import 'dart:async';

import 'library_model.dart';

/// A Home Assistant speaker's own media tree: what its integration lists
/// (a Sonos's favorites, a Spotify account, Radio Browser, local media)
/// and search where the integration supports it. The tree belongs to the
/// speaker, so there is nothing to show until one is picked.
class HaLibrarySource extends LibrarySource {
  HaLibrarySource({required this.request, required this.baseUrl});

  /// One Home Assistant websocket command and its result. Throws on an
  /// error answer.
  final Future<Object?> Function(Map<String, Object?> command) request;

  /// Home Assistant's address, for thumbnails given as paths.
  final String Function() baseUrl;

  static const _searchFeature = 4194304;
  static const _enqueueFeature = 2097152;

  /// Media sources with nothing to play on a speaker: pictures, cameras,
  /// the AI image store, generated speech.
  static const _hidden = {
    'media-source://ai_task',
    'media-source://camera',
    'media-source://image',
    'media-source://image_upload',
    'media-source://tts',
    'media-source://unifiprotect',
    'media-source://frigate',
    'media-source://nest',
    'media-source://reolink',
    'media-source://xbox',
  };

  String _entity = '';
  int _features = 0;

  @override
  String get key => 'ha';

  @override
  bool get hasSearch => _features & _searchFeature != 0;

  @override
  bool get hasBrowse => true;

  Future<void> _ready = Future.value();

  /// Settles once the followed speaker's features are read.
  Future<void> get ready => _ready;

  /// The speaker whose tree is shown, from the player pick. Reads its
  /// features so search shows only where it works.
  Future<void> follow(String pick) {
    final entity = pick.startsWith('ha:') ? pick.substring(3) : '';
    if (entity == _entity) return _ready;
    _entity = entity;
    _features = 0;
    return _ready = entity.isEmpty ? Future.value() : _readFeatures(entity);
  }

  Future<void> _readFeatures(String entity) async {
    try {
      final states = await request({'type': 'get_states'});
      if (states is! List || entity != _entity) return;
      for (final s in states.whereType<Map>()) {
        if (s['entity_id'] != entity) continue;
        final f = (s['attributes'] as Map?)?['supported_features'];
        _features = f is int ? f : 0;
        break;
      }
    } catch (_) {
      // No search then; browsing still works.
    }
  }

  void _needSpeaker() {
    if (_entity.isEmpty) throw const LibraryError('no_speaker');
  }

  Future<Map> _browse(LibraryItem? folder) async {
    await _ready;
    _needSpeaker();
    final raw = folder?.raw as Map?;
    final result = await _ask({
      'type': 'media_player/browse_media',
      'entity_id': _entity,
      if (raw != null) 'media_content_id': raw['media_content_id'],
      if (raw != null) 'media_content_type': raw['media_content_type'],
    });
    return result is Map ? result : const {};
  }

  Future<Object?> _ask(Map<String, Object?> command) async {
    try {
      return await request(command);
    } on LibraryError {
      rethrow;
    } catch (e) {
      throw LibraryError('$e'.replaceFirst('Bad state: ', ''));
    }
  }

  @override
  Future<LibraryPage> browse(LibraryItem? folder) async {
    final node = await _browse(folder);
    final children = _items(node['children']);
    return LibraryPage(
      items: folder == null
          ? [
              for (final c in children)
                if (!_hidden.any(c.id.startsWith)) c,
            ]
          : children,
    );
  }

  @override
  Future<LibraryDetail> open(LibraryItem item) async {
    final node = await _browse(item);
    final children = _items(node['children']);
    final opened = _item(node);
    return LibraryDetail(
      item: opened == null || opened.title.isEmpty
          ? item
          : LibraryItem(
              id: opened.id,
              kind: item.kind,
              title: opened.title,
              subtitle: item.subtitle,
              art: opened.art ?? item.art,
              playable: opened.playable,
              expandable: true,
              raw: opened.raw,
            ),
      tracks: children,
    );
  }

  @override
  Future<List<LibraryShelf>> search(String query) async {
    await _ready;
    _needSpeaker();
    final q = query.trim();
    if (q.isEmpty || !hasSearch) return const [];
    final result = await _ask({
      'type': 'call_service',
      'domain': 'media_player',
      'service': 'search_media',
      'target': {'entity_id': _entity},
      'service_data': {'search_query': q},
      'return_response': true,
    });
    final response = result is Map ? result['response'] : null;
    final mine = response is Map ? response[_entity] : null;
    final items = _items(mine is Map ? mine['result'] : null);
    if (items.isEmpty) return const [];
    // Shelves by kind, the way the other sources answer.
    final byKind = <LibraryKind, List<LibraryItem>>{};
    for (final i in items) {
      byKind.putIfAbsent(i.kind, () => []).add(i);
    }
    const order = {
      LibraryKind.track: 'tracks',
      LibraryKind.artist: 'artists',
      LibraryKind.album: 'albums',
      LibraryKind.playlist: 'playlists',
      LibraryKind.radio: 'radio',
      LibraryKind.podcast: 'podcasts',
    };
    return [
      for (final e in order.entries)
        if (byKind.remove(e.key) case final list?)
          LibraryShelf(key: e.value, items: list),
      if (byKind.values.expand((l) => l).toList() case final rest
          when rest.isNotEmpty)
        LibraryShelf(key: 'more', items: rest),
    ];
  }

  @override
  bool needsSpeaker(String pick) => !pick.startsWith('ha:');

  @override
  Future<String?> play(
    LibraryItem item,
    PlayMode mode, {
    required String pick,
    LibraryItem? within,
  }) async {
    final entity = pick.startsWith('ha:') ? pick.substring(3) : '';
    if (entity.isEmpty) return 'no_speaker';
    final raw = item.raw as Map? ?? const {};
    // A speaker without a queue takes the media as is.
    final enqueue = entity == _entity && _features & _enqueueFeature != 0;
    try {
      await _ask({
        'type': 'call_service',
        'domain': 'media_player',
        'service': 'play_media',
        'target': {'entity_id': entity},
        'service_data': {
          'media_content_id': raw['media_content_id'],
          'media_content_type': raw['media_content_type'],
          if (enqueue)
            'enqueue': switch (mode) {
              PlayMode.replace || PlayMode.radio => 'replace',
              PlayMode.now => 'play',
              PlayMode.next => 'next',
              PlayMode.add => 'add',
            },
        },
      });
      return null;
    } on LibraryError catch (e) {
      return e.message;
    }
  }

  String _entityOf(String pick) =>
      pick.startsWith('ha:') ? pick.substring(3) : '';

  @override
  Future<SpeakerState?> speakerState(String pick) async {
    final entity = _entityOf(pick);
    if (entity.isEmpty) return null;
    try {
      final states = await request({'type': 'get_states'});
      if (states is! List) return null;
      for (final s in states.whereType<Map>()) {
        if (s['entity_id'] != entity) continue;
        final a = s['attributes'] as Map? ?? const {};
        final volume = a['volume_level'];
        return SpeakerState(
          volume: volume is num ? (volume * 100).round() : null,
          shuffle: a['shuffle'] is bool ? a['shuffle'] as bool : null,
          repeat: a['repeat'] is String ? a['repeat'] as String : null,
        );
      }
    } catch (_) {
      // Nothing to put back then.
    }
    return null;
  }

  Future<bool> _service(String entity, String service, [Map? data]) async {
    try {
      await request({
        'type': 'call_service',
        'domain': 'media_player',
        'service': service,
        'target': {'entity_id': entity},
        'service_data': ?data,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> setPlayModes(
    String pick, {
    bool? shuffle,
    String? repeat,
  }) async {
    final entity = _entityOf(pick);
    if (entity.isEmpty) return false;
    var ok = true;
    if (shuffle != null) {
      ok = await _service(entity, 'shuffle_set', {'shuffle': shuffle}) && ok;
    }
    if (repeat != null) {
      ok = await _service(entity, 'repeat_set', {'repeat': repeat}) && ok;
    }
    return ok;
  }

  @override
  Future<bool> setSpeakerVolume(String pick, int percent) async {
    final entity = _entityOf(pick);
    if (entity.isEmpty) return false;
    return _service(entity, 'volume_set', {
      'volume_level': percent.clamp(0, 100) / 100,
    });
  }

  @override
  Future<bool> stopSpeaker(String pick) async {
    final entity = _entityOf(pick);
    if (entity.isEmpty) return false;
    return await _service(entity, 'media_stop') ||
        await _service(entity, 'media_pause');
  }

  @override
  Future<bool> clearSpeaker(String pick) async {
    final stopped = await stopSpeaker(pick);
    final entity = _entityOf(pick);
    if (entity.isNotEmpty) await _service(entity, 'clear_playlist');
    return stopped;
  }

  List<LibraryItem> _items(Object? rows) => [
    if (rows is Iterable)
      for (final row in rows.whereType<Map>()) ?_item(row),
  ];

  LibraryItem? _item(Map m) {
    final id = '${m['media_content_id'] ?? ''}';
    final cls = '${m['media_class'] ?? ''}';
    final canExpand = m['can_expand'] == true;
    final kind = switch (cls) {
      'artist' => LibraryKind.artist,
      'album' => LibraryKind.album,
      'track' || 'music' => canExpand ? LibraryKind.folder : LibraryKind.track,
      'playlist' => LibraryKind.playlist,
      'podcast' => LibraryKind.podcast,
      'episode' => LibraryKind.episode,
      'channel' => canExpand ? LibraryKind.folder : LibraryKind.radio,
      _ => canExpand ? LibraryKind.folder : LibraryKind.other,
    };
    return LibraryItem(
      id: id.isEmpty ? '${m['media_content_type'] ?? ''}' : id,
      kind: kind,
      title: '${m['title'] ?? ''}',
      art: _thumb(m['thumbnail']),
      playable: m['can_play'] == true,
      expandable: canExpand,
      raw: m,
    );
  }

  String? _thumb(Object? thumbnail) {
    final t = '${thumbnail ?? ''}';
    if (t.isEmpty) return null;
    if (t.startsWith('http')) return t;
    final base = baseUrl().trim().replaceFirst(RegExp(r'/+$'), '');
    return base.isEmpty ? null : '$base${t.startsWith('/') ? '' : '/'}$t';
  }
}
