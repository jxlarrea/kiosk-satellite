import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/voice/ha_socket.dart';
import 'package:kiosk_satellite/managers/voice/remote_speaker.dart';

/// Home Assistant with one media player: entity subscriptions get its
/// state as the compressed messages, service calls are recorded.
class _Ha extends HaSocket {
  _Ha(this.initial) : super(baseUrl: () => '', token: () => '');

  final Map<String, Object?> initial;
  final calls = <Map<String, Object?>>[];
  final _listeners = <void Function(Map<String, Object?> event)>[];
  bool failPlay = false;

  /// Holds play_media's answer until completed, as Music Assistant answers
  /// an announcement only once it has played.
  Completer<void>? holdPlay;

  /// What network/url answers, or null to fail it.
  Map<String, Object?>? urls = {
    'internal': 'http://192.168.1.5:8123/',
    'external': 'https://ha.example.com',
  };

  static const entity = 'media_player.kitchen';

  @override
  Future<Object?> request(
    Map<String, Object?> command, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    calls.add(command);
    if (command['service'] == 'play_media') await holdPlay?.future;
    if (failPlay && command['service'] == 'play_media') {
      throw StateError('unavailable');
    }
    if (command['type'] == 'network/url') {
      return urls ?? (throw StateError('unknown command'));
    }
    return null;
  }

  @override
  Future<Future<void> Function()> subscribe(
    Map<String, Object?> command,
    void Function(Map<String, Object?> event) onEvent, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _listeners.add(onEvent);
    onEvent({
      'a': {entity: initial},
    });
    return () async => _listeners.remove(onEvent);
  }

  /// The player's state changes.
  void change(String state, [Map<String, Object?> attributes = const {}]) {
    for (final listener in [..._listeners]) {
      listener({
        'c': {
          entity: {
            '+': {'s': state, 'a': attributes},
          },
        },
      });
    }
  }

  bool get askedUrl => calls.any((c) => c['type'] == 'network/url');

  List<String> get services => [
    for (final c in calls)
      if (c['type'] == 'call_service') '${c['service']}',
  ];

  Map<Object?, Object?> data(String service, {bool last = false}) {
    final matching = calls.where((c) => c['service'] == service);
    return (last ? matching.last : matching.first)['service_data']! as Map;
  }
}

const _music = {
  's': 'playing',
  'a': {
    'media_content_id': 'http://radio/stream',
    'media_content_type': 'music',
    'media_position': 42,
    'media_duration': 300,
  },
};

