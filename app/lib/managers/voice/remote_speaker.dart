/// Plays Voice Satellite's sounds on a Home Assistant media player, its TTS
/// output, for the native satellite: the answers (tts/index.js), the chimes
/// (audio/chime.js), announcements (shared/satellite-notification.js) and
/// the timer alert (timer/ui.js). The kiosk plays nothing itself: it asks
/// the player, and follows the player's state or the sound's length to know
/// when a sound is over.
///
/// In normal playback mode (speakers that ignore the announce flag) the
/// first sound of an interaction takes a snapshot of what the player was
/// playing, and the last one puts it back. Every sound cancels a pending
/// restore and the end of the interaction schedules it again, so the music
/// comes back once, after the last chime.
library;

import 'dart:async';

import 'assist_view.dart' show estimateSpeechSeconds;
import 'ha_socket.dart';

/// How a remote sound's end is known.
enum RemoteSound {
  /// The assistant's answer: the player's state, and the sound's measured
  /// length once known (TtsManager.checkRemotePlayback).
  speech,

  /// An announcement or its preannounce sound: the player's state, the
  /// measured length as a deadline (checkRemoteNotificationPlayback).
  notification,

  /// A chime or the timer phrase: over after its length.
  timed,
}

class RemoteSpeaker {
  RemoteSpeaker({
    required this.ha,
    required this.onEnded,
    required this.log,
    this.onProgress,
    this.measure,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final HaSocket ha;

  /// A sound this speaker played is over, under the id it was given.
  final void Function(String id, {String? error}) onEnded;
  final void Function(String line) log;

  /// Where a sound is, once its length is known: the scroll paces by it.
  final void Function(String id, Duration position, Duration length)?
  onProgress;

  /// How long the audio at a URL plays, in seconds, or null. Home Assistant
  /// measured it for the dashboard integration (tts-audio-duration).
  final Future<double?> Function(String url, Duration timeout)? measure;

  /// The time, for tests to run on fake time.
  final DateTime Function() _now;

  /// Voice Satellite's timings.
  static const safety = Duration(seconds: 30);
  static const durationPad = Duration(seconds: 2);

  /// Music Assistant plays its own chime before an announcement and fetches
  /// the sound first, which the measured length does not count. Its answer
  /// to play_media ends the sound, and this much more is allowed for it.
  static const announcerPad = Duration(seconds: 10);

  /// How long Music Assistant's answer to an announcement is waited for.
  static const announcerAnswer = Duration(minutes: 5);
  static const timerPad = Duration(milliseconds: 750);
  static const timerFallbackSeconds = 2.5;
  static const timerMeasureTimeout = Duration(seconds: 3);

  int _next = 0;
  _Play? _current;
  final _timed = <String, _Timed>{};

  /// What the player was playing before a normal playback interaction took
  /// it over, put back when the interaction is done.
  _Snapshot? _snapshot;
  Timer? _restore;

  /// Paths of the sounds this speaker sent, so a snapshot never takes our
  /// own chime or speech for the user's music.
  final _sent = <String>[];

  bool owns(String id) => id.startsWith('remote-');

  /// Plays [url] on [entity] as the answer or an announcement. [normal] is
  /// normal playback mode: no announce flag, and the music put back after.
  /// [text] is what it says, when known. Null when the player could not be
  /// followed or asked.
  Future<String?> play(
    String entity,
    String url, {
    required bool normal,
    RemoteSound kind = RemoteSound.speech,
    String text = '',
  }) async {
    if (kind == RemoteSound.timed) {
      return timed(entity, url, normal: normal, text: text);
    }
    final previous = _current;
    if (previous != null) _finish(previous);
    final id = 'remote-${++_next}';
    final play = _Play(id, entity, Uri.tryParse(url)?.path ?? '', kind);
    _current = play;
    // Every remote write cancels a pending restore: the end of this one
    // schedules it again.
    _cancelRestore();
    final watch = await _Watch.open(ha, entity, log);
    if (!identical(_current, play)) {
      unawaited(watch?.close());
      return null;
    }
    play.watch = watch;
    final state = watch?.state;
    play.initialState = state?.state;
    play.initialContent = state?.content;
    play.answersAtEnd =
        !normal && state?.attributes['mass_player_type'] != null;
    if (normal) _ensureSnapshot(entity, state);
    final media = await _forSpeaker(entity, url, state: state);
    if (!identical(_current, play)) return id;
    watch?.onChange = () {
      if (!identical(_current, play)) return;
      final started = play.startedAt;
      final length = play.length;
      play.evaluate(
        watch.state,
        log,
        lengthPlayed:
            started != null &&
            length != null &&
            _now().difference(started) >= length,
      );
      if (play.done) _finish(play);
    };
    log(
      '${kind.name} on $entity announce=${!normal} media=$media '
      'was=${play.initialState} ${play.initialContent ?? ''}',
    );
    // Not waited for, as Voice Satellite: Music Assistant answers an
    // announcement only once it has played, and the caller needs the id
    // before the end it follows. That answer is the end of the sound, as
    // its player may report nothing while it plays. A refused call ends the
    // sound as if it had played, the turn carries on.
    unawaited(
      _playMedia(
        entity,
        media,
        announce: !normal,
        timeout: play.answersAtEnd ? announcerAnswer : null,
      ).then((sent) {
        if (play.finished) return;
        if (!sent) {
          log('play_media refused, completing');
          _finish(play);
          return;
        }
        if (play.answersAtEnd) _answered(play);
      }),
    );
    play.startedAt = _now();
    // A player that never says it finished is let go after this, or after
    // the sound's length once it is measured. The answer's words stand in
    // for a length the kiosk cannot measure, when they say it runs longer.
    var limit = safety;
    if (kind == RemoteSound.speech && text.trim().isNotEmpty) {
      final words = Duration(
        milliseconds: (estimateSpeechSeconds(text) * 1500).round() + 5000,
      );
      if (words > limit) limit = words;
    }
    play.deadline = Timer(limit, () {
      log('no end reported by $entity after ${limit.inSeconds}s, completing');
      _finish(play);
    });
    unawaited(_measure(play, url));
    return id;
  }

  /// Plays a chime of [seconds] on [entity], over after its length.
  /// [end] marks the end of an interaction (the done and error chimes): the
  /// music a normal playback took over comes back after it.
  Future<String?> chime(
    String entity,
    String url,
    double seconds, {
    required bool normal,
    bool end = false,
  }) async {
    _cancelRestore();
    if (normal && _snapshot == null) await _takeSnapshot(entity);
    final id = 'remote-${++_next}';
    log('chime on $entity announce=${!normal}');
    unawaited(_playMedia(entity, url, announce: !normal));
    _timed[id] = _Timed(
      entity,
      Timer(Duration(milliseconds: (seconds * 1000).round()), () {
        if (_timed.remove(id) != null) onEnded(id);
      }),
    );
    if (end && normal && _snapshot != null) {
      _scheduleRestore(Duration(milliseconds: (seconds * 1000).round()));
    }
    return id;
  }

  /// The timer phrase on [entity]: its length is measured (3 seconds at
  /// most, else read from [text]) and it is over that long after it starts.
  Future<String?> timed(
    String entity,
    String url, {
    required bool normal,
    String text = '',
  }) async {
    _cancelRestore();
    if (normal && _snapshot == null) await _takeSnapshot(entity);
    final measured = await measure?.call(url, timerMeasureTimeout);
    final seconds = measured ?? _timerEstimate(text);
    final id = 'remote-${++_next}';
    final media = await _forSpeaker(entity, url);
    log('timer phrase on $entity announce=${!normal} media=$media');
    await _playMedia(entity, media, announce: !normal);
    _timed[id] = _Timed(
      entity,
      Timer(Duration(milliseconds: (seconds * 1000).round()) + timerPad, () {
        if (_timed.remove(id) != null) onEnded(id);
      }),
    );
    return id;
  }

  /// Stops [id]. An answer or announcement that took music over in normal
  /// playback mode puts it back instead of leaving the player silent.
  Future<void> stop(String id) async {
    final timed = _timed.remove(id);
    if (timed != null) {
      timed.timer.cancel();
      onEnded(id);
      await _stopPlayer(timed.entity);
      return;
    }
    final play = _current;
    if (play == null || play.id != id) return;
    final restoring = _snapshot != null;
    _finish(play, stopped: true);
    if (restoring) {
      // A trailing done chime reschedules it for after itself.
      _scheduleRestore(const Duration(seconds: 1));
      return;
    }
    _cancelRestore();
    await _stopPlayer(play.entity);
  }

  /// The interaction is over with no chime to follow: put the music back,
  /// if a normal playback took it over (scheduleRemoteRestoreIfNeeded).
  void settle() {
    if (_snapshot != null) _scheduleRestore(const Duration(seconds: 1));
  }

  void _finish(_Play play, {bool stopped = false}) {
    if (play.finished) return;
    play.finished = true;
    play.deadline?.cancel();
    unawaited(play.watch?.close());
    if (identical(_current, play)) _current = null;
    // The answer schedules the restore itself, a done chime moves it to
    // after the chime. An announcement leaves it to the chime or the end
    // of the interaction.
    if (!stopped && play.kind == RemoteSound.speech && _snapshot != null) {
      _scheduleRestore(const Duration(seconds: 1));
    }
    onEnded(play.id);
  }

  /// Music Assistant answered the announcement. Before the sound's length
  /// has gone by the answer cannot be its end: the length decides.
  void _answered(_Play play) {
    final started = play.startedAt;
    final length = play.length;
    if (started != null &&
        length != null &&
        _now().difference(started) >= length) {
      log('Music Assistant finished the ${play.kind.name}');
      _finish(play);
      return;
    }
    play.answersAtEnd = false;
    log('Music Assistant answered early, following the length');
    if (length != null) _armLength(play, length);
  }

  Future<void> _measure(_Play play, String url) async {
    final started = play.startedAt;
    if (measure == null || started == null) return;
    final seconds = await measure!(url, const Duration(seconds: 60));
    if (seconds == null || play.finished) return;
    final length = Duration(milliseconds: (seconds * 1000).round());
    log('${play.kind.name} measured at ${seconds.toStringAsFixed(2)}s');
    play.measured = true;
    play.length = length;
    onProgress?.call(play.id, _now().difference(started), length);
    _armLength(play, length);
  }

  /// Ends [play] by its [length], counted from when it was sent, not from
  /// when its length came back: a streamed answer is measured only once
  /// Home Assistant has all of it, seconds into its playback. A sound
  /// Music Assistant answers for is given more, its answer ends it.
  void _armLength(_Play play, Duration length) {
    final started = play.startedAt!;
    final pad = play.answersAtEnd ? durationPad + announcerPad : durationPad;
    final left = length + pad - _now().difference(started);
    play.deadline?.cancel();
    play.deadline = Timer(left.isNegative ? Duration.zero : left, () {
      log('${play.kind.name} over by its length');
      _finish(play);
    });
  }

  void _ensureSnapshot(String entity, _State? state) {
    if (_snapshot != null || state == null) return;
    final snapshot = state.snapshot(entity);
    if (snapshot == null || _isOurs(snapshot.id)) return;
    _snapshot = snapshot;
    log(
      'snapshot of $entity: ${snapshot.id} '
      'at ${snapshot.position.toStringAsFixed(1)}s',
    );
  }

  Future<void> _takeSnapshot(String entity) async =>
      _ensureSnapshot(entity, await _stateOf(entity));

  /// [entity]'s state right now, or null when it could not be read.
  Future<_State?> _stateOf(String entity) async {
    final watch = await _Watch.open(ha, entity, log);
    unawaited(watch?.close());
    return watch?.state;
  }

  bool _isOurs(String content) =>
      content.contains('/api/tts_proxy/') ||
      _sent.any((path) => path.isNotEmpty && content.contains(path));

  void _cancelRestore() {
    _restore?.cancel();
    _restore = null;
  }

  /// Puts the snapshot back half a second after [after], skipping media
  /// that was at its end.
  void _scheduleRestore(Duration after) {
    _cancelRestore();
    _restore = Timer(after + const Duration(milliseconds: 500), () {
      _restore = null;
      final snapshot = _snapshot;
      _snapshot = null;
      if (snapshot == null) return;
      final duration = snapshot.duration;
      if (duration != null && snapshot.position + 2 >= duration) {
        log('not restoring ${snapshot.id}, it was at its end');
        return;
      }
      log(
        'restoring ${snapshot.id} on ${snapshot.entity} '
        'at ${snapshot.position.toStringAsFixed(1)}s',
      );
      unawaited(_putBack(snapshot));
    });
  }

  /// Plays [snapshot] again where it was: Cast honors the position in
  /// `extra`, others take a seek once it has buffered.
  Future<void> _putBack(_Snapshot snapshot) async {
    await _call('play_media', {
      'entity_id': snapshot.entity,
      'media_content_id': snapshot.id,
      'media_content_type': snapshot.type,
      'extra': {'current_time': snapshot.position},
    });
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await _call('media_seek', {
      'entity_id': snapshot.entity,
      'seek_position': snapshot.position,
    }, quiet: true);
  }

  Future<bool> _playMedia(
    String entity,
    String media, {
    required bool announce,
    Duration? timeout,
  }) {
    _sent
      ..add(Uri.tryParse(media)?.path ?? media)
      ..removeRange(0, _sent.length > 20 ? _sent.length - 20 : 0);
    return _call('play_media', {
      'entity_id': entity,
      'media_content_id': media,
      'media_content_type': 'music',
      'announce': announce,
    }, timeout: timeout);
  }

  Future<void> _stopPlayer(String entity) =>
      _call('media_stop', {'entity_id': entity});

  Future<bool> _call(
    String service,
    Map<String, Object?> data, {
    bool quiet = false,
    Duration? timeout,
  }) async {
    try {
      final command = {
        'type': 'call_service',
        'domain': 'media_player',
        'service': service,
        'service_data': data,
      };
      if (timeout == null) {
        await ha.request(command);
      } else {
        await ha.request(command, timeout: timeout);
      }
      return true;
    } catch (e) {
      if (!quiet) log('$service on ${data['entity_id']} failed: $e');
      return false;
    }
  }

  /// [url] as [entity] gets it. A Home Assistant URL goes as a path from
  /// its root, which Home Assistant resolves and signs for the speaker the
  /// way tts.speak does. The speaker may not reach the address the kiosk
  /// uses, or trust its certificate. media-source:// ids pass as they are,
  /// for Home Assistant to resolve.
  ///
  /// Music Assistant's integration resolves media-source ids only and its
  /// players refuse a path, so they get it on Home Assistant's own address,
  /// the one Home Assistant puts in front of it for every other player.
  Future<String> _forSpeaker(String entity, String url, {_State? state}) async {
    final path = _haPath(url);
    if (path == null) return url;
    state ??= await _stateOf(entity);
    if (state?.attributes['mass_player_type'] == null) return path;
    final base = await _haAddress();
    return base == null ? url : '$base$path';
  }

  /// The path and query of a Home Assistant API URL, or null for anything
  /// else.
  static String? _haPath(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.path.startsWith('/api/')) {
      return null;
    }
    return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
  }

  /// Home Assistant's address for the devices it sends media to: its
  /// internal URL, else its external one, as its get_url picks them.
  Future<String?> _haAddress() async {
    try {
      final urls = await ha.request({'type': 'network/url'});
      if (urls is Map) {
        for (final key in const ['internal', 'external']) {
          final url = urls[key];
          if (url is String && url.isNotEmpty) {
            return url.replaceFirst(RegExp(r'/+$'), '');
          }
        }
      }
      log('Home Assistant has no URL for devices');
    } catch (e) {
      log('Home Assistant URL not read: $e');
    }
    return null;
  }

  /// About how long [text] takes to say: the timer phrase's stand-in when
  /// its audio cannot be measured (words at 420 ms, 2.5 s at least).
  static double _timerEstimate(String text) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final seconds = words.length * 0.42;
    return seconds > timerFallbackSeconds ? seconds : timerFallbackSeconds;
  }

