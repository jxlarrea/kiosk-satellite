/// What the kiosk screen does with a navigation key press (issue #377).
///
/// A TV box or a tablet with a remote has no touch: the dpad is the whole
/// input, and until now its presses sank into whatever native view held
/// focus, leaving no way to reach the menu. MainActivity routes the dpad,
/// arrow and select keys by hand: into Flutter while a surface of ours
/// navigates (the navCapture flag the kiosk screen pushes), to the
/// frontmost WebView over the bare dashboard — all but left, which always
/// comes here to open the drawer. The kiosk screen asks this table what
/// an arriving press means where the UI currently stands, and leaves
/// everything it can to the framework's own focus traversal (arrows walk
/// the focusable rows, select taps the focused one).
///
/// Pure on purpose: the kiosk screen itself cannot be pumped in a widget
/// test (the dashboard is a platform view), so the decision is kept where
/// a test can reach it.
library;

import 'package:flutter/widgets.dart';

/// The app-wide traversal policy (installed around the whole app in
/// main.dart): reading order, plus one repair. Arrow traversal scrolls
/// only far enough to reveal the focused row itself, so walking up a
/// settings page stops with the first row at the viewport's top edge and
/// the page title above it off screen for good — a dpad user can never
/// see which page they are on again. Focusing the first row of a scope
/// therefore scrolls its scrollable all the way to the top, bringing the
/// header back with it.
class KsTraversalPolicy extends ReadingOrderTraversalPolicy {
  KsTraversalPolicy() : super(requestFocusCallback: _requestFocus);

  /// Sort order only; stateless, so one instance serves the callback.
  static final _order = ReadingOrderTraversalPolicy();

  static void _requestFocus(
    FocusNode node, {
    ScrollPositionAlignmentPolicy? alignmentPolicy,
    double? alignment,
    Duration? duration,
    Curve? curve,
  }) {
    FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
      node,
      alignmentPolicy: alignmentPolicy,
      alignment: alignment,
      duration: duration,
      curve: curve,
    );
    final scope = node.enclosingScope;
    final context = node.context;
    if (scope == null || context == null) return;
    final sorted = _order.sortDescendants(scope.traversalDescendants, node);
    if (sorted.isEmpty || sorted.first != node) return;
    final position = Scrollable.maybeOf(context)?.position;
    if (position == null || position.pixels <= position.minScrollExtent) {
      return;
    }
    position.animateTo(
      position.minScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }
}

enum KeyNavAction {
  /// Not ours: leave the key to the focus system.
  pass,

  /// Consumed with no further effect. The screensaver case: the activity
  /// ping sent alongside already dismissed it, and the same press must not
  /// also land somewhere behind it.
  swallow,

  /// Open the drawer and move focus onto its first entry.
  openDrawer,

  /// The drawer is open (an edge swipe opened it) but holds no focus yet:
  /// focus its first entry so the arrows have somewhere to start.
  focusDrawer,
}

/// The decision for one navigation key, from where the UI stands.
///
/// [overlayUp] is any surface out of the feature's scope sitting over the
/// kiosk: the app launcher, a camera view, a rotation page. [routeCovered]
/// is any route pushed over the kiosk screen — the settings route, a
/// dialog, a picker — each a focus scope of its own that the framework's
/// traversal bootstraps and walks by itself; grabbing the drawer's focus
/// from under an "Exit Application" confirm would send the arrows behind
/// the modal. [openAllowed] mirrors the edge swipe's own gate: the kiosk
/// is unlocked, or the owner opted into the restricted quick menu.
KeyNavAction decideNavKey({
  required bool lockdown,
  required bool screensaverActive,
  bool nowPlayingControls = false,
  required bool overlayUp,
  required bool routeCovered,
  required bool drawerOpen,
  required bool drawerFocused,
  required bool openAllowed,
  required bool isLeft,
}) {
  // Lockdown swallows keys like its shield swallows touches: nothing on
  // screen may answer.
  if (lockdown) return KeyNavAction.swallow;
  // The Now Playing view with its media controls up is a page of
  // buttons: the arrows walk them and select presses them, the way a
  // touch there is a press and not a dismissal.
  if (screensaverActive) {
    return nowPlayingControls ? KeyNavAction.pass : KeyNavAction.swallow;
  }
  if (overlayUp || routeCovered) return KeyNavAction.pass;
  if (drawerOpen) {
    return drawerFocused ? KeyNavAction.pass : KeyNavAction.focusDrawer;
  }
  if (isLeft && openAllowed) return KeyNavAction.openDrawer;
  // Up, down, right and select over the bare kiosk: consumed, or a focus
  // search would land on something invisible behind the dashboard.
  return KeyNavAction.swallow;
}
