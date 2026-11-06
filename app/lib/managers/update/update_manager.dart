import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import 'release_apk.dart';
import 'update_http_client.dart';

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

/// An APK the remote admin uploaded, inspected and waiting to be installed
/// (issue #566): a kiosk on a network without internet or a file server
/// gets its update pushed from the admin's browser instead.
class UploadedApk {
  const UploadedApk({
    required this.file,
    required this.version,
    required this.buildNumber,
    required this.size,
  });

  final File file;
  final String version;
  final int buildNumber;
  final int size;

  Map<String, Object?> toJson() => {
    'version': version,
    'buildNumber': buildNumber,
    'size': size,
    'path': file.path,
  };
}

/// Watches the GitHub releases for a newer APK and, on request, downloads it
/// and hands it to the Android package installer.
///
/// A wall tablet has no Play Store nudging it, so the app checks on its own:
/// once shortly after start and then twice a day. The result feeds the
/// drawer's notice and the Home Assistant update entity (over ESPHome); nothing
/// downloads or installs until a tap in either place asks for it.
class UpdateManager extends Manager {
  UpdateManager(
    super.bus,
    super.commands,
    super.log, {
    this.useShizuku = _shizukuDisabled,
    this.customSource = _noCustomSource,
  });

  final bool Function() useShizuku;
  static bool _shizukuDisabled() => false;

  /// The custom repository folder, or null while releases come from
  /// GitHub. A folder on the user's own web server that holds a copy of
  /// GitHub's releases list as `releases.json` and the APKs it names, for
  /// kiosks on a network without internet access. Read on every check, so
  /// a change in settings takes effect at the next one. An empty string is
  /// the custom source picked with no URL entered yet: the check reports
  /// that rather than quietly asking GitHub, which such a network cannot
  /// reach anyway.
  final String? Function() customSource;
  static String? _noCustomSource() => null;

  /// The releases list rather than `/releases/latest`: one request either
  /// way, but the list also carries the bodies of releases the device
  /// skipped, which is what lets the notice show everything that changed
  /// since the running version (#165) without a request per release. The
  /// window is a display cap, not a paging cursor: a device further behind
  /// than this gets the newest releases and a pointer to the history.
  static const _releasesUrl =
      'https://api.github.com/repos/jxlarrea/kiosk-satellite/'
      'releases?per_page=30';

  /// The file a custom repository serves in place of the GitHub query:
  /// that query's response, saved as is. Same parser, same ABI selection,
  /// same notes; only the asset URLs are re-rooted at the folder.
  static const releasesFileName = 'releases.json';

  /// Where the next check asks: GitHub, or the custom folder's releases
  /// file. Null when the custom source is picked without a URL.
  Uri? _releasesUri(String? source) {
    if (source == null) return Uri.parse(_releasesUrl);
    if (source.isEmpty) return null;
    return Uri.parse('$source/$releasesFileName');
  }

  /// The download URL of [apk] as the source serves it: GitHub's own for
  /// GitHub, the asset's name under the custom folder otherwise. A mirror
  /// holds the files under the names GitHub gave them, so the saved
  /// releases list needs no editing.
  String? _assetUrl(Map<String, dynamic> apk, String? source) {
    if (source == null) return apk['browser_download_url'] as String?;
    final name = apk['name'] as String?;
    if (name == null || name.isEmpty) return null;
    return '$source/${Uri.encodeComponent(name)}';
  }

  /// The client for [source]: strict verification for GitHub, the app's
  /// own certificate policy (the Ignore SSL errors setting included) for a
  /// server on the user's network, which is where a custom source lives.
  http.Client _clientFor(String? source) =>
      source == null ? clientFactory() : localClientFactory();

  /// App-scoped (see ApkInstaller). The Shizuku opt-in overrides installation.
  /// Otherwise native silent installation, the ADB helper and confirmation keep their order.
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
  late final String _packageName;

  /// The running build's versionCode, what an uploaded APK is measured
  /// against: Android refuses a lower one, so the upload is refused first
  /// with a message that says so.
  int _currentBuild = 0;

