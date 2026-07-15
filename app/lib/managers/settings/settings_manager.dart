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
    if (raw is T) return raw;
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
        await _prefs.setDouble(_prefix + def.key, v.toDouble());
      default:
        throw ArgumentError('unsupported setting type: $value');
    }
    log.info(name, 'set ${def.key}${def.secret ? '' : ' = $value'}');
    bus.publish(SettingChanged(key: def.key, value: value));
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
      case SettingType.string ||
            SettingType.password when value is String:
        await set(def, value);
      case SettingType.select
          when value is String &&
              (def.options?.contains(value) ?? false):
        await set(def, value);
      default:
        return false;
    }
    return true;
  }

  /// Snapshot of definitions + values for the remote API and settings UI.
  /// Secrets report whether they are set, never their value.
  List<Map<String, Object?>> describe() => [
        for (final def in allSettings)
          {
            'key': def.key,
            'type': def.type.name,
            'title': def.title,
            'description': def.description,
            'category': def.category,
            if (def.options != null) 'options': def.options,
            'default': def.secret ? null : def.defaultValue,
            'value': def.secret
                ? ((get(def) as String).isNotEmpty ? '__set__' : '')
                : get(def),
            'secret': def.secret,
          }
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
