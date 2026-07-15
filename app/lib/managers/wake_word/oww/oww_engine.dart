import 'dart:isolate';

import '../engine.dart';
import '../isolate_engine.dart';
import 'oww_isolate.dart';
import 'oww_model_store.dart';

/// Native openWakeWord engine.
///
/// The three-stage chain — melspectrogram, embedding, per-word classifier —
/// runs in [owwIsolateEntry]; the base owns the mic and the pre-roll. The card
/// runs this same chain on WebGPU because its embedding model is ~80 ms per
/// chunk in pure JS; natively on the CPU the whole chain is ~3.8 ms.
///
/// Like microWakeWord and unlike vsWakeWord this reports no wake-word *end*: a
/// window classifier knows only that the wake word occurred recently, so the
/// stream starts at the detection instant, which is never earlier than the wake
/// word finished (see WakeWordEngine.startAudioStream).
class OwwEngine extends IsolateWakeEngine {
  OwwEngine(super.log, {OwwModelStore? store, super.mic, super.spawner})
      : _store = store ?? OwwModelStore();

  final OwwModelStore _store;

  @override
  String get tag => 'oww';

  @override
  WakeWordEngineType get engineType => WakeWordEngineType.openWakeWord;

  @override
  void Function(SendPort) get isolateEntry => owwIsolateEntry;

  @override
  Future<WakeModelPayload?> loadModels(WakeWordConfig config) async {
    // openWakeWord ships no manifests: the card sends the classifier URL and
    // the finished cutoff, and the two shared stages live in the same
    // directory. So this only fetches bytes.
    final models = <Map<String, Object>>[];
    for (final ref in config.models) {
      try {
        final bytes = await _store.fetchModel(ref.manifestUrl);
        models.add({
          'id': ref.id,
          'wakeWord': ref.wakeWord,
          'onnx': bytes,
          // The card resolved its Sensitivity setting into this absolute
          // cutoff; 0.5 only covers a card too old to send one.
          'cutoff': ref.cutoff ?? 0.5,
        });
        log.info(tag, 'downloaded "${ref.id}" (${bytes.length} bytes)');
      } catch (e) {
        log.error(tag, 'download "${ref.id}" failed: $e');
      }
    }

    // The stop classifier is just another openWakeWord model, disarmed until
    // the card reports an interruptible state. Not fatal if it fails.
    var hasStop = false;
    final stopRef = config.stopModel;
    if (stopRef != null) {
      try {
        final bytes = await _store.fetchModel(stopRef.manifestUrl);
        models.add({
          'id': stopRef.id,
          'wakeWord': stopRef.wakeWord,
          'onnx': bytes,
          'cutoff': stopRef.cutoff ?? 0.65,
          'stop': true,
        });
        hasStop = true;
        log.info(
            tag, 'downloaded stop model "${stopRef.id}" (${bytes.length} bytes)');
      } catch (e) {
        log.error(tag, 'download stop model "${stopRef.id}" failed: $e');
      }
    }
    if (models.isEmpty) return null;

    // mel + embedding: shared by every wake word, fetched once. Unlike a
    // per-word failure this one is fatal — without them nothing can score.
    final OwwSharedModels shared;
    try {
      shared = await _store.shared(config.models.first.manifestUrl);
    } catch (e) {
      log.error(tag, 'shared model download failed: $e');
      return null;
    }

    return WakeModelPayload(
      models: models,
      hasStopModel: hasStop,
      extraInit: {
        'melspectrogram': shared.melspectrogram,
        'embedding': shared.embedding,
      },
    );
  }
}
