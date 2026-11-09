import 'dart:async';

import '../../core/command_registry.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import '../analytics/usage_counters.dart';
import 'ha_library_source.dart';
import 'library_model.dart';
import 'music_library_manager.dart';
import 'sonos_library_source.dart';
import '../plugins/plugin_players.dart';

/// What the Kiosk Satellite music script asks for: play something on the
/// speaker this kiosk's Now Playing follows (or one the user names),
/// queue it, open the library on it, say what is playing, steer the
/// transport and the volume, read or clear the queue and list the
/// speakers. Answers in the shape the script hands back to the LLM.
class MusicRequests {
  MusicRequests(this._settings, this._library, this._commands);

  final SettingsManager _settings;
  final MusicLibraryManager _library;
  final CommandRegistry _commands;

  /// How long a play is waited for before the answer says it is starting.
  static const playWait = Duration(seconds: 8);

  Future<Map<String, Object?>> handle(Map<String, Object?> p) async {
    final action = '${p['action'] ?? ''}'.trim();
    if (action.isNotEmpty) {
      unawaited(UsageCounters.bump(_settings, 'library_voice_requests'));
    }
    String text(String key) => '${p[key] ?? ''}'.trim();
    try {
      return switch (action) {
        'play' => await _play(
          query: text('query'),
          kind: text('kind'),
          artist: text('artist'),
          mode: text('mode'),
          speaker: text('speaker'),
        ),
        'show' => await _show(text('query'), text('kind')),
        'now_playing' => await _nowPlaying(),
        'pause' || 'resume' || 'next' || 'previous' => await _control(action),
        'volume' ||
        'volume_up' ||
        'volume_down' => await _volume(action, p['level']),
        'queue' => await _queue(),
        'clear_queue' => await _clearQueue(),
        'speakers' => await _speakers(),
        _ => _fail('unknown_action'),
      };
    } on LibraryError catch (e) {
      return _fail(e.message);
    }
  }

  Map<String, Object?> _ok(String result, [Map<String, Object?>? more]) => {
    'ok': true,
    'kiosk': _settings.get(defs.deviceName),
    'result': result,
    ...?more,
  };

  Map<String, Object?> _fail(String error, [Map<String, Object?>? more]) => {
    'ok': false,
    'kiosk': _settings.get(defs.deviceName),
    'error': error,
    ...?more,
  };

  // ── Playing ───────────────────────────────────────────────────────

  Future<Map<String, Object?>> _play({
    required String query,
    required String kind,
    required String artist,
    required String mode,
    required String speaker,
  }) async {
    if (query.isEmpty && artist.isEmpty) return _fail('query_required');
    final target = await _target(speaker);
    if (target.error != null) return target.error!;
    final source = _library.sourceFor(target.source)!;
    if (source is HaLibrarySource) await source.follow(target.pick);
    final found = await _find(source, query.isEmpty ? artist : query);
    final best = bestMatch(
      found,
      query: query.isEmpty ? artist : query,
      kind: kind,
      artist: query.isEmpty ? '' : artist,
    );
    if (best == null) {
      return _fail(
        found.isEmpty && !_searches(source) ? 'no_search' : 'nothing_found',
        {'query': query, 'speaker': target.name},
      );
    }
    final playMode = switch (mode) {
      'next' => PlayMode.next,
      'add' => PlayMode.add,
      'radio' => PlayMode.radio,
      _ => PlayMode.replace,
    };
    // Music Assistant answers a play once it has the music ready, which
    // for an artist or a long playlist on a service can take longer than
    // the conversation waits for a tool. Past a few seconds the answer is
    // that it is starting, and the play carries on.
    var slow = false;
    final error = await source
        .play(best.item, playMode, pick: target.pick)
        .timeout(
          playWait,
          onTimeout: () {
            slow = true;
            return null;
          },
        );
    if (error != null) return _fail(error, {'speaker': target.name});
    // Counted like a tap in the library: by source, or as a queue add.
    unawaited(
      UsageCounters.bump(
        _settings,
        playMode == PlayMode.next || playMode == PlayMode.add
            ? 'library_queue_adds'
            : 'library_plays_${source.key}',
      ),
    );
    return _ok(
      switch (playMode) {
        PlayMode.next => 'playing_next',
        PlayMode.add => 'added_to_queue',
        PlayMode.radio => slow ? 'radio_starting' : 'radio_started',
        _ => slow ? 'starting' : 'playing',
      },
      {
        'title': best.item.title,
        if (best.item.subtitle.isNotEmpty) 'artist': best.item.subtitle,
        'kind': best.item.kind.name,
        'speaker': target.name,
        if (best.others.isNotEmpty)
          'other_matches': [
            for (final o in best.others)
              {
                'title': o.title,
                if (o.subtitle.isNotEmpty) 'artist': o.subtitle,
                'kind': o.kind.name,
              },
          ],
      },
    );
  }

