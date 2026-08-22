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

  /// One GitHub release object, as the releases list carries them.
  Map<String, Object?> entry(String tag,
          {bool prerelease = false, int? size}) =>
      {
        'tag_name': 'v$tag',
        'html_url': 'https://github.com/jxlarrea/kiosk-satellite/'
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
    kioskCalls = [];
    messenger.setMockMethodCallHandler(installer, (call) async {
      if (call.method == 'needsConfirmation') return needsConfirm;
      if (call.method != 'installApk') return null;
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
    registry.register(Command(
      name: 'pauseKioskForInstall',
      description: '',
      handler: (_) async {
        kioskCalls.add('pause');
        return const CommandResult.ok();
      },
    ));
    registry.register(Command(
      name: 'resumeKioskAfterInstall',
      description: '',
      handler: (_) async {
        kioskCalls.add('resume');
        return const CommandResult.ok();
      },
    ));
    update = UpdateManager(EventBus(), registry, log);
  });

  tearDown(() async {
    await update.dispose();
    messenger.setMockMethodCallHandler(pathProvider, null);
    messenger.setMockMethodCallHandler(installer, null);
    if (await cache.exists()) await cache.delete(recursive: true);
  });

  /// Runs the check that raises the notice, with GitHub offering [tag].
  Future<void> notice(String tag) async {
    update.clientFactory = () => MockClient(
        (request) async => http.Response(release(tag), 200));
    await update.init();
    expect(await update.check(), isTrue);
    expect(update.available.value?.version, tag);
  }

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
    update.clientFactory = () => MockClient((request) async =>
        http.Response(releases([entry('1.1.0'), entry('1.0.0')]), 200));
    await update.init();
    expect(await update.check(), isTrue);
    expect(update.available.value?.notes, 'Notes for 1.1.0');
  });

  test('skipped releases stack their notes newest first', () async {
    update.clientFactory = () => MockClient((request) async => http.Response(
        releases([entry('1.3.0'), entry('1.2.0'), entry('1.0.0')]), 200));
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
    update.clientFactory = () => MockClient((request) async =>
        http.Response(releases([entry('1.3.0'), entry('1.2.0')]), 200));
    await update.init();
    expect(await update.check(), isTrue);
    expect(update.available.value?.notes, contains('releases page'));
  });

  test('prereleases never count as the latest release', () async {
    update.clientFactory = () => MockClient((request) async => http.Response(
        releases([entry('1.2.0', prerelease: true), entry('1.1.0')]), 200));
    await update.init();
    expect(await update.check(), isTrue);
    expect(update.available.value?.version, '1.1.0');
    expect(update.available.value?.notes, isNot(contains('1.2.0')));
  });

  /// Delivers an installer callback the way the native side would.
  Future<void> installerEvent(String method) async {
    await messenger.handlePlatformMessage(
      'kiosk_satellite/installer',
      const StandardMethodCodec().encodeMethodCall(MethodCall(method)),
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
    expect(installed.single, endsWith('kiosk-satellite-update-1.1.0.apk'));
    expect((await File(installed.single).readAsBytes()).first, 7);
    expect(await stale.exists(), isFalse); // swept, not left to linger
  });

  test('a mismatched leftover file is downloaded fresh, not installed',
      () async {
    await notice('1.1.0');
    final dir = Directory('${cache.path}/updates');
    await dir.create(recursive: true);
    await File('${dir.path}/kiosk-satellite-update-1.1.0.apk')
        .writeAsBytes(List.filled(100, 1)); // truncated earlier attempt
    final asked = <String>[];
    update.clientFactory = () => MockClient((request) async {
          asked.add(request.url.toString());
          return isReleaseQuery(request)
              ? http.Response(releases([entry('1.1.0', size: 2048)]), 200)
              : http.Response.bytes(List.filled(2048, 7), 200);
        });

    expect(await update.downloadAndInstall(), isNull);

    expect(asked, contains('https://example.invalid/1.1.0.apk'));
    expect(await File(installed.single).length(), 2048);
  });

  test('an install that needs confirming stands the kiosk down first and '
      're-arms it when declined', () async {
    needsConfirm = true;
    await notice('1.1.0');
    update.clientFactory = () => MockClient((request) async =>
        isReleaseQuery(request)
            ? http.Response(release('1.1.0'), 200)
            : http.Response.bytes(List.filled(64, 7), 200));

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

  test('cancelUpdateDownload aborts a running download and keeps the notice',
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
    expect((await registry.execute('cancelUpdateDownload', const {})).ok,
        isFalse);
    await apkBytes.close();
  });

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
    final sub =
        update.bus.on<UpdateStateChanged>().listen((_) => busEvents++);

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

  test('a silent install never touches the kiosk', () async {
    await notice('1.1.0');
    update.clientFactory = () => MockClient((request) async =>
        isReleaseQuery(request)
            ? http.Response(release('1.1.0'), 200)
            : http.Response.bytes(List.filled(64, 7), 200));

    expect(await update.downloadAndInstall(), isNull);

    expect(kioskCalls, isEmpty);
    expect(installed, hasLength(1));
  });
}
