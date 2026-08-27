import { cmd } from './core.js';

/* ---- Dashboard ---- */
// The one modal scaffold: backdrop, card, fixed title, a body that scrolls
// its overflow, and a fixed footer for the actions. onDismiss (optional)
// Keeps every .edge-fade container's two mask lengths honest: an edge that
// still hides content gets its fade, one scrolled to the end goes crisp.
// One capturing scroll listener covers containers created at any time; the
// mutation observer catches content appearing or disappearing without a
// scroll (a modal opening, rows re-rendering), batched to one pass per
// frame since it reads layout.
export function updateEdgeFade(el) {
  if (el.classList.contains('edge-fade-x')) {
    const span = el.scrollWidth - el.clientWidth;
    setEdgeFadeVar(el, '--fade-left', Math.max(0, Math.min(28, el.scrollLeft)));
    setEdgeFadeVar(el, '--fade-right',
      Math.max(0, Math.min(28, span - el.scrollLeft)));
    return;
  }
  const max = el.scrollHeight - el.clientHeight;
  // Proportional through the last 28px of travel, saturated at 28 the
  // rest of the way: mid-list scrolling writes the same values, which
  // the guard below turns into no style work at all.
  const top = Math.max(0, Math.min(28, el.scrollTop));
  const bottom = Math.max(0, Math.min(28, max - el.scrollTop));
  setEdgeFadeVar(el, '--fade-top', top);
  setEdgeFadeVar(el, '--fade-bottom', bottom);
}
export function setEdgeFadeVar(el, name, px) {
  const value = px > 0 ? px.toFixed(1) + 'px' : '0px';
  if (el.style.getPropertyValue(name) !== value) {
    el.style.setProperty(name, value);
  }
}
export let edgeFadeQueued = false;
export function queueEdgeFades() {
  if (edgeFadeQueued) return;
  edgeFadeQueued = true;
  requestAnimationFrame(() => {
    edgeFadeQueued = false;
    document.querySelectorAll('.edge-fade, .edge-fade-x').forEach(updateEdgeFade);
  });
}
document.addEventListener('scroll', (e) => {
  if (e.target instanceof Element && (e.target.classList.contains('edge-fade')
    || e.target.classList.contains('edge-fade-x'))) {
    updateEdgeFade(e.target);
  }
}, true);
// Class changes too (but not style: the fade writes styles itself, and
// observing them would re-trigger the observer forever): visibility here
// is toggled by classes, like the sidebar swapping its nav for search
// results, and a container measured while hidden reports no overflow.
new MutationObserver(queueEdgeFades).observe(document.body, {
  childList: true, subtree: true,
  attributes: true, attributeFilter: ['class'],
});
window.addEventListener('resize', queueEdgeFades);
queueEdgeFades();

// runs on a backdrop tap; pass it for pickers, omit it for alerts that
// must be answered with a button.
export function modalShell({ title, width, onDismiss }) {
  const back = document.createElement('div');
  back.className = 'modal-back';
  const card = document.createElement('div');
  card.className = 'card modal-card';
  if (width) card.style.maxWidth = width + 'px';
  const head = document.createElement('h3');
  head.className = 'modal-title';
  head.textContent = title;
  const body = document.createElement('div');
  body.className = 'modal-body edge-fade';
  const foot = document.createElement('div');
  foot.className = 'modal-foot';
  card.append(head, body, foot);
  back.appendChild(card);
  document.body.appendChild(back);
  if (onDismiss) {
    back.addEventListener('click', (e) => { if (e.target === back) onDismiss(); });
  }
  return { back, card, head, body, foot, close: () => back.remove() };
}

// Styled stand-in for alert()/confirm(), on the modal scaffold. Resolves to
// the label of the pressed button; no backdrop dismiss, an alert is answered.
// For the result of a command the user just issued, showToast is the first
// choice; this box is for answers that need a button.
export function messageBox({ title, message, buttons = ['OK'] }) {
  return new Promise((resolve) => {
    const { back, body, foot } = modalShell({ title });
    const p = document.createElement('p');
    p.textContent = message;
    p.style.cssText = 'margin:0; color:var(--muted); font-size:15px; line-height:1.5; white-space:pre-line;';
    body.appendChild(p);
    buttons.forEach((label, i) => {
      const btn = document.createElement('button');
      btn.textContent = label;
      btn.className = i === buttons.length - 1 ? 'btn-primary' : 'btn-text';
      btn.addEventListener('click', () => { back.remove(); resolve(label); });
      foot.appendChild(btn);
    });
  });
}

