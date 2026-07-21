/// XML documents and helpers for the DLNA MediaRenderer.
///
/// Everything a control point reads: the device description, the three
/// service SCPDs, SOAP envelopes and GENA LastChange payloads. Kept as
/// templates and string builders — the documents are static shapes, and a
/// full XML dependency for them (and for parsing the handful of flat SOAP
/// arguments we receive) would be the heaviest part of the feature.
library;

const mediaRendererType = 'urn:schemas-upnp-org:device:MediaRenderer:1';
const avtType = 'urn:schemas-upnp-org:service:AVTransport:1';
const rcsType = 'urn:schemas-upnp-org:service:RenderingControl:1';
const cmsType = 'urn:schemas-upnp-org:service:ConnectionManager:1';

/// What we accept over http-get. The WebView's ExoPlayer decodes the video
/// and audio side; images render in Flutter.
const sinkProtocolInfo =
    'http-get:*:image/jpeg:*,http-get:*:image/png:*,http-get:*:image/gif:*,'
    'http-get:*:image/webp:*,http-get:*:image/bmp:*,'
    'http-get:*:video/mp4:*,http-get:*:video/x-matroska:*,'
    'http-get:*:video/webm:*,http-get:*:video/quicktime:*,'
    'http-get:*:video/x-msvideo:*,http-get:*:video/mpeg:*,'
    'http-get:*:video/mp2t:*,'
    // HLS: what HA camera streams browse and resolve as. Without these the
    // media browser hides cameras as "incompatible with the selected
    // player".
    'http-get:*:application/vnd.apple.mpegurl:*,'
    'http-get:*:application/x-mpegurl:*,http-get:*:audio/mpegurl:*,'
    'http-get:*:audio/mpeg:*,http-get:*:audio/mp4:*,http-get:*:audio/flac:*,'
    'http-get:*:audio/x-flac:*,http-get:*:audio/wav:*,http-get:*:audio/ogg:*,'
    'http-get:*:audio/aac:*';

String escapeXml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

String unescapeXml(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

String deviceDescription({
  required String friendlyName,
  required String uuid,
  required String appVersion,
}) =>
    '''
<?xml version="1.0" encoding="utf-8"?>
<root xmlns="urn:schemas-upnp-org:device-1-0" xmlns:dlna="urn:schemas-dlna-org:device-1-0">
  <specVersion><major>1</major><minor>0</minor></specVersion>
  <device>
    <deviceType>$mediaRendererType</deviceType>
    <friendlyName>${escapeXml(friendlyName)}</friendlyName>
    <manufacturer>Kiosk Satellite</manufacturer>
    <manufacturerURL>https://github.com/jxlarrea/kiosk-satellite</manufacturerURL>
    <modelName>Kiosk Satellite</modelName>
    <modelDescription>Home Assistant kiosk media renderer</modelDescription>
    <modelNumber>$appVersion</modelNumber>
    <UDN>uuid:$uuid</UDN>
    <dlna:X_DLNADOC>DMR-1.50</dlna:X_DLNADOC>
    <serviceList>
      <service>
        <serviceType>$avtType</serviceType>
        <serviceId>urn:upnp-org:serviceId:AVTransport</serviceId>
        <SCPDURL>/AVTransport.xml</SCPDURL>
        <controlURL>/control/AVTransport</controlURL>
        <eventSubURL>/event/AVTransport</eventSubURL>
      </service>
      <service>
        <serviceType>$rcsType</serviceType>
        <serviceId>urn:upnp-org:serviceId:RenderingControl</serviceId>
        <SCPDURL>/RenderingControl.xml</SCPDURL>
        <controlURL>/control/RenderingControl</controlURL>
        <eventSubURL>/event/RenderingControl</eventSubURL>
      </service>
      <service>
        <serviceType>$cmsType</serviceType>
        <serviceId>urn:upnp-org:serviceId:ConnectionManager</serviceId>
        <SCPDURL>/ConnectionManager.xml</SCPDURL>
        <controlURL>/control/ConnectionManager</controlURL>
        <eventSubURL>/event/ConnectionManager</eventSubURL>
      </service>
    </serviceList>
  </device>
</root>
''';

String _scpd(String body) =>
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<scpd xmlns="urn:schemas-upnp-org:service-1-0">'
    '<specVersion><major>1</major><minor>0</minor></specVersion>$body</scpd>';

String _action(String name, List<(String, String, String)> args) =>
    '<action><name>$name</name><argumentList>${args.map((a) => '<argument>'
        '<name>${a.$1}</name><direction>${a.$2}</direction>'
        '<relatedStateVariable>${a.$3}</relatedStateVariable>'
        '</argument>').join()}</argumentList></action>';

