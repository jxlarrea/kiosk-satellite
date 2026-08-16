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
import '../core/events.dart';
import '../core/locale_dates.dart';
import '../managers/browser/ha_session_script.dart';
import '../managers/browser/vs_suppress_script.dart';
import '../managers/home_assistant/kiosk_mode.dart';
import '../managers/home_assistant/home_assistant_manager.dart'
    show GlanceSubscription;
import '../managers/screensaver/immich_manager.dart' show ImmichAsset;
import '../managers/screensaver/screensaver_widgets.dart';
import '../managers/settings/definitions.dart' as defs;
import 'camera_view_overlay.dart' show ClosingCameraPlayer;
import 'clock_faces.dart';
import 'glance_row.dart';
import 'sendspin_player_overlay.dart' show SendspinFullscreenView;

/// The screensaver overlay: whichever of the four views the manager says is
/// active, or nothing.
///
/// Black and clock render natively — the lightest possible thing on a weak
/// panel. Media and website go through a WebView, reusing Chromium's video,
/// image and WebRTC exactly as Voice Satellite does, rather than pulling native
/// decoders into the app. A tap anywhere dismisses.
class ScreensaverOverlay extends StatefulWidget {
  const ScreensaverOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  State<ScreensaverOverlay> createState() => _ScreensaverOverlayState();
}

class _ScreensaverOverlayState extends State<ScreensaverOverlay> {
  StreamSubscription<SettingChanged>? _widgetsSub;

  AppContainer get container => widget.container;

