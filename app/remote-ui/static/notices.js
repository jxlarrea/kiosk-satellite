import { cameraText, cameraError, screenAudioText, screensaverText, t } from './localization.js';
import { watchUpdates } from './live.js';
import { hintRow } from './widgets.js';
import { api, cmd, state } from './core.js';
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
    'camera.disable_detection_snapshots', 'camera.snapshots',
    'camera.snapshot_interval', 'motion.sensor',
    'motion.sensor_off_delay', 'motion.fps', 'motion.sensitivity',
    'motion.start_delay']) {
    tab.querySelector(`[data-key="${key}"]`)?.remove();
  }
  tab.querySelectorAll('[data-key^="camera.rtsp."], [data-key^="camera.onvif."], .subpage[data-subpage="RTSP & ONVIF Streaming"], .subpage-entry[data-subpage-entry="RTSP & ONVIF Streaming"], .subpage[data-subpage="Motion Sensor"], .subpage-entry[data-subpage-entry="Motion Sensor"]')
    .forEach((row) => row.remove());
  // Remove empty cards and their headings too.
  for (const card of [...tab.querySelectorAll('.card')]) {
    if (card.children.length) continue;
    const heading = card.previousElementSibling;
    if (heading?.classList.contains('card-title')) heading.remove();
    card.remove();
  }
  if (tab.querySelector('.camera-missing-notice')) return;
  const row = readOnlyRow(cameraText('No camera detected'),
    cameraText('This device does not report any usable camera.'), '');
  row.classList.add('camera-missing-notice');
  anchor.insertAdjacentElement('afterend', row);
}

/* Single-camera hardware (Echo Show 5: front only) gets no front/back
   picker, mirroring the device: the camera.device select is replaced by a
   plain row naming the only camera. The capture falls back to the camera
   present regardless of the stored value. */
export async function updateCameraFacingsRow() {
  if (state.cameraPresent === false) return;
  try {
    await api('/api/commands/getCameraStreamResolutions', { method: 'POST', body: '{}' });
  } catch (_) {}
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
  const facing = state.cameraFacings[0];
  const label = facing === 'back' ? cameraText('Back')
    : facing === 'external' ? cameraText('External') : cameraText('Front');
  const row = readOnlyRow(cameraText('Camera'), cameraText('The only camera this device has.'), label);
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
  const row = readOnlyRow(cameraText('Camera permission missing'),
    cameraText('Without it the camera cannot be used. The grant dialog appears on the tablet screen.'), '');
  row.classList.add('camera-grant-notice');
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = cameraText('Grant on device');
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
  if (s < 5) return cameraText('just now');
  if (s < 60) return t('cameraSecondsAgo', {count: String(s)});
  const m = Math.floor(s / 60);
  if (m < 60) return m === 1 ? cameraText('1 minute ago') : t('cameraMinutesAgo', {count: String(m)});
  const h = Math.floor(m / 60);
  if (h < 24) return h === 1 ? cameraText('1 hour ago') : t('cameraHoursAgo', {count: String(h)});
  const d = Math.floor(h / 24);
  return d === 1 ? cameraText('1 day ago') : t('cameraDaysAgo', {count: String(d)});
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
  info.innerHTML = '<div class="name"></div><div class="desc"></div>';
  info.querySelector('.name').textContent = cameraText('Latest snapshot');
  const desc = info.querySelector('.desc');
  desc.textContent = cameraText('No snapshot yet.');
  const img = document.createElement('img');
  img.alt = cameraText('Latest camera snapshot');
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
  btn.textContent = cameraText('Take snapshot');
  btn.style.cssText = 'flex-shrink:0;';
  btn.addEventListener('click', async () => {
    btn.disabled = true;
    try {
      const res = await (await api('/api/commands/takeCameraSnapshot', {
        method: 'POST', body: '{}' })).json();
      if (res.ok) await refresh();
      else desc.textContent = cameraError(res.error || 'Snapshot failed.');
    } catch (_) {} finally { btn.disabled = false; }
  });
  row.append(info, btn, img);
  const heading = document.createElement('h2');
  heading.className = 'card-title camera-snapshot-heading';
  heading.textContent = cameraText('Latest snapshot');
  const card = document.createElement('div');
  card.className = 'card camera-snapshot-card';
  card.appendChild(row);
  tab.append(heading, card);
  try { await refresh(); } catch (_) {}
  watchUpdates(['camera-snapshot'], refresh, { owner: row });
  cameraSnapshotTimer = setInterval(async () => {
    if (!row.isConnected) { clearInterval(cameraSnapshotTimer); return; }
    if (!tab.classList.contains('active')) return;
    if (at) desc.textContent = agoLabel(at);
  }, 5000);
}

