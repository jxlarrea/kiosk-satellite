import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import '../assist_view.dart';
import '../chat_log.dart';
import '../reactive_level.dart';
import '../voice_session.dart';
import 'pcm_resampler.dart';
import 'realtime_backend.dart';
import 'realtime_history.dart';
import 'realtime_player.dart';

/// The settings a realtime session reads, fresh each time.
class RealtimeOptions {
  const RealtimeOptions({
    this.wakeSound = true,
    this.seamless = false,
    this.idleSeconds = 10,
    this.talkOver = true,
    this.talkOverLevel = RealtimeSession.bargeInLevel,
    this.language = '',
    this.historyHours = 0,
  });

  final bool wakeSound;

  /// Keep what was said right after the wake word, with no chime.
  final bool seamless;

  /// The session ends after this long with nobody talking.
  final int idleSeconds;

  /// Full duplex: the microphone stays open while the model speaks, so
  /// the user can talk over it. Off, the model's own voice cannot reach
  /// it on a device whose echo canceller lets it through, and only the
  /// stop word interrupts.
  final bool talkOver;

  /// How loud the microphone has to be, chunk after chunk, for speech over
  /// an answer to be the user, from [RealtimeSession.talkOverLevel].
  final int talkOverLevel;

  /// The kiosk's language, a transcription hint.
  final String language;

  /// How long earlier exchanges carry into the next conversation, in
  /// hours. 0 starts every conversation fresh.
  final double historyHours;
}

/// One realtime voice conversation: from the wake word until the user goes
/// quiet, says goodbye or closes it. The device side of full duplex: the
/// microphone streams the whole time, the model's voice plays as it
/// arrives, and when the user talks over it the rest is dropped and the
/// model is told how much was heard. The model side is the backend's.
///
/// The overlay is docked: a bubble with the current exchange and the
/// skin's bar along its bottom, up for the whole conversation. The
/// dashboard stays visible and usable underneath.
///
/// Every await re-checks a generation counter, as [VoiceSession] does.
class RealtimeSession {
  RealtimeSession({
    required this.backend,
    required this.mic,
    required this.player,
    required this.chimes,
    required this.options,
    required this.onView,
    required this.onLevel,
    required this.onCountdown,
    required this.onBusy,
    required this.onStopArmed,
    required this.onError,
    this.onWarning,
    this.onIdle,
    this.onTrace,
    this.location,
    RealtimeHistory? history,
    DateTime Function()? now,
    this.tick = const Duration(milliseconds: 20),
  }) : _now = now ?? DateTime.now,
       history = history ?? RealtimeHistory(now: now);

  /// A fresh backend per conversation.
  final RealtimeBackend Function() backend;
  final VoiceMicPort mic;
  final RealtimePlayerPort player;

  /// The wake and done chimes.
  final VoicePlayerPort chimes;
  final RealtimeOptions Function() options;
  final void Function(AssistView view) onView;
  final void Function(double level) onLevel;

  /// How much of the silence before the end is left, 0..1, over its last
  /// [countdown]; 1 the rest of the time.
  final void Function(double left) onCountdown;
  final void Function(bool busy, String reason) onBusy;
  final void Function(bool armed) onStopArmed;
  final void Function(String code, String message) onError;
  final void Function(String message)? onWarning;
  final void Function()? onIdle;
  final void Function(String step, {String? text})? onTrace;

  /// Where the kiosk is, for the instructions (see [RealtimeStart.context]).
  /// Waited on for at most [locationWait] while the wake chime plays.
  final Future<String> Function()? location;
  static const locationWait = Duration(milliseconds: 1500);

  /// What was said, across conversations.
  final RealtimeHistory history;
  final DateTime Function() _now;
  final Duration tick;

  /// The stretch of the silence the bar counts down over.
  static const countdown = Duration(seconds: 5);

  /// The self-heal in the wake word manager gives a turn ten minutes.
  static const maxLength = Duration(minutes: 9);

  /// Echo lingers after the voice stops: the microphone stays shut this
  /// long after it, without talk over.
  static const echoTail = Duration(milliseconds: 600);

  /// Audio held while the connection comes up, at most.
  static const _holdLimit = 24000 * 2 * 6;

  static const chimeDrain = Duration(milliseconds: 250);

  int _gen = 0;
  bool _busy = false;
  RealtimeBackend? _backend;
  StreamSubscription<RealtimeEvent>? _events;
  Timer? _ticker;

  bool get busy => _busy;

  // The microphone.
  bool _micOpen = false;
  PcmResampler? _resampler;
  final _held = <Uint8List>[];
  int _heldBytes = 0;
  bool _ready = false;

  /// Mic audio is dropped until then: the wake chime.
  DateTime? _deafUntil;

  // Playback.
  bool _playerOpen = false;
  int _outRate = 24000;
  int _written = 0;
  int _playedKnown = 0;
  DateTime _playedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _polling = false;
  DateTime? _lastPoll;
  String _item = '';
  final _itemStart = <String, int>{};
  bool _wasPlaying = false;
  DateTime? _playEnded;

  /// Output levels, one per slice from [_levelBase] on.
  final _outLevels = <double>[];

