import '../wake_word/engine.dart';
import '../wake_word/model_source.dart';
import '../wake_word/pryon/pryon_catalog.dart';

/// The wake words native Voice Satellite can listen for: the models bundled
/// with the app per engine, the microWakeWord models Home Assistant offers
/// from its `config/custom_wake_words` folder and the custom models added to
/// the kiosk itself.
///
/// The tables here are Voice Satellite's own (its wake-word module and the
/// vsWakeWord and openWakeWord sensitivity modules), ported so a kiosk needs
/// nothing in Home Assistant beyond the satellite itself.

/// The engines, by the stored setting value.
const voiceEngines = <String, WakeWordEngineType>{
  'vswakeword': WakeWordEngineType.vsWakeWord,
  'microwakeword': WakeWordEngineType.microWakeWord,
  'openwakeword': WakeWordEngineType.openWakeWord,
  'pryon': WakeWordEngineType.pryon,
};

/// Bundled model ids per engine, in the order the wake word selects offer
/// them. The stop classifiers are not wake words and are listed apart.
const bundledWakeWords = <WakeWordEngineType, List<String>>{
  WakeWordEngineType.vsWakeWord: [
    'ok_nabu',
    'hey_jarvis',
    'alexa',
    'hey_mycroft',
    'hey_home_assistant',
    'hey_luna',
    'ok_computer',
    'ok_luna',
    'ok_nova',
    'ok_vesta',
    'hey_vesta',
    'hey_alfred',
  ],
  WakeWordEngineType.microWakeWord: [
    'ok_nabu',
    'hey_jarvis',
    'alexa',
    'hey_mycroft',
    'hey_home_assistant',
    'hey_luna',
    'okay_computer',
    'hey_baby',
  ],
  WakeWordEngineType.openWakeWord: [
    'ok_nabu',
    'hey_jarvis',
    'alexa',
    'hey_mycroft',
    'home_assistant',
    'hey_luna',
    'okay_computer',
    'hey_rhasspy',
  ],
};

const _stopIds = <WakeWordEngineType, String>{
  WakeWordEngineType.vsWakeWord: 'ok_stop',
  WakeWordEngineType.microWakeWord: 'stop',
  WakeWordEngineType.openWakeWord: 'stop',
};

/// The phrases Home Assistant dedupes simultaneous wakes on and matches its
/// Wake word selects against (Voice Satellite's WAKE_WORD_PHRASES). Anything
/// else is title-cased from the id, as there.
const _phrases = <String, String>{
  'ok_nabu': 'Okay Nabu',
  'hey_jarvis': 'Hey Jarvis',
  'alexa': 'Alexa',
  'hey_mycroft': 'Hey Mycroft',
  'hey_home_assistant': 'Hey Home Assistant',
  'hey_luna': 'Hey Luna',
  'okay_computer': 'Okay Computer',
};

String wakeWordPhraseFor(String id) =>
    _phrases[id] ??
    id
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

String engineFolder(WakeWordEngineType engine) => switch (engine) {
  WakeWordEngineType.vsWakeWord => 'vswakeword',
  WakeWordEngineType.microWakeWord => 'microwakeword',
  WakeWordEngineType.openWakeWord => 'openwakeword',
  WakeWordEngineType.pryon => 'pryon',
};

/// Where a bundled model is: a `.json` manifest for vsWakeWord and
/// microWakeWord (the stores derive the weights from it), the classifier
/// itself for openWakeWord, which ships no manifest.
String bundledModelManifest(WakeWordEngineType engine, String id) {
  final ext = engine == WakeWordEngineType.openWakeWord ? 'onnx' : 'json';
  return bundledModelUrl('assets/wake_words/${engineFolder(engine)}/$id.$ext');
}

/// A microWakeWord model Home Assistant offers from config/custom_wake_words.
class ExternalWakeWord {
  const ExternalWakeWord({
    required this.id,
    required this.wakeWord,
    required this.url,
    required this.modelType,
  });

  final String id;
  final String wakeWord;

  /// The manifest's URL on Home Assistant; the `.tflite` sits beside it.
  final String url;
  final String modelType;

  static ExternalWakeWord? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = '${raw['id'] ?? ''}';
    final url = '${raw['url'] ?? ''}';
    if (id.isEmpty || url.isEmpty) return null;
    return ExternalWakeWord(
      id: id,
      wakeWord: '${raw['wakeWord'] ?? ''}'.isEmpty
          ? wakeWordPhraseFor(id)
          : '${raw['wakeWord']}',
      url: url,
      modelType: '${raw['modelType'] ?? ''}',
    );
  }
}

/// A custom model added to the kiosk: its engine, id (the file name), the
/// phrase it answers to and its model's `file://` URL, the manifest for
/// microWakeWord and vsWakeWord, the classifier for openWakeWord.
class CustomWakeWord {
  const CustomWakeWord({
    required this.engine,
    required this.id,
    required this.phrase,
    required this.url,
  });

  final WakeWordEngineType engine;
  final String id;
  final String phrase;
  final String url;
}

