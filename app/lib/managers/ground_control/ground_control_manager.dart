import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'mine.dart';

/// Kiosk Satellite Ground Control: finds the service, keeps this kiosk's
/// control connection to it and tells the rest of the app where it is.
///
/// The service is a Home Assistant app or a Docker container that runs
/// what is too heavy for a kiosk on a capable machine. Its first feature is
/// Voice Match: who is talking, and when someone else starts. It advertises
/// `_ks-groundctl._tcp` over mDNS, unless the Address setting names it.
/// The kiosk signs in with its Home Assistant token.
///
/// The control connection (`/api/kiosk`) says hello with this kiosk's
/// device id, name and model, so enrollments and sessions know where they
/// came from, and carries everyone's names and colors back. The voice
/// turns open their own session sockets (voice_match_client.dart); this
/// manager only publishes the address they use, as
/// [GroundControlServiceChanged].
class GroundControlManager extends Manager {
  GroundControlManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'ground_control';

  static const _methods = MethodChannel('kiosk_satellite/ground_control');
  static const _found = EventChannel('kiosk_satellite/ground_control_stream');

  /// off, searching, connecting, connected, unreachable or refused.
  String status = 'off';
  String? baseUrl;
  String version = '';
  String model = '';
  List<Map<String, Object?>> people = const [];

  ({String? id, String name, String? by})? _speaking;

  /// Who Voice Match placed in this kiosk's last voice turn, with their
  /// things as Ground Control has them now. Null before the voice is
  /// placed, for a voice nobody enrolled and with Voice Match off.
  Speaking? get speaking {
    final s = _speaking;
    if (s == null || s.id == null) return null;
    return Speaking(
      id: s.id,
      name: s.name,
      by: s.by,
      things: thingsOf(s.id, people),
    );
  }

  /// The enrollment on this kiosk, as VoiceMatchEnrollment.toJson gives
  /// it, while it runs and its result shows.
  Map<String, Object?>? enrollment;

  /// The app's page in Home Assistant (`/hassio/ingress/<slug>`) when the
  /// service runs as a Home Assistant app.
  String? appPath;

  /// Where Open goes: the app's page in Home Assistant, or the Docker
  /// container's own web page. Null until connected.
  String? get appUrl {
    final base = baseUrl;
    if (status != 'connected' || base == null) return null;
    final path = appPath;
    final ha = _settings
        .get(defs.haUrl)
        .trim()
        .replaceFirst(RegExp(r'/+$'), '');
    if (path != null && ha.isNotEmpty) return '$ha$path';
    return '$base/';
  }

  final _subs = <StreamSubscription<Object?>>[];
  StreamSubscription<Object?>? _discovery;
  final _discovered = <String, String>{};
  bool _discovering = false;
  WebSocketChannel? _socket;
  StreamSubscription<Object?>? _socketSub;
  Timer? _retry;
  int _attempt = 0;
  int _generation = 0;
  String? _published;

  bool get _enabled => _settings.get(defs.groundControlEnabled);

  /// Whether the Ground Control app can record a voice here: Allow
  /// enrollment here, on a kiosk that runs Voice Match.
  bool get _enrollAllowed =>
      _settings.get(defs.voiceEnabled) &&
      _settings.get(defs.voiceMatchEnabled) &&
      _settings.get(defs.voiceMatchAllowEnroll);

  @override
  Future<void> init() async {
    _subs.add(
      bus.on<SettingChanged>().listen((e) {
        if (e.key == defs.voiceMatchAllowEnroll.key ||
            e.key == defs.voiceMatchEnabled.key ||
            e.key == defs.voiceEnabled.key) {
          _sendSettings();
          return;
        }
        if (e.key == defs.groundControlEnabled.key ||
            e.key == defs.groundControlAddress.key ||
            e.key == defs.haToken.key ||
            e.key == defs.deviceName.key) {
          unawaited(_apply());
        }
      }),
    );
    _subs.add(bus.on<VoiceMatchEnrollmentChanged>().listen(_onEnrollment));
    _subs.add(
      bus.on<VoiceSpeakerChanged>().listen((e) {
        _speaking = e.name.isEmpty ? null : (id: e.id, name: e.name, by: e.by);
        // A new turn clears the speaker: nothing was placed yet.
        if (e.name.isNotEmpty || e.score != null) _speakerEvent(e);
      }),
    );
    commands.register(
      Command(
        name: 'groundControlStatus',
        description:
            'Kiosk Satellite Ground Control: whether it is on and connected, '
            'its address and version, and who is enrolled',
        quiet: true,
        handler: (_) async => CommandResult.ok(describe()),
      ),
    );
    commands.register(
      Command(
        name: 'groundControlMine',
        description:
            'What "my" to-do list, calendar, playlist or person means for '
            'the person speaking in this kiosk\'s voice turn, as the Kiosk '
            'Satellite scripts ask for it',
        params: const {'thing': 'todo_list, calendar, playlist or person'},
        // The voice requests manager logs each one with its outcome.
        quiet: true,
        handler: (p) async => CommandResult.ok(
          resolveMine(
            '${p['thing'] ?? ''}'.trim(),
            p.containsKey('speaking') ? Speaking.from(p['speaking']) : speaking,
            people,
          ),
        ),
      ),
    );
    await _apply();
  }

