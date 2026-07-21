import 'dart:async';
import 'dart:io';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'upnp_xml.dart';

/// What the renderer was handed to show: one URI plus what kind of thing
/// it is. `kind` is 'image' | 'video' | 'audio'.
class DlnaMedia {
  const DlnaMedia({
    required this.uri,
    required this.kind,
    required this.metadata,
    this.title,
    this.hls = false,
  });

  final String uri;
  final String kind;
  final String metadata;
  final String? title;

  /// HLS stream (HA camera streams arrive this way). The player needs the
  /// explicit hint: ExoPlayer's by-extension sniffing misses it and tries
  /// to read the playlist with progressive extractors.
  final bool hls;
}

class _Subscription {
  _Subscription(this.sid, this.callback, this.expiry);
  final String sid;
  final Uri callback;
  DateTime expiry;
  int seq = 0;

  /// Consecutive delivery failures; the subscription is dropped after a
  /// few, so a dead subscriber cannot keep slowing awaited deliveries.
  int failures = 0;

  /// Notifies are chained per subscription: GENA SEQ promises ordered
  /// delivery, and two concurrent HTTP requests milliseconds apart can
  /// land swapped — after which the subscriber believes a stale state
  /// (dlna_dmr then waits forever for a transition that already happened).
  Future<void> sendQueue = Future.value();
}

/// A DLNA/UPnP MediaRenderer, so Home Assistant's built-in `dlna_dmr`
/// integration (and any DLNA controller) can push images, video and audio
/// to the kiosk with `media_player.play_media`.
///
/// Three parts, all here: an SSDP responder/advertiser for discovery, a
/// small HTTP server (description + SCPD documents, SOAP control, GENA
/// eventing), and the transport state machine. Rendering happens in
/// [DlnaMediaOverlay], which watches [media]/[transportState] and reports
/// progress back so GetPositionInfo can answer truthfully.
class DlnaManager extends Manager {
  DlnaManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  static const _port = 2325;
  static const _ssdpAddress = '239.255.255.250';
  static const _ssdpPort = 1900;

  @override
  String get name => 'dlna';

  // ── Rendering state (the overlay watches these) ─────────────────────

  final media = ValueNotifier<DlnaMedia?>(null);

  /// 'STOPPED' | 'PLAYING' | 'PAUSED_PLAYBACK' | 'TRANSITIONING'
  final transportState = ValueNotifier<String>('STOPPED');

  /// 0..100, applied by the overlay to its player (device volume stays the
  /// user's own; a pushed video should not stomp the media volume knob).
  final volume = ValueNotifier<int>(100);
  final muted = ValueNotifier<bool>(false);

  /// One-shot seek requests for the overlay's player.
  final seekTo = ValueNotifier<Duration?>(null);

  /// True from SetAVTransportURI until Play (or Stop, or a timeout): the
  /// overlay shows its loading screen right away instead of leaving the
  /// controller's buffering window as dead air on the wall.
  final pending = ValueNotifier<bool>(false);
  Timer? _pendingTimeout;

  void _setPending(bool value) {
    _pendingTimeout?.cancel();
    _pendingTimeout = null;
    pending.value = value;
    if (value) {
      // A controller that queues a URI and never plays it should not hold
      // a black screen forever.
      _pendingTimeout = Timer(const Duration(seconds: 30), () {
        pending.value = false;
      });
    }
  }

  /// What the controller may do right now, reported in events and
  /// GetCurrentTransportActions — dlna_dmr polls this between queueing a
  /// URI and pressing Play, and without it waits out its full timeout.
  String get _transportActions => media.value == null
      ? ''
      : transportState.value == 'PLAYING'
          ? 'Stop,Pause,Seek'
          : 'Play,Stop';

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // ── Infrastructure ──────────────────────────────────────────────────

  HttpServer? _server;
  RawDatagramSocket? _ssdp;
  Timer? _aliveTimer;
  Timer? _restartDebounce;
  Timer? _activityTick;
  String _uuid = '';
  String _ip = '';
  String _appVersion = '';
  final _subs = <String, List<_Subscription>>{
    'AVTransport': [],
    'RenderingControl': [],
    'ConnectionManager': [],
  };
  Future<void> _transition = Future.value();

