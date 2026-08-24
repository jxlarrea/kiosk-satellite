import { $, api, cmd, state } from './core.js';
import { readOnlyRow } from './device.js';
import { loadSettings } from './settings.js';

/* Overlay grant notice: mirror of the device's row directly under
   "Auto-reload on error", shown only while that switch is on and the
   "display over other apps" grant is missing - without it the crash

   self-heal cannot bring the kiosk back on Android 10+. */
export async function updateAutoReloadOverlayNotice() {
  const autoReload = (state.settings || [])
    .find((s) => s.key === 'browser.auto_reload_on_error');
  if (!autoReload || autoReload.value !== true) return;
  let granted;
  try {
    const res = await (await api('/api/commands/getSystemPermissions', { method: 'POST', body: '{}' })).json();
    granted = !!(res.data || {}).displayOverOtherApps;
  } catch (_) { return; }
  if (granted) return;
  const tab = document.getElementById('tab-browser');
  const anchor = [...tab.querySelectorAll('.row')]
    .find((r) => r.querySelector('.name')?.textContent === 'Auto-reload on error');
  if (!anchor || tab.querySelector('.autoreload-overlay-notice')) return;
  const row = readOnlyRow('"Display over other apps" permission missing',
    'Without it the kiosk cannot bring itself back after a crash. The grant screen appears on the tablet.', '');
  row.classList.add('autoreload-overlay-notice');
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = 'Grant on device';
  btn.style.cssText = 'flex-shrink:0;';
  btn.addEventListener('click', async () => {
    btn.disabled = true;
    try {
      await api('/api/commands/requestOsPermissions', { method: 'POST',
        body: JSON.stringify({ which: ['overlay'] }) });
    } catch (_) {}
    for (let i = 0; i < 30; i++) {
      await new Promise((r) => setTimeout(r, 2500));
      try {
        const res = await (await api('/api/commands/getSystemPermissions', { method: 'POST', body: '{}' })).json();
        if ((res.data || {}).displayOverOtherApps) { row.remove(); return; }
      } catch (_) {}
    }
    btn.disabled = false;
  });
  row.appendChild(btn);
  anchor.insertAdjacentElement('afterend', row);
}

/* Immich validate row: mirror of the device's row directly under the API
   key. Every Immich row below gates on immich_validated, so a successful
   validation reloads the tab and they appear on their own. */
export function updateImmichValidateRow() {
  const byKey = Object.fromEntries((state.settings || []).map((s) => [s.key, s]));
  if (byKey['screensaver.mode']?.value !== 'immich') return;
  const tab = document.getElementById('tab-screensaver');
  const anchor = [...tab.querySelectorAll('.row')]
    .find((r) => r.querySelector('.name')?.textContent === 'API key');
  if (!anchor || tab.querySelector('.immich-validate-row')) return;
  const validated = byKey['screensaver.immich_validated']?.value === true;
  const row = readOnlyRow('Validate connection',
    validated ? 'Connected'
      : 'Not validated yet. The settings below unlock once the connection checks out.', '');
  row.classList.add('immich-validate-row');
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = 'Validate';
  btn.style.cssText = 'flex-shrink:0;';
  btn.addEventListener('click', async () => {
    btn.disabled = true; btn.textContent = 'Checking…';
    let res;
    try { res = await (await api('/api/commands/immichValidate', { method: 'POST', body: '{}' })).json(); }
    catch (_) { res = { ok: false, error: 'The device did not answer.' }; }
    if (res.ok) { await loadSettings(); return; }
    btn.disabled = false; btn.textContent = 'Validate';
    row.querySelector('.desc').textContent = res.error || 'Validation failed.';
  });
  row.appendChild(btn);
  anchor.insertAdjacentElement('afterend', row);
}

/* MQTT validate row: mirror of the device's row, under the last credential
   field. Unlike Home Assistant and Immich it gates nothing — it answers
   "does the broker accept these settings?" without reading the log. */
