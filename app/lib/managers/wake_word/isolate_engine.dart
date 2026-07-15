import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../../core/logging.dart';
import 'engine.dart';
import 'vsww/native_mic.dart';
import 'wake_msg.dart';

export 'wake_msg.dart' show WakeMsg;

/// One mic chunk, tagged with the absolute sample index it starts at so it can
/// be sliced at a wake-word boundary.
@visibleForTesting
class PreRollChunk {
  PreRollChunk(this.startSample, this.bytes);
  final int startSample;
  final Uint8List bytes;

  int get endSample => startSample + bytes.length ~/ 2; // PCM16

  /// The part of this chunk at or after [sample], or null if it is all older.
  Uint8List? after(int sample) {
    if (endSample <= sample) return null;
    if (startSample >= sample) return bytes;
    return Uint8List.sublistView(bytes, (sample - startSample) * 2);
  }
}

/// Recent mic audio, kept so a stream can start slightly in the past.
///
/// Covers the gap between the wake word firing and the card asking for audio,
/// so speech right after the wake word isn't clipped. Its sample counter is the
/// clock shared with the compute isolate: a detection reports the absolute
/// sample the wake word ended on, which indexes straight back into here.
class PreRollBuffer {
  PreRollBuffer({this.maxChunks = 8}); // 8 x 80 ms = 640 ms

  final int maxChunks;
  final List<PreRollChunk> _chunks = [];
  int _absSamples = 0;

  /// Samples seen from the mic since the last [reset].
  int get absSamples => _absSamples;

  void add(Uint8List bytes) {
    _chunks.add(PreRollChunk(_absSamples, bytes));
    _absSamples += bytes.length ~/ 2; // PCM16
    while (_chunks.length > maxChunks) {
      _chunks.removeAt(0);
    }
  }

  /// Buffered audio at or after [from], oldest first. A null [from] yields
  /// everything: nothing was detected, so there is no wake word to trim.
  List<Uint8List> flush(int? from) {
    final out = <Uint8List>[];
    for (final chunk in _chunks) {
      final pcm = from == null ? chunk.bytes : chunk.after(from);
      if (pcm != null && pcm.isNotEmpty) out.add(pcm);
    }
    return out;
  }

  /// Drop the audio *and* restart the clock at zero.
  ///
  /// Both halves matter. A compute isolate always starts counting from zero, so
  /// an engine whose clock kept running across a stop/start (the card's wake
  /// word tester does exactly that) would compare a detection's wake-end sample
  /// against pre-roll recorded millions of samples later, conclude every chunk
  /// was newer, and trim nothing — replaying the wake word into STT.
  void reset() {
    _chunks.clear();
    _absSamples = 0;
  }
}

/// The models to load, as handed to the compute isolate.
class WakeModelPayload {
  const WakeModelPayload({
    required this.models,
    this.hasStopModel = false,
    this.extraInit = const {},
  });

  /// Per-model init entries. Engine-specific apart from `id`/`wakeWord`, plus
  /// `stop: true` marking the stop classifier.
  final List<Map<String, Object>> models;

  /// The stop classifier loaded and can be armed.
  final bool hasStopModel;

  /// Extra init fields this engine needs (openWakeWord's shared stages).
  final Map<String, Object> extraInit;

  bool get isEmpty => models.isEmpty;
}

/// Opens the mic. Injectable so the engines are testable without a device.
typedef MicSource = Stream<Uint8List> Function();

/// Spawns the compute isolate; returns null if it did not really spawn one.
typedef IsolateSpawner = Future<Isolate?> Function(
    void Function(SendPort) entry, SendPort port, String debugName);

Future<Isolate?> _spawnIsolate(
        void Function(SendPort) entry, SendPort port, String debugName) =>
    Isolate.spawn(entry, port, onError: port, debugName: debugName);

/// A wake-word engine that owns the mic and runs its detector in a compute
/// isolate. The shared half of vsWakeWord, microWakeWord and openWakeWord.
///
/// The split is the point: inference must not run on the platform isolate (it
/// janks the WebView, which is the whole reason detection moved out of the
/// browser), while the mic EventChannel and the pre-roll ring must stay on it.
/// So this controller downloads models, owns the mic, forwards raw PCM to the
/// isolate, keeps the pre-roll, and surfaces detections; the subclass supplies
/// only what is actually engine-specific:
///
///  - [tag] / [engineType] / [isolateEntry] — identity
///  - [loadModels] — fetching and describing the models
///  - [wakeEndIsAligned] — whether it can locate where the wake word *ended*
///
/// Everything else here is the contract in [WakeWordEngine], and it is
/// deliberately implemented once: pre-roll trimming, the shared sample clock
/// and the delegated audio stream are the subtlest code in the wake path, and
/// three copies of it drifted (see the sample-clock reset in
/// [PreRollBuffer.reset]) before anyone noticed.
abstract class IsolateWakeEngine extends WakeWordEngine {
  IsolateWakeEngine(this.log, {MicSource? mic, IsolateSpawner? spawner})
      : _mic = mic ?? (() => NativeMic().stream()),
        _spawn = spawner ?? _spawnIsolate;

