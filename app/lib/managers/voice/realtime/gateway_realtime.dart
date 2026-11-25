import 'dart:async';
import 'dart:convert';

import 'gemini_live_backend.dart';
import 'openai_realtime_backend.dart';
import 'realtime_backend.dart';
import 'realtime_tools.dart';

/// Vercel AI Gateway: one key for the realtime models of several providers,
/// named `<provider>/<model>`, over one WebSocket.
///
/// The gateway speaks the AI SDK's realtime protocol, the same for every
/// model, and wraps each event it sends with the provider's own event in
/// `raw`. So the backends that already talk to each provider directly run
/// unchanged over a [GatewaySocket], which hands them the `raw` events:
/// OpenAI's and xAI's (OpenAiRealtimeBackend), Gemini's (GeminiLiveBackend)
/// and ElevenLabs', whose events are OpenAI's. On the way out the gateway
/// passes OpenAI's and xAI's own events through, and takes only its own
/// protocol for Gemini and ElevenLabs: the socket translates theirs.
///
/// Measured against the gateway on 2026-11-25 with every realtime model it
/// lists. A frame it cannot translate closes the connection with 1008
/// "WebSocket transform rejected frame" about 10 s later, with no error
/// event: Gemini refused a transcription language, speech detection
/// timings, a session update after the first and a Google Search tool that
/// way, and ElevenLabs any of OpenAI's own events.
enum GatewayFamily {
  /// OpenAI's realtime models. Every OpenAI event passes through, so they
  /// keep everything the direct provider has: the session taking the turns,
  /// the earlier exchanges as items, reasoning effort and speed.
  openai(prefix: 'openai/', dialect: RealtimeProvider.openai, voice: 'marin'),

  /// xAI's Grok voice models, as the direct xAI provider runs them.
  xai(prefix: 'spacexai/', dialect: RealtimeProvider.xai, voice: 'eve'),

  /// Gemini Live, over the gateway's protocol. Its events come back as
  /// Gemini's own. Thinking levels were read aloud as part of the answer
  /// and Google Search was refused, so neither goes.
  gemini(prefix: 'google/', dialect: RealtimeProvider.gemini, voice: 'Puck'),

  /// ElevenLabs, over the gateway's protocol, with OpenAI's events coming
  /// back. Its server keeps the turns as xAI's does: the gateway's
  /// protocol has no way to take them, and its speech detection is
  /// semantic only.
  elevenlabs(
    prefix: 'elevenlabs/',
    dialect: RealtimeProvider.xai,
    voice: 'brian',
  );

  const GatewayFamily({
    required this.prefix,
    required this.dialect,
    required this.voice,
  });

  /// The start of the gateway's model ids for this provider.
  final String prefix;

  /// The direct provider whose protocol the backend speaks.
  final RealtimeProvider dialect;

  /// The voice when none is picked.
  final String voice;

  /// The gateway passes this provider's own events through.
  bool get passthrough => this == openai || this == xai;

  /// The provider of the gateway model [model]. An unknown provider is
  /// taken for one whose events are OpenAI's over the gateway's protocol,
  /// which every model the gateway lists accepted.
  static GatewayFamily of(String model) => values.firstWhere(
    (f) => model.trim().startsWith(f.prefix),
    orElse: () => elevenlabs,
  );
}

/// What reaches a model through the gateway: [config] with the protocol
/// its provider speaks, the model without the provider in front and a
/// voice the provider has.
RealtimeConfig gatewayUpstream(RealtimeConfig config) {
  final model = config.effectiveModel;
  final family = GatewayFamily.of(model);
  final slash = model.indexOf('/');
  final passthrough = family.passthrough;
  return RealtimeConfig(
    provider: family.dialect,
    endpoint: config.url.replace(query: '').toString(),
    apiKey: config.apiKey,
    model: slash < 0 ? model : model.substring(slash + 1),
    voice: config.voice.trim().isEmpty ? family.voice : config.voice,
    instructions: config.instructions,
    speed: passthrough ? config.speed : 1,
    reasoning: family == GatewayFamily.openai ? config.reasoning : '',
  );
}

