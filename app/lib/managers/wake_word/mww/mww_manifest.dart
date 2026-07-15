/// microWakeWord model manifest, as served by Voice Satellite at
/// `<ha>/voice_satellite/models/<name>.json`.
///
/// Only the `micro` block matters to us; the rest is provenance for humans.
/// Example (ok_nabu):
///
/// ```json
/// { "type": "micro", "wake_word": "Okay Nabu", "model": "okay_nabu.tflite",
///   "micro": { "probability_cutoff": 0.85, "feature_step_size": 10,
///              "sliding_window_size": 5, "tensor_arena_size": 37000 } }
/// ```
///
/// Note `model` names the ESPHome-side file and does NOT necessarily match the
/// file Voice Satellite serves (ok_nabu.json ships alongside ok_nabu.tflite,
/// while `model` says okay_nabu.tflite). The URL is derived from the manifest's
/// own path instead, which is what the card's browser runner does too.
class MwwManifest {
  MwwManifest({
    required this.wakeWord,
    required this.probabilityCutoff,
    required this.slidingWindowSize,
    required this.featureStepSize,
  });

  final String wakeWord;

  /// Sliding-window mean above which the wake word counts as heard.
  final double probabilityCutoff;

  /// How many probabilities the mean is taken over.
  final int slidingWindowSize;

  /// Feature frames per inference in the trained model. The real value is
  /// probed off the input tensor at load ([1, 3, 40] -> 3); this is only the
  /// fallback, since the tensor is authoritative and the manifest is not.
  final int featureStepSize;

  static MwwManifest? fromJson(Map<String, Object?> json) {
    final micro = json['micro'];
    if (micro is! Map) return null;
    final cutoff = (micro['probability_cutoff'] as num?)?.toDouble();
    final window = (micro['sliding_window_size'] as num?)?.toInt();
    if (cutoff == null || window == null || window <= 0) return null;
    return MwwManifest(
      wakeWord: json['wake_word'] as String? ?? '',
      probabilityCutoff: cutoff,
      slidingWindowSize: window,
      featureStepSize: (micro['feature_step_size'] as num?)?.toInt() ?? 1,
    );
  }
}
