import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/core/permissions.dart';
import 'package:kiosk_satellite/managers/wake_word/engine.dart';
import 'package:kiosk_satellite/managers/wake_word/isolate_engine.dart';

/// The half of the wake path every engine shares: the pre-roll ring, the sample
/// clock it shares with the compute isolate, and the audio stream delegated to
/// the card. This is the code a wake word's first word of speech depends on.
void main() {
  /// 16-bit PCM, [samples] of it, each sample carrying [value] so a slice can
  /// be identified by its content.
  Uint8List pcm(int samples, {int value = 1}) {
    final bytes = Uint8List(samples * 2);
    final view = ByteData.sublistView(bytes);
    for (var i = 0; i < samples; i++) {
      view.setInt16(i * 2, value, Endian.little);
    }
    return bytes;
  }

  int samplesIn(List<Uint8List> chunks) =>
      chunks.fold(0, (sum, c) => sum + c.length ~/ 2);

  /// Let queued port messages land.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 2));

  group('PreRollBuffer', () {
    test('keeps the clock across chunks', () {
      final buf = PreRollBuffer();
      expect(buf.absSamples, 0);
      buf.add(pcm(1280));
      buf.add(pcm(1280));
      expect(buf.absSamples, 2560);
    });

    test('holds only the most recent maxChunks', () {
      final buf = PreRollBuffer(maxChunks: 8);
      for (var i = 0; i < 20; i++) {
        buf.add(pcm(1280));
      }
      // 8 x 80 ms = 640 ms, however long the mic has been open.
      expect(samplesIn(buf.flush(null)), 8 * 1280);
      expect(buf.absSamples, 20 * 1280);
    });

    test('a null trim point yields everything buffered', () {
      // A manual wake or start_conversation: no wake word was spoken, so there
      // is nothing to trim and the full pre-roll is the useful answer.
      final buf = PreRollBuffer();
      buf.add(pcm(1280));
      buf.add(pcm(1280));
      expect(samplesIn(buf.flush(null)), 2560);
    });

    test('trims whole chunks older than the wake end', () {
      final buf = PreRollBuffer();
      buf.add(pcm(1280)); // 0..1280
      buf.add(pcm(1280)); // 1280..2560
      expect(samplesIn(buf.flush(1280)), 1280, reason: 'first chunk is older');
    });

    test('splits the chunk the wake word ended inside', () {
      final buf = PreRollBuffer();
      buf.add(pcm(1280, value: 7));
      buf.add(pcm(1280, value: 9));
      // The wake word ended 280 samples into the first chunk.
      final out = buf.flush(280);
      expect(samplesIn(out), 2560 - 280);
      // The surviving part of the split chunk is the *tail*, not the head.
      final first = ByteData.sublistView(out.first);
      expect(first.getInt16(0, Endian.little), 7);
      expect(out.first.length ~/ 2, 1000);
    });

    test('a wake end past everything buffered yields nothing', () {
      final buf = PreRollBuffer();
      buf.add(pcm(1280));
      expect(buf.flush(1280), isEmpty, reason: 'all of it is the wake word');
    });

    test('reset restarts the clock, not just the audio', () {
      // The regression that motivated this: the engine's clock is shared with
      // the compute isolate, and a fresh isolate always counts from zero. An
      // engine that kept counting across a stop/start would compare a wake-end
      // sample from the new isolate against pre-roll stamped by the old clock,
      // find every chunk "newer", and trim nothing — feeding the wake word
      // itself to STT. The card's wake word tester restarts the engine every
      // time it runs, so this is a real path.
      final buf = PreRollBuffer();
      for (var i = 0; i < 100; i++) {
        buf.add(pcm(1280));
      }
      expect(buf.absSamples, 128000);

      buf.reset();
      expect(buf.absSamples, 0, reason: 'must restart with the next isolate');
      expect(buf.flush(null), isEmpty);

      // Re-run: a detection at sample 1280 now trims correctly again.
      buf.add(pcm(1280));
      buf.add(pcm(1280));
      expect(samplesIn(buf.flush(1280)), 1280);
    });
  });

  group('IsolateWakeEngine', () {
    late _FakeEngine engine;
    late StreamController<Uint8List> mic;

    setUp(() {
      mic = StreamController<Uint8List>.broadcast();
      engine = _FakeEngine(Logger(), mic: () => mic.stream);
    });

    tearDown(() async {
      await engine.stop();
      await mic.close();
    });

    Future<void> start({WakeWordConfig? config}) async {
      await engine.start(
        config: config ?? _config,
        onDetection: (m) async => engine.detections.add(m),
      );
    }

    /// Push a mic chunk and let it reach the isolate. The delay is real, not
    /// cosmetic: a SendPort delivers on the event loop, so a zero-duration
    /// microtask can resume before the "isolate" has seen anything.
    Future<void> feed(int samples, {int value = 1}) async {
      mic.add(pcm(samples, value: value));
      await settle();
    }

    test('asks for the microphone before it needs it', () async {
      // The fresh-install path. Nothing else asks: the WebView requests the mic
      // when a page calls getUserMedia, and the entire point of the handoff is
      // that Voice Satellite stops calling getUserMedia once we claim the
      // engine. So on a new device that prompt never fires and AudioRecord
      // fails on a permission nobody asked for — every wake word, silently.
      await start();
      expect(engine.micPermissionAsks, 1);
      expect(engine.running, isTrue);
    });

    test('asks before downloading, not after', () async {
      // Models are megabytes; a denied mic makes all of them pointless.
      engine.micOutcome = PermissionOutcome.declined;
      await start();
      expect(engine.micPermissionAsks, 1);
      expect(engine.loadCalls, 0, reason: 'nothing worth downloading');
    });

    test('a denied microphone does not start the engine', () async {
      engine.micOutcome = PermissionOutcome.declined;
      await start();
      expect(engine.running, isFalse);
      // The manager turns "did not start" into available:false, which is what
      // sends Voice Satellite back to browser detection.
      expect(engine.isolateAudio, isEmpty);
    });

    test('declined and blocked are reported apart', () async {
      // They need different answers: a decline can be asked again, a block can
      // only be undone in the OS settings. Reporting both as "denied" is how a
      // stray tap turns into a device nobody can fix.
      final failures = <EngineFailure>[];

      engine.micOutcome = PermissionOutcome.declined;
      await engine.start(
          config: _config,
          onDetection: (_) async {},
          onFailure: (kind, _) => failures.add(kind));
      expect(failures, [EngineFailure.micDeclined]);

      engine.micOutcome = PermissionOutcome.blocked;
      await engine.start(
          config: _config,
          onDetection: (_) async {},
          onFailure: (kind, _) => failures.add(kind));
      expect(failures, [EngineFailure.micDeclined, EngineFailure.micBlocked]);
    });

    test('a retry after a decline asks again', () async {
      // Android keeps asking until the second refusal, so a stray "Don't allow"
      // must not be the end of it.
      engine.micOutcome = PermissionOutcome.declined;
      await start();
      expect(engine.running, isFalse);

      engine.micOutcome = PermissionOutcome.granted;
      await start();
      expect(engine.micPermissionAsks, 2);
      expect(engine.running, isTrue, reason: 'the second ask was allowed');
    });

    test('no models is reported as such, not as a mic problem', () async {
      engine.payload = const WakeModelPayload(models: []);
      final failures = <EngineFailure>[];
      await engine.start(
          config: _config,
          onDetection: (_) async {},
          onFailure: (kind, _) => failures.add(kind));
      expect(failures, [EngineFailure.modelsUnavailable]);
    });

    test('refuses a config for another engine', () async {
      await engine.start(
        config: const WakeWordConfig(
            engine: WakeWordEngineType.openWakeWord, models: []),
        onDetection: (_) async {},
      );
      expect(engine.running, isFalse);
      expect(engine.loadCalls, 0, reason: 'not even worth downloading');
    });

    test('does not start when no model loads', () async {
      engine.payload = const WakeModelPayload(models: []);
      await start();
      expect(engine.running, isFalse);
    });

    test('reports the stop word only when one actually loaded', () async {
      expect(engine.supportsStopWord, isFalse);
      engine.payload = WakeModelPayload(
          models: engine.payload!.models, hasStopModel: true);
      await start();
      expect(engine.supportsStopWord, isTrue);

      // A restart re-negotiates: claiming a stop model we no longer hold would
      // have the card drop its own browser classifier for nothing.
      await engine.stop();
      expect(engine.supportsStopWord, isFalse);
    });

    test('forwards mic audio to the isolate while listening', () async {
      await start();
      await feed(1280);
      expect(samplesIn(engine.isolateAudio), 1280);
    });

    test('a detection pauses detection but keeps the mic', () async {
      await start();
      await feed(1280);
      await engine.fireDetection(wakeEndSample: 1280);

      expect(engine.detections, hasLength(1));
      expect(engine.detections.single.id, 'okay_nabu');

      // The mic stays open: we are the audio source for the turn about to run.
      final before = samplesIn(engine.isolateAudio);
      await feed(1280);
      expect(samplesIn(engine.isolateAudio), before,
          reason: 'paused: the detector stops being fed');
      expect(engine.running, isTrue, reason: 'but the mic stays open');
    });

    test('an armed stop word keeps feeding the isolate through a turn',
        () async {
      engine.payload = WakeModelPayload(
          models: engine.payload!.models, hasStopModel: true);
      await start();
      await engine.setStopWordActive(true);
      await settle();
      await engine.fireDetection(wakeEndSample: 0);

      // The stop word only matters *during* a turn — that is the whole point of
      // it — so a paused detector must not starve it of audio.
      final before = samplesIn(engine.isolateAudio);
      await feed(1280);
      expect(samplesIn(engine.isolateAudio), before + 1280);
    });

    test('the audio stream opens with pre-roll trimmed to the wake end',
        () async {
      await start();
      await feed(1280, value: 3); // 0..1280: the wake word
      await feed(1280, value: 5); // 1280..2560: the command
      await engine.fireDetection(wakeEndSample: 1280);

      final chunks = <Uint8List>[];
      final flags = <bool>[];
      await engine.startAudioStream((pcm, preRoll) {
        chunks.add(pcm);
        flags.add(preRoll);
      });

      expect(samplesIn(chunks), 1280, reason: 'the wake word is trimmed away');
      expect(ByteData.sublistView(chunks.first).getInt16(0, Endian.little), 5,
          reason: 'what survives is the command, not the wake word');
      expect(flags, everyElement(isTrue),
          reason: 'replayed audio must be flagged so live meters skip it');
    });

    test('live audio after the stream opens is not flagged as pre-roll',
        () async {
      await start();
      await engine.fireDetection(wakeEndSample: 0);
      final flags = <bool>[];
      await engine.startAudioStream((_, preRoll) => flags.add(preRoll));
      flags.clear();
      await feed(1280);
      expect(flags, [isFalse]);
    });

    test('a detection with no wake end falls back to the detection instant',
        () async {
      // What the window classifiers (mww, oww) report. Detection never precedes
      // the wake word ending, so trimming to "now" cannot replay it.
      await start();
      await feed(1280);
      await feed(1280);
      await engine.fireDetection(wakeEndSample: null);

      final chunks = <Uint8List>[];
      await engine.startAudioStream((pcm, _) => chunks.add(pcm));
      expect(chunks, isEmpty, reason: 'trimmed to now: nothing is newer');
    });

    test('resuming re-syncs the isolate clock to the mic', () async {
      await start();
      await feed(1280);
      await engine.fireDetection(wakeEndSample: 1280);
      // Audio kept flowing into the pre-roll during the turn while the isolate
      // was not being fed, so it must be told where the clock got to.
      await feed(1280);
      await feed(1280);
      await engine.resumeDetection();
      await settle();

      final resume = engine.control.lastWhere((m) => m['type'] == WakeMsg.resume);
      expect(resume['absSample'], 3 * 1280);
    });

    test('resuming clears the trim point', () async {
      await start();
      await feed(1280, value: 3);
      await engine.fireDetection(wakeEndSample: 1280);
      await engine.resumeDetection();
      await feed(1280, value: 5);

      // The next stream is not opening off the back of a detection, so the old
      // wake end must not still be trimming it.
      final chunks = <Uint8List>[];
      await engine.startAudioStream((pcm, _) => chunks.add(pcm));
      expect(samplesIn(chunks), 2560, reason: 'the whole pre-roll is useful');
    });

    test('stopAudioStream detaches the page', () async {
      await start();
      final chunks = <Uint8List>[];
      await engine.startAudioStream((pcm, _) => chunks.add(pcm));
      await feed(1280);
      expect(chunks, hasLength(1));

      await engine.stopAudioStream();
      await feed(1280);
      expect(chunks, hasLength(1), reason: 'the page stopped receiving audio');
    });

    test('arming the stop word is idempotent and needs a loaded model',
        () async {
      await start(); // hasStopModel: false
      await engine.setStopWordActive(true);
      await settle();
      expect(engine.control.where((m) => m['type'] == WakeMsg.armStop), isEmpty,
          reason: 'no stop model loaded: nothing to arm');

      await engine.stop();
      engine.payload = WakeModelPayload(
          models: engine.payload!.models, hasStopModel: true);
      await start();
      await engine.setStopWordActive(true);
      await engine.setStopWordActive(true);
      await settle();
      expect(engine.control.where((m) => m['type'] == WakeMsg.armStop),
          hasLength(1), reason: 're-arming an armed classifier is a no-op');
    });

    test('a dead mic is fatal, not a warning', () async {
      // The real incident: revoking the microphone permission left
      // "AudioRecord init failed" on this stream. Nothing threw again, the
      // engine kept reporting `running`, and Voice Satellite — which had
      // stopped its own browser detection because we said we were covered —
      // heard nothing for the rest of the session.
      final failures = <EngineFailure>[];
      await engine.start(
        config: _config,
        onDetection: (m) async => engine.detections.add(m),
        onFailure: (kind, _) => failures.add(kind),
      );
      expect(engine.running, isTrue);

      mic.addError(Exception('AudioRecord init failed'));
      await settle();

      expect(failures, [EngineFailure.micLost]);
      expect(engine.running, isFalse,
          reason: 'a deaf engine must not claim to be running');
    });

    test('a mic that dies twice reports once', () async {
      final failures = <EngineFailure>[];
      await engine.start(
        config: _config,
        onDetection: (_) async {},
        onFailure: (kind, _) => failures.add(kind),
      );
      mic.addError(Exception('first'));
      await settle();
      mic.addError(Exception('second'));
      await settle();
      expect(failures, hasLength(1), reason: 'already stopped by the first');
    });

    test('stop releases the mic and tears the isolate down', () async {
      await start();
      expect(mic.hasListener, isTrue);
      await engine.stop();
      expect(engine.running, isFalse);
      expect(mic.hasListener, isFalse, reason: 'the mic must be released');
      expect(engine.control.last['type'], WakeMsg.stop,
          reason: 'the isolate is asked to free its models first');
    });

    test('a restart re-syncs the clock with the fresh isolate', () async {
      // End to end over the bug PreRollBuffer.reset() exists for: the card's
      // wake word tester stops the engine to take the mic, then restarts it.
      await start();
      for (var i = 0; i < 50; i++) {
        await feed(1280);
      }
      await engine.stop();

      await start();
      await feed(1280, value: 3); // the new isolate's samples 0..1280
      await feed(1280, value: 5);
      await engine.fireDetection(wakeEndSample: 1280);

      final chunks = <Uint8List>[];
      await engine.startAudioStream((pcm, _) => chunks.add(pcm));
      expect(samplesIn(chunks), 1280,
          reason: 'a stale clock would trim nothing and replay the wake word');
      expect(ByteData.sublistView(chunks.first).getInt16(0, Endian.little), 5);
    });
  });
}

