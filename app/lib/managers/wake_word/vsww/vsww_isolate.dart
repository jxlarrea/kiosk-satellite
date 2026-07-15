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
  static const resume = 'resume';
  static const armStop = 'armStop';
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
        case VswwMsg.resume:
          worker.resumeDetection(msg['absSample'] as int?);
        case VswwMsg.armStop:
          worker.armStop(msg['active'] == true);
        case VswwMsg.stop:
          worker.stop();
          port.close();
      }
    }
  });
}

class _Kw {
  _Kw(this.id, this.wakeWord, this.manifest, this.session, this.inputName,
      this.decoder, this.stream, this.gate, {this.isStop = false});
  final String id;
  final String wakeWord;

  /// Stop classifier rather than a wake word: armed only during interruptible
  /// states, and firing interrupts playback instead of starting a turn.
  final bool isStop;
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

  /// Total samples that have entered the ring, in the *mic's* timeline: the
  /// main isolate keeps the same count and re-syncs us on resume (it goes on
  /// counting while detection is paused and we are not being fed). Shared
  /// origin is what lets a detection name an absolute sample the main isolate
  /// can find again in its pre-roll ring.
  int _absSamples = 0;
  final _pending = BytesBuilder(copy: false);
  final _chunk = Float32List(_chunkSamples);
  bool _stopped = false;

  /// A wake word fired and we are waiting to be re-armed: wake models go quiet,
  /// but the stop classifier does not, since the turn it started is exactly
  /// when the user might say "stop".
  bool _detected = false;
  bool _stopArmed = false;

  // Energy gate: the card's "skip inference while the room is quiet" policy,
  // handed to us as plain numbers. Inference is the entire cost here (log-mel
  // + ONNX); the ring write is a memcpy. So we gate only _infer() and keep the
  // ring filling, which means the sample clock never skips, the pre-roll stays
  // continuous, and waking needs no replay buffer: the last 1.3s of audio is
  // already in the window.
  bool _energyEnabled = false;
  double _wakeRms = 0;
  int _sleepAfterChunks = 0;
  bool _sleeping = false;
  int _silentChunks = 0;

  void _log(String level, String message) =>
      _main.send({'type': VswwMsg.log, 'level': level, 'message': message});

  static bool _sameFeature(VswwFeatureConfig a, VswwFeatureConfig b) =>
      a.windowSamples == b.windowSamples &&
      a.frames == b.frames &&
      a.nMels == b.nMels &&
      a.hopSamples == b.hopSamples &&
      a.sampleRate == b.sampleRate;

