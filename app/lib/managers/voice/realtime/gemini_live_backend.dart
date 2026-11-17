import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'openai_realtime_backend.dart';
import 'realtime_backend.dart';
import 'realtime_tools.dart';

/// A direct backend over Google's Gemini Live API. Runs the tools itself,
/// as [OpenAiRealtimeBackend] does.
///
/// Gemini keeps the turns: its own voice activity detection decides when
/// the user is done and stops an answer the user talks over. It reports
/// neither the start nor the end of speech, only the transcript as it
/// grows, so the session's listening and thinking states come from that.
/// It has no way to cut an answer short from the kiosk either: the session
/// holds the microphone back while an answer plays, as it does for xAI.
class GeminiLiveBackend implements RealtimeBackend {
  GeminiLiveBackend({
    required this.config,
    required this.toolbox,
    RealtimeConnector? connector,
    this.log,
    this.readyTimeout = const Duration(seconds: 10),
  }) : _connector = connector ?? connectRealtimeSocket;

  final RealtimeConfig config;
  final RealtimeToolbox toolbox;

  final RealtimeConnector _connector;
  final void Function(String line)? log;
  final Duration readyTimeout;

  static const inputRate = 16000;
  static const outputRate = 24000;

  /// The user counts as done talking once the transcript stops growing for
  /// this long with no answer yet.
  static const speechQuiet = Duration(milliseconds: 1500);

  /// A transcript this soon after an answer is the end of what came before
  /// it, never the user starting to talk over the answer still playing.
  static const lateTranscript = Duration(seconds: 1);

  final _events = StreamController<RealtimeEvent>();
  RealtimeSocket? _socket;
  StreamSubscription<Object?>? _sub;
  bool _closing = false;
  bool _ready = false;
  Timer? _readyTimer;
  Timer? _quietTimer;

  /// An answer is open: Gemini has started its turn and not completed it.
  bool _responding = false;
  int _answers = 0;
  String _item = '';
  DateTime? _answerEnded;
  final _answer = StringBuffer();

  /// The user is talking, as far as the transcript shows.
  bool _hearing = false;
  final _heard = StringBuffer();

  /// Calls Gemini took back: their outputs are not sent.
  final _cancelled = <String>{};

  /// Problems already logged this conversation, for those that would
  /// repeat with every message.
  final _noted = <String>{};

  void _note(String kind, String line) {
    if (_noted.add(kind)) log?.call(line);
  }

  /// What the Live API sends. Anything else is logged once: a failure
  /// would otherwise go unseen.
  static const _known = {
    'setupComplete',
    'serverContent',
    'toolCall',
    'toolCallCancellation',
    'goAway',
    'sessionResumptionUpdate',
    'usageMetadata',
  };

