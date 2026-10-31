import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random, sqrt;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

import '../../core/permissions.dart';
import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/kiosk_http_client.dart';
import '../../core/manager.dart';
import '../audio/mic_hub.dart';
import '../home_assistant/ha_tts.dart';
import '../notifications/notification_sounds.dart';
import '../remote/auth.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import '../voice/ha_socket.dart';
import '../voice/voice_requests_manager.dart' show normalizeKioskName;
import '../voice/voice_turns.dart';
import 'intercom_audio.dart';
import 'intercom_routes.dart';
import 'intercom_sensors.dart';

/// One kiosk on the roster, with what its identity probe said.
class IntercomKiosk {
  IntercomKiosk({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    required this.version,
    this.tls = false,
  });

  final String id;
  String name;
  String address;
  int port;
  String version;
  bool tls;
  int? intercomPort;
  bool? intercomTls;
  int get callPort => intercomPort ?? port;
  bool get callTls => intercomTls ?? tls;
  String get callUrl => Uri(
    scheme: callTls ? 'https' : 'http',
    host: address,
    port: callPort,
  ).toString();

  /// Whether the kiosk is discovered or remains in the saved fleet.
  bool heard = true;

  /// What `GET /api/intercom/identity` answered, or null before a probe.
  bool? enabled;
  String? keyFingerprint;
  bool dnd = false;
  DateTime? probedAt;
  bool probeFailed = false;

  String get url =>
      Uri(scheme: tls ? 'https' : 'http', host: address, port: port).toString();

  /// ready, off, key, tls, dnd, unreachable, offline, unknown. Unreachable is
  /// a known kiosk whose admin port does not answer.
  String status(String ourFingerprint, {bool encrypted = false}) {
    if (!heard) return 'offline';
    if (enabled == null) return probeFailed ? 'unreachable' : 'unknown';
    if (enabled == false) return 'off';
    if (keyFingerprint != ourFingerprint) return 'key';
    if (callTls != encrypted) return 'tls';
    if (dnd) return 'dnd';
    return 'ready';
  }

  Map<String, Object?> toJson(String ourFingerprint, {bool encrypted = false}) {
    final s = status(ourFingerprint, encrypted: encrypted);
    return {
      'id': id,
      'name': name,
      'address': address,
      'port': port,
      'version': version,
      'status': s,
      'statusText': switch (s) {
        'ready' => 'Ready',
        'off' => 'Intercom off',
        'key' => 'Different key',
        'tls' => 'Encryption mismatch',
        'dnd' => 'Do not disturb',
        'unreachable' => 'Unreachable',
        'offline' => 'Offline',
        _ => 'Checking…',
      },
    };
  }
}

/// The call this kiosk is on, or was on until the card closes.
class IntercomCall {
  IntercomCall({
    required this.id,
    required this.kind,
    required this.outgoing,
    required this.peer,
  });

  final String id;

  /// `call` or `broadcast`.
  final String kind;
  final bool outgoing;

  /// The other kiosk: the callee, the caller, or the broadcast's sender.
  /// For a broadcast this kiosk sends, the first target (the card names
  /// them all through [targets]).
  Map<String, Object?> peer;

  /// When the voice started flowing, null while still connecting.
  DateTime? since;
  DateTime? endedAt;
  String reason = '';

  /// An announcement's spoken text, for its card. Empty for a clip.
  String message = '';
  bool farTalking = false;
  bool localTalking = false;
  bool muted = false;

  /// When Answer automatically opens the call, for the countdown.
  DateTime? autoAnswerAt;

  /// Frames sent and received, for the status and a silent link.
  int sent = 0;
  int received = 0;

  /// An announcement Home Assistant asked for: the audio is a decoded
  /// clip, not the microphone, and the card offers Stop alone.
  bool automated = false;

  /// Plays an announcement without its on-device modal or screen wake.
  bool audioOnly = false;

  /// The broadcast's recipients, by kiosk id: `listening`, `busy`, `dnd`,
  /// `off`, `unreachable`, `key`.
  final targets = <String, Map<String, Object?>>{};

  int get durationSeconds {
    final s = since;
    if (s == null) return 0;
    return (endedAt ?? DateTime.now()).difference(s).inSeconds;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind,
    'outgoing': outgoing,
    'peer': peer,
    'since': since?.millisecondsSinceEpoch,
    'talking': farTalking,
    'localTalking': localTalking,
    'muted': muted,
    'reason': reason,
    'duration': durationSeconds,
    'autoAnswerAt': autoAnswerAt?.millisecondsSinceEpoch,
    'sent': sent,
    'received': received,
    'automated': automated,
    'audioOnly': audioOnly,
    'message': message,
    if (kind == 'broadcast') 'targets': targets.values.toList(),
  };
}

/// One audio socket: to the kiosk called, or from the kiosk calling.
class _Link {
  _Link(this.peerId, this.channel);
  final String peerId;
  final WebSocketChannel channel;
  StreamSubscription<Object?>? sub;

  void sendText(Map<String, Object?> msg) {
    try {
      channel.sink.add(jsonEncode(msg));
    } catch (_) {}
  }

  void sendBytes(Uint8List bytes) {
    try {
      channel.sink.add(bytes);
    } catch (_) {}
  }

  Future<void> close() async {
    await sub?.cancel();
    sub = null;
    try {
      await channel.sink.close();
    } catch (_) {}
  }
}

/// Kiosks on the same network talk to each other.
///
/// A call is placed from the kiosk menu's sheet (or a gesture) and rings
/// on the kiosk picked; Announce to all talks to every ready kiosk at once,
/// one way, and Home Assistant's announce action does the same with a
/// spoken message. Both
/// signaling and voice use a dedicated listener advertised by the admin
/// identity route. Its HTTPS setting is independent. Three
/// REST routes before the bearer gate, verified with a token signed by the
/// shared intercom key, and one WebSocket per call carrying raw 16 kHz
/// PCM16 chunks both ways, straight from the microphone hub. Playback
/// goes through a communication-route AudioTrack so the platform echo
/// canceller keeps the far voice out of the near microphone.
///
/// The roster is the kiosk switcher's list (the `fleet` command), each
/// entry probed with `GET /api/intercom/identity` for whether its intercom
/// is on, which key it holds and whether it is on Do not disturb.
///
/// Both UIs draw the `intercomStatus` command and hear
/// [IntercomStateChanged] when to redraw. The call itself holds the
/// screensaver, the rotation and the home timer the way a voice turn does
/// ([VoiceInteractionChanged] with reason `intercom`), ducks the music
/// through the same event and pauses wake word detection.
///
/// States: idle, calling (waiting for the other kiosk to pick up), ringing
/// (a call coming in), in_call, broadcasting (this kiosk talks to
/// everyone), listening (a broadcast coming in), ended (the card's last
/// words, ten seconds) and missed (a minute for Home Assistant).
class IntercomManager extends Manager {
  IntercomManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;
  HttpServer? _server;
  Future<void>? _listenerQueue;
  bool _listenerTls = false;
  bool _disposed = false;
  bool _certificateChanged = false;
  late final _routes = IntercomRoutes(
    commands,
    requiresTls: () => _settings.get(defs.intercomTls),
  );

  Future<void> _syncListener() {
    final next = (_listenerQueue ?? Future<void>.value()).then((_) async {
      final tls = _settings.get(defs.intercomTls);
      final running = !_disposed && enabled && available;
      if (_server != null &&
          (!running || tls != _listenerTls || (tls && _certificateChanged))) {
        await _finish('ended');
        final old = _server;
        _server = null;
        await old?.close(force: true);
      }
      _certificateChanged = false;
      if (!running || _server != null) return;
      try {
        final context = tls
            ? (await _settings.tls.load()).securityContext()
            : null;
        _server = context == null
            ? await HttpServer.bind(InternetAddress.anyIPv4, 0)
            : await HttpServer.bindSecure(InternetAddress.anyIPv4, 0, context);
        _listenerTls = tls;
        _server!.listen(
          (request) async {
            try {
              await shelf_io.handleRequest(request, _routes.call);
            } catch (e) {
              log.debug(name, 'Intercom connection ended: $e');
            }
          },
          onError: (Object e) {
            log.debug(name, 'Intercom connection refused: $e');
          },
        );
      } catch (e) {
        log.error(name, 'Could not start intercom listener: $e');
      }
    });
    _listenerQueue = next.catchError((Object e) {
      log.error(name, 'Intercom listener configuration failed: $e');
    });
    return _listenerQueue!;
  }

  @override
  String get name => 'intercom';

  /// Swapped for fakes in tests.
  http.Client Function()? _clientFactory;
  http.Client Function() get clientFactory => _clientFactory ?? http.Client.new;
  set clientFactory(http.Client Function() factory) => _clientFactory = factory;

  /// The Home Assistant websocket the voice pickers list voices over; a
  /// test hands in its own.
  HaSocket Function(String base, String token)? haSocketFactory;
  http.Client _peerClient() => _clientFactory?.call() ?? kioskPeerClient();
  late WebSocketChannel Function(Uri uri) socketFactory = (uri) {
    final client = kioskPeerHttpClient(requireTls: uri.scheme == 'wss');
    final channel = IOWebSocketChannel.connect(
      uri,
      customClient: client,
      connectTimeout: const Duration(seconds: 6),
    );
    channel.ready.then(
      (_) => client.close(),
      onError: (Object _) => client.close(force: true),
    );
    return channel;
  };
  IntercomAudio audio = IntercomAudio();
  MicHub micHub = MicHub.instance;
  Future<bool> Function() micPermission = () =>
      ensureOsPermission(Permission.microphone);
  Random random = Random.secure();

  /// How long one call to another kiosk may take.
  Duration requestTimeout = const Duration(seconds: 4);
  Duration probeTimeout = const Duration(seconds: 3);

  /// Answer automatically waits this long with Decline on screen.
  Duration autoAnswerDelay = const Duration(seconds: 3);

  /// The card stays up this long after a call ends.
  Duration endedHold = const Duration(seconds: 10);

  /// A broadcast's card closes this long after the sender is done.
  Duration broadcastHold = const Duration(seconds: 5);

  /// How much of a picked ring sound a short ring plays: enough to know
  /// the sound, then out of the way of an announcement.
  Duration shortRingSound = const Duration(seconds: 2);

  /// The state sensor reads missed for this long.
  Duration missedHold = const Duration(minutes: 1);

  /// The ring sound repeats at this cadence.
  Duration ringCadence = const Duration(seconds: 4);

  /// How long a probe result is trusted.
  Duration probeTtl = const Duration(seconds: 30);

  /// A call asked for by voice waits this long for the conversation to
  /// end before it ends it.
  Duration voiceTurnWait = const Duration(seconds: 30);

  /// How long a call rings here before it is missed: the Ring for setting.
  /// Tests shorten it.
  Duration Function()? ringForOverride;

  Duration get _ringFor =>
      ringForOverride?.call() ??
      Duration(
        seconds: int.tryParse(_settings.get(defs.intercomRingSeconds)) ?? 30,
      );

  /// How long a live call may run here before it hangs up, null for no
  /// limit: the Maximum call duration setting. Tests shorten it.
  Duration? Function()? maxCallOverride;

  Duration? get _maxCall {
    final override = maxCallOverride;
    if (override != null) return override();
    final minutes =
        int.tryParse(_settings.get(defs.intercomMaxCallMinutes)) ?? 0;
    return minutes > 0 ? Duration(minutes: minutes) : null;
  }

  /// The margin the caller waits past the callee's own ring time.
  Duration callerMargin = const Duration(seconds: 10);

