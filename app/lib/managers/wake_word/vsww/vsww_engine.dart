import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../../../core/logging.dart';
import '../engine.dart';
import 'model_store.dart';
import 'native_mic.dart';
import 'vsww_isolate.dart';

/// One mic chunk in the pre-roll ring, tagged with the absolute sample index
/// it starts at so it can be sliced at a wake-word boundary.
class _PreRollChunk {
  _PreRollChunk(this.startSample, this.bytes);
  final int startSample;
  final Uint8List bytes;

  int get endSample => startSample + bytes.length ~/ 2;

  /// The part of this chunk at or after [sample], or null if it is all older.
  Uint8List? after(int sample) {
    if (endSample <= sample) return null;
    if (startSample >= sample) return bytes;
    return Uint8List.sublistView(bytes, (sample - startSample) * 2);
  }
}

/// Native vsWakeWord engine (main-isolate controller).
///
/// The heavy pipeline — ring buffer, log-mel features, ONNX inference,
/// CTC decode/match, detection gate — runs in a dedicated compute isolate
/// ([vswwIsolateEntry]) so it never touches the UI/platform isolate (no
/// WebView jank) and can use synchronous ONNX inference (no per-call thread
/// hops). This controller downloads the models, owns the mic EventChannel,
/// forwards raw PCM to the isolate, and surfaces detections.
///
/// Native inference is the whole point of the handoff: the ONNX runs natively
/// instead of the WebGPU/WASM JS runner in the WebView.
class VswwEngine extends WakeWordEngine {
  VswwEngine(this._log, {ModelStoreFactory? storeFactory})
      : _store = (storeFactory ?? VswwModelStore.new)();

  final Logger _log;
  final VswwModelStore _store;
  final _mic = NativeMic();

  bool _running = false;

  /// Detection paused (during a voice turn) — the mic stays open and the
  /// models stay loaded; we just stop feeding the detector.
  bool _detectionPaused = false;

  /// Streaming captured audio to the page (the card uses us instead of
  /// getUserMedia during a turn).
  void Function(Uint8List pcm, bool preRoll)? _onAudioChunk;

  /// Recent mic chunks kept so a stream can start in the past: covers the gap
  /// between the wake firing and the card asking for audio, so speech right
  /// after the wake word isn't clipped. 8 x 80 ms = 640 ms.
  static const _preRollChunks = 8;
  final List<_PreRollChunk> _preRoll = [];

  /// Samples seen from the mic. The shared clock between us and the compute
  /// isolate: a detection reports the absolute sample the wake word ended on,
  /// which indexes straight into [_preRoll].
  int _absSamples = 0;

  /// Absolute sample the audio stream should start from after a detection: the
  /// sample the wake word ended on. Null when the stream is not opening off the
  /// back of a detection (a manual wake, start_conversation), where there is no
  /// wake word to trim away and the full pre-roll is the useful answer.
  int? _wakeEndSample;

  Isolate? _isolate;
  SendPort? _isolatePort;
  ReceivePort? _fromIsolate;
  StreamSubscription<Uint8List>? _audioSub;
  DetectionCallback? _onDetection;
  StopDetectionCallback? _onStopDetection;

  /// The stop classifier is loaded and can be armed.
  bool _hasStopModel = false;

  /// Stop classifier currently listening (an interruptible state is running).
  bool _stopArmed = false;
  Completer<bool>? _ready;
  Completer<void>? _stopped;

  @override
  Set<WakeWordEngineType> get supportedEngines =>
      const {WakeWordEngineType.vsWakeWord};

  @override
  bool get supportsStopWord => _hasStopModel;

  @override
  bool get running => _running;

  @override
  Future<void> start({
    required WakeWordConfig config,
    required DetectionCallback onDetection,
    StopDetectionCallback? onStopDetection,
  }) async {
    if (_running) return;
    if (config.engine != WakeWordEngineType.vsWakeWord) return;
    _onDetection = onDetection;
    _onStopDetection = onStopDetection;

    // Download models on the main isolate (needs http + path_provider).
    final models = <Map<String, Object>>[];
    for (final ref in config.models) {
      try {
        final model = await _store.fetch(ref.manifestUrl);
        models.add({
          'id': ref.id,
          'wakeWord': ref.wakeWord,
          'manifestJson': model.manifestJson,
          'onnx': model.onnxBytes,
        });
        _log.info('vsww', 'downloaded "${ref.id}" (${model.onnxBytes.length} bytes)');
      } catch (e) {
        _log.error('vsww', 'download "${ref.id}" failed: $e');
      }
    }

    // The stop classifier loads with the wake words but stays disarmed until
    // the card reports an interruptible state. A failure here is not fatal:
    // wake detection is still worth running without it.
    final stopRef = config.stopModel;
    if (stopRef != null) {
      try {
        final model = await _store.fetch(stopRef.manifestUrl);
        models.add({
          'id': stopRef.id,
          'wakeWord': stopRef.wakeWord,
          'manifestJson': model.manifestJson,
          'onnx': model.onnxBytes,
          'stop': true,
        });
        _hasStopModel = true;
        _log.info('vsww',
            'downloaded stop model "${stopRef.id}" (${model.onnxBytes.length} bytes)');
      } catch (e) {
        _log.error('vsww', 'download stop model "${stopRef.id}" failed: $e');
      }
    }
    if (models.isEmpty) {
      _log.warn('vsww', 'no models; not starting');
      return;
    }

    // Spawn the compute isolate and wait for its port + readiness.
    _ready = Completer<bool>();
    _fromIsolate = ReceivePort();
    _fromIsolate!.listen(_onIsolateMessage);
    _isolate = await Isolate.spawn(vswwIsolateEntry, _fromIsolate!.sendPort,
        onError: _fromIsolate!.sendPort, debugName: 'vsww');

    // _onIsolateMessage sends init once it has the isolate's port.
    _pendingInit = {'type': VswwMsg.init, 'models': models};

    final ready = await _ready!.future
        .timeout(const Duration(seconds: 20), onTimeout: () => false);
    if (!ready) {
      _log.error('vsww', 'isolate failed to become ready');
      await stop();
      return;
    }

    // The mic EventChannel stays on the main isolate; per chunk we hand the
    // raw bytes to the compute isolate (unless detection is paused), keep a
    // short pre-roll, and feed the page's audio stream when it wants one.
    _audioSub = _mic.stream().listen(
      _onMicChunk,
      onError: (Object e) => _log.warn('vsww', 'audio stream error: $e'),
    );
    _running = true;
    _log.info(
        'vsww',
        'listening (${config.models.length} wake word(s)'
        '${_hasStopModel ? ' + stop word' : ''}, isolate)');
  }

