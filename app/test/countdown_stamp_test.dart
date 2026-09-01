import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/btproxy/countdown_stamp.dart';

/// The Next screensaver stamp (issue #406): the first moment after a quiet
/// spell publishes immediately, a stream of touches collapses to one
/// publish a minute, the trailing publish carries the true moment, and the
/// moment on the wire is corrected before it can pass.
void main() {
  test('leading edge lands immediately, a touch stream throttles to one '
      'publish a minute, and the trailing publish keeps the final moment', () {
    fakeAsync((async) {
      var now = DateTime.utc(2026, 9, 1, 12);
      void tick(Duration d) {
        now = now.add(d);
        async.elapse(d);
      }

      const timeout = Duration(minutes: 5);
      final published = <DateTime?>[];
      final stamp = CountdownStamp(published.add, now: () => now);

      stamp.set(now.add(timeout));
      expect(published, [DateTime.utc(2026, 9, 1, 12, 5)]);

      tick(const Duration(seconds: 10));
      stamp.set(now.add(timeout)); // throttled; a trailing publish is armed
      tick(const Duration(seconds: 20));
      stamp.set(
        now.add(timeout),
      ); // refreshes what the trailing publish carries
      final lastDue = now.add(timeout);
      expect(published, hasLength(1));
      expect(stamp.latest, lastDue);

      tick(const Duration(seconds: 30)); // the minute gap runs out
      expect(published, hasLength(2));
      expect(published.last, lastDue);

      tick(const Duration(seconds: 90));
      stamp.set(now.add(timeout)); // quiet spell over: leading edge again
      expect(published, hasLength(3));
      expect(published.last, now.add(timeout));
    });
  });

  test('a short timeout republishes before the moment on the wire passes', () {
    fakeAsync((async) {
      var now = DateTime.utc(2026, 9, 1, 12);
      void tick(Duration d) {
        now = now.add(d);
        async.elapse(d);
      }

      const timeout = Duration(seconds: 30);
      final published = <DateTime?>[];
      final stamp = CountdownStamp(published.add, now: () => now);

      stamp.set(now.add(timeout));
      final first = now.add(timeout);
      tick(const Duration(seconds: 10));
      stamp.set(now.add(timeout));
      tick(const Duration(seconds: 10));
      stamp.set(now.add(timeout));
      final lastDue = now.add(timeout);
      expect(published, [first]);

      // 29s after the first publish: one second before it would pass, the
      // real moment replaces it, minute gap or not.
      tick(const Duration(seconds: 9));
      expect(published, [first, lastDue]);
    });
  });

  test('a clear lands at once and the next moment after it does too', () {
    fakeAsync((async) {
      var now = DateTime.utc(2026, 9, 1, 12);
      void tick(Duration d) {
        now = now.add(d);
        async.elapse(d);
      }

      final published = <DateTime?>[];
      final stamp = CountdownStamp(published.add, now: () => now);

      stamp.set(now.add(const Duration(minutes: 5)));
      tick(const Duration(seconds: 5));
      stamp.set(now.add(const Duration(minutes: 5))); // held
      tick(const Duration(seconds: 5));
      stamp.set(null); // a voice turn: nothing counts down
      expect(published, hasLength(2));
      expect(published.last, isNull);
      tick(const Duration(seconds: 5));
      final due = now.add(const Duration(minutes: 5));
      stamp.set(due); // the turn ended: the clock is back
      expect(published, hasLength(3));
      expect(published.last, due);
      // The held moment from before the clear never lands on its own.
      tick(const Duration(minutes: 2));
      expect(published, hasLength(3));
    });
  });

  test('setting the published moment again cancels a waiting publish', () {
    fakeAsync((async) {
      var now = DateTime.utc(2026, 9, 1, 12);
      final published = <DateTime?>[];
      final stamp = CountdownStamp(published.add, now: () => now);
      final due = now.add(const Duration(minutes: 5));
      stamp.set(due);
      now = now.add(const Duration(seconds: 10));
      async.elapse(const Duration(seconds: 10));
      stamp.set(due.add(const Duration(seconds: 10)));
      stamp.set(due);
      async.elapse(const Duration(minutes: 2));
      expect(published, [due]);
    });
  });

  test('dispose cancels a waiting trailing publish', () {
    fakeAsync((async) {
      var now = DateTime.utc(2026, 9, 1, 12);
      final published = <DateTime?>[];
      final stamp = CountdownStamp(published.add, now: () => now);
      stamp.set(now.add(const Duration(minutes: 5)));
      now = now.add(const Duration(seconds: 10));
      async.elapse(const Duration(seconds: 10));
      stamp.set(now.add(const Duration(minutes: 5)));
      stamp.dispose();
      async.elapse(const Duration(minutes: 2));
      expect(published, hasLength(1));
    });
  });
}
