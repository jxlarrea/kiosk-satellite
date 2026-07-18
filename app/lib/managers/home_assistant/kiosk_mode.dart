/// HA kiosk mode: hide the Home Assistant header and/or sidebar, per the
/// user's choice (some people rely on the header tabs to move between
/// views, so neither is mandatory).
///
/// Two strategies (setting `ha.kiosk_mode`):
///   plugin — query parameters handled by the kiosk-mode HACS plugin, which
///            tracks HA's shadow-DOM changes across releases. Preferred.
///   css    — inject CSS through the shadow roots ourselves. Version-fragile
///            by nature; deliberately isolated to this file.
///   auto   — plugin params AND the CSS fallback. The params are inert
///            without the plugin, and the CSS also covers a plugin that is
///            installed but broken against the running HA release.
library;

/// Add the kiosk-mode plugin query parameters matching the hide choices.
/// Both hidden is the plugin's `?kiosk`; one alone uses its dedicated
/// parameter; neither leaves the URL untouched.
String withKioskParam(
  String url, {
  bool hideHeader = true,
  bool hideSidebar = true,
}) {
  if (!hideHeader && !hideSidebar) return url;
  final param = hideHeader && hideSidebar
      ? 'kiosk'
      : hideHeader
      ? 'hide_header'
      : 'hide_sidebar';
  final uri = Uri.parse(url);
  if (uri.queryParameters.containsKey(param)) return url;
  return uri
      .replace(queryParameters: {...uri.queryParameters, param: ''})
      .toString();
}

/// JS that pierces HA's shadow DOM to hide the header and/or sidebar
/// without the kiosk-mode plugin. Best-effort fallback for setups that
/// don't run the plugin; HA's internal DOM changes across releases, so the
/// plugin is preferred when available. Covers both drawer generations: the
/// old mwc drawer (`.mdc-drawer` + `--mdc-drawer-width`) and the current
/// one, whose shadow holds `div.sidebar-shell` next to `div.app-content`.
/// Idempotent; re-applies on HA's client-side route changes and keeps a
/// MutationObserver so late-mounted panels get styled too. Pass
/// `apply=false` (or both hides false) to tear the styles back out.
String kioskModeScript({
  required bool apply,
  bool hideHeader = true,
  bool hideSidebar = true,
}) =>
    '''
(function () {
  const ID = 'kiosk-satellite-kiosk-mode';
  const APPLY = $apply;
  const HIDE_HEADER = $hideHeader;
  const HIDE_SIDEBAR = $hideSidebar;

  function styleInto(root, css) {
    if (!root) return;
    let el = root.getElementById ? root.getElementById(ID) : null;
    if (!css) { if (el) el.remove(); return; }
    if (!el) {
      el = document.createElement('style');
      el.id = ID;
      root.appendChild(el);
    }
    el.textContent = css;
  }

  function apply() {
    const ha = document.querySelector('home-assistant');
    const main = ha && ha.shadowRoot
      && ha.shadowRoot.querySelector('home-assistant-main');
    if (!main || !main.shadowRoot) return false;

    const sidebarCss = (APPLY && HIDE_SIDEBAR)
      ? ':host{--mdc-drawer-width:0px!important;}' +
        'ha-drawer{--mdc-drawer-width:0px!important;}' +
        'ha-sidebar{display:none!important;}'
      : '';
    styleInto(main.shadowRoot, sidebarCss);

    // The drawer keeps its own shadow root; the sidebar container lives
    // there, out of reach of the styles above. Old generation: aside
    // .mdc-drawer. Current generation: div.sidebar-shell beside
    // div.app-content.
    const drawer = main.shadowRoot.querySelector('ha-drawer');
    if (drawer && drawer.shadowRoot) {
      styleInto(drawer.shadowRoot, (APPLY && HIDE_SIDEBAR)
        ? '.mdc-drawer,.sidebar-shell{display:none!important;' +
          'width:0!important;min-width:0!important;border:0!important;}' +
          '.mdc-drawer-app-content,.app-content{margin-left:0!important;' +
          'margin-inline-start:0!important;padding-left:0!important;' +
          'padding-inline-start:0!important;}'
        : '');
    }

    // The dashboard header (toolbar + view tabs) in every lovelace root.
    const roots = main.shadowRoot.querySelectorAll('ha-panel-lovelace');
    let styled = false;
    roots.forEach(function (panel) {
      const huiRoot = panel.shadowRoot
        && panel.shadowRoot.querySelector('hui-root');
      if (huiRoot && huiRoot.shadowRoot) {
        styleInto(huiRoot.shadowRoot, (APPLY && HIDE_HEADER)
          ? '.header,.toolbar,app-header,ch-header{display:none!important;}' +
            '#view,hui-view{padding-top:0!important;min-height:100vh!important;}'
          : '');
        styled = true;
      }
    });
    return styled;
  }

  // One live instance per document. This script is re-run on every load and
  // on every settings change; without the handoff an older run's watchers
  // would keep re-asserting their stale choices over the new ones.
  const prev = window.__ksKioskMode;
  if (prev) {
    if (prev.timer) clearInterval(prev.timer);
    if (prev.observer) prev.observer.disconnect();
    if (prev.onLocation) {
      window.removeEventListener('location-changed', prev.onLocation);
    }
  }
  const state = window.__ksKioskMode =
      { timer: null, observer: null, onLocation: null };

  // Nothing to hide: strip whatever a previous run styled and stand down.
  if (!APPLY || (!HIDE_HEADER && !HIDE_SIDEBAR)) { apply(); return; }

  // The observer can only attach once <home-assistant> has a shadow root,
  // which on a cold load is well after this script runs. It watches the app
  // root for remounts; panel internals live in deeper shadow roots it cannot
  // see, so route changes are covered by HA's location-changed event instead.
  function ensureObserver() {
    if (state.observer) return;
    const ha = document.querySelector('home-assistant');
    if (!ha || !ha.shadowRoot) return;
    state.observer = new MutationObserver(function () { apply(); });
    state.observer.observe(ha.shadowRoot, { childList: true, subtree: true });
  }

  // Poll until the dashboard is styled. A cold start can spend a long time
  // booting (auth restore, service worker, a slow tablet), so the window is
  // generous; the cap only exists for non-dashboard pages, where the
  // observer and the location listener keep covering later navigation.
  let n = 0;
  state.timer = setInterval(function () {
    ensureObserver();
    if ((apply() && state.observer) || ++n > 240) clearInterval(state.timer);
  }, 250);
  state.onLocation = function () { setTimeout(apply, 80); };
  window.addEventListener('location-changed', state.onLocation);
  ensureObserver();
  apply();
})();
''';
