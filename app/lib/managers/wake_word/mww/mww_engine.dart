import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../../../core/logging.dart';
import '../engine.dart';
import '../vsww/native_mic.dart';
import 'mww_isolate.dart';
import 'mww_model_store.dart';

/// One mic chunk in the pre-roll ring, tagged with the absolute sample index it
/// starts at so it can be sliced at a detection boundary.
class _PreRollChunk {
  _PreRollChunk(this.startSample, this.bytes);
  final int startSample;
  final Uint8List bytes;

  int get endSample => startSample + bytes.length ~/ 2;

  Uint8List? after(int sample) {
    if (endSample <= sample) return null;
    if (startSample >= sample) return bytes;
    return Uint8List.sublistView(bytes, (sample - startSample) * 2);
  }
}

/// Native microWakeWord engine (main-isolate controller).
///
/// Same shape as [VswwEngine]: the mic and the pre-roll ring live here, while
/// the feature frontend, TFLite invoke and detection gate run in a compute
/// isolate so they never touch the platform isolate.
///
/// NOTE: the mic ownership, pre-roll ring and delegated audio stream below are
/// duplicated from VswwEngine almost line for line. Both want the same base
/// class ("isolate engine that owns the mic"); they are kept separate for now
/// only to avoid restructuring the proven vsWakeWord path in the same change.
///
/// Unlike vsWakeWord this reports no wake-word *end*: microWakeWord is a
/// sliding-window classifier that knows only that the wake word occurred in the
/// recent window. The stream therefore starts at the detection instant, which
/// is never earlier than the wake word finished, so the wake word is still
/// never replayed into STT (see WakeWordEngine.startAudioStream).
class MwwEngine extends WakeWordEngine {
  MwwEngine(this._log, {MwwModelStore? store})
      : _store = store ?? MwwModelStore();

  final Logger _log;
  final MwwModelStore _store;
  final _mic = NativeMic();

  bool _running = false;
  bool _detectionPaused = false;

  /// The stop classifier is loaded and can be armed.
  bool _hasStopModel = false;

  /// Stop classifier currently listening (an interruptible state is running).
  bool _stopArmed = false;

  void Function(Uint8List pcm, bool preRoll)? _onAudioChunk;

  static const _preRollChunks = 8; // 8 x 80 ms = 640 ms
  final List<_PreRollChunk> _preRoll = [];

  int _absSamples = 0;
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
  Set<WakeWordEngineType> get supportedEngines =>
      const {WakeWordEngineType.microWakeWord};

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
    if (config.engine != WakeWordEngineType.microWakeWord) return;
    _onDetection = onDetection;
    _onStopDetection = onStopDetection;

    final models = <Map<String, Object>>[];
    for (final ref in config.models) {
      try {
        final model = await _store.fetch(ref.manifestUrl);
        models.add({
          'id': ref.id,
          'wakeWord': ref.wakeWord,
          'tflite': model.tfliteBytes,
          // The card resolved its Sensitivity setting into this multiplier; we
          // only apply it. Raising the cutoff makes the model harder to
          // trigger, which is what "Slightly sensitive" (x1.10) means.
          'cutoff': model.manifest.probabilityCutoff * ref.confidenceScale,
          'slidingWindowSize': model.manifest.slidingWindowSize,
        });
        _log.info('mww',
            'downloaded "${ref.id}" (${model.tfliteBytes.length} bytes)');
      } catch (e) {
        _log.error('mww', 'download "${ref.id}" failed: $e');
      }
    }
    // microWakeWord's stop classifier is just another mww model ('stop'), so it
    // loads exactly like a wake word and stays disarmed until the card reports
    // an interruptible state. Not fatal if it fails: wake detection is still
    // worth running.
    final stopRef = config.stopModel;
    if (stopRef != null) {
      try {
        final model = await _store.fetch(stopRef.manifestUrl);
        models.add({
          'id': stopRef.id,
          'wakeWord': stopRef.wakeWord,
          'tflite': model.tfliteBytes,
          'cutoff': model.manifest.probabilityCutoff * stopRef.confidenceScale,
          'slidingWindowSize': model.manifest.slidingWindowSize,
          'stop': true,
        });
        _hasStopModel = true;
        _log.info('mww',
            'downloaded stop model "${stopRef.id}" (${model.tfliteBytes.length} bytes)');
      } catch (e) {
        _log.error('mww', 'download stop model "${stopRef.id}" failed: $e');
      }
    }

    if (models.isEmpty) {
      _log.warn('mww', 'no models; not starting');
      return;
    }

    _ready = Completer<bool>();
    _fromIsolate = ReceivePort();
    _fromIsolate!.listen(_onIsolateMessage);
    _isolate = await Isolate.spawn(mwwIsolateEntry, _fromIsolate!.sendPort,
        onError: _fromIsolate!.sendPort, debugName: 'mww');

    _pendingInit = {
      'type': MwwMsg.init,
      'models': models,
      'energyGate': config.energyGate.toJson(),
    };

