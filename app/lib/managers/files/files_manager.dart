import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/command_registry.dart';
import '../../core/manager.dart';

/// A simple file manager, Fully Kiosk style: browse folders, and (through
/// the remote admin) download and upload files.
///
/// Two roots, so the useful case works before any special grant:
///
///  - `shared` — the device's shared storage (/storage/emulated/0). Needs
///    the "All files access" grant on Android 11+, which is a settings
///    screen rather than a dialog; both UIs surface it with a button.
///  - `app` — this app's own external files folder. Always accessible, and
///    where downloads, caches and exports already live.
///
/// Every client-supplied path resolves against its root and is canonicalized
/// before use; a path that escapes the root is refused, which is what keeps
/// the remote endpoints from being a directory-traversal hole.
class FilesManager extends Manager {
  FilesManager(super.bus, super.commands, super.log);

  static const _background = MethodChannel('kiosk_satellite/background');

  @override
  String get name => 'files';

  Directory? _appRoot;

  @override
  Future<void> init() async {
    try {
      _appRoot = await getExternalStorageDirectory();
    } catch (_) {
      _appRoot = null;
    }

    commands
      ..register(Command(
        name: 'fileRoots',
        description:
            'The file manager roots: shared storage (needs the "All files '
            'access" grant) and the app folder, with availability',
        handler: (_) async {
          var sharedGranted = false;
          try {
            sharedGranted = await _background
                    .invokeMethod<bool>('hasAllFilesAccess') ==
                true;
          } catch (_) {}
          return CommandResult.ok({
            'roots': [
              {
                'id': 'shared',
                'label': 'Shared storage',
                'available': sharedGranted,
                'grantNeeded': !sharedGranted,
              },
              {
                'id': 'app',
                'label': 'App folder',
                'available': _appRoot != null,
                'grantNeeded': false,
              },
            ],
          });
        },
      ))
      ..register(Command(
        name: 'fileList',
        description:
            'List a folder: entries with name, dir flag, size and modified '
            'time (ms since epoch), folders first',
        params: const {
          'root': "'shared' or 'app'",
          'path': 'folder path relative to the root, empty for the root',
        },
        handler: (p) async {
          final dir = _resolve(p['root'] as String?, p['path'] as String?);
          if (dir == null) return const CommandResult.fail('invalid path');
          final d = Directory(dir.path);
          if (!await d.exists()) {
            return const CommandResult.fail('no such folder');
          }
          final entries = <Map<String, Object?>>[];
          try {
            await for (final e in d.list(followLinks: false)) {
              final stat = await e.stat();
              entries.add({
                'name': e.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
                'dir': e is Directory,
                'size': stat.size,
                'modified': stat.modified.millisecondsSinceEpoch,
              });
            }
          } on FileSystemException catch (e) {
            return CommandResult.fail('cannot read folder: ${e.osError?.message ?? e.message}');
          }
          entries.sort((a, b) {
            final byType = (b['dir'] == true ? 1 : 0) - (a['dir'] == true ? 1 : 0);
            if (byType != 0) return byType;
            return (a['name'] as String)
                .toLowerCase()
                .compareTo((b['name'] as String).toLowerCase());
          });
          return CommandResult.ok({'entries': entries});
        },
      ))
      ..register(Command(
        name: 'fileDelete',
        description: 'Delete a file (never a folder)',
        params: const {'root': "'shared' or 'app'", 'path': 'file path'},
        handler: (p) async {
          final f = _resolve(p['root'] as String?, p['path'] as String?);
          if (f == null) return const CommandResult.fail('invalid path');
          final file = File(f.path);
          if (!await file.exists()) {
            return const CommandResult.fail('no such file');
          }
          await file.delete();
          log.info(name, 'deleted ${p['root']}:${p['path']}');
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'fileResolve',
        description:
            'Resolve a root plus relative path to an absolute device path, '
            'refusing anything that escapes the root. Used by the remote '
            "admin's file download and upload endpoints",
        params: const {'root': "'shared' or 'app'", 'path': 'relative path'},
        handler: (p) async {
          final f = _resolve(p['root'] as String?, p['path'] as String?);
          if (f == null) return const CommandResult.fail('invalid path');
          return CommandResult.ok({'path': f.path});
        },
      ))
      ..register(Command(
        name: 'requestAllFilesAccess',
        description:
            'Open the "All files access" settings screen for this app (the '
            'grant behind the shared storage root; a screen, not a dialog)',
        handler: (_) async {
          try {
            await _background.invokeMethod('requestAllFilesAccess');
            return const CommandResult.ok();
          } catch (e) {
            return CommandResult.fail('could not open the grant screen: $e');
          }
        },
      ));
  }

  /// Root + relative path to an absolute location, or null when the root is
  /// unknown or the path tries to walk out of it.
  FileSystemEntity? _resolve(String? root, String? rel) {
    final base = switch (root) {
      'shared' => Platform.isAndroid ? '/storage/emulated/0' : null,
      'app' => _appRoot?.path,
      _ => null,
    };
    if (base == null) return null;
    final cleaned = (rel ?? '').replaceAll('\\', '/');
    final joined = cleaned.isEmpty ? base : '$base/$cleaned';
    // Canonicalize without touching the filesystem: resolve . and .. by hand
    // so a not-yet-existing upload target still validates.
    final parts = <String>[];
    for (final part in joined.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (parts.isEmpty) return null;
        parts.removeLast();
        continue;
      }
      parts.add(part);
    }
    final canonical = '/${parts.join('/')}';
    if (canonical != base && !canonical.startsWith('$base/')) return null;
    return File(canonical);
  }
}
