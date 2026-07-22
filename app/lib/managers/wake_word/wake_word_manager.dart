import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../../core/permissions.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'background_listening.dart';
import 'engine.dart';
import 'model_cache.dart';
import 'system_permissions.dart';
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

  /// Per-inference telemetry for the wake-word tester. Broadcast: the tester
  /// dialog subscribes while it is open. Off (no engine overhead) otherwise.
  final _telemetry = StreamController<Map<String, Object?>>.broadcast();
  int _testers = 0;

  /// Live per-inference scores from the running engine, while a tester holds
  /// [startTest] open.
  Stream<Map<String, Object?>> get telemetry => _telemetry.stream;

  /// Begin streaming telemetry from whichever engine is running. Reference
  /// counted so overlapping testers (device + remote) share one feed.
  void startTest() {
    _testers++;
    if (_testers == 1) _applyTelemetry();
  }

  void stopTest() {
    if (_testers == 0) return;
    _testers--;
    if (_testers == 0) _applyTelemetry();
  }

  /// Point the active engine's telemetry at our stream (or unhook it).
  /// Re-run whenever the running engine changes, so requesting a test
  /// before the engine is up — or across an engine switch — still lands on
  /// the one actually inferring.
  void _applyTelemetry() {
    final want = _testers > 0;
    _engine.onTelemetry = want
        ? ((m) {
            if (!_telemetry.isClosed) _telemetry.add(m);
          })
        : null;
    _engine.setTelemetry(want);
  }

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

  /// Whether the foreground service is up, so we only cross the platform
  /// channel when the answer actually changes — and never at all where the
  /// setting is off, which is every kiosk that stays in front.
  bool _serviceRunning = false;

  /// Run the keep-alive service exactly while there is something to keep alive.
  ///
  /// Without it Android freezes the whole process the moment another app covers
  /// us: mic, WebView, Voice Satellite's websocket and our own Dart, together.
  /// See [BackgroundListening].
  Future<void> _syncBackgroundService() async {
    final want = _settings.get(defs.wakeWordBackground) && _engine.running;
    if (want == _serviceRunning) return;
    try {
      if (want) {
        await BackgroundListening.start();
      } else {
        await BackgroundListening.stop();
      }
      _serviceRunning = want;
      log.info(
          name, want ? 'background listening on' : 'background listening off');
    } catch (e) {
      // A platform with no such service (tests, desktop). Nothing to keep
      // alive, so nothing is broken by not keeping it alive.
      log.warn(name, 'background service unavailable: $e');
      _serviceRunning = false;
    }
  }

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
            label: 'Microphone blocked. Android will not ask again, so allow it '
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
        label: 'No native runner for ${config.engine.label}. Voice Satellite '
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
      if (e.key == defs.wakeWordEnabled.key ||
          e.key == defs.wakeWordBackground.key) {
        _sync();
      } else if (e.key == defs.audioMicDevice.key) {
        // The engine reads its capture device when the mic opens, so a new
        // selection needs a stop/start. AudioRoutingManager has already
        // updated the selector by the time this listener runs (it inits,
        // and so subscribes, before this manager).
        _restartForMicChange();
      }
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
              '${available ? '' : ' (no native runner, reporting unavailable)'}');
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
          'reason': "optional: 'muted' | 'browser', shown to the user",
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
        name: 'bringToFront',
        description: 'Bring the app to the foreground, for a server-initiated '
            'interaction (announcement, ask_question, start_conversation) that '
            'arrives while the app is behind another one. No-op when already in '
            'front; false when it cannot come forward (no "Display over other '
            'apps" grant). The app must be running to receive the trigger at '
            'all, which is what keeping the wake word alive in the background '
            'ensures.',
        handler: (_) async {
          // Already in front: do nothing and report success. Relaunching a
          // foreground Activity recreates the WebView and reloads the page —
          // dropping the card session in the middle of the very interaction
          // this was meant to reveal. Only come forward when actually behind
          // something (same guard as the native wake path).
          if (WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed) {
            return const CommandResult.ok(true);
          }
          return CommandResult.ok(await BackgroundListening.bringToFront());
        },
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
        name: 'getSystemPermissions',
        description: 'OS grants native wake-word detection needs, and whether '
            'this device holds them. Read-only: they can only be given on the '
            'device itself. `required` is false when wake word detection is '
            'off, where the browser asks for the microphone on its own and '
            'none of this applies.',
        handler: (_) async {
          final perms = await SystemPermissions.read();
          return CommandResult.ok({
            'required': enabled,
            'background': _settings.get(defs.wakeWordBackground),
            ...perms.toJson(),
          });
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
          _pageAudioActive = true;
          await _openPageAudioStream();
          return const CommandResult.ok({'sampleRate': 16000});
        },
      ))
      ..register(Command(
        name: 'stopAudioStream',
        description: 'Stop streaming mic audio to the page',
        handler: (_) async {
          _pageAudioActive = false;
          await _engine.stopAudioStream();
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'startWakeWordTest',
        description:
            'Start streaming per-inference wake-word telemetry (score, '
            'threshold, rms, latency, near-miss) for the wake word tester',
        handler: (_) async {
          startTest();
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'stopWakeWordTest',
        description: 'Stop wake-word telemetry streaming',
        handler: (_) async {
          stopTest();
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
            'Fire a wake-word detection without the engine, for testing the '
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
  /// Whether the page asked for the mic audio stream and has not released
  /// it. Owned here (not by the engine) so a restart can restore the stream:
  /// the delivery callback is this manager's, the page only consumes events.
  bool _pageAudioActive = false;

  /// Feed the page: every chunk (pre-roll first) as a kiosksatellite:audio
  /// event. Shared by the startAudioStream command and the restart path.
  Future<void> _openPageAudioStream() =>
      _engine.startAudioStream((pcm, preRoll) {
        bus.publish(AudioChunk(
          base64: base64Encode(pcm),
          sampleRate: 16000,
          preRoll: preRoll,
        ));
      });

  /// Reopen the mic on the newly selected device. Models come from the disk
  /// cache on the way back up, so the gap is brief; a rare, user-initiated
  /// change is worth it.
  Future<void> _restartForMicChange() async {
    final running = _runningEngine;
    if (running == null || !running.running) return;
    log.info(name, 'microphone selection changed; restarting the engine');
    await running.stop();
    _runningEngine = null;
    await _sync();
    // The page's audio stream (an idle-held one included) died with the old
    // engine; put it back so the next turn is not a 60-second hang against a
    // stream the page still believes is open.
    if (_pageAudioActive && _engine.running) {
      await _openPageAudioStream();
    }
  }

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
        // A tester opened before this engine came up (or across an engine
        // switch) still gets its telemetry.
        if (_testers > 0) _applyTelemetry();
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
    await _syncBackgroundService();
    bus.publish(WakeWordStateChanged(active: _active, listening: listening));
  }

  /// The stop word fired. Unlike a wake word this starts no turn and touches
  /// no engine state: the page owns what "stop" means (cancel TTS, pause media,
  /// silence a timer), and it disarms us as part of tearing that down.
  Future<void> _onStopDetection() async {
    log.info(name, 'stop word detected');
    bus.publish(const StopWordDetected());
  }

  /// Bring the app to the front when the wake word arrived while we were
  /// behind something else.
  ///
  /// Only when it is actually behind: [AppLifecycleState] is the last state the
  /// framework reported, and re-fronting an app that is already in front would
  /// mean every wake word poked the Activity for nothing.
  ///
  /// A missing "Display over other apps" grant is not a small problem here — we
  /// heard the wake word and cannot act on it, which is worse for the user than
  /// not having listened — so it is logged as an error and reads as one in both
  /// settings UIs, which show the grant as missing.
  Future<void> _comeForwardIfBehind() async {
    // Not resumed covers two distinct darknesses: the screen is off (the
    // kiosk still frontmost), or another app is in front. Waking a dark
    // panel needs no grant and no setting, so the attempt is made
    // unconditionally — bringToFront wakes the display first and only
    // then needs the overlay grant to actually switch tasks.
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return;
    }
    try {
      if (await BackgroundListening.bringToFront()) {
        log.info(name, 'woke the screen / brought the app forward');
      } else if (_settings.get(defs.wakeWordBackground)) {
        log.error(
            name,
            'heard the wake word from the background but cannot come forward: '
            '"Display over other apps" is not granted');
      }
    } catch (e) {
      log.warn(name, 'could not come forward: $e');
    }
  }

  Future<void> _onDetection(WakeWordModelRef model) async {
    // The engine has already paused detection and kept the mic — it is the
    // audio source for the turn the page is about to run.
    _active = false;
    log.info(name, 'detected "${model.id}"');
    // Heard from behind another app: come forward, or the turn happens on a
    // page nobody can see. Ordered before the event so the card's UI is on
    // screen by the time it reacts; the audio it will ask us for is already in
    // the pre-roll, so the trip costs nothing.
    await _comeForwardIfBehind();
    // A wake heard from the background may land on a websocket Chromium let die
    // while the WebView was hidden. Make it live and re-subscribed BEFORE Voice
    // Satellite starts its pipeline on it, or the run comes back as a duplicate
    // wake-up (a reconnect mid-pipeline) or a broken, reload-only page. A quick
    // no-op when the socket is already up, so foreground wakes pay nothing; the
    // deferred audio is in the pre-roll, so the short wait loses no speech.
    await commands.execute('ensureHaConnected', const {});
    bus.publish(WakeWordDetected(model: model.id, phrase: model.wakeWord));

    // Self-heal: if the page never resumes us (crash, navigation), re-arm.
    _resumeTimer?.cancel();
    final timeout =
        _settings.get(defs.wakeWordResumeTimeoutSeconds).toInt();
    if (timeout > 0) {
      _resumeTimer = Timer(Duration(seconds: timeout), () async {
        if (!_active) {
          log.warn(name, 'page never resumed listening; self-healing');
          // The page that opened the audio stream is gone with the turn;
          // without closing it every mic chunk keeps being base64-encoded
          // and published to a listener that no longer exists.
          _pageAudioActive = false;
          await _engine.stopAudioStream();
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
