import 'dart:async';
import 'dart:io';
import 'dart:math' show Random, min;

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../core/logging.dart';
import 'music_assistant_api.dart';

/// The Now Playing surface following a player that is not this device
/// (issue #265): a wall tablet showing and controlling the kitchen Sonos
/// instead of its own speaker.
///
/// Where the local player learns about its track from the Sendspin stream
/// itself, a remote player has no stream here — everything comes from
/// Music Assistant's API over one long-lived socket: the active queue on
/// connect, then the queue_updated / queue_time_updated / player_updated
/// events the server pushes at every authenticated client. Transport
/// commands go back over the same socket as players/cmd calls.
///
/// Output is [onSnapshot]: the same map shape SendspinManager publishes
/// for the local player ('title', 'artist', 'album', 'durationMs',
/// 'positionMs', 'receivedAt', 'artworkUrl', 'playing',
/// 'supportedCommands'), or null when there is nothing to show — so the
/// floating card, the full-screen view and the screensaver takeover all
/// work unchanged.
class MaRemotePlayer {
  MaRemotePlayer({
    required String baseUrl,
    required String token,
    required this.playerId,
    required this.onSnapshot,
    required this.log,
  }) : _api = MusicAssistantApi(baseUrl: baseUrl, token: token);

  static const _name = 'sendspin';

  /// Every transport the card can render. Not read from the player's own
  /// supported_features: transport acts on the queue, which Music
  /// Assistant drives for any player (a pause it cannot pass through
  /// becomes a stop server-side).
  static const commands = ['play', 'pause', 'stop', 'next', 'previous'];

  final MusicAssistantApi _api;
  final Logger log;
  final String playerId;
  final void Function(Map<String, Object?>? snapshot) onSnapshot;

  bool _stopped = false;
  HttpClient? _client;
  WebSocket? _socket;
  MaSession? _session;
  Timer? _retry;
  int _attempts = 0;

  /// The queue currently followed — a synced player's active queue is
  /// another player's, so it is whatever the last lookup answered, not
  /// [playerId].
  String _queueId = '';
  Timer? _refreshDebounce;

  /// Whether this session has seen the queue actually play. An idle queue
  /// still carries its last track, which must not conjure a card out of
  /// stale metadata at startup — but after playback (or an explicit
  /// [reveal]) the same idle state IS the paused card, because players
  /// without a native pause stop instead.
  bool _sawPlayback = false;

  Map<String, Object?>? _snapshot;

  void start() {
    unawaited(_connect());
  }

  Future<void> stop() async {
    _stopped = true;
    _retry?.cancel();
    _refreshDebounce?.cancel();
    await _close();
  }

  /// The "Show the Sendspin player" reveal with nothing on screen: surface
  /// the queue's last track as a paused card even before any playback has
  /// been seen, mirroring the local player's queue recovery (issue #178).
  void reveal() {
    _sawPlayback = true;
    unawaited(refresh());
  }

  /// Ask for the player's active queue and republish from the answer.
  Future<void> refresh() async {
    final session = _session;
    if (session == null) return;
    try {
      final queue = await session.send('player_queues/get_active_queue', {
        'player_id': playerId,
      });
      publishQueue(queue);
    } catch (e) {
      log.warn(_name, 'remote player queue lookup failed: $e');
    }
  }

  /// Send a transport command for the followed player. False when the
  /// connection is down or the server refuses it.
  Future<bool> control(String command) async {
    final session = _session;
    if (session == null || !commands.contains(command)) return false;
    try {
      await session.send('players/cmd/$command', {'player_id': playerId});
      return true;
    } catch (e) {
      log.warn(_name, 'remote $command failed: $e');
      return false;
    }
  }

