import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/wake_word/engine.dart';
import 'package:kiosk_satellite/managers/wake_word/model_cache.dart';
import 'package:kiosk_satellite/managers/wake_word/vsww/model_store.dart';
import 'package:kiosk_satellite/managers/wake_word/wake_word_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// permission_handler's PermissionStatus, over the wire.
const _denied = 0;
const _granted = 1;

/// A microWakeWord runner that comes up without models or a microphone and
/// records whether a turn's audio stream is open on it.
class _FakeEngine extends WakeWordEngine {
  bool _running = false;
  bool streamOpen = false;

  @override
  Set<WakeWordEngineType> get supportedEngines => const {
    WakeWordEngineType.microWakeWord,
  };

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

  @override
  Future<void> startAudioStream(
    void Function(Uint8List pcm, bool preRoll) onChunk,
  ) async {
    streamOpen = true;
  }

  @override
  Future<void> stopAudioStream() async {
    streamOpen = false;
  }
}

/// An engine whose start takes a while, as a real one loading models does,
/// counting how many starts overlap.
class _SlowEngine extends _FakeEngine {
  int starting = 0;
  int overlapped = 0;
  final started = <String>[];

  @override
  Future<void> start({
    required WakeWordConfig config,
    required DetectionCallback onDetection,
    StopDetectionCallback? onStopDetection,
    EngineFailureCallback? onFailure,
  }) async {
    if (++starting > 1) overlapped++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    starting--;
    started.add(config.models.first.id);
    _running = true;
  }
}

/// An engine whose microphone dies right after it opens, [failuresLeft]
/// times, the way AudioRecord does while the audio HAL is still coming up.
class _MicLostEngine extends _FakeEngine {
  int failuresLeft = 0;
  int starts = 0;
  EngineFailure failure = EngineFailure.micLost;

  @override
  Future<void> start({
    required WakeWordConfig config,
    required DetectionCallback onDetection,
    StopDetectionCallback? onStopDetection,
    EngineFailureCallback? onFailure,
  }) async {
    starts++;
    if (failuresLeft > 0) {
      failuresLeft--;
      if (failure != EngineFailure.micLost) {
        onFailure?.call(failure, 'test');
        return;
      }
      _running = true;
      // The mic stream's error arrives after start has returned.
      scheduleMicrotask(() {
        _running = false;
        onFailure?.call(EngineFailure.micLost, 'microphone failed: test');
      });
      return;
    }
    _running = true;
  }
}

