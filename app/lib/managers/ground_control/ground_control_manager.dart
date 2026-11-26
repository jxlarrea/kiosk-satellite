import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../gestures/gesture_mappings.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'client_key.dart';
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
/// The control connection (`/api/kiosk`) opens with a challenge from the
/// service, which this kiosk signs with Kiosk Satellite's client key
/// (client_key.dart) in its hello. The hello carries this kiosk's device
/// id, name, model and Voice Match features, so enrollments and sessions
/// know where they came from and the Kiosks page shows what is on. A new
/// kiosk waits until it is approved in the Ground Control app, which then
/// sends a ticket and everyone's names and colors. The voice turns open
/// their own session sockets (voice_match_client.dart) with that ticket;
/// this manager only publishes the address and ticket they use, as
/// [GroundControlServiceChanged].
class GroundControlManager extends Manager {
  GroundControlManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    Future<ClientKey?> Function()? clientKey,
  }) : _loadKey = clientKey ?? _bridgeKey;

  final SettingsManager _settings;
  final Future<ClientKey?> Function() _loadKey;
  Future<ClientKey?>? _key;

  /// The key this build was made with, from GroundControlBridge.
  static Future<ClientKey?> _bridgeKey() async {
    try {
      final raw = await _methods.invokeMethod<Map<Object?, Object?>>(
        'clientKey',
      );
      final id = raw?['id'];
      final seed = raw?['seed'];
      if (id is String && seed is List<int>) return ClientKey(id, seed);
    } on PlatformException {
      // No key.
    } on MissingPluginException {
      // Tests and platforms without the bridge.
    }
    return null;
  }

  @override
  String get name => 'ground_control';

  static const _methods = MethodChannel('kiosk_satellite/ground_control');
  static const _found = EventChannel('kiosk_satellite/ground_control_stream');

  /// off, searching, connecting, connected, unreachable, refused,
  /// pending (waiting for approval), declined or unsigned (a build
  /// without the client key).
  String status = 'off';
  String? baseUrl;
  String version = '';
  String model = '';
  List<Map<String, Object?>> people = const [];

  /// Ground Control person id to their Home Assistant picture's address,
  /// or null for a person without one, looked up once.
  final _pictures = <String, Future<String?>>{};

  /// The picture of the Home Assistant person a Ground Control person is
  /// linked to (their Person under What's theirs), as an address to load
  /// with the Home Assistant token. Null when they have none.
  Future<String?> pictureOf(String personId) =>
      _pictures[personId] ??= _lookUpPicture(personId);

  Future<String?> _lookUpPicture(String personId) async {
    final person = people.where((p) => p['id'] == personId).firstOrNull;
    final things = person?['things'];
    final entity = things is Map ? things['person'] : null;
    final base = _settings
        .get(defs.haUrl)
        .trim()
        .replaceFirst(RegExp(r'/+$'), '');
    final token = _settings.get(defs.haToken);
    if (entity is! String || entity.isEmpty || base.isEmpty || token.isEmpty) {
      return null;
    }
    try {
      final r = await http
          .get(
            Uri.parse('$base/api/states/$entity'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final attrs = (jsonDecode(r.body) as Map)['attributes'];
      final picture = attrs is Map ? attrs['entity_picture'] : null;
      if (picture is! String || picture.isEmpty) return null;
      if (picture.startsWith('http://') || picture.startsWith('https://')) {
        return picture;
      }
      return '$base${picture.startsWith('/') ? '' : '/'}$picture';
    } on Object catch (e) {
      log.debug(name, 'no picture for $entity: $e');
      // Try again next time: Home Assistant may have been away.
      _pictures.remove(personId);
      return null;
    }
  }

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

  /// How the service is installed, for the Ground Control page and Kiosk
  /// Satellite Analytics: `install` (ha_app, docker or python), `arch`,
  /// `cuda` (the CUDA image's version, empty for the CPU image) and `onGpu`.
  /// Empty from a Ground Control that doesn't say.
  Map<String, Object?> install = const {};

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
  String? _publishedTicket;

  /// The ticket the service gave this kiosk once it was approved, for the
  /// session and enrollment sockets.
  String? ticket;

  /// The hello to sign when the service's challenge comes.
  Map<String, Object?>? _pendingHello;

  bool get _enabled => _settings.get(defs.groundControlEnabled);

  /// Whether the Ground Control app can record a voice here: Allow
  /// enrollment here, on a kiosk that runs Voice Match.
  bool get _enrollAllowed =>
      _settings.get(defs.voiceEnabled) &&
      _settings.get(defs.voiceMatchEnabled) &&
      _settings.get(defs.voiceMatchAllowEnroll);

  /// The settings that make what [features] says.
  static final _featureKeys = {
    defs.voiceEnabled.key,
    defs.voiceMatchEnabled.key,
    defs.voiceMatchPolicy.key,
    defs.voiceMatchPeople.key,
    defs.voiceMatchEndOnOtherVoice.key,
    defs.voiceMatchIsolation.key,
    defs.voiceMatchWakeWordAligner.key,
    defs.voiceMatchSpeakerSensor.key,
    defs.voiceMatchShowSpeaker.key,
    defs.voiceMatchAllowEnroll.key,
    defs.visionMatchEnabled.key,
    defs.visionMatchFaceDetection.key,
    defs.visionMatchFaceRecognition.key,
    defs.visionMatchFaceConfirmsVoice.key,
    defs.visionMatchHandGestures.key,
    defs.screensaverDismissOnFace.key,
    defs.screensaverPostponeOnFace.key,
    defs.gestureMappings.key,
  };

  /// Face Recognition on this kiosk: Vision Match with its faces looked at
  /// on Ground Control, and the switch.
  bool get faceRecognition =>
      _settings.get(defs.groundControlEnabled) &&
      _settings.get(defs.cameraEnabled) &&
      _settings.get(defs.visionMatchEnabled) &&
      _settings.get(defs.visionMatchFaceDetection) &&
      _settings.get(defs.visionMatchFaceRecognition);

  /// The Voice Match and Vision Match features this kiosk has on, for the
  /// Kiosks page of the Ground Control app.
  Map<String, Object?> get features {
    final s = _settings;
    final people = [
      for (final p in defs.decodeVoiceMatchPeople(s.get(defs.voiceMatchPeople)))
        p.id,
    ];
    final chosen = s.get(defs.voiceMatchPolicy) == 'people';
    return {
      'voice_match': s.get(defs.voiceEnabled) && s.get(defs.voiceMatchEnabled),
      'policy': !chosen ? 'anyone' : (people.isEmpty ? 'enrolled' : 'people'),
      if (chosen && people.isNotEmpty) 'people': people,
      'trimming': s.get(defs.voiceMatchEndOnOtherVoice),
      'isolation': s.get(defs.voiceMatchIsolation),
      'wake_word_aligner': s.get(defs.voiceMatchWakeWordAligner),
      'speaker_sensor': s.get(defs.voiceMatchSpeakerSensor),
      'show_speaker': s.get(defs.voiceMatchShowSpeaker),
      'vision_match': s.get(defs.visionMatchEnabled),
      'face_detection': s.get(defs.visionMatchFaceDetection),
      'face_recognition': faceRecognition,
      // Confirm voices with faces: Ground Control takes a close voice for
      // the person it sees at the kiosk.
      'face_confirms_voice':
          faceRecognition && s.get(defs.visionMatchFaceConfirmsVoice),
      'hand_gestures': s.get(defs.visionMatchHandGestures),
      'dismiss_on_face': s.get(defs.screensaverDismissOnFace),
      'postpone_on_face': s.get(defs.screensaverPostponeOnFace),
      'finger_gestures': decodeGestureMappings(
        s.get(defs.gestureMappings),
      ).where((m) => m.triggerType == 'fingers').length,
    };
  }

  @override
  Future<void> init() async {
    _subs.add(
      bus.on<SettingChanged>().listen((e) {
        if (_faceRecognitionKeys.contains(e.key)) _faceRecognitionChanged();
        if (_featureKeys.contains(e.key)) {
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
    _subs
      ..add(
        bus.on<FaceArrived>().listen(
          (e) => _faceEvent('arrived', e.id, e.name),
        ),
      )
      ..add(bus.on<FaceLeft>().listen((e) => _faceEvent('left', e.id, e.name)))
      ..add(
        bus.on<FaceInViewChanged>().listen((e) {
          _inView = e;
          _faceRecognitionChanged();
        }),
      )
      ..add(
        bus.on<VisionPresenceChanged>().listen((e) {
          _presence = e;
          _faceRecognitionChanged();
        }),
      )
      ..add(
        bus.on<FacePinSkipped>().listen(
          (e) => _faceEvent('pin_skipped', e.id, e.name, {
            'mode': e.lockdown ? 'lockdown' : 'kiosk',
          }),
        ),
      )
      ..add(
        bus.on<FaceLockdownChanged>().listen((e) {
          if (!e.locked) _faceEvent('lockdown_off', e.id, e.name ?? '');
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
        name: 'faceRecognitionState',
        description:
            'Kiosk Satellite Face Recognition: who is at the kiosk, everyone '
            'recognized in view and, with Presence sensors on, whether '
            'someone is in front of the kiosk and looking at it',
        quiet: true,
        handler: (_) async => CommandResult.ok(faceRecognitionState()),
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
    // Runs as a Home Assistant app, not a Docker container.
    'haApp': appPath != null,
    'install': install,
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

  /// The latest of who Face Recognition sees and of the Presence sensors.
  FaceInViewChanged _inView = const FaceInViewChanged();
  VisionPresenceChanged? _presence;
  String? _faceRecognitionSent;

  /// The settings [faceRecognitionState] follows.
  static final _faceRecognitionKeys = {
    defs.groundControlEnabled.key,
    defs.cameraEnabled.key,
    defs.visionMatchEnabled.key,
    defs.visionMatchFaceDetection.key,
    defs.visionMatchFaceRecognition.key,
    defs.visionMatchPresenceSensors.key,
  };

  /// What plugins with the face.recognition capability and Home Assistant
  /// and custom pages read of Face Recognition: whether it runs, the person
  /// at the kiosk (empty name when nobody known is in view), everyone
  /// recognized in view with the person at the kiosk first, and the
  /// Presence and Looking at the kiosk sensors, null while Presence sensors
  /// is off. Ground Control's person ids stay private: the Home Assistant
  /// person is the key to act on.
  Map<String, Object?> faceRecognitionState() {
    final s = _settings;
    final on = faceRecognition;
    final sensors =
        s.get(defs.groundControlEnabled) &&
        s.get(defs.cameraEnabled) &&
        s.get(defs.visionMatchEnabled) &&
        s.get(defs.visionMatchFaceDetection) &&
        s.get(defs.visionMatchPresenceSensors);
    final view = on ? _inView : const FaceInViewChanged();
    String person(String? id) => thingsOf(id, people)['person'] ?? '';
    final id = view.id;
    return {
      'enabled': on,
      'name': id == null ? '' : view.name,
      'person': person(id),
      'color': id == null ? null : view.color ?? view.colors[id],
      'people': [
        for (final p in view.people)
          {'name': p.name, 'person': person(p.id), 'color': view.colors[p.id]},
      ],
      'present': sensors ? _presence?.present ?? false : null,
      'looking': sensors ? _presence?.looking ?? false : null,
    };
  }

  /// Publishes [FaceRecognitionChanged] when what it reports moved.
  void _faceRecognitionChanged() {
    final state = faceRecognitionState();
    final value = jsonEncode(state);
    if (value == _faceRecognitionSent) return;
    _faceRecognitionSent = value;
    bus.publish(FaceRecognitionChanged(state));
  }

  /// Face Recognition on Home Assistant's bus as
  /// `esphome.kiosk_satellite_face`, for automations: someone arrived or
  /// left on the arrival card's rule, or the PIN was skipped or Lockdown
  /// Mode turned off because they were recognized. With their Home
  /// Assistant person when Ground Control has one.
  void _faceEvent(
    String type,
    String? id,
    String who, [
    Map<String, Object?> extra = const {},
  ]) {
    final person = thingsOf(id, people)['person'] ?? '';
    bus.publish(
      HaEventRequested('kiosk_satellite_face', {
        'event_type': type,
        'name': who,
        'person': person,
        ...extra,
      }),
    );
    if (type == 'arrived' || type == 'left') {
      bus.publish(FaceArrivalReported(type: type, name: who, person: person));
    }
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
        // The hello goes out signed, once the service's challenge comes.
        _pendingHello = hello;
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
      'device_id': deviceId,
      'name': deviceName.isNotEmpty ? deviceName : '${data['name'] ?? ''}',
      'model': '${data['model'] ?? ''}',
      'version': '${data['appVersion'] ?? ''}',
      'enroll': _enrollAllowed,
      'features': features,
    };
  }

  /// Allow enrollment here or a Voice Match feature changed: the service
  /// lists the kiosk to match.
  void _sendSettings() {
    _send({'type': 'settings', 'enroll': _enrollAllowed, 'features': features});
  }

  /// Signs the service's challenge into the hello and sends it.
  Future<void> _answer(int gen, String nonce) async {
    final hello = _pendingHello;
    _pendingHello = null;
    if (hello == null) return;
    final key = await (_key ??= _loadKey());
    if (gen != _generation) return;
    if (key == null) {
      log.warn(
        name,
        'this build has no Ground Control client key, so Ground Control '
        'turns it away',
      );
    }
    final proof = key == null
        ? null
        : await key.proof(nonce, '${hello['device_id'] ?? ''}');
    if (gen != _generation) return;
    _send({...hello, 'proof': ?proof});
  }

  void _send(Map<String, Object?> message) {
    try {
      _socket?.sink.add(jsonEncode(message));
    } on Object {
      // Gone: the next connection says hello with the current settings.
    }
  }

  /// The id this kiosk goes by in Ground Control, for the session sockets too.
  String get deviceId => defs.groundControlDeviceId(
    _settings.get(defs.deviceHostname),
    _settings.get(defs.deviceName).trim(),
    _settings.get(defs.fleetId),
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
      case 'challenge':
        final nonce = msg['nonce'];
        if (nonce is String) unawaited(_answer(gen, nonce));
      case 'ticket':
        final t = msg['ticket'];
        ticket = t is String && t.isNotEmpty ? t : null;
      case 'pending':
      case 'declined':
        ticket = null;
        log.info(
          name,
          msg['type'] == 'pending'
              ? 'waiting for approval in the Ground Control app'
              : 'declined in the Ground Control app',
        );
        _attempt = 0;
        _setStatus('${msg['type']}', null);
      case 'people':
        people = [
          for (final p in (msg['people'] as List? ?? const []))
            if (p is Map) p.cast<String, Object?>(),
        ];
        // A person may have been linked to another Home Assistant person.
        _pictures.clear();
        _faceRecognitionChanged();
        version = '${msg['version'] ?? version}';
        model = '${msg['model'] ?? model}';
        final path = msg['app_path'];
        appPath = path is String && path.startsWith('/') ? path : null;
        final kind = msg['install'];
        if (kind is String) {
          install = {
            'install': kind,
            'arch': '${msg['arch'] ?? ''}',
            'cuda': '${msg['cuda'] ?? ''}',
            'onGpu': msg['on_gpu'] == true,
          };
        } else {
          // An older Ground Control: nothing left from the one before it.
          install = const {};
        }
        _attempt = 0;
        _setStatus('connected', baseUrl);
      case 'error':
        log.warn(name, 'Ground Control turned this kiosk away: ${msg['code']}');
        if (msg['code'] == 'unauthorized') _setStatus('refused', null);
        if (msg['code'] == 'not_kiosk_satellite') _setStatus('unsigned', null);
      case 'enroll_face':
        final personId = '${msg['person_id'] ?? ''}';
        if (personId.isEmpty) return;
        if (!faceRecognition) {
          log.info(
            name,
            'face enrollment for ${msg['name']} refused: Face Recognition is off',
          );
          _send({
            'type': 'enroll_error',
            'person_id': personId,
            'code': 'off',
            'message': '',
          });
          return;
        }
        bus.publish(
          FaceEnrollRequested(
            personId: personId,
            name: '${msg['name'] ?? ''}',
            color: msg['color'] is String ? msg['color'] as String : null,
          ),
        );
      case 'enroll_face_stop':
        bus.publish(const FaceEnrollStopRequested());
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
    _pendingHello = null;
    ticket = null;
    if (code == 4401) {
      _setStatus('refused', null);
      return;
    }
    if (code == 4403) {
      // Not Kiosk Satellite to the service: a build without the key.
      _setStatus('unsigned', null);
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
    final pass = usable == null ? null : ticket;
    if (usable != _published || pass != _publishedTicket) {
      _published = usable;
      _publishedTicket = pass;
      bus.publish(GroundControlServiceChanged(usable, ticket: pass));
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
