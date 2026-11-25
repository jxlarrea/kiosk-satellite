import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/voice/realtime/gateway_realtime.dart';
import 'package:kiosk_satellite/managers/voice/realtime/gemini_live_backend.dart';
import 'package:kiosk_satellite/managers/voice/realtime/openai_realtime_backend.dart';
import 'package:kiosk_satellite/managers/voice/realtime/realtime_backend.dart';
import 'package:kiosk_satellite/managers/voice/realtime/realtime_tools.dart';
import 'package:kiosk_satellite/managers/voice/voice_manager.dart';

/// The gateway's end of the socket: what the kiosk sent, as sent.
class _Wire implements RealtimeSocket {
  final incoming = StreamController<Object?>();
  final sent = <Map<String, Object?>>[];

  @override
  Stream<Object?> get messages => incoming.stream;

  @override
  void send(String message) =>
      sent.add((jsonDecode(message) as Map).cast<String, Object?>());

  @override
  Future<void> close() async => incoming.close();

  String? reason;

  @override
  String? get closeReason => reason;

  /// The gateway's event [type] wrapping the provider's own [raw].
  void wrap(String type, Object? raw) =>
      incoming.add(jsonEncode({'type': type, 'raw': raw}));

  List<String> get types => [for (final m in sent) '${m['type']}'];
}

class _Tools implements RealtimeToolbox {
  final calls = <String>[];

  @override
  Future<List<RealtimeToolSpec>> list() async => const [
    RealtimeToolSpec(
      name: 'get_temperature',
      description: 'Indoor temperature',
      parameters: {
        'type': 'object',
        'properties': {
          'room': {'type': 'string', 'enum': ' kitchen'},
          'unit': {
            'type': ['string', 'null'],
          },
        },
        'required': ['room'],
      },
    ),
  ];

  @override
  Future<RealtimeToolOutput> call(String name, Map<String, Object?> a) async {
    calls.add(name);
    return const RealtimeToolOutput('{"celsius": 21.5}');
  }

  @override
  String originalName(String name) => name;

  @override
  void close() {}
}