/// A wake word the kiosk can offer: id, phrase and where its model is.
class OfferedWakeWord {
  const OfferedWakeWord(this.id, this.phrase, this.manifestUrl);
  final String id;
  final String phrase;
  final String manifestUrl;
}

/// Everything the engine can listen for right now: its bundled models, for
/// microWakeWord the custom ones Home Assistant offered, then the custom
/// models added to the kiosk for this engine. A custom id wins over a
/// bundled model of the same id (the user put that file there), and the
/// kiosk's own over Home Assistant's.
List<OfferedWakeWord> offeredWakeWords(
  WakeWordEngineType engine, {
  List<ExternalWakeWord> external = const [],
  List<CustomWakeWord> custom = const [],
  String pryonLocale = '',
}) {
  // Amazon's engine listens only with the models the Echo image has for
  // [pryonLocale] (PryonCatalog.resolveLocale).
  if (engine == WakeWordEngineType.pryon) {
    return [
      for (final w in PryonCatalog.wakeWordsFor(pryonLocale))
        OfferedWakeWord(w.id, wakeWordPhraseFor(w.id), w.url),
    ];
  }
  final local = [
    for (final w in custom)
      if (w.engine == engine) w,
  ];
  final localIds = {for (final w in local) w.id};
  final fromHa = engine == WakeWordEngineType.microWakeWord
      ? [
          for (final w in external)
            if ((w.modelType.isEmpty || w.modelType == 'micro') &&
                !localIds.contains(w.id))
              w,
        ]
      : const <ExternalWakeWord>[];
  final customIds = {...localIds, for (final w in fromHa) w.id};
  final offered = [
    for (final id in bundledWakeWords[engine] ?? const <String>[])
      if (!customIds.contains(id))
        OfferedWakeWord(
          id,
          wakeWordPhraseFor(id),
          bundledModelManifest(engine, id),
        ),
    for (final w in fromHa) OfferedWakeWord(w.id, w.wakeWord, w.url),
  ];
  // Home Assistant tells the wake words apart by name, in its selects and
  // when it picks pipeline 1 or 2 by the phrase heard: a custom model named
  // like one already offered goes by its file name instead.
  final taken = {for (final w in offered) w.phrase.toLowerCase()};
  for (final w in local) {
    var phrase = w.phrase;
    if (taken.contains(phrase.toLowerCase())) phrase = wakeWordPhraseFor(w.id);
    final base = phrase;
    for (var n = 2; taken.contains(phrase.toLowerCase()); n++) {
      phrase = '$base $n';
    }
    taken.add(phrase.toLowerCase());
    offered.add(OfferedWakeWord(w.id, phrase, w.url));
  }
  return offered;
}

// ── Sensitivity (Voice Satellite's vsWakeWord and openWakeWord policy) ───

const _confFactors = {'slightly': 1.10, 'moderately': 1.00, 'very': 0.90};
const _stopConfFactors = {'slightly': 1.05, 'moderately': 1.00, 'very': 0.95};
const _owwWakeOffsets = {'slightly': 0.10, 'moderately': 0.0, 'very': -0.10};
const _owwStopOffsets = {'slightly': 0.05, 'moderately': 0.0, 'very': -0.05};
const _energyWake = {'slightly': 0.12, 'moderately': 0.06, 'very': 0.025};

// Amazon's engine accepted spoken "Alexa"s on a Dot at 0.927 to 0.983 against
// its own 0.923, and reports anything above 0.69 as a near miss. So
// "Slightly sensitive" asks a little more of an accept and "Very sensitive"
// takes the near misses closest to the line as well.
const _pryonOffsets = {'slightly': 0.02, 'moderately': 0.0, 'very': -0.06};

// Amazon's stop word is made for "Alexa, stop". A plain "stop" scored 0.20
// to 0.41 on a Dot, so the Echo images have the engine accept it from
// 0.18. "Very sensitive" also takes the near misses just under that, which
// arrive about a second later.
const _pryonStopOffsets = {'slightly': 0.04, 'moderately': 0.0, 'very': -0.03};

/// What Amazon's engine adds to its own threshold, which it reports with
/// each detection.
double pryonThresholdOffsetFor(
  String sensitivity, {
  bool stop = false,
  double tune = 0,
}) =>
    ((stop ? _pryonStopOffsets : _pryonOffsets)[sensitivity] ?? 0.0) -
    0.06 * tune;

/// The factor every confidence gate of a model is multiplied by.
/// [tune] is the Sensitivity fine-tune slider, see [wakeTuneFor].
double confidenceScaleFor(
  String sensitivity, {
  bool stop = false,
  double tune = 0,
}) =>
    ((stop ? _stopConfFactors : _confFactors)[sensitivity] ?? 1.0) - 0.2 * tune;

/// openWakeWord's absolute cutoff, which ships no manifest to scale.
double owwCutoffFor(String sensitivity, {bool stop = false, double tune = 0}) {
  final base = stop ? 0.65 : 0.5;
  final offset = (stop ? _owwStopOffsets : _owwWakeOffsets)[sensitivity] ?? 0.0;
  return (base + offset - 0.1 * tune).clamp(0.1, 0.99).toDouble();
}

