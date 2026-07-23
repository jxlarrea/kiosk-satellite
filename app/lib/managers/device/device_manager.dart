import 'dart:collection' show ListQueue;
import 'dart:convert' show LineSplitter, utf8;
import 'dart:io';

import 'dart:async' show StreamSubscription;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show EventChannel, MethodChannel;

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/settings_manager.dart';
import '../settings/definitions.dart' as defs;
import '../wake_word/background_listening.dart';
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

  /// Whether the device has an ambient light sensor; several budget tablets
  /// (Fire HD 8 among them) ship without one.
  bool hasLightSensor = false;

  /// Latest ambient light reading in lux, or null before the first event.
  double? lightLux;
  StreamSubscription<dynamic>? _lightSub;

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
    log.info(name, '$model, $osVersion, app $appVersion');

    commands.register(
      Command(
        name: 'getDeviceDetails',
        description:
            'Memory, storage, panel, WebView and build details. Fields '
            'Android will not give an app come back null rather than as a '
            'placeholder; see DeviceDetails.',
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

    await _initLightSensor();
    commands.register(
      Command(
        name: 'getLightLevel',
        description:
            'The ambient light sensor: whether the device has one, and the '
            'latest reading in lux',
        handler: (_) async => CommandResult.ok({
          'present': hasLightSensor,
          'lux': lightLux,
        }),
      ),
    );

    // Media volume, percent both ways. No OS permission involved:
    // STREAM_MUSIC is freely settable (only ring/notification streams under
    // Do Not Disturb are gated, and those are never touched).
    const background = MethodChannel('kiosk_satellite/background');
    BackgroundListening.onVolumeChanged =
        () => bus.publish(const VolumeChanged());
    commands.register(
      Command(
        name: 'getVolume',
        description: 'Media volume as a percentage (0-100)',
        handler: (_) async {
          final raw = await background.invokeMethod<Map>('getVolume');
          final level = (raw?['level'] as num?)?.toInt() ?? 0;
          final max = (raw?['max'] as num?)?.toInt() ?? 1;
          return CommandResult.ok((level * 100 / max).round());
        },
      ),
    );
    commands.register(
      Command(
        name: 'setVolume',
        description: 'Set the media volume',
        params: const {'percent': 'target volume, 0-100'},
        handler: (p) async {
          final percent =
              ((p['percent'] as num?)?.toDouble() ?? 0).clamp(0.0, 100.0);
          final raw = await background.invokeMethod<Map>('getVolume');
          final max = (raw?['max'] as num?)?.toInt() ?? 15;
          await background.invokeMethod('setVolume', {
            'level': (percent / 100 * max).round(),
          });
          bus.publish(const VolumeChanged());
          return const CommandResult.ok();
        },
      ),
    );

    commands.register(
      Command(
        name: 'getLogcat',
        description:
            'The Android logcat tail for this app (main, system and crash '
            'buffers) — the place renderer crashes and OS-level kills show '
            'up, which the in-app log cannot see. An app may always read '
            'its own logcat lines; no permission involved.',
        params: const {'lines': 'max lines, default 800'},
        handler: (p) async {
          final lines = ((p['lines'] as num?)?.toInt() ?? 800).clamp(50, 5000);
          try {
            // The framework logs an I/View setRequestedFrameRate line on
            // every WebView draw (~100/s), so the buffer is mostly that
            // spam. The View:W filterspec drops it, but logcat applies -t
            // to the raw buffer BEFORE filtering, which would leave only
            // the few real lines among the last N spammy ones. So: dump
            // the whole buffer filtered and take the tail ourselves.
            final proc = await Process.start('logcat', [
              '-b', 'main', '-b', 'system', '-b', 'crash',
              '-d', '-v', 'time',
              'View:W', '*:V',
            ]);
            // Tail through a bounded queue while the dump streams:
            // Process.run would hold the whole multi-MB buffer dump in
            // memory (twice, as a UTF-16 string) just to keep its tail.
            final tail = ListQueue<String>(lines + 1);
            final stderrTail = StringBuffer();
            await Future.wait([
              proc.stdout
                  .transform(utf8.decoder)
                  .transform(const LineSplitter())
                  .forEach((line) {
                    if (tail.length >= lines) tail.removeFirst();
                    tail.add(line);
                  }),
              proc.stderr
                  .transform(utf8.decoder)
                  .forEach(stderrTail.write),
            ]);
            final exitCode = await proc.exitCode;
            if (exitCode != 0) {
              return CommandResult.fail(
                  'logcat failed: ${stderrTail.isEmpty ? exitCode : stderrTail}');
            }
            return CommandResult.ok(tail.join('\n'));
          } catch (e) {
            return CommandResult.fail('logcat unavailable: $e');
          }
        },
      ),
    );

    commands.register(
      Command(
        name: 'getStats',
        description:
            'Battery, CPU load and temperature only: the live header '
            'numbers, without everything else getDeviceInfo gathers.',
        handler: (_) async => CommandResult.ok(await stats()),
      ),
    );
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

  /// Hook up the ambient light stream when the hardware exists. The native
  /// side damps the event rate (5 lx / 10% deadband, 2s minimum spacing);
  /// listeners downstream (MQTT) add their own coarser limits.
  Future<void> _initLightSensor() async {
    if (!Platform.isAndroid) return;
    try {
      const methods = MethodChannel('kiosk_satellite/light_sensor');
      hasLightSensor = await methods.invokeMethod<bool>('hasSensor') ?? false;
      if (!hasLightSensor) {
        log.info(name, 'no ambient light sensor');
        return;
      }
      const stream = EventChannel('kiosk_satellite/light_sensor_stream');
      _lightSub = stream.receiveBroadcastStream().listen((v) {
        final lux = (v as num?)?.toDouble();
        if (lux == null) return;
        lightLux = lux;
        bus.publish(LightLevelChanged(lux: lux));
      }, onError: (Object e) {
        log.warn(name, 'light sensor stream failed: $e');
      });
      log.info(name, 'ambient light sensor streaming');
    } catch (e) {
      // A host without the channel (tests, older platform code): no sensor.
      log.warn(name, 'light sensor unavailable: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _lightSub?.cancel();
  }

  Future<Map<String, Object?>> info() async {
    return {
      ...await stats(),
      'name': deviceName,
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
