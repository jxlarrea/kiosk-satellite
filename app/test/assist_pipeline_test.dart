import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/assist_pipeline/assist_pipeline_manager.dart';
import 'package:kiosk_satellite/managers/assist_pipeline/native_audio_source.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The native pipeline transport (docs/js-api.md, "Pipeline delegation")
/// against a real local websocket speaking the HA auth + subscription
/// protocol: subscribe payloads, verbatim event forwarding, the
/// buffer/mute/send gating the page's choreography depends on, binary
/// frame framing, and the mid-run death signal.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHaServer server;
  late _FakeMic mic;
  late EventBus bus;
  late CommandRegistry commands;
  late AssistPipelineManager pipeline;

  Future<void> build({bool enabled = true, String token = 'tok'}) async {
    server = await _FakeHaServer.start();
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://127.0.0.1:${server.port}',
      'ks.ha.token': token,
      'ks.vs.native_pipeline': enabled,
    });
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    mic = _FakeMic();
    pipeline = AssistPipelineManager(bus, commands, log, settings, mic);
    await pipeline.init();
  }

  tearDown(() async {
    await pipeline.dispose();
    await server.close();
  });

  Uint8List pcm(List<int> samples) {
    final bytes = Uint8List(samples.length * 2);
    final data = ByteData.view(bytes.buffer);
    for (var i = 0; i < samples.length; i++) {
      data.setInt16(i * 2, samples[i], Endian.little);
    }
    return bytes;
  }

  /// A loud-ish alternating chunk, so the speech-weighted level is nonzero.
  Uint8List loudChunk() =>
      pcm(List.generate(320, (i) => i.isEven ? 8000 : -8000));

  test('a run subscribes with auth, forwards events, uploads framed audio',
      () async {
    await build();

    final events = <PipelineEvent>[];
    final levels = <PipelineMicLevel>[];
    bus.on<PipelineEvent>().listen(events.add);
    bus.on<PipelineMicLevel>().listen(levels.add);

    final open = await commands.execute('pipelineOpenMic', const {});
    expect(open.ok, isTrue);
    expect((open.data as Map)['sampleRate'], 16000);

    final run = await commands.execute('pipelineRun', const {
      'entity_id': 'assist_satellite.office_tablet',
      'start_stage': 'stt',
      'end_stage': 'tts',
      'sample_rate': 16000,
      'wake_word_phrase': 'Okay Nabu',
    });
    expect(run.ok, isTrue);
    final runId = (run.data as Map)['runId'] as String;

    // The server authenticated us and saw the subscribe payload verbatim.
    expect(server.authedTokens, ['tok']);
    final sub = await server.nextJson((m) => m['type'] == 'voice_satellite/run_pipeline');
    expect(sub['entity_id'], 'assist_satellite.office_tablet');
    expect(sub['start_stage'], 'stt');
    expect(sub['wake_word_phrase'], 'Okay Nabu');
    expect(sub.containsKey('conversation_id'), isFalse,
        reason: 'absent options must not be sent as nulls');

    // Events forward verbatim, the synthetic init included.
    server.sendEvent(sub['id'] as int, {'type': 'init', 'handler_id': 7});
    server.sendEvent(sub['id'] as int, {'type': 'run-start', 'data': {}});
    await _until(() => events.length >= 2);
    expect(events[0].runId, runId);
    expect(events[0].message['type'], 'init');
    expect(events[1].message['type'], 'run-start');

    // Not sending, not buffering: chunks are dropped, but levels flow.
    mic.feed(loudChunk());
    await commands.execute('pipelineStartSending', {'runId': runId});
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(server.binaryFrames, isEmpty,
        reason: 'audio from before sending started must not upload');

    // Sending: chunks upload as [handler_id][PCM16] frames.
    final chunk = loudChunk();
    mic.feed(chunk);
    await _until(() => server.binaryFrames.isNotEmpty);
    expect(server.binaryFrames.first[0], 7);
    expect(server.binaryFrames.first.sublist(1), chunk);
    await _until(() => levels.isNotEmpty);
    expect(levels.last.level, greaterThan(0));

    // Muted: dropped on arrival, never buffered, level zeroed.
    server.binaryFrames.clear();
    await commands.execute('pipelineSetMuted', const {'muted': true});
    mic.feed(loudChunk());
    await commands.execute('pipelineSetMuted', const {'muted': false});
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(server.binaryFrames, isEmpty,
        reason: 'the chime window must never reach STT');

    // Stopping unsubscribes.
    await commands.execute('pipelineStop', {'runId': runId});
    final unsub = await server.nextJson((m) => m['type'] == 'unsubscribe_events');
    expect(unsub['subscription'], sub['id']);
  });

  test('buffered audio (the seamless window) uploads before live audio',
      () async {
    await build();
    await commands.execute('pipelineOpenMic', const {});
    // The seamless wake path arms buffering BEFORE the run exists.
    await commands.execute('pipelineStartBuffering', const {'reset': true});
    final preRollChunk = pcm(List.filled(320, 1000));
    mic.feed(preRollChunk, preRoll: true);

    final run = await commands.execute('pipelineRun', const {
      'entity_id': 'assist_satellite.office_tablet',
      'start_stage': 'stt',
      'end_stage': 'tts',
      'sample_rate': 16000,
    });
    final runId = (run.data as Map)['runId'] as String;
    final sub = await server.nextJson((m) => m['type'] == 'voice_satellite/run_pipeline');
    server.sendEvent(sub['id'] as int, {'type': 'init', 'handler_id': 3});

    await commands.execute('pipelineStartSending', {'runId': runId});
    await _until(() => server.binaryFrames.isNotEmpty);
    expect(server.binaryFrames.first[0], 3);
    expect(server.binaryFrames.first.sublist(1), preRollChunk,
        reason: 'the pre-roll buffered during the seamless window leads');
  });

  test('clearing the buffer drops the chime-window audio', () async {
    await build();
    await commands.execute('pipelineOpenMic', const {});
    await commands.execute('pipelineStartBuffering', const {'reset': true});
    mic.feed(loudChunk());
    await commands.execute('pipelineClearBuffer', const {});

    final run = await commands.execute('pipelineRun', const {
      'entity_id': 'assist_satellite.office_tablet',
      'start_stage': 'stt',
      'end_stage': 'tts',
      'sample_rate': 16000,
    });
    final sub = await server.nextJson((m) => m['type'] == 'voice_satellite/run_pipeline');
    server.sendEvent(sub['id'] as int, {'type': 'init', 'handler_id': 3});
    await commands
        .execute('pipelineStartSending', {'runId': (run.data as Map)['runId']});
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(server.binaryFrames, isEmpty);
  });

  test('a socket death mid-run tells the page', () async {
    await build();
    final closed = <PipelineClosed>[];
    bus.on<PipelineClosed>().listen(closed.add);

    final run = await commands.execute('pipelineRun', const {
      'entity_id': 'assist_satellite.office_tablet',
      'start_stage': 'stt',
      'end_stage': 'tts',
      'sample_rate': 16000,
    });
    expect(run.ok, isTrue);

    await server.dropClients();
    await _until(() => closed.isNotEmpty);
    expect(closed.single.runId, (run.data as Map)['runId']);

    // And the next run reconnects on its own.
    final again = await commands.execute('pipelineRun', const {
      'entity_id': 'assist_satellite.office_tablet',
      'start_stage': 'stt',
      'end_stage': 'tts',
      'sample_rate': 16000,
    });
    expect(again.ok, isTrue);
    expect(server.authedTokens.length, 2);
  });

  test('the Native voice pipeline setting off refuses everything', () async {
    await build(enabled: false);
    expect((await commands.execute('pipelineRun', const {
      'entity_id': 'x',
      'start_stage': 'stt',
      'end_stage': 'tts',
      'sample_rate': 16000,
    }))
        .ok, isFalse);
    expect((await commands.execute('pipelineOpenMic', const {})).ok, isFalse);
    expect(server.authedTokens, isEmpty);
  });

  test('a mic the engine cannot provide refuses the open', () async {
    await build();
    mic.available = false;
    expect((await commands.execute('pipelineOpenMic', const {})).ok, isFalse);
  });
}

