import { api, cmd, state } from './core.js';
import { readOnlyRow } from './device.js';
import { attachSlider } from './widgets.js';

// ── Microphone level meter ────────────────────────────────────────────
// Mirrors the device's segmented meter: 24 segments on a dB scale
// (-60..-6 dBFS), green up to the 0.05-RMS gain target, amber to about
// -15 dBFS, red above. Levels arrive as {type:'micLevel', rms} WS frames
// while the watchMicLevel command stays re-armed; the watch self-expires
// on the device, so the keepalive below only runs while the row is
// actually on screen.
export const MIC_METER_SEGMENTS = 24;
export let micMeterEl = null;
export let micMeterLabelEl = null;
export let micMeterLastFrame = 0;
export let micMeterLastArm = 0;

export function micLevelFraction(rms) {
  if (!rms || rms <= 0) return 0;
  const db = 20 * Math.log10(rms);
  return Math.min(1, Math.max(0, (db + 60) / 54));
}

export function micLevelRow() {
  const row = document.createElement('div'); row.className = 'row';
  // Lets the capture channel row insert itself above this one on a re-run.
  row.dataset.key = 'x:mic_level';
  const info = document.createElement('div'); info.className = 'info';
  info.innerHTML = `<div class="name"></div><div class="desc"></div>`;
  info.querySelector('.name').textContent = 'Microphone level';
  info.querySelector('.desc').textContent =
    'Speak from where you use the device; adjust the gain until normal ' +
    'speech tops out around the end of the green.';
  row.appendChild(info);
  const wrap = document.createElement('div');
  wrap.style.cssText =
    'display:flex; gap:10px; align-items:center; flex:none; align-self:center';
  const bar = document.createElement('div');
  bar.style.cssText = 'display:flex; gap:3px; width:180px; height:12px';
  for (let i = 0; i < MIC_METER_SEGMENTS; i++) {
    const seg = document.createElement('div');
    seg.style.cssText = 'flex:1; border-radius:2px; background:var(--border)';
    bar.appendChild(seg);
  }
  // Fixed-width readout so the bar does not jitter as digit counts change.
  const label = document.createElement('span');
  label.style.cssText =
    'width:92px; text-align:right; font-size:12px; color:var(--muted); ' +
    'font-variant-numeric:tabular-nums; white-space:nowrap';
  wrap.appendChild(bar);
  wrap.appendChild(label);
  micMeterEl = bar;
  micMeterLabelEl = label;
  row.appendChild(wrap);
  return row;
}

export function renderMicLevel(rms) {
  if (!micMeterEl || !micMeterEl.isConnected) return;
  micMeterLastFrame = Date.now();
  const lit = Math.round(micLevelFraction(rms) * MIC_METER_SEGMENTS);
  [...micMeterEl.children].forEach((seg, i) => {
    seg.style.background = i >= lit ? 'var(--border)'
      : i < 15 ? 'var(--ok)' : i < 20 ? 'var(--warn)' : 'var(--error)';
  });
  if (micMeterLabelEl) {
    micMeterLabelEl.textContent = rms > 0
      ? `${rms.toFixed(3)} (${Math.round(20 * Math.log10(rms))} dB)`
      : '';
  }
}

// Keepalive: re-arm the device-side watch while the meter is visible.
setInterval(() => {
  if (!micMeterEl || !micMeterEl.isConnected || !micMeterEl.offsetParent) return;
  if (Date.now() - micMeterLastArm < 6000) return;
  micMeterLastArm = Date.now();
  api('/api/commands/watchMicLevel', { method: 'POST', body: '{}' })
    .catch(() => {});
}, 1000);

// Telemetry stops when detection pauses (a voice turn) or the watch
// lapses; decay to dark instead of freezing on the last value.
setInterval(() => {
  if (micMeterEl && micMeterEl.isConnected && micMeterLastFrame &&
      Date.now() - micMeterLastFrame > 600) {
    renderMicLevel(0);
    micMeterLastFrame = 0;
  }
}, 300);

// A hand-built switch row for cards that re-render themselves in place:
// the shared settingRow's save calls loadSettings() whenever other rows
// gate on the switch, and on the Home Assistant tab that reads as a
// full-page refresh. onChange (absent for a disabled switch) receives the
// new value; the caller re-renders its own card.
export function toggleRow(name, desc, checked, onChange) {
  const row = readOnlyRow(name, desc, '');
  row.querySelector('span').remove();
  const lbl = document.createElement('label'); lbl.className = 'switch';
  const cb = document.createElement('input');
  cb.type = 'checkbox'; cb.checked = checked; cb.disabled = !onChange;
  const sl = document.createElement('span'); sl.className = 'slider';
  lbl.append(cb, sl); row.appendChild(lbl);
  if (onChange) cb.addEventListener('change', () => onChange(cb.checked));
  return row;
}

// The master volume fader on the Audio page, mirroring the device's row:
// hand-built because it is the device's live volume (getVolume/setVolume
// commands), not a setting. Media and assistant scale under it.
export async function prependMasterVolumeRow() {
  const card = document
    .querySelector('#tab-screenaudio [data-key="audio.media_volume"]')
    ?.closest('.card');
  if (!card || card.querySelector('[data-key="master-volume"]')) return;
  let percent = null;
  try {
    const r = await cmd('getVolume');
    if (r.ok && typeof r.data === 'number') percent = r.data;
  } catch (_) {}
  if (percent == null) return;
  const row = document.createElement('div'); row.className = 'row';
  row.dataset.key = 'master-volume';
  const info = document.createElement('div'); info.className = 'info';
  info.innerHTML = '<div class="name"></div><div class="desc"></div>';
  info.querySelector('.name').textContent = 'Master volume';
  info.querySelector('.desc').textContent =
    'The device volume. Media and assistant volume scale under it.';
  row.appendChild(info);
  attachSlider(row, { min: 0, max: 100, step: 5, value: Math.round(percent),
    label: (v) => `${v}%`,
    onChange: (v) => cmd('setVolume', { percent: v }) });
  card.prepend(row);
}