/// How much less the wake words take while the kiosk plays audio: half the
/// step between two presets, on top of the sensitivity and the fine-tune.
/// Only for the kiosk's own players, which the echo canceller takes out, so
/// what is left is a residue that costs the wake word some score rather than
/// a song the model has to tell apart from it. Amazon's engine lowers its
/// own threshold while music plays and gets none. The stop word keeps its
/// own, since one that fires too easily pauses the music.
const playbackConfidenceStep = 0.05;
const playbackOwwCutoffStep = 0.05;

/// The Sensitivity fine-tune slider (-10 to 10) as -1 to 1, positive
/// meaning more sensitive. It moves the wake words between and past the
/// presets: at the ends, the confidence gates by 0.2, openWakeWord's
/// cutoff by 0.1 and Amazon's threshold by 0.06, the step between its
/// Moderately and Very sensitive. The stop word has a slider of its own,
/// since a stop word that fires too easily cuts answers short.
double wakeTuneFor(num fineTune) => fineTune.clamp(-10, 10) / 10;

EnergyGateConfig energyGateFor(String sensitivity, {required bool enabled}) =>
    EnergyGateConfig(
      enabled: enabled,
      wakeRms: _energyWake[sensitivity] ?? 0.06,
      sleepAfterChunks: 30,
    );

/// The wake words the kiosk listens for, slot 1 first: the active ids
/// that are offered, two at most, or the first offered one with none left.
List<OfferedWakeWord> listenedWakeWords(
  List<String> activeIds,
  List<OfferedWakeWord> offered,
) {
  final byId = {for (final w in offered) w.id: w};
  final picked = <OfferedWakeWord>[for (final id in activeIds) ?byId[id]];
  final unique = <String, OfferedWakeWord>{for (final w in picked) w.id: w};
  final listened = unique.values.take(2).toList();
  if (listened.isEmpty && offered.isNotEmpty) listened.add(offered.first);
  return listened;
}

/// The engine config for the settings: the active wake words (slot 1
/// first), the stop classifier when stop word interruption is on, the gates
/// the sensitivity and the fine-tunes resolve to. Ids the engine does not
/// offer are dropped; with none left, slot 1 falls back to the engine's
/// first.
WakeWordConfig buildWakeConfig({
  required WakeWordEngineType engine,
  required List<String> activeIds,
  required String sensitivity,
  num fineTune = 0,
  num stopFineTune = 0,
  required bool noiseGate,
  required bool stopWord,
  List<ExternalWakeWord> external = const [],
  List<CustomWakeWord> custom = const [],
  String pryonLocale = '',
}) {
  final offered = offeredWakeWords(
    engine,
    external: external,
    custom: custom,
    pryonLocale: pryonLocale,
  );
  final models = listenedWakeWords(activeIds, offered);
  final oww = engine == WakeWordEngineType.openWakeWord;
  final pryon = engine == WakeWordEngineType.pryon;
  final tune = wakeTuneFor(fineTune);
  final stopTune = wakeTuneFor(stopFineTune);
  WakeWordModelRef ref(OfferedWakeWord w, {bool stop = false}) {
    final t = stop ? stopTune : tune;
    final scale = confidenceScaleFor(sensitivity, stop: stop, tune: t);
    final cutoff = oww ? owwCutoffFor(sensitivity, stop: stop, tune: t) : null;
    final boost = !stop && !pryon;
    return WakeWordModelRef(
      id: w.id,
      wakeWord: w.phrase,
      manifestUrl: w.manifestUrl,
      confidenceScale: scale,
      cutoff: cutoff,
      thresholdOffset: pryon
          ? pryonThresholdOffsetFor(sensitivity, stop: stop, tune: t)
          : 0.0,
      playbackConfidenceScale: boost && !oww
          ? scale - playbackConfidenceStep
          : null,
      playbackCutoff: boost && cutoff != null
          ? (cutoff - playbackOwwCutoffStep).clamp(0.1, 0.99).toDouble()
          : null,
    );
  }

  // Amazon's stop word is part of each model: the one of the first wake
  // word's model, so listening needs no other model.
  final pryonStop = pryon && models.isNotEmpty
      ? PryonCatalog.stopWordFor(
          PryonCatalog.byUrl(models.first.manifestUrl)?.model ?? '',
        )
      : null;
  final OfferedWakeWord? stopModel = pryon
      ? pryonStop == null
            ? null
            : OfferedWakeWord(
                pryonStop.id,
                wakeWordPhraseFor(pryonStop.id),
                pryonStop.url,
              )
      : OfferedWakeWord(
          _stopIds[engine]!,
          wakeWordPhraseFor(_stopIds[engine]!),
          bundledModelManifest(engine, _stopIds[engine]!),
        );
  return WakeWordConfig(
    engine: engine,
    models: [for (final w in models) ref(w)],
    stopModel: stopWord && stopModel != null
        ? ref(stopModel, stop: true)
        : null,
    energyGate: energyGateFor(sensitivity, enabled: noiseGate),
  );
}