String _stateVar(String name, String type, {bool events = false}) =>
    '<stateVariable sendEvents="${events ? 'yes' : 'no'}">'
    '<name>$name</name><dataType>$type</dataType></stateVariable>';

final avtScpd = _scpd(
  '<actionList>'
  '${_action('SetAVTransportURI', [
        ('InstanceID', 'in', 'A_ARG_TYPE_InstanceID'),
        ('CurrentURI', 'in', 'AVTransportURI'),
        ('CurrentURIMetaData', 'in', 'AVTransportURIMetaData'),
      ])}'
  '${_action('Play', [
        ('InstanceID', 'in', 'A_ARG_TYPE_InstanceID'),
        ('Speed', 'in', 'TransportPlaySpeed'),
      ])}'
  '${_action('Pause', [('InstanceID', 'in', 'A_ARG_TYPE_InstanceID')])}'
  '${_action('Stop', [('InstanceID', 'in', 'A_ARG_TYPE_InstanceID')])}'
  '${_action('Seek', [
        ('InstanceID', 'in', 'A_ARG_TYPE_InstanceID'),
        ('Unit', 'in', 'A_ARG_TYPE_SeekMode'),
        ('Target', 'in', 'A_ARG_TYPE_SeekTarget'),
      ])}'
  '${_action('GetCurrentTransportActions', [
        ('InstanceID', 'in', 'A_ARG_TYPE_InstanceID'),
        ('Actions', 'out', 'CurrentTransportActions'),
      ])}'
  '${_action('GetTransportInfo', [
        ('InstanceID', 'in', 'A_ARG_TYPE_InstanceID'),
        ('CurrentTransportState', 'out', 'TransportState'),
        ('CurrentTransportStatus', 'out', 'TransportStatus'),
        ('CurrentSpeed', 'out', 'TransportPlaySpeed'),
      ])}'
  '${_action('GetPositionInfo', [
        ('InstanceID', 'in', 'A_ARG_TYPE_InstanceID'),
        ('Track', 'out', 'CurrentTrack'),
        ('TrackDuration', 'out', 'CurrentTrackDuration'),
        ('TrackMetaData', 'out', 'CurrentTrackMetaData'),
        ('TrackURI', 'out', 'CurrentTrackURI'),
        ('RelTime', 'out', 'RelativeTimePosition'),
        ('AbsTime', 'out', 'AbsoluteTimePosition'),
        ('RelCount', 'out', 'RelativeCounterPosition'),
        ('AbsCount', 'out', 'AbsoluteCounterPosition'),
      ])}'
  '${_action('GetMediaInfo', [
        ('InstanceID', 'in', 'A_ARG_TYPE_InstanceID'),
        ('NrTracks', 'out', 'NumberOfTracks'),
        ('MediaDuration', 'out', 'CurrentMediaDuration'),
        ('CurrentURI', 'out', 'AVTransportURI'),
        ('CurrentURIMetaData', 'out', 'AVTransportURIMetaData'),
        ('NextURI', 'out', 'NextAVTransportURI'),
        ('NextURIMetaData', 'out', 'NextAVTransportURIMetaData'),
        ('PlayMedium', 'out', 'PlaybackStorageMedium'),
        ('RecordMedium', 'out', 'RecordStorageMedium'),
        ('WriteStatus', 'out', 'RecordMediumWriteStatus'),
      ])}'
  '</actionList>'
  '<serviceStateTable>'
  '${_stateVar('TransportState', 'string')}'
  '${_stateVar('CurrentTransportActions', 'string')}'
  '${_stateVar('TransportStatus', 'string')}'
  '${_stateVar('TransportPlaySpeed', 'string')}'
  '${_stateVar('NumberOfTracks', 'ui4')}'
  '${_stateVar('CurrentTrack', 'ui4')}'
  '${_stateVar('CurrentTrackDuration', 'string')}'
  '${_stateVar('CurrentMediaDuration', 'string')}'
  '${_stateVar('CurrentTrackURI', 'string')}'
  '${_stateVar('CurrentTrackMetaData', 'string')}'
  '${_stateVar('AVTransportURI', 'string')}'
  '${_stateVar('AVTransportURIMetaData', 'string')}'
  '${_stateVar('NextAVTransportURI', 'string')}'
  '${_stateVar('NextAVTransportURIMetaData', 'string')}'
  '${_stateVar('PlaybackStorageMedium', 'string')}'
  '${_stateVar('RecordStorageMedium', 'string')}'
  '${_stateVar('RecordMediumWriteStatus', 'string')}'
  '${_stateVar('RelativeTimePosition', 'string')}'
  '${_stateVar('AbsoluteTimePosition', 'string')}'
  '${_stateVar('RelativeCounterPosition', 'i4')}'
  '${_stateVar('AbsoluteCounterPosition', 'i4')}'
  '${_stateVar('LastChange', 'string', events: true)}'
  '${_stateVar('A_ARG_TYPE_InstanceID', 'ui4')}'
  '${_stateVar('A_ARG_TYPE_SeekMode', 'string')}'
  '${_stateVar('A_ARG_TYPE_SeekTarget', 'string')}'
  '</serviceStateTable>',
);

