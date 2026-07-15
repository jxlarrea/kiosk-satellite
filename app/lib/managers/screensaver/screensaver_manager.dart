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
/// Dimming and restoring go through 'setBrightness'/'screenOn'/'screenOff'
/// registry commands so this manager never references the screen manager.
class ScreensaverManager extends Manager {
  ScreensaverManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'screensaver';

  Timer? _idleTimer;
  bool _active = false;
  bool _paused = false;
  double? _savedBrightness;

  /// The UI layer renders a black, tap-to-dismiss overlay while true.
  final ValueNotifier<bool> overlayActive = ValueNotifier(false);

  bool get isActive => _active;

  @override
  Future<void> init() async {
    bus.on<ActivityDetected>().listen((e) => notifyActivity(e.source));
    bus.on<MotionDetected>().listen((_) {
      if (_settings.get(defs.screensaverDismissOnMotion)) {
        notifyActivity('motion');
      }
    });
    bus.on<SettingChanged>().listen((e) {
      if (e.key.startsWith('screensaver.')) _resetIdleTimer();
    });

    commands
      ..register(Command(
        name: 'startScreensaver',
        description: 'Start the screensaver now',
        handler: (_) async {
          await start();
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'stopScreensaver',
        description: 'Dismiss the screensaver (one-shot)',
        handler: (_) async {
          await stop();
          _resetIdleTimer();
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'pauseScreensaver',
        description: 'Suppress (paused=true) or release the screensaver',
        params: const {'paused': 'true to suppress, false to release'},
        handler: (p) async {
          _paused = p['paused'] == true;
          if (_paused) {
            await stop();
          }
          _resetIdleTimer();
          return const CommandResult.ok();
        },
      ));

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
    if (!_settings.get(defs.screensaverEnabled) || _paused) return;
    final seconds = _settings.get(defs.screensaverTimeoutSeconds).toInt();
    if (seconds <= 0) return;
    _idleTimer = Timer(Duration(seconds: seconds), start);
  }

  Future<void> start() async {
    if (_active || _paused) return;
    _active = true;
    final mode = _settings.get(defs.screensaverMode);
    log.info(name, 'start ($mode)');

    final brightness =
        await commands.execute('getBrightness', const {});
    _savedBrightness = (brightness.data as num?)?.toDouble();

    if (mode == 'black') {
      overlayActive.value = true;
      await commands.execute('screenOff', const {});
    } else {
      final dim = _settings.get(defs.screensaverDimLevel).toDouble();
      await commands.execute('setBrightness', {'level': dim});
    }
    bus.publish(const ScreensaverStateChanged(active: true));
  }

  Future<void> stop() async {
    if (!_active) return;
    _active = false;
    log.info(name, 'stop');
    overlayActive.value = false;
    await commands.execute('screenOn', const {});
    if (_savedBrightness != null) {
      await commands.execute('setBrightness', {'level': _savedBrightness});
    }
    bus.publish(const ScreensaverStateChanged(active: false));
  }

  @override
  Future<void> dispose() async {
    _idleTimer?.cancel();
    overlayActive.dispose();
  }
}