  Map<String, Object?> describe() => {
    'enabled': _enabled,
    'status': status,
    'baseUrl': baseUrl,
    'version': version,
    'model': model,
    'people': people,
    'appUrl': appUrl,
    'allowEnroll': _enrollAllowed,
    'enrollment': enrollment,
  };

  /// Puts the voice Voice Match placed on Home Assistant's bus as
  /// `esphome.kiosk_satellite_speaker`, for automations: who it is, their
  /// Home Assistant person when Ground Control has one, the score and how
  /// it was placed. A voice nobody enrolled comes with an empty name.
  void _speakerEvent(VoiceSpeakerChanged e) {
    final person = thingsOf(e.id, people)['person'];
    bus.publish(
      HaEventRequested('kiosk_satellite_speaker', {
        'event_type': e.name.isEmpty ? 'unknown' : 'recognized',
        'name': e.name,
        'person': person ?? '',
        'score': e.score,
        'by': e.name.isEmpty ? '' : e.by ?? 'voice',
      }),
    );
  }

  /// Tell the service when an enrollment it asked for did not start or
  /// ended on the kiosk's side, so the app is not left waiting.
  void _onEnrollment(VoiceMatchEnrollmentChanged e) {
    final state = e.state;
    if (state?['phase'] != 'refused') {
      enrollment = state;
      bus.publish(const RemoteStatusChanged('ground-control'));
    }
    if (state == null) return;
    final phase = state['phase'];
    final code = state['code'];
    if (phase == 'refused' ||
        (phase == 'failed' &&
            const {'no_mic', 'stopped', 'lost'}.contains(code))) {
      _send({
        'type': 'enroll_error',
        'person_id': state['personId'],
        'code': code,
        'message': state['message'] ?? '',
      });
    }
  }

  /// Starts over from the settings: stop what runs, then connect again.
  Future<void> _apply() async {
    final gen = ++_generation;
    _retry?.cancel();
    _attempt = 0;
    await _closeSocket();
    if (!_enabled) {
      await _stopDiscovery();
      _setStatus('off', null);
      return;
    }
    final typed = _settings.get(defs.groundControlAddress).trim();
    if (typed.isNotEmpty) {
      await _stopDiscovery();
      baseUrl = _normalize(typed);
      _connect(gen);
      return;
    }
    baseUrl = null;
    _setStatus('searching', null);
    await _startDiscovery();
    if (_discovered.isNotEmpty) {
      baseUrl = _discovered.values.first;
      _connect(gen);
    }
  }

  /// `host`, `host:port` or a URL, as an http(s) base URL. Port 10900 when
  /// none is given.
  static String _normalize(String typed) {
    var t = typed.trim();
    if (!t.contains('://')) t = 'http://$t';
    final uri = Uri.parse(t);
    final port = uri.hasPort ? uri.port : 10900;
    return '${uri.scheme}://${uri.host}:$port';
  }

  Future<void> _startDiscovery() async {
    _discovery ??= _found.receiveBroadcastStream().listen((raw) {
      if (raw is! Map) return;
      final e = raw.cast<String, Object?>();
      final name = '${e['name'] ?? ''}';
      if (e['event'] == 'found') {
        final host = '${e['host'] ?? ''}';
        final port = e['port'];
        if (host.isEmpty || port is! int) return;
        final url = host.contains(':')
            ? 'http://[$host]:$port'
            : 'http://$host:$port';
        _discovered[name] = url;
        log.info(this.name, 'found Ground Control at $url');
        if (_enabled &&
            baseUrl == null &&
            _settings.get(defs.groundControlAddress).trim().isEmpty) {
          baseUrl = url;
          _connect(_generation);
        }
      } else if (e['event'] == 'lost') {
        _discovered.remove(name);
      }
    }, onError: (Object _) {});
    if (_discovering) return;
    _discovering = true;
    try {
      await _methods.invokeMethod<void>('start');
    } on PlatformException catch (err) {
      log.warn(name, 'discovery did not start: ${err.message}');
    } on MissingPluginException {
      // Tests and platforms without the bridge.
    }
  }

  Future<void> _stopDiscovery() async {
    if (!_discovering) return;
    _discovering = false;
    _discovered.clear();
    try {
      await _methods.invokeMethod<void>('stop');
    } on PlatformException {
      // Stopped anyway.
    } on MissingPluginException {
      // Tests.
    }
  }

