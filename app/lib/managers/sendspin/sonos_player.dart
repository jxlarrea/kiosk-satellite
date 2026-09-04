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
    this.showInputs = false,
    this.clientFactory = SonosClient.new,
  });

  /// Whether the volume slider sets the whole group's volume while the
  /// room plays in one or only the room's own.
  final bool groupVolume;

  /// Whether a TV or line-in input shows as a card named after it, or
  /// the room reads as idle while one plays.
  final bool showInputs;

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
  String _repeat = 'off';
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
      // A station's name and logo live on the station, not the track:
      // the track metadata of a radio stream names the song (or the
      // stream file) and carries no art, while the media the speaker was
      // given (GetMediaInfo) is the station item with both. Read once
      // per stream, when the track brings no art of its own.
      final trackUri = (position['TrackURI'] ?? '').trim();
      final trackArt = SonosClient.parseDidlItems(
        position['TrackMetaData'] ?? '',
      ).firstOrNull?['art'];
      // The media the speaker was given, read once per track: whether it
      // plays from its queue (a station or a line-in does not, and then
      // there is nothing to skip to, whatever the track metadata says)
      // and, for a track with no art of its own, the station's name and
      // logo.
      if (trackUri.isNotEmpty && _mediaFor != trackUri) {
        _mediaFor = trackUri;
        _station = null;
        try {
          final media = await co.mediaInfo();
          final currentUri = (media['CurrentURI'] ?? '').trim();
          _inQueue = currentUri.startsWith('x-rincon-queue:');
          _appSession = appSession(currentUri);
          if (trackArt == null) _station = stationFrom(media, co.host);
          // The item My Sonos would hold: the station the speaker was
          // given, or the track itself when it plays from the queue. An
          // app's session is the app's, and My Sonos cannot keep it.
          _item = _appSession
              ? null
              : _inQueue
              ? _FavoriteItem(
                  uri: trackUri,
                  metadata: position['TrackMetaData'] ?? '',
                )
              : _FavoriteItem(
                  uri: currentUri,
                  metadata: media['CurrentURIMetaData'] ?? '',
                );
          await _readFavorite(co);
        } catch (_) {
          // No media info: the next poll asks again.
          _mediaFor = '';
        }
      }
      if (trackArt != null) _station = null;
      // The play mode and the volume change rarely and cost a call each:
      // read them at the start, then every few ticks.
      if (_ticks % 5 == 0) {
        final settings = await co.transportSettings();
        _shuffle = (settings['PlayMode'] ?? '').contains('SHUFFLE');
        _repeat = repeatOfMode(settings['PlayMode'] ?? '');
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
      repeat: _repeat,
      volume: _volume,
      muted: _muted,
      sawPlayback: _sawPlayback,
      station: _station,
      inQueue: _inQueue,
      appSession: _appSession,
      favorite: _item == null ? null : _favoriteId != null,
      showInputs: showInputs,
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

  /// The station the speaker plays and whether it plays from its queue
  /// or from an app's session, read from its media info for the track
  /// URI in [_mediaFor], and the item My Sonos would hold for it with
  /// the favorite's id when it does.
  SonosStation? _station;
  bool _inQueue = true;
  bool _appSession = false;
  String _mediaFor = '';
  _FavoriteItem? _item;
  String? _favoriteId;

  /// Look the playing item up in My Sonos.
  Future<void> _readFavorite(SonosClient co) async {
    final item = _item;
    if (item == null || item.uri.isEmpty) {
      _favoriteId = null;
      return;
    }
    final favorites = await co.browseFavorites();
    _favoriteId = favorites
        .where((f) => sameItem(f['uri'] ?? '', item.uri))
        .map((f) => f['id'] ?? '')
        .where((id) => id.isNotEmpty)
        .firstOrNull;
  }

  /// Whether two Sonos resource URIs name the same item: the resource
  /// itself and the service (sid), the session and flag parameters
  /// aside, which the household rewrites between a favorite and a play.
  @visibleForTesting
  static bool sameItem(String a, String b) {
    String key(String uri) {
      final q = uri.indexOf('?');
      final path = (q < 0 ? uri : uri.substring(0, q)).toLowerCase();
      final sid = RegExp(r'[?&]sid=(\d+)').firstMatch(uri)?.group(1) ?? '';
      return '$path|$sid';
    }

    return a.isNotEmpty && key(a) == key(b);
  }

  /// My Sonos is the household's own library, and it cannot keep an
  /// app's session, so the heart leaves the view for one.
  @override
  bool get hasFavorites => !_appSession;

  /// Put the playing item in My Sonos or take it out, and republish
  /// with the heart as the household now has it.
  @override
  Future<bool> setFavorite(bool on) async {
    final item = _item;
    if (item == null || item.uri.isEmpty) return false;
    try {
      final co = _coordinator;
      if (on) {
        if (_favoriteId == null) {
          final snap = _snapshot ?? const <String, Object?>{};
          final meta = SonosClient.parseDidlItems(item.metadata).firstOrNull;
          await co.addFavorite(
            title: meta?['title'] ?? '${snap['album'] ?? snap['title'] ?? ''}',
            uri: item.uri,
            metadata: item.metadata,
            art: meta?['art'] ?? '',
            description: serviceName(item.uri),
          );
        }
      } else if (_favoriteId != null) {
        await co.removeFavorite(_favoriteId!);
      }
      await _readFavorite(co);
      final current = _snapshot;
      if (current != null) _emit({...current, 'favorite': _favoriteId != null});
      return true;
    } catch (e) {
      log.warn(_name, 'Sonos favorite failed: $e');
      return false;
    }
  }

  /// The input a Sonos resource URI stands for, when it is one: the home
  /// theater input of a soundbar (HDMI ARC, optical), or a line-in. Null
  /// for anything that is music.
  @visibleForTesting
  static String? inputOf(String uri) {
    if (uri.startsWith('x-sonos-htastream:')) return 'TV';
    if (uri.startsWith('x-rincon-stream:')) return 'Line-in';
    return null;
  }

  /// Whether a Sonos resource URI is an app's session on the speaker:
  /// Spotify Connect or AirPlay, which the speaker plays as a virtual
  /// line-in. The app keeps the queue, and the speaker passes next and
  /// previous on to it.
  @visibleForTesting
  static bool appSession(String uri) => uri.startsWith('x-sonos-vli:');

  /// The service a Sonos resource URI plays from, as My Sonos names it
  /// under a favorite.
  @visibleForTesting
  static String serviceName(String uri) {
    final scheme = uri.split(':').first;
    return switch (scheme) {
      'x-sonosapi-radio' => 'Sonos Radio',
      'x-sonosapi-stream' => 'TuneIn',
      'x-sonos-spotify' => 'Spotify',
      'x-sonos-http' when uri.contains('DZR') => 'Deezer',
      'x-sonosapi-hls' => 'Apple Music',
      _ => '',
    };
  }

  /// The station in a GetMediaInfo answer: the name and logo of the item
  /// the speaker was given to play, the logo made absolute on the
  /// speaker when it is a path. Null when the item carries neither.
  @visibleForTesting
  static SonosStation? stationFrom(Map<String, String> media, String host) {
    final item = SonosClient.parseDidlItems(
      media['CurrentURIMetaData'] ?? '',
    ).firstOrNull;
    if (item == null) return null;
    final name = item['title'] ?? '';
    final art = item['art'] ?? '';
    if (name.isEmpty && art.isEmpty) return null;
    return SonosStation(
      name: name,
      art: art.isEmpty
          ? null
          : art.startsWith('http')
          ? art
          : 'http://$host:${SonosClient.port}${art.startsWith('/') ? '' : '/'}$art',
    );
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
    'favorite',
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
    String repeat = 'off',
    int? volume,
    bool? muted,
    bool sawPlayback = false,
    SonosStation? station,
    bool inQueue = true,
    bool appSession = false,
    bool? favorite,
    bool showInputs = false,
  }) {
    final state = transport['CurrentTransportState'] ?? '';
    final playing = state == 'PLAYING' || state == 'TRANSITIONING';
    final paused = state == 'PAUSED_PLAYBACK';
    if (!playing && !paused && !sawPlayback) return null;
    // A TV or line-in input: nothing to show but the input's name, and
    // by default not even that, so a soundbar under a television does
    // not hold the screensaver off with its own serial as the title.
    final input = inputOf(position['TrackURI'] ?? '');
    if (input != null) {
      if (!showInputs) return null;
      return {
        'trackUri': (position['TrackURI'] ?? '').trim(),
        'title': input,
        'positionMs': 0,
        'receivedAt': DateTime.now().millisecondsSinceEpoch,
        'playing': playing,
        'shuffle': false,
        'repeat': 'off',
        'trackNumber': 0,
        'stream': true,
        'supportedCommands': ['play', 'pause', 'stop', 'volume'],
        'volume': ?volume,
        'muted': ?muted,
      };
    }
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
    // The station's own name, over a track title that is the stream's
    // file name or nothing at all.
    final stationName = station?.name ?? '';
    if (stationName.isNotEmpty && (title.isEmpty || _looksLikeFile(title))) {
      title = stationName;
    }
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
    final art = item['art'] ?? station?.art ?? '';
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
      'repeat': repeat,
      'favorite': ?favorite,
      'trackNumber': tracks,
      'stream': isStream,
      'supportedCommands': [
        'play',
        'pause',
        'stop',
        // A stream has nothing to skip to, and neither does anything
        // played outside the speaker's queue, unless an app plays its
        // own queue through the speaker and takes the skips.
        if (!isStream && (inQueue || appSession)) 'next',
        if (!isStream && (inQueue || appSession)) 'previous',
        if (durationMs > 0) 'seek',
        'shuffle',
        'repeat',
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

  /// The repeat behind a Sonos play mode: 'one', 'all' or 'off'. The
  /// plain SHUFFLE mode repeats all; SHUFFLE_NOREPEAT does not.
  @visibleForTesting
  static String repeatOfMode(String mode) {
    if (mode.contains('REPEAT_ONE')) return 'one';
    if (mode == 'REPEAT_ALL' || mode == 'SHUFFLE') return 'all';
    return 'off';
  }

  /// The Sonos play mode for a shuffle and repeat pair.
  @visibleForTesting
  static String modeFor({required bool shuffle, required String repeat}) =>
      switch ((shuffle, repeat)) {
        (true, 'one') => 'SHUFFLE_REPEAT_ONE',
        (true, 'all') => 'SHUFFLE',
        (true, _) => 'SHUFFLE_NOREPEAT',
        (false, 'one') => 'REPEAT_ONE',
        (false, 'all') => 'REPEAT_ALL',
        (false, _) => 'NORMAL',
      };

  @override
  Future<bool> setShuffle(bool on) async {
    try {
      final co = _coordinator;
      final settings = await co.transportSettings();
      final repeat = repeatOfMode(settings['PlayMode'] ?? 'NORMAL');
      await co.setPlayMode(modeFor(shuffle: on, repeat: repeat));
      _shuffle = on;
      _repeat = repeat;
      unawaited(_poll());
      return true;
    } catch (e) {
      log.warn(_name, 'Sonos shuffle failed: $e');
      return false;
    }
  }

  @override
  Future<bool> setRepeat(String mode) async {
    try {
      final co = _coordinator;
      final settings = await co.transportSettings();
      final shuffle = (settings['PlayMode'] ?? '').contains('SHUFFLE');
      await co.setPlayMode(modeFor(shuffle: shuffle, repeat: mode));
      _shuffle = shuffle;
      _repeat = mode;
      unawaited(_poll());
      return true;
    } catch (e) {
      log.warn(_name, 'Sonos repeat failed: $e');
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
  /// track number. A station, a line-in or an app's session plays
  /// outside the queue, and the panel shows that as nothing queued.
  @override
  Future<RemoteQueue?> fetchQueue() async {
    try {
      final co = _coordinator;
      final media = await co.mediaInfo();
      final inQueue = (media['CurrentURI'] ?? '').startsWith('x-rincon-queue:');
      // A station, a line-in or an app's session plays outside the
      // queue: the queue the speaker still holds is not what is
      // playing, so the panel says nothing is queued.
      if (!inQueue) return const RemoteQueue(items: [], upNext: 0);
      final (items, total) = await co.browseQueue();
      final current = _snapshot?['trackNumber'] as int? ?? 0;
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
            // The row's thumbnail: the service's own image where the
            // cover lookup has found it for this track, else the
            // speaker's art proxy, which the panel fetches on a short
            // leash since it can hang on an image it cannot reach.
            'artworkUrl': ?_queueArt(it, co.host),
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

  String? _queueArt(Map<String, String> item, String host) {
    final uri = item['uri'] ?? '';
    final found = uri.isEmpty ? null : _artCache[uri];
    if (found != null) return found;
    final art = item['art'] ?? '';
    if (art.isEmpty) return null;
    return art.startsWith('http')
        ? art
        : 'http://$host:${SonosClient.port}${art.startsWith('/') ? '' : '/'}$art';
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

/// A stream's file name standing in for a title: no spaces, an extension
/// or a scheme, the way a speaker names a stream it was handed with no
/// metadata of its own.
bool _looksLikeFile(String title) =>
    !title.contains(' ') &&
    (title.contains('://') || RegExp(r'\.[A-Za-z0-9]{2,4}$').hasMatch(title));

/// The station a Sonos was given to play: its name and its logo, from the
/// speaker's media info.
class SonosStation {
  const SonosStation({required this.name, required this.art});

  final String name;
  final String? art;
}

/// The playing item as My Sonos would keep it: its resource URI and the
/// metadata document the speaker plays it from.
class _FavoriteItem {
  const _FavoriteItem({required this.uri, required this.metadata});

  final String uri;
  final String metadata;
}
