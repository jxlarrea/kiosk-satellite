import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/wake_word/engine.dart';
import 'package:kiosk_satellite/managers/wake_word/near_miss.dart';
import 'package:kiosk_satellite/managers/wake_word/pcm16.dart';
import 'package:kiosk_satellite/managers/wake_word/pcm_ring.dart';
import 'package:kiosk_satellite/managers/wake_word/wake_diagnostics.dart';
import 'package:kiosk_satellite/managers/wake_word/wake_word_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uint8List _pcm(List<int> samples) =>
    Uint8List.view(Int16List.fromList(samples).buffer);

List<int> _samples(Uint8List pcm) => pcm16Samples(pcm, 0, pcm.length).toList();

/// A runner that keeps what the manager hands it: the detection callback,
/// the record switch and a canned clip and detection report.
class _RecordingEngine extends WakeWordEngine {
  bool _running = false;
  bool recording = false;
  DetectionCallback? onDetection;
  Uint8List clip = _pcm(List.filled(16000, 1000));
  Map<String, Object?>? detection = {'score': 0.91, 'threshold': 0.65};

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
    this.onDetection = onDetection;
    _running = true;
  }

  @override
  Future<void> stop() async => _running = false;

  @override
  set recordAudio(bool enabled) => recording = enabled;

  @override
  Uint8List? recentAudio(Duration length) => recording ? clip : null;

  @override
  Map<String, Object?>? get lastDetection => detection;

  void Function(WakeWordModelRef, Map<String, Object?>)? nearMissSink;

  @override
  set onNearMiss(
    void Function(WakeWordModelRef model, Map<String, Object?> detail)? sink,
  ) => nearMissSink = sink;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PcmRing', () {
    test('keeps the newest samples, oldest first, across the wrap', () {
      final ring = PcmRing(5);
      ring.add(_pcm([1, 2, 3]));
      ring.add(_pcm([4, 5, 6, 7]));
      expect(ring.length, 5);
      expect(_samples(ring.last(5)), [3, 4, 5, 6, 7]);
      expect(_samples(ring.last(2)), [6, 7]);
      expect(_samples(ring.last(99)), [3, 4, 5, 6, 7]);
    });

    test('an oversized chunk leaves only its tail', () {
      final ring = PcmRing(3)..add(_pcm([9]));
      ring.add(_pcm([1, 2, 3, 4, 5]));
      expect(_samples(ring.last(3)), [3, 4, 5]);
    });

    test('reads a chunk that starts at an odd byte offset', () {
      final bytes = Uint8List(7)..setRange(1, 5, _pcm([300, -2]));
      final ring = PcmRing(4)..add(Uint8List.sublistView(bytes, 1, 5));
      expect(_samples(ring.last(4)), [300, -2]);
    });

    test('clear empties it', () {
      final ring = PcmRing(4)..add(_pcm([1, 2]));
      ring.clear();
      expect(ring.length, 0);
      expect(ring.last(4), isEmpty);
    });
  });

  group('NearMissTracker', () {
    test('one report per episode, carrying its peak and detail', () {
      final t = NearMissTracker();
      var built = 0;
      Map<String, Object?>? feed(double score) => t.update(
        score: score,
        threshold: 8,
        fired: false,
        detail: () => {'decoded': 'n${built++}'},
      );
      expect(feed(2), isNull); // below 75%: nothing opens
      expect(feed(6.5), isNull);
      expect(feed(7.5), isNull);
      expect(feed(7), isNull); // lower than the peak: no new detail
      final report = feed(1);
      expect(report, {'decoded': 'n1', 'score': 7.5, 'threshold': 8.0});
      expect(built, 2);
      expect(feed(1), isNull); // closed: one report, not two
    });

    test('firing turns the episode into an activation, not a miss', () {
      final t = NearMissTracker();
      t.update(score: 7, threshold: 8, fired: false);
      expect(t.update(score: 9, threshold: 8, fired: true), isNull);
      expect(t.update(score: 0, threshold: 8, fired: false), isNull);
    });

    test('a non-finite score (no match) ends an episode', () {
      final t = NearMissTracker();
      t.update(score: 0.7, threshold: 0.8, fired: false);
      final r = t.update(
        score: double.negativeInfinity,
        threshold: 0.8,
        fired: false,
      );
      expect(r?['score'], 0.7);
    });

    test('reset forgets an open episode', () {
      final t = NearMissTracker()..update(score: 7, threshold: 8, fired: false);
      t.reset();
      expect(t.update(score: 0, threshold: 8, fired: false), isNull);
    });
  });

  group('WAV and levels', () {
    test('the WAV header describes 16 kHz mono PCM16', () {
      final wav = pcm16Wav(_pcm([1, 2, 3]));
      final header = ByteData.sublistView(wav);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 16)), 'WAVEfmt ');
      expect(header.getUint16(22, Endian.little), 1);
      expect(header.getUint32(24, Endian.little), 16000);
      expect(header.getUint16(34, Endian.little), 16);
      expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
      expect(header.getUint32(40, Endian.little), 6);
      expect(wav.length, 44 + 6);
    });

    test('full scale counts as clipped and reads 0 dBFS', () {
      final levels = pcm16Levels(_pcm([32767, -32768, 0, 100]));
      expect(levels.clipped, 2);
      expect(levels.peakDb, closeTo(0, 0.01));
    });

    test('half scale reads about -6 dBFS, silence minus infinity', () {
      final half = pcm16Levels(_pcm(List.filled(100, 16384)));
      expect(half.peakDb, closeTo(-6.02, 0.05));
      expect(half.rmsDb, closeTo(-6.02, 0.05));
      expect(half.clipped, 0);
      final silent = pcm16Levels(_pcm(List.filled(10, 0)));
      expect(silent.peakDb, double.negativeInfinity);
    });
  });

  group('WakeWordDiagnostics', () {
    late Directory tmp;
    late Directory dir;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('wake_diag_');
      dir = Directory('${tmp.path}/diag');
    });
    tearDown(() => tmp.delete(recursive: true));

    WakeWordDiagnostics store() =>
        WakeWordDiagnostics(directory: () async => dir);

    test('keeps the newest ten and deletes the clips it drops', () async {
      final d = store();
      final start = DateTime(2026, 9, 25, 12);
      for (var i = 0; i < 12; i++) {
        await d.record(
          wakeWord: 'Okay Nabu',
          engine: 'microWakeWord',
          pcm: _pcm([i, i]),
          at: start.add(Duration(seconds: i)),
        );
      }
      expect(d.activations, hasLength(10));
      expect(d.activations.first.at, start.add(const Duration(seconds: 11)));
      final wavs = dir.listSync().where((f) => f.path.endsWith('.wav'));
      expect(wavs, hasLength(10));
      expect(await d.clip(d.activations.last.id), isNotNull);
    });

    test('a new run reads back what the last one saved', () async {
      await store().record(
        wakeWord: 'Hey Jarvis',
        engine: 'vsWakeWord',
        pcm: _pcm(List.filled(48000, 32767)),
        detection: {
          'score': 1.2,
          'threshold': 0.8,
          'decoded': 'hh ey jh aa r v ih s',
          'editDistance': 1,
        },
      );
      final again = store();
      await again.load();
      final a = again.activations.single;
      expect(a.wakeWord, 'Hey Jarvis');
      expect(a.engine, 'vsWakeWord');
      expect(a.score, 1.2);
      expect(a.threshold, 0.8);
      expect(a.decoded, 'hh ey jh aa r v ih s');
      expect(a.editDistance, 1);
      expect(a.durationMs, 3000);
      expect(a.clipped, 48000);
    });

    test('a silent clip survives the JSON round trip', () async {
      await store().record(
        wakeWord: 'Alexa',
        engine: 'openWakeWord',
        pcm: _pcm(List.filled(8, 0)),
      );
      final again = store();
      await again.load();
      expect(again.activations.single.peakDb, double.negativeInfinity);
    });

    test(
      'near misses have their own ten and never push out activations',
      () async {
        final d = store();
        await d.record(wakeWord: 'A', engine: 'e', pcm: _pcm([1]));
        final start = DateTime(2026, 9, 25, 12);
        for (var i = 0; i < 15; i++) {
          await d.record(
            wakeWord: 'A',
            engine: 'e',
            pcm: _pcm([i]),
            nearMiss: true,
            at: start.add(Duration(seconds: i)),
          );
        }
        expect(d.activations, hasLength(1));
        expect(d.nearMisses, hasLength(10));
        expect(d.nearMisses.every((a) => a.nearMiss), isTrue);
        final wavs = dir.listSync().where((f) => f.path.endsWith('.wav'));
        expect(wavs, hasLength(11));
        final again = store();
        await again.load();
        expect(again.activations, hasLength(1));
        expect(again.nearMisses, hasLength(10));
      },
    );

    test('clear deletes everything, the folder included', () async {
      final d = store();
      await d.record(wakeWord: 'A', engine: 'e', pcm: _pcm([1]));
      await d.clear();
      expect(d.activations, isEmpty);
      expect(await dir.exists(), isFalse);
    });
  });

  group('WakeWordManager with diagnostics', () {
    late Directory tmp;
    late EventBus bus;
    late CommandRegistry commands;
    late SettingsManager settings;
    late WakeWordManager wakeWord;
    late _RecordingEngine engine;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter.baseflow.com/permissions/methods'),
            (call) async => switch (call.method) {
              'checkPermissionStatus' => 1,
              'requestPermissions' => {call.arguments.first: 1},
              _ => null,
            },
          );
      tmp = await Directory.systemTemp.createTemp('wake_diag_mgr_');
      bus = EventBus();
      final log = Logger();
      commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      engine = _RecordingEngine();
      wakeWord = WakeWordManager(
        bus,
        commands,
        log,
        settings,
        engines: {WakeWordEngineType.microWakeWord: engine},
        diagnostics: WakeWordDiagnostics(
          directory: () async => Directory('${tmp.path}/diag'),
        ),
      );
      await wakeWord.init();
      // The detection path wakes the screen and checks the HA socket.
      commands
        ..register(
          Command(
            name: 'screenOn',
            description: '',
            handler: (_) async => const CommandResult.ok(),
          ),
        )
        ..register(
          Command(
            name: 'ensureHaConnected',
            description: '',
            handler: (_) async => const CommandResult.ok(),
          ),
        );
      await commands.execute('setWakeWordConfig', const {
        'engine': 'microWakeWord',
        'models': [
          {'id': 'okay_nabu', 'wakeWord': 'Okay Nabu', 'manifestUrl': 'x'},
        ],
      });
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter.baseflow.com/permissions/methods'),
            null,
          );
      await wakeWord.dispose();
      await bus.dispose();
      await tmp.delete(recursive: true);
    });

    const nabu = WakeWordModelRef(
      id: 'okay_nabu',
      wakeWord: 'Okay Nabu',
      manifestUrl: '',
    );

    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      // The save runs file IO on the real event loop.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    test('off by default: no audio kept, nothing saved', () async {
      expect(engine.recording, isFalse);
      await engine.onDetection!(nabu);
      await settle();
      expect(wakeWord.diagnostics.activations, isEmpty);
    });

    test('a tester keeps audio only while it is open', () {
      wakeWord.startTest();
      expect(engine.recording, isTrue);
      wakeWord.stopTest();
      expect(engine.recording, isFalse);
    });

    test('on: a detection saves its clip and scores', () async {
      await settings.set(defs.wakeWordDiagnostics, true);
      await settle();
      expect(engine.recording, isTrue);
      await engine.onDetection!(nabu);
      await settle();
      final a = wakeWord.diagnostics.activations.single;
      expect(a.wakeWord, 'Okay Nabu');
      expect(a.engine, 'microWakeWord');
      expect(a.score, 0.91);
      expect(a.durationMs, 1000);

      final list = await commands.execute('getWakeWordActivations', const {});
      final data = list.data as Map;
      expect(data['enabled'], isTrue);
      expect((data['activations'] as List).single['id'], a.id);

      final audio = await commands.execute('getWakeWordActivationAudio', {
        'id': a.id,
      });
      final wav = base64Decode((audio.data as Map)['base64'] as String);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(wav.length, 44 + 32000);
    });

    test('turning it off deletes what it saved and stops recording', () async {
      await settings.set(defs.wakeWordDiagnostics, true);
      await settle();
      await engine.onDetection!(nabu);
      await settle();
      expect(wakeWord.diagnostics.activations, hasLength(1));
      final pushed = bus.on<RemoteStatusChanged>().first;
      await settings.set(defs.wakeWordDiagnostics, false);
      expect((await pushed).topic, 'wakeword-activations');
      await settle();
      expect(wakeWord.diagnostics.activations, isEmpty);
      expect(engine.recording, isFalse);
    });

    test(
      'a near miss is saved with its clip, but not under a tester',
      () async {
        await settings.set(defs.wakeWordDiagnostics, true);
        await settle();
        final sink = engine.nearMissSink!;
        wakeWord.startTest();
        sink(nabu, {'score': 6.5, 'threshold': 8.0});
        await settle();
        expect(wakeWord.diagnostics.nearMisses, isEmpty);
        wakeWord.stopTest();
        sink(nabu, {'score': 6.5, 'threshold': 8.0, 'decoded': 'ow k ey'});
        // Within the gap: one noisy stretch is one entry.
        sink(nabu, {'score': 7.0, 'threshold': 8.0});
        await settle();
        final miss = wakeWord.diagnostics.nearMisses.single;
        expect(miss.score, 6.5);
        expect(miss.decoded, 'ow k ey');
        expect(wakeWord.diagnostics.activations, isEmpty);
        final list = await commands.execute('getWakeWordActivations', const {});
        expect(
          ((list.data as Map)['nearMisses'] as List).single['nearMiss'],
          true,
        );
      },
    );

    test('off: the engine is not asked for near misses', () async {
      expect(engine.nearMissSink, isNull);
    });

    test('a simulated wake carries no stale score', () async {
      await settings.set(defs.wakeWordDiagnostics, true);
      await settle();
      await commands.execute('simulateWakeWord', const {});
      await settle();
      expect(wakeWord.diagnostics.activations.single.score, isNull);
    });
  });
}
