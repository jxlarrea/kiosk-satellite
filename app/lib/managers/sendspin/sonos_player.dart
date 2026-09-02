import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../core/logging.dart';
import '../dlna/upnp_xml.dart' show parseUpnpTime;
import 'remote_player.dart';
import 'sonos_client.dart';

/// The Now Playing surfaces following a Sonos speaker directly, over the
/// speaker's own local interface: no Home Assistant, no Music Assistant
/// in between. A room is picked; whatever group it plays in is followed,
/// so a regrouping from the Sonos app re-points the follower on its own.
///
/// Everything is polled: transport state and position from the group's
/// coordinator once a second while playing (every few seconds otherwise),
/// the play mode and the volume a little less often, the topology every
/// half minute. A speaker answers each call in milliseconds and polling
/// works across VLANs where the speaker could never reach an event
/// callback on the tablet.
class SonosPlayer implements RemotePlayer {
  SonosPlayer({
    required this.host,
    required this.uuid,
    required this.onSnapshot,
    required this.log,
    this.groupVolume = true,
    this.clientFactory = SonosClient.new,
  });

  /// Whether the volume slider sets the whole group's volume while the
  /// room plays in one or only the room's own.
  final bool groupVolume;

  static const _name = 'sendspin';

  /// The picked room's address and id.
  final String host;
  final String uuid;
  final void Function(Map<String, Object?>? snapshot) onSnapshot;
  final Logger log;

  @visibleForTesting
  final SonosClient Function(String host) clientFactory;

  @override
  String get playerId => uuid;

  @override
  bool queueEmpty = false;

  @override
  bool get hasQueue => true;

  @override
  bool get hasFavorites => false;

  /// Position is read from the speaker itself every second.
  @override
  bool get lyricsSynced => true;

  bool _running = false;
  Timer? _tick;
  int _ticks = 0;
  bool _sawPlayback = false;
  bool _playing = false;
  bool _shuffle = false;
  int? _volume;
  bool? _muted;
  Map<String, Object?>? _snapshot;

  /// The group the room plays in, as of the last topology read: the
  /// coordinator takes the transport, the queue and the group volume.
  SonosGroup? _group;
  int _topologyAt = 0;

  /// The room's own client and the coordinator's (the same one while the
  /// room plays alone), each kept for its connections.
  late final SonosClient _room = clientFactory(host);
  SonosClient? _leader;
  SonosClient get _coordinator {
    final leader = _group?.leader;
    if (leader == null || leader.host == host) return _room;
    if (_leader?.host != leader.host) {
      _leader?.close();
      _leader = clientFactory(leader.host);
    }
    return _leader!;
  }

  bool get _grouped => (_group?.members.length ?? 1) > 1;

  @override
  void start() {
    _running = true;
    unawaited(_poll());
  }

  @override
  Future<void> stop() async {
    _running = false;
    _tick?.cancel();
    _tick = null;
    _room.close();
    _leader?.close();
    _leader = null;
  }

  @override
  void reveal() {
    _sawPlayback = true;
    unawaited(_poll());
  }

  @override
  Future<void> refresh() => _poll();