// The microphone / speaker pickers on the Screen & Audio page, mirroring the
// device's rows: hand-built because their options are live hardware from
// getAudioDevices, not declared constants. Values are the app's stable device
// selectors; empty means automatic. A configured device that is currently
// absent stays choosable under the name embedded in its selector. The mic row
// only while detection is on (with it off this app never opens the mic).
export async function appendAudioDeviceRows(card, wakeWordOn) {
  let data = null;
  try {
    const r = await cmd('getAudioDevices');
    if (r.ok) data = r.data;
  } catch (_) {}
  if (!data) return;
  const rows = [];
  if (wakeWordOn) {
    rows.push({
      key: 'audio.mic_device',
      title: 'Microphone',
      desc: 'The microphone wake word detection and voice turns capture from.',
      list: data.inputs || [],
      current: data.micSelected || '',
    });
  }
  rows.push({
    key: 'audio.speaker_device',
    title: 'Speaker',
    desc: 'Output for Voice Satellite sounds; media playback follows the system route. Echo cancellation only works with the microphone and speaker on the same device.',
    list: data.outputs || [],
    current: data.speakerSelected || '',
  });
  for (const spec of rows) {
    const row = readOnlyRow(spec.title, spec.desc, '');
    row.querySelector('span').remove();
    const sel = document.createElement('select');
    const opts = [{ selector: '', label: 'Automatic' }, ...spec.list];
    if (spec.current && !opts.some((o) => o.selector === spec.current)) {
      const name = spec.current.split('|')[2] || 'Selected device';
      opts.push({ selector: spec.current, label: `${name} (not connected)` });
    }
    for (const o of opts) {
      const opt = document.createElement('option');
      opt.value = o.selector;
      opt.textContent = o.label;
      opt.selected = o.selector === spec.current;
      sel.appendChild(opt);
    }
    sel.addEventListener('change', async () => {
      await api('/api/settings', { method: 'PATCH', body: JSON.stringify({ [spec.key]: sel.value }) });
      const cached = (state.settings || []).find((o) => o.key === spec.key);
      if (cached) cached.value = sel.value;
      // The capture channel row exists only under a multichannel mic, so it
      // follows the selection in place, like the device's row does.
      if (spec.key === 'audio.mic_device') await updateMicChannelRow();
    });
    row.appendChild(sel);
    card.appendChild(row);
  }
}

// The capture channel of a multichannel microphone, mirroring the device's
// hand-built row in the Microphone settings card: only while the selected
// microphone reports more than one channel, with options Downmix plus
// Channel 1..N to its count. The value is 'audio.mic_channel' (a number,
// 0 = the platform's every-channel downmix, the historical behavior); the
// title and wording come from the hidden definition so the two UIs cannot
// drift. Re-run after a microphone selection change.
export async function updateMicChannelRow() {
  const root = document.getElementById('tab-screenaudio');
  const micCard = root && [...root.querySelectorAll('.card')]
    .find((c) => c.querySelector('[data-key="audio.mic_source"]'));
  if (!micCard) return;
  const old = micCard.querySelector('[data-key="audio.mic_channel"]');
  const setting = (state.settings || []).find((o) => o.key === 'audio.mic_channel');
  const selected = (state.settings || [])
    .find((o) => o.key === 'audio.mic_device')?.value || '';
  let channels = 0;
  if (setting && selected) {
    try {
      const r = await cmd('getAudioDevices');
      if (r.ok) {
        const hit = (r.data.inputs || []).find((d) => d.selector === selected);
        channels = Number(hit?.channels) || 0;
      }
    } catch (_) {}
  }
  if (channels < 2) { old?.remove(); return; }
  const row = readOnlyRow(setting.title, setting.description, '');
  row.querySelector('span').remove();
  row.dataset.key = 'audio.mic_channel';
  const current = Number(setting.value) || 0;
  const opts = [[0, 'Downmix (default)']];
  for (let i = 1; i <= channels; i++) opts.push([i, `Channel ${i}`]);
  // A stored channel beyond what the mic reports stays visible instead of
  // masquerading as another option; capture falls back to the mono downmix
  // until it is repicked.
  if (current > channels) {
    opts.push([current, `Channel ${current} (not on this microphone)`]);
  }
  const sel = document.createElement('select');
  for (const [v, label] of opts) {
    const opt = document.createElement('option');
    opt.value = String(v);
    opt.textContent = label;
    opt.selected = v === current;
    sel.appendChild(opt);
  }
  sel.addEventListener('change', async () => {
    const value = Number(sel.value) || 0;
    await api('/api/settings', { method: 'PATCH', body: JSON.stringify({ 'audio.mic_channel': value }) });
    setting.value = value;
  });
  row.appendChild(sel);
  if (old) {
    old.replaceWith(row);
  } else {
    // The device's place for it: after the gain, before the level meter.
    const level = micCard.querySelector('[data-key="x:mic_level"]');
    if (level) level.before(row);
    else micCard.appendChild(row);
  }
}