  // ── State ──────────────────────────────────────────────────────────

  String _state = 'idle';
  IntercomCall? _call;

  /// Whether the full screen roster (Call a kiosk) is up on the kiosk
  /// screen. Set by `intercomOpen`, cleared by the close button, back, a
  /// call starting, the screensaver, Lockdown Mode or the intercom going
  /// off, so every opener and every closer meet at one place, the way the
  /// app launcher's [visible] works.
  final rosterVisible = ValueNotifier<bool>(false);

  /// The states the full screen call card shows in, its last words
  /// included.
  static const callScreenStates = {
    'calling',
    'ringing',
    'in_call',
    'broadcasting',
    'listening',
    'ended',
  };

  /// Whether the roster or the call card fills the kiosk screen. An
  /// announcement from Home Assistant has a card of its own.
  bool get screenShown =>
      rosterVisible.value ||
      (callScreenStates.contains(_state) &&
          !(_call?.automated == true && _call?.outgoing != true));
  bool _screenShown = false;

  void _syncScreenShown() {
    final shown = screenShown;
    if (shown == _screenShown) return;
    _screenShown = shown;
    bus.publish(FullscreenViewChanged(view: 'intercom', shown: shown));
  }

  final _links = <String, _Link>{};
  final _kiosks = <String, IntercomKiosk>{};
  String _selfId = '';
  String _selfName = '';
  String _selfAddress = '';
  int _selfPort = 0;
  String _selfVersion = '';
  bool _fleetEnabled = false;
  bool _micGranted = true;

  /// The page kept the microphone through [pageMicWait]: a page that does
  /// not answer [IntercomMicHold], and the call is listen only.
  bool _micBusy = false;

  /// Whether the page has been asked to let go of the microphone.
  bool _pageMicHeld = false;

  /// How long a page gets to let go of the microphone after
  /// [IntercomMicHold] before the call goes on without it.
  Duration pageMicWait = const Duration(seconds: 2);

  /// The tokens verified so far, by their expiry, so one cannot be replayed.
  final _seenTokens = <String, int>{};

  /// What the answer mode was before the Do not disturb tile flipped it.
  String _dndPrevious = 'ring';

  StreamSubscription<Uint8List>? _mic;
  final _subs = <StreamSubscription<Object?>>[];

  /// Whether this kiosk is in a conversation, for a call asked for by
  /// voice to wait out.
  late final _voiceTurns = VoiceTurns(bus);
  Timer? _remoteRosterTimer;
  Timer? _ringTimer;
  Timer? _chimeTimer;
  Timer? _autoTimer;
  Timer? _holdTimer;
  Timer? _connectTimer;
  Timer? _missedTimer;
  Timer? _injectTimer;

  /// The picked ring sound plays under this id, so the cadence finds it
  /// still going and the end of the ringing can stop it.
  static const _ringSoundId = 'intercom-ring';
  bool _ringSoundPlaying = false;

  /// Bumped by every stop, so a ring still looking up its file when the
  /// call is answered stays quiet.
  int _ringGeneration = 0;
  Timer? _ringSoundCut;
  Timer? _limitTimer;

  /// The key code last handed to the kiosk manager for the hang up button.
  int _hangupKeyArmed = 0;
  DateTime _lastLevel = DateTime.fromMillisecondsSinceEpoch(0);
  double _farLevel = 0;
  double _nearLevel = 0;
  bool _interactionHeld = false;
  int _nextId = 0;

  String get state => _state;
  IntercomCall? get call => _call;
  List<IntercomKiosk> get kiosks => List.unmodifiable(_kiosks.values);

  bool get enabled => _settings.get(defs.intercomEnabled);

  /// Whether the feature can run at all: the remote admin serves and the
  /// discovery names this kiosk and finds the others.
  bool get available => _fleetEnabled;

  bool get dnd =>
      _settings.get(defs.intercomAnswerMode) == 'dnd' ||
      _settings.get(defs.lockdownEnabled);

  String get key => _settings.get(defs.intercomKey);

  /// The first eight hex digits of the key's SHA-256, what the identity
  /// probe compares. Empty with no key.
  String get keyFingerprint => fingerprintOf(key);

  static String fingerprintOf(String key) => key.isEmpty
      ? ''
      : sha256.convert(utf8.encode(key)).toString().substring(0, 8);

  AuthStore? _auth;
  String _authKey = '';
  AuthStore get _tokens {
    if (_auth == null || _authKey != key) {
      _authKey = key;
      _auth = AuthStore('intercom:$key');
    }
    return _auth!;
  }

  // ── Init ───────────────────────────────────────────────────────────

  @override
  Future<void> init() async {
    _registerCommands();
    _voiceTurns.start();
    _subs.add(
      bus.on<RemoteObserversChanged>().listen((event) {
        if (!event.topics.contains('intercom')) {
          _remoteRosterTimer?.cancel();
          _remoteRosterTimer = null;
        } else {
          _remoteRosterTimer ??= Timer.periodic(const Duration(seconds: 30), (
            _,
          ) {
            if (enabled) unawaited(_probeAll());
          });
        }
      }),
    );
    rosterVisible.addListener(_syncScreenShown);
    _subs.add(bus.on<FleetChanged>().listen((_) => _readFleet()));
    _subs.add(
      bus.on<SoundEnded>().listen((e) {
        if (e.id == _ringSoundId) _ringSoundPlaying = false;
      }),
    );
    _subs.add(
      bus.on<TlsIdentityChanged>().listen((_) {
        _certificateChanged = true;
        unawaited(_syncListener());
      }),
    );
    // An abandoned roster gives way to the screensaver, as the launcher
    // does.
    _subs.add(
      bus.on<ScreensaverStateChanged>().listen((e) {
        if (e.active) rosterVisible.value = false;
      }),
    );
    _subs.add(
      bus.on<SettingChanged>().listen((e) {
        if (e.key == defs.lockdownEnabled.key && e.value == true) {
          rosterVisible.value = false;
        }
        if (e.key == defs.intercomTls.key) {
          unawaited(_syncListener());
          _changed();
        } else if (e.key == defs.intercomEnabled.key) {
          if (e.value != true) rosterVisible.value = false;
          unawaited(_onEnabledChanged());
        } else if (e.key == defs.intercomHangupKey.key ||
            e.key == defs.intercomHangupKeyRinging.key) {
          _syncHangupKey();
        } else if (e.key == defs.intercomVolume.key) {
          unawaited(audio.setVolume(_playbackGain()));
        } else if (e.key == defs.intercomTalkMode.key) {
          unawaited(audio.setHandsFree(_handsFreeCall));
          _changed();
        } else if (e.key == defs.intercomAnswerMode.key ||
            e.key == defs.lockdownEnabled.key ||
            e.key == defs.intercomKey.key) {
          _changed();
        } else if (e.key == defs.remoteEnabled.key ||
            e.key == defs.remotePassword.key ||
            e.key == defs.remoteFleetDiscovery.key) {
          unawaited(_readFleet());
        }
      }),
    );
    // Another Voice Satellite turn or a page taking the microphone ends
    // the call: the page holds the microphone exclusively.
    micHub.browserCapturing.addListener(_onBrowserCapture);
    _subs.add(
      bus.on<IntercomHangupRequested>().listen((e) {
        if (_hangupStates.contains(_state)) {
          unawaited(hangup());
        } else if (e.button && _state == 'ringing') {
          switch (_settings.get(defs.intercomHangupKeyRinging)) {
            case 'answer':
              unawaited(_answer());
            case 'decline':
              unawaited(_decline());
          }
        }
      }),
    );
    await _readFleet();
    if (enabled && key.isEmpty) await _ensureKey();
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _syncListener();
    _remoteRosterTimer?.cancel();
    micHub.browserCapturing.removeListener(_onBrowserCapture);
    for (final s in _subs) {
      await s.cancel();
    }
    await _voiceTurns.dispose();
    await _finish('ended', notify: false);
    _cancelTimers();
    _holdTimer?.cancel();
    _missedTimer?.cancel();
    _limitTimer?.cancel();
    rosterVisible.dispose();
  }

  Future<void> _onEnabledChanged() async {
    await _syncListener();
    if (enabled) {
      await _ensureKey();
      unawaited(_probeAll(force: true));
    } else if (_state != 'idle') {
      await _finish('ended');
    }
    _changed();
  }

  void _onBrowserCapture() {
    if (micHub.browserCapturing.value && _active) {
      log.info(name, 'the page took the microphone, ending the call');
      unawaited(hangup(reason: 'mic_busy'));
    }
  }

  Future<void> _ensureKey() async {
    if (key.isNotEmpty) return;
    await _settings.set(defs.intercomKey, _newKey());
    log.info(name, 'intercom key made');
  }

  String _newKey() => base64Url
      .encode(List<int>.generate(32, (_) => random.nextInt(256)))
      .replaceAll('=', '');

  // ── The roster ─────────────────────────────────────────────────────

  Future<void> _readFleet() async {
    final r = await commands.execute('fleet', const {});
    if (!r.ok || r.data is! Map) return;
    final data = (r.data as Map).cast<String, Object?>();
    _fleetEnabled = data['enabled'] == true;
    final devices = data['devices'];
    final heard = <String>{};
    if (devices is List) {
      for (final d in devices) {
        if (d is! Map) continue;
        final id = '${d['id'] ?? ''}';
        if (id.isEmpty) continue;
        if (d['self'] == true) {
          _selfId = id;
          _selfName = '${d['name'] ?? ''}';
          _selfAddress = '${d['address'] ?? ''}';
          _selfPort = (d['port'] as num?)?.toInt() ?? 0;
          _selfVersion = '${d['version'] ?? ''}';
          continue;
        }
        heard.add(id);
        final k = _kiosks[id];
        if (k == null) {
          _kiosks[id] = IntercomKiosk(
            id: id,
            name: '${d['name'] ?? ''}',
            address: '${d['address'] ?? ''}',
            port: (d['port'] as num?)?.toInt() ?? 2324,
            version: '${d['version'] ?? ''}',
            tls: d['tls'] == true,
          );
        } else {
          if (k.tls != (d['tls'] == true) ||
              k.address != '${d['address'] ?? ''}' ||
              k.port != ((d['port'] as num?)?.toInt() ?? k.port)) {
            k
              ..enabled = null
              ..keyFingerprint = null
              ..probedAt = null
              ..probeFailed = false;
          }
          k
            ..tls = d['tls'] == true
            ..name = '${d['name'] ?? ''}'
            ..address = '${d['address'] ?? ''}'
            ..port = (d['port'] as num?)?.toInt() ?? k.port
            ..version = '${d['version'] ?? ''}'
            ..heard = true;
        }
      }
    }
    for (final k in _kiosks.values) {
      if (!heard.contains(k.id)) k.heard = false;
    }
    await _syncListener();
    _changed();
    if (enabled) unawaited(_probeAll());
  }

  /// Probes every heard kiosk whose result is stale. A forced probe waits
  /// for one already under way, then runs; an ordinary one rides it.
  Future<void> _probeAll({bool force = false}) async {
    final inFlight = _probeFuture;
    if (inFlight != null) {
      await inFlight;
      if (!force) return;
    }
    final run = _probeDue(force);
    _probeFuture = run;
    try {
      await run;
    } finally {
      if (_probeFuture == run) _probeFuture = null;
    }
  }

  Future<void>? _probeFuture;

  Future<void> _probeDue(bool force) async {
    final now = DateTime.now();
    final due = [
      for (final k in _kiosks.values)
        if (k.heard &&
            (force ||
                k.probedAt == null ||
                now.difference(k.probedAt!) > probeTtl))
          k,
    ];
    if (due.isEmpty) return;
    await Future.wait([for (final k in due) _probe(k)]);
    _changed();
  }

