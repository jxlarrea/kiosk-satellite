import 'package:flutter/services.dart';

/// The device facts that need the platform to answer: memory, storage, the
/// panel, the WebView actually rendering the page.
///
/// Everything here is read on demand, and is limited to what Android will
/// answer without a further grant. A null field means the platform declined,
/// and is rendered as unavailable rather than as a plausible-looking zero.
class DeviceDetails {
  const DeviceDetails._(this._raw);

  final Map<String, Object?> _raw;

  static const _channel = MethodChannel('kiosk_satellite/device_details');

  /// Empty when the platform has no such channel (tests, desktop).
  static Future<DeviceDetails> read() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('read');
      return DeviceDetails._(raw ?? const {});
    } catch (_) {
      return const DeviceDetails._({});
    }
  }

  /// The SSAID — stable per device and app signing key, surviving app
  /// reinstalls (only a factory reset changes it). Null off Android or when
  /// the platform declines. The seed for the licensing Device ID.
  static Future<String?> androidId() async {
    try {
      return await _channel.invokeMethod<String>('androidId');
    } catch (_) {
      return null;
    }
  }

  /// The device's real Wi-Fi hardware address, uppercase colon form, or null
  /// where Android hides it (any non-device-owner install on Android 11+).
  /// Read on demand and never displayed as a row: it exists to be adopted as
  /// the ESPHome identity so Home Assistant links this kiosk with the same
  /// device from router integrations (issue #252).
  /// The Java heap's ceiling in bytes, or null where the platform cannot
  /// say. ExoPlayer buffers media into Java byte arrays, so this is the
  /// budget a video's buffering must fit in.
  static Future<int?> javaHeapMax() async {
    try {
      return await _channel.invokeMethod<int>('javaHeapMax');
    } catch (_) {
      return null;
    }
  }

  /// Whether videos should start on a platform view instead of Flutter's
  /// texture: Samsung Exynos devices, whose compressed decoder frames leak
  /// graphics memory through the texture (issue #894). False where the
  /// platform cannot say.
  static Future<bool> platformVideoFirst() async {
    try {
      return await _channel.invokeMethod<bool>('platformVideoFirst') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// [tags] as language names in [display]'s language, for the text to
  /// speech Language pickers: en-US reads English (United States). A tag
  /// the platform cannot name, or no platform at all (tests), keeps the tag.
  static Future<Map<String, String>> languageNames(
    List<String> tags,
    String display,
  ) async {
    try {
      final raw = await _channel.invokeMapMethod<String, String>(
        'languageNames',
        {'tags': tags, 'display': display},
      );
      return {for (final t in tags) t: raw?[t] ?? t};
    } catch (_) {
      return {for (final t in tags) t: t};
    }
  }

  static Future<String?> wifiMac() async {
    try {
      return await _channel.invokeMethod<String>('wifiMac');
    } catch (_) {
      return null;
    }
  }

  /// Live CPU load (`usage`, 0-100), average clock (`clock`, MHz) and
  /// temperature (`temp`, °C). Each is null when the platform declines; the
  /// whole map is empty off-Android.
  static Future<Map<String, Object?>> cpu() async {
    try {
      return await _channel.invokeMapMethod<String, Object?>('cpu') ?? const {};
    } catch (_) {
      return const {};
    }
  }

  /// Free (the kernel's MemAvailable) and total memory in bytes, plus the
  /// low-memory flag: `free`, `total`, `low`. Empty off-Android.
  static Future<Map<String, Object?>> ram() async {
    try {
      return await _channel.invokeMapMethod<String, Object?>('ram') ?? const {};
    } catch (_) {
      return const {};
    }
  }

  /// Whether external power is connected, from the charger's own online flag
  /// (EXTRA_PLUGGED) rather than the battery status — some kernels report a
  /// status of "charging" forever (issue #205). Null off Android or when the
  /// platform won't say.
  static Future<bool?> plugged() async {
    try {
      return await _channel.invokeMethod<bool>('plugged');
    } catch (_) {
      return null;
    }
  }

  /// The battery as the platform reports it (issue #367): `present` is the
  /// kernel's own word on whether the device has one, `level` the charge
  /// percent screened through [batteryPercent], so a battery-less device
  /// reads null rather than the sentinel Android answers for a property
  /// it cannot read. `temp` is the battery's temperature in °C, null when
  /// the HAL has no sensor behind it. Null off Android or when the platform
  /// won't say, and the caller falls back to the plugin read.
  static Future<({bool present, int? level, double? temp})?> battery() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('battery');
      if (raw == null) return null;
      final present = raw['present'] != false;
      return (
        present: present,
        level: present ? batteryPercent(raw['level']) : null,
        temp: present ? (raw['temp'] as num?)?.toDouble() : null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Called whenever a Bluetooth link comes up or goes down, from the
  /// platform's own ACL broadcasts. The connected-devices sensors publish on
  /// it instead of waiting for the minute poll, which a link held for half a
  /// minute (Home Assistant talking to a lock through the proxy) falls
  /// straight through.
  static void listenBluetooth(void Function() onChanged) {
    _onBluetoothChanged = onChanged;
    _installCues();
  }

  /// Called on every battery broadcast (level, plugged and status alike),
  /// only as a cue to read [plugged] again. The platform side never opens
  /// the broadcast itself: a Lenovo TB311XU sends one whose extras cannot
  /// be read, and battery_plus's receiver read them and took the process
  /// down with every battery change.
  static void listenPower(void Function()? onChanged) {
    _onPowerChanged = onChanged;
    _installCues();
  }

  static void _installCues() {
    if (_cuesInstalled) return;
    _cuesInstalled = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'bluetoothChanged':
          _onBluetoothChanged?.call();
        case 'powerChanged':
          _onPowerChanged?.call();
      }
    });
  }

  static void Function()? _onBluetoothChanged;
  static void Function()? _onPowerChanged;
  static bool _cuesInstalled = false;

  /// The Bluetooth devices this kiosk holds a link to right now:
  /// `connected` (the count), `devices` (their names) and `enabled` (the
  /// adapter's own switch). Null where Android will not answer at all: no
  /// adapter, or the Nearby devices grant missing on Android 12+.
  static Future<Map<String, Object?>?> bluetooth() async {
    try {
      return await _channel.invokeMapMethod<String, Object?>('bluetooth');
    } catch (_) {
      return null;
    }
  }

  /// Seconds since the process started (`app`), since the device booted
  /// (`device`) and since the default network last came up (`network`, null
  /// while offline). The network number reads
  /// the kernel's own timestamp on the interface's IP address where it can,
  /// so it survives app restarts; where the kernel read is refused it falls
  /// back to a clock anchored at app start at the earliest, which then reads
  /// as "how long since a drop was last seen" (issue #75). `networkSource`
  /// names which of the two answered. Empty off-Android.
  static Future<Map<String, Object?>> uptime() async {
    try {
      return await _channel.invokeMapMethod<String, Object?>('uptime') ??
          const {};
    } catch (_) {
      return const {};
    }
  }

  /// The default network's `type` (ethernet, wifi, cellular, vpn or other)
  /// and, on Wi-Fi, `rssi` (dBm), `speedMbps` and `frequencyMhz`, each null
  /// when Android reports it as unknown. Null while offline or off Android.
  /// No SSID: that needs a location grant.
  static Future<Map<String, Object?>?> link() async {
    try {
      return await _channel.invokeMapMethod<String, Object?>('link');
    } catch (_) {
      return null;
    }
  }

  /// The interface order the device's address is picked by (issue #1371):
  /// `preferred` names the interfaces of the networks Android has, the
  /// default network first, and `last` names VPNs and point-to-point links.
  /// Null off Android or when the platform declines.
  static Future<({List<String> preferred, List<String> last})?>
  interfaceOrder() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>(
        'interfaceOrder',
      );
      if (raw == null) return null;
      List<String> names(Object? v) =>
          v is List ? [for (final n in v) '$n'] : const [];
      return (preferred: names(raw['preferred']), last: names(raw['last']));
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?>? _map(String key) {
    final v = _raw[key];
    return v is Map ? v.cast<String, Object?>() : null;
  }

  String? get brand => _raw['brand'] as String?;
  String? get manufacturer => _raw['manufacturer'] as String?;
  String? get model => _raw['model'] as String?;

  /// Build.DISPLAY — the build the OEM shipped, which is what a bug report
  /// needs and what the marketing version number never says.
  String? get androidBuild => _raw['androidBuild'] as String?;
  String? get fingerprint => _raw['fingerprint'] as String?;

  int? get ramFree => (_map('ram')?['free'] as num?)?.toInt();
  int? get ramTotal => (_map('ram')?['total'] as num?)?.toInt();
  bool get ramLow => _map('ram')?['low'] == true;

  int? get storageFree => (_map('storage')?['free'] as num?)?.toInt();
  int? get storageTotal => (_map('storage')?['total'] as num?)?.toInt();

  int? get screenWidth => (_map('screen')?['width'] as num?)?.toInt();
  int? get screenHeight => (_map('screen')?['height'] as num?)?.toInt();
  double? get screenDensity => (_map('screen')?['density'] as num?)?.toDouble();

  /// `landscape` or `portrait`, from the current size.
  String? get screenOrientation => _map('screen')?['orientation'] as String?;

  /// Degrees the display is turned from its natural orientation (0, 90, 180
  /// or 270). A panel mounted sideways reads landscape at 90.
  int? get screenRotation => (_map('screen')?['rotation'] as num?)?.toInt();

  /// The WebView implementation in use — not the app's, the system's, and it
  /// updates itself out from under the app.
  String? get webviewPackage => _map('webview')?['package'] as String?;
  String? get webviewVersion => _map('webview')?['version'] as String?;

  /// False when Android reports no WebView provider at all (API 26+); null
  /// where the platform cannot say.
  bool? get webviewAvailable => _map('webview')?['available'] as bool?;

  /// MediaTek's DuraSpeed is installed and on (see DeviceDetails.kt).
  bool get duraSpeed => _map('webview')?['duraSpeed'] == true;

  Map<String, Object?> toJson() => {
    'brand': brand,
    'manufacturer': manufacturer,
    'model': model,
    'androidBuild': androidBuild,
    'fingerprint': fingerprint,
    'ram': {'free': ramFree, 'total': ramTotal, 'low': ramLow},
    'storage': {'free': storageFree, 'total': storageTotal},
    'screen': {
      'width': screenWidth,
      'height': screenHeight,
      'density': screenDensity,
      'orientation': screenOrientation,
      'rotation': screenRotation,
    },
    'webview': {'package': webviewPackage, 'version': webviewVersion},
  };
}

/// A battery reading as a percent, or null for anything that is not one
/// (issue #367): Android's BatteryManager answers Integer.MIN_VALUE (0 on
/// targets before Android 9) for a capacity the kernel does not expose,
/// and a value outside 0..100 is a sentinel of some kind, never a charge.
/// Every consumer (the screensaver widget, ESPHome, the remote admin
/// and /api/health) reads through this one gate.
int? batteryPercent(Object? raw) {
  if (raw is! num) return null;
  final level = raw.toInt();
  if (level < 0 || level > 100) return null;
  return level;
}
