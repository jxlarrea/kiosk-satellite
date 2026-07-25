import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
