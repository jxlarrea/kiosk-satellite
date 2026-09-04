/// Turns the raw facts the native Bluetooth tracker records about a device
/// (broadcast name, manufacturer company IDs, service UUIDs) into the best
/// honest identity line the Nearby devices list can show.
///
/// This is deliberately a judgment layer over the relay, never part of it:
/// the proxy forwards advertisements to Home Assistant untouched, and these
/// labels exist only in Kiosk Satellite's own list and Nearby devices sensor.
///
/// Sources, in order of trust: the name the device broadcasts, the service
/// UUID (identifies a device class even on anonymous devices), the
/// Bluetooth SIG company ID behind its manufacturer data, and finally the
/// optional OUI vendor looked up online for public addresses.
library;

/// Bluetooth SIG company identifiers seen in the wild around smart homes,
/// plus a few unregistered IDs vendors squat on (Govee, EcoFlow). Small on
/// purpose: this names what a Home Assistant household actually hears, not
/// the whole registry.
const Map<int, String> companyNames = {
  6: 'Microsoft',
  76: 'Apple',
  117: 'Samsung',
  224: 'Google',
  135: 'Garmin',
  89: 'Nordic Semiconductor',
  301: 'Sony',
  15: 'Broadcom',
  196: 'LG',
  741: 'Espressif',
  911: 'Xiaomi',
  349: 'Tile',
  1447: 'Shelly',
  2409: 'SwitchBot',
  1744: 'VeSync (Levoit/Etekcity)',
  34883: 'Govee',
  46517: 'EcoFlow',
  60552: 'Victron',
  2338: 'Amazon',
  257: 'Logitech',
  1177: 'iRobot',
  474: 'Fitbit',
  220: 'Oura',
  107: 'Polar',
  920: 'IKEA',
  1508: 'Sonos',
  57: 'Bose',
  85: 'Plantronics',
  29: 'Qualcomm',
  2: 'Intel',
};

/// 16-bit service UUIDs that identify a device class outright. These beat
/// company IDs: an anonymous advertisement carrying the BTHome UUID is a
/// BTHome sensor whoever made it.
const Map<String, String> serviceNames = {
  'fcd2': 'BTHome sensor',
  'fe95': 'Xiaomi sensor',
  'fd3d': 'SwitchBot',
  'fdcd': 'Qingping sensor',
  'fef3': 'Google/Nest device',
  'feaa': 'Eddystone beacon',
  'fe2c': 'Google Fast Pair device',
  'fcb2': 'Apple Find My device',
  'fd6f': 'Exposure notification (phone)',
  'fe24': 'August/Yale lock',
  'fe0f': 'Philips Hue',
  'fe03': 'Amazon device',
  'fd5a': 'Samsung SmartThings',
  'fe9f': 'Google Nest',
  'feed': 'Tile tracker',
  'fd44': 'Apple CarPlay',
  '1812': 'Input device (remote/keyboard)',
  '180d': 'Heart rate sensor',
  '181a': 'Environmental sensor',
  'fe61': 'Logitech',
  'fe07': 'Sonos',
};

/// Apple manufacturer-data frame types (the first payload byte). One
/// company ID covers everything Apple ships; the frame type is what tells
/// an idle iPhone from an AirTag.
const Map<int, String> appleFrames = {
  0x02: 'Apple iBeacon',
  0x05: 'Apple AirDrop',
  0x07: 'Apple AirPods',
  0x09: 'Apple AirPlay',
  0x0c: 'Apple Handoff',
  0x10: 'Apple device',
  0x12: 'Apple Find My device',
};

/// One identified nearby device, ready for the UI row and the Nearby
/// devices sensor.
class NearbyDevice {
  const NearbyDevice({
    required this.address,
    required this.identity,
    required this.rotating,
    required this.rssi,
    required this.lastSeenAt,
    this.connected = false,
    this.broadcastName,
    this.vendor,
  });

  final String address;

  /// The best label available: broadcast name, else class/vendor guess.
  final String identity;

  /// An active GATT connection is being carried for this device right now.
  final bool connected;

  /// True for resolvable-private addresses: the MAC changes periodically,
  /// so this row is an appearance, not a stable device.
  final bool rotating;
  final int rssi;
  final DateTime lastSeenAt;
  final String? broadcastName;

  /// Manufacturer, from tables or the OUI lookup. Null when unknown.
  final String? vendor;

  Map<String, Object?> toJson() => {
    'mac': address,
    'identity': identity,
    if (broadcastName != null) 'name': broadcastName,
    if (vendor != null) 'vendor': vendor,
    if (rotating) 'rotating': true,
    if (connected) 'connected': true,
    'rssi': rssi,
    'last_seen': lastSeenAt.toIso8601String(),
  };
}

/// Whether [address] can be looked up in an OUI registry at all: only
/// globally administered unicast addresses carry a real vendor prefix.
/// Rotating private addresses and synthetic MACs set the locally
/// administered bit and would return garbage.
bool hasRealOui(String address) {
  final first = int.tryParse(address.split(':').first, radix: 16);
  if (first == null) return false;
  return (first & 0x02) == 0 && (first & 0x01) == 0;
}

/// The OUI prefix ("AA:BB:CC") used as the lookup and cache key.
String ouiOf(String address) =>
    address.split(':').take(3).join(':').toUpperCase();