  @override
  void initState() {
    super.initState();
    // Editing the Widgets group while the screensaver shows (the remote
    // admin can) applies immediately: the widget list is read at build,
    // so a changed list needs this rebuild to mount or unmount overlays.
    // The scaling slider rides along and doubles as a live preview.
    _widgetsSub = container.bus.on<SettingChanged>().listen((e) {
      if ((e.key == defs.screensaverWidgets.key ||
              e.key == defs.screensaverWidgetScale.key) &&
          mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _widgetsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: container.screensaver.activeView,
      builder: (context, view, _) {
        if (view == null) return const SizedBox.shrink();
        // A Black screensaver asked to look off (issue #151): one switch
        // blanks the overlays instead of asking people to unconfigure the
        // small clock and At a Glance row for the night.
        final blackBare = view == 'black' &&
            container.settings.get(defs.screensaverBlackHideExtras);
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
                  // The camera grid reports its own touches (the WebView
                  // swallows Flutter gestures), so it dismisses itself
                  // rather than sitting under _Dismissable.
                  'camera' => CameraScreensaver(container: container),
                  // 'black' and anything unexpected: the safe, opaque cover,
                  // carrying the At a Glance row when there is one — unless
                  // the active schedule entry withholds it for its hours,
                  // the same override the corner widgets have.
                  _ => _Dismissable(
                    container: container,
                    child: ValueListenableBuilder<bool?>(
                      valueListenable: container.screensaver.scheduleGlance,
                      builder: (context, scheduled, _) =>
                          !blackBare &&
                              (scheduled ??
                                  container.settings.get(
                                    defs.screensaverGlanceEnabled,
                                  ))
                          ? GlanceScreensaver(container: container)
                          : const ColoredBox(color: Colors.black),
                    ),
                  ),
                },
                // The corner widgets ride over every mode their type
                // allows (the small clock stays off Clock, which is one
                // already, and the camera grid, where it sits over a live
                // feed). The active schedule entry can withhold them for
                // its hours — widgets by day, a bare screen at night —
                // which is why they hang off their own listenable: a
                // boundary between two entries of the same mode changes
                // nothing else this widget rebuilds on.
                if (!blackBare)
                  ValueListenableBuilder<bool?>(
                    valueListenable: container.screensaver.scheduleWidgets,
                    builder: (context, scheduled, _) => Stack(
                      fit: StackFit.expand,
                      children: [
                        if (scheduled ?? true)
                          for (final spec in decodeScreensaverWidgets(
                            container.settings.get(defs.screensaverWidgets),
                          ))
                            if (screensaverWidgetAllowedOnMode(spec.type, view))
                              switch (spec.type) {
                                'clock' => ClockWidgetOverlay(
                                  container: container,
                                  spec: spec,
                                ),
                                'weather' => WeatherWidgetOverlay(
                                  container: container,
                                  spec: spec,
                                ),
                                _ => const SizedBox.shrink(),
                              },
                      ],
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
  /// How far the At a Glance row sits above the bottom edge, as a fraction
  /// of the display height. Measured from the display, not from the clock,
  /// so the clock's size slider cannot move it.
  static const _glanceBottomInset = 0.06;

  /// Where the clock block sits while the row is showing. It gives up the
  /// centre so the two are not crowded, matching the mockups in issue #37.
  static const _clockAnchorWithGlance = -0.2;

  Timer? _tick;
  Timer? _shift;
  DateTime _now = DateTime.now();
  Offset _offset = Offset.zero;

  /// The background photo, resolved off the path setting: the provider and
  /// the aspect its fill treatment keys off. [_bgPath] is what they were
  /// resolved FROM, so a changed path re-resolves and an unchanged one
  /// costs nothing per rebuild.
  String? _bgPath;
  double? _bgAspect;
  ImageProvider? _bgImage;
  StreamSubscription<SettingChanged>? _bgSub;

  @override
  void initState() {
    super.initState();
    _scheduleTick();
    if (widget.container.settings.get(defs.screensaverPixelShift)) {
      // Nudge the whole face once a minute so a static clock cannot burn in.
      _shift = Timer.periodic(const Duration(minutes: 1), (_) => _nudge());
    }
    // The face only rebuilds on clock ticks, a minute apart with seconds
    // off — a background pushed over MQTT (issue #150) must not wait out
    // the minute.
    _bgSub = widget.container.bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.screensaverClockBackground.key && mounted) {
        setState(() {});
      }
    });
  }

  // Re-align to each wall-clock second (or minute, when seconds are not
  // shown — the face only changes once a minute then, and a per-second
  // rebuild would be 60x the wakeups for identical pixels) rather than
  // drifting off a fixed period.
  void _scheduleTick() {
    final now = DateTime.now();
    // Seconds only exist on the digital face. The flip face changes once a
    // minute, so ticking it per second would be 60x the wakeups (and 60x
    // the flip animations) for identical output; the roller runs its own
    // per-frame ticker and ignores this timer entirely.
    final s = widget.container.settings;
    final secs = s.get(defs.screensaverClockStyle) == 'digital' &&
        s.get(defs.screensaverClockSeconds);
    final delay = secs
        ? Duration(milliseconds: 1000 - now.millisecond)
        : Duration(
            milliseconds: 60000 - now.second * 1000 - now.millisecond,
          );
    _tick = Timer(delay, () {
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
    _bgSub?.cancel();
    super.dispose();
  }

  Color _rgb(defs.SettingDef<String> def, Color orElse) {
    final raw = widget.container.settings.get(def);
    final parts = raw.split(',').map((p) => int.tryParse(p.trim())).toList();
    if (parts.length == 3 && parts.every((p) => p != null)) {
      return Color.fromARGB(255, parts[0]!, parts[1]!, parts[2]!);
    }
    return orElse;
  }

  Color _color() => _rgb(defs.screensaverClockColor, const Color(0xFFFAFAFA));

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

  // Localized via the device locale, names and word order both (issue #108):
  // "Sunday, August 2" on an American device, "zondag 2 augustus" on a
  // Dutch one.
  String _date() => fullDate(_now);

  /// Re-resolve the background provider when the path setting moved. A
  /// missing file resolves to nothing but is not marked seen, so a path
  /// published before its file lands (issue #150) starts showing on the
  /// rebuild after the file appears; a restore onto another device, whose
  /// setting names a copy that never came along, just keeps the solid
  /// color instead of taking the clock down.
  void _ensureBackground(String path, Size size, double dpr) {
    if (path == _bgPath) return;
    if (path.isEmpty) {
      _bgPath = path;
      _bgAspect = null;
      _bgImage = null;
      return;
    }
    final file = File(path);
    if (!file.existsSync()) {
      _bgPath = null;
      _bgAspect = null;
      _bgImage = null;
      return;
    }
    _bgPath = path;
    unawaited(() async {
      // The header read costs one pass over the file, but the bytes are
      // hot in the page cache when FileImage decodes them, and knowing
      // the aspect up front means the fill decision never flickers.
      double? aspect;
      try {
        aspect = await _aspectOf(await file.readAsBytes());
      } catch (_) {}
      if (!mounted || _bgPath != path) return;
      final old = _bgImage;
      setState(() {
        _bgAspect = aspect;
        // Decoded at screen resolution, not the photo's — a 12MP shot
        // would otherwise hold ~50MB of texture for the session.
        _bgImage = ResizeImage(
          FileImage(file),
          width: (size.width * dpr).round(),
        );
      });
      if (old != null) unawaited(old.evict());
    }());
  }

  /// The background photo layers, or nothing when none is set. Fill the
  /// screen, always on, the same recipe as the photo screensavers (issue
  /// #130): a photo shaped close enough to the panel is cover-fitted edge
  /// to edge (crop capped at a 1.45x ratio mismatch), one that keeps its
  /// full frame gets itself, blurred and dimmed, as the backdrop instead
  /// of black bars. The scrim on top keeps the clock and the row readable
  /// over either.
  List<Widget> _background(Size size, double dpr) {
    _ensureBackground(
      widget.container.settings.get(defs.screensaverClockBackground),
      size,
      dpr,
    );
    final image = _bgImage;
    if (image == null) return const [];
    final screen = size.width / size.height;
    final photo = _bgAspect;
    // An unreadable aspect (odd format) falls back to the cover fit the
    // clock always used.
    final covers =
        photo == null || max(photo / screen, screen / photo) <= 1.45;
    final picture = Image(
      image: image,
      fit: covers ? BoxFit.cover : BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    return [
      if (covers)
        picture
      else
        Stack(
          fit: StackFit.expand,
          children: [
            // Blur + scrim so the backdrop reads as atmosphere, not a
            // second copy of the photo. ImageFiltered over the same
            // provider, not BackdropFilter: a backdrop filter re-samples
            // the scene every frame it composites, which on weak tablet
            // GPUs is a standing 60fps blur tax.
            RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: 40,
                      sigmaY: 40,
                      tileMode: ui.TileMode.clamp,
                    ),
                    child: Image(
                      image: image,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => const SizedBox.expand(),
                    ),
                  ),
                  const ColoredBox(color: Color(0x99000000)),
                ],
              ),
            ),
            picture,
          ],
        ),
      const ColoredBox(color: Color(0x59000000)),
    ];
  }

  /// The center of the face for the non-digital styles (issue #56). The
  /// shell around it — glance row, pixel shift, anchor — is shared, so the
  /// style only swaps what sits in the middle.
  Widget _styledFace(String style, double scale) {
    if (style == 'flip') {
      return FlipClockFace(
        now: _now,
        use24h: widget.container.settings.get(defs.screensaverClock24h),
        digitColor:
            _rgb(defs.screensaverFlipDigitColor, const Color(0xFF212121)),
        cardColor: _rgb(defs.screensaverFlipBgColor, const Color(0xFFF5F5F5)),
        scale: scale,
      );
    }
    return RollerClockFace(
      use24h: widget.container.settings.get(defs.screensaverClock24h),
      digitColor:
          _rgb(defs.screensaverRollerDigitColor, const Color(0xFFFAFAFA)),
      scale: scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.container.settings;
    final style = s.get(defs.screensaverClockStyle);
    final scale = (s.get(defs.screensaverClockScale) / 100).clamp(0.5, 3.0);
    final color = _color();
    final size = MediaQuery.of(context).size;
    // The At a Glance row sits under the clock and needs room for itself,
    // so the clock gives some back rather than pushing the row off a short
    // panel. Only when the row actually has something to show.
    final glance = widget.container.glance.entities.value.isNotEmpty;
    final glanceScale = min(1.0, size.height / 480).clamp(0.75, 1.0);
    final clockShrink = glance ? 0.72 : 1.0;
    // min(20vw, 30vh), the same basis Voice Satellite uses, then scaled.
    final clockSize =
        min(size.width * 0.20, size.height * 0.30) * scale * clockShrink;
    final dateSize =
        min(size.width * 0.05, size.height * 0.07) * scale * clockShrink;

    return ColoredBox(
      color: switch (style) {
        'roller' => _rgb(defs.screensaverRollerBgColor, Colors.black),
        // The flip backdrop follows the card color (see flipBackdrop).
        'flip' => flipBackdrop(
            _rgb(defs.screensaverFlipBgColor, const Color(0xFFF5F5F5))),
        _ => _rgb(defs.screensaverClockBgColor, Colors.black),
      },
      // Expand: both children are pinned to the display, so the stack must
      // be the display rather than sized to whatever the clock happens to
      // measure.
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The background photo (issue #132), under everything, on any
          // face. Decoded at screen resolution, not the photo's — a 12MP
          // shot would otherwise hold ~50MB of texture for the whole
          // screensaver session. The scrim keeps the clock and the row
          // readable over whatever the photo happens to be.
          ..._background(size, MediaQuery.devicePixelRatioOf(context)),
          // The row is pinned to the bottom of the display, NOT laid out
          // below the clock. Stacked under it, its position moved with the
          // clock's height, so turning the size slider up walked the row
          // down the screen and off the bottom by about 130%. Pinned, the
          // slider only ever resizes the clock.
          if (glance)
            Positioned(
              left: 0,
              right: 0,
              bottom: size.height * _glanceBottomInset,
              child: GlanceRow(
                container: widget.container,
                scale: glanceScale,
                // The row wears the face's digit color so it reads as part
                // of the clock — and stays legible on every face, whose
                // backdrops all follow the user's colors now (issue #173:
                // a white backdrop under grey-on-black glance rows).
                tint: switch (style) {
                  'flip' => _rgb(
                      defs.screensaverFlipDigitColor, const Color(0xFF212121)),
                  'roller' => _rgb(defs.screensaverRollerDigitColor,
                      const Color(0xFFFAFAFA)),
                  _ => _color(),
                },
              ),
            ),
          Align(
            alignment: Alignment(0, glance ? _clockAnchorWithGlance : 0),
            child: Transform.translate(
              offset: _offset,
              child: style != 'digital'
                  ? _styledFace(style, scale * clockShrink)
                  : Column(
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
        ],
      ),
    );
  }
}

/// The At a Glance row on its own, centred: the Black screensaver has no
/// clock to hang it under, so the row is the whole display.
class GlanceScreensaver extends StatelessWidget {
  const GlanceScreensaver({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GlanceRow(
            container: container,
            scale: min(1.0, height / 480).clamp(0.75, 1.25),
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
          // Front-loaded: still ~60% black well past a third of the way
          // out, so the text area is solidly backed before the long fade
          // begins. 80% at the corner itself: anything lighter left the
          // widgets washing out on bright daylight photos.
          colors: const [
            Color(0xCC000000),
            Color(0x99000000),
            Color(0x00000000),
          ],
          stops: [0, 0.4, 1],
        ),
      ),
      child: const SizedBox.expand(),
    );

/// The small clock widget, shown over every screensaver mode except Clock.
/// Minute-aligned ticks (it shows no seconds), a soft shadow so it reads on
/// photos and video alike, and — with pixel shift on — the same slow nudge
/// the big clock does, since a static bright corner is exactly how OLED
/// burn-in starts.
class ClockWidgetOverlay extends StatefulWidget {
  const ClockWidgetOverlay({
    super.key,
    required this.container,
    required this.spec,
  });

  final AppContainer container;
  final ScreensaverWidget spec;

  @override
  State<ClockWidgetOverlay> createState() => _ClockWidgetOverlayState();
}

class _ClockWidgetOverlayState extends State<ClockWidgetOverlay> {
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

  String _time() {
    final h24 = widget.spec.config['h24'] == true;
    final h = h24 ? _now.hour : (_now.hour % 12 == 0 ? 12 : _now.hour % 12);
    final hh = h24 ? h.toString().padLeft(2, '0') : h.toString();
    final mm = _now.minute.toString().padLeft(2, '0');
    var t = '$hh:$mm';
    if (!h24) t += _now.hour < 12 ? ' AM' : ' PM';
    return t;
  }

  // Localized like the big clock's date (issue #108): "Sun, Aug 2" or
  // "zo 2 aug", per the device locale.
  String _date() => shortDate(_now);

  @override
  Widget build(BuildContext context) {
    final corner = _cornerAlignment(widget.spec.position);
    final color = _widgetRgb(widget.spec.config['color']);
    final size = MediaQuery.of(context).size;
    // Proportional to the panel, but floored: on a small low-density screen
    // (the Echo Show 5's 480 logical pixels) the proportional size lands
    // near the metadata's fixed-pixel text and reads absurdly small for a
    // clock. The Widget scaling slider then corrects for the screen.
    final scale =
        widget.container.settings.get(defs.screensaverWidgetScale).toDouble() /
        100;
    final clockSize = max(min(size.width, size.height) * 0.063, 44.0) * scale;
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
                        // render identically on every device. Proportional
                        // figures, not tabular: the block hugs its corner
                        // (the outer edge cannot jitter), and a leading 1's
                        // tabular side-bearing left the time visibly
                        // indented against its own date line.
                        fontFamily: 'Rubik',
                        color: color,
                        fontSize: clockSize,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                        shadows: shadows,
                      ),
                    ),
                    if (widget.spec.config['date'] == true)
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

/// A widget's "r,g,b" color, falling back to the overlays' near-white.
Color _widgetRgb(Object? raw) {
  final parts = '$raw'.split(',').map((p) => int.tryParse(p.trim())).toList();
  if (parts.length == 3 && parts.every((p) => p != null)) {
    return Color.fromARGB(255, parts[0]!, parts[1]!, parts[2]!);
  }
  return const Color(0xFFFAFAFA);
}

/// The weather widget: one Home Assistant weather entity in a corner —
/// the location name, a big temperature, the forecast with its icon, and
/// optional humidity, wind and visibility lines, each shown only when its
/// toggle is on AND the entity actually carries the reading. Fed by its
/// own subscribe_entities socket while the screensaver shows (the At a
/// Glance pattern), so the readings stay live without polling.
class WeatherWidgetOverlay extends StatefulWidget {
  const WeatherWidgetOverlay({
    super.key,
    required this.container,
    required this.spec,
  });

  final AppContainer container;
  final ScreensaverWidget spec;

  @override
  State<WeatherWidgetOverlay> createState() => _WeatherWidgetOverlayState();
}

class _WeatherWidgetOverlayState extends State<WeatherWidgetOverlay> {
  GlanceSubscription? _live;
  Timer? _retry;
  Timer? _shift;
  Offset _offset = Offset.zero;

  /// Last known state and attributes, merged across updates: the
  /// subscription diffs, so attributes only arrive when they change.
  String _condition = '';
  final Map<String, Object?> _attributes = {};
  bool _haveData = false;

  /// The friendlier description some integrations publish as a sensor
  /// next to the weather entity ("overcast clouds" vs "cloudy"); shown on
  /// the forecast line when it reports, while the icon always follows
  /// the condition.
  String _forecastText = '';

  /// OpenWeatherMap's naming; a missing companion simply never reports.
  String? _companion(String entity) {
    final parts = entity.split('.');
    return parts.length == 2 ? 'sensor.${parts[1]}_weather' : null;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_open());
    // The same slow OLED-protecting nudge the small clock does.
    _shift = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!widget.container.settings.get(defs.screensaverPixelShift)) return;
      final r = Random();
      const max = 10.0;
      setState(() {
        _offset = Offset(
          (r.nextDouble() * 2 - 1) * max,
          (r.nextDouble() * 2 - 1) * max,
        );
      });
    });
  }

  Future<void> _open() async {
    final entity = '${widget.spec.config['entity'] ?? ''}';
    if (entity.isEmpty) return;
    final live = await widget.container.homeAssistant.subscribeEntities(
      [entity, ?_companion(entity)],
      _onState,
    );
    if (!mounted) {
      unawaited(live?.close());
      return;
    }
    if (live == null) {
      // Home Assistant unreachable, mid-restart, whatever: keep showing
      // what we last knew and try again shortly (the At a Glance cadence).
      _retry?.cancel();
      _retry = Timer(const Duration(seconds: 20), () {
        if (mounted) unawaited(_open());
      });
      return;
    }
    // A socket that dies after establishing reopens after a beat; the
    // delay keeps a flapping server from turning this into a tight loop.
    live.onClosed = () {
      if (!mounted || _live != live) return;
      _retry?.cancel();
      _retry = Timer(const Duration(seconds: 5), () {
        if (mounted) unawaited(_open());
      });
    };
    _live = live;
  }

  void _onState(String entityId, Map<String, Object?> state) {
    if (!mounted) return;
    setState(() {
      final s = state['state'];
      if (entityId.startsWith('sensor.')) {
        if (s is String) {
          _forecastText = (s == 'unavailable' || s == 'unknown') ? '' : s;
        }
        return;
      }
      if (s is String) _condition = s;
      final attrs = state['attributes'];
      if (attrs is Map) {
        _attributes.addAll(attrs.map((k, v) => MapEntry('$k', v)));
      }
      _haveData = true;
    });
  }

  // A live edit can repoint the widget at another entity; the element is
  // reused in place, so the subscription has to follow by hand.
  @override
  void didUpdateWidget(WeatherWidgetOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ('${oldWidget.spec.config['entity']}' !=
        '${widget.spec.config['entity']}') {
      _retry?.cancel();
      final live = _live;
      _live = null;
      if (live != null) unawaited(live.close());
      _attributes.clear();
      _condition = '';
      _forecastText = '';
      _haveData = false;
      unawaited(_open());
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    _shift?.cancel();
    final live = _live;
    _live = null;
    if (live != null) unawaited(live.close());
    super.dispose();
  }

  bool _on(String key) => widget.spec.config[key] == true;

  num? _num(String key) {
    final value = _attributes[key];
    return value is num ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    // Nothing sensible to draw before the first snapshot, or while the
    // entity itself is gone.
    if (!_haveData ||
        _condition == 'unavailable' ||
        _condition == 'unknown') {
      return const SizedBox.shrink();
    }
    final corner = _cornerAlignment(widget.spec.position);
    final color = _widgetRgb(widget.spec.config['color']);
    final size = MediaQuery.of(context).size;
    // The temperature is exactly the small clock's size, and the location
    // and detail lines take the Immich metadata panel's fixed sizes, so
    // the corner overlays all read as one family. The Widget scaling
    // slider then corrects everything for the screen.
    final scale =
        widget.container.settings.get(defs.screensaverWidgetScale).toDouble() /
        100;
    final tempSize =
        max(min(size.width, size.height) * 0.063, 44.0) * scale;
    const shadows = [Shadow(color: Colors.black54, blurRadius: 8)];

    TextStyle line({
      double size = 16,
      FontWeight? weight,
      double alpha = 0.9,
    }) => TextStyle(
      fontFamily: 'Rubik',
      color: color.withValues(alpha: alpha),
      fontSize: size * scale,
      fontWeight: weight ?? FontWeight.w400,
      shadows: shadows,
      height: 1.2,
    );

    // One reading with its monochrome icon, tinted like the text. The
    // icon sits on the corner's outer edge — left corners lead with it,
    // right corners trail — so the icon column stays flush however long
    // the readings run.
    final right = corner.x > 0;
    Widget detail(String value, IconData icon) {
      final glyph = Icon(
        icon,
        size: 16 * scale,
        color: color.withValues(alpha: 0.85),
        shadows: shadows,
      );
      final text = Text(value, style: line());
      final gap = SizedBox(width: 9 * scale);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: right ? [text, gap, glyph] : [glyph, gap, text],
      );
    }

    String reading(num value, String unitKey) {
      final unit = '${_attributes[unitKey] ?? ''}';
      return unit.isEmpty ? '${value.round()}' : '${value.round()} $unit';
    }

    final temperature = _num('temperature');
    final humidity = _num('humidity');
    final wind = _num('wind_speed');
    final visibility = _num('visibility');
    // The place is named by hand (weather entities carry no city
    // attribute, and their names are integration names); left empty, the
    // line simply stays off.
    final location = '${widget.spec.config['label'] ?? ''}'.trim();

    final align = corner.x < 0
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.end;
    // The readings sit in their own tighter column, so the list reads as
    // one block under the temperature rather than four spaced lines.
    final details = <Widget>[
      if (_on('forecast') && _condition.isNotEmpty)
        detail(
          _forecastText.isNotEmpty
              ? _sentenceCase(_forecastText)
              : _conditionLabel(_condition),
          _conditionIcon(_condition),
        ),
      if (_on('humidity') && humidity != null)
        detail('${humidity.round()}%', Icons.water_drop_outlined),
      if (_on('wind') && wind != null)
        detail(reading(wind, 'wind_speed_unit'), Icons.air),
      if (_on('visibility') && visibility != null)
        detail(reading(visibility, 'visibility_unit'),
            Icons.visibility_outlined),
    ];
    final lines = <Widget>[
      if (_on('location') && location.isNotEmpty)
        Text(location, style: line(size: 18, weight: FontWeight.w600,
            alpha: 1)),
      if (temperature != null)
        Text(
          '${temperature.round()}${_attributes['temperature_unit'] ?? '°'}',
          // Proportional figures, not tabular: the block hugs its corner,
          // so a leading 1's tabular side-bearing would only read as the
          // number sitting off the lines around it.
          style: TextStyle(
            fontFamily: 'Rubik',
            color: color,
            fontSize: tempSize,
            fontWeight: FontWeight.w400,
            height: 1.0,
            shadows: shadows,
          ),
        ),
      if (details.isNotEmpty)
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          crossAxisAlignment: align,
          children: details,
        ),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();

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
                  spacing: 6,
                  crossAxisAlignment: align,
                  children: lines,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _sentenceCase(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Home Assistant's weather conditions as readable text; conditions this
/// map does not know just clean up (dashes out, first letter up).
String _conditionLabel(String condition) => switch (condition) {
  'clear-night' => 'Clear night',
  'cloudy' => 'Cloudy',
  'exceptional' => 'Severe weather',
  'fog' => 'Fog',
  'hail' => 'Hail',
  'lightning' => 'Lightning',
  'lightning-rainy' => 'Thunderstorms',
  'partlycloudy' => 'Partly cloudy',
  'pouring' => 'Pouring',
  'rainy' => 'Rainy',
  'snowy' => 'Snowy',
  'snowy-rainy' => 'Sleet',
  'sunny' => 'Sunny',
  'windy' => 'Windy',
  'windy-variant' => 'Windy',
  _ => _sentenceCase(condition).replaceAll('-', ' '),
};

/// Monochrome Material glyphs for the conditions, tinted with the widget
/// color exactly like the text.
IconData _conditionIcon(String condition) => switch (condition) {
  'clear-night' => Icons.nights_stay,
  'cloudy' => Icons.cloud,
  'exceptional' => Icons.storm,
  'fog' => Icons.foggy,
  'hail' => Icons.grain,
  'lightning' => Icons.bolt,
  'lightning-rainy' => Icons.thunderstorm,
  'partlycloudy' => Icons.wb_cloudy,
  'pouring' => Icons.umbrella,
  'rainy' => Icons.umbrella,
  'snowy' => Icons.ac_unit,
  'snowy-rainy' => Icons.ac_unit,
  'sunny' => Icons.wb_sunny,
  'windy' || 'windy-variant' => Icons.air,
  _ => Icons.cloud,
};

/// Media and website, rendered in their own WebView.
///
/// Media loads a bundled HTML page porting Voice Satellite's screensaver:
/// the whole HA playlist path — browse, resolve, image slideshow, video,
/// and camera WebRTC with an MJPEG fallback — using Chromium's native
/// engines. We hand it the HA URL and token and the chosen options; it
/// does the rest and calls back on a tap so we can dismiss.
///
/// A website loads TOP-LEVEL, not through the bundled page's iframe
/// (issue #118): sites gated by a SameSite=Lax/Strict session cookie
/// (DAKboard private URLs) serve their login page to a cross-site
/// subframe — the WebView withholds third-party cookies there, and Lax
/// cookies never flow into one anyway. First-party top-level navigation
/// shares the app's cookie jar and renders like the dashboard WebView.
/// The bundled page's tap-to-dismiss and pixel shift come along as
/// injected scripts.
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

  /// The live controller, for re-asserting kiosk mode on it.
  InAppWebViewController? _webView;

  /// Kiosk mode changing while a Home Assistant page is on screen applies to
  /// it there and then, exactly as it does on the dashboard.
  StreamSubscription<SettingChanged>? _kioskSub;

  Future<void> _applyKiosk(InAppWebViewController controller) async {
    final settings = widget.container.settings;
    await controller.evaluateJavascript(
      source: kioskModeApplyJs(
        apply: settings.get(defs.haKioskMode),
        hideHeader: settings.get(defs.haKioskHideHeader),
        hideSidebar: settings.get(defs.haKioskHideSidebar),
      ),
    );
  }

  /// Bumped to recreate the WebView after its renderer dies. Without the
  /// onRenderProcessGone handler below, Android answers a renderer death
  /// in an unhandling WebView by killing the whole app — the dashboard
  /// WebView has survived that path for a long time while this one, on
  /// low-RAM devices exactly when the screensaver recomposites, had not.
  int _epoch = 0;

  /// One pending retry at a time for a website that failed to load (the
  /// network dropped mid-session). Previously an error page just sat for
  /// the whole session; a paced reload brings the site back on its own.
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    _kioskSub = widget.container.bus.on<SettingChanged>().listen((e) {
      if (e.key != defs.haKioskMode.key &&
          e.key != defs.haKioskHideHeader.key &&
          e.key != defs.haKioskHideSidebar.key) {
        return;
      }
      final controller = _webView;
      if (controller != null) unawaited(_applyKiosk(controller));
    });
  }

  @override
  void dispose() {
    _retry?.cancel();
    _kioskSub?.cancel();
    super.dispose();
  }

  void _scheduleRetry(InAppWebViewController controller, String why) {
    if (_retry?.isActive ?? false) return;
    widget.container.log.warn('screensaver', '$why; retrying in 10s');
    _retry = Timer(const Duration(seconds: 10), () {
      if (mounted) unawaited(controller.reload());
    });
  }

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

  /// Any tap dismisses, like every screensaver. The WebView swallows
  /// Flutter's gestures, so the page reports the tap itself; capture
  /// phase and every frame, so a site that stops propagation (or hosts
  /// its content in its own iframes) still dismisses.
  static const _dismissScript = '''
document.addEventListener('pointerdown', function () {
  if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
    window.flutter_inappwebview.callHandler('dismiss');
  }
}, true);''';

  /// The bundled page's burn-in shift, applied to the site's root instead.
  static const _pixelShiftScript = '''
setInterval(function () {
  var max = Math.min(24, window.innerWidth * 0.015);
  var x = (Math.random() * 2 - 1) * max, y = (Math.random() * 2 - 1) * max;
  document.documentElement.style.transform =
      'translate(' + x + 'px,' + y + 'px)';
}, 60000);''';

  /// The dashboard's Home Assistant session for [url], when the site shown
  /// here is that same Home Assistant. Null for anywhere else: a stranger's
  /// site never sees these credentials.
  String? _haSessionScript(String url) {
    final target = Uri.tryParse(url);
    final browser = widget.container.browser;
    if (target == null || !browser.isHomeAssistantOrigin(target)) return null;
    return buildHaSessionScript(tokens: browser.haSession, url: url);
  }

  /// Kiosk mode for a Home Assistant page shown as the screensaver: a wall
  /// clock or a dashboard put here is meant to be the whole screen, and the
  /// header and sidebar are neither wanted nor reachable — the first touch
  /// dismisses the screensaver (discussion #225). Follows the same settings
  /// the dashboard does, and only for this Home Assistant's own pages.
  List<String> _kioskSources(String url) {
    final target = Uri.tryParse(url);
    final settings = widget.container.settings;
    if (target == null ||
        !widget.container.browser.isHomeAssistantOrigin(target)) {
      return const [];
    }
    return [
      // The screensaver is not a second satellite (see vs_suppress_script).
      vsSuppressScript,
      ...externalKioskModeSources(
        origin: target.origin,
        apply: settings.get(defs.haKioskMode),
        hideHeader: settings.get(defs.haKioskHideHeader),
        hideSidebar: settings.get(defs.haKioskHideSidebar),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final website = widget.mode == 'website'
        ? widget.container.settings.get(defs.screensaverWebsiteUrl).trim()
        : '';
    // An empty URL falls through to the bundled page, whose website mode
    // shows the same black screen it always has.
    final topLevel = website.isNotEmpty;
    return InAppWebView(
      key: ValueKey(_epoch),
      initialUrlRequest: topLevel ? URLRequest(url: WebUri(website)) : null,
      initialFile: topLevel ? null : 'assets/screensaver/index.html',
      initialUserScripts: UnmodifiableListView([
        if (topLevel) ...[
          UserScript(
            source: _dismissScript,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
            forMainFrameOnly: false,
          ),
          // A Home Assistant page shown as the screensaver signs in from the
          // dashboard's session (discussion #225): the login form it would
          // otherwise show cannot be answered here — the first touch
          // dismisses the screensaver.
          if (_haSessionScript(website) case final seed?)
            UserScript(
              source: seed,
              injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
            ),
          for (final source in _kioskSources(website))
            UserScript(
              source: source,
              injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
            ),
          if (widget.container.settings.get(defs.screensaverPixelShift))
            UserScript(
              source: _pixelShiftScript,
              injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
            ),
        ] else
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
      // The user's pasted JavaScript for external pages, after every load
      // (issue #224). Only the website mode has a page of theirs to run it
      // on; the bundled screensaver is ours.
      onLoadStop: (controller, url) async {
        if (!topLevel) return;
        // This view outlives a settings change, so the flags baked in at
        // creation can be stale by the time a page loads.
        await _applyKiosk(controller);
        final inject = widget.container.settings.get(
          defs.browserInjectJsExternal,
        );
        if (inject.trim().isEmpty) return;
        await controller.evaluateJavascript(source: inject);
      },
      onReceivedError: (controller, request, error) {
        if (request.isForMainFrame ?? true) {
          _scheduleRetry(controller, 'load error: ${error.description}');
        }
      },
      onReceivedHttpError: (controller, request, errorResponse) {
        // Server errors only, like the dashboard WebView: a 4xx is the
        // site answering (login page, missing path), not an outage.
        final status = errorResponse.statusCode ?? 0;
        if ((request.isForMainFrame ?? true) && status >= 500) {
          _scheduleRetry(controller, 'HTTP $status');
        }
      },
      onRenderProcessGone: (controller, detail) {
        widget.container.log.warn(
          'screensaver',
          'WebView renderer gone (crashed: ${detail.didCrash}) — '
              'rebuilding the WebView',
        );
        if (mounted) setState(() => _epoch++);
      },
      onWebViewCreated: (controller) {
        _webView = controller;
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

/// The image's aspect ratio read from its header — no full decode, so it
/// costs microseconds, not a second of jank before every slide.
Future<double?> _aspectOf(Uint8List bytes) async {
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

  /// The current slide's provider, decoded at screen size. Held so the
  /// previous slide's decoded bitmap can be evicted from the engine's
  /// image cache when it leaves — otherwise every slide parks another
  /// full bitmap there until the cache's 100MB cap, which alone can OOM
  /// a low-RAM device running the WebView alongside.
  ImageProvider? _image;

  /// Width over height of the current image, or null when unknown; feeds
  /// the fill-the-screen decision.
  double? _imageAspect;

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
        var ended = false;
        video.addListener(() {
          final v = video.value;
          if (!ended &&
              v.isInitialized &&
              !v.isPlaying &&
              v.position >= v.duration &&
              v.duration > Duration.zero) {
            // Once only: the controller keeps notifying while it retires,
            // and a second _advance would skip a slide.
            ended = true;
            _advance();
          }
        });
        if (!mounted) {
          await video.dispose();
          await old?.dispose();
          return;
        }
        _video = video;
        final oldImage = _image;
        c.screensaver.notifySlideChanged();
        setState(() {
          _index = next;
          _image = null;
        });
        if (oldImage != null) unawaited(oldImage.evict());
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
      // The header read costs one extra pass over the file, but the bytes
      // are hot in the OS page cache by the time FileImage decodes them,
      // and knowing the aspect before the first frame means the backdrop
      // decision never flickers in after the slide is already up.
      double? aspect;
      if (c.settings.get(
        _gallery ? defs.screensaverGalleryFill : defs.screensaverLocalFill,
      )) {
        try {
          aspect = await _aspectOf(await file.readAsBytes());
        } catch (_) {}
        if (!mounted) {
          await old?.dispose();
          return;
        }
      }
      final oldImage = _image;
      final image = _screenSizedFile(file);
      // Decode before the hand-off, same as the Immich path (#212): an
      // undecoded slide paints as nothing, so the crossfade would dip
      // through black instead of blending photo into photo.
      await precacheImage(image, context, onError: (_, _) {});
      if (!mounted) {
        await old?.dispose();
        return;
      }
      c.screensaver.notifySlideChanged();
      setState(() {
        _index = next;
        _imageAspect = aspect;
        _image = image;
      });
      if (oldImage != null) unawaited(oldImage.evict());
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

  /// Decode capped at the panel's physical width: originals can be 48MP
  /// phone shots that decode to ~190MB of RGBA at full size, and the
  /// screen can never show more pixels than it has.
  ImageProvider _screenSizedFile(File file) {
    final mq = MediaQuery.of(context);
    return ResizeImage(
      FileImage(file),
      width: (mq.size.width * mq.devicePixelRatio).round(),
    );
  }

  /// Outgoing video controllers live until every transition that could
  /// still be painting them has finished, then die.
  final _retiring = <VideoPlayerController>[];
  final _retireTimers = <Timer>[];

  void _retire(VideoPlayerController? old) {
    if (old == null) return;
    _retiring.add(old);
    late final Timer t;
    t = Timer(const Duration(milliseconds: 1200), () {
      _retireTimers.remove(t);
      _retiring.remove(old);
      old.dispose();
    });
    _retireTimers.add(t);
  }

  void _advance() {
    if (!mounted || _files.isEmpty) return;
    _show(_index + 1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final t in _retireTimers) {
      t.cancel();
    }
    _video?.dispose();
    for (final v in _retiring) {
      v.dispose();
    }
    _image?.evict();
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
    } else if (_files.isEmpty || (_image == null && video == null)) {
      body = const SizedBox.expand();
    } else {
      final transition = _transition;
      final isVideoSlide = video != null && video.value.isInitialized;
      // The index is in the key so a repeated file still hands off.
      final key = ValueKey('$_index:${_files[_index].path}');
      // Fill the screen: same recipe as the Immich screensaver — photos
      // shaped close enough to the panel are cover-fitted edge to edge
      // (crop capped at a 1.45x ratio mismatch), and the ones that keep
      // their full frame get the photo itself, blurred and dimmed, as the
      // backdrop instead of black bars.
      final fillWanted =
          !isVideoSlide &&
          c.settings.get(
            _gallery ? defs.screensaverGalleryFill : defs.screensaverLocalFill,
          );
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
        Widget picture = Image(
          image: _image!,
          fit: covers ? BoxFit.cover : BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.expand(),
        );
        if (transition == 'kenburns') {
          // Stills drift for the whole hold; videos supply their own
          // motion and just crossfade (the default branch of _handOff).
          // The drift wraps only the photo: the blurred backdrop stays
          // static behind it, so it rasterizes once per slide instead of
          // re-blurring the whole screen on every animation frame.
          picture = _KenBurnsDrift(
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
            child: SizedBox.expand(child: picture),
          );
        }
        inner = fillWanted && !covers
            ? Stack(
                fit: StackFit.expand,
                children: [
                  // Blur + scrim so the backdrop reads as atmosphere, not
                  // a second copy of the photo. ImageFiltered over the
                  // same provider, not BackdropFilter: a backdrop filter
                  // must re-sample the scene every frame it composites,
                  // which on weak tablet GPUs is a standing 60fps blur tax.
                  RepaintBoundary(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: 40,
                            sigmaY: 40,
                            tileMode: ui.TileMode.clamp,
                          ),
                          child: Image(
                            image: _image!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (_, _, _) =>
                                const SizedBox.expand(),
                          ),
                        ),
                        const ColoredBox(color: Color(0x99000000)),
                      ],
                    ),
                  ),
                  picture,
                ],
              )
            : SizedBox.expand(child: picture);
      }
      final Widget slide = KeyedSubtree(key: key, child: inner);
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
/// image is prefetched while the current one holds and decoded before the
/// crossfade begins, so a hand-off never waits on the network and never
/// fades through black.
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

  /// The current slide's provider, decoded at screen size and evicted
  /// from the engine's image cache when the slide leaves. Without the
  /// eviction every slide is a fresh never-hit cache key, so the cache
  /// ratchets to its 100MB cap and stays there for the process life.
  ImageProvider? _image;

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

  /// The last fetch failure as a user-readable reason, so the give-up
  /// message can say what actually went wrong: a rejected API key is not
  /// an unreachable server (issue #222).
  String? _lastFailure;

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
              '${c.immich.readableError(e)} It will retry next time.',
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
      setState(
        () => _problem = _lastFailure ?? 'Could not reach the Immich server.',
      );
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
        var ended = false;
        video.addListener(() {
          final v = video.value;
          if (!ended &&
              v.isInitialized &&
              !v.isPlaying &&
              v.position >= v.duration &&
              v.duration > Duration.zero) {
            // Once only: the controller keeps notifying while it retires,
            // and a second _advance would skip a slide.
            ended = true;
            _advance();
          }
        });
        if (!mounted) {
          await video.dispose();
          await old?.dispose();
          return;
        }
        _failures = 0;
        _lastFailure = null;
        _video = video;
        final oldImage = _image;
        setState(() {
          _index = next;
          _imageBytes = null;
          _image = null;
        });
        if (oldImage != null) unawaited(oldImage.evict());
        // A warmed buffer for a slide we already passed would sit through
        // the whole video for nothing.
        _prefetchedIndex = null;
        _prefetchedBytes = null;
        await video.play();
      } catch (e) {
        c.log.warn('screensaver', 'immich video failed (${asset.id}): $e');
        await video.dispose();
        _failures++;
        _lastFailure = c.immich.readableError(e);
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
        _lastFailure = c.immich.readableError(e);
        if (mounted) unawaited(_show(next + 1));
        await old?.dispose();
        return;
      }
      // Consumed (or stale): drop the warm buffer so it never outlives
      // its one use.
      _prefetchedIndex = null;
      _prefetchedBytes = null;
      final aspect = await _aspectOf(bytes);
      if (!mounted) {
        await old?.dispose();
        return;
      }
      _failures = 0;
      _lastFailure = null;
      final oldImage = _image;
      final mq = MediaQuery.of(context);
      // Screen-width decode cap: server previews can still out-size a
      // small panel (Echo Show class) several times over.
      final image = ResizeImage(
        MemoryImage(bytes),
        width: (mq.size.width * mq.devicePixelRatio).round(),
      );
      // Decode before the hand-off: the switcher starts fading the moment
      // the new slide mounts, and a decode still in flight paints as
      // nothing, so the old photo would fade into black and the new one
      // pop in late (#212). Waiting here just holds the current photo a
      // beat longer, then the crossfade blends image into image.
      await precacheImage(image, context, onError: (_, _) {});
      if (!mounted) {
        await old?.dispose();
        return;
      }
      c.screensaver.notifySlideChanged();
      setState(() {
        _index = next;
        _imageBytes = bytes;
        _imageAspect = aspect;
        _image = image;
      });
      if (oldImage != null) unawaited(oldImage.evict());
      final seconds = c.settings
          .get(defs.screensaverImmichInterval)
          .toInt()
          .clamp(2, 3600);
      _timer = Timer(Duration(seconds: seconds), _advance);
      unawaited(_prefetch(next + 1));
    }
    _retire(old);
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
  final _retireTimers = <Timer>[];

  void _retire(VideoPlayerController? old) {
    if (old == null) return;
    _retiring.add(old);
    late final Timer t;
    t = Timer(const Duration(milliseconds: 1200), () {
      _retireTimers.remove(t);
      _retiring.remove(old);
      old.dispose();
    });
    _retireTimers.add(t);
  }

  void _advance() {
    if (!mounted || _assets.isEmpty) return;
    _show(_index + 1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final t in _retireTimers) {
      t.cancel();
    }
    _video?.dispose();
    for (final v in _retiring) {
      v.dispose();
    }
    _image?.evict();
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
    } else if (_image == null && video == null) {
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
        Widget picture = Image(
          image: _image!,
          fit: covers ? BoxFit.cover : BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.expand(),
        );
        if (transition == 'kenburns') {
          // The drift wraps only the photo: the blurred backdrop stays
          // static behind it, so it rasterizes once per slide instead of
          // re-blurring the whole screen on every animation frame.
          picture = _KenBurnsDrift(
            index: _index,
            duration:
                Duration(
                  seconds: c.settings
                      .get(defs.screensaverImmichInterval)
                      .toInt()
                      .clamp(2, 3600),
                ) +
                const Duration(seconds: 2),
            child: SizedBox.expand(child: picture),
          );
        }
        inner = fillWanted && !covers
            ? Stack(
                fit: StackFit.expand,
                children: [
                  // Blur + scrim so the backdrop reads as atmosphere, not
                  // a second copy of the photo (sendspin_player_overlay
                  // established the recipe). ImageFiltered over the same
                  // provider, not BackdropFilter: a backdrop filter must
                  // re-sample the scene every frame it composites, which
                  // on weak tablet GPUs is a standing 60fps blur tax.
                  RepaintBoundary(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: 40,
                            sigmaY: 40,
                            tileMode: ui.TileMode.clamp,
                          ),
                          child: Image(
                            image: _image!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (_, _, _) =>
                                const SizedBox.expand(),
                          ),
                        ),
                        const ColoredBox(color: Color(0x99000000)),
                      ],
                    ),
                  ),
                  picture,
                ],
              )
            : SizedBox.expand(child: picture);
      }
      final Widget slide = KeyedSubtree(key: key, child: inner);
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
                _ImmichMetadata(container: c, asset: _assets[_index]),
              ],
            )
          : body,
    );
  }
}