// Bound to every tile, including the quick-control ones whose command
// changes with the device's state (the camera tile drops its command
// altogether while its own picker owns the click), so the command is read
// at click time, never captured here.
document.querySelectorAll('.action.tile, .action[data-cmd]').forEach((b) =>
  b.addEventListener('click', async () => {
    if (!b.dataset.cmd) return;
    // Surface refusals, with a retry loop: the common case is "Screen off"
    // pending its one-tap device-admin grant on the tablet — approve there,
    // press Retry here.
    const label = b.textContent.trim();
    let res = await cmd(b.dataset.cmd).catch(() => null);
    while (res && res.ok === false && res.error) {
      const choice = await messageBox({
        title: label,
        message: res.error,
        buttons: ['Cancel', 'Retry'],
      });
      if (choice !== 'Retry') return;
      res = await cmd(b.dataset.cmd).catch(() => null);
    }
    // The device shows the result; here a toast says the command landed.
    if (res && res.ok !== false) showToast({ title: label, kind: 'success' });
    else if (!res) showToast({ title: label, message: 'The device did not answer.', kind: 'error' });
  }));

// A hint row inside a card, under the row it explains: the device's HintRow
// (and WarnRow with `warn`). One sentence; the caveat the description could
// not hold.
const HINT_ICONS = {
  info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v5"/><path d="M12 7.5h.01"/>',
  warn: '<path d="M12 4 2.5 20h19z"/><path d="M12 10v4m0 3h.01"/>',
};
export function hintRow(text, { warn = false, className = '' } = {}) {
  const div = document.createElement('div');
  div.className = 'hint-row' + (warn ? ' warn' : '') + (className ? ' ' + className : '');
  div.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"'
    + ' stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
    + (warn ? HINT_ICONS.warn : HINT_ICONS.info) + '</svg><span></span>';
  div.querySelector('span').textContent = text;
  return div;
}

// A banner above the rows it affects: the device's Banner. `error` for a
// failure that blocks the page, otherwise the warning tint for a state
// that makes a section inert.
export function banner(text, { error = false, className = '' } = {}) {
  const div = document.createElement('div');
  div.className = 'banner ' + (error ? 'error' : 'warn') + (className ? ' ' + className : '');
  div.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"'
    + ' stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
    + (error ? TOAST_ICONS.error : HINT_ICONS.warn) + '</svg><span></span>';
  div.querySelector('span').textContent = text;
  return div;
}
/* Camera grant notice: mirror of the device's row directly under "Enable
   camera", shown only while that switch is on and the camera permission is
   missing. Toggling the switch re-renders the tab (its dependants force a
   layout reload), so visibility follows the setting on its own. */

/* ---- Toast ---- */
// The device's toast (lib/ui/toast.dart), on the remote: a compact card
// floated bottom center over whatever is on screen, a disc in the kind's
// container tint, one at a time, 4 seconds or sticky until dismissed.
// Command results and confirmations land here; the message box stays for
// answers that need a button. A toast with no action ignores touches so
// the page beneath keeps taking them.
const TOAST_ICONS = {
  info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v5"/><path d="M12 7.5h.01"/>',
  success: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
  warning: '<path d="M12 4 2.5 20h19z"/><path d="M12 10v4m0 3h.01"/>',
  error: '<circle cx="12" cy="12" r="9"/><path d="M12 8v4m0 4h.01"/>',
};
let toastEl = null;
let toastTimer = 0;
export function dismissToast() {
  clearTimeout(toastTimer);
  toastEl?.remove();
  toastEl = null;
}
export function showToast({ title, message = '', kind = 'info',
  actionLabel = '', onAction = null, duration = 4000, sticky = false }) {
  dismissToast();
  const el = document.createElement('div');
  el.className = `toast toast-${kind}`;
  el.setAttribute('role', 'status');
  const disc = document.createElement('span');
  disc.className = 'toast-disc';
  disc.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"'
    + ' stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
    + (TOAST_ICONS[kind] || TOAST_ICONS.info) + '</svg>';
  const text = document.createElement('div');
  text.className = 'toast-text';
  const t = document.createElement('div');
  t.className = 'toast-title';
  t.textContent = title;
  text.appendChild(t);
  if (message) {
    const m = document.createElement('div');
    m.className = 'toast-msg';
    m.textContent = message;
    text.appendChild(m);
  }
  el.append(disc, text);
  if (actionLabel) {
    const btn = document.createElement('button');
    btn.className = 'btn-text toast-action';
    btn.textContent = actionLabel;
    btn.addEventListener('click', () => { dismissToast(); onAction?.(); });
    el.appendChild(btn);
  } else {
    el.classList.add('inert');
  }
  document.body.appendChild(el);
  toastEl = el;
  if (!sticky) toastTimer = setTimeout(dismissToast, duration);
  return el;
}

