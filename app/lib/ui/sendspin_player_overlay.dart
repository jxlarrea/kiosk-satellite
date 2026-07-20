import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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

class SendspinPlayerOverlay extends StatefulWidget {
  const SendspinPlayerOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  State<SendspinPlayerOverlay> createState() => _SendspinPlayerOverlayState();
}

class _SendspinPlayerOverlayState extends State<SendspinPlayerOverlay> {
  static const _cardWidth = 320.0;
  static const _cardHeight = 96.0;

  AppContainer get c => widget.container;

  /// Position as fractions of the free area (screen minus card), 0..1.
  late double _fx, _fy;

  /// Ticks the progress bar between metadata pushes.
  Timer? _tick;

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
    if (url.isEmpty) {
      if (mounted) setState(() => _artBytes = null);
      return;
    }
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
      if (mounted && _artUrl == url && response.statusCode == 200) {
        setState(() => _artBytes = Uint8List.fromList(bytes));
      }
    } catch (_) {
      if (mounted && _artUrl == url) setState(() => _artBytes = null);
    }
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
    _onNowPlaying();
  }

  @override
  void dispose() {
    c.sendspin.nowPlaying.removeListener(_onNowPlaying);
    _tick?.cancel();
    super.dispose();
  }

  void _onNowPlaying() {
    final artwork = '${c.sendspin.nowPlaying.value?['artworkUrl'] ?? ''}';
    if (artwork != _artUrl) _loadArtwork(artwork);
    final playing = c.sendspin.nowPlaying.value?['playing'] == true;
    if (playing && _tick == null) {
      _tick = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    } else if (!playing) {
      _tick?.cancel();
      _tick = null;
    }
    if (mounted) setState(() {});
  }

  String _clock(int ms) {
    final s = (ms / 1000).round();
    final m = s ~/ 60;
    return '$m:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final now = c.sendspin.nowPlaying.value;
    if (now == null || !c.settings.get(defs.sendspinShowPlayer)) {
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
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 72,
                              height: 72,
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
                                        color: scheme.surfaceContainerHighest,
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
                            padding: const EdgeInsets.fromLTRB(0, 12, 14, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _Marquee(
                                        text: title,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                    ),
                                    Icon(
                                      playing
                                          ? Icons.graphic_eq
                                          : Icons.pause_circle_outline,
                                      size: 16,
                                      color: scheme.primary,
                                    ),
                                  ],
                                ),
                                if (artist.isNotEmpty)
                                  _Marquee(
                                    text: artist,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                const Spacer(),
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
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                      Text(
                                        _clock(duration),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
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
