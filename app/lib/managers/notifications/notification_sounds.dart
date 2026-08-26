import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../settings/definitions.dart';

/// The folder every notification sound comes from (issue #320): `sounds`
/// under the app's external files directory, which is the File Manager's
/// "app" root. One place, reachable four ways (the device's Browse, the
/// remote admin's Upload, the File Manager, USB or adb), so the sound
/// setting and the action's `chime_file` can name a file instead of a
/// path, and a backup restored onto another kiosk still means the same
/// file. The folder needs no permission on any Android and survives
/// restarts and updates; like the rest of the app's data it goes with an
/// uninstall.
abstract final class NotificationSounds {
  static const folder = 'sounds';

  /// The folder's location as a person would type it, for the settings
  /// hint: Android puts every app's external files directory here.
  static const displayPath =
      'Android/data/me.jxl.kiosk_satellite/files/$folder';

  /// The folder, made on demand, or null where there is no external
  /// storage at all (never on a real device; the unit tests).
  static Future<Directory?> directory({bool create = false}) async {
    try {
      final root = await getExternalStorageDirectory();
      if (root == null) return null;
      final dir = Directory('${root.path}/$folder');
      if (create && !await dir.exists()) await dir.create(recursive: true);
      return dir;
    } catch (_) {
      return null;
    }
  }

  /// The sound files in the folder, by name, in a stable order. Anything
  /// that is not one of [notificationSoundExtensions] is left out, so a
  /// stray file cannot be picked.
  static Future<List<String>> list() async {
    final dir = await directory();
    if (dir == null || !await dir.exists()) return const [];
    final names = <String>[];
    await for (final entry in dir.list(followLinks: false)) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.last;
      if (validateNotificationSound(name) == null) names.add(name);
    }
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  /// The path of the sound called [name], or null when the name is not a
  /// sound file's or the file is not there.
  static Future<String?> resolve(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || validateNotificationSound(trimmed) != null) {
      return null;
    }
    final dir = await directory();
    if (dir == null) return null;
    final file = File('${dir.path}/$trimmed');
    return await file.exists() ? file.path : null;
  }

  /// Copies a file into the folder and returns the name it landed under
  /// (the original's, which is what the setting stores). Same name
  /// overwrites: replacing a sound with a better take is the common case.
  static Future<String> import(String sourcePath) async {
    final name = sourcePath.split('/').last;
    final refused = validateNotificationSound(name);
    if (refused != null) throw ArgumentError(refused);
    final dir = await directory(create: true);
    if (dir == null) throw StateError('no external storage');
    await File(sourcePath).copy('${dir.path}/$name');
    return name;
  }
}
