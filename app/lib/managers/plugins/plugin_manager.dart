import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/manager.dart';
import '../../core/events.dart';
import 'plugin_repository.dart';
import 'plugin_host_api.dart';

class PluginWindow {
  const PluginWindow({
    required this.id,
    required this.title,
    required this.message,
    required this.buttonLabel,
  });
  final String id;
  final String title;
  final String message;
  final String buttonLabel;
}

/// Owns the Flutter surface of the Android plugin runtime.
class PluginManager extends Manager {
  PluginManager(
    super.bus,
    super.commands,
    super.log, {
    PluginRepository? repository,
  }) : repository = repository ?? PluginRepository();

  final PluginRepository repository;
  List<Map<String, Object?>> _entities = [];
  final _runtimeEntities = <String, List<Map<String, Object?>>>{};
  static const maxZipBytes = PluginRepository.maxPackageBytes;

  static const channel = MethodChannel('kiosk_satellite/plugins');
  final installed = ValueNotifier<List<Map<String, Object?>>>(const []);
  final charts = ValueNotifier<Map<String, List<Map<String, Object?>>>>({});
  final _runtimeSessions = <String, String>{};
  final windows = ValueNotifier<List<PluginWindow>>(const []);
  final status = ValueNotifier<String>('');
  final enabled = ValueNotifier<bool>(false);
  bool _disposed = false;
  late final PluginHostApi _hostReads;

  List<Map<String, Object?>> get actions => [
    for (final plugin in installed.value)
      for (final command
          in (plugin['commands'] as List? ?? const []).whereType<Map>())
        {
          'pluginId': plugin['id'],
          'pluginName': plugin['name'],
          'command': command['id'],
          'title': command['title'],
          'available': enabled.value && plugin['running'] == true,
          'drawer':
              ((plugin['actionOptions'] as Map?)?[command['id']]
                  as Map?)?['drawer'] ==
              true,
          'homeAssistant':
              ((plugin['actionOptions'] as Map?)?[command['id']]
                  as Map?)?['homeAssistant'] ==
              true,
        },
  ];

  List<Map<String, Object?>> get drawerActions => actions
      .where(
        (action) => action['available'] == true && action['drawer'] == true,
      )
      .toList();

  @override
  String get name => 'plugins';

