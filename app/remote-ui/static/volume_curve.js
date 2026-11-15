/* The adaptive volume curve editor (issue #1450), mirroring the device's
   VolumeCurveEditor and built like the brightness curve's: a chart of
   volume over the room's noise, four points, the room's level marked on
   it, and a chip per point that opens a dialog for exact values. A point
   holds one noise level and a volume for each of the volumes that follow
   the room, so the chart draws a line per volume through the same four
   noise levels. Dragging a ring moves its point along the noise scale and
   that one volume up or down. It stands in for the curve setting's row. */
import { api, state } from './core.js';
import { cameraEditor, cameraField } from './cameras.js';
import { screenAudioText, t } from './localization.js';
import { hintRow } from './widgets.js';
import {
  VOLUME_CHANNELS,
  VOLUME_CURVE_KEY,
  clampVolumePoint,
  encodeVolumeCurve,
  parseVolumeCurve,
  volumeCurveDomain,
  volumeLevelAt,
  volumePointBounds,
  withVolumePoint,
} from './adaptive_volume_curve.js';

const CURVE_HINT = 'Drag a point, or tap it to type exact values. The percentages '
  + 'apply to the Assistant, Media and Intercom volume sliders under Screen & Audio: '
  + "100% plays at the slider's level and 50% plays like the slider set to half.";

const SVG = 'http://www.w3.org/2000/svg';
const PAD = { left: 40, right: 10, top: 14, bottom: 26 };

/* What each volume is called, as its switch on the page calls it, its
   field in the point dialog and the setting that makes it follow the
   room. */
const CHANNEL = {
  assistant: { name: 'Assistant', field: 'Assistant (%)', key: 'audio.adaptive_volume_assistant' },
  media: { name: 'Media', field: 'Media (%)', key: 'audio.adaptive_volume_media' },
  intercom: { name: 'Intercom', field: 'Intercom (%)', key: 'audio.adaptive_volume_intercom' },
};

/* The editors on the page, for the room's level and for a volume that
   starts or stops following the room. */
const editors = new Set();
function refreshEditors() {
  for (const editor of editors) {
    if (editor.row.isConnected) editor.refresh();
    else editors.delete(editor);
  }
}
document.addEventListener('ks-adaptivevolume', refreshEditors);
document.addEventListener('ks-settings', refreshEditors);

let gradients = 0;

const setting = (key) => (state.settings || []).find((s) => s.key === key)?.value;

/* The volumes that follow the room: only they have a line, a ring on each
   point and a field in the dialog. */
function shownChannels() {
  return VOLUME_CHANNELS.filter((channel) => setting(CHANNEL[channel].key) === true
    && (channel !== 'intercom' || setting('intercom.enabled') === true));
}

const ease = (k) => 1 - (1 - k) ** 3;
const noiseText = (noise) => t('screenAudioDbfs', { level: String(Math.round(noise)) });
const roomNoise = () => (typeof state.adaptiveVolume?.noise === 'number'
  ? state.adaptiveVolume.noise : null);

/* Builds the editor into `row` (the curve setting's row). `showError` and
   `clearError` are the row's own error line. */
