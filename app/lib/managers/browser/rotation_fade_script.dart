import 'dart:convert';

/// Crossfade for the dashboard view rotation (issue #189): one rotation
/// step dissolves the current view into the next instead of cutting.
///
/// There is only one WebView, so nothing outside the page can blend two
/// dashboards - but inside the page two views of the SAME dashboard can
/// coexist, exactly the trick the swipe carousel already rides: hui-root
/// keeps every view element it has built in `_viewCache`, and a cached
/// element can be mounted in a wrapper next to (here: on top of) the live
/// view. Two paths, mirroring the carousel's seamless/blind split:
///
/// - Seamless: the target view has a detached cached element. It gets a
///   fresh `hass` (a synchronous re-render, paid while still invisible),
///   is mounted centered over the live view in an absolutely positioned
///   wrapper at opacity ~0 - above Chromium's effectively-invisible
///   cutoff so the mount rasters NOW, not mid-fade (the carousel's PARKED
///   lesson) - then fades to 1 on the compositor (opacity only, the
///   reactive-bar rule). Only then does the soft navigation fire, and
///   HA's own swap appendChild()s that same element, MOVING it out of the
///   wrapper into the container. The MutationObserver callback is a
///   microtask, before the next paint: dropping the wrapper there is
///   atomic with the swap, so the handoff shows no seam. The swap
///   signature is exact (the borrowed element being appended) so
///   background mutations cannot end the wait early; scroll is reset in
///   the same microtask because the wrapper was viewport-aligned while
///   the swapped-in view lands at the container's flow top.
///
/// - Fade-through: the element is cached but connected (the carousel's
///   preview strip holds it - stealing from a live strip corrupts its
///   bookkeeping mid-gesture, so it is left alone). The container fades
///   out, the navigation fires with a childList observer already
///   listening (the swap must not land before anyone waits for it), and
///   the new view fades back in once swapped - with a timeout so an
///   unseen swap can never wedge the dashboard invisible. Only ever for
///   BUILT views, where the swap is an instant append: a first visit has
///   no cached element and cuts ('plain') instead, because fading out
///   ahead of a first build left an Echo Show's screen dark for the
///   seconds the view took to construct - a hard cut beats a black hole.
///
/// Everything is timed with setTimeout, never requestAnimationFrame: a
/// covered dashboard stops compositing (rendering freeze, overlay pages)
/// and rAF stalls with it - the choreography must reach the navigation
/// even when nobody can see it, or rotation silently stops advancing.
///
/// Anything the fade cannot handle returns 'plain' and the caller runs
/// the instant navigation instead: a different dashboard (the panel swap
/// destroys the container mid-fade), a bare or unknown route, a missing
/// hui-root, a transition already in flight. LOAD-BEARING, from the
/// carousel: the wrapper is never the container's last child - hui-root's
/// _selectView removes lastChild as "the current view" on every swap, and
/// a wrapper sitting there gets removed in the view's place.
///
/// The whole script is evaluated per rotation step with its arguments
/// baked in (like navigateToViewPath's own JS) rather than injected as a
/// persistent user script: nothing global to keep in sync with the
/// toggle, and non-HA pages never carry it. It returns synchronously -
/// 'fade' when the choreography started (the caller is done), 'plain'
/// when the instant path should run - while the fade itself continues
/// async, guarded against overlap by a self-expiring busy stamp. The
/// stamp's ceiling is deliberately fat (6s against a sub-second fade):
/// on a janked main thread the choreography's timers starve, and a stamp
/// sized to the nominal duration expired mid-flight - the next tick then
/// started a second fade over the first and the two interleaved into
/// out-of-order navigations (observed live on an Echo Show 8). Ticks
/// that land inside the window cut instead, which is always safe.
String rotationCrossfadeJs({required String base, required String viewPath}) {
  return '''
(function () {
  var base = ${jsonEncode(base)};
  var viewPath = ${jsonEncode(viewPath)};
  var FADE_MS = 400;    // seamless dissolve
  var OUT_MS = 200;     // fade-through, outgoing leg
  var IN_MS = 260;      // fade-through, incoming leg
  try {
    if (!location.href.startsWith(base)) return 'plain';
    var path = '/' + viewPath;
    if (location.pathname === path ||
        location.pathname.indexOf(path + '/') === 0) {
      return 'plain'; // "already there": let the instant path answer it
    }
    if (window.__ksRotFadeBusy && window.__ksRotFadeBusy > Date.now()) {
      return 'plain';
    }
    var parts = viewPath.split('/');
    var urlPath = parts[0] || '';
    // Bare dashboard paths (strategy dashboards rotated as a whole) have
    // no view route to resolve; they are hard loads or cuts anyway.
    if (!urlPath || parts.length < 2) return 'plain';
    var route = decodeURIComponent(parts.slice(1).join('/'));
    if ((location.pathname.split('/')[1] || '') !== urlPath) {
      return 'plain'; // different dashboard: the panel itself swaps
    }
    var ha = document.querySelector('home-assistant');
    var main = ha && ha.shadowRoot &&
      ha.shadowRoot.querySelector('home-assistant-main');
    var panel = main && main.shadowRoot &&
      main.shadowRoot.querySelector('ha-panel-lovelace');
    var hr = panel && panel.shadowRoot &&
      panel.shadowRoot.querySelector('hui-root');
    if (!hr || !hr.getClientRects().length) return 'plain';
    var container = hr.shadowRoot &&
      (hr.shadowRoot.querySelector('hui-view-container') ||
       hr.shadowRoot.querySelector('#view'));
    if (!container) return 'plain';
    var cfg = hr.lovelace && hr.lovelace.config;
    var views = cfg && cfg.views;
    if (!views || !views.length) return 'plain';
    var idx = -1;
    for (var i = 0; i < views.length; i++) {
      var v = views[i] || {};
      var key = v.path != null && v.path !== '' ? String(v.path) : String(i);
      if (key === route || String(i) === route) { idx = i; break; }
    }
    if (idx === -1) return 'plain';

    var navigate = function () {
      history.pushState(null, '', path);
      window.dispatchEvent(new CustomEvent('location-changed'));
    };
    var busy = function (ms) { window.__ksRotFadeBusy = Date.now() + ms; };
    var idle = function () { window.__ksRotFadeBusy = 0; };

    var cached = null;
    try { cached = hr._viewCache && hr._viewCache[idx]; } catch (_) {}
    // First visit: nothing rendered exists to fade to, and fading out
    // ahead of the build holds a slow device's screen dark for however
    // long the view takes to construct. Cut; the visit fills the cache.
    if (!cached) return 'plain';

    // ── Seamless: dissolve the cached target view in over the live one ──
    if (!cached.isConnected) {
      busy(FADE_MS + 6000);
      // Fresh states before showing: assigning hass re-renders the view
      // synchronously, which is fine while it is still invisible.
      try { if (hr.hass) cached.hass = hr.hass; } catch (_) {}
      var undoPos = false;
      if (getComputedStyle(container).position === 'static') {
        container.style.position = 'relative';
        undoPos = true;
      }
      // Align with what the eye sees on a scrolled page. gBCR comes back
      // in zoom-multiplied pixels under the CSS zoom this app itself sets
      // (the #147 lesson), so divide it back out.
      var scrolled = false;
      var top = 0;
      if (container.scrollTop > 0) {
        top = container.scrollTop;
        scrolled = true;
      } else {
        var r = container.getBoundingClientRect();
        if (r.top < 0) {
          var z = parseFloat(document.documentElement.style.zoom) || 1;
          top = -r.top / z;
          scrolled = true;
        }
      }
      // z-index makes the stacking explicit: whether hui-view is itself
      // positioned varies by HA version and view type, and the incoming
      // view must cover the outgoing one deterministically. Huge, but it
      // only competes inside the container - dialogs live on the body.
      var wrap = document.createElement('div');
      wrap.style.cssText =
        'position:absolute;left:0;top:' + top + 'px;' +
        'width:100%;height:100%;overflow:hidden;pointer-events:none;' +
        'will-change:opacity;opacity:0.02;z-index:2147480000;';
      wrap.appendChild(cached);
      // NEVER as the last child: _selectView removes lastChild as "the
      // current view" on every swap (the carousel lesson).
      container.insertBefore(wrap, container.lastChild);
      var cleanup = function () {
        try {
          if (cached.parentNode === wrap) wrap.removeChild(cached);
          wrap.remove();
        } catch (_) {}
        if (undoPos) container.style.position = '';
        idle();
      };
      setTimeout(function () { // mount rasters while imperceptible
        wrap.style.transition = 'opacity ' + FADE_MS + 'ms ease-in-out';
        wrap.style.opacity = '1';
        setTimeout(function () {
          var mo = null, done = false;
          var finish = function (recs) {
            if (done) return;
            if (recs) {
              var real = false;
              for (var i = 0; i < recs.length && !real; i++) {
                var added = recs[i].addedNodes;
                for (var j = 0; j < added.length; j++) {
                  if (added[j] === cached) { real = true; break; }
                }
              }
              if (!real) return;
            }
            done = true;
            if (mo) mo.disconnect();
            // The wrapper was viewport-aligned; the swapped-in view sits
            // at the container's flow top. Same microtask as the wrapper
            // drop, so the correction paints with the swap.
            if (recs && scrolled) {
              try {
                container.scrollTop = 0;
                var d = document.scrollingElement ||
                  document.documentElement;
                if (d.scrollTop) d.scrollTop = 0;
              } catch (_) {}
            }
            cleanup();
          };
          try {
            mo = new MutationObserver(finish);
            mo.observe(container, { childList: true });
          } catch (_) {}
          // An unseen swap (same-view nav, an error mid-swap) must not
          // leave the borrowed element wedged in the wrapper.
          setTimeout(function () { finish(null); }, 800);
          navigate();
        }, FADE_MS + 30);
      }, 80);
      return 'fade';
    }

    // ── Fade-through: built view, but the carousel strip holds it ───────
    busy(6000);
    var s = container.style;
    s.willChange = 'opacity';
    s.transition = 'opacity ' + OUT_MS + 'ms ease-in';
    s.opacity = '0';
    setTimeout(function () {
      var mo = null, done = false;
      var finish = function () {
        if (done) return;
        done = true;
        if (mo) mo.disconnect();
        setTimeout(function () { // let the swapped view paint dark first
          s.transition = 'opacity ' + IN_MS + 'ms ease-out';
          s.opacity = '1';
          setTimeout(function () {
            s.transition = '';
            s.willChange = '';
            s.opacity = '';
            idle();
          }, IN_MS + 60);
        }, 50);
      };
      try {
        mo = new MutationObserver(finish);
        mo.observe(container, { childList: true });
      } catch (_) {}
      // The swap may never come: never wedge the dashboard dark.
      setTimeout(finish, 700);
      navigate();
    }, OUT_MS + 20);
    return 'fade';
  } catch (_) { return 'plain'; }
})();
''';
}
