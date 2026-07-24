/// The name an exported configuration is saved under:
/// `ks-backup_<device>_<YYYYMMDD>_<HHmmss>.json`.
///
/// A fleet of tablets used to produce a pile of identical
/// `kiosk-satellite-config.json` files, indistinguishable once they left the
/// download folder. The device name and the moment of export go in the name
/// instead, so a directory listing is enough to tell them apart.
///
/// Underscores separate the parts, which is why the device name keeps dashes
/// inside it — the two never run together.
///
/// Mirrored in the remote admin (assets/remote-ui/index.html, exportFileName)
/// so a download from either surface lands under the same name.
String exportFileName(String deviceName, DateTime at) {
  final slug = exportNameSlug(deviceName);
  final stamp = exportTimestamp(at);
  return slug.isEmpty ? 'ks-backup_$stamp.json' : 'ks-backup_${slug}_$stamp.json';
}

/// A device name reduced to something safe on every filesystem.
///
/// Accented letters fold to their plain form first, so "Salón" reads as
/// "Salon" rather than losing the letter to a dash. Whatever is left that is
/// not a letter or digit — punctuation, emoji, scripts with no ASCII form —
/// collapses to a single dash. Case is kept: the name is there to be read.
///
/// Empty when the device has no usable name, which leaves the filename with
/// just its timestamp.
String exportNameSlug(String deviceName) {
  final buffer = StringBuffer();
  for (final rune in deviceName.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_foldedLatin[char] ?? char);
  }
  final slug = buffer
      .toString()
      .replaceAll(RegExp('[^A-Za-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  // Long enough for any real name, short enough to leave room for the rest
  // of the filename on a stricter filesystem.
  return slug.length <= 40
      ? slug
      : slug.substring(0, 40).replaceAll(RegExp(r'-+$'), '');
}

/// Accented Latin letters and their plain equivalents. Mirrored exactly in
/// the remote admin's copy, so both surfaces name the same device the same
/// way. Anything absent here is simply not a Latin letter and becomes a dash.
const _foldedLatin = <String, String>{
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ā': 'a',
  'Á': 'A', 'À': 'A', 'Â': 'A', 'Ä': 'A', 'Ã': 'A', 'Å': 'A', 'Ā': 'A',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e',
  'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E', 'Ē': 'E',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i',
  'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I', 'Ī': 'I',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ø': 'o', 'ō': 'o',
  'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Ö': 'O', 'Õ': 'O', 'Ø': 'O', 'Ō': 'O',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u',
  'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U', 'Ū': 'U',
  'ñ': 'n', 'Ñ': 'N', 'ç': 'c', 'Ç': 'C', 'ý': 'y', 'ÿ': 'y', 'Ý': 'Y',
  'š': 's', 'Š': 'S', 'ž': 'z', 'Ž': 'Z', 'ł': 'l', 'Ł': 'L',
  'đ': 'd', 'Đ': 'D', 'ß': 'ss', 'æ': 'ae', 'Æ': 'AE', 'œ': 'oe', 'Œ': 'OE',
};

/// `YYYYMMDD_HHmmss` in the device's own local time: sorts correctly in a
/// file listing and carries no characters a filesystem objects to.
String exportTimestamp(DateTime at) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${at.year}${two(at.month)}${two(at.day)}'
      '_${two(at.hour)}${two(at.minute)}${two(at.second)}';
}
