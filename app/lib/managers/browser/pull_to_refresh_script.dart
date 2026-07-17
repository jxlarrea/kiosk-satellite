/// Pull-to-refresh fallback for scrollable pages.
///
/// Android's swipe-refresh wrapper (PullToRefreshController) only receives
/// the gesture when Chromium declines it, and Chromium claims every vertical
/// drag on a page with a scrollable document — so native pull-to-refresh
/// works on pages that fit the screen and goes dead the moment one scrolls.
/// The page itself is the only party that always sees the gesture, so it
/// reports a qualifying pull over the JS bridge instead.
///
/// Qualifying means: a mostly-vertical single-finger downward drag of at
/// least 80px (about the native trigger distance) measured from the moment
/// every scroller in the touch path sits at its top. Arming re-evaluates
/// during the drag, not only at touch-start — the natural gesture of
/// catching a moving list, riding it to the top and continuing to pull must
/// fire too. The path check walks `composedPath()`, which pierces shadow
/// DOM — Home Assistant scrolls in a shadow-root scroller while the document
/// stays at 0, and without this a pull mid-dashboard-scroll would reload the
/// page out from under you. Scroller tops tolerate a few sub-pixels: HA's
/// lists settle at fractional offsets after a fling.
///
/// Capture-phase, passive listeners: the page cannot swallow them and they
/// cannot slow its scrolling. Whether a report acts is the app's decision
/// (the setting is checked on the Dart side), so toggling the setting needs
/// no reinjection.
const pullToRefreshProbeScript = '''
(function () {
  if (window.__ksPullProbe) return;
  window.__ksPullProbe = true;
  var tracking = false, fired = false, x0 = 0, armY = null;
  function pathAtTop(e) {
    var path = e.composedPath ? e.composedPath() : [];
    for (var i = 0; i < path.length; i++) {
      var el = path[i];
      if (el instanceof Element && el.scrollTop > 4) return false;
    }
    var doc = document.scrollingElement || document.documentElement;
    return !doc || doc.scrollTop <= 4;
  }
  addEventListener('touchstart', function (e) {
    fired = false;
    tracking = e.touches.length === 1;
    if (!tracking) return;
    x0 = e.touches[0].clientX;
    armY = pathAtTop(e) ? e.touches[0].clientY : null;
  }, { passive: true, capture: true });
  addEventListener('touchmove', function (e) {
    if (!tracking || fired) return;
    if (e.touches.length !== 1) { tracking = false; return; }
    var t = e.touches[0];
    if (armY === null) {
      // Not at the top when the finger landed; arm the moment we get there.
      if (pathAtTop(e)) armY = t.clientY;
      return;
    }
    var dy = t.clientY - armY;
    if (dy > 80 && dy > Math.abs(t.clientX - x0) * 2) {
      fired = true;
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('ksPullToRefresh');
      }
    }
  }, { passive: true, capture: true });
})();
''';
