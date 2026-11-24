import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/voice/assist_view.dart';
import 'package:kiosk_satellite/managers/voice/voice_session.dart';

class _Link implements VoiceLinkPort {
  final requests = <(bool, String)>[];
  final sent = <Uint8List>[];
  int finishedCount = 0;
  bool subscribed = true;

  @override
  Future<bool> request({
    required bool start,
    String wakeWordPhrase = '',
  }) async {
    requests.add((start, wakeWordPhrase));
    return subscribed;
  }

  @override
  Future<bool> audio(Uint8List pcm) async {
    sent.add(pcm);
    return true;
  }

  int audioEnds = 0;

  @override
  Future<bool> audioEnd() async {
    audioEnds++;
    return true;
  }

  @override
  Future<bool> finished() async {
    finishedCount++;
    return true;
  }
}

class _Mic implements VoiceMicPort {
  void Function(Uint8List pcm, bool preRoll)? sink;
  int opens = 0;
  int closes = 0;

  @override
  Future<bool> open(void Function(Uint8List pcm, bool preRoll) onChunk) async {
    opens++;
    sink = onChunk;
    return true;
  }

  @override
  Future<void> close() async {
    closes++;
    sink = null;
  }

  void speak(int value, {bool preRoll = false}) =>
      sink?.call(Uint8List(2560)..fillRange(0, 2560, value), preRoll);
}

class _Player implements VoicePlayerPort {
  final played = <String>[];
  final chimes = <String>[];
  final stopped = <String>[];
  final announcements = <String>[];
  int settled = 0;
  int _next = 0;

  @override
  Future<String?> play(
    String url, {
    String text = '',
    bool announcement = false,
  }) async {
    played.add(url);
    if (announcement) announcements.add(url);
    return 'snd${++_next}';
  }

  @override
  Future<(String, double)?> chime(String kind) async {
    chimes.add(kind);
    return ('snd${++_next}', 0.3);
  }

  @override
  Future<void> stop(String id) async => stopped.add(id);

  @override
  Future<void> settle() async => settled++;

  String get lastId => 'snd$_next';
}

class _MatchTurn implements VoiceMatchTurnPort {
  _MatchTurn(
    this.onEvent, {
    this.onAudio,
    this.onLost,
    this.follow = false,
    this.followup = false,
    this.seamless = false,
    this.asked = false,
  });
  final void Function(Map<String, Object?> event) onEvent;
  final void Function(Uint8List pcm)? onAudio;
  final void Function()? onLost;
  final bool follow;
  final bool followup;
  final bool seamless;
  final bool asked;
  int fed = 0;
  bool ended = false;
  String? kind;

  @override
  bool ready = true;

  @override
  void interaction(String kind) => this.kind = kind;

  @override
  void feed(Uint8List pcm) => fed++;

  @override
  void end() => ended = true;

  /// The service sending back the user's speech.
  void user(int value) =>
      onAudio?.call(Uint8List(2560)..fillRange(0, 2560, value));
}

class _Match implements VoiceMatchPort {
  _Match({this.ready = true});
  final bool ready;
  final turns = <_MatchTurn>[];

  @override
  VoiceMatchTurnPort? begin(
    void Function(Map<String, Object?> event) onEvent, {
    bool follow = false,
    bool followup = false,
    bool seamless = false,
    bool asked = false,
    void Function(Uint8List pcm)? onAudio,
    void Function()? onLost,
  }) {
    final t = _MatchTurn(
      onEvent,
      onAudio: onAudio,
      onLost: onLost,
      follow: follow,
      followup: followup,
      seamless: seamless,
      asked: asked,
    )..ready = ready;
    turns.add(t);
    return t;
  }
}

/// Voice Match saying who is talking only, with the microphone going to
/// Home Assistant as without it.
const _live = VoiceSessionOptions(matchEndOnOtherVoice: false);

class _Harness {
  _Harness({
    this.options = const VoiceSessionOptions(),
    FakeAsync? time,
    this.match,
  }) {
    session = VoiceSession(
      link: link,
      mic: mic,
      player: player,
      options: () => options,
      onView: views.add,
      onLevel: (_) {},
      onBusy: (busy, reason) => busy_.add((busy, reason)),
      onStopArmed: stopArmed.add,
      onError: (code, message) => errors.add(code),
      onIdle: () => idles++,
      onTrace: (step, {text}) => traces.add((step, text)),
      voiceMatch: match,
      onSpeaker: speakers.add,
      now: time == null ? null : () => DateTime(2026).add(time.elapsed),
    );
  }

  final _Match? match;
  final speakers = <Map<String, Object?>?>[];

  VoiceSessionOptions options;
  late final VoiceSession session;
  final link = _Link();
  final mic = _Mic();
  final player = _Player();
  final views = <AssistView>[];
  final busy_ = <(bool, String)>[];
  final stopArmed = <bool>[];
  final errors = <String>[];
  final traces = <(String, String?)>[];
  int idles = 0;

  AssistView get view => views.last;
}

