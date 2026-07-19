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
import 'ort_tensor_io.dart';
import 'stream_matcher.dart';
import '../wake_msg.dart';

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
  _Kw(this.id, this.wakeWord, this.manifest, this.session, this.inputName,
      this.decoder, this.stream, this.gate, {this.isStop = false})
      : logitsBuf = Float32List(manifest.tOut * manifest.ctc.vocabSize);
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

  /// Reused per-inference logits destination, [tOut * vocab].
  final Float32List logitsBuf;

  /// Whether the session's output element count was verified against the
  /// manifest's [tOut * vocab] (checked on the first inference; a mismatched
  /// model is dropped rather than read out of bounds).
  bool outputChecked = false;

  /// Set when the first-inference output check fails: the session is released
  /// and the model never scored again (removing mid-iteration would break the
  /// scoring loop).
  bool dead = false;
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

  // One input tensor and one run-options handle for the whole session: every
  // model scores the same feature window, so writing it once per chunk into a
  // persistent native buffer replaces a per-model create/copy/release cycle.
  ReusableInputTensor? _input;
  OrtRunOptions? _runOptions;
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
      _main.send({'type': WakeMsg.log, 'level': level, 'message': message});

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
        _main.send({'type': WakeMsg.error, 'message': 'no models loaded'});
        return;
      }
      final f = _feature!;
      _extractor = LogMelExtractor(f);
      _ring = Float32List(f.windowSamples);
      _scratch = Float32List(f.windowSamples);
      _input = ReusableInputTensor.create([1, f.frames, f.nMels]);
      _runOptions = OrtRunOptions();
      _log(
          'info',
          _energyEnabled
              ? 'energy gate on (wake rms $_wakeRms, sleep after $_sleepAfterChunks quiet chunks)'
              : 'energy gate off');
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
      // buf is freshly built (byte offset 0) and offset stays even, so an
      // aligned Int16List view is safe; PCM16LE matches host endianness.
      final samples = Int16List.sublistView(buf, offset, offset + chunkBytes);
      for (var i = 0; i < _chunkSamples; i++) {
        _chunk[i] = samples[i] / 32768.0;
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
    // Bulk copy in at most two runs instead of a per-sample modulo walk.
    var src = 0;
    var remaining = chunk.length;
    while (remaining > 0) {
      final len = math.min(remaining, n - _head);
      ring.setRange(_head, _head + len, chunk, src);
      _head = (_head + len) % n;
      src += len;
      remaining -= len;
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

  bool _telemetry = false;

  void setTelemetry(bool enabled) => _telemetry = enabled;

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
    final rms = math.sqrt(sumSq / n);
    final silent = rms < _rmsVeto;

    final features = extractor.extract(scratch, newSamples: newSamples);
    _input!.write(features);

    for (final k in _kws) {
      if (k.dead) continue;
      // Wake models go quiet once one has fired (until re-armed); the stop
      // classifier only runs while the card says playback is interruptible.
      if (k.isStop ? !_stopArmed : _detected) continue;
      final tOut = k.manifest.tOut;
      final vocab = k.manifest.ctc.vocabSize;
      final sw = _telemetry ? (Stopwatch()..start()) : null;
      final logits = _run(k);
      sw?.stop();
      if (logits == null) continue;

      final decode = k.decoder.decode(logits, tOut, vocab);
      final perWindow = k.decoder.match(decode);
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
      if (_telemetry && !k.isStop) {
        // A CTC model has no continuous probability; the meaningful signal
        // is the matched confidence when the decoder aligns a target (a hit
        // or a below-gate near miss), plus what phonemes it actually
        // decoded — the whole point of the tester for vsWakeWord: seeing
        // that it heard [ax l eh k s ax] and how far that is from the
        // target. Blank frames dropped; only rendered when speech is
        // present, so the log is signal not silence.
        final conf = combined.matchedConfidence;
        final decoded = k.manifest.ctc.phonemesFor(decode.ids);
        _main.send({
          'type': WakeMsg.telemetry,
          'id': k.id,
          'wakeWord': k.wakeWord,
          't': nowMs,
          'score': conf.isFinite ? conf : 0.0,
          'threshold': combined.gateThreshold.isFinite
              ? combined.gateThreshold
              : (k.manifest.ctc.minMatchedConfidence.isFinite
                    ? k.manifest.ctc.minMatchedConfidence
                    : 0.0),
          'fired': fired,
          'nearMiss': conf.isFinite && !fired,
          'editDistance': combined.editDistance < (1 << 20)
              ? combined.editDistance
              : -1,
          'matchedConfidence': conf.isFinite ? conf : null,
          'decoded': decoded,
          'rms': rms,
          'latencyUs': sw?.elapsedMicroseconds ?? 0,
        });
      }
      // Tester open: the hit is in telemetry above, but must not fire a
      // real detection (that would start a voice interaction). Keep
      // scoring — do not latch _detected.
      if (fired && _telemetry) continue;
      if (fired) {
        if (k.isStop) {
          _log('info',
              'stop word detected (conf ${combined.matchedConfidence.toStringAsFixed(2)}, ed ${combined.editDistance})');
          // Report and keep listening. We do NOT disarm ourselves: the card
          // owns the stop state and disarms us as part of tearing the
          // interruptible state down. Deciding here would fork that state.
          // The gate's cooldown, not a self-disarm, is what stops the same
          // word firing twice before the card's command lands.
          _main.send({'type': WakeMsg.detection, 'id': k.id, 'stop': true});
          return;
        }
        final wakeEnd = _wakeEndSample(k, combined, identical(combined, perWindow));
        _log('info',
            'detected "${k.id}" (conf ${combined.matchedConfidence.toStringAsFixed(2)}, ed ${combined.editDistance}, wake ended ${_absSamples - wakeEnd} samples back)');
        _detected = true;
        _main.send({
          'type': WakeMsg.detection,
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

  Float32List? _run(_Kw k) {
    List<OrtValue?>? outputs;
    try {
      outputs =
          k.session.run(_runOptions!, {k.inputName: _input!.tensor}); // sync
      final out = outputs.isNotEmpty ? outputs[0] : null;
      if (out == null) return null;
      if (!k.outputChecked) {
        final count = tensorElementCount(out);
        if (count != k.logitsBuf.length) {
          _log('warn',
              '"${k.id}": output has $count elements, manifest says ${k.logitsBuf.length}; dropping model');
          k.dead = true;
          k.session.release();
          return null;
        }
        k.outputChecked = true;
      }
      readFloatTensor(out, k.logitsBuf);
      return k.logitsBuf;
    } catch (e) {
      _log('warn', 'inference error: $e');
      return null;
    } finally {
      outputs?.forEach((o) => o?.release());
    }
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
      if (!k.dead) k.session.release(); // dead models released at drop time
    }
    _kws.clear();
    _input?.release();
    _input = null;
    _runOptions?.release();
    _runOptions = null;
    _main.send({'type': WakeMsg.stopped});
  }
}