/* ---- Sliders ---- */
// The device's slider: a 4 track with the active run in primary fill and
// a 20 thumb. The fill is a gradient sized by --pct, painted from the
// value here: on every input event, and on the batched mutation pass for
// ranges that arrive with a value already set.
export function paintRange(inp) {
  const min = Number(inp.min) || 0;
  const max = inp.max === '' ? 100 : Number(inp.max);
  const span = max - min;
  const pct = span > 0 ? ((Number(inp.value) - min) / span) * 100 : 0;
  const value = `${Math.max(0, Math.min(100, pct)).toFixed(2)}%`;
  if (inp.style.getPropertyValue('--pct') !== value) {
    inp.style.setProperty('--pct', value);
  }
}
document.addEventListener('input', (e) => {
  if (e.target instanceof HTMLInputElement && e.target.type === 'range') {
    paintRange(e.target);
  }
}, true);
new MutationObserver(() => requestAnimationFrame(() =>
  document.querySelectorAll('input[type=range]').forEach(paintRange)))
  .observe(document.body, { childList: true, subtree: true });

// A slider row, the way the device stacks it: the name and description on
// the first line with the value at the end in the row title's weight, the
// slider running the full row width beneath. Attaches to a row that
// already carries its .info. The label updates live while dragging; the
// value saves once, on release (onChange).
export function attachSlider(row, { min, max, step = 'any', value,
  label = (v) => String(v), onChange = null }) {
  row.classList.add('slider-row');
  const val = document.createElement('span');
  val.className = 'slider-value';
  const inp = document.createElement('input');
  inp.type = 'range';
  inp.className = 'range';
  inp.min = String(min);
  inp.max = String(max);
  inp.step = String(step);
  inp.value = String(value);
  const paint = () => {
    val.textContent = label(Number(inp.value));
    paintRange(inp);
  };
  paint();
  inp.addEventListener('input', paint);
  if (onChange) inp.addEventListener('change', () => onChange(Number(inp.value)));
  row.append(val, inp);
  return { input: inp, value: val, set: (v) => { inp.value = String(v); paint(); } };
}

/* ---- Time ---- */
const CLOCK_ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"'
  + ' stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
  + '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.5 2"/></svg>';
const CHEVRONS = {
  up: '<path d="m6 15 6-6 6 6"/>',
  down: '<path d="m6 9 6 6 6-6"/>',
};
function chevronButton(dir, label, onClick) {
  const btn = document.createElement('button');
  btn.type = 'button';
  btn.className = 'icon-btn';
  btn.title = label;
  btn.setAttribute('aria-label', label);
  btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"'
    + ' stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
    + CHEVRONS[dir] + '</svg>';
  btn.addEventListener('click', onClick);
  return btn;
}
const pad2 = (n) => String(n).padStart(2, '0');

// A time of day at rest: the control box showing the value with a clock
// glyph, tap opens the picker. Empty reads Not set. `full` makes it the
// labeled field of an editor.
export function timeBox({ title, value, onPick, full = false }) {
  const btn = document.createElement('button');
  btn.type = 'button';
  btn.className = 'time-box';
  if (full) btn.classList.add('full');
  const text = document.createElement('span');
  btn.appendChild(text);
  btn.insertAdjacentHTML('beforeend', CLOCK_ICON);
  let current = value || '';
  const set = (v) => {
    current = v || '';
    text.textContent = current || 'Not set';
    btn.classList.toggle('empty', !current);
  };
  set(current);
  btn.addEventListener('click', async () => {
    const picked = await pickTime({ title, value: current });
    if (picked == null) return;
    set(picked);
    onPick(picked);
  });
  return { el: btn, set, get value() { return current; } };
}

