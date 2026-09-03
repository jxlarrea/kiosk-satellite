import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'remote_player.dart';

/// The primary artist of a Sendspin slash-joined credit, or null when
/// [artist] offers no different name to retry a track lookup with.
String? lyricsRetryArtist(String artist) {
  if (!artist.contains('/')) return null;
  final primary = artist.split('/').first.trim();
  return primary.isEmpty || primary == artist.trim() ? null : primary;
}

/// The browsable web interface behind the configured server address, or
/// null when no address is set.
///
/// The same address the API uses, minus the protocol juggling: whatever the
/// user typed is a host they can also open in a WebView, so a missing scheme
/// becomes https (as with the API) and a websocket scheme is mapped back to
/// the http one it was derived from.
///
/// A non-empty [player] lands the interface on that player instead of
/// whichever one it showed last: Music Assistant's frontend routes in the
/// URL fragment, so the parameter goes after the hash (issue #265).
String? musicAssistantWebUrl(String raw, {String player = ''}) {
  final trimmed = raw.trim().replaceAll(RegExp(r'/+$'), '');
  if (trimmed.isEmpty) return null;
  final withScheme = trimmed.startsWith('http') || trimmed.startsWith('ws')
      ? trimmed
      : 'https://$trimmed';
  final uri = Uri.tryParse(withScheme);
  if (uri == null || !uri.hasAuthority) return null;
  final base = uri
      .replace(
        scheme: switch (uri.scheme) {
          'ws' => 'http',
          'wss' => 'https',
          final other => other,
        },
      )
      .toString();
  if (player.trim().isEmpty) return base;
  return '$base/#/?player=${Uri.encodeComponent(player.trim())}';
}

/// The player the Music Assistant web interface should land on: the
/// followed remote player when one is picked, otherwise this device's own
/// player — provided it is enabled, since selecting a player that is not
/// registered does nothing. Empty means leave the interface on whatever
/// it showed last.
/// The followed player's name when it is a Music Assistant player, empty
/// otherwise: the web interface can only land on its own players.
String maFollowedPlayerName(SettingsManager settings) =>
    PlayerSource.parse(settings.get(defs.sendspinPlayer)).kind ==
        PlayerSourceKind.musicAssistant
    ? settings.get(defs.sendspinPlayerName)
    : '';

String maLandingPlayer({
  required String remotePlayerName,
  required String localPlayerName,
  required bool localPlayerEnabled,
}) {
  final remote = remotePlayerName.trim();
  if (remote.isNotEmpty) return remote;
  return localPlayerEnabled ? localPlayerName.trim() : '';
}

/// Whether [url] is a page on the Music Assistant server configured as
/// [serverAddress] — the test that decides whether a page gets handed this
/// device's Music Assistant token.
bool isMusicAssistantOrigin(String url, String serverAddress) {
  final server = musicAssistantWebUrl(serverAddress);
  if (server == null) return false;
  final a = Uri.tryParse(url);
  final b = Uri.parse(server);
  return a != null &&
      a.scheme == b.scheme &&
      a.host == b.host &&
      a.port == b.port;
}

/// A single request/response against Music Assistant's own API.
///
/// Separate from the Sendspin connection on purpose: Sendspin is the player
/// protocol and carries a track's title, artist and album and nothing more.
/// Anything richer — lyrics — lives behind this API, which has its own
/// address, its own token and its own scopes.
///
/// The protocol, as of Music Assistant 2.9: connect to `/ws`, the server
/// opens with an info frame, then every message is
/// `{message_id, command, args}` answered by `{message_id, result}` or
/// `{message_id, error_code, details}`. Authentication is a command like any
/// other (`auth` with a `token` arg) and must come first, since anything
/// with a required scope is refused until it lands.
class MusicAssistantApi {
  MusicAssistantApi({required this.baseUrl, required this.token});

  final String baseUrl;
  final String token;

  /// A Music Assistant address is typically https with a self-signed
  /// certificate (the add-on generates its own), so a normal client refuses
  /// it. The user typed this address themselves, on their own network.
  static HttpClient newHttpClient() => HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..badCertificateCallback = (_, _, _) => true;

