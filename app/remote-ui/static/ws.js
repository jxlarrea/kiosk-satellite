import { applyHeadless } from './headless.js';
import { t } from './localization.js';
import { attachSocket, detachSocket, receiveResult } from './transport.js';
import { receiveUpdate, syncSubscriptions } from './live.js';
import { applySettingsUpdate } from './settings.js';
import { setDeviceName } from './fleet.js';
import { renderMicLevel } from './audio.js';
import { $, api, apiUrl, logout, state } from './core.js';
import { appendLine, logView, updateConsoleMeta } from './logs.js';
import {
  showAdaptiveLight, showAdaptiveVolume, showExternalMotion, showLightLevel,
} from './notices.js';
import { applyFullscreenView, applyQuickEvent, applyQuickState, loadScreenshot, quickStateOf } from './panels.js';
import { loadVsPermissions, renderVsControls } from './vs.js';
import { modalShell, paintRange } from './widgets.js';

/* ---- Live state (WebSocket) ---- */
let reconnectTimer = null;
let retryDelay = 1000;
let heartbeat = null;
let lastMessage = 0;
// Resolved when the connection attempt in flight opens or gives up, so
// the boot can wait for the socket and read everything through it.
let settled = null;
let settle = () => {};
document.addEventListener('ks-logout', () => {
  clearTimeout(reconnectTimer);
  clearInterval(heartbeat);
  hideReconnecting();
});
/* A connection that was up and went away: the page is a mirror of the
   device and every control on it would now write into the void, so it is
   covered until the socket is back. Not for an attempt that never opened
   (the boot falls back to HTTP for that), and not for a logout. After a
   while the cover offers a reload, for a kiosk that is not coming back. */