void main() {
  const url = 'https://ha.local:8123/api/tts_proxy/abc123.mp3';
  const ours = {'media_content_id': 'http://ha:8123/api/tts_proxy/abc123.mp3'};
  const chime = 'http://192.168.1.5:40000/token/done.mp3';

  RemoteSpeaker speakerFor(
    _Ha ha,
    List<String> ended, {
    Future<double?> Function(String, Duration)? measure,
    List<Duration>? progress,
    FakeAsync? time,
  }) => RemoteSpeaker(
    ha: ha,
    onEnded: (id, {error}) => ended.add(id),
    onProgress: (id, position, length) => progress?.add(length),
    measure: measure,
    log: (_) {},
    now: time == null ? null : () => DateTime(2026).add(time.elapsed),
  );

  test('a Cast player: our speech buffers, plays and stops', () {
    fakeAsync((async) {
      final ha = _Ha({'s': 'idle', 'a': <String, Object?>{}});
      final ended = <String>[];
      final speaker = speakerFor(ha, ended);
      String? id;
      speaker.play(_Ha.entity, url, normal: false).then((v) => id = v);
      async.flushMicrotasks();
      // Relative, for Home Assistant to resolve and sign for the speaker.
      expect(
        ha.data('play_media')['media_content_id'],
        '/api/tts_proxy/abc123.mp3',
      );
      expect(ha.data('play_media')['announce'], isTrue);
      expect(ha.askedUrl, isFalse);
      ha.change('buffering', ours);
      ha.change('playing', ours);
      expect(ended, isEmpty);
      ha.change('idle');
      expect(ended, [id]);
      // Once only.
      ha.change('playing', ours);
      ha.change('idle');
      expect(ended, [id]);
    });
  });

  group('a Music Assistant player', () {
    const idle = {
      's': 'idle',
      'a': {'mass_player_type': 'player'},
    };

    test('gets the full URL on Home Assistant\'s own address', () {
      fakeAsync((async) {
        final ha = _Ha(idle);
        final ended = <String>[];
        final speaker = speakerFor(ha, ended);
        String? id;
        speaker.play(_Ha.entity, url, normal: false).then((v) => id = v);
        async.flushMicrotasks();
        expect(
          ha.data('play_media')['media_content_id'],
          'http://192.168.1.5:8123/api/tts_proxy/abc123.mp3',
        );
        expect(ha.data('play_media')['announce'], isTrue);
        // Followed as any other player.
        ha.change('playing', {
          'media_content_id':
              'builtin://radio/http://192.168.1.5:8123/api/tts_proxy/abc123.mp3',
        });
        ha.change('idle');
        expect(ended, [id]);
      });
    });

    test('an announcement answered only once played still ends the turn', () {
      fakeAsync((async) {
        final ha = _Ha(idle)..holdPlay = Completer<void>();
        final ended = <String>[];
        final speaker = speakerFor(ha, ended);
        String? id;
        speaker.play(_Ha.entity, url, normal: false).then((v) => id = v);
        async.flushMicrotasks();
        // The id comes back before the end it is followed by.
        expect(id, isNotNull);
        ha.change('playing', {'media_content_id': 'announcement'});
        ha.change('idle');
        expect(ended, [id]);
        ha.holdPlay!.complete();
        async.flushMicrotasks();
        expect(ended, [id]);
      });
    });

    test('keeps a signed query, and falls back to the external URL', () {
      fakeAsync((async) {
        final ha = _Ha(idle)
          ..urls = {'internal': null, 'external': 'https://ha.example.com'};
        final speaker = speakerFor(ha, []);
        speaker.play(
          _Ha.entity,
          'https://ha.local:8123/api/media/x.mp3?authSig=abc',
          normal: true,
        );
        async.flushMicrotasks();
        expect(
          ha.data('play_media')['media_content_id'],
          'https://ha.example.com/api/media/x.mp3?authSig=abc',
        );
        expect(ha.data('play_media')['announce'], isFalse);
      });
    });

    test('gets the URL as it came when Home Assistant has no address', () {
      fakeAsync((async) {
        final ha = _Ha(idle)..urls = null;
        final speaker = speakerFor(ha, []);
        speaker.play(_Ha.entity, url, normal: false);
        async.flushMicrotasks();
        expect(ha.data('play_media')['media_content_id'], url);
      });
    });

    test('the timer phrase gets the full URL too', () {
      fakeAsync((async) {
        final ha = _Ha(idle);
        final speaker = speakerFor(ha, [], measure: (url, timeout) async => 2);
        speaker.play(_Ha.entity, url, normal: false, kind: RemoteSound.timed);
        async.flushMicrotasks();
        expect(
          ha.data('play_media')['media_content_id'],
          'http://192.168.1.5:8123/api/tts_proxy/abc123.mp3',
        );
      });
    });

    test('chimes and media-source ids pass as they are', () {
      fakeAsync((async) {
        final ha = _Ha(idle);
        final speaker = speakerFor(ha, []);
        speaker.chime(_Ha.entity, chime, 0.3, normal: false);
        async.flushMicrotasks();
        speaker.play(
          _Ha.entity,
          'media-source://tts/tts.piper?message=hi',
          normal: false,
        );
        async.flushMicrotasks();
        expect(ha.data('play_media')['media_content_id'], chime);
        expect(
          ha.data('play_media', last: true)['media_content_id'],
          'media-source://tts/tts.piper?message=hi',
        );
        expect(ha.askedUrl, isFalse);
      });
    });
  });

  group('a Music Assistant announcement', () {
    // Idle on the last track it played, as a Music Assistant player sits
    // after its queue ends.
    const lastTrack = {
      's': 'idle',
      'a': {
        'mass_player_type': 'player',
        'media_content_id': 'spotify://track/6xiX',
      },
    };
    const onLastTrack = {'media_content_id': 'spotify://track/6xiX'};

    test('is not ended by the last track\'s id while it plays', () {
      fakeAsync((async) {
        final ha = _Ha(lastTrack)..holdPlay = Completer<void>();
        final ended = <String>[];
        final speaker = speakerFor(ha, ended, time: async);
        speaker.play(_Ha.entity, url, normal: false);
        async.flushMicrotasks();
        ha.change('playing', onLastTrack);
        // An update in the middle of the announcement.
        ha.change('playing', onLastTrack);
        expect(ended, isEmpty);
        ha.change('idle', onLastTrack);
        expect(ended, hasLength(1));
      });
    });

    test('ends when Music Assistant answers, after its own chime', () {
      fakeAsync((async) {
        final ha = _Ha(lastTrack)..holdPlay = Completer<void>();
        final ended = <String>[];
        final speaker = speakerFor(
          ha,
          ended,
          measure: (url, timeout) async => 4.0,
          time: async,
        );
        speaker.play(_Ha.entity, url, normal: false);
        async.flushMicrotasks();
        // Its length and the 2 s margin go by: Music Assistant still plays.
        async.elapse(const Duration(seconds: 8));
        expect(ended, isEmpty);
        ha.holdPlay!.complete();
        async.flushMicrotasks();
        expect(ended, hasLength(1));
      });
    });

    test('an announcement on Music Assistant ends when it answers too', () {
      fakeAsync((async) {
        final ha = _Ha(lastTrack)..holdPlay = Completer<void>();
        final ended = <String>[];
        final speaker = speakerFor(
          ha,
          ended,
          measure: (url, timeout) async => 3.0,
          time: async,
        );
        speaker.play(
          _Ha.entity,
          url,
          normal: false,
          kind: RemoteSound.notification,
        );
        async.flushMicrotasks();
        ha.change('playing', onLastTrack);
        ha.change('playing', onLastTrack);
        async.elapse(const Duration(seconds: 7));
        expect(ended, isEmpty);
        ha.holdPlay!.complete();
        async.flushMicrotasks();
        expect(ended, hasLength(1));
      });
    });

    test('a measured answer ends when the player goes idle after its '
        'length', () {
      fakeAsync((async) {
        final ha = _Ha(lastTrack)..holdPlay = Completer<void>();
        final ended = <String>[];
        final speaker = speakerFor(
          ha,
          ended,
          measure: (url, timeout) async => 4.0,
          time: async,
        );
        speaker.play(_Ha.entity, url, normal: false);
        async.flushMicrotasks();
        ha.change('playing', onLastTrack);
        // Idle before the length went by: a blip, not the end.
        async.elapse(const Duration(seconds: 2));
        ha.change('idle', onLastTrack);
        expect(ended, isEmpty);
        ha.change('playing', onLastTrack);
        async.elapse(const Duration(seconds: 5));
        ha.change('idle', onLastTrack);
        expect(ended, hasLength(1));
      });
    });

    test('an answer before the length has gone by is not the end', () {
      fakeAsync((async) {
        final ha = _Ha(lastTrack)..holdPlay = Completer<void>();
        final ended = <String>[];
        final speaker = speakerFor(
          ha,
          ended,
          measure: (url, timeout) async => 4.0,
          time: async,
        );
        speaker.play(_Ha.entity, url, normal: false);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        ha.holdPlay!.complete();
        async.flushMicrotasks();
        expect(ended, isEmpty);
        // Back to the length and the 2 s margin.
        async.elapse(const Duration(milliseconds: 4900));
        expect(ended, isEmpty);
        async.elapse(const Duration(milliseconds: 100));
        expect(ended, hasLength(1));
      });
    });

    test('is let go 12 s after its length when Music Assistant never '
        'answers', () {
      fakeAsync((async) {
        final ha = _Ha(lastTrack)..holdPlay = Completer<void>();
        final ended = <String>[];
        final speaker = speakerFor(
          ha,
          ended,
          measure: (url, timeout) async => 4.0,
          time: async,
        );
        speaker.play(_Ha.entity, url, normal: false);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 15900));
        expect(ended, isEmpty);
        async.elapse(const Duration(milliseconds: 100));
        expect(ended, hasLength(1));
      });
    });

    test('normal playback still ends by its length', () {
      fakeAsync((async) {
        final ha = _Ha(lastTrack);
        final ended = <String>[];
        final speaker = speakerFor(
          ha,
          ended,
          measure: (url, timeout) async => 4.0,
          time: async,
        );
        speaker.play(_Ha.entity, url, normal: true);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 5900));
        expect(ended, isEmpty);
        async.elapse(const Duration(milliseconds: 100));
        expect(ended, hasLength(1));
      });
    });
  });

  test('announcing over music ends when the music comes back', () {
    fakeAsync((async) {
      final ha = _Ha({
        's': 'playing',
        'a': {'media_content_id': 'spotify:track:1'},
      });
      final ended = <String>[];
      final speaker = speakerFor(ha, ended);
      speaker.play(_Ha.entity, url, normal: false);
      async.flushMicrotasks();
      // Still the music: not our speech yet.
      ha.change('playing', {'media_content_id': 'spotify:track:1'});
      expect(ended, isEmpty);
      ha.change('playing', {'media_content_id': 'announcement'});
      expect(ended, isEmpty);
      ha.change('playing', {'media_content_id': 'spotify:track:1'});
      expect(ended, hasLength(1));
    });
  });

  test('normal playback: snapshot at the wake chime, music back after '
      'the done chime', () {
    fakeAsync((async) {
      final ha = _Ha(_music);
      final ended = <String>[];
      final speaker = speakerFor(ha, ended);
      speaker.chime(_Ha.entity, chime, 0.3, normal: true);
      async.flushMicrotasks();
      expect(ha.data('play_media')['announce'], isFalse);
      speaker.play(_Ha.entity, url, normal: true);
      async.flushMicrotasks();
      ha.change('playing', ours);
      ha.change('idle');
      // The answer, the wake chime's length not yet gone by.
      expect(ended, hasLength(1));
      // The answer's restore waits for a chime that may follow.
      async.elapse(const Duration(milliseconds: 1000));
      speaker.chime(_Ha.entity, chime, 0.3, normal: true, end: true);
      async.flushMicrotasks();
      // Rescheduled after the done chime: 0.3 s plus half a second.
      async.elapse(const Duration(milliseconds: 700));
      expect(ha.services, ['play_media', 'play_media', 'play_media']);
      async.elapse(const Duration(milliseconds: 200));
      expect(ha.services, hasLength(4));
      final restore = ha.data('play_media', last: true);
      // The music as it was before the wake chime, not the chime.
      expect(restore['media_content_id'], 'http://radio/stream');
      expect((restore['extra']! as Map)['current_time'], 42);
      async.elapse(const Duration(milliseconds: 1500));
      expect(ha.services.last, 'media_seek');
      expect(ha.data('media_seek')['seek_position'], 42);
    });
  });

  test('a restore pending when more sound comes is put off', () {
    fakeAsync((async) {
      final ha = _Ha(_music);
      final speaker = speakerFor(ha, []);
      speaker.chime(_Ha.entity, chime, 0.3, normal: true, end: true);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 500));
      // A follow-up's chime before the restore fired.
      speaker.chime(_Ha.entity, chime, 0.3, normal: true);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 5));
      expect(ha.services, ['play_media', 'play_media']);
      speaker.settle();
      async.elapse(const Duration(milliseconds: 1500));
      expect(ha.services, ['play_media', 'play_media', 'play_media']);
    });
  });

  test('media at its end is not restored', () {
    fakeAsync((async) {
      final ha = _Ha({
        's': 'playing',
        'a': {
          'media_content_id': 'http://radio/song.mp3',
          'media_position': 299,
          'media_duration': 300,
        },
      });
      final speaker = speakerFor(ha, []);
      speaker.chime(_Ha.entity, chime, 0.3, normal: true, end: true);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 5));
      expect(ha.services, ['play_media']);
    });
  });

  test('our own speech is never taken for the music', () {
    fakeAsync((async) {
      final ha = _Ha({'s': 'playing', 'a': ours});
      final speaker = speakerFor(ha, []);
      speaker.chime(_Ha.entity, chime, 0.3, normal: true);
      async.flushMicrotasks();
      speaker.settle();
      async.elapse(const Duration(seconds: 5));
      expect(ha.services, ['play_media']);
    });
  });

  test('stopping: announcement mode stops the player, normal playback '
      'puts the music back', () {
    fakeAsync((async) {
      final ha = _Ha({'s': 'idle', 'a': <String, Object?>{}});
      final ended = <String>[];
      final speaker = speakerFor(ha, ended);
      String? id;
      speaker.play(_Ha.entity, url, normal: false).then((v) => id = v);
      async.flushMicrotasks();
      speaker.stop(id!);
      async.flushMicrotasks();
      expect(ended, [id]);
      expect(ha.services, ['play_media', 'media_stop']);

      final music = _Ha(_music);
      final normal = speakerFor(music, []);
      normal.play(_Ha.entity, url, normal: true).then((v) => id = v);
      async.flushMicrotasks();
      normal.stop(id!);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 1500));
      expect(music.services, ['play_media', 'play_media']);
      expect(
        music.data('play_media', last: true)['media_content_id'],
        'http://radio/stream',
      );
    });
  });

  test('a refused call ends the sound as played', () {
    fakeAsync((async) {
      final ha = _Ha({'s': 'idle', 'a': <String, Object?>{}})..failPlay = true;
      final errors = <String?>[];
      final speaker = RemoteSpeaker(
        ha: ha,
        onEnded: (id, {error}) => errors.add(error),
        log: (_) {},
      );
      String? id;
      speaker.play(_Ha.entity, url, normal: false).then((v) => id = v);
      async.flushMicrotasks();
      expect(id, isNotNull);
      expect(errors, [null]);
    });
  });

  test('a player that reports nothing is let go after 30 seconds, or '
      'after a long answer', () {
    fakeAsync((async) {
      final ha = _Ha({'s': 'idle', 'a': <String, Object?>{}});
      final ended = <String>[];
      final speaker = speakerFor(ha, ended);
      speaker.play(_Ha.entity, url, normal: false, text: 'Sure.');
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 29));
      expect(ended, isEmpty);
      async.elapse(const Duration(seconds: 1));
      expect(ended, hasLength(1));

      speaker.play(
        _Ha.entity,
        url,
        normal: false,
        text: List.filled(100, 'word').join(' '),
      );
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 31));
      expect(ended, hasLength(1));
      async.elapse(const Duration(seconds: 30));
      expect(ended, hasLength(2));
    });
  });

  test('a measured answer ends by its length, or when the player shows '
      'it and stops', () {
    fakeAsync((async) {
      final ha = _Ha({
        's': 'playing',
        'a': {'media_content_id': 'spotify:track:1'},
      });
      final ended = <String>[];
      final progress = <Duration>[];
      final speaker = speakerFor(
        ha,
        ended,
        measure: (url, timeout) async => 4.0,
        progress: progress,
      );
      speaker.play(_Ha.entity, url, normal: false);
      async.flushMicrotasks();
      expect(progress, [const Duration(seconds: 4)]);
      // Announce mode blips back to the music early: the length decides.
      ha.change('playing', {'media_content_id': 'announcement'});
      ha.change('playing', {'media_content_id': 'spotify:track:1'});
      expect(ended, isEmpty);
      async.elapse(const Duration(seconds: 6));
      expect(ended, hasLength(1));

      speaker.play(_Ha.entity, url, normal: false);
      async.flushMicrotasks();
      ha.change('playing', ours);
      ha.change('idle');
      expect(ended, hasLength(2));
    });
  });

  group('a length measured late', () {
    // A Sonos announcing over paused music stays paused on the music the
    // whole time: the length is its only end.
    const paused = {
      's': 'paused',
      'a': {'media_content_id': 'x-sonos-spotify:track:1'},
    };

    test('ends the answer its length after it was sent, not after the '
        'measurement', () {
      fakeAsync((async) {
        final ha = _Ha(paused);
        final ended = <String>[];
        final measured = Completer<double?>();
        final progress = <Duration>[];
        final positions = <Duration>[];
        final speaker = RemoteSpeaker(
          ha: ha,
          onEnded: (id, {error}) => ended.add(id),
          onProgress: (id, position, length) {
            positions.add(position);
            progress.add(length);
          },
          measure: (url, timeout) => measured.future,
          log: (_) {},
          now: () => DateTime(2026).add(async.elapsed),
        );
        speaker.play(_Ha.entity, url, normal: false);
        async.flushMicrotasks();
        // A long streamed answer, measured 5.2 s in.
        async.elapse(const Duration(milliseconds: 5200));
        measured.complete(15.7);
        async.flushMicrotasks();
        expect(positions, [const Duration(milliseconds: 5200)]);
        expect(progress, [const Duration(milliseconds: 15700)]);
        // Its 15.7 s plus the 2 s pad: 17.7 s after it was sent.
        async.elapse(const Duration(milliseconds: 12400));
        expect(ended, isEmpty);
        async.elapse(const Duration(milliseconds: 100));
        expect(ended, hasLength(1));
      });
    });

    test('ends at once when the answer is already over', () {
      fakeAsync((async) {
        final ha = _Ha(paused);
        final ended = <String>[];
        final measured = Completer<double?>();
        final speaker = speakerFor(
          ha,
          ended,
          measure: (url, timeout) => measured.future,
          time: async,
        );
        speaker.play(_Ha.entity, url, normal: false, text: 'Sure.');
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 5));
        measured.complete(2.0);
        async.flushMicrotasks();
        async.elapse(Duration.zero);
        expect(ended, hasLength(1));
      });
    });

    test('ends an announcement its length after it was sent', () {
      fakeAsync((async) {
        final ha = _Ha(paused);
        final ended = <String>[];
        final measured = Completer<double?>();
        final speaker = speakerFor(
          ha,
          ended,
          measure: (url, timeout) => measured.future,
          time: async,
        );
        speaker.play(
          _Ha.entity,
          url,
          normal: false,
          kind: RemoteSound.notification,
        );
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        measured.complete(3.0);
        async.flushMicrotasks();
        // 3 s plus the 2 s pad, from when it was sent.
        async.elapse(const Duration(milliseconds: 3900));
        expect(ended, isEmpty);
        async.elapse(const Duration(milliseconds: 100));
        expect(ended, hasLength(1));
      });
    });

    test('a player that shows our sound and stops still ends it early', () {
      fakeAsync((async) {
        final ha = _Ha({'s': 'idle', 'a': <String, Object?>{}});
        final ended = <String>[];
        final measured = Completer<double?>();
        final speaker = speakerFor(
          ha,
          ended,
          measure: (url, timeout) => measured.future,
          time: async,
        );
        speaker.play(_Ha.entity, url, normal: false);
        async.flushMicrotasks();
        ha.change('playing', ours);
        async.elapse(const Duration(seconds: 1));
        measured.complete(4.0);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        ha.change('idle');
        expect(ended, hasLength(1));
        async.elapse(const Duration(seconds: 10));
        expect(ended, hasLength(1));
      });
    });
  });

  test('the timer phrase plays for its length, and stops the player', () {
    fakeAsync((async) {
      final ha = _Ha({'s': 'idle', 'a': <String, Object?>{}});
      final ended = <String>[];
      final speaker = speakerFor(ha, ended, measure: (url, timeout) async => 2);
      speaker.play(_Ha.entity, url, normal: false, kind: RemoteSound.timed);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 2700));
      expect(ended, isEmpty);
      async.elapse(const Duration(milliseconds: 100));
      expect(ended, hasLength(1));

      String? id;
      speaker.chime(_Ha.entity, chime, 0.6, normal: false).then((v) => id = v);
      async.flushMicrotasks();
      speaker.stop(id!);
      async.flushMicrotasks();
      expect(ended, hasLength(2));
      expect(ha.services.last, 'media_stop');
    });
  });
}
