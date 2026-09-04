import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../dlna/upnp_xml.dart';

/// One Sonos speaker's local UPnP interface, port 1400: SOAP calls to its
/// AVTransport, RenderingControl, GroupRenderingControl, ContentDirectory
/// and ZoneGroupTopology services, plus the discovery that finds speakers
/// and the parsers for what they answer. No events: the follower polls,
/// which works across VLANs where a speaker could never reach a callback
/// on the tablet and a speaker answers a call in a few milliseconds.
class SonosClient {
  SonosClient(this.host);

  /// The speaker's address, without scheme or port.
  final String host;

  static const port = 1400;

  static const avTransport = 'urn:schemas-upnp-org:service:AVTransport:1';
  static const renderingControl =
      'urn:schemas-upnp-org:service:RenderingControl:1';
  static const groupRendering =
      'urn:schemas-upnp-org:service:GroupRenderingControl:1';
  static const contentDirectory =
      'urn:schemas-upnp-org:service:ContentDirectory:1';
  static const zoneGroupTopology =
      'urn:schemas-upnp-org:service:ZoneGroupTopology:1';

  static const _paths = {
    avTransport: '/MediaRenderer/AVTransport/Control',
    renderingControl: '/MediaRenderer/RenderingControl/Control',
    groupRendering: '/MediaRenderer/GroupRenderingControl/Control',
    contentDirectory: '/MediaServer/ContentDirectory/Control',
    zoneGroupTopology: '/ZoneGroupTopology/Control',
  };

  String get baseUrl => 'http://$host:$port';

