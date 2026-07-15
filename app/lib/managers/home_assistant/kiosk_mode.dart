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

/// JS that pierces HA's shadow DOM and hides the header + sidebar. Injected
/// at document end, re-applied on HA's route changes.
const kioskModeCss = '''
(function () {
  const STYLE_ID = 'kiosk-satellite-kiosk-mode';

  function inject() {
    try {
      const ha = document.querySelector('home-assistant');
      const main = ha && ha.shadowRoot
        && ha.shadowRoot.querySelector('home-assistant-main');
      if (!main || !main.shadowRoot) return false;

      if (!main.shadowRoot.getElementById(STYLE_ID)) {
        const style = document.createElement('style');
        style.id = STYLE_ID;
        style.textContent =
          'ha-drawer { --mdc-drawer-width: 0 !important; }' +
          'ha-sidebar { display: none !important; }';
        main.shadowRoot.appendChild(style);
      }

      const panel = main.shadowRoot.querySelector('ha-drawer partial-panel-resolver');
      const lovelace = panel && panel.querySelector('ha-panel-lovelace');
      const root = lovelace && lovelace.shadowRoot
        && lovelace.shadowRoot.querySelector('hui-root');
      if (root && root.shadowRoot && !root.shadowRoot.getElementById(STYLE_ID)) {
        const style = document.createElement('style');
        style.id = STYLE_ID;
        style.textContent =
          '.header { display: none !important; }' +
          '#view { min-height: 100vh !important; padding-top: 0 !important; }';
        root.shadowRoot.appendChild(style);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  let attempts = 0;
  const timer = setInterval(function () {
    if (inject() || ++attempts > 50) clearInterval(timer);
  }, 200);
  window.addEventListener('location-changed', function () {
    setTimeout(inject, 100);
  });
})();
''';