  @protected
  final Logger log;
  final MicSource _mic;
  final IsolateSpawner _spawn;

  /// Short name for logs and the isolate's debug name.
  @protected
  String get tag;

  /// The engine this subclass runs. One each; the manager picks by this.
  @protected
  WakeWordEngineType get engineType;

  /// Top-level entry point of the compute isolate.
  @protected
  void Function(SendPort) get isolateEntry;

  /// Download the models and describe them for the isolate. Returning null (or
  /// an empty payload) aborts the start.
  @protected
  Future<WakeModelPayload?> loadModels(WakeWordConfig config);

  /// True when a detection's `wakeEndSample` is the sample the wake word
  /// actually ended on rather than the detection instant. Only vsWakeWord can
  /// say (its CTC decode aligns the match); the window classifiers cannot.
  /// Diagnostic only — see [startAudioStream] for why the distinction is a
  /// quality difference and not a correctness one.
  @protected
  bool get wakeEndIsAligned => false;

  final _preRoll = PreRollBuffer();

  bool _running = false;

  /// Detection paused (during a voice turn) — the mic stays open and the models
  /// stay loaded; we just stop feeding the detector.
  bool _detectionPaused = false;

  /// The stop classifier is loaded and can be armed.
  bool _hasStopModel = false;

  /// Stop classifier currently listening (an interruptible state is running).
  bool _stopArmed = false;

  /// Streaming captured audio to the page (the card uses us instead of
  /// getUserMedia during a turn).
  void Function(Uint8List pcm, bool preRoll)? _onAudioChunk;

  /// Absolute sample the audio stream should start from after a detection.
  /// Null when the stream is not opening off the back of a detection (a manual
  /// wake, start_conversation), where there is no wake word to trim away and
  /// the full pre-roll is the useful answer.
  int? _wakeEndSample;

  Isolate? _isolate;
  SendPort? _isolatePort;
  ReceivePort? _fromIsolate;
  StreamSubscription<Uint8List>? _audioSub;
  DetectionCallback? _onDetection;
  StopDetectionCallback? _onStopDetection;
  Completer<bool>? _ready;
  Completer<void>? _stopped;
  Map<String, Object>? _pendingInit;

  @override
  Set<WakeWordEngineType> get supportedEngines => {engineType};

  @override
  bool get running => _running;

  @override
  bool get supportsStopWord => _hasStopModel;

  @override
  Future<void> start({
    required WakeWordConfig config,
    required DetectionCallback onDetection,
    StopDetectionCallback? onStopDetection,
  }) async {
    if (_running) return;
    if (config.engine != engineType) return;
    _onDetection = onDetection;
    _onStopDetection = onStopDetection;

    // Models are downloaded here, on the main isolate: http and path_provider
    // are platform channels and only work on the isolate that owns them.
    final payload = await loadModels(config);
    if (payload == null || payload.isEmpty) {
      log.warn(tag, 'no models; not starting');
      return;
    }
    _hasStopModel = payload.hasStopModel;

    _ready = Completer<bool>();
    _fromIsolate = ReceivePort();
    _fromIsolate!.listen(_onIsolateMessage);
    _isolate = await _spawn(isolateEntry, _fromIsolate!.sendPort, tag);

    // _onIsolateMessage sends this once it has the isolate's port.
    _pendingInit = {
      'type': WakeMsg.init,
      'models': payload.models,
      'energyGate': config.energyGate.toJson(),
      ...payload.extraInit,
    };

    final ready = await _ready!.future
        .timeout(const Duration(seconds: 20), onTimeout: () => false);
    if (!ready) {
      log.error(tag, 'isolate failed to become ready');
      await stop();
      return;
    }

    // The mic EventChannel stays on the main isolate; per chunk we hand the raw
    // bytes to the compute isolate (unless detection is paused), keep a short
    // pre-roll, and feed the page's audio stream when it wants one.
    _audioSub = _mic().listen(
      _onMicChunk,
      onError: (Object e) => log.warn(tag, 'audio stream error: $e'),
    );
    _running = true;
    log.info(
        tag,
        'listening (${config.models.length} wake word(s)'
        '${_hasStopModel ? ' + stop word' : ''}, isolate)');
  }

  void _onMicChunk(Uint8List bytes) {
    // Detection (skipped while a voice turn owns the audio). The stop word is
    // the exception: it only matters *during* a turn, so an armed stop
    // classifier keeps the audio flowing even with wake detection paused.
    if (!_detectionPaused || _stopArmed) _isolatePort?.send(bytes);
    _preRoll.add(bytes);
    // Live stream to the page.
    _onAudioChunk?.call(bytes, false);
  }

  @override
  Future<void> pauseDetection() async {
    if (_detectionPaused) return;
    _detectionPaused = true;
    log.info(tag, 'detection paused (mic stays open)');
  }