  @override
  Future<void> init() async {
    _uuid = await _settings.secret('dlna_uuid', _newUuid);
    bus.on<SettingChanged>().listen((e) {
      if (!e.key.startsWith('dlna.') && e.key != defs.deviceName.key) return;
      _restartDebounce?.cancel();
      _restartDebounce = Timer(const Duration(milliseconds: 500), () {
        _transition = _transition.then((_) => _restart());
      });
    });
    commands.register(
      Command(
        name: 'dlnaStatus',
        description: 'DLNA renderer state: running, current media, transport',
        handler: (_) async => CommandResult.ok({
          'running': _server != null,
          'transportState': transportState.value,
          'uri': media.value?.uri,
          'kind': media.value?.kind,
          'title': media.value?.title,
          'subscriptions': {
            for (final e in _subs.entries)
              e.key: [for (final s in e.value) '${s.callback}'],
          },
        }),
      ),
    );
    final version = await commands.execute('getDeviceInfo', const {});
    _appVersion =
        ((version.data as Map?)?['appVersion'] as String?) ?? '0.0.0';
    if (_settings.get(defs.dlnaEnabled)) {
      _transition = _transition.then((_) => _start());
    }
  }

  @override
  Future<void> dispose() async {
    _restartDebounce?.cancel();
    await _stop();
  }

  Future<void> _restart() async {
    await _stop();
    if (_settings.get(defs.dlnaEnabled)) await _start();
  }

  Future<void> _start() async {
    try {
      _ip = await _localIp();
      _server = await shelf_io.serve(_route, InternetAddress.anyIPv4, _port);
      await _startSsdp();
      log.info(name, 'renderer up at http://$_ip:$_port (uuid $_uuid)');
    } catch (e) {
      log.error(name, 'failed to start: $e');
      await _stop();
    }
  }

  Future<void> _stop() async {
    _aliveTimer?.cancel();
    _aliveTimer = null;
    _activityTick?.cancel();
    _activityTick = null;
    if (_ssdp != null) {
      _sendByeBye();
      _ssdp!.close();
      _ssdp = null;
    }
    await _server?.close(force: true);
    _server = null;
    for (final list in _subs.values) {
      list.clear();
    }
    _setPending(false);
    media.value = null;
    transportState.value = 'STOPPED';
  }

  static String _newUuid() {
    final r = Random.secure();
    String hex(int n) =>
        List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-'
        '${(8 + r.nextInt(4)).toRadixString(16)}${hex(3)}-${hex(12)}';
  }

