/// HA kiosk mode: hide the Home Assistant header and/or sidebar, per the
/// user's choice (some people rely on the header tabs to move between
/// views, so neither is mandatory).
///
/// Two strategies (setting `ha.kiosk_mode`):
///   plugin — query parameters handled by the kiosk-mode HACS plugin, which
///            tracks HA's shadow-DOM changes across releases. Preferred.
///   css    — inject CSS through the shadow roots ourselves. Version-fragile
///            by nature; deliberately isolated to this file.
///   auto   — plugin params AND the CSS fallback (the params are inert
///            without the plugin; the CSS covers that case).
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

  // Retry until the panel mounts, then keep watching for route changes.
  let n = 0;
  const timer = setInterval(function () {
    if (apply() || ++n > 60) clearInterval(timer);
  }, 150);
  window.addEventListener('location-changed', function () { setTimeout(apply, 80); });
  try {
    const ha = document.querySelector('home-assistant');
    if (ha && ha.shadowRoot) {
      new MutationObserver(function () { apply(); })
        .observe(ha.shadowRoot, { childList: true, subtree: true });
    }
  } catch (e) { /* ignore */ }
})();
''';
