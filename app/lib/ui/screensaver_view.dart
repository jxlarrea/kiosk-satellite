import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:video_player/video_player.dart';

import '../app_container.dart';
import '../managers/settings/definitions.dart' as defs;

/// The screensaver overlay: whichever of the four views the manager says is
/// active, or nothing.
///
/// Black and clock render natively — the lightest possible thing on a weak
/// panel. Media and website go through a WebView, reusing Chromium's video,
/// image and WebRTC exactly as Voice Satellite does, rather than pulling native
/// decoders into the app. A tap anywhere dismisses.
class ScreensaverOverlay extends StatelessWidget {
  const ScreensaverOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: container.screensaver.activeView,
      builder: (context, view, _) {
        if (view == null) return const SizedBox.shrink();
        return Positioned.fill(
          child: switch (view) {
            'clock' => _Dismissable(
              container: container,
              child: ClockScreensaver(container: container),
            ),
            'media' ||
            'website' => ScreensaverWebView(container: container, mode: view),
            'local' || 'gallery' => _Dismissable(
              container: container,
              child: LocalMediaScreensaver(container: container, mode: view),
            ),
            // 'black' and anything unexpected: the safe, opaque cover.
            _ => _Dismissable(
              container: container,
              child: const ColoredBox(color: Colors.black),
            ),
          },
        );
      },
    );
  }
}

/// Tap anywhere to wake. Used by the native views; the WebView reports its own
/// taps over the JS bridge, since it swallows Flutter gestures.
class _Dismissable extends StatelessWidget {
  const _Dismissable({required this.container, required this.child});

  final AppContainer container;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => container.screensaver.notifyActivity('touch'),
    child: child,
  );
}

/// A full-screen digital clock over black, mirroring Voice Satellite's clock.
/// The clock's font, preferring the system Google Sans where it exists.
///
/// On Pixel/GMS devices Google Sans is a registered system family, so we ask
/// for it first (under the couple of names it ships as). Everywhere it is
/// absent — the Samsung tablets, the LineageOS Echo — the request falls
/// through to the bundled [Rubik], which gives the same geometric feel. Rubik
/// stays last so any real Google Sans wins.
const _clockFontFamily = 'Google Sans';
const _clockFontFallback = <String>[
  'Google Sans Text',
  'Product Sans',
  'Rubik',
];

class ClockScreensaver extends StatefulWidget {
  const ClockScreensaver({super.key, required this.container});

  final AppContainer container;

  @override
  State<ClockScreensaver> createState() => _ClockScreensaverState();
}

