import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/command_registry.dart';
import '../../core/manager.dart';

/// A newer release on GitHub, ready to fetch.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.apkUrl,
    required this.notes,
  });

  /// Bare version, tag with the leading `v` stripped (e.g. `0.2.0`).
  final String version;
  final String apkUrl;

  /// The GitHub release body (markdown), shown before the download starts.
  final String notes;
}

/// Watches the GitHub releases for a newer APK and, on request, downloads it
/// and hands it to the Android package installer.
///
/// A wall tablet has no Play Store nudging it, so the app checks on its own:
/// once shortly after start and then twice a day. The result only feeds the
/// drawer's notice — nothing downloads or installs without a tap.
class UpdateManager extends Manager {
  UpdateManager(super.bus, super.commands, super.log);

  static const _latestUrl =
      'https://api.github.com/repos/jxlarrea/kiosk-satellite/releases/latest';

  /// Activity-scoped (see MainActivity): the installer intent needs a live
  /// Activity, which is fine — the drawer that triggers it lives in one.
  static const _installer = MethodChannel('kiosk_satellite/installer');

  @override
  String get name => 'update';

  /// The newer release, or null while up to date (or never checked).
  final ValueNotifier<UpdateInfo?> available = ValueNotifier(null);

  /// 0..1 while a download runs, null otherwise. Doubles as the re-entry
  /// guard: a second tap while downloading is a no-op.
  final ValueNotifier<double?> progress = ValueNotifier(null);

  late final String _currentVersion;
  Timer? _timer;

  @override
  Future<void> init() async {
    _currentVersion = (await PackageInfo.fromPlatform()).version;
    // The remote admin mirrors the drawer's notice through these.
    commands
      ..register(
        Command(
          name: 'getUpdateStatus',
          description:
              'Running version, the newer GitHub release if any, and the '
              'APK download progress (0..1, null while idle)',
          handler: (_) async => CommandResult.ok({
            'currentVersion': _currentVersion,
            'availableVersion': available.value?.version,
            'availableNotes': available.value?.notes,
            'progress': progress.value,
          }),
        ),
      )
      ..register(
        Command(
          name: 'checkUpdateNow',
          description:
              'Query GitHub for the latest release immediately (the '
              'periodic check runs only twice a day) and report the result '
              'in getUpdateStatus shape, plus reachable=false when GitHub '
              'could not be queried',
          handler: (_) async {
            final reachable = await check();
            return CommandResult.ok({
              'reachable': reachable,
              'currentVersion': _currentVersion,
              'availableVersion': available.value?.version,
              'availableNotes': available.value?.notes,
              'progress': progress.value,
            });
          },
        ),
      )
      ..register(
        Command(
          name: 'installUpdate',
          description:
              'Download the newer release APK and open the Android package '
              'installer (the install itself is confirmed on the device '
              'screen)',
          handler: (_) async {
            if (available.value == null) {
              return CommandResult.fail('no update available');
            }
            if (progress.value != null) {
              return CommandResult.fail('a download is already running');
            }
            unawaited(downloadAndInstall());
            return CommandResult.ok(true);
          },
        ),
      );
    // Not immediately: at boot the network may still be settling, and the
    // check is never urgent.
    Timer(const Duration(seconds: 20), () => unawaited(check()));
    _timer = Timer.periodic(
      const Duration(hours: 12),
      (_) => unawaited(check()),
    );
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
  }

  /// Returns whether GitHub answered; the outcome itself lands in
  /// [available] either way.
  Future<bool> check() async {
    try {
      final res = await http.get(
        Uri.parse(_latestUrl),
        headers: const {'Accept': 'application/vnd.github+json'},
      );
      if (res.statusCode != 200) {
        log.warn(name, 'release check failed: HTTP ${res.statusCode}');
        return false;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = (body['tag_name'] as String? ?? '').replaceFirst(
        RegExp('^v'),
        '',
      );
      final assets = (body['assets'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      final apk = assets.firstWhere(
        (a) => (a['name'] as String? ?? '').endsWith('.apk'),
        orElse: () => const {},
      );
      final url = apk['browser_download_url'] as String?;
      if (tag.isEmpty || url == null) return false;
      final newer = _isNewer(tag, _currentVersion);
      log.info(
        name,
        'latest release $tag, running $_currentVersion: '
        '${newer ? 'update available' : 'up to date'}',
      );
      available.value = newer
          ? UpdateInfo(
              version: tag,
              apkUrl: url,
              notes: (body['body'] as String? ?? '').trim(),
            )
          : null;
      return true;
    } catch (e) {
      log.warn(name, 'release check failed: $e');
      return false;
    }
  }

  /// Numeric-triple comparison; suffixes (`-beta`) are ignored, so a
  /// re-tagged `v0.1.0-beta` never counts as newer than the running `0.1.0`.
  static bool _isNewer(String remote, String current) {
    List<int> nums(String v) => RegExp(
      r'\d+',
    ).allMatches(v).take(3).map((m) => int.parse(m[0]!)).toList();
    final r = nums(remote);
    final c = nums(current);
    for (var i = 0; i < 3; i++) {
      final a = i < r.length ? r[i] : 0;
      final b = i < c.length ? c[i] : 0;
      if (a != b) return a > b;
    }
    return false;
  }

  /// Streams the APK into the app cache and hands it to the Android package
  /// installer. Returns an error message, or null when the installer UI has
  /// taken over (Android asks its own confirmation from there; on the first
  /// use it walks the user through the "install unknown apps" grant).
  Future<String?> downloadAndInstall() async {
    final info = available.value;
    if (info == null || progress.value != null) return null;
    progress.value = 0;
    final client = http.Client();
    try {
      final res = await client.send(
        http.Request('GET', Uri.parse(info.apkUrl)),
      );
      if (res.statusCode != 200) {
        return 'Download failed (HTTP ${res.statusCode}).';
      }
      // One fixed name, replaced every time: cache never accumulates old
      // APKs. The updates/ folder is what the manifest's FileProvider maps.
      final dir = Directory(
        '${(await getTemporaryDirectory()).path}/updates',
      );
      await dir.create(recursive: true);
      final file = File('${dir.path}/kiosk-satellite-update.apk');
      final sink = file.openWrite();
      final total = res.contentLength ?? 0;
      var got = 0;
      try {
        await for (final chunk in res.stream) {
          sink.add(chunk);
          got += chunk.length;
          if (total > 0) progress.value = got / total;
        }
      } finally {
        await sink.close();
      }
      log.info(
        name,
        'downloaded v${info.version} (${(got / 1048576).toStringAsFixed(1)} '
        'MB), launching installer',
      );
      await _installer.invokeMethod('installApk', {'path': file.path});
      return null;
    } catch (e) {
      log.warn(name, 'update failed: $e');
      return 'Update failed: $e';
    } finally {
      client.close();
      progress.value = null;
    }
  }
}
