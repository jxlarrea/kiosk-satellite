import 'dart:async';

import '../dlna/upnp_xml.dart' show unescapeXml;
import '../sendspin/sonos_client.dart';
import 'library_model.dart';

/// A Sonos household's own library, read from a speaker's ContentDirectory:
/// My Sonos favorites, Sonos playlists and the music library the speakers
/// index from a shared folder. Plays on the picked room's group.
class SonosLibrarySource extends LibrarySource {
  SonosLibrarySource({
    required this.hosts,
    SonosClient Function(String)? client,
  }) : _client = client ?? SonosClient.new;

  /// The known speakers: uuid to address, from the Sonos page.
  final Map<String, String> Function() hosts;

  final SonosClient Function(String host) _client;
  final _clients = <String, SonosClient>{};

  static const pageSize = 100;

  @override
  String get key => 'sonos';

  @override
  List<LibraryCategory> get categories => const [
    LibraryCategory('favorites', LibraryKind.other),
    LibraryCategory('sonos_playlists', LibraryKind.playlist),
    LibraryCategory('artists', LibraryKind.artist),
    LibraryCategory('albums', LibraryKind.album),
    LibraryCategory('tracks', LibraryKind.track),
  ];

  static const _containers = {
    'favorites': 'FV:2',
    'sonos_playlists': 'SQ:',
    'artists': 'A:ALBUMARTIST',
    'albums': 'A:ALBUM',
    'tracks': 'A:TRACKS',
  };

  /// The lists this household has anything in: most have favorites, few
  /// index a music library.
  @override
  Future<List<LibraryCategory>> availableCategories() async {
    final counts = await Future.wait([
      for (final c in categories)
        _browse(
          _containers[c.key]!,
          count: 1,
        ).then((r) => r.$2).catchError((Object _) => 0),
    ]);
    return [
      for (var i = 0; i < categories.length; i++)
        if (counts[i] > 0) categories[i],
    ];
  }

  SonosClient _at(String host) =>
      _clients.putIfAbsent(host, () => _client(host));

  /// Any known speaker answers for the whole household's library.
  SonosClient get _any {
    final known = hosts().values.where((h) => h.isNotEmpty);
    if (known.isEmpty) throw const LibraryError('no_sonos');
    return _at(known.first);
  }

  Future<(List<LibraryItem>, int)> _browse(
    String objectId, {
    int start = 0,
    int count = pageSize,
  }) async {
    try {
      final r = await _any.call(SonosClient.contentDirectory, 'Browse', {
        'ObjectID': objectId,
        'BrowseFlag': 'BrowseDirectChildren',
        'Filter': '*',
        'StartingIndex': '$start',
        'RequestedCount': '$count',
        'SortCriteria': '',
      });
      return (
        parseEntries(r['Result'] ?? '', baseUrl: _any.baseUrl),
        int.tryParse(r['TotalMatches'] ?? '') ?? 0,
      );
    } on LibraryError {
      rethrow;
    } catch (e) {
      throw LibraryError('$e');
    }
  }

  @override
  Future<LibraryPage> list(
    LibraryCategory category, {
    int offset = 0,
    bool favorites = false,
    LibrarySort? sort,
    bool albumArtists = false,
  }) async {
    final id = _containers[category.key];
    if (id == null) return LibraryPage.empty;
    final (items, total) = await _browse(id, start: offset);
    return LibraryPage(
      // A shortcut favorite opens the Sonos app's own browsing and has
      // nothing to play here.
      items: [
        for (final i in items)
          if (i.playable || i.expandable) i,
      ],
      more: offset + items.length < total,
    );
  }

  @override
  Future<LibraryDetail> open(LibraryItem item) async {
    final (items, _) = await _browse(item.id);
    return LibraryDetail(item: item, tracks: items);
  }

  @override
  bool needsSpeaker(String pick) => !pick.startsWith('sonos:');

  /// The client of the coordinator of the group [uuid] is in, where a
  /// queue and a transport belong.
  Future<(SonosClient, String)?> _coordinator(String uuid) async {
    final host = hosts()[uuid];
    if (host == null || host.isEmpty) return null;
    final groups = await _at(host).zoneGroups();
    for (final g in groups) {
      if (g.contains(uuid)) return (_at(g.leader.host), g.coordinator);
    }
    return (_at(host), uuid);
  }