  /// The raw loudness of the same slices, 0..1 of full scale: whether the
  /// voice is speaking at a moment, which the bar's levels do not say.
  final _outRaw = <double>[];
  int _levelBase = 0;
  static const _sliceMs = 20;

  // The conversation.
  DateTime _started = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _activity = DateTime.fromMillisecondsSinceEpoch(0);
  bool _userSpeaking = false;
  bool _responding = false;
  bool _awaiting = false;

  /// Tools running for the model now. The answer that asked for them is
  /// done and nothing plays, which looked like silence to the end of the
  /// conversation: a slow tool started the countdown and could end it.
  int _toolsRunning = 0;
  DateTime? _awaitingSince;
  bool _endRequested = false;

  /// The answer that ended the conversation is done: the conversation ends
  /// once its voice plays out. Gemini can start another turn after the
  /// tool's output, and that one is never played or waited for.
  bool _goodbyeDone = false;

  /// Asked to end once the model has answered: an intercom call placed by
  /// voice waits for the conversation, and the closing silence would only
  /// keep it ringing later. [_answeredSinceEndAsk] is an answer finished
  /// since the ask, so a tool still running does not end it first.
  bool _endAfterAnswer = false;
  bool _answeredSinceEndAsk = false;
  bool _stopArmed = false;

  AssistView _view = AssistView.hidden;

  /// The user started talking: the bubble's exchange is replaced once
  /// their words arrive, not before.
  bool _newExchange = false;
  final _levels = ReactiveLevel();

  void _show(AssistView view) {
    _view = view;
    onView(view);
  }

  /// The caption is the current exchange. Nothing in it hides it.
  AssistView _docked({
    AssistPhase? phase,
    String? command,
    String? answer,
    bool? streaming,
    List<String>? tools,
    bool? reactive,
  }) => AssistView(
    phase: phase ?? _view.phase,
    command: command ?? _view.command,
    answer: answer ?? _view.answer,
    streaming: streaming ?? _view.streaming,
    tools: tools ?? _view.tools,
    reactive: reactive ?? _view.reactive,
    docked: true,
  );

  // ── start ───────────────────────────────────────────────────────────────

  /// The wake word fired ([phrase] names it), or a conversation was asked
  /// for without one. With an [opening], the assistant speaks first: the
  /// model says it in its own voice once connected, after the announcement
  /// chime when [announceChime] is on, and [onOpened] runs once it has
  /// played or the conversation ended first.
  Future<void> wake(
    String phrase, {
    String opening = '',
    bool announceChime = false,
    void Function()? onOpened,
  }) async {
    if (_busy) {
      onOpened?.call();
      return;
    }
    final gen = ++_gen;
    _reset();
    _busy = true;
    _started = _now();
    _activity = _started;
    _opening = opening.trim();
    _onOpened = onOpened;
    final opts = options();
    if (_opening.isEmpty) {
      onTrace?.call('realtime conversation, wake word "$phrase"');
    } else {
      onTrace?.call('realtime conversation, opening', text: _opening);
    }
    onBusy(true, 'voice');
    // Listening shows with the wake chime, which holds its start until
    // its track has settled (see LeadInProcessor); without one, now. An
    // opening has nothing to listen to until it is said.
    final wakeChime = _opening.isEmpty && opts.wakeSound && !opts.seamless;
    if (_opening.isNotEmpty) {
      _show(
        const AssistView(
          phase: AssistPhase.thinking,
          reactive: false,
          docked: true,
        ),
      );
    } else if (!wakeChime) {
      _showListening();
    }
    onCountdown(1);

    final opened = await mic.open((pcm, preRoll) => _onMic(gen, pcm, preRoll));
    if (gen != _gen) {
      if (opened) await mic.close();
      return;
    }
    _micOpen = opened;
    if (!opened) {
      onError('microphone', 'The microphone is not available.');
      await _end(gen, sound: 'error');
      return;
    }

    final backend = this.backend();
    _backend = backend;
    final caps = backend.capabilities;
    _outRate = caps.outputRate;
    _resampler = PcmResampler(from: 16000, to: caps.inputRate);
    _events = backend.events.listen((e) => _onEvent(gen, e));
    _ticker = Timer.periodic(tick, (_) => _onTick(gen));

    // The chime plays while the connection comes up. What the microphone
    // hears over it is not part of what the user says.
    final chime = wakeChime
        ? _chime(gen, 'wake')
        : _opening.isNotEmpty && announceChime
        ? _chime(gen, 'announce')
        : Future<void>.value();
    _chimed = chime;
    unawaited(_connect(gen, backend, phrase, opts));
    await chime;
  }

  /// The line the assistant opens with, empty when the user speaks first.
  String _opening = '';
  void Function()? _onOpened;

  /// The chime the conversation started with, which the opening waits for.
  Future<void> _chimed = Future<void>.value();

  void _opened() {
    final done = _onOpened;
    _onOpened = null;
    done?.call();
  }

  Future<void> _connect(
    int gen,
    RealtimeBackend backend,
    String phrase,
    RealtimeOptions opts,
  ) async {
    var where = '';
    final lookup = location;
    if (lookup != null) {
      try {
        where = await lookup().timeout(locationWait);
      } catch (e) {
        // The conversation goes on without the room in its instructions.
        onTrace?.call('kiosk location lookup failed: $e');
      }
    }
    if (gen != _gen) return;
    final minutes = (opts.historyHours * 60).round();
    await backend.start(
      RealtimeStart(
        wakeWord: phrase,
        language: opts.language,
        context: where,
        history: minutes > 0
            ? history.recent(Duration(minutes: minutes))
            : const [],
      ),
    );
  }