  Future<void> _poll() async {
    if (!_running) return;
    _tick?.cancel();
    _tick = null;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_group == null || now - _topologyAt > 30000) {
        await _refreshTopology();
        _topologyAt = now;
      }
      final co = _coordinator;
      final transport = await co.transportInfo();
      final position = await co.positionInfo();
      // The play mode and the volume change rarely and cost a call each:
      // read them at the start, then every few ticks.
      if (_ticks % 5 == 0) {
        final settings = await co.transportSettings();
        _shuffle = (settings['PlayMode'] ?? '').contains('SHUFFLE');
        if (_grouped && groupVolume) {
          _volume = await co.groupVolume();
          _muted = await co.groupMute();
        } else {
          _volume = await _room.volume();
          _muted = await _room.mute();
        }
      }
      _ticks++;
      _publish(transport, position);
    } catch (e) {
      log.warn(_name, 'Sonos poll failed: $e');
      // Out of reach: nothing live to show. The topology is re-read on
      // the next round in case the coordinator changed under us.
      _group = null;
      _emit(null);
    }
    if (!_running) return;
    _tick = Timer(
      Duration(seconds: _playing ? 1 : 3),
      () => unawaited(_poll()),
    );
  }

  Future<void> _refreshTopology() async {
    final groups = await _room.zoneGroups();
    final mine = groups.where((g) => g.contains(uuid)).firstOrNull;
    if (mine != null && (mine.leader.uuid != _group?.leader.uuid)) {
      log.info(
        _name,
        'Sonos group: ${mine.name} (coordinator ${mine.leader.name})',
      );
    }
    _group = mine;
  }

  void _publish(Map<String, String> transport, Map<String, String> position) {
    final snap = snapshotFrom(
      transport: transport,
      position: position,
      host: _coordinator.host,
      shuffle: _shuffle,
      volume: _volume,
      muted: _muted,
      sawPlayback: _sawPlayback,
    );
    _playing = snap?['playing'] == true;
    if (_playing) _sawPlayback = true;
    queueEmpty = snap == null;
    // A poll that changed nothing stays quiet: the surfaces extrapolate
    // the position from the last report, and a fresh map every second
    // would rebuild the whole view (blur and all) under a finger. What
    // gets through: a new track, a state flip, a level change, and the
    // position when it has drifted from the extrapolation or the last
    // report is getting old.
    if (!_differs(_snapshot, snap)) return;
    _emit(snap);
  }

  static const _stable = [
    'title',
    'artist',
    'album',
    'artworkUrl',
    'playing',
    'shuffle',
    'volume',
    'muted',
    'durationMs',
    'trackNumber',
    'stream',
  ];

  static bool _differs(Map<String, Object?>? old, Map<String, Object?>? now) {
    if (old == null || now == null) return old != now;
    for (final k in _stable) {
      if (old[k] != now[k]) return true;
    }
    final oldPos = (old['positionMs'] as num?)?.toInt() ?? 0;
    final oldAt = (old['receivedAt'] as num?)?.toInt() ?? 0;
    final newPos = (now['positionMs'] as num?)?.toInt() ?? 0;
    final newAt = (now['receivedAt'] as num?)?.toInt() ?? 0;
    final elapsed = newAt - oldAt;
    if (elapsed > 10000) return true;
    final expected = now['playing'] == true ? oldPos + elapsed : oldPos;
    return (newPos - expected).abs() > 1500;
  }

  /// The Now Playing map for a transport and position answer: null with
  /// nothing to show. Playing and paused always show; a stopped speaker
  /// that still holds its last track shows only after playback was seen
  /// (or a reveal), so a stale track does not conjure a card at startup.
  @visibleForTesting
  static Map<String, Object?>? snapshotFrom({
    required Map<String, String> transport,
    required Map<String, String> position,
    required String host,
    bool shuffle = false,
    int? volume,
    bool? muted,
    bool sawPlayback = false,
  }) {
    final state = transport['CurrentTransportState'] ?? '';
    final playing = state == 'PLAYING' || state == 'TRANSITIONING';
    final paused = state == 'PAUSED_PLAYBACK';
    if (!playing && !paused && !sawPlayback) return null;
    final items = SonosClient.parseDidlItems(position['TrackMetaData'] ?? '');
    final item = items.isEmpty ? const <String, String>{} : items.first;
    // A radio stream names the station in the title and the song, when
    // the station sends one, in its own field.
    final stream = item['streamContent'];
    final isStream =
        (item['class'] ?? '').contains('audioBroadcast') ||
        (position['TrackDuration'] ?? '') == 'NOT_IMPLEMENTED';
    var title = item['title'] ?? '';
    var artist = item['artist'] ?? '';
    var album = item['album'] ?? '';
    if (stream != null && stream.isNotEmpty) {
      // "Artist - Title" is the common shape; anything else is the title.
      final dash = stream.indexOf(' - ');
      if (dash > 0) {
        album = title;
        artist = stream.substring(0, dash).trim();
        title = stream.substring(dash + 3).trim();
      } else {
        album = title;
        title = stream;
      }
    }
    if (title.isEmpty) return null;
    final duration = parseUpnpTime(position['TrackDuration'] ?? '');
    final elapsed = parseUpnpTime(position['RelTime'] ?? '');
    final durationMs = duration?.inMilliseconds ?? 0;
    final art = item['art'] ?? '';
    final tracks = int.tryParse(position['Track'] ?? '') ?? 0;
    return {
      'title': title,
      if (artist.isNotEmpty) 'artist': artist,
      if (album.isNotEmpty) 'album': album,
      if (durationMs > 0) 'durationMs': durationMs,
      'positionMs': elapsed?.inMilliseconds ?? 0,
      'receivedAt': DateTime.now().millisecondsSinceEpoch,
      'playing': playing,
      'shuffle': shuffle,
      'trackNumber': tracks,
      'stream': isStream,
      'supportedCommands': [
        'play',
        'pause',
        'stop',
        'next',
        'previous',
        if (durationMs > 0) 'seek',
        'shuffle',
        'volume',
      ],
      'volume': ?volume,
      'muted': ?muted,
      if (art.isNotEmpty)
        'artworkUrl': art.startsWith('http')
            ? art
            : 'http://$host:${SonosClient.port}${art.startsWith('/') ? '' : '/'}$art',
    };
  }

  @override
  Future<bool> control(String command) async {
    try {
      final co = _coordinator;
      switch (command) {
        case 'play':
          await co.play();
        case 'pause':
          try {
            await co.pause();
          } on SonosError catch (e) {
            // A radio stream has no pause; Sonos itself stops instead.
            if (e.code != 701) rethrow;
            await co.stop();
          }
        case 'stop':
          await co.stop();
        case 'next':
          await co.next();
        case 'previous':
          await co.previous();
        default:
          return false;
      }
      unawaited(_poll());
      return true;
    } catch (e) {
      log.warn(_name, 'Sonos $command failed: $e');
      return false;
    }
  }

  @override
  Future<bool> setShuffle(bool on) async {
    try {
      final co = _coordinator;
      final settings = await co.transportSettings();
      final mode = settings['PlayMode'] ?? 'NORMAL';
      final repeat = mode.contains('REPEAT');
      final one = mode == 'REPEAT_ONE';
      await co.setPlayMode(
        on
            ? (repeat && !one ? 'SHUFFLE' : 'SHUFFLE_NOREPEAT')
            : (one
                  ? 'REPEAT_ONE'
                  : repeat
                  ? 'REPEAT_ALL'
                  : 'NORMAL'),
      );
      _shuffle = on;
      unawaited(_poll());
      return true;
    } catch (e) {
      log.warn(_name, 'Sonos shuffle failed: $e');
      return false;
    }
  }

  @override
  Future<bool> seek(int positionMs) async {
    try {
      await _coordinator.seekTime(Duration(milliseconds: positionMs));
      unawaited(_poll());
      return true;
    } catch (e) {
      log.warn(_name, 'Sonos seek failed: $e');
      return false;
    }
  }

  /// The room's own volume or the group's when the room plays in one.
  @override
  Future<bool> setVolume(int percent) async {
    try {
      if (_grouped && groupVolume) {
        await _coordinator.setGroupVolume(percent);
      } else {
        await _room.setVolume(percent);
      }
      _volume = percent;
      return true;
    } catch (e) {
      log.warn(_name, 'Sonos volume failed: $e');
      return false;
    }
  }

  /// Mute the room, or the group while the room plays in one.
  @override
  Future<bool> setMute(bool muted) async {
    try {
      if (_grouped && groupVolume) {
        await _coordinator.setGroupMute(muted);
      } else {
        await _room.setMute(muted);
      }
      _muted = muted;
      unawaited(_poll());
      return true;
    } catch (e) {
      log.warn(_name, 'Sonos mute failed: $e');
      return false;
    }
  }

  /// The group's queue, the playing item flagged by the transport's
  /// track number. A station or a line-in plays outside the queue, and
  /// the panel shows that as nothing queued.
  @override
  Future<RemoteQueue?> fetchQueue() async {
    try {
      final co = _coordinator;
      final media = await co.mediaInfo();
      final inQueue = (media['CurrentURI'] ?? '').startsWith('x-rincon-queue:');
      final (items, total) = await co.browseQueue();
      final current = inQueue ? (_snapshot?['trackNumber'] as int? ?? 0) : 0;
      final rows = [
        for (final (i, it) in items.indexed)
          {
            'index': i,
            'id': '${i + 1}',
            'title': it['title'] ?? '',
            'artist': it['artist'] ?? '',
            'durationMs': ?parseUpnpTime(it['duration'] ?? '')?.inMilliseconds,
            'current': current == i + 1,
            'played': current > 0 && i + 1 < current,
          },
      ];
      return RemoteQueue(
        items: rows,
        upNext: current > 0 ? (total - current).clamp(0, total) : total,
      );
    } catch (e) {
      log.warn(_name, 'Sonos queue failed: $e');
      return null;
    }
  }

  /// Jump the queue to the row [id], its 1-based track number. A speaker
  /// playing something else first switches back to its queue.
  @override
  Future<bool> playQueueItem(String id) async {
    final track = int.tryParse(id);
    if (track == null || track < 1) return false;
    try {
      final co = _coordinator;
      final media = await co.mediaInfo();
      if (!(media['CurrentURI'] ?? '').startsWith('x-rincon-queue:')) {
        await co.playQueue(_group?.leader.uuid ?? uuid);
      }
      await co.seekTrack(track);
      await co.play();
      unawaited(_poll());
      return true;
    } catch (e) {
      log.warn(_name, 'Sonos queue jump failed: $e');
      return false;
    }
  }

  void _emit(Map<String, Object?>? snapshot) {
    _snapshot = snapshot;
    if (_running) onSnapshot(snapshot);
  }
}
