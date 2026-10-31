import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiosk_satellite/managers/voice/assist_view.dart';
import 'package:kiosk_satellite/managers/voice/realtime/gemini_live_backend.dart';
import 'package:kiosk_satellite/managers/voice/realtime/mcp_client.dart';
import 'package:kiosk_satellite/managers/voice/realtime/openai_realtime_backend.dart';
import 'package:kiosk_satellite/managers/voice/realtime/pcm_resampler.dart';
import 'package:kiosk_satellite/managers/voice/realtime/realtime_backend.dart';
import 'package:kiosk_satellite/managers/voice/realtime/realtime_history.dart';
import 'package:kiosk_satellite/managers/voice/realtime/realtime_player.dart';
import 'package:kiosk_satellite/managers/voice/realtime/realtime_session.dart';
import 'package:kiosk_satellite/managers/voice/realtime/realtime_tools.dart';
import 'package:kiosk_satellite/managers/voice/voice_manager.dart'
    show realtimeLocationLine;
import 'package:kiosk_satellite/managers/voice/voice_session.dart';

Uint8List _pcm(List<int> samples) {
  final out = Uint8List(samples.length * 2);
  final view = ByteData.sublistView(out);
  for (var i = 0; i < samples.length; i++) {
    view.setInt16(i * 2, samples[i], Endian.little);
  }
  return out;
}

List<int> _samples(Uint8List pcm) {
  final view = ByteData.sublistView(pcm);
  return [
    for (var i = 0; i < pcm.length ~/ 2; i++)
      view.getInt16(i * 2, Endian.little),
  ];
}

// ── the socket and the tools ──────────────────────────────────────────────

class _Socket implements RealtimeSocket {
  final incoming = StreamController<Object?>();
  final sent = <Map<String, Object?>>[];
  bool closed = false;

  @override
  Stream<Object?> get messages => incoming.stream;

  @override
  void send(String message) =>
      sent.add((jsonDecode(message) as Map).cast<String, Object?>());

  @override
  Future<void> close() async {
    closed = true;
    await incoming.close();
  }

  /// What the peer gave when it closed.
  String? reason;

  @override
  String? get closeReason => reason;

  void server(Map<String, Object?> event) => incoming.add(jsonEncode(event));

  List<String> get types => [for (final m in sent) '${m['type']}'];
}

class _Tools implements RealtimeToolbox {
  final calls = <(String, Map<String, Object?>)>[];
  Completer<void>? gate;
  bool fail = false;

  @override
  Future<List<RealtimeToolSpec>> list() async => const [
    RealtimeToolSpec(
      name: 'intent__HassTurnOn',
      description: 'Turns on',
      parameters: {'type': 'object', 'properties': <String, Object?>{}},
    ),
    RealtimeToolSpec(
      name: LocalToolbox.endConversation,
      description: 'End',
      parameters: {'type': 'object', 'properties': <String, Object?>{}},
    ),
  ];

  @override
  Future<RealtimeToolOutput> call(
    String name,
    Map<String, Object?> args,
  ) async {
    calls.add((name, args));
    await gate?.future;
    if (name == LocalToolbox.endConversation) {
      return const RealtimeToolOutput('{}', endConversation: true);
    }
    if (fail) {
      return const RealtimeToolOutput(
        '{"error": "no such entity"}',
        error: true,
      );
    }
    return const RealtimeToolOutput('{"success": true}');
  }

  @override
  String originalName(String name) => name;

  @override
  void close() {}
}

// ── the session's ports ───────────────────────────────────────────────────

class _Backend implements RealtimeBackend {
  final _events = StreamController<RealtimeEvent>();
  final audio = <Uint8List>[];
  final interruptions = <(String, int)>[];
  final turns = <bool>[];
  final spoken = <String>[];
  RealtimeStart? started;
  bool closed = false;
  bool clientTurns = false;

  @override
  RealtimeCapabilities get capabilities =>
      RealtimeCapabilities(clientTurns: clientTurns);

  @override
  void userTurn({required bool keep}) => turns.add(keep);

  @override
  void speak(String line) => spoken.add(line);

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  Future<void> start(RealtimeStart start) async => started = start;

  @override
  void sendAudio(Uint8List pcm) => audio.add(pcm);

  @override
  void interrupted(String itemId, int playedMs) =>
      interruptions.add((itemId, playedMs));

  @override
  Future<void> close() async {
    closed = true;
    await _events.close();
  }

  void emit(RealtimeEvent event) => _events.add(event);
}

class _Mic implements VoiceMicPort {
  void Function(Uint8List pcm, bool preRoll)? sink;
  int closes = 0;

  @override
  Future<bool> open(void Function(Uint8List pcm, bool preRoll) onChunk) async {
    sink = onChunk;
    return true;
  }

  @override
  Future<void> close() async {
    closes++;
    sink = null;
  }

  /// 80 ms at 16 kHz.
  void speak({int value = 1000, bool preRoll = false}) =>
      sink?.call(_pcm(List.filled(1280, value)), preRoll);
}

class _Player implements RealtimePlayerPort {
  final written = <Uint8List>[];

  /// Frames the fake track has played, moved by the test.
  int frames = 0;
  int flushes = 0;
  bool open = false;
  int? rate;

  @override
  Future<bool> start(int sampleRate) async {
    rate = sampleRate;
    return open = true;
  }

  @override
  void write(Uint8List pcm) => written.add(pcm);

  @override
  Future<int> flush() async {
    flushes++;
    return frames;
  }

  @override
  Future<int> played() async => frames;

  @override
  Future<void> stop() async => open = false;
}

class _Chimes implements VoicePlayerPort {
  final chimes = <String>[];
  int settled = 0;

  @override
  Future<(String, double)?> chime(String kind) async {
    chimes.add(kind);
    return ('c${chimes.length}', 0.3);
  }

  @override
  Future<String?> play(
    String url, {
    String text = '',
    bool announcement = false,
  }) async => null;

  @override
  Future<void> stop(String id) async {}

  @override
  Future<void> settle() async => settled++;
}

class _Harness {
  _Harness(this.time, {this.options = const RealtimeOptions(), this.location}) {
    session = RealtimeSession(
      location: location,
      // A new backend once a conversation closed its own, as the app
      // makes one per conversation.
      backend: () => backend.closed
          ? backend = (_Backend()..clientTurns = backend.clientTurns)
          : backend,
      mic: mic,
      player: player,
      chimes: chimes,
      options: () => options,
      onView: views.add,
      onLevel: (_) {},
      onCountdown: countdown.add,
      onBusy: (busy, _) => busy_.add(busy),
      onStopArmed: stopArmed.add,
      onError: (code, _) => errors.add(code),
      onIdle: () => idles++,
      onTrace: (step, {text}) => traces.add(step),
      now: () => DateTime(2026).add(time.elapsed),
    );
  }

  final FakeAsync time;
  RealtimeOptions options;
  final Future<String> Function()? location;
  late final RealtimeSession session;
  var backend = _Backend();
  final mic = _Mic();
  final player = _Player();
  final chimes = _Chimes();
  final views = <AssistView>[];
  final countdown = <double>[];
  final busy_ = <bool>[];
  final stopArmed = <bool>[];
  final errors = <String>[];
  final traces = <String>[];
  int idles = 0;

  AssistView get view => views.last;

  /// Wakes, lets the chime pass and brings the backend up.
  void wakeAndConnect() {
    unawaited(session.wake('Hey Jarvis'));
    time.flushMicrotasks();
    time.elapse(const Duration(milliseconds: 600));
    backend.emit(const RealtimeReady());
    time.flushMicrotasks();
  }

  /// One second of the model's voice at 24 kHz.
  void answer(String item, {int seconds = 1}) {
    backend.emit(const RealtimeResponseStarted());
    backend.emit(RealtimeAudio(item, _pcm(List.filled(24000 * seconds, 3000))));
    time.flushMicrotasks();
  }
}

