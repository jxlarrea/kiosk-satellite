import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

import '../app_container.dart';
import '../managers/screensaver/immich_manager.dart' show ImmichAsset;
import '../managers/settings/definitions.dart' as defs;
import 'sendspin_player_overlay.dart' show SendspinFullscreenView;

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
        return ValueListenableBuilder<Map<String, Object?>?>(
          valueListenable: container.sendspin.nowPlaying,
          builder: (context, nowPlaying, child) {
            // Music playing with the full-screen player enabled: the
            // screensaver slot shows the now-playing view instead of the
            // configured mode, dismissed exactly like any screensaver.
            // Falls back live when playback ends mid-screensaver; a track
            // merely PAUSED gets the regular screensaver, not a frozen
            // now-playing panel.
            if (nowPlaying?['playing'] == true &&
                container.settings.get(defs.sendspinFullscreen)) {
              return Positioned.fill(
                child: _Dismissable(
                  container: container,
                  child: SendspinFullscreenView(container: container),
                ),
              );
            }
            return child!;
          },
          child: Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                switch (view) {
                  'clock' => _Dismissable(
                    container: container,
                    child: ClockScreensaver(container: container),
                  ),
                  'media' || 'website' => ScreensaverWebView(
                    container: container,
                    mode: view,
                  ),
                  'local' || 'gallery' => _Dismissable(
                    container: container,
                    child: LocalMediaScreensaver(
                      container: container,
                      mode: view,
                    ),
                  ),
                  'immich' => _Dismissable(
                    container: container,
                    child: ImmichScreensaver(container: container),
                  ),
                  // 'black' and anything unexpected: the safe, opaque cover.
                  _ => _Dismissable(
                    container: container,
                    child: const ColoredBox(color: Colors.black),
                  ),
                },
                // The small corner clock rides over every mode except Clock,
                // which is a clock already.
                if (view != 'clock' &&
                    container.settings.get(defs.screensaverMiniClock))
                  MiniClockOverlay(container: container),
              ],
            ),
          ),
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

/// The corner an overlay setting names, as an alignment. Shared by the small
/// clock and the Immich metadata panel so "top_left" means the same place to
/// both.
Alignment _cornerAlignment(String corner) => switch (corner) {
  'top_left' => Alignment.topLeft,
  'bottom_left' => Alignment.bottomLeft,
  'bottom_right' => Alignment.bottomRight,
  _ => Alignment.topRight,
};

/// A soft radial darkening anchored to [corner], painted behind a corner
/// overlay so its text survives a bright photo. Radial rather than a boxed
/// gradient: it fades out in every direction, so there is no rectangle edge
/// to catch the eye.
Widget _cornerVignette(Alignment corner, {double radius = 0.7}) =>
    DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: corner,
          radius: radius,
          // Front-loaded: still ~half black a third of the way out, so the
          // text area is solidly backed before the long fade begins.
          colors: const [
            Color(0xB3000000),
            Color(0x80000000),
            Color(0x00000000),
          ],
          stops: [0, 0.35, 1],
        ),
      ),
      child: const SizedBox.expand(),
    );

/// The small corner clock, shown over every screensaver mode except Clock.
/// Minute-aligned ticks (it shows no seconds), a soft shadow so it reads on
/// photos and video alike, and — with pixel shift on — the same slow nudge
/// the big clock does, since a static bright corner is exactly how OLED
/// burn-in starts.
class MiniClockOverlay extends StatefulWidget {
  const MiniClockOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  State<MiniClockOverlay> createState() => _MiniClockOverlayState();
}

