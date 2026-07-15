import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:onnxruntime/onnxruntime.dart';

import 'ctc_decoder.dart';
import 'detection_gate.dart';
import 'log_mel.dart';
import 'manifest.dart';
import 'ort_init.dart';
import 'stream_matcher.dart';

/// Message type tags exchanged with the compute isolate.
class VswwMsg {
  // isolate → main
  static const ready = 'ready';
  static const detection = 'detection';
  static const error = 'error';
  static const log = 'log';
  static const stopped = 'stopped';
  // main → isolate (control; audio is sent as a bare Uint8List)
  static const init = 'init';
  static const stop = 'stop';
}

/// Entry point of the vsWakeWord compute isolate. Pure Dart + FFI (no platform
/// channels): the main isolate owns the mic and forwards raw PCM here as bare
/// Uint8List messages; control messages are Maps.
void vswwIsolateEntry(SendPort mainPort) {
  final worker = _IsolateWorker(mainPort);
  final port = ReceivePort();
  mainPort.send(port.sendPort); // hand our port back to main
  port.listen((msg) {
    if (msg is Uint8List) {
      worker.onAudio(msg);
    } else if (msg is Map) {
      switch (msg['type']) {
        case VswwMsg.init:
          worker.init(msg);
        case VswwMsg.stop:
          worker.stop();
          port.close();
      }
    }
  });
}

class _Kw {
  _Kw(this.id, this.wakeWord, this.manifest, this.session, this.inputName,
      this.decoder, this.stream, this.gate);
  final String id;
  final String wakeWord;
  final VswwManifest manifest;
  final OrtSession session;
  final String inputName;
  final CtcDecoder decoder;
  final StreamMatcher stream;
  final DetectionGate gate;
}

class _IsolateWorker {
  _IsolateWorker(this._main);
  final SendPort _main;

  static const _chunkSamples = 1280;
  static const _rmsVeto = 0.002;

  final List<_Kw> _kws = [];
  LogMelExtractor? _extractor;
  VswwFeatureConfig? _feature;
  Float32List? _ring;
  Float32List? _scratch;
  int _head = 0;
  int _filled = 0;
  int _samplesSinceInfer = 0;
  int _epochMs = 0;
  final _pending = BytesBuilder(copy: false);
  final _chunk = Float32List(_chunkSamples);
  bool _stopped = false;
  bool _detected = false;

  void _log(String level, String message) =>
      _main.send({'type': VswwMsg.log, 'level': level, 'message': message});

  void init(Map msg) {
    try {
      ensureOrtInit();
      for (final md in (msg['models'] as List)) {
        final manifest = VswwManifest.fromJson(
            jsonDecode(md['manifestJson'] as String) as Map<String, dynamic>);
        final opts = OrtSessionOptions()
          ..setIntraOpNumThreads(1)
          ..setInterOpNumThreads(1);
        final session = OrtSession.fromBuffer(md['onnx'] as Uint8List, opts);
        final decoder = CtcDecoder(manifest.ctc);
        _kws.add(_Kw(
          md['id'] as String,
          md['wakeWord'] as String,
          manifest,
          session,
          session.inputNames.first,
          decoder,
          StreamMatcher(manifest, decoder),
          DetectionGate(manifest.runtime),
        ));
        _feature ??= manifest.feature;
        _log('info', 'loaded "${md['id']}"');
      }
      if (_kws.isEmpty) {
        _main.send({'type': VswwMsg.error, 'message': 'no models loaded'});
        return;
      }
      final f = _feature!;
      _extractor = LogMelExtractor(f);
      _ring = Float32List(f.windowSamples);
      _scratch = Float32List(f.windowSamples);
      _main.send({'type': VswwMsg.ready});
    } catch (e) {
      _main.send({'type': VswwMsg.error, 'message': '$e'});
    }
  }

  void onAudio(Uint8List bytes) {
    if (_stopped || _detected) return;
    _pending.add(bytes);
    final buf = _pending.toBytes();
    const chunkBytes = _chunkSamples * 2;
    var offset = 0;
    while (buf.length - offset >= chunkBytes) {
      final view = ByteData.sublistView(buf, offset, offset + chunkBytes);
      for (var i = 0; i < _chunkSamples; i++) {
        _chunk[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
      }
      offset += chunkBytes;
      _ingest(_chunk);
      if (_detected) return;
    }
    _pending.clear();
    if (offset < buf.length) {
      _pending.add(Uint8List.sublistView(buf, offset));
    }
  }

  void _ingest(Float32List chunk) {
    final ring = _ring;
    if (ring == null) return;
    final n = ring.length;
    for (var i = 0; i < chunk.length; i++) {
      ring[_head] = chunk[i];
      _head = (_head + 1) % n;
    }
    if (_filled < n) _filled = math.min(n, _filled + chunk.length);
    _samplesSinceInfer += chunk.length;
    _epochMs += 80;
    if (_filled >= n) _infer(); // synchronous — we are already off the UI
  }

  void _infer() {
    final ring = _ring, scratch = _scratch, extractor = _extractor;
    if (ring == null || scratch == null || extractor == null) return;
    final newSamples = _samplesSinceInfer;
    _samplesSinceInfer = 0;
    final nowMs = _epochMs;
    final n = ring.length;

    final tail = n - _head;
    scratch.setRange(0, tail, ring, _head);
    scratch.setRange(tail, n, ring, 0);

    var sumSq = 0.0;
    for (var i = 0; i < n; i++) {
      sumSq += scratch[i] * scratch[i];
    }
    final silent = math.sqrt(sumSq / n) < _rmsVeto;

    final features = extractor.extract(scratch, newSamples: newSamples);
    final feat = _feature!;
    final shape = [1, feat.frames, feat.nMels];

    for (final k in _kws) {
      final tOut = k.manifest.tOut;
      final vocab = k.manifest.ctc.vocabSize;
      final logits = _run(k, features, shape, tOut, vocab);
      if (logits == null) continue;

      final perWindow = k.decoder.match(k.decoder.decode(logits, tOut, vocab));
      k.stream.update(logits, newSamples, tOut, vocab);
      final streamRes = k.manifest.runtime.streamMatch
          ? k.stream.analyze()
          : MatchResult.miss;

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
        _log('info',
            'detected "${k.id}" (conf ${combined.matchedConfidence.toStringAsFixed(2)}, ed ${combined.editDistance})');
        _detected = true;
        _main.send(
            {'type': VswwMsg.detection, 'id': k.id, 'wakeWord': k.wakeWord});
        return;
      }
    }
  }

  Float32List? _run(
      _Kw k, Float32List features, List<int> shape, int tOut, int vocab) {
    OrtValueTensor? input;
    List<OrtValue?>? outputs;
    try {
      input = OrtValueTensor.createTensorWithDataList(features, shape);
      outputs = k.session.run(OrtRunOptions(), {k.inputName: input}); // sync
      return _flatten(outputs.isNotEmpty ? outputs[0]?.value : null, tOut, vocab);
    } catch (e) {
      _log('warn', 'inference error: $e');
      return null;
    } finally {
      input?.release();
      outputs?.forEach((o) => o?.release());
    }
  }

  static Float32List? _flatten(Object? value, int tOut, int vocab) {
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

  void stop() {
    if (_stopped) return;
    _stopped = true;
    for (final k in _kws) {
      k.session.release();
    }
    _kws.clear();
    _main.send({'type': VswwMsg.stopped});
  }
}
