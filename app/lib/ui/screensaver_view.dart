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
    final old = _video;
    _video = null;
    await old?.dispose();
    if (!mounted || _files.isEmpty) return;
    setState(() => _index = index % _files.length);
    final file = _files[_index];
    if (_isVideo(file)) {
      final video = VideoPlayerController.file(file);
      _video = video;
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
        if (!mounted) return;
        setState(() {});
        await video.play();
      } catch (e) {
        // A codec the device lacks must not stall the slideshow.
        c.log.warn('screensaver', 'video failed (${file.path}): $e');
        _advance();
      }
    } else {
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
  }

  void _advance() {
    if (!mounted || _files.isEmpty) return;
    _show(_index + 1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return ColoredBox(
      color: Colors.black,
      child: _problem != null
          ? Center(
              child: Text(
                _problem!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : _files.isEmpty
          ? const SizedBox.expand()
          : video != null && video.value.isInitialized
          ? Center(
              child: AspectRatio(
                aspectRatio: video.value.aspectRatio,
                child: VideoPlayer(video),
              ),
            )
          : SizedBox.expand(
              child: Image.file(
                _files[_index],
                key: ValueKey(_files[_index].path),
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.expand(),
              ),
            ),
    );
  }
}
