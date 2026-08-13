import 'dart:convert';

/// Fade for the dashboard view rotation (issue #189): one rotation step
/// fades the screen out to the dashboard's background color, switches
/// views while covered, and fades back in once the new view has
/// rendered.
///
/// The first version was a true crossfade: the cached target view
/// mounted over the live one and dissolved in while the old view faded
/// beneath it. Real dashboards made it look clunky no matter how the
/// legs were staggered - wherever the incoming view was transparent the
/// outgoing content showed through and popped at the swap, the atomic
/// handoff turned any pixel difference into a visible step, and hass
/// re-renders landed mid-fade as content jumps. The reporter's own
/// card-mod experiment (fade to black, switch covered, fade back) reads
/// smoother than the dissolve ever did, because nothing the viewer can
/// see changes while anything structural is happening. This is that,
/// generalized: a fixed full-viewport cover in the theme's background
/// color (so the dip reads as the dashboard breathing, not a cut to
/// black on light themes; #000 when no color can be read) fades in over
/// the whole UI, the same soft SPA navigation the instant path uses
/// fires underneath it, a poll waits until the view container holds a
/// NEW rendered view element plus a settle beat for its raster, and the
/// cover fades away.
///
/// Covered switching also erases the old machinery's hard problems by
/// construction: first visits simply build under the cover (no
/// hand-built hui-view, no cache seeding, no rendered-DOM audition), no
/// element is ever borrowed from `hui-root._viewCache` (nothing to
/// scrub, nothing the carousel's strip can conflict over), and page
/// scroll needs no reconciliation. The poll is bounded and the fade-out
/// runs on its own timer regardless, so an unseen swap shows the page
/// again no matter what - the cover can never wedge the screen blank.
///
/// Everything is timed with setTimeout, never requestAnimationFrame: a
/// covered dashboard stops compositing (rendering freeze, overlay pages)
/// and rAF stalls with it - the choreography must reach the navigation
/// even when nobody can see it, or rotation silently stops advancing.
///
/// Anything the fade cannot handle returns 'plain' and the caller runs
/// the instant navigation instead: a different dashboard, a bare or
/// unknown route, a missing hui-root, a transition already in flight.
/// The whole script is evaluated per rotation step with its arguments
/// baked in (like navigateToViewPath's own JS) rather than injected as a
/// persistent user script: nothing global to keep in sync with the
/// toggle, and non-HA pages never carry it. It returns synchronously -
/// 'fade' when the choreography started (the caller is done), 'plain'
/// when the instant path should run - while the fade itself continues
/// async, guarded against overlap by a self-expiring busy stamp whose
/// ceiling is deliberately fat: on a janked main thread the timers
/// starve, and a stamp sized to the nominal duration expired mid-flight
/// and let the next tick start a second choreography over the first
/// (observed live on an Echo Show 8). Ticks landing inside the window
/// cut instead, which is always safe.
String rotationCrossfadeJs({required String base, required String viewPath}) {
  return '''
(function () {
  var base = ${jsonEncode(base)};
  var viewPath = ${jsonEncode(viewPath)};
  var OUT_MS = 600;     // fade to the background color
  var IN_MS = 800;      // fade back into the new view
  var SETTLE_MS = 250;  // raster beat after the new view appears
  var POLL_MS = 100;    // swap-watch cadence while covered
  var POLL_MAX = 2500;  // longest covered wait for the swap
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
    function huiRoot() {
      var ha = document.querySelector('home-assistant');
      var main = ha && ha.shadowRoot &&
        ha.shadowRoot.querySelector('home-assistant-main');
      var panel = main && main.shadowRoot &&
        main.shadowRoot.querySelector('ha-panel-lovelace');
      return panel && panel.shadowRoot &&
        panel.shadowRoot.querySelector('hui-root');
    }
    function viewContainer() {
      var hr = huiRoot();
      return hr && hr.shadowRoot &&
        (hr.shadowRoot.querySelector('hui-view-container') ||
         hr.shadowRoot.querySelector('#view'));
    }
    var container = viewContainer();
    var hr = huiRoot();
    if (!hr || !hr.getClientRects().length || !container) return 'plain';
    // The route must actually exist in this dashboard, or the covered
    // wait times out staring at nothing and the fade shows a spinner.
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

    // The theme's background, so the dip reads as the dashboard
    // breathing rather than a cut to black on light themes.
    var bg = '';
    try {
      bg = getComputedStyle(document.documentElement)
        .getPropertyValue('--primary-background-color').trim();
      if (!bg) {
        var b = getComputedStyle(document.body).backgroundColor;
        if (b && b !== 'rgba(0, 0, 0, 0)' && b !== 'transparent') bg = b;
      }
    } catch (_) {}
    if (!bg) bg = '#000';

    window.__ksRotFadeBusy =
      Date.now() + OUT_MS + POLL_MAX + SETTLE_MS + IN_MS + 6000;
    var idle = function () { window.__ksRotFadeBusy = 0; };

    var cover = document.createElement('div');
    cover.id = '__ksRotFadeCover';
    cover.style.cssText =
      'position:fixed;inset:0;z-index:2147483647;pointer-events:none;' +
      'background:' + bg + ';opacity:0;will-change:opacity;' +
      'transition:opacity ' + OUT_MS + 'ms ease-in-out;';
    (document.body || document.documentElement).appendChild(cover);
    var dropped = false;
    var drop = function () {
      if (dropped) return;
      dropped = true;
      try { cover.remove(); } catch (_) {}
      idle();
    };
    var reveal = function () {
      cover.style.transition = 'opacity ' + IN_MS + 'ms ease-in-out';
      cover.style.opacity = '0';
      setTimeout(drop, IN_MS + 100);
    };

    setTimeout(function () { // the append must commit before the fade
      cover.style.opacity = '1';
      setTimeout(function () {
        // Fully covered: switch. The old view element is what the
        // container holds NOW; the swap is detected by that reference
        // changing to a new element that has produced DOM.
        var before = container.lastElementChild;
        history.pushState(null, '', path);
        window.dispatchEvent(new CustomEvent('location-changed'));
        var waited = 0;
        var poll = function () {
          var done = false;
          try {
            var c = viewContainer() || container;
            var el = c.lastElementChild;
            done = !!el && el !== before &&
              (el.childElementCount > 0 ||
               (el.shadowRoot && el.shadowRoot.childElementCount > 0));
          } catch (_) {}
          if (done) { setTimeout(reveal, SETTLE_MS); return; }
          waited += POLL_MS;
          // An unseen swap must never wedge the screen behind the
          // cover: give up and show whatever the page is.
          if (waited >= POLL_MAX) { reveal(); return; }
          setTimeout(poll, POLL_MS);
        };
        setTimeout(poll, POLL_MS);
      }, OUT_MS + 50);
    }, 20);
    return 'fade';
  } catch (_) { return 'plain'; }
})();
''';
}