const _config = WakeWordConfig(
  engine: WakeWordEngineType.vsWakeWord,
  models: [
    WakeWordModelRef(
        id: 'okay_nabu', wakeWord: 'Okay Nabu', manifestUrl: 'http://x/m.json'),
  ],
);

/// Stands in for the OS microphone grant.
class _FakeGrant {
  PermissionOutcome outcome = PermissionOutcome.granted;
  int asks = 0;

  Future<PermissionOutcome> ask() async {
    asks++;
    return outcome;
  }
}

/// Stands in for the compute isolate: same ports, same protocol, no models.
///
/// It answers `init` with `ready` and `stop` with `stopped` the way a real
/// worker does, records what it was sent, and lets a test report a detection.
/// So the base's own logic runs for real; only the inference is absent.
class _FakeIsolate {
  final List<Map<String, Object?>> control = [];
  final List<Uint8List> audio = [];
  SendPort? _toMain;

  Future<Isolate?> spawn(
      void Function(SendPort) entry, SendPort main, String name) async {
    _toMain = main;
    final port = ReceivePort();
    port.listen((msg) {
      if (msg is Uint8List) {
        audio.add(msg);
        return;
      }
      if (msg is! Map) return;
      control.add(Map<String, Object?>.from(msg));
      switch (msg['type']) {
        case WakeMsg.init:
          main.send({'type': WakeMsg.ready});
        case WakeMsg.stop:
          main.send({'type': WakeMsg.stopped});
          port.close();
      }
    });
    main.send(port.sendPort);
    // No real isolate: the base has nothing to kill, which is what null means.
    return null;
  }

