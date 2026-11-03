import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../../core/permissions.dart';
import '../assist_pipeline/native_audio_source.dart';
import '../audio/mic_level_monitor.dart';
import '../analytics/usage_counters.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'background_listening.dart';
import 'engine.dart';
import 'model_cache.dart';
import 'playback_watch.dart';
import 'system_permissions.dart';
import 'wake_arbitration.dart';
import 'wake_diagnostics.dart';
import 'mww/mww_engine.dart';
import 'mww/mww_probe.dart';
import 'oww/oww_engine.dart';
import 'pryon/pryon_engine.dart';
import 'oww/oww_probe.dart';
import 'vsww/benchmark.dart';
import 'vsww/model_store.dart';
import 'vsww/native_mic.dart';
import 'vsww/vsww_engine.dart';
import 'package:kiosk_satellite/core/lifecycle.dart';

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
class WakeWordManager extends Manager
    with WidgetsBindingObserver
    implements NativeAudioSource {
  /// [engines] pre-seeds the per-runner engine map: a test hands in a fake
  /// that runs without models or a microphone. Production leaves it empty
  /// and the real engines are created lazily below.
  WakeWordManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    @visibleForTesting Map<WakeWordEngineType, WakeWordEngine>? engines,
    WakeWordDiagnostics? diagnostics,
    @visibleForTesting Future<bool> Function()? playbackPlayed,
  }) : _engines = {...?engines},
       diagnostics = diagnostics ?? WakeWordDiagnostics() {
    _playback = PlaybackWatch(
      onChanged: (playing) => _engine.setPlaybackActive(playing),
      wanted: () => _engine.running,
      played: playbackPlayed,
    );
  }

  /// Moves the wake words to their playback thresholds while the kiosk
  /// plays audio. Runs only while an engine runs a config that has them.
  late final PlaybackWatch _playback;

  /// The last few activations with a clip of each, while the user has wake
  /// word diagnostics on. Both settings UIs list them.
  final WakeWordDiagnostics diagnostics;

  final SettingsManager _settings;

  @override
  String get name => 'wake_word';

  // One engine per runner, created lazily and kept: switching wake word
  // engines should not re-download models the other one already has.
  final Map<WakeWordEngineType, WakeWordEngine> _engines;

  WakeWordEngine? _engineFor(WakeWordEngineType type) => switch (type) {
    WakeWordEngineType.vsWakeWord => _engines.putIfAbsent(
      type,
      () => VswwEngine(
        log,
        preferInt8: () => !_settings.get(defs.wakeWordPreferFp32),
      ),
    ),
    WakeWordEngineType.microWakeWord => _engines.putIfAbsent(
      type,
      () => MwwEngine(log),
    ),
    WakeWordEngineType.openWakeWord => _engines.putIfAbsent(
      type,
      () => OwwEngine(log),
    ),
    WakeWordEngineType.pryon => _engines.putIfAbsent(
      type,
      () => PryonEngine(log),
    ),
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
  Timer? _backgroundReturnTimer;
  StreamSubscription<VoiceInteractionChanged>? _backgroundInteractionSub;
  final _pageInteractions = <String>{};
  bool _returnToBackground = false;
  bool _voiceInteractionSeen = false;
  bool _returnedToScreen = false;
  int _backgroundReturnGeneration = 0;

  bool get _backgroundReturnEnabled =>
      _settings.get(defs.wakeWordBackground) &&
      _settings.get(defs.wakeWordReturnToBackground);

  void _cancelBackgroundReturn() {
    _backgroundReturnGeneration++;
    _backgroundReturnTimer?.cancel();
    _returnToBackground = false;
    _voiceInteractionSeen = false;
    _returnedToScreen = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_returnToBackground) return;
    if (!Lifecycle.offScreen(state)) {
      _returnedToScreen = true;
    } else if (_returnedToScreen) {
      // The user left during the interaction. A later manual return stays up.
      _cancelBackgroundReturn();
    }
  }

  /// Voice interactions from the dashboard's Voice Satellite or the native
  /// one: either can bring the kiosk forward and send it back after.
  void _onBackgroundInteraction(VoiceInteractionChanged event) {
    if (event.source != InteractionSource.page &&
        event.source != InteractionSource.native) {
      return;
    }
    if (event.active) {
      _pageInteractions.add(event.reason);
      _backgroundReturnTimer?.cancel();
      if (const {
        '',
        'voice',
        'announcement',
        'ask_question',
        'start_conversation',
      }.contains(event.reason)) {
        _voiceInteractionSeen = true;
      }
    } else {
      _pageInteractions.remove(event.reason);
      if (_pageInteractions.isEmpty && !_voiceInteractionSeen) {
        _cancelBackgroundReturn();
        return;
      }
      _scheduleBackgroundReturn();
    }
  }

  void _scheduleBackgroundReturn() {
    if (!_returnToBackground ||
        !_voiceInteractionSeen ||
        _pageInteractions.isNotEmpty) {
      return;
    }
    _backgroundReturnTimer?.cancel();
    // Let a follow-up turn or another queued interaction claim the screen.
    _backgroundReturnTimer = Timer(const Duration(milliseconds: 300), () async {
      final shouldReturn =
          _backgroundReturnEnabled && Lifecycle.onScreen && !_intercomHold;
      _cancelBackgroundReturn();
      if (!shouldReturn) return;
      try {
        if (await BackgroundListening.returnToBackground()) {
          log.info(
            name,
            'voice interaction finished, returned to previous app',
          );
        }
      } catch (e) {
        log.warn(name, 'could not return to previous app: $e');
      }
    });
  }

  Future<bool> _bringToFront({required bool voiceInteraction}) async {
    if (!voiceInteraction) _cancelBackgroundReturn();
    if (Lifecycle.onScreen) return true;
    if (!_returnToBackground) {
      _voiceInteractionSeen = _pageInteractions.any(
        const {
          '',
          'voice',
          'announcement',
          'ask_question',
          'start_conversation',
        }.contains,
      );
    }
    final generation = _backgroundReturnGeneration;
    final remember =
        voiceInteraction &&
        _backgroundReturnEnabled &&
        await BackgroundListening.isBehindAnotherApp();
    final broughtForward = await BackgroundListening.bringToFront();
    if (remember &&
        broughtForward &&
        generation == _backgroundReturnGeneration &&
        _backgroundReturnEnabled) {
      _returnToBackground = true;
      _returnedToScreen = Lifecycle.onScreen;
      _scheduleBackgroundReturn();
    }
    return broughtForward;
  }

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

  /// Begin streaming telemetry for a TESTER, which also suppresses real
  /// detections (a tester hit must not start a voice interaction).
  /// Reference counted so overlapping testers (device + remote) share one
  /// feed.
  void startTest() {
    _testers++;
    _applyTelemetry();
  }

  void stopTest() {
    if (_testers == 0) return;
    _testers--;
    _applyTelemetry();
  }

  // Remote mic-level watch. The admin UI cannot hold an in-process
  // subscription, so it re-arms this while its meter is visible and the
  // watch self-expires - a browser that vanishes mid-watch can never leave
  // the microphone open. Levels come off the shared capture
  // ([MicLevelMonitor]), not the engine, so the meter also works before
  // Voice Satellite has started one. Like the device's meter, never with
  // detection off: then this app does not open the microphone at all.
  Timer? _micLevelExpiry;
  bool _remoteMicObserved = false;
  StreamSubscription<RemoteObserversChanged>? _remoteObservers;
  StreamSubscription<double>? _micLevelSub;
  int _lastMicLevelPushMs = 0;

  void _watchMicLevel() {
    if (!enabled) return;
    _micLevelExpiry?.cancel();
    if (!_remoteMicObserved) {
      _micLevelExpiry = Timer(const Duration(seconds: 15), _stopMicLevelWatch);
    }
    if (_micLevelSub != null) return;
    final monitor = MicLevelMonitor.instance;
    _micLevelSub = monitor.levels.listen((rms) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastMicLevelPushMs < 100) return;
      _lastMicLevelPushMs = now;
      bus.publish(MicLevelSample(rms: rms));
    });
    monitor.start();
  }

  void _stopMicLevelWatch() {
    _micLevelExpiry?.cancel();
    _micLevelExpiry = null;
    if (_micLevelSub == null) return;
    _micLevelSub!.cancel();
    _micLevelSub = null;
    MicLevelMonitor.instance.stop();
  }

  bool get _diagnosticsOn => enabled && _settings.get(defs.wakeWordDiagnostics);

  /// Keep recent audio in the engine while something can use it: the tester
  /// plays back the last 10 seconds, and diagnostics saves a clip of each
  /// activation. Nobody else pays for the buffer.
  void _applyRecording() {
    _engine
      ..recordAudio = _testers > 0 || _diagnosticsOn || _arbitrationOn
      ..preRollExtra = _arbitrationOn ? _arbitrationWindow : Duration.zero
      ..onNearMiss = _diagnosticsOn ? _onNearMiss : null;
  }

  /// Wake word arbitration: only the native satellite takes part, and only
  /// with the switch on. The arbiter is made on first use and kept.
  bool get _arbitrationOn =>
      enabled &&
      _settings.get(defs.voiceRuntime) == 'native' &&
      _settings.get(defs.voiceEnabled) &&
      _settings.get(defs.voiceWakeArbitration);

  Duration get _arbitrationWindow => Duration(
    milliseconds: _settings
        .get(defs.voiceWakeArbitrationWindowMs)
        .clamp(100, 500)
        .toInt(),
  );

  @visibleForTesting
  WakeArbiter? arbiter;

  Future<void> _applyArbitration() async {
    _applyRecording();
    if (_arbitrationOn) {
      await (arbiter ??= WakeArbiter(log)).start();
    } else {
      await arbiter?.stop();
    }
  }

  /// Settle with the other kiosks that heard this wake word. True when
  /// this kiosk answers: it won, or there was nothing to settle.
  Future<bool> _arbitrate(WakeWordModelRef model) async {
    final a = arbiter;
    // A muted kiosk answers nothing, so it must not win for the others.
    if (a == null || !a.running || _settings.get(defs.voiceMute)) return true;
    // The microphone's own levels, from before the noise suppressor, or
    // the audio the engine heard where the platform keeps none.
    final levels = await NativeMic.recentLevels(wakeEnergyWindow);
    var energy = levels == null ? null : wakeEnergyOfLevels(levels);
    if (energy == null) {
      final pcm = _engine.recentAudio(wakeEnergyWindow);
      energy = pcm == null ? null : wakeEnergy(pcm);
    }
    if (energy == null) return true;
    energy += _settings.get(defs.voiceWakeArbitrationOffsetDb).toDouble();
    final phrase = model.wakeWord.isEmpty ? model.id : model.wakeWord;
    final r = await a.contend(
      phrase: phrase,
      energy: energy,
      window: _arbitrationWindow,
    );
    if (r.won) _lateClaim = a.overtaken(r, _arbitrationWindow);
    final mine = energy.toStringAsFixed(1);
    final heard = r.heard.isEmpty ? '' : '; heard ${r.heard.join(', ')}';
    log.info(
      name,
      r.won
          ? 'arbitration: answering at $mine dB$heard'
          : 'arbitration: ${r.winner} answers instead, '
                'this kiosk heard $mine dB$heard',
    );
    // Only a contested wake says arbitration did something: a win with
    // nobody else heard is every wake on a lone kiosk.
    if (!r.won) {
      unawaited(UsageCounters.bump(_settings, 'vs_arbitration_lost'));
    } else if (r.heard.isNotEmpty) {
      unawaited(UsageCounters.bump(_settings, 'vs_arbitration_won'));
    }
    return r.won;
  }

  /// After a win, a louder claim that may still come in late (see
  /// [WakeArbiter.overtaken]). Hooked up once the turn has started, so
  /// standing down always has a turn to end.
  Future<LateClaim?>? _lateClaim;

  /// A kiosk that detected the wake word later can claim it louder after
  /// this one's window closed. It heard this kiosk's claim inside its own
  /// window and answers, so this one ends the turn it just started instead
  /// of both answering.
  void _standDownIfOvertaken() {
    final late = _lateClaim;
    _lateClaim = null;
    late?.then((louder) async {
      if (louder == null) return;
      log.info(
        name,
        'arbitration: ${louder.from} claimed it louder (${louder.energy} dB) '
        'after the window, standing down',
      );
      await commands.execute('voiceCancel', const {});
    });
  }

  /// At most one near miss per this, so one noisy conversation cannot fill
  /// all ten slots in a few seconds.
  static const _nearMissGap = Duration(seconds: 3);
  DateTime? _lastNearMiss;

  void _onNearMiss(WakeWordModelRef model, Map<String, Object?> detail) {
    // A tester (or a clip playing back through the speaker, which holds
    // one) is not the room: its near misses are not worth keeping.
    if (!_diagnosticsOn || _testers > 0) return;
    final now = DateTime.now();
    final last = _lastNearMiss;
    if (last != null && now.difference(last) < _nearMissGap) return;
    final pcm = _engine.recentAudio(WakeWordDiagnostics.clipLength);
    if (pcm == null || pcm.isEmpty) return;
    _lastNearMiss = now;
    diagnostics
        .record(
          wakeWord: model.wakeWord,
          engine: _config?.engine.label ?? '',
          pcm: pcm,
          detection: detail,
          nearMiss: true,
          at: now,
        )
        .then(
          (_) {},
          onError: (Object e) =>
              log.warn(name, 'could not save the near miss: $e'),
        );
  }

  /// Up to [length] of what the engine heard last, as 16 kHz mono PCM16, or
  /// null when it is not recording (no tester open, diagnostics off).
  Uint8List? recentAudio(Duration length) => _engine.recentAudio(length);

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
    _engine.setTelemetry(want, tester: want);
    _applyRecording();
  }

  bool get enabled => _settings.get(defs.wakeWordEnabled);

  /// Something can start the engine: the native satellite while it is
  /// switched on, or the integration's engine on a dashboard runtime. With
  /// the native satellite off nothing listens, so the microphone and the
  /// background listening grants are not needed.
  bool get inUse =>
      enabled &&
      (_settings.get(defs.voiceRuntime) == 'dashboard' ||
          _settings.get(defs.voiceEnabled));

  /// The satellite is muted (the card said so when it released the mic).
  /// Carried on [WakeWordStateChanged] so the clap detector goes quiet too.
  bool get _muted => _released && _releaseReason == 'muted';

  /// Actively detecting. The engine can be running (mic open, models loaded)
  /// while detection is paused for the duration of a voice turn.
  bool get listening => _engine.running && _active;

  /// The wake-word config inherited from Voice Satellite (null until the VS
  /// card pushes it via setWakeWordConfig).
  WakeWordConfig? get config => _config;

  /// The page's Voice Satellite announced it knows the delegated pipeline
  /// transport (docs/js-api.md, "Pipeline delegation").
  bool _pagePipelineSupport = false;

  /// Whether voice turns will run their transport natively: the card said
  /// it knows the delegated pipeline AND this app can take it (Home
  /// Assistant configured, kill switch on). Rendered as the "Native voice
  /// pipeline" row by both settings UIs, off [describeState] so the two
  /// cannot disagree.
  bool get nativePipelineSupported =>
      _pagePipelineSupport &&
      _settings.get(defs.vsNativePipeline) &&
      _settings.get(defs.haUrl).isNotEmpty &&
      _settings.get(defs.haToken).isNotEmpty;

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

  /// Whether the page released the mic (engine stopped, muted, or detection
  /// handed back to the browser). The settings UIs collapse the "Running in
  /// Kiosk" rows behind this: the retained config only describes what the
  /// next push would run.
  bool get released => _released;

  /// What went wrong, or null when nothing has — or when it no longer matters
  /// because the card has since taken the microphone back.
  EngineFailure? get failure => canRetry ? _failure : null;

  /// The microphone is refused and Android will not ask again, so the only way
  /// back is the OS settings screen. Both UIs offer that when this is true.
  bool get needsAppSettings => failure == EngineFailure.micBlocked;

  /// Crashes seen in the current window, and when that window opened. A
  /// detector that dies once is worth restarting silently; one that dies
  /// over and over is a device this build cannot listen on, and pretending
  /// otherwise costs the user their voice assistant either way.
  int _crashes = 0;
  DateTime? _crashWindowStart;
  Timer? _crashRestart;

  static const _maxCrashRestarts = 3;
  static const _crashWindow = Duration(hours: 1);

  /// A dead detector, brought back rather than reported.
  ///
  /// The alternative is what issue #52 describes: the isolate dies, the app
  /// keeps saying "listening natively", and the device is deaf until someone
  /// notices and restarts it by hand. Voice Satellite is not told anything,
  /// because from its side nothing changed and a restart takes seconds.
  void _onEngineCrash(String detail) {
    final now = DateTime.now();
    if (_crashWindowStart == null ||
        now.difference(_crashWindowStart!) > _crashWindow) {
      _crashWindowStart = now;
      _crashes = 0;
    }
    _crashes++;
    if (_crashes > _maxCrashRestarts) {
      log.error(
        name,
        'the detector has crashed $_crashes times in the last hour; '
        'giving up on restarting it',
      );
      _onEngineFailure(EngineFailure.crashed, detail);
      return;
    }
    log.warn(
      name,
      'the detector crashed ($detail); restarting it '
      '($_crashes of $_maxCrashRestarts this hour)',
    );
    _runningEngine = null;
    // A beat before retrying: an immediate respawn against whatever killed
    // the last one just burns the allowance.
    _crashRestart?.cancel();
    _crashRestart = Timer(const Duration(seconds: 2), () async {
      await _runningEngine?.stop();
      await _engine.stop();
      _runningEngine = null;
      await _sync();
      // The page's audio stream died with the old engine; the mic-change
      // path does the same thing for the same reason.
      if (_pageAudioActive && _engine.running) {
        await _openPageAudioStream();
      } else if (_nativeAudioSink != null && _engine.running) {
        await _engine.startAudioStream(_nativeAudioSink!);
      }
    });
  }

  /// Automatic retries after a lost microphone in the current window, and
  /// when that window opened.
  ///
  /// Right after a boot the audio HAL can refuse AudioRecord for a few
  /// seconds, and nothing else would ever retry: the card only pushes config
  /// on page load, and that has already happened (issue #1145). A permission
  /// revoked underneath us lands here too, but the retry asks for the mic
  /// first, so it turns into micDeclined or micBlocked and the ladder stops.
  int _micRetries = 0;
  DateTime? _micRetryWindowStart;
  Timer? _micRetry;

  static const _micRetryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];
  static const _micRetryWindow = Duration(hours: 1);

  void _scheduleMicRetry() {
    final now = DateTime.now();
    if (_micRetryWindowStart == null ||
        now.difference(_micRetryWindowStart!) > _micRetryWindow) {
      _micRetryWindowStart = now;
      _micRetries = 0;
    }
    if (_micRetries >= _micRetryDelays.length) {
      log.error(
        name,
        'the microphone failed $_micRetries times in the last hour; '
        'giving up on reopening it',
      );
      return;
    }
    final delay = _micRetryDelays[_micRetries++];
    log.warn(
      name,
      'reopening the microphone in ${delay.inSeconds}s '
      '($_micRetries of ${_micRetryDelays.length} this hour)',
    );
    _micRetry?.cancel();
    _micRetry = Timer(delay, () {
      _micRetry = null;
      // Something else may have retried or taken the mic back meanwhile.
      if (!_failed || _failure != EngineFailure.micLost || _released) return;
      log.info(name, 'reopening the microphone');
      unawaited(retry());
    });
  }

  void _onEngineFailure(EngineFailure kind, String detail) {
    if (kind == EngineFailure.crashed && _crashes <= _maxCrashRestarts) {
      _onEngineCrash(detail);
      return;
    }
    _failed = true;
    _failure = kind;
    _runningEngine = null;
    log.error(
      name,
      'engine unavailable ($detail); Voice Satellite keeps browser detection',
    );
    if (kind == EngineFailure.micLost && !_released) _scheduleMicRetry();
    // Tell the page and the settings UIs, both of which may be showing
    // "Listening natively" over a microphone that no longer exists.
    bus.publish(
      WakeWordStateChanged(
        active: _active,
        listening: listening,
        muted: _muted,
      ),
    );
  }

  /// Try again after a failure: re-ask for the microphone, re-fetch the models.
  ///
  /// The card only pushes config on page load, so without this a stray "Don't
  /// allow" leaves the device deaf until something reloads it — and the person
  /// who tapped it has no idea that is the fix.
  Future<bool> retry() async {
    _micRetry?.cancel();
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
        label:
            'Wake word detection is off. Turn it on to inherit models from '
            'Voice Satellite.',
      );
    }
    final config = _config;
    if (config == null) {
      return (
        code: 'waiting',
        label:
            'Waiting for Voice Satellite. The engine and wake words are '
            'configured by the card once this device opens its dashboard.',
      );
    }
    if (_released) {
      // Why the card took the mic back is the card's to know: mute and "the
      // browser is taking detection back" are the same event to us.
      return switch (_releaseReason) {
        'muted' => (
          code: 'muted',
          label:
              'Muted in Voice Satellite. The microphone is closed until '
              'the satellite is unmuted.',
        ),
        'browser' => (
          code: 'browser',
          label:
              'Voice Satellite is running detection in the browser for '
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
          label:
              'Microphone blocked. Android will not ask again, so allow it '
              'in the app settings, then retry.',
        ),
        EngineFailure.micDeclined => (
          code: 'micDeclined',
          label:
              'Microphone declined. Wake word detection needs it; retry '
              'to be asked again.',
        ),
        EngineFailure.micLost => (
          code: 'micLost',
          label: 'The microphone stopped working. Retry, or reload the page.',
        ),
        EngineFailure.modelsUnavailable => (
          code: 'modelsUnavailable',
          label:
              'Could not download the models from Home Assistant. Retry '
              'once it is reachable.',
        ),
        EngineFailure.crashed => (
          code: 'crashed',
          label:
              'The detector kept crashing on this device, so it was '
              'stopped. Voice Satellite is listening in the browser '
              'instead. Retry, or restart the app.',
        ),
        null => (
          code: 'failed',
          label:
              'The wake-word engine could not start. Retry, or reload '
              'the page.',
        ),
      };
    }
    if (!_engine.supportedEngines.contains(config.engine)) {
      return (
        code: 'unavailable',
        label:
            'No native runner for ${config.engine.label}. Voice Satellite '
            'keeps browser detection.',
      );
    }
    return listening
        ? (code: 'listening', label: 'Listening natively')
        : (
            code: 'suspended',
            label: 'Ready (suspended during a voice session)',
          );
  }

  /// The whole wake-word state as data: what `getWakeWordState` answers, what
  /// the settings screen draws, and what the web admin draws. One shape, so the
  /// two UIs cannot disagree.
  /// Aggregate precision of the loaded vsWakeWord models for the settings
  /// UIs: 'int8', 'fp32', 'mixed' (some fell back), or null when the engine
  /// is not vsWakeWord or nothing has downloaded yet.
  String? get modelPrecision {
    final config = _config;
    if (config == null || config.engine != WakeWordEngineType.vsWakeWord) {
      return null;
    }
    final ids = [
      for (final m in config.models) m.id,
      if (config.stopModel != null) config.stopModel!.id,
    ];
    final seen = {for (final id in ids) _engine.modelPrecision(id)}
      ..remove(null);
    if (seen.isEmpty) return null;
    return seen.length == 1 ? seen.first : 'mixed';
  }

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
    'muted': _muted,
    'needsAppSettings': needsAppSettings,
    'stopWord': _config?.stopModel?.wakeWord,
    'nativePipeline': nativePipelineSupported,
    'models': [
      for (final m in _config?.models ?? const <WakeWordModelRef>[])
        {
          ...m.toJson(),
          // Which file the engine actually loaded ('int8'/'fp32'); null
          // until the download has happened.
          'precision': _engine.modelPrecision(m.id),
        },
    ],
    'stopWordPrecision': switch (_config?.stopModel?.id) {
      null => null,
      final id => _engine.modelPrecision(id),
    },
    'modelPrecision': modelPrecision,
  };

  @override
  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    // Saved activations belong to a switch that is on; anything left over
    // from one turned off mid-write goes now.
    unawaited(_diagnosticsOn ? diagnostics.load() : diagnostics.clear());
    unawaited(_applyArbitration());
    diagnostics.addListener(
      () => bus.publish(const RemoteStatusChanged('wakeword-activations')),
    );
    _backgroundInteractionSub = bus.on<VoiceInteractionChanged>().listen(
      _onBackgroundInteraction,
    );
    _remoteObservers = bus.on<RemoteObserversChanged>().listen((event) {
      final observed = event.topics.contains('micLevel');
      if (observed == _remoteMicObserved) return;
      _remoteMicObserved = observed;
      if (observed) {
        _watchMicLevel();
      } else {
        _stopMicLevelWatch();
      }
    });
    bus.on<VoiceInteractionChanged>().listen((e) {
      if (e.reason != 'intercom' || e.active == _intercomHold) return;
      _intercomHold = e.active;
      log.info(
        name,
        e.active
            ? 'paused for an intercom call'
            : 'resumed after the intercom call',
      );
      _sync();
    });
    bus.on<SettingChanged>().listen((e) {
      if ((e.key == defs.wakeWordBackground.key ||
              e.key == defs.wakeWordReturnToBackground.key) &&
          !_backgroundReturnEnabled) {
        _cancelBackgroundReturn();
      }
      if (e.key == defs.wakeWordEnabled.key ||
          e.key == defs.wakeWordBackground.key ||
          e.key == defs.lockdownEnabled.key) {
        _sync();
      } else if (e.key == defs.audioMicDevice.key) {
        // The engine reads its capture device when the mic opens, so a new
        // selection needs a stop/start. AudioRoutingManager has already
        // updated the selector by the time this listener runs (it inits,
        // and so subscribes, before this manager).
        _restartForMicChange('microphone selection changed');
      } else if (e.key == defs.micEchoCancellationMethod.key &&
          defs.isEchoMethodVerdict(e.previous, e.value)) {
        // Automatic's verdict: the canceller already runs it.
      } else if (e.key == defs.micCaptureMode.key ||
          e.key == defs.micSoftwareEchoCancellation.key ||
          e.key == defs.micEchoCancellationMethod.key ||
          e.key == defs.micNoiseSuppression.key ||
          e.key == defs.micGainDb.key ||
          e.key == defs.micChannel.key ||
          e.key == defs.micCaptureFormat.key) {
        // Capture tuning and effects are fixed when the
        // capture session opens, so they land the same way the device
        // selection does.
        _restartForMicChange('microphone settings changed');
      } else if (e.key == defs.wakeWordDiagnostics.key) {
        _applyRecording();
        if (!_diagnosticsOn) unawaited(diagnostics.clear());
        // The remote list shows or hides with the switch, even when there
        // is nothing to clear.
        bus.publish(const RemoteStatusChanged('wakeword-activations'));
      } else if (e.key == defs.voiceWakeArbitration.key ||
          e.key == defs.voiceWakeArbitrationWindowMs.key ||
          e.key == defs.voiceEnabled.key ||
          e.key == defs.voiceRuntime.key) {
        unawaited(_applyArbitration());
      } else if (e.key == defs.wakeWordPreferFp32.key) {
        // Models are fetched at engine start; a precision flip needs the
        // same stop/start to re-download as a mic change does.
        _restartForMicChange('model precision preference changed');
      }
    });

    // Hotplug: the selected mic connected or vanished, so the open capture
    // is on the wrong device until it reopens.
    bus.on<AudioDevicesChanged>().listen((e) {
      if (e.capturePathChanged) {
        _restartForMicChange('selected microphone came or went');
      }
    });

    commands
      ..register(
        Command(
          name: 'setStopWordArmed',
          description:
              'Arm or disarm the stop word for a holder (a ringing alarm). '
              'It listens while any holder wants it.',
          params: const {
            'armed': 'true or false',
            'holder': 'who is asking, alarm by default',
          },
          handler: (p) async => CommandResult.ok(
            await setStopWordArmed(
              p['armed'] == true,
              holder: '${p['holder'] ?? 'alarm'}',
            ),
          ),
        ),
      )
      ..register(
        Command(
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
            // The card announces whether it knows the delegated pipeline
            // transport; absent means a build that predates it. Recorded per
            // push (one per page load), so a downgrade reads honest.
            _pagePipelineSupport = p['nativePipeline'] == true;
            await configure(config, source: 'page');
            return CommandResult.ok({
              'available': available,
              'stopWordAvailable': stopWordAvailable,
            });
          },
        ),
      )
      ..register(
        Command(
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
            await release(p['reason'] as String?, source: 'page');
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
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
        ),
      )
      ..register(
        Command(
          name: 'setWakeWordActive',
          description:
              'Resume (active=true) or suspend native wake-word listening. '
              'Pages must resume after their voice session returns to idle.',
          params: const {'active': 'true to resume, false to suspend'},
          handler: (p) async {
            setActive(p['active'] == true);
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'getWakeWordState',
          description: 'Current wake-word engine state',
          handler: (_) async => CommandResult.ok(describeState()),
        ),
      )
      ..register(
        Command(
          name: 'bringToFront',
          description:
              'Bring the app to the foreground, for a server-initiated '
              'interaction (announcement, ask_question, start_conversation) that '
              'arrives while the app is behind another one. No-op when already in '
              'front; false when it cannot come forward (no "Display over other '
              'apps" grant). The app must be running to receive the trigger at '
              'all, which is what keeping the wake word alive in the background '
              'ensures.',
          handler: (p) async {
            // Already in front: do nothing and report success. Relaunching a
            // foreground Activity recreates the WebView and reloads the page —
            // dropping the card session in the middle of the very interaction
            // this was meant to reveal. Only come forward when actually behind
            // something (same guard as the native wake path).
            return CommandResult.ok(
              await _bringToFront(
                voiceInteraction: p['voiceInteraction'] == true,
              ),
            );
          },
        ),
      )
      ..register(
        Command(
          name: 'retryWakeWord',
          description:
              'Try to start the wake-word engine again after a failure: '
              're-asks for the microphone and re-fetches the models. The card '
              'only pushes config on page load, so this is the way back without '
              'a reload.',
          handler: (_) async {
            final ok = await retry();
            return CommandResult.ok({'available': ok, ...describeState()});
          },
        ),
      )
      ..register(
        Command(
          name: 'openAppSettings',
          description:
              'Open this app in the OS settings. The only way back from '
              'a microphone the user blocked, since Android stops asking.',
          handler: (_) async {
            final opened = await openOsAppSettings();
            return opened
                ? const CommandResult.ok()
                : const CommandResult.fail('could not open the OS settings');
          },
        ),
      )
      ..register(
        Command(
          name: 'getSystemPermissions',
          description:
              'OS grants native wake-word detection needs, and whether '
              'this device holds them. Read-only: they can only be given on the '
              'device itself. `required` is false when nothing listens for '
              'the wake word, as with Voice Satellite switched off, and none '
              'of this applies.',
          handler: (_) async {
            final perms = await SystemPermissions.read();
            return CommandResult.ok({
              'required': inUse,
              'background': _settings.get(defs.wakeWordBackground),
              ...perms.toJson(),
            });
          },
        ),
      )
      ..register(
        Command(
          name: 'watchMicLevel',
          description:
              'Stream microphone level samples to admin clients for '
              'the settings meter, opening the microphone when no wake word '
              'engine holds it. Expires after 15 s: callers re-arm it while '
              'their meter is visible, so a closed browser stops the stream '
              'on its own.',
          handler: (_) async {
            if (!enabled) {
              return const CommandResult.fail('wake word detection is off');
            }
            _watchMicLevel();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'clearWakeWordModels',
          description:
              'Delete cached wake-word models and re-download them. '
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
            log.info(
              name,
              'cleared $removed cached model file(s) (${(held / 1024).round()} KB)',
            );
            // Coming back up re-fetches from Home Assistant.
            await _sync();
            return CommandResult.ok({
              'removed': removed,
              'bytesFreed': held,
              'restarted': running && _engine.running,
            });
          },
        ),
      )
      ..register(
        Command(
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
        ),
      )
      ..register(
        Command(
          name: 'stopAudioStream',
          description: 'Stop streaming mic audio to the page',
          handler: (_) async {
            _pageAudioActive = false;
            await _engine.stopAudioStream();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'startWakeWordTest',
          description:
              'Start streaming per-inference wake-word telemetry (score, '
              'threshold, rms, latency, near-miss) for the wake word tester',
          handler: (_) async {
            startTest();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'stopWakeWordTest',
          description: 'Stop wake-word telemetry streaming',
          handler: (_) async {
            stopTest();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'getWakeWordActivations',
          description:
              'The last wake word activations and near misses saved by '
              'wake word diagnostics, newest first, with their scores and '
              'clip levels',
          quiet: true,
          handler: (_) async => CommandResult.ok({
            'enabled': _diagnosticsOn,
            'activations': [
              for (final a in diagnostics.activations) a.toJson(),
            ],
            'nearMisses': [for (final a in diagnostics.nearMisses) a.toJson()],
          }),
        ),
      )
      ..register(
        Command(
          name: 'getWakeWordActivationAudio',
          description:
              'The clip of one saved wake word activation or near miss, as '
              'a base64 WAV '
              '(16 kHz mono PCM16)',
          params: const {'id': 'the activation id'},
          quiet: true,
          handler: (p) async {
            final file = await diagnostics.clip('${p['id']}');
            if (file == null) return const CommandResult.fail('no such clip');
            return CommandResult.ok({
              'mimeType': 'audio/wav',
              'base64': base64Encode(await file.readAsBytes()),
            });
          },
        ),
      )
      ..register(
        Command(
          name: 'benchmarkVsww',
          description:
              'Benchmark vsWakeWord ONNX inference across CPU/XNNPACK/NNAPI '
              'execution providers (ms per inference vs the 80 ms budget)',
          params: const {
            'manifestUrl': 'model manifest URL (defaults to first configured)',
            'iters': 'timed iterations (default 60)',
          },
          handler: (p) async {
            final url =
                (p['manifestUrl'] as String?) ??
                _config?.models.firstOrNull?.manifestUrl;
            if (url == null || url.isEmpty) {
              return const CommandResult.fail(
                'no manifestUrl and no configured model',
              );
            }
            // Stop live capture so it doesn't compete for CPU during timing.
            final wasActive = _active;
            await _engine.stop();
            try {
              final model = await VswwModelStore().fetch(url);
              final result = await VswwBenchmark(
                log,
              ).run(model, iters: (p['iters'] as num?)?.toInt() ?? 60);
              return CommandResult.ok(result);
            } catch (e) {
              return CommandResult.fail('$e');
            } finally {
              _active = wasActive;
              await _sync(); // resume listening if it was on
            }
          },
        ),
      )
      ..register(
        Command(
          name: 'probeMww',
          description:
              'Can this device run a microWakeWord .tflite model? Reports its '
              'tensors and times one invoke. Groundwork for native mww.',
          params: const {
            'url': 'absolute .tflite URL',
            'compare':
                'true to also run one input sequence through the '
                'default runtime and through XNNPACK with variable operators '
                'and report both output streams',
          },
          handler: (p) async {
            final url = p['url'] as String?;
            if (url == null || url.isEmpty) {
              return const CommandResult.fail('url required');
            }
            final res = await probeMww(
              url,
              compare: p['compare'] == true || p['compare'] == 'true',
            );
            log.info(name, 'mww probe: $res');
            return CommandResult.ok(res);
          },
        ),
      )
      ..register(
        Command(
          name: 'probeOww',
          description:
              'Can this device run the openWakeWord chain (mel + embedding + '
              'classifier) in real time on the CPU? Times each stage against the '
              '80ms per-chunk budget. Groundwork for native oww.',
          params: const {
            'base':
                'models base URL, e.g. <ha>/voice_satellite/models/openwakeword',
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
        ),
      )
      ..register(
        Command(
          name: 'injectWakeAudio',
          description:
              'Diagnostic: feed a wake word clip through the running engine as '
              'if the mic had heard it (real capture muted meanwhile), '
              'optionally after a stretch of digital silence and repeated with '
              'a noise gap between repeats. In tester mode (default) no turn '
              'starts and the per-inference telemetry is returned instead.',
          params: const {
            'wavBase64': 'WAV file (16 kHz mono PCM16), base64',
            'silenceMs': 'digital silence fed before the first clip (3200)',
            'repeat': 'how many times the clip is fed (2)',
            'gapMs': 'noise fed between repeats (3000)',
            'gapRms': 'rms of that noise, full scale 1.0 (0.1)',
            'tester': 'suppress real detections, return telemetry (true)',
          },
          handler: (p) async {
            if (!_engine.running) {
              return const CommandResult.fail('engine not running');
            }
            final wav = p['wavBase64'] as String?;
            if (wav == null || wav.isEmpty) {
              return const CommandResult.fail('wavBase64 required');
            }
            final clip = _wavPcm16k(base64Decode(wav));
            if (clip == null) {
              return const CommandResult.fail(
                'WAV must be 16 kHz mono PCM16 with a data chunk',
              );
            }
            final silenceMs = (p['silenceMs'] as num? ?? 3200).toInt();
            final repeat = (p['repeat'] as num? ?? 2).toInt().clamp(1, 10);
            final gapMs = (p['gapMs'] as num? ?? 3000).toInt();
            final gapRms = (p['gapRms'] as num? ?? 0.1).toDouble();
            final tester = p['tester'] != false;

            // Assemble: silence, clip, (noise, clip) x (repeat - 1), tail.
            final out = BytesBuilder(copy: false);
            final clipWindows = <Map<String, int>>[];
            out.add(Uint8List(silenceMs * 32));
            for (var i = 0; i < repeat; i++) {
              if (i > 0) out.add(_noisePcm(gapMs, gapRms, seed: i));
              final startMs = out.length ~/ 32;
              out.add(clip);
              clipWindows.add({'startMs': startMs, 'endMs': out.length ~/ 32});
            }
            out.add(Uint8List(500 * 32));
            final pcm = out.takeBytes();

            final samples = <Map<String, Object?>>[];
            StreamSubscription<Map<String, Object?>>? sub;
            if (tester) {
              sub = telemetry.listen(samples.add);
              startTest();
              // Let the isolate pick the tester flag up before audio arrives.
              await Future<void>.delayed(const Duration(milliseconds: 200));
            }
            final startMs = await _engine.injectAudio(pcm);
            if (startMs == null) {
              await sub?.cancel();
              if (tester) stopTest();
              return const CommandResult.fail('engine could not inject');
            }
            // Wait for the isolate to chew through the queue: done when the
            // telemetry clock passes the end of the injected audio, or when
            // nothing arrives for a while.
            final endMs = startMs + pcm.length ~/ 32;
            final deadline = DateTime.now().add(const Duration(seconds: 20));
            var lastCount = -1;
            var idle = 0;
            while (DateTime.now().isBefore(deadline)) {
              await Future<void>.delayed(const Duration(milliseconds: 250));
              final t = samples.isEmpty
                  ? -1
                  : (samples.last['t'] as num).toInt();
              if (t >= endMs) break;
              if (samples.length == lastCount) {
                if (++idle >= (tester ? 8 : 4)) break;
              } else {
                idle = 0;
                lastCount = samples.length;
              }
            }
            await sub?.cancel();
            if (tester) stopTest();

            // Per clip: what the detector saw inside its window plus a second
            // of slack for the sliding window to fill.
            final perClip = <Map<String, Object?>>[];
            for (final w in clipWindows) {
              final lo = startMs + w['startMs']!;
              final hi = startMs + w['endMs']! + 1000;
              final inWin = samples.where((m) {
                final t = (m['t'] as num).toInt();
                return t >= lo && t <= hi && m['id'] != null;
              }).toList();
              double maxRaw = 0, maxScore = 0;
              var fired = 0;
              // Each model's best score in the window: several classifiers
              // listen at once, and one firing says nothing of the others.
              final byModel = <String, double>{};
              for (final m in inWin) {
                final raw = (m['raw'] as num?)?.toDouble() ?? 0;
                final sc = (m['score'] as num?)?.toDouble() ?? 0;
                if (raw > maxRaw) maxRaw = raw;
                if (sc > maxScore) maxScore = sc;
                if (m['fired'] == true) fired++;
                final id = '${m['id']}';
                if (sc > (byModel[id] ?? -1)) byModel[id] = sc;
              }
              perClip.add({
                'clipStartMs': w['startMs'],
                'inferences': inWin.length,
                'maxRaw': maxRaw,
                'maxScore': maxScore,
                'fired': fired,
                'models': byModel,
              });
            }
            return CommandResult.ok({
              'fedMs': pcm.length ~/ 32,
              'timelineStartMs': startMs,
              'tester': tester,
              'telemetrySamples': samples.length,
              'firedAtMs': [
                for (final m in samples)
                  if (m['fired'] == true && (m['t'] as num).toInt() >= startMs)
                    (m['t'] as num).toInt() - startMs,
              ],
              'clips': perClip,
            });
          },
        ),
      )
      ..register(
        Command(
          name: 'simulateWakeWord',
          description:
              'Fire a wake-word detection without the engine, for testing the '
              'Voice Satellite handoff end-to-end',
          handler: (_) async {
            final model =
                _config?.models.firstOrNull ??
                const WakeWordModelRef(
                  id: 'test',
                  wakeWord: 'Test',
                  manifestUrl: '',
                );
            await _onDetection(model, simulated: true);
            return const CommandResult.ok();
          },
        ),
      );

    await _sync();
  }

  /// Whether an intercom call holds detection (see _sync).
  bool _intercomHold = false;

  /// Run [config]: what Voice Satellite pushes from the page, or what the
  /// native satellite builds from its own settings ([source] says which, for
  /// the log). A genuinely new config (a different wake word, the stop word
  /// switched on) restarts the engine, which only reads it at start; the
  /// same config again does not, since that would reload every model. A push
  /// after a failure retries even when identical: whatever broke (a mic
  /// permission, a missing model) may be fixed by now.
  Future<void> configure(
    WakeWordConfig config, {
    String source = 'page',
  }) async {
    final changed = _config != config || _released || _failed;
    _micRetry?.cancel(); // this push is the retry
    _released = false; // a fresh config takes the mic back
    _releaseReason = null;
    _failed = false; // and re-earns the right to claim availability
    _config = config;
    if (changed && _engine.running) {
      log.info(name, 'config changed; restarting engine');
      await _engine.stop();
    }
    log.info(
      name,
      'configured by $source: ${config.engine.name} '
      '[${config.models.map((m) => m.id).join(', ')}]'
      '${config.stopModel == null ? '' : ' + stop:${config.stopModel!.id}'}'
      '${available ? '' : ' (no native runner, reporting unavailable)'}',
    );
    await _sync();
    // A fresh config owns no interruptible state yet, so it cannot want the
    // stop word armed. Without this, a page reload would inherit the previous
    // page's arming: it never disarms on the way out, and an unchanged config
    // does not restart the engine.
    await _engine.setStopWordActive(false);
  }

  /// Stop detection and close the microphone until the next [configure]:
  /// the satellite muted ('muted'), detection taken elsewhere ('browser'),
  /// or the native satellite standing down.
  Future<void> release(String? reason, {String source = 'page'}) async {
    if (_released) return;
    _released = true;
    _releaseReason = reason;
    _resumeTimer?.cancel();
    _micRetry?.cancel();
    _active = true; // a later config starts listening, not suspended
    await _engine.stop();
    log.info(name, 'released by $source (mic closed)');
    bus.publish(
      WakeWordStateChanged(
        active: _active,
        listening: listening,
        muted: _muted,
      ),
    );
  }

  /// Who wants the stop word listening: the voice turn (TTS, a ringing
  /// timer) and a ringing alarm arm it apart, and it stays armed while
  /// either still wants it.
  final _stopWordHolders = <String>{};

  /// Arm or disarm the stop word classifier for [holder]; false when none
  /// is loaded.
  Future<bool> setStopWordArmed(bool armed, {String holder = 'voice'}) async {
    armed ? _stopWordHolders.add(holder) : _stopWordHolders.remove(holder);
    if (!stopWordAvailable) return false;
    await _engine.setStopWordActive(_stopWordHolders.isNotEmpty);
    return true;
  }

  /// Page-driven resume/suspend (setWakeWordActive).
  void setActive(bool active) {
    _active = active;
    log.info(name, active ? 'resumed' : 'suspended');
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
        bus.publish(
          AudioChunk(
            base64: base64Encode(pcm),
            sampleRate: 16000,
            preRoll: preRoll,
          ),
        );
      });

  /// In-process consumer for the native pipeline transport (the assist
  /// pipeline manager), so a delegated turn's audio never leaves the app.
  /// Same single-consumer engine stream the page path uses — Voice
  /// Satellite runs one or the other per turn, never both.
  void Function(Uint8List pcm, bool preRoll)? _nativeAudioSink;

  /// Open the mic for the native pipeline transport. Pre-roll semantics are
  /// identical to the page stream: already-captured audio since the wake
  /// word's end is flushed first, flagged preRoll.
  @override
  Future<bool> openNativeAudioStream(
    void Function(Uint8List pcm, bool preRoll) onChunk,
  ) async {
    if (!_engine.running) return false;
    _nativeAudioSink = onChunk;
    await _engine.startAudioStream(onChunk);
    return true;
  }

  @override
  Future<void> closeNativeAudioStream() async {
    if (_nativeAudioSink == null) return;
    _nativeAudioSink = null;
    await _engine.stopAudioStream();
  }

  /// Reopen the mic on the right device. Models come from the disk cache on
  /// the way back up, so the gap is brief; a rare, user- or hotplug-driven
  /// change is worth it.
  Future<void> _restartForMicChange(String reason) async {
    final running = _runningEngine;
    if (running == null || !running.running) return;
    log.info(name, '$reason; restarting the engine');
    await running.stop();
    _runningEngine = null;
    await _sync();
    // The page's audio stream (an idle-held one included) died with the old
    // engine; put it back so the next turn is not a 60-second hang against a
    // stream the page still believes is open. Same for the native pipeline's
    // in-process stream.
    if (_pageAudioActive && _engine.running) {
      await _openPageAudioStream();
    } else if (_nativeAudioSink != null && _engine.running) {
      await _engine.startAudioStream(_nativeAudioSink!);
    }
  }

  /// The engine stays running — mic open, models loaded — for the whole time
  /// wake word detection is enabled. Suspending during a voice turn only
  /// pauses detection: tearing the engine down per wake would re-download and
  /// recompile every model, and would drop the mic the page is streaming from.
  /// One sync at a time. The engine only counts as running once its isolate
  /// is ready, so two syncs in a row (the native satellite reconfigures on
  /// every setting a migration writes) both saw it stopped and both started
  /// it: the second start took over the first one's fields, and the first,
  /// never hearing ready, timed out 20 seconds later and marked the engine
  /// failed under a turn that had just worked.
  Future<void> _syncChain = Future.value();

  Future<void> _sync() {
    _syncChain = _syncChain.then((_) => _syncNow()).catchError((Object e) {
      log.warn(name, 'engine sync failed: $e');
    });
    return _syncChain;
  }

  /// The config the running engine was started with.
  WakeWordConfig? _startedConfig;

  Future<void> _syncNow() async {
    // Lockdown Mode mutes the microphone too: a locked tablet should not
    // answer voice any more than touch. The engine stops (mic closed) and
    // comes back through this same sync when the mode lifts, exactly as if
    // the wake word toggle had been flipped, without touching the setting.
    final shouldRun =
        enabled && available && !_settings.get(defs.lockdownEnabled);
    // A config that switched runners (vsWakeWord -> microWakeWord) leaves the
    // previous engine running and holding the mic. Stop it before starting the
    // new one, or two engines fight over the microphone.
    final desired = shouldRun ? _engine : null;
    final previous = _runningEngine;
    if (previous != null && !identical(previous, desired) && previous.running) {
      log.info(name, 'engine changed; stopping the previous runner');
      await previous.stop();
      previous.recordAudio = false;
      _runningEngine = null;
    }
    // A config that changed while a start was still loading: the engine came
    // up with the one before.
    if (shouldRun && _engine.running && _startedConfig != _config) {
      log.info(name, 'config changed; restarting engine');
      await _engine.stop();
    }
    if (shouldRun && !_engine.running) {
      _startedConfig = _config;
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
          '${_engine.supportsStopWord ? ' + stop word' : ''}',
        );
        _runningEngine = _engine;
        _watchPlayback();
        // A tester opened before this engine came up (or across an engine
        // switch) still gets its telemetry.
        if (_testers > 0) _applyTelemetry();
        _applyRecording();
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
          'reporting unavailable so Voice Satellite keeps browser detection',
        );
      }
    } else if (!shouldRun && _engine.running) {
      await _engine.stop();
      _runningEngine = null;
      log.info(name, 'stopped');
    }
    if (_engine.running) {
      // An intercom call holds detection too: the far voice and the near
      // one both stay out of the assistant, and the page never asked.
      if (_active && !_intercomHold) {
        await _engine.resumeDetection();
      } else {
        await _engine.pauseDetection();
      }
    }
    bus.publish(
      WakeWordStateChanged(
        active: _active,
        listening: listening,
        muted: _muted,
      ),
    );
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
    if (Lifecycle.onScreen) return;
    try {
      if (await _bringToFront(voiceInteraction: true)) {
        log.info(name, 'woke the screen / brought the app forward');
      } else if (_settings.get(defs.wakeWordBackground)) {
        log.error(
          name,
          'heard the wake word from the background but cannot come forward: '
          '"Display over other apps" is not granted',
        );
      }
    } catch (e) {
      log.warn(name, 'could not come forward: $e');
    }
  }

  Future<void> _onDetection(
    WakeWordModelRef model, {
    bool simulated = false,
  }) async {
    // The engine has already paused detection and kept the mic — it is the
    // audio source for the turn the page is about to run.
    _active = false;
    log.info(name, 'detected "${model.id}"');
    // Before any await: the clip must end at the detection, not wherever
    // the mic has got to once the screen is on.
    _recordActivation(model, simulated: simulated);
    _lateClaim = null;
    // Another kiosk heard it louder: back to listening before anything
    // about the turn shows, chimes or reaches Home Assistant.
    if (!simulated && !await _arbitrate(model)) {
      setActive(true);
      return;
    }
    // A dark panel wakes first, before anything else about the turn:
    // someone spoke to the device, and the UI the turn is about to show
    // must land on a lit screen. Covers the screensaver's screen-off timer
    // and any other power-off, from the foreground or behind another app
    // alike; a no-op when the panel is already lit.
    await commands.execute('screenOn', const {});
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
    _standDownIfOvertaken();

    // Self-heal: if the page never resumes us (crash, navigation), re-arm.
    _armResumeTimer();
  }

  void _recordActivation(WakeWordModelRef model, {required bool simulated}) {
    if (!_diagnosticsOn) return;
    final pcm = _engine.recentAudio(WakeWordDiagnostics.clipLength);
    if (pcm == null || pcm.isEmpty) return;
    diagnostics
        .record(
          wakeWord: model.wakeWord,
          engine: _config?.engine.label ?? '',
          pcm: pcm,
          // A simulated wake has no score; the engine's is an older one.
          detection: simulated ? null : _engine.lastDetection,
        )
        .then(
          (_) {},
          onError: (Object e) =>
              log.warn(name, 'could not save the activation: $e'),
        );
  }

  /// Whether a voice turn is running on the mic right now: the page (or the
  /// native pipeline on its behalf) opened the audio stream after the
  /// handoff and has not closed it. Proof that the page is alive and busy.
  bool get _turnStreamOpen => _pageAudioActive || _nativeAudioSink != null;

  /// How long an open turn stream keeps the self-heal waiting, in total.
  /// No voice turn lasts this long, so a stream still open at this point
  /// belongs to a page that died mid-turn without reloading, and the mic
  /// chunks it keeps receiving go nowhere. Healing then costs no one a turn.
  static const _turnCeilingSeconds = 600;

  /// Arm the self-heal for the handoff that just happened.
  ///
  /// The page is expected to call setWakeWordActive(true) when its turn ends.
  /// A page that crashed or navigated away never will, and without this the
  /// wake word stays suspended for good. The timeout counts from the handoff
  /// and is measured against the page's silence, not the turn's length: while
  /// the turn's audio stream is open the page is demonstrably alive, so a
  /// fire during the turn re-arms for another period instead of healing.
  /// Healing then would stop a stream that is still feeding STT, which is
  /// exactly a turn cut off mid-sentence, and a short timeout (the setting
  /// has no floor) made that happen on every wake. The check lands within one
  /// period of the stream closing, so a page lost after its turn is still
  /// caught, and [_turnCeilingSeconds] bounds the wait for one lost mid-turn.
  ///
  /// The native satellite ends its own turns and hands the wake word back
  /// when it goes idle, past its own watchdogs, and a spoken answer can run
  /// long after the microphone closed. It keeps only the ceiling as a
  /// backstop, never the page's timeout.
  void _armResumeTimer({int deferred = 0}) {
    _resumeTimer?.cancel();
    final timeout = _settings.get(defs.voiceRuntime) == 'native'
        ? _turnCeilingSeconds
        : _settings.get(defs.wakeWordResumeTimeoutSeconds).toInt();
    if (timeout <= 0) return;
    _resumeTimer = Timer(Duration(seconds: timeout), () async {
      if (_active) return;
      final waited = (deferred + 1) * timeout;
      if (_turnStreamOpen && waited < _turnCeilingSeconds) {
        log.debug(
          name,
          'turn still streaming audio after ${waited}s; self-heal waits',
        );
        _armResumeTimer(deferred: deferred + 1);
        return;
      }
      log.warn(
        name,
        _turnStreamOpen
            ? 'turn still streaming audio after ${waited}s with the page '
                  'silent; self-healing'
            : 'page never resumed listening; self-healing',
      );
      // A stream left open by a page that is gone keeps every mic chunk
      // flowing (base64 to a listener that no longer exists on the page
      // path, into the pipeline buffer on the native one). Close it.
      _pageAudioActive = false;
      _nativeAudioSink = null;
      await _engine.stopAudioStream();
      setActive(true);
    });
  }

  /// Start the playback watch for a freshly started engine, or stop it when
  /// the config has no playback thresholds (Amazon's engine, or a config
  /// Voice Satellite's page pushed).
  void _watchPlayback() {
    final config = _config;
    final boosts =
        config != null &&
        config.models.any(
          (m) => m.playbackConfidenceScale != null || m.playbackCutoff != null,
        );
    // A new engine starts at its normal thresholds: playback has to be
    // seen again before they move.
    _playback.stop();
    if (boosts) _playback.start();
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _playback.stop();
    await _backgroundInteractionSub?.cancel();
    _cancelBackgroundReturn();
    await _remoteObservers?.cancel();
    _stopMicLevelWatch();
    _resumeTimer?.cancel();
    _micRetry?.cancel();
    await arbiter?.stop();
    await _engine.stop();
    diagnostics.dispose();
  }
}