/// The backend for [config] on the gateway: the direct provider's, over a
/// [GatewaySocket]. A refused session is closed with 1008 about 10 s in,
/// so the backend waits a little longer than that for its answer.
RealtimeBackend gatewayBackend(
  RealtimeConfig config,
  RealtimeToolbox toolbox, {
  RealtimeConnector? connector,
  void Function(String line)? log,
}) {
  final family = GatewayFamily.of(config.effectiveModel);
  final upstream = gatewayUpstream(config);
  final url = config.url;
  final key = config.apiKey.trim();
  final connect = connector ?? connectRealtimeSocket;
  Future<RealtimeSocket> gateway(Uri _, Map<String, String> _) async =>
      GatewaySocket(
        await connect(url, {
          if (key.isNotEmpty) 'Authorization': 'Bearer $key',
        }),
        family,
      );
  const readyTimeout = Duration(seconds: 13);
  return family.dialect == RealtimeProvider.gemini
      ? GeminiLiveBackend(
          config: upstream,
          toolbox: toolbox,
          connector: gateway,
          log: log,
          readyTimeout: readyTimeout,
        )
      : OpenAiRealtimeBackend(
          config: upstream,
          toolbox: toolbox,
          connector: gateway,
          log: log,
          readyTimeout: readyTimeout,
        );
}

/// The gateway's WebSocket as the provider's own: each event arrives as the
/// provider sent it, and what the backend sends goes out in the form the
/// gateway takes for [family].
class GatewaySocket implements RealtimeSocket {
  GatewaySocket(this._inner, this.family);

  final RealtimeSocket _inner;
  final GatewayFamily family;

  /// The provider event last handed on. The gateway can make several of
  /// its events from one of Gemini's, an answer's audio and its words,
  /// and each carries the whole of it.
  String _last = '';

  @override
  Stream<Object?> get messages => _inner.messages.expand(_inbound);

  Iterable<Object?> _inbound(Object? message) sync* {
    final Map<Object?, Object?> event;
    try {
      final decoded = jsonDecode(
        message is String ? message : utf8.decode(message as List<int>),
      );
      if (decoded is! Map) return;
      event = decoded;
    } catch (_) {
      return;
    }
    final raw = event['raw'];
    if (raw is Map && raw.isNotEmpty) {
      final text = jsonEncode(raw);
      if (text == _last) return;
      _last = text;
      yield text;
      return;
    }
    // The gateway's own: a failure before any provider was reached, such
    // as a model it does not serve.
    if (event['type'] == 'error') {
      final error = {
        'message': '${event['message'] ?? 'error'}',
        if (event['code'] != null) 'code': '${event['code']}',
      };
      yield jsonEncode(
        family.dialect == RealtimeProvider.gemini
            ? {'gatewayError': error}
            : {'type': 'error', 'error': error},
      );
    }
  }

  @override
  void send(String message) {
    if (family.passthrough) {
      _inner.send(message);
      return;
    }
    final Map<String, Object?> event;
    try {
      event = (jsonDecode(message) as Map).cast<String, Object?>();
    } catch (_) {
      return;
    }
    final out = family.dialect == RealtimeProvider.gemini
        ? gatewayFromGemini(event)
        : gatewayFromOpenAi(event);
    for (final e in out) {
      _inner.send(jsonEncode(e));
    }
  }

  @override
  Future<void> close() => _inner.close();

  @override
  String? get closeReason {
    final reason = _inner.closeReason;
    if (reason == null || !reason.startsWith('1008')) return reason;
    return 'The gateway refused the session for this model (1008).';
  }
}