  bool _searches(LibrarySource s) => s.hasSearch || s is SonosLibrarySource;

  /// The search results, or for a Sonos, which has no search, its
  /// favorites.
  Future<List<LibraryShelf>> _find(LibrarySource source, String query) async {
    if (source.hasSearch) return source.search(query);
    if (source is SonosLibrarySource) {
      final favorites = await source.list(source.categories.first);
      return [LibraryShelf(key: 'favorites', items: favorites.items)];
    }
    return const [];
  }

  /// The speaker a play lands on: the one [named], made the followed one,
  /// or the one this kiosk already follows.
  Future<
    ({String pick, String name, String source, Map<String, Object?>? error})
  >
  _target(String named) async {
    if (_library.available.isEmpty) {
      return (pick: '', name: '', source: '', error: _fail('no_source'));
    }
    if (named.isEmpty) {
      final pick = _library.pick.value;
      // A plugin player's library is keyed by the player's own pick.
      final source = PluginPlayers.isPick(pick)
          ? pick
          : pick.contains(':')
          ? pick.substring(0, pick.indexOf(':'))
          : (_library.pickIn('ma') ? 'ma' : '');
      if (source.isEmpty || !_library.available.contains(source)) {
        return (
          pick: '',
          name: '',
          source: '',
          error: _fail('no_speaker', {'speakers': await _speakerNames()}),
        );
      }
      return (
        pick: pick,
        name: await _followedName(),
        source: source,
        error: null,
      );
    }
    final wanted = normalize(named).replaceAll(' ', '');
    final current = _library.source.value?.key;
    final order = [
      ?current,
      for (final k in _library.available)
        if (k != current) k,
    ];
    LibrarySpeaker? contains;
    var containsSource = '';
    for (final key in order) {
      final (speakers, _) = await _library.speakers(key);
      for (final s in speakers.where((s) => s.available)) {
        final name = normalize(s.name).replaceAll(' ', '');
        if (name == wanted) {
          return await _followed(s, key);
        }
        if (contains == null &&
            (name.contains(wanted) || wanted.contains(name))) {
          contains = s;
          containsSource = key;
        }
      }
    }
    if (contains != null) return await _followed(contains, containsSource);
    return (
      pick: '',
      name: '',
      source: '',
      error: _fail('speaker_not_found', {
        'speaker': named,
        'speakers': await _speakerNames(),
      }),
    );
  }

  Future<
    ({String pick, String name, String source, Map<String, Object?>? error})
  >
  _followed(LibrarySpeaker speaker, String source) async {
    if (speaker.pick != _library.pick.value) await _library.follow(speaker);
    return (
      pick: speaker.pick,
      name: speaker.name,
      source: source,
      error: null,
    );
  }

  Future<String> _followedName() async {
    final state = await _commands.execute('mediaPlayerState', const {});
    final data = state.data;
    final name = data is Map ? '${data['source'] ?? ''}' : '';
    if (name.isNotEmpty) return name;
    final picked = _library.pickName.value.trim();
    return picked.isNotEmpty ? picked : _settings.get(defs.deviceName);
  }

  Future<List<String>> _speakerNames() async {
    final key = _library.source.value?.key ?? _library.available.firstOrNull;
    if (key == null) return const [];
    final (speakers, _) = await _library.speakers(key);
    return [
      for (final s in speakers)
        if (s.available) s.name,
    ];
  }

  // ── The library on screen ─────────────────────────────────────────

  Future<Map<String, Object?>> _show(String query, String kind) async {
    if (_library.available.isEmpty) return _fail('no_source');
    final category = switch (kind) {
      'artist' => 'artists',
      'album' => 'albums',
      'track' => 'tracks',
      'playlist' => 'playlists',
      'radio' => 'radios',
      'podcast' => 'podcasts',
      'audiobook' => 'audiobooks',
      _ => null,
    };
    await _library.openAt(
      query: query.isEmpty ? null : query,
      category: query.isEmpty ? category : null,
    );
    return _ok('shown', {if (query.isNotEmpty) 'query': query});
  }

  // ── The followed player ───────────────────────────────────────────

  Future<Map<String, Object?>> _nowPlaying() async {
    final state = await _commands.execute('mediaPlayerState', const {});
    final data = state.data is Map
        ? (state.data! as Map).cast<String, Object?>()
        : const <String, Object?>{};
    return _ok('now_playing', {
      'state': data['state'] ?? 'idle',
      if ('${data['title'] ?? ''}'.isNotEmpty) 'title': data['title'],
      if ('${data['artist'] ?? ''}'.isNotEmpty) 'artist': data['artist'],
      'speaker': await _followedName(),
    });
  }

  Future<Map<String, Object?>> _control(String action) async {
    final r = await _commands.execute('sendspinControl', {
      'command': action == 'resume' ? 'play' : action,
    });
    return r.ok ? _ok(action) : _fail(r.error ?? 'not_sent');
  }

