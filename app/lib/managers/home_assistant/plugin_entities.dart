import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Selected entity states for plugins. Credentials stay inside the HA manager.
class HaPluginEntities {
  HaPluginEntities({
    required this.baseUrl,
    required this.token,
    required this.emit,
  });

  final String Function() baseUrl;
  final String Function() token;
  final void Function(String owner, String entityId, Map<String, Object?> state)
  emit;
  final _owners = <String, Set<String>>{};
  final _states = <String, Map<String, Object?>>{};
  WebSocketChannel? _socket;
  Timer? _retry;
  Timer? _deadline;
  Timer? _heartbeat;
  int _generation = 0;
  int _retrySeconds = 1;
  bool _closed = false;
  bool _ready = false;
  bool _initial = true;

  static bool validId(Object? id) =>
      id is String &&
      id.length <= 255 &&
      RegExp(r'^[a-z0-9_]+\.[a-z0-9_]+$').hasMatch(id);

  static Map<String, Object?> unavailable(String id, String status) => {
    'entityId': id,
    'status': status,
    'state': null,
    'attributes': <String, Object?>{},
    'lastChanged': null,
    'lastUpdated': null,
  };

  /// The same detached, bounded shape is used for reads and live events.
  static Map<String, Object?> snapshot(String id, Map raw) {
    final state = raw['state'];
    final result = <String, Object?>{
      'entityId': id,
      'status': state == 'unknown' || state == 'unavailable'
          ? state
          : 'available',
      'state': state is String ? state : null,
      'attributes': raw['attributes'] is Map
          ? raw['attributes']
          : <String, Object?>{},
      'lastChanged': raw['last_changed'] is String ? raw['last_changed'] : null,
      'lastUpdated': raw['last_updated'] is String ? raw['last_updated'] : null,
    };
    final encoded = jsonEncode(result);
    if (utf8.encode(encoded).length > 30000) {
      return unavailable(id, 'too_large');
    }
    return (jsonDecode(encoded) as Map).cast<String, Object?>();
  }

  Future<Map<String, Object?>> read(String id) async {
    final origin = baseUrl();
    final credential = token();
    if (origin.isEmpty || credential.isEmpty) {
      return unavailable(id, 'not_configured');
    }
    try {
      final response = await http
          .get(
            Uri.parse('$origin/api/states/$id'),
            headers: {'Authorization': 'Bearer $credential'},
          )
          .timeout(const Duration(seconds: 5));
      if (_closed || origin != baseUrl() || credential != token()) {
        return unavailable(id, 'disconnected');
      }
      if (response.statusCode == 404) return unavailable(id, 'missing');
      if (response.statusCode != 200) return unavailable(id, 'disconnected');
      final raw = jsonDecode(response.body);
      if (raw is! Map || raw['entity_id'] != id) {
        return unavailable(id, 'disconnected');
      }
      return snapshot(id, raw);
    } catch (_) {
      return unavailable(id, 'disconnected');
    }
  }

  void watch(String owner, String id) {
    if (_closed) return;
    final ids = _owners.putIfAbsent(owner, () => <String>{});
    if (ids.contains(id)) return;
    if (ids.length >= 16) {
      throw StateError('At most 16 entity subscriptions per plugin');
    }
    final existing = _owners.values.any((set) => set.contains(id));
    ids.add(id);
    if (existing && _ready) {
      emit(owner, id, _states[id] ?? unavailable(id, 'missing'));
    } else {
      restart();
    }
  }

  void unwatch(String owner, [String? id]) {
    final ids = _owners[owner];
    if (ids == null) return;
    if (id == null) {
      _owners.remove(owner);
    } else {
      ids.remove(id);
      if (ids.isEmpty) _owners.remove(owner);
    }
    restart();
  }

  void _publish(String id, Map<String, Object?> value) {
    _states[id] = value;
    for (final entry in _owners.entries) {
      if (entry.value.contains(id)) emit(entry.key, id, value);
    }
  }

  Set<String> get _ids => _owners.values.expand((ids) => ids).toSet();

  void _cancelSocket() {
    _generation++;
    _retry?.cancel();
    _deadline?.cancel();
    _heartbeat?.cancel();
    final socket = _socket;
    _socket = null;
    if (socket != null) unawaited(socket.sink.close().catchError((_) {}));
    _ready = false;
    _states.clear();
  }

  void restart() {
    if (_closed) return;
    _cancelSocket();
    _retrySeconds = 1;
    if (_ids.isEmpty) return;
    _retry = Timer(const Duration(milliseconds: 100), _connect);
  }