  Map<String, Object>? _pendingInit;

  void _onMicChunk(Uint8List bytes) {
    // Detection (skipped while a voice turn owns the audio). The stop word is
    // the exception: it only matters *during* a turn, so an armed stop
    // classifier keeps the audio flowing even with wake detection paused.
    if (!_detectionPaused || _stopArmed) _isolatePort?.send(bytes);
    // Pre-roll ring, so a stream can start slightly in the past.
    _preRoll.add(_PreRollChunk(_absSamples, bytes));
    _absSamples += bytes.length ~/ 2; // PCM16
    while (_preRoll.length > _preRollChunks) {
      _preRoll.removeAt(0);
    }
    // Live stream to the page.
    _onAudioChunk?.call(bytes, false);
  }

  @override
  Future<void> pauseDetection() async {
    if (_detectionPaused) return;
    _detectionPaused = true;
    _log.info('vsww', 'detection paused (mic stays open)');
  }

  @override
  Future<void> resumeDetection() async {
    if (!_detectionPaused) return;
    // Clear the isolate's audio window + detector state so speech from the
    // turn we just handled can't fire a stale detection, and re-sync its
    // sample clock: it stopped counting when we stopped feeding it.
    _isolatePort?.send({'type': VswwMsg.resume, 'absSample': _absSamples});
    _wakeEndSample = null;
    _detectionPaused = false;
    _log.info('vsww', 'detection re-armed');
  }

  @override
  Future<void> startAudioStream(
      void Function(Uint8List pcm, bool preRoll) onChunk) async {
    _onAudioChunk = onChunk;
    // Flush the pre-roll first so the caller gets the audio captured between
    // the wake word firing and this call, otherwise the start of the user's
    // command is lost. Flagged as pre-roll: it is past audio, so live
    // renderers must skip it (see AudioChunk.preRoll).
    //
    // Trimmed to start exactly where the wake word ended, which is the whole
    // trick behind one-shot phrases ("okay nabu turn off the lights"): every
    // sample of the command survives, and none of the wake word reaches STT to
    // be transcribed as part of it.
    final wakeEnd = _wakeEndSample;
    var samples = 0;
    for (final chunk in List<_PreRollChunk>.of(_preRoll)) {
      final pcm = wakeEnd == null ? chunk.bytes : chunk.after(wakeEnd);
      if (pcm == null || pcm.isEmpty) continue;
      samples += pcm.length ~/ 2;
      onChunk(pcm, true);
    }
    _log.info(
        'vsww',
        'audio stream started (${(samples / 16).round()}ms pre-roll'
        '${wakeEnd == null ? '' : ', trimmed to wake end'})');
  }

  @override
  Future<void> stopAudioStream() async {
    if (_onAudioChunk == null) return;
    _onAudioChunk = null;
    _log.info('vsww', 'audio stream stopped');
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
      _log.error('vsww', 'isolate error: ${msg.first}');
      _ready?.complete(false);
      return;
    }
    if (msg is! Map) return;
    switch (msg['type']) {
      case VswwMsg.ready:
        _ready?.complete(true);
      case VswwMsg.log:
        final message = '${msg['message']}';
        switch (msg['level']) {
          case 'error':
            _log.error('vsww', message);
          case 'warn':
            _log.warn('vsww', message);
          default:
            _log.info('vsww', message);
        }
      case VswwMsg.detection:
        _onDetectionMessage(msg);
      case VswwMsg.error:
        _log.error('vsww', 'isolate: ${msg['message']}');
        _ready?.complete(false);
      case VswwMsg.stopped:
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
    _wakeEndSample = msg['wakeEndSample'] as int? ?? _absSamples;
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
    _isolatePort?.send({'type': VswwMsg.armStop, 'active': active});
  }

  @override
  Future<void> stop() async {
    if (!_running && _isolate == null) return;
    _running = false;
    await _audioSub?.cancel();
    _audioSub = null;

    // Ask the isolate to release its ONNX sessions, then tear it down.
    if (_isolatePort != null) {
      _stopped = Completer<void>();
      _isolatePort!.send({'type': VswwMsg.stop});
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
    // these set would have us claim a stop model we no longer have loaded.
    _hasStopModel = false;
    _stopArmed = false;
    _detectionPaused = false;
    _wakeEndSample = null;
    _preRoll.clear();
  }
}

typedef ModelStoreFactory = VswwModelStore Function();
