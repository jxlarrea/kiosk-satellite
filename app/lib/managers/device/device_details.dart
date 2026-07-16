import 'package:flutter/services.dart';

/// The device facts that need the platform to answer: memory, storage, the
/// panel, the WebView actually rendering the page.
///
/// Everything here is read on demand. A null field means Android would not tell
/// us, and is rendered as unavailable with the reason rather than as a
/// plausible-looking zero — see [DeviceDetails.macAddresses], which is the
/// cautionary tale.
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

  /// The WebView implementation in use — not the app's, the system's, and it
  /// updates itself out from under the app.
  String? get webviewPackage => _map('webview')?['package'] as String?;
  String? get webviewVersion => _map('webview')?['version'] as String?;

  /// Empty on any modern Android. Kept as a list rather than a string so
  /// "none" is representable without inventing one.
  List<String> get macAddresses =>
      (_raw['macAddresses'] as List?)?.cast<String>() ?? const [];

  /// Null without "Usage access", the special grant this needs.
  String? get foregroundApp => _raw['foregroundApp'] as String?;
  bool get hasUsageAccess => _raw['hasUsageAccess'] == true;

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
        },
        'webview': {'package': webviewPackage, 'version': webviewVersion},
        'macAddresses': macAddresses,
        'foregroundApp': foregroundApp,
        'hasUsageAccess': hasUsageAccess,
      };
}
