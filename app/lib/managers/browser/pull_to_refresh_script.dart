/// Pull-to-refresh fallback for scrollable pages.
///
/// Android's swipe-refresh wrapper (PullToRefreshController) only receives
/// the gesture when Chromium declines it, and Chromium claims every vertical
/// drag on a page with a scrollable document — so native pull-to-refresh
/// works on pages that fit the screen and goes dead the moment one scrolls.
/// The page itself is the only party that always sees the gesture, so the
/// probe re-creates the whole interaction in-page:
///
/// * A Chrome-style disc indicator that follows the finger down with
///   resistance and rotates with progress — the animation the native side
///   would have drawn. On pages where the native wrapper *does* intercept,
///   the page receives touchcancel and the disc retracts: no double UI.
/// * The refresh fires on RELEASE past the threshold, never mid-drag —
///   reloading a page while a finger still holds a live gesture on it is
///   exactly the "spinner turns forever, reload lands much later" failure.
/// * Arming requires every scroller in the touch path at its top (walking
///   `composedPath()`, which pierces Home Assistant's shadow-root scrollers,
///   with a few sub-pixels of tolerance for post-fling remainders), and
///   re-evaluates during the drag so catching a moving list and riding it to
///   the top still counts. Scrolling away from the top disarms.
///
/// Capture-phase, passive listeners: the page cannot swallow them and they
/// cannot slow its scrolling. Whether a report acts is the app's decision
/// (the setting is checked on the Dart side), so toggling the setting needs
/// no reinjection; an ignored report only costs a retracting disc.
const pullToRefreshProbeScript = '''
(function () {
  if (window.__ksPullProbe) return;
  window.__ksPullProbe = true;

  var THRESHOLD = 72;   // travel (after resistance) that arms the release
  var MAX = 110;        // furthest the disc rides
  var tracking = false, fired = false, x0 = 0, armY = null, travel = 0;
  var el = null;

  function pathAtTop(e) {
    var path = e.composedPath ? e.composedPath() : [];
    for (var i = 0; i < path.length; i++) {
      var n = path[i];
      if (n instanceof Element && n.scrollTop > 4) return false;
    }
    var doc = document.scrollingElement || document.documentElement;
    return !doc || doc.scrollTop <= 4;
  }

  function indicator() {
    if (el) return el;
    if (!document.getElementById('__ksPtrStyle')) {
      var st = document.createElement('style');
      st.id = '__ksPtrStyle';
      st.textContent = '@keyframes __ksPtrSpin { to { transform: rotate(360deg); } }';
      (document.head || document.documentElement).appendChild(st);
    }
    el = document.createElement('div');
    el.setAttribute('style',
      'position:fixed;left:50%;top:0;z-index:2147483647;width:40px;height:40px;' +
      'margin-left:-20px;border-radius:50%;background:#fff;' +
      'box-shadow:0 2px 8px rgba(0,0,0,.28);display:flex;align-items:center;' +
      'justify-content:center;transform:translateY(-56px);opacity:0;' +
      'will-change:transform;pointer-events:none');
    el.innerHTML =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" ' +
      'stroke="#749c6f" stroke-width="2.6" stroke-linecap="round">' +
      '<path d="M19.5 12a7.5 7.5 0 1 1-2.4-5.5"/>' +
      '<path d="M17.5 2.5v4.4h-4.4" stroke-width="2.4"/></svg>';
    (document.body || document.documentElement).appendChild(el);
    return el;
  }

  function setPull(t) {
    var d = indicator();
    var y = Math.min(t, MAX) - 56;
    d.style.transition = 'none';
    d.style.opacity = Math.min(t / 40, 1);
    d.style.transform = 'translateY(' + y + 'px) rotate(' + (t * 2.2) + 'deg)';
  }

  function spin() {
    var d = indicator();
    d.style.transition = 'transform .15s ease-out';
    d.style.transform = 'translateY(24px)';
    d.firstChild.style.animation = '__ksPtrSpin .8s linear infinite';
  }

  function retract() {
    if (!el) return;
    var d = el;
    el = null;
    d.style.transition = 'transform .18s ease-in, opacity .18s';
    d.style.transform = 'translateY(-56px)';
    d.style.opacity = '0';
    setTimeout(function () { if (d.parentNode) d.parentNode.removeChild(d); }, 220);
  }

  function disarm() {
    armY = null;
    travel = 0;
    retract();
  }

  addEventListener('touchstart', function (e) {
    fired = false;
    travel = 0;
    tracking = e.touches.length === 1;
    if (!tracking) return;
    x0 = e.touches[0].clientX;
    armY = pathAtTop(e) ? e.touches[0].clientY : null;
  }, { passive: true, capture: true });

  addEventListener('touchmove', function (e) {
    if (!tracking || fired) return;
    if (e.touches.length !== 1) { tracking = false; disarm(); return; }
    var t = e.touches[0];
    var top = pathAtTop(e);
    if (armY === null) {
      // Not at the top when the finger landed; arm the moment we get there.
      if (top) armY = t.clientY;
      return;
    }
    if (!top) { disarm(); return; }
    var dy = t.clientY - armY;
    var dx = Math.abs(t.clientX - x0);
    if (dy <= 0 || (dx > 48 && dx > dy)) { travel = 0; retract(); return; }
    travel = dy * 0.5;
    setPull(travel);
  }, { passive: true, capture: true });

  addEventListener('touchend', function () {
    if (!tracking) return;
    tracking = false;
    if (armY !== null && !fired && travel >= THRESHOLD) {
      fired = true;
      spin();
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('ksPullToRefresh');
      } else {
        retract();
      }
    } else {
      retract();
    }
  }, { passive: true, capture: true });

  addEventListener('touchcancel', function () {
    tracking = false;
    disarm();
  }, { passive: true, capture: true });
})();
''';
