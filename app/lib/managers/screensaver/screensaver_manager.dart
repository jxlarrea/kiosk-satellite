import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../core/active_interactions.dart';
import '../../core/app_locales.dart';
import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../../l10n/generated/message_lookup.dart';
import '../../l10n/generated/setting_option_ids.dart';
import '../../l10n/generated/ui_strings.dart';
import '../camera/models.dart' show encodeCameraViewIds;
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'screensaver_widgets.dart';

/// A slideshow's hand on its own deck: a positive [direction] shows the
/// next slide, a negative one the slide before, either way restarting the
/// hold from the new slide.
typedef SlideNavigator = Future<void> Function(int direction);

/// "HH:MM" as minutes since midnight, or null when malformed.
int? scheduleMinutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return null;
  }
  return h * 60 + m;
}

/// The stored schedule JSON as validated entries, sorted by time. Malformed
/// entries (bad time, missing mode) are dropped rather than breaking the
/// whole schedule; garbage input is an empty schedule.
List<Map<String, Object?>> parseScreensaverSchedule(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) return const [];
    final entries = <Map<String, Object?>>[];
    for (final e in decoded) {
      if (e is! Map) continue;
      final at = e['at'];
      final mode = e['mode'];
      if (at is! String || mode is! String) continue;
      if (scheduleMinutes(at) == null) continue;
      entries.add({
        'at': at,
        'mode': mode,
        if (e['brightness'] is num)
          'brightness': (e['brightness'] as num).clamp(0, 1),
        // Tri-state motion override (issue #89): absent follows the
        // "Dismiss on motion" switch.
        if (e['motion'] is bool) 'motion': e['motion'],
        // The same for "Dismiss on face" (issue #304): a day entry can
        // wake on faces while a night entry falls back to motion.
        if (e['face'] is bool) 'face': e['face'],
        // And for "Dismiss on proximity" and "Dismiss on person" (issue
        // #437), each gated by the device having the sensor at all.
        if (e['proximity'] is bool) 'proximity': e['proximity'],
        if (e['person'] is bool) 'person': e['person'],
        // Tri-state widgets override: absent shows whatever the Widgets
        // group configures, false hides the corner widgets for this
        // entry's hours.
        if (e['widgets'] is bool) 'widgets': e['widgets'],
        // The same for the At a glance row.
        if (e['glance'] is bool) 'glance': e['glance'],
        if (e['now_playing'] is bool) 'now_playing': e['now_playing'],
        // The entry's own "Turn screen off after" (issue #437), in minutes:
        // absent follows the slider outside the schedule, 0 keeps the
        // panel on for this entry's hours even when that slider is set.
        if (e['screen_off'] is num)
          'screen_off': (e['screen_off'] as num).clamp(0, 60).toInt(),
      });
    }
    entries.sort(
      (a, b) => scheduleMinutes(
        a['at'] as String,
      )!.compareTo(scheduleMinutes(b['at'] as String)!),
    );
    return entries;
  } catch (_) {
    return const [];
  }
}

/// The schedule entry in force now, or null when scheduling is disabled.
Map<String, Object?>? currentScreensaverScheduleEntry(
  SettingsManager settings, {
  DateTime? now,
}) {
  if (!settings.get(defs.screensaverScheduleEnabled)) return null;
  final entries = parseScreensaverSchedule(
    settings.get(defs.screensaverSchedule),
  );
  final time = now ?? DateTime.now();
  return activeScheduleEntry(entries, time.hour * 60 + time.minute);
}

/// [entry] written into [entries]: replacing the one at [index], or appended
/// when [index] is null (or no longer in range).
///
/// Position, not identity: both editors decode the stored JSON afresh on
/// every read, so the map a row was drawn from is never the same object as
/// the one in the list being written — matching by identity silently
/// appended a duplicate instead of replacing.
List<Map<String, Object?>> upsertScheduleEntry(
  List<Map<String, Object?>> entries,
  Map<String, Object?> entry,
  int? index,
) {
  final next = [...entries];
  if (index != null && index >= 0 && index < next.length) {
    next[index] = entry;
  } else {
    next.add(entry);
  }
  return next;
}

/// The entry in force at [minutesNow]: the latest one at or before it, or —
/// before the day's first entry — the last one, still holding from
/// yesterday. Null only for an empty schedule.
Map<String, Object?>? activeScheduleEntry(
  List<Map<String, Object?>> entries,
  int minutesNow,
) {
  if (entries.isEmpty) return null;
  Map<String, Object?>? current;
  for (final e in entries) {
    if (scheduleMinutes(e['at'] as String)! <= minutesNow) current = e;
  }
  return current ?? entries.last;
}

/// The Night mode decision (issue #391): whether the clock wears its night
/// color, given the last decision.
///
/// Entering at the threshold but leaving only a quarter above it keeps a
/// reading hovering on the line from flickering the color back and forth:
/// the sensor's native damper spaces events out, it does not steady them.
/// A null [lux] is a sensor that has not spoken and has no persisted last
/// reading, which cannot claim the room is dark. The screensaver manager
/// decides once for the clock face, Turn screen off at night (issue #1060)
/// and plugins, so the screen only goes off under a face already wearing
/// its night colors.
bool clockNightActive({
  required bool previous,
  required bool enabled,
  required double? lux,
  required double threshold,
}) {
  if (!enabled || lux == null) return false;
  if (lux <= threshold) return true;
  if (lux > threshold * 1.25) return false;
  return previous;
}

