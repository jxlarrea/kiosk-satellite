import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/sendspin/sonos_client.dart';
import 'package:kiosk_satellite/managers/sendspin/sonos_player.dart';

// Captured from an Era 100 SL (software 96.1) on 2026-09-02.
const _topology =
    '<ZoneGroupState><ZoneGroups>'
    '<ZoneGroup Coordinator="RINCON_74CA60A4CCD001400" ID="RINCON_74CA60A4CCD001400:49279019">'
    '<ZoneGroupMember UUID="RINCON_74CA60A4CCD001400" Location="http://10.11.12.70:1400/xml/device_description.xml" ZoneName="Office" Icon="" Configuration="1" SoftwareVersion="96.1-79270" SWGen="2" WirelessMode="1" AirPlayEnabled="1" IdleState="1"/>'
    '</ZoneGroup>'
    '<ZoneGroup Coordinator="RINCON_AAA" ID="RINCON_AAA:12">'
    '<ZoneGroupMember UUID="RINCON_BBB" Location="http://10.11.12.72:1400/xml/device_description.xml" ZoneName="Living Room"/>'
    '<ZoneGroupMember UUID="RINCON_AAA" Location="http://10.11.12.71:1400/xml/device_description.xml" ZoneName="Kitchen &amp; Dining"/>'
    '<ZoneGroupMember UUID="RINCON_SUB" Location="http://10.11.12.73:1400/xml/device_description.xml" ZoneName="Kitchen &amp; Dining" Invisible="1"/>'
    '</ZoneGroup>'
    '</ZoneGroups><VanishedDevices></VanishedDevices></ZoneGroupState>';

const _trackMeta =
    '<DIDL-Lite xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" xmlns:r="urn:schemas-rinconnetworks-com:metadata-1-0/" xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/">'
    '<item id="-1" parentID="-1"><res protocolInfo="http-get:*:audio/mp4:*">x-sonos-http:sonos%3aa78b8e1eb-DZR%3a28.mp4?sid=303&amp;flags=0&amp;sn=1</res>'
    '<upnp:albumArtURI>https://sonosradio.imgix.net/station-images/054fdfb6.jpeg?w=200&amp;auto=format</upnp:albumArtURI>'
    '<upnp:class>object.item.audioItem.musicTrack</upnp:class><dc:title>drop dead</dc:title><dc:creator>Olivia Rodrigo</dc:creator>'
    '<r:trackGain>4.000000</r:trackGain></item></DIDL-Lite>';

const _queueDidl =
    '<DIDL-Lite xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/">'
    '<item id="Q:0/1" parentID="Q:0" restricted="true"><res protocolInfo="sonos.com-spotify:*:audio/x-spotify:*" duration="0:03:18">x-sonos-spotify:spotify%3atrack%3a1</res>'
    '<upnp:albumArtURI>/getaa?s=1&amp;u=x-sonos-spotify%3aspotify%253atrack%253a1</upnp:albumArtURI><dc:title>Brother Sun</dc:title><upnp:class>object.item.audioItem.musicTrack</upnp:class>'
    '<dc:creator>The Porter&apos;s Gate</dc:creator><upnp:album>Neighbor Songs</upnp:album></item>'
    '<item id="Q:0/2" parentID="Q:0" restricted="true"><res duration="0:04:01">x-sonos-spotify:spotify%3atrack%3a2</res><dc:title>Second</dc:title><dc:creator>Someone</dc:creator></item>'
    '</DIDL-Lite>';

