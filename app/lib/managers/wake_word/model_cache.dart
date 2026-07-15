import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// The on-disk model caches, and the one way to drop them.
///
/// Every engine caches downloaded weights under application support, keyed by a
/// hash of the URL they came from. That key never changes when the *bytes*
/// behind the URL change, so a model re-published on the Home Assistant box —
/// retrained, re-exported, or corrected — is invisible to a device that already
/// fetched the old one. The cache is otherwise write-once and forever.
///
/// Without this the only way to re-fetch was to clear the app's data, which
/// also destroys the device's settings and its Home Assistant login. That is
/// never a proportionate way to drop a cache.
class WakeModelCache {
  /// One per engine. Names must match the stores' own `_cacheDir()`.
  static const dirNames = ['vsww_models', 'mww_models', 'oww_models'];

  static Future<List<Directory>> _dirs() async {
    final base = await getApplicationSupportDirectory();
    return [for (final name in dirNames) Directory('${base.path}/$name')];
  }

  /// Delete every cached model. Returns the number of files removed.
  ///
  /// Only the caches: settings, secrets and the WebView's session live
  /// elsewhere and are none of this method's business.
  static Future<int> clear() async {
    var removed = 0;
    for (final dir in await _dirs()) {
      if (!await dir.exists()) continue;
      await for (final entry in dir.list()) {
        if (entry is File) {
          await entry.delete();
          removed++;
        }
      }
    }
    return removed;
  }

  /// Bytes currently held, for reporting.
  static Future<int> size() async {
    var bytes = 0;
    for (final dir in await _dirs()) {
      if (!await dir.exists()) continue;
      await for (final entry in dir.list()) {
        if (entry is File) bytes += await entry.length();
      }
    }
    return bytes;
  }
}
