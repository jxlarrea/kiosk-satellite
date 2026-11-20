import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../l10n/generated/ui_strings.dart';
import 'voice_session.dart' show VoiceMicPort;

/// Where an enrollment is: getting ready, recording, saving what was
/// recorded, saved, or failed. [refused] never started (the kiosk was busy
/// or its microphone was not available).
enum EnrollPhase { starting, recording, saving, saved, failed, refused }

/// One enrollment on this kiosk, as the screen, the lights and the remote
/// admin show it. Immutable: every change is a new one.
class VoiceMatchEnrollment {
  const VoiceMatchEnrollment({
    required this.personId,
    required this.name,
    this.color,
    required this.targetS,
    this.phase = EnrollPhase.starting,
    this.speechS = 0,
    this.sentence,
    this.sentenceFill = 0,
    this.level = -90,
    this.otherVoices = 0,
    this.otherVoiceAt,
    this.addedS = 0,
    this.totalS = 0,
    this.droppedS = 0,
    this.code,
    this.message,
  });

  final String personId;
  final String name;

  /// The person's ring color in Voice Match, `#RRGGBB`.
  final String? color;
  final double targetS;
  final EnrollPhase phase;

  /// Speech counted toward [targetS] so far.
  final double speechS;

  /// The sentence of the passage to read and how much of it was spoken,
  /// as Ground Control paces it. Null from a Ground Control that doesn't
  /// pace the passage.
  final int? sentence;
  final double sentenceFill;

  /// The last half second's level, dBFS, for the meter.
  final double level;

  /// How many stretches sounded like someone else and were left out, and
  /// when the last one was.
  final int otherVoices;
  final DateTime? otherVoiceAt;

  /// Once saved: speech this enrollment added, the person's speech in all
  /// and what was left out as someone else's.
  final double addedS;
  final double totalS;
  final double droppedS;

  /// Why it failed or was refused: busy, no_mic, muted, too_short, lost or
  /// what the service said.
  final String? code;
  final String? message;

  bool get active =>
      phase == EnrollPhase.starting ||
      phase == EnrollPhase.recording ||
      phase == EnrollPhase.saving;

  double get progress =>
      targetS <= 0 ? 0 : (speechS / targetS).clamp(0.0, 1.0).toDouble();

  VoiceMatchEnrollment copyWith({
    EnrollPhase? phase,
    double? speechS,
    int? sentence,
    double? sentenceFill,
    double? level,
    int? otherVoices,
    DateTime? otherVoiceAt,
    double? addedS,
    double? totalS,
    double? droppedS,
    String? code,
    String? message,
  }) => VoiceMatchEnrollment(
    personId: personId,
    name: name,
    color: color,
    targetS: targetS,
    phase: phase ?? this.phase,
    speechS: speechS ?? this.speechS,
    sentence: sentence ?? this.sentence,
    sentenceFill: sentenceFill ?? this.sentenceFill,
    level: level ?? this.level,
    otherVoices: otherVoices ?? this.otherVoices,
    otherVoiceAt: otherVoiceAt ?? this.otherVoiceAt,
    addedS: addedS ?? this.addedS,
    totalS: totalS ?? this.totalS,
    droppedS: droppedS ?? this.droppedS,
    code: code ?? this.code,
    message: message ?? this.message,
  );

  Map<String, Object?> toJson() => {
    'personId': personId,
    'name': name,
    'color': color,
    'phase': phase.name,
    'speechS': speechS,
    'sentence': sentence,
    'sentenceFill': sentenceFill,
    'targetS': targetS,
    'otherVoices': otherVoices,
    'addedS': addedS,
    'totalS': totalS,
    'droppedS': droppedS,
    'code': code,
    'message': message,
  };
}

/// The passage, one sentence at a time, in this kiosk's language.
List<String> enrollPassage(UiStrings t) => [
  t.voiceMatchEnrollPassage1,
  t.voiceMatchEnrollPassage2,
  t.voiceMatchEnrollPassage3,
  t.voiceMatchEnrollPassage4,
  t.voiceMatchEnrollPassage5,
  t.voiceMatchEnrollPassage6,
  t.voiceMatchEnrollPassage7,
  t.voiceMatchEnrollPassage8,
  t.voiceMatchEnrollPassage9,
  t.voiceMatchEnrollPassage10,
  t.voiceMatchEnrollPassage11,
  t.voiceMatchEnrollPassage12,
  t.voiceMatchEnrollPassage13,
  t.voiceMatchEnrollPassage14,
];

