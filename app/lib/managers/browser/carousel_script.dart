/// Dashboard carousel: swipe left or right anywhere on a lovelace view to
/// move to the neighboring view, so a small screen can drop the header
/// tabs (HA kiosk mode) without losing navigation.
///
/// Everything happens inside the page. There is only one WebView, so the
/// animation cannot slide two live WebViews past each other; instead the
/// view container inside hui-root moves. The gesture follows the finger:
/// once a touch proves itself horizontal (20px travel, twice the vertical
/// drift), the current view tracks the finger via a continuous rAF loop
/// easing toward the latest touch position — touch events arrive slower
/// and less regularly than the display refreshes (they ride the
/// embedder's platform-view dispatch), so setting the transform per event
/// makes a fast finger leap 20-40px per step while a slow one glides.
/// Releasing past the commit distance — or flicking — carries the view
/// out from wherever the finger left it; releasing short springs it back.
/// Transform and opacity only, so the whole thing stays on the compositor
/// (the reactive-bar lesson: never animate anything that re-rasterizes).
///
/// The neighbor previews are built AT IDLE, never during the gesture.
/// hui-root keeps the view elements it has already built (`_viewCache`,
/// why revisiting a view is instant); ~400ms after every navigation
/// settles, the neighbors with a cached element are mounted — hass
/// refreshed, that is idle time — in wrappers parked at +-100% INSIDE the
/// container, at near-zero opacity. Parked-but-painted matters twice:
/// mounting a whole dashboard view costs a style/layout/raster storm that
/// must not land inside a fast swipe (a slow swipe pays the same cost
/// while the finger barely moves, which is why only fast swipes ever
/// looked janky), and an unpainted layer rasters lazily as it is exposed,
/// so the revealed view pops in chunkily. Opacity ~0 keeps the layer
/// painted where visibility:hidden would discard it; the drag then only
/// flips opacity, which costs nothing. A neighbor without a pre-built
/// wrapper (first visit, rebuild raced the gesture) is built on demand at
/// drag lock — the old, jankier path, but only ever once per route.
///
/// On commit the strip carries on until the neighbor sits centered, the
/// soft navigation fires, and HA's own swap appendChild()s that same
/// cached element — DOM elements live in one place, so it MOVES out of
/// the wrapper into the container. The MutationObserver callback is a
/// microtask, i.e. it runs before the next paint: resetting the transform
/// there is atomic with the swap and the handoff shows no seam. The swap
/// signature is exact (the borrowed element being appended), so the
/// observer cannot be fooled by background re-appends or wrapper
/// bookkeeping. LOAD-BEARING: hui-root's _selectView removes the
/// container's LAST CHILD as "the current view" on every swap, so a
/// wrapper must never sit last — it gets removed in the view's place and
/// the old view never leaves (two half-width views side by side). Every
/// wrapper is inserted before lastChild: after hui-view-background (so it
/// paints above it), never in the swap's line of fire. Anything
/// unexpected — no cache, a connected element, a thrown accessor —
/// degrades to the no-preview path, which parks the container offscreen
/// invisible until a childList mutation says the new view is really in
/// the tree (HA's swap is asynchronous to the navigation; sliding in
/// straight after nav() animates the OLD content), with a timeout so an
/// unseen swap never wedges the dashboard invisible.
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
/// Cost note: while the toggle is on, up to two already-visited views
/// stay mounted (invisible) between gestures, so their cards keep any
/// timers they run. That is the price of previews that move at full
/// frame rate on the first swipe; the feature is opt-in.
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
  // Parked wrapper opacity. Deliberately ABOVE Chromium's
  // effectively-invisible cutoff (~0.0026, below which the subtree is
  // not painted at all — parking at 0.002 silently discarded the
  // pre-paint and the reveal re-rastered mid-swipe, the exact storm the
  // strip exists to avoid). 2% is imperceptible but keeps the layer
  // painted and warm.
  var PARKED = '0.02';
  var SETTLE_MS = 400;     // navigation settle before (re)building the strip

  var start = null;    // {x, y} candidate touch, null once rejected
  var drag = null;     // live follow state, see touchmove
  var animating = false;

  // Pre-built neighbor previews: [{el, wrapper, side}]. Rebuilt at idle
  // after every navigation; consumed/repaired around commits.
  var strip = [];
  var undoPos = false; // container position was ours to set, restore it
  var settleTimer = null;

  // Diagnostics ring: per-event input latency (handler run minus event
  // timestamp) and follow-loop frame gaps, readable from the admin's
  // evalJs as window.__ksCarouselStats after a real-finger gesture —
  // synthetic adb swipes cannot reproduce real event pressure, so the
  // only honest smoothness data comes from instrumenting the user's own
  // swipe.
  var stats = { lat: [], fg: [] };
  window.__ksCarouselStats = stats;
  function push(a, v) {
    a.push(Math.round(v));
    if (a.length > 300) a.splice(0, a.length - 300);
  }

  function startFollowLoop(d) {
    var last = performance.now();
    (function step() {
      if (!d.alive) return;
      var now = performance.now();
      var dt = now - last;
      last = now;
      push(stats.fg, dt);
      var diff = d.target - d.shown;
      // Frame-time-adaptive easing: at fast frame rates this smooths the
      // event-to-frame rate mismatch; when frames stretch the factor
      // reaches 1 and the view tracks the finger directly — fixed-factor
      // easing at a low frame rate compounds into visible lag.
      var k = Math.min(1, (dt / 16) * 0.5);
      if (Math.abs(diff) < 0.5) { d.shown = d.target; }
      else { d.shown += diff * k; }
      d.container.style.transform = 'translateX(' + d.shown + 'px)';
      requestAnimationFrame(step);
    })();
  }

  function huiRoot() {
    try {
      var ha = document.querySelector('home-assistant');
      var main = ha && ha.shadowRoot &&
        ha.shadowRoot.querySelector('home-assistant-main');
      var panel = main && main.shadowRoot &&
        main.shadowRoot.querySelector('ha-panel-lovelace');
      huiRoot.panel = panel || null;
      return panel && panel.shadowRoot &&
        panel.shadowRoot.querySelector('hui-root');
    } catch (_) { return null; }
  }

  // Whether the lovelace panel is a cached, hidden one (a settings page
  // is on screen). Inline-style read only: this guard runs inside the
  // touch path, where a layout read (getClientRects, as an earlier
  // version used) pays a whole-document flush whenever HA's own periodic
  // renders left layout dirty — ~86ms mid-swipe, caught by profiling.
  function panelHidden() {
    var p = huiRoot.panel;
    return !!(p && p.style && p.style.display === 'none');
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
        index: i,
      });
    }
    if (eligible.length < 2) return null;
    var parts = location.pathname.split('/');
    var urlPath = parts[1] || '';
    if (!urlPath) return null;
    var route = decodeURIComponent(parts[2] || '');
    var cur = 0;
    for (var j = 0; j < eligible.length; j++) {
      if (eligible[j].key === route || String(eligible[j].index) === route) {
        cur = j;
        break;
      }
    }
    return { eligible: eligible, cur: cur, urlPath: urlPath };
  }

  function neighbor(info, dir) {
    return info.eligible[
      (info.cur + dir + info.eligible.length) % info.eligible.length];
  }

  function clearStyles(s) {
    s.transition = '';
    s.willChange = '';
    s.transform = '';
    s.opacity = '';
  }

  // Tell the app a drag/animation started or ended: the native side puts
  // the scrollbars to sleep for the duration — drift and the parked
  // preview's content extent awaken them over an animation that is not a
  // scroll. Idempotent both ways.
  function dragUi(active) {
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('ksCarouselDrag', !!active);
      }
    } catch (_) {}
  }

  // ── Page indicator dots ─────────────────────────────────────────────
  // Bottom-center pill showing the eligible views and where the cycle
  // stands, visible only around a swipe. Lives on document.body, NOT
  // inside the moving container: a transform creates a fixed-position
  // containing block, so a fixed element inside the container would ride
  // the strip. Everything here is write-only DOM (no reads, this runs on
  // the touch path) and fades on opacity alone.

  var dots = null;     // {host, items, n, cur}
  var dotsHide = null; // pending fade-out

  function ensureDots(n) {
    if (dots && dots.n === n) return dots;
    if (dots) {
      try { dots.host.remove(); } catch (_) {}
      dots = null;
    }
    var host = document.createElement('div');
    host.id = '__ksCarouselDots';
    host.style.cssText =
      'position:fixed;left:50%;' +
      'bottom:calc(18px + env(safe-area-inset-bottom, 0px));' +
      'transform:translateX(-50%);z-index:2147483647;display:flex;' +
      'gap:7px;align-items:center;padding:7px 11px;border-radius:999px;' +
      'background:rgba(0,0,0,.38);pointer-events:none;opacity:0;' +
      'transition:opacity .25s;will-change:opacity;';
    var items = [];
    for (var i = 0; i < n; i++) {
      var d = document.createElement('div');
      d.style.cssText =
        'width:7px;height:7px;border-radius:50%;' +
        'background:rgba(255,255,255,.45);' +
        'transition:background .15s, transform .15s;';
      host.appendChild(d);
      items.push(d);
    }
    (document.body || document.documentElement).appendChild(host);
    dots = { host: host, items: items, n: n, cur: -1 };
    return dots;
  }

  function showDots(n, cur) {
    if (n < 2) return;
    var dd = ensureDots(n);
    if (dd.cur !== cur) {
      var old = dd.items[dd.cur];
      if (old) {
        old.style.background = 'rgba(255,255,255,.45)';
        old.style.transform = '';
      }
      var active = dd.items[cur];
      if (active) {
        active.style.background = '#fff';
        active.style.transform = 'scale(1.35)';
      }
      dd.cur = cur;
    }
    clearTimeout(dotsHide);
    dd.host.style.opacity = '1';
  }

  function scheduleDotsHide() {
    clearTimeout(dotsHide);
    dotsHide = setTimeout(function () {
      if (dots) dots.host.style.opacity = '0';
    }, 900);
  }

  function dropDots() {
    clearTimeout(dotsHide);
    if (dots) {
      try { dots.host.remove(); } catch (_) {}
      dots = null;
    }
  }

  function navigate(urlPath, key) {
    history.pushState(null, '',
      '/' + urlPath + '/' + encodeURIComponent(key));
    window.dispatchEvent(new CustomEvent('location-changed'));
  }

  // ── The pre-built preview strip ─────────────────────────────────────

  // A cached view element is borrowable when it is parked: detached, or
  // already sitting in one of OUR wrappers.
  function borrowable(el) {
    if (!el.isConnected) return true;
    for (var i = 0; i < strip.length; i++) {
      if (strip[i].el === el) return true;
    }
    return false;
  }

  function entryFor(el) {
    for (var i = 0; i < strip.length; i++) {
      if (strip[i].el === el) return strip[i];
    }
    return null;
  }

  // A scrolled-down page: align the preview's top with what the eye
  // sees, not with the container's content top. gBCR comes back in
  // zoom-multiplied pixels under the CSS zoom this app itself sets
  // (the #147 lesson), so divide it back out.
  function computeTop(container) {
    if (container.scrollTop > 0) return container.scrollTop;
    var r = container.getBoundingClientRect();
    if (r.top < 0) {
      var z = parseFloat(document.documentElement.style.zoom) || 1;
      return -r.top / z;
    }
    return 0;
  }

  function makeWrapper(container) {
    var wrap = document.createElement('div');
    // Parked on the LEFT always, whichever side it will reveal on:
    // right-hanging content extends the document's reported horizontal
    // scroll range even under overflow-x:hidden, and Android awakens
    // BOTH scrollbars on every scroll whenever a range exists — so a
    // preview parked at left:100% made plain vertical scrolling flash a
    // horizontal bar. Left-hanging content adds no range (the same CSS
    // asymmetry behind the original stutter). The flip to the right
    // happens at drag lock: a write-only position change on the
    // wrapper's own layer, while the bars are already slept.
    //
    // will-change gives the wrapper its own compositor layer: painted
    // once while parked, so revealing is an opacity flip on the
    // compositor and sliding never repaints — without it the reveal
    // repaints the whole preview into the container's layer mid-swipe.
    wrap.style.cssText =
      'position:absolute;left:-100%;' +
      'top:' + computeTop(container) + 'px;width:100%;height:100%;' +
      'overflow:hidden;pointer-events:none;' +
      'will-change:transform,opacity;opacity:' + PARKED + ';';
    return wrap;
  }

  // Mount [el] as the preview on [side] of [container]. Reuses its
  // existing wrapper when it has one (re-siding is a position change on
  // an absolutely positioned box — no subtree relayout).
  function mountPreview(hr, container, el, side) {
    try {
      var entry = entryFor(el);
      if (entry) {
        // Write-only re-side; reads here run inside the touch path.
        if (entry.side !== side) {
          entry.wrapper.style.left = side > 0 ? '100%' : '-100%';
          entry.side = side;
        }
        return entry;
      }
      if (!borrowable(el)) return null;
      if (getComputedStyle(container).position === 'static' && !undoPos) {
        container.style.position = 'relative';
        undoPos = true;
      }
      var wrap = makeWrapper(container);
      wrap.appendChild(el);
      // NEVER as the last child: hui-root's _selectView removes
      // `lastChild` as "the current view" on every swap. A wrapper
      // sitting last gets removed in the view's place and the old view
      // never leaves — two half-width views side by side (observed on
      // .5). Before the last child the wrapper is safe from HA's swap
      // and still paints above hui-view-background, which comes first.
      container.insertBefore(wrap, container.lastChild);
      ensureClip();
      // Everything parks on side -1; the reveal re-sides via the reuse
      // branch above when the drag wants the right edge.
      entry = { el: el, wrapper: wrap, side: -1 };
      if (side !== -1) {
        wrap.style.left = '100%';
        entry.side = side;
      }
      strip.push(entry);
      return entry;
    } catch (_) { return null; }
  }

  // Tear one strip entry down, leaving the cached element exactly as
  // hui-root keeps it: detached, parented nowhere. A no-op on the element
  // when a commit already moved it into the container.
  function unmount(entry) {
    try {
      if (entry.el.parentNode === entry.wrapper) {
        entry.wrapper.removeChild(entry.el);
      }
      entry.wrapper.remove();
    } catch (_) {}
    var i = strip.indexOf(entry);
    if (i !== -1) strip.splice(i, 1);
  }

  function teardownStrip(container) {
    while (strip.length) unmount(strip[0]);
    dropClip();
    dropDots();
    if (undoPos && container) {
      container.style.position = '';
      undoPos = false;
    }
  }

  function parkStrip() {
    for (var i = 0; i < strip.length; i++) {
      var e = strip[i];
      e.wrapper.style.opacity = PARKED;
      // Back to the range-free left side (see makeWrapper).
      if (e.side !== -1) {
        e.wrapper.style.left = '-100%';
        e.side = -1;
      }
    }
  }

  // (Re)build the previews for the current route, at idle. The heavy part
  // — style, layout and first raster of up to two full views — happens
  // HERE, precisely so it cannot happen mid-gesture: a mount inside a
  // fast swipe stalls the main thread for its first frames, which is
  // invisible under a slow finger and pure jank under a fast one.
  var rebuildTries = 0;
  var lastTouch = 0;
  var scrollDirty = false;
  addEventListener('scroll', function () { scrollDirty = true; },
    { passive: true, capture: true });

  // THE direction-asymmetry bug: a wrapper parked at left:100% extends
  // the DOCUMENT's scrollable overflow to the right (content hanging off
  // the left edge never does — CSS's classic asymmetry), so the page
  // became horizontally scrollable (scrollWidth doubled, verified live)
  // and every next-direction swipe was a native compositor scroll
  // FIGHTING the carousel's transform — stutter no paint or layout fix
  // could touch, invisible to JS-driven sweeps because only real touch
  // scrolls. HA never scrolls the document horizontally, so clamp it
  // while previews exist; the preview only ever needs to be visible
  // inside the viewport.
  function ensureClip() {
    if (document.getElementById('__ksCarouselClip')) return;
    var st = document.createElement('style');
    st.id = '__ksCarouselClip';
    // overscroll-behavior-x: the container hanging past the right edge
    // mid-drag briefly creates a horizontal range, and a rightward
    // gesture then counts as overscroll-at-left-edge — Android 12+
    // answers with its stretch effect, visibly dragging the WHOLE
    // surface (fixed elements included) a few pixels with the finger.
    // Only ever in the prev direction: leftward-hanging content makes
    // no range. Vertical overscroll stays stock.
    st.textContent =
      'html { overflow-x: hidden !important; ' +
      'overscroll-behavior-x: none !important; }';
    (document.head || document.documentElement).appendChild(st);
    var d = document.scrollingElement || document.documentElement;
    if (d.scrollLeft) d.scrollLeft = 0;
  }

  function dropClip() {
    var st = document.getElementById('__ksCarouselClip');
    if (st) st.remove();
  }
  function rebuildStrip() {
    var hrForTeardown = huiRoot();
    var contForTeardown = hrForTeardown && viewContainer(hrForTeardown);
    if (window.__ksCarouselEnabled === false) {
      teardownStrip(contForTeardown);
      return;
    }
    if (drag || animating) { scheduleRebuild(); return; }
    // Mounting is main-thread-heavy; wait for the fingers to actually be
    // gone, or rapid back-and-forth swiping eats the stall mid-gesture.
    if (performance.now() - lastTouch < 800) { scheduleRebuild(); return; }
    var hr = hrForTeardown;
    if (!hr || !hr.getClientRects().length) {
      // A cold load takes a while to grow a hui-root; keep trying for a
      // bit so the first swipe already has its strip.
      if (++rebuildTries < 40) scheduleRebuild();
      return;
    }
    rebuildTries = 0;
    // Entries whose element was stolen (a rotation or manual navigation
    // made it the live view) leave an empty shell behind; purge first.
    for (var p = strip.length - 1; p >= 0; p--) {
      if (strip[p].el.parentNode !== strip[p].wrapper) unmount(strip[p]);
    }
    var container = viewContainer(hr);
    var info = container && routeInfo(hr);
    if (!info) { teardownStrip(container); return; }
    var cache;
    try { cache = hr._viewCache; } catch (_) { cache = null; }
    if (!cache) { teardownStrip(container); return; }
    var want = [];
    var sides = [1, -1];
    for (var i = 0; i < sides.length; i++) {
      var el = cache[neighbor(info, sides[i]).index];
      // With two eligible views both directions share one neighbor; the
      // single wrapper re-sides at drag lock instead.
      // Deliberately NO hass refresh here: assigning hass re-renders the
      // whole view synchronously, and "idle" is not idle when someone is
      // swiping back and forth — the refresh landed exactly under the
      // next test swipe. Parked previews show the states their cache
      // holds; HA re-sets hass on every commit append, so a landed view
      // is always fresh.
      if (el && borrowable(el) && want.indexOf(el) === -1) {
        want.push(el);
        mountPreview(hr, container, el, -1); // parked left, re-sided at lock
      }
    }
    if (strip.length) ensureClip(); else dropClip();
    // Drop entries for views that are no longer neighbors (route moved).
    for (var j = strip.length - 1; j >= 0; j--) {
      if (want.indexOf(strip[j].el) === -1) unmount(strip[j]);
    }
    // Re-align tops here, at idle — the one place layout reads are
    // allowed — and only after an actual scroll: computeTop reads
    // geometry, and paying that flush on every between-swipe rebuild is
    // what the profiler caught as a ~90ms injected setTimeout.
    if (scrollDirty && strip.length) {
      var top = computeTop(container) + 'px';
      for (var k = 0; k < strip.length; k++) {
        if (strip[k].wrapper.style.top !== top) {
          strip[k].wrapper.style.top = top;
        }
      }
      scrollDirty = false;
    }
  }

  function scheduleRebuild() {
    clearTimeout(settleTimer);
    settleTimer = setTimeout(rebuildStrip, SETTLE_MS);
  }

  window.addEventListener('location-changed', function () {
    rebuildTries = 0;
    scheduleRebuild();
  });
  // The toggle flips this live from the app side; a disable tears the
  // parked previews down instead of leaving them mounted until the next
  // navigation happens to rebuild.
  window.__ksCarouselSync = scheduleRebuild;
  scheduleRebuild(); // the initial build once the frontend settles

  // ── Commit paths ────────────────────────────────────────────────────

  // Fallback phase 2: park offscreen invisible, wait for HA to really
  // swap the view (childList on the container), then slide the new one
  // in.
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
            dragUi(false);
            scheduleDotsHide();
            scheduleRebuild();
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

  // With a live preview: carry the strip until the neighbor is centered,
  // navigate, and reset the transform inside the observer microtask —
  // before the browser paints the swapped DOM — so the handoff is
  // seamless.
  function commitSeamless(d, dir, info) {
    var next = neighbor(info, dir);
    var entry = d.preview;
    animating = true;
    var s = d.container.style;
    var w = Math.max(d.container.clientWidth || window.innerWidth, 1);
    s.willChange = 'transform';
    s.transition = 'transform 130ms ease-out';
    s.transform = 'translateX(' + (dir * -w) + 'px)';
    setTimeout(function () {
      var mo = null;
      var done = false;
      var finish = function (recs) {
        if (done) return;
        // Only HA's swap counts, and its signature is exact: it appends
        // THE element this preview borrowed (moving it out of the
        // wrapper). Background re-appends and our own wrapper
        // bookkeeping must not end the wait.
        if (recs) {
          var real = false;
          for (var i = 0; i < recs.length && !real; i++) {
            var added = recs[i].addedNodes;
            for (var j = 0; j < added.length; j++) {
              if (added[j] === entry.el) { real = true; break; }
            }
          }
          if (!real) return;
        }
        done = true;
        if (mo) mo.disconnect();
        s.transition = 'none';
        s.transform = '';
        unmount(entry); // its element now IS the view; drop the shell
        parkStrip();
        clearStyles(s);
        animating = false;
        dragUi(false);
        scheduleDotsHide();
        scheduleRebuild();
      };
      var fallback = function () {
        if (done) return;
        done = true;
        if (mo) mo.disconnect();
        // The swap never showed: degrade to park-and-reveal, which has
        // its own last-resort timeout and cannot wedge invisible.
        unmount(entry);
        parkStrip();
        s.opacity = '0';
        revealAfterSwap(d.container, dir);
      };
      try {
        mo = new MutationObserver(finish);
        mo.observe(d.container, { childList: true });
      } catch (_) {}
      setTimeout(fallback, 500);
      navigate(info.urlPath, next.key);
    }, 140);
  }

  // Without a preview: carry the view out from wherever the finger left
  // it, fade, then park-and-reveal.
  function commitBlind(d, dir, info) {
    var next = neighbor(info, dir);
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

  function commit(d, dir) {
    var info = routeInfo(d.hr);
    if (!info) { snapBack(d); return; }
    dragUi(true); // idempotent; covers the no-drag flick path too
    // The target dot lights up as the swap starts, so the indicator
    // lands with the view.
    showDots(info.eligible.length,
      (info.cur + dir + info.eligible.length) % info.eligible.length);
    if (d.preview && d.preview.side === dir &&
        d.preview.el.parentNode === d.preview.wrapper) {
      commitSeamless(d, dir, info);
    } else {
      commitBlind(d, dir, info);
    }
  }

  function snapBack(d) {
    if (!d.container) { dragUi(false); scheduleDotsHide(); return; }
    var s = d.container.style;
    s.transition = 'transform 150ms ease-out';
    s.transform = '';
    setTimeout(function () {
      parkStrip();
      clearStyles(s);
      dragUi(false);
      scheduleDotsHide();
    }, 170);
  }

  // The drag's preview for [dir]: the pre-built entry when the strip has
  // it (just an opacity flip — the fast path this whole strip exists
  // for), built on demand otherwise (first visit; pays the mount cost
  // mid-gesture, once).
  function previewFor(d, dir) {
    var info = routeInfo(d.hr);
    if (!info) return null;
    var cache;
    try { cache = d.hr._viewCache; } catch (_) { return null; }
    var el = cache && cache[neighbor(info, dir).index];
    if (!el) return null;
    var entry = mountPreview(d.hr, d.container, el, dir);
    // Opacity flip ONLY — no reads. An earlier version re-aligned the
    // preview's top here via getBoundingClientRect, and that single read
    // forced a whole-document layout flush (~85ms with the strip
    // mounted, caught live by long-animation-frame profiling) right at
    // the lock of every reveal-direction swipe. Alignment is computed at
    // idle build time instead; a page scrolled since then shows the
    // preview slightly offset until the next idle rebuild.
    if (entry) entry.wrapper.style.opacity = '';
    return entry;
  }

  // ── Gesture ─────────────────────────────────────────────────────────

  addEventListener('touchstart', function (e) {
    lastTouch = performance.now();
    start = null;
    if (window.__ksCarouselEnabled === false || animating || drag) return;
    if (e.touches.length !== 1) return;
    if (blockedPath(e)) return;
    start = { x: e.touches[0].clientX, y: e.touches[0].clientY };
  }, { passive: true, capture: true });

  addEventListener('touchmove', function (e) {
    if (e.touches.length !== 1) { // a pinch, not a swipe
      if (drag) {
        drag.alive = false;
        window.__ksCarouselDragging = false;
        snapBack(drag);
        drag = null;
      }
      start = null;
      return;
    }
    var t = e.touches[0];
    if (!drag) {
      if (!start) return;
      var dx0 = t.clientX - start.x;
      var dy0 = t.clientY - start.y;
      if (Math.abs(dx0) < LOCK_DX || Math.abs(dx0) < RATIO * Math.abs(dy0)) {
        return;
      }
      var hr = huiRoot();
      // The panel resolver caches panels: a lovelace root can answer the
      // query while a settings page is on screen.
      var lockInfo = hr && !panelHidden() ? routeInfo(hr) : null;
      if (!lockInfo) {
        start = null;
        return;
      }
      var container = viewContainer(hr);
      if (!container) { start = null; return; }
      window.__ksCarouselDragging = true; // the PTR probe stands down
      dragUi(true);
      showDots(lockInfo.eligible.length, lockInfo.cur);
      container.style.willChange = 'transform';
      container.style.transition = 'none';
      // Offsets measure from the lock point, so the view starts moving
      // from rest instead of jumping by the lock distance.
      drag = {
        hr: hr, container: container, preview: null, pvDir: 0,
        x0: t.clientX, dx: 0, vx: 0, px: t.clientX, pt: e.timeStamp,
        target: 0, shown: 0, alive: true,
      };
      startFollowLoop(drag);
      start = null;
    }
    lastTouch = performance.now();
    push(stats.lat, lastTouch - e.timeStamp);
    var dt = e.timeStamp - drag.pt;
    if (dt > 0) {
      var inst = (t.clientX - drag.px) / dt;
      drag.vx = 0.7 * drag.vx + 0.3 * inst;
      drag.px = t.clientX;
      drag.pt = e.timeStamp;
    }
    drag.dx = t.clientX - drag.x0;
    drag.target = drag.dx;
    // Reveal (or re-side) the neighbor preview for the direction the
    // finger is actually heading; a reversal swaps sides.
    var dir = drag.dx < 0 ? 1 : drag.dx > 0 ? -1 : 0;
    if (dir && dir !== drag.pvDir) {
      if (drag.preview) drag.preview.wrapper.style.opacity = PARKED;
      drag.preview = previewFor(drag, dir);
      drag.pvDir = dir;
    }
  }, { passive: true, capture: true });

  addEventListener('touchend', function (e) {
    lastTouch = performance.now();
    var st = start;
    start = null;
    var d = drag;
    drag = null;
    if (d) {
      d.alive = false;
      window.__ksCarouselDragging = false;
    }
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
    if (!hr || panelHidden()) return;
    commit({ hr: hr, container: viewContainer(hr), dx: dx, preview: null },
      dx < 0 ? 1 : -1);
  }, { passive: true, capture: true });

  // The native side claiming the gesture (the drawer's edge swipe, a
  // Flutter overlay) cancels the page's stream; spring back and forget.
  addEventListener('touchcancel', function () {
    start = null;
    if (drag) {
      drag.alive = false;
      window.__ksCarouselDragging = false;
      snapBack(drag);
      drag = null;
    }
  }, { passive: true, capture: true });
})();
''';
