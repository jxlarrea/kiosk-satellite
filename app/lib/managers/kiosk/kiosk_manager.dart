import '../../core/manager.dart';
import '../settings/settings_manager.dart';

/// Lockdown: keeping the device in the app and the app on the device.
///
/// Skeleton. Planned per platform:
///   Android — screen pinning / lock task mode (full lock task needs device
///             owner via `dpm set-device-owner`, worth supporting for
///             dedicated tablets), boot start via a BOOT_COMPLETED receiver,
///             crash-restart, exit PIN.
///   iOS     — no app can self-lock; detect and walk the user through
///             Guided Access / supervised Single App Mode instead.
class KioskManager extends Manager {
  KioskManager(super.bus, super.commands, super.log, this._settings);

  // ignore: unused_field
  final SettingsManager _settings;

  @override
  String get name => 'kiosk';

  @override
  Future<void> init() async {
    // TODO(milestone-3): platform channels for lock task / screen pinning,
    // BOOT_COMPLETED autostart, exit PIN gate for the local settings UI.
    log.info(name, 'lockdown not yet implemented');
  }
}
