import 'dart:async' show Timer, unawaited;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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
class KioskManager extends Manager with WidgetsBindingObserver {
  KioskManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  /// Armed when the app loses the foreground under lockdown (or under
  /// kiosk mode with Disable home wanted but not pinned); see
  /// [didChangeAppLifecycleState].
  Timer? _reclaimTimer;

  /// Set by the kiosk screen while its drawer or the settings are open:
  /// grant screens launched from there pause the app legitimately, and
  /// the kiosk-mode reclaim must not yank the owner out of them.
  bool menuBusy = false;

  /// The last sanctioned app launch (launcher, gesture, MQTT). A pause
  /// right after one is the launched app coming up — the launcher's
  /// auto-return owns the way back, not the reclaim.
  DateTime? _appLaunchedAt;
  static const _launchGrace = Duration(seconds: 15);

  /// Kiosk mode wants Home dead. When the pin holds, it already is; the
  /// reclaim covers the gap where pinning was declined or lost.
  bool get _kioskHomeGuard =>
      _settings.get(defs.kioskEnabled) &&
      _settings.get(defs.kioskDisableHome);

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

  /// Whether Lockdown Mode holds (discussion #143): the kiosk screen keeps
  /// a touch shield over everything and the exit gesture disables the mode
  /// instead of opening the menu.
  bool get lockdownActive => _settings.get(defs.lockdownEnabled);

  /// Taps a gesture variant needs; 0 disables the counter. Lockdown and
  /// kiosk each pick their own variant, but only one is armed at a time —
  /// the lockdown gesture replaces the kiosk one while the mode holds.
  static int gestureTapCount(String gesture) => switch (gesture) {
        'taps5' || 'taps5hold' => 5,
        'taps7' || 'taps7hold' => 7,
        _ => 0,
      };

  /// Whether [pin] matches the configured PIN. An empty setting means no
  /// PIN is asked at all.
  bool get pinRequired => _settings.get(defs.kioskPin).isNotEmpty;
  bool pinMatches(String pin) => pin == _settings.get(defs.kioskPin);

  /// Whether the System UI guard (the accessibility service that closes
  /// the notification shade and recents while protections hold) is enabled
  /// in Android's Accessibility settings.
  Future<bool> uiGuardEnabled() async =>
      await _invoke<bool>('hasUiGuard') ?? false;

  /// Open Android's Accessibility settings, where the guard is enabled.
  Future<void> openUiGuardSettings() => _invoke<void>('openUiGuardSettings');