  void _showListening() => _show(
    const AssistView(
      phase: AssistPhase.listening,
      reactive: false,
      docked: true,
    ),
  );

  Future<void> _chime(int gen, String kind) async {
    _deafUntil = _now().add(const Duration(seconds: 5));
    final played = await chimes.chime(kind);
    if (gen != _gen) return;
    if (kind == 'wake' && !_view.visible) _showListening();
    if (played == null) {
      _deafUntil = null;
      return;
    }
    _deafUntil = _now().add(
      Duration(milliseconds: (played.$2 * 1000).round()) + chimeDrain,
    );
  }

  // ── the microphone ──────────────────────────────────────────────────────

  void _onMic(int gen, Uint8List pcm, bool preRoll) {
    if (gen != _gen || !_busy) return;
    final opts = options();
    if (preRoll && !opts.seamless) return;
    final deaf = _deafUntil;
    if (deaf != null) {
      if (_now().isBefore(deaf)) {
        _held.clear();
        _heldBytes = 0;
        return;
      }
      _deafUntil = null;
    }
    final playing = _playing;
    final level = meanAbs(pcm);
    if (playing) _echo.add(level);
    // The bar follows the voice playing, else the microphone.
    if (!playing) _micLevel(_levels.mic(pcm));
    final echo = playing || _inEchoTail;
    if (!opts.talkOver && echo) return;
    if (!echo) _room.hear(pcm, level);
    if (playing) _watchSettling(level);
    _recent.add(echo && _settling ? 0 : level);
    if (_recent.length > _recentChunks) _recent.removeAt(0);
    if (playing && !_settling && !_suspect && !_talkingOver) {
      _echoUnder.add(level);
      if (_echoUnder.length > _echoUnderChunks) _echoUnder.removeAt(0);
    }
    if (_suspect) _weighSuspect(gen, level);
    if (playing && _settling) {
      // The canceller has not caught up with this answer yet: the room's
      // own noise instead.
      final comfort = _room.comfort(pcm.length);
      if (_ready) _backend?.sendAudio(_resampler?.convert(comfort) ?? comfort);
      return;
    }
    // The canceller mutes the microphone outright while it cancels, and a
    // room with a noise floor (an air conditioner) then comes back all at
    // once when it lets go. The provider takes that step for someone
    // starting to talk and answers nothing, so the muted stretch goes as
    // the room's noise. Someone talking over the answer is louder than the
    // room and goes as it is.
    if (echo && _room.muted(level)) pcm = _room.comfort(pcm.length);
    if (_ready && echo && !_clientTurns && !_talkingOver) {
      _holdBack(gen, pcm);
      return;
    }
    final converted = _resampler?.convert(pcm) ?? pcm;
    if (!_ready) {
      _held.add(converted);
      _heldBytes += converted.length;
      while (_heldBytes > _holdLimit && _held.isNotEmpty) {
        _heldBytes -= _held.removeAt(0).length;
      }
      return;
    }
    _backend?.sendAudio(converted);
  }

  /// The microphone's level through the answer playing now, logged when
  /// it ends: a working echo canceller keeps it near the room's own noise
  /// (under 100 on a Galaxy Tab S8), a failing one lets the answer back in
  /// as loud as the user (1000 and more). One line per answer, so a
  /// conversation that answered itself says why in the log.
  final _echo = <int>[];

  void _logEcho() {
    if (_echo.length < 5) {
      _echo.clear();
      return;
    }
    final sorted = List.of(_echo)..sort();
    final loud = sorted.where((v) => v > 800).length;
    onTrace?.call(
      'microphone while the answer played: median ${sorted[sorted.length ~/ 2]}, '
      'peak ${sorted.last}, loud ${loud * 100 ~/ sorted.length}%',
    );
    _echo.clear();
  }

  /// Mean absolute sample of PCM16.
  static int meanAbs(Uint8List pcm) {
    final data = ByteData.sublistView(pcm);
    final n = pcm.length ~/ 2;
    if (n == 0) return 0;
    var sum = 0;
    for (var i = 0; i < n; i++) {
      sum += data.getInt16(i * 2, Endian.little).abs();
    }
    return sum ~/ n;
  }

  /// The room's noise, heard between answers.
  final _room = RoomNoise();

  double _lastMicLevel = 0;
  void _micLevel(double level) => _lastMicLevel = level;

  /// When the answer playing now started, from nothing playing.
  DateTime? _answerFrom;

  /// The echo canceller locks onto each answer a moment after it starts,
  /// and until it does the answer comes back into the microphone as loud
  /// as the user (measured on a Galaxy Tab S8). The provider takes that for
  /// the user talking over it, stops the answer and starts another, which
  /// leaks again. With talk over on, the microphone goes as the room's
  /// noise from the start of each answer until the canceller has it: the
  /// cleaned microphone stays near the room's own level for [settledAfter]
  /// chunks in a row while the voice is speaking. Usually well under a
  /// second, and never longer than this: after it, the user can interrupt.
  static const echoSettle = Duration(seconds: 4);

