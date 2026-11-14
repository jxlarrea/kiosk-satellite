import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/kiosk_http_client.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'voice_timer_manager.dart';

/// A kiosk picked under Share with.
class SharedTimerTarget {
  const SharedTimerTarget(this.id, this.name);
  final String id;
  final String name;

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  /// The saved pick list: a JSON list of `{id, name}`.
  static List<SharedTimerTarget> parse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final seen = <String>{};
      return [
        for (final entry in decoded)
          if (entry is Map &&
              entry['id'] is String &&
              (entry['id'] as String).isNotEmpty &&
              seen.add(entry['id'] as String))
            SharedTimerTarget(entry['id'] as String, '${entry['name'] ?? ''}'),
      ];
    } catch (_) {
      return const [];
    }
  }

  static String encode(Iterable<SharedTimerTarget> targets) =>
      jsonEncode([for (final t in targets) t.toJson()]);
}

/// What this kiosk knows about a kiosk it shares with.
class _Peer {
  /// That kiosk's clock minus this one's, in milliseconds, from the round
  /// trip with the shortest delay.
  int? offset;
  int rtt = 1 << 30;
  int offsetAt = 0;

  /// The last push left timers there, so it is owed an empty one.
  bool holds = false;
  String status = 'unknown';
  Timer? retry;
}

/// A kiosk sharing its timers here, and where to answer it.
class _Origin {
  String name = '';
  String address = '';
  int port = 0;
  bool tls = false;
  int seen = 0;
}

/// Shared timers: a kiosk's timers also run on the kiosks it picks.
///
/// Home Assistant keeps every timer on the kiosk it was started on, and it
/// stays the only owner. That kiosk sends the others a full picture of its
/// timers each time one changes: `POST /api/timers/shared` on their remote
/// admin port, before the password, the way the intercom knocks. The
/// receiving kiosk shows them beside its own and rings them. A pause, a
/// cancel or a dismissal there goes back to the owner
/// (`POST /api/timers/shared/action`), which runs it through Home
/// Assistant and sends the new picture to everyone.
///
/// The countdowns and the ring stay in step without the kiosks' clocks
/// agreeing. Every answer carries the receiver's clock, so the owner learns
/// how far each kiosk's clock is from its own (the round trip with the
/// shortest delay wins) and sends that along. End times and the first
/// chime then land on the same instant everywhere, and the owner holds its
/// own first chime back by [ringLead] to give the others time to hear of
/// it.
class SharedTimersManager extends Manager {
  SharedTimersManager(
    super.bus,
    super.commands,
    super.log,
    this._settings,
    this._timers, {
    http.Client Function()? clientFactory,
    DateTime Function()? clock,
  }) : _clientFactory = clientFactory ?? kioskPeerClient,
       _clock = clock ?? DateTime.now;

  final SettingsManager _settings;
  final VoiceTimerManager _timers;
  final http.Client Function() _clientFactory;
  final DateTime Function() _clock;

  @override
  String get name => 'shared_timers';

  /// How long the owner waits before its first chime.
  static const ringLead = Duration(milliseconds: 400);

  /// A picture is sent again this often while timers run, so a kiosk that
  /// missed one catches up and knows the owner is still there.
  static const heartbeat = Duration(seconds: 30);

  /// A sharing kiosk not heard from for this long is taken off.
  static const staleAfter = Duration(seconds: 100);

  static const _requestTimeout = Duration(seconds: 4);
  static const _maxTimers = 24;

  final _subs = <StreamSubscription<Object?>>[];
  final _peers = <String, _Peer>{};
  final _origins = <String, _Origin>{};
  http.Client? _client;
  List<Map<String, Object?>> _latest = const [];
  Map<String, Map<String, Object?>> _devices = const {};
  Map<String, Object?> _self = const {};
  bool _fleetEnabled = false;
  int _devicesAt = 0;
  Timer? _pushTimer;
  Timer? _beat;
  Timer? _sweep;
  int _generation = 0;
  bool _disposed = false;

  int get _now => _clock().millisecondsSinceEpoch;

  bool get sharing => _settings.get(defs.voiceTimersShare);

  List<SharedTimerTarget> get targets =>
      SharedTimerTarget.parse(_settings.get(defs.voiceTimersShareWith));

