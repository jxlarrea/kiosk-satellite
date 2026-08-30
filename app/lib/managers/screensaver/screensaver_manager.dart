import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
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
        // Tri-state widgets override: absent shows whatever the Widgets
        // group configures, false hides the corner widgets for this
        // entry's hours.
        if (e['widgets'] is bool) 'widgets': e['widgets'],
        // The same for the At a glance row.
        if (e['glance'] is bool) 'glance': e['glance'],
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
/// exactly one place, the "Turn screen off after" timer, and by explicit
/// request — with background listening on, the process (and its camera,
/// carried by the camera-type foreground service) keeps running behind the
/// dark panel, so motion, the MQTT dismiss and the wake word can all light
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
  });

  final SettingsManager _settings;

  @override
  String get name => 'screensaver';

  Timer? _idleTimer;
  Timer? _scheduleTimer;
  bool _active = false;
  bool _paused = false;

  /// "Turn screen off after": armed when a session starts (and re-armed on
  /// a mid-session wake, so a power-button wake that dismisses nothing gets
  /// its own fresh countdown), canceled when the session ends or the panel
  /// goes dark by other hands.
  Timer? _screenOffTimer;

  /// One real minute, injectable for tests only.
  final Duration _screenOffUnit;

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
  bool _cameraViewActive = false;
  double? _savedBrightness;

  /// Whether a notification is on screen. A dimmed screensaver lifts back
  /// to the brightness it saved while one is up: a message nobody can read
  /// is not a message (issue #278).
  bool _notificationShowing = false;

  /// The visual overlay the UI should render, or null for none.
  ///
  /// One of 'black' | 'clock' | 'media' | 'website'. The 'dim' mode sets no
  /// view — it only lowers the backlight — so this stays null there.
  final ValueNotifier<String?> activeView = ValueNotifier(null);

  bool get isActive => _active;

  /// Whether the Sendspin now-playing display is active (a track loaded),
  /// mirrored from its bus event for the motion-dismiss policy above.
  bool _sendspinNowPlaying = false;

  /// The double-tap dismiss chain (discussion #248). One physical tap
  /// reports here twice — the kiosk screen's raw pointer Listener
  /// ('touch') and the screensaver WebView's JS bridge ('touch_page') —
  /// and timing cannot tell that echo from a genuinely fast double tap,
  /// so only the Listener's reports count for the chain and the bridge's
  /// are dropped while the gate holds. Reports faster than [_tapDebounce]
  /// after the chain opened are the other fingers of one gesture (a
  /// pinch), not a second tap.
  DateTime? _tapChainStart;
  static const _tapDebounce = Duration(milliseconds: 120);
  static const _doubleTapWindow = Duration(milliseconds: 400);

  /// Wall clock, injectable for the double-tap tests only.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  /// Whether dismissal currently takes two taps: only the website
  /// screensaver offers the option (its page is the only thing a single
  /// tap could talk to), and never while the Sendspin now-playing view
  /// has taken the slot over — that view is ours, not a page.
  bool get _doubleTapToDismiss =>
      activeView.value == 'website' &&
      !_nowPlayingTakeover &&
      _settings.get(defs.screensaverWebsiteDoubleTap);

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
      _paused = e.active;
      if (_paused) unawaited(stop());
      _resetIdleTimer();
    });
    bus.on<CameraViewStateChanged>().listen((event) {
      _cameraViewActive = event.active;
      if (event.active) {
        unawaited(stop());
        _idleTimer?.cancel();
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
      if (_active) {
        log.debug(name, 'dismissed by wake word');
        stop();
      }
      _idleTimer?.cancel();
    });
    // The page resuming wake detection (active again) is the end of the turn —
    // only now does the idle countdown begin. A stuck turn is covered by the
    // wake manager's own resume timeout, which resumes and lands us here too.
    bus.on<WakeWordStateChanged>().listen((e) {
      if (e.active && _voiceTurn) {
        _voiceTurn = false;
        _resetIdleTimer();
      }
    });
    // The panel changing state under an active session: a power-off — ours
    // or anyone's — leaves nothing to count down for, and a wake depends on
    // whose hand it was. A person at the panel (power button, double-tap-
    // to-wake: source system) is activity like a touch, so they land on
    // the dashboard rather than the screensaver — except under lockdown,
    // which keeps its screen locked here exactly like it does for motion.
    // The app's own pokes (source app) are either part of a dismiss that
    // is already running or an automation switching the panel on to show
    // the screensaver (a photo frame's morning switch-on), so those keep
    // the session and just start a fresh screen-off countdown.
    bus.on<ScreenStateChanged>().listen((e) {
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
        _screenOffTimer?.cancel();
        _screenOffTimer = null;
        return;
      }
      if (byHand) {
        notifyActivity('screen on');
        return;
      }
      _armScreenOffTimer();
    });
    bus.on<NotificationsChanged>().listen((e) {
      unawaited(_onNotificationsChanged(e.showing));
    });
    bus.on<SendspinNowPlayingChanged>().listen((e) {
      _sendspinNowPlaying = e.active;
      // Mid-session flip: music started (dim gives way to Now Playing at
      // full brightness) or stopped (the configured mode re-asserts).
      if (_active) unawaited(_applyVisuals());
    });
    bus.on<MotionDetected>().listen((_) {
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
      // The active schedule entry's motion override (issue #89) wins over
      // the switch, matching the camera's own gating in MotionManager.
      if (!(_motionPolicy ?? _settings.get(defs.screensaverDismissOnMotion))) {
        return;
      }
      // The full-screen now-playing view has its own motion policy: it is
      // a music display, and someone walking past should not interrupt it
      // unless explicitly asked to (sendspin.fullscreen_motion).
      final showingNowPlaying =
          activeView.value != null &&
          _sendspinNowPlaying &&
          _settings.get(defs.sendspinFullscreen);
      if (showingNowPlaying && !_settings.get(defs.sendspinFullscreenMotion)) {
        return;
      }
      notifyActivity('motion');
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
      final showingNowPlaying =
          activeView.value != null &&
          _sendspinNowPlaying &&
          _settings.get(defs.sendspinFullscreen);
      if (showingNowPlaying && !_settings.get(defs.sendspinFullscreenMotion)) {
        return;
      }
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
      if (!_settings.get(defs.screensaverDismissOnPerson)) return;
      // Dismiss acts on someone arriving. A held signal is someone who
      // was already there when the screensaver started: with Postpone off
      // that screensaver is wanted, and re-dismissing it on every
      // heartbeat made a start-and-dismiss loop (issue #369).
      if (e.held) return;
      // Now Playing keeps its own policy; someone there counts like
      // motion there.
      final showingNowPlaying =
          activeView.value != null &&
          _sendspinNowPlaying &&
          _settings.get(defs.sendspinFullscreen);
      if (showingNowPlaying && !_settings.get(defs.sendspinFullscreenMotion)) {
        return;
      }
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
      if (!_settings.get(defs.screensaverDismissOnProximity)) return;
      // The approach dismisses; something still close when the screensaver
      // starts does not (issue #369, the same rule as the person sensor).
      if (e.held) return;
      // Now Playing keeps its own policy; something coming close counts
      // like motion there.
      final showingNowPlaying =
          activeView.value != null &&
          _sendspinNowPlaying &&
          _settings.get(defs.sendspinFullscreen);
      if (showingNowPlaying && !_settings.get(defs.sendspinFullscreenMotion)) {
        return;
      }
      notifyActivity('proximity');
    });
    bus.on<SettingChanged>().listen((e) {
      if (e.key.startsWith('screensaver.')) _resetIdleTimer();
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
      // dismisses it), but over MQTT or the remote admin nothing else
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
          _idleTimer?.cancel();
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
          _idleTimer?.cancel();
        }
      }
      // Hold mode pins whatever is on screen right now (issue #266): a
      // showing screensaver is never what the user meant to pin, so
      // engaging hold dismisses it and stops the idle clock; releasing
      // the hold puts the clock back.
      if (e.key == defs.haHoldMode.key) {
        if (e.value == true) {
          unawaited(stop());
          _idleTimer?.cancel();
        } else {
          _resetIdleTimer();
        }
      }
      // Moving the screen-off slider under a running session applies to it:
      // the countdown restarts at the new value (or stops at 0).
      if (_active && e.key == defs.screensaverScreenOffMinutes.key) {
        _armScreenOffTimer();
      }
      // Moving the screensaver-brightness controls while the screensaver is
      // showing applies immediately: the slider doubles as a live preview.
      if (_active &&
          (e.key == defs.screensaverBrightnessEnabled.key ||
              e.key == defs.screensaverBrightnessLevel.key)) {
        unawaited(_onBrightnessSettingChanged());
      }
      // Editing the schedule while the screensaver shows applies right
      // away, same as the brightness slider: the editor doubles as a
      // live preview.
      if (_active &&
          (e.key == defs.screensaverSchedule.key ||
              e.key == defs.screensaverScheduleEnabled.key ||
              e.key == defs.screensaverMode.key)) {
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
          name: 'startScreensaver',
          description: 'Start the screensaver now',
          handler: (_) async {
            await start();
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
          name: 'isScreensaverActive',
          description: 'Whether the screensaver is showing right now',
          quiet: true,
          handler: (_) async => CommandResult.ok(_active),
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

  void notifyActivity(String source) {
    if (_active &&
        _doubleTapToDismiss &&
        (source == 'touch' || source == 'touch_page')) {
      // The bridge echoes taps the Listener already delivered.
      if (source == 'touch_page') return;
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
        _idleTimer?.cancel();
        if (_active) {
          log.info(name, 'another app is in front; standing down');
          await stop();
        } else {
          log.debug(name, 'another app is in front; idle clock on hold');
        }
      });
    } else if (state == AppLifecycleState.resumed) {
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

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_cameraViewActive || _behindAnotherApp) return;
    if (!_settings.get(defs.screensaverEnabled) || _paused || _voiceTurn) {
      return;
    }
    // Hold mode (issue #266): the current view stays put, so the idle
    // clock never arms while it is on. Releasing the hold re-arms it
    // through the SettingChanged branch above.
    if (_settings.get(defs.haHoldMode)) return;
    final seconds = _settings.get(defs.screensaverTimeoutSeconds).toInt();
    if (seconds <= 0) return;
    _idleTimer = Timer(Duration(seconds: seconds), start);
  }

  /// Whether the Sendspin "Now Playing" view is what the screensaver slot
  /// actually shows right now.
  bool get _nowPlayingTakeover =>
      _sendspinNowPlaying && _settings.get(defs.sendspinFullscreen);

  /// The schedule entry in force right now, or null when the schedule is
  /// off or empty.
  Map<String, Object?>? get _scheduleEntry {
    if (!_settings.get(defs.screensaverScheduleEnabled)) return null;
    final entries = parseScreensaverSchedule(
      _settings.get(defs.screensaverSchedule),
    );
    final now = DateTime.now();
    return activeScheduleEntry(entries, now.hour * 60 + now.minute);
  }

  /// The mode the screensaver should show: the scheduled one when an entry
  /// is in force, the configured mode otherwise.
  String get _effectiveMode =>
      (_scheduleEntry?['mode'] as String?) ??
      _settings.get(defs.screensaverMode);

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

  /// Corners the running mode has taken for itself, which the corner
  /// widgets stand down from for as long as it holds them. The Immich
  /// screensaver claims both bottom corners while a pair of portrait photos
  /// shares the screen: each photo's metadata sits under its own half, and
  /// a clock or weather widget there would land on top of it. Empty the
  /// rest of the time, so widgets behave exactly as before.
  final ValueNotifier<Set<String>> claimedCorners = ValueNotifier(const {});

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

  /// Announce the active entry's motion and face overrides (issues #89 and
  /// #304), each null between sessions and for entries without one.
  void _publishMotionPolicy(bool? motion, bool? face) {
    if (motion == _motionPolicy && face == _facePolicy) return;
    _motionPolicy = motion;
    _facePolicy = face;
    bus.publish(
      ScreensaverMotionPolicyChanged(
        dismissOnMotion: motion,
        dismissOnFace: face,
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

  Future<void> start() async {
    if (_active || _paused || _cameraViewActive) return;
    // Another app owns the screen; a dim now would dim it (the brightness
    // is the device's), and the idle clock is on hold for the same reason.
    if (_behindAnotherApp) {
      log.debug(name, 'start refused: another app is in front');
      return;
    }
    // Hold mode refuses every start, commanded ones included: "keep this
    // view on screen" beats a startScreensaver arriving over MQTT or a
    // gesture (issue #266).
    if (_settings.get(defs.haHoldMode)) return;
    // No screensaver under Lockdown Mode unless the owner opted in: by
    // default the locked dashboard stays glanceable. Opted in, it renders
    // under the screen-level shield — visible, but untouchable like
    // everything else, and the exit gesture still counts natively.
    if (_settings.get(defs.lockdownEnabled) &&
        !_settings.get(defs.lockdownAllowScreensaver)) {
      return;
    }
    _active = true;
    // A fresh session starts with no half-open double-tap chain.
    _tapChainStart = null;
    // Hold the panel on for the whole screensaver, every mode. The screensaver
    // owns the display while it is up — black means brightness 0 under a black
    // overlay, not the OS powering the panel off, which would also freeze the
    // app and take the admin server down with it.
    await commands.execute('keepScreenAwake', {'enabled': true});
    log.info(name, 'start ($_effectiveMode)');
    _armScreenOffTimer();
    await _applyVisuals();
    bus.publish(const ScreensaverStateChanged(active: true));
  }

  /// "Turn screen off after": once the screensaver has been up this long,
  /// truly power the panel off (device-admin lockNow via the screenOff
  /// command). The session stays active behind the dark panel — that is
  /// what lets motion, the MQTT dismiss and the wake word wake it through
  /// the normal [stop] path. Quiet on a missing device admin grant: a
  /// timer firing overnight must never put Android's permission screen up.
  void _armScreenOffTimer() {
    _screenOffTimer?.cancel();
    _screenOffTimer = null;
    final minutes = _settings.get(defs.screensaverScreenOffMinutes).toInt();
    if (minutes <= 0) return;
    _screenOffTimer = Timer(_screenOffUnit * minutes, () async {
      _screenOffTimer = null;
      if (!_active) return;
      log.info(name, 'up for ${minutes}m; powering the panel off');
      final r = await commands.execute('screenOff', const {'prompt': false});
      if (!r.ok) {
        log.warn(name, 'could not power the panel off: ${r.error}');
      }
    });
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
    if (!_active || _savedBrightness == null) return;
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
    activeView.value = view;
    bus.publish(ScreensaverViewChanged(view: view));
  }

  /// Apply what the screensaver session should currently look like: the
  /// configured mode, or the Sendspin "Now Playing" takeover. Called at
  /// start and again whenever the takeover flips mid-session (music
  /// starting or stopping under an active screensaver), so the brightness
  /// policy always matches what is actually displayed — Now Playing is a
  /// music display and must not inherit dim's backlight or black's zero.
  Future<void> _applyVisuals() async {
    final mode = _effectiveMode;
    final entry = _scheduleEntry;
    _appliedScheduleAt = entry?['at'] as String?;
    _publishMotionPolicy(entry?['motion'] as bool?, entry?['face'] as bool?);
    scheduleWidgets.value = entry?['widgets'] as bool?;
    scheduleGlance.value = entry?['glance'] as bool?;
    // Modes that change brightness save their restore point first.
    if (mode == 'dim' || mode == 'black' || _contentDimEnabled(mode)) {
      await _ensureSavedBrightness();
    }
    if (_nowPlayingTakeover) {
      // A non-null view gives the override a slot to render into ('dim'
      // normally shows no overlay at all), at full brightness.
      _setView((mode == 'dim') ? 'black' : mode);
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
        _notificationShowing &&
        _savedBrightness != null &&
        _settings.get(defs.screensaverNotificationBrightness);
    switch (mode) {
      case 'dim':
        // Backlight only — no overlay. stop() restores the saved level.
        // A scheduled brightness wins over the configured dim level.
        _setView(null);
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
        // not glow all night).
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
    final mode = _effectiveMode;
    if (mode == 'dim' || mode == 'black' || _nowPlayingTakeover) return;
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
    if (!_active) return;
    _active = false;
    _screenOffTimer?.cancel();
    _screenOffTimer = null;
    log.info(name, 'stop');
    // Thaw the dashboard while the overlay still covers it, so the wake
    // never shows a blank hole where the page is (a no-op unless the
    // rendering freeze optimization hid it).
    await commands.execute('unfreezeRendering', const {});
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
    _publishMotionPolicy(null, null);
    scheduleWidgets.value = null;
    scheduleGlance.value = null;
    claimedCorners.value = const {};
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
    activeView.dispose();
  }
}
