import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'native_audio_source.dart';

/// Native transport for Voice Satellite's assist pipeline runs
/// (docs/js-api.md, "Pipeline delegation").
///
/// Under the wake-word handoff the page used to be the audio middleman:
/// the app base64-encoded every mic chunk into an evaluateJavascript call,
/// the page decoded it, re-encoded it to PCM16 and re-sent it as a binary
/// frame on the dashboard's Home Assistant websocket. On weak tablets that
/// round trip competes with the page's own rendering for the main thread,
/// and speech delivery stutters exactly when the page does.
///
/// With delegation the page keeps everything it is good at — the session
/// policy, the overlay UI, every pipeline event — and hands us only the
/// transport: we subscribe to `voice_satellite/run_pipeline` on our own
/// authenticated websocket, upload mic PCM as binary frames directly, and
/// forward every pipeline event into the page. The page's audio calls
/// (mute, buffer, send) map one-to-one onto commands here, so its turn
/// choreography (chime mute window, cross-tablet dedupe, seamless one-shot
/// buffering) runs unchanged; only where the audio lives moved.
///
/// The page never sees PCM at all during a delegated turn. Its reactive bar
/// gets a per-chunk speech-weighted level instead ([PipelineMicLevel]),
/// computed here with the same band-split math the page used on raw chunks.
class AssistPipelineManager extends Manager {
  AssistPipelineManager(
    super.bus,
    super.commands,
    super.log,
    this._settings,
    this._mic, {
    WebSocketChannel Function(Uri uri)? channelFactory,
  }) : _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final SettingsManager _settings;
  final NativeAudioSource _mic;
  final WebSocketChannel Function(Uri uri) _channelFactory;

  @override
  String get name => 'pipeline';

  /// One command socket, kept across runs. Opened lazily (and kicked
  /// preemptively on wake detection, so it is authenticated by the time the
  /// page asks for a run) and reopened on demand after it dies — screen-off
  /// Wi-Fi naps kill idle sockets, and a reconnect loop would just fight
  /// that for nothing.
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSub;
  Future<bool>? _connecting;
  bool _authed = false;
  int _nextId = 1;
  final Map<int, Completer<Object?>> _pending = {};

  /// The single active run. Voice Satellite runs one pipeline at a time
  /// (its own generation counter enforces it); a new run displaces a stale
  /// one here the same way its defensive cleanup unsubscribes first.
  String? _runId;
  int? _runSubId;
  int _runCounter = 0;
  int? _handlerId;

  // ── Delegated audio state ────────────────────────────────────────────
  // Mirrors the page's AudioManager exactly: chunks are buffered only
  // while sending or explicitly buffering, muted chunks are dropped on
  // arrival (never buffered), and a 100 ms pump drains the buffer into
  // binary frames. Parity is the point — the page's choreography was
  // tuned against these semantics and must not notice the move.
  final List<Uint8List> _buffer = [];
  bool _micOpen = false;
  bool _buffering = false;
  bool _sending = false;
  bool _muted = false;
  Timer? _pump;

  // One-pole band-split state for the speech-weighted level (the page's
  // pushMicPcm math, ported so the bar renders identically).
  double _lp180 = 0;
  double _lp3400 = 0;

  // Level batching: the benchmark showed the bridge's cost is the CALL
  // count, not the payload, so per-chunk level events were as expensive as
  // the audio chunks they replaced. Levels accumulate with offsets and
  // flush as one event every few chunks; the page replays them locally, so
  // the bar still moves at chunk cadence for one batch window of latency.
  final List<Map<String, Object?>> _levelBatch = [];
  int _levelBatchStartMs = 0;
  static const _levelBatchMax = 3;
  static const _levelBatchWindowMs = 240;

  bool get _enabled =>
      _settings.get(defs.vsNativePipeline) &&
      _settings.get(defs.haUrl).isNotEmpty &&
      _settings.get(defs.haToken).isNotEmpty;

