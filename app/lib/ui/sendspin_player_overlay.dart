import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:intl/intl.dart' show NumberFormat;
import 'glance_row.dart';
import 'lyrics_view.dart';
import 'theme.dart';
import 'thumb_cache.dart';

import '../app_container.dart';
import '../l10n/messages.dart';
import '../core/events.dart';
import '../managers/sendspin/audiobook_chapters.dart';
import '../managers/sendspin/remote_player.dart';
import '../managers/settings/definitions.dart' as defs;

String _transportLabel(BuildContext context, String command) =>
    switch (command) {
      'previous' => l10n(context).mediaPreviousTrack,
      'next' => l10n(context).mediaNextTrack,
      'pause' => l10n(context).mediaPause,
      _ => l10n(context).mediaPlay,
    };

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
///
/// Timed, not animated: a ticker asks for every frame, the hold included,
/// and over the dashboard each frame is costly (the platform view puts
/// Flutter on its image view path). The text moves one physical pixel at
/// a time, which at its speed is a few dozen frames a second, and nothing
/// is drawn while it holds. It stops where tickers are muted.
class _Marquee extends StatefulWidget {
  const _Marquee({required this.text, this.style});

  final String text;
  final TextStyle? style;

  static const gap = 48.0;
  static const pxPerSecond = 24.0;
  static const hold = Duration(seconds: 2);

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> {
  /// How far the text has moved, in logical pixels.
  final _offset = ValueNotifier<double>(0);

  /// One copy and the gap: past this the loop starts over. Zero while the
  /// text fits.
  double _distance = 0;

  /// One physical pixel, in logical pixels.
  double _pixel = 1;

  Timer? _timer;
  ValueListenable<TickerModeData>? _tickerMode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pixel = 1 / MediaQuery.devicePixelRatioOf(context);
    final mode = TickerMode.getValuesNotifier(context);
    if (mode != _tickerMode) {
      _tickerMode?.removeListener(_restart);
      _tickerMode = mode..addListener(_restart);
      _restart();
    }
  }

  @override
  void didUpdateWidget(_Marquee old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tickerMode?.removeListener(_restart);
    _offset.dispose();
    super.dispose();
  }

  /// Back to the start and its hold, or still while muted or fitting.
  void _restart() {
    _timer?.cancel();
    _timer = null;
    _offset.value = 0;
    if (_distance <= 0 || !(_tickerMode?.value.enabled ?? true)) return;
    _timer = Timer(_Marquee.hold, _scroll);
  }

  /// A pixel a tick. The tick count includes the ticks a busy moment
  /// missed, so the speed holds.
  void _scroll() {
    final step = Duration(
      microseconds: (1e6 * _pixel / _Marquee.pxPerSecond).round(),
    );
    _timer = Timer.periodic(step, (timer) {
      final moved = timer.tick * _pixel;
      if (moved >= _distance) {
        _restart();
        return;
      }
      _offset.value = moved;
    });
  }

