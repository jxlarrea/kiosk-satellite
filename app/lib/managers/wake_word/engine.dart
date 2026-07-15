/// Wake-word engine abstraction.
///
/// Kiosk Satellite does not own wake-word configuration — it is *inherited*
/// from Voice Satellite in Home Assistant. VS supports three engines
/// (microWakeWord, openWakeWord, vsWakeWord), each with its own model
/// catalog served by the VS integration as static HTTP paths under
/// `<ha>/voice_satellite/models/` (`.tflite`/`.onnx` + `.json` manifests).
/// The VS card pushes the active engine + model manifest URLs through the
/// JS API (`setWakeWordConfig`); the app reports whether it can run that
/// engine natively so the card can fall back to browser detection.
library;

typedef DetectionCallback = Future<void> Function(WakeWordModelRef model);

enum WakeWordEngineType { microWakeWord, openWakeWord, vsWakeWord }

WakeWordEngineType? engineTypeFromWire(String? value) => switch (value) {
      'microWakeWord' || 'mww' => WakeWordEngineType.microWakeWord,
      'openWakeWord' || 'oww' => WakeWordEngineType.openWakeWord,
      'vsWakeWord' || 'vww' => WakeWordEngineType.vsWakeWord,
      _ => null,
    };

/// A model as pushed by Voice Satellite: identity plus where to fetch the
/// model + manifest from the HA instance.
class WakeWordModelRef {
  const WakeWordModelRef({
    required this.id,
    required this.wakeWord,
    required this.manifestUrl,
  });

  final String id;

  /// Human-readable phrase, e.g. "Okay Nabu".
  final String wakeWord;

  /// Absolute URL of the model's JSON manifest on the HA instance.
  final String manifestUrl;

  Map<String, Object?> toJson() =>
      {'id': id, 'wakeWord': wakeWord, 'manifestUrl': manifestUrl};
}

/// The configuration Voice Satellite pushes: one engine, one or two models
/// (VS supports two wake words routed to separate pipeline slots).
class WakeWordConfig {
  const WakeWordConfig({required this.engine, required this.models});

  final WakeWordEngineType engine;
  final List<WakeWordModelRef> models;

  static WakeWordConfig? fromJson(Map<String, Object?> json) {
    final engine = engineTypeFromWire(json['engine'] as String?);
    final rawModels = json['models'];
    if (engine == null || rawModels is! List) return null;
    final models = <WakeWordModelRef>[];
    for (final raw in rawModels) {
      if (raw is! Map) continue;
      final id = raw['id'];
      final wakeWord = raw['wakeWord'];
      final manifestUrl = raw['manifestUrl'];
      if (id is String && wakeWord is String && manifestUrl is String) {
        models.add(WakeWordModelRef(
            id: id, wakeWord: wakeWord, manifestUrl: manifestUrl));
      }
    }
    if (models.isEmpty) return null;
    return WakeWordConfig(engine: engine, models: models);
  }
}

abstract class WakeWordEngine {
  /// Engines this implementation can run natively. The manager reports
  /// `available: false` for configs outside this set so Voice Satellite
  /// keeps using its browser engine instead.
  Set<WakeWordEngineType> get supportedEngines;

  bool get running;

  Future<void> start({
    required WakeWordConfig config,
    required DetectionCallback onDetection,
  });

  Future<void> stop();
}

/// No-op engine: supports nothing, never detects. Keeps the manager's state
/// machine and the JS handoff contract fully testable (see the
/// `simulateWakeWord` command) before the native TFLite work lands.
// TODO(milestone-2): native microWakeWord via tflite_flutter, downloading
// the .tflite + manifest from the URLs in WakeWordConfig.
class StubWakeWordEngine extends WakeWordEngine {
  bool _running = false;

  @override
  Set<WakeWordEngineType> get supportedEngines => const {};

  @override
  bool get running => _running;

  @override
  Future<void> start({
    required WakeWordConfig config,
    required DetectionCallback onDetection,
  }) async {
    _running = true;
  }

  @override
  Future<void> stop() async {
    _running = false;
  }
}
