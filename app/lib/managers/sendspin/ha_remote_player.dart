import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random, min;

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../core/logging.dart';
import 'remote_player.dart';

/// The Now Playing surfaces following a Home Assistant media_player
/// entity: any player Home Assistant can drive, treated alike.
///
/// One websocket to Home Assistant carries everything: `subscribe_entities`
/// for the one entity (the full state on subscribe, then diffs as the
/// player changes) and `call_service` for the transport, shuffle, seek and
/// volume. Track, artwork, position and the supported buttons all come
/// from the entity's attributes, so a Sonos, a Chromecast and a receiver
/// look the same here; nothing is special-cased per integration.
///
/// Position is the entity's last reported position plus the wall time
/// since Home Assistant stamped it, which the integrations refresh on
/// every transport event. The surfaces extrapolate from 'receivedAt' the
/// way they do for every source.
class HaRemotePlayer implements RemotePlayer {
  HaRemotePlayer({
    required this.baseUrl,
    required this.token,
    required this.entityId,
    required this.onSnapshot,
    required this.log,
  });

  static const _name = 'sendspin';

  /// Home Assistant's media_player supported_features bits.
  static const featurePause = 1;
  static const featureSeek = 2;
  static const featureVolumeSet = 4;
  static const featurePrevious = 16;
  static const featureNext = 32;
  static const featureStop = 4096;
  static const featurePlay = 16384;
  static const featureShuffle = 32768;

  final String baseUrl;
  final String token;
  final String entityId;
  final void Function(Map<String, Object?>? snapshot) onSnapshot;
  final Logger log;

  @override
  String get playerId => entityId;

  @override
  bool queueEmpty = false;

  /// Home Assistant's media_player model has no queue of its own, and
  /// no library.
  @override
  bool get hasQueue => false;

  @override
  bool get hasFavorites => false;

  @override
  Future<RemoteQueue?> fetchQueue() async => null;

  @override
  Future<bool> playQueueItem(String id) async => false;

  @override
  bool get lyricsSynced => true;

  bool _stopped = false;
  WebSocket? _socket;
  Timer? _retry;
  int _attempts = 0;
  int _nextId = 1;
  final _pending = <int, Completer<Object?>>{};

  /// The entity's state and attributes as last merged: a diff carries only
  /// what changed, so the whole is kept here.
  String _state = '';
  Map<String, Object?> _attributes = const {};
  bool _sawPlayback = false;
  Map<String, Object?>? _snapshot;

  @override
  void start() {
    unawaited(_connect());
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    _retry?.cancel();
    await _close();
  }

  @override
  void reveal() {
    _sawPlayback = true;
    _publish();
  }

  @override
  Future<void> refresh() async {
    // The subscription pushes every change; nothing to poll for.
    _publish();
  }

  @override
  Future<bool> control(String command) async {
    final service = switch (command) {
      'play' => 'media_play',
      'pause' => 'media_pause',
      'stop' => 'media_stop',
      'next' => 'media_next_track',
      'previous' => 'media_previous_track',
      _ => null,
    };
    if (service == null) return false;
    return _callService(service);
  }

  @override
  Future<bool> setShuffle(bool on) =>
      _callService('shuffle_set', {'shuffle': on});

  @override
  Future<bool> seek(int positionMs) =>
      _callService('media_seek', {'seek_position': positionMs / 1000});

  @override
  Future<bool> setVolume(int percent) => _callService('volume_set', {
    'volume_level': (percent.clamp(0, 100)) / 100,
  });

  Future<bool> _callService(
    String service, [
    Map<String, Object?> data = const {},
  ]) async {
    try {
      await _send({
        'type': 'call_service',
        'domain': 'media_player',
        'service': service,
        'service_data': data,
        'target': {'entity_id': entityId},
      });
      return true;
    } catch (e) {
      log.warn(_name, 'Home Assistant $service failed: $e');
      return false;
    }
  }