let reconnectOverlay = null;
let reconnectSince = 0;
function showReconnecting() {
  if (reconnectOverlay) return;
  reconnectSince = Date.now();
  const back = document.createElement('div');
  back.className = 'modal-back reconnect-back';
  back.innerHTML = '<div class="card modal-card reconnect-card">'
    + '<span class="splash-spinner"></span>'
    + '<h3 class="modal-title"></h3>'
    + '<p class="reconnect-text"></p>'
    + '<button type="button" class="btn-ghost hidden"></button></div>';
  paintReconnecting(back);
  const reload = back.querySelector('button');
  reload.addEventListener('click', () => location.reload());
  document.body.appendChild(back);
  reconnectOverlay = back;
  const tick = () => {
    if (reconnectOverlay !== back) return;
    if (Date.now() - reconnectSince > 20000) reload.classList.remove('hidden');
    setTimeout(tick, 1000);
  };
  tick();
}
function paintReconnecting(back = reconnectOverlay) {
  if (!back) return;
  const name = state.device?.name || state.device?.model;
  back.querySelector('.modal-title').textContent = t('remoteReconnecting');
  back.querySelector('.reconnect-text').textContent = name
    ? t('remoteConnectionLost', { name }) : t('remoteConnectionLostUnnamed');
  back.querySelector('button').textContent = t('remoteReloadPage');
}
document.addEventListener('ks-settings-cached', () => paintReconnecting());
function hideReconnecting() {
  reconnectOverlay?.remove();
  reconnectOverlay = null;
}
export function socketSettled(timeoutMs = 3000) {
  if (state.ws?.readyState === WebSocket.OPEN || !settled) return Promise.resolve();
  return Promise.race([settled, new Promise((r) => setTimeout(r, timeoutMs))]);
}
export function connectWs() {
  clearTimeout(reconnectTimer);
  if (!state.token || (state.ws && state.ws.readyState < 2)) return;
  const url = new URL(apiUrl(`/api/ws?token=${state.token}`), location.href);
  url.protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
  const ws = new WebSocket(url);
  state.ws = ws;
  settled = new Promise((r) => { settle = r; });
  // The connect-time `state` snapshot is read across several awaits on the
  // device while the event feed already flows to this socket, so a change
  // landing inside that window arrives as its event first and then as a
  // snapshot that predates it. Per connection: a quick-control state an
  // event moved before the snapshot landed keeps the event's value.
  let snapshotSeen = false;
  const movedFirst = {};
  let opened = false;
  ws.onopen = () => {
    if (state.ws !== ws) { ws.close(); return; }
    opened = true;
    attachSocket(ws);
    retryDelay = 1000;
    lastMessage = Date.now();
    settle();
    hideReconnecting();
    setConn('on');
    syncSubscriptions({ reconnect: true });
    document.dispatchEvent(new CustomEvent('ks-connected'));
    clearInterval(heartbeat);
    heartbeat = setInterval(() => {
      if (Date.now() - lastMessage > 65000) { ws.close(); return; }
      if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify({ type: 'ping' }));
    }, 25000);
  };
  ws.onclose = async (event) => {
    if (state.ws !== ws) return;
    clearInterval(heartbeat);
    detachSocket(ws);
    state.ws = null;
    settle();
    setConn('off');
    if (event.code === 1008) { logout(); return; }
    if (opened && state.token) showReconnecting();
    // Upgrade failures hide their HTTP status from browser JavaScript.
    // A single authenticated read distinguishes expiry from an outage.
    const check = new AbortController();
    const deadline = setTimeout(() => check.abort(), 3000);
    try { await api('/api/commands', { method: 'HEAD', signal: check.signal }); } catch (_) {}
    finally { clearTimeout(deadline); }
    if (state.token) {
      reconnectTimer = setTimeout(connectWs, retryDelay + Math.random() * 500);
      retryDelay = Math.min(30000, retryDelay * 2);
    }
  };
  ws.onmessage = (ev) => {
    if (state.ws !== ws) return;
    lastMessage = Date.now();
    let msg;
    try { msg = JSON.parse(ev.data); } catch (_) { return; }
    if (receiveResult(msg) || msg.type === 'pong') return;
    if (msg.type === 'settings') { applySettingsUpdate(msg); return; }
    if (msg.type === 'update') { receiveUpdate(msg.topic, msg.results); return; }
    if (msg.type === 'state') {
      applyInfo(msg.device, msg.currentUrl, snapshotSeen ? {} : movedFirst);
      snapshotSeen = true;
      // The snapshot carries the build the device is running: after an
      // update the app restarts, this socket comes back, and the page
      // still holding the old admin bundle is the one that has to go.
      if (state.appVersion && versionOf(msg.device) && versionOf(msg.device) !== state.appVersion) {
        showVersionMismatch(msg.device);
      }
    }
    else if (msg.type === 'stats') renderStats(msg);
    else if (msg.type === 'console') { appendLine($('#consoleOut'), msg.level, msg.message, msg.time); updateConsoleMeta(); }
    else if (msg.type === 'log') {
      // Live pushes belong to the app log; don't interleave them into logcat.
      if (logView === 'app') appendLine($('#logsOut'), msg.entry.level, `${msg.entry.tag}: ${msg.entry.message}`, Date.parse(msg.entry.time));
    }
    else if (msg.type === 'event') {
      // Screen, screensaver and camera view changes relabel the
      // dashboard's quick-control tiles, and what the screen shows has
      // changed with them, so the screenshot follows a moment later.
      const moved = quickStateOf(msg.event);
      if (moved && !snapshotSeen) movedFirst[moved] = true;
      applyQuickEvent(msg.event, msg.data);
      if (moved) queueScreenshotRefresh();
      // The Overview listens for the rest (the volume fader follows the
      // tablet's rocker) without this module knowing the page.
      document.dispatchEvent(new CustomEvent('ks-event',
        { detail: { event: msg.event, data: msg.data } }));
    }
    // Now Playing or the intercom took over the screen or left it: the
    // badge says which, and the screenshot follows like the events above.
    else if (msg.type === 'fullscreen-view') {
      if (!snapshotSeen) movedFirst[msg.view] = true;
      applyFullscreenView(msg.view, msg.shown === true);
      queueScreenshotRefresh();
    }
    // The device's own settings screen updates live off the same event; this
    // panel has to as well, or the two disagree about the same device.
    else if (msg.type === 'wakeword-state') {
      queueVsControlsRefresh();
      document.dispatchEvent(new CustomEvent('ks-wakeword'));
    }
    // The screensaver and the card both dim behind our back.
    else if (msg.type === 'brightness') showBrightness(msg.level);
    else if (msg.type === 'lightlevel') showLightLevel(msg.lux);
    else if (msg.type === 'adaptivelight') showAdaptiveLight(msg);
    else if (msg.type === 'adaptivevolume') showAdaptiveVolume(msg);
    else if (msg.type === 'externalmotion') showExternalMotion(msg);
    else if (msg.type === 'micLevel') renderMicLevel(msg.rms);
  };
}
/* The screenshot after a screen, screensaver, camera view, Now Playing or
   intercom change: one capture a second after the last event (a dismiss
   lights the panel, stops the screensaver and redraws the page as three
   events in a row), giving the panel time to settle into what it will
   actually show. Not
   from a hidden tab: nobody is looking, and each capture makes the
   tablet read back and encode its screen. */
