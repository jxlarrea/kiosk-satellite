import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show md5;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/command_registry.dart';
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

  @override
  String get commandSource => 'remote admin';

  HttpServer? _server;

  /// Why the server is not listening, or null when it is (or when it is off
  /// on purpose). "Remote management" being on is not the same as the server
  /// running — it also needs an admin password and a free port — and the
  /// difference used to be invisible: the switch read on, nothing served,
  /// and on a restart not even a log line said so.
  final ValueNotifier<String?> stoppedReason = ValueNotifier(null);

  /// The last bind failure, kept so [stoppedReason] can name it.
  String? _startError;

  String _currentUrl = '';
  final _wsClients = <WebSocketChannel>{};
  String? _indexHtml;

  /// The SPA's stylesheet and ES modules, keyed by file name under
  /// `assets/remote-ui/static/`, discovered from the asset manifest so a
  /// new module only needs to exist to be served.
  final _staticFiles = <String, Uint8List>{};

  /// The newest device-camera frame, for the admin's snapshot preview.
  /// Mirrored off the bus rather than fetched on request: serving a cached
  /// frame is free, and the admin page refreshing must not drive captures.
  Uint8List? _lastSnapshot;
  DateTime? _lastSnapshotAt;

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
    // Minted for a fleet leader when this kiosk accepts its invitation:
    // the same signed token as a login, carrying the leader's id, which
    // the gate below reads to keep it off everything but the fleet
    // endpoints and only while that leader is this kiosk's. Ten years,
    // like an automation token; leaving the fleet is what revokes it.
    commands.register(
      Command(
        name: 'issueFleetToken',
        description:
            'A bearer token good only for the fleet endpoints, naming the '
            'leader it was minted for (the fleet sync manager asks on '
            'accept).',
        params: const {'leader': "The leader's kiosk id"},
        handler: (p) async {
          final leader = '${p['leader'] ?? ''}';
          if (leader.isEmpty) return const CommandResult.fail('leader required');
          return CommandResult.ok(
            _auth.issueToken(ttl: AuthStore.maxTtl, claims: {'fleet': leader}),
          );
        },
      ),
    );

    // The admin SPA: index.html plus the ES modules and stylesheet under
    // static/. Everything is loaded into memory up front (a few hundred KB)
    // and the page's __KSV__ token is replaced with a content hash, so the
    // static files can be cached forever while the page itself never is.
    try {
      var index = await rootBundle.loadString('assets/remote-ui/index.html');
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      const prefix = 'assets/remote-ui/static/';
      final names =
          manifest.listAssets().where((k) => k.startsWith(prefix)).toList()
            ..sort();
      final hashed = BytesBuilder(copy: false)..add(utf8.encode(index));
      for (final key in names) {
        final bytes = (await rootBundle.load(key)).buffer.asUint8List();
        _staticFiles[key.substring(prefix.length)] = bytes;
        hashed.add(bytes);
      }
      final version = md5
          .convert(hashed.takeBytes())
          .toString()
          .substring(0, 12);
      // The page pins main.js by hash, but the imports inside the modules
      // would fetch bare './x.js' URLs that the immutable cache header
      // then keeps forever. Stamp the hash into every import specifier so
      // one changed file re-fetches the whole graph.
      final import$ = RegExp(r"(from\s+'\./[A-Za-z0-9._-]+\.js)(')");
      for (final entry in _staticFiles.entries.toList()) {
        if (!entry.key.endsWith('.js')) continue;
        _staticFiles[entry.key] = utf8.encode(
          utf8
              .decode(entry.value)
              .replaceAllMapped(import$, (m) => "${m[1]}?v=$version${m[2]}"),
        );
      }
      _indexHtml = index.replaceAll('__KSV__', version);
    } catch (e) {
      log.warn(name, 'remote-ui asset missing: $e');
    }

    bus.on<PageChanged>().listen((e) => _currentUrl = e.url);
    bus.on<UrlChanged>().listen((e) => _currentUrl = e.url);
    bus.on<CameraSnapshotTaken>().listen((e) {
      _lastSnapshot = e.jpeg;
      _lastSnapshotAt = DateTime.now();
    });

    // Live event feed for connected WS clients. sound-level is excluded:
    // it fires at up to 20 Hz for the page's reactive bar and the admin
    // UI has no use for it.
    bus.stream.listen((event) {
      final wireName = event.wireName;
      if (wireName == null || wireName == 'sound-level' || _wsClients.isEmpty) {
        return;
      }
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
      _broadcast({'type': 'brightness', 'level': e.panel});
    });

    // The ambient light reading, for the live row on the Adaptive
    // brightness page: the curve's ends are typed against it. No wireName
    // (the page has no use for it), and damped at the sensor to a few a
    // minute at most.
    bus.on<LightLevelChanged>().listen((e) {
      if (_wsClients.isEmpty) return;
      _broadcast({'type': 'lightlevel', 'lux': e.lux});
    });

    // Mic level samples for the admin settings meter. No wireName (the page
    // computes its own levels), and they only flow while a client holds a
    // mic-level watch, so this is not a standing 10 Hz feed.
    bus.on<MicLevelSample>().listen((e) {
      if (_wsClients.isEmpty) return;
      _broadcast({'type': 'micLevel', 'rms': e.rms});
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
      // Losing remote access is the one settings change nobody can diagnose
      // afterwards from here, because the log this writes to is served by
      // the very server it just switched off. At warn so it also reaches
      // the platform log, where `adb logcat` can still find it.
      if (e.key == defs.remoteEnabled.key &&
          !_settings.get(defs.remoteEnabled)) {
        log.warn(name, 'remote management switched off');
      }
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
    final enabled = _settings.get(defs.remoteEnabled);
    final hasPassword = _settings.get(defs.remotePassword).isNotEmpty;
    final port = _settings.get(defs.remotePort).toInt();
    final wantRunning = _setupMode || (enabled && hasPassword);
    if (wantRunning && _server == null) {
      await _start();
    } else if (!wantRunning && _server != null) {
      await _stop();
    } else if (wantRunning && _server != null && _server!.port != port) {
      // The port changed; only that warrants a restart. A password set or
      // changed while serving (the onboarding wizard's first step sets
      // one, from this very server) used to restart it too, which cut the
      // reply to the request that set it: the browser saw a failed fetch,
      // stayed on the password step, and the next press was refused as
      // "setup already done".
      await _stop();
      await _start();
    }
    // Said every time, not only on the transition that switched it off: the
    // silent case was the one that mattered — enabled, no password, nothing
    // running, and a restart that logged nothing at all.
    stoppedReason.value = _server != null || !enabled
        ? null
        : !hasPassword
        ? 'Set an admin password below to start the server.'
        : _startError ?? 'The server is not running.';
    final reason = stoppedReason.value;
    if (reason != null) log.warn(name, 'not serving: $reason');
  }

  Future<void> _start() async {
    final port = _settings.get(defs.remotePort).toInt();
    try {
      _server = await shelf_io.serve(
        const Pipeline().addHandler(_route),
        InternetAddress.anyIPv4,
        port,
      );
      _startError = null;
      log.info(name, 'listening on :$port');
    } catch (e) {
      _startError = 'Could not listen on port $port: $e';
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
    // Released before the close, and forced: turning remote management off
    // from the remote admin closes the very connection serving that request,
    // and a graceful close waits for it forever. That left _server non-null,
    // so every later sync took the "restart" branch, awaited the same stuck
    // close, and never started anything again — the switch read on and
    // nothing served until the app was restarted.
    final server = _server;
    _server = null;
    await server?.close(force: true);
    log.info(name, 'stopped');
  }

  // ── Routing ──────────────────────────────────────────────────────────

  Future<Response> _route(Request request) async {
    final path = request.url.path;

    if (path.isEmpty || path == 'index.html') return _index();
    if (path.startsWith('static/')) {
      return _staticFile(path.substring('static/'.length));
    }
    if (path == 'api/login') return _login(request);
    if (path == 'api/ws') return _ws(request);

    // First-run onboarding. Status is public (the UI decides whether to
    // show the wizard); the password endpoint works exactly once — only
    // while no password exists on an unconfigured device — and answers
    // with a session token so the wizard continues authenticated.
    if (path == 'api/setup/status') {
      // The name the device goes by right now: what was set, or the model.
      // The wizard's first page seeds its Device name field with it, so
      // the remote and device wizards start from the same value.
      final info = await commands.execute('getDeviceInfo', const {});
      final data = info.ok ? info.data as Map? : null;
      final deviceName = data?['name'];
      return _json(200, {
        'setupNeeded': _setupMode,
        'passwordNeeded': _settings.get(defs.remotePassword).isEmpty,
        'deviceName': deviceName is String ? deviceName : '',
        // An import applied its settings but the OS permission prompts are
        // still being answered on the device; the start URL (what ends
        // setup) lands after them. The UI shows "finish on the device"
        // instead of an empty wizard.
        'importPending': _settings.importFinishing,
      });
    }
    // The wizard's first page shows the service's grants before any
    // password exists, so it cannot carry a token yet. These two answer
    // only in that window (unconfigured device, no password), the same
    // window in which anyone may set the password anyway; the moment one
    // exists the page logs in and uses the gated commands like the rest.
    final passwordless =
        _setupMode && _settings.get(defs.remotePassword).isEmpty;
    if (path == 'api/setup/grants' && request.method == 'GET') {
      if (!passwordless) return _json(403, {'error': 'setup already done'});
      final perms = await commands.execute('getSystemPermissions', const {});
      final service = await commands.execute('getServiceStatus', const {});
      return _json(200, {
        'permissions': perms.ok ? perms.data : null,
        'grants': service.ok ? (service.data as Map)['grants'] : null,
      });
    }
    if (path == 'api/setup/grant' && request.method == 'POST') {
      if (!passwordless) return _json(403, {'error': 'setup already done'});
      final body = await _body(request);
      final which = body?['which'];
      if (which is! List) return _json(400, {'error': 'which required'});
      final out = await commands.execute('requestOsPermissions', {
        'which': which,
      });
      return _json(out.ok ? 200 : 400, out.toJson());
    }
    if (path == 'api/setup/password' && request.method == 'POST') {
      if (!_setupMode) return _json(403, {'error': 'setup already done'});
      // Setting one is public (there is nothing to authenticate with yet);
      // changing one, from the wizard's Welcome step after a Back, needs
      // the session that password minted, or anyone on the network could
      // take an unconfigured tablet's admin over.
      if (_settings.get(defs.remotePassword).isNotEmpty &&
          !_auth.validate(_bearerToken(request))) {
        return _json(403, {'error': 'setup already done'});
      }
      final body = await _body(request);
      final password = body?['password'];
      if (password is! String || password.length < 4) {
        return _json(400, {'error': 'password must be at least 4 characters'});
      }
      // The first page's other field. It rides the same request because
      // before a password exists there is no session to PATCH settings
      // with; the wizard sends it whenever it sends a password.
      final deviceName = body?['deviceName'];
      if (deviceName is String) {
        await _settings.set(defs.deviceName, deviceName.trim());
      }
      await _settings.set(defs.remotePassword, password);
      await _settings.set(defs.remoteEnabled, true);
      log.info(name, 'remote password set by onboarding');
      return _json(200, {'token': _auth.issueToken()});
    }

    // Deliberately public (issue #75): the point of a health check is a
    // monitor polling it every minute, and a monitor cannot do a login
    // dance around a 7-day token. Read-only hardware facts; no settings,
    // no secrets, no page content.
    if (path == 'api/health' && request.method == 'GET') return _health();

    // Fleet Management's public face, for a kiosk that has no token here
    // yet: who this kiosk is, an invitation to follow (which waits on the
    // screen and decides nothing by itself) and what became of one. The
    // nonce in the invitation is the only secret in the exchange.
    if (path == 'api/fleet/identity' && request.method == 'GET') {
      final r = await commands.execute('fleetIdentity', const {});
      return r.ok
          ? _json(200, (r.data as Map).cast<String, Object?>())
          : _json(503, {'error': r.error});
    }
    if (path == 'api/fleet/invite' && request.method == 'POST') {
      final ip = _clientIp(request);
      final last = _inviteAt[ip];
      final now = DateTime.now();
      if (last != null && now.difference(last) < const Duration(seconds: 3)) {
        return _json(429, {'error': 'too many invitations'});
      }
      _inviteAt[ip] = now;
      final body = await _body(request);
      if (body == null) return _json(400, {'error': 'invalid JSON'});
      final r = await commands.execute('fleetInviteReceived', {
        ...body,
        // Where it really came from, whatever the body says.
        'address': ip,
      });
      return _json(r.ok ? 200 : 400, r.toJson());
    }
    if (path.startsWith('api/fleet/invite/') && request.method == 'GET') {
      final r = await commands.execute('fleetInvitePoll', {
        'invite': path.substring('api/fleet/invite/'.length),
      });
      return _json(200, (r.data as Map?)?.cast<String, Object?>() ?? {});
    }

    if (!path.startsWith('api/')) return Response.notFound('not found');

    // Everything else under /api/ requires a bearer token.
    final token = _bearerToken(request);
    if (!_auth.validate(token)) {
      return _json(401, {'error': 'unauthorized'});
    }
    // A fleet token is a leader's, not an admin's: it opens the fleet
    // endpoints and the update commands, nothing else and only while the
    // leader it names is the one this kiosk follows. Leaving the fleet
    // revokes every token that leader holds without a revocation list.
    final fleetClaim = _auth.claimsOf(token)?['fleet'];
    if (fleetClaim != null) {
      if (fleetClaim != _followedLeaderId) {
        return _json(403, {'error': "not this kiosk's leader"});
      }
      if (!_fleetScoped.contains(path)) {
        return _json(403, {'error': 'fleet token'});
      }
    }

    switch ((request.method, path)) {
      case ('GET', 'api/info'):
        return _info();
      case ('GET', 'api/settings'):
        return _json(200, {
          'settings': _settings.describe(),
          // Named second-level pages, so the remote can label an entry
          // row for a page that has no settings of its own.
          'subpageHints': subpageHints,
        });
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
        // The body is the config file itself, so the import options ride
        // as query parameters ("0"/"false" = off, anything else = on).
        bool flag(String name) {
          final v = request.url.queryParameters[name];
          return v != '0' && v != 'false';
        }
        final imported = await commands.execute('importConfig', {
          'config': body,
          'adoptIdentity': flag('adoptIdentity'),
          'importLocalStorage': flag('importLocalStorage'),
        });
        return _json(imported.ok ? 200 : 400, imported.toJson());
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
      case ('GET', 'api/media/artwork'):
        return _artwork();
      case ('GET', 'api/camera/snapshot'):
        final snapshot = _lastSnapshot;
        if (snapshot == null) {
          return _json(404, {'error': 'no snapshot has been taken yet'});
        }
        return Response.ok(
          snapshot,
          headers: {
            'Content-Type': 'image/jpeg',
            'Cache-Control': 'no-store',
            'X-Snapshot-At': _lastSnapshotAt!.toUtc().toIso8601String(),
          },
        );
      case ('GET', 'api/fleet/status'):
        final r = await commands.execute('fleetFollowerStatus', const {});
        return _json(200, (r.data as Map?)?.cast<String, Object?>() ?? {});
      case ('POST', 'api/fleet/apply'):
        final body = await _body(request);
        if (body == null) return _json(400, {'error': 'invalid JSON'});
        final r = await commands.execute('fleetApply', body);
        return _json(r.ok ? 200 : 400, r.toJson());
      case ('POST', 'api/fleet/leave'):
        final r = await commands.execute('fleetLeaderLeft', const {});
        return _json(200, r.toJson());
      case ('GET', 'api/files/download'):
        return _fileDownload(request);
      case ('POST', 'api/files/upload'):
        return _fileUpload(request);
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
      // ttl_days (issue #84): a Home Assistant rest_command cannot redo the
      // login dance every week, so an automation logs in once with a long
      // expiry and pastes the token into its config for good.
      final days = (body?['ttl_days'] as num?)?.toInt();
      return _json(200, {
        'token': _auth.issueToken(
          ttl: days == null ? null : Duration(days: days),
        ),
      });
    }
    _auth.recordFailure(ip);
    log.warn(name, 'failed login from $ip');
    return _json(401, {'error': 'invalid password'});
  }

  Future<Response> _info() async {
    return _json(200, await _deviceState());
  }

  /// The Device Info tab's Hardware section as one JSON read (issue #75):
  /// identity, addresses, battery, screen, memory, storage, CPU load and
  /// temperature, and the app and network uptimes. One stable shape for
  /// external monitoring to poll, instead of the three command calls the
  /// admin UI assembles the same rows from.
  Future<Response> _health() async {
    final device = await commands.execute('getDeviceInfo', const {});
    final details = await commands.execute('getDeviceDetails', const {});
    final screenOn = await commands.execute('isScreenOn', const {});
    final brightness = await commands.execute('getBrightness', const {});
    final info = (device.data as Map?)?.cast<String, Object?>() ?? const {};
    final det = (details.data as Map?)?.cast<String, Object?>() ?? const {};
    return _json(200, {
      'name': info['name'],
      'model': info['model'],
      'brand': det['brand'],
      'androidVersion': info['osVersion'],
      'sdkInt': info['sdkInt'],
      'androidBuild': det['androidBuild'],
      'appVersion': info['appVersion'],
      'ip': info['ip'],
      'ipv6': info['ipv6'],
      'battery': info['battery'],
      'charging': info['charging'],
      'screenOn': screenOn.ok ? screenOn.data : null,
      'brightness': (brightness.data as num?)?.toDouble(),
      'screen': det['screen'],
      'ram': det['ram'],
      'storage': det['storage'],
      'cpu': {'usage': info['cpu'], 'temp': info['temp']},
      // Seconds. `network` is null while offline; its clock starts at app
      // start at the earliest (see DeviceDetails.uptime).
      'uptime': info['uptime'],
    });
  }

  /// What the device is doing, as the admin's dashboard draws it.
  ///
  /// Brightness comes from the screen manager rather than getDeviceInfo, which
  /// is about identity and battery. It belongs here because the admin shows a
  /// brightness control: a slider with nothing behind it is not a control, it
  /// is a decoration that happens to send.
  ///
  /// The screen, screensaver and camera view states are here for the same
  /// reason: the dashboard's quick controls are one tile each that reads
  /// "Screen off" or "Screen on" by what the panel is doing, and a tile
  /// born saying one of them before anyone asked would be guessing. Live
  /// changes reach the client through the event feed (screenon/screenoff,
  /// screensaverstart/screensaverstop, cameraview); this is the snapshot
  /// they diff against.
  Future<Map<String, Object?>> _deviceState() async {
    final device = await commands.execute('getDeviceInfo', const {});
    final brightness = await commands.execute('getBrightness', const {});
    final screenOn = await commands.execute('isScreenOn', const {});
    final screensaver = await commands.execute('isScreensaverActive', const {});
    final cameraView = await commands.execute('getCameraViewState', const {});
    return {
      ...?(device.data as Map<String, Object?>?),
      'brightness': (brightness.data as num?)?.toDouble(),
      'screenOn': screenOn.ok ? screenOn.data as bool? : null,
      'screensaverActive': screensaver.ok ? screensaver.data as bool? : null,
      'cameraView': cameraView.ok ? cameraView.data : null,
      'currentUrl': _currentUrl,
    };
  }

  Future<Response> _patchSettings(Request request) async {
    final body = await _body(request);
    if (body == null) return _json(400, {'error': 'invalid JSON'});
    final rejected = <String>[];
    // The validator's own words per rejected key, where a definition has
    // one, so the page can say what was wrong with the value instead of
    // silently keeping the old one.
    final errors = <String, String>{};
    for (final entry in body.entries) {
      if (!await _settings.setFromJson(
        entry.key,
        entry.value,
        source: 'remote admin',
        batch: body,
      )) {
        rejected.add(entry.key);
        final def = _settings.defByKey(entry.key);
        final message = def == null
            ? null
            : _settings.validate(def, entry.value, batch: body);
        if (message != null) errors[entry.key] = message;
      }
    }
    return _json(200, {
      'ok': rejected.isEmpty,
      'rejected': rejected,
      'errors': errors,
    });
  }

  Future<Response> _import(Request request) async {
    final body = await _body(request);
    if (body == null) return _json(400, {'error': 'invalid JSON'});
    // Provisioning a second device from another's dump must not carry the
    // source's identity along, exactly like /api/config/import (issue
    // #221): adoptIdentity=0 keeps this device's own name, ESPHome node
    // name and Sendspin player id. Default on, matching importConfig, so a
    // same-device restore keeps its discovered HA device.
    final adopt = request.url.queryParameters['adoptIdentity'];
    if (adopt == '0' || adopt == 'false') {
      await _settings.shedImportedIdentity(body);
      // A settings dump carries no localStorage, so this seed setting is
      // the only carrier of the Voice Satellite selection here, and two
      // devices answering as one assist_satellite displace each other
      // mid-turn.
      body.remove(defs.haSatelliteEntity.key);
    }
    final applied = await _settings.import(body);
    return _json(200, {'applied': applied});
  }

  Future<Response> _command(Request request, String commandName) async {
    if (_deviceOnly.contains(commandName)) {
      return _json(403, {'error': 'answered on the kiosk itself'});
    }
    final params = await _body(request) ?? const <String, Object?>{};
    final result = await commands.execute(commandName, params);
    return _json(result.ok ? 200 : 400, result.toJson());
  }

  /// Commands that only the kiosk's own screen may run: accepting a fleet
  /// invitation is the one confirmation the remote admin must not give.
  static const _deviceOnly = {'fleetAccept', 'fleetDecline'};

  /// What a fleet token opens: the follower's side of the fleet wire and
  /// the update commands the leader drives.
  static const _fleetScoped = {
    'api/fleet/status',
    'api/fleet/apply',
    'api/fleet/leave',
    'api/commands/getUpdateStatus',
    'api/commands/checkUpdateNow',
    'api/commands/installUpdate',
  };

  /// One invitation per client every few seconds: the endpoint is public.
  final _inviteAt = <String, DateTime>{};

  /// The id of the leader this kiosk follows or null.
  String? get _followedLeaderId {
    final raw = _settings.get(defs.fleetLeaderInfo);
    if (raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      final id = map is Map ? map['id'] : null;
      return id is String && id.isNotEmpty ? id : null;
    } catch (_) {
      return null;
    }
  }

  static String _clientIp(Request request) =>
      (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)
          ?.remoteAddress
          .address ??
      'unknown';

  /// Path safety for both file endpoints lives in the files manager
  /// (fileResolve refuses anything escaping its root); these only stream.
  Future<String?> _resolveFilePath(Request request) async {
    final resolved = await commands.execute('fileResolve', {
      'root': request.url.queryParameters['root'],
      'path': request.url.queryParameters['path'],
    });
    final data = resolved.data;
    return resolved.ok && data is Map ? data['path'] as String? : null;
  }

  Future<Response> _fileDownload(Request request) async {
    final path = await _resolveFilePath(request);
    if (path == null) return _json(400, {'error': 'invalid path'});
    final file = File(path);
    if (!await file.exists()) return _json(404, {'error': 'no such file'});
    final name = Uri.encodeComponent(file.uri.pathSegments.last);
    return Response.ok(
      file.openRead(),
      headers: {
        'content-type': 'application/octet-stream',
        'content-length': '${await file.length()}',
        'content-disposition': 'attachment; filename="$name"',
      },
    );
  }

  Future<Response> _fileUpload(Request request) async {
    final path = await _resolveFilePath(request);
    if (path == null) return _json(400, {'error': 'invalid path'});
    final file = File(path);
    try {
      await file.parent.create(recursive: true);
      final sink = file.openWrite();
      try {
        await sink.addStream(request.read());
      } finally {
        await sink.close();
      }
    } on FileSystemException catch (e) {
      return _json(500, {
        'error': 'write failed: ${e.osError?.message ?? e.message}',
      });
    }
    log.info(name, 'uploaded ${file.path} (${await file.length()} bytes)');
    return _json(200, {'ok': true, 'size': await file.length()});
  }

  Future<Response> _screenshot() async {
    final result = await commands.execute('screenshot', const {});
    if (!result.ok || result.data is! String) {
      return _json(500, {'error': result.error ?? 'screenshot failed'});
    }
    final bytes = base64Decode(result.data as String);
    // Captures are JPEG; the screen-off placeholder is PNG. Label by the
    // magic bytes rather than promising one of them.
    final png = bytes.length > 1 && bytes[0] == 0x89 && bytes[1] == 0x50;
    // A person asked to see the screen: the Home Assistant twins get the
    // same frame and Last screenshot moves with it.
    bus.publish(ScreenshotTaken(jpeg: bytes));
    return Response.ok(
      bytes,
      headers: {'content-type': png ? 'image/png' : 'image/jpeg'},
    );
  }

  /// The shown track's cover, fetched by the device: a browser cannot
  /// load it from a Music Assistant image proxy on a self-signed address.
  Future<Response> _artwork() async {
    final result = await commands.execute('sendspinArtwork', const {});
    if (!result.ok || result.data is! Map) {
      return _json(404, {'error': result.error ?? 'no artwork'});
    }
    final data = result.data as Map;
    final bytes = base64Decode('${data['data']}');
    // Label by the magic bytes rather than trusting the URL's extension.
    final type = bytes.length > 3 && bytes[0] == 0x89 && bytes[1] == 0x50
        ? 'image/png'
        : bytes.length > 3 && bytes[0] == 0x47 && bytes[1] == 0x49
        ? 'image/gif'
        : bytes.length > 11 && bytes[8] == 0x57 && bytes[9] == 0x45
        ? 'image/webp'
        : 'image/jpeg';
    return Response.ok(
      bytes,
      headers: {
        'Content-Type': type,
        'Cache-Control': 'no-store',
        'X-Artwork-Url': '${data['url']}',
      },
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
              if (msg['type'] == 'command' &&
                  msg['name'] is String &&
                  !_deviceOnly.contains(msg['name'])) {
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
    headers: {
      'content-type': 'text/html; charset=utf-8',
      // The page pins its static files by content hash (?v=), so it must
      // never be cached itself: a stale page would pin stale modules.
      'cache-control': 'no-store',
    },
  );

  /// Static files are public like the page itself (the login gate lives in
  /// the page, not around it) and content-addressed via the ?v= hash, so
  /// far-future caching is safe: any change serves under a new URL.
  Response _staticFile(String name) {
    final bytes = _staticFiles[name];
    if (bytes == null) return Response.notFound('not found');
    const types = {
      'js': 'text/javascript; charset=utf-8',
      'css': 'text/css; charset=utf-8',
      'svg': 'image/svg+xml',
      'png': 'image/png',
      'woff2': 'font/woff2',
    };
    final ext = name.split('.').last;
    return Response.ok(
      bytes,
      headers: {
        'content-type': types[ext] ?? 'application/octet-stream',
        'cache-control': 'public, max-age=31536000, immutable',
      },
    );
  }

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