  /// Quiet chunks under a speaking voice that show the echo is out.
  static const settledAfter = 6;

  /// The settling never ends sooner: the echo of an answer's first words
  /// reaches the microphone a moment after they play, and a microphone
  /// still waiting for it is quiet for the wrong reason.
  static const settleAtLeast = Duration(seconds: 1);

  /// How far back the voice counts as speaking for a quiet chunk: its echo
  /// comes back this much later.
  static const echoReach = Duration(milliseconds: 300);

  /// Playback this loud (of full scale) is the voice speaking.
  static const voiced = 0.02;

  /// A chunk this quiet, or near the room's own level, or well under what
  /// counts as the user ([_bargeInThreshold] over [quietUnderBargeIn]),
  /// holds no echo worth waiting for. The room's level is only measured
  /// while nothing plays, so a conversation started over music has none,
  /// and over ducked music the canceller leaves a residual that sits
  /// around this level: on a Galaxy Tab S8 a median of 100 and a p90 of
  /// 270, which kept an answer "settling" for 10 s against the bare 150.
  static const quietLevel = 150;
  static const quietUnderBargeIn = 4;

  bool _settled = false;
  int _quietVoiced = 0;

  /// With the turns in the session's hands: speech was heard over the
  /// answer, and the microphone decides whether it was the user.
  bool get _clientTurns => _backend?.capabilities.clientTurns ?? false;
  bool _suspect = false;
  int _suspectLoud = 0;

  /// Chunks this loud, [bargeInChunks] of them, make speech over an answer
  /// the user: a voice at the kiosk reads in the thousands, what is left
  /// of the answer's own echo a few hundred.
  static const bargeInLevel = 1200;
  static const bargeInChunks = 3;

  /// The microphone's last second, chunk by chunk: the provider says
  /// speech started half a second after it did (the audio's trip there
  /// and the word back), by when a short "stop" is mostly over.
  final _recent = <int>[];
  static const _recentChunks = 12;

  /// The level for the talk over sensitivity setting, 0 to 100:
  /// [bargeInLevel] at 50, down to 40 at 100 and up to 4800 at 0, evenly
  /// spaced on a log scale. Some microphones come out of the canceller far
  /// quieter than a Galaxy Tab S8's (110 for a user talking over an answer
  /// on an Android Things display, heard from about 90). The canceller's
  /// own echo bursts into the hundreds or thousands on most devices, which
  /// is why a lower level is not the default. Below 50 helps a device that
  /// keeps interrupting itself.
  static int talkOverLevel(num sensitivity) {
    final s = sensitivity.clamp(0, 100).toDouble();
    final range = s > 50 ? 1 / 30 : 4.0;
    return (bargeInLevel * math.pow(range, (s - 50).abs() / 50)).round();
  }

  /// The level and the room's floor scale together, so a noisy room does
  /// not undo a lower level.
  int get _bargeInThreshold {
    final level = options().talkOverLevel;
    return math.max(level, _room.level * 10 * level ~/ bargeInLevel);
  }

  bool _loud(int level) => level >= _bargeInThreshold;

  /// The cleaned microphone under the settled voice, the last few seconds
  /// of it across answers: what is left of the echo on this device, for
  /// the log.
  final _echoUnder = <int>[];
  static const _echoUnderChunks = 60;

  /// The loudest chunk of the speech being weighed, and whether the
  /// canceller was still settling while it was heard.
  int _suspectPeak = 0;
  bool _suspectSettling = false;

  /// Speech heard over an answer, starting now with what the microphone
  /// already holds. The echo estimate drops that stretch: it was the user.
  void _startSuspect() {
    final drop = math.min(_recentChunks, _echoUnder.length);
    _echoUnder.removeRange(_echoUnder.length - drop, _echoUnder.length);
    _suspectLoud = _recent.where(_loud).length;
    _suspectPeak = _recent.fold(0, math.max);
    _suspectSettling = _settling;
  }

  /// Why speech over an answer was or was not the user, for the log.
  String get _talkOverDetail {
    final sorted = List.of(_echoUnder)..sort();
    final echo = sorted.isEmpty
        ? 'echo unknown'
        : 'echo median ${sorted[sorted.length ~/ 2]}, '
              'p90 ${sorted[sorted.length * 9 ~/ 10]}';
    return 'peak $_suspectPeak, $_suspectLoud of $bargeInChunks chunks at '
        '$_bargeInThreshold, $echo, room ${_room.level}'
        '${_suspectSettling ? ', while settling' : ''}';
  }

  void _weighSuspect(int gen, int level) {
    _suspectPeak = math.max(_suspectPeak, level);
    if (_settling) _suspectSettling = true;
    if (!_loud(level)) return;
    if (++_suspectLoud < bargeInChunks) return;
    _suspect = false;
    onTrace?.call('talked over the answer: $_talkOverDetail');
    unawaited(_confirmBargeIn(gen));
  }