  @override
  Future<void> init() async {
    _hostReads = PluginHostApi(
      commands,
      bus,
      (event) => channel.invokeMethod<void>('hostEvent', event),
    );
    channel.setMethodCallHandler((call) async {
      if (_disposed) return null;
      switch (call.method) {
        case 'hostSession':
          final data = call.arguments as Map;
          _runtimeSessions[data['id'] as String] = data['session'] as String;
          _setCharts(data['id'] as String, const []);
          _setEntities(data['id'] as String, const []);
          _hostReads.open(call.arguments as Map);
        case 'hostSessionClosed':
          final data = call.arguments as Map;
          if (_runtimeSessions[data['id']] == data['session']) {
            _runtimeSessions.remove(data['id']);
            _setCharts(data['id'] as String, const []);
            _setEntities(data['id'] as String, const []);
          }
          _hostReads.close(call.arguments as Map);
        case 'hostSubscription':
          _hostReads.subscription(call.arguments as Map);
        case 'hostCommand':
          return _hostReads.execute(call.arguments as Map);
        case 'entities':
          final data = call.arguments as Map;
          if (_runtimeSessions[data['id']] == data['session'] &&
              data['session'] != null) {
            _setEntities(data['id'] as String, data['entities'] as List);
          }
        case 'charts':
          final data = call.arguments as Map;
          if (_runtimeSessions[data['id']] == data['session'] &&
              data['session'] != null) {
            _setCharts(data['id'] as String, data['charts'] as List);
          }
        case 'changed':
          _readInstalled(call.arguments);
        case 'window':
          final data = Map<String, Object?>.from(call.arguments as Map);
          final id = data['id'] as String;
          final window = PluginWindow(
            id: id,
            title: data['title'] as String,
            message: data['message'] as String,
            buttonLabel: data['buttonLabel'] as String,
          );
          final next = [...windows.value];
          final index = next.indexWhere((w) => w.id == id);
          if (index < 0) {
            next.add(window);
          } else {
            next[index] = window;
          }
          windows.value = next;
        case 'hideWindow':
          _hide((call.arguments as Map)['id'] as String);
        case 'log':
          final data = call.arguments as Map;
          log.info('plugin:${data['id']}', '${data['message']}');
      }
      return null;
    });
    void register(
      String command,
      String description,
      Future<Object?> Function(Map<String, Object?>) action,
      Map<String, String> params,
    ) {
      commands.register(
        Command(
          name: command,
          description: description,
          // Packages and plugin settings do not belong in command logs.
          quiet: true,
          params: params,
          handler: (p) async {
            try {
              return CommandResult.ok(await action(p));
            } catch (error) {
              return CommandResult.fail(_errorText(error));
            }
          },
        ),
      );
    }

    register(
      'getPluginCharts',
      'Read current plugin chart snapshots without refreshing settings.',
      (p) async => charts.value[p['id']] ?? const [],
      const {'id': 'Plugin ID'},
    );
    register(
      'getPluginActions',
      'List declared plugin actions and their availability.',
      (_) async => actions,
      const {},
    );
    register(
      'configurePluginAction',
      'Choose where a plugin action is available.',
      (p) => update('configureAction', p),
      const {
        'id': 'Plugin ID',
        'command': 'Command ID',
        'drawer': 'Show in kiosk drawer',
        'homeAssistant': 'Expose an ESPHome button',
      },
    );
    register(
      'getPluginEntities',
      'Read active plugin entities.',
      (_) async => _entities,
      const {},
    );
    register(
      'pluginEntityCommand',
      'Send a command to an active plugin entity.',
      (p) async {
        final entity = _entities
            .where((e) => e['objectId'] == p['objectId'])
            .firstOrNull;
        if (entity == null) throw StateError('Plugin entity is not available');
        if (entity['type'] == 'button') {
          return update('execute', {
            'id': entity['pluginId'],
            'command': entity['command'],
          });
        }
        if (!const ['light', 'select'].contains(entity['type'])) {
          throw StateError('Plugin entity is read-only');
        }
        if (entity['type'] == 'select' &&
            !(entity['options'] as List).contains(p['value'])) {
          throw ArgumentError('Selection is not an advertised option');
        }
        return update('entityCommand', {
          'id': entity['pluginId'],
          'key': entity['key'],
          'type': entity['type'],
          'value': p['value'],
        });
      },
      const {
        'objectId': 'Plugin entity object ID',
        'value': 'Light command map or select option string',
      },
    );
    register(
      'listPlugins',
      'List installed plugins and their settings.',
      (_) => refresh(),
      const {},
    );
    register(
      'getPluginState',
      'Read the master plugin switch and installed plugins.',
      (_) => getState(),
      const {},
    );
    register(
      'setPluginsEnabled',
      'Enable or pause plugin execution without changing individual plugin choices.',
      (p) {
        if (p['enabled'] is! bool) {
          throw const FormatException('Missing enabled flag');
        }
        return setEnabled(p['enabled'] as bool);
      },
      const {'enabled': 'Master plugin switch'},
    );
    register(
      'previewPluginRepository',
      'Read a public GitHub plugin manifest and README before installation.',
      (p) => previewRepository(p['url'] as String? ?? ''),
      const {'url': 'Public GitHub repository URL'},
    );
    register(
      'checkPluginUpdate',
      'Check an installed plugin repository for an updated release without installing it.',
      (p) => checkUpdate(p['id'] as String? ?? ''),
      const {'id': 'Installed plugin ID'},
    );
    register(
      'installPluginRepository',
      'Install the release from a reviewed repository preview.',
      (p) => installRepository(
        p['previewId'] as String? ?? '',
        trusted: p['trusted'] == true,
      ),
      const {
        'previewId': 'ID returned by previewPluginRepository',
        'trusted': 'Explicit trust acknowledgment',
      },
    );
    register(
      'installPlugin',
      'Install a local plugin ZIP for development. New plugins start disabled. Updates preserve the enabled state.',
      (p) async {
        if (p['trusted'] != true) {
          throw StateError('Confirm that you trust the plugin author');
        }
        final data = p['data'];
        if (data is! String ||
            data.isEmpty ||
            data.length > ((maxZipBytes + 2) ~/ 3) * 4) {
          throw const FormatException('Plugin ZIP must be at most 4 MB');
        }
        return installZip(base64Decode(data), trusted: true);
      },
      const {
        'data': 'Base64-encoded plugin ZIP, at most 4 MB',
        'trusted': 'Explicit trust acknowledgment',
      },
    );
    for (final entry in {
      'enablePlugin': 'enable',
      'disablePlugin': 'disable',
      'removePlugin': 'remove',
    }.entries) {
      register(
        entry.key,
        '${entry.value} an installed plugin.',
        (p) => update(entry.value, p),
        const {'id': 'Plugin ID'},
      );
    }
    register(
      'configurePlugin',
      'Save validated plugin settings.',
      (p) => update('configure', p),
      const {'id': 'Plugin ID', 'values': 'Complete settings object'},
    );
    register(
      'runPluginCommand',
      'Run a declared command of an enabled plugin.',
      (p) => update('execute', p),
      const {
        'id': 'Plugin ID',
        'command': 'Command ID from the plugin manifest',
      },
    );
    // Plugin startup must not hold up the dashboard or remote administration.
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await update('initialize', const {});
    } catch (error) {
      if (_disposed) return;
      status.value = _errorText(error);
      log.warn(name, status.value);
    }
  }

  Future<Map<String, Object?>> previewRepository(String url) async {
    final preview = await repository.preview(url);
    final compatibility = await channel
        .invokeMapMethod<String, Object?>('validateManifest', {
          'manifest': jsonEncode(preview['manifest']),
        })
        .timeout(const Duration(seconds: 10));
    return {...preview, ...?compatibility};
  }

  Future<Map<String, Object?>> checkUpdate(String id) async {
    await refresh();
    final plugin = installed.value.where((p) => p['id'] == id).firstOrNull;
    if (plugin == null) throw StateError('Plugin is not installed');
    final source = plugin['source'];
    if (source is! Map || source['repository'] is! String) {
      throw StateError(
        'This plugin was installed from ZIP. Use Install from ZIP to update it.',
      );
    }
    final preview = await previewRepository(source['repository'] as String);
    return {
      ...preview,
      'installedVersion': plugin['version'],
      'updateAvailable': PluginRepository.hasUpdate(preview, plugin),
    };
  }

  Future<List<Map<String, Object?>>> installRepository(
    String token, {
    required bool trusted,
  }) async {
    final args = await repository.installArguments(token, trusted: trusted);
    return update('install', args);
  }

  Future<List<Map<String, Object?>>> installZipStream(
    Stream<List<int>> stream, {
    required bool trusted,
  }) async {
    if (!trusted) throw StateError('Confirm that you trust the plugin author');
    final data = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      if (data.length + chunk.length > maxZipBytes) {
        throw const FormatException('Plugin ZIP must be at most 4 MB');
      }
      data.add(chunk);
    }
    return installZip(data.takeBytes(), trusted: true);
  }

  Future<List<Map<String, Object?>>> installZip(
    Uint8List bytes, {
    required bool trusted,
  }) async {
    if (!trusted) throw StateError('Confirm that you trust the plugin author');
    if (bytes.isEmpty || bytes.length > maxZipBytes) {
      throw const FormatException('Plugin ZIP must be at most 4 MB');
    }
    return update('install', {'bytes': bytes, 'trusted': true});
  }

  Map<String, Object?> get _state => {
    'enabled': enabled.value,
    'plugins': installed.value,
  };

  Future<Map<String, Object?>> getState() async {
    await refresh();
    return _state;
  }

  Future<Map<String, Object?>> setEnabled(bool value) async {
    await update('setEnabled', {'enabled': value});
    return _state;
  }

  Future<List<Map<String, Object?>>> refresh() => update('list', const {});

  Future<List<Map<String, Object?>>> update(
    String method,
    Map<String, Object?> args,
  ) async {
    try {
      final result = await channel
          .invokeMethod<Object?>(method, args)
          .timeout(const Duration(seconds: 60));
      if (!_disposed) {
        _readInstalled(result);
        status.value = '';
      }
      return installed.value;
    } catch (error) {
      if (!_disposed) status.value = _errorText(error);
      rethrow;
    }
  }

  void _setCharts(String id, List value) {
    final next = value.map((v) => Map<String, Object?>.from(v as Map)).toList();
    if (jsonEncode(charts.value[id] ?? const []) == jsonEncode(next)) return;
    charts.value = {...charts.value}
      ..remove(id)
      ..addAll(next.isEmpty ? {} : {id: next});
  }

  void _setEntities(String id, List value) {
    final next = value.map((v) => Map<String, Object?>.from(v as Map)).toList();
    if (jsonEncode(_runtimeEntities[id] ?? const []) == jsonEncode(next)) {
      return;
    }
    if (next.isEmpty) {
      _runtimeEntities.remove(id);
    } else {
      _runtimeEntities[id] = next;
    }
    _refreshEntities();
  }

  void _readInstalled(Object? value) {
    if (value is Map) {
      enabled.value = value['enabled'] == true;
      value = value['plugins'];
    }
    if (value is! List) return;
    final items = [
      for (final item in value) Map<String, Object?>.from(item as Map),
    ];
    for (final item in items) {
      final data = item.remove('charts');
      final entities = item.remove('entities') as List? ?? const [];
      _runtimeEntities[item['id']
          as String] = enabled.value && item['running'] == true
          ? entities.map((e) => Map<String, Object?>.from(e as Map)).toList()
          : const [];
      if (!enabled.value || item['running'] != true) {
        _runtimeSessions.remove(item['id']);
      }
      _setCharts(
        item['id'] as String,
        enabled.value && item['running'] == true
            ? data as List? ?? const []
            : const [],
      );
    }
    for (final id in charts.value.keys.toList()) {
      if (!items.any((p) => p['id'] == id)) {
        _runtimeSessions.remove(id);
        _setCharts(id, const []);
      }
    }
    _runtimeEntities.removeWhere(
      (id, _) => !items.any(
        (item) => item['id'] == id && item['running'] == true && enabled.value,
      ),
    );
    installed.value = [for (final item in items) item];
    _refreshEntities();
    final running = installed.value
        .where((p) => p['running'] == true)
        .map((p) => p['id'])
        .toSet();
    windows.value = windows.value.where((w) => running.contains(w.id)).toList();
  }

  void _refreshEntities() {
    final nextEntities = <Map<String, Object?>>[
      for (final action in actions)
        if (action['available'] == true && action['homeAssistant'] == true)
          {
            'objectId':
                'plugin_${action['pluginId'].toString().replaceAll('-', '_')}___${action['command'].toString().replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}')}',
            'pluginId': action['pluginId'],
            'command': action['command'],
            'name': '${action['pluginName']}: ${action['title']}',
            'type': 'button',
            'icon': 'mdi:puzzle',
          },
      for (final plugin in installed.value)
        if (enabled.value && plugin['running'] == true)
          for (final light
              in (plugin['lights'] as List? ?? const []).whereType<Map>())
            {
              'objectId':
                  'plugin_${plugin['id'].toString().replaceAll('-', '_')}__${light['key']}',
              'pluginId': plugin['id'],
              'key': light['key'],
              'name': light['name'],
              'type': 'light',
              'icon': 'mdi:led-on',
              'colorCapable': true,
              'effects': light['effects'],
              'state': light['state'],
            },
      for (final plugin in installed.value)
        if (enabled.value && plugin['running'] == true)
          for (final entity
              in _runtimeEntities[plugin['id']] ??
                  const <Map<String, Object?>>[])
            {
              ...entity,
              'objectId':
                  'plugin_${plugin['id'].toString().replaceAll('-', '_')}____${entity['type']}_${entity['key']}',
              'pluginId': plugin['id'],
              'name': '${plugin['name']}: ${entity['name']}',
              'icon': switch (entity['type']) {
                'sensor' => 'mdi:gauge',
                'text_sensor' => 'mdi:text-box-outline',
                'binary_sensor' => 'mdi:checkbox-marked-circle-outline',
                _ => 'mdi:form-select',
              },
            },
    ];
    List<Map<String, Object?>> catalog(List<Map<String, Object?>> entries) => [
      for (final entry in entries) {...entry}..remove('state'),
    ];
    final previousEntities = _entities;
    _entities = nextEntities;
    for (final previous in previousEntities) {
      if (const [
            'sensor',
            'text_sensor',
            'binary_sensor',
            'select',
          ].contains(previous['type']) &&
          !nextEntities.any((e) => e['objectId'] == previous['objectId'])) {
        bus.publish(
          PluginEntityStateChanged(previous['objectId'] as String, null),
        );
      }
    }
    if (jsonEncode(catalog(nextEntities)) !=
        jsonEncode(catalog(previousEntities))) {
      bus.publish(const PluginEntityCatalogChanged());
    }
    for (final entity in nextEntities) {
      if (entity['type'] == 'button') continue;
      final previous = previousEntities
          .where((e) => e['objectId'] == entity['objectId'])
          .firstOrNull;
      if (previous == null ||
          jsonEncode(previous['state']) != jsonEncode(entity['state'])) {
        bus.publish(
          PluginEntityStateChanged(
            entity['objectId'] as String,
            entity['state'],
          ),
        );
      }
    }
  }

  void _hide(String id) =>
      windows.value = windows.value.where((w) => w.id != id).toList();

  Future<void> windowEvent(String id, {required bool closed}) async {
    if (closed) _hide(id);
    try {
      await channel
          .invokeMethod<void>('windowEvent', {
            'id': id,
            'event': closed ? 'window.closed' : 'window.action',
          })
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      log.warn('plugin:$id', _errorText(error));
    }
  }

  String _errorText(Object error) => error is PlatformException
      ? error.message ?? error.code
      : error is MissingPluginException
      ? 'Plugins are available on Android.'
      : '$error';

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _hostReads.dispose();
    repository.close();
    channel.setMethodCallHandler(null);
    try {
      await channel
          .invokeMethod<void>('stopAll')
          .timeout(const Duration(seconds: 30));
    } catch (_) {}
    charts.dispose();
    installed.dispose();
    windows.dispose();
    status.dispose();
    enabled.dispose();
  }
}
