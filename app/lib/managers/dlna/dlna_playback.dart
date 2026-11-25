import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// What the DLNA overlay needs from a player: the video_player controller
/// for video, or [DlnaAudioPlayback] for audio.
abstract interface class DlnaPlayback
    implements ValueListenable<VideoPlayerValue> {
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

/// What a player's state says about the media ending.
enum DlnaEnd {
  /// Still playing, buffering, paused by the controller, or live audio.
  no,

  /// Media with a length reached its end.
  now,

  /// A live video stream stopped without buffering. A stream that closed
  /// stays this way, so end it if it is still stopped a moment later.
  ifStillStopped,
}

/// A live stream has no length. ExoPlayer reports C.TIME_UNSET for it,
/// which video_player turns into a 1 ms duration (its millisecond to
/// microsecond multiply overflows) and then clamps the position to. Treat
/// that as unknown, or every rebuffer looks like the end of the media
/// (issue #1604). The kiosk's audio player reports 0 for a live stream.
bool hasUnknownLength(VideoPlayerValue v) =>
    v.duration <= const Duration(milliseconds: 1);

DlnaEnd dlnaEndOf(
  VideoPlayerValue v, {
  required bool paused,
  required bool video,
}) {
  if (!v.isInitialized || v.isPlaying) return DlnaEnd.no;
  if (!hasUnknownLength(v)) {
    return v.position >= v.duration ? DlnaEnd.now : DlnaEnd.no;
  }
  // The audio player reports no buffering state, so a live audio stream
  // only ends on Stop, as before.
  if (!video || paused || v.isBuffering) return DlnaEnd.no;
  return DlnaEnd.ifStillStopped;
}

class DlnaVideoPlayback implements DlnaPlayback {
  DlnaVideoPlayback(this.controller);

  final VideoPlayerController controller;

  @override
  VideoPlayerValue get value => controller.value;

  @override
  void addListener(VoidCallback listener) => controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      controller.removeListener(listener);

  @override
  Future<void> play() => controller.play();

  @override
  Future<void> pause() => controller.pause();

  @override
  Future<void> seekTo(Duration position) => controller.seekTo(position);

  @override
  Future<void> setVolume(double volume) => controller.setVolume(volume);

  @override
  Future<void> dispose() => controller.dispose();
}

/// Audio through the kiosk's own native player (DlnaAudio.kt), which the
/// software echo canceller hears, so the wake word still works over music
/// pushed to the kiosk. One at a time, like the renderer itself.
class DlnaAudioPlayback extends ValueNotifier<VideoPlayerValue>
    implements DlnaPlayback {
  DlnaAudioPlayback._() : super(VideoPlayerValue(duration: Duration.zero));

  static const _channel = MethodChannel('kiosk_satellite/dlna_audio');
  static DlnaAudioPlayback? _current;

  static Future<DlnaAudioPlayback> open(String uri, {bool hls = false}) async {
    final playback = DlnaAudioPlayback._();
    _current = playback;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'state') _current?._onState(call.arguments);
      return null;
    });
    await _channel.invokeMethod('open', {'uri': uri, 'hls': hls});
    return playback;
  }

  bool _disposed = false;

  void _onState(Object? raw) {
    if (_disposed || raw is! Map) return;
    final error = raw['error'];
    if (error is String) {
      value = value.copyWith(errorDescription: error, isPlaying: false);
      return;
    }
    value = value.copyWith(
      // Once it has started it stays started, as the plugin's value does.
      isInitialized: value.isInitialized || raw['ready'] == true,
      isPlaying: raw['playing'] == true,
      position: Duration(
        milliseconds: (raw['positionMs'] as num?)?.toInt() ?? 0,
      ),
      duration: Duration(
        milliseconds: (raw['durationMs'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  @override
  Future<void> play() => _call('play');

  @override
  Future<void> pause() => _call('pause');

  @override
  Future<void> seekTo(Duration position) =>
      _call('seek', {'ms': position.inMilliseconds});

  @override
  Future<void> setVolume(double volume) =>
      _call('volume', {'volume': volume.clamp(0.0, 1.0)});

  Future<void> _call(String method, [Map<String, Object?>? args]) async {
    if (_disposed || !identical(_current, this)) return;
    await _channel.invokeMethod(method, args);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (identical(_current, this)) {
      _current = null;
      await _channel.invokeMethod('close');
    }
    super.dispose();
  }
}