  /// With the turns in the provider's hands (xAI), whatever it hears over
  /// an answer stops it, and it also answers every fragment it takes for
  /// speech. Measured on 2026-09-30, it accepts OpenAI's switches for that
  /// and ignores them. So the microphone goes as the room's noise while
  /// an answer plays, and the provider hears it only once the microphone
  /// shows the user talking over it by the same rule as [_clientTurns]:
  /// then the answer stops here and the provider gets the last second,
  /// the start of what the user said, and the live microphone after it.
  bool _talkingOver = false;
  final _heldBack = <Uint8List>[];

  void _holdBack(int gen, Uint8List pcm) {
    _heldBack.add(pcm);
    if (_heldBack.length > _recentChunks) _heldBack.removeAt(0);
    if (_recent.where(_loud).length < bargeInChunks) {
      final comfort = _room.comfort(pcm.length);
      _backend?.sendAudio(_resampler?.convert(comfort) ?? comfort);
      return;
    }
    _talkingOver = true;
    for (final chunk in _heldBack) {
      _backend?.sendAudio(_resampler?.convert(chunk) ?? chunk);
    }
    _heldBack.clear();
    _startSuspect();
    onTrace?.call('talked over the answer: $_talkOverDetail');
    unawaited(_confirmBargeIn(gen));
  }

  Future<void> _confirmBargeIn(int gen) async {
    _recent.clear();
    await _bargeIn(gen);
    if (gen != _gen) return;
    _newExchange = true;
    _show(
      _docked(phase: AssistPhase.listening, streaming: false, reactive: true),
    );
  }

  bool get _settling {
    final from = _answerFrom;
    return from != null && !_settled && _now().difference(from) < echoSettle;
  }

  /// How loud the voice was at its loudest over the last [echoReach].
  double get _playingRaw {
    final per = _outRate * _sliceMs ~/ 1000;
    final slice = (_playedEstimate - _levelBase) ~/ per;
    final from = slice - echoReach.inMilliseconds ~/ _sliceMs;
    var loudest = 0.0;
    for (var i = math.max(0, from); i <= slice && i < _outRaw.length; i++) {
      loudest = math.max(loudest, _outRaw[i]);
    }
    return loudest;
  }

  /// Counts the cleaned microphone's quiet chunks under the speaking voice,
  /// and ends the settling once there are enough in a row.
  void _watchSettling(int level) {
    if (_settled || _playingRaw < voiced) return;
    final quiet = level <= math.max(
      math.max(quietLevel, _room.level * 3),
      _bargeInThreshold ~/ quietUnderBargeIn,
    );
    _quietVoiced = quiet ? _quietVoiced + 1 : 0;
    final from = _answerFrom;
    if (_quietVoiced >= settledAfter &&
        from != null &&
        _now().difference(from) >= settleAtLeast) {
      _settled = true;
      onTrace?.call(
        'echo settled after ${_now().difference(from).inMilliseconds}ms',
      );
    }
  }

  bool get _inEchoTail {
    final ended = _playEnded;
    return ended != null && _now().difference(ended) < echoTail;
  }

  // ── the model ───────────────────────────────────────────────────────────

  Future<void> _onEvent(int gen, RealtimeEvent event) async {
    if (gen != _gen) return;
    switch (event) {
      case RealtimeReady():
        await _onReady(gen);
      case RealtimeSpeechStarted():
        // The conversation is over once the goodbye plays: Gemini taking
        // the room or the answer's echo for speech does not cut it.
        if (_goodbyeDone) return;
        _userSpeaking = true;
        _touch();
        if (_clientTurns && (_playing || _responding)) {
          // Maybe the user, maybe a trace of the answer's own voice: the
          // microphone shows which, starting with what it already heard.
          _startSuspect();
          onTrace?.call('speech over the answer: $_talkOverDetail');
          if (_suspectLoud >= bargeInChunks) {
            onTrace?.call('talked over the answer: $_talkOverDetail');
            await _confirmBargeIn(gen);
            return;
          }
          _suspect = true;
          return;
        }
        if (_playing || _responding) await _bargeIn(gen);
        if (gen != _gen) return;
        // A new exchange. The last one stays in the bubble until the new
        // one has words of its own.
        _newExchange = true;
        _show(
          _docked(
            phase: AssistPhase.listening,
            streaming: false,
            reactive: true,
          ),
        );
      case RealtimeSpeechStopped():
        _userSpeaking = false;
        if (_suspect) {
          // It never got loud: not the user. The answer carries on and the
          // model never hears it.
          _suspect = false;
          onTrace?.call(
            'ignored speech too quiet to be the user: $_talkOverDetail',
          );
          _backend?.userTurn(keep: false);
          _touch();
          return;
        }
        if (_clientTurns) _backend?.userTurn(keep: true);
        _awaiting = true;
        _awaitingSince = _now();
        _touch();
        _show(_docked(phase: AssistPhase.thinking, reactive: false));
      case RealtimeUserText(:final text, :final complete):
        if (complete) {
          onTrace?.call('heard', text: text);
          history.add(user: true, text: text);
        }
        if (_newExchange) {
          _newExchange = false;
          _show(
            _docked(
              command: text,
              answer: '',
              tools: const [],
              streaming: false,
            ),
          );
        } else {
          _show(_docked(command: text));
        }
      case RealtimeResponseStarted():
        _responding = true;
        _awaiting = false;
        _touch();
      case RealtimeAudio(:final itemId, :final pcm):
        _onAudio(itemId, pcm);
      case RealtimeAnswerText(:final text, :final complete):
        if (_goodbyeDone) return;
        if (complete) {
          onTrace?.call('answer', text: text);
          history.add(user: false, text: text);
        }
        _show(_docked(answer: text, streaming: !complete));
      case RealtimeToolActivity(:final name, :final done):
        _touch();
        if (done) {
          _toolsRunning = math.max(0, _toolsRunning - 1);
          // Its output goes to the model, which answers it next.
          _awaiting = true;
          _awaitingSince = _now();
        } else {
          _toolsRunning++;
        }
        if (!done) {
          onTrace?.call('tool $name');
          final line = humanizeToolName(name);
          if (!_view.tools.contains(line)) {
            _show(_docked(tools: [..._view.tools, line]));
          }
        }
      case RealtimeResponseDone():
        _responding = false;
        if (_endRequested) _goodbyeDone = true;
        if (_endAfterAnswer) _answeredSinceEndAsk = true;
        if (_staged.isNotEmpty) _release();
        _touch();
      case RealtimeEndRequested():
        onTrace?.call('the assistant ended the conversation');
        _endRequested = true;
        // Called after its answer was done: there is nothing more to wait
        // for.
        if (!_responding) _goodbyeDone = true;
      case RealtimeWarning(:final message):
        onWarning?.call(message);
      case RealtimeClosed(:final error):
        if (error != null) {
          onError('realtime', error);
          await _end(gen, sound: 'error');
        } else {
          await _end(gen, sound: 'done');
        }
    }
  }

