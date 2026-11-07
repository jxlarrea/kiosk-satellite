import 'dart:async';
import 'dart:io';
import 'dart:math' show Random, max, min;

import 'package:flutter/foundation.dart'
    show ValueNotifier, listEquals, visibleForTesting;

import '../../core/logging.dart';
import 'music_assistant_api.dart';
import 'remote_player.dart';

/// The Now Playing surface following a player that is not this device
/// (issue #265): a wall tablet showing and controlling the kitchen Sonos
/// instead of its own speaker.
///
/// Where the local player learns about its track from the Sendspin stream
/// itself, a remote player has no stream here — everything comes from
/// Music Assistant's API over one long-lived socket: the active queue and
/// player metadata on connect, then queue and player events. External
/// sources such as Spotify Connect can supply a track without a queue. Transport
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
    this.showInputs = false,
  }) : _api = MusicAssistantApi(baseUrl: baseUrl, token: token);

  /// What the log calls this connection: the follower of a remote player,
  /// or the watcher that keeps the local player's queue state (shuffle,
  /// the queue panel) in step with Music Assistant.
  final String label;

  /// Whether a TV or line-in input shows as a card named for the input.
  /// Off, the room reads as idle while one plays, so a soundbar under a
  /// television does not hold the screensaver off.
  final bool showInputs;

  /// The active sources Music Assistant gives a TV (HDMI or optical),
  /// line-in or phono input, with the names to show: `tv` and `line_in`
  /// from the Sonos provider, `hdmi`, `optical`, `line_in` and `phono_in`
  /// from the WiiM one. Matched by id, not by the source list's
  /// capabilities, since some providers list music sources such as
  /// Bluetooth with the same no-pause flags as an input.
  static const _inputs = {
    'tv': 'TV',
    'hdmi': 'TV',
    'optical': 'TV',
    'line_in': 'Line-in',
    'phono_in': 'Phono',
  };

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
    'repeat',
    'volume',
  ];

  /// The transport commands, the ones [control] can send.
  static const _transport = ['play', 'pause', 'stop', 'next', 'previous'];

  final MusicAssistantApi _api;
  final Logger log;
  @override
  final String playerId;
  final void Function(Map<String, Object?>? snapshot) onSnapshot;

  /// External sources can play without a Music Assistant queue.
  @override
  bool get hasQueue => !_usingPlayerMedia;

  @override
  Future<RemoteQueue?> fetchQueue() async => null;

  @override
  Future<bool> playQueueItem(String id) async => false;

  /// Music Assistant groups (syncs) players of one kind on command.
  @override
  bool get hasGrouping => true;

  /// The leader of the last group read, so a member is grouped under the
  /// player this one is actually synced to.
  String _leaderId = '';

  @override
  Future<RemoteGroup?> fetchGroup() async {
    final group = await _api.fetchGroup(playerId);
    if (group != null) {
      _leaderId = group.leaderId;
    } else {
      log.warn(_name, '$label group read failed: ${_api.groupProblem}');
    }
    return group;
  }

  @override
  Future<bool> setGrouped(String id, bool grouped) async {
    final error = await _api.setGrouped(
      leaderId: _leaderId.isNotEmpty ? _leaderId : playerId,
      memberId: id,
      grouped: grouped,
    );
    if (error != null) {
      log.warn(_name, '$label ${grouped ? 'group' : 'ungroup'} $id: $error');
    }
    return error == null;
  }

  /// The queue's live elapsed time, read every few seconds while playing,
  /// keeps the position within a moment of the audio.
  @override
  bool get lyricsSynced => !_usingPlayerMedia || _playerPosition != null;

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
  Object? _queue;
  Map? _player;
  bool _usingPlayerMedia = false;

  /// The player a protocol player plays for: the one that names it among
  /// its output protocols, a universal player wrapping a Sendspin client
  /// for one. Music Assistant lists the sources and what each can do only
  /// on that one, so the protocol player's own list is empty.
  String _ownerId = '';
  Map? _owner;

  /// The server's provider names by instance id, read once a connection
  /// is up, for the audio quality to name its source.
  Map<String, String> _providerNames = const {};
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

  /// The player's volume as Music Assistant last reported it, 0 to 100,
  /// and whether it is muted: read with the queue on a refresh and
  /// pushed by player_updated.
  int? _volume;
  bool? _muted;

  /// The player whose group this one plays in (issue #867): the one it
  /// is synced to, itself while it leads others, empty while it plays
  /// alone. Its group volume and mute are Music Assistant's own: the
  /// loudest member's level, and muted only when every member is.
  String _groupLeader = '';
  int? _groupVolume;
  bool? _groupMuted;

  /// The group volume, 0 to 100, while the player plays in a group; null
  /// while it plays alone or the server has not said.
  int? get groupVolume => _groupVolume;

  /// Whether the group the player plays in is muted, null as above.
  bool? get groupMuted => _groupMuted;

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

  /// Read the active queue and player metadata, including external sources.
  @override
  Future<void> refresh() async {
    final session = _session;
    if (session == null) return;
    Object? queue;
    try {
      queue = await session.send('player_queues/get_active_queue', {
        'player_id': playerId,
      });
    } catch (e) {
      log.warn(_name, '$label queue lookup failed: $e');
    }
    try {
      final player = await session.send('players/get', {'player_id': playerId});
      if (player is Map) {
        _player = player;
        _readVolume(player);
        _readMembers(player);
        await _readGroup(session, player);
        await _readOwner(session, player);
      }
    } catch (e) {
      log.warn(_name, '$label player lookup failed: $e');
    }
    if (_stopped || !identical(_session, session)) return;
    publishQueue(queue);
  }

  /// Follow the player [player] plays for while it is a protocol player
  /// (see [_ownerId]), found once among all players and read again on
  /// every refresh after that.
  Future<void> _readOwner(MaSession session, Map player) async {
    if (player['type'] != 'protocol') {
      _ownerId = '';
      _owner = null;
      return;
    }
    try {
      if (_ownerId.isEmpty) {
        final players = await session.send('players/all', const {});
        _ownerId = players is List ? ownerOf(players, playerId) : '';
      }
      if (_ownerId.isEmpty) return;
      final owner = await session.send('players/get', {'player_id': _ownerId});
      _owner = owner is Map ? owner : null;
    } catch (e) {
      log.warn(_name, '$label owner lookup failed: $e');
    }
  }

  @visibleForTesting
  set ownerId(String id) => _ownerId = id;

  /// The id of the player in [players] that plays through [protocolId] as
  /// one of its output protocols, or empty when none does.
  @visibleForTesting
  static String ownerOf(List players, String protocolId) {
    for (final p in players) {
      if (p is! Map || p['player_id'] == protocolId) continue;
      final protocols = p['output_protocols'];
      if (protocols is! List) continue;
      for (final o in protocols) {
        if (o is Map && o['output_protocol_id'] == protocolId) {
          return '${p['player_id'] ?? ''}';
        }
      }
    }
    return '';
  }

  void _readVolume(Object? player) {
    if (player is! Map) return;
    final level = player['volume_level'];
    if (level is num) _volume = level.round().clamp(0, 100);
    final muted = player['volume_muted'];
    if (muted is bool) _muted = muted;
  }

  /// The players Music Assistant last listed in this player's group.
  final members = ValueNotifier<List<String>>(const []);

  void _readMembers(Object? player) {
    final next = <String>[
      if (player is Map)
        for (final key in const ['group_members', 'static_group_members'])
          if (player[key] case final List listed)
            for (final m in listed) '$m',
    ];
    if (!listEquals(next, members.value)) members.value = next;
  }

  /// The leader of the group [player] plays in, or empty while it plays
  /// alone. A player that leads lists itself among its group members.
  String _leaderOf(Map player) {
    final synced = '${player['synced_to'] ?? ''}';
    if (synced.isNotEmpty) return synced;
    final members = player['group_members'];
    return members is List && members.any((m) => '$m' != playerId)
        ? playerId
        : '';
  }

  /// Follow the group volume of the group [player] plays in. A member
  /// reports only its own level, so the leader is asked for the group's.
  Future<void> _readGroup(MaSession session, Map player) async {
    _groupLeader = _leaderOf(player);
    Object? leader = player;
    if (_groupLeader.isEmpty) {
      leader = null;
    } else if (_groupLeader != playerId) {
      try {
        leader = await session.send('players/get', {'player_id': _groupLeader});
      } catch (e) {
        log.warn(_name, '$label group leader lookup failed: $e');
        leader = null;
      }
    }
    _readGroupVolume(leader);
  }

  void _readGroupVolume(Object? leader) {
    final level = leader is Map ? leader['group_volume'] : null;
    final muted = leader is Map ? leader['group_volume_muted'] : null;
    _groupVolume = level is num ? level.round().clamp(0, 100) : null;
    _groupMuted = muted is bool ? muted : null;
    // Music Assistant leaves the leader out of the group volume unless it
    // is a plain player, so a bare Sendspin player under a universal one
    // (type 'protocol') reports only the others: the loudest member and
    // muted only with everyone muted, the leader included, is the group's.
    if (leader is Map &&
        leader['type'] == 'protocol' &&
        leader['volume_control'] != 'none') {
      final own = leader['volume_level'];
      if (own is num && _groupVolume != null) {
        _groupVolume = max(_groupVolume!, own.round().clamp(0, 100));
      }
      if (_groupMuted == true && leader['volume_muted'] == false) {
        _groupMuted = false;
      }
    }
  }

  /// Set the volume of the group the player plays in (issue #867). Music
  /// Assistant moves every member from its own level, keeping the rooms'
  /// balance, the way its own group slider does, and takes a member's id
  /// for its leader's.
  Future<bool> setGroupVolume(int percent) async {
    final session = _session;
    if (session == null) return false;
    final level = percent.clamp(0, 100);
    try {
      await session.send('players/cmd/group_volume', {
        'player_id': playerId,
        'volume_level': level,
      });
    } catch (e) {
      log.warn(_name, '$label group volume failed: $e');
      return false;
    }
    // The loudest member lands on the level asked for, so the group
    // volume is known before the members report back.
    if (_groupVolume != null) {
      _groupVolume = level;
      _reemit();
    }
    return true;
  }

  /// Mute or unmute every member of the group the player plays in.
  Future<bool> setGroupMute(bool muted) async {
    final session = _session;
    if (session == null) return false;
    try {
      await session.send('players/cmd/group_volume_mute', {
        'player_id': playerId,
        'muted': muted,
      });
    } catch (e) {
      log.warn(_name, '$label group mute failed: $e');
      return false;
    }
    if (_groupMuted != null) {
      _groupMuted = muted;
      _reemit();
    }
    return true;
  }

  /// Publish the last snapshot again when the volume it carries changed.
  void _reemit() {
    final snap = _snapshot;
    if (snap == null) return;
    if (snap['volume'] != _volume ||
        snap['muted'] != _muted ||
        snap['groupVolume'] != _groupVolume ||
        snap['groupMuted'] != _groupMuted) {
      _emit({...snap, 'volume': ?_volume, 'muted': ?_muted});
    }
  }

  /// Mute the followed player: a player command in Music Assistant,
  /// echoed back by player_updated.
  @override
  Future<bool> setMute(bool muted) async {
    final session = _session;
    if (session == null) return false;
    try {
      await session.send('players/cmd/volume_mute', {
        'player_id': playerId,
        'muted': muted,
      });
      return true;
    } catch (e) {
      log.warn(_name, 'remote mute failed: $e');
      return false;
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
    if (session == null || !hasQueue || _queueId.isEmpty) return false;
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

  /// Repeat the followed player's queue: off, one or all, a queue setting
  /// like shuffle, echoed back by queue_updated.
  @override
  Future<bool> setRepeat(String mode) async {
    final session = _session;
    if (session == null || !hasQueue || _queueId.isEmpty) return false;
    try {
      await session.send('player_queues/repeat', {
        'queue_id': _queueId,
        'repeat_mode': mode,
      });
      return true;
    } catch (e) {
      log.warn(_name, 'remote repeat failed: $e');
      return false;
    }
  }

  /// Music Assistant keeps a library the playing track can be marked a
  /// favorite in, for the local player and its own players alike.
  @override
  bool get hasFavorites => !_usingPlayerMedia;

  /// The manager marks the track through Music Assistant's own library;
  /// nothing to do here.
  @override
  Future<bool> setFavorite(bool on) async => false;

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
      await _readProviderNames(session);
      await refresh();
    } catch (e) {
      log.warn(_name, '$label connect failed: $e');
      await _close();
      _scheduleRetry();
    }
  }

  Future<void> _readProviderNames(MaSession session) async {
    try {
      final providers = await session.send('providers', const {});
      if (providers is! List) return;
      _providerNames = {
        for (final p in providers.whereType<Map>())
          if ('${p['instance_id'] ?? ''}'.isNotEmpty &&
              '${p['name'] ?? ''}'.isNotEmpty)
            '${p['instance_id']}': '${p['name']}',
      };
    } catch (e) {
      log.warn(_name, '$label provider lookup failed: $e');
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
    _player = null;
    _owner = null;
    _ownerId = '';
    _queue = null;
    _queueId = '';
    _groupLeader = '';
    _groupVolume = null;
    _groupMuted = null;
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
          when objectId == _queueId &&
              _queueId.isNotEmpty &&
              !_usingPlayerMedia:
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
        // External sources report track changes here without queue events.
        // Publish their metadata now and refresh the queue for handoffs.
        if (data is Map) _player = data;
        _readVolume(data);
        _readMembers(data);
        // A leader carries its group's volume itself and a player left
        // alone has none; a member waits for the refresh below to ask its
        // leader.
        if (data is Map) {
          final leader = _leaderOf(data);
          if (leader.isEmpty || leader == playerId) {
            _groupLeader = leader;
            _readGroupVolume(leader.isEmpty ? null : data);
          }
        }
        if (_usingPlayerMedia ||
            _hasExternalSource ||
            _queue == null ||
            _radioQueueItem != null) {
          _publishSnapshot(preservePosition: true);
        } else {
          _reemit();
        }
        _refreshDebounce?.cancel();
        _refreshDebounce = Timer(
          const Duration(milliseconds: 400),
          () => unawaited(refresh()),
        );
      case 'player_updated'
          when objectId == _groupLeader && _groupLeader.isNotEmpty:
        // The leader's own update carries the group volume, moved from
        // another room or Music Assistant's own group slider.
        _readGroupVolume(data);
        _reemit();
      case 'player_updated' when objectId == _ownerId && _ownerId.isNotEmpty:
        // The owner's update carries the source list, what each source
        // can do included.
        if (data is Map) _owner = data;
        if (_usingPlayerMedia || _hasExternalSource) {
          _publishSnapshot(preservePosition: true);
        }
      case 'player_removed' when objectId == playerId:
        _player = null;
        _queue = null;
        _queueId = '';
        _emit(null);
    }
  }

  /// Republish from a queue dict — the get_active_queue answer or a
  /// queue_updated event's payload, which are the same shape.
  @visibleForTesting
  void publishQueue(Object? queue) {
    _queue = queue;
    _queueId = queue is Map ? '${queue['queue_id'] ?? ''}' : '';
    _publishSnapshot();
  }

  void _publishSnapshot({bool preservePosition = false}) {
    final queue = _queue;
    final snap = queueTrackSnapshot(
      _hasExternalSource || (queue is Map && queue['active'] == false)
          ? null
          : queue,
      webBase: musicAssistantWebUrl(_api.baseUrl),
      currentMedia: _radioPlayerMedia,
      providerNames: _providerNames,
    );
    _usingPlayerMedia = snap == null;
    queueEmpty = queue is Map && snap == null;
    if (snap == null) {
      _publishPlayerMedia();
      return;
    }
    final playing = snap['state'] == 'playing';
    if (playing) _sawPlayback = true;
    final show = playing || snap['state'] == 'paused' || _sawPlayback;
    if (!show) {
      _emit(null);
      return;
    }
    final previous = _snapshot;
    final keepPosition =
        preservePosition &&
        previous != null &&
        previous['queueItemId'] == snap['queueItemId'] &&
        previous['mediaUri'] == snap['mediaUri'] &&
        previous['playing'] == playing;
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
      'volume': ?_volume,
      'muted': ?_muted,
      // A time the server just measured, in a queue dict or a time
      // event alike: what the local player's position follows.
      'timeFresh': true,
      if (keepPosition) ...{
        'positionMs': previous['positionMs'],
        'receivedAt': previous['receivedAt'],
        'timeFresh': false,
      },
    });
  }

  Map? get _radioQueueItem {
    final queue = _queue;
    if (queue is! Map) return null;
    final item = queue['current_item'];
    if (item is! Map) return null;
    final media = item['media_item'];
    return media is Map && media['media_type'] == 'radio' ? item : null;
  }

  /// Player metadata is a fallback for radio queues without stream metadata.
  /// Match the item before using it so a station change cannot reuse an old
  /// song. Ordinary tracks and their queue timing keep their existing path.
  Map? get _radioPlayerMedia {
    final item = _radioQueueItem;
    final current = _player?['current_media'];
    if (item == null || current is! Map) return null;
    final media = item['media_item'] as Map;
    final source = '${current['source_id'] ?? ''}';
    if (source.isNotEmpty && source != _queueId) return null;
    final itemId = '${item['queue_item_id'] ?? ''}';
    final currentId = '${current['queue_item_id'] ?? ''}';
    if (currentId.isNotEmpty) {
      return itemId.isNotEmpty && currentId == itemId ? current : null;
    }
    final uri = '${item['uri'] ?? media['uri'] ?? ''}';
    return uri.isNotEmpty && current['uri'] == uri ? current : null;
  }

  bool get _hasExternalSource {
    final source = '${_player?['active_source'] ?? ''}';
    // Group members and protocol players can report their own player id
    // while get_active_queue resolves the leader's or parent's queue.
    return source.isNotEmpty &&
        source != _queueId &&
        source != playerId &&
        source != _player?['synced_to'] &&
        source != _player?['active_group'];
  }

  /// The position and the time it was measured at, both from one place.
  /// The media's own pair comes first: MA puts the song's position there,
  /// while a synced group member's player-level time is the leader's
  /// stream clock, which runs from when the stream started.
  (num, Object?)? get _playerPosition {
    final player = _player;
    final media = player?['current_media'];
    for (final holder in [media, player]) {
      if (holder is Map && holder['elapsed_time'] is num) {
        return (
          holder['elapsed_time'] as num,
          holder['elapsed_time_last_updated'],
        );
      }
    }
    return null;
  }

  void _publishPlayerMedia() {
    final player = _player;
    final media = player?['current_media'];
    final state = player?['playback_state'] ?? player?['state'];
    final title = media is Map ? '${media['title'] ?? ''}'.trim() : '';
    final active = state == 'playing' || state == 'paused';
    // A TV or line-in input: nothing to show but the input's name, and
    // by default not even that.
    final input = player == null ? null : _inputs[player['active_source']];
    if (input != null &&
        showInputs &&
        active &&
        player!['available'] != false) {
      queueEmpty = false;
      _emit({
        'title': input,
        'positionMs': 0,
        'receivedAt': DateTime.now().millisecondsSinceEpoch,
        'playing': state == 'playing',
        'stream': true,
        'supportedCommands': ['stop', if (_volume != null) 'volume'],
        'volume': ?_volume,
        'muted': ?_muted,
      });
      return;
    }
    if (player == null ||
        input != null ||
        player['available'] == false ||
        media is! Map ||
        title.isEmpty ||
        !active) {
      queueEmpty = player != null;
      _emit(null);
      return;
    }
    queueEmpty = false;
    final playing = state == 'playing';
    final now = DateTime.now().millisecondsSinceEpoch;
    final (elapsed, measuredAt) = _playerPosition ?? (null, null);
    var position = ((elapsed ?? 0) * 1000).round();
    if (playing && elapsed != null && measuredAt is num) {
      position += max(0, now - (measuredAt * 1000).round());
    }
    // A radio stream's elapsed time is the station's, not the song's
    // (see queueTrackSnapshot): no duration, so no bar.
    final duration = media['media_type'] == 'radio' ? null : media['duration'];
    final durationMs = duration is num ? (duration * 1000).round() : 0;
    position = max(0, durationMs > 0 ? min(position, durationMs) : position);
    // A protocol player lists no sources of its own: its owner's list
    // says what the source can do.
    Map? source;
    for (final holder in [player, _owner]) {
      if (holder?['source_list'] case final List sources) {
        for (final item in sources) {
          if (item is Map && item['id'] == player['active_source']) {
            source = item;
          }
        }
      }
      if (source != null) break;
    }
    _emit({
      'title': title,
      'artist': '${media['artist'] ?? ''}',
      'album': '${media['album'] ?? ''}',
      'artworkUrl': '${media['image_url'] ?? ''}',
      'durationMs': durationMs,
      'positionMs': position,
      'receivedAt': now,
      'playing': playing,
      'supportedCommands': [
        'stop',
        if (source?['can_play_pause'] == true) ...['play', 'pause'],
        if (source?['can_next_previous'] == true) ...['next', 'previous'],
        if (source?['can_seek'] == true) 'seek',
        if (_volume != null) 'volume',
      ],
      'volume': ?_volume,
      'muted': ?_muted,
      'timeFresh': elapsed != null,
    });
  }

  void _emit(Map<String, Object?>? snapshot) {
    // Every snapshot carries the group volume as last read, whichever
    // path built it.
    if (snapshot != null) {
      snapshot = {
        for (final e in snapshot.entries)
          if (e.key != 'groupVolume' && e.key != 'groupMuted') e.key: e.value,
        'groupVolume': ?_groupVolume,
        'groupMuted': ?_groupMuted,
      };
    }
    _snapshot = snapshot;
    if (!_stopped) onSnapshot(snapshot);
  }
}
