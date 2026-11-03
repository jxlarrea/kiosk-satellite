import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'system_update_source.dart';

/// When Android installs its own system updates (issue #1292): the ones
/// the device maker ships, not Kiosk Satellite's (UpdateManager) or the
/// Echo image's (SystemUpdateManager).
///
/// Android asks for the restart in the notification shade. The lock task
/// kiosk mode a device owner gets hides the shade, so a downloaded update
/// waited until someone restarted the panel. The device owner can set a
/// system update policy instead. Android then installs and restarts by
/// itself, right away or in a daily window.
///
/// Only the device owner may set it. The Echo images update through their
/// own updater. Everywhere else the rows are hidden from both UIs before
/// any page renders. The policy is set at boot and on every change
/// of the three settings, so a settings import or a fleet push takes
/// effect at once. Android keeps it across reboots and clears it when the
/// app stops being the device owner.
class AndroidUpdatePolicyManager extends Manager {
  AndroidUpdatePolicyManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    Future<String?> Function()? romUpdater,
  }) : _romUpdater = romUpdater ?? RomSystemUpdateSource.detect;

  final SettingsManager _settings;
  final Future<String?> Function() _romUpdater;

  static const _background = MethodChannel('kiosk_satellite/background');

  static final _keys = {
    defs.androidUpdatePolicy.key,
    defs.androidUpdateWindowStart.key,
    defs.androidUpdateWindowEnd.key,
  };

  /// Android only; the tests flip it on against mocked channels.
  @visibleForTesting
  bool active = Platform.isAndroid;

  /// Whether this device can take the policy: the device owner, outside
  /// the Echo images.
  bool get supported => _supported;
  bool _supported = false;

  bool _echoImage = false;

  StreamSubscription<SettingChanged>? _settingSub;
  StreamSubscription<DeviceOwnerChanged>? _ownerSub;

  @override
  String get name => 'android_update';

  @override
  Future<void> init() async {
    if (!active) {
      defs.deviceHiddenKeys.addAll(_keys);
      return;
    }
    try {
      _echoImage = await _romUpdater() != null;
    } catch (_) {
      // No updater bridge: not an Echo image.
    }
    await _refresh();
    _settingSub = bus.on<SettingChanged>().listen((e) {
      if (_supported && _keys.contains(e.key)) unawaited(apply());
    });
    // Made the device owner (or no longer it) while running: the rows
    // follow and a policy saved before takes effect.
    _ownerSub = bus.on<DeviceOwnerChanged>().listen((_) => _refresh());
  }

  Future<void> _refresh() async {
    var owner = false;
    try {
      owner = await _background.invokeMethod<bool>('isDeviceOwner') ?? false;
    } on PlatformException catch (_) {
      // Not owner is the safe reading of a bridge that cannot say.
    } on MissingPluginException catch (_) {
      // Tests and non-Android hosts.
    }
    _supported = owner && !_echoImage;
    if (_supported) {
      defs.deviceHiddenKeys.removeAll(_keys);
      await apply();
    } else {
      defs.deviceHiddenKeys.addAll(_keys);
    }
  }

  /// Hands the stored policy to Android and logs what it holds after.
  @visibleForTesting
  Future<void> apply() async {
    final policy = _settings.get(defs.androidUpdatePolicy);
    final start = minutesOf(
      _settings.get(defs.androidUpdateWindowStart),
      3 * 60,
    );
    final end = minutesOf(_settings.get(defs.androidUpdateWindowEnd), 5 * 60);
    try {
      final result = await _background.invokeMapMethod<String, Object?>(
        'setSystemUpdatePolicy',
        {'policy': policy, 'start': start, 'end': end},
      );
      if (result?['ok'] == true) {
        final applied = result?['applied'];
        log.info(
          name,
          applied == 'windowed'
              ? 'Android updates install between '
                    '${_clock(start)} and ${_clock(end)}'
              : 'Android update policy: $applied',
        );
      } else {
        log.warn(
          name,
          'Android refused the update policy $policy: ${result?['error']}',
        );
      }
    } on PlatformException catch (e) {
      log.warn(name, 'Android refused the update policy $policy: $e');
    } on MissingPluginException catch (_) {
      // Tests and non-Android hosts.
    }
  }

  /// `HH:MM` as minutes after midnight, or [fallback] when it does not
  /// read as a time of day.
  @visibleForTesting
  static int minutesOf(String value, int fallback) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return fallback;
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    if (h > 23 || m > 59) return fallback;
    return h * 60 + m;
  }

  static String _clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  @override
  Future<void> dispose() async {
    await _settingSub?.cancel();
    await _ownerSub?.cancel();
  }
}