void main() {
  test('a turn: chime, stream past the chime, answer, done', () {
    fakeAsync((async) {
      final h = _Harness();
      h.session.wake('Okay Nabu');
      async.flushMicrotasks();
      expect(h.link.requests.single, (true, 'Okay Nabu'));
      expect(h.view.phase, AssistPhase.listening);
      // Heard over the dedupe window and the chime: never sent.
      h.mic.speak(1, preRoll: true);
      async.elapse(const Duration(milliseconds: 250));
      expect(h.player.chimes, ['wake']);
      h.mic.speak(2);
      async.elapse(const Duration(milliseconds: 600));
      expect(h.link.sent, isEmpty);
      h.mic.speak(3);
      expect(h.link.sent.single.first, 3);

      h.session.onEvent(VaEvent.sttStart, {});
      h.session.onEvent(VaEvent.sttEnd, {'text': 'turn on the lights'});
      async.flushMicrotasks();
      expect(h.mic.closes, 1);
      expect(h.view.phase, AssistPhase.thinking);
      expect(h.view.command, 'turn on the lights');

      h.session.onEvent(VaEvent.intentEnd, {
        'conversation_id': 'c1',
        'continue_conversation': '0',
      });
      h.session.onEvent(VaEvent.ttsStart, {'text': 'Done.'});
      h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/tts.mp3'});
      async.flushMicrotasks();
      expect(h.player.played, ['http://ha/tts.mp3']);
      expect(h.view.answer, 'Done.');
      h.session.onEvent(VaEvent.runEnd, {});
      async.flushMicrotasks();
      // Still speaking: the run's end waits for the playback.
      expect(h.session.busy, isTrue);
      h.session.onSoundEnded(h.player.lastId);
      async.flushMicrotasks();
      expect(h.link.finishedCount, 1);
      expect(h.player.chimes, ['wake', 'done']);
      expect(h.session.busy, isFalse);
      expect(h.view.phase, AssistPhase.hidden);
      expect(h.busy_, [(true, 'voice'), (false, '')]);
      expect(h.idles, 1);
    });
  });

  test('seamless: no chime and the pre-roll goes up', () {
    fakeAsync((async) {
      final h = _Harness(options: const VoiceSessionOptions(seamless: true));
      h.session.wake('Okay Nabu');
      async.flushMicrotasks();
      h.mic.speak(9, preRoll: true);
      async.flushMicrotasks();
      expect(h.player.chimes, isEmpty);
      expect(h.link.sent.single.first, 9);
    });
  });

  test('a duplicate wake ends silently, other expected errors with done', () {
    fakeAsync((async) {
      final h = _Harness();
      h.session.wake('Okay Nabu');
      async.flushMicrotasks();
      h.session.onEvent(VaEvent.error, {
        'code': 'duplicate_wake_up_detected',
        'message': 'x',
      });
      async.elapse(const Duration(seconds: 2));
      expect(h.player.chimes, isEmpty);
      expect(h.errors, isEmpty);
      expect(h.session.busy, isFalse);
      // No chime ends it: a speaker gets its music back regardless.
      expect(h.player.settled, 1);

      h.session.wake('Okay Nabu');
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));
      h.session.onEvent(VaEvent.error, {
        'code': 'stt-no-text-recognized',
        'message': 'x',
      });
      async.flushMicrotasks();
      expect(h.player.chimes, ['wake', 'done']);
      expect(h.errors, isEmpty);
    });
  });

  test('an unexpected error is reported with the error chime', () {
    fakeAsync((async) {
      final h = _Harness();
      h.session.wake('Okay Nabu');
      async.elapse(const Duration(seconds: 1));
      h.session.onEvent(VaEvent.error, {
        'code': 'intent-failed',
        'message': 'boom',
      });
      async.flushMicrotasks();
      expect(h.errors, ['intent-failed']);
      expect(h.player.chimes.last, 'error');
      expect(h.session.busy, isFalse);
    });
  });

  test('not connected: says so and stays out of the way', () {
    fakeAsync((async) {
      final h = _Harness();
      h.link.subscribed = false;
      h.session.wake('Okay Nabu');
      async.flushMicrotasks();
      expect(h.errors, ['not-connected']);
      expect(h.mic.closes, 1);
      expect(h.session.busy, isFalse);
    });
  });

  test('a follow-up listens again without a new wake word', () {
    fakeAsync((async) {
      final h = _Harness(time: async);
      h.session.wake('Hey Jarvis');
      async.elapse(const Duration(seconds: 5));
      h.session.onEvent(VaEvent.sttEnd, {'text': 'set a timer'});
      h.session.onEvent(VaEvent.intentEnd, {
        'conversation_id': 'c1',
        'continue_conversation': '1',
      });
      h.session.onEvent(VaEvent.ttsStart, {'text': 'For how long?'});
      h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/q.mp3'});
      async.flushMicrotasks();
      h.session.onSoundEnded(h.player.lastId);
      async.flushMicrotasks();
      h.session.onEvent(VaEvent.runEnd, {});
      async.flushMicrotasks();
      // Same wake word, so Home Assistant keeps pipeline 2.
      expect(h.link.requests.last, (true, 'Hey Jarvis'));
      expect(h.mic.opens, 2);
      expect(h.session.busy, isTrue);
      expect(h.view.phase, AssistPhase.listening);
      // The first turn stays on screen; the second starts its own lines.
      expect(h.view.earlier.single.command, 'set a timer');
      expect(h.view.earlier.single.answer, 'For how long?');
      expect(h.view.command, isEmpty);
      expect(h.view.answer, isEmpty);

      async.elapse(const Duration(seconds: 1));
      h.session.onEvent(VaEvent.sttEnd, {'text': 'five minutes'});
      h.session.onEvent(VaEvent.ttsStart, {'text': 'Timer set.'});
      async.flushMicrotasks();
      expect(h.view.earlier.single.command, 'set a timer');
      expect(h.view.command, 'five minutes');
      expect(h.view.answer, 'Timer set.');
    });
  });

  test('the answer\'s playback clock runs from the player\'s reports', () {
    fakeAsync((async) {
      final h = _Harness(time: async);
      h.session.wake('Okay Nabu');
      async.elapse(const Duration(seconds: 1));
      h.session.onEvent(VaEvent.sttEnd, {'text': 'tell me a story'});
      h.session.onEvent(VaEvent.ttsStart, {'text': 'Once upon a time.'});
      h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/story.mp3'});
      async.flushMicrotasks();
      final id = h.player.lastId;
      // A stream still arriving has no length yet: no clock.
      h.session.onSoundProgress(id, const Duration(seconds: 1), null);
      expect(h.session.playback, isNull);
      h.session.onSoundProgress(
        id,
        const Duration(seconds: 2),
        const Duration(seconds: 10),
      );
      expect(h.session.playback, (elapsed: 2.0, duration: 10.0));
      // Carried forward between reports, never past the end.
      async.elapse(const Duration(milliseconds: 500));
      expect(h.session.playback?.elapsed, 2.5);
      async.elapse(const Duration(seconds: 20));
      expect(h.session.playback?.elapsed, 10.0);
      // Someone else's sound does not move it; the answer's end clears it.
      h.session.onSoundProgress(
        'other',
        Duration.zero,
        const Duration(seconds: 1),
      );
      expect(h.session.playback?.duration, 10.0);
      h.session.onSoundEnded(id);
      async.flushMicrotasks();
      expect(h.session.playback, isNull);
    });
  });

  test('a turn\'s steps are traced, what was said kept apart', () {
    fakeAsync((async) {
      final h = _Harness();
      h.session.wake('Okay Nabu');
      async.elapse(const Duration(seconds: 1));
      h.session.onEvent(VaEvent.sttEnd, {'text': 'lights on'});
      h.session.onEvent(VaEvent.intentEnd, {'continue_conversation': '0'});
      h.session.onEvent(VaEvent.ttsStart, {'text': 'Done.'});
      h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/done.mp3'});
      async.flushMicrotasks();
      h.session.onSoundEnded(h.player.lastId);
      h.session.onEvent(VaEvent.runEnd, {});
      async.flushMicrotasks();
      expect(h.traces.map((t) => t.$1).toList(), [
        'wake word "Okay Nabu"',
        'asked Home Assistant for the assistant',
        'command heard',
        'intent done',
        'answer',
        'answer played',
        startsWith('turn over'),
      ]);
      expect(h.traces[2].$2, 'lights on');
      expect(h.traces[4].$2, 'Done.');
      expect(h.traces.where((t) => t.$2 != null), hasLength(2));
    });
  });

  test('an answer that cannot play is reported', () {
    fakeAsync((async) {
      final h = _Harness();
      h.session.wake('Okay Nabu');
      async.elapse(const Duration(seconds: 1));
      h.session.onEvent(VaEvent.sttEnd, {'text': 'hello'});
      h.session.onEvent(VaEvent.ttsStart, {'text': 'Hi.'});
      h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/hi.mp3'});
      async.flushMicrotasks();
      h.session.onSoundEnded(h.player.lastId, error: 'decoder died');
      h.session.onEvent(VaEvent.runEnd, {});
      async.flushMicrotasks();
      expect(h.errors, ['playback']);
    });
  });

  test('a stuck pipeline is reported when the watchdog ends the turn', () {
    fakeAsync((async) {
      final h = _Harness();
      h.session.wake('Okay Nabu');
      async.elapse(const Duration(seconds: 1));
      h.session.onEvent(VaEvent.sttStart, {});
      async.elapse(VoiceSession.vadWatchdog + const Duration(seconds: 1));
      expect(h.errors, ['watchdog']);
      expect(h.session.busy, isFalse);
    });
  });

  test('losing Home Assistant mid-turn ends the turn at once', () {
    fakeAsync((async) {
      final h = _Harness();
      h.session.wake('Okay Nabu');
      async.elapse(const Duration(seconds: 1));
      h.session.onEvent(VaEvent.sttEnd, {'text': 'hello'});
      h.session.connectionLost();
      async.flushMicrotasks();
      expect(h.errors, ['connection-lost']);
      expect(h.session.busy, isFalse);
      expect(h.player.chimes.last, 'error');
      // Nothing is waiting on a pipeline once it is over: no report.
      h.session.connectionLost();
      async.flushMicrotasks();
      expect(h.errors, ['connection-lost']);
    });
  });

  test('cancel during the chime leaves nothing of the turn running', () {
    fakeAsync((async) {
      final h = _Harness();
      h.session.wake('Okay Nabu');
      async.elapse(const Duration(milliseconds: 300));
      h.session.cancel();
      async.elapse(const Duration(seconds: 2));
      h.mic.speak(5);
      expect(h.link.sent, isEmpty);
      expect(h.link.requests.last, (false, ''));
      expect(h.view.phase, AssistPhase.hidden);
      expect(h.session.busy, isFalse);
    });
  });

  test('the stop word is armed while the answer plays', () {
    fakeAsync((async) {
      final h = _Harness(options: const VoiceSessionOptions(stopWord: true));
      h.session.wake('Okay Nabu');
      async.elapse(const Duration(seconds: 1));
      h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/tts.mp3'});
      async.elapse(const Duration(milliseconds: 300));
      expect(h.stopArmed, [true]);
      h.session.cancel();
      async.flushMicrotasks();
      expect(h.player.stopped, isNotEmpty);
      expect(h.stopArmed.last, isFalse);
      // Home Assistant is told the answer ended.
      expect(h.link.finishedCount, 1);
    });
  });

  test('an announcement plays, reports and lingers', () {
    fakeAsync((async) {
      final h = _Harness();
      h.session.announce(
        const VoiceAnnouncement(
          mediaId: 'http://ha/a.mp3',
          text: 'The laundry is done.',
          preannounceMediaId:
              'http://ha/api/assist_satellite/static/preannounce.mp3',
          startConversation: false,
        ),
      );
      async.flushMicrotasks();
      expect(h.player.chimes, ['announce']);
      expect(h.view.phase, AssistPhase.announcement);
      expect(h.view.answer, 'The laundry is done.');
      h.session.onSoundEnded(h.player.lastId);
      async.flushMicrotasks();
      expect(h.player.played, ['http://ha/a.mp3']);
      expect(h.player.announcements, ['http://ha/a.mp3']);
      h.session.onSoundEnded(h.player.lastId);
      async.flushMicrotasks();
      expect(h.link.finishedCount, 1);
      expect(h.view.phase, AssistPhase.announcement);
      async.elapse(const Duration(seconds: 5));
      expect(h.view.phase, AssistPhase.hidden);
    });
  });

  test('start_conversation listens after the announcement', () {
    fakeAsync((async) {
      final h = _Harness();
      h.session.announce(
        const VoiceAnnouncement(
          mediaId: 'http://ha/q.mp3',
          text: 'Close the garage?',
          preannounceMediaId: '',
          startConversation: true,
        ),
      );
      async.flushMicrotasks();
      // The assistant's line in the chat layout, not a centered
      // announcement.
      expect(h.view.phase, AssistPhase.speaking);
      expect(h.view.answer, 'Close the garage?');
      h.session.onSoundEnded(h.player.lastId);
      async.flushMicrotasks();
      expect(h.link.finishedCount, 1);
      expect(h.link.requests.single, (true, ''));
      expect(h.view.phase, AssistPhase.listening);
      // The question moves above, the reply and its answer come under it.
      expect(h.view.earlier.single.answer, 'Close the garage?');
      expect(h.view.answer, isEmpty);
      // A follow-up's handoff: no chime with the follow-up chime off, and
      // the layout stays put.
      expect(h.player.chimes, isEmpty);
      expect(h.view.reactive, isTrue);
      expect(h.busy_.last, (true, 'voice'));
    });
  });

  test('ask_question: the reply goes to Home Assistant and the kiosk goes '
      'idle without confirming it', () {
    fakeAsync((async) {
      final h = _Harness();
      h.session.announce(
        const VoiceAnnouncement(
          mediaId: 'http://ha/q.mp3',
          text: 'Which room?',
          preannounceMediaId: '',
          startConversation: true,
        ),
      );
      async.flushMicrotasks();
      h.session.onSoundEnded(h.player.lastId);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));
      // Its pipeline ends at speech to text: no intent, no answer.
      h.session.onEvent(VaEvent.sttStart, {});
      h.session.onEvent(VaEvent.sttEnd, {'text': 'the garage'});
      async.flushMicrotasks();
      h.session.onEvent(VaEvent.runEnd, {});
      async.flushMicrotasks();
      expect(h.player.chimes, isNot(contains('done')));
      expect(h.session.busy, isFalse);
      expect(h.view.phase, AssistPhase.hidden);
    });
  });

  test('results keep the overlay up for their linger', () {
    fakeAsync((async) {
      final h = _Harness(
        options: const VoiceSessionOptions(resultsLingerSeconds: 30),
      );
      h.session.wake('Okay Nabu');
      async.elapse(const Duration(seconds: 1));
      h.session.onEvent(VaEvent.sttEnd, {'text': 'weather'});
      h.session.onEvent(VaEvent.intentEnd, {'conversation_id': 'c1'});
      h.session.showResults(
        tools: const ['Get weather forecast'],
        results: const [AssistResult('weather', {})],
      );
      h.session.onEvent(VaEvent.runEnd, {});
      async.flushMicrotasks();
      expect(h.session.busy, isFalse);
      expect(h.view.phase, isNot(AssistPhase.hidden));
      expect(h.view.tools, ['Get weather forecast']);
      // Nothing listens or speaks while it lingers: the bar is down.
      expect(h.view.lingering, isTrue);
      async.elapse(const Duration(seconds: 31));
      expect(h.view.phase, AssistPhase.hidden);
    });
  });

  group('the stop word is not taken while a sound starts', () {
    const held = VoiceSessionOptions(stopWord: true);

    /// The player reports the sound playing now at [position].
    void progress(_Harness h, Duration position) =>
        h.session.onSoundProgress(h.player.lastId, position, null);

    /// Lets the sound playing now go a second and a half in, the hold with
    /// it, from a first report 250 ms in.
    void playThrough(FakeAsync async, _Harness h) {
      progress(h, const Duration(milliseconds: 250));
      async.elapse(const Duration(milliseconds: 1249));
      expect(h.session.stopWordHeld, isTrue);
      async.elapse(const Duration(milliseconds: 1));
      expect(h.session.stopWordHeld, isFalse);
    }

    test('an answer is held for a second and a half of its own playing', () {
      fakeAsync((async) {
        final h = _Harness(options: held);
        expect(h.session.stopWordHeld, isFalse);
        h.session.wake('Okay Nabu');
        async.elapse(const Duration(seconds: 1));
        expect(h.session.stopWordHeld, isFalse);
        h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/tts.mp3'});
        // A streamed answer: at the player, nothing heard yet. The stop
        // word listens from the start and is not taken.
        async.elapse(const Duration(milliseconds: 600));
        progress(h, Duration.zero);
        expect(h.stopArmed, [true]);
        expect(h.session.stopWordHeld, isTrue);
        async.elapse(const Duration(milliseconds: 250));
        playThrough(async, h);
        // Later reports do not hold it again.
        progress(h, const Duration(seconds: 2));
        expect(h.session.stopWordHeld, isFalse);
        h.session.cancel();
        async.flushMicrotasks();
        expect(h.session.stopWordHeld, isFalse);
      });
    });

    test('a player that never reports holds it for three seconds', () {
      fakeAsync((async) {
        final h = _Harness(options: held);
        h.session.wake('Okay Nabu');
        async.elapse(const Duration(seconds: 1));
        h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/tts.mp3'});
        async.elapse(const Duration(milliseconds: 2999));
        expect(h.session.stopWordHeld, isTrue);
        async.elapse(const Duration(milliseconds: 1));
        expect(h.session.stopWordHeld, isFalse);
        h.session.cancel();
        async.flushMicrotasks();
      });
    });

    test('a first report past the hold ends it at once', () {
      fakeAsync((async) {
        final h = _Harness(options: held);
        h.session.wake('Okay Nabu');
        async.elapse(const Duration(seconds: 1));
        h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/tts.mp3'});
        async.flushMicrotasks();
        expect(h.session.stopWordHeld, isTrue);
        progress(h, const Duration(seconds: 2));
        expect(h.session.stopWordHeld, isFalse);
        h.session.cancel();
        async.flushMicrotasks();
      });
    });

    test('nothing is held once the sound is over', () {
      fakeAsync((async) {
        final h = _Harness(options: held);
        h.session.wake('Okay Nabu');
        async.elapse(const Duration(seconds: 1));
        h.session.onEvent(VaEvent.intentEnd, {'continue_conversation': '0'});
        h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/done.mp3'});
        async.flushMicrotasks();
        progress(h, const Duration(milliseconds: 250));
        async.elapse(const Duration(milliseconds: 700));
        expect(h.session.stopWordHeld, isTrue);
        h.session.onSoundEnded(h.player.lastId);
        async.flushMicrotasks();
        expect(h.session.stopWordHeld, isFalse);
      });
    });

    test('every answer of a conversation with follow-ups is held again', () {
      fakeAsync((async) {
        final h = _Harness(options: held);
        h.session.wake('Hey Jarvis');
        async.elapse(const Duration(seconds: 5));
        h.session.onEvent(VaEvent.sttEnd, {'text': 'set a timer'});
        h.session.onEvent(VaEvent.intentEnd, {
          'conversation_id': 'c1',
          'continue_conversation': '1',
        });
        h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/q.mp3'});
        async.flushMicrotasks();
        expect(h.session.stopWordHeld, isTrue);
        playThrough(async, h);
        h.session.onSoundEnded(h.player.lastId);
        async.flushMicrotasks();
        h.session.onEvent(VaEvent.runEnd, {});
        async.flushMicrotasks();
        // The second turn, with no new wake word: nothing plays yet.
        expect(h.mic.opens, 2);
        expect(h.session.stopWordHeld, isFalse);
        async.elapse(const Duration(seconds: 3));
        h.session.onEvent(VaEvent.sttEnd, {'text': 'five minutes'});
        h.session.onEvent(VaEvent.intentEnd, {
          'conversation_id': 'c1',
          'continue_conversation': '0',
        });
        h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/a.mp3'});
        async.flushMicrotasks();
        expect(h.player.played.last, 'http://ha/a.mp3');
        expect(h.session.stopWordHeld, isTrue);
        async.elapse(const Duration(milliseconds: 400));
        playThrough(async, h);
      });
    });

    test('an announcement is held, its chime is not a sound to stop', () {
      fakeAsync((async) {
        final h = _Harness(options: held);
        h.session.announce(
          const VoiceAnnouncement(
            mediaId: 'http://ha/a.mp3',
            text: 'The laundry is done.',
            preannounceMediaId:
                'http://ha/api/assist_satellite/static/preannounce.mp3',
            startConversation: false,
          ),
        );
        async.flushMicrotasks();
        expect(h.player.chimes, ['announce']);
        expect(h.session.stopWordHeld, isFalse);
        h.session.onSoundEnded(h.player.lastId);
        async.flushMicrotasks();
        expect(h.player.played, ['http://ha/a.mp3']);
        expect(h.session.stopWordHeld, isTrue);
        playThrough(async, h);
        h.session.onSoundEnded(h.player.lastId);
        async.flushMicrotasks();
        expect(h.session.stopWordHeld, isFalse);
      });
    });

    test('start_conversation holds it for the question and for the answer', () {
      fakeAsync((async) {
        final h = _Harness(options: held);
        h.session.announce(
          const VoiceAnnouncement(
            mediaId: 'http://ha/q.mp3',
            text: 'Close the garage?',
            preannounceMediaId: '',
            startConversation: true,
          ),
        );
        async.flushMicrotasks();
        expect(h.player.played, ['http://ha/q.mp3']);
        expect(h.session.stopWordHeld, isTrue);
        playThrough(async, h);
        h.session.onSoundEnded(h.player.lastId);
        async.flushMicrotasks();
        expect(h.view.phase, AssistPhase.listening);
        expect(h.session.stopWordHeld, isFalse);
        // The reply and its answer.
        async.elapse(const Duration(seconds: 3));
        h.session.onEvent(VaEvent.sttEnd, {'text': 'yes'});
        h.session.onEvent(VaEvent.intentEnd, {'continue_conversation': '0'});
        h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/ok.mp3'});
        async.flushMicrotasks();
        expect(h.player.played.last, 'http://ha/ok.mp3');
        expect(h.session.stopWordHeld, isTrue);
        playThrough(async, h);
      });
    });

    test('with the stop word off nothing is held', () {
      fakeAsync((async) {
        final h = _Harness();
        h.session.wake('Okay Nabu');
        async.elapse(const Duration(seconds: 1));
        h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/tts.mp3'});
        async.flushMicrotasks();
        expect(h.session.stopWordHeld, isFalse);
        h.session.cancel();
        async.flushMicrotasks();
      });
    });
  });

  test('a lingering result panel keeps the stop word armed', () {
    fakeAsync((async) {
      final h = _Harness(
        options: const VoiceSessionOptions(
          resultsLingerSeconds: 0,
          stopWord: true,
        ),
      );
      h.session.wake('Okay Nabu');
      async.elapse(const Duration(seconds: 1));
      h.session.onEvent(VaEvent.sttEnd, {'text': 'weekly forecast'});
      h.session.onEvent(VaEvent.intentEnd, {'conversation_id': 'c1'});
      h.session.showResults(
        tools: const ['Get weather forecast'],
        results: const [AssistResult('weather', {})],
      );
      h.session.onEvent(VaEvent.runEnd, {});
      async.flushMicrotasks();
      // Held until dismissed, dismissible by voice all the while.
      async.elapse(const Duration(minutes: 5));
      expect(h.view.phase, isNot(AssistPhase.hidden));
      expect(h.stopArmed.last, isTrue);
      // The stop word takes it down with the done chime and lets go.
      h.session.dismiss();
      async.flushMicrotasks();
      expect(h.view.phase, AssistPhase.hidden);
      expect(h.stopArmed.last, isFalse);
      expect(h.player.chimes.last, 'done');
    });
  });

  test('an opened video stops the answer and stays until dismissed', () {
    fakeAsync((async) {
      final h = _Harness(
        options: const VoiceSessionOptions(resultsLingerSeconds: 30),
      );
      h.session.wake('Okay Nabu');
      async.elapse(const Duration(seconds: 1));
      h.session.onEvent(VaEvent.sttEnd, {'text': 'play a video of cats'});
      h.session.showResults(
        results: const [
          AssistResult('videos', {
            'items': [
              {'video_id': 'abc'},
            ],
          }),
        ],
      );
      h.session.onEvent(VaEvent.intentEnd, {'continue_conversation': '1'});
      h.session.onEvent(VaEvent.ttsStart, {'text': 'Here are some cats.'});
      h.session.onEvent(VaEvent.ttsEnd, {'url': 'http://ha/tts.mp3'});
      async.flushMicrotasks();
      final speech = h.player.lastId;
      h.session.holdResults(silence: true);
      async.flushMicrotasks();
      expect(h.player.stopped, contains(speech));
      h.session.onEvent(VaEvent.runEnd, {});
      async.flushMicrotasks();
      // No follow-up: the video is what the person is watching.
      expect(h.session.busy, isFalse);
      expect(h.link.requests.length, 1);
      async.elapse(const Duration(minutes: 5));
      expect(h.view.phase, isNot(AssistPhase.hidden));
      h.session.dismiss();
      expect(h.view.phase, AssistPhase.hidden);
    });
  });

  test('a show streams its answer and stays until dismissed', () {
    fakeAsync((async) {
      final h = _Harness();
      final gen = h.session.beginShow('What is on my calendar?')!;
      async.flushMicrotasks();
      expect(h.view.phase, AssistPhase.thinking);
      expect(h.view.command, 'What is on my calendar?');
      expect(h.player.chimes, ['wake']);
      // Nothing else starts over it.
      expect(h.session.beginShow('again'), isNull);
      h.session.wake('Okay Nabu');
      async.flushMicrotasks();
      expect(h.link.requests, isEmpty);

      h.session.showAnswer(gen, 'You have');
      expect(h.view.answer, 'You have');
      h.session.showAnswer(gen, 'You have two meetings.');
      expect(h.view.phase, AssistPhase.speaking);
      h.session.endShow(gen, seconds: 0);
      async.flushMicrotasks();
      expect(h.session.busy, isFalse);
      async.elapse(const Duration(minutes: 10));
      expect(h.view.answer, 'You have two meetings.');
      h.session.dismiss();
      expect(h.view.phase, AssistPhase.hidden);

      final next = h.session.beginShow('Weather?')!;
      h.session.showAnswer(next, 'Sunny.');
      h.session.endShow(next, seconds: 5);
      async.elapse(const Duration(seconds: 4));
      expect(h.view.phase, isNot(AssistPhase.hidden));
      async.elapse(const Duration(seconds: 2));
      expect(h.view.phase, AssistPhase.hidden);
    });
  });

  group('the Voice Satellite sensor', () {
    test('reads the turn in assist_satellite states', () {
      String of(AssistPhase phase, {bool lingering = false}) => satelliteState(
        AssistView(phase: phase, lingering: lingering),
        busy: true,
      );
      expect(of(AssistPhase.hidden), 'idle');
      expect(of(AssistPhase.listening), 'listening');
      expect(of(AssistPhase.thinking), 'processing');
      expect(of(AssistPhase.speaking), 'responding');
      expect(of(AssistPhase.announcement), 'responding');
      // The answer left on screen after its turn is over.
      expect(of(AssistPhase.speaking, lingering: true), 'idle');
    });

    test('a view with no turn behind it is idle', () {
      // The Appearance page's preview draws a speaking overlay.
      expect(
        satelliteState(
          const AssistView(phase: AssistPhase.speaking),
          busy: false,
        ),
        'idle',
      );
    });
  });

  test(
    "Voice Match's speaker in the log: a name, a short answer or nobody",
    () {
      expect(
        voiceMatchSpeakerLine({'name': 'Ana', 'score': 0.71, 'by': 'voice'}),
        'voice match: Ana (0.71)',
      );
      // A reply to a question with no wake word, too short to say who: taken
      // without a name, which is not an unknown voice.
      expect(
        voiceMatchSpeakerLine({
          'name': null,
          'score': 0.457,
          'by': 'answer',
          'line': 0.32,
        }),
        'voice match: short answer taken (0.457, needed 0.32)',
      );
      expect(
        voiceMatchSpeakerLine({'name': null, 'score': 0.2, 'by': null}),
        'voice match: unknown voice (0.2)',
      );
    },
  );

  group('Voice Match', () {
    void listening(_Harness h, FakeAsync async) {
      h.session.wake('Okay Nabu');
      async.flushMicrotasks();
      h.mic.speak(1, preRoll: true);
      async.elapse(const Duration(milliseconds: 900));
      h.session.onEvent(VaEvent.sttStart, {});
      h.mic.speak(2);
      async.flushMicrotasks();
    }

    test('hears what Home Assistant hears and ends with the turn', () {
      fakeAsync((async) {
        final h = _Harness(match: _Match(), options: _live);
        listening(h, async);
        final turn = h.match!.turns.single;
        // Not the pre-roll and the chime Home Assistant never gets: the
        // chime's echo would read as speech.
        expect(turn.fed, h.link.sent.length);
        expect(turn.fed, 1);
        expect(h.speakers, [null]);
        turn.onEvent({
          'type': 'speaker',
          'name': 'Ana',
          'color': '#56814F',
          'score': 0.8,
        });
        expect(h.speakers.last?['name'], 'Ana');
        // The overlay names her from then on, the command line included.
        expect(h.views.last.speaker, 'Ana');
        expect(h.views.last.speakerColor, '#56814F');
        h.session.onEvent(VaEvent.sttEnd, {'text': 'hi'});
        async.flushMicrotasks();
        expect(h.views.last.command, 'hi');
        expect(h.views.last.speaker, 'Ana');
        h.session.onEvent(VaEvent.runEnd, {});
        async.flushMicrotasks();
        expect(turn.ended, isTrue);
      });
    });

    test('a reply to a question from Home Assistant is one Voice Match can '
        'take a short answer for', () {
      fakeAsync((async) {
        final h = _Harness(match: _Match());
        h.session.announce(
          const VoiceAnnouncement(
            mediaId: 'http://ha/q.mp3',
            text: 'Close the garage?',
            preannounceMediaId: '',
            startConversation: true,
          ),
        );
        async.flushMicrotasks();
        h.session.onSoundEnded(h.player.lastId);
        async.flushMicrotasks();
        final turn = h.match!.turns.single;
        expect(turn.asked, isTrue);
        expect(turn.followup, isFalse);
        expect(turn.seamless, isFalse);
      });
    });

    test('Voice Match is told which kind of question it was once Home '
        'Assistant shows it', () {
      // ask_question and start_conversation arrive the same. A reply whose
      // pipeline ends at speech to text was an ask_question. One that Home
      // Assistant goes on to answer itself was a start_conversation.
      _MatchTurn asked(FakeAsync async, _Harness h) {
        h.session.announce(
          const VoiceAnnouncement(
            mediaId: 'http://ha/q.mp3',
            text: 'Close the garage?',
            preannounceMediaId: '',
            startConversation: true,
          ),
        );
        async.flushMicrotasks();
        h.session.onSoundEnded(h.player.lastId);
        async.flushMicrotasks();
        return h.match!.turns.single;
      }

      // An ask_question's pipeline ends at speech to text, so its start
      // carries no URL for an answer.
      fakeAsync((async) {
        final h = _Harness(match: _Match());
        final turn = asked(async, h);
        expect(turn.kind, isNull);
        h.session.onEvent(VaEvent.runStart, {});
        async.flushMicrotasks();
        expect(turn.kind, 'ask_question');
        h.session.onEvent(VaEvent.sttEnd, {'text': 'yes'});
        h.session.onEvent(VaEvent.runEnd, {});
        async.flushMicrotasks();
        expect(turn.kind, 'ask_question');
      });
      // A start_conversation runs through to an answer: the URL is there
      // from the start.
      fakeAsync((async) {
        final h = _Harness(match: _Match());
        final turn = asked(async, h);
        h.session.onEvent(VaEvent.runStart, {'url': 'http://ha/a.mp3'});
        async.flushMicrotasks();
        expect(turn.kind, 'start_conversation');
      });
      // A pipeline that gives no URL at its start and then answers anyway
      // was a start_conversation after all.
      fakeAsync((async) {
        final h = _Harness(match: _Match());
        final turn = asked(async, h);
        h.session.onEvent(VaEvent.runStart, {});
        h.session.onEvent(VaEvent.sttEnd, {'text': 'yes'});
        h.session.onEvent(VaEvent.intentStart, {});
        async.flushMicrotasks();
        expect(turn.kind, 'start_conversation');
      });
      // A wake word turn says nothing more: it started as one.
      fakeAsync((async) {
        final h = _Harness(match: _Match());
        listening(h, async);
        h.session.onEvent(VaEvent.runStart, {'url': 'http://ha/a.mp3'});
        h.session.onEvent(VaEvent.sttEnd, {'text': 'lights on'});
        h.session.onEvent(VaEvent.intentStart, {});
        h.session.onEvent(VaEvent.runEnd, {});
        async.flushMicrotasks();
        expect(h.match!.turns.single.kind, isNull);
      });
    });

    test('a wake word turn is not a reply to a question', () {
      fakeAsync((async) {
        final h = _Harness(match: _Match());
        listening(h, async);
        expect(h.match!.turns.single.asked, isFalse);
      });
    });

    test('seamless: the pre-roll goes to Voice Match too', () {
      fakeAsync((async) {
        final h = _Harness(
          match: _Match(),
          options: const VoiceSessionOptions(
            seamless: true,
            matchEndOnOtherVoice: false,
          ),
        );
        listening(h, async);
        expect(h.match!.turns.single.fed, h.link.sent.length);
        expect(h.match!.turns.single.fed, 2);
        // Voice Match is told, so the end of the wake word can be left out.
        expect(h.match!.turns.single.seamless, isTrue);
      });
    });

    test(
      'with the wake chime, Voice Match is not told the turn is seamless',
      () {
        fakeAsync((async) {
          final h = _Harness(match: _Match());
          listening(h, async);
          expect(h.match!.turns.single.seamless, isFalse);
        });
      },
    );

    test('the speaker stopping ends the audio and keeps the turn', () {
      fakeAsync((async) {
        final h = _Harness(match: _Match(), options: _live);
        listening(h, async);
        h.match!.turns.single.onEvent({
          'type': 'end_of_speech',
          'reason': 'silence',
        });
        async.flushMicrotasks();
        expect(h.link.audioEnds, 1);
        expect(h.mic.closes, 1);
        expect(h.link.requests.where((r) => !r.$1), isEmpty);
        expect(h.session.busy, isTrue);
      });
    });

    test('with the switch off, another voice does not end the audio', () {
      fakeAsync((async) {
        final off = _Harness(match: _Match(), options: _live);
        listening(off, async);
        expect(off.match!.turns.single.follow, isFalse);
        off.match!.turns.single.onEvent({
          'type': 'end_of_speech',
          'reason': 'other_voice',
        });
        async.flushMicrotasks();
        expect(off.link.audioEnds, 0);
      });
    });

    test(
      'follow mode: Home Assistant hears only what Voice Match sends back',
      () {
        fakeAsync((async) {
          final h = _Harness(match: _Match());
          listening(h, async);
          final turn = h.match!.turns.single;
          expect(turn.follow, isTrue);
          expect(turn.followup, isFalse);
          // The microphone went to Voice Match, not to Home Assistant.
          expect(turn.fed, 1);
          expect(h.link.sent, isEmpty);
          turn.onEvent({'type': 'turn_start', 't': 0.5});
          turn.user(7);
          turn.user(8);
          h.mic.speak(3);
          async.flushMicrotasks();
          expect(h.link.sent.map((p) => p.first), [7, 8]);
          expect(turn.fed, 2);
          turn.onEvent({'type': 'turn_end', 't': 2.0});
          async.flushMicrotasks();
          expect(h.link.audioEnds, 1);
          expect(h.mic.closes, 1);
          expect(h.session.busy, isTrue);
        });
      },
    );

    test(
      'follow mode: Voice Match gone before the user talked, Home Assistant gets the microphone',
      () {
        fakeAsync((async) {
          final h = _Harness(match: _Match());
          listening(h, async);
          final turn = h.match!.turns.single;
          h.mic.speak(4);
          async.flushMicrotasks();
          expect(h.link.sent, isEmpty);
          turn.onLost!();
          async.flushMicrotasks();
          // What it heard so far, then the live microphone.
          expect(h.link.sent.map((p) => p.first), [2, 4]);
          h.mic.speak(5);
          async.flushMicrotasks();
          expect(h.link.sent.map((p) => p.first), [2, 4, 5]);
        });
      },
    );

    test(
      'follow mode: Voice Match not answering in time is as good as gone',
      () {
        fakeAsync((async) {
          final h = _Harness(match: _Match(ready: false));
          listening(h, async);
          expect(h.link.sent, isEmpty);
          async.elapse(VoiceSession.matchReadyWait);
          expect(h.link.sent.map((p) => p.first), [2]);
        });
      },
    );

    test(
      'follow mode: nobody talking cancels the run, and a late event is ignored',
      () {
        fakeAsync((async) {
          final h = _Harness(match: _Match());
          listening(h, async);
          async.elapse(const Duration(seconds: 10));
          async.flushMicrotasks();
          // Home Assistant never had audio: ending it would leave it waiting.
          expect(h.link.audioEnds, 0);
          expect(h.link.requests.last, (false, ''));
          expect(h.session.busy, isFalse);
          h.match!.turns.single.onEvent({'type': 'turn_start', 't': 9.2});
          async.flushMicrotasks();
          expect(h.session.busy, isFalse);
        });
      },
    );

    test(
      'follow mode: keepalives send silence before the user talks, and nobody talking still cancels',
      () {
        fakeAsync((async) {
          final h = _Harness(match: _Match());
          listening(h, async);
          final turn = h.match!.turns.single;
          for (var i = 0; i < 3; i++) {
            turn.onEvent({'type': 'keepalive', 't': 0.5 * (i + 1), 'ms': 20});
          }
          async.flushMicrotasks();
          // 20 ms of silence each, so Home Assistant Cloud keeps the stream.
          expect(h.link.sent.length, 3);
          expect(h.link.sent.every((p) => p.length == 640), isTrue);
          expect(h.link.sent.every((p) => p.every((b) => b == 0)), isTrue);
          async.elapse(const Duration(seconds: 10));
          async.flushMicrotasks();
          // The silence isn't the user's speech: the run is still cancelled.
          expect(h.link.audioEnds, 0);
          expect(h.session.busy, isFalse);
        });
      },
    );

    test(
      'follow mode: Voice Match gone after keepalives, Home Assistant still gets the microphone',
      () {
        fakeAsync((async) {
          final h = _Harness(match: _Match());
          listening(h, async);
          final turn = h.match!.turns.single;
          turn.onEvent({'type': 'keepalive', 't': 0.5, 'ms': 20});
          h.mic.speak(4);
          async.flushMicrotasks();
          turn.onLost!();
          async.flushMicrotasks();
          // The silence, then what the microphone heard from the start.
          expect(h.link.sent.skip(1).map((p) => p.first), [2, 4]);
        });
      },
    );

    test(
      'a voice that is not enrolled ends the turn, quietly or with a chime',
      () {
        fakeAsync((async) {
          final quiet = _Harness(match: _Match());
          listening(quiet, async);
          quiet.match!.turns.single.onEvent({'type': 'rejected', 'score': 0.2});
          async.flushMicrotasks();
          expect(quiet.link.requests.last, (false, ''));
          expect(quiet.session.busy, isFalse);
          expect(quiet.player.chimes, ['wake']);
          expect(quiet.match!.turns.single.ended, isTrue);

          final loud = _Harness(
            match: _Match(),
            options: const VoiceSessionOptions(matchRejectChime: true),
          );
          listening(loud, async);
          loud.match!.turns.single.onEvent({'type': 'rejected', 'score': 0.2});
          async.flushMicrotasks();
          expect(loud.player.chimes, ['wake', 'error']);
        });
      },
    );

    test('events from a turn that is over are ignored', () {
      fakeAsync((async) {
        final h = _Harness(match: _Match());
        listening(h, async);
        final first = h.match!.turns.single;
        h.session.onEvent(VaEvent.sttEnd, {'text': 'hi'});
        h.session.onEvent(VaEvent.runEnd, {});
        async.flushMicrotasks();
        first.onEvent({'type': 'turn_end', 't': 1.0});
        async.flushMicrotasks();
        expect(h.link.audioEnds, 0);
      });
    });
  });
}
