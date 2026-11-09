import { gestureText, haText, pluginText, t } from './localization.js';
import { cmd } from './core.js';
import { cameraIcon } from './cameras.js';
import { dashboardField } from './dashboard_picker.js';
import { describeGestureAction, loadPluginActionNames, pickGestureAction } from './gestures.js';
import { ENTITY_ICONS, cachedList, entitySpec, loadEntityList, onListLoaded, pickField, pickItem } from './entity_picker.js';
import { choiceControl, choiceLabel, choiceSpec, watchPluginSetup } from './plugin_setup.js';
import { hintRow, modalShell, swatch } from './widgets.js';

/* Plugin list settings and the picker setting types, the device's
   plugin_list_setting.dart in the browser: the rows inline on the plugin
   page, a modal per row, and the icon, dashboard, camera view and action
   fields. */

const SVG = 'http://www.w3.org/2000/svg';
const CHEVRON = 'M7.41,8.58L12,13.17L16.59,8.58L18,10L12,16L6,10L7.41,8.58Z';
const PLACEHOLDER = 'M12,2A10,10 0 0,0 2,12A10,10 0 0,0 12,22A10,10 0 0,0 22,12A10,10 0 0,0 12,2M12,4A8,8 0 0,1 20,12A8,8 0 0,1 12,20A8,8 0 0,1 4,12A8,8 0 0,1 12,4Z';
const BACK = 'M20,11V13H8L13.5,18.5L12.08,19.92L4.16,12L12.08,4.08L13.5,5.5L8,11H20Z';

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

function svgPath(d, size = 24) {
  const svg = document.createElementNS(SVG, 'svg');
  svg.setAttribute('viewBox', '0 0 24 24');
  svg.setAttribute('width', size); svg.setAttribute('height', size);
  svg.setAttribute('aria-hidden', 'true');
  const path = document.createElementNS(SVG, 'path');
  path.setAttribute('d', d); path.setAttribute('fill', 'currentColor');
  svg.appendChild(path);
  return svg;
}

/* ------------------------------------------------------------ rules */

// The default a field starts with. Row fields may leave it out, and then
// the type supplies one, the same as the device.
export function fieldDefault(field) {
  if ('default' in field) return structuredClone(field.default);
  switch (field.type) {
    case 'boolean': return false;
    case 'number': return field.min;
    case 'select': return field.options[0];
    case 'color': return '#FFFFFF';
    case 'list': return [];
    case 'action': return {};
    default: return '';
  }
}

// Whether [field] shows, given the other values on its level. A field
// under a hidden one hides too.
export function fieldVisible(field, values, fields) {
  const condition = field.visibleWhen;
  if (!condition) return true;
  const target = fields.find((f) => f.key === condition.key);
  if (!target) return true;
  if (!fieldVisible(target, values, fields)) return false;
  const value = condition.key in values ? values[condition.key] : fieldDefault(target);
  if ('notEmpty' in condition) {
    return typeof value === 'string' ? value !== '' : typeof value === 'boolean' ? value : value != null;
  }
  const expected = (v) => (Array.isArray(v) ? v : [v]);
  if ('equals' in condition) return expected(condition.equals).includes(value);
  return !expected(condition.notEquals).includes(value);
}

// A required field shown on [row] still empty, or a shown list short of
// its minimum. Save waits for both.
function fieldMissing(field, row, fields) {
  if (!fieldVisible(field, row, fields)) return false;
  const value = row[field.key];
  if (field.type === 'list') {
    const rows = Array.isArray(value) ? value : [];
    return rows.length < (field.minItems || 0) || rows.some((r) => !rowComplete(field.fields, r));
  }
  if (field.type === 'action') return field.required === true && !actionChosen(value);
  return field.required === true && String(value ?? '').trim() === '';
}

const actionChosen = (value) => !!value && typeof value === 'object' && Object.keys(value).length > 0;

export function rowComplete(fields, row) {
  return !fields.some((f) => fieldMissing(f, row, fields));
}

// Why [text] is not a value the number [field] takes, or null when it is.
// The same checks as PluginManifest.validateValue.
export function numberError(field, text) {
  const value = String(text).trim() === '' ? NaN : Number(text);
  if (!Number.isFinite(value)) return pluginText('Expected a numeric setting');
  if (value < field.min || value > field.max) return pluginText('Numeric setting is outside its range');
  const steps = (value - field.min) / (field.step || 1);
  if (Math.abs(steps - Math.round(steps)) >= 0.00001) return pluginText('Numeric setting does not match its step');
  return null;
}

