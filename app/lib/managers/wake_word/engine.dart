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

import 'dart:typed_data';

typedef DetectionCallback = Future<void> Function(WakeWordModelRef model);
typedef StopDetectionCallback = Future<void> Function();

/// Why an engine could not run, or stopped running.
///
/// A code rather than a message, because the UI has to *act* on the difference:
/// a blocked microphone needs a link to the OS settings, a declined one needs a
/// retry, and a model that would not download needs neither.
enum EngineFailure {
  /// The microphone grant was refused, and can be asked for again.
  micDeclined,

  /// The microphone grant was refused for good; only the OS settings can undo
  /// it. See [PermissionOutcome.blocked].
  micBlocked,

  /// The microphone was granted, opened, and then died — permission revoked
  /// underneath us, or another app took the device.
  micLost,

  /// No model could be loaded, so there is nothing to listen with.
  modelsUnavailable,
}

/// The engine cannot run this config, or can no longer run it.
///
/// Reported so the manager can tell Voice Satellite it is not covered, rather
/// than leave the card trusting a runner that has gone deaf, and so the UIs can
/// say something truer than "it isn't working". [detail] is for the log.
typedef EngineFailureCallback = void Function(EngineFailure kind, String detail);

enum WakeWordEngineType { microWakeWord, openWakeWord, vsWakeWord }

WakeWordEngineType? engineTypeFromWire(String? value) => switch (value) {
      'microWakeWord' || 'mww' => WakeWordEngineType.microWakeWord,
      'openWakeWord' || 'oww' => WakeWordEngineType.openWakeWord,
      'vsWakeWord' || 'vww' => WakeWordEngineType.vsWakeWord,
      _ => null,
    };

extension WakeWordEngineTypeLabel on WakeWordEngineType {
  /// Human-readable engine name for the settings UI.
  String get label => switch (this) {
        WakeWordEngineType.microWakeWord => 'microWakeWord',
        WakeWordEngineType.openWakeWord => 'openWakeWord',
        WakeWordEngineType.vsWakeWord => 'vsWakeWord',
      };
}

/// A model as pushed by Voice Satellite: identity plus where to fetch the
/// model + manifest from the HA instance.
class WakeWordModelRef {
  const WakeWordModelRef({
    required this.id,
    required this.wakeWord,
    required this.manifestUrl,
    this.confidenceScale = 1.0,
    this.cutoff,
  });

  final String id;

  /// Human-readable phrase, e.g. "Okay Nabu".
  final String wakeWord;

  /// Absolute URL of the model's JSON manifest on the HA instance.
  final String manifestUrl;

  /// An absolute detection cutoff resolved by Voice Satellite, or null to use
  /// the model manifest's own (scaled by [confidenceScale]).
  ///
  /// openWakeWord ships no manifest: its cutoff is entirely the card's policy,
  /// so we are handed the finished number. vsWakeWord and microWakeWord carry
  /// theirs in the manifest we download, so those get a multiplier instead.
  /// Either way the card decides and we apply.
  final double? cutoff;

  /// Multiplier for this model's confidence gates, resolved by Voice Satellite
  /// from its Sensitivity setting.
  ///
  /// We deliberately do not know what "Very sensitive" means: that mapping is
  /// the card's policy and lives there alone, so it can be retuned without an
  /// app release. All we do is multiply, exactly as the card's own browser
  /// engine does (min_matched_confidence, each target_min_matched_confidence,
  /// and runtime.high_confidence_bypass). 1.0 leaves the manifest untouched.
  final double confidenceScale;

  Map<String, Object?> toJson() => {
        'id': id,
        'wakeWord': wakeWord,
        'manifestUrl': manifestUrl,
        'confidenceScale': confidenceScale,
        if (cutoff != null) 'cutoff': cutoff,
      };

  @override
  bool operator ==(Object other) =>
      other is WakeWordModelRef &&
      other.id == id &&
      other.wakeWord == wakeWord &&
      other.manifestUrl == manifestUrl &&
      other.confidenceScale == confidenceScale &&
      other.cutoff == cutoff;