  @override
  RealtimeCapabilities get capabilities =>
      const RealtimeCapabilities(inputRate: inputRate, outputRate: outputRate);

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  void _emit(RealtimeEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  @override
  Future<void> start(RealtimeStart start) async {
    final url = config.url;
    log?.call('connecting to ${url.replace(query: '')}');
    List<RealtimeToolSpec> tools;
    try {
      tools = await toolbox.list();
    } catch (e) {
      tools = const [];
      _emit(RealtimeWarning('tools: $e'));
    }
    if (toolbox case final CombinedToolbox box when box.problems.isNotEmpty) {
      for (final problem in box.problems) {
        _emit(RealtimeWarning(problem));
      }
    }
    if (_closing) return;
    final key = config.apiKey.trim();
    try {
      _socket = await _connector(url, {
        if (key.isNotEmpty) 'x-goog-api-key': key,
      });
    } catch (e) {
      _finish(error: realtimeConnectError(e));
      return;
    }
    if (_closing) {
      await _socket?.close();
      return;
    }
    _sub = _socket!.messages.listen(
      _onMessage,
      onError: (Object e) => _finish(error: describeRealtimeError(e)),
      onDone: () {
        final reason = _socket?.closeReason;
        if (_closing) {
          _finish();
        } else if (!_ready && reason != null) {
          // Gemini refuses a session by closing it with the reason, as in
          // "1007 API key not valid. Please pass a valid API key."
          _finish(error: reason.replaceFirst(RegExp(r'^\d+ '), ''));
        } else {
          _finish(
            error: 'connection closed${reason == null ? '' : ' ($reason)'}',
          );
        }
      },
    );
    _send(setupMessage(start, tools));
    _readyTimer = Timer(readyTimeout, () {
      if (!_ready) _finish(error: 'no answer from the provider');
    });
  }

  /// The first message: the model, its voice, the instructions with the
  /// kiosk's place and the earlier exchanges, and the tools.
  Map<String, Object?> setupMessage(
    RealtimeStart start,
    List<RealtimeToolSpec> tools,
  ) {
    final added = realtimeContextText(
      context: start.context,
      history: start.history,
    );
    final instructions = [
      config.instructions.trim().isEmpty
          ? OpenAiRealtimeBackend.defaultInstructions
          : config.instructions.trim(),
      if (added.isNotEmpty) added,
    ].join('\n\n');
    final model = config.effectiveModel;
    final declarations = [for (final tool in tools) functionDeclaration(tool)];
    return {
      'setup': {
        'model': model.startsWith('models/') ? model : 'models/$model',
        'generationConfig': {
          'responseModalities': ['AUDIO'],
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {'voiceName': config.effectiveVoice},
            },
          },
          if (config.reasoning.isNotEmpty)
            'thinkingConfig': {'thinkingLevel': config.reasoning},
        },
        'systemInstruction': {
          'parts': [
            {'text': instructions},
          ],
        },
        if (declarations.isNotEmpty || config.search)
          'tools': [
            if (config.search) {'googleSearch': <String, Object?>{}},
            if (declarations.isNotEmpty) {'functionDeclarations': declarations},
          ],
        if (config.proactive) 'proactivity': {'proactiveAudio': true},
        'inputAudioTranscription': <String, Object?>{},
        'outputAudioTranscription': <String, Object?>{},
      },
    };
  }

  /// A tool as Gemini declares it. Its parameters take a subset of JSON
  /// Schema and refuse the whole setup over anything else, so the schema
  /// is rewritten into that subset. A tool without arguments has no
  /// parameters at all: Gemini refuses an object with no properties.
  static Map<String, Object?> functionDeclaration(RealtimeToolSpec tool) {
    final parameters = geminiSchema(tool.parameters);
    return {
      'name': tool.name,
      'description': tool.description,
      if (parameters != null &&
          parameters['type'] == 'OBJECT' &&
          parameters.containsKey('properties'))
        'parameters': parameters,
    };
  }

  /// [schema] in the part of OpenAPI's schema Gemini takes, null when
  /// nothing of it is left (an object with no properties).
  static Map<String, Object?>? geminiSchema(Object? schema) {
    if (schema is! Map) return null;
    final out = <String, Object?>{};
    var type = schema['type'];
    var nullable = schema['nullable'] == true;
    if (type is List) {
      final types = [
        for (final t in type)
          if (t != 'null') t,
      ];
      nullable = nullable || types.length < type.length;
      type = types.isEmpty ? null : types.first;
    }
    final variants = schema['anyOf'] ?? schema['oneOf'];
    if (type == null && variants is List) {
      final options = [for (final v in variants) ?geminiSchema(v)];
      if (options.isEmpty) return null;
      if (options.length == 1) return options.single;
      out['anyOf'] = options;
    } else {
      type ??= schema['properties'] is Map
          ? 'object'
          : schema['items'] is Map
          ? 'array'
          : 'string';
      out['type'] = '$type'.toUpperCase();
    }
    for (final field in ['title', 'description']) {
      if (schema[field] is String) out[field] = schema[field];
    }
    if (nullable) out['nullable'] = true;
    switch (out['type']) {
      case 'STRING':
        final values = schema['enum'] ?? [?schema['const']];
        if (values is List && values.isNotEmpty) {
          out['enum'] = [for (final v in values) '$v'];
          out['format'] = 'enum';
        } else if (schema['format'] == 'date-time') {
          out['format'] = 'date-time';
        }
        for (final field in ['minLength', 'maxLength', 'pattern']) {
          if (schema[field] != null) out[field] = schema[field];
        }
      case 'INTEGER' || 'NUMBER':
        for (final field in ['minimum', 'maximum']) {
          if (schema[field] is num) out[field] = schema[field];
        }
      case 'ARRAY':
        out['items'] =
            geminiSchema(schema['items']) ?? const {'type': 'STRING'};
        for (final field in ['minItems', 'maxItems']) {
          if (schema[field] is num) out[field] = schema[field];
        }
      case 'OBJECT':
        final properties = <String, Object?>{};
        if (schema['properties'] case final Map props) {
          for (final MapEntry(:key, :value) in props.entries) {
            if (geminiSchema(value) case final s?) properties['$key'] = s;
          }
        }
        if (properties.isEmpty) return null;
        out['properties'] = properties;
        final required = [
          if (schema['required'] case final List list)
            for (final name in list)
              if (properties.containsKey('$name')) '$name',
        ];
        if (required.isNotEmpty) out['required'] = required;
    }
    return out;
  }

  void _send(Map<String, Object?> message) {
    final socket = _socket;
    if (socket == null || _closing) return;
    try {
      socket.send(jsonEncode(message));
    } catch (e) {
      _note('send', 'send failed: $e');
    }
  }

  @override
  void sendAudio(Uint8List pcm) {
    if (!_ready || pcm.isEmpty) return;
    _send({
      'realtimeInput': {
        'audio': {
          'data': base64Encode(pcm),
          'mimeType': 'audio/pcm;rate=$inputRate',
        },
      },
    });
  }

  /// Gemini cannot be told an answer was cut short: it stops one only when
  /// it hears the user over it. What it sends of a cut answer after this
  /// is dropped by the session, which knows the answer by its item.
  @override
  void interrupted(String itemId, int playedMs) {}

  /// Gemini keeps the turns ([RealtimeCapabilities.clientTurns] is off).
  @override
  void userTurn({required bool keep}) {}

  /// Gemini's speech detection stays on: it only ever hears the user's
  /// speech while Ground Control follows them, and the end of the audio
  /// stream flushes the turn. Its client activity signals were reported
  /// to answer too early on Gemini 3.1.
  @override
  void endTurn() {
    if (!_ready) return;
    _send({
      'realtimeInput': {'audioStreamEnd': true},
    });
  }

  /// Nothing to switch back: its speech detection never went off.
  @override
  void autoTurns() {}

  /// Gemini has no system items mid-conversation and a typed turn would
  /// get an answer: the speaker stays out of its context.
  @override
  void speaker(String name) {}

  /// A typed turn asking for the line. Gemini has no instructions per
  /// answer.
  @override
  void speak(String line) {
    if (!_ready) return;
    _send({
      'realtimeInput': {'text': realtimeSpeakPrompt(line)},
    });
  }

  void _onMessage(Object? raw) {
    final Map<String, Object?> msg;
    try {
      msg =
          (jsonDecode(raw is String ? raw : utf8.decode(raw as List<int>))
                  as Map)
              .cast<String, Object?>();
    } catch (e) {
      _note('message', 'unreadable message: ${realtimeLogText('$e')}');
      return;
    }
    for (final key in msg.keys) {
      if (!_known.contains(key)) {
        _note('key $key', '$key: ${realtimeLogText(msg[key])}');
      }
    }
    if (msg.containsKey('setupComplete')) _markReady();
    if (msg['serverContent'] case final Map content) _onContent(content);
    if (msg['toolCall'] case final Map call) {
      _beginAnswer();
      for (final fc in (call['functionCalls'] as List? ?? const [])) {
        if (fc is! Map) continue;
        final args = fc['args'];
        unawaited(
          _runTool(
            '${fc['id'] ?? ''}',
            '${fc['name'] ?? ''}',
            args is Map ? args.cast<String, Object?>() : const {},
          ),
        );
      }
    }
    if (msg['toolCallCancellation'] case final Map cancel) {
      for (final id in (cancel['ids'] as List? ?? const [])) {
        _cancelled.add('$id');
      }
    }
    if (msg['goAway'] case final Map away) {
      log?.call('the provider ends the connection in ${away['timeLeft']}');
    }
  }

  void _onContent(Map content) {
    if (content['interrupted'] == true) {
      // Gemini heard the user over the answer and stopped it.
      _completeExchange();
      _hear();
    }
    if (content['inputTranscription'] case final Map input) {
      final text = '${input['text'] ?? ''}';
      if (text.isNotEmpty) {
        final late =
            _answerEnded != null &&
            DateTime.now().difference(_answerEnded!) < lateTranscript;
        if (!_responding && !late) _hear();
        _heard.write(text);
        final so = _heard.toString().trim();
        if (so.isNotEmpty) _emit(RealtimeUserText(so, complete: false));
        if (_hearing) {
          _quietTimer?.cancel();
          _quietTimer = Timer(speechQuiet, _stoppedTalking);
        }
      }
    }
    if (content['modelTurn'] case final Map turn) {
      for (final part in (turn['parts'] as List? ?? const [])) {
        if (part is! Map) continue;
        final data = part['inlineData'];
        if (data is! Map || '${data['mimeType'] ?? ''}'.startsWith('text')) {
          continue;
        }
        final audio = data['data'];
        if (audio is! String || audio.isEmpty) continue;
        _beginAnswer();
        try {
          _emit(RealtimeAudio(_item, base64Decode(audio)));
        } catch (e) {
          _note('audio', 'unreadable audio: $e');
        }
      }
    }
    if (content['outputTranscription'] case final Map output) {
      final text = '${output['text'] ?? ''}';
      if (text.isNotEmpty) {
        _beginAnswer();
        _answer.write(text);
        _emit(RealtimeAnswerText(_answer.toString()));
      }
    }
    // A turn with no answer open is the one just interrupted.
    if (content['turnComplete'] == true && _responding) {
      _completeExchange();
      _emit(const RealtimeResponseDone());
    }
  }

  /// The exchange is over: what the user said and the answer, in that
  /// order. The user's transcript comes in apart from the answer and can
  /// still grow after the answer starts, so it is only final here.
  void _completeExchange() {
    final heard = _heard.toString().trim();
    _heard.clear();
    if (heard.isNotEmpty) _emit(RealtimeUserText(heard));
    if (_responding && _answer.isNotEmpty) {
      _emit(RealtimeAnswerText(_answer.toString(), complete: true));
    }
    _closeAnswer();
  }

  /// The transcript shows the user talking.
  void _hear() {
    if (_hearing) return;
    _hearing = true;
    _emit(const RealtimeSpeechStarted());
  }

  /// The user stopped talking: the answer started, a tool was called or
  /// the transcript went quiet.
  void _stoppedTalking() {
    _quietTimer?.cancel();
    if (!_hearing) return;
    _hearing = false;
    _emit(const RealtimeSpeechStopped());
  }

  /// The model's turn started, with its voice or a tool call.
  void _beginAnswer() {
    if (_responding) return;
    _stoppedTalking();
    _responding = true;
    _item = 'answer-${++_answers}';
    _answer.clear();
    _emit(const RealtimeResponseStarted());
  }

  void _closeAnswer() {
    _responding = false;
    _answerEnded = DateTime.now();
    _answer.clear();
  }

  void _markReady() {
    if (_ready || _closing) return;
    _ready = true;
    _readyTimer?.cancel();
    log?.call('session ready');
    _emit(const RealtimeReady());
  }

  Future<void> _runTool(
    String id,
    String name,
    Map<String, Object?> args,
  ) async {
    if (name.isEmpty) return;
    final display = toolbox.originalName(name);
    _emit(RealtimeToolActivity(display));
    final output = await toolbox.call(name, args);
    if (output.error) {
      log?.call('tool $display failed: ${realtimeLogText(output.text)}');
    }
    if (_closing) return;
    _emit(RealtimeToolActivity(display, done: true, error: output.error));
    // Gemini waits for every call's output before it goes on, the one that
    // ends the conversation too: without it the turn never completes.
    if (!_cancelled.remove(id)) {
      _send({
        'toolResponse': {
          'functionResponses': [
            {
              if (id.isNotEmpty) 'id': id,
              'name': name,
              'response': {output.error ? 'error' : 'result': output.text},
            },
          ],
        },
      });
    }
    if (output.endConversation) _emit(const RealtimeEndRequested());
  }

  void _finish({String? error}) {
    _readyTimer?.cancel();
    _quietTimer?.cancel();
    if (_events.isClosed) return;
    if (error != null) log?.call('closed: $error');
    _emit(RealtimeClosed(error: error));
    unawaited(_events.close());
  }

  @override
  Future<void> close() async {
    if (_closing) return;
    _closing = true;
    _readyTimer?.cancel();
    _quietTimer?.cancel();
    await _sub?.cancel();
    await _socket?.close();
    toolbox.close();
    if (!_events.isClosed) await _events.close();
  }
}