// A typed number: the box, its unit after it and the reason it is not
// valid yet under it. [onInput] gets the box's text on every keystroke.
export function numberControl(field, text, onInput) {
  const control = el('div', 'plugin-number');
  const input = el('input', 'field');
  input.type = 'number'; input.min = field.min; input.max = field.max; input.step = field.step || 1;
  input.value = text;
  input.setAttribute('aria-label', field.title);
  control.appendChild(input);
  if (field.unit) control.appendChild(el('span', 'desc', field.unit));
  const error = el('div', 'desc plugin-number-error');
  const check = () => {
    const reason = numberError(field, input.value);
    input.classList.toggle('error', reason != null);
    error.textContent = reason || '';
    error.hidden = reason == null;
    return reason;
  };
  input.oninput = () => { check(); onInput(input.value); };
  check();
  return { control, input, error, check };
}

function filledRow(list, row) {
  const out = {};
  for (const field of list.fields) {
    out[field.key] = row && field.key in row ? structuredClone(row[field.key]) : fieldDefault(field);
  }
  return out;
}

function rowKey(list, part) {
  if (list.row?.[part]) return list.row[part];
  if (part !== 'title') return null;
  return list.fields.find((f) => f.type === 'string')?.key || null;
}

const fieldOf = (list, key) => (key ? list.fields.find((f) => f.key === key) || null : null);
const findEntity = (id) => cachedList('entities')?.items.find((i) => i.id === id) || null;

// The entity a row's title names, when its title is an entity field that
// holds one. Its item comes from the shared entity list once that loads.
function titleEntity(list, row) {
  const key = rowKey(list, 'title');
  if (fieldOf(list, key)?.type !== 'entity') return null;
  const id = String(row[key] ?? '').trim();
  return id ? { id, item: findEntity(id) } : null;
}

// The fields a row's title and second line read from.
function rowFields(list) {
  const declared = list.row?.subtitle;
  const keys = [rowKey(list, 'title'), ...(Array.isArray(declared) ? declared : [declared])];
  return keys.map((key) => fieldOf(list, key)).filter(Boolean);
}

// Whether a row's title or second line reads from the entity list.
const rowShowsEntities = (list) => rowFields(list).some((field) => field.type === 'entity');

const takesChoices = (field) => field.type === 'string' && field.choices === 'plugin';

// Whether a list or a list inside it has a field that takes plugin choices.
const hasChoices = (list) => list.fields.some((field) => takesChoices(field) || (field.type === 'list' && hasChoices(field)));

// A plugin choice by its label once the plugin lists it. [at] is the
// plugin and the list's dotted path.
function choiceText(field, value, at) {
  if (!takesChoices(field) || !at?.plugin) return null;
  return choiceLabel(at.plugin.id, `${at.path}.${field.key}`, String(value ?? ''));
}

// An entity shows its friendly name, or its id until the list has it.
function rowTitle(list, row, at) {
  const entity = titleEntity(list, row);
  if (entity) return entity.item?.name || entity.id;
  const key = rowKey(list, 'title');
  const value = key ? String(row[key] ?? '').trim() : '';
  if (!value) return pluginText('Untitled');
  return choiceText(fieldOf(list, key) || {}, value, at) ?? value;
}

function addTitle(list) { return list.addTitle || t('commonAdd'); }
function maxItems(list) { return list.maxItems || 32; }
// Whether the editor offers Duplicate on a row of [list] holding [count]
// rows. A plugin turns it on per list, and a full list has no room for
// the copy.
function canDuplicate(list, count) { return list.duplicate === true && count < maxItems(list); }

/* ------------------------------------------------------------ sources */

// SVG paths for icon names, asked of the kiosk in one batch and kept.
const paths = new Map();
export async function iconPaths(names) {
  const missing = [...new Set(names.filter((n) => n && !paths.has(n)))];
  if (missing.length) {
    const r = await cmd('searchIcons', { names: missing.slice(0, 100) }).catch(() => null);
    for (const name of missing) paths.set(name, null);
    for (const icon of (r?.ok && Array.isArray(r.data) ? r.data : [])) paths.set(icon.name, icon.path);
  }
  return names.map((n) => paths.get(n) || null);
}