  void dispose() {
    _cancelRestore();
    for (final t in _timed.values) {
      t.timer.cancel();
    }
    _timed.clear();
    final play = _current;
    if (play != null) _finish(play, stopped: true);
  }
}

class _Timed {
  _Timed(this.entity, this.timer);
  final String entity;
  final Timer timer;
}

/// One media player's state, as Home Assistant's compressed entity
/// messages keep it.
class _State {
  String? state;
  Map<String, Object?> attributes = {};

  String? get content => attributes['media_content_id'] as String?;
  bool get active => state == 'playing' || state == 'buffering';

  /// `a` adds an entity whole, `c` changes it (`+` new values, `-` removed
  /// attributes), `r` removes it.
  void apply(String entity, Map<String, Object?> event) {
    final added = event['a'];
    if (added is Map && added[entity] is Map) {
      final e = (added[entity] as Map).cast<String, Object?>();
      state = e['s'] as String?;
      attributes = ((e['a'] as Map?) ?? const {}).cast<String, Object?>();
    }
    final changed = event['c'];
    if (changed is Map && changed[entity] is Map) {
      final diff = (changed[entity] as Map).cast<String, Object?>();
      final plus = diff['+'];
      if (plus is Map) {
        if (plus['s'] is String) state = plus['s'] as String;
        final attrs = plus['a'];
        if (attrs is Map) {
          attributes = {...attributes, ...attrs.cast<String, Object?>()};
        }
      }
      final minus = diff['-'];
      if (minus is Map && minus['a'] is List) {
        attributes = {...attributes}
          ..removeWhere((k, _) => (minus['a'] as List).contains(k));
      }
    }
    final removed = event['r'];
    if (removed is List && removed.contains(entity)) state = 'unavailable';
  }

