import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/command_registry.dart';
import '../../core/manager.dart';
import '../settings/settings_manager.dart';
import '../settings/definitions.dart' as defs;

/// Device identity and status: model, OS, app version, battery.
class DeviceManager extends Manager {
  DeviceManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;
  final _battery = Battery();

  @override
  String get name => 'device';

  late final String model;
  late final String osVersion;
  late final String appVersion;

  String get os => Platform.isAndroid ? 'android' : 'ios';

  String get deviceName {
    final configured = _settings.get(defs.deviceName);
    return configured.isNotEmpty ? configured : model;
  }

  @override
  Future<void> init() async {
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;

    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      model = '${android.manufacturer} ${android.model}';
      osVersion = 'Android ${android.version.release}';
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      model = ios.utsname.machine;
      osVersion = '${ios.systemName} ${ios.systemVersion}';
    } else {
      model = Platform.operatingSystem;
      osVersion = Platform.operatingSystemVersion;
    }
    log.info(name, '$model, $osVersion, app $appVersion');

    commands.register(Command(
      name: 'getDeviceInfo',
      description: 'Device identity and battery status',
      handler: (_) async => CommandResult.ok(await info()),
    ));
  }

  Future<Map<String, Object?>> info() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    return {
      'name': deviceName,
      'model': model,
      'os': os,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'battery': level,
      'charging': state == BatteryState.charging ||
          state == BatteryState.connectedNotCharging,
    };
  }
}
