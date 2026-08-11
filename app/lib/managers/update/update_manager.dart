import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';

/// A newer release on GitHub, ready to fetch.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.apkUrl,
    required this.notes,
    required this.releaseUrl,
    this.apkSize,
  });

  /// Bare version, tag with the leading `v` stripped (e.g. `0.2.0`).
  final String version;
  final String apkUrl;

  /// The APK asset's byte size as GitHub reports it, or null when the API
  /// omitted it. What lets an already-downloaded file be recognized and
  /// reused instead of downloaded again (issue #170).
  final int? apkSize;

  /// What is new since the running version, shown before the download
  /// starts: the GitHub release body, or, when the device skipped releases,
  /// every missed body newest-first under a Version heading each (#165).
  final String notes;

  /// The release's GitHub page, linked from the HA update entity.
  final String releaseUrl;
}

/// Watches the GitHub releases for a newer APK and, on request, downloads it
/// and hands it to the Android package installer.
///
/// A wall tablet has no Play Store nudging it, so the app checks on its own:
/// once shortly after start and then twice a day. The result feeds the
/// drawer's notice and the Home Assistant update entity (over MQTT); nothing
/// downloads or installs until a tap in either place asks for it.
class UpdateManager extends Manager {
  UpdateManager(super.bus, super.commands, super.log);

  /// The releases list rather than `/releases/latest`: one request either
  /// way, but the list also carries the bodies of releases the device
  /// skipped, which is what lets the notice show everything that changed
  /// since the running version (#165) without a request per release. The
  /// window is a display cap, not a paging cursor: a device further behind
  /// than this gets the newest releases and a pointer to the history.
  static const _releasesUrl =
      'https://api.github.com/repos/jxlarrea/kiosk-satellite/'
      'releases?per_page=30';

  /// App-scoped (see ApkInstaller): installs go through a PackageInstaller
  /// session, which needs no Activity. On Android 12+ the session installs
  /// silently once this app is the installer of record (i.e. from the second
  /// update installed through here onward); everywhere else Android shows its
  /// confirmation screen on the device.
  static const _installer = MethodChannel('kiosk_satellite/installer');

  /// Same channel the kiosk manager's restart preflight uses: whether the
  /// draw-over-apps grant is in place, which is what lets the relaunch
  /// receiver reopen the app after the installer kills the process.
  static const _background = MethodChannel('kiosk_satellite/background');

  @override
  String get name => 'update';

  /// The newer release, or null while up to date (or never checked).
  final ValueNotifier<UpdateInfo?> available = ValueNotifier(null);

  /// 0..1 while a download runs, null otherwise. Doubles as the re-entry
  /// guard: a second tap while downloading is a no-op.
  final ValueNotifier<double?> progress = ValueNotifier(null);

  late final String _currentVersion;

  /// Read once at init, not through the getDeviceInfo command: that command
  /// gathers CPU load, whose sampler pays a 500ms paired read whenever it is
  /// called twice in quick succession — exactly what the About page's
  /// info-then-update-status sequence did, making getUpdateStatus a half
  /// second call for one integer. Null off Android.
  int? _sdkInt;

  /// Builds the client for the release query and the APK download. Swapped
  /// in tests; production always hands back a real one.
  @visibleForTesting
  http.Client Function() clientFactory = http.Client.new;

  Timer? _firstCheck;
  Timer? _timer;

  /// Last whole percent pushed onto the bus; keeps the progress stream from
  /// flooding listeners (MQTT republishes every event it hears).
  int _lastPercent = -1;