/// The metadata panel in a corner of the Immich screensaver: album, date,
/// camera and location, shadow-on-photo text like the small clock, and only
/// the lines the asset actually carries. The panel outlives the slide: the
/// vignette holds steady from photo to photo while the text fades out with
/// the old one and back in with the new. Remounting the whole panel per
/// slide read as a hard blink against the crossfading photos.
class _ImmichMetadata extends StatefulWidget {
  const _ImmichMetadata({required this.container, required this.asset});

  final AppContainer container;
  final ImmichAsset asset;

  @override
  State<_ImmichMetadata> createState() => _ImmichMetadataState();
}

class _ImmichMetadataState extends State<_ImmichMetadata> {
  /// The details on screen right now. They lag [_ImmichMetadata.asset] by
  /// design: the old text holds through its fade-out, and the vignette
  /// rides this map, so it only moves when an asset truly has no lines.
  Map<String, String> _details = const {};
  bool _textVisible = false;

  static const _fade = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _swap(widget.asset, fadeOut: false);
  }

  @override
  void didUpdateWidget(_ImmichMetadata old) {
    super.didUpdateWidget(old);
    if (old.asset.id != widget.asset.id) _swap(widget.asset, fadeOut: true);
  }

  /// Fade the old text out, look up the new asset's lines (already cached
  /// when the prefetcher got there first), fade back in. A newer swap wins:
  /// each continuation checks it still speaks for the current asset.
  Future<void> _swap(ImmichAsset asset, {required bool fadeOut}) async {
    if (fadeOut) setState(() => _textVisible = false);
    final details = await widget.container.immich.assetDetails(asset);
    if (fadeOut) await Future<void>.delayed(_fade);
    if (!mounted || widget.asset.id != asset.id) return;
    setState(() {
      _details = details;
      _textVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final container = widget.container;
    // Widgets own their corners: rather than stacking two panels into
    // one corner, the metadata steps to the first free one, and stands
    // down entirely on the (unlikely) fully claimed screen.
    final claimed = {
      for (final w in decodeScreensaverWidgets(
        container.settings.get(defs.screensaverWidgets),
      ))
        if (screensaverWidgetAllowedOnMode(w.type, 'immich')) w.position,
    };
    final preferred = container.settings.get(
      defs.screensaverImmichMetadataPosition,
    );
    final spot = [preferred, ...defs.cornerOptions]
        .where((c) => !claimed.contains(c))
        .firstOrNull;
    if (spot == null) return const SizedBox.shrink();
    final corner = _cornerAlignment(spot);
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
    final details = _details;
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
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The vignette fades with content presence, not with the slide:
          // consecutive photos with metadata keep one steady vignette.
          AnimatedOpacity(
            opacity: details.isEmpty ? 0 : 1,
            duration: _fade,
            child: _cornerVignette(corner, radius: 0.6),
          ),
          AnimatedOpacity(
            opacity: _textVisible && details.isNotEmpty ? 1 : 0,
            duration: _fade,
            child: Align(
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
          ),
        ],
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

class _KenBurnsDriftState extends State<_KenBurnsDrift> {
  static const _anchors = [
    Alignment.topLeft,
    Alignment.bottomRight,
    Alignment.topRight,
    Alignment.bottomLeft,
  ];

  /// A timer at ~12fps, deliberately NOT an AnimationController: a ticker
  /// demands a frame every vsync for its whole life, and this zoom moves
  /// 0.1 scale over the slide's many seconds — under a pixel per step even
  /// at this cadence. At 60fps it kept a full CPU core busy around the
  /// clock on weak panels (measured on an Echo Show 5: the "idle" kiosk at
  /// 40+fps, 60C, and a GC sawtooth in available RAM, because a kiosk's
  /// idle hours ARE screensaver hours).
  static const _step = Duration(milliseconds: 80);

  final _progress = ValueNotifier<double>(0);
  final _clock = Stopwatch()..start();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_step, (_) {
      final ms = widget.duration.inMilliseconds;
      final t = ms <= 0 ? 1.0 : _clock.elapsedMilliseconds / ms;
      _progress.value = t.clamp(0.0, 1.0);
      // Fully zoomed: stop asking for frames at all.
      if (t >= 1) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedBuilder(
      animation: _progress,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.1 * _progress.value,
        alignment: _anchors[widget.index % _anchors.length],
        child: child,
      ),
      child: widget.child,
    ),
  );
}

/// The WebRTC camera grid as a screensaver: the configured camera view,
/// non-interactive, dismissed by a touch anywhere like every other mode.
///
/// This is deliberately its own player rather than the camera manager's
/// active view. A view someone opened is an interaction and holds the
/// screensaver off; the screensaver showing cameras is the opposite, and
/// letting the two share state would have each cancel the other.
class CameraScreensaver extends StatelessWidget {
  const CameraScreensaver({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    final viewId = container.settings.get(defs.screensaverCameraView);
    final view = container.camera.config.views
        .where((item) => item.id == viewId)
        .firstOrNull;
    // No view chosen, one that has since been deleted, or one left empty:
    // black, the same safe cover an unknown mode gets.
    if (view == null || view.cameraIds.isEmpty) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => container.screensaver.notifyActivity('touch'),
        child: const ColoredBox(color: Colors.black),
      );
    }
    // Through the closing wrapper like the camera view overlay, so the
    // streams are shut down from a mounted widget rather than on the way
    // out (see ClosingCameraPlayer).
    return ClosingCameraPlayer(
      key: ValueKey('screensaver-${view.id}'),
      container: container,
      view: view,
      interactive: false,
      onDismiss: () => container.screensaver.notifyActivity('touch'),
    );
  }
}
