import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/thumb_cache.dart';

/// The queue panel's thumbnail store and fetch line: bounded by bytes
/// with the oldest out first, and a few fetches at a time with a row
/// that scrolled away withdrawing before its turn.
void main() {
  Uint8List bytes(int n) => Uint8List(n);

  group('ThumbCache', () {
    test('evicts the least recently used past the byte budget', () {
      final cache = ThumbCache(maxBytes: 100);
      cache.put('a', bytes(40));
      cache.put('b', bytes(40));
      // A hit moves 'a' to the back of the line, so 'b' goes first.
      expect(cache.get('a'), isNotNull);
      cache.put('c', bytes(40));
      expect(cache.contains('b'), isFalse);
      expect(cache.contains('a'), isTrue);
      expect(cache.contains('c'), isTrue);
      expect(cache.bytes, 80);
    });

    test('remembers an empty fetch without spending the budget', () {
      final cache = ThumbCache(maxBytes: 100);
      cache.put('missing', null);
      expect(cache.contains('missing'), isTrue);
      expect(cache.get('missing'), isNull);
      expect(cache.bytes, 0);
    });

    test('an image past the whole budget is not kept', () {
      final cache = ThumbCache(maxBytes: 100);
      cache.put('a', bytes(40));
      cache.put('huge', bytes(500));
      expect(cache.contains('huge'), isFalse);
      expect(cache.contains('a'), isTrue);
    });

    test('a thousand covers stay within the budget', () {
      final cache = ThumbCache(maxBytes: 3 << 20);
      for (var i = 0; i < 1000; i++) {
        cache.put('cover $i', bytes(80 * 1024));
      }
      expect(cache.bytes, lessThanOrEqualTo(3 << 20));
      expect(cache.length, lessThan(40));
    });
  });

  group('FetchLane', () {
    test('runs a few at a time and lets a waiter withdraw', () async {
      final lane = FetchLane(width: 2);
      final gates = <Completer<void>>[];
      final ran = <int>[];
      for (var i = 0; i < 4; i++) {
        final gate = Completer<void>();
        gates.add(gate);
        lane.schedule(() {
          ran.add(i);
          return gate.future;
        });
      }
      expect(ran, [0, 1]);
      expect(lane.pending, 2);
      // The third row scrolled away: it never runs.
      // (Withdrawing needs the ticket; schedule one more and cancel it.)
      final ticket = lane.schedule(() async => ran.add(9));
      expect(ticket.cancel(), isTrue);
      gates[0].complete();
      await Future<void>.delayed(Duration.zero);
      expect(ran, [0, 1, 2]);
      gates[1].complete();
      gates[2].complete();
      await Future<void>.delayed(Duration.zero);
      expect(ran, [0, 1, 2, 3]);
      expect(lane.pending, 0);
    });
  });
}