  @override
  Future<String?> play(
    LibraryItem item,
    PlayMode mode, {
    required String pick,
    LibraryItem? within,
  }) async {
    if (!pick.startsWith('sonos:')) return 'no_speaker';
    final raw = item.raw as Map? ?? const {};
    final uri = '${raw['uri'] ?? ''}';
    final metadata = '${raw['meta'] ?? ''}';
    if (uri.isEmpty) return 'not_playable';
    try {
      final target = await _coordinator(pick.substring(6));
      if (target == null) return 'no_speaker';
      final (sonos, coordinator) = target;
      // A station plays on the transport itself; it never sits in a
      // queue.
      if (isStream(uri)) {
        await sonos.call(SonosClient.avTransport, 'SetAVTransportURI', {
          'InstanceID': '0',
          'CurrentURI': uri,
          'CurrentURIMetaData': metadata,
        });
        await sonos.play();
        return null;
      }
      final replace = mode == PlayMode.replace || mode == PlayMode.radio;
      if (replace) {
        await sonos.call(SonosClient.avTransport, 'RemoveAllTracksFromQueue', {
          'InstanceID': '0',
        });
      }
      final added = await sonos.call(SonosClient.avTransport, 'AddURIToQueue', {
        'InstanceID': '0',
        'EnqueuedURI': uri,
        'EnqueuedURIMetaData': metadata,
        'DesiredFirstTrackNumberEnqueued': '0',
        'EnqueueAsNext': mode == PlayMode.next || mode == PlayMode.now
            ? '1'
            : '0',
      });
      if (mode == PlayMode.next || mode == PlayMode.add) return null;
      final first = int.tryParse(added['FirstTrackNumberEnqueued'] ?? '') ?? 1;
      await sonos.playQueue(coordinator);
      await sonos.seekTrack(replace ? 1 : first);
      await sonos.play();
      return null;
    } catch (e) {
      return '$e';
    }
  }

  /// The room's own client, where its volume is, and the coordinator's,
  /// where the transport and its play mode are.
  Future<(SonosClient, SonosClient)?> _speaker(String pick) async {
    if (!pick.startsWith('sonos:')) return null;
    final uuid = pick.substring(6);
    final host = hosts()[uuid];
    if (host == null || host.isEmpty) return null;
    final target = await _coordinator(uuid);
    if (target == null) return null;
    return (_at(host), target.$1);
  }

  static const _modes = {
    'NORMAL': (false, 'off'),
    'REPEAT_ALL': (false, 'all'),
    'REPEAT_ONE': (false, 'one'),
    'SHUFFLE_NOREPEAT': (true, 'off'),
    'SHUFFLE': (true, 'all'),
    'SHUFFLE_REPEAT_ONE': (true, 'one'),
  };