final rcsScpd = _scpd(
  '<actionList>'
  '${_action('GetVolume', [
        ('InstanceID', 'in', 'A_ARG_TYPE_InstanceID'),
        ('Channel', 'in', 'A_ARG_TYPE_Channel'),
        ('CurrentVolume', 'out', 'Volume'),
      ])}'
  '${_action('SetVolume', [
        ('InstanceID', 'in', 'A_ARG_TYPE_InstanceID'),
        ('Channel', 'in', 'A_ARG_TYPE_Channel'),
        ('DesiredVolume', 'in', 'Volume'),
      ])}'
  '${_action('GetMute', [
        ('InstanceID', 'in', 'A_ARG_TYPE_InstanceID'),
        ('Channel', 'in', 'A_ARG_TYPE_Channel'),
        ('CurrentMute', 'out', 'Mute'),
      ])}'
  '${_action('SetMute', [
        ('InstanceID', 'in', 'A_ARG_TYPE_InstanceID'),
        ('Channel', 'in', 'A_ARG_TYPE_Channel'),
        ('DesiredMute', 'in', 'Mute'),
      ])}'
  '</actionList>'
  '<serviceStateTable>'
  '<stateVariable sendEvents="no"><name>Volume</name><dataType>ui2</dataType>'
  '<allowedValueRange><minimum>0</minimum><maximum>100</maximum><step>1</step>'
  '</allowedValueRange></stateVariable>'
  '${_stateVar('Mute', 'boolean')}'
  '${_stateVar('LastChange', 'string', events: true)}'
  '${_stateVar('A_ARG_TYPE_InstanceID', 'ui4')}'
  '${_stateVar('A_ARG_TYPE_Channel', 'string')}'
  '</serviceStateTable>',
);

final cmsScpd = _scpd(
  '<actionList>'
  '${_action('GetProtocolInfo', [
        ('Source', 'out', 'SourceProtocolInfo'),
        ('Sink', 'out', 'SinkProtocolInfo'),
      ])}'
  '${_action('GetCurrentConnectionIDs', [
        ('ConnectionIDs', 'out', 'CurrentConnectionIDs'),
      ])}'
  '${_action('GetCurrentConnectionInfo', [
        ('ConnectionID', 'in', 'A_ARG_TYPE_ConnectionID'),
        ('RcsID', 'out', 'A_ARG_TYPE_RcsID'),
        ('AVTransportID', 'out', 'A_ARG_TYPE_AVTransportID'),
        ('ProtocolInfo', 'out', 'A_ARG_TYPE_ProtocolInfo'),
        ('PeerConnectionManager', 'out', 'A_ARG_TYPE_ConnectionManager'),
        ('PeerConnectionID', 'out', 'A_ARG_TYPE_ConnectionID'),
        ('Direction', 'out', 'A_ARG_TYPE_Direction'),
        ('Status', 'out', 'A_ARG_TYPE_ConnectionStatus'),
      ])}'
  '</actionList>'
  '<serviceStateTable>'
  '${_stateVar('SourceProtocolInfo', 'string', events: true)}'
  '${_stateVar('SinkProtocolInfo', 'string', events: true)}'
  '${_stateVar('CurrentConnectionIDs', 'string', events: true)}'
  '${_stateVar('A_ARG_TYPE_ConnectionStatus', 'string')}'
  '${_stateVar('A_ARG_TYPE_ConnectionManager', 'string')}'
  '${_stateVar('A_ARG_TYPE_Direction', 'string')}'
  '${_stateVar('A_ARG_TYPE_ProtocolInfo', 'string')}'
  '${_stateVar('A_ARG_TYPE_ConnectionID', 'i4')}'
  '${_stateVar('A_ARG_TYPE_AVTransportID', 'i4')}'
  '${_stateVar('A_ARG_TYPE_RcsID', 'i4')}'
  '</serviceStateTable>',
);

