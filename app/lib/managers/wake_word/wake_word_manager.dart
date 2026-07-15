import 'dart:async';
import 'dart:convert';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'engine.dart';
import 'mww/mww_probe.dart';
import 'vsww/benchmark.dart';
import 'vsww/model_store.dart';
import 'vsww/vsww_engine.dart';

/// Native wake-word detection and the mic-ownership handoff with the
/// Voice Satellite card (docs/js-api.md, "Wake-word handoff protocol").
///
/// Configuration is inherited from Voice Satellite: the card pushes the
/// engine + model list via `setWakeWordConfig` (JS API); nothing is chosen
/// locally except the master enable switch. The app answers with
/// `available` so the card can fall back to browser detection when the
/// configured engine has no native runner here.
///
/// State:
///   enabled   — the `wake_word.enabled` local master switch
///   config    — pushed by the VS card; null until the page configures us
///   active    — page-controlled via setWakeWordActive(); suspended (false)
///               while the VS card owns the mic for STT
///   listening — mic actually open and inference running
///
/// Ordering contract: on detection the engine is stopped *before*
/// WakeWordDetected is published, so the page may open getUserMedia the
/// moment its event listener fires.
class WakeWordManager extends Manager {
  WakeWordManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'wake_word';

  // vsWakeWord runs natively (ONNX). microWakeWord/openWakeWord fall through
  // to unavailable (VS keeps browser detection) until ported.
  late final WakeWordEngine _engine = VswwEngine(log);

  WakeWordConfig? _config;
  bool _active = true;
  Timer? _resumeTimer;

  /// The page handed the mic back (it muted the satellite, or switched to an
  /// engine we cannot run). Distinct from `active:false`, which keeps the mic
  /// open for an instant resume: released means *stop capturing entirely*.
  /// Cleared when the page pushes config again.
  bool _released = false;

  bool get enabled => _settings.get(defs.wakeWordEnabled);

  /// Actively detecting. The engine can be running (mic open, models loaded)
  /// while detection is paused for the duration of a voice turn.
  bool get listening => _engine.running && _active;

  /// The wake-word config inherited from Voice Satellite (null until the VS
  /// card pushes it via setWakeWordConfig).
  WakeWordConfig? get config => _config;

  /// Whether this app will natively handle wake-word detection for the
  /// pushed config: the user enabled wake word detection in *our* settings
  /// AND we have a native runner for that engine.
  ///
  /// This is the honest answer Voice Satellite gates its handoff on — if it
  /// is false, VS transparently keeps doing detection in the browser. It must
  /// therefore include [enabled]: handing off to a disabled engine would mean
  /// nobody is listening.
  bool get available =>
      enabled &&
      !_released &&
      _config != null &&
      _engine.supportedEngines.contains(_config!.engine);

  /// Whether we are natively running the card's stop-word classifier. False
  /// unless the card actually pushed a stop model and the engine loaded it, so
  /// the card knows to keep its own browser stop classifier instead.
  bool get stopWordAvailable => available && _engine.supportsStopWord;

