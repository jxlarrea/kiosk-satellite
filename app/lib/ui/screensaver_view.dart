import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import 'alarms_overlay.dart' show alarmTimeText;
import '../managers/alarms/alarm_manager.dart';
import 'alarm_ring_overlay.dart';
import 'clock_setting.dart';
import 'calendar_overlay.dart'
    show
        CalendarAvatarStack,
        CalendarBands,
        CalendarPaint,
        CalendarScreen,
        calendarTime;
import '../managers/calendar/calendar_manager.dart';
import '../managers/calendar/calendar_model.dart' as cal_model;
import '../app_container.dart';
import '../l10n/messages.dart';
import '../core/events.dart';
import '../core/locale_dates.dart';
import '../managers/browser/ha_session_script.dart';
import '../managers/browser/viewport_zoom_script.dart';
import '../managers/browser/vs_suppress_script.dart';
import '../managers/home_assistant/kiosk_mode.dart';
import '../managers/glance/glance_manager.dart'
    show GlanceEntity, glanceAttributeText;
import '../managers/home_assistant/home_assistant_manager.dart'
    show GlanceSubscription;
import '../managers/screensaver/immich_manager.dart'
    show
        ImmichAsset,
        ImmichPairing,
        arrangeImmichPairs,
        immichFiltersActive,
        immichMetadataShown,
        immichMetadataVisible,
        immichPairPhoto,
        immichPairingFor;
import '../managers/camera/models.dart'
    show CameraViewConfig, decodeCameraViewIds;
import '../managers/device/haptics.dart';
import '../managers/screensaver/photo_metadata.dart';
import '../managers/screensaver/screensaver_widgets.dart';
import '../managers/settings/definitions.dart' as defs;
import '../managers/settings/settings_manager.dart';

import 'camera_view_overlay.dart' show ClosingCameraPlayer;
import 'clock_faces.dart';
import 'digital_clock_face.dart';
import 'weather_readings.dart';
import 'photo_frames.dart';
import 'plugin_screensaver.dart';
import 'celestial_screensaver.dart';
import 'weather_mood_screensaver.dart';

import 'glance_row.dart';
import 'sendspin_player_overlay.dart' show SendspinFullscreenView;
import 'ui_scale.dart' show UiScaleExempt;
import 'video_surface.dart';
import 'webview_server_trust.dart';

export 'photo_frames.dart' show photoCovers;

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

  /// Whether the Clock screensaver's Night mode holds (issue #391), as the
  /// screensaver manager decides it. Read here rather than in the clock
  /// face because the corner widgets, which ride over the face from this
  /// overlay, take the night color too.
  bool get _night => container.screensaver.clockNight.value;

  AppContainer get container => widget.container;

  @override
  void initState() {
    super.initState();
    container.screensaver.scheduleNowPlaying.addListener(_scheduleChanged);
    container.screensaver.clockNight.addListener(_scheduleChanged);
    container.screensaver.pluginTint.addListener(_scheduleChanged);
    // Editing the Widgets group while the screensaver shows (the remote
    // admin can) applies immediately: the widget list is read at build,
    // so a changed list needs this rebuild to mount or unmount overlays.
    // The scaling slider rides along and doubles as a live preview.
    // The photo metadata lines ride along for the same reason: their
    // toggles are read at build, so turning one off has to reach the
    // panel already on screen. So do the At a Glance switch and style,
    // read at build by the overlay row the photo and web modes carry.
    final live = {
      defs.screensaverWidgets.key,
      defs.screensaverWidgetsEnabled.key,
      defs.screensaverWeatherEntity.key,
      defs.screensaverWeatherPreview.key,
      defs.screensaverWeatherBar.key,
      defs.screensaverWeatherBarScale.key,
      defs.screensaverWidgetScale.key,
      defs.screensaverWidgetFont.key,
      defs.screensaverWidgetFontWeight.key,
      defs.screensaverWidgetTextShadow.key,
      defs.screensaverVignetteStrength.key,
      defs.screensaverGlanceEnabled.key,
      defs.screensaverGlanceTextOnly.key,
      defs.screensaverGlanceBwIcons.key,
      defs.screensaverGlanceHideNames.key,
      defs.screensaverGlanceScale.key,
      defs.screensaverGlanceFont.key,
      defs.screensaverGlanceFontWeight.key,
      defs.screensaverClockNightHideWidgets.key,
      // The Now Playing transport, read at build by the full-screen view.
      defs.sendspinFullscreenControls.key,
      defs.sendspinFullscreenSplit.key,
      defs.sendspinFullscreenPhotoFill.key,
      // Whether the dashboard mode's clear layer takes taps.
      defs.screensaverDashboardDoubleTap.key,
      // The edge zones (issue #453), read at build by the row below the
      // mode, so the toggle mounts or unmounts them on the spot.
      for (final def in slideEdgeTapDefs.values) def.key,
      for (final metadata in photoMetadataDefs.values)
        for (final def in metadata.all) def.key,
    };
    // The Night mode colors ride along so they can be tuned from the
    // remote admin against the live face. The manager remakes the decision
    // itself when its switch or threshold moves.
    live.addAll({
      defs.screensaverClockNightColor.key,
      defs.screensaverClockNightBgColor.key,
      defs.screensaverClockNightCardColor.key,
    });
    _widgetsSub = container.bus.on<SettingChanged>().listen((e) {
      if (mounted && live.contains(e.key)) setState(() {});
    });
  }

  void _scheduleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    container.screensaver.scheduleNowPlaying.removeListener(_scheduleChanged);
    container.screensaver.clockNight.removeListener(_scheduleChanged);
    container.screensaver.pluginTint.removeListener(_scheduleChanged);
    _widgetsSub?.cancel();
    super.dispose();
  }

  /// Whether Night mode clears the corner widgets off the Clock
  /// screensaver (issue #784). The face drops its own At a Glance row on
  /// the same switch.
  bool _widgetsNightHidden(String view) =>
      view == 'clock' &&
      _night &&
      container.settings.get(defs.screensaverClockNightHideWidgets);

  /// The color Night mode imposes on the corner widgets over the Clock
  /// screensaver, or the tint a plugin screensaver asked for over itself
  /// (issue #1299), or null: on any other view the widgets keep their own,
  /// Night mode being the clock's.
  Color? _widgetNightColor(String view) {
    if (view == 'clock' && _night) {
      return _rgbOr(
        container.settings.get(defs.screensaverClockNightColor),
        const Color(0xFF822222),
      );
    }
    final tint = container.screensaver.pluginTint.value;
    return tint != null && tint.mode == view ? Color(tint.color) : null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: container.screensaver.activeView,
      builder: (context, view, _) {
        if (view == null || view == 'blank') return const SizedBox.shrink();
        // A Black screensaver asked to look off (issue #151): one switch
        // blanks the overlays instead of asking people to unconfigure the
        // small clock and At a Glance row for the night.
        final weatherUnset =
            view == 'weather_mood' && !weatherMoodHasScene(container.settings);
        final blackBare =
            view == 'black' &&
            container.settings.get(defs.screensaverBlackHideExtras);
        return ListenableBuilder(
          // An alarm on the screensaver keeps it: its music plays, but Now
          // Playing stays behind until the alarm lets go.
          listenable: Listenable.merge([
            container.sendspin.fullscreenActive,
            container.screensaver.alarmTakeover,
          ]),
          builder: (context, child) {
            final nowPlaying = container.sendspin.fullscreenActive.value;
            final scheduled = container.screensaver.scheduleNowPlaying.value;
            final playing =
                nowPlaying &&
                container.settings.get(defs.sendspinFullscreen) &&
                scheduled != false &&
                container.screensaver.alarmTakeover.value == null;
            return Positioned.fill(
              child: _ScreensaverPlayerLayout(
                container: container,
                split:
                    scheduled ??
                    container.settings.get(defs.sendspinFullscreenSplit),
                photoFill: container.settings.get(
                  defs.sendspinFullscreenPhotoFill,
                ),
                screensaver: child!,
                player: playing
                    ? (shared) => _Dismissable(
                        container: container,
                        child: SendspinFullscreenView(
                          container: container,
                          alongsideScreensaver: shared,
                        ),
                      )
                    : null,
              ),
            );
          },
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                switch (view) {
                  // A touch renderer keeps its taps (issue #1282) and the
                  // kiosk screen's raw pointer reports run the manager's
                  // double-tap chain, as on the dashboard.
                  final mode when defs.isPluginScreensaver(mode) =>
                    ValueListenableBuilder(
                      valueListenable: container.plugins.screensavers,
                      builder: (context, _, child) => _Dismissable(
                        container: container,
                        enabled: !container.plugins.screensaverTouch(mode),
                        child: child!,
                      ),
                      child: UiScaleExempt(
                        child: PluginScreensaver(
                          container: container,
                          mode: mode,
                        ),
                      ),
                    ),
                  'weather_mood' => _Dismissable(
                    container: container,
                    child: UiScaleExempt(
                      child: WeatherMoodScreensaver(container: container),
                    ),
                  ),
                  // Not wrapped in _Dismissable: the calendar keeps its
                  // touches, and its X ends the screensaver.
                  'calendar' => CalendarScreen(
                    container: container,
                    screensaver: true,
                  ),
                  // Not wrapped in _Dismissable: a drag looks around the
                  // sky, and the view closes itself on a double tap.
                  'celestial' => UiScaleExempt(
                    child: CelestialScreensaver(container: container),
                  ),
                  'clock' => _Dismissable(
                    container: container,
                    child: ClockScreensaver(
                      container: container,
                      night: _night,
                    ),
                  ),
                  // Exempt from the Scale UI factor like every WebView: the
                  // page renders at its own scale. The metadata panel is
                  // Flutter's, over the page, and scales like Immich's. The
                  // Stack stays put when the panel comes and goes, so the
                  // page is never remounted for it.
                  'media' => Stack(
                    fit: StackFit.expand,
                    children: [
                      UiScaleExempt(
                        child: ScreensaverWebView(
                          container: container,
                          mode: view,
                        ),
                      ),
                      if (photoMetadataVisible(container.settings, view))
                        ValueListenableBuilder(
                          valueListenable: container.screensaver.mediaSlide,
                          builder: (context, slide, _) => _PhotoMetadata(
                            container: container,
                            mode: view,
                            slide: slide?.id,
                            // Only asked for while there is a slide.
                            details: () => remotePhotoDetails(
                              slide!.id,
                              Uri.parse(slide.url),
                            ),
                          ),
                        ),
                    ],
                  ),
                  'website' => UiScaleExempt(
                    child: ScreensaverWebView(container: container, mode: view),
                  ),
                  'local' || 'gallery' => _Dismissable(
                    container: container,
                    child: LocalMediaScreensaver(
                      container: container,
                      mode: view,
                    ),
                  ),
                  'url' => _Dismissable(
                    container: container,
                    child: ImageUrlScreensaver(container: container),
                  ),
                  'immich' => _Dismissable(
                    container: container,
                    child: ImmichScreensaver(container: container),
                  ),
                  // The camera grid reports its own touches (the WebView
                  // swallows Flutter gestures), so it dismisses itself
                  // rather than sitting under _Dismissable.
                  'camera' => CameraScreensaver(container: container),
                  // The Home Assistant Dashboard mode: the dashboard itself
                  // shows through a clear layer that takes the tap, so a
                  // touch dismisses rather than pressing a card. With
                  // Double tap to dismiss there is no layer: taps reach the
                  // cards and the kiosk screen's raw pointer reports run
                  // the manager's double-tap chain.
                  'dashboard'
                      when container.settings.get(
                        defs.screensaverDashboardDoubleTap,
                      ) =>
                    const SizedBox.shrink(),
                  'dashboard' => _Dismissable(
                    container: container,
                    child: const SizedBox.expand(),
                  ),
                  // Dim beside a shared player: the page shows through,
                  // with nothing over it.
                  'dim' => _Dismissable(
                    container: container,
                    child: const SizedBox.expand(),
                  ),
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
                // The slideshow modes' edge zones (issue #453): a tap on
                // the outer fifth of either side steps the deck instead of
                // waking. Over the mode, so the mode's tap-to-wake never
                // sees those taps, and under the corner widgets and the
                // At a Glance row, which ignore pointers anyway.
                if (slideEdgeTapsEnabled(container.settings, view))
                  _SlideEdges(container: container),
                // The At a Glance row rides over the photo and web modes
                // too, pinned to the bottom the way the Clock screensaver
                // pins it. Black and Clock place their own row (centred,
                // under the clock), and the calendar and the camera grid
                // stay clear, the same line the corner widgets draw. IgnorePointer keeps
                // taps falling through to the mode underneath: dismissal
                // for the native modes, the page for the web ones.
                if (!blackBare &&
                    !weatherUnset &&
                    view != 'dim' &&
                    view != 'black' &&
                    view != 'clock' &&
                    view != 'weather_mood' &&
                    view != 'calendar' &&
                    view != 'camera')
                  _StepAside(
                    container: container,
                    child: ValueListenableBuilder<bool?>(
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
                            // Photo metadata in a bottom corner, whether
                            // the Immich pair's two panels (which claim
                            // theirs live) or the single-photo panel's
                            // settled spot, and the row narrows to
                            // portrait's two columns so it wraps clear of
                            // the panels instead of spreading into them.
                            final metadata = photoMetadataCorner(
                              container.settings,
                              view,
                            );
                            final narrow =
                                claimed.any((c) => c.startsWith('bottom_')) ||
                                metadata == 'bottom_left' ||
                                metadata == 'bottom_right';
                            if (!narrow ||
                                !photoMetadataDefs.containsKey(view)) {
                              return _GlanceOverlay(
                                container: container,
                                narrow: narrow,
                                night: _widgetNightColor(view),
                              );
                            }
                            // Once the panels have been measured, the row
                            // fits itself to the room they leave.
                            return ValueListenableBuilder<Map<String, Size>>(
                              valueListenable:
                                  container.screensaver.metadataFootprint,
                              builder: (context, footprint, _) =>
                                  _GlanceOverlay(
                                    container: container,
                                    narrow: true,
                                    corners: footprint.values,
                                    night: _widgetNightColor(view),
                                  ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                // The corner widgets ride over every mode their type
                // allows (the small clock stays off Clock, which is one
                // already, and the camera grid, where it sits over a live
                // feed). The active schedule entry can withhold them for
                // its hours — widgets by day, a bare screen at night —
                // which is why they hang off their own listenable: a
                // boundary between two entries of the same mode changes
                // nothing else this widget rebuilds on.
                if (!blackBare && !weatherUnset && view != 'dim')
                  _StepAside(
                    container: container,
                    child: ValueListenableBuilder<bool?>(
                      valueListenable: container.screensaver.scheduleWidgets,
                      // A mode can also claim corners for itself while it
                      // runs (the Immich pair's two metadata panels): a
                      // widget in a claimed corner stands down until the
                      // corner is free again, rather than sitting on top of
                      // what claimed it.
                      builder: (context, scheduled, _) =>
                          ValueListenableBuilder<Set<String>>(
                            valueListenable:
                                container.screensaver.claimedCorners,
                            builder: (context, claimed, _) =>
                                _AboveWeatherChips(
                                  container: container,
                                  enabled: view == 'weather_mood',
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if ((scheduled ?? true) &&
                                          !_widgetsNightHidden(view))
                                        for (final spec
                                            in activeScreensaverWidgets(
                                              container.settings,
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
                                                nightColor: _widgetNightColor(
                                                  view,
                                                ),
                                              ),
                                              'weather' => WeatherWidgetOverlay(
                                                container: container,
                                                spec: spec,
                                                nightColor: _widgetNightColor(
                                                  view,
                                                ),
                                              ),
                                              'forecast' =>
                                                ForecastWidgetOverlay(
                                                  container: container,
                                                  spec: spec,
                                                  nightColor: _widgetNightColor(
                                                    view,
                                                  ),
                                                ),
                                              'battery' => BatteryWidgetOverlay(
                                                container: container,
                                                spec: spec,
                                                nightColor: _widgetNightColor(
                                                  view,
                                                ),
                                              ),
                                              'entity' => EntityWidgetOverlay(
                                                container: container,
                                                spec: spec,
                                                nightColor: _widgetNightColor(
                                                  view,
                                                ),
                                              ),
                                              'alarm' => AlarmWidgetOverlay(
                                                container: container,
                                                spec: spec,
                                                nightColor: _widgetNightColor(
                                                  view,
                                                ),
                                              ),
                                              'calendar' =>
                                                CalendarWidgetOverlay(
                                                  container: container,
                                                  spec: spec,
                                                  nightColor: _widgetNightColor(
                                                    view,
                                                  ),
                                                ),
                                              _ => const SizedBox.shrink(),
                                            },
                                    ],
                                  ),
                                ),
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

/// Fades the corner widgets and the At a Glance row out while the running
/// mode shows its own controls, so the two never stack.
class _StepAside extends StatelessWidget {
  const _StepAside({required this.container, required this.child});
  final AppContainer container;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: container.screensaver.modeControlsShown,
    builder: (context, shown, child) => IgnorePointer(
      ignoring: shown,
      child: AnimatedOpacity(
        opacity: shown ? 0 : 1,
        duration: const Duration(milliseconds: 250),
        child: child,
      ),
    ),
    child: child,
  );
}

/// Gives each surface its own viewport so clocks, photos and player controls
/// size themselves to their panel. Stable slots keep a slideshow running when
/// playback ends and its panel expands back to the whole screen.
class _ScreensaverPlayerLayout extends StatelessWidget {
  const _ScreensaverPlayerLayout({
    required this.container,
    required this.split,
    required this.photoFill,
    required this.screensaver,
    required this.player,
  });

  final AppContainer container;
  final bool split;
  final String photoFill;
  final Widget screensaver;
  final Widget Function(bool shared)? player;

  Widget _pane(BuildContext context, Rect rect, String name, Widget child) =>
      Positioned.fromRect(
        key: ValueKey(name),
        rect: rect,
        child: RepaintBoundary(
          child: ClipRect(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(size: rect.size),
              child: child,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = box.biggest;
      final landscape = size.width > size.height;
      final shared =
          split &&
          player != null &&
          (landscape ? size.width >= 700 : size.height >= 700);
      final full = Offset.zero & size;
      final Rect saverRect;
      final Rect playerRect;
      if (shared && landscape) {
        final playerWidth = (size.width / 3).clamp(280.0, size.width / 2);
        saverRect = Rect.fromLTWH(0, 0, size.width - playerWidth, size.height);
        playerRect = Rect.fromLTWH(
          saverRect.right,
          0,
          playerWidth,
          size.height,
        );
      } else if (shared) {
        saverRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.5);
        playerRect = Rect.fromLTWH(
          0,
          saverRect.bottom,
          size.width,
          size.height - saverRect.height,
        );
      } else {
        saverRect = full;
        playerRect = full;
      }
      container.screensaver.setNowPlayingShared(
        shared,
        panel: !shared
            ? EdgeInsets.zero
            : landscape
            ? EdgeInsets.only(right: playerRect.width)
            : EdgeInsets.only(bottom: playerRect.height),
      );
      return Stack(
        fit: StackFit.expand,
        children: [
          if (player == null || shared)
            _pane(
              context,
              saverRect,
              'screensaver-pane',
              PhotoFillOverride(
                fill: shared && photoFill != 'default' ? photoFill : null,
                // Opaque when shared: a clear pane (the dashboard with
                // Double tap to dismiss) still takes the touch that
                // dismisses, as every shared pane does.
                child: Listener(
                  behavior: shared
                      ? HitTestBehavior.opaque
                      : HitTestBehavior.deferToChild,
                  onPointerDown: shared
                      ? (_) => container.screensaver.notifyActivity(
                          'screensaver_touch',
                        )
                      : null,
                  child: screensaver,
                ),
              ),
            ),
          if (player != null)
            _pane(context, playerRect, 'now-playing-pane', player!(shared)),
        ],
      );
    },
  );
}

/// The edge-tap switch of each slideshow mode (issue #453), by the view
/// name the overlay mounts it under.
const slideEdgeTapDefs = <String, defs.SettingDef<bool>>{
  'media': defs.screensaverMediaEdgeTaps,
  'local': defs.screensaverLocalEdgeTaps,
  'gallery': defs.screensaverGalleryEdgeTaps,
  'url': defs.screensaverUrlEdgeTaps,
  'immich': defs.screensaverImmichEdgeTaps,
};

/// The share of the width each edge zone takes: a fifth on either side,
/// the middle three fifths still wake.
const slideEdgeFraction = 0.2;

/// Whether [view] shows edge zones: a slideshow mode with its switch on.
/// Home Assistant Media only when it plays a folder; a single image, a
/// video or a camera has nothing to step, so every tap wakes as before.
bool slideEdgeTapsEnabled(SettingsManager settings, String view) {
  final def = slideEdgeTapDefs[view];
  if (def == null || !settings.get(def)) return false;
  if (view == 'media' && !settings.get(defs.screensaverMediaIsFolder)) {
    return false;
  }
  return true;
}

/// Two invisible strips, the outer fifth of either side: a tap on the left
/// shows the previous slide, on the right the next, each resetting the
/// slide's full dwell exactly as the ESPHome buttons do. The strips are
/// opaque to hit testing, so neither the mode's tap-to-wake wrapper nor a
/// WebView underneath sees the touch; the kiosk screen's raw Listener
/// still does, and the mark on the pointer's way down tells the manager
/// to let that report pass. A press that turns into a drag steps nothing
/// and wakes nothing.
class _SlideEdges extends StatelessWidget {
  const _SlideEdges({required this.container});

  final AppContainer container;

  void _step(int direction) {
    if (container.settings.get(defs.haHaptics)) {
      Haptics.tap(strength: container.settings.get(defs.haHapticsStrength));
    }
    unawaited(container.screensaver.stepSlide(direction));
  }

  Widget _zone(int direction) => Listener(
    onPointerDown: (_) => container.screensaver.markSlideTouch(),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _step(direction),
      child: const SizedBox.expand(),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth * slideEdgeFraction;
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: width,
            child: _zone(-1),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: width,
            child: _zone(1),
          ),
        ],
      );
    },
  );
}

/// Tap anywhere to wake. Used by the native views; the WebView reports its own
/// taps over the JS bridge, since it swallows Flutter gestures.
class _Dismissable extends StatelessWidget {
  const _Dismissable({
    required this.container,
    required this.child,
    this.enabled = true,
  });

  final AppContainer container;
  final Widget child;

  /// Off while the child keeps its own taps. It stays in the tree so the
  /// child is not rebuilt when that changes.
  final bool enabled;

  /// 'tap', not 'touch': the kiosk screen's raw pointer Listener has
  /// already reported this finger on its way down, and this fires as it
  /// lifts. The manager takes it as that touch's echo, so the double-tap
  /// chain counts one tap per finger rather than one per phase.
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: enabled ? () => container.screensaver.notifyActivity('tap') : null,
    child: child,
  );
}

/// A timeout cover above widgets, timers and notifications. A voice turn
/// draws over it: while the voice overlay is up the kiosk places the cover
/// right under it instead ([underVoice]), so the turn shows on black.
class ScreensaverBlankOverlay extends StatelessWidget {
  const ScreensaverBlankOverlay({
    super.key,
    required this.container,
    this.underVoice = false,
  });

  final AppContainer container;

  /// This copy is the one under the voice overlay, shown only during a
  /// turn; the other is shown only outside one.
  final bool underVoice;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      container.screensaver.activeView,
      container.screensaver.renderPaused,
    ]),
    builder: (context, _) =>
        container.screensaver.activeView.value == 'blank' &&
            container.screensaver.renderPaused.value == underVoice
        ? Positioned.fill(
            child: _Dismissable(
              container: container,
              child: const ColoredBox(color: Colors.black),
            ),
          )
        : const SizedBox.shrink(),
  );
}

