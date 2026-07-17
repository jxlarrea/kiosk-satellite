import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:battery_plus/battery_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/command_registry.dart';
import '../../core/manager.dart';
import '../settings/settings_manager.dart';
import '../settings/definitions.dart' as defs;
import 'device_details.dart';

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
  late final String packageName;
  late final String buildNumber;

  /// The licensing Device ID, `XXXX-XXXX-XXXX-XXXX`.
  ///
  /// Derived (hashed) from the SSAID, so it survives a reinstall and even a
  /// cleared app storage — a license bound to it stays bound to the device.
  /// Where the platform has no SSAID the seed is random and persisted
  /// instead, which is as stable as the app's data. The raw SSAID never
  /// leaves the device; only the hash does.
  late final String deviceId;

  /// Android API level, or null off Android. Worth reporting: most of what
  /// bites a kiosk on this platform is versioned by it, not by the marketing
  /// number — background limits, foreground-service types, permission rules.
  int? sdkInt;

  /// Whether this is a debug or a release build.
  ///
  /// Not cosmetic: a release build sends its logs to the remote admin and *not*
  /// to logcat (see Logger._add), so someone holding an adb cable and seeing
  /// silence needs to know which of the two they are looking at.
  String get buildMode => kDebugMode ? 'debug' : 'release';

  String get os => Platform.isAndroid ? 'android' : 'ios';

  String get deviceName {
    final configured = _settings.get(defs.deviceName);
    return configured.isNotEmpty ? configured : model;
  }

  @override
  Future<void> init() async {
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    packageName = packageInfo.packageName;
    buildNumber = packageInfo.buildNumber;

    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      model = '${android.manufacturer} ${android.model}';
      osVersion = 'Android ${android.version.release}';
      sdkInt = android.version.sdkInt;
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      model = ios.utsname.machine;
      osVersion = '${ios.systemName} ${ios.systemVersion}';
    } else {
      model = Platform.operatingSystem;
      osVersion = Platform.operatingSystemVersion;
    }
    deviceId = await _deriveDeviceId();
    log.info(name, '$model, $osVersion, app $appVersion, id $deviceId');

    commands.register(
      Command(
        name: 'getDeviceDetails',
        description:
            'Memory, storage, panel, WebView and build details. Fields '
            'Android will not give an app come back null rather than as a '
            'placeholder — see DeviceDetails.',
        handler: (_) async =>
            CommandResult.ok((await DeviceDetails.read()).toJson()),
      ),
    );

    commands.register(
      Command(
        name: 'getDeviceInfo',
        description: 'Device identity and battery status',
        handler: (_) async => CommandResult.ok(await info()),
      ),
    );

    commands.register(
      Command(
        name: 'getStats',
        description:
            'Battery, CPU load and temperature only — the live header '
            'numbers, without everything else getDeviceInfo gathers.',
        handler: (_) async => CommandResult.ok(await stats()),
      ),
    );
  }

  Future<String> _deriveDeviceId() async {
    var seed = await DeviceDetails.androidId();
    if (seed == null || seed.isEmpty) {
      // No SSAID to derive from: fall back to a random seed persisted with
      // the settings. Weaker (cleared app data mints a new identity), but
      // only reachable off Android.
      seed = await _settings.secret('device_id_seed', () {
        final random = Random.secure();
        return base64Url.encode(
          List<int>.generate(16, (_) => random.nextInt(256)),
        );
      });
    }
    // Salted so the ID is this app's identity, not a re-usable device
    // fingerprint; 64 bits of the digest is plenty to never collide across
    // any realistic install base and stays short enough to read out loud.
    final digest = sha256.convert(utf8.encode('kiosk-satellite:$seed')).bytes;
    final hex = [
      for (final b in digest.take(8))
        b.toRadixString(16).padLeft(2, '0').toUpperCase(),
    ].join();
    return [for (var i = 0; i < 16; i += 4) hex.substring(i, i + 4)].join('-');
  }

  /// The three live numbers the admin header shows. Its own read because the
  /// remote admin polls this every few seconds: [info] walks every network
  /// interface (twice) and queries the package on each call, all to produce
  /// fields a stats tick throws away.
  Future<Map<String, Object?>> stats() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    final cpu = await DeviceDetails.cpu();
    return {
      'battery': level,
      'charging':
          state == BatteryState.charging ||
          state == BatteryState.connectedNotCharging,
      'cpu': cpu['usage'],
      'temp': cpu['temp'],
    };
  }

  /// Every non-loopback IPv6 address, in interface order.
  ///
  /// All of them, link-local included: on a kiosk the interesting question is
  /// usually "what can reach this thing", and a device with a global address
  /// and a stale link-local one looks identical from here unless both are
  /// shown. Empty when the network has no IPv6 at all, which is not an error.
  Future<List<String>> ipv6Addresses() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv6,
        includeLoopback: false,
        // Off by default in Dart, which quietly drops every fe80:: address —
        // the device reports them, we just would not have. They are worth
        // listing: a device with a global address and a link-local one that no
        // longer routes looks identical from here unless both are shown.
        includeLinkLocal: true,
      );
      return [
        for (final interface in interfaces)
          for (final address in interface.addresses) address.address,
      ];
    } catch (e) {
      log.warn(name, 'ipv6Addresses failed: $e');
      return const [];
    }
  }

  /// First non-loopback IPv4 address, or null (e.g. no network).
  Future<String?> ipAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          return address.address;
        }
      }
    } catch (e) {
      log.warn(name, 'ipAddress failed: $e');
    }
    return null;
  }

  Future<Map<String, Object?>> info() async {
    return {
      ...await stats(),
      'name': deviceName,
      'deviceId': deviceId,
      'ip': await ipAddress(),
      'ipv6': await ipv6Addresses(),
      'model': model,
      'os': os,
      'osVersion': osVersion,
      'sdkInt': sdkInt,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'buildMode': buildMode,
      'package': packageName,
    };
  }
}
