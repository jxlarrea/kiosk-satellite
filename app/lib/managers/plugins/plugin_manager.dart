import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/manager.dart';
import 'plugin_repository.dart';

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

  static const channel = MethodChannel('kiosk_satellite/plugins');
  final installed = ValueNotifier<List<Map<String, Object?>>>(const []);
  final windows = ValueNotifier<List<PluginWindow>>(const []);
  final status = ValueNotifier<String>('');
  bool _disposed = false;

  @override
  String get name => 'plugins';

  @override
  Future<void> init() async {
    channel.setMethodCallHandler((call) async {
      if (_disposed) return;
      switch (call.method) {
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
      'listPlugins',
      'List installed plugins and their settings.',
      (_) => refresh(),
      const {},
    );
    register(
      'previewPluginRepository',
      'Read a public GitHub plugin manifest and README before installation.',
      (p) => previewRepository(p['url'] as String? ?? ''),
      const {'url': 'Public GitHub repository URL'},
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

  Future<List<Map<String, Object?>>> installRepository(
    String token, {
    required bool trusted,
  }) async {
    final args = await repository.installArguments(token, trusted: trusted);
    return update('install', args);
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

  void _readInstalled(Object? value) {
    if (value is! List) return;
    installed.value = [
      for (final item in value) Map<String, Object?>.from(item as Map),
    ];
    final running = installed.value
        .where((p) => p['running'] == true)
        .map((p) => p['id'])
        .toSet();
    windows.value = windows.value.where((w) => running.contains(w.id)).toList();
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
    repository.close();
    channel.setMethodCallHandler(null);
    try {
      await channel
          .invokeMethod<void>('stopAll')
          .timeout(const Duration(seconds: 30));
    } catch (_) {}
    installed.dispose();
    windows.dispose();
    status.dispose();
  }
}