/// [event], one of the OpenAI protocol events OpenAiRealtimeBackend sends
/// (as for xAI), in the gateway's protocol. Those with no counterpart go
/// nowhere: deleting an item (the session never takes the turns here) and
/// a system item (the speaker's name).
List<Map<String, Object?>> gatewayFromOpenAi(Map<String, Object?> event) {
  switch ('${event['type'] ?? ''}') {
    case 'session.update':
      final session = event['session'] is Map
          ? (event['session'] as Map).cast<String, Object?>()
          : const <String, Object?>{};
      final config = <String, Object?>{};
      if (session['instructions'] case final String text) {
        config['instructions'] = text;
      }
      if (session['voice'] case final String name) config['voice'] = name;
      final audio = session['audio'] is Map ? session['audio'] as Map : null;
      final input = audio?['input'] is Map ? audio!['input'] as Map : null;
      final output = audio?['output'] is Map ? audio!['output'] as Map : null;
      if (input?['format'] case final Map format) {
        config['inputAudioFormat'] = format;
        config['inputAudioTranscription'] = <String, Object?>{};
        config['outputModalities'] = ['audio'];
      }
      if (output?['format'] case final Map format) {
        config['outputAudioFormat'] = format;
      }
      if (session.containsKey('turn_detection')) {
        // The only speech detection ElevenLabs has, and off while the
        // session ends each turn itself.
        config['turnDetection'] = {
          'type': session['turn_detection'] == null
              ? 'disabled'
              : 'semantic-vad',
        };
      }
      if (session['tools'] case final List tools) {
        config['tools'] = [
          for (final tool in tools)
            if (tool is Map && tool['type'] == 'function')
              {
                'type': 'function',
                'name': tool['name'],
                if (tool['description'] != null)
                  'description': tool['description'],
                'parameters': tool['parameters'] ?? const {'type': 'object'},
              },
        ];
      }
      return [
        {'type': 'session-update', 'config': config},
      ];
    case 'input_audio_buffer.append':
      return [
        {'type': 'input-audio-append', 'audio': event['audio']},
      ];
    case 'input_audio_buffer.commit':
      // The end of a turn the session took (Ground Control). xAI answers
      // its commit by itself and OpenAiRealtimeBackend asks for no reply:
      // this asks ElevenLabs for one, as the backend did before.
      return [
        {'type': 'input-audio-commit'},
        {'type': 'response-create'},
      ];
    case 'conversation.item.create':
      final item = event['item'] is Map ? event['item'] as Map : const {};
      if (item['type'] == 'function_call_output') {
        return [
          {
            'type': 'conversation-item-create',
            'item': {
              'type': 'function-call-output',
              'callId': item['call_id'],
              'output': '${item['output'] ?? ''}',
            },
          },
        ];
      }
      if (item['type'] == 'message' && item['role'] == 'user') {
        final text = [
          for (final part in (item['content'] as List? ?? const []))
            if (part is Map && part['text'] is String) part['text'],
        ].join('\n');
        if (text.isEmpty) return const [];
        return [
          {
            'type': 'conversation-item-create',
            'item': {'type': 'text-message', 'role': 'user', 'text': text},
          },
        ];
      }
      return const [];
    case 'response.create':
      final response = event['response'] is Map
          ? event['response'] as Map
          : const {};
      // ElevenLabs ignored instructions for one answer, and said the line
      // asked for word for word as a typed turn, as Gemini does.
      return [
        if (response['instructions'] case final String text)
          {
            'type': 'conversation-item-create',
            'item': {'type': 'text-message', 'role': 'user', 'text': text},
          },
        {'type': 'response-create'},
      ];
    case 'response.cancel':
      return [
        {'type': 'response-cancel'},
      ];
    case 'conversation.item.truncate':
      return [
        {
          'type': 'conversation-item-truncate',
          'itemId': event['item_id'],
          'contentIndex': event['content_index'] ?? 0,
          'audioEndMs': event['audio_end_ms'] ?? 0,
        },
      ];
  }
  return const [];
}

