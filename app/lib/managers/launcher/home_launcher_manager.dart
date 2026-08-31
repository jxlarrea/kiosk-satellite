import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// The home-launcher role (issue #219): registering the kiosk as the
/// device's home screen, replacing the OEM launcher. The system then starts
/// the kiosk at boot itself and every HOME press lands back on it, with
/// no screen pinning and no consent dialog.
///
/// The native half is HomeRole (the alias, the per-device acquisition
/// paths, the structural release) and HomeFuse (the crash-loop fuse that
/// hands HOME back to the OEM launcher when the kiosk cannot boot). This
/// manager is the single funnel: the device UI, the remote admin and a
/// settings import all flip home.enabled, and the SettingChanged listener
/// here is what acts on it. Release deliberately rides the engine-scoped
/// background channel so the remote rescue works with no Activity alive.
class HomeLauncherManager extends Manager {
  HomeLauncherManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  static const _background = MethodChannel('kiosk_satellite/background');

  /// Outbound-only: the handler on this channel is KioskManager's, which
  /// forwards the role relays as bus events.
  static const _lock = MethodChannel('kiosk_satellite/kiosk_lock');

  /// Internal key remembering who was the home screen before the takeover.
  /// Cosmetic: release lands there immediately instead of on the next
  /// HOME press. The undo itself never depends on it.
  static const _previousKey = 'home.previous_launcher';

  /// Internal key carrying the fuse's reason after a trip, so the
  /// settings row can explain itself after the native marker is cleared.
  static const _fuseReasonKey = 'home.fuse_reason';

  /// Whether the kiosk is the device's home screen right now, cached for the
  /// synchronous readers: the kiosk screen's PopScope must refuse the
  /// system pop while the role is held (a home screen never finishes on
  /// back), and predictive back asks before any channel round trip could
  /// answer. Updated from every native status read and role relay.
  final roleHeld = ValueNotifier<bool>(false);

  StreamSubscription<SettingChanged>? _settingSub;
  StreamSubscription<HomeRoleChanged>? _roleSub;

  /// The role machinery is Android's; the headless tests flip this on to
  /// drive it against mocked channels (KioskManager.pushFlags precedent).
  @visibleForTesting
  bool active = Platform.isAndroid;

  @override
  String get name => 'home';

