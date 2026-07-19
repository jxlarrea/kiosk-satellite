/// Parsed `vs-wake-word-ctc-v1` manifest (the JSON that ships beside each
/// vsWakeWord `.onnx`). Mirrors the fields the Voice Satellite runtime reads;
/// see the port spec in the wake-word docs.
library;

class VswwFeatureConfig {
  const VswwFeatureConfig({
    required this.sampleRate,
    required this.nFft,
    required this.nMels,
    required this.fMin,
    required this.fMax,
    required this.logFloor,
    required this.frameSamples,
    required this.hopSamples,
    required this.windowSamples,
    required this.frames,
  });

  final int sampleRate;
  final int nFft;
  final int nMels;
  final double fMin;
  final double fMax;
  final double logFloor;
  final int frameSamples;
  final int hopSamples;
  final int windowSamples;
  final int frames;

  factory VswwFeatureConfig.fromJson(Map<String, dynamic> j) {
    return VswwFeatureConfig(
      sampleRate: (j['sample_rate'] as num).toInt(),
      nFft: (j['n_fft'] as num).toInt(),
      nMels: (j['n_mels'] as num).toInt(),
      fMin: (j['f_min'] as num).toDouble(),
      fMax: (j['f_max'] as num).toDouble(),
      logFloor: (j['log_floor'] as num).toDouble(),
      frameSamples: (j['frame_samples'] as num).toInt(),
      hopSamples: (j['hop_samples'] as num).toInt(),
      windowSamples: (j['window_samples'] as num).toInt(),
      frames: (j['frames'] as num).toInt(),
    );
  }
}

class VswwCtcConfig {
  const VswwCtcConfig({
    required this.vocabSize,
    required this.blankId,
    required this.padId,
    required this.wordSepId,
    required this.wakeWordTargets,
    required this.maxEditDistance,
    required this.trailTolerance,
    required this.minMatchedConfidence,
    required this.targetMaxEditDistance,
    required this.targetMinMatchedConfidence,
    required this.inventory,
    required this.targetPhonemes,
  });

  final int vocabSize;
  final int blankId;
  final int padId;
  final int wordSepId;

  /// Phoneme label per vocab id, for rendering a decode as readable
  /// phonemes in the wake-word tester. Empty when the manifest omits it.
  final List<String> inventory;

  /// The wake-word targets as phoneme labels (one list per target), so the
  /// tester can show what the model is listening *for*.
  final List<List<String>> targetPhonemes;

  /// A decoded id sequence rendered to phoneme labels (blanks/pads dropped).
  String phonemesFor(List<int> ids) {
    if (inventory.isEmpty) return '';
    final out = <String>[];
    for (final id in ids) {
      if (id == blankId || id == padId) continue;
      if (id == wordSepId) {
        out.add('_');
      } else if (id >= 0 && id < inventory.length) {
        out.add(inventory[id]);
      }
    }
    return out.join(' ');
  }

  /// Each target is a sequence of phoneme ids.
  final List<List<int>> wakeWordTargets;

  final int maxEditDistance;

  /// -1 = disabled.
  final int trailTolerance;

  /// Global confidence gate in raw-logit units (-inf = disabled).
  final double minMatchedConfidence;

  /// Per-target overrides (empty = use global).
  final List<int> targetMaxEditDistance;
  final List<double> targetMinMatchedConfidence;

  int maxEditFor(int targetIndex) =>
      targetIndex < targetMaxEditDistance.length
          ? targetMaxEditDistance[targetIndex]
          : maxEditDistance;

  double minConfidenceFor(int targetIndex) =>
      targetIndex < targetMinMatchedConfidence.length
          ? targetMinMatchedConfidence[targetIndex]
          : minMatchedConfidence;

