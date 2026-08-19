/// HA kiosk mode: hide the Home Assistant header and/or sidebar, per the
/// user's choice (some people rely on the header tabs to move between
/// views, so neither is mandatory).
///
/// This used to be able to defer to the kiosk-mode HACS resource, driving it
/// through `?kiosk` URL parameters. That is gone: the resource opens a
/// websocket subscription to every state change in the instance and sorts
/// them out in the browser, which is a heavy enough stream on a wall tablet
/// that Home Assistant disconnects it for falling behind, and the app cannot
/// filter what it never sees. Hiding a header is not worth a connection, so
/// the app does the hiding itself.
///
/// Doing it ourselves means reaching into Home Assistant's shadow DOM, which
/// is private and moves between releases. The approach is chosen to age as
/// well as that allows:
///
///  - Elements are found by custom-element tag name (`ha-drawer`, `hui-root`)
///    rather than by tree position. Tag names are the most stable thing about
///    the frontend; the shape around them is not.
///  - Every shadow root is caught as it is created, by wrapping
///    `attachShadow` before the frontend runs. No polling, no waiting for a
///    tree to settle, and panels mounted an hour later are styled the moment
///    they exist.
///  - The styles name several generations of each element at once (the mwc
///    drawer's `.mdc-drawer` and the current `.sidebar-shell`, `app-header`
///    and `ch-header`), so a release that moves to the next one is already
///    covered and an obsolete selector just matches nothing.
///
/// A hidden sidebar also stays hidden: the edge swipe and the menu button
/// both work by opening the drawer, so the toggle event is swallowed and the
/// drawer's `open` attribute is stripped if anything sets it anyway.
library;

import 'dart:convert';