/// [message], one of the Live API messages GeminiLiveBackend sends, in the
/// gateway's protocol. The gateway sets Gemini up itself from a session
/// update, and refuses the setup's thinking level, Google Search and
/// proactive audio (the provider's dialog does not offer them).
List<Map<String, Object?>> gatewayFromGemini(Map<String, Object?> message) {
  if (message['setup'] case final Map setup) {
    final generation = setup['generationConfig'] is Map
        ? setup['generationConfig'] as Map
        : const {};
    final voice =
        ((((generation['speechConfig'] as Map?)?['voiceConfig']
                    as Map?)?['prebuiltVoiceConfig']
                as Map?)?['voiceName'])
            as String?;
    final parts =
        (setup['systemInstruction'] as Map?)?['parts'] as List? ?? const [];
    final instructions = [
      for (final part in parts)
        if (part is Map && part['text'] is String) part['text'],
    ].join('\n');
    final tools = [
      for (final tool in (setup['tools'] as List? ?? const []))
        if (tool is Map && tool['functionDeclarations'] is List)
          for (final fn in tool['functionDeclarations'] as List)
            if (fn is Map)
              {
                'type': 'function',
                'name': fn['name'],
                if (fn['description'] != null) 'description': fn['description'],
                'parameters':
                    gatewaySchema(fn['parameters']) ??
                    const {'type': 'object', 'properties': {}},
              },
    ];
    return [
      {
        'type': 'session-update',
        'config': {
          if (instructions.isNotEmpty) 'instructions': instructions,
          'voice': ?voice,
          'outputModalities': ['audio'],
          'inputAudioFormat': {
            'type': 'audio/pcm',
            'rate': GeminiLiveBackend.inputRate,
          },
          'outputAudioFormat': {
            'type': 'audio/pcm',
            'rate': GeminiLiveBackend.outputRate,
          },
          // No language and no timings: Gemini refused both.
          'turnDetection': {'type': 'server-vad'},
          'inputAudioTranscription': <String, Object?>{},
          'outputAudioTranscription': <String, Object?>{},
          if (tools.isNotEmpty) 'tools': tools,
        },
      },
    ];
  }
  if (message['realtimeInput'] case final Map input) {
    if (input['audio'] case final Map audio) {
      return [
        {'type': 'input-audio-append', 'audio': audio['data']},
      ];
    }
    if (input['audioStreamEnd'] == true) {
      return [
        {'type': 'input-audio-commit'},
      ];
    }
    // A typed turn, which Gemini answers on its own.
    if (input['text'] case final String text) {
      return [
        {
          'type': 'conversation-item-create',
          'item': {'type': 'text-message', 'role': 'user', 'text': text},
        },
      ];
    }
  }
  if (message['toolResponse'] case final Map response) {
    return [
      for (final fn in (response['functionResponses'] as List? ?? const []))
        if (fn is Map)
          {
            'type': 'conversation-item-create',
            'item': {
              'type': 'function-call-output',
              'callId': fn['id'] ?? '',
              'name': fn['name'],
              'output': jsonEncode(fn['response'] ?? const {}),
            },
          },
    ];
  }
  return const [];
}

/// A schema in Gemini's form (GeminiLiveBackend.geminiSchema) back in JSON
/// Schema's, which the gateway takes and turns into Gemini's itself.
Map<String, Object?>? gatewaySchema(Object? schema) {
  if (schema is! Map) return null;
  final out = <String, Object?>{};
  for (final MapEntry(:key, :value) in schema.entries) {
    switch (key) {
      case 'type':
        out['type'] = '$value'.toLowerCase();
      case 'format' when value == 'enum':
      case 'nullable':
        break;
      case 'properties' when value is Map:
        out['properties'] = {
          for (final MapEntry(:key, :value) in value.entries)
            '$key': gatewaySchema(value) ?? const {'type': 'string'},
        };
      case 'items':
        out['items'] = gatewaySchema(value) ?? const {'type': 'string'};
      case 'anyOf' when value is List:
        out['anyOf'] = [for (final v in value) ?gatewaySchema(v)];
      default:
        out['$key'] = value;
    }
  }
  return out;
}