  factory VswwCtcConfig.fromJson(Map<String, dynamic> j) {
    List<List<int>> targets = ((j['wake_word_targets'] as List?) ?? const [])
        .map((t) => (t as List).map((e) => (e as num).toInt()).toList())
        .toList();
    return VswwCtcConfig(
      vocabSize: (j['vocab_size'] as num).toInt(),
      blankId: (j['blank_id'] as num?)?.toInt() ?? 1,
      padId: (j['pad_id'] as num?)?.toInt() ?? 0,
      wordSepId: (j['word_sep_id'] as num?)?.toInt() ?? 2,
      wakeWordTargets: targets,
      maxEditDistance: (j['max_edit_distance'] as num?)?.toInt() ?? 1,
      trailTolerance: (j['wake_word_trail_tolerance'] as num?)?.toInt() ?? -1,
      minMatchedConfidence:
          (j['min_matched_confidence'] as num?)?.toDouble() ?? double.negativeInfinity,
      targetMaxEditDistance:
          ((j['target_max_edit_distance'] as List?) ?? const [])
              .map((e) => (e as num).toInt())
              .toList(),
      targetMinMatchedConfidence:
          ((j['target_min_matched_confidence'] as List?) ?? const [])
              .map((e) => (e as num).toDouble())
              .toList(),
      inventory: ((j['inventory'] as List?) ?? const [])
          .map((e) => '$e')
          .toList(),
      targetPhonemes:
          ((j['wake_word_target_phonemes'] as List?) ?? const [])
              .map((t) => (t as List).map((e) => '$e').toList())
              .toList(),
    );
  }
}

class VswwRuntimeConfig {
  const VswwRuntimeConfig({
    required this.requiredHits,
    required this.cooldownMs,
    required this.highConfidenceBypass,
    required this.highConfidenceBypassMinHits,
    required this.streamMatch,
    required this.streamBufferMs,
    required this.streamLagFrames,
  });

  final int requiredHits;
  final int cooldownMs;

  /// Raw-logit threshold; null = disabled.
  final double? highConfidenceBypass;
  final int highConfidenceBypassMinHits;
  final bool streamMatch;
  final int streamBufferMs;
  final int streamLagFrames;

  factory VswwRuntimeConfig.fromJson(Map<String, dynamic> j) {
    return VswwRuntimeConfig(
      requiredHits: (j['required_hits'] as num?)?.toInt() ?? 1,
      cooldownMs: (j['cooldown_ms'] as num?)?.toInt() ?? 2000,
      highConfidenceBypass: (j['high_confidence_bypass'] as num?)?.toDouble(),
      highConfidenceBypassMinHits:
          (j['high_confidence_bypass_min_hits'] as num?)?.toInt() ?? 1,
      streamMatch: (j['stream_match'] as bool?) ?? true,
      streamBufferMs: (j['stream_buffer_ms'] as num?)?.toInt() ?? 2500,
      streamLagFrames: (j['stream_lag_frames'] as num?)?.toInt() ?? 20,
    );
  }
}

/// A full parsed CTC manifest.
class VswwManifest {
  const VswwManifest({
    required this.name,
    required this.format,
    required this.recommendedThreshold,
    required this.inputShape,
    required this.outputShape,
    required this.feature,
    required this.ctc,
    required this.runtime,
    required this.windowMs,
  });

  final String name;
  final String format;
  final double recommendedThreshold;
  final List<int> inputShape; // [1, frames, mels]
  final List<int> outputShape; // [1, T_out, vocab]
  final VswwFeatureConfig feature;
  final VswwCtcConfig ctc;
  final VswwRuntimeConfig runtime;
  final double windowMs;

  bool get isCtc => format == 'vs-wake-word-ctc-v1';
  int get tOut => outputShape[1];

  factory VswwManifest.fromJson(Map<String, dynamic> j) {
    final feature = VswwFeatureConfig.fromJson(
        (j['feature_config'] as Map).cast<String, dynamic>());
    return VswwManifest(
      name: j['name'] as String,
      format: j['format'] as String,
      recommendedThreshold:
          (j['recommended_threshold'] as num?)?.toDouble() ?? 0.5,
      inputShape: ((j['input'] as Map)['shape'] as List)
          .map((e) => (e as num).toInt())
          .toList(),
      outputShape: ((j['output'] as Map)['shape'] as List)
          .map((e) => (e as num).toInt())
          .toList(),
      feature: feature,
      ctc: VswwCtcConfig.fromJson((j['ctc'] as Map).cast<String, dynamic>()),
      runtime: VswwRuntimeConfig.fromJson(
          ((j['runtime'] as Map?) ?? const {}).cast<String, dynamic>()),
      // window_ms drives the stream frame timing; default from window/sr.
      windowMs: ((j['feature_config'] as Map)['window_ms'] as num?)?.toDouble() ??
          (feature.windowSamples * 1000 / feature.sampleRate),
    );
  }
}
