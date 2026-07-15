/// HA kiosk mode: hide the Home Assistant header and sidebar.
///
/// Two strategies (setting `ha.kiosk_mode`):
///   plugin — append `?kiosk`, handled by the kiosk-mode HACS plugin, which
///            tracks HA's shadow-DOM changes across releases. Preferred.
///   css    — inject CSS through the shadow roots ourselves. Version-fragile
///            by nature; deliberately isolated to this file.
///   auto   — plugin param AND the CSS fallback (the param is inert without
///            the plugin; the CSS covers that case).
library;

/// Add the kiosk-mode plugin query parameter to a dashboard URL.
String withKioskParam(String url) {
  final uri = Uri.parse(url);
  if (uri.queryParameters.containsKey('kiosk')) return url;
  return uri
      .replace(queryParameters: {...uri.queryParameters, 'kiosk': ''})
      .toString();
}

/// JS that pierces HA's shadow DOM to hide the header + sidebar without the
/// kiosk-mode plugin. Best-effort fallback for setups that don't run the
/// plugin — HA's internal DOM changes across releases, so the plugin is
/// preferred when available. Idempotent; re-applies on HA's client-side
/// route changes and keeps a MutationObserver so late-mounted panels get
/// styled too. Pass `apply=false` to tear the styles back out (live toggle).
String kioskModeScript({required bool apply}) => '''
(function () {
  const ID = 'kiosk-satellite-kiosk-mode';
  const APPLY = $apply;

  function styleInto(root, css) {
    if (!root) return;
    let el = root.getElementById ? root.getElementById(ID) : null;
    if (!APPLY) { if (el) el.remove(); return; }
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

    // Collapse the docked sidebar drawer to zero width and hide its content.
    styleInto(main.shadowRoot,
      ':host{--mdc-drawer-width:0px!important;}' +
      'ha-drawer{--mdc-drawer-width:0px!important;}' +
      'ha-drawer .mdc-drawer{width:0!important;min-width:0!important;border:0!important;}' +
      'ha-drawer .mdc-drawer-app-content{margin-left:0!important;margin-inline-start:0!important;}' +
      'ha-sidebar{display:none!important;}');

    // Hide the dashboard header (toolbar + view tabs) in every lovelace root.
    const roots = main.shadowRoot.querySelectorAll('ha-panel-lovelace');
    let styled = false;
    roots.forEach(function (panel) {
      const huiRoot = panel.shadowRoot
        && panel.shadowRoot.querySelector('hui-root');
      if (huiRoot && huiRoot.shadowRoot) {
        styleInto(huiRoot.shadowRoot,
          '.header,.toolbar,app-header,ch-header{display:none!important;}' +
          '#view,hui-view{padding-top:0!important;min-height:100vh!important;}');
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