export function updateMqttValidateRow() {
  const tab = document.getElementById('tab-mqtt');
  const anchor = [...tab.querySelectorAll('.row')]
    .find((r) => r.querySelector('.name')?.textContent === 'Password');
  if (!anchor || tab.querySelector('.mqtt-validate-row')) return;
  const row = readOnlyRow('Validate connection',
    'Check the broker accepts these settings.', '');
  row.classList.add('mqtt-validate-row');
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = 'Validate';
  btn.style.cssText = 'flex-shrink:0;';
  btn.addEventListener('click', async () => {
    btn.disabled = true; btn.textContent = 'Checking…';
    let res;
    try { res = await (await api('/api/commands/mqttValidate', { method: 'POST', body: '{}' })).json(); }
    catch (_) { res = { ok: false, error: 'The device did not answer.' }; }
    btn.disabled = false; btn.textContent = 'Validate';
    row.querySelector('.desc').textContent = res.ok
      ? 'Connected' : (res.error || 'Validation failed.');
  });
  row.appendChild(btn);
  anchor.insertAdjacentElement('afterend', row);
}

/* Music Assistant validate row: mirror of the device's row, under the auth
   token on the Sendspin tab. Opening the API and authenticating is the only
   way to tell a wrong port from a wrong token. */
export function updateMaValidateRow() {
  const tab = document.getElementById('tab-sendspin');
  if (!tab) return;
  const anchor = [...tab.querySelectorAll('.row')]
    .find((r) => r.querySelector('.name')?.textContent === 'Auth token');
  if (!anchor || tab.querySelector('.ma-validate-row')) return;
  const row = readOnlyRow('Validate connection',
    'Check the address and token before turning on the shortcut or lyrics.', '');
  row.classList.add('ma-validate-row');
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = 'Validate';
  btn.style.cssText = 'flex-shrink:0;';
  btn.addEventListener('click', async () => {
    btn.disabled = true; btn.textContent = 'Checking\u2026';
    let res;
    try { res = await (await api('/api/commands/maValidate', { method: 'POST', body: '{}' })).json(); }
    catch (_) { res = { ok: false, error: 'The device did not answer.' }; }
    btn.disabled = false; btn.textContent = 'Validate';
    const version = res.ok ? (res.data || {}).version : null;
    row.querySelector('.desc').textContent = res.ok
      ? (version ? `Connected to Music Assistant ${version}` : 'Connected')
      : (res.error || 'Validation failed.');
  });
  row.appendChild(btn);
  anchor.insertAdjacentElement('afterend', row);
}

/* Which Music Assistant player the Now Playing card follows (issue #265):
   this device's own Sendspin player, or any player the server offers.
   Mirror of the device's picker row, under the validate row; the list is
   the server's, fetched through the maPlayers command. */
export async function updateMaPlayerRow() {
  const tab = document.getElementById('tab-sendspin');
  if (!tab) return;
  const anchor = tab.querySelector('.ma-validate-row');
  if (!anchor || tab.querySelector('.ma-player-row')) return;
  const byKey = Object.fromEntries(
    (state.settings || []).map((s) => [s.key, s]));
  const currentId = byKey['sendspin.ma_player']?.value || '';
  const currentName = byKey['sendspin.ma_player_name']?.value || '';
  const row = readOnlyRow('Player to control',
    'Show and control another Music Assistant player instead of this device.',
    '');
  row.classList.add('ma-player-row');
  row.querySelector('span')?.remove();
  const sel = document.createElement('select');
  sel.className = 'field';
  sel.style.cssText = 'flex-shrink:0; max-width:220px;';
  const add = (value, label) => {
    const option = document.createElement('option');
    option.value = value; option.textContent = label;
    option.selected = value === currentId;
    sel.appendChild(option);
    return option;
  };
  add('', 'This device');
  if (currentId) add(currentId, currentName || currentId);
  row.appendChild(sel);
  anchor.insertAdjacentElement('afterend', row);
  // Say what the pick just did to this device, mirroring the device's
  // warning row. The full re-render on change rebuilds it as the pick
  // comes and goes.
  if (currentId) {
    const note = document.createElement('div');
    note.className = 'row ma-player-warn';
    note.style.cssText = 'font-size:12.5px; color:var(--warn);';
    note.textContent = "WARNING: This device's own player is disconnected "
      + 'from Music Assistant while another player is controlled.';
    row.insertAdjacentElement('afterend', note);
  }
  let res;
  try { res = await (await api('/api/commands/maPlayers', { method: 'POST', body: '{}' })).json(); }
  catch (_) { res = { ok: false }; }
  if (res.ok && Array.isArray(res.data)) {
    // Rebuild from the live list, keeping the selection.
    sel.textContent = '';
    add('', 'This device');
    let seen = false;
    for (const p of res.data) {
      if (p.id === currentId) seen = true;
      add(p.id, p.available === false ? `${p.name} (offline)` : p.name);
    }
    if (currentId && !seen) add(currentId, currentName || currentId);
  }
  sel.addEventListener('change', async () => {
    const name = sel.value
      ? (res.ok && (res.data.find((p) => p.id === sel.value) || {}).name)
        || sel.options[sel.selectedIndex].textContent
      : '';
    // player_active mirrors what the device computes: the card rows gate
    // on it (local enabled OR remote followed).
    const active = sel.value !== ''
      || byKey['sendspin.enabled']?.value === true;
    await api('/api/settings', { method: 'PATCH', body: JSON.stringify({
      'sendspin.ma_player': sel.value,
      'sendspin.ma_player_name': name,
      'sendspin.player_active': active,
    }) });
    // The pick flips rows across cards (lyrics here, the whole local
    // player group next door), which syncGatedRows cannot place; take
    // the full re-render.
    await loadSettings();
  });
}

