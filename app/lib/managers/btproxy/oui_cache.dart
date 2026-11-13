import 'dart:collection';
import 'dart:convert';
import 'dart:io';

/// The vendor names the online OUI lookup returned, prefix "AA:BB:CC" to
/// name.
///
/// Names live in a small file of their own and the file is written only
/// when a new name arrives, which is rare: a home holds a few hundred
/// vendors at most. Prefixes the registry does not know are kept in memory
/// only. Below Android 15 a random Bluetooth address cannot be told from a
/// public one, so a new unknown prefix turns up about once a minute all day
/// and never repeats. Saving those grew the settings file by hundreds of KB
/// and rewrote all of it every minute.
class OuiCache {
  OuiCache(this._file);

  /// Unknown prefixes remembered for this session. A rotating address is
  /// gone for good within minutes, so the oldest ones are safe to forget.
  static const maxMisses = 4096;

  /// Null keeps the names in memory only (no app directory to write to).
  final File? _file;
  final Map<String, String> _names = {};
  final LinkedHashSet<String> _misses = LinkedHashSet();

  int get nameCount => _names.length;

  /// Reads the file. [legacy] is the JSON map older builds kept in the
  /// settings store, '' for a miss: its names are folded in and written to
  /// the file.
  Future<void> load({String legacy = ''}) async {
    final file = _file;
    try {
      if (file != null && await file.exists()) {
        _names.addAll(_decode(await file.readAsString()));
      }
    } catch (_) {}
    if (legacy.isEmpty) return;
    final before = _names.length;
    for (final e in _decode(legacy).entries) {
      _names.putIfAbsent(e.key, () => e.value);
    }
    if (_names.length != before) await _write();
  }

  static Map<String, String> _decode(String json) {
    try {
      final raw = jsonDecode(json);
      if (raw is! Map) return {};
      return {
        for (final e in raw.entries)
          if (e.value is String && (e.value as String).isNotEmpty)
            '${e.key}': e.value as String,
      };
    } catch (_) {
      return {};
    }
  }

  /// The vendor name for [oui], null when unknown or never looked up.
  String? name(String oui) => _names[oui];

  /// Whether [oui] already has an answer, a name or a miss.
  bool knows(String oui) => _names.containsKey(oui) || _misses.contains(oui);

  Future<void> putName(String oui, String name) async {
    if (name.isEmpty) return putMiss(oui);
    if (_names[oui] == name) return;
    _misses.remove(oui);
    _names[oui] = name;
    await _write();
  }

  void putMiss(String oui) {
    if (_names.containsKey(oui)) return;
    _misses.add(oui);
    while (_misses.length > maxMisses) {
      _misses.remove(_misses.first);
    }
  }

  /// Written beside the file and renamed over it, so a power cut leaves
  /// the old file or the new one.
  Future<void> _write() async {
    final file = _file;
    if (file == null) return;
    await file.parent.create(recursive: true);
    final next = File('${file.path}.tmp');
    await next.writeAsString(jsonEncode(_names), flush: true);
    await next.rename(file.path);
  }
}
