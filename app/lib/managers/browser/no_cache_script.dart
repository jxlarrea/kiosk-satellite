/// Document-start script injected when "Disable cache" is on.
///
/// Setting `cacheEnabled: false` / `cacheMode: LOAD_NO_CACHE` only bypasses the
/// WebView's HTTP cache. A **service worker** sits above that cache and serves
/// its own Cache Storage, so it happily keeps handing back a stale bundle even
/// with the HTTP cache disabled. Home Assistant always registers one, which is
/// what makes a redeployed dashboard/card appear not to update (the resource
/// URL is unchanged unless the version is bumped).
///
/// So on load we unregister any service worker and delete Cache Storage, then
/// reload once so the page is refetched with no worker controlling it.
///
/// Guarded by a `sessionStorage` flag so it runs at most once per page session
/// — HA re-registers its worker on every load, so an unguarded purge+reload
/// would loop forever.
///
/// Deliberately does NOT touch localStorage or cookies: pages (e.g. the Voice
/// Satellite card) keep their saved config.
const noCachePurgeScript = '''
(function () {
  try {
    if (sessionStorage.getItem('__ks_cache_purged') === '1') return;
    var done = function () {
      try { sessionStorage.setItem('__ks_cache_purged', '1'); } catch (e) {}
    };
    var swP = ('serviceWorker' in navigator)
      ? navigator.serviceWorker.getRegistrations()
      : Promise.resolve([]);
    var cacheP = ('caches' in window) ? caches.keys() : Promise.resolve([]);
    Promise.all([swP, cacheP]).then(function (res) {
      var regs = res[0] || [];
      var keys = res[1] || [];
      if (!regs.length && !keys.length) { done(); return; }
      return Promise.all(
        regs.map(function (r) { return r.unregister(); })
          .concat(keys.map(function (k) { return caches.delete(k); }))
      ).then(function () {
        done();
        // Refetch without a worker in the way. localStorage/cookies survive.
        location.reload();
      });
    }).catch(done);
  } catch (e) { /* never break the page */ }
})();
''';
