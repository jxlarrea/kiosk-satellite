import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

import 'micro_frontend.dart';
import 'mww_gate.dart';
import '../wake_msg.dart';

/// Entry point of the microWakeWord compute isolate.
///
/// Same split as vsWakeWord: the mic lives on the main isolate and hands raw
/// PCM over, so the feature extraction and TFLite invoke never touch the
/// platform isolate and cannot jank the WebView.
void mwwIsolateEntry(SendPort mainPort) {
  final worker = _MwwWorker(mainPort);
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
  _Kw(this.id, this.wakeWord, this.interpreter, this.gate, this.framesPerInfer,
      this.inputScale, this.inputZeroPoint, int inputElements,
      {this.isStop = false})
      : accum = List.generate(framesPerInfer, (_) => Float32List(kFeatureSize)),
        inputBuf = Int8List(inputElements);

  final String id;
  final String wakeWord;

  /// Stop classifier rather than a wake word: armed only while the card says
  /// something interruptible is playing, and firing interrupts it rather than
  /// starting a turn.
  final bool isStop;
  final Interpreter interpreter;
  final MwwGate gate;

  /// Feature frames the model consumes per invoke, probed off its input tensor
  /// ([1, 3, 40] -> 3) rather than trusted from the manifest.
  final int framesPerInfer;
  final double inputScale;
  final int inputZeroPoint;

  /// Preallocated frame slots, [accumLen] of them filled. Frames are copied in
  /// because the frontend reuses its buffers on the next feed.
  final List<Float32List> accum;
  int accumLen = 0;

  /// Reusable flat quantized-input buffer (tensor element count) plus its byte
  /// view for the copy into the input tensor. int8 and uint8 tensors store the
  /// same byte patterns, so one Int8List serves both.
  final Int8List inputBuf;
  late final Uint8List inputBytes = inputBuf.buffer.asUint8List();

  late final Tensor inputTensor = interpreter.getInputTensor(0);
  late final Tensor outputTensor = interpreter.getOutputTensor(0);

  /// int8 output bytes must be sign-extended before scaling; uint8 read as is.
  /// Matches how the plugin's own decoding treated each type.
  late final bool outputSigned = outputTensor.type == TensorType.int8;
}

class _MwwWorker {
  _MwwWorker(this._main);
  final SendPort _main;

  static const _chunkSamples = 1280; // 80 ms at 16 kHz, as the mic delivers

  final List<_Kw> _kws = [];
  MicroFrontend? _frontend;
  final _pending = BytesBuilder(copy: false);
  final Float64List _chunk = Float64List(_chunkSamples);
  bool _stopped = false;

  /// A wake word fired and we await re-arming: wake models go quiet, but the
  /// stop classifier does not, since the turn it started is exactly when the
  /// user might say "stop".
  bool _detected = false;
  bool _stopArmed = false;

  // The card's energy gate, resolved to numbers. Gates the TFLite invoke only:
  // the frontend keeps running so its window stays continuous and waking needs
  // no replay buffer. Saves less than vsWakeWord's gate, where inference is the
  // whole cost; here the feature extraction still runs.
  bool _energyEnabled = false;
  double _wakeRms = 0;
  int _sleepAfterChunks = 0;
  bool _sleeping = false;
  int _silentChunks = 0;

  /// Mic-timeline sample count, shared with the main isolate so a detection can
  /// name an absolute sample. mww cannot say where the wake word *ended* (it is
  /// a window classifier), so this only ever reports "now".
  int _absSamples = 0;

  void _log(String level, String message) =>
      _main.send({'type': WakeMsg.log, 'level': level, 'message': message});

