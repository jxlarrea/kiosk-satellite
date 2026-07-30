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