  /// Let touches through the screen-level lockdown shield (or stop again):
  /// the exit gesture's PIN dialog is ordinary Flutter UI underneath it.
  Future<void> setLockShieldPassThrough(bool value) =>
      _invoke<void>('lockShieldPassThrough', {'value': value});

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
              'notifications, batteryOptimizations, overlay, location, '
              'writeSettings, deviceAdmin); overrides full',
        },
        handler: (p) async {
          const known = <String, Permission>{
            'microphone': Permission.microphone,
            'camera': Permission.camera,
            'notifications': Permission.notification,
            'batteryOptimizations': Permission.ignoreBatteryOptimizations,
            'overlay': Permission.systemAlertWindow,
            // Only a page ever wants this, but the Device page's permission
            // list offers it like the rest, and the remote admin can only
            // ask through this command (issue #156).
            'location': Permission.locationWhenInUse,
          };
          final which = p['which'];
          final wanted = which is List
              ? [
                  for (final name in which)
                    if (known.containsKey(name)) name as String,
                ]
              // "The recommended set" deliberately excludes location: no
              // native feature uses it, pages ask for it themselves, and an
              // unexplained location prompt during onboarding is exactly
              // the kind of thing that gets an app distrusted.
              : p['full'] == true
              ? [for (final k in known.keys) if (k != 'location') k]
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

    commands.register(
      Command(
        name: 'hasUiGuard',
        description:
            'Whether the System UI guard accessibility service is enabled '
            'in Android settings. The remote UI shows the status; enabling '
            'it can only be done on the device.',
        handler: (_) async => CommandResult.ok(await uiGuardEnabled()),
      ),
    );

    commands.register(
      Command(
        name: 'hasOverlayPermission',
        description:
            'Whether the draw-over-apps grant is held. The lockdown shield '
            'and the foreground reclaim both ride on it.',
        handler: (_) async => CommandResult.ok(
          await _invoke<bool>('hasOverlayPermission') ?? false,
        ),
      ),
    );

    commands.register(
      Command(
        name: 'openUiGuardSettings',
        description:
            'Open Android Accessibility settings on the device, where the '
            'System UI guard is enabled.',
        handler: (_) async {
          await openUiGuardSettings();
          return const CommandResult.ok();
        },
      ),
    );

    bus.on<AppLaunched>().listen((_) => _appLaunchedAt = DateTime.now());

    if (!Platform.isAndroid) return;

    WidgetsBinding.instance.addObserver(this);

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
          !e.key.startsWith('lockdown.') &&
          e.key != defs.browserCutoutMode.key) {
        return;
      }
      // Lockdown flips on: reclaim the foreground first, so an app opened
      // via the launcher or launchApp cannot sit above the shield.
      if (e.key == defs.lockdownEnabled.key && e.value == true) {
        unawaited(commands.execute('bringToFront', const {}));
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

  /// The unpinned half of lockdown's home protection: if the app loses the
  /// foreground while the mode holds (a transient-bar Home or Recents, an
  /// app another automation raised), pull it straight back. Same
  /// bringToFront the launcher's auto-return rides on, so it needs the
  /// same draw-over-apps grant, and it keeps retrying until it lands or
  /// the mode ends.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (!lockdownActive) {
        final launched = _appLaunchedAt;
        final sanctioned = launched != null &&
            DateTime.now().difference(launched) <= _launchGrace;
        if (!_kioskHomeGuard || sanctioned || menuBusy) return;
      }
      _reclaimTimer?.cancel();
      _reclaimTimer = Timer(const Duration(seconds: 1), _reclaimForeground);
    } else if (state == AppLifecycleState.resumed) {
      _reclaimTimer?.cancel();
      _reclaimTimer = null;
    }
  }

  Future<void> _reclaimForeground() async {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return;
    }
    if (!lockdownActive) {
      if (!_kioskHomeGuard || menuBusy) return;
      // Pinned means Home is already dead system-wide: whatever paused
      // the app, it was not an escape this guard needs to answer.
      if (await _invoke<bool>('isPinned') ?? false) return;
    }
    log.info(name, 'reclaiming the foreground');
    final result = await commands.execute('bringToFront', const {});
    if (result.data == false) {
      log.warn(name, 'foreground reclaim needs the draw-over-apps grant');
    }
    _reclaimTimer = Timer(const Duration(seconds: 5), _reclaimForeground);
  }

  @override
  Future<void> dispose() async {
    if (Platform.isAndroid) WidgetsBinding.instance.removeObserver(this);
    _reclaimTimer?.cancel();
    _reclaimTimer = null;
  }

  /// Push the armed flags to the Activity. With [force] false the bundle is
  /// all-off regardless of settings (used on exit, where staying pinned
  /// would block the app from closing).
  Future<void> _apply({bool force = true}) async {
    if (!Platform.isAndroid) return;
    // Lockdown arms the whole kiosk bundle without touching the persisted
    // kiosk settings: on exit the device returns to exactly the protections
    // the owner configured, kiosk mode on or off.
    final lockdown = force && _settings.get(defs.lockdownEnabled);
    final on = (force && _settings.get(defs.kioskEnabled)) || lockdown;
    // One gesture slot on the native side: while lockdown holds, its own
    // exit gesture is armed and the kiosk one stands down (the menu it
    // would open is unreachable under the shield anyway).
    final gesture = lockdown
        ? _settings.get(defs.lockdownExitGesture)
        : _settings.get(defs.kioskExitGesture);
    // The status-bar shield needs the draw-over-apps grant. The kiosk
    // toggle requests it interactively at enable time; lockdown is flipped
    // remotely with nobody cooperative in front of the device, so it takes
    // the shield only if the grant is already there and never fires the
    // grant screen for whoever is being locked out to approve.
    final shieldGranted = lockdown &&
        !_settings.get(defs.kioskDisableStatusBar) &&
        (await _invoke<bool>('hasOverlayPermission') ?? false);
    // The pin the owner asked for themselves, consent dialog and all;
    // distinct from the pin lockdown would add on top.
    final kioskHome = force &&
        _settings.get(defs.kioskEnabled) &&
        _settings.get(defs.kioskDisableHome);
    await _invoke<void>('apply', {
      // Back and the bar-blink watcher are tied to the master switch, not
      // their own toggles: a kiosk the back button can background — or one
      // where the bars linger — is not locked in any useful sense.
      'back': on,
      'bars': on,
      'volume': lockdown || (on && _settings.get(defs.kioskDisableVolume)),
      'power': lockdown || (on && _settings.get(defs.kioskDisablePower)),
      'statusBar': shieldGranted ||
          (on && _settings.get(defs.kioskDisableStatusBar)),
      'home': lockdown || kioskHome,
      // Without device ownership, pinning pops a consent dialog with a
      // "No thanks" button and printed unpin instructions — every time,
      // and shown to exactly the person lockdown is meant to lock out.
      // When the pin demand comes only from lockdown, pin silently
      // (device owner) or not at all; the lifecycle watchdog reclaims
      // the foreground instead.
      'homeSilent': lockdown && !kioskHome,
      'gestureTaps': !on ? 0 : gestureTapCount(gesture),
      // The System UI guard (accessibility service, owner-enabled once in
      // Android settings): shade slams shut whenever the status bar is
      // being protected, recents bounces under lockdown. Kiosk mode's own
      // recents defense stays the pin the owner consented to.
      'a11yShade':
          lockdown || (on && _settings.get(defs.kioskDisableStatusBar)),
      // Recents bounce: under lockdown always; under kiosk whenever
      // Disable home is wanted. No pinned check needed — a pinned device
      // never shows recents, so the guard only ever fires in the gap
      // where the pin is not holding.
      'a11yRecents': lockdown || kioskHome,
      // The screen-level shield (draw-over-apps): covers the whole display
      // above every app, so escaping the kiosk buys a screen that still
      // does not answer. Falls back to the in-app Flutter shield alone
      // when the overlay grant is missing (the native side checks).
      'lockShield': lockdown,
      'lockBlackout': lockdown && _settings.get(defs.lockdownBlackout),
      // Hold-the-last-tap variants (issue #120): tapping a dashboard
      // button repeatedly can reach any count, but never ends in a
      // deliberate hold.
      'gestureTapHold': gesture.endsWith('hold'),
      // Configurable gestures (issue #99): armed whenever any are
      // configured, kiosk mode or not. Disable Gestures is the kiosk-time
      // opt-out; the force=false bundle (app exit) disarms them like
      // everything else. Lockdown disarms them all: the exit gesture is
      // the only thing a locked screen listens for.
      'gestures': !force ||
              lockdown ||
              (on && _settings.get(defs.kioskDisableGestures))
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
