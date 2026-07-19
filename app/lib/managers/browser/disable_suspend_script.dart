/// Document-start script that stops Home Assistant suspending the kiosk's
/// websocket while it is off screen.
///
/// HA's "Suspend background connections" preference (per-user, surfaced as
/// `hass.suspendWhenHidden`) closes the server connection after five minutes
/// in a hidden window/background tab. On a wall tablet that is exactly wrong:
/// the kiosk spends most of its life with the dashboard behind a wake overlay
/// or the screen off, and a closed connection breaks the next wake until it
/// reconnects. So on every Home Assistant load we force it off for this
/// session and persist it off for the user, so future loads start that way
/// too.
///
/// This is belt-and-suspenders, not the whole fix: Chromium's own hidden-tab
/// timer throttling can still starve the keepalive and drop the socket even
/// with suspension off, which is why the wake path's `ensureHaConnected`
/// (BrowserManager) remains the guarantee. This just removes one deliberate
/// cause of the drop.
///
/// Runs at document start, so hass is not up yet; it polls until the
/// connection is live, re-asserts the runtime flag across a few hass rebuilds,
/// persists once, then stops. A no-op on non-HA pages (no home-assistant
/// element ever appears, so it just times out).
const disableSuspendScript = '''
(function () {
  var persisted = false, applied = 0, ticks = 0;
  function apply() {
    ticks++;
    var el = document.querySelector('home-assistant');
    var hass = el && el.hass;
    if (!hass || !hass.connection || !hass.connection.connected) return;
    // This session: never suspend, whatever the stored preference says.
    try { hass.suspendWhenHidden = false; } catch (e) {}
    applied++;
    // Persist once for this user, merged so other core prefs survive.
    if (!persisted) {
      persisted = true;
      try {
        hass.connection.sendMessagePromise(
          { type: 'frontend/get_user_data', key: 'core' }
        ).then(function (r) {
          var core = (r && r.value) || {};
          if (core.suspendWhenHidden === false) return;
          core.suspendWhenHidden = false;
          return hass.connection.sendMessagePromise(
            { type: 'frontend/set_user_data', key: 'core', value: core }
          );
        }).catch(function () { persisted = false; });
      } catch (e) { persisted = false; }
    }
  }
  var iv = setInterval(function () {
    apply();
    // Re-assert across a few hass rebuilds, then stop; give up if the page
    // never brings up a connection (it is not a Home Assistant page).
    if (applied >= 3 || ticks >= 30) clearInterval(iv);
  }, 2000);
})();
''';