  /// `wss://host:8095/ws` from the address as typed, however it was typed.
  Uri get socketUri {
    final trimmed = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final withScheme = trimmed.startsWith('http') || trimmed.startsWith('ws')
        ? trimmed
        : 'https://$trimmed';
    final uri = Uri.parse(withScheme);
    return uri.replace(
      scheme: switch (uri.scheme) {
        'http' => 'ws',
        'ws' => 'ws',
        _ => 'wss',
      },
      path: '${uri.path.replaceAll(RegExp(r'/+$'), '')}/ws',
    );
  }

  /// Opens, authenticates, runs [command], and closes.
  ///
  /// One connection per call: the only caller so far asks once per track,
  /// and a socket held open for that would be a socket to keep alive,
  /// reconnect and account for on a device that spends its life idle.
  Future<MusicAssistantResult> call(
    String command, {
    Map<String, Object?> args = const {},
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (baseUrl.trim().isEmpty) {
      return const MusicAssistantResult.failure('No server address set.');
    }
    if (token.trim().isEmpty) {
      return const MusicAssistantResult.failure('No auth token set.');
    }
    final client = newHttpClient();
    WebSocket? socket;
    try {
      socket = await WebSocket.connect(
        socketUri.toString(),
        customClient: client,
      ).timeout(timeout);
      final session = MaSession(socket);
      await session.send('auth', {'token': token}, timeout: timeout);
      final result = command == 'auth'
          ? null
          : await session.send(command, args, timeout: timeout);
      return MusicAssistantResult.success(result, session.serverInfo);
    } on MusicAssistantError catch (error) {
      return MusicAssistantResult.failure(error.message);
    } on TimeoutException {
      return const MusicAssistantResult.failure(
        'Music Assistant did not answer in time.',
      );
    } on SocketException catch (error) {
      return MusicAssistantResult.failure(
        'Could not reach ${_describeHost()}: ${error.osError?.message ?? error.message}',
      );
    } on WebSocketException catch (error) {
      return MusicAssistantResult.failure(
        'Could not reach ${_describeHost()}: ${error.message}',
      );
    } catch (error) {
      return MusicAssistantResult.failure('$error');
    } finally {
      await socket?.close();
      client.close(force: true);
    }
  }

  String _describeHost() {
    final uri = socketUri;
    return '${uri.host}:${uri.port}';
  }

  /// The group [playerId] plays in and every player it could group with,
  /// from one read of the player list. Null when the server cannot be
  /// reached or knows no such player.
  Future<RemoteGroup?> fetchGroup(String playerId) async {
    final res = await call('players/all');
    final players = res.result;
    if (!res.ok || players is! List) return null;
    return groupFrom(players, playerId);
  }

  /// Put [memberId] in [leaderId]'s group, or take it out of whatever
  /// group it is in. Null when the server took it, its refusal otherwise.
  Future<String?> setGrouped({
    required String leaderId,
    required String memberId,
    required bool grouped,
  }) async {
    final res = grouped
        ? await call(
            'players/cmd/group',
            args: {'player_id': memberId, 'target_player': leaderId},
          )
        : await call('players/cmd/ungroup', args: {'player_id': memberId});
    return res.ok ? null : (res.error ?? 'refused');
  }

  /// [playerId]'s group out of a `players/all` answer: the player it is
  /// synced to leads, or it leads itself; the leader's children are in
  /// the group; every enabled, visible, plain player the leader can
  /// group with (by id, or by belonging to a provider the leader names)
  /// is a candidate. The leader is not listed: it is the menu's title. A bare
  /// Sendspin client id answers for the wrapper Music Assistant lists it
  /// under when the bare player is not in the list itself (a universal
  /// player prefixes the id it wraps).
  static RemoteGroup? groupFrom(List<Object?> players, String playerId) {
    final byId = <String, Map<Object?, Object?>>{
      for (final p in players)
        if (p is Map) '${p['player_id'] ?? ''}': p,
    };
    var myId = playerId;
    var me = byId[myId];
    if (me == null && playerId.isNotEmpty) {
      final wanted = playerId.toLowerCase();
      myId = byId.keys.firstWhere(
        (id) => id.toLowerCase().contains(wanted),
        orElse: () => '',
      );
      me = byId[myId];
    }
    if (me == null) return null;
    final syncedTo = '${me['synced_to'] ?? ''}';
    final leaderId = syncedTo.isNotEmpty ? syncedTo : myId;
    final leader = byId[leaderId] ?? me;
    String nameOf(Map<Object?, Object?> p) =>
        '${p['display_name'] ?? p['name'] ?? p['player_id'] ?? ''}';
    final children = (leader['group_members'] ?? leader['group_childs']);
    final inGroup = {
      leaderId,
      if (children is List) ...children.map((c) => '$c'),
    };
    final canGroup = {
      if (leader['can_group_with'] is List)
        ...(leader['can_group_with'] as List).map((c) => '$c'),
    };
    final members = <GroupMember>[];
    for (final entry in byId.entries) {
      final id = entry.key;
      final p = entry.value;
      if (id == leaderId || id.isEmpty) continue;
      if (p['enabled'] == false ||
          p['hidden'] == true ||
          p['hide_in_ui'] == true) {
        continue;
      }
      if ('${p['type'] ?? ''}' == 'group') continue;
      final grouped = inGroup.contains(id);
      final candidate =
          canGroup.contains(id) || canGroup.contains('${p['provider'] ?? ''}');
      if (!grouped && !candidate) continue;
      members.add(
        GroupMember(
          id: id,
          name: nameOf(p),
          inGroup: grouped,
          available: p['available'] != false,
        ),
      );
    }
    return RemoteGroup(
      selfId: myId,
      leaderId: leaderId,
      leaderName: nameOf(leader),
      members: RemoteGroup.ordered(members),
    );
  }

  /// The current track of the player's active queue, or null when there is
  /// no queue, the queue is empty, or the server cannot be reached.
  ///
  /// This exists for the "Show the Sendspin player" reveal (issue #178):
  /// the Sendspin connection itself announces nothing about a queue that is
  /// not playing, so after an app restart a paused queue is invisible to
  /// the player until someone presses play elsewhere. Music Assistant does
  /// know, and its player id for a Sendspin client is the client id this
  /// device connects with. The active queue is asked for (not the player's
  /// own) so a player synced into a group finds the group's queue.
  ///
  /// The map uses the same keys as Sendspin metadata ('title', 'artist',
  /// 'album', 'durationMs', 'positionMs', 'artworkUrl'), plus 'state' (the
  /// queue's playing/paused/idle) for the caller to decide with.
  Future<Map<String, Object?>?> fetchActiveQueueTrack({
    required String playerId,
  }) async {
    if (playerId.trim().isEmpty ||
        baseUrl.trim().isEmpty ||
        token.trim().isEmpty) {
      return null;
    }
    final client = newHttpClient();
    WebSocket? socket;
    try {
      socket = await WebSocket.connect(
        socketUri.toString(),
        customClient: client,
      ).timeout(const Duration(seconds: 15));
      final session = MaSession(socket);
      await session.send('auth', {'token': token});
      final queue = await session.send('player_queues/get_active_queue', {
        'player_id': playerId,
      });
      return queueTrackSnapshot(queue, webBase: musicAssistantWebUrl(baseUrl));
    } catch (_) {
      return null;
    } finally {
      await socket?.close();
      client.close(force: true);
    }
  }

  /// The synced lyrics for a track, or null when there are none.
  ///
  /// Two calls on one connection: Sendspin only tells us what is playing by
  /// name, so the track has to be found in Music Assistant first
  /// (`music/track_by_name`), and the lyrics lookup wants that whole track
  /// object. Music Assistant asks its own metadata providers, so whatever
  /// the user configured there — LRCLIB and the rest — is what answers.
  ///
  /// Only the LRC half of the reply is used. The plain-text half cannot be
  /// followed along with, and a wall of untimed text is not what a
  /// now-playing screen is for.
  Future<String?> fetchLyrics({
    required String title,
    required String artist,
    String album = '',
  }) async {
    if (title.trim().isEmpty) return null;
    final client = newHttpClient();
    WebSocket? socket;
    try {
      socket = await WebSocket.connect(
        socketUri.toString(),
        customClient: client,
      ).timeout(const Duration(seconds: 15));
      final session = MaSession(socket);
      await session.send('auth', {'token': token});
      var track = await session.send('music/track_by_name', {
        'track_name': title,
        if (artist.isNotEmpty) 'artist_name': artist,
        if (album.isNotEmpty) 'album_name': album,
      });
      // Sendspin credits a multi-artist track as one slash-joined string
      // ("The Porter's Gate/Liz Vice"), which track_by_name does not match
      // — the primary artist alone does (issue #90). Retry only on a miss,
      // so an artist with a real slash in the name (AC/DC) still matches
      // whole on the first attempt.
      final primary = lyricsRetryArtist(artist);
      if (track == null && primary != null) {
        track = await session.send('music/track_by_name', {
          'track_name': title,
          'artist_name': primary,
          if (album.isNotEmpty) 'album_name': album,
        });
      }
      if (track == null) return null;
      // Generous: the lyrics answer rides Music Assistant's own provider
      // lookups (LRCLIB et al), measured north of 30s when a provider is
      // slow — and lyrics arriving late still beat lyrics never arriving,
      // on a track that runs minutes.
      final result = await session.send('metadata/get_track_lyrics', {
        'track': track,
      }, timeout: const Duration(seconds: 45));
      // The reply is (plain lyrics, LRC lyrics).
      if (result is! List || result.length < 2) return null;
      final lrc = result[1];
      return lrc is String && lrc.trim().isNotEmpty ? lrc : null;
    } catch (_) {
      return null;
    } finally {
      await socket?.close();
      client.close(force: true);
    }
  }
}

/// The current track of a Music Assistant queue dict, in the same key
/// shape as Sendspin metadata ('title', 'artist', 'album', 'durationMs',
/// 'positionMs', 'artworkUrl'), plus 'state' (the queue's
/// playing/paused/idle) and 'positionAtMs' (epoch ms the server measured
/// the position at) for the caller to decide with. Null when [queue] is
/// not a queue, has no current item, or the item has no name.
///
/// One parser for both queue sources: the one-shot
/// [MusicAssistantApi.fetchActiveQueueTrack] and the live queue_updated
/// events a remote-controlled player streams (issue #265) — the event's
/// data IS the queue dict.
Map<String, Object?>? queueTrackSnapshot(Object? queue, {String? webBase}) {
  if (queue is! Map) return null;
  final item = queue['current_item'];
  if (item is! Map) return null;
  final media = item['media_item'] is Map
      ? (item['media_item'] as Map).cast<String, Object?>()
      : const <String, Object?>{};
  final title = '${media['name'] ?? item['name'] ?? ''}';
  if (title.trim().isEmpty) return null;
  // Sendspin credits multiple artists as one slash-joined string; the
  // recovered card reads the same as a live one.
  final artist = ((media['artists'] as List?) ?? const [])
      .map((a) => a is Map ? '${a['name'] ?? ''}' : '')
      .where((s) => s.isNotEmpty)
      .join('/');
  final album = media['album'] is Map
      ? '${(media['album'] as Map)['name'] ?? ''}'
      : '';
  final duration = (item['duration'] as num?) ?? (media['duration'] as num?);
  final elapsed = queue['elapsed_time'] as num?;
  final measuredAt = queue['elapsed_time_last_updated'] as num?;
  return {
    'state': '${queue['state'] ?? ''}',
    'title': title,
    if (artist.isNotEmpty) 'artist': artist,
    if (album.isNotEmpty) 'album': album,
    if (duration != null) 'durationMs': (duration * 1000).round(),
    'positionMs': ((elapsed ?? 0) * 1000).round(),
    if (measuredAt != null) 'positionAtMs': (measuredAt * 1000).round(),
    'shuffle': queue['shuffle_enabled'] == true,
    // The queue's identity beside the track's, so a watcher can tell a
    // queue edit from a progress tick.
    'queueItemId': '${item['queue_item_id'] ?? ''}',
    'currentIndex': (queue['current_index'] as num?)?.toInt() ?? 0,
    'queueLength': (queue['items'] as num?)?.toInt() ?? 0,
    ...switch (queueImageUrl(item['image'], webBase)) {
      final url? => {'artworkUrl': url},
      null => const <String, Object?>{},
    },
  };
}

/// A fetchable URL for a queue item's image: the path itself when it is
/// a plain web URL, otherwise the server's image proxy (rooted at
/// [webBase]) via the image's deterministic proxy id. Null when there is
/// no image to offer.
String? queueImageUrl(Object? image, String? webBase) {
  if (image is! Map) return null;
  final path = '${image['path'] ?? ''}';
  if (image['remotely_accessible'] == true && path.startsWith('http')) {
    return path;
  }
  final proxyId = '${image['proxy_id'] ?? ''}';
  if (proxyId.isEmpty || webBase == null) return null;
  return '$webBase/imageproxy/$proxyId?size=512&fmt=jpg';
}

/// Request/response bookkeeping for one open connection, plus the events
/// Music Assistant pushes at every authenticated client.
///
/// Large results arrive chunked ({partial: true} frames carrying list
/// slices under the request's id, then a final frame with the tail);
/// [send] hands back the reassembled whole.
class MaSession {
  MaSession(this._socket, {this.onEvent, this.onDone}) {
    _socket.listen(
      (raw) {
        final decoded = jsonDecode('$raw');
        if (decoded is! Map) return;
        final message = decoded.cast<String, Object?>();
        if (message.containsKey('event')) {
          onEvent?.call(
            '${message['event']}',
            '${message['object_id'] ?? ''}',
            message['data'],
          );
          return;
        }
        final id = message['message_id'];
        if (id == null) {
          // The opening frame, which carries the server's identity.
          if (serverInfo.isEmpty) serverInfo = message;
          return;
        }
        if (message['partial'] == true) {
          final part = message['result'];
          _partials['$id'] = [
            ...?_partials['$id'],
            ...(part is List ? part : [part]),
          ];
          return;
        }
        final completer = _pending.remove('$id');
        final held = _partials.remove('$id');
        if (completer == null || completer.isCompleted) return;
        if (message.containsKey('error_code')) {
          completer.completeError(
            MusicAssistantError(
              '${message['details'] ?? message['error_code']}',
            ),
          );
        } else {
          final result = message['result'];
          completer.complete(
            held == null
                ? result
                : [...held, ...(result is List ? result : const [])],
          );
        }
      },
      onDone: () {
        for (final completer in _pending.values) {
          if (!completer.isCompleted) {
            completer.completeError(
              const MusicAssistantError('the server closed the connection'),
            );
          }
        }
        _pending.clear();
        _partials.clear();
        onDone?.call();
      },
      onError: (Object _) {},
    );
  }

