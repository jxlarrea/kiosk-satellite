import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'auth.dart';

/// Embedded remote-management server (docs/remote-api.md).
///
/// REST + WebSocket, both thin adapters over the [CommandRegistry] and
/// [SettingsManager] — nothing here implements a feature. Serves the
/// remote-ui SPA at `/` (placeholder until remote-ui is built).
class RemoteManager extends Manager {
  RemoteManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;
  final _auth = AuthStore();

  @override
  String get name => 'remote';

  HttpServer? _server;
  String _currentUrl = '';
  final _wsClients = <WebSocketChannel>{};

  @override
  Future<void> init() async {
    bus.on<PageChanged>().listen((e) => _currentUrl = e.url);

    // Live event feed for connected WS clients.
    bus.stream.listen((event) {
      final wireName = event.wireName;
      if (wireName == null || _wsClients.isEmpty) return;
      _broadcast({'type': 'event', 'event': wireName, 'data': event.toJson()});
    });
    log.stream.listen((entry) {
      if (_wsClients.isEmpty) return;
      _broadcast({'type': 'log', 'entry': entry.toJson()});
    });

    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.remoteEnabled.key ||
          e.key == defs.remotePort.key ||
          e.key == defs.remotePassword.key) {
        _sync();
      }
    });

    await _sync();
  }

  Future<void> _sync() async {
    final wantRunning = _settings.get(defs.remoteEnabled) &&
        _settings.get(defs.remotePassword).isNotEmpty;
    if (wantRunning && _server == null) {
      await _start();
    } else if (!wantRunning && _server != null) {
      await _stop();
      if (_settings.get(defs.remoteEnabled)) {
        log.warn(name, 'remote enabled but no admin password set; not starting');
      }
    } else if (wantRunning && _server != null) {
      // Port may have changed; restart.
      await _stop();
      await _start();
    }
  }

  Future<void> _start() async {
    final port = _settings.get(defs.remotePort).toInt();
    try {
      _server = await shelf_io.serve(
        const Pipeline().addHandler(_route),
        InternetAddress.anyIPv4,
        port,
      );
      log.info(name, 'listening on :$port');
    } catch (e) {
      log.error(name, 'failed to start on :$port: $e');
    }
  }

  Future<void> _stop() async {
    for (final client in _wsClients.toList()) {
      await client.sink.close();
    }
    _wsClients.clear();
    await _server?.close();
    _server = null;
    log.info(name, 'stopped');
  }

  // ── Routing ──────────────────────────────────────────────────────────

  Future<Response> _route(Request request) async {
    final path = request.url.path;

    if (path.isEmpty || path == 'index.html') return _index();
    if (path == 'api/login') return _login(request);
    if (path == 'api/ws') return _ws(request);

    if (!path.startsWith('api/')) return Response.notFound('not found');

    // Everything else under /api/ requires a bearer token.
    if (!_auth.validate(_bearerToken(request))) {
      return _json(401, {'error': 'unauthorized'});
    }

    switch ((request.method, path)) {
      case ('GET', 'api/info'):
        return _info();
      case ('GET', 'api/settings'):
        return _json(200, {'settings': _settings.describe()});
      case ('PATCH', 'api/settings'):
        return _patchSettings(request);
      case ('GET', 'api/settings/export'):
        return _json(200, _settings.export());
      case ('POST', 'api/settings/import'):
        return _import(request);
      case ('GET', 'api/commands'):
        return _json(200, {
          'commands': [
            for (final c in commands.all)
              {
                'name': c.name,
                'description': c.description,
                'params': c.params,
              }
          ]
        });
      case ('GET', 'api/logs'):
        return _json(200, {'logs': [for (final e in log.recent) e.toJson()]});
      case ('GET', 'api/screenshot'):
        return _screenshot();
    }

    // POST /api/commands/<name>
    if (request.method == 'POST' && path.startsWith('api/commands/')) {
      return _command(request, path.substring('api/commands/'.length));
    }

    return Response.notFound('not found');
  }

  // ── Handlers ─────────────────────────────────────────────────────────

  Future<Response> _login(Request request) async {
    if (request.method != 'POST') return Response.notFound('not found');
    final ip =
        (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)
                ?.remoteAddress
                .address ??
            'unknown';
    if (_auth.isThrottled(ip)) {
      return _json(429, {'error': 'too many attempts'});
    }
    final body = await _body(request);
    final password = body?['password'];
    if (password is String &&
        password.isNotEmpty &&
        password == _settings.get(defs.remotePassword)) {
      _auth.clearFailures(ip);
      return _json(200, {'token': _auth.issueToken()});
    }
    _auth.recordFailure(ip);
    log.warn(name, 'failed login from $ip');
    return _json(401, {'error': 'invalid password'});
  }

  Future<Response> _info() async {
    final device = await commands.execute('getDeviceInfo', const {});
    return _json(200, {
      ...?(device.data as Map<String, Object?>?),
      'currentUrl': _currentUrl,
    });
  }

  Future<Response> _patchSettings(Request request) async {
    final body = await _body(request);
    if (body == null) return _json(400, {'error': 'invalid JSON'});
    final rejected = <String>[];
    for (final entry in body.entries) {
      if (!await _settings.setFromJson(entry.key, entry.value)) {
        rejected.add(entry.key);
      }
    }
    return _json(200, {'ok': rejected.isEmpty, 'rejected': rejected});
  }

  Future<Response> _import(Request request) async {
    final body = await _body(request);
    if (body == null) return _json(400, {'error': 'invalid JSON'});
    final applied = await _settings.import(body);
    return _json(200, {'applied': applied});
  }

  Future<Response> _command(Request request, String commandName) async {
    final params = await _body(request) ?? const <String, Object?>{};
    final result = await commands.execute(commandName, params);
    return _json(result.ok ? 200 : 400, result.toJson());
  }

  Future<Response> _screenshot() async {
    final result = await commands.execute('screenshot', const {});
    if (!result.ok || result.data is! String) {
      return _json(500, {'error': result.error ?? 'screenshot failed'});
    }
    return Response.ok(
      base64Decode(result.data as String),
      headers: {'content-type': 'image/png'},
    );
  }

  FutureOr<Response> _ws(Request request) {
    if (!_auth.validate(request.url.queryParameters['token'])) {
      return _json(401, {'error': 'unauthorized'});
    }
    return webSocketHandler((WebSocketChannel channel, String? protocol) {
      _wsClients.add(channel);
      _sendState(channel);
      channel.stream.listen((raw) async {
        try {
          final msg = jsonDecode(raw as String) as Map<String, dynamic>;
          if (msg['type'] == 'command' && msg['name'] is String) {
            final result = await commands.execute(
              msg['name'] as String,
              (msg['params'] as Map?)?.cast<String, Object?>() ?? const {},
            );
            channel.sink.add(jsonEncode({
              'type': 'result',
              'name': msg['name'],
              ...result.toJson(),
            }));
          }
        } catch (e) {
          log.debug(name, 'bad ws message: $e');
        }
      }, onDone: () => _wsClients.remove(channel));
    })(request);
  }

  Future<void> _sendState(WebSocketChannel channel) async {
    final device = await commands.execute('getDeviceInfo', const {});
    channel.sink.add(jsonEncode({
      'type': 'state',
      'device': device.data,
      'currentUrl': _currentUrl,
    }));
  }

  void _broadcast(Map<String, Object?> message) {
    final encoded = jsonEncode(message);
    for (final client in _wsClients) {
      client.sink.add(encoded);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Response _index() => Response.ok(
        _placeholderHtml,
        headers: {'content-type': 'text/html'},
      );

  static String? _bearerToken(Request request) {
    final header = request.headers['authorization'];
    if (header == null || !header.startsWith('Bearer ')) return null;
    return header.substring(7);
  }

  static Future<Map<String, Object?>?> _body(Request request) async {
    try {
      final text = await request.readAsString();
      final decoded = jsonDecode(text);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } catch (_) {
      return null;
    }
  }

  static Response _json(int status, Map<String, Object?> body) =>
      Response(status,
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'});

  @override
  Future<void> dispose() => _stop();
}

/// Served at `/` until the remote-ui SPA is built and bundled.
const _placeholderHtml = '''
<!doctype html>
<html>
<head><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Kiosk Satellite</title>
<style>
  body { font-family: system-ui, sans-serif; display: grid; place-items: center;
         min-height: 100vh; margin: 0; background: #0f1117; color: #e6e8ee; }
  main { text-align: center; }
  h1 { font-weight: 600; }
  code { background: #1c2030; padding: 2px 6px; border-radius: 4px; }
</style></head>
<body><main>
  <h1>&#128752; Kiosk Satellite</h1>
  <p>The remote admin UI is not built yet.</p>
  <p>The REST API is live &mdash; start with <code>POST /api/login</code>.</p>
</main></body>
</html>
''';
