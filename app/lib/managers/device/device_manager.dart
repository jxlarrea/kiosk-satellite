import 'dart:collection' show ListQueue;
import 'dart:convert' show LineSplitter, Utf8Decoder;
import 'dart:io';

import 'dart:async' show StreamSubscription, unawaited;

import 'package:flutter/foundation.dart' show ValueNotifier, kDebugMode;
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

  /// Manufacturer and model, the device's name until someone gives it one.
  /// Empty until [init] reads it, not late: the setup wizard's first page
  /// reads it as the Device name field's starting value and a widget test
  /// pumps that page without booting the device manager.
  String model = '';
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
  /// Until then, the last reading of the previous session where one was
  /// persisted, with [lightLive] false: some drivers (the Echo Show's)
  /// emit nothing at registration, so a restart in a still, dark room
  /// would otherwise know nothing about the room until the light
  /// physically changes, and adaptive brightness would start at Maximum.
  double? lightLux;

  /// Whether [lightLux] came from the sensor this session.
  bool lightLive = false;
  StreamSubscription<dynamic>? _lightSub;

  /// Where the last reading is kept across restarts. The ESPHome entity
  /// reads the same key for its own last-known fallback.
  static const _lastLuxKey = 'esphome_last_lux';

  /// Whether the device has a default network right now.
  ///
  /// The bus event is a transition ("an outage just ended"); this is the
  /// state, which is what anything drawing on screen needs — the offline
  /// notice has to be right the moment it is built, including on a kiosk
  /// that has been sitting offline since before the app started.
  final networkUp = ValueNotifier<bool>(true);

  /// The composed media gain (0..1) the Dart players apply (the DLNA
  /// overlay): the media fader, times the software master on fixed-volume
  /// devices (Chromebooks, issue #62). Native computes it (one curve, one
  /// owner); this mirrors.
  final mediaGain = ValueNotifier<double>(1.0);
  StreamSubscription<VolumeChanged>? _volumeSub;
  StreamSubscription<SettingChanged>? _mixSub;

  String get os => Platform.isAndroid ? 'android' : 'ios';

  String get deviceName {
    final configured = _settings.get(defs.deviceName);
    return configured.isNotEmpty ? configured : model;
  }

  /// When the device's next alarm goes off, or null when none is set.
  /// Whichever app set it: this is the alarm the status bar's icon shows.
  DateTime? nextAlarm;

  /// The package that set [nextAlarm], so an automation can tell the clock
  /// app's alarm from some other app's.
  String? nextAlarmPackage;

  void _setNextAlarm(Map<String, Object?>? alarm) {
    final triggerTime = (alarm?['triggerTime'] as num?)?.toInt();
    // A trigger time of zero means no alarm, not the epoch.
    nextAlarm = triggerTime == null || triggerTime <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(triggerTime);
    nextAlarmPackage = alarm?['package'] as String?;
  }

  /// The next alarm as Home Assistant wants a timestamp: ISO 8601 in UTC,
  /// or null when there is none.
  Map<String, Object?>? nextAlarmJson() {
    final at = nextAlarm;
    if (at == null) return null;
    return {
      'at': at.toUtc().toIso8601String(),
      'local': at.toIso8601String(),
      'package': nextAlarmPackage,
    };
  }

  @override
  Future<void> init() async {
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    packageName = packageInfo.packageName;
    buildNumber = packageInfo.buildNumber;

    // A previous run's fatal crash, persisted by the native CrashJournal
    // (issue #21: logcat rotates faster than reporters can copy it).
    // Logged here so every reporting surface — the Logs screen, the remote
    // admin, /api/logs — carries the trace from the moment the app is back.
    // The journal itself is kept until the next crash overwrites it, so a
    // report filed days later still finds it.
    if (Platform.isAndroid) {
      unawaited(() async {
        try {
          const background = MethodChannel('kiosk_satellite/background');
          final crash =
              await background.invokeMethod<String>('getLastCrash') ?? '';
          if (crash.trim().isNotEmpty) {
            log.error(
              name,
              'a previous run crashed; the recorded trace follows\n$crash',
            );
          }
        } catch (_) {}
      }());
    }

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

    commands.register(
      Command(
        name: 'getIpAddresses',
        description:
            'Every non-loopback IP address, keyed by interface name: '
            '{ipv4: {iface: [addr, ...]}, ipv6: {iface: [addr, ...]}}. '
            'IPv6 link-local addresses included.',
        handler: (_) async => CommandResult.ok({
          'ipv4': await addressesByInterface(InternetAddressType.IPv4),
          'ipv6': await addressesByInterface(InternetAddressType.IPv6),
        }),
      ),
    );

    // Links coming up and going down reach the sensors as an event; the
    // poll alone would miss a lock connected through the proxy for half a
    // minute (issue #281).
    DeviceDetails.listenBluetooth(
      () => bus.publish(const BluetoothLinksChanged()),
    );
    commands.register(
      Command(
        name: 'getBluetoothConnections',
        description:
            'The Bluetooth devices the kiosk is linked to right now: '
            '{connected: n, devices: [name, ...], enabled: bool}. Empty '
            'where Android will not say (no adapter, or the Nearby devices '
            'grant missing on Android 12+).',
        handler: (_) async =>
            CommandResult.ok(await DeviceDetails.bluetooth() ?? const {}),
      ),
    );

    commands.register(
      Command(
        name: 'getUptime',
        description:
            'Seconds since the app process started (app) and since the '
            'default network last came up (network, null while offline).',
        handler: (_) async {
          final data = await DeviceDetails.uptime();
          // Once per run: whether the kernel's address timestamp answered
          // or the app-start fallback clock did, so a report's logs say
          // which number a device is actually publishing.
          final source = data['networkSource'];
          if (!_uptimeSourceLogged && source != null) {
            _uptimeSourceLogged = true;
            log.info(name, 'network uptime source: $source');
          }
          return CommandResult.ok(data);
        },
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
          'live': lightLive,
        }),
      ),
    );

    const background = MethodChannel('kiosk_satellite/background');

    // The device's next alarm, as set in whichever clock app owns it
    // (issue #42). Read once at start and then pushed by the system's own
    // change broadcast, so an alarm set, moved or dismissed is reflected
    // without polling.
    BackgroundListening.onNextAlarmChanged = (alarm) {
      _setNextAlarm(alarm);
      bus.publish(const NextAlarmChanged());
    };
    try {
      _setNextAlarm(
        (await background.invokeMethod<Map>(
          'nextAlarm',
        ))?.cast<String, Object?>(),
      );
    } catch (_) {}
    commands.register(
      Command(
        name: 'getNextAlarm',
        description:
            "The device's next alarm: an ISO 8601 UTC timestamp and the "
            'package that set it, or null when none is set.',
        handler: (_) async => CommandResult.ok(nextAlarmJson()),
      ),
    );

    // Default-network transitions from the platform side. The registration
    // replay (network already up at app start) arrives flagged initial and
    // is dropped here, so an `up` on the bus always means an outage ended.
    // [networkUp] still takes it: the flag says "this is not a transition",
    // not "this is not the truth".
    BackgroundListening.onNetworkChanged = (up, initial) {
      networkUp.value = up;
      if (initial) return;
      log.info(name, up ? 'network available' : 'network lost');
      bus.publish(NetworkStateChanged(up: up));
    };
    // Seeded from the platform, because a device that starts offline is
    // told nothing: there is no network to replay, and the first callback
    // only comes when one appears. Without this the UI would call an
    // offline boot online until something changed.
    try {
      networkUp.value =
          await background.invokeMethod<bool>('networkUp') ?? true;
    } catch (_) {}

    // Media volume, percent both ways. No OS permission involved:
    // STREAM_MUSIC is freely settable (only ring/notification streams under
    // Do Not Disturb are gated, and those are never touched).
    BackgroundListening.onVolumeChanged = () =>
        bus.publish(const VolumeChanged());
    _volumeSub = bus.on<VolumeChanged>().listen((_) => _refreshMediaGain());
    // The media and assistant faders live in settings; the platform side
    // applies them (issue #79), so hand them down at start and on every
    // slider move, then re-read the composed gain for the Dart players.
    _mixSub = bus.on<SettingChanged>().listen((e) async {
      if (e.key != defs.mediaVolume.key && e.key != defs.assistantVolume.key) {
        return;
      }
      await _pushVolumeMix();
      await _refreshMediaGain();
    });
    unawaited(() async {
      await _pushVolumeMix();
      await _refreshMediaGain();
    }());
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
          final percent = ((p['percent'] as num?)?.toDouble() ?? 0).clamp(
            0.0,
            100.0,
          );
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
              '-b',
              'main',
              '-b',
              'system',
              '-b',
              'crash',
              '-d',
              '-v',
              'time',
              'View:W',
              '*:V',
            ]);
            // Tail through a bounded queue while the dump streams:
            // Process.run would hold the whole multi-MB buffer dump in
            // memory (twice, as a UTF-16 string) just to keep its tail.
            final tail = ListQueue<String>(lines + 1);
            final stderrTail = StringBuffer();
            await Future.wait([
              // allowMalformed: logcat buffers carry whatever bytes apps and
              // the platform wrote; one truncated sequence must not void the
              // whole dump (issue #404, FydeOS).
              proc.stdout
                  .transform(const Utf8Decoder(allowMalformed: true))
                  .transform(const LineSplitter())
                  .forEach((line) {
                    if (tail.length >= lines) tail.removeFirst();
                    tail.add(line);
                  }),
              proc.stderr
                  .transform(const Utf8Decoder(allowMalformed: true))
                  .forEach(stderrTail.write),
            ]);
            final exitCode = await proc.exitCode;
            if (exitCode != 0) {
              return CommandResult.fail(
                'logcat failed: ${stderrTail.isEmpty ? exitCode : stderrTail}',
              );
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
        // Executed every 4 seconds for as long as an admin page is open.
        quiet: true,
        handler: (_) async => CommandResult.ok(await stats()),
      ),
    );

    _watchPower();
  }

  /// Whether external power is connected right now. Plugged, not the battery
  /// status: "charging" here has always meant "on external power" (a docked
  /// kiosk at 100% counts), and the status lies on some kernels — a LineageOS
  /// Fire 7 reports charging forever (issue #205). The status is only the
  /// fallback for hosts without the channel.
  Future<bool> _chargingNow([BatteryState? state]) async {
    final plugged = await DeviceDetails.plugged();
    if (plugged != null) return plugged;
    final s = state ?? await _battery.batteryState;
    return s == BatteryState.charging || s == BatteryState.connectedNotCharging;
  }

  StreamSubscription<BatteryState>? _powerSub;

  /// The last value the push path saw, so only genuine flips become events.
  bool? _chargingSeen;

  /// Pushes charging flips as they happen. Android broadcasts every battery
  /// change (level, plugged, status alike); each broadcast is only a cue to
  /// re-read the plugged flag — the carried status is the very value issue
  /// #205 showed lying. Without this the Charging entity trailed the cable
  /// by up to a minute, the MQTT poll interval.
  void _watchPower() {
    try {
      _powerSub = _battery.onBatteryStateChanged.listen(
        (state) async {
          final charging = await _chargingNow(state);
          if (charging == _chargingSeen) return;
          _chargingSeen = charging;
          bus.publish(PowerChanged(charging: charging));
        },
        onError: (Object e) {
          // Hosts without the battery event channel (tests, desktop): the
          // minute poll still covers charging.
        },
      );
    } catch (_) {}
  }

  /// Logged once per run: which source the network uptime came from.
  bool _uptimeSourceLogged = false;

  /// Logged once per run: which thermal zones the sandbox actually sees on
  /// a device that reports no CPU temperature, so a bug report's app logs
  /// carry the diagnosis (issue #138) without an adb session.
  bool _thermalLogged = false;

  /// Logged once per run: that this device reports no battery, so a bug
  /// report about a missing Battery entity carries its own answer.
  bool _batteryLogged = false;

  /// The charge percent, or null for a device with no battery to speak of
  /// (issue #367): a mains-powered box whose kernel exposes none, or one
  /// whose battery property answers a sentinel. The platform's own
  /// presence flag and range check come first; the plugin read is the
  /// fallback for hosts without the channel, screened the same way, since
  /// the plugin passes Android's "unsupported" sentinel through as a level.
  Future<int?> _batteryLevel() async {
    int? level;
    final native = await DeviceDetails.battery();
    if (native != null) {
      level = native.level;
    } else {
      try {
        level = batteryPercent(await _battery.batteryLevel);
      } catch (_) {
        // Desktops and emulators without a battery.
      }
    }
    if (level == null && !_batteryLogged) {
      _batteryLogged = true;
      log.info(
        name,
        native == null
            ? 'no battery level: the platform did not answer'
            : native.present
            ? 'no battery level: the platform reports one but no valid charge'
            : 'no battery: the platform reports none present',
      );
    }
    return level;
  }

  /// The battery as the corner widget shows it: the charge percent (null
  /// for a device without a battery) and whether the device is on external
  /// power. Its own read rather than [stats], which also samples the CPU
  /// for the admin header and would make a widget tick cost more than the
  /// reading it needs.
  Future<({int? level, bool charging})> batteryStatus() async =>
      (level: await _batteryLevel(), charging: await _chargingNow());

  /// The three live numbers the admin header shows. Its own read because the
  /// remote admin polls this every few seconds: [info] walks every network
  /// interface (twice) and queries the package on each call, all to produce
  /// fields a stats tick throws away.
  Future<Map<String, Object?>> stats() async {
    // Through the same gate as the widget, and never a throw: a host
    // without a battery used to fail the whole read and take the CPU
    // numbers down with it.
    final level = await _batteryLevel();
    final charging = await _chargingNow();
    final cpu = await DeviceDetails.cpu();
    if (!_thermalLogged && cpu.containsKey('temp') && cpu['temp'] == null) {
      _thermalLogged = true;
      log.info(
        name,
        'no CPU temperature; thermal zones: ${cpu['thermalZones']}',
      );
    }
    return {
      'battery': level,
      'charging': charging,
      'cpu': cpu['usage'],
      'temp': cpu['temp'],
    };
  }

  /// Every non-loopback address of [type], keyed by interface name in
  /// interface order. Link-local IPv6 included: Dart drops every fe80::
  /// address by default — the device reports them, we just would not have.
  /// They are worth listing: a device with a global address and a stale
  /// link-local one that no longer routes looks identical from here unless
  /// both are shown. Empty when the network has none, which is not an error.
  Future<Map<String, List<String>>> addressesByInterface(
    InternetAddressType type,
  ) async {
    try {
      final interfaces = await NetworkInterface.list(
        type: type,
        includeLoopback: false,
        includeLinkLocal: true,
      );
      return {
        for (final interface in interfaces)
          if (interface.addresses.isNotEmpty)
            interface.name: [
              for (final address in interface.addresses) address.address,
            ],
      };
    } catch (e) {
      log.warn(name, 'addressesByInterface failed: $e');
      return const {};
    }
  }

  /// Every non-loopback IPv6 address, in interface order. See
  /// [addressesByInterface] for why link-local addresses are included.
  Future<List<String>> ipv6Addresses() async => [
    for (final addresses in (await addressesByInterface(
      InternetAddressType.IPv6,
    )).values)
      ...addresses,
  ];

  /// First non-loopback IPv4 address, or null (e.g. no network). Link-local
  /// 169.254 addresses are skipped: this is the address the admin URL and
  /// the setup screen print for people to visit, and a DHCP-failure address
  /// routes nowhere.
  Future<String?> ipAddress() async {
    for (final addresses in (await addressesByInterface(
      InternetAddressType.IPv4,
    )).values) {
      for (final address in addresses) {
        if (address.startsWith('169.254.')) continue;
        return address;
      }
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
      final remembered = num.tryParse(_settings.internal(_lastLuxKey));
      if (remembered != null) lightLux = remembered.toDouble();
      const stream = EventChannel('kiosk_satellite/light_sensor_stream');
      _lightSub = stream.receiveBroadcastStream().listen(
        (v) {
          final lux = (v as num?)?.toDouble();
          if (lux == null) return;
          lightLux = lux;
          lightLive = true;
          // Persisted so the next session starts from it (see lightLux).
          unawaited(_settings.setInternal(_lastLuxKey, '${lux.round()}'));
          bus.publish(LightLevelChanged(lux: lux));
        },
        onError: (Object e) {
          log.warn(name, 'light sensor stream failed: $e');
        },
      );
      log.info(
        name,
        'ambient light sensor streaming'
        '${remembered == null ? '' : ' (last known ${remembered.round()} lx '
                  'until the first reading)'}',
      );
    } catch (e) {
      // A host without the channel (tests, older platform code): no sensor.
      log.warn(name, 'light sensor unavailable: $e');
    }
  }

  Future<void> _refreshMediaGain() async {
    try {
      const background = MethodChannel('kiosk_satellite/background');
      final raw = await background.invokeMethod<Map>('getVolume');
      mediaGain.value = (raw?['gain'] as num?)?.toDouble() ?? 1.0;
    } catch (_) {}
  }

  Future<void> _pushVolumeMix() async {
    try {
      const background = MethodChannel('kiosk_satellite/background');
      await background.invokeMethod<void>('setVolumeMix', {
        'media': _settings.get(defs.mediaVolume).toInt(),
        'assistant': _settings.get(defs.assistantVolume).toInt(),
      });
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await _powerSub?.cancel();
    await _lightSub?.cancel();
    await _volumeSub?.cancel();
    await _mixSub?.cancel();
  }

  Future<Map<String, Object?>> info() async {
    return {
      ...await stats(),
      'uptime': await DeviceDetails.uptime(),
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
