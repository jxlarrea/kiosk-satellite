import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/voice/voice_match_enroll.dart';
import 'package:kiosk_satellite/managers/voice/voice_session.dart';

class _Mic implements VoiceMicPort {
  _Mic({this.works = true});
  final bool works;
  void Function(Uint8List pcm, bool preRoll)? sink;
  int opens = 0;
  int closes = 0;

  @override
  Future<bool> open(void Function(Uint8List pcm, bool preRoll) onChunk) async {
    opens++;
    if (!works) return false;
    sink = onChunk;
    return true;
  }

  @override
  Future<void> close() async {
    closes++;
    sink = null;
  }

  void speak({bool preRoll = false}) => sink?.call(Uint8List(3200), preRoll);
}

class _Socket implements EnrollSocketPort {
  _Socket(this.onEvent);
  final void Function(Map<String, Object?> event) onEvent;
  int fed = 0;
  bool ended = false;
  bool closed = false;

  @override
  void feed(Uint8List pcm) => fed++;

  @override
  void end() => ended = true;

  @override
  void close() => closed = true;
}

class _Harness {
  _Harness({bool micWorks = true}) : mic = _Mic(works: micWorks) {
    enroller = VoiceMatchEnroller(
      mic: mic,
      openSocket: (request, onEvent) {
        final s = _Socket(onEvent);
        sockets.add(s);
        return s;
      },
      chime: (kind) async => chimes.add(kind),
      onChanged: states.add,
      pauseWake: () => wake.add(false),
      resumeWake: () => wake.add(true),
    );
  }

  final _Mic mic;
  late final VoiceMatchEnroller enroller;
  final sockets = <_Socket>[];
  final chimes = <String>[];
  final states = <VoiceMatchEnrollment?>[];
  final wake = <bool>[];

  _Socket get socket => sockets.single;
  VoiceMatchEnrollment? get last => states.last;
}

const _ana = EnrollRequest(
  personId: 'p1',
  name: 'Ana',
  color: '#56814F',
  targetS: 20,
);