Future<void> _until(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not met within 5s');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _FakeMic implements NativeAudioSource {
  void Function(Uint8List pcm, bool preRoll)? onChunk;
  bool available = true;

  @override
  Future<bool> openNativeAudioStream(
      void Function(Uint8List pcm, bool preRoll) onChunk) async {
    if (!available) return false;
    this.onChunk = onChunk;
    return true;
  }

  @override
  Future<void> closeNativeAudioStream() async {
    onChunk = null;
  }

  void feed(Uint8List pcm, {bool preRoll = false}) => onChunk?.call(pcm, preRoll);
}

/// A minimal Home Assistant websocket: auth handshake, JSON command replies
/// (success for everything), and capture of JSON + binary traffic.
class _FakeHaServer {
  _FakeHaServer._(this._http);

  final HttpServer _http;
  final List<WebSocket> _clients = [];
  final List<String> authedTokens = [];
  final List<Map<String, dynamic>> jsonMessages = [];
  final List<Uint8List> binaryFrames = [];

  int get port => _http.port;

  static Future<_FakeHaServer> start() async {
    final http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final server = _FakeHaServer._(http);
    http.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      server._clients.add(socket);
      socket.add(jsonEncode({'type': 'auth_required'}));
      socket.listen((raw) {
        if (raw is String) {
          final msg = jsonDecode(raw) as Map<String, dynamic>;
          if (msg['type'] == 'auth') {
            server.authedTokens.add('${msg['access_token']}');
            socket.add(jsonEncode({'type': 'auth_ok'}));
            return;
          }
          server.jsonMessages.add(msg);
          socket.add(jsonEncode({
            'id': msg['id'],
            'type': 'result',
            'success': true,
            'result': null,
          }));
        } else if (raw is List<int>) {
          server.binaryFrames.add(Uint8List.fromList(raw));
        }
      });
    });
    return server;
  }

  /// The next (or an already-received) JSON message matching [test].
  Future<Map<String, dynamic>> nextJson(
      bool Function(Map<String, dynamic>) test) async {
    await _until(() => jsonMessages.any(test));
    return jsonMessages.firstWhere(test);
  }

  void sendEvent(int id, Map<String, Object?> event) {
    for (final socket in _clients) {
      socket.add(jsonEncode({'id': id, 'type': 'event', 'event': event}));
    }
  }

  Future<void> dropClients() async {
    for (final socket in _clients) {
      await socket.close();
    }
    _clients.clear();
  }

  Future<void> close() async {
    await dropClients();
    await _http.close(force: true);
  }
}