  /// One connection pool per speaker: a poll makes a few calls a second
  /// for as long as the room is followed, and a fresh client (and TCP
  /// handshake) for each would cost the tablet more than the speaker.
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5)
    ..idleTimeout = const Duration(seconds: 15);

  /// Drop the pooled connections. The client is unusable after this.
  void close() => _client.close(force: true);

  /// One SOAP action. Returns the response's argument elements by name,
  /// unescaped. Throws on a transport error, a non-200 answer or a UPnP
  /// fault, with the fault's error code in the message.
  Future<Map<String, String>> call(
    String service,
    String action, [
    Map<String, String> args = const {},
  ]) async {
    final body =
        '<?xml version="1.0" encoding="utf-8"?>'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
        's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
        '<s:Body><u:$action xmlns:u="$service">'
        '${args.entries.map((e) => '<${e.key}>${escapeXml(e.value)}</${e.key}>').join()}'
        '</u:$action></s:Body></s:Envelope>';
    try {
      final request = await _client.postUrl(
        Uri.parse('$baseUrl${_paths[service]}'),
      );
      request.headers.set('Content-Type', 'text/xml; charset="utf-8"');
      request.headers.set('SOAPACTION', '"$service#$action"');
      // A plain body with its length: the speaker's HTTP server does not
      // read a chunked request and without the length Dart sends one.
      final bytes = utf8.encode(body);
      request.headers.contentLength = bytes.length;
      request.add(bytes);
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        final code = RegExp(
          r'<errorCode>(\d+)</errorCode>',
        ).firstMatch(text)?[1];
        throw SonosError(
          '$action failed: HTTP ${response.statusCode}'
          '${code == null ? '' : ', UPnP error $code'}',
          code: int.tryParse(code ?? ''),
        );
      }
      return parseSoapArgs(text);
    } on SonosError {
      rethrow;
    } catch (e) {
      throw SonosError('$action failed: $e');
    }
  }

  // ── AVTransport ────────────────────────────────────────────────────

  Future<Map<String, String>> transportInfo() =>
      call(avTransport, 'GetTransportInfo', {'InstanceID': '0'});

  Future<Map<String, String>> positionInfo() =>
      call(avTransport, 'GetPositionInfo', {'InstanceID': '0'});

  Future<Map<String, String>> mediaInfo() =>
      call(avTransport, 'GetMediaInfo', {'InstanceID': '0'});

  Future<Map<String, String>> transportSettings() =>
      call(avTransport, 'GetTransportSettings', {'InstanceID': '0'});

  Future<void> play() =>
      call(avTransport, 'Play', {'InstanceID': '0', 'Speed': '1'});

  Future<void> pause() => call(avTransport, 'Pause', {'InstanceID': '0'});

  Future<void> stop() => call(avTransport, 'Stop', {'InstanceID': '0'});

  Future<void> next() => call(avTransport, 'Next', {'InstanceID': '0'});

  Future<void> previous() => call(avTransport, 'Previous', {'InstanceID': '0'});

  Future<void> seekTime(Duration position) => call(avTransport, 'Seek', {
    'InstanceID': '0',
    'Unit': 'REL_TIME',
    'Target': formatUpnpTime(position),
  });

  /// Jump to the queue's [track], 1-based.
  Future<void> seekTrack(int track) => call(avTransport, 'Seek', {
    'InstanceID': '0',
    'Unit': 'TRACK_NR',
    'Target': '$track',
  });

  Future<void> setPlayMode(String mode) => call(avTransport, 'SetPlayMode', {
    'InstanceID': '0',
    'NewPlayMode': mode,
  });

  /// Point the transport at the speaker's own queue, the URI Sonos uses
  /// for it: what a queue jump needs when a station or a line-in was
  /// playing instead.
  Future<void> playQueue(String coordinatorUuid) =>
      call(avTransport, 'SetAVTransportURI', {
        'InstanceID': '0',
        'CurrentURI': 'x-rincon-queue:$coordinatorUuid#0',
        'CurrentURIMetaData': '',
      });

  // ── Grouping ───────────────────────────────────────────────────────

  /// Join the group [coordinatorUuid] leads: the room's transport points
  /// at the coordinator and plays whatever it plays.
  Future<void> join(String coordinatorUuid) =>
      call(avTransport, 'SetAVTransportURI', {
        'InstanceID': '0',
        'CurrentURI': 'x-rincon:$coordinatorUuid',
        'CurrentURIMetaData': '',
      });

  /// Leave the group: the room becomes the coordinator of a group of its
  /// own, silent until told to play something.
  Future<void> leaveGroup() => call(
    avTransport,
    'BecomeCoordinatorOfStandaloneGroup',
    {'InstanceID': '0'},
  );

  // ── Volume ─────────────────────────────────────────────────────────

  Future<int?> volume() async {
    final r = await call(renderingControl, 'GetVolume', {
      'InstanceID': '0',
      'Channel': 'Master',
    });
    return int.tryParse(r['CurrentVolume'] ?? '');
  }

  Future<void> setVolume(int level) => call(renderingControl, 'SetVolume', {
    'InstanceID': '0',
    'Channel': 'Master',
    'DesiredVolume': '${level.clamp(0, 100)}',
  });

  Future<bool?> mute() async {
    final r = await call(renderingControl, 'GetMute', {
      'InstanceID': '0',
      'Channel': 'Master',
    });
    return switch (r['CurrentMute']) {
      '1' => true,
      '0' => false,
      _ => null,
    };
  }

  Future<void> setMute(bool muted) => call(renderingControl, 'SetMute', {
    'InstanceID': '0',
    'Channel': 'Master',
    'DesiredMute': muted ? '1' : '0',
  });

  Future<bool?> groupMute() async {
    final r = await call(groupRendering, 'GetGroupMute', {'InstanceID': '0'});
    return switch (r['CurrentMute']) {
      '1' => true,
      '0' => false,
      _ => null,
    };
  }

  Future<void> setGroupMute(bool muted) => call(
    groupRendering,
    'SetGroupMute',
    {'InstanceID': '0', 'DesiredMute': muted ? '1' : '0'},
  );

  Future<int?> groupVolume() async {
    final r = await call(groupRendering, 'GetGroupVolume', {'InstanceID': '0'});
    return int.tryParse(r['CurrentVolume'] ?? '');
  }

  Future<void> setGroupVolume(int level) => call(
    groupRendering,
    'SetGroupVolume',
    {'InstanceID': '0', 'DesiredVolume': '${level.clamp(0, 100)}'},
  );

  // ── Queue ──────────────────────────────────────────────────────────

  /// The speaker's queue as DIDL items, [start] onward.
  Future<(List<Map<String, String>> items, int total)> browseQueue({
    int start = 0,
    int count = 200,
  }) async {
    final r = await call(contentDirectory, 'Browse', {
      'ObjectID': 'Q:0',
      'BrowseFlag': 'BrowseDirectChildren',
      'Filter': '*',
      'StartingIndex': '$start',
      'RequestedCount': '$count',
      'SortCriteria': '',
    });
    return (
      parseDidlItems(r['Result'] ?? ''),
      int.tryParse(r['TotalMatches'] ?? '') ?? 0,
    );
  }

  // ── Topology ───────────────────────────────────────────────────────

  /// Every group in the household this speaker belongs to.
  Future<List<SonosGroup>> zoneGroups() async {
    final r = await call(zoneGroupTopology, 'GetZoneGroupState');
    return parseZoneGroups(r['ZoneGroupState'] ?? '');
  }

  // ── Parsers ────────────────────────────────────────────────────────

  /// The groups in a ZoneGroupState document: each with its coordinator
  /// and its members, invisible ones (a stereo pair's second speaker, a
  /// subwoofer) left out.
  static List<SonosGroup> parseZoneGroups(String xml) {
    final groups = <SonosGroup>[];
    for (final g in RegExp(
      r'<ZoneGroup\s([^>]*)>([\s\S]*?)</ZoneGroup>',
    ).allMatches(xml)) {
      final coordinator = _attr(g[1]!, 'Coordinator') ?? '';
      final members = <SonosMember>[];
      for (final m in RegExp(
        r'<ZoneGroupMember\s([^>]*?)/?>',
      ).allMatches(g[2]!)) {
        final attrs = m[1]!;
        if (_attr(attrs, 'Invisible') == '1') continue;
        final uuid = _attr(attrs, 'UUID') ?? '';
        final location = _attr(attrs, 'Location') ?? '';
        final host = Uri.tryParse(location)?.host ?? '';
        if (uuid.isEmpty || host.isEmpty) continue;
        members.add(
          SonosMember(
            uuid: uuid,
            host: host,
            name: unescapeXml(_attr(attrs, 'ZoneName') ?? uuid),
          ),
        );
      }
      if (members.isEmpty) continue;
      // The coordinator leads the member list, so a group's name reads
      // the way the Sonos app shows it.
      members.sort((a, b) {
        if (a.uuid == coordinator) return -1;
        if (b.uuid == coordinator) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      groups.add(SonosGroup(coordinator: coordinator, members: members));
    }
    return groups;
  }

  /// The items of a DIDL-Lite document: title, artist, album, art, the
  /// stream's own text for a radio, the resource's duration and the
  /// item's id and class.
  static List<Map<String, String>> parseDidlItems(String didl) {
    final out = <Map<String, String>>[];
    for (final m in RegExp(
      r'<item\s([^>]*)>([\s\S]*?)</item>',
    ).allMatches(didl)) {
      final attrs = m[1]!;
      final body = m[2]!;
      String? text(String tag) {
        final t = RegExp(
          '<$tag(?:\\s[^>]*)?>([\\s\\S]*?)</$tag>',
        ).firstMatch(body)?[1];
        final v = t == null ? null : unescapeXml(t).trim();
        return v == null || v.isEmpty ? null : v;
      }

      final duration = RegExp(
        r'<res[^>]*\sduration="([^"]*)"',
      ).firstMatch(body)?[1];
      final res = RegExp(r'<res[^>]*>([^<]*)</res>').firstMatch(body)?[1];
      out.add({
        if (res != null && res.trim().isNotEmpty)
          'uri': unescapeXml(res.trim()),
        'id': unescapeXml(_attr(attrs, 'id') ?? ''),
        'title': ?text('dc:title'),
        'artist': ?text('dc:creator'),
        'album': ?text('upnp:album'),
        'art': ?text('upnp:albumArtURI'),
        'streamContent': ?text('r:streamContent'),
        'class': ?text('upnp:class'),
        if (duration != null && duration.isNotEmpty) 'duration': duration,
      });
    }
    return out;
  }

  static String? _attr(String attrs, String name) {
    final m = RegExp('\\b$name="([^"]*)"').firstMatch(attrs);
    return m == null ? null : unescapeXml(m[1]!);
  }

  // ── Discovery ──────────────────────────────────────────────────────

  /// Speakers answering an SSDP search on this network: their hosts.
  /// Multicast stays on the tablet's own VLAN, so a speaker elsewhere is
  /// added by address instead.
  static Future<Set<String>> discover({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final hosts = <String>{};
    RawDatagramSocket? sock;
    try {
      sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      sock.broadcastEnabled = true;
      const search =
          'M-SEARCH * HTTP/1.1\r\n'
          'HOST: 239.255.255.250:1900\r\n'
          'MAN: "ssdp:discover"\r\n'
          'MX: 1\r\n'
          'ST: urn:schemas-upnp-org:device:ZonePlayer:1\r\n'
          '\r\n';
      final done = Completer<void>();
      sock.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = sock!.receive();
        if (dg == null) return;
        final text = String.fromCharCodes(dg.data);
        if (!text.toLowerCase().contains('zoneplayer')) return;
        final location = RegExp(
          r'^LOCATION:\s*(.+?)\s*$',
          multiLine: true,
          caseSensitive: false,
        ).firstMatch(text)?[1];
        final host = Uri.tryParse(location ?? '')?.host;
        if (host != null && host.isNotEmpty) hosts.add(host);
      });
      final target = InternetAddress('239.255.255.250');
      sock.send(search.codeUnits, target, 1900);
      Timer(const Duration(milliseconds: 300), () {
        try {
          sock?.send(search.codeUnits, target, 1900);
        } catch (_) {}
      });
      Timer(timeout, () {
        if (!done.isCompleted) done.complete();
      });
      await done.future;
    } catch (_) {
      // No network or multicast refused: nothing found is the answer.
    } finally {
      sock?.close();
    }
    return hosts;
  }
}

class SonosError implements Exception {
  SonosError(this.message, {this.code});

  final String message;

  /// The UPnP error code when the speaker answered with a fault: 701 is
  /// "transition not available", what a Pause on a radio stream gets.
  final int? code;

  @override
  String toString() => message;
}

/// One speaker in a household, as the topology names it.
class SonosMember {
  const SonosMember({
    required this.uuid,
    required this.host,
    required this.name,
  });

  final String uuid;
  final String host;
  final String name;
}

/// One group of speakers playing as one, its coordinator first.
class SonosGroup {
  const SonosGroup({required this.coordinator, required this.members});

  final String coordinator;
  final List<SonosMember> members;

  bool contains(String uuid) => members.any((m) => m.uuid == uuid);

  SonosMember get leader => members.firstWhere(
    (m) => m.uuid == coordinator,
    orElse: () => members.first,
  );

  /// The group's name as the Sonos app shows it: the coordinator's room
  /// and, past it, every other room joined with a plus.
  String get name => members.map((m) => m.name).join(' + ');
}
