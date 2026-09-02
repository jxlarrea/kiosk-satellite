import 'dart:async';
import 'dart:io';
import 'dart:math' show Random, min;

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../core/logging.dart';
import 'music_assistant_api.dart';
import 'remote_player.dart';

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
class MaRemotePlayer implements RemotePlayer {
  MaRemotePlayer({
    required String baseUrl,
    required String token,
    required this.playerId,
    required this.onSnapshot,
    required this.log,
    this.label = 'remote player',
  }) : _api = MusicAssistantApi(baseUrl: baseUrl, token: token);

  /// What the log calls this connection: the follower of a remote player,
  /// or the watcher that keeps the local player's queue state (shuffle,
  /// the queue panel) in step with Music Assistant.
  final String label;

  static const _name = 'sendspin';

  /// Every transport the card can render. Not read from the player's own
  /// supported_features: transport acts on the queue, which Music
  /// Assistant drives for any player (a pause it cannot pass through
  /// becomes a stop server-side). Shuffle is the queue's, volume the
  /// player's; both are Music Assistant commands for any player.
  static const commands = [
    'play',
    'pause',
    'stop',
    'next',
    'previous',
    'seek',
    'shuffle',
    'volume',
  ];

  /// The transport commands, the ones [control] can send.
  static const _transport = ['play', 'pause', 'stop', 'next', 'previous'];

  final MusicAssistantApi _api;
  final Logger log;
  @override
  final String playerId;
  final void Function(Map<String, Object?>? snapshot) onSnapshot;

  /// Music Assistant keeps a queue for every player it drives.
  @override
  bool get hasQueue => true;

  /// The queue's live elapsed time, read every few seconds while playing,
  /// keeps the position within a moment of the audio.
  @override
  bool get lyricsSynced => true;

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

  /// Whether the server's last word on the queue was that it holds no
  /// track: a cleared queue, as opposed to a connection that dropped. The
  /// local player's watcher reads it to tell a stop from a pause, which
  /// the Sendspin stream alone cannot.
  @override
  bool queueEmpty = false;

  Map<String, Object?>? _snapshot;

  @override
  void start() {
    unawaited(_connect());
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    _retry?.cancel();
    _refreshDebounce?.cancel();
    await _close();
  }

  /// The "Show the Sendspin player" reveal with nothing on screen: surface
  /// the queue's last track as a paused card even before any playback has
  /// been seen, mirroring the local player's queue recovery (issue #178).
  @override
  void reveal() {
    _sawPlayback = true;
    unawaited(refresh());
  }

  /// Ask for the player's active queue and republish from the answer.
  @override
  Future<void> refresh() async {
    final session = _session;
    if (session == null) return;
    try {
      final queue = await session.send('player_queues/get_active_queue', {
        'player_id': playerId,
      });
      publishQueue(queue);
    } catch (e) {
      log.warn(_name, '$label queue lookup failed: $e');
    }
  }

  /// Send a transport command for the followed player. False when the
  /// connection is down or the server refuses it.
  @override
  Future<bool> control(String command) async {
    final session = _session;
    if (session == null || !_transport.contains(command)) return false;
    try {
      await session.send('players/cmd/$command', {'player_id': playerId});
      return true;
    } catch (e) {
      log.warn(_name, 'remote $command failed: $e');
      return false;
    }
  }

  /// Shuffle the followed player's queue on or off: a queue setting in
  /// Music Assistant, not a player command, echoed back by queue_updated.
  @override
  Future<bool> setShuffle(bool on) async {
    final session = _session;
    if (session == null || _queueId.isEmpty) return false;
    try {
      await session.send('player_queues/shuffle', {
        'queue_id': _queueId,
        'shuffle_enabled': on,
      });
      return true;
    } catch (e) {
      log.warn(_name, 'remote shuffle failed: $e');
      return false;
    }
  }

  /// Seek the followed player's queue: Music Assistant takes the position
  /// in whole seconds and answers with a queue_time_updated for the bar.
  @override
  Future<bool> seek(int positionMs) async {
    final session = _session;
    if (session == null) return false;
    try {
      await session.send('players/cmd/seek', {
        'player_id': playerId,
        'position': (positionMs / 1000).round(),
      });
      return true;
    } catch (e) {
      log.warn(_name, 'remote seek failed: $e');
      return false;
    }
  }

  /// Set the followed player's volume: a player command in Music
  /// Assistant, echoed back by player_updated.
  @override
  Future<bool> setVolume(int percent) async {
    final session = _session;
    if (session == null) return false;
    try {
      await session.send('players/cmd/volume_set', {
        'player_id': playerId,
        'volume_level': percent.clamp(0, 100),
      });
      return true;
    } catch (e) {
      log.warn(_name, 'remote volume failed: $e');
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
      final session = MaSession(socket, onEvent: handleEvent, onDone: _onDone);
      _session = session;
      await session.send('auth', {'token': _api.token});
      _attempts = 0;
      log.info(_name, '$label: following $playerId');
      await refresh();
    } catch (e) {
      log.warn(_name, '$label connect failed: $e');
      await _close();
      _scheduleRetry();
    }
  }

  void _onDone() {
    if (_stopped) return;
    log.info(_name, '$label connection closed');
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
            // A time the server just measured, as opposed to a queue
            // dict's stamp-extrapolated one: the only kind the local
            // player's position re-base trusts.
            'timeFresh': true,
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
    queueEmpty = queue is Map && snap == null;
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
    // The elapsed time in a queue dict is live at the moment the server
    // serializes it, while its stamp ('positionAtMs') marks when the
    // server last heard from the player, which for a Sendspin player can
    // be half a minute back. Extrapolating from the stamp counted that
    // gap twice and ran the bar twenty seconds ahead of the audio; the
    // arrival time is the base.
    _emit({
      for (final e in snap.entries)
        if (e.key != 'state' && e.key != 'positionAtMs') e.key: e.value,
      'receivedAt': DateTime.now().millisecondsSinceEpoch,
      'playing': playing,
      'supportedCommands': commands,
      // A time the server just measured, in a queue dict or a time
      // event alike: what the local player's position follows.
      'timeFresh': true,
    });
  }

  void _emit(Map<String, Object?>? snapshot) {
    _snapshot = snapshot;
    if (!_stopped) onSnapshot(snapshot);
  }
}