  @override
  int get hashCode =>
      Object.hash(id, wakeWord, manifestUrl, confidenceScale, cutoff);
}

/// Voice Satellite's energy gate, already resolved to numbers.
///
/// Skips inference while the room is quiet, which on an always-listening
/// tablet is nearly all the time. As with [WakeWordModelRef.confidenceScale],
/// we are told the thresholds rather than the Sensitivity label or the
/// noise_gate switch: the policy is the card's.
class EnergyGateConfig {
  const EnergyGateConfig({
    required this.enabled,
    required this.wakeRms,
    required this.sleepAfterChunks,
  });

  /// Off unless the card's noise_gate switch is on.
  final bool enabled;

  /// Chunk RMS at or above which audio counts as speech.
  final double wakeRms;

  /// Consecutive sub-threshold chunks before inference sleeps.
  final int sleepAfterChunks;

  /// A disabled gate: what an older card that sends none implies.
  static const off =
      EnergyGateConfig(enabled: false, wakeRms: 0, sleepAfterChunks: 0);

  static EnergyGateConfig fromJson(Object? raw) {
    if (raw is! Map) return off;
    final wakeRms = (raw['wakeRms'] as num?)?.toDouble();
    final sleepAfter = (raw['sleepAfterChunks'] as num?)?.toInt();
    if (wakeRms == null || sleepAfter == null || sleepAfter <= 0) return off;
    return EnergyGateConfig(
      enabled: raw['enabled'] == true,
      wakeRms: wakeRms,
      sleepAfterChunks: sleepAfter,
    );
  }

  Map<String, Object?> toJson() => {
        'enabled': enabled,
        'wakeRms': wakeRms,
        'sleepAfterChunks': sleepAfterChunks,
      };

  @override
  bool operator ==(Object other) =>
      other is EnergyGateConfig &&
      other.enabled == enabled &&
      other.wakeRms == wakeRms &&
      other.sleepAfterChunks == sleepAfterChunks;

  @override
  int get hashCode => Object.hash(enabled, wakeRms, sleepAfterChunks);
}

/// The configuration Voice Satellite pushes: one engine, one or two models
/// (VS supports two wake words routed to separate pipeline slots).
class WakeWordConfig {
  const WakeWordConfig({
    required this.engine,
    required this.models,
    this.stopModel,
    this.energyGate = EnergyGateConfig.off,
  });

  final WakeWordEngineType engine;
  final List<WakeWordModelRef> models;

  /// Skip-inference-while-quiet policy, resolved by the card.
  final EnergyGateConfig energyGate;

  /// Optional stop-word classifier ("ok_stop"), pushed when Voice Satellite's
  /// stop_word switch is on. Loaded alongside the wake words but only armed
  /// while the card says an interruptible state is running (TTS, media, a
  /// ringing timer), since it is only meaningful then.
  final WakeWordModelRef? stopModel;

  static WakeWordModelRef? _refFrom(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final wakeWord = raw['wakeWord'];
    final manifestUrl = raw['manifestUrl'];
    if (id is String && wakeWord is String && manifestUrl is String) {
      final scale = (raw['confidenceScale'] as num?)?.toDouble();
      return WakeWordModelRef(
        id: id,
        wakeWord: wakeWord,
        manifestUrl: manifestUrl,
        // An older card sends no scale; leave the manifest gates alone.
        confidenceScale: scale != null && scale > 0 ? scale : 1.0,
        cutoff: (raw['cutoff'] as num?)?.toDouble(),
      );
    }
    return null;
  }

  static WakeWordConfig? fromJson(Map<String, Object?> json) {
    final engine = engineTypeFromWire(json['engine'] as String?);
    final rawModels = json['models'];
    if (engine == null || rawModels is! List) return null;
    final models = <WakeWordModelRef>[];
    for (final raw in rawModels) {
      final ref = _refFrom(raw);
      if (ref != null) models.add(ref);
    }
    if (models.isEmpty) return null;
    return WakeWordConfig(
      engine: engine,
      models: models,
      stopModel: _refFrom(json['stopModel']),
      energyGate: EnergyGateConfig.fromJson(json['energyGate']),
    );
  }

