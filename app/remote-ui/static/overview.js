import { isHeadless } from './headless.js';
import { overviewLabel, overviewMessageBox as messageBox, overviewModalShell as modalShell } from './overview_labels.js';
import { fleetStatusText } from './fleet-messages.js';
import { overviewText, overviewStatus, cameraError, deviceText, deviceOperationError, fleetText, intercomText, mediaText, mediaError, navigationText, t, voiceText } from './localization.js';
import { watchUpdates } from './live.js';
import { $, api, cmd, state } from './core.js';
import { attachSystemUpdateInstall, attachUpdateInstall, refreshUpdateBadge, systemUpdateBusy } from './device.js';
import { readFilterStatus } from './filter_status.js';
import { agoLabel } from './notices.js';
import { loadScreenshot, quick, renderQuickControls } from './panels.js';
import { adbHint, permissionSpecs } from './permissions.js';
import { loadPlugins, reviewPluginUpdate } from './plugins.js';
import { showTab } from './tabs.js';
import { attachSlider, showToast } from './widgets.js';
import { openVsMigrationWizard } from './vs_native.js';
import { ALARM_ICON, alarmClockText } from './alarms.js';

/* ---- Overview ----
   The first page, and for most visits the only one: what the kiosk needs
   from a person, what its screen shows, how each part of it is doing.
   Everything here reads the device's own status commands, nothing is a
   setting, so the page is rebuilt from a fresh read every time it is
   looked at and when its subscribed state changes. Never from a
   hidden tab or another page: each read is work on the tablet. */