/// PCM16 payload of a 16 kHz mono WAV, or null when it is anything else.
Uint8List? _wavPcm16k(Uint8List wav) {
  if (wav.length < 12) return null;
  final bd = ByteData.sublistView(wav);
  if (String.fromCharCodes(wav.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(wav.sublist(8, 12)) != 'WAVE') {
    return null;
  }
  var off = 12;
  var ok = false;
  while (off + 8 <= wav.length) {
    final id = String.fromCharCodes(wav.sublist(off, off + 4));
    final size = bd.getUint32(off + 4, Endian.little);
    final body = off + 8;
    if (id == 'fmt ' && body + 16 <= wav.length) {
      final format = bd.getUint16(body, Endian.little);
      final channels = bd.getUint16(body + 2, Endian.little);
      final rate = bd.getUint32(body + 4, Endian.little);
      final bits = bd.getUint16(body + 14, Endian.little);
      ok = format == 1 && channels == 1 && rate == 16000 && bits == 16;
    } else if (id == 'data') {
      if (!ok) return null;
      final end = body + size > wav.length ? wav.length : body + size;
      return Uint8List.sublistView(wav, body, end & ~1);
    }
    off = body + size + (size & 1);
  }
  return null;
}

/// [ms] of uniform noise at [rms] (full scale 1.0), deterministic per [seed].
Uint8List _noisePcm(int ms, double rms, {int seed = 1}) {
  final samples = ms * 16;
  final out = Int16List(samples);
  // Uniform on [-a, a] has rms a / sqrt(3).
  final a = (rms * 1.7320508 * 32767).clamp(0, 32767).toDouble();
  var state = 0x9E3779B9 ^ seed;
  for (var i = 0; i < samples; i++) {
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    final u = state / 0x7fffffff; // [0, 1)
    out[i] = ((u * 2 - 1) * a).round();
  }
  return Uint8List.view(out.buffer);
}