/* Both notices land between the Screen card and the Audio Volume heading,
   mirroring where the device page puts them; before the settings have
   rendered there is no heading yet and they simply append. */
export function insertAfterScreenCard(...els) {
  const root = document.getElementById('tab-screenaudio');
  const anchor = [...root.querySelectorAll('h2.card-title')]
    .find((h) => h.textContent === 'Audio Volume');
  if (anchor) anchor.before(...els); else root.append(...els);
}

/* The always-on display notice on the Screen & Audio tab, mirroring the
   device's card. Shown only where a screen-off leaves the panel showing a
   dim lock screen, which no app can override and which is why the Home
   Assistant screen entity withdraws itself there (issue #51). */
export async function updateAmbientDisplayNotice() {
  let ambient = false;
  try {
    const res = await (await api('/api/commands/getAmbientDisplay', { method: 'POST', body: '{}' })).json();
    ambient = res.data === true;
  } catch (_) { return; }
  const root = document.getElementById('tab-screenaudio');
  const existing = root.querySelector('.ambient-display-card');
  if (!ambient) { root.querySelectorAll('.ambient-display-card').forEach((el) => el.remove()); return; }
  if (existing) return;
  const heading = document.createElement('h2');
  heading.className = 'card-title ambient-display-card';
  heading.textContent = 'Always-on display';
  const card = document.createElement('div');
  card.className = 'card ambient-display-card';
  card.appendChild(readOnlyRow('This device keeps a dim clock on',
    'Turning the screen off puts the device to sleep, but the always-on display lights the lock screen back up and no app can stop it. Turn off "Always show time and info" in Android settings under Display, near the lock screen options; some ROMs call it always-on display. The Home Assistant screen entity stays unavailable until you do.', ''));
  insertAfterScreenCard(heading, card);
}

/* Brightness grant notices: shown under the dashboard slider and on the
   Screen & Audio tab only while "Modify system settings" is missing on the
   device. Without it the slider falls back to dimming the app window; the
   panel's system brightness (what the MQTT entity reports) never moves. */
export async function updateBrightnessGrantNotices() {
  let granted;
  try {
    const res = await (await api('/api/commands/getSystemPermissions', { method: 'POST', body: '{}' })).json();
    granted = !!(res.data || {}).writeSettings;
  } catch (_) { return; }
  $('#brightnessGrantRow').style.display = granted ? 'none' : '';
  const root = document.getElementById('tab-screenaudio');
  const existing = root.querySelector('.brightness-grant-card');
  if (granted) { root.querySelectorAll('.brightness-grant-card').forEach((el) => el.remove()); return; }
  if (existing) return;
  const heading = document.createElement('h2');
  heading.className = 'card-title brightness-grant-card';
  heading.textContent = 'Permission';
  const card = document.createElement('div');
  card.className = 'card brightness-grant-card';
  card.appendChild(readOnlyRow('Brightness is using a fallback',
    'Without the "Modify system settings" permission, brightness changes only dim the app instead of setting the panel\'s actual brightness.', ''));
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = 'Grant on device';
  btn.style.cssText = 'margin:0 0 14px';
  btn.addEventListener('click', requestBrightnessGrant);
  card.appendChild(btn);
  insertAfterScreenCard(heading, card);
}

