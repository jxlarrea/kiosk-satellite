import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random, min;

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/kiosk_http_client.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import '../voice/assist_view.dart';
import '../voice/companion_voice.dart';

/// A kiosk that shows this kiosk's voice sessions, as the active kiosk
/// keeps it.
class CompanionScreen {
  CompanionScreen({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    required this.tls,
    required this.nonce,
    required this.status,
    required this.addedAt,
  });

  final String id;
  String name;
  String address;
  int port;
  bool tls;

  /// The nonce of the invitation. The companion presents it to open the
  /// stream.
  final String nonce;

  /// `pending`, `accepted`, `declined` or `left`.
  String status;
  final int addedAt;

  String get url =>
      Uri(scheme: tls ? 'https' : 'http', host: address, port: port).toString();

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'port': port,
    'tls': tls,
    'nonce': nonce,
    'status': status,
    'addedAt': addedAt,
  };

  static CompanionScreen? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final nonce = raw['nonce'];
    if (id is! String || id.isEmpty || nonce is! String || nonce.isEmpty) {
      return null;
    }
    return CompanionScreen(
      id: id,
      name: '${raw['name'] ?? ''}',
      address: '${raw['address'] ?? ''}',
      port: (raw['port'] as num?)?.toInt() ?? 0,
      tls: raw['tls'] == true,
      nonce: nonce,
      status: '${raw['status'] ?? 'pending'}',
      addedAt: (raw['addedAt'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Companion screens: a kiosk shows the voice sessions of another kiosk.
///
/// The active kiosk runs Voice Satellite as it always does. Each companion
/// screen it invited opens a WebSocket to it (`/api/companion/stream` on its
/// remote admin port, before the password) and receives what its overlay
/// shows: the view snapshot each time it changes and, while a session is on
/// screen, the bar's level, the docked countdown and the answer's playback
/// a few times a second. The companion draws it with its own appearance
/// settings. A dismissal or a result opened on the companion goes back
/// over the same socket.
///
/// There is no key to set up. The active kiosk sends the invitation with a
/// random nonce, the companion accepts it on its screen or in its remote
/// admin, and the nonce is what the companion presents from then on. Only
/// the active kiosk can invite, and a companion screen shows one kiosk.
class CompanionManager extends Manager {
  CompanionManager(
    super.bus,
    super.commands,
    super.log,
    this._settings,
    this._voice, {
    http.Client Function()? clientFactory,
    WebSocketChannel Function(Uri uri)? socketFactory,
  }) : _clientFactory = clientFactory ?? kioskPeerClient,
       _socketFactory = socketFactory ?? _connectPeer;

  final SettingsManager _settings;
  final CompanionVoice _voice;
  final http.Client Function() _clientFactory;
  final WebSocketChannel Function(Uri uri) _socketFactory;

  @override
  String get name => 'companion';

  static const _requestTimeout = Duration(seconds: 6);

  /// How often the bar's level and the countdown go out while a session is
  /// on screen.
  static const tickEvery = Duration(milliseconds: 66);

  /// How often a pending invitation is asked about.
  static const _pollEvery = Duration(seconds: 5);

  /// An unanswered invitation on the companion is dropped after a day.
  static const _inviteLifetime = Duration(days: 1);

  final _subs = <StreamSubscription<Object?>>[];
  bool _disposed = false;

  // ── the active kiosk ──────────────────────────────────────────────────

  /// The streams open to companion screens, by companion id.
  final _streams = <String, WebSocketChannel>{};
  Timer? _tick;
  Timer? _poll;
  double _sentLevel = -1;
  double _sentCountdown = -1;

  // ── the companion screen ──────────────────────────────────────────────

  WebSocketChannel? _link;
  StreamSubscription<Object?>? _linkSub;
  Timer? _retry;
  int _attempt = 0;
  int _linkGeneration = 0;

  /// `idle`, `connecting`, `connected`, `offline` or `refused`.
  String _linkState = 'idle';
  String _linkError = '';

  /// This kiosk to the others, from the discovery directory.
  Map<String, Object?> _self = const {};

  /// Whether the discovery of other kiosks runs, which inviting needs.
  bool _discovery = false;

  Map<String, Map<String, Object?>> _devices = const {};

  // ── settings ──────────────────────────────────────────────────────────

  /// This kiosk runs the satellite and can stream to companion screens.
  bool get _active => _voice.nativeRuntime && _settings.voiceSatelliteOn;

  bool get _companion => _voice.companionScreen;

  List<CompanionScreen> get screens {
    try {
      final decoded = jsonDecode(_settings.get(defs.voiceCompanionScreens));
      if (decoded is! List) return [];
      return [for (final e in decoded) ?CompanionScreen.fromJson(e)];
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveScreens(List<CompanionScreen> list) => _settings.set(
    defs.voiceCompanionScreens,
    list.isEmpty ? '' : jsonEncode([for (final s in list) s.toJson()]),
  );

  Map<String, Object?>? _readJson(defs.SettingDef<String> def) {
    final raw = _settings.get(def);
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } catch (_) {
      return null;
    }
  }

  /// The kiosk this companion screen shows.
  Map<String, Object?>? get companionOf => _readJson(defs.voiceCompanionOf);

  Map<String, Object?>? get invite => _readJson(defs.voiceCompanionInvite);

  /// The invitation waiting for an answer on this kiosk, if any.
  Map<String, Object?>? get pendingInvite {
    final inv = invite;
    return inv != null && inv['status'] == 'pending' ? inv : null;
  }

  // ── lifecycle ─────────────────────────────────────────────────────────

  @override
  Future<void> init() async {
    _registerCommands();
    _voice.companionDismiss = () => _sendLink({'t': 'dismiss'});
    _voice.companionHold = ({bool silence = false}) =>
        _sendLink({'t': 'hold', 'silence': silence});
    _voice.view.addListener(_onView);
    _subs.add(
      bus.on<SettingChanged>().listen((e) {
        if (e.key == defs.voiceEnabled.key ||
            e.key == defs.voiceCompanionMode.key ||
            e.key == defs.voiceRuntime.key) {
          _sync();
        }
      }),
    );
    // Discovery's own list, with no command to log for each change.
    _subs.add(
      bus.on<FleetChanged>().listen((e) => unawaited(_applyDevices(e.devices))),
    );
    // A day old and never answered: whoever sent it has moved on.
    final inv = invite;
    final at = (inv?['at'] as num?)?.toInt() ?? 0;
    if (inv != null &&
        DateTime.now().millisecondsSinceEpoch - at >
            _inviteLifetime.inMilliseconds) {
      await _settings.set(defs.voiceCompanionInvite, '');
    }
    await _readFleet(force: true);
    _sync();
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _voice.view.removeListener(_onView);
    _voice.companionDismiss = null;
    _voice.companionHold = null;
    _tick?.cancel();
    _poll?.cancel();
    _retry?.cancel();
    await _linkSub?.cancel();
    await _link?.sink.close();
    // Closing one fires its onDone, which takes it off the map.
    final streams = _streams.values.toList();
    _streams.clear();
    for (final s in streams) {
      await s.sink.close();
    }
    for (final sub in _subs) {
      await sub.cancel();
    }
  }

  /// Brings both roles in line with the settings.
  void _sync() {
    if (_disposed) return;
    if (!_active) {
      for (final id in _streams.keys.toList()) {
        _closeStream(id);
      }
    }
    _schedulePoll();
    if (_companion && companionOf != null) {
      if (_link == null && _retry == null) _connect();
    } else {
      _disconnect();
    }
    _changed();
  }

  void _changed() {
    bus.publish(const CompanionChanged());
    bus.publish(const RemoteStatusChanged('companion'));
  }

  int _fleetReadAt = 0;

  /// The kiosks on the network, from the `fleet` command. A status read
  /// takes the list from the last few seconds; inviting and connecting
  /// read it fresh.
  Future<void> _readFleet({bool force = false}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - _fleetReadAt < 10000) return;
    final r = await commands.execute('fleet', const {});
    final data = r.data;
    if (!r.ok || data is! Map) return;
    _fleetReadAt = now;
    _discovery = data['enabled'] == true;
    await _applyDevices(data['devices'] as List? ?? const []);
  }

  Future<void> _applyDevices(List<Object?> heard) async {
    final devices = <String, Map<String, Object?>>{};
    for (final d in heard) {
      if (d is! Map) continue;
      final id = '${d['id'] ?? ''}';
      if (id.isEmpty) continue;
      if (d['self'] == true) {
        _self = d.cast<String, Object?>();
      } else {
        devices[id] = d.cast<String, Object?>();
      }
    }
    _devices = devices;
    // Addresses move: keep the saved ones current from what discovery
    // heard, as Fleet does for its followers.
    final list = screens;
    var moved = false;
    for (final s in list) {
      final d = devices[s.id];
      if (d == null) continue;
      final address = '${d['address'] ?? ''}';
      final port = (d['port'] as num?)?.toInt() ?? s.port;
      final tls = d['tls'] == true;
      final name = '${d['name'] ?? s.name}';
      if (address.isNotEmpty &&
          (address != s.address ||
              port != s.port ||
              tls != s.tls ||
              name != s.name)) {
        s
          ..address = address
          ..port = port
          ..tls = tls
          ..name = name;
        moved = true;
      }
    }
    if (moved) await _saveScreens(list);
  }

  String get _selfId => '${_self['id'] ?? ''}';
  String get _selfName => '${_self['name'] ?? ''}';

  // ── commands ──────────────────────────────────────────────────────────

  void _registerCommands() {
    commands
      ..register(
        Command(
          name: 'companionStatus',
          description:
              'Companion screens: whether this kiosk is one, the kiosk it '
              'shows and its link, an invitation waiting here, and the '
              'companion screens of this kiosk with their state.',
          quiet: true,
          handler: (_) async {
            await _readFleet();
            return CommandResult.ok(describe());
          },
        ),
      )
      ..register(
        Command(
          name: 'companionCandidates',
          description:
              'The kiosks on the network that can be invited as companion '
              'screens, with whether companion screen mode is on there.',
          quiet: true,
          handler: (_) async => CommandResult.ok(await _candidates()),
        ),
      )
      ..register(
        Command(
          name: 'companionInvite',
          description: 'Invite a kiosk to show this kiosk\'s voice sessions.',
          params: const {'id': 'The kiosk id, from companionCandidates'},
          handler: (p) => _invite('${p['id'] ?? ''}'),
        ),
      )
      ..register(
        Command(
          name: 'companionRemove',
          description:
              'Stop showing this kiosk\'s voice sessions on a companion '
              'screen.',
          params: const {'id': 'The companion screen id'},
          handler: (p) => _remove('${p['id'] ?? ''}'),
        ),
      )
      ..register(
        Command(
          name: 'companionAccept',
          description:
              'Accept the invitation waiting on this companion screen.',
          handler: (_) => _accept(),
        ),
      )
      ..register(
        Command(
          name: 'companionDecline',
          description:
              'Decline the invitation waiting on this companion screen.',
          handler: (_) => _decline(),
        ),
      )
      ..register(
        Command(
          name: 'companionStop',
          description:
              'Stop showing the voice sessions of the kiosk this companion '
              'screen shows.',
          handler: (_) => _stop(),
        ),
      )
      // The wire, from the routes before the password.
      ..register(
        Command(
          name: 'companionIdentity',
          description:
              'Internal: who this kiosk is to a kiosk inviting companion '
              'screens.',
          quiet: true,
          handler: (_) async {
            await _readFleet();
            final of = companionOf;
            return CommandResult.ok({
              'id': _selfId,
              'name': _selfName,
              'companion': _companion,
              'of': ?of?['name'],
              'ofId': ?of?['id'],
            });
          },
        ),
      )
      ..register(
        Command(
          name: 'companionInviteReceived',
          description: 'Internal: an invitation from another kiosk.',
          quiet: true,
          handler: _received,
        ),
      )
      ..register(
        Command(
          name: 'companionInvitePoll',
          description: 'Internal: what became of an invitation.',
          quiet: true,
          handler: (p) async =>
              CommandResult.ok(await _pollAnswer('${p['nonce'] ?? ''}')),
        ),
      )
      ..register(
        Command(
          name: 'companionLeave',
          description:
              'Internal: the kiosk this companion screen shows took it off.',
          quiet: true,
          handler: (p) => _takenOff('${p['nonce'] ?? ''}'),
        ),
      )
      ..register(
        Command(
          name: 'companionLeft',
          description:
              'Internal: a companion screen stopped showing this kiosk.',
          quiet: true,
          handler: (p) =>
              _companionLeft('${p['id'] ?? ''}', '${p['nonce'] ?? ''}'),
        ),
      )
      ..register(
        Command(
          name: 'companionStreamVerify',
          description:
              'Internal: whether a companion screen may open its stream.',
          quiet: true,
          handler: (p) async => _verifyStream(
            '${p['id'] ?? ''}',
            '${p['nonce'] ?? ''}',
            '${p['address'] ?? ''}',
          ),
        ),
      )
      ..register(
        Command(
          name: 'companionAttach',
          description: 'Internal: a companion screen\'s stream opened.',
          quiet: true,
          handler: (p) async {
            final channel = p['channel'];
            if (channel is! WebSocketChannel) {
              return const CommandResult.fail('no channel');
            }
            _attach('${p['id'] ?? ''}', channel);
            return const CommandResult.ok();
          },
        ),
      );
  }

  Map<String, Object?> describe() {
    final of = companionOf;
    final inv = pendingInvite;
    final from = inv?['from'];
    return {
      'mode': _settings.get(defs.voiceCompanionMode),
      'companion': _companion,
      'discovery': _discovery,
      if (of != null)
        'of': {
          'id': of['id'],
          'name': _devices['${of['id']}']?['name'] ?? of['name'],
          'state': _linkState,
          if (_linkError.isNotEmpty) 'error': _linkError,
        },
      if (from is Map)
        'invite': {'id': from['id'], 'name': from['name'], 'at': inv?['at']},
      'screens': [
        for (final s in screens)
          {
            'id': s.id,
            'name': s.name,
            'status': s.status,
            'connected': _streams.containsKey(s.id),
            'online': _devices.containsKey(s.id),
          },
      ],
    };
  }

  // ── peers over HTTP ───────────────────────────────────────────────────

  Future<Map<String, Object?>?> _get(String url) async {
    final client = _clientFactory();
    try {
      final r = await client.get(Uri.parse(url)).timeout(_requestTimeout);
      if (r.statusCode != 200) return null;
      final decoded = jsonDecode(r.body);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  Future<(int, Map<String, Object?>)?> _post(
    String url,
    Map<String, Object?> body,
  ) async {
    final client = _clientFactory();
    try {
      final r = await client
          .post(
            Uri.parse(url),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
      final decoded = r.body.isEmpty ? null : jsonDecode(r.body);
      return (
        r.statusCode,
        decoded is Map ? decoded.cast<String, Object?>() : <String, Object?>{},
      );
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  static String _urlOf(Map<String, Object?> d) => Uri(
    scheme: d['tls'] == true ? 'https' : 'http',
    host: '${d['address'] ?? ''}',
    port: (d['port'] as num?)?.toInt() ?? 0,
  ).toString();

  static String _nonce() {
    final r = Random.secure();
    return [
      for (var i = 0; i < 32; i++)
        r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }

  // ── inviting (the active kiosk) ───────────────────────────────────────

  Future<List<Map<String, Object?>>> _candidates() async {
    await _readFleet(force: true);
    final taken = {for (final s in screens) s.id};
    final out = <Map<String, Object?>>[];
    await Future.wait([
      for (final d in _devices.values)
        if (!taken.contains(d['id']))
          () async {
            final identity = await _get('${_urlOf(d)}/api/companion/identity');
            out.add({
              'id': d['id'],
              'name': d['name'],
              'address': d['address'],
              // A kiosk on a build without companion screens answers 404.
              'supported': identity != null,
              'companion': identity?['companion'] == true,
              'of': ?identity?['of'],
              'ofSelf': identity?['ofId'] == _selfId && _selfId.isNotEmpty,
            });
          }(),
    ]);
    out.sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
    return out;
  }

  Future<CommandResult> _invite(String id) async {
    if (!_active) {
      return const CommandResult.fail('Voice Satellite is off on this kiosk');
    }
    await _readFleet(force: true);
    final d = _devices[id];
    if (d == null) return const CommandResult.fail('That kiosk is not online');
    if (screens.any((s) => s.id == id)) {
      return const CommandResult.fail('That kiosk is already on the list');
    }
    final nonce = _nonce();
    final port = _settings.get(defs.remotePort).toInt();
    final r = await _post('${_urlOf(d)}/api/companion/invite', {
      'nonce': nonce,
      'from': {
        'id': _selfId,
        'name': _selfName,
        'port': port,
        if (_settings.get(defs.remoteTls)) 'tls': true,
      },
    });
    if (r == null) {
      return const CommandResult.fail('That kiosk did not answer');
    }
    final (code, body) = r;
    if (code != 200 || body['ok'] == false) {
      return CommandResult.fail(
        '${body['error'] ?? 'That kiosk refused the invitation'}',
      );
    }
    final data = body['data'];
    final accepted = data is Map && data['status'] == 'accepted';
    final list = screens
      ..add(
        CompanionScreen(
          id: id,
          name: '${d['name'] ?? ''}',
          address: '${d['address'] ?? ''}',
          port: (d['port'] as num?)?.toInt() ?? 0,
          tls: d['tls'] == true,
          nonce: nonce,
          status: accepted ? 'accepted' : 'pending',
          addedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    await _saveScreens(list);
    log.info(name, 'invited ${d['name']} as a companion screen');
    _schedulePoll();
    _changed();
    return const CommandResult.ok();
  }

  Future<CommandResult> _remove(String id) async {
    final list = screens;
    final s = list.where((s) => s.id == id).firstOrNull;
    if (s == null) return const CommandResult.fail('No such companion screen');
    list.remove(s);
    await _saveScreens(list);
    _closeStream(id);
    // Told so it stops reconnecting; it forgets this kiosk either way once
    // its stream is refused.
    unawaited(_post('${s.url}/api/companion/leave', {'nonce': s.nonce}));
    log.info(name, 'removed companion screen ${s.name}');
    _changed();
    return const CommandResult.ok();
  }

  void _schedulePoll() {
    final pending = _active && screens.any((s) => s.status == 'pending');
    if (!pending) {
      _poll?.cancel();
      _poll = null;
      return;
    }
    _poll ??= Timer.periodic(_pollEvery, (_) => unawaited(_pollPending()));
  }

  Future<void> _pollPending() async {
    final list = screens;
    var changed = false;
    for (final s in list.where((s) => s.status == 'pending')) {
      final r = await _get('${s.url}/api/companion/invite/${s.nonce}');
      final status = r?['status'];
      if (status == 'accepted' || status == 'declined') {
        s.status = '$status';
        changed = true;
      }
    }
    if (changed) {
      await _saveScreens(list);
      _changed();
    }
    _schedulePoll();
  }

  Future<CommandResult> _companionLeft(String id, String nonce) async {
    final list = screens;
    final s = list.where((s) => s.id == id && s.nonce == nonce).firstOrNull;
    if (s == null) return const CommandResult.fail('unknown');
    s.status = 'left';
    await _saveScreens(list);
    _closeStream(id);
    log.info(name, '${s.name} stopped showing this kiosk');
    _changed();
    return const CommandResult.ok();
  }

  // ── streaming (the active kiosk) ──────────────────────────────────────

  CommandResult _verifyStream(String id, String nonce, String address) {
    if (!_active) return const CommandResult.fail('off');
    final list = screens;
    final s = list
        .where(
          (s) =>
              s.id == id &&
              s.nonce == nonce &&
              (s.status == 'pending' || s.status == 'accepted'),
        )
        .firstOrNull;
    if (s == null) return const CommandResult.fail('refused');
    // Accepted, whether or not the answer to the invitation was read yet.
    if (s.status != 'accepted' ||
        (address.isNotEmpty && s.address != address)) {
      s.status = 'accepted';
      if (address.isNotEmpty) s.address = address;
      unawaited(_saveScreens(list).then((_) => _schedulePoll()));
    }
    return const CommandResult.ok();
  }

  void _attach(String id, WebSocketChannel channel) {
    _closeStream(id);
    _streams[id] = channel;
    log.info(name, 'companion screen ${_nameOf(id)} connected');
    channel.stream.listen(
      (message) => _fromCompanion(message),
      onDone: () {
        if (identical(_streams[id], channel)) {
          _streams.remove(id);
          log.info(name, 'companion screen ${_nameOf(id)} disconnected');
          _syncTick();
          _changed();
        }
      },
      onError: (Object _) {},
      cancelOnError: true,
    );
    _send(channel, {'t': 'hello', 'name': _selfName});
    _send(channel, {'t': 'view', 'view': _voice.view.value.toJson()});
    _sentLevel = -1;
    _sentCountdown = -1;
    _syncTick();
    _changed();
  }

  String _nameOf(String id) =>
      screens.where((s) => s.id == id).firstOrNull?.name ?? id;

  void _closeStream(String id) {
    final s = _streams.remove(id);
    if (s == null) return;
    unawaited(s.sink.close());
    _syncTick();
  }

  void _fromCompanion(Object? message) {
    if (message is! String) return;
    Object? decoded;
    try {
      decoded = jsonDecode(message);
    } catch (_) {
      return;
    }
    if (decoded is! Map) return;
    switch (decoded['t']) {
      case 'dismiss':
        _voice.dismiss();
      case 'hold':
        _voice.holdResults(silence: decoded['silence'] == true);
    }
  }

  void _send(WebSocketChannel channel, Map<String, Object?> message) {
    try {
      channel.sink.add(jsonEncode(message));
    } catch (_) {}
  }

  void _broadcast(Map<String, Object?> message) {
    if (_streams.isEmpty) return;
    final text = jsonEncode(message);
    for (final s in _streams.values) {
      try {
        s.sink.add(text);
      } catch (_) {}
    }
  }

  void _onView() {
    if (_companion) return;
    if (_streams.isNotEmpty) {
      _broadcast({'t': 'view', 'view': _voice.view.value.toJson()});
    }
    _syncTick();
  }

  void _syncTick() {
    final want =
        _streams.isNotEmpty && !_companion && _voice.view.value.visible;
    if (!want) {
      _tick?.cancel();
      _tick = null;
      return;
    }
    _tick ??= Timer.periodic(tickEvery, (_) => _sendTick());
  }

  void _sendTick() {
    final level = (_voice.level.value * 1000).roundToDouble() / 1000;
    final countdown =
        (_voice.dockCountdown.value * 1000).roundToDouble() / 1000;
    final playback = _voice.playback;
    if (level == _sentLevel &&
        countdown == _sentCountdown &&
        playback == null) {
      return;
    }
    _sentLevel = level;
    _sentCountdown = countdown;
    _broadcast({
      't': 'tick',
      'level': level,
      'countdown': countdown,
      if (playback != null) 'playback': [playback.elapsed, playback.duration],
    });
  }

  // ── being invited (the companion screen) ──────────────────────────────

  Future<CommandResult> _received(Map<String, Object?> p) async {
    if (!_companion) {
      return const CommandResult.fail('Companion screen mode is off there');
    }
    final nonce = '${p['nonce'] ?? ''}';
    final from = p['from'];
    final address = '${p['address'] ?? ''}';
    if (nonce.length < 32 || from is! Map || address.isEmpty) {
      return const CommandResult.fail('invalid invitation');
    }
    final id = '${from['id'] ?? ''}';
    final port = (from['port'] as num?)?.toInt() ?? 0;
    final tls = from['tls'] == true;
    if (id.isEmpty || port <= 0) {
      return const CommandResult.fail('invalid invitation');
    }
    // The kiosk at the address it came from must be the one it says it is.
    final identity = await _get(
      '${_urlOf({'address': address, 'port': port, 'tls': tls})}'
      '/api/fleet/identity',
    );
    if (identity == null || identity['id'] != id) {
      return const CommandResult.fail('could not confirm who sent it');
    }
    final sender = {
      'id': id,
      'name': '${identity['name'] ?? from['name'] ?? ''}',
      'address': address,
      'port': port,
      if (tls) 'tls': true,
    };
    // Already showing that kiosk: it lost the old invitation, so the new
    // one takes over with no question asked.
    if (companionOf?['id'] == id) {
      await _settings.set(
        defs.voiceCompanionOf,
        jsonEncode({
          ...sender,
          'nonce': nonce,
          'at': DateTime.now().millisecondsSinceEpoch,
        }),
      );
      _disconnect();
      _sync();
      return const CommandResult.ok({'status': 'accepted'});
    }
    await _settings.set(
      defs.voiceCompanionInvite,
      jsonEncode({
        'nonce': nonce,
        'from': sender,
        'at': DateTime.now().millisecondsSinceEpoch,
        'status': 'pending',
      }),
    );
    log.info(name, 'invitation from ${sender['name']} to be its companion');
    _changed();
    return const CommandResult.ok({'status': 'pending'});
  }

  Future<Map<String, Object?>> _pollAnswer(String nonce) async {
    final inv = invite;
    if (inv == null || inv['nonce'] != nonce) return {'status': 'unknown'};
    final status = '${inv['status'] ?? 'pending'}';
    // Read once: the answer is the inviting kiosk's now.
    if (status != 'pending') {
      await _settings.set(defs.voiceCompanionInvite, '');
    }
    return {'status': status};
  }

  Future<CommandResult> _accept() async {
    final inv = pendingInvite;
    final from = inv?['from'];
    if (inv == null || from is! Map) {
      return const CommandResult.fail('No invitation is waiting');
    }
    final previous = companionOf;
    if (previous != null && previous['id'] != from['id']) {
      unawaited(_tellLeft(previous));
    }
    await _settings.set(
      defs.voiceCompanionOf,
      jsonEncode({
        ...from.cast<String, Object?>(),
        'nonce': inv['nonce'],
        'at': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    await _settings.set(
      defs.voiceCompanionInvite,
      jsonEncode({...inv, 'status': 'accepted'}),
    );
    log.info(name, 'now a companion screen of ${from['name']}');
    _disconnect();
    _sync();
    return const CommandResult.ok();
  }

  Future<CommandResult> _decline() async {
    final inv = pendingInvite;
    if (inv == null) {
      return const CommandResult.fail('No invitation is waiting');
    }
    await _settings.set(
      defs.voiceCompanionInvite,
      jsonEncode({...inv, 'status': 'declined'}),
    );
    _changed();
    return const CommandResult.ok();
  }

  Future<CommandResult> _stop() async {
    final of = companionOf;
    if (of == null) return const CommandResult.fail('Not a companion screen');
    unawaited(_tellLeft(of));
    await _forget();
    log.info(name, 'stopped showing ${of['name']}');
    return const CommandResult.ok();
  }

  Future<void> _tellLeft(Map<String, Object?> of) async {
    await _readFleet();
    await _post('${_urlOf(of)}/api/companion/left', {
      'id': _selfId,
      'nonce': of['nonce'],
    });
  }

  Future<CommandResult> _takenOff(String nonce) async {
    final of = companionOf;
    if (of == null || of['nonce'] != nonce || nonce.isEmpty) {
      return const CommandResult.fail('unknown');
    }
    log.info(name, '${of['name']} took this companion screen off');
    await _forget();
    return const CommandResult.ok();
  }

  Future<void> _forget() async {
    await _settings.set(defs.voiceCompanionOf, '');
    _disconnect();
    _sync();
  }

  // ── the link (the companion screen) ───────────────────────────────────

  static WebSocketChannel _connectPeer(Uri uri) {
    final client = kioskPeerHttpClient(requireTls: uri.scheme == 'wss');
    final channel = IOWebSocketChannel.connect(
      uri,
      customClient: client,
      connectTimeout: const Duration(seconds: 6),
      pingInterval: const Duration(seconds: 10),
    );
    channel.ready.then(
      (_) => client.close(),
      onError: (Object _) => client.close(force: true),
    );
    return channel;
  }

  void _connect() {
    _retry?.cancel();
    _retry = null;
    final of = companionOf;
    if (_disposed || !_companion || of == null) return;
    final generation = ++_linkGeneration;
    _linkState = 'connecting';
    _changed();
    unawaited(() async {
      await _readFleet(force: true);
      if (generation != _linkGeneration) return;
      // Where discovery heard it last, or where it invited from.
      final heard = _devices['${of['id']}'];
      final target = heard ?? of;
      final uri = Uri(
        scheme: target['tls'] == true ? 'wss' : 'ws',
        host: '${target['address'] ?? ''}',
        port: (target['port'] as num?)?.toInt() ?? 0,
        path: '/api/companion/stream',
        queryParameters: {'id': _selfId, 'nonce': '${of['nonce'] ?? ''}'},
      );
      final WebSocketChannel channel;
      try {
        channel = _socketFactory(uri);
        await channel.ready;
      } catch (e) {
        if (generation != _linkGeneration) return;
        _linkError = '$e'.contains('403') ? 'refused' : '';
        _lost(generation);
        return;
      }
      if (generation != _linkGeneration) {
        unawaited(channel.sink.close());
        return;
      }
      _link = channel;
      _attempt = 0;
      _linkError = '';
      _linkState = 'connected';
      log.info(name, 'showing ${of['name']}');
      _changed();
      _linkSub = channel.stream.listen(
        _fromActive,
        onDone: () => _lost(generation),
        onError: (Object _) => _lost(generation),
        cancelOnError: true,
      );
    }());
  }

  void _lost(int generation) {
    if (generation != _linkGeneration) return;
    _link = null;
    unawaited(_linkSub?.cancel());
    _linkSub = null;
    _voice.showCompanion(AssistView.hidden);
    if (_disposed || !_companion || companionOf == null) {
      _linkState = 'idle';
      _changed();
      return;
    }
    _linkState = _linkError == 'refused' ? 'refused' : 'offline';
    // Quick at first, then every half minute: the active kiosk restarts,
    // or drops off the network for a while.
    final seconds = min(30, 2 << min(_attempt, 4));
    _attempt++;
    _retry = Timer(Duration(seconds: seconds), _connect);
    _changed();
  }

  void _disconnect() {
    _linkGeneration++;
    _retry?.cancel();
    _retry = null;
    _attempt = 0;
    final link = _link;
    _link = null;
    unawaited(_linkSub?.cancel());
    _linkSub = null;
    if (link != null) unawaited(link.sink.close());
    _voice.showCompanion(AssistView.hidden);
    _linkState = 'idle';
    _linkError = '';
  }

  void _sendLink(Map<String, Object?> message) {
    final link = _link;
    if (link == null) return;
    try {
      link.sink.add(jsonEncode(message));
    } catch (_) {}
  }

  void _fromActive(Object? message) {
    if (message is! String) return;
    Object? decoded;
    try {
      decoded = jsonDecode(message);
    } catch (_) {
      return;
    }
    if (decoded is! Map) return;
    switch (decoded['t']) {
      case 'view':
        _voice.showCompanion(AssistView.fromJson(decoded['view']));
      case 'tick':
        final playback = decoded['playback'];
        _voice.companionTick(
          level: (decoded['level'] as num?)?.toDouble(),
          countdown: (decoded['countdown'] as num?)?.toDouble(),
          playback:
              playback is List &&
                  playback.length == 2 &&
                  playback[0] is num &&
                  playback[1] is num
              ? (
                  elapsed: (playback[0] as num).toDouble(),
                  duration: (playback[1] as num).toDouble(),
                )
              : null,
        );
      case 'hello':
        final name = decoded['name'];
        final of = companionOf;
        if (name is String &&
            name.isNotEmpty &&
            of != null &&
            of['name'] != name) {
          unawaited(
            _settings.set(
              defs.voiceCompanionOf,
              jsonEncode({...of, 'name': name}),
            ),
          );
        }
    }
  }
}