const TICK_MS = 5000;


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
  media: `<svg ${STROKE}><circle cx="12" cy="12" r="10"/><path d="m9.75 7.5 7 4.5-7 4.5z"/></svg>`,
  intercom: `<svg ${STROKE}><rect x="3" y="3" width="11" height="18" rx="2.5"/><circle cx="8.5" cy="9" r="2.2"/><path d="M6.5 15.5h4"/><path d="M17.5 8.5a5 5 0 0 1 0 7M20 6a8.5 8.5 0 0 1 0 12"/></svg>`,
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
  for (const [id, name, tab] of TILES) {
    if (grid.querySelector(`[data-status="${id}"]`)) continue;
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'status';
    b.dataset.status = id;
    b.innerHTML = '<span class="dot"></span><span class="s-text">'
      + '<span class="s-name"></span><span class="s-sub"></span></span>';
    overviewLabel(b.querySelector('.s-name'), name);
    overviewLabel(b.querySelector('.s-sub'), 'Checking…');
    b.addEventListener('click', () => showTab(tab));
    grid.insertBefore(b, grid.querySelector('.status.plugin'));
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
const LEVELS = new Set(['', 'on', 'warn', 'off']);

/* ---- Metric tiles ----
   CPU, memory and temperature as terminal style LED stacks: one column a
   sample, lit from the bottom up to the value, each cell colored by the
   band it sits in so a climbing column goes green, amber, red. The device
   keeps the last fifteen minutes (getStatsHistory), so the stack is full
   at connect; the four second stats push moves the value and the dot and
   adds a column every interval while the page stays open. Fixed scales,
   so a lit cell always means the same thing, with the ceiling and floor
   labelled beside the stack. Memory is the used share, so a taller stack
   is more pressure, while the state line says what is free. */
const METRICS = [
  { id: 'cpu', name: 'CPU', lo: 0, hi: 100, warn: 70, err: 90, unit: '%' },
  // Short names on purpose: every letter of the name is a column the
  // stack cannot have.
  { id: 'memory', name: 'RAM', lo: 0, hi: 100, warn: 80, err: 92, unit: '%' },
  // The header's own thresholds for the temperature tint.
  { id: 'temp', name: 'Temp', lo: 20, hi: 90, warn: 65, err: 80, unit: '°C' },
];
const METRIC_CAPACITY = 60;
const metricHistory = { intervalMs: 15000, at: 0, cpu: [], memory: [], temp: [] };
const metricNow = { cpu: null, memory: null, temp: null, memFree: null };
let metricsRead = false;

// The stack as data: `columns` columns of `rows` cells, bottom to top, the
// newest sample in the last column and history too short for the width
// padded with unlit columns on the left. A cell is null (unlit) or the
// band of its midpoint: ok, warn or off (the dot's own levels).
export function ledCells(values, spec, columns, rows) {
  const span = spec.hi - spec.lo;
  const tail = values.slice(-columns);
  const cols = [];
  for (let i = tail.length; i < columns; i++) cols.push(Array(rows).fill(null));
  for (const v of tail) {
    const lit = v == null ? 0
      : Math.max(0, Math.min(rows, Math.ceil(rows * (v - spec.lo) / span - 1e-9)));
    const col = [];
    for (let k = 0; k < rows; k++) {
      const mid = spec.lo + span * (k + 0.5) / rows;
      col.push(k < lit ? (mid >= spec.err ? 'off' : mid >= spec.warn ? 'warn' : 'ok') : null);
    }
    cols.push(col);
  }
  return cols;
}
// 2 by 3 cells with a 1px gap, as many as the slot holds up to the history
// the device keeps; the slot's own size decides the columns and rows so a
// shorter, wider slot draws more columns of fewer cells without a second
// code path. The stack sits at the slot's right, the newest sample last.
function ledSvg(values, spec, width, height) {
  const colW = 2, cellH = 3, gap = 1;
  const columns = Math.max(1, Math.min(METRIC_CAPACITY, Math.floor((width + gap) / (colW + gap))));
  const rows = Math.max(1, Math.floor((height + gap) / (cellH + gap)));
  const w = columns * (colW + gap) - gap, h = rows * (cellH + gap) - gap;
  let out = '';
  ledCells(values, spec, columns, rows).forEach((col, i) => col.forEach((band, k) => {
    out += `<rect x="${i * (colW + gap)}" y="${h - (k + 1) * cellH - k * gap}" width="${colW}" height="${cellH}" class="${band || 'dim'}"/>`;
  }));
  return `<svg viewBox="0 0 ${w} ${h}" width="${w}" height="${h}" aria-hidden="true">${out}</svg>`;
}
function buildMetricTiles() {
  const grid = $('#statusGrid');
  for (const spec of METRICS) {
    if (grid.querySelector(`[data-status="${spec.id}"]`)) continue;
    // A reading, not a control: no page to open and nothing to press.
    const b = document.createElement('div');
    b.className = 'status metric';
    b.dataset.status = spec.id;
    b.innerHTML = '<span class="dot"></span><span class="s-text">'
      + '<span class="s-name"></span><span class="s-sub"></span></span>'
      + '<span class="s-chart"><span class="s-led"></span>'
      + '<span class="s-axis"><span class="hi"></span><span class="lo"></span></span></span>';
    overviewLabel(b.querySelector('.s-name'), spec.name);
    overviewLabel(b.querySelector('.s-sub'), 'Checking…');
    b.querySelector('.hi').textContent = `${spec.hi}${spec.unit}`;
    b.querySelector('.lo').textContent = `${spec.lo}${spec.unit}`;
    grid.insertBefore(b, grid.querySelector('.status.plugin'));
  }
}
const metricLevel = (spec, v) => (v == null ? '' : v >= spec.err ? 'off' : v >= spec.warn ? 'warn' : 'on');
function metricText(spec, v) {
  if (v == null) return overviewText('Status unavailable');
  if (spec.id === 'memory' && metricNow.memFree != null) {
    return t('overviewMemoryFree', {amount: (metricNow.memFree / 1073741824).toFixed(1)});
  }
  if (spec.id === 'temp') return t('overviewMetricDegrees', {value: String(Math.round(v))});
  return t('overviewMetricPercent', {value: String(Math.round(v))});
}
function paintMetricTiles() {
  for (const spec of METRICS) {
    const b = document.querySelector(`#statusGrid [data-status="${spec.id}"]`);
    if (!b) continue;
    const v = metricNow[spec.id];
    const history = metricHistory[spec.id];
    // A host that declines the read (no thermal zone, no Android) gets no
    // tile rather than one that says unavailable forever; a tile only
    // goes once the first history read has confirmed there is nothing.
    const known = v != null || history.some((x) => x != null);
    b.classList.toggle('hidden', metricsRead && !known);
    if (!known) continue;
    paintTile(spec.id, metricLevel(spec, v), metricText(spec, v));
    const led = b.querySelector('.s-led');
    if (!led.clientWidth) continue; // Hidden tab: the resize that shows it repaints.
    led.innerHTML = ledSvg(history, spec, led.clientWidth, led.clientHeight);
  }
}
function applyMetricHistory(h) {
  if (!h || typeof h !== 'object') return;
  const list = (key) => (Array.isArray(h[key]) ? h[key].slice(-METRIC_CAPACITY).map((x) => (typeof x === 'number' ? x : null)) : []);
  metricHistory.cpu = list('cpu');
  metricHistory.memory = list('memory');
  metricHistory.temp = list('temp');
  if (typeof h.intervalSeconds === 'number' && h.intervalSeconds > 0) metricHistory.intervalMs = h.intervalSeconds * 1000;
  // Ages the device's last sample on our clock, so the next column lands
  // one interval after it rather than one interval after the fetch.
  metricHistory.at = typeof h.at === 'number' ? Math.min(Date.now(), h.at) : Date.now();
}
async function readMetricHistory() {
  const h = await ask('getStatsHistory');
  if (h) applyMetricHistory(h);
  metricsRead = true;
  paintMetricTiles();
}
// Every stats push: the live value, and a new column once an interval has
// passed since the last one, on the device's cadence.
document.addEventListener('ks-stats', (e) => {
  const o = e.detail || {};
  metricNow.cpu = typeof o.cpu === 'number' ? o.cpu : null;
  metricNow.temp = typeof o.temp === 'number' ? o.temp : null;
  const free = typeof o.memFree === 'number' ? o.memFree : typeof o.ramFree === 'number' ? o.ramFree : null;
  const total = typeof o.memTotal === 'number' ? o.memTotal : typeof o.ramTotal === 'number' ? o.ramTotal : null;
  metricNow.memFree = free;
  metricNow.memory = free != null && total > 0 ? Math.max(0, Math.min(100, 100 * (1 - free / total))) : null;
  const now = Date.now();
  if (now - metricHistory.at >= metricHistory.intervalMs) {
    for (const spec of METRICS) {
      metricHistory[spec.id].push(metricNow[spec.id]);
      if (metricHistory[spec.id].length > METRIC_CAPACITY) metricHistory[spec.id].shift();
    }
    metricHistory.at = now;
  }
  if (onOverview()) paintMetricTiles();
});
// A reconnect brings the device's history back in place of ours, which
// stopped while the socket was down.
document.addEventListener('ks-connected', () => { if (metricsRead) readMetricHistory(); });
{
  const grid = $('#statusGrid');
  if (grid) new ResizeObserver(() => paintMetricTiles()).observe(grid);
}

/* ---- Plugin tiles ----
   Tiles a running plugin publishes through the SDK. They sit after the
   built-in tiles and name their plugin, so a plugin's tile never reads as a
   claim the kiosk itself is making. Each opens the plugin's page. A tile
   goes when its plugin stops, is disabled or Plugin Manager is off: the
   read simply stops listing it. */
function paintPluginTiles(tiles) {
  const grid = $('#statusGrid');
  const keep = new Set();
  for (const tile of Array.isArray(tiles) ? tiles : []) {
    if (!tile || typeof tile.pluginId !== 'string' || typeof tile.key !== 'string') continue;
    const id = `plugin:${tile.pluginId}:${tile.key}`;
    keep.add(id);
    let b = grid.querySelector(`[data-status="${id}"]`);
    if (!b) {
      b = document.createElement('button');
      b.type = 'button';
      b.className = 'status plugin';
      b.dataset.status = id;
      b.innerHTML = '<span class="dot"></span><span class="s-text">'
        + '<span class="s-name"></span><span class="s-sub"></span><span class="s-from"></span></span>';
      // The plugin pages are built on first visit: build them before opening one.
      b.addEventListener('click', async () => {
        await loadPlugins();
        showTab(`plugins/${tile.pluginId}`, { refresh: false });
      });
      grid.appendChild(b);
    }
    b.querySelector('.s-name').textContent = tile.title || tile.key;
    b.querySelector('.s-from').textContent = t('overviewPluginAttribution', {name: tile.pluginName || tile.pluginId});
    paintTile(id, LEVELS.has(tile.level) ? tile.level : '', tile.text || '');
  }
  for (const b of grid.querySelectorAll('.status.plugin')) {
    if (!keep.has(b.dataset.status)) b.remove();
  }
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
      const name = card.querySelector(`[data-key="${CSS.escape(it.key)}"] .name`);
      if (name) name.textContent = it.name;
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
    row.appendChild(info);
    // One button, or several side by side (Decline, Accept). A phone
    // gives several their own line under the text.
    const list = it.actions || [it.action];
    const actions = document.createElement('div');
    actions.className = 'row-actions' + (list.length > 1 ? ' several' : '');
    for (const action of list) {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'btn-ghost';
      action(btn);
      actions.appendChild(btn);
    }
    row.appendChild(actions);
    card.appendChild(row);
  }
}
// The grant happens on the tablet (Android has no way to accept on
// someone's behalf); the button opens the dialog there and re-reads until
// it lands, the same flow as the Permissions Manager rows.
function grantButton(btn, spec) {
  overviewLabel(btn, spec.guard ? 'Open settings on device' : 'Grant on device');
  btn.onclick = async () => {
    btn.disabled = true;
    try {
      if (spec.guard) await cmd('openUiGuardSettings');
      else await cmd('requestOsPermissions', { which: [].concat(spec.ask) });
    } catch (_) {}
    btn.disabled = false;
    readSource('service').then(() => paintHealth({ filter: false }));
  };
}
// Accept or Decline on a fleet invitation. Both buttons hold still until
// the answer lands, then the fleet push repaints the list without the row.
function inviteButton(btn, label, command) {
  btn.textContent = fleetText(label);
  btn.onclick = async () => {
    const both = btn.parentElement.querySelectorAll('button');
    both.forEach((b) => { b.disabled = true; });
    let res;
    try { res = await cmd(command); } catch (_) { res = null; }
    both.forEach((b) => { b.disabled = false; });
    if (res && res.ok !== false) {
      if (command === 'fleetAccept') {
        showToast({ title: fleetText('Joined the fleet'),
          message: fleetText('Settings from the leader arrive shortly.'), kind: 'success' });
      }
    } else {
      showToast({ title: fleetText('Fleet Management'),
        message: fleetStatusText((res && res.error) || 'The device did not answer.'), kind: 'error' });
    }
    readSource('fleet').then(() => paintHealth({ filter: false }));
  };
}
function openButton(btn, label, tab) {
  overviewLabel(btn, label);
  btn.onclick = () => showTab(tab);
}

