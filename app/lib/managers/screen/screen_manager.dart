import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import '../wake_word/background_listening.dart';

/// Brightness, keep-awake, and screen power.
///
/// "Screen on/off" is real display power, never a brightness trick: on is a
/// wake-lock poke (no permission needed), off is device-admin lockNow — an
/// active admin is the only way Android lets an app power the panel off, so
/// without the grant the off button reports why instead of faking it. The
/// black screensaver keeps its own brightness-zero overlay (it must keep the
/// app alive for motion and wake word), independent of these commands.
class ScreenManager extends Manager with WidgetsBindingObserver {
  ScreenManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    this._wakeSettle = const Duration(milliseconds: 700),
    this._activitySettle = const Duration(milliseconds: 1500),
  });

  final SettingsManager _settings;

  /// How long a wake lock, then a wake Activity, get to light the panel
  /// before [_confirmWake] looks; injectable so tests need not wait.
  final Duration _wakeSettle;
  final Duration _activitySettle;

  @override
  String get name => 'screen';

  bool _screenOn = true;

  bool get isScreenOn => _screenOn;

  /// Move the logical state and tell everyone, once. Both the app's own
  /// screenOn/screenOff and the system's broadcasts land here, so a change
  /// is announced exactly once no matter which of them saw it first: the
  /// broadcast that follows this app's own lockNow finds the flag already
  /// moved and stays quiet.
  void _setScreenOn(bool on, {required String source}) {
    if (_screenOn == on) return;
    _screenOn = on;
    log.debug(name, 'screen ${on ? 'on' : 'off'} ($source)');
    bus.publish(ScreenStateChanged(on: on, source: source));
  }

  /// The screensaver asks the screen to stay on while its overlay is up (see
  /// [_applyWakelock]).
  bool _screensaverHold = false;

  @override
  Future<void> init() async {
    await _applyWakelock();

    // Reapplied every time the app reaches the foreground. The apply above
    // is not enough on its own: at boot this init runs on the cached engine
    // before the Activity exists, so wakelock_plus throws "wakelock requires
    // a foreground activity" and "Keep screen on" silently never takes
    // effect until the setting is toggled by hand (issue #167). The flag is
    // also a property of the Activity window, so a recreated Activity (crash
    // self-heal, config change) starts without it. Both cases end with a
    // resume, which is the retry.
    WidgetsBinding.instance.addObserver(this);

    // The panel's real state, however it got there. Without this the flag
    // below only ever moved when this app itself turned the screen on or
    // off, so the power button, the OS idle timeout or another app left
    // every mirror of it stale — the MQTT light stuck on, the remote admin
    // disagreeing with the tablet in front of you (issue #41).
    // Through BackgroundListening, which multiplexes this channel: setting a
    // handler on it directly would replace the one carrying download and
    // volume pushes.
    BackgroundListening.onScreenStateChanged = (on) =>
        _setScreenOn(on, source: 'system');
    // Seed from reality rather than assuming on: a device whose screen is
    // already off when the app starts would otherwise report on until
    // something happened to change it.
    try {
      final interactive = await _background.invokeMethod<bool>(
        'isScreenInteractive',
      );
      if (interactive != null) _screenOn = interactive;
    } catch (_) {}

    // An explicitly set always-on preference answers the question without
    // waiting for a screen-off to observe. Unset (-1) says nothing: the ROM
    // default applies and is not readable, so that case waits for the probe.
    // Watched as well as read: it is changed in Android's settings while
    // this app runs, and nothing else would ever tell us.
    BackgroundListening.onAmbientDisplayChanged = _applyAmbientSetting;
    try {
      _applyAmbientSetting(
        await _background.invokeMethod<int>('ambientDisplaySetting') ?? -1,
      );
    } catch (_) {}

    // External brightness changes (quick settings, adaptive brightness):
    // pushed by the native observer so every mirror of the value — the
    // remote admin's slider, the MQTT brightness state — tracks the panel
    // instead of the last value this app happened to write.
    _brightness.setMethodCallHandler((call) async {
      if (call.method == 'brightnessChanged') {
        final level = (call.arguments as num?)?.toDouble();
        // While a window override is up (no-grant fallback), a system value
        // change does not alter what the panel shows; reporting it would
        // move every mirror to a number the panel is not displaying.
        if (level != null && _overrideLevel == null) {
          bus.publish(BrightnessChanged(level: level));
        }
      }
      // Both of these are here to be readable in a device's own log: what
      // levels mean on this panel is invisible from outside, and it decides
      // whether a level lands where it was asked for (issue #270).
      if (call.method == 'brightnessRange') {
        _logBrightnessScale(call.arguments as Map?);
      }
      if (call.method == 'brightnessRecovered') {
        final args = (call.arguments as Map?) ?? const {};
        log.warn(
          name,
          'brightness write reverted by the system (asked '
          '${args['asked']}, reverted to ${args['reverted']}); toggled '
          'adaptive brightness and wrote it again',
        );
      }
      if (call.method == 'brightnessClamped') {
        final args = (call.arguments as Map?) ?? const {};
        log.warn(
          name,
          'brightness written as ${args['asked']}, the system kept '
          '${args['kept']}',
        );
      }
      return null;
    });

    // Logged once at start, since a panel whose scale is not the usual
    // 0..255 is the difference between a brightness slider that works and
    // one that lands in the dark.
    try {
      _logBrightnessScale(
        await _brightness.invokeMethod<Map<Object?, Object?>>('range'),
      );
    } catch (_) {}

    // The default brightness, applied at start when its gate is on. Also
    // applied live as the slider moves (or the gate turns on) — brightness
    // is the kind of setting whose feedback should be the panel itself.
    if (_settings.get(defs.setBrightnessOnLaunch)) {
      await setBrightness(_settings.get(defs.defaultBrightness).toDouble());
    }

    bus.on<SettingChanged>().listen((e) async {
      if (e.key == defs.keepScreenOn.key || e.key == defs.haHoldMode.key) {
        await _applyWakelock();
      }
      if (e.key == defs.defaultBrightness.key &&
          _settings.get(defs.setBrightnessOnLaunch)) {
        await setBrightness((e.value as num).toDouble());
      }
      if (e.key == defs.setBrightnessOnLaunch.key && e.value == true) {
        await setBrightness(_settings.get(defs.defaultBrightness).toDouble());
      }
    });

    commands
      ..register(
        Command(
          name: 'getBrightness',
          description: 'Current screen brightness (0..1)',
          handler: (_) async => CommandResult.ok(await getBrightness()),
        ),
      )
      ..register(
        Command(
          name: 'isScreenOn',
          description: 'Whether the screen is (logically) on',
          handler: (_) async => CommandResult.ok(isScreenOn),
        ),
      )
      ..register(
        Command(
          name: 'getAmbientDisplay',
          description:
              'Whether this device leaves an ambient lock screen lit after the '
              'screen is turned off, which no app can override',
          handler: (_) async => CommandResult.ok(ambientDisplay),
        ),
      )
      ..register(
        Command(
          name: 'setBrightness',
          description: 'Set screen brightness',
          params: const {'level': 'Brightness 0..1'},
          handler: (p) async {
            final level = (p['level'] as num?)?.toDouble();
            if (level == null || level < 0 || level > 1) {
              return const CommandResult.fail('level must be 0..1');
            }
            await setBrightness(level);
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'screenOn',
          description: 'Wake the display (works on a sleeping panel)',
          params: const {
            'path':
                "'activity' to skip the wake lock and wake through the "
                'activity route only, to tell which route works on a '
                'panel that stays dark',
          },
          handler: (p) async {
            await screenOn(activityOnly: p['path'] == 'activity');
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'screenOff',
          description:
              'Turn the display off (needs the device admin permission)',
          params: const {
            'prompt':
                'false to fail quietly without raising the device '
                'admin grant screen (unattended callers like the '
                'screensaver timer)',
          },
          handler: (p) async {
            if (await screenOff()) return const CommandResult.ok();
            if (p['prompt'] == false) {
              return const CommandResult.fail(
                'the device admin permission is not active',
              );
            }
            // Missing grant: put Android's own activation screen up on the
            // device — one tap there and the next press works. Via the
            // Activity when one is up (Samsung shows the proper dialog only
            // then); the app-context fallback covers a detached Activity.
            try {
              await _admin.invokeMethod('requestScreenOffAdmin');
            } catch (_) {
              try {
                await _background.invokeMethod('requestScreenOffAdmin');
              } catch (_) {}
            }
            return const CommandResult.fail(
              'Turning the screen off needs a one-time permission. The tablet '
              'is now showing the "device admin" grant screen. Approve it '
              'there, then try again.',
            );
          },
        ),
      )
      ..register(
        Command(
          name: 'keepScreenAwake',
          description:
              'Hold the panel on regardless of the keep-awake setting. '
              'The screensaver uses this so a black overlay stays black-and-on '
              'rather than letting the OS power the display off underneath it, '
              'which would also freeze the app and drop the admin server.',
          params: const {'enabled': 'true to hold the screen on'},
          handler: (p) async {
            _screensaverHold = p['enabled'] == true;
            await _applyWakelock();
            return const CommandResult.ok();
          },
        ),
      );
  }

  /// See the observer registration in [init]: a resume means there is now a
  /// foreground Activity, which is exactly what a failed or lost wakelock
  /// apply was missing. Enable and disable both just set or clear a window
  /// flag, so reapplying on every resume is harmless when nothing changed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_applyWakelock());
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Keep the screen on when the user's setting asks for it, the
  /// screensaver is holding it, or hold mode is pinning the current view
  /// (issue #266: a held recipe that goes dark defeats the point).
  /// `FLAG_KEEP_SCREEN_ON` (via wakelock_plus) stops
  /// the OS display timeout — the panel stays powered, brightness is ours to
  /// set (0 for black), and the app is never backgrounded into a freeze.
  Future<void> _applyWakelock() async {
    final want =
        _settings.get(defs.keepScreenOn) ||
        _screensaverHold ||
        _settings.get(defs.haHoldMode);
    try {
      want ? await WakelockPlus.enable() : await WakelockPlus.disable();
      if (_wakelockRetryPending) {
        _wakelockRetryPending = false;
        log.info(name, 'wakelock ${want ? 'enabled' : 'disabled'} on retry');
      }
    } catch (e) {
      _wakelockRetryPending = true;
      log.warn(name, 'wakelock ${want ? 'enable' : 'disable'} failed: $e');
    }
  }

  /// A failed apply waiting for its resume retry; only exists so the retry
  /// logs its success and the fix is visible in the app logs.
  bool _wakelockRetryPending = false;

  /// The level of the window override currently masking the system value,
  /// null when none is up. Set only by the no-grant fallback in
  /// [setBrightness]; while set, IT is what the panel shows, so reads
  /// report it and system-value observer events are ignored.
  double? _overrideLevel;

  void _logBrightnessScale(Map<Object?, Object?>? range) {
    if (range == null) return;
    log.info(name, 'brightness scale ${range['min']}..${range['max']}');
  }

  /// The panel's actual brightness: the window override while one is up
  /// (the no-grant fallback), else the system setting — never the plugin's
  /// stale view, which stops tracking reality the moment anything else
  /// (quick settings, adaptive brightness) moves the panel.
  Future<double?> getBrightness() async {
    final override = _overrideLevel;
    if (override != null) return override;
    try {
      final level = await _brightness.invokeMethod<double>('get');
      if (level != null) return level;
    } catch (_) {
      // Not Android, or the channel is unavailable: plugin fallback below.
    }
    try {
      return await ScreenBrightness().application;
    } catch (e) {
      log.warn(name, 'getBrightness failed: $e');
      return null;
    }
  }

  Future<bool> setBrightness(double level) async {
    final clamped = level.clamp(0.0, 1.0);
    // The real thing first: write the system setting, so the value every
    // other surface reads (quick settings, the MQTT state) moves too.
    // Needs the "Modify system settings" grant; false without it.
    try {
      if (await _brightness.invokeMethod<bool>('set', {'level': clamped}) ==
          true) {
        // Drop any app-window override so the system value shows through.
        try {
          await ScreenBrightness().resetApplicationScreenBrightness();
        } catch (_) {}
        _overrideLevel = null;
        bus.publish(BrightnessChanged(level: clamped));
        return true;
      }
    } catch (_) {}
    // No grant: the window override still visibly dims the fullscreen
    // kiosk, it just cannot move the system slider with it.
    try {
      await ScreenBrightness().setApplicationScreenBrightness(clamped);
      _overrideLevel = clamped;
      bus.publish(BrightnessChanged(level: clamped));
      return true;
    } catch (e) {
      log.warn(name, 'setBrightness failed: $e');
      return false;
    }
  }

  /// Restore OS-controlled brightness (undoes any app override).
  Future<void> resetBrightness() async {
    try {
      await ScreenBrightness().resetApplicationScreenBrightness();
      _overrideLevel = null;
    } catch (e) {
      log.warn(name, 'resetBrightness failed: $e');
    }
  }

  /// App-scoped bridge (lives on the cached engine); carries the wake-lock
  /// poke that lights a sleeping panel and the device-admin lockNow that
  /// truly powers it off.
  static const _background = MethodChannel('kiosk_satellite/background');

  /// Activity-scoped (see MainActivity): the device-admin grant dialog.
  static const _admin = MethodChannel('kiosk_satellite/admin');

  /// System brightness bridge (BrightnessBridge.kt): the real panel value,
  /// its observer, and the "Modify system settings" grant.
  static const _brightness = MethodChannel('kiosk_satellite/brightness');

  /// True panel off via device-admin lockNow — never a brightness trick;
  /// the brightness slider owns brightness (issue #2). Returns false when
  /// the device admin permission is not active, in which case nothing
  /// happens at all.
  Future<bool> screenOff() async {
    var ok = false;
    try {
      ok = await _background.invokeMethod('screenOff') == true;
    } catch (_) {}
    if (ok) {
      // A wake confirmation still in flight would otherwise judge this
      // deliberate dark panel as a failed wake.
      _wakeGeneration++;
      _setScreenOn(false, source: 'app');
      unawaited(_probeAmbientDisplay());
    }
    return ok;
  }

  /// Whether this device leaves its panel lit after a screen-off.
  ///
  /// lockNow is everything an app is allowed to do, and on a device with an
  /// always-on display that is not enough: it sleeps and locks, then the ROM
  /// lights a dim clock (issue #51). Nothing distinguishes that from a real
  /// power-off except looking at the panel afterwards, which is what
  /// [_probeAmbientDisplay] does.
  bool get ambientDisplay => _settings.get(defs.screenAmbientDisplay);

  /// Take the always-on display preference as read: 1 on, 0 off, -1 unset
  /// (the ROM's own default, which is not readable and is on for some, so
  /// that case is left to [_probeAmbientDisplay]).
  void _applyAmbientSetting(int setting) {
    if (setting != 0 && setting != 1) return;
    _setAmbientDisplay(setting == 1);
  }

  Future<void> _setAmbientDisplay(bool on) async {
    if (on == ambientDisplay) return;
    await _settings.set(defs.screenAmbientDisplay, on);
    log.info(
      name,
      on
          ? 'this device keeps its panel lit after a screen off (always-on '
                'display); the Home Assistant screen entity is withdrawn'
          : 'the panel goes dark on a screen off; the Home Assistant screen '
                'entity is back',
    );
    bus.publish(AmbientDisplayChanged(on: on));
  }

  /// Display.STATE_OFF, the one value that means the panel is dark.
  static const _displayStateOff = 1;

  /// Look at the panel shortly after a screen-off and remember what we find.
  ///
  /// Twice, and seconds apart: the sleep transition takes a moment, and a
  /// panel that is going to stay lit is lit for good, so a single early
  /// reading would call every device ambient.
  Future<void> _probeAmbientDisplay() async {
    var lit = false;
    for (final delay in const [
      Duration(milliseconds: 1500),
      Duration(seconds: 5),
    ]) {
      await Future<void>.delayed(delay);
      // A wake in the meantime makes the reading meaningless: the panel is
      // on because the screen is on.
      if (_screenOn) return;
      try {
        final state = await _background.invokeMethod<int>('displayState');
        if (state == null || state == 0) return; // unknown, nothing learned
        lit = state != _displayStateOff;
      } catch (_) {
        return;
      }
      if (!lit) break;
    }
    await _setAmbientDisplay(lit);
  }

  /// Light a sleeping panel.
  ///
  /// Two routes. The wake lock first: a poke that needs no permission and
  /// is a no-op on a lit panel. It runs before the logical-state guard, and
  /// must: the power button (or screenOff above) puts the display to sleep
  /// without this manager necessarily hearing about it, so _screenOn can
  /// still read true in exactly the situation the admin's "Screen on"
  /// exists for. Then, a beat later, a look at the panel: some devices
  /// accept the lock and leave the display dark (issue #305, a Galaxy Tab
  /// S7+), and the only trace was a "screen on" log line over a black
  /// panel while every mirror of the state said lit. A panel still asleep
  /// then goes through the second route, an Activity the system lights the
  /// panel for (WakeActivity), and both outcomes are logged so a device
  /// where neither works says so.
  ///
  /// [activityOnly] skips the wake lock: the command's diagnostic, to tell
  /// on a device which of the two routes works.
  Future<void> screenOn({bool activityOnly = false}) async {
    if (!activityOnly) {
      try {
        await _background.invokeMethod('wakeScreen');
      } catch (_) {}
    }
    // Optimistic, as the ACTION_SCREEN_ON broadcast reports a wake too and
    // whichever arrives first moves the flag; the confirmation takes it
    // back if the panel turns out to have stayed dark.
    _setScreenOn(true, source: 'app');
    unawaited(_confirmWake(activityOnly: activityOnly));
  }

  /// Bumped by every wake and every screenOff, so a confirmation that a
  /// newer request has overtaken stops instead of judging a panel it did
  /// not move.
  int _wakeGeneration = 0;

  Future<void> _confirmWake({required bool activityOnly}) async {
    final generation = ++_wakeGeneration;
    if (!activityOnly) {
      await Future<void>.delayed(_wakeSettle);
      if (generation != _wakeGeneration) return;
      // Lit, or unanswerable (no bridge): nothing more to do.
      if (await _isInteractive() ?? true) return;
      log.warn(
        name,
        'the wake lock did not light the panel; trying the activity route',
      );
    }
    String? outcome;
    try {
      outcome = await _background.invokeMethod<String>('wakeScreenViaActivity');
    } catch (_) {}
    if (outcome != 'started') {
      log.warn(
        name,
        outcome == 'no_overlay_grant'
            ? 'the activity route needs the Display over other apps '
                  'permission; the panel stays dark'
            : 'the activity route could not start; the panel stays dark',
      );
      _setScreenOn(false, source: 'probe');
      return;
    }
    await Future<void>.delayed(_activitySettle);
    if (generation != _wakeGeneration) return;
    final lit = await _isInteractive();
    if (lit == null) return;
    if (lit) {
      log.info(name, 'the activity route lit the panel');
      _setScreenOn(true, source: 'app');
    } else {
      log.warn(name, 'the panel stayed dark after both wake routes');
      _setScreenOn(false, source: 'probe');
    }
  }

  /// Whether the display is awake right now, null when the bridge cannot
  /// say (no platform, a detached engine).
  Future<bool?> _isInteractive() async {
    try {
      return await _background.invokeMethod<bool>('isScreenInteractive');
    } catch (_) {
      return null;
    }
  }
}
