/// Document-start script that hides Kiosk Satellite's own freezes from the
/// page.
///
/// The freeze sets the dashboard WebView to `View.INVISIBLE` (WebViewFreeze) so
/// Chromium stops compositing a page nobody can see. Chromium derives page
/// visibility from view visibility, so the page is told it went to the
/// background: `document.hidden` flips and `visibilitychange` fires. That is
/// indistinguishable from the user switching away, and web apps react by
/// tearing things down. Voice Satellite released the microphone and rebuilt its
/// wake-word stack on every screensaver, which cost it a wake-word handoff each
/// time (VS #137); Home Assistant itself throttles on the same signal.
///
/// So the page keeps hearing "visible" for as long as the freeze is ours: the
/// masked getters answer visible, and the `visibilitychange` events the freeze
/// and the thaw generate are swallowed in the capture phase before any page
/// listener (on `document` or `window`) sees them. Nothing else is touched — a
/// genuine background, where the app really is behind another app, still
/// reaches the page as it always did.
///
/// Only events the mask itself created are swallowed, and only in pairs: a
/// `visible` is withheld from the page only when the matching `hidden` was
/// withheld too. An unpaired `visible` is the one event that must never be
/// eaten: the Home Assistant frontend blocks every websocket reconnect from
/// the moment it sees `hidden` until it sees `visible`, so a page that saw
/// the first and never the second can never reconnect again, and sits on
/// "Connection lost. Reconnecting…" until it is reloaded (issue #228 is that
/// state, reached without any mask involved). The mask can straddle a real
/// background exactly that way: the freeze goes up as the app comes forward,
/// between the flip of `visibilityState` and the dispatch of its event, and
/// the mask starts one event too early.
///
/// `window.__ksVisibilityMasked` reads back whether the page is being masked
/// right now, for anyone diagnosing a page that disagrees with the screen.
///
/// [maskVisibilityJs] drives it from Dart around the freeze. Masking must be on
/// before the view is hidden; unmasking is deferred until the page is really
/// visible again, so the thaw's own event is swallowed too whichever order the
/// renderer delivers it in.
const visibilityMaskScript = '''
(function () {
  if (window.__ksSetVisibilityMask) return;
  var masked = false;
  var unmaskWhenVisible = false;
  // Walk the chain for the real accessors: Chromium defines both on
  // Document.prototype, which is two links up from the document itself.
  function descriptor(name) {
    for (var o = document; o; o = Object.getPrototypeOf(o)) {
      var d = Object.getOwnPropertyDescriptor(o, name);
      if (d && d.get) return d;
    }
    return null;
  }
  var hiddenDesc = descriptor('hidden');
  var stateDesc = descriptor('visibilityState');
  if (!hiddenDesc || !stateDesc) return;
  function reallyHidden() {
    try { return hiddenDesc.get.call(document); } catch (e) { return false; }
  }
  try {
    Object.defineProperty(document, 'hidden', {
      configurable: true,
      get: function () { return masked ? false : reallyHidden(); },
    });
    Object.defineProperty(document, 'visibilityState', {
      configurable: true,
      get: function () {
        if (masked) return 'visible';
        try { return stateDesc.get.call(document); } catch (e) { return 'visible'; }
      },
    });
  } catch (e) { return; }
  // Capture phase on document, registered before the page's own code runs, so
  // stopImmediatePropagation reaches every later listener - document, window,
  // and the onvisibilitychange properties alike.
  var deferred = null;
  var maskWhenVisible = false;
  // Whether the page owes a visible: the mask swallowed the hidden edge of
  // this freeze, so the matching visible is the one to swallow too. Without
  // it, a mask that started after the page had already been told it went
  // hidden would swallow the visible that answers it (see above).
  var swallowedHidden = false;
  function start() {
    masked = true;
    maskWhenVisible = false;
    unmaskWhenVisible = false;
    swallowedHidden = false;
    window.__ksVisibilityMasked = true;
    if (deferred) { clearTimeout(deferred); deferred = null; }
  }
  function stop() {
    masked = false;
    maskWhenVisible = false;
    unmaskWhenVisible = false;
    swallowedHidden = false;
    window.__ksVisibilityMasked = false;
    if (deferred) { clearTimeout(deferred); deferred = null; }
  }
  document.addEventListener('visibilitychange', function (e) {
    if (!masked) {
      // A freeze that began while the page was genuinely in the background:
      // the page was told it went hidden, so it is owed the matching visible.
      // Let this one through and pick the mask up from here.
      if (maskWhenVisible && !reallyHidden()) start();
      return;
    }
    if (reallyHidden()) {
      // The freeze's own hidden edge: swallow it, and remember that the
      // visible answering it is ours to swallow as well.
      swallowedHidden = true;
      e.stopImmediatePropagation();
      return;
    }
    // A visible the page is owed (its hidden reached it) must go through,
    // whatever the mask is doing — the page has been sitting on a hidden it
    // never saw answered, and some of what it stopped doing there only
    // restarts on this event.
    if (swallowedHidden) {
      swallowedHidden = false;
      e.stopImmediatePropagation();
    }
    if (unmaskWhenVisible) stop();
  }, true);
  window.__ksVisibilityMasked = false;
  window.__ksSetVisibilityMask = function (on) {
    if (on) {
      // Already hidden for a reason that is not ours - the app is behind
      // another app. Masking now would silently take back a hidden the page
      // has already seen, so wait for it to come forward.
      if (!masked && reallyHidden()) {
        maskWhenVisible = true;
        return;
      }
      start();
      return;
    }
    // Asked to stop masking while the view is still hidden: the thaw's event
    // has not arrived yet. Keep swallowing until it does, or the page would
    // see the freeze end without ever having been told it started. The timer
    // is the backstop - a mask that outlives its freeze would go on hiding a
    // genuine background from the page, which is far worse than one leaked
    // event, and nothing else would ever come to lift it.
    if (masked && reallyHidden()) {
      unmaskWhenVisible = true;
      if (deferred) clearTimeout(deferred);
      deferred = setTimeout(stop, 3000);
      return;
    }
    stop();
  };
})();
''';

/// Turn the mask on or off in the page. No-op on pages loaded before the
/// script existed (an older WebView, or a page the script did not reach).
String maskVisibilityJs(bool on) =>
    'if (window.__ksSetVisibilityMask) window.__ksSetVisibilityMask($on);';
