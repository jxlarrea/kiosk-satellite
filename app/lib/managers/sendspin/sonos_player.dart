import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  /// Public artwork by track URI, for the streaming services whose art
  /// the speaker only proxies. The proxy fetches the image from the
  /// service itself and hangs when it cannot, which a speaker on a
  /// walled-off VLAN does often; the services answer the tablet
  /// directly, no key needed. Bounded: a queue's worth of tracks.
  static final Map<String, String?> _artCache = {};
  final Set<String> _artPending = {};

  /// A tablet kept off the internet cannot reach the services: after a
  /// few lookups in a row come back empty, the follower stops asking for
  /// a while and the speaker's proxy carries the art on its own.
  static int _artMisses = 0;
  static DateTime? _artHoldUntil;
  static const _artMissLimit = 3;
  static const _artHold = Duration(minutes: 15);

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
    _household = groups;
    final mine = groups.where((g) => g.contains(uuid)).firstOrNull;
    if (mine != null && (mine.leader.uuid != _group?.leader.uuid)) {
      log.info(
        _name,
        'Sonos group: ${mine.name} (coordinator ${mine.leader.name})',
      );
    }
    _group = mine;
  }

  /// Every group of the household as of the last topology read, for the
  /// chip's menu: the rooms not in this one are the ones it could take.
  List<SonosGroup> _household = const [];

  /// Rooms join and leave over the speaker's own transport.
  @override
  bool get hasGrouping => true;

  @override
  Future<RemoteGroup?> fetchGroup() async {
    try {
      await _refreshTopology();
      _topologyAt = DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      log.warn(_name, 'Sonos topology read failed: $e');
      return null;
    }
    return groupFrom(_household, uuid);
  }

  /// [uuid]'s group out of the household's [groups]: its coordinator
  /// leads, the rooms with it are in, every room of the other groups
  /// could join. The coordinator is not listed: it is the menu's title.
  static RemoteGroup? groupFrom(List<SonosGroup> groups, String uuid) {
    final mine = groups.where((g) => g.contains(uuid)).firstOrNull;
    if (mine == null) return null;
    final leader = mine.leader;
    return RemoteGroup(
      selfId: uuid,
      leaderId: leader.uuid,
      leaderName: leader.name,
      members: RemoteGroup.ordered([
        for (final g in groups)
          for (final m in g.members)
            if (m.uuid != leader.uuid)
              GroupMember(id: m.uuid, name: m.name, inGroup: g == mine),
      ]),
    );
  }

  /// A room joins this group by pointing its transport at the coordinator
  /// and leaves by becoming a coordinator of its own (this room's own row
  /// unchecked is this room leaving); either way the topology is read
  /// back at once so the chip and the queue follow.
  @override
  Future<bool> setGrouped(String id, bool grouped) async {
    final leader = _group?.leader;
    if (leader == null) return false;
    SonosMember? room;
    for (final g in _household) {
      for (final m in g.members) {
        if (m.uuid == id) room = m;
      }
    }
    if (room == null) return false;
    final client = clientFactory(room.host);
    try {
      if (grouped) {
        await client.join(leader.uuid);
      } else {
        await client.leaveGroup();
      }
      await _refreshTopology();
      _topologyAt = DateTime.now().millisecondsSinceEpoch;
      return true;
    } catch (e) {
      log.warn(_name, 'Sonos ${grouped ? 'join' : 'leave'} failed: $e');
      return false;
    } finally {
      client.close();
    }
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
    if (snap != null) _preferPublicArt(snap);
    // A poll that changed nothing stays quiet: the surfaces extrapolate
    // the position from the last report, and a fresh map every second
    // would rebuild the whole view (blur and all) under a finger. What
    // gets through: a new track, a state flip, a level change, and the
    // position when it has drifted from the extrapolation or the last
    // report is getting old.
    if (!_differs(_snapshot, snap)) return;
    _emit(snap);
  }

  /// Swap the speaker's art proxy for the service's own image where one
  /// is known, or start finding it, after which the next poll picks it
  /// up (or this one is re-emitted when the answer lands).
  void _preferPublicArt(Map<String, Object?> snap) {
    final art = '${snap['artworkUrl'] ?? ''}';
    final uri = '${snap['trackUri'] ?? ''}';
    if (!art.contains('/getaa?') || uri.isEmpty) return;
    final lookup = publicArtLookup(uri);
    if (lookup == null) return;
    if (_artCache.containsKey(uri)) {
      final found = _artCache[uri];
      if (found != null) snap['artworkUrl'] = found;
      return;
    }
    final hold = _artHoldUntil;
    if (hold != null) {
      if (DateTime.now().isBefore(hold)) return;
      _artHoldUntil = null;
      _artMisses = 0;
    }
    if (!_artPending.add(uri)) return;
    unawaited(
      fetchPublicArt(lookup).then((found) {
        _artPending.remove(uri);
        if (found == null) {
          if (++_artMisses >= _artMissLimit) {
            _artHoldUntil = DateTime.now().add(_artHold);
            log.info(_name, 'public artwork out of reach; using the speaker');
          }
          // Not cached: the next look may be after the hold, with the
          // network back.
          return;
        }
        _artMisses = 0;
        if (_artCache.length > 200) _artCache.clear();
        _artCache[uri] = found;
        final current = _snapshot;
        if (current != null && current['trackUri'] == uri) {
          _emit({...current, 'artworkUrl': found});
        }
      }),
    );
  }

  /// The service and track id behind a Sonos track URI, for the services
  /// with a public cover lookup: Spotify (`x-sonos-spotify:spotify:track:id`)
  /// and Deezer (`dzrs.trk.id` inside a Sonos HTTP URI). Null otherwise.
  @visibleForTesting
  static (String service, String id)? publicArtLookup(String trackUri) {
    final decoded = Uri.decodeFull(Uri.decodeFull(trackUri));
    final spotify = RegExp(r'spotify:track:([A-Za-z0-9]+)').firstMatch(decoded);
    if (spotify != null) return ('spotify', spotify[1]!);
    final deezer = RegExp(r'dzrs\.trk\.(\d+)').firstMatch(decoded);
    if (deezer != null) return ('deezer', deezer[1]!);
    return null;
  }

  /// The cover's public URL for [lookup], or null when the service does
  /// not answer. Spotify's oEmbed hands back a 300 pixel thumbnail whose
  /// id names the size; the same id with the 640 marker is the full
  /// cover.
  static Future<String?> fetchPublicArt((String, String) lookup) async {
    final (service, id) = lookup;
    final url = switch (service) {
      'spotify' => 'https://open.spotify.com/oembed?url=spotify%3Atrack%3A$id',
      'deezer' => 'https://api.deezer.com/track/$id',
      _ => null,
    };
    if (url == null) return null;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode != 200) return null;
      final body = jsonDecode(await response.transform(utf8.decoder).join());
      if (body is! Map) return null;
      if (service == 'spotify') {
        final thumb = '${body['thumbnail_url'] ?? ''}';
        if (thumb.isEmpty) return null;
        return thumb.replaceFirst('ab67616d00001e02', 'ab67616d0000b273');
      }
      final album = body['album'];
      if (album is! Map) return null;
      final cover = '${album['cover_xl'] ?? album['cover_big'] ?? ''}';
      return cover.isEmpty ? null : cover;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
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
    final trackUri = (position['TrackURI'] ?? '').trim();
    return {
      if (trackUri.isNotEmpty) 'trackUri': trackUri,
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
