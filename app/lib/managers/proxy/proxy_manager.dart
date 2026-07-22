import 'dart:async';
import 'dart:io';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// Loopback reverse proxy that turns a plain-http Home Assistant into a
/// secure context.
///
/// Browsers withhold the whole https-only API surface from insecure origins:
/// on `http://<lan-ip>:8123` there is no `navigator.mediaDevices`, no
/// `AudioWorklet`, no `crypto.subtle` — Voice Satellite's microphone path is
/// simply absent. The spec's escape hatch is that `http://127.0.0.1` is a
/// *potentially trustworthy origin*: served from loopback, the same page is
/// a secure context and everything lights up. So when the setting is on and
/// the start URL is plain http, this manager serves that origin from
/// `127.0.0.1:2325` — every request is streamed through to Home Assistant
/// (WebSockets bridged, bodies streamed so camera feeds keep flowing) and
/// [mapUrl] rewrites page loads onto the loopback origin.
///
/// The listener binds to loopback ONLY: nothing new is exposed on the LAN,
/// and no auth is needed because only this device can reach it.
///
/// The page's origin changes when the proxy turns on, so the dashboard's
/// localStorage (including the Home Assistant login) starts fresh; the
/// setting description and the enable-flow modals warn about the one-time
/// re-login.
class ProxyManager extends Manager {
  ProxyManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'proxy';

  static const _preferredPort = 2325;

  /// Headers that describe the connection hop, not the payload; forwarding
  /// them would corrupt the proxied connection's own negotiation.
  static const _hopByHop = {
    'connection',
    'keep-alive',
    'proxy-authenticate',
    'proxy-authorization',
    'te',
    'trailer',
    'transfer-encoding',
    'upgrade',
  };

  HttpServer? _server;
  HttpClient? _client;

  /// Origin being proxied (scheme http, host, explicit port).
  Uri? _target;

  bool get running => _server != null;
  int get port => _server?.port ?? 0;

  /// The proxied origin (e.g. `http://192.168.1.10:8123`), null while off.
  String? get targetOrigin {
    final t = _target;
    if (_server == null || t == null) return null;
    return 'http://${t.host}:${t.port}';
  }

  /// The loopback origin the page actually lives on, null while off.
  String? get loopbackOrigin =>
      _server == null ? null : 'http://127.0.0.1:${_server!.port}';

  /// Last known mapping, kept after a stop so [unmapUrl] can translate a
  /// proxied URL back even right after the toggle turned the server off.
  String? _lastTargetOrigin;
  String? _lastLoopbackOrigin;

  /// The inverse of [mapUrl]: a URL on the loopback origin translated back
  /// to the real Home Assistant origin. Pass-through for everything else.
  String unmapUrl(String url) {
    final from = _lastLoopbackOrigin;
    final to = _lastTargetOrigin;
    if (from == null || to == null || !url.startsWith(from)) return url;
    return to + url.substring(from.length);
  }