/// About how long [sentence] takes to read aloud, in seconds of speech:
/// 14 letters a second, or 4.5 for Chinese characters, 1.5 s at least.
double readingSeconds(String sentence) {
  var latin = 0;
  var wide = 0;
  for (final rune in sentence.runes) {
    if (rune >= 0x2E80) {
      wide++;
    } else if (rune > 0x20) {
      latin++;
    }
  }
  return math.max(1.5, latin / 14 + wide / 4.5);
}

/// Which sentence to show after [speechS] of [targetS] seconds of speech.
/// The passage is spread over the target, so it ends as the enrollment
/// does. It starts over when someone reads past it.
int sentenceAt(List<String> passage, double speechS, double targetS) {
  final lengths = [for (final s in passage) readingSeconds(s)];
  final total = lengths.fold<double>(0, (a, b) => a + b);
  if (total <= 0 || targetS <= 0) return 0;
  var at = (speechS / targetS * total) % total;
  for (var i = 0; i < lengths.length; i++) {
    if (at < lengths[i]) return i;
    at -= lengths[i];
  }
  return lengths.length - 1;
}

/// What starts an enrollment: the person and how much speech to collect.
class EnrollRequest {
  const EnrollRequest({
    required this.personId,
    required this.name,
    this.color,
    this.targetS = 45,
  });

  final String personId;
  final String name;
  final String? color;
  final double targetS;
}

/// The enrollment socket (`/api/enroll`) for one enrollment.
abstract class EnrollSocketPort {
  void feed(Uint8List pcm);

  /// Stop early: the service saves what there is when it is enough.
  void end();

  void close();
}

typedef OpenEnrollSocket =
    EnrollSocketPort Function(
      EnrollRequest request,
      void Function(Map<String, Object?> event) onEvent,
    );

/// Records a person's voice with the kiosk's microphone for Voice Match.
///
/// The service sends `enroll` over the control socket when someone starts
/// an enrollment on this kiosk from the Ground Control app. The wake word
/// stands down while the person reads, so the passage never starts a voice
/// command, and the audio is the same the voice turns send: the wake word
/// engine's stream, after echo cancellation.
class VoiceMatchEnroller {
  VoiceMatchEnroller({
    required this.mic,
    required this.openSocket,
    required this.chime,
    required this.onChanged,
    required this.pauseWake,
    required this.resumeWake,
    this.log,
  });

  final VoiceMicPort mic;
  final OpenEnrollSocket openSocket;

  /// Plays a voice chime and waits for it to end.
  final Future<void> Function(String kind) chime;
  final void Function(VoiceMatchEnrollment? state) onChanged;
  final void Function() pauseWake;
  final void Function() resumeWake;
  final void Function(String line)? log;

  /// The enrollment on screen, or null. A finished one stays a few
  /// seconds for its result card.
  VoiceMatchEnrollment? get state => _state;
  VoiceMatchEnrollment? _state;

  bool get active => _state?.active ?? false;

  EnrollSocketPort? _socket;
  bool _micOpen = false;
  int _gen = 0;
  Timer? _clear;
  Timer? _limit;

  /// How long the result card stays.
  static const resultFor = Duration(seconds: 6);

  /// An enrollment that goes on this long is stopped and saved.
  static const maxLength = Duration(minutes: 4);

  /// Starts recording [request], unless [refuse] names why it cannot
  /// (busy, no_mic, muted): then it is refused and nothing records.
  Future<void> start(EnrollRequest request, {String? refuse}) async {
    if (active) {
      _set(_refused(request, 'busy'));
      return;
    }
    if (refuse != null) {
      _set(_refused(request, refuse));
      return;
    }
    final gen = ++_gen;
    _clear?.cancel();
    _set(
      VoiceMatchEnrollment(
        personId: request.personId,
        name: request.name,
        color: request.color,
        targetS: request.targetS,
      ),
    );
    log?.call('enrolling ${request.name} (${request.targetS} s)');
    pauseWake();
    await chime('wake');
    if (gen != _gen) return;
    final socket = openSocket(request, (e) => _onEvent(gen, e));
    _socket = socket;
    // Pre-roll is what the wake word engine kept from before: not the
    // person reading.
    final opened = await mic.open((pcm, preRoll) {
      if (!preRoll && gen == _gen) socket.feed(pcm);
    });
    if (gen != _gen) return;
    if (!opened) {
      socket.close();
      _socket = null;
      await _fail(gen, 'no_mic');
      return;
    }
    _micOpen = true;
    _limit = Timer(maxLength, stop);
  }

