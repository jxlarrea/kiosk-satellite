import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/dlna/dlna_playback.dart';
import 'package:video_player/video_player.dart';

/// Issue #1604: a live stream's unknown length reaches Dart as a 1 ms
/// duration, so every rebuffer used to look like the end of the media.
void main() {
  // What video_player makes of ExoPlayer's C.TIME_UNSET.
  const timeUnset = -9223372036854775807;
  final liveDuration = Duration(milliseconds: timeUnset);

  VideoPlayerValue value({
    required Duration duration,
    Duration position = Duration.zero,
    bool playing = false,
    bool buffering = false,
  }) => VideoPlayerValue(
    duration: duration,
    position: position,
    isInitialized: true,
    isPlaying: playing,
    isBuffering: buffering,
  );

  test('TIME_UNSET overflows to 1 ms and counts as unknown length', () {
    expect(liveDuration, const Duration(milliseconds: 1));
    expect(hasUnknownLength(value(duration: liveDuration)), isTrue);
    expect(hasUnknownLength(value(duration: Duration.zero)), isTrue);
    expect(
      hasUnknownLength(value(duration: const Duration(seconds: 30))),
      isFalse,
    );
  });

  test('a live video rebuffer is not the end', () {
    final v = value(
      duration: liveDuration,
      position: liveDuration,
      buffering: true,
    );
    expect(dlnaEndOf(v, paused: false, video: true), DlnaEnd.no);
  });

  test('a live video that stopped without buffering waits to end', () {
    final v = value(duration: liveDuration, position: liveDuration);
    expect(dlnaEndOf(v, paused: false, video: true), DlnaEnd.ifStillStopped);
    expect(dlnaEndOf(v, paused: true, video: true), DlnaEnd.no);
  });

  test('live audio only ends on Stop', () {
    final v = value(duration: Duration.zero);
    expect(dlnaEndOf(v, paused: false, video: false), DlnaEnd.no);
  });

  test('media with a length ends at its end', () {
    const length = Duration(minutes: 3);
    expect(
      dlnaEndOf(
        value(duration: length, position: length),
        paused: false,
        video: true,
      ),
      DlnaEnd.now,
    );
    expect(
      dlnaEndOf(
        value(duration: length, position: const Duration(minutes: 1)),
        paused: false,
        video: true,
      ),
      DlnaEnd.no,
    );
    expect(
      dlnaEndOf(
        value(duration: length, position: length, playing: true),
        paused: false,
        video: true,
      ),
      DlnaEnd.no,
    );
  });
}
