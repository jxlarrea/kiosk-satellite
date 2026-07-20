import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/settings/definitions.dart' as defs;

/// The floating now-playing card for the Sendspin player.
///
/// Lives in the kiosk Stack above the dashboard. Appears while music plays
/// (or sits paused with a track loaded), shows artwork, title, artist and
/// live progress, and can be dragged anywhere; the position persists as
/// fractions of the free area, so it survives restarts and stays sensible
/// across orientation changes. Colors come from the app theme, so it
/// follows the kiosk's light/dark setting like every other app surface.
/// Single-line text that marquees leftward when it does not fit: hold,
/// scroll the hidden part into view, hold, loop from the start. Static
/// (no animation cost) when the text fits.
class _Marquee extends StatefulWidget {
  const _Marquee({required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee>
    with SingleTickerProviderStateMixin {
  static const _gap = 48.0;
  static const _pxPerSecond = 24.0;
  static const _holdSeconds = 2.0;

  late final AnimationController _ctrl = AnimationController(vsync: this);

  @override
  void didUpdateWidget(_Marquee old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _ctrl.value = 0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();
        final textWidth = painter.width;
        if (textWidth <= constraints.maxWidth) {
          _ctrl.stop();
          return Text(widget.text, maxLines: 1, style: widget.style);
        }
        // Scroll one full copy plus the gap, so the second copy lands where
        // the first began and the loop is seamless.
        final distance = textWidth + _gap;
        final scrollSeconds = distance / _pxPerSecond;
        final total = _holdSeconds + scrollSeconds;
        _ctrl.duration = Duration(milliseconds: (total * 1000).round());
        if (!_ctrl.isAnimating) _ctrl.repeat();
        // Fixed box of exactly one text line: OverflowBox has no size of its
        // own and would otherwise absorb all the height the column offers,
        // pushing the rest of the card out of view.
        return SizedBox(
          height: painter.height,
          width: constraints.maxWidth,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = _ctrl.value * total;
                final offset = t <= _holdSeconds
                    ? 0.0
                    : (t - _holdSeconds) * _pxPerSecond;
                return Transform.translate(
                  offset: Offset(-offset, 0),
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.text, maxLines: 1, style: widget.style),
                        const SizedBox(width: _gap),
                        Text(widget.text, maxLines: 1, style: widget.style),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// The full-screen now-playing view that stands in for the screensaver
/// while music plays (sendspin.fullscreen): album art as a blurred, dimmed
/// backdrop, the art again as a centered panel, and large title/artist
/// text. Deliberately control-free — it behaves exactly like a screensaver
/// and the host wraps it in the same tap-to-dismiss surface.
class SendspinFullscreenView extends StatefulWidget {
  const SendspinFullscreenView({super.key, required this.container});

  final AppContainer container;

  @override
  State<SendspinFullscreenView> createState() => _SendspinFullscreenViewState();
}

class _SendspinFullscreenViewState extends State<SendspinFullscreenView> {
  AppContainer get c => widget.container;

  Uint8List? _artBytes;
  String _artUrl = '';

  @override
  void initState() {
    super.initState();
    c.sendspin.nowPlaying.addListener(_onNowPlaying);
    _onNowPlaying();
  }

  @override
  void dispose() {
    c.sendspin.nowPlaying.removeListener(_onNowPlaying);
    super.dispose();
  }

  void _onNowPlaying() {
    final url = '${c.sendspin.nowPlaying.value?['artworkUrl'] ?? ''}';
    if (url != _artUrl) {
      _artUrl = url;
      _fetchArt(url);
    }
    if (mounted) setState(() {});
  }

  Future<void> _fetchArt(String url) async {
    final bytes = await fetchSendspinArtwork(c, url);
    if (mounted && url == _artUrl) setState(() => _artBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final now = c.sendspin.nowPlaying.value;
    final title = '${now?['title'] ?? ''}';
    final artist = [
      now?['artist'],
      now?['album'],
    ].where((v) => v != null && '$v'.isNotEmpty).join(' · ');
    final art = _artBytes;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        // Cross-fade the backdrop between songs rather than cutting.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          child: art == null
              ? const SizedBox.expand(key: ValueKey('no-art'))
              : Image.memory(
                  art,
                  key: ValueKey(_artUrl),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
        ),
        // Blur + scrim so the backdrop reads as atmosphere, not content.
        if (art != null)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: const ColoredBox(color: Color(0x99000000)),
          ),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: Column(
              // Keyed on the track so the whole panel (art + text) fades as
              // one between songs.
              key: ValueKey('$title|$_artUrl'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (art != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.memory(
                      art,
                      width: 360,
                      height: 360,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  )
                else
                  const Icon(
                    Icons.music_note,
                    size: 160,
                    color: Colors.white24,
                  ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ),
                if (artist.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      artist,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Fetch artwork accepting a bad TLS certificate only for the configured
/// Sendspin server's host (Music Assistant's image proxy is self-signed).
/// Shared by the floating card and the full-screen view.
Future<Uint8List?> fetchSendspinArtwork(AppContainer c, String url) async {
  if (url.isEmpty) return null;
  try {
    final serverHost = Uri.parse(
      'ws://${c.settings.get(defs.sendspinServer).trim()}',
    ).host;
    final client = HttpClient()
      ..badCertificateCallback = (cert, host, port) =>
          host == serverHost && serverHost.isNotEmpty;
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final bytes = <int>[];
    await for (final part in response) {
      bytes.addAll(part);
    }
    client.close();
    if (response.statusCode != 200) return null;
    return Uint8List.fromList(bytes);
  } catch (_) {
    return null;
  }
}

class SendspinPlayerOverlay extends StatefulWidget {
  const SendspinPlayerOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  State<SendspinPlayerOverlay> createState() => _SendspinPlayerOverlayState();
}

class _SendspinPlayerOverlayState extends State<SendspinPlayerOverlay> {
  bool get _large => c.settings.get(defs.sendspinPlayerSize) == 'large';
  double get _cardWidth => _large ? 400.0 : 320.0;
  double get _cardHeight => _large ? 152.0 : 96.0;
  double get _artSize => _large ? 128.0 : 72.0;

  AppContainer get c => widget.container;

  /// Position as fractions of the free area (screen minus card), 0..1.
  late double _fx, _fy;

  /// Ticks the progress bar between metadata pushes.
  Timer? _tick;

  /// Manually closed (the X while paused) or timed out paused: hidden
  /// until playback next starts. A paused card is resumable, but it must
  /// not squat on the dashboard forever.
  bool _dismissed = false;
  Timer? _pausedHide;

  /// Artwork bytes, fetched ourselves rather than via Image.network:
  /// Music Assistant serves artwork through its image proxy over https
  /// with a self-signed certificate, which stock fetching rejects. We
  /// accept a bad certificate ONLY when the artwork host is the same
  /// host as the configured Sendspin server, the machine this player
  /// already trusts with its whole audio session.
  Uint8List? _artBytes;
  String _artUrl = '';

  Future<void> _loadArtwork(String url) async {
    _artUrl = url;
    final bytes = await fetchSendspinArtwork(c, url);
    if (mounted && _artUrl == url) setState(() => _artBytes = bytes);
  }

  @override
  void initState() {
    super.initState();
    final parts = c.settings.get(defs.sendspinPlayerPos).split(',');
    _fx = double.tryParse(parts.first)?.clamp(0.0, 1.0) ?? 0.98;
    _fy =
        (parts.length > 1 ? double.tryParse(parts[1]) : null)?.clamp(
          0.0,
          1.0,
        ) ??
        0.98;
    c.sendspin.nowPlaying.addListener(_onNowPlaying);
    c.sendspin.voiceActive.addListener(_onVoiceActive);
    _onNowPlaying();
  }

  @override
  void dispose() {
    c.sendspin.nowPlaying.removeListener(_onNowPlaying);
    c.sendspin.voiceActive.removeListener(_onVoiceActive);
    _tick?.cancel();
    _pausedHide?.cancel();
    super.dispose();
  }

  void _onVoiceActive() {
    if (mounted) setState(() {});
  }

  void _onNowPlaying() {
    final now = c.sendspin.nowPlaying.value;
    final artwork = '${now?['artworkUrl'] ?? ''}';
    if (artwork != _artUrl) _loadArtwork(artwork);
    final playing = now?['playing'] == true;
    if (playing && _tick == null) {
      _tick = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    } else if (!playing) {
      _tick?.cancel();
      _tick = null;
    }
    // Playing again: any dismissal is over. Paused: start the auto-hide
    // countdown. Gone entirely: reset for the next session.
    if (playing || now == null) {
      _dismissed = false;
      _pausedHide?.cancel();
      _pausedHide = null;
    } else {
      _pausedHide ??= Timer(
        Duration(
          minutes: c.settings.get(defs.sendspinPausedHideMinutes).toInt(),
        ),
        () {
          if (mounted) setState(() => _dismissed = true);
        },
      );
    }
    if (mounted) setState(() {});
  }

  /// The large card's transport row. Buttons appear only for commands the
  /// server advertises; play/pause swaps on state. All act on the group.
  Widget _controls(Map<String, Object?> now, bool playing, ColorScheme scheme) {
    final supported =
        (now['supportedCommands'] as List?)?.map((e) => '$e').toList() ??
        const <String>[];
    bool has(String cmd) => supported.isEmpty || supported.contains(cmd);
    Widget btn(IconData icon, String command, {double size = 26}) => IconButton(
      icon: Icon(icon, size: size),
      color: scheme.onSurface,
      visualDensity: VisualDensity.compact,
      onPressed: () => c.sendspin.control(command),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (has('previous')) btn(Icons.skip_previous, 'previous'),
        if (has(playing ? 'pause' : 'play'))
          btn(
            playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
            playing ? 'pause' : 'play',
            size: 36,
          ),
        if (has('next')) btn(Icons.skip_next, 'next'),
      ],
    );
  }

  String _clock(int ms) {
    final s = (ms / 1000).round();
    final m = s ~/ 60;
    return '$m:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final now = c.sendspin.nowPlaying.value;
    // Hidden during voice interactions: Voice Satellite's own UI owns the
    // screen for the duration, and the card would sit on top of it.
    if (now == null ||
        _dismissed ||
        c.sendspin.voiceActive.value ||
        !c.settings.get(defs.sendspinShowPlayer)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = '${now['title'] ?? 'Playing'}';
    final artist = [now['artist'], now['album']]
        .where((v) => v != null && '$v'.isNotEmpty)
        .join(' — ')
        .replaceAll(' — ', ' · ');
    final playing = now['playing'] == true;

    // Live position: last reported position plus wall time since it was
    // reported, frozen while paused, clamped to the track.
    final duration = (now['durationMs'] as num?)?.toInt() ?? 0;
    var position = (now['positionMs'] as num?)?.toInt() ?? 0;
    final receivedAt = (now['receivedAt'] as num?)?.toInt();
    if (playing && receivedAt != null) {
      position += DateTime.now().millisecondsSinceEpoch - receivedAt;
    }
    if (duration > 0) position = position.clamp(0, duration);

    return LayoutBuilder(
      builder: (context, constraints) {
        final freeW = (constraints.maxWidth - _cardWidth).clamp(0.0, 1e6);
        final freeH = (constraints.maxHeight - _cardHeight).clamp(0.0, 1e6);
        return Stack(
          children: [
            Positioned(
              left: _fx * freeW,
              top: _fy * freeH,
              child: GestureDetector(
                onPanUpdate: (d) => setState(() {
                  if (freeW > 0) {
                    _fx = (_fx + d.delta.dx / freeW).clamp(0.0, 1.0);
                  }
                  if (freeH > 0) {
                    _fy = (_fy + d.delta.dy / freeH).clamp(0.0, 1.0);
                  }
                }),
                onPanEnd: (_) => c.settings.set(
                  defs.sendspinPlayerPos,
                  '${_fx.toStringAsFixed(3)},${_fy.toStringAsFixed(3)}',
                ),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: scheme.surface.withValues(alpha: 0.96),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: _cardWidth,
                    height: _cardHeight,
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: _artSize,
                                  height: _artSize,
                                  child: _artBytes == null
                                      ? ColoredBox(
                                          color: scheme.surfaceContainerHighest,
                                          child: Icon(
                                            Icons.music_note,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        )
                                      : Image.memory(
                                          _artBytes!,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                          errorBuilder: (_, _, _) => ColoredBox(
                                            color:
                                                scheme.surfaceContainerHighest,
                                            child: Icon(
                                              Icons.music_note,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  12,
                                  14,
                                  10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _Marquee(
                                            text: title,
                                            // The large card earns
                                            // larger type; compact
                                            // keeps its fit.
                                            style: _large
                                                ? theme.textTheme.titleLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      )
                                                : theme.textTheme.titleSmall,
                                          ),
                                        ),
                                        // A constant-size badge slot:
                                        // the equalizer while playing,
                                        // empty while paused, so the
                                        // marquee width never changes
                                        // with the state.
                                        SizedBox(
                                          width: _large ? 24.0 : 20.0,
                                          child: playing
                                              ? Icon(
                                                  Icons.graphic_eq,
                                                  size: _large ? 20 : 16,
                                                  color: scheme.primary,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                    if (artist.isNotEmpty)
                                      _Marquee(
                                        text: artist,
                                        style:
                                            (_large
                                                    ? theme.textTheme.bodyMedium
                                                    : theme.textTheme.bodySmall)
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                      ),
                                    const Spacer(),
                                    // Large size: transport buttons for the
                                    // whole playback group (controller role),
                                    // shown only when the server accepts them.
                                    if (_large) _controls(now, playing, scheme),
                                    if (duration > 0) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: (position / duration).clamp(
                                            0.0,
                                            1.0,
                                          ),
                                          minHeight: 3,
                                          backgroundColor:
                                              scheme.surfaceContainerHighest,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _clock(position),
                                            style:
                                                (_large
                                                        ? theme
                                                              .textTheme
                                                              .labelMedium
                                                        : theme
                                                              .textTheme
                                                              .labelSmall)
                                                    ?.copyWith(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                    ),
                                          ),
                                          Text(
                                            _clock(duration),
                                            style:
                                                (_large
                                                        ? theme
                                                              .textTheme
                                                              .labelMedium
                                                        : theme
                                                              .textTheme
                                                              .labelSmall)
                                                    ?.copyWith(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                    ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Paused: the close button floats over the card's
                        // top-right corner. An overlay, not a layout
                        // participant, so nothing shifts when it comes
                        // and goes.
                        if (!playing)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: scheme.surfaceContainerHighest,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => setState(() => _dismissed = true),
                                child: SizedBox(
                                  width: _large ? 44.0 : 38.0,
                                  height: _large ? 44.0 : 38.0,
                                  child: Icon(
                                    Icons.close,
                                    size: _large ? 24 : 20,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
