import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// Lockdown: keeping the device in the app and the app on the device.
///
/// The declarative half lives in the Kiosk settings; this manager folds them
/// into one flag bundle and pushes it over the platform channel, where
/// KioskLock.kt does the Activity-level work (key swallowing, screen
/// re-wake, the status-bar shield, screen pinning, tap counting). The
/// gesture comes back the other way as [KioskExitGesture]; the kiosk screen
/// owns the PIN prompt and the menu it guards.
///
/// iOS has no self-lockdown for ordinary apps (Guided Access is the OS's
/// answer), so everything here is Android-only and quietly inert elsewhere.
class KioskManager extends Manager {
  KioskManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  static const _channel = MethodChannel('kiosk_satellite/kiosk_lock');

  @override
  String get name => 'kiosk';

  /// Whether lockdown is on — the kiosk screen swaps the drawer swipe for
  /// the exit gesture while this holds.
  bool get locked => _settings.get(defs.kioskEnabled);

  /// Whether [pin] matches the configured PIN. An empty setting means no
  /// PIN is asked at all.
  bool get pinRequired => _settings.get(defs.kioskPin).isNotEmpty;
  bool pinMatches(String pin) => pin == _settings.get(defs.kioskPin);

  @override
  Future<void> init() async {
    commands.register(
      Command(
        name: 'exitApp',
        description: 'Close Kiosk Satellite',
        handler: (_) async {
          log.info(name, 'exiting application');
          // Pinned tasks refuse to be backgrounded; unpin before leaving.
          await _apply(force: false);
          await SystemNavigator.pop();
          return const CommandResult.ok();
        },
      ),
    );

    if (!Platform.isAndroid) return;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'ready':
          // A fresh Activity starts unarmed; re-push the flags.
          await _apply();
        case 'exitGesture':
          log.info(name, 'exit gesture detected');
          bus.publish(const KioskExitGesture());
      }
      return null;
    });

    bus.on<SettingChanged>().listen((e) async {
      if (!e.key.startsWith('kiosk.')) return;
      // Enabling the shield needs the draw-over-apps grant; fire the system
      // settings page the first time so the person is standing in front of
      // the right screen.
      if (e.key == defs.kioskDisableStatusBar.key && e.value == true) {
        final has = await _invoke<bool>('hasOverlayPermission') ?? false;
        if (!has) await _invoke<void>('requestOverlayPermission');
      }
      await _apply();
    });

    await _apply();
  }

  /// Push the armed flags to the Activity. With [force] false the bundle is
  /// all-off regardless of settings (used on exit, where staying pinned
  /// would block the app from closing).
  Future<void> _apply({bool force = true}) async {
    if (!Platform.isAndroid) return;
    final on = force && _settings.get(defs.kioskEnabled);
    final gesture = _settings.get(defs.kioskExitGesture);
    await _invoke<void>('apply', {
      'volume': on && _settings.get(defs.kioskDisableVolume),
      'power': on && _settings.get(defs.kioskDisablePower),
      'statusBar': on && _settings.get(defs.kioskDisableStatusBar),
      'home': on && _settings.get(defs.kioskDisableHome),
      'gestureTaps': !on
          ? 0
          : switch (gesture) {
              'taps5' => 5,
              'taps7' => 7,
              _ => 0,
            },
    });
  }

  Future<T?> _invoke<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      log.warn(name, '$method failed: ${e.message}');
    } on MissingPluginException {
      // No Activity yet (cold start); its "ready" call will re-apply.
    }
    return null;
  }
}
