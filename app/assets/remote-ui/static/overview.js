import { $, api, cmd, state } from './core.js';
import { attachUpdateInstall, refreshUpdateBadge } from './device.js';
import { agoLabel } from './notices.js';
import { loadScreenshot, quick } from './panels.js';
import { permissionSpecs } from './permissions.js';
import { showTab } from './tabs.js';
import { attachSlider, messageBox, modalShell, showToast } from './widgets.js';

/* ---- Overview ----
   The first page, and for most visits the only one: what the kiosk needs
   from a person, what its screen shows, how each part of it is doing.
   Everything here reads the device's own status commands, nothing is a
   setting, so the page is rebuilt from a fresh read every time it is
   looked at and every half minute while it stays in view. Never from a
   hidden tab or another page: each read is work on the tablet. */

const TICK_MS = 5000;
// Ticks between full status reads: every 30 seconds.
const HEALTH_EVERY = 6;

function onOverview() {
  return !document.hidden
    && document.getElementById('tab-dashboard').classList.contains('active');
}
const settingVal = (k) => (state.settings || []).find((s) => s.key === k)?.value;
const settingOn = (k) => settingVal(k) === true;
// A command's data, or null for a refusal, an error or a missing answer.
const ask = (name, params) => cmd(name, params)
  .then((r) => (r && r.ok !== false && r.data !== undefined ? r.data : null))
  .catch(() => null);

const STROKE = 'viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"';
const ICONS = {
  moon: `<svg ${STROKE}><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>`,
  screenOff: `<svg ${STROKE}><rect x="5" y="3" width="14" height="18" rx="2.5"/><path d="M4 20 20 4"/></svg>`,
  camera: `<svg ${STROKE}><rect x="3" y="6.5" width="12.5" height="11" rx="2.5"/><path d="m15.5 10.5 5.5-3v9l-5.5-3"/></svg>`,
  play: `<svg ${STROKE}><path d="M8 5l10 7-10 7z"/></svg>`,
  pause: `<svg ${STROKE}><path d="M8 5v14M16 5v14"/></svg>`,
};

/* ---- Status tiles ----
   One per part of the kiosk that has a connection or an engine to keep
   up. Each opens the page where it is configured. */
const TILES = [
  ['ha', 'Home Assistant', 'homeassistant'],
  ['voice', 'Voice Satellite', 'voicesatellite'],
  ['esphome', 'ESPHome', 'esphome'],
  ['media', 'Media Player', 'sendspin'],
  ['service', 'Service', 'device/Kiosk Satellite Service'],
  ['update', 'App Version', 'about'],
];
function buildTiles() {
  const grid = $('#statusGrid');
  if (grid.childElementCount) return;
  for (const [id, name, tab] of TILES) {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'status';
    b.dataset.status = id;
    b.innerHTML = '<span class="dot"></span><span class="s-text">'
      + '<span class="s-name"></span><span class="s-sub">Checking…</span></span>';
    b.querySelector('.s-name').textContent = name;
    b.addEventListener('click', () => showTab(tab));
    grid.appendChild(b);
  }
}
// level: on (green), warn (amber), off (red), '' (muted: switched off or
// unknown, which is not a problem to paint as one).
function paintTile(id, level, text) {
  const b = document.querySelector(`#statusGrid [data-status="${id}"]`);
  if (!b) return;
  b.querySelector('.dot').className = `dot ${level}`;
  b.classList.toggle('warn', level === 'warn');
  b.classList.toggle('error', level === 'off');
  b.querySelector('.s-sub').textContent = text;
}
// "Music Assistant (d5369777-music-assistant)" reads as Music Assistant.
const serverLabel = (name) => (name || '').replace(/\s*\(.*\)\s*$/, '').trim();

/* ---- Needs attention ----
   What a person has to do, each with its button; hidden while empty, so a
   healthy kiosk opens on its screen. */
