import { isHeadless } from './headless.js';
import { cameraStreamsError } from './localization.js';
import { overviewLabel, overviewMessageBox, overviewModalShell } from './overview_labels.js';
import { mediaText, mediaError, deviceText, t, screenAudioText, screensaverText, immichError, overviewText } from './localization.js';
import { receiveUpdate, watchUpdates } from './live.js';
import { $, api, cmd, state } from './core.js';
import { readOnlyRow } from './device.js';
import { INTRO_INFO_ICON, hintRow, introRow, showToast } from './widgets.js';
import { loadSettings } from './settings.js';
import { radioRow } from './views.js';
import { currentDashboardPath, dashboardField } from './dashboard_picker.js';
import { PLAYER_ICONS, cachedList, fixedPlayerSpec, pickField, pickItem, playerSpec } from './entity_picker.js';
import { messageBox, modalShell } from './widgets.js';

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
  const anchor = tab.querySelector('[data-key="browser.auto_reload_on_error"]');
  if (!anchor || tab.querySelector('.autoreload-overlay-notice')) return;
  const row = readOnlyRow(t('browserCrashPermissionMissing'), t('browserCrashPermissionRemoteHelp'), '');
  row.classList.add('autoreload-overlay-notice');
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = deviceText('Grant on device');
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
  const anchor = tab.querySelector('[data-key="screensaver.immich_api_key"]');
  if (!anchor || tab.querySelector('.immich-validate-row')) return;
  const validated = byKey['screensaver.immich_validated']?.value === true;
  const row = readOnlyRow(screensaverText('Validate connection'),
    validated ? screensaverText('Connected')
      : screensaverText('Not validated yet. The settings below unlock once the connection checks out.'), '');
  row.classList.add('immich-validate-row');
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = screensaverText('Validate');
  btn.style.cssText = 'flex-shrink:0;';
  btn.addEventListener('click', async () => {
    btn.disabled = true; btn.textContent = screensaverText('Checking…');
    let res;
    try { res = await (await api('/api/commands/immichValidate', { method: 'POST', body: '{}' })).json(); }
    catch (_) { res = { ok: false, error: screensaverText('The device did not answer.') }; }
    if (res.ok) { await loadSettings(); return; }
    btn.disabled = false; btn.textContent = screensaverText('Validate');
    row.querySelector('.desc').textContent = res.error ? immichError(res.error) : screensaverText('Validation failed.');
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
  const anchor = tab.querySelector('[data-key="sendspin.ma_token"]');
  if (!anchor || tab.querySelector('.ma-validate-row')) return;
  const row = readOnlyRow(mediaText('Validate connection'),
    mediaText('Check the address and token before turning on the shortcut or lyrics.'), '');
  row.classList.add('ma-validate-row');
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = mediaText('Validate');
  btn.style.cssText = 'flex-shrink:0;';
  btn.addEventListener('click', async () => {
    btn.disabled = true; btn.textContent = mediaText('Checking\u2026');
    let res;
    try { res = await (await api('/api/commands/maValidate', { method: 'POST', body: '{}' })).json(); }
    catch (_) { res = { ok: false, error: 'The device did not answer.' }; }
    btn.disabled = false; btn.textContent = mediaText('Validate');
    const version = res.ok ? (res.data || {}).version : null;
    row.querySelector('.desc').textContent = res.ok
      ? (version ? t('mediaConnectedVersion', {version}) : mediaText('Connected'))
      : mediaError(res.error || 'Validation failed.');
  });
  row.appendChild(btn);
  anchor.insertAdjacentElement('afterend', row);
}

/* This device's Local Media Session: whichever other app plays on it
   (issue #722), the device source's second player beside Sendspin. */
const LOCAL_SESSION = 'session:*';
const LOCAL_SESSION_NAME = 'Local Media Session';
/* And its AirPlay receiver, the third: a name no language translates. */
const AIRPLAY = 'airplay';
const AIRPLAY_NAME = 'AirPlay';

/* Which player of the picked source the Now Playing surfaces follow
   (issue #265). The definition renders as a text field; this swaps in a
   select fed by the mediaPlayers command for that source, or this device's
   own two players, and puts the device's warning under it while the
   Sendspin player is offline. */
export async function updatePlayerRow() {
  const tab = document.getElementById('tab-sendspin');
  if (!tab) return;
  // What every source has in common, said once at the top of the page.
  // Both surfaces it names need a screen.
  if (!isHeadless() && !tab.querySelector('.media-player-intro')) {
    const intro = document.createElement('div');
    intro.className = 'card media-player-intro';
    intro.appendChild(introRow(INTRO_INFO_ICON, '', mediaText('The floating player and Now Playing show only while '
      + 'the picked player has a track playing or a queue loaded. With nothing '
      + 'playing or queued, neither appears.')));
    tab.prepend(intro);
  }
  const byKey = Object.fromEntries(
    (state.settings || []).map((s) => [s.key, s]));
  const source = byKey['sendspin.player_source']?.value || '';
  updateSessionPermissions(tab, !source && byKey['sendspin.player']?.value === LOCAL_SESSION);
  const row = tab.querySelector('[data-key="sendspin.player"]');
  if (!row) return;
  if (row.playerSource === source && row.refreshPlayer) {
    row.refreshPlayer();
    return;
  }
  row.stopPlayerWatch?.();
  row.playerSource = source;
  row.querySelectorAll('input, select, .ep-field').forEach(el => el.remove());
  row.classList.add('dp-field-row');
  // The entity picker over the source's players, or this device's own three.
  const spec = source ? playerSpec(source) : fixedPlayerSpec('players:local', [
    { id: '', name: mediaText('Sendspin Player'), iconPath: PLAYER_ICONS.speaker,
      group: '', available: true, raw: {} },
    { id: AIRPLAY, name: AIRPLAY_NAME, iconPath: PLAYER_ICONS.airplay,
      group: '', available: true, raw: {} },
    { id: LOCAL_SESSION, name: mediaText(LOCAL_SESSION_NAME), iconPath: PLAYER_ICONS.session,
      group: '', available: true, raw: {} },
  ]);
  const titles = { ma: 'Music Assistant player', ha: 'Home Assistant media player', sonos: 'Sonos room' };
  const picked = () => {
    const settings = Object.fromEntries((state.settings || []).map(s => [s.key, s.value]));
    return { id: settings['sendspin.player'] || '', name: settings['sendspin.player_name'] || '' };
  };
  let field = null;
  const choose = async () => {
    const { id } = picked();
    const out = await pickItem({
      title: source ? mediaText(titles[source] || 'Player') : (byKey['sendspin.player']?.title || ''),
      spec, selected: source ? (id || null) : id,
    });
    if (!out || (out.id ?? '') === id) return;
    const next = out.id ?? '';
    // Stored in English like every other name the pick keeps.
    const name = next === LOCAL_SESSION ? LOCAL_SESSION_NAME
      : next === AIRPLAY ? AIRPLAY_NAME
      : next ? (cachedList(spec.key)?.items.find(p => p.id === next)?.name || next) : '';
    const values = {
      'sendspin.player': next,
      'sendspin.player_name': name,
      'sendspin.player_active': !!next || !!source
        || byKey['sendspin.enabled']?.value === true,
    };
    try {
      const response = await api('/api/settings', { method: 'PATCH', body: JSON.stringify(values) });
      const result = await response.json();
      if (!response.ok || !result.ok) throw new Error(result.error || 'Could not save the player.');
      for (const setting of state.settings || []) {
        if (setting.key in values) setting.value = values[setting.key];
      }
    } catch (error) {
      showToast({ title: mediaText('Could not select player'), message: mediaError(error.message), kind: 'error' });
    }
    paint();
  };
  const paint = () => {
    if (!row.isConnected && field) return;
    const { id, name } = picked();
    const localSession = !source && id === LOCAL_SESSION;
    const airplay = !source && id === AIRPLAY;
    const fresh = pickField({
      spec, value: id,
      placeholder: mediaText(source ? 'Pick a player' : 'Sendspin Player'),
      // Only the Local Media Session's name is the app's to translate; a
      // player's own name stays exactly as the source sent it.
      fallbackLabel: name === LOCAL_SESSION_NAME ? mediaText(name) : (name || null),
      flagMissing: false,
      // This device's Sendspin player is the empty pick.
      emptyIsPick: !source,
      onClick: choose,
    });
    if (field) field.el.replaceWith(fresh.el); else row.appendChild(fresh.el);
    field = fresh;
    updateSessionPermissions(tab, localSession);
    tab.querySelector('.player-warn')?.remove();
    const message = offlineNotice(source, id, name);
    if (message) {
      const warning = hintRow(message, { warn: true });
      warning.classList.add('player-warn', 'divided');
      row.insertAdjacentElement('afterend', warning);
    }
  };
  row.refreshPlayer = paint;
  row.updateSetting = () => { paint(); return true; };
  row.stopPlayerWatch = null;
  paint();
}

/* What the pick turns off on this device, under the Player row: the
   Sendspin player and the AirPlay receiver, each only while switched on and
   not the pick itself. Nothing for a pick that leaves both as they were. The
   device draws the same (settings_screen.dart, _offlineNotice). */
function offlineNotice(source, id, name) {
  const value = (key) => (state.settings || []).find((s) => s.key === key)?.value;
  const sourceSetting = () => (state.settings || []).find((s) => s.key === 'sendspin.player_source');
  // A followed group this device is in keeps the Sendspin player on.
  const kept = value('sendspin.kept_for');
  const sendspinOff = value('sendspin.enabled') === true && !(!source && !id)
    && !(kept && kept === value('sendspin.player'));
  const airplayOff = value('airplay.enabled') === true && !(!source && id === AIRPLAY);
  if (!sendspinOff && !airplayOff) return '';
  const player = !source && !id ? mediaText('Sendspin Player')
    : !source && id === LOCAL_SESSION ? mediaText(LOCAL_SESSION_NAME)
    : !source && id === AIRPLAY ? AIRPLAY_NAME
    // A source with no player picked yet: the source by name.
    : (name || sourceSetting()?.optionLabels?.[source] || mediaText('another player'));
  const key = sendspinOff && airplayOff ? 'mediaOfflineBoth'
    : sendspinOff ? 'mediaOfflineSendspin' : 'mediaOfflineAirplay';
  return t(key, { player });
}

/* The Local Media Session's Required system permissions group, at the end
   of the page and only while it is the pick: Android lists other apps'
   media sessions to no one without Notification access. The grant screen
   opens on the tablet, so the row polls until it flips. Mirror of the
   device's group. */
function updateSessionPermissions(tab, shown) {
  let group = tab.querySelector(':scope > .session-permissions');
  if (!shown) {
    group?.remove();
    return;
  }
  if (group) {
    tab.appendChild(group);
    return;
  }
  group = document.createElement('div');
  group.className = 'session-permissions';
  const h = document.createElement('h2');
  h.className = 'card-title';
  h.textContent = mediaText('Required system permissions');
  const card = document.createElement('div');
  card.className = 'card';
  const row = document.createElement('div');
  row.className = 'row';
  const info = document.createElement('div');
  info.className = 'info';
  info.innerHTML = '<div class="name"></div><div class="desc"></div>';
  info.querySelector('.name').textContent = mediaText('Notification access');
  info.querySelector('.desc').textContent = deviceText('Checking...');
  const status = document.createElement('span');
  status.style.whiteSpace = 'nowrap';
  row.append(info, status);
  card.appendChild(row);
  group.append(h, card);
  tab.appendChild(group);
  const poll = () => cmd('getSystemPermissions')
    .then((r) => (r.ok && r.data ? r.data.notificationAccess === true : null))
    .catch(() => null);
  const render = (ok) => {
    info.querySelector('.desc').textContent = ok === null
      ? deviceText('Status unavailable.')
      : ok ? mediaText('Now Playing can follow the apps playing on this device.')
        : mediaText('Without this Android lists no media sessions, so Now Playing cannot follow the apps playing on this device. The grant screen appears on the tablet.');
    status.textContent = ok === null ? '' : ok ? deviceText('Granted') : deviceText('Missing');
    status.style.color = ok ? 'var(--ok)' : 'var(--error)';
    row.querySelector('button')?.remove();
    if (ok !== false) return;
    const btn = document.createElement('button');
    btn.className = 'btn-ghost';
    btn.textContent = deviceText('Grant on device');
    btn.style.cssText = 'flex-shrink:0;';
    btn.addEventListener('click', async () => {
      btn.disabled = true;
      try { await cmd('requestOsPermissions', { which: ['notificationAccess'] }); } catch (_) {}
      // The grant happens on the tablet; keep reading until it lands.
      for (let i = 0; i < 30 && row.isConnected; i++) {
        await new Promise((r) => setTimeout(r, 2000));
        if (await poll()) { render(true); return; }
      }
      btn.disabled = false;
    });
    row.appendChild(btn);
  };
  poll().then(render);
  watchUpdates(['service'], () => poll().then(render), { owner: row });
}

/* The Music Library page's voice group, after its settings. Voice music
   lives in Home Assistant (the blueprint), so the group only points at the
   guide. Mirror of the device's group. */
const MUSIC_VOICE_DOCS_URL = 'https://kiosksatellite.com/docs/music-library/#playing-music-by-voice';

export function updateMusicLibraryPage() {
  const panel = document.querySelector('#tab-sendspin > .subpage[data-subpage="Music Library"]');
  if (!panel || panel.querySelector('.library-voice')) return;
  const heading = document.createElement('h2');
  heading.className = 'card-title';
  heading.textContent = t('libraryVoiceSection');
  const card = document.createElement('div');
  card.className = 'card library-voice';
  const row = document.createElement('div');
  row.className = 'row';
  row.dataset.searchId = 'x:library_voice';
  const info = document.createElement('div');
  info.className = 'info';
  info.innerHTML = '<div class="name"></div><div class="desc"></div>';
  info.querySelector('.name').textContent = t('libraryVoiceManage');
  info.querySelector('.desc').textContent = t('libraryVoiceHint');
  const link = document.createElement('a');
  link.className = 'btn-ghost';
  link.textContent = deviceText('Open guide');
  link.href = MUSIC_VOICE_DOCS_URL;
  link.target = '_blank';
  link.rel = 'noreferrer';
  row.append(info, link);
  card.appendChild(row);
  panel.append(heading, card);
}

/* The Sonos page's speakers, under its setting: every room the device
   knows with a Forget, a search of the network and an address field for a
   speaker the search cannot reach. Mirror of the device's card. */
export async function updateSonosPage() {
  const panel = document.querySelector('#tab-sendspin > .subpage[data-subpage="Sonos"]');
  if (!panel) return;
  if (panel.querySelector('.sonos-speakers')) return;
  const h = document.createElement('h2');
  h.className = 'card-title';
  h.textContent = mediaText('Speakers');
  const card = document.createElement('div');
  card.className = 'card sonos-speakers';
  panel.append(h, card);
  const list = document.createElement('div');
  card.appendChild(list);
  // The parent page's Player select was built from the speakers known
  // when the page rendered: a change to the list here rebuilds it, so a
  // speaker just added can be picked without a reload.
  const refreshPick = () => receiveUpdate('media-players');
  const render = (speakers) => {
    list.textContent = '';
    if (!speakers.length) {
      list.appendChild(readOnlyRow(mediaText('No speakers yet'),
        mediaText('Search this network or add a speaker by its address.'), ''));
    }
    for (const p of speakers) {
      // The address, and the id an automation can follow the room by.
      const r = readOnlyRow(p.name, `${p.host} · ${p.id}`, '');
      r.querySelector('span')?.remove();
      const forget = document.createElement('button');
      forget.className = 'icon-btn';
      forget.title = mediaText('Forget');
      forget.setAttribute('aria-label', mediaText('Forget'));
      forget.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 7h16"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M6 7l1 13h10l1-13"/><path d="M9 7V4h6v3"/></svg>';
      forget.addEventListener('click', async () => {
        const out = await (await api('/api/commands/sonosForget', {
          method: 'POST', body: JSON.stringify({ id: p.id }) })).json();
        if (out.ok) { render(out.data || []); refreshPick(); }
      });
      r.appendChild(forget);
      list.appendChild(r);
    }
  };
  const load = async (discover) => {
    let out;
    try {
      out = await (await api('/api/commands/sonosSpeakers', {
        method: 'POST', body: JSON.stringify({ discover }) })).json();
    } catch (_) { out = { ok: false }; }
    render(out.ok ? (out.data || []) : []);
    if (discover && out.ok) refreshPick();
    if (discover && out.ok && !(out.data || []).length) {
      showToast({ title: mediaText('No Sonos found'),
        message: mediaText('Nothing answered on this network. Add one by address.'), kind: 'warning' });
    }
  };
  const search = readOnlyRow(mediaText('Search the network'),
    mediaText('Finds Sonos speakers on this network. The speakers must be on the same VLAN as this device to be auto discovered.'), '');
  search.querySelector('span')?.remove();
  const searchBtn = document.createElement('button');
  searchBtn.className = 'btn-ghost';
  searchBtn.textContent = mediaText('Search');
  searchBtn.addEventListener('click', async () => {
    searchBtn.disabled = true; searchBtn.textContent = mediaText('Searching…');
    await load(true);
    searchBtn.disabled = false; searchBtn.textContent = mediaText('Search');
  });
  search.appendChild(searchBtn);
  card.appendChild(search);
  const addRow = readOnlyRow(mediaText('Add by address'),
    mediaText("The speaker's address on the network. The whole household is added from it."), '');
  addRow.querySelector('span')?.remove();
  const addBtn = document.createElement('button');
  addBtn.className = 'btn-primary';
  addBtn.textContent = mediaText('Add');
  addBtn.style.cssText = 'flex-shrink:0;';
  addBtn.addEventListener('click', () => {
    // The address in a modal, the way every value is entered here.
    const shell = modalShell({ title: mediaText('Add a Sonos by address'), width: 440,
      onDismiss: () => shell.close() });
    const input = document.createElement('input');
    input.className = 'field';
    input.placeholder = '192.168.1.40';
    input.style.cssText = 'width:100%;';
    shell.body.appendChild(input);
    const cancel = document.createElement('button');
    cancel.className = 'btn-text';
    cancel.textContent = mediaText('Cancel');
    cancel.addEventListener('click', () => shell.close());
    const ok = document.createElement('button');
    ok.className = 'btn-primary';
    ok.textContent = mediaText('Add');
    const submit = async () => {
      const host = input.value.trim();
      if (!host) return;
      ok.disabled = true;
      let out;
      try {
        out = await (await api('/api/commands/sonosAdd', {
          method: 'POST', body: JSON.stringify({ host }) })).json();
      } catch (_) { out = { ok: false, error: 'The device did not answer.' }; }
      ok.disabled = false;
      if (!out.ok) { showToast({ title: mediaText('No Sonos found'), message: mediaError(out.error || ''), kind: 'error' }); return; }
      shell.close();
      showToast({ title: mediaText('Sonos added'), message: (out.data || []).map((p) => p.name).join(', '), kind: 'success' });
      await load(false);
      refreshPick();
    };
    ok.addEventListener('click', submit);
    input.addEventListener('keydown', (e) => { if (e.key === 'Enter') submit(); });
    shell.foot.append(cancel, ok);
    input.focus();
  });
  addRow.appendChild(addBtn);
  card.appendChild(addRow);
  watchUpdates(['sonos'], () => load(false), { owner: card, intervalMs: 1000 });
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
  heading.textContent = screenAudioText('Always-on display');
  const card = document.createElement('div');
  card.className = 'card ambient-display-card';
  card.appendChild(readOnlyRow(screenAudioText('This device keeps a dim clock on'),
    screenAudioText('Turning the screen off puts the device to sleep, but the always-on display lights the lock screen back up and no app can stop it. Turn off "Always show time and info" in Android settings under Display, near the lock screen options; some ROMs call it always-on display. The Home Assistant screen entity stays unavailable until you do.'), ''));
  insertAfterScreenCard(heading, card);
}

/* Brightness grant notices: shown under the dashboard slider and on the
   Screen & Audio tab only while "Modify system settings" is missing on the
   device. Without it the slider falls back to dimming the app window; the
   panel's system brightness (what the ESPHome entity reports) never moves. */
export async function updateBrightnessGrantNotices() {
  let granted;
  try {
    const res = await (await api('/api/commands/getSystemPermissions', { method: 'POST', body: '{}' })).json();
    granted = !!(res.data || {}).writeSettings;
  } catch (_) { return; }
  $('#brightnessGrantRow').style.display = granted ? 'none' : '';
  // No panel to light on a device without a screen.
  if (isHeadless()) return;
  const root = document.getElementById('tab-screenaudio');
  const existing = root.querySelector('.brightness-grant-card');
  if (granted) { root.querySelectorAll('.brightness-grant-card').forEach((el) => el.remove()); return; }
  if (existing) return;
  const heading = document.createElement('h2');
  heading.className = 'card-title brightness-grant-card';
  heading.textContent = screenAudioText('Permission');
  const card = document.createElement('div');
  card.className = 'card brightness-grant-card';
  card.appendChild(readOnlyRow(screenAudioText('Brightness is using a fallback'),
    screenAudioText('Without the "Modify system settings" permission, brightness changes only dim the app instead of setting the panel\'s actual brightness.'), ''));
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = screenAudioText('Grant on device');
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
   any page on the internet; the dashboard picker over the instance's own
   views navigates without opening that door. The field shows the view on
   screen and opens the picker in go mode: a tap navigates at once and the
   view on screen reads Showing. */
// Built on first use, not at module load, so nothing here runs before
// the modules it imports are ready.
let viewJump = null;
export async function loadViewJump() {
  const base = () => (state.settings || []).find((o) => o.key === 'ha.url')?.value || '';
  if (!viewJump) {
    viewJump = dashboardField({
      title: overviewText('Go to view'),
      mode: 'go',
      showing: () => currentDashboardPath(base()),
      onPick: (path) => cmd('haNavigate', { path }),
    });
    viewJump.el.id = 'viewJump';
    $('#viewJump').replaceWith(viewJump.el);
  }
  viewJump.setValue(await currentDashboardPath(base()));
}
/* ---- Quick controls ----
   The screen, screensaver and camera view tiles are one tile each that
   reads by what the device is doing, so the dashboard offers the action
   that applies instead of a pair where one is always a no-op. The truth
   is the device's: the state snapshot at connect (and /api/info at boot)
   seeds it, the event feed moves it, and a command this page sent is not
   assumed to have worked; the tile flips when the device says so. */
export const quick = {
  screenOn: null, screensaverActive: null, cameraView: null, nowPlaying: null, intercom: null,
};

const STROKE = 'viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"';
// The off/dismiss face of each pair is the on face with a slash, the
// language the Screen off tile already spoke.
const QUICK_ICONS = {
  screenOn: `<svg ${STROKE}><circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M4.9 4.9l1.4 1.4m11.4 11.4 1.4 1.4M2 12h2m16 0h2M4.9 19.1l1.4-1.4m11.4-11.4 1.4-1.4"/></svg>`,
  screenOff: `<svg ${STROKE}><rect x="5" y="3" width="14" height="18" rx="2.5"/><path d="M4 20 20 4"/></svg>`,
  saverStart: `<svg ${STROKE}><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>`,
  saverStop: `<svg ${STROKE}><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/><path d="M4 20 20 4"/></svg>`,
  cameraShow: `<svg ${STROKE}><rect x="3" y="6.5" width="12.5" height="11" rx="2.5"/><path d="m15.5 10.5 5.5-3v9l-5.5-3"/></svg>`,
  cameraHide: `<svg ${STROKE}><rect x="3" y="6.5" width="12.5" height="11" rx="2.5"/><path d="m15.5 10.5 5.5-3v9l-5.5-3"/><path d="M4 20 20 4"/></svg>`,
};

function setTile(id, { icon, label, command }) {
  const tile = document.getElementById(id);
  if (!tile) return;
  tile.querySelector('.disc').innerHTML = QUICK_ICONS[icon];
  overviewLabel(tile.querySelector('.disc + span'), label);
  // No command means the tile's own handler takes the click (the camera
  // picker); the generic .action handler skips a tile without one.
  if (command) tile.dataset.cmd = command; else delete tile.dataset.cmd;
}

export function renderQuickControls() {
  // Unknown (a device too old to report, or a command that failed) keeps
  // the quiet-state face rather than a tile claiming something it was
  // never told: the quiet state is where a kiosk spends nearly all its
  // time, and each command is harmless when it does not apply.
  setTile('tileScreen', quick.screenOn === false
    ? { icon: 'screenOn', label: 'Screen on', command: 'screenOn' }
    : { icon: 'screenOff', label: 'Screen off', command: 'screenOff' });
  setTile('tileScreensaver', quick.screensaverActive === true
    ? { icon: 'saverStop', label: 'Dismiss screensaver', command: 'stopScreensaver' }
    : { icon: 'saverStart', label: 'Start screensaver', command: 'startScreensaver' });
  setTile('tileCameraView', quick.cameraView?.active
    ? { icon: 'cameraHide', label: 'Dismiss camera view', command: 'hideCameraView' }
    : { icon: 'cameraShow', label: 'Show camera view', command: null });
  // The Overview's screenshot badge reads the same states.
  document.dispatchEvent(new CustomEvent('ks-quick'));
}

// The snapshot: /api/info at boot and every WS `state` message. Fields a
// device does not report are left as they were, and so are the states
// named in `keep` (ws.js passes the ones an event on the same socket
// already moved past this snapshot).
export function applyQuickState(device, keep = {}) {
  if (!device) return;
  if ('screenOn' in device && !keep.screenOn) quick.screenOn = device.screenOn;
  if ('screensaverActive' in device && !keep.screensaverActive) {
    quick.screensaverActive = device.screensaverActive;
  }
  if ('cameraView' in device && !keep.cameraView) quick.cameraView = device.cameraView;
  if ('nowPlayingShown' in device && !keep.nowPlaying) quick.nowPlaying = device.nowPlayingShown;
  if ('intercomShown' in device && !keep.intercom) quick.intercom = device.intercomShown;
  renderQuickControls();
}

// Which quick-control state an event moves, for that bookkeeping.
export function quickStateOf(event) {
  if (event === 'screenon' || event === 'screenoff') return 'screenOn';
  if (event === 'screensaverstart' || event === 'screensaverstop') return 'screensaverActive';
  if (event === 'cameraview') return 'cameraView';
  return null;
}

// The diffs: the same bus events the JS API and ESPHome hear.
export function applyQuickEvent(event, data) {
  if (event === 'screenon') quick.screenOn = true;
  else if (event === 'screenoff') quick.screenOn = false;
  else if (event === 'screensaverstart') quick.screensaverActive = true;
  else if (event === 'screensaverstop') quick.screensaverActive = false;
  else if (event === 'cameraview') quick.cameraView = data || { active: false };
  else return;
  renderQuickControls();
}

// Now Playing or the intercom filling the screen: no tile of their own,
// only the screenshot badge.
export function applyFullscreenView(view, shown) {
  if (view !== 'nowPlaying' && view !== 'intercom') return;
  quick[view] = shown;
  document.dispatchEvent(new CustomEvent('ks-quick'));
}

// "Show camera view" has a question the other tiles do not: which one.
// One usable view shows straight away; several ask; none says where to
// make one. The Cameras tab has the same Show buttons per view, this is
// the shortcut from the dashboard.
async function showCameraViewFromTile() {
  const config = (await cmd('cameraGetConfig').catch(() => null))?.data;
  const views = (config?.views || []).filter((v) => (v.cameraIds || []).length);
  if (!views.length) {
    await overviewMessageBox({
      title: 'Show camera view',
      message: 'No camera view has any cameras yet. Add cameras to a view under Cameras first.',
    });
    return;
  }
  let viewId = views[0].id;
  if (views.length > 1) {
    viewId = await new Promise((resolve) => {
      const { back, body, foot } = overviewModalShell({
        title: 'Show camera view',
        onDismiss: () => { back.remove(); resolve(null); },
      });
      const names = Object.fromEntries((config.cameras || []).map((c) => [c.id, c.name]));
      for (const v of views) {
        const desc = v.cameraIds.map((id) => names[id] || id).join(', ');
        body.appendChild(radioRow(v.name, desc, false, () => { back.remove(); resolve(v.id); }));
      }
      const cancel = document.createElement('button');
      cancel.className = 'btn-text';
      overviewLabel(cancel, 'Cancel');
      cancel.addEventListener('click', () => { back.remove(); resolve(null); });
      foot.appendChild(cancel);
    });
    if (!viewId) return;
  }
  const shown = await cmd('showCameraView', { viewId }).catch(() => null);
  if (shown && shown.ok === false && shown.error) {
    await overviewMessageBox({ title: 'Could not show view', message: shown.error }, cameraStreamsError);
  }
}
document.getElementById('tileCameraView')?.addEventListener('click', () => {
  // With a view up the tile carries hideCameraView and the generic
  // handler has the click.
  if (quick.cameraView?.active) return;
  showCameraViewFromTile();
});

export async function loadScreenshot() {
  // Nothing to capture on a device without a screen.
  if (isHeadless()) return;
  try {
    const res = await api('/api/screenshot');
    if (!res.ok) return false;
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const wrap = $('#shotWrap');
    let img = wrap.querySelector('img');
    if (!img) {
      // The placeholder goes; the state badge over the frame stays.
      wrap.querySelector('.placeholder')?.remove();
      img = document.createElement('img');
      // Size the box to the screenshot's own aspect once it arrives (a
      // portrait phone shot must not be squeezed into a 16/10 landscape box).
      img.addEventListener('load', () => wrap.classList.add('free'));
      wrap.prepend(img);
    }
    const old = img.src; img.src = url; if (old) URL.revokeObjectURL(old);
    // When and what, for the Overview's "Taken ... ago" and its download.
    state.screenshotAt = Date.now();
    state.screenshotType = blob.type;
    document.dispatchEvent(new CustomEvent('ks-screenshot'));
    return true;
  } catch (_) { return false; }
}
