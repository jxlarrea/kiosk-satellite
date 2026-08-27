import { api, state } from './core.js';
import { readOnlyRow } from './device.js';

/* No-camera notice: mirror of the device's page when the hardware has no
   camera at all (a ROM without a camera HAL, e.g. LineageOS on an Echo
   Show). The master switch renders off and disabled, its dependent rows
   disappear, and the notice says why. Runs (awaited) before the other

   camera panels, which read state.cameraPresent to stand down. */
export async function updateNoCameraNotice() {
  // The vision runtimes' answer rides the same probe pass (issue #331:
  // Android 7 cannot load them): the face rows, the schedule editor and
  // the Show fingers trigger read state.visionSupport to stand down.
  try {
    const res = await (await api('/api/commands/getVisionSupport', { method: 'POST', body: '{}' })).json();
    state.visionSupport = res.data && typeof res.data === 'object' ? res.data : null;
  } catch (_) { state.visionSupport = null; }
  try {
    const res = await (await api('/api/commands/hasDeviceCamera', { method: 'POST', body: '{}' })).json();
    state.cameraPresent = res.data !== false;
  } catch (_) { state.cameraPresent = true; return; }
  if (state.cameraPresent) return;
  const tab = document.getElementById('tab-camera');
  const anchor = tab.querySelector('[data-key="camera.enabled"]');
  if (!anchor) return;
  const input = anchor.querySelector('.switch input');
  if (input) { input.checked = false; input.disabled = true; }
  for (const key of ['camera.device', 'camera.snapshot_resolution',
    'camera.snapshots', 'camera.snapshot_interval', 'motion.sensor',
    'motion.sensor_off_delay', 'motion.fps', 'motion.sensitivity',
    'motion.start_delay']) {
    tab.querySelector(`[data-key="${key}"]`)?.remove();
  }
  // Emptied cards (the Motion Detection group) go too, headings included.
  for (const card of [...tab.querySelectorAll('.card')]) {
    if (card.children.length) continue;
    const heading = card.previousElementSibling;
    if (heading?.classList.contains('card-title')) heading.remove();
    card.remove();
  }
  if (tab.querySelector('.camera-missing-notice')) return;
  const row = readOnlyRow('No camera detected',
    'This device does not report any usable camera.', '');
  row.classList.add('camera-missing-notice');
  anchor.insertAdjacentElement('afterend', row);
}

/* Single-camera hardware (Echo Show 5: front only) gets no front/back
   picker, mirroring the device: the camera.device select is replaced by a
   plain row naming the only camera. The capture falls back to the camera
   present regardless of the stored value. */
export async function updateCameraFacingsRow() {
  if (state.cameraPresent === false) return;
  if (state.cameraFacings === undefined) {
    try {
      const res = await (await api('/api/commands/getCameraFacings', { method: 'POST', body: '{}' })).json();
      state.cameraFacings = Array.isArray(res.data) ? res.data : null;
    } catch (_) { state.cameraFacings = null; }
  }
  if (!state.cameraFacings || state.cameraFacings.length !== 1) return;
  const tab = document.getElementById('tab-camera');
  const sel = tab.querySelector('[data-key="camera.device"]');
  if (!sel) return;
  const label = state.cameraFacings[0] === 'back' ? 'Back' : 'Front';
  const row = readOnlyRow('Camera', 'The only camera this device has.', label);
  row.dataset.key = 'camera.device';
  sel.replaceWith(row);
}

export async function updateCameraGrantNotice() {
  if (state.cameraPresent === false) return;
  const cameraEnabled = (state.settings || [])
    .find((s) => s.key === 'camera.enabled');
  if (!cameraEnabled || cameraEnabled.value !== true) return;
  let granted;
  try {
    const res = await (await api('/api/commands/getSystemPermissions', { method: 'POST', body: '{}' })).json();
    granted = !!(res.data || {}).camera;
  } catch (_) { return; }
  if (granted) return;
  const tab = document.getElementById('tab-camera');
  const anchor = tab.querySelector('[data-key="camera.enabled"]');
  if (!anchor || tab.querySelector('.camera-grant-notice')) return;
  const row = readOnlyRow('Camera permission missing',
    'Without it the camera cannot be used. The grant dialog appears on the tablet screen.', '');
  row.classList.add('camera-grant-notice');
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = 'Grant on device';
  btn.style.cssText = 'flex-shrink:0;';
  btn.addEventListener('click', async () => {
    btn.disabled = true;
    try {
      await api('/api/commands/requestOsPermissions', { method: 'POST',
        body: JSON.stringify({ which: ['camera'] }) });
    } catch (_) {}
    for (let i = 0; i < 30; i++) {
      await new Promise((r) => setTimeout(r, 2500));
      try {
        const res = await (await api('/api/commands/getSystemPermissions', { method: 'POST', body: '{}' })).json();
        if ((res.data || {}).camera) { row.remove(); return; }
      } catch (_) {}
    }
    btn.disabled = false;
  });
  row.appendChild(btn);
  anchor.insertAdjacentElement('afterend', row);
}