  Future<void> _onReady(int gen) async {
    _playerOpen = await player.start(_outRate);
    if (gen != _gen) return;
    if (!_playerOpen) {
      onError('playback', 'Audio could not be played on the device.');
      await _end(gen, sound: 'error');
      return;
    }
    _ready = true;
    _touch();
    onTrace?.call('connected');
    if (_opening.isNotEmpty) {
      // Nobody has spoken yet: what the microphone held is only the room.
      _held.clear();
      _heldBytes = 0;
      // The chime has started by then. The line waits for it to end.
      await _chimed;
      final deaf = _deafUntil;
      if (deaf != null && deaf.isAfter(_now())) {
        await Future<void>.delayed(deaf.difference(_now()));
      }
      if (gen != _gen) return;
      _awaiting = true;
      _awaitingSince = _now();
      _backend?.speak(_opening);
      return;
    }
    for (final pcm in _held) {
      _backend?.sendAudio(pcm);
    }
    _held.clear();
    _heldBytes = 0;
    _show(_docked(reactive: true));
  }

  /// The start of an answer, held back until enough of it is here to play
  /// without running dry: the network delivers it in bursts. Released at
  /// [prebuffer], after [prebufferWait] or when the answer is done. The
  /// rest of the answer goes straight to the player, whose queue covers the
  /// bursts from there.
  final _staged = <(String, Uint8List)>[];
  int _stagedFrames = 0;
  DateTime? _stagedSince;

  static const prebuffer = Duration(milliseconds: 300);

  /// A slow stream still plays: what is staged goes out after this long.
  static const prebufferWait = Duration(milliseconds: 600);

  /// Answers the user talked over. The provider keeps sending what it had
  /// made of one for a moment after it is stopped, and playing that read
  /// as a new answer: the microphone went back to the room's noise while
  /// it settled, and the provider took the user for done after a word.
  final _cut = <String>{};

  void _onAudio(String itemId, Uint8List pcm) {
    if (!_playerOpen || pcm.isEmpty || _cut.contains(itemId) || _goodbyeDone) {
      return;
    }
    _awaiting = false;
    if (_view.phase != AssistPhase.speaking) {
      _show(_docked(phase: AssistPhase.speaking, reactive: true));
    }
    // A new answer with nothing playing ahead of it starts staged; the
    // one it follows would cover the wait otherwise.
    final starting = _staged.isNotEmpty || (itemId != _item && !_playing);
    if (!starting) {
      _write(itemId, pcm);
      return;
    }
    _staged.add((itemId, pcm));
    _stagedFrames += pcm.length ~/ 2;
    _stagedSince ??= _now();
    if (_stagedFrames >= _outRate * prebuffer.inMilliseconds ~/ 1000) {
      _release();
    }
  }

  void _release() {
    final staged = List.of(_staged);
    _staged.clear();
    _stagedFrames = 0;
    _stagedSince = null;
    for (final (item, pcm) in staged) {
      _write(item, pcm);
    }
  }

  void _write(String itemId, Uint8List pcm) {
    if (itemId != _item) {
      _item = itemId;
      _itemStart[itemId] = _written;
    }
    if (!_playing) {
      // A new answer, and the microphone is held back over it again.
      _talkingOver = false;
      _heldBack.clear();
      // Playback starts from here: the estimate runs from now.
      _playedKnown = _written;
      _playedAt = _now();
      _answerFrom = _now();
      _settled = false;
      _quietVoiced = 0;
    }
    _addLevels(pcm);
    player.write(pcm);
    _written += pcm.length ~/ 2;
    _touch();
    if (!_stopArmed) {
      _stopArmed = true;
      onStopArmed(true);
    }
  }