/* The Device admin grant, surfaced right under "Turn screen off after",
   mirroring the device row: the screen-off timer fails quietly without
   the grant, so this row is what says why nothing turned off. */
let screenOffAdminGranted;
export async function updateScreenOffAdminNotice() {
  syncScreenOffAdminNotice();
  try {
    const res = await (await api('/api/commands/getSystemPermissions', { method: 'POST', body: '{}' })).json();
    screenOffAdminGranted = !!(res.data || {}).deviceAdmin;
  } catch (_) { return; }
  syncScreenOffAdminNotice();
}

// Keep the notice below the action toggle so showing it never moves that toggle.
export function syncScreenOffAdminNotice() {
  const tab = document.getElementById('tab-screensaver');
  if (!tab) return;
  const existing = tab.querySelector('.screen-off-admin-notice');
  const blank = state.settings?.some(s => s.key === 'screensaver.screen_off_black' && s.value === true);
  if (blank || screenOffAdminGranted !== false) {
    existing?.remove();
    return;
  }
  const anchor = tab.querySelector('[data-key="screensaver.screen_off_black"]')
    || tab.querySelector('[data-key="screensaver.screen_off_minutes"]');
  if (!anchor) return;
  if (existing) {
    if (anchor.nextElementSibling !== existing) anchor.after(existing);
    return;
  }
  const row = readOnlyRow(screensaverText('Device admin permission missing'),
    screensaverText('Without it the screen cannot be turned off. The grant dialog appears '
    + 'on the tablet screen.'), '');
  row.classList.add('screen-off-admin-notice');
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = screensaverText('Grant on device');
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
        if ((res.data || {}).deviceAdmin) {
          screenOffAdminGranted = true;
          syncScreenOffAdminNotice();
          return;
        }
      } catch (_) {}
    }
    btn.disabled = false;
  });
  row.appendChild(btn);
  anchor.insertAdjacentElement('afterend', row);
}

/* The screensaver's motion switches follow the Camera section, mirroring
   the device: with the camera master switch off, "Dismiss on motion"
   renders disabled with the reason, unless a Home Assistant entity
   detects motion in the camera's place (issue #973); with it on, a hint
   under the postpone row marks where the tuning rows used to sit - camera
   pick, frame rate and sensitivity are Camera-settings decisions now.
   Idempotent, so the save path re-runs it when the entity switch flips. */
