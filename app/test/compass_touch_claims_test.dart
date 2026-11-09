import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/compass/compass_touch_claims.dart';

// A plugin overlay marks its own touches, so a drag on its slider is never
// taken for a Compass swipe. A touch beside it stays free.
void main() {
  testWidgets('a touch on the marked widget is claimed, one beside it is not', (
    tester,
  ) async {
    final seen = <int, bool>{};
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Listener(
          // An ancestor, like the Compass gesture layer: it hears the
          // touch after the marked widget did.
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) =>
              seen[e.pointer] = CompassTouchClaims.claimed(e.pointer),
          child: Stack(
            children: [
              const SizedBox.expand(),
              Positioned(
                left: 0,
                top: 0,
                width: 100,
                height: 100,
                child: CompassClaimTouches(
                  child: Container(color: const Color(0xFF000000)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final on = await tester.startGesture(const Offset(50, 50));
    final off = await tester.startGesture(const Offset(300, 300));
    expect(seen.values.toList(), [true, false]);
    await on.up();
    await off.up();
    // Lifted: the mark goes with it.
    expect(seen.keys.every((p) => !CompassTouchClaims.claimed(p)), isTrue);
  });
}
