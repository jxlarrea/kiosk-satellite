import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/headless.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/core/permissions.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/voice/wake_catalog.dart';
import 'package:kiosk_satellite/managers/wake_word/engine.dart';
import 'package:kiosk_satellite/managers/wake_word/pryon/pryon_catalog.dart';
import 'package:kiosk_satellite/managers/wake_word/pryon/pryon_engine.dart';

/// What biscuit-pryond says first on the Echo images, shortened to three
/// of its models: en-US first, as the service orders them.
const _hello =
    '{"event":"hello","version":1,"models":['
    '{"model":"alexa-en-US","locales":["en-US"],'
    '"wake_words":["ALEXA"],"stop_words":["STOP"],'
    '"accept_thresholds":{"ALEXA":0.923,"STOP":0.18}},'
    '{"model":"echo-en-US","locales":["en-US","en-CA"],'
    '"wake_words":["ECHO","HEY_DISNEY"],"stop_words":["STOP"],'
    '"accept_thresholds":{"ECHO":0.769,"HEY_DISNEY":0.25,"STOP":0.18}},'
    '{"model":"echo-de-DE","locales":["de-DE"],'
    '"wake_words":["ECHO"],"stop_words":["STOP"],'
    '"accept_thresholds":{"ECHO":0.751,"STOP":0.18}}]}';

