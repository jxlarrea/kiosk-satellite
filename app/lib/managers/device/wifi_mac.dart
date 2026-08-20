import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'device_details.dart';

/// The adopted real-MAC identity (issue #252), or null while the setting is
/// off or the platform will not reveal the address.
///
/// Adoption is one-time: the first successful read is stored and every later
/// call returns the stored value without asking the platform again. That
/// keeps the identity stable across the ways the address could later become
/// unreadable (an OS upgrade past the API cutoffs, device ownership removed)
/// or change (a USB Wi-Fi adapter) — Home Assistant keys the device entry on
/// this value, and an identity that shifts under it orphans the entry.
///
/// Shared by the ESPHome identity and the MQTT discovery device block, so
/// both integrations land on the same Home Assistant device.
Future<String?> adoptedWifiMac(SettingsManager settings) async {
  if (!settings.get(defs.esphomeRealMac)) return null;
  final stored = settings.internal('esphome_adopted_mac');
  if (stored.isNotEmpty) return stored;
  final mac = await DeviceDetails.wifiMac();
  if (mac == null || mac.isEmpty) return null;
  await settings.setInternal('esphome_adopted_mac', mac);
  return mac;
}
