/// Document-start script that tells the app when Home Assistant's set of
/// dashboards may have changed, through the page's own live connection.
///
/// The dashboard view selects (MQTT and ESPHome) carry the dashboards and
/// views as their option list, and the ESPHome one can only change that
/// list by re-registering with Home Assistant, which makes every entity
/// unavailable for a moment. So the list is never re-read on a timer: the
/// page reports the moments it can actually have moved, and nothing else
/// (issue #362). Home Assistant fires `panels_updated` on its bus when a
/// dashboard is created or deleted and `lovelace_updated` when one is
/// edited (views added or removed); the connection's `ready` fires once
/// it is authenticated, on a load and again on every reconnect, which is
/// the outage ending. Each becomes one `ksHaDashboardsChanged` message;
/// the app coalesces them.
///
/// The frontend's `hass` appears a moment after the document does, so the
/// script waits for it, for a bounded while: a page that never grows one
/// is not Home Assistant.
const haDashboardsWatchScript = '''
(function () {
  if (window.__ksDashWatch) return;
  window.__ksDashWatch = true;
  var tries = 0;
  function report(why) {
    try {
      window.flutter_inappwebview.callHandler('ksHaDashboardsChanged', why);
    } catch (e) {}
  }
  function arm() {
    var el = document.querySelector('home-assistant');
    var conn = el && el.hass && el.hass.connection;
    if (!conn || typeof conn.subscribeEvents !== 'function') {
      if (++tries < 120) setTimeout(arm, 1000);
      return;
    }
    try {
      conn.subscribeEvents(function () { report('panels'); }, 'panels_updated');
      conn.subscribeEvents(function () { report('lovelace'); }, 'lovelace_updated');
      if (typeof conn.addEventListener === 'function') {
        conn.addEventListener('ready', function () { report('ready'); });
      }
    } catch (e) {}
    report('ready');
  }
  arm();
})();
''';
