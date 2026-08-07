import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

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
      });
    }
    entries.sort((a, b) => scheduleMinutes(a['at'] as String)!
        .compareTo(scheduleMinutes(b['at'] as String)!));
    return entries;
  } catch (_) {
    return const [];
  }
}

/// The entry in force at [minutesNow]: the latest one at or before it, or —
/// before the day's first entry — the last one, still holding from
/// yesterday. Null only for an empty schedule.
Map<String, Object?>? activeScheduleEntry(
    List<Map<String, Object?>> entries, int minutesNow) {
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
/// commands so this manager never references the screen manager. Never
/// 'screenOff': that is real display power (device-admin lockNow), which
/// would freeze the app — the screensaver's black is brightness zero
/// behind an overlay, with everything still running.
class ScreensaverManager extends Manager {
  ScreensaverManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'screensaver';

  Timer? _idleTimer;
  Timer? _scheduleTimer;
  bool _active = false;
  bool _paused = false;

  /// The `at` of the schedule entry the current visuals were applied under,
  /// so the periodic tick only reapplies on an actual boundary crossing.
  String? _appliedScheduleAt;

  /// A voice turn is in progress (wake word fired, page not yet resumed). The
  /// idle timer is held the whole time, so the screensaver cannot return while
  /// the user is mid-interaction.
  bool _voiceTurn = false;
  bool _cameraViewActive = false;
  double? _savedBrightness;

  /// The visual overlay the UI should render, or null for none.
  ///
  /// One of 'black' | 'clock' | 'media' | 'website'. The 'dim' mode sets no
  /// view — it only lowers the backlight — so this stays null there.
  final ValueNotifier<String?> activeView = ValueNotifier(null);

  bool get isActive => _active;

  /// Whether the Sendspin now-playing display is active (a track loaded),
  /// mirrored from its bus event for the motion-dismiss policy above.
  bool _sendspinNowPlaying = false;

  @override
  Future<void> init() async {
    await _migrateMiniClock24h();
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
    bus.on<SendspinNowPlayingChanged>().listen((e) {
      _sendspinNowPlaying = e.active;
      // Mid-session flip: music started (dim gives way to Now Playing at
      // full brightness) or stopped (the configured mode re-asserts).
      if (_active) unawaited(_applyVisuals());
    });
    bus.on<MotionDetected>().listen((_) {
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
      if (!(_motionPolicy ??
          _settings.get(defs.screensaverDismissOnMotion))) {
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
    bus.on<SettingChanged>().listen((e) {
      if (e.key.startsWith('screensaver.')) _resetIdleTimer();
      // Lockdown Mode owns the display while it holds: a running
      // screensaver stops, and start() refuses below until it lifts.
      if (e.key == defs.lockdownEnabled.key) {
        if (e.value == true) {
          unawaited(stop());
          _idleTimer?.cancel();
        } else {
          _resetIdleTimer();
        }
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
    _scheduleTimer =
        Timer.periodic(const Duration(seconds: 20), (_) => _scheduleTick());

    // A process death mid-screensaver loses the in-memory restore point; the
    // persisted copy keeps the dim level from becoming the new normal. Runs
    // before any screensaver can start, so a pending value is always stale.
    final orphaned = _settings.get(defs.screensaverSavedBrightness).toDouble();
    if (orphaned >= 0) {
      log.info(name, 'restoring brightness after an interrupted screensaver');
      await commands.execute('setBrightness', {'level': orphaned});
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
          name: 'getScreensaverSuppressed',
          description:
              'Whether the page should stand down its own screensaver '
              'because this app runs one and is set to take precedence',
          handler: (_) async => CommandResult.ok(
            _settings.get(defs.screensaverEnabled) &&
                _settings.get(defs.vsSuppressScreensaver),
          ),
        ),
      );

    _resetIdleTimer();
  }

  /// A slideshow view swapped to its next slide: the room is about to be
  /// relit by the app's own display (see [ScreensaverSlideChanged]).
  void notifySlideChanged() => bus.publish(const ScreensaverSlideChanged());

  void notifyActivity(String source) {
    if (_active) {
      log.debug(name, 'dismissed by $source');
      stop();
    }
    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_cameraViewActive) return;
    if (!_settings.get(defs.screensaverEnabled) || _paused || _voiceTurn) {
      return;
    }
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
    final entries =
        parseScreensaverSchedule(_settings.get(defs.screensaverSchedule));
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

  /// The motion policy last announced to the bus, so boundary ticks only
  /// publish actual changes. Applied during a session, null between them.
  bool? _motionPolicy;

  /// Announce the active entry's motion override (issue #89), [policy]
  /// itself being null between sessions and for entries without one.
  void _publishMotionPolicy(bool? policy) {
    if (policy == _motionPolicy) return;
    _motionPolicy = policy;
    bus.publish(ScreensaverMotionPolicyChanged(dismissOnMotion: policy));
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
    // No screensaver under Lockdown Mode: the locked dashboard stays
    // glanceable, and nothing must sit above the touch shield.
    if (_settings.get(defs.lockdownEnabled)) return;
    _active = true;
    // Hold the panel on for the whole screensaver, every mode. The screensaver
    // owns the display while it is up — black means brightness 0 under a black
    // overlay, not the OS powering the panel off, which would also freeze the
    // app and take the admin server down with it.
    await commands.execute('keepScreenAwake', {'enabled': true});
    log.info(name, 'start ($_effectiveMode)');
    await _applyVisuals();
    bus.publish(const ScreensaverStateChanged(active: true));
  }

  /// Save the restore point before the first brightness change of a
  /// session — once: _applyVisuals may re-dim and re-brighten several
  /// times in one screensaver session as music starts and stops or the
  /// schedule crosses a boundary. Capture-on-demand keeps it the true
  /// pre-screensaver level even when a session starts in a mode that
  /// never touches brightness and only later switches to one that does.
  Future<void> _ensureSavedBrightness() async {
    if (_savedBrightness != null) return;
    final brightness = await commands.execute('getBrightness', const {});
    _savedBrightness = (brightness.data as num?)?.toDouble();
    if (_savedBrightness != null) {
      await _settings.set(defs.screensaverSavedBrightness, _savedBrightness!);
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
    _publishMotionPolicy(entry?['motion'] as bool?);
    // Modes that change brightness save their restore point first.
    if (mode == 'dim' || mode == 'black' || _contentDimEnabled(mode)) {
      await _ensureSavedBrightness();
    }
    if (_nowPlayingTakeover) {
      // A non-null view gives the override a slot to render into ('dim'
      // normally shows no overlay at all), at full brightness.
      _setView((mode == 'dim') ? 'black' : mode);
      if (_savedBrightness != null) {
        await commands.execute('setBrightness', {'level': _savedBrightness});
      }
      return;
    }
    switch (mode) {
      case 'dim':
        // Backlight only — no overlay. stop() restores the saved level.
        // A scheduled brightness wins over the configured dim level.
        _setView(null);
        final dim = _scheduleBrightness ??
            _settings.get(defs.screensaverDimLevel).toDouble();
        await commands.execute('setBrightness', {'level': dim});
      case 'black':
        // Backlight to zero behind a black overlay — deliberately NOT the
        // screenOff command, which truly powers the panel off (device-admin
        // lockNow) and would freeze the app with it. The black screensaver
        // must stay alive: motion wake, the wake word UI and the admin's
        // live view all keep running behind the dark glass.
        _setView('black');
        await commands.execute('setBrightness', {'level': 0});
      default:
        // clock / media / website: a lit overlay showing content, at normal
        // brightness unless the separate screensaver brightness — or the
        // active schedule entry — asks for its own level (a clock that must
        // not glow all night).
        _setView(mode);
        if (_contentDimEnabled(mode)) {
          final level = _scheduleBrightness ??
              _settings.get(defs.screensaverBrightnessLevel).toDouble();
          await commands.execute('setBrightness', {'level': level});
        } else if (_savedBrightness != null) {
          // A mid-session switch out of a dimmed mode (schedule boundary,
          // music starting) must lift the old mode's darkness with it.
          await commands.execute('setBrightness', {'level': _savedBrightness});
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
        'level': _scheduleBrightness ??
            _settings.get(defs.screensaverBrightnessLevel).toDouble()
      });
    } else if (_savedBrightness != null) {
      await commands.execute('setBrightness', {'level': _savedBrightness});
      _savedBrightness = null;
      await _settings.set(defs.screensaverSavedBrightness, -1);
    }
  }

  Future<void> stop() async {
    if (!_active) return;
    _active = false;
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
      await commands.execute('setBrightness', {'level': _savedBrightness});
      _savedBrightness = null;
      await _settings.set(defs.screensaverSavedBrightness, -1);
    }
    _publishMotionPolicy(null);
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

  @override
  Future<void> dispose() async {
    _idleTimer?.cancel();
    _scheduleTimer?.cancel();
    activeView.dispose();
  }
}