/// Idle tracking and the screensaver itself.
///
/// Modes:
///   dim   — lower brightness to `screensaver.dim_level`
///   black — brightness 0 + a black overlay (rendered by the UI layer, which
///           watches [overlayActive])
///
/// Dimming and restoring go through 'setBrightness'/'screenOn' registry
/// commands so this manager never references the screen manager. The
/// screensaver's black stays brightness zero behind an overlay (the app
/// alive, motion and wake word running); real display power-off happens in
/// two places, the "Turn screen off after" timer and Night mode's "Turn
/// screen off at night", both through [_goDark], and by explicit request —
/// with background listening on, the process (and its camera,
/// carried by the camera-type foreground service) keeps running behind the
/// dark panel, so motion, the ESPHome dismiss and the wake word can all light
/// it back up. The session stays active across the power-off, which is what
/// routes every dismiss source through [stop] and its screenOn.
class ScreensaverManager extends Manager with WidgetsBindingObserver {
  ScreensaverManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    this._screenOffUnit = const Duration(minutes: 1),
    this._pauseProbeDelay = const Duration(seconds: 1),
    double? Function()? lightReading,
    this._nightTurnOffUnit = const Duration(minutes: 1),
  }) : _lightReading = lightReading ?? _noLightReading;

  static double? _noLightReading() => null;

  /// Whether the plugin renderer behind a mode takes taps (issue #1282).
  /// Wired at the composition root, like the settings' plugin lookups.
  bool Function(String mode) pluginTouch = (_) => false;

  final SettingsManager _settings;

  @override
  String get name => 'screensaver';

  Timer? _idleTimer;
  Timer? _scheduleTimer;
  bool _active = false;
  bool _paused = false;
  final _interactions = ActiveInteractions();

  /// "Turn screen off after": armed when a session starts (and re-armed on
  /// a mid-session wake, so a power-button wake that dismisses nothing gets
  /// its own fresh countdown), canceled when the session ends or the panel
  /// goes dark by other hands.
  Timer? _screenOffTimer;

  /// One real minute, injectable for tests only.
  final Duration _screenOffUnit;

  /// The ambient light the clock face reads (DeviceManager's lightLux, null
  /// without a sensor), for Turn screen off at night.
  final double? Function() _lightReading;

  /// Turn screen off at night after (issue #1060): one of its minutes, the
  /// way [_screenOffUnit] is one of Turn screen off after's. The countdown
  /// starts when Night mode does and again after every wake that keeps the
  /// session. Injectable for tests only.
  final Duration _nightTurnOffUnit;
  Timer? _nightTimer;

  /// Night mode's decision, kept between sessions so the band above the
  /// threshold holds. The clock face, its corner widgets and plugins
  /// (screensaver.appearance) all follow this one decision.
  final clockNight = ValueNotifier<bool>(false);

  /// The color a plugin screensaver asked its corner widgets and At a
  /// Glance row to wear (issue #1299), drawn the way Night mode's color is
  /// on the clock. It belongs to the plugin screensaver that was on screen
  /// when the plugin asked and ends once that one leaves the screen, so a
  /// plugin that never clears it cannot tint any other screensaver.
  final pluginTint = ValueNotifier<({String mode, int color})?>(null);

  /// Tints the widgets over [pluginId]'s screensaver. False when none of
  /// that plugin's screensavers is on screen.
  bool setPluginTint(String pluginId, int color) {
    final view = activeView.value;
    if (!defs.isPluginScreensaver(view) || view!.split(':')[1] != pluginId) {
      return false;
    }
    pluginTint.value = (mode: view, color: color);
    return true;
  }

  /// Drops [pluginId]'s tint. Another plugin's stays.
  void clearPluginTint(String pluginId) {
    final tint = pluginTint.value;
    if (tint != null && tint.mode.split(':')[1] == pluginId) {
      pluginTint.value = null;
    }
  }

  /// The dark panel or black screen in this session is Night mode's, so
  /// the room brightening may undo it. A panel turned off by hand or by
  /// Turn screen off after is never Night mode's to light.
  bool _nightDark = false;

  /// Android refused the power-off, which means the Device admin grant is
  /// missing. Asking again every countdown would only fill the log, so
  /// the night waits for a settings change or the next session.
  bool _nightRefused = false;

  bool get _nightBlack => _settings.get(defs.screensaverClockNightTurnOffBlack);

  /// Something is using the screen: the countdown starts over instead of
  /// cutting it off.
  bool get _nightHeld =>
      _paused ||
      _voiceTurn ||
      _assistOverlay ||
      _behindAnotherApp ||
      _nowPlayingTakeover ||
      alarmTakeover.value != null;

  /// Bring Night mode's decision up to date and act on it: count down to
  /// a dark screen while the room is dark under the Clock screensaver, and
  /// light the clock again once it is not.
  void _reviewNight() {
    clockNight.value = clockNightActive(
      previous: clockNight.value,
      enabled: _settings.get(defs.screensaverClockNight),
      lux: _lightReading(),
      threshold: _settings.get(defs.screensaverClockNightLux).toDouble(),
    );
    final minutes = _settings.get(defs.screensaverClockNightTurnOffMinutes);
    final wanted =
        _active && clockNight.value && _effectiveMode == 'clock' && minutes > 0;
    if (!wanted) {
      _nightTimer?.cancel();
      _nightTimer = null;
      if (_nightDark) {
        _nightDark = false;
        log.info(name, 'Night mode over; lighting the screen');
        if (_blanked) {
          unawaited(_wakeFromBlank());
        } else if (_panelDark) {
          unawaited(commands.execute('screenOn', const {}));
        }
      }
      return;
    }
    if (_screenDark || _nightTimer != null) return;
    if (_nightRefused && !_nightBlack) return;
    _nightTimer = Timer(_nightTurnOffUnit * minutes, () {
      _nightTimer = null;
      unawaited(_turnOffForNight());
    });
  }

  Future<void> _turnOffForNight() async {
    if (!_active || _screenDark) return;
    if (_nightHeld) {
      _reviewNight();
      return;
    }
    _screenOffTimer?.cancel();
    _screenOffTimer = null;
    final ok = await _goDark(black: _nightBlack, why: 'Night mode');
    if (!ok) {
      _nightRefused = true;
      return;
    }
    // A dismissal while Android was powering off already ran stop(), whose
    // screenOn came too early to count: the dashboard must not stay dark.
    if (!_active) {
      await commands.execute('screenOn', const {});
      return;
    }
    _nightDark = true;
  }

  /// The minutes the running countdown was armed with, so a schedule
  /// boundary or a slider move re-arms only when the effective value
  /// actually changed: a notification lifting the brightness or music
  /// starting under the screensaver reapplies the visuals too, and neither
  /// is a reason to restart the clock. Null between sessions.
  int? _armedScreenOffMinutes;

  /// The panel went dark under the session (the timer's own power-off or
  /// anyone else's). Nothing is counted down while it is, whatever the
  /// schedule crosses into: a second lockNow on a dark panel does nothing
  /// useful, and the wake paths re-arm on their own.
  bool _panelDark = false;

  // The timeout can cover the app without powering off the physical panel.
  bool _blanked = false;
  bool get _screenDark => _panelDark || _blanked;

  Future<void> _wakeFromBlank() async {
    _blanked = false;
    _nightDark = false;
    _armScreenOffTimer();
    await _applyVisuals();
  }

  /// Another app is in front of the kiosk (an app from the launcher, a
  /// gesture or Home Assistant, Home pressed without kiosk mode). The
  /// screensaver stands down entirely: brightness is the device's, so a
  /// dim under someone using Chrome dims Chrome, and Turn screen off
  /// after would power the panel off under them. Set by the pause probe,
  /// cleared on resume.
  bool _behindAnotherApp = false;
  bool _lifecyclePaused = false;

  /// A dark panel pauses the Activity exactly like an escape does, and
  /// the screen-off broadcast may land after the pause; the probe waits
  /// this long and then asks isScreenOn, the same trick the kiosk
  /// manager's reclaim uses (issue #291). Injectable for tests only.
  Timer? _pauseProbe;
  final Duration _pauseProbeDelay;

  /// The `at` of the schedule entry the current visuals were applied under,
  /// so the periodic tick only reapplies on an actual boundary crossing.
  String? _appliedScheduleAt;

  /// A voice turn is in progress (wake word fired, page not yet resumed). The
  /// idle timer is held the whole time, so the screensaver cannot return while
  /// the user is mid-interaction.
  bool _voiceTurn = false;
  bool _restoreNowPlaying = false;

  /// A launch on play that a voice turn or page interaction refused. Music
  /// asked for by voice starts mid-turn, so the launch waits for the turn
  /// to end instead of being dropped (issue #718).
  bool _launchOnPlayPending = false;

  /// The session exists only to show Now Playing: playback launched it or
  /// something asked for the view itself. It ends with the view (issue
  /// #774). A session the idle clock or a plain start opened keeps going
  /// in the configured mode instead.
  bool _startedForNowPlaying = false;

  /// The session opens Now Playing because someone asked for it: the
  /// Menu, the floating player, Compass or the command. It opens like any
  /// other view, so holds that only keep the screensaver from starting by
  /// itself do not apply to it, nor does Hold Mode.
  bool _openedByHand = false;
  bool _restoreForNowPlaying = false;
  Future<void>? _interactionStop;
  bool _cameraViewActive = false;

  /// Native Voice Satellite's overlay is on screen. It draws over the
  /// screensaver, which stays up underneath: its backlight lifted back to
  /// the saved level, its rendering paused and its screen-off countdown
  /// held until the overlay goes (an answer or results can linger after
  /// the turn itself ends). The integration's engine lives in the
  /// dashboard, so there a turn still dismisses the screensaver.
  bool _assistOverlay = false;

  /// The screensaver's animations are paused under the voice overlay.
  final renderPaused = ValueNotifier<bool>(false);

  /// Views that cost next to nothing to draw, left live around the docked
  /// overlay. The Home Assistant Dashboard and Dim views are clear layers
  /// over the dashboard, which pauses on its own.
  static const _cheapUnderDock = {null, 'black', 'clock', 'dashboard', 'dim'};

  bool get _nativeVoice =>
      _settings.get(defs.voiceRuntime) == 'native' &&
      _settings.get(defs.voiceEnabled);
  double? _savedBrightness;

  /// Whether a notification is on screen. A dimmed screensaver lifts back
  /// to the brightness it saved while one is up: a message nobody can read
  /// is not a message (issue #278).
  bool _notificationShowing = false;

  /// Lifted for a touch the screensaver kept, until [_touchLiftTimer]
  /// runs out, Brighten for touch interactions seconds after the last one.
  bool _touchLifted = false;
  Timer? _touchLiftTimer;

  /// The visual overlay the UI should render, or null for none.
  ///
  /// One of 'blank' | 'black' | 'clock' | 'media' | 'website' | ... Dim
  /// only lowers the backlight, so this stays null there, unless a shared
  /// Now Playing panel needs a slot: then it is 'dim', a bare clear layer.
  /// 'dashboard' is a clear layer over the dashboard itself, there to take
  /// the tap that dismisses it and to carry the widgets.
  final ValueNotifier<String?> activeView = ValueNotifier(null);

  /// The view the Home Assistant Dashboard mode put on the page this
  /// session, so the dismissal takes it back and a reapply that changes
  /// nothing (a notification, a schedule tick) does not navigate again.
  String? _dashboardShown;

  /// Whether the Home Assistant Dashboard mode has the page on screen, for
  /// the kiosk screen to swap in the mode's own header and sidebar choice
  /// (issue #1183). Cleared once the dismissal has moved the page back.
  final ValueNotifier<bool> dashboardShowing = ValueNotifier(false);

  bool get isActive => _active;

  /// Whether the Sendspin now-playing display is active (a track loaded),
  /// mirrored from its bus event for the motion-dismiss policy above.
  bool _sendspinNowPlaying = false;

  /// Whether Sendspin playback is running, for the launch-on-play edge.
  bool _sendspinPlaying = false;

  /// The double-tap dismiss chain (discussion #248). One physical tap
  /// reports here twice: the kiosk screen's raw pointer Listener
  /// ('touch') on the way down, then either the screensaver WebView's JS
  /// bridge ('touch_page') or the view's own gesture detector ('tap') as
  /// the finger lifts. Timing cannot tell that echo from a genuinely fast
  /// double tap (a finger held past the debounce lifts inside the
  /// window), so only the Listener's reports count for the chain and the
  /// echoes are dropped while the gate holds. Reports faster than
  /// [_tapDebounce] after the chain opened are the other fingers of one
  /// gesture (a pinch), not a second tap.
  DateTime? _tapChainStart;
  static const _tapDebounce = Duration(milliseconds: 120);
  static const _doubleTapWindow = Duration(milliseconds: 400);

  /// Wall clock for dismissal timing and schedule boundaries.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  /// The rendered layout reports this because small screens can fall back
  /// to the standalone player even when the shared-layout setting is on.
  bool _nowPlayingShared = false;
  bool get nowPlayingShared => _nowPlayingShared && _nowPlayingTakeover;

  /// The edges the shared Now Playing panel covers, as the layout last
  /// reported them.
  EdgeInsets _nowPlayingPanel = EdgeInsets.zero;

  /// The room the shared Now Playing panel takes from the page beside it
  /// under the Home Assistant Dashboard and Dim modes, for the kiosk
  /// screen to keep the dashboard clear of (issue #1268): the page lays
  /// itself out in what is left instead of under the panel. Zero
  /// otherwise.
  final pageReserve = ValueNotifier<EdgeInsets>(EdgeInsets.zero);

  void _syncPageReserve() {
    final view = activeView.value;
    pageReserve.value =
        _active && nowPlayingShared && (view == 'dashboard' || view == 'dim')
        ? _nowPlayingPanel
        : EdgeInsets.zero;
  }

  bool get _nowPlayingNormalBrightness =>
      _nowPlayingTakeover &&
      (!nowPlayingShared ||
          _settings.get(defs.sendspinFullscreenOverrideBrightness));

  void setNowPlayingShared(bool shared, {EdgeInsets panel = EdgeInsets.zero}) {
    if (!_active) return;
    if (_nowPlayingShared == shared) {
      // A rotation moves the panel without changing the layout.
      if (panel != _nowPlayingPanel) {
        _nowPlayingPanel = panel;
        unawaited(Future<void>.microtask(_syncPageReserve));
      }
      return;
    }
    _nowPlayingPanel = panel;
    _nowPlayingShared = shared;
    _tapChainStart = null;
    // Layout reports during build. Apply brightness after that frame's
    // synchronous work so view notifications cannot rebuild its ancestors.
    unawaited(
      Future<void>.microtask(() async {
        _syncNowPlayingCovers();
        if (_active) await _applyVisuals();
      }),
    );
  }

  /// Whether dismissal currently takes two taps: the website and Home
  /// Assistant Dashboard screensavers offer the option (their pages are
  /// the only things a single tap could talk to, discussion #1069), a
  /// plugin renderer published with touch always takes it (issue #1282),
  /// and never while the Sendspin now-playing view has taken the slot
  /// over. That view is ours, not a page.
  bool get _doubleTapToDismiss =>
      (!_nowPlayingTakeover &&
          switch (activeView.value) {
            'website' => _settings.get(defs.screensaverWebsiteDoubleTap),
            'dashboard' => _settings.get(defs.screensaverDashboardDoubleTap),
            final mode? when defs.isPluginScreensaver(mode) => pluginTouch(
              mode,
            ),
            _ => false,
          }) ||
      (_nowPlayingHoldsTouch &&
          !nowPlayingShared &&
          _settings.get(defs.sendspinFullscreenDoubleTap));

  /// When a touch last landed on a timer pill or a Now Playing control,
  /// the transport, the toggles or a queue row. The view reports it from
  /// the pointer's way down, ahead of the kiosk screen's own report of
  /// the same touch, so the double-tap chain can leave that touch alone:
  /// a quick double press on Next must skip twice, not close the view.
  DateTime? _controlTouchAt;

  void markControlTouch() => _controlTouchAt = clock();

  /// Set while the Celestial screensaver follows the device held up to the
  /// sky: someone moving the tablet around would otherwise read as motion,
  /// a face or something close, and close it. Cleared on stop.
  bool holdSensorDismiss = false;

  bool get _touchOnControl => _within(_controlTouchAt);

  /// When a touch last landed on a slideshow's edge zone (issue #453):
  /// the outer fifth of either side steps the deck instead of waking. The
  /// zone reports from the pointer's way down, ahead of the kiosk screen's
  /// own report of the same touch, which [notifyActivity] then drops
  /// rather than dismissing. The zone sits over the mode's own tap-to-wake
  /// wrapper, so no other echo of that touch arrives.
  DateTime? _slideTouchAt;

  void markSlideTouch() => _slideTouchAt = clock();

  bool get _touchOnSlideEdge => _within(_slideTouchAt);

  bool _within(DateTime? at) =>
      at != null && clock().difference(at) < const Duration(milliseconds: 150);

  @override
  Future<void> init() async {
    await _migrateMiniClock24h();
    await _migrateMiniClockWidget();
    await _migrateCameraView();
    if (Platform.isAndroid) WidgetsBinding.instance.addObserver(this);
    bus.on<ActivityDetected>().listen((e) => notifyActivity(e.source));
    // Stand down while a page interaction runs (voice turn, ringing timer
    // alert, media playback), whichever API the page signalled it through:
    // setInteractionActive, or the legacy pauseScreensaver fallback.
    bus.on<VoiceInteractionChanged>().listen((e) {
      // Local music can play behind any screensaver. Other managers can
      // still observe its playback interaction.
      if (e.source == InteractionSource.sendspin && e.reason == 'media') return;
      _paused = _interactions.update(e);
      // The native satellite's overlay draws over the screensaver, full
      // screen or docked.
      if (_paused &&
          e.source != InteractionSource.native &&
          !(_openedByHand && !_interactions.needsScreen)) {
        _stopForInteraction();
      }
      _resetIdleTimer();
      if (!_paused) unawaited(_restoreAfterInteraction());
    });
    // An alarm on the screensaver puts Now Playing behind it.
    alarmTakeover.addListener(_syncNowPlayingCovers);
    bus.on<AssistOverlayVisibility>().listen((event) {
      // Paused under the full screen overlay, and docked when it is one
      // that costs: a still of Weather Mood or a slideshow shows around
      // the bubble as well as the live one, and a clock keeps ticking.
      renderPaused.value =
          _active &&
          (event.covers ||
              (event.pauses && !_cheapUnderDock.contains(activeView.value)));
      if (event.visible == _assistOverlay) return;
      _assistOverlay = event.visible;
      if (event.visible) {
        _cancelIdleTimer();
        if (_active) {
          _screenOffTimer?.cancel();
          _screenOffTimer = null;
          _armedScreenOffMinutes = null;
          unawaited(_applyVisuals());
        }
      } else if (_active) {
        if (!_screenDark) _armScreenOffTimer();
        unawaited(_applyVisuals());
      } else {
        _resetIdleTimer();
      }
    });
    bus.on<CameraViewStateChanged>().listen((event) {
      _cameraViewActive = event.active;
      if (event.active) {
        unawaited(stop());
        _cancelIdleTimer();
      } else {
        _resetIdleTimer();
      }
    });
    // A wake word starts a voice turn: wake the screen, then hold the idle
    // timer until the turn actually finishes. Arming it here — as a touch would
    // — is wrong: the countdown would run through the user speaking and the
    // spoken reply, and the screensaver could reappear mid-conversation.
    bus.on<WakeWordDetected>().listen((_) {
      _voiceTurn = true;
      if (_active && !_nativeVoice) {
        log.debug(name, 'dismissed by wake word');
        _stopForInteraction();
      }
      _cancelIdleTimer();
    });
    // The page resuming wake detection (active again) is the end of the turn —
    // only now does the idle countdown begin. A stuck turn is covered by the
    // wake manager's own resume timeout, which resumes and lands us here too.
    bus.on<WakeWordStateChanged>().listen((e) {
      if (e.active && _voiceTurn) {
        _voiceTurn = false;
        _resetIdleTimer();
        unawaited(_restoreAfterInteraction());
      }
    });
    // The panel changing state under an active session: a power-off — ours
    // or anyone's — leaves nothing to count down for, and a wake depends on
    // whose hand it was. A person at the panel (power button, double-tap-
    // to-wake: source system) is activity like a touch, so they land on
    // the dashboard rather than the screensaver — except under lockdown,
    // which keeps its screen locked here exactly like it does for motion,
    // and with Power button picked under Wake to screensaver, which brings
    // the screensaver back for these wakes the same as for a detection
    // (issue #952). Android
    // never tells an app which key or gesture woke the panel, so every
    // wake the app did not ask for counts here. The one exception is the
    // Portal's presence service turning the screen on for someone it sees,
    // which the person sensor reads out of the log and which follows
    // Person instead (issue #1092).
    // The app's own pokes (source app) are either part of a dismiss that
    // is already running or an automation switching the panel on to show
    // the screensaver (a photo frame's morning switch-on), so those keep
    // the session and just start a fresh screen-off countdown.
    bus.on<ScreenStateChanged>().listen((e) async {
      final byHand =
          e.on && e.source == 'system' && !_settings.get(defs.lockdownEnabled);
      if (!_active) {
        // No session up, so nothing to dismiss, but a person waking a
        // panel the OS had timed out is using the dashboard: the idle
        // clock starts over from the wake, not from their last touch
        // (issue #348).
        if (byHand) _resetIdleTimer();
        return;
      }
      if (!e.on) {
        _panelDark = true;
        _screenOffTimer?.cancel();
        _screenOffTimer = null;
        return;
      }
      _panelDark = false;
      // Any wake that keeps the session gives the clock a fresh countdown
      // before Night mode takes the screen off again.
      _nightDark = false;
      if (byHand && !_wakesToScreensaver('power')) {
        // The Portal's presence service turns the screen on by itself when
        // it sees someone (issue #1092): that wake follows Person.
        final source = await _systemWakeSource();
        if (source == null || !_wakesToScreensaver(source)) {
          notifyActivity('screen on');
          return;
        }
        // Gone dark or ended while the source was looked up.
        if (!_active || _panelDark) return;
        log.info(name, 'woken by $source; screen on, screensaver stays');
      } else if (byHand) {
        log.info(name, 'woken by the device; screensaver stays');
      }
      if (_blanked) {
        unawaited(_wakeFromBlank());
      } else {
        _armScreenOffTimer();
        _reviewNight();
      }
    });
    // The room getting darker or lighter is what Turn screen off at night
    // answers to, session or not: between sessions it only keeps the
    // decision in step with the face's.
    bus.on<LightLevelChanged>().listen((_) => _reviewNight());
    // The last known reading stands until the sensor speaks, so the face
    // starts in the colors it left off in.
    _reviewNight();
    bus.on<NotificationsChanged>().listen((e) {
      unawaited(_onNotificationsChanged(e.showing));
    });
    // The player handed back after an alarm's music: Now Playing may show
    // again if the player it follows plays.
    bus.on<SettingChanged>().listen((e) {
      if (e.key != defs.sendspinHandoff.key || !_active) return;
      _syncNowPlayingShown();
      unawaited(_applyVisuals());
    });
    bus.on<SendspinNowPlayingChanged>().listen((e) {
      final startedPlaying = e.playing && !_sendspinPlaying;
      _sendspinPlaying = e.playing;
      if (!e.playing) _launchOnPlayPending = false;
      final changed = _sendspinNowPlaying != e.active;
      _sendspinNowPlaying = e.active;
      _syncNowPlayingShown();
      // Mid-session flip: music started (dim gives way to Now Playing at
      // full brightness) or stopped (the configured mode re-asserts). A
      // session that only existed for the view ends with it instead, back
      // to the dashboard.
      if (_active) {
        if (changed && !e.active && _startedForNowPlaying) {
          log.info(name, 'Now Playing ended; ending its session');
          unawaited(stop().then((_) => _resetIdleTimer()));
          return;
        }
        if (changed) unawaited(_applyVisuals());
        return;
      }
      // Launch on play (sendspin.fullscreen_on_play): playback starting
      // is the cue for the music display, not the idle clock. start()
      // keeps every refusal it has for a timed start (hold mode, a
      // voice turn, another app in front, lockdown). A voice turn or page
      // interaction only defers it: the launch runs once they end.
      if (startedPlaying &&
          !_alarmOnTop &&
          allowsNowPlaying &&
          _settings.get(defs.sendspinFullscreen) &&
          _settings.get(defs.sendspinFullscreenOnPlay)) {
        log.info(name, 'Now Playing launched by playback');
        _launchOnPlayPending = _paused || _voiceTurn;
        unawaited(start(forNowPlaying: true));
      }
    });
    // The camera's motion, unless a Home Assistant entity stands in for
    // it (issue #973). The camera still ticks for the Motion sensor entity
    // then, and that is not the screensaver's motion.
    bus.on<MotionDetected>().listen((_) {
      if (_settings.get(defs.motionUseEntity)) return;
      _onMotion();
    });
    bus.on<ExternalMotionDetected>().listen((e) {
      if (!_settings.get(defs.motionUseEntity)) return;
      _onMotion(held: e.held);
    });
    bus.on<FaceDetected>().listen((_) {
      // Same lockdown rule as motion.
      if (_settings.get(defs.lockdownEnabled)) return;
      if (!_active) {
        // Between screensavers a face can only postpone the next one,
        // under Postpone on motion's rules: the postpone switch extends
        // Dismiss on face and never acts on its own, and Dismiss on
        // motion keeps precedence over both face legs.
        if (_settings.get(defs.screensaverPostponeOnFace) &&
            _settings.get(defs.screensaverDismissOnFace) &&
            !_settings.get(defs.screensaverDismissOnMotion)) {
          _resetIdleTimer();
        }
        return;
      }
      if (!_screenDark &&
          _settings.get(defs.screensaverDismissOnFaceScreenOffOnly)) {
        return;
      }
      // Dismiss on motion (or its schedule override) takes precedence:
      // the native side does not look for faces while motion is on, and
      // this double-gate keeps a stale tick from acting either way.
      if (_motionPolicy ?? _settings.get(defs.screensaverDismissOnMotion)) {
        return;
      }
      if (!(_facePolicy ?? _settings.get(defs.screensaverDismissOnFace))) {
        return;
      }
      // Now Playing keeps its own policy; a face counts like motion there.
      final showingNowPlaying = activeView.value != null && _nowPlayingTakeover;
      if (showingNowPlaying &&
          !nowPlayingShared &&
          !_settings.get(defs.sendspinFullscreenMotion)) {
        return;
      }
      // A wake to the screensaver dismisses nothing, so no camera preview.
      if (_wakeToScreensaver('face')) return;
      // Before the stop, so the camera preview's hold (MotionManager) is
      // armed by the time the session's end reaches it.
      bus.publish(const FaceDismissedScreensaver());
      notifyActivity('face');
    });
    bus.on<PersonDetected>().listen((e) {
      // The device's own person sensor (discussion #353), under
      // Proximity's rules: lockdown holds, the postpone switch extends
      // Dismiss on person and never acts on its own, and the sensor
      // repeats while someone stays so the postpone leg keeps the
      // screensaver off.
      if (_settings.get(defs.lockdownEnabled)) return;
      if (!_active) {
        if (_settings.get(defs.screensaverPostponeOnPerson) &&
            _settings.get(defs.screensaverDismissOnPerson)) {
          _resetIdleTimer();
        }
        return;
      }
      if (!_screenDark &&
          _settings.get(defs.screensaverDismissOnPersonScreenOffOnly)) {
        return;
      }
      // The active schedule entry's override (issue #437) wins over the
      // switch, as the motion override does.
      if (!(_personPolicy ?? _settings.get(defs.screensaverDismissOnPerson))) {
        return;
      }
      // Dismiss acts on someone arriving. A held signal is someone who
      // was already there when the screensaver started: with Postpone off
      // that screensaver is wanted, and re-dismissing it on every
      // heartbeat made a start-and-dismiss loop (issue #369).
      if (e.held) return;
      // Now Playing keeps its own policy; someone there counts like
      // motion there.
      final showingNowPlaying = activeView.value != null && _nowPlayingTakeover;
      if (showingNowPlaying &&
          !nowPlayingShared &&
          !_settings.get(defs.sendspinFullscreenMotion)) {
        return;
      }
      if (_wakeToScreensaver('person')) return;
      notifyActivity('person');
    });
    bus.on<ProximityDetected>().listen((e) {
      // Same lockdown rule as motion.
      if (_settings.get(defs.lockdownEnabled)) return;
      if (!_active) {
        // Between screensavers, proximity can only postpone the next one,
        // under Postpone on motion's rules: the postpone switch extends
        // Dismiss on proximity and never acts on its own.
        if (_settings.get(defs.screensaverPostponeOnProximity) &&
            _settings.get(defs.screensaverDismissOnProximity)) {
          _resetIdleTimer();
        }
        return;
      }
      if (!_screenDark &&
          _settings.get(defs.screensaverDismissOnProximityScreenOffOnly)) {
        return;
      }
      // The active schedule entry's override (issue #437) wins over the
      // switch, as the motion override does.
      if (!(_proximityPolicy ??
          _settings.get(defs.screensaverDismissOnProximity))) {
        return;
      }
      // The approach dismisses; something still close when the screensaver
      // starts does not (issue #369, the same rule as the person sensor).
      if (e.held) return;
      // Now Playing keeps its own policy; something coming close counts
      // like motion there.
      final showingNowPlaying = activeView.value != null && _nowPlayingTakeover;
      if (showingNowPlaying &&
          !nowPlayingShared &&
          !_settings.get(defs.sendspinFullscreenMotion)) {
        return;
      }
      if (_wakeToScreensaver('proximity')) return;
      notifyActivity('proximity');
    });
    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.screensaverClockNight.key ||
          e.key == defs.screensaverClockNightLux.key ||
          e.key == defs.screensaverClockNightTurnOffMinutes.key ||
          e.key == defs.screensaverClockNightTurnOffBlack.key) {
        // A changed setting is also the moment to try a refused power-off
        // again: the grant may have come with it. A moved slider counts
        // its new time from now.
        _nightRefused = false;
        if (e.key == defs.screensaverClockNightTurnOffMinutes.key) {
          _nightTimer?.cancel();
          _nightTimer = null;
        }
        _reviewNight();
      }
      // The saved brightness is the session's own bookkeeping, written
      // as it starts and stops: re-arming on it put a due moment on the
      // wire in the middle of every start (issue #406).
      if (e.key.startsWith('screensaver.') &&
          e.key != defs.screensaverSavedBrightness.key) {
        _resetIdleTimer();
      }
      // An old backup import re-arms the legacy small clock switch; its
      // sub-keys land in the same batch, so fold them into a widget only
      // after the batch has settled (the importing flag holds for 1s).
      if (e.key == defs.screensaverMiniClock.key && e.value == true) {
        unawaited(
          Future<void>.delayed(
            const Duration(seconds: 2),
            _migrateMiniClockWidget,
          ),
        );
      }
      // Likewise the single camera view of a backup taken before the
      // Camera Streams mode rotated: folded into the view list once the
      // batch has settled.
      if (e.key == defs.screensaverCameraView.key &&
          e.value is String &&
          (e.value as String).isNotEmpty) {
        unawaited(
          Future<void>.delayed(const Duration(seconds: 2), _migrateCameraView),
        );
      }
      // Disabling the master toggle takes a running screensaver down with
      // it. On the device this never shows (opening settings already
      // dismisses it), but over ESPHome or the remote admin nothing else
      // would, and the screensaver stayed up with no timer (issue #152).
      if (e.key == defs.screensaverEnabled.key && e.value == false) {
        unawaited(stop());
      }
      // Lockdown Mode owns the display while it holds: a running
      // screensaver stops, and start() refuses below until it lifts —
      // unless the owner opted in to letting it run under the shield.
      if (e.key == defs.lockdownEnabled.key) {
        if (e.value == true && !_settings.get(defs.lockdownAllowScreensaver)) {
          unawaited(stop());
          _cancelIdleTimer();
        } else {
          _resetIdleTimer();
        }
      }
      // Flipping the opt-in while locked applies immediately, both ways.
      if (e.key == defs.lockdownAllowScreensaver.key &&
          _settings.get(defs.lockdownEnabled)) {
        if (e.value == true) {
          _resetIdleTimer();
        } else {
          unawaited(stop());
          _cancelIdleTimer();
        }
      }
      // Hold mode pins whatever is on screen right now (issue #266): a
      // showing screensaver is never what the user meant to pin, so
      // engaging hold dismisses it and stops the idle clock; releasing
      // the hold puts the clock back. Now Playing opened by hand is a view
      // like any other, so hold pins it instead.
      if (e.key == defs.haHoldMode.key) {
        if (e.value == true) {
          if (!_openedByHand) unawaited(stop());
          _cancelIdleTimer();
        } else {
          _resetIdleTimer();
        }
      }
      // Moving the screen-off slider under a running session applies to it:
      // the countdown restarts at the new value (or stops at 0), unless the
      // active schedule entry carries its own, which the slider never
      // reaches.
      if (_active && e.key == defs.screensaverScreenOffMinutes.key) {
        _syncScreenOffTimer();
      }
      if (_active &&
          e.key == defs.screensaverScreenOffBlack.key &&
          e.value == false &&
          _blanked) {
        unawaited(_wakeFromBlank());
      }
      // Moving the screensaver-brightness controls while the screensaver is
      // showing applies immediately: the slider doubles as a live preview.
      if (_active &&
          (e.key == defs.screensaverBrightnessEnabled.key ||
              e.key == defs.screensaverBrightnessLevel.key)) {
        unawaited(_onBrightnessSettingChanged());
      }
      if (nowPlayingShared &&
          e.key == defs.sendspinFullscreenOverrideBrightness.key) {
        unawaited(_applyVisuals());
      }
      // Editing the schedule while the screensaver shows applies right
      // away, same as the brightness slider: the editor doubles as a
      // live preview.
      if (_active &&
          (e.key == defs.screensaverSchedule.key ||
              e.key == defs.screensaverScheduleEnabled.key ||
              e.key == defs.screensaverMode.key ||
              e.key == defs.screensaverDashboardView.key)) {
        unawaited(_applyVisuals());
      }
    });
    // The schedule's clock: cheap check on a short period so a boundary
    // lands within seconds of the set time, reapplying only on a change.
    _scheduleTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _scheduleTick(),
    );

    // A process death mid-screensaver loses the in-memory restore point; the
    // persisted copy keeps the dim level from becoming the new normal. Runs
    // before any screensaver can start, so a pending value is always stale.
    final orphaned = _settings.get(defs.screensaverSavedBrightness).toDouble();
    if (orphaned >= 0) {
      log.info(name, 'restoring brightness after an interrupted screensaver');
      await commands.execute('setBrightness', {
        'level': orphaned,
        'ceiling': true,
      });
      await _settings.set(defs.screensaverSavedBrightness, -1);
    }

    commands
      ..register(
        Command(
          name: 'alarmTakeover',
          description:
              'An alarm shows on this screensaver: phase sunrise or ringing '
              'starts it past every idle gate and keeps the panel lit; null '
              'lets go and leaves the screensaver as it is. Fails when the '
              'screensaver could not start.',
          params: const {'phase': 'sunrise, ringing or null'},
          handler: (p) async {
            final phase = p['phase'] as String?;
            if (phase == null) {
              if (alarmTakeover.value == null) return const CommandResult.ok();
              alarmTakeover.value = null;
              if (_active) {
                _armScreenOffTimer();
                // Back down to the screensaver's own level.
                await _applyVisuals();
              }
              return const CommandResult.ok();
            }
            return await _takeOverForAlarm(phase)
                ? const CommandResult.ok()
                : const CommandResult.fail('the screensaver did not start');
          },
        ),
      )
      ..register(
        Command(
          name: 'startScreensaver',
          description:
              'Start the screensaver now. nowPlaying: true marks a session '
              'opened for the Now Playing view, which ends with the view. '
              'It opens like any other view: a page playing media, a '
              'pauseScreensaver hold and Hold Mode do not stop it.',
          handler: (params) async {
            final nowPlaying = params['nowPlaying'] == true;
            await start(forNowPlaying: nowPlaying, byHand: nowPlaying);
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'stopScreensaver',
          description: 'Dismiss the screensaver (one-shot)',
          handler: (_) async {
            await stop();
            // The dismiss must light a dark panel even when nothing was up
            // to dismiss (stop() pokes it only when a session ended): the
            // button's job is "bring the dashboard back", and half of that
            // is the screen. A no-op on a lit panel.
            await commands.execute('screenOn', const {});
            _resetIdleTimer();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'postponeScreensaver',
          description:
              'Reset the screensaver idle timer, dismissing the screensaver '
              'first if it is showing — external activity (issue #129)',
          handler: (_) async {
            notifyActivity('remote');
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'nextScreensaverSlide',
          description:
              'Show the next slide of a running slideshow screensaver '
              '(Home Assistant Media, Local Media, Photo Gallery, Immich '
              'Media), or the next view of a Camera Streams rotation; a '
              'no-op for every other mode. Returns whether there was '
              'anything to step',
          handler: (_) async => CommandResult.ok(await stepSlide(1)),
        ),
      )
      ..register(
        Command(
          name: 'previousScreensaverSlide',
          description:
              'Show the previous slide of a running slideshow screensaver, '
              'or the previous view of a Camera Streams rotation; a no-op '
              'for every other mode. Returns whether there was anything '
              'to step',
          handler: (_) async => CommandResult.ok(await stepSlide(-1)),
        ),
      )
      ..register(
        Command(
          name: 'pauseScreensaver',
          description: 'Suppress (paused=true) or release the screensaver',
          params: const {'paused': 'true to suppress, false to release'},
          handler: (p) async {
            // Older Voice Satellite versions bracket every interaction with
            // this screensaver call; newer ones use setInteractionActive. Both
            // funnel into the same app-wide event, and THIS manager pauses via
            // its listener on that event like every other ambient feature —
            // the screensaver is a consumer of the interaction signal, not
            // its owner.
            bus.publish(VoiceInteractionChanged(active: p['paused'] == true));
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'holdScreensaver',
          description:
              'Keep the screensaver from starting on its idle timer while a '
              'screen is up, by holder name. Releasing restarts the '
              'countdown.',
          params: const {
            'holder': 'who holds it',
            'held': 'true to hold, false to let go',
          },
          handler: (p) async {
            final holder = '${p['holder'] ?? ''}';
            if (holder.isEmpty) {
              return const CommandResult.fail('holder is required');
            }
            p['held'] == true ? _holders.add(holder) : _holders.remove(holder);
            _resetIdleTimer();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'isScreensaverActive',
          description: 'Whether the screensaver is showing right now',
          quiet: true,
          handler: (_) async => CommandResult.ok(_active),
        ),
      )
      ..register(
        Command(
          name: 'getScreensaverDue',
          description:
              'When the idle clock will start the screensaver, ISO 8601 UTC, '
              'or null while nothing is counting down',
          quiet: true,
          handler: (_) async =>
              CommandResult.ok(_idleDue?.toUtc().toIso8601String()),
        ),
      )
      ..register(
        Command(
          name: 'getScreensaverSuppressed',
          description:
              'Whether the page should stand down its own screensaver. '
              'Always true: this app owns the screen, so two screensavers '
              'fighting over it is never the right outcome.',
          handler: (_) async => const CommandResult.ok(true),
        ),
      );

    _resetIdleTimer();
  }

  /// A slideshow view swapped to its next slide: the room is about to be
  /// relit by the app's own display (see [ScreensaverSlideChanged]).
  void notifySlideChanged() => bus.publish(const ScreensaverSlideChanged());

  /// Motion from the camera, or from the Home Assistant entity in its
  /// place (issue #973). [held] is the entity still on: it postpones like
  /// any motion but never dismisses, the person sensor's rule (issue
  /// #369), since a screensaver that started with the sensor on is wanted.
  void _onMotion({bool held = false}) {
    // Under lockdown the screen must stay locked: motion neither
    // dismisses a screensaver running under the opt-in nor postpones
    // the next one. The mode lifting brings normal behavior back.
    if (_settings.get(defs.lockdownEnabled)) return;
    if (!_active) {
      // Between screensavers, motion can only postpone the next one
      // (discussion #126): people moving in front of the device keep
      // resetting the idle clock, exactly like a touch would. Gated on
      // Dismiss on motion too — the postpone switch extends it and must
      // never act on its own (a stale true would otherwise act from
      // under a hidden row).
      if (_settings.get(defs.screensaverPostponeOnMotion) &&
          _settings.get(defs.screensaverDismissOnMotion)) {
        _resetIdleTimer();
      }
      return;
    }
    if (!_screenDark &&
        _settings.get(defs.screensaverDismissOnMotionScreenOffOnly)) {
      return;
    }
    // The active schedule entry's motion override (issue #89) wins over
    // the switch, matching the camera's own gating in MotionManager.
    if (!(_motionPolicy ?? _settings.get(defs.screensaverDismissOnMotion))) {
      return;
    }
    if (held) return;
    // The full-screen now-playing view has its own motion policy: it is
    // a music display, and someone walking past should not interrupt it
    // unless explicitly asked to (sendspin.fullscreen_motion).
    final showingNowPlaying = activeView.value != null && _nowPlayingTakeover;
    if (showingNowPlaying &&
        !nowPlayingShared &&
        !_settings.get(defs.sendspinFullscreenMotion)) {
      return;
    }
    if (_wakeToScreensaver('motion')) return;
    notifyActivity('motion');
  }

  /// What turned the screen on, for a wake the app did not ask for, when
  /// the device can say: 'person' for the Portal's presence service.
  /// Composition-root wiring to the person sensor, null without one.
  Future<String?> Function()? systemWakeSource;

  Future<String?> _systemWakeSource() async {
    final lookup = systemWakeSource;
    if (lookup == null || !_wakesToScreensaver('person')) return null;
    return lookup();
  }

  /// Whether [source] is picked under Wake to screensaver.
  bool _wakesToScreensaver(String source) => defs
      .decodeWakeToScreensaver(
        _settings.get(defs.screensaverScreenOffWakeToScreensaver),
      )
      .contains(source);

  /// "Wake to screensaver": a detection under a dark panel powers the
  /// screen back on and nothing more. The app's own wake reaches the
  /// ScreenStateChanged listener as source app, which keeps the session
  /// and arms a fresh screen-off countdown, the same path the ESPHome
  /// Screen light takes. Returns whether it took the event; a lit panel
  /// or a source not picked leaves the dismiss to the caller.
  bool _wakeToScreensaver(String source) {
    if (!_screenDark || !_wakesToScreensaver(source)) return false;
    log.info(name, 'woken by $source; screen on, screensaver stays');
    if (_blanked && !_panelDark) {
      unawaited(_wakeFromBlank());
    } else {
      unawaited(commands.execute('screenOn', const {}));
    }
    return true;
  }

  /// When a touch last brought the screensaver back over a black screen
  /// (Touch under Wake to screensaver, issue #954). One tap reports twice
  /// (see [_tapChainStart]), and the lift of the waking tap must not be
  /// the second touch that opens the dashboard: until the next finger
  /// comes down, the echoes are dropped, and so are the other fingers of
  /// the same gesture.
  DateTime? _touchWokeAt;

  static bool _isTouch(String source) =>
      source == 'touch' ||
      source == 'touch_page' ||
      source == 'tap' ||
      source == 'screensaver_touch';

  void notifyActivity(String source) {
    final lit = _active && !_blanked;
    _handleActivity(source);
    // A touch that left the screensaver up is someone using the panel. A
    // touch that woke it from black is not: it only brought the
    // screensaver back.
    if (source == 'touch' && lit && _active && !_blanked) _liftForTouch();
  }

  /// Lifts the dimming the way a notification does, for Brighten for touch
  /// interactions seconds after the last touch.
  void _liftForTouch() {
    final seconds = _settings.get(defs.screensaverTouchBrightnessSeconds);
    if (seconds <= 0 || _savedBrightness == null) return;
    _touchLiftTimer?.cancel();
    _touchLiftTimer = Timer(Duration(seconds: seconds.toInt()), () {
      _touchLiftTimer = null;
      _touchLifted = false;
      if (_active) unawaited(_applyVisuals());
    });
    if (_touchLifted) return;
    _touchLifted = true;
    unawaited(
      commands.execute('setBrightness', {
        'level': _savedBrightness,
        'ceiling': true,
      }),
    );
  }

  void _endTouchLift() {
    _touchLiftTimer?.cancel();
    _touchLiftTimer = null;
    _touchLifted = false;
  }

  void _handleActivity(String source) {
    // A ringing alarm on this screensaver ends through its Snooze and Stop
    // buttons only: a brush of the hand, motion or a face never dismisses
    // it.
    if (alarmTakeover.value == 'ringing') return;
    if (_isTouch(source)) {
      final woke = _touchWokeAt;
      if (woke != null) {
        if (source != 'touch' || clock().difference(woke) < _tapDebounce) {
          return;
        }
        _touchWokeAt = null;
      }
      // Only a black screen takes touches: a powered-off panel does not.
      if (_active && _blanked && !_panelDark && _wakeToScreensaver('touch')) {
        _touchWokeAt = clock();
        return;
      }
    }
    if (_active &&
        holdSensorDismiss &&
        const {'motion', 'face', 'person', 'proximity'}.contains(source)) {
      return;
    }
    // Overlay controls consume their touch without dismissing the view.
    // Off the screensaver the touch is still activity.
    if (_touchOnControl &&
        (source == 'touch' || source == 'touch_page' || source == 'tap')) {
      if (!_active) _resetIdleTimer();
      return;
    }
    // Shared layouts dismiss through the screensaver panel. Generic touch
    // reports include player buttons and must leave the combined view up.
    if (nowPlayingShared &&
        (source == 'touch' || source == 'touch_page' || source == 'tap')) {
      return;
    }
    // Now Playing with its controls up: a touch there is a button press
    // or a seek and a key press is the dpad walking the buttons, so
    // neither dismisses. The view's close button reports as 'close', and
    // the back button, the motion policy and every other source still
    // land below.
    if (_nowPlayingHoldsTouch &&
        (source == 'touch' ||
            source == 'touch_page' ||
            source == 'tap' ||
            source == 'key')) {
      // Unless a double tap anywhere is the way out (issue #409): then a
      // touch off the controls runs the chain below, the same one the
      // website screensaver uses.
      if (source != 'touch' ||
          !_settings.get(defs.sendspinFullscreenDoubleTap) ||
          _touchOnControl) {
        return;
      }
    }
    // A touch on a slideshow's edge zone stepped the deck (issue #453):
    // the raw Listener's report of it is not a wake.
    if (_active &&
        _touchOnSlideEdge &&
        (source == 'touch' ||
            source == 'touch_page' ||
            source == 'tap' ||
            source == 'screensaver_touch')) {
      return;
    }
    if (_active &&
        _doubleTapToDismiss &&
        (source == 'touch' || source == 'touch_page' || source == 'tap')) {
      // The bridge and the gesture detector echo taps the Listener
      // already delivered.
      if (source == 'touch_page' || source == 'tap') return;
      final now = clock();
      final start = _tapChainStart;
      if (start == null || now.difference(start) > _doubleTapWindow) {
        // A first tap belongs to the page underneath; only its double
        // dismisses. Motion, voice and every other source stay single.
        _tapChainStart = now;
        return;
      }
      if (now.difference(start) < _tapDebounce) return;
      _tapChainStart = null;
    }
    if (_active) {
      log.debug(name, 'dismissed by $source');
      stop();
    }
    _resetIdleTimer();
  }

  /// The kiosk going behind another app, and coming back. Only a pause
  /// that finds the screen still lit counts: a dark panel is handled by
  /// the ScreenStateChanged listener and keeps its session.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lifecyclePaused = true;
      _pauseProbe?.cancel();
      _pauseProbe = Timer(_pauseProbeDelay, () async {
        _pauseProbe = null;
        if (!_lifecyclePaused) return;
        final on = (await commands.execute('isScreenOn', const {})).data;
        if (on == false || !_lifecyclePaused) return;
        _behindAnotherApp = true;
        _cancelIdleTimer();
        if (_active) {
          log.info(name, 'another app is in front; standing down');
          await stop();
        } else {
          log.debug(name, 'another app is in front; idle clock on hold');
        }
      });
    } else if (state == AppLifecycleState.resumed ||
        (state == AppLifecycleState.inactive && _lifecyclePaused)) {
      // A resume, or an inactive after a pause: either way the Activity
      // is back on screen. Android reports resumed only once the window
      // also holds the input focus, and a device with a focus-holding
      // window over the kiosk (a firmware overlay, a system window) comes
      // back as inactive and stays there. Waiting for resumed alone left
      // this flag set with the kiosk in plain view: no idle screensaver
      // and no Now Playing on play until a restart (issue #560).
      _lifecyclePaused = false;
      _pauseProbe?.cancel();
      _pauseProbe = null;
      if (_behindAnotherApp) {
        _behindAnotherApp = false;
        log.debug(name, 'kiosk back in front; idle clock restarted');
        _resetIdleTimer();
      }
    }
  }

  /// A key press that is driving the menu or the settings: the idle clock
  /// restarts, nothing else. It skips [notifyActivity] on purpose: there is
  /// nothing showing to dismiss, and the press may be the very one that
  /// starts the screensaver, whose dismissal riding along would race the
  /// start it commanded. A session already up keeps its own clock.
  void extendIdle() {
    if (_active) return;
    _resetIdleTimer();
  }

  /// Screens that keep the screensaver away while they are up, by name
  /// (the alarm list while an alarm is being set). Only the idle clock
  /// stands still: unlike an interaction hold, music, the wake word and
  /// the dashboard rotation carry on.
  final _holders = <String>{};

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_holders.isNotEmpty) return _setIdleDue(null);
    if (_cameraViewActive || _assistOverlay || _behindAnotherApp) {
      return _setIdleDue(null);
    }
    if (!_settings.get(defs.screensaverEnabled) || _paused || _voiceTurn) {
      return _setIdleDue(null);
    }
    // Hold mode (issue #266): the current view stays put, so the idle
    // clock never arms while it is on. Releasing the hold re-arms it
    // through the SettingChanged branch above.
    if (_settings.get(defs.haHoldMode)) return _setIdleDue(null);
    final seconds = _settings.get(defs.screensaverTimeoutSeconds).toInt();
    if (seconds <= 0) return _setIdleDue(null);
    final wait = Duration(seconds: seconds);
    _idleTimer = Timer(wait, () {
      // The clock ran out: nothing is counting down any more, whether or
      // not start() below actually gets to show anything.
      _setIdleDue(null);
      start();
    });
    _setIdleDue(clock().add(wait));
  }

  void _stopForInteraction() {
    if (!_active) return;
    final restore = activeView.value != null && _nowPlayingTakeover;
    final forNowPlaying = _startedForNowPlaying;
    _interactionStop = stop();
    _restoreNowPlaying = restore;
    _restoreForNowPlaying = restore && forNowPlaying;
  }

  Future<void> _restoreAfterInteraction() async {
    if (!_restoreNowPlaying && !_launchOnPlayPending) return;
    // Dismissal may still be thawing the dashboard or restoring brightness.
    // Let it finish before bringing the player back over the page.
    await _interactionStop;
    if (!_restoreNowPlaying && !_launchOnPlayPending) return;
    if (_paused || _voiceTurn) return;
    final launchOnPlay =
        _sendspinPlaying && _settings.get(defs.sendspinFullscreenOnPlay);
    final launch = _restoreNowPlaying || launchOnPlay;
    final forNowPlaying = _restoreNowPlaying
        ? _restoreForNowPlaying
        : launchOnPlay;
    _restoreNowPlaying = false;
    _restoreForNowPlaying = false;
    _launchOnPlayPending = false;
    if (!launch || !_nowPlayingTakeover) return;
    _cancelIdleTimer();
    await start(forNowPlaying: forNowPlaying);
    if (!_active) _resetIdleTimer();
  }

  /// Stops the idle clock without re-arming it; the countdown sensor
  /// reads unknown until the next [_resetIdleTimer].
  void _cancelIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
    _setIdleDue(null);
  }

  /// The moment the idle clock will start the screensaver, null while it
  /// is not running (issue #406). Announced on the bus on every move.
  DateTime? get idleDue => _idleDue;
  DateTime? _idleDue;

  void _setIdleDue(DateTime? due) {
    if (due == _idleDue) return;
    _idleDue = due;
    bus.publish(
      ScreensaverCountdownChanged(
        due: due,
        mode: due == null ? null : _modeAt(due),
      ),
    );
  }

  /// The mode a session starting at [at] would show: a plugin's override,
  /// the schedule entry in force then, the configured mode otherwise.
  String _modeAt(DateTime at) =>
      modeOverride.value ??
      (currentScreensaverScheduleEntry(_settings, now: at)?['mode']
          as String?) ??
      _settings.get(defs.screensaverMode);

  /// Whether the Sendspin "Now Playing" view is what the screensaver slot
  /// actually shows right now.
  bool get _nowPlayingTakeover =>
      !_blanked &&
      _sendspinNowPlaying &&
      _settings.get(defs.sendspinFullscreen) &&
      allowsNowPlaying &&
      !_alarmOnTop;

  /// An alarm owns the screen: one shows on this screensaver, or the
  /// followed player is lent to an alarm's music or the music picker's
  /// preview. Now Playing stays behind it, since the music is the
  /// alarm's, and comes back once the alarm lets go.
  bool get _alarmOnTop =>
      alarmTakeover.value != null ||
      _settings.get(defs.sendspinHandoff).trim().isNotEmpty;

  /// An Off schedule suppresses both the shared and standalone player.
  bool get allowsNowPlaying => _scheduleEntry?['now_playing'] != false;

  /// Whether the Now Playing view is on screen with its media controls
  /// (sendspin.fullscreen_controls), which is when a tap stops meaning
  /// "dismiss".
  /// Whether the Now Playing view is up with its media controls: keys
  /// walk its buttons then instead of dismissing (the kiosk screen's key
  /// routing reads it).
  bool get nowPlayingControlsUp => _nowPlayingHoldsTouch;

  /// Whether the Now Playing view is on screen at all, controls or not:
  /// the volume key routing reads it (issue #544).
  bool get nowPlayingShowing =>
      _active && activeView.value != null && _nowPlayingTakeover;

  bool get _nowPlayingHoldsTouch =>
      _active &&
      activeView.value != null &&
      _nowPlayingTakeover &&
      _settings.get(defs.sendspinFullscreenControls);

  /// The schedule entry in force right now, or null when the schedule is
  /// off or empty.
  Map<String, Object?>? get _scheduleEntry =>
      currentScreensaverScheduleEntry(_settings, now: clock());

  /// The mode the screensaver should show: a plugin's override, then the
  /// scheduled one when an entry is in force, the configured mode otherwise.
  String get _effectiveMode =>
      modeOverride.value ??
      (_scheduleEntry?['mode'] as String?) ??
      _settings.get(defs.screensaverMode);

  /// Modes plugins with the screensaver.mode capability asked for in place
  /// of the schedule and the setting, by owning session, oldest first. The
  /// newest wins, and clearing it falls back to the one before. Never
  /// saved, synced or shown to Home Assistant.
  final _modeOverrides = <String, String>{};

  /// The mode plugins hold the screensaver on, or null for the usual one.
  final ValueNotifier<String?> modeOverride = ValueNotifier(null);

  /// Every mode a plugin may pick, labeled as the device shows it in its
  /// own language: the stock modes this device offers, then each plugin
  /// screensaver published right now.
  List<Map<String, String>> get selectableModes {
    final strings = lookupUiStrings(
      appLocaleForLanguage(_settings.get(defs.uiLanguage)),
    );
    final plugins = _settings.pluginScreensavers();
    return [
      for (final id in _settings.optionsFor(defs.screensaverMode))
        if (!defs.isPluginScreensaver(id))
          {
            'id': id,
            'label': messageById(
              strings,
              settingOptionMessageIds[defs.screensaverMode.key]?[id],
              _settings.optionLabel(defs.screensaverMode, id) ?? id,
            ),
          },
      for (final entry in plugins.entries)
        {'id': entry.key, 'label': entry.value},
    ];
  }

  /// What a plugin reads of the mode: the one in force, where it comes
  /// from and what it may change to.
  Map<String, Object?> get modeState => {
    'mode': _effectiveMode,
    'saved': _settings.get(defs.screensaverMode),
    'schedule': _scheduleEntry?['mode'] as String?,
    'override': modeOverride.value,
    'active': _active,
    'modes': selectableModes,
  };

  /// Holds the screensaver on [mode] for [owner] until it clears it. False
  /// for a mode the device cannot show.
  bool setModeOverride(String owner, String mode) {
    if (!selectableModes.any((m) => m['id'] == mode)) return false;
    final before = _effectiveMode;
    _modeOverrides.remove(owner);
    _modeOverrides[owner] = mode;
    _modeOverrideChanged(before);
    return true;
  }

  /// Drops [owner]'s override, such as when its plugin session ends.
  void clearModeOverride(String owner) {
    if (!_modeOverrides.containsKey(owner)) return;
    final before = _effectiveMode;
    _modeOverrides.remove(owner);
    _modeOverrideChanged(before);
  }

  void _modeOverrideChanged(String before) {
    modeOverride.value = _modeOverrides.values.lastOrNull;
    if (_effectiveMode == before) return;
    log.info(name, 'mode override: ${modeOverride.value ?? 'none'}');
    final due = _idleDue;
    if (due != null) {
      bus.publish(ScreensaverCountdownChanged(due: due, mode: _modeAt(due)));
    }
    // The shown screensaver switches right away, like a schedule boundary.
    if (_active) unawaited(_applyVisuals());
  }

  /// The active entry's brightness (0..1), overriding the global
  /// screensaver brightness, or null when no entry carries one.
  double? get _scheduleBrightness =>
      (_scheduleEntry?['brightness'] as num?)?.toDouble();

  /// Whether the active schedule entry hides the corner widgets: null
  /// follows the Widgets group, as it did before any schedule existed.
  /// Applied during a session, null between them, and re-read at every
  /// schedule boundary — the UI layer watches this to mount or unmount the
  /// overlays without the view itself having to change.
  final ValueNotifier<bool?> scheduleWidgets = ValueNotifier(null);

  /// Null follows the global layout, true requests the shared layout and
  /// false leaves only the scheduled screensaver visible.
  final ValueNotifier<bool?> scheduleNowPlaying = ValueNotifier(null);

  /// Corners the running mode has taken for itself, which the corner
  /// widgets stand down from for as long as it holds them. The Immich
  /// screensaver claims both bottom corners while a pair of portrait photos
  /// shares the screen: each photo's metadata sits under its own half, and
  /// a clock or weather widget there would land on top of it. Empty the
  /// rest of the time, so widgets behave exactly as before.
  final ValueNotifier<Set<String>> claimedCorners = ValueNotifier(const {});

  /// The height the Weather Mood chips take at the bottom of the screen,
  /// measured after layout, so bottom corner widgets sit just above them.
  /// Zero whenever the chips are not showing.
  final ValueNotifier<double> weatherChipsHeight = ValueNotifier(0);

  /// Whether the running mode shows its own controls, which the corner
  /// widgets and the At a Glance row step aside for. The Celestial sky
  /// raises it for the few seconds its chips are up after a touch.
  final ValueNotifier<bool> modeControlsShown = ValueNotifier(false);

  /// The room the Immich metadata takes in each bottom corner it sits in,
  /// measured after layout, so the At a Glance row can wrap between the
  /// panels or rise above them (issue #916). It only grows while the
  /// screensaver runs: every photo's details differ, and a row that
  /// followed each slide would hop up and down with them.
  final ValueNotifier<Map<String, Size>> metadataFootprint = ValueNotifier(
    const {},
  );

  /// How far above the bottom edge the photo caption reaches, measured
  /// after layout, so the At a Glance row rises above it (issue #1290).
  /// Zero without a caption. Like [metadataFootprint] it only grows while
  /// the screensaver runs, so the row does not hop with every slide.
  final ValueNotifier<double> captionFootprint = ValueNotifier(0);

  /// Records how far the caption reaches, keeping the highest seen.
  void reportCaptionFootprint(double top) {
    if (top > captionFootprint.value) captionFootprint.value = top;
  }

  /// The photo the Home Assistant Media page shows, as its media id and the
  /// URL it was loaded from, so the metadata panel drawn over the page can
  /// read its EXIF (issue #953). Null for a video, a camera or nothing yet.
  final ValueNotifier<({String id, String url})?> mediaSlide = ValueNotifier(
    null,
  );

  /// Records the metadata panel's size in [corner], keeping the largest
  /// seen this session.
  void reportMetadataFootprint(String corner, Size size) {
    final had = metadataFootprint.value[corner];
    if (had != null && had.width >= size.width && had.height >= size.height) {
      return;
    }
    metadataFootprint.value = {
      ...metadataFootprint.value,
      corner: had == null
          ? size
          : Size(
              size.width > had.width ? size.width : had.width,
              size.height > had.height ? size.height : had.height,
            ),
    };
  }

  /// The slideshow on screen, when the running mode is one. Home Assistant
  /// Media, Local Media, Photo Gallery and Immich Media register on mount
  /// and stand down on unmount, and so does the Camera Streams rotation,
  /// whose views step the same way; the next and previous slide buttons
  /// ride this and do nothing for every other mode, or between
  /// screensavers.
  SlideNavigator? _slides;

  void attachSlides(SlideNavigator navigator) => _slides = navigator;

  void detachSlides(SlideNavigator navigator) {
    if (identical(_slides, navigator)) _slides = null;
  }

  /// Steps the showing slideshow by [direction] (1 next, -1 previous).
  /// False when no slideshow is up to step: not an error, the buttons are
  /// meant to be pressable at any time.
  Future<bool> stepSlide(int direction) async {
    final navigator = _slides;
    if (navigator == null || !_active || direction == 0) return false;
    await navigator(direction);
    return true;
  }

  /// The same for the At a glance row, which is its own setting and so its
  /// own override: a night entry can drop the widgets, the row, or both.
  final ValueNotifier<bool?> scheduleGlance = ValueNotifier(null);

  /// The motion policy last announced to the bus, so boundary ticks only
  /// publish actual changes. Applied during a session, null between them.
  bool? _motionPolicy;

  /// The face override (issue #304), kept the same way.
  bool? _facePolicy;

  /// The proximity and person overrides (issue #437), kept the same way.
  bool? _proximityPolicy;
  bool? _personPolicy;

  /// Announce the active entry's motion, face, proximity and person
  /// overrides (issues #89, #304 and #437), each null between sessions and
  /// for entries without one.
  void _publishMotionPolicy(
    bool? motion,
    bool? face,
    bool? proximity,
    bool? person,
  ) {
    if (motion == _motionPolicy &&
        face == _facePolicy &&
        proximity == _proximityPolicy &&
        person == _personPolicy) {
      return;
    }
    _motionPolicy = motion;
    _facePolicy = face;
    _proximityPolicy = proximity;
    _personPolicy = person;
    bus.publish(
      ScreensaverMotionPolicyChanged(
        dismissOnMotion: motion,
        dismissOnFace: face,
        dismissOnProximity: proximity,
        dismissOnPerson: person,
      ),
    );
  }

  void _scheduleTick() {
    if (!_active) return;
    final at = _scheduleEntry?['at'] as String?;
    if (at == _appliedScheduleAt) return;
    log.info(name, 'schedule: ${at ?? 'no entry'} takes over');
    unawaited(_applyVisuals());
  }

  /// An alarm showing on this screensaver: `sunrise` while its glow
  /// window runs, `ringing` while it rings, null otherwise. The Clock and
  /// Weather Mood faces draw the label and the buttons off it, and while it
  /// rings nothing but those buttons ends the session.
  final alarmTakeover = ValueNotifier<String?>(null);

  /// Start (or keep) the session for an alarm, past every gate an idle
  /// start respects: the alarm decided this screensaver shows it.
  Future<bool> _takeOverForAlarm(String phase) async {
    if (!_active) await start(force: true);
    if (!_active) return false;
    alarmTakeover.value = phase;
    _screenOffTimer?.cancel();
    _screenOffTimer = null;
    _armedScreenOffMinutes = null;
    if (_screenDark) {
      _panelDark = false;
      _blanked = false;
      _nightDark = false;
      await commands.execute('screenOn', const {});
    }
    // A ring lifts the screensaver's own dimming back to normal.
    await _applyVisuals();
    return true;
  }

  /// [byHand] opens Now Playing because someone asked for it: page holds
  /// that only keep the screensaver away (media on the page, a
  /// pauseScreensaver hold) and Hold Mode let it through.
  Future<void> start({
    bool force = false,
    bool forNowPlaying = false,
    bool byHand = false,
  }) async {
    if (_active) return;
    final held = _paused && !(byHand && !_interactions.needsScreen);
    // Say why a start goes nowhere: a page hold that never gets released
    // (a leaked "interaction running" from the dashboard) otherwise reads
    // as "Now Playing launched" followed by nothing at all.
    if (!force && (held || _voiceTurn || _cameraViewActive || _assistOverlay)) {
      final why = <String>[
        if (held) 'interaction held (${_interactions.held.join(', ')})',
        if (_voiceTurn) 'voice turn',
        if (_cameraViewActive) 'camera view',
        if (_assistOverlay) 'voice overlay',
      ];
      log.info(name, 'start refused: ${why.join(', ')}');
      return;
    }
    // Another app owns the screen; a dim now would dim it (the brightness
    // is the device's), and the idle clock is on hold for the same reason.
    if (_behindAnotherApp && !force) {
      log.debug(name, 'start refused: another app is in front');
      return;
    }
    // Hold mode refuses every start, commanded ones included: "keep this
    // view on screen" beats a startScreensaver arriving over ESPHome or a
    // gesture (issue #266).
    if (_settings.get(defs.haHoldMode) && !force && !byHand) return;
    // No screensaver under Lockdown Mode unless the owner opted in: by
    // default the locked dashboard stays glanceable. Opted in, it renders
    // under the screen-level shield — visible, but untouchable like
    // everything else, and the exit gesture still counts natively.
    if (!force &&
        _settings.get(defs.lockdownEnabled) &&
        !_settings.get(defs.lockdownAllowScreensaver)) {
      return;
    }
    _active = true;
    _startedForNowPlaying = forNowPlaying;
    _openedByHand = byHand;
    _panelDark = false;
    _blanked = false;
    // A fresh session starts with no half-open double-tap chain.
    _tapChainStart = null;
    // Hold the panel on for the whole screensaver, every mode. The screensaver
    // owns the display while it is up — black means brightness 0 under a black
    // overlay, not the OS powering the panel off, which would also freeze the
    // app and take the admin server down with it.
    await commands.execute('keepScreenAwake', {'enabled': true});
    // A dismissal can land while the await above runs — the activity ping
    // of the very key press that commanded the start arrives on the event
    // bus a beat later (issue #377). stop() has then already undone
    // everything; carrying on would rebuild the visuals over a session the
    // manager no longer owns, a ghost screensaver no key can dismiss.
    if (!_active) return;
    // The idle clock can open a session over a panel that is already off,
    // turned off from the dashboard. It starts dark then: the screen-off-
    // only detections must count it as dark and there is no panel left to
    // power off (issue #980).
    if ((await commands.execute('isScreenOn', const {})).data == false) {
      _panelDark = true;
    }
    if (!_active) return;
    log.info(
      name,
      'start ($_effectiveMode)${_panelDark ? ', screen off' : ''}',
    );
    if (!_screenDark) _armScreenOffTimer();
    await _applyVisuals();
    if (!_active) return;
    bus.publish(
      ScreensaverStateChanged(active: true, nowPlaying: _nowPlayingSession),
    );
  }

  /// Whether this session counts as Now Playing for where the dashboard
  /// lands after it (issue #899): the player has a track for the view, or
  /// the session was opened for it. A panel switched off by Turn screen
  /// off after still counts, since the music plays on under it.
  bool get _nowPlayingSession =>
      _startedForNowPlaying ||
      (_sendspinNowPlaying &&
          _settings.get(defs.sendspinFullscreen) &&
          allowsNowPlaying);

  /// "Turn screen off after": once the screensaver has been up this long,
  /// cover the app at zero brightness when requested or power the panel
  /// off with the screenOff command. The session stays active. That is
  /// what lets motion, the ESPHome dismiss and the wake word wake it through
  /// the normal [stop] path. Quiet on a missing device admin grant: a
  /// timer firing overnight must never put Android's permission screen up.
  void _armScreenOffTimer() {
    _screenOffTimer?.cancel();
    _screenOffTimer = null;
    // An alarm on this screensaver keeps the panel lit until it lets go.
    if (alarmTakeover.value != null) {
      _armedScreenOffMinutes = null;
      return;
    }
    final minutes = _effectiveScreenOffMinutes;
    _armedScreenOffMinutes = minutes;
    if (minutes <= 0) return;
    _screenOffTimer = Timer(_screenOffUnit * minutes, () async {
      _screenOffTimer = null;
      if (!_active) return;
      await _goDark(
        black: _settings.get(defs.screensaverScreenOffBlack),
        why: 'up for ${minutes}m',
      );
    });
  }

  /// Take the screen dark under the session: a black screen at zero
  /// brightness, or the panel really powered off. Never prompts for the
  /// Device admin grant, since nobody may be in the room; false when
  /// Android refused the power-off for want of it.
  Future<bool> _goDark({required bool black, required String why}) async {
    if (black) {
      log.info(name, '$why; blanking the screen');
      _blanked = true;
      _nowPlayingShared = false;
      _tapChainStart = null;
      _controlTouchAt = null;
      _slideTouchAt = null;
      await _applyVisuals();
      return true;
    }
    log.info(name, '$why; powering the panel off');
    final r = await commands.execute('screenOff', const {'prompt': false});
    if (!r.ok) log.warn(name, 'could not power the panel off: ${r.error}');
    return r.ok;
  }

  /// The minutes in force right now: the active schedule entry's own
  /// (issue #437), where 0 means never even over a set slider, or the
  /// slider outside the schedule.
  int get _effectiveScreenOffMinutes =>
      (_scheduleEntry?['screen_off'] as int?) ??
      _settings.get(defs.screensaverScreenOffMinutes).toInt();

  /// Re-arm the countdown only when the effective minutes changed under the
  /// session: a schedule boundary crossing into an entry with its own
  /// value, the schedule edited live, or the slider moved. Never under a
  /// dark panel, and never for a reapply that leaves the value alone.
  void _syncScreenOffTimer() {
    if (!_active || _screenDark || _assistOverlay) return;
    if (_effectiveScreenOffMinutes == _armedScreenOffMinutes) return;
    _armScreenOffTimer();
  }

  /// Save the restore point before the first brightness change of a
  /// session — once: _applyVisuals may re-dim and re-brighten several
  /// times in one screensaver session as music starts and stops or the
  /// schedule crosses a boundary. Capture-on-demand keeps it the true
  /// pre-screensaver level even when a session starts in a mode that
  /// never touches brightness and only later switches to one that does.
  Future<void> _ensureSavedBrightness() async {
    if (_savedBrightness != null) return;
    // The ceiling, not the panel: under adaptive brightness the panel is
    // the ceiling dimmed for the room as it is now, and restoring that
    // number later, in another light, would land somewhere else.
    final brightness = await commands.execute('getBrightness', const {
      'ceiling': true,
    });
    _savedBrightness = (brightness.data as num?)?.toDouble();
    if (_savedBrightness != null) {
      await _settings.set(defs.screensaverSavedBrightness, _savedBrightness!);
    }
  }

  /// A notification came up over the screensaver, or the last one went.
  /// Only the brightness moves: the mode keeps its overlay, so the clock
  /// or the photo stays exactly where it was, lit enough to read the card
  /// on top of it.
  Future<void> _onNotificationsChanged(bool showing) async {
    if (_notificationShowing == showing) return;
    _notificationShowing = showing;
    // Nothing to lift unless a session is running and it dimmed something
    // (_savedBrightness is the level it will go back to).
    if (!_active || _blanked || _savedBrightness == null) return;
    if (!_settings.get(defs.screensaverNotificationBrightness)) return;
    if (showing) {
      await commands.execute('setBrightness', {
        'level': _savedBrightness,
        'ceiling': true,
      });
    } else {
      // Back to whatever this mode, schedule entry or takeover asks for.
      await _applyVisuals();
    }
  }

  /// Set the overlay and tell the bus: the browser manager freezes the
  /// dashboard's rendering only while an overlay actually covers it, and
  /// coverage can flip mid-session (a schedule boundary swapping Dim for a
  /// content mode, music starting under Dim).
  void _setView(String? view) {
    // A plugin's tint goes with its screensaver. The black screen-off
    // cover in the same session keeps it for when the view comes back.
    final tint = pluginTint.value;
    if (tint != null && view != tint.mode && view != 'blank') {
      pluginTint.value = null;
    }
    activeView.value = view;
    bus.publish(ScreensaverViewChanged(view: view));
    _syncNowPlayingShown();
    _syncPageReserve();
  }

  /// Whether the Now Playing view is on screen, as the screensaver overlay
  /// draws it: a session with a visible view that the takeover fills.
  bool _nowPlayingShown = false;
  bool get nowPlayingShown => _nowPlayingShown;

  /// Now Playing fills the whole screen: shown and not sharing it with the
  /// screensaver. The dashboard and the pages over it are out of sight, so
  /// the kiosk screen leaves them out of the frame.
  final nowPlayingCovers = ValueNotifier<bool>(false);

  void _syncNowPlayingCovers() {
    final view = activeView.value;
    nowPlayingCovers.value =
        _active &&
        view != null &&
        view != 'blank' &&
        _nowPlayingTakeover &&
        !_nowPlayingShared;
  }

  void _syncNowPlayingShown() {
    _syncNowPlayingCovers();
    final view = activeView.value;
    final shown = view != null && view != 'blank' && _nowPlayingTakeover;
    if (shown == _nowPlayingShown) return;
    _nowPlayingShown = shown;
    bus.publish(FullscreenViewChanged(view: 'nowPlaying', shown: shown));
  }

  /// Apply what the screensaver session should currently look like: the
  /// configured mode, or the Sendspin "Now Playing" takeover. Called at
  /// start and again whenever the takeover flips mid-session (music
  /// starting or stopping under an active screensaver), so the brightness
  /// policy matches the display. The standalone player keeps normal
  /// brightness. Shared layouts follow the screensaver's brightness unless
  /// their brightness override is enabled.
  Future<void> _applyVisuals() async {
    // Every change of what the session shows (a start, the schedule, Now
    // Playing, an alarm letting go, a wake) is a moment Night mode's
    // countdown may need to start or stop.
    _reviewNight();
    _syncNowPlayingCovers();
    final mode = _effectiveMode;
    final entry = _scheduleEntry;
    _appliedScheduleAt = entry?['at'] as String?;
    _publishMotionPolicy(
      entry?['motion'] as bool?,
      entry?['face'] as bool?,
      entry?['proximity'] as bool?,
      entry?['person'] as bool?,
    );
    scheduleNowPlaying.value = entry?['now_playing'] as bool?;
    scheduleWidgets.value = entry?['widgets'] as bool?;
    scheduleGlance.value = entry?['glance'] as bool?;
    _syncScreenOffTimer();
    // The voice overlay over the screensaver reads at the saved level,
    // whatever the mode dims to, and so does an alarm ringing on it: a
    // screensaver at 0% must not ring in the dark.
    final lift = _assistOverlay || alarmTakeover.value == 'ringing';
    final liftForVoice = lift && _savedBrightness != null;
    if (_blanked) {
      await _ensureSavedBrightness();
      if (!_active || !_blanked) return;
      _setView('blank');
      await commands.execute('setBrightness', {
        'level': lift ? _savedBrightness : 0,
        'ceiling': true,
      });
      return;
    }
    // Modes that change brightness save their restore point first.
    if (mode == 'dim' || mode == 'black' || _contentDimEnabled(mode)) {
      await _ensureSavedBrightness();
    }
    // The Home Assistant Dashboard mode moves the page to its view before
    // anything decides what covers it: under the Now Playing takeover the
    // view waits behind the player, and the dismissal undoes the move
    // either way.
    dashboardShowing.value = _active && mode == 'dashboard';
    final dashboardView = _settings.get(defs.screensaverDashboardView);
    if (mode == 'dashboard' && dashboardView != _dashboardShown) {
      _dashboardShown = dashboardView;
      await commands.execute('showScreensaverDashboard', {
        'path': dashboardView,
      });
      if (!_active) return;
    }
    if (_nowPlayingNormalBrightness) {
      // A non-null view gives the override a slot to render into, at full
      // brightness. 'dim' and 'dashboard' show the page itself beside a
      // shared panel and give way to black under a full-screen one.
      _setView(switch (mode) {
        'dim' || 'dashboard' when !nowPlayingShared => 'black',
        _ => mode,
      });
      if (_savedBrightness != null) {
        await commands.execute('setBrightness', {
          'level': _savedBrightness,
          'ceiling': true,
        });
      }
      return;
    }
    // A notification on screen outranks every mode's darkness, including a
    // schedule entry's: the overlay below is still the mode's own, only the
    // backlight is borrowed back until the last card goes.
    final liftForNotification =
        liftForVoice ||
        (_notificationShowing &&
            _savedBrightness != null &&
            _settings.get(defs.screensaverNotificationBrightness)) ||
        (_touchLifted && _savedBrightness != null);
    switch (mode) {
      case 'dim':
        // Backlight only — no overlay. stop() restores the saved level.
        // A scheduled brightness wins over the configured dim level.
        // Beside a shared player the 'dim' view is a clear layer that
        // gives the player its slot and leaves the page showing.
        _setView(nowPlayingShared ? 'dim' : null);
        final dim =
            _scheduleBrightness ??
            _settings.get(defs.screensaverDimLevel).toDouble();
        await commands.execute('setBrightness', {
          'level': liftForNotification ? _savedBrightness : dim,
          'ceiling': true,
        });
      case 'black' when liftForNotification:
        _setView('black');
        await commands.execute('setBrightness', {
          'level': _savedBrightness,
          'ceiling': true,
        });
      case 'black':
        // Backlight to zero behind a black overlay — deliberately NOT the
        // screenOff command, which truly powers the panel off (device-admin
        // lockNow) and would freeze the app with it. The black screensaver
        // must stay alive: motion wake, the wake word UI and the admin's
        // live view all keep running behind the dark glass.
        _setView('black');
        await commands.execute('setBrightness', {'level': 0, 'ceiling': true});
      default:
        // clock / media / website: a lit overlay showing content, at normal
        // brightness unless the separate screensaver brightness — or the
        // active schedule entry — asks for its own level (a clock that must
        // not glow all night). Beside a shared player the dashboard keeps
        // showing, laid out in the room the panel leaves (pageReserve).
        _setView(mode);
        if (_contentDimEnabled(mode)) {
          final level =
              _scheduleBrightness ??
              _settings.get(defs.screensaverBrightnessLevel).toDouble();
          await commands.execute('setBrightness', {
            'level': liftForNotification ? _savedBrightness : level,
            'ceiling': true,
          });
        } else if (_savedBrightness != null) {
          // A mid-session switch out of a dimmed mode (schedule boundary,
          // music starting) must lift the old mode's darkness with it.
          await commands.execute('setBrightness', {
            'level': _savedBrightness,
            'ceiling': true,
          });
        }
    }
  }

  /// Whether a separate content brightness applies to [mode]: every content
  /// mode, never Dim (its own level) or Black (always zero). The schedule's
  /// per-entry brightness counts even when the global switch is off.
  bool _contentDimEnabled(String mode) =>
      mode != 'dim' &&
      mode != 'black' &&
      (_scheduleBrightness != null ||
          _settings.get(defs.screensaverBrightnessEnabled));

  /// Live tweak while the screensaver shows: apply the new level, saving the
  /// restore point first when the toggle just turned on; turning it off
  /// restores the pre-screensaver brightness right away.
  Future<void> _onBrightnessSettingChanged() async {
    if (_blanked) return;
    final mode = _effectiveMode;
    if (mode == 'dim' || mode == 'black' || _nowPlayingNormalBrightness) {
      return;
    }
    if (_contentDimEnabled(mode)) {
      await _ensureSavedBrightness();
      // An active schedule entry's brightness still wins over the slider.
      await commands.execute('setBrightness', {
        'level':
            _scheduleBrightness ??
            _settings.get(defs.screensaverBrightnessLevel).toDouble(),
        'ceiling': true,
      });
    } else if (_savedBrightness != null) {
      await commands.execute('setBrightness', {
        'level': _savedBrightness,
        'ceiling': true,
      });
      _savedBrightness = null;
      await _settings.set(defs.screensaverSavedBrightness, -1);
    }
  }

  Future<void> stop() async {
    // An explicit dismissal also cancels a player waiting to return or
    // to launch.
    _restoreNowPlaying = false;
    _restoreForNowPlaying = false;
    _launchOnPlayPending = false;
    if (!_active) return;
    final nowPlaying = _nowPlayingSession;
    _active = false;
    _endTouchLift();
    holdSensorDismiss = false;
    _startedForNowPlaying = false;
    _openedByHand = false;
    alarmTakeover.value = null;
    renderPaused.value = false;
    _nowPlayingShared = false;
    // Before the thaw below, which a covering Now Playing would hold off.
    _syncNowPlayingCovers();
    // The page takes its full width back while the overlay still covers
    // it, not after the dismissal has shown it squeezed.
    _syncPageReserve();
    _tapChainStart = null;
    _screenOffTimer?.cancel();
    _screenOffTimer = null;
    _armedScreenOffMinutes = null;
    _panelDark = false;
    _blanked = false;
    _nightTimer?.cancel();
    _nightTimer = null;
    _nightDark = false;
    _nightRefused = false;
    log.info(name, 'stop');
    // Thaw the dashboard while the overlay still covers it, so the wake
    // never shows a blank hole where the page is (a no-op unless the
    // rendering freeze optimization hid it).
    await commands.execute('unfreezeRendering', const {});
    // Move the page to where the dismissal lands while the overlay still
    // covers it. Awaited, so a navigation commanded right after the
    // dismissal (the ESPHome Dashboard select, haNavigate) lands after
    // this return.
    _dashboardShown = null;
    await commands.execute('leaveScreensaver', {'nowPlaying': nowPlaying});
    dashboardShowing.value = false;
    _setView(null);
    await commands.execute('screenOn', const {});
    // Release the hold; the keep-awake setting (if any) still applies.
    await commands.execute('keepScreenAwake', {'enabled': false});
    if (_savedBrightness != null) {
      await commands.execute('setBrightness', {
        'level': _savedBrightness,
        'ceiling': true,
      });
      _savedBrightness = null;
      await _settings.set(defs.screensaverSavedBrightness, -1);
    }
    _publishMotionPolicy(null, null, null, null);
    scheduleNowPlaying.value = null;
    scheduleWidgets.value = null;
    scheduleGlance.value = null;
    claimedCorners.value = const {};
    weatherChipsHeight.value = 0;
    modeControlsShown.value = false;
    metadataFootprint.value = const {};
    captionFootprint.value = 0;
    mediaSlide.value = null;
    _slides = null;
    bus.publish(const ScreensaverStateChanged(active: false));
  }

  /// One-time carry-over for the small clock's own 24-hour switch (issue
  /// #116): it used to follow the Clock mode's, so a device that had that
  /// on keeps its 24-hour small clock instead of silently flipping to
  /// AM/PM on update.
  Future<void> _migrateMiniClock24h() async {
    if (_settings.internal('screensaver.mini_clock_24h.migrated').isNotEmpty) {
      return;
    }
    if (_settings.get(defs.screensaverClock24h)) {
      await _settings.set(defs.screensaverMiniClock24h, true);
      log.info(name, 'small clock keeps its 24-hour format');
    }
    await _settings.setInternal('screensaver.mini_clock_24h.migrated', '1');
  }

  /// Fold an enabled legacy small clock into a Widgets entry. Value-driven
  /// rather than marker-driven: migrating turns the old switch off, so it
  /// naturally runs once — and runs again when an old backup import turns
  /// it back on.
  Future<void> _migrateMiniClockWidget() async {
    if (!_settings.get(defs.screensaverMiniClock)) return;
    final position = _settings.get(defs.screensaverMiniClockPosition);
    final entry = ScreensaverWidget(
      position: position,
      type: 'clock',
      config: {
        'color': _settings.get(defs.screensaverMiniClockColor),
        'h24': _settings.get(defs.screensaverMiniClock24h),
        'date': _settings.get(defs.screensaverMiniClockDate),
      },
    );
    final others = [
      for (final w in decodeScreensaverWidgets(
        _settings.get(defs.screensaverWidgets),
      ))
        if (w.position != position && w.type != 'clock') w,
    ];
    await _settings.set(
      defs.screensaverWidgets,
      encodeScreensaverWidgets([...others, entry]),
    );
    await _settings.set(defs.screensaverMiniClock, false);
    log.info(name, 'small clock migrated to a $position widget');
  }

  /// Fold the single view of the pre-rotation Camera Streams setting into
  /// the view list. Value-driven like the small clock: migrating clears the
  /// old key, so it runs once, and runs again when an old backup import
  /// fills it. The old key was the one view the screensaver showed, so it
  /// becomes the whole rotation rather than joining whatever was listed:
  /// an old backup restores the screensaver it describes.
  Future<void> _migrateCameraView() async {
    final legacy = _settings.get(defs.screensaverCameraView);
    if (legacy.isEmpty) return;
    await _settings.set(
      defs.screensaverCameraViews,
      encodeCameraViewIds([legacy]),
    );
    await _settings.set(defs.screensaverCameraView, '');
    await _settings.set(defs.screensaverCameraViewName, '');
    log.info(name, 'camera screensaver view $legacy migrated to the view list');
  }

  @override
  Future<void> dispose() async {
    if (Platform.isAndroid) WidgetsBinding.instance.removeObserver(this);
    _pauseProbe?.cancel();
    _idleTimer?.cancel();
    _scheduleTimer?.cancel();
    _screenOffTimer?.cancel();
    _nightTimer?.cancel();
    _endTouchLift();
    activeView.dispose();
    pageReserve.dispose();
    clockNight.dispose();
    pluginTint.dispose();
    dashboardShowing.dispose();
    scheduleNowPlaying.dispose();
    modeOverride.dispose();
  }
}