  @override
  Future<SpeakerState?> speakerState(String pick) async {
    try {
      final speaker = await _speaker(pick);
      if (speaker == null) return null;
      final (room, coordinator) = speaker;
      final volume = await room.volume();
      final mode = _modes[(await coordinator.transportSettings())['PlayMode']];
      return SpeakerState(volume: volume, shuffle: mode?.$1, repeat: mode?.$2);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> setPlayModes(
    String pick, {
    bool? shuffle,
    String? repeat,
  }) async {
    try {
      final speaker = await _speaker(pick);
      if (speaker == null) return false;
      final coordinator = speaker.$2;
      final now =
          _modes[(await coordinator.transportSettings())['PlayMode']] ??
          (false, 'off');
      final want = (shuffle ?? now.$1, repeat ?? now.$2);
      final mode = _modes.entries.firstWhere((e) => e.value == want).key;
      await coordinator.setPlayMode(mode);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> setSpeakerVolume(String pick, int percent) async {
    try {
      final speaker = await _speaker(pick);
      if (speaker == null) return false;
      await speaker.$1.setVolume(percent);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> stopSpeaker(String pick) async {
    try {
      final speaker = await _speaker(pick);
      if (speaker == null) return false;
      await speaker.$2.stop();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> clearSpeaker(String pick) async {
    try {
      final speaker = await _speaker(pick);
      if (speaker == null) return false;
      final coordinator = speaker.$2;
      await coordinator.stop();
      await coordinator.call(
        SonosClient.avTransport,
        'RemoveAllTracksFromQueue',
        {'InstanceID': '0'},
      );
      return true;
    } catch (_) {
      return stopSpeaker(pick);
    }
  }

  @override
  void dispose() {
    for (final c in _clients.values) {
      c.close();
    }
    _clients.clear();
  }

  /// Whether [uri] is a live stream the transport plays directly.
  static bool isStream(String uri) => const [
    'x-sonosapi-radio:',
    'x-sonosapi-stream:',
    'x-sonosapi-hls:',
    'x-sonosapi-hls-static:',
    'x-rincon-mp3radio:',
    'aac:',
    'hls-radio:',
  ].any(uri.startsWith);

  /// The items and containers of a DIDL-Lite document. A favorite carries
  /// the metadata to play it back from in r:resMD, and what it is in that
  /// document's class.
  static List<LibraryItem> parseEntries(
    String didl, {
    required String baseUrl,
  }) {
    final out = <LibraryItem>[];
    for (final m in RegExp(
      r'<(item|container)\s([^>]*)>([\s\S]*?)</\1>',
    ).allMatches(didl)) {
      final container = m[1] == 'container';
      final attrs = m[2]!;
      final body = m[3]!;
      String text(String tag) {
        final t = RegExp(
          '<$tag(?:\\s[^>]*)?>([\\s\\S]*?)</$tag>',
        ).firstMatch(body)?[1];
        return t == null ? '' : unescapeXml(t).trim();
      }

      final id = unescapeXml(
        RegExp(r'\bid="([^"]*)"').firstMatch(attrs)?[1] ?? '',
      );
      final res = text('res');
      final resMd = text('r:resMD');
      var cls = text('upnp:class');
      // A favorite's own class says only that it is one; what it plays is
      // in its metadata.
      if (cls.contains('sonos-favorite') && resMd.isNotEmpty) {
        cls =
            RegExp(r'<upnp:class>([^<]*)</upnp:class>').firstMatch(resMd)?[1] ??
            cls;
      }
      final art = text('upnp:albumArtURI');
      final kind = cls.contains('audioBroadcast')
          ? LibraryKind.radio
          : cls.contains('musicArtist') || cls.contains('person')
          ? LibraryKind.artist
          : cls.contains('musicAlbum')
          ? LibraryKind.album
          : cls.contains('playlistContainer')
          ? LibraryKind.playlist
          : cls.contains('audioItem')
          ? LibraryKind.track
          : container
          ? LibraryKind.folder
          : LibraryKind.other;
      final duration = RegExp(
        r'<res[^>]*\sduration="([^"]*)"',
      ).firstMatch(body)?[1];
      final favorite = id.startsWith('FV:');
      out.add(
        LibraryItem(
          id: id,
          kind: kind,
          title: text('dc:title'),
          subtitle: favorite ? text('r:description') : text('dc:creator'),
          art: art.isEmpty
              ? null
              : art.startsWith('http')
              ? art
              : '$baseUrl${art.startsWith('/') ? '' : '/'}$art',
          playable: res.isNotEmpty,
          // A favorite plays as one piece, even an album or a playlist.
          expandable: container && !favorite,
          durationMs: _duration(duration),
          raw: {
            'uri': res,
            // A library entry's metadata is the entry itself.
            'meta': resMd.isNotEmpty
                ? resMd
                : '<DIDL-Lite xmlns:dc="http://purl.org/dc/elements/1.1/" '
                      'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" '
                      'xmlns:r="urn:schemas-rinconnetworks-com:metadata-1-0/" '
                      'xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/">'
                      '<${m[1]} $attrs>$body</${m[1]}></DIDL-Lite>',
          },
        ),
      );
    }
    return out;
  }

  static int? _duration(String? hms) {
    if (hms == null || hms.isEmpty) return null;
    final parts = hms.split(':');
    if (parts.length != 3) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final s = double.tryParse(parts[2]) ?? 0;
    final ms = ((h * 3600 + m * 60) * 1000 + s * 1000).round();
    return ms > 0 ? ms : null;
  }
}
