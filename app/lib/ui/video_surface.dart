/// Opening a video the way a broken hardware decoder will accept.
///
/// Flutter renders a texture into an `ImageReader` on API 29 and up, and
/// that reader holds up to 7 images, so the native window asks the decoder
/// for 8 buffers beyond its own. Some MediaTek AVC decoders cap their
/// output port well below the sum and refuse every count ACodec tries
/// (issue #374, reproduced on an Echo Show 8):
///
///     [OUTPUT] ... nBufferCountActual(6)
///     [OMX.MTK.VIDEO.DECODER.AVC] setting nBufferCountActual to 14 failed: -22
///     ... 13, 12, 11 ...
///     Failed to allocate buffers after transitioning to IDLE state
///     Decoder init failed: OMX.MTK.VIDEO.DECODER.AVC
///
/// A SurfaceView keeps only two or three buffers back, so the same file and
/// the same decoder start fine through a platform view. The texture stays
/// the default everywhere - it composites inside Flutter and costs less -
/// and only a device that fails this way pays for the second attempt.
library;

import 'package:video_player/video_player.dart';

/// Whether a player error is the video decoder refusing to start, rather
/// than a URL, a network or a container the device cannot read.
///
/// ExoPlayer's message reaches Dart as the plugin's
/// "Video player had error `<exception>`" string, so the match is on wording,
/// not a type. All three spellings below have been seen in the field.
bool isVideoDecoderFailure(Object error) {
  final text = error.toString();
  return text.contains('MediaCodecVideoRenderer error') ||
      text.contains('Decoder init failed') ||
      text.contains('DecoderInitializationException');
}

/// Builds a controller with [build] and initializes it, retrying once on a
/// decoder failure with [VideoViewType.platformView].
///
/// [build] must return a fresh controller for the view type it is handed;
/// the failed one is disposed before the retry. [onFallback] reports the
/// first error when the retry happens, for the log. The returned controller
/// is initialized and owned by the caller.
Future<VideoPlayerController> openVideo(
  VideoPlayerController Function(VideoViewType viewType) build, {
  void Function(Object error)? onFallback,
}) async {
  final first = build(VideoViewType.textureView);
  try {
    await first.initialize();
    return first;
  } catch (e) {
    await first.dispose();
    if (!isVideoDecoderFailure(e)) rethrow;
    onFallback?.call(e);
    final second = build(VideoViewType.platformView);
    try {
      await second.initialize();
      return second;
    } catch (_) {
      await second.dispose();
      rethrow;
    }
  }
}
