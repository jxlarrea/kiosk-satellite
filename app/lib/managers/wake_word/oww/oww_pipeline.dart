import 'dart:math' as math;
import 'dart:typed_data';

import 'package:onnxruntime/onnxruntime.dart';

import '../vsww/ort_tensor_io.dart';

/// openWakeWord's three-stage streaming pipeline.
///
///   raw 16 kHz audio -> melspectrogram -> embedding -> classifier
///
/// Ported from Voice Satellite's `oww/inference.js`, which mirrors upstream
/// `openwakeword/utils.py`. Per 1280-sample chunk:
///
///   1. prepend the last 480 samples of audio history -> 1760 samples -> mel
///      (the history exists for STFT continuity across chunks)
///   2. apply the mel transform: `x / 10 + 2`
///   3. append the new mel frames to the rolling mel buffer
///   4. run the newest 76 mel frames -> embedding model -> 96-dim vector
///   5. append it to the rolling classifier window
///   6. run the newest 16 embeddings -> classifier -> probability
///
/// Audio arrives as +/-1 floats and is scaled by 32768 first: the mel model was
/// trained on int16 PCM cast to float, so feeding +/-1 underflows its
/// calibrated convolution kernels and the whole chain reads as silence.
///
/// The card runs this on WebGPU because its embedding model takes ~80 ms per
/// chunk in pure JS. Natively on the CPU the whole chain is ~3.8 ms, so there
/// is nothing to accelerate.
class OwwPipeline {
  OwwPipeline({
    required this.melSession,
    required this.embeddingSession,
  })  : _melInputName = melSession.inputNames.first,
        _embInputName = embeddingSession.inputNames.first;

  static const chunkSamples = 1280;
  static const melBins = 32;
  static const melWindow = 76;
  static const embeddingDim = 96;
  static const embeddingWindow = 16;
  static const melPrefixSamples = 160 * 3; // 480
  static const _melBufferMax = 970;

  final OrtSession melSession;
  final OrtSession embeddingSession;
  final String _melInputName;
  final String _embInputName;

  final Float32List _audioHistory = Float32List(melPrefixSamples);
  final Float32List _melInput = Float32List(chunkSamples + melPrefixSamples);
  final Float32List _melBuffer = Float32List(_melBufferMax * melBins);
  int _melBufferLen = 0;
  final Float32List _classifierInput = Float32List(embeddingWindow * embeddingDim);
  final Float32List _scaled = Float32List(chunkSamples);

  // Persistent native input tensors and one run-options handle, following the
  // vsww isolate: the plugin's per-run tensor create/box/release cycle (and
  // the OrtRunOptions it never released) dominates a chain this cheap. See
  // ort_tensor_io.dart.
  final ReusableInputTensor _melTensor =
      ReusableInputTensor.create([1, chunkSamples + melPrefixSamples]);
  final ReusableInputTensor _embTensor =
      ReusableInputTensor.create([1, melWindow, melBins, 1]);
  final OrtRunOptions _runOptions = OrtRunOptions();

  // Reusable per-stage output buffers, sized from the session on first use
  // (the mel output length is not knowable ahead of the first run).
  Float32List? _melOut;
  Float32List? _embOut;

  /// The noise-warmed classifier window, snapshotted after [warmup].
  ///
  /// Restored by [reset] instead of zeroing. An all-zero window is not neutral:
  /// the card learned this the hard way, where zeroing made `alexa` score ~1.0
  /// on silence after every turn. Noise is what openWakeWord itself pre-fills
  /// with (`feature_buffer = self._get_embeddings(noise)`).
  Float32List? _warmClassifierInput;

  /// Match openWakeWord's `melspectrogram_buffer = np.ones((76, 32))`.
  void _initMelBuffer() {
    _melBuffer.fillRange(0, melWindow * melBins, 1);
    _melBufferLen = melWindow;
  }

  /// Pre-fill the classifier window with embeddings of pseudo-random noise, so
  /// it never sees zero padding before real speech arrives. Deterministic, so
  /// two runs warm to the same state.
  void warmup() {
    _audioHistory.fillRange(0, _audioHistory.length, 0);
    _initMelBuffer();

    const warmupChunks = embeddingWindow;
    final audio = Float32List(warmupChunks * chunkSamples);
    var state = 0x9E3779B1; // Weyl sequence seed, as the card uses
    for (var i = 0; i < audio.length; i++) {
      state = (state + 0x9E3779B1) & 0xFFFFFFFF;
      // Map [0, 2^32) -> [-1000, 1000): int16-range values, since this feeds
      // the same scaled path as live audio.
      audio[i] = ((state / 0x100000000) * 2000).floorToDouble() - 1000;
    }

    for (var c = 0; c < warmupChunks; c++) {
      final chunk = Float32List.sublistView(
          audio, c * chunkSamples, (c + 1) * chunkSamples);
      _appendEmbedding(_runFrontend(chunk));
    }
    _warmClassifierInput = Float32List.fromList(_classifierInput);
  }

