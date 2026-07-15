import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:onnxruntime/onnxruntime.dart';

import '../../../core/logging.dart';
import '../engine.dart';
import 'ctc_decoder.dart';
import 'detection_gate.dart';
import 'log_mel.dart';
import 'manifest.dart';
import 'model_store.dart';
import 'native_mic.dart';
import 'ort_init.dart';
import 'stream_matcher.dart';

/// One loaded wake word: ONNX session + its decode/stream/gate state.
class _Keyword {
  _Keyword(this.ref, this.model, this.session, this.inputName, this.decoder,
      this.stream, this.gate);

  final WakeWordModelRef ref;
  final VswwModel model;
  final OrtSession session;
  final String inputName;
  final CtcDecoder decoder;
  final StreamMatcher stream;
  final DetectionGate gate;
}

/// Native vsWakeWord engine. Captures 16 kHz mono audio, runs the log-mel →
/// TCResNet-CTC ONNX → phoneme-decode → match → gate pipeline for each
/// configured wake word, and fires [DetectionCallback] on a hit.
///
/// Native inference is the whole point of the handoff: the ONNX runs on the
/// CPU (NNAPI-eligible) instead of the WebGPU/WASM JS runner in the WebView.
class VswwEngine extends WakeWordEngine {
  VswwEngine(this._log, {ModelStoreFactory? storeFactory})
      : _store = (storeFactory ?? VswwModelStore.new)();

  final Logger _log;
  final VswwModelStore _store;
  final _mic = NativeMic();

  static const _chunkSamples = 1280; // 80 ms @ 16 kHz
  static const _windowRmsVeto = 0.002; // hard-silence veto

  bool _running = false;
  StreamSubscription<Uint8List>? _audioSub;
  DetectionCallback? _onDetection;

  final List<_Keyword> _keywords = [];
  LogMelExtractor? _extractor;
  VswwFeatureConfig? _feature;

  // rolling window ring buffer
  Float32List? _ring;
  Float32List? _scratch;
  int _head = 0;
  int _filled = 0;

  final _pendingBytes = BytesBuilder(copy: false);
  final _chunkBuf = Float32List(_chunkSamples);
  int _samplesSinceInfer = 0;
  bool _inferring = false;
  int _epochMs = 0;

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

    ensureOrtInit();

    // Load each wake word (download + compile ONNX + build pipeline).
    for (final ref in config.models) {
      try {
        final model = await _store.fetch(ref.manifestUrl);
        final opts = OrtSessionOptions();
        final session = OrtSession.fromBuffer(model.onnxBytes, opts);
        final inputName = session.inputNames.first;
        final decoder = CtcDecoder(model.manifest.ctc);
        final stream = StreamMatcher(model.manifest, decoder);
        final gate = DetectionGate(model.manifest.runtime);
        _keywords.add(_Keyword(
            ref, model, session, inputName, decoder, stream, gate));
        _feature ??= model.manifest.feature;
        _log.info('vsww', 'loaded "${ref.id}" (${model.onnxBytes.length} bytes)');
      } catch (e) {
        _log.error('vsww', 'failed to load "${ref.id}": $e');
      }
    }
    if (_keywords.isEmpty) {
      _log.warn('vsww', 'no wake words loaded; not starting capture');
      return;
    }

    final feature = _feature!;
    _extractor = LogMelExtractor(feature);
    _ring = Float32List(feature.windowSamples);
    _scratch = Float32List(feature.windowSamples);
    _head = 0;
    _filled = 0;
    _samplesSinceInfer = 0;
    _epochMs = 0;