let attentionKeys = null;
function renderAttention(items) {
  const title = $('#attentionTitle');
  const card = $('#attentionCard');
  const keys = items.map((i) => i.key).join('|');
  title.classList.toggle('hidden', !items.length);
  card.classList.toggle('hidden', !items.length);
  if (keys === attentionKeys) {
    // The same items as last time: refresh the words and leave the
    // buttons alone, one may be riding an update download.
    for (const it of items) {
      const desc = card.querySelector(`[data-key="${CSS.escape(it.key)}"] .desc`);
      if (desc) desc.textContent = it.desc;
    }
    return;
  }
  attentionKeys = keys;
  card.innerHTML = '';
  for (const it of items) {
    const row = document.createElement('div');
    row.className = 'row';
    row.dataset.key = it.key;
    const info = document.createElement('div');
    info.className = 'info';
    info.innerHTML = '<div class="name"></div><div class="desc"></div>';
    info.querySelector('.name').textContent = it.name;
    info.querySelector('.desc').textContent = it.desc;
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'btn-ghost';
    btn.style.flexShrink = '0';
    it.action(btn);
    row.append(info, btn);
    card.appendChild(row);
  }
}
// The grant happens on the tablet (Android has no way to accept on
// someone's behalf); the button opens the dialog there and re-reads until
// it lands, the same flow as the Permissions Manager rows.
function grantButton(btn, spec) {
  btn.textContent = spec.guard ? 'Open settings on device' : 'Grant on device';
  btn.onclick = async () => {
    btn.disabled = true;
    try {
      if (spec.guard) await cmd('openUiGuardSettings');
      else await cmd('requestOsPermissions', { which: [].concat(spec.ask) });
    } catch (_) {}
    let tries = 30;
    const tick = setInterval(async () => {
      const now = (await ask('getSystemPermissions')) || {};
      if (spec.guard) now.uiGuard = (await ask('hasUiGuard')) === true;
      if (now[spec.key] === true || --tries <= 0) {
        clearInterval(tick);
        btn.disabled = false;
        refreshHealth();
      }
    }, 2000);
  };
}
function openButton(btn, label, tab) {
  btn.textContent = label;
  btn.onclick = () => showTab(tab);
}