/* ---- Health ----
   One cache slot per status source. Each source has its own topic and
   reader: an update for that topic re-reads (or paints from the pushed
   results) that one source, and the tiles and the attention list are
   painted whole from the cache. A settings change repaints from the
   cache without a single command. */
const health = { ha: null, wake: null, voice: null, esp: null, media: null, svc: null,
  upd: null, sys: null, perms: null, guard: null, buttons: null, fleet: null, tiles: null, plugins: null };
const SOURCES = {
  ha: { topics: ['ha'], read: async () => { health.ha = await ask('haStatus'); } },
  // Wake word pushes arrive as their own message (ks-wakeword below).
  wake: { topics: [], read: async () => { health.wake = await ask('getWakeWordState'); } },
  // The native satellite: added to Home Assistant, listening or mid-turn.
  // The same source and topic as the Voice Satellite page's Status row.
  voice: { topics: ['voice-status'], read: async () => {
    health.voice = settingVal('voice.runtime') === 'dashboard' ? null : await ask('voiceStatus');
  } },
  // Sampled on the device, pushed only when something other than the
  // beacon counters moved, with the sample attached.
  esp: { topics: ['bluetooth'], read: async (results) => {
    health.esp = results?.esphomeStatus ? dataOf(results.esphomeStatus) : await ask('esphomeStatus');
  } },
  media: { topics: ['media'], intervalMs: 1000, read: async () => { health.media = await ask('sendspinStatus'); } },
  service: { topics: ['service'], read: async (results) => {
    // The button service of a device without a screen, which adb enables.
    health.buttons = isHeadless() ? await ask('getHardwareButtons') : null;
    if (results?.getServiceStatus) {
      health.svc = dataOf(results.getServiceStatus);
      health.perms = dataOf(results.getSystemPermissions);
      health.guard = dataOf(results.hasUiGuard);
      return;
    }
    [health.svc, health.perms, health.guard] = await Promise.all(
      ['getServiceStatus', 'getSystemPermissions', 'hasUiGuard'].map((c) => ask(c)));
  } },
  update: { topics: ['update'], read: async () => { health.upd = await ask('getUpdateStatus'); } },
  // The system image's own update, where its updater reports one.
  sys: { topics: ['update'], read: async () => {
    const sys = await ask('getSystemUpdateStatus');
    health.sys = sys?.supported ? sys : null;
  } },
  fleet: { topics: ['fleetsync'], read: async () => { health.fleet = await ask('fleetStatus'); } },
  tiles: { topics: ['plugin-tiles'], read: async () => { health.tiles = await ask('getPluginStatusTiles'); } },
  plugins: { topics: ['plugin-updates'], read: async () => {
    const updates = await ask('getPluginUpdates');
    health.plugins = Array.isArray(updates) ? updates : [];
  } },
};
const dataOf = (r) => (r && r.ok !== false && r.data !== undefined ? r.data : null);
// One read per source at a time: a tab shown during a read joins it.
function readSource(name, results) {
  const source = SOURCES[name];
  if (source.pending) return source.pending;
  source.pending = Promise.resolve(source.read(results)).catch(() => {})
    .finally(() => { source.pending = null; source.readAt = Date.now(); });
  return source.pending;
}
export async function refreshHealth() {
  await Promise.all(Object.keys(SOURCES).map((name) => readSource(name)));
  paintHealth();
}
for (const [name, source] of Object.entries(SOURCES)) {
  if (!source.topics.length) continue;
  watchUpdates(source.topics, async (results) => {
    // Entering the page (no results at all, as opposed to a push with
    // none) right after the boot read it is not worth a second read.
    if (results === undefined && Date.now() - (source.readAt || 0) < 5000) { paintHealth(); return; }
    await readSource(name, results);
    paintHealth();
  }, { visible: onOverview, intervalMs: source.intervalMs || 0 });
}
// The settings the tiles and the attention list read straight from the
// cache: a flip repaints, and only the filter label asks the device.
document.addEventListener('ks-settings', (e) => {
  if (!onOverview()) return;
  paintHealth({ filter: (e.detail || []).includes('browser.ws_filter') });
  paintSnapshotTile();
});