  void init(Map msg) {
    try {
      ensureOrtInit();
      final gate = msg['energyGate'];
      if (gate is Map && gate['enabled'] == true) {
        _energyEnabled = true;
        _wakeRms = (gate['wakeRms'] as num).toDouble();
        _sleepAfterChunks = (gate['sleepAfterChunks'] as num).toInt();
      }
      for (final md in (msg['models'] as List)) {
        final manifest = VswwManifest.fromJson(
            jsonDecode(md['manifestJson'] as String) as Map<String, dynamic>);
        // One log-mel extractor feeds every model, so they must agree on the
        // feature shape. Rejecting a mismatch beats silently scoring a model
        // against features it was never trained on.
        if (_feature != null && !_sameFeature(_feature!, manifest.feature)) {
          _log('warn',
              'skipped "${md['id']}": feature config differs from the loaded models');
          continue;
        }
        final opts = OrtSessionOptions()
          ..setIntraOpNumThreads(1)
          ..setInterOpNumThreads(1);
        final session = OrtSession.fromBuffer(md['onnx'] as Uint8List, opts);
        // The card's Sensitivity setting, already resolved to a multiplier.
        final scale = (md['confidenceScale'] as num?)?.toDouble() ?? 1.0;
        final decoder = CtcDecoder(manifest.ctc, confidenceScale: scale);
        final isStop = md['stop'] == true;
        _kws.add(_Kw(
          md['id'] as String,
          md['wakeWord'] as String,
          manifest,
          session,
          session.inputNames.first,
          decoder,
          StreamMatcher(manifest, decoder),
          DetectionGate(manifest.runtime, confidenceScale: scale),
          isStop: isStop,
        ));
        _feature ??= manifest.feature;
        _log(
            'info',
            'loaded "${md['id']}"${isStop ? ' (stop classifier)' : ''}'
            '${scale == 1.0 ? '' : ', conf gate scale x${scale.toStringAsFixed(2)}'}');
      }
      if (_kws.isEmpty) {
        _main.send({'type': VswwMsg.error, 'message': 'no models loaded'});
        return;
      }
      final f = _feature!;
      _extractor = LogMelExtractor(f);
      _ring = Float32List(f.windowSamples);
      _scratch = Float32List(f.windowSamples);
      _log(
          'info',
          _energyEnabled
              ? 'energy gate on (wake rms $_wakeRms, sleep after $_sleepAfterChunks quiet chunks)'
              : 'energy gate off');
      _main.send({'type': VswwMsg.ready});
    } catch (e) {
      _main.send({'type': VswwMsg.error, 'message': '$e'});
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
    _absSamples += chunk.length;
    _epochMs += 80;
    // The ring is always fed; only the expensive part is gated.
    if (_filled >= n && _shouldInfer(chunk)) {
      _infer(); // synchronous — we are already off the UI
    }
  }

  /// The card's energy gate: is this chunk worth running inference on?
  ///
  /// Mirrors the browser engine's gate (sleep after N consecutive chunks below
  /// the wake RMS, resume on the first chunk at or above it), minus its replay
  /// buffer, which exists because its inference owns the audio window. Ours is
  /// external and never stopped filling, so on wake the window already holds
  /// the last 1.3 s including whatever just got loud.
  bool _shouldInfer(Float32List chunk) {
    if (!_energyEnabled) return true;
    final rms = _rms(chunk);
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
    // Drop detector state with the audio we are about to stop scoring, so a
    // pre-silence fragment cannot pair up with post-silence speech.
    for (final k in _kws) {
      k.stream.reset();
      k.gate.reset();
    }
    _log('info', 'energy gate: asleep (rms ${rms.toStringAsFixed(4)})');
    return false;
  }

  static double _rms(Float32List samples) {
    var sum = 0.0;
    for (var i = 0; i < samples.length; i++) {
      sum += samples[i] * samples[i];
    }
    return math.sqrt(sum / samples.length);
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
      // Wake models go quiet once one has fired (until re-armed); the stop
      // classifier only runs while the card says playback is interruptible.
      if (k.isStop ? !_stopArmed : _detected) continue;
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
        if (k.isStop) {
          _log('info',
              'stop word detected (conf ${combined.matchedConfidence.toStringAsFixed(2)}, ed ${combined.editDistance})');
          // Report and keep listening. We do NOT disarm ourselves: the card
          // owns the stop state and disarms us as part of tearing the
          // interruptible state down. Deciding here would fork that state.
          // The gate's cooldown, not a self-disarm, is what stops the same
          // word firing twice before the card's command lands.
          _main.send({'type': VswwMsg.detection, 'id': k.id, 'stop': true});
          return;
        }
        final wakeEnd = _wakeEndSample(k, combined, identical(combined, perWindow));
        _log('info',
            'detected "${k.id}" (conf ${combined.matchedConfidence.toStringAsFixed(2)}, ed ${combined.editDistance}, wake ended ${_absSamples - wakeEnd} samples back)');
        _detected = true;
        _main.send({
          'type': VswwMsg.detection,
          'id': k.id,
          'wakeWord': k.wakeWord,
          'wakeEndSample': wakeEnd,
        });
        return;
      }
    }
  }

  /// Absolute sample index where the matched wake word ended.
  ///
  /// This is what makes a one-shot phrase work: the caller can start the audio
  /// stream exactly after "okay nabu" and keep every sample of "turn off the
  /// lights", without replaying the wake word into STT. Detection fires up to a
  /// window late, so the end has to be recovered from the match alignment
  /// rather than assumed to be now.
  int _wakeEndSample(_Kw k, MatchResult m, bool fromWindow) {
    final windowSamples = _feature!.windowSamples;
    final tOut = k.manifest.tOut;
    final frameSamples = windowSamples ~/ tOut;
    int samplesBack;
    if (fromWindow && m.endFrame >= 0) {
      // Window frame `endFrame` ends this many samples before the window edge.
      samplesBack = windowSamples - (m.endFrame + 1) * frameSamples;
    } else if (!fromWindow) {
      samplesBack = k.stream.lastMatchSamplesBack;
    } else {
      samplesBack = 0; // no alignment: treat the wake as ending now
    }
    if (samplesBack < 0) samplesBack = 0;
    if (samplesBack > windowSamples) samplesBack = windowSamples;
    final end = _absSamples - samplesBack;
    return end < 0 ? 0 : end;
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

  /// Re-arm after a voice turn. Keeps the loaded ONNX sessions (resuming must
  /// be instant — reloading them per wake would be pure waste) but clears the
  /// audio window and all detector state so speech from the turn we just
  /// handled can't fire a stale detection.
  void resumeDetection([int? absSample]) {
    if (_stopped) return;
    _detected = false;
    _samplesSinceInfer = 0;
    // Main kept counting through the turn while we were not being fed; adopt
    // its count or every later detection names a sample it has long evicted.
    if (absSample != null) _absSamples = absSample;
    // The ring is shared with the stop classifier, so only blank it when the
    // stop word is not listening; wiping it mid-playback would leave stop deaf
    // for a whole window while it refills. Resetting the wake detectors below
    // is what actually prevents a stale re-fire.
    if (!_stopArmed) {
      _head = 0;
      _filled = 0;
      _pending.clear();
    }
    for (final k in _kws) {
      if (k.isStop) continue; // armed independently; not ours to reset
      k.stream.reset();
      k.gate.reset();
    }
    _log('info', 're-armed');
  }

  /// Arm/disarm the stop classifier. Clears its detector state on the way in so
  /// speech from before the interruptible state started cannot fire it.
  void armStop(bool active) {
    if (_stopped || _stopArmed == active) return;
    _stopArmed = active;
    for (final k in _kws) {
      if (!k.isStop) continue;
      k.stream.reset();
      k.gate.reset();
    }
    _log('info', active ? 'stop word armed' : 'stop word disarmed');
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
