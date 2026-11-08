/// The page's half of Compass navigation.
///
/// The swipe itself is read on the Flutter side, from raw pointer events
/// that never enter the gesture arena, so the WebView keeps every touch as
/// it always did. What Flutter cannot see is the page: whether the finger
/// landed on something that owns its own drag (a slider, a map, a card that
/// scrolls sideways) and whether the page can still scroll the way a
/// vertical swipe would go. This probe answers both, once per touch, at
/// touchstart, through the `ksCompassTouch` handler:
///
/// * `h`: a sideways swipe belongs to the page (a slider, a map, a dialog,
///   a sideways scroller, a card that runs its own swipe).
/// * `v`: an up or down swipe belongs to the page (the same controls, minus
///   the sideways scrollers).
/// * `top` / `bottom`: every scroller under the finger, the document
///   included, is at its top or bottom, so a pull past that edge is the
///   kiosk's to take.
///
/// Capture-phase and passive like the pull-to-refresh probe: the page
/// cannot swallow it and it cannot slow scrolling. Always injected, acting
/// only while `window.__ksCompassEnabled` says so, so switching the
/// navigation style needs no reload.
const compassPageScript = r'''
(function () {
  if (window.__ksCompassProbe) return;
  window.__ksCompassProbe = true;

  var BLOCK = /^(input|textarea|select|video|audio|canvas|iframe)$/;

  function owns(n, sideways) {
    var name = n.localName || '';
    var cls = n.getAttribute('class') || '';
    if (BLOCK.test(name) ||
        name.indexOf('slider') !== -1 ||
        cls.indexOf('slider') !== -1 ||
        n.getAttribute('role') === 'slider' ||
        name.indexOf('dialog') !== -1 ||
        name.indexOf('-map') !== -1 ||
        cls.indexOf('leaflet') !== -1 ||
        name.indexOf('swipe') !== -1 ||
        cls.indexOf('swiper') !== -1) {
      return true;
    }
    // A card that scrolls sideways on its own keeps a sideways swipe.
    if (sideways && n.scrollWidth > n.clientWidth + 8) {
      var ox = getComputedStyle(n).overflowX;
      if (ox === 'auto' || ox === 'scroll') return true;
    }
    return false;
  }

  function report(e) {
    if (window.__ksCompassEnabled !== true) return;
    if (!e.touches || e.touches.length !== 1) return;
    var path = e.composedPath ? e.composedPath() : [];
    var h = false, v = false, top = true, bottom = true;
    for (var i = 0; i < path.length; i++) {
      var n = path[i];
      if (!(n instanceof Element)) continue;
      if (!h && owns(n, true)) h = true;
      if (!v && owns(n, false)) v = true;
      if (n.scrollHeight > n.clientHeight + 4) {
        var oy = getComputedStyle(n).overflowY;
        if (oy === 'auto' || oy === 'scroll') {
          if (n.scrollTop > 4) top = false;
          if (n.scrollTop + n.clientHeight < n.scrollHeight - 4) bottom = false;
        }
      }
    }
    var doc = document.scrollingElement || document.documentElement;
    if (doc) {
      if (doc.scrollTop > 4) top = false;
      if (doc.scrollTop + window.innerHeight < doc.scrollHeight - 4) {
        bottom = false;
      }
    }
    try {
      window.flutter_inappwebview.callHandler('ksCompassTouch', {
        h: h, v: v, top: top, bottom: bottom
      });
    } catch (_) {}
  }

  window.addEventListener('touchstart', report, { capture: true, passive: true });
})();
''';