void main() {
  late _Wire wire;
  late List<RealtimeEvent> events;
  Uri? url;
  Map<String, String>? headers;

  RealtimeBackend make(String model, {String voice = '', double speed = 1}) {
    wire = _Wire();
    events = [];
    final backend = gatewayBackend(
      RealtimeConfig(
        provider: RealtimeProvider.vercel,
        apiKey: 'vck_x',
        model: model,
        voice: voice,
        speed: speed,
        reasoning: 'high',
      ),
      _Tools(),
      connector: (u, h) async {
        url = u;
        headers = h;
        return wire;
      },
    );
    backend.events.listen(events.add);
    return backend;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('GatewayFamily', () {
    test('by the provider in front of the model', () {
      expect(GatewayFamily.of('openai/gpt-realtime-2'), GatewayFamily.openai);
      expect(GatewayFamily.of('spacexai/grok-voice-3.0'), GatewayFamily.xai);
      expect(GatewayFamily.of('google/gemini-3.8-live'), GatewayFamily.gemini);
      expect(
        GatewayFamily.of('elevenlabs/eleven-realtime-v1-mini'),
        GatewayFamily.elevenlabs,
      );
      // A provider the gateway adds later gets its own protocol.
      expect(GatewayFamily.of('acme/voice-1'), GatewayFamily.elevenlabs);
    });

    test('the voices follow the model', () {
      List<String> voices(String model) =>
          VoiceManager.realtimeVoices(RealtimeProvider.vercel, model);
      expect(voices(''), contains('marin'));
      expect(voices('spacexai/grok-voice-3.0'), contains('eve'));
      expect(voices('google/gemini-3.8-live'), contains('Puck'));
      expect(voices('elevenlabs/eleven-realtime-v1-max'), contains('brian'));
    });
  });

  test('the model rides ai-model-id, the key a Bearer header', () async {
    final backend = make('');
    await backend.start(const RealtimeStart());
    expect(
      url.toString(),
      'wss://ai-gateway.vercel.sh/v4/ai/realtime-model'
      '?ai-model-id=openai%2Fgpt-realtime-2',
    );
    expect(headers, {'Authorization': 'Bearer vck_x'});
    await backend.close();
  });

  group('OpenAI models', () {
    test('OpenAI\'s own events pass through, as the direct provider sends '
        'them', () async {
      final backend = make('openai/gpt-realtime-mini', speed: 1.2);
      await backend.start(const RealtimeStart());
      expect(backend.capabilities.clientTurns, isTrue);
      final session = wire.sent.single['session'] as Map;
      expect(wire.sent.single['type'], 'session.update');
      expect(session['model'], 'gpt-realtime-mini');
      expect(session['reasoning'], {'effort': 'high'});
      final output = (session['audio'] as Map)['output'] as Map;
      expect(output['voice'], 'marin');
      expect(output['speed'], 1.2);
      await backend.close();
    });

    test('the provider\'s events come out of raw', () async {
      final backend = make('openai/gpt-realtime-mini');
      await backend.start(const RealtimeStart());
      wire.wrap('session-updated', {'type': 'session.updated'});
      wire.wrap('speech-started', {
        'type': 'input_audio_buffer.speech_started',
        'audio_start_ms': 212,
      });
      wire.wrap('audio-delta', {
        'type': 'response.output_audio.delta',
        'item_id': 'i1',
        'delta': base64Encode(Uint8List(4)),
      });
      // The gateway's own events with nothing of the provider's.
      wire.incoming.add(jsonEncode({'type': 'session-usage'}));
      wire.incoming.add(
        jsonEncode({'type': 'custom', 'raw': <String, Object?>{}}),
      );
      await settle();
      expect(events.whereType<RealtimeReady>(), hasLength(1));
      expect(events.whereType<RealtimeSpeechStarted>().single.audioMs, 212);
      expect(events.whereType<RealtimeAudio>().single.itemId, 'i1');
      await backend.close();
    });

    test('a gateway error reaches the backend as one of OpenAI\'s', () async {
      final backend = make('openai/gpt-realtime-mini');
      await backend.start(const RealtimeStart());
      wire.incoming.add(
        jsonEncode({
          'type': 'error',
          'message': 'Model not found',
          'code': 'model_not_found',
        }),
      );
      await settle();
      expect(
        events.whereType<RealtimeClosed>().single.error,
        'Model not found',
      );
    });
  });

  test('Grok models run as xAI does, with its voices', () async {
    final backend = make('spacexai/grok-voice-3.0');
    await backend.start(const RealtimeStart());
    expect(backend.capabilities.clientTurns, isFalse);
    final session = wire.sent.single['session'] as Map;
    expect(session['voice'], 'eve');
    expect(session.containsKey('reasoning'), isFalse);
    await backend.close();
  });

  group('Gemini models', () {
    test('the setup goes as the gateway\'s session update', () async {
      final backend = make('google/gemini-3.8-live', voice: 'Kore');
      await backend.start(const RealtimeStart(context: 'In the kitchen.'));
      expect(backend.capabilities.inputRate, GeminiLiveBackend.inputRate);
      final update = wire.sent.single;
      expect(update['type'], 'session-update');
      final config = update['config'] as Map;
      expect(config['voice'], 'Kore');
      expect(config['instructions'], contains('In the kitchen.'));
      expect(config['inputAudioFormat'], {'type': 'audio/pcm', 'rate': 16000});
      // Gemini refused speech detection timings and a language.
      expect(config['turnDetection'], {'type': 'server-vad'});
      expect(config['inputAudioTranscription'], isEmpty);
      // No thinking level: Gemini read it aloud.
      expect(jsonEncode(config), isNot(contains('thinking')));
      final tool = (config['tools'] as List).single as Map;
      final params = tool['parameters'] as Map;
      expect(params['type'], 'object');
      expect((params['properties'] as Map)['unit'], {'type': 'string'});
      await backend.close();
    });

    test('Gemini\'s events come out of raw once each, and its audio, '
        'speech and tool answers go as the gateway\'s', () async {
      final backend = make('google/gemini-3.8-live');
      await backend.start(const RealtimeStart());
      wire.wrap('session-created', {'setupComplete': <String, Object?>{}});
      await settle();
      expect(events.whereType<RealtimeReady>(), hasLength(1));

      backend.sendAudio(Uint8List(4));
      expect(wire.sent.last, {
        'type': 'input-audio-append',
        'audio': base64Encode(Uint8List(4)),
      });

      // One message of Gemini's, wrapped twice: its audio and its words.
      final content = {
        'serverContent': {
          'modelTurn': {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'audio/pcm;rate=24000',
                  'data': base64Encode(Uint8List(8)),
                },
              },
            ],
          },
          'outputTranscription': {'text': 'Hi'},
        },
      };
      wire.wrap('audio-delta', content);
      wire.wrap('audio-transcript-delta', content);
      await settle();
      expect(events.whereType<RealtimeAudio>(), hasLength(1));
      expect(events.whereType<RealtimeAnswerText>().last.text, 'Hi');

      wire.wrap('function-call-arguments-done', {
        'toolCall': {
          'functionCalls': [
            {
              'id': 'c1',
              'name': 'get_temperature',
              'args': {'room': 'kitchen'},
            },
          ],
        },
      });
      await settle();
      await settle();
      final output = wire.sent.last;
      expect(output['type'], 'conversation-item-create');
      final item = output['item'] as Map;
      expect(item['type'], 'function-call-output');
      expect(item['callId'], 'c1');
      expect(item['name'], 'get_temperature');
      expect(jsonDecode('${item['output']}'), {'result': '{"celsius": 21.5}'});

      backend.speak('Your timer is done.');
      expect(wire.sent.last['type'], 'conversation-item-create');
      expect(
        ((wire.sent.last['item'] as Map)['text'] as String),
        contains('Your timer is done.'),
      );
      await backend.close();
    });

    test('a refused setup says so instead of the gateway\'s 1008', () async {
      final backend = make('google/gemini-3.8-live');
      await backend.start(const RealtimeStart());
      wire.reason = '1008 WebSocket transform rejected frame';
      await wire.incoming.close();
      await settle();
      expect(
        events.whereType<RealtimeClosed>().single.error,
        contains('refused the session for this model'),
      );
    });
  });

  group('ElevenLabs models', () {
    test('OpenAI\'s events go as the gateway\'s, and its server keeps the '
        'turns', () async {
      final backend = make('elevenlabs/eleven-realtime-v1-mini');
      await backend.start(const RealtimeStart());
      expect(backend.capabilities.clientTurns, isFalse);
      final update = wire.sent.single;
      expect(update['type'], 'session-update');
      final config = update['config'] as Map;
      expect(config['voice'], 'brian');
      expect(config['turnDetection'], {'type': 'semantic-vad'});
      expect(config['inputAudioFormat'], {'type': 'audio/pcm', 'rate': 24000});
      expect(
        (config['tools'] as List).single,
        containsPair('type', 'function'),
      );

      wire.wrap('session-updated', {'type': 'session.updated'});
      await settle();
      backend.sendAudio(Uint8List(2));
      backend.speak('Your timer is done.');
      backend.interrupted('i1', 1200);
      expect(wire.types, [
        'session-update',
        'input-audio-append',
        'conversation-item-create',
        'response-create',
        'conversation-item-truncate',
      ]);
      expect(
        (wire.sent[2]['item'] as Map)['text'],
        contains('Your timer is done.'),
      );
      expect(wire.sent[4], {
        'type': 'conversation-item-truncate',
        'itemId': 'i1',
        'contentIndex': 0,
        'audioEndMs': 1200,
      });
      // The speaker's name has nowhere to go.
      backend.speaker('Ana');
      expect(wire.sent, hasLength(5));
      await backend.close();
    });
  });

  test('gatewayFromOpenAi: tool outputs and turns', () {
    expect(
      gatewayFromOpenAi({
        'type': 'conversation.item.create',
        'item': {
          'type': 'function_call_output',
          'call_id': 'c1',
          'output': '{"ok":true}',
        },
      }),
      [
        {
          'type': 'conversation-item-create',
          'item': {
            'type': 'function-call-output',
            'callId': 'c1',
            'output': '{"ok":true}',
          },
        },
      ],
    );
    expect(
      gatewayFromOpenAi({
        'type': 'session.update',
        'session': {'turn_detection': null},
      }),
      [
        {
          'type': 'session-update',
          'config': {
            'turnDetection': {'type': 'disabled'},
          },
        },
      ],
    );
    expect(gatewayFromOpenAi({'type': 'conversation.item.delete'}), isEmpty);
    expect(gatewayFromOpenAi({'type': 'input_audio_buffer.commit'}), [
      {'type': 'input-audio-commit'},
      {'type': 'response-create'},
    ]);
  });

  test('gatewaySchema: Gemini\'s schema back in JSON Schema', () {
    final gemini = GeminiLiveBackend.geminiSchema({
      'type': 'object',
      'properties': {
        'mode': {
          'type': 'string',
          'enum': ['heat', 'cool'],
        },
        'rooms': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
      'required': ['mode'],
    });
    expect(gatewaySchema(gemini), {
      'type': 'object',
      'properties': {
        'mode': {
          'type': 'string',
          'enum': ['heat', 'cool'],
        },
        'rooms': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
      'required': ['mode'],
    });
  });
}