let cameraViews = null;
async function loadCameraViews() {
  const r = await cmd('cameraGetConfig').catch(() => null);
  if (!r?.ok) return null;
  cameraViews = r.data?.views || [];
  const [cctv] = await iconPaths(['mdi:cctv']);
  return {
    items: cameraViews.map((view) => {
      const n = (view.cameraIds || []).length;
      return {
        id: String(view.id), name: view.name || String(view.id),
        sub: t(n === 1 ? 'screensaverMediaOneCamera' : 'screensaverMediaCameras', { count: String(n) }),
        iconPath: cctv, group: '', available: true, raw: view,
      };
    }),
    notes: {},
  };
}

// The kiosk's camera views for camera view settings.
export function cameraViewSpec() {
  return {
    key: 'pluginCameraViews', loader: loadCameraViews,
    searchHint: pluginText('Search camera views'),
    noGroup: '', chips: false, headings: false, byGroupName: false, keep: null,
  };
}

/* ------------------------------------------------------------ icons */

// Searches the kiosk's icons as you type, in the entity picker's frame:
// the title and search box on top, a grid of icons, Clear and Cancel
// below. Under 520 it fills the screen. Resolves to the picked name, ''
// for Clear, null when dismissed.
export function pickIcon({ title, value = '' }) {
  return new Promise((resolve) => {
    const openedAt = Date.now();
    const shell = modalShell({ title: '', width: 760,
      onDismiss: () => { if (Date.now() - openedAt > 500) finish(null); } });
    shell.card.classList.add('dash-picker-card');
    shell.back.classList.add('dash-picker-back');
    shell.body.classList.remove('edge-fade');
    shell.head.remove();
    shell.foot.remove();
    const root = el('div', 'dp ep plugin-icon-picker');
    const head = el('div', 'dp-head');
    const bar = el('div', 'dp-bar');
    const back = iconButton(t('commonBack'), BACK);
    back.classList.add('dp-back');
    back.onclick = () => finish(null);
    const heading = el('div', 'dp-heading');
    heading.appendChild(el('div', 'dp-name modal-title', title));
    bar.append(back, heading);
    const search = el('input', 'dp-search');
    search.type = 'search'; search.autocomplete = 'off';
    search.placeholder = pluginText('Search icons');
    search.setAttribute('aria-label', pluginText('Search icons'));
    head.append(bar, search);
    const content = el('div', 'dp-content');
    const grid = el('div', 'plugin-icon-grid edge-fade');
    content.appendChild(grid);
    const foot = el('div', 'dp-foot');
    if (value) {
      const clear = el('button', 'btn-text', t('commonClear'));
      clear.type = 'button';
      clear.onclick = () => finish('');
      foot.appendChild(clear);
    }
    foot.appendChild(el('span', 'dp-count'));
    const cancel = el('button', 'btn-text', t('commonCancel'));
    cancel.type = 'button';
    cancel.onclick = () => finish(null);
    foot.appendChild(cancel);
    root.append(head, content, foot);
    shell.body.appendChild(root);
    const observer = new ResizeObserver(() => {
      const narrow = root.clientWidth < 520;
      root.classList.toggle('narrow', narrow);
      back.hidden = !narrow;
    });
    observer.observe(root);
    function finish(result) {
      observer.disconnect();
      shell.close();
      resolve(result);
    }
    let asked = 0;
    const show = async () => {
      const mine = ++asked;
      const r = await cmd('searchIcons', { query: search.value, limit: 120 }).catch(() => null);
      if (mine !== asked) return;
      let icons = r?.ok && Array.isArray(r.data) ? r.data : [];
      // The current icon leads while nothing is typed, even when it is
      // not among the first ones.
      if (value && !search.value.trim() && !icons.some((icon) => icon.name === value)) {
        const [path] = await iconPaths([value]);
        if (mine !== asked) return;
        if (path) icons = [{ name: value, path }, ...icons.slice(0, 119)];
      }
      grid.replaceChildren();
      if (!icons.length) {
        const empty = el('div', 'dp-state');
        empty.appendChild(el('div', 'dp-state-title', haText('Nothing matches')));
        grid.appendChild(empty);
      }
      for (const icon of icons) {
        paths.set(icon.name, icon.path);
        const cell = el('button', 'plugin-icon-cell');
        cell.type = 'button'; cell.title = icon.name;
        cell.classList.toggle('picked', icon.name === value);
        cell.append(svgPath(icon.path, 28), el('span', '', icon.name.slice(4)));
        cell.onclick = () => finish(icon.name);
        grid.appendChild(cell);
      }
      grid.scrollTop = 0;
    };
    let timer = 0;
    search.oninput = () => { clearTimeout(timer); timer = setTimeout(show, 200); };
    show();
    search.focus();
  });
}

