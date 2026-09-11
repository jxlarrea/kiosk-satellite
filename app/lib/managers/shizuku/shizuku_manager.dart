import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/manager.dart';
import '../wake_word/permission_descriptions.dart';

class ShizukuManager extends Manager {
  ShizukuManager(super.bus, super.commands, super.log);
  static const channel = MethodChannel('kiosk_satellite/shizuku');
  final state = ValueNotifier<Map<String, Object?>>(const {
    'status': 'checking',
  });
  bool _disposed = false;
  @override
  String get name => 'shizuku';
  @override
  Future<void> init() async {
    channel.setMethodCallHandler((call) async {
      if (!_disposed && call.method == 'state') {
        state.value = Map<String, Object?>.from(call.arguments as Map);
      }
    });
    for (final name in [
      'getShizukuState',
      'requestShizukuPermission',
      'runShizukuAction',
    ]) {
      commands.register(
        Command(
          name: name,
          description: switch (name) {
            'getShizukuState' => 'Read the device Shizuku connection.',
            'requestShizukuPermission' =>
              'Show the Shizuku permission request on this kiosk.',
            _ => 'Run a predefined Shizuku action for KS only.',
          },
          quiet: name == 'getShizukuState',
          params: name == 'runShizukuAction'
              ? const {
                  'action':
                      'grantAll, identity, microphone, batteryUnrestricted, camera, bluetooth, notification, displayOverOtherApps, writeSettings, uiGuard, deviceAdmin, allFiles, usageAccess or location',
                }
              : const {},
          handler: (args) async {
            try {
              return CommandResult.ok(
                name == 'runShizukuAction'
                    ? await run(args['action'] as String? ?? '')
                    : await refresh(
                        request: name == 'requestShizukuPermission',
                      ),
              );
            } catch (error) {
              return CommandResult.fail('$error');
            }
          },
        ),
      );
    }
  }

  Future<Map<String, Object?>> refresh({bool request = false}) async {
    final result = await channel
        .invokeMapMethod<String, Object?>(
          request ? 'requestPermission' : 'state',
        )
        .timeout(const Duration(seconds: 10));
    final value = result ?? const <String, Object?>{'status': 'unavailable'};
    if (!_disposed) state.value = value;
    return value;
  }

  Future<Map<String, Object?>> run(String action) async {
    if (action != 'grantAll' &&
        action != 'identity' &&
        !devicePermissionDescriptions.containsKey(action)) {
      throw ArgumentError('Unknown Shizuku action');
    }
    if (action == 'identity') {
      return await channel
              .invokeMapMethod<String, Object?>('runAction', {'action': action})
              .timeout(const Duration(seconds: 15)) ??
          const {};
    }
    Future<Map> readPermissions() async {
      final grants = await commands.execute('getSystemPermissions', const {});
      if (!grants.ok || grants.data is! Map) {
        throw StateError('Could not read current permissions. Try again.');
      }
      final guard = await commands.execute('hasUiGuard', const {});
      return {...grants.data as Map, 'uiGuard': guard.ok && guard.data == true};
    }

    final held = await readPermissions();
    Object? grantStatus(String key, Map values) => key == 'bluetooth'
        ? values['bluetoothPair'] ?? values[key]
        : values[key];
    final permissions = devicePermissionDescriptions.keys
        .where((key) => grantStatus(key, held) != true)
        .toList();
    final result = await channel
        .invokeMapMethod<String, Object?>('runAction', {
          'action': action,
          if (action == 'grantAll') 'permissions': permissions,
        })
        .timeout(const Duration(seconds: 180));
    final checked = await readPermissions();
    return {
      ...?result,
      if (action != 'identity')
        'results': [
          for (final row
              in (result?['results'] as List? ?? const []).whereType<Map>())
            {
              ...row,
              if (row['ok'] == true &&
                  grantStatus(row['key'] as String, checked) != true) ...{
                'ok': false,
                'error':
                    'Android has not confirmed this permission. Check Permissions Manager on the device.',
              },
            },
        ],
    };
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    channel.setMethodCallHandler(null);
    state.dispose();
  }
}
