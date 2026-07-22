import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import '../app_container.dart';
import '../managers/dlna/dlna_manager.dart';

/// Full-screen display for media pushed over DLNA: an image, a video, or
/// audio (shown as a title card while it plays). Sits above the kiosk and
/// the drawer, below the screensaver — which never shows while this plays,
/// because the manager reports playback as activity.
///
/// A tap anywhere dismisses (and reports Stop to the controller); ending
/// media dismisses itself.
class DlnaMediaOverlay extends StatelessWidget {
  const DlnaMediaOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    final dlna = container.dlna;
    return AnimatedBuilder(
      animation: Listenable.merge([
        dlna.media,
        dlna.transportState,
        dlna.pending,
      ]),
      builder: (context, _) {
        final media = dlna.media.value;
        final state = dlna.transportState.value;
        // Queued-but-not-yet-playing shows the loading screen right away:
        // the controller's buffering window (URI resolution, its can-play
        // poll, stream spin-up) is otherwise dead air on the wall.
        final loading = media != null && state == 'STOPPED' && dlna.pending.value;
        if (media == null || (state == 'STOPPED' && !loading)) {
          return const SizedBox.shrink();
        }
        return GestureDetector(
          onTap: dlna.userDismiss,
          child: Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: loading
                ? _Loading(title: media.title)
                : switch (media.kind) {
                    'image' =>
                      _DlnaImage(key: ValueKey(media.uri), uri: media.uri),
                    'auto' => _DlnaProbe(
                        key: ValueKey(media.uri),
                        dlna: dlna,
                        media: media,
                        paused: state == 'PAUSED_PLAYBACK',
                      ),
                    _ => _DlnaPlayer(
                        key: ValueKey(media.uri),
                        dlna: dlna,
                        media: media,
                        paused: state == 'PAUSED_PLAYBACK',
                      ),
                  },
          ),
        );
      },
    );
  }

}

/// Undeclared media (generic upnp:class, octet-stream mime): ask the URL
/// itself. One request for the response headers decides — image/* and
/// MJPEG multipart render as images, everything else goes to the video
/// player (with the HLS hint when the server says mpegurl).
class _DlnaProbe extends StatefulWidget {
  const _DlnaProbe({
    super.key,
    required this.dlna,
    required this.media,
    required this.paused,
  });

  final DlnaManager dlna;
  final DlnaMedia media;
  final bool paused;

  @override
  State<_DlnaProbe> createState() => _DlnaProbeState();
}

class _DlnaProbeState extends State<_DlnaProbe> {
  String? _resolved; // 'image' | 'video' | 'hls'
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe() async {
    final client = http.Client();
    try {
      final res = await client
          .send(http.Request('GET', Uri.parse(widget.media.uri)))
          .timeout(const Duration(seconds: 15));
      final type = (res.headers['content-type'] ?? '').toLowerCase();
      if (!mounted) return;
      setState(() {
        _resolved = type.startsWith('image/') ||
                type.startsWith('multipart/x-mixed-replace')
            ? 'image'
            : type.contains('mpegurl')
                ? 'hls'
                : 'video';
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      // The decision needed only the headers; the chosen component opens
      // its own connection.
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.white38, size: 72),
      );
    }
    return switch (_resolved) {
      null => const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
      'image' => _DlnaImage(uri: widget.media.uri),
      _ => _DlnaPlayer(
          dlna: widget.dlna,
          media: DlnaMedia(
            uri: widget.media.uri,
            kind: 'video',
            metadata: widget.media.metadata,
            title: widget.media.title,
            hls: _resolved == 'hls',
          ),
          paused: widget.paused,
        ),
    };
  }
}

/// The buffering screen: spinner plus the media title when one was sent.
class _Loading extends StatelessWidget {
  const _Loading({this.title});

  final String? title;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white54),
          if (title != null && title!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                title!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 20),
              ),
            ),
          ],
        ],
      );
}

/// Image display that handles what HA actually serves. Media files come as
/// plain `image/*` responses; image ENTITIES resolve to the
/// `image_proxy_stream` endpoint, a `multipart/x-mixed-replace` stream that
/// pushes a new frame whenever the entity updates and never ends —
/// Image.network buffers such a stream forever. Multipart frames are shown
/// as they arrive, so a pushed image entity stays live on the wall.
class _DlnaImage extends StatefulWidget {
  const _DlnaImage({super.key, required this.uri});

  final String uri;

  @override
  State<_DlnaImage> createState() => _DlnaImageState();
}