export function updateMotionCameraRows() {
  const byKey = Object.fromEntries((state.settings || []).map((s) => [s.key, s]));
  const camOn = byKey['camera.enabled']?.value === true
    && state.cameraPresent !== false;
  const entityOn = byKey['motion.use_entity']?.value === true;
  const tab = document.getElementById('tab-screensaver');
  if (!tab) return;
  for (const stale of tab.querySelectorAll('.motion-camera-note')) stale.remove();
  const dismiss = tab.querySelector('[data-key="screensaver.dismiss_on_motion"]');
  if (!dismiss) return;
  const note = (text) => hintRow(text, { className: 'motion-camera-note' });
  const input = dismiss.querySelector('.switch input');
  if (input) {
    input.disabled = false;
    input.checked = byKey['screensaver.dismiss_on_motion']?.value === true;
  }
  if (!camOn && !entityOn) {
    if (input) { input.checked = false; input.disabled = true; }
    dismiss.insertAdjacentElement('afterend',
      note(screensaverText('Requires the camera. Turn it on in the Camera settings first.')));
  } else if (camOn) {
    const anchor = tab.querySelector('[data-key="screensaver.postpone_on_motion"]');
    if (anchor) {
      anchor.insertAdjacentElement('afterend',
        note(screensaverText('Motion detection is tuned in the Camera settings.')));
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
  const note = (text, warn) => hintRow(text, { warn, className: 'face-note' });
  if (!camOn) {
    const input = face.querySelector('.switch input');
    if (input) { input.checked = false; input.disabled = true; }
    face.insertAdjacentElement('afterend',
      note(screensaverText('Requires the camera. Turn it on in the Camera settings first.')));
    return;
  }
  if (state.visionSupport && state.visionSupport.faces === false) {
    const input = face.querySelector('.switch input');
    if (input) { input.checked = false; input.disabled = true; }
    face.insertAdjacentElement('afterend',
      note(screensaverText(state.visionSupport.hint || 'Not available on this device.')));
    return;
  }
  if (byKey['screensaver.dismiss_on_motion']?.value === true) {
    face.insertAdjacentElement('afterend', note(
      screensaverText("Dismiss on motion is on and takes precedence, so face detection stays idle until it is turned off."), true));
  }
  const sensitivity = tab.querySelector('[data-key="face.sensitivity"]');
  if (sensitivity) {
    sensitivity.insertAdjacentElement('afterend', note(
      screensaverText("Frame rate, camera pick and startup delay are tuned in the Camera settings.")));
  }
}

/* The proximity detection rows, mirroring the device. The switch
   renders off and disabled with the reason on a device without a
   proximity sensor; where there is one, a read-only row under the switch
   names it, because the name is what tells a hover sensor from a phone's
   call-only palm sensor. The answer is asked once per page load. */
export async function updateProximityRows() {
  if (state.proximitySupport === undefined) {
    try {
      const res = await (await api('/api/commands/getProximitySupport',
        { method: 'POST', body: '{}' })).json();
      state.proximitySupport = res.data && typeof res.data === 'object' ? res.data : null;
    } catch (_) { state.proximitySupport = null; }
  }
  const tab = document.getElementById('tab-screensaver');
  if (!tab) return;
  for (const stale of tab.querySelectorAll('.proximity-note')) stale.remove();
  const row = tab.querySelector('[data-key="screensaver.dismiss_on_proximity"]');
  if (!row) return;
  const support = state.proximitySupport;
  if (support && support.supported === false) {
    const input = row.querySelector('.switch input');
    if (input) { input.checked = false; input.disabled = true; }
    row.insertAdjacentElement('afterend', hintRow(
      screensaverText(support.hint || 'Not available on this device.'),
      { className: 'proximity-note' }));
    return;
  }
  if (!support || !support.name) return;
  const sensor = readOnlyRow(screensaverText('Sensor'), screensaverText(PROXIMITY_SENSOR_NOTE), support.name, false);
  sensor.classList.add('proximity-note');
  const value = sensor.lastElementChild;
  value.style.whiteSpace = 'normal';
  value.style.textAlign = 'right';
  row.insertAdjacentElement('afterend', sensor);
}

/* The adaptive brightness rows (issue #343), mirroring the device. On a
   device without an ambient light sensor a note under the switch says so;
   the switch stays usable, since a Home Assistant entity can stand in
   (issue #911). With one, a live reading sits under the switch (the
   curve's two light levels are typed against it, and what a sensor calls
   a lit room is anyone's guess until it is on screen; the value updates
   off the WebSocket's lightlevel messages). The curve editor marks the
   reading adaptive brightness follows, the sensor's or the entity's, off
   the adaptivelight messages. With the switch
   on, the Default brightness slider stands down with the reason, and a
   hint under each screensaver brightness slider says the slider is the
   bright-room level the room's light dims from. Idempotent, so the save
   path re-runs it when the switch flips. The sensor is asked about once
   per page load, the light adaptive brightness follows again when
   [reprobe] says its source changed. */
export async function updateAdaptiveBrightnessRows({ reprobe = false } = {}) {
  await Promise.all([probeLightSensor(), probeAdaptiveLight(reprobe)]);
  for (const stale of document.querySelectorAll('.adaptive-note')) stale.remove();
  const note = (text) => hintRow(screenAudioText(text), { className: 'adaptive-note' });
  const row = document.querySelector('[data-key="screen.adaptive_brightness"]');
  const byKey = Object.fromEntries((state.settings || []).map((s) => [s.key, s]));
  const adaptiveOn = byKey['screen.adaptive_brightness']?.value === true;
  // The Overview slider turns a setting, and which one depends on the
  // switch: say so under it, the way the Screen light's docs do.
  const modeRow = document.getElementById('brightnessModeRow');
  if (modeRow) {
    modeRow.style.display = '';
    document.getElementById('brightnessMode').textContent = adaptiveOn
      ? screenAudioText('Sets Maximum brightness: adaptive brightness is on.')
      : screenAudioText('Sets Default brightness.');
  }
  const defaultRow = document.querySelector('[data-key="screen.default_brightness"]');
  const defaultSlider = defaultRow?.querySelector('input[type="range"]');
  if (defaultSlider) defaultSlider.disabled = false;
  if (row && state.lightSensor === false) {
    row.insertAdjacentElement('afterend', note(NO_LIGHT_SENSOR_NOTE));
  }
  // The curve editor and the entity row may have been built before the
  // probe answered.
  document.dispatchEvent(new CustomEvent('ks-adaptivelight'));
  if (row && state.lightSensor) {
    const reading = readOnlyRow(screenAudioText('Ambient light'), screenAudioText(AMBIENT_LIGHT_NOTE),
      formatLux(state.lightLux));
    reading.classList.add('adaptive-note');
    reading.lastElementChild.classList.add('ambient-light-value');
    row.insertAdjacentElement('afterend', reading);
  }
  if (!adaptiveOn) return;
  if (defaultRow) {
    if (defaultSlider) defaultSlider.disabled = true;
    defaultRow.insertAdjacentElement('afterend', note(ADAPTIVE_OWNS_NOTE));
  }
  for (const key of ['screensaver.brightness_level', 'screensaver.dim_level']) {
    const slider = document.querySelector(`[data-key="${key}"]`);
    if (slider) slider.insertAdjacentElement('afterend', note(ADAPTIVE_NOTE));
  }
}

/* The sensor is asked about once per page load; the adaptive brightness
   rows and the Clock screensaver's Night mode share the answer, and a
   shared in-flight promise keeps the two from asking twice at once. */
let lightSensorProbe;
function probeLightSensor() {
  if (state.lightSensor !== undefined) return Promise.resolve();
  lightSensorProbe ??= (async () => {
    try {
      const res = await (await api('/api/commands/getLightLevel',
        { method: 'POST', body: '{}' })).json();
      const data = res.data && typeof res.data === 'object' ? res.data : null;
      state.lightSensor = data ? data.present === true : null;
      if (data && typeof data.lux === 'number') {
        state.lightLux = data.lux;
        state.lightLive = data.live === true;
      }
    } catch (_) { state.lightSensor = null; }
  })();
  return lightSensorProbe;
}

/* Night mode on the Clock screensaver page (issue #391), mirroring the
   device: on a device without an ambient light sensor the switch renders
   off and disabled with the reason. With one, the generic rows already
   say everything. Idempotent, like the adaptive rows above. */
export async function updateClockNightRows() {
  await probeLightSensor();
  for (const stale of document.querySelectorAll('.clock-night-note')) stale.remove();
  if (state.lightSensor !== false) return;
  const row = document.querySelector('[data-key="screensaver.clock_night"]');
  if (!row) return;
  const input = row.querySelector('.switch input');
  if (input) { input.checked = false; input.disabled = true; }
  row.insertAdjacentElement('afterend',
    hintRow(screenAudioText(NO_LIGHT_SENSOR_NOTE), { className: 'clock-night-note' }));
}

/* The adaptive volume rows (issue #1450), mirroring the device: under the
   switch, the room's noise level as adaptive volume follows it, live off
   the adaptivevolume messages, and the rule that makes it trustworthy:
   the room is only measured while the kiosk is silent. With no reading a
   second note says what one needs. The curve editor marks
   the same level. Idempotent, so the save path re-runs it when the switch
   flips. */
const ROOM_NOISE_NOTE = 'What the microphone reads while this device is silent.';
const ROOM_NOISE_HOLDS_NOTE = 'The reading holds while this device plays. Changes in the room '
  + 'during playback are not used.';
const ROOM_NOISE_NO_READING_NOTE = 'If there is no reading, turn on adaptive volume or wake word '
  + 'detection and check that the microphone is not muted.';

const hasRoomNoise = () => typeof state.adaptiveVolume?.noise === 'number';
const roomNoiseText = () => (hasRoomNoise()
  ? t('screenAudioDbfs', { level: String(Math.round(state.adaptiveVolume.noise)) })
  : screenAudioText('No reading yet'));

export async function updateAdaptiveVolumeRows() {
  await probeAdaptiveVolume();
  for (const stale of document.querySelectorAll('.adaptive-volume-note')) stale.remove();
  // The curve editor may have been built before the probe answered.
  document.dispatchEvent(new CustomEvent('ks-adaptivevolume'));
  const row = document.querySelector('[data-key="audio.adaptive_volume"]');
  if (!row) return;
  const reading = readOnlyRow(screenAudioText('Room noise'), screenAudioText(ROOM_NOISE_NOTE),
    roomNoiseText());
  reading.classList.add('adaptive-volume-note');
  reading.lastElementChild.classList.add('room-noise-value');
  const holds = hintRow(screenAudioText(ROOM_NOISE_HOLDS_NOTE), { className: 'adaptive-volume-note' });
  const needsWake = hintRow(screenAudioText(ROOM_NOISE_NO_READING_NOTE),
    { className: 'adaptive-volume-note room-noise-needs-wake' });
  needsWake.style.display = hasRoomNoise() ? 'none' : '';
  row.after(reading, holds, needsWake);
  await updateVolumeTestRows();
}

/* The Test volume group under the curve, mirroring the device
   (settings_screen.dart, _VolumeTestRows): one button plays a Voice
   Satellite announcement at the Assistant volume, the other an ESPHome
   announcement at the Media volume, each at the level the room picks now.
   A button waits for its feature to be set up. Idempotent: the save path
   re-runs it when the switch, Voice Satellite or announcements change. */
const ASSISTANT_TEST_HINT = 'Plays a Voice Satellite announcement at the Assistant volume. '
  + 'Needs Voice Satellite set up in Home Assistant.';
const MEDIA_TEST_HINT = 'Plays an ESPHome announcement at the Media volume. Needs '
  + 'Announcements turned on under ESPHome.';
const VOLUME_TEST_MESSAGE = 'This is how loud an announcement plays right now.';

export async function updateVolumeTestRows() {
  for (const stale of document.querySelectorAll('.volume-test-group')) stale.remove();
  const curveCard = document.querySelector('[data-key="audio.adaptive_volume_curve"]')
    ?.closest('.card');
  if (!curveCard) return;
  const heading = document.createElement('h2');
  heading.className = 'card-title volume-test-group';
  heading.textContent = screenAudioText('Test volume');
  const card = document.createElement('div');
  card.className = 'card volume-test-group';
  const byKey = Object.fromEntries((state.settings || []).map((s) => [s.key, s]));
  const mediaReady = byKey['esphome.enabled']?.value === true
    && byKey['announcements.enabled']?.value === true;
  const assistant = testRow('Test Assistant volume', ASSISTANT_TEST_HINT, false,
    () => cmd('voiceTestAnnouncement', { message: screenAudioText(VOLUME_TEST_MESSAGE) }));
  const media = testRow('Test Media volume', MEDIA_TEST_HINT, mediaReady,
    () => cmd('announce', { message: screenAudioText(VOLUME_TEST_MESSAGE), audio_only: true }));
  card.append(assistant.row, media.row);
  curveCard.after(heading, card);
  // The satellite entity is the device's to know: the button stays off
  // until it answers.
  try {
    const voice = (await cmd('voiceStatus'))?.data;
    assistant.setReady(voice?.enabled === true && !!voice?.satelliteEntity);
  } catch (_) {}
}

function testRow(title, hint, ready, run) {
  const row = readOnlyRow(screenAudioText(title), screenAudioText(hint), '');
  const button = document.createElement('button');
  button.className = 'btn-ghost';
  button.textContent = screenAudioText('Test');
  button.style.cssText = 'flex-shrink:0;';
  button.disabled = !ready;
  button.addEventListener('click', async () => {
    button.disabled = true;
    button.textContent = screenAudioText('Playing');
    let ok = false;
    try { ok = (await run())?.ok === true; } catch (_) {}
    if (ok) {
      button.textContent = screenAudioText('Test');
      button.disabled = false;
      return;
    }
    button.textContent = screenAudioText('Failed');
    setTimeout(() => { button.textContent = screenAudioText('Test'); button.disabled = false; }, 2000);
  });
  row.appendChild(button);
  return { row, setReady: (value) => { button.disabled = !value; } };
}

/* Adaptive volume's state, asked about once per page load; the
   adaptivevolume messages keep it current after that. */
let adaptiveVolumeProbe;
function probeAdaptiveVolume() {
  adaptiveVolumeProbe ??= (async () => {
    try {
      const res = await (await api('/api/commands/getAdaptiveVolume',
        { method: 'POST', body: '{}' })).json();
      const data = res.data && typeof res.data === 'object' ? res.data : null;
      // A message that beat the answer is the newer of the two.
      if (data && state.adaptiveVolume === undefined) showAdaptiveVolume(data, false);
    } catch (_) {}
  })();
  return adaptiveVolumeProbe;
}

/* The room's level and each volume's share of its slider, from the
   WebSocket: the Room noise row and the curve's marker repaint off it. */
export function showAdaptiveVolume(msg, notify = true) {
  state.adaptiveVolume = {
    noise: typeof msg.noise === 'number' ? msg.noise : null,
    assistant: msg.assistant,
    media: msg.media,
    intercom: msg.intercom,
  };
  for (const el of document.querySelectorAll('.room-noise-value')) el.textContent = roomNoiseText();
  for (const el of document.querySelectorAll('.room-noise-needs-wake')) {
    el.style.display = hasRoomNoise() ? 'none' : '';
  }
  if (notify) document.dispatchEvent(new CustomEvent('ks-adaptivevolume'));
}

/* The light level adaptive brightness follows, asked about once per page
   load and again when its source changes; the adaptivelight messages
   keep it current in between. */
let adaptiveLightProbe;
function probeAdaptiveLight(reprobe) {
  if (reprobe) adaptiveLightProbe = undefined;
  adaptiveLightProbe ??= (async () => {
    try {
      const res = await (await api('/api/commands/getAdaptiveLight',
        { method: 'POST', body: '{}' })).json();
      const data = res.data && typeof res.data === 'object' ? res.data : null;
      if (data) showAdaptiveLight(data, false);
    } catch (_) {}
  })();
  return adaptiveLightProbe;
}

/* A fresh reading of the light adaptive brightness follows, or a new
   source, from the WebSocket: the curve's marker and the Light sensor
   entity row repaint off the event. */
export function showAdaptiveLight(msg, notify = true) {
  state.adaptiveSource = msg.source;
  state.adaptiveLux = typeof msg.lux === 'number' ? msg.lux : null;
  state.adaptiveLive = msg.live === true;
  if (notify) document.dispatchEvent(new CustomEvent('ks-adaptivelight'));
}

/* What the Home Assistant motion entity reads (issue #973), asked about
   once per page load and again when the entity changes; the
   externalmotion messages keep it current in between. */
let externalMotionProbe;
export function probeExternalMotion(reprobe = false) {
  if (reprobe) externalMotionProbe = undefined;
  externalMotionProbe ??= (async () => {
    try {
      const res = await (await api('/api/commands/getExternalMotion',
        { method: 'POST', body: '{}' })).json();
      const data = res.data && typeof res.data === 'object' ? res.data : null;
      if (data) showExternalMotion(data);
    } catch (_) {}
  })();
  return externalMotionProbe;
}

/* A new state from the WebSocket: the Motion sensor entity row repaints
   off the event. */
export function showExternalMotion(msg) {
  state.externalMotion = typeof msg.detected === 'boolean' ? msg.detected : null;
  document.dispatchEvent(new CustomEvent('ks-externalmotion'));
}

/* The motion entity's state for its row, worded like the Occupancy rows'. */
export function externalMotionReading() {
  if (state.externalMotion === true) return screensaverText('Detected');
  if (state.externalMotion === false) return t('screensaverDetectionClear');
  return screenAudioText('No reading yet');
}

/* The Home Assistant entity's reading for its row (issue #911), worded
   like the Ambient light row's. */
export function entityLightReading() {
  return formatLux(state.adaptiveSource === 'entity' ? state.adaptiveLux : null,
    state.adaptiveLive);
}

/* A fresh sensor reading from the WebSocket: the live row, if it is up. */
export function showLightLevel(lux) {
  state.lightLux = lux;
  state.lightLive = true;
  const el = document.querySelector('.ambient-light-value');
  if (el) el.textContent = formatLux(lux);
}

/* Until the sensor has spoken this session, the reading is the last
   session's (some drivers emit nothing at registration), and says so. */
function formatLux(lux, live = state.lightLive) {
  if (typeof lux !== 'number') return screenAudioText('No reading yet');
  return t(live ? 'screenAudioLux' : 'screenAudioLuxLast',
    {lux: String(Number.isInteger(lux) ? lux : lux.toFixed(1))});
}

const ADAPTIVE_NOTE =
  'Level in a bright room. Adaptive brightness dims it from there.';
const ADAPTIVE_OWNS_NOTE = 'Adaptive brightness is on.';
const NO_LIGHT_SENSOR_NOTE = 'No ambient light sensor on this device.';
const AMBIENT_LIGHT_NOTE = 'What the ambient light sensor reads right now.';

const PROXIMITY_SENSOR_NOTE =
  'What the device reports as the proximity sensor. A sensor made for calls '
  + 'named "palm" or "touch" will not work.';

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
  div.textContent = screensaverText('WARNING: Dim keeps the dashboard visible, so the '
    + '"Pause dashboard during screensaver" optimization will not be applied '
    + 'and the dashboard keeps using CPU, GPU and battery.');
  anchor.insertAdjacentElement('afterend', div);
}

/* File Manager (remote admin only): browse device folders, download,
   upload and delete files. Two roots from the app: shared storage (gated
   on the "All files access" grant, requested on the device) and the app's
   own folder, which always works. */
export const filesState = { root: null, crumbs: [] };