  /// The Stop button: the service keeps what was recorded when it is
  /// enough.
  Future<void> stop() async {
    final s = _state;
    if (s == null || !s.active) return;
    log?.call('enrollment stopped at ${s.speechS} s');
    await _closeMic();
    final now = _state;
    if (now == null || !now.active) return;
    if (now.phase == EnrollPhase.starting && _socket == null) {
      // Still on the chime: nothing was recorded.
      ++_gen;
      _set(now.copyWith(phase: EnrollPhase.failed, code: 'stopped'));
      _finish();
      return;
    }
    _set(now.copyWith(phase: EnrollPhase.saving));
    _socket?.end();
  }

  /// Something else needs the kiosk (a voice turn, an announcement): stop
  /// like the Stop button.
  Future<void> interrupt() => stop();

  void _onEvent(int gen, Map<String, Object?> e) {
    if (gen != _gen) return;
    final s = _state;
    if (s == null) return;
    double read(String key, double fallback) =>
        (e[key] is num) ? (e[key] as num).toDouble() : fallback;
    switch (e['type']) {
      case 'ready':
        if (s.phase == EnrollPhase.starting) {
          _set(s.copyWith(phase: EnrollPhase.recording));
        }
      case 'progress':
        _set(
          s.copyWith(
            phase: s.phase == EnrollPhase.starting
                ? EnrollPhase.recording
                : null,
            speechS: read('speech_s', s.speechS),
            sentence: e['sentence'] is int ? e['sentence'] as int : null,
            sentenceFill: read('sentence_fill', s.sentenceFill),
            level: read('level', s.level),
          ),
        );
      case 'other_voice':
        _set(
          s.copyWith(
            otherVoices: s.otherVoices + 1,
            otherVoiceAt: DateTime.now(),
          ),
        );
      case 'done':
        unawaited(_closeMic());
        _set(
          s.copyWith(
            phase: EnrollPhase.saving,
            speechS: read('speech_s', s.speechS),
          ),
        );
      case 'saved':
        _limit?.cancel();
        unawaited(_closeMic());
        _socket?.close();
        _socket = null;
        _set(
          s.copyWith(
            phase: EnrollPhase.saved,
            addedS: read('added_s', 0),
            totalS: read('speech_s', 0),
            droppedS: read('dropped_s', 0),
          ),
        );
        log?.call('enrolled ${s.name}: ${e['added_s']} s added');
        unawaited(chime('done'));
        _finish();
      case 'error':
        _socket?.close();
        _socket = null;
        unawaited(
          _fail(
            gen,
            '${e['code'] ?? 'error'}',
            message: e['message'] as String?,
          ),
        );
      case 'closed':
        // The socket went away before the service said it saved.
        if (s.active) unawaited(_fail(gen, 'lost'));
    }
  }

  Future<void> _fail(int gen, String code, {String? message}) async {
    if (gen != _gen) return;
    _limit?.cancel();
    await _closeMic();
    final s = _state;
    if (s == null) return;
    log?.call(
      'enrollment failed: $code${message == null ? '' : ' ($message)'}',
    );
    _set(s.copyWith(phase: EnrollPhase.failed, code: code, message: message));
    unawaited(chime('error'));
    _finish();
  }

  Future<void> _closeMic() async {
    if (!_micOpen) return;
    _micOpen = false;
    await mic.close();
  }

  /// Back to normal: the wake word listens again and the result card
  /// leaves after a few seconds.
  void _finish() {
    _limit?.cancel();
    resumeWake();
    final gen = _gen;
    _clear?.cancel();
    _clear = Timer(resultFor, () {
      if (gen != _gen || (_state?.active ?? false)) return;
      _set(null);
    });
  }

