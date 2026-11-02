import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../core/logging.dart';
import 'music_assistant_api.dart';

/// Music Assistant commands and events for plugins (the SDK's `ma`
/// capability).
///
/// Every plugin shares one connection, signed in with the kiosk's Music
/// Assistant token, which never reaches a plugin. A plugin sends a command
/// and its args, and the app numbers the message.
///
/// Music Assistant has no subscribe command: it pushes every event to every
/// signed-in client. A plugin's subscription is a filter kept here, by
/// event name and optionally by object id, so a plugin hears only what it
/// asked for.
///
/// The connection opens on the first call and closes after [idleClose]
/// with nothing in flight and no subscriptions. While subscriptions exist
/// it reconnects with backoff.
class MaPluginSocket {
  MaPluginSocket({
    required this.baseUrl,
    required this.token,
    required this.log,
    this.idleClose = const Duration(seconds: 60),
    this.callTimeout = const Duration(seconds: 25),
    this.maxResult = maxResultBytes,
    this.locale,
  });

  /// The Music Assistant address and token from the Sendspin settings,
  /// read on every connect so a change is picked up.
  final String Function() baseUrl;
  final String Function() token;
  final Logger log;
  final Duration idleClose;
  final Duration callTimeout;

  /// The largest answer handed back. Plugins get [maxResultBytes]. Zero
  /// hands back any size without measuring it: the Music Library's own
  /// connection, whose album and playlist listings run large and would
  /// otherwise be encoded once more on the UI thread just to be counted.
  final int maxResult;

  /// The Music Assistant locale declared when signing in, so the server
  /// answers with names in that language. Read on every connect. Null or
  /// empty leaves the server's English.
  final String Function()? locale;

  /// Delivers a subscription's events and status changes to its plugin
  /// session: `{type: event, event, objectId, data}`, `{type: too_large,
  /// event, objectId}`, `{type: disconnected}` and `{type: reconnected}`.
  void Function(String owner, String key, Map<String, Object?> payload)? emit;

  static const maxSubscriptions = 16;
  static const maxEventNames = 16;
  static const maxArgsBytes = 32768;
  static const maxResultBytes = 524288;
  static const maxEventBytes = 65536;

  static final _keyPattern = RegExp(r'^[A-Za-z0-9_.-]{1,64}$');
  static final _commandPattern = RegExp(r'^[a-z0-9_]+(?:/[a-z0-9_]+)*$');
  static final _eventPattern = RegExp(r'^[a-z0-9_]{1,64}$');

  static bool validKey(Object? key) =>
      key is String && _keyPattern.hasMatch(key);

  /// Playback, players, the library and metadata. Server configuration,
  /// sign-in, users, tokens and the rest of the admin surface stay off
  /// this connection, whatever the token's role allows.
  static bool allowedCommand(String command) {
    if (command.length > 128 || !_commandPattern.hasMatch(command)) {
      return false;
    }
    // In allowed namespaces, but they change the server's configuration.
    if (const {
      'players/remove',
      'players/create_group_player',
      'players/remove_group_player',
      'metadata/set_default_preferred_language',
    }.contains(command)) {
      return false;
    }
    return command == 'info' ||
        command == 'providers' ||
        command == 'providers/manifests' ||
        command == 'providers/icon' ||
        const [
          'players/',
          'player_queues/',
          'music/',
          'metadata/',
        ].any(command.startsWith);
  }

  WebSocket? _socket;
  HttpClient? _client;
  MaSession? _session;
  Future<String?>? _connecting;
  bool _closed = false;
  int _generation = 0;
  int _retrySeconds = 1;
  int _inFlight = 0;
  Timer? _retry;
  Timer? _idle;

  /// The server's opening frame on the current connection: server_id,
  /// server_version, schema_version, name and the rest.
  Map<String, Object?> get serverInfo => _session?.serverInfo ?? const {};

  /// The preferences of the token's user, as sign-in last handed them
  /// over: what Music Assistant's own pages saved, the Discover layout
  /// among them. Read again on every connect. Never handed to plugins.
  Map<String, Object?> get userPreferences => _preferences;
  Map<String, Object?> _preferences = const {};

  /// The owner of each call in flight, so a session's end fails them at
  /// once.
  final _calls = <Completer<Map<String, Object?>>, String>{};
  final _subs = <String, _Subscription>{};

  @visibleForTesting
  bool get connected => _session != null;

  @visibleForTesting
  int get subscriptionCount => _subs.length;