  /// The text's width changed what the loop covers: start it over, after
  /// the layout that measured it.
  void _measure(double distance) {
    if (distance == _distance) return;
    _distance = distance;
    scheduleMicrotask(() {
      if (mounted) _restart();
    });
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
        final height = painter.height;
        painter.dispose();
        if (textWidth <= constraints.maxWidth) {
          _measure(0);
          return Text(widget.text, maxLines: 1, style: widget.style);
        }
        // Scroll one full copy plus the gap, so the second copy lands where
        // the first began and the loop is seamless.
        _measure(textWidth + _Marquee.gap);
        // Fixed box of exactly one text line: OverflowBox has no size of its
        // own and would otherwise absorb all the height the column offers,
        // pushing the rest of the card out of view.
        return SizedBox(
          height: height,
          width: constraints.maxWidth,
          child: ClipRect(
            child: ValueListenableBuilder<double>(
              valueListenable: _offset,
              builder: (context, offset, row) =>
                  Transform.translate(offset: Offset(-offset, 0), child: row),
              child: OverflowBox(
                maxWidth: double.infinity,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.text, maxLines: 1, style: widget.style),
                    const SizedBox(width: _Marquee.gap),
                    Text(widget.text, maxLines: 1, style: widget.style),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Minutes and seconds of a millisecond count, "3:07".
String _clock(int ms) {
  final s = (ms / 1000).round();
  final m = s ~/ 60;
  return '$m:${(s % 60).toString().padLeft(2, '0')}';
}

/// The full-screen now-playing view that stands in for the screensaver
/// while music plays (sendspin.fullscreen): album art as a blurred, dimmed
/// backdrop, the art again as a centered panel, and large title/artist
/// text. Without its media controls it behaves exactly like a screensaver
/// and the host wraps it in the same tap-to-dismiss surface; with them
/// (sendspin.fullscreen_controls, the default) the screensaver manager
/// holds the touch reports, the transport sits pinned along the bottom of
/// the screen and a close button in the corner is the way out. Lyrics or
/// the queue take the space beside (landscape) or under (portrait) the
/// cover. Optional Horizontal mode gives artwork half the display and
/// moves details beneath it while the transport moves down for a panel.
class SendspinFullscreenView extends StatefulWidget {
  const SendspinFullscreenView({
    super.key,
    required this.container,
    this.alongsideScreensaver = false,
  });

  final AppContainer container;

  /// The host supplies a panel-sized MediaQuery while sharing the display.
  final bool alongsideScreensaver;

  @override
  State<SendspinFullscreenView> createState() => _SendspinFullscreenViewState();
}

class _SendspinFullscreenViewState extends State<SendspinFullscreenView> {
  AppContainer get c => widget.container;

  Uint8List? _artBytes;
  String _artUrl = '';
  String _loadedArtUrl = '';
  Object? _presentation;

  /// Whether the last build showed a panel beside or under the cover:
  /// with lyrics on and their lookup still out, the layout holds rather
  /// than dropping to the plain look and back for the beat it takes.
  bool _panelShown = false;

  /// The lyrics and queue settings decide the layout, so a flip from the
  /// view's own buttons or either settings surface rebuilds it.
  StreamSubscription<SettingChanged>? _settingsSub;

  @override
  void initState() {
    super.initState();
    c.sendspin.nowPlaying.addListener(_onNowPlaying);
    c.sendspin.lyrics.addListener(_onLayoutChanged);
    c.sendspin.lyricsPending.addListener(_onLayoutChanged);
    _settingsSub = c.bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.sendspinLyrics.key ||
          e.key == defs.sendspinFullscreenQueue.key ||
          e.key == defs.sendspinSpeakerPill.key ||
          e.key == defs.sendspinAudioQuality.key ||
          e.key == defs.sendspinFullscreenTextScale.key ||
          e.key == defs.sendspinFullscreenButtonScale.key ||
          e.key == defs.sendspinFullscreenLayout.key ||
          e.key == defs.sendspinFullscreenDoubleTap.key ||
          e.key == defs.sendspinFullscreenCloseButton.key) {
        _onLayoutChanged();
      }
    });
    // The entity list going from empty to populated (or back) changes the
    // whole layout, not just the row, so the view rebuilds with it.
    c.glance.entities.addListener(_onLayoutChanged);
    _onNowPlaying();
  }

  @override
  void dispose() {
    c.sendspin.nowPlaying.removeListener(_onNowPlaying);
    c.sendspin.lyrics.removeListener(_onLayoutChanged);
    c.sendspin.lyricsPending.removeListener(_onLayoutChanged);
    c.glance.entities.removeListener(_onLayoutChanged);
    _settingsSub?.cancel();
    super.dispose();
  }

  void _onNowPlaying() {
    final now = c.sendspin.nowPlaying.value;
    final url = '${now?['artworkUrl'] ?? ''}';
    if (url != _artUrl) {
      _artUrl = url;
      _fetchArt(url);
    }
    final presentation = (
      now?['title'],
      now?['artist'],
      now?['album'],
      url,
      c.sendspin.playerChipName,
      c.sendspin.queueOpen,
      '${now?['audioQuality'] ?? ''}',
    );
    if (presentation == _presentation) return;
    _presentation = presentation;
    _onLayoutChanged();
  }

  void _onLayoutChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchArt(String url) async {
    final bytes = await fetchSendspinArtwork(c, url);
    if (mounted && url == _artUrl) {
      setState(() {
        _artBytes = bytes;
        _loadedArtUrl = url;
      });
    }
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
    // Start with panel-sized defaults, then apply the independent scales.
    // Artwork gives up space before text needs to shrink.
    final screen = MediaQuery.sizeOf(context);
    final short = screen.shortestSide;
    final artSize = (short * 0.52).clamp(120.0, 360.0);
    final textScale =
        c.settings.get(defs.sendspinFullscreenTextScale).toDouble() / 100;
    final titleSize = (short * 0.085).clamp(20.0, 40.0) * textScale;
    final artistSize = (short * 0.047).clamp(13.0, 22.0) * textScale;
    final gap = (screen.height * 0.05).clamp(12.0, 40.0);
    final controls = c.settings.get(defs.sendspinFullscreenControls);
    // Sharing the screen should not shrink the base touch targets just
    // because the player pane is narrow. Controls still fit their slot.
    final baseControlsScale = widget.alongsideScreensaver
        ? 1.0
        : (short / 800).clamp(0.7, 1.0);
    final controlsScale =
        baseControlsScale *
        c.settings.get(defs.sendspinFullscreenButtonScale).toDouble() /
        100;
    // Double tap to dismiss (issue #409) replaces the close button unless
    // it is kept on (issue #1203): the manager runs the tap chain on
    // touches off the controls.
    final doubleTap =
        controls && c.settings.get(defs.sendspinFullscreenDoubleTap);
    final showClose =
        controls &&
        (!doubleTap || c.settings.get(defs.sendspinFullscreenCloseButton)) &&
        !widget.alongsideScreensaver;
    final showPlayerChip =
        c.settings.get(defs.sendspinSpeakerPill) &&
        c.sendspin.playerChipName.isNotEmpty;
    // The way into the music library, beside the close button.
    final showLibrary =
        controls &&
        !widget.alongsideScreensaver &&
        c.settings.get(defs.libraryNowPlayingButton) &&
        c.settings.get(defs.kioskAllowMusicLibrary) &&
        c.musicLibrary.available.isNotEmpty;
    // The queue panel (controls only: its button lives there) and the
    // lyrics share one slot, the queue winning while it is open. Either
    // takes whatever spare axis the panel has: a second column on a
    // landscape screen, the space under the cover on a portrait one. A
    // panel too small for either keeps the plain now-playing look rather
    // than squeezing two lines into a corner.
    final queue = controls && c.sendspin.queueOpen;
    final lyricsOn = !queue && c.settings.get(defs.sendspinLyrics);
    final haveLyrics =
        lyricsOn &&
        (c.sendspin.lyrics.value.isNotEmpty ||
            (c.sendspin.lyricsPending.value && _panelShown));
    final havePanel = queue || haveLyrics;
    final layout = widget.alongsideScreensaver
        ? 'vertical'
        : c.settings.get(defs.sendspinFullscreenLayout);
    final horizontal = layout == 'horizontal';
    // The cover alone, the details and transport over it only after a
    // touch, which leaves nowhere for lyrics or the queue: those open in
    // the vertical layouts.
    final artOnly = layout == 'art_only' && !havePanel;
    final landscape = screen.width > screen.height;
    final sideBySide = havePanel && landscape && screen.width >= 560;
    final stacked = havePanel && !landscape && screen.height >= 620;
    final panelOnly =
        havePanel && widget.alongsideScreensaver && !sideBySide && !stacked;
    // The At a Glance row joins the plain layout only (issue #209): the
    // panel layouts already spend every free pixel on the words.
    final glance =
        !widget.alongsideScreensaver &&
        !sideBySide &&
        !stacked &&
        c.settings.get(defs.screensaverGlanceNowPlaying) &&
        c.glance.entities.value.isNotEmpty;
    final edge = (screen.width * 0.06).clamp(16.0, 64.0);
    final quality = c.settings.get(defs.sendspinAudioQuality)
        ? audioQualityLabels(context, now?['audioQuality'])
        : const <String>[];
    _panelShown =
        sideBySide || stacked || panelOnly || (horizontal && havePanel);

    // On a Material of its own: the rows are ink wells, and their focus
    // highlight only paints on one.
    Widget panel() => queue
        ? _ControlTouch(
            container: c,
            child: Material(
              type: MaterialType.transparency,
              child: _QueueView(
                container: c,
                fontSize: (short * 0.035).clamp(14.0, 21.0) * textScale,
              ),
            ),
          )
        : LyricsView(
            container: c,
            fontSize: (short * 0.055).clamp(15.0, 26.0) * textScale,
            centred: stacked && !horizontal,
          );

    // Title, artist and album on lines of their own, for the layouts with
    // room for all three.
    Widget trackDetails(Key key, {List<Shadow>? shadows}) => Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            height: 1.15,
            shadows: shadows,
          ),
        ),
        for (final value in [now?['artist'], now?['album']])
          if (value != null && '$value'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$value',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                // Gray loses to a busy cover, so text over one stays white.
                style: TextStyle(
                  color: shadows == null ? Colors.white70 : Colors.white,
                  fontSize: artistSize,
                  shadows: shadows,
                ),
              ),
            ),
      ],
    );

    Widget horizontalContent() {
      Widget details() =>
          trackDetails(const ValueKey('horizontal-track-details'));

      final horizontalPadding = (screen.width * 0.04).clamp(32.0, 48.0);
      // Only the close button needs clearance. The speaker pill floats
      // over the content, artwork included, briefly after interaction.
      final verticalPadding = showClose ? 64.0 : 24.0;
      Widget half(String key, Widget child, {bool centered = true}) => Expanded(
        child: SizedBox.expand(
          key: ValueKey(key),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              verticalPadding + MediaQuery.paddingOf(context).top,
              horizontalPadding,
              (centered ? verticalPadding : 24) +
                  MediaQuery.paddingOf(context).bottom,
            ),
            child: child,
          ),
        ),
      );

      return Row(
        children: [
          half(
            'horizontal-artwork-half',
            LayoutBuilder(
              builder: (context, box) {
                final detailsHeight = havePanel
                    ? titleSize * 2.3 + artistSize * 2.8 + 16 + gap * 0.5
                    : 0.0;
                final coverSize = min(
                  box.maxWidth,
                  max(48.0, box.maxHeight - detailsHeight),
                );
                return Center(
                  child: _fitted(
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          key: const ValueKey('horizontal-cover'),
                          dimension: coverSize,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 700),
                            child: art == null
                                ? const Center(
                                    key: ValueKey('horizontal-no-art'),
                                    child: Icon(
                                      Icons.music_note,
                                      size: 96,
                                      color: Colors.white24,
                                    ),
                                  )
                                : ClipRRect(
                                    key: ValueKey(_loadedArtUrl),
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.memory(
                                      art,
                                      width: double.infinity,
                                      height: double.infinity,
                                      cacheWidth:
                                          (coverSize *
                                                  MediaQuery.devicePixelRatioOf(
                                                    context,
                                                  ))
                                              .ceil(),
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                          ),
                        ),
                        if (havePanel) ...[
                          SizedBox(height: gap * 0.5),
                          details(),
                        ],
                      ],
                    ),
                    width: box.maxWidth,
                  ),
                );
              },
            ),
          ),
          half(
            'horizontal-controls-half',
            LayoutBuilder(
              builder: (context, box) {
                Widget transport() => _ControlTouch(
                  container: c,
                  child: _NowPlayingControls(
                    container: c,
                    width: box.maxWidth,
                    scale: controlsScale,
                    maxHeight: box.maxHeight * (havePanel ? 0.6 : 0.65),
                  ),
                );
                if (havePanel) {
                  return Column(
                    children: [
                      Expanded(child: panel()),
                      if (controls) ...[
                        SizedBox(height: gap * 0.5),
                        transport(),
                      ],
                    ],
                  );
                }
                return Center(
                  child: _fitted(
                    Column(
                      key: const ValueKey('horizontal-track-controls'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        details(),
                        if (controls) ...[SizedBox(height: gap), transport()],
                        if (glance)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: GlanceRow(
                              container: c,
                              scale: (short / 800).clamp(0.7, 1.0),
                            ),
                          ),
                      ],
                    ),
                    width: box.maxWidth,
                  ),
                );
              },
            ),
            centered: !havePanel,
          ),
        ],
      );
    }

    // The cover as large as the screen allows, centered, and nothing
    // else until a touch or a key: then the view dims and the track
    // details and transport come up for a few seconds, the transport
    // docked to the bottom of the screen, the way a video player shows
    // its controls. On a portrait screen they reach below the cover.
    Widget artOnlyContent() {
      final safe = MediaQuery.paddingOf(context);
      final sidePadding = (screen.width * 0.04).clamp(24.0, 48.0);
      final inset = (short * 0.04).clamp(16.0, 32.0);
      // The close button comes and goes with the controls, so the cover
      // needs no room kept for it.
      final padding = EdgeInsets.fromLTRB(
        sidePadding + safe.left,
        24 + safe.top,
        sidePadding + safe.right,
        24 + safe.bottom,
      );
      return LayoutBuilder(
        builder: (context, full) {
          final area = padding.deflateRect(Offset.zero & full.biggest);
          final coverSize = max(0.0, min(area.width, area.height));
          final cover = Rect.fromCenter(
            center: area.center,
            width: coverSize,
            height: coverSize,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fromRect(
                rect: cover,
                child: AnimatedSwitcher(
                  key: const ValueKey('art-only-cover'),
                  duration: const Duration(milliseconds: 700),
                  child: art == null
                      ? const Center(
                          key: ValueKey('art-only-no-art'),
                          child: Icon(
                            Icons.music_note,
                            size: 96,
                            color: Colors.white24,
                          ),
                        )
                      : ClipRRect(
                          key: ValueKey(_loadedArtUrl),
                          borderRadius: BorderRadius.circular(24),
                          child: Image.memory(
                            art,
                            width: double.infinity,
                            height: double.infinity,
                            cacheWidth:
                                (coverSize *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .ceil(),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                ),
              ),
              _TransientOnActivity(
                container: c,
                visibilityKey: const ValueKey('art-only-controls-visibility'),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Color(0x99000000)),
                    // As wide as the cover, as tall as the screen allows.
                    // Half the inset below: the transport already keeps a
                    // margin under its buttons.
                    Positioned(
                      left: cover.left,
                      width: coverSize,
                      top: area.top,
                      bottom: full.maxHeight - area.bottom,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          inset,
                          inset,
                          inset,
                          inset / 2,
                        ),
                        child: LayoutBuilder(
                          builder: (context, inner) => Align(
                            alignment: Alignment.bottomCenter,
                            child: _fitted(
                              Column(
                                key: const ValueKey('art-only-track-controls'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (glance)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: GlanceRow(
                                        container: c,
                                        scale: (short / 800).clamp(0.7, 1.0),
                                      ),
                                    ),
                                  trackDetails(
                                    const ValueKey('art-only-track-details'),
                                    shadows: _overArtShadows,
                                  ),
                                  if (controls) ...[
                                    SizedBox(height: gap * 0.5),
                                    _ControlTouch(
                                      container: c,
                                      child: _NowPlayingControls(
                                        container: c,
                                        width: inner.maxWidth,
                                        scale: controlsScale,
                                        // Sized to the cover, not the
                                        // column a portrait screen leaves.
                                        maxHeight:
                                            min(inner.maxHeight, coverSize) *
                                            0.5,
                                        shadows: _overArtShadows,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              width: inner.maxWidth,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    Widget content() {
      if (panelOnly) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, showClose ? 64 : 12, 16, 0),
          child: panel(),
        );
      } else if (sideBySide) {
        // Art and words to one side, the panel to the other: a lyric needs
        // the height, and stacking it under a 360px cover leaves room for
        // about two lines.
        return Padding(
          padding: EdgeInsets.fromLTRB(edge, 12, edge, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: _fitTrack(
                  _trackPanel(
                    art: art,
                    title: title,
                    artist: artist,
                    artSize: artSize * 0.85,
                    titleSize: titleSize * 0.75,
                    artistSize: artistSize * 0.85,
                    gap: gap * 0.5,
                    horizontalPadding: 8,
                  ),
                  width: artSize * 0.85 * 1.5 * max(1.0, textScale),
                ),
              ),
              SizedBox(width: (screen.width * 0.04).clamp(12.0, 48.0)),
              Expanded(flex: 6, child: panel()),
            ],
          ),
        );
      } else if (stacked) {
        // Portrait: cover and track up top, the panel filling everything
        // below them. Left as the plain centred view, a tall panel spends
        // its whole lower half on nothing.
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            (screen.height * 0.05).clamp(12.0, 48.0),
            20,
            0,
          ),
          child: LayoutBuilder(
            builder: (context, box) => Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: box.maxHeight * 0.5),
                  child: _fitTrack(
                    _trackPanel(
                      art: art,
                      title: title,
                      artist: artist,
                      artSize: artSize * 0.66,
                      titleSize: titleSize * 0.8,
                      artistSize: artistSize * 0.9,
                      gap: gap * 0.6,
                      horizontalPadding: 12,
                    ),
                    width: screen.width - 40,
                  ),
                ),
                SizedBox(height: (screen.height * 0.03).clamp(10.0, 32.0)),
                Expanded(child: panel()),
              ],
            ),
          ),
        );
      } else {
        // A portrait screen with no lyrics or queue under the cover gives
        // it the full width, the height left after the track details
        // capping it on a short screen.
        final portraitCover = !landscape && !widget.alongsideScreensaver;
        final coverWidth = screen.width - edge * 2;
        return Center(
          child: _fitTrack(
            _trackPanel(
              art: art,
              title: title,
              artist: artist,
              artSize: portraitCover ? coverWidth : artSize,
              titleSize: titleSize,
              artistSize: artistSize,
              gap: gap,
              horizontalPadding: 0,
            ),
            width: portraitCover
                ? coverWidth
                : min(
                    screen.width - (widget.alongsideScreensaver ? 32 : 96),
                    artSize * 2.2 * max(1.0, textScale),
                  ),
          ),
        );
      }
    }

    // The content above, the row and the transport pinned below it:
    // the transport keeps its place whatever the content does.
    Widget verticalContent() => Column(
      children: [
        Expanded(child: content()),
        if (glance)
          Padding(
            padding: EdgeInsets.only(
              top: 8,
              bottom: controls ? 4 : (screen.height * 0.06).clamp(12.0, 48.0),
            ),
            // The default cards carry their own backdrop, and the
            // text-only style's grey-on-black palette reads over the
            // black backdrop and the scrimmed art alike, so no tint.
            child: GlanceRow(
              container: c,
              scale: min(1.0, screen.height / 480).clamp(0.75, 1.0),
            ),
          ),
        if (controls)
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              gap * 0.4,
              16,
              (screen.height * 0.03).clamp(8.0, 24.0),
            ),
            child: Center(
              child: _ControlTouch(
                container: c,
                child: _NowPlayingControls(
                  container: c,
                  // A wide bar: most of the screen, so the thumb has
                  // room to land and the times can read at a distance.
                  width: min(
                    max(artSize * 1.4, screen.width * 0.62),
                    screen.width - 32,
                  ),
                  scale: controlsScale,
                  maxHeight: screen.height * 0.5,
                ),
              ),
            ),
          ),
      ],
    );

    // The close button joins the controls in coming and going.
    Widget transientInArtOnly(Widget child) =>
        artOnly ? _TransientOnActivity(container: c, child: child) : child;

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        // Cross-fade the backdrop between songs rather than cutting.
        // Scaled to cover the full screen at its own aspect ratio; the
        // overflow is cropped, which under this much blur is invisible.
        Positioned.fill(
          child: RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, box) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 700),
                child: art == null
                    ? const SizedBox.expand(key: ValueKey('no-art'))
                    : _BlurredArt(
                        key: ValueKey(_loadedArtUrl),
                        bytes: art,
                        size: box.biggest,
                      ),
              ),
            ),
          ),
        ),
        // Blur + scrim so the backdrop reads as atmosphere, not content.
        if (art != null) const ColoredBox(color: Color(0x99000000)),
        // The layout above, the audio quality pills along the bottom edge.
        Column(
          children: [
            Expanded(
              child: horizontal
                  ? horizontalContent()
                  : artOnly
                  ? artOnlyContent()
                  : verticalContent(),
            ),
            if (quality.isNotEmpty)
              _AudioQualityPills(
                labels: quality,
                fontSize: (short * 0.024).clamp(11.0, 15.0) * textScale,
              ),
          ],
        ),
        // Whose music this is: the shown player's name in a chip opposite
        // the close button, and the way into its group where the source
        // can put other players in it.
        if (showPlayerChip)
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: _TransientOnActivity(
                container: c,
                visibilityKey: const ValueKey('speaker-pill-visibility'),
                child: _PlayerChip(
                  container: c,
                  maxWidth: max(
                    80,
                    screen.width -
                        (showClose ? 80 : 24) -
                        (showLibrary ? 58 : 0),
                  ),
                  // It follows the text up but never shrinks below its
                  // touch target.
                  scale: max(1.0, textScale),
                ),
              ),
            ),
          ),
        // With the transport up a tap is a button press, so the way out is
        // explicit: the same floating close the page overlays wear. It
        // reports its own source so the manager can tell it from the
        // touches it is holding.
        if (showLibrary)
          Positioned(
            top: 12,
            right: showClose ? 70 : 12,
            child: SafeArea(
              child: transientInArtOnly(
                _ControlTouch(
                  container: c,
                  child: Material(
                    color: Colors.black45,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      focusColor: Colors.white24,
                      onTap: () => unawaited(
                        c.commands.execute('openMusicLibrary', const {}),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.library_music_outlined,
                          color: Colors.white,
                          size: 24,
                          semanticLabel: l10n(context).libraryTitle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (showClose)
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: transientInArtOnly(
                Material(
                  color: Colors.black45,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    focusColor: Colors.white24,
                    onTap: () => c.screensaver.notifyActivity('close'),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                        semanticLabel: l10n(context).commonClose,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The panel at its natural size when its slot allows, scaled down as
  /// one piece when it does not: the cover, the title and the artist
  /// shrink together instead of overflowing on a short screen. [width]
  /// bounds the text so a long title wraps rather than stretching.
  Widget _fitted(Widget panel, {required double width}) => FittedBox(
    fit: BoxFit.scaleDown,
    child: SizedBox(width: width, child: panel),
  );

  Widget _fitTrack(Widget panel, {required double width}) => LayoutBuilder(
    builder: (context, box) =>
        SizedBox(width: min(width, box.maxWidth), child: panel),
  );

  /// The cover, title and artist as one block. Shared by every layout so
  /// a change to the look lands in each: on its own in the middle, or
  /// beside the panel at reduced size.
  Widget _trackPanel({
    required Uint8List? art,
    required String title,
    required String artist,
    required double artSize,
    required double titleSize,
    required double artistSize,
    required double gap,
    required double horizontalPadding,
  }) {
    return LayoutBuilder(
      builder: (context, box) {
        final titleStyle = TextStyle(
          color: Colors.white,
          fontSize: titleSize,
          fontWeight: FontWeight.w700,
          height: 1.15,
        );
        final artistStyle = TextStyle(
          color: Colors.white70,
          fontSize: artistSize,
          fontWeight: FontWeight.w400,
        );
        double textHeight(String text, TextStyle style) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: DefaultTextStyle.of(context).style.merge(style),
            ),
            maxLines: 2,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: max(1, box.maxWidth - horizontalPadding * 2));
          final height = painter.height;
          painter.dispose();
          return height;
        }

        final titleHeight = textHeight(title, titleStyle);
        final artistHeight = artist.isEmpty
            ? 0.0
            : textHeight(artist, artistStyle);
        final spare = max(0.0, box.maxHeight - titleHeight - artistHeight);
        final fittedGap = min(gap, spare * 0.15);
        final artistGap = artist.isEmpty ? 0.0 : min(12.0, spare * 0.1);
        final coverSize = min(
          min(art == null ? artSize * 0.45 : artSize, box.maxWidth),
          max(0.0, spare - fittedGap - artistGap),
        );
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: box.maxWidth,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              child: Column(
                // Keyed on the track so the whole panel (art + text) fades as
                // one between songs.
                key: ValueKey('$title|$_artUrl'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (art != null && coverSize > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.memory(
                        art,
                        cacheWidth:
                            (coverSize * MediaQuery.devicePixelRatioOf(context))
                                .ceil(),
                        width: coverSize,
                        height: coverSize,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    )
                  else if (coverSize > 0)
                    Icon(
                      Icons.music_note,
                      size: coverSize,
                      color: Colors.white24,
                    ),
                  SizedBox(height: fittedGap),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: titleStyle,
                    ),
                  ),
                  if (artist.isNotEmpty) ...[
                    SizedBox(height: artistGap),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Text(
                        artist,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: artistStyle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The Now Playing backdrop: the cover blurred once into a small image and
/// scaled up over the view. Impeller keeps no raster cache, so a live blur
/// filter over the whole screen ran again on every frame anything moved
/// (the seek bar, a lyric scrolling, a docked voice turn on top). Black
/// until the image is ready.
class _BlurredArt extends StatefulWidget {
  const _BlurredArt({super.key, required this.bytes, required this.size});

  final Uint8List bytes;

  /// The box the backdrop covers, which sets how far the blur reaches.
  final Size size;

  /// The blur, in logical pixels of the view.
  static const sigma = 40.0;

  /// The width the cover is decoded and blurred at. A blur this wide
  /// leaves nothing a larger image would show.
  static const width = 160;

  @override
  State<_BlurredArt> createState() => _BlurredArtState();
}

class _BlurredArtState extends State<_BlurredArt> {
  ui.Image? _image;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_render());
  }

  @override
  void didUpdateWidget(_BlurredArt old) {
    super.didUpdateWidget(old);
    if (old.bytes != widget.bytes || old.size != widget.size) {
      unawaited(_render());
    }
  }

  @override
  void dispose() {
    _generation++;
    _image?.dispose();
    super.dispose();
  }

  Future<void> _render() async {
    final generation = ++_generation;
    final size = widget.size;
    if (size.isEmpty || !size.isFinite) return;
    final ui.Image source;
    try {
      final codec = await ui.instantiateImageCodec(
        widget.bytes,
        targetWidth: _BlurredArt.width,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      source = frame.image;
    } catch (_) {
      return;
    }
    if (generation != _generation || !mounted) {
      source.dispose();
      return;
    }
    // The blur in the image's own pixels: the view's sigma over the scale
    // the cover is drawn at.
    final scale = max(size.width / source.width, size.height / source.height);
    final sigma = _BlurredArt.sigma / scale;
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImage(
      source,
      Offset.zero,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.clamp,
        ),
    );
    final picture = recorder.endRecording();
    final blurred = picture.toImageSync(source.width, source.height);
    picture.dispose();
    source.dispose();
    if (generation != _generation || !mounted) {
      blurred.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = blurred;
    });
  }

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: RawImage(
      image: _image,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    ),
  );
}

/// The pills [_AudioQualityPills] shows for a track's audio quality (see
/// audioQualityOf), in order: Hi-Res or CD quality for lossless audio and
/// Lossy for a compressed codec, the codec, the bit depth (for a lossy
/// codec, the depth it decodes to), the sample rate, the bitrate and the
/// source. Empty when the server reported none of it.
List<String> audioQualityLabels(BuildContext context, Object? quality) {
  if (quality is! Map) return const [];
  final strings = l10n(context);
  final number = NumberFormat(
    '0.#',
    Localizations.localeOf(context).toString(),
  );
  final lossless = quality['lossless'] == true;
  final codec = quality['codec'] as String?;
  final sampleRate = quality['sampleRate'] as num?;
  final bitDepth = quality['bitDepth'] as num?;
  final bitRate = quality['bitRate'] as num?;
  final hiRes = (bitDepth ?? 0) > 16 || (sampleRate ?? 0) > 48000;
  final cd =
      (sampleRate == 44100 || sampleRate == 48000) &&
      (bitDepth == null || bitDepth == 16);
  return [
    if (lossless && hiRes)
      strings.mediaAudioHiRes
    else if (lossless && cd)
      strings.mediaAudioCdQuality
    else if (!lossless && codec != null)
      strings.mediaAudioLossy,
    ?codec,
    if (bitDepth != null) strings.mediaAudioBitDepth('$bitDepth'),
    if (sampleRate != null)
      strings.mediaAudioSampleRate(number.format(sampleRate / 1000)),
    if (bitRate != null) strings.mediaAudioBitRate('$bitRate'),
    if (quality['source'] case final String source) source,
  ];
}

/// The audio quality pills along the bottom edge of the Now Playing view
/// (sendspin.audio_quality), centered and wrapping onto a second line on a
/// narrow panel rather than shrinking.
class _AudioQualityPills extends StatelessWidget {
  const _AudioQualityPills({required this.labels, required this.fontSize});

  final List<String> labels;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    return Padding(
      key: const ValueKey('audio-quality-pills'),
      padding: EdgeInsets.fromLTRB(
        16 + safe.left,
        4,
        16 + safe.right,
        12 + safe.bottom,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final label in labels)
            DecoratedBox(
              decoration: ShapeDecoration(
                color: Colors.black38,
                shape: const StadiumBorder(
                  side: BorderSide(color: Colors.white24),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: fontSize * 0.8,
                  vertical: fontSize * 0.3,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Marks a touch as landing on something the Now Playing view acts on
/// (the transport, the toggles, a queue row), for the screensaver
/// manager's double-tap chain to leave alone. A raw pointer listener,
/// deliberately: it hears the pointer on its way down, before the kiosk
/// screen's own listener reports the same touch as activity, and it
/// never competes with the buttons for the gesture.
class _ControlTouch extends StatelessWidget {
  const _ControlTouch({required this.container, required this.child});

  final AppContainer container;
  final Widget child;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => container.screensaver.markControlTouch(),
    child: child,
  );
}

/// The queue in the lyrics' slot, laid out the way Music Assistant's own
/// is: what already played faded above a Now Playing heading, the
/// playing row under it, then an Up next heading with the count and the
/// rest. It opens on the Now Playing heading and goes back there at each
/// track change; scrolling up shows the past. A tap on any row jumps the
/// queue there, with a spinner by its duration until this device is
/// actually playing it. Scrollable, unlike the lyrics: a queue is for
/// looking around.
/// Tracks whether the ink well it builds holds focus, so the row can
/// paint its own focus tint.
class _FocusTint extends StatefulWidget {
  const _FocusTint({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    bool focused,
    ValueChanged<bool> onFocusChange,
  )
  builder;

  @override
  State<_FocusTint> createState() => _FocusTintState();
}

class _FocusTintState extends State<_FocusTint> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => widget.builder(context, _focused, (f) {
    if (mounted && f != _focused) setState(() => _focused = f);
  });
}

class _QueueView extends StatefulWidget {
  const _QueueView({required this.container, required this.fontSize});

  final AppContainer container;
  final double fontSize;

  @override
  State<_QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<_QueueView> {
  AppContainer get container => widget.container;
  double get fontSize => widget.fontSize;

  /// The thumbnails switch flipping from either settings surface
  /// rebuilds the rows.
  StreamSubscription<SettingChanged>? _artSub;

  final _scroll = ScrollController();
  final _nowPlayingKey = GlobalKey();
  final _lastPlayedKey = GlobalKey();
  List<Map<String, Object?>>? _scrolledFor;

  /// The row just tapped, spinning until its track is what this device
  /// is actually playing (the server switches its queue at once, the
  /// audio a couple of seconds later, and that gap is the wait), another
  /// row is tapped, or the jump plainly did not happen.
  String? _pendingId;
  String _pendingTitle = '';
  Timer? _pendingTimeout;
  Timer? _chapterTick;
  int? _pendingChapterStart;
  int? _chapterRowsSignature;
  List<Map<String, Object?>> _chapterRows = const [];

  @override
  void initState() {
    super.initState();
    _artSub = container.bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.sendspinQueueArt.key && mounted) setState(() {});
    });
    container.sendspin.nowPlaying.addListener(_onNowPlaying);
    _onNowPlaying();
  }

  @override
  void didUpdateWidget(covariant _QueueView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fontSize != widget.fontSize) _scrolledFor = null;
  }

  @override
  void dispose() {
    container.sendspin.nowPlaying.removeListener(_onNowPlaying);
    _pendingTimeout?.cancel();
    _chapterTick?.cancel();
    _scroll.dispose();
    _artSub?.cancel();
    super.dispose();
  }

  void _onNowPlaying() {
    if (!mounted) return;
    final now = container.sendspin.nowPlaying.value;
    final chapters = audiobookChapters(now);
    if (chapters.isNotEmpty && now?['playing'] == true) {
      _chapterTick ??= Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => _onNowPlaying(),
      );
    } else {
      _chapterTick?.cancel();
      _chapterTick = null;
    }
    if (_pendingId != null) {
      if (_pendingChapterStart case final start?) {
        final position = now == null
            ? 0
            : playbackPositionMs(now, DateTime.now().millisecondsSinceEpoch);
        final index = currentChapterIndex(
          chapters,
          position,
          (now?['durationMs'] as num?)?.toInt() ?? 0,
        );
        if ('${now?['title'] ?? ''}' != _pendingTitle ||
            (index >= 0 && chapters[index].startMs == start)) {
          _clearPending();
        }
      } else if ('${now?['title'] ?? ''}' == _pendingTitle) {
        _clearPending();
      }
    }
    if (chapters.isNotEmpty || _chapterRowsSignature != null) setState(() {});
  }

  void _clearPending() {
    _pendingTimeout?.cancel();
    _pendingTimeout = null;
    if (mounted) {
      setState(() {
        _pendingId = null;
        _pendingChapterStart = null;
      });
    }
  }

  Future<void> _play(Map<String, Object?> item) async {
    final id = '${item['id'] ?? ''}';
    if (id.isEmpty) return;
    final start = item['chapterStartMs'] as int?;
    _pendingTimeout?.cancel();
    setState(() {
      _pendingId = id;
      _pendingChapterStart = start;
      _pendingTitle = start == null
          ? '${item['title'] ?? ''}'
          : '${container.sendspin.nowPlaying.value?['title'] ?? ''}';
    });
    _pendingTimeout = Timer(const Duration(seconds: 15), () {
      if (_pendingId == id) _clearPending();
    });
    final ok = start == null
        ? await container.sendspin.playQueueItem(id)
        : await container.sendspin.seek(start);
    if (!mounted) return;
    if (!ok && _pendingId == id) _clearPending();
  }

  /// Land the Now Playing heading near the top once per queue listing,
  /// on open and again when a track change re-lists it, with half of the
  /// row that just played showing above it: a hint that there is a past
  /// to scroll up to, and a glimpse of what that was.
  void _scrollToNowPlaying(List<Map<String, Object?>> items, int current) {
    // A listing with no playing row yet (the position not read, the
    // track just changed) has nothing to land on; the next listing gets
    // its turn.
    if (current < 0 || identical(_scrolledFor, items)) return;
    _scrolledFor = items;
    _landOnNowPlaying(items, current, 0);
  }

  void _landOnNowPlaying(
    List<Map<String, Object?>> items,
    int current,
    int attempt,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_scrolledFor, items) || !_scroll.hasClients) {
        return;
      }
      final position = _scroll.position;
      final heading = _nowPlayingKey.currentContext?.findRenderObject();
      if (heading is! RenderBox) {
        // The list builds only the rows around the viewport, so a heading
        // far down has no context yet. Jump to where the rows built so
        // far say it should sit; that builds the rows around it and the
        // next frame lands on it exactly.
        if (attempt >= 8) return;
        final guess = position.maxScrollExtent * current / items.length;
        _scroll.jumpTo(
          guess.clamp(position.minScrollExtent, position.maxScrollExtent),
        );
        _landOnNowPlaying(items, current, attempt + 1);
        return;
      }
      final viewport = RenderAbstractViewport.of(heading);
      final top = viewport.getOffsetToReveal(heading, 0).offset;
      final played = _lastPlayedKey.currentContext?.findRenderObject();
      final peek = played is RenderBox ? played.size.height / 2 : 0.0;
      final target = (top - peek).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (attempt > 0) {
        _scroll.jumpTo(target);
        return;
      }
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Widget _heading(String label, {int? count, Key? key}) => Padding(
    key: key,
    padding: EdgeInsets.fromLTRB(12, fontSize * 0.9, 12, fontSize * 0.4),
    child: Row(
      children: [
        Flexible(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white70,
              fontSize: fontSize * 0.7,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 10),
          Text(
            '$count',
            style: TextStyle(
              color: Colors.white38,
              fontSize: fontSize * 0.7,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
        const SizedBox(width: 14),
        const Expanded(child: Divider(color: Colors.white24, height: 1)),
      ],
    ),
  );

  Widget _row(Map<String, Object?> item, {Key? key}) {
    final current = item['current'] == true;
    final played = item['played'] == true;
    final duration = (item['durationMs'] as num?)?.toInt() ?? 0;
    final id = '${item['id'] ?? ''}';
    final waiting = _pendingId != null && _pendingId == id;
    return _FocusTint(
      key: key,
      builder: (context, focused, onFocusChange) {
        // A focused row reads at full strength whatever its place in
        // the queue, the way the playing one does.
        final titleColor = current || focused
            ? Colors.white
            : played
            ? Colors.white38
            : Colors.white70;
        final subColor = current || focused
            ? Colors.white70
            : played
            ? Colors.white24
            : Colors.white38;
        return InkWell(
          onTap: item['canSeek'] == false ? null : () => _play(item),
          borderRadius: BorderRadius.circular(10),
          onFocusChange: onFocusChange,
          // A dpad walking the rows needs to see where it is, whatever the
          // focus highlight mode: a touch device paints no ink ring until
          // it has seen a key, so the row tints itself.
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: focused
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: LayoutBuilder(
                builder: (context, box) {
                  final compact = box.maxWidth < fontSize * 12;
                  final durationLabel = Text(
                    _clock(duration),
                    style: TextStyle(
                      color: subColor,
                      fontSize: fontSize * 0.8,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  );
                  return Row(
                    children: [
                      if (container.settings.get(defs.sendspinQueueArt)) ...[
                        Opacity(
                          opacity: played && !current && !focused ? 0.45 : 1,
                          child: _QueueThumb(
                            container: container,
                            url: '${item['artworkUrl'] ?? ''}',
                            size: min(fontSize * 2.4, box.maxWidth * 0.2),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['title'] ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: Ks.displayFont,
                                color: titleColor,
                                fontSize: current ? fontSize : fontSize * 0.9,
                                fontWeight: current
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            if ('${item['artist'] ?? ''}'.isNotEmpty)
                              Text(
                                '${item['artist']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: subColor,
                                  fontSize: fontSize * 0.8,
                                ),
                              ),
                            if (compact && duration > 0) durationLabel,
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // A constant slot before the duration: the spinner while a
                      // tap is on its way, nothing otherwise, so the durations line
                      // up whatever a row is doing.
                      SizedBox(
                        width: fontSize,
                        height: fontSize,
                        child: waiting
                            ? Padding(
                                padding: EdgeInsets.all(fontSize * 0.1),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              )
                            : null,
                      ),
                      if (!compact && duration > 0) ...[
                        const SizedBox(width: 8),
                        durationLabel,
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, Object?>>>(
      valueListenable: container.sendspin.queueItems,
      builder: (context, items, _) {
        final now = container.sendspin.nowPlaying.value;
        final chapters = audiobookChapters(
          now,
          unnamedChapter: (number) =>
              l10n(context).mediaUnnamedChapter('$number'),
        );
        final chapterMode = chapters.isNotEmpty;
        if (chapterMode) {
          final position = playbackPositionMs(
            now!,
            DateTime.now().millisecondsSinceEpoch,
          );
          final active = currentChapterIndex(
            chapters,
            position,
            (now['durationMs'] as num?)?.toInt() ?? 0,
          );
          final commands = now['supportedCommands'] as List?;
          final canSeek =
              commands == null || commands.isEmpty || commands.contains('seek');
          final signature = Object.hash(
            now['mediaUri'],
            now['queueItemId'],
            now['title'],
            now['artworkUrl'],
            active,
            canSeek,
            Object.hashAll(
              chapters.map(
                (chapter) =>
                    Object.hash(chapter.name, chapter.startMs, chapter.endMs),
              ),
            ),
          );
          if (signature != _chapterRowsSignature) {
            _chapterRowsSignature = signature;
            _chapterRows = [
              for (final (i, chapter) in chapters.indexed)
                {
                  'id': 'chapter:${chapter.startMs}',
                  'title': chapter.name,
                  'durationMs': chapter.durationMs,
                  'chapterStartMs': chapter.startMs,
                  'canSeek': canSeek,
                  'current': i == active,
                  'played': chapter.endMs <= position && i != active,
                  'artworkUrl': now['artworkUrl'],
                },
            ];
          }
          items = _chapterRows;
        } else {
          _chapterRowsSignature = null;
        }
        if (items.isEmpty) {
          return Center(
            child: Text(
              mediaText(context, 'Nothing queued'),
              style: TextStyle(color: Colors.white38, fontSize: fontSize),
            ),
          );
        }
        final current = items.indexWhere((it) => it['current'] == true);
        final played = current < 0
            ? const <Map<String, Object?>>[]
            : items.sublist(0, current);
        final upcoming = current < 0 ? items : items.sublist(current + 1);
        _scrollToNowPlaying(items, current);
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0.0, 0.06, 0.94, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: ValueListenableBuilder<int>(
            valueListenable: container.sendspin.queueUpNext,
            builder: (context, upNext, _) => ListView(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                if (chapterMode)
                  _heading(mediaText(context, 'Chapters'), count: items.length),
                for (final (i, item) in played.indexed)
                  _row(
                    item,
                    key: i == played.length - 1 ? _lastPlayedKey : null,
                  ),
                if (current >= 0) ...[
                  _heading(
                    mediaText(context, 'Now playing'),
                    key: _nowPlayingKey,
                  ),
                  _row(items[current]),
                ],
                _heading(
                  mediaText(context, 'Up next'),
                  count: chapterMode ? upcoming.length : upNext,
                ),
                for (final item in upcoming) _row(item),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A queue row's cover: fetched once per URL and kept in a cache bounded
/// by bytes, a placeholder glyph while it loads and when nothing comes.
/// Built to survive a thousand-row queue flung end to end: the rows
/// themselves are lazy and only visible rows request images after the
/// scroll settles. Downloads shared by an album's rows are cancelled
/// once no visible row needs them. Small thumbnails persist on disk and
/// recently used images stay in memory. A total timeout bounds
/// each transfer because a speaker's art proxy can hang.
class _QueueThumb extends StatefulWidget {
  const _QueueThumb({
    required this.container,
    required this.url,
    required this.size,
  });

  final AppContainer container;
  final String url;
  final double size;

  static final lane = FetchLane();

  /// One fetch per URL however many rows share it (an album's tracks
  /// do), with a count of the rows waiting on it: the fetch stays in
  /// line while any of them is on screen and leaves it only when the
  /// last one has scrolled away.
  static final _pending = <String, _SharedFetch>{};

  @override
  State<_QueueThumb> createState() => _QueueThumbState();
}

class _SharedFetch {
  final completer = Completer<Uint8List?>();
  final cancelled = Completer<void>();
  FetchTicket? ticket;
  int waiters = 0;
}

class _QueueThumbState extends State<_QueueThumb> {
  Uint8List? _bytes;
  String _waitingOn = '';
  _SharedFetch? _fetch;
  ScrollPosition? _position;
  bool _visibilityScheduled = false;
  bool _attempted = false;

  /// A beat before asking: the panel lands on the playing track a frame
  /// after it opens, and the rows built at the top in between are gone
  /// before this fires.
  Timer? _grace;

  /// Release a download once no visible row needs it.
  void _withdraw() {
    final url = _waitingOn;
    _waitingOn = '';
    final shared = _fetch;
    _fetch = null;
    if (shared == null) return;
    shared.waiters--;
    if (shared.waiters <= 0) {
      shared.ticket?.cancel();
      shared.cancelled.complete();
      if (identical(_QueueThumb._pending[url], shared)) {
        _QueueThumb._pending.remove(url);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.of(context).position;
    if (!identical(position, _position)) {
      _position?.removeListener(_checkAfterLayout);
      _position?.isScrollingNotifier.removeListener(_checkAfterLayout);
      _position = position;
      position.addListener(_checkAfterLayout);
      position.isScrollingNotifier.addListener(_checkAfterLayout);
    }
    _checkAfterLayout();
  }

  void _checkAfterLayout() {
    if (_visibilityScheduled) return;
    _visibilityScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityScheduled = false;
      if (mounted) _checkVisibility();
    });
  }

  bool get _visible {
    final box = context.findRenderObject();
    final position = _position;
    if (box is! RenderBox || !box.hasSize || position == null) return false;
    final viewport = RenderAbstractViewport.of(box);
    final top = viewport.getOffsetToReveal(box, 0).offset;
    return top < position.pixels + position.viewportDimension &&
        top + box.size.height > position.pixels;
  }

  void _checkVisibility() {
    if (!_visible) {
      _attempted = false;
      _grace?.cancel();
      _grace = null;
      _withdraw();
      return;
    }
    if (_position!.isScrollingNotifier.value) {
      _grace?.cancel();
      _grace = null;
      return;
    }
    if (!_attempted && _bytes == null && _fetch == null && _grace == null) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant _QueueThumb old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _grace?.cancel();
      _grace = null;
      _withdraw();
      _bytes = null;
      _attempted = false;
      _checkAfterLayout();
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_checkAfterLayout);
    _position?.isScrollingNotifier.removeListener(_checkAfterLayout);
    _grace?.cancel();
    _withdraw();
    super.dispose();
  }

  void _load() {
    final url = widget.url;
    if (url.isEmpty) return;
    final cache = widget.container.sendspin.queueArtworkCache.memory;
    if (cache.contains(url)) {
      setState(() => _bytes = cache.get(url));
      return;
    }
    _grace?.cancel();
    _grace = Timer(const Duration(milliseconds: 250), () {
      _grace = null;
      if (mounted &&
          widget.url == url &&
          _visible &&
          !_position!.isScrollingNotifier.value) {
        _ask(url);
      }
    });
  }

  void _ask(String url) {
    _attempted = true;
    final cache = widget.container.sendspin.queueArtworkCache.memory;
    if (cache.contains(url)) {
      setState(() => _bytes = cache.get(url));
      return;
    }
    var shared = _QueueThumb._pending[url];
    if (shared == null) {
      final fresh = _SharedFetch();
      final player = widget.container.sendspin;
      _QueueThumb._pending[url] = fresh;
      fresh.ticket = _QueueThumb.lane.schedule(() async {
        Uint8List? bytes;
        try {
          bytes = await player.queueArtworkCache.load(
            url,
            () => player.fetchArtwork(
              url,
              timeout: const Duration(seconds: 8),
              cancelled: fresh.cancelled.future,
            ),
            cancelled: () => fresh.cancelled.isCompleted,
          );
        } catch (_) {
          bytes = null;
        }
        if (identical(_QueueThumb._pending[url], fresh)) {
          _QueueThumb._pending.remove(url);
        }
        fresh.completer.complete(bytes);
      });
      shared = fresh;
    }
    shared.waiters++;
    _waitingOn = url;
    _fetch = shared;
    shared.completer.future.then((bytes) {
      if (!mounted || !identical(_fetch, shared)) return;
      _fetch = null;
      _waitingOn = '';
      setState(() => _bytes = bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    _checkAfterLayout();
    final bytes = _bytes;
    // Decoded at the drawn size: a speaker's thumbnail is the whole
    // cover, and a full decode per row is what fills memory on a fling.
    final px = (widget.size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: bytes != null
            ? Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: px,
                cacheHeight: px,
              )
            : ColoredBox(
                color: Colors.white10,
                child: Icon(
                  Icons.music_note_rounded,
                  color: Colors.white24,
                  size: widget.size * 0.5,
                ),
              ),
      ),
    );
  }
}

/// Shows [child] for a few seconds after each touch or key press, then
/// fades it out: the speaker pill, and the album art only layout's
/// details, transport and close button. Hidden, it takes no touches or
/// focus, so the touch that brings it up never lands on a button under
/// the finger.
class _TransientOnActivity extends StatefulWidget {
  const _TransientOnActivity({
    required this.container,
    required this.child,
    this.visibilityKey,
  });

  final AppContainer container;
  final Widget child;

  /// Keys the fade, for tests to read its opacity.
  final Key? visibilityKey;

  @override
  State<_TransientOnActivity> createState() => _TransientOnActivityState();
}

class _TransientOnActivityState extends State<_TransientOnActivity> {
  StreamSubscription<ActivityDetected>? _activitySub;
  Timer? _hide;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _activitySub = widget.container.bus.on<ActivityDetected>().listen((event) {
      if (event.source != 'touch' && event.source != 'key') return;
      _hide?.cancel();
      if (!_visible) setState(() => _visible = true);
      _hide = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _visible = false);
      });
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    _activitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !_visible,
    child: ExcludeFocus(
      excluding: !_visible,
      child: AnimatedOpacity(
        key: widget.visibilityKey,
        opacity: _visible ? 1 : 0,
        duration: _visible ? Duration.zero : const Duration(milliseconds: 300),
        child: widget.child,
      ),
    ),
  );
}

/// The chip naming the shown player. Where the source can group players
/// (Music Assistant, a Sonos household) a tap opens the group menu: the
/// players in the group first, then every one that could join, each with
/// a checkbox. Reports its touches as control touches so a tap on it is
/// never a step of the double-tap dismiss chain.
class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.container,
    required this.maxWidth,
    required this.scale,
  });

  final AppContainer container;
  final double maxWidth;

  /// The Now Playing text scale, so the chip grows with the title.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final c = container;
    final grouping = c.sendspin.groupAvailable;
    final iconSize = 20 * scale;
    return _ControlTouch(
      container: c,
      child: Material(
        color: Colors.black45,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: grouping
              // The menu grows at 70% of the chip's rate, so the list
              // keeps room for more rows.
              ? () => _GroupMenu.show(context, c, 1 + (scale - 1) * 0.7)
              : null,
          focusColor: Colors.white24,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12 * scale,
              8 * scale,
              (grouping ? 10 : 16) * scale,
              8 * scale,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.speaker_outlined,
                  semanticLabel: grouping
                      ? l10n(context).mediaSpeakerSelection
                      : null,
                  color: Colors.white70,
                  size: iconSize,
                ),
                SizedBox(width: 8 * scale),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: min(
                      240 * scale,
                      max(0, maxWidth - (grouping ? 74 : 56) * scale),
                    ),
                  ),
                  child: Text(
                    c.sendspin.playerChipName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (grouping) ...[
                  SizedBox(width: 4 * scale),
                  Icon(
                    Icons.expand_more_rounded,
                    color: Colors.white70,
                    size: iconSize,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The group menu under the chip: the leader's name as its title, then
/// the players in the group and the ones that could join, checkboxes
/// each, the grouped ones first and alphabetical within. A toggle sends
/// the command, spins on its row until the source reports the group back
/// and puts the box back if the source refused.
class _GroupMenu extends StatefulWidget {
  const _GroupMenu({
    required this.container,
    required this.anchor,
    required this.panelWidth,
    required this.scale,
  });

  final AppContainer container;
  final Rect anchor;
  final double panelWidth;

  /// The chip's scale, slowed down by [_PlayerChip].
  final double scale;

  static Future<void> show(
    BuildContext context,
    AppContainer container,
    double scale,
  ) {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(
              context,
              rootNavigator: true,
            ).overlay!.context.findRenderObject()!
            as RenderBox;
    final anchor = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
    final panelWidth = MediaQuery.sizeOf(context).width;
    return showDialog<void>(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black26,
      builder: (_) => _GroupMenu(
        container: container,
        anchor: anchor,
        panelWidth: panelWidth,
        scale: scale,
      ),
    );
  }

  @override
  State<_GroupMenu> createState() => _GroupMenuState();
}

class _GroupMenuState extends State<_GroupMenu> {
  RemoteGroup? _group;
  bool _loading = true;
  bool _failed = false;
  final _pending = <String>{};

  /// What a toggle just asked for, shown until the source reports it:
  /// Music Assistant's player list can lag its own group command by a
  /// moment, and a box that snapped back would read as a refusal.
  final _asked = <String, bool>{};
  Timer? _recheck;

  /// Each player's level as its slider last left it (issue #867): the
  /// player list is only read again on a group change, so a level set
  /// here stands until then.
  final _levels = <String, double>{};

  @override
  void initState() {
    super.initState();
    // The menu is a route above the view, so the view going away (the
    // screensaver dismissed, playback ending) would leave it up on its
    // own: it goes with the view.
    final c = widget.container;
    c.screensaver.activeView.addListener(_viewChanged);
    c.sendspin.fullscreenActive.addListener(_viewChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    final c = widget.container;
    c.screensaver.activeView.removeListener(_viewChanged);
    c.sendspin.fullscreenActive.removeListener(_viewChanged);
    _recheck?.cancel();
    super.dispose();
  }

  void _viewChanged() {
    final c = widget.container;
    if (c.screensaver.activeView.value == null ||
        !c.sendspin.fullscreenActive.value) {
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  Future<void> _load() async {
    RemoteGroup? group;
    try {
      group = await widget.container.sendspin.fetchGroup();
    } catch (_) {
      group = null;
    }
    if (!mounted) return;
    setState(() {
      _group = group;
      _loading = false;
      _failed = group == null;
      // An ask the source now agrees with is settled.
      if (group != null) {
        for (final m in group.members) {
          if (_asked[m.id] == m.inGroup) _asked.remove(m.id);
        }
      }
    });
    // Asks still unsettled: look again shortly.
    if (_asked.isNotEmpty) {
      _recheck?.cancel();
      _recheck = Timer(const Duration(seconds: 2), () => unawaited(_load()));
    }
  }

  Future<void> _toggle(GroupMember member) async {
    if (_pending.contains(member.id)) return;
    final want = !member.inGroup;
    setState(() => _pending.add(member.id));
    final ok = await widget.container.sendspin.setGrouped(member.id, want);
    if (!mounted) return;
    if (ok) {
      _asked[member.id] = want;
      await _load();
    }
    if (!mounted) return;
    setState(() => _pending.remove(member.id));
  }

  /// The members as shown: the source's word, with a fresh ask laid
  /// over it, in the chip's order.
  List<GroupMember> get _members => RemoteGroup.ordered([
    for (final m in _group?.members ?? const <GroupMember>[])
      _asked.containsKey(m.id)
          ? GroupMember(
              id: m.id,
              name: m.name,
              inGroup: _asked[m.id]!,
              available: m.available,
              volume: m.volume,
            )
          : m,
  ]);

  /// A player's own volume: a slider and its level, lined up under the
  /// player's name [indent] in. Sent when the finger lifts, as the view's
  /// slider does.
  Widget _volume(String id, int level, double indent) {
    final scale = widget.scale;
    final value = _levels[id] ?? level.toDouble();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        (indent - 14) * scale,
        0,
        16 * scale,
        4 * scale,
      ),
      child: SizedBox(
        height: 32 * scale,
        child: Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3 * scale,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white24,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: 6 * scale,
                  ),
                  overlayShape: RoundSliderOverlayShape(
                    overlayRadius: 14 * scale,
                  ),
                  trackShape: const RectangularSliderTrackShape(),
                ),
                child: Slider(
                  key: ValueKey('group-volume-$id'),
                  semanticFormatterCallback: (v) =>
                      '${l10n(context).mediaVolume}: ${v.round()}%',
                  value: value.clamp(0, 100),
                  max: 100,
                  onChanged: (v) => setState(() => _levels[id] = v),
                  onChangeEnd: (v) => unawaited(
                    widget.container.sendspin.setMemberVolume(id, v.round()),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 40 * scale,
              child: Text(
                '${value.round()}%',
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.white54, fontSize: 13 * scale),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final group = _group;
    final members = _members;
    final isLocal = widget.container.sendspin.followedPlayerName.isEmpty;
    final scale = widget.scale;
    final titleStyle = TextStyle(
      color: Colors.white,
      fontSize: 16 * scale,
      fontWeight: FontWeight.w600,
    );
    final rowStyle = TextStyle(color: Colors.white, fontSize: 15 * scale);
    Widget note(String text) => Padding(
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        12 * scale,
        16 * scale,
        16 * scale,
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white54, fontSize: 14 * scale),
      ),
    );
    final width = min(
      340.0 * scale,
      min(widget.panelWidth - 24, screen.width - 24),
    );
    final left = widget.anchor.left.clamp(12.0, screen.width - width - 12);
    final top = widget.anchor.bottom + 8;
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(left: left, top: top),
        child: Material(
          key: const ValueKey('speaker-group-menu'),
          color: const Color(0xF0202020),
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: width,
              maxWidth: width,
              maxHeight: min(
                screen.height * 0.7,
                max(
                  0,
                  screen.height -
                      top -
                      MediaQuery.paddingOf(context).bottom -
                      12,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16 * scale,
                    14 * scale,
                    16 * scale,
                    10 * scale,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.speaker_group_outlined,
                        color: Colors.white70,
                        size: 20 * scale,
                      ),
                      SizedBox(width: 10 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group?.leaderName ??
                                  widget.container.sendspin.playerChipName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                            // Another player's name over this one's
                            // menu: say why.
                            if (group != null && !group.leads)
                              Text(
                                mediaText(context, 'Leads the group'),
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13 * scale,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // The leader's own volume, once there is a group for it
                // to lead.
                if (group?.leaderVolume case final level?
                    when members.any((m) => m.inGroup))
                  _volume(group!.leaderId, level, 46),
                const Divider(height: 1, color: Colors.white12),
                if (_loading)
                  Padding(
                    padding: EdgeInsets.all(20 * scale),
                    child: Center(
                      child: SizedBox(
                        width: 22 * scale,
                        height: 22 * scale,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  )
                else if (_failed)
                  note(mediaText(context, 'The group could not be read.'))
                else if (members.isEmpty)
                  note(mediaText(context, 'No other players to group with.'))
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(vertical: 6 * scale),
                      children: [
                        for (final (i, m) in members.indexed) ...[
                          InkWell(
                            autofocus: i == 0,
                            focusColor: Colors.white12,
                            onTap: () => _toggle(m),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14 * scale,
                                vertical: 10 * scale,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24 * scale,
                                    height: 24 * scale,
                                    child: _pending.contains(m.id)
                                        ? Padding(
                                            padding: EdgeInsets.all(3 * scale),
                                            child:
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white70,
                                                ),
                                          )
                                        : Icon(
                                            m.inGroup
                                                ? Icons.check_box_rounded
                                                : Icons
                                                      .check_box_outline_blank_rounded,
                                            color: m.inGroup
                                                ? Colors.white
                                                : Colors.white54,
                                            size: 24 * scale,
                                          ),
                                  ),
                                  SizedBox(width: 12 * scale),
                                  Expanded(
                                    child: Text(
                                      m.available
                                          ? m.name
                                          : l10n(
                                              context,
                                            ).mediaOfflineName(m.name),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: rowStyle.copyWith(
                                        color: m.available
                                            ? Colors.white
                                            : Colors.white38,
                                      ),
                                    ),
                                  ),
                                  // The shown player's own row, under a
                                  // name the source may spell its own
                                  // way: unchecking it is leaving.
                                  if (m.id == group?.selfId && isLocal) ...[
                                    SizedBox(width: 10 * scale),
                                    Text(
                                      mediaText(context, 'This device'),
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13 * scale,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          // A member's own volume while it plays in the group.
                          if (m.volume case final level?
                              when m.inGroup && !_pending.contains(m.id))
                            _volume(m.id, level, 50),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Now Playing view's transport (sendspin.fullscreen_controls): the
/// large card's previous, play/pause and next at wall-tablet size, over a
/// progress bar that seeks where the server allows it, flanked by the
/// smaller toggles the way Music Assistant's own player lays them out:
/// volume, favorite and shuffle to the left, repeat, lyrics and queue
/// to the right. Its
/// own widget with its own tick, so the position refresh rebuilds these
/// few pixels and not the blurred backdrop behind them.
class _NowPlayingControls extends StatefulWidget {
  const _NowPlayingControls({
    required this.container,
    required this.width,
    required this.scale,
    required this.maxHeight,
    this.shadows,
  });

  final AppContainer container;

  /// The bar's width; the buttons center under it.
  final double width;

  /// Everything scales down from the tablet sizes on a small panel.
  final double scale;

  final double maxHeight;

  /// Drop shadows under the buttons, the bars and the times, for controls
  /// drawn over the cover.
  final List<Shadow>? shadows;

  @override
  State<_NowPlayingControls> createState() => _NowPlayingControlsState();
}

class _NowPlayingControlsState extends State<_NowPlayingControls> {
  AppContainer get c => widget.container;

  Object? _presentation;

  /// The shuffle toggle as just pressed, shown until the server reports
  /// the state again (or reports it unchanged, which means it refused).
  bool? _shuffleOverride;
  bool? _lastShuffle;

  /// The repeat mode as just pressed, the same way.
  String? _repeatOverride;
  String? _lastRepeat;

  /// Where a dpad lands when the view comes up: play or pause, the
  /// middle of the transport, so left and right reach everything else.
  final _playFocus = FocusNode(debugLabel: 'now playing play');

  /// The volume slider standing in for the seek bar: opened by its
  /// toggle, closed by a second tap or a few seconds after the last
  /// touch. The dragged level holds for a moment after release, until
  /// the source reports the new level back.
  bool _volumeOpen = false;
  double? _volumeDrag;
  Timer? _volumeClose;
  Timer? _volumeHold;

  void _armVolumeClose() {
    _volumeClose?.cancel();
    _volumeClose = Timer(const Duration(seconds: 4), () {
      _volumeClose = null;
      if (!mounted || !_volumeOpen) return;
      setState(() => _volumeOpen = false);
    });
  }

  void _toggleVolume() {
    setState(() => _volumeOpen = !_volumeOpen);
    if (_volumeOpen) {
      _armVolumeClose();
    } else {
      _volumeClose?.cancel();
      _volumeClose = null;
    }
  }

  /// A hardware volume key moved the player (issue #544): show the
  /// slider for a moment, the way the system shows its own volume.
  void _onVolumeNudge() {
    if (!mounted || !c.sendspin.volumeAvailable) return;
    if (!_volumeOpen) setState(() => _volumeOpen = true);
    _armVolumeClose();
  }

  Future<void> _setVolume(double level) async {
    _armVolumeClose();
    _volumeHold?.cancel();
    _volumeHold = Timer(const Duration(seconds: 3), () {
      _volumeHold = null;
      if (mounted) setState(() => _volumeDrag = null);
    });
    await c.sendspin.setVolume(level.round());
  }

  /// The lyrics and queue toggles read settings, so they follow the
  /// setting bus.
  StreamSubscription<SettingChanged>? _settingsSub;

  @override
  void initState() {
    super.initState();
    c.sendspin.nowPlaying.addListener(_onNowPlaying);
    c.sendspin.favorite.addListener(_rebuild);
    c.sendspin.volumeNudge.addListener(_onVolumeNudge);
    // Nothing else on the view takes focus, so without this a dpad had
    // nothing to walk from.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_playFocus.hasFocus) _playFocus.requestFocus();
    });
    _settingsSub = c.bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.sendspinLyrics.key ||
          e.key == defs.sendspinFullscreenQueue.key) {
        _rebuild();
      }
    });
    _onNowPlaying();
  }

  @override
  void dispose() {
    c.sendspin.nowPlaying.removeListener(_onNowPlaying);
    c.sendspin.favorite.removeListener(_rebuild);
    c.sendspin.volumeNudge.removeListener(_onVolumeNudge);
    _settingsSub?.cancel();
    _volumeClose?.cancel();
    _volumeHold?.cancel();
    _playFocus.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onNowPlaying() {
    final now = c.sendspin.nowPlaying.value;
    final playing = now?['playing'] == true;
    final presentation = (
      now == null,
      playing,
      now?['shuffle'],
      now?['repeat'],
      (now?['supportedCommands'] as List?)?.join(','),
      c.sendspin.volumeAvailable,
      c.sendspin.volumeLevel,
      c.sendspin.muted,
      c.sendspin.favoriteAvailable,
      c.sendspin.lyricsAvailable,
      c.sendspin.queueAvailable,
    );
    if (presentation == _presentation) return;
    _presentation = presentation;
    // Any fresh word from the server on shuffle outranks the press.
    final shuffle = now?['shuffle'] == true;
    final repeat = '${now?['repeat'] ?? 'off'}';
    if (repeat != _lastRepeat) {
      _lastRepeat = repeat;
      _repeatOverride = null;
    }
    if (shuffle != _lastShuffle) {
      _lastShuffle = shuffle;
      _shuffleOverride = null;
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleShuffle(bool on) async {
    setState(() => _shuffleOverride = on);
    final ok = await c.sendspin.setShuffle(on);
    if (!ok && mounted) setState(() => _shuffleOverride = null);
  }

  /// Off, all, one, off: the order every player app cycles in.
  Future<void> _cycleRepeat(String current) async {
    final next = switch (current) {
      'off' => 'all',
      'all' => 'one',
      _ => 'off',
    };
    setState(() => _repeatOverride = next);
    final ok = await c.sendspin.setRepeat(next);
    if (!ok && mounted) setState(() => _repeatOverride = null);
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, box) => _buildControls(context, box));

  Widget _buildControls(BuildContext context, BoxConstraints box) {
    final now = c.sendspin.nowPlaying.value;
    if (now == null) return const SizedBox.shrink();
    final playing = now['playing'] == true;
    // Leave room above the controls for artwork, track details or lyrics.
    final scale = min(widget.scale, widget.maxHeight / 184);
    final supported =
        (now['supportedCommands'] as List?)?.map((e) => '$e').toList() ??
        const <String>[];
    bool has(String cmd) => supported.isEmpty || supported.contains(cmd);
    final timeStyle = TextStyle(
      color: Colors.white70,
      fontSize: 17 * scale,
      fontFeatures: const [FontFeature.tabularFigures()],
      shadows: widget.shadows,
    );

    Widget btn(
      IconData icon,
      VoidCallback? onPressed, {
      required double size,
      required String label,
      Color color = Colors.white,
      FocusNode? focusNode,
    }) => IconButton(
      icon: Icon(icon, size: size * scale, shadows: widget.shadows),
      tooltip: label,
      color: color,
      disabledColor: color,
      // A dpad walking the buttons needs to see where it is, on a dark
      // backdrop the theme's ring would vanish into.
      focusColor: Colors.white24,
      focusNode: focusNode,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: (size + 16) * scale,
        minHeight: (size + 16) * scale,
      ),
      onPressed: onPressed,
    );
    Widget transport(IconData icon, String command, {required double size}) =>
        btn(
          icon,
          () => c.sendspin.control(command),
          size: size,
          label: _transportLabel(context, command),
        );
    // The six toggles, three a side: lit when on, dimmed when off. A
    // missing one leaves its width behind so the transport stays
    // centered under the cover either way.
    const toggleSize = 32.0;
    // Off stays close to on so a toggle never fades into the artwork; the
    // icon itself tells the two apart where the state matters.
    const off = Colors.white70;
    const unknown = Colors.white38;
    final toggleBlank = SizedBox(width: (toggleSize + 16) * scale);
    // The heart: unknown (the lookup still out) draws faint and inert,
    // and without a Music Assistant library behind the source there is
    // nothing to favorite into.
    final favorite = c.sendspin.favorite.value;
    final heart = c.sendspin.favoriteAvailable
        ? btn(
            favorite == true
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            favorite == null ? null : c.sendspin.toggleFavorite,
            label: favorite == true
                ? l10n(context).mediaFavoriteRemove
                : l10n(context).mediaFavoriteAdd,
            size: toggleSize,
            color: favorite == true
                ? Colors.white
                : favorite == null
                ? unknown
                : off,
          )
        : toggleBlank;
    // Repeat: off dim, all lit, one lit with the numbered glyph. The
    // local player's server names it per mode in its command set.
    final repeatMode = _repeatOverride ?? '${now['repeat'] ?? 'off'}';
    final repeat = has('repeat') || has('repeat_all')
        ? btn(
            repeatMode == 'one'
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            () => _cycleRepeat(repeatMode),
            label: switch (repeatMode) {
              'off' => l10n(context).mediaRepeatAll,
              'all' => l10n(context).mediaRepeatOne,
              _ => l10n(context).mediaRepeatOff,
            },
            size: toggleSize,
            color: repeatMode == 'off' ? off : Colors.white,
          )
        : toggleBlank;
    final shuffleOn = _shuffleOverride ?? (now['shuffle'] == true);
    final shuffle = has('shuffle')
        ? btn(
            Icons.shuffle_rounded,
            () => _toggleShuffle(!shuffleOn),
            label: shuffleOn
                ? l10n(context).mediaShuffleOff
                : l10n(context).mediaShuffleOn,
            size: toggleSize,
            color: shuffleOn ? Colors.white : off,
          )
        : toggleBlank;
    // Lyrics need a position close enough to sing along with, which
    // every source but a coarsely reported one gives. Lit only while
    // they are actually the panel: the queue outranks them while it is
    // open.
    final queueOpen = c.sendspin.queueOpen;
    final lyricsOn = c.settings.get(defs.sendspinLyrics) && !queueOpen;
    final lyrics = c.sendspin.lyricsAvailable
        ? btn(
            lyricsOn ? Icons.lyrics_rounded : Icons.lyrics_outlined,
            c.sendspin.toggleLyrics,
            label: lyricsOn
                ? l10n(context).mediaHideLyrics
                : l10n(context).mediaShowLyrics,
            size: toggleSize,
            color: lyricsOn ? Colors.white : off,
          )
        : toggleBlank;
    final queue = c.sendspin.queueAvailable
        ? btn(
            Icons.queue_music_rounded,
            c.sendspin.toggleQueue,
            label: queueOpen
                ? l10n(context).mediaHideQueue
                : l10n(context).mediaShowQueue,
            size: toggleSize,
            color: queueOpen ? Colors.white : off,
          )
        : toggleBlank;
    // The volume toggle leads the left cluster; the right one keeps a
    // blank so the transport stays centered with three slots a side.
    final volumeAvailable = c.sendspin.volumeAvailable;
    final volumeOpen = _volumeOpen && volumeAvailable;
    final level =
        _volumeDrag ?? c.sendspin.volumeLevel?.toDouble().clamp(0.0, 100.0);
    final muted = c.sendspin.muted;
    final volume = volumeAvailable
        ? btn(
            muted
                ? (volumeOpen
                      ? Icons.volume_off_rounded
                      : Icons.volume_off_outlined)
                : (volumeOpen
                      ? Icons.volume_up_rounded
                      : Icons.volume_up_outlined),
            _toggleVolume,
            label: volumeOpen
                ? l10n(context).mediaHideVolume
                : l10n(context).mediaShowVolume,
            size: toggleSize,
            color: volumeOpen ? Colors.white : off,
          )
        : toggleBlank;
    // Each side packs its buttons against the transport and pushes the
    // blanks for what the source lacks to the outside, so the buttons
    // sit where they always do and the transport stays centered. Keyed,
    // so a button keeps its element (and the press under a finger) when
    // a neighbor comes or goes.
    List<Widget> cluster(List<(String, Widget)> items, {required bool left}) {
      final present = [
        for (final (key, w) in items)
          if (w != toggleBlank) KeyedSubtree(key: ValueKey(key), child: w),
      ];
      final blanks = [
        for (var i = present.length; i < items.length; i++) toggleBlank,
      ];
      final ordered = left ? [...blanks, ...present] : [...present, ...blanks];
      return [
        for (final (i, w) in ordered.indexed) ...[
          if (i > 0) SizedBox(width: 12 * scale),
          w,
        ],
      ];
    }

    // The bar takes the cover's width, but never less than the row of
    // buttons under it needs: on a small panel the buttons keep their
    // tap targets and the bar widens to match.
    double item(double size) =>
        max((size + 16) * scale, kMinInteractiveDimension);
    // Three toggles a side, present or blank, so the play button sits on
    // the screen's center line under the cover: a spare slot on one side
    // once shifted the whole row half a toggle off it.
    final rowWidth =
        item(toggleSize) * 6 +
        item(44) * 2 +
        item(68) +
        (12 * 4 + 20 * 2 + 16 * 2) * scale;
    // Narrow panels give the transport its own row to preserve tap targets.
    final maxWidth = min(
      box.maxWidth,
      MediaQuery.sizeOf(context).width - 24 * scale,
    );
    final compact = maxWidth < rowWidth;
    final transportButtons = <Widget>[
      if (has('previous'))
        transport(Icons.skip_previous_rounded, 'previous', size: 44),
      SizedBox(width: 16 * scale),
      if (has(playing ? 'pause' : 'play'))
        btn(
          playing
              ? Icons.pause_circle_filled_rounded
              : Icons.play_circle_fill_rounded,
          () => c.sendspin.control(playing ? 'pause' : 'play'),
          label: playing ? l10n(context).mediaPause : l10n(context).mediaPlay,
          size: 68,
          focusNode: _playFocus,
        ),
      SizedBox(width: 16 * scale),
      if (has('next')) transport(Icons.skip_next_rounded, 'next', size: 44),
    ];
    final width = max(widget.width, rowWidth).clamp(0.0, maxWidth);
    final secondaryButtons = [
      for (final toggle in [volume, heart, shuffle, repeat, lyrics, queue])
        if (toggle != toggleBlank) toggle,
    ];
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (volumeOpen) ...[
            // The volume in the seek bar's place, the same two rows the
            // seek bar takes (the bar, then the times' line with the level
            // at the right), so the block keeps its height and nothing
            // above it moves.
            SizedBox(
              height: 24 * scale,
              child: Row(
                children: [
                  // The speaker beside the slider mutes: lit and crossed
                  // while it is.
                  btn(
                    muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    () async {
                      _armVolumeClose();
                      await c.sendspin.toggleMute();
                      // The local mute is the manager's alone; a followed
                      // player reports its own back through the snapshot.
                      if (mounted) setState(() {});
                    },
                    size: 32,
                    label: muted
                        ? l10n(context).mediaUnmute
                        : l10n(context).mediaMute,
                    color: muted ? Colors.white : Colors.white70,
                  ),
                  Expanded(
                    child: _trackShadow(
                      scale: scale,
                      shadows: widget.shadows,
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4 * scale,
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white24,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 7 * scale,
                          ),
                          overlayShape: RoundSliderOverlayShape(
                            overlayRadius: 16 * scale,
                          ),
                          trackShape: const RectangularSliderTrackShape(),
                        ),
                        child: Slider(
                          semanticFormatterCallback: (value) =>
                              '${l10n(context).mediaVolume}: ${value.round()}%',
                          value: level ?? 0,
                          max: 100,
                          onChanged: level == null
                              ? null
                              : (v) {
                                  _armVolumeClose();
                                  setState(() => _volumeDrag = v);
                                },
                          onChangeEnd: level == null ? null : _setVolume,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _barTimes(
              right: level == null ? null : '${level.round()}%',
              style: timeStyle,
            ),
          ],
          Offstage(
            key: const ValueKey('now-playing-progress'),
            offstage: volumeOpen,
            child: _NowPlayingProgress(
              container: c,
              scale: scale,
              active: !volumeOpen,
              shadows: widget.shadows,
            ),
          ),
          if (compact) ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: transportButtons,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                key: const ValueKey('now-playing-secondary-controls'),
                width: max(
                  width,
                  secondaryButtons.length * item(toggleSize) +
                      max(0, secondaryButtons.length - 1) * 16 * scale,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: secondaryButtons,
                ),
              ),
            ),
          ] else
            Transform.translate(
              offset: Offset(0, -12 * scale),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...cluster([
                      ('volume', volume),
                      ('heart', heart),
                      ('shuffle', shuffle),
                    ], left: true),
                    SizedBox(width: 20 * scale),
                    ...transportButtons,
                    SizedBox(width: 20 * scale),
                    ...cluster([
                      ('repeat', repeat),
                      ('lyrics', lyrics),
                      ('queue', queue),
                    ], left: false),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Owns progress ticks and optimistic seeking without rebuilding transport.
class _NowPlayingProgress extends StatefulWidget {
  const _NowPlayingProgress({
    required this.container,
    required this.scale,
    required this.active,
    this.shadows,
  });
  final AppContainer container;
  final double scale;
  final bool active;
  final List<Shadow>? shadows;

  @override
  State<_NowPlayingProgress> createState() => _NowPlayingProgressState();
}

class _NowPlayingProgressState extends State<_NowPlayingProgress> {
  AppContainer get c => widget.container;
  Timer? _tick;

  /// The thumb while a finger holds it, in ms; null between drags.
  double? _dragMs;
  bool _dragging = false;
  AudiobookChapter? _dragChapter;
  String? _progressKey;

  /// A seek just sent, held on screen until the next position report
  /// replaces it, so the bar does not snap back for the beat the round
  /// trip takes. The local engine adopts the target itself (Music
  /// Assistant sends no fresh progress after a seek) and reports it when
  /// the restarted stream's music plays, so the bar stands still at the
  /// target through the silence before it.
  int? _seekMs;
  int? _seekAt;

  @override
  void initState() {
    super.initState();
    c.sendspin.nowPlaying.addListener(_onNowPlaying);
    _onNowPlaying();
  }

  @override
  void didUpdateWidget(_NowPlayingProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _onNowPlaying();
  }

  @override
  void dispose() {
    c.sendspin.nowPlaying.removeListener(_onNowPlaying);
    _tick?.cancel();
    super.dispose();
  }

  void _onNowPlaying() {
    final now = c.sendspin.nowPlaying.value;
    final key = '${now?['mediaUri']}|${now?['title']}|${now?['artist']}';
    if (key != _progressKey) {
      _progressKey = key;
      _dragMs = null;
      _dragging = false;
      _dragChapter = null;
      _seekMs = null;
      _seekAt = null;
    }
    final ticking =
        widget.active &&
        now?['playing'] == true &&
        ((now?['durationMs'] as num?)?.toInt() ?? 0) > 0;
    if (ticking && _tick == null) {
      _tick = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => setState(() {}),
      );
    } else if (!ticking) {
      _tick?.cancel();
      _tick = null;
    }
    final receivedAt = (now?['receivedAt'] as num?)?.toInt();
    if (_seekAt != null && receivedAt != null && receivedAt > _seekAt!) {
      _seekMs = null;
      _seekAt = null;
    }
    if (mounted && widget.active) setState(() {});
  }

  Future<void> _seek(double ms) async {
    final target = c.sendspin.seekTarget(ms.round());
    setState(() {
      _dragMs = null;
      _dragging = false;
      _dragChapter = null;
      _seekMs = target;
      _seekAt = DateTime.now().millisecondsSinceEpoch;
    });
    final ok = await c.sendspin.seek(target);
    if (!ok && mounted) {
      setState(() {
        _seekMs = null;
        _seekAt = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = c.sendspin.nowPlaying.value;
    if (now == null) return const SizedBox.shrink();
    final playing = now['playing'] == true;
    final bookDuration = (now['durationMs'] as num?)?.toInt() ?? 0;
    // Live position: the last report plus the wall time since, the way
    // the card and the lyrics extrapolate it; a seek in flight shows its
    // target, still, for at most a few seconds.
    var position = (now['positionMs'] as num?)?.toInt() ?? 0;
    final receivedAt = (now['receivedAt'] as num?)?.toInt();
    final wall = DateTime.now().millisecondsSinceEpoch;
    if (playing && receivedAt != null) position += wall - receivedAt;
    final seekAt = _seekAt;
    if (_seekMs != null && seekAt != null) {
      if (wall - seekAt < 6000) {
        position = _seekMs!;
      } else {
        _seekMs = null;
        _seekAt = null;
      }
    }
    if (bookDuration > 0) position = position.clamp(0, bookDuration);
    final chapters = audiobookChapters(
      now,
      unnamedChapter: (number) => l10n(context).mediaUnnamedChapter('$number'),
    );
    final chapterIndex = currentChapterIndex(chapters, position, bookDuration);
    final chapter = _dragging
        ? _dragChapter
        : (chapterIndex < 0 ? null : chapters[chapterIndex]);
    final duration = chapter?.durationMs ?? bookDuration;
    final relativePosition = position - (chapter?.startMs ?? 0);

    final supported =
        (now['supportedCommands'] as List?)?.map((e) => '$e').toList() ??
        const <String>[];
    bool has(String cmd) => supported.isEmpty || supported.contains(cmd);
    final canSeek = duration > 0 && has('seek');
    final scale = widget.scale;
    final shown = (_dragMs ?? relativePosition.toDouble()).clamp(
      0.0,
      duration > 0 ? duration.toDouble() : 0.0,
    );
    final timeStyle = TextStyle(
      color: Colors.white70,
      fontSize: 17 * scale,
      fontFeatures: const [FontFeature.tabularFigures()],
      shadows: widget.shadows,
    );

    if (duration <= 0) return const SizedBox.shrink();
    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chapter != null)
            Text(
              chapter.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: timeStyle,
            ),
          SizedBox(
            height: 24 * scale,
            child: _trackShadow(
              scale: scale,
              shadows: widget.shadows,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4 * scale,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white30,
                  disabledActiveTrackColor: Colors.white,
                  disabledInactiveTrackColor: Colors.white30,
                  thumbColor: Colors.white,
                  disabledThumbColor: Colors.transparent,
                  overlayColor: Colors.white24,
                  // No thumb where a seek cannot land: the bar reads as
                  // the card's progress line then.
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: 7 * scale,
                    disabledThumbRadius: 0,
                  ),
                  overlayShape: RoundSliderOverlayShape(
                    overlayRadius: 16 * scale,
                  ),
                  trackShape: const RectangularSliderTrackShape(),
                ),
                child: Slider(
                  semanticFormatterCallback: (value) =>
                      '${l10n(context).mediaPlaybackPosition}: ${_clock(value.round())}',
                  value: shown,
                  max: duration.toDouble(),
                  onChangeStart: canSeek
                      ? (_) => setState(() {
                          _dragging = true;
                          _dragChapter = chapter;
                        })
                      : null,
                  onChanged: canSeek
                      ? (v) => setState(() => _dragMs = v)
                      : null,
                  onChangeEnd: canSeek
                      ? (v) => _seek(
                          chapter?.absolutePosition(v.round()).toDouble() ?? v,
                        )
                      : null,
                ),
              ),
            ),
          ),
          _barTimes(
            left: _clock(shown.round()),
            right: _clock(duration),
            style: timeStyle,
          ),
        ],
      ),
    );
  }
}

/// The line under a now-playing bar: the seek bar's times, or the volume
/// slider's level at the right. Shared so the two blocks are the same
/// height and the bar does not move when one replaces the other (issue
/// #1212). The line always holds text: an empty one rounds its height
/// differently from one with glyphs, a pixel off at some font sizes.
Widget _barTimes({String? left, String? right, required TextStyle style}) {
  Widget time(String text) => Flexible(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, style: style),
    ),
  );
  return Row(
    mainAxisAlignment: left == null
        ? MainAxisAlignment.end
        : MainAxisAlignment.spaceBetween,
    children: [if (left != null) time(left), time(right ?? ' ')],
  );
}

/// Drop shadows for the track details and controls the album art only
/// layout draws over the cover. Tight and nearly opaque, so they read as an edge
/// around the white rather than a glow that a busy cover swallows.
const _overArtShadows = [
  Shadow(color: Color(0xE6000000), offset: Offset(0, 1), blurRadius: 2),
  Shadow(color: Color(0x99000000), blurRadius: 1),
];

/// [child], a now-playing slider, with [shadows] under its track. The
/// track spans the slider less its 16 point overlay radius a side.
Widget _trackShadow({
  required double scale,
  required List<Shadow>? shadows,
  required Widget child,
}) {
  if (shadows == null) return child;
  return Stack(
    fit: StackFit.expand,
    alignment: Alignment.center,
    children: [
      Positioned(
        left: 16 * scale,
        right: 16 * scale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              for (final shadow in shadows)
                BoxShadow(
                  color: shadow.color,
                  offset: shadow.offset,
                  blurRadius: shadow.blurRadius,
                ),
            ],
          ),
          child: SizedBox(height: 4 * scale),
        ),
      ),
      child,
    ],
  );
}

/// Shared by the floating card and the full-screen view: the manager's
/// fetcher, which trusts the Sendspin and Music Assistant hosts.
Future<Uint8List?> fetchSendspinArtwork(AppContainer c, String url) =>
    c.sendspin.loadArtwork(url);

class SendspinPlayerOverlay extends StatefulWidget {
  const SendspinPlayerOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  State<SendspinPlayerOverlay> createState() => _SendspinPlayerOverlayState();
}

class _SendspinPlayerOverlayState extends State<SendspinPlayerOverlay> {
  bool get _large => c.settings.get(defs.sendspinPlayerSize) == 'large';

  /// The title line's trailing badge slot (the equalizer while playing),
  /// constant in both states so the marquee width never changes.
  double get _corner => _large ? 24.0 : 20.0;

  /// The title line's glyph, and the Now Playing badge in the corner.
  double get _badgeSize => _large ? 20.0 : 16.0;
  double get _cardWidth => _large ? 480.0 : 320.0;
  double get _cardHeight => _large ? 152.0 : 96.0;
  double get _artSize => _large ? 128.0 : 72.0;

  AppContainer get c => widget.container;

  bool get _covered => c.screensaver.activeView.value != null;
  bool get _visible =>
      !_covered &&
      c.sendspin.nowPlaying.value != null &&
      !c.sendspin.voiceActive.value &&
      (_override.value ?? c.settings.get(defs.sendspinShowPlayer));

  StreamSubscription<SettingChanged>? _settingsSub;

  void _syncVisuals() {
    final now = c.sendspin.nowPlaying.value;
    final ticking =
        _visible &&
        now?['playing'] == true &&
        ((now?['durationMs'] as num?)?.toInt() ?? 0) > 0;
    if (ticking && _tick == null) {
      _tick = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    } else if (!ticking) {
      _tick?.cancel();
      _tick = null;
    }
    if (_visible) {
      final url = '${now?['artworkUrl'] ?? ''}';
      if (url != _artUrl) _loadArtwork(url);
    }
  }

  void _onVisibility() {
    _syncVisuals();
    if (mounted) setState(() {});
  }

  /// Position as fractions of the free area (screen minus card), 0..1.
  late double _fx, _fy;

  /// Ticks the progress bar between metadata pushes.
  Timer? _tick;

  /// Dismissals and reveals live in [SendspinManager.cardOverride] so the
  /// kiosk menu can read and flip them; this widget owns the transitions.
  /// A fling or the paused-hide timer writes false (hidden until playback
  /// next starts — a paused card is resumable, but it must not squat on
  /// the dashboard forever); the menu or a gesture writes true, which
  /// shows the card even while sendspin.show_player is off.
  ValueNotifier<bool?> get _override => c.sendspin.cardOverride;
  bool _wasPlaying = false;
  Timer? _pausedHide;
  StreamSubscription<SendspinShowPlayerRequested>? _reveal;

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
    c.screensaver.activeView.addListener(_onVisibility);
    _settingsSub = c.bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.sendspinShowPlayer.key) _onVisibility();
    });
    _override.addListener(_onOverride);
    // The "Show the Sendspin player" gesture and the kiosk menu entry: a
    // fling (or the paused-hide timer) hides the card via the override,
    // and the reveal arrives as its own event so it can also clear the
    // paused-hide timer and trigger the queue recovery in the manager.
    _reveal = c.bus.on<SendspinShowPlayerRequested>().listen((_) {
      if (!mounted) return;
      _pausedHide?.cancel();
      _pausedHide = null;
      _override.value = true;
    });
    _onNowPlaying();
  }

  @override
  void dispose() {
    c.sendspin.nowPlaying.removeListener(_onNowPlaying);
    c.sendspin.voiceActive.removeListener(_onVoiceActive);
    c.screensaver.activeView.removeListener(_onVisibility);
    _settingsSub?.cancel();
    _override.removeListener(_onOverride);
    _reveal?.cancel();
    _tick?.cancel();
    _pausedHide?.cancel();
    super.dispose();
  }

  void _onVoiceActive() {
    _onVisibility();
  }

  void _onOverride() {
    _onVisibility();
  }

  void _onNowPlaying() {
    final now = c.sendspin.nowPlaying.value;
    final playing = now?['playing'] == true;
    // A dismissal ends only when playback actually STARTS (false to true
    // transition) or the session ends. Level-checking `playing` here
    // un-dismissed a flung card during the stop's grace window, where the
    // snapshot still reads playing, so it popped back paused. An explicit
    // reveal (override true) survives playback starting — the card was
    // just summoned — but resets with the session like everything else,
    // so a player configured not to pop up stays summoned-per-session.
    if (now == null) {
      _override.value = null;
    } else if (playing && !_wasPlaying && _override.value == false) {
      _override.value = null;
    }
    _wasPlaying = playing;
    if (playing || now == null) {
      _pausedHide?.cancel();
      _pausedHide = null;
    } else {
      _pausedHide ??= Timer(
        Duration(
          minutes: c.settings.get(defs.sendspinPausedHideMinutes).toInt(),
        ),
        () {
          if (mounted) _override.value = false;
        },
      );
    }
    _syncVisuals();
    if (mounted && !_covered) setState(() {});
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
      tooltip: _transportLabel(context, command),
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

  @override
  Widget build(BuildContext context) {
    final now = c.sendspin.nowPlaying.value;
    // Hidden during voice interactions: Voice Satellite's own UI owns the
    // screen for the duration, and the card would sit on top of it.
    if (!_visible || now == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = '${now['title'] ?? l10n(context).mediaPlaying}';
    final artist = [now['artist'], now['album']]
        .where((v) => v != null && '$v'.isNotEmpty)
        .join(' — ')
        .replaceAll(' — ', ' · ');
    final playing = now['playing'] == true;
    // With the Now Playing view enabled, the corner badge is the way to
    // it; without, it stays the state glyph it always was.
    final fullscreen = c.settings.get(defs.sendspinFullscreen);

    // The floating progress follows the same chapter as the full view.
    var duration = (now['durationMs'] as num?)?.toInt() ?? 0;
    var position = playbackPositionMs(
      now,
      DateTime.now().millisecondsSinceEpoch,
    );
    final chapters = audiobookChapters(
      now,
      unnamedChapter: (number) => l10n(context).mediaUnnamedChapter('$number'),
    );
    final chapterIndex = currentChapterIndex(chapters, position, duration);
    if (chapterIndex >= 0) {
      final chapter = chapters[chapterIndex];
      duration = chapter.durationMs;
      position -= chapter.startMs;
    }

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
                onPanEnd: (d) {
                  // A quick fling dismisses the card; a slow release
                  // repositions. No chrome on the card itself: the gesture
                  // everyone tries IS the close button. Flinging away
                  // active playback also stops the music by default — a
                  // dismissed player that keeps playing invisibly would be
                  // worse — unless the user opted into exactly that
                  // (sendspin.dismiss_keeps_playing).
                  if (d.velocity.pixelsPerSecond.distance > 700) {
                    if (playing &&
                        !c.settings.get(defs.sendspinDismissKeepsPlaying)) {
                      c.sendspin.control('stop');
                    }
                    _override.value = false;
                    return;
                  }
                  c.settings.set(
                    defs.sendspinPlayerPos,
                    '${_fx.toStringAsFixed(3)},${_fy.toStringAsFixed(3)}',
                  );
                },
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
                                          cacheWidth:
                                              (_artSize *
                                                      MediaQuery.devicePixelRatioOf(
                                                        context,
                                                      ))
                                                  .ceil(),
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
                                        // with the state. With the Now
                                        // Playing view on, the corner
                                        // badge below takes its place
                                        // and the slot only keeps the
                                        // marquee clear of it.
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: _corner,
                                          child: fullscreen
                                              ? null
                                              : Icon(
                                                  playing
                                                      ? Icons.graphic_eq
                                                      : Icons
                                                            .pause_circle_outline,
                                                  size: _badgeSize,
                                                  color: scheme.primary,
                                                ),
                                        ),
                                      ],
                                    ),
                                    if (artist.isNotEmpty)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _Marquee(
                                              text: artist,
                                              style:
                                                  (_large
                                                          ? theme
                                                                .textTheme
                                                                .bodyMedium
                                                          : theme
                                                                .textTheme
                                                                .bodySmall)
                                                      ?.copyWith(
                                                        color: scheme
                                                            .onSurfaceVariant,
                                                      ),
                                            ),
                                          ),
                                        ],
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
                        // Last, so it sits over the title row: the glyph
                        // there is drawn text and would take the tap.
                        // The badge is inset so its visible corners sit
                        // at the same 12 from the edges as the art
                        // opposite: the glyph fills 14 of its 24 unit
                        // box, so the box is set 5/24 of its size
                        // closer to the corner.
                        if (fullscreen)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                // Out of the dpad's path: with the view
                                // gone, focus would land here and paint
                                // a ring on a card nobody is walking.
                                canRequestFocus: false,
                                onTap: () => c.sendspin.showFullscreen(),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: 12 - _badgeSize * 5 / 24,
                                        right: 12 - _badgeSize * 5 / 24,
                                      ),
                                      child: Icon(
                                        Icons.fullscreen_rounded,
                                        semanticLabel: l10n(
                                          context,
                                        ).mediaShowNowPlaying,
                                        size: _badgeSize,
                                        color: scheme.primary,
                                      ),
                                    ),
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
