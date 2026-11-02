import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/voice/chat_log.dart';
import 'package:kiosk_satellite/managers/voice/wake_catalog.dart';
import 'package:kiosk_satellite/managers/wake_word/engine.dart';

void main() {
  test('every bundled wake word and stop model has its files', () {
    for (final entry in bundledWakeWords.entries) {
      final engine = entry.key;
      for (final id in [
        ...entry.value,
        engine == WakeWordEngineType.vsWakeWord ? 'ok_stop' : 'stop',
      ]) {
        final url = bundledModelManifest(engine, id);
        final path = Uri.parse(url).path.replaceFirst('/', '');
        expect(File(path).existsSync(), isTrue, reason: '$engine $id: $path');
        if (engine == WakeWordEngineType.microWakeWord) {
          expect(
            File(path.replaceAll('.json', '.tflite')).existsSync(),
            isTrue,
          );
        }
        if (engine == WakeWordEngineType.vsWakeWord) {
          // The int8 build only: no fp32 weights ship.
          final onnx = path.replaceAll('.json', '.onnx');
          expect(File(onnx).existsSync(), isFalse, reason: onnx);
          expect(
            File(
              onnx.replaceFirst('vswakeword/', 'vswakeword/int8/'),
            ).existsSync(),
            isTrue,
          );
        }
      }
    }
    for (final shared in ['melspectrogram', 'embedding_model']) {
      expect(
        File('assets/wake_words/openwakeword/$shared.onnx').existsSync(),
        isTrue,
      );
    }
  });

  test('phrases match Voice Satellite, which Home Assistant dedupes on', () {
    expect(wakeWordPhraseFor('ok_nabu'), 'Okay Nabu');
    expect(wakeWordPhraseFor('hey_jarvis'), 'Hey Jarvis');
    expect(wakeWordPhraseFor('okay_computer'), 'Okay Computer');
    expect(wakeWordPhraseFor('ok_nova'), 'Ok Nova');
  });

  test("sensitivity resolves to Voice Satellite's numbers", () {
    expect(confidenceScaleFor('slightly'), 1.10);
    expect(confidenceScaleFor('very'), 0.90);
    expect(confidenceScaleFor('very', stop: true), 0.95);
    expect(owwCutoffFor('moderately'), 0.5);
    expect(owwCutoffFor('slightly'), closeTo(0.6, 1e-9));
    expect(owwCutoffFor('very', stop: true), closeTo(0.6, 1e-9));
    final gate = energyGateFor('very', enabled: true);
    expect(gate.wakeRms, 0.025);
    expect(gate.sleepAfterChunks, 30);
  });

  test('the fine-tune moves the wake words past the presets', () {
    expect(wakeTuneFor(0), 0);
    expect(wakeTuneFor(5), 0.5);
    expect(wakeTuneFor(-20), -1);
    expect(confidenceScaleFor('very', tune: 1), closeTo(0.70, 1e-9));
    expect(confidenceScaleFor('slightly', tune: -1), closeTo(1.30, 1e-9));
    expect(owwCutoffFor('very', tune: 1), closeTo(0.3, 1e-9));
    expect(owwCutoffFor('slightly', tune: -1), closeTo(0.7, 1e-9));
    expect(pryonThresholdOffsetFor('very', tune: 1), closeTo(-0.12, 1e-9));

    WakeWordConfig config(WakeWordEngineType engine, num fineTune) =>
        buildWakeConfig(
          engine: engine,
          activeIds: const [],
          sensitivity: 'very',
          fineTune: fineTune,
          noiseGate: false,
          stopWord: true,
        );
    // Very sensitive plus 3 steps: Hey Luna's 8.0 gate lands at 6.72.
    final vsww = config(WakeWordEngineType.vsWakeWord, 3);
    expect(vsww.models.single.confidenceScale, closeTo(0.84, 1e-9));
    final oww = config(WakeWordEngineType.openWakeWord, -10);
    expect(oww.models.single.cutoff, closeTo(0.5, 1e-9));
    // The stop word keeps the preset.
    expect(vsww.stopModel?.confidenceScale, 0.95);
    expect(oww.stopModel?.cutoff, closeTo(0.6, 1e-9));
    // Its own fine-tune moves only the stop word.
    final stop = buildWakeConfig(
      engine: WakeWordEngineType.openWakeWord,
      activeIds: const [],
      sensitivity: 'very',
      stopFineTune: 5,
      noiseGate: false,
      stopWord: true,
    );
    expect(stop.stopModel?.cutoff, closeTo(0.55, 1e-9));
    expect(stop.models.single.cutoff, closeTo(0.4, 1e-9));
    // 0 leaves the preset alone.
    expect(
      config(WakeWordEngineType.vsWakeWord, 0).models.single.confidenceScale,
      0.90,
    );
  });

  test('the wake words take half a preset less while the kiosk plays', () {
    WakeWordConfig config(WakeWordEngineType engine, {num fineTune = 0}) =>
        buildWakeConfig(
          engine: engine,
          activeIds: const [],
          sensitivity: 'moderately',
          fineTune: fineTune,
          noiseGate: false,
          stopWord: true,
        );
    final vsww = config(WakeWordEngineType.vsWakeWord);
    expect(vsww.models.single.playbackConfidenceScale, closeTo(0.95, 1e-9));
    expect(vsww.models.single.playbackCutoff, isNull);
    final mww = config(WakeWordEngineType.microWakeWord);
    expect(mww.models.single.playbackConfidenceScale, closeTo(0.95, 1e-9));
    final oww = config(WakeWordEngineType.openWakeWord);
    expect(oww.models.single.playbackCutoff, closeTo(0.45, 1e-9));
    expect(oww.models.single.playbackConfidenceScale, isNull);
    // On top of the fine-tune, not instead of it.
    expect(
      config(
        WakeWordEngineType.vsWakeWord,
        fineTune: 5,
      ).models.single.playbackConfidenceScale,
      closeTo(0.85, 1e-9),
    );
    // The stop word keeps its thresholds.
    for (final c in [vsww, mww, oww]) {
      expect(c.stopModel?.playbackConfidenceScale, isNull);
      expect(c.stopModel?.playbackCutoff, isNull);
    }
  });

  test('the config keeps two known wake words, slot 1 first', () {
    final config = buildWakeConfig(
      engine: WakeWordEngineType.openWakeWord,
      activeIds: ['hey_jarvis', 'nope', 'ok_nabu', 'alexa'],
      sensitivity: 'slightly',
      noiseGate: true,
      stopWord: true,
    );
    expect([for (final m in config.models) m.id], ['hey_jarvis', 'ok_nabu']);
    expect(config.models.first.wakeWord, 'Hey Jarvis');
    expect(config.models.first.cutoff, closeTo(0.6, 1e-9));
    expect(config.stopModel?.id, 'stop');
    expect(config.stopModel?.cutoff, closeTo(0.7, 1e-9));
    expect(config.energyGate.enabled, isTrue);
  });

  test('an unknown set falls back to the engine first wake word', () {
    final config = buildWakeConfig(
      engine: WakeWordEngineType.vsWakeWord,
      activeIds: const ['okay_computer'],
      sensitivity: 'moderately',
      noiseGate: false,
      stopWord: false,
    );
    expect(config.models.single.id, 'ok_nabu');
    expect(config.stopModel, isNull);
    expect(config.models.single.cutoff, isNull);
  });

  test('a wake word that went away leaves the ones still offered', () {
    // What the kiosk reports to Home Assistant's selects after an engine
    // switch or a deleted model: the rest move up, a lone one takes slot 1.
    final offered = offeredWakeWords(WakeWordEngineType.microWakeWord);
    List<String> listened(List<String> active) => [
      for (final w in listenedWakeWords(active, offered)) w.id,
    ];
    expect(listened(['gone', 'hey_jarvis']), ['hey_jarvis']);
    expect(listened(['alexa', 'gone']), ['alexa']);
    expect(listened(['gone']), ['ok_nabu']);
    expect(listened([]), ['ok_nabu']);
    expect(listenedWakeWords(['alexa'], const []), isEmpty);
  });

  test("Home Assistant's custom microWakeWord models join the offer", () {
    final external = [
      ExternalWakeWord.fromMap({
        'id': 'hey_kitchen',
        'wakeWord': 'Hey Kitchen',
        'url': 'http://ha/api/esphome/wake_words/hey_kitchen.json',
        'modelType': 'micro',
      })!,
    ];
    final mww = offeredWakeWords(
      WakeWordEngineType.microWakeWord,
      external: external,
    );
    expect(mww.last.id, 'hey_kitchen');
    expect(mww.last.manifestUrl, startsWith('http://ha/'));
    final vww = offeredWakeWords(
      WakeWordEngineType.vsWakeWord,
      external: external,
    );
    expect(vww.any((w) => w.id == 'hey_kitchen'), isFalse);
  });

  test('tool names and results read like Voice Satellite', () {
    expect(humanizeToolName('HassTurnOn'), 'Turn on');
    expect(
      humanizeToolName(
        'voice-satellite-card-weather-forecast__get_weather_forecast',
      ),
      'Get weather forecast',
    );
    expect(humanizeToolName('search_images'), 'Search images');
    final digest = digestLatestTurn([
      {'role': 'user', 'content': 'old'},
      {'role': 'assistant', 'content': 'old answer'},
      {'role': 'user', 'content': 'weather'},
      {
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          {'id': 't1', 'tool_name': 'weather__get_weather_forecast'},
        ],
      },
      {
        'role': 'tool_result',
        'tool_call_id': 't1',
        'tool_name': 'weather__get_weather_forecast',
        'tool_result': {'forecast': [], 'current_temperature': 72},
      },
      {'role': 'assistant', 'content': 'Sunny.'},
    ]);
    expect(digest.tools, ['Get weather forecast']);
    expect(digest.results.single.kind, 'weather');
    expect(digest.answer, 'Sunny.');
    expect(stripSentimentTags('[happy] Sure thing!'), 'Sure thing!');
  });

  test('sentiment tags in angle brackets go, other text stays', () {
    expect(
      stripSentimentTags("Morning! <chuckle> You're up early."),
      "Morning! You're up early.",
    );
    expect(
      stripSentimentTags('Hmm <short pause> okay <sigh> fine.'),
      'Hmm okay fine.',
    );
    expect(
      stripSentimentTags('Yes, 3 < 5 and 7 > 2.'),
      'Yes, 3 < 5 and 7 > 2.',
    );
    expect(stripSentimentTags('Use <Enter> to go.'), 'Use <Enter> to go.');
    // A tag cut off mid stream goes only while the answer streams.
    expect(stripSentimentTags('Morning! <chuck', streaming: true), 'Morning!');
    expect(stripSentimentTags('Sure [hap', streaming: true), 'Sure');
    expect(stripSentimentTags('Morning! <chuck'), 'Morning! <chuck');
  });

  test('common HTML tags stay', () {
    expect(
      stripSentimentTags('It is <b>72°</b> <sigh> and <i>sunny</i>.'),
      'It is <b>72°</b> and <i>sunny</i>.',
    );
    expect(
      stripSentimentTags('<p>Line one<br>Line two</p> <laugh>'),
      '<p>Line one<br>Line two</p>',
    );
    expect(stripSentimentTags('<a little pause> <s>'), '<a little pause> <s>');
    // Starts like an HTML name but is not one.
    expect(stripSentimentTags('<sigh> <bold> Okay.'), 'Okay.');
  });

  group('custom models on the kiosk', () {
    const onnx = CustomWakeWord(
      engine: WakeWordEngineType.openWakeWord,
      id: 'hey_computer',
      phrase: 'Hey Computer',
      url: 'file:///models/openwakeword/hey_computer.onnx',
    );

    test('are offered with their own engine only', () {
      final oww = offeredWakeWords(
        WakeWordEngineType.openWakeWord,
        custom: const [onnx],
      );
      expect(oww.last.id, 'hey_computer');
      expect(oww.last.manifestUrl, onnx.url);
      expect(
        offeredWakeWords(
          WakeWordEngineType.vsWakeWord,
          custom: const [onnx],
        ).map((w) => w.id),
        isNot(contains('hey_computer')),
      );
    });

    test('replace a bundled model of the same id', () {
      const mine = CustomWakeWord(
        engine: WakeWordEngineType.microWakeWord,
        id: 'hey_luna',
        phrase: 'Hey Luna',
        url: 'file:///models/microwakeword/hey_luna.json',
      );
      final offered = offeredWakeWords(
        WakeWordEngineType.microWakeWord,
        custom: const [mine],
      );
      expect(
        offered.where((w) => w.id == 'hey_luna').single.manifestUrl,
        mine.url,
      );
    });

    test('never share a name, Home Assistant tells them apart by it', () {
      const again = CustomWakeWord(
        engine: WakeWordEngineType.vsWakeWord,
        id: 'luna_v2',
        phrase: 'Hey Luna',
        url: 'file:///models/vswakeword/luna_v2.json',
      );
      const third = CustomWakeWord(
        engine: WakeWordEngineType.vsWakeWord,
        id: 'hey_luna_',
        phrase: 'Hey Luna',
        url: 'file:///models/vswakeword/hey_luna_.json',
      );
      final names = offeredWakeWords(
        WakeWordEngineType.vsWakeWord,
        custom: const [again, third],
      ).map((w) => w.phrase).toList();
      expect(names.toSet().length, names.length);
      expect(names, containsAll(['Hey Luna', 'Luna V2', 'Hey Luna 2']));
    });
  });
}