  /// Run [command] with [args] for [owner] and answer `{ok: true, result}`
  /// or `{ok: false, error: {code, message}}`.
  Future<Map<String, Object?>> call(
    String owner,
    String command,
    Map<String, Object?> args,
  ) async {
    if (!allowedCommand(command)) {
      return _error('not_allowed', '$command is not available to plugins');
    }
    try {
      if (_bytes(args) > maxArgsBytes) {
        return _error('too_large', 'The args are larger than 32 KB');
      }
    } catch (_) {
      return _error('invalid_message', 'The args are not JSON');
    }
    _inFlight++;
    final done = Completer<Map<String, Object?>>();
    _calls[done] = owner;
    try {
      final error = await _ensureConnected();
      if (error != null) return _error(error);
      final session = _session;
      if (session == null) return _error('connection_lost');
      unawaited(
        session
            .send(command, args, timeout: callTimeout)
            .then<void>(
              (result) {
                if (done.isCompleted) return;
                done.complete(
                  maxResult > 0 && _bytes({'result': result}) > maxResult
                      ? _error('too_large', 'The result is larger than 512 KB')
                      : {'ok': true, 'result': result},
                );
              },
              onError: (Object e) {
                if (done.isCompleted) return;
                done.complete(switch (e) {
                  TimeoutException() => _error('timeout'),
                  MusicAssistantError(code: final code?) => _error(
                    '$code',
                    e.message,
                  ),
                  _ => _error('connection_lost'),
                });
              },
            ),
      );
      return await done.future;
    } finally {
      _calls.remove(done);
      _inFlight--;
      _scheduleIdle();
    }
  }

  /// Hear the events [filter] names under [key], for [owner]. The filter
  /// is `{events: [names], objectId}`, the object id being optional.
  /// Answers like [call] once the connection is up. Events then arrive
  /// through [emit] until [unsubscribe].
  Future<Map<String, Object?>> subscribe(
    String owner,
    String key,
    Map<String, Object?> filter,
  ) async {
    if (!validKey(key)) return _error('invalid_key');
    final events = filter['events'];
    final objectId = filter['objectId'];
    if (events is! List ||
        events.isEmpty ||
        events.length > maxEventNames ||
        !events.every((e) => e is String && _eventPattern.hasMatch(e))) {
      return _error(
        'invalid_message',
        'events lists 1 to 16 Music Assistant event names',
      );
    }
    if (objectId != null && (objectId is! String || objectId.length > 256)) {
      return _error('invalid_message', 'objectId must be a string');
    }
    if (filter.keys.any((k) => k != 'events' && k != 'objectId')) {
      return _error('invalid_message', 'The filter takes events and objectId');
    }
    final name = _name(owner, key);
    if (_subs.containsKey(name)) return _error('in_use');
    if (_subs.values.where((s) => s.owner == owner).length >=
        maxSubscriptions) {
      return _error('too_many', 'At most 16 subscriptions per plugin');
    }
    final sub = _Subscription(owner, key, {
      for (final e in events) e as String,
    }, objectId as String?);
    _subs[name] = sub;
    final error = await _ensureConnected();
    if (!identical(_subs[name], sub)) return _error('unsubscribed');
    if (error != null) {
      _subs.remove(name);
      _scheduleIdle();
      return _error(error);
    }
    sub.confirmed = true;
    return {'ok': true};
  }

  /// End [owner]'s subscription [key]. Unknown keys are ignored.
  void unsubscribe(String owner, String key) {
    _subs.remove(_name(owner, key));
    _scheduleIdle();
  }

  /// End everything [owner] holds: its session ended.
  void release(String owner) {
    _subs.removeWhere((_, s) => s.owner == owner);
    for (final entry in _calls.entries.toList()) {
      if (entry.value == owner && !entry.key.isCompleted) {
        entry.key.complete(_error('session_ended'));
      }
    }
    _scheduleIdle();
  }

  /// The address or token changed: start over with the new one.
  void restart() {
    if (_closed) return;
    _drop('settings_changed');
    _retrySeconds = 1;
    if (_subs.isNotEmpty) _reconnectSoon(Duration.zero);
  }

  void dispose() {
    _closed = true;
    _retry?.cancel();
    _idle?.cancel();
    _drop('disposed');
    _subs.clear();
    emit = null;
  }

  Future<String?> _ensureConnected() {
    _idle?.cancel();
    if (_closed) return Future.value('not_configured');
    if (_session != null) return Future.value(null);
    return _connecting ??= _connect().whenComplete(() => _connecting = null);
  }