  /// Value equality so the manager can tell a genuine config change (the user
  /// switched wake word, or turned the stop word on) from the card re-pushing
  /// the same config on every page load. Only the former is worth a restart.
  @override
  bool operator ==(Object other) =>
      other is WakeWordConfig &&
      other.engine == engine &&
      other.stopModel == stopModel &&
      other.energyGate == energyGate &&
      _listEquals(other.models, models);

  @override
  int get hashCode =>
      Object.hash(engine, stopModel, energyGate, Object.hashAll(models));

  static bool _listEquals(List<WakeWordModelRef> a, List<WakeWordModelRef> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

abstract class WakeWordEngine {
  /// Engines this implementation can run natively. The manager reports
  /// `available: false` for configs outside this set so Voice Satellite
  /// keeps using its browser engine instead.
  Set<WakeWordEngineType> get supportedEngines;

  bool get running;

  /// True when this engine can run the config's stop model natively. The
  /// manager reports it back to the card, which keeps its own browser stop
  /// classifier loaded when we answer false.
  bool get supportsStopWord => false;


  Future<void> start({
    required WakeWordConfig config,
    required DetectionCallback onDetection,
    StopDetectionCallback? onStopDetection,
    EngineFailureCallback? onFailure,
  });

  Future<void> stop();

  /// Arm/disarm the stop-word classifier. Unlike wake detection this runs
  /// *during* a voice turn (that is the whole point: interrupting playback),
  /// so it is independent of [pauseDetection].
  Future<void> setStopWordActive(bool active) async {}

  /// Pause/resume *detection* without tearing the engine down. The mic stays
  /// open and the models stay loaded, so resuming is instant — as opposed to
  /// stop()+start(), which re-downloads/recompiles every model.
  ///
  /// This is what runs between a wake word and the end of the voice turn: the
  /// page owns the audio during the turn, and we re-arm afterwards.
  Future<void> pauseDetection() async {}
  Future<void> resumeDetection() async {}

  /// Stream captured audio to the page (the app owns the mic; the card uses
  /// this instead of getUserMedia). [onChunk] receives raw 16 kHz mono PCM16
  /// little-endian bytes, starting with a short pre-roll of already-captured
  /// audio so speech right after the wake word isn't lost. `preRoll` marks
  /// those replayed chunks, so consumers that render audio live (a level
  /// meter) can skip past audio while the pipeline still consumes it.
  ///
  /// After a detection the pre-roll is trimmed so the wake word itself is
  /// never replayed into the stream. **Every engine must honour this**, which
  /// is what lets the card's one-shot handling work regardless of engine:
  ///
  ///  - An engine that can locate where the wake word *ended* (vsWakeWord,
  ///    via its CTC alignment) trims to exactly that point, keeping the audio
  ///    between the wake word ending and detection settling. That is the part
  ///    a one-shot phrase's command starts in.
  ///  - An engine that cannot (microWakeWord, openWakeWord, and any other
  ///    sliding-window classifier that only knows the wake word occurred
  ///    somewhere in the last window) trims to the detection instant instead.
  ///    Detection never fires before the wake word ends, so this is always
  ///    safe, and it is exactly what the card's own browser path does.
  ///
  /// So the wake end is a quality improvement, not a prerequisite: a
  /// classifier engine gives up the audio between wake end and detection, the
  /// same audio the browser gives up, and nothing more.
  Future<void> startAudioStream(
      void Function(Uint8List pcm, bool preRoll) onChunk) async {}
  Future<void> stopAudioStream() async {}
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
    StopDetectionCallback? onStopDetection,
    EngineFailureCallback? onFailure,
  }) async {
    _running = true;
  }

  @override
  Future<void> stop() async {
    _running = false;
  }
}