let screenshotTimer = null;
export function queueScreenshotRefresh() {
  if (document.hidden) return;
  clearTimeout(screenshotTimer);
  screenshotTimer = setTimeout(() => {
    screenshotTimer = null;
    loadScreenshot();
  }, 1000);
}

/* Wake-word state pushes arrive at the START and END of every voice turn
   (detection suspends while the tablet's own speaker answers). Refreshing
   the Voice Satellite panel per push made this page an accomplice in a
   per-turn freeze ON THE KIOSK: each refresh runs the vsControls snapshot
   over there, and an admin tab left open - usually in a background tab -
   was hammering it exactly while it tried to animate a voice turn. So:
   never refresh from a hidden tab (catch up on return instead), and
   coalesce the turn's start/end burst into one refresh after quiet. */
export let vsRefreshTimer = null;
export let vsRefreshPending = false;
export function queueVsControlsRefresh() {
  if (document.hidden) { vsRefreshPending = true; return; }
  clearTimeout(vsRefreshTimer);
  vsRefreshTimer = setTimeout(() => {
    vsRefreshTimer = null;
    // A wake state change can move the permissions story (a lost
    // microphone) and the controlled entities (an engine or wake word
    // change re-negotiates); follow along.
    const vsRoot = document.getElementById('tab-voicesatellite');
    if (vsRoot?.classList.contains('active') && document.getElementById('vsGeneralCard')) {
      loadVsPermissions();
      renderVsControls(vsRoot, { auto: true });
    }
  }, 2000);
}
document.addEventListener('visibilitychange', () => {
  if (!document.hidden && vsRefreshPending) {
    vsRefreshPending = false;
    queueVsControlsRefresh();
  }
});

export function setConn(s) { $('#connDot').className = `dot ${s}`; }
function versionOf(device) {
  if (!device?.appVersion) return '';
  return `${device.appVersion}+${device.buildNumber ?? ''}`;
}
/* The device came back on a different build than this page was loaded
   against. Everything here (the settings schema, the panels, the static
   bundle) belongs to the old one, so say so and reload; a countdown
   rather than an instant reload, so a person watching an update land
   sees why the page went away. */