  Future<String?> _connect() async {
    final base = baseUrl().trim();
    final key = token().trim();
    if (base.isEmpty || key.isEmpty) return 'not_configured';
    final generation = ++_generation;
    final client = MusicAssistantApi.newHttpClient();
    final uri = MusicAssistantApi(baseUrl: base, token: key).socketUri;
    String? error;
    try {
      final socket = await WebSocket.connect(
        uri.toString(),
        customClient: client,
      ).timeout(const Duration(seconds: 10));
      if (generation != _generation) {
        unawaited(socket.close().catchError((_) {}));
        client.close(force: true);
        return 'connection_lost';
      }
      socket.pingInterval = const Duration(seconds: 20);
      final session = MaSession(
        socket,
        onEvent: (event, objectId, data) {
          if (generation == _generation) _onEvent(event, objectId, data);
        },
        onDone: () {
          if (generation == _generation) _lost();
        },
      );
      _socket = socket;
      _client = client;
      try {
        final lang = locale?.call() ?? '';
        final auth = await session.send('auth', {
          'token': key,
          if (lang.isNotEmpty) 'locale': lang,
        }, timeout: callTimeout);
        final user = auth is Map ? auth['user'] : null;
        final preferences = user is Map ? user['preferences'] : null;
        if (generation == _generation) {
          _preferences = preferences is Map
              ? preferences.cast<String, Object?>()
              : const {};
        }
      } on MusicAssistantError catch (e) {
        // A refusal carries Music Assistant's error code. A closed
        // connection does not.
        error = e.code != null ? 'auth_invalid' : 'unreachable';
      }
      // Closed while signing in: the retry below tries again.
      if (generation != _generation) {
        error = 'connection_lost';
      } else if (error == null) {
        _session = session;
        _retrySeconds = 1;
      } else {
        _drop(error);
      }
    } catch (_) {
      if (generation == _generation) _drop('unreachable');
      client.close(force: true);
      error = 'unreachable';
    }
    if (error == null) {
      log.info('plugins', 'Music Assistant connection for plugins open');
      for (final sub in _subs.values.where((s) => s.confirmed && s.down)) {
        sub.down = false;
        emit?.call(sub.owner, sub.key, {'type': 'reconnected'});
      }
    } else {
      log.warn('plugins', 'Music Assistant connection for plugins: $error');
      if (_subs.values.any((s) => s.confirmed)) _reconnectSoon();
    }
    return error;
  }

  void _onEvent(String event, String objectId, Object? data) {
    if (_subs.isEmpty) return;
    Map<String, Object?>? payload;
    for (final sub in _subs.values.toList()) {
      if (!sub.confirmed || !sub.events.contains(event)) continue;
      if (sub.objectId != null && sub.objectId != objectId) continue;
      payload ??= () {
        final full = <String, Object?>{
          'type': 'event',
          'event': event,
          'objectId': objectId,
          'data': data,
        };
        return _bytes(full) > maxEventBytes
            ? <String, Object?>{
                'type': 'too_large',
                'event': event,
                'objectId': objectId,
              }
            : full;
      }();
      emit?.call(sub.owner, sub.key, payload);
    }
  }

  /// The connection went down on its own.
  void _lost() {
    final retry = _session != null && _subs.values.any((s) => s.confirmed);
    _drop('connection_lost');
    if (retry) _reconnectSoon();
  }

  /// Close the connection. Calls in flight fail with [reason], and every
  /// confirmed subscription hears it went down.
  void _drop(String reason) {
    _generation++;
    final wasReady = _session != null;
    _session = null;
    final socket = _socket;
    final client = _client;
    _socket = null;
    _client = null;
    if (socket != null) unawaited(socket.close().catchError((_) {}));
    client?.close(force: true);
    for (final done in _calls.keys.toList()) {
      if (!done.isCompleted) done.complete(_error(reason));
    }
    if (!wasReady) return;
    for (final sub in _subs.values) {
      if (sub.confirmed && !sub.down) {
        sub.down = true;
        emit?.call(sub.owner, sub.key, {'type': 'disconnected'});
      }
    }
    log.info(
      'plugins',
      'Music Assistant connection for plugins closed: $reason',
    );
  }

  void _reconnectSoon([Duration? delay]) {
    if (_closed) return;
    _retry?.cancel();
    final wait = delay ?? Duration(seconds: _retrySeconds);
    _retrySeconds = (_retrySeconds * 2).clamp(1, 30);
    _retry = Timer(wait, () {
      if (_closed ||
          _session != null ||
          !_subs.values.any((s) => s.confirmed)) {
        return;
      }
      unawaited(_ensureConnected());
    });
  }

  void _scheduleIdle() {
    _idle?.cancel();
    if (_closed || _subs.isNotEmpty || _inFlight > 0) return;
    _idle = Timer(idleClose, () {
      if (_subs.isEmpty && _inFlight == 0) _drop('idle');
    });
  }

  static String _name(String owner, String key) => '$owner\n$key';

  static int _bytes(Object? value) => utf8.encode(jsonEncode(value)).length;

  static Map<String, Object?> _error(String code, [String message = '']) => {
    'ok': false,
    'error': {'code': code, 'message': message},
  };
}

class _Subscription {
  _Subscription(this.owner, this.key, this.events, this.objectId);

  final String owner;
  final String key;
  final Set<String> events;
  final String? objectId;

  /// Answered once, so a reconnect tells the plugin it is back.
  bool confirmed = false;

  /// The plugin heard the connection go down and has not heard it return.
  bool down = false;
}