  /// The uploaded APK waiting to be installed, or null.
  UploadedApk? _uploaded;
  UploadedApk? get uploaded => _uploaded;

  /// True while an uploaded APK is being handed to the installer. The
  /// download path's re-entry guard is [progress], which an upload never
  /// sets; this is the same guard for the other path, and each refuses to
  /// start while the other runs.
  bool _installing = false;
  bool get installing => _installing;

  /// Read once at init, not through the getDeviceInfo command: that command
  /// gathers CPU load, whose sampler pays a 500ms paired read whenever it is
  /// called twice in quick succession — exactly what the About page's
  /// info-then-update-status sequence did, making getUpdateStatus a half
  /// second call for one integer. Null off Android.
  int? _sdkInt;

  /// Android's ABI preference order. Empty off Android, using universal.
  @visibleForTesting
  List<String> supportedAbis = const [];

  /// Builds the client for the release query and the APK download from
  /// GitHub. Swapped in tests; production always hands back a real one.
  @visibleForTesting
  http.Client Function() clientFactory = createUpdateHttpClient;

  /// The same for a custom repository, see [_clientFor].
  @visibleForTesting
  http.Client Function() localClientFactory = createLocalUpdateHttpClient;

  Timer? _firstCheck;
  Timer? _timer;

  /// Last whole percent pushed onto the bus; keeps the progress stream from
  /// flooding listeners (the ESPHome entity republishes every event it hears).
  int _lastPercent = -1;

