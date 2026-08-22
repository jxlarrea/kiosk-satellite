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
  /// guard: a second tap while downloading is a no-op. Advances in whole
  /// percents, not per network chunk: every set notifies every listener
  /// (the drawer's progress dialog rebuilds on each one), and per-chunk
  /// sets are hundreds of notifications a second of pure churn (#272).
  final ValueNotifier<double?> progress = ValueNotifier(null);

  /// How the last download attempt ended: `silent` or `confirm` (handed to
  /// the installer), `cancelled`, `failed`, or `uptodate` (the offered
  /// release vanished and the running version is the latest). Null while a
  /// download runs or before any ran. What lets the remote admin tell a
  /// cancelled or failed download from one waiting on the device screen.
  String? _lastOutcome;

  /// The user-facing message of a failed attempt, for the remote admin
  /// (the command that started the download returned before it failed).
  String? _lastError;

  /// Abort hook for the in-flight download: cancels the byte stream's
  /// subscription so [cancelDownload] unblocks even a stalled transfer
  /// whose next chunk would otherwise never come.
  void Function()? _abort;
  http.Client? _downloadClient;
  bool _cancelRequested = false;

  /// How long the download waits between chunks before giving up. A slow
  /// connection delivers something well inside this; a dead one delivers
  /// nothing and used to leave the download "running" forever, blocking
  /// retries until an app restart (#272).
  @visibleForTesting
  Duration stallTimeout = const Duration(seconds: 60);

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

  /// When the last mid-download percent went onto the bus (see the
  /// progress listener's one-a-second cap).
  DateTime _lastProgressPublish = DateTime.fromMillisecondsSinceEpoch(0);

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
      // At most one mid-download publish a second: each one fans out to a
      // getUpdateStatus execution and a state push on MQTT and the ESPHome
      // surface apiece, and on a fast download the percent flips several
      // times a second — a storm reported as log spam and CPU load on weak
      // tablets (#272). The transitions in and out of "downloading" always
      // go out, so nothing ever misses the start or the end.
      final now = DateTime.now();
      final transition = p == null || _lastPercent == -1;
      if (!transition &&
          now.difference(_lastProgressPublish) <
              const Duration(seconds: 1)) {
        return;
      }
      _lastProgressPublish = now;
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
          // Executed per progress event by the MQTT and ESPHome listeners
          // and once a second by a remote admin riding a download.
          quiet: true,
          handler: (_) async => CommandResult.ok({
            'currentVersion': _currentVersion,
            'availableVersion': available.value?.version,
            'availableNotes': available.value?.notes,
            'releaseUrl': available.value?.releaseUrl,
            'progress': progress.value,
            'lastOutcome': _lastOutcome,
            'lastError': _lastError,
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
      )
      ..register(
        Command(
          name: 'cancelUpdateDownload',
          description:
              'Abort the running update download. The update notice stays '
              'up, so the download can be started again',
          handler: (_) async {
            if (progress.value == null) {
              return CommandResult.fail('no download is running');
            }
            cancelDownload();
            return const CommandResult.ok(true);
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
    _lastOutcome = null;
    _lastError = null;
    _cancelRequested = false;
    final client = clientFactory();
    _downloadClient = client;
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
          _lastOutcome = 'uptodate';
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
      // The updates/ folder is what the manifest's FileProvider maps. One
      // file per version, anything else swept first, so the cache never
      // accumulates old APKs and a leftover from an earlier release can
      // never impersonate the new one. The name must carry the version
      // because byte size alone cannot tell releases apart: two builds
      // differing by nothing but a same-length version string produce
      // APKs of identical size, and on exactly such a pair the reuse
      // check below installed the cached old release as if it were the
      // new download, "updating" the device to the version it already ran.
      final dir = Directory(
        '${(await getTemporaryDirectory()).path}/updates',
      );
      await dir.create(recursive: true);
      final file = File(
        '${dir.path}/kiosk-satellite-update-${info.version}.apk',
      );
      await for (final stale in dir.list()) {
        if (stale.path != file.path) await stale.delete();
      }
      // An earlier attempt whose install never went through (declined, or
      // the confirmation could not show) already paid for this download;
      // a file of this version's name whose size matches what GitHub
      // reports for the asset is that download, not a truncated one
      // (issue #170).
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
          return _fail('Download failed (HTTP ${res.statusCode}).');
        }
        final sink = file.openWrite();
        final total = res.contentLength ?? 0;
        var got = 0;
        try {
          // A listen()ed subscription rather than await-for: cancelling
          // must unblock even a stalled transfer, whose await-for would
          // sit inside the loop until a chunk that never comes.
          final done = Completer<void>();
          var flushed = 0;
          late final StreamSubscription<List<int>> sub;
          sub = res.stream
              .timeout(
                stallTimeout,
                onTimeout: (s) => s.addError(
                  'The download stalled: no data arrived for '
                  '${stallTimeout.inSeconds} seconds.',
                ),
              )
              .listen(
                (chunk) {
                  sink.add(chunk);
                  got += chunk.length;
                  // sink.add only queues; when flash writes lag the
                  // network the queue is unbounded heap. Pause the
                  // transfer every few MB until the file has caught up —
                  // on a 1GB tablet the alternative is GC churn.
                  if (got - flushed > 4 * 1024 * 1024) {
                    flushed = got;
                    sub.pause();
                    unawaited(sink.flush().whenComplete(sub.resume));
                  }
                  if (total > 0) {
                    final frac = got / total;
                    if ((frac * 100).floor() >
                        ((progress.value ?? 0) * 100).floor()) {
                      progress.value = frac;
                    }
                  }
                },
                onDone: () {
                  if (!done.isCompleted) done.complete();
                },
                onError: (Object e) {
                  if (!done.isCompleted) done.completeError(e);
                },
                cancelOnError: true,
              );
          _abort = () {
            unawaited(sub.cancel());
            if (!done.isCompleted) done.complete();
          };
          try {
            await done.future;
          } finally {
            _abort = null;
            await sub.cancel();
          }
        } finally {
          await sink.close();
        }
        if (_cancelRequested) {
          log.info(name, 'download cancelled');
          if (await file.exists()) await file.delete();
          _lastOutcome = 'cancelled';
          return null;
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
      _lastOutcome = mode == 'silent' ? 'silent' : 'confirm';
      log.info(
        name,
        mode == 'silent'
            ? 'installing silently; the app restarts itself when done'
            : 'waiting for the install to be confirmed on the device screen',
      );
      return null;
    } catch (e) {
      // A cancel closes the client mid-transfer, which surfaces here as a
      // connection error; that is the cancel doing its job, not a failure.
      if (_cancelRequested) {
        log.info(name, 'download cancelled');
        _lastOutcome = 'cancelled';
        return null;
      }
      log.warn(name, 'update failed: $e');
      await _resumeKioskIfPaused();
      return _fail('Update failed: $e');
    } finally {
      _downloadClient = null;
      _abort = null;
      client.close();
      progress.value = null;
    }
  }

  /// Records a failed attempt for getUpdateStatus and hands the message on.
  String _fail(String message) {
    _lastOutcome = 'failed';
    _lastError = message;
    return message;
  }

  /// Aborts the running download; a no-op while none runs. The update
  /// notice stays up, so the download can simply be started again — the
  /// escape hatch for a transfer that stalled and would otherwise block
  /// retries until an app restart (#272).
  void cancelDownload() {
    if (progress.value == null) return;
    _cancelRequested = true;
    // Both ends: the subscription so the waiter unblocks now, and the
    // client so the socket actually dies rather than draining on.
    _abort?.call();
    _downloadClient?.close();
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