  @override
  Future<void> init() async {
    commands.register(
      Command(
        name: 'proxyMapUrl',
        description:
            'Rewrite a URL to its loopback-proxied form when the secure '
            'context proxy is running and the URL is on the proxied origin; '
            'returns it unchanged otherwise',
        params: const {'url': 'The URL to map'},
        handler: (p) async =>
            CommandResult.ok(mapUrl(p['url'] as String? ?? '')),
      ),
    );
    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.secureProxy.key || e.key == defs.startUrl.key) {
        unawaited(sync());
      }
      // The toggle only means something for a plain-http instance. When the
      // HA URL moves to https (or loopback) the proxy is forced off, so the
      // connection card's row never shows an "on" it cannot honor.
      if (e.key == defs.haUrl.key && _settings.get(defs.secureProxy)) {
        final u = Uri.tryParse((e.value as String? ?? '').trim());
        final isHttp = u != null &&
            u.scheme == 'http' &&
            u.host != 'localhost' &&
            u.host != '127.0.0.1';
        if (!isHttp) unawaited(_settings.set(defs.secureProxy, false));
      }
    });
    await sync();
  }

  @override
  Future<void> dispose() async {
    await _stop();
  }

  Future<void> _syncChain = Future<void>.value();

  /// Bring the server state in line with the setting and the start URL.
  /// Public so the UI can await readiness before reloading the page after a
  /// toggle (its own SettingChanged reaction races this manager's) —
  /// which is also why the body is serialized: two concurrent syncs would
  /// each see no server and both bind one, leaking the loser.
  Future<void> sync() {
    return _syncChain = _syncChain.then((_) async {
      _target = _mappableOrigin();
      final wanted = _settings.get(defs.secureProxy) && _target != null;
      if (wanted && _server == null) await _start();
      if (!wanted && _server != null) await _stop();
    });
  }

  /// The start URL's origin when it is plain http on a non-loopback host —
  /// the only case the proxy helps. https needs nothing, and loopback is
  /// already a secure context.
  Uri? _mappableOrigin() {
    final url = Uri.tryParse(_settings.get(defs.startUrl));
    if (url == null || url.scheme != 'http') return null;
    final host = url.host;
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      return null;
    }
    return Uri(scheme: 'http', host: host, port: url.hasPort ? url.port : 80);
  }

  /// Rewrite [url] onto the loopback origin when the proxy is running and
  /// the URL sits on the proxied origin; anything else passes through.
  String mapUrl(String url) {
    final t = _target;
    final server = _server;
    if (t == null || server == null) return url;
    final u = Uri.tryParse(url);
    if (u == null || u.scheme != 'http' || u.host != t.host) return url;
    if ((u.hasPort ? u.port : 80) != t.port) return url;
    return u.replace(host: '127.0.0.1', port: server.port).toString();
  }

  Future<void> _start() async {
    _client = HttpClient()
      // Pass bodies through verbatim: decompressing here would desync the
      // Content-Encoding/Length headers the page receives.
      ..autoUncompress = false
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        _preferredPort,
      );
    } on SocketException {
      // Port taken (another app, or a previous instance mid-teardown): any
      // free port works, mapUrl always uses the live one.
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    }
    _server!.listen(_handle, onError: (Object e) {
      log.warn(name, 'server error: $e');
    });
    _lastTargetOrigin = targetOrigin;
    _lastLoopbackOrigin = loopbackOrigin;
    log.info(
      name,
      'secure context proxy on 127.0.0.1:${_server!.port} '
      'for ${_target?.host}:${_target?.port}',
    );
  }

  Future<void> _stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
    _client?.close(force: true);
    _client = null;
    if (server != null) log.info(name, 'secure context proxy stopped');
  }

  Future<void> _handle(HttpRequest req) async {
    final t = _target;
    if (t == null) {
      req.response.statusCode = HttpStatus.badGateway;
      await req.response.close();
      return;
    }
    try {
      if (WebSocketTransformer.isUpgradeRequest(req)) {
        await _bridgeWebSocket(req, t);
      } else {
        await _forward(req, t);
      }
    } catch (e) {
      log.debug(name, '${req.method} ${req.uri.path} failed: $e');
      try {
        req.response.statusCode = HttpStatus.badGateway;
        await req.response.close();
      } catch (_) {}
    }
  }

  Future<void> _forward(HttpRequest req, Uri t) async {
    final client = _client;
    if (client == null) return;
    final out = await client.openUrl(
      req.method,
      Uri.parse('http://${t.host}:${t.port}${req.uri}'),
    );
    // Redirects go back to the page so relative navigation state stays
    // correct; an absolute Location onto the proxied origin is remapped.
    out.followRedirects = false;
    req.headers.forEach((k, values) {
      final lk = k.toLowerCase();
      if (_hopByHop.contains(lk) || lk == 'host' || lk == 'content-length') {
        return;
      }
      for (final v in values) {
        out.headers.add(k, v);
      }
    });
    await out.addStream(req);
    final upstream = await out.close();

    final res = req.response;
    res.statusCode = upstream.statusCode;
    res.contentLength = upstream.contentLength;
    upstream.headers.forEach((k, values) {
      final lk = k.toLowerCase();
      if (_hopByHop.contains(lk) || lk == 'content-length') return;
      for (var v in values) {
        if (lk == 'location') v = mapUrl(v);
        res.headers.add(k, v);
      }
    });
    // Streamed, not buffered: camera MJPEG and event streams never end.
    await res.addStream(upstream);
    await res.close();
  }

  Future<void> _bridgeWebSocket(HttpRequest req, Uri t) async {
    final page = await WebSocketTransformer.upgrade(req);
    WebSocket upstream;
    try {
      upstream = await WebSocket.connect(
        'ws://${t.host}:${t.port}${req.uri}',
      );
    } catch (e) {
      await page.close(WebSocketStatus.internalServerError, 'upstream');
      rethrow;
    }
    // addStream, not listen-and-add: piping applies backpressure, so when
    // one side stops reading (Android freezing the renderer with the
    // screen off is the common case) the other side is paused instead of
    // every HA state frame accumulating in this process's heap for as
    // long as the freeze lasts. HA dropping a stalled client is the
    // strictly better failure.
    unawaited(_pump(page, upstream));
    unawaited(_pump(upstream, page));
  }

  Future<void> _pump(WebSocket from, WebSocket to) async {
    try {
      await to.addStream(from);
      await to.close(_sendableCode(from.closeCode), from.closeReason);
    } catch (_) {
      try {
        await to.close(WebSocketStatus.internalServerError);
      } catch (_) {}
    }
  }

  /// 1005/1006 are receive-side markers ("no status", "abnormal") that must
  /// never be sent in a Close frame; mirror them as a plain default close.
  static int? _sendableCode(int? code) =>
      code == WebSocketStatus.noStatusReceived ||
          code == WebSocketStatus.abnormalClosure
      ? null
      : code;
}