/// Orders the Nearby devices list (as the JSON maps [NearbyDevice.toJson]
/// produces) by the user's chosen sort. Shared by the on-device list; the
/// remote UI mirrors the same rules in its own renderer.
///
/// Ties fall back to the address so the order is stable between refreshes:
/// a list that reshuffles under the reader every ten seconds is unusable
/// whatever the primary key.
List<Map<String, Object?>> sortNearbyJson(
  List<Map<String, Object?>> devices,
  String mode,
) {
  // Actively connected devices always lead, whatever the sort: they are
  // the ones the proxy is serving right now, there are at most a few, and
  // they must never fall past the list's display cap.
  final connected = [
    for (final d in devices)
      if (d['connected'] == true) d,
  ];
  final rest = [
    for (final d in devices)
      if (d['connected'] != true) d,
  ];
  return [..._sortByMode(connected, mode), ..._sortByMode(rest, mode)];
}

List<Map<String, Object?>> _sortByMode(
  List<Map<String, Object?>> devices,
  String mode,
) {
  final sorted = List<Map<String, Object?>>.of(devices);
  int byMac(Map<String, Object?> a, Map<String, Object?> b) =>
      '${a['mac']}'.compareTo('${b['mac']}');
  switch (mode) {
    case 'name':
      // Alphabetical by the shown label; unknowns sink to the bottom
      // rather than clustering under U.
      sorted.sort((a, b) {
        final an = '${a['identity']}'.toLowerCase();
        final bn = '${b['identity']}'.toLowerCase();
        final aUnknown = an.startsWith('unknown');
        final bUnknown = bn.startsWith('unknown');
        if (aUnknown != bUnknown) return aUnknown ? 1 : -1;
        final cmp = an.compareTo(bn);
        return cmp != 0 ? cmp : byMac(a, b);
      });
    case 'mac':
      sorted.sort(byMac);
    case 'rssi':
      // Strongest first: the devices actually in this room on top.
      sorted.sort((a, b) {
        final cmp = ((b['rssi'] as int?) ?? -128).compareTo(
          (a['rssi'] as int?) ?? -128,
        );
        return cmp != 0 ? cmp : byMac(a, b);
      });
    default:
      // last_seen: newest first, the order the tracker already emits;
      // re-sorted anyway so a stale caller cannot depend on luck.
      sorted.sort((a, b) {
        final cmp = '${b['last_seen']}'.compareTo('${a['last_seen']}');
        return cmp != 0 ? cmp : byMac(a, b);
      });
  }
  return sorted;
}

/// Buckets an RSSI into the three signal tiers the Nearby devices list
/// colors. BLE through domestic walls: -65 dBm and better is same-room
/// reception that never drops, down to -84 is an adjacent room and still
/// dependable for sensors, -85 and below is the edge of range where
/// advertisements start going missing. Both UIs map these to their
/// green/yellow/red.
String rssiTier(int rssi) => rssi >= -65
    ? 'strong'
    : rssi >= -84
    ? 'medium'
    : 'weak';

/// Whether [address] is a resolvable private address: top two bits 01.
/// Only these actually rotate; static random addresses (top bits 11, most
/// Govee/Nordic sensors) are stable for the device's lifetime, and marking
/// them "rotating" would wrongly dismiss a perfectly trackable sensor.
bool isRotatingAddress(String address) {
  final first = int.tryParse(address.split(':').first, radix: 16);
  if (first == null) return false;
  return (first & 0xC0) == 0x40;
}

/// Classifies one entry from the native tracker. [ouiVendor] is the cached
/// online lookup result for this address's OUI, when the user opted in and
/// one exists.
NearbyDevice classify(
  Map<dynamic, dynamic> raw, {
  String? ouiVendor,
  DateTime? now,
}) {
  final address = '${raw['address'] ?? ''}';
  final name = (raw['name'] as String?)?.trim();
  final companies = [
    for (final id in (raw['companies'] as List? ?? const [])) id as int,
  ];
  final uuids = [
    for (final u in (raw['uuids'] as List? ?? const [])) '$u'.toLowerCase(),
  ];
  final firstBytes = {
    for (final e in (raw['firstBytes'] as Map? ?? const {}).entries)
      int.tryParse('${e.key}') ?? -1: e.value as int,
  };

  // Vendor line: tables first, the online OUI answer as the fallback for
  // hardware nothing here recognizes.
  String? vendor;
  for (final id in companies) {
    vendor ??= companyNames[id];
  }
  vendor ??= ouiVendor;

  // Class line: what kind of thing this is, when anything says so.
  String? kind;
  for (final uuid in uuids) {
    kind ??= serviceNames[uuid];
  }
  if (kind == null && companies.contains(76)) {
    kind = appleFrames[firstBytes[76]] ?? 'Apple device';
  }
  kind ??= switch (vendor) {
    'Microsoft' => 'Windows PC',
    'Samsung' => 'Samsung device',
    'Google' => 'Google device',
    null => null,
    _ => '$vendor device',
  };

  final identity = (name != null && name.isNotEmpty)
      ? name
      : kind ?? 'Unknown device';

  final addressType = raw['addressType'] as int? ?? 0;
  final lastSeenMs = raw['lastSeenAt'] as int? ?? 0;
  return NearbyDevice(
    address: address,
    identity: identity,
    connected: raw['connected'] == true,
    broadcastName: (name != null && name.isEmpty) ? null : name,
    vendor: vendor,
    // Only anonymous devices earn the rotating mark. The top-bits check
    // cannot tell a public OUI that happens to start with 01 (Govee's
    // 5C:E7:53) from a true resolvable private address on Android
    // versions that hide the link-layer address type, and a broadcast
    // name is the practical tiebreak: the anonymous rotating crowd
    // (phones, watches, trackers) never carries one.
    rotating:
        addressType == 1 &&
        isRotatingAddress(address) &&
        (name == null || name.isEmpty),
    rssi: raw['rssi'] as int? ?? 0,
    lastSeenAt: lastSeenMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(lastSeenMs)
        : (now ?? DateTime.now()),
  );
}
