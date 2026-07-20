import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

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
  bool _active = false;
  bool _paused = false;

  /// A voice turn is in progress (wake word fired, page not yet resumed). The
  /// idle timer is held the whole time, so the screensaver cannot return while
  /// the user is mid-interaction.
  bool _voiceTurn = false;
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
    bus.on<ActivityDetected>().listen((e) => notifyActivity(e.source));
    // Stand down while a page interaction runs (voice turn, ringing timer
    // alert, media playback), whichever API the page signalled it through:
    // setInteractionActive, or the legacy pauseScreensaver fallback.
    bus.on<VoiceInteractionChanged>().listen((e) {
      _paused = e.active;
      if (_paused) unawaited(stop());
      _resetIdleTimer();
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
      if (!_settings.get(defs.screensaverDismissOnMotion)) return;
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
    });

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

  void notifyActivity(String source) {
    if (_active) {
      log.debug(name, 'dismissed by $source');
      stop();
    }
    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
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

  Future<void> start() async {
    if (_active || _paused) return;
    _active = true;
    // Hold the panel on for the whole screensaver, every mode. The screensaver
    // owns the display while it is up — black means brightness 0 under a black
    // overlay, not the OS powering the panel off, which would also freeze the
    // app and take the admin server down with it.
    await commands.execute('keepScreenAwake', {'enabled': true});
    final mode = _settings.get(defs.screensaverMode);
    log.info(name, 'start ($mode)');
    // Modes that change brightness get their restore point saved up front,
    // once — _applyVisuals may re-dim and re-brighten several times in one
    // screensaver session as music starts and stops.
    if (mode == 'dim' || mode == 'black') {
      final brightness = await commands.execute('getBrightness', const {});
      _savedBrightness = (brightness.data as num?)?.toDouble();
    }
    await _applyVisuals();
    bus.publish(const ScreensaverStateChanged(active: true));
  }

  /// Apply what the screensaver session should currently look like: the
  /// configured mode, or the Sendspin "Now Playing" takeover. Called at
  /// start and again whenever the takeover flips mid-session (music
  /// starting or stopping under an active screensaver), so the brightness
  /// policy always matches what is actually displayed — Now Playing is a
  /// music display and must not inherit dim's backlight or black's zero.
  Future<void> _applyVisuals() async {
    final mode = _settings.get(defs.screensaverMode);
    if (_nowPlayingTakeover) {
      // A non-null view gives the override a slot to render into ('dim'
      // normally shows no overlay at all), at full brightness.
      activeView.value = (mode == 'dim') ? 'black' : mode;
      if (_savedBrightness != null) {
        await commands.execute('setBrightness', {'level': _savedBrightness});
      }
      return;
    }
    switch (mode) {
      case 'dim':
        // Backlight only — no overlay. stop() restores the saved level.
        activeView.value = null;
        final dim = _settings.get(defs.screensaverDimLevel).toDouble();
        await commands.execute('setBrightness', {'level': dim});
      case 'black':
        // Backlight to zero behind a black overlay — deliberately NOT the
        // screenOff command, which truly powers the panel off (device-admin
        // lockNow) and would freeze the app with it. The black screensaver
        // must stay alive: motion wake, the wake word UI and the admin's
        // live view all keep running behind the dark glass.
        activeView.value = 'black';
        await commands.execute('setBrightness', {'level': 0});
      default:
        // clock / media / website: a lit overlay showing content. The screen
        // stays at its normal brightness — dimming a clock to 10% defeats it.
        activeView.value = mode;
    }
  }

  Future<void> stop() async {
    if (!_active) return;
    _active = false;
    log.info(name, 'stop');
    activeView.value = null;
    await commands.execute('screenOn', const {});
    // Release the hold; the keep-awake setting (if any) still applies.
    await commands.execute('keepScreenAwake', {'enabled': false});
    if (_savedBrightness != null) {
      await commands.execute('setBrightness', {'level': _savedBrightness});
      _savedBrightness = null;
    }
    bus.publish(const ScreensaverStateChanged(active: false));
  }

  @override
  Future<void> dispose() async {
    _idleTimer?.cancel();
    activeView.dispose();
  }
}
