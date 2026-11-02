import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether the kiosk is playing audio, for the wake words' playback
/// thresholds (`WakeWordModelRef.playbackConfidenceScale`).
///
/// Asks the echo reference once a second whether one of the kiosk's own
/// players made a sound. Those are the players the echo canceller takes out,
/// and the reference only fills while it runs, so a kiosk without it never
/// counts as playing. Playback starts after a few seconds of it and ends
/// after a few quiet ones: a chime or the gap between two tracks should not
/// move the thresholds back and forth.
class PlaybackWatch {
  PlaybackWatch({
    required this.onChanged,
    required this.wanted,
    Future<bool> Function()? played,
  }) : _played = played ?? _nativePlayed;

  /// Called with the new state on every change.
  final void Function(bool playing) onChanged;

  /// Whether anything still listens. Once it says no, the watch stops on
  /// its next poll, so every way an engine stops is covered.
  final bool Function() wanted;
  final Future<bool> Function() _played;

  static const period = Duration(seconds: 1);

  /// Polls in a row that must agree before the state flips.
  static const confirmPolls = 3;

  /// A player writes a little ahead of the speaker and in bursts, so the
  /// question covers more than one poll.
  static const _window = Duration(milliseconds: 1500);

  static const _channel = MethodChannel('kiosk_satellite/audio_routing');

  static Future<bool> _nativePlayed() async {
    try {
      return await _channel.invokeMethod<bool>('playedWithin', {
            'ms': _window.inMilliseconds,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Timer? _timer;
  bool _polling = false;
  bool _playing = false;
  int _streak = 0;

  bool get playing => _playing;
  bool get running => _timer != null;

  void start() {
    _timer ??= Timer.periodic(period, (_) => poll());
  }

  /// Stop polling and forget the state, without reporting the change: the
  /// engine it was for has stopped and forgets it too.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _playing = false;
    _streak = 0;
  }

  @visibleForTesting
  Future<void> poll() async {
    if (_polling) return;
    if (!wanted()) {
      stop();
      return;
    }
    _polling = true;
    try {
      final played = await _played();
      // Stopped while it asked.
      if (_timer == null) return;
      if (played == _playing) {
        _streak = 0;
        return;
      }
      if (++_streak < confirmPolls) return;
      _streak = 0;
      _playing = played;
      onChanged(played);
    } finally {
      _polling = false;
    }
  }
}