  @override
  Future<void> init() async {
    commands
      ..register(
        Command(
          name: 'sharedTimers',
          description:
              'Shared timers on this kiosk: whether it shares, the kiosks '
              'it shares with and how the last send to each went, the '
              'kiosks sharing here and the kiosks on the network to pick '
              'from.',
          quiet: true,
          handler: (_) async {
            await _readFleet(force: true);
            return CommandResult.ok(describe());
          },
        ),
      )
      ..register(
        Command(
          name: 'sharedTimersReceive',
          description:
              'Internal: the timers another kiosk shares with this one, '
              'from its POST to /api/timers/shared.',
          quiet: true,
          handler: (p) async => _receive(p),
        ),
      )
      ..register(
        Command(
          name: 'sharedTimersAction',
          description:
              'Internal: a pause, resume, cancel or dismissal of one of '
              'this kiosk\'s timers from a kiosk it shares them with.',
          quiet: true,
          handler: (p) async => _action(p),
        ),
      );
    _subs
      ..add(
        bus.on<VoiceTimersChanged>().listen((e) {
          _latest = e.timers;
          _schedulePush();
        }),
      )
      ..add(
        bus.on<SettingChanged>().listen((e) {
          if (e.key == defs.voiceTimersShare.key ||
              e.key == defs.voiceTimersShareWith.key) {
            _syncLead();
            _schedulePush();
          } else if (e.key == defs.voiceTimersReceive.key && e.value != true) {
            for (final id in _origins.keys.toList()) {
              _drop(id);
            }
          } else if (e.key == defs.voiceMuteTimers.key ||
              e.key == defs.voiceTimerAlertPill.key ||
              e.key == defs.voiceTimerSpeak.key) {
            _replay();
          }
        }),
      )
      ..add(
        bus.on<VoiceTimerAction>().listen((e) {
          if (e.entityId.startsWith('shared:')) unawaited(_sendAction(e));
        }),
      );
    _timers.localAlertChanged.addListener(_schedulePush);
    _sweep = Timer.periodic(const Duration(seconds: 20), (_) => _sweepStale());
    _syncLead();
    // A restart loses the last picture; timers that outlived it come back
    // with the next event from Home Assistant.
    final current = await commands.execute('voiceTimers', const {});
    final data = current.data;
    if (current.ok && data is Map && data['timers'] is List) {
      _latest = [
        for (final t in data['timers'] as List)
          if (t is Map) t.cast<String, Object?>(),
      ];
      if (_latest.isNotEmpty) _schedulePush();
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _timers.localAlertChanged.removeListener(_schedulePush);
    _pushTimer?.cancel();
    _beat?.cancel();
    _sweep?.cancel();
    for (final peer in _peers.values) {
      peer.retry?.cancel();
    }
    for (final sub in _subs) {
      await sub.cancel();
    }
    _client?.close();
  }

  Map<String, Object?> describe() {
    final picked = targets;
    return {
      'available': _fleetEnabled,
      'sharing': sharing,
      'receiving': _settings.get(defs.voiceTimersReceive),
      'targets': [
        for (final t in picked)
          {
            'id': t.id,
            'name': _devices[t.id]?['name'] ?? t.name,
            'status': !_devices.containsKey(t.id)
                ? 'offline'
                : (_peers[t.id]?.status ?? 'unknown'),
          },
      ],
      'kiosks': [
        for (final d in _devices.values)
          {'id': d['id'], 'name': d['name'], 'address': d['address']},
      ],
      'from': [
        for (final e in _origins.entries) {'id': e.key, 'name': e.value.name},
      ],
    };
  }

  /// The owner holds its first chime back only while someone is listening.
  void _syncLead() {
    _timers.ringLead = sharing && targets.isNotEmpty ? ringLead : Duration.zero;
  }

  // ── The kiosks on the network ──────────────────────────────────────

  Future<void> _readFleet({bool force = false}) async {
    if (!force && _now - _devicesAt < 15000 && _devices.isNotEmpty) return;
    final r = await commands.execute('fleet', const {});
    final data = r.data;
    if (!r.ok || data is! Map) return;
    _devicesAt = _now;
    _fleetEnabled = data['enabled'] == true;
    final devices = <String, Map<String, Object?>>{};
    final list = data['devices'];
    if (list is List) {
      for (final d in list) {
        if (d is! Map) continue;
        final id = '${d['id'] ?? ''}';
        if (id.isEmpty) continue;
        if (d['self'] == true) {
          _self = d.cast<String, Object?>();
        } else {
          devices[id] = d.cast<String, Object?>();
        }
      }
    }
    _devices = devices;
  }

  static String? _urlOf(Map<String, Object?>? device) {
    if (device == null) return null;
    final address = '${device['address'] ?? ''}';
    final port = (device['port'] as num?)?.toInt() ?? 0;
    if (address.isEmpty || port <= 0) return null;
    return Uri(
      scheme: device['tls'] == true ? 'https' : 'http',
      host: address,
      port: port,
    ).toString();
  }

  // ── Sending ────────────────────────────────────────────────────────

  /// One send covers a burst: a timer finishing changes the list, the
  /// alert and then its phrase within a few milliseconds.
  void _schedulePush() {
    if (_disposed) return;
    _pushTimer ??= Timer(const Duration(milliseconds: 15), () {
      _pushTimer = null;
      unawaited(_push());
    });
  }

  /// This kiosk's timers as the others get them, times on this kiosk's
  /// clock.
  Map<String, Object?> _picture() {
    final running = <Map<String, Object?>>[];
    final ringing = <Map<String, Object?>>[];
    for (final t in _latest.take(_maxTimers)) {
      final id = '${t['timer_id'] ?? ''}';
      if (id.isEmpty) continue;
      if (t['finished'] == true) {
        ringing.add({'id': id, 'name': '${t['name'] ?? ''}'});
        continue;
      }
      final active = t['is_active'] == true;
      final ends = active ? DateTime.tryParse('${t['ends_at'] ?? ''}') : null;
      final left = (t['seconds_left'] as num?)?.toInt() ?? 0;
      running.add({
        'id': id,
        'name': '${t['name'] ?? ''}',
        'duration':
            (t['duration_seconds'] as num?)?.toInt() ??
            (t['total_seconds'] as num?)?.toInt() ??
            0,
        'active': active && ends != null,
        if (active && ends != null)
          'ends': ends.millisecondsSinceEpoch
        else
          'left': left,
      });
    }
    return {
      'v': 1,
      'from': {
        'id': '${_self['id'] ?? ''}',
        'name': '${_self['name'] ?? ''}',
        'port': (_self['port'] as num?)?.toInt() ?? 0,
        if (_self['tls'] == true) 'tls': true,
      },
      'timers': running,
      'ringing': ringing,
      if (ringing.isNotEmpty)
        'ring_at': _timers.localRingAt ?? _now + ringLead.inMilliseconds,
      if (ringing.isNotEmpty && _timers.localSpeech != null) ...{
        'speech': _timers.localSpeech,
        'speech_text': _timers.localSpeechText,
      },
    };
  }

  Future<void> _push() async {
    if (_disposed) return;
    final generation = ++_generation;
    final picked = sharing ? targets : const <SharedTimerTarget>[];
    final ids = {for (final t in picked) t.id};
    // A kiosk taken off the list, or all of them once sharing is off, gets
    // one empty picture so its copies go.
    final owed = [
      for (final e in _peers.entries)
        if (e.value.holds && !ids.contains(e.key)) e.key,
    ];
    if (picked.isEmpty && owed.isEmpty) {
      _beat?.cancel();
      _beat = null;
      return;
    }
    await _readFleet();
    if ('${_self['id'] ?? ''}'.isEmpty) {
      log.debug(name, 'not sharing: this kiosk is not on the network list');
      return;
    }
    final picture = _picture();
    final empty =
        (picture['timers'] as List).isEmpty &&
        (picture['ringing'] as List).isEmpty;
    final cleared = {
      ...picture,
      'timers': const <Object>[],
      'ringing': const <Object>[],
    }..remove('ring_at');
    await Future.wait([
      for (final t in picked)
        if (!empty || (_peers[t.id]?.holds ?? false))
          _send(t.id, picture, generation),
      for (final id in owed) _send(id, cleared, generation),
    ]);
    if (_disposed || generation != _generation) return;
    final anyHeld = _peers.values.any((p) => p.holds);
    if (!empty || anyHeld) {
      _beat ??= Timer.periodic(heartbeat, (_) => _schedulePush());
    } else {
      _beat?.cancel();
      _beat = null;
    }
  }

  Future<void> _send(
    String id,
    Map<String, Object?> picture,
    int generation, {
    int attempt = 0,
    bool refined = false,
  }) async {
    final peer = _peers.putIfAbsent(id, _Peer.new);
    peer.retry?.cancel();
    peer.retry = null;
    final url = _urlOf(_devices[id]);
    if (url == null) {
      peer.status = 'offline';
      return;
    }
    // A clock reading older than ten minutes is measured again.
    if (peer.offset != null && _now - peer.offsetAt > 600000) {
      peer.rtt = 1 << 30;
    }
    final sentOffset = peer.offset;
    final empty =
        (picture['timers'] as List).isEmpty &&
        (picture['ringing'] as List).isEmpty;
    final t0 = _now;
    http.Response? res;
    try {
      res = await (_client ??= _clientFactory())
          .post(
            Uri.parse('$url/api/timers/shared'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({...picture, 'now': t0, 'offset': ?sentOffset}),
          )
          .timeout(_requestTimeout);
    } catch (e) {
      log.debug(name, 'send to $id: $e');
    }
    final t2 = _now;
    if (_disposed) return;
    if (res != null && res.statusCode == 200) {
      peer
        ..status = 'ok'
        ..holds = !empty;
      final theirs = _json(res.body)?['now'];
      if (theirs is num) {
        final rtt = t2 - t0;
        if (rtt <= peer.rtt || peer.offset == null) {
          peer
            ..rtt = rtt
            ..offset = theirs.toInt() - (t0 + t2) ~/ 2
            ..offsetAt = t2;
        }
      }
      // The first picture went out before the clocks were compared, or
      // with a rougher reading: send it again with the better one.
      final better = peer.offset;
      if (!refined &&
          !empty &&
          generation == _generation &&
          better != null &&
          (sentOffset == null || (better - sentOffset).abs() > 25)) {
        await _send(id, picture, generation, refined: true);
      }
      return;
    }
    if (res != null && res.statusCode == 403) {
      // It does not take shared timers: nothing to retry.
      peer
        ..status = 'off'
        ..holds = false;
      return;
    }
    peer.status = 'unreachable';
    if (attempt < 2 && generation == _generation) {
      peer.retry = Timer(Duration(seconds: attempt == 0 ? 1 : 3), () {
        if (generation == _generation) {
          unawaited(_send(id, picture, generation, attempt: attempt + 1));
        }
      });
    }
  }

  // ── Receiving ──────────────────────────────────────────────────────

  /// The last picture of each sharing kiosk as it arrived, to draw again
  /// when a setting of this kiosk's own changes how it rings.
  final _last = <String, Map<String, Object?>>{};

  CommandResult _receive(Map<String, Object?> p) {
    if (!_settings.get(defs.voiceTimersReceive)) {
      return const CommandResult.ok({'code': 403, 'error': 'off'});
    }
    final from = p['from'];
    final id = from is Map ? '${from['id'] ?? ''}' : '';
    if (id.isEmpty || id.length > 80 || id == '${_self['id'] ?? ''}') {
      return const CommandResult.fail('who is sharing is required');
    }
    final timers = p['timers'];
    final ringing = p['ringing'];
    if (timers is! List ||
        ringing is! List ||
        timers.length > _maxTimers ||
        ringing.length > _maxTimers) {
      return const CommandResult.fail('invalid timers');
    }
    final received = (p['received'] as num?)?.toInt() ?? _now;
    final sent = (p['now'] as num?)?.toInt();
    final offset = (p['offset'] as num?)?.toInt();
    if (sent == null) return const CommandResult.fail('invalid timers');
    final origin = _origins.putIfAbsent(id, _Origin.new)
      ..name = _clip('${(from as Map)['name'] ?? ''}')
      ..address = '${p['address'] ?? ''}'
      ..port = (from['port'] as num?)?.toInt() ?? 0
      ..tls = from['tls'] == true
      ..seen = received;
    _last[id] = {
      ...p,
      // The sender's clock to this one's: as measured, or as if the
      // picture took no time to arrive.
      'shift': offset ?? received - sent,
    };
    if (!_apply(id, origin)) {
      _origins.remove(id);
      _last.remove(id);
      return const CommandResult.fail('invalid timers');
    }
    if (timers.isEmpty && ringing.isEmpty) {
      _origins.remove(id);
      _last.remove(id);
    }
    return CommandResult.ok({'code': 200, 'now': received});
  }

  bool _apply(String id, _Origin origin) {
    final p = _last[id];
    if (p == null) return false;
    final shift = (p['shift'] as num).toInt();
    final now = _now;
    final running = <VoiceTimer>[];
    final seen = <String>{};
    for (final raw in p['timers'] as List) {
      if (raw is! Map) return false;
      final timerId = '${raw['id'] ?? ''}';
      if (timerId.isEmpty || timerId.length > 120 || !seen.add(timerId)) {
        return false;
      }
      final duration = (raw['duration'] as num?)?.toInt() ?? 0;
      final ends = (raw['ends'] as num?)?.toInt();
      final left = (raw['left'] as num?)?.toInt() ?? 0;
      if (raw['active'] == true && ends != null) {
        final local = ends + shift;
        // Whole seconds left, counted from an instant that puts each tick
        // of the countdown where the owner's falls.
        final seconds = ((local - now) / 1000).ceil().clamp(0, 8640000);
        running.add(
          VoiceTimer(
            id: timerId,
            name: _clip('${raw['name'] ?? ''}'),
            totalSeconds: seconds,
            startedAt: local - seconds * 1000,
            active: true,
            duration: duration.clamp(0, 8640000),
          ),
        );
      } else {
        running.add(
          VoiceTimer(
            id: timerId,
            name: _clip('${raw['name'] ?? ''}'),
            totalSeconds: left.clamp(0, 8640000),
            startedAt: now,
            active: false,
            duration: duration.clamp(0, 8640000),
          ),
        );
      }
    }
    final alerts = <VoiceTimer>[];
    for (final raw in p['ringing'] as List) {
      if (raw is! Map) return false;
      final timerId = '${raw['id'] ?? ''}';
      if (timerId.isEmpty || timerId.length > 120 || !seen.add(timerId)) {
        return false;
      }
      alerts.add(
        VoiceTimer(
          id: timerId,
          name: _clip('${raw['name'] ?? ''}'),
          totalSeconds: 0,
          startedAt: 0,
          active: false,
          finished: true,
        ),
      );
    }
    final ringAt = (p['ring_at'] as num?)?.toInt();
    final speech = p['speech'];
    _timers.setShared(
      id,
      name: origin.name,
      timers: running,
      alerts: alerts,
      ringAt: ringAt == null ? null : ringAt + shift,
      muted: _settings.get(defs.voiceMuteTimers),
      hidden: !_settings.get(defs.voiceTimerAlertPill),
      speech:
          _settings.get(defs.voiceTimerSpeak) &&
              speech is String &&
              (speech.startsWith('http://') || speech.startsWith('https://'))
          ? speech
          : null,
      speechText: _clip('${p['speech_text'] ?? ''}', 400),
    );
    return true;
  }

  /// Draws every shared picture again after a setting that changes how
  /// this kiosk rings.
  void _replay() {
    for (final e in _origins.entries.toList()) {
      _apply(e.key, e.value);
    }
  }

  void _drop(String id) {
    final origin = _origins.remove(id);
    _last.remove(id);
    if (origin == null) return;
    _timers.setShared(
      id,
      name: origin.name,
      timers: const [],
      alerts: const [],
    );
  }

  void _sweepStale() {
    final now = _now;
    for (final e in _origins.entries.toList()) {
      if (now - e.value.seen > staleAfter.inMilliseconds) {
        log.info(name, 'shared timers from ${e.value.name} went stale');
        _drop(e.key);
      }
    }
  }

  // ── Actions ────────────────────────────────────────────────────────

  /// A tap on a shared timer here: the kiosk that owns it runs it.
  Future<void> _sendAction(VoiceTimerAction action) async {
    final id = action.entityId.substring('shared:'.length);
    await _readFleet();
    final origin = _origins[id];
    final url =
        _urlOf(_devices[id]) ??
        (origin == null
            ? null
            : _urlOf({
                'address': origin.address,
                'port': origin.port,
                'tls': origin.tls,
              }));
    http.Response? res;
    if (url != null) {
      try {
        res = await (_client ??= _clientFactory())
            .post(
              Uri.parse('$url/api/timers/shared/action'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({
                'from': '${_self['id'] ?? ''}',
                'id': action.id,
                'action': action.action,
              }),
            )
            .timeout(_requestTimeout);
      } catch (e) {
        log.debug(name, 'action to $id: $e');
      }
    }
    if (res?.statusCode != 200 && !_disposed) {
      log.warn(name, 'timer ${action.action} did not reach its kiosk');
      _timers.error.value++;
    }
  }

  /// A kiosk this one shares with asks to change one of its timers.
  CommandResult _action(Map<String, Object?> p) {
    final from = '${p['from'] ?? ''}';
    if (!sharing || !targets.any((t) => t.id == from)) {
      return const CommandResult.ok({'code': 403, 'error': 'off'});
    }
    final action = '${p['action'] ?? ''}';
    if (action == 'dismiss') {
      _timers.dismissLocal();
      return const CommandResult.ok({'code': 200});
    }
    if (!const {'pause', 'resume', 'cancel'}.contains(action)) {
      return const CommandResult.fail('unknown action');
    }
    final id = '${p['id'] ?? ''}';
    if (!_timers.timers.value.any((t) => t.id == id && !t.shared)) {
      return const CommandResult.ok({'code': 404, 'error': 'no such timer'});
    }
    _timers.control(id, action);
    return const CommandResult.ok({'code': 200});
  }

  static String _clip(String text, [int max = 80]) =>
      text.length > max ? text.substring(0, max) : text;

  static Map<String, Object?>? _json(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } catch (_) {
      return null;
    }
  }
}
