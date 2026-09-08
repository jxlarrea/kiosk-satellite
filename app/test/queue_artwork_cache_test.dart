import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/sendspin/queue_artwork_cache.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
  );
  late Directory directory;
  QueueArtworkCache cache({int? bytes, int entries = 4096}) =>
      QueueArtworkCache(
        directory: () async => directory,
        prepare: (bytes) async => bytes,
        maxBytes: bytes ?? 100 << 20,
        maxEntries: entries,
      );
  Future<Uint8List?> fetch() async => png;
  Future<Uint8List?> unexpectedFetch() async {
    fail('Cached artwork should not download again');
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('queue-artwork-test-');
  });
  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
    'thumbnails survive a new cache instance without storing URLs',
    () async {
      final url = 'https://art.local/image?token=private';
      await cache().load(url, fetch);
      final next = cache();
      expect(await next.load(url, unexpectedFetch), png);
      expect((await next.stats())['bytes'], png.length);
      expect((await next.stats())['items'], 1);
      final names = await directory
          .list()
          .map((f) => f.uri.pathSegments.last)
          .toList();
      expect(names.single, matches(RegExp(r'^[a-f0-9]{64}\.png$')));
    },
  );

  test('disk reads refresh eviction order across restarts', () async {
    final first = cache(bytes: png.length * 2);
    await first.load('a', fetch);
    await first.load('b', fetch);
    first.memory.clear();
    await first.load('a', unexpectedFetch);
    await first.load('c', fetch);
    expect((await first.stats())['bytes'], png.length * 2);
    final second = cache(bytes: png.length * 2);
    expect(await second.load('a', unexpectedFetch), png);
    expect(await second.load('c', unexpectedFetch), png);
    var downloaded = false;
    await second.load('b', () async {
      downloaded = true;
      return png;
    });
    expect(downloaded, isTrue);
  });

  test('startup enforces entry limit and discards unfinished files', () async {
    final first = cache();
    await first.load('a', fetch);
    await first.load('b', fetch);
    await File('${directory.path}/unfinished.part').writeAsBytes(png);
    expect((await cache(entries: 1).stats())['items'], 1);
    expect(await directory.list().length, 1);
  });

  test(
    'clear removes disk and memory and invalidates in-flight loads',
    () async {
      final store = cache();
      await store.load('a', fetch);
      final started = Completer<void>();
      final download = Completer<Uint8List?>();
      final pending = store.load('b', () {
        started.complete();
        return download.future;
      });
      await started.future;
      await store.clear();
      download.complete(png);
      expect(await pending, isNull);
      expect(store.memory.get('a'), isNull);
      expect((await store.stats())['bytes'], 0);
      expect((await cache().stats())['items'], 0);
      expect(await store.load('b', fetch), png);
      expect((await store.stats())['items'], 1);
    },
  );

  test('clear invalidates image preparation too', () async {
    final started = Completer<void>();
    final prepared = Completer<Uint8List?>();
    final store = QueueArtworkCache(
      directory: () async => directory,
      prepare: (_) {
        started.complete();
        return prepared.future;
      },
    );
    final pending = store.load('a', fetch);
    await started.future;
    await store.clear();
    prepared.complete(png);
    expect(await pending, isNull);
    expect((await store.stats())['items'], 0);
  });

  test('missing and truncated files are downloaded again', () async {
    final store = cache();
    await store.load('a', fetch);
    store.memory.clear();
    final file = (await directory.list().toList()).single as File;
    await file.writeAsBytes([1, 2, 3]);
    var downloads = 0;
    Future<Uint8List?> reload() async {
      downloads++;
      return png;
    }

    expect(await store.load('a', reload), png);
    store.memory.clear();
    await file.delete();
    expect((await store.stats())['bytes'], 0);
    expect(await store.load('a', reload), png);
    expect(downloads, 2);
  });

  test(
    'unavailable disk still loads and reuses thumbnails in memory',
    () async {
      final store = QueueArtworkCache(
        directory: () async => throw const FileSystemException('unavailable'),
        prepare: (bytes) async => bytes,
      );
      expect(await store.load('a', fetch), png);
      expect(await store.load('a', unexpectedFetch), png);
    },
  );

  test('failed and cancelled downloads do not fill the cache', () async {
    final store = cache();
    expect(await store.load('a', () async => null), isNull);
    var cancelled = false;
    expect(
      await store.load('b', () async {
        cancelled = true;
        return png;
      }, cancelled: () => cancelled),
      isNull,
    );
    expect((await store.stats())['items'], 0);
    expect(await store.load('a', fetch), png);
  });

  test(
    'large artwork becomes a thumbnail with the same aspect ratio',
    () async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(
        recorder,
      ).drawColor(const ui.Color(0xff123456), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final original = await picture.toImage(1200, 600);
      final bytes = await original.toByteData(format: ui.ImageByteFormat.png);
      original.dispose();
      picture.dispose();
      final resized = await QueueArtworkCache.thumbnail(
        bytes!.buffer.asUint8List(),
      );
      final codec = await ui.instantiateImageCodec(resized!);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 256);
      expect(frame.image.height, 128);
      frame.image.dispose();
      codec.dispose();
      expect(
        await QueueArtworkCache.thumbnail(Uint8List.fromList([1, 2, 3])),
        isNull,
      );
    },
  );

  testWidgets('settings row shows usage and clears the cache', (tester) async {
    final container = AppContainer();
    final store = _RowCache();
    container.sendspin.queueArtworkCache = store;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AlbumArtCacheRow(container: container)),
      ),
    );
    await tester.pump();
    expect(find.text('Album art cache'), findsOneWidget);
    expect(find.textContaining('1.0 KB used of 100.0 MB'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(find.textContaining('0 B used of 100.0 MB'), findsOneWidget);
    expect(store.clears, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _RowCache extends QueueArtworkCache {
  int bytes = 1024;
  int clears = 0;

  @override
  Future<Map<String, Object?>> stats() async => {
    'bytes': bytes,
    'items': bytes == 0 ? 0 : 1,
    'maxBytes': 100 << 20,
  };

  @override
  Future<void> clear() async {
    clears++;
    bytes = 0;
  }
}