let haStatusRevision = 0;
let cachedFilterStatus;
async function paintHaStatus(ha, { filter = true } = {}) {
  const revision = filter ? ++haStatusRevision : haStatusRevision;
  const filtering = settingOn('browser.ws_filter');
  if (!filtering || !ha?.configured || !ha?.connected) cachedFilterStatus = undefined;
  if (!ha) paintTile('ha', '', overviewText('Status unavailable'));
  else if (!ha.configured) paintTile('ha', 'warn', overviewText('Not set up'));
  // "connected" is this run's validation verdict, not a live probe: it never
  // drops when the server goes away, so the tile says Validated, not Connected.
  else if (!ha.connected) paintTile('ha', 'off', overviewText('Not validated'));
  // The update filter is the dashboard's, which a device without a screen
  // does not have.
  else if (isHeadless()) {
    paintTile('ha', 'on', overviewText('Headless mode'));
    return;
  }
  else paintTile('ha', filtering && cachedFilterStatus?.unfiltered ? 'warn' : 'on', filtering
    ? cachedFilterStatus === undefined ? overviewText('Checking filter...') : overviewStatus(cachedFilterStatus?.label || 'Filter status unavailable')
    : overviewText('Validated'));
  // Keep the rest of Overview responsive if the dashboard cannot answer.
  // Disabled or disconnected panels do not get a JavaScript request.
  if (!filter || !onOverview()) return;
  const status = await readFilterStatus(filtering && !!ha?.configured && !!ha?.connected);
  if (revision !== haStatusRevision || !onOverview() || !ha?.configured || !ha?.connected) return;
  const enabled = settingOn('browser.ws_filter');
  const current = enabled ? status : null;
  cachedFilterStatus = current;
  paintTile('ha', current?.unfiltered ? 'warn' : 'on',
    enabled ? overviewStatus(current?.label || 'Filter status unavailable') : overviewText('Validated'));
}

/* The native satellite, worded as the Voice Satellite page's Status row.
   A wake word engine that failed on its own (a lost microphone, missing
   models) still says why; muting and turning Voice Satellite off release
   it on purpose and read as themselves. */
function paintNativeVoice(wake, voice) {
  const words = (wake?.models || []).map((m) => m.wakeWord).filter(Boolean).join(', ');
  if (!settingOn('voice.enabled')) paintTile('voice', '', overviewText('Off'));
  else if (!settingOn('esphome.enabled') || voice?.subscribed !== true) paintTile('voice', 'warn', voiceText('Not added'));
  else if (settingOn('voice.mute')) paintTile('voice', '', voiceText('Muted'));
  else if (wake?.released && !['muted', 'native-off'].includes(wake.releaseReason)) {
    paintTile('voice', 'warn', overviewStatus(wake.statusLabel || 'Not listening'));
  } else if (voice?.busy) paintTile('voice', 'on', voiceText('Busy'));
  else if (!voice?.listening) paintTile('voice', 'warn', overviewStatus(wake?.statusLabel || 'Not listening'));
  else paintTile('voice', 'on', words ? t('overviewListeningFor', {words}) : overviewText('Listening'));
}

