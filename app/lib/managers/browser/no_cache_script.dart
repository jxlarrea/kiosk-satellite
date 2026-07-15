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