// The grant is Android's own settings screen on the tablet: launch it there,
// then keep re-reading until it lands so the notices dismiss themselves.
export async function requestBrightnessGrant() {
  try {
    await api('/api/commands/requestOsPermissions', { method: 'POST',
      body: JSON.stringify({ which: ['writeSettings'] }) });
  } catch (_) {}
  for (let i = 0; i < 30; i++) {
    await new Promise((r) => setTimeout(r, 2500));
    try {
      const res = await (await api('/api/commands/getSystemPermissions', { method: 'POST', body: '{}' })).json();
      if ((res.data || {}).writeSettings) break;
    } catch (_) {}
  }
  updateBrightnessGrantNotices();
}
document.querySelector('.js-brightness-grant')
  .addEventListener('click', requestBrightnessGrant);

$('#brightness').addEventListener('input', (e) =>
  $('#brightnessValue').textContent = `${e.target.value}%`);
$('#brightness').addEventListener('change', (e) =>
  cmd('setBrightness', { level: e.target.value / 100 }));
/* The free Load URL box this replaced let an admin point a locked kiosk at
   any page on the internet; a picker over the instance's own dashboard
   views navigates without opening that door. Same list, same paths, same
   command as the rotation picker and the MQTT Dashboard select. */
export async function loadViewJump() {
  const sel = $('#viewJump');
  try {
    if (!state.dashboardsCache) {
      state.dashboardsCache = (await (await api('/api/commands/haListDashboards', {
        method: 'POST', body: '{}' })).json()).data || [];
    }
    const dashboards = state.dashboardsCache;
    sel.innerHTML = '';
    const ph = document.createElement('option');
    ph.value = '';
    ph.textContent = 'Pick a dashboard view…';
    sel.appendChild(ph);
    for (const d of dashboards) {
      let views = [];
      try {
        const r = await (await api('/api/commands/haListDashboardViews', {
          method: 'POST', body: JSON.stringify({ url_path: d.url_path }) })).json();
        if (r.ok && Array.isArray(r.data) && r.data.length) views = r.data;
      } catch (_) {}
      // Auto-generated and strategy dashboards store no view list; their
      // bare path resolves the default view, same as the rotation picker.
      if (!views.length) views = [{ title: 'Default view', route: '' }];
      const group = document.createElement('optgroup');
      group.label = d.title || d.url_path;
      for (const v of views) {
        const o = document.createElement('option');
        o.value = v.route ? `${d.url_path}/${v.route}` : d.url_path;
        o.textContent = v.title || v.route || 'Default view';
        group.appendChild(o);
      }
      sel.appendChild(group);
    }
    sel.disabled = sel.options.length <= 1;
    if (sel.disabled) sel.options[0].textContent = 'No dashboards found';
  } catch (_) {
    sel.options[0].textContent = 'Views unavailable';
  }
}
$('#viewJump').addEventListener('change', async (e) => {
  const path = e.target.value;
  if (!path) return;
  await cmd('haNavigate', { path });
  // A jump control, not a state display: back to the placeholder so the
  // row never claims a view the tablet may have since navigated away from.
  e.target.value = '';
});
$('#refreshShot').addEventListener('click', loadScreenshot);
export async function loadScreenshot() {
  try {
    const res = await api('/api/screenshot');
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const wrap = $('#shotWrap');
    let img = wrap.querySelector('img');
    if (!img) {
      wrap.innerHTML = '';
      img = document.createElement('img');
      // Size the box to the screenshot's own aspect once it arrives (a
      // portrait phone shot must not be squeezed into a 16/10 landscape box).
      img.addEventListener('load', () => wrap.classList.add('free'));
      wrap.appendChild(img);
    }
    const old = img.src; img.src = url; if (old) URL.revokeObjectURL(old);
  } catch (_) { /* ignore */ }
}