class _DlnaImageState extends State<_DlnaImage> {
  ImageProvider? _image;
  bool _failed = false;
  http.Client? _client;
  StreamSubscription<Uint8List>? _frames;
  Timer? _firstFrameTimeout;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = http.Client();
      _client = client;
      final res = await client.send(
        http.Request('GET', Uri.parse(widget.uri)),
      );
      if (res.statusCode != 200) throw http.ClientException('${res.statusCode}');
      final type = res.headers['content-type'] ?? '';
      if (type.startsWith('multipart/x-mixed-replace')) {
        var boundary =
            RegExp(r'boundary=([^;\s]+)').firstMatch(type)?[1] ?? '';
        // RFC 2045 allows the boundary parameter to be quoted; the quotes
        // are not part of the marker.
        if (boundary.length > 1 &&
            boundary.startsWith('"') &&
            boundary.endsWith('"')) {
          boundary = boundary.substring(1, boundary.length - 1);
        }
        _firstFrameTimeout = Timer(const Duration(seconds: 20), () {
          if (_image == null && mounted) setState(() => _failed = true);
        });
        _frames = _multipartFrames(res.stream, boundary).listen(
          _setFrame,
          onError: (Object _) {
            if (_image == null && mounted) setState(() => _failed = true);
          },
        );
      } else {
        final bytes = await res.stream.toBytes();
        client.close();
        _client = null;
        _setFrame(bytes);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Split a multipart/x-mixed-replace body into frame payloads. Parts
  /// carry their own headers; Content-Length is used when present, the
  /// next boundary marker otherwise.
  Stream<Uint8List> _multipartFrames(
    http.ByteStream body,
    String boundary,
  ) async* {
    // 16 MB is generous for any camera frame; a part that outgrows it has
    // a bogus Content-Length or a boundary that will never match, so the
    // buffered bytes are dropped and parsing resyncs at the next marker.
    const maxBuffer = 16 * 1024 * 1024;
    const headerSep = [13, 10, 13, 10];
    final marker = '--$boundary'.codeUnits;
    var buf = Uint8List(64 * 1024);
    var len = 0;
    var headerEnd = -1; // Separator position once found, -1 while scanning.
    var frameEnd = -1; // Known end when the part declared Content-Length.
    var scanFrom = 0; // Searches resume here instead of rescanning old bytes.
    var resyncing = false;

    // Drop the first n bytes; the remainder moves to the front.
    void consume(int n) {
      buf.setRange(0, len - n, buf, n);
      len -= n;
      headerEnd = -1;
      frameEnd = -1;
      scanFrom = 0;
    }

    void append(List<int> chunk) {
      if (len + chunk.length > buf.length) {
        var cap = buf.length;
        while (cap < len + chunk.length) {
          cap *= 2;
        }
        final grown = Uint8List(cap);
        grown.setRange(0, len, buf);
        buf = grown;
      }
      buf.setRange(len, len + chunk.length, chunk);
      len += chunk.length;
    }

    await for (final chunk in body) {
      if (len + chunk.length > maxBuffer) {
        if (boundary.isEmpty) {
          // No marker to resync on.
          throw const FormatException('unbounded multipart part');
        }
        final keep = marker.length - 1;
        if (len > keep) consume(len - keep);
        resyncing = true;
      }
      append(chunk);
      if (resyncing) {
        final next = _indexOf(buf, len, marker);
        if (next < 0) {
          // Keep a marker-sized tail so a boundary split across chunks
          // still matches.
          final keep = marker.length - 1;
          if (len > keep) consume(len - keep);
          continue;
        }
        consume(next);
        resyncing = false;
      }
      while (true) {
        if (headerEnd < 0) {
          headerEnd = _indexOf(buf, len, headerSep, from: scanFrom);
          if (headerEnd < 0) {
            scanFrom = len > 3 ? len - 3 : 0;
            break;
          }
          final headers = String.fromCharCodes(buf, 0, headerEnd);
          final lengthMatch = RegExp(
            r'content-length:\s*(\d+)',
            caseSensitive: false,
          ).firstMatch(headers);
          if (lengthMatch != null) {
            final length = int.parse(lengthMatch[1]!);
            if (headerEnd + 4 + length > maxBuffer) {
              throw const FormatException('multipart frame exceeds cap');
            }
            frameEnd = headerEnd + 4 + length;
          } else {
            scanFrom = headerEnd + 4;
          }
        }
        final bodyStart = headerEnd + 4;
        int end;
        if (frameEnd >= 0) {
          if (len < frameEnd) break;
          end = frameEnd;
        } else {
          end = _indexOf(buf, len, marker, from: scanFrom);
          if (end < 0) {
            final resume = len - marker.length + 1;
            scanFrom = resume > bodyStart ? resume : bodyStart;
            break;
          }
        }
        yield buf.sublist(bodyStart, end);
        consume(end);
      }
    }
  }

  static int _indexOf(
    Uint8List haystack,
    int length,
    List<int> needle, {
    int from = 0,
  }) {
    outer:
    for (var i = from; i <= length - needle.length; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) continue outer;
      }
      return i;
    }
    return -1;
  }

  /// Swap in a new frame. The provider is built once per frame so the
  /// evict below hits the same cache key, and ResizeImage bounds the
  /// decode to the screen instead of the camera's native resolution.
  void _setFrame(Uint8List bytes) {
    if (!mounted) return;
    final width = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .round();
    final previous = _image;
    setState(() {
      _image = width > 0
          ? ResizeImage(MemoryImage(bytes), width: width)
          : MemoryImage(bytes);
    });
    // Without the evict every multipart frame stays in the global
    // imageCache forever.
    unawaited(previous?.evict());
  }

  @override
  void dispose() {
    _firstFrameTimeout?.cancel();
    unawaited(_frames?.cancel());
    _client?.close();
    unawaited(_image?.evict());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white38,
          size: 72,
        ),
      );
    }
    final image = _image;
    if (image == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }
    // gaplessPlayback: a multipart frame update swaps the picture without
    // flashing through a blank decode gap.
    return Image(
      image: image,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) => const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white38,
          size: 72,
        ),
      ),
    );
  }
}