// The one time picker, on both surfaces (the device's showKsTimePicker):
// two boxes, hour and minute, 24 hour. Tap a box to type; the chevrons
// step it (hours by 1, minutes by 5) so a tablet with no keyboard can set
// a time with taps. An entry out of range paints the box error and
// disables Set. Resolves to "HH:mm", or null when cancelled.
export function pickTime({ title, value }) {
  return new Promise((resolve) => {
    const [h0, m0] = String(value || '').split(':').map((n) => parseInt(n, 10));
    const { back, body, foot } = modalShell({
      title, width: 360, onDismiss: () => { back.remove(); resolve(null); },
    });
    const wrap = document.createElement('div');
    wrap.className = 'time-pick';
    const column = (label, initial, max, delta) => {
      const col = document.createElement('div');
      col.className = 'time-col';
      const inp = document.createElement('input');
      inp.type = 'text';
      inp.inputMode = 'numeric';
      inp.maxLength = 2;
      inp.className = 'time-digits';
      inp.value = pad2(initial);
      const read = () => {
        const v = /^\d{1,2}$/.test(inp.value.trim()) ? Number(inp.value) : NaN;
        return v >= 0 && v <= max ? v : null;
      };
      const check = () => {
        inp.classList.toggle('error', read() == null);
        setBtn.disabled = !(hour.read() != null && minute.read() != null);
      };
      const step = (d) => {
        const current = read() ?? 0;
        const base = Math.abs(d) === 5 ? Math.floor(current / 5) * 5 : current;
        inp.value = pad2((((base + d) % (max + 1)) + max + 1) % (max + 1));
        check();
      };
      inp.addEventListener('input', check);
      inp.addEventListener('focus', () => inp.select());
      const lab = document.createElement('div');
      lab.className = 'time-label';
      lab.textContent = label;
      col.append(chevronButton('up', 'Up', () => step(delta)), inp,
        chevronButton('down', 'Down', () => step(-delta)), lab);
      return { col, inp, read, check };
    };
    const colon = document.createElement('div');
    colon.className = 'time-colon';
    colon.textContent = ':';
    const cancel = document.createElement('button');
    cancel.className = 'btn-text';
    cancel.textContent = 'Cancel';
    cancel.addEventListener('click', () => { back.remove(); resolve(null); });
    const setBtn = document.createElement('button');
    setBtn.className = 'btn-primary';
    setBtn.textContent = 'Set';
    const hour = column('Hour', Number.isInteger(h0) ? Math.min(23, Math.max(0, h0)) : 0, 23, 1);
    const minute = column('Minute', Number.isInteger(m0) ? Math.min(59, Math.max(0, m0)) : 0, 59, 5);
    setBtn.addEventListener('click', () => {
      const h = hour.read();
      const m = minute.read();
      if (h == null || m == null) return;
      back.remove();
      resolve(`${pad2(h)}:${pad2(m)}`);
    });
    wrap.append(hour.col, colon, minute.col);
    body.appendChild(wrap);
    foot.append(cancel, setBtn);
    hour.check();
    hour.inp.focus();
  });
}

/* ---- Color ---- */
// The clock and widget tints, as the device stores them: "r,g,b".
const COLOR_PRESETS = [['White', '#FAFAFA'], ['Warm', '#FFE0B2'],
  ['Amber', '#FFB300'], ['Red', '#EF5350'], ['Green', '#66BB6A'],
  ['Blue', '#42A5F5'], ['Cyan', '#26C6DA'], ['Dim', '#616161']];
export function parseRgb(rgb) {
  const parts = String(rgb || '').split(',').map((n) => parseInt(n, 10));
  return parts.length === 3 && parts.every((n) => Number.isInteger(n))
    ? parts.map((n) => Math.min(255, Math.max(0, n))) : [250, 250, 250];
}
const hexToRgb = (hex) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
const cssRgb = ([r, g, b]) => `rgb(${r}, ${g}, ${b})`;
// Relative luminance, the same reading as Flutter's computeLuminance.
function luminance([r, g, b]) {
  const lin = (c) => { c /= 255; return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; };
  return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
}

// The row's color control: a 34 circle swatch with an outline ring. The
// swatch is the value; tap opens the picker.
export function swatch(rgb, title, onPick) {
  const btn = document.createElement('button');
  btn.type = 'button';
  btn.className = 'swatch';
  btn.title = title;
  btn.setAttribute('aria-label', title);
  let current = parseRgb(rgb).join(',');
  const paint = () => { btn.style.background = cssRgb(parseRgb(current)); };
  paint();
  btn.addEventListener('click', async () => {
    const picked = await pickColor({ title, rgb: current });
    if (picked == null) return;
    current = picked;
    paint();
    onPick(picked);
  });
  Object.defineProperty(btn, 'rgb', { get: () => current });
  return btn;
}