  @override
  Future<void> init() async {
    _currentVersion = (await PackageInfo.fromPlatform()).version;
    if (Platform.isAndroid) {
      _sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    }
    // The installer's asynchronous outcomes. Success never arrives: Android
    // kills the process as it swaps the code, and the relaunch receiver
    // brings the app back already running the new version.
    _installer.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'installDeclined':
          log.info(name, 'install declined on the device screen');
          await _resumeKioskIfPaused();
        case 'installFailed':
          log.warn(name, 'install failed: ${call.arguments}');
          await _resumeKioskIfPaused();
      }
      bus.publish(const UpdateStateChanged());
      return null;
    });
    available.addListener(() {
      _lastPercent = -1;
      bus.publish(const UpdateStateChanged());
    });
    progress.addListener(() {
      final p = progress.value;
      final percent = p == null ? -1 : (p * 100).floor();
      if (percent == _lastPercent) return;
      _lastPercent = percent;
      bus.publish(const UpdateStateChanged());
    });
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
            'releaseUrl': available.value?.releaseUrl,
            'progress': progress.value,
            'canRelaunch': await canRelaunch(),
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
              'Download the newer release APK and install it. Silent on '
              'Android 12+ once the app is the installer of record (from the '
              'second in-app update onward); otherwise Android asks for '
              'confirmation on the device screen',
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
    _firstCheck = Timer(const Duration(seconds: 20), () => unawaited(check()));
    _timer = Timer.periodic(
      const Duration(hours: 12),
      (_) => unawaited(check()),
    );
  }

  @override
  Future<void> dispose() async {
    _firstCheck?.cancel();
    _timer?.cancel();
  }

  /// Returns whether GitHub answered; the outcome itself lands in
  /// [available] either way.
  Future<bool> check() async {
    final latest = await _fetchLatest();
    if (!latest.reachable) return false;
    available.value = latest.info;
    return true;
  }

  /// Asks GitHub for the newest releases. `reachable` is false when the
  /// query itself failed (offline, rate limited, malformed release), which
  /// is the case where the caller keeps what it already knew; `info` is null
  /// when GitHub answered and the running version is already the latest.
  Future<({bool reachable, UpdateInfo? info})> _fetchLatest() async {
    final client = clientFactory();
    try {
      final res = await client.get(
        Uri.parse(_releasesUrl),
        headers: const {'Accept': 'application/vnd.github+json'},
      );
      if (res.statusCode != 200) {
        log.warn(name, 'release check failed: HTTP ${res.statusCode}');
        return (reachable: false, info: null);
      }
      String tagOf(Map<String, dynamic> r) =>
          (r['tag_name'] as String? ?? '').replaceFirst(RegExp('^v'), '');
      // Betas and drafts never count, exactly as /releases/latest excluded
      // them; the first entry left is the release that endpoint would have
      // answered with.
      final releases = (jsonDecode(res.body) as List)
          .cast<Map<String, dynamic>>()
          .where((r) => r['draft'] != true && r['prerelease'] != true)
          .toList();
      final latest = releases.firstOrNull;
      if (latest == null) return (reachable: false, info: null);
      final tag = tagOf(latest);
      final assets = (latest['assets'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      final apk = assets.firstWhere(
        (a) => (a['name'] as String? ?? '').endsWith('.apk'),
        orElse: () => const {},
      );
      final url = apk['browser_download_url'] as String?;
      if (tag.isEmpty || url == null) return (reachable: false, info: null);
      final newer = _isNewer(tag, _currentVersion);
      log.info(
        name,
        'latest release $tag, running $_currentVersion: '
        '${newer ? 'update available' : 'up to date'}',
      );
      return (
        reachable: true,
        info: newer
            ? UpdateInfo(
                version: tag,
                apkUrl: url,
                notes: _combinedNotes(releases, tagOf),
                releaseUrl: latest['html_url'] as String? ??
                    'https://github.com/jxlarrea/kiosk-satellite/releases',
                apkSize: (apk['size'] as num?)?.toInt(),
              )
            : null,
      );
    } catch (e) {
      log.warn(name, 'release check failed: $e');
      return (reachable: false, info: null);
    } finally {
      client.close();
    }
  }

  /// The release notes to show for an update: every fetched release newer
  /// than the running version, newest first (#165). A single release keeps
  /// its body untouched, today's look; a skipped-releases update separates
  /// the bodies with a Version heading each, so nothing that changed in
  /// between goes unseen. When even the oldest fetched release is newer
  /// than the running version, the device is further behind than the fetch
  /// window and the notes end by saying where the rest lives.
  String _combinedNotes(
    List<Map<String, dynamic>> releases,
    String Function(Map<String, dynamic>) tagOf,
  ) {
    String bodyOf(Map<String, dynamic> r) =>
        (r['body'] as String? ?? '').trim();
    final missed = releases
        .where((r) => _isNewer(tagOf(r), _currentVersion))
        .toList();
    if (missed.length <= 1) return missed.map(bodyOf).join();
    final parts = <String>[
      for (final r in missed) '# Version ${tagOf(r)}\n\n${bodyOf(r)}',
      if (missed.length == releases.length)
        'Earlier changes are on the GitHub releases page.',
    ];
    return parts.join('\n\n');
  }

  /// Whether the app can reopen itself after the installer kills it. On
  /// Android 10+ the relaunch receiver's activity start is a background
  /// launch, only honored with the draw-over-apps grant; without it the
  /// update installs but the kiosk stays closed until someone taps the icon.
  /// Android 9 and older restart fine regardless.
  Future<bool> canRelaunch() async {
    try {
      // Unknown (tests, non-Android): claim yes rather than nag.
      if (_sdkInt == null || _sdkInt! < 29) return true;
      return await _background.invokeMethod<bool>('canBringToFront') ?? false;
    } catch (_) {
      return true;
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
    var info = available.value;
    if (info == null || progress.value != null) return null;
    progress.value = 0;
    final client = clientFactory();
    try {
      // The notice can be half a day old (the periodic check runs twice a
      // day) and stays up until it is acted on, so a release cut in the
      // meantime would install the version that was current when the notice
      // appeared and leave another update waiting right behind it. Ask
      // GitHub once more and take whatever is newest now; when GitHub cannot
      // be reached the known release is still better than no update at all.
      final latest = await _fetchLatest();
      if (latest.reachable) {
        final fresh = latest.info;
        if (fresh == null) {
          // The release the notice pointed at is gone (pulled or re-tagged)
          // and nothing newer stands behind it: nothing to install.
          log.info(
            name,
            'skipping the install: v${info.version} is no longer offered and '
            '$_currentVersion is the latest release',
          );
          available.value = null;
          return 'Already up to date. Version $_currentVersion is the latest '
              'release.';
        }
        if (fresh.version != info.version) {
          log.info(
            name,
            'v${fresh.version} was released since the update notice '
            'appeared: installing that instead of v${info.version}',
          );
        }
        // Adopted even on the same version: the fresh record carries the
        // asset's current byte size, which the reuse check below compares
        // the cached file against (issue #170).
        available.value = fresh;
        info = fresh;
      }
      // One fixed name, replaced every time: cache never accumulates old
      // APKs. The updates/ folder is what the manifest's FileProvider maps.
      final dir = Directory(
        '${(await getTemporaryDirectory()).path}/updates',
      );
      await dir.create(recursive: true);
      final file = File('${dir.path}/kiosk-satellite-update.apk');
      // An earlier attempt whose install never went through (declined, or
      // the confirmation could not show) already paid for this download;
      // a file whose size matches what GitHub reports for the asset is
      // that download, not a stale or truncated one (issue #170).
      final expected = info.apkSize;
      if (expected != null &&
          await file.exists() &&
          await file.length() == expected) {
        log.info(
          name,
          'reusing the already-downloaded v${info.version} APK',
        );
      } else {
        final res = await client.send(
          http.Request('GET', Uri.parse(info.apkUrl)),
        );
        if (res.statusCode != 200) {
          return 'Download failed (HTTP ${res.statusCode}).';
        }
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
          'MB), handing to the installer',
        );
      }
      if (!await canRelaunch()) {
        log.warn(
          name,
          'the "Display over other apps" permission is missing: the update '
          'will install but the app cannot reopen itself afterwards',
        );
      }
      // When Android's confirm screen is coming, the kiosk has to stand
      // down first: lock task pinning blocks that screen outright, and
      // the foreground reclaim would cover it seconds after it appeared,
      // so the install silently went nowhere (issue #170). Asked before
      // the session is committed — by PENDING_USER_ACTION it is too late.
      // The kiosk re-arms when the install is declined or fails (below);
      // a successful install kills the process and the relaunch re-arms.
      if (await _needsConfirmation()) {
        _kioskPaused =
            (await commands.execute('pauseKioskForInstall', const {})).ok;
      }
      final mode =
          await _installer.invokeMethod<String>('installApk', {'path': file.path});
      log.info(
        name,
        mode == 'silent'
            ? 'installing silently; the app restarts itself when done'
            : 'waiting for the install to be confirmed on the device screen',
      );
      return null;
    } catch (e) {
      log.warn(name, 'update failed: $e');
      await _resumeKioskIfPaused();
      return 'Update failed: $e';
    } finally {
      client.close();
      progress.value = null;
    }
  }

  /// Whether the coming install will put Android's confirmation screen up
  /// (true) or go through silently (false). Off Android there is nothing
  /// to confirm and nothing to pause.
  Future<bool> _needsConfirmation() async {
    try {
      return await _installer.invokeMethod<bool>('needsConfirmation') ?? true;
    } catch (_) {
      return false;
    }
  }

  /// Whether the kiosk stood down for this install and still owes a
  /// re-arm. Cleared by the declined/failed callbacks; a successful
  /// install ends the process instead.
  bool _kioskPaused = false;

  Future<void> _resumeKioskIfPaused() async {
    if (!_kioskPaused) return;
    _kioskPaused = false;
    await commands.execute('resumeKioskAfterInstall', const {});
  }
}