  Future<Object?> _send(Map<String, Object?> command) {
    final socket = _socket;
    if (socket == null) return Future.error(StateError('not connected'));
    final id = _nextId++;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    socket.add(jsonEncode({'id': id, ...command}));
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('Home Assistant did not answer');
      },
    );
  }

  Future<void> _connect() async {
    if (_stopped) return;
    final wsBase = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    try {
      final socket = await WebSocket.connect(
        '$wsBase/api/websocket',
      ).timeout(const Duration(seconds: 15));
      if (_stopped) {
        await socket.close();
        return;
      }
      socket.pingInterval = const Duration(seconds: 20);
      _socket = socket;
      socket.listen(
        (raw) => handleFrame(raw is String ? raw : '$raw'),
        onError: (Object e) => log.warn(_name, 'Home Assistant socket: $e'),
        onDone: _onDone,
        cancelOnError: true,
      );
    } catch (e) {
      log.warn(_name, 'Home Assistant follower connect failed: $e');
      await _close();
      _scheduleRetry();
    }
  }

  /// One websocket frame from Home Assistant: the auth handshake, the
  /// subscription's state events and the answers to sent commands.
  @visibleForTesting
  void handleFrame(String raw) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (msg['type']) {
      case 'auth_required':
        _socket?.add(jsonEncode({'type': 'auth', 'access_token': token}));
      case 'auth_ok':
        _attempts = 0;
        log.info(_name, 'following Home Assistant player $entityId');
        unawaited(
          _send({
            'type': 'subscribe_entities',
            'entity_ids': [entityId],
          }).catchError((Object e) {
            log.warn(_name, 'Home Assistant subscribe failed: $e');
            return null;
          }),
        );
      case 'auth_invalid':
        log.warn(_name, 'Home Assistant follower rejected: bad token');
        unawaited(_close());
        _emit(null);
      case 'result':
        final id = msg['id'];
        final completer = id is int ? _pending.remove(id) : null;
        if (completer == null) return;
        if (msg['success'] == true) {
          completer.complete(msg['result']);
        } else {
          final error = msg['error'];
          completer.completeError(
            StateError(error is Map ? '${error['message']}' : '$error'),
          );
        }
      case 'event':
        handleEntityEvent(msg['event']);
    }
  }

  /// The compressed `subscribe_entities` payload: `a` carries the whole
  /// state once, `c` a diff with `+` for what changed and `-` for
  /// attributes that went away.
  @visibleForTesting
  void handleEntityEvent(Object? event) {
    if (event is! Map) return;
    final added = event['a'];
    if (added is Map && added[entityId] is Map) {
      final value = added[entityId] as Map;
      _state = '${value['s'] ?? ''}';
      _attributes = value['a'] is Map
          ? (value['a'] as Map).cast<String, Object?>()
          : const {};
    }
    final changed = event['c'];
    if (changed is Map && changed[entityId] is Map) {
      final diff = changed[entityId] as Map;
      final plus = diff['+'];
      final minus = diff['-'];
      var attrs = Map<String, Object?>.of(_attributes);
      if (minus is Map && minus['a'] is List) {
        for (final key in minus['a'] as List) {
          attrs.remove('$key');
        }
      }
      if (plus is Map) {
        if (plus.containsKey('s')) _state = '${plus['s'] ?? ''}';
        if (plus['a'] is Map) {
          attrs = {...attrs, ...(plus['a'] as Map).cast<String, Object?>()};
        }
      }
      _attributes = attrs;
    }
    _publish();
  }

  void _publish() {
    final snap = snapshotFrom(
      state: _state,
      attributes: _attributes,
      baseUrl: baseUrl,
      sawPlayback: _sawPlayback,
    );
    if (snap?['playing'] == true) _sawPlayback = true;
    queueEmpty = _state.isNotEmpty && snap == null;
    _emit(snap);
  }

  /// The Now Playing map for an entity state: null with nothing to show.
  /// Playing and paused always show; an idle player that still carries
  /// its last track shows only after playback was seen (or a reveal), so
  /// stale metadata at startup does not conjure a card.
  @visibleForTesting
  static Map<String, Object?>? snapshotFrom({
    required String state,
    required Map<String, Object?> attributes,
    required String baseUrl,
    bool sawPlayback = false,
  }) {
    final title = '${attributes['media_title'] ?? ''}'.trim();
    if (title.isEmpty) return null;
    final playing = state == 'playing' || state == 'buffering';
    final paused = state == 'paused';
    if (!playing && !paused) {
      if (state != 'idle' && state != 'on') return null;
      if (!sawPlayback) return null;
    }
    final features = (attributes['supported_features'] as num?)?.toInt() ?? 0;
    bool has(int bit) => features & bit != 0;
    final commands = <String>[
      if (has(featurePlay)) 'play',
      if (has(featurePause)) 'pause',
      if (has(featureStop)) 'stop',
      if (has(featureNext)) 'next',
      if (has(featurePrevious)) 'previous',
      if (has(featureSeek)) 'seek',
      if (has(featureShuffle)) 'shuffle',
      if (has(featureVolumeSet)) 'volume',
    ];
    final now = DateTime.now().millisecondsSinceEpoch;
    final duration = (attributes['media_duration'] as num?)?.toDouble();
    var position = (attributes['media_position'] as num?)?.toDouble() ?? 0;
    final updatedAt = attributes['media_position_updated_at'];
    if (playing && updatedAt is String) {
      final stamp = DateTime.tryParse(updatedAt);
      if (stamp != null) {
        final elapsed = (now - stamp.millisecondsSinceEpoch) / 1000;
        if (elapsed > 0) position += elapsed;
      }
    }
    if (duration != null && duration > 0 && position > duration) {
      position = duration;
    }
    final artist = '${attributes['media_artist'] ?? ''}'.trim();
    final album = '${attributes['media_album_name'] ?? ''}'.trim();
    final picture = '${attributes['entity_picture'] ?? ''}'.trim();
    final volume = (attributes['volume_level'] as num?)?.toDouble();
    return {
      'title': title,
      if (artist.isNotEmpty) 'artist': artist,
      if (album.isNotEmpty) 'album': album,
      if (duration != null && duration > 0)
        'durationMs': (duration * 1000).round(),
      'positionMs': (position * 1000).round(),
      'receivedAt': now,
      'playing': playing,
      'shuffle': attributes['shuffle'] == true,
      'supportedCommands': commands,
      if (volume != null) 'volume': (volume * 100).round(),
      if (attributes['is_volume_muted'] is bool)
        'muted': attributes['is_volume_muted'],
      if (picture.isNotEmpty)
        'artworkUrl': picture.startsWith('http')
            ? picture
            : '$baseUrl${picture.startsWith('/') ? '' : '/'}$picture',
    };
  }

  void _onDone() {
    if (_stopped) return;
    log.info(_name, 'Home Assistant follower connection closed');
    unawaited(_close());
    _emit(null);
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_stopped || _retry != null) return;
    final delay = min(30, 3 * (1 << min(_attempts, 4))) + Random().nextInt(3);
    _attempts++;
    _retry = Timer(Duration(seconds: delay), () {
      _retry = null;
      unawaited(_connect());
    });
  }

  Future<void> _close() async {
    final socket = _socket;
    _socket = null;
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(StateError('connection closed'));
    }
    _pending.clear();
    try {
      await socket?.close();
    } catch (_) {}
  }

  void _emit(Map<String, Object?>? snapshot) {
    _snapshot = snapshot;
    if (!_stopped) onSnapshot(snapshot);
  }

  /// The last published snapshot, for tests.
  @visibleForTesting
  Map<String, Object?>? get snapshot => _snapshot;

  /// Every media_player entity Home Assistant has, for the player picker:
  /// id, friendly name and availability. One REST call; the list is the
  /// whole instance, so it is fetched when the picker opens rather than
  /// kept.
  static Future<List<Map<String, Object?>>> listMediaPlayers({
    required String baseUrl,
    required String token,
  }) async {
    final client = HttpClient();
    try {
      final request = await client
          .getUrl(Uri.parse('$baseUrl/api/states'))
          .timeout(const Duration(seconds: 15));
      request.headers.set('Authorization', 'Bearer $token');
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! List) return const [];
      final players = <Map<String, Object?>>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final id = '${item['entity_id'] ?? ''}';
        if (!id.startsWith('media_player.')) continue;
        final attrs = item['attributes'] is Map
            ? (item['attributes'] as Map)
            : const {};
        players.add({
          'id': id,
          'name': '${attrs['friendly_name'] ?? id}',
          'available': '${item['state']}' != 'unavailable',
        });
      }
      players.sort(
        (a, b) => '${a['name']}'.toLowerCase().compareTo(
          '${b['name']}'.toLowerCase(),
        ),
      );
      return players;
    } finally {
      client.close(force: true);
    }
  }
}