  @override
  Future<void> init() async {
    commands.register(
      Command(
        name: 'homeLauncherStatus',
        description:
            'The home-launcher role as the device sees it: {enabled, '
            'supported, reason, held, defaultHome, deviceOwner, '
            'fuseTripped, fuseReason, roleDenials}.',
        handler: (_) async => CommandResult.ok(await _status()),
      ),
    );

    commands.register(
      Command(
        name: 'acquireHomeRole',
        description:
            'Ask the device to make Kiosk Satellite the home screen. Silent '
            'with device ownership; otherwise the system dialog or home '
            'settings open on the device for someone to confirm.',
        handler: (_) async {
          final status = await _status();
          if (status['supported'] != true) {
            return const CommandResult.fail(
              'this device does not allow changing the home screen',
            );
          }
          if (await _acquire(deviceOwner: status['deviceOwner'] == true)) {
            return const CommandResult.ok();
          }
          return const CommandResult.fail(
            'could not start the home role request; is the kiosk on screen?',
          );
        },
      ),
    );

    commands.register(
      Command(
        name: 'releaseHomeRole',
        description:
            'Stop being the home screen and hand the screen back to the '
            'previous launcher. Works with the kiosk UI unreachable: this '
            'is the remote recovery lever.',
        handler: (_) async {
          // Through the setting when it is on, so every surface tells the
          // truth; straight to native when it is already off (a stuck
          // alias, a manual rescue).
          if (_settings.get(defs.homeLauncherEnabled)) {
            await _settings.set(defs.homeLauncherEnabled, false);
          } else {
            await _release();
          }
          return const CommandResult.ok();
        },
      ),
    );

    if (!active) return;

    _settingSub = bus.on<SettingChanged>().listen((e) async {
      if (e.key != defs.homeLauncherEnabled.key) return;
      if (e.value == true) {
        final status = await _status();
        if (status['supported'] != true) {
          // The rows are hidden on such a device, so this write came in
          // raw (the API, an import). Storing an intent the device can
          // never honor would leave every surface lying; revert it.
          log.warn(
            name,
            'home launcher enable rejected: this device does not allow '
            'changing the home screen (${status['reason']})',
          );
          await _settings.set(defs.homeLauncherEnabled, false);
          return;
        }
        // A deliberate enable is the fuse's reset, and the moment to
        // remember who the launcher was.
        await _settings.setInternal(_fuseReasonKey, '');
        await _invoke<bool>('homeFuseClear');
        final current = status['defaultHome'];
        if (current is String &&
            current.isNotEmpty &&
            current != 'me.jxl.kiosk_satellite') {
          await _settings.setInternal(_previousKey, current);
        }
        await _acquire(deviceOwner: status['deviceOwner'] == true);
      } else {
        await _release();
      }
    });

    _roleSub = bus.on<HomeRoleChanged>().listen((e) {
      roleHeld.value = e.held;
      log.info(
        name,
        e.held
            ? 'Kiosk Satellite is now the home screen'
            : 'home role not granted',
      );
    });

    // Boot reconciliation.
    final status = await _status();
    if (status['supported'] != true) {
      // An unsupported device gets no toggle at all (user-decided): the
      // rows disappear from both UIs before any page renders, and only
      // the status row stays to say why. Runs in init like the person
      // sensor's gate, so nothing ever flashes. A stored true (a config
      // imported from a supported device) is cleared so no surface
      // claims an intent this device cannot honor.
      defs.deviceHiddenKeys
        ..add(defs.homeLauncherEnabled.key)
        ..add(defs.homeKeepPinning.key);
      if (_settings.get(defs.homeLauncherEnabled)) {
        log.warn(
          name,
          'home launcher was on in the stored settings but this device '
          'does not allow changing the home screen (${status['reason']}); '
          'turning it off',
        );
        await _settings.set(defs.homeLauncherEnabled, false);
      }
      return;
    }
    if (status['fuseTripped'] == true) {
      // The fuse gave HOME back to the OEM launcher while Dart was in no
      // state to be asked. Surface it loudly and make the stored setting
      // match what the device is actually doing.
      final reason = '${status['fuseReason'] ?? ''}';
      log.error(
        name,
        reason.isEmpty
            ? 'home launcher was disabled automatically after repeated '
                  'failed starts'
            : reason,
      );
      await _settings.setInternal(
        _fuseReasonKey,
        reason.isEmpty ? 'disabled after repeated failed starts' : reason,
      );
      await _invoke<bool>('homeFuseClear');
      if (_settings.get(defs.homeLauncherEnabled)) {
        await _settings.set(defs.homeLauncherEnabled, false);
      }
    } else if (_settings.get(defs.homeLauncherEnabled) &&
        status['aliasEnabled'] != true) {
      // A settings import (or restore) landed on a device whose alias was
      // never enabled: re-engage. Silent where possible; otherwise the
      // status row carries the call to action.
      log.info(name, 're-enabling the home alias after a settings import');
      if (status['deviceOwner'] == true) {
        await _invoke<bool>('homeRoleAcquireSilent');
      } else {
        await _invoke<bool>('homeAliasEnable');
      }
    }
  }

  /// The stored fuse explanation for the settings row, empty when none.
  String get storedFuseReason => _settings.internal(_fuseReasonKey);

  Future<Map<String, Object?>> _status() async {
    final raw = await _invoke<Map<Object?, Object?>>('homeRoleStatus');
    if (raw != null) roleHeld.value = raw['held'] == true;
    return {
      'enabled': _settings.get(defs.homeLauncherEnabled),
      'storedFuseReason': storedFuseReason,
      if (raw != null)
        for (final entry in raw.entries) '${entry.key}': entry.value,
    };
  }

  /// Start the acquisition that fits the device. Returns whether anything
  /// was set in motion (the role itself may still need a tap on device).
  Future<bool> _acquire({required bool deviceOwner}) async {
    if (deviceOwner) {
      final ok = await _invoke<bool>('homeRoleAcquireSilent') ?? false;
      if (ok) {
        roleHeld.value = true;
        // Taking the role only changes what HOME resolves to; nothing
        // launches. A silent enable is a remote one by nature, the
        // device may have no home button (an Echo Show), and whoever
        // flipped it expects the kiosk on screen, so finish the job.
        unawaited(commands.execute('bringToFront', const {}));
      }
      return ok;
    }
    // The dialog needs a foreground Activity; the kiosk_lock channel only
    // has a native handler while one is attached, so a headless flip
    // stays staged and the status row finishes the job on device.
    try {
      await _lock.invokeMethod<bool>('homeRoleRequest');
      return true;
    } on MissingPluginException {
      log.info(
        name,
        'home role staged: no kiosk screen up to show the system dialog',
      );
      return false;
    } on PlatformException catch (e) {
      log.warn(name, 'home role request failed: $e');
      return false;
    }
  }

  Future<void> _release() async {
    final previous = _settings.internal(_previousKey);
    await _invoke<bool>('homeRoleRelease', {
      'previous': previous.isEmpty ? null : previous,
    });
    roleHeld.value = false;
    log.info(name, 'home role released');
  }

  Future<T?> _invoke<T>(String method, [Object? args]) async {
    try {
      return await _background.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      log.warn(name, '$method failed: $e');
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    await _settingSub?.cancel();
    await _roleSub?.cancel();
  }
}