// An icon at rest in the field box: the glyph and its name.
// An action setting's control: what the chosen action does, opening the
// Gestures action chooser, with Clear when the action is optional.
export function actionField({ value = {}, required = false, onPick }) {
  const wrap = el('div', 'plugin-dashboard-field');
  const box = el('button', 'dp-field');
  box.type = 'button';
  let current = actionChosen(value) ? value : {};
  const clear = iconButton(t('commonClear'), 'M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z');
  const paint = () => {
    const lead = el('span', 'dp-field-icon');
    lead.appendChild(svgPath('M8,5.14V19.14L19,12.14L8,5.14Z', 20));
    const text = el('span', 'dp-field-text');
    if (actionChosen(current)) {
      lead.classList.add('primary');
      text.textContent = describeGestureAction(current);
    } else {
      text.classList.add('placeholder');
      text.textContent = gestureText('Choose an action');
    }
    box.replaceChildren(lead, text, svgPath(CHEVRON, 20));
    clear.hidden = required || !actionChosen(current);
  };
  box.onclick = async () => {
    const picked = await pickGestureAction(actionChosen(current) ? current : null);
    if (!picked) return;
    current = picked;
    paint();
    onPick(picked);
  };
  clear.onclick = () => { current = {}; paint(); onPick({}); };
  paint();
  // Plugin actions show the plugin's current names once they load.
  loadPluginActionNames().then(paint);
  wrap.append(box, clear);
  return { el: wrap };
}

export function iconField({ value = '', title, onPick }) {
  const box = el('button', 'dp-field');
  box.type = 'button';
  let current = value;
  const paint = async () => {
    const lead = el('span', 'dp-field-icon');
    const text = el('span', 'dp-field-text');
    const chev = el('span', 'dp-field-chev');
    chev.appendChild(svgPath(CHEVRON, 20));
    if (!current) {
      lead.appendChild(svgPath(PLACEHOLDER, 20));
      text.classList.add('placeholder');
      text.textContent = pluginText('Choose an icon');
    } else {
      const [path] = await iconPaths([current]);
      lead.appendChild(svgPath(path || PLACEHOLDER, 20));
      lead.classList.add('primary');
      text.appendChild(el('span', 'dp-mono', current));
    }
    box.replaceChildren(lead, text, chev);
  };
  box.onclick = async () => {
    const picked = await pickIcon({ title, value: current });
    if (picked == null || picked === current) return;
    current = picked;
    paint();
    onPick(picked);
  };
  paint();
  return { el: box };
}

/* ------------------------------------------------------------ rows */

function displayValue(field, value, at) {
  switch (field.type) {
    case 'string': {
      const label = choiceText(field, value, at);
      if (label) return label;
      break;
    }
    case 'boolean': case 'list': case 'color': return null;
    case 'number': return `${value} ${field.unit || ''}`.trim();
    case 'entity': {
      const item = findEntity(String(value ?? ''));
      if (item) return [item.name, item.state].filter(Boolean).join(' · ');
      break;
    }
    case 'cameraView': {
      const view = (cameraViews || []).find((v) => v.id === value);
      if (view) return view.name;
      break;
    }
    case 'action': return actionChosen(value) ? describeGestureAction(value) : null;
  }
  const text = String(value ?? '').trim();
  return text || null;
}

function rowSubtitle(list, row, at) {
  const declared = list.row?.subtitle;
  const keys = Array.isArray(declared) ? declared : declared ? [declared] : [];
  for (const key of keys) {
    const field = list.fields.find((f) => f.key === key);
    if (!field || !fieldVisible(field, row, list.fields)) continue;
    const text = displayValue(field, row[key], at);
    if (text) return text;
  }
  // Without one, an entity title adds its state and id, the way the At a
  // Glance rows do.
  // An entity the list lacks already shows its id as the title.
  const item = titleEntity(list, row)?.item;
  if (!item) return '';
  return item.state ? `${item.state} · ${item.id}` : item.id;
}