  void detect({required int? wakeEndSample}) => _toMain?.send({
        'type': WakeMsg.detection,
        'id': 'okay_nabu',
        'wakeWord': 'Okay Nabu',
        // Omitted entirely by an engine that cannot align its match, which is
        // not the same as sending null.
        'wakeEndSample': ?wakeEndSample,
      });
}

/// An engine with no models: the base's behaviour on its own.
class _FakeEngine extends IsolateWakeEngine {
  factory _FakeEngine(Logger log, {MicSource? mic}) {
    // A mutable box, because the engine takes the permission check at
    // construction and the tests flip the answer afterwards.
    final grant = _FakeGrant();
    return _FakeEngine._(_FakeIsolate(), grant, log,
        mic: mic, micPermission: grant.ask);
  }

  _FakeEngine._(this.isolate, this._grant, Logger log,
      {MicSource? mic, MicPermission? micPermission})
      : super(log,
            mic: mic, spawner: isolate.spawn, micPermission: micPermission);

  final _FakeGrant _grant;

  /// Stands in for the OS grant.
  PermissionOutcome get micOutcome => _grant.outcome;
  set micOutcome(PermissionOutcome v) => _grant.outcome = v;
  int get micPermissionAsks => _grant.asks;

  final _FakeIsolate isolate;
  final List<WakeWordModelRef> detections = [];
  int loadCalls = 0;

  WakeModelPayload? payload = const WakeModelPayload(models: [
    {'id': 'okay_nabu', 'wakeWord': 'Okay Nabu'}
  ]);

  List<Map<String, Object?>> get control => isolate.control;
  List<Uint8List> get isolateAudio => isolate.audio;

  @override
  String get tag => 'fake';

  @override
  WakeWordEngineType get engineType => WakeWordEngineType.vsWakeWord;

  @override
  bool get wakeEndIsAligned => true;

  @override
  void Function(SendPort) get isolateEntry => _unusedEntry;

  /// Never runs: [_FakeIsolate.spawn] ignores it.
  static void _unusedEntry(SendPort _) {}

  @override
  Future<WakeModelPayload?> loadModels(WakeWordConfig config) async {
    loadCalls++;
    return payload;
  }

  /// Report a detection exactly as a compute isolate would.
  Future<void> fireDetection({required int? wakeEndSample}) async {
    isolate.detect(wakeEndSample: wakeEndSample);
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}