  void _connect() {
    if (_closed || _ids.isEmpty) return;
    if (baseUrl().isEmpty || token().isEmpty) {
      for (final id in _ids) {
        _publish(id, unavailable(id, 'not_configured'));
      }
      return;
    }
    final generation = ++_generation;
    final ids = _ids;
    _initial = true;
    for (final id in ids) {
      _publish(id, unavailable(id, 'connecting'));
    }
    void lost() {
      if (_closed || generation != _generation) return;
      _cancelSocket();
      for (final id in _ids) {
        _publish(id, unavailable(id, 'disconnected'));
      }
      _retry = Timer(Duration(seconds: _retrySeconds), _connect);
      _retrySeconds = (_retrySeconds * 2).clamp(1, 30);
    }

    try {
      final uri = Uri.parse(baseUrl()).replace(
        scheme: baseUrl().startsWith('https:') ? 'wss' : 'ws',
        path: '/api/websocket',
      );
      final socket = _socket = WebSocketChannel.connect(uri);
      unawaited(socket.ready.then<void>((_) {}, onError: (Object _) => lost()));
      void send(Map<String, Object?> value) =>
          socket.sink.add(jsonEncode(value));
      _deadline = Timer(const Duration(seconds: 8), lost);
      var pingId = 2;
      socket.stream.listen(
        (raw) {
          if (_closed || generation != _generation) return;
          try {
            final frame = jsonDecode(raw as String) as Map;
            switch (frame['type']) {
              case 'auth_required':
                send({'type': 'auth', 'access_token': token()});
              case 'auth_ok':
                send({
                  'id': 1,
                  'type': 'subscribe_entities',
                  'entity_ids': ids.toList(),
                });
              case 'auth_invalid':
                lost();
              case 'result':
                if (frame['id'] != 1) return;
                if (frame['success'] != true) {
                  lost();
                  return;
                }
                _deadline?.cancel();
                _ready = true;
                _retrySeconds = 1;
                _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
                  send({'id': pingId++, 'type': 'ping'});
                  _deadline = Timer(const Duration(seconds: 10), lost);
                });
              case 'pong':
                _deadline?.cancel();
              case 'event':
                if (frame['id'] != 1 || frame['event'] is! Map) return;
                final event = frame['event'] as Map;
                final updates = applyEntityUpdates(_states, event, ids);
                for (final entry in updates.entries) {
                  _publish(entry.key, entry.value);
                }
                if (_initial) {
                  _initial = false;
                  for (final id in ids.difference(updates.keys.toSet())) {
                    _publish(id, unavailable(id, 'missing'));
                  }
                }
            }
          } catch (_) {
            lost();
          }
        },
        onError: (Object _) => lost(),
        onDone: lost,
        cancelOnError: true,
      );
    } catch (_) {
      lost();
    }
  }

  void dispose() {
    _closed = true;
    _cancelSocket();
    _owners.clear();
  }
}

/// Merge HA's compressed entity updates, including deleted attributes.
Map<String, Map<String, Object?>> applyEntityUpdates(
  Map<String, Map<String, Object?>> previous,
  Map event,
  Set<String> ids,
) {
  final result = <String, Map<String, Object?>>{};
  String? timestamp(Object? value) => value is num && value.isFinite
      ? DateTime.fromMillisecondsSinceEpoch(
          (value * 1000).round(),
          isUtc: true,
        ).toIso8601String()
      : null;
  final added = event['a'];
  if (added is Map) {
    for (final id in ids) {
      final raw = added[id];
      if (raw is! Map) continue;
      result[id] = HaPluginEntities.snapshot(id, {
        'state': raw['s'],
        'attributes': raw['a'],
        'last_changed': timestamp(raw['lc']),
        'last_updated': timestamp(raw['lu'] ?? raw['lc']),
      });
    }
  }
  final changed = event['c'];
  if (changed is Map) {
    for (final id in ids) {
      final diff = changed[id];
      final old = result[id] ?? previous[id];
      if (diff is! Map || old == null) continue;
      if (old['status'] == 'too_large') {
        result[id] = HaPluginEntities.unavailable(id, 'too_large');
        continue;
      }
      final plus = diff['+'] is Map ? diff['+'] as Map : const {};
      final minus = diff['-'] is Map ? diff['-'] as Map : const {};
      final attributes = Map<String, Object?>.from(
        old['attributes'] as Map? ?? const {},
      );
      if (plus['a'] is Map) {
        attributes.addAll(Map<String, Object?>.from(plus['a'] as Map));
      }
      if (minus['a'] is List) {
        for (final key in minus['a']) {
          attributes.remove(key);
        }
      }
      result[id] = HaPluginEntities.snapshot(id, {
        'state': plus['s'] ?? old['state'],
        'attributes': attributes,
        'last_changed': timestamp(plus['lc']) ?? old['lastChanged'],
        'last_updated':
            timestamp(plus['lc'] ?? plus['lu']) ?? old['lastUpdated'],
      });
    }
  }
  final removed = event['r'];
  if (removed is List) {
    for (final id in ids.intersection(removed.whereType<String>().toSet())) {
      result[id] = HaPluginEntities.unavailable(id, 'missing');
    }
  }
  return result;
}
