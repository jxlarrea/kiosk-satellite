/// What the assist overlay shows, as one immutable snapshot the native voice
/// satellite publishes and the overlay draws. Kept free of Flutter so the
/// session can be tested without widgets.
library;

enum AssistPhase {
  /// Nothing on screen.
  hidden,

  /// Listening for the command: the bar follows the voice.
  listening,

  /// The command is in; the assistant is working on it.
  thinking,

  /// The answer is on screen (and usually being spoken).
  speaking,

  /// An announcement from Home Assistant, centered.
  announcement,
}

/// One result a turn produced: weather, a stock quote, images, videos.
/// [kind] names the panel, [data] is the tool result as Home Assistant sent
/// it (see results.dart for the shapes each panel reads).
class AssistResult {
  const AssistResult(this.kind, this.data);
  final String kind;
  final Map<String, Object?> data;

  Map<String, Object?> toJson() => {'kind': kind, 'data': data};

  static AssistResult? fromJson(Object? raw) {
    if (raw is! Map || raw['kind'] is! String) return null;
    final data = raw['data'];
    return AssistResult(
      raw['kind'] as String,
      data is Map ? data.cast<String, Object?>() : const {},
    );
  }
}

/// A finished turn of the conversation, kept on screen above the turns
/// after it, as Voice Satellite keeps every line of a conversation.
class AssistTurn {
  const AssistTurn({
    this.command = '',
    this.tools = const [],
    this.answer = '',
    this.speaker = '',
    this.speakerColor,
  });

  final String command;
  final List<String> tools;
  final String answer;

  /// Who said [command], from Voice Match, and their ring color
  /// (`#RRGGBB`). Empty when not known.
  final String speaker;
  final String? speakerColor;

  bool get isEmpty => command.isEmpty && tools.isEmpty && answer.isEmpty;

  Map<String, Object?> toJson() => {
    'command': command,
    'tools': tools,
    'answer': answer,
    'speaker': speaker,
    'speakerColor': ?speakerColor,
  };

  static AssistTurn fromJson(Object? raw) {
    if (raw is! Map) return const AssistTurn();
    return AssistTurn(
      command: _string(raw['command']),
      tools: _strings(raw['tools']),
      answer: _string(raw['answer']),
      speaker: _string(raw['speaker']),
      speakerColor: raw['speakerColor'] is String
          ? raw['speakerColor'] as String
          : null,
    );
  }
}

String _string(Object? v) => v is String ? v : '';

List<String> _strings(Object? v) => v is List
    ? [
        for (final e in v)
          if (e is String) e,
      ]
    : const [];

class AssistView {
  const AssistView({
    this.phase = AssistPhase.hidden,
    this.earlier = const [],
    this.command = '',
    this.answer = '',
    this.streaming = false,
    this.tools = const [],
    this.results = const [],
    this.reactive = true,
    this.docked = false,
    this.lingering = false,
    this.assistant = 1,
    this.speaker = '',
    this.speakerColor,
  });

  static const hidden = AssistView();

  final AssistPhase phase;

  /// The conversation's earlier turns, oldest first. The lines below
  /// ([command], [tools], [answer]) are the turn in progress.
  final List<AssistTurn> earlier;

  /// What the user said (speech to text), or the prompt of a show.
  final String command;

  /// The assistant's answer, or the announcement's text.
  final String answer;

  /// Whether [answer] is still arriving (a vs_show streams it in).
  final bool streaming;

  /// One line per action the assistant took ("Turn on").
  final List<String> tools;

  final List<AssistResult> results;

  /// Whether the bar follows the audio level right now. Off while the wake
  /// chime plays and while the assistant thinks.
  final bool reactive;

  /// A realtime conversation: the bar along the edge and a small caption,
  /// with the screen under it visible and usable.
  final bool docked;

  /// The turn is over and its answer or results stay on screen. Nothing
  /// listens or speaks, so the skin's bar is down.
  final bool lingering;

  /// Who answers, 1 or 2, which picks the skin: 2 for wake word 2 and a
  /// vs_show on pipeline 2.
  final int assistant;