let healthInFlight = null;
export function refreshHealth() {
  // One read at a time: a tab shown during a read joins it.
  if (healthInFlight) return healthInFlight;
  healthInFlight = readHealth().finally(() => { healthInFlight = null; });
  return healthInFlight;
}
async function readHealth() {
  const [ha, wake, esp, media, svc, upd, perms, guard] = await Promise.all([
    'haStatus', 'getWakeWordState', 'esphomeStatus', 'sendspinStatus',
    'getServiceStatus', 'getUpdateStatus', 'getSystemPermissions', 'hasUiGuard',
  ].map((c) => ask(c)));

  if (!ha) paintTile('ha', '', 'Status unavailable');
  else if (!ha.configured) paintTile('ha', 'warn', 'Not set up');
  else if (!ha.connected) paintTile('ha', 'off', 'Disconnected');
  else paintTile('ha', 'on', 'Connected');

  if (!settingOn('wake_word.enabled')) paintTile('voice', '', 'Wake word detection off');
  else if (!wake) paintTile('voice', '', 'Status unavailable');
  else if (wake.released) paintTile('voice', 'warn', wake.releaseReason || 'Stopped');
  else if (wake.listening) {
    const words = (wake.models || []).map((m) => m.wakeWord).filter(Boolean).join(', ');
    paintTile('voice', 'on', words ? `Listening for ${words}` : 'Listening');
  } else paintTile('voice', 'warn', wake.statusLabel || 'Not listening');

  if (!esp) paintTile('esphome', '', 'Status unavailable');
  else if (!esp.running) paintTile('esphome', '', 'Off');
  else if ((esp.connections || []).length || esp.subscribers) {
    // What the connection carries, from the two switches under it.
    const entities = settingOn('esphome.entities');
    const proxy = settingOn('btproxy.enabled');
    paintTile('esphome', 'on', entities && proxy ? 'Entities and BT proxy'
      : entities ? 'Entities only' : proxy ? 'BT Proxy only' : 'Connected');
  } else paintTile('esphome', 'warn', 'Waiting for Home Assistant');

  // Green only while something plays. Idle is the normal state of a
  // player, not a fault: an own Sendspin player with no server around and
  // a followed remote player at rest both read the same, so nothing here
  // asks a person to go and fix a quiet speaker.
  if (!media) paintTile('media', '', 'Status unavailable');
  else if (!media.enabled) paintTile('media', '', 'Off');
  else {
    const where = media.remotePlayer || serverLabel(media.serverName);
    const label = (word) => (where ? `${word} - ${where}` : word);
    if (media.playing) paintTile('media', 'on', label('Playing'));
    else if (media.playbackState === 'paused') paintTile('media', '', label('Paused'));
    else paintTile('media', '', label('Idle'));
  }

  if (!svc) paintTile('service', '', 'Status unavailable');
  else if (svc.error) paintTile('service', 'off', svc.error);
  else if (!svc.running) paintTile('service', 'warn', 'Not running');
  else {
    const n = (svc.reasons || []).length;
    paintTile('service', 'on', n ? `Running - ${n} feature${n === 1 ? '' : 's'}` : 'Running');
  }

  if (!upd) paintTile('update', '', 'Status unavailable');
  else if (upd.progress !== null && upd.progress !== undefined) {
    paintTile('update', 'warn', `Downloading: ${upd.availableVersion || ''}`.trim());
  } else if (upd.availableVersion) paintTile('update', 'warn', `New version: ${upd.availableVersion}`);
  else paintTile('update', 'on', upd.currentVersion ? `Up to date: ${upd.currentVersion}` : 'Up to date');

  const items = [];
  if (upd?.availableVersion) {
    items.push({
      key: 'update',
      name: 'Update available',
      desc: `Kiosk Satellite ${upd.availableVersion} is ready to install. `
        + 'The installation is confirmed on the tablet screen.',
      action: (btn) => { btn.textContent = 'Install'; attachUpdateInstall(btn, upd); },
    });
  }
  if (ha && !ha.configured) {
    items.push({
      key: 'ha-setup',
      name: 'Home Assistant not set up',
      desc: 'Connect the kiosk to Home Assistant to load a dashboard.',
      action: (btn) => openButton(btn, 'Set up', 'homeassistant'),
    });
  } else if (ha && !ha.connected) {
    items.push({
      key: 'ha',
      name: 'Home Assistant disconnected',
      desc: 'The dashboard session and the Voice Satellite are offline until the connection is back.',
      action: (btn) => openButton(btn, 'Open setup', 'homeassistant'),
    });
  }
  if (settingOn('wake_word.enabled') && wake?.released) {
    items.push({
      key: 'wake',
      name: 'Wake word detection stopped',
      desc: wake.releaseReason || 'The engine was released.',
      action: (btn) => {
        if (!wake.canRetry) { openButton(btn, 'Open Voice Satellite', 'voicesatellite'); return; }
        btn.textContent = 'Retry';
        btn.onclick = async () => {
          btn.disabled = true;
          await cmd('retryWakeWord').catch(() => null);
          setTimeout(refreshHealth, 1500);
        };
      },
    });
  }
  if (svc?.error) {
    items.push({
      key: 'service',
      name: 'Kiosk Satellite Service',
      desc: svc.error,
      action: (btn) => openButton(btn, 'Open service', 'device/Kiosk Satellite Service'),
    });
  }
  if (perms) {
    // A grant is only a problem while a switched-on feature needs it;
    // the Permissions Manager on the Device page carries the rest.
    const all = { ...perms };
    if (guard !== null) all.uiGuard = guard === true;
    const text = (t) => (typeof t === 'function' ? t(all) : t);
    for (const spec of permissionSpecs(settingOn)) {
      if (!spec.needed || all[spec.key] !== false) continue;
      // No settings screen for it on this device: the adb line on the
      // Device page is the answer, not a button that opens nothing.
      if (spec.requestable && all[spec.requestable] === false) continue;
      items.push({
        key: `perm:${spec.key}`,
        name: `${spec.name} permission missing`,
        desc: text(spec.missing),
        action: (btn) => grantButton(btn, spec),
      });
    }
  }
  renderAttention(items);
  paintNowPlaying(media);
}

/* ---- Screen ---- */
let live = localStorage.getItem('ks_shot_live') === '1';
function paintShotMode() {
  document.querySelectorAll('#shotMode button').forEach((b) =>
    b.classList.toggle('active', (b.dataset.live === '1') === live));
  paintTaken();
}
function paintTaken() {
  const el = $('#shotTaken');
  if (live) el.textContent = 'Live, every 5 seconds';
  else if (state.screenshotAt) el.textContent = `Taken ${agoLabel(new Date(state.screenshotAt))}`;
  else el.textContent = '';
}
// What the panel is doing, on the frame, so a black capture reads as the
// screen being off or the screensaver rather than as a broken kiosk.
export function paintShotBadge() {
  const el = $('#shotBadge');
  let icon = '';
  let text = '';
  if (quick.screenOn === false) { icon = ICONS.screenOff; text = 'Screen off'; }
  else if (quick.cameraView?.active) {
    icon = ICONS.camera;
    text = quick.cameraView.viewName ? `Camera view: ${quick.cameraView.viewName}` : 'Camera view';
  } else if (quick.screensaverActive === true) { icon = ICONS.moon; text = 'Screensaver'; }
  el.classList.toggle('hidden', !text);
  el.innerHTML = icon;
  el.appendChild(document.createTextNode(text));
}
document.querySelectorAll('#shotMode button').forEach((b) =>
  b.addEventListener('click', () => {
    live = b.dataset.live === '1';
    localStorage.setItem('ks_shot_live', live ? '1' : '0');
    paintShotMode();
    if (live) loadScreenshot();
  }));