function iconButton(label, d) {
  const button = el('button', 'icon-btn'); button.type = 'button';
  button.title = label; button.setAttribute('aria-label', label);
  button.appendChild(svgPath(d, 20));
  return button;
}

// The rows of a list and the row that adds one. A row drags onto another
// to take its place; a touch screen has no drag, so the arrows move it a
// step at a time. onOpen gets the row's index, or null to add one. [plugin]
// lists the choices, and [path] is the list's dotted path.
function listRows({ list, rows, onOpen, onReorder, plugin = null, path = list.key }) {
  const at = { plugin, path };
  const choiceFields = plugin ? rowFields(list).filter(takesChoices) : [];
  const box = el('div', 'plugin-list-rows');
  const max = maxItems(list);
  const iconKey = list.row?.icon || null;
  const titleIsEntity = fieldOf(list, rowKey(list, 'title'))?.type === 'entity';
  const entities = rowShowsEntities(list);
  let dragFrom = null;
  rows.forEach((row, index) => {
    const item = el('div', 'row camera-list-row plugin-list-row');
    item.tabIndex = 0; item.setAttribute('role', 'button');
    const main = el('div', 'camera-row-main');
    const icon = el('span', 'camera-row-icon');
    const info = el('div', 'info');
    // A picked icon wins. Without one, an entity title brings its own,
    // or a warning when Home Assistant no longer has it.
    const paint = () => {
      const entity = titleEntity(list, row);
      if (!(iconKey && row[iconKey]) && titleIsEntity) {
        const gone = !!entity && !entity.item && !!cachedList('entities');
        icon.classList.toggle('plugin-row-missing', gone);
        icon.replaceChildren(svgPath(gone ? ENTITY_ICONS.warn : (entity?.item?.iconPath || ENTITY_ICONS.generic), 24));
      }
      info.replaceChildren(el('div', 'name', rowTitle(list, row, at)));
      const subtitle = rowSubtitle(list, row, at);
      if (subtitle) info.append(el('div', 'desc', subtitle));
    };
    if (iconKey && row[iconKey]) {
      icon.appendChild(svgPath(PLACEHOLDER, 24));
      iconPaths([row[iconKey]]).then(([d]) => { if (d) icon.replaceChildren(svgPath(d, 24)); });
    } else if (iconKey && !titleIsEntity) {
      icon.appendChild(svgPath(PLACEHOLDER, 24));
    }
    paint();
    // Entity names and states come from the shared list, so the row
    // redraws once it loads.
    if (entities) onListLoaded('entities', item, paint);
    // Choice labels come from the plugin, so the row redraws as they do.
    for (const field of choiceFields) onListLoaded(choiceSpec(plugin.id, `${path}.${field.key}`).key, item, paint);
    // A plugin action shows the plugin's current names once they load.
    if (rowFields(list).some((field) => field.type === 'action')) loadPluginActionNames().then(() => { if (item.isConnected) paint(); });
    if (iconKey || titleIsEntity) main.appendChild(icon);
    main.appendChild(info);
    const actions = el('div', 'camera-row-actions');
    actions.addEventListener('click', (event) => event.stopPropagation());
    if (rows.length > 1) {
      const up = iconButton(t('commonMoveUp'), 'M13,20H11V8L5.5,13.5L4.08,12.08L12,4.16L19.92,12.08L18.5,13.5L13,8V20Z');
      up.disabled = index === 0; up.onclick = () => onReorder(index, index - 1);
      const down = iconButton(t('commonMoveDown'), 'M11,4H13V16L18.5,10.5L19.92,11.92L12,19.84L4.08,11.92L5.5,10.5L11,16V4Z');
      down.disabled = index === rows.length - 1; down.onclick = () => onReorder(index, index + 1);
      actions.append(up, down);
      item.draggable = true;
      const handle = el('span', 'camera-row-icon plugin-drag');
      handle.innerHTML = cameraIcon('drag');
      handle.title = pluginText('Drag to reorder');
      actions.appendChild(handle);
      item.addEventListener('dragstart', (event) => {
        dragFrom = index; item.classList.add('dragging');
        event.dataTransfer.effectAllowed = 'move';
        // Firefox refuses to start a drag without payload.
        event.dataTransfer.setData('text/plain', String(index));
      });
      item.addEventListener('dragend', () => { dragFrom = null; item.classList.remove('dragging'); });
      item.addEventListener('dragover', (event) => {
        if (dragFrom === null || dragFrom === index) return;
        event.preventDefault(); event.dataTransfer.dropEffect = 'move';
      });
      item.addEventListener('drop', (event) => {
        if (dragFrom === null || dragFrom === index) return;
        event.preventDefault();
        const from = dragFrom; dragFrom = null;
        onReorder(from, index);
      });
    }
    item.append(main, actions);
    item.onclick = () => onOpen(index);
    item.onkeydown = (event) => {
      if (event.target === item && (event.key === 'Enter' || event.key === ' ')) { event.preventDefault(); onOpen(index); }
    };
    box.appendChild(item);
  });
  if (rows.length < max) {
    const add = el('div', 'row plugin-add-row plugin-list-add');
    const info = el('div', 'info'); info.append(el('div', 'name', addTitle(list)));
    const plus = iconButton(addTitle(list), 'M19,13H13V19H11V13H5V11H11V5H13V11H19V13Z');
    plus.onclick = (event) => { event.stopPropagation(); onOpen(null); };
    add.onclick = () => onOpen(null);
    add.append(info, plus);
    box.appendChild(add);
  }
  if (entities && !cachedList('entities')) loadEntityList();
  if (choiceFields.length) watchPluginSetup(plugin.id);
  return box;
}