/// A full-screen digital clock over black, mirroring Voice Satellite's clock.
/// The font is the Font setting's pick (issue #391), Rubik by default, so
/// out of the box the screensaver never looks like a different app from the
/// settings behind it; clockFontFamily (clock_faces.dart) does the mapping
/// for all four faces.
class ClockScreensaver extends StatefulWidget {
  const ClockScreensaver({
    super.key,
    required this.container,
    this.night = false,
  });

  final AppContainer container;

  /// Whether Night mode holds (issue #391): the digits, the date, the At a
  /// Glance row and the flip cards take their night colors and the night
  /// background covers the backdrop. Decided by the overlay above, which
  /// applies the same color to the corner widgets riding over the face.
  final bool night;

  @override
  State<ClockScreensaver> createState() => _ClockScreensaverState();
}

class _ClockScreensaverState extends State<ClockScreensaver>
    with _PhotoScreenState<ClockScreensaver> {
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
  /// the aspect its fill treatment keys off. The path and display size
  /// form [_bgKey], so unchanged rebuilds do no image work.
  Object? _bgKey;
  PreparedPhoto? _bgPhoto;
  double? _bgAspect;
  ImageProvider? _bgImage;
  StreamSubscription<SettingChanged>? _bgSub;

  /// The Refresh URL background interval (issue #464), and the one-shot
  /// retry a failed URL fetch arms so a clock started before Wi-Fi came
  /// up still gets its photo.
  Timer? _bgRefresh;
  Timer? _bgRetry;

  /// The settings the face reads at build and applies the moment they
  /// change, rather than at the next minute tick: the background and its
  /// refresh, the font, and every color of the four faces, so an
  /// automation writing a color through the remote API (a trash-day
  /// reminder turning the clock green) shows it on the clock already on
  /// screen, the way the Night mode keys do through the overlay.
  static final _liveKeys = {
    defs.screensaverClockBackground.key,
    defs.screensaverClockBackgroundRefresh.key,
    defs.screensaverClockNightHideBackground.key,
    defs.screensaverClockNightHideWidgets.key,
    defs.screensaverClockFont.key,
    defs.screensaverClockFontWeight.key,
    defs.screensaverClockVertical.key,
    defs.screensaverClock24h.key,
    defs.screensaverClockAmPm.key,
    defs.screensaverClockColor.key,
    defs.screensaverClockBgColor.key,
    defs.screensaverFlipDigitColor.key,
    defs.screensaverFlipBgColor.key,
    defs.screensaverFlipBackdropColor.key,
    defs.screensaverRollerDigitColor.key,
    defs.screensaverRollerBgColor.key,
    defs.screensaverHandNumbers.key,
    defs.screensaverHandColor.key,
    defs.screensaverHandBgColor.key,
  };

  /// Bounds a URL fetch: a host that accepts the connection and never
  /// answers would otherwise hold the clock's photo hostage.
  static const _bgFetchTimeout = Duration(seconds: 30);
  static const _bgRetryDelay = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _watchPhotoScreen(widget.container);
    _scheduleTick();
    if (_awake && widget.container.settings.get(defs.screensaverPixelShift)) {
      // Nudge the whole face once a minute so a static clock cannot burn in.
      _shift = Timer.periodic(const Duration(minutes: 1), (_) => _nudge());
    }
    // The face only rebuilds on clock ticks, a minute apart with seconds
    // off — a background pushed over ESPHome (issue #150) must not wait out
    // the minute. The Font and Vertical mode keys ride the same listener
    // so they can be tuned from the remote admin against the live face;
    // the Night mode keys reach the face through the overlay, which owns
    // that decision.
    _bgSub = widget.container.bus.on<SettingChanged>().listen((e) {
      if (!mounted) return;
      if (e.key == defs.screensaverClockBackground.key ||
          e.key == defs.screensaverClockBackgroundRefresh.key) {
        // Every write reloads, an unchanged value included (issue #464):
        // rewriting the entity is how Home Assistant asks for a fresh
        // copy of a URL, or of a file replaced under its old name.
        _bgKey = null;
        _armBackgroundRefresh();
      }
      // The seconds hand sets the tick rate, so turning it on must not
      // leave the hand parked until the next minute.
      if (e.key == defs.screensaverHandSeconds.key) {
        _tick?.cancel();
        _now = DateTime.now();
        _scheduleTick();
        setState(() {});
      }
      if (_liveKeys.contains(e.key)) setState(() {});
    });
    _armBackgroundRefresh();
    widget.container.screensaver.alarmTakeover.addListener(_onTakeover);
  }

  void _onTakeover() {
    if (mounted) setState(() {});
  }

  /// Fetch a URL background again every Refresh URL background minutes
  /// (issue #464); nothing for a file, a blank, or a zero interval. Only
  /// while the screen is lit: the dark clock does no image work.
  void _armBackgroundRefresh() {
    _bgRefresh?.cancel();
    _bgRefresh = null;
    if (!_awake) return;
    final s = widget.container.settings;
    final minutes = s.get(defs.screensaverClockBackgroundRefresh);
    if (minutes <= 0 ||
        !defs.isClockBackgroundUrl(s.get(defs.screensaverClockBackground))) {
      return;
    }
    _bgRefresh = Timer.periodic(Duration(minutes: minutes.round()), (_) {
      if (!mounted) return;
      _bgKey = null;
      setState(() {});
    });
  }

  @override
  void _photoScreenChanged(bool awake) {
    _tick?.cancel();
    _shift?.cancel();
    _bgRetry?.cancel();
    _bgRetry = null;
    _armBackgroundRefresh();
    if (!awake) return;
    _now = DateTime.now();
    _scheduleTick();
    if (widget.container.settings.get(defs.screensaverPixelShift)) {
      _shift = Timer.periodic(const Duration(minutes: 1), (_) => _nudge());
    }
  }

  /// The digit color Night mode imposes, or null while it stands down.
  Color? _nightColor() => widget.night
      ? _rgb(defs.screensaverClockNightColor, const Color(0xFF822222))
      : null;

  /// The backdrop Night mode imposes, likewise.
  Color? _nightBg() => widget.night
      ? _rgb(defs.screensaverClockNightBgColor, Colors.black)
      : null;

  /// The flip card color Night mode imposes, likewise: the cards are the
  /// one part of the face the night background leaves alone.
  Color? _nightCard() => widget.night
      ? _rgb(defs.screensaverClockNightCardColor, const Color(0xFF141414))
      : null;

  // Re-align to each wall-clock second (or minute, when seconds are not
  // shown — the face only changes once a minute then, and a per-second
  // rebuild would be 60x the wakeups for identical pixels) rather than
  // drifting off a fixed period.
  void _scheduleTick() {
    if (!_awake) return;
    final now = DateTime.now();
    // Seconds only exist on the digital face and the hand clock's seconds
    // hand. The flip face changes once a minute, so ticking it per second
    // would be 60x the wakeups (and 60x the flip animations) for identical
    // output; the roller runs its own per-frame ticker and ignores this
    // timer entirely.
    final s = widget.container.settings;
    final secs = switch (s.get(defs.screensaverClockStyle)) {
      'digital' => s.get(defs.screensaverClockSeconds),
      'hand' => s.get(defs.screensaverHandSeconds),
      _ => false,
    };
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
    widget.container.screensaver.alarmTakeover.removeListener(_onTakeover);
    _tick?.cancel();
    _shift?.cancel();
    _bgSub?.cancel();
    _bgRefresh?.cancel();
    _bgRetry?.cancel();
    _bgPhoto?.dispose();
    super.dispose();
  }

  Color _rgb(defs.SettingDef<String> def, Color orElse) =>
      _rgbOr(widget.container.settings.get(def), orElse);

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
    if (!h24 && s.get(defs.screensaverClockAmPm)) {
      t += _now.hour < 12 ? ' AM' : ' PM';
    }
    return t;
  }

  // Localized via the device locale, names and word order both (issue #108):
  // "Sunday, August 2" on an American device, "zondag 2 augustus" on a
  // Dutch one.
  String _date() => fullDate(_now);

  /// Re-resolve the background provider when the setting moved. A file is
  /// keyed with its stamp too, so an image overwritten under an unchanged
  /// name (issue #464) is picked up on the next tick, no rotating filename
  /// needed. A missing file resolves to nothing but is not marked seen, so
  /// a path published before its file lands (issue #150) starts showing
  /// on the rebuild after the file appears; a restore onto another
  /// device, whose setting names a copy that never came along, just keeps
  /// the solid color instead of taking the clock down. A URL (issue #464)
  /// is fetched by the app itself, through the same certificate policy as
  /// every other client in the process; a failed fetch keeps whatever
  /// photo is up and tries again in a minute rather than blanking the
  /// clock over a transient outage. [fill] is in the key so the decode
  /// width follows a Fill the screen change.
  void _ensureBackground(String value, Size size, double dpr, String fill) {
    final url = defs.isClockBackgroundUrl(value);
    FileStat? stat;
    if (!url && value.isNotEmpty) {
      stat = FileStat.statSync(value);
      if (stat.type == FileSystemEntityType.notFound) {
        _bgKey = null;
        _bgAspect = null;
        _bgImage = null;
        return;
      }
    }
    final key = (value, size, dpr, fill, stat?.modified, stat?.size);
    if (key == _bgKey) return;
    _bgKey = key;
    _bgRetry?.cancel();
    _bgRetry = null;
    if (value.isEmpty) {
      _bgAspect = null;
      _bgImage = null;
      _bgPhoto?.dispose();
      _bgPhoto = null;
      return;
    }
    unawaited(() async {
      try {
        final bytes = url
            ? await fetchScreensaverImage(value, timeout: _bgFetchTimeout)
            : await File(value).readAsBytes();
        await _waitForPhotoScreen();
        if (!mounted || _bgKey != key) return;
        final photo = await PreparedPhoto.prepare(
          bytes,
          context: context,
          frame: size * dpr,
          fill: fill,
          zoom: false,
          valid: () => mounted && _bgKey == key,
          beforeDecode: _waitForPhotoScreen,
        );
        final old = _bgPhoto;
        setState(() {
          _bgPhoto = photo;
          _bgAspect = photo.aspect;
          _bgImage = photo.image;
        });
        old?.dispose();
      } catch (e) {
        if (!mounted || _bgKey != key) return;
        if (!url) {
          _bgKey = null;
          return;
        }
        widget.container.log.warn(
          'screensaver',
          'clock background fetch failed: $e; retrying in 1 min',
        );
        _bgRetry = Timer(_bgRetryDelay, () {
          if (!mounted || _bgKey != key) return;
          _bgKey = null;
          setState(() {});
        });
      }
    }());
  }

  /// The background photo layers, or nothing when none is set. Fill the
  /// screen, always on, the same recipe as the photo screensavers (issue
  /// #130): a photo shaped close enough to the panel is cover-fitted edge
  /// to edge (crop capped at a 1.45x ratio mismatch), one that keeps its
  /// full frame gets itself, blurred and dimmed, as the backdrop instead
  /// of black bars. The scrim on top keeps the clock and the row readable
  /// over either. Beside Now Playing (issue #938) the panel's Fill the
  /// screen override applies here too, like every photo screensaver.
  List<Widget> _background(Size size, double dpr) {
    if (widget.night &&
        widget.container.settings.get(
          defs.screensaverClockNightHideBackground,
        )) {
      return const [];
    }
    final fill = PhotoFillOverride.resolve(context, 'smart');
    _ensureBackground(
      widget.container.settings.get(defs.screensaverClockBackground),
      size,
      dpr,
      fill,
    );
    final image = _bgImage;
    if (image == null) return const [];
    final screen = size.width / size.height;
    final photo = _bgAspect;
    // An unreadable aspect (odd format) falls back to the cover fit the
    // clock always used, unless Off says never crop.
    final covers = photo == null
        ? fill != 'off'
        : photoCovers(fill, photo, screen);
    final picture = Image(
      image: image,
      fit: covers ? BoxFit.cover : BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    return [
      if (covers || fill == 'off')
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
                      image: _bgPhoto?.background ?? image,
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
  Widget _styledFace(
    String style,
    double scale,
    String? fontFamily, {
    required bool vertical,
  }) {
    final weight = clockWeightOverride(
      widget.container.settings.get(defs.screensaverClockFontWeight),
    );
    final opticalSize = clockOpticalSize(
      widget.container.settings.get(defs.screensaverClockFont),
    );
    if (style == 'flip') {
      return FlipClockFace(
        now: _now,
        use24h: widget.container.settings.get(defs.screensaverClock24h),
        digitColor:
            _nightColor() ??
            _rgb(defs.screensaverFlipDigitColor, const Color(0xFFFAFAFA)),
        cardColor:
            _nightCard() ??
            _rgb(defs.screensaverFlipBgColor, const Color(0xFF141414)),
        // The hinge gap shows the wall, so it follows the same override
        // the wall itself takes in the dark.
        backdropColor:
            _nightBg() ?? _rgb(defs.screensaverFlipBackdropColor, Colors.black),
        scale: scale,
        fontFamily: fontFamily,
        weight: weight,
        opticalSize: opticalSize,
        vertical: vertical,
      );
    }
    if (style == 'hand') {
      return HandClockFace(
        now: _now,
        color:
            _nightColor() ??
            _rgb(defs.screensaverHandColor, const Color(0xFFFAFAFA)),
        scale: scale,
        fontFamily: fontFamily,
        allNumbers:
            widget.container.settings.get(defs.screensaverHandNumbers) == 'all',
        seconds: widget.container.settings.get(defs.screensaverHandSeconds),
        weight: weight,
        opticalSize: opticalSize,
      );
    }
    return RollerClockFace(
      use24h: widget.container.settings.get(defs.screensaverClock24h),
      digitColor:
          _nightColor() ??
          _rgb(defs.screensaverRollerDigitColor, const Color(0xFFFAFAFA)),
      scale: scale,
      fontFamily: fontFamily,
      weight: weight,
      opticalSize: opticalSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.container.settings;
    final style = s.get(defs.screensaverClockStyle);
    final scale = (s.get(defs.screensaverClockScale) / 100).clamp(0.5, 3.0);
    // Night mode (issue #391) takes the digits and the backdrop, pure
    // black behind them by default; the flip cards take a night color of
    // their own in _styledFace.
    final color = _nightColor() ?? _color();
    final nightBg = _nightBg();
    final fontValue = s.get(defs.screensaverClockFont);
    final font = clockFontFamily(fontValue);
    final timeWeight =
        clockWeightOverride(s.get(defs.screensaverClockFontWeight)) ??
        clockFontWeight(fontValue);
    final opticalSize = clockOpticalSize(fontValue);
    final size = MediaQuery.of(context).size;
    // A ringing alarm takes the face over: the label on the date line and
    // Snooze and Stop under it, in the face's own colors. The glance row
    // steps aside for them.
    final ringing =
        widget.container.screensaver.alarmTakeover.value == 'ringing';
    // The At a Glance row sits under the clock and needs room for itself,
    // so the clock gives some back rather than pushing the row off a short
    // panel. Only when the row actually has something to show, and not
    // at night when Night mode is asked to leave the clock alone.
    final glance =
        !ringing &&
        !(widget.night && s.get(defs.screensaverClockNightHideWidgets)) &&
        widget.container.glance.entities.value.isNotEmpty;
    final glanceScale = min(1.0, size.height / 480).clamp(0.75, 1.0);
    final clockShrink = glance ? 0.72 : 1.0;
    // Vertical mode (issue #767) stacks the digital and flip faces; the
    // roller and the dial have nothing to stack, so a switch left on from
    // another style does nothing there.
    final vertical =
        (style == 'digital' || style == 'flip') &&
        s.get(defs.screensaverClockVertical);
    final lines = DigitalClockFace.linesFor(
      seconds: s.get(defs.screensaverClockSeconds),
    );
    final clockSize =
        DigitalClockFace.sizeFor(size, vertical: vertical, lines: lines) *
        scale *
        clockShrink;
    final dateSize =
        DigitalClockFace.dateSizeFor(size, vertical: vertical, lines: lines) *
        scale *
        clockShrink;
    final backdrop =
        nightBg ??
        switch (style) {
          'roller' => _rgb(defs.screensaverRollerBgColor, Colors.black),
          'flip' => _rgb(defs.screensaverFlipBackdropColor, Colors.black),
          'hand' => _rgb(defs.screensaverHandBgColor, Colors.black),
          _ => _rgb(defs.screensaverClockBgColor, Colors.black),
        };
    final Widget face = style != 'digital'
        ? _styledFace(style, scale * clockShrink, font, vertical: vertical)
        : DigitalClockFace(
            time: _time(),
            vertical: vertical,
            date: !ringing && s.get(defs.screensaverClockDate) ? _date() : null,
            fontFamily: font,
            color: color,
            clockSize: clockSize,
            dateSize: dateSize,
            weight: timeWeight,
            opticalSize: opticalSize,
          );
    final digitColor =
        _nightColor() ??
        switch (style) {
          'flip' => _rgb(
            defs.screensaverFlipDigitColor,
            const Color(0xFFFAFAFA),
          ),
          'roller' => _rgb(
            defs.screensaverRollerDigitColor,
            const Color(0xFFFAFAFA),
          ),
          'hand' => _rgb(defs.screensaverHandColor, const Color(0xFFFAFAFA)),
          _ => color,
        };

    return ColoredBox(
      color: backdrop,
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
                // a white backdrop under grey-on-black glance rows). Night
                // mode rides separately (issue #425): the tint only ever
                // reached the floating text, so the chips stayed white
                // beside the dimmed digits; night reaches both styles.
                night: _nightColor(),
                tint: switch (style) {
                  'flip' => _rgb(
                    defs.screensaverFlipDigitColor,
                    const Color(0xFFFAFAFA),
                  ),
                  'roller' => _rgb(
                    defs.screensaverRollerDigitColor,
                    const Color(0xFFFAFAFA),
                  ),
                  'hand' => _rgb(
                    defs.screensaverHandColor,
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
              child: !ringing
                  ? face
                  // The face gives way to the label and the buttons, which
                  // keep their full size: a flip or roller face fills the
                  // screen on its own and would otherwise squeeze them.
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: face,
                            ),
                          ),
                          SizedBox(height: clockSize * .1),
                          AlarmTakeoverControls(
                            container: widget.container,
                            color: digitColor,
                            ink: backdrop,
                            glass: digitColor.withValues(alpha: .1),
                            edge: digitColor.withValues(alpha: .22),
                            labelSize: dateSize,
                            fontFamily: font,
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

/// Where the At a Glance row goes over a mode with metadata panels in its
/// bottom corners: its distance from the bottom edge, the widest it may
/// run and whether it wraps narrow. [corners] are the panels' measured
/// sizes, margins included, and [compactWidth] the narrowest the row
/// wraps to.
///
/// The row is centred, so the wider panel sets the room on both sides. A
/// fixed narrow width still ran into the panels on a small screen (issue
/// #916): the row now wraps into the room the panels leave when two chips
/// fit across it, and otherwise rises above the taller panel and takes
/// the full width. Until the panels have been measured it wraps narrow as
/// before.
@visibleForTesting
({double bottom, double maxWidth, bool narrow}) glancePlacement({
  required double width,
  required double inset,
  required bool narrow,
  required Iterable<Size> corners,
  required double Function() compactWidth,
}) {
  if (!narrow || corners.isEmpty) {
    return (bottom: inset, maxWidth: width, narrow: narrow);
  }
  final room = width - 2 * corners.map((c) => c.width).reduce(max);
  if (compactWidth() <= room) {
    return (bottom: inset, maxWidth: room, narrow: true);
  }
  final rise = corners.map((c) => c.height).reduce(max);
  return (bottom: max(inset, rise), maxWidth: width, narrow: false);
}

/// Which half of a side-by-side pair a caption belongs to.
enum _CaptionHalf { left, right }

/// Where a photo caption goes in an area [width] wide: its distance from
/// the bottom edge and the widest it may run (issue #1290). [panel] is the
/// measured size of the metadata panel in a bottom corner of the area,
/// margins included, or null when no panel sits there.
///
/// The caption is centered, so the panel takes its width from both sides.
/// When the room left still holds a readable line the caption keeps the
/// bottom inset and wraps in that room. Otherwise it rises above the
/// panel and takes the full width. Either way it never runs wider than a
/// comfortable reading line, [scale] being the panel's Text scaling.
@visibleForTesting
({double bottom, double maxWidth}) captionPlacement({
  required double width,
  required double inset,
  required double scale,
  Size? panel,
}) {
  final line = min(width - 56, min(max(width * 0.6, 360 * scale), 640 * scale));
  if (panel == null) return (bottom: inset, maxWidth: max(0.0, line));
  final room = width - 2 * panel.width;
  if (room >= 260 * scale) return (bottom: inset, maxWidth: min(line, room));
  return (bottom: max(inset, panel.height), maxWidth: max(0.0, line));
}

/// The At a Glance row over the photo and web modes: bottom-pinned at the
/// Clock screensaver's inset, sized by its rule, and never in the way of a
/// touch. Its own widget so the overlay's build stays a list of layers.
class _GlanceOverlay extends StatelessWidget {
  const _GlanceOverlay({
    required this.container,
    required this.narrow,
    this.corners = const [],
    this.night,
  });

  final AppContainer container;

  /// The color the row is drawn in alone, as Night mode draws it on the
  /// clock: a plugin screensaver's tint. Null keeps its own colors.
  final Color? night;

  /// Whether the mode's bottom corners are spoken for (the Immich
  /// metadata panels), so the row should wrap narrow instead of spreading
  /// into them.
  final bool narrow;

  /// The measured size of each panel in a bottom corner, margins
  /// included. Empty until they have laid out, and the row then wraps
  /// narrow as before.
  final Iterable<Size> corners;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final scale = min(1.0, height / 480).clamp(0.75, 1.0);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final (:bottom, :maxWidth, :narrow) = glancePlacement(
            width: constraints.maxWidth,
            inset: height * 0.06,
            narrow: this.narrow,
            corners: corners,
            compactWidth: () =>
                GlanceRow.compactWidth(context, container, scale),
          );
          return Align(
            alignment: Alignment.bottomCenter,
            child: ValueListenableBuilder<double>(
              // A photo caption owns the bottom center (issue #1290): the
              // row stacks on top of it rather than over it.
              valueListenable: container.screensaver.captionFootprint,
              builder: (context, caption, child) => Padding(
                padding: EdgeInsets.only(
                  bottom: caption > 0
                      ? max(bottom, caption + 14 * scale)
                      : bottom,
                ),
                child: child,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: GlanceRow(
                  container: container,
                  scale: scale,
                  narrow: narrow,
                  night: night,
                ),
              ),
            ),
          );
        },
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

/// The three stops of a corner vignette at [strength] percent, the corner's
/// darkness. Front-loaded: still three quarters of the corner's darkness
/// well past a third of the way out, so the text area is solidly backed
/// before the long fade begins. The default 40 keeps the photo visible
/// behind the text. Out-of-range
/// values clamp, so an imported 250 is a full black corner, not an overflow.
List<Color> vignetteColors(num strength) {
  final corner = (strength.toDouble().clamp(0, 100) / 100 * 255).round();
  return [
    Color.fromARGB(corner, 0, 0, 0),
    Color.fromARGB((corner * 0.75).round(), 0, 0, 0),
    const Color(0x00000000),
  ];
}

List<Shadow> _overlayTextShadows(
  AppContainer container, {
  defs.SettingDef<bool> setting = defs.screensaverWidgetTextShadow,
}) => container.settings.get(setting)
    ? const [Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 4)]
    : const [];

/// A soft radial darkening anchored to [corner], painted behind a corner
/// overlay so its text survives a bright photo. Radial rather than a boxed
/// gradient: it fades out in every direction, so there is no rectangle edge
/// to catch the eye. Its darkness is a Vignette strength slider, the
/// widgets' unless [def] names the Immich metadata overlay's, read at build
/// so a move in the remote admin previews live; at 0 nothing is painted at
/// all.
Widget _cornerVignette(
  Alignment corner,
  AppContainer container, {
  double radius = 0.7,
  defs.SettingDef<num> def = defs.screensaverVignetteStrength,
}) {
  final strength = container.settings.get(def);
  if (strength <= 0) return const SizedBox.expand();
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: corner,
        radius: radius,
        colors: vignetteColors(strength),
        stops: const [0, 0.4, 1],
      ),
    ),
    child: const SizedBox.expand(),
  );
}

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
    this.nightColor,
  });

  final AppContainer container;
  final ScreensaverWidget spec;

  /// The Clock screensaver's night color while its Night mode holds
  /// (issue #391), in place of the widget's own; null otherwise.
  final Color? nightColor;

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
    // Entries saved before Show AM/PM existed carry no key and keep it.
    if (!h24 && widget.spec.config['ampm'] != false) {
      t += _now.hour < 12 ? ' AM' : ' PM';
    }
    return t;
  }

  // Localized like the big clock's date (issue #108): "Sun, Aug 2" or
  // "zo 2 aug", per the device locale.
  String _date() => shortDate(_now);

  @override
  Widget build(BuildContext context) {
    final corner = _cornerAlignment(widget.spec.position);
    final color = widget.nightColor ?? _widgetRgb(widget.spec.config['color']);
    final size = MediaQuery.of(context).size;
    // Proportional to the panel, but floored: on a small low-density screen
    // (the Echo Show 5's 480 logical pixels) the proportional size lands
    // near the metadata's fixed-pixel text and reads absurdly small for a
    // clock. The scale sliders then correct for the screen.
    final scale = _widgetScale(widget.container, widget.spec);
    final clockSize = max(min(size.width, size.height) * 0.063, 44.0) * scale;
    final font = _widgetFont(widget.container, widget.spec);
    // Readable over a bright photo without boxing the text in.
    final shadows = _overlayTextShadows(widget.container);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _cornerVignette(corner, widget.container),
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
                        // The widget's font, Rubik unless a Font family
                        // says otherwise. Proportional figures, not
                        // tabular: the block hugs its corner (the outer
                        // edge cannot jitter), and a leading 1's tabular
                        // side-bearing left the time visibly indented
                        // against its own date line.
                        fontFamily: font.family,
                        color: color,
                        fontSize: clockSize,
                        fontWeight: font.weight ?? FontWeight.w400,
                        fontVariations: clockFontVariations(
                          font.opticalSize,
                          font.weight ?? FontWeight.w400,
                        ),
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
                            fontFamily: font.family,
                            color: color.withValues(alpha: 0.75),
                            fontSize: clockSize * 0.52,
                            fontWeight: font.weight ?? FontWeight.w400,
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
    this.nightColor,
  });

  final AppContainer container;
  final ScreensaverWidget spec;

  /// The Clock screensaver's night color while its Night mode holds
  /// (issue #391), in place of the widget's own; null otherwise.
  final Color? nightColor;

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
    final color = widget.nightColor ?? _widgetRgb(widget.spec.config['color']);
    final size = MediaQuery.of(context).size;
    // Two thirds of the small clock: readable across a room, without a
    // corner of the photo given over to a battery.
    final scale = _widgetScale(widget.container, widget.spec);
    final textSize = max(min(size.width, size.height) * 0.042, 30.0) * scale;
    final font = _widgetFont(widget.container, widget.spec);
    final shadows = _overlayTextShadows(widget.container);
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
              fontFamily: font.family,
              color: color,
              fontSize: textSize,
              fontWeight: font.weight ?? FontWeight.w400,
              fontVariations: clockFontVariations(
                font.opticalSize,
                font.weight ?? FontWeight.w400,
              ),
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
          _cornerVignette(corner, widget.container, radius: 0.5),
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