  /// Feed one 1280-sample chunk of +/-1 audio; returns the classifier input
  /// window to score, or null if the pipeline could not run.
  Float32List? process(Float32List samples) {
    for (var i = 0; i < chunkSamples; i++) {
      _scaled[i] = samples[i] * 32768;
    }
    final emb = _runFrontend(_scaled);
    if (emb == null) return null;
    _appendEmbedding(emb);
    return _classifierInput;
  }

  /// mel + embedding for one already-scaled chunk.
  Float32List? _runFrontend(Float32List scaledChunk) {
    // 480 samples of history + this chunk, matching the card's mel call.
    _melInput.setRange(0, melPrefixSamples, _audioHistory);
    _melInput.setRange(melPrefixSamples, melPrefixSamples + chunkSamples, scaledChunk);
    _audioHistory.setRange(
        0, melPrefixSamples, scaledChunk, chunkSamples - melPrefixSamples);

    final mel =
        _melOut = _runStage(melSession, _melInputName, _melTensor, _melInput, _melOut);
    if (mel == null) return null;
    _appendMel(mel);

    if (_melBufferLen < melWindow) return null;
    final start = (_melBufferLen - melWindow) * melBins;
    final window = Float32List.sublistView(
        _melBuffer, start, start + melWindow * melBins);
    return _embOut =
        _runStage(embeddingSession, _embInputName, _embTensor, window, _embOut);
  }

  /// Apply `x / 10 + 2` and append each frame to the rolling mel buffer.
  void _appendMel(Float32List melOut) {
    final numFrames = melOut.length ~/ melBins;
    if (numFrames == 0) return;
    var len = _melBufferLen;
    if (len + numFrames > _melBufferMax) {
      // Slide the newest melWindow frames to the front and continue.
      final keep = melWindow;
      _melBuffer.setRange(0, keep * melBins, _melBuffer, (len - keep) * melBins);
      len = keep;
    }
    final writeOff = len * melBins;
    for (var i = 0; i < numFrames * melBins; i++) {
      _melBuffer[writeOff + i] = melOut[i] * 0.1 + 2;
    }
    _melBufferLen = len + numFrames;
  }

  void _appendEmbedding(Float32List? emb) {
    if (emb == null) return;
    _classifierInput.setRange(
        0, (embeddingWindow - 1) * embeddingDim, _classifierInput, embeddingDim);
    _classifierInput.setRange(
        (embeddingWindow - 1) * embeddingDim, embeddingWindow * embeddingDim, emb);
  }

  /// Run one stage through its persistent input tensor, reading the float32
  /// output straight out of ORT's buffer into the stage's reusable [out]
  /// (allocated on the first run; the count is fixed after that because the
  /// input shape never changes).
  Float32List? _runStage(OrtSession session, String inputName,
      ReusableInputTensor input, Float32List data, Float32List? out) {
    input.write(data);
    List<OrtValue?>? outputs;
    try {
      outputs = session.run(_runOptions, {inputName: input.tensor});
      final value = outputs.isNotEmpty ? outputs[0] : null;
      if (value == null) return null;
      out ??= Float32List(tensorElementCount(value));
      readFloatTensor(value, out);
      return out;
    } finally {
      outputs?.forEach((o) => o?.release());
    }
  }

  /// Wipe per-stream history so the next chunk is treated as a cold start,
  /// restoring the noise-warmed classifier window rather than zeroing it.
  void reset() {
    _audioHistory.fillRange(0, _audioHistory.length, 0);
    _initMelBuffer();
    final warm = _warmClassifierInput;
    if (warm != null) _classifierInput.setAll(0, warm);
  }

  /// Release the pipeline's native input tensors and run options. The two
  /// sessions stay alive; they belong to the caller.
  void dispose() {
    _melTensor.release();
    _embTensor.release();
    _runOptions.release();
  }

  /// Chunk RMS, for the card's energy gate.
  static double rms(Float32List samples) {
    var sum = 0.0;
    for (var i = 0; i < samples.length; i++) {
      sum += samples[i] * samples[i];
    }
    return math.sqrt(sum / samples.length);
  }
}
