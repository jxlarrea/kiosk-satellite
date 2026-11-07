/// The seam between a realtime voice session and whatever runs the model.
///
/// The session owns the device side: the microphone, the echo canceller's
/// route, playback, barge-in and the overlay. A backend owns the model side:
/// the connection, the conversation and the tools. Today the one backend
/// talks to the provider directly (OpenAI's realtime protocol, which xAI
/// follows). When Home Assistant's pipeline engines can run audio-to-audio
/// models, a backend over the ESPHome satellite takes its place and the
/// session does not change. That is why tools stay inside the backend: with
/// Home Assistant they run in Home Assistant, and the session only shows
/// that they ran.
library;

import 'dart:convert';
import 'dart:typed_data';

/// What a backend can do, read before the session starts streaming.
class RealtimeCapabilities {
  const RealtimeCapabilities({
    this.inputRate = 24000,
    this.outputRate = 24000,
    this.serverBargeIn = true,
    this.clientTurns = false,
  });

  /// The microphone audio it takes, PCM16 mono at this rate.
  final int inputRate;

  /// The voice it sends back, PCM16 mono at this rate.
  final int outputRate;

  /// The backend hears the user start talking over an answer and says so
  /// ([RealtimeSpeechStarted]). False leaves barge-in to the stop word.
  final bool serverBargeIn;

  /// Speech heard neither stops an answer nor gets a reply on its own: the
  /// session decides each turn ([RealtimeBackend.userTurn]) and stops the
  /// answer itself ([RealtimeBackend.interrupted]). A faint echo of the
  /// answer the provider takes for speech then does nothing. Without it,
  /// the provider hears nothing over an answer until the session decides
  /// the user is talking over it.
  final bool clientTurns;
}

/// Why and how the session started.
class RealtimeStart {
  const RealtimeStart({
    this.wakeWord = '',
    this.language = '',
    this.context = '',
    this.history = const [],
  });

  /// The wake word that started it, empty for a manual wake.
  final String wakeWord;

  /// The kiosk's language, a hint for transcription.
  final String language;

  /// Where the kiosk is, added to the instructions: its name and its area
  /// in Home Assistant, so "the lights" are the ones in this room.
  final String context;

  /// Earlier exchanges still within the session duration, oldest first.
  final List<RealtimeTurn> history;
}

/// One side of an earlier exchange: what the user said or the answer.
class RealtimeTurn {
  const RealtimeTurn({required this.user, required this.text});

  /// True for the user, false for the assistant.
  final bool user;
  final String text;
}

sealed class RealtimeEvent {
  const RealtimeEvent();
}

/// The connection is up and the model is listening.
class RealtimeReady extends RealtimeEvent {
  const RealtimeReady();
}

/// A piece of the answer's audio. [itemId] names the answer it belongs to,
/// which is what an interruption refers back to.
class RealtimeAudio extends RealtimeEvent {
  const RealtimeAudio(this.itemId, this.pcm);
  final String itemId;
  final Uint8List pcm;
}

/// The user started talking. While an answer plays, this is a barge-in.
/// [audioMs] is where the speech starts in the audio sent this session,
/// when the provider says (OpenAI and xAI's audio_start_ms). It arrives
/// half a second or more after the speech started.
class RealtimeSpeechStarted extends RealtimeEvent {
  const RealtimeSpeechStarted({this.audioMs});
  final int? audioMs;
}

/// [audioMs] is where the speech ends in the audio sent this session, when
/// the provider says.
class RealtimeSpeechStopped extends RealtimeEvent {
  const RealtimeSpeechStopped({this.audioMs});
  final int? audioMs;
}

/// What the user said, once transcribed. [complete] is false while the
/// transcript is still growing.
class RealtimeUserText extends RealtimeEvent {
  const RealtimeUserText(this.text, {this.complete = true});
  final String text;
  final bool complete;
}

/// The answer's words so far, as the model speaks them.
class RealtimeAnswerText extends RealtimeEvent {
  const RealtimeAnswerText(this.text, {this.complete = false});
  final String text;
  final bool complete;
}

/// The model called a tool. [done] is false while it runs.
class RealtimeToolActivity extends RealtimeEvent {
  const RealtimeToolActivity(
    this.name, {
    this.done = false,
    this.error = false,
  });
  final String name;
  final bool done;
  final bool error;
}

/// The model started an answer.
class RealtimeResponseStarted extends RealtimeEvent {
  const RealtimeResponseStarted();
}

/// The model finished generating an answer. It may still be playing.
class RealtimeResponseDone extends RealtimeEvent {
  const RealtimeResponseDone();
}

/// The model decided the conversation is over (the user said goodbye).
/// The session ends once the answer finishes playing.
class RealtimeEndRequested extends RealtimeEvent {
  const RealtimeEndRequested();
}

/// The backend is gone. [error] says why when it was not asked to go.
class RealtimeClosed extends RealtimeEvent {
  const RealtimeClosed({this.error});
  final String? error;
}

/// A problem worth telling the user that does not end the session.
class RealtimeWarning extends RealtimeEvent {
  const RealtimeWarning(this.message);
  final String message;
}

abstract class RealtimeBackend {
  RealtimeCapabilities get capabilities;

  /// Everything the model side reports, in order. One listener.
  Stream<RealtimeEvent> get events;

  /// Connects and configures the conversation. [RealtimeReady] or
  /// [RealtimeClosed] follows.
  Future<void> start(RealtimeStart start);

  /// Microphone audio at [RealtimeCapabilities.inputRate].
  void sendAudio(Uint8List pcm);

  /// Playback of [itemId] was cut after [playedMs]: the user talked over
  /// it, or it was stopped. The model forgets what was not heard.
  void interrupted(String itemId, int playedMs);

  /// With [RealtimeCapabilities.clientTurns]: the speech that just ended
  /// was the user ([keep], and it gets a reply) or not (it is dropped from
  /// the conversation, unanswered).
  void userTurn({required bool keep});

  /// The model says [line] word for word, in its own voice, as its answer,
  /// and listens after it: Home Assistant's start_conversation, where the
  /// assistant speaks first.
  void speak(String line);

  /// Closes the connection. No events follow.
  Future<void> close();
}

/// [value] for a log line: JSON when it is JSON, cut at [max] characters.
String realtimeLogText(Object? value, {int max = 300}) {
  String text;
  try {
    text = value is String ? value : jsonEncode(value);
  } catch (_) {
    text = '$value';
  }
  return text.length > max ? '${text.substring(0, max)}...' : text;
}

/// What a backend asks for to have [line] spoken as it is. OpenAI, xAI and
/// Gemini all said it word for word in a live test (2026-10-06), a line in
/// another language and one that reads like an instruction too.
String realtimeSpeakPrompt(String line) =>
    'Say exactly this to the user, word for word, and nothing else: "$line"';

/// What the kiosk adds after a conversation's instructions: where it is
/// and the earlier exchanges.
String realtimeContextText({
  String context = '',
  List<RealtimeTurn> history = const [],
}) => [
  if (context.trim().isNotEmpty) context.trim(),
  if (history.isNotEmpty)
    [
      'Earlier conversations with the user, oldest first. Use them when '
          'the user refers back to something:',
      for (final turn in history)
        '${turn.user ? 'User' : 'Assistant'}: ${turn.text}',
    ].join('\n'),
].join('\n\n');