  /// When the last mid-download percent went onto the bus (see the
  /// progress listener's one-a-second cap).
  DateTime _lastProgressPublish = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Future<void> init() async {
    final pkg = await PackageInfo.fromPlatform();
    _currentVersion = pkg.version;
    _packageName = pkg.packageName;
    _currentBuild = int.tryParse(pkg.buildNumber) ?? 0;
    if (Platform.isAndroid) {
      final android = await DeviceInfoPlugin().androidInfo;
      _sdkInt = android.version.sdkInt;
      supportedAbis = android.supportedAbis;
    }
    // The installer's asynchronous outcomes. Success never arrives: Android
    // kills the process as it swaps the code, and the relaunch receiver
    // brings the app back already running the new version.
    _installer.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'installDeclined':
          log.info(
            name,
            'install declined on the device screen (${call.arguments})',
          );
          _lastOutcome = 'cancelled';
          await _resumeKioskIfPaused();
        case 'silentInstallRefused':
          await _retryWithConfirmation('${call.arguments}');
        case 'installFailed':
          log.warn(name, 'install failed: ${call.arguments}');
          _fail('Install failed: ${call.arguments}');
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
      // getUpdateStatus execution and a state push on the ESPHome
      // surface, and on a fast download the percent flips several
      // times a second — a storm reported as log spam and CPU load on weak
      // tablets (#272). The transitions in and out of "downloading" always
      // go out, so nothing ever misses the start or the end.
      final now = DateTime.now();
      final transition = p == null || _lastPercent == -1;
      if (!transition &&
          now.difference(_lastProgressPublish) < const Duration(seconds: 1)) {
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
          name: 'getUpdateInstallerStatus',
          description:
              'Android silent installation and live update helper status',
          quiet: true,
          handler: (_) async => CommandResult.ok(await installerStatus()),
        ),
      )
      ..register(
        Command(
          name: 'stopUpdateHelper',
          description:
              'Stop the ADB update helper until it is started through ADB again',
          handler: (_) async {
            final state = await _installer.invokeMethod<String>(
              'stopUpdateHelper',
            );
            if (state == 'busy') {
              return CommandResult.fail(
                'An update is being installed. Try again when it finishes.',
              );
            }
            return CommandResult.ok(state);
          },
        ),
      )
      ..register(
        Command(
          name: 'getUpdateStatus',
          description:
              'Running version, the newer GitHub release if any, and the '
              'APK download progress (0..1, null while idle)',
          // Executed per progress event by the ESPHome listener
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
            'uploaded': _uploaded?.toJson(),
            'installing': _installing,
            // Only worth asking Android while there is something to install.
            if (available.value != null) 'silent': await _installsSilently(),
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
              'Download the newer release APK and install it. Silent when '
              'Android permits it, the update helper is running or Shizuku updates are enabled and authorized. Otherwise '
              'Android asks for confirmation on the device screen',
          handler: (_) async {
            if (available.value == null) {
              return CommandResult.fail('no update available');
            }
            if (progress.value != null) {
              return CommandResult.fail('a download is already running');
            }
            if (_installing) {
              return CommandResult.fail('an install is already running');
            }
            unawaited(downloadAndInstall());
            return CommandResult.ok(true);
          },
        ),
      )
      ..register(
        Command(
          name: 'receiveUploadedUpdate',
          description:
              'Take in an APK uploaded through POST /api/update/upload, '
              'check that it is a newer Kiosk Satellite build and keep it '
              'for installUploadedApk. In-process only: the APK travels as '
              'the raw body of that endpoint, not as a command parameter',
          params: const {
            'stream': 'the APK bytes (in-process only)',
            'length': 'the byte count announced by the upload, if any',
          },
          // The stream object must not be printed into the log.
          quiet: true,
          handler: (p) async {
            final stream = p['stream'];
            if (stream is! Stream<List<int>>) {
              return CommandResult.fail(
                'the APK travels as the raw body of POST /api/update/upload',
              );
            }
            final length = p['length'];
            try {
              return CommandResult.ok(
                await receiveUpload(
                  stream,
                  length: length is int && length > 0 ? length : null,
                ),
              );
            } on StateError catch (e) {
              return CommandResult.fail(e.message);
            }
          },
        ),
      )
      ..register(
        Command(
          name: 'installUploadedApk',
          description:
              'Install the APK uploaded through POST /api/update/upload. '
              'Silent or confirmed on the device screen under the same '
              'rules as installUpdate; getUpdateStatus reports the outcome '
              'in lastOutcome once installing turns false',
          handler: (_) async {
            final up = _uploaded;
            if (up == null) {
              return CommandResult.fail('no uploaded APK is waiting');
            }
            if (progress.value != null) {
              return CommandResult.fail('a download is already running');
            }
            if (_installing) {
              return CommandResult.fail('an install is already running');
            }
            unawaited(installUploaded(up));
            return CommandResult.ok(up.toJson());
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
    final source = customSource();
    final uri = _releasesUri(source);
    if (uri == null) {
      log.warn(
        name,
        'release check skipped: the custom update repository has no URL',
      );
      return (reachable: false, info: null);
    }
    final client = _clientFor(source);
    try {
      final res = await client.get(
        uri,
        headers: const {'Accept': 'application/vnd.github+json'},
      );
      if (res.statusCode != 200) {
        log.warn(
          name,
          'release check failed: HTTP ${res.statusCode} from ${uri.host}',
        );
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
      final apk = selectReleaseApk(assets, tag, supportedAbis);
      if (apk == null) {
        log.warn(name, 'release $tag has no compatible APK');
        return (reachable: false, info: null);
      }
      final url = _assetUrl(apk, source);
      if (tag.isEmpty || url == null) return (reachable: false, info: null);
      final newer = _isNewer(tag, _currentVersion);
      if (newer) log.info(name, 'selected APK: ${apk['name']}');
      log.info(
        name,
        'latest release $tag on ${source == null ? 'GitHub' : uri.host}, '
        'running $_currentVersion: '
        '${newer ? 'update available' : 'up to date'}',
      );
      return (
        reachable: true,
        info: newer
            ? UpdateInfo(
                version: tag,
                apkUrl: url,
                notes: _combinedNotes(releases, tagOf),
                releaseUrl:
                    latest['html_url'] as String? ??
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
    if (info == null || progress.value != null || _installing) return null;
    final useShizukuUpdates = useShizuku();
    progress.value = 0;
    _lastOutcome = null;
    _lastError = null;
    _cancelRequested = false;
    final client = _clientFor(customSource());
    _downloadClient = client;
    try {
      if (useShizukuUpdates) await _needsConfirmation(shizuku: true);
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
      // file per release asset, anything else swept first, so the cache never
      // accumulates old APKs and a leftover from an earlier release can
      // never impersonate the new one. The name must carry the version
      // because byte size alone cannot tell releases apart: two builds
      // differing by nothing but a same-length version string produce
      // APKs of identical size, and on exactly such a pair the reuse
      // check below installed the cached old release as if it were the
      // new download, "updating" the device to the version it already ran.
      final dir = await _updatesDir();
      // A release can gain a split after its universal APK was cached.
      // Include asset identity so equal-sized variants never share a file.
      final assetKey = sha256
          .convert(utf8.encode(info.apkUrl))
          .toString()
          .substring(0, 12);
      final file = File(
        '${dir.path}/kiosk-satellite-update-${info.version}-$assetKey.apk',
      );
      await for (final stale in dir.list()) {
        if (stale.path != file.path) await stale.delete();
      }
      // An uploaded APK waiting in the same folder went with the sweep.
      _uploaded = null;
      // An earlier attempt whose install never went through (declined, or
      // the confirmation could not show) already paid for this download;
      // a file of this version's name whose size matches what GitHub
      // reports for the asset is that download, not a truncated one
      // (issue #170).
      final expected = info.apkSize;
      if (expected != null &&
          await file.exists() &&
          await file.length() == expected) {
        log.info(name, 'reusing the already-downloaded v${info.version} APK');
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
      await _installFile(file, useShizukuUpdates: useShizukuUpdates);
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

  /// The updates/ folder of the app cache: what the manifest's FileProvider
  /// maps, so the update helper and the confirm installer can read from it.
  /// Holds one APK at a time, downloaded or uploaded.
  Future<Directory> _updatesDir() async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/updates');
    await dir.create(recursive: true);
    return dir;
  }

  /// The installer copies the APK into its session before committing, so
  /// an upload needs room for two copies plus some slack for the install.
  static const _installSlack = 64 * 1024 * 1024;

  /// Streams an uploaded APK into the updates folder and inspects it
  /// (issue #566). Throws a [StateError] with the reason when the file is
  /// refused: too big for the free space, cut short, not an APK, another
  /// app's package, or an older build than the one running. The accepted
  /// file waits for [installUploaded]; a new upload replaces it. Returns
  /// what was accepted, as getUpdateStatus reports it.
  Future<Map<String, Object?>> receiveUpload(
    Stream<List<int>> body, {
    int? length,
  }) async {
    if (progress.value != null) {
      throw StateError('A download is running. Wait for it to finish.');
    }
    if (_installing) {
      throw StateError('An install is running. Wait for it to finish.');
    }
    final dir = await _updatesDir();
    _uploaded = null;
    await for (final stale in dir.list()) {
      await stale.delete();
    }
    if (length != null) {
      final free = await _freeSpace();
      if (free != null && free < length * 2 + _installSlack) {
        throw StateError(
          'Not enough free space: the APK is ${_mb(length)} MB and the '
          'install needs about ${_mb(length * 2 + _installSlack)} MB, but '
          'the device has ${_mb(free)} MB free.',
        );
      }
    }
    final part = File('${dir.path}/upload.apk.part');
    Never refuse(String reason) {
      if (part.existsSync()) part.deleteSync();
      log.warn(name, 'refused an uploaded APK: $reason');
      throw StateError(reason);
    }

    var got = 0;
    final sink = part.openWrite();
    try {
      // addStream has backpressure built in: the socket waits for the
      // flash, not the other way round.
      await sink.addStream(
        body.map((chunk) {
          got += chunk.length;
          return chunk;
        }),
      );
    } catch (e) {
      // The browser went away mid-transfer (tab closed, Wi-Fi dropped):
      // nothing to keep, and the half file must not wait for the sweep.
      // The sink is already in error and its close may say so again.
      try {
        await sink.close();
      } catch (_) {}
      refuse('The upload was interrupted after ${_mb(got)} MB: $e');
    }
    await sink.close();

    if (got == 0) refuse('The upload was empty.');
    if (length != null && got != length) {
      refuse(
        'The upload ended early: ${_mb(got)} of ${_mb(length)} MB arrived.',
      );
    }
    final apk = await _inspectApk(part);
    if (apk == null) refuse('The file is not an Android APK.');
    final package = apk['packageName'] as String?;
    if (package != _packageName) {
      refuse(
        'The APK is ${package ?? 'another package'}, not Kiosk Satellite '
        '($_packageName).',
      );
    }
    final version = '${apk['versionName'] ?? ''}';
    final build = (apk['versionCode'] as num?)?.toInt() ?? 0;
    if (build < _currentBuild) {
      refuse(
        'The APK is version $version (build $build), older than the '
        'running $_currentVersion (build $_currentBuild). Downgrades are '
        'refused: Android would not install one either.',
      );
    }
    // Named like a download but never like one: a download's key is a
    // hash of the asset URL, so its size-based reuse check can never pick
    // this file up as its own.
    final file = File('${dir.path}/kiosk-satellite-update-$version-upload.apk');
    await part.rename(file.path);
    _uploaded = UploadedApk(
      file: file,
      version: version,
      buildNumber: build,
      size: got,
    );
    log.info(
      name,
      'received an uploaded APK: v$version (build $build, ${_mb(got)} MB)'
      '${build == _currentBuild ? ', the build already running' : ''}',
    );
    bus.publish(const UpdateStateChanged());
    return {
      ..._uploaded!.toJson(),
      'currentVersion': _currentVersion,
      'currentBuild': _currentBuild,
    };
  }

  static String _mb(int bytes) => (bytes / 1048576).toStringAsFixed(1);

  /// Installs the uploaded APK. The outcome lands in lastOutcome the way a
  /// download's does; the file stays so a declined install can be retried
  /// without uploading again.
  Future<String?> installUploaded(UploadedApk up) async {
    if (progress.value != null || _installing) {
      return 'an update is already running';
    }
    _installing = true;
    _lastOutcome = null;
    _lastError = null;
    bus.publish(const UpdateStateChanged());
    try {
      if (!await up.file.exists()) {
        _uploaded = null;
        return _fail('The uploaded APK is gone. Upload it again.');
      }
      log.info(
        name,
        'installing the uploaded v${up.version} (build ${up.buildNumber})',
      );
      await _installFile(up.file, useShizukuUpdates: useShizuku());
      return null;
    } catch (e) {
      log.warn(name, 'install of the uploaded APK failed: $e');
      await _resumeKioskIfPaused();
      return _fail('Install failed: $e');
    } finally {
      _installing = false;
      bus.publish(const UpdateStateChanged());
    }
  }

  /// Package name, version name and version code of the APK at [file], or
  /// null when Android cannot parse it as one.
  Future<Map<String, dynamic>?> _inspectApk(File file) async {
    try {
      return await _installer.invokeMapMethod<String, dynamic>('inspectApk', {
        'path': file.path,
      });
    } on MissingPluginException {
      return null;
    }
  }

  /// Free bytes on the volume the app cache lives on; null when the
  /// platform cannot say, in which case the upload is simply attempted.
  Future<int?> _freeSpace() async {
    try {
      return await _installer.invokeMethod<int>('freeSpace');
    } catch (_) {
      return null;
    }
  }

  /// Hands an APK that is already on disk to the installer: the download's
  /// last step, and the whole of an uploaded APK's install (issue #566).
  /// Stands the kiosk down first when Android's confirm screen is coming,
  /// and falls back to the system installer when the update helper goes
  /// away between preflight and commit. Throws on an installer failure;
  /// the caller turns that into the recorded outcome.
  Future<void> _installFile(
    File file, {
    required bool useShizukuUpdates,
  }) async {
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
    if (await _needsConfirmation(shizuku: useShizukuUpdates) ||
        await _stepsAsideForInstall()) {
      _kioskPaused = (await commands.execute(
        'pauseKioskForInstall',
        const {},
      )).ok;
    }
    _apkPath = file.path;
    var mode = await _installer.invokeMethod<String>('installApk', {
      'path': file.path,
      if (useShizukuUpdates) 'useShizuku': true,
    });
    if (mode == 'fallback') {
      if (useShizukuUpdates) {
        throw StateError(
          'Shizuku could not install the update. No confirmation installer was opened.',
        );
      }
      // The helper can disappear between preflight and upload. Native
      // code only returns this before a commit could reach the helper.
      if (!_kioskPaused) {
        _kioskPaused = (await commands.execute(
          'pauseKioskForInstall',
          const {},
        )).ok;
      }
      mode = await _installer.invokeMethod<String>('installApk', {
        'path': file.path,
        'useSystemInstaller': true,
      });
    }
    // A native failure callback can arrive before the method reply.
    _lastOutcome ??= mode == 'silent' ? 'silent' : 'confirm';
    log.info(
      name,
      mode == 'silent'
          ? 'installing silently; the app restarts itself when done'
          : 'waiting for the install to be confirmed on the device screen',
    );
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
  Future<bool> _needsConfirmation({bool shizuku = false}) async {
    try {
      return await _installer.invokeMethod<bool>(
            'needsConfirmation',
            shizuku ? {'useShizuku': true} : null,
          ) ??
          true;
    } catch (_) {
      if (shizuku) rethrow;
      return false;
    }
  }

  /// Whether the install moves the screen to the device's other launcher
  /// first (see UpdateHomeHandoff). The pin would block that move and the
  /// foreground reclaim would undo it, so the kiosk stands down for it the
  /// same way it does for a confirmation.
  Future<bool> _stepsAsideForInstall() async {
    try {
      return await _installer.invokeMethod<bool>('stepsAsideForInstall') ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Whether the next install goes through without a confirmation on the
  /// device: Shizuku installs it, or Android lets this app install on its
  /// own (device owner, the update helper).
  Future<bool> _installsSilently() async {
    try {
      if (useShizuku()) {
        return (await installerStatus())['shizukuReady'] == true;
      }
      return !await _needsConfirmation();
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> installerStatus() async {
    final status = await _installer.invokeMapMethod<String, dynamic>(
      'getInstallerStatus',
    );
    return {...?status, 'shizukuEnabled': useShizuku()};
  }

  /// Whether the kiosk stood down for this install and still owes a
  /// re-arm. Cleared by the declined/failed callbacks; a successful
  /// install ends the process instead.
  bool _kioskPaused = false;

  /// The APK most recently handed to the installer, for the retry below.
  String? _apkPath;

  /// Android accepted a silent install and then aborted it with nothing on
  /// screen. Xiaomi's MIUI and HyperOS do this to every silent update even
  /// though stock Android allows it (issue #768), which left those tablets
  /// unable to update at all. The same APK goes through the confirm screen
  /// instead. Only a silent session can trigger this, and the retry is a
  /// confirm session, so it happens at most once per install.
  Future<void> _retryWithConfirmation(String message) async {
    final path = _apkPath;
    log.warn(
      name,
      'Android refused the silent install ($message); asking for '
      'confirmation on the device screen instead',
    );
    if (path == null || !await File(path).exists()) {
      _fail('Install failed: $message');
      await _resumeKioskIfPaused();
      return;
    }
    try {
      if (!_kioskPaused) {
        _kioskPaused = (await commands.execute(
          'pauseKioskForInstall',
          const {},
        )).ok;
      }
      await _installer.invokeMethod<String>('installApk', {
        'path': path,
        'useSystemInstaller': true,
      });
      _lastOutcome = 'confirm';
      log.info(
        name,
        'waiting for the install to be confirmed on the device screen',
      );
    } catch (e) {
      log.warn(name, 'install failed: $e');
      _fail('Install failed: $e');
      await _resumeKioskIfPaused();
    }
  }

  Future<void> _resumeKioskIfPaused() async {
    if (!_kioskPaused) return;
    _kioskPaused = false;
    await commands.execute('resumeKioskAfterInstall', const {});
  }
}
