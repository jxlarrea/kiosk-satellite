import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/update/update_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The update notice can sit on the drawer for half a day (the periodic check
/// runs twice a day) and stays up until someone acts on it, so the release it
/// names is not necessarily the newest one by the time the download starts.
/// These cover what the install does about that.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const installer = MethodChannel('kiosk_satellite/installer');
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Directory cache;
  late UpdateManager update;
  late CommandRegistry registry;
  late List<String> installed;
  late List<String> kioskCalls;
  var needsConfirm = false;
  var shizukuEnabled = false;
  var shizukuReady = true;
  final installArguments = <Map>[];
  var helperFallback = false;
  var helperCommitFailure = false;
  // What the native side reads out of an uploaded APK, and the free bytes
  // it reports for the space check (#566).
  Map<String, Object?>? inspected;
  int? freeSpace;

  /// One GitHub release object, as the releases list carries them.
  Map<String, Object?> entry(
    String tag, {
    bool prerelease = false,
    int? size,
  }) => {
    'tag_name': 'v$tag',
    'html_url':
        'https://github.com/jxlarrea/kiosk-satellite/'
        'releases/tag/v$tag',
    'body': 'Notes for $tag',
    'prerelease': prerelease,
    'draft': false,
    'assets': [
      {
        'name': 'kiosk-satellite-$tag.apk',
        'browser_download_url': 'https://example.invalid/$tag.apk',
        'size': ?size,
      },
    ],
  };

  /// The releases-list payload, newest first, as the check fetches it.
  String releases(List<Map<String, Object?>> entries) => jsonEncode(entries);

  String release(String tag) => releases([entry(tag)]);

  bool isReleaseQuery(http.BaseRequest request) =>
      request.url.host == 'api.github.com';

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('ks_update_test');
    installed = [];
    messenger.setMockMethodCallHandler(
      pathProvider,
      (call) async =>
          call.method == 'getTemporaryDirectory' ? cache.path : null,
    );
    needsConfirm = false;
    shizukuEnabled = false;
    shizukuReady = true;
    installArguments.clear();
    helperFallback = false;
    helperCommitFailure = false;
    inspected = {
      'packageName': 'me.jxl.kiosk_satellite',
      'versionName': '1.2.0',
      'versionCode': 5,
    };
    freeSpace = null;
    kioskCalls = [];
    messenger.setMockMethodCallHandler(installer, (call) async {
      if (call.method == 'inspectApk') return inspected;
      if (call.method == 'freeSpace') return freeSpace;
      if (call.method == 'needsConfirmation') {
        if ((call.arguments as Map?)?['useShizuku'] == true) {
          if (!shizukuReady) {
            throw PlatformException(
              code: 'install',
              message: 'Shizuku is unavailable',
            );
          }
          return false;
        }
        return needsConfirm;
      }
      if (call.method != 'installApk') return null;
      installArguments.add(Map.from(call.arguments as Map));
      if (helperCommitFailure) {
        throw PlatformException(
          code: 'install',
          message: 'Lost contact after committing',
        );
      }
      if (helperFallback) {
        if ((call.arguments as Map)['useSystemInstaller'] != true) {
          return 'fallback';
        }
        expect(kioskCalls, ['pause']);
      }
      installed.add((call.arguments as Map)['path'] as String);
      return needsConfirm ? 'confirm' : 'silent';
    });
    PackageInfo.setMockInitialValues(
      appName: 'Kiosk Satellite',
      packageName: 'me.jxl.kiosk_satellite',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final log = Logger();
    registry = CommandRegistry(log);
    // Stand-ins for the kiosk manager's install pause (issue #170); the
    // update manager only ever executes them by name.
    registry.register(
      Command(
        name: 'pauseKioskForInstall',
        description: '',
        handler: (_) async {
          kioskCalls.add('pause');
          return const CommandResult.ok();
        },
      ),
    );
    registry.register(
      Command(
        name: 'resumeKioskAfterInstall',
        description: '',
        handler: (_) async {
          kioskCalls.add('resume');
          return const CommandResult.ok();
        },
      ),
    );
    update = UpdateManager(
      EventBus(),
      registry,
      log,
      useShizuku: () => shizukuEnabled,
    );
  });

  tearDown(() async {
    await update.dispose();
    messenger.setMockMethodCallHandler(pathProvider, null);
    messenger.setMockMethodCallHandler(installer, null);
    if (await cache.exists()) await cache.delete(recursive: true);
  });

  /// Runs the check that raises the notice, with GitHub offering [tag].
  Future<void> notice(String tag) async {
    update.clientFactory = () =>
        MockClient((request) async => http.Response(release(tag), 200));
    await update.init();
    expect(await update.check(), isTrue);
    expect(update.available.value?.version, tag);
  }

  group('custom repository', () {
    const folder = 'http://nas.local/kiosk-satellite';
    late List<Uri> requested;
    late List<Uri> strictRequested;

    /// A mirror of [entries] under [folder]: the saved releases list and
    /// the APK files under the names GitHub gave them, served by a client
    /// that fails on anything else. GitHub itself is unreachable, as on
    /// the network such a mirror is for.
    void mirror(List<Map<String, Object?>> entries, List<int> apkBytes) {
      requested = [];
      strictRequested = [];
      update.localClientFactory = () => MockClient((request) async {
        requested.add(request.url);
        if (request.url.toString() == '$folder/releases.json') {
          return http.Response(releases(entries), 200);
        }
        if (request.url.path.endsWith('.apk')) {
          return http.Response.bytes(apkBytes, 200);
        }
        return http.Response('not found', 404);
      });
      update.clientFactory = () => MockClient((request) async {
        strictRequested.add(request.url);
        throw const SocketException('no route to GitHub');
      });
    }

    setUp(() {
      update = UpdateManager(
        EventBus(),
        registry,
        Logger(),
        useShizuku: () => shizukuEnabled,
        customSource: () => folder,
      );
    });

    test('the check reads releases.json from the folder and roots the APK '
        'there', () async {
      final apkBytes = List<int>.generate(100, (i) => i);
      mirror([entry('1.1.0', size: apkBytes.length)], apkBytes);
      await update.init();
      expect(await update.check(), isTrue);
      expect(update.available.value?.version, '1.1.0');
      expect(
        update.available.value?.apkUrl,
        '$folder/kiosk-satellite-1.1.0.apk',
      );
      expect(update.available.value?.apkSize, apkBytes.length);
      expect(strictRequested, isEmpty);

      expect(await update.downloadAndInstall(), isNull);
      expect(installed, hasLength(1));
      expect(await File(installed.single).readAsBytes(), apkBytes);
      expect(requested.map((u) => u.toString()), [
        '$folder/releases.json',
        '$folder/releases.json',
        '$folder/kiosk-satellite-1.1.0.apk',
      ]);
    });

    test('a folder without the releases file leaves the notice down', () async {
      mirror([], const []);
      update.localClientFactory = () =>
          MockClient((request) async => http.Response('not found', 404));
      await update.init();
      expect(await update.check(), isFalse);
      expect(update.available.value, isNull);
    });

    test('an older release in the folder is up to date', () async {
      mirror([entry('0.9.0')], const []);
      await update.init();
      expect(await update.check(), isTrue);
      expect(update.available.value, isNull);
    });

    test(
      'the custom source without a URL never falls back to GitHub',
      () async {
        update = UpdateManager(
          EventBus(),
          registry,
          Logger(),
          customSource: () => '',
        );
        var asked = 0;
        update.clientFactory = () => MockClient((request) async {
          asked++;
          return http.Response(release('2.0.0'), 200);
        });
        update.localClientFactory = update.clientFactory;
        await update.init();
        expect(await update.check(), isFalse);
        expect(update.available.value, isNull);
        expect(asked, 0);
      },
    );
  });

  test('the install downloads the release cut after the notice', () async {
    await notice('1.1.0');
    final asked = <String>[];
    update.clientFactory = () => MockClient((request) async {
      asked.add(request.url.toString());
      return isReleaseQuery(request)
          ? http.Response(release('1.2.0'), 200)
          : http.Response.bytes(List.filled(2048, 7), 200);
    });

    expect(await update.downloadAndInstall(), isNull);

    // The notice named 1.1.0; nothing ever asks for that APK.
    expect(asked, isNot(contains('https://example.invalid/1.1.0.apk')));
    expect(asked, contains('https://example.invalid/1.2.0.apk'));
    expect(installed, hasLength(1));
    expect(await File(installed.single).length(), 2048);
    // Everything reading the notice (drawer, remote admin, the Home
    // Assistant update entity) follows the version actually being installed.
    expect(update.available.value?.version, '1.2.0');
    expect(update.progress.value, isNull);
  });

  test('an unreachable GitHub still installs the known release', () async {
    await notice('1.1.0');
    final asked = <String>[];
    update.clientFactory = () => MockClient((request) async {
      asked.add(request.url.toString());
      return isReleaseQuery(request)
          ? http.Response('rate limited', 403)
          : http.Response.bytes(List.filled(64, 7), 200);
    });

    expect(await update.downloadAndInstall(), isNull);

    expect(asked, contains('https://example.invalid/1.1.0.apk'));
    expect(installed, hasLength(1));
    expect(update.available.value?.version, '1.1.0');
  });

  test('a release pulled since the notice installs nothing', () async {
    await notice('1.1.0');
    final asked = <String>[];
    update.clientFactory = () => MockClient((request) async {
      asked.add(request.url.toString());
      return isReleaseQuery(request)
          ? http.Response(release('1.0.0'), 200)
          : http.Response.bytes(List.filled(64, 7), 200);
    });

    expect(await update.downloadAndInstall(), contains('Already up to date'));

    expect(asked.any((url) => url.endsWith('.apk')), isFalse);
    expect(installed, isEmpty);
    // The notice clears, so nothing keeps offering the release that is gone.
    expect(update.available.value, isNull);
    expect(update.progress.value, isNull);
  });

  test('one release behind shows that body alone, untouched', () async {
    update.clientFactory = () => MockClient(
      (request) async =>
          http.Response(releases([entry('1.1.0'), entry('1.0.0')]), 200),
    );
    await update.init();
    expect(await update.check(), isTrue);
    expect(update.available.value?.notes, 'Notes for 1.1.0');
  });

  test('skipped releases stack their notes newest first', () async {
    update.clientFactory = () => MockClient(
      (request) async => http.Response(
        releases([entry('1.3.0'), entry('1.2.0'), entry('1.0.0')]),
        200,
      ),
    );
    await update.init();
    expect(await update.check(), isTrue);
    expect(update.available.value?.version, '1.3.0');
    final notes = update.available.value!.notes;
    expect(
      notes.indexOf('Notes for 1.3.0'),
      lessThan(notes.indexOf('Notes for 1.2.0')),
    );
    expect(notes, contains('# Version 1.3.0'));
    expect(notes, contains('# Version 1.2.0'));
    // The running release and older stay out, and the whole gap fit the
    // fetch window, so nothing points at the release history.
    expect(notes, isNot(contains('Notes for 1.0.0')));
    expect(notes, isNot(contains('releases page')));
  });

  test('a gap beyond the fetch window points at the history', () async {
    update.clientFactory = () => MockClient(
      (request) async =>
          http.Response(releases([entry('1.3.0'), entry('1.2.0')]), 200),
    );
    await update.init();
    expect(await update.check(), isTrue);
    expect(update.available.value?.notes, contains('releases page'));
  });

  test('prereleases never count as the latest release', () async {
    update.clientFactory = () => MockClient(
      (request) async => http.Response(
        releases([entry('1.2.0', prerelease: true), entry('1.1.0')]),
        200,
      ),
    );
    await update.init();
    expect(await update.check(), isTrue);
    expect(update.available.value?.version, '1.1.0');
    expect(update.available.value?.notes, isNot(contains('1.2.0')));
  });

  /// Delivers an installer callback the way the native side would.
  Future<void> installerEvent(String method, [Object? arguments]) async {
    await messenger.handlePlatformMessage(
      'kiosk_satellite/installer',
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(method, arguments),
      ),
      (_) {},
    );
  }

  test('a second install attempt reuses the downloaded APK instead of '
      'downloading it again', () async {
    await notice('1.1.0');
    final asked = <String>[];
    update.clientFactory = () => MockClient((request) async {
      asked.add(request.url.toString());
      return isReleaseQuery(request)
          ? http.Response(releases([entry('1.1.0', size: 2048)]), 200)
          : http.Response.bytes(List.filled(2048, 7), 200);
    });

    expect(await update.downloadAndInstall(), isNull);
    expect(asked, contains('https://example.invalid/1.1.0.apk'));

    // The person declined (or the confirmation never showed); the notice
    // is still up and they try again.
    await installerEvent('installDeclined');
    asked.clear();
    expect(await update.downloadAndInstall(), isNull);

    expect(asked.any((url) => url.endsWith('.apk')), isFalse);
    expect(installed, hasLength(2));
  });

  test('startup deletes installed downloads and keeps a newer one '
      '(#1359)', () async {
    final dir = Directory('${cache.path}/updates');
    await dir.create(recursive: true);
    Future<File> put(String name) =>
        File('${dir.path}/$name').writeAsBytes([1]);
    final installedNow = await put(
      'kiosk-satellite-update-1.0.0-0123456789ab.apk',
    );
    final older = await put('kiosk-satellite-update-0.9.0-upload.apk');
    final part = await put('upload.apk.part');
    final newer = await put('kiosk-satellite-update-1.1.0-0123456789ab.apk');

    await update.init();

    expect(await installedNow.exists(), isFalse);
    expect(await older.exists(), isFalse);
    expect(await part.exists(), isFalse);
    expect(await newer.exists(), isTrue);
  });

  test('a cached APK from the previous release is never reused, even at '
      'the exact byte size of the new one', () async {
    // Two consecutive builds can differ by nothing but a same-length
    // version string and come out byte-identical in size; a size-only
    // reuse check "updated" a device by reinstalling the release it
    // already ran.
    await notice('1.1.0');
    final dir = Directory('${cache.path}/updates');
    await dir.create(recursive: true);
    final stale = File('${dir.path}/kiosk-satellite-update-1.0.0.apk');
    await stale.writeAsBytes(List.filled(2048, 9)); // old release, same size
    final asked = <String>[];
    update.clientFactory = () => MockClient((request) async {
      asked.add(request.url.toString());
      return isReleaseQuery(request)
          ? http.Response(releases([entry('1.1.0', size: 2048)]), 200)
          : http.Response.bytes(List.filled(2048, 7), 200);
    });

    expect(await update.downloadAndInstall(), isNull);

    expect(asked, contains('https://example.invalid/1.1.0.apk'));
    expect(
      installed.single,
      matches(r'kiosk-satellite-update-1\.1\.0-[0-9a-f]{12}\.apk$'),
    );
    expect((await File(installed.single).readAsBytes()).first, 7);
    expect(await stale.exists(), isFalse); // swept, not left to linger
  });

  test(
    'a mismatched leftover file is downloaded fresh, not installed',
    () async {
      await notice('1.1.0');
      final asked = <String>[];
      update.clientFactory = () => MockClient((request) async {
        asked.add(request.url.toString());
        return isReleaseQuery(request)
            ? http.Response(releases([entry('1.1.0', size: 2048)]), 200)
            : http.Response.bytes(List.filled(2048, 7), 200);
      });

      expect(await update.downloadAndInstall(), isNull);
      await File(installed.single).writeAsBytes(List.filled(100, 1));
      installed.clear();
      asked.clear();
      await installerEvent('installDeclined');
      expect(await update.downloadAndInstall(), isNull);

      expect(asked, contains('https://example.invalid/1.1.0.apk'));
      expect(await File(installed.single).length(), 2048);
    },
  );

  test(
    'refresh switches a cached universal APK to the matching split',
    () async {
      await update.init();
      update.supportedAbis = ['armeabi-v7a', 'armeabi'];
      var splitReady = false;
      final downloads = <String>[];
      update.clientFactory = () => MockClient((request) async {
        if (isReleaseQuery(request)) {
          final latest = entry('1.1.0', size: 64);
          if (splitReady) {
            (latest['assets'] as List).insert(0, {
              'name': 'kiosk-satellite-v1.1.0.armeabi-v7a.apk',
              'browser_download_url': 'https://example.invalid/arm.apk',
              'size': 64,
            });
          }
          return http.Response(releases([latest]), 200);
        }
        downloads.add(request.url.toString());
        return http.Response.bytes(List.filled(64, splitReady ? 2 : 1), 200);
      });
      expect(await update.check(), true);
      expect(await update.downloadAndInstall(), isNull);
      final universalFile = File(installed.single);
      await installerEvent('installDeclined');
      splitReady = true;
      expect(await update.downloadAndInstall(), isNull);
      expect(update.available.value!.apkUrl, 'https://example.invalid/arm.apk');
      expect(update.available.value!.apkSize, 64);
      expect(downloads, [
        'https://example.invalid/1.1.0.apk',
        'https://example.invalid/arm.apk',
      ]);
      expect(installed.last, isNot(installed.first));
      expect(await universalFile.exists(), false);
      expect((await File(installed.last).readAsBytes()).first, 2);
    },
  );

  test('an install that needs confirming stands the kiosk down first and '
      're-arms it when declined', () async {
    needsConfirm = true;
    await notice('1.1.0');
    update.clientFactory = () => MockClient(
      (request) async => isReleaseQuery(request)
          ? http.Response(release('1.1.0'), 200)
          : http.Response.bytes(List.filled(64, 7), 200),
    );

    expect(await update.downloadAndInstall(), isNull);

    // Stood down before the session was committed, and only once.
    expect(kioskCalls, ['pause']);
    expect(installed, hasLength(1));

    await installerEvent('installDeclined');
    expect(kioskCalls, ['pause', 'resume']);

    // The callback can only owe one re-arm; a stray repeat changes nothing.
    await installerEvent('installFailed');
    expect(kioskCalls, ['pause', 'resume']);
  });

  for (final mode in ['helper', 'shizuku']) {
    test('$mode receives the matching architecture APK', () async {
      shizukuEnabled = mode == 'shizuku';
      await update.init();
      update.supportedAbis = ['arm64-v8a', 'armeabi-v7a'];
      final downloads = <String>[];
      update.clientFactory = () => MockClient((request) async {
        if (isReleaseQuery(request)) {
          final latest = entry('1.1.0', size: 64);
          (latest['assets'] as List).add({
            'name': 'kiosk-satellite-v1.1.0.arm64-v8a.apk',
            'browser_download_url': 'https://example.invalid/arm64.apk',
            'size': 64,
          });
          return http.Response(releases([latest]), 200);
        }
        downloads.add(request.url.toString());
        return http.Response.bytes(List.filled(64, 2), 200);
      });
      expect(await update.check(), true);
      expect(await update.downloadAndInstall(), isNull);
      expect(downloads, ['https://example.invalid/arm64.apk']);
      expect(installArguments.single['useShizuku'] == true, shizukuEnabled);
      expect(kioskCalls, isEmpty);
      expect(await File(installed.single).readAsBytes(), List.filled(64, 2));
    });
  }

  test(
    'enabled Shizuku blocks unavailable service before downloading or pausing the kiosk',
    () async {
      shizukuEnabled = true;
      shizukuReady = false;
      await notice('1.1.0');
      var requests = 0;
      update.clientFactory = () => MockClient((request) async {
        requests++;
        return http.Response('', 500);
      });
      expect(
        await update.downloadAndInstall(),
        contains('Shizuku is unavailable'),
      );
      expect(requests, 0);
      expect(installArguments, isEmpty);
      expect(kioskCalls, isEmpty);
    },
  );

  test('Shizuku failure never opens the confirmation installer', () async {
    shizukuEnabled = true;
    helperCommitFailure = true;
    await notice('1.1.0');
    update.clientFactory = () => MockClient(
      (request) async => isReleaseQuery(request)
          ? http.Response(release('1.1.0'), 200)
          : http.Response.bytes(List.filled(64, 7), 200),
    );
    expect(
      await update.downloadAndInstall(),
      contains('Lost contact after committing'),
    );
    expect(installArguments, hasLength(1));
    expect(installArguments.single['useShizuku'], true);
    expect(kioskCalls, isEmpty);
  });

  test(
    'helper loss after preflight releases kiosk before system fallback',
    () async {
      helperFallback = true;
      await notice('1.1.0');
      update.clientFactory = () => MockClient(
        (request) async => isReleaseQuery(request)
            ? http.Response(release('1.1.0'), 200)
            : http.Response.bytes(List.filled(64, 7), 200),
      );
      expect(await update.downloadAndInstall(), isNull);
      expect(kioskCalls, ['pause']);
      expect(installed, hasLength(1));
      await installerEvent('installDeclined');
      expect(kioskCalls, ['pause', 'resume']);
    },
  );

  test(
    'uncertain helper commit does not retry through the system installer',
    () async {
      helperCommitFailure = true;
      await notice('1.1.0');
      update.clientFactory = () => MockClient(
        (request) async => isReleaseQuery(request)
            ? http.Response(release('1.1.0'), 200)
            : http.Response.bytes(List.filled(64, 7), 200),
      );
      expect(
        await update.downloadAndInstall(),
        contains('Lost contact after committing'),
      );
      expect(installed, isEmpty);
      expect(kioskCalls, isEmpty);
      final status = await registry.execute('getUpdateStatus', const {});
      expect((status.data as Map)['lastOutcome'], 'failed');
    },
  );

  test('an early native failure survives the install method reply', () async {
    await notice('1.1.0');
    update.clientFactory = () => MockClient(
      (request) async => isReleaseQuery(request)
          ? http.Response(release('1.1.0'), 200)
          : http.Response.bytes(List.filled(64, 7), 200),
    );
    messenger.setMockMethodCallHandler(installer, (call) async {
      if (call.method == 'needsConfirmation') return true;
      if (call.method == 'installApk') {
        await installerEvent('installFailed');
        return 'confirm';
      }
      return null;
    });

    await update.downloadAndInstall();

    final status = await registry.execute('getUpdateStatus', const {});
    expect((status.data as Map)['lastOutcome'], 'failed');
    expect(kioskCalls, ['pause', 'resume']);
  });

  /// A client whose APK response streams from [apkBytes], so a test can
  /// hold the transfer open, stall it, or feed it chunk by chunk.
  http.Client Function() streamingClient(
    StreamController<List<int>> apkBytes, {
    int contentLength = 4096,
  }) =>
      () => MockClient.streaming((request, _) async {
        if (isReleaseQuery(request)) {
          return http.StreamedResponse(
            Stream.value(utf8.encode(release('1.1.0'))),
            200,
          );
        }
        return http.StreamedResponse(
          apkBytes.stream,
          200,
          contentLength: contentLength,
        );
      });

  test(
    'cancelUpdateDownload aborts a running download and keeps the notice',
    () async {
      await notice('1.1.0');
      final apkBytes = StreamController<List<int>>();
      update.clientFactory = streamingClient(apkBytes);

      final result = update.downloadAndInstall();
      apkBytes.add(List.filled(1024, 7)); // 25%: mid-download, held open
      while ((update.progress.value ?? 0) == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      final cancel = await registry.execute('cancelUpdateDownload', const {});
      expect(cancel.ok, isTrue);
      expect(await result, isNull);

      expect(installed, isEmpty);
      // The notice stays up, so the download can simply be started again.
      expect(update.available.value?.version, '1.1.0');
      expect(update.progress.value, isNull);
      final status = await registry.execute('getUpdateStatus', const {});
      expect((status.data as Map)['lastOutcome'], 'cancelled');
      // A second cancel with nothing running is refused, not a crash.
      expect(
        (await registry.execute('cancelUpdateDownload', const {})).ok,
        isFalse,
      );
      await apkBytes.close();
    },
  );

  test('a stalled download fails instead of running forever', () async {
    await notice('1.1.0');
    update.stallTimeout = const Duration(milliseconds: 100);
    final apkBytes = StreamController<List<int>>(); // never delivers a byte
    update.clientFactory = streamingClient(apkBytes);

    final error = await update.downloadAndInstall();

    expect(error, contains('stalled'));
    expect(installed, isEmpty);
    expect(update.available.value?.version, '1.1.0');
    expect(update.progress.value, isNull);
    final status = await registry.execute('getUpdateStatus', const {});
    expect((status.data as Map)['lastOutcome'], 'failed');
    await apkBytes.close();
  });

  test('progress moves in whole percents, not per network chunk', () async {
    await notice('1.1.0');
    final apkBytes = StreamController<List<int>>();
    update.clientFactory = streamingClient(apkBytes, contentLength: 100000);

    var progressSets = 0;
    update.progress.addListener(() => progressSets++);
    var busEvents = 0;
    final sub = update.bus.on<UpdateStateChanged>().listen((_) => busEvents++);

    final result = update.downloadAndInstall();
    // 50 chunks all inside the first whole percent, then one that crosses
    // to 5%. Unquantized, every chunk notified every listener (#272).
    for (var i = 0; i < 50; i++) {
      apkBytes.add(List.filled(10, 7));
    }
    apkBytes.add(List.filled(4500, 7));
    await pumpEventQueue();
    await apkBytes.close();
    expect(await result, isNull);
    await pumpEventQueue();

    // null -> 0 at the start, 0 -> 0.05 at the percent crossing, -> null
    // at the end: three, not fifty-one.
    expect(progressSets, 3);
    // Start, the fresh-release adoption, the first percent, the end. The
    // in-between percents are capped to one a second on top of the whole-
    // percent gate, so a chunk storm never becomes a bus storm.
    expect(busEvents, 4);
    await sub.cancel();
  });

  test('a refused silent install retries once through the confirm screen '
      '(#768)', () async {
    await notice('1.1.0');
    update.clientFactory = () => MockClient(
      (request) async => isReleaseQuery(request)
          ? http.Response(release('1.1.0'), 200)
          : http.Response.bytes(List.filled(64, 7), 200),
    );

    expect(await update.downloadAndInstall(), isNull);
    expect(kioskCalls, isEmpty);

    await installerEvent('silentInstallRefused', 'INSTALL_FAILED_ABORTED');

    // The same APK, now asking for the confirm screen with the kiosk down.
    expect(installArguments, hasLength(2));
    expect(installArguments.last['useSystemInstaller'], true);
    expect(installed, [installed.first, installed.first]);
    expect(kioskCalls, ['pause']);
    var status = await registry.execute('getUpdateStatus', const {});
    expect((status.data as Map)['lastOutcome'], 'confirm');

    // Declining that screen is a real decline and re-arms the kiosk.
    await installerEvent('installDeclined', 'INSTALL_FAILED_ABORTED');
    expect(kioskCalls, ['pause', 'resume']);
    status = await registry.execute('getUpdateStatus', const {});
    expect((status.data as Map)['lastOutcome'], 'cancelled');
  });

  test('a silent install never touches the kiosk', () async {
    await notice('1.1.0');
    update.clientFactory = () => MockClient(
      (request) async => isReleaseQuery(request)
          ? http.Response(release('1.1.0'), 200)
          : http.Response.bytes(List.filled(64, 7), 200),
    );

    expect(await update.downloadAndInstall(), isNull);

    expect(kioskCalls, isEmpty);
    expect(installed, hasLength(1));
  });

  group('uploaded APK (#566)', () {
    Stream<List<int>> bytes(List<int> data, {int chunk = 7}) async* {
      for (var i = 0; i < data.length; i += chunk) {
        yield data.sublist(
          i,
          i + chunk > data.length ? data.length : i + chunk,
        );
      }
    }

    Future<Map<String, Object?>> status() async =>
        ((await registry.execute('getUpdateStatus', const {})).data as Map)
            .cast<String, Object?>();

    test(
      'an upload is inspected, kept under its version and installed',
      () async {
        await update.init();
        final apk = List<int>.generate(50, (i) => i);
        final got = await update.receiveUpload(bytes(apk), length: apk.length);
        expect(got['version'], '1.2.0');
        expect(got['buildNumber'], 5);
        expect(got['size'], 50);
        expect(got['currentBuild'], 1);
        final file = File('${got['path']}');
        expect(
          file.path,
          endsWith('/updates/kiosk-satellite-update-1.2.0-upload.apk'),
        );
        expect(await file.readAsBytes(), apk);
        expect((await status())['uploaded'], containsPair('version', '1.2.0'));

        final r = await registry.execute('installUploadedApk', const {});
        expect(r.ok, isTrue);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(installed, [file.path]);
        final st = await status();
        expect(st['installing'], isFalse);
        expect(st['lastOutcome'], 'silent');
        // The file stays for a retry after a declined confirmation.
        expect(await file.exists(), isTrue);
      },
    );

    test('the command refuses what is not on the wire', () async {
      await update.init();
      final r = await registry.execute('receiveUploadedUpdate', {'length': 3});
      expect(r.ok, isFalse);
      expect(r.error, contains('raw body'));
      final none = await registry.execute('installUploadedApk', const {});
      expect(none.ok, isFalse);
      expect(none.error, contains('no uploaded APK'));
    });

    test('another package, a downgrade, a short upload and a non-APK are '
        'refused and leave nothing behind', () async {
      await update.init();
      final apk = List<int>.generate(20, (i) => i);
      Future<String> refused({int? length}) async {
        try {
          await update.receiveUpload(bytes(apk), length: length ?? apk.length);
        } on StateError catch (e) {
          return e.message;
        }
        fail('accepted');
      }

      inspected = {
        'packageName': 'com.example.other',
        'versionName': '9.0',
        'versionCode': 99,
      };
      expect(await refused(), contains('com.example.other'));
      PackageInfo.setMockInitialValues(
        appName: 'Kiosk Satellite',
        packageName: 'me.jxl.kiosk_satellite',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
      inspected = {
        'packageName': 'me.jxl.kiosk_satellite',
        'versionName': '0.9.0',
        'versionCode': 0,
      };
      expect(await refused(), contains('Downgrades are refused'));
      inspected = null;
      expect(await refused(), contains('not an Android APK'));
      inspected = {
        'packageName': 'me.jxl.kiosk_satellite',
        'versionName': '1.2.0',
        'versionCode': 5,
      };
      expect(await refused(length: apk.length + 5), contains('ended early'));
      final dir = Directory('${cache.path}/updates');
      expect(await dir.list().toList(), isEmpty);
      expect((await status())['uploaded'], isNull);
      expect(installed, isEmpty);
    });

    test(
      'the space check refuses an APK the cache cannot hold twice',
      () async {
        await update.init();
        freeSpace = 100;
        final apk = List<int>.generate(60, (i) => i);
        var read = false;
        try {
          await update.receiveUpload(
            bytes(apk).map((c) {
              read = true;
              return c;
            }),
            length: apk.length,
          );
          fail('accepted');
        } on StateError catch (e) {
          expect(e.message, contains('Not enough free space'));
        }
        expect(read, isFalse);
        expect(
          await Directory('${cache.path}/updates').list().toList(),
          isEmpty,
        );
      },
    );

    test('an upload cut off mid-transfer is refused and cleaned up', () async {
      await update.init();
      Stream<List<int>> dropped() async* {
        yield List<int>.filled(4000, 1);
        yield List<int>.filled(4000, 2);
        throw const SocketException('connection reset');
      }

      try {
        await update.receiveUpload(dropped(), length: 20000);
        fail('accepted');
      } on StateError catch (e) {
        expect(e.message, contains('interrupted'));
      }
      expect(await Directory('${cache.path}/updates').list().toList(), isEmpty);
      expect((await status())['uploaded'], isNull);
      // The folder is usable again right away.
      final apk = List<int>.generate(10, (i) => i);
      final got = await update.receiveUpload(bytes(apk), length: apk.length);
      expect(got['size'], 10);
    });

    test('a same-build upload is accepted and says so', () async {
      await update.init();
      inspected = {
        'packageName': 'me.jxl.kiosk_satellite',
        'versionName': '1.0.0',
        'versionCode': 1,
      };
      final apk = List<int>.generate(10, (i) => i);
      final got = await update.receiveUpload(bytes(apk), length: apk.length);
      expect(got['buildNumber'], got['currentBuild']);
    });

    test('a download sweeps the waiting upload', () async {
      await notice('1.1.0');
      final apk = List<int>.generate(10, (i) => i);
      await update.receiveUpload(bytes(apk), length: apk.length);
      update.clientFactory = () => MockClient(
        (request) async => isReleaseQuery(request)
            ? http.Response(release('1.1.0'), 200)
            : http.Response.bytes(apk, 200),
      );
      expect(await update.downloadAndInstall(), isNull);
      expect((await status())['uploaded'], isNull);
    });

    test('a failed install of the upload records the outcome and re-arms '
        'the kiosk', () async {
      await update.init();
      needsConfirm = true;
      helperCommitFailure = true;
      final apk = List<int>.generate(10, (i) => i);
      await update.receiveUpload(bytes(apk), length: apk.length);
      final r = await registry.execute('installUploadedApk', const {});
      expect(r.ok, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final st = await status();
      expect(st['installing'], isFalse);
      expect(st['lastOutcome'], 'failed');
      expect('${st['lastError']}', contains('Lost contact'));
      expect(kioskCalls, ['pause', 'resume']);
    });
  });
}
