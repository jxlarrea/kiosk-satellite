import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/wake_word/model_cache.dart';
import 'package:kiosk_satellite/managers/wake_word/wake_word_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// permission_handler's PermissionStatus, over the wire.
const _denied = 0;
const _granted = 1;

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

  const vsConfig = {
    'engine': 'microWakeWord',
    'models': [
      {
        'id': 'okay_nabu',
        'wakeWord': 'Okay Nabu',
        'manifestUrl': 'http://ha.local:8123/voice_satellite/models/okay_nabu.json',
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
    final log = Logger();
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
            null);
    await wakeWord.dispose();
    await bus.dispose();
  });

  test('unconfigured until Voice Satellite pushes a config', () async {
    expect(wakeWord.available, isFalse);
    final state = await commands.execute('getWakeWordState', const {});
    expect((state.data as Map)['engine'], isNull);
  });

  test('rejects malformed configs', () async {
    final result = await commands
        .execute('setWakeWordConfig', const {'engine': 'bogus', 'models': []});
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

  test('having a runner for an engine is not the same as being able to run it',
      () async {
    // `available` is not a claim about which engines we support, it is a
    // promise to Voice Satellite that we are listening *now* — the card stops
    // its own browser detection on the strength of it. We do have a native
    // microWakeWord runner, but here every model download fails (the test
    // binding stubs HTTP to 400), so the promise cannot honestly be made.
    final result = await commands.execute('setWakeWordConfig', vsConfig);
    expect(result.ok, isTrue, reason: 'the config is understood and kept');
    expect((result.data as Map)['available'], isFalse,
        reason: 'nothing came up, so nothing is covered');
    expect(wakeWord.describeState()['engine'], 'microWakeWord',
        reason: 'we still know what was asked for');
  });

  test('detection releases the mic before publishing, page resume re-arms',
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
  });

  group('the two settings UIs must say the same thing', () {
    // The on-device settings screen and the remote web admin describe the same
    // device. Anything Voice Satellite feeds us (engine, wake words, stop word)
    // has to reach both, and neither may word it for itself: the web admin can
    // only render what getWakeWordState hands it.
    test('the state carries the status sentence, not just the flags', () async {
      var state = wakeWord.describeState();
      expect(state['status'], 'waiting',
          reason: 'no config pushed yet');
      expect(state['statusLabel'], contains('Waiting for Voice Satellite'),
          reason: 'the wording is derived once, here');

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
      // Each of these backs a row in assets/remote-ui/index.html
      // (loadWakeWord). Renaming one without touching the other silently
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
      ]) {
        expect(state, contains(key), reason: 'the web admin reads "$key"');
      }
      expect(state['engineLabel'], 'microWakeWord',
          reason: "VS's name for it, not the Dart enum's");
      expect((state['models'] as List).single, containsPair('wakeWord', 'Okay Nabu'));
    });

    test('a disabled engine explains itself rather than going blank', () async {
      await commands.execute('setWakeWordConfig', vsConfig);
      await settings.setFromJson('wake_word.enabled', false);
      final state = wakeWord.describeState();
      expect(state['status'], 'disabled');
      expect(state['statusLabel'], contains('off'));
      expect(state['available'], isFalse);
    });

    test('the stop word is reported so both UIs can show it', () async {
      await commands.execute('setWakeWordConfig', {
        ...vsConfig,
        'stopModel': {
          'id': 'stop',
          'wakeWord': 'Stop',
          'manifestUrl': 'http://ha.local:8123/voice_satellite/models/stop.json',
        },
      });
      expect(wakeWord.describeState()['stopWord'], 'Stop');
    });
  });

  test('an engine that cannot start reports unavailable, not silence',
      () async {
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
    expect((result.data as Map)['available'], isFalse,
        reason: 'nothing is listening, so do not claim otherwise');
    expect(wakeWord.describeState()['status'], 'modelsUnavailable',
        reason: 'and it says which of the ways it failed');
  });

  test('a failed engine retries when the card pushes the same config again',
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
      expect(state['needsAppSettings'], isFalse,
          reason: 'Android will still ask, so settings is the wrong advice');
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

    test('the model download failure is not mistaken for a mic problem',
        () async {
      answerMic(_granted);
      await commands.execute('setWakeWordConfig', vsConfig);
      final state = wakeWord.describeState();
      expect(state['status'], 'modelsUnavailable');
      expect(state['needsAppSettings'], isFalse);
      expect(state['statusLabel'], contains('Home Assistant'));
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
              const MethodChannel('plugins.flutter.io/path_provider'), null);
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
}
