/// Pull-to-refresh fallback for scrollable pages.
///
/// Android's swipe-refresh wrapper (PullToRefreshController) only receives
/// the gesture when Chromium declines it, and Chromium claims every vertical
/// drag on a page with a scrollable document — so native pull-to-refresh
/// works on pages that fit the screen and goes dead the moment one scrolls.
/// The page itself is the only party that always sees the gesture, so it
/// reports a qualifying pull over the JS bridge instead.
///
/// Qualifying means: a single-finger downward drag of at least 160px that
/// STARTED with every scroller in the touch path at its top. The path check
/// walks `composedPath()`, which pierces shadow DOM — Home Assistant scrolls
/// in a shadow-root scroller while the document stays at 0, and without this
/// a pull mid-dashboard-scroll would reload the page out from under you.
///
/// Capture-phase, passive listeners: the page cannot swallow them and they
/// cannot slow its scrolling. Whether a report acts is the app's decision
/// (the setting is checked on the Dart side), so toggling the setting needs
/// no reinjection.
const pullToRefreshProbeScript = '''
(function () {
  if (window.__ksPullProbe) return;
  window.__ksPullProbe = true;
  var startY = null, armed = false, fired = false;
  function pathAtTop(e) {
    var path = e.composedPath ? e.composedPath() : [];
    for (var i = 0; i < path.length; i++) {
      var el = path[i];
      if (el instanceof Element && el.scrollTop > 0) return false;
    }
    var doc = document.scrollingElement || document.documentElement;
    return !doc || doc.scrollTop <= 0;
  }
  addEventListener('touchstart', function (e) {
    fired = false;
    armed = e.touches.length === 1 && pathAtTop(e);
    startY = armed ? e.touches[0].clientY : null;
  }, { passive: true, capture: true });
  addEventListener('touchmove', function (e) {
    if (!armed || fired || e.touches.length !== 1) return;
    if (e.touches[0].clientY - startY > 160) {
      fired = true;
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('ksPullToRefresh');
      }
    }
  }, { passive: true, capture: true });
})();
''';
