import 'dart:async' show unawaited;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../gestures/gesture_mappings.dart';
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

  /// The device-admin grant screen for "Screen off" (see MainActivity /
  /// BackgroundBridge; the Activity one shows the proper one-tap dialog).
  static const _adminChannel = MethodChannel('kiosk_satellite/admin');
  static const _backgroundChannel = MethodChannel('kiosk_satellite/background');
  static const _brightnessChannel = MethodChannel('kiosk_satellite/brightness');

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
        name: 'launchApp',
        description:
            'Open another Android app by package name, leaving the kiosk '
            'running behind it (issue #44). Fails when the package is not '
            'installed or has nothing launchable.',
        params: const {'package': 'Android package, e.g. com.android.deskclock'},
        handler: (p) async {
          final package = '${p['package'] ?? ''}'.trim();
          if (package.isEmpty) {
            return const CommandResult.fail('package required');
          }
          try {
            final launched = await _backgroundChannel
                .invokeMethod<bool>('launchApp', {'package': package});
            if (launched != true) {
              return CommandResult.fail(
                '$package is not installed, or has no app to open',
              );
            }
            log.info(name, 'opened $package');
            bus.publish(AppLaunched(package: package));
            return const CommandResult.ok();
          } on PlatformException catch (e) {
            return CommandResult.fail('could not open $package: $e');
          } on MissingPluginException {
            return const CommandResult.fail('opening apps is Android-only');
          }
        },
      ),
    );

    commands.register(
      Command(
        name: 'openUri',
        description:
            'Open a deep link or custom URI with whatever app claims it '
            '(gesture actions, issue #99). Fails when nothing on the device '
            'handles the scheme.',
        params: const {'uri': 'URI to open, e.g. myapp://path or geo:0,0'},
        handler: (p) async {
          final uri = '${p['uri'] ?? ''}'.trim();
          if (uri.isEmpty) return const CommandResult.fail('uri required');
          try {
            final opened = await _backgroundChannel
                .invokeMethod<bool>('openUri', {'uri': uri});
            if (opened != true) {
              return CommandResult.fail('nothing on the device opens $uri');
            }
            log.info(name, 'opened uri $uri');
            return const CommandResult.ok();
          } on PlatformException catch (e) {
            return CommandResult.fail('could not open $uri: $e');
          } on MissingPluginException {
            return const CommandResult.fail('opening URIs is Android-only');
          }
        },
      ),
    );

    commands.register(
      Command(
        name: 'openSystemSettings',
        description: 'Open the Android Settings app over the kiosk.',
        handler: (_) async {
          try {
            final opened = await _backgroundChannel
                .invokeMethod<bool>('openSystemSettings');
            if (opened != true) {
              return const CommandResult.fail('could not open settings');
            }
            log.info(name, 'opened Android settings');
            return const CommandResult.ok();
          } on PlatformException catch (e) {
            return CommandResult.fail('could not open settings: $e');
          } on MissingPluginException {
            return const CommandResult.fail(
              'Android settings is Android-only',
            );
          }
        },
      ),
    );

    commands.register(
      Command(
        name: 'exitApp',
        description: 'Close Kiosk Satellite',
        handler: (_) async {
          log.info(name, 'exiting application');
          // Pinned tasks refuse to be backgrounded; unpin before leaving.
          await _apply(force: false);
          // A true quit: the native side stops the foreground service (so
          // START_STICKY will not revive us), clears the task, and ends the
          // process. SystemNavigator.pop only finished the Activity and left
          // the service keeping the app alive in the background.
          try {
            await _backgroundChannel.invokeMethod<void>('exit');
          } on PlatformException catch (e) {
            log.warn(name, 'native exit failed, falling back: $e');
            await SystemNavigator.pop();
          } on MissingPluginException catch (e) {
            log.warn(name, 'native exit unavailable, falling back: $e');
            await SystemNavigator.pop();
          }
          return const CommandResult.ok();
        },
      ),
    );

    commands.register(
      Command(
        name: 'restartApp',
        description:
            'Kill and relaunch the whole app. The clean-slate recovery for '
            'anything a page reload cannot fix; the same mechanism the frame '
            'watchdog uses',
        handler: (_) async {
          // The relaunch is a background activity start from a process that
          // has just died, which Android 10+ only honors with the
          // draw-over-apps grant. Refuse up front rather than killing an app
          // that cannot come back, and send the grant screen to the device -
          // the same dance as Screen off and its admin grant. Android 9 and
          // older restart fine without it.
          final device = await commands.execute('getDeviceInfo', const {});
          final sdk = (device.data is Map)
              ? ((device.data as Map)['sdkInt'] as num?)?.toInt()
              : null;
          if (sdk != null && sdk >= 29) {
            final canReturn = await _backgroundChannel
                    .invokeMethod<bool>('canBringToFront') ??
                false;
            if (!canReturn) {
              unawaited(commands.execute('requestOsPermissions', {
                'which': ['overlay'],
              }));
              return const CommandResult.fail(
                  'Restarting needs the "Display over other apps" permission '
                  'or the app cannot bring itself back. The grant screen is '
                  'opening on the device; allow it there and retry.');
            }
          }
          log.info(name, 'restarting application');
          try {
            await _backgroundChannel.invokeMethod<void>('restartProcess');
          } on PlatformException catch (e) {
            return CommandResult.fail('restart failed: $e');
          } on MissingPluginException {
            return const CommandResult.fail('restart is Android-only');
          }
          return const CommandResult.ok();
        },
      ),
    );

    commands.register(
      Command(
        name: 'requestOsPermissions',
        description:
            'Fire the OS permission prompts on the device: microphone '
            'always; notifications, battery-optimization exemption and '
            'draw-over-apps too when full=true. The dialogs appear on the '
            'device screen; the remote wizard sends someone to tap them.',
        params: const {
          'full': 'true for the whole recommended set',
          'which':
              'explicit list of permissions to request (microphone, camera, '
              'notifications, batteryOptimizations, overlay, writeSettings, '
              'deviceAdmin); overrides full',
        },
        handler: (p) async {
          const known = <String, Permission>{
            'microphone': Permission.microphone,
            'camera': Permission.camera,
            'notifications': Permission.notification,
            'batteryOptimizations': Permission.ignoreBatteryOptimizations,
            'overlay': Permission.systemAlertWindow,
          };
          final which = p['which'];
          final wanted = which is List
              ? [
                  for (final name in which)
                    if (known.containsKey(name)) name as String,
                ]
              : p['full'] == true
              ? known.keys.toList()
              : const ['microphone'];
          final results = <String, bool>{};
          for (final name in wanted) {
            try {
              results[name] = (await known[name]!.request()).isGranted;
            } catch (_) {
              results[name] = false;
            }
          }
          // "Modify system settings" (real brightness writes) is a settings
          // Activity like the admin screen below; both go after the runtime
          // dialogs so they cannot bury them.
          final askWriteSettings =
              which is List && which.contains('writeSettings');
          if (askWriteSettings) {
            try {
              if (await _brightnessChannel.invokeMethod<bool>('canWrite') ==
                  true) {
                results['writeSettings'] = true;
              } else {
                await _brightnessChannel.invokeMethod('requestWrite');
                // Only launched: the user grants (or not) on that screen.
                results['writeSettings'] = false;
              }
            } catch (_) {
              results['writeSettings'] = false;
            }
          }
          // Device admin (the real "Screen off") is an Activity, not a
          // dialog, so it goes LAST: launched earlier it would bury the
          // runtime permission prompts. Activity channel first — Samsung
          // only shows the one-tap activation screen to a foreground
          // Activity — with the app-context fallback for a detached one.
          final askAdmin = which is List
              ? which.contains('deviceAdmin')
              : p['full'] == true;
          if (askAdmin) {
            try {
              await _adminChannel.invokeMethod('requestScreenOffAdmin');
              results['deviceAdmin'] = true;
            } catch (_) {
              try {
                await _backgroundChannel.invokeMethod(
                  'requestScreenOffAdmin',
                );
                results['deviceAdmin'] = true;
              } catch (_) {
                results['deviceAdmin'] = false;
              }
            }
          }
          return CommandResult.ok(results);
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
        case 'gesture':
          final id = '${call.arguments}';
          log.info(name, 'gesture detected: $id');
          bus.publish(GestureDetected(id: id));
        case 'backPressed':
          bus.publish(const KioskBackPressed());
      }
      return null;
    });

    bus.on<SettingChanged>().listen((e) async {
      if (!e.key.startsWith('kiosk.') &&
          !e.key.startsWith('gestures.') &&
          e.key != defs.browserCutoutMode.key) {
        return;
      }
      // Enabling the shield needs the draw-over-apps grant; fire the system
      // settings page the first time so the person is standing in front of
      // the right screen.
      if ((e.key == defs.kioskDisableStatusBar.key ||
              e.key == defs.kioskStartOnBoot.key) &&
          e.value == true) {
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
      // Back and the bar-blink watcher are tied to the master switch, not
      // their own toggles: a kiosk the back button can background — or one
      // where the bars linger — is not locked in any useful sense.
      'back': on,
      'bars': on,
      'volume': on && _settings.get(defs.kioskDisableVolume),
      'power': on && _settings.get(defs.kioskDisablePower),
      'statusBar': on && _settings.get(defs.kioskDisableStatusBar),
      'home': on && _settings.get(defs.kioskDisableHome),
      'gestureTaps': !on
          ? 0
          : switch (gesture) {
              'taps5' || 'taps5hold' => 5,
              'taps7' || 'taps7hold' => 7,
              _ => 0,
            },
      // Hold-the-last-tap variants (issue #120): tapping a dashboard
      // button repeatedly can reach any count, but never ends in a
      // deliberate hold.
      'gestureTapHold': gesture.endsWith('hold'),
      // Configurable gestures (issue #99): armed whenever any are
      // configured, kiosk mode or not. Disable Gestures is the kiosk-time
      // opt-out; the force=false bundle (app exit) disarms them like
      // everything else.
      'gestures': !force || (on && _settings.get(defs.kioskDisableGestures))
          ? const <Map<String, Object?>>[]
          : nativeGestureTriggers(
              decodeGestureMappings(_settings.get(defs.gestureMappings)),
            ),
      // Window layout, not lockdown: applied whatever the kiosk switch says,
      // including the force=false bundle on exit (the window keeps its shape).
      'cutout': _settings.get(defs.browserCutoutMode),
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
