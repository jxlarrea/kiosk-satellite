import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
            'media' || 'website' => ScreensaverWebView(
                container: container,
                mode: view,
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
    setState(() => _offset =
        Offset((r.nextDouble() * 2 - 1) * max, (r.nextDouble() * 2 - 1) * max));
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
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'
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
            widget.container.log
                .info('screensaver', args.isNotEmpty ? '${args.first}' : '');
            return null;
          },
        );
      },
    );
  }
}