class _ClockScreensaverState extends State<ClockScreensaver> {
  Timer? _tick;
  Timer? _shift;
  DateTime _now = DateTime.now();
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _scheduleTick();
    if (widget.container.settings.get(defs.screensaverPixelShift)) {
      // Nudge the whole face once a minute so a static clock cannot burn in.
      _shift = Timer.periodic(const Duration(minutes: 1), (_) => _nudge());
    }
  }

  // Re-align to each wall-clock second rather than drifting off a fixed period.
  void _scheduleTick() {
    final ms = DateTime.now().millisecondsSinceEpoch % 1000;
    _tick = Timer(Duration(milliseconds: 1000 - ms), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _scheduleTick();
    });
  }

  void _nudge() {
    if (!mounted) return;
    final r = Random();
    const max = 24.0;
    setState(
      () => _offset = Offset(
        (r.nextDouble() * 2 - 1) * max,
        (r.nextDouble() * 2 - 1) * max,
      ),
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    _shift?.cancel();
    super.dispose();
  }

  Color _color() {
    final raw = widget.container.settings.get(defs.screensaverClockColor);
    final parts = raw.split(',').map((p) => int.tryParse(p.trim())).toList();
    if (parts.length == 3 && parts.every((p) => p != null)) {
      return Color.fromARGB(255, parts[0]!, parts[1]!, parts[2]!);
    }
    return const Color(0xFFFAFAFA);
  }

  String _time() {
    final s = widget.container.settings;
    final h24 = s.get(defs.screensaverClock24h);
    final secs = s.get(defs.screensaverClockSeconds);
    final h = h24 ? _now.hour : (_now.hour % 12 == 0 ? 12 : _now.hour % 12);
    final hh = h24 ? h.toString().padLeft(2, '0') : h.toString();
    final mm = _now.minute.toString().padLeft(2, '0');
    var t = '$hh:$mm';
    if (secs) t += ':${_now.second.toString().padLeft(2, '0')}';
    if (!h24) t += _now.hour < 12 ? ' AM' : ' PM';
    return t;
  }

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _date() =>
      '${_weekdays[_now.weekday - 1]}, ${_months[_now.month - 1]} ${_now.day}';

  @override
  Widget build(BuildContext context) {
    final s = widget.container.settings;
    final scale = (s.get(defs.screensaverClockScale) / 100).clamp(0.5, 3.0);
    final color = _color();
    final size = MediaQuery.of(context).size;
    // min(20vw, 30vh), the same basis Voice Satellite uses, then scaled.
    final clockSize = min(size.width * 0.20, size.height * 0.30) * scale;
    final dateSize = min(size.width * 0.05, size.height * 0.07) * scale;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Transform.translate(
          offset: _offset,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _time(),
                style: TextStyle(
                  fontFamily: _clockFontFamily,
                  fontFamilyFallback: _clockFontFallback,
                  color: color,
                  fontSize: clockSize,
                  fontWeight: FontWeight.w300,
                  letterSpacing: clockSize * 0.02,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1.0,
                ),
              ),
              if (s.get(defs.screensaverClockDate)) ...[
                SizedBox(height: clockSize * 0.1),
                Text(
                  _date(),
                  style: TextStyle(
                    fontFamily: _clockFontFamily,
                    fontFamilyFallback: _clockFontFallback,
                    // The date sits back a little, as in VS (~65% of the clock).
                    color: color.withValues(alpha: 0.65),
                    fontSize: dateSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Media and website, rendered by a bundled HTML page in its own WebView.
///
/// The page ports Voice Satellite's screensaver: an iframe for a website, and
/// for media the whole HA playlist path — browse, resolve, image slideshow,
/// video, and camera WebRTC with an MJPEG fallback — using Chromium's native
/// engines. We hand it the HA URL and token and the chosen options; it does the
/// rest and calls back on a tap so we can dismiss.
class ScreensaverWebView extends StatefulWidget {
  const ScreensaverWebView({
    super.key,
    required this.container,
    required this.mode,
  });

  final AppContainer container;
  final String mode;

  @override
  State<ScreensaverWebView> createState() => _ScreensaverWebViewState();
}

class _ScreensaverWebViewState extends State<ScreensaverWebView> {
  late final String _configJson = _buildConfig();

  String _buildConfig() {
    final s = widget.container.settings;
    return jsonEncode({
      'mode': widget.mode,
      'haUrl': widget.container.homeAssistant.baseUrl,
      'haToken': s.get(defs.haToken),
      'websiteUrl': s.get(defs.screensaverWebsiteUrl),
      'mediaId': s.get(defs.screensaverMediaId),
      'mediaIntervalSeconds': s.get(defs.screensaverMediaInterval),
      'mediaShuffle': s.get(defs.screensaverMediaShuffle),
      'mediaRecursive': s.get(defs.screensaverMediaRecursive),
      'mediaTransition': s.get(defs.screensaverMediaTransition),
      'pixelShift': s.get(defs.screensaverPixelShift),
    });
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialFile: 'assets/screensaver/index.html',
      initialUserScripts: UnmodifiableListView([
        // The config has to exist before the page's own script runs.
        UserScript(
          source: 'window.__ksScreensaver = $_configJson;',
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      ]),
      initialSettings: InAppWebViewSettings(
        transparentBackground: false,
        // The page shows only remote media/website content; no reason to let it
        // navigate the app anywhere.
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
      ),
      onReceivedServerTrustAuthRequest: (controller, challenge) async {
        // Same policy as the kiosk WebView: the media screensaver talks to
        // the same self-signed Home Assistant.
        if (widget.container.settings.get(defs.ignoreSslErrors)) {
          return ServerTrustAuthResponse(
            action: ServerTrustAuthResponseAction.PROCEED,
          );
        }
        return ServerTrustAuthResponse(
          action: ServerTrustAuthResponseAction.CANCEL,
        );
      },
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: 'dismiss',
          callback: (_) {
            widget.container.screensaver.notifyActivity('touch');
            return null;
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'log',
          callback: (args) {
            widget.container.log.info(
              'screensaver',
              args.isNotEmpty ? '${args.first}' : '',
            );
            return null;
          },
        );
      },
    );
  }
}

/// The Local Media screensaver: photos and videos from a folder on this
/// device, no Home Assistant involved. Photos hold for the configured
/// interval; videos play to their end (muted — a screensaver that suddenly
/// has a voice at 2am is a defect, not a feature). The listing is read once
/// per activation: a screensaver session is short, and re-listing between
/// slides would hitch exactly when nothing should.
class LocalMediaScreensaver extends StatefulWidget {
  const LocalMediaScreensaver({
    super.key,
    required this.container,
    required this.mode,
  });

  final AppContainer container;

  /// 'local' cycles a folder; 'gallery' cycles the hand-picked selection
  /// (app-storage copies listed in screensaver.gallery_items).
  final String mode;

  @override
  State<LocalMediaScreensaver> createState() => _LocalMediaScreensaverState();
}

class _LocalMediaScreensaverState extends State<LocalMediaScreensaver> {
  static const _imageExt = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'};
  static const _videoExt = {'.mp4', '.webm', '.mkv', '.mov', '.3gp'};

  List<File> _files = const [];
  int _index = 0;
  Timer? _timer;
  VideoPlayerController? _video;

  /// Set when the folder is missing, unreadable, or empty — the message is
  /// the screensaver then, because a silently black screen looks like a
  /// crash and teaches nothing.
  String? _problem;

  AppContainer get c => widget.container;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _gallery => widget.mode == 'gallery';

  Future<void> _load() async {
    if (_gallery) {
      var files = <File>[];
      try {
        files = [
          for (final p in jsonDecode(
            c.settings.get(defs.screensaverGalleryItems),
          ) as List)
            File(p as String),
        ];
      } catch (_) {}
      files = [for (final f in files) if (f.existsSync()) f];
      if (files.isEmpty) {
        setState(
          () => _problem = 'No photos selected. Pick some in Settings.',
        );
        return;
      }
      if (c.settings.get(defs.screensaverGalleryShuffle)) {
        files.shuffle(Random());
      }
      setState(() => _files = files);
      _show(0);
      return;
    }
    final folder = c.settings.get(defs.screensaverLocalFolder);
    if (folder.isEmpty) {
      setState(() => _problem = 'No folder selected. Pick one in Settings.');
      return;
    }
    try {
      final recursive = c.settings.get(defs.screensaverLocalRecursive);
      final files = <File>[];
      await for (final entry in Directory(
        folder,
      ).list(recursive: recursive, followLinks: false)) {
        if (entry is! File) continue;
        final dot = entry.path.lastIndexOf('.');
        if (dot < 0) continue;
        final ext = entry.path.substring(dot).toLowerCase();
        if (_imageExt.contains(ext) || _videoExt.contains(ext)) {
          files.add(entry);
        }
      }
      if (files.isEmpty) {
        setState(() => _problem = 'No photos or videos in $folder');
        return;
      }
      if (c.settings.get(defs.screensaverLocalShuffle)) {
        files.shuffle(Random());
      } else {
        files.sort((a, b) => a.path.compareTo(b.path));
      }
      if (!mounted) return;
      setState(() => _files = files);
      _show(0);
    } catch (e) {
      c.log.warn('screensaver', 'local media listing failed: $e');
      if (mounted) {
        setState(
          () => _problem =
              'Could not read $folder — is the '
              'media permission granted?',
        );
      }
    }
  }

  bool _isVideo(File f) {
    final dot = f.path.lastIndexOf('.');
    return dot >= 0 && _videoExt.contains(f.path.substring(dot).toLowerCase());
  }

  Future<void> _show(int index) async {
    _timer?.cancel();
    _rolled = _randomPool[_rand.nextInt(_randomPool.length)];
    // The outgoing video is not disposed here: it has to keep rendering
    // while the transition plays it out. _retire parks it until the
    // hand-off is over.
    final old = _video;
    _video = null;
    if (!mounted || _files.isEmpty) {
      await old?.dispose();
      return;
    }
    final next = index % _files.length;
    final file = _files[next];
    if (_isVideo(file)) {
      // The previous slide holds the screen while the video spins up —
      // _index only moves once there are frames to hand off to.
      final video = VideoPlayerController.file(file);
      try {
        await video.initialize();
        await video.setVolume(0);
        video.addListener(() {
          final v = video.value;
          if (v.isInitialized &&
              !v.isPlaying &&
              v.position >= v.duration &&
              v.duration > Duration.zero) {
            _advance();
          }
        });
        if (!mounted) {
          await video.dispose();
          await old?.dispose();
          return;
        }
        _video = video;
        setState(() => _index = next);
        await video.play();
      } catch (e) {
        // A codec the device lacks must not stall the slideshow. Skip past
        // `next` explicitly — _index never reached it, and retrying it
        // forever would loop on the same broken file.
        c.log.warn('screensaver', 'video failed (${file.path}): $e');
        await video.dispose();
        if (mounted) unawaited(_show(next + 1));
        await old?.dispose();
        return;
      }
    } else {
      setState(() => _index = next);
      final seconds = c.settings
          .get(
            _gallery
                ? defs.screensaverGalleryInterval
                : defs.screensaverLocalInterval,
          )
          .toInt()
          .clamp(2, 3600);
      _timer = Timer(Duration(seconds: seconds), _advance);
    }
    _retire(old);
  }

  /// Outgoing video controllers live until every transition that could
  /// still be painting them has finished, then die.
  final _retiring = <VideoPlayerController>[];

  void _retire(VideoPlayerController? old) {
    if (old == null) return;
    _retiring.add(old);
    Timer(const Duration(milliseconds: 1200), () {
      _retiring.remove(old);
      old.dispose();
    });
  }

  void _advance() {
    if (!mounted || _files.isEmpty) return;
    _show(_index + 1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _video?.dispose();
    for (final v in _retiring) {
      v.dispose();
    }
    super.dispose();
  }

  static final _rand = Random();
  static const _randomPool = ['fade', 'slide', 'zoom', 'kenburns'];

  /// The transition Random rolled for the hand-off now on screen. Rolled
  /// once per slide change so both sides of one hand-off move the same way.
  String _rolled = 'fade';

  String get _transition {
    final setting = c.settings.get(
      _gallery
          ? defs.screensaverGalleryTransition
          : defs.screensaverLocalTransition,
    );
    return setting == 'random' ? _rolled : setting;
  }

  static Duration _switchDuration(String transition) => switch (transition) {
    'slide' => const Duration(milliseconds: 450),
    'zoom' => const Duration(milliseconds: 600),
    'kenburns' => const Duration(milliseconds: 800),
    _ => const Duration(milliseconds: 500),
  };

  Widget _handOff(
    String transition,
    Key currentKey,
    Widget child,
    Animation<double> animation,
  ) {
    switch (transition) {
      case 'slide':
        // A push: the newcomer enters from the right while the incumbent
        // leaves left. The outgoing child's animation runs in reverse, so
        // its zero-target tween walks it off the opposite edge.
        final tween = child.key == currentKey
            ? Tween(begin: const Offset(1, 0), end: Offset.zero)
            : Tween(begin: const Offset(-1, 0), end: Offset.zero);
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      case 'zoom':
        // One shared tween reads as a zoom-through: the newcomer settles
        // down from 1.08 as the incumbent, reversed, swells into it.
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation.drive(Tween(begin: 1.08, end: 1.0)),
            child: child,
          ),
        );
      default: // fade — and the crossfade half of Ken Burns
        return FadeTransition(opacity: animation, child: child);
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    Widget body;
    if (_problem != null) {
      body = Center(
        child: Text(
          _problem!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    } else if (_files.isEmpty) {
      body = const SizedBox.expand();
    } else {
      final transition = _transition;
      final isVideoSlide = video != null && video.value.isInitialized;
      // The index is in the key so a repeated file still hands off.
      final key = ValueKey('$_index:${_files[_index].path}');
      final Widget inner = isVideoSlide
          ? Center(
              child: AspectRatio(
                aspectRatio: video.value.aspectRatio,
                child: VideoPlayer(video),
              ),
            )
          : SizedBox.expand(
              child: Image.file(
                _files[_index],
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.expand(),
              ),
            );
      final Widget slide = transition == 'kenburns' && !isVideoSlide
          // Stills drift for the whole hold; videos supply their own
          // motion and just crossfade (the default branch of _handOff).
          ? _KenBurnsDrift(
              key: key,
              index: _index,
              duration:
                  Duration(
                    seconds: c.settings
                        .get(
                          _gallery
                              ? defs.screensaverGalleryInterval
                              : defs.screensaverLocalInterval,
                        )
                        .toInt()
                        .clamp(2, 3600),
                  ) +
                  const Duration(seconds: 2),
              child: inner,
            )
          : KeyedSubtree(key: key, child: inner);
      body = transition == 'none'
          ? slide
          : ClipRect(
              child: AnimatedSwitcher(
                duration: _switchDuration(transition),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                // StackFit.expand: with only positioned/animated children a
                // plain Stack can collapse to nothing (the kiosk screen
                // learned this the hard way).
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, animation) =>
                    _handOff(transition, key, child, animation),
                child: slide,
              ),
            );
    }
    return ColoredBox(color: Colors.black, child: body);
  }
}

/// The Ken Burns drift: a slow constant-velocity zoom anchored to a corner,
/// a different corner each slide so consecutive photos drift different
/// ways. The controller runs the full hold plus the hand-off, so the motion
/// never freezes while the photo is still on screen.
class _KenBurnsDrift extends StatefulWidget {
  const _KenBurnsDrift({
    super.key,
    required this.index,
    required this.duration,
    required this.child,
  });

  final int index;
  final Duration duration;
  final Widget child;

  @override
  State<_KenBurnsDrift> createState() => _KenBurnsDriftState();
}

class _KenBurnsDriftState extends State<_KenBurnsDrift>
    with SingleTickerProviderStateMixin {
  static const _anchors = [
    Alignment.topLeft,
    Alignment.bottomRight,
    Alignment.topRight,
    Alignment.bottomLeft,
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.1 * _controller.value,
        alignment: _anchors[widget.index % _anchors.length],
        child: child,
      ),
      child: widget.child,
    ),
  );
}
