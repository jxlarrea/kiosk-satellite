/// Wake-word engine abstraction.
///
/// The real implementation (milestone 2) captures 16 kHz mono audio and runs
/// microWakeWord streaming .tflite models — the same model files Voice
/// Satellite bundles — via tflite_flutter. The stub keeps the manager's
/// state machine and the JS handoff contract fully testable (see the
/// `simulateWakeWord` command) before any native audio work lands.
library;

typedef DetectionCallback = Future<void> Function(String model);

class WakeWordModelInfo {
  const WakeWordModelInfo({
    required this.id,
    required this.wakeWord,
    required this.engine,
  });

  final String id;
  final String wakeWord;
  final String engine;
}

abstract class WakeWordEngine {
  bool get available;
  bool get running;
  List<WakeWordModelInfo> get models;

  Future<void> start({
    required String model,
    required DetectionCallback onDetection,
  });

  Future<void> stop();

  String phraseFor(String model) {
    for (final m in models) {
      if (m.id == model) return m.wakeWord;
    }
    return model;
  }
}

/// No-op engine: reports the catalog, never detects on its own.
class StubWakeWordEngine extends WakeWordEngine {
  bool _running = false;

  @override
  bool get available => false;

  @override
  bool get running => _running;

  @override
  List<WakeWordModelInfo> get models => const [
        WakeWordModelInfo(
            id: 'okay_nabu', wakeWord: 'Okay Nabu', engine: 'microWakeWord'),
        WakeWordModelInfo(
            id: 'hey_jarvis', wakeWord: 'Hey Jarvis', engine: 'microWakeWord'),
      ];

  @override
  Future<void> start({
    required String model,
    required DetectionCallback onDetection,
  }) async {
    _running = true;
  }

  @override
  Future<void> stop() async {
    _running = false;
  }
}