  /// What is playing now, to put back later: only music actually playing.
  _Snapshot? snapshot(String entity) {
    final id = content;
    if (state != 'playing' || id == null || id.isEmpty) return null;
    final updated = DateTime.tryParse(
      '${attributes['media_position_updated_at'] ?? ''}',
    );
    final elapsed = updated == null
        ? 0.0
        : DateTime.now().difference(updated).inMilliseconds / 1000;
    final position =
        ((attributes['media_position'] as num?)?.toDouble() ?? 0) +
        (elapsed > 0 ? elapsed : 0);
    final duration = (attributes['media_duration'] as num?)?.toDouble();
    return _Snapshot(
      entity: entity,
      id: id,
      type: '${attributes['media_content_type'] ?? 'music'}',
      position: position,
      duration: duration != null && duration > 0 ? duration : null,
    );
  }
}

/// A subscription to one media player's state: [state] is current from
/// the moment [open] returns.
class _Watch {
  _Watch._(this.entity);

  final String entity;
  final state = _State();
  void Function()? onChange;
  Future<void> Function()? _unsubscribe;

  static Future<_Watch?> open(
    HaSocket ha,
    String entity,
    void Function(String) log,
  ) async {
    final watch = _Watch._(entity);
    final first = Completer<void>();
    try {
      watch._unsubscribe = await ha.subscribe(
        {
          'type': 'subscribe_entities',
          'entity_ids': [entity],
        },
        (event) {
          watch.state.apply(entity, event);
          if (!first.isCompleted) {
            first.complete();
            return;
          }
          watch.onChange?.call();
        },
      );
      await first.future.timeout(const Duration(seconds: 3));
      return watch;
    } catch (e) {
      log('state of $entity not followed: $e');
      unawaited(watch.close());
      return null;
    }
  }