function paintHealth({ filter = true } = {}) {
  const { ha, wake, esp, media, svc, upd, perms, guard, fleet, tiles } = health;
  void paintHaStatus(ha, { filter });

  if (settingVal('voice.runtime') !== 'dashboard') paintNativeVoice(wake, health.voice);
  else if (!settingOn('wake_word.enabled')) paintTile('voice', '', overviewText('Wake word detection off'));
  else if (!wake) paintTile('voice', '', overviewText('Status unavailable'));
  else if (wake.released) paintTile('voice', 'warn', overviewStatus(wake.releaseReason || 'Stopped'));
  else if (wake.listening) {
    const words = (wake.models || []).map((m) => m.wakeWord).filter(Boolean).join(', ');
    paintTile('voice', 'on', words ? t('overviewListeningFor', {words}) : overviewText('Listening'));
  } else paintTile('voice', 'warn', overviewStatus(wake.statusLabel || 'Not listening'));

  // Connected means a Home Assistant session subscribed to entity states
  // (clients), or the proxy relaying: advertisements subscribed or a
  // device connected through it. The proxy signals alone used to decide,
  // so an entities-only server read as waiting while it served everything.
  if (!esp) paintTile('esphome', '', overviewText('Status unavailable'));
  else if (!esp.running) paintTile('esphome', '', overviewText('Off'));
  else if (esp.clients || (esp.connections || []).length || esp.subscribers) {
    // What the connection carries, from the two switches under it.
    const entities = settingOn('esphome.entities');
    const proxy = settingOn('btproxy.enabled');
    paintTile('esphome', 'on', entities && proxy ? overviewText('Entities and BT proxy')
      : entities ? overviewText('Entities only') : proxy ? overviewText('BT Proxy only') : overviewText('Connected'));
  } else paintTile('esphome', 'warn', overviewText('Waiting for Home Assistant'));

  // Green only while something plays. Idle is the normal state of a
  // player, not a fault: an own Sendspin player with no server around and
  // a followed remote player at rest both read the same, so nothing here
  // asks a person to go and fix a quiet speaker.
  const mediaName = document.querySelector('[data-status="media"] .s-name');
  if (mediaName) mediaName.textContent = navigationText('Media Player');
  if (!media) paintTile('media', '', mediaText('Status unavailable'));
  else if (!media.enabled) paintTile('media', '', mediaText('Off'));
  else {
    const where = media.remotePlayer || serverLabel(media.serverName);
    const label = (word) => (where ? t('mediaStatusSource', {status: mediaText(word), source: where}) : mediaText(word));
    if (media.playing) paintTile('media', 'on', label('Playing'));
    else if (media.playbackState === 'paused') paintTile('media', '', label('Paused'));
    else paintTile('media', '', label('Idle'));
  }

  if (!svc) paintTile('service', '', overviewText('Status unavailable'));
  else if (svc.error) paintTile('service', 'off', svc.error);
  else if (!svc.running) paintTile('service', 'warn', overviewText('Not running'));
  else {
    const n = (svc.reasons || []).length;
    paintTile('service', 'on', n ? n === 1 ? overviewText('Running - 1 feature') : t('overviewRunningMany', {count: String(n)}) : overviewText('Running'));
  }

  if (!upd) paintTile('update', '', overviewText('Status unavailable'));
  else if (upd.progress !== null && upd.progress !== undefined) {
    paintTile('update', 'warn', t('overviewDownloading', {version: upd.availableVersion || ''}).trim());
  } else if (upd.availableVersion) paintTile('update', 'warn', t('overviewNewVersion', {version: upd.availableVersion}));
  else paintTile('update', 'on', upd.currentVersion ? t('overviewCurrentVersion', {version: upd.currentVersion}) : overviewText('Up to date'));

  paintPluginTiles(tiles);

  const items = [];
  // A fleet invitation, answered here or on the kiosk screen. Followers
  // behind the leader's release hold the sync until they update.
  if (fleet?.invite?.leader) {
    const leader = fleet.invite.leader;
    items.push({
      key: 'fleet-invite',
      name: t('overviewInvitation', {name: leader.name}),
      desc: [leader.address, leader.version].filter(Boolean).join(' · '),
      actions: [
        (btn) => inviteButton(btn, 'Decline', 'fleetDecline'),
        (btn) => { btn.className = 'btn-primary'; inviteButton(btn, 'Accept', 'fleetAccept'); },
      ],
    });
  }
  if (fleet?.leader && (fleet.outdated || []).length) {
    const names = fleet.outdated;
    items.push({
      key: 'fleet-outdated',
      name: names.length === 1 ? overviewText('1 follower runs another release') : t('overviewOutdatedMany', {count: String(names.length)}),
      desc: t('overviewSyncWaiting', {names: names.join(', '), version: fleet.self?.version || overviewText('this release')}),
      action: (btn) => {
        overviewLabel(btn, 'Update');
        btn.onclick = async () => {
          btn.disabled = true;
          try { await cmd('fleetUpdate'); } catch (_) {}
          btn.disabled = false;
          refreshHealth();
        };
      },
    });
  }
  if (upd?.availableVersion) {
    items.push({
      key: 'update',
      name: overviewText('Update available'),
      // Where the install is confirmed, if anywhere: a device owner or
      // Shizuku installs without asking, and a device without a screen has
      // nowhere to ask.
      desc: t(upd.silent ? 'overviewInstallSilentHelp'
        : isHeadless() ? 'overviewInstallHeadlessHelp' : 'overviewInstallHelp', {version: upd.availableVersion}),
      action: (btn) => { overviewLabel(btn, 'Install'); attachUpdateInstall(btn, () => health.upd); },
    });
  }
  if (health.sys?.availableVersion) {
    items.push({
      key: 'system-update',
      name: t('overviewSystemUpdate'),
      desc: t('overviewSystemImageUpdateHelp', {version: health.sys.availableVersion}),
      action: (btn) => {
        overviewLabel(btn, 'Install');
        attachSystemUpdateInstall(btn, () => health.sys, () => { refreshUpdateBadge(); refreshHealth(); });
      },
    });
  } else if (health.sys?.manualVersion && !systemUpdateBusy(health.sys)) {
    // A newer image the updater cannot install: only its guide.
    items.push({
      key: 'system-manual',
      name: t('aboutSystemManual'),
      desc: t('aboutSystemManualHelp', {version: health.sys.manualVersion}),
      action: (btn) => {
        overviewLabel(btn, 'Open guide');
        btn.onclick = () => window.open(health.sys.manualUrl, '_blank', 'noreferrer');
      },
    });
  }
  // Never installed from here without a person: Update opens the review.
  for (const plugin of health.plugins ?? []) {
    items.push({
      key: `plugin-update:${plugin.id}`,
      name: t('overviewPluginUpdate', {name: plugin.name}),
      desc: t('overviewPluginUpdateHelp', {version: plugin.version}),
      action: (btn) => {
        overviewLabel(btn, 'Update');
        btn.onclick = () => reviewPluginUpdate(plugin, btn);
      },
    });
  }
  if (ha && !ha.configured) {
    items.push({
      key: 'ha-setup',
      name: overviewText('Home Assistant not set up'),
      desc: overviewText('Connect the kiosk to Home Assistant to load a dashboard.'),
      action: (btn) => openButton(btn, 'Set up', 'homeassistant'),
    });
  } else if (ha && !ha.connected) {
    items.push({
      key: 'ha',
      name: overviewText('Home Assistant not validated'),
      desc: overviewText('The URL and token have not passed a connection check this run. The kiosk retries every 30 seconds.'),
      action: (btn) => openButton(btn, 'Open setup', 'homeassistant'),
    });
  }
  if (settingOn('wake_word.enabled') && wake?.released) {
    items.push({
      key: 'wake',
      name: overviewText('Wake word detection stopped'),
      desc: overviewStatus(wake.releaseReason || 'The engine was released.'),
      action: (btn) => {
        if (!wake.canRetry) { openButton(btn, 'Open Voice Satellite', 'voicesatellite'); return; }
        overviewLabel(btn, 'Retry');
        btn.onclick = async () => {
          btn.disabled = true;
          await cmd('retryWakeWord').catch(() => null);
          setTimeout(refreshWake, 1500);
        };
      },
    });
  }
  // Still on the Voice Satellite integration's engine: the Voice Satellite
  // page's notice, with the same way out.
  if (settingVal('voice.runtime') === 'dashboard' && ha?.connected) {
    items.push({
      key: 'vs-migrate',
      name: 'Voice Satellite',
      desc: voiceText('Voice Satellite is currently installed as an integration in Home Assistant. Migrate to a native experience inside Kiosk Satellite.'),
      action: (btn) => {
        btn.textContent = voiceText('Migrate');
        btn.onclick = () => openVsMigrationWizard();
      },
    });
  }
  if (svc?.error) {
    items.push({
      key: 'service',
      name: overviewText('Kiosk Satellite Service'),
      desc: svc.error,
      action: (btn) => openButton(btn, 'Open service', 'device/Kiosk Satellite Service'),
    });
  }
  if (perms) {
    // A grant is only a problem while a switched-on feature needs it;
    // the Permissions Manager on the Device page carries the rest.
    const all = { ...perms };
    if (guard !== null) all.uiGuard = guard === true;
    if (health.buttons) {
      all.hardwareButtons = health.buttons.listening === true;
      all.hardwareButtonsOn = health.buttons.switchedOn === true;
    }
    const text = (t) => (typeof t === 'function' ? t(all) : t);
    for (const spec of permissionSpecs(settingOn, settingVal)) {
      if (!spec.needed || all[spec.key] !== false) continue;
      // No screen at all: the adb line is the answer, in place of a
      // button that would open a dialog nobody can see.
      if (isHeadless()) {
        items.push({
          key: `perm:${spec.key}`,
          name: t('overviewPermissionMissing', {permission: deviceText(spec.name)}),
          desc: deviceText(adbHint(spec, all)),
          actions: [],
        });
        continue;
      }
      // No settings screen for it on this device: the adb line on the
      // Device page is the answer, not a button that opens nothing.
      if (spec.requestable && all[spec.requestable] === false) continue;
      items.push({
        key: `perm:${spec.key}`,
        name: t('overviewPermissionMissing', {permission: deviceText(spec.name)}),
        desc: deviceText(text(spec.missing)),
        action: (btn) => grantButton(btn, spec),
      });
    }
  }
  renderAttention(items);
  paintNowPlaying(media);
}
// The wake word engine and the Voice Satellite tile. A microphone grant
// it may have lost shows up through the service sample, which the device
// pushes on its own.
async function refreshWake() {
  await Promise.all([readSource('wake'), readSource('voice')]);
  paintHealth({ filter: false });
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
  if (live) el.textContent = overviewText('Live, every 5 seconds');
  else if (state.screenshotAt) el.textContent = t('overviewTaken', {age: agoLabel(new Date(state.screenshotAt))});
  else el.textContent = '';
}
// What the panel is doing, on the frame, so a black capture reads as the
// screen being off or the screensaver rather than as a broken kiosk.
export function paintShotBadge() {
  const el = $('#shotBadge');
  let icon = '';
  let text = '';
  // Topmost first, the way the kiosk stacks them: the call card covers
  // a camera wall, which covers the screensaver Now Playing fills.
  if (quick.screenOn === false) { icon = ICONS.screenOff; text = t('overviewScreenOffState'); }
  else if (quick.intercom === true) { icon = ICONS.intercom; text = intercomText('Intercom'); }
  else if (quick.cameraView?.active) {
    icon = ICONS.camera;
    text = quick.cameraView.viewName ? t('overviewCameraViewNamed', {name: quick.cameraView.viewName}) : overviewText('Camera view');
  } else if (quick.nowPlaying === true) { icon = ICONS.media; text = mediaText('Now playing'); }
  else if (quick.screensaverActive === true) { icon = ICONS.moon; text = overviewText('Screensaver'); }
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
  $('#npTitle').textContent = mediaText('Now playing');
  const show = !!(s && s.enabled && (s.playing || s.title));
  $('#npTitle').classList.toggle('hidden', !show);
  $('#npCard').classList.toggle('hidden', !show);
  npVisible = show;
  if (!show) return;
  $('#npTrack').textContent = s.title || mediaText('Unknown track');
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
  for (const button of document.querySelectorAll('#npCard [data-np]')) {
    const id = {previous: 'mediaPreviousTrack', next: 'mediaNextTrack', play: 'mediaPlay', pause: 'mediaPause'}[button.dataset.np];
    button.title = t(id);
    button.setAttribute('aria-label', button.title);
  }
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
  await readSource('media');
  paintNowPlaying(health.media);
}
$('#npArt img').addEventListener('error', function () { this.hidden = true; });
document.querySelectorAll('#npCard [data-np]').forEach((b) =>
  b.addEventListener('click', async () => {
    const res = await cmd('sendspinControl', { command: b.dataset.np }).catch(() => null);
    if (res && res.ok === false && res.error) {
      showToast({ title: b.title || navigationText('Media Player'), message: mediaError(res.error), kind: 'error' });
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
  healthTimer = setTimeout(refreshWake, 2000);
});

/* ---- Quick controls ---- */
// The discs cycle the brand accents like the nav rail, but a grid is not a
// list: painted in markup order, four colors over four columns put one
// color in each column. So the color comes from where a tile lands, its
// visible row plus column, which runs the cycle diagonally at any column
// count. Repainted when a tile shows or hides and when the grid reflows.
const DISC_CYCLE = ['d1', 'd2', 'd3', 'd4'];
function paintTileDiscs() {
  const grid = $('.grid.tiles');
  if (!grid) return;
  const tracks = getComputedStyle(grid).gridTemplateColumns;
  // A grid inside a hidden tab reports its authored tracks, not resolved
  // ones; the resize that shows it brings us back.
  if (!tracks || tracks.includes('repeat')) return;
  const columns = Math.max(1, tracks.split(' ').length);
  const tiles = [...grid.querySelectorAll('.action.tile')].filter((t) => !t.classList.contains('hidden'));
  tiles.forEach((tile, i) => {
    const disc = tile.querySelector('.disc');
    if (!disc) return;
    const want = DISC_CYCLE[(Math.floor(i / columns) + (i % columns)) % DISC_CYCLE.length];
    if (disc.classList.contains(want)) return;
    disc.classList.remove(...DISC_CYCLE);
    disc.classList.add(want);
  });
}
{
  const grid = $('.grid.tiles');
  if (grid) {
    new MutationObserver(paintTileDiscs).observe(grid, { attributes: true, attributeFilter: ['class'], subtree: true });
    new ResizeObserver(paintTileDiscs).observe(grid);
  }
}
// Restart device: only where a restart can land (device owner, or a granted
// Shizuku connection), so the tile never promises what the device refuses.
// Confirmed first like the drawer's entry: a reboot has no Retry.
async function paintRestartDeviceTile() {
  const res = await cmd('getDeviceRebootSupport').catch(() => null);
  const supported = !!(res && res.ok !== false && res.data && res.data.supported === true);
  $('#tileRestartDevice').classList.toggle('hidden', !supported);
}
$('#tileRestartDevice').addEventListener('click', async () => {
  const choice = await messageBox({
    title: 'Restart device',
    message: 'Restart this device? Kiosk Satellite comes back when it boots.',
    buttons: ['Cancel', 'Restart'],
  });
  if (choice !== 'Restart') return;
  const res = await cmd('rebootDevice').catch(() => null);
  if (res && res.ok !== false) showToast({ title: overviewText('Restart device'), kind: 'success' });
  else showToast({ title: overviewText('Restart device'), message: deviceOperationError(res && res.error) || overviewText('The device did not answer.'), kind: 'error' });
});

// Do not disturb: only with the intercom on and the remote admin there to
// carry it. The tile reads on while Answer mode is Do not disturb and
// flips it back to what it was before. Painted from the same status the
// Intercom page draws, and from the intercom event the device pushes.
let dnd = false;
function paintDndTile(s) {
  const tile = $('#tileDnd');
  const shown = !!(s && s.enabled === true && s.available !== false);
  tile.classList.toggle('hidden', !shown);
  if (!shown) return;
  dnd = s.dnd === true;
  tile.classList.toggle('active', dnd);
  overviewLabel(tile.querySelector('.disc + span'), dnd ? 'Do not disturb on' : 'Do not disturb');
}
async function refreshDndTile() {
  paintDndTile(await ask('intercomStatus'));
}
$('#tileDnd').addEventListener('click', async () => {
  const tile = $('#tileDnd');
  tile.disabled = true;
  try {
    const res = await cmd('intercomSetDnd', { on: !dnd }).catch(() => null);
    if (!res || res.ok === false) {
      showToast({ title: overviewText('Do not disturb'),
        message: (res && res.error) || overviewText('The device did not answer.'), kind: 'error' });
    }
    await refreshDndTile();
  } finally { tile.disabled = false; }
});
document.addEventListener('ks-event', (e) => {
  if (e.detail?.event !== 'intercom') return;
  if (e.detail.data && typeof e.detail.data === 'object') paintDndTile(e.detail.data);
});

/* ---- Alarm banner ----
   While an alarm rings, is snoozed or runs its sunrise, a banner over
   everything else on the page with Snooze (while ringing) and Stop.
   Painted from the alarmsStatus command on a visit and from the alarms
   event the device pushes, which carries the same status. */
let alarmState = null;
function paintAlarmBanner(s) {
  alarmState = s;
  const el = $('#alarmBanner');
  if (!el) return;
  const phase = s?.phase;
  const title = { ringing: t('alarmsRinging'), snoozed: t('alarmsSnoozed'),
    sunrise: t('alarmsSunriseRunning') }[phase];
  el.classList.toggle('hidden', !title);
  if (!title) { el.replaceChildren(); return; }
  const labels = (s.labels || []).filter(Boolean);
  const line = (phase === 'snoozed' && s.snoozedUntil
    ? [t('alarmsSnoozedUntil', { time: alarmClockText(s.snoozedUntil) }), ...labels]
    : [s.at ? alarmClockText(s.at) : '', ...labels]).filter(Boolean).join(' \u00b7 ');
  const icon = document.createElement('span');
  icon.className = 'alarm-banner-icon';
  icon.innerHTML = ALARM_ICON;
  const text = document.createElement('div');
  text.className = 'alarm-banner-text';
  const head = document.createElement('b');
  head.textContent = title;
  const sub = document.createElement('span');
  sub.textContent = line;
  text.append(head, sub);
  const actions = document.createElement('div');
  actions.className = 'alarm-banner-actions';
  const act = (label, cls, name) => {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = cls;
    b.textContent = label;
    b.addEventListener('click', async () => {
      b.disabled = true;
      const res = await cmd(name).catch(() => null);
      if (!res || res.ok === false) {
        showToast({ title: label, message: (res && res.error) || overviewText('The device did not answer.'), kind: 'error' });
        b.disabled = false;
      }
      paintAlarmBanner(await ask('alarmsStatus'));
    });
    return b;
  };
  if (phase === 'ringing') actions.appendChild(act(t('alarmsSnooze'), 'btn-ghost', 'alarmSnooze'));
  actions.appendChild(act(t('alarmsStop'), 'btn-primary', 'alarmStop'));
  el.replaceChildren(icon, text, actions);
}
async function refreshAlarmBanner() {
  paintAlarmBanner(await ask('alarmsStatus'));
}
document.addEventListener('ks-event', (e) => {
  if (e.detail?.event !== 'alarms') return;
  if (e.detail.data && typeof e.detail.data === 'object') paintAlarmBanner(e.detail.data);
});

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
        message: res?.error || 'The device did not answer.' }, error => cameraError(overviewText(error)));
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
    overviewLabel(img, 'Camera snapshot', 'alt');
    img.style.cssText = 'display:block; width:100%; border-radius:12px;';
    body.appendChild(img);
    const close = document.createElement('button');
    close.className = 'btn-text';
    overviewLabel(close, 'Close');
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
    await readSource('update');
    paintHealth({ filter: false });
    if (!res?.reachable) {
      await messageBox({ title: 'Check for updates',
        message: 'Update check failed. Can the device reach GitHub?' });
    } else if (!res.availableVersion) {
      await messageBox({ title: 'Check for updates', message: 'You are on the latest version.' });
    } else {
      showToast({ title: t('overviewVersionAvailable', {version: res.availableVersion}),
        message: overviewText('Install it from Needs attention.'), kind: 'info' });
    }
  } finally { tile.disabled = false; }
});