let versionModal = null;
export function showVersionMismatch(device) {
  if (versionModal) return;
  const { back, body, foot } = modalShell({ title: t('remoteUpdated') });
  versionModal = back;
  const p = document.createElement('p');
  p.style.cssText = 'margin:0; color:var(--muted); font-size:15px; line-height:1.5;';
  body.appendChild(p);
  const now = document.createElement('button');
  now.className = 'btn-primary';
  now.textContent = t('remoteReloadNow');
  now.addEventListener('click', () => location.reload());
  foot.appendChild(now);
  let left = 5;
  const tick = () => {
    back.querySelector('.modal-title').textContent = t('remoteUpdated');
    now.textContent = t('remoteReloadNow');
    p.textContent = t('remoteUpdatedHelp', {
      version: device.appVersion,
      build: device.buildNumber ? t('remoteBuild', { build: device.buildNumber }) : '',
      seconds: left,
    });
    if (left-- <= 0) { location.reload(); return; }
    setTimeout(tick, 1000);
  };
  tick();
}
export function applyInfo(device, currentUrl, keepQuick = {}) {
  if (!device) return;
  // The build this page was loaded against: the first snapshot's.
  state.appVersion ||= versionOf(device);
  const name = device.name || device.model || '';
  setDeviceName(name);
  // The tab's name is the device's name: with several kiosks administered
  // side by side, "Kiosk Satellite Remote" three times is a guessing game.
  // Login keeps the static default; renames land on the next info refresh.
  if (name) document.title = name + ' - Kiosk Satellite Remote';
  applyHeadless(device.headless);
  renderStats(device);
  if (device.brightness != null) showBrightness(device.brightness);
  applyQuickState(device, keepQuick);
  state.device = device;
}

// Battery, CPU load and temperature in the header, from either the initial
// state or a live `stats` push. CPU/temp are null on platforms that decline
// (kept hidden rather than shown as a fake 0). Temp warms from muted → amber →
// red so a hot kiosk stands out at a glance.
export function setStat(cls, text, color) {
  document.querySelectorAll(cls).forEach((el) => {
    el.textContent = text ?? '';
    el.style.color = color || '';
  });
}
// A flat battery glyph in the UI's stroke-icon language (the emoji clashed
// with everything else). The body fills to the charge level; charging swaps
// the fill for a bolt.
export function batterySvg(level, charging) {
  const inner = charging
    ? '<path d="M11.2 8.6l-2.7 3.7h2.6l-1.5 3.1 4.2-4.4h-2.5l1.7-2.4z" fill="currentColor" stroke="none"/>'
    : `<rect x="4.5" y="9.5" width="${Math.max(0.8, 13 * Math.min(1, level / 100)).toFixed(1)}" height="5" rx="1" fill="currentColor" stroke="none"/>`;
  return '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round" style="vertical-align:-3px; margin-right:3px">'
    + '<rect x="2" y="7" width="18" height="10" rx="2.5"/><path d="M22.5 10.5v3" stroke-linecap="round"/>' + inner + '</svg>';
}
export function renderStats(o) {
  // Null on a device without a battery: the header slot stays empty
  // rather than showing a made-up percent (issue #367).
  document.querySelectorAll('.js-batt').forEach((el) => {
    el.innerHTML = o.battery == null
      ? '' : `${batterySvg(o.battery, o.charging)}${o.battery}%`;
  });
  setStat('.js-cpu', o.cpu != null ? `CPU ${Math.round(o.cpu)}%` : '');
  // The Overview's metric tiles read the same numbers (overview.js).
  document.dispatchEvent(new CustomEvent('ks-stats', { detail: o }));
  if (o.temp == null) { setStat('.js-temp', ''); return; }
  const t = Math.round(o.temp);
  setStat('.js-temp', `${t}°C`,
    t >= 80 ? 'var(--error)' : t >= 65 ? 'var(--warn)' : '');
}

// The slider is also a readout. It used to be born at 100 and only ever send,
// so a screensaver dimming the screen to nothing left it sitting at full;
// reporting a number nobody had measured.
export function showBrightness(level) {
  const pct = Math.round(level * 100);
  $('#brightness').value = pct;
  paintRange($('#brightness'));
  $('#brightnessValue').textContent = `${pct}%`;
}

document.addEventListener('ks-device-name', (e) => {
  setDeviceName(e.detail);
  document.title = e.detail + ' - Kiosk Satellite Remote';
});