/// Document-start script. Always injected, and acts only while its flags say
/// so, so the setting applies live with no page reload (the same contract the
/// pull-to-refresh and carousel scripts use). [kioskModeApplyJs] drives it.
const kioskModeScript = '''
(function () {
  if (window.__ksKiosk) return;
  var ID = 'ks-kiosk-mode';
  var S = { on: false, header: true, sidebar: true, roots: [] };
  window.__ksKiosk = S;

  // The elements worth styling, by tag. Anything else that grows a shadow
  // root is none of our business and is not even remembered.
  function target(tag) {
    return tag === 'home-assistant-main' || tag === 'ha-drawer' ||
      tag === 'hui-root';
  }

  // Outside the dashboard's own WebView the script is handed the one origin
  // it may touch, so a page that navigates on from Home Assistant to
  // somewhere else keeps its own header and sidebar. The dashboard sets no
  // list: everything it loads is the dashboard.
  function allowedHere() {
    var o = window.__ksKioskOrigins;
    return !o || !o.length || o.indexOf(location.origin) >= 0;
  }

  function css(tag) {
    if (!S.on || !allowedHere()) return '';
    if (tag === 'home-assistant-main') {
      return S.sidebar
        ? 'ha-drawer{--mdc-drawer-width:0px!important;}' +
          'ha-sidebar{display:none!important;}'
        : '';
    }
    if (tag === 'ha-drawer') {
      // The drawer owns the sidebar's container and the content offset that
      // makes room for it; both live in its own shadow root, out of reach of
      // the styles above.
      return S.sidebar
        ? '.mdc-drawer,.sidebar-shell{display:none!important;width:0!important;' +
          'min-width:0!important;border:0!important;}' +
          '.mdc-drawer-scrim{display:none!important;}' +
          '.mdc-drawer-app-content,.app-content{margin-left:0!important;' +
          'margin-inline-start:0!important;padding-left:0!important;' +
          'padding-inline-start:0!important;}'
        : '';
    }
    if (tag === 'hui-root') {
      // Panel cards size themselves against the header through
      // var(--kiosk-header-height, var(--header-height)), the contract the
      // kiosk-mode resource established (the advanced camera card among
      // them), so hiding the header must also declare the kiosk height as
      // zero or a panel card ends a header short (#232). The padding must be
      // zero, nothing cleverer: the view container pads itself by the header
      // height plus the safe-area inset, and a padding that keeps the inset
      // leaves a cutout-sized band where the header was, doubled because
      // #view and hui-view nest (#249).
      return S.header
        ? '.header,.toolbar,app-header,ch-header{display:none!important;}' +
          '#view,hui-view{padding-top:0!important;' +
          'min-height:100vh!important;--kiosk-header-height:0px;}'
        : '';
    }
    return '';
  }

  function style(root) {
    var host = root && root.host;
    if (!host) return;
    var rules = css((host.tagName || '').toLowerCase());
    var el = root.getElementById ? root.getElementById(ID) : null;
    if (!rules) { if (el) el.remove(); return; }
    if (!el) {
      el = document.createElement('style');
      el.id = ID;
      root.appendChild(el);
    }
    if (el.textContent !== rules) el.textContent = rules;
  }

  // A drawer that is told to open anyway (the edge swipe, the menu button on
  // a release that does not route through the toggle event) is closed again
  // before it can show. One observer per drawer, for the life of that drawer.
  function guard(host) {
    if (host.__ksKioskGuard) return;
    host.__ksKioskGuard = true;
    try {
      new MutationObserver(function () {
        if (S.on && S.sidebar && allowedHere() && host.hasAttribute('open')) {
          host.removeAttribute('open');
        }
      }).observe(host, { attributes: true, attributeFilter: ['open'] });
    } catch (e) {}
  }

  function track(root) {
    var host = root && root.host;
    if (!host) return;
    var tag = (host.tagName || '').toLowerCase();
    if (!target(tag)) return;
    if (S.roots.indexOf(root) < 0) S.roots.push(root);
    if (tag === 'ha-drawer') guard(host);
    style(root);
  }

  // Catch every shadow root as it is born. Registered before the frontend's
  // own code runs, so nothing that matters is created before this is in
  // place.
  var attach = Element.prototype.attachShadow;
  if (attach) {
    Element.prototype.attachShadow = function (init) {
      var root = attach.call(this, init);
      try { track(root); } catch (e) {}
      return root;
    };
  }

  // Roots that already exist: only relevant when this script reaches a page
  // that was already up (an app update, a WebView that outlived a reload).
  // Bounded walk, and it only has to find the three tags above.
  function sweep(root, depth) {
    if (!root || depth > 12) return;
    var nodes;
    try { nodes = root.querySelectorAll('*'); } catch (e) { return; }
    for (var i = 0; i < nodes.length; i++) {
      var sr = nodes[i].shadowRoot;
      if (sr) { track(sr); sweep(sr, depth + 1); }
    }
  }

  function restyle() {
    for (var i = 0; i < S.roots.length; i++) style(S.roots[i]);
  }

  // The menu button and the edge swipe both ask the app to open the drawer
  // with this event. Capture phase, so it never reaches the handler.
  window.addEventListener('hass-toggle-menu', function (e) {
    if (S.on && S.sidebar && allowedHere()) {
      e.stopImmediatePropagation();
      if (e.preventDefault) e.preventDefault();
    }
  }, true);

  window.__ksKioskApply = function (on, header, sidebar) {
    S.on = !!on;
    S.header = !!header;
    S.sidebar = !!sidebar;
    sweep(document, 0);
    restyle();
  };

  // A navigation can mount a panel whose root was created before its
  // ancestors were styled; re-asserting costs a handful of string compares.
  window.addEventListener('location-changed', function () {
    setTimeout(function () { sweep(document, 0); restyle(); }, 80);
  });
})();
''';

/// Turn kiosk mode on or off in the page, live. No-op on a page loaded
/// before the script existed.
String kioskModeApplyJs({
  required bool apply,
  bool hideHeader = true,
  bool hideSidebar = true,
}) =>
    'if (window.__ksKioskApply) window.__ksKioskApply('
    '$apply, $hideHeader, $hideSidebar);';

/// The document-start sources that put kiosk mode on a Home Assistant page
/// shown OUTSIDE the dashboard WebView: a page opened from a dashboard link,
/// a rotation page, a Home Assistant page set as the website screensaver
/// (discussion #225). Those views load whatever address they are given, so
/// this is fenced twice over: the caller only asks for it when the address
/// belongs to this Home Assistant, and [origin] then holds the script to that
/// one origin for the life of the view, so a page that navigates onward to
/// somebody else's site is never touched. On a Home Assistant page that has
/// no header or sidebar to hide there is simply nothing to match.
///
/// Injected whether or not kiosk mode is on, and acting only while the flags
/// say so — the same contract the dashboard uses. These views are built once
/// and kept, so a script injected only while the setting was on would leave
/// the page with no way to hear about the setting being turned on later.
List<String> externalKioskModeSources({
  required String origin,
  required bool apply,
  required bool hideHeader,
  required bool hideSidebar,
}) => [
  'window.__ksKioskOrigins = [${jsonEncode(origin)}];',
  kioskModeScript,
  kioskModeApplyJs(
    apply: apply,
    hideHeader: hideHeader,
    hideSidebar: hideSidebar,
  ),
];
