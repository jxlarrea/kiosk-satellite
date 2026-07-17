/// Document-start script injected when "Disable cache" is on.
///
/// `cacheEnabled: false` / `cacheMode: LOAD_NO_CACHE` only bypasses the
/// WebView's HTTP cache. A **service worker** sits above that cache and serves
/// its own Cache Storage, so it happily keeps handing back a stale bundle even
/// with the HTTP cache disabled. Home Assistant always registers one, which is
/// why a redeployed dashboard/card appears not to update (the resource URL is
/// unchanged unless the version is bumped).
///
/// So on **every** load we empty Cache Storage and drop any worker. An empty
/// cache forces the worker to go to the network, so the page is always fresh —
/// no reload needed, and therefore no purge/reload loop (Home Assistant
/// re-registers its worker on each load, so a guard-free purge+reload would
/// ping-pong forever, and a sticky guard would only work once per session and
/// silently serve stale code after the next deploy).
///
/// Deliberately does NOT touch localStorage, sessionStorage or cookies: pages
/// (e.g. the Voice Satellite card, which keeps its per-browser satellite
/// config there) must not lose saved state just because caching is off.
const noCachePurgeScript = '''
(function () {
  try {
    if ('caches' in window) {
      caches.keys().then(function (keys) {
        keys.forEach(function (k) { caches.delete(k); });
      }).catch(function () {});
    }
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.getRegistrations().then(function (regs) {
        regs.forEach(function (r) { r.unregister(); });
      }).catch(function () {});
    }
  } catch (e) { /* never break the page */ }
})();
''';

/// Purge script for the on-demand "Clear web cache" action: same as above but
/// reloads afterwards, so the current page is refetched immediately. Also
/// storage-safe — localStorage and cookies survive, so you stay logged in and
/// keep your saved page config.
/// Fully awaited on purpose — this is the drawer's deliberate maintenance
/// action, not a gesture. Reloading before the worker is truly gone was
/// tried (timeboxed) and produced a delayed aftershock: the half-cleaned
/// page reloads, Home Assistant re-registers its worker, and when that
/// worker finishes installing — up to half a minute later on cold caches —
/// it seizes the page and the frontend reloads itself "out of nowhere".
/// The pull-to-refresh gesture uses [pullRefreshClearScript] instead, which
/// never touches the worker and so never has the aftershock.
const clearWebCacheScript = '''
(async function () {
  try {
    if ('serviceWorker' in navigator) {
      var regs = await navigator.serviceWorker.getRegistrations();
      for (var i = 0; i < regs.length; i++) { await regs[i].unregister(); }
    }
    if ('caches' in window) {
      var keys = await caches.keys();
      for (var j = 0; j < keys.length; j++) { await caches.delete(keys[j]); }
    }
  } catch (e) { /* fall through to the reload regardless */ }
  location.reload();
})();
''';

/// The cache-clearing pull: empty Cache Storage (timeboxed), reload, and
/// leave the service worker ALONE.
///
/// An empty cache forces the worker to the network, so the reload is exactly
/// as fresh as a full clear — but without unregistering anything there is no
/// registration churn, and therefore none of the aftershock described on
/// [clearWebCacheScript]. The timebox keeps a busy worker (mid-install right
/// after a boot, actively writing these caches) from holding the reload
/// hostage; whatever survives the window is stale cache the next pull can
/// take another swing at.
///
/// Worker UPDATES still flow: the browser re-checks the worker script on
/// every navigation anyway, and the fire-and-forget `update()` below asks
/// explicitly on every pull. A genuinely new worker installs, activates
/// (Home Assistant's calls skipWaiting) and runs the site's own update flow;
/// an unchanged one is a no-op with no controller churn.
const pullRefreshClearScript = '''
(async function () {
  try {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.getRegistrations().then(function (regs) {
        regs.forEach(function (r) { r.update(); });
      }).catch(function () {});
    }
    var work = (async function () {
      if ('caches' in window) {
        var keys = await caches.keys();
        for (var i = 0; i < keys.length; i++) { await caches.delete(keys[i]); }
      }
    })();
    await Promise.race([
      work,
      new Promise(function (r) { setTimeout(r, 1500); }),
    ]);
  } catch (e) { /* fall through to the reload regardless */ }
  location.reload();
})();
''';