void main() {
  test('records with the wake word paused and saves', () {
    fakeAsync((async) {
      final h = _Harness();
      h.enroller.start(_ana);
      async.flushMicrotasks();
      expect(h.wake, [false]);
      expect(h.chimes, ['wake']);
      expect(h.mic.opens, 1);
      expect(h.last?.phase, EnrollPhase.starting);

      // Pre-roll is from before the request: not the person reading.
      h.mic.speak(preRoll: true);
      h.mic.speak();
      expect(h.socket.fed, 1);

      h.socket.onEvent({'type': 'ready'});
      expect(h.last?.phase, EnrollPhase.recording);
      h.socket.onEvent({'type': 'progress', 'speech_s': 8.5, 'level': -24.0});
      expect(h.last?.speechS, 8.5);
      expect(h.last?.progress, closeTo(0.425, 1e-9));
      // An older Ground Control doesn't pace the passage.
      expect(h.last?.sentence, isNull);
      h.socket.onEvent({
        'type': 'progress',
        'speech_s': 9.0,
        'sentence': 3,
        'sentence_fill': 0.4,
      });
      expect(h.last?.sentence, 3);
      expect(h.last?.sentenceFill, 0.4);
      h.socket.onEvent({'type': 'other_voice', 'score': 0.1});
      expect(h.last?.otherVoices, 1);
      expect(h.last?.otherVoiceAt, isNotNull);

      h.socket.onEvent({'type': 'done', 'speech_s': 20.1});
      async.flushMicrotasks();
      expect(h.last?.phase, EnrollPhase.saving);
      expect(h.mic.closes, 1);
      h.socket.onEvent({
        'type': 'saved',
        'added_s': 20.1,
        'speech_s': 40.0,
        'dropped_s': 2.0,
      });
      async.flushMicrotasks();
      expect(h.last?.phase, EnrollPhase.saved);
      expect(h.last?.addedS, 20.1);
      expect(h.chimes, ['wake', 'done']);
      expect(h.wake, [false, true]);
      expect(h.enroller.active, isFalse);

      // The result card goes on its own.
      async.elapse(VoiceMatchEnroller.resultFor);
      expect(h.last, isNull);
    });
  });

  test('a busy kiosk refuses and keeps listening for the wake word', () {
    fakeAsync((async) {
      final h = _Harness();
      h.enroller.start(_ana, refuse: 'busy');
      async.flushMicrotasks();
      expect(h.last?.phase, EnrollPhase.refused);
      expect(h.last?.code, 'busy');
      expect(h.wake, isEmpty);
      expect(h.mic.opens, 0);
      expect(h.sockets, isEmpty);
      expect(h.enroller.state, isNull);
    });
  });

  test('a second request while recording is refused', () {
    fakeAsync((async) {
      final h = _Harness();
      h.enroller.start(_ana);
      async.flushMicrotasks();
      h.enroller.start(const EnrollRequest(personId: 'p2', name: 'Leo'));
      async.flushMicrotasks();
      expect(h.last?.phase, EnrollPhase.refused);
      expect(h.last?.personId, 'p2');
      expect(h.enroller.state?.personId, 'p1');
      expect(h.enroller.active, isTrue);
    });
  });

  test('Stop asks the service to save what there is', () {
    fakeAsync((async) {
      final h = _Harness();
      h.enroller.start(_ana);
      async.flushMicrotasks();
      h.socket.onEvent({'type': 'progress', 'speech_s': 12.0, 'level': -30.0});
      h.enroller.stop();
      async.flushMicrotasks();
      expect(h.socket.ended, isTrue);
      expect(h.mic.closes, 1);
      expect(h.last?.phase, EnrollPhase.saving);
      h.socket.onEvent({
        'type': 'error',
        'code': 'too_short',
        'message': 'only 9 s',
      });
      async.flushMicrotasks();
      expect(h.last?.phase, EnrollPhase.failed);
      expect(h.last?.code, 'too_short');
      expect(h.chimes.last, 'error');
      expect(h.wake.last, isTrue);
    });
  });

  test('no microphone fails and gives the wake word back', () {
    fakeAsync((async) {
      final h = _Harness(micWorks: false);
      h.enroller.start(_ana);
      async.flushMicrotasks();
      expect(h.last?.phase, EnrollPhase.failed);
      expect(h.last?.code, 'no_mic');
      expect(h.socket.closed, isTrue);
      expect(h.wake, [false, true]);
    });
  });

  test('a lost connection before saving fails', () {
    fakeAsync((async) {
      final h = _Harness();
      h.enroller.start(_ana);
      async.flushMicrotasks();
      h.socket.onEvent({'type': 'ready'});
      h.socket.onEvent({'type': 'closed'});
      async.flushMicrotasks();
      expect(h.last?.phase, EnrollPhase.failed);
      expect(h.last?.code, 'lost');
      expect(h.mic.closes, 1);
    });
  });

  test('the passage is spread over the target and starts over', () {
    final passage = ['One two three.', 'Four five six seven eight.', 'Nine.'];
    expect(sentenceAt(passage, 0, 30), 0);
    expect(sentenceAt(passage, 29.9, 30), 2);
    expect(sentenceAt(passage, 30.1, 30), 0);
    // Chinese reads slower per character than letters.
    expect(readingSeconds('打开厨房的灯。'), greaterThan(readingSeconds('Lights.')));
  });

  test('the start message carries the passage the kiosk shows', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final first = Completer<Map<String, Object?>>();
    server.listen((req) async {
      final ws = await WebSocketTransformer.upgrade(req);
      ws.listen((m) {
        if (!first.isCompleted) {
          first.complete(jsonDecode(m as String) as Map<String, Object?>);
        }
      });
    });
    final socket = EnrollSocket.open(
      baseUrl: 'http://127.0.0.1:${server.port}',
      token: 't',
      request: const EnrollRequest(personId: 'ana', name: 'Ana'),
      deviceId: 'k1',
      deviceName: 'Kitchen',
      model: '',
      passage: const ['Uno.', 'Dos.'],
      onEvent: (_) {},
    );
    final start = await first.future.timeout(const Duration(seconds: 5));
    expect(start['type'], 'start');
    expect(start['person_id'], 'ana');
    expect(start['passage'], ['Uno.', 'Dos.']);
    socket.close();
    await server.close(force: true);
  });
}