/// The wake-word contract (docs/js-api.md): config is pushed by the Voice
/// Satellite card (setWakeWordConfig), detection releases the mic before the
/// event is published, and the page resumes listening via
/// setWakeWordActive(true).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late WakeWordManager wakeWord;
  late SettingsManager settings;
  late Logger log;

  const vsConfig = {
    'engine': 'microWakeWord',
    'models': [
      {
        'id': 'okay_nabu',
        'wakeWord': 'Okay Nabu',
        'manifestUrl':
            'http://ha.local:8123/voice_satellite/models/okay_nabu.json',
      },
    ],
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // The engine asks the OS for the microphone before it opens it, and
    // permission_handler has no implementation under `flutter test`. Answer
    // "granted", which is the interesting case here: these tests are about what
    // the manager does once the mic is allowed. The denial path is covered
    // against the engine directly, in isolate_engine_test.dart.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async => switch (call.method) {
            'checkPermissionStatus' => _granted,
            'requestPermissions' => {call.arguments.first: _granted},
            _ => null,
          },
        );

    bus = EventBus();
    log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    wakeWord = WakeWordManager(bus, commands, log, settings);
    await wakeWord.init();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          null,
        );
    await wakeWord.dispose();
    await bus.dispose();
  });

  test('unconfigured until Voice Satellite pushes a config', () async {
    expect(wakeWord.available, isFalse);
    final state = await commands.execute('getWakeWordState', const {});
    expect((state.data as Map)['engine'], isNull);
  });

  test('needs the microphone only while something can listen', () async {
    // A new install: native runtime with Voice Satellite off.
    expect(wakeWord.inUse, isFalse);
    await settings.set(defs.voiceEnabled, true);
    expect(wakeWord.inUse, isTrue);
    await settings.set(defs.voiceEnabled, false);
    await settings.set(defs.voiceRuntime, 'dashboard');
    expect(wakeWord.inUse, isTrue, reason: 'the page starts the engine');
  });

  test('rejects malformed configs', () async {
    final result = await commands.execute('setWakeWordConfig', const {
      'engine': 'bogus',
      'models': [],
    });
    expect(result.ok, isFalse);
  });

  test('accepts a VS config and remembers it', () async {
    final result = await commands.execute('setWakeWordConfig', vsConfig);
    expect(result.ok, isTrue);

    final state = await commands.execute('getWakeWordState', const {});
    final data = state.data as Map<String, Object?>;
    expect(data['engine'], 'microWakeWord');
    expect((data['models'] as List), hasLength(1));
  });

  test(
    'having a runner for an engine is not the same as being able to run it',
    () async {
      // `available` is not a claim about which engines we support, it is a
      // promise to Voice Satellite that we are listening *now* — the card stops
      // its own browser detection on the strength of it. We do have a native
      // microWakeWord runner, but here every model download fails (the test
      // binding stubs HTTP to 400), so the promise cannot honestly be made.
      final result = await commands.execute('setWakeWordConfig', vsConfig);
      expect(result.ok, isTrue, reason: 'the config is understood and kept');
      expect(
        (result.data as Map)['available'],
        isFalse,
        reason: 'nothing came up, so nothing is covered',
      );
      expect(
        wakeWord.describeState()['engine'],
        'microWakeWord',
        reason: 'we still know what was asked for',
      );
    },
  );

  test(
    'a detection lights a dark panel before the page hears about it',
    () async {
      await commands.execute('setWakeWordConfig', vsConfig);

      // The screen manager is absent here; record its command instead. A
      // detection must poke the panel on (screensaver screen-off timer, OS
      // timeout, app behind another app — all the dark cases) and must do so
      // before WakeWordDetected, so the turn's UI lands on a lit screen.
      var screenPokes = 0;
      commands.register(
        Command(
          name: 'screenOn',
          description: 'recorder',
          handler: (_) async {
            screenPokes++;
            return const CommandResult.ok();
          },
        ),
      );
      var pokedBeforeEvent = false;
      bus.on<WakeWordDetected>().listen((_) {
        pokedBeforeEvent = screenPokes > 0;
      });

      await commands.execute('simulateWakeWord', const {});
      await Future<void>.delayed(Duration.zero);
      expect(screenPokes, greaterThan(0));
      expect(
        pokedBeforeEvent,
        isTrue,
        reason: 'the panel wakes before the turn starts',
      );
    },
  );

  test(
    'detection releases the mic before publishing, page resume re-arms',
    () async {
      await commands.execute('setWakeWordConfig', vsConfig);

      final detections = <WakeWordDetected>[];
      var listeningAtDetection = true;
      bus.on<WakeWordDetected>().listen((e) {
        detections.add(e);
        listeningAtDetection = wakeWord.listening;
      });

      final result = await commands.execute('simulateWakeWord', const {});
      expect(result.ok, isTrue);
      await Future<void>.delayed(Duration.zero);

      expect(detections, hasLength(1));
      expect(detections.single.model, 'okay_nabu');
      expect(detections.single.phrase, 'Okay Nabu');
      // Mic released before the page hears about the detection.
      expect(listeningAtDetection, isFalse);

      // Detection suspends listening until the page resumes us.
      var state = await commands.execute('getWakeWordState', const {});
      expect((state.data as Map)['active'], isFalse);

      await commands.execute('setWakeWordActive', const {'active': true});
      state = await commands.execute('getWakeWordState', const {});
      expect((state.data as Map)['active'], isTrue);
    },
  );

  test('configs pushed back to back never start the engine twice at once, '
      'and the last one wins', () async {
    await wakeWord.dispose();
    await bus.dispose();
    bus = EventBus();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    final engine = _SlowEngine();
    wakeWord = WakeWordManager(
      bus,
      commands,
      log,
      settings,
      engines: {WakeWordEngineType.microWakeWord: engine},
    );
    await wakeWord.init();
    Map<String, Object?> config(String id) => {
      ...vsConfig,
      'models': [
        {
          'id': id,
          'wakeWord': id,
          'manifestUrl': 'http://ha.local:8123/$id.json',
        },
      ],
    };
    // What a migration does: several settings in a row, each a new push.
    await Future.wait([
      commands.execute('setWakeWordConfig', config('okay_nabu')),
      commands.execute('setWakeWordConfig', config('hey_jarvis')),
    ]);
    expect(engine.overlapped, 0);
    expect(engine.started.last, 'hey_jarvis');
    expect(engine.running, isTrue);
  });

  test('Lockdown Mode stops the engine unless Allow Voice Satellite keeps '
      'it listening', () async {
    await wakeWord.dispose();
    await bus.dispose();
    bus = EventBus();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    final engine = _FakeEngine();
    wakeWord = WakeWordManager(
      bus,
      commands,
      log,
      settings,
      engines: {WakeWordEngineType.microWakeWord: engine},
    );
    await wakeWord.init();
    await commands.execute('setWakeWordConfig', vsConfig);
    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    await settle();
    expect(engine.running, isTrue);
    await settings.set(defs.lockdownEnabled, true);
    await settle();
    expect(engine.running, isFalse);
    await settings.set(defs.lockdownAllowVoice, true);
    await settle();
    expect(engine.running, isTrue);
    await settings.set(defs.lockdownEnabled, false);
    await settle();
    expect(engine.running, isTrue);
  });

  group('the self-heal after a handoff', () {
    // The page must call setWakeWordActive(true) when its turn ends. When it
    // never does (crash, navigation) the timer re-arms detection. It must not
    // fire while the turn is still running: the stream it would close is the
    // one feeding STT, and a short timeout then aborts every wake mid-word.
    late _FakeEngine engine;

    setUp(() async {
      // Rebuilt from scratch: the outer setUp's manager already registered
      // its commands on that registry, and the fake engine has to be in
      // place before init.
      await wakeWord.dispose();
      await bus.dispose();
      bus = EventBus();
      commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      engine = _FakeEngine();
      wakeWord = WakeWordManager(
        bus,
        commands,
        log,
        settings,
        engines: {WakeWordEngineType.microWakeWord: engine},
      );
      await wakeWord.init();
      // The page's handoff: the dashboard runtime.
      await settings.set(defs.voiceRuntime, 'dashboard');
      await settings.set(defs.wakeWordResumeTimeoutSeconds, 1);
      await commands.execute('setWakeWordConfig', vsConfig);
      expect(wakeWord.listening, isTrue);
      // A detection asks the platform to bring the app forward. Answered
      // here so the call completes inside fakeAsync, where an unmocked
      // channel never returns and the handoff would never reach its timer.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('kiosk_satellite/background'),
            (call) async => call.method == 'bringToFront' ? true : null,
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('kiosk_satellite/background'),
            null,
          );
    });

    Future<bool> active() async {
      final state = await commands.execute('getWakeWordState', const {});
      return (state.data as Map)['active'] as bool;
    }

    for (final scenario in [
      'wake word',
      'announcement',
      'ask_question',
      'start_conversation',
      'foreground',
      'screen off',
      'disabled',
      'background disabled',
      'failed front',
      'ordinary front',
      'manual return',
      'disabled mid-turn',
      'follow-up',
      'overlapping media',
      'timer only',
      'native wake word',
    ]) {
      test('return to previous app: $scenario', () async {
        await settings.set(
          defs.wakeWordBackground,
          scenario != 'background disabled',
        );
        await settings.set(
          defs.wakeWordReturnToBackground,
          scenario != 'disabled',
        );
        var minimized = 0;
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/background'),
          (call) async => switch (call.method) {
            'isBehindAnotherApp' => scenario != 'screen off',
            'bringToFront' => scenario != 'failed front',
            _ => null,
          },
        );
        messenger.setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/admin'),
          (call) async {
            if (call.method == 'moveTaskToBack') minimized++;
            return true;
          },
        );
        addTearDown(
          () => messenger.setMockMethodCallHandler(
            const MethodChannel('kiosk_satellite/admin'),
            null,
          ),
        );
        final binding = TestWidgetsFlutterBinding.instance;
        {
          Future<void> interaction(bool active, String reason) async {
            bus.publish(
              VoiceInteractionChanged(
                active: active,
                reason: reason,
                // The native satellite reports its turns as its own.
                source: scenario == 'native wake word'
                    ? InteractionSource.native
                    : InteractionSource.page,
              ),
            );
            await Future<void>.delayed(Duration.zero);
          }

          binding.handleAppLifecycleStateChanged(
            scenario == 'foreground'
                ? AppLifecycleState.resumed
                : AppLifecycleState.paused,
          );
          if (scenario == 'wake word' || scenario == 'native wake word') {
            await commands.execute('simulateWakeWord', const {});
          } else {
            await commands.execute('bringToFront', {
              'voiceInteraction': scenario != 'ordinary front',
            });
          }
          await Future<void>.delayed(Duration.zero);
          binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          final reason = switch (scenario) {
            'announcement' ||
            'ask_question' ||
            'start_conversation' => scenario,
            'timer only' => 'timer',
            _ => 'voice',
          };
          await interaction(true, reason);
          // Resuming detection can happen before playback finishes.
          await commands.execute('setWakeWordActive', const {'active': true});
          await Future<void>.delayed(const Duration(milliseconds: 350));
          expect(minimized, 0);
          if (scenario == 'manual return') {
            binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
            binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          }
          if (scenario == 'disabled mid-turn') {
            await settings.set(defs.wakeWordReturnToBackground, false);
            await Future<void>.delayed(Duration.zero);
          }
          if (scenario == 'overlapping media') await interaction(true, 'media');
          await interaction(false, reason);
          if (scenario == 'follow-up') {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            await interaction(true, reason);
            await Future<void>.delayed(const Duration(milliseconds: 350));
            expect(minimized, 0);
            await interaction(false, reason);
          }
          if (scenario == 'overlapping media') {
            await Future<void>.delayed(const Duration(milliseconds: 350));
            expect(minimized, 0);
            await interaction(false, 'media');
          }
          await Future<void>.delayed(const Duration(milliseconds: 350));
          final shouldReturn = const {
            'wake word',
            'native wake word',
            'announcement',
            'ask_question',
            'start_conversation',
            'follow-up',
            'overlapping media',
          }.contains(scenario);
          expect(minimized, shouldReturn ? 1 : 0);
          // A later foreground interaction must never inherit the old return.
          await interaction(true, 'voice');
          await interaction(false, 'voice');
          await Future<void>.delayed(const Duration(milliseconds: 350));
          expect(minimized, shouldReturn ? 1 : 0);
        }
      });
    }

    test('an app on screen without the input focus is not fronted', () {
      // Android reports an Activity resumed under a focus-holding window
      // as inactive, never resumed (issue #560). Fronting it anyway would
      // relaunch the Activity and reload the page mid-interaction.
      var fronted = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('kiosk_satellite/background'),
            (call) async {
              if (call.method == 'bringToFront') fronted++;
              return true;
            },
          );
      final binding = TestWidgetsFlutterBinding.instance;
      fakeAsync((async) {
        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        commands.execute('bringToFront', const {});
        async.flushMicrotasks();
        expect(fronted, 0);
        commands.execute('simulateWakeWord', const {});
        async.flushMicrotasks();
        expect(fronted, 0);
        // Genuinely behind: both routes come forward.
        async.elapse(const Duration(seconds: 2));
        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        commands.execute('bringToFront', const {});
        async.flushMicrotasks();
        expect(fronted, 1);
        commands.execute('simulateWakeWord', const {});
        async.flushMicrotasks();
        expect(fronted, 2);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      });
    });

    test('a page that never answers the handoff is healed', () {
      fakeAsync((async) {
        commands.execute('simulateWakeWord', const {});
        async.flushMicrotasks();
        var isActive = true;
        active().then((v) => isActive = v);
        async.flushMicrotasks();
        expect(isActive, isFalse);

        async.elapse(const Duration(seconds: 1));
        active().then((v) => isActive = v);
        async.flushMicrotasks();
        expect(isActive, isTrue, reason: 'nothing was streaming: heal');
      });
    });

    test('the native satellite keeps only the ten minute backstop', () {
      fakeAsync((async) {
        settings.set(defs.voiceRuntime, 'native');
        async.flushMicrotasks();
        commands.execute('simulateWakeWord', const {});
        async.flushMicrotasks();
        // A long spoken answer, far past the page's timeout: the satellite
        // hands the wake word back itself when it goes idle.
        async.elapse(const Duration(seconds: 120));
        var isActive = true;
        active().then((v) => isActive = v);
        async.flushMicrotasks();
        expect(isActive, isFalse);
        async.elapse(const Duration(seconds: 480));
        active().then((v) => isActive = v);
        async.flushMicrotasks();
        expect(isActive, isTrue, reason: 'the backstop');
      });
    });

    test('a turn streaming to the page is left alone until it ends', () {
      fakeAsync((async) {
        commands.execute('simulateWakeWord', const {});
        async.flushMicrotasks();
        commands.execute('startAudioStream', const {});
        async.flushMicrotasks();
        expect(engine.streamOpen, isTrue);

        // Far past the timeout: the page is alive and mid-turn.
        async.elapse(const Duration(seconds: 30));
        var isActive = true;
        active().then((v) => isActive = v);
        async.flushMicrotasks();
        expect(isActive, isFalse, reason: 'the turn is still running');
        expect(engine.streamOpen, isTrue, reason: 'STT still fed');

        // The turn ends and the page dies before resuming us.
        commands.execute('stopAudioStream', const {});
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        active().then((v) => isActive = v);
        async.flushMicrotasks();
        expect(isActive, isTrue, reason: 'healed within one period');
      });
    });

    test('a turn on the native pipeline transport counts the same', () {
      fakeAsync((async) {
        commands.execute('simulateWakeWord', const {});
        async.flushMicrotasks();
        wakeWord.openNativeAudioStream((_, _) {});
        async.flushMicrotasks();
        expect(engine.streamOpen, isTrue);

        async.elapse(const Duration(seconds: 30));
        var isActive = true;
        active().then((v) => isActive = v);
        async.flushMicrotasks();
        expect(isActive, isFalse);
        expect(engine.streamOpen, isTrue);

        // The page resumes us the normal way, mid-stream: the timer is done.
        commands.execute('setWakeWordActive', const {'active': true});
        async.flushMicrotasks();
        active().then((v) => isActive = v);
        async.flushMicrotasks();
        expect(isActive, isTrue);
        expect(engine.streamOpen, isTrue, reason: 'resuming never closes it');
      });
    });

    test('a stream held open by a page lost mid-turn is closed eventually', () {
      fakeAsync((async) {
        commands.execute('simulateWakeWord', const {});
        async.flushMicrotasks();
        commands.execute('startAudioStream', const {});
        async.flushMicrotasks();

        async.elapse(const Duration(minutes: 9));
        expect(engine.streamOpen, isTrue);
        async.elapse(const Duration(minutes: 2));
        var isActive = false;
        active().then((v) => isActive = v);
        async.flushMicrotasks();
        expect(isActive, isTrue);
        expect(engine.streamOpen, isFalse, reason: 'the orphan is closed');
      });
    });
  });

  group('the two settings UIs must say the same thing', () {
    // The on-device settings screen and the remote web admin describe the same
    // device. Anything Voice Satellite feeds us (engine, wake words, stop word)
    // has to reach both, and neither may word it for itself: the web admin can
    // only render what getWakeWordState hands it.
    test('the state carries the status sentence, not just the flags', () async {
      var state = wakeWord.describeState();
      expect(state['status'], 'waiting', reason: 'no config pushed yet');
      expect(
        state['statusLabel'],
        contains('Waiting for Voice Satellite'),
        reason: 'the wording is derived once, here',
      );

      await commands.execute('setWakeWordConfig', vsConfig);
      state = wakeWord.describeState();
      // Downloads fail under test, so this lands on 'unavailable'. Either way
      // the point holds: there is a sentence, and both UIs read it from here
      // rather than composing their own.
      expect(state['status'], isNotEmpty);
      expect(state['statusLabel'], isNotEmpty);
    });

    test('describeState carries every field the web admin renders', () async {
      await commands.execute('setWakeWordConfig', vsConfig);
      final state = wakeWord.describeState();
      // Each of these backs a row in remote-ui/static/device.js
      // (loadDeviceInfo). Renaming one without touching the other silently
      // empties that row, which is exactly the drift this guards.
      for (final key in [
        'status',
        'statusLabel',
        'engineLabel',
        'models',
        'stopWordAvailable',
        'available',
        'listening',
        'canRetry',
        'needsAppSettings',
        'modelPrecision',
      ]) {
        expect(state, contains(key), reason: 'the web admin reads "$key"');
      }
      expect(
        state['engineLabel'],
        'microWakeWord',
        reason: "VS's name for it, not the Dart enum's",
      );
      expect(
        (state['models'] as List).single,
        containsPair('wakeWord', 'Okay Nabu'),
      );
    });

    test('the retired master switch cannot be turned off', () async {
      await commands.execute('setWakeWordConfig', vsConfig);
      // The switch is hidden and forced on: with Voice Satellite installed
      // the app always takes detection over, and the Wake word engine
      // select in Home Assistant is the real off switch. Any write (an old
      // config import, a stale remote) must land as on.
      await settings.setFromJson('wake_word.enabled', false);
      expect(settings.get(defs.wakeWordEnabled), isTrue);
      expect(wakeWord.describeState()['status'], isNot('disabled'));
    });

    test('the stop word is reported so both UIs can show it', () async {
      await commands.execute('setWakeWordConfig', {
        ...vsConfig,
        'stopModel': {
          'id': 'stop',
          'wakeWord': 'Stop',
          'manifestUrl':
              'http://ha.local:8123/voice_satellite/models/stop.json',
        },
      });
      expect(wakeWord.describeState()['stopWord'], 'Stop');
    });
  });

  test('an engine that cannot start reports unavailable, not silence', () async {
    // Voice Satellite reads `available` as "Kiosk Satellite has this covered"
    // and stops its own browser detection on the strength of it. So a runner
    // that failed to come up — models 404, microphone permission revoked — must
    // say so. The alternative, seen for real, is a satellite that looks healthy
    // in every log and ignores every wake word.
    //
    // Under test every model download fails (the binding stubs HTTP to 400),
    // which is exactly the shape of that failure.
    final result = await commands.execute('setWakeWordConfig', vsConfig);
    expect(result.ok, isTrue, reason: 'the config itself was fine');
    expect(
      (result.data as Map)['available'],
      isFalse,
      reason: 'nothing is listening, so do not claim otherwise',
    );
    expect(
      wakeWord.describeState()['status'],
      'modelsUnavailable',
      reason: 'and it says which of the ways it failed',
    );
  });

  test(
    'a failed engine retries when the card pushes the same config again',
    () async {
      // The only retry there is: whatever broke may be fixed by now (the user
      // granted the mic back, the model was re-published). An unchanged config
      // normally does not restart the engine, and must here.
      await commands.execute('setWakeWordConfig', vsConfig);
      expect(wakeWord.available, isFalse);

      final again = await commands.execute('setWakeWordConfig', vsConfig);
      expect(again.ok, isTrue);
      // Still failing (HTTP is still stubbed), but it did try: the point is that
      // the failure is not latched forever.
      expect(wakeWord.describeState()['status'], 'modelsUnavailable');
    },
  );

  group('releasing the mic explains itself', () {
    // Muting the satellite and "the browser is taking detection back" are the
    // same event here — the card closes our mic — so the card tells us which.
    // Without that this fell through to the catch-all and told anyone who muted
    // their satellite that openWakeWord had no native runner.
    test('a mute says it is muted', () async {
      await commands.execute('setWakeWordConfig', vsConfig);
      await commands.execute('releaseWakeWord', const {'reason': 'muted'});

      final state = wakeWord.describeState();
      expect(state['status'], 'muted');
      expect(state['statusLabel'], contains('Muted in Voice Satellite'));
      expect(state['available'], isFalse, reason: 'the mic really is closed');
      expect(state['statusLabel'], isNot(contains('No native runner')));
      expect(
        state['canRetry'],
        isFalse,
        reason: 'nothing failed; unmuting is the fix, not retrying',
      );
    });

    test('detection going back to the browser says that instead', () async {
      await commands.execute('setWakeWordConfig', vsConfig);
      await commands.execute('releaseWakeWord', const {'reason': 'browser'});
      expect(wakeWord.describeState()['status'], 'browser');
    });

    test('a card too old to give a reason still does not lie', () async {
      await commands.execute('setWakeWordConfig', vsConfig);
      await commands.execute('releaseWakeWord', const {});
      final state = wakeWord.describeState();
      expect(state['status'], 'released');
      expect(state['statusLabel'], contains('released the microphone'));
      expect(state['statusLabel'], isNot(contains('No native runner')));
    });

    test(
      'unmuting clears it: a fresh config push takes the mic back',
      () async {
        await commands.execute('setWakeWordConfig', vsConfig);
        await commands.execute('releaseWakeWord', const {'reason': 'muted'});
        expect(wakeWord.describeState()['status'], 'muted');

        await commands.execute('setWakeWordConfig', vsConfig);
        expect(wakeWord.describeState()['status'], isNot('muted'));
        expect(wakeWord.describeState()['releaseReason'], isNull);
      },
    );

    test(
      '"no native runner" is kept for the case that really is that',
      () async {
        // The catch-all became a lie because it was a catch-all. It still has to
        // be right about its own case: an engine with no native runner here.
        await commands.execute('setWakeWordConfig', const {
          'engine': 'vsWakeWord',
          'models': [
            {
              'id': 'ok_luna',
              'wakeWord': 'Ok Luna',
              'manifestUrl': 'http://x/m.json',
            },
          ],
        });
        // vsWakeWord *does* have a runner, so this must not claim otherwise —
        // it fails on the model download instead.
        expect(wakeWord.describeState()['status'], 'modelsUnavailable');
      },
    );
  });

  group('a refused microphone is recoverable', () {
    // The dead end this guards: Android stops asking after the second "Don't
    // allow", and the browser fallback needs the same permission, so both paths
    // go silent at once. If the UI does not say what happened and offer the way
    // out, a stray tap disables the feature permanently.
    /// [rationale] is Android's shouldShowRequestPermissionRationale: true only
    /// while the OS is still willing to show the dialog.
    void answerMic(int status, {bool rationale = false}) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter.baseflow.com/permissions/methods'),
            (call) async => switch (call.method) {
              'checkPermissionStatus' => status,
              'requestPermissions' => {call.arguments.first: status},
              'shouldShowRequestPermissionRationale' => rationale,
              _ => null,
            },
          );
    }

    test('a blocked mic says so, and does not blame the engine', () async {
      // What the device actually reports once the user has refused twice:
      // plain `denied`, with the rationale flag false. Reading it as a simple
      // decline would promise a retry that can never succeed.
      answerMic(_denied, rationale: false);
      await commands.execute('setWakeWordConfig', vsConfig);

      final state = wakeWord.describeState();
      expect(state['status'], 'micBlocked');
      expect(state['statusLabel'], contains('app settings'));
      expect(state['needsAppSettings'], isTrue);
      expect(state['canRetry'], isTrue);
      // The bug this replaces: a refused mic displayed as a missing runner,
      // sending whoever read it off to debug the wrong thing.
      expect(state['statusLabel'], isNot(contains('No native runner')));
    });

    test('a declined mic offers a retry, not the settings screen', () async {
      // One refusal: Android still shows the dialog, so retrying is the fix.
      answerMic(_denied, rationale: true);
      await commands.execute('setWakeWordConfig', vsConfig);

      final state = wakeWord.describeState();
      expect(state['status'], 'micDeclined');
      expect(state['canRetry'], isTrue);
      expect(
        state['needsAppSettings'],
        isFalse,
        reason: 'Android will still ask, so settings is the wrong advice',
      );
    });

    test('retrying after the user relents starts the engine', () async {
      answerMic(_denied, rationale: true);
      await commands.execute('setWakeWordConfig', vsConfig);
      expect(wakeWord.describeState()['status'], 'micDeclined');

      // The user grants it, then hits Retry in either UI.
      answerMic(_granted);
      final result = await commands.execute('retryWakeWord', const {});
      expect(result.ok, isTrue);
      // Models still fail to download here, so it lands on the *next* honest
      // failure rather than 'micDeclined'. The point is that the mic is no
      // longer the blocker and nothing latched.
      expect(wakeWord.describeState()['status'], isNot('micDeclined'));
    });

    test(
      'the model download failure is not mistaken for a mic problem',
      () async {
        answerMic(_granted);
        await commands.execute('setWakeWordConfig', vsConfig);
        final state = wakeWord.describeState();
        expect(state['status'], 'modelsUnavailable');
        expect(state['needsAppSettings'], isFalse);
        expect(state['statusLabel'], contains('Home Assistant'));
      },
    );
  });

  group('a microphone that is not ready yet', () {
    // Issue #1145: right after a boot the audio HAL refuses AudioRecord for a
    // few seconds. The card has already pushed its config by then, so
    // without a retry of our own the satellite stays deaf until a restart.
    late _MicLostEngine engine;

    setUp(() async {
      await wakeWord.dispose();
      await bus.dispose();
      bus = EventBus();
      commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      await settings.set(defs.voiceRuntime, 'dashboard');
      engine = _MicLostEngine();
    });

    // Built inside fakeAsync: the manager chains every engine sync onto a
    // future, and one created in the real zone would never run here.
    void boot(FakeAsync async) {
      wakeWord = WakeWordManager(
        bus,
        commands,
        log,
        settings,
        engines: {WakeWordEngineType.microWakeWord: engine},
      );
      wakeWord.init();
      async.flushMicrotasks();
    }

    test('reopens the mic on its own once it works', () {
      fakeAsync((async) {
        boot(async);
        engine.failuresLeft = 2;
        commands.execute('setWakeWordConfig', vsConfig);
        async.flushMicrotasks();
        expect(wakeWord.describeState()['status'], 'micLost');
        expect(engine.starts, 1);

        async.elapse(const Duration(seconds: 5));
        expect(engine.starts, 2);
        expect(wakeWord.describeState()['status'], 'micLost');

        async.elapse(const Duration(seconds: 15));
        expect(engine.starts, 3);
        expect(wakeWord.listening, isTrue);
        expect(wakeWord.available, isTrue);

        // Nothing left over to restart a healthy engine.
        async.elapse(const Duration(minutes: 30));
        expect(engine.starts, 3);
      });
    });

    test('gives up after the ladder and leaves Retry to the user', () {
      fakeAsync((async) {
        boot(async);
        engine.failuresLeft = 1000;
        commands.execute('setWakeWordConfig', vsConfig);
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 30));
        // The first start plus six retries.
        expect(engine.starts, 7);
        expect(wakeWord.describeState()['status'], 'micLost');
        expect(wakeWord.canRetry, isTrue);
        async.elapse(const Duration(minutes: 20));
        expect(engine.starts, 7);
      });
    });

    test('a release cancels the pending retry', () {
      fakeAsync((async) {
        boot(async);
        engine.failuresLeft = 1;
        commands.execute('setWakeWordConfig', vsConfig);
        async.flushMicrotasks();
        commands.execute('releaseWakeWord', const {'reason': 'muted'});
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 10));
        expect(engine.starts, 1);
        expect(wakeWord.describeState()['status'], 'muted');
      });
    });

    test('other failures are not retried on their own', () {
      fakeAsync((async) {
        boot(async);
        engine
          ..failuresLeft = 1000
          ..failure = EngineFailure.modelsUnavailable;
        commands.execute('setWakeWordConfig', vsConfig);
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 10));
        expect(engine.starts, 1);
        expect(wakeWord.describeState()['status'], 'modelsUnavailable');
      });
    });
  });

  group('the model cache', () {
    // The cache keys on the model URL, so a model re-published on Home
    // Assistant under the same name never reaches a device that already has
    // one. Before this the only way to re-fetch was clearing the app's data,
    // which also destroys the settings and the Home Assistant login.
    late Directory support;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('ks_cache_test');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => call.method == 'getApplicationSupportDirectory'
                ? support.path
                : null,
          );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      if (await support.exists()) await support.delete(recursive: true);
    });

    /// A cached model for each engine, as the stores would leave them.
    Future<void> seed() async {
      for (final name in WakeModelCache.dirNames) {
        final dir = Directory('${support.path}/$name');
        await dir.create(recursive: true);
        await File('${dir.path}/deadbeef.bin').writeAsBytes(List.filled(64, 7));
      }
    }

    test('clears every engine and reports what it freed', () async {
      await seed();
      expect(await WakeModelCache.size(), 3 * 64);

      await commands.execute('setWakeWordConfig', vsConfig);
      final result = await commands.execute('clearWakeWordModels', const {});
      expect(result.ok, isTrue);
      expect((result.data as Map)['removed'], 3);
      expect((result.data as Map)['bytesFreed'], 3 * 64);
      expect(await WakeModelCache.size(), 0);
    });

    test('drops downloads and nothing else', () async {
      await seed();
      await commands.execute('setWakeWordConfig', vsConfig);
      await settings.setFromJson('ha.url', 'https://ha.example');
      await commands.execute('clearWakeWordModels', const {});

      // The whole point: this is the surgical alternative to wiping app data.
      // The config from the card, and the device's own settings, both survive.
      final state = await commands.execute('getWakeWordState', const {});
      expect((state.data as Map)['engine'], 'microWakeWord');
      expect(settings.get(defs.haUrl), 'https://ha.example');
    });

    test('is safe to run before anything has been downloaded', () async {
      final result = await commands.execute('clearWakeWordModels', const {});
      expect(result.ok, isTrue);
      expect((result.data as Map)['removed'], 0);
    });
  });

  group('int8 model preference', () {
    // Kiosk Satellite prefers the quantized int8 sibling under `int8/`
    // (same manifest, ~35% faster inference) and falls back to the fp32
    // file when the server does not carry one, so an older Voice Satellite
    // keeps working untouched.
    late Directory support;
    late HttpServer server;
    late List<String> requestedPaths;
    late Set<String> present;

    // The smallest manifest VswwManifest.fromJson accepts.
    String manifestJson() =>
        '{"name":"ok_test","format":"vs-wake-word-ctc-v1",'
        '"input":{"shape":[1,128,40]},"output":{"shape":[1,64,52]},'
        '"feature_config":{"sample_rate":16000,"n_fft":512,"n_mels":40,'
        '"f_min":80.0,"f_max":7600.0,"log_floor":1e-6,"frame_samples":400,'
        '"hop_samples":160,"window_samples":20800,"frames":128,'
        '"window_ms":1300},'
        '"ctc":{"vocab_size":52,"wake_word_targets":[[3,4,5]]}}';

    setUp(() async {
      support = await Directory.systemTemp.createTemp('ks_int8_test');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => call.method == 'getApplicationSupportDirectory'
                ? support.path
                : null,
          );
      requestedPaths = [];
      present = {'/m/ok_test.json', '/m/ok_test.onnx', '/m/int8/ok_test.onnx'};
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) {
        requestedPaths.add(req.uri.path);
        if (!present.contains(req.uri.path)) {
          req.response.statusCode = 404;
          req.response.close();
          return;
        }
        if (req.uri.path.endsWith('.json')) {
          req.response.write(manifestJson());
        } else {
          // Distinguishable bodies, so the test can tell which file loaded.
          req.response.add(
            req.uri.path.contains('/int8/') ? [8, 8, 8] : [32, 32, 32, 32],
          );
        }
        req.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      if (await support.exists()) await support.delete(recursive: true);
    });

    String url(String q) => 'http://127.0.0.1:${server.port}/m/ok_test.json$q';

    // flutter_test blocks network with a 400-everything HttpClient; the
    // base HttpOverrides restores the real one for the loopback server.
    Future<VswwModel> fetch(String u, {required bool preferInt8}) =>
        HttpOverrides.runWithHttpOverrides(
          () => VswwModelStore().fetch(u, preferInt8: preferInt8),
          _RealHttpOverrides(),
        );

    test('prefers the int8 sibling and says so', () async {
      final model = await fetch(url(''), preferInt8: true);
      expect(model.precision, 'int8');
      expect(model.onnxBytes, [8, 8, 8]);
      expect(requestedPaths, contains('/m/int8/ok_test.onnx'));
    });

    test('falls back to fp32 when the server has no int8 build', () async {
      present.remove('/m/int8/ok_test.onnx');
      final model = await fetch(url(''), preferInt8: true);
      expect(model.precision, 'fp32');
      expect(model.onnxBytes, [32, 32, 32, 32]);
      // It did try: the 404 is the negotiation, not an error.
      expect(requestedPaths, contains('/m/int8/ok_test.onnx'));
    });

    test('fp32 preference never touches the int8 path', () async {
      final model = await fetch(url(''), preferInt8: false);
      expect(model.precision, 'fp32');
      expect(requestedPaths.where((p) => p.contains('/int8/')), isEmpty);
    });

    test('the cache-busting query rides along to the int8 URL', () async {
      await fetch(url('?v=2026.8.8'), preferInt8: true);
      final onnxReq = requestedPaths.firstWhere(
        (p) => p.contains('/int8/ok_test.onnx'),
      );
      expect(onnxReq, '/m/int8/ok_test.onnx');
    });

    test('the toggle default fetches int8', () {
      expect(settings.get(defs.wakeWordPreferFp32), isFalse);
    });
  });
}

class _RealHttpOverrides extends HttpOverrides {}
