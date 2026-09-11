/// Selects a device-compatible APK without relying on GitHub's asset order.
/// Unknown architectures and releases without a matching split use universal.
Map<String, dynamic>? selectReleaseApk(
  List<Map<String, dynamic>> assets,
  String tag,
  List<String> supportedAbis,
) {
  final version = tag.replaceFirst(RegExp('^v'), '');
  final prefixes = ['kiosk-satellite-v$version', 'kiosk-satellite-$version'];
  Map<String, dynamic>? named(String suffix) {
    for (final prefix in prefixes) {
      for (final asset in assets) {
        final url = asset['browser_download_url'];
        if (asset['name'] == '$prefix$suffix' &&
            url is String &&
            url.isNotEmpty &&
            (asset['state'] == null || asset['state'] == 'uploaded')) {
          return asset;
        }
      }
    }
    return null;
  }

  // Android orders these by preference and reports what its OS can run.
  // A 64-bit CPU with a 32-bit Android installation reports 32-bit ABIs.
  for (final abi in supportedAbis) {
    if (!const {'arm64-v8a', 'armeabi-v7a', 'x86_64'}.contains(abi)) continue;
    final split = named('.$abi.apk');
    if (split != null) return split;
  }
  return named('.apk');
}
