import { api, cmd, state } from './core.js';
import { settingRow } from './rows.js';
import { radioRow } from './views.js';
import { messageBox, modalShell } from './widgets.js';

export function cameraField(label, value = '', type = 'text') {
  const wrap = document.createElement('label');
  wrap.className = 'form-field';
  const title = document.createElement('span');
  title.className = 'desc';
  title.textContent = label;
  const input = document.createElement('input');
  input.type = type;
  input.value = value;
  input.className = 'field';
  input.style.maxWidth = 'none';
  wrap.append(title, input);
  return { wrap, input };
}

export const CAMERA_ICONS = {
  dns: '<rect x="3" y="4" width="18" height="6" rx="2"/>'
    + '<rect x="3" y="14" width="18" height="6" rx="2"/>'
    + '<path d="M7 7h.01M7 17h.01M11 7h7M11 17h7"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.5 2"/>',
  weather: '<path d="M17.5 19H7a4 4 0 01-.7-7.94 5.5 5.5 0 0110.61-1.53'
    + 'A4.25 4.25 0 0117.5 19z"/>',
  battery: '<rect x="2" y="7" width="17" height="10" rx="2.5"/>'
    + '<path d="M21.5 10.5v3"/><path d="M5 10v4"/><path d="M8.5 10v4"/>',
  folder: '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1'
    + ' -2 2H5a2 2 0 0 1-2-2z"/>',
  home: '<path d="M3 11.5 12 4l9 7.5"/><path d="M5.5 10.5V20h13v-9.5"/>',
  download: '<path d="M12 3v12m0 0 5-5m-5 5-5-5M5 21h14"/>',
  delete: '<path d="M4 7h16M9 7V4h6v3m-8 0 1 14h8l1-14M10 11v6m4-6v6"/>',
  add: '<path d="M12 5v14M5 12h14"/>',
  video: '<rect x="3" y="6" width="14" height="12" rx="2"/>'
    + '<path d="m17 10 4-2v8l-4-2z"/>',
  videoOff: '<path d="M3 3l18 18"/>'
    + '<path d="M7 6H5a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-1"/>'
    + '<path d="m17 10 4-2v8l-2-1"/>',
  linkOff: '<path d="M10 13a4 4 0 0 0 5.7.3l2-2a4 4 0 0 0-5.7-5.6l-1.1 1.1"/>'
    + '<path d="M14 11a4 4 0 0 0-5.7-.3l-2 2a4 4 0 0 0 5.7 5.6l1.1-1.1M3 3l18 18"/>',
  grid: '<rect x="3" y="3" width="7" height="7" rx="1"/>'
    + '<rect x="14" y="3" width="7" height="7" rx="1"/>'
    + '<rect x="3" y="14" width="7" height="7" rx="1"/>'
    + '<rect x="14" y="14" width="7" height="7" rx="1"/>',
  play: '<path d="m8 5 11 7-11 7z" fill="currentColor" stroke="none"/>',
  stop: '<rect x="6" y="6" width="12" height="12" rx="1.5"'
    + ' fill="currentColor" stroke="none"/>',
  star: '<path d="m12 4 2.4 4.9 5.4.8-3.9 3.8.9 5.4-4.8-2.5-4.8 2.5'
    + '.9-5.4L4.2 9.7l5.4-.8z"/>',
  drag: '<path d="M9 6h.01M9 12h.01M9 18h.01M15 6h.01M15 12h.01M15 18h.01"/>',
  gear: '<circle cx="12" cy="12" r="3"/>'
    + '<path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83'
    + 'l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1'
    + '-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06'
    + 'a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0'
    + '-1.51-1H3a2 2 0 1 1 0-4h.09a1.65 1.65 0 0 0 1.51-1 1.65 1.65 0 0 0'
    + '-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33'
    + 'h.01a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51'
    + ' 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06'
    + 'a1.65 1.65 0 0 0-.33 1.82v.01a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4'
    + 'h-.09a1.65 1.65 0 0 0-1.51 1z"/>',
  up: '<path d="M12 19V5m0 0-6 6m6-6 6 6"/>',
  down: '<path d="M12 5v14m0 0 6-6m-6 6-6-6"/>',
  pencil: '<path d="M4 20h4L19.5 8.5a2.1 2.1 0 0 0-3-3L5 17z"/>'
    + '<path d="m13.5 6.5 4 4"/>',
  gesture: '<path d="M4 9c1-2 2.6-3.6 3.7-3 1.3.7-1.3 3.4-2.1 5.3'
    + '-.9 2.2-.4 4.7 1.9 4.7 3.2 0 4.5-6.5 8-6.5 2.4 0 3 2 3 3.5 0 2.6'
    + '-1.7 5-4 5-1.4 0-2.3-1-2.3-2.1 0-1.5 1.5-2.9 3.6-2.9H21"/>',
  // The gesture action chooser's glyphs, mirroring the device's Material
  // icons (gesture_settings.dart _actionGroups).
  globe: '<circle cx="12" cy="12" r="9"/>'
    + '<path d="M3 12h18M12 3a13.5 13.5 0 0 1 0 18M12 3a13.5 13.5 0 0 0 0 18"/>',
  speaker: '<rect x="6" y="3" width="12" height="18" rx="2.5"/>'
    + '<circle cx="12" cy="14.5" r="3.5"/><circle cx="12" cy="7.5" r="1"/>',
  moon: '<path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M4.9 4.9l1.4 1.4'
    + 'm11.4 11.4 1.4 1.4M2 12h2m16 0h2M4.9 19.1l1.4-1.4m11.4-11.4 1.4-1.4"/>',
  // Two palms coming together under an impact burst: the clap trigger.
  clap: '<rect x="6.1" y="9.5" width="4.2" height="10.5" rx="2.1"'
    + ' transform="rotate(-16 8.2 14.75)"/>'
    + '<rect x="13.7" y="9.5" width="4.2" height="10.5" rx="2.1"'
    + ' transform="rotate(16 15.8 14.75)"/>'
    + '<path d="M12 6.5V3.5M8.4 7.4 6.4 5.2M15.6 7.4l2-2.2"/>',
  // An open hand held up: the raised-hand trigger.
  hand: '<path d="M7.5 12V6a1.5 1.5 0 0 1 3 0v5M10.5 11V4a1.5 1.5 0 0 1 3 0v7'
    + 'M13.5 11V5a1.5 1.5 0 0 1 3 0v7"/>'
    + '<path d="M16.5 12V8.5a1.5 1.5 0 0 1 3 0V14c0 4-3 7-7.5 7-3 0-4.6-1.2'
    + '-6-3.3L3.3 13.6a1.5 1.5 0 0 1 2.5-1.6L7.5 14"/>',
  apps: '<path d="M5 5h.01M12 5h.01M19 5h.01M5 12h.01M12 12h.01M19 12h.01'
    + 'M5 19h.01M12 19h.01M19 19h.01"/>',
  link: '<path d="M10 13a4 4 0 0 0 5.7.3l2-2a4 4 0 0 0-5.7-5.6l-1.1 1.1"/>'
    + '<path d="M14 11a4 4 0 0 0-5.7-.3l-2 2a4 4 0 0 0 5.7 5.6l1.1-1.1"/>',
  android: '<path d="M5 15.5a7 7 0 0 1 14 0z"/>'
    + '<path d="M8 10 6.5 7.5M16 10l1.5-2.5M9.5 13h.01M14.5 13h.01"/>',
  home: '<path d="M3 11.5 12 4l9 7.5"/><path d="M5.5 10.5V20h13v-9.5"/>',
  doc: '<path d="M6 3h8l4 4v14H6z"/><path d="M14 3v4h4M9 12h6M9 16h6"/>',
  playCircle: '<circle cx="12" cy="12" r="9"/>'
    + '<path d="m10 8.5 5.5 3.5-5.5 3.5z"/>',
  pauseCircle: '<circle cx="12" cy="12" r="9"/>'
    + '<path d="M10 9v6M14 9v6"/>',
  announce: '<path d="M4 9v6h4l5 4V5L8 9z"/>'
    + '<path d="M16.5 8.5a5 5 0 0 1 0 7"/>',
};

