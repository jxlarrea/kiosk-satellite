import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:flutter/services.dart' show rootBundle;
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
  late final AuthStore _auth;

  @override
  String get name => 'remote';

  HttpServer? _server;
  String _currentUrl = '';
  final _wsClients = <WebSocketChannel>{};
  String? _indexHtml;

  @override
  Future<void> init() async {
    // Persistent signing secret → tokens survive app restarts.
    final secret = await _settings.secret('remote_auth', () {
      final random = Random.secure();
      return base64Url.encode(
        List<int>.generate(32, (_) => random.nextInt(256)),
      );
    });
    _auth = AuthStore(secret);

    // The admin SPA is a single self-contained asset.
    try {
      _indexHtml = await rootBundle.loadString('assets/remote-ui/index.html');
    } catch (e) {
      log.warn(name, 'remote-ui asset missing: $e');
    }

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

    // Relay the page's JS console to admin clients (ConsoleMessage has no
    // wireName, so it is not covered by the generic event feed above).
    bus.on<ConsoleLine>().listen((event) {
      if (_wsClients.isEmpty) return;
      _broadcast({'type': 'console', ...event.toJson()});
    });

    // Brightness, which the screensaver and the Voice Satellite card both
    // change behind the admin's back. No wireName either, so the generic feed
    // skips it and the dashboard's slider sat at whatever it was born with.
    bus.on<BrightnessChanged>().listen((e) {
      if (_wsClients.isEmpty) return;
      _broadcast({'type': 'brightness', 'level': e.level});
    });

    // Wake-word state, likewise: no wireName, so the generic feed skips it.
    //
    // The admin shows the same wake-word panel as the device's own settings
    // screen, and that one updates live off this event. Without relaying it,
    // the remote copy silently went stale — toggle the master switch and the
    // status, engine and wake words all kept describing the state before the
    // toggle until someone reloaded the page. Two views of one device that
    // disagree are worse than one view.
    bus.on<WakeWordStateChanged>().listen((_) {
      if (_wsClients.isEmpty) return;
      _broadcast({'type': 'wakeword-state'});
    });

    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.remoteEnabled.key ||
          e.key == defs.remotePort.key ||
          e.key == defs.remotePassword.key ||
          // Setup completing (start URL set) may mean the server should
          // stop — the wizard ran on the setup-mode allowance alone.
          e.key == defs.startUrl.key) {
        _sync();
      }
    });

    // Live header stats. Battery, CPU load and temperature change on their own,
    // so push them on a cadence rather than only at connect. Cheap while nobody
    // is watching — it does nothing with no clients — and deliberately its own
    // lean message, not a full state re-push, so it never disturbs the
    // brightness slider or url the admin might be interacting with.
    _statsTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_wsClients.isEmpty) return;
      // getStats, not getDeviceInfo: the full read walks every network
      // interface to answer questions this tick never asks.
      final info = await commands.execute('getStats', const {});
      final data = info.data;
      if (data is! Map) return;
      _broadcast({
        'type': 'stats',
        'battery': data['battery'],
        'charging': data['charging'],
        'cpu': data['cpu'],
        'temp': data['temp'],
      });
    });

    await _sync();
  }

  Timer? _statsTimer;

  /// Unconfigured device: the remote onboarding wizard must be reachable,
  /// password or not — its own first step is to set one.
  bool get _setupMode => _settings.get(defs.startUrl).isEmpty;

  Future<void> _sync() async {
    final wantRunning =
        _setupMode ||
        (_settings.get(defs.remoteEnabled) &&
            _settings.get(defs.remotePassword).isNotEmpty);
    if (wantRunning && _server == null) {
      await _start();
    } else if (!wantRunning && _server != null) {
      await _stop();
      if (_settings.get(defs.remoteEnabled)) {
        log.warn(
          name,
          'remote enabled but no admin password set; not starting',
        );
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
      // Not awaited: a dead peer's close never completes and would stall
      // the settings-driven restart behind it.
      unawaited(client.sink.close());
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

    // First-run onboarding. Status is public (the UI decides whether to
    // show the wizard); the password endpoint works exactly once — only
    // while no password exists on an unconfigured device — and answers
    // with a session token so the wizard continues authenticated.
    if (path == 'api/setup/status') {
      return _json(200, {
        'setupNeeded': _setupMode,
        'passwordNeeded': _settings.get(defs.remotePassword).isEmpty,
      });
    }
    if (path == 'api/setup/password' && request.method == 'POST') {
      if (!_setupMode || _settings.get(defs.remotePassword).isNotEmpty) {
        return _json(403, {'error': 'setup already done'});
      }
      final body = await _body(request);
      final password = body?['password'];
      if (password is! String || password.length < 4) {
        return _json(400, {'error': 'password must be at least 4 characters'});
      }
      await _settings.set(defs.remotePassword, password);
      await _settings.set(defs.remoteEnabled, true);
      log.info(name, 'remote password set by onboarding');
      return _json(200, {'token': _auth.issueToken()});
    }

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
      // The full backup: settings with secrets plus the page's
      // localStorage — strictly bearer-gated like everything else here.
      case ('GET', 'api/config/export'):
        final exported = await commands.execute('exportConfig', const {});
        return exported.ok
            ? _json(200, (exported.data as Map).cast<String, Object?>())
            : _json(500, {'error': exported.error});
      case ('POST', 'api/config/import'):
        final body = await _body(request);
        if (body == null) return _json(400, {'error': 'invalid JSON'});
        final imported = await commands.execute('importConfig', {
          'config': body,
        });
        return _json(
          imported.ok ? 200 : 400,
          imported.toJson(),
        );
      case ('GET', 'api/commands'):
        return _json(200, {
          'commands': [
            for (final c in commands.all)
              {
                'name': c.name,
                'description': c.description,
                'params': c.params,
              },
          ],
        });
      case ('GET', 'api/logs'):
        return _json(200, {
          'logs': [for (final e in log.recent) e.toJson()],
        });
      case ('GET', 'api/console'):
        final console = await commands.execute('getConsole', const {});
        return _json(200, {'console': console.data});
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
    return _json(200, await _deviceState());
  }

  /// What the device is doing, as the admin's dashboard draws it.
  ///
  /// Brightness comes from the screen manager rather than getDeviceInfo, which
  /// is about identity and battery. It belongs here because the admin shows a
  /// brightness control: a slider with nothing behind it is not a control, it
  /// is a decoration that happens to send.
  Future<Map<String, Object?>> _deviceState() async {
    final device = await commands.execute('getDeviceInfo', const {});
    final brightness = await commands.execute('getBrightness', const {});
    return {
      ...?(device.data as Map<String, Object?>?),
      'brightness': (brightness.data as num?)?.toDouble(),
      'currentUrl': _currentUrl,
    };
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
      headers: {'content-type': 'image/jpeg'},
    );
  }

  FutureOr<Response> _ws(Request request) {
    if (!_auth.validate(request.url.queryParameters['token'])) {
      return _json(401, {'error': 'unauthorized'});
    }
    return webSocketHandler(
      // Pings reap silently-vanished peers (phone left wifi, laptop lid
      // closed). Without them the channel never errors, the client stays
      // in _wsClients, and every broadcast queues into a socket nobody
      // reads — an unbounded buffer on exactly the feed that carries the
      // page's whole console output.
      pingInterval: const Duration(seconds: 30),
      (WebSocketChannel channel, String? protocol) {
        _wsClients.add(channel);
        _sendState(channel);
        channel.stream.listen(
          (raw) async {
            try {
              final msg = jsonDecode(raw as String) as Map<String, dynamic>;
              if (msg['type'] == 'command' && msg['name'] is String) {
                final result = await commands.execute(
                  msg['name'] as String,
                  (msg['params'] as Map?)?.cast<String, Object?>() ?? const {},
                );
                channel.sink.add(
                  jsonEncode({
                    'type': 'result',
                    'name': msg['name'],
                    ...result.toJson(),
                  }),
                );
              }
            } catch (e) {
              log.debug(name, 'bad ws message: $e');
            }
          },
          onDone: () => _wsClients.remove(channel),
          onError: (_) => _wsClients.remove(channel),
        );
      },
    )(request);
  }

  Future<void> _sendState(WebSocketChannel channel) async {
    final state = await _deviceState();
    channel.sink.add(
      jsonEncode({
        'type': 'state',
        'device': state,
        'currentUrl': state['currentUrl'],
      }),
    );
  }

  void _broadcast(Map<String, Object?> message) {
    final encoded = jsonEncode(message);
    for (final client in _wsClients) {
      client.sink.add(encoded);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Response _index() => Response.ok(
    _indexHtml ?? _placeholderHtml,
    headers: {'content-type': 'text/html; charset=utf-8'},
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

  static Response _json(int status, Map<String, Object?> body) => Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );

  @override
  Future<void> dispose() {
    _statsTimer?.cancel();
    return _stop();
  }
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
