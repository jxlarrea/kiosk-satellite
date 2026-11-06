import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/sound/sound_capture.dart';
import 'package:kiosk_satellite/managers/sound/sound_manager.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _SoundPaths extends PathProviderPlatform {
  _SoundPaths(this.path);
  final String path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('kiosk_satellite/sound');
  late SoundManager sound;
  late CommandRegistry commands;
  late Logger log;
  late Directory temp;
  late HttpClient client;
  late HttpServer upstream;
  late PathProviderPlatform oldPaths;
  final calls = <MethodCall>[];
  var nativeAcceptsReplay = true;

  setUpAll(() => HttpOverrides.global = null);
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('ks_sound_diagnostics');
    oldPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _SoundPaths(temp.path);
    client = HttpClient();
    upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    calls.clear();
    nativeAcceptsReplay = true;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return call.method == 'playDiagnostic' ? nativeAcceptsReplay : true;
    });
    log = Logger();
    commands = CommandRegistry(log);
    sound = SoundManager(EventBus(), commands, log);
    await sound.init();
  });
  tearDown(() async {
    client.close(force: true);
    await sound.dispose();
    await upstream.close(force: true);
    await log.dispose();
    PathProviderPlatform.instance = oldPaths;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await temp.delete(recursive: true);
  });

  Future<CommandResult> diagnostic(String action, [String? decoder]) => commands
      .execute('soundDiagnostics', {'action': action, 'decoder': ?decoder});

  Future<void> nativeEvent(String method, Map<String, Object?> args) async {
    final done = Completer<void>();
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
      (_) => done.complete(),
    );
    await done.future;
  }

  Future<(String, Uri)> startSound() async {
    final result = await commands.execute('playSound', {
      'url': 'http://127.0.0.1:${upstream.port}/tts.mp3',
      'stream': true,
    });
    expect(result.ok, isTrue);
    final args = calls.last.arguments as Map;
    expect(args.containsKey('exoDecoder'), isFalse);
    return ((result.data as Map)['id'] as String, Uri.parse(args['source']));
  }

  Future<List<int>> download(Uri uri) async {
    final response = await (await client.getUrl(uri)).close();
    return response.fold<List<int>>([], (bytes, part) => bytes..addAll(part));
  }

  test(
    'captures exact bytes once and replays both decoders from disk',
    () async {
      final audio = List.generate(4096, (i) => i % 256);
      var requests = 0;
      upstream.listen((req) async {
        requests++;
        req.response.headers.contentType = ContentType('audio', 'mpeg');
        req.response.add(audio.take(2000).toList());
        await req.response.flush();
        req.response.add(audio.skip(2000).toList());
        await req.response.close();
      });
      await diagnostic('arm');
      final (id, uri) = await startSound();
      expect(await download(uri), audio);
      // A player retry must not append another response to the captured clip.
      expect(await download(uri), audio);
      expect((await diagnostic('replay')).ok, isFalse);
      await nativeEvent('ended', {'id': id, 'error': 'ERROR_CODE_TIMEOUT'});
      final exported = (await diagnostic('export')).data as Map;
      expect(base64Decode(exported['base64']), audio);
      expect(exported['httpComplete'], isTrue);
      expect(exported['playbackError'], 'ERROR_CODE_TIMEOUT');
      for (final decoder in ['default', 'software']) {
        final replay = await diagnostic('replay', decoder);
        expect(replay.ok, isTrue);
        final call = calls.last;
        expect(call.method, 'playDiagnostic');
        final args = call.arguments as Map;
        expect(args['exoDecoder'], decoder);
        final file = File(args['source']);
        expect(await file.readAsBytes(), audio);
        expect((await diagnostic('replay', decoder)).ok, isFalse);
        await nativeEvent('ended', {'id': (replay.data as Map)['id']});
        expect(await file.exists(), isFalse);
      }
      expect(requests, 2); // Replays do not fetch a new TTS response.
      expect(
        log.recent.any((e) => e.message.contains('HTTP upstream complete')),
        isTrue,
      );
      await diagnostic('clear');
      expect((await diagnostic('export')).ok, isFalse);
    },
  );

  test('an unfinished response is visible but cannot be replayed', () async {
    final release = Completer<void>();
    upstream.listen((req) async {
      req.response.add(Uint8List(64 * 1024));
      await req.response.flush();
      await release.future;
      await req.response.close();
    });
    await diagnostic('arm');
    final (id, uri) = await startSound();
    final response = await (await client.getUrl(uri)).close();
    final firstChunk = Completer<void>();
    final finished = Completer<void>();
    response.listen((_) {
      if (!firstChunk.isCompleted) firstChunk.complete();
    }, onDone: finished.complete);
    await firstChunk.future;
    final status = (await diagnostic('status')).data as Map;
    expect((status['capture'] as Map)['httpComplete'], isFalse);
    expect((await diagnostic('export')).ok, isFalse);
    await nativeEvent('ended', {'id': id, 'error': 'timeout'});
    expect((await diagnostic('replay')).ok, isFalse);
    release.complete();
    await finished.future;
    expect((await diagnostic('export')).ok, isTrue);
  });

  test(
    'unarmed playback keeps no capture and non-200 audio cannot replay',
    () async {
      upstream.listen((req) async {
        req.response.statusCode = 404;
        req.response.write('missing');
        await req.response.close();
      });
      final (_, first) = await startSound();
      await download(first);
      expect(((await diagnostic('status')).data as Map)['capture'], isNull);
      await diagnostic('arm');
      final (id, second) = await startSound();
      await download(second);
      await nativeEvent('ended', {'id': id});
      final capture =
          ((await diagnostic('status')).data as Map)['capture'] as Map;
      expect(capture['statusCode'], 404);
      expect(capture['httpComplete'], isTrue);
      expect((await diagnostic('export')).ok, isFalse);
      expect((await diagnostic('replay')).ok, isFalse);
    },
  );

  test('refused replay removes its file and allows another attempt', () async {
    upstream.listen((req) async {
      req.response.add([1, 2, 3]);
      await req.response.close();
    });
    await diagnostic('arm');
    final (id, uri) = await startSound();
    await download(uri);
    await nativeEvent('ended', {'id': id});
    nativeAcceptsReplay = false;
    expect((await diagnostic('replay')).ok, isFalse);
    expect(await temp.list().toList(), isEmpty);
    nativeAcceptsReplay = true;
    expect((await diagnostic('replay')).ok, isTrue);
  });

  test('native diagnostics reach App Logs', () async {
    await nativeEvent('diagnostic', {
      'id': 'snd1',
      'message': 'audio sink ended',
    });
    expect(log.recent.last.message, 'sound snd1: audio sink ended');
  });

  test('ending a sound frees a stream that has gone quiet', () async {
    // A raw socket writes at once, as Home Assistant does, and reports the
    // moment the relay lets go.
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final dropped = Completer<void>();
    server.listen((socket) {
      socket.listen(
        (_) {
          // Nothing follows, as while an agent runs a tool.
          socket.write(
            'HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n'
            '3\r\nabc\r\n',
          );
        },
        onError: (_) {},
        onDone: () {
          dropped.complete();
          socket.destroy();
        },
      );
    });
    final result = await commands.execute('playSound', {
      'url': 'http://127.0.0.1:${server.port}/tts.mp3',
      'stream': true,
    });
    final id = (result.data as Map)['id'] as String;
    final uri = Uri.parse((calls.last.arguments as Map)['source']);
    final response = await (await client.getUrl(uri)).close();
    final heard = Completer<void>();
    final read = Completer<void>();
    response.listen(
      (_) {
        if (!heard.isCompleted) heard.complete();
      },
      onError: (_) {
        if (!read.isCompleted) read.complete();
      },
      onDone: () {
        if (!read.isCompleted) read.complete();
      },
      cancelOnError: false,
    );
    // What was said reaches the player while the stream is quiet.
    await heard.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () => fail('the audio stayed in the relay'),
    );
    expect(read.isCompleted, isFalse);
    await nativeEvent('ended', {'id': id});
    await read.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () => fail('the player read stayed blocked'),
    );
    await dropped.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () => fail('the upstream stayed open'),
    );
    expect(log.recent.any((e) => e.message.contains('relay failed')), isFalse);
  });

  test('a truncated HTTP body is discarded and the relay closes', () async {
    upstream.listen((req) async {
      final socket = await req.response.detachSocket(writeHeaders: false);
      socket.write(
        'HTTP/1.1 200 OK\r\nContent-Length: 100\r\n'
        'Content-Type: audio/mpeg\r\nConnection: close\r\n\r\nabc',
      );
      await socket.flush();
      await socket.close();
    });
    await diagnostic('arm');
    final (id, uri) = await startSound();
    await expectLater(download(uri), throwsA(isA<HttpException>()));
    await nativeEvent('ended', {'id': id, 'error': 'load failed'});
    final capture =
        ((await diagnostic('status')).data as Map)['capture'] as Map;
    expect(capture['error'], 'HTTP transfer failed');
    expect(capture['ready'], isFalse);
    expect((await diagnostic('export')).ok, isFalse);
    expect((await diagnostic('replay')).ok, isFalse);
    expect(
      log.recent.any((e) => e.message.contains('HTTP upstream complete')),
      isFalse,
    );
  });

  test(
    'oversized and cleared captures release audio and ignore later chunks',
    () {
      final capture = SoundCapture('test')..statusCode = 200;
      capture.add(Uint8List(SoundCapture.maxBytes));
      capture.add([1]);
      capture.httpComplete = true;
      expect(capture.ready, isFalse);
      expect(capture.audio, isEmpty);
      expect(capture.error, contains('exceeded'));
      capture.add([2, 3]);
      expect(capture.audio, isEmpty);
      final cleared = SoundCapture('clear')..add([1, 2]);
      cleared.discard('cleared');
      cleared.add([3]);
      expect(cleared.audio, isEmpty);
    },
  );
}