class _MiniClockOverlayState extends State<MiniClockOverlay> {
  Timer? _tick;
  DateTime _now = DateTime.now();
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  // Re-align to each wall-clock minute rather than drifting off a period.
  void _scheduleTick() {
    final now = DateTime.now();
    final toNextMinute = Duration(
      seconds: 60 - now.second,
      milliseconds: -now.millisecond,
    );
    _tick = Timer(toNextMinute, () {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
        if (widget.container.settings.get(defs.screensaverPixelShift)) {
          final r = Random();
          const max = 10.0;
          _offset = Offset(
            (r.nextDouble() * 2 - 1) * max,
            (r.nextDouble() * 2 - 1) * max,
          );
        }
      });
      _scheduleTick();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Color _color() {
    final raw = widget.container.settings.get(defs.screensaverMiniClockColor);
    final parts = raw.split(',').map((p) => int.tryParse(p.trim())).toList();
    if (parts.length == 3 && parts.every((p) => p != null)) {
      return Color.fromARGB(255, parts[0]!, parts[1]!, parts[2]!);
    }
    return const Color(0xFFFAFAFA);
  }

  String _time() {
    final h24 = widget.container.settings.get(defs.screensaverClock24h);
    final h = h24 ? _now.hour : (_now.hour % 12 == 0 ? 12 : _now.hour % 12);
    final hh = h24 ? h.toString().padLeft(2, '0') : h.toString();
    final mm = _now.minute.toString().padLeft(2, '0');
    var t = '$hh:$mm';
    if (!h24) t += _now.hour < 12 ? ' AM' : ' PM';
    return t;
  }

  static const _shortWeekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _date() =>
      '${_shortWeekdays[_now.weekday - 1]}, '
      '${_shortMonths[_now.month - 1]} ${_now.day}';

  @override
  Widget build(BuildContext context) {
    final s = widget.container.settings;
    final corner = _cornerAlignment(s.get(defs.screensaverMiniClockPosition));
    final color = _color();
    final size = MediaQuery.of(context).size;
    // Proportional to the panel, but floored: on a small low-density screen
    // (the Echo Show 5's 480 logical pixels) the proportional size lands
    // near the metadata's fixed-pixel text and reads absurdly small for a
    // clock.
    final clockSize = max(min(size.width, size.height) * 0.063, 44.0);
    // Readable over a bright photo without boxing the text in.
    const shadows = [Shadow(color: Colors.black54, blurRadius: 8)];
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _cornerVignette(corner),
          Align(
            alignment: corner,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Transform.translate(
                offset: _offset,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: corner.x < 0
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    Text(
                      _time(),
                      style: TextStyle(
                        // Always the bundled Rubik, not the big clock's
                        // system-font preference: the small overlays should
                        // render identically on every device.
                        fontFamily: 'Rubik',
                        color: color,
                        fontSize: clockSize,
                        fontWeight: FontWeight.w400,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        height: 1.0,
                        shadows: shadows,
                      ),
                    ),
                    if (s.get(defs.screensaverMiniClockDate))
                      Padding(
                        padding: EdgeInsets.only(top: clockSize * 0.05),
                        child: Text(
                          _date(),
                          style: TextStyle(
                            fontFamily: 'Rubik',
                            color: color.withValues(alpha: 0.75),
                            fontSize: clockSize * 0.42,
                            fontWeight: FontWeight.w400,
                            shadows: shadows,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
          for (final p
              in jsonDecode(c.settings.get(defs.screensaverGalleryItems))
                  as List)
            File(p as String),
        ];
      } catch (_) {}
      files = [
        for (final f in files)
          if (f.existsSync()) f,
      ];
      if (files.isEmpty) {
        setState(() => _problem = 'No photos selected. Pick some in Settings.');
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
              'Could not read $folder. Is the '
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

/// The Immich Media screensaver: the playlist comes from the Immich server
/// once per activation, images arrive as screen-sized previews (through the
/// local cache when enabled), videos stream muted and play in full. The next
/// image is prefetched while the current one holds, so a hand-off never
/// waits on the network.
class ImmichScreensaver extends StatefulWidget {
  const ImmichScreensaver({super.key, required this.container});

  final AppContainer container;

  @override
  State<ImmichScreensaver> createState() => _ImmichScreensaverState();
}

class _ImmichScreensaverState extends State<ImmichScreensaver> {
  List<ImmichAsset> _assets = const [];
  int _index = 0;
  Uint8List? _imageBytes;

  /// Width over height of the current image, or null when unknown; feeds
  /// the fill-the-screen decision.
  double? _imageAspect;
  Timer? _timer;
  VideoPlayerController? _video;
  String? _problem;

  /// The next image slide, fetched during the current hold.
  int? _prefetchedIndex;
  Uint8List? _prefetchedBytes;

  /// Consecutive fetch failures; a whole playlist of them means the server
  /// went away, and the message should say so instead of skipping forever.
  int _failures = 0;

  AppContainer get c => widget.container;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!c.settings.get(defs.screensaverImmichValidated)) {
      setState(
        () => _problem = 'Immich is not connected. Validate it in Settings.',
      );
      return;
    }
    try {
      final assets = await c.immich.listAssets();
      if (assets.isEmpty) {
        setState(() => _problem = 'No media in the selected source.');
        return;
      }
      if (c.settings.get(defs.screensaverImmichShuffle)) {
        assets.shuffle(Random());
      }
      if (!mounted) return;
      setState(() => _assets = assets);
      _show(0);
    } catch (e) {
      c.log.warn('screensaver', 'immich listing failed: $e');
      if (mounted) {
        setState(
          () => _problem =
              'Could not reach the Immich server. It will retry next time.',
        );
      }
    }
  }

  Future<void> _show(int index) async {
    _timer?.cancel();
    _rolled = _randomPool[_rand.nextInt(_randomPool.length)];
    final old = _video;
    _video = null;
    if (!mounted || _assets.isEmpty) {
      await old?.dispose();
      return;
    }
    if (_failures >= _assets.length || _failures >= 20) {
      setState(() => _problem = 'Could not reach the Immich server.');
      await old?.dispose();
      return;
    }
    final next = index % _assets.length;
    final asset = _assets[next];
    if (asset.isVideo) {
      // Streamed, never cached; the previous slide holds until frames exist.
      final video = VideoPlayerController.networkUrl(
        c.immich.videoUri(asset),
        httpHeaders: c.immich.videoHeaders,
      );
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
        _failures = 0;
        _video = video;
        setState(() {
          _index = next;
          _imageBytes = null;
        });
        await video.play();
      } catch (e) {
        c.log.warn('screensaver', 'immich video failed (${asset.id}): $e');
        await video.dispose();
        _failures++;
        if (mounted) unawaited(_show(next + 1));
        await old?.dispose();
        return;
      }
    } else {
      Uint8List bytes;
      try {
        bytes = (_prefetchedIndex == next && _prefetchedBytes != null)
            ? _prefetchedBytes!
            : await c.immich.imageBytes(asset);
      } catch (e) {
        c.log.warn('screensaver', 'immich image failed (${asset.id}): $e');
        _failures++;
        if (mounted) unawaited(_show(next + 1));
        await old?.dispose();
        return;
      }
      final aspect = await _aspectOf(bytes);
      if (!mounted) {
        await old?.dispose();
        return;
      }
      _failures = 0;
      setState(() {
        _index = next;
        _imageBytes = bytes;
        _imageAspect = aspect;
      });
      final seconds = c.settings
          .get(defs.screensaverImmichInterval)
          .toInt()
          .clamp(2, 3600);
      _timer = Timer(Duration(seconds: seconds), _advance);
      unawaited(_prefetch(next + 1));
    }
    _retire(old);
  }

  /// The image's aspect ratio read from its header — no full decode, so it
  /// costs microseconds, not a second of jank before every slide.
  static Future<double?> _aspectOf(Uint8List bytes) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      try {
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        final aspect = descriptor.width / descriptor.height;
        descriptor.dispose();
        return aspect;
      } finally {
        buffer.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  /// Pull the next image into memory during the current hold. Videos are
  /// skipped: they stream, and warming them means downloading them. The
  /// metadata lookup is warmed for both, so the overlay appears with the
  /// slide instead of trailing it.
  Future<void> _prefetch(int index) async {
    if (_assets.isEmpty) return;
    final next = index % _assets.length;
    final asset = _assets[next];
    if (c.settings.get(defs.screensaverImmichMetadata)) {
      unawaited(c.immich.assetDetails(asset));
    }
    if (asset.isVideo || _prefetchedIndex == next) return;
    try {
      final bytes = await c.immich.imageBytes(asset);
      if (!mounted) return;
      _prefetchedIndex = next;
      _prefetchedBytes = bytes;
    } catch (_) {
      // The show path retries and reports; a failed warm-up is not news.
    }
  }

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
    if (!mounted || _assets.isEmpty) return;
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
  String _rolled = 'fade';

  String get _transition {
    final setting = c.settings.get(defs.screensaverImmichTransition);
    return setting == 'random' ? _rolled : setting;
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
    } else if (_imageBytes == null && video == null) {
      body = const SizedBox.expand();
    } else {
      final transition = _transition;
      final isVideoSlide = video != null && video.value.isInitialized;
      final key = ValueKey('$_index:${_assets[_index].id}');
      // Fill the screen: photos shaped close enough to the panel are
      // cover-fitted edge to edge. "Close enough" caps the crop at roughly
      // a quarter along one axis (1.45x ratio mismatch) — it admits the
      // common cases (4:3 or 16:9 camera frames on a 16:10 panel, either
      // orientation) while portrait and square photos on a landscape
      // screen keep their full frame, exactly the shots a crop would gut.
      // Those framed photos get the photo itself, blurred and dimmed, as
      // the backdrop instead of black bars — the Now Playing treatment.
      final fillWanted =
          !isVideoSlide && c.settings.get(defs.screensaverImmichFill);
      var covers = false;
      if (fillWanted && _imageAspect != null) {
        final size = MediaQuery.of(context).size;
        final screen = size.width / size.height;
        final photo = _imageAspect!;
        covers = max(photo / screen, screen / photo) <= 1.45;
      }
      final Widget inner;
      if (isVideoSlide) {
        inner = Center(
          child: AspectRatio(
            aspectRatio: video.value.aspectRatio,
            child: VideoPlayer(video),
          ),
        );
      } else {
        final picture = Image.memory(
          _imageBytes!,
          fit: covers ? BoxFit.cover : BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.expand(),
        );
        inner = fillWanted && !covers
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    _imageBytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const SizedBox.expand(),
                  ),
                  // Blur + scrim so the backdrop reads as atmosphere, not
                  // a second copy of the photo (sendspin_player_overlay
                  // established the recipe).
                  BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: const ColoredBox(color: Color(0x99000000)),
                  ),
                  picture,
                ],
              )
            : SizedBox.expand(child: picture);
      }
      final Widget slide = transition == 'kenburns' && !isVideoSlide
          ? _KenBurnsDrift(
              key: key,
              index: _index,
              duration:
                  Duration(
                    seconds: c.settings
                        .get(defs.screensaverImmichInterval)
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
    final showMetadata =
        _problem == null &&
        _assets.isNotEmpty &&
        (_imageBytes != null || video != null) &&
        c.settings.get(defs.screensaverImmichMetadata);
    return ColoredBox(
      color: Colors.black,
      child: showMetadata
          ? Stack(
              fit: StackFit.expand,
              children: [
                body,
                _ImmichMetadata(
                  key: ValueKey('meta:${_assets[_index].id}'),
                  container: c,
                  asset: _assets[_index],
                ),
              ],
            )
          : body,
    );
  }
}

/// The metadata panel in a corner of the Immich screensaver: album, date,
/// camera and location, shadow-on-photo text like the small clock, and only
/// the lines the asset actually carries. Instant when the lookup was
/// prefetched; otherwise it appears as soon as the server answers.
class _ImmichMetadata extends StatelessWidget {
  const _ImmichMetadata({
    super.key,
    required this.container,
    required this.asset,
  });

  final AppContainer container;
  final ImmichAsset asset;

  @override
  Widget build(BuildContext context) {
    final corner = _cornerAlignment(
      container.settings.get(defs.screensaverImmichMetadataPosition),
    );
    const shadows = [Shadow(color: Colors.black54, blurRadius: 8)];
    TextStyle style({double size = 16, FontWeight? weight, double alpha = 1}) =>
        TextStyle(
          fontFamily: 'Rubik',
          color: Colors.white.withValues(alpha: alpha),
          fontSize: size,
          fontWeight: weight ?? FontWeight.w400,
          shadows: shadows,
          height: 1.35,
        );
    return IgnorePointer(
      child: FutureBuilder<Map<String, String>>(
        future: container.immich.assetDetails(asset),
        builder: (context, snapshot) {
          final details = snapshot.data;
          if (details == null || details.isEmpty) {
            return const SizedBox.shrink();
          }
          // One icon per row; the two camera lines (model and exposure)
          // share the exif icon as a single logical entry.
          Widget row(String icon, List<Widget> texts) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/svg/$icon.svg',
                width: 15,
                height: 15,
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.85),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 9),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: texts,
              ),
            ],
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              _cornerVignette(corner, radius: 0.6),
              Align(
                alignment: corner,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 10,
                    crossAxisAlignment: corner.x < 0
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      if (details['album'] != null)
                        row('album', [
                          Text(
                            details['album']!,
                            style: style(size: 18, weight: FontWeight.w600),
                          ),
                        ]),
                      if (details['date'] != null)
                        row('calendar', [
                          Text(details['date']!, style: style(alpha: 0.9)),
                        ]),
                      if (details['settings'] != null)
                        row('exif', [
                          Text(details['settings']!, style: style(alpha: 0.8)),
                        ]),
                      if (details['location'] != null)
                        row('location', [
                          Text(details['location']!, style: style(alpha: 0.9)),
                        ]),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Slideshow hand-off machinery, shared by every slideshow mode ──
// (local folder, photo gallery, Immich): one vocabulary of transitions,
// identical motion whichever source feeds the slides.

const _randomPool = ['fade', 'slide', 'zoom', 'kenburns'];

Duration _switchDuration(String transition) => switch (transition) {
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
      return SlideTransition(position: animation.drive(tween), child: child);
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
