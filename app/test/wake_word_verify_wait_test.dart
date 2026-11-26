import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/wake_word/engine.dart';
import 'package:kiosk_satellite/managers/wake_word/wake_word_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An engine that fires when the test says and keeps a wake clip, as the
/// real ones do from the microphone.
class _Engine extends WakeWordEngine {
  bool _running = false;
  DetectionCallback? fire;
  Duration preRoll = Duration.zero;

  /// How long ago the wake word ended when the detection reaches the
  /// manager. The microphone goes on from there.
  Duration ended = Duration.zero;
  final _since = Stopwatch();

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
    fire = onDetection;
  }

  @override
  Future<void> stop() async => _running = false;

  @override
  set preRollExtra(Duration extra) => preRoll = extra;

  @override
  Duration? get sinceWake => _since.isRunning ? ended + _since.elapsed : null;

  @override
  Uint8List? wakeClip(Duration length) =>
      _since.isRunning ? Uint8List(length.inMilliseconds * 32) : null;

  Future<void> detect() async {
    _since
      ..reset()
      ..start();
    await fire!(
      const WakeWordModelRef(
        id: 'okay_nabu',
        wakeWord: 'Okay Nabu',
        manifestUrl: '',
      ),
    );
  }
}

/// Wait for wake word verification: Ground Control is asked about a wake
/// word before anything about the turn shows, and a wake word that wasn't
/// said starts nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late SettingsManager settings;
  late WakeWordManager wakeWord;
  late _Engine engine;
  late List<WakeWordDetected> detected;
  late List<Map<String, Object?>> asked;
  Object? answer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => switch (call.method) {
        'checkPermissionStatus' => 1,
        'requestPermissions' => {call.arguments.first: 1},
        _ => null,
      },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('kiosk_satellite/background'),
      (call) async => call.method == 'isBehindAnotherApp' ? false : null,
    );
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    asked = [];
    answer = null;
    // Ground Control's side, as GroundControlManager registers it.
    commands.register(
      Command(
        name: 'groundControlVerifyWakeWord',
        description: 'test',
        quiet: true,
        handler: (p) async {
          asked.add(p);
          return CommandResult.ok({'said': answer});
        },
      ),
    );
    engine = _Engine();
    wakeWord = WakeWordManager(
      bus,
      commands,
      log,
      settings,
      engines: {WakeWordEngineType.microWakeWord: engine},
    );
    await wakeWord.init();
    await settings.set(defs.voiceRuntime, 'native');
    await settings.set(defs.voiceEnabled, true);
    await settings.set(defs.groundControlEnabled, true);
    await settings.set(defs.voiceMatchEnabled, true);
    await commands.execute('setWakeWordConfig', const {
      'engine': 'microWakeWord',
      'models': [
        {
          'id': 'okay_nabu',
          'wakeWord': 'Okay Nabu',
          'manifestUrl': 'http://ha.local:8123/okay_nabu.json',
        },
      ],
    });
    detected = [];
    bus.on<WakeWordDetected>().listen(detected.add);
  });

  tearDown(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [
      'flutter.baseflow.com/permissions/methods',
      'kiosk_satellite/background',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), null);
    }
    await wakeWord.dispose();
    await bus.dispose();
  });

  Future<bool> active() async {
    final state = await commands.execute('getWakeWordState', const {});
    return (state.data as Map)['active'] as bool;
  }

  test('off unless the kiosk turned it on', () async {
    expect(defs.voiceMatchVerifierWait.defaultValue, isFalse);
    expect(engine.running, isTrue);
    await engine.detect();
    await Future<void>.delayed(Duration.zero);
    expect(asked, isEmpty);
    expect(detected, hasLength(1));
    expect(wakeWord.wakeVerified, isNull);
    expect(engine.preRoll, Duration.zero);
  });

  group('on', () {
    setUp(() => settings.set(defs.voiceMatchVerifierWait, true));

    test('a wake word that wasn\'t said starts nothing', () async {
      answer = false;
      final held = Stopwatch()..start();
      await engine.detect();
      await Future<void>.delayed(Duration.zero);
      // Asked once the microphone had 0.3 s past the wake word.
      expect(held.elapsed, greaterThanOrEqualTo(WakeWordManager.verifyAfter));
      expect(asked, hasLength(1));
      expect(asked.single['wakeWord'], 'Okay Nabu');
      expect(asked.single['clip'], isA<Uint8List>());
      expect(asked.single['tailMs'], inInclusiveRange(300, 400));
      expect(asked.single['id'], isNotEmpty);
      // No event: no chime, no overlay and nothing to the assistant. The
      // kiosk listens for the wake word again.
      expect(detected, isEmpty);
      expect(wakeWord.wakeVerified, isNull);
      expect(await active(), isTrue);
    });

    test('a wake word that was said starts the turn with its check', () async {
      answer = true;
      await engine.detect();
      await Future<void>.delayed(Duration.zero);
      expect(detected, hasLength(1));
      expect(wakeWord.wakeVerified, asked.single['id']);
      expect(await active(), isFalse);
      // The next wake word has no check of its own until it is asked.
      answer = null;
      await commands.execute('setWakeWordActive', const {'active': true});
      await engine.detect();
      await Future<void>.delayed(Duration.zero);
      expect(detected, hasLength(2));
      expect(wakeWord.wakeVerified, isNull);
    });

    test('no answer from Ground Control starts the turn', () async {
      answer = null;
      await engine.detect();
      await Future<void>.delayed(Duration.zero);
      expect(asked, hasLength(1));
      expect(detected, hasLength(1));
      expect(wakeWord.wakeVerified, isNull);
    });

    test('the wait counts from the end of the wake word', () async {
      answer = true;
      // An engine that fired late: the microphone already has what the
      // check hears.
      engine.ended = const Duration(milliseconds: 350);
      final held = Stopwatch()..start();
      await engine.detect();
      expect(held.elapsed, lessThan(const Duration(milliseconds: 150)));
      // The wake clip never runs more than 0.4 s past the wake word.
      expect(asked.single['tailMs'], inInclusiveRange(350, 400));
    });

    test('the pre-roll keeps what is said while the wake is held', () async {
      // The switch reaches the manager over the bus.
      await Future<void>.delayed(Duration.zero);
      expect(
        engine.preRoll,
        WakeWordManager.verifyAfter + WakeWordManager.verifyAnswerWithin,
      );
      await settings.set(defs.voiceMatchVerifierWait, false);
      await Future<void>.delayed(Duration.zero);
      expect(engine.preRoll, Duration.zero);
    });

    test('only with what the Wake Word Verifier needs', () async {
      for (final off in [
        defs.voiceMatchWakeWordVerifier,
        defs.voiceMatchEndOnOtherVoice,
        defs.voiceMatchEnabled,
        defs.groundControlEnabled,
      ]) {
        await settings.set(off, false);
        await commands.execute('setWakeWordActive', const {'active': true});
        await engine.detect();
        await Future<void>.delayed(Duration.zero);
        expect(asked, isEmpty, reason: off.key);
        await settings.set(off, true);
      }
      // A muted kiosk answers nothing: there is no turn to hold.
      await settings.set(defs.voiceMute, true);
      await commands.execute('setWakeWordActive', const {'active': true});
      await engine.detect();
      expect(asked, isEmpty);
    });
  });
}