/// Video and audio playback via the platform player. Reports progress to
/// the manager (GetPositionInfo answers from it), obeys pause/volume/mute/
/// seek from the controller, and stops the whole overlay when media ends.
class _DlnaPlayer extends StatefulWidget {
  const _DlnaPlayer({
    super.key,
    required this.dlna,
    required this.media,
    required this.paused,
  });

  final DlnaManager dlna;
  final DlnaMedia media;
  final bool paused;

  @override
  State<_DlnaPlayer> createState() => _DlnaPlayerState();
}

class _DlnaPlayerState extends State<_DlnaPlayer> {
  VideoPlayerController? _controller;
  Timer? _progress;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
    widget.dlna.volume.addListener(_applyVolume);
    widget.dlna.muted.addListener(_applyVolume);
    widget.dlna.seekTo.addListener(_applySeek);
  }

  Future<void> _start() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.media.uri),
        // HLS must be declared: ExoPlayer's by-extension sniffing misses
        // signed HA camera-stream URLs and tries progressive extractors,
        // which cannot read a playlist ("None of the available
        // extractors could read the stream").
        formatHint: widget.media.hls ? VideoFormat.hls : null,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      _applyVolume();
      await controller.play();
      controller.addListener(_onPlayerEvent);
      _progress = Timer.periodic(const Duration(milliseconds: 500), (_) {
        final v = _controller?.value;
        if (v != null && v.isInitialized) {
          widget.dlna.reportProgress(widget.media.uri, v.position, v.duration);
        }
      });
      setState(() {});
    } catch (e) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onPlayerEvent() {
    final v = _controller?.value;
    if (v == null) return;
    // Completion: position pinned at duration and not playing.
    if (v.isInitialized &&
        !v.isPlaying &&
        v.duration > Duration.zero &&
        v.position >= v.duration) {
      widget.dlna.onPlaybackEnded(widget.media.uri);
    }
  }

  void _applyVolume() {
    final v = widget.dlna.muted.value ? 0.0 : widget.dlna.volume.value / 100;
    _controller?.setVolume(v);
  }

  void _applySeek() {
    final target = widget.dlna.seekTo.value;
    if (target != null) {
      _controller?.seekTo(target);
      widget.dlna.seekTo.value = null;
    }
  }

  @override
  void didUpdateWidget(_DlnaPlayer old) {
    super.didUpdateWidget(old);
    if (widget.paused != old.paused) {
      widget.paused ? _controller?.pause() : _controller?.play();
    }
  }

  @override
  void dispose() {
    widget.dlna.volume.removeListener(_applyVolume);
    widget.dlna.muted.removeListener(_applyVolume);
    widget.dlna.seekTo.removeListener(_applySeek);
    _progress?.cancel();
    _controller?.removeListener(_onPlayerEvent);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.white38, size: 72),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }
    // Audio (or a video stream with no visual): a simple title card.
    if (widget.media.kind == 'audio' || controller.value.size.width == 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note_outlined, color: Colors.white54, size: 96),
          if (widget.media.title != null) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                widget.media.title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      );
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    );
  }
}
