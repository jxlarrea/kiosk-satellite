/// One address family as the entities report it (issue #213).
///
/// The raw reading is a map of interface name to the addresses on it. The
/// ESPHome protocol has no attributes, so each detail becomes its own text
/// sensor. The reading is summarized here, once, so the sensors and the
/// remote admin can never disagree about which address leads or how an
/// interface is spelled.
class IpFamily {
  const IpFamily({
    required this.primary,
    required this.byInterface,
    required this.others,
  });

  /// The address the sensor's state carries; empty when the device has no
  /// address of this family, which Home Assistant reads as unknown.
  final String primary;

  /// Every address, keyed by the interface it belongs to.
  final Map<String, List<String>> byInterface;

  /// Every address except [primary].
  final List<String> others;

  /// The interface map as one line, for a surface that can only carry a
  /// string: `wlan0: 192.168.1.5; eth0: 10.0.0.2`. Home Assistant refuses a
  /// state longer than 255 characters, so a device with more addresses than
  /// that loses whole interfaces off the end rather than the whole reading.
  String get oneLine {
    final parts = [
      for (final entry in byInterface.entries)
        if (entry.value.isNotEmpty) '${entry.key}: ${entry.value.join(", ")}',
    ];
    var line = parts.join('; ');
    while (line.length > 255 && parts.length > 1) {
      parts.removeLast();
      line = '${parts.join('; ')}; ...';
    }
    return line.length > 255 ? '${line.substring(0, 252)}...' : line;
  }
}

/// Summarizes one family of the `getIpAddresses` reading.
///
/// [preferGlobal] is for IPv6: an interface lists its link-local `fe80::`
/// address before the routable one, and the routable one is what a person
/// means by "the device's address", so it takes the state slot whenever the
/// device has one.
IpFamily summarizeIpFamily(Object? raw, {required bool preferGlobal}) {
  final byInterface = <String, List<String>>{
    if (raw is Map)
      for (final entry in raw.entries)
        if (entry.value is List)
          '${entry.key}': [
            // Dart reports IPv6 addresses with their scope id suffix
            // ("fd42::1%9", "fe80::1%wlan0"); the interface is already named
            // by the key, so the suffix is only noise in Home Assistant.
            for (final address in entry.value as List)
              if ('$address'.split('%').first.isNotEmpty)
                '$address'.split('%').first,
          ],
  };
  final all = [for (final addresses in byInterface.values) ...addresses];
  var primary = all.isEmpty ? '' : all.first;
  if (preferGlobal) {
    primary = all.firstWhere(
      (a) => !a.startsWith('fe80'),
      orElse: () => primary,
    );
  }
  return IpFamily(
    primary: primary,
    byInterface: byInterface,
    others: [
      for (final address in all)
        if (address != primary) address,
    ],
  );
}
