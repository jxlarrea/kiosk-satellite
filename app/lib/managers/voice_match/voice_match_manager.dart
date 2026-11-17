import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// Kiosk Satellite Voice Match: finds the service, keeps this kiosk's
/// control connection to it and tells the rest of the app where it is.
///
/// The service is a Home Assistant app or a Docker container that tells
/// who is talking and when someone else starts. It advertises
/// `_ks-voice-match._tcp` over mDNS, unless the Address setting names it.
/// The kiosk signs in with its Home Assistant token.
///
/// The control connection (`/api/kiosk`) says hello with this kiosk's
/// device id, name and model, so enrollments and sessions know where they
/// came from, and carries everyone's names and colors back. The voice
/// turns open their own session sockets (voice_match_client.dart); this
/// manager only publishes the address they use, as
/// [VoiceMatchServiceChanged].
class VoiceMatchManager extends Manager {
  VoiceMatchManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'voice_match';

  static const _methods = MethodChannel('kiosk_satellite/voice_match');
  static const _found = EventChannel('kiosk_satellite/voice_match_stream');

  /// off, searching, connecting, connected, unreachable or refused.
  String status = 'off';
  String? baseUrl;
  String version = '';
  String model = '';
  List<Map<String, Object?>> people = const [];

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

  bool get _enabled =>
      _settings.get(defs.voiceEnabled) && _settings.get(defs.voiceMatchEnabled);

  @override
  Future<void> init() async {
    _subs.add(
      bus.on<SettingChanged>().listen((e) {
        if (e.key == defs.voiceMatchEnabled.key ||
            e.key == defs.voiceMatchAddress.key ||
            e.key == defs.voiceEnabled.key ||
            e.key == defs.haToken.key ||
            e.key == defs.deviceName.key) {
          unawaited(_apply());
        }
      }),
    );
    commands.register(
      Command(
        name: 'voiceMatchStatus',
        description:
            'Kiosk Satellite Voice Match: whether it is on and connected, '
            'its address and version, and who is enrolled',
        quiet: true,
        handler: (_) async => CommandResult.ok(describe()),
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
  };

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
    final typed = _settings.get(defs.voiceMatchAddress).trim();
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
        final url = host.contains(':') ? 'http://[$host]:$port' : 'http://$host:$port';
        _discovered[name] = url;
        log.info(this.name, 'found Voice Match at $url');
        if (_enabled && baseUrl == null && _settings.get(defs.voiceMatchAddress).trim().isEmpty) {
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
        log.info(name, 'Voice Match not reachable at $base: $err');
        _lost(gen, null);
      }
    }());
  }

  Future<Map<String, Object?>> _hello() async {
    final info = await commands.execute('getDeviceInfo', const {});
    final data = info.ok && info.data is Map ? (info.data as Map).cast<String, Object?>() : const <String, Object?>{};
    final deviceName = _settings.get(defs.deviceName).trim();
    return {
      'type': 'hello',
      'token': _settings.get(defs.haToken),
      'device_id': defs.effectiveHostname(_settings.get(defs.deviceHostname), deviceName),
      'name': deviceName.isNotEmpty ? deviceName : '${data['name'] ?? ''}',
      'model': '${data['model'] ?? ''}',
      'version': '${data['appVersion'] ?? ''}',
    };
  }

  /// The id this kiosk goes by in Voice Match, for the session sockets too.
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
        _attempt = 0;
        _setStatus('connected', baseUrl);
      case 'error':
        if (msg['code'] == 'unauthorized') _setStatus('refused', null);
      case 'enroll':
        // On-device enrollment arrives with the enrollment screens.
        log.info(name, 'enrollment asked for ${msg['name']}, not supported yet');
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
    if (_settings.get(defs.voiceMatchAddress).trim().isEmpty && _discovered.isEmpty) {
      baseUrl = null;
      _setStatus('searching', null);
    }
    // Back off: 2, 4, 8 ... up to 60 seconds.
    final wait = Duration(seconds: (2 << _attempt.clamp(0, 5)).clamp(2, 60));
    _attempt++;
    _retry?.cancel();
    _retry = Timer(wait, () {
      if (gen != _generation || !_enabled) return;
      if (baseUrl == null && _discovered.isNotEmpty) baseUrl = _discovered.values.first;
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
      bus.publish(VoiceMatchServiceChanged(usable));
    }
    // The status row on both settings surfaces.
    bus.publish(const RemoteStatusChanged('voice-match'));
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