  Future<void> _probe(IntercomKiosk k) async {
    final url = k.url;
    final res = await _get('$url/api/intercom/identity', timeout: probeTimeout);
    if (k.url != url) return;
    if (res?.statusCode == 429) return;
    k.probedAt = DateTime.now();
    final data = _jsonOf(res);
    if (res == null || res.statusCode != 200 || data == null) {
      k.probeFailed = true;
      k.enabled = null;
      // An older build without the route: the intercom is off there.
      if (res != null && res.statusCode == 404) {
        k.probeFailed = false;
        k.enabled = false;
      }
      return;
    }
    final endpoint = data['endpoint'];
    if (endpoint is Map &&
        endpoint['port'] is int &&
        (endpoint['port'] as int) > 0 &&
        (endpoint['port'] as int) <= 65535 &&
        endpoint['tls'] is bool) {
      k.intercomPort = endpoint['port'] as int;
      k.intercomTls = endpoint['tls'] as bool;
    } else {
      k.intercomPort = null;
      k.intercomTls = null;
    }
    k.probeFailed = false;
    k.enabled = data['enabled'] == true;
    k.keyFingerprint = '${data['key'] ?? ''}';
    k.dnd = data['dnd'] == true;
    final n = '${data['name'] ?? ''}';
    if (n.isNotEmpty) k.name = n;
  }

  IntercomKiosk? _kioskById(String id) => _kiosks[id];

  /// A kiosk by its name, any case, or its address: how an automation
  /// names one, since a kiosk's id is nothing Home Assistant sees. The
  /// roster is read again when the name is unknown, so a kiosk that
  /// appeared since the last look is found too.
  Future<IntercomKiosk?> _kioskNamed(String target) async {
    final t = target.trim();
    if (t.isEmpty) return null;
    var k = _matchKiosk(t);
    if (k == null) {
      await _readFleet();
      k = _matchKiosk(t);
    }
    return k;
  }

  IntercomKiosk? _matchKiosk(String t) {
    final lower = t.toLowerCase();
    return _kiosks.values
        .where((k) => k.name.toLowerCase() == lower || k.address == t)
        .firstOrNull;
  }

  bool get _encrypted => _settings.get(defs.intercomTls);
  static const _encryptionMismatch =
      'Encryption mismatch. Enable Encrypt communications on all kiosks in the call.';

  List<IntercomKiosk> get _ready => [
    for (final k in _kiosks.values)
      if (k.status(keyFingerprint, encrypted: _encrypted) == 'ready') k,
  ];

  // ── Voice requests ─────────────────────────────────────────────────

  /// The Kiosk Satellite intercom script, through the voice requests
  /// manager: `list` names the kiosks this one can call and `call` rings
  /// one. Asked for in a voice turn, the call is checked now and placed
  /// once the turn ends, so the call taking the microphone never cuts off
  /// the answer that says it is coming.
  Future<Map<String, Object?>> _voiceRequest(Map<String, Object?> p) async {
    await _readFleet();
    final self = _selfName.isNotEmpty
        ? _selfName
        : _settings.get(defs.deviceName);
    final rooms = voiceRooms(p['rooms']);
    Map<String, Object?> entry(IntercomKiosk k) {
      final st = k.status(keyFingerprint, encrypted: _encrypted);
      final area = rooms[normalizeKioskName(k.name)]?.area ?? '';
      return {
        'name': k.name,
        if (area.isNotEmpty) 'area': area,
        'status': _voiceStatus[st] ?? st,
      };
    }

    Map<String, Object?> fail(
      String error, [
      Iterable<IntercomKiosk>? kiosks,
    ]) => {
      'ok': false,
      'kiosk': self,
      'error': error,
      if (kiosks != null) 'kiosks': [for (final k in kiosks) entry(k)],
    };
    if (!enabled) return fail('the intercom is off on this kiosk');
    if (!available) {
      return fail('the intercom needs Remote Administration on this kiosk');
    }
    switch ('${p['action'] ?? ''}'.trim().toLowerCase()) {
      case 'list':
        await _probeAll();
        return {
          'ok': true,
          'kiosk': self,
          'result': 'listed',
          'kiosks': [for (final k in _voiceRoster) entry(k)],
        };
      case 'call':
        if (_busy && _state != 'listening') {
          return fail('this kiosk is already in a call');
        }
        final target = '${p['kiosk'] ?? ''}';
        final matches = matchKiosks(
          target,
          _kiosks.values,
          name: (k) => k.name,
          address: (k) => k.address,
          rooms: rooms,
        );
        if (matches.length != 1) {
          await _probeAll();
          if (matches.length > 1) {
            return fail('several kiosks match, ask which one', matches);
          }
          if (matchKiosks(
            target,
            [self],
            name: (n) => n,
            rooms: rooms,
          ).isNotEmpty) {
            return fail('that is this kiosk');
          }
          return fail('no kiosk goes by that name', _voiceRoster);
        }
        final k = matches.single;
        await _probe(k);
        final st = k.status(keyFingerprint, encrypted: _encrypted);
        if (st != 'ready') {
          return fail('${k.name}: ${_voiceStatus[st] ?? st}');
        }
        final calling = {
          'ok': true,
          'kiosk': self,
          'result': 'calling',
          'calling': k.name,
        };
        if (p['voiceTurn'] == true) {
          unawaited(_callAfterTurn(k));
          return calling;
        }
        final r = await _place(k);
        return r.ok ? calling : fail(r.error ?? 'failed');
      default:
        return fail('action must be call or list');
    }
  }

