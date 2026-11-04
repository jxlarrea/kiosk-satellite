import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/resized_image.dart';

const _channel = MethodChannel('kiosk_satellite/image');

/// A solid PNG of [width] x [height], encoded by the engine.
Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF3366CC),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<(int, int)> _decodedSize(ImageProvider provider) async {
  final stream = provider.resolve(ImageConfiguration.empty);
  final info = await _first(stream);
  final size = (info.image.width, info.image.height);
  info.dispose();
  return size;
}

Future<ImageInfo> _first(ImageStream stream) {
  final done = Completer<ImageInfo>();
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      stream.removeListener(listener);
      done.complete(info);
    },
    onError: (Object error, StackTrace? stack) {
      stream.removeListener(listener);
      done.completeError(error, stack);
    },
  );
  stream.addListener(listener);
  return done.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    GpuResize.risky = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    PaintingBinding.instance.imageCache.clear();
  });

  group('resolvedTargetSize follows ResizeImage', () {
    test('a width alone keeps the aspect ratio', () {
      expect(
        resolvedTargetSize(
          1000,
          500,
          300,
          null,
          ResizeImagePolicy.exact,
          false,
        ),
        (300, 150),
      );
    });

    test('a height alone rounds the width', () {
      expect(
        resolvedTargetSize(
          1000,
          333,
          null,
          100,
          ResizeImagePolicy.exact,
          false,
        ),
        (300, 100),
      );
    });

    test('exact never upscales unless allowed', () {
      expect(
        resolvedTargetSize(100, 50, 300, null, ResizeImagePolicy.exact, false),
        (100, 50),
      );
      expect(
        resolvedTargetSize(100, 50, 300, null, ResizeImagePolicy.exact, true),
        (300, 150),
      );
    });

    test('exact with both sides takes both', () {
      expect(
        resolvedTargetSize(1000, 500, 64, 64, ResizeImagePolicy.exact, false),
        (64, 64),
      );
    });

    test('fit keeps landscape and portrait inside the box', () {
      expect(
        resolvedTargetSize(1000, 500, 256, 256, ResizeImagePolicy.fit, false),
        (256, 128),
      );
      expect(
        resolvedTargetSize(500, 1000, 256, 256, ResizeImagePolicy.fit, false),
        (128, 256),
      );
      expect(
        resolvedTargetSize(200, 100, 256, 256, ResizeImagePolicy.fit, false),
        (200, 100),
      );
    });
  });

  group('jpegEighthSize', () {
    test('picks the smallest eighth that covers the target', () {
      // An Immich preview shown at 960: 6/8.
      expect(jpegEighthSize(1440, 1913, 960, 1275), (1080, 1435));
      // A 512 cover at 366: 6/8.
      expect(jpegEighthSize(512, 512, 366, 366), (384, 384));
      // A 50 MP photo at 960: 1/8, sides rounded up like libjpeg-turbo.
      expect(jpegEighthSize(8160, 6144, 960, 722), (1020, 768));
      expect(jpegEighthSize(4001, 3001, 500, 375), (501, 376));
    });

    test('an exact eighth is taken as is', () {
      expect(jpegEighthSize(800, 600, 400, 300), (400, 300));
    });

    test('a target past 7/8 decodes whole', () {
      expect(jpegEighthSize(800, 500, 790, 493), (800, 500));
    });

    test('far more pixels than the target goes to Android', () {
      // Just above 1/8: the next eighth has almost four times the pixels.
      expect(jpegEighthSize(4000, 3000, 520, 390), isNull);
    });

    test('tiny images go to Android', () {
      expect(jpegEighthSize(12, 12, 6, 6), isNull);
    });
  });

  test('without the risk the provider is a plain ResizeImage', () {
    GpuResize.risky = false;
    final bytes = Uint8List(8);
    expect(resizedMemoryImage(bytes, width: 10), isA<ResizeImage>());
    expect(resizedMemoryImage(bytes), isA<MemoryImage>());
  });

  testWidgets('with the risk the decode takes Android pixels at the size', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final bytes = await _png(400, 200);
      final calls = <Map<Object?, Object?>>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
            final args = call.arguments as Map<Object?, Object?>;
            calls.add(args);
            final width = args['width']! as int;
            final height = args['height']! as int;
            return {
              'width': width,
              'height': height,
              'pixels': Uint8List(width * height * 4),
            };
          });
      GpuResize.risky = true;
      final provider = resizedMemoryImage(bytes, width: 100);
      expect(provider, isNot(isA<ResizeImage>()));
      expect(await _decodedSize(provider), (100, 50));
      expect(calls, hasLength(1));
      expect(calls.single['width'], 100);
      expect(calls.single['height'], 50);
      expect(calls.single['sourceWidth'], 400);
      expect(calls.single['sourceHeight'], 200);
    });
  });

  testWidgets('with the risk a stored size that already fits skips Android', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final bytes = await _png(80, 40);
      var called = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
            called = true;
            return null;
          });
      GpuResize.risky = true;
      expect(await _decodedSize(resizedMemoryImage(bytes, width: 300)), (
        80,
        40,
      ));
      expect(called, isFalse);
    });
  });

  testWidgets('with the risk a declined downscale falls back to Flutter', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final bytes = await _png(400, 200);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async => null);
      GpuResize.risky = true;
      expect(await _decodedSize(resizedMemoryImage(bytes, width: 100)), (
        100,
        50,
      ));
      final codec = await instantiateResizedCodec(bytes, targetWidth: 40);
      final frame = await codec.getNextFrame();
      expect((frame.image.width, frame.image.height), (40, 20));
      frame.image.dispose();
      codec.dispose();
    });
  });

  testWidgets('cpu helpers stay out of the way without the risk', (
    tester,
  ) async {
    await tester.runAsync(() async {
      GpuResize.risky = false;
      final bytes = await _png(40, 40);
      expect(await cpuPngThumbnail(bytes, 16), isNull);
      expect(await cpuRgba(bytes, 8, 8), isNull);
    });
  });
}