  VoiceMatchEnrollment _refused(EnrollRequest r, String code) =>
      VoiceMatchEnrollment(
        personId: r.personId,
        name: r.name,
        color: r.color,
        targetS: r.targetS,
        phase: EnrollPhase.refused,
        code: code,
      );

  void _set(VoiceMatchEnrollment? next) {
    // A refusal is reported, but what is on screen stays.
    if (next?.phase == EnrollPhase.refused) {
      onChanged(next);
      return;
    }
    _state = next;
    onChanged(next);
  }

  void dispose() {
    ++_gen;
    _clear?.cancel();
    _limit?.cancel();
    _socket?.close();
    unawaited(_closeMic());
  }
}

/// The enrollment socket on a real service.
class EnrollSocket implements EnrollSocketPort {
  EnrollSocket._(this._onEvent, this._log);

  final void Function(Map<String, Object?> event) _onEvent;
  final void Function(String line)? _log;
  WebSocketChannel? _socket;
  StreamSubscription<Object?>? _sub;
  final _queue = <Uint8List>[];
  int _queued = 0;
  bool _ready = false;
  bool _closed = false;
  bool _endAsked = false;

  static const _maxQueued = 320000;

  static EnrollSocket open({
    required String baseUrl,
    required String token,
    String? ticket,
    required EnrollRequest request,
    required String deviceId,
    required String deviceName,
    required String model,
    List<String> passage = const [],
    required void Function(Map<String, Object?> event) onEvent,
    void Function(String line)? log,
  }) {
    final socket = EnrollSocket._(onEvent, log);
    final base = Uri.parse(baseUrl);
    final uri = base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/api/enroll',
    );
    unawaited(
      socket._connect(uri, {
        'type': 'start',
        'token': token,
        'ticket': ?ticket,
        'person_id': request.personId,
        'device_id': deviceId,
        'device_name': deviceName,
        'model': model,
        'target_s': request.targetS,
        // The text this kiosk shows, so the Ground Control app shows the same.
        if (passage.isNotEmpty) 'passage': passage,
      }),
    );
    return socket;
  }

  Future<void> _connect(Uri uri, Map<String, Object?> start) async {
    try {
      final socket = WebSocketChannel.connect(uri);
      await socket.ready.timeout(const Duration(seconds: 5));
      if (_closed) {
        await socket.sink.close();
        return;
      }
      _socket = socket;
      socket.sink.add(jsonEncode(start));
      _sub = socket.stream.listen(
        _onMessage,
        onError: (Object _) => _gone(),
        onDone: _gone,
        cancelOnError: true,
      );
    } on Object catch (err) {
      _log?.call('voice match enrollment did not open: $err');
      _gone();
    }
  }

  void _onMessage(Object? data) {
    if (data is! String) return;
    final Map<String, Object?> e;
    try {
      e = (jsonDecode(data) as Map).cast<String, Object?>();
    } on Object {
      return;
    }
    if (e['type'] == 'ready') {
      _ready = true;
      for (final pcm in _queue) {
        _socket?.sink.add(pcm);
      }
      _queue.clear();
      _queued = 0;
      if (_endAsked) _sendEnd();
    }
    _onEvent(e);
  }

  @override
  void feed(Uint8List pcm) {
    if (_closed || _endAsked) return;
    if (_ready) {
      _socket?.sink.add(pcm);
      return;
    }
    if (_queued + pcm.length > _maxQueued) return;
    _queue.add(Uint8List.fromList(pcm));
    _queued += pcm.length;
  }

  @override
  void end() {
    if (_closed || _endAsked) return;
    _endAsked = true;
    if (_ready) _sendEnd();
  }

  void _sendEnd() {
    try {
      _socket?.sink.add(jsonEncode({'type': 'end'}));
    } on Object {
      // Closed already: _gone reports it.
    }
  }

  void _gone() {
    if (_closed) return;
    close();
    _onEvent(const {'type': 'closed'});
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _ready = false;
    _queue.clear();
    unawaited(_sub?.cancel());
    _sub = null;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      unawaited(socket.sink.close().catchError((Object _) {}));
    }
  }
}