  List<IntercomKiosk> get _voiceRoster => [
    for (final k in _kiosks.values)
      if (k.heard) k,
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  /// A kiosk's status as the LLM reads it.
  static const _voiceStatus = {
    'ready': 'ready',
    'off': 'its intercom is off',
    'key': 'a different intercom key',
    'tls': 'encryption mismatch',
    'dnd': 'do not disturb',
    'unreachable': 'not answering',
    'offline': 'offline',
    'unknown': 'not checked yet',
  };

  Future<void> _callAfterTurn(IntercomKiosk k) async {
    // A realtime conversation would otherwise hold on through its closing
    // silence after the answer.
    await commands.execute('voiceEndAfterAnswer', const {});
    if (!await _voiceTurns.ended(voiceTurnWait)) {
      log.info(name, 'the conversation is still going, ending it for the call');
      await commands.execute('voiceCancel', const {});
    }
    final r = await _place(k);
    if (!r.ok) log.warn(name, 'the call to ${k.name} failed: ${r.error}');
  }

  // ── Status ─────────────────────────────────────────────────────────

  Map<String, Object?> status() => {
    'available': available,
    'enabled': enabled,
    'state': _state,
    'answerMode': _settings.get(defs.intercomAnswerMode),
    'talkMode': talkMode,
    'dnd': dnd,
    'lockdown': _settings.get(defs.lockdownEnabled),
    'micGranted': _micGranted,
    'micBusy': _micBusy,
    'self': {'id': _selfId, 'name': _selfName},
    'call': _call?.toJson(),
    'kiosks':
        [
          for (final k in _kiosks.values..toList())
            k.toJson(keyFingerprint, encrypted: _encrypted),
        ]..sort(
          (a, b) => '${a['name']}'.toLowerCase().compareTo(
            '${b['name']}'.toLowerCase(),
          ),
        ),
  };

  /// The talk mode this kiosk calls with. Hands free leans on the device's
  /// echo canceller, which plenty of devices have without reporting one, so
  /// the choice is always the user's.
  String get talkMode => _settings.get(defs.intercomTalkMode);

  void _changed() => bus.publish(IntercomStateChanged(status()));

  bool get _active =>
      _state == 'in_call' || _state == 'broadcasting' || _state == 'listening';

  bool get _busy => _state != 'idle' && _state != 'ended' && _state != 'missed';

  // ── Commands ───────────────────────────────────────────────────────

  void _registerCommands() {
    commands
      ..register(
        Command(
          name: 'intercomStatus',
          description:
              'The intercom as both UIs draw it: state, the current call, '
              'the kiosks on the network and their readiness.',
          quiet: true,
          handler: (_) async {
            if (enabled) unawaited(_probeAll());
            return CommandResult.ok(status());
          },
        ),
      )
      ..register(
        Command(
          name: 'intercomSensors',
          description:
              'What the Intercom sensors report: enabled, state, the other '
              'kiosk and Do not disturb. Probes nothing.',
          quiet: true,
          handler: (_) async => CommandResult.ok({
            'enabled': enabled,
            ...intercomSensors(status()),
          }),
        ),
      )
      ..register(
        Command(
          name: 'intercomKiosks',
          description: 'The roster, probed afresh when asked.',
          params: const {'probe': 'true to probe every kiosk again'},
          quiet: true,
          handler: (p) async {
            await _readFleet();
            if (p['probe'] == true) await _probeAll(force: true);
            return CommandResult.ok(status()['kiosks']);
          },
        ),
      )
      ..register(
        Command(
          name: 'intercomCall',
          description:
              'Call another kiosk by its id, or by its name or address.',
          params: const {
            'id': "The kiosk's id from intercomStatus",
            'kiosk': "The kiosk's name (any case) or address, without an id",
          },
          handler: (p) async {
            final id = '${p['id'] ?? ''}';
            final k = id.isNotEmpty
                ? _kioskById(id)
                : await _kioskNamed('${p['kiosk'] ?? ''}');
            if (k == null) return const CommandResult.fail('unknown kiosk');
            final r = await _place(k);
            if (!r.ok) return r;
            return CommandResult.ok({'id': k.id, 'kiosk': k.name});
          },
        ),
      )
      ..register(
        Command(
          name: 'intercomVoiceRequest',
          description:
              'What the Kiosk Satellite intercom script asks for, answered '
              'in the shape the script hands back to the LLM.',
          params: const {
            'action': 'call or list',
            'kiosk': 'The kiosk to call, by name',
            'voiceTurn':
                'true to place the call once the voice turn that asked '
                'for it ends',
          },
          // The voice requests manager logs each one with its outcome.
          quiet: true,
          handler: (p) async => CommandResult.ok(await _voiceRequest(p)),
        ),
      )
      ..register(
        Command(
          name: 'intercomBroadcast',
          description: 'Talk to every ready kiosk at once, push to talk.',
          handler: (_) async => _broadcast(),
        ),
      )
      ..register(
        Command(
          name: 'intercomAnswer',
          description: 'Answer the call ringing here.',
          handler: (_) async => _answer(),
        ),
      )
      ..register(
        Command(
          name: 'intercomDecline',
          description: 'Decline the call ringing here.',
          handler: (_) async => _decline(),
        ),
      )
      ..register(
        Command(
          name: 'intercomHangup',
          description:
              'End the call, cancel one being placed, or close a broadcast.',
          handler: (_) async {
            if (!_busy) return const CommandResult.fail('no call');
            await hangup();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'intercomDismiss',
          description: 'Close the card left after a call ended or was missed.',
          quiet: true,
          handler: (_) async {
            if (_state == 'ended' || _state == 'missed') {
              _holdTimer?.cancel();
              _missedTimer?.cancel();
              _call = null;
              _setState('idle');
            }
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'intercomTalk',
          description: 'Push to talk: on while the button is held.',
          params: const {'on': 'true while held'},
          quiet: true,
          handler: (p) async {
            final c = _call;
            if (c == null || !_active) {
              return const CommandResult.fail('no call');
            }
            final on = p['on'] == true;
            if (c.localTalking == on) return const CommandResult.ok();
            c.localTalking = on;
            for (final l in _links.values) {
              l.sendText({'type': 'talk', 'on': on});
            }
            _changed();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'intercomMute',
          description: 'Hands free: mute or unmute this microphone.',
          params: const {'on': 'true to mute'},
          handler: (p) async {
            final c = _call;
            if (c == null || !_active) {
              return const CommandResult.fail('no call');
            }
            c.muted = p['on'] == true;
            for (final l in _links.values) {
              l.sendText({'type': 'talk', 'on': !c.muted});
            }
            _changed();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'intercomOpen',
          description: 'Open the Call a kiosk screen on the kiosk.',
          handler: (_) async {
            if (!enabled) return const CommandResult.fail('intercom is off');
            if (!available) {
              return const CommandResult.fail(
                'the intercom needs the remote admin and Find other kiosks',
              );
            }
            // The screen has nothing to say during a call: the call
            // screen is already up.
            if (_state != 'idle' && _state != 'missed') {
              return const CommandResult.fail('in a call');
            }
            // Same choreography as the app launcher: an ESPHome or
            // gesture open lands on a lit, frontmost kiosk.
            await commands.execute('screenOn', const {});
            await commands.execute('bringToFront', const {});
            await commands.execute('stopScreensaver', const {});
            rosterVisible.value = true;
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'intercomSetDnd',
          description:
              'Do not disturb on or off: flips the answer mode and back to '
              'what it was.',
          params: const {'on': 'true for Do not disturb'},
          handler: (p) async {
            final on = p['on'] == true;
            final mode = _settings.get(defs.intercomAnswerMode);
            if (on && mode != 'dnd') {
              _dndPrevious = mode;
              await _settings.set(defs.intercomAnswerMode, 'dnd');
            } else if (!on && mode == 'dnd') {
              await _settings.set(defs.intercomAnswerMode, _dndPrevious);
            }
            return CommandResult.ok({'dnd': dnd});
          },
        ),
      )
      ..register(
        Command(
          name: 'intercomSetKey',
          description: 'Paste a key from another kiosk, or make a new one.',
          params: const {
            'key': 'The key to use',
            'regenerate': 'true for a fresh random key',
          },
          secretParams: const {'key'},
          handler: (p) async {
            final String next;
            if (p['regenerate'] == true) {
              next = _newKey();
            } else {
              next = '${p['key'] ?? ''}'.trim();
              if (next.length < 16) {
                return const CommandResult.fail(
                  'a key is at least 16 characters',
                );
              }
            }
            await _settings.set(defs.intercomKey, next);
            _seenTokens.clear();
            unawaited(_probeAll(force: true));
            return CommandResult.ok({'key': next});
          },
        ),
      )
      ..register(
        Command(
          name: 'announcementTtsEngines',
          description:
              "Home Assistant's text to speech entities, for the engine "
              'picker: id and name each.',
          quiet: true,
          handler: (_) async {
            final engines = await _ttsEngines();
            return engines == null
                ? const CommandResult.fail('could not reach Home Assistant')
                : CommandResult.ok(engines);
          },
        ),
      )
      ..register(
        Command(
          name: 'ttsVoices',
          description:
              "A Home Assistant text to speech engine's languages and its "
              'voices for one of them, for the Language and Voice pickers.',
          params: const {
            'engine': 'A Home Assistant tts entity',
            'language':
                "The language to list voices for, empty for Home Assistant's",
          },
          quiet: true,
          handler: (p) async {
            final voices = await haTtsVoices(
              base: _haBase,
              token: _settings.get(defs.haToken),
              engine: '${p['engine'] ?? ''}',
              language: '${p['language'] ?? ''}',
              socket: haSocketFactory,
            );
            return voices == null
                ? const CommandResult.fail('could not reach Home Assistant')
                : CommandResult.ok(voices.toJson());
          },
        ),
      )
      ..register(
        Command(
          name: 'announce',
          description:
              'Play an announcement on this kiosk: a message Home Assistant '
              'speaks, or an audio URL, with a chime first.',
          params: const {
            'message': 'What to say, through Home Assistant text to speech',
            'url': 'An audio file to play instead of a message',
            'chime': 'Play a chime first, or use the setting when omitted',
            'chime_file':
                'A file name in the sounds folder, empty uses the setting',
            'tts_engine': 'A Home Assistant tts entity, empty uses the setting',
            'tts_language':
                'A language the engine speaks, empty uses the setting',
            'tts_voice': 'A voice the engine has, empty uses the setting',
            'audio_only': 'Play without showing the announcement modal',
            'volume':
                'A share of the master volume, 0..1, instead of the media '
                'volume; 0 or missing keeps the media volume',
            'repeat':
                'How many times to play it, 1 to 10; 0 or missing is once',
            'repeat_pause':
                'Seconds of silence between plays, up to 30; 0 or missing '
                'is 0.6',
          },
          handler: (p) async => _announce(p),
        ),
      )
      ..register(
        Command(
          name: 'announceStop',
          description:
              'Stop the announcement from Home Assistant playing on this '
              'kiosk, if any.',
          handler: (_) async => _announceStop(),
        ),
      )
      // A test hook, like injectWakeAudio: a 16 kHz mono PCM16 WAV sent
      // over the live call's socket in 80 ms chunks as if this kiosk's
      // microphone had heard it, whatever the talk mode says. How a
      // conversation is simulated when one person tests both ends.
      ..register(
        Command(
          name: 'intercomInjectAudio',
          description:
              'Send a WAV (16 kHz mono PCM16, base64) into the live call as '
              'this kiosk\'s voice, for testing.',
          params: const {'wavBase64': 'WAV file (16 kHz mono PCM16), base64'},
          quiet: true,
          handler: (p) async {
            if (!_active || _links.isEmpty) {
              return const CommandResult.fail('no live call');
            }
            final wav = p['wavBase64'];
            if (wav is! String || wav.isEmpty) {
              return const CommandResult.fail('wavBase64 required');
            }
            final pcm = _wavPcm16k(base64Decode(wav));
            if (pcm == null) {
              return const CommandResult.fail('not a 16 kHz mono PCM16 WAV');
            }
            await _streamClip(_call!, pcm);
            return CommandResult.ok({'ms': pcm.length ~/ 32});
          },
        ),
      )
      // The wire side, called by the remote server.
      ..register(
        Command(
          name: 'intercomIdentity',
          description:
              'What another kiosk learns about this one before a call: '
              'whether the intercom is on, which key it holds, Do not disturb.',
          quiet: true,
          handler: (_) async => CommandResult.ok({
            'id': _selfId,
            'name': _selfName,
            'version': _selfVersion,
            'enabled': enabled && available && _server != null,
            if (_server != null)
              'endpoint': {'port': _server!.port, 'tls': _listenerTls},
            'key': keyFingerprint,
            'dnd': dnd,
          }),
        ),
      )
      ..register(
        Command(
          name: 'intercomIncoming',
          description:
              'A call or broadcast from another kiosk landed here (the '
              'remote server relays it with the token and the real address).',
          quiet: true,
          handler: (p) async => _incoming(p),
        ),
      )
      ..register(
        Command(
          name: 'intercomSignal',
          description:
              'The other side of a call answered, declined, cancelled or '
              'hung up (relayed by the remote server).',
          quiet: true,
          handler: (p) async => _signal(p),
        ),
      )
      ..register(
        Command(
          name: 'intercomVerify',
          description:
              'Whether a token opens the audio socket of the call named.',
          quiet: true,
          handler: (p) async {
            final callId = '${p['call'] ?? ''}';
            final ok =
                _verifyToken('${p['token'] ?? ''}', callId) &&
                _call?.id == callId &&
                (_state == 'in_call' || _state == 'listening');
            return ok
                ? const CommandResult.ok()
                : const CommandResult.fail('refused');
          },
        ),
      )
      ..register(
        Command(
          name: 'intercomAttachSocket',
          description:
              'The audio socket of a call this kiosk was called on, opened '
              'by the caller (the remote server hands it over).',
          quiet: true,
          handler: (p) async {
            final channel = p['channel'];
            final callId = '${p['call'] ?? ''}';
            if (channel is! WebSocketChannel ||
                _call?.id != callId ||
                !(_state == 'in_call' || _state == 'listening')) {
              return const CommandResult.fail('no such call');
            }
            await _attach(channel, '${_call!.peer['id']}');
            return const CommandResult.ok();
          },
        ),
      );
  }

  // ── Placing a call ─────────────────────────────────────────────────

  Future<CommandResult> _place(IntercomKiosk k) async {
    if (!enabled) return const CommandResult.fail('intercom is off');
    if (!available) return const CommandResult.fail('needs the remote admin');
    if (_server == null) {
      return const CommandResult.fail('intercom listener unavailable');
    }
    if (_busy) {
      // Reply from a broadcast: leave it, then call.
      if (_state == 'listening') {
        await _finish('ended', notify: false);
      } else {
        return const CommandResult.fail('already in a call');
      }
    }
    await _probe(k);
    if (k.callTls != _encrypted) {
      _changed();
      return const CommandResult.fail(_encryptionMismatch);
    }
    _holdTimer?.cancel();
    _missedTimer?.cancel();
    final id = _callId();
    final c = IntercomCall(
      id: id,
      kind: 'call',
      outgoing: true,
      peer: _peerOf(k),
    );
    _call = c;
    _setState('calling');
    log.info(name, 'calling ${k.name}');
    final res = await _post(
      '${k.callUrl}/api/intercom/call',
      {'call': id, 'kind': 'call', 'from': _selfInfo()},
      token: _tokens.issueToken(
        ttl: const Duration(seconds: 60),
        claims: {'intercom': id, 'from': _selfId, 'n': _nonce()},
      ),
    );
    if (_call != c) return const CommandResult.ok();
    final data = _jsonOf(res);
    final st = res == null
        ? 'unreachable'
        : res.statusCode == 403
        ? 'key'
        : '${data?['status'] ?? 'failed'}';
    switch (st) {
      case 'ringing':
      case 'auto':
        // The callee answers or declines through intercomSignal; its own
        // ring timeout tells us a miss, with a margin here.
        _ringTimer = Timer(_ringFor + callerMargin, () => _finish('no_answer'));
        _changed();
        return const CommandResult.ok();
      default:
        await _finish(st);
        return CommandResult.fail(_reasonText(st));
    }
  }

  Future<CommandResult> _broadcast() async {
    if (!enabled) return const CommandResult.fail('intercom is off');
    if (!available) return const CommandResult.fail('needs the remote admin');
    if (_server == null) {
      return const CommandResult.fail('intercom listener unavailable');
    }
    if (_busy) return const CommandResult.fail('already in a call');
    await _readFleet();
    await _probeAll();
    final targets = _ready;
    if (targets.isEmpty) {
      return CommandResult.fail(
        _kiosks.values.any(
              (k) => k.status(keyFingerprint, encrypted: _encrypted) == 'tls',
            )
            ? _encryptionMismatch
            : 'no kiosk is ready',
      );
    }
    if (!await _openMic()) return CommandResult.fail(_micReason);
    return _startBroadcast(targets);
  }

  /// Fans an announcement out: one socket per kiosk that takes it. With
  /// [audio] (an announcement from Home Assistant) the clip plays into
  /// every socket, and here too when [playLocally], instead of the
  /// microphone, and the announcement ends when the clip does.
  Future<CommandResult> _startBroadcast(
    List<IntercomKiosk> targets, {
    Uint8List? audio,
    bool playLocally = false,
  }) async {
    _holdTimer?.cancel();
    _missedTimer?.cancel();
    final id = _callId();
    final c = IntercomCall(
      id: id,
      kind: 'broadcast',
      outgoing: true,
      peer: targets.isEmpty
          ? {'id': _selfId, 'name': _selfName, 'address': _selfAddress}
          : _peerOf(targets.first),
    )..automated = audio != null;
    for (final k in targets) {
      c.targets[k.id] = {'id': k.id, 'name': k.name, 'status': 'calling'};
    }
    _call = c;
    _setState('broadcasting');
    log.info(
      name,
      '${audio == null ? 'announcing' : 'playing an announcement'} to '
      '${targets.length} kiosks${playLocally ? ' and here' : ''}',
    );
    await Future.wait([for (final k in targets) _inviteBroadcast(c, k)]);
    if (_call != c) return const CommandResult.ok();
    if (_links.isEmpty && !playLocally) {
      await _finish('no_targets');
      return CommandResult.fail(_targetsSummary(c));
    }
    c.since = DateTime.now();
    if (audio != null) {
      if (playLocally) await _startPlayback();
      unawaited(
        _streamClip(c, audio, local: playLocally).then((_) {
          if (_call == c && _state == 'broadcasting') _finish('ended');
        }),
      );
    }
    _changed();
    return CommandResult.ok({
      'targets': c.targets.values.toList(),
      'self': playLocally,
      if (audio != null) 'ms': audio.length ~/ 32,
    });
  }

  static String _targetsSummary(IntercomCall c) => c.targets.values
      .map((t) => '${t['name']}: ${_targetText('${t['status']}')}')
      .join(', ');

  static String _targetText(String status) => switch (status) {
    'listening' => 'listening',
    'busy' => 'busy',
    'dnd' => 'do not disturb',
    'off' => 'intercom off',
    'refused' => 'announcements off',
    'key' => 'a different key',
    'tls' => _encryptionMismatch,
    'unreachable' => 'unreachable',
    'left' => 'done',
    _ => status,
  };

  /// Sends [pcm] (mono PCM16 at [rate], 16 kHz for anything that goes
  /// to a link) in 80 ms chunks to every link, and to this kiosk's own
  /// speaker when [local], on the clock a microphone would keep. Resolves
  /// when the clip ran out or the call ended.
  Future<void> _streamClip(
    IntercomCall c,
    Uint8List pcm, {
    bool local = false,
    int rate = IntercomAudio.callRate,
  }) {
    _injectTimer?.cancel();
    var offset = 0;
    final chunk = (rate * 2 * 80 ~/ 1000) & ~1;
    final done = Completer<void>();
    _injectTimer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (_call != c || !_active || offset >= pcm.length) {
        t.cancel();
        if (_injectTimer == t) _injectTimer = null;
        if (!done.isCompleted) done.complete();
        return;
      }
      final end = (offset + chunk).clamp(0, pcm.length);
      final piece = Uint8List.fromList(pcm.sublist(offset, end));
      offset = end;
      c.sent++;
      for (final l in _links.values) {
        l.sendBytes(piece);
      }
      if (local) audio.write(piece);
      _nearLevel = _level(piece);
      _publishLevel();
    });
    return done.future;
  }

  // ── Announcements from Home Assistant ──────────────────────────────

  /// Counts announce actions and stops, so one still fetching its audio
  /// knows a newer action has taken its place by the time it is ready.
  int _announceSeq = 0;

  /// A Home Assistant announcement playing here alone: a new one takes
  /// its place and announce_stop ends it. An intercom call or Announce to
  /// all is never cut short by either.
  bool get _announcing {
    final c = _call;
    return _busy &&
        c != null &&
        c.automated &&
        !c.outgoing &&
        c.peer['id'] == 'home-assistant';
  }

  /// The `announce_stop` action: ends the announcement playing here, and
  /// one still fetching its audio never starts. Nothing playing is fine.
  Future<CommandResult> _announceStop() async {
    _announceSeq++;
    if (!_announcing) return const CommandResult.ok({'stopped': false});
    log.info(name, 'announcement stopped by Home Assistant');
    await _finish('broadcast_over');
    return const CommandResult.ok({'stopped': true});
  }

  /// The `announce` action: a message for Home Assistant's text to speech
  /// or an audio URL, played on this kiosk alone with a chime first. Its
  /// own feature under ESPHome, Announcements; the intercom only lends
  /// it the playback sink and the card.
  Future<CommandResult> _announce(Map<String, Object?> p) async {
    if (!_settings.get(defs.announcementsEnabled)) {
      return const CommandResult.fail('announcements are off');
    }
    if (_busy && !_announcing) return const CommandResult.fail('in a call');
    final seq = ++_announceSeq;
    final message = '${p['message'] ?? ''}'.trim();
    final url = '${p['url'] ?? ''}'.trim();
    if (message.isEmpty && url.isEmpty) {
      return const CommandResult.fail('message or url required');
    }
    final Uint8List bytes;
    if (url.isNotEmpty) {
      final fetched = await _fetchAudio(url);
      if (fetched == null) return CommandResult.fail('could not fetch $url');
      bytes = fetched;
    } else {
      final spoken = await _ttsAudio(
        message,
        engine: '${p['tts_engine'] ?? ''}'.trim(),
        language: '${p['tts_language'] ?? ''}'.trim(),
        voice: '${p['tts_voice'] ?? ''}'.trim(),
      );
      if (spoken == null) {
        return const CommandResult.fail('Home Assistant could not speak it');
      }
      bytes = spoken;
    }
    // At the file's own rate: it plays here alone, never on a link, and
    // brought down to the intercom's 16 kHz it lost its top octave.
    final decoded = await audio.decode(bytes);
    if (decoded == null || decoded.pcm.isEmpty) {
      return const CommandResult.fail('could not decode the audio');
    }
    final rate = decoded.rate;
    // Repeat: the clip that many times with a short pause between, the
    // chime once before. Ten at most, the action's 0 means once.
    final asked = p['repeat'];
    final repeat = (asked is num ? asked.toInt() : int.tryParse('$asked') ?? 1)
        .clamp(1, 10);
    // The pause between plays, seconds; 0 or less means the 0.6 s default.
    final pauseRaw = p['repeat_pause'];
    final pauseAsked = pauseRaw is num
        ? pauseRaw.toDouble()
        : double.tryParse('$pauseRaw') ?? 0;
    final pauseMs = pauseAsked > 0
        ? (pauseAsked.clamp(0, 30) * 1000).round()
        : 600;
    final pcm = repeat == 1
        ? decoded.pcm
        : _repeated(decoded.pcm, repeat, pauseMs, rate);
    // The chime rides the same track as the words, ahead of them: one
    // route, one gain and one pass through the platform's processing, so
    // the two play equally loud however Android routes the words (the
    // communication route plays them louder than media on some devices).
    final chime = p['chime'] is bool
        ? p['chime'] as bool
        : _settings.get(defs.announcementsChime);
    final chimePcm = chime
        ? await _announcementChime('${p['chime_file'] ?? ''}'.trim(), rate)
        : null;
    final clip = chimePcm == null ? pcm : _joined(chimePcm, pcm, 200, rate);
    const superseded = CommandResult.fail(
      'replaced by a newer announcement or stopped',
    );
    if (seq != _announceSeq) return superseded;
    // The one playing gives way: the newest action is the one wanted,
    // like an alarm loop a dismiss automation replaces with its own words.
    if (_announcing) {
      log.info(name, 'a new announcement replaces the one playing');
      await _finish('broadcast_over', notify: false);
      if (seq != _announceSeq) return superseded;
    }
    if (_busy) return const CommandResult.fail('in a call');
    _holdTimer?.cancel();
    _missedTimer?.cancel();
    final c =
        IntercomCall(
            id: _callId(),
            kind: 'broadcast',
            outgoing: false,
            peer: const {'id': 'home-assistant', 'name': 'Home Assistant'},
          )
          ..automated = true
          ..audioOnly = p['audio_only'] == true
          ..message = message;
    _call = c;
    if (!c.audioOnly) await _comeForward();
    _setState('listening');
    // The media fader, unless the action names a volume of its own: a
    // share of the master, 0..1, on the same squared taper the faders
    // use. 0 or less (the action cannot leave a number out) means the
    // fader.
    final askedVolumeRaw = p['volume'];
    final askedVolume = askedVolumeRaw is num
        ? askedVolumeRaw.toDouble()
        : double.tryParse('$askedVolumeRaw') ?? 0;
    final share = askedVolume > 0
        ? askedVolume.clamp(0.0, 1.0)
        : _settings.get(defs.mediaVolume).toDouble().clamp(0, 100) / 100;
    await _startPlayback(volume: share * share, rate: rate);
    c.since = DateTime.now();
    final ms = pcm.length * 1000 ~/ (rate * 2);
    log.info(name, 'announcement from Home Assistant, $ms ms at $rate Hz');
    unawaited(
      _streamClip(c, clip, local: true, rate: rate).then((_) {
        if (_call == c && _state == 'listening') _finish('broadcast_over');
      }),
    );
    return CommandResult.ok({'ms': ms});
  }

  /// [clip] [times] over with [pauseMs] of silence between, for repeat.
  static Uint8List _repeated(Uint8List clip, int times, int pauseMs, int rate) {
    final gap = (rate * 2 * pauseMs ~/ 1000) & ~1;
    final out = Uint8List(clip.length * times + gap * (times - 1));
    var at = 0;
    for (var i = 0; i < times; i++) {
      out.setRange(at, at + clip.length, clip);
      at += clip.length + gap;
    }
    return out;
  }

  /// [first], [gapMs] of silence, then [second]: the chime and the words.
  static Uint8List _joined(
    Uint8List first,
    Uint8List second,
    int gapMs,
    int rate,
  ) {
    final gap = (rate * 2 * gapMs ~/ 1000) & ~1;
    final head = first.length & ~1;
    return Uint8List(head + gap + second.length)
      ..setRange(0, head, first)
      ..setRange(head + gap, head + gap + second.length, second);
  }

  /// The chime before an announcement as PCM at the words' [rate]:
  /// the picked sound file decoded like the words, else the built-in two
  /// note chime the native sink synthesizes. Null when neither could be
  /// had; the words play without it.
  Future<Uint8List?> _announcementChime(String asked, int rate) async {
    var path = asked.isEmpty ? null : await NotificationSounds.resolve(asked);
    if (asked.isNotEmpty && path == null) {
      log.warn(
        name,
        'sound "$asked" is not in ${NotificationSounds.displayPath}, '
        'falling back to the announcement sound',
      );
    }
    if (path == null) {
      final sound = _settings.get(defs.announcementsChimeFile).trim();
      path = sound.isEmpty ? null : await NotificationSounds.resolve(sound);
    }
    if (path != null) {
      Uint8List? decoded;
      try {
        decoded = (await audio.decode(
          await File(path).readAsBytes(),
          rate: rate,
        ))?.pcm;
      } catch (e) {
        log.debug(name, 'read $path: $e');
      }
      if (decoded != null && decoded.isNotEmpty) return decoded;
      log.warn(name, 'could not decode $path, playing the built-in chime');
    }
    return audio.chimePcm(rate: rate);
  }

  /// Home Assistant's `tts.*` entities as `{entity_id, name}`, or null
  /// when it cannot be reached.
  Future<List<Map<String, String>>?> _ttsEngines() async {
    final base = _haBase;
    final token = _settings.get(defs.haToken);
    if (base.isEmpty || token.isEmpty) return null;
    final states = await _get('$base/api/states', token: token, external: true);
    if (states == null || states.statusCode != 200) return null;
    Object? list;
    try {
      list = jsonDecode(states.body);
    } catch (_) {
      return null;
    }
    if (list is! List) return null;
    final out = <Map<String, String>>[];
    for (final e in list) {
      if (e is! Map) continue;
      final id = '${e['entity_id']}';
      if (!id.startsWith('tts.')) continue;
      final attrs = e['attributes'];
      final friendly = attrs is Map ? '${attrs['friendly_name'] ?? ''}' : '';
      out.add({'entity_id': id, 'name': friendly.isEmpty ? id : friendly});
    }
    out.sort(
      (a, b) => a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()),
    );
    return out;
  }

  /// Home Assistant speaking [message] as audio bytes. An action's engine,
  /// language and voice win over the settings. The settings' language and
  /// voice only go with the settings' engine: another engine's voices are
  /// not these. A language or voice Home Assistant fails with is tried once
  /// more without them, so a stale pick costs the voice, not the words.
  Future<Uint8List?> _ttsAudio(
    String message, {
    String engine = '',
    String language = '',
    String voice = '',
  }) async {
    final picked = _settings.get(defs.announcementsTtsEngine).trim();
    if (picked.isNotEmpty && (engine.isEmpty || engine == picked)) {
      if (language.isEmpty) {
        language = _settings.get(defs.announcementsTtsLanguage).trim();
      }
      if (voice.isEmpty) {
        voice = _settings.get(defs.announcementsTtsVoice).trim();
      }
    }
    final url = await _ttsUrl(
      message,
      engine: engine,
      language: language,
      voice: voice,
    );
    final bytes = url == null ? null : await _fetchAudio(url);
    if (bytes != null || (language.isEmpty && voice.isEmpty)) return bytes;
    log.warn(
      name,
      'Home Assistant could not speak with language "$language" and voice '
      '"$voice"; trying the engine default',
    );
    final plain = await _ttsUrl(message, engine: engine);
    return plain == null ? null : _fetchAudio(plain);
  }

  /// Asks Home Assistant to speak [message] and answers the audio URL.
  Future<String?> _ttsUrl(
    String message, {
    String engine = '',
    String language = '',
    String voice = '',
  }) async {
    final base = _haBase;
    final token = _settings.get(defs.haToken);
    if (base.isEmpty || token.isEmpty) return null;
    if (engine.isEmpty) {
      engine = _settings.get(defs.announcementsTtsEngine).trim();
    }
    if (engine.isEmpty) {
      final engines = await _ttsEngines();
      engine = engines == null || engines.isEmpty
          ? ''
          : engines.first['entity_id']!;
      if (engine.isEmpty) {
        log.warn(name, 'Home Assistant has no text to speech entity');
        return null;
      }
    }
    final res = await _post(
      '$base/api/tts_get_url',
      ttsRequestBody(
        engine: engine,
        message: message,
        language: language,
        voice: voice,
      ),
      token: token,
      external: true,
    );
    final data = _jsonOf(res);
    final url = data?['url'];
    if (res == null || res.statusCode != 200 || url is! String) {
      log.warn(
        name,
        'tts_get_url with $engine: ${res?.statusCode} ${res?.body}',
      );
      return null;
    }
    return url;
  }

  String get _haBase =>
      _settings.get(defs.haUrl).trim().replaceAll(RegExp(r'/+$'), '');

  Future<Uint8List?> _fetchAudio(String url) async {
    final base = _haBase;
    final onHa = base.isNotEmpty && url.startsWith(base);
    final client = clientFactory();
    try {
      final res = await client
          .get(
            Uri.parse(url),
            headers: {
              if (onHa)
                'Authorization': 'Bearer ${_settings.get(defs.haToken)}',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      return res.bodyBytes;
    } catch (e) {
      log.debug(name, 'GET $url: $e');
      return null;
    } finally {
      client.close();
    }
  }

  Future<void> _inviteBroadcast(IntercomCall c, IntercomKiosk k) async {
    if (k.callTls != _encrypted) {
      c.targets[k.id]?['status'] = 'tls';
      return;
    }
    final res = await _post(
      '${k.callUrl}/api/intercom/call',
      {'call': c.id, 'kind': 'broadcast', 'from': _selfInfo()},
      token: _tokens.issueToken(
        ttl: const Duration(seconds: 60),
        claims: {'intercom': c.id, 'from': _selfId, 'n': _nonce()},
      ),
    );
    if (_call != c) return;
    final data = _jsonOf(res);
    final st = res == null
        ? 'unreachable'
        : res.statusCode == 403
        ? 'key'
        : '${data?['status'] ?? 'failed'}';
    c.targets[k.id]?['status'] = st;
    if (st != 'listening') return;
    final ok = await _connect(k, c.id);
    if (_call != c) return;
    if (!ok && c.targets[k.id]?['status'] != 'tls') {
      c.targets[k.id]?['status'] = 'unreachable';
    }
  }

  /// Opens the audio socket to a kiosk that answered.
  Future<bool> _connect(IntercomKiosk k, String callId) async {
    if (k.callTls != _encrypted) {
      final c = _call;
      if (c?.id == callId) {
        if (c!.kind == 'broadcast') {
          c.targets[k.id]?['status'] = 'tls';
        } else {
          await _finish('tls');
        }
      }
      return false;
    }
    final token = _tokens.issueToken(
      ttl: const Duration(seconds: 60),
      claims: {'intercom': callId, 'from': _selfId, 'n': _nonce()},
    );
    final encrypted = k.callTls;
    final uri = Uri(
      scheme: encrypted ? 'wss' : 'ws',
      host: k.address,
      port: k.callPort,
      path: '/api/intercom/audio/$callId',
      queryParameters: {'token': token},
    );
    try {
      final channel = socketFactory(uri);
      await channel.ready.timeout(requestTimeout);
      if (_call?.id != callId || !_active || encrypted != _encrypted) {
        await channel.sink.close();
        return false;
      }
      await _attach(channel, k.id);
      return true;
    } catch (e) {
      log.warn(name, 'audio socket to ${k.name}: $e');
      return false;
    }
  }

  // ── A call coming in ───────────────────────────────────────────────

  Future<CommandResult> _incoming(Map<String, Object?> p) async {
    final callId = '${p['call'] ?? ''}';
    final kind = '${p['kind'] ?? 'call'}';
    final from = (p['from'] as Map?)?.cast<String, Object?>() ?? const {};
    if (callId.isEmpty || from['id'] == null) {
      return const CommandResult.fail('call and from required');
    }
    if (!enabled || !available) return CommandResult.ok({'status': 'off'});
    if (!_verifyToken('${p['token'] ?? ''}', callId)) {
      return CommandResult.ok({'status': 'key', 'code': 403});
    }
    if ((from['tls'] == true) != _encrypted) {
      return CommandResult.ok({'status': 'tls', 'code': 409});
    }
    // Accept announcements off refuses Announce to all. Lockdown Mode
    // and Do not disturb refuse everything.
    if (kind == 'broadcast' &&
        !_settings.get(defs.intercomAcceptAnnouncements)) {
      return CommandResult.ok({'status': 'refused'});
    }
    if (dnd) return CommandResult.ok({'status': 'dnd'});
    if (_busy) return CommandResult.ok({'status': 'busy'});
    final peer = {
      'id': '${from['id']}',
      'name': '${from['name'] ?? ''}',
      // Where it really came from, whatever the body says.
      'address': '${p['address'] ?? from['address'] ?? ''}',
      'port': (from['port'] as num?)?.toInt() ?? 2324,
      'version': '${from['version'] ?? ''}',
      if (from['tls'] == true) 'tls': true,
    };
    _holdTimer?.cancel();
    _missedTimer?.cancel();
    final c = IntercomCall(
      id: callId,
      kind: kind == 'broadcast' ? 'broadcast' : 'call',
      outgoing: false,
      peer: peer,
    );
    _call = c;
    await _comeForward();
    if (c.kind == 'broadcast') {
      _setState('listening');
      log.info(name, '${peer['name']} is announcing');
      unawaited(_ring(short: true));
      unawaited(_startPlayback());
      _armConnectTimeout();
      return CommandResult.ok({'status': 'listening'});
    }
    final auto = _settings.get(defs.intercomAnswerMode) == 'auto';
    _setState('ringing');
    log.info(name, '${peer['name']} is calling');
    unawaited(_ring(short: auto));
    if (auto) {
      c.autoAnswerAt = DateTime.now().add(autoAnswerDelay);
      _autoTimer = Timer(autoAnswerDelay, () {
        if (_call == c && _state == 'ringing') unawaited(_answer());
      });
    } else {
      _chimeTimer = Timer.periodic(ringCadence, (_) => _ring());
      _ringTimer = Timer(_ringFor, () async {
        if (_call != c || _state != 'ringing') return;
        await _signalPeer('missed');
        await _finish('missed');
      });
    }
    _changed();
    return CommandResult.ok({'status': auto ? 'auto' : 'ringing'});
  }

  /// A call or an announcement coming in wakes a dark screen and brings
  /// the kiosk in front of whatever app covers it, the way a wake word
  /// does: bringToFront wakes the display first, then switches tasks,
  /// which needs the Display over other apps grant and is logged without
  /// it. screenOn is the fallback where the command is missing (tests).
  Future<void> _comeForward() async {
    final r = await commands.execute('bringToFront', const {});
    if (!r.ok) await commands.execute('screenOn', const {});
  }

  Future<CommandResult> _answer() async {
    final c = _call;
    if (c == null || _state != 'ringing') {
      return const CommandResult.fail('nothing is ringing');
    }
    _cancelTimers();
    await _stopRing();
    if (!await _openMic()) {
      // Answer anyway: listening is still worth it, the card says why
      // nothing goes out.
      log.warn(name, '$_micReason, the call is listen only');
    }
    _setState('in_call');
    await _startPlayback();
    _armConnectTimeout();
    final ok = await _signalPeer('answer');
    if (!ok && _call == c) {
      if (c.reason == 'tls') {
        return const CommandResult.fail(_encryptionMismatch);
      }
      await _finish('unreachable');
      return const CommandResult.fail('the caller did not answer');
    }
    _changed();
    return const CommandResult.ok();
  }

  Future<CommandResult> _decline() async {
    if (_state != 'ringing') {
      return const CommandResult.fail('nothing is ringing');
    }
    await _signalPeer('decline');
    await _finish('declined');
    return const CommandResult.ok();
  }

  /// Nothing came over the socket in time: the caller went away.
  void _armConnectTimeout() {
    _connectTimer?.cancel();
    _connectTimer = Timer(const Duration(seconds: 10), () {
      if (_links.isEmpty && (_state == 'in_call' || _state == 'listening')) {
        unawaited(_finish('failed'));
      }
    });
  }

  Future<CommandResult> _signal(Map<String, Object?> p) async {
    final callId = '${p['call'] ?? ''}';
    final action = '${p['action'] ?? ''}';
    if (!_verifyToken('${p['token'] ?? ''}', callId)) {
      return const CommandResult.fail('refused');
    }
    final c = _call;
    if (c == null || c.id != callId) {
      return const CommandResult.fail('no such call');
    }
    switch (action) {
      case 'answer':
        if (_state != 'calling') return const CommandResult.fail('not calling');
        _ringTimer?.cancel();
        final k = _kioskById('${c.peer['id']}');
        if (k == null) {
          await _finish('failed');
          return const CommandResult.fail('unknown kiosk');
        }
        if (!await _openMic()) {
          log.warn(name, '$_micReason, the call is listen only');
        }
        _setState('in_call');
        await _startPlayback();
        unawaited(() async {
          final ok = await _connect(k, c.id);
          if (!ok && _call == c && c.reason != 'tls') await _finish('failed');
        }());
        return const CommandResult.ok();
      case 'decline':
        await _finish('declined');
        return const CommandResult.ok();
      case 'missed':
        await _finish('no_answer');
        return const CommandResult.ok();
      case 'cancel':
      case 'hangup':
        await _finish(_state == 'ringing' ? 'cancelled' : 'ended');
        return const CommandResult.ok();
    }
    return const CommandResult.fail('unknown action');
  }

  /// Tells the other side of the current call something. True when it
  /// took it.
  Future<bool> _signalPeer(String action) async {
    final c = _call;
    if (c == null) return false;
    final url = Uri(
      scheme: c.peer['tls'] == true ? 'https' : 'http',
      host: '${c.peer['address']}',
      port: (c.peer['port'] as num).toInt(),
      path: '/api/intercom/call/${c.id}',
    ).toString();
    final res = await _post(
      url,
      {'action': action},
      token: _tokens.issueToken(
        ttl: const Duration(seconds: 60),
        claims: {'intercom': c.id, 'from': _selfId, 'n': _nonce()},
      ),
    );
    if (_jsonOf(res)?['status'] == 'tls' && _call == c) {
      await _finish('tls');
    }
    return res != null && res.statusCode == 200;
  }

  // ── The audio socket ───────────────────────────────────────────────

  Future<void> _attach(WebSocketChannel channel, String peerId) async {
    final c = _call;
    if (c == null) {
      try {
        await channel.sink.close();
      } catch (_) {}
      return;
    }
    final old = _links.remove(peerId);
    await old?.close();
    final link = _Link(peerId, channel);
    _links[peerId] = link;
    _connectTimer?.cancel();
    link.sub = channel.stream.listen(
      (raw) => _onFrame(link, raw),
      onDone: () => _onLinkClosed(link),
      onError: (Object e) {
        log.debug(name, 'audio socket: $e');
        _onLinkClosed(link);
      },
    );
    c.since ??= DateTime.now();
    if (c.kind == 'broadcast' && c.outgoing) {
      c.targets[peerId]?['status'] = 'listening';
    }
    // The other side learns our talk state at once: hands free with the
    // microphone open reads as talking.
    link.sendText({'type': 'talk', 'on': _sending});
    if (!c.outgoing || c.kind == 'call') {
      log.info(name, 'voice connected with ${c.peer['name']}');
    }
    _changed();
  }

  void _onFrame(_Link link, Object? raw) {
    final c = _call;
    if (c == null) return;
    if (raw is String) {
      Map<String, Object?>? msg;
      try {
        final d = jsonDecode(raw);
        if (d is Map) msg = d.cast<String, Object?>();
      } catch (_) {}
      if (msg == null) return;
      switch ('${msg['type']}') {
        case 'talk':
          c.farTalking = msg['on'] == true;
          _changed();
        case 'end':
          unawaited(_peerEnded(link));
      }
      return;
    }
    if (raw is List<int>) {
      final bytes = raw is Uint8List ? raw : Uint8List.fromList(raw);
      c.received++;
      audio.write(bytes);
      _farLevel = _level(bytes);
      _publishLevel();
    }
  }

  Future<void> _peerEnded(_Link link) async {
    final c = _call;
    if (c == null) return;
    if (c.kind == 'broadcast' && c.outgoing) {
      c.targets[link.peerId]?['status'] = 'left';
      await link.close();
      _links.remove(link.peerId);
      if (_links.isEmpty) await _finish('ended');
      _changed();
      return;
    }
    await _finish(_state == 'listening' ? 'broadcast_over' : 'ended');
  }

  void _onLinkClosed(_Link link) {
    if (_links[link.peerId] != link) return;
    _links.remove(link.peerId);
    final c = _call;
    if (c == null || !_active) return;
    if (c.kind == 'broadcast' && c.outgoing) {
      c.targets[link.peerId]?['status'] = 'left';
      if (_links.isEmpty) unawaited(_finish('ended'));
      _changed();
      return;
    }
    unawaited(_finish(_state == 'listening' ? 'broadcast_over' : 'ended'));
  }

  // ── Microphone and playback ────────────────────────────────────────

  /// Whether chunks go out right now.
  bool get _sending {
    final c = _call;
    if (c == null || !_active || _mic == null) return false;
    if (c.kind == 'broadcast' && !c.outgoing) return false;
    if (c.automated) return false;
    if (talkMode == 'ptt') return c.localTalking;
    return !c.muted;
  }

  /// Why nothing goes out, for the log and the card.
  String get _micReason =>
      _micBusy ? 'the page holds the microphone' : 'microphone not granted';

  Future<bool> _openMic() async {
    if (_mic != null) return true;
    final c = _call;
    if (micHub.browserCapturing.value) {
      // The page holds the microphone: Voice Satellite streaming to Home
      // Assistant for its wake word, or a browser engine. The call comes
      // first, so ask it to let go and wait. A page that does not know
      // the event keeps it and the call is listen only.
      _holdPageMic(true);
      final freed = await _waitPageMic();
      // The call ended while the page was letting go.
      if (c != null && !_busy) return false;
      if (!freed) {
        _micBusy = true;
        if (_call == null) _holdPageMic(false);
        _changed();
        return false;
      }
    }
    _micBusy = false;
    _micGranted = await micPermission();
    if (!_micGranted) {
      if (_call == null) _holdPageMic(false);
      _changed();
      return false;
    }
    _mic = micHub.stream().listen(
      (chunk) {
        if (!_sending) return;
        _call?.sent++;
        for (final l in _links.values) {
          l.sendBytes(chunk);
        }
        _nearLevel = _level(chunk);
        _publishLevel();
      },
      onError: (Object e) {
        log.warn(name, 'microphone: $e');
      },
    );
    return true;
  }

  Future<void> _closeMic() async {
    final sub = _mic;
    _mic = null;
    await sub?.cancel();
  }

  /// Tells the page the intercom wants the microphone it holds, or that
  /// the call is over and the page may take it back. Once per change.
  void _holdPageMic(bool hold) {
    if (_pageMicHeld == hold) return;
    _pageMicHeld = hold;
    bus.publish(IntercomMicHold(hold: hold));
  }

  /// True once the page has let go of the microphone, false when it has
  /// not within [pageMicWait].
  Future<bool> _waitPageMic() async {
    if (!micHub.browserCapturing.value) return true;
    final freed = Completer<bool>();
    void onChange() {
      if (!micHub.browserCapturing.value && !freed.isCompleted) {
        freed.complete(true);
      }
    }

    micHub.browserCapturing.addListener(onChange);
    final timeout = Timer(pageMicWait, () {
      if (!freed.isCompleted) freed.complete(false);
    });
    try {
      return await freed.future;
    } finally {
      timeout.cancel();
      micHub.browserCapturing.removeListener(onChange);
    }
  }

  bool get _handsFreeCall => _call?.kind == 'call' && talkMode == 'handsfree';

  Future<void> _startPlayback({
    double? volume,
    int rate = IntercomAudio.callRate,
  }) async {
    if (audio.open && audio.rate == rate) return;
    final ok = await audio.start(
      volume: volume ?? _playbackGain(),
      handsFree: _handsFreeCall,
      rate: rate,
    );
    if (!ok) log.warn(name, 'playback could not open');
  }

  /// The intercom fader on the app's squared taper.
  double _playbackGain() {
    final pct = _settings.get(defs.intercomVolume).toDouble().clamp(0, 100);
    final f = pct / 100;
    return f * f;
  }

  /// The ring: the picked sound file through the chime player, else the
  /// built-in telephone ring the native sink synthesizes (no asset). A
  /// short ring is one burst: Answer automatically and a broadcast, which
  /// cut a picked sound off after [shortRingSound]. A picked sound longer
  /// than the cadence is left to finish before the next ring starts it
  /// again.
  Future<void> _ring({bool short = false}) async {
    final generation = _ringGeneration;
    final volume = _settings
        .get(defs.notificationsVolume)
        .toDouble()
        .clamp(0.0, 1.0);
    final sound = _settings.get(defs.intercomRingSound).trim();
    final path = sound.isEmpty ? null : await NotificationSounds.resolve(sound);
    if (generation != _ringGeneration) return;
    if (path != null) {
      if (_ringSoundPlaying) return;
      _ringSoundPlaying = true;
      final r = await commands.execute('playChime', {
        'source': path,
        'volume': volume,
        'id': _ringSoundId,
      });
      if (!r.ok) {
        _ringSoundPlaying = false;
      } else if (short) {
        _ringSoundCut = Timer(shortRingSound, () {
          if (generation == _ringGeneration) unawaited(_stopRing());
        });
      }
      return;
    }
    final err = await audio.ring(volume: volume, short: short);
    if (err != null) {
      log.warn(name, 'ring failed: $err');
    } else {
      log.debug(name, 'ring${short ? ' (short)' : ''} at $volume');
    }
  }

  /// Silences the ring, whichever player has it.
  Future<void> _stopRing() async {
    _ringGeneration++;
    _ringSoundCut?.cancel();
    _ringSoundCut = null;
    await audio.stopRing();
    if (!_ringSoundPlaying) return;
    _ringSoundPlaying = false;
    await commands.execute('stopSound', const {'id': _ringSoundId});
  }

  static double _level(Uint8List pcm) {
    if (pcm.length < 4) return 0;
    final data = ByteData.sublistView(pcm);
    var sum = 0.0;
    final n = pcm.length ~/ 2;
    for (var i = 0; i < n; i++) {
      final s = data.getInt16(i * 2, Endian.little).toDouble();
      sum += s * s;
    }
    final rms = sqrt(sum / n);
    return (rms / 4000).clamp(0.0, 1.0);
  }

  void _publishLevel() {
    final now = DateTime.now();
    if (now.difference(_lastLevel) < const Duration(milliseconds: 66)) return;
    _lastLevel = now;
    bus.publish(IntercomLevel(near: _nearLevel, far: _farLevel));
  }

  // ── Ending ─────────────────────────────────────────────────────────

  /// Ends whatever is going on: cancels a call being placed, declines
  /// nothing (that is intercomDecline), hangs up a live call or closes a
  /// broadcast.
  Future<void> hangup({String reason = 'ended'}) async {
    final c = _call;
    if (c == null) return;
    if (_links.isNotEmpty) {
      for (final l in _links.values) {
        l.sendText(const {'type': 'end'});
      }
    } else if (_state == 'calling' || _state == 'in_call') {
      await _signalPeer(_state == 'calling' ? 'cancel' : 'hangup');
    }
    await _finish(_state == 'calling' ? 'cancelled' : reason);
  }

  /// The call a [_finish] is tearing down right now. A peer hanging up
  /// sends its end and then closes the link, and that close lands while
  /// the first finish is still awaiting. A second finish would find the
  /// call already ended, read that as not busy and clear it to idle,
  /// skipping the call length screen (discussion #729).
  IntercomCall? _finishing;

  Future<void> _finish(String reason, {bool notify = true}) async {
    final c = _call;
    if (c != null && identical(_finishing, c)) return;
    _finishing = c;
    try {
      await _finishCall(c, reason, notify: notify);
    } finally {
      if (identical(_finishing, c)) _finishing = null;
    }
  }

  Future<void> _finishCall(
    IntercomCall? c,
    String reason, {
    required bool notify,
  }) async {
    _cancelTimers();
    _connectTimer?.cancel();
    _injectTimer?.cancel();
    _injectTimer = null;
    await _stopRing();
    for (final l in _links.values.toList()) {
      await l.close();
    }
    _links.clear();
    await _closeMic();
    _holdPageMic(false);
    _micBusy = false;
    await audio.stop();
    if (c == null) {
      if (_state != 'idle' && _state != 'ended' && _state != 'missed') {
        _setState('idle');
      }
      return;
    }
    c.endedAt = DateTime.now();
    c.reason = reason;
    c.farTalking = false;
    c.localTalking = false;
    final wasBusy = _busy;
    log.info(name, 'call with ${c.peer['name']}: ${_reasonText(reason)}');
    if (reason == 'missed') {
      _setState('missed', notify: notify);
      _missedTimer?.cancel();
      _missedTimer = Timer(missedHold, () {
        if (_state == 'missed') {
          _call = null;
          _setState('idle');
        }
      });
      return;
    }
    if (!wasBusy) {
      _call = null;
      _setState('idle', notify: notify);
      return;
    }
    _setState('ended', notify: notify);
    _holdTimer?.cancel();
    _holdTimer = Timer(
      reason == 'broadcast_over' ? broadcastHold : endedHold,
      () {
        if (_state == 'ended' && _call == c) {
          _call = null;
          _setState('idle');
        }
      },
    );
  }

  void _cancelTimers() {
    _ringTimer?.cancel();
    _chimeTimer?.cancel();
    _autoTimer?.cancel();
    _ringTimer = null;
    _chimeTimer = null;
    _autoTimer = null;
  }

  void _setState(String next, {bool notify = true}) {
    if (_state == next) {
      if (notify) _changed();
      return;
    }
    _state = next;
    _syncCallLimit();
    _syncHangupKey();
    // The call screen takes over from the roster.
    if (next != 'idle' && next != 'missed') rosterVisible.value = false;
    // The card's last words hold nothing: the screensaver and the wake
    // word come back the moment the voice stops.
    final holds = next != 'idle' && next != 'missed' && next != 'ended';
    if (holds != _interactionHeld) {
      _interactionHeld = holds;
      bus.publish(
        VoiceInteractionChanged(
          active: holds,
          reason: 'intercom',
          source: InteractionSource.command,
        ),
      );
    }
    _syncScreenShown();
    if (notify) _changed();
  }

  /// The states the hang up button ends: a call being placed, a live call
  /// and either end of a broadcast. A ringing call arms it only when Hang
  /// up button while ringing picks Accept or Decline.
  static const _hangupStates = {
    'calling',
    'in_call',
    'broadcasting',
    'listening',
  };

  void _syncHangupKey() {
    final armed =
        _hangupStates.contains(_state) ||
        (_state == 'ringing' &&
            _settings.get(defs.intercomHangupKeyRinging) != 'ignore');
    final code = armed
        ? defs.intercomHangupKeyCodes[_settings.get(defs.intercomHangupKey)] ??
              0
        : 0;
    if (code == _hangupKeyArmed) return;
    _hangupKeyArmed = code;
    bus.publish(IntercomHangupKeyArmed(code));
  }

  /// Starts the Maximum call duration clock when a call or a broadcast
  /// goes live and stops it when that ends.
  void _syncCallLimit() {
    if (!_active) {
      _limitTimer?.cancel();
      _limitTimer = null;
      return;
    }
    if (_limitTimer != null) return;
    final limit = _maxCall;
    if (limit == null) return;
    _limitTimer = Timer(limit, () {
      _limitTimer = null;
      if (!_active) return;
      log.info(name, 'the call reached its maximum duration');
      unawaited(hangup(reason: 'time_limit'));
    });
  }

  static String _reasonText(String reason) => switch (reason) {
    'ended' => 'ended',
    'declined' => 'declined',
    'cancelled' => 'cancelled',
    'busy' => 'busy',
    'dnd' => 'do not disturb',
    'off' => 'its intercom is off',
    'key' => 'a different intercom key',
    'tls' => _encryptionMismatch,
    'no_answer' => 'no answer',
    'missed' => 'missed',
    'unreachable' => 'did not answer',
    'failed' => 'the voice link failed',
    'mic_busy' => 'the page took the microphone',
    'no_targets' => 'nobody could take it',
    'broadcast_over' => 'the broadcast ended',
    'time_limit' => 'maximum duration reached',
    _ => reason,
  };

  // ── Trust ──────────────────────────────────────────────────────────

  bool _verifyToken(String token, String callId) {
    if (key.isEmpty || token.isEmpty) return false;
    final claims = _tokens.claimsOf(token);
    if (claims == null) return false;
    if ('${claims['intercom']}' != callId) return false;
    final exp = claims['exp'];
    if (exp is! int) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    _seenTokens.removeWhere((_, e) => e < now);
    if (_seenTokens.containsKey(token)) return false;
    _seenTokens[token] = exp;
    return true;
  }

  String _nonce() => random.nextInt(1 << 30).toRadixString(36);

  String _callId() =>
      '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}'
      '-${(++_nextId).toRadixString(36)}-${_nonce()}';

  Map<String, Object?> _selfInfo() => {
    'id': _selfId,
    'name': _selfName,
    'address': _selfAddress,
    'port': _server?.port ?? _selfPort,
    'version': _selfVersion,
    if (_server != null ? _listenerTls : _settings.get(defs.remoteTls))
      'tls': true,
  };

  Map<String, Object?> _peerOf(IntercomKiosk k) => {
    'id': k.id,
    'name': k.name,
    'address': k.address,
    'port': k.callPort,
    'version': k.version,
    if (k.callTls) 'tls': true,
  };

  // ── HTTP ───────────────────────────────────────────────────────────

  Future<http.Response?> _get(
    String url, {
    Duration? timeout,
    String? token,
    bool external = false,
  }) async {
    final client = external ? clientFactory() : _peerClient();
    try {
      return await client
          .get(
            Uri.parse(url),
            headers: {if (token != null) 'Authorization': 'Bearer $token'},
          )
          .timeout(timeout ?? requestTimeout);
    } catch (e) {
      log.debug(name, 'GET $url: $e');
      return null;
    } finally {
      client.close();
    }
  }

  Future<http.Response?> _post(
    String url,
    Map<String, Object?> body, {
    required String token,
    bool external = false,
  }) async {
    // Discovery can use HTTP, but credentials and call data must not downgrade.
    if (!external && _encrypted && Uri.parse(url).scheme != 'https') {
      return http.Response(jsonEncode({'status': 'tls'}), 409);
    }
    final client = external ? clientFactory() : _peerClient();
    try {
      final request = http.Request('POST', Uri.parse(url))
        ..followRedirects = external
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        })
        ..body = jsonEncode(body);
      return await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(requestTimeout);
    } catch (e) {
      log.debug(name, 'POST $url: $e');
      return null;
    } finally {
      client.close();
    }
  }

  static Map<String, Object?>? _jsonOf(http.Response? res) {
    if (res == null) return null;
    try {
      final decoded = jsonDecode(res.body);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } catch (_) {
      return null;
    }
  }
}

/// PCM16 payload of a 16 kHz mono WAV, or null when it is anything else.
/// The wake word harness has the same reader.
Uint8List? _wavPcm16k(Uint8List wav) {
  if (wav.length < 12) return null;
  final bd = ByteData.sublistView(wav);
  if (String.fromCharCodes(wav.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(wav.sublist(8, 12)) != 'WAVE') {
    return null;
  }
  var off = 12;
  var ok = false;
  while (off + 8 <= wav.length) {
    final id = String.fromCharCodes(wav.sublist(off, off + 4));
    final size = bd.getUint32(off + 4, Endian.little);
    final body = off + 8;
    if (id == 'fmt ' && body + 16 <= wav.length) {
      final format = bd.getUint16(body, Endian.little);
      final channels = bd.getUint16(body + 2, Endian.little);
      final rate = bd.getUint32(body + 4, Endian.little);
      final bits = bd.getUint16(body + 14, Endian.little);
      ok = format == 1 && channels == 1 && rate == 16000 && bits == 16;
    } else if (id == 'data') {
      if (!ok) return null;
      final end = body + size > wav.length ? wav.length : body + size;
      return Uint8List.sublistView(wav, body, end & ~1);
    }
    off = body + size + (size & 1);
  }
  return null;
}

/// What the intercom script tells about each kiosk: the name its user gave
/// its ESPHome device in Home Assistant and the device's area, keyed by the
/// device name, which is the kiosk's name.
Map<String, ({String alias, String area})> voiceRooms(Object? raw) {
  final out = <String, ({String alias, String area})>{};
  if (raw is! List) return out;
  for (final r in raw) {
    if (r is! Map) continue;
    final n = normalizeKioskName('${r['name'] ?? ''}');
    if (n.isEmpty) continue;
    out[n] = (
      alias: '${r['alias'] ?? ''}'.trim(),
      area: '${r['area'] ?? ''}'.trim(),
    );
  }
  return out;
}

/// The kiosks a spoken name means, by the kiosk's name, the name given to
/// its device in Home Assistant or its area, so "the master bedroom
/// intercom" finds the kiosk in the Master Bedroom. In order: a name said
/// exactly (or the address), then every kiosk whose name holds the words
/// said or is held in them, then the kiosks sharing the most words with
/// it. Several matches mean the request has to say which.
List<T> matchKiosks<T>(
  String target,
  Iterable<T> kiosks, {
  required String Function(T) name,
  String Function(T)? address,
  Map<String, ({String alias, String area})> rooms = const {},
}) {
  final asked = normalizeKioskName(target);
  if (asked.isEmpty) return const [];
  List<String> namesOf(T k) {
    final room = rooms[normalizeKioskName(name(k))];
    return [
      name(k),
      if (room != null && room.alias.isNotEmpty) room.alias,
      if (room != null && room.area.isNotEmpty) room.area,
    ];
  }

  final exact = [
    for (final k in kiosks)
      if (address?.call(k) == target.trim() ||
          namesOf(k).any((n) => normalizeKioskName(n) == asked))
        k,
  ];
  if (exact.isNotEmpty) return exact;
  final said = _words(target);
  if (said.isEmpty) return const [];
  final within = [
    for (final k in kiosks)
      if (namesOf(k).any((n) {
        final words = _words(n);
        return words.isNotEmpty && (_holds(said, words) || _holds(words, said));
      }))
        k,
  ];
  if (within.isNotEmpty) return within;
  final heard = said.where((w) => !_filler.contains(w)).toSet();
  var best = 0;
  var out = <T>[];
  for (final k in kiosks) {
    final shared = {
      for (final n in namesOf(k)) ..._words(n),
    }.intersection(heard).length;
    if (shared == 0 || shared < best) continue;
    if (shared > best) {
      best = shared;
      out = [];
    }
    out.add(k);
  }
  return out;
}

List<String> _words(String s) => [
  for (final w in s.toLowerCase().split(
    RegExp(r'[^\p{L}\p{N}]+', unicode: true),
  ))
    if (w.isNotEmpty) w,
];

/// [words] holds [part] as a run of whole words: "the master bedroom
/// intercom" holds "master bedroom", "garden" never holds "den".
bool _holds(List<String> words, List<String> part) {
  for (var i = 0; i + part.length <= words.length; i++) {
    var all = true;
    for (var j = 0; j < part.length && all; j++) {
      all = words[i + j] == part[j];
    }
    if (all) return true;
  }
  return false;
}

/// Words that say nothing about which kiosk, left out of the word count.
const _filler = {'the', 'a', 'an', 'my', 'our', 'kiosk', 'tablet', 'intercom'};