// The color picker, the device's dialog drawn here: a live preview with
// the RGB values on it, three channel sliders tinted R, G and B, then the
// 8 presets as 34 swatches. Resolves to "r,g,b", or null when cancelled.
export function pickColor({ title, rgb }) {
  return new Promise((resolve) => {
    const color = parseRgb(rgb);
    const { back, body, foot } = modalShell({
      title, width: 360, onDismiss: () => { back.remove(); resolve(null); },
    });
    const preview = document.createElement('div');
    preview.className = 'color-preview';
    const channels = document.createElement('div');
    channels.className = 'color-channels';
    const paint = () => {
      preview.style.background = cssRgb(color);
      preview.style.color = luminance(color) > 0.5 ? '#000000' : '#ffffff';
      preview.textContent = color.join(', ');
      inputs.forEach((inp, i) => {
        if (Number(inp.value) !== color[i]) inp.value = String(color[i]);
        paintRange(inp);
        vals[i].textContent = String(color[i]);
      });
    };
    const inputs = [];
    const vals = [];
    [['R', '#E53935'], ['G', '#43A047'], ['B', '#1E88E5']].forEach(([label, tint], i) => {
      const line = document.createElement('div');
      line.className = 'color-channel';
      const name = document.createElement('span');
      name.textContent = label;
      name.style.color = tint;
      const inp = document.createElement('input');
      inp.type = 'range';
      inp.className = 'range';
      inp.min = '0';
      inp.max = '255';
      inp.step = '1';
      inp.style.setProperty('--range-color', tint);
      inp.addEventListener('input', () => { color[i] = Number(inp.value); paint(); });
      const val = document.createElement('span');
      val.className = 'color-val';
      inputs.push(inp);
      vals.push(val);
      line.append(name, inp, val);
      channels.appendChild(line);
    });
    const presets = document.createElement('div');
    presets.className = 'color-presets';
    for (const [name, hex] of COLOR_PRESETS) {
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'swatch';
      b.title = name;
      b.setAttribute('aria-label', name);
      b.style.background = hex;
      b.addEventListener('click', () => {
        hexToRgb(hex).forEach((n, i) => { color[i] = n; });
        paint();
      });
      presets.appendChild(b);
    }
    body.append(preview, channels, presets);
    paint();
    const cancel = document.createElement('button');
    cancel.className = 'btn-text';
    cancel.textContent = 'Cancel';
    cancel.addEventListener('click', () => { back.remove(); resolve(null); });
    const save = document.createElement('button');
    save.className = 'btn-primary';
    save.textContent = 'Save';
    save.addEventListener('click', () => { back.remove(); resolve(color.join(',')); });
    foot.append(cancel, save);
  });
}

/* ---- Copyable value ---- */
// navigator.clipboard exists only on secure origins and this admin page is
// plain http, so the execCommand fallback is the path that actually runs
// day to day.
export async function copyText(text) {
  let ok = false;
  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text);
      ok = true;
    }
  } catch (_) {}
  if (!ok) {
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.cssText = 'position:fixed; opacity:0';
    document.body.appendChild(ta);
    ta.select();
    try { ok = document.execCommand('copy'); } catch (_) {}
    ta.remove();
  }
  return ok;
}
const COPY_ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"'
  + ' stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
  + '<rect x="9" y="9" width="11" height="11" rx="2"/>'
  + '<path d="M5 15V6a2 2 0 0 1 2-2h9"/></svg>';
const CHECK_ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"'
  + ' stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
  + '<path d="M5 12.5l4.5 4.5L19 7.5"/></svg>';

// A value the user takes elsewhere (the ESPHome encryption key): the
// control box, read only, the value in mono, with a 36 copy disc inside
// its end. Tapping anywhere on the box copies; the disc turns to a check
// for two seconds and a toast says Copied. Never a bare selectable
// string: a double click stops at the + / = a base64 key is full of, and
// a partial key pasted into Home Assistant fails with a generic error.
export function copyBox(value, { placeholder = 'Not set' } = {}) {
  const box = document.createElement('button');
  box.type = 'button';
  box.className = 'copy-box';
  box.title = 'Copy';
  const text = document.createElement('span');
  text.className = 'copy-value';
  const disc = document.createElement('span');
  disc.className = 'icon-btn copy-disc';
  disc.innerHTML = COPY_ICON;
  box.append(text, disc);
  let current = '';
  let reset = 0;
  const set = (v) => {
    current = v || '';
    text.textContent = current || placeholder;
    box.classList.toggle('empty', !current);
    box.disabled = !current;
  };
  set(value);
  box.addEventListener('click', async () => {
    if (!current) return;
    const ok = await copyText(current);
    disc.innerHTML = ok ? CHECK_ICON : COPY_ICON;
    disc.classList.toggle('done', ok);
    showToast({
      title: ok ? 'Copied' : 'Could not copy',
      message: ok ? '' : 'Select the key and copy it by hand.',
      kind: ok ? 'success' : 'error',
      duration: 2000,
    });
    clearTimeout(reset);
    reset = setTimeout(() => {
      disc.innerHTML = COPY_ICON;
      disc.classList.remove('done');
    }, 2000);
  });
  return { el: box, set };
}
