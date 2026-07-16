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

  /// The visual overlay the UI should render, or null for none.
  ///
  /// One of 'black' | 'clock' | 'media' | 'website'. The 'dim' mode sets no
  /// view — it only lowers the backlight — so this stays null there.
  final ValueNotifier<String?> activeView = ValueNotifier(null);

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

    switch (mode) {
      case 'dim':
        // Backlight only — no overlay. Save the level so stop() can restore it.
        final brightness = await commands.execute('getBrightness', const {});
        _savedBrightness = (brightness.data as num?)?.toDouble();
        final dim = _settings.get(defs.screensaverDimLevel).toDouble();
        await commands.execute('setBrightness', {'level': dim});
      case 'black':
        // The panel off *is* the black, and it saves the backlight. The overlay
        // is the catch: if the OS refuses screenOff, the black Container still
        // covers whatever is behind it.
        activeView.value = 'black';
        await commands.execute('screenOff', const {});
      default:
        // clock / media / website: a lit overlay showing content. The screen
        // stays at its normal brightness — dimming a clock to 10% defeats it.
        activeView.value = mode;
    }
    bus.publish(const ScreensaverStateChanged(active: true));
  }

  Future<void> stop() async {
    if (!_active) return;
    _active = false;
    log.info(name, 'stop');
    activeView.value = null;
    await commands.execute('screenOn', const {});
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
