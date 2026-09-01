/// What the kiosk screen does with a system back press (discussion #312).
///
/// On gesture-navigation devices the OS owns the left edge: the swipe that
/// would open the menu is claimed as the back gesture before the app ever
/// sees it, and arrives as a back press instead. So back doubles as the
/// menu key, the double-back pattern of Instagram and TikTok: over the
/// bare kiosk the first press opens the menu and a toast says to press
/// again, and a second press within the window performs the back the
/// first one swallowed — re-arming the window, so a run of quick presses
/// keeps stepping the history without the menu reopening between them.
/// A press with something dismissable on screen keeps its old job, one
/// layer at a time.
///
/// Pure on purpose: the kiosk screen itself cannot be pumped in a widget
/// test (the dashboard is a platform view), so the decision is kept where
/// a test can reach it.
library;

enum BackAction {
  /// The screensaver is showing: the press is its dismissal and nothing
  /// else — it must not also close or step something invisible behind it.
  stopScreensaver,

  /// The menu is open (an edge swipe opened it, or the double-back window
  /// has lapsed): close it, nothing more.
  closeDrawer,

  /// The menu is open from a first back press still inside the window:
  /// close it and perform the back that press swallowed.
  closeDrawerAndBack,

  /// The app launcher is up: hide it.
  hideLauncher,

  /// A link or rotation page covers the dashboard: back uncovers it.
  dismissOverlay,

  /// A camera view with one camera focused: back out to the grid.
  unfocusCamera,

  /// A camera view without a focused camera: hide the view.
  hideCameraView,

  /// First press over the bare kiosk: open the menu, arm the window, show
  /// the toast. While kiosk mode is locked this must open the restricted
  /// quick menu, exactly as the edge swipe would.
  openDrawer,

  /// The real back: step the page history, or leave the app where the
  /// plain pop used to (see [backLeavesApp]).
  back,
}

/// The decision for one back press, from where the UI stands.
///
/// [armed] is a still-live double-back window: the previous press opened
/// the menu (or stepped the history) recently enough that this one means
/// "really go back". [quickMenuAvailable] mirrors the edge swipe's gate
/// while kiosk mode is locked: the owner opted into the quick menu and it
/// would actually show something. Lockdown never opens the menu on back —
/// its shield answers to the exit gesture alone — and keeps the old
/// invisible history step even under the screensaver, so back changes
/// nothing about how lockdown holds the screen.
BackAction decideBack({
  required bool drawerOpen,
  required bool armed,
  required bool launcherVisible,
  required bool overlayUp,
  required bool cameraViewUp,
  required bool cameraFocused,
  required bool screensaverActive,
  required bool lockdown,
  required bool locked,
  required bool quickMenuAvailable,
}) {
  if (screensaverActive && !lockdown) return BackAction.stopScreensaver;
  if (drawerOpen) {
    return armed ? BackAction.closeDrawerAndBack : BackAction.closeDrawer;
  }
  if (launcherVisible) return BackAction.hideLauncher;
  if (overlayUp) return BackAction.dismissOverlay;
  if (cameraViewUp) {
    return cameraFocused ? BackAction.unfocusCamera : BackAction.hideCameraView;
  }
  if (armed) return BackAction.back;
  if (!lockdown && (!locked || quickMenuAvailable)) {
    return BackAction.openDrawer;
  }
  return BackAction.back;
}

/// Whether the real back leaves the app — the plain pop of old: the
/// Activity finishes and the task behind shows — rather than stepping the
/// page history. Kiosk mode and lockdown must never background the app,
/// and a home screen never finishes on back (issue #219).
bool backLeavesApp({
  required bool locked,
  required bool lockdown,
  required bool homeRoleHeld,
}) => !locked && !lockdown && !homeRoleHeld;
