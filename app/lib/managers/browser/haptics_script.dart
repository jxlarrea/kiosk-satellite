/// Button haptics: a short native vibration whenever a tap lands on
/// something button-shaped in the dashboard, so a wall panel answers like
/// a physical switch.
///
/// Everything is event-driven and idle-free: one capture-phase click
/// listener on the window, no timers, no rAF loops, no observers, and the
/// per-tap work is a handful of string checks over the event's composed
/// path — never a layout read (getComputedStyle/gBCR would pay a document
/// flush right under the tap; the carousel learned that the hard way).
/// Clicks arrive at human rates, so the cost while enabled is effectively
/// zero, and while disabled the listener returns on the first check.
///
/// `click` rather than pointerdown: click only fires on a completed tap,
/// so a scroll that happens to start on a card never buzzes, and Enter-key
/// activation gets the same feedback. The composed path is walked instead
/// of the retargeted event.target because HA nests everything in open
/// shadow roots — the target at the window is just `home-assistant`.
///
/// What counts as a button: real form controls, HA's web-component zoo by
/// name fragment (ha-icon-button, ha-switch, ha-control-*, mwc-*, chips,
/// fabs), ARIA roles, and any element carrying HA's actionHandler
/// property — the directive the frontend attaches to everything with a
/// tap_action, which is what makes tile cards and entity rows count.
///
/// The haptic itself is native (see HapticsBridge.kt): one fire-and-forget
/// callHandler message per accepted tap, throttled to one per 90ms so a
/// synthetic double-dispatch cannot buzz twice.
///
/// Gated by `window.__ksHapticsEnabled`, seeded at document start,
/// re-asserted on every load and updated live on toggle, so the setting
/// needs no reload — the same contract as `__ksCarouselEnabled`.
const buttonHapticsScript = '''
(function () {
  if (window.__ksHaptics) return;
  window.__ksHaptics = true;

  var THROTTLE_MS = 90; // one buzz per tap, even if a component re-clicks
  var MAX_WALK = 20;    // elements of the composed path worth looking at

  var last = 0;

  var EXACT = /^(button|select|summary|a)\$/;
  var TYPES = /^(checkbox|radio|button|submit|reset|range)\$/;
  var ROLES = /^(button|switch|checkbox|radio|menuitem|option|tab|link)\$/;

  function wantsHaptic(e) {
    var path = e.composedPath ? e.composedPath() : [];
    var seen = 0;
    for (var i = 0; i < path.length && seen < MAX_WALK; i++) {
      var n = path[i];
      if (!(n instanceof Element)) continue;
      seen++;
      var name = n.localName || '';
      if (EXACT.test(name)) return true;
      if (name === 'input') return TYPES.test(n.type || '');
      // The frontend's component names are a moving target; fragments
      // catch the whole family (ha-icon-button, ha-control-switch,
      // mwc-button, hui-button-card, ha-assist-chip, md-fab, ...).
      if (name.indexOf('button') !== -1 ||
          name.indexOf('switch') !== -1 ||
          name.indexOf('checkbox') !== -1 ||
          name.indexOf('-radio') !== -1 ||
          name.indexOf('chip') !== -1 ||
          name.indexOf('fab') !== -1) {
        return true;
      }
      var role = n.getAttribute && n.getAttribute('role');
      if (role && ROLES.test(role)) return true;
      // HA's action-handler directive marks everything with a
      // tap_action — tile cards, entity-row icons, picture elements.
      try { if (n.actionHandler) return true; } catch (_) {}
    }
    return false;
  }

  addEventListener('click', function (e) {
    if (window.__ksHapticsEnabled !== true) return;
    var now = e.timeStamp || 0;
    if (now - last < THROTTLE_MS) return;
    if (!wantsHaptic(e)) return;
    last = now;
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('ksHaptic');
      }
    } catch (_) {}
  }, { passive: true, capture: true });
})();
''';