  @override
  Future<void> resumeDetection() async {
    if (!_detectionPaused) return;
    // Clear the isolate's audio window + detector state so speech from the turn
    // we just handled can't fire a stale detection, and re-sync its sample
    // clock: it stopped counting when we stopped feeding it.
    _isolatePort
        ?.send({'type': WakeMsg.resume, 'absSample': _preRoll.absSamples});
    _wakeEndSample = null;
    _detectionPaused = false;
    log.info(tag, 'detection re-armed');
  }

  @override
  Future<void> startAudioStream(
      void Function(Uint8List pcm, bool preRoll) onChunk) async {
    _onAudioChunk = onChunk;
    // Flush the pre-roll first so the caller gets the audio captured between
    // the wake word firing and this call, otherwise the start of the user's
    // command is lost. Flagged as pre-roll: it is past audio, so live renderers
    // must skip it (see AudioChunk.preRoll).
    //
    // Trimmed so the wake word itself never reaches STT, which is what makes
    // one-shot phrases work ("okay nabu turn off the lights"): to the wake end
    // when the engine can align it, otherwise to the detection instant.
    final wakeEnd = _wakeEndSample;
    var samples = 0;
    for (final pcm in _preRoll.flush(wakeEnd)) {
      samples += pcm.length ~/ 2;
      onChunk(pcm, true);
    }
    log.info(
        tag,
        'audio stream started (${(samples / 16).round()}ms pre-roll'
        '${wakeEnd == null ? '' : ', trimmed to '
            '${wakeEndIsAligned ? 'wake end' : 'detection'}'})');
  }

  @override
  Future<void> stopAudioStream() async {
    if (_onAudioChunk == null) return;
    _onAudioChunk = null;
    log.info(tag, 'audio stream stopped');
  }

  void _onIsolateMessage(dynamic msg) {
    if (msg is SendPort) {
      _isolatePort = msg;
      if (_pendingInit != null) {
        _isolatePort!.send(_pendingInit);
        _pendingInit = null;
      }
      return;
    }
    if (msg is List) {
      // uncaught isolate error: [error, stackTrace]
      log.error(tag, 'isolate error: ${msg.first}');
      _ready?.complete(false);
      return;
    }
    if (msg is! Map) return;
    switch (msg['type']) {
      case WakeMsg.ready:
        _ready?.complete(true);
      case WakeMsg.log:
        final message = '${msg['message']}';
        switch (msg['level']) {
          case 'error':
            log.error(tag, message);
          case 'warn':
            log.warn(tag, message);
          default:
            log.info(tag, message);
        }
      case WakeMsg.detection:
        _onDetectionMessage(msg);
      case WakeMsg.error:
        log.error(tag, 'isolate: ${msg['message']}');
        _ready?.complete(false);
      case WakeMsg.stopped:
        _stopped?.complete();
    }
  }

  Future<void> _onDetectionMessage(Map msg) async {
    if (msg['stop'] == true) {
      // Report only. The card decides what "stop" means and disarms us as part
      // of ending the interruptible state; unlike a wake word, the stop
      // classifier does not suspend itself (Voice Satellite's own engine
      // behaves the same way, see WakeWordManager._onStopDetection).
      await _onStopDetection?.call();
      return;
    }
    final ref = WakeWordModelRef(
      id: msg['id'] as String? ?? '',
      wakeWord: msg['wakeWord'] as String? ?? '',
      manifestUrl: '',
    );
    // Fall back to "now": an engine that cannot align its match still must not
    // replay the wake word, and detection never precedes the wake word ending.
    _wakeEndSample = msg['wakeEndSample'] as int? ?? _preRoll.absSamples;
    // Keep the mic open — we are the audio source for the turn (the card
    // streams PCM from us instead of opening its own mic, which is what makes
    // wake -> STT instant and loses no speech). Just stop detecting.
    await pauseDetection();
    await _onDetection?.call(ref);
  }

  @override
  Future<void> setStopWordActive(bool active) async {
    if (!_hasStopModel || _stopArmed == active) return;
    _stopArmed = active;
    _isolatePort?.send({'type': WakeMsg.armStop, 'active': active});
  }

  @override
  Future<void> stop() async {
    if (!_running && _isolate == null) return;
    _running = false;
    await _audioSub?.cancel();
    _audioSub = null;

    // Ask the isolate to release its models, then tear it down.
    if (_isolatePort != null) {
      _stopped = Completer<void>();
      _isolatePort!.send({'type': WakeMsg.stop});
      await _stopped!.future
          .timeout(const Duration(seconds: 2), onTimeout: () {});
    }
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _isolatePort = null;
    _fromIsolate?.close();
    _fromIsolate = null;
    _pendingInit = null;

    // Per-run state: a restart re-negotiates from the next config, so leaving
    // these set would have us claim a stop model we no longer have loaded, and
    // the clock must restart with the next isolate's.
    _hasStopModel = false;
    _stopArmed = false;
    _detectionPaused = false;
    _wakeEndSample = null;
    _preRoll.reset();
  }
}
