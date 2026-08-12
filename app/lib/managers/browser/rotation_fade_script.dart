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
/// - Seamless: the target view has a detached cached element - or none
///   at all, in which case one is built the way hui-root's _selectView
///   builds them (a hui-view with index/lovelace/narrow/hass) and given
///   1.5s to construct its cards invisibly, the current view fully
///   visible the whole time; it is adopted into `_viewCache` only after
///   proving it rendered, so a dud can never become a permanently blank
///   view HA reuses forever, and an unrendered build degrades to the
///   plain cut. Either way the element gets current `hass` (a
///   synchronous re-render, paid while still invisible), is mounted
///   centered over the live view in an absolutely positioned wrapper at
///   opacity ~0 - above Chromium's effectively-invisible cutoff so the
///   mount rasters NOW, not mid-fade (the carousel's PARKED lesson) -
///   then fades to 1 on the compositor (opacity only, the reactive-bar
///   rule). The outgoing view fades DOWN beneath it on a slight stagger:
///   wherever the incoming view is transparent (card gaps, transparent
///   card backgrounds) the old content would otherwise hold at full
///   opacity and blink out at the swap; the stagger keeps the shared
///   background from bleeding through regions where both views are
///   opaque. Both elements outlive the fade in `_viewCache`, so every
///   exit path scrubs the inline fade styles - a leftover opacity:0
///   comes back as an invisible view on a later pass. Only after both
///   fades does the soft navigation fire, and
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
///   BUILT views, where the swap is an instant append. Fading out ahead
///   of a first-visit build was tried and left an Echo Show's screen
///   dark for the seconds the view took to construct - which is why
///   first visits build invisibly under the seamless path instead.
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
  var OLD_DELAY = 150;  // stagger before the outgoing view fades under it
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
    // First visit: no cached element exists, so build one the way
    // hui-root's _selectView does and let it construct INVISIBLY over the
    // fully visible current view (fading out ahead of the build instead
    // held a slow device's screen dark for the whole construction). It
    // only enters hui-root's cache at fade time, after proving it
    // actually rendered - seeding a dud would hand HA a permanently
    // blank view to reuse forever.
    var warm = false;
    if (!cached) {
      if (!hr._viewCache) return 'plain';
      try {
        cached = document.createElement('hui-view');
        cached.index = idx;
        cached.lovelace = hr.lovelace;
        cached.narrow = hr.narrow;
        cached.hass = hr.hass;
        warm = true;
      } catch (_) { return 'plain'; }
    }

    // ── Seamless: dissolve the cached target view in over the live one ──
    if (!cached.isConnected) {
      // A freshly built view needs real time to construct its cards
      // before it is worth looking at; a cached one only needs its mount
      // rastered.
      var settleMs = warm ? 1500 : 80;
      busy(settleMs + FADE_MS + 6000);
      // Fresh states before showing: assigning hass re-renders the view
      // synchronously, which is fine while it is still invisible. A
      // warm-built view was created with current hass moments ago.
      try { if (!warm && hr.hass) cached.hass = hr.hass; } catch (_) {}
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
      // A previous fade-out may have left inline opacity on this cached
      // element (it lives on in _viewCache between passes); mounting it
      // invisible would show background where the view belongs.
      try {
        cached.style.opacity = '';
        cached.style.transition = '';
      } catch (_) {}
      wrap.appendChild(cached);
      // The outgoing view, faded DOWN while the incoming one fades up:
      // wherever the incoming view is transparent (card gaps, cards with
      // transparent backgrounds) the old content would otherwise sit at
      // full opacity behind it until the swap yanked it - a visible
      // blink. Captured before the wrapper goes in, while the view is
      // still the last element.
      var old = container.lastElementChild;
      if (!old || old === cached || !old.style) old = null;
      // NEVER as the last child: _selectView removes lastChild as "the
      // current view" on every swap (the carousel lesson).
      container.insertBefore(wrap, container.lastChild);
      // The old element ALSO lives on in _viewCache after the swap: any
      // inline fade style must be scrubbed on every exit path, or the
      // view comes back invisible when the rotation returns to it.
      var restoreOld = function () {
        if (!old) return;
        try {
          old.style.transition = '';
          old.style.opacity = '';
          old.style.willChange = '';
        } catch (_) {}
      };
      var cleanup = function () {
        try {
          if (cached.parentNode === wrap) wrap.removeChild(cached);
          wrap.remove();
        } catch (_) {}
        restoreOld();
        if (undoPos) container.style.position = '';
        idle();
      };
      setTimeout(function () { // construct/raster while imperceptible
        if (warm) {
          // The build had its settle time; a view that produced no DOM
          // (an unknown layout, an old frontend) must neither be shown
          // nor cached. Cut instead - exactly what a plain tick does.
          var rendered = false;
          try {
            rendered = cached.childElementCount > 0 ||
              (cached.shadowRoot && cached.shadowRoot.childElementCount > 0);
          } catch (_) {}
          if (!rendered) { cleanup(); navigate(); return; }
          // Adopt it into hui-root's cache so HA's own swap reuses THIS
          // element - the seamless handoff depends on the swap appending
          // the very element the wrapper holds.
          try { hr._viewCache[idx] = cached; } catch (_) {
            cleanup(); navigate(); return;
          }
        }
        wrap.style.transition = 'opacity ' + FADE_MS + 'ms ease-in-out';
        wrap.style.opacity = '1';
        // Slightly staggered so the incoming view is mostly opaque before
        // the outgoing one thins: fading both at full overlap lets the
        // shared background bleed through regions where both are opaque.
        if (old) {
          old.style.willChange = 'opacity';
          old.style.transition =
            'opacity ' + FADE_MS + 'ms ease-in-out ' + OLD_DELAY + 'ms';
          old.style.opacity = '0';
        }
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
        }, FADE_MS + OLD_DELAY + 50);
      }, settleMs);
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
