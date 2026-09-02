import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'glance_row.dart';
import 'lyrics_view.dart';
import 'theme.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../managers/sendspin/music_assistant_api.dart';
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
/// cover; the transport never moves for them.
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
    c.sendspin.lyrics.addListener(_onNowPlaying);
    c.sendspin.lyricsPending.addListener(_onNowPlaying);
    _settingsSub = c.bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.sendspinLyrics.key ||
          e.key == defs.sendspinFullscreenQueue.key) {
        _onNowPlaying();
      }
    });
    // The entity list going from empty to populated (or back) changes the
    // whole layout, not just the row, so the view rebuilds with it.
    c.glance.entities.addListener(_onNowPlaying);
    _onNowPlaying();
  }

  @override
  void dispose() {
    c.sendspin.nowPlaying.removeListener(_onNowPlaying);
    c.sendspin.lyrics.removeListener(_onNowPlaying);
    c.sendspin.lyricsPending.removeListener(_onNowPlaying);
    c.glance.entities.removeListener(_onNowPlaying);
    _settingsSub?.cancel();
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
    // Sized off the panel, not fixed: a 360px cover with 40px type fits a
    // tablet but overflows small panels (the Echo Show's 480px-tall
    // screen). Everything scales from the shortest side and caps at the
    // tablet design sizes; a panel that still does not fit its slot is
    // scaled down as one piece.
    final screen = MediaQuery.sizeOf(context);
    final short = screen.shortestSide;
    final artSize = (short * 0.52).clamp(120.0, 360.0);
    final titleSize = (short * 0.085).clamp(20.0, 40.0);
    final artistSize = (short * 0.047).clamp(13.0, 22.0);
    final gap = (screen.height * 0.05).clamp(12.0, 40.0);
    final controls = c.settings.get(defs.sendspinFullscreenControls);
    final controlsScale = (short / 800).clamp(0.7, 1.0);
    // Double tap to dismiss (issue #409) replaces the close button: the
    // manager runs the tap chain on touches off the controls.
    final doubleTap =
        controls && c.settings.get(defs.sendspinFullscreenDoubleTap);
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
    final landscape = screen.width > screen.height;
    final sideBySide = havePanel && landscape && screen.width >= 560;
    final stacked = havePanel && !landscape && screen.height >= 620;
    // The At a Glance row joins the plain layout only (issue #209): the
    // panel layouts already spend every free pixel on the words.
    final glance =
        !sideBySide &&
        !stacked &&
        c.settings.get(defs.screensaverGlanceNowPlaying) &&
        c.glance.entities.value.isNotEmpty;
    final edge = (screen.width * 0.06).clamp(16.0, 64.0);
    _panelShown = sideBySide || stacked;

    Widget panel() => queue
        ? _ControlTouch(
            container: c,
            child: _QueueView(
              container: c,
              fontSize: (short * 0.035).clamp(14.0, 21.0),
            ),
          )
        : LyricsView(
            container: c,
            fontSize: (short * 0.055).clamp(15.0, 26.0),
            centred: stacked,
          );

    final Widget content;
    if (sideBySide) {
      // Art and words to one side, the panel to the other: a lyric needs
      // the height, and stacking it under a 360px cover leaves room for
      // about two lines.
      content = Padding(
        padding: EdgeInsets.fromLTRB(edge, 12, edge, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: _fitted(
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
                width: artSize * 0.85 * 1.5,
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
      content = Padding(
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
                child: _fitted(
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
      content = Center(
        child: _fitted(
          _trackPanel(
            art: art,
            title: title,
            artist: artist,
            artSize: artSize,
            titleSize: titleSize,
            artistSize: artistSize,
            gap: gap,
            horizontalPadding: 0,
          ),
          width: min(screen.width - 96, artSize * 2.2),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        // Cross-fade the backdrop between songs rather than cutting.
        // Scaled to cover the full screen at its own aspect ratio; the
        // overflow is cropped, which under this much blur is invisible.
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: art == null
                ? const SizedBox.expand(key: ValueKey('no-art'))
                : Image.memory(
                    art,
                    key: ValueKey(_artUrl),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
          ),
        ),
        // Blur + scrim so the backdrop reads as atmosphere, not content.
        if (art != null)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: const ColoredBox(color: Color(0x99000000)),
          ),
        // The content above, the row and the transport pinned below it:
        // the transport keeps its place whatever the content does.
        Column(
          children: [
            Expanded(child: content),
            if (glance)
              Padding(
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: controls
                      ? 4
                      : (screen.height * 0.06).clamp(12.0, 48.0),
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
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Whose music this is, when it is not this device's: the
        // followed player's name in a chip opposite the close button.
        if (c.sendspin.followedPlayerName.isNotEmpty)
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: Material(
                color: Colors.black45,
                shape: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.speaker_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          c.sendspin.followedPlayerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // With the transport up a tap is a button press, so the way out is
        // explicit: the same floating close the page overlays wear. It
        // reports its own source so the manager can tell it from the
        // touches it is holding.
        if (controls && !doubleTap)
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: Material(
                color: Colors.black45,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => c.screensaver.notifyActivity('close'),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.close, color: Colors.white, size: 24),
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
    return AnimatedSwitcher(
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
                width: artSize,
                height: artSize,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            )
          else
            Icon(Icons.music_note, size: artSize * 0.45, color: Colors.white24),
          SizedBox(height: gap),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
          if (artist.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Text(
                artist,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: artistSize,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
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

  @override
  void initState() {
    super.initState();
    container.sendspin.nowPlaying.addListener(_onNowPlaying);
  }

  @override
  void dispose() {
    container.sendspin.nowPlaying.removeListener(_onNowPlaying);
    _pendingTimeout?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onNowPlaying() {
    if (_pendingId == null || !mounted) return;
    final title = '${container.sendspin.nowPlaying.value?['title'] ?? ''}';
    if (title == _pendingTitle) _clearPending();
  }

  void _clearPending() {
    _pendingTimeout?.cancel();
    _pendingTimeout = null;
    if (mounted) setState(() => _pendingId = null);
  }

  Future<void> _play(String id, String title) async {
    if (id.isEmpty) return;
    _pendingTimeout?.cancel();
    setState(() {
      _pendingId = id;
      _pendingTitle = title;
    });
    _pendingTimeout = Timer(const Duration(seconds: 15), () {
      if (_pendingId == id) _clearPending();
    });
    final ok = await container.sendspin.playQueueItem(id);
    if (!ok && _pendingId == id) _clearPending();
  }

  /// Land the Now Playing heading near the top once per queue listing,
  /// on open and again when a track change re-lists it, with half of the
  /// row that just played showing above it: a hint that there is a past
  /// to scroll up to, and a glimpse of what that was.
  void _scrollToNowPlaying(List<Map<String, Object?>> items) {
    if (identical(_scrolledFor, items)) return;
    _scrolledFor = items;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final heading = _nowPlayingKey.currentContext?.findRenderObject();
      if (!mounted || heading is! RenderBox || !_scroll.hasClients) return;
      final viewport = RenderAbstractViewport.of(heading);
      final top = viewport.getOffsetToReveal(heading, 0).offset;
      final played = _lastPlayedKey.currentContext?.findRenderObject();
      final peek = played is RenderBox ? played.size.height / 2 : 0.0;
      final target = (top - peek).clamp(
        _scroll.position.minScrollExtent,
        _scroll.position.maxScrollExtent,
      );
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
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white70,
            fontSize: fontSize * 0.7,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
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
    final titleColor = current
        ? Colors.white
        : played
        ? Colors.white38
        : Colors.white70;
    final subColor = current
        ? Colors.white70
        : played
        ? Colors.white24
        : Colors.white38;
    return InkWell(
      key: key,
      onTap: () => _play(id, '${item['title'] ?? ''}'),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
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
                      fontWeight: current ? FontWeight.w700 : FontWeight.w500,
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
            if (duration > 0) ...[
              const SizedBox(width: 8),
              Text(
                _clock(duration),
                style: TextStyle(
                  color: subColor,
                  fontSize: fontSize * 0.8,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, Object?>>>(
      valueListenable: container.sendspin.queueItems,
      builder: (context, items, _) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'Nothing queued',
              style: TextStyle(color: Colors.white38, fontSize: fontSize),
            ),
          );
        }
        final current = items.indexWhere((it) => it['current'] == true);
        final played = current < 0
            ? const <Map<String, Object?>>[]
            : items.sublist(0, current);
        final upcoming = current < 0 ? items : items.sublist(current + 1);
        _scrollToNowPlaying(items);
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
          // Every row is built, not just the visible ones, so the Now
          // Playing heading has a context to scroll to wherever it sits.
          child: ValueListenableBuilder<int>(
            valueListenable: container.sendspin.queueUpNext,
            builder: (context, upNext, _) => ListView(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                for (final (i, item) in played.indexed)
                  _row(
                    item,
                    key: i == played.length - 1 ? _lastPlayedKey : null,
                  ),
                if (current >= 0) ...[
                  _heading('Now playing', key: _nowPlayingKey),
                  _row(items[current]),
                ],
                _heading('Up next', count: upNext),
                for (final item in upcoming) _row(item),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The Now Playing view's transport (sendspin.fullscreen_controls): the
/// large card's previous, play/pause and next at wall-tablet size, over a
/// progress bar that seeks where the server allows it, flanked by the
/// smaller toggles the way Music Assistant's own player lays them out:
/// favorite and shuffle to the left, lyrics and queue to the right. Its
/// own widget with its own tick, so the position refresh rebuilds these
/// few pixels and not the blurred backdrop behind them.
class _NowPlayingControls extends StatefulWidget {
  const _NowPlayingControls({
    required this.container,
    required this.width,
    required this.scale,
  });

  final AppContainer container;

  /// The bar's width; the buttons center under it.
  final double width;

  /// Everything scales down from the tablet sizes on a small panel.
  final double scale;

  @override
  State<_NowPlayingControls> createState() => _NowPlayingControlsState();
}

class _NowPlayingControlsState extends State<_NowPlayingControls> {
  AppContainer get c => widget.container;

  Timer? _tick;

  /// The thumb while a finger holds it, in ms; null between drags.
  double? _dragMs;

  /// A seek just sent, held on screen until the next position report
  /// replaces it, so the bar does not snap back for the beat the round
  /// trip takes. The local engine adopts the target itself (Music
  /// Assistant sends no fresh progress after a seek), so the report that
  /// replaces this one already agrees with it.
  int? _seekMs;
  int? _seekAt;

  /// The shuffle toggle as just pressed, shown until the server reports
  /// the state again (or reports it unchanged, which means it refused).
  bool? _shuffleOverride;
  bool? _lastShuffle;

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
    _settingsSub?.cancel();
    _tick?.cancel();
    _volumeClose?.cancel();
    _volumeHold?.cancel();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onNowPlaying() {
    final now = c.sendspin.nowPlaying.value;
    final playing = now?['playing'] == true;
    // Any fresh word from the server on shuffle outranks the press.
    final shuffle = now?['shuffle'] == true;
    if (shuffle != _lastShuffle) {
      _lastShuffle = shuffle;
      _shuffleOverride = null;
    }
    // Half a second: the bar moves visibly without the tick showing up in
    // a low-end panel's frame budget.
    if (playing && _tick == null) {
      _tick = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => setState(() {}),
      );
    } else if (!playing) {
      _tick?.cancel();
      _tick = null;
    }
    final receivedAt = (now?['receivedAt'] as num?)?.toInt();
    final seekAt = _seekAt;
    if (seekAt != null && receivedAt != null && receivedAt > seekAt) {
      _seekMs = null;
      _seekAt = null;
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleShuffle(bool on) async {
    setState(() => _shuffleOverride = on);
    final ok = await c.sendspin.setShuffle(on);
    if (!ok && mounted) setState(() => _shuffleOverride = null);
  }

  Future<void> _seek(double ms) async {
    final target = ms.round();
    setState(() {
      _dragMs = null;
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
    final duration = (now['durationMs'] as num?)?.toInt() ?? 0;
    // Live position: the last report plus the wall time since, the way
    // the card and the lyrics extrapolate it; a seek in flight shows its
    // target for at most a few seconds.
    var position = (now['positionMs'] as num?)?.toInt() ?? 0;
    final receivedAt = (now['receivedAt'] as num?)?.toInt();
    final wall = DateTime.now().millisecondsSinceEpoch;
    if (playing && receivedAt != null) position += wall - receivedAt;
    final seekAt = _seekAt;
    if (_seekMs != null && seekAt != null) {
      if (wall - seekAt < 4000) {
        position = _seekMs! + (playing ? wall - seekAt : 0);
      } else {
        _seekMs = null;
        _seekAt = null;
      }
    }
    if (duration > 0) position = position.clamp(0, duration);

    final supported =
        (now['supportedCommands'] as List?)?.map((e) => '$e').toList() ??
        const <String>[];
    bool has(String cmd) => supported.isEmpty || supported.contains(cmd);
    final canSeek = duration > 0 && has('seek');
    final scale = widget.scale;
    final shown = (_dragMs ?? position.toDouble()).clamp(
      0.0,
      duration > 0 ? duration.toDouble() : 0.0,
    );
    final timeStyle = TextStyle(
      color: Colors.white70,
      fontSize: 17 * scale,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget btn(
      IconData icon,
      VoidCallback? onPressed, {
      required double size,
      Color color = Colors.white,
    }) => IconButton(
      icon: Icon(icon, size: size * scale),
      color: color,
      disabledColor: color,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: (size + 16) * scale,
        minHeight: (size + 16) * scale,
      ),
      onPressed: onPressed,
    );
    Widget transport(IconData icon, String command, {required double size}) =>
        btn(icon, () => c.sendspin.control(command), size: size);
    // The four toggles: lit when on, dimmed when off. A missing one
    // leaves its width behind so the transport stays centered under the
    // cover either way.
    const toggleSize = 24.0;
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
            size: toggleSize,
            color: favorite == true
                ? Colors.white
                : favorite == null
                ? Colors.white24
                : Colors.white38,
          )
        : toggleBlank;
    final shuffleOn = _shuffleOverride ?? (now['shuffle'] == true);
    final shuffle = has('shuffle')
        ? btn(
            Icons.shuffle_rounded,
            () => _toggleShuffle(!shuffleOn),
            size: toggleSize,
            color: shuffleOn ? Colors.white : Colors.white38,
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
            size: toggleSize,
            color: lyricsOn ? Colors.white : Colors.white38,
          )
        : toggleBlank;
    final queue = c.sendspin.queueAvailable
        ? btn(
            Icons.queue_music_rounded,
            c.sendspin.toggleQueue,
            size: toggleSize,
            color: queueOpen ? Colors.white : Colors.white38,
          )
        : toggleBlank;
    // The volume toggle leads the left cluster; the right one keeps a
    // blank so the transport stays centered with three slots a side.
    final volumeAvailable = c.sendspin.volumeAvailable;
    final volumeOpen = _volumeOpen && volumeAvailable;
    final level =
        _volumeDrag ?? c.sendspin.volumeLevel?.toDouble().clamp(0.0, 100.0);
    final volume = volumeAvailable
        ? btn(
            volumeOpen ? Icons.volume_up_rounded : Icons.volume_down_rounded,
            _toggleVolume,
            size: toggleSize,
            color: volumeOpen ? Colors.white : Colors.white38,
          )
        : toggleBlank;

    // The bar takes the cover's width, but never less than the row of
    // buttons under it needs: on a small panel the buttons keep their
    // tap targets and the bar widens to match.
    double item(double size) =>
        max((size + 16) * scale, kMinInteractiveDimension);
    final rowWidth =
        item(toggleSize) * 6 +
        item(44) * 2 +
        item(68) +
        (12 * 4 + 20 * 2 + 16 * 2) * scale;
    // Never wider than the screen: a portrait phone shrinks the row of
    // buttons a little instead of overflowing it.
    final maxWidth = MediaQuery.sizeOf(context).width - 24 * scale;
    return SizedBox(
      width: max(widget.width, rowWidth).clamp(0.0, max(maxWidth, 200.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (volumeOpen) ...[
            // The volume in the seek bar's place: the same bar, the level
            // beside it instead of the times.
            SizedBox(
              height: 24 * scale,
              child: Row(
                children: [
                  Icon(
                    Icons.volume_down_rounded,
                    color: Colors.white70,
                    size: 20 * scale,
                  ),
                  Expanded(
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
                  SizedBox(
                    width: 44 * scale,
                    child: Text(
                      level == null ? '' : '${level.round()}%',
                      style: timeStyle,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            // The times row's height, so the transport under it stays put.
            SizedBox(height: 20 * scale),
          ] else if (duration > 0) ...[
            SizedBox(
              height: 24 * scale,
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
                  value: shown,
                  max: duration.toDouble(),
                  onChanged: canSeek
                      ? (v) => setState(() => _dragMs = v)
                      : null,
                  onChangeEnd: canSeek ? _seek : null,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_clock(shown.round()), style: timeStyle),
                Text(_clock(duration), style: timeStyle),
              ],
            ),
          ],
          // The buttons ride up into the tap-target padding above them,
          // so the bar sits close over the transport instead of a line
          // of empty space away.
          Transform.translate(
            offset: Offset(0, -12 * scale),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  volume,
                  SizedBox(width: 12 * scale),
                  heart,
                  SizedBox(width: 12 * scale),
                  shuffle,
                  SizedBox(width: 20 * scale),
                  if (has('previous'))
                    transport(
                      Icons.skip_previous_rounded,
                      'previous',
                      size: 44,
                    ),
                  SizedBox(width: 16 * scale),
                  if (has(playing ? 'pause' : 'play'))
                    transport(
                      playing
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      playing ? 'pause' : 'play',
                      size: 68,
                    ),
                  SizedBox(width: 16 * scale),
                  if (has('next'))
                    transport(Icons.skip_next_rounded, 'next', size: 44),
                  SizedBox(width: 20 * scale),
                  lyrics,
                  SizedBox(width: 12 * scale),
                  queue,
                  SizedBox(width: 12 * scale),
                  toggleBlank,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fetch artwork accepting a bad TLS certificate only for the configured
/// Sendspin server's host or the Music Assistant server's (its image
/// proxy is self-signed, and a remote player's artwork comes from the
/// Music Assistant address, which need not be the Sendspin one).
/// Shared by the floating card and the full-screen view.
Future<Uint8List?> fetchSendspinArtwork(AppContainer c, String url) async {
  if (url.isEmpty) return null;
  try {
    final serverHost = Uri.parse(
      'ws://${c.settings.get(defs.sendspinServer).trim()}',
    ).host;
    final maHost =
        Uri.tryParse(
          musicAssistantWebUrl(c.settings.get(defs.sendspinMaUrl)) ?? '',
        )?.host ??
        '';
    final client = HttpClient()
      ..badCertificateCallback = (cert, host, port) =>
          host.isNotEmpty && (host == serverHost || host == maHost);
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

  /// The title line's trailing badge slot (the equalizer while playing),
  /// constant in both states so the marquee width never changes.
  double get _corner => _large ? 24.0 : 20.0;
  double get _cardWidth => _large ? 480.0 : 320.0;
  double get _cardHeight => _large ? 152.0 : 96.0;
  double get _artSize => _large ? 128.0 : 72.0;

  AppContainer get c => widget.container;

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
    _override.removeListener(_onOverride);
    _reveal?.cancel();
    _tick?.cancel();
    _pausedHide?.cancel();
    super.dispose();
  }

  void _onVoiceActive() {
    if (mounted) setState(() {});
  }

  void _onOverride() {
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

  @override
  Widget build(BuildContext context) {
    final now = c.sendspin.nowPlaying.value;
    // Hidden during voice interactions: Voice Satellite's own UI owns the
    // screen for the duration, and the card would sit on top of it.
    if (now == null ||
        c.sendspin.voiceActive.value ||
        !(_override.value ?? c.settings.get(defs.sendspinShowPlayer))) {
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
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: _corner,
                                          child: Icon(
                                            playing
                                                ? Icons.graphic_eq
                                                : Icons.pause_circle_outline,
                                            size: _large ? 20 : 16,
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
