import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/sendspin/artwork_cache.dart';

void main() {
  test(
    'concurrent surfaces share a download and the same encoded bytes',
    () async {
      final cache = ArtworkCache();
      final pending = Completer<Uint8List?>();
      var calls = 0;
      Future<Uint8List?> fetch(String url) {
        calls++;
        return pending.future;
      }

      final first = cache.load('cover', fetch);
      final second = cache.load('cover', fetch);
      final bytes = Uint8List.fromList([1, 2, 3]);
      pending.complete(bytes);
      expect(await first, same(bytes));
      expect(await second, same(bytes));
      expect(await cache.load('cover', fetch), same(bytes));
      expect(calls, 1);
    },
  );

  test('byte and entry bounds evict the least recently used covers', () async {
    final cache = ArtworkCache(maxBytes: 6, maxEntries: 2);
    final calls = <String>[];
    Future<Uint8List?> fetch(String url) async {
      calls.add(url);
      return Uint8List(3);
    }

    await cache.load('a', fetch);
    await cache.load('b', fetch);
    await cache.load('a', fetch);
    await cache.load('c', fetch);
    expect(cache.bytes, 6);
    expect(cache.length, 2);
    await cache.load('a', fetch);
    expect(calls, ['a', 'b', 'c']);
    await cache.load('b', fetch);
    expect(calls, ['a', 'b', 'c', 'b']);
    final tiny = ArtworkCache(maxBytes: 100, maxEntries: 2);
    for (final url in ['a', 'b', 'c']) {
      await tiny.load(url, fetch);
    }
    expect(tiny.length, 2);
  });

  test(
    'oversized covers are returned without displacing cached covers',
    () async {
      final cache = ArtworkCache(maxBytes: 4);
      await cache.load('small', (_) async => Uint8List(3));
      expect((await cache.load('large', (_) async => Uint8List(8)))!.length, 8);
      expect(cache.bytes, 3);
      expect(cache.length, 1);
    },
  );

  test('failed and empty downloads can be retried', () async {
    final cache = ArtworkCache();
    await expectLater(
      cache.load('a', (_) => throw StateError('offline')),
      throwsStateError,
    );
    expect(await cache.load('a', (_) async => null), isNull);
    expect((await cache.load('a', (_) async => Uint8List(2)))!.length, 2);
  });
}