  final WebSocket _socket;

  /// A pushed event: name, the id of what it concerns, and its payload.
  final void Function(String event, String objectId, Object? data)? onEvent;

  /// The connection ended, however it ended (pending requests have already
  /// been failed).
  final void Function()? onDone;

  /// The server's opening frame (name, versions), once it has arrived.
  Map<String, Object?> serverInfo = const {};

  final _pending = <String, Completer<Object?>>{};
  final _partials = <String, List<Object?>>{};
  var _nextId = 0;

  Future<Object?> send(
    String command,
    Map<String, Object?> args, {
    Duration timeout = const Duration(seconds: 20),
  }) {
    final id = '${++_nextId}';
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _socket.add(
      jsonEncode({
        'message_id': id,
        'command': command,
        if (args.isNotEmpty) 'args': args,
      }),
    );
    return completer.future.timeout(timeout);
  }
}

class MusicAssistantResult {
  const MusicAssistantResult.success(this.result, this.serverInfo)
    : error = null;
  const MusicAssistantResult.failure(this.error)
    : result = null,
      serverInfo = const {};

  final Object? result;
  final Map<String, Object?> serverInfo;
  final String? error;

  bool get ok => error == null;
}

class MusicAssistantError implements Exception {
  const MusicAssistantError(this.message);

  final String message;

  @override
  String toString() => message;
}