    _audioSub = _mic.stream().listen(_onAudio, onError: (Object e) {
      _log.warn('vsww', 'audio stream error: $e');
    });
    _running = true;
    _log.info('vsww', 'listening (${_keywords.length} wake word(s))');
  }

  @override
  Future<void> stop() async {
    if (!_running && _audioSub == null) return;
    _running = false;
    // Cancelling the subscription releases the native AudioRecord (mic_stream),
    // freeing the mic for the WebView's getUserMedia during STT.
    await _audioSub?.cancel();
    _audioSub = null;
    for (final k in _keywords) {
      k.session.release();
    }
    _keywords.clear();
    _extractor = null;
    _ring = null;
    _scratch = null;
    _pendingBytes.clear();
  }

  // ── Audio → chunks ─────────────────────────────────────────────────
  void _onAudio(Uint8List bytes) {
    if (!_running) return;
    _pendingBytes.add(bytes);
    // Need 2 bytes per sample; process whole 1280-sample chunks.
    var buf = _pendingBytes.toBytes();
    const chunkBytes = _chunkSamples * 2;
    var offset = 0;
    while (buf.length - offset >= chunkBytes) {
      final view = ByteData.sublistView(buf, offset, offset + chunkBytes);
      for (var i = 0; i < _chunkSamples; i++) {
        _chunkBuf[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
      }
      offset += chunkBytes;
      _ingestChunk(_chunkBuf);
    }
    // keep leftover bytes
    _pendingBytes.clear();
    if (offset < buf.length) {
      _pendingBytes.add(Uint8List.sublistView(buf, offset));
    }
  }

  void _ingestChunk(Float32List chunk) {
    final ring = _ring;
    if (ring == null) return;
    final n = ring.length;
    for (var i = 0; i < chunk.length; i++) {
      ring[_head] = chunk[i];
      _head = (_head + 1) % n;
    }
    if (_filled < n) _filled = math.min(n, _filled + chunk.length);
    _samplesSinceInfer += chunk.length;
    _epochMs += 80; // one chunk = 80 ms

    if (_filled >= n && !_inferring) {
      unawaited(_runInference());
    }
  }

  // ── Inference step ─────────────────────────────────────────────────
  Future<void> _runInference() async {
    final ring = _ring, scratch = _scratch, extractor = _extractor;
    if (ring == null || scratch == null || extractor == null) return;
    _inferring = true;
    final newSamples = _samplesSinceInfer;
    _samplesSinceInfer = 0;
    final nowMs = _epochMs;
    try {
      final n = ring.length;
      for (var i = 0; i < n; i++) {
        scratch[i] = ring[(_head + i) % n];
      }
      // energy veto
      var sumSq = 0.0;
      for (var i = 0; i < n; i++) {
        sumSq += scratch[i] * scratch[i];
      }
      final windowRms = math.sqrt(sumSq / n);
      final silent = windowRms < _windowRmsVeto;

      final features = extractor.extract(scratch);
      final feat = _feature!;
      final inputShape = [1, feat.frames, feat.nMels];

      for (final k in _keywords) {
        final tOut = k.model.manifest.tOut;
        final vocab = k.model.manifest.ctc.vocabSize;
        final logits = await _run(k, features, inputShape, tOut, vocab);
        if (logits == null) continue;

        final perWindow = k.decoder.match(k.decoder.decode(logits, tOut, vocab));
        k.stream.update(logits, newSamples, tOut, vocab);
        final streamRes = k.model.manifest.runtime.streamMatch
            ? k.stream.analyze()
            : MatchResult.miss;

        // combine the two matchers; take whichever matched (prefer higher conf)
        MatchResult combined = MatchResult.miss;
        if (perWindow.matched && streamRes.matched) {
          combined = perWindow.matchedConfidence >= streamRes.matchedConfidence
              ? perWindow
              : streamRes;
        } else if (perWindow.matched) {
          combined = perWindow;
        } else if (streamRes.matched) {
          combined = streamRes;
        }

        final matched = combined.matched && !silent;
        final fired = k.gate.update(
          matched: matched,
          matchedConfidence: combined.matchedConfidence,
          targetIndex: combined.targetIndex,
          nowMs: nowMs,
        );
        if (fired) {
          _log.info('vsww',
              'detected "${k.ref.id}" (conf ${combined.matchedConfidence.toStringAsFixed(2)}, ed ${combined.editDistance})');
          final cb = _onDetection;
          await stop();
          if (cb != null) await cb(k.ref);
          return;
        }
      }
    } catch (e) {
      _log.warn('vsww', 'inference error: $e');
    } finally {
      _inferring = false;
    }
  }

  Future<Float32List?> _run(_Keyword k, Float32List features,
      List<int> inputShape, int tOut, int vocab) async {
    OrtValueTensor? input;
    List<OrtValue?>? outputs;
    try {
      input = OrtValueTensor.createTensorWithDataList(features, inputShape);
      outputs = await k.session
          .runAsync(OrtRunOptions(), {k.inputName: input});
      final value = outputs?.first?.value;
      return _flattenLogits(value, tOut, vocab);
    } finally {
      input?.release();
      outputs?.forEach((o) => o?.release());
    }
  }

  /// The plugin returns [1, T, V] as nested Lists of double. Flatten to a
  /// row-major [T*V] Float32List.
  static Float32List? _flattenLogits(Object? value, int tOut, int vocab) {
    if (value is! List || value.isEmpty) return null;
    final batch = value[0];
    if (batch is! List) return null;
    final out = Float32List(tOut * vocab);
    for (var t = 0; t < tOut && t < batch.length; t++) {
      final row = batch[t];
      if (row is! List) return null;
      for (var v = 0; v < vocab && v < row.length; v++) {
        out[t * vocab + v] = (row[v] as num).toDouble();
      }
    }
    return out;
  }
}

typedef ModelStoreFactory = VswwModelStore Function();
