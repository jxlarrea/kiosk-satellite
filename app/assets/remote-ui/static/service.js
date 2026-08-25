import { api, cmd } from './core.js';
import { readOnlyRow } from './device.js';

/* ---- Kiosk Satellite Service page ---- */
// The device's Settings -> Device -> Kiosk Satellite Service page, mirrored:
// what the keep-alive foreground service is doing right now, why it is
// running, and the OS grants it needs for that. The page's one setting (the
// CPU wake lock) is rendered by the schema like any other row; this wraps
// it with the live cards above and below.

let pollTimer = null;

const fmtUptime = (ms) => {
  if (ms == null) return null;
  let s = Math.floor(ms / 1000);
  const d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600),
    m = Math.floor((s % 3600) / 60);
  return d ? `${d}d ${h}h` : h ? `${h}h ${m}m` : m ? `${m}m` : `${s}s`;
};

const get = async (name, params = {}) => {
  try { const r = await cmd(name, params); return r.ok ? r.data : null; }
  catch { return null; }
};

const titled = (title) => {
  const h = document.createElement('h2');
  h.className = 'card-title';
  h.textContent = title;
  const card = document.createElement('div');
  card.className = 'card';
  return [h, card];
};

export function renderServicePage(panel) {
  if (pollTimer) { clearInterval(pollTimer); pollTimer = null; }
  // Above the schema's own card: the status and the reasons.
  const [statusHead, statusCard] = titled('Status');
  const [whyHead, whyCard] = titled('Keeping it running');
  panel.prepend(statusHead, statusCard, whyHead, whyCard);
  // Below it: the grants, in the three-state shape of the Permissions
  // Manager on the same tab.
  const [permHead, permCard] = titled('Required system permissions');
  panel.append(permHead, permCard);

  const renderStatus = (st) => {
    statusCard.innerHTML = '';
    whyCard.innerHTML = '';
    if (!st) {
      statusCard.appendChild(readOnlyRow('Service',
        'Status unavailable.', ''));
      return;
    }
    const running = st.running === true;
    const fg = st.foreground === true;
    const up = fmtUptime(st.uptimeMs);
    statusCard.appendChild(readOnlyRow('Service',
      !running
        ? (st.error ? `Stopped: ${st.error}` : 'Stopped.')
        : fg
          ? (up ? `Running for ${up}.` : 'Running.')
          : 'Running without the foreground exemption.',
      running ? 'Running' : 'Stopped'));
    const types = (st.types || []);
    statusCard.appendChild(readOnlyRow('Foreground service types',
      'What the service declares to Android for the features it holds up.',
      types.length ? types.join(', ') : 'none'));
    statusCard.appendChild(readOnlyRow('CPU wake lock',
      st.cpuAwake === false
        ? 'Off: the setting below is off.'
        : st.cpuLockHeld
          ? 'Held: the screen is off.'
          : st.screenInteractive
            ? 'Released while the screen is on.'
            : 'Not held.',
      st.cpuLockHeld ? 'Held' : 'Released'));
    statusCard.appendChild(readOnlyRow('Wi-Fi lock',
      'Keeps the radio out of power saving through screen-off.',
      st.wifiLockHeld ? 'Held' : 'Released'));
    statusCard.appendChild(readOnlyRow('Notification',
      st.notificationsEnabled === false
        ? 'Hidden: notifications are turned off for the app. The service '
          + 'runs regardless.'
        : 'Shown in the notification shade while the service runs.',
      st.notificationsEnabled === false ? 'Hidden' : 'Shown'));
    const reasons = st.reasons || [];
    for (const r of reasons) {
      const row = readOnlyRow(r.title, r.detail, '');
      row.querySelector('span').remove();
      whyCard.appendChild(row);
    }
  };

  // Three states, like the Permissions Manager: granted, missing (and
  // something switched on needs it), or merely not granted.
  const permRow = (name, held, missing, idle, ask) => {
    const row = document.createElement('div');
    row.className = 'row';
    const info = document.createElement('div');
    info.className = 'info';
    info.innerHTML = '<div class="name"></div><div class="desc"></div>';
    info.querySelector('.name').textContent = name;
    info.querySelector('.desc').textContent = 'Checking...';
    row.appendChild(info);
    const state = document.createElement('span');
    state.style.whiteSpace = 'nowrap';
    row.appendChild(state);
    row._render = (granted, needed) => {
      const ok = granted === true;
      info.querySelector('.desc').textContent =
        granted == null ? 'Status unavailable.' : ok ? held : needed ? missing : idle;
      info.querySelector('.desc').style.color =
        ok || needed || granted == null ? '' : 'var(--muted)';
      state.textContent = granted == null ? '' : ok ? 'Granted' : needed ? 'Missing' : 'Not granted';
      state.style.color = ok ? 'var(--ok)' : needed ? 'var(--error)' : 'var(--muted)';
      row.querySelector('button')?.remove();
      if (ok || granted == null) return;
      const btn = document.createElement('button');
      btn.className = 'btn-ghost';
      btn.textContent = 'Grant on device';
      btn.style.cssText = 'flex-shrink:0;';
      btn.addEventListener('click', async () => {
        btn.disabled = true;
        try {
          await api('/api/commands/requestOsPermissions', {
            method: 'POST', body: JSON.stringify({ which: ask }) });
        } catch (_) { }
        // The grant happens on the tablet; keep re-reading until it lands
        // so the row flips by itself.
        let tries = 30;
        const tick = setInterval(async () => {
          const now = await refreshPerms();
          if (now === true || --tries <= 0) clearInterval(tick);
        }, 2000);
      });
      row.appendChild(btn);
    };
    return row;
  };

  const ROWS = {
    batteryUnrestricted: permRow('Unrestricted battery',
      'Allows the process to run in the background without being paused or killed.',
      'Android may pause the app when the screen is off, dropping the Home '
        + 'Assistant connection and the MQTT entities with it.',
      '', ['batteryOptimizations']),
    displayOverOtherApps: permRow('Display over other apps',
      'Kiosk Satellite can bring itself back in the foreground.',
      'Without this the service cannot relaunch the kiosk after a crash or '
        + 'a close from recents.',
      'Needed to relaunch the kiosk after a crash.', ['overlay']),
    notification: permRow('Notifications',
      "The service's notification is shown.",
      "The service's notification is not shown.",
      'Without it the service still runs; its notification is not shown.',
      ['notifications']),
    microphone: permRow('Microphone',
      'Allows microphone usage for wake word detection and speech to text.',
      'Background listening is on and nothing is listening.',
      'Needed by background listening.', ['microphone']),
    camera: permRow('Camera',
      'Motion detection and snapshots can use the camera.',
      'The camera is switched on and cannot be opened.',
      'Needed by motion detection.', ['camera']),
    bluetooth: permRow('Nearby devices',
      'The Bluetooth proxy can scan for nearby devices.',
      'The Bluetooth proxy is switched on and cannot scan.',
      'Needed by the Bluetooth proxy to scan for devices.',
      ['bluetoothScan', 'bluetoothConnect']),
  };
  // Always: the three the service needs whatever runs. The feature rows
  // only appear while their feature is one of the reasons.
  const ALWAYS = ['batteryUnrestricted', 'displayOverOtherApps', 'notification'];
  const FEATURE = { microphone: 'listening', camera: 'camera', bluetooth: 'bluetooth' };

  let grants = {};
  let reasonIds = new Set();
  const placeRows = () => {
    permCard.innerHTML = '';
    for (const k of ALWAYS) permCard.appendChild(ROWS[k]);
    for (const [k, reason] of Object.entries(FEATURE)) {
      if (reasonIds.has(reason)) permCard.appendChild(ROWS[k]);
    }
  };

  // Returns whether every row now reads granted, for the button polls.
  const refreshPerms = async () => {
    const p = await get('getSystemPermissions');
    if (!p) {
      for (const row of Object.values(ROWS)) row._render(null, false);
      return null;
    }
    let all = true;
    for (const [k, row] of Object.entries(ROWS)) {
      if (!row.isConnected) continue;
      const granted = p[k] === true;
      row._render(granted, grants[k] === true);
      if (!granted) all = false;
    }
    return all;
  };

  const refresh = async () => {
    const st = await get('getServiceStatus');
    renderStatus(st);
    grants = st?.grants || {};
    reasonIds = new Set((st?.reasons || []).map((r) => r.id));
    placeRows();
    await refreshPerms();
  };

  refresh();
  // Live while the page is open; the next render() replaces the panel and
  // this timer with it. Every command the page sends is a line in the
  // device's log, so this stays slow enough not to drown it.
  pollTimer = setInterval(() => {
    if (!panel.isConnected) { clearInterval(pollTimer); pollTimer = null; return; }
    if (!panel.classList.contains('open')) return;
    refresh();
  }, 10000);
}
