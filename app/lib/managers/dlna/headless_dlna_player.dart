import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logging.dart';
import 'dlna_manager.dart';
import 'dlna_playback.dart';

/// DLNA playback on a device without a screen.
///
/// With a screen, the DLNA overlay owns the player (ui/dlna_media_overlay.dart),
/// even for background audio, which it keeps mounted offstage. Headless
/// there is no widget tree, so this class does the overlay's player work:
/// open the kiosk's own audio player for whatever the controller sets, keep
/// pause, volume, mute and seek in step with it, and report progress and
/// the end of the media back to the manager. The renderer only advertises
/// audio here, so video should not arrive; if a controller sends it anyway,
/// its sound plays.
class HeadlessDlnaPlayer {
  HeadlessDlnaPlayer(this._dlna, this._mediaGain, this._log);

  final DlnaManager _dlna;
  final ValueListenable<double> _mediaGain;
  final Logger _log;

  DlnaPlayback? _player;
  String? _uri;
  Timer? _progress;

  /// Bumped by every open and close, so an open that finishes after the
  /// media moved on closes what it opened instead of keeping it.
  int _generation = 0;

  void start() {
    _dlna.media.addListener(_sync);
    _dlna.transportState.addListener(_sync);
    _dlna.volume.addListener(_applyVolume);
    _dlna.muted.addListener(_applyVolume);
    _mediaGain.addListener(_applyVolume);
    _dlna.seekTo.addListener(_applySeek);
  }

  void _sync() {
    final media = _dlna.media.value;
    final state = _dlna.transportState.value;
    // Nothing to run while the controller is still queueing.
    final wanted = media != null && state != 'STOPPED' && media.kind != 'image'
        ? media.uri
        : null;
    if (wanted != _uri) {
      unawaited(_close());
      if (wanted != null) unawaited(_open(media!));
      return;
    }
    if (state == 'PAUSED_PLAYBACK') {
      unawaited(_player?.pause());
    } else if (state == 'PLAYING') {
      unawaited(_player?.play());
    }
  }

  Future<void> _open(DlnaMedia media) async {
    final generation = ++_generation;
    _uri = media.uri;
    try {
      final player = await DlnaAudioPlayback.open(media.uri, hls: media.hls);
      if (generation != _generation) {
        await player.dispose();
        return;
      }
      _player = player;
      _applyVolume();
      if (_dlna.transportState.value != 'PAUSED_PLAYBACK') await player.play();
      player.addListener(_onPlayerEvent);
      _progress = Timer.periodic(const Duration(milliseconds: 500), (_) {
        final v = _player?.value;
        if (v != null && v.isInitialized) {
          _dlna.reportProgress(media.uri, v.position, v.duration);
        }
      });
    } catch (e) {
      if (generation == _generation) {
        _dlna.reportPlaybackFailure(media.uri, '$e');
      }
    }
  }

  Future<void> _close() async {
    _generation++;
    _uri = null;
    _progress?.cancel();
    _progress = null;
    final player = _player;
    _player = null;
    if (player == null) return;
    player.removeListener(_onPlayerEvent);
    try {
      await player.dispose();
    } catch (e) {
      _log.warn('dlna', 'closing the player failed: $e');
    }
  }

  void _onPlayerEvent() {
    final uri = _uri;
    final v = _player?.value;
    if (uri == null || v == null) return;
    if (v.hasError) {
      _dlna.reportPlaybackFailure(uri, v.errorDescription ?? 'player error');
      return;
    }
    if (dlnaEndOf(v, paused: false, video: false) == DlnaEnd.now) {
      _dlna.onPlaybackEnded(uri);
    }
  }

  void _applyVolume() {
    final v = _dlna.muted.value
        ? 0.0
        : _dlna.volume.value / 100 * _mediaGain.value;
    unawaited(_player?.setVolume(v));
  }

  void _applySeek() {
    final target = _dlna.seekTo.value;
    if (target == null || _player == null) return;
    unawaited(_player!.seekTo(target));
    _dlna.seekTo.value = null;
  }
}
