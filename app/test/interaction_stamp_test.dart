import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/managers/mqtt/interaction_stamp.dart';

/// The Last interaction stamp (issue #241): the first touch after a quiet
/// spell publishes immediately, a stream of touches collapses to one
/// publish a minute, and the trailing publish carries the true final stamp.
void main() {
  test(
      'leading edge lands immediately, a touch stream throttles to one '
      'publish a minute, and the trailing publish keeps the final stamp',
      () {
    fakeAsync((async) {
      var now = DateTime.utc(2026, 8, 19, 12);
      void tick(Duration d) {
        now = now.add(d);
        async.elapse(d);
      }

      final published = <DateTime>[];
      final stamp = InteractionStamp(published.add, now: () => now);

      stamp.mark();
      expect(published, [DateTime.utc(2026, 8, 19, 12)]);

      tick(const Duration(seconds: 10));
      stamp.mark(); // throttled; a trailing publish is armed
      tick(const Duration(seconds: 20));
      stamp.mark(); // refreshes the stamp the trailing publish will carry
      final lastTouch = now;
      expect(published, hasLength(1));
      expect(stamp.latest, lastTouch);

      tick(const Duration(seconds: 30)); // the minute gap runs out
      expect(published, hasLength(2));
      expect(published.last, lastTouch);

      tick(const Duration(seconds: 90));
      stamp.mark(); // quiet spell over: leading edge again
      expect(published, hasLength(3));
      expect(published.last, now);
    });
  });

  test('dispose cancels a waiting trailing publish', () {
    fakeAsync((async) {
      var now = DateTime.utc(2026, 8, 19, 12);
      final published = <DateTime>[];
      final stamp = InteractionStamp(published.add, now: () => now);
      stamp.mark();
      now = now.add(const Duration(seconds: 10));
      async.elapse(const Duration(seconds: 10));
      stamp.mark();
      stamp.dispose();
      async.elapse(const Duration(minutes: 2));
      expect(published, hasLength(1));
    });
  });

  test('only spoken turns count as voice interactions', () {
    expect(
        InteractionStamp.countsAsVoice(
            const VoiceInteractionChanged(active: true, reason: 'voice')),
        isTrue);
    // The legacy pauseScreensaver fallback carries no reason.
    expect(
        InteractionStamp.countsAsVoice(
            const VoiceInteractionChanged(active: true)),
        isTrue);
    expect(
        InteractionStamp.countsAsVoice(
            const VoiceInteractionChanged(active: false, reason: 'voice')),
        isFalse);
    for (final reason in ['announcement', 'timer', 'media']) {
      expect(
          InteractionStamp.countsAsVoice(
              VoiceInteractionChanged(active: true, reason: reason)),
          isFalse,
          reason: reason);
    }
  });
}