  @override
  Future<void> init() async {
    // The app hears the wake word before the page does (it is the
    // detector), so start authenticating now and the socket is usually
    // ready by the time the page asks for its run.
    bus.on<WakeWordDetected>().listen((_) {
      if (_enabled) unawaited(_ensureConnected());
    });

    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.haUrl.key || e.key == defs.haToken.key) {
        // Credentials moved; whatever is open is for the old ones. Through
        // the dead-socket path so a run in flight tells the page it died.
        _onSocketDead('settings changed');
      }
    });

    commands
      ..register(Command(
        name: 'pipelineOpenMic',
        description:
            'Open the delegated microphone for a native pipeline run: mic '
            'chunks flow into the app-side buffer (pre-roll first) instead '
            'of the page, and per-chunk levels are dispatched for the '
            'reactive bar. Fails when the native pipeline is disabled or '
            'the wake-word engine is not running.',
        handler: (_) async {
          if (!_enabled) return const CommandResult.fail('native pipeline off');
          final ok = await _mic.openNativeAudioStream(_onChunk);
          if (!ok) return const CommandResult.fail('engine not running');
          _micOpen = true;
          return const CommandResult.ok({'sampleRate': 16000});
        },
      ))
      ..register(Command(
        name: 'pipelineCloseMic',
        description: 'Close the delegated microphone and drop buffered audio',
        handler: (_) async {
          await _closeMic();
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'pipelineSetMuted',
        description:
            'Mute the delegated capture: chunks are dropped on arrival, '
            'never buffered — the wake chime must not reach STT. The page '
            'brackets its chime window with this.',
        params: const {'muted': 'true to drop mic chunks'},
        handler: (p) async {
          _muted = p['muted'] == true;
          if (_muted) _publishLevel(0, force: true);
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'pipelineStartBuffering',
        description:
            'Capture mic chunks into the buffer before sending starts (the '
            'seamless one-shot window between wake word and STT stream)',
        params: const {'reset': 'true to clear the buffer first'},
        handler: (p) async {
          if (p['reset'] == true) _buffer.clear();
          _buffering = true;
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'pipelineStopBuffering',
        description: 'Stop capturing into the buffer',
        params: const {'clear': 'true to drop what was buffered'},
        handler: (p) async {
          _buffering = false;
          if (p['clear'] == true) _buffer.clear();
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'pipelineClearBuffer',
        description:
            'Drop buffered audio (the page clears stale audio before '
            'resuming the stream after its chime)',
        handler: (_) async {
          _buffer.clear();
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'pipelineRun',
        description:
            'Subscribe a voice_satellite/run_pipeline run on the app\'s own '
            'Home Assistant websocket. Every subscription event (init, '
            'run-start, stt partials, tts-end, errors) is forwarded into '
            'the page as kiosksatellite:pipeline events; the binary STT '
            'audio upload happens natively and never touches the page.',
        params: const {
          'entity_id': 'satellite entity the run belongs to',
          'start_stage': 'wake_word | stt | intent',
          'end_stage': 'usually tts',
          'sample_rate': 'STT sample rate (16000)',
        },
        handler: (p) async {
          if (!_enabled) return const CommandResult.fail('native pipeline off');
          try {
            final runId = await _startRun(p);
            return CommandResult.ok({'runId': runId});
          } catch (e) {
            log.warn(name, 'run failed to start: $e');
            return CommandResult.fail('$e');
          }
        },
      ))
      ..register(Command(
        name: 'pipelineStop',
        description: 'Unsubscribe the delegated run and stop its audio',
        params: const {'runId': 'the run to stop'},
        handler: (p) async {
          await _stopRun(p['runId'] as String?);
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'pipelineStartSending',
        description:
            'Start uploading audio into the active run: buffered chunks '
            'first, then live. Waits out the init event internally — frames '
            'sent before the handler ID exists would be dropped anyway.',
        params: const {'runId': 'the run the audio belongs to'},
        handler: (p) async {
          final runId = p['runId'] as String?;
          if (runId != null && runId != _runId) {
            return const CommandResult.fail('stale run');
          }
          _sending = true;
          _startPump();
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'pipelineStopSending',
        description: 'Pause the audio upload (the chime window does this)',
        handler: (_) async {
          _sending = false;
          _stopPump();
          return const CommandResult.ok();
        },
      ));
  }

  // ── Audio path ───────────────────────────────────────────────────────

  void _onChunk(Uint8List pcm, bool preRoll) {
    // Page parity (audio/index.js kiosk branch): muted chunks are dropped
    // on the floor — buffering them would put the wake chime into the STT
    // recording. The bar was already zeroed when the mute command landed.
    if (_muted) return;
    if (_sending || _buffering) _buffer.add(pcm);
    // Pre-roll is past audio: the pipeline wants it, the bar must not
    // render it (it would trail live speech by the pre-roll's length).
    if (preRoll) return;
    _publishLevel(_speechLevel(pcm));
  }

  Future<void> _closeMic() async {
    if (!_micOpen) return;
    _micOpen = false;
    await _mic.closeNativeAudioStream();
    _sending = false;
    _buffering = false;
    _stopPump();
    _buffer.clear();
    _levelBatch.clear();
    _lp180 = 0;
    _lp3400 = 0;
  }

  void _startPump() {
    _pump ??= Timer.periodic(const Duration(milliseconds: 100), (_) => _drain());
    _drain();
  }

  void _stopPump() {
    _pump?.cancel();
    _pump = null;
  }

  void _drain() {
    if (!_sending || _buffer.isEmpty) return;
    final channel = _channel;
    final handlerId = _handlerId;
    // No handler yet (init still in flight): keep buffering, exactly like
    // the page's send loop skips while its handler-id getter returns null.
    if (channel == null || !_authed || handlerId == null) return;
    for (final pcm in _buffer) {
      final frame = Uint8List(pcm.length + 1);
      frame[0] = handlerId;
      frame.setRange(1, frame.length, pcm);
      channel.sink.add(frame);
    }
    _buffer.clear();
  }

  /// The page's pushMicPcm math (audio/analyser.js), so the reactive bar
  /// renders the same level it would have computed from the raw chunk:
  /// mean |amplitude| shaped by a speech-band weight from two one-pole
  /// band splits at 180 Hz and 3.4 kHz.
  double _speechLevel(Uint8List pcm) {
    final n = pcm.length ~/ 2;
    if (n == 0) return 0;
    final data = pcm.buffer.asByteData(pcm.offsetInBytes, pcm.length);
    var l180 = _lp180;
    var l3400 = _lp3400;
    const a180 = 0.9318;
    const a3400 = 0.2628;
    var sumAll = 0.0, sumLow = 0.0, sumMid = 0.0;
    for (var i = 0; i < n; i++) {
      final x = data.getInt16(i * 2, Endian.little) / 32768.0;
      l180 = a180 * l180 + (1 - a180) * x;
      l3400 = a3400 * l3400 + (1 - a3400) * x;
      sumAll += x.abs();
      sumLow += l180.abs();
      sumMid += l3400.abs();
    }
    _lp180 = l180;
    _lp3400 = l3400;
    final all = sumAll / n;
    final low = sumLow / n;
    final mid = sumMid / n;
    final voice = math.max(0.0, mid - low);
    final air = math.max(0.0, all - mid);
    final ratio = voice / math.max(1e-4, low + air + voice);
    final weight = (ratio * 1.2).clamp(0.18, 1.0);
    return all * weight;
  }

  void _publishLevel(double level, {bool force = false}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (force) {
      // Immediate, batch discarded: a mute must zero the bar NOW, not a
      // batch window from now with stale levels replaying after it.
      _levelBatch.clear();
      bus.publish(PipelineMicLevel(level: level));
      return;
    }
    // A batch left over from a stream that stopped mid-window would replay
    // old audio's shape at the front of the next turn; start clean instead.
    if (_levelBatch.isNotEmpty &&
        now - _levelBatchStartMs > _levelBatchWindowMs * 4) {
      _levelBatch.clear();
    }
    if (_levelBatch.isEmpty) _levelBatchStartMs = now;
    _levelBatch.add({'o': now - _levelBatchStartMs, 'v': level});
    if (_levelBatch.length >= _levelBatchMax ||
        now - _levelBatchStartMs >= _levelBatchWindowMs) {
      bus.publish(PipelineMicLevel(level: level, levels: List.of(_levelBatch)));
      _levelBatch.clear();
    }
  }

  // ── Run lifecycle ────────────────────────────────────────────────────

  Future<String> _startRun(Map<String, Object?> params) async {
    if (!await _ensureConnected()) {
      throw StateError('Home Assistant websocket unavailable');
    }
    // A stale run the page never stopped (its defensive cleanup normally
    // unsubscribes first) must not keep consuming the subscription id.
    if (_runId != null) await _stopRun(_runId);

    final subscribe = <String, Object?>{
      'type': 'voice_satellite/run_pipeline',
      for (final key in const [
        'entity_id',
        'start_stage',
        'end_stage',
        'sample_rate',
        'conversation_id',
        'extra_system_prompt',
        'wake_word_phrase',
        'wake_word_slot',
        'intent_input',
        'pipeline_id',
      ])
        if (params[key] != null) key: params[key],
    };

    final id = _nextId++;
    final runId = 'run-${++_runCounter}';
    // Registered before the result arrives: the init event can beat it.
    _runSubId = id;
    _runId = runId;
    _handlerId = null;
    try {
      await _send(id, subscribe);
    } catch (e) {
      _runSubId = null;
      _runId = null;
      rethrow;
    }
    log.info(name, 'run $runId subscribed (${subscribe['start_stage']} → '
        '${subscribe['end_stage']})');
    return runId;
  }

  Future<void> _stopRun(String? runId) async {
    if (runId == null || runId != _runId) return;
    final subId = _runSubId;
    _runId = null;
    _runSubId = null;
    _handlerId = null;
    _sending = false;
    _stopPump();
    if (subId != null && _channel != null && _authed) {
      try {
        await _send(_nextId++, {'type': 'unsubscribe_events', 'subscription': subId});
      } catch (e) {
        log.debug(name, 'unsubscribe failed (socket likely gone): $e');
      }
    }
    log.info(name, 'run $runId stopped');
  }

  // ── Socket ───────────────────────────────────────────────────────────

  Future<bool> _ensureConnected() {
    if (_channel != null && _authed) return Future.value(true);
    return _connecting ??= _connect().whenComplete(() => _connecting = null);
  }

  Future<bool> _connect() async {
    _closeSocket('reconnecting', quiet: true);
    final base = _settings
        .get(defs.haUrl)
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final authed = Completer<bool>();
    try {
      final channel = _channelFactory(Uri.parse('$base/api/websocket'));
      _channel = channel;
      _channelSub = channel.stream.listen(
        (raw) => _onFrame(raw, channel, authed),
        onError: (Object e) {
          log.warn(name, 'socket error: $e');
          if (!authed.isCompleted) authed.complete(false);
        },
        onDone: () {
          if (!authed.isCompleted) authed.complete(false);
          if (identical(_channel, channel)) _onSocketDead('socket closed');
        },
        cancelOnError: true,
      );
    } catch (e) {
      log.warn(name, 'connect failed: $e');
      return false;
    }
    final ok = await authed.future
        .timeout(const Duration(seconds: 10), onTimeout: () => false);
    if (!ok) _closeSocket('auth failed', quiet: true);
    return ok;
  }

  void _onFrame(dynamic raw, WebSocketChannel channel, Completer<bool> authed) {
    if (raw is! String) return; // no binary frames arrive on this socket
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      log.warn(name, 'frame ignored: $e');
      return;
    }
    switch (msg['type']) {
      case 'auth_required':
        channel.sink.add(jsonEncode({
          'type': 'auth',
          'access_token': _settings.get(defs.haToken),
        }));
      case 'auth_ok':
        _authed = true;
        log.info(name, 'websocket authenticated');
        if (!authed.isCompleted) authed.complete(true);
      case 'auth_invalid':
        log.warn(name, 'websocket rejected: bad token');
        if (!authed.isCompleted) authed.complete(false);
      case 'result':
        final completer = _pending.remove(msg['id']);
        if (completer == null) return;
        if (msg['success'] == true) {
          completer.complete(msg['result']);
        } else {
          completer.completeError(StateError('${msg['error']}'));
        }
      case 'event':
        if (msg['id'] != _runSubId) return;
        final event = msg['event'];
        if (event is! Map) return;
        final payload = event.cast<String, Object?>();
        // The synthetic init event carries the binary handler ID the
        // upload frames are prefixed with. Forwarded too: the page's
        // pipeline code keys its own bookkeeping off it.
        if (payload['type'] == 'init') {
          _handlerId = (payload['handler_id'] as num?)?.toInt();
          log.info(name, 'run $_runId init (handler ${_handlerId ?? '?'})');
        }
        final runId = _runId;
        if (runId != null) {
          bus.publish(PipelineEvent(runId: runId, message: payload));
        }
    }
  }

  Future<Object?> _send(int id, Map<String, Object?> command) {
    final channel = _channel;
    if (channel == null || !_authed) {
      return Future.error(StateError('not connected'));
    }
    final completer = Completer<Object?>();
    _pending[id] = completer;
    channel.sink.add(jsonEncode({'id': id, ...command}));
    return completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
      _pending.remove(id);
      throw TimeoutException('command $id timed out');
    });
  }

  /// The socket died underneath us. A run in flight cannot be resumed
  /// (subscriptions die with their connection): tell the page so its
  /// pipeline recovery restarts the turn, exactly like its dashboard-socket
  /// reconnect handler does.
  void _onSocketDead(String reason) {
    final runId = _runId;
    _closeSocket(reason, quiet: true);
    if (runId != null) {
      log.warn(name, 'socket died with run $runId active ($reason)');
      _runId = null;
      _runSubId = null;
      _handlerId = null;
      _sending = false;
      _stopPump();
      bus.publish(PipelineClosed(runId: runId, reason: reason));
    }
  }

  void _closeSocket(String reason, {bool quiet = false}) {
    final channel = _channel;
    if (channel == null) return;
    if (!quiet) log.info(name, 'closing websocket ($reason)');
    _channel = null;
    _authed = false;
    _channelSub?.cancel();
    _channelSub = null;
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('socket closed: $reason'));
      }
    }
    _pending.clear();
    try {
      channel.sink.close();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await _closeMic();
    _closeSocket('dispose', quiet: true);
  }
}
