import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/back_nav.dart';

/// Discussion #312: what the kiosk screen does with a system back press,
/// state by state. The kiosk screen itself cannot be pumped (the dashboard
/// is a platform view), so the decision table is tested on its own.
void main() {
  BackAction decide({
    bool drawerOpen = false,
    bool armed = false,
    bool launcherVisible = false,
    bool overlayUp = false,
    bool cameraViewUp = false,
    bool cameraFocused = false,
    bool screensaverActive = false,
    bool lockdown = false,
    bool locked = false,
    bool quickMenuAvailable = false,
  }) => decideBack(
    drawerOpen: drawerOpen,
    armed: armed,
    launcherVisible: launcherVisible,
    overlayUp: overlayUp,
    cameraViewUp: cameraViewUp,
    cameraFocused: cameraFocused,
    screensaverActive: screensaverActive,
    lockdown: lockdown,
    locked: locked,
    quickMenuAvailable: quickMenuAvailable,
  );

  group('decideBack', () {
    test('first press over the bare kiosk opens the menu', () {
      expect(decide(), BackAction.openDrawer);
    });

    test('a press inside the window does the back the first one swallowed, '
        'menu open or already closed by hand', () {
      expect(
        decide(drawerOpen: true, armed: true),
        BackAction.closeDrawerAndBack,
      );
      expect(decide(armed: true), BackAction.back);
    });

    test('a lapsed window just closes the menu again', () {
      expect(decide(drawerOpen: true), BackAction.closeDrawer);
    });

    test('locked kiosk without the quick menu keeps the old history step', () {
      expect(decide(locked: true), BackAction.back);
    });

    test('locked with the quick menu opted in opens on back too', () {
      expect(
        decide(locked: true, quickMenuAvailable: true),
        BackAction.openDrawer,
      );
    });

    test('lockdown never opens the menu, quick menu or not', () {
      expect(decide(lockdown: true), BackAction.back);
      expect(
        decide(lockdown: true, locked: true, quickMenuAvailable: true),
        BackAction.back,
      );
    });

    test('a showing screensaver takes the press as its dismissal only', () {
      expect(decide(screensaverActive: true), BackAction.stopScreensaver);
      expect(
        decide(screensaverActive: true, drawerOpen: true),
        BackAction.stopScreensaver,
      );
    });

    test('under lockdown the screensaver is left alone, as before', () {
      expect(decide(lockdown: true, screensaverActive: true), BackAction.back);
    });

    test('covering surfaces keep their old jobs, one layer at a time', () {
      expect(decide(launcherVisible: true), BackAction.hideLauncher);
      expect(decide(overlayUp: true), BackAction.dismissOverlay);
      expect(decide(cameraViewUp: true), BackAction.hideCameraView);
      expect(
        decide(cameraViewUp: true, cameraFocused: true),
        BackAction.unfocusCamera,
      );
    });

    test('an armed window does not skip past a covering surface', () {
      expect(
        decide(armed: true, launcherVisible: true),
        BackAction.hideLauncher,
      );
      expect(decide(armed: true, overlayUp: true), BackAction.dismissOverlay);
    });
  });

  group('backLeavesApp', () {
    test('a plain unlocked kiosk backgrounds on the real back', () {
      expect(
        backLeavesApp(locked: false, lockdown: false, homeRoleHeld: false),
        isTrue,
      );
    });

    test('kiosk mode, lockdown and the home role each pin the app', () {
      expect(
        backLeavesApp(locked: true, lockdown: false, homeRoleHeld: false),
        isFalse,
      );
      expect(
        backLeavesApp(locked: false, lockdown: true, homeRoleHeld: false),
        isFalse,
      );
      expect(
        backLeavesApp(locked: false, lockdown: false, homeRoleHeld: true),
        isFalse,
      );
    });
  });
}