/* Latest snapshot preview (remote admin only): the newest frame the device
   published, in its own group at the end of the Camera page (so the Motion
   Detection group is not buried under the image), with how long ago it was
   taken. Serves the server's cached frame - rendering this panel never
   drives a capture. While the Camera tab is on screen the "ago" label
   ticks and the frame is re-fetched every 15s so motion- and
   interval-driven snapshots show up on their own. */
export let cameraSnapshotTimer = null;
export function agoLabel(date) {
  const s = Math.max(0, Math.round((Date.now() - date.getTime()) / 1000));
  if (s < 5) return 'just now';
  if (s < 60) return `${s} seconds ago`;
  const m = Math.floor(s / 60);
  if (m < 60) return m === 1 ? '1 minute ago' : `${m} minutes ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return h === 1 ? '1 hour ago' : `${h} hours ago`;
  const d = Math.floor(h / 24);
  return d === 1 ? '1 day ago' : `${d} days ago`;
}
export async function updateCameraSnapshotPanel() {
  const tab = document.getElementById('tab-camera');
  tab.querySelector('.camera-snapshot-heading')?.remove();
  tab.querySelector('.camera-snapshot-card')?.remove();
  clearInterval(cameraSnapshotTimer);
  cameraSnapshotTimer = null;
  const byKey = Object.fromEntries((state.settings || []).map((s) => [s.key, s]));
  if (byKey['camera.enabled']?.value !== true) return;
  if (state.cameraPresent === false) return;
  const row = document.createElement('div');
  row.className = 'row camera-snapshot-row';
  row.style.flexWrap = 'wrap';
  const info = document.createElement('div');
  info.className = 'info';
  info.innerHTML = '<div class="name">Latest snapshot</div><div class="desc"></div>';
  const desc = info.querySelector('.desc');
  desc.textContent = 'No snapshot yet.';
  const img = document.createElement('img');
  img.alt = 'Latest camera snapshot';
  img.style.cssText = 'width:100%; border-radius:12px; margin-top:10px; display:none;';
  let at = null;
  const refresh = async () => {
    const res = await api('/api/camera/snapshot');
    if (!res.ok) return; // 404: nothing captured yet
    at = new Date(res.headers.get('X-Snapshot-At'));
    const old = img.src;
    img.src = URL.createObjectURL(await res.blob());
    img.style.display = '';
    if (old) URL.revokeObjectURL(old);
    desc.textContent = agoLabel(at);
  };
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = 'Take snapshot';
  btn.style.cssText = 'flex-shrink:0;';
  btn.addEventListener('click', async () => {
    btn.disabled = true;
    try {
      const res = await (await api('/api/commands/takeCameraSnapshot', {
        method: 'POST', body: '{}' })).json();
      if (res.ok) await refresh();
      else desc.textContent = res.error || 'Snapshot failed.';
    } catch (_) {} finally { btn.disabled = false; }
  });
  row.append(info, btn, img);
  const heading = document.createElement('h2');
  heading.className = 'card-title camera-snapshot-heading';
  heading.textContent = 'Latest snapshot';
  const card = document.createElement('div');
  card.className = 'card camera-snapshot-card';
  card.appendChild(row);
  tab.append(heading, card);
  try { await refresh(); } catch (_) {}
  let ticks = 0;
  cameraSnapshotTimer = setInterval(async () => {
    if (!row.isConnected) { clearInterval(cameraSnapshotTimer); return; }
    if (!tab.classList.contains('active')) return;
    if (at) desc.textContent = agoLabel(at);
    if (++ticks % 3 !== 0) return; // re-fetch the frame every third tick
    try { await refresh(); } catch (_) {}
  }, 5000);
}

/* The Device admin grant, surfaced right under "Turn screen off after",
   mirroring the device row: the screen-off timer fails quietly without
   the grant, so this row is what says why nothing turned off. */
export async function updateScreenOffAdminNotice() {
  let granted;
  try {
    const res = await (await api('/api/commands/getSystemPermissions', { method: 'POST', body: '{}' })).json();
    granted = !!(res.data || {}).deviceAdmin;
  } catch (_) { return; }
  if (granted) return;
  const tab = document.getElementById('tab-screensaver');
  const anchor = tab.querySelector('[data-key="screensaver.screen_off_minutes"]');
  if (!anchor || tab.querySelector('.screen-off-admin-notice')) return;
  const row = readOnlyRow('Device admin permission missing',
    'Without it the screen cannot be turned off. The grant dialog appears '
    + 'on the tablet screen.', '');
  row.classList.add('screen-off-admin-notice');
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = 'Grant on device';
  btn.style.cssText = 'flex-shrink:0;';
  btn.addEventListener('click', async () => {
    btn.disabled = true;
    try {
      await api('/api/commands/requestOsPermissions', { method: 'POST',
        body: JSON.stringify({ which: ['deviceAdmin'] }) });
    } catch (_) {}
    for (let i = 0; i < 30; i++) {
      await new Promise((r) => setTimeout(r, 2500));
      try {
        const res = await (await api('/api/commands/getSystemPermissions', { method: 'POST', body: '{}' })).json();
        if ((res.data || {}).deviceAdmin) { row.remove(); return; }
      } catch (_) {}
    }
    btn.disabled = false;
  });
  row.appendChild(btn);
  anchor.insertAdjacentElement('afterend', row);
}

/* The screensaver's motion switches follow the Camera section, mirroring
   the device: with the camera master switch off, "Dismiss on motion"
   renders disabled with the reason; with it on, a hint under the postpone
   row marks where the tuning rows used to sit - camera pick, frame rate
   and sensitivity are Camera-settings decisions now. */
export function updateMotionCameraRows() {
  const byKey = Object.fromEntries((state.settings || []).map((s) => [s.key, s]));
  const camOn = byKey['camera.enabled']?.value === true
    && state.cameraPresent !== false;
  const tab = document.getElementById('tab-screensaver');
  const dismiss = tab.querySelector('[data-key="screensaver.dismiss_on_motion"]');
  if (!dismiss) return;
  const note = (text) => {
    const div = document.createElement('div');
    div.className = 'row';
    div.style.cssText = 'font-size:12.5px; color:var(--muted);';
    div.textContent = text;
    return div;
  };
  if (!camOn) {
    const input = dismiss.querySelector('.switch input');
    if (input) { input.checked = false; input.disabled = true; }
    dismiss.insertAdjacentElement('afterend',
      note('Requires the camera. Turn it on in the Camera settings first.'));
  } else {
    const anchor = tab.querySelector('[data-key="screensaver.postpone_on_motion"]');
    if (anchor) {
      anchor.insertAdjacentElement('afterend',
        note('Motion detection is tuned in the Camera settings.'));
    }
  }
}

/* The face detection rows (issue #304), mirroring the device: with the
   camera master switch off, "Dismiss on face" renders disabled with the
   reason; with Dismiss on motion on, a warning under it says motion takes
   precedence and the face leg is idle; and a hint under the sensitivity
   slider marks where the shared tuning lives. Idempotent, so the toggle
   save path can re-run it when Dismiss on motion flips. */
export function updateFaceRows() {
  const byKey = Object.fromEntries((state.settings || []).map((s) => [s.key, s]));
  const camOn = byKey['camera.enabled']?.value === true
    && state.cameraPresent !== false;
  const tab = document.getElementById('tab-screensaver');
  if (!tab) return;
  for (const stale of tab.querySelectorAll('.face-note')) stale.remove();
  const face = tab.querySelector('[data-key="screensaver.dismiss_on_face"]');
  if (!face) return;
  const note = (text, warn) => {
    const div = document.createElement('div');
    div.className = 'row face-note';
    div.style.cssText = 'font-size:12.5px; color:var(--'
      + (warn ? 'warn' : 'muted') + ');';
    div.textContent = text;
    return div;
  };
  if (!camOn) {
    const input = face.querySelector('.switch input');
    if (input) { input.checked = false; input.disabled = true; }
    face.insertAdjacentElement('afterend',
      note('Requires the camera. Turn it on in the Camera settings first.'));
    return;
  }
  if (state.visionSupport && state.visionSupport.faces === false) {
    const input = face.querySelector('.switch input');
    if (input) { input.checked = false; input.disabled = true; }
    face.insertAdjacentElement('afterend',
      note(state.visionSupport.hint || 'Not available on this device.'));
    return;
  }
  if (byKey['screensaver.dismiss_on_motion']?.value === true) {
    face.insertAdjacentElement('afterend', note(
      'Dismiss on motion is on and takes precedence, so face detection '
      + 'stays idle until it is turned off.', true));
  }
  const sensitivity = tab.querySelector('[data-key="face.sensitivity"]');
  if (sensitivity) {
    sensitivity.insertAdjacentElement('afterend', note(
      'Frame rate, camera pick and startup delay are tuned in the Camera '
      + 'settings.'));
  }
}

/* The Dim screensaver warning, mirroring the device: Dim is the one mode
   the pause-dashboard optimization cannot help - there is no overlay, the
   page IS the display. Kept identical to the device's copy in
   settings_screen.dart. */
export function updateDimModeNotice() {
  const byKey = Object.fromEntries((state.settings || []).map((s) => [s.key, s]));
  if (byKey['screensaver.mode']?.value !== 'dim') return;
  const tab = document.getElementById('tab-screensaver');
  const anchor = tab.querySelector('[data-key="screensaver.dim_level"]');
  if (!anchor || tab.querySelector('.dim-mode-note')) return;
  const div = document.createElement('div');
  div.className = 'row dim-mode-note';
  div.style.cssText = 'font-size:12.5px; color:var(--warn);';
  div.textContent = 'WARNING: Dim keeps the dashboard visible, so the '
    + '"Pause dashboard during screensaver" optimization will not be applied '
    + 'and the dashboard keeps using CPU, GPU and battery.';
  anchor.insertAdjacentElement('afterend', div);
}

/* File Manager (remote admin only): browse device folders, download,
   upload and delete files. Two roots from the app: shared storage (gated
   on the "All files access" grant, requested on the device) and the app's
   own folder, which always works. */
export const filesState = { root: null, crumbs: [] };
