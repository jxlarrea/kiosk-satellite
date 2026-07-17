import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// Brightness, keep-awake, and (simulated) screen power.
///
/// True hardware screen-off requires device-owner privileges on Android; the
/// portable approach — same as kiosk browsers use — is brightness 0 plus a
/// black overlay, which the screensaver manager renders. "Screen on/off"
/// here therefore tracks a logical state that other managers react to.
class ScreenManager extends Manager {
  ScreenManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'screen';

  bool _screenOn = true;
  double? _savedBrightness;

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
        description: 'Turn the screen on',
        handler: (_) async {
          await screenOn();
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'screenOff',
        description: 'Turn the screen off (black overlay + zero brightness)',
        handler: (_) async {
          await screenOff();
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'keepScreenAwake',
        description: 'Hold the panel on regardless of the keep-awake setting. '
            'The screensaver uses this so a black overlay stays black-and-on '
            'rather than letting the OS power the display off underneath it — '
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

  Future<void> screenOff() async {
    if (!_screenOn) return;
    _screenOn = false;
    _savedBrightness = await getBrightness();
    await setBrightness(0);
    bus.publish(const ScreenStateChanged(on: false));
  }

  Future<void> screenOn() async {
    if (_screenOn) return;
    _screenOn = true;
    if (_savedBrightness != null) {
      await setBrightness(_savedBrightness!);
    } else {
      await resetBrightness();
    }
    bus.publish(const ScreenStateChanged(on: true));
  }
}