const move = (rows, from, to) => { const next = [...rows]; next.splice(to, 0, next.splice(from, 1)[0]); return next; };

// A list setting on the plugin's page: the rows inline, each opening the
// row editor. Every completed edit, delete and move saves the whole list.
export function listSetting({ setting, rows, showTitle, onChange, plugin = null }) {
  const block = el('div', 'plugin-list');
  // The page keeps reading the plugin's choices while a list takes them.
  if (plugin && hasChoices(setting)) block.dataset.pluginChoices = 'true';
  if (showTitle) {
    const head = el('div', 'row');
    const info = el('div', 'info'); info.append(el('div', 'name', setting.title));
    if (setting.description) info.append(el('div', 'desc', setting.description));
    head.appendChild(info); block.appendChild(head);
  }
  block.appendChild(listRows({
    list: setting, rows, plugin,
    onOpen: async (index) => {
      const result = await editRow({ list: setting, row: index == null ? null : rows[index], plugin,
        duplicate: canDuplicate(setting, rows.length) });
      if (!result) return;
      const next = [...rows];
      if (result.row == null) next.splice(index, 1);
      else if (index == null || result.copied) next.push(result.row);
      else next[index] = result.row;
      onChange(next);
    },
    onReorder: (from, to) => onChange(move(rows, from, to)),
  }));
  // Alone in its group the list goes without a title, so its description
  // closes the card as a hint, the way the device's HintRow shows it.
  if (!showTitle && setting.description) block.appendChild(hintRow(setting.description, { className: 'divided plugin-list-note' }));
  return block;
}

/* ------------------------------------------------------------ editor */