$('#shotRefresh').addEventListener('click', loadScreenshot);
$('#shotFull').addEventListener('click', () => {
  const img = $('#shotWrap img');
  if (img?.src) window.open(img.src, '_blank');
});
$('#shotSave').addEventListener('click', () => {
  const img = $('#shotWrap img');
  if (!img?.src) return;
  const at = new Date(state.screenshotAt || Date.now());
  const pad = (n) => String(n).padStart(2, '0');
  const stamp = `${at.getFullYear()}${pad(at.getMonth() + 1)}${pad(at.getDate())}-`
    + `${pad(at.getHours())}${pad(at.getMinutes())}${pad(at.getSeconds())}`;
  const who = (state.device?.name || 'kiosk').replace(/[^\w-]+/g, '-').replace(/^-+|-+$/g, '');
  const ext = state.screenshotType === 'image/png' ? 'png' : 'jpg';
  const a = document.createElement('a');
  a.href = img.src;
  a.download = `${who}-${stamp}.${ext}`;
  document.body.appendChild(a);
  a.click();
  a.remove();
});
document.addEventListener('ks-screenshot', paintTaken);
document.addEventListener('ks-quick', paintShotBadge);

/* ---- Now playing ----
   While the media player has a track: what, from where, and transport.
   The same read the Media Player tile paints from. */
let npVisible = false;
function paintNowPlaying(s) {
  const show = !!(s && s.enabled && (s.playing || s.title));
  $('#npTitle').classList.toggle('hidden', !show);
  $('#npCard').classList.toggle('hidden', !show);
  npVisible = show;
  if (!show) return;
  $('#npTrack').textContent = s.title || 'Unknown track';
  $('#npArtist').textContent = [s.artist, s.album].filter(Boolean).join(' · ');
  $('#npSource').textContent = [serverLabel(s.serverName), settingVal('sendspin.player_name')]
    .filter(Boolean).join(' · ');
  // The cover comes through the device (/api/media/artwork): a Music
  // Assistant image proxy sits on a self-signed https address the
  // browser would refuse silently. Fetched once per URL; a fetch that
  // fails leaves the glyph and is tried again on the next read.
  const img = $('#npArt img');
  if (s.artworkUrl) {
    if (img.dataset.src !== s.artworkUrl) {
      img.dataset.src = s.artworkUrl;
      loadArtwork(img, s.artworkUrl);
    }
  } else {
    delete img.dataset.src;
    img.hidden = true;
    img.removeAttribute('src');
  }
  const play = $('#npPlay');
  play.innerHTML = s.playing ? ICONS.pause : ICONS.play;
  play.dataset.np = s.playing ? 'pause' : 'play';
  play.title = s.playing ? 'Pause' : 'Play';
  const supported = s.supportedCommands || [];
  document.querySelectorAll('#npCard [data-np]').forEach((b) => {
    b.disabled = supported.length > 0 && !supported.includes(b.dataset.np);
  });
}
async function loadArtwork(img, url) {
  try {
    const res = await api('/api/media/artwork');
    if (img.dataset.src !== url) return; // the track moved on meanwhile
    if (!res.ok) throw new Error('no artwork');
    const blob = URL.createObjectURL(await res.blob());
    const old = img.src;
    img.src = blob;
    img.hidden = false;
    if (old.startsWith('blob:')) URL.revokeObjectURL(old);
  } catch (_) {
    if (img.dataset.src === url) { delete img.dataset.src; img.hidden = true; }
  }
}
async function refreshNowPlaying() {
  paintNowPlaying(await ask('sendspinStatus'));
}
$('#npArt img').addEventListener('error', function () { this.hidden = true; });
document.querySelectorAll('#npCard [data-np]').forEach((b) =>
  b.addEventListener('click', async () => {
    const res = await cmd('sendspinControl', { command: b.dataset.np }).catch(() => null);
    if (res && res.ok === false && res.error) {
      showToast({ title: b.title || 'Media player', message: res.error, kind: 'error' });
    }
    setTimeout(refreshNowPlaying, 800);
  }));

/* ---- Master volume ----
   The device volume, the same fader the Screen & Audio page carries, here
   because it is the one setting a person reaches for as often as
   brightness. Live: the rocker on the tablet moves it too. */