  Future<void> close() async {
    final unsubscribe = _unsubscribe;
    _unsubscribe = null;
    onChange = null;
    try {
      await unsubscribe?.call();
    } catch (_) {}
  }
}

/// One answer or announcement on the player.
class _Play {
  _Play(this.id, this.entity, this.path, this.kind);

  final String id;
  final String entity;

  /// The path of our audio: the player reporting it is on our sound.
  final String path;
  final RemoteSound kind;

  _Watch? watch;
  String? initialState;
  String? initialContent;
  DateTime? startedAt;
  bool sawPlaying = false;
  bool sawOurs = false;
  bool measured = false;
  Duration? length;

  /// Music Assistant's answer to the announcement is its end.
  bool answersAtEnd = false;
  bool finished = false;
  bool done = false;
  Timer? deadline;

  /// Judges the player's latest state against the one from before.
  /// [lengthPlayed]: the sound's measured length has gone by since it was
  /// sent.
  void evaluate(
    _State now,
    void Function(String) log, {
    bool lengthPlayed = false,
  }) {
    final active = now.active;
    final id = now.content;
    if (active && id != null && path.isNotEmpty && id.contains(path)) {
      sawOurs = true;
    }
    // A player that was already playing is on our sound only once what it
    // plays changes, and done once it is back on what it played. One that
    // was not playing has nothing to go back to: Music Assistant keeps the
    // last track's id while it announces, and an update in the middle of
    // the announcement would look like the music coming back.
    final wasActive = initialState == 'playing' || initialState == 'buffering';
    // Once the answer's length is known it decides, since players with
    // other media blip through paused or resume the same content early.
    // What outranks it: the player showed our sound, then stopped, or a
    // player that was not playing played and stopped once the length went
    // by. Nothing else looks like that.
    if (kind == RemoteSound.speech && measured) {
      if (active && !wasActive) sawPlaying = true;
      if (active) return;
      if (sawOurs) {
        log('the player finished our sound (${now.state}), completing');
        done = true;
      } else if (sawPlaying && !wasActive && lengthPlayed) {
        log('the player stopped (${now.state}), completing');
        done = true;
      }
      return;
    }
    if (!sawPlaying) {
      if (!active) return;
      if (wasActive && id == initialContent) return;
      sawPlaying = true;
      return;
    }
    if (!active) {
      log('the player stopped (${now.state}), completing');
      done = true;
      return;
    }
    if (wasActive && initialContent != null && id == initialContent) {
      log('the player resumed what it played before, completing');
      done = true;
    }
  }
}

class _Snapshot {
  const _Snapshot({
    required this.entity,
    required this.id,
    required this.type,
    required this.position,
    this.duration,
  });

  final String entity;
  final String id;
  final String type;
  final double position;
  final double? duration;
}