  void _connect(int gen) {
    final base = baseUrl;
    if (base == null || gen != _generation) return;
    _setStatus('connecting', null);
    final uri = Uri.parse(base).replace(
      scheme: base.startsWith('https') ? 'wss' : 'ws',
      path: '/api/kiosk',
    );
    unawaited(() async {
      final hello = await _hello();
      if (gen != _generation) return;
      try {
        final socket = WebSocketChannel.connect(uri);
        await socket.ready.timeout(const Duration(seconds: 8));
        if (gen != _generation) {
          await socket.sink.close();
          return;
        }
        _socket = socket;
        socket.sink.add(jsonEncode(hello));
        _socketSub = socket.stream.listen(
          (data) => _onMessage(gen, data),
          onDone: () => _lost(gen, socket.closeCode),
          onError: (Object _) => _lost(gen, null),
          cancelOnError: true,
        );
      } on Object catch (err) {
        log.info(name, 'Ground Control not reachable at $base: $err');
        _lost(gen, null);
      }
    }());
  }

  Future<Map<String, Object?>> _hello() async {
    final info = await commands.execute('getDeviceInfo', const {});
    final data = info.ok && info.data is Map
        ? (info.data as Map).cast<String, Object?>()
        : const <String, Object?>{};
    final deviceName = _settings.get(defs.deviceName).trim();
    return {
      'type': 'hello',
      'token': _settings.get(defs.haToken),
      'device_id': defs.effectiveHostname(
        _settings.get(defs.deviceHostname),
        deviceName,
      ),
      'name': deviceName.isNotEmpty ? deviceName : '${data['name'] ?? ''}',
      'model': '${data['model'] ?? ''}',
      'version': '${data['appVersion'] ?? ''}',
      'enroll': _enrollAllowed,
    };
  }

  /// Allow enrollment here changed: the service lists the kiosk to match.
  void _sendSettings() {
    _send({'type': 'settings', 'enroll': _enrollAllowed});
  }

  void _send(Map<String, Object?> message) {
    try {
      _socket?.sink.add(jsonEncode(message));
    } on Object {
      // Gone: the next connection says hello with the current settings.
    }
  }

  /// The id this kiosk goes by in Ground Control, for the session sockets too.
  String get deviceId => defs.effectiveHostname(
    _settings.get(defs.deviceHostname),
    _settings.get(defs.deviceName).trim(),
  );

  void _onMessage(int gen, Object? data) {
    if (gen != _generation || data is! String) return;
    final Map<String, Object?> msg;
    try {
      msg = (jsonDecode(data) as Map).cast<String, Object?>();
    } on Object {
      return;
    }
    switch (msg['type']) {
      case 'people':
        people = [
          for (final p in (msg['people'] as List? ?? const []))
            if (p is Map) p.cast<String, Object?>(),
        ];
        version = '${msg['version'] ?? version}';
        model = '${msg['model'] ?? model}';
        final path = msg['app_path'];
        appPath = path is String && path.startsWith('/') ? path : null;
        _attempt = 0;
        _setStatus('connected', baseUrl);
      case 'error':
        if (msg['code'] == 'unauthorized') _setStatus('refused', null);
      case 'enroll':
        final personId = '${msg['person_id'] ?? ''}';
        if (personId.isEmpty) return;
        if (!_enrollAllowed) {
          log.info(
            name,
            'enrollment for ${msg['name']} refused: Allow enrollment here is off',
          );
          _send({
            'type': 'enroll_error',
            'person_id': personId,
            'code': 'off',
            'message': '',
          });
          return;
        }
        final target = msg['target_s'];
        bus.publish(
          VoiceMatchEnrollRequested(
            personId: personId,
            name: '${msg['name'] ?? ''}',
            color: msg['color'] is String ? msg['color'] as String : null,
            targetS: target is num ? target.toDouble().clamp(10.0, 300.0) : 45,
          ),
        );
      default:
        break;
    }
  }

  void _lost(int gen, int? code) {
    if (gen != _generation) return;
    _socketSub?.cancel();
    _socketSub = null;
    _socket = null;
    if (code == 4401) {
      _setStatus('refused', null);
      return;
    }
    _setStatus('unreachable', null);
    if (_settings.get(defs.groundControlAddress).trim().isEmpty &&
        _discovered.isEmpty) {
      baseUrl = null;
      _setStatus('searching', null);
    }
    // Back off: 2, 4, 8 ... up to 60 seconds.
    final wait = Duration(seconds: (2 << _attempt.clamp(0, 5)).clamp(2, 60));
    _attempt++;
    _retry?.cancel();
    _retry = Timer(wait, () {
      if (gen != _generation || !_enabled) return;
      if (baseUrl == null && _discovered.isNotEmpty)
        baseUrl = _discovered.values.first;
      _connect(gen);
    });
  }

  Future<void> _closeSocket() async {
    await _socketSub?.cancel();
    _socketSub = null;
    final s = _socket;
    _socket = null;
    if (s != null) {
      try {
        await s.sink.close();
      } on Object {
        // Already gone.
      }
    }
  }

  void _setStatus(String next, String? url) {
    status = next;
    final usable = next == 'connected' ? url : null;
    if (usable != _published) {
      _published = usable;
      bus.publish(GroundControlServiceChanged(usable));
    }
    // The status row on both settings surfaces.
    bus.publish(const RemoteStatusChanged('ground-control'));
  }

  @override
  Future<void> dispose() async {
    _generation++;
    _retry?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    await _discovery?.cancel();
    await _closeSocket();
    await _stopDiscovery();
  }
}