let volume = null;
let volumeTimer = null;
export async function refreshVolume() {
  const row = $('#volumeRow');
  const level = await ask('getVolume');
  if (typeof level !== 'number') { row.classList.add('hidden'); return; }
  row.classList.remove('hidden');
  if (!volume) {
    volume = attachSlider(row, { min: 0, max: 100, step: 5, value: Math.round(level),
      label: (v) => `${v}%`,
      onChange: (v) => cmd('setVolume', { percent: v }) });
  } else if (document.activeElement !== volume.input) {
    volume.set(Math.round(level));
  }
}
document.addEventListener('ks-event', (e) => {
  if (e.detail?.event !== 'volumechanged') return;
  clearTimeout(volumeTimer);
  volumeTimer = setTimeout(refreshVolume, 300);
});
// A wake word state push (a lost microphone, a released engine) moves the
// Voice Satellite tile and possibly the attention list; coalesce the
// start/end burst of a voice turn into one read after quiet.
let healthTimer = null;
document.addEventListener('ks-wakeword', () => {
  if (!onOverview()) return;
  clearTimeout(healthTimer);
  healthTimer = setTimeout(refreshHealth, 2000);
});

/* ---- Quick controls ---- */
function paintSnapshotTile() {
  const tile = $('#tileSnapshot');
  tile.classList.toggle('hidden', !settingOn('camera.enabled') || state.cameraPresent === false);
}
$('#tileSnapshot').addEventListener('click', async () => {
  const tile = $('#tileSnapshot');
  tile.disabled = true;
  try {
    const res = await cmd('takeCameraSnapshot').catch(() => null);
    if (!res || res.ok === false) {
      await messageBox({ title: 'Take snapshot',
        message: res?.error || 'The device did not answer.' });
      return;
    }
    const r = await api('/api/camera/snapshot');
    if (!r.ok) {
      await messageBox({ title: 'Take snapshot', message: 'No snapshot came back.' });
      return;
    }
    const url = URL.createObjectURL(await r.blob());
    const { back, body, foot } = modalShell({ title: 'Camera snapshot', width: 720 });
    const img = document.createElement('img');
    img.src = url;
    img.alt = 'Camera snapshot';
    img.style.cssText = 'display:block; width:100%; border-radius:12px;';
    body.appendChild(img);
    const close = document.createElement('button');
    close.className = 'btn-text';
    close.textContent = 'Close';
    close.addEventListener('click', () => { back.remove(); URL.revokeObjectURL(url); });
    foot.appendChild(close);
  } finally { tile.disabled = false; }
});
$('#tileCheckUpdate').addEventListener('click', async () => {
  const tile = $('#tileCheckUpdate');
  tile.disabled = true;
  try {
    const res = await ask('checkUpdateNow');
    refreshUpdateBadge();
    await refreshHealth();
    if (!res?.reachable) {
      await messageBox({ title: 'Check for updates',
        message: 'Update check failed. Can the device reach GitHub?' });
    } else if (!res.availableVersion) {
      await messageBox({ title: 'Check for updates', message: 'You are on the latest version.' });
    } else {
      showToast({ title: `Version ${res.availableVersion} is available`,
        message: 'Install it from Needs attention.', kind: 'info' });
    }
  } finally { tile.disabled = false; }
});

/* ---- Lifecycle ---- */
let ticks = 0;
setInterval(() => {
  if (!onOverview()) return;
  ticks++;
  if (live) loadScreenshot();
  if (ticks % HEALTH_EVERY === 0) refreshHealth();
  else if (npVisible) refreshNowPlaying();
}, TICK_MS);
setInterval(() => { if (onOverview() && !live) paintTaken(); }, 1000);

// The page came back into view: a tab switch here, or the browser tab
// returning. Fresh reads, and a Live capture if the last one is stale.
export function overviewShown() {
  refreshHealth();
  refreshVolume();
  paintShotBadge();
  paintSnapshotTile();
  paintTaken();
  if (live && (!state.screenshotAt || Date.now() - state.screenshotAt > TICK_MS)) loadScreenshot();
}
document.addEventListener('visibilitychange', () => { if (onOverview()) overviewShown(); });

// Boot: built behind the splash with the rest of the app, so the page
// opens populated rather than filling in.
export async function initOverview() {
  buildTiles();
  paintShotMode();
  paintShotBadge();
  paintSnapshotTile();
  await Promise.all([refreshHealth(), refreshVolume()]);
}
