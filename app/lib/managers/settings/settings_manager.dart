import 'package:shared_preferences/shared_preferences.dart';

import '../../core/events.dart';
import '../../core/manager.dart';
import 'definitions.dart';

export 'definitions.dart';

/// Owns persistence and change notification for every declared setting.
class SettingsManager extends Manager {
  SettingsManager(super.bus, super.commands, super.log);

  @override
  String get name => 'settings';

  late SharedPreferences _prefs;

  static const _prefix = 'ks.';

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  T get<T>(SettingDef<T> def) {
    final raw = _prefs.get(_prefix + def.key);
    // The `raw != null` guard matters: when T is inferred nullable (e.g.
    // Object? from a caller's ternary), `null is T` is true, which would
    // wrongly return null for an unstored setting instead of its default.
    if (raw != null && raw is T) return raw as T;
    // num settings may come back as int or double depending on what was set.
    if (raw is num && def.defaultValue is num) return raw as T;
    return def.defaultValue;
  }

  Future<void> set<T>(SettingDef<T> def, T value) async {
    switch (value) {
      case final bool v:
        await _prefs.setBool(_prefix + def.key, v);
      case final String v:
        await _prefs.setString(_prefix + def.key, v);
      case final num v:
        // A whole value is an int, not 10.0 — SharedPreferences keeps the two
        // apart, and get() reads back whichever was stored.
        if (v is int || v == v.roundToDouble()) {
          await _prefs.setInt(_prefix + def.key, v.toInt());
        } else {
          await _prefs.setDouble(_prefix + def.key, v.toDouble());
        }
      default:
        throw ArgumentError('unsupported setting type: $value');
    }
    log.info(name, 'set ${def.key}${def.secret ? '' : ' = $value'}');
    bus.publish(SettingChanged(key: def.key, value: value));
  }

  /// Persisted internal value not exposed in the settings UI (e.g. the
  /// remote-auth signing secret). Returns [orElse] and stores it when absent.
  Future<String> secret(String key, String Function() orElse) async {
    final existing = _prefs.getString('${_prefix}secret.$key');
    if (existing != null && existing.isNotEmpty) return existing;
    final value = orElse();
    await _prefs.setString('${_prefix}secret.$key', value);
    return value;
  }

  SettingDef<Object>? defByKey(String key) {
    for (final def in allSettings) {
      if (def.key == key) return def;
    }
    return null;
  }

  /// Set from an untyped (JSON) value — used by the remote API and import.
  Future<bool> setFromJson(String key, Object? value) async {
    final def = defByKey(key);
    if (def == null) return false;
    switch (def.type) {
      case SettingType.boolean when value is bool:
        await set(def, value);
      case SettingType.number when value is num:
        await set(def, value);
      case SettingType.string || SettingType.password when value is String:
        await set(def, value);
      case SettingType.select
          when value is String && (def.options?.contains(value) ?? false):
        await set(def, value);
      default:
        return false;
    }
    return true;
  }

  /// Snapshot of definitions + values for the remote API and settings UI.
  /// Secrets report whether they are set, never their value.
  /// Whether [def] should be shown at all: its [SettingDef.dependsOn] switch
  /// is on, or it has none.
  bool visible(SettingDef<Object> def) {
    final key = def.dependsOn;
    if (key == null) return true;
    final dep = allSettings.where((d) => d.key == key).firstOrNull;
    // A dependency that does not exist is a typo in the definitions, and
    // hiding the row would hide the evidence.
    if (dep == null) return true;
    // Transitive: the dependency must both hold *and* itself be visible, so a
    // setting can gate on a hidden flag that gates on the mode (folder
    // playlist settings → media_is_folder → mode == media).
    return get(dep) == def.dependsOnValue && visible(dep);
  }

  List<Map<String, Object?>> describe() => [
    for (final def in allSettings)
      {
        'key': def.key,
        'type': def.type.name,
        'title': def.title,
        'description': def.description,
        'category': def.category,
        if (def.section != null) 'section': def.section,
        // The remote admin renders these too, and must hide what the
        // device hides.
        if (def.dependsOn != null) 'dependsOn': def.dependsOn,
        if (def.dependsOn != null) 'dependsOnValue': def.dependsOnValue,
        if (def.hidden) 'hidden': true,
        if (def.options != null) 'options': def.options,
        // Number ranges: with min+max present the remote renders a
        // slider, exactly as the device does.
        if (def.min != null) 'min': def.min,
        if (def.max != null) 'max': def.max,
        if (def.step != null) 'step': def.step,
        if (def.unit != null) 'unit': def.unit,
        'default': def.secret ? null : def.defaultValue,
        'value': def.secret
            ? ((get(def) as String).isNotEmpty ? '__set__' : '')
            : get(def),
        'secret': def.secret,
      },
  ];

  /// Full config for provisioning. Secrets included only when [withSecrets].
  Map<String, Object?> export({bool withSecrets = false}) => {
    for (final def in allSettings)
      if (!def.secret || withSecrets) def.key: get(def),
  };

  Future<int> import(Map<String, Object?> config) async {
    var applied = 0;
    for (final entry in config.entries) {
      if (await setFromJson(entry.key, entry.value)) applied++;
    }
    return applied;
  }
}
