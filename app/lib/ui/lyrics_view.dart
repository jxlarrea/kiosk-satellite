import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/sendspin/lyrics.dart';

/// The playing track's lyrics, the current line lit and the rest receding,
/// scrolling itself so the current line stays put (issue #43).
///
/// The position it follows is Sendspin's, extrapolated from the last update
/// the same way the progress bar does it. That position is server-synced —
/// the whole player exists to keep audio aligned to it — so the highlight
/// tracks what is actually coming out of the speaker rather than what a
/// media_player entity last reported.
class LyricsView extends StatefulWidget {
  const LyricsView({
    super.key,
    required this.container,
    required this.fontSize,
  });

  final AppContainer container;

  /// The current line's size; the others are drawn slightly smaller.
  final double fontSize;

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  static const _lineKeyPrefix = 'lyric-';

  final _scroll = ScrollController();
  Timer? _tick;
  int _index = -1;

  @override
  void initState() {
    super.initState();
    widget.container.sendspin.lyrics.addListener(_onLyricsChanged);
    // Four times a second: a line change lands within a quarter of a second
    // of the voice, which reads as immediate, and it is four rebuilds of a
    // handful of text lines.
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) => _sync());
    _sync();
  }

  @override
  void dispose() {
    widget.container.sendspin.lyrics.removeListener(_onLyricsChanged);
    _tick?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onLyricsChanged() {
    _index = -1;
    if (mounted) setState(() {});
    _sync();
  }

  /// Where the track is now, from the last reported position plus the wall
  /// time since it was reported. Mirrors the floating player's progress.
  Duration _position() {
    final now = widget.container.sendspin.nowPlaying.value;
    if (now == null) return Duration.zero;
    var ms = (now['positionMs'] as num?)?.toInt() ?? 0;
    final receivedAt = (now['receivedAt'] as num?)?.toInt();
    if (now['playing'] == true && receivedAt != null) {
      ms += DateTime.now().millisecondsSinceEpoch - receivedAt;
    }
    return Duration(milliseconds: ms < 0 ? 0 : ms);
  }

  void _sync() {
    final lines = widget.container.sendspin.lyrics.value;
    if (lines.isEmpty) return;
    final next = currentLyricIndex(lines, _position());
    if (next == _index) return;
    setState(() => _index = next);
    _scrollToCurrent();
  }

  void _scrollToCurrent() {
    if (_index < 0) return;
    final context = _lineContexts[_index]?.currentContext;
    if (context == null) return;
    // Centre the current line in the view rather than scrolling it to an
    // edge: on a wall panel the eye is already in the middle.
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  final _lineContexts = <int, GlobalKey>{};

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<LyricLine>>(
      valueListenable: widget.container.sendspin.lyrics,
      builder: (context, lines, _) {
        if (lines.isEmpty) return const SizedBox.shrink();
        return ShaderMask(
          // Fade both ends so lines arrive and leave rather than being cut
          // off against the panel edge.
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0.0, 0.18, 0.82, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            controller: _scroll,
            // No dragging: this is a screensaver, and a lyric scrolled by a
            // passing hand would never find its way back.
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 90),
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final key = _lineContexts.putIfAbsent(
                index,
                () => GlobalKey(debugLabel: '$_lineKeyPrefix$index'),
              );
              final current = index == _index;
              return Padding(
                key: key,
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    color: current ? Colors.white : Colors.white38,
                    fontSize: current
                        ? widget.fontSize
                        : widget.fontSize * 0.88,
                    fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                    height: 1.3,
                  ),
                  child: Text(lines[index].text, textAlign: TextAlign.left),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