  Future<Map<String, Object?>> _volume(String action, Object? level) async {
    final r = await _commands.execute('mediaVolume', {
      if (action == 'volume')
        'level': level is num ? level : num.tryParse('$level'),
      if (action == 'volume_up') 'delta': 10,
      if (action == 'volume_down') 'delta': -10,
    });
    final data = r.data;
    return r.ok
        ? _ok('volume_set', {if (data is Map) 'volume': data['volume']})
        : _fail(r.error ?? 'not_set');
  }

  Future<Map<String, Object?>> _queue() async {
    final r = await _commands.execute('mediaQueue', {'action': 'list'});
    final data = r.data;
    return r.ok && data is Map
        ? _ok('queue', data.cast<String, Object?>())
        : _fail(r.error ?? 'no_queue');
  }

  Future<Map<String, Object?>> _clearQueue() async {
    final r = await _commands.execute('mediaQueue', {'action': 'clear'});
    return r.ok ? _ok('queue_cleared') : _fail(r.error ?? 'not_cleared');
  }

  Future<Map<String, Object?>> _speakers() async {
    if (_library.available.isEmpty) return _fail('no_source');
    return _ok('speakers', {
      'speakers': await _speakerNames(),
      'following': await _followedName(),
    });
  }

  // ── Matching ──────────────────────────────────────────────────────

  /// Lower case, letters and digits only, single spaces.
  static String normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();

  static const _kindOrder = {
    LibraryKind.artist: 6,
    LibraryKind.playlist: 5,
    LibraryKind.album: 4,
    LibraryKind.track: 3,
    LibraryKind.radio: 2,
    LibraryKind.podcast: 1,
    LibraryKind.audiobook: 1,
  };

  /// The entry of [shelves] the user most likely means: a title equal to
  /// [query] first, then one that starts with it, then one that has it,
  /// [artist] deciding between the same title by several artists. [kind]
  /// (track, album, artist, playlist, radio) keeps only that kind. What is
  /// in the user's library or a favorite wins over the same name found on
  /// a service. Past that, with no kind, an artist, a playlist or an album
  /// wins over a track of the same name, and the others of that name come
  /// back in [others] for the agent to offer. The source's own order
  /// breaks ties.
  static ({LibraryItem item, List<LibraryItem> others})? bestMatch(
    List<LibraryShelf> shelves, {
    required String query,
    String kind = '',
    String artist = '',
  }) {
    // Compared without spaces too: speech to text writes "Night Shift"
    // as Nightshift as often as not.
    final q = normalize(query).replaceAll(' ', '');
    final a = normalize(artist).replaceAll(' ', '');
    final wanted = LibraryKind.values.where((k) => k.name == kind).firstOrNull;
    final scored = <(LibraryItem, double)>[];
    for (final shelf in shelves) {
      for (final (i, item) in shelf.items.indexed) {
        if (!item.playable) continue;
        if (wanted != null && item.kind != wanted) continue;
        final t = normalize(item.title).replaceAll(' ', '');
        var score = t == q
            ? 100.0
            : t.startsWith(q) || (q.startsWith(t) && t.length * 2 > q.length)
            ? 60.0
            : t.contains(q)
            ? 40.0
            : 0.0;
        if (a.isNotEmpty) {
          final by = normalize(item.subtitle).replaceAll(' ', '');
          score += by.contains(a) ? 30 : (by.isEmpty ? 0 : -50);
        }
        if (score <= 0) continue;
        // The user's own music before a stranger's of the same name: a
        // track in the library over an artist found on a service.
        if (item.inLibrary) score += 12;
        if (item.favorite) score += 6;
        score += (_kindOrder[item.kind] ?? 0) + (20 - i).clamp(0, 20) / 10;
        scored.add((item, score));
      }
    }
    if (scored.isEmpty) {
      // Nothing by name: the search's own first pick of the kind asked
      // for, tracks before the rest.
      final pool = [
        for (final shelf in shelves)
          for (final item in shelf.items)
            if (item.playable && (wanted == null || item.kind == wanted)) item,
      ];
      if (pool.isEmpty) return null;
      final track = pool.where((i) => i.kind == LibraryKind.track).firstOrNull;
      return (item: track ?? pool.first, others: const <LibraryItem>[]);
    }
    scored.sort((x, y) => y.$2.compareTo(x.$2));
    final best = scored.first.$1;
    final title = normalize(best.title).replaceAll(' ', '');
    // The same title in another kind, by the artist asked for when one
    // was: worth offering. Once each.
    final seen = <String>{};
    final others = [
      for (final (item, _) in scored.skip(1))
        if (normalize(item.title).replaceAll(' ', '') == title &&
            item.kind != best.kind &&
            (a.isEmpty ||
                normalize(item.subtitle).replaceAll(' ', '').contains(a)) &&
            seen.add('${item.kind.name}|${normalize(item.subtitle)}'))
          item,
    ].take(3).toList();
    return (item: best, others: others);
  }
}