  void init(Map msg) {
    try {
      _frontend = MicroFrontend();
      final gate = msg['energyGate'];
      if (gate is Map && gate['enabled'] == true) {
        _energyEnabled = true;
        _wakeRms = (gate['wakeRms'] as num).toDouble();
        _sleepAfterChunks = (gate['sleepAfterChunks'] as num).toInt();
      }
      for (final md in (msg['models'] as List)) {
        final interpreter = Interpreter.fromBuffer(md['tflite'] as Uint8List);
        final inT = interpreter.getInputTensors().first;

        // The tensor is authoritative about frames-per-invoke and
        // quantization; the manifest is not, and tfweb could not read either,
        // which is why the card probes the input buffer length instead.
        final inputShape = inT.shape; // e.g. [1, 3, 40]
        final inputElements = inputShape.fold<int>(1, (a, b) => a * b);
        final framesPerInfer = inputElements ~/ kFeatureSize;
        final params = inT.params;
        final scale = params.scale > 0 ? params.scale : 0.10196078568696976;
        final zeroPoint = params.zeroPoint;

        final cutoff = (md['cutoff'] as num).toDouble();
        final window = (md['slidingWindowSize'] as num).toInt();
        _kws.add(_Kw(
          md['id'] as String,
          md['wakeWord'] as String,
          interpreter,
          MwwGate(cutoff: cutoff, slidingWindowSize: window),
          framesPerInfer < 1 ? 1 : framesPerInfer,
          scale,
          zeroPoint,
          inputElements,
          isStop: md['stop'] == true,
        ));
        _log(
            'info',
            'loaded "${md['id']}"${md['stop'] == true ? ' (stop classifier)' : ''}'
            ' (frames/infer $framesPerInfer, cutoff '
            '${cutoff.toStringAsFixed(3)}, window $window, scale '
            '${scale.toStringAsFixed(5)}, zp $zeroPoint)');
      }
      if (_kws.isEmpty) {
        _main.send({'type': WakeMsg.error, 'message': 'no models loaded'});
        return;
      }
      _main.send({'type': WakeMsg.ready});
    } catch (e) {
      _main.send({'type': WakeMsg.error, 'message': '$e'});
    }
  }