export function volumeCurveRow(row, { showError, clearError }) {
  row.classList.add('curve-row', 'volume-curve');
  row.textContent = '';
  const key = document.createElement('div');
  key.className = 'curve-key';
  const chart = document.createElement('div');
  chart.className = 'curve-chart';
  const svg = document.createElementNS(SVG, 'svg');
  svg.setAttribute('aria-hidden', 'true');
  chart.appendChild(svg);
  const chips = document.createElement('div');
  chips.className = 'curve-points';
  row.append(key, chart, chips, hintRow(screenAudioText(CURVE_HINT)));
  const gradientId = `volume-curve-fill-${++gradients}`;

  // The curve as the setting holds it, the one on screen easing toward it
  // when something else writes it, and a drag in progress.
  let target = parseVolumeCurve(setting(VOLUME_CURVE_KEY));
  let from = target;
  let morphStart = 0;
  let noise = roomNoise();
  let noiseFrom = noise;
  let noiseStart = 0;
  let drag = null;
  let frame = 0;

  const shown = () => {
    if (drag) return drag.points;
    const k = morphStart ? Math.min(1, (performance.now() - morphStart) / 320) : 1;
    if (k >= 1) return target;
    const e = ease(k);
    const mix = (a, b) => a + (b - a) * e;
    return target.map((p, i) => ({
      noise: mix(from[i].noise, p.noise),
      assistant: mix(from[i].assistant, p.assistant),
      media: mix(from[i].media, p.media),
      intercom: mix(from[i].intercom, p.intercom),
    }));
  };
  const shownNoise = () => {
    if (noise == null || noiseFrom == null || !noiseStart) return noise;
    const k = Math.min(1, (performance.now() - noiseStart) / 420);
    return noiseFrom + (noise - noiseFrom) * ease(k);
  };
  const animating = () => (morphStart && performance.now() - morphStart < 320)
    || (noiseStart && performance.now() - noiseStart < 420);

  const schedule = () => {
    if (frame) return;
    frame = requestAnimationFrame(() => {
      frame = 0;
      paint();
      if (animating()) schedule();
    });
  };

  // Chart coordinates for the current size and range.
  const geometry = (domain) => {
    const width = Math.max(chart.clientWidth, 200);
    const height = chart.clientHeight || 250;
    const plot = {
      left: PAD.left, top: PAD.top,
      right: width - PAD.right, bottom: height - PAD.bottom,
    };
    const span = plot.right - plot.left;
    const x = (v) => plot.left + (Math.min(Math.max(v, domain.lo), domain.hi) - domain.lo)
      / (domain.hi - domain.lo) * span;
    const y = (v) => plot.bottom - Math.min(Math.max(v, 0), 1) * (plot.bottom - plot.top);
    const noiseAt = (px) => domain.lo + Math.min(Math.max((px - plot.left) / span, 0), 1)
      * (domain.hi - domain.lo);
    const levelAtY = (py) => Math.min(Math.max((plot.bottom - py) / (plot.bottom - plot.top), 0), 1);
    return { width, height, plot, domain, x, y, noiseAt, levelAtY };
  };
  const currentGeometry = () => geometry(drag ? drag.domain : volumeCurveDomain(target));

  const el = (name, attrs = {}, text) => {
    const node = document.createElementNS(SVG, name);
    for (const [k, v] of Object.entries(attrs)) node.setAttribute(k, v);
    if (text != null) node.textContent = text;
    return node;
  };

  // One chip per point: its noise level over its volumes.
  const chipEls = [0, 1, 2, 3].map((i) => {
    const chip = document.createElement('button');
    chip.type = 'button';
    chip.className = 'curve-point';
    const noiseEl = document.createElement('span');
    noiseEl.className = 'curve-lux';
    const levelEl = document.createElement('span');
    levelEl.className = 'curve-level';
    chip.append(noiseEl, levelEl);
    chip.addEventListener('click', () => editPoint(i));
    chips.appendChild(chip);
    return { chip, noiseEl, levelEl };
  });
  row.updateSetting = () => { retarget(); return true; };

  // Invisible handles over the rings take the pointer and the keyboard: a
  // drag starting on one never scrolls the page, and one starting anywhere
  // else on the chart still does. One per point and volume; those of a
  // volume that does not follow the room are hidden.
  const handles = [0, 1, 2, 3].map((i) => Object.fromEntries(VOLUME_CHANNELS.map((channel) => {
    const handle = document.createElement('button');
    handle.type = 'button';
    handle.className = 'curve-handle';
    handle.setAttribute('aria-label', `${t('screenAudioCurvePoint', { number: String(i + 1) })}, `
      + screenAudioText(CHANNEL[channel].name));
    handle.addEventListener('pointerdown', (e) => startDrag(e, i, channel));
    handle.addEventListener('keydown', (e) => nudge(e, i, channel));
    chart.appendChild(handle);
    return [channel, handle];
  })));

  let keyFor = '';
  function paintKey(channels) {
    const next = channels.join(',');
    if (next === keyFor) return;
    keyFor = next;
    key.textContent = '';
    key.style.display = channels.length ? '' : 'none';
    for (const channel of channels) {
      const item = document.createElement('span');
      const sample = document.createElementNS(SVG, 'svg');
      sample.setAttribute('viewBox', '0 0 26 10');
      sample.setAttribute('aria-hidden', 'true');
      sample.appendChild(el('line', { class: `curve-line ${channel}`, x1: 1.5, y1: 5, x2: 24.5, y2: 5 }));
      const name = document.createElement('span');
      name.textContent = screenAudioText(CHANNEL[channel].name);
      item.append(sample, name);
      key.appendChild(item);
    }
  }

  function paint() {
    const points = shown();
    const now = shownNoise();
    const channels = shownChannels();
    const g = currentGeometry();
    const { plot } = g;
    paintKey(channels);
    svg.setAttribute('viewBox', `0 0 ${g.width} ${g.height}`);
    svg.textContent = '';
    const defs = el('defs');
    const gradient = el('linearGradient', { id: gradientId, x1: 0, y1: 0, x2: 0, y2: 1 });
    gradient.append(
      el('stop', { offset: 0, style: 'stop-color:var(--primary);stop-opacity:.22' }),
      el('stop', { offset: 1, style: 'stop-color:var(--primary);stop-opacity:.02' }));
    defs.appendChild(gradient);
    svg.appendChild(defs);

    for (let q = 0; q <= 4; q++) {
      const y = g.y(q / 4);
      svg.appendChild(el('line', { class: 'curve-grid', x1: plot.left, x2: plot.right, y1: y, y2: y }));
      if (q % 2 === 0) {
        svg.appendChild(el('text', { class: 'curve-label', x: plot.left - 8, y, 'text-anchor': 'end',
          'dominant-baseline': 'central' }, `${q * 25}%`));
      }
    }
    // A line every 10 dB of noise, labeled under the axis.
    for (let tens = Math.ceil(g.domain.lo / 10); tens <= Math.floor(g.domain.hi / 10); tens++) {
      const x = g.x(tens * 10);
      svg.appendChild(el('line', { class: 'curve-grid', x1: x, x2: x, y1: plot.top, y2: plot.bottom }));
      svg.appendChild(el('text', { class: 'curve-label', x, y: plot.bottom + 6,
        'text-anchor': x - plot.left < 12 ? 'start' : plot.right - x < 12 ? 'end' : 'middle',
        'dominant-baseline': 'hanging' }, String(tens * 10)));
    }

    // A line per volume, flat before the first point and after the last.
    // The first one carries the fill.
    channels.forEach((channel, n) => {
      let d = `M${plot.left},${g.y(points[0][channel]).toFixed(1)}`;
      for (const p of points) d += `L${g.x(p.noise).toFixed(1)},${g.y(p[channel]).toFixed(1)}`;
      d += `L${plot.right},${g.y(points[points.length - 1][channel]).toFixed(1)}`;
      if (n === 0) {
        svg.appendChild(el('path', { d: `${d}L${plot.right},${plot.bottom}L${plot.left},${plot.bottom}Z`,
          fill: `url(#${gradientId})` }));
      }
      svg.appendChild(el('path', { class: `curve-line ${channel}`, d }));
    });

    // The room right now: a dashed line at its level, a dot where it meets
    // each volume's line and the level above.
    if (now != null) {
      const x = g.x(now);
      svg.appendChild(el('line', { class: 'curve-now', x1: x, x2: x, y1: plot.top, y2: plot.bottom }));
      for (const channel of channels) {
        const y = g.y(volumeLevelAt(points, channel, now));
        svg.appendChild(el('circle', { class: 'curve-now-halo', cx: x, cy: y, r: 9 }));
        svg.appendChild(el('circle', { class: 'curve-now-dot', cx: x, cy: y, r: 5 }));
      }
      const text = el('text', { class: 'curve-pill-text', y: plot.top + 6, 'dominant-baseline': 'central' },
        noiseText(now));
      const pill = el('rect', { class: 'curve-pill', y: plot.top - 4, height: 20, rx: 10 });
      svg.append(pill, text);
      const w = text.getComputedTextLength() + 14;
      const left = Math.min(Math.max(x - w / 2, plot.left), plot.right - w);
      pill.setAttribute('x', left);
      pill.setAttribute('width', w);
      text.setAttribute('x', left + 7);
    }

    points.forEach((p, i) => {
      const cx = g.x(p.noise);
      for (const channel of VOLUME_CHANNELS) {
        const handle = handles[i][channel];
        const visible = channels.includes(channel);
        handle.style.display = visible ? '' : 'none';
        if (!visible) continue;
        const cy = g.y(p[channel]);
        const active = drag?.index === i && drag.channel === channel;
        if (active) svg.appendChild(el('circle', { class: 'curve-halo', cx, cy, r: 20 }));
        svg.appendChild(el('circle', { class: active ? 'curve-dot active' : 'curve-dot', cx, cy,
          r: active ? 9 : 7 }));
        handle.style.left = `${cx}px`;
        handle.style.top = `${cy}px`;
      }
      chipEls[i].noiseEl.textContent = noiseText(p.noise);
      chipEls[i].levelEl.textContent = channels.map((c) => `${Math.round(p[c] * 100)}%`).join(' · ');
      chipEls[i].levelEl.style.display = channels.length ? '' : 'none';
      chipEls[i].chip.classList.toggle('active', drag?.index === i);
    });
  }

  function retarget({ animate = true } = {}) {
    if (drag) return;
    const next = parseVolumeCurve(setting(VOLUME_CURVE_KEY));
    from = animate ? shown() : next;
    target = next;
    morphStart = animate ? performance.now() : 0;
    schedule();
  }

  const editor = {
    row,
    refresh() {
      const next = roomNoise();
      if (next !== noise) {
        noiseFrom = next == null ? null : (shownNoise() ?? next);
        noise = next;
        noiseStart = next == null ? 0 : performance.now();
      }
      // A volume may have started or stopped following the room, and the
      // curve may have been written elsewhere.
      if (!drag && encodeVolumeCurve(target) !== encodeVolumeCurve(
        parseVolumeCurve(setting(VOLUME_CURVE_KEY)))) {
        retarget();
        return;
      }
      schedule();
    },
  };
  editors.add(editor);

  function startDrag(e, index, channel) {
    if (e.button !== 0) return;
    e.preventDefault();
    const handle = handles[index][channel];
    handle.setPointerCapture(e.pointerId);
    handle.focus({ preventScroll: true });
    const box = chart.getBoundingClientRect();
    const g = currentGeometry();
    const points = shown().map((p) => ({ ...p }));
    const local = { x: e.clientX - box.left, y: e.clientY - box.top };
    drag = {
      index, channel, points, domain: g.domain, pointer: e.pointerId, travel: 0,
      last: local,
      grab: { x: g.x(points[index].noise) - local.x, y: g.y(points[index][channel]) - local.y },
    };
    const move = (ev) => {
      if (!drag || ev.pointerId !== drag.pointer) return;
      const b = chart.getBoundingClientRect();
      const at = { x: ev.clientX - b.left, y: ev.clientY - b.top };
      drag.travel += Math.hypot(at.x - drag.last.x, at.y - drag.last.y);
      drag.last = at;
      if (drag.travel < 4) return;
      const gm = geometry(drag.domain);
      const moved = clampVolumePoint(drag.points, drag.index, {
        ...drag.points[drag.index],
        noise: Math.round(gm.noiseAt(at.x + drag.grab.x)),
        [drag.channel]: Math.round(gm.levelAtY(at.y + drag.grab.y) * 100) / 100,
      });
      drag.points = withVolumePoint(drag.points, drag.index, moved);
      schedule();
    };
    const end = async (ev) => {
      if (!drag || ev.pointerId !== drag.pointer) return;
      handle.removeEventListener('pointermove', move);
      handle.removeEventListener('pointerup', end);
      handle.removeEventListener('pointercancel', end);
      const done = drag;
      if (done.travel < 4) {
        drag = null;
        schedule();
        editPoint(done.index);
        return;
      }
      await commit(done.points);
      drag = null;
      retarget({ animate: false });
    };
    handle.addEventListener('pointermove', move);
    handle.addEventListener('pointerup', end);
    handle.addEventListener('pointercancel', end);
    schedule();
  }

  // Arrows move the focused ring: up and down by 1% of that volume, left
  // and right by 1 dB of noise. Enter opens the point's dialog.
  async function nudge(e, index, channel) {
    const step = {
      ArrowUp: [0, 0.01], ArrowDown: [0, -0.01], ArrowRight: [1, 0], ArrowLeft: [-1, 0],
    }[e.key];
    if (!step) return;
    e.preventDefault();
    const points = target.map((p) => ({ ...p }));
    const p = points[index];
    const moved = clampVolumePoint(points, index, {
      ...p,
      noise: p.noise + step[0],
      [channel]: Math.round((p[channel] + step[1]) * 100) / 100,
    });
    await commit(withVolumePoint(points, index, moved));
    retarget({ animate: false });
  }

  // The whole curve is one setting, so a point's values are written
  // together and the device checks them as one.
  async function commit(points) {
    const value = encodeVolumeCurve(points);
    try {
      const res = await api('/api/settings', { method: 'PATCH',
        body: JSON.stringify({ [VOLUME_CURVE_KEY]: value }) });
      const out = await res.json().catch(() => null);
      if (!res.ok || out?.ok !== true) {
        throw new Error(Object.values(out?.errors || {})[0] || out?.error
          || 'Could not save this setting. Try again.');
      }
    } catch (error) {
      showError(error?.message || 'Could not save this setting. Try again.');
      return false;
    }
    clearError();
    for (const s of state.settings || []) {
      if (s.key === VOLUME_CURVE_KEY) s.value = value;
    }
    return true;
  }

  function editPoint(index) {
    const points = target.map((p) => ({ ...p }));
    const p = points[index];
    const b = volumePointBounds(points, index);
    const channels = shownChannels();
    const body = document.createElement('div');
    const noiseField = cameraField(screenAudioText('Room noise (dBFS)'), String(Math.round(p.noise)));
    noiseField.input.inputMode = 'text';
    body.appendChild(noiseField.wrap);
    const levels = document.createElement('div');
    levels.className = 'curve-fields';
    const levelFields = channels.map((channel) => {
      const field = cameraField(screenAudioText(CHANNEL[channel].field),
        String(Math.round(p[channel] * 100)));
      field.input.inputMode = 'numeric';
      levels.appendChild(field.wrap);
      return [channel, field];
    });
    if (channels.length) body.appendChild(levels);
    requestAnimationFrame(() => noiseField.input.focus());
    cameraEditor({
      title: t('screenAudioCurvePoint', { number: String(index + 1) }),
      width: 420,
      body,
      save: async () => {
        const typed = noiseField.input.value.trim().replace(',', '.');
        const next = { ...p, noise: Number(typed) };
        if (!typed || !Number.isFinite(next.noise) || next.noise < b.noiseLo - 1e-9
            || next.noise > b.noiseHi + 1e-9) {
          return { ok: false, error: t('screenAudioVolumeCurveNoiseRange',
            { low: String(Math.round(b.noiseLo)), high: String(Math.round(b.noiseHi)) }) };
        }
        next.noise = Math.round(next.noise);
        for (const [channel, field] of levelFields) {
          const level = Number(field.input.value.trim());
          if (!field.input.value.trim() || !Number.isFinite(level)
              || level / 100 < b.levelLo[channel] - 1e-9 || level / 100 > b.levelHi[channel] + 1e-9) {
            field.input.focus();
            return { ok: false, error: `${screenAudioText(CHANNEL[channel].name)}: `
              + t('screenAudioVolumeCurveLevelRange', {
                low: String(Math.round(b.levelLo[channel] * 100)),
                high: String(Math.round(b.levelHi[channel] * 100)),
              }) };
          }
          next[channel] = Math.round(level) / 100;
        }
        const ok = await commit(withVolumePoint(points, index, next));
        retarget({ animate: false });
        return ok ? { ok: true } : { ok: false, error: row.querySelector('.row-error')?.textContent };
      },
    });
  }

  // The chart follows the card's width.
  new ResizeObserver(() => schedule()).observe(chart);
  schedule();
  return row;
}
