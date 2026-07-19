import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// Brightness, keep-awake, and screen power.
///
/// "Screen on/off" is real display power, never a brightness trick: on is a
/// wake-lock poke (no permission needed), off is device-admin lockNow — an
/// active admin is the only way Android lets an app power the panel off, so
/// without the grant the off button reports why instead of faking it. The
/// black screensaver keeps its own brightness-zero overlay (it must keep the
/// app alive for motion and wake word), independent of these commands.
class ScreenManager extends Manager {
  ScreenManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'screen';

  bool _screenOn = true;

  bool get isScreenOn => _screenOn;

  /// The screensaver asks the screen to stay on while its overlay is up (see
  /// [_applyWakelock]).
  bool _screensaverHold = false;

  @override
  Future<void> init() async {
    await _applyWakelock();

    // The default brightness, applied at start when its gate is on. Also
    // applied live as the slider moves (or the gate turns on) — brightness
    // is the kind of setting whose feedback should be the panel itself.
    if (_settings.get(defs.setBrightnessOnLaunch)) {
      await setBrightness(_settings.get(defs.defaultBrightness).toDouble());
    }

    bus.on<SettingChanged>().listen((e) async {
      if (e.key == defs.keepScreenOn.key) await _applyWakelock();
      if (e.key == defs.defaultBrightness.key &&
          _settings.get(defs.setBrightnessOnLaunch)) {
        await setBrightness((e.value as num).toDouble());
      }
      if (e.key == defs.setBrightnessOnLaunch.key && e.value == true) {
        await setBrightness(_settings.get(defs.defaultBrightness).toDouble());
      }
    });

    commands
      ..register(Command(
        name: 'getBrightness',
        description: 'Current screen brightness (0..1)',
        handler: (_) async => CommandResult.ok(await getBrightness()),
      ))
      ..register(Command(
        name: 'isScreenOn',
        description: 'Whether the screen is (logically) on',
        handler: (_) async => CommandResult.ok(isScreenOn),
      ))
      ..register(Command(
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
      ))
      ..register(Command(
        name: 'screenOn',
        description: 'Wake the display (works on a sleeping panel)',
        handler: (_) async {
          await screenOn();
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'screenOff',
        description:
            'Turn the display off (needs the device admin permission)',
        handler: (_) async {
          if (await screenOff()) return const CommandResult.ok();
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
      ))
      ..register(Command(
        name: 'keepScreenAwake',
        description: 'Hold the panel on regardless of the keep-awake setting. '
            'The screensaver uses this so a black overlay stays black-and-on '
            'rather than letting the OS power the display off underneath it, '
            'which would also freeze the app and drop the admin server.',
        params: const {'enabled': 'true to hold the screen on'},
        handler: (p) async {
          _screensaverHold = p['enabled'] == true;
          await _applyWakelock();
          return const CommandResult.ok();
        },
      ));
  }

  /// Keep the screen on when either the user's setting asks for it or the
  /// screensaver is holding it. `FLAG_KEEP_SCREEN_ON` (via wakelock_plus) stops
  /// the OS display timeout — the panel stays powered, brightness is ours to
  /// set (0 for black), and the app is never backgrounded into a freeze.
  Future<void> _applyWakelock() async {
    final want = _settings.get(defs.keepScreenOn) || _screensaverHold;
    try {
      want ? await WakelockPlus.enable() : await WakelockPlus.disable();
    } catch (e) {
      log.warn(name, 'wakelock ${want ? 'enable' : 'disable'} failed: $e');
    }
  }

  Future<double?> getBrightness() async {
    try {
      return await ScreenBrightness().application;
    } catch (e) {
      log.warn(name, 'getBrightness failed: $e');
      return null;
    }
  }

  Future<bool> setBrightness(double level) async {
    try {
      await ScreenBrightness().setApplicationScreenBrightness(
          level.clamp(0.0, 1.0));
      bus.publish(BrightnessChanged(level: level));
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

  /// True panel off via device-admin lockNow — never a brightness trick;
  /// the brightness slider owns brightness (issue #2). Returns false when
  /// the device admin permission is not active, in which case nothing
  /// happens at all.
  Future<bool> screenOff() async {
    var ok = false;
    try {
      ok = await _background.invokeMethod('screenOff') == true;
    } catch (_) {}
    if (ok && _screenOn) {
      _screenOn = false;
      bus.publish(const ScreenStateChanged(on: false));
    }
    return ok;
  }

  Future<void> screenOn() async {
    // The wake poke runs before the logical-state guard, and must: the power
    // button (or screenOff above) puts the display to sleep without this
    // manager necessarily hearing about it, so _screenOn can still read true
    // in exactly the situation the admin's "Screen on" exists for. It is a
    // no-op on an already-lit panel and needs no permission.
    try {
      await _background.invokeMethod('wakeScreen');
    } catch (_) {}
    if (_screenOn) return;
    _screenOn = true;
    bus.publish(const ScreenStateChanged(on: true));
  }
}