/* The name an exported configuration downloads under. Mirror of the device's
   exportFileName (managers/settings/export_filename.dart): a fleet of tablets
   used to produce identical kiosk-satellite-config.json files, unidentifiable
   once saved. Falls back to this browser's clock only when an older device
   sends an export without its own timestamp. */
export function exportFileName(deviceName, exportedAt) {
  const at = exportedAt ? new Date(exportedAt) : new Date();
  const when = isNaN(at.getTime()) ? new Date() : at;
  const two = (value) => String(value).padStart(2, '0');
  const stamp = `${when.getFullYear()}${two(when.getMonth() + 1)}`
    + `${two(when.getDate())}_${two(when.getHours())}`
    + `${two(when.getMinutes())}${two(when.getSeconds())}`;
  let slug = String(deviceName || '')
    .replace(/[^\x00-\x7F]/g, (ch) => EXPORT_FOLDED_LATIN[ch] || ch)
    .replace(/[^A-Za-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
  if (slug.length > 40) slug = slug.slice(0, 40).replace(/-+$/, '');
  return slug ? `ks-backup_${slug}_${stamp}.json` : `ks-backup_${stamp}.json`;
}

/* Mirror of _foldedLatin in export_filename.dart. Deliberately the same
   explicit table rather than NFD normalization, which Dart has no built-in
   equivalent for: both surfaces must name the same device identically. */
export const EXPORT_FOLDED_LATIN = {
  'á':'a','à':'a','â':'a','ä':'a','ã':'a','å':'a','ā':'a',
  'Á':'A','À':'A','Â':'A','Ä':'A','Ã':'A','Å':'A','Ā':'A',
  'é':'e','è':'e','ê':'e','ë':'e','ē':'e',
  'É':'E','È':'E','Ê':'E','Ë':'E','Ē':'E',
  'í':'i','ì':'i','î':'i','ï':'i','ī':'i',
  'Í':'I','Ì':'I','Î':'I','Ï':'I','Ī':'I',
  'ó':'o','ò':'o','ô':'o','ö':'o','õ':'o','ø':'o','ō':'o',
  'Ó':'O','Ò':'O','Ô':'O','Ö':'O','Õ':'O','Ø':'O','Ō':'O',
  'ú':'u','ù':'u','û':'u','ü':'u','ū':'u',
  'Ú':'U','Ù':'U','Û':'U','Ü':'U','Ū':'U',
  'ñ':'n','Ñ':'N','ç':'c','Ç':'C','ý':'y','ÿ':'y','Ý':'Y',
  'š':'s','Š':'S','ž':'z','Ž':'Z','ł':'l','Ł':'L',
  'đ':'d','Đ':'D','ß':'ss','æ':'ae','Æ':'AE','œ':'oe','Œ':'OE',
};

export function cameraIcon(name) {
  return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"'
    + ' stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"'
    + ' aria-hidden="true">' + CAMERA_ICONS[name] + '</svg>';
}

export function cameraAction(label, action, primary = false, icon = '', disabled = false) {
  const button = document.createElement('button');
  button.className = primary ? 'btn-primary' : 'btn-ghost';
  button.disabled = !!disabled;
  if (icon) {
    // The device's IconButton: a 40 borderless disc, the icon its label.
    // No inline width here: it would override the disc's 40 and squash
    // the hover ring into an oval.
    button.className = 'icon-btn';
    button.innerHTML = cameraIcon(icon);
    button.title = label;
    button.setAttribute('aria-label', label);
  } else {
    button.style.width = 'auto';
    button.textContent = label;
  }
  button.addEventListener('click', action);
  return button;
}

export function cameraListRow(title, description, actions, options = {}) {
  const row = document.createElement('div');
  row.className = 'row camera-list-row';
  const main = document.createElement('div');
  main.className = 'camera-row-main';
  if (options.icon) {
    const icon = document.createElement('span');
    icon.className = 'camera-row-icon';
    icon.innerHTML = cameraIcon(options.icon);
    main.appendChild(icon);
  }
  const info = document.createElement('div');
  info.className = 'info';
  const name = document.createElement('div');
  name.className = 'name';
  name.textContent = title;
  const desc = document.createElement('div');
  desc.className = 'desc';
  desc.textContent = description;
  info.append(name, desc);
  main.appendChild(info);
  const buttons = document.createElement('div');
  buttons.className = 'camera-row-actions';
  buttons.addEventListener('click', (event) => event.stopPropagation());
  actions.forEach((button) => buttons.appendChild(button));
  row.append(main, buttons);
  if (options.onClick && !options.disabled) {
    row.classList.add('camera-row-clickable');
    row.tabIndex = 0;
    row.setAttribute('role', 'button');
    row.addEventListener('click', options.onClick);
    row.addEventListener('keydown', (event) => {
      if (event.key !== 'Enter' && event.key !== ' ') return;
      event.preventDefault();
      options.onClick();
    });
  } else if (options.disabled) {
    row.classList.add('disabled');
    row.setAttribute('aria-disabled', 'true');
  }
  return row;
}

export function cameraSelectField(label, options, value) {
  const wrap = document.createElement('label');
  wrap.className = 'form-field';
  const title = document.createElement('span');
  title.className = 'desc';
  title.textContent = label;
  const select = document.createElement('select');
  select.className = 'field';
  select.style.maxWidth = 'none';
  for (const optionValue of options) {
    const option = document.createElement('option');
    option.value = optionValue.value;
    option.textContent = optionValue.label;
    option.selected = optionValue.value === value;
    select.appendChild(option);
  }
  wrap.append(title, select);
  return { wrap, select };
}

export function cameraToggle(label, checked, description = '') {
  const wrap = document.createElement('div');
  wrap.className = 'row';
  const info = document.createElement('div');
  info.className = 'info';
  const name = document.createElement('div');
  name.className = 'name';
  name.textContent = label;
  const desc = document.createElement('div');
  desc.className = 'desc';
  desc.textContent = description;
  info.append(name, desc);
  const toggle = document.createElement('label');
  toggle.className = 'switch';
  const input = document.createElement('input');
  input.type = 'checkbox';
  input.checked = checked;
  const slider = document.createElement('span');
  slider.className = 'slider';
  toggle.append(input, slider);
  wrap.append(info, toggle);
  return { wrap, input };
}

export function cameraEditor({ title, body, save, width = 620, tall = false }) {
  return new Promise((resolve) => {
    const shell = modalShell({ title, width });
    if (tall) shell.card.style.maxHeight = 'min(94vh, 1000px)';
    body.classList.add('modal-form');
    shell.body.appendChild(body);
    // The error stays visible under the body, above the fixed actions.
    const error = document.createElement('div');
    error.className = 'msg-error';
    error.style.flex = 'none';
    shell.card.insertBefore(error, shell.foot);
    const cancel = cameraAction('Cancel', () => {
      shell.close();
      resolve(false);
    });
    cancel.className = 'btn-text';
    const submit = cameraAction('Save', async () => {
      submit.disabled = true;
      error.textContent = '';
      try {
        const result = await save();
        if (!result || !result.ok) {
          error.textContent = result?.error || 'Could not save';
          submit.disabled = false;
          return;
        }
        shell.close();
        resolve(true);
      } catch (exception) {
        error.textContent = String(exception);
        submit.disabled = false;
      }
    }, true);
    shell.foot.append(cancel, submit);
  });
}

/* The At a Glance entity chooser, as a modal. Mirrors the device's picker:
   the chosen entities on top in display order, a Home Assistant search below.
   Nothing is listed until something is typed — the unfiltered list is every
   entity in the instance, which is thousands of rows of noise and a lot of
   traffic for a panel nobody asked to browse. Resolves to the new list, or
   null when cancelled. */
export const GLANCE_MAX = 4;

/* The Microphone settings warning. Kept identical to the device's copy in
   settings_screen.dart, which is the one users read on the tablet. */
export const MIC_GROUP_NOTE =
  'Only for devices that capture too quietly. Wrong values make wake word ' +
  'detection worse.';

/* One chosen glance entity's editable pieces in a single modal, mirroring
   the device's dialog: the name the row shows (issue #206) — a custom one,
   or the Home Assistant name when the field is left empty — and which value
   it displays, the state (the default) or one of its attributes (issue
   #132). The attribute options are the entity's live scalar attributes,
   each shown with its current reading, so the choice is made by looking at
   real values. Applies the edit to `entity` and resolves to true when
   saved. */
export async function glanceEntityEditor(entity) {
  let attributes = null;
  try {
    const res = await (await api('/api/commands/haEntityAttributes', {
      method: 'POST', body: JSON.stringify({ entity_id: entity.entity_id }) })).json();
    if (res.ok) attributes = res.data || {};
  } catch (_) {}
  if (!attributes) {
    messageBox({ title: 'At a glance', message: 'Could not reach Home Assistant.' });
    return false;
  }
  /* Presentation metadata and structured values are left out, same list as
     the device's picker: a forecast array is not a glanceable reading. */
  const hidden = ['friendly_name', 'icon', 'entity_picture',
    'supported_features', 'attribution'];
  const names = Object.keys(attributes).filter((k) =>
    !hidden.includes(k)
    && (attributes[k] === null || typeof attributes[k] !== 'object')).sort();
  const body = document.createElement('div');
  const field = cameraField('Name', entity.custom_name || '');
  field.input.placeholder = entity.name || entity.entity_id;
  const note = document.createElement('div');
  note.className = 'desc';
  note.style.marginTop = '8px';
  note.textContent = 'Leave empty to use the Home Assistant name.';
  const label = document.createElement('div');
  label.className = 'desc';
  label.style.cssText = 'margin-top:16px; font-weight:600;';
  label.textContent = 'Displayed value';
  let picked = entity.attribute || '';
  const rows = document.createElement('div');
  const paint = () => {
    rows.innerHTML = '';
    rows.appendChild(radioRow('State', '', picked === '', () => {
      picked = '';
      paint();
    }));
    for (const name of names) {
      rows.appendChild(radioRow(name, String(attributes[name]),
        picked === name, () => { picked = name; paint(); }));
    }
  };
  paint();
  body.append(field.wrap, note, label, rows);
  const saved = await cameraEditor({
    title: entity.name || entity.entity_id, body, width: 460,
    save: async () => ({ ok: true }) });
  if (!saved) return false;
  const name = field.input.value.trim();
  if (name) entity.custom_name = name;
  else delete entity.custom_name;
  if (picked) entity.attribute = picked;
  else delete entity.attribute;
  return true;
}

export async function glanceEntityPicker(initial) {
  const chosen = (initial || []).map((e) => ({ ...e }));
  const body = document.createElement('div');

  const chosenLabel = document.createElement('div');
  chosenLabel.className = 'desc';
  chosenLabel.style.cssText = 'margin:0 2px 6px; font-weight:600;';
  chosenLabel.textContent = 'Showing';
  const list = document.createElement('div');
  list.className = 'card';
  list.style.cssText = 'margin:0 0 16px; padding:0 16px;';

  const search = document.createElement('input');
  search.type = 'search';
  search.placeholder = 'Search by name or entity id';
  search.className = 'field';
  search.style.margin = '0';
  const results = document.createElement('div');
  results.className = 'edge-fade';
  results.style.cssText = 'max-height:320px; overflow:auto; margin-top:8px;';
  const hint = (text) => {
    results.innerHTML = '';
    const el = document.createElement('div');
    el.className = 'desc';
    el.style.padding = '14px 2px';
    el.textContent = text;
    results.appendChild(el);
  };

  let lastResults = [];
  const renderChosen = () => {
    list.innerHTML = '';
    chosenLabel.style.display = chosen.length ? '' : 'none';
    list.style.display = chosen.length ? '' : 'none';
    chosen.forEach((entity, index) => {
      const item = document.createElement('div');
      item.className = 'row';
      item.style.cssText = 'gap:8px;';
      const info = document.createElement('div');
      info.className = 'info';
      const name = document.createElement('div');
      name.className = 'name';
      name.textContent = entity.custom_name || entity.name || entity.entity_id;
      const desc = document.createElement('div');
      desc.className = 'desc';
      desc.textContent = entity.attribute
        ? `${entity.entity_id} · ${entity.attribute}`
        : entity.entity_id;
      info.append(name, desc);
      const edit = cameraAction('Edit', async () => {
        if (await glanceEntityEditor(entity)) renderChosen();
      }, false, 'pencil');
      const move = (delta) => {
        const to = index + delta;
        if (to < 0 || to >= chosen.length) return;
        chosen.splice(to, 0, chosen.splice(index, 1)[0]);
        renderChosen();
      };
      const up = cameraAction('Move up', () => move(-1), false, 'up', index === 0);
      const down = cameraAction('Move down', () => move(1), false, 'down',
        index === chosen.length - 1);
      const remove = cameraAction('Remove', () => {
        chosen.splice(index, 1);
        renderChosen();
        renderResults(lastResults);
      }, false, 'delete');
      item.append(info, edit, up, down, remove);
      list.appendChild(item);
    });
  };

  const renderResults = (entities) => {
    lastResults = entities;
    if (!entities.length) {
      hint(search.value.trim() ? 'Nothing matched.' : 'Type to search entities.');
      return;
    }
    results.innerHTML = '';
    for (const entity of entities) {
      const picked = chosen.some((e) => e.entity_id === entity.entity_id);
      const item = document.createElement('div');
      item.className = 'row';
      const info = document.createElement('div');
      info.className = 'info';
      const name = document.createElement('div');
      name.className = 'name';
      name.textContent = entity.name;
      const desc = document.createElement('div');
      desc.className = 'desc';
      desc.textContent = `${entity.entity_id} \u00b7 ${entity.state}`;
      info.append(name, desc);
      const btn = cameraAction(picked ? 'Remove' : 'Add', () => {
        if (picked) {
          const at = chosen.findIndex((e) => e.entity_id === entity.entity_id);
          if (at >= 0) chosen.splice(at, 1);
        } else if (chosen.length < GLANCE_MAX) {
          chosen.push({ entity_id: entity.entity_id, name: entity.name });
        } else {
          return;
        }
        renderChosen();
        renderResults(lastResults);
      }, false, picked ? 'delete' : 'add', !picked && chosen.length >= GLANCE_MAX);
      item.append(info, btn);
      results.appendChild(item);
    }
  };

  let debounce;
  search.addEventListener('input', () => {
    clearTimeout(debounce);
    const query = search.value.trim();
    if (!query) { renderResults([]); return; }
    debounce = setTimeout(async () => {
      hint('Searching\u2026');
      try {
        const res = await (await api('/api/commands/haSearchEntities', {
          method: 'POST', body: JSON.stringify({ query }) })).json();
        if (search.value.trim() !== query) return; // a newer search won
        if (!res.ok) { hint('Could not reach Home Assistant.'); return; }
        renderResults(res.data || []);
      } catch (_) {
        hint('The device did not answer.');
      }
    }, 350);
  });

  renderChosen();
  renderResults([]);
  body.append(chosenLabel, list, search, results);
  const saved = await cameraEditor({
    title: 'At a glance entities',
    body,
    save: async () => ({ ok: true }),
  });
  return saved ? chosen : null;
}

export async function editCameraServer(server) {
  const body = document.createElement('div');
  const name = cameraField('Name', server?.name || 'Go2RTC');
  const url = cameraField('Base URL', server?.baseUrl || '');
  url.input.placeholder = 'http://192.168.1.10:1984';
  const username = cameraField('Username (optional)', server?.username || '');
  const password = cameraField(
    server?.passwordSet ? 'New password (leave blank to keep)' : 'Password (optional)',
    '',
    'password',
  );
  const invalidCertificate = cameraToggle(
    'Allow invalid TLS certificate',
    server?.allowInvalidCertificate === true,
  );
  body.append(
    name.wrap,
    url.wrap,
    username.wrap,
    password.wrap,
    invalidCertificate.wrap,
  );
  return cameraEditor({
    title: server ? 'Edit server' : 'Add Go2RTC server',
    body,
    save: () => {
      const params = {
        id: server?.id || '',
        name: name.input.value,
        baseUrl: url.input.value,
        username: username.input.value,
        allowInvalidCertificate: invalidCertificate.input.checked,
      };
      if (!server || password.input.value) params.password = password.input.value;
      return cmd('cameraPutServer', params);
    },
  });
}

export async function editCameraSource(config, camera) {
  const body = document.createElement('div');
  const name = cameraField('Name', camera?.name || '');
  const initialKind = camera?.kind || (config.servers.length ? 'go2rtc' : 'whep');
  const kind = cameraSelectField('Type', [
    { value: 'go2rtc', label: 'Go2RTC stream' },
    { value: 'whep', label: 'Direct WHEP URL' },
    { value: 'ha', label: 'Home Assistant camera' },
  ], initialKind);
  const server = cameraSelectField(
    'Server',
    config.servers.map((item) => ({ value: item.id, label: item.name })),
    camera?.serverId || config.servers[0]?.id || '',
  );
  const stream = cameraField('Go2RTC stream name', camera?.streamName || '');
  const fullscreen = cameraField(
    'Fullscreen stream (optional)',
    camera?.fullscreenStreamName || '',
  );
  const whep = cameraField('WHEP URL', camera?.whepUrl || '');
  const entity = cameraField('Camera entity', camera?.entityId || '');
  body.append(
    name.wrap,
    kind.wrap,
    server.wrap,
    stream.wrap,
    fullscreen.wrap,
    whep.wrap,
    entity.wrap,
  );
  const updateKind = () => {
    const value = kind.select.value;
    const go2rtc = value === 'go2rtc';
    server.wrap.style.display = go2rtc ? '' : 'none';
    stream.wrap.style.display = go2rtc ? '' : 'none';
    fullscreen.wrap.style.display = go2rtc ? '' : 'none';
    whep.wrap.style.display = value === 'whep' ? '' : 'none';
    entity.wrap.style.display = value === 'ha' ? '' : 'none';
  };
  kind.select.addEventListener('change', updateKind);
  updateKind();
  return cameraEditor({
    title: camera ? 'Edit camera' : 'Add camera',
    body,
    save: () => cmd('cameraPutSource', {
      id: camera?.id || '',
      name: name.input.value,
      kind: kind.select.value,
      serverId: server.select.value,
      streamName: stream.input.value,
      fullscreenStreamName: fullscreen.input.value,
      whepUrl: whep.input.value,
      entityId: entity.input.value,
    }),
  });
}

export async function editCameraView(config, view) {
  const body = document.createElement('div');
  const name = cameraField('Name', view?.name || '');
  const showNames = cameraToggle(
    'Show camera names',
    view?.showCameraNames !== false,
    'Display a label over each camera.',
  );
  const selected = [...(view?.cameraIds || [])];
  const byId = Object.fromEntries(config.cameras.map((c) => [c.id, c]));

  // Two lists: the ones in the view, in grid order and draggable, and the
  // rest waiting to be added. Selection order used to be the only way to
  // order tiles, which meant unticking everything to move one.
  const chosen = document.createElement('div');
  chosen.className = 'card';
  chosen.style.cssText = 'margin:0; padding:0 16px;';
  const available = document.createElement('div');
  available.className = 'card';
  available.style.cssText = 'margin:0; padding:0 16px;';
  // Section labels styled like the device dialog's: primary color, semibold.
  const label = (text) => {
    const el = document.createElement('div');
    el.className = 'desc';
    el.style.cssText = 'margin:14px 2px 6px; font-weight:600;'
      + ' color:var(--primary);';
    el.textContent = text;
    return el;
  };
  const chosenLabel = label('In this view');
  const availableLabel = label('Available');
  // The grid the view renders with: the UniFi Protect layout per slot
  // count, chosen in a dropdown like UniFi's and numbered in camera order.
  // GRIDS is [columns, rows] in layout units, SPANS lists
  // [columnSpan, rowSpan] for the leading tiles that cover several units.
  // Mirrored in assets/camera-view/index.html and ui/camera_settings.dart.
  const GRIDS = {
    1: [1, 1], 2: [2, 1], 3: [2, 2], 4: [2, 2], 5: [4, 2], 6: [3, 3],
    7: [4, 4], 8: [3, 4], 9: [3, 3], 10: [4, 4], 11: [5, 4], 12: [6, 6],
  };
  const SPANS = {
    3: [[1, 2]],
    5: [[2, 2]],
    6: [[2, 2]],
    7: [[2, 2], [2, 2], [2, 2]],
    8: [[1, 2], [1, 2], [1, 1], [1, 1], [1, 2], [1, 2]],
    10: [[2, 2], [1, 1], [1, 1], [1, 1], [1, 1], [2, 2]],
    11: [[2, 2], [2, 2], [1, 1], [1, 1], [2, 2]],
    12: [[3, 3], [3, 3], [3, 3]],
  };
  let grid = view?.grid || selected.length || 1;

  // A miniature wireframe of a layout, the dropdown icon.
  const gridIcon = (size) => {
    const icon = document.createElement('div');
    const spec = GRIDS[size];
    icon.style.cssText = 'display:grid; gap:1.5px; width:34px; height:22px;'
      + ` flex:none; grid-template-columns:repeat(${spec[0]}, 1fr);`
      + ` grid-template-rows:repeat(${spec[1]}, 1fr);`;
    const spans = SPANS[size] || [];
    for (let slot = 0; slot < size; slot++) {
      const cell = document.createElement('div');
      cell.style.cssText = 'border:1px solid var(--muted);'
        + ' border-radius:1.5px; min-width:0; min-height:0;';
      const span = spans[slot] || [1, 1];
      if (span[0] > 1) cell.style.gridColumn = `span ${span[0]}`;
      if (span[1] > 1) cell.style.gridRow = `span ${span[1]}`;
      icon.appendChild(cell);
    }
    return icon;
  };

  // The Grid dropdown is custom-built: a native select cannot show the
  // layout icons the device dropdown has.
  const gridField = document.createElement('div');
  gridField.className = 'form-field';
  gridField.style.cssText = 'margin-top:14px; position:relative;';
  const gridLabel = label('Grid');
  gridLabel.style.margin = '0 2px';
  const gridButton = document.createElement('button');
  gridButton.type = 'button';
  gridButton.className = 'field';
  gridButton.style.cssText = 'max-width:none; display:flex;'
    + ' align-items:center; gap:12px; cursor:pointer; text-align:left;';
  const gridMenu = document.createElement('div');
  gridMenu.className = 'edge-fade';
  gridMenu.style.cssText = 'display:none; position:absolute; top:100%;'
    + ' left:0; right:0; z-index:30; margin-top:4px;'
    + ' background:var(--surface); border:1px solid var(--border);'
    + ' border-radius:var(--radius-sm);'
    + ' box-shadow:0 12px 32px rgba(0,0,0,.35);'
    + ' max-height:320px; overflow-y:auto; padding:6px;';
  gridField.append(gridLabel, gridButton, gridMenu);
  const closeGridMenu = () => { gridMenu.style.display = 'none'; };
  const outsideGridMenu = (event) => {
    if (!document.body.contains(gridField)) {
      document.removeEventListener('click', outsideGridMenu);
    } else if (!gridField.contains(event.target)) {
      closeGridMenu();
    }
  };
  document.addEventListener('click', outsideGridMenu);
  gridButton.addEventListener('click', () => {
    gridMenu.style.display =
      gridMenu.style.display === 'none' ? 'block' : 'none';
  });

  const preview = document.createElement('div');
  preview.style.cssText = 'display:grid; gap:3px; width:210px; height:126px;'
    + ' margin:12px auto 2px;';
  const renderPreview = () => {
    grid = Math.min(12, Math.max(grid, selected.length, 1));
    gridButton.innerHTML = '';
    const gridText = document.createElement('span');
    gridText.textContent = `${grid} Camera${grid === 1 ? '' : 's'}`;
    gridText.style.flex = '1';
    const chevron = document.createElement('span');
    chevron.style.cssText = 'color:var(--muted); display:flex;';
    chevron.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" '
      + 'fill="none" stroke="currentColor" stroke-width="2" '
      + 'stroke-linecap="round" stroke-linejoin="round">'
      + '<path d="m6 9 6 6 6-6"/></svg>';
    gridButton.append(gridIcon(grid), gridText, chevron);
    gridMenu.innerHTML = '';
    for (let size = Math.max(1, selected.length); size <= 12; size++) {
      const option = document.createElement('button');
      option.type = 'button';
      option.style.cssText = 'display:flex; align-items:center; gap:12px;'
        + ' width:100%; padding:8px 10px; border:none; background:'
        + (size === grid ? 'var(--surface-2)' : 'transparent')
        + '; color:var(--text); border-radius:8px; cursor:pointer;'
        + ' font-size:14px; text-align:left;';
      const optionText = document.createElement('span');
      optionText.textContent = `${size} Camera${size === 1 ? '' : 's'}`;
      option.append(gridIcon(size), optionText);
      option.addEventListener('click', () => {
        grid = size;
        closeGridMenu();
        renderPreview();
      });
      gridMenu.appendChild(option);
    }
    gridField.style.display = selected.length ? '' : 'none';
    preview.style.display = selected.length ? 'grid' : 'none';
    const spec = GRIDS[grid];
    if (!spec || !selected.length) return;
    // Cameras take the largest tiles first, exactly like the live view:
    // rank[slot] says which camera, by view order, sits in each slot.
    const spans = SPANS[grid] || [];
    const area = (slot) => {
      const span = spans[slot];
      return span ? span[0] * span[1] : 1;
    };
    const priority = Array.from({ length: grid }, (_, slot) => slot)
      .sort((a, b) => area(b) - area(a) || a - b);
    const rank = [];
    priority.forEach((slot, position) => { rank[slot] = position; });
    preview.innerHTML = '';
    preview.style.gridTemplateColumns = `repeat(${spec[0]}, 1fr)`;
    preview.style.gridTemplateRows = `repeat(${spec[1]}, 1fr)`;
    for (let slot = 0; slot < grid; slot++) {
      const cell = document.createElement('div');
      const span = spans[slot] || [1, 1];
      const hasCamera = rank[slot] < selected.length;
      cell.style.cssText =
        `border:1px solid var(${hasCamera ? '--border' : '--divider'});`
        + (hasCamera ? ' background:var(--surface-2);' : '')
        + ' border-radius:4px; display:flex; align-items:center;'
        + ' justify-content:center; font-size:11px; color:var(--muted);'
        + ' min-width:0; min-height:0;';
      if (span[0] > 1) cell.style.gridColumn = `span ${span[0]}`;
      if (span[1] > 1) cell.style.gridRow = `span ${span[1]}`;
      if (hasCamera) cell.textContent = rank[slot] + 1;
      preview.appendChild(cell);
    }
  };

  let dragId = null;
  const render = () => {
    renderPreview();
    chosen.innerHTML = '';
    available.innerHTML = '';
    selected.forEach((id, index) => {
      const camera = byId[id];
      const row = document.createElement('div');
      row.className = 'row';
      row.draggable = true;
      row.dataset.id = id;
      row.style.cssText = 'cursor:grab; gap:10px;';
      const handle = document.createElement('span');
      handle.className = 'camera-row-icon';
      handle.innerHTML = cameraIcon('drag');
      handle.style.flexShrink = '0';
      const info = document.createElement('div');
      info.className = 'info';
      const cameraName = document.createElement('div');
      cameraName.className = 'name';
      cameraName.textContent = camera ? camera.name : id;
      const description = document.createElement('div');
      description.className = 'desc';
      description.textContent = `Position ${index + 1}`;
      info.append(cameraName, description);
      const remove = cameraAction('Remove', () => {
        selected.splice(selected.indexOf(id), 1);
        render();
      }, false, 'delete');
      row.append(handle, info, remove);
      // Drop onto a row: the dragged camera takes that row's place, and
      // everything from there shifts down. Touch devices use the arrows.
      row.addEventListener('dragstart', (event) => {
        dragId = id;
        row.style.opacity = '.45';
        event.dataTransfer.effectAllowed = 'move';
        // Firefox refuses to start a drag without payload.
        event.dataTransfer.setData('text/plain', id);
      });
      row.addEventListener('dragend', () => {
        dragId = null;
        row.style.opacity = '';
      });
      row.addEventListener('dragover', (event) => {
        if (!dragId || dragId === id) return;
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
      });
      row.addEventListener('drop', (event) => {
        if (!dragId || dragId === id) return;
        event.preventDefault();
        const from = selected.indexOf(dragId);
        const to = selected.indexOf(id);
        selected.splice(from, 1);
        selected.splice(to, 0, dragId);
        dragId = null;
        render();
      });
      // A tablet has no drag: the same reordering, one step at a time.
      const move = (delta) => {
        const to = index + delta;
        if (to < 0 || to >= selected.length) return;
        selected.splice(to, 0, selected.splice(index, 1)[0]);
        render();
      };
      const up = cameraAction('Move up', () => move(-1), false, 'up', index === 0);
      const down = cameraAction('Move down', () => move(1), false, 'down',
        index === selected.length - 1);
      row.insertBefore(down, remove);
      row.insertBefore(up, down);
      chosen.appendChild(row);
    });
    for (const camera of config.cameras) {
      if (selected.includes(camera.id)) continue;
      const row = document.createElement('div');
      row.className = 'row';
      const info = document.createElement('div');
      info.className = 'info';
      const cameraName = document.createElement('div');
      cameraName.className = 'name';
      cameraName.textContent = camera.name;
      const description = document.createElement('div');
      description.className = 'desc';
      description.textContent = camera.missing ? 'Missing from Go2RTC' : '';
      info.append(cameraName, description);
      const add = cameraAction('Add', () => {
        if (selected.length >= 12) return;
        selected.push(camera.id);
        render();
      }, false, 'add', selected.length >= 12);
      row.append(info, add);
      available.appendChild(row);
    }
    chosenLabel.style.display = selected.length ? '' : 'none';
    chosen.style.display = selected.length ? '' : 'none';
    const hasAvailable = config.cameras.some((c) => !selected.includes(c.id));
    availableLabel.style.display = hasAvailable ? '' : 'none';
    available.style.display = hasAvailable ? '' : 'none';
  };
  render();
  body.append(name.wrap, showNames.wrap, gridField, preview,
    chosenLabel, chosen, availableLabel, available);
  return cameraEditor({
    title: view ? 'Edit view' : 'Create camera view',
    body,
    width: 780,
    tall: true,
    save: () => cmd('cameraPutView', {
      id: view?.id || '',
      name: name.input.value,
      cameraIds: selected,
      showCameraNames: showNames.input.checked,
      ...(selected.length ? { grid } : {}),
    }),
  });
}

export async function loadCameras() {
  const root = document.getElementById('tab-cameras');
  const result = await cmd('cameraGetConfig').catch(() => null);
  if (!result || !result.ok) {
    root.innerHTML = '<div class="card"><div class="desc">Could not load cameras.</div></div>';
    return;
  }
  const config = result.data;
  // The page is otherwise built from the camera document alone; the playback
  // row at the end is a real setting, so its definition comes from the
  // settings API the same way the generic pages read theirs.
  let settings = [];
  try {
    const read = await (await api('/api/settings')).json();
    settings = read.settings || [];
    state.settings = settings;
  } catch (_) {}
  root.innerHTML = '';

  const heading = (text) => {
    const h = document.createElement('h2');
    h.className = 'card-title';
    h.textContent = text;
    root.appendChild(h);
  };
  const card = () => {
    const value = document.createElement('div');
    value.className = 'card';
    root.appendChild(value);
    return value;
  };
  const refresh = () => loadCameras();

  heading('Home Assistant');
  const haCard = card();
  haCard.appendChild(cameraListRow(
    'Import cameras from Home Assistant',
    'Add every camera of the connected Home Assistant, playing over '
      + 'WebRTC, HLS or MJPEG. Importing again merges new cameras.',
    [
      cameraAction('Import', async () => {
        const imported = await cmd('cameraImportHomeAssistant');
        if (!imported.ok) {
          await messageBox({ title: 'Import failed', message: imported.error });
        } else {
          await messageBox({
            title: 'Import complete',
            message: `${imported.data.added} added, ${imported.data.missing} missing.`,
          });
        }
        refresh();
      }, false, 'download'),
    ],
    { icon: 'home' },
  ));

  heading('Go2RTC servers');
  const serversCard = card();
  for (const server of config.servers) {
    serversCard.appendChild(cameraListRow(server.name, server.baseUrl, [
      cameraAction('Import', async () => {
        const imported = await cmd('cameraImportGo2Rtc', { serverId: server.id });
        if (!imported.ok) {
          await messageBox({ title: 'Import failed', message: imported.error });
        } else {
          await messageBox({
            title: 'Import complete',
            message: `${imported.data.added} added, ${imported.data.missing} missing.`,
          });
        }
        refresh();
      }, false, 'download'),
      cameraAction('Delete', async () => {
        const choice = await messageBox({
          title: `Delete ${server.name}?`,
          message: 'Its cameras will be removed from every view.',
          buttons: ['Cancel', 'Delete'],
        });
        if (choice !== 'Delete') return;
        await cmd('cameraDeleteServer', { id: server.id });
        refresh();
      }, false, 'delete'),
    ], {
      icon: 'dns',
      onClick: async () => {
        if (await editCameraServer(server)) refresh();
      },
    }));
  }
  serversCard.appendChild(cameraListRow(
    'Add Go2RTC server',
    'Connect to a server and import its streams.',
    [],
    {
      icon: 'add',
      onClick: async () => {
        if (await editCameraServer(null)) refresh();
      },
    },
  ));

  heading('Cameras');
  const camerasCard = card();
  if (!config.cameras.length) {
    camerasCard.appendChild(cameraListRow(
      'No cameras configured',
      'Import cameras from Home Assistant or Go2RTC, or add one manually.',
      [],
      { icon: 'videoOff' },
    ));
  }
  const serverNames = Object.fromEntries(config.servers.map((server) => [server.id, server.name]));
  // The stream formats a camera can play with, for its list row.
  // Mirrored from ui/camera_settings.dart (_cameraFormats).
  const cameraFormats = (camera) => {
    if (camera.kind === 'go2rtc') return 'WebRTC, MSE';
    if (camera.kind !== 'ha') return 'WebRTC';
    if (!camera.streamTypes) return 'WebRTC, HLS, MJPEG';
    return [
      camera.streamTypes.includes('web_rtc') && 'WebRTC',
      camera.streamTypes.includes('hls') && 'HLS',
      'MJPEG',
    ].filter(Boolean).join(', ');
  };
  for (const camera of config.cameras) {
    const formats = ` · ${cameraFormats(camera)}`;
    const description = camera.kind === 'whep'
      ? `${camera.whepUrl}${formats}`
      : camera.kind === 'ha'
        ? `Home Assistant: ${camera.entityId || ''}`
          + (camera.missing ? ' (missing)' : '') + formats
        : `${serverNames[camera.serverId] || 'Unknown server'}: ${camera.streamName}`
          + (camera.missing ? ' (missing)' : '') + formats;
    camerasCard.appendChild(cameraListRow(camera.name, description, [
      cameraAction('Delete', async () => {
        const choice = await messageBox({
          title: `Delete ${camera.name}?`,
          message: 'It will be removed from every view.',
          buttons: ['Cancel', 'Delete'],
        });
        if (choice !== 'Delete') return;
        await cmd('cameraDeleteSource', { id: camera.id });
        refresh();
      }, false, 'delete'),
    ], {
      icon: camera.missing ? 'linkOff' : 'video',
      onClick: async () => {
        if (await editCameraSource(config, camera)) refresh();
      },
    }));
  }
  camerasCard.appendChild(cameraListRow(
    'Add camera manually',
    'Use a Go2RTC stream name, a WHEP URL or a Home Assistant camera entity.',
    [],
    {
      icon: 'add',
      onClick: async () => {
        if (await editCameraSource(config, null)) refresh();
      },
    },
  ));

  heading('Views');
  const viewsCard = card();
  const cameraNames = Object.fromEntries(config.cameras.map((camera) => [camera.id, camera.name]));
  for (const view of config.views) {
    const empty = !view.cameraIds.length;
    const actions = [
      cameraAction('Show', async () => {
        const shown = await cmd('showCameraView', { viewId: view.id });
        if (!shown.ok) {
          await messageBox({ title: 'Could not show view', message: shown.error });
        }
      }, false, 'play', empty),
      cameraAction('Stop', async () => {
        await cmd('hideCameraView');
      }, false, 'stop'),
    ];
    // The default view is permanent: emptying it retires it.
    if (!view.isDefault) {
      actions.push(cameraAction('Delete', async () => {
        const choice = await messageBox({
          title: `Delete ${view.name}?`,
          message: 'This cannot be undone.',
          buttons: ['Cancel', 'Delete'],
        });
        if (choice !== 'Delete') return;
        await cmd('cameraDeleteView', { id: view.id });
        refresh();
      }, false, 'delete'));
    }
    viewsCard.appendChild(cameraListRow(
      view.name,
      empty
        ? 'No cameras yet'
        : view.cameraIds.map((id) => cameraNames[id] || id).join(', ')
          + ` · Names ${view.showCameraNames === false ? 'hidden' : 'shown'}`,
      actions,
      {
        icon: view.isDefault ? 'star' : 'grid',
        onClick: async () => {
          if (await editCameraView(config, view)) refresh();
        },
      },
    ));
  }
  viewsCard.appendChild(cameraListRow(
    'Create camera view',
    config.cameras.length
      ? 'Choose and order up to 12 cameras.'
      : 'Add a camera first.',
    [],
    {
      icon: 'add',
      disabled: !config.cameras.length,
      onClick: async () => {
        if (await editCameraView(config, null)) refresh();
      },
    },
  ));

  // Mirrors the device's Playback section (ui/camera_settings.dart).
  const playbackKeys = ['camera.allow_h265', 'camera.prefer_mse',
    'camera.prefer_hls', 'camera.single_audio', 'camera.pinch_zoom',
    'camera.auto_dismiss_seconds'];
  const playback = playbackKeys
    .map((key) => settings.find((setting) => setting.key === key))
    .filter(Boolean);
  if (playback.length) {
    heading('Playback');
    const playbackCard = card();
    for (const setting of playback) playbackCard.appendChild(settingRow(setting));
  }
}