void main() {
  group('SonosClient parsers', () {
    test('zone groups: coordinator first, invisible members out', () {
      final groups = SonosClient.parseZoneGroups(_topology);
      expect(groups, hasLength(2));
      expect(groups[0].leader.uuid, 'RINCON_74CA60A4CCD001400');
      expect(groups[0].leader.host, '10.11.12.70');
      expect(groups[0].name, 'Office');
      expect(groups[0].members, hasLength(1));
      final pair = groups[1];
      expect(pair.leader.uuid, 'RINCON_AAA');
      expect(pair.leader.name, 'Kitchen & Dining');
      expect(pair.name, 'Kitchen & Dining + Living Room');
      expect(pair.members.map((m) => m.uuid), ['RINCON_AAA', 'RINCON_BBB']);
      expect(pair.contains('RINCON_BBB'), isTrue);
      expect(pair.contains('RINCON_SUB'), isFalse);
    });

    test('DIDL items: title, artist, album, art, duration', () {
      final items = SonosClient.parseDidlItems(_queueDidl);
      expect(items, hasLength(2));
      expect(items[0]['title'], 'Brother Sun');
      expect(items[0]['artist'], "The Porter's Gate");
      expect(items[0]['album'], 'Neighbor Songs');
      expect(items[0]['duration'], '0:03:18');
      expect(items[0]['art'], startsWith('/getaa?s=1&u='));
      expect(items[0]['id'], 'Q:0/1');
      expect(items[1]['title'], 'Second');
      expect(items[1].containsKey('album'), isFalse);
    });
  });

  group('SonosPlayer.publicArtLookup', () {
    test('finds the Spotify and Deezer ids behind a track URI', () {
      expect(
        SonosPlayer.publicArtLookup(
          'x-sonos-spotify:spotify%3atrack%3a2EPxhPbZczxce6wHbuOlQ6?sid=9&flags=8232&sn=2',
        ),
        ('spotify', '2EPxhPbZczxce6wHbuOlQ6'),
      );
      expect(
        SonosPlayer.publicArtLookup(
          'x-sonos-http:sonos%3aa78b8e1eb-DZR%3a28%3a1788373720219%3amiddle%3a2997%3a%3adzrs.trk.3965376601%3adefault%3aSD.mp4?sid=303&flags=0&sn=1',
        ),
        ('deezer', '3965376601'),
      );
      expect(SonosPlayer.publicArtLookup('x-rincon-stream:RINCON_1'), isNull);
    });
  });

  group('SonosPlayer.stationArt', () {
    test('the station item in the media info carries the logo', () {
      // A TuneIn station as GetMediaInfo describes it: the track metadata
      // of the stream names the song and has no art; this item has it.
      const media = {
        'CurrentURI': 'x-sonosapi-stream:s24939?sid=254&flags=8224&sn=0',
        'CurrentURIMetaData':
            '<DIDL-Lite xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" xmlns:r="urn:schemas-rinconnetworks-com:metadata-1-0/" xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/">'
            '<item id="F00092020s24939" parentID="L" restricted="true"><dc:title>1LIVE</dc:title><upnp:class>object.item.audioItem.audioBroadcast</upnp:class>'
            '<upnp:albumArtURI>https://cdn-profiles.tunein.com/s24939/images/logoq.jpg?t=1</upnp:albumArtURI>'
            '<desc id="cdudn" nameSpace="urn:schemas-rinconnetworks-com:metadata-1-0/">SA_RINCON65031_</desc></item></DIDL-Lite>',
      };
      expect(
        SonosPlayer.stationArt(media, '10.11.12.70'),
        'https://cdn-profiles.tunein.com/s24939/images/logoq.jpg?t=1',
      );
      // A path is served by the speaker; no item is no logo.
      expect(
        SonosPlayer.stationArt({
          'CurrentURIMetaData':
              '<DIDL-Lite><item id="x"><upnp:albumArtURI>/getaa?s=1&amp;u=x</upnp:albumArtURI></item></DIDL-Lite>',
        }, '10.11.12.70'),
        'http://10.11.12.70:1400/getaa?s=1&u=x',
      );
      expect(SonosPlayer.stationArt(const {}, 'h'), isNull);
    });
  });

  group('SonosPlayer.snapshotFrom', () {
    test('a playing station track: no duration, no seek, absolute art', () {
      final snap = SonosPlayer.snapshotFrom(
        transport: {'CurrentTransportState': 'PLAYING'},
        position: {
          'Track': '2',
          'TrackDuration': '0:00:00',
          'TrackMetaData': _trackMeta,
          'RelTime': '0:01:17',
        },
        host: '10.11.12.70',
        shuffle: false,
        volume: 9,
        muted: true,
      );
      expect(snap, isNotNull);
      expect(snap!['title'], 'drop dead');
      expect(snap['artist'], 'Olivia Rodrigo');
      expect(snap['playing'], isTrue);
      expect(snap['positionMs'], 77000);
      expect(snap.containsKey('durationMs'), isFalse);
      expect(snap['supportedCommands'], isNot(contains('seek')));
      expect(
        snap['supportedCommands'],
        containsAll(['pause', 'next', 'volume']),
      );
      expect(snap['volume'], 9);
      expect(snap['muted'], isTrue);
      expect(snap['trackNumber'], 2);
      expect(
        snap['artworkUrl'],
        'https://sonosradio.imgix.net/station-images/054fdfb6.jpeg?w=200&auto=format',
      );
    });

    test('a queue track: duration, seek, art on the speaker', () {
      final items = SonosClient.parseDidlItems(_queueDidl);
      // A track's metadata is one DIDL item; borrow the queue's first.
      final meta = _queueDidl.replaceFirst(
        RegExp(r'<item id="Q:0/2".*?</item>'),
        '',
      );
      expect(items, isNotEmpty);
      final snap = SonosPlayer.snapshotFrom(
        transport: {'CurrentTransportState': 'PAUSED_PLAYBACK'},
        position: {
          'Track': '1',
          'TrackDuration': '0:03:18',
          'TrackMetaData': meta,
          'RelTime': '0:00:30',
        },
        host: '10.11.12.70',
        shuffle: true,
      );
      expect(snap!['playing'], isFalse);
      expect(snap['durationMs'], 198000);
      expect(snap['positionMs'], 30000);
      expect(snap['shuffle'], isTrue);
      expect(snap['album'], 'Neighbor Songs');
      expect(snap['supportedCommands'], contains('seek'));
      expect(snap['artworkUrl'], startsWith('http://10.11.12.70:1400/getaa?'));
    });

    test('a radio stream names the station and the song', () {
      const meta =
          '<DIDL-Lite xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" xmlns:r="urn:schemas-rinconnetworks-com:metadata-1-0/">'
          '<item id="-1" parentID="-1"><dc:title>Groove Salad</dc:title><upnp:class>object.item.audioItem.audioBroadcast</upnp:class>'
          '<r:streamContent>Boards of Canada - Dayvan Cowboy</r:streamContent></item></DIDL-Lite>';
      final snap = SonosPlayer.snapshotFrom(
        transport: {'CurrentTransportState': 'TRANSITIONING'},
        position: {
          'Track': '1',
          'TrackDuration': 'NOT_IMPLEMENTED',
          'TrackMetaData': meta,
          'RelTime': '0:12:00',
        },
        host: '10.11.12.70',
      );
      expect(snap!['title'], 'Dayvan Cowboy');
      expect(snap['artist'], 'Boards of Canada');
      expect(snap['album'], 'Groove Salad');
      expect(snap['stream'], isTrue);
      expect(snap['playing'], isTrue);
    });

    test('stopped shows nothing until playback was seen', () {
      final position = {
        'Track': '2',
        'TrackDuration': '0:00:00',
        'TrackMetaData': _trackMeta,
        'RelTime': '0:00:00',
      };
      expect(
        SonosPlayer.snapshotFrom(
          transport: {'CurrentTransportState': 'STOPPED'},
          position: position,
          host: 'h',
        ),
        isNull,
      );
      final after = SonosPlayer.snapshotFrom(
        transport: {'CurrentTransportState': 'STOPPED'},
        position: position,
        host: 'h',
        sawPlayback: true,
      );
      expect(after, isNotNull);
      expect(after!['playing'], isFalse);
      // No track at all is nothing to show, whatever was seen.
      expect(
        SonosPlayer.snapshotFrom(
          transport: {'CurrentTransportState': 'STOPPED'},
          position: {'TrackMetaData': '', 'RelTime': '0:00:00'},
          host: 'h',
          sawPlayback: true,
        ),
        isNull,
      );
    });
  });
}
