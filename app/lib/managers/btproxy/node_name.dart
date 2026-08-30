/// The ESPHome node name: what the kiosk calls itself on the wire.
///
/// It is not a label. The same string is the mDNS instance and the
/// `<name>.local` hostname the announcer publishes, and Home Assistant
/// builds this device's action names from it
/// (`esphome.<node with underscores>_notification`, see
/// build_service_name in its ESPHome integration). So it has to be a DNS
/// label, and it has to be unique on the network.
///
/// Home Assistant keys the config entry and every entity's unique id on
/// the MAC address, not on this, so renaming a kiosk does not orphan its
/// entities or its history. What a rename does change is the action
/// names, and automations calling the old ones stop working.
library;

/// The longest slug produced. DNS allows 63 characters in a label; this
/// leaves room and keeps the action names in Home Assistant readable.
const _maxLength = 40;

/// Accented Latin letters folded to their base, so "Cocina Pequeña"
/// becomes `cocina-pequena` rather than losing the letter (and gaining a
/// hyphen where it was).
const _fold = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ñ': 'n',
  'ç': 'c',
  'ý': 'y',
  'ÿ': 'y',
  'ß': 'ss',
};

/// The node name a fresh install takes from its device name: the slug
/// under a `ks-` prefix, so every kiosk sorts together in Home Assistant's
/// ESPHome list and the mDNS browser (`ks-amazon-kftuwi`, `ks-kitchen`).
/// A device name that already starts with "ks" ("KS Kitchen") keeps the
/// one prefix. Empty when the name has nothing usable, the caller's cue to
/// leave the generated name in place. A name typed in the Node name
/// setting itself is never prefixed; that one is taken as written.
String esphomeNodeFromDeviceName(String deviceName) {
  final slug = esphomeNodeSlug(deviceName);
  if (slug.isEmpty) return '';
  if (slug == 'ks' || slug.startsWith('ks-')) return slug;
  return 'ks-$slug';
}

/// [name] as a DNS label: lowercase, letters, digits and single hyphens.
/// Empty when nothing usable survives, which is the caller's cue to keep
/// the generated `kiosk-satellite-<id>` name.
String esphomeNodeSlug(String name) {
  final buffer = StringBuffer();
  var pendingHyphen = false;
  for (final source in name.trim().toLowerCase().runes) {
    final folded = _fold[String.fromCharCode(source)];
    final char = folded ?? String.fromCharCode(source);
    final rune = folded != null ? char.codeUnitAt(0) : source;
    final keep =
        (rune >= 0x61 && rune <= 0x7a) || (rune >= 0x30 && rune <= 0x39);
    if (keep) {
      // A separator only becomes a hyphen once something follows it, so
      // "  Kitchen  " never comes out with edges.
      if (pendingHyphen && buffer.isNotEmpty) buffer.write('-');
      pendingHyphen = false;
      buffer.write(char);
      if (buffer.length >= _maxLength) break;
    } else {
      pendingHyphen = true;
    }
  }
  return buffer.toString();
}