  Future<String> _localIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );
    for (final i in interfaces) {
      for (final a in i.addresses) {
        if (!a.isLoopback) return a.address;
      }
    }
    throw StateError('no network address');
  }

  // ── SSDP ────────────────────────────────────────────────────────────

  /// NT/ST values this renderer answers for, with their USNs.
  Map<String, String> get _targets => {
        'upnp:rootdevice': 'uuid:$_uuid::upnp:rootdevice',
        'uuid:$_uuid': 'uuid:$_uuid',
        mediaRendererType: 'uuid:$_uuid::$mediaRendererType',
        avtType: 'uuid:$_uuid::$avtType',
        rcsType: 'uuid:$_uuid::$rcsType',
        cmsType: 'uuid:$_uuid::$cmsType',
      };

  String get _serverHeader =>
      'Android/1.0 UPnP/1.0 KioskSatellite/$_appVersion';

  Future<void> _startSsdp() async {
    final sock = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _ssdpPort,
      reuseAddress: true,
      reusePort: true,
    );
    sock.joinMulticast(InternetAddress(_ssdpAddress));
    sock.multicastHops = 2;
    sock.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = sock.receive();
      if (dg == null) return;
      _onDatagram(dg);
    });
    _ssdp = sock;
    // Announce twice shortly after start (UDP is lossy), then keep alive.
    _sendAlive();
    Timer(const Duration(milliseconds: 400), _sendAlive);
    _aliveTimer = Timer.periodic(
      const Duration(seconds: 600),
      (_) => _sendAlive(),
    );
  }

  void _onDatagram(Datagram dg) {
    final text = String.fromCharCodes(dg.data);
    if (!text.startsWith('M-SEARCH')) return;
    final st = RegExp(
      r'^ST:\s*(.+?)\s*$',
      multiLine: true,
      caseSensitive: false,
    ).firstMatch(text)?[1];
    if (st == null) return;
    final matches = st == 'ssdp:all'
        ? _targets.entries.toList()
        : _targets.containsKey(st)
            ? [MapEntry(st, _targets[st]!)]
            : const <MapEntry<String, String>>[];
    if (matches.isEmpty) return;
    // A short random delay per the spec (MX), spreading replies out.
    Timer(Duration(milliseconds: Random().nextInt(80)), () {
      final sock = _ssdp;
      if (sock == null) return;
      for (final m in matches) {
        final response = 'HTTP/1.1 200 OK\r\n'
            'CACHE-CONTROL: max-age=1800\r\n'
            'EXT:\r\n'
            'LOCATION: http://$_ip:$_port/device.xml\r\n'
            'SERVER: $_serverHeader\r\n'
            'ST: ${m.key}\r\n'
            'USN: ${m.value}\r\n'
            'BOOTID.UPNP.ORG: 1\r\n'
            '\r\n';
        sock.send(response.codeUnits, dg.address, dg.port);
      }
    });
  }

  void _sendSsdpNotify(String nts) {
    final sock = _ssdp;
    if (sock == null) return;
    for (final t in _targets.entries) {
      final msg = 'NOTIFY * HTTP/1.1\r\n'
          'HOST: $_ssdpAddress:$_ssdpPort\r\n'
          'CACHE-CONTROL: max-age=1800\r\n'
          'LOCATION: http://$_ip:$_port/device.xml\r\n'
          'NT: ${t.key}\r\n'
          'NTS: $nts\r\n'
          'SERVER: $_serverHeader\r\n'
          'USN: ${t.value}\r\n'
          'BOOTID.UPNP.ORG: 1\r\n'
          '\r\n';
      sock.send(msg.codeUnits, InternetAddress(_ssdpAddress), _ssdpPort);
    }
  }

  void _sendAlive() => _sendSsdpNotify('ssdp:alive');
  void _sendByeBye() => _sendSsdpNotify('ssdp:byebye');

  // ── HTTP: description, control, eventing ────────────────────────────

  Future<Response> _route(Request request) async {
    final path = request.url.path;
    switch ((request.method, path)) {
      case ('GET', 'device.xml'):
        return _xml(deviceDescription(
          friendlyName: _settings.get(defs.deviceName).isEmpty
              ? 'Kiosk Satellite'
              : _settings.get(defs.deviceName),
          uuid: _uuid,
          appVersion: _appVersion,
        ));
      case ('GET', 'AVTransport.xml'):
        return _xml(avtScpd);
      case ('GET', 'RenderingControl.xml'):
        return _xml(rcsScpd);
      case ('GET', 'ConnectionManager.xml'):
        return _xml(cmsScpd);
    }
    if (request.method == 'POST' && path.startsWith('control/')) {
      return _control(request, path.substring('control/'.length));
    }
    if ((request.method == 'SUBSCRIBE' || request.method == 'UNSUBSCRIBE') &&
        path.startsWith('event/')) {
      return _gena(request, path.substring('event/'.length));
    }
    return Response.notFound('not found');
  }

  Response _xml(String body) => Response.ok(
        body,
        headers: {'content-type': 'text/xml; charset="utf-8"'},
      );

  Future<Response> _control(Request request, String service) async {
    final soapAction = request.headers['soapaction'] ?? '';
    final action =
        RegExp(r'#(\w+)').firstMatch(soapAction)?[1] ?? 'unknown';
    final body = await request.readAsString();
    final args = parseSoapArgs(body);
    log.debug(name, '$service.$action ${args.keys.toList()}');
    try {
      final result = switch ((service, action)) {
        ('AVTransport', _) => await _avTransport(action, args),
        ('RenderingControl', _) => _renderingControl(action, args),
        ('ConnectionManager', _) => _connectionManager(action),
        _ => null,
      };
      if (result == null) {
        return Response(
          500,
          body: soapFault(401, 'Invalid Action'),
          headers: {'content-type': 'text/xml; charset="utf-8"'},
        );
      }
      final type = switch (service) {
        'AVTransport' => avtType,
        'RenderingControl' => rcsType,
        _ => cmsType,
      };
      return _xml(soapResponse(type, action, result));
    } on _UpnpError catch (e) {
      log.warn(name, '$service.$action rejected: ${e.code} ${e.message}');
      return Response(
        500,
        body: soapFault(e.code, e.message),
        headers: {'content-type': 'text/xml; charset="utf-8"'},
      );
    }
  }

  // ── AVTransport ─────────────────────────────────────────────────────

  /// State-changing actions AWAIT event delivery before answering: the
  /// controller's next decision (dlna_dmr skips Play when it believes the
  /// renderer is still playing) is made from its evented view of us, and a
  /// notify that races the SOAP response loses — the controller then acts
  /// on the state we just left.
  Future<Map<String, String>?> _avTransport(
    String action,
    Map<String, String> args,
  ) async {
    switch (action) {
      case 'SetAVTransportURI':
        final uri = args['CurrentURI'] ?? '';
        final meta = args['CurrentURIMetaData'] ?? '';
        if (uri.isEmpty) {
          log.warn(name, 'SetAVTransportURI without a URI, args: $args');
          throw _UpnpError(714, 'Illegal MIME-type');
        }
        final mime = mimeOf(meta) ?? '';
        final path = Uri.tryParse(uri)?.path.toLowerCase() ?? '';
        media.value = DlnaMedia(
          uri: uri,
          kind: _kindOf(uri, meta),
          metadata: meta,
          title: titleOf(meta),
          hls: mime.contains('mpegurl') || path.endsWith('.m3u8'),
        );
        log.info(name, 'media set: ${media.value!.kind}'
            '${media.value!.hls ? ' (hls)' : ''} $uri');
        _position = Duration.zero;
        _duration = Duration.zero;
        // No pending flag while already PLAYING: SetAVTransportURI during
        // playback is the in-place switch semantic — the overlay swaps
        // players immediately, no Play follows.
        if (transportState.value != 'PLAYING') _setPending(true);
        await _notifyAvt();
        return const {};
      case 'Play':
        if (media.value == null) {
          log.warn(name, 'Play with no media loaded');
          throw _UpnpError(701, 'Transition not available');
        }
        log.info(name, 'play');
        _setPending(false);
        transportState.value = 'PLAYING';
        _onPlaybackStarted();
        await _notifyAvt();
        return const {};
      case 'Pause':
        if (transportState.value == 'PLAYING') {
          transportState.value = 'PAUSED_PLAYBACK';
          await _notifyAvt();
        }
        return const {};
      case 'Stop':
        await stopPlayback();
        return const {};
      case 'Seek':
        final target = parseUpnpTime(args['Target'] ?? '');
        if (target != null) seekTo.value = target;
        return const {};
      case 'GetCurrentTransportActions':
        return {'Actions': _transportActions};
      case 'GetTransportInfo':
        return {
          'CurrentTransportState': transportState.value,
          'CurrentTransportStatus': 'OK',
          'CurrentSpeed': '1',
        };
      case 'GetPositionInfo':
        return {
          'Track': media.value == null ? '0' : '1',
          'TrackDuration': formatUpnpTime(_duration),
          'TrackMetaData': media.value?.metadata ?? '',
          'TrackURI': media.value?.uri ?? '',
          'RelTime': formatUpnpTime(_position),
          'AbsTime': formatUpnpTime(_position),
          'RelCount': '2147483647',
          'AbsCount': '2147483647',
        };
      case 'GetMediaInfo':
        return {
          'NrTracks': media.value == null ? '0' : '1',
          'MediaDuration': formatUpnpTime(_duration),
          'CurrentURI': media.value?.uri ?? '',
          'CurrentURIMetaData': media.value?.metadata ?? '',
          'NextURI': '',
          'NextURIMetaData': '',
          'PlayMedium': 'NETWORK',
          'RecordMedium': 'NOT_IMPLEMENTED',
          'WriteStatus': 'NOT_IMPLEMENTED',
        };
    }
    return null;
  }

  /// The media kind: DIDL upnp:class first (authoritative when specific),
  /// then the res mime, then the file extension. 'auto' when nothing is
  /// conclusive — HA sends camera_proxy_stream URLs as object.item +
  /// application/octet-stream, and the only truth left is the response's
  /// actual content type, which the overlay probes at display time.
  String _kindOf(String uri, String meta) {
    switch (upnpClassOf(meta)) {
      case 'imageItem':
        return 'image';
      case 'audioItem':
        return 'audio';
      case 'videoItem':
        return 'video';
    }
    final mime = mimeOf(meta) ?? '';
    if (mime.startsWith('image/')) return 'image';
    if (mime.contains('mpegurl') || mime.startsWith('video/')) return 'video';
    if (mime.startsWith('audio/')) return 'audio';
    final path = Uri.tryParse(uri)?.path.toLowerCase() ?? '';
    const images = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    const audio = ['.mp3', '.flac', '.wav', '.ogg', '.m4a', '.aac', '.opus'];
    const video = ['.mp4', '.mkv', '.webm', '.mov', '.avi', '.ts', '.m3u8'];
    if (images.any(path.endsWith)) return 'image';
    if (audio.any(path.endsWith)) return 'audio';
    if (video.any(path.endsWith)) return 'video';
    return 'auto';
  }

  // ── RenderingControl ────────────────────────────────────────────────

  Map<String, String>? _renderingControl(
    String action,
    Map<String, String> args,
  ) {
    switch (action) {
      case 'GetVolume':
        return {'CurrentVolume': '${volume.value}'};
      case 'SetVolume':
        volume.value =
            (int.tryParse(args['DesiredVolume'] ?? '') ?? volume.value)
                .clamp(0, 100);
        _notifyRcs();
        return const {};
      case 'GetMute':
        return {'CurrentMute': muted.value ? '1' : '0'};
      case 'SetMute':
        final v = args['DesiredMute'];
        muted.value = v == '1' || v == 'true';
        _notifyRcs();
        return const {};
    }
    return null;
  }

  Map<String, String>? _connectionManager(String action) {
    switch (action) {
      case 'GetProtocolInfo':
        return {'Source': '', 'Sink': sinkProtocolInfo};
      case 'GetCurrentConnectionIDs':
        return {'ConnectionIDs': '0'};
      case 'GetCurrentConnectionInfo':
        return {
          'RcsID': '0',
          'AVTransportID': '0',
          'ProtocolInfo': '',
          'PeerConnectionManager': '',
          'PeerConnectionID': '-1',
          'Direction': 'Input',
          'Status': 'OK',
        };
    }
    return null;
  }

  // ── GENA eventing ───────────────────────────────────────────────────

  Future<Response> _gena(Request request, String service) async {
    final subs = _subs[service];
    if (subs == null) return Response.notFound('unknown service');
    if (request.method == 'UNSUBSCRIBE') {
      subs.removeWhere((s) => s.sid == request.headers['sid']);
      return Response.ok('');
    }
    final existingSid = request.headers['sid'];
    if (existingSid != null) {
      // Renewal.
      final sub = subs.where((s) => s.sid == existingSid).firstOrNull;
      if (sub == null) return Response(412);
      sub.expiry = DateTime.now().add(const Duration(seconds: 300));
      return Response.ok('', headers: {
        'SID': sub.sid,
        'TIMEOUT': 'Second-300',
        'SERVER': _serverHeader,
      });
    }
    final callback = RegExp(r'<(.+?)>')
        .firstMatch(request.headers['callback'] ?? '')?[1];
    final url = callback == null ? null : Uri.tryParse(callback);
    if (url == null) return Response(412);
    final sub = _Subscription(
      'uuid:${_newUuid()}',
      url,
      DateTime.now().add(const Duration(seconds: 300)),
    );
    subs.add(sub);
    log.info(name, 'subscribed: $service -> $url');
    // The initial event: full state, SEQ 0, required by GENA so the
    // subscriber starts from truth rather than from silence. Queued like
    // every other notify so a state change racing the subscription cannot
    // deliver out of order.
    Timer(const Duration(milliseconds: 100), () {
      sub.sendQueue = sub.sendQueue.then((_) => _notifyOne(service, sub));
    });
    return Response.ok('', headers: {
      'SID': sub.sid,
      'TIMEOUT': 'Second-300',
      'SERVER': _serverHeader,
    });
  }

  Map<String, String> _eventProps(String service) {
    switch (service) {
      case 'AVTransport':
        return {
          'LastChange': lastChange(
            'urn:schemas-upnp-org:metadata-1-0/AVT/',
            {
              'TransportState': transportState.value,
              'CurrentTransportActions': _transportActions,
              'TransportStatus': 'OK',
              'CurrentPlayMode': 'NORMAL',
              'NumberOfTracks': media.value == null ? '0' : '1',
              'CurrentTrack': media.value == null ? '0' : '1',
              'CurrentTrackURI': media.value?.uri ?? '',
              'CurrentTrackMetaData': media.value?.metadata ?? '',
              'CurrentTrackDuration': formatUpnpTime(_duration),
              'AVTransportURI': media.value?.uri ?? '',
              'AVTransportURIMetaData': media.value?.metadata ?? '',
            },
          ),
        };
      case 'RenderingControl':
        return {
          'LastChange': lastChange(
            'urn:schemas-upnp-org:metadata-1-0/RCS/',
            {
              'Volume': '${volume.value}',
              'Mute': muted.value ? '1' : '0',
            },
          ),
        };
      default:
        return {
          'SourceProtocolInfo': '',
          'SinkProtocolInfo': escapeXml(sinkProtocolInfo),
          'CurrentConnectionIDs': '0',
        };
    }
  }

  Future<void> _notifyAvt() => _notifyAll('AVTransport');
  void _notifyRcs() => unawaited(_notifyAll('RenderingControl'));

  /// Queues the notify on every subscription's ordered chain; the returned
  /// future completes when this change has been DELIVERED everywhere, so
  /// action handlers can hold their SOAP response until subscribers are
  /// up to date.
  Future<void> _notifyAll(String service) {
    final subs = _subs[service]!;
    subs.removeWhere(
      (s) => s.expiry.isBefore(DateTime.now()) || s.failures >= 3,
    );
    final delivered = <Future<void>>[];
    for (final sub in subs) {
      sub.sendQueue = sub.sendQueue.then((_) => _notifyOne(service, sub));
      delivered.add(sub.sendQueue);
    }
    return Future.wait(delivered);
  }

  Future<void> _notifyOne(String service, _Subscription sub) async {
    final req = http.Request('NOTIFY', sub.callback)
      ..headers.addAll({
        'content-type': 'text/xml; charset="utf-8"',
        'NT': 'upnp:event',
        'NTS': 'upnp:propchange',
        'SID': sub.sid,
        'SEQ': '${sub.seq}',
      })
      ..body = propertySet(_eventProps(service));
    sub.seq++;
    try {
      await http.Client()
          .send(req)
          .timeout(const Duration(seconds: 5))
          .then((r) => r.stream.drain<void>());
      sub.failures = 0;
    } catch (e) {
      sub.failures++;
      log.warn(name, 'event notify failed (${sub.callback}): $e');
    }
  }

  // ── Overlay callbacks / shared behavior ─────────────────────────────

  /// The overlay reports playback progress here (and the manager answers
  /// GetPositionInfo from it). Callbacks carry the URI they belong to:
  /// a player being torn down mid-swap must not clobber (or, below, kill)
  /// the media that replaced it.
  void reportProgress(String uri, Duration position, Duration duration) {
    if (media.value?.uri != uri) return;
    _position = position;
    _duration = duration;
  }

  void onPlaybackEnded(String uri) {
    if (media.value?.uri != uri) return;
    stopPlayback();
  }

  /// A user tap on the overlay is the same as a controller Stop.
  void userDismiss() => stopPlayback();

  /// The state event goes out on every stop: a controller-initiated Stop
  /// being echoed back is harmless, and a local stop (tap, media end) MUST
  /// be pushed or HA's entity goes stale. Returns when the event is
  /// delivered (the Stop action awaits it; local callers need not).
  Future<void> stopPlayback() {
    if (transportState.value == 'STOPPED' && media.value == null) {
      return Future.value();
    }
    _setPending(false);
    transportState.value = 'STOPPED';
    media.value = null;
    _position = Duration.zero;
    _activityTick?.cancel();
    _activityTick = null;
    return _notifyAvt();
  }

  /// Pushed media owns the screen: dismiss the screensaver now and keep
  /// the idle timer at bay while playing, the same signal a touch sends.
  void _onPlaybackStarted() {
    bus.publish(const ActivityDetected(source: 'dlna'));
    _activityTick?.cancel();
    _activityTick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (transportState.value == 'PLAYING') {
        bus.publish(const ActivityDetected(source: 'dlna'));
      }
    });
  }
}

class _UpnpError implements Exception {
  _UpnpError(this.code, this.message);
  final int code;
  final String message;
}
