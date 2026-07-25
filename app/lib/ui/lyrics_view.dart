import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/sendspin/lyrics.dart';
import '../managers/settings/definitions.dart' as defs;

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
    this.centred = false,
  });

  final AppContainer container;

  /// The current line's size; the others are drawn slightly smaller.
  final double fontSize;

  /// Centre the lines rather than ranging them left. Beside the cover they
  /// read as a column of text and want a left edge; stacked underneath a
  /// centred cover they want to share its axis.
  final bool centred;

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
    // Ten times a second. At four the line could land a quarter second late
    // on its own, which is enough to read as lagging the voice; the work is
    // an integer comparison and a rebuild only when the line actually
    // changes.
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) => _sync());
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
    _lineContexts.clear();
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
    // The user's nudge. Positive runs the lyrics ahead of the music, which
    // is what a reader wants: the line has to be read before it is sung,
    // and LRC timestamps mark where a line STARTS being sung.
    final offset =
        widget.container.settings.get(defs.sendspinLyricsOffset).toDouble();
    ms += (offset * 1000).round();
    return Duration(milliseconds: ms < 0 ? 0 : ms);
  }

  void _sync() {
    final lines = widget.container.sendspin.lyrics.value;
    if (lines.isEmpty) return;
    final next = currentLyricIndex(lines, _position());
    if (next == _index) return;
    // A jump of more than a line is not the song advancing: it is a track
    // joined mid-way, a seek, or the lyrics arriving late. Land there
    // rather than scrolling the whole way through the song.
    final jumped = (next - _index).abs() > 1;
    setState(() => _index = next);
    _scrollToCurrent(animate: !jumped);
  }

  void _scrollToCurrent({required bool animate}) {
    if (_index < 0) return;
    // After the frame: a line that has just become current may not have
    // been laid out yet, and its context would not exist to scroll to.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _lineContexts[_index]?.currentContext;
      if (context == null) return;
      // Centre the current line in the view rather than scrolling it to an
      // edge: on a wall panel the eye is already in the middle.
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: animate
            ? const Duration(milliseconds: 450)
            : Duration.zero,
        curve: Curves.easeOutCubic,
      );
    });
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
          // Every line is built, not just the visible ones. A lazy list only
          // creates what is on screen, so the key of a line further down
          // resolves to nothing and there is no context to scroll to — which
          // left a track joined mid-way sitting on its first verse forever,
          // highlighting a line nobody could see. A song is a few dozen
          // short Text widgets; building them all costs nothing.
          child: SingleChildScrollView(
            controller: _scroll,
            // No dragging: this is a screensaver, and a lyric scrolled by a
            // passing hand would never find its way back.
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 90),
            child: Column(
              crossAxisAlignment: widget.centred
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (index, line) in lines.indexed)
                  Padding(
                    key: _lineContexts.putIfAbsent(
                      index,
                      () => GlobalKey(debugLabel: '$_lineKeyPrefix$index'),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        color: index == _index
                            ? Colors.white
                            : Colors.white38,
                        fontSize: index == _index
                            ? widget.fontSize
                            : widget.fontSize * 0.88,
                        fontWeight: index == _index
                            ? FontWeight.w700
                            : FontWeight.w500,
                        height: 1.3,
                      ),
                      child: Text(
                        line.text,
                        textAlign:
                            widget.centred ? TextAlign.center : TextAlign.left,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