  /// Who is talking in the turn in progress, from Voice Match, and their
  /// ring color (`#RRGGBB`). Empty when not known.
  final String speaker;
  final String? speakerColor;

  bool get visible => phase != AssistPhase.hidden;

  /// The snapshot as a companion screen receives it.
  Map<String, Object?> toJson() => {
    'phase': phase.name,
    'earlier': [for (final t in earlier) t.toJson()],
    'command': command,
    'answer': answer,
    'streaming': streaming,
    'tools': tools,
    'results': [for (final r in results) r.toJson()],
    'reactive': reactive,
    'docked': docked,
    'lingering': lingering,
    'assistant': assistant,
    'speaker': speaker,
    'speakerColor': ?speakerColor,
  };

  /// A snapshot from [toJson]. Anything it cannot read reads hidden.
  static AssistView fromJson(Object? raw) {
    if (raw is! Map) return hidden;
    final phase = AssistPhase.values
        .where((p) => p.name == raw['phase'])
        .firstOrNull;
    if (phase == null) return hidden;
    final earlier = raw['earlier'];
    final results = raw['results'];
    final assistant = raw['assistant'];
    return AssistView(
      phase: phase,
      earlier: earlier is List
          ? [for (final t in earlier) AssistTurn.fromJson(t)]
          : const [],
      command: _string(raw['command']),
      answer: _string(raw['answer']),
      streaming: raw['streaming'] == true,
      tools: _strings(raw['tools']),
      results: results is List
          ? [for (final r in results) ?AssistResult.fromJson(r)]
          : const [],
      reactive: raw['reactive'] != false,
      docked: raw['docked'] == true,
      lingering: raw['lingering'] == true,
      assistant: assistant == 2 ? 2 : 1,
      speaker: _string(raw['speaker']),
      speakerColor: raw['speakerColor'] is String
          ? raw['speakerColor'] as String
          : null,
    );
  }

  /// The turn in progress, as it would be kept once the next one starts.
  AssistTurn get turn => AssistTurn(
    command: command,
    tools: tools,
    answer: answer,
    speaker: speaker,
    speakerColor: speakerColor,
  );

  AssistView copyWith({
    AssistPhase? phase,
    List<AssistTurn>? earlier,
    String? command,
    String? answer,
    bool? streaming,
    List<String>? tools,
    List<AssistResult>? results,
    bool? reactive,
    bool? docked,
    bool? lingering,
    int? assistant,
    String? speaker,
    String? speakerColor,
  }) => AssistView(
    phase: phase ?? this.phase,
    earlier: earlier ?? this.earlier,
    command: command ?? this.command,
    answer: answer ?? this.answer,
    streaming: streaming ?? this.streaming,
    tools: tools ?? this.tools,
    results: results ?? this.results,
    reactive: reactive ?? this.reactive,
    docked: docked ?? this.docked,
    lingering: lingering ?? this.lingering,
    assistant: assistant ?? this.assistant,
    speaker: speaker ?? this.speaker,
    speakerColor: speaker != null ? speakerColor : this.speakerColor,
  );
}

/// The turn in Home Assistant's assist_satellite states (idle, listening,
/// processing, responding), for the Voice Satellite sensor. [busy] is
/// whether a turn or a conversation runs: a preview or an answer left on
/// screen after its turn reads idle.
String satelliteState(AssistView view, {required bool busy}) {
  if (!busy || view.lingering) return 'idle';
  return switch (view.phase) {
    AssistPhase.hidden => 'idle',
    AssistPhase.listening => 'listening',
    AssistPhase.thinking => 'processing',
    AssistPhase.speaking || AssistPhase.announcement => 'responding',
  };
}

/// Voice Satellite's estimate of how long [text] takes to say, in seconds:
/// 2.8 words a second, 0.7 more per number, three at least.
double estimateSpeechSeconds(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  final words = trimmed.split(RegExp(r'\s+')).length;
  final numbers = RegExp(r'\d[\d,.]*%?').allMatches(text).length;
  final seconds = words / 2.8 + numbers * 0.7;
  return seconds < 3 ? 3 : seconds;
}
