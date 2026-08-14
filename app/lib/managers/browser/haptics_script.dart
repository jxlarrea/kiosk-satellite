/// Haptics: a short native vibration whenever a tap lands on something
/// button-shaped in the dashboard, and a lighter tick for every step a
/// slider crosses while it drags — so a wall panel answers like a
/// physical switch and a brightness drag feels like a detented knob.
///
/// Everything is event-driven and idle-free: capture-phase listeners on
/// the window, no timers, no rAF loops, no observers, and the per-event
/// work is a handful of string checks and one property read — never a
/// layout read (getComputedStyle/gBCR would pay a document flush right
/// under the tap; the carousel learned that the hard way). Clicks arrive
/// at human rates; slider events arrive at input rate during a drag but
/// each one does two comparisons and returns unless a step boundary was
/// actually crossed.
///
/// Buttons ride `click` rather than pointerdown: click only fires on a
/// completed tap, so a scroll that happens to start on a card never
/// buzzes, and Enter-key activation gets the same feedback. The composed
/// path is walked instead of the retargeted event.target because HA nests
/// everything in open shadow roots — the target at the window is just
/// `home-assistant`.
///
/// What counts as a button: real form controls, HA's web-component zoo by
/// name fragment (ha-icon-button, ha-switch, ha-control-*, mwc-*, chips,
/// fabs), ARIA roles, and any element carrying HA's actionHandler
/// property — the directive the frontend attaches to everything with a
/// tap_action, which is what makes tile cards and entity rows count.
/// Anything slider-named in the path hands the click over to the slider
/// path instead: the release of a drag also fires a click, and a full
/// tap on top of the last tick would double-buzz.
///
/// Sliders funnel into one function from two directions. Native range
/// inputs (ha-slider is md-slider around one) surface as composed `input`
/// events at the window, where composedPath()[0] is the real inner input
/// event.target was retargeted away from. Everything else announces a
/// value by DISPATCHING a custom event — HA's `slider-moved` /
/// `value-changed`, the thermostat wheel's `value/low/high-changing`
/// stream (ha-control-circular-slider fires -changing per step during the
/// drag and -changed only on release), and custom cards like Mushroom
/// whose `current-change` / `change` are created with neither bubbles nor
/// composed, so no listener anywhere above them can ever see them. So the
/// custom-event side hooks EventTarget.prototype.dispatchEvent itself and
/// watches slider-named elements dispatch — the source end of the pipe,
/// where flags do not matter. The hook's overhead off the slider path is
/// one regex test per JS-dispatched event; page-generated events (clicks,
/// input, pointer) never pass through it at all.
///
/// The value is quantized to the control's step and remembered on the
/// element itself, so a tick fires only when the stepped value actually
/// changes — release events repeating the last value dedupe against the
/// same memory, and holding still buzzes nothing. A dual-target
/// thermostat's low and high handles keep separate memories on their
/// shared element.
///
/// The haptic itself is native (see HapticsBridge.kt): one fire-and-forget
/// callHandler message per accepted event — 'tap' or 'tick', strength is
/// the app's business — throttled per kind (taps 90ms, ticks 30ms) so a
/// synthetic double-dispatch cannot buzz twice and a fast drag reads as
/// texture rather than saturating the motor.
///
/// Gated by `window.__ksHapticsEnabled`, seeded at document start,
/// re-asserted on every load and updated live on toggle, so the setting
/// needs no reload — the same contract as `__ksCarouselEnabled`.
const buttonHapticsScript = '''
(function () {
  if (window.__ksHaptics) return;
  window.__ksHaptics = true;

  var TAP_MS = 90;   // one buzz per tap, even if a component re-clicks
  var TICK_MS = 30;  // fast drags feel like texture, not a stall
  var MAX_WALK = 20; // elements of the composed path worth looking at

  var lastTap = 0;
  var lastTick = 0;

  var EXACT = /^(button|select|summary|a)\$/;
  var TYPES = /^(checkbox|radio|button|submit|reset)\$/;
  var ROLES = /^(button|switch|checkbox|radio|menuitem|option|tab|link)\$/;

  function send(kind) {
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('ksHaptic', kind);
      }
    } catch (_) {}
  }

  // ── Buttons ─────────────────────────────────────────────────────────

  function wantsTap(e) {
    var path = e.composedPath ? e.composedPath() : [];
    var seen = 0;
    for (var i = 0; i < path.length && seen < MAX_WALK; i++) {
      var n = path[i];
      if (!(n instanceof Element)) continue;
      seen++;
      var name = n.localName || '';
      // A slider owns its haptics: its drag already ticked, and the
      // release fires a click whose path can reach an action-handled
      // card — a tap on top of the last tick would double-buzz.
      if (name.indexOf('slider') !== -1) return false;
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
    if (now - lastTap < TAP_MS) return;
    if (!wantsTap(e)) return;
    lastTap = now;
    send('tap');
  }, { passive: true, capture: true });

  // ── Sliders ─────────────────────────────────────────────────────────

  // Every custom event a slider family announces values with. 'change'
  // and 'value-changed' are generic across the frontend; the slider-name
  // gate below keeps text fields and pickers out.
  var SLIDE_EV = new RegExp('^(slider-moved|value-changed|value-changing|' +
    'low-changing|low-changed|high-changing|high-changed|' +
    'current-change|change)\$');

  // [dv] is the event's detail.value when it carried one; release events
  // that signal end-of-interaction with an undefined detail fall back to
  // the element's own value, which sits on the last step and dedupes.
  function sliderTick(t, type, dv, now) {
    var name = t.localName || '';
    var isRange = name === 'input' && t.type === 'range';
    if (!isRange && name.indexOf('slider') === -1) return;
    var v = typeof dv === 'number' ? dv : parseFloat(t.value);
    if (!isFinite(v)) return;
    var step = parseFloat(t.step) || 1;
    var q = Math.round(v / step);
    // Dual-target thermostats drive low and high from one element; each
    // handle remembers its own step or they would dedupe against each
    // other where the ranges meet.
    var key = type.lastIndexOf('low-', 0) === 0 ? '__ksHapticStepLo'
      : type.lastIndexOf('high-', 0) === 0 ? '__ksHapticStepHi'
      : '__ksHapticStep';
    if (t[key] === q) return;
    t[key] = q;
    if (now - lastTick < TICK_MS) return;
    lastTick = now;
    send('tick');
  }

  addEventListener('input', function (e) {
    if (window.__ksHapticsEnabled !== true) return;
    var t = e.composedPath ? e.composedPath()[0] : e.target;
    if (t instanceof Element) sliderTick(t, e.type, null, e.timeStamp || 0);
  }, { passive: true, capture: true });

  var dispatch = EventTarget.prototype.dispatchEvent;
  EventTarget.prototype.dispatchEvent = function (ev) {
    try {
      if (window.__ksHapticsEnabled === true && ev &&
          SLIDE_EV.test(ev.type) && this instanceof Element) {
        var d = ev.detail;
        sliderTick(this, ev.type,
          d && typeof d.value === 'number' ? d.value : null,
          performance.now());
      }
    } catch (_) {}
    return dispatch.call(this, ev);
  };
})();
''';
