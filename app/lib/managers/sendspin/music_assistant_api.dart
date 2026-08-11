import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
String? musicAssistantWebUrl(String raw) {
  final trimmed = raw.trim().replaceAll(RegExp(r'/+$'), '');
  if (trimmed.isEmpty) return null;
  final withScheme = trimmed.startsWith('http') || trimmed.startsWith('ws')
      ? trimmed
      : 'https://$trimmed';
  final uri = Uri.tryParse(withScheme);
  if (uri == null || !uri.hasAuthority) return null;
  return uri
      .replace(
        scheme: switch (uri.scheme) {
          'ws' => 'http',
          'wss' => 'https',
          final other => other,
        },
      )
      .toString();
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
  static HttpClient _client() =>
      HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..badCertificateCallback = (_, _, _) => true;

  /// `wss://host:8095/ws` from the address as typed, however it was typed.
  Uri get _socketUri {
    final trimmed = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final withScheme =
        trimmed.startsWith('http') || trimmed.startsWith('ws')
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
    final client = _client();
    WebSocket? socket;
    try {
      socket = await WebSocket.connect(
        _socketUri.toString(),
        customClient: client,
      ).timeout(timeout);
      final pending = <String, Completer<Object?>>{};
      Map<String, Object?>? serverInfo;
      final closed = Completer<void>();
      socket.listen(
        (raw) {
          final decoded = jsonDecode('$raw');
          if (decoded is! Map) return;
          final message = decoded.cast<String, Object?>();
          final id = message['message_id'];
          if (id == null) {
            // The opening frame, which carries the server's identity.
            serverInfo ??= message;
            return;
          }
          final completer = pending.remove('$id');
          if (completer == null || completer.isCompleted) return;
          if (message.containsKey('error_code')) {
            completer.completeError(
              MusicAssistantError(
                '${message['details'] ?? message['error_code']}',
              ),
            );
          } else {
            completer.complete(message['result']);
          }
        },
        onError: (Object error) {
          if (!closed.isCompleted) closed.completeError(error);
        },
        onDone: () {
          if (!closed.isCompleted) closed.complete();
          for (final completer in pending.values) {
            if (!completer.isCompleted) {
              completer.completeError(
                const MusicAssistantError('the server closed the connection'),
              );
            }
          }
          pending.clear();
        },
      );

      var nextId = 0;
      Future<Object?> send(String name, Map<String, Object?> arguments) {
        final id = '${++nextId}';
        final completer = Completer<Object?>();
        pending[id] = completer;
        socket!.add(jsonEncode({
          'message_id': id,
          'command': name,
          if (arguments.isNotEmpty) 'args': arguments,
        }));
        return completer.future.timeout(timeout);
      }

      await send('auth', {'token': token});
      final result = command == 'auth' ? null : await send(command, args);
      return MusicAssistantResult.success(result, serverInfo ?? const {});
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
    final uri = _socketUri;
    return '${uri.host}:${uri.port}';
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
    final client = _client();
    WebSocket? socket;
    try {
      socket = await WebSocket.connect(
        _socketUri.toString(),
        customClient: client,
      ).timeout(const Duration(seconds: 15));
      final session = _Session(socket);
      await session.send('auth', {'token': token});
      final queue = await session.send('player_queues/get_active_queue', {
        'player_id': playerId,
      });
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
      final duration =
          (item['duration'] as num?) ?? (media['duration'] as num?);
      final elapsed = queue['elapsed_time'] as num?;
      return {
        'state': '${queue['state'] ?? ''}',
        'title': title,
        if (artist.isNotEmpty) 'artist': artist,
        if (album.isNotEmpty) 'album': album,
        if (duration != null) 'durationMs': (duration * 1000).round(),
        'positionMs': ((elapsed ?? 0) * 1000).round(),
        ...switch (_imageUrl(item['image'])) {
          final url? => {'artworkUrl': url},
          null => const <String, Object?>{},
        },
      };
    } catch (_) {
      return null;
    } finally {
      await socket?.close();
      client.close(force: true);
    }
  }

  /// A fetchable URL for a queue item's image: the path itself when it is
  /// a plain web URL, otherwise the server's image proxy via the image's
  /// deterministic proxy id. Null when there is no image to offer.
  String? _imageUrl(Object? image) {
    if (image is! Map) return null;
    final path = '${image['path'] ?? ''}';
    if (image['remotely_accessible'] == true && path.startsWith('http')) {
      return path;
    }
    final proxyId = '${image['proxy_id'] ?? ''}';
    final base = musicAssistantWebUrl(baseUrl);
    if (proxyId.isEmpty || base == null) return null;
    return '$base/imageproxy/$proxyId?size=512&fmt=jpg';
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
    final client = _client();
    WebSocket? socket;
    try {
      socket = await WebSocket.connect(
        _socketUri.toString(),
        customClient: client,
      ).timeout(const Duration(seconds: 15));
      final session = _Session(socket);
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
      final result = await session.send(
        'metadata/get_track_lyrics',
        {'track': track},
        timeout: const Duration(seconds: 45),
      );
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

/// Request/response bookkeeping for one open connection.
class _Session {
  _Session(this._socket) {
    _socket.listen(
      (raw) {
        final decoded = jsonDecode('$raw');
        if (decoded is! Map) return;
        final message = decoded.cast<String, Object?>();
        final id = message['message_id'];
        if (id == null) return;
        final completer = _pending.remove('$id');
        if (completer == null || completer.isCompleted) return;
        if (message.containsKey('error_code')) {
          completer.completeError(
            MusicAssistantError('${message['details'] ?? message['error_code']}'),
          );
        } else {
          completer.complete(message['result']);
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
      },
      onError: (Object _) {},
    );
  }

  final WebSocket _socket;
  final _pending = <String, Completer<Object?>>{};
  var _nextId = 0;

  Future<Object?> send(
    String command,
    Map<String, Object?> args, {
    Duration timeout = const Duration(seconds: 20),
  }) {
    final id = '${++_nextId}';
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _socket.add(jsonEncode({
      'message_id': id,
      'command': command,
      if (args.isNotEmpty) 'args': args,
    }));
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
