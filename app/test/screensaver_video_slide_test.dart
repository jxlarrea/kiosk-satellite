import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Issue #1298: Immich videos follow Fill the screen like the photos do,
/// and Video length on Same as photos cuts a video off once the seconds per
/// image run out. The fake video never ends on its own, so whatever moves
/// the slideshow on is the hold.
class _Video extends VideoPlayerPlatform {
  final events = <int, StreamController<VideoEvent>>{};
  final playing = <int>{};
  final mixWithOthers = <bool>[];
  var creates = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = ++creates;
    events[id] = StreamController<VideoEvent>();
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final controller = events[playerId]!;
    scheduleMicrotask(
      () => controller.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 30),
          size: const Size(1920, 1080),
        ),
      ),
    );
    return controller.stream;
  }

  /// A decoder failure the way the plugin reports one.
  void fail(int playerId) => events[playerId]!.addError(
    PlatformException(
      code: 'VideoError',
      message:
          'Video player had error androidx.media3.exoplayer.'
          'ExoPlaybackException: MediaCodecVideoRenderer error',
    ),
  );

  @override
  Future<void> dispose(int playerId) async {
    playing.remove(playerId);
    await events.remove(playerId)?.close();
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> play(int playerId) async => playing.add(playerId);
  @override
  Future<void> pause(int playerId) async => playing.remove(playerId);
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Future<void> setMixWithOthers(bool mix) async => mixWithOthers.add(mix);
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => HttpOverrides.global = null);

  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
    '60e6kgAAAABJRU5ErkJggg==',
  );

  late HttpServer server;
  late AppContainer container;
  late _Video video;
  late VideoPlayerPlatform original;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      final path = request.uri.path;
      final response = request.response;
      if (path == '/api/albums') {
        response.headers.contentType = ContentType.json;
        response.write('[]');
      } else if (path == '/api/search/metadata') {
        response.headers.contentType = ContentType.json;
        response.write(
          jsonEncode({
            'assets': {
              'items': [
                {'id': 'video-1', 'type': 'VIDEO'},
                {'id': 'photo-2', 'type': 'IMAGE'},
              ],
              'nextPage': null,
            },
          }),
        );
      } else if (path.endsWith('/thumbnail')) {
        response.headers.contentType = ContentType('image', 'png');
        response.add(png);
      } else {
        response.statusCode = 404;
      }
      response.close();
    });

    SharedPreferences.setMockInitialValues({
      'ks.screensaver.immich_url': 'http://127.0.0.1:${server.port}',
      'ks.screensaver.immich_api_key': 'test-key',
      'ks.screensaver.immich_validated': true,
      'ks.screensaver.immich_shuffle': false,
      'ks.screensaver.immich_cache': false,
      'ks.screensaver.immich_interval_seconds': 2,
    });
    container = AppContainer();
    await container.settings.init();
    await container.immich.init();
    // No heap to judge against: every video plays.
    container.immich.javaHeapMaxOverride = 0;
    original = VideoPlayerPlatform.instance;
    video = _Video();
    VideoPlayerPlatform.instance = video;
  });

  tearDown(() async {
    VideoPlayerPlatform.instance = original;
    await server.close(force: true);
  });

  Future<void> pumpUntil(WidgetTester tester, bool Function() done) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!done() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
    await tester.pump();
  }

  Future<void> start(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ImmichScreensaver(container: container)),
    );
    await pumpUntil(tester, () => video.playing.contains(1));
    expect(find.byType(VideoPlayer), findsOneWidget);
  }

  testWidgets('a video plays past the interval by default', (tester) async {
    await tester.runAsync(() async {
      await start(tester);
      await Future<void>.delayed(const Duration(milliseconds: 2600));
      await tester.pump();
      expect(find.byType(VideoPlayer), findsOneWidget);
      expect(video.creates, 1);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Same as photos stops a video once the interval runs out', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await container.settings.set(
        defs.screensaverImmichVideoLength,
        'interval',
      );
      await start(tester);
      await pumpUntil(tester, () => find.byType(Image).evaluate().isNotEmpty);
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Smart fill crops a video shaped close to the screen', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // The test surface is 800 by 600: a 16:9 video is close enough to 4:3.
      await start(tester);
      final fitted = tester.widget<FittedBox>(
        find.ancestor(
          of: find.byType(VideoPlayer),
          matching: find.byType(FittedBox),
        ),
      );
      expect(fitted.fit, BoxFit.cover);
      expect(fitted.clipBehavior, Clip.hardEdge);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('a video keeps its frame with Fill the screen off', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await container.settings.set(defs.screensaverImmichFill, 'off');
      await start(tester);
      expect(
        find.ancestor(
          of: find.byType(VideoPlayer),
          matching: find.byType(FittedBox),
        ),
        findsNothing,
      );
      final box = tester.widget<AspectRatio>(
        find.ancestor(
          of: find.byType(VideoPlayer),
          matching: find.byType(AspectRatio),
        ),
      );
      expect(box.aspectRatio, closeTo(16 / 9, 0.001));
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Same as photos stops a Local Media video too', (tester) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('ks_video_length');
      // Sorted by name: the video first, then the photo.
      File('${dir.path}/a.mp4').writeAsBytesSync([0]);
      File('${dir.path}/b.png').writeAsBytesSync(png);
      await container.settings.set(defs.screensaverLocalFolder, dir.path);
      await container.settings.set(defs.screensaverLocalInterval, 2);
      await container.settings.set(
        defs.screensaverLocalVideoLength,
        'interval',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: LocalMediaScreensaver(container: container, mode: 'local'),
        ),
      );
      await pumpUntil(tester, () => video.playing.contains(1));
      expect(find.byType(VideoPlayer), findsOneWidget);
      await pumpUntil(tester, () => find.byType(Image).evaluate().isNotEmpty);
      expect(find.byType(Image), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      await dir.delete(recursive: true);
    });
  });
}
