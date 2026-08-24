import { renderMicLevel } from './audio.js';
import { $, state } from './core.js';
import { appendLine, logView, updateConsoleMeta } from './logs.js';
import { loadScreenshot } from './panels.js';
import { loadVsPermissions, renderVsControls } from './vs.js';

/* ---- Live state (WebSocket) ---- */
export function connectWs() {
  const proto = location.protocol === 'https:' ? 'wss' : 'ws';
  const ws = new WebSocket(`${proto}://${location.host}/api/ws?token=${state.token}`);
  state.ws = ws;
  ws.onopen = () => {
    setConn('on');
    ws.send(JSON.stringify({ type: 'subscribe', topics: ['state', 'events', 'console', 'logs'] }));
  };
  ws.onclose = () => { setConn('off'); if (state.token) setTimeout(connectWs, 3000); };
  ws.onmessage = (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.type === 'state') applyInfo(msg.device, msg.currentUrl);
    else if (msg.type === 'stats') renderStats(msg);
    else if (msg.type === 'console') { appendLine($('#consoleOut'), msg.level, msg.message, msg.time); updateConsoleMeta(); }
    else if (msg.type === 'log') {
      // Live pushes belong to the app log; don't interleave them into logcat.
      if (logView === 'app') appendLine($('#logsOut'), msg.entry.level, `${msg.entry.tag}: ${msg.entry.message}`, Date.parse(msg.entry.time));
    }
    else if (msg.type === 'event' && msg.event === 'screenon') loadScreenshot();
    // The device's own settings screen updates live off the same event; this
    // panel has to as well, or the two disagree about the same device.
    else if (msg.type === 'wakeword-state') {
      queueVsControlsRefresh();
    }
    // The screensaver and the card both dim behind our back.
    else if (msg.type === 'brightness') showBrightness(msg.level);
    else if (msg.type === 'micLevel') renderMicLevel(msg.rms);
  };
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
    loadVsPermissions();
    const vsRoot = document.getElementById('tab-voicesatellite');
    if (vsRoot && document.getElementById('vsGeneralCard')) {
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
export function applyInfo(device, currentUrl) {
  if (!device) return;
  const name = device.name || device.model || '';
  $('#deviceName').textContent = name;
  // The tab's name is the device's name: with several kiosks administered
  // side by side, "Kiosk Satellite Remote" three times is a guessing game.
  // Login keeps the static default; renames land on the next info refresh.
  if (name) document.title = name + ' - Kiosk Satellite Remote';
  renderStats(device);
  if (currentUrl) $('#currentUrl').textContent = currentUrl;
  if (device.brightness != null) showBrightness(device.brightness);
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
  if (o.battery != null) {
    document.querySelectorAll('.js-batt').forEach((el) => {
      el.innerHTML = `${batterySvg(o.battery, o.charging)}${o.battery}%`;
    });
  }
  setStat('.js-cpu', o.cpu != null ? `CPU ${Math.round(o.cpu)}%` : '');
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
  $('#brightnessValue').textContent = `${pct}%`;
}