void main() {
  group('PcmResampler', () {
    test('16 kHz to 24 kHz makes three samples of every two', () {
      final r = PcmResampler(from: 16000, to: 24000);
      var total = 0;
      for (var i = 0; i < 10; i++) {
        total += r.convert(_pcm(List.filled(1280, 100))).length ~/ 2;
      }
      // 12800 in, 19200 out, give or take the last carried sample.
      expect(total, closeTo(19200, 2));
    });

    test('interpolates across chunk edges', () {
      final r = PcmResampler(from: 16000, to: 24000);
      final a = _samples(r.convert(_pcm([0, 300])));
      final b = _samples(r.convert(_pcm([600, 900])));
      final all = [...a, ...b];
      // A straight ramp stays a straight ramp at 200 per output sample.
      for (var i = 1; i < all.length; i++) {
        expect(all[i] - all[i - 1], 200);
      }
    });

    test('the same rate passes through', () {
      final r = PcmResampler(from: 24000, to: 24000);
      final pcm = _pcm([1, 2, 3]);
      expect(r.convert(pcm), same(pcm));
    });
  });

  group('McpClient', () {
    test(
      'initializes once, keeps the session and reads an event stream',
      () async {
        final requests = <Map<String, Object?>>[];
        final sessions = <String?>[];
        final client = MockClient.streaming((request, body) async {
          final text = await body.bytesToString();
          final json = (jsonDecode(text) as Map).cast<String, Object?>();
          requests.add(json);
          sessions.add(request.headers['Mcp-Session-Id']);
          expect(request.headers['Authorization'], 'Bearer tok');
          switch (json['method']) {
            case 'initialize':
              return http.StreamedResponse(
                Stream.value(
                  utf8.encode(
                    jsonEncode({
                      'jsonrpc': '2.0',
                      'id': json['id'],
                      'result': {'protocolVersion': '2025-06-18'},
                    }),
                  ),
                ),
                200,
                headers: {
                  'content-type': 'application/json',
                  'mcp-session-id': 'sess1',
                },
              );
            case 'notifications/initialized':
              return http.StreamedResponse(const Stream.empty(), 202);
            case 'tools/list':
              final event =
                  'event: message\ndata: ${jsonEncode({
                    'jsonrpc': '2.0',
                    'id': json['id'],
                    'result': {
                      'tools': [
                        {
                          'name': 'HassTurnOn',
                          'description': 'Turns on a device',
                          'inputSchema': {'type': 'object', 'properties': {}},
                        },
                      ],
                    },
                  })}\n\n';
              return http.StreamedResponse(
                Stream.value(utf8.encode(event)),
                200,
                headers: {'content-type': 'text/event-stream'},
              );
            case 'tools/call':
              return http.StreamedResponse(
                Stream.value(
                  utf8.encode(
                    jsonEncode({
                      'jsonrpc': '2.0',
                      'id': json['id'],
                      'result': {
                        'content': [
                          {'type': 'text', 'text': 'done'},
                        ],
                      },
                    }),
                  ),
                ),
                200,
                headers: {'content-type': 'application/json'},
              );
          }
          return http.StreamedResponse(const Stream.empty(), 400);
        });
        final mcp = McpClient(
          url: Uri.parse('http://ha/api/mcp'),
          token: 'tok',
          client: client,
        );
        final tools = await mcp.listTools();
        expect(tools.single.name, 'HassTurnOn');
        final result = await mcp.callTool('HassTurnOn', {'name': 'Kitchen'});
        expect(result.text, 'done');
        expect(result.error, isFalse);
        expect(
          [for (final r in requests) r['method']],
          [
            'initialize',
            'notifications/initialized',
            'tools/list',
            'tools/call',
          ],
        );
        // The session the server gave rides every request after it.
        expect(sessions.skip(1), everyElement('sess1'));
      },
    );

    test('the device rides tools/list and tools/call as _meta', () async {
      final params = <String, Map<String, Object?>>{};
      final client = MockClient((request) async {
        final json = (jsonDecode(request.body) as Map).cast<String, Object?>();
        final method = '${json['method']}';
        params[method] = ((json['params'] ?? {}) as Map)
            .cast<String, Object?>();
        if (method.startsWith('notifications/')) return http.Response('', 202);
        final result = switch (method) {
          'tools/list' => {'tools': <Object?>[]},
          'tools/call' => {'content': <Object?>[]},
          _ => <String, Object?>{},
        };
        return http.Response(
          jsonEncode({'jsonrpc': '2.0', 'id': json['id'], 'result': result}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final mcp = McpClient(
        url: Uri.parse('http://ha/api/mcp'),
        client: client,
        deviceId: () async => 'dev1',
      );
      await mcp.listTools();
      await mcp.callTool('HassStartTimer', {'minutes': 5});
      const meta = {McpClient.deviceMetaKey: 'dev1'};
      expect(params['tools/list']!['_meta'], meta);
      expect(params['tools/call']!['_meta'], meta);
      expect(params['initialize']!.containsKey('_meta'), isFalse);

      // No device, or a failed lookup, sends no _meta.
      for (final lookup in <Future<String?> Function()>[
        () async => null,
        () async => throw StateError('offline'),
      ]) {
        params.clear();
        await McpClient(
          url: Uri.parse('http://ha/api/mcp'),
          client: client,
          deviceId: lookup,
        ).listTools();
        expect(params['tools/list']!.containsKey('_meta'), isFalse);
      }
    });

    group('the device rides script calls', () {
      late List<Map<String, Object?>> calls;
      late Map<String, Object?> Function(Map<String, Object?> args) answer;

      MockClient server() => MockClient((request) async {
        final json = (jsonDecode(request.body) as Map).cast<String, Object?>();
        final method = '${json['method']}';
        if (method.startsWith('notifications/')) return http.Response('', 202);
        final params = ((json['params'] ?? {}) as Map).cast<String, Object?>();
        final result = switch (method) {
          'tools/list' => {
            'tools': [
              for (final name in [
                'script__probe',
                'assist__script__probe',
                'assist__HassTurnOn',
                'HassTurnOn',
              ])
                {
                  'name': name,
                  'description': '',
                  'inputSchema': {
                    'type': 'object',
                    'properties': {
                      'room': {'type': 'string'},
                      McpClient.scriptDeviceArgument: {'type': 'string'},
                    },
                    'required': ['room', McpClient.scriptDeviceArgument],
                  },
                },
            ],
          },
          'tools/call' => answer(
            (calls..add(params)).last['arguments']! as Map<String, Object?>,
          ),
          _ => <String, Object?>{},
        };
        return http.Response(
          jsonEncode({'jsonrpc': '2.0', 'id': json['id'], 'result': result}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      Map<String, Object?> text(String text, {bool error = false}) => {
        'content': [
          {'type': 'text', 'text': text},
        ],
        'isError': error,
      };

      setUp(() {
        calls = [];
        answer = (_) => text('done');
      });

      test('as an argument the model never sees', () async {
        final mcp = McpClient(
          url: Uri.parse('http://ha/api/mcp'),
          client: server(),
          deviceId: () async => 'dev1',
        );
        final tools = {for (final t in await mcp.listTools()) t.name: t};
        // A script that declares the field gets it from the kiosk.
        final script = tools['script__probe']!.inputSchema;
        expect((script['properties']! as Map).keys, ['room']);
        expect(script['required'], ['room']);
        // Any other tool is left as the server sent it.
        expect(
          (tools['HassTurnOn']!.inputSchema['properties']! as Map).keys,
          contains(McpClient.scriptDeviceArgument),
        );

        // The kiosk's device wins over one the model made up.
        await mcp.callTool('script__probe', {
          'room': 'Kitchen',
          McpClient.scriptDeviceArgument: 'made_up',
        });
        await mcp.callTool('HassTurnOn', {'name': 'Kitchen'});
        expect(calls[0]['arguments'], {
          'room': 'Kitchen',
          McpClient.scriptDeviceArgument: 'dev1',
        });
        expect(calls[1]['arguments'], {'name': 'Kitchen'});
      });

      test('when the server puts the API name in front', () async {
        final mcp = McpClient(
          url: Uri.parse('http://ha/api/mcp'),
          client: server(),
          deviceId: () async => 'dev1',
        );
        final tools = {for (final t in await mcp.listTools()) t.name: t};
        final script = tools['assist__script__probe']!.inputSchema;
        expect((script['properties']! as Map).keys, ['room']);
        expect(
          (tools['assist__HassTurnOn']!.inputSchema['properties']! as Map).keys,
          contains(McpClient.scriptDeviceArgument),
        );

        await mcp.callTool('assist__script__probe', {'room': 'Kitchen'});
        await mcp.callTool('assist__HassTurnOn', {'name': 'Kitchen'});
        expect(calls[0]['arguments'], {
          'room': 'Kitchen',
          McpClient.scriptDeviceArgument: 'dev1',
        });
        expect(calls[1]['arguments'], {'name': 'Kitchen'});
      });

      test('not on a server without a device', () async {
        final mcp = McpClient(
          url: Uri.parse('http://ha/api/mcp'),
          client: server(),
        );
        final tools = await mcp.listTools();
        expect(
          (tools.first.inputSchema['properties']! as Map).keys,
          contains(McpClient.scriptDeviceArgument),
        );
        await mcp.callTool('script__probe', {'room': 'Kitchen'});
        expect(calls.single['arguments'], {'room': 'Kitchen'});
      });

      test(
        'runs the script again without it only when it was refused',
        () async {
          answer = (args) => args.containsKey(McpClient.scriptDeviceArgument)
              ? text(
                  'Error calling tool: extra keys not allowed @ '
                  "data['${McpClient.scriptDeviceArgument}']",
                  error: true,
                )
              : text('done');
          final mcp = McpClient(
            url: Uri.parse('http://ha/api/mcp'),
            client: server(),
            deviceId: () async => 'dev1',
          );
          final result = await mcp.callTool('script__probe', {
            'room': 'Kitchen',
          });
          expect(result.text, 'done');
          expect(result.error, isFalse);
          expect(calls.last['arguments'], {'room': 'Kitchen'});
          expect(calls, hasLength(2));

          // A script that failed on its own is never run twice.
          calls.clear();
          answer = (_) => text(
            'Error calling tool: no device ${McpClient.scriptDeviceArgument}',
            error: true,
          );
          final failed = await mcp.callTool('script__probe', {'room': 'Hall'});
          expect(failed.error, isTrue);
          expect(calls, hasLength(1));
        },
      );
    });

    test('an HTTP error says so', () async {
      final mcp = McpClient(
        url: Uri.parse('http://ha/api/mcp'),
        client: MockClient((_) async => http.Response('nope', 401)),
      );
      await expectLater(
        mcp.listTools(),
        throwsA(isA<McpException>().having((e) => e.status, 'status', 401)),
      );
    });
  });

  group('McpToolbox', () {
    test('model names are safe and map back', () {
      expect(McpToolbox.safeName('light__HassLightSet'), 'light__HassLightSet');
      expect(McpToolbox.safeName('weird name.v2'), 'weird_name_v2');
      expect(McpToolbox.safeName('x' * 80).length, 64);
    });
  });

  group('OpenAiRealtimeBackend', () {
    late _Socket socket;
    late _Tools tools;
    late List<RealtimeEvent> events;
    Uri? url;
    Map<String, String>? headers;

    OpenAiRealtimeBackend make(RealtimeConfig config) {
      socket = _Socket();
      tools = _Tools();
      events = [];
      final backend = OpenAiRealtimeBackend(
        config: config,
        toolbox: tools,
        connector: (u, h) async {
          url = u;
          headers = h;
          return socket;
        },
      );
      backend.events.listen(events.add);
      return backend;
    }

    test('OpenAI: the model in the query and the GA session shape', () async {
      final backend = make(
        const RealtimeConfig(provider: RealtimeProvider.openai, apiKey: 'sk'),
      );
      await backend.start(const RealtimeStart(language: 'es'));
      expect(
        url.toString(),
        'wss://api.openai.com/v1/realtime?model=gpt-realtime',
      );
      expect(headers?['Authorization'], 'Bearer sk');
      final session = socket.sent.first['session'] as Map;
      expect(session['type'], 'realtime');
      final audio = session['audio'] as Map;
      expect((audio['output'] as Map)['voice'], 'marin');
      final input = audio['input'] as Map;
      expect((input['format'] as Map)['rate'], 24000);
      // The session takes the turns: speech neither stops nor gets a reply
      // on its own.
      expect((input['turn_detection'] as Map)['interrupt_response'], false);
      expect((input['turn_detection'] as Map)['create_response'], false);
      expect((input['transcription'] as Map)['language'], 'es');
      expect((session['tools'] as List).length, 2);
      await backend.close();
    });

    test('speech speed goes in audio.output, left out at 1', () async {
      for (final provider in [RealtimeProvider.openai, RealtimeProvider.xai]) {
        var backend = make(RealtimeConfig(provider: provider, speed: 1.25));
        await backend.start(const RealtimeStart());
        var audio = (socket.sent.first['session'] as Map)['audio'] as Map;
        expect((audio['output'] as Map)['speed'], 1.25);
        await backend.close();

        backend = make(RealtimeConfig(provider: provider));
        await backend.start(const RealtimeStart());
        audio = (socket.sent.first['session'] as Map)['audio'] as Map;
        expect((audio['output'] as Map).containsKey('speed'), isFalse);
        await backend.close();
      }
    });

    test('reasoning effort goes to OpenAI only, left out when empty', () async {
      var backend = make(
        const RealtimeConfig(
          provider: RealtimeProvider.openai,
          reasoning: 'high',
        ),
      );
      await backend.start(const RealtimeStart());
      expect((socket.sent.first['session'] as Map)['reasoning'], {
        'effort': 'high',
      });
      await backend.close();

      backend = make(const RealtimeConfig(provider: RealtimeProvider.openai));
      await backend.start(const RealtimeStart());
      expect(
        (socket.sent.first['session'] as Map).containsKey('reasoning'),
        isFalse,
      );
      await backend.close();

      // xAI refuses the whole session.update over the field.
      backend = make(
        const RealtimeConfig(provider: RealtimeProvider.xai, reasoning: 'high'),
      );
      await backend.start(const RealtimeStart());
      expect(
        (socket.sent.first['session'] as Map).containsKey('reasoning'),
        isFalse,
      );
      await backend.close();
    });

    test('where the kiosk is joins the instructions, with xAI the earlier '
        'exchanges too', () async {
      const history = [
        RealtimeTurn(user: true, text: 'Dim the kitchen'),
        RealtimeTurn(user: false, text: 'Done.'),
      ];
      for (final provider in [RealtimeProvider.openai, RealtimeProvider.xai]) {
        final backend = make(
          RealtimeConfig(provider: provider, instructions: 'Be brief.'),
        );
        await backend.start(
          const RealtimeStart(
            context: 'This kiosk is in the Kitchen area.',
            history: history,
          ),
        );
        final instructions =
            (socket.sent.first['session'] as Map)['instructions'] as String;
        if (provider == RealtimeProvider.xai) {
          expect(
            instructions,
            'Be brief.\n\n${realtimeContextText(context: 'This kiosk is in the Kitchen area.', history: history)}',
          );
          expect(
            instructions,
            endsWith('User: Dim the kitchen\nAssistant: Done.'),
          );
          expect(socket.sent, hasLength(1));
        } else {
          expect(
            instructions,
            'Be brief.\n\nThis kiosk is in the Kitchen area.',
          );
        }
        await backend.close();
      }
      // Neither: the instructions alone.
      final backend = make(
        const RealtimeConfig(provider: RealtimeProvider.openai),
      );
      await backend.start(const RealtimeStart());
      expect(
        (socket.sent.first['session'] as Map)['instructions'],
        OpenAiRealtimeBackend.defaultInstructions,
      );
      expect(socket.sent, hasLength(1));
      await backend.close();
    });

    test(
      'OpenAI: earlier exchanges replay as the conversation\'s items',
      () async {
        final backend = make(
          const RealtimeConfig(provider: RealtimeProvider.openai),
        );
        await backend.start(
          const RealtimeStart(
            history: [
              RealtimeTurn(user: true, text: 'Turn on the AC.'),
              RealtimeTurn(user: false, text: 'The office AC is now on.'),
            ],
          ),
        );
        expect(socket.sent.first['type'], 'session.update');
        expect(socket.sent.skip(1).toList(), [
          {
            'type': 'conversation.item.create',
            'item': {
              'type': 'message',
              'role': 'user',
              'content': [
                {'type': 'input_text', 'text': 'Turn on the AC.'},
              ],
            },
          },
          {
            'type': 'conversation.item.create',
            'item': {
              'type': 'message',
              'role': 'assistant',
              'content': [
                {'type': 'output_text', 'text': 'The office AC is now on.'},
              ],
            },
          },
        ]);
        await backend.close();
      },
    );

    test('Azure: the key goes in the api-key header', () async {
      final backend = make(
        const RealtimeConfig(
          provider: RealtimeProvider.openai,
          endpoint: 'https://res.openai.azure.com/openai/v1/realtime?model=dep',
          apiKey: 'az',
        ),
      );
      await backend.start(const RealtimeStart());
      expect(
        url.toString(),
        'wss://res.openai.azure.com/openai/v1/realtime?model=dep',
      );
      expect(headers, {'api-key': 'az'});
      await backend.close();
    });

    test('a failed connection never shows a key in the address', () async {
      final backend = OpenAiRealtimeBackend(
        config: const RealtimeConfig(
          provider: RealtimeProvider.openai,
          apiKey: 'sk',
        ),
        toolbox: _Tools(),
        connector: (u, h) async => throw ArgumentError(
          "Unsupported scheme 'wss' in URI "
          'wss://res.openai.azure.com/v1/realtime?model=m&api-key=secret',
        ),
      );
      final closed = backend.events.firstWhere((e) => e is RealtimeClosed);
      await backend.start(const RealtimeStart());
      final error = (await closed as RealtimeClosed).error!;
      expect(error, contains('api-key=***'));
      expect(error, isNot(contains('secret')));
      await backend.close();
    });

    test(
      'xAI: voice and turn detection at the top, a relay endpoint',
      () async {
        final backend = make(
          const RealtimeConfig(
            provider: RealtimeProvider.xai,
            endpoint: 'http://relay.local:8099/realtime',
            voice: 'ara',
          ),
        );
        await backend.start(const RealtimeStart());
        expect(
          url.toString(),
          'ws://relay.local:8099/realtime?model=grok-voice-latest',
        );
        // No key: the relay adds it.
        expect(headers, isEmpty);
        final session = socket.sent.first['session'] as Map;
        expect(session['voice'], 'ara');
        expect((session['turn_detection'] as Map)['type'], 'server_vad');
        expect(session.containsKey('type'), isFalse);
        await backend.close();
      },
    );

    test('audio, transcripts and the answer come through as events', () async {
      final backend = make(
        const RealtimeConfig(provider: RealtimeProvider.openai),
      );
      await backend.start(const RealtimeStart());
      socket
        ..server({'type': 'session.updated'})
        ..server({'type': 'input_audio_buffer.speech_started'})
        ..server({
          'type': 'conversation.item.input_audio_transcription.completed',
          'item_id': 'u1',
          'transcript': 'Turn on the kitchen',
        })
        ..server({'type': 'response.created'})
        ..server({
          'type': 'response.output_audio.delta',
          'item_id': 'a1',
          'delta': base64Encode([1, 0, 2, 0]),
        })
        ..server({
          'type': 'response.audio.delta',
          'item_id': 'a1',
          'delta': base64Encode([3, 0]),
        })
        ..server({
          'type': 'response.output_audio_transcript.delta',
          'delta': 'Done',
        })
        ..server({
          'type': 'response.done',
          'response': {'status': 'completed'},
        });
      await pumpEventQueue();
      expect(events.whereType<RealtimeReady>(), hasLength(1));
      expect(events.whereType<RealtimeSpeechStarted>(), hasLength(1));
      expect(
        events.whereType<RealtimeUserText>().single.text,
        'Turn on the kitchen',
      );
      final audio = events.whereType<RealtimeAudio>().toList();
      expect(audio.map((a) => a.itemId), ['a1', 'a1']);
      expect(audio.first.pcm, [1, 0, 2, 0]);
      expect(events.whereType<RealtimeAnswerText>().last.text, 'Done');
      expect(events.whereType<RealtimeResponseDone>(), hasLength(1));
      backend.sendAudio(Uint8List.fromList([9, 9]));
      expect(socket.sent.last['type'], 'input_audio_buffer.append');
      await backend.close();
    });

    test(
      'a tool runs, its output goes back and the model answers it',
      () async {
        final backend = make(
          const RealtimeConfig(provider: RealtimeProvider.openai),
        );
        await backend.start(const RealtimeStart());
        tools.gate = Completer<void>();
        socket
          ..server({'type': 'session.updated'})
          ..server({'type': 'response.created'})
          ..server({
            'type': 'response.function_call_arguments.done',
            'call_id': 'c1',
            'name': 'intent__HassTurnOn',
            'arguments': '{"name":"Kitchen"}',
          })
          ..server({'type': 'response.done'});
        await pumpEventQueue();
        // The answer is done but its tool is not: nothing asked yet.
        expect(socket.types, isNot(contains('response.create')));
        tools.gate!.complete();
        await pumpEventQueue();
        expect(tools.calls.single.$2, {'name': 'Kitchen'});
        final output = socket.sent.firstWhere(
          (m) => m['type'] == 'conversation.item.create',
        );
        expect((output['item'] as Map)['call_id'], 'c1');
        expect(socket.types.last, 'response.create');
        final activity = events.whereType<RealtimeToolActivity>().toList();
        expect(activity.map((a) => a.done), [false, true]);
        await backend.close();
      },
    );

    test(
      'end_conversation asks the session to end, with no new answer',
      () async {
        final backend = make(
          const RealtimeConfig(provider: RealtimeProvider.openai),
        );
        await backend.start(const RealtimeStart());
        socket
          ..server({'type': 'session.updated'})
          ..server({'type': 'response.created'})
          ..server({
            'type': 'response.function_call_arguments.done',
            'call_id': 'c2',
            'name': LocalToolbox.endConversation,
            'arguments': '{}',
          })
          ..server({'type': 'response.done'});
        await pumpEventQueue();
        expect(events.whereType<RealtimeEndRequested>(), hasLength(1));
        expect(socket.types, isNot(contains('response.create')));
        await backend.close();
      },
    );

    test('a failed transcription warns once and shows no text', () async {
      final lines = <String>[];
      socket = _Socket();
      events = [];
      final backend = OpenAiRealtimeBackend(
        config: const RealtimeConfig(provider: RealtimeProvider.openai),
        toolbox: _Tools(),
        log: lines.add,
        connector: (_, _) async => socket,
      );
      backend.events.listen(events.add);
      await backend.start(const RealtimeStart());
      socket.server({'type': 'session.updated'});
      for (final item in ['i1', 'i2']) {
        socket.server({
          'type': 'conversation.item.input_audio_transcription.failed',
          'item_id': item,
          'error': {'type': 'server_error', 'code': 'DeploymentNotFound'},
        });
      }
      await pumpEventQueue();
      expect(lines.where((l) => l.startsWith('transcription failed')), [
        'transcription failed: DeploymentNotFound',
        'transcription failed: DeploymentNotFound',
      ]);
      final warnings = events.whereType<RealtimeWarning>().toList();
      expect(warnings, hasLength(1));
      expect(
        warnings.single.message,
        'transcription with gpt-4o-mini-transcribe failed: DeploymentNotFound',
      );
      expect(events.whereType<RealtimeUserText>(), isEmpty);
      await backend.close();
    });

    test('failures with no handling of their own are logged', () async {
      final lines = <String>[];
      socket = _Socket();
      tools = _Tools()..fail = true;
      final backend = OpenAiRealtimeBackend(
        config: const RealtimeConfig(provider: RealtimeProvider.xai),
        toolbox: tools,
        log: lines.add,
        connector: (_, _) async => socket,
      );
      backend.events.listen((_) {});
      await backend.start(const RealtimeStart());
      socket
        ..server({'type': 'session.updated'})
        ..server({
          'type': 'response.done',
          'response': {
            'status': 'incomplete',
            'status_details': {'reason': 'content_filter'},
          },
        })
        ..server({
          'type': 'response.mcp_call.failed',
          'error': {'code': 'boom'},
        })
        ..server({'type': 'response.output_item.added'})
        ..server({
          'type': 'response.function_call_arguments.done',
          'call_id': 'c1',
          'name': 'intent__HassTurnOn',
          'arguments': '{not json',
        });
      socket.incoming
        ..add('not json')
        ..add('still not json');
      await pumpEventQueue();
      expect(lines.where((l) => !l.startsWith('connecting')), [
        'session ready',
        'answer incomplete: content_filter',
        'response.mcp_call.failed: {"code":"boom"}',
        startsWith('tool intent__HassTurnOn: unreadable arguments'),
        'tool intent__HassTurnOn failed: {"error": "no such entity"}',
        startsWith('unreadable message:'),
      ]);
      await backend.close();
    });

    test('an interruption cancels the answer and truncates it', () async {
      final backend = make(
        const RealtimeConfig(provider: RealtimeProvider.openai),
      );
      await backend.start(const RealtimeStart());
      socket
        ..server({'type': 'session.updated'})
        ..server({'type': 'response.created'});
      await pumpEventQueue();
      backend.interrupted('a1', 1250);
      expect(socket.types.sublist(socket.types.length - 2), [
        'response.cancel',
        'conversation.item.truncate',
      ]);
      expect(socket.sent.last['audio_end_ms'], 1250);
      await backend.close();
    });

    test('an opening line goes as one answer\'s instructions', () async {
      final backend = make(
        const RealtimeConfig(provider: RealtimeProvider.xai, apiKey: 'k'),
      );
      await backend.start(const RealtimeStart());
      socket.server({'type': 'session.updated'});
      await pumpEventQueue();
      backend.speak('The garage door is open. Want me to close it?');
      expect(socket.sent.last, {
        'type': 'response.create',
        'response': {
          'instructions': realtimeSpeakPrompt(
            'The garage door is open. Want me to close it?',
          ),
        },
      });
      await backend.close();
    });

    test('xAI: the web and X searches go in the tools when on', () async {
      final off = make(const RealtimeConfig(provider: RealtimeProvider.xai));
      await off.start(const RealtimeStart());
      final plain = (socket.sent.first['session'] as Map)['tools'] as List;
      expect(plain.map((t) => (t as Map)['type']), everyElement('function'));
      await off.close();
      final on = make(
        const RealtimeConfig(
          provider: RealtimeProvider.xai,
          search: true,
          xSearch: true,
        ),
      );
      await on.start(const RealtimeStart());
      final listed = (socket.sent.first['session'] as Map)['tools'] as List;
      expect(listed.map((t) => (t as Map)['type']), [
        'function',
        'function',
        'web_search',
        'x_search',
      ]);
      await on.close();
    });

    test('xAI: its own search calls are not run, the app\'s are', () async {
      final backend = make(
        const RealtimeConfig(provider: RealtimeProvider.xai, search: true),
      );
      await backend.start(const RealtimeStart());
      socket
        ..server({'type': 'session.updated'})
        ..server({'type': 'response.created'})
        ..server({
          'type': 'response.function_call_arguments.done',
          'call_id': 'c1',
          'name': 'web_search',
          'arguments': '{"query":"weather"}',
        })
        ..server({
          'type': 'response.function_call_arguments.done',
          'call_id': 'c2',
          'name': 'x_keyword_search',
          'arguments': '{"query":"from:xai"}',
        })
        ..server({'type': 'response.done'});
      await pumpEventQueue();
      expect(tools.calls, isEmpty);
      expect(events.whereType<RealtimeToolActivity>(), isEmpty);
      expect(socket.types, isNot(contains('conversation.item.create')));
      expect(socket.types, isNot(contains('response.create')));
      socket
        ..server({'type': 'response.created'})
        ..server({
          'type': 'response.function_call_arguments.done',
          'call_id': 'c3',
          'name': 'intent__HassTurnOn',
          'arguments': '{}',
        })
        ..server({'type': 'response.done'});
      await pumpEventQueue();
      expect(tools.calls.single.$1, 'intent__HassTurnOn');
      expect(socket.types.last, 'response.create');
      await backend.close();
    });

    test('xAI: talking over it leaves the cancel to the server', () async {
      final backend = make(
        const RealtimeConfig(provider: RealtimeProvider.xai),
      );
      await backend.start(const RealtimeStart());
      socket
        ..server({'type': 'session.updated'})
        ..server({'type': 'response.created'})
        ..server({'type': 'input_audio_buffer.speech_started'});
      await pumpEventQueue();
      backend.interrupted('a1', 800);
      expect(socket.types, isNot(contains('response.cancel')));
      expect(socket.types.last, 'conversation.item.truncate');
      await backend.close();
    });

    test('OpenAI: the session stops the answer and takes the turns', () async {
      final backend = make(
        const RealtimeConfig(provider: RealtimeProvider.openai),
      );
      expect(backend.capabilities.clientTurns, isTrue);
      await backend.start(const RealtimeStart());
      socket
        ..server({'type': 'session.updated'})
        ..server({'type': 'response.created'})
        ..server({'type': 'input_audio_buffer.speech_started'})
        ..server({
          'type': 'input_audio_buffer.speech_stopped',
          'item_id': 'u1',
        });
      await pumpEventQueue();
      // Not the user: the item goes, and its transcript is not shown.
      backend.userTurn(keep: false);
      expect(socket.types.last, 'conversation.item.delete');
      socket.server({
        'type': 'conversation.item.input_audio_transcription.completed',
        'item_id': 'u1',
        'transcript': 'Stop.',
      });
      await pumpEventQueue();
      expect(events.whereType<RealtimeUserText>(), isEmpty);
      // The user: the answer is cancelled and a reply asked for.
      backend.interrupted('a1', 800);
      expect(socket.types, contains('response.cancel'));
      backend.userTurn(keep: true);
      // Any answer still open on the server goes first.
      expect(socket.types.skip(socket.types.length - 2), [
        'response.cancel',
        'response.create',
      ]);
      await backend.close();
    });

    test('an error before the session is up closes it', () async {
      final backend = make(
        const RealtimeConfig(provider: RealtimeProvider.openai),
      );
      await backend.start(const RealtimeStart());
      socket.server({
        'type': 'error',
        'error': {'code': 'invalid_api_key', 'message': 'Incorrect API key'},
      });
      await pumpEventQueue();
      expect(
        events.whereType<RealtimeClosed>().single.error,
        'Incorrect API key',
      );
    });
  });

  group('GeminiLiveBackend', () {
    late _Socket socket;
    late _Tools tools;
    late List<RealtimeEvent> events;
    Uri? url;
    Map<String, String>? headers;

    GeminiLiveBackend make(RealtimeConfig config) {
      socket = _Socket();
      tools = _Tools();
      events = [];
      final backend = GeminiLiveBackend(
        config: config,
        toolbox: tools,
        connector: (u, h) async {
          url = u;
          headers = h;
          return socket;
        },
      );
      backend.events.listen(events.add);
      return backend;
    }

    Map<String, Object?> setup() =>
        (socket.sent.first['setup'] as Map).cast<String, Object?>();

    Future<GeminiLiveBackend> ready() async {
      final backend = make(
        const RealtimeConfig(provider: RealtimeProvider.gemini, apiKey: 'g'),
      );
      await backend.start(const RealtimeStart());
      socket.server({'setupComplete': <String, Object?>{}});
      await pumpEventQueue();
      return backend;
    }

    String audio(List<int> samples) => base64Encode(_pcm(samples));

    test('the key in a header, the model and voice in the setup', () async {
      final backend = make(
        const RealtimeConfig(
          provider: RealtimeProvider.gemini,
          apiKey: 'g',
          instructions: 'Be brief.',
        ),
      );
      await backend.start(
        const RealtimeStart(
          context: 'This kiosk is in the Kitchen area.',
          history: [
            RealtimeTurn(user: true, text: 'Dim the kitchen'),
            RealtimeTurn(user: false, text: 'Done.'),
          ],
        ),
      );
      // No model in the address, and the key never in it either.
      expect(url.toString(), RealtimeProvider.gemini.endpoint);
      expect(headers, {'x-goog-api-key': 'g'});
      final s = setup();
      expect(s['model'], 'models/gemini-3.8-live');
      final generation = s['generationConfig'] as Map;
      expect(generation['responseModalities'], ['AUDIO']);
      expect(
        (((generation['speechConfig'] as Map)['voiceConfig']
                as Map)['prebuiltVoiceConfig']
            as Map)['voiceName'],
        'Puck',
      );
      final text =
          (((s['systemInstruction'] as Map)['parts'] as List).single
              as Map)['text'];
      expect(text, startsWith('Be brief.\n\nThis kiosk is in the Kitchen'));
      expect(text, endsWith('User: Dim the kitchen\nAssistant: Done.'));
      expect(s['inputAudioTranscription'], isEmpty);
      expect(s['outputAudioTranscription'], isEmpty);
      // Tools without arguments declare no parameters: Gemini refuses an
      // object with no properties.
      final declarations =
          ((s['tools'] as List).single as Map)['functionDeclarations'] as List;
      expect(declarations, hasLength(2));
      expect((declarations.first as Map).containsKey('parameters'), isFalse);
      // Nothing streams before the setup is confirmed.
      backend.sendAudio(_pcm([1, 2]));
      expect(socket.sent, hasLength(1));
      await backend.close();
    });

    test('reasoning, Google Search and proactive audio when set', () async {
      var backend = make(
        const RealtimeConfig(
          provider: RealtimeProvider.gemini,
          reasoning: 'low',
          search: true,
          proactive: true,
        ),
      );
      await backend.start(const RealtimeStart());
      // Only Google's v1alpha API has proactive audio.
      expect(
        url.toString(),
        RealtimeProvider.gemini.endpoint.replaceFirst('v1beta', 'v1alpha'),
      );
      var s = setup();
      expect((s['generationConfig'] as Map)['thinkingConfig'], {
        'thinkingLevel': 'low',
      });
      final tools = s['tools'] as List;
      expect(tools.first, {'googleSearch': <String, Object?>{}});
      expect((tools.last as Map).containsKey('functionDeclarations'), isTrue);
      expect(s['proactivity'], {'proactiveAudio': true});
      await backend.close();

      backend = make(const RealtimeConfig(provider: RealtimeProvider.gemini));
      await backend.start(const RealtimeStart());
      expect(url.toString(), RealtimeProvider.gemini.endpoint);
      s = setup();
      expect(
        (s['generationConfig'] as Map).containsKey('thinkingConfig'),
        isFalse,
      );
      expect((s['tools'] as List), hasLength(1));
      expect(s.containsKey('proactivity'), isFalse);
      await backend.close();

      // A relay keeps its own address.
      backend = make(
        const RealtimeConfig(
          provider: RealtimeProvider.gemini,
          endpoint: 'ws://relay.local:8099/live',
          proactive: true,
        ),
      );
      await backend.start(const RealtimeStart());
      expect(url.toString(), 'ws://relay.local:8099/live');
      await backend.close();
    });

    test('a relay endpoint without a key, a model named in full', () async {
      final backend = make(
        const RealtimeConfig(
          provider: RealtimeProvider.gemini,
          endpoint: 'http://relay.local:8099/live',
          model: 'models/gemini-3.1-flash-live-preview',
          voice: 'Kore',
        ),
      );
      await backend.start(const RealtimeStart());
      expect(url.toString(), 'ws://relay.local:8099/live');
      expect(headers, isEmpty);
      expect(setup()['model'], 'models/gemini-3.1-flash-live-preview');
      await backend.close();
    });

    test('an opening line goes as a typed turn', () async {
      final backend = await ready();
      backend.speak('Good morning. Ready for the weather?');
      expect(socket.sent.last, {
        'realtimeInput': {
          'text': realtimeSpeakPrompt('Good morning. Ready for the weather?'),
        },
      });
      await backend.close();
    });

    test('unknown messages and failed tools are logged', () async {
      final lines = <String>[];
      socket = _Socket();
      tools = _Tools()..fail = true;
      final backend = GeminiLiveBackend(
        config: const RealtimeConfig(provider: RealtimeProvider.gemini),
        toolbox: tools,
        log: lines.add,
        connector: (_, _) async => socket,
      );
      backend.events.listen((_) {});
      await backend.start(const RealtimeStart());
      socket
        ..server({'setupComplete': <String, Object?>{}})
        ..server({'usageMetadata': <String, Object?>{}})
        ..server({
          'error': {'code': 13, 'message': 'internal'},
        })
        ..server({
          'error': {'code': 13, 'message': 'internal'},
        })
        ..server({
          'toolCall': {
            'functionCalls': [
              {'id': 'c1', 'name': 'intent__HassTurnOn', 'args': {}},
            ],
          },
        });
      await pumpEventQueue();
      expect(lines.where((l) => !l.startsWith('connecting')), [
        'session ready',
        'error: {"code":13,"message":"internal"}',
        'tool intent__HassTurnOn failed: {"error": "no such entity"}',
      ]);
      await backend.close();
    });

    test('tool schemas are rewritten into what Gemini takes', () {
      final schema = GeminiLiveBackend.geminiSchema({
        r'$schema': 'http://json-schema.org/draft-07/schema#',
        'type': 'object',
        'additionalProperties': false,
        'properties': {
          'name': {'type': 'string', 'description': 'The name'},
          'area': {
            'type': ['string', 'null'],
          },
          'brightness': {'type': 'integer', 'minimum': 0, 'maximum': 100},
          'domain': {
            'type': 'array',
            'items': {
              'type': 'string',
              'enum': ['light', 'switch'],
            },
          },
          'tags': {'type': 'array'},
          'level': {
            'type': 'string',
            'enum': [1, 2],
          },
          'url': {'type': 'string', 'format': 'uri'},
          'empty': {'type': 'object', 'properties': <String, Object?>{}},
          'either': {
            'anyOf': [
              {'type': 'string'},
              {'type': 'number'},
            ],
          },
        },
        'required': ['name', 'empty'],
      });
      expect(schema, {
        'type': 'OBJECT',
        'properties': {
          'name': {'type': 'STRING', 'description': 'The name'},
          'area': {'type': 'STRING', 'nullable': true},
          'brightness': {'type': 'INTEGER', 'minimum': 0, 'maximum': 100},
          'domain': {
            'type': 'ARRAY',
            'items': {
              'type': 'STRING',
              'enum': ['light', 'switch'],
              'format': 'enum',
            },
          },
          'tags': {
            'type': 'ARRAY',
            'items': {'type': 'STRING'},
          },
          'level': {
            'type': 'STRING',
            'enum': ['1', '2'],
            'format': 'enum',
          },
          'url': {'type': 'STRING'},
          'either': {
            'anyOf': [
              {'type': 'STRING'},
              {'type': 'NUMBER'},
            ],
          },
        },
        'required': ['name'],
      });
      expect(
        GeminiLiveBackend.geminiSchema({
          'type': 'object',
          'properties': <String, Object?>{},
        }),
        isNull,
      );
    });

    test('16 kHz in, 24 kHz out, the turns kept by Gemini', () async {
      final backend = await ready();
      expect(events.whereType<RealtimeReady>(), hasLength(1));
      expect(backend.capabilities.inputRate, 16000);
      expect(backend.capabilities.outputRate, 24000);
      expect(backend.capabilities.clientTurns, isFalse);
      backend.sendAudio(_pcm([1, 2]));
      expect(socket.sent.last, {
        'realtimeInput': {
          'audio': {
            'data': audio([1, 2]),
            'mimeType': 'audio/pcm;rate=16000',
          },
        },
      });
      await backend.close();
    });

    test('an exchange: the transcript, the answer, then the turn', () async {
      final backend = await ready();
      events.clear();
      socket.server({
        'serverContent': {
          'inputTranscription': {'text': 'Turn on '},
        },
      });
      socket.server({
        'serverContent': {
          'modelTurn': {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'audio/pcm;rate=24000',
                  'data': audio([5, 6]),
                },
              },
            ],
          },
        },
      });
      // The rest of what the user said comes after the answer started.
      socket.server({
        'serverContent': {
          'inputTranscription': {'text': 'the lights'},
        },
      });
      socket.server({
        'serverContent': {
          'outputTranscription': {'text': 'Done.'},
        },
      });
      socket.server({
        'serverContent': {'turnComplete': true},
      });
      await pumpEventQueue();
      expect(events[0], isA<RealtimeSpeechStarted>());
      expect((events[1] as RealtimeUserText).complete, isFalse);
      expect(events[2], isA<RealtimeSpeechStopped>());
      expect(events[3], isA<RealtimeResponseStarted>());
      final pcm = events[4] as RealtimeAudio;
      expect(pcm.itemId, 'answer-1');
      expect(_samples(pcm.pcm), [5, 6]);
      final heard = events.whereType<RealtimeUserText>().where(
        (e) => e.complete,
      );
      expect(heard.single.text, 'Turn on the lights');
      final answer = events.whereType<RealtimeAnswerText>().last;
      expect(answer.text, 'Done.');
      expect(answer.complete, isTrue);
      expect(events.last, isA<RealtimeResponseDone>());
      // A transcript right after the turn is late, not the user again.
      expect(events.whereType<RealtimeSpeechStarted>(), hasLength(1));

      events.clear();
      socket.server({
        'serverContent': {
          'outputTranscription': {'text': 'More.'},
        },
      });
      socket.server({
        'serverContent': {
          'modelTurn': {
            'parts': [
              {
                'inlineData': {
                  'data': audio([7]),
                },
              },
            ],
          },
        },
      });
      await pumpEventQueue();
      expect(events.whereType<RealtimeAudio>().single.itemId, 'answer-2');
      await backend.close();
    });

    test('Gemini stopping an answer the user talked over', () async {
      final backend = await ready();
      socket.server({
        'serverContent': {
          'outputTranscription': {'text': 'It is a long'},
        },
      });
      await pumpEventQueue();
      events.clear();
      socket.server({
        'serverContent': {'interrupted': true},
      });
      await pumpEventQueue();
      final cut = events.whereType<RealtimeAnswerText>().single;
      expect(cut.text, 'It is a long');
      expect(cut.complete, isTrue);
      expect(events.last, isA<RealtimeSpeechStarted>());
      // No truncate in Gemini's protocol: nothing goes out.
      final sent = socket.sent.length;
      backend.interrupted('answer-1', 300);
      expect(socket.sent, hasLength(sent));
      await backend.close();
    });

    test('the user counts as done once the transcript goes quiet', () {
      fakeAsync((async) {
        final backend = make(
          const RealtimeConfig(provider: RealtimeProvider.gemini),
        );
        unawaited(backend.start(const RealtimeStart()));
        async.flushMicrotasks();
        socket.server({'setupComplete': <String, Object?>{}});
        socket.server({
          'serverContent': {
            'inputTranscription': {'text': 'Hello'},
          },
        });
        async.flushMicrotasks();
        expect(events.last, isA<RealtimeUserText>());
        async.elapse(GeminiLiveBackend.speechQuiet);
        expect(events.last, isA<RealtimeSpeechStopped>());
        unawaited(backend.close());
        async.flushMicrotasks();
      });
    });

    test('tools run with the call\'s arguments and answer by id', () async {
      final backend = await ready();
      events.clear();
      // The calls are still running when Gemini takes one back.
      tools.gate = Completer<void>();
      socket.server({
        'toolCall': {
          'functionCalls': [
            {
              'id': 'c1',
              'name': 'intent__HassTurnOn',
              'args': {'name': 'kitchen'},
            },
            {
              'id': 'c2',
              'name': 'intent__HassTurnOn',
              'args': <String, Object?>{},
            },
          ],
        },
      });
      socket.server({
        'toolCallCancellation': {
          'ids': ['c2'],
        },
      });
      await pumpEventQueue();
      tools.gate!.complete();
      await pumpEventQueue();
      expect(tools.calls.first.$1, 'intent__HassTurnOn');
      expect(tools.calls.first.$2, {'name': 'kitchen'});
      expect(events.first, isA<RealtimeResponseStarted>());
      expect(events.whereType<RealtimeToolActivity>(), hasLength(4));
      final responses = [
        for (final m in socket.sent)
          if (m['toolResponse'] case final Map r)
            (r['functionResponses'] as List).single as Map,
      ];
      // The cancelled call is not answered.
      expect(responses, [
        {
          'id': 'c1',
          'name': 'intent__HassTurnOn',
          'response': {'result': '{"success": true}'},
        },
      ]);
      await backend.close();
    });

    test('ending the conversation answers the call', () async {
      final backend = make(
        const RealtimeConfig(provider: RealtimeProvider.gemini),
      );
      await backend.start(const RealtimeStart());
      socket.server({'setupComplete': <String, Object?>{}});
      socket.server({
        'toolCall': {
          'functionCalls': [
            {'id': 'e', 'name': LocalToolbox.endConversation},
          ],
        },
      });
      await pumpEventQueue();
      expect(events.whereType<RealtimeEndRequested>(), hasLength(1));
      // Gemini waits for every output before it completes the turn.
      expect(socket.sent.last.containsKey('toolResponse'), isTrue);
      socket.server({
        'serverContent': {'turnComplete': true},
      });
      await pumpEventQueue();
      expect(events.whereType<RealtimeResponseDone>(), hasLength(1));
      await backend.close();
    });

    test('a refused key reads as Gemini words it', () async {
      final backend = make(
        const RealtimeConfig(provider: RealtimeProvider.gemini, apiKey: 'bad'),
      );
      socket.reason = '1007 API key not valid. Please pass a valid API key.';
      await backend.start(const RealtimeStart());
      await socket.incoming.close();
      await pumpEventQueue();
      expect(
        events.whereType<RealtimeClosed>().single.error,
        'API key not valid. Please pass a valid API key.',
      );
      await backend.close();
    });
  });

  group('RealtimeHistory', () {
    test('drops what is older than the duration, keeps the rest in order', () {
      var now = DateTime(2026);
      final history = RealtimeHistory(now: () => now);
      history.add(user: true, text: 'first');
      now = now.add(const Duration(minutes: 40));
      history
        ..add(user: true, text: 'second')
        ..add(user: false, text: '  ')
        ..add(user: false, text: 'answer');
      now = now.add(const Duration(minutes: 30));
      expect(history.recent(const Duration(hours: 1)).map((t) => t.text), [
        'second',
        'answer',
      ]);
      // Gone for good, even if the duration grows again.
      expect(history.recent(const Duration(hours: 12)).map((t) => t.text), [
        'second',
        'answer',
      ]);
    });

    test('hands over the newest exchanges within the limits', () {
      final history = RealtimeHistory();
      for (var i = 0; i < 100; i++) {
        history.add(user: i.isEven, text: 'turn $i');
      }
      final recent = history.recent(const Duration(hours: 1));
      expect(recent, hasLength(RealtimeHistory.maxTurns));
      expect(recent.last.text, 'turn 99');
      history
        ..clear()
        ..add(user: true, text: 'x' * 5000)
        ..add(user: true, text: 'y' * 5000);
      expect(history.recent(const Duration(hours: 1)).map((t) => t.text[0]), [
        'y',
      ]);
    });
  });

  test('the location line names the device, not the assistant', () {
    expect(
      realtimeLocationLine(name: 'KS Portal Go', area: 'Kitchen'),
      'You run on a device named "KS Portal Go" in Home Assistant. That is '
      'its name, not yours. The device is in the Kitchen area. '
      "When the user doesn't name an area, use this one.",
    );
    expect(
      realtimeLocationLine(name: 'KS Portal Go', area: ''),
      'You run on a device named "KS Portal Go" in Home Assistant. That is '
      'its name, not yours.',
    );
    expect(
      realtimeLocationLine(name: '', area: 'Kitchen'),
      "The device is in the Kitchen area. When the user doesn't name an "
      'area, use this one.',
    );
    expect(realtimeLocationLine(name: '', area: ''), '');
  });

  group('RealtimeSession', () {
    test(
      'what was said carries into the next conversation for the session duration',
      () {
        fakeAsync((time) {
          final h = _Harness(
            time,
            options: const RealtimeOptions(historyHours: 1),
          );
          h.wakeAndConnect();
          expect(h.backend.started?.history, isEmpty);
          h.backend
            ..emit(const RealtimeUserText('Dim the kitchen'))
            ..emit(const RealtimeAnswerText('Dim'))
            ..emit(const RealtimeAnswerText('Dimmed to half.', complete: true));
          time.flushMicrotasks();
          h.session.cancel();
          time.flushMicrotasks();
          time.elapse(const Duration(minutes: 30));
          h.wakeAndConnect();
          expect(h.backend.started?.history.map((t) => (t.user, t.text)), [
            (true, 'Dim the kitchen'),
            (false, 'Dimmed to half.'),
          ]);
          h.session.cancel();
          time.flushMicrotasks();
          time.elapse(const Duration(minutes: 31));
          h.wakeAndConnect();
          expect(h.backend.started?.history, isEmpty);
          h.session.cancel();
          time.flushMicrotasks();
        });
      },
    );

    test(
      'where the kiosk is reaches the provider, and a slow lookup does not hold it up',
      () {
        fakeAsync((time) {
          final h = _Harness(
            time,
            location: () async => 'This kiosk is in the Kitchen area.',
          );
          h.wakeAndConnect();
          expect(
            h.backend.started?.context,
            'This kiosk is in the Kitchen area.',
          );
          h.session.cancel();
          time.flushMicrotasks();
          final slow = _Harness(
            time,
            location: () => Completer<String>().future,
          );
          unawaited(slow.session.wake('Hey Jarvis'));
          time.elapse(
            RealtimeSession.locationWait + const Duration(milliseconds: 100),
          );
          expect(slow.backend.started?.context, '');
          slow.session.cancel();
          time.flushMicrotasks();
        });
      },
    );

    test('quiet speech survives a pause and a long continuous utterance', () {
      fakeAsync((time) {
        final h = _Harness(time);
        h.wakeAndConnect();
        for (var i = 0; i < 65; i++) {
          h.mic.speak(value: 50);
          time.elapse(const Duration(milliseconds: 80));
        }
        h.backend.audio.clear();
        // A quiet first syllable must not need an absolute gate threshold.
        h.mic.speak(value: 100);
        expect(
          RealtimeSession.meanAbs(h.backend.audio.single),
          closeTo(100, 2),
        );
        for (var i = 0; i < 80; i++) {
          h.mic.speak(value: 250);
          time.elapse(const Duration(milliseconds: 80));
        }
        // Continuous speech must not become the gate's new noise floor.
        expect(RealtimeSession.meanAbs(h.backend.audio.last), closeTo(250, 2));
        h.session.cancel();
        time.flushMicrotasks();
      });
    });

    test('streams the microphone once connected, the chime left out', () {
      fakeAsync((time) {
        final h = _Harness(time);
        unawaited(h.session.wake('Hey Jarvis'));
        time.flushMicrotasks();
        expect(h.chimes.chimes, ['wake']);
        expect(h.view.docked, isTrue);
        // Over the chime: dropped.
        h.mic.speak();
        time.elapse(const Duration(milliseconds: 600));
        // After it, before the connection: held.
        h.mic.speak();
        expect(h.backend.audio, isEmpty);
        h.backend.emit(const RealtimeReady());
        time.flushMicrotasks();
        expect(h.player.rate, 24000);
        // The held chunk, resampled to 24 kHz: 1280 samples become 1920.
        expect(h.backend.audio, hasLength(1));
        expect(h.backend.audio.single.length ~/ 2, closeTo(1920, 1));
        h.mic.speak();
        expect(h.backend.audio, hasLength(2));
        h.session.cancel();
        time.flushMicrotasks();
      });
    });

    test('an opening is said first, after the announcement chime', () {
      fakeAsync((time) {
        final h = _Harness(time);
        var opened = 0;
        unawaited(
          h.session.wake(
            '',
            opening: ' The garage door is open. Close it? ',
            announceChime: true,
            onOpened: () => opened++,
          ),
        );
        time.flushMicrotasks();
        expect(h.chimes.chimes, ['announce']);
        expect(h.view.phase, AssistPhase.thinking);
        expect(h.view.docked, isTrue);
        // Connected while the chime still plays: the line waits for it.
        h.backend.emit(const RealtimeReady());
        time.flushMicrotasks();
        expect(h.backend.spoken, isEmpty);
        time.elapse(const Duration(milliseconds: 600));
        h.mic.speak();
        expect(h.backend.spoken, ['The garage door is open. Close it?']);
        h.answer('a1');
        expect(h.view.phase, AssistPhase.speaking);
        expect(opened, 0);
        h.player.frames = 24000;
        time.elapse(const Duration(milliseconds: 1500));
        // Played: Home Assistant hears the announcement finished, and the
        // conversation listens.
        expect(opened, 1);
        expect(h.view.phase, AssistPhase.listening);
        expect(h.session.busy, isTrue);
        h.session.cancel();
        time.flushMicrotasks();
        expect(opened, 1);
      });
    });

    test('an opening drops what the microphone held, nobody spoke yet', () {
      fakeAsync((time) {
        final h = _Harness(time);
        unawaited(h.session.wake('', opening: 'Hello'));
        time.flushMicrotasks();
        // No chime asked for: nothing plays and nothing is dropped.
        expect(h.chimes.chimes, isEmpty);
        h.mic.speak();
        h.backend.emit(const RealtimeReady());
        time.flushMicrotasks();
        expect(h.backend.audio, isEmpty);
        expect(h.backend.spoken, ['Hello']);
        h.mic.speak();
        expect(h.backend.audio, hasLength(1));
        h.session.cancel();
        time.flushMicrotasks();
      });
    });

    test('an opening never said still reports the announcement over', () {
      fakeAsync((time) {
        final h = _Harness(time);
        var opened = 0;
        unawaited(
          h.session.wake('', opening: 'Hello', onOpened: () => opened++),
        );
        time.flushMicrotasks();
        h.backend.emit(const RealtimeClosed(error: 'connection refused'));
        time.flushMicrotasks();
        expect(opened, 1);
        expect(h.session.busy, isFalse);
        // A second one while a conversation is on is not started.
        h.wakeAndConnect();
        unawaited(h.session.wake('', opening: 'Hi', onOpened: () => opened++));
        time.flushMicrotasks();
        expect(opened, 2);
        expect(h.backend.spoken, isEmpty);
        h.session.cancel();
        time.flushMicrotasks();
      });
    });

    test('plays the answer and talking over it cuts it where it was heard', () {
      fakeAsync((time) {
        final h = _Harness(time);
        h.wakeAndConnect();
        h.answer('a1', seconds: 2);
        expect(h.player.written, hasLength(1));
        expect(h.view.phase, AssistPhase.speaking);
        expect(h.stopArmed.last, isTrue);
        time.elapse(const Duration(milliseconds: 500));
        h.player.frames = 12000;
        h.backend.emit(const RealtimeSpeechStarted());
        time.flushMicrotasks();
        expect(h.player.flushes, 1);
        expect(h.backend.interruptions.single, ('a1', 500));
        expect(h.view.phase, AssistPhase.listening);
        expect(h.view.answer, isEmpty);
        h.session.cancel();
        time.flushMicrotasks();
      });
    });

    test('only the start of an answer waits for a buffer', () {
      fakeAsync((time) {
        final h = _Harness(time);
        h.wakeAndConnect();
        final tenth = _pcm(List.filled(2400, 3000));
        h.backend.emit(const RealtimeResponseStarted());
        h.backend.emit(RealtimeAudio('a1', tenth));
        time.flushMicrotasks();
        // 100 ms of a new answer: held.
        expect(h.player.written, isEmpty);
        h.backend.emit(RealtimeAudio('a1', tenth));
        h.backend.emit(RealtimeAudio('a1', tenth));
        time.flushMicrotasks();
        // 300 ms: out it goes.
        expect(h.player.written, hasLength(3));
        // The stream pauses longer than what was queued, then goes on:
        // the rest of the same answer is not held back again.
        time.elapse(const Duration(milliseconds: 500));
        h.backend.emit(RealtimeAudio('a1', tenth));
        time.flushMicrotasks();
        expect(h.player.written, hasLength(4));
        h.session.cancel();
        time.flushMicrotasks();
      });
    });

    test('the microphone goes as silence while an answer settles', () {
      fakeAsync((time) {
        final h = _Harness(time);
        h.backend.clientTurns = true;
        h.wakeAndConnect();
        h.answer('a1', seconds: 5);
        h.backend.audio.clear();
        h.mic.speak(value: 2000);
        expect(h.backend.audio.single.every((b) => b == 0), isTrue);
        // A microphone that never quiets down under the voice waits the
        // whole settling out.
        time.elapse(const Duration(milliseconds: 2100));
        h.backend.audio.clear();
        h.mic.speak(value: 2000);
        expect(h.backend.audio.single.every((b) => b == 0), isTrue);
        time.elapse(const Duration(milliseconds: 2000));
        h.backend.audio.clear();
        h.mic.speak(value: 2000);
        expect(h.backend.audio.single.any((b) => b != 0), isTrue);
        h.session.cancel();
        time.flushMicrotasks();
      });
    });

    test('the settling ends once the canceller keeps the voice out', () {
      fakeAsync((time) {
        final h = _Harness(time);
        h.backend.clientTurns = true;
        h.wakeAndConnect();
        h.answer('a1', seconds: 5);
        // Quiet chunks while the voice speaks, past the least it waits:
        // the echo is out.
        time.elapse(RealtimeSession.settleAtLeast);
        for (var i = 0; i < RealtimeSession.settledAfter; i++) {
          time.elapse(const Duration(milliseconds: 80));
          h.mic.speak(value: 10);
        }
        h.backend.audio.clear();
        h.mic.speak(value: 2000);
        expect(
          RealtimeSession.meanAbs(h.backend.audio.single),
          closeTo(2000, 2),
        );
        expect(h.traces, contains(startsWith('echo settled after')));
        h.session.cancel();
        time.flushMicrotasks();
      });
    });

    test('the room\'s noise stands in while the canceller mutes it', () {
      fakeAsync((time) {
        // A noise floor (an air conditioner) that comes back all at once
        // when the canceller lets go reads as someone talking.
        final h = _Harness(time);
        h.backend.clientTurns = true;
        h.wakeAndConnect();
        for (var i = 0; i < 20; i++) {
          h.mic.speak(value: 50);
        }
        int level(Uint8List pcm) => RealtimeSession.meanAbs(pcm);
        h.answer('a1', seconds: 5);
        h.backend.audio.clear();
        h.mic.speak(value: 2000);
        expect(level(h.backend.audio.single), closeTo(50, 2));
        time.elapse(RealtimeSession.echoSettle);
        h.backend.audio.clear();
        h.mic.speak(value: 0);
        expect(level(h.backend.audio.single), closeTo(50, 2));
        h.backend.audio.clear();
        h.mic.speak(value: 2000);
        expect(level(h.backend.audio.single), closeTo(2000, 2));
        h.session.cancel();
        time.flushMicrotasks();
      });
    });

    test('a quiet room goes as it is', () {
      fakeAsync((time) {
        final h = _Harness(time);
        h.wakeAndConnect();
        for (var i = 0; i < 20; i++) {
          h.mic.speak(value: 2);
        }
        h.answer('a1', seconds: 5);
        time.elapse(const Duration(milliseconds: 2100));
        h.backend.audio.clear();
        h.mic.speak(value: 0);
        expect(RealtimeSession.meanAbs(h.backend.audio.single), 0);
        h.session.cancel();
        time.flushMicrotasks();
      });
    });

    group('with the turns in the session', () {
      test('quiet speech over an answer is dropped, the answer goes on', () {
        fakeAsync((time) {
          final h = _Harness(time);
          h.backend.clientTurns = true;
          h.wakeAndConnect();
          h.answer('a1', seconds: 8);
          time.elapse(RealtimeSession.echoSettle);
          h.backend.emit(const RealtimeSpeechStarted());
          time.flushMicrotasks();
          for (var i = 0; i < 5; i++) {
            time.elapse(const Duration(milliseconds: 80));
            h.mic.speak(value: 300);
          }
          h.backend.emit(const RealtimeSpeechStopped());
          time.flushMicrotasks();
          expect(h.player.flushes, 0);
          expect(h.backend.interruptions, isEmpty);
          expect(h.backend.turns, [false]);
          h.session.cancel();
          time.flushMicrotasks();
        });
      });

      test('loud speech over an answer stops it and gets a reply', () {
        fakeAsync((time) {
          final h = _Harness(time);
          h.backend.clientTurns = true;
          h.wakeAndConnect();
          h.answer('a1', seconds: 8);
          time.elapse(RealtimeSession.echoSettle);
          h.backend.emit(const RealtimeSpeechStarted());
          time.flushMicrotasks();
          for (var i = 0; i < RealtimeSession.bargeInChunks; i++) {
            time.elapse(const Duration(milliseconds: 80));
            h.mic.speak(value: 3000);
          }
          time.flushMicrotasks();
          expect(h.player.flushes, 1);
          expect(h.backend.interruptions.single.$1, 'a1');
          h.backend.emit(const RealtimeSpeechStopped());
          time.flushMicrotasks();
          expect(h.backend.turns, [true]);
          h.session.cancel();
          time.flushMicrotasks();
        });
      });

      test('the rest of a cut answer does not play', () {
        fakeAsync((time) {
          final h = _Harness(time);
          h.backend.clientTurns = true;
          h.wakeAndConnect();
          h.answer('a1', seconds: 8);
          time.elapse(RealtimeSession.echoSettle);
          h.backend.emit(const RealtimeSpeechStarted());
          time.flushMicrotasks();
          for (var i = 0; i < RealtimeSession.bargeInChunks; i++) {
            time.elapse(const Duration(milliseconds: 80));
            h.mic.speak(value: 3000);
          }
          time.flushMicrotasks();
          expect(h.player.flushes, 1);
          final written = h.player.written.length;
          // What the provider had already sent of it arrives late.
          h.backend.emit(RealtimeAudio('a1', _pcm(List.filled(24000, 3000))));
          time.flushMicrotasks();
          expect(h.player.written, hasLength(written));
          // The user goes on talking, and the provider hears it.
          h.backend.audio.clear();
          h.mic.speak(value: 3000);
          expect(
            RealtimeSession.meanAbs(h.backend.audio.single),
            closeTo(3000, 2),
          );
          h.session.cancel();
          time.flushMicrotasks();
        });
      });

      test('the loud speech it already heard counts', () {
        fakeAsync((time) {
          final h = _Harness(time);
          h.backend.clientTurns = true;
          h.wakeAndConnect();
          h.answer('a1', seconds: 8);
          time.elapse(RealtimeSession.echoSettle);
          // The user speaks; the provider says so half a second later.
          for (var i = 0; i < RealtimeSession.bargeInChunks; i++) {
            time.elapse(const Duration(milliseconds: 80));
            h.mic.speak(value: 3000);
          }
          h.backend.emit(const RealtimeSpeechStarted());
          time.flushMicrotasks();
          expect(h.player.flushes, 1);
          h.session.cancel();
          time.flushMicrotasks();
        });
      });

      /// The cleaned microphone under the speaking voice, chunk by chunk.
      void underVoice(FakeAsync time, _Harness h, List<int> levels) {
        for (final level in levels) {
          time.elapse(const Duration(milliseconds: 80));
          h.mic.speak(value: level);
        }
      }

      /// Measured on an Android Things display (#1130): the canceller
      /// leaves 3 under the voice and the user talking over it reads 110.
      _Harness quietUserTalksOver(FakeAsync time, num sensitivity) {
        final h = _Harness(
          time,
          options: RealtimeOptions(
            talkOverLevel: RealtimeSession.talkOverLevel(sensitivity),
          ),
        );
        h.backend.clientTurns = true;
        h.wakeAndConnect();
        h.answer('a1', seconds: 10);
        time.elapse(RealtimeSession.settleAtLeast);
        underVoice(time, h, List.filled(36, 3));
        underVoice(time, h, [110, 110, 110]);
        h.backend.emit(const RealtimeSpeechStarted());
        time.flushMicrotasks();
        underVoice(time, h, [110, 110]);
        h.backend.emit(const RealtimeSpeechStopped());
        time.flushMicrotasks();
        return h;
      }

      test('a quiet microphone is too quiet at the default sensitivity', () {
        fakeAsync((time) {
          final h = quietUserTalksOver(time, 50);
          expect(h.player.flushes, 0);
          expect(h.backend.turns, [false]);
          expect(
            h.traces,
            contains(
              allOf(
                startsWith('ignored speech too quiet to be the user: '),
                contains('peak 110, 0 of 3 chunks at 1200'),
              ),
            ),
          );
          h.session.cancel();
          time.flushMicrotasks();
        });
      });

      test('a higher sensitivity hears a quiet microphone', () {
        fakeAsync((time) {
          final h = quietUserTalksOver(time, 90);
          expect(h.player.flushes, 1);
          expect(h.backend.interruptions.single.$1, 'a1');
          expect(h.backend.turns, [true]);
          expect(h.traces, contains(startsWith('talked over the answer: ')));
          h.session.cancel();
          time.flushMicrotasks();
        });
      });

      test('the sensitivity keeps 1200 at 50 and spreads on a log scale', () {
        expect(RealtimeSession.talkOverLevel(50), RealtimeSession.bargeInLevel);
        expect(RealtimeSession.talkOverLevel(0), 4800);
        expect(RealtimeSession.talkOverLevel(100), 40);
        expect(RealtimeSession.talkOverLevel(90), lessThan(110));
        expect(RealtimeSession.talkOverLevel(-5), 4800);
        expect(RealtimeSession.talkOverLevel(120), 40);
      });

      test('echo leaking as loud as a quiet voice never stops the answer', () {
        // What AEC3 leaves under the voice on a Galaxy Tab S8: 50 to 150,
        // with bursts of a few hundred the provider takes for speech.
        fakeAsync((time) {
          final h = _Harness(time);
          h.backend.clientTurns = true;
          h.wakeAndConnect();
          h.answer('a1', seconds: 10);
          time.elapse(RealtimeSession.echoSettle);
          underVoice(time, h, [
            for (var i = 0; i < 6; i++) ...[60, 90, 140, 70, 120, 300],
          ]);
          underVoice(time, h, [350, 420, 380]);
          h.backend.emit(const RealtimeSpeechStarted());
          time.flushMicrotasks();
          underVoice(time, h, [400, 260]);
          h.backend.emit(const RealtimeSpeechStopped());
          time.flushMicrotasks();
          expect(h.player.flushes, 0);
          expect(h.backend.interruptions, isEmpty);
          expect(h.backend.turns, [false]);
          expect(
            h.traces,
            contains(
              allOf(
                startsWith('ignored speech too quiet to be the user: '),
                contains('peak 420'),
              ),
            ),
          );
          h.session.cancel();
          time.flushMicrotasks();
        });
      });

      test('speech with nothing playing gets a reply', () {
        fakeAsync((time) {
          final h = _Harness(time);
          h.backend.clientTurns = true;
          h.wakeAndConnect();
          h.backend.emit(const RealtimeSpeechStarted());
          time.flushMicrotasks();
          h.mic.speak(value: 2000);
          h.backend.emit(const RealtimeSpeechStopped());
          time.flushMicrotasks();
          expect(h.backend.turns, [true]);
          expect(h.player.flushes, 0);
          h.session.cancel();
          time.flushMicrotasks();
        });
      });
    });

    group('with the turns in the provider', () {
      test('the provider hears the room over an answer, not the echo', () {
        fakeAsync((time) {
          final h = _Harness(time);
          h.wakeAndConnect();
          for (var i = 0; i < 20; i++) {
            h.mic.speak(value: 50);
          }
          h.answer('a1', seconds: 8);
          time.elapse(RealtimeSession.echoSettle);
          h.backend.audio.clear();
          for (var i = 0; i < 5; i++) {
            time.elapse(const Duration(milliseconds: 80));
            h.mic.speak(value: 600);
          }
          expect(h.backend.audio, hasLength(5));
          expect(
            h.backend.audio.map(RealtimeSession.meanAbs),
            everyElement(closeTo(50, 2)),
          );
          expect(h.player.flushes, 0);
          expect(h.backend.interruptions, isEmpty);
          h.session.cancel();
          time.flushMicrotasks();
        });
      });

      test('loud speech over an answer stops it and reaches the provider', () {
        fakeAsync((time) {
          final h = _Harness(time);
          h.wakeAndConnect();
          h.answer('a1', seconds: 8);
          time.elapse(RealtimeSession.echoSettle);
          h.backend.audio.clear();
          for (var i = 0; i < RealtimeSession.bargeInChunks; i++) {
            time.elapse(const Duration(milliseconds: 80));
            h.mic.speak(value: 3000);
          }
          time.flushMicrotasks();
          expect(h.player.flushes, 1);
          expect(h.backend.interruptions.single.$1, 'a1');
          // The comfort noise that went out while it weighed the first
          // chunks, then all three as they were heard.
          final levels = h.backend.audio.map(RealtimeSession.meanAbs).toList();
          expect(
            levels.skip(levels.length - RealtimeSession.bargeInChunks),
            everyElement(closeTo(3000, 2)),
          );
          h.backend.audio.clear();
          h.mic.speak(value: 3000);
          expect(
            RealtimeSession.meanAbs(h.backend.audio.single),
            closeTo(3000, 2),
          );
          h.session.cancel();
          time.flushMicrotasks();
        });
      });

      test('the next answer holds the microphone back again', () {
        fakeAsync((time) {
          final h = _Harness(time);
          h.wakeAndConnect();
          h.answer('a1', seconds: 8);
          time.elapse(RealtimeSession.echoSettle);
          for (var i = 0; i < RealtimeSession.bargeInChunks; i++) {
            time.elapse(const Duration(milliseconds: 80));
            h.mic.speak(value: 3000);
          }
          time.flushMicrotasks();
          time.elapse(const Duration(seconds: 3));
          h.answer('a2', seconds: 8);
          time.elapse(RealtimeSession.echoSettle);
          h.backend.audio.clear();
          h.mic.speak(value: 600);
          expect(
            RealtimeSession.meanAbs(h.backend.audio.single),
            lessThan(600),
          );
          h.session.cancel();
          time.flushMicrotasks();
        });
      });
    });

    test('without talk over the microphone is shut while it speaks', () {
      fakeAsync((time) {
        final h = _Harness(
          time,
          options: const RealtimeOptions(talkOver: false),
        );
        h.wakeAndConnect();
        h.answer('a1');
        final before = h.backend.audio.length;
        h.mic.speak();
        expect(h.backend.audio.length, before);
        // Played out, and past the echo tail: open again.
        h.player.frames = 24000;
        time.elapse(const Duration(seconds: 2));
        h.mic.speak();
        expect(h.backend.audio.length, before + 1);
        h.session.cancel();
        time.flushMicrotasks();
      });
    });

    test('ends after the silence, counting the last seconds down', () {
      fakeAsync((time) {
        final h = _Harness(
          time,
          options: const RealtimeOptions(idleSeconds: 8),
        );
        h.wakeAndConnect();
        time.elapse(const Duration(seconds: 5));
        expect(h.countdown.last, lessThan(1));
        expect(h.session.busy, isTrue);
        time.elapse(const Duration(seconds: 4));
        expect(h.session.busy, isFalse);
        expect(h.chimes.chimes.last, 'done');
        expect(h.mic.closes, 1);
        expect(h.backend.closed, isTrue);
        expect(h.player.open, isFalse);
        expect(h.view.visible, isFalse);
        expect(h.busy_, [true, false]);
        expect(h.idles, 1);
      });
    });

    test('someone talking holds the end off', () {
      fakeAsync((time) {
        final h = _Harness(
          time,
          options: const RealtimeOptions(idleSeconds: 5),
        );
        h.wakeAndConnect();
        h.backend.emit(const RealtimeSpeechStarted());
        time.elapse(const Duration(seconds: 20));
        expect(h.session.busy, isTrue);
        h.session.cancel();
        time.flushMicrotasks();
      });
    });

    test('a slow tool holds the end off, and the countdown resumes after', () {
      fakeAsync((time) {
        final h = _Harness(
          time,
          options: const RealtimeOptions(idleSeconds: 5),
        );
        h.wakeAndConnect();
        h.backend
          ..emit(const RealtimeResponseStarted())
          ..emit(const RealtimeToolActivity('weather__GetForecast'))
          ..emit(const RealtimeResponseDone());
        time.elapse(const Duration(seconds: 20));
        expect(h.countdown.last, 1);
        expect(h.session.busy, isTrue);
        // The tool comes back and its answer is asked for: still waiting.
        h.backend.emit(
          const RealtimeToolActivity('weather__GetForecast', done: true),
        );
        time.elapse(const Duration(seconds: 3));
        expect(h.countdown.last, 1);
        h.answer('a1');
        h.backend.emit(const RealtimeResponseDone());
        h.player.frames = 24000;
        time.elapse(const Duration(seconds: 4));
        expect(h.countdown.last, lessThan(1));
        time.elapse(const Duration(seconds: 3));
        expect(h.session.busy, isFalse);
      });
    });

    test('the goodbye plays out before the conversation ends', () {
      fakeAsync((time) {
        final h = _Harness(time);
        h.wakeAndConnect();
        h.answer('a1');
        h.backend.emit(const RealtimeEndRequested());
        h.backend.emit(const RealtimeResponseDone());
        time.elapse(const Duration(milliseconds: 300));
        expect(h.session.busy, isTrue);
        h.player.frames = 24000;
        time.elapse(const Duration(seconds: 1));
        expect(h.session.busy, isFalse);
      });
    });

    test('a turn after the goodbye is neither played nor waited for', () {
      fakeAsync((time) {
        final h = _Harness(time);
        h.wakeAndConnect();
        h.answer('a1');
        h.backend.emit(const RealtimeEndRequested());
        h.backend.emit(const RealtimeResponseDone());
        // Gemini goes on after the tool's output and never completes it.
        h.answer('a2');
        h.backend.emit(const RealtimeSpeechStarted());
        time.elapse(const Duration(milliseconds: 300));
        expect(h.session.busy, isTrue);
        h.player.frames = 24000;
        time.elapse(const Duration(seconds: 1));
        expect(h.session.busy, isFalse);
        expect(
          h.player.written.fold<int>(0, (n, b) => n + b.length ~/ 2),
          24000,
        );
        expect(h.player.flushes, 0);
      });
    });

    test('asked to end after the answer, it ends once that plays', () {
      fakeAsync((time) {
        final h = _Harness(
          time,
          options: const RealtimeOptions(idleSeconds: 30),
        );
        h.wakeAndConnect();
        // The intercom script runs as a tool: the ask comes mid tool.
        h.backend
          ..emit(const RealtimeResponseStarted())
          ..emit(const RealtimeToolActivity('script__intercom'))
          ..emit(const RealtimeResponseDone());
        time.flushMicrotasks();
        h.session.endAfterAnswer();
        h.backend.emit(
          const RealtimeToolActivity('script__intercom', done: true),
        );
        time.elapse(const Duration(seconds: 2));
        expect(h.session.busy, isTrue);
        h.answer('a1');
        h.backend.emit(const RealtimeResponseDone());
        time.elapse(const Duration(milliseconds: 300));
        expect(h.session.busy, isTrue);
        h.player.frames = 24000;
        time.elapse(const Duration(seconds: 1));
        // Long before the 30 second silence.
        expect(h.session.busy, isFalse);
      });
    });

    test('a connection that fails ends it with the error chime', () {
      fakeAsync((time) {
        final h = _Harness(time);
        unawaited(h.session.wake(''));
        time.flushMicrotasks();
        h.backend.emit(const RealtimeClosed(error: 'could not connect'));
        time.flushMicrotasks();
        expect(h.errors, ['realtime']);
        expect(h.chimes.chimes.last, 'error');
        expect(h.session.busy, isFalse);
      });
    });

    test(
      'tools and the answer fill the bubble, a new question replaces them',
      () {
        fakeAsync((time) {
          final h = _Harness(time);
          h.wakeAndConnect();
          h.backend
            ..emit(const RealtimeSpeechStarted())
            ..emit(const RealtimeUserText('Dim the kitchen'))
            ..emit(const RealtimeSpeechStopped())
            ..emit(const RealtimeToolActivity('light__HassLightSet'))
            ..emit(const RealtimeAnswerText('Done.', complete: true));
          time.flushMicrotasks();
          expect(h.view.command, 'Dim the kitchen');
          expect(h.view.tools, ['Light set']);
          expect(h.view.answer, 'Done.');
          // Talking again keeps the last exchange up until the new words
          // arrive.
          h.backend.emit(const RealtimeSpeechStarted());
          time.flushMicrotasks();
          expect(h.view.command, 'Dim the kitchen');
          expect(h.view.answer, 'Done.');
          h.backend.emit(const RealtimeUserText('And the hallway'));
          time.flushMicrotasks();
          expect(h.view.command, 'And the hallway');
          expect(h.view.tools, isEmpty);
          expect(h.view.answer, isEmpty);
          h.session.cancel();
          time.flushMicrotasks();
        });
      },
    );
  });
}