/* ---- Lifecycle ---- */
setInterval(() => {
  if (!onOverview()) return;
  if (live) loadScreenshot();

}, TICK_MS);
setInterval(() => { if (onOverview() && !live) paintTaken(); }, 1000);

// The page came back into view: a tab switch here, or the browser tab
// returning. Fresh reads, and a Live capture if the last one is stale.
export function overviewShown() {
  // The source watches re-read on entry (live.js); the wake word has no
  // topic of its own, so it is read here.
  readSource('wake').then(() => paintHealth({ filter: false }));
  refreshVolume();
  paintShotBadge();
  paintSnapshotTile();
  paintRestartDeviceTile();
  refreshDndTile();
  refreshAlarmBanner();
  paintTaken();
  if (live && (!state.screenshotAt || Date.now() - state.screenshotAt > TICK_MS)) loadScreenshot();
}
document.addEventListener('visibilitychange', () => { if (onOverview()) overviewShown(); });

// Boot: built behind the splash with the rest of the app, so the page
// opens populated rather than filling in.
export async function initOverview() {
  buildTiles();
  buildMetricTiles();
  paintShotMode();
  paintShotBadge();
  paintSnapshotTile();
  await Promise.all([refreshHealth(), refreshVolume(), paintRestartDeviceTile(), refreshDndTile(), refreshAlarmBanner(), readMetricHistory()]);
}

document.addEventListener('ks-settings-cached', () => {
  paintHealth({filter: false});
  // A language change: the banner's words, from the status already held.
  paintAlarmBanner(alarmState);
  paintShotMode();
  renderQuickControls();
});
