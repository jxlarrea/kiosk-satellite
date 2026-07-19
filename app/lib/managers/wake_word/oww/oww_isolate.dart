import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:onnxruntime/onnxruntime.dart';

import '../vsww/ort_init.dart';
import 'oww_gate.dart';
import 'oww_pipeline.dart';
import '../wake_msg.dart';

/// Entry point of the openWakeWord compute isolate.
void owwIsolateEntry(SendPort mainPort) {
  final worker = _OwwWorker(mainPort);
  final port = ReceivePort();
  mainPort.send(port.sendPort);
  port.listen((msg) {
    if (msg is Uint8List) {
      worker.onAudio(msg);
    } else if (msg is Map) {
      switch (msg['type']) {
        case WakeMsg.init:
          worker.init(msg);
        case WakeMsg.resume:
          worker.resumeDetection(msg['absSample'] as int?);
        case WakeMsg.armStop:
          worker.armStop(msg['active'] == true);
        case WakeMsg.setTelemetry:
          worker.setTelemetry(msg['enabled'] == true);
        case WakeMsg.stop:
          worker.stop();
          port.close();
      }
    }
  });
}

class _Kw {
  _Kw(this.id, this.wakeWord, this.session, this.inputName, this.gate,
      {this.isStop = false});
  final String id;
  final String wakeWord;
  final OrtSession session;
  final String inputName;
  final OwwGate gate;
  final bool isStop;
}

class _OwwWorker {
  _OwwWorker(this._main);
  final SendPort _main;

  static const _chunkSamples = OwwPipeline.chunkSamples; // 1280 = 80 ms

  final List<_Kw> _kws = [];
  OwwPipeline? _pipeline;
  final _pending = BytesBuilder(copy: false);
  final Float32List _chunk = Float32List(_chunkSamples);
  final List<OrtSession> _sharedSessions = [];
  bool _stopped = false;
  bool _detected = false;
  bool _stopArmed = false;

  // The card's energy gate, resolved to numbers. Worth far more here than for
  // the other engines: openWakeWord's chain is the most expensive of the three.
  bool _energyEnabled = false;
  double _wakeRms = 0;
  int _sleepAfterChunks = 0;
  bool _sleeping = false;
  int _silentChunks = 0;

  int _absSamples = 0;

  void _log(String level, String message) =>
      _main.send({'type': WakeMsg.log, 'level': level, 'message': message});

  void init(Map msg) {
    try {
      ensureOrtInit();
      final gate = msg['energyGate'];
      if (gate is Map && gate['enabled'] == true) {
        _energyEnabled = true;
        _wakeRms = (gate['wakeRms'] as num).toDouble();
        _sleepAfterChunks = (gate['sleepAfterChunks'] as num).toInt();
      }

      OrtSession load(Uint8List bytes) {
        final opts = OrtSessionOptions()
          ..setIntraOpNumThreads(1)
          ..setInterOpNumThreads(1);
        final s = OrtSession.fromBuffer(bytes, opts);
        _sharedSessions.add(s);
        return s;
      }

      final mel = load(msg['melspectrogram'] as Uint8List);
      final emb = load(msg['embedding'] as Uint8List);
      _pipeline = OwwPipeline(melSession: mel, embeddingSession: emb);

      for (final md in (msg['models'] as List)) {
        final session = load(md['onnx'] as Uint8List);
        final cutoff = (md['cutoff'] as num).toDouble();
        final isStop = md['stop'] == true;
        _kws.add(_Kw(
          md['id'] as String,
          md['wakeWord'] as String,
          session,
          session.inputNames.first,
          OwwGate(cutoff: cutoff),
          isStop: isStop,
        ));
        _log(
            'info',
            'loaded "${md['id']}"${isStop ? ' (stop classifier)' : ''} '
            '(cutoff ${cutoff.toStringAsFixed(3)})');
      }
      if (_kws.isEmpty) {
        _main.send({'type': WakeMsg.error, 'message': 'no models loaded'});
        return;
      }

      // Pre-fill the classifier window with noise embeddings before any audio
      // arrives, so the first real chunk is judged against openWakeWord's
      // expected state rather than zeros.
      final sw = Stopwatch()..start();
      _pipeline!.warmup();
      sw.stop();
      _log('info', 'warmed up in ${sw.elapsedMilliseconds}ms');

      _main.send({'type': WakeMsg.ready});
    } catch (e) {
      _main.send({'type': WakeMsg.error, 'message': '$e'});
    }
  }

