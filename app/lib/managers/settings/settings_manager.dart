import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/command_registry.dart';
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

    commands
      ..register(
        Command(
          name: 'exportConfig',
          description:
              'Full configuration for backup or cloning: every setting '
              '(secrets included) plus the page\'s localStorage.',
          handler: (_) async {
            // Browser-owned; fails harmlessly when no page is up.
            final local = await commands.execute('getLocalStorage', const {});
            return CommandResult.ok({
              'kind': 'kiosk-satellite-config',
              'version': 1,
              'settings': export(withSecrets: true),
              if (local.ok && local.data is String)
                'localStorage': local.data,
            });
          },
        ),
      )
      ..register(
        Command(
          name: 'importConfig',
          description: 'Apply a configuration produced by exportConfig.',
          params: const {
            'config': 'The exported JSON object',
            'adoptIdentity':
                "take over the backup's device identity (device name, MQTT "
                'device id) as a replacement device; false keeps this '
                "device's own so the two can run side by side (default true)",
            'importLocalStorage':
                "apply the backup's page localStorage, which carries the "
                'Voice Satellite selection; false leaves it (and the '
                'satellite entity setting) alone so this device answers as '
                'its own satellite (default true)',
          },
          handler: (p) async {
            final config = p['config'];
            if (config is! Map) {
              return const CommandResult.fail('config must be an object');
            }
            if (config['kind'] != 'kiosk-satellite-config') {
              return const CommandResult.fail(
                'not a Kiosk Satellite configuration file',
              );
            }
            final settings = config['settings'];
            if (settings is! Map) {
              return const CommandResult.fail('no settings in file');
            }
            final adoptIdentity = p['adoptIdentity'] != false;
            final importLocal = p['importLocalStorage'] != false;
            // Whether this device was still unconfigured, read before the
            // import flips it: it decides the permission pass below.
            final firstSetup = get(startUrl).isEmpty;
            final map = settings.map((k, v) => MapEntry(k.toString(), v));
            // Side-by-side clone: the backup's identity must not come
            // along, or the two devices contend for one MQTT client id
            // and one discovered HA device, each override the other's
            // discovery on launch (issue #25). Dropping the keys keeps
            // this device's own name and id; a fresh device simply
            // generates a new id at the next MQTT connect.
            if (!adoptIdentity) {
              final importedId = map.remove(mqttDeviceId.key);
              final importedName = map.remove(deviceName.key);
              // A device that inherited this very identity from an older
              // verbatim clone would keep colliding by "keeping its own";
              // equality with the backup is that inheritance, so shed it
              // (the id regenerates at the next MQTT connect, the name is
              // the user's to re-set).
              if (importedId is String &&
                  importedId.isNotEmpty &&
                  get(mqttDeviceId) == importedId) {
                await set(mqttDeviceId, '');
              }
              if (importedName is String &&
                  importedName.isNotEmpty &&
                  get(deviceName) == importedName) {
                await set(deviceName, '');
              }
            }
            // Same idea for the satellite: the entity selection lives in
            // the page's localStorage plus this seed setting, and two
            // devices answering as one assist_satellite displace each
            // other mid-turn.
            if (!importLocal) {
              map.remove(haSatelliteEntity.key);
            }
            // On a first setup the start URL is held back until the very
            // end, like the wizard does: it is what flips the app to
            // configured and loads the page, whose wake-word engine
            // immediately runs its own microphone check. Android allows one
            // permission request at a time, so a page racing the prompts
            // below gets some of them silently rejected ("A request for
            // permissions is already running").
            final heldStartUrl = firstSetup ? map.remove(startUrl.key) : null;
            var applied = await import(map);
            // Stash localStorage BEFORE the reload below, so the fresh page
            // load picks it up (see BrowserManager.onPageLoaded).
            final local = config['localStorage'];
            if (importLocal && local is String && local.isNotEmpty) {
              await commands.execute('setLocalStorage', {'data': local});
            }
            // An onboarding import IS the setup, so it also does the
            // wizard's last chore: fire the OS permission prompts the
            // imported settings need (the backup carries grants only as
            // settings; the OS ones must be asked for on this device).
            // Post-setup imports skip this — that device already ran a
            // wizard, and permission Activities on every restore would be
            // noise.
            //
            // Detached, NOT awaited: the prompts are answered by a human
            // at the DEVICE, and an import that came over the remote API
            // must not hold its HTTP response hostage to them — that reads
            // as "Importing…" forever in a browser while the tablet sits
            // on a system dialog. The start URL stays sequenced after the
            // prompts (see above); callers see pendingSetup and wait for
            // the device to become configured instead.
            if (firstSetup) {
              unawaited(Future(() async {
                await commands.execute('requestOsPermissions', {
                  'which': [
                    if (get(wakeWordEnabled) || get(webMicrophone))
                      'microphone',
                    if (get(screensaverDismissOnMotion) || get(webCamera))
                      'camera',
                    if (get(wakeWordBackground)) ...[
                      'notifications',
                      'batteryOptimizations',
                    ],
                    if (get(wakeWordBackground) || get(kioskStartOnBoot))
                      'overlay',
                    'writeSettings',
                    'deviceAdmin',
                  ],
                });
                if (heldStartUrl != null) {
                  await setFromJson(startUrl.key, heldStartUrl);
                  await commands.execute('loadUrl', {'url': get(startUrl)});
                }
                log.info(name, 'imported setup finished (permissions done)');
              }));
              log.info(
                  name,
                  'imported configuration ($applied settings); permission '
                  'prompts continue on the device');
              return CommandResult.ok({
                'applied': applied,
                'pendingSetup': heldStartUrl != null,
              });
            }
            // The imported start URL should be what ends up on screen.
            if (settings.containsKey(startUrl.key)) {
              await commands.execute('loadUrl', {'url': get(startUrl)});
            }
            log.info(name, 'imported configuration ($applied settings)');
            return CommandResult.ok({'applied': applied});
          },
        ),
      );
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

  /// Internal string value with no settings row (state, not preference).
  /// Empty string and absent are the same thing: nothing pending.
  String internal(String key) =>
      _prefs.getString('${_prefix}internal.$key') ?? '';

  Future<void> setInternal(String key, String value) async {
    if (value.isEmpty) {
      await _prefs.remove('${_prefix}internal.$key');
    } else {
      await _prefs.setString('${_prefix}internal.$key', value);
    }
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
    if (def.validator?.call(value) != null) return false;
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
        if (def.multiline) 'multiline': true,
        if (def.placeholder != null) 'placeholder': def.placeholder,
        if (def.options != null) 'options': def.options,
        if (def.optionLabels != null) 'optionLabels': def.optionLabels,
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