// Edits one row of [list] in a modal, a new one when [row] is null.
// Resolves to { row } on Save, { row: null } on Delete, null on Cancel.
// A nested row opens in the same modal, so there is one editing surface.
// [plugin] lists the choices of fields that take them. [duplicate] offers
// Duplicate on an existing row, which turns the editor into a new row
// holding a copy of what it shows, resolved as { row, copied: true }.
export function editRow({ list, row, plugin = null, duplicate = false }) {
  return new Promise((resolve) => {
    const shell = modalShell({ title: '', width: 600 });
    const draft = filledRow(list, row);
    let entry = null;
    // Duplicate turned the outer row into a new one. The draft keeps what
    // was on screen and Save adds it, leaving the saved row as it was.
    let copied = false;
    // Text typed into number fields that they do not take, per row being
    // edited. The row keeps its last valid number and Save waits while a
    // shown field holds such text.
    const typed = new WeakMap();
    const finish = (result) => { shell.close(); resolve(result); };

    const render = () => {
      const level = entry ? entry.list : list;
      const values = entry ? entry.draft : draft;
      const isNew = entry ? entry.index == null : row == null || copied;
      shell.head.replaceChildren();
      if (entry) {
        const back = iconButton(t('commonBack'), BACK);
        back.classList.add('plugin-editor-back');
        back.onclick = () => { entry = null; render(); };
        shell.head.append(back);
      }
      const path = entry ? `${list.key}.${entry.list.key}` : list.key;
      shell.head.append(entry ? entry.title : (isNew ? addTitle(list) : rowTitle(list, row, { plugin, path })));
      const form = el('div', 'modal-form plugin-editor');
      const save = el('button', 'btn-primary', entry ? pluginText('Done') : t('commonSave'));
      if (!typed.has(values)) typed.set(values, {});
      const pending = typed.get(values);
      const refresh = () => {
        save.disabled = !rowComplete(level.fields, values)
          || level.fields.some((f) => f.key in pending && fieldVisible(f, values, level.fields));
      };
      const rerender = () => render();
      for (const field of level.fields) {
        if (!fieldVisible(field, values, level.fields)) continue;
        form.appendChild(fieldControl(field, values, level.fields, { refresh, rerender, openEntry, plugin, path, pending }));
      }
      shell.body.replaceChildren(form);
      shell.foot.replaceChildren();
      let copy = null;
      if (!isNew) {
        const remove = el('button', 'btn-text danger', t('commonDelete'));
        remove.onclick = () => {
          if (!entry) { finish({ row: null }); return; }
          draft[entry.list.key].splice(entry.index, 1);
          entry = null; render();
        };
        shell.foot.append(remove);
        if (entry ? canDuplicate(entry.list, draft[entry.list.key].length) : duplicate) {
          copy = el('button', 'btn-text plugin-duplicate', pluginText('Duplicate'));
          copy.onclick = () => {
            if (entry) entry = { ...entry, index: null, title: addTitle(entry.list) };
            else copied = true;
            render();
          };
          shell.foot.append(copy);
        }
      }
      const cancel = el('button', 'btn-text', t('commonCancel'));
      cancel.onclick = () => { if (entry) { entry = null; render(); } else finish(null); };
      save.onclick = () => {
        if (!entry) { finish(copied ? { row: draft, copied } : { row: draft }); return; }
        const rows = draft[entry.list.key];
        if (entry.index == null) rows.push(entry.draft); else rows[entry.index] = entry.draft;
        entry = null; render();
      };
      // Beside Duplicate, Cancel and Save wrap as a pair on a phone.
      if (copy) {
        const end = el('div', 'plugin-foot-end');
        end.append(cancel, save);
        shell.foot.append(end);
      } else {
        shell.foot.append(cancel, save);
      }
      refresh();
    };

    const openEntry = (field, index) => {
      const current = index == null ? null : draft[field.key][index];
      entry = { list: field, index, draft: filledRow(field, current),
        title: current ? rowTitle(field, current, { plugin, path: `${list.key}.${field.key}` }) : addTitle(field) };
      render();
    };
    render();
  });
}