  @override
  Future<void> init() async {
    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.wakeWordEnabled.key) _sync();
    });

    commands
      ..register(Command(
        name: 'setWakeWordConfig',
        description:
            'Inherit wake-word config from Voice Satellite: engine '
            '(microWakeWord | openWakeWord | vsWakeWord) and models with '
            'manifest URLs on the HA instance',
        params: const {
          'engine': 'microWakeWord | openWakeWord | vsWakeWord',
          'models': '[{id, wakeWord, manifestUrl}]',
        },
        handler: (p) async {
          final config = WakeWordConfig.fromJson(p);
          if (config == null) {
            return const CommandResult.fail('invalid wake word config');
          }
          // A genuinely new config (different wake word, stop word toggled on)
          // has to reach the engine, and it only reads the config at start.
          // Re-pushing the same config on every page load must NOT restart it,
          // though: that would re-download every model on each navigation.
          final changed = _config != config || _released;
          _released = false; // a fresh push takes the mic back
          _config = config;
          if (changed && _engine.running) {
            log.info(name, 'config changed; restarting engine');
            await _engine.stop();
          }
          log.info(
              name,
              'configured by page: ${config.engine.name} '
              '[${config.models.map((m) => m.id).join(', ')}]'
              '${config.stopModel == null ? '' : ' + stop:${config.stopModel!.id}'}'
              '${available ? '' : ' (no native runner — reporting unavailable)'}');
          await _sync();
          // A page that has just (re)configured us owns no interruptible state
          // yet, so it cannot want the stop word armed. Without this, a reload
          // would inherit the previous page's arming: it never disarms on the
          // way out, and an unchanged config does not restart the engine.
          await _engine.setStopWordActive(false);
          return CommandResult.ok({
            'available': available,
            'stopWordAvailable': stopWordAvailable,
          });
        },
      ))
      ..register(Command(
        name: 'releaseWakeWord',
        description:
            'Stop detection and release the microphone entirely. Unlike '
            'setWakeWordActive(false), which keeps the mic open for an instant '
            'resume between turns, this closes it: for when the satellite is '
            'muted or the page switched to an engine we do not run. Push '
            'setWakeWordConfig again to take it back.',
        handler: (_) async {
          if (_released) return const CommandResult.ok();
          _released = true;
          _resumeTimer?.cancel();
          _active = true; // a later re-push starts listening, not suspended
          await _engine.stop();
          log.info(name, 'released by page (mic closed)');
          bus.publish(WakeWordStateChanged(active: _active, listening: listening));
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'setStopWordActive',
        description:
            'Arm (active=true) or disarm the native stop-word classifier. '
            'Pages arm it for the duration of an interruptible state (TTS '
            'playback, media, a ringing timer) and disarm it when that ends.',
        params: const {'active': 'true to arm, false to disarm'},
        handler: (p) async {
          if (!stopWordAvailable) {
            return const CommandResult.fail('no native stop word');
          }
          await _engine.setStopWordActive(p['active'] == true);
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'setWakeWordActive',
        description:
            'Resume (active=true) or suspend native wake-word listening. '
            'Pages must resume after their voice session returns to idle.',
        params: const {'active': 'true to resume, false to suspend'},
        handler: (p) async {
          setActive(p['active'] == true);
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'getWakeWordState',
        description: 'Current wake-word engine state',
        handler: (_) async => CommandResult.ok({
          'available': available,
          'stopWordAvailable': stopWordAvailable,
          'enabled': enabled,
          'active': _active,
          'listening': listening,
          'engine': _config?.engine.name,
          'models': [
            for (final m in _config?.models ?? const <WakeWordModelRef>[])
              m.toJson(),
          ],
        }),
      ))
      ..register(Command(
        name: 'startAudioStream',
        description:
            'Stream captured mic audio to the page (PCM16 16 kHz mono, '
            'base64, via kiosksatellite:audio events), starting with a short '
            'pre-roll. The card uses this instead of getUserMedia during a '
            'voice turn, so wake -> STT is instant and no speech is clipped.',
        handler: (_) async {
          if (!_engine.running) {
            return const CommandResult.fail('engine not running');
          }
          await _engine.startAudioStream((pcm, preRoll) {
            bus.publish(AudioChunk(
              base64: base64Encode(pcm),
              sampleRate: 16000,
              preRoll: preRoll,
            ));
          });
          return const CommandResult.ok({'sampleRate': 16000});
        },
      ))
      ..register(Command(
        name: 'stopAudioStream',
        description: 'Stop streaming mic audio to the page',
        handler: (_) async {
          await _engine.stopAudioStream();
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'benchmarkVsww',
        description:
            'Benchmark vsWakeWord ONNX inference across CPU/XNNPACK/NNAPI '
            'execution providers (ms per inference vs the 80 ms budget)',
        params: const {
          'manifestUrl': 'model manifest URL (defaults to first configured)',
          'iters': 'timed iterations (default 60)',
        },
        handler: (p) async {
          final url = (p['manifestUrl'] as String?) ??
              _config?.models.firstOrNull?.manifestUrl;
          if (url == null || url.isEmpty) {
            return const CommandResult.fail(
                'no manifestUrl and no configured model');
          }
          // Stop live capture so it doesn't compete for CPU during timing.
          final wasActive = _active;
          await _engine.stop();
          try {
            final model = await VswwModelStore().fetch(url);
            final result = await VswwBenchmark(log)
                .run(model, iters: (p['iters'] as num?)?.toInt() ?? 60);
            return CommandResult.ok(result);
          } catch (e) {
            return CommandResult.fail('$e');
          } finally {
            _active = wasActive;
            await _sync(); // resume listening if it was on
          }
        },
      ))
      ..register(Command(
        name: 'probeMww',
        description:
            'Can this device run a microWakeWord .tflite model? Reports its '
            'tensors and times one invoke. Groundwork for native mww.',
        params: const {'url': 'absolute .tflite URL'},
        handler: (p) async {
          final url = p['url'] as String?;
          if (url == null || url.isEmpty) {
            return const CommandResult.fail('url required');
          }
          final res = await probeMww(url);
          log.info(name, 'mww probe: $res');
          return CommandResult.ok(res);
        },
      ))
      ..register(Command(
        name: 'simulateWakeWord',
        description:
            'Fire a wake-word detection without the engine — for testing the '
            'Voice Satellite handoff end-to-end',
        handler: (_) async {
          final model = _config?.models.firstOrNull ??
              const WakeWordModelRef(
                  id: 'test', wakeWord: 'Test', manifestUrl: '');
          await _onDetection(model);
          return const CommandResult.ok();
        },
      ));

    await _sync();
  }

  /// Page-driven resume/suspend (setWakeWordActive).
  void setActive(bool active) {
    _active = active;
    log.info(name, active ? 'resumed by page' : 'suspended by page');
    if (active) _resumeTimer?.cancel();
    _sync();
  }

  /// Bring the engine up (or down) with the config, then pause/resume
  /// *detection* to match [_active].
  ///
  /// The engine stays running — mic open, models loaded — for the whole time
  /// wake word detection is enabled. Suspending during a voice turn only
  /// pauses detection: tearing the engine down per wake would re-download and
  /// recompile every model, and would drop the mic the page is streaming from.
  Future<void> _sync() async {
    final shouldRun = enabled && available;
    if (shouldRun && !_engine.running) {
      await _engine.start(
        config: _config!,
        onDetection: _onDetection,
        onStopDetection: _onStopDetection,
      );
      log.info(
          name,
          'listening (${_config!.engine.name})'
          '${_engine.supportsStopWord ? ' + stop word' : ''}');
    } else if (!shouldRun && _engine.running) {
      await _engine.stop();
      log.info(name, 'stopped');
    }
    if (_engine.running) {
      if (_active) {
        await _engine.resumeDetection();
      } else {
        await _engine.pauseDetection();
      }
    }
    bus.publish(WakeWordStateChanged(active: _active, listening: listening));
  }

  /// The stop word fired. Unlike a wake word this starts no turn and touches
  /// no engine state: the page owns what "stop" means (cancel TTS, pause media,
  /// silence a timer), and it disarms us as part of tearing that down.
  Future<void> _onStopDetection() async {
    log.info(name, 'stop word detected');
    bus.publish(const StopWordDetected());
  }

  Future<void> _onDetection(WakeWordModelRef model) async {
    // The engine has already paused detection and kept the mic — it is the
    // audio source for the turn the page is about to run.
    _active = false;
    log.info(name, 'detected "${model.id}"');
    bus.publish(WakeWordDetected(model: model.id, phrase: model.wakeWord));

    // Self-heal: if the page never resumes us (crash, navigation), re-arm.
    _resumeTimer?.cancel();
    final timeout =
        _settings.get(defs.wakeWordResumeTimeoutSeconds).toInt();
    if (timeout > 0) {
      _resumeTimer = Timer(Duration(seconds: timeout), () {
        if (!_active) {
          log.warn(name, 'page never resumed listening; self-healing');
          setActive(true);
        }
      });
    }
  }

  @override
  Future<void> dispose() async {
    _resumeTimer?.cancel();
    await _engine.stop();
  }
}
