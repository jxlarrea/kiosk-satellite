import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/motion/vision_presence.dart';

/// Vision Match > Presence sensors: Presence and Looking at the kiosk from
/// Ground Control's answers to the kiosk's looks.
void main() {
  late List<(bool, bool)> changes;
  late VisionPresence presence;

  void build() {
    changes = [];
    presence = VisionPresence((p, l) => changes.add((p, l)));
  }

  const facing = {
    'faces': [
      {'frontal': true},
    ],
  };
  const turned = {
    'faces': [
      {'frontal': false},
    ],
  };
  const hand = {'faces': <Object>[], 'hand': <String, Object>{}};
  const nobody = {'faces': <Object>[]};

  test('a face looking at the kiosk turns both on, and each goes off after '
      'its own hold', () {
    fakeAsync((async) {
      build();
      presence.look(facing);
      expect(changes, [(true, true)]);
      async.elapse(const Duration(seconds: 2));
      presence.look(turned);
      expect(changes, [(true, true)]);
      async.elapse(const Duration(seconds: 2));
      // Looking went 3 s after the last face looking at the kiosk.
      expect(changes.last, (true, false));
      async.elapse(const Duration(seconds: 27));
      expect(changes.last, (true, false));
      // Presence went 30 s after the last look that found someone.
      async.elapse(const Duration(seconds: 2));
      expect(changes.last, (false, false));
      expect(changes, hasLength(3));
    });
  });

  test('a turned head or a raised hand is presence without looking', () {
    fakeAsync((async) {
      build();
      presence.look(turned);
      expect(changes, [(true, false)]);
      presence.clear();
      presence.look(hand);
      expect(changes.last, (true, false));
    });
  });

  test('a look that finds nobody or fails keeps the holds running', () {
    fakeAsync((async) {
      build();
      presence.look(facing);
      presence.look(nobody);
      presence.look(const {'failed': true});
      expect(changes, [(true, true)]);
      async.elapse(const Duration(seconds: 31));
      expect(changes.last, (false, false));
    });
  });

  test('someone staying in view stays present', () {
    fakeAsync((async) {
      build();
      for (var i = 0; i < 10; i++) {
        presence.look(turned);
        async.elapse(const Duration(seconds: 20));
      }
      expect(changes, [(true, false)]);
    });
  });

  test('clear turns both off at once', () {
    fakeAsync((async) {
      build();
      presence.look(facing);
      presence.clear();
      expect(changes.last, (false, false));
      async.elapse(const Duration(minutes: 1));
      expect(changes, hasLength(2));
    });
  });
}
