/// Dashboard carousel: swipe left or right anywhere on a lovelace view to
/// move to the neighboring view, so a small screen can drop the header
/// tabs (HA kiosk mode) without losing navigation.
///
/// Everything happens inside the page. There is only one WebView, so the
/// animation cannot slide two live views past each other; instead the view
/// container inside hui-root moves. The gesture follows the finger: once a
/// touch proves itself horizontal (20px travel, twice the vertical drift),
/// the current view tracks the finger 1:1 (transform set per frame,
/// rAF-throttled). Releasing past the commit distance — or flicking —
/// carries the view out from wherever the finger left it; releasing short
/// springs it back. Transform and opacity only, so the whole thing stays
/// on the compositor (the reactive-bar lesson: never animate anything that
/// re-rasterizes).
///
/// The swap is NOT synchronous with the navigation: HA processes
/// location-changed on its own schedule and only then detaches the old
/// view element and attaches the new one. Sliding in right after nav()
/// would animate the OLD content for its first beats (it did, first
/// attempt). So after the carry-out the container parks offscreen and
/// invisible until a childList mutation says the new view is really in the
/// tree (with a timeout so a swap this cannot see never wedges the
/// dashboard invisible), then slides in — a short blank beat instead of
/// the wrong view.
///
/// Navigation is the same soft SPA path the view rotation uses
/// (pushState + location-changed), read against the view list the loaded
/// frontend itself holds (hui-root.lovelace.config.views) — no websocket
/// round trip, and strategy dashboards whose views the frontend generated
/// client-side just work. Views marked subview or visible:false are
/// skipped; fewer than two eligible views leaves the script inert.
///
/// Touch listeners mirror the pull-to-refresh probe: capture-phase and
/// passive, so the page can neither swallow them nor be slowed by them.
/// Passive also means the page may still scroll a little vertically while
/// a drag is live — accepted; active listeners would let this script jank
/// HA's own scrolling. A gesture starting on an open dialog, an
/// interactive control (sliders above all) or an element that scrolls
/// horizontally itself is never claimed — those keep their own gestures.
///
/// Gated by `window.__ksCarouselEnabled`, seeded at document start,
/// re-asserted on every load and updated live on toggle, so the setting
/// needs no reload — the same contract as `__ksPtrEnabled`.
const dashboardCarouselScript = '''
(function () {
  if (window.__ksCarousel) return;
  window.__ksCarousel = true;

  var LOCK_DX = 20;    // travel that locks a touch as a horizontal drag
  var COMMIT_DX = 70;  // release offset that commits the view change
  var FLICK_DX = 60;   // travel for the no-drag fast-flick fallback
  var RATIO = 2;       // how decisively horizontal the gesture must be
  var FLICK_V = 0.5;   // px/ms: a fast release commits below COMMIT_DX

  var start = null;    // {x, y} candidate touch, null once rejected
  var drag = null;     // live follow: {hr, container, x0, dx, vx, px, pt, raf}
  var animating = false;

  function huiRoot() {
    try {
      var ha = document.querySelector('home-assistant');
      var main = ha && ha.shadowRoot &&
        ha.shadowRoot.querySelector('home-assistant-main');
      var panel = main && main.shadowRoot &&
        main.shadowRoot.querySelector('ha-panel-lovelace');
      return panel && panel.shadowRoot &&
        panel.shadowRoot.querySelector('hui-root');
    } catch (_) { return null; }
  }

  // Elements whose own gesture must win over the carousel. Name fragments
  // rather than an exact list: HA and custom cards ship endless slider and
  // dialog variants, and a missed one here means a light dims while the
  // view flies away.
  var BLOCK = /^(input|textarea|select|button|a|video|audio|canvas|iframe)\$/;
  function blockedPath(e) {
    var path = e.composedPath ? e.composedPath() : [];
    for (var i = 0; i < path.length; i++) {
      var n = path[i];
      if (!(n instanceof Element)) continue;
      var name = n.localName || '';
      if (BLOCK.test(name) ||
          name.indexOf('slider') !== -1 ||
          name.indexOf('dialog') !== -1 ||
          name.indexOf('-map') !== -1 ||
          name.indexOf('swipe') !== -1) {
        return true;
      }
      // A card that scrolls sideways on its own (a horizontal stack, a
      // table) keeps its scroll gesture.
      if (n.scrollWidth > n.clientWidth + 8) {
        var ox = getComputedStyle(n).overflowX;
        if (ox === 'auto' || ox === 'scroll') return true;
      }
    }
    return false;
  }

  function viewContainer(hr) {
    return hr.shadowRoot &&
      (hr.shadowRoot.querySelector('hui-view-container') ||
       hr.shadowRoot.querySelector('#view'));
  }

  // Eligible views and where the current route sits among them, or null
  // when the carousel has nothing to do here (single view, off-dashboard).
  function routeInfo(hr) {
    var cfg = hr.lovelace && hr.lovelace.config;
    var views = cfg && cfg.views;
    if (!views || views.length < 2) return null;
    var eligible = [];
    for (var i = 0; i < views.length; i++) {
      var v = views[i] || {};
      if (v.subview === true || v.visible === false) continue;
      // A view is addressable by its path or its index; keep both so the
      // current route matches whichever form got it here.
      eligible.push({
        key: v.path != null && v.path !== '' ? String(v.path) : String(i),
        alt: String(i),
      });
    }
    if (eligible.length < 2) return null;
    var parts = location.pathname.split('/');
    var urlPath = parts[1] || '';
    if (!urlPath) return null;
    var route = decodeURIComponent(parts[2] || '');
    var cur = 0;
    for (var j = 0; j < eligible.length; j++) {
      if (eligible[j].key === route || eligible[j].alt === route) {
        cur = j;
        break;
      }
    }
    return { eligible: eligible, cur: cur, urlPath: urlPath };
  }

  function clearStyles(s) {
    s.transition = '';
    s.willChange = '';
    s.transform = '';
    s.opacity = '';
  }

  function navigate(urlPath, key) {
    history.pushState(null, '',
      '/' + urlPath + '/' + encodeURIComponent(key));
    window.dispatchEvent(new CustomEvent('location-changed'));
  }

  // Phase 2: park offscreen invisible, wait for HA to really swap the
  // view (childList on the container), then slide the new one in.
  function revealAfterSwap(container, dir) {
    var s = container.style;
    s.transition = 'none';
    s.transform = 'translateX(' + (dir * 24) + '%)';
    var mo = null;
    var done = false;
    var finish = function () {
      if (done) return;
      done = true;
      if (mo) mo.disconnect();
      // Two frames so the swapped view commits a paint at the parked
      // position; transitioning in the same frame flashes it centered.
      requestAnimationFrame(function () {
        requestAnimationFrame(function () {
          s.transition = 'transform 150ms ease-out, opacity 150ms ease-out';
          s.transform = '';
          s.opacity = '1';
          setTimeout(function () {
            clearStyles(s);
            animating = false;
          }, 180);
        });
      });
    };
    try {
      mo = new MutationObserver(finish);
      mo.observe(container, { childList: true });
    } catch (_) {}
    setTimeout(finish, 500);
  }

  // Carry the view out from wherever the finger left it, then swap.
  // dir: +1 = next view (content moves left), -1 = previous.
  function commit(d, dir) {
    var info = routeInfo(d.hr);
    if (!info) { snapBack(d); return; }
    var next =
      info.eligible[(info.cur + dir + info.eligible.length) %
        info.eligible.length];
    if (!d.container) { navigate(info.urlPath, next.key); return; }
    animating = true;
    var s = d.container.style;
    var w = Math.max(d.container.clientWidth || window.innerWidth, 1);
    // Never move backwards: a finger already past the resting exit point
    // keeps its position and only fades.
    var target = dir > 0
      ? Math.min(d.dx || 0, -0.24 * w)
      : Math.max(d.dx || 0, 0.24 * w);
    s.willChange = 'transform, opacity';
    s.transition = 'transform 100ms ease-in, opacity 100ms ease-in';
    s.transform = 'translateX(' + target + 'px)';
    s.opacity = '0';
    setTimeout(function () {
      // Observer first, navigation second: the swap must not be able to
      // land before anyone is listening for it.
      revealAfterSwap(d.container, dir);
      navigate(info.urlPath, next.key);
    }, 110);
  }

  function snapBack(d) {
    if (!d.container) return;
    var s = d.container.style;
    s.transition = 'transform 150ms ease-out';
    s.transform = '';
    setTimeout(function () { clearStyles(s); }, 170);
  }

  addEventListener('touchstart', function (e) {
    start = null;
    if (window.__ksCarouselEnabled === false || animating || drag) return;
    if (e.touches.length !== 1) return;
    if (blockedPath(e)) return;
    start = { x: e.touches[0].clientX, y: e.touches[0].clientY };
  }, { passive: true, capture: true });

  addEventListener('touchmove', function (e) {
    if (e.touches.length !== 1) { // a pinch, not a swipe
      if (drag) {
        if (drag.raf) cancelAnimationFrame(drag.raf);
        snapBack(drag);
        drag = null;
      }
      start = null;
      return;
    }
    var t = e.touches[0];
    if (!drag) {
      if (!start) return;
      var dx = t.clientX - start.x;
      var dy = t.clientY - start.y;
      if (Math.abs(dx) < LOCK_DX || Math.abs(dx) < RATIO * Math.abs(dy)) {
        return;
      }
      var hr = huiRoot();
      // The panel resolver caches panels: a lovelace root can answer the
      // query while a settings page is on screen. No client rects =
      // hidden = not the page being swiped.
      if (!hr || !hr.getClientRects().length || !routeInfo(hr)) {
        start = null;
        return;
      }
      var container = viewContainer(hr);
      if (!container) { start = null; return; }
      container.style.willChange = 'transform';
      container.style.transition = 'none';
      // Offsets measure from the lock point, so the view starts moving
      // from rest instead of jumping by the lock distance.
      drag = {
        hr: hr, container: container,
        x0: t.clientX, dx: 0, vx: 0, px: t.clientX, pt: e.timeStamp, raf: 0,
      };
      start = null;
    }
    var dt = e.timeStamp - drag.pt;
    if (dt > 0) {
      var inst = (t.clientX - drag.px) / dt;
      drag.vx = 0.7 * drag.vx + 0.3 * inst;
      drag.px = t.clientX;
      drag.pt = e.timeStamp;
    }
    drag.dx = t.clientX - drag.x0;
    if (!drag.raf) {
      drag.raf = requestAnimationFrame(function () {
        if (!drag) return;
        drag.raf = 0;
        drag.container.style.transform =
          'translateX(' + drag.dx + 'px)';
      });
    }
  }, { passive: true, capture: true });

  addEventListener('touchend', function (e) {
    var st = start;
    start = null;
    var d = drag;
    drag = null;
    if (d && d.raf) cancelAnimationFrame(d.raf);
    if (window.__ksCarouselEnabled === false) {
      if (d) snapBack(d);
      return;
    }
    if (d) {
      var flick = Math.abs(d.vx) > FLICK_V &&
        d.vx * d.dx > 0 && Math.abs(d.dx) > LOCK_DX;
      if (Math.abs(d.dx) >= COMMIT_DX || flick) {
        commit(d, d.dx < 0 ? 1 : -1);
      } else {
        snapBack(d);
      }
      return;
    }
    // Flick so fast no touchmove ever locked the drag: the pre-follow
    // detection, kept as a fallback.
    if (!st || animating) return;
    var t = e.changedTouches && e.changedTouches[0];
    if (!t) return;
    var dx = t.clientX - st.x;
    var dy = t.clientY - st.y;
    if (Math.abs(dx) < FLICK_DX || Math.abs(dx) < RATIO * Math.abs(dy)) {
      return;
    }
    var hr = huiRoot();
    if (!hr || !hr.getClientRects().length) return;
    commit({ hr: hr, container: viewContainer(hr), dx: dx },
      dx < 0 ? 1 : -1);
  }, { passive: true, capture: true });

  // The native side claiming the gesture (the drawer's edge swipe, a
  // Flutter overlay) cancels the page's stream; spring back and forget.
  addEventListener('touchcancel', function () {
    start = null;
    if (drag) {
      if (drag.raf) cancelAnimationFrame(drag.raf);
      snapBack(drag);
      drag = null;
    }
  }, { passive: true, capture: true });
})();
''';
