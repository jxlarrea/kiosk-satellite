import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/screensaver/immich_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Crop around faces (issue #1552): the Immich slideshow asks the server for
/// the faces in a photo it is about to crop and moves the crop to them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The test binding stubs every HttpClient to answer 400; these tests talk
  // to a real loopback server instead.
  setUpAll(() => HttpOverrides.global = null);

  // A 30x40 PNG: a portrait photo, which an 800x500 panel crops top and
  // bottom with Fill the screen set to Always.
  final portraitPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAB4AAAAoCAIAAABmcd1FAAAALklEQVR4nO3MQQEAQAQAsHMttJJYNil4bQEWXfl2/KVXrVar1Wq1Wq1Wq9WH9QCo5QF3BVxaYAAAAABJRU5ErkJggg==',
  );

  /// One face high in the photo, as Immich reports it on a 300x400 preview.
  Map<String, Object?> face({double top = 40}) => {
    'id': 'face-1',
    'imageWidth': 300,
    'imageHeight': 400,
    'boundingBoxX1': 120,
    'boundingBoxY1': top,
    'boundingBoxX2': 180,
    'boundingBoxY2': top + 50,
    'person': null,
  };

  late HttpServer server;
  late AppContainer c;
  var faceRequests = 0;
  var faceStatus = 200;
  Object faceAnswer = const [];
  Duration faceDelay = Duration.zero;

  setUp(() async {
    faceRequests = 0;
    faceStatus = 200;
    faceAnswer = [face()];
    faceDelay = Duration.zero;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
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
                {'id': 'asset-1', 'type': 'IMAGE'},
                {'id': 'asset-2', 'type': 'IMAGE'},
              ],
              'nextPage': null,
            },
          }),
        );
      } else if (path.endsWith('/thumbnail')) {
        response.headers.contentType = ContentType('image', 'png');
        response.add(portraitPng);
      } else if (path == '/api/faces') {
        faceRequests++;
        await Future<void>.delayed(faceDelay);
        response.statusCode = faceStatus;
        response.headers.contentType = ContentType.json;
        response.write(
          jsonEncode(
            faceStatus == 200
                ? faceAnswer
                : {'message': 'Missing required permission: face.read'},
          ),
        );
      } else {
        response.statusCode = 404;
      }
      await response.close();
    });
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.immich_url': 'http://127.0.0.1:${server.port}',
      'ks.screensaver.immich_api_key': 'test-key',
      'ks.screensaver.immich_validated': true,
      'ks.screensaver.immich_shuffle': false,
      'ks.screensaver.immich_cache': false,
      'ks.screensaver.immich_pair_portrait': false,
      'ks.screensaver.immich_fill': 'always',
      'ks.screensaver.immich_transition': 'none',
    });
    c = AppContainer();
    await c.settings.init();
    await c.immich.init();
  });

  tearDown(() async {
    await c.immich.dispose();
    await server.close(force: true);
  });

  group('immichFaceBoxes', () {
    test('turns pixel boxes into fractions of the measured picture', () {
      final boxes = immichFaceBoxes([face()]);
      expect(boxes, hasLength(1));
      expect(boxes.single.left, closeTo(0.4, 1e-9));
      expect(boxes.single.top, closeTo(0.1, 1e-9));
      expect(boxes.single.right, closeTo(0.6, 1e-9));
      expect(boxes.single.bottom, closeTo(0.225, 1e-9));
    });

    test('drops entries it cannot place and clips the rest', () {
      expect(immichFaceBoxes(null), isEmpty);
      expect(immichFaceBoxes({'faces': []}), isEmpty);
      final boxes = immichFaceBoxes([
        {...face(), 'imageWidth': 0},
        {...face(), 'boundingBoxX1': null},
        'not a face',
        {...face(), 'boundingBoxX2': 400},
      ]);
      expect(boxes, hasLength(1));
      expect(boxes.single.right, 1);
    });
  });

  group('ImmichManager.faces', () {
    const asset = ImmichAsset(id: 'asset-1', isVideo: false);

    test('shares one request and keeps the answer', () async {
      faceDelay = const Duration(milliseconds: 30);
      final answers = await Future.wait(
        List.generate(3, (_) => c.immich.faces(asset)),
      );
      expect(faceRequests, 1);
      expect(answers.every((a) => a.length == 1), isTrue);
      await c.immich.faces(asset);
      expect(faceRequests, 1);
    });

    test('a refused face.read is remembered for the whole key', () async {
      var now = DateTime(2026, 11, 21, 12);
      c.immich.clock = () => now;
      faceStatus = 403;
      expect(await c.immich.faces(asset), isEmpty);
      expect(
        await c.immich.faces(const ImmichAsset(id: 'asset-2', isVideo: false)),
        isEmpty,
      );
      expect(faceRequests, 1);
      // Granted later: picked up once the wait is over.
      faceStatus = 200;
      now = now.add(ImmichManager.faceRetry);
      expect(await c.immich.faces(asset), hasLength(1));
      expect(faceRequests, 2);
    });

    test('a photo without faces is asked again only after the wait', () async {
      var now = DateTime(2026, 11, 21, 12);
      c.immich.clock = () => now;
      faceAnswer = const [];
      expect(await c.immich.faces(asset), isEmpty);
      expect(await c.immich.faces(asset), isEmpty);
      expect(faceRequests, 1);
      faceAnswer = [face()];
      now = now.add(ImmichManager.faceRetry);
      expect(await c.immich.faces(asset), hasLength(1));
      expect(faceRequests, 2);
    });

    test('a server error is not remembered', () async {
      faceStatus = 503;
      expect(await c.immich.faces(asset), isEmpty);
      faceStatus = 200;
      expect(await c.immich.faces(asset), hasLength(1));
      expect(faceRequests, 2);
    });

    test('a new API key starts over', () async {
      faceStatus = 403;
      expect(await c.immich.faces(asset), isEmpty);
      await c.settings.set(defs.screensaverImmichApiKey, 'new-key');
      faceStatus = 200;
      expect(await c.immich.faces(asset), hasLength(1));
      expect(faceRequests, 2);
    });
  });

  group('the slideshow', () {
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

    Future<Image> shownPhoto(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: ImmichScreensaver(container: c)),
      );
      await pumpUntil(tester, () => find.byType(Image).evaluate().isNotEmpty);
      return tester.widget<Image>(find.byType(Image).first);
    }

    testWidgets('crops a portrait photo around the face', (tester) async {
      await tester.runAsync(() async {
        final photo = await shownPhoto(tester);
        expect(faceRequests, greaterThan(0));
        expect(photo.fit, BoxFit.cover);
        final alignment = photo.alignment as Alignment;
        expect(alignment.x, 0);
        expect(alignment.y, lessThan(-0.5));
        await tester.pumpWidget(const SizedBox());
      });
    });

    testWidgets('with the setting off asks nothing and stays centered', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await c.settings.set(defs.screensaverImmichCropFaces, false);
        final photo = await shownPhoto(tester);
        expect(faceRequests, 0);
        expect(photo.alignment, Alignment.center);
        await tester.pumpWidget(const SizedBox());
      });
    });

    testWidgets('a photo shown whole asks nothing', (tester) async {
      await tester.runAsync(() async {
        await c.settings.set(defs.screensaverImmichFill, 'off');
        final photo = await shownPhoto(tester);
        expect(faceRequests, 0);
        expect(photo.fit, BoxFit.contain);
        expect(photo.alignment, Alignment.center);
        await tester.pumpWidget(const SizedBox());
      });
    });

    testWidgets('Ken Burns zooms on the faces instead of a corner', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await c.settings.set(defs.screensaverImmichTransition, 'kenburns');
        final photo = await shownPhoto(tester);
        final crop = photo.alignment as Alignment;
        expect(crop.y, lessThan(-0.5));
        final zoom = tester
            .widgetList<Transform>(
              find.ancestor(
                of: find.byType(Image).first,
                matching: find.byType(Transform),
              ),
            )
            .map((t) => t.alignment)
            .whereType<Alignment>()
            .toList();
        // The face sits a little above the middle of the frame and in the
        // middle across, which no corner anchor is.
        expect(
          zoom,
          contains(
            isA<Alignment>()
                .having((a) => a.x, 'x', closeTo(0, 0.01))
                .having((a) => a.y, 'y', inInclusiveRange(-0.9, -0.1)),
          ),
        );
        await tester.pumpWidget(const SizedBox());
      });
    });

    testWidgets('a slow server shows the photo centered', (tester) async {
      await tester.runAsync(() async {
        faceDelay = const Duration(seconds: 4);
        final photo = await shownPhoto(tester);
        expect(photo.alignment, Alignment.center);
        await tester.pumpWidget(const SizedBox());
      });
    });
  });

  test('the setting shows only while Fill the screen crops', () {
    final def = defs.screensaverImmichCropFaces;
    expect(def.defaultValue, isTrue);
    expect(def.dependsOn, defs.screensaverImmichFill.key);
    expect(def.dependsSatisfiedBy('smart'), isTrue);
    expect(def.dependsSatisfiedBy('always'), isTrue);
    expect(def.dependsSatisfiedBy('off'), isFalse);
  });
}
