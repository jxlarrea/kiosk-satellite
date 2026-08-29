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
import '../core/image_orientation.dart';
import '../core/locale_dates.dart';
import '../managers/browser/ha_session_script.dart';
import '../managers/browser/vs_suppress_script.dart';
import '../managers/home_assistant/kiosk_mode.dart';
import '../managers/glance/glance_manager.dart'
    show GlanceEntity, glanceAttributeText;
import '../managers/home_assistant/home_assistant_manager.dart'
    show GlanceSubscription;
import '../managers/screensaver/immich_manager.dart'
    show
        ImmichAsset,
        arrangeImmichPairs,
        immichFiltersActive,
        immichMetadataCorner,
        immichMetadataFieldOn,
        immichMetadataFields,
        immichMetadataVisible,
        immichPairableScreen,
        immichPairsPortrait,
        immichPortraitPhoto;
import '../managers/camera/models.dart'
    show CameraViewConfig, decodeCameraViewIds;
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
    // The Immich metadata lines ride along for the same reason: their
    // toggles are read at build, so turning one off has to reach the
    // panel already on screen. So do the At a Glance switch and style,
    // read at build by the overlay row the photo and web modes carry.
    final live = {
      defs.screensaverWidgets.key,
      defs.screensaverWidgetScale.key,
      defs.screensaverImmichMetadata.key,
      defs.screensaverImmichMetadataPosition.key,
      defs.screensaverGlanceEnabled.key,
      defs.screensaverGlanceTextOnly.key,
      defs.screensaverGlanceBwIcons.key,
      defs.screensaverGlanceScale.key,
      for (final def in immichMetadataFields.values) def.key,
    };
    _widgetsSub = container.bus.on<SettingChanged>().listen((e) {
      if (live.contains(e.key) && mounted) setState(() {});
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
        final blackBare =
            view == 'black' &&
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
                // The At a Glance row rides over the photo and web modes
                // too, pinned to the bottom the way the Clock screensaver
                // pins it. Black and Clock place their own row (centred,
                // under the clock), and the camera grid stays clear, the
                // same line the corner widgets draw. IgnorePointer keeps
                // taps falling through to the mode underneath: dismissal
                // for the native modes, the page for the web ones.
                if (!blackBare &&
                    view != 'black' &&
                    view != 'clock' &&
                    view != 'camera')
                  ValueListenableBuilder<bool?>(
                    valueListenable: container.screensaver.scheduleGlance,
                    builder: (context, scheduled, _) {
                      if (!(scheduled ??
                          container.settings.get(
                            defs.screensaverGlanceEnabled,
                          ))) {
                        return const SizedBox.shrink();
                      }
                      return ValueListenableBuilder<Set<String>>(
                        valueListenable: container.screensaver.claimedCorners,
                        builder: (context, claimed, _) {
                          // Immich metadata in a bottom corner, whether
                          // the pair's two panels (which claim theirs
                          // live) or the single-photo panel's settled
                          // spot, and the row narrows to portrait's two
                          // columns so it wraps clear of the panels
                          // instead of spreading into them.
                          final metadata = view == 'immich'
                              ? immichMetadataCorner(container.settings)
                              : null;
                          return _GlanceOverlay(
                            container: container,
                            narrow:
                                claimed.any((c) => c.startsWith('bottom_')) ||
                                metadata == 'bottom_left' ||
                                metadata == 'bottom_right',
                          );
                        },
                      );
                    },
                  ),
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
                    // A mode can also claim corners for itself while it
                    // runs (the Immich pair's two metadata panels): a
                    // widget in a claimed corner stands down until the
                    // corner is free again, rather than sitting on top of
                    // what claimed it.
                    builder: (context, scheduled, _) =>
                        ValueListenableBuilder<Set<String>>(
                          valueListenable: container.screensaver.claimedCorners,
                          builder: (context, claimed, _) => Stack(
                            fit: StackFit.expand,
                            children: [
                              if (scheduled ?? true)
                                for (final spec in decodeScreensaverWidgets(
                                  container.settings.get(
                                    defs.screensaverWidgets,
                                  ),
                                ))
                                  if (screensaverWidgetAllowedOnMode(
                                        spec.type,
                                        view,
                                      ) &&
                                      !claimed.contains(spec.position))
                                    switch (spec.type) {
                                      'clock' => ClockWidgetOverlay(
                                        container: container,
                                        spec: spec,
                                      ),
                                      'weather' => WeatherWidgetOverlay(
                                        container: container,
                                        spec: spec,
                                      ),
                                      'battery' => BatteryWidgetOverlay(
                                        container: container,
                                        spec: spec,
                                      ),
                                      'entity' => EntityWidgetOverlay(
                                        container: container,
                                        spec: spec,
                                      ),
                                      _ => const SizedBox.shrink(),
                                    },
                            ],
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
/// The clock's font: the bundled Rubik, the same face every other piece of
/// app text uses, so the screensaver never looks like a different app from
/// the settings behind it.
const _clockFontFamily = 'Rubik';

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
    final secs =
        s.get(defs.screensaverClockStyle) == 'digital' &&
        s.get(defs.screensaverClockSeconds);
    final delay = secs
        ? Duration(milliseconds: 1000 - now.millisecond)
        : Duration(milliseconds: 60000 - now.second * 1000 - now.millisecond);
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
    final covers = photo == null || max(photo / screen, screen / photo) <= 1.45;
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
        digitColor: _rgb(
          defs.screensaverFlipDigitColor,
          const Color(0xFF212121),
        ),
        cardColor: _rgb(defs.screensaverFlipBgColor, const Color(0xFFF5F5F5)),
        scale: scale,
      );
    }
    return RollerClockFace(
      use24h: widget.container.settings.get(defs.screensaverClock24h),
      digitColor: _rgb(
        defs.screensaverRollerDigitColor,
        const Color(0xFFFAFAFA),
      ),
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
          _rgb(defs.screensaverFlipBgColor, const Color(0xFFF5F5F5)),
        ),
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
                    defs.screensaverFlipDigitColor,
                    const Color(0xFF212121),
                  ),
                  'roller' => _rgb(
                    defs.screensaverRollerDigitColor,
                    const Color(0xFFFAFAFA),
                  ),
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

/// The At a Glance row over the photo and web modes: bottom-pinned at the
/// Clock screensaver's inset, sized by its rule, and never in the way of a
/// touch. Its own widget so the overlay's build stays a list of layers.
class _GlanceOverlay extends StatelessWidget {
  const _GlanceOverlay({required this.container, required this.narrow});

  final AppContainer container;

  /// Whether the mode's bottom corners are spoken for (the Immich
  /// metadata panels), so the row should wrap narrow instead of spreading
  /// into them.
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: height * 0.06),
          child: GlanceRow(
            container: container,
            scale: min(1.0, height / 480).clamp(0.75, 1.0),
            narrow: narrow,
          ),
        ),
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
Widget _cornerVignette(Alignment corner, {double radius = 0.7}) => DecoratedBox(
  decoration: BoxDecoration(
    gradient: RadialGradient(
      center: corner,
      radius: radius,
      // Front-loaded: still ~60% black well past a third of the way
      // out, so the text area is solidly backed before the long fade
      // begins. 80% at the corner itself: anything lighter left the
      // widgets washing out on bright daylight photos.
      colors: const [Color(0xCC000000), Color(0x99000000), Color(0x00000000)],
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

/// The battery widget (discussion #267): the device's own charge in a
/// corner, so a wall tablet says how it is doing without a dashboard card
/// or the Home Assistant app. An icon that follows the level, an optional
/// percentage beside it, and a bolt while it is on external power.
class BatteryWidgetOverlay extends StatefulWidget {
  const BatteryWidgetOverlay({
    super.key,
    required this.container,
    required this.spec,
  });

  final AppContainer container;
  final ScreensaverWidget spec;

  @override
  State<BatteryWidgetOverlay> createState() => _BatteryWidgetOverlayState();
}

class _BatteryWidgetOverlayState extends State<BatteryWidgetOverlay> {
  Timer? _poll;
  Timer? _shift;
  StreamSubscription<PowerChanged>? _power;
  Offset _offset = Offset.zero;

  int? _level;
  bool _charging = false;
  bool _read = false;

  /// A charge moves by single points over tens of minutes, so a minute is
  /// as often as this is worth reading; the cable is the only thing that
  /// changes in an instant, and that arrives as an event.
  static const _interval = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _poll = Timer.periodic(_interval, (_) => unawaited(_refresh()));
    _power = widget.container.bus.on<PowerChanged>().listen((_) {
      unawaited(_refresh());
    });
    // The same slow OLED-protecting nudge the other corner overlays do.
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

  Future<void> _refresh() async {
    final status = await widget.container.device.batteryStatus();
    if (!mounted) return;
    setState(() {
      _level = status.level;
      _charging = status.charging;
      _read = true;
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _shift?.cancel();
    unawaited(_power?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nothing until the first reading: an empty corner beats a widget that
    // flashes 0% on the way in.
    if (!_read) return const SizedBox.shrink();
    final level = _level;
    if (!batteryWidgetVisible(
      lowOnly: widget.spec.config['low'] == true,
      level: level,
      charging: _charging,
    )) {
      return const SizedBox.shrink();
    }
    final corner = _cornerAlignment(widget.spec.position);
    final color = _widgetRgb(widget.spec.config['color']);
    final size = MediaQuery.of(context).size;
    // Two thirds of the small clock: readable across a room, without a
    // corner of the photo given over to a battery.
    final scale =
        widget.container.settings.get(defs.screensaverWidgetScale).toDouble() /
        100;
    final textSize = max(min(size.width, size.height) * 0.042, 30.0) * scale;
    const shadows = [Shadow(color: Colors.black54, blurRadius: 8)];
    final glyph = Icon(
      _batteryIcon(level, charging: _charging),
      size: textSize * 1.15,
      color: color,
      shadows: shadows,
    );
    final text = widget.spec.config['percent'] != false && level != null
        ? Text(
            '$level%',
            style: TextStyle(
              fontFamily: 'Rubik',
              color: color,
              fontSize: textSize,
              fontWeight: FontWeight.w400,
              height: 1.0,
              shadows: shadows,
            ),
          )
        : null;
    // The icon leads on a left corner and trails on a right one, the same
    // rule the weather and metadata rows follow.
    final right = corner.x > 0;
    final gap = SizedBox(width: 8 * scale);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _cornerVignette(corner, radius: 0.5),
          Align(
            alignment: corner,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Transform.translate(
                offset: _offset,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (text != null && right) ...[text, gap],
                    glyph,
                    if (text != null && !right) ...[gap, text],
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

/// At or below this the charge counts as low: the "only when low" widget
/// appears, matching the level Android itself starts warning at.
const lowBatteryLevel = 20;

/// Whether the battery widget draws at all. "Only when low" keeps the
/// corner clear until the charge is worth walking over for: a device on
/// the cable is already being dealt with, and a host that cannot report a
/// level has no "low" to speak of, so neither shows.
bool batteryWidgetVisible({
  required bool lowOnly,
  required int? level,
  required bool charging,
}) {
  if (!lowOnly) return true;
  return !charging && level != null && level <= lowBatteryLevel;
}

/// The battery glyph for a level: the bolt while it is on external power,
/// the alert below [_lowBattery], and the bar icons in between. An unknown
/// level shows the outline rather than an empty battery, which would read
/// as a flat one.
IconData _batteryIcon(int? level, {required bool charging}) {
  if (charging) return Icons.battery_charging_full;
  if (level == null) return Icons.battery_unknown;
  if (level <= 10) return Icons.battery_alert;
  if (level >= 95) return Icons.battery_full;
  if (level >= 80) return Icons.battery_6_bar;
  if (level >= 65) return Icons.battery_5_bar;
  if (level >= 50) return Icons.battery_4_bar;
  if (level >= 35) return Icons.battery_3_bar;
  if (level >= lowBatteryLevel) return Icons.battery_2_bar;
  return Icons.battery_1_bar;
}

/// A widget's "r,g,b" color, falling back to the overlays' near-white.
Color _widgetRgb(Object? raw) {
  final parts = '$raw'.split(',').map((p) => int.tryParse(p.trim())).toList();
  if (parts.length == 3 && parts.every((p) => p != null)) {
    return Color.fromARGB(255, parts[0]!, parts[1]!, parts[2]!);
  }
  return const Color(0xFFFAFAFA);
}

/// The entity widget (issue #336): one Home Assistant entity's reading in
/// a corner, the At a Glance row's chip in the widget family's look: the
/// entity's icon and its value on one line, the name under them, all in
/// the widget's color over the corner vignette. Fed by its own
/// subscribe_entities socket while the screensaver shows (the weather
/// widget's pattern) and read through the same formatting the row uses
/// (icon, precision, unit, attribute), so the corner and the row never
/// disagree about a sensor.
class EntityWidgetOverlay extends StatefulWidget {
  const EntityWidgetOverlay({
    super.key,
    required this.container,
    required this.spec,
  });

  final AppContainer container;
  final ScreensaverWidget spec;

  @override
  State<EntityWidgetOverlay> createState() => _EntityWidgetOverlayState();
}

class _EntityWidgetOverlayState extends State<EntityWidgetOverlay> {
  GlanceSubscription? _live;
  Timer? _retry;
  Timer? _shift;
  Offset _offset = Offset.zero;

  /// The configured entity with whatever live state has arrived, the row's
  /// own model so its icon and text helpers apply unchanged.
  late GlanceEntity _entity = entityWidgetEntity(widget.spec.config);

  @override
  void initState() {
    super.initState();
    unawaited(_open());
    // The same slow OLED-protecting nudge the other corner overlays do.
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
    final id = _entity.entityId;
    if (id.isEmpty) return;
    final live = await widget.container.homeAssistant.subscribeEntities(
      [id],
      _onState,
      onPrecision: _onPrecision,
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

  void _onPrecision(Map<String, int> precisions) {
    if (!mounted) return;
    final precision = precisions[_entity.entityId];
    if (precision == null) return;
    setState(() => _entity = _entity.merge(precision: precision));
  }

  /// One update from the subscription, merged the way the row merges:
  /// attributes arrive only when they change, so a name or icon already
  /// known is kept rather than lost.
  void _onState(String entityId, Map<String, Object?> state) {
    if (!mounted || entityId != _entity.entityId) return;
    final attributes = (state['attributes'] as Map?) ?? const {};
    final attribute = _entity.attribute;
    setState(() {
      _entity = _entity.merge(
        state: state['state'] as String?,
        name: attributes['friendly_name'] as String?,
        icon: attributes['icon'] as String?,
        deviceClass: attributes['device_class'] as String?,
        unit: attributes['unit_of_measurement'] as String?,
        attributeValue: attribute != null && attributes.containsKey(attribute)
            ? glanceAttributeText(attributes[attribute])
            : null,
      );
    });
  }

  void _closeLive() {
    _retry?.cancel();
    final live = _live;
    _live = null;
    if (live != null) unawaited(live.close());
  }

  // A live edit can repoint the widget at another entity, or change what
  // it shows of the same one; the element is reused in place, so the
  // subscription and the model have to follow by hand.
  @override
  void didUpdateWidget(EntityWidgetOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = entityWidgetEntity(widget.spec.config);
    if (next.entityId != _entity.entityId) {
      _closeLive();
      _entity = next;
      unawaited(_open());
      return;
    }
    if (next.customName != _entity.customName ||
        next.attribute != _entity.attribute) {
      // Same entity, so the live state carries over; the attribute value
      // only when the attribute itself did not change.
      _entity = GlanceEntity(
        entityId: next.entityId,
        name: _entity.name,
        customName: next.customName,
        attribute: next.attribute,
        state: _entity.state,
        attributeValue: next.attribute == _entity.attribute
            ? _entity.attributeValue
            : null,
        icon: _entity.icon,
        deviceClass: _entity.deviceClass,
        unit: _entity.unit,
        precision: _entity.precision,
      );
    }
  }

  @override
  void dispose() {
    _shift?.cancel();
    _closeLive();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nothing until the first reading: an empty corner beats a widget that
    // says "…" on the way in.
    if (_entity.state == null) return const SizedBox.shrink();
    final corner = _cornerAlignment(widget.spec.position);
    final color = _widgetRgb(widget.spec.config['color']);
    final size = MediaQuery.of(context).size;
    // The value is the battery widget's size, the name the weather
    // widget's detail line, so the corner overlays all read as one
    // family. The Widget scaling slider then corrects everything for the
    // screen.
    final scale =
        widget.container.settings.get(defs.screensaverWidgetScale).toDouble() /
        100;
    final textSize = max(min(size.width, size.height) * 0.042, 30.0) * scale;
    const shadows = [Shadow(color: Colors.black54, blurRadius: 8)];
    final glyph = GlanceIcon(
      entity: _entity,
      size: textSize * 1.15,
      color: color,
    );
    final value = Text(
      glanceStateText(_entity),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Rubik',
        color: color,
        fontSize: textSize,
        fontWeight: FontWeight.w400,
        height: 1.0,
        shadows: shadows,
      ),
    );
    final label = Text(
      _entity.displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Rubik',
        color: color.withValues(alpha: 0.9),
        fontSize: 16 * scale,
        fontWeight: FontWeight.w400,
        height: 1.35,
        shadows: shadows,
      ),
    );
    // The icon leads on a left corner and trails on a right one, the same
    // rule the battery and weather widgets follow.
    final right = corner.x > 0;
    final gap = SizedBox(width: 10 * scale);
    // Show name off: the value and its icon alone, for a corner that
    // explains itself.
    final showName = widget.spec.config['show_name'] != false;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _cornerVignette(corner, radius: 0.5),
          Align(
            alignment: corner,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Transform.translate(
                offset: _offset,
                child: ConstrainedBox(
                  // Capped so one long name or value cannot run across the
                  // screen; the text inside truncates instead.
                  constraints: BoxConstraints(maxWidth: size.width * 0.4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    crossAxisAlignment: right
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (right) ...[Flexible(child: value), gap],
                          glyph,
                          if (!right) ...[gap, Flexible(child: value)],
                        ],
                      ),
                      if (showName) label,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The entity widget's configuration as the row's own model: the id, the
/// cached friendly name, a hand-chosen name (the "label" key, the Home
/// Assistant name when empty) and the attribute shown instead of the state
/// (the state when empty). No live fields yet: those arrive over the
/// subscription.
GlanceEntity entityWidgetEntity(Map<String, Object?> config) {
  final label = '${config['label'] ?? ''}'.trim();
  final attribute = '${config['attribute'] ?? ''}'.trim();
  return GlanceEntity(
    entityId: '${config['entity'] ?? ''}'.trim(),
    name: '${config['name'] ?? ''}',
    customName: label.isEmpty ? null : label,
    attribute: attribute.isEmpty ? null : attribute,
  );
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

  /// Home Assistant's own translation of the weather conditions, keyed by
  /// condition, in the language the server is set to (issue #268). Empty on
  /// an English server and whenever the lookup fails, and then the built-in
  /// labels below speak.
  Map<String, String> _translated = const {};

  /// OpenWeatherMap's naming; a missing companion simply never reports.
  String? _companion(String entity) {
    final parts = entity.split('.');
    return parts.length == 2 ? 'sensor.${parts[1]}_weather' : null;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_open());
    unawaited(_loadTranslations());
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

  /// Cached in the manager after the first widget asks, so this costs one
  /// lookup per app run rather than one per screensaver.
  Future<void> _loadTranslations() async {
    final translated = await widget.container.homeAssistant.stateTranslations(
      'weather',
    );
    if (!mounted || translated.isEmpty) return;
    setState(() => _translated = translated);
  }

  Future<void> _open() async {
    final entity = '${widget.spec.config['entity'] ?? ''}';
    if (entity.isEmpty) return;
    final live = await widget.container.homeAssistant.subscribeEntities([
      entity,
      ?_companion(entity),
    ], _onState);
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
    if (!_haveData || _condition == 'unavailable' || _condition == 'unknown') {
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
    final tempSize = max(min(size.width, size.height) * 0.063, 44.0) * scale;
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
      // The Immich metadata panel's line height: the two blocks share a
      // corner vocabulary, and the tighter 1.2 read as cramped beside it.
      height: 1.35,
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
      // Home Assistant's own translation first: the companion sensor's
      // richer wording ("overcast clouds") is only ever English, and an
      // English line in an Italian house is what issue #268 is about.
      if (_on('forecast') && _condition.isNotEmpty)
        detail(
          _translated[_condition] ??
              (_forecastText.isNotEmpty
                  ? _sentenceCase(_forecastText)
                  : _conditionLabel(_condition)),
          _conditionIcon(_condition),
        ),
      if (_on('humidity') && humidity != null)
        detail('${humidity.round()}%', Icons.water_drop_outlined),
      if (_on('wind') && wind != null)
        detail(reading(wind, 'wind_speed_unit'), Icons.air),
      if (_on('visibility') && visibility != null)
        detail(
          reading(visibility, 'visibility_unit'),
          Icons.visibility_outlined,
        ),
    ];
    final lines = <Widget>[
      if (_on('location') && location.isNotEmpty)
        Text(
          location,
          style: line(size: 18, weight: FontWeight.w600, alpha: 1),
        ),
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
    if (widget.mode == 'media') {
      widget.container.screensaver.attachSlides(_step);
    }
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
    widget.container.screensaver.detachSlides(_step);
    _retry?.cancel();
    _kioskSub?.cancel();
    super.dispose();
  }

  /// The Home Assistant Media deck lives in the page; the bundled script
  /// exposes one hook for stepping it. Nothing to do until the page is up
  /// or when it has no playlist yet, and the hook itself says so.
  Future<void> _step(int direction) async {
    final controller = _webView;
    if (controller == null) return;
    await controller.evaluateJavascript(
      source:
          'typeof window.__ksSlide === "function" && '
          'window.__ksSlide(${direction.sign})',
    );
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
      'mediaFill': s.get(defs.screensaverMediaFill),
      'pixelShift': s.get(defs.screensaverPixelShift),
    });
  }

  /// Any tap dismisses, like every screensaver. The WebView swallows
  /// Flutter's gestures, so the page reports the tap itself; capture
  /// phase and every frame, so a site that stops propagation (or hosts
  /// its content in its own iframes) still dismisses.
  ///
  /// Only primary pointers report: a pinch's second finger would otherwise
  /// read as a second tap the instant it lands, dismissing right through
  /// the double-tap option below. The single-tap default loses nothing —
  /// the first finger of any gesture is the primary one.
  static const _dismissScript = '''
document.addEventListener('pointerdown', function (e) {
  if (e.isPrimary === false) return;
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
            // 'touch_page', not 'touch': the kiosk screen's raw pointer
            // Listener reports the same taps, and under the double-tap
            // option (discussion #248) the manager must count each tap
            // once, so the bridge's reports carry their own name for it
            // to drop while that gate holds.
            widget.container.screensaver.notifyActivity('touch_page');
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

/// The image's aspect ratio as it will appear on screen, read from its
/// header — no full decode, so it costs microseconds, not a second of jank
/// before every slide.
///
/// EXIF orientation included: a photo taken in portrait is commonly stored
/// landscape with a "turn me" tag, and the renderer turns it. Measuring the
/// stored dimensions alone called those photos landscape, so they were
/// judged backwards by both the fill decision and the portrait pairing.
Future<double?> _aspectOf(Uint8List bytes) async {
  try {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final width = descriptor.width;
      final height = descriptor.height;
      descriptor.dispose();
      return orientationSwapsAxes(jpegOrientation(bytes))
          ? height / width
          : width / height;
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
    c.screensaver.attachSlides(_step);
    _load();
  }

  bool get _gallery => widget.mode == 'gallery';

  /// The hand-off a step is waiting on, so a second press mid-transition
  /// is dropped rather than racing two slides onto the screen.
  Future<void>? _stepping;

  /// The next or previous slide on request (the Home Assistant buttons),
  /// which restarts the hold from the new slide like any other hand-off.
  Future<void> _step(int direction) {
    if (_stepping != null || !mounted || _files.isEmpty) {
      return Future<void>.value();
    }
    final pending = _show(_index + direction.sign);
    _stepping = pending;
    return pending.whenComplete(() => _stepping = null);
  }

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
            // and a second _advance would skip a slide. A video stepped
            // past by a button keeps playing out its hand-off; its end is
            // no longer the slideshow's cue.
            ended = true;
            if (identical(_video, video)) _advance();
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
    c.screensaver.detachSlides(_step);
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
                            errorBuilder: (_, _, _) => const SizedBox.expand(),
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
  const ImmichScreensaver({
    super.key,
    required this.container,
    this.retryFloor = const Duration(seconds: 15),
  });

  final AppContainer container;

  /// The first wait before the listing is tried again after the server
  /// went away; each later wait doubles up to a minute. Tests shorten it.
  final Duration retryFloor;

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

  /// The second half of a pair of portrait photos: the playlist index right
  /// after [_index], its decoded provider and its aspect. Null whenever one
  /// photo (or a video) has the screen to itself, which is every landscape
  /// slide and every slide at all with "Pair portrait photos" off.
  int? _pairIndex;
  ImageProvider? _pairImage;
  double? _pairAspect;

  /// How many playlist entries the current slide consumed, so the advance
  /// steps over both halves of a pair.
  int get _span => _pairIndex == null ? 1 : 2;

  Timer? _timer;
  VideoPlayerController? _video;
  String? _problem;

  /// Image slides fetched during the current hold, by playlist index. Two
  /// at most: the next slide, and the portrait photo that may join it, so a
  /// pair hands off as promptly as a single photo does.
  final _warm = <int, Uint8List>{};

  /// Whether the metadata overlay is on and so the pair's two panels
  /// actually occupy the bottom corners. Every line turned off counts as
  /// off: there would be nothing under the photos to protect.
  bool get _metadataOn => immichMetadataVisible(c.settings);

  /// Tell the widget layer which corners this slide has taken. A pair puts
  /// a metadata panel under each half, so both bottom corners are spoken
  /// for; anything else leaves every corner to the widgets.
  void _claimCorners() {
    c.screensaver.claimedCorners.value = _pairIndex != null && _metadataOn
        ? const {'bottom_left', 'bottom_right'}
        : const {};
  }

  /// Consecutive fetch failures; a whole playlist of them means the server
  /// went away, and the message should say so instead of skipping forever.
  int _failures = 0;

  /// The last fetch failure as a user-readable reason, so the give-up
  /// message can say what actually went wrong: a rejected API key is not
  /// an unreachable server (issue #222).
  String? _lastFailure;

  /// The pending reload after the server went away, and how long the next
  /// one waits. A device that drops its network while the screen is off
  /// used to show the failure until someone restarted the screensaver; now
  /// the listing is tried again on a backoff from the widget's retryFloor
  /// to [_retryCeiling], and the slideshow resumes on its own once the
  /// server answers (issue #337).
  Timer? _retry;
  late Duration _retryDelay = widget.retryFloor;
  static const _retryCeiling = Duration(seconds: 60);

  /// Reload after [_retryDelay], doubling the wait for the time after up
  /// to the ceiling. Idempotent while one is pending.
  void _scheduleRetry() {
    if (_retry?.isActive ?? false) return;
    final delay = _retryDelay;
    c.log.info('screensaver', 'immich retrying in ${delay.inSeconds}s');
    _retry = Timer(delay, () {
      if (!mounted) return;
      _failures = 0;
      _lastFailure = null;
      unawaited(_load());
    });
    _retryDelay = delay * 2 > _retryCeiling ? _retryCeiling : delay * 2;
  }

  AppContainer get c => widget.container;

  @override
  void initState() {
    super.initState();
    c.screensaver.attachSlides(_step);
    _load();
  }

  /// See the Local Media state's [_stepping].
  Future<void>? _stepping;

  /// The next or previous slide on request. Forward steps over both halves
  /// of a showing pair, as the hold does; back goes to the photo before the
  /// pair's first, which may bring the first back as its partner.
  Future<void> _step(int direction) {
    if (_stepping != null || !mounted || _assets.isEmpty) {
      return Future<void>.value();
    }
    final pending = _show(direction > 0 ? _index + _span : _index - 1);
    _stepping = pending;
    return pending.whenComplete(() => _stepping = null);
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
        setState(
          () => _problem = immichFiltersActive(c.settings)
              ? 'No media matches the source and filters.'
              : 'No media in the selected source.',
        );
        return;
      }
      if (c.settings.get(defs.screensaverImmichShuffle)) {
        assets.shuffle(Random());
      }
      if (!mounted) return;
      // After the shuffle, so a portrait photo reaches for its partner in
      // the order the slideshow will actually run in.
      final size = MediaQuery.of(context).size;
      final arranged =
          c.settings.get(defs.screensaverImmichPairPortrait) && size.height > 0
          ? arrangeImmichPairs(assets, screenAspect: size.width / size.height)
          : assets;
      // A reload after an outage: the server is back, so the message goes
      // and the backoff starts over for the next one.
      _failures = 0;
      _lastFailure = null;
      _retryDelay = widget.retryFloor;
      setState(() {
        _assets = arranged;
        _problem = null;
      });
      _show(0);
    } catch (e) {
      c.log.warn('screensaver', 'immich listing failed: $e');
      if (mounted) {
        setState(
          () =>
              _problem = '${c.immich.readableError(e)} Retrying automatically.',
        );
        _scheduleRetry();
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
        () => _problem =
            '${_lastFailure ?? 'Could not reach the Immich server.'} '
            'Retrying automatically.',
      );
      _scheduleRetry();
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
            // and a second _advance would skip a slide. A video stepped
            // past by a button keeps playing out its hand-off; its end is
            // no longer the slideshow's cue.
            ended = true;
            if (identical(_video, video)) _advance();
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
        final oldPair = _pairImage;
        setState(() {
          _index = next;
          _imageBytes = null;
          _image = null;
          _pairIndex = null;
          _pairImage = null;
          _pairAspect = null;
        });
        _claimCorners();
        if (oldImage != null) unawaited(oldImage.evict());
        if (oldPair != null) unawaited(oldPair.evict());
        // A warmed buffer for a slide we already passed would sit through
        // the whole video for nothing.
        _warm.clear();
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
        // Consumed, so it never outlives its one use; the pairing below
        // reads its own entry, and whatever is left is stale by then.
        bytes = _warm.remove(next) ?? await c.immich.imageBytes(asset);
      } catch (e) {
        c.log.warn('screensaver', 'immich image failed (${asset.id}): $e');
        _failures++;
        _lastFailure = c.immich.readableError(e);
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
      _lastFailure = null;
      final oldImage = _image;
      final oldPair = _pairImage;
      final mq = MediaQuery.of(context);
      // A portrait photo wastes most of a landscape panel on its own, so
      // the one after it joins it when it is portrait too (each half then
      // covers its own half-screen). Only worth the extra fetch once the
      // first photo is portrait and the panel is wide enough, so an ordinary
      // landscape slideshow does no extra work at all.
      final pair = await _pairFor(next, aspect, mq.size);
      if (!mounted) {
        await old?.dispose();
        return;
      }
      _warm.clear();
      // Screen-width decode cap: server previews can still out-size a
      // small panel (Echo Show class) several times over. A paired photo
      // only ever paints half the width, so it decodes to half.
      ImageProvider sized(Uint8List data) => ResizeImage(
        MemoryImage(data),
        width: (mq.size.width * mq.devicePixelRatio / (pair == null ? 1 : 2))
            .round(),
      );
      final image = sized(bytes);
      final pairImage = pair == null ? null : sized(pair.bytes);
      // Decode before the hand-off: the switcher starts fading the moment
      // the new slide mounts, and a decode still in flight paints as
      // nothing, so the old photo would fade into black and the new one
      // pop in late (#212). Waiting here just holds the current photo a
      // beat longer, then the crossfade blends image into image.
      await Future.wait([
        precacheImage(image, context, onError: (_, _) {}),
        if (pairImage != null)
          precacheImage(pairImage, context, onError: (_, _) {}),
      ]);
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
        _pairIndex = pair?.index;
        _pairImage = pairImage;
        _pairAspect = pair?.aspect;
      });
      _claimCorners();
      if (oldImage != null) unawaited(oldImage.evict());
      if (oldPair != null) unawaited(oldPair.evict());
      final seconds = c.settings
          .get(defs.screensaverImmichInterval)
          .toInt()
          .clamp(2, 3600);
      _timer = Timer(Duration(seconds: seconds), _advance);
      unawaited(_prefetch(next + _span));
    }
    _retire(old);
  }

  /// The photo that should share the screen with the one at [index], or
  /// null when this slide stands alone: pairing off, panel too narrow,
  /// either photo not portrait, the next entry a video, a playlist with
  /// nothing else in it, or a fetch that failed (a pair is a bonus, never
  /// a reason to stall the slideshow).
  Future<({int index, Uint8List bytes, double? aspect})?> _pairFor(
    int index,
    double? aspect,
    Size screen,
  ) async {
    if (!c.settings.get(defs.screensaverImmichPairPortrait)) return null;
    if (_assets.length < 2) return null;
    final screenAspect = screen.height == 0
        ? 0.0
        : screen.width / screen.height;
    if (!immichPairableScreen(screenAspect) || !immichPortraitPhoto(aspect)) {
      return null;
    }
    final candidate = (index + 1) % _assets.length;
    final asset = _assets[candidate];
    if (asset.isVideo) return null;
    try {
      final bytes = _warm[candidate] ?? await c.immich.imageBytes(asset);
      final pairAspect = await _aspectOf(bytes);
      if (!immichPairsPortrait(
        screenAspect: screenAspect,
        first: aspect,
        second: pairAspect,
      )) {
        return null;
      }
      return (index: candidate, bytes: bytes, aspect: pairAspect);
    } catch (e) {
      // The second half is optional; the first photo shows on its own and
      // the failing asset gets its own turn (and its own error handling)
      // on the next advance.
      c.log.debug('screensaver', 'immich pair fetch failed: $e');
      return null;
    }
  }

  /// Pull the next image into memory during the current hold. Videos are
  /// skipped: they stream, and warming them means downloading them. The
  /// metadata lookup is warmed for both, so the overlay appears with the
  /// slide instead of trailing it.
  /// [partner] marks the second call of a pair, which never warms a third
  /// photo: a slideshow of portrait photos would otherwise warm its way
  /// through the whole playlist.
  Future<void> _prefetch(int index, {bool partner = false}) async {
    if (_assets.isEmpty) return;
    final next = index % _assets.length;
    final asset = _assets[next];
    if (immichMetadataVisible(c.settings)) {
      unawaited(c.immich.assetDetails(asset));
    }
    if (asset.isVideo || _warm.containsKey(next)) return;
    try {
      final bytes = await c.immich.imageBytes(asset);
      if (!mounted) return;
      _warm[next] = bytes;
      // A portrait warm slide will most likely want a partner, and pairing
      // at hand-off time would mean fetching it while the current photo
      // waits. Warm that one too, so both halves are already in hand.
      if (!partner &&
          c.settings.get(defs.screensaverImmichPairPortrait) &&
          immichPortraitPhoto(await _aspectOf(bytes))) {
        unawaited(_prefetch(next + 1, partner: true));
      }
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
    // Over both halves when a pair is showing: the second photo has had
    // its turn already.
    _show(_index + _span);
  }

  @override
  void dispose() {
    c.screensaver.detachSlides(_step);
    _timer?.cancel();
    _retry?.cancel();
    for (final t in _retireTimers) {
      t.cancel();
    }
    _video?.dispose();
    for (final v in _retiring) {
      v.dispose();
    }
    _image?.evict();
    _pairImage?.evict();
    // The corners go back to the widgets with the screensaver.
    c.screensaver.claimedCorners.value = const {};
    super.dispose();
  }

  static final _rand = Random();
  String _rolled = 'fade';

  String get _transition {
    final setting = c.settings.get(defs.screensaverImmichTransition);
    return setting == 'random' ? _rolled : setting;
  }

  /// One photo filling the frame it is given: the whole panel on its own,
  /// or half of it when it shares the screen with another portrait shot.
  ///
  /// Fill the screen: a photo shaped close enough to its frame is
  /// cover-fitted edge to edge. "Close enough" caps the crop at roughly a
  /// quarter along one axis (1.45x ratio mismatch) — it admits the common
  /// cases (4:3 or 16:9 camera frames on a 16:10 panel, either
  /// orientation, and a portrait shot in a portrait half) while shapes a
  /// crop would gut keep their full frame. Those framed photos get the
  /// photo itself, blurred and dimmed, as the backdrop instead of black
  /// bars — the Now Playing treatment.
  Widget _photoBlock({
    required ImageProvider image,
    required double? aspect,
    required double frameAspect,
    required int index,
    required String transition,
  }) {
    final fillWanted = c.settings.get(defs.screensaverImmichFill);
    var covers = false;
    if (fillWanted && aspect != null && frameAspect > 0) {
      covers = max(aspect / frameAspect, frameAspect / aspect) <= 1.45;
    }
    Widget picture = Image(
      image: image,
      fit: covers ? BoxFit.cover : BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const SizedBox.expand(),
    );
    if (transition == 'kenburns') {
      // The drift wraps only the photo: the blurred backdrop stays
      // static behind it, so it rasterizes once per slide instead of
      // re-blurring the whole screen on every animation frame.
      picture = _KenBurnsDrift(
        index: index,
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
    if (!fillWanted || covers) return SizedBox.expand(child: picture);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blur + scrim so the backdrop reads as atmosphere, not a second
        // copy of the photo (sendspin_player_overlay established the
        // recipe). ImageFiltered over the same provider, not
        // BackdropFilter: a backdrop filter must re-sample the scene every
        // frame it composites, which on weak tablet GPUs is a standing
        // 60fps blur tax.
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
    );
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
      final pairIndex = _pairIndex;
      // A pair is one slide, and its key names both halves so the switcher
      // hands off once, not twice.
      final key = ValueKey(
        '$_index:${_assets[_index].id}'
        '${pairIndex == null ? '' : '+${_assets[pairIndex].id}'}',
      );
      final size = MediaQuery.of(context).size;
      final Widget inner;
      if (isVideoSlide) {
        inner = Center(
          child: AspectRatio(
            aspectRatio: video.value.aspectRatio,
            child: VideoPlayer(video),
          ),
        );
      } else if (pairIndex == null) {
        inner = _photoBlock(
          image: _image!,
          aspect: _imageAspect,
          frameAspect: size.height == 0 ? 1 : size.width / size.height,
          index: _index,
          transition: transition,
        );
      } else {
        // Two portrait photos, half the panel each: no gutter between them,
        // since the whole point is that no screen goes to waste. Each half
        // makes its own fill decision against its half-width frame, so an
        // ordinary portrait shot covers its side completely.
        final half = size.height == 0 ? 1.0 : size.width / 2 / size.height;
        inner = Row(
          children: [
            Expanded(
              child: _photoBlock(
                image: _image!,
                aspect: _imageAspect,
                frameAspect: half,
                index: _index,
                transition: transition,
              ),
            ),
            Expanded(
              child: _photoBlock(
                image: _pairImage!,
                aspect: _pairAspect,
                frameAspect: half,
                index: pairIndex,
                transition: transition,
              ),
            ),
          ],
        );
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
        immichMetadataVisible(c.settings);
    final pairIndex = _pairIndex;
    return ColoredBox(
      color: Colors.black,
      child: showMetadata
          ? Stack(
              fit: StackFit.expand,
              children: [
                body,
                // A pair gets a panel per photo, each under its own half,
                // rather than one panel speaking for a photo it may not
                // even be next to. The corners are fixed here — the widget
                // layer stands down from both while the pair holds them.
                if (pairIndex == null)
                  _ImmichMetadata(container: c, asset: _assets[_index])
                else ...[
                  _ImmichMetadata(
                    container: c,
                    asset: _assets[_index],
                    corner: 'bottom_left',
                  ),
                  _ImmichMetadata(
                    container: c,
                    asset: _assets[pairIndex],
                    corner: 'bottom_right',
                  ),
                ],
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
  const _ImmichMetadata({
    required this.container,
    required this.asset,
    this.corner,
  });

  final AppContainer container;
  final ImmichAsset asset;

  /// The corner this panel must sit in, overriding both the setting and the
  /// step-past-a-widget search: a pair's two panels belong under their own
  /// photos, and the widgets give those corners up instead.
  final String? corner;

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
    final forced = widget.corner;
    if (forced != null) return _panel(_cornerAlignment(forced));
    // Widgets own their corners: rather than stacking two panels into
    // one corner, the metadata steps to the first free one, and stands
    // down entirely on the (unlikely) fully claimed screen. The helper
    // is shared with the At a Glance row, which narrows when this
    // settles in a bottom corner.
    final spot = immichMetadataCorner(container.settings);
    if (spot == null) return const SizedBox.shrink();
    return _panel(_cornerAlignment(spot));
  }

  /// The panel itself, anchored to [corner].
  Widget _panel(Alignment corner) {
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
    // One icon per row.
    // In a right-hand corner the icons sit on the right of their text and
    // the lines run to the right edge, mirroring the weather widget: an
    // icon column hanging off the inner side of a right-aligned block
    // reads as a ragged edge pointing at nothing.
    final right = corner.x > 0;
    Widget row(String icon, List<Widget> texts) {
      final glyph = SvgPicture.asset(
        'assets/svg/$icon.svg',
        width: 15,
        height: 15,
        colorFilter: ColorFilter.mode(
          Colors.white.withValues(alpha: 0.85),
          BlendMode.srcIn,
        ),
      );
      const gap = SizedBox(width: 9);
      final text = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: right
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: texts,
      );
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: right ? [text, gap, glyph] : [glyph, gap, text],
      );
    }

    // Only the lines the user kept (issue #268) and the asset actually
    // carries. An empty list takes the vignette with it: a corner darkened
    // for nothing reads as a smudge on the photo.
    String? kept(String field) =>
        immichMetadataFieldOn(widget.container.settings, field)
        ? details[field]
        : null;
    final album = kept('album');
    final date = kept('date');
    final camera = kept('camera');
    final exposure = kept('settings');
    final place = kept('location');
    final lines = <Widget>[
      if (album != null)
        row('album', [
          Text(album, style: style(size: 18, weight: FontWeight.w600)),
        ]),
      if (date != null) row('calendar', [Text(date, style: style(alpha: 0.9))]),
      // The camera and its exposure read as two facts, so they get a line
      // and an icon each: the camera body, then the aperture glyph over
      // the exposure it was shot at.
      if (camera != null)
        row('camera', [Text(camera, style: style(alpha: 0.9))]),
      if (exposure != null)
        row('exif', [Text(exposure, style: style(alpha: 0.8))]),
      if (place != null)
        row('location', [Text(place, style: style(alpha: 0.9))]),
    ];
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The vignette fades with content presence, not with the slide:
          // consecutive photos with metadata keep one steady vignette.
          AnimatedOpacity(
            opacity: lines.isEmpty ? 0 : 1,
            duration: _fade,
            child: _cornerVignette(corner, radius: 0.6),
          ),
          AnimatedOpacity(
            opacity: _textVisible && lines.isNotEmpty ? 1 : 0,
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

/// The camera grid as a screensaver: the configured camera views, one at a
/// time in their order, each for its dwell, non-interactive, dismissed by a
/// touch anywhere like every other mode. One view never rotates.
///
/// This is deliberately its own player rather than the camera manager's
/// active view. A view someone opened is an interaction and holds the
/// screensaver off; the screensaver showing cameras is the opposite, and
/// letting the two share state would have each cancel the other.
class CameraScreensaver extends StatefulWidget {
  const CameraScreensaver({super.key, required this.container});

  final AppContainer container;

  @override
  State<CameraScreensaver> createState() => _CameraScreensaverState();
}

class _CameraScreensaverState extends State<CameraScreensaver>
    with WidgetsBindingObserver {
  /// The rotation: the configured ids that still name a view with cameras,
  /// in order. Resolved when the screensaver comes up and again when the
  /// list is edited while it shows (from the remote admin, typically, with
  /// the black "nothing selected" cover on the panel), so the edit shows
  /// without a dismiss and restart.
  late List<CameraViewConfig> _views = _configuredViews();
  int _index = 0;
  StreamSubscription<SettingChanged>? _settingsSub;

  /// The view on screen, or null while one is being taken down between
  /// two views (and when there is nothing to show).
  CameraViewConfig? _view;
  Timer? _dwell;
  Timer? _handoff;
  bool _paused = false;

  /// Whether the view on screen has shown video yet. The dwell counts from
  /// that moment, not from the mount: negotiating the streams takes a few
  /// seconds the person should not lose from every view. A view whose
  /// cameras never come up still moves on, after the dwell plus a grace.
  bool _playing = false;

  /// Which way the hand-off in flight moves: forward on the timer, either
  /// way from the buttons.
  int _direction = 1;

  static const _connectGrace = Duration(seconds: 20);

  AppContainer get c => widget.container;

  List<CameraViewConfig> _configuredViews() {
    final ids = decodeCameraViewIds(
      c.settings.get(defs.screensaverCameraViews),
    );
    // The single view of the pre-rotation setting: the screensaver manager
    // folds it into the list at startup, this is the belt to its braces.
    if (ids.isEmpty) {
      final legacy = c.settings.get(defs.screensaverCameraView);
      if (legacy.isNotEmpty) ids.add(legacy);
    }
    final byId = {for (final view in c.camera.config.views) view.id: view};
    return [
      for (final id in ids)
        // Deleted since, or left empty: skipped, there is nothing to show.
        if (byId[id] != null && byId[id]!.cameraIds.isNotEmpty) byId[id]!,
    ];
  }

  Duration get _dwellFor => Duration(
    seconds: max(
      defs.screensaverCameraViewSecondsMin,
      c.settings.get(defs.screensaverCameraViewSeconds).round(),
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The next and previous slide buttons step the rotation like a
    // slideshow, through the same hand-off as the timer.
    c.screensaver.attachSlides(_step);
    _view = _views.firstOrNull;
    _armDwell();
    _settingsSub = c.bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.screensaverCameraViews.key) {
        _reload();
      } else if (e.key == defs.screensaverCameraViewSeconds.key) {
        // A new dwell applies from now, like the slideshow intervals.
        _armDwell();
      }
    });
  }

  /// The list changed under a showing screensaver: start over from its
  /// first view. A grid on screen leaves through the usual hand-off first;
  /// the black cover (nothing was selected) just gets the view directly.
  void _reload() {
    if (!mounted) return;
    final views = _configuredViews();
    setState(() {
      _views = views;
      _index = 0;
    });
    if (_view != null) {
      _direction = 0;
      _advance();
    } else if (_handoff != null) {
      // Mid hand-off: it lands on the new first view.
      _direction = 0;
    } else if (views.isNotEmpty) {
      _playing = false;
      setState(() => _view = views.first);
      _armDwell();
    }
  }

  /// A step from the buttons: the same hand-off as the timer, in the asked
  /// direction, and the view it lands on holds for its full dwell. Nothing
  /// to step with one view; a press mid hand-off just redirects it.
  Future<void> _step(int direction) async {
    if (!mounted || _views.length < 2) return;
    if (_view == null) {
      if (_handoff != null) _direction = direction;
      return;
    }
    _direction = direction;
    _advance();
  }

  /// The full dwell once the view plays; until then the dwell plus the
  /// connect grace, so a dead camera cannot stall the rotation on itself.
  void _armDwell() {
    _dwell?.cancel();
    if (_views.length < 2 || _paused) return;
    _dwell = Timer(_playing ? _dwellFor : _dwellFor + _connectGrace, _advance);
  }

  void _onPlaying() {
    if (_playing || _view == null) return;
    _playing = true;
    _armDwell();
  }

  /// Two steps, never one. The grid on screen is taken down first, which
  /// runs [ClosingCameraPlayer]'s exit: the page stops its streams from a
  /// mounted widget and is dropped after the shutdown grace. Only then is
  /// the next view mounted, so two grids never run at once (a second set
  /// of peer connections and decoders on top of one still winding down is
  /// exactly what a low-RAM tablet cannot take) and no player is disposed
  /// mid-teardown with its streams still alive, which is the leak the
  /// wrapper exists to prevent. The moment of black between the two is the
  /// price, and the next grid takes longer than that to negotiate anyway.
  void _advance() {
    if (!mounted || _view == null) return;
    setState(() => _view = null);
    _playing = false;
    _dwell?.cancel();
    _handoff?.cancel();
    _handoff = Timer(
      ClosingCameraPlayer.shutdownGrace + const Duration(milliseconds: 100),
      () {
        _handoff = null;
        if (!mounted) return;
        if (_views.isEmpty) {
          _direction = 1;
          return;
        }
        _index = (_index + _direction) % _views.length;
        _direction = 1;
        c.log.debug(
          'screensaver',
          'camera view ${_index + 1}/${_views.length}: '
              '${_views[_index].name}',
        );
        setState(() => _view = _views[_index]);
        _armDwell();
      },
    );
  }

  /// A grid nobody sees is not worth cycling: while the app is behind
  /// another app or a dark panel the dwell stops where it is, and a fresh
  /// one starts on return. A rotation mid hand-off still completes it, so
  /// the screen is never left black.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final paused =
        state != AppLifecycleState.resumed &&
        state != AppLifecycleState.inactive;
    if (paused == _paused) return;
    _paused = paused;
    if (paused) {
      _dwell?.cancel();
    } else {
      _armDwell();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    c.screensaver.detachSlides(_step);
    _settingsSub?.cancel();
    _dwell?.cancel();
    _handoff?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => c.screensaver.notifyActivity('touch'),
    // Black under it all: no view chosen, every chosen one deleted or
    // emptied since (the same safe cover an unknown mode gets), and the
    // hand-off between two views.
    child: ColoredBox(
      color: Colors.black,
      child: _views.isEmpty && _handoff == null
          ? const SizedBox.expand()
          // One wrapper for the whole rotation, never keyed by view: a
          // view change has to go through its exit (see _advance), and a
          // new wrapper per view would drop the old player on the spot.
          : ClosingCameraPlayer(
              container: c,
              view: _view,
              interactive: false,
              onDismiss: () => c.screensaver.notifyActivity('touch'),
              onPlaying: _onPlaying,
            ),
    ),
  );
}