/// The next alarm in a corner: its time within the next 24 hours, or when
/// a snooze runs out. Empty the rest of the time, so the corner stays
/// clear. A tap opens the alarm list, the one spot on the screensaver that
/// does more than dismiss it.
class AlarmWidgetOverlay extends StatefulWidget {
  const AlarmWidgetOverlay({
    super.key,
    required this.container,
    required this.spec,
    this.nightColor,
  });

  final AppContainer container;
  final ScreensaverWidget spec;
  final Color? nightColor;

  @override
  State<AlarmWidgetOverlay> createState() => _AlarmWidgetOverlayState();
}

class _AlarmWidgetOverlayState extends State<AlarmWidgetOverlay> {
  Timer? _shift;
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _shift = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!widget.container.settings.get(defs.screensaverPixelShift)) {
        // Still rebuild: the 24 hour window moves with the clock.
        setState(() {});
        return;
      }
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

  @override
  void dispose() {
    _shift?.cancel();
    super.dispose();
  }

  // Times follow Settings > Alarms > 24-hour clock.
  @override
  Widget build(BuildContext context) => ClockSetting(
    container: widget.container,
    setting: defs.alarmsClock24h,
    child: Builder(builder: _alarm),
  );

  Widget _alarm(BuildContext context) => ValueListenableBuilder<AlarmStatus>(
    valueListenable: widget.container.alarms.status,
    builder: (context, status, _) {
      final now = DateTime.now();
      final snoozed = status.phase == AlarmPhase.snoozed
          ? status.snoozedUntil
          : null;
      final next = status.next?.at;
      final String text;
      final IconData icon;
      if (snoozed != null) {
        text = l10n(
          context,
        ).alarmsSnoozedUntil(alarmTimeText(context, snoozed));
        icon = Icons.snooze;
      } else if (next != null &&
          next.difference(now) <= const Duration(hours: 24)) {
        text = alarmTimeText(context, next);
        icon = Icons.alarm;
      } else {
        return const SizedBox.shrink();
      }
      final corner = _cornerAlignment(widget.spec.position);
      final color =
          widget.nightColor ?? _widgetRgb(widget.spec.config['color']);
      final size = MediaQuery.of(context).size;
      final scale = _widgetScale(widget.container, widget.spec);
      final textSize = max(min(size.width, size.height) * 0.042, 30.0) * scale;
      final font = _widgetFont(widget.container, widget.spec);
      final shadows = _overlayTextShadows(widget.container);
      final glyph = Icon(
        icon,
        size: textSize * 1.1,
        color: color,
        shadows: shadows,
      );
      final label = Text(
        text,
        style: TextStyle(
          fontFamily: font.family,
          color: color,
          fontSize: textSize,
          fontWeight: font.weight ?? FontWeight.w400,
          fontVariations: clockFontVariations(
            font.opticalSize,
            font.weight ?? FontWeight.w400,
          ),
          height: 1.0,
          shadows: shadows,
        ),
      );
      final right = corner.x > 0;
      final gap = SizedBox(width: 10 * scale);
      return Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: _cornerVignette(corner, widget.container, radius: 0.5),
          ),
          Align(
            alignment: corner,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Transform.translate(
                offset: _offset,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      widget.container.commands.execute('openAlarms', const {}),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (right) ...[label, gap],
                      glyph,
                      if (!right) ...[gap, label],
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

/// The family calendar's next events today in a corner: a dot in each
/// event's calendar color (split for a shared one), the start time (or All
/// day, those listed first) and the title. Empty once nothing more is on
/// today, so the corner stays clear.
/// A tap opens the calendar, the alarm widget's twin.
class CalendarWidgetOverlay extends StatefulWidget {
  const CalendarWidgetOverlay({
    super.key,
    required this.container,
    required this.spec,
    this.nightColor,
  });

  final AppContainer container;
  final ScreensaverWidget spec;
  final Color? nightColor;

  @override
  State<CalendarWidgetOverlay> createState() => _CalendarWidgetOverlayState();
}

class _CalendarWidgetOverlayState extends State<CalendarWidgetOverlay> {
  Timer? _shift;
  Offset _offset = Offset.zero;

  CalendarManager get _cal => widget.container.calendar;

  @override
  void initState() {
    super.initState();
    _watchToday();
    _shift = Timer.periodic(const Duration(minutes: 1), (_) {
      // The day and what is still to come move with the clock.
      _watchToday();
      if (!widget.container.settings.get(defs.screensaverPixelShift)) {
        setState(() {});
        return;
      }
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

  void _watchToday() {
    final today = cal_model.dateOnly(DateTime.now());
    _cal.watch(this, today, cal_model.addDays(today, _days));
  }

  @override
  void didUpdateWidget(CalendarWidgetOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _watchToday();
  }

  /// How many days the widget looks ahead, today counting as one.
  int get _days {
    final days = (widget.spec.config['days'] as num?)?.toInt() ?? 1;
    return upNextDayOptions.contains(days) ? days : 1;
  }

  @override
  void dispose() {
    _shift?.cancel();
    _cal.unwatch(this);
    super.dispose();
  }

  Color _dotColor(String entity) {
    final rgb = cal_model.parseRgb(_cal.source(entity)?.color ?? '');
    final base = rgb == null
        ? const Color(0xFF6C9B9F)
        : Color.fromARGB(255, rgb.$1, rgb.$2, rgb.$3);
    return Color.lerp(base, Colors.white, .3)!;
  }

  // Times follow Settings > Calendar > 24-hour clock.
  @override
  Widget build(BuildContext context) => ClockSetting(
    container: widget.container,
    setting: defs.calendarClock24h,
    child: Builder(builder: _upNext),
  );

  Widget _upNext(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_cal.snapshot, _cal.hidden, _cal.calendars]),
    builder: (context, _) {
      final now = DateTime.now();
      final count = ((widget.spec.config['count'] as num?)?.toInt() ?? 3).clamp(
        1,
        5,
      );
      final coming = cal_model
          .upNext(
            cal_model.visibleEvents(
              _cal.snapshot.value.events,
              _cal.hidden.value,
            ),
            now,
            allDay: widget.spec.config['all_day'] != false,
            days: _days,
          )
          .take(count)
          .toList();
      if (coming.isEmpty) return const SizedBox.shrink();
      final corner = _cornerAlignment(widget.spec.position);
      final color =
          widget.nightColor ?? _widgetRgb(widget.spec.config['color']);
      final size = MediaQuery.of(context).size;
      final scale = _widgetScale(widget.container, widget.spec);
      final textSize = max(min(size.width, size.height) * 0.032, 22.0) * scale;
      final font = _widgetFont(widget.container, widget.spec);
      final shadows = _overlayTextShadows(widget.container);
      TextStyle style(double size, {double alpha = 1, FontWeight? weight}) =>
          TextStyle(
            fontFamily: font.family,
            color: color.withValues(alpha: alpha),
            fontSize: size,
            fontWeight: weight ?? font.weight ?? FontWeight.w400,
            fontVariations: clockFontVariations(
              font.opticalSize,
              weight ?? font.weight ?? FontWeight.w400,
            ),
            height: 1.2,
            shadows: shadows,
          );
      final right = corner.x > 0;
      final headingStyle = style(
        textSize * .62,
        alpha: .62,
        weight: FontWeight.w600,
      ).copyWith(letterSpacing: 1.2);
      // Each later day's events go under its name. Today's come first,
      // with no heading.
      final today = cal_model.dateOnly(now);
      DateTime? dayOf(cal_model.CalendarEvent e) {
        final day = cal_model.dateOnly(e.start);
        return day.isAfter(today) ? day : null;
      }

      String dayName(DateTime day) => day == cal_model.addDays(today, 1)
          ? l10n(context).calendarTomorrow
          : weekdayName(day);
      String when(cal_model.CalendarEvent e) => e.allDay
          ? l10n(context).calendarAllDay
          : e.start.isAfter(now)
          ? calendarTime(context, e.start)
          : l10n(context).calendarHappeningNow;
      // The times share the widest one's width, so the titles line up.
      final timeStyle = style(textSize, alpha: .72);
      final timeWidth = coming
          .map(
            (e) => (TextPainter(
              text: TextSpan(
                text: when(e),
                // What the Text below draws with: the theme's
                // family under the widget's own style.
                style: DefaultTextStyle.of(context).style.merge(timeStyle),
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout()).width,
          )
          .reduce(max);
      // Each event's calendars as their people's pictures (the initial on
      // the calendar's color without one), or the colored dot when the
      // widget asks for it. Night mode keeps to the dots, so a bright
      // picture does not glare out of the dimmed screen.
      final dots =
          widget.spec.config['dots'] == true || widget.nightColor != null;
      final avatarSize = textSize * 1.1;
      final avatarPaint = CalendarPaint(context, _cal, dark: true);
      // The pictures' slot takes the widest stack, so the times line up.
      final leadWidth = dots
          ? textSize * .42
          : avatarSize +
                4 +
                (avatarSize - 7) *
                    (coming.map((e) => e.calendars.length).reduce(max) - 1);
      Widget lead(cal_model.CalendarEvent e) => dots
          ? SizedBox(
              width: textSize * .42,
              height: textSize * .42,
              child: CustomPaint(
                painter: CalendarBands([
                  for (final id in e.calendars) _dotColor(id),
                ], circle: true),
              ),
            )
          : SizedBox(
              width: leadWidth,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: CalendarAvatarStack(
                  container: widget.container,
                  entities: e.calendars,
                  paint: avatarPaint,
                  ring: const Color(0xFF1A1B1E),
                  size: avatarSize,
                ),
              ),
            );
      final rows = [
        for (final (i, e) in coming.indexed) ...[
          if (dayOf(e) case final day?
              when i == 0 || dayOf(coming[i - 1]) != day)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : textSize * .8),
              child: Text(dayName(day).toUpperCase(), style: headingStyle),
            ),
          Padding(
            padding: EdgeInsets.only(
              top: i == 0 && dayOf(e) == null ? 0 : textSize * .4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                lead(e),
                SizedBox(width: textSize * .55),
                SizedBox(
                  width: timeWidth + 1,
                  child: Text(
                    when(e),
                    style: timeStyle,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                SizedBox(width: textSize * .55),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: size.width * .32),
                  child: Text(
                    e.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style(textSize, weight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ];
      return Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: _cornerVignette(corner, widget.container, radius: 0.6),
          ),
          Align(
            alignment: corner,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Transform.translate(
                offset: _offset,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.container.commands.execute(
                    'openCalendar',
                    const {'view': 'schedule'},
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: right
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: rows,
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

/// At or below this the charge counts as low: the "only when low" widget
/// appears, matching the level Android itself starts warning at.
const lowBatteryLevel = 20;

/// Whether the battery widget draws at all. A device without a battery
/// (a mains-powered box, issue #367) has nothing to show: a bolt burning
/// in the corner forever would only say the box is plugged in. "Only when
/// low" keeps the corner clear until the charge is worth walking over for:
/// a device on the cable is already being dealt with.
bool batteryWidgetVisible({
  required bool lowOnly,
  required int? level,
  required bool charging,
}) {
  if (level == null) return false;
  if (!lowOnly) return true;
  return !charging && level <= lowBatteryLevel;
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
/// A corner widget's typography: the family it draws in and the weight
/// its lines take when the widget or the Global font weight names one
/// (null leaves each line its own), plus the optical size a family with
/// that axis wants for its large line. The family is the widget's own
/// Font family unless left at Default, then the Global font family; the
/// weight resolves the same way.
typedef _WidgetFont = ({
  String? family,
  FontWeight? weight,
  double? opticalSize,
});

_WidgetFont _widgetFont(AppContainer container, ScreensaverWidget spec) {
  final font = screensaverWidgetFontValue(
    spec.config,
    container.settings.get(defs.screensaverWidgetFont),
  );
  final weight = screensaverWidgetFontWeightValue(
    spec.config,
    container.settings.get(defs.screensaverWidgetFontWeight),
  );
  return (
    family: clockFontFamily(font),
    weight: clockWeightOverride(weight),
    opticalSize: clockOpticalSize(font),
  );
}

/// A corner widget's size factor: the Global widget scaling slider, which
/// scales every widget together for the panel, times the widget's own
/// Scale slider, which sets its size relative to the others. Both at their
/// defaults is 1.
double _widgetScale(AppContainer container, ScreensaverWidget spec) =>
    container.settings.get(defs.screensaverWidgetScale).toDouble() /
    100 *
    screensaverWidgetScaleFactor(spec.config);

Color _widgetRgb(Object? raw) => _rgbOr('$raw', const Color(0xFFFAFAFA));

/// An "r,g,b" setting value as a color, or [orElse] for anything else.
Color _rgbOr(String raw, Color orElse) {
  final parts = raw.split(',').map((p) => int.tryParse(p.trim())).toList();
  if (parts.length == 3 && parts.every((p) => p != null)) {
    return Color.fromARGB(255, parts[0]!, parts[1]!, parts[2]!);
  }
  return orElse;
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
    this.nightColor,
  });

  final AppContainer container;
  final ScreensaverWidget spec;

  /// The Clock screensaver's night color while its Night mode holds
  /// (issue #391), in place of the widget's own; null otherwise.
  final Color? nightColor;

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
      onStateLabels: (labels) {
        if (mounted) setState(() => _entity = _entity.merge(labels: labels));
      },
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
        labels: _entity.labels,
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
    // Nothing until the first reading, and nothing while the value is
    // blank: an empty corner beats a widget that says "…".
    if (_entity.state == null || glanceValueBlank(_entity)) {
      return const SizedBox.shrink();
    }
    final text = glanceStateText(_entity, strings: l10n(context));
    if (!entityWidgetStateVisible(widget.spec.config, _entity, text)) {
      return const SizedBox.shrink();
    }
    final corner = _cornerAlignment(widget.spec.position);
    final color = widget.nightColor ?? _widgetRgb(widget.spec.config['color']);
    final size = MediaQuery.of(context).size;
    // The value is the battery widget's size, the name the weather
    // widget's detail line, so the corner overlays all read as one
    // family. The scale sliders then correct everything for the screen.
    final scale = _widgetScale(widget.container, widget.spec);
    final textSize = max(min(size.width, size.height) * 0.042, 30.0) * scale;
    final font = _widgetFont(widget.container, widget.spec);
    final shadows = _overlayTextShadows(widget.container);
    final glyph = GlanceIcon(
      entity: _entity,
      size: textSize * 1.15,
      color: color,
    );
    final value = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: font.family,
        color: color,
        fontSize: textSize,
        fontWeight: font.weight ?? FontWeight.w400,
        fontVariations: clockFontVariations(
          font.opticalSize,
          font.weight ?? FontWeight.w400,
        ),
        height: 1.0,
        shadows: shadows,
      ),
    );
    final label = Text(
      _entity.displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: font.family,
        color: color.withValues(alpha: 0.9),
        fontSize: 16 * scale,
        fontWeight: font.weight ?? FontWeight.w400,
        height: 1.35,
        shadows: shadows,
      ),
    );
    // The icon leads on a left corner and trails on a right one, the same
    // rule the battery and weather widgets follow.
    final right = corner.x > 0;
    final gap = SizedBox(width: 10 * scale);
    // Show name off: the value and its icon alone, for a corner that
    // explains itself. Show icon off: the value and its name alone.
    final showName = widget.spec.config['show_name'] != false;
    final showIcon = widget.spec.config['show_icon'] != false;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _cornerVignette(corner, widget.container, radius: 0.5),
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
                          if (!showIcon)
                            Flexible(child: value)
                          else ...[
                            if (right) ...[Flexible(child: value), gap],
                            glyph,
                            if (!right) ...[gap, Flexible(child: value)],
                          ],
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

/// Whether the entity widget shows for this reading (issue #1066). An empty
/// Visible states list always shows. Otherwise one entry has to match the
/// displayed [text] ("Open") or the raw value behind it ("on"), ignoring
/// case, so either way of writing it works.
bool entityWidgetStateVisible(
  Map<String, Object?> config,
  GlanceEntity entity,
  String text,
) {
  final states = {
    for (final s in '${config['show_states'] ?? ''}'.split(','))
      if (s.trim().isNotEmpty) s.trim().toLowerCase(),
  };
  if (states.isEmpty) return true;
  final raw = entity.attribute == null ? entity.state : entity.attributeValue;
  return states.contains(text.trim().toLowerCase()) ||
      (raw != null && states.contains(raw.trim().toLowerCase()));
}

/// A Home Assistant weather entity with a prominent temperature, a labeled
/// apparent temperature and optional condition, today's high and low,
/// humidity, wind and visibility.
class WeatherWidgetOverlay extends StatefulWidget {
  const WeatherWidgetOverlay({
    super.key,
    required this.container,
    required this.spec,
    this.nightColor,
  });

  final AppContainer container;
  final ScreensaverWidget spec;

  /// The Clock screensaver's night color while its Night mode holds
  /// (issue #391), in place of the widget's own; null otherwise.
  final Color? nightColor;

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

  /// The entity's daily forecast by local date, for today's high and low
  /// (issue #1262). Empty when the integration has no daily forecast.
  Map<DateTime, DayForecast> _daily = const {};

  /// sun.sun's state, so no icon shows a sun after dark; null until it
  /// reports, and then the local time decides.
  String? _sun;

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
    // Cached in the manager once a socket brings them, so later
    // screensavers get them without another lookup.
    final live = await widget.container.homeAssistant.subscribeEntities(
      [entity, ?_companion(entity), 'sun.sun'],
      _onState,
      translationDomain: 'weather',
      onTranslations: (translated) {
        if (mounted) setState(() => _translated = translated);
      },
      forecastEntity: entity,
      onForecast: (forecast) {
        if (mounted) setState(() => _daily = parseForecast(forecast));
      },
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
      if (entityId == 'sun.sun') {
        if (s is String) _sun = s;
        return;
      }
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
      _daily = const {};
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

  bool _on(String key, {bool orElse = false}) => widget.spec.config[key] is bool
      ? widget.spec.config[key] == true
      : orElse;

  num? _num(String key) {
    final value = _attributes[key];
    return value is num && value.isFinite ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    // Nothing sensible to draw before the first snapshot, or while the
    // entity itself is gone.
    if (!_haveData || _condition == 'unavailable' || _condition == 'unknown') {
      return const SizedBox.shrink();
    }
    final corner = _cornerAlignment(widget.spec.position);
    final color = widget.nightColor ?? _widgetRgb(widget.spec.config['color']);
    final size = MediaQuery.of(context).size;
    final scale = _widgetScale(widget.container, widget.spec);
    final tempSize = max(min(size.width, size.height) * 0.063, 44.0) * scale;
    final font = _widgetFont(widget.container, widget.spec);
    final shadows = _overlayTextShadows(widget.container);

    // A picked weight wins over the line's own: the location line is
    // semibold by design, and Default keeps it so.
    TextStyle line({double? size, FontWeight? weight, double alpha = 0.9}) =>
        TextStyle(
          fontFamily: font.family,
          color: color.withValues(alpha: alpha),
          fontSize: size ?? tempSize * .48,
          fontWeight: font.weight ?? weight ?? FontWeight.w400,
          shadows: shadows,
          // The Immich metadata panel's line height: the two blocks share a
          // corner vocabulary, and the tighter 1.2 read as cramped beside it.
          height: 1.35,
        );

    // One reading with its monochrome icon, tinted like the text. The
    // icon sits on the corner's outer edge. Left corners lead with it and
    // right corners trail so the icon column stays flush however long
    // the readings run.
    final right = corner.x > 0;
    Widget detail(
      String value,
      IconData icon, {
      String? condition,
      bool night = false,
    }) {
      final glyph = condition != null
          ? WeatherConditionIcon(
              condition,
              size: tempSize * .43,
              color: color.withValues(alpha: 0.85),
              shadows: shadows,
              night: night,
            )
          : Icon(
              icon,
              size: tempSize * .43,
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

    final temperature = WeatherTemperatureReading.fromAttributes(
      _attributes,
      feelsLike: _on('feels_like'),
      feelsLikeOnly: _on('feels_like_only'),
    );
    // The unit is already on the temperature right above, so the pair
    // reads "31° / 24°", the way Home Assistant's forecast card writes it.
    final today = _daily[cal_model.dateOnly(DateTime.now())];
    final high = today?.high;
    final low = today?.low;
    final humidity = _num('humidity');
    final wind = _num('wind_speed');
    final visibility = _num('visibility');
    // On unless switched off, so entries saved before the switch existed
    // get the colors too.
    final colored =
        _on('colored_icons', orElse: true) && widget.nightColor == null;
    final night = weatherMoodNight(_sun, DateTime.now());
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
          weatherConditionIcon(_condition),
          condition: _condition,
          night: night,
        ),
      if (_on('high_low') && high != null && low != null)
        detail('${high.round()}° / ${low.round()}°', Icons.thermostat),
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
          style: line(size: tempSize * .50, weight: FontWeight.w600, alpha: 1),
        ),
      if (temperature != null)
        Builder(
          builder: (context) {
            // The current conditions beside the temperature, on the
            // corner's outer edge like the detail lines' icons, centered on
            // the temperature line. The Clock's Night mode keeps every
            // widget in its one dim color, so the colors stand down there.
            final icon = _condition.isEmpty
                ? null
                : SizedBox(
                    height: tempSize,
                    child: Center(
                      child: colored
                          ? ColoredWeatherConditionIcon(
                              _condition,
                              size: tempSize * 1.1,
                              fallbackColor: color,
                              night: night,
                            )
                          : WeatherConditionIcon(
                              _condition,
                              size: tempSize * .9,
                              color: color,
                              shadows: shadows,
                              night: night,
                            ),
                    ),
                  );
            final reading = WeatherTemperature(
              reading: temperature,
              alignment: align,
              secondaryStyle: line(size: tempSize * .40),
              primaryStyle: TextStyle(
                fontFamily: font.family,
                color: color,
                fontSize: tempSize,
                fontWeight: font.weight ?? FontWeight.w400,
                fontVariations: clockFontVariations(
                  font.opticalSize,
                  font.weight ?? FontWeight.w400,
                ),
                height: 1.0,
                shadows: shadows,
              ),
            );
            final gap = SizedBox(width: tempSize * .25);
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null && !right) ...[icon, gap],
                reading,
                if (icon != null && right) ...[gap, icon],
              ],
            );
          },
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
          _cornerVignette(corner, widget.container),
          Align(
            alignment: corner,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Transform.translate(
                offset: _offset,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: corner,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    crossAxisAlignment: align,
                    children: lines,
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

/// The Weather forecast widget's rows: up to [days] days of [daily] in
/// date order, from today when [includeToday] is set and from tomorrow
/// otherwise. Days the integration does not forecast are simply missing,
/// so a short forecast lists fewer rows.
List<(DateTime, DayForecast)> forecastWidgetRows(
  Map<DateTime, DayForecast> daily,
  DateTime now, {
  required int days,
  required bool includeToday,
}) {
  final today = cal_model.dateOnly(now);
  final first = includeToday ? today : cal_model.addDays(today, 1);
  final dates = daily.keys.where((d) => !d.isBefore(first)).toList()..sort();
  return [for (final d in dates.take(days)) (d, daily[d]!)];
}

/// The Weather forecast widget (issue #1277): the coming days of a weather
/// entity's daily forecast, one row each with the day, the condition icon,
/// the high and the low. The columns share the widest entry's width, so
/// the icons and temperatures line up down the list. Fed over its own
/// subscribe_entities socket, the Weather widget's pattern, which also
/// brings the daily forecast.
class ForecastWidgetOverlay extends StatefulWidget {
  const ForecastWidgetOverlay({
    super.key,
    required this.container,
    required this.spec,
    this.nightColor,
  });

  final AppContainer container;
  final ScreensaverWidget spec;

  /// The Clock screensaver's night color while its Night mode holds
  /// (issue #391), in place of the widget's own; null otherwise.
  final Color? nightColor;

  @override
  State<ForecastWidgetOverlay> createState() => _ForecastWidgetOverlayState();
}

class _ForecastWidgetOverlayState extends State<ForecastWidgetOverlay> {
  GlanceSubscription? _live;
  Timer? _retry;
  Timer? _shift;
  Offset _offset = Offset.zero;

  /// The entity's own state: an unavailable entity hides the widget
  /// rather than leave a stale forecast up.
  String _condition = '';
  Map<DateTime, DayForecast> _daily = const {};

  /// sun.sun's state, so today's row shows no sun after dark; null until
  /// it reports, and then the local time decides.
  String? _sun;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
    // The same slow OLED-protecting nudge the other widgets do. The tick
    // also moves the list on to the next day after midnight.
    _shift = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!widget.container.settings.get(defs.screensaverPixelShift)) {
        setState(() {});
        return;
      }
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
      [entity, 'sun.sun'],
      _onState,
      forecastEntity: entity,
      onForecast: (forecast) {
        if (mounted) setState(() => _daily = parseForecast(forecast));
      },
    );
    if (!mounted) {
      unawaited(live?.close());
      return;
    }
    if (live == null) {
      // Home Assistant unreachable: keep what we last knew and try again
      // shortly, the Weather widget's cadence.
      _retry?.cancel();
      _retry = Timer(const Duration(seconds: 20), () {
        if (mounted) unawaited(_open());
      });
      return;
    }
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
    final s = state['state'];
    if (s is! String) return;
    setState(() {
      if (entityId == 'sun.sun') {
        _sun = s;
      } else {
        _condition = s;
      }
    });
  }

  // A live edit can repoint the widget at another entity; the element is
  // reused in place, so the subscription has to follow by hand.
  @override
  void didUpdateWidget(ForecastWidgetOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ('${oldWidget.spec.config['entity']}' !=
        '${widget.spec.config['entity']}') {
      _retry?.cancel();
      final live = _live;
      _live = null;
      if (live != null) unawaited(live.close());
      _condition = '';
      _daily = const {};
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

  @override
  Widget build(BuildContext context) {
    if (_condition == 'unavailable' || _condition == 'unknown') {
      return const SizedBox.shrink();
    }
    final config = widget.spec.config;
    final days = switch ((config['days'] as num?)?.toInt()) {
      final d? when forecastDayOptions.contains(d) => d,
      _ => 5,
    };
    final now = DateTime.now();
    final rows = forecastWidgetRows(
      _daily,
      now,
      days: days,
      includeToday: config['today'] != false,
    );
    if (rows.isEmpty) return const SizedBox.shrink();
    final corner = _cornerAlignment(widget.spec.position);
    final color = widget.nightColor ?? _widgetRgb(config['color']);
    final size = MediaQuery.of(context).size;
    final scale = _widgetScale(widget.container, widget.spec);
    final textSize = max(min(size.width, size.height) * 0.036, 24.0) * scale;
    final font = _widgetFont(widget.container, widget.spec);
    final shadows = _overlayTextShadows(widget.container);
    TextStyle style({double alpha = 1, FontWeight? weight}) => TextStyle(
      fontFamily: font.family,
      color: color.withValues(alpha: alpha),
      fontSize: textSize,
      fontWeight: font.weight ?? weight ?? FontWeight.w400,
      shadows: shadows,
      height: 1.35,
    );
    final dayStyle = style(weight: FontWeight.w500);
    final highStyle = style();
    final lowStyle = style(alpha: .62);
    // Every row, today's included, reads as its short weekday, the way a
    // forecast card lists them.
    String dayName(DateTime day) => shortWeekdayName(day);
    // Today's row after dark shows no sun. Later days are daytime
    // forecasts, so they keep their day icons.
    final today = cal_model.dateOnly(now);
    final night = weatherMoodNight(_sun, now);
    String degrees(double? t) => t == null ? '' : '${t.round()}°';
    // Each column takes its widest entry's width, so the list reads as a
    // table whatever the day names and temperatures run to.
    double widest(Iterable<String> texts, TextStyle style) => texts
        .map(
          (text) => (TextPainter(
            text: TextSpan(
              text: text,
              style: DefaultTextStyle.of(context).style.merge(style),
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout()).width,
        )
        .reduce(max);
    final dayWidth = widest(rows.map((r) => dayName(r.$1)), dayStyle) + 1;
    final highWidth = widest(rows.map((r) => degrees(r.$2.high)), highStyle);
    final lowWidth = widest(rows.map((r) => degrees(r.$2.low)), lowStyle);
    // On unless switched off, so entries saved before the switch existed
    // keep the colors.
    final colored =
        config['colored_icons'] != false && widget.nightColor == null;
    final gap = SizedBox(width: textSize * .6);
    Widget cell(String text, double width, TextStyle style, TextAlign align) =>
        SizedBox(
          width: width + 1,
          child: Text(
            text,
            style: style,
            textAlign: align,
            maxLines: 1,
            softWrap: false,
          ),
        );

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _cornerVignette(corner, widget.container),
          Align(
            alignment: corner,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Transform.translate(
                offset: _offset,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: corner,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: textSize * .2,
                    children: [
                      for (final (day, f) in rows)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            cell(
                              dayName(day),
                              dayWidth,
                              dayStyle,
                              TextAlign.start,
                            ),
                            gap,
                            // The Clock's Night mode keeps every widget in
                            // its one dim color, so the colors stand down.
                            if (colored)
                              ColoredWeatherConditionIcon(
                                f.condition,
                                size: textSize * 1.3,
                                fallbackColor: color.withValues(alpha: .85),
                                night: night && day == today,
                              )
                            else
                              WeatherConditionIcon(
                                f.condition,
                                size: textSize * 1.15,
                                color: color.withValues(alpha: .85),
                                shadows: shadows,
                                night: night && day == today,
                              ),
                            gap,
                            cell(
                              degrees(f.high),
                              highWidth,
                              highStyle,
                              TextAlign.end,
                            ),
                            if (lowWidth > 0) ...[
                              SizedBox(width: textSize * .45),
                              cell(
                                degrees(f.low),
                                lowWidth,
                                lowStyle,
                                TextAlign.end,
                              ),
                            ],
                          ],
                        ),
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
  String get _configJson => _buildConfig();
  String? _photoFill;

  /// The live controller, for re-asserting kiosk mode on it.
  InAppWebViewController? _webView;

  /// Kiosk mode changing while a Home Assistant page is on screen applies to
  /// it there and then, exactly as it does on the dashboard.
  StreamSubscription<SettingChanged>? _kioskSub;
  StreamSubscription<ScreenStateChanged>? _photoScreenSub;
  late bool _photoScreenOn = widget.container.screen.isScreenOn;

  Future<void> _setPhotoActivity() async {
    if (widget.mode != 'media') return;
    try {
      await _webView?.evaluateJavascript(
        source:
            'window.__ksPhotoActive && '
            'window.__ksPhotoActive(${_photoScreenOn && !_renderPaused})',
      );
    } catch (_) {
      // A navigating renderer receives the state again after its load.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _photoFill = PhotoFillOverride.resolve(
      context,
      widget.container.settings.get(defs.screensaverMediaFill),
    );
    unawaited(_applyPhotoFill());
  }

  Future<void> _applyPhotoFill() async {
    if (widget.mode != 'media') return;
    try {
      await _webView?.evaluateJavascript(
        source:
            'window.__ksPhotoFill && window.__ksPhotoFill(${jsonEncode(_photoFill)})',
      );
    } catch (_) {
      // The current fill is sent again when the page finishes loading.
    }
  }

  /// Video length applies to the Media deck's next video without a reload.
  Future<void> _applyVideoLength() async {
    if (widget.mode != 'media') return;
    final length = widget.container.settings.get(
      defs.screensaverMediaVideoLength,
    );
    try {
      await _webView?.evaluateJavascript(
        source:
            'window.__ksVideoLength && '
            'window.__ksVideoLength(${jsonEncode(length)})',
      );
    } catch (_) {
      // A navigating renderer reads it from the config after its load.
    }
  }

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

  /// The website's zoom level as a viewport scale, the dashboard's own
  /// mechanism (viewport_zoom_script.dart). Re-asserted after every load:
  /// the rewritten meta dies with each document.
  Future<void> _applyZoom(InAppWebViewController controller) async {
    final settings = widget.container.settings;
    await controller.evaluateJavascript(
      source: viewportZoomJs(
        zoom: settings.get(defs.screensaverWebsiteZoom),
        pinch: settings.get(defs.pinchToZoom),
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

  bool get _renderPaused => widget.container.screensaver.renderPaused.value;

  /// Under the native voice overlay, which shows a still of the
  /// screensaver: the page is paused (its own onPause, which stops its
  /// scripts' rendering, animations and video) and the Media deck holds.
  void _renderPausedChanged() {
    unawaited(_setPhotoActivity());
    final controller = _webView;
    if (controller == null) return;
    unawaited(_renderPaused ? controller.pause() : controller.resume());
  }

  @override
  void initState() {
    super.initState();
    widget.container.screensaver.renderPaused.addListener(_renderPausedChanged);
    if (widget.mode == 'media') {
      _photoScreenSub = widget.container.bus.on<ScreenStateChanged>().listen((
        e,
      ) {
        _photoScreenOn = e.on;
        unawaited(_setPhotoActivity());
      });
      widget.container.screensaver.attachSlides(_step);
    }
    _kioskSub = widget.container.bus.on<SettingChanged>().listen((e) {
      if (!mounted) return;
      if (e.key == defs.screensaverMediaFill.key) {
        _photoFill = PhotoFillOverride.resolve(
          context,
          widget.container.settings.get(defs.screensaverMediaFill),
        );
        unawaited(_applyPhotoFill());
      }
      if (e.key == defs.screensaverMediaVideoLength.key) {
        unawaited(_applyVideoLength());
      }
      final controller = _webView;
      if (controller == null) return;
      // The website's zoom level applies live too, through the viewport
      // clamp; the bundled page has no such setting.
      if (e.key == defs.screensaverWebsiteZoom.key) {
        if (widget.mode == 'website') unawaited(_applyZoom(controller));
        return;
      }
      if (e.key != defs.haKioskMode.key &&
          e.key != defs.haKioskHideHeader.key &&
          e.key != defs.haKioskHideSidebar.key) {
        return;
      }
      unawaited(_applyKiosk(controller));
    });
  }

  @override
  void dispose() {
    widget.container.screensaver.renderPaused.removeListener(
      _renderPausedChanged,
    );
    widget.container.screensaver.detachSlides(_step);
    _retry?.cancel();
    _kioskSub?.cancel();
    _photoScreenSub?.cancel();
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

  /// A photo the Media page reported, or null for anything else.
  static ({String id, String url})? _mediaPhoto(List<dynamic> args) {
    final photo = args.isEmpty ? null : args.first;
    if (photo is! Map) return null;
    final id = photo['id'], url = photo['url'];
    if (id is! String || url is! String || Uri.tryParse(url) == null) {
      return null;
    }
    return (id: id, url: url);
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
      'mediaIsFolder': s.get(defs.screensaverMediaIsFolder),
      'photoActive': _photoScreenOn,
      'mediaIntervalSeconds': s.get(defs.screensaverMediaInterval),
      'mediaVideoLength': s.get(defs.screensaverMediaVideoLength),
      'mediaShuffle': s.get(defs.screensaverMediaShuffle),
      'mediaRecursive': s.get(defs.screensaverMediaRecursive),
      'mediaTransition': s.get(defs.screensaverMediaTransition),
      'mediaFill': _photoFill ?? s.get(defs.screensaverMediaFill),
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
      // Same policy as the kiosk WebView: the media screensaver talks to
      // the same self-signed Home Assistant.
      onReceivedServerTrustAuthRequest: (controller, challenge) async =>
          webViewServerTrust(
            'screensaver',
            widget.container.settings,
            challenge,
          ),
      // The user's pasted JavaScript for external pages, after every load
      // (issue #224). Only the website mode has a page of theirs to run it
      // on; the bundled screensaver is ours.
      onLoadStop: (controller, url) async {
        await _setPhotoActivity();
        if (!topLevel) {
          // WebViews older than 91 have no DOCUMENT_START_SCRIPT, and the
          // fallback injection of the config UserScript loses the race
          // against the bundled page's parse (issue #399). The page waits
          // for its config rather than reading it at parse time; hand it
          // over now for the WebViews where the injection arrived late.
          await controller.evaluateJavascript(
            source: 'window.ksSetConfig && window.ksSetConfig($_configJson);',
          );
          await _applyPhotoFill();
          return;
        }
        // This view outlives a settings change, so the flags baked in at
        // creation can be stale by the time a page loads.
        await _applyKiosk(controller);
        if (widget.container.settings.get(defs.screensaverWebsiteZoom) != 1) {
          await _applyZoom(controller);
        }
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
        if (_renderPaused) unawaited(controller.pause());
        controller.addJavaScriptHandler(
          handlerName: 'dismiss',
          callback: (_) {
            // 'touch_page', not 'touch': the kiosk screen's raw pointer
            // Listener reports the same taps, and under the double-tap
            // option (discussion #248) the manager must count each tap
            // once, so the bridge's reports carry their own name for it
            // to drop while that gate holds.
            widget.container.screensaver.notifyActivity(
              widget.container.screensaver.nowPlayingShared
                  ? 'screensaver_touch'
                  : 'touch_page',
            );
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
        // The Media page names each photo it loads and shows, so the
        // metadata panel over it can read the photo's EXIF (issue #953):
        // 'photo' as the image starts loading, a head start for the
        // lookup, and 'slide' once it is on screen (null for a video or a
        // camera).
        controller.addJavaScriptHandler(
          handlerName: 'photo',
          callback: (args) {
            final photo = _mediaPhoto(args);
            if (photo != null &&
                photoMetadataVisible(widget.container.settings, 'media')) {
              unawaited(remotePhotoDetails(photo.id, Uri.parse(photo.url)));
            }
            return null;
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'slide',
          callback: (args) {
            widget.container.screensaver.mediaSlide.value = _mediaPhoto(args);
            return null;
          },
        );
      },
    );
  }
}

/// The display aspect from the image descriptor, without a full decode.
/// The descriptor already accounts for EXIF orientation.
Future<double?> _aspectOf(Uint8List bytes) => photoAspect(bytes);

/// Whether [video] has frames to show. A video slide clears the photo, and
/// a decoder error resets the controller to uninitialized, so an errored
/// video with no photo behind it is an empty slide until the next one.
bool _videoShowing(VideoPlayerController? video) =>
    video != null && video.value.isInitialized;

/// A video slide under Fill the screen (issue #1298), decided by the photo
/// rule on the video's own shape. A video that covers is cropped to the
/// edges; the rest keep their frame between black bars. A blurred backdrop
/// like the photos get would blur every frame, so videos go without one.
/// The crop only scales the frames the decoder already made, so it costs
/// no extra memory.
Widget _videoSlide(VideoPlayerController video, String fill, Size screen) {
  final v = video.value;
  final covers =
      !v.size.isEmpty &&
      screen.height > 0 &&
      photoCovers(fill, v.aspectRatio, screen.width / screen.height);
  if (!covers) {
    return Center(
      child: AspectRatio(aspectRatio: v.aspectRatio, child: VideoPlayer(video)),
    );
  }
  return SizedBox.expand(
    child: FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: v.size.width,
        height: v.size.height,
        child: VideoPlayer(video),
      ),
    ),
  );
}

/// Whether a video slide stops once the seconds per photo run out instead
/// of playing to its end (issue #1298).
bool _videoFollowsInterval(String videoLength) => videoLength == 'interval';

/// Screen-off preserves the slide and its remaining hold. In-flight reads
/// finish, but decoding and committing a new slide wait for the panel. The
/// native voice overlay holds it the same way: it shows a still of the
/// screensaver, so nothing under it advances or decodes.
mixin _PhotoScreenState<T extends StatefulWidget> on State<T> {
  bool _awake = true;
  bool _screenOn = true;
  ValueListenable<bool>? _photoRenderPaused;
  StreamSubscription<ScreenStateChanged>? _photoScreenSub;
  Completer<void>? _wake;
  StreamSubscription<SettingChanged>? _photoSettingsSub;
  Future<void> Function()? _photoRefresh;
  Object? _photoViewport;

  void _watchPhotoSettings(
    AppContainer c,
    Set<String> keys,
    Future<void> Function() refresh,
  ) {
    _photoRefresh = refresh;
    _photoSettingsSub = c.bus.on<SettingChanged>().listen((e) {
      if (keys.contains(e.key)) unawaited(refresh());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.maybeOf(context);
    final viewport = (
      mq?.size,
      mq?.devicePixelRatio,
      PhotoFillOverride.of(context),
    );
    if (_photoViewport != null && _photoViewport != viewport) {
      final refresh = _photoRefresh;
      if (refresh != null) unawaited(refresh());
    }
    _photoViewport = viewport;
  }

  final _retiringPhotos = <PreparedPhoto>[];
  final _photoRetireTimers = <Timer>[];

  void _watchPhotoScreen(AppContainer c) {
    _screenOn = c.screen.isScreenOn;
    _photoRenderPaused = c.screensaver.renderPaused
      ..addListener(_photoAwakeChanged);
    _awake = _photoAwake;
    _photoScreenSub = c.bus.on<ScreenStateChanged>().listen((e) {
      _screenOn = e.on;
      _photoAwakeChanged();
    });
  }

  bool get _photoAwake => _screenOn && !(_photoRenderPaused?.value ?? false);

  void _photoAwakeChanged() {
    final awake = _photoAwake;
    if (!mounted || _awake == awake) return;
    setState(() => _awake = awake);
    if (awake) {
      _wake?.complete();
      _wake = null;
    }
    _photoScreenChanged(awake);
  }

  Future<void> _waitForPhotoScreen() async {
    if (!_awake && mounted) await (_wake ??= Completer<void>()).future;
  }

  void _photoScreenChanged(bool awake);

  /// Holds the video on screen with the slideshow, and plays it on after.
  void _holdVideo(VideoPlayerController? video, bool awake) {
    if (video == null || !video.value.isInitialized) return;
    if (!awake) {
      unawaited(video.pause());
      return;
    }
    final value = video.value;
    if (value.duration > Duration.zero && value.position >= value.duration) {
      return;
    }
    unawaited(video.play());
  }

  void _retirePhoto(PreparedPhoto? photo) {
    if (photo == null) return;
    _retiringPhotos.add(photo);
    late Timer timer;
    timer = Timer(const Duration(milliseconds: 1200), () {
      _photoRetireTimers.remove(timer);
      _retiringPhotos.remove(photo);
      photo.dispose();
    });
    _photoRetireTimers.add(timer);
  }

  @override
  void dispose() {
    _photoScreenSub?.cancel();
    _photoRenderPaused?.removeListener(_photoAwakeChanged);
    _photoSettingsSub?.cancel();
    _wake?.complete();
    for (final timer in _photoRetireTimers) {
      timer.cancel();
    }
    for (final photo in _retiringPhotos) {
      photo.dispose();
    }
    super.dispose();
  }
}

/// The Local Media screensaver: photos and videos from a folder on this
/// device, no Home Assistant involved. Photos hold for the configured
/// interval; videos play to their end or for the same interval, as Video
/// length says (muted — a screensaver that suddenly
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

class _LocalMediaScreensaverState extends State<LocalMediaScreensaver>
    with _PhotoScreenState<LocalMediaScreensaver> {
  static const _imageExt = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'};
  static const _videoExt = {'.mp4', '.webm', '.mkv', '.mov', '.3gp'};

  List<File> _files = const [];
  int _index = 0;
  PausableTimer? _timer;
  PreparedPhoto? _photo;
  int _photoFailures = 0;
  final _prepared = SlidePreloader<PreparedPhoto>((photo) => photo.dispose());
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
    _watchPhotoScreen(c);
    _watchPhotoSettings(c, {
      defs.screensaverLocalFill.key,
      defs.screensaverGalleryFill.key,
      defs.screensaverLocalTransition.key,
      defs.screensaverGalleryTransition.key,
      defs.screensaverLocalInterval.key,
      defs.screensaverGalleryInterval.key,
    }, _refreshPhoto);

    c.screensaver.attachSlides(_step);
    _load();
  }

  bool get _gallery => widget.mode == 'gallery';

  /// The hand-off a step is waiting on, so a second press mid-transition
  /// is dropped rather than racing two slides onto the screen.
  Future<void>? _stepping;

  /// The next or previous slide on request (the Home Assistant buttons),
  /// which restarts the hold from the new slide like any other hand-off.
  Future<void> _step(int direction) => _go(_index + direction.sign);

  Future<void> _go(int index) {
    if (_stepping != null || !mounted || _files.isEmpty) {
      return Future<void>.value();
    }
    final pending = _show(index);
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
      unawaited(_go(0));
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
      unawaited(_go(0));
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
    await _waitForPhotoScreen();
    if (!mounted) return;
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
      // Held apart from `video` so the catch can dispose an attempt that
      // got as far as opening; openVideo disposes the ones that did not.
      VideoPlayerController? opened;
      try {
        final video = opened = await openVideo(
          (viewType) => VideoPlayerController.file(
            file,
            viewType: viewType,
            videoPlayerOptions: mutedVideoOptions,
          ),
          onFallback: (e) => c.log.warn(
            'screensaver',
            'decoder refused the video surface, retrying on a platform '
                'view (${file.path}): $e',
          ),
        );
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
          } else if (!ended && v.hasError) {
            // A decoder that dies mid-playback resets the controller to
            // uninitialized and never reaches the end, so the error is the
            // cue instead.
            ended = true;
            if (!identical(_video, video)) return;
            c.log.warn(
              'screensaver',
              'video stopped playing (${file.path}): ${v.errorDescription}',
            );
            _advance();
          }
        });
        if (!mounted) {
          await video.dispose();
          await old?.dispose();
          return;
        }
        _photoFailures = 0;
        _video = video;
        final oldPhoto = _photo;
        _photo = null;
        _prepared.clear();
        c.screensaver.notifySlideChanged();
        setState(() {
          _index = next;
          _image = null;
        });
        _retirePhoto(oldPhoto);
        await video.play();
        _holdVideoForInterval(video);
      } catch (e) {
        // A codec the device lacks must not stall the slideshow. Skip past
        // `next` explicitly — _index never reached it, and retrying it
        // forever would loop on the same broken file.
        c.log.warn('screensaver', 'video failed (${file.path}): $e');
        await opened?.dispose();
        if (mounted) await _show(next + 1);
        await old?.dispose();
        return;
      }
    } else {
      PreparedPhoto photo;
      try {
        photo = await _prepared.take(
          _prepareKey(next),
          (valid) => _prepare(next, valid),
        );
      } catch (e) {
        if (e is! PhotoPreparationCancelled) {
          c.log.warn('screensaver', 'photo failed (${file.path}): $e');
          _photoFailures++;
          if (mounted && _photoFailures < _files.length) {
            await _show(next + 1);
          } else if (mounted) {
            setState(() => _problem = 'Could not read photos.');
          }
        }
        await old?.dispose();
        return;
      }
      await _waitForPhotoScreen();
      if (!mounted) {
        photo.dispose();
        await old?.dispose();
        return;
      }
      _photoFailures = 0;
      final oldPhoto = _photo;
      c.screensaver.notifySlideChanged();
      setState(() {
        _problem = null;
        _index = next;
        _photo = photo;
        _imageAspect = photo.aspect;
        _image = photo.image;
      });
      _retirePhoto(oldPhoto);
      if (_files.length > 1) {
        _timer = PausableTimer(_interval, _advance, paused: !_awake);
        _prefetch(next + 1);
      }
    }
    _retire(old);
  }

  Duration get _interval => Duration(
    seconds: c.settings
        .get(
          _gallery
              ? defs.screensaverGalleryInterval
              : defs.screensaverLocalInterval,
        )
        .toInt()
        .clamp(2, 3600),
  );

  /// With Video length on Same as photos, [video] gets the photo hold and
  /// the slideshow moves on when it runs out or the video ends, whichever
  /// comes first. The hold pauses with the screen like a photo's.
  void _holdVideoForInterval(VideoPlayerController video) {
    final length = c.settings.get(
      _gallery
          ? defs.screensaverGalleryVideoLength
          : defs.screensaverLocalVideoLength,
    );
    if (!mounted || !identical(_video, video) || _files.length < 2) return;
    if (!_videoFollowsInterval(length)) return;
    _timer?.cancel();
    _timer = PausableTimer(_interval, _advance, paused: !_awake);
  }

  Future<void> _refreshPhoto() async {
    _prepared.clear();
    await _stepping;
    if (!mounted) return;
    if (_image != null) {
      await _go(_index);
    } else if (_videoShowing(_video)) {
      // A new fill reframes the playing video without restarting it.
      setState(() {});
    }
  }

  String get _fill => PhotoFillOverride.resolve(
    context,
    c.settings.get(
      _gallery ? defs.screensaverGalleryFill : defs.screensaverLocalFill,
    ),
  );

  bool get _zoom => ['kenburns', 'zoom', 'random'].contains(
    c.settings.get(
      _gallery
          ? defs.screensaverGalleryTransition
          : defs.screensaverLocalTransition,
    ),
  );

  Object _prepareKey(int index) => (
    index,
    MediaQuery.sizeOf(context),
    MediaQuery.devicePixelRatioOf(context),
    _fill,
    _zoom,
  );

  Future<PreparedPhoto> _prepare(int index, bool Function() valid) async {
    final bytes = await _files[index].readAsBytes();
    if (!mounted || !valid()) throw PhotoPreparationCancelled();
    await _waitForPhotoScreen();
    if (!mounted || !valid()) throw PhotoPreparationCancelled();
    final mq = MediaQuery.of(context);
    return PreparedPhoto.prepare(
      bytes,
      context: context,
      frame: mq.size * mq.devicePixelRatio,
      fill: _fill,
      zoom: _zoom,
      valid: () => mounted && valid(),
      beforeDecode: _waitForPhotoScreen,
    );
  }

  void _prefetch(int index) {
    if (!_awake || _files.length < 2) return;
    final next = index % _files.length;
    if (_isVideo(_files[next])) return;
    _prepared.warm(_prepareKey(next), (valid) => _prepare(next, valid));
    if (photoMetadataVisible(c.settings, widget.mode)) {
      unawaited(localPhotoDetails(_files[next].path));
    }
  }

  @override
  void _photoScreenChanged(bool awake) {
    _holdVideo(_video, awake);
    if (awake) {
      _timer?.resume();
      if (_image != null && _stepping == null) _prefetch(_index + 1);
    } else {
      _timer?.pause();
      _prepared.clear();
    }
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
    unawaited(_step(1));
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
    _prepared.clear();
    _photo?.dispose();
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
          screensaverPlaybackNotice(context, _problem!),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    } else if (_files.isEmpty || (_image == null && !_videoShowing(video))) {
      body = const SizedBox.expand();
    } else {
      final transition = _transition;
      final isVideoSlide = video != null && video.value.isInitialized;
      // The index is in the key so a repeated file still hands off.
      final key = ValueKey('$_index:${_files[_index].path}');
      // Fill the screen: photoCovers holds the rule, shared with the
      // Immich screensaver. A photo that keeps its frame gets the photo
      // itself, blurred and dimmed, as the backdrop instead of black bars.
      // Videos follow the same rule without the backdrop (_videoSlide).
      final fill = _fill;
      final fillWanted = !isVideoSlide && fill != 'off';
      final size = MediaQuery.of(context).size;
      final covers =
          fillWanted &&
          photoCovers(fill, _imageAspect, size.width / size.height);
      final Widget inner;
      if (isVideoSlide) {
        inner = _videoSlide(video, fill, size);
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
            active: _awake,
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
                            image: _photo?.background ?? _image!,
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
    // The photo's own EXIF in a corner (issue #953). Local Media only: the
    // Photo Gallery shares this widget but has no metadata settings.
    final showMetadata =
        _problem == null &&
        _files.isNotEmpty &&
        (_image != null || _videoShowing(video)) &&
        photoMetadataVisible(c.settings, widget.mode);
    if (!showMetadata) return ColoredBox(color: Colors.black, child: body);
    final path = _files[_index].path;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          body,
          _PhotoMetadata(
            container: c,
            mode: widget.mode,
            // A video carries no EXIF, so it clears the panel.
            slide: _image != null ? '$_index:$path' : null,
            details: () => localPhotoDetails(path),
          ),
        ],
      ),
    );
  }
}

/// One image fetched from [url], for the Clock background and the Image URL
/// screensaver. No conditional caching: the point of a re-fetch is a new
/// image under the same URL, and a proxy answering 304 would defeat it.
/// The app makes the request itself, through the same certificate policy
/// as every other client in the process.
Future<Uint8List> fetchScreensaverImage(
  String url, {
  required Duration timeout,
}) async {
  final uri = Uri.parse(url.trim());
  final response = await http
      .get(uri, headers: const {'Cache-Control': 'no-cache'})
      .timeout(timeout);
  if (response.statusCode != 200) {
    throw HttpException('HTTP ${response.statusCode}', uri: uri);
  }
  return response.bodyBytes;
}

/// One photo the Image URL screensaver fetched, numbered in fetch order so
/// two answers from the same address still read as two slides.
class _UrlSlide {
  const _UrlSlide(this.serial, this.bytes);

  final int serial;
  final Uint8List bytes;
}

/// The Image URL screensaver (issue #1038): one address that answers with
/// a new image on every request, fetched again for every slide. There is
/// no playlist to read up front, so the next photo is fetched when the
/// hold ends and the current one stays on screen until it has decoded: a
/// slow or failing server never fades the screen to black. The last few
/// photos stay in memory so Previous has something to go back to.
class ImageUrlScreensaver extends StatefulWidget {
  const ImageUrlScreensaver({
    super.key,
    required this.container,
    this.retryDelay = const Duration(seconds: 30),
  });

  final AppContainer container;

  /// How long a failed fetch waits before the next try.
  final Duration retryDelay;

  @override
  State<ImageUrlScreensaver> createState() => _ImageUrlScreensaverState();
}

class _ImageUrlScreensaverState extends State<ImageUrlScreensaver>
    with _PhotoScreenState<ImageUrlScreensaver> {
  /// The photos Previous can step back through, the one on screen
  /// included. Few, since each holds a whole encoded photo.
  static const _historyLimit = 4;
  static const _fetchTimeout = Duration(seconds: 30);

  final _history = <_UrlSlide>[];

  /// Where in [_history] the photo on screen sits.
  int _position = -1;
  int _serial = 0;
  _UrlSlide? _slide;
  PreparedPhoto? _photo;
  PausableTimer? _timer;
  Timer? _retry;
  StreamSubscription<SettingChanged>? _urlSub;

  /// Set when there is nothing to show yet: no URL, or a first fetch that
  /// failed. A photo already on screen stays instead.
  String? _problem;

  /// The hand-off a step is waiting on, so a second press mid-fetch is
  /// dropped rather than racing two photos onto the screen.
  Future<void>? _stepping;

  /// The address a fetch in flight asked for.
  String? _fetching;

  AppContainer get c => widget.container;

  @override
  void initState() {
    super.initState();
    _watchPhotoScreen(c);
    _watchPhotoSettings(c, {
      defs.screensaverUrlFill.key,
      defs.screensaverUrlTransition.key,
      defs.screensaverUrlInterval.key,
    }, _refreshPhoto);
    // A new address shows at once rather than after the current hold.
    // A write that lands with the mode switch finds the first fetch
    // already asking for it, and does not fetch twice.
    _urlSub = c.bus.on<SettingChanged>().listen((e) {
      if (e.key != defs.screensaverUrlImage.key) return;
      if (_fetching == c.settings.get(defs.screensaverUrlImage).trim()) return;
      unawaited(_reload());
    });
    c.screensaver.attachSlides(_step);
    unawaited(_run(_fetchNext));
  }

  Future<void> _run(Future<void> Function() action) {
    if (_stepping != null || !mounted) return Future<void>.value();
    final pending = action();
    _stepping = pending;
    return pending.whenComplete(() => _stepping = null);
  }

  /// Next walks forward through photos Previous stepped back over, then
  /// fetches a new one. Previous stops at the oldest photo kept.
  Future<void> _step(int direction) {
    if (direction < 0) {
      if (_position <= 0) return Future<void>.value();
      return _run(() => _showKept(_position - 1));
    }
    if (_position < _history.length - 1) {
      return _run(() => _showKept(_position + 1));
    }
    return _run(_fetchNext);
  }

  void _advance() {
    if (mounted) unawaited(_step(1));
  }

  Future<void> _reload() async {
    await _stepping;
    if (mounted) await _run(_fetchNext);
  }

  Future<void> _fetchNext() async {
    _retry?.cancel();
    _retry = null;
    final url = c.settings.get(defs.screensaverUrlImage).trim();
    if (url.isEmpty) {
      _timer?.cancel();
      setState(() => _problem = 'No image URL set. Add one in Settings.');
      return;
    }
    await _waitForPhotoScreen();
    if (!mounted) return;
    final _UrlSlide slide;
    try {
      _fetching = url;
      slide = _UrlSlide(
        ++_serial,
        await fetchScreensaverImage(url, timeout: _fetchTimeout),
      );
      if (!mounted || !await _present(slide)) return;
    } catch (e) {
      if (!mounted) return;
      c.log.warn(
        'screensaver',
        'image URL fetch failed: $e; retrying in '
            '${widget.retryDelay.inSeconds}s',
      );
      _timer?.cancel();
      if (_slide == null) {
        setState(
          () => _problem = 'Could not load the image. Retrying automatically.',
        );
      }
      _retry = Timer(widget.retryDelay, _advance);
      return;
    } finally {
      _fetching = null;
    }
    _history.add(slide);
    if (_history.length > _historyLimit) _history.removeAt(0);
    _position = _history.length - 1;
  }

  Future<void> _showKept(int position) async {
    try {
      if (await _present(_history[position])) _position = position;
    } catch (e) {
      c.log.warn('screensaver', 'image URL photo failed: $e');
    }
  }

  /// Decodes [slide] and hands off to it, restarting the hold. False when
  /// the screensaver went away first.
  Future<bool> _present(_UrlSlide slide) async {
    final PreparedPhoto photo;
    try {
      photo = await _prepare(slide.bytes);
    } on PhotoPreparationCancelled {
      return false;
    }
    await _waitForPhotoScreen();
    if (!mounted) {
      photo.dispose();
      return false;
    }
    _timer?.cancel();
    _rolled = _randomPool[_rand.nextInt(_randomPool.length)];
    final old = _photo;
    c.screensaver.notifySlideChanged();
    setState(() {
      _problem = null;
      _slide = slide;
      _photo = photo;
    });
    _retirePhoto(old);
    _timer = PausableTimer(_interval, _advance, paused: !_awake);
    return true;
  }

  Future<PreparedPhoto> _prepare(Uint8List bytes) async {
    await _waitForPhotoScreen();
    if (!mounted) throw PhotoPreparationCancelled();
    final mq = MediaQuery.of(context);
    return PreparedPhoto.prepare(
      bytes,
      context: context,
      frame: mq.size * mq.devicePixelRatio,
      fill: _fill,
      zoom: _zoom,
      valid: () => mounted,
      beforeDecode: _waitForPhotoScreen,
    );
  }

  /// Decodes the photo on screen again for a new fill, transition or
  /// size, without fetching.
  Future<void> _refreshPhoto() async {
    await _stepping;
    final slide = _slide;
    if (!mounted || slide == null) return;
    await _run(() async {
      try {
        await _present(slide);
      } catch (e) {
        c.log.warn('screensaver', 'image URL photo failed: $e');
      }
    });
  }

  Duration get _interval => Duration(
    seconds: c.settings.get(defs.screensaverUrlInterval).toInt().clamp(5, 3600),
  );

  String get _fill => PhotoFillOverride.resolve(
    context,
    c.settings.get(defs.screensaverUrlFill),
  );

  bool get _zoom => [
    'kenburns',
    'zoom',
    'random',
  ].contains(c.settings.get(defs.screensaverUrlTransition));

  @override
  void _photoScreenChanged(bool awake) {
    if (awake) {
      _timer?.resume();
    } else {
      _timer?.pause();
    }
  }

  @override
  void dispose() {
    c.screensaver.detachSlides(_step);
    _urlSub?.cancel();
    _timer?.cancel();
    _retry?.cancel();
    _photo?.dispose();
    super.dispose();
  }

  static final _rand = Random();

  /// The transition Random rolled for the hand-off now on screen.
  String _rolled = 'fade';

  String get _transition {
    final setting = c.settings.get(defs.screensaverUrlTransition);
    return setting == 'random' ? _rolled : setting;
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slide;
    final photo = _photo;
    if (slide == null || photo == null) {
      return ColoredBox(
        color: Colors.black,
        child: _problem == null
            ? const SizedBox.expand()
            : Center(
                child: Text(
                  screensaverPlaybackNotice(context, _problem!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
      );
    }
    final transition = _transition;
    final key = ValueKey(slide.serial);
    // Fill the screen follows the same rule as the other photo modes: a
    // photo that keeps its frame gets itself, blurred and dimmed, as the
    // backdrop instead of black bars.
    final fill = _fill;
    final size = MediaQuery.of(context).size;
    final covers =
        fill != 'off' &&
        photoCovers(fill, photo.aspect, size.width / size.height);
    Widget picture = Image(
      image: photo.image,
      fit: covers ? BoxFit.cover : BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const SizedBox.expand(),
    );
    if (transition == 'kenburns') {
      picture = _KenBurnsDrift(
        index: slide.serial,
        active: _awake,
        duration: _interval + const Duration(seconds: 2),
        child: SizedBox.expand(child: picture),
      );
    }
    final inner = fill != 'off' && !covers
        ? Stack(
            fit: StackFit.expand,
            children: [
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
                        image: photo.background ?? photo.image,
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
    final Widget current = KeyedSubtree(key: key, child: inner);
    final body = transition == 'none'
        ? current
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
              child: current,
            ),
          );
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          body,
          if (photoMetadataVisible(c.settings, 'url'))
            _PhotoMetadata(
              container: c,
              mode: 'url',
              slide: '${slide.serial}',
              details: () => memoryPhotoDetails('${slide.serial}', slide.bytes),
            ),
        ],
      ),
    );
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

class _ImmichSlide {
  _ImmichSlide(this.photo, this.pair, this.pairIndex, this.pairing);
  final PreparedPhoto photo;
  final PreparedPhoto? pair;
  final int? pairIndex;

  /// How the two halves share the screen, null without a pair.
  final ImmichPairing? pairing;
  void dispose() {
    photo.dispose();
    pair?.dispose();
  }
}

class _ImmichScreensaverState extends State<ImmichScreensaver>
    with _PhotoScreenState<ImmichScreensaver> {
  List<ImmichAsset> _assets = const [];
  int _index = 0;
  PreparedPhoto? _photo;
  PreparedPhoto? _pairPhoto;
  final _prepared = SlidePreloader<_ImmichSlide>((slide) => slide.dispose());

  /// The current slide's provider, decoded at screen size and evicted
  /// from the engine's image cache when the slide leaves. Without the
  /// eviction every slide is a fresh never-hit cache key, so the cache
  /// ratchets to its 100MB cap and stays there for the process life.
  ImageProvider? _image;

  /// Width over height of the current image, or null when unknown; feeds
  /// the fill-the-screen decision.
  double? _imageAspect;

  /// The second half of a pair of photos: the playlist index right after
  /// [_index], its decoded provider and its aspect. Null whenever one photo
  /// (or a video) has the screen to itself, which is every slide that does
  /// not fit the panel's pairing and every slide at all with both pairing
  /// settings off.
  int? _pairIndex;
  ImageProvider? _pairImage;
  double? _pairAspect;

  /// Whether the showing pair sits side by side (two portrait photos on a
  /// landscape panel) or one above the other (two landscape photos on a
  /// portrait panel). Null without a pair.
  ImmichPairing? _pairing;

  /// How many playlist entries the current slide consumed, so the advance
  /// steps over both halves of a pair.
  int get _span => _pairIndex == null ? 1 : 2;

  PausableTimer? _timer;
  VideoPlayerController? _video;
  String? _problem;

  /// Whether the metadata overlay is on and so the pair's two panels
  /// actually occupy the bottom corners. Every line turned off counts as
  /// off: there would be nothing under the photos to protect.
  bool get _metadataOn => immichMetadataVisible(c.settings);

  Set<String>? _claimedCorners;

  /// The corners a pair's two metadata panels take, first half first: both
  /// bottom corners for photos side by side, so each panel sits under its
  /// own photo. Photos one above the other both use the bottom corner on
  /// the overlay's own side, the top photo's panel in the bottom corner of
  /// its own half (see the build), so the screen's top corners stay free
  /// for the widgets.
  List<String> get _pairCorners {
    if (_pairing == ImmichPairing.stacked) {
      final side =
          c.settings
              .get(defs.screensaverImmichMetadataPosition)
              .endsWith('right')
          ? 'right'
          : 'left';
      return ['bottom_$side', 'bottom_$side'];
    }
    return const ['bottom_left', 'bottom_right'];
  }

  /// Tell the widget layer which corners this slide has taken. A pair puts
  /// a metadata panel on each half, so the corners those sit in are spoken
  /// for; anything else leaves every corner to the widgets.
  void _claimCorners() {
    final corners = <String>{
      if (_pairIndex != null && _metadataOn) ..._pairCorners,
    };
    _claimedCorners = corners;
    c.screensaver.claimedCorners.value = corners;
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
  PausableTimer? _retry;
  late Duration _retryDelay = widget.retryFloor;
  static const _retryCeiling = Duration(seconds: 60);

  /// Reload after [_retryDelay], doubling the wait for the time after up
  /// to the ceiling. Idempotent while one is pending.
  void _scheduleRetry() {
    if (_retry?.isActive ?? false) return;
    final delay = _retryDelay;
    c.log.info('screensaver', 'immich retrying in ${delay.inSeconds}s');
    _retry = PausableTimer(delay, () {
      if (!mounted) return;
      _failures = 0;
      _lastFailure = null;
      unawaited(_load(fresh: true));
    }, paused: !_awake);
    _retryDelay = delay * 2 > _retryCeiling ? _retryCeiling : delay * 2;
  }

  AppContainer get c => widget.container;

  @override
  void initState() {
    super.initState();
    _watchPhotoScreen(c);
    _watchPhotoSettings(c, {
      defs.screensaverImmichFill.key,
      defs.screensaverImmichTransition.key,
      defs.screensaverImmichInterval.key,
      defs.screensaverImmichPairPortrait.key,
      defs.screensaverImmichPairLandscape.key,
    }, _refreshPhoto);

    c.screensaver.attachSlides(_step);
    _load();
  }

  /// See the Local Media state's [_stepping].
  Future<void>? _stepping;

  /// The next or previous slide on request. Forward steps over both halves
  /// of a showing pair, as the hold does; back goes to the photo before the
  /// pair's first, which may bring the first back as its partner.
  Future<void> _step(int direction) =>
      _go(direction > 0 ? _index + _span : _index - 1);

  Future<void> _go(int index) {
    if (_stepping != null || !mounted || _assets.isEmpty) {
      return Future<void>.value();
    }
    final pending = _show(index);
    _stepping = pending;
    return pending.whenComplete(() => _stepping = null);
  }

  /// [fresh] asks the server for the playlist again, dropping the one the
  /// manager kept: a retry after every photo failed to fetch may be
  /// looking at deleted assets.
  Future<void> _load({bool fresh = false}) async {
    await _waitForPhotoScreen();
    if (!mounted) return;
    if (!c.settings.get(defs.screensaverImmichValidated)) {
      setState(
        () => _problem = 'Immich is not connected. Validate it in Settings.',
      );
      return;
    }
    final started = Stopwatch()..start();
    try {
      // The manager keeps the playlist between sessions and readies the
      // first photo ahead of the idle clock (issue #659), so this waits on
      // the server only when nothing was kept.
      final assets = await c.immich.startOrder(fresh: fresh);
      if (assets.isEmpty) {
        setState(
          () => _problem = immichFiltersActive(c.settings)
              ? 'No media matches the source and filters.'
              : 'No media in the selected source.',
        );
        return;
      }
      if (!mounted) return;
      // On the shuffled order, so a photo reaches for its partner in the
      // order the slideshow will actually run in.
      final size = MediaQuery.of(context).size;
      final pairPortrait = c.settings.get(defs.screensaverImmichPairPortrait);
      final pairLandscape = c.settings.get(defs.screensaverImmichPairLandscape);
      final arranged = (pairPortrait || pairLandscape) && size.height > 0
          ? arrangeImmichPairs(
              assets,
              screenAspect: size.width / size.height,
              portrait: pairPortrait,
              landscape: pairLandscape,
            )
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
      unawaited(
        _go(0).then((_) {
          if (mounted && _image != null) {
            c.log.info(
              'screensaver',
              'immich first slide in ${started.elapsedMilliseconds} ms',
            );
          }
        }),
      );
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
    await _waitForPhotoScreen();
    if (!mounted) return;
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
    // Its turn in the lap came, whether it shows or has to be passed over,
    // so the next session starts with what this one did not reach.
    c.immich.markShown(asset);
    if (asset.isVideo) {
      // A video the device cannot afford to buffer is passed over, and
      // remembered so a lap of the playlist asks the server only once. A
      // playlist that is nothing but such videos says so instead of
      // spinning through them forever.
      if (!await c.immich.videoFits(asset)) {
        _skippedVideos.add(asset.id);
        if (!mounted) {
          await old?.dispose();
          return;
        }
        if (_skippedVideos.length >= _assets.length) {
          setState(
            () => _problem =
                'Every video in this playlist is too large for this '
                'device to play.',
          );
          await old?.dispose();
          return;
        }
        await _show(next + 1);
        await old?.dispose();
        return;
      }
      // Streamed, never cached; the previous slide holds until frames exist.
      // Held apart from `video` so the catch can dispose an attempt that
      // got as far as opening; openVideo disposes the ones that did not.
      VideoPlayerController? opened;
      try {
        final video = opened = await openVideo(
          (viewType) => VideoPlayerController.networkUrl(
            c.immich.videoUri(asset),
            httpHeaders: c.immich.videoHeaders,
            viewType: viewType,
            videoPlayerOptions: mutedVideoOptions,
          ),
          onFallback: (e) => c.log.warn(
            'screensaver',
            'decoder refused the video surface, retrying on a platform '
                'view: $e',
          ),
        );
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
          } else if (!ended && v.hasError) {
            // A decoder that dies mid-playback resets the controller to
            // uninitialized and never reaches the end, so the error is the
            // cue instead.
            ended = true;
            if (!identical(_video, video)) return;
            c.log.warn(
              'screensaver',
              'immich video stopped playing (${asset.id}): '
                  '${v.errorDescription}',
            );
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
        final oldPhoto = _photo;
        final oldPairPhoto = _pairPhoto;
        setState(() {
          _index = next;
          _photo = null;
          _pairPhoto = null;
          _image = null;
          _pairIndex = null;
          _pairImage = null;
          _pairAspect = null;
          _pairing = null;
        });
        _claimCorners();
        _retirePhoto(oldPhoto);
        _retirePhoto(oldPairPhoto);
        // A warmed buffer for a slide we already passed would sit through
        // the whole video for nothing. Nothing is warmed for the next slide
        // while a video plays either: its buffers and a decoded photo
        // would share the heap (see ImmichManager.videoFits).
        _prepared.clear();
        await video.play();
        _holdVideoForInterval(video);
      } catch (e) {
        c.log.warn('screensaver', 'immich video failed (${asset.id}): $e');
        await opened?.dispose();
        _failures++;
        _lastFailure = c.immich.readableError(e);
        if (mounted) await _show(next + 1);
        await old?.dispose();
        return;
      }
    } else {
      _ImmichSlide slide;
      try {
        slide = await _prepared.take(
          _prepareKey(next),
          (valid) => _prepareSlide(next, valid),
        );
      } catch (e) {
        if (e is! PhotoPreparationCancelled) {
          c.log.warn('screensaver', 'immich image failed (${asset.id}): $e');
          _failures++;
          _lastFailure = c.immich.readableError(e);
          if (mounted) await _show(next + 1);
        }
        await old?.dispose();
        return;
      }
      await _waitForPhotoScreen();
      if (!mounted) {
        slide.dispose();
        await old?.dispose();
        return;
      }
      _failures = 0;
      _lastFailure = null;
      if (slide.pairIndex case final i?) c.immich.markShown(_assets[i]);
      final oldPhoto = _photo;
      final oldPairPhoto = _pairPhoto;
      c.screensaver.notifySlideChanged();
      setState(() {
        _index = next;
        _photo = slide.photo;
        _pairPhoto = slide.pair;
        _imageAspect = slide.photo.aspect;
        _image = slide.photo.image;
        _pairIndex = slide.pairIndex;
        _pairImage = slide.pair?.image;
        _pairAspect = slide.pair?.aspect;
        _pairing = slide.pairing;
      });
      _claimCorners();
      _retirePhoto(oldPhoto);
      _retirePhoto(oldPairPhoto);
      if (_assets.length > _span) {
        _timer = PausableTimer(_interval, _advance, paused: !_awake);
        _prefetch(next + _span);
      }
    }
    _retire(old);
  }

  Duration get _interval => Duration(
    seconds: c.settings
        .get(defs.screensaverImmichInterval)
        .toInt()
        .clamp(2, 3600),
  );

  /// See the Local Media state's [_holdVideoForInterval].
  void _holdVideoForInterval(VideoPlayerController video) {
    final length = c.settings.get(defs.screensaverImmichVideoLength);
    if (!mounted || !identical(_video, video) || _assets.length < 2) return;
    if (!_videoFollowsInterval(length)) return;
    _timer?.cancel();
    _timer = PausableTimer(_interval, _advance, paused: !_awake);
  }

  /// The photo that should share the screen with the one at [index], or
  /// null when this slide stands alone: pairing off, a panel with no room
  /// for the pairing it is set to, either photo the wrong shape for it, the
  /// next entry a video, a playlist with nothing else in it, or a fetch
  /// that failed (a pair is a bonus, never a reason to stall the
  /// slideshow).
  Future<({int index, Uint8List bytes, double? aspect, ImmichPairing pairing})?>
  _pairFor(int index, double? aspect, Size screen) async {
    if (_assets.length < 2) return null;
    final screenAspect = screen.height == 0
        ? 0.0
        : screen.width / screen.height;
    final pairing = immichPairingFor(
      screenAspect,
      portrait: c.settings.get(defs.screensaverImmichPairPortrait),
      landscape: c.settings.get(defs.screensaverImmichPairLandscape),
    );
    if (pairing == null || !immichPairPhoto(pairing, aspect)) return null;
    final candidate = (index + 1) % _assets.length;
    final asset = _assets[candidate];
    if (asset.isVideo) return null;
    if (immichMetadataShown(c.settings)) {
      unawaited(c.immich.assetDetails(asset));
    }
    try {
      final bytes = await c.immich.imageBytes(asset);
      final pairAspect = await _aspectOf(bytes);
      if (!immichPairPhoto(pairing, pairAspect)) return null;
      return (
        index: candidate,
        bytes: bytes,
        aspect: pairAspect,
        pairing: pairing,
      );
    } catch (e) {
      // The second half is optional; the first photo shows on its own and
      // the failing asset gets its own turn (and its own error handling)
      // on the next advance.
      c.log.debug('screensaver', 'immich pair fetch failed: $e');
      return null;
    }
  }

  Future<void> _refreshPhoto() async {
    _prepared.clear();
    await _stepping;
    if (!mounted) return;
    if (_image != null) {
      await _go(_index);
    } else if (_videoShowing(_video)) {
      // A new fill reframes the playing video without restarting it.
      setState(() {});
    }
  }

  Object _prepareKey(int index) => (
    index,
    MediaQuery.sizeOf(context),
    MediaQuery.devicePixelRatioOf(context),
    PhotoFillOverride.resolve(
      context,
      c.settings.get(defs.screensaverImmichFill),
    ),
    c.settings.get(defs.screensaverImmichTransition),
    c.settings.get(defs.screensaverImmichPairPortrait),
    c.settings.get(defs.screensaverImmichPairLandscape),
  );

  Future<_ImmichSlide> _prepareSlide(int index, bool Function() valid) async {
    bool current() => mounted && valid();
    final bytes = await c.immich.imageBytes(_assets[index]);
    if (!mounted || !valid()) throw PhotoPreparationCancelled();
    await _waitForPhotoScreen();
    if (!mounted || !valid()) throw PhotoPreparationCancelled();
    final aspect = await _aspectOf(bytes);
    if (!mounted || !valid()) throw PhotoPreparationCancelled();
    final mq = MediaQuery.of(context);
    final pair = await _pairFor(index, aspect, mq.size);
    if (!mounted || !valid()) throw PhotoPreparationCancelled();
    await _waitForPhotoScreen();
    if (!mounted || !valid()) throw PhotoPreparationCancelled();
    // Each half decodes for the half it will fill: the left or right half
    // of the width side by side, the top or bottom half of the height
    // stacked.
    final frame =
        switch (pair?.pairing) {
          null => mq.size,
          ImmichPairing.sideBySide => Size(mq.size.width / 2, mq.size.height),
          ImmichPairing.stacked => Size(mq.size.width, mq.size.height / 2),
        } *
        mq.devicePixelRatio;
    final fill = PhotoFillOverride.resolve(
      context,
      c.settings.get(defs.screensaverImmichFill),
    );
    final zoom = [
      'kenburns',
      'zoom',
      'random',
    ].contains(c.settings.get(defs.screensaverImmichTransition));
    final photo = await PreparedPhoto.prepare(
      bytes,
      context: context,
      frame: frame,
      fill: fill,
      zoom: zoom,
      aspect: aspect,
      valid: current,
      beforeDecode: _waitForPhotoScreen,
    );
    try {
      if (!mounted || !valid()) throw PhotoPreparationCancelled();
      final partner = pair == null
          ? null
          : await PreparedPhoto.prepare(
              pair.bytes,
              context: context,
              frame: frame,
              fill: fill,
              zoom: zoom,
              aspect: pair.aspect,
              valid: current,
              beforeDecode: _waitForPhotoScreen,
            );
      return _ImmichSlide(photo, partner, pair?.index, pair?.pairing);
    } catch (e) {
      photo.dispose();
      if (e is PhotoPreparationCancelled || !mounted || !valid()) rethrow;
      // A broken optional partner must not discard the usable first photo.
      c.log.debug('screensaver', 'immich partner decode failed: $e');
      final single = await PreparedPhoto.prepare(
        bytes,
        context: context,
        frame: mq.size * mq.devicePixelRatio,
        fill: fill,
        zoom: zoom,
        aspect: aspect,
        valid: current,
        beforeDecode: _waitForPhotoScreen,
      );
      return _ImmichSlide(single, null, null, null);
    }
  }

  void _prefetch(int index) {
    if (!_awake || _assets.length <= _span) return;
    final next = index % _assets.length;
    final asset = _assets[next];
    if (immichMetadataShown(c.settings)) {
      unawaited(c.immich.assetDetails(asset));
    }
    if (asset.isVideo) return;
    _prepared.warm(_prepareKey(next), (valid) => _prepareSlide(next, valid));
  }

  @override
  void _photoScreenChanged(bool awake) {
    _holdVideo(_video, awake);
    if (awake) {
      _timer?.resume();
      _retry?.resume();
      if (_image != null && _stepping == null) _prefetch(_index + _span);
    } else {
      _timer?.pause();
      _retry?.pause();
      _prepared.clear();
    }
  }

  final _retiring = <VideoPlayerController>[];
  final _retireTimers = <Timer>[];

  /// The videos this device could not afford to buffer; see
  /// ImmichManager.videoFits.
  final _skippedVideos = <String>{};

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
    unawaited(_step(1));
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
    _prepared.clear();
    _photo?.dispose();
    _pairPhoto?.dispose();
    // Disposal runs while Flutter locks the widget tree. Notify the corner
    // widgets after the frame so their rebuild can schedule another frame.
    // A replacement slideshow may already have claimed its own corners.
    final corners = c.screensaver.claimedCorners;
    final claimed = _claimedCorners;
    scheduleMicrotask(() {
      if (claimed != null && identical(corners.value, claimed)) {
        corners.value = const {};
      }
    });
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
  /// Fill the screen: photoCovers holds the rule, and the frame here is
  /// the whole panel or half of it. A photo that keeps its frame gets the
  /// photo itself, blurred and dimmed, as the backdrop instead of black
  /// bars — the Now Playing treatment.
  Widget _photoBlock({
    required ImageProvider image,
    ImageProvider? background,
    required double? aspect,
    required double frameAspect,
    required int index,
    required String transition,
  }) {
    final fill = PhotoFillOverride.resolve(
      context,
      c.settings.get(defs.screensaverImmichFill),
    );
    final fillWanted = fill != 'off';
    final covers = photoCovers(fill, aspect, frameAspect);
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
        active: _awake,
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
                  image: background ?? image,
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

  /// The metadata panel for [asset], whose details the Immich server holds.
  Widget _immichMetadata(
    ImmichAsset asset, {
    String? corner,
    _CaptionHalf? captionHalf,
    bool reportCaption = true,
  }) => _PhotoMetadata(
    container: c,
    mode: 'immich',
    slide: asset.id,
    details: () => c.immich.assetDetails(asset),
    corner: corner,
    captionHalf: captionHalf,
    reportCaption: reportCaption,
  );

  @override
  Widget build(BuildContext context) {
    final video = _video;
    Widget body;
    if (_problem != null) {
      body = Center(
        child: Text(
          screensaverPlaybackNotice(context, _problem!),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    } else if (_image == null && !_videoShowing(video)) {
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
        inner = _videoSlide(
          video,
          PhotoFillOverride.resolve(
            context,
            c.settings.get(defs.screensaverImmichFill),
          ),
          size,
        );
      } else if (pairIndex == null) {
        inner = _photoBlock(
          image: _image!,
          background: _photo?.background,
          aspect: _imageAspect,
          frameAspect: size.height == 0 ? 1 : size.width / size.height,
          index: _index,
          transition: transition,
        );
      } else {
        // Two photos, half the panel each: no gutter between them, since
        // the whole point is that no screen goes to waste. Portrait photos
        // split the width, landscape photos the height. Each half makes
        // its own fill decision against its half frame, so an ordinary
        // portrait shot covers its side completely and an ordinary
        // landscape shot its band.
        final stacked = _pairing == ImmichPairing.stacked;
        final half = size.height == 0
            ? 1.0
            : stacked
            ? size.width / (size.height / 2)
            : size.width / 2 / size.height;
        final halves = [
          Expanded(
            child: _photoBlock(
              image: _image!,
              background: _photo?.background,
              aspect: _imageAspect,
              frameAspect: half,
              index: _index,
              transition: transition,
            ),
          ),
          Expanded(
            child: _photoBlock(
              image: _pairImage!,
              background: _pairPhoto?.background,
              aspect: _pairAspect,
              frameAspect: half,
              index: pairIndex,
              transition: transition,
            ),
          ),
        ];
        inner = stacked ? Column(children: halves) : Row(children: halves);
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
        (_image != null || video != null) &&
        immichMetadataShown(c.settings);
    final pairIndex = _pairIndex;
    return ColoredBox(
      color: Colors.black,
      child: showMetadata
          ? Stack(
              fit: StackFit.expand,
              children: [
                body,
                // A pair gets a panel per photo, each on its own half,
                // rather than one panel speaking for a photo it may not
                // even be next to. The corners are fixed here (the widget
                // layer stands down from both while the pair holds them).
                if (pairIndex == null)
                  _immichMetadata(_assets[_index])
                else ...[
                  if (_pairing == ImmichPairing.stacked)
                    // The top photo's panel lives in the top half, so its
                    // bottom corner is the middle of the screen: the photo
                    // keeps its details under it, and the screen's top
                    // corners stay the widgets'.
                    // Its caption likewise sits over the seam, under its
                    // own photo, and stays out of the At a Glance row's
                    // reckoning since it is nowhere near the bottom.
                    Positioned(
                      left: 0,
                      top: 0,
                      right: 0,
                      height: MediaQuery.sizeOf(context).height / 2,
                      child: _immichMetadata(
                        _assets[_index],
                        corner: _pairCorners[0],
                        reportCaption: false,
                      ),
                    )
                  else
                    _immichMetadata(
                      _assets[_index],
                      corner: _pairCorners[0],
                      captionHalf: _CaptionHalf.left,
                    ),
                  _immichMetadata(
                    _assets[pairIndex],
                    corner: _pairCorners[1],
                    captionHalf: _pairing == ImmichPairing.stacked
                        ? null
                        : _CaptionHalf.right,
                  ),
                ],
              ],
            )
          : body,
    );
  }
}

/// The metadata panel in a corner of a photo screensaver: album, date,
/// camera and location on Immich, the date and camera from the photo's EXIF
/// elsewhere, shadow-on-photo text like the small clock, and only the lines
/// the slide actually carries. The panel outlives the slide: the vignette
/// holds steady from photo to photo while the text fades out with the old
/// one and back in with the new. Remounting the whole panel per slide read
/// as a hard blink against the crossfading photos.
class _PhotoMetadata extends StatefulWidget {
  const _PhotoMetadata({
    required this.container,
    required this.mode,
    required this.slide,
    required this.details,
    this.corner,
    this.captionHalf,
    this.reportCaption = true,
  });

  final AppContainer container;

  /// The screensaver mode, which picks the settings the panel follows.
  final String mode;

  /// What identifies the slide on screen, or null for one with nothing to
  /// say (a camera stream). A new value swaps the text.
  final String? slide;

  /// The slide's lines, looked up when [slide] changes.
  final Future<Map<String, String>> Function() details;

  /// The corner this panel must sit in, overriding both the setting and the
  /// step-past-a-widget search: a pair's two panels belong under their own
  /// photos, and the widgets give those corners up instead.
  final String? corner;

  /// The half of the screen the caption centers in, for a pair side by
  /// side, so each description sits under its own photo. Null centers it
  /// across the whole area the panel is given.
  final _CaptionHalf? captionHalf;

  /// Whether the caption tells the At a Glance row how high it reaches.
  /// Only a caption at the bottom of the screen is in the row's way: the
  /// top photo of a stacked pair keeps its caption over the seam.
  final bool reportCaption;

  @override
  State<_PhotoMetadata> createState() => _PhotoMetadataState();
}

class _PhotoMetadataState extends State<_PhotoMetadata> {
  /// The details on screen right now. They lag [_PhotoMetadata.slide] by
  /// design: the old text holds through its fade-out, and the vignette
  /// rides this map, so it only moves when a slide truly has no lines.
  Map<String, String> _details = const {};
  bool _textVisible = false;

  static const _fade = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _swap(fadeOut: false);
  }

  @override
  void didUpdateWidget(_PhotoMetadata old) {
    super.didUpdateWidget(old);
    if (old.slide != widget.slide) _swap(fadeOut: true);
  }

  /// Fade the old text out, look up the new slide's lines (already cached
  /// when a prefetch got there first), fade back in. A newer swap wins:
  /// each continuation checks it still speaks for the current slide.
  Future<void> _swap({required bool fadeOut}) async {
    final slide = widget.slide;
    if (fadeOut) setState(() => _textVisible = false);
    final details = slide == null
        ? const <String, String>{}
        : await widget.details();
    if (fadeOut) await Future<void>.delayed(_fade);
    if (!mounted || widget.slide != slide) return;
    setState(() {
      _details = details;
      _textVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.container.settings;
    // Widgets own their corners: rather than stacking two panels into
    // one corner, the metadata steps to the first free one, and stands
    // down entirely on the (unlikely) fully claimed screen. The helper
    // is shared with the At a Glance row, which narrows when this
    // settles in a bottom corner. A pair's corners are fixed instead.
    final spot = !photoMetadataVisible(settings, widget.mode)
        ? null
        : widget.corner ?? photoMetadataCorner(settings, widget.mode);
    final caption = photoCaptionOn(settings, widget.mode);
    if (!caption) {
      return spot == null
          ? const SizedBox.shrink()
          : _panel(_cornerAlignment(spot));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (spot != null) _panel(_cornerAlignment(spot)),
        _caption(spot),
      ],
    );
  }

  /// The caption: the photo's description centered at the bottom (issue
  /// #1290), wrapped between the bottom corner panel and its mirror image
  /// when two lines fit there, raised above the panel when they do not.
  /// [panelCorner] is the corner this slide's panel sits in, null without
  /// one.
  Widget _caption(String? panelCorner) {
    final container = widget.container;
    final metadata = photoMetadataDefs[widget.mode]!;
    final shadows = _overlayTextShadows(
      container,
      setting: metadata.textShadow,
    );
    final scale = container.settings.get(metadata.scale).toDouble() / 100;
    final text = _details['description'];
    final bottomPanel = panelCorner != null && panelCorner.startsWith('bottom_')
        ? panelCorner
        : null;
    final half = widget.captionHalf;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: text == null ? 0 : 1,
            duration: _fade,
            child: _cornerVignette(
              switch (half) {
                null => Alignment.bottomCenter,
                _CaptionHalf.left => const Alignment(-0.5, 1),
                _CaptionHalf.right => const Alignment(0.5, 1),
              },
              container,
              radius: 0.6,
              def: metadata.vignette,
            ),
          ),
          ValueListenableBuilder<Map<String, Size>>(
            valueListenable: container.screensaver.metadataFootprint,
            builder: (context, footprint, _) => LayoutBuilder(
              builder: (context, constraints) {
                final width = half == null
                    ? constraints.maxWidth
                    : constraints.maxWidth / 2;
                final (:bottom, :maxWidth) = captionPlacement(
                  width: width,
                  // The panel's own margin, so a caption beside it
                  // ends on the same line as the panel's last row.
                  inset: 28,
                  scale: scale,
                  panel: bottomPanel == null ? null : footprint[bottomPanel],
                );
                final placed = Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottom),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: _ReportSize(
                        onSize: widget.reportCaption && text != null
                            ? (size) => container.screensaver
                                  .reportCaptionFootprint(bottom + size.height)
                            : null,
                        child: AnimatedOpacity(
                          opacity: _textVisible && text != null ? 1 : 0,
                          duration: _fade,
                          child: Text(
                            text ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 17 * scale,
                              shadows: shadows,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                if (half == null) return placed;
                // Laid out inside its own half rather than aligned across
                // the screen: an alignment matches the same fraction of
                // the caption and the screen, so a wide caption would
                // drift toward the middle and into its neighbor.
                return Align(
                  alignment: half == _CaptionHalf.left
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: SizedBox(
                    width: width,
                    height: constraints.maxHeight,
                    child: placed,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// The panel itself, anchored to [corner].
  Widget _panel(Alignment corner) {
    final metadata = photoMetadataDefs[widget.mode]!;
    final shadows = _overlayTextShadows(
      widget.container,
      setting: metadata.textShadow,
    );
    // Fixed pixel sizes, then the Text scaling slider over every one of
    // them (text, icons and the gap between), the widgets' rule.
    final scale =
        widget.container.settings.get(metadata.scale).toDouble() / 100;
    TextStyle style({double size = 16, FontWeight? weight, double alpha = 1}) =>
        TextStyle(
          fontFamily: 'Rubik',
          color: Colors.white.withValues(alpha: alpha),
          fontSize: size * scale,
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
        width: 15 * scale,
        height: 15 * scale,
        colorFilter: ColorFilter.mode(
          Colors.white.withValues(alpha: 0.85),
          BlendMode.srcIn,
        ),
      );
      final gap = SizedBox(width: 9 * scale);
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
        photoMetadataFieldOn(widget.container.settings, widget.mode, field)
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
            child: _cornerVignette(
              corner,
              widget.container,
              radius: 0.6,
              def: metadata.vignette,
            ),
          ),
          AnimatedOpacity(
            opacity: _textVisible && lines.isNotEmpty ? 1 : 0,
            duration: _fade,
            child: Align(
              alignment: corner,
              child: _ReportSize(
                // A bottom panel tells the At a Glance row how much room
                // it takes, so the row keeps clear of it (issue #916).
                onSize: corner.y > 0 && lines.isNotEmpty
                    ? (size) =>
                          widget.container.screensaver.reportMetadataFootprint(
                            corner.x < 0 ? 'bottom_left' : 'bottom_right',
                            size,
                          )
                    : null,
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
          ),
        ],
      ),
    );
  }
}

/// Hands its child's laid-out size to [onSize] whenever it changes, after
/// the frame, since a listener may rebuild other widgets.
class _ReportSize extends SingleChildRenderObjectWidget {
  const _ReportSize({required this.onSize, super.child});

  final ValueChanged<Size>? onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReportSize(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderReportSize render) =>
      render.onSize = onSize;
}

class _RenderReportSize extends RenderProxyBox {
  _RenderReportSize(this.onSize);

  ValueChanged<Size>? onSize;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final callback = onSize;
    if (callback == null || size == _reported) return;
    final reported = _reported = size;
    SchedulerBinding.instance.addPostFrameCallback((_) => callback(reported));
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
    required this.active,
    required this.child,
  });

  final bool active;
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
  final _clock = Stopwatch();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncActivity();
  }

  @override
  void didUpdateWidget(_KenBurnsDrift oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncActivity();
  }

  void _syncActivity() {
    _timer?.cancel();
    if (!widget.active) {
      _clock.stop();
      return;
    }
    if (_progress.value >= 1) return;
    _clock.start();
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
    c.screensaver.renderPaused.addListener(_syncPaused);
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
    _background =
        state != AppLifecycleState.resumed &&
        state != AppLifecycleState.inactive;
    _syncPaused();
  }

  bool _background = false;

  /// Behind another app, or under the native voice overlay (which shows a
  /// still of the grid): the rotation holds.
  void _syncPaused() {
    final paused = _background || c.screensaver.renderPaused.value;
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
    c.screensaver.renderPaused.removeListener(_syncPaused);
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
              paused: c.screensaver.renderPaused,
            ),
    ),
  );
}

/// Lifts the bottom corner widgets just above the Weather Mood chips, by
/// the height the chips measured after layout.
class _AboveWeatherChips extends StatelessWidget {
  const _AboveWeatherChips({
    required this.container,
    required this.enabled,
    required this.child,
  });
  final AppContainer container;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ValueListenableBuilder<double>(
      valueListenable: container.screensaver.weatherChipsHeight,
      builder: (context, height, child) => Padding(
        padding: EdgeInsets.only(bottom: height),
        child: child,
      ),
      child: child,
    );
  }
}