// One field in the editor, the device's _Labeled layout: the label above
// with Required beside an empty required field, the description beneath.
function fieldControl(field, values, fields, { refresh, rerender, openEntry, plugin, path, pending }) {
  const wrap = el('div', 'form-field');
  const label = el('span', 'desc', field.title);
  const required = el('span', 'plugin-required', ` · ${pluginText('Required')}`);
  label.appendChild(required);
  const paintRequired = () => { required.hidden = !fieldMissing(field, values, fields); };
  // Fields others depend on redraw the form, so dependents show or hide.
  const depended = fields.some((f) => f.visibleWhen?.key === field.key);
  // A text box or slider redraws once it is done, never mid-typing.
  const set = (value, { settled = true } = {}) => {
    values[field.key] = value;
    paintRequired();
    if (depended && settled) rerender(); else refresh();
  };
  const value = values[field.key];
  let control;
  // The same picker and Refresh as a choices setting, with the warning and
  // the refresh's progress below. A list row has nothing to save first.
  if (takesChoices(field) && plugin) {
    const choice = choiceControl(plugin, { key: `${path}.${field.key}`, title: field.title, emptyText: field.emptyText }, value ?? '',
      async () => {}, async (picked) => set(picked));
    const body = el('div', 'plugin-choice-field');
    body.append(choice.control, ...choice.lines);
    choice.attach(body);
    wrap.append(label, body);
    if (field.description) wrap.append(el('span', 'desc plugin-field-note', field.description));
    paintRequired();
    return wrap;
  }
  switch (field.type) {
    case 'boolean': {
      const row = el('div', 'row');
      const info = el('div', 'info'); info.append(el('div', 'name', field.title));
      if (field.description) info.append(el('div', 'desc', field.description));
      const toggle = el('label', 'switch');
      const input = el('input'); input.type = 'checkbox'; input.checked = value === true;
      input.setAttribute('aria-label', field.title);
      input.onchange = () => set(input.checked);
      toggle.append(input, el('span', 'slider'));
      row.append(info, toggle);
      return row;
    }
    case 'number': {
      if (field.input === 'field') {
        const number = numberControl(field, field.key in pending ? pending[field.key] : String(value), (text) => {
          if (numberError(field, text)) { pending[field.key] = text; refresh(); return; }
          delete pending[field.key];
          set(Number(text), { settled: false });
        });
        number.input.onchange = () => { if (!(field.key in pending)) set(values[field.key]); };
        wrap.append(label, number.control, number.error);
        if (field.description) wrap.append(el('span', 'desc plugin-field-note', field.description));
        paintRequired();
        return wrap;
      }
      control = el('div', 'plugin-range');
      const input = el('input'); input.type = 'range';
      input.min = field.min; input.max = field.max; input.step = field.step || 1; input.value = value;
      input.setAttribute('aria-label', field.title);
      const output = el('span', 'desc', `${value} ${field.unit || ''}`.trim());
      input.oninput = () => { output.textContent = `${input.value} ${field.unit || ''}`.trim(); set(Number(input.value), { settled: false }); };
      input.onchange = () => set(Number(input.value));
      control.append(input, output);
      break;
    }
    case 'select': {
      control = el('select', 'field');
      control.setAttribute('aria-label', field.title);
      for (const choice of field.options) { const option = el('option', '', choice); option.value = choice; control.append(option); }
      control.value = value;
      control.onchange = () => set(control.value);
      break;
    }
    case 'color': {
      const rgb = [1, 3, 5].map((i) => parseInt(value.slice(i, i + 2), 16)).join(',');
      control = swatch(rgb, field.title, (picked) => {
        set('#' + picked.split(',').map((c) => Number(c).toString(16).padStart(2, '0')).join('').toUpperCase());
      });
      break;
    }
    case 'entity': case 'cameraView': {
      const domains = Array.isArray(field.domain) ? field.domain.map(String) : (field.domain ? [String(field.domain)] : []);
      const spec = field.type === 'entity'
        ? entitySpec({ domains, includeHidden: field.includeHidden === true }) : cameraViewSpec();
      const picker = pickField({
        spec, value,
        placeholder: field.type === 'cameraView' ? pluginText('Choose a camera view') : null,
        onClick: async () => {
          const out = await pickItem({ title: field.title, spec, selected: values[field.key] || null, allowClear: true });
          if (!out) return;
          picker.setValue(out.id ?? '');
          set(out.id ?? '');
        },
      });
      control = picker.el;
      break;
    }
    case 'dashboard': {
      control = el('div', 'plugin-dashboard-field');
      const picker = dashboardField({ value, title: field.title, onPick: (path) => { set(path); paintClear(); } });
      // The dashboard picker has no Clear of its own.
      const clear = iconButton(t('commonClear'), 'M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z');
      const paintClear = () => { clear.hidden = field.required === true || !values[field.key]; };
      clear.onclick = () => { picker.setValue(''); set(''); paintClear(); };
      paintClear();
      control.append(picker.el, clear);
      break;
    }
    case 'icon':
      control = iconField({ value, title: field.title, onPick: set }).el;
      break;
    case 'action':
      control = actionField({ value, required: field.required === true, onPick: set }).el;
      break;
    case 'list': {
      control = el('div', 'plugin-list-box');
      control.appendChild(listRows({
        list: field, rows: value, plugin, path: `${path}.${field.key}`,
        onOpen: (index) => openEntry(field, index),
        onReorder: (from, to) => { values[field.key] = move(value, from, to); rerender(); },
      }));
      break;
    }
    default: {
      control = el('input', 'field');
      control.type = 'text'; control.maxLength = 512; control.value = value ?? '';
      control.setAttribute('aria-label', field.title);
      control.oninput = () => set(control.value, { settled: false });
      control.onchange = () => set(control.value);
    }
  }
  wrap.append(label, control);
  if (field.description) wrap.append(el('span', 'desc plugin-field-note', field.description));
  paintRequired();
  return wrap;
}
