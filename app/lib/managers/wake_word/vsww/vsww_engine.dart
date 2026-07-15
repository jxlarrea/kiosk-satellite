import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../../../core/logging.dart';
import '../engine.dart';
import 'model_store.dart';
import 'native_mic.dart';
import 'vsww_isolate.dart';

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
  Isolate? _isolate;
  SendPort? _isolatePort;
  ReceivePort? _fromIsolate;
  StreamSubscription<Uint8List>? _audioSub;
  DetectionCallback? _onDetection;
  Completer<bool>? _ready;
  Completer<void>? _stopped;

  @override
  Set<WakeWordEngineType> get supportedEngines =>
      const {WakeWordEngineType.vsWakeWord};

  @override
  bool get running => _running;

  @override
  Future<void> start({
    required WakeWordConfig config,
    required DetectionCallback onDetection,
  }) async {
    if (_running) return;
    if (config.engine != WakeWordEngineType.vsWakeWord) return;
    _onDetection = onDetection;

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

    // Forward mic audio to the isolate. The mic EventChannel stays on the
    // main isolate; per chunk we just hand the raw bytes across.
    _audioSub = _mic.stream().listen(
      (bytes) => _isolatePort?.send(bytes),
      onError: (Object e) => _log.warn('vsww', 'audio stream error: $e'),
    );
    _running = true;
    _log.info('vsww', 'listening (${models.length} wake word(s), isolate)');
  }

  Map<String, Object>? _pendingInit;

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
    final ref = WakeWordModelRef(
      id: msg['id'] as String? ?? '',
      wakeWord: msg['wakeWord'] as String? ?? '',
      manifestUrl: '',
    );
    // Release the mic immediately so the WebView can open getUserMedia for STT.
    await _audioSub?.cancel();
    _audioSub = null;
    // The manager's callback stops us and fires the wake-word event.
    await _onDetection?.call(ref);
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
  }
}

typedef ModelStoreFactory = VswwModelStore Function();
