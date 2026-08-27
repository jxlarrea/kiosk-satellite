import { api } from './core.js';
import { readOnlyRow } from './device.js';
import { messageBox, modalShell } from './widgets.js';

// The navigation path of a view within a dashboard: "url_path/route", or
// just the dashboard when the route is empty (its default first view).
export function viewPath(urlPath, route) {
  return route ? `${urlPath}/${route}` : urlPath;
}

// One dashboard's views (title + route), or null for a strategy dashboard
// whose view list cannot be read.
export async function fetchViews(urlPath) {
  try {
    const r = await (await api('/api/commands/haListDashboardViews', {
      method: 'POST', body: JSON.stringify({ url_path: urlPath }) })).json();
    if (r.ok && Array.isArray(r.data)) return r.data;
  } catch (_) {}
  return null;
}

// The "Change view" modal: a dashboard's views as radio rows. Resolves to the
// chosen route, or null if cancelled.
export function pickView(urlPath, views, currentRoute) {
  return new Promise((resolve) => {
    const { back, body, foot } = modalShell({
      title: 'Choose a view',
      onDismiss: () => { back.remove(); resolve(null); },
    });
    views.forEach((v) => {
      const route = String(v.route);
      body.appendChild(radioRow(v.title || route, viewPath(urlPath, route),
        route === currentRoute, () => { back.remove(); resolve(route); }));
    });
    const cancel = document.createElement('button');
    cancel.className = 'btn-text';
    cancel.textContent = 'Cancel';
    cancel.addEventListener('click', () => { back.remove(); resolve(null); });
    foot.appendChild(cancel);
  });
}

// The update filter's watched-entities modal: the current allowlist with
// friendly names, fetched live from the page (window.__ksWs.allow).
export async function showWatchedEntities() {
  let items = null;
  try {
    const r = await (await api('/api/commands/evalJs', { method: 'POST',
      body: JSON.stringify({ code: '(function(){var S=window.__ksWs;if(!S||!S.allow)return "null";'
        + 'var h=document.querySelector("home-assistant");var st=(h&&h.hass&&h.hass.states)||{};'
        + 'var out=Array.from(S.allow).map(function(id){var s=st[id];'
        + 'return {id:id,name:(s&&s.attributes&&s.attributes.friendly_name)||""};});'
        + 'out.sort(function(a,b){return (a.name||a.id).localeCompare(b.name||b.id);});'
        + 'return JSON.stringify(out);})()' }) })).json();
    items = JSON.parse(r.data);
    if (typeof items === 'string') items = JSON.parse(items);
  } catch (_) {}
  if (!Array.isArray(items) || !items.length) {
    messageBox({ title: 'Watched entities', message: 'The entity list is not available right now.' });
    return;
  }
  const { back, body, foot } = modalShell({
    title: `Watched entities (${items.length})`,
    width: 520,
    onDismiss: () => back.remove(),
  });
  items.forEach((it) => body.appendChild(readOnlyRow(it.name || it.id, it.name ? it.id : '', '')));
  const done = document.createElement('button');
  done.className = 'btn-primary';
  done.textContent = 'Close';
  done.addEventListener('click', () => back.remove());
  foot.appendChild(done);
}

// A pick-one row (dashboard, satellite): a real radio control leading the
// row, like the device's RadioListTile. The whole row is the click target;
// the input is the visual, kept in sync by each re-render.
export function radioRow(name, desc, selected, onPick) {
  const row = readOnlyRow(name, desc, '');
  row.querySelector('span').remove();
  const r = document.createElement('input');
  r.type = 'radio';
  r.checked = selected;
  r.style.pointerEvents = 'none';
  row.prepend(r);
  row.style.cursor = 'pointer';
  row.addEventListener('click', onPick);
  return row;
}