/// Amazon's wake word engine on the Echo images: the catalog the
/// service's hello fills, the config the settings resolve to, and the engine
/// against a stand-in for the service.
void main() {
  tearDown(() => PryonCatalog.debugWords = const []);

  group('PryonCatalog', () {
    test("reads every model's words, thresholds and locales", () {
      final words = PryonCatalog.parseHello(_hello);
      expect(words.first, const PryonWord(
        id: 'alexa',
        model: 'alexa-en-US',
        keyword: 'ALEXA',
        acceptThreshold: 0.923,
        locales: ['en-US'],
      ));
      expect(words.first.url, 'pryon:alexa-en-US/ALEXA');
      expect([for (final w in words) w.url], [
        'pryon:alexa-en-US/ALEXA',
        'pryon:alexa-en-US/STOP',
        'pryon:echo-en-US/ECHO',
        'pryon:echo-en-US/HEY_DISNEY',
        'pryon:echo-en-US/STOP',
        'pryon:echo-de-DE/ECHO',
        'pryon:echo-de-DE/STOP',
      ]);
    });

    test('lists the locales in the service order', () {
      PryonCatalog.debugWords = PryonCatalog.parseHello(_hello);
      expect(PryonCatalog.locales, ['en-US', 'en-CA', 'de-DE']);
      expect(PryonCatalog.localeLabel('de-DE'), 'Deutsch (Deutschland)');
      expect(PryonCatalog.localeLabel('xx-YY'), 'xx-YY');
    });

    test("offers each locale its own models' wake words", () {
      PryonCatalog.debugWords = PryonCatalog.parseHello(_hello);
      expect([for (final w in PryonCatalog.wakeWordsFor('en-US')) w.url], [
        'pryon:alexa-en-US/ALEXA',
        'pryon:echo-en-US/ECHO',
        'pryon:echo-en-US/HEY_DISNEY',
      ]);
      expect([for (final w in PryonCatalog.wakeWordsFor('de-DE')) w.url], [
        'pryon:echo-de-DE/ECHO',
      ]);
      expect(PryonCatalog.stopWordFor('echo-de-DE')?.url, 'pryon:echo-de-DE/STOP');
    });

    test("follows the setting, else the app's language", () {
      PryonCatalog.debugWords = PryonCatalog.parseHello(_hello);
      expect(PryonCatalog.resolveLocale('en-CA', 'de'), 'en-CA');
      expect(PryonCatalog.resolveLocale('', 'de'), 'de-DE');
      expect(PryonCatalog.resolveLocale('', 'en'), 'en-US');
      // A language the service has no model for, or a locale it lost.
      expect(PryonCatalog.resolveLocale('', 'ru'), 'en-US');
      expect(PryonCatalog.resolveLocale('fr-FR', 'zh-CN'), 'en-US');
    });

    // The Echo Dot image says so with ro.biscuit.pryon, the Echo Show images
    // with ro.echo.pryon (PryonService.kt), and the Shows have a screen.
    for (final headless in [false, true]) {
      test(
        'offers the engine where the image runs the service, '
        '${headless ? 'without' : 'with'} a screen',
        () async {
          final messenger = TestWidgetsFlutterBinding.ensureInitialized()
              .defaultBinaryMessenger;
          const channel = MethodChannel('kiosk_satellite/background');
          messenger.setMockMethodCallHandler(
            channel,
            (call) async => call.method == 'pryon' ? true : null,
          );
          final dir = await Directory.systemTemp.createTemp('pryon');
          PryonCatalog.socketPath = '${dir.path}/sock';
          final service = await _FakeService.start(PryonCatalog.socketPath);
          Headless.debugActive = headless;
          addTearDown(() async {
            messenger.setMockMethodCallHandler(channel, null);
            Headless.debugActive = false;
            PryonCatalog.socketPath = '/dev/socket/biscuit-pryon';
            await service.close();
            await dir.delete(recursive: true);
            defs.deviceHiddenOptions.remove(defs.voiceWakeWordEngine.key);
            defs.deviceHiddenKeys.remove(defs.voiceAmazonLocale.key);
          });

          await PryonCatalog.init(Logger());
          expect(PryonCatalog.available, isTrue);
          expect(PryonCatalog.locales, ['en-US', 'en-CA', 'de-DE']);
          expect(
            defs.deviceHiddenOptions[defs.voiceWakeWordEngine.key],
            isNull,
          );
          expect(
            defs.deviceHiddenKeys,
            isNot(contains(defs.voiceAmazonLocale.key)),
          );
        },
      );
    }

    test('hides the engine and its language without the image', () async {
      // A tablet, or an Echo on another ROM: neither ro.biscuit.pryon nor
      // ro.echo.pryon.
      await PryonCatalog.init(Logger());
      addTearDown(() {
        defs.deviceHiddenOptions.remove(defs.voiceWakeWordEngine.key);
        defs.deviceHiddenKeys.remove(defs.voiceAmazonLocale.key);
      });
      expect(defs.deviceHiddenOptions[defs.voiceWakeWordEngine.key], {'pryon'});
      expect(defs.deviceHiddenKeys, contains(defs.voiceAmazonLocale.key));
    });

    test('refuses anything but a hello', () {
      expect(
        () => PryonCatalog.parseHello('{"event":"started"}'),
        throwsFormatException,
      );
    });
  });

  group('wake config', () {
    test('offers nothing without the service', () {
      expect(offeredWakeWords(WakeWordEngineType.pryon), isEmpty);
      expect(PryonCatalog.available, isFalse);
    });

    test("offers the locale's wake words and its model's stop word", () {
      PryonCatalog.debugWords = PryonCatalog.parseHello(_hello);
      final offered = offeredWakeWords(
        WakeWordEngineType.pryon,
        pryonLocale: 'en-US',
      );
      expect([for (final w in offered) (w.id, w.phrase)], [
        ('alexa', 'Alexa'),
        ('echo', 'Echo'),
        ('hey_disney', 'Hey Disney'),
      ]);
      final config = buildWakeConfig(
        engine: WakeWordEngineType.pryon,
        activeIds: const ['echo', 'ok_nabu'],
        sensitivity: 'very',
        noiseGate: false,
        stopWord: true,
        pryonLocale: 'en-US',
      );
      // An id the locale does not offer is dropped.
      expect(config.models.single.manifestUrl, 'pryon:echo-en-US/ECHO');
      expect(config.models.single.thresholdOffset, -0.06);
      // The engine lowers its own threshold while music plays.
      expect(config.models.single.playbackConfidenceScale, isNull);
      expect(config.models.single.playbackCutoff, isNull);
      // The stop word of Echo's own model: no second model just for it.
      expect(config.stopModel?.manifestUrl, 'pryon:echo-en-US/STOP');
      expect(config.stopModel?.thresholdOffset, -0.03);
    });

    test("falls back to the locale's first wake word", () {
      PryonCatalog.debugWords = PryonCatalog.parseHello(_hello);
      final config = buildWakeConfig(
        engine: WakeWordEngineType.pryon,
        activeIds: const ['alexa'],
        sensitivity: 'moderately',
        noiseGate: false,
        stopWord: true,
        pryonLocale: 'de-DE',
      );
      expect(config.models.single.manifestUrl, 'pryon:echo-de-DE/ECHO');
      expect(config.stopModel?.manifestUrl, 'pryon:echo-de-DE/STOP');
    });

    test('sensitivity moves the threshold a little', () {
      expect(pryonThresholdOffsetFor('slightly'), 0.02);
      expect(pryonThresholdOffsetFor('moderately'), 0.0);
      expect(pryonThresholdOffsetFor('very'), -0.06);
      // Around the image's 0.18: 0.22, 0.18 and 0.15 for a plain "stop".
      expect(pryonThresholdOffsetFor('slightly', stop: true), 0.04);
      expect(pryonThresholdOffsetFor('moderately', stop: true), 0.0);
      expect(pryonThresholdOffsetFor('very', stop: true), -0.03);
    });
  });

  group('PryonEngine', () {
    late Directory dir;
    late _FakeService service;
    late StreamController<Uint8List> mic;
    late PryonEngine engine;
    late List<WakeWordModelRef> detections;
    late int stops;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('pryon');
      PryonCatalog.socketPath = '${dir.path}/sock';
      PryonCatalog.debugWords = PryonCatalog.parseHello(_hello);
      service = await _FakeService.start(PryonCatalog.socketPath);
      mic = StreamController<Uint8List>();
      engine = PryonEngine(
        Logger(),
        mic: () => mic.stream,
        micPermission: () async => PermissionOutcome.granted,
      );
      detections = [];
      stops = 0;
    });

    tearDown(() async {
      await engine.stop();
      // Not awaited: a mic the engine never listened to never finishes
      // closing.
      unawaited(mic.close());
      await service.close();
      PryonCatalog.socketPath = '/dev/socket/biscuit-pryon';
      await dir.delete(recursive: true);
    });

    Future<void> start(String sensitivity) => engine.start(
      config: buildWakeConfig(
        engine: WakeWordEngineType.pryon,
        activeIds: const ['alexa'],
        sensitivity: sensitivity,
        noiseGate: false,
        stopWord: true,
        pryonLocale: 'en-US',
      ),
      onDetection: (model) async => detections.add(model),
      onStopDetection: () async => stops++,
    );

    /// 80 ms of PCM16, every sample [value].
    Uint8List chunk(int value) {
      final bytes = Uint8List(2560);
      final view = ByteData.sublistView(bytes);
      for (var i = 0; i < 1280; i++) {
        view.setInt16(i * 2, value, Endian.little);
      }
      return bytes;
    }

    Map<String, Object> detection({
      String keyword = 'ALEXA',
      required bool accepted,
      required double score,
      double threshold = 0.923,
      int end = 1280,
    }) => {
      'event': 'detection',
      'model': 'alexa-en-US',
      'keyword': keyword,
      'stop': keyword == 'STOP',
      'accepted': accepted,
      'score': score,
      'threshold': threshold,
      'begin': 0,
      'end': end,
    };

    test('streams the mic and fires on an accept', () async {
      await start('moderately');
      expect(engine.running, isTrue);
      expect(service.started, 'alexa-en-US');

      mic.add(chunk(1));
      mic.add(chunk(2));
      await _until(() => service.samples == 2560);

      service.send(detection(accepted: true, score: 0.95));
      await _until(() => detections.isNotEmpty);
      expect(detections.single.id, 'alexa');
      expect(engine.lastDetection?['score'], 0.95);

      // The stream starts where the service said the word ended: the
      // second chunk, not the first.
      final pre = <Uint8List>[];
      await engine.startAudioStream((pcm, _) => pre.add(pcm));
      expect(pre.length, 1);
      expect(ByteData.sublistView(pre.single).getInt16(0, Endian.little), 2);
    });

    test('"Slightly sensitive" lets an accept close to the line go', () async {
      await start('slightly');
      service.send(detection(accepted: true, score: 0.93));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(detections, isEmpty);
    });

    test('"Very sensitive" takes a near miss close to the line', () async {
      await start('very');
      // A near miss carries the lower threshold near misses start from. It
      // is held against the accept threshold from the hello instead.
      service.send(detection(accepted: false, score: 0.87, threshold: 0.69));
      await _until(() => detections.isNotEmpty);
      expect(detections.single.id, 'alexa');
    });

    test('a near miss far from the line does not fire', () async {
      await start('very');
      service.send(detection(accepted: false, score: 0.80, threshold: 0.69));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(detections, isEmpty);
    });

    test('the stop word fires only while armed', () async {
      await start('moderately');
      expect(engine.supportsStopWord, isTrue);
      service.send(
        detection(keyword: 'STOP', accepted: true, score: 0.7, threshold: 0.18),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(stops, 0);

      await engine.setStopWordActive(true);
      service.send(
        detection(keyword: 'STOP', accepted: true, score: 0.7, threshold: 0.18),
      );
      await _until(() => stops == 1);
      expect(detections, isEmpty);
    });

    test('"Very sensitive" takes a stop near miss just under 0.18', () async {
      await start('very');
      await engine.setStopWordActive(true);
      // The image reports a "stop" under its 0.18 as a near miss from 0.05.
      service.send(
        detection(keyword: 'STOP', accepted: false, score: 0.12, threshold: 0.05),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(stops, 0);
      service.send(
        detection(keyword: 'STOP', accepted: false, score: 0.16, threshold: 0.05),
      );
      await _until(() => stops == 1);
    });

    test('a stop near miss does not count at the default', () async {
      await start('moderately');
      await engine.setStopWordActive(true);
      service.send(
        detection(keyword: 'STOP', accepted: false, score: 0.17, threshold: 0.05),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(stops, 0);
    });

    test('tells the service about the gap a voice turn leaves', () async {
      await start('moderately');
      mic.add(chunk(1));
      service.send(detection(accepted: true, score: 0.95));
      await _until(() => detections.isNotEmpty);
      await engine.resumeDetection();
      await _until(() => service.gaps == 1);
    });

    test('waits out a service that is restarting', () async {
      // Closing the server removes its socket file.
      await service.close();
      final starting = start('moderately');
      await Future<void>.delayed(const Duration(seconds: 2));
      service = await _FakeService.start(PryonCatalog.socketPath);
      await starting;
      expect(engine.running, isTrue);
      expect(service.started, 'alexa-en-US');
    });

    test('reports a service that will not listen', () async {
      service.refuse = true;
      await engine.start(
        config: buildWakeConfig(
          engine: WakeWordEngineType.pryon,
          activeIds: const ['alexa'],
          sensitivity: 'moderately',
          noiseGate: false,
          stopWord: false,
          pryonLocale: 'en-US',
        ),
        onDetection: (_) async {},
      );
      expect(engine.running, isFalse);
    });
  });
}

Future<void> _until(bool Function() done) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

/// biscuit-pryond as the engine sees it: the hello, then frames in and
/// JSON lines out.
class _FakeService {
  _FakeService._(this._server) {
    _server.listen(_onClient);
  }

  static Future<_FakeService> start(String path) async => _FakeService._(
    await ServerSocket.bind(
      InternetAddress(path, type: InternetAddressType.unix),
      0,
    ),
  );

  final ServerSocket _server;
  Socket? _client;
  final _buffer = BytesBuilder();

  /// Answer the start with an error.
  bool refuse = false;

  /// The models the client asked to listen with.
  String? started;
  int samples = 0;
  int gaps = 0;

  void _onClient(Socket client) {
    _client = client;
    client.write('$_hello\n');
    client.listen(_onBytes, onError: (_) {});
  }

  void _onBytes(Uint8List bytes) {
    _buffer.add(bytes);
    var data = _buffer.takeBytes();
    while (data.length >= 5) {
      final len = ByteData.sublistView(data, 1, 5).getUint32(0, Endian.little);
      if (data.length < 5 + len) break;
      final type = String.fromCharCode(data[0]);
      final payload = Uint8List.sublistView(data, 5, 5 + len);
      switch (type) {
        case 'S':
          if (refuse) {
            send({'event': 'error', 'message': 'no model to listen with'});
          } else {
            started = utf8.decode(payload);
            send({
              'event': 'started',
              'models': [started],
            });
          }
        case 'A':
          samples += len ~/ 2;
        case 'E':
          gaps++;
      }
      data = Uint8List.sublistView(data, 5 + len);
    }
    _buffer.add(data);
  }

  void send(Map<String, Object?> event) =>
      _client?.write('${jsonEncode(event)}\n');

  Future<void> close() async {
    _client?.destroy();
    await _server.close();
  }
}