    final ready = await _ready!.future
        .timeout(const Duration(seconds: 20), onTimeout: () => false);
    if (!ready) {
      _log.error('mww', 'isolate failed to become ready');
      await stop();
      return;
    }

    _audioSub = _mic.stream().listen(
      _onMicChunk,
      onError: (Object e) => _log.warn('mww', 'audio stream error: $e'),
    );
    _running = true;
    _log.info(
        'mww',
        'listening (${config.models.length} wake word(s)'
        '${_hasStopModel ? ' + stop word' : ''}, isolate)');
  }

  void _onMicChunk(Uint8List bytes) {
    // The stop word only matters *during* a turn, so an armed stop classifier
    // keeps the audio flowing even with wake detection paused.
    if (!_detectionPaused || _stopArmed) _isolatePort?.send(bytes);
    _preRoll.add(_PreRollChunk(_absSamples, bytes));
    _absSamples += bytes.length ~/ 2; // PCM16
    while (_preRoll.length > _preRollChunks) {
      _preRoll.removeAt(0);
    }
    _onAudioChunk?.call(bytes, false);
  }

  @override
  Future<void> pauseDetection() async {
    if (_detectionPaused) return;
    _detectionPaused = true;
    _log.info('mww', 'detection paused (mic stays open)');
  }

  @override
  Future<void> resumeDetection() async {
    if (!_detectionPaused) return;
    _isolatePort?.send({'type': MwwMsg.resume, 'absSample': _absSamples});
    _wakeEndSample = null;
    _detectionPaused = false;
    _log.info('mww', 'detection re-armed');
  }

  @override
  Future<void> startAudioStream(
      void Function(Uint8List pcm, bool preRoll) onChunk) async {
    _onAudioChunk = onChunk;
    // Trimmed to the detection instant: a window classifier cannot say where
    // the wake word ended, so this gives up the audio between the wake word
    // finishing and detection settling. That is exactly the trade the card's
    // own browser path makes, and it never replays the wake word into STT.
    final wakeEnd = _wakeEndSample;
    var samples = 0;
    for (final chunk in List<_PreRollChunk>.of(_preRoll)) {
      final pcm = wakeEnd == null ? chunk.bytes : chunk.after(wakeEnd);
      if (pcm == null || pcm.isEmpty) continue;
      samples += pcm.length ~/ 2;
      onChunk(pcm, true);
    }
    _log.info(
        'mww',
        'audio stream started (${(samples / 16).round()}ms pre-roll'
        '${wakeEnd == null ? '' : ', trimmed to detection'})');
  }

  @override
  Future<void> stopAudioStream() async {
    if (_onAudioChunk == null) return;
    _onAudioChunk = null;
    _log.info('mww', 'audio stream stopped');
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
      _log.error('mww', 'isolate error: ${msg.first}');
      _ready?.complete(false);
      return;
    }
    if (msg is! Map) return;
    switch (msg['type']) {
      case MwwMsg.ready:
        _ready?.complete(true);
      case MwwMsg.log:
        final message = '${msg['message']}';
        switch (msg['level']) {
          case 'error':
            _log.error('mww', message);
          case 'warn':
            _log.warn('mww', message);
          default:
            _log.info('mww', message);
        }
      case MwwMsg.detection:
        _onDetectionMessage(msg);
      case MwwMsg.error:
        _log.error('mww', 'isolate: ${msg['message']}');
        _ready?.complete(false);
      case MwwMsg.stopped:
        _stopped?.complete();
    }
  }

  @override
  Future<void> setStopWordActive(bool active) async {
    if (!_hasStopModel || _stopArmed == active) return;
    _stopArmed = active;
    _isolatePort?.send({'type': MwwMsg.armStop, 'active': active});
  }

  Future<void> _onDetectionMessage(Map msg) async {
    if (msg['stop'] == true) {
      // Report only: the card decides what "stop" means and disarms us as part
      // of ending the interruptible state.
      await _onStopDetection?.call();
      return;
    }
    final ref = WakeWordModelRef(
      id: msg['id'] as String? ?? '',
      wakeWord: msg['wakeWord'] as String? ?? '',
      manifestUrl: '',
    );
    _wakeEndSample = msg['wakeEndSample'] as int? ?? _absSamples;
    // Keep the mic: we are the audio source for the turn the page is about to
    // run. Just stop detecting.
    await pauseDetection();
    await _onDetection?.call(ref);
  }

  @override
  Future<void> stop() async {
    if (!_running && _isolate == null) return;
    _running = false;
    await _audioSub?.cancel();
    _audioSub = null;

    if (_isolatePort != null) {
      _stopped = Completer<void>();
      _isolatePort!.send({'type': MwwMsg.stop});
      await _stopped!.future
          .timeout(const Duration(seconds: 2), onTimeout: () {});
    }
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _isolatePort = null;
    _fromIsolate?.close();
    _fromIsolate = null;
    _pendingInit = null;

    _detectionPaused = false;
    _wakeEndSample = null;
    _preRoll.clear();
    // Per-run state: a restart re-negotiates from the next config.
    _hasStopModel = false;
    _stopArmed = false;
  }
}
