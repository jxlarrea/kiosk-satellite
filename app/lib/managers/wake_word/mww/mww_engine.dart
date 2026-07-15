import 'dart:isolate';

import '../engine.dart';
import '../isolate_engine.dart';
import 'mww_isolate.dart';
import 'mww_model_store.dart';

/// Native microWakeWord engine.
///
/// The feature frontend, TFLite invoke and detection gate run in
/// [mwwIsolateEntry]; the base owns the mic and the pre-roll.
///
/// This reports no wake-word *end*: microWakeWord is a sliding-window
/// classifier that knows only that the wake word occurred in the recent window,
/// so the stream starts at the detection instant. That is never earlier than
/// the wake word finished, so the wake word is still never replayed into STT
/// (see WakeWordEngine.startAudioStream).
class MwwEngine extends IsolateWakeEngine {
  MwwEngine(super.log, {MwwModelStore? store, super.mic, super.spawner})
      : _store = store ?? MwwModelStore();

  final MwwModelStore _store;

  @override
  String get tag => 'mww';

  @override
  WakeWordEngineType get engineType => WakeWordEngineType.microWakeWord;

  @override
  void Function(SendPort) get isolateEntry => mwwIsolateEntry;

  @override
  Future<WakeModelPayload?> loadModels(WakeWordConfig config) async {
    final models = <Map<String, Object>>[];
    for (final ref in config.models) {
      try {
        final model = await _store.fetch(ref.manifestUrl);
        models.add(_entry(ref, model));
        log.info(
            tag, 'downloaded "${ref.id}" (${model.tfliteBytes.length} bytes)');
      } catch (e) {
        log.error(tag, 'download "${ref.id}" failed: $e');
      }
    }

    // microWakeWord's stop classifier is just another mww model ('stop'), so it
    // loads exactly like a wake word and stays disarmed until the card reports
    // an interruptible state. Not fatal if it fails: wake detection is still
    // worth running.
    var hasStop = false;
    final stopRef = config.stopModel;
    if (stopRef != null) {
      try {
        final model = await _store.fetch(stopRef.manifestUrl);
        models.add({..._entry(stopRef, model), 'stop': true});
        hasStop = true;
        log.info(tag,
            'downloaded stop model "${stopRef.id}" (${model.tfliteBytes.length} bytes)');
      } catch (e) {
        log.error(tag, 'download stop model "${stopRef.id}" failed: $e');
      }
    }

    return WakeModelPayload(models: models, hasStopModel: hasStop);
  }

  Map<String, Object> _entry(WakeWordModelRef ref, MwwModel model) => {
        'id': ref.id,
        'wakeWord': ref.wakeWord,
        'tflite': model.tfliteBytes,
        // The card resolved its Sensitivity setting into this multiplier; we
        // only apply it. Raising the cutoff makes the model harder to trigger,
        // which is what "Slightly sensitive" (x1.10) means.
        'cutoff': model.manifest.probabilityCutoff * ref.confidenceScale,
        'slidingWindowSize': model.manifest.slidingWindowSize,
      };
}
