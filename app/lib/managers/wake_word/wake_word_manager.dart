import 'dart:async';
import 'dart:convert';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../../core/permissions.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'engine.dart';
import 'model_cache.dart';
import 'mww/mww_engine.dart';
import 'mww/mww_probe.dart';
import 'oww/oww_engine.dart';
import 'oww/oww_probe.dart';
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

  // One engine per runner, created lazily and kept: switching wake word
  // engines should not re-download models the other one already has.
  final Map<WakeWordEngineType, WakeWordEngine> _engines = {};

  WakeWordEngine? _engineFor(WakeWordEngineType type) => switch (type) {
        WakeWordEngineType.vsWakeWord =>
          _engines.putIfAbsent(type, () => VswwEngine(log)),
        WakeWordEngineType.microWakeWord =>
          _engines.putIfAbsent(type, () => MwwEngine(log)),
        WakeWordEngineType.openWakeWord =>
          _engines.putIfAbsent(type, () => OwwEngine(log)),
      };

  /// The engine for the pushed config, or a do-nothing stand-in when there is
  /// no config or no native runner for it. Never the *running* engine: see
  /// [_active] handling in [_sync], which stops the outgoing one on a switch.
  WakeWordEngine get _engine {
    final config = _config;
    if (config == null) return _noEngine;
    return _engineFor(config.engine) ?? _noEngine;
  }

  final WakeWordEngine _noEngine = StubWakeWordEngine();

  WakeWordConfig? _config;
  bool _active = true;
  Timer? _resumeTimer;

  /// The page handed the mic back (it muted the satellite, or switched to an
  /// engine we cannot run). Distinct from `active:false`, which keeps the mic
  /// open for an instant resume: released means *stop capturing entirely*.
  /// Cleared when the page pushes config again.
  bool _released = false;

  /// Why the page released us, in the card's words: 'muted', 'browser', or
  /// null from a card too old to say. Both are a closed mic to us and nothing
  /// else, so without being told we can only report the mechanism and not the
  /// cause — which is how muting the satellite came to display as "no native
  /// runner for openWakeWord".
  String? _releaseReason;

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
      !_failed &&
      _config != null &&
      _engine.supportedEngines.contains(_config!.engine);

  /// The engine was asked to run this config and could not.
  ///
  /// Having a native runner for an engine is not the same as that runner
  /// working here and now: the models may fail to download, or the microphone
  /// may refuse to open (permission revoked, another app holding it). Both end
  /// with us loaded, willing, and deaf.
  ///
  /// This must feed [available], because Voice Satellite reads that as "I have
  /// this covered" and *stops its own detection* on the strength of it. Saying
  /// yes while nothing is listening is the worst answer available: the card
  /// would keep browser detection running if we simply admitted we cannot.
  ///
  /// Cleared whenever the card pushes config again, so a reload retries.
  bool _failed = false;

  /// Why, when we know. Drives what the UIs offer to do about it.
  EngineFailure? _failure;

  /// Whether offering a retry would mean anything.
  ///
  /// Not while the card has released us: retrying re-runs the sync, which will
  /// not start anything the card has taken back, so the button would do
  /// nothing. Unmuting is what fixes a mute, and that comes from the card.
  bool get canRetry => _failed && !_released;

  /// What went wrong, or null when nothing has — or when it no longer matters
  /// because the card has since taken the microphone back.
  EngineFailure? get failure => canRetry ? _failure : null;

  /// The microphone is refused and Android will not ask again, so the only way
  /// back is the OS settings screen. Both UIs offer that when this is true.
  bool get needsAppSettings => failure == EngineFailure.micBlocked;

  void _onEngineFailure(EngineFailure kind, String detail) {
    _failed = true;
    _failure = kind;
    _runningEngine = null;
    log.error(
        name,
        'engine unavailable ($detail); Voice Satellite keeps browser detection');
    // Tell the page and the settings UIs, both of which may be showing
    // "Listening natively" over a microphone that no longer exists.
    bus.publish(WakeWordStateChanged(active: _active, listening: listening));
  }

  /// Try again after a failure: re-ask for the microphone, re-fetch the models.
  ///
  /// The card only pushes config on page load, so without this a stray "Don't
  /// allow" leaves the device deaf until something reloads it — and the person
  /// who tapped it has no idea that is the fix.
  Future<bool> retry() async {
    _failed = false;
    _failure = null;
    await _sync();
    return available;
  }

  /// Engines that were started and must be stopped when the config moves to a
  /// different runner. Without this, switching engines would leave the old one
  /// holding the mic.
  WakeWordEngine? _runningEngine;

  /// Whether we are natively running the card's stop-word classifier. False
  /// unless the card actually pushed a stop model and the engine loaded it, so
  /// the card knows to keep its own browser stop classifier instead.
  bool get stopWordAvailable => available && _engine.supportsStopWord;

  /// How the wake-word state should read to a person, as a code plus the
  /// sentence to show. Derived here rather than in either UI: the on-device
  /// settings screen and the remote web admin must say the same thing about the
  /// same device, and they cannot if each decides for itself what "available
  /// but not listening" means.
  /// Deliberately walks the same clauses as [available], in the same order, so
  /// each way of being unavailable gets its own answer. There is no catch-all
  /// here on purpose: "No native runner" used to be one, and it told anyone who
  /// muted the satellite that their engine was unsupported.
  ({String code, String label}) get status {
    if (!enabled) {
      return (
        code: 'disabled',
        label: 'Wake word detection is off. Turn it on to inherit models from '
            'Voice Satellite.',
      );
    }
    final config = _config;
    if (config == null) {
      return (
        code: 'waiting',
        label: 'Waiting for Voice Satellite. The engine and wake words are '
            'configured by the card once this device opens its dashboard.',
      );
    }
    if (_released) {
      // Why the card took the mic back is the card's to know: mute and "the
      // browser is taking detection back" are the same event to us.
      return switch (_releaseReason) {
        'muted' => (
            code: 'muted',
            label: 'Muted in Voice Satellite. The microphone is closed until '
                'the satellite is unmuted.',
          ),
        'browser' => (
            code: 'browser',
            label: 'Voice Satellite is running detection in the browser for '
                'this engine.',
          ),
        _ => (
            code: 'released',
            label: 'Voice Satellite released the microphone.',
          ),
      };
    }
    if (_failed) {
      return switch (_failure) {
        EngineFailure.micBlocked => (
            code: 'micBlocked',
            label: 'Microphone blocked. Android will not ask again — allow it '
                'in the app settings, then retry.',
          ),
        EngineFailure.micDeclined => (
            code: 'micDeclined',
            label: 'Microphone declined. Wake word detection needs it; retry '
                'to be asked again.',
          ),
        EngineFailure.micLost => (
            code: 'micLost',
            label: 'The microphone stopped working. Retry, or reload the page.',
          ),
        EngineFailure.modelsUnavailable => (
            code: 'modelsUnavailable',
            label: 'Could not download the models from Home Assistant. Retry '
                'once it is reachable.',
          ),
        null => (
            code: 'failed',
            label: 'The wake-word engine could not start. Retry, or reload '
                'the page.',
          ),
      };
    }
    if (!_engine.supportedEngines.contains(config.engine)) {
      return (
        code: 'unavailable',
        label: 'No native runner for ${config.engine.label} — Voice Satellite '
            'keeps browser detection.',
      );
    }
    return listening
        ? (code: 'listening', label: 'Listening natively')
        : (code: 'suspended', label: 'Ready (suspended during a voice session)');
  }

  /// The whole wake-word state as data: what `getWakeWordState` answers, what
  /// the settings screen draws, and what the web admin draws. One shape, so the
  /// two UIs cannot disagree.
  Map<String, Object?> describeState() => {
        'available': available,
        'stopWordAvailable': stopWordAvailable,
        'enabled': enabled,
        'active': _active,
        'listening': listening,
        'engine': _config?.engine.name,
        // The label Voice Satellite uses ("microWakeWord"), not the enum name.
        'engineLabel': _config?.engine.label,
        'status': status.code,
        'statusLabel': status.label,
        // Both UIs offer a way out; they must not each decide when to.
        'canRetry': canRetry,
        'released': _released,
        'releaseReason': _releaseReason,
        'needsAppSettings': needsAppSettings,
        'stopWord': _config?.stopModel?.wakeWord,
        'models': [
          for (final m in _config?.models ?? const <WakeWordModelRef>[])
            m.toJson(),
        ],
      };

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
          // A push after a failure must retry, even when the config is
          // identical: whatever broke (mic permission, a model 404) may well be
          // fixed by now, and this is the only retry there is.
          final changed = _config != config || _released || _failed;
          _released = false; // a fresh push takes the mic back
          _releaseReason = null;
          _failed = false; // and re-earns the right to claim availability
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
        params: const {
          'reason': "optional: 'muted' | 'browser' — shown to the user",
        },
        handler: (p) async {
          if (_released) return const CommandResult.ok();
          _released = true;
          _releaseReason = p['reason'] as String?;
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
        handler: (_) async => CommandResult.ok(describeState()),
      ))
      ..register(Command(
        name: 'retryWakeWord',
        description: 'Try to start the wake-word engine again after a failure: '
            're-asks for the microphone and re-fetches the models. The card '
            'only pushes config on page load, so this is the way back without '
            'a reload.',
        handler: (_) async {
          final ok = await retry();
          return CommandResult.ok({
            'available': ok,
            ...describeState(),
          });
        },
      ))
      ..register(Command(
        name: 'openAppSettings',
        description: 'Open this app in the OS settings. The only way back from '
            'a microphone the user blocked, since Android stops asking.',
        handler: (_) async {
          final opened = await openOsAppSettings();
          return opened
              ? const CommandResult.ok()
              : const CommandResult.fail('could not open the OS settings');
        },
      ))
      ..register(Command(
        name: 'clearWakeWordModels',
        description: 'Delete cached wake-word models and re-download them. '
            'Use after re-publishing a model on Home Assistant: the cache is '
            'keyed by URL, so new bytes at the same URL are otherwise never '
            'picked up.',
        handler: (_) async {
          final held = await WakeModelCache.size();
          final running = _engine.running;
          // Stop first: the engine holds the loaded copies, and on some
          // platforms the open files too.
          if (running) await _engine.stop();
          final removed = await WakeModelCache.clear();
          log.info(name,
              'cleared $removed cached model file(s) (${(held / 1024).round()} KB)');
          // Coming back up re-fetches from Home Assistant.
          await _sync();
          return CommandResult.ok({
            'removed': removed,
            'bytesFreed': held,
            'restarted': running && _engine.running,
          });
        },
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
        name: 'probeOww',
        description:
            'Can this device run the openWakeWord chain (mel + embedding + '
            'classifier) in real time on the CPU? Times each stage against the '
            '80ms per-chunk budget. Groundwork for native oww.',
        params: const {
          'base': 'models base URL, e.g. <ha>/voice_satellite/models/openwakeword',
          'wakeWord': 'classifier name, e.g. alexa',
        },
        handler: (p) async {
          final base = p['base'] as String?;
          final wakeWord = p['wakeWord'] as String? ?? 'alexa';
          if (base == null || base.isEmpty) {
            return const CommandResult.fail('base required');
          }
          final res = await probeOww(base, wakeWord);
          log.info(name, 'oww probe: $res');
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
    // A config that switched runners (vsWakeWord -> microWakeWord) leaves the
    // previous engine running and holding the mic. Stop it before starting the
    // new one, or two engines fight over the microphone.
    final desired = shouldRun ? _engine : null;
    final previous = _runningEngine;
    if (previous != null && !identical(previous, desired) && previous.running) {
      log.info(name, 'engine changed; stopping the previous runner');
      await previous.stop();
      _runningEngine = null;
    }
    if (shouldRun && !_engine.running) {
      await _engine.start(
        config: _config!,
        onDetection: _onDetection,
        onStopDetection: _onStopDetection,
        onFailure: _onEngineFailure,
      );
      // start() gives up rather than throwing when every model fails to
      // download, so ask the engine instead of assuming it worked: claiming to
      // listen while nothing is running is how a satellite goes quietly deaf.
      if (_engine.running) {
        log.info(
            name,
            'listening (${_config!.engine.name})'
            '${_engine.supportsStopWord ? ' + stop word' : ''}');
        _runningEngine = _engine;
      } else if (!_failed) {
        // The engine reports its own failures (a refused mic, models that would
        // not download) through onFailure, which has already run and said
        // something specific. This is the backstop for a runner that declined
        // to start without explaining itself: report unavailable regardless, so
        // the card keeps doing this rather than trust something that never came
        // up.
        _failed = true;
        log.error(
            name,
            'engine failed to start (${_config!.engine.name}); '
            'reporting unavailable so Voice Satellite keeps browser detection');
      }
    } else if (!shouldRun && _engine.running) {
      await _engine.stop();
      _runningEngine = null;
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
