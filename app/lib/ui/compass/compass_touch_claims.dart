import 'package:flutter/widgets.dart';

/// Touches something drawn over the Compass views took for itself, such as
/// a plugin overlay's slider: a drag that starts there is never a swipe.
///
/// A widget marks the touch with [CompassClaimTouches]. Pointer events
/// reach the deepest widget first, so the mark is in place before the
/// Compass gesture layer, an ancestor of everything on screen, sees the
/// same touch go down.
abstract final class CompassTouchClaims {
  static final _pointers = <int>{};

  static bool claimed(int pointer) => _pointers.contains(pointer);

  static void claim(int pointer) {
    // A lifted touch normally takes its mark with it. A widget that left
    // mid touch never sees the lift, so the set is kept from growing.
    if (_pointers.length > 16) _pointers.clear();
    _pointers.add(pointer);
  }

  static void release(int pointer) => _pointers.remove(pointer);
}

/// Marks every touch that lands on [child] for [CompassTouchClaims]. Only a
/// touch that hits the child counts.
class CompassClaimTouches extends StatelessWidget {
  const CompassClaimTouches({
    super.key,
    required this.child,
    this.behavior = HitTestBehavior.deferToChild,
  });

  final Widget child;
  final HitTestBehavior behavior;

  @override
  Widget build(BuildContext context) => Listener(
    behavior: behavior,
    onPointerDown: (e) => CompassTouchClaims.claim(e.pointer),
    onPointerUp: (e) => CompassTouchClaims.release(e.pointer),
    onPointerCancel: (e) => CompassTouchClaims.release(e.pointer),
    child: child,
  );
}