  Future<void> _connect() async {
    if (_stopped) return;
    try {
      final client = MusicAssistantApi.newHttpClient();
      _client = client;
      final socket = await WebSocket.connect(
        _api.socketUri.toString(),
        customClient: client,
      ).timeout(const Duration(seconds: 15));
      if (_stopped) {
        await socket.close();
        client.close(force: true);
        return;
      }
      // Idle is this connection's normal state (nothing flows while no
      // music plays), so only the protocol's own ping can tell a quiet
      // socket from a dead one.
      socket.pingInterval = const Duration(seconds: 20);
      _socket = socket;
      final session = MaSession(
        socket,
        onEvent: handleEvent,
        onDone: _onDone,
      );
      _session = session;
      await session.send('auth', {'token': _api.token});
      _attempts = 0;
      log.info(_name, 'following remote player $playerId');
      await refresh();
    } catch (e) {
      log.warn(_name, 'remote player connect failed: $e');
      await _close();
      _scheduleRetry();
    }
  }

  void _onDone() {
    if (_stopped) return;
    log.info(_name, 'remote player connection closed');
    unawaited(_close());
    // Nothing live to show while disconnected; an empty card would lie.
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
    final client = _client;
    _socket = null;
    _session = null;
    _client = null;
    try {
      await socket?.close();
    } catch (_) {}
    client?.close(force: true);
  }

  @visibleForTesting
  void handleEvent(String event, String objectId, Object? data) {
    switch (event) {
      case 'queue_updated' when objectId == _queueId && _queueId.isNotEmpty:
        // The event's payload is the full queue dict; no round trip.
        publishQueue(data);
      case 'queue_time_updated'
          when objectId == _queueId && _queueId.isNotEmpty:
        final snap = _snapshot;
        final elapsed = data as num?;
        if (snap != null && elapsed != null) {
          _emit({
            ...snap,
            'positionMs': (elapsed * 1000).round(),
            'receivedAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      case 'player_updated' when objectId == playerId:
        // Play, pause, a queue handoff into or out of a group — all land
        // here. The queue answer is authoritative, so just look it up,
        // debounced: one action fires a handful of these back to back.
        _refreshDebounce?.cancel();
        _refreshDebounce = Timer(
          const Duration(milliseconds: 400),
          () => unawaited(refresh()),
        );
      case 'player_removed' when objectId == playerId:
        _emit(null);
    }
  }

  /// Republish from a queue dict — the get_active_queue answer or a
  /// queue_updated event's payload, which are the same shape.
  @visibleForTesting
  void publishQueue(Object? queue) {
    if (queue is Map) _queueId = '${queue['queue_id'] ?? ''}';
    final snap = queueTrackSnapshot(
      queue,
      webBase: musicAssistantWebUrl(_api.baseUrl),
    );
    if (snap == null) {
      _emit(null);
      return;
    }
    final playing = snap['state'] == 'playing';
    if (playing) _sawPlayback = true;
    final show = playing || snap['state'] == 'paused' || _sawPlayback;
    if (!show) {
      _emit(null);
      return;
    }
    // The server stamps the position it reports ('positionAtMs'); trust
    // that stamp as the extrapolation base when the clocks roughly agree,
    // since the elapsed time in a queue event can be seconds old by the
    // time it arrives. Wildly apart means an unsynced clock somewhere:
    // fall back to arrival time rather than freeze or run the bar wild.
    final now = DateTime.now().millisecondsSinceEpoch;
    final measuredAt = (snap['positionAtMs'] as num?)?.toInt();
    final receivedAt =
        measuredAt != null && (now - measuredAt).abs() < 60000
        ? measuredAt
        : now;
    _emit({
      for (final e in snap.entries)
        if (e.key != 'state' && e.key != 'positionAtMs') e.key: e.value,
      'receivedAt': receivedAt,
      'playing': playing,
      'supportedCommands': commands,
    });
  }

  void _emit(Map<String, Object?>? snapshot) {
    _snapshot = snapshot;
    if (!_stopped) onSnapshot(snapshot);
  }
}