String soapResponse(String serviceType, String action, Map<String, String> args) =>
    '<?xml version="1.0" encoding="utf-8"?>'
    '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
    's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body>'
    '<u:${action}Response xmlns:u="$serviceType">'
    '${args.entries.map((e) => '<${e.key}>${escapeXml(e.value)}</${e.key}>').join()}'
    '</u:${action}Response></s:Body></s:Envelope>';

String soapFault(int code, String description) =>
    '<?xml version="1.0" encoding="utf-8"?>'
    '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
    's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body>'
    '<s:Fault><faultcode>s:Client</faultcode><faultstring>UPnPError</faultstring>'
    '<detail><UPnPError xmlns="urn:schemas-upnp-org:control-1-0">'
    '<errorCode>$code</errorCode>'
    '<errorDescription>${escapeXml(description)}</errorDescription>'
    '</UPnPError></detail></s:Fault></s:Body></s:Envelope>';

/// The LastChange payload GENA notifies carry: current state variables of
/// one service instance, themselves XML, escaped into the property value.
String lastChange(String serviceNs, Map<String, String> vars) => escapeXml(
      '<Event xmlns="$serviceNs"><InstanceID val="0">'
      '${vars.entries.map((e) => '<${e.key} val="${escapeXml(e.value)}"/>').join()}'
      '</InstanceID></Event>',
    );

String propertySet(Map<String, String> props) =>
    '<?xml version="1.0" encoding="utf-8"?>'
    '<e:propertyset xmlns:e="urn:schemas-upnp-org:event-1-0">'
    '${props.entries.map((e) => '<e:property><${e.key}>${e.value}</${e.key}></e:property>').join()}'
    '</e:propertyset>';

/// Pull the flat argument elements out of a SOAP action request body.
/// Control points send simple `<Name>value</Name>` pairs inside the action
/// element; nothing here needs a full parser.
Map<String, String> parseSoapArgs(String body) {
  final args = <String, String>{};
  for (final m in RegExp(
    r'<(?:\w+:)?(\w+)(?:\s[^>]*)?>([\s\S]*?)</(?:\w+:)?\1>',
    multiLine: true,
  ).allMatches(body)) {
    final name = m[1]!;
    final value = m[2] ?? '';
    // Containers (the envelope plumbing and the action element itself)
    // hold the argument elements: recurse into anything that still looks
    // like markup, keep leaves. Escaped payloads (DIDL metadata) contain
    // only &lt; entities, so they read as leaves.
    if (const {'Envelope', 'Body', 'Header'}.contains(name) ||
        value.contains('</')) {
      args.addAll(parseSoapArgs(value));
    } else {
      args[name] = unescapeXml(value.trim());
    }
  }
  return args;
}

/// 'imageItem' | 'videoItem' | 'audioItem' from DIDL-Lite metadata, or null.
String? upnpClassOf(String? metadata) {
  if (metadata == null || metadata.isEmpty) return null;
  final m = RegExp(
    r'object\.item\.(\w+Item)',
  ).firstMatch(unescapeXml(metadata));
  return m?[1];
}

/// The res element's mime type from DIDL-Lite metadata
/// (protocolInfo="http-get:*:MIME:..."), or null.
String? mimeOf(String? metadata) {
  if (metadata == null || metadata.isEmpty) return null;
  final m = RegExp(
    r'protocolInfo="http-get:\*:([^:"]+):',
  ).firstMatch(unescapeXml(metadata));
  return m?[1]?.toLowerCase();
}

/// dc:title from DIDL-Lite metadata, or null.
String? titleOf(String? metadata) {
  if (metadata == null || metadata.isEmpty) return null;
  final m = RegExp(
    r'<dc:title>([\s\S]*?)</dc:title>',
  ).firstMatch(unescapeXml(metadata));
  final t = m?[1]?.trim();
  return (t == null || t.isEmpty) ? null : unescapeXml(t);
}

String formatUpnpTime(Duration d) {
  final h = d.inHours;
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

Duration? parseUpnpTime(String s) {
  final parts = s.split(':');
  if (parts.length != 3) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final sec = double.tryParse(parts[2]);
  if (h == null || m == null || sec == null) return null;
  return Duration(hours: h, minutes: m, milliseconds: (sec * 1000).round());
}
