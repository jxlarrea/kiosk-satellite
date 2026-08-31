import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/key_nav.dart';

/// Issue #377: what the kiosk screen does with a dpad/arrow/select press,
/// state by state. The kiosk screen itself cannot be pumped (the dashboard
/// is a platform view), so the decision table is tested on its own.
void main() {
  KeyNavAction decide({
    bool lockdown = false,
    bool screensaverActive = false,
    bool overlayUp = false,
    bool routeCovered = false,
    bool drawerOpen = false,
    bool drawerFocused = false,
    bool openAllowed = true,
    bool isLeft = false,
  }) => decideNavKey(
    lockdown: lockdown,
    screensaverActive: screensaverActive,
    overlayUp: overlayUp,
    routeCovered: routeCovered,
    drawerOpen: drawerOpen,
    drawerFocused: drawerFocused,
    openAllowed: openAllowed,
    isLeft: isLeft,
  );

  group('decideNavKey', () {
    test('left over the bare kiosk opens the drawer', () {
      expect(decide(isLeft: true), KeyNavAction.openDrawer);
    });

    test('other keys over the bare kiosk are swallowed, not left to a '
        'focus search across invisible widgets', () {
      expect(decide(), KeyNavAction.swallow);
    });

    test(
      'left while the kiosk is locked without the quick menu stays shut',
      () {
        expect(decide(isLeft: true, openAllowed: false), KeyNavAction.swallow);
      },
    );

    test('locked with the quick menu opted in still opens', () {
      expect(decide(isLeft: true, openAllowed: true), KeyNavAction.openDrawer);
    });

    test('lockdown swallows everything, screensaver dismissal included', () {
      expect(decide(lockdown: true, isLeft: true), KeyNavAction.swallow);
      expect(
        decide(lockdown: true, screensaverActive: true),
        KeyNavAction.swallow,
      );
    });

    test('a showing screensaver takes the press as its dismissal only', () {
      expect(decide(screensaverActive: true), KeyNavAction.swallow);
      expect(
        decide(screensaverActive: true, isLeft: true),
        KeyNavAction.swallow,
      );
    });

    test('an open drawer without focus gets focused first', () {
      expect(decide(drawerOpen: true), KeyNavAction.focusDrawer);
    });

    test('an open, focused drawer leaves the arrows to focus traversal', () {
      expect(decide(drawerOpen: true, drawerFocused: true), KeyNavAction.pass);
    });

    test('a covering route - settings, a dialog - owns its keys', () {
      expect(decide(routeCovered: true, isLeft: true), KeyNavAction.pass);
      expect(
        decide(routeCovered: true, drawerOpen: true),
        KeyNavAction.pass,
      );
    });

    test('launcher, camera view and rotation pages are left alone', () {
      expect(decide(overlayUp: true, isLeft: true), KeyNavAction.pass);
    });

    test('screensaver outranks an open drawer left behind it', () {
      expect(
        decide(screensaverActive: true, drawerOpen: true, drawerFocused: true),
        KeyNavAction.swallow,
      );
    });
  });
}