  /// A level for every 20 ms of the voice, read when that slice plays.
  void _addLevels(Uint8List pcm) {
    final samples = pcm.length ~/ 2;
    final per = _outRate * _sliceMs ~/ 1000;
    final data = ByteData.sublistView(pcm);
    // Slices are counted from the frame the list starts at.
    final expected = (_written - _levelBase) ~/ per;
    while (_outLevels.length < expected) {
      _outLevels.add(0);
      _outRaw.add(0);
    }
    for (var start = 0; start < samples; start += per) {
      final end = math.min(samples, start + per);
      var sum = 0.0;
      for (var i = start; i < end; i++) {
        sum += data.getInt16(i * 2, Endian.little).abs() / 32768.0;
      }
      final raw = sum / math.max(1, end - start);
      _outLevels.add(_levels.playback(raw));
      _outRaw.add(raw);
    }
  }

  /// Frames played by now: the player's last count, carried forward at
  /// the playback rate, never past what was written.
  int get _playedEstimate {
    final elapsed = _now().difference(_playedAt).inMicroseconds;
    final est = _playedKnown + (elapsed * _outRate / 1e6).round();
    return math.min(_written, est);
  }

  bool get _playing => _playerOpen && _playedEstimate < _written;

  /// The user talked over the answer: drop what is left of it and tell the
  /// model how much was heard.
  Future<void> _bargeIn(int gen) async {
    _logEcho();
    _staged.clear();
    _stagedFrames = 0;
    _stagedSince = null;
    final item = _item;
    if (item.isNotEmpty) _cut.add(item);
    final heard = _playerOpen ? await player.flush() : _written;
    if (gen != _gen) return;
    final start = _itemStart[item] ?? heard;
    final ms = ((heard - start) * 1000 / _outRate).round();
    onTrace?.call('interrupted after ${ms}ms');
    _written = heard;
    _playedKnown = heard;
    _playedAt = _now();
    _outLevels.clear();
    _outRaw.clear();
    _levelBase = heard;
    _responding = false;
    _backend?.interrupted(item, math.max(0, ms));
    _armStop(false);
  }

  void _armStop(bool on) {
    if (_stopArmed == on) return;
    _stopArmed = on;
    onStopArmed(on);
  }

  void _touch() => _activity = _now();

  // ── the clock ───────────────────────────────────────────────────────────

  void _onTick(int gen) {
    if (gen != _gen || !_busy) return;
    final now = _now();
    _poll(gen);
    final since = _stagedSince;
    if (since != null && now.difference(since) >= prebufferWait) _release();
    final playing = _playing || _staged.isNotEmpty;
    if (_wasPlaying && !playing) {
      _logEcho();
      _playEnded = now;
      _touch();
      _armStop(false);
      _opened();
      if (!_userSpeaking && _view.phase == AssistPhase.speaking) {
        _show(_docked(phase: AssistPhase.listening, streaming: false));
      }
    }
    _wasPlaying = playing;

    // The bar.
    if (playing) {
      final per = _outRate * _sliceMs ~/ 1000;
      final slice = (_playedEstimate - _levelBase) ~/ per;
      onLevel(slice >= 0 && slice < _outLevels.length ? _outLevels[slice] : 0);
      if (slice > 200) {
        // Keep the list short: drop what has played.
        _outLevels.removeRange(0, slice - 50);
        _outRaw.removeRange(0, slice - 50);
        _levelBase += (slice - 50) * per;
      }
    } else {
      onLevel(_ready ? _lastMicLevel : 0);
    }

    if (_awaiting &&
        _awaitingSince != null &&
        now.difference(_awaitingSince!) > const Duration(seconds: 15)) {
      _awaiting = false;
    }

    // The end.
    if (now.difference(_started) > maxLength) {
      onTrace?.call('conversation reached its length limit');
      unawaited(_end(gen, sound: 'done'));
      return;
    }
    if (_goodbyeDone && !playing) {
      unawaited(_end(gen, sound: 'done'));
      return;
    }
    if (_endAfterAnswer &&
        _answeredSinceEndAsk &&
        !_responding &&
        !_awaiting &&
        _toolsRunning == 0 &&
        !playing) {
      onTrace?.call('ending after the answer');
      unawaited(_end(gen, sound: 'done'));
      return;
    }
    final quiet =
        _ready &&
        !_userSpeaking &&
        !_responding &&
        !_awaiting &&
        _toolsRunning == 0 &&
        !playing;
    if (!quiet) {
      onCountdown(1);
      return;
    }
    final idle = Duration(seconds: math.max(3, options().idleSeconds));
    final silent = now.difference(_activity);
    final left = idle - silent;
    if (left <= Duration.zero) {
      onTrace?.call('quiet for ${idle.inSeconds}s');
      unawaited(_end(gen, sound: 'done'));
      return;
    }
    onCountdown(
      left >= countdown ? 1 : left.inMilliseconds / countdown.inMilliseconds,
    );
  }