  void onAudio(Uint8List bytes) {
    if (_stopped) return;
    if (_detected && !_stopArmed) return; // nothing left to score
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

  void _ingest(Float64List chunk) {
    final frontend = _frontend;
    if (frontend == null) return;
    _absSamples += chunk.length;
    if (_telemetry) {
      var sum = 0.0;
      for (final s in chunk) {
        sum += s * s;
      }
      _chunkRms = math.sqrt(sum / chunk.length);
    }
    final scoreThisChunk = _shouldScore(chunk);

    // One 80 ms chunk yields 8 feature frames (10 ms step). The frontend is fed
    // regardless of the energy gate so its window never goes stale.
    for (final feature in frontend.feed(chunk)) {
      for (final k in _kws) {
        // Wake models go quiet once one has fired (until re-armed); the stop
        // classifier only runs while the card says playback is interruptible,
        // or while a tester is watching it (telemetry, no real detection).
        if (k.isStop ? (!_stopArmed && !_telemetry) : _detected) continue;
        // Copied, not referenced: the frontend reuses its frame buffers.
        k.accum[k.accumLen].setAll(0, feature);
        k.accumLen++;
        if (k.accumLen < k.framesPerInfer) continue;
        if (!scoreThisChunk) {
          k.accumLen = 0;
          continue;
        }
        final sw = _telemetry ? (Stopwatch()..start()) : null;
        final probability = _invoke(k);
        sw?.stop();
        k.accumLen = 0;
        if (probability == null) continue;

        final trigger = k.gate.update(probability, _absSamples ~/ 16);
        if (_telemetry) {
          // The windowed mean is what the gate compares to the cutoff; the
          // raw per-inference probability is the spikier underlying signal.
          _main.send({
            'type': WakeMsg.telemetry,
            'id': k.id,
            'wakeWord': k.wakeWord,
            't': _absSamples ~/ 16,
            'score': k.gate.windowMean,
            'raw': probability,
            'threshold': k.gate.cutoff,
            'fired': trigger != null,
            'rms': _chunkRms,
            'latencyUs': sw?.elapsedMicroseconds ?? 0,
          });
        }
        if (trigger == null) continue;
        // Tester open: the hit is recorded in telemetry above, but must not
        // fire a real detection (that would start a voice interaction). Keep
        // scoring — do not latch _detected — so the chart stays live.
        if (_telemetry) continue;

        if (k.isStop) {
          _log(
              'info',
              'stop word detected (${trigger.name}, mean '
              '${k.gate.windowMean.toStringAsFixed(3)})');
          // Report and keep listening: the card owns the stop state and
          // disarms us as it tears the interruptible state down. Deciding here
          // would fork that state (see the vsWakeWord isolate).
          _main.send({'type': WakeMsg.detection, 'id': k.id, 'stop': true});
          return;
        }

        _log(
            'info',
            'detected "${k.id}" (${trigger.name}, mean '
            '${k.gate.windowMean.toStringAsFixed(3)})');
        _detected = true;
        _main.send({
          'type': WakeMsg.detection,
          'id': k.id,
          'wakeWord': k.wakeWord,
          // A window classifier knows only that the wake word happened
          // recently, not where it ended, so the stream starts at the detection
          // instant. Never replays the wake word: detection cannot precede it.
          // See WakeWordEngine.startAudioStream.
          'wakeEndSample': _absSamples,
        });
        return;
      }
    }
  }

  /// The card's energy gate: is this chunk worth running inference on?
  bool _shouldScore(Float64List chunk) {
    if (!_energyEnabled) return true;
    var sum = 0.0;
    for (var i = 0; i < chunk.length; i++) {
      sum += chunk[i] * chunk[i];
    }
    final rms = math.sqrt(sum / chunk.length);
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
    for (final k in _kws) {
      k.gate.reset();
      k.accumLen = 0;
    }
    _log('info', 'energy gate: asleep (rms ${rms.toStringAsFixed(4)})');
    return false;
  }

  /// Arm/disarm the stop classifier, clearing its state on the way in so
  /// speech from before the interruptible state cannot fire it.
  void armStop(bool active) {
    if (_stopped || _stopArmed == active) return;
    _stopArmed = active;
    for (final k in _kws) {
      if (!k.isStop) continue;
      k.gate.reset();
      k.accumLen = 0;
    }
    _log('info', active ? 'stop word armed' : 'stop word disarmed');
  }

  /// Quantize the accumulated frames into the model's int8 input tensor,
  /// invoke, and return the uint8 output as a probability in [0, 1].
  ///
  /// Quantization mirrors the card exactly, float32 rounding included: divide
  /// by scale, add zero point, then *banker's* round (see [roundBankers] - the
  /// zero point is negative, so Dart's `.round()` would be wrong here).
  double? _invoke(_Kw k) {
    try {
      final input = k.inputBuf;
      final n = input.length;
      final scaleF32 = _fround32(k.inputScale);
      final zpF32 = _fround32(k.inputZeroPoint.toDouble());
      var idx = 0;
      for (var f = 0; f < k.accumLen && idx < n; f++) {
        final frame = k.accum[f];
        for (var j = 0; j < frame.length && idx < n; j++) {
          final divided = _fround32(frame[j] / scaleF32);
          final shifted = _fround32(divided + zpF32);
          var q = roundBankers(shifted);
          if (q < -128) q = -128;
          if (q > 127) q = 127;
          input[idx++] = q;
        }
      }
      if (idx < n) input.fillRange(idx, n, 0);

      // Byte copies straight into/out of the tensors; the nested boxed lists
      // runForMultipleInputs marshals through cost more than the invoke.
      k.inputTensor.data = k.inputBytes;
      k.interpreter.invoke();
      final out = k.outputTensor.data;
      if (out.isEmpty) return null;
      final raw = k.outputSigned ? out[0].toSigned(8) : out[0];
      // Output is uint8 [0, 255].
      return raw / 255.0;
    } catch (e) {
      _log('warn', 'inference error: $e');
      return null;
    }
  }

  /// Re-arm after a voice turn: keeps the interpreters loaded (reloading per
  /// wake would be pure waste) but drops detector and feature state so speech
  /// from the turn just handled cannot fire a stale detection.
  void resumeDetection(int? absSample) {
    if (_stopped) return;
    _detected = false;
    if (absSample != null) _absSamples = absSample;
    _pending.clear();
    _frontend?.reset();
    for (final k in _kws) {
      if (k.isStop) continue; // armed independently; not ours to reset
      k.accumLen = 0;
      k.gate.reset();
    }
    _log('info', 're-armed');
  }

  void stop() {
    if (_stopped) return;
    _stopped = true;
    for (final k in _kws) {
      k.interpreter.close();
    }
    _kws.clear();
    _main.send({'type': WakeMsg.stopped});
  }
}

final Float32List _f32scratch = Float32List(1);
double _fround32(double x) {
  _f32scratch[0] = x;
  return _f32scratch[0];
}
