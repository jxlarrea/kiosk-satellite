import 'dart:isolate';

import '../engine.dart';
import '../isolate_engine.dart';
import 'model_store.dart';
import 'vsww_isolate.dart';

typedef ModelStoreFactory = VswwModelStore Function();

/// Native vsWakeWord engine.
///
/// The heavy pipeline — ring buffer, log-mel features, ONNX inference, CTC
/// decode/match, detection gate — runs in [vswwIsolateEntry]; the base owns the
/// mic and the pre-roll. Native inference is the whole point of the handoff:
/// the ONNX runs natively instead of the WebGPU/WASM JS runner in the WebView.
///
/// Alone among the three, this engine can say where the wake word *ended*: its
/// CTC decode aligns the match to a frame, so the pre-roll trims to the wake
/// word's last sample rather than to the detection instant.
class VswwEngine extends IsolateWakeEngine {
  VswwEngine(super.log,
      {ModelStoreFactory? storeFactory, super.mic, super.spawner})
      : _store = (storeFactory ?? VswwModelStore.new)();

  final VswwModelStore _store;

  @override
  String get tag => 'vsww';

  @override
  WakeWordEngineType get engineType => WakeWordEngineType.vsWakeWord;

  @override
  void Function(SendPort) get isolateEntry => vswwIsolateEntry;

  @override
  bool get wakeEndIsAligned => true;

  @override
  Future<WakeModelPayload?> loadModels(WakeWordConfig config) async {
    final models = <Map<String, Object>>[];
    for (final ref in config.models) {
      try {
        final model = await _store.fetch(ref.manifestUrl);
        models.add({
          'id': ref.id,
          'wakeWord': ref.wakeWord,
          'manifestJson': model.manifestJson,
          'onnx': model.onnxBytes,
          // The card resolved its Sensitivity setting into this multiplier; we
          // only apply it.
          'confidenceScale': ref.confidenceScale,
        });
        log.info(
            tag, 'downloaded "${ref.id}" (${model.onnxBytes.length} bytes)');
      } catch (e) {
        log.error(tag, 'download "${ref.id}" failed: $e');
      }
    }

    // The stop classifier loads with the wake words but stays disarmed until
    // the card reports an interruptible state. A failure here is not fatal:
    // wake detection is still worth running without it.
    var hasStop = false;
    final stopRef = config.stopModel;
    if (stopRef != null) {
      try {
        final model = await _store.fetch(stopRef.manifestUrl);
        models.add({
          'id': stopRef.id,
          'wakeWord': stopRef.wakeWord,
          'manifestJson': model.manifestJson,
          'onnx': model.onnxBytes,
          'confidenceScale': stopRef.confidenceScale,
          'stop': true,
        });
        hasStop = true;
        log.info(tag,
            'downloaded stop model "${stopRef.id}" (${model.onnxBytes.length} bytes)');
      } catch (e) {
        log.error(tag, 'download stop model "${stopRef.id}" failed: $e');
      }
    }

    return WakeModelPayload(models: models, hasStopModel: hasStop);
  }
}