  /// Asks the player where it is, now and then, to correct the estimate.
  void _poll(int gen) {
    if (!_playerOpen || _polling) return;
    final now = _now();
    final last = _lastPoll;
    if (last != null &&
        now.difference(last) < const Duration(milliseconds: 200)) {
      return;
    }
    if (_playedEstimate >= _written) return;
    _polling = true;
    _lastPoll = now;
    unawaited(
      player.played().then((frames) {
        _polling = false;
        if (gen != _gen) return;
        _playedKnown = math.min(frames, _written);
        _playedAt = _now();
      }),
    );
  }

  // ── ending ──────────────────────────────────────────────────────────────

  /// The stop word: stop the answer and keep listening.
  Future<void> stopAnswer() async {
    if (!_busy) return;
    final gen = _gen;
    if (_playing || _responding) await _bargeIn(gen);
    if (gen != _gen) return;
    _touch();
    _show(_docked(phase: AssistPhase.listening, streaming: false));
  }

  /// Ends the conversation once the model has spoken its next answer.
  void endAfterAnswer() {
    if (!_busy) return;
    _endAfterAnswer = true;
    _answeredSinceEndAsk = false;
  }

  /// Closed from the overlay or the voiceCancel command.
  Future<void> cancel() async {
    if (!_busy) return;
    onTrace?.call('conversation closed');
    await _end(_gen, sound: 'done');
  }

  Future<void> _end(int gen, {String? sound}) async {
    if (gen != _gen || !_busy) return;
    final ended = ++_gen;
    _busy = false;
    _opened();
    _logEcho();
    _ticker?.cancel();
    _ticker = null;
    // Not awaited: nothing is delivered after a cancel, and the future it
    // returns can belong to another zone.
    unawaited(_events?.cancel());
    _events = null;
    final backend = _backend;
    _backend = null;
    unawaited(backend?.close());
    if (_micOpen) {
      _micOpen = false;
      await mic.close();
    }
    if (_playerOpen) {
      _playerOpen = false;
      await player.stop();
    }
    _armStop(false);
    onLevel(0);
    onCountdown(1);
    _show(AssistView.hidden);
    if (sound != null && (sound == 'error' || options().wakeSound)) {
      await chimes.chime(sound);
    } else {
      await chimes.settle();
    }
    if (ended != _gen) return;
    onTrace?.call('conversation over');
    onBusy(false, '');
    onIdle?.call();
  }

  void _reset() {
    _opening = '';
    _onOpened = null;
    _chimed = Future<void>.value();
    _recent.clear();
    _cut.clear();
    _talkingOver = false;
    _heldBack.clear();
    _suspect = false;
    _suspectLoud = 0;
    _suspectPeak = 0;
    _suspectSettling = false;
    _echoUnder.clear();
    _ready = false;
    _held.clear();
    _heldBytes = 0;
    _deafUntil = null;
    _written = 0;
    _playedKnown = 0;
    _playedAt = _now();
    _lastPoll = null;
    _polling = false;
    _item = '';
    _itemStart.clear();
    _wasPlaying = false;
    _playEnded = null;
    _outLevels.clear();
    _outRaw.clear();
    _levelBase = 0;
    _staged.clear();
    _stagedFrames = 0;
    _stagedSince = null;
    _userSpeaking = false;
    _responding = false;
    _awaiting = false;
    _awaitingSince = null;
    _toolsRunning = 0;
    _endRequested = false;
    _goodbyeDone = false;
    _endAfterAnswer = false;
    _answeredSinceEndAsk = false;
    _newExchange = false;
    _lastMicLevel = 0;
    _answerFrom = null;
    _room.clear();
  }

  Future<void> dispose() async {
    if (_busy) await _end(_gen);
  }
}

/// Comfort noise: the room's own background, recorded between answers and
/// played to the provider in place of the stretches the echo canceller
/// mutes, so the noise floor it hears never steps from nothing to
/// something. Telephone networks do the same for the same reason.
class RoomNoise {
  /// Chunks of the room kept, about five seconds of the microphone.
  static const keep = 60;

  /// A room quieter than this has no floor to step back up to.
  static const audible = 10;

  final _chunks = <(Uint8List, int)>[];
  int _next = 0;

  void hear(Uint8List pcm, int level) {
    _chunks.add((pcm, level));
    if (_chunks.length > keep) _chunks.removeAt(0);
  }

  /// The room's floor: a low percentile, so talking does not count.
  int get level {
    if (_chunks.isEmpty) return 0;
    final levels = [for (final (_, l) in _chunks) l]..sort();
    return levels[levels.length ~/ 5];
  }

  /// Whether a chunk at [level] is the canceller muting a room that has a
  /// floor, rather than the room or someone in it.
  bool muted(int level) {
    final floor = this.level;
    return floor >= audible && level < floor ~/ 2;
  }

  /// [length] bytes of the room's quiet stretches, in the order heard.
  /// Silence while there is nothing to go on.
  Uint8List comfort(int length) {
    final floor = level;
    final quiet = [
      for (final (pcm, l) in _chunks)
        if (floor >= audible && l <= floor * 2 + audible) pcm,
    ];
    final out = Uint8List(length);
    if (quiet.isEmpty) return out;
    var at = 0;
    while (at < length) {
      final chunk = quiet[_next++ % quiet.length];
      final n = math.min(chunk.length, length - at);
      out.setRange(at, at + n, chunk);
      at += n;
    }
    return out;
  }

  void clear() {
    _chunks.clear();
    _next = 0;
  }
}
