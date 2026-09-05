import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Immich screensaver heals on its own after the server goes away
/// (issue #337): a device that drops its network while the screen is off
/// used to wake to the failure message and sit on it until someone
/// restarted the screensaver. Both dead ends, a failed listing and a
/// playlist of failed fetches, now retry the listing on a backoff and the
/// slideshow resumes once the server answers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The test binding stubs every HttpClient to answer 400 without any
  // network; these tests talk to a real loopback server instead.
  setUpAll(() => HttpOverrides.global = null);

  // A 1x1 PNG, so a fetched slide decodes and the slideshow really starts.
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
    '60e6kgAAAABJRU5ErkJggg==',
  );

  late HttpServer server;
  late AppContainer container;

  /// What the fake server refuses right now: the album listing, the
  /// thumbnails, or nothing. A refusal answers 503, which reads as a
  /// server error; the mechanism under test is the same for a socket
  /// that never connects.
  var listingDown = false;
  var thumbnailsDown = false;
  var listings = 0;
  var portraitPair = false;
  var imageRequests = 0;

  setUp(() async {
    listingDown = false;
    thumbnailsDown = false;
    listings = 0;
    portraitPair = false;
    imageRequests = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      final path = request.uri.path;
      final response = request.response;
      if (path == '/api/albums') {
        response.headers.contentType = ContentType.json;
        response.write('[]');
      } else if (path == '/api/search/metadata') {
        listings++;
        if (listingDown) {
          response.statusCode = 503;
          response.headers.contentType = ContentType.json;
          response.write(jsonEncode({'message': 'down'}));
        } else {
          response.headers.contentType = ContentType.json;
          response.write(
            jsonEncode({
              'assets': {
                'items': [
                  {'id': 'asset-1', 'type': 'IMAGE'},
                  {'id': 'asset-2', 'type': 'IMAGE'},
                ],
                'nextPage': null,
              },
            }),
          );
        }
      } else if (path.startsWith('/api/assets/') &&
          path.endsWith('/thumbnail')) {
        if (thumbnailsDown) {
          response.statusCode = 503;
          response.headers.contentType = ContentType.json;
          response.write(jsonEncode({'message': 'down'}));
        } else {
          response.headers.contentType = ContentType('image', 'png');
          imageRequests++;
          response.add(
            portraitPair
                ? base64Decode(
                    'iVBORw0KGgoAAAANSUhEUgAAAB4AAAAoCAIAAABmcd1FAAAALklEQVR4nO3MQQEAQAQAsHMttJJYNil4bQEWXfl2/KVXrVar1Wq1Wq1Wq9WH9QCo5QF3BVxaYAAAAABJRU5ErkJggg==',
                  )
                : png,
          );
        }
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
      // The local cache calls path_provider, which has no test host.
      'ks.screensaver.immich_cache': false,
    });
    container = AppContainer();
    await container.settings.init();
    await container.immich.init();
  });

  tearDown(() => server.close(force: true));

  /// Mounts the screensaver with a short retry floor and polls until
  /// [done] holds or [timeout] passes, pumping a frame between polls.
  Future<void> pumpUntil(
    WidgetTester tester,
    bool Function() done, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!done() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
    await tester.pump();
  }

  Future<void> mount(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: ImmichScreensaver(
        container: container,
        retryFloor: const Duration(milliseconds: 100),
      ),
    ),
  );

  Finder retrying() => find.textContaining('Retrying automatically.');

  testWidgets('a failed listing is retried until the server answers', (
    tester,
  ) async {
    await tester.runAsync(() async {
      listingDown = true;
      await mount(tester);
      await pumpUntil(tester, () => retrying().evaluate().isNotEmpty);
      expect(retrying(), findsOneWidget);
      // Still down: the message stays and the listing keeps being asked.
      final before = listings;
      await pumpUntil(tester, () => listings > before);
      expect(retrying(), findsOneWidget);

      listingDown = false;
      await pumpUntil(tester, () => retrying().evaluate().isEmpty);
      expect(retrying(), findsNothing);
      // The slideshow is running: a slide made it to the screen.
      await pumpUntil(tester, () => find.byType(Image).evaluate().isNotEmpty);
      expect(find.byType(Image), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('a playlist of failed fetches is retried too', (tester) async {
    await tester.runAsync(() async {
      // The listing worked; the server went away before the photos.
      thumbnailsDown = true;
      await mount(tester);
      await pumpUntil(tester, () => retrying().evaluate().isNotEmpty);
      expect(retrying(), findsOneWidget);
      expect(listings, 1);

      thumbnailsDown = false;
      await pumpUntil(tester, () => find.byType(Image).evaluate().isNotEmpty);
      expect(retrying(), findsNothing);
      expect(find.byType(Image), findsWidgets);
      // Healed through a fresh listing, not by hammering the same photos.
      expect(listings, greaterThan(1));
      await tester.pumpWidget(const SizedBox());
    });
  });
  testWidgets(
    'a single portrait pair stays loaded across holds and screen-off',
    (tester) async {
      await tester.runAsync(() async {
        portraitPair = true;
        await container.settings.set(defs.screensaverImmichPairPortrait, true);
        await container.settings.set(defs.screensaverImmichInterval, 2);
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var changes = 0;
        final sub = container.bus.on<ScreensaverSlideChanged>().listen(
          (_) => changes++,
        );
        await mount(tester);
        await pumpUntil(tester, () => changes == 1);
        expect(find.byType(Image), findsNWidgets(2));
        expect(imageRequests, 2);
        await Future<void>.delayed(const Duration(seconds: 3));
        await tester.pump();
        expect(changes, 1);
        container.bus.publish(const ScreenStateChanged(on: false));
        await Future<void>.delayed(const Duration(seconds: 3));
        await tester.pump();
        expect(imageRequests, 2);
        container.bus.publish(
          const ScreenStateChanged(on: true, source: 'app'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        expect(changes, 1);
        expect(imageRequests, 2);
        await tester.pumpWidget(const SizedBox());
        await sub.cancel();
      });
    },
  );
}