  void onAudio(Uint8List bytes) {
    if (_stopped) return;
    if (_detected && !_stopArmed) return;
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
      if (_detected && !_stopArmed) break;
    }
    _pending.clear();
    if (offset < buf.length) {
      _pending.add(Uint8List.sublistView(buf, offset));
    }
  }

  bool _telemetry = false;
  double _chunkRms = 0;

  void setTelemetry(bool enabled) => _telemetry = enabled;

  void _ingest(Float32List chunk) {
    final pipeline = _pipeline;
    if (pipeline == null) return;
    _absSamples += chunk.length;
    if (_telemetry) {
      var sum = 0.0;
      for (final s in chunk) {
        sum += s * s;
      }
      _chunkRms = math.sqrt(sum / chunk.length);
    }
    if (!_shouldScore(chunk)) return;

    // mel + embedding run once per chunk and are shared by every classifier;
    // only the per-model head runs per wake word.
    final window = pipeline.process(chunk);
    if (window == null) return;

    for (final k in _kws) {
      if (k.isStop ? !_stopArmed : _detected) continue;
      final sw = _telemetry ? (Stopwatch()..start()) : null;
      final probability = _classify(k, window);
      sw?.stop();
      if (probability == null) continue;
      final trigger = k.gate.update(probability, _absSamples ~/ 16);
      if (_telemetry && !k.isStop) {
        _main.send({
          'type': WakeMsg.telemetry,
          'id': k.id,
          'wakeWord': k.wakeWord,
          't': _absSamples ~/ 16,
          'score': probability,
          'threshold': k.gate.cutoff,
          'fired': trigger != null,
          'rms': _chunkRms,
          'latencyUs': sw?.elapsedMicroseconds ?? 0,
        });
      }
      if (trigger == null) continue;
      // Tester open: recorded in telemetry, but do not fire a real
      // detection (it would start a voice interaction). Keep scoring.
      if (_telemetry) continue;

      if (k.isStop) {
        _log('info',
            'stop word detected (${trigger.name}, score ${probability.toStringAsFixed(3)})');
        _main.send({'type': WakeMsg.detection, 'id': k.id, 'stop': true});
        return;
      }

      _log('info',
          'detected "${k.id}" (${trigger.name}, score ${probability.toStringAsFixed(3)})');
      _detected = true;
      _main.send({
        'type': WakeMsg.detection,
        'id': k.id,
        'wakeWord': k.wakeWord,
        // A window classifier: it knows the wake word happened recently, not
        // where it ended, so the stream starts at the detection instant.
        'wakeEndSample': _absSamples,
      });
      return;
    }
  }

  double? _classify(_Kw k, Float32List window) {
    OrtValueTensor? input;
    List<OrtValue?>? outputs;
    try {
      input = OrtValueTensor.createTensorWithDataList(
          window, [1, OwwPipeline.embeddingWindow, OwwPipeline.embeddingDim]);
      outputs = k.session.run(OrtRunOptions(), {k.inputName: input});
      final value = outputs.isNotEmpty ? outputs[0]?.value : null;
      if (value == null) return null;
      Object? cur = value;
      while (cur is List) {
        if (cur.isEmpty) return null;
        cur = cur.first;
      }
      return cur is num ? cur.toDouble() : null;
    } catch (e) {
      _log('warn', 'inference error: $e');
      return null;
    } finally {
      input?.release();
      outputs?.forEach((o) => o?.release());
    }
  }

  bool _shouldScore(Float32List chunk) {
    if (!_energyEnabled) return true;
    final rms = OwwPipeline.rms(chunk);
    if (_sleeping) {
      if (rms < _wakeRms) return false;
      _sleeping = false;
      _silentChunks = 0;
      _log('info', 'energy gate: awake (rms ${rms.toStringAsFixed(4)})');
      return true;
    }
    if (rms >= _wakeRms) {
      _silentChunks = 0;
      return true;
    }
    _silentChunks++;
    if (_silentChunks < _sleepAfterChunks) return true;
    _sleeping = true;
    _pipeline?.reset();
    for (final k in _kws) {
      k.gate.reset();
    }
    _log('info', 'energy gate: asleep (rms ${rms.toStringAsFixed(4)})');
    return false;
  }

  void armStop(bool active) {
    if (_stopped || _stopArmed == active) return;
    _stopArmed = active;
    for (final k in _kws) {
      if (k.isStop) k.gate.reset();
    }
    _log('info', active ? 'stop word armed' : 'stop word disarmed');
  }

  /// Re-arm after a turn. Wipes the stream so the wake word we just handled
  /// cannot fire again, restoring the noise-warmed window rather than zeros.
  void resumeDetection(int? absSample) {
    if (_stopped) return;
    _detected = false;
    if (absSample != null) _absSamples = absSample;
    _pending.clear();
    _pipeline?.reset();
    for (final k in _kws) {
      if (k.isStop) continue;
      k.gate.reset();
    }
    _log('info', 're-armed');
  }

  void stop() {
    if (_stopped) return;
    _stopped = true;
    for (final s in _sharedSessions) {
      s.release();
    }
    _sharedSessions.clear();
    _kws.clear();
    _pipeline = null;
    _main.send({'type': WakeMsg.stopped});
  }
}
