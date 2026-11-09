import { gestureText, haText, launcherText, mediaError, mediaText, screensaverText, t } from './localization.js';
import { cmd } from './core.js';
import { centerInRow, dragScroll, modalShell, queueEdgeFades } from './widgets.js';

/* The entity picker, the device's ItemPicker in the browser: a source's
   rows (Home Assistant's entities, one source's media players) grouped
   under their headings, a search and chips on top, Cancel and Clear
   below. Under 520 it fills the screen. Entity icons arrive from the
   device as SVG path data (icon_path); players draw a speaker. */

const SVG = 'http://www.w3.org/2000/svg';
const ICONS = {
  generic: 'M11,13.5V21.5H3V13.5H11M9,15.5H5V19.5H9V15.5M12,2L17.5,11H6.5L12,2M12,5.86L10.08,9H13.92L12,5.86M17.5,13C20,13 22,15 22,17.5C22,20 20,22 17.5,22C15,22 13,20 13,17.5C13,15 15,13 17.5,13M17.5,15A2.5,2.5 0 0,0 15,17.5A2.5,2.5 0 0,0 17.5,20A2.5,2.5 0 0,0 20,17.5A2.5,2.5 0 0,0 17.5,15Z',
  speaker: 'M12,12A3,3 0 0,0 9,15A3,3 0 0,0 12,18A3,3 0 0,0 15,15A3,3 0 0,0 12,12M12,20A5,5 0 0,1 7,15A5,5 0 0,1 12,10A5,5 0 0,1 17,15A5,5 0 0,1 12,20M12,4A2,2 0 0,1 14,6A2,2 0 0,1 12,8C10.89,8 10,7.1 10,6C10,4.89 10.89,4 12,4M17,2H7C5.89,2 5,2.89 5,4V20A2,2 0 0,0 7,22H17A2,2 0 0,0 19,20V4C19,2.89 18.1,2 17,2Z',
  speakers: 'M14,10A3,3 0 0,0 11,13A3,3 0 0,0 14,16A3,3 0 0,0 17,13A3,3 0 0,0 14,10M14,18A5,5 0 0,1 9,13A5,5 0 0,1 14,8A5,5 0 0,1 19,13A5,5 0 0,1 14,18M14,2A2,2 0 0,1 16,4A2,2 0 0,1 14,6A2,2 0 0,1 12,4A2,2 0 0,1 14,2M19,0H9A2,2 0 0,0 7,2V18A2,2 0 0,0 9,20H19A2,2 0 0,0 21,18V2A2,2 0 0,0 19,0M5,22H17V24H5A2,2 0 0,1 3,22V4H5',
  session: 'M19.1,8.7C20.9,10.5 20.9,13.3 19.1,15.2L20.1,16.2C22.6,13.9 22.6,10.1 20.1,7.7L19.1,8.7M18,9.8L17,10.8C17.5,11.5 17.5,12.4 17,13.1L18,14.1C19.2,12.9 19.2,11.1 18,9.8M14,1H4A2,2 0 0,0 2,3V21A2,2 0 0,0 4,23H14A2,2 0 0,0 16,21V3A2,2 0 0,0 14,1M14,20H4V4H14V20Z',
  warn: 'M13,14H11V10H13M13,18H11V16H13M1,21H23L12,2L1,21Z',
  app: 'M21 2H3C1.9 2 1 2.9 1 4V20C1 21.1 1.9 22 3 22H21C22.1 22 23 21.1 23 20V4C23 2.9 22.1 2 21 2M21 20H3V6H21V20Z',
  chevron: 'M7.41,8.58L12,13.17L16.59,8.58L18,10L12,16L6,10L7.41,8.58Z',
  back: 'M20,11V13H8L13.5,18.5L12.08,19.92L4.16,12L12.08,4.08L13.5,5.5L8,11H20Z',
  up: 'M13,20H11V8L5.5,13.5L4.08,12.08L12,4.16L19.92,12.08L18.5,13.5L13,8V20Z',
  down: 'M11,4H13V16L18.5,10.5L19.92,11.92L12,19.84L4.08,11.92L5.5,10.5L11,16V4Z',
  hidden: 'M11.83,9L15,12.16C15,12.11 15,12.05 15,12A3,3 0 0,0 12,9C11.94,9 11.89,9 11.83,9M7.53,9.8L9.08,11.35C9.03,11.56 9,11.77 9,12A3,3 0 0,0 12,15C12.22,15 12.44,14.97 12.65,14.92L14.2,16.47C13.53,16.8 12.79,17 12,17A5,5 0 0,1 7,12C7,11.21 7.2,10.47 7.53,9.8M2,4.27L4.28,6.55L4.73,7C3.08,8.3 1.78,10 1,12C2.73,16.39 7,19.5 12,19.5C13.55,19.5 15.03,19.2 16.38,18.66L16.81,19.08L19.73,22L21,20.73L3.27,3M12,7A5,5 0 0,1 17,12C17,12.64 16.87,13.26 16.64,13.82L19.57,16.75C21.07,15.5 22.27,13.86 23,12C21.27,7.61 17,4.5 12,4.5C10.6,4.5 9.26,4.75 8,5.2L10.17,7.35C10.74,7.13 11.35,7 12,7Z',
  drag: 'M9,3H11V5H9V3M13,3H15V5H13V3M9,7H11V9H9V7M13,7H15V9H13V7M9,11H11V13H9V11M13,11H15V13H13V11M9,15H11V17H9V15M13,15H15V17H13V15M9,19H11V21H9V19M13,19H15V21H13V19Z',
};

/* ------------------------------------------------------------ catalogs */

const lists = new Map();
const pending = new Map();
const listeners = new Map();

export function cachedList(key) { return lists.get(key) || null; }

// Loads [spec]'s list, one load at a time per key. Null when the source
// cannot be reached; the last good list stays cached.
export function loadList(spec) {
  if (!pending.has(spec.key)) {
    pending.set(spec.key, (async () => {
      try {
        const list = await spec.loader();
        if (list) {
          lists.set(spec.key, list);
          (listeners.get(spec.key) || new Set()).forEach((fn) => fn());
        }
        return list;
      } catch (_) {
        return null;
      } finally {
        pending.delete(spec.key);
      }
    })());
  }
  return pending.get(spec.key);
}

// Repaints [node] whenever [key]'s list loads, until it leaves the page.
function follow(key, node, paint) {
  if (!listeners.has(key)) listeners.set(key, new Set());
  let seen = false;
  const fn = () => {
    if (node.isConnected) { seen = true; paint(); } else if (seen) listeners.get(key).delete(fn);
  };
  listeners.get(key).add(fn);
}

const findIn = (list, id) => (list ? list.items.find((i) => i.id === id) || null : null);

/* ------------------------------------------------------------ sources */

// Home Assistant's entities, all of them, filtered here per picker. One
// list serves every entity picker.
// Entities Home Assistant hides stay out unless includeHidden asks for
// them.
export function entitySpec({ domains = [], deviceClass = null, includeHidden = false } = {}) {
  return {
    key: 'entities',
    loader: loadEntities,
    searchHint: haText('Search entities'),
    noGroup: haText('No area'),
    chips: domains.length !== 1,
    headings: true,
    byGroupName: true,
    keep: (item) => (includeHidden || item.raw.hidden !== true)
      && (!domains.length || domains.includes(item.raw.domain))
      && (!deviceClass || matchesDeviceClass(item.raw, deviceClass)),
  };
}

// Mirrors the device's matchesDeviceClass (entity_list.dart): illuminance
// also takes readings in lux, occupancy also takes motion and presence
// binary sensors (issue #973).
const OCCUPANCY_CLASSES = new Set(['occupancy', 'motion', 'presence']);
function matchesDeviceClass(raw, deviceClass) {
  if (deviceClass === 'illuminance') return raw.device_class === 'illuminance' || raw.unit === 'lx';
  if (deviceClass === 'occupancy') return raw.domain === 'binary_sensor' && OCCUPANCY_CLASSES.has(raw.device_class);
  return raw.device_class === deviceClass;
}

export function loadEntityList() { return loadList(entitySpec()); }

async function loadEntities() {
  const r = await cmd('haListEntities', { icons: true }, { timeoutMs: 20000 });
  if (!r?.ok || !Array.isArray(r.data)) return null;
  return {
    items: r.data.map((e) => ({
      id: String(e.entity_id),
      name: e.name || e.entity_id,
      sub: String(e.entity_id),
      subMono: true,
      state: e.state == null ? null : String(e.state),
      iconPath: e.icon_path || null,
      group: e.area || '',
      chip: e.domain_title || null,
      available: true,
      raw: e,
    })),
    notes: {},
  };
}

// Home Assistant's services under their domains' titles, for a gesture
// that calls one. Each row keeps the entity domains the service acts on
// (entity_domains: null for none, empty for any).
export function serviceSpec() {
  return {
    key: 'services',
    loader: loadServices,
    searchHint: gestureText('Search services'),
    noGroup: '', chips: false, headings: true, byGroupName: true, keep: null,
  };
}

async function loadServices() {
  const r = await cmd('haListServices', { icons: true }, { timeoutMs: 20000 });
  if (!r?.ok || !Array.isArray(r.data)) return null;
  const rows = [...r.data].sort((a, b) => String(a.name).localeCompare(String(b.name)));
  return {
    items: rows.map((e) => ({
      id: String(e.id),
      name: e.name || e.id,
      sub: String(e.id),
      subMono: true,
      state: null,
      iconPath: e.icon_path || null,
      group: e.domain_title || e.domain || '',
      chip: null,
      available: true,
      raw: e,
    })),
    notes: {},
  };
}

// The entity domains [serviceId] acts on, from the loaded services: null
// when it takes no entity, empty when it takes any. Before the list loads
// (or for a service it lacks) the service's own domain.
export function serviceEntityDomains(serviceId) {
  if (!serviceId) return null;
  const item = findIn(cachedList('services'), serviceId);
  if (!item) return [serviceId.split('.')[0]];
  return Array.isArray(item.raw.entity_domains) ? item.raw.entity_domains.map(String) : null;
}

// Calls [paint] each time [key]'s list loads, while [node] is on the page.
export function onListLoaded(key, node, paint) { follow(key, node, paint); }

// One source's players ('ma', 'ha', 'sonos') from mediaPlayers. The
// source's note (not reachable, not set up) shows above its rows.
export function playerSpec(source, { speakers = false } = {}) {
  return {
    key: `players:${source}:${speakers}`,
    loader: () => loadPlayers(source, speakers, false),
    searchHint: mediaText('Search players'),
    noGroup: '', chips: false, headings: false, byGroupName: false, keep: null,
    noteText: mediaError,
  };
}

// The players the speaker selection pill can offer: Music Assistant's
// players and every Sonos room, each under its source's name with chips
// to show one source. Sonos is left out while it knows no speakers, and
// one source alone reads as a plain list. The device's speakerPillSpec.
export function speakerPillSpec() {
  return {
    key: 'players:pill',
    loader: loadPillPlayers,
    searchHint: mediaText('Search players'),
    noGroup: '', chips: true, headings: true, byGroupName: false, keep: null,
    noteText: mediaError,
  };
}

async function loadPillPlayers() {
  const [ma, sonos] = await Promise.all([
    loadPlayers('ma', false, false),
    loadPlayers('sonos', false, true),
  ]);
  // Product names, the same in every language.
  const both = sonos.items.length > 0;
  const maGroup = both ? 'Music Assistant' : '';
  const under = (group) => (i) => ({ ...i, group, chip: group || null });
  // Sonos says when it knows no speakers, which is no news to anyone
  // without them, so only Music Assistant's note stays.
  const maNote = ma.notes.ma;
  return {
    items: [...ma.items.map(under(maGroup)), ...sonos.items.map(under('Sonos'))],
    notes: maNote ? { [maGroup]: maNote } : {},
  };
}

// The device's launchable apps from installedApps, alphabetical, for the
// app launcher's picks (issue #1067). The caller lists them first, so a
// failure can say why.
export function appSpec(apps) {
  return {
    key: 'apps',
    loader: async () => ({
      items: apps.map((a) => ({
        id: String(a.package),
        name: String(a.label),
        sub: String(a.package),
        subMono: true,
        iconPath: ICONS.app,
        group: '',
        available: true,
        raw: a,
      })),
      notes: {},
    }),
    searchHint: launcherText('Search apps'),
    noGroup: '', chips: false, headings: false, byGroupName: false, keep: null,
  };
}

// A fixed list of players: this device's own.
export function fixedPlayerSpec(key, items) {
  return {
    key,
    loader: async () => ({ items, notes: {} }),
    searchHint: mediaText('Search players'),
    noGroup: '', chips: false, headings: false, byGroupName: false, keep: null,
  };
}

// AirPlay wears its audio mark (mdi cast-audio-variant): a triangle under
// sound waves, not the screen of the video one.
const AIRPLAY_ICON = 'M14.5 12C14.5 10.62 13.38 9.5 12 9.5C10.62 9.5 9.5 10.62 9.5 12C9.5 13 10.09 13.84 10.93 14.25L9.82 15.35C8.73 14.64 8 13.41 8 12C8 9.79 9.79 8 12 8C14.21 8 16 9.79 16 12C16 13.41 15.27 14.64 14.18 15.35L13.08 14.25C13.92 13.84 14.5 13 14.5 12M12 2C6.5 2 2 6.5 2 12C2 15.06 3.38 17.8 5.54 19.63L6.61 18.57C4.71 17 3.5 14.64 3.5 12C3.5 7.31 7.31 3.5 12 3.5C16.69 3.5 20.5 7.31 20.5 12C20.5 14.64 19.29 17 17.39 18.57L18.46 19.63C20.62 17.79 22 15.06 22 12C22 6.5 17.5 2 12 2M19 12C19 8.13 15.87 5 12 5C8.13 5 5 8.13 5 12C5 14.23 6.05 16.22 7.68 17.5L8.75 16.43C7.39 15.42 6.5 13.82 6.5 12C6.5 8.97 8.97 6.5 12 6.5C15.03 6.5 17.5 8.97 17.5 12C17.5 13.82 16.61 15.42 15.25 16.43L16.33 17.5C17.95 16.22 19 14.23 19 12M6 22H18L12 16L6 22Z';
export const ENTITY_ICONS = { generic: ICONS.generic, warn: ICONS.warn };
// A puzzle piece (mdi puzzle-outline): a player a plugin publishes.
const PLUGIN_ICON = 'M22,13.5C22,15.26 20.7,16.72 19,16.96V20A2,2 0 0,1 17,22H13.2V21.7A2.7,2.7 0 0,0 10.5,19C9,19 7.8,20.21 7.8,21.7V22H4A2,2 0 0,1 2,20V16.2H2.3C3.79,16.2 5,15 5,13.5C5,12 3.79,10.8 2.3,10.8H2V7A2,2 0 0,1 4,5H7.04C7.28,3.3 8.74,2 10.5,2C12.26,2 13.72,3.3 13.96,5H17A2,2 0 0,1 19,7V10.04C20.7,10.28 22,11.74 22,13.5M17,15H18.5A1.5,1.5 0 0,0 20,13.5A1.5,1.5 0 0,0 18.5,12H17V7H12V5.5A1.5,1.5 0 0,0 10.5,4A1.5,1.5 0 0,0 9,5.5V7H4V9.12C5.76,9.8 7,11.5 7,13.5C7,15.5 5.75,17.2 4,17.88V20H6.12C6.8,18.25 8.5,17 10.5,17C12.5,17 14.2,18.25 14.88,20H17V15Z';
export const PLAYER_ICONS = { speaker: ICONS.speaker, session: ICONS.session, airplay: AIRPLAY_ICON, plugin: PLUGIN_ICON };

// rooms lists every Sonos room on its own, as the speaker selection pill
// does.
async function loadPlayers(source, speakers, rooms) {
  const r = await cmd('mediaPlayers', { source, ...(speakers ? { speakers: true } : {}),
    ...(rooms ? { rooms: true } : {}) }, { timeoutMs: 15000 });
  if (!r?.ok) return { items: [], notes: { [source]: r?.error || '' } };
  const players = Array.isArray(r.data?.players) ? r.data.players : [];
  const notes = r.data?.notes || {};
  const items = players.filter((p) => p.group === source).map((p) => {
    const id = String(p.id);
    const ha = id.startsWith('ha:');
    const available = p.available !== false;
    return {
      id,
      name: p.name || id,
      sub: p.sub != null ? String(p.sub) : (ha ? id.slice(3) : null),
      subMono: p.sub == null && ha,
      // Offline is drawn, not stored: the list outlives a language switch.
      state: null,
      iconPath: String(p.sub || '').includes(',') ? ICONS.speakers : ICONS.speaker,
      group: source,
      available,
      raw: p,
    };
  });
  return { items, notes: notes[source] != null ? { [source]: String(notes[source]) } : {} };
}

/* ------------------------------------------------------------ pieces */

function el(tag, cls, text) {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  if (text != null) e.textContent = text;
  return e;
}

function svgPath(d, size) {
  const svg = document.createElementNS(SVG, 'svg');
  svg.setAttribute('viewBox', '0 0 24 24');
  svg.setAttribute('width', size);
  svg.setAttribute('height', size);
  svg.setAttribute('aria-hidden', 'true');
  const p = document.createElementNS(SVG, 'path');
  p.setAttribute('fill', 'currentColor');
  p.setAttribute('d', d);
  svg.appendChild(p);
  return svg;
}

function disc(item, cls = 'ep-disc') {
  const d = el('span', cls);
  d.appendChild(svgPath(item?.iconPath || ICONS.generic, 22));
  return d;
}

function highlighted(text, query, cls) {
  const span = el('span', cls);
  const i = query ? text.toLowerCase().indexOf(query.toLowerCase()) : -1;
  if (i < 0) { span.textContent = text; return span; }
  span.append(text.slice(0, i), el('mark', 'dp-mark', text.slice(i, i + query.length)),
    text.slice(i + query.length));
  return span;
}

// What shows on the right: the state, or Offline for a player that is.
function itemState(item) {
  return item.state || (item.available === false ? mediaText('Offline') : null);
}

function itemRow(item, { picked, multiple, disabled, query, onClick }) {
  const b = el('button', 'dp-row ep-row' + (picked ? ' picked' : '') + (disabled || !item.available ? ' dim' : ''));
  b.type = 'button';
  if (disabled) b.disabled = true;
  if (multiple) {
    const cb = el('input');
    cb.type = 'checkbox';
    cb.checked = picked;
    cb.tabIndex = -1;
    b.appendChild(cb);
  }
  b.appendChild(disc(item));
  const text = el('span', 'dp-text');
  const title = highlighted(item.name, query, 'dp-title');
  // An entity Home Assistant hides, marked the way Home Assistant marks it.
  if (item.raw?.hidden === true) {
    const line = el('span', 'ep-title-line');
    const mark = el('span', 'ep-hidden');
    mark.appendChild(svgPath(ICONS.hidden, 16));
    line.append(title, mark);
    text.appendChild(line);
  } else {
    text.appendChild(title);
  }
  if (item.sub) text.appendChild(highlighted(item.sub, query, item.subMono ? 'dp-mono' : 'dp-sub'));
  b.appendChild(text);
  const state = itemState(item);
  if (state) b.appendChild(el('span', 'ep-state', state));
  if (picked && !multiple) b.appendChild(el('span', 'dp-tick'));
  b.addEventListener('click', onClick);
  return b;
}

function stateMessage(title, message, action) {
  const box = el('div', 'dp-state');
  box.appendChild(el('div', 'dp-state-title', title));
  if (message) box.appendChild(el('div', 'dp-state-text', message));
  if (action) box.appendChild(action);
  return box;
}

/* ------------------------------------------------------------ the picker */

// Rows go into the list a page at a time, more as it scrolls near the end.
// Building thousands of entity rows on every keystroke stalled the search
// (issue #1047).
const PAGE = 100;
const collator = new Intl.Collator();

// Each item's lowercase search text, worked out once per list.
const searchKeys = new WeakMap();
function keysOf(item) {
  let k = searchKeys.get(item);
  if (!k) {
    const sub = (item.sub || '').toLowerCase();
    k = { name: item.name.toLowerCase(), sub, tail: sub.split('.').pop(),
      group: (item.group || '').toLowerCase() };
    searchKeys.set(item, k);
  }
  return k;
}

function buildPicker({ title, spec, selected = [], multiple = false, max = null,
  allowClear = false, onPick, onClear, onDone, onClose }) {
  const st = {
    list: cachedList(spec.key), failed: false, query: '', chip: null,
    picked: [...selected], wide: true, scrolled: false, limit: PAGE,
  };
  const root = el('div', 'dp ep');
  const head = el('div', 'dp-head');
  const bar = el('div', 'dp-bar');
  const back = el('button', 'icon-btn dp-back');
  back.type = 'button';
  back.setAttribute('aria-label', haText('Back'));
  back.appendChild(svgPath(ICONS.back, 22));
  back.addEventListener('click', () => onClose?.());
  const heading = el('div', 'dp-heading');
  heading.appendChild(el('div', 'dp-name modal-title', title));
  bar.append(back, heading);
  const search = el('input', 'dp-search');
  search.type = 'search';
  search.autocomplete = 'off';
  search.placeholder = spec.searchHint;
  search.addEventListener('input', () => {
    const query = search.value.trim();
    if (query === st.query) return;
    st.query = query;
    st.limit = PAGE;
    render();
  });
  head.append(bar, search);
  const chipsRow = el('div', 'ep-chips edge-fade-x');
  dragScroll(chipsRow);
  const content = el('div', 'dp-content');
  const columns = el('div', 'ep-columns');
  const showing = el('div', 'ep-showing');
  columns.append(content, showing);
  const foot = el('div', 'dp-foot');
  root.append(head, chipsRow, columns, foot);

  // The kept items and their chips change only with the list, the rows on
  // show only with the list, the chip or the search.
  let keptMemo = null;
  let rowsMemo = null;
  const kept = () => {
    if (keptMemo?.list !== st.list) {
      const all = st.list?.items || [];
      const items = spec.keep ? all.filter(spec.keep) : all;
      const chips = [...new Set(items.map((i) => i.chip).filter(Boolean))].sort();
      keptMemo = { list: st.list, items, chips };
    }
    return keptMemo;
  };
  const onShow = () => {
    const { items } = kept();
    if (rowsMemo?.items !== items || rowsMemo.chip !== st.chip || rowsMemo.query !== st.query) {
      rowsMemo = { items, chip: st.chip, query: st.query, entries: entries(items) };
    }
    return rowsMemo.entries;
  };
  const full = () => multiple && max != null && st.picked.length >= max;

  function tap(item) {
    if (!multiple) { onPick?.(item.id); return; }
    if (st.picked.includes(item.id)) st.picked = st.picked.filter((p) => p !== item.id);
    else if (!full()) st.picked.push(item.id);
    render();
  }

  function entries(items) {
    let rows = st.chip ? items.filter((i) => i.chip === st.chip) : items;
    const q = st.query.toLowerCase();
    if (q) {
      const hits = [];
      for (const i of rows) {
        const k = keysOf(i);
        if (!k.name.includes(q) && !k.sub.includes(q) && !k.group.includes(q)) continue;
        const rank = k.name.startsWith(q) || k.tail.startsWith(q) ? 0 : k.name.includes(q) ? 1 : 2;
        hits.push([rank, i]);
      }
      hits.sort((a, b) => a[0] - b[0] || collator.compare(a[1].name, b[1].name));
      return hits.map(([, i]) => ({ item: i }));
    }
    const groups = new Map();
    for (const i of rows) {
      if (!groups.has(i.group)) groups.set(i.group, []);
      groups.get(i.group).push(i);
    }
    const notes = st.chip ? {} : (st.list?.notes || {});
    for (const g of Object.keys(notes)) if (!groups.has(g)) groups.set(g, []);
    let order = [...groups.keys()];
    if (spec.byGroupName) {
      order.sort((a, b) => (!a !== !b ? (a ? -1 : 1) : collator.compare(a, b)));
      for (const g of order) groups.get(g).sort((a, b) => collator.compare(a.name, b.name));
    }
    const out = [];
    for (const g of order) {
      // Rows outside every group go without a heading when the source has
      // no name for them.
      if (spec.headings && (order.length > 1 || g) && (g || spec.noGroup)) {
        out.push({ heading: g || spec.noGroup, count: groups.get(g).length });
      }
      if (notes[g] != null) out.push({ note: spec.noteText ? spec.noteText(notes[g]) : notes[g] });
      for (const i of groups.get(g)) out.push({ item: i });
    }
    return out;
  }

  // A picked chip slides to the middle of the row once it is drawn again.
  let centerPicked = false;
  function renderChips(chips) {
    chipsRow.replaceChildren();
    chipsRow.hidden = !spec.chips || chips.length < 2;
    if (chipsRow.hidden) return;
    const chip = (label, value) => {
      const b = el('button', 'ep-chip' + (st.chip === value ? ' active' : ''), label);
      b.type = 'button';
      b.addEventListener('click', () => { st.chip = value; st.limit = PAGE; centerPicked = true; render(); });
      chipsRow.appendChild(b);
    };
    chip(haText('All'), null);
    chips.forEach((c) => chip(c, c));
    const active = chipsRow.querySelector('.ep-chip.active');
    if (centerPicked && active) centerInRow(chipsRow, active);
    centerPicked = false;
  }

  function renderShowing() {
    showing.replaceChildren();
    showing.hidden = !multiple || !st.wide;
    if (showing.hidden) return;
    showing.appendChild(el('div', 'dp-subhead', max == null
      ? t('dashboardPickerSelected', { count: String(st.picked.length) })
      : t('entityPickerShowing', { count: String(st.picked.length), max: String(max) })));
    st.picked.forEach((id, i) => {
      const item = findIn(st.list, id);
      const row = el('div', 'ep-showing-row');
      row.draggable = true;
      row.dataset.index = String(i);
      const grip = el('span', 'ep-grip');
      grip.appendChild(svgPath(ICONS.drag, 18));
      row.appendChild(grip);
      row.appendChild(disc(item, 'ep-disc small'));
      row.appendChild(el('span', 'ep-showing-name', item?.name || id));
      const move = (to) => {
        st.picked.splice(to, 0, st.picked.splice(i, 1)[0]);
        render();
      };
      const arrow = (icon, label, to, off) => {
        const b = el('button', 'icon-btn ep-arrow');
        b.type = 'button';
        b.setAttribute('aria-label', label);
        b.appendChild(svgPath(icon, 18));
        b.disabled = off;
        b.addEventListener('click', () => move(to));
        row.appendChild(b);
      };
      arrow(ICONS.up, screensaverText('Move up'), i - 1, i === 0);
      arrow(ICONS.down, screensaverText('Move down'), i + 1, i === st.picked.length - 1);
      row.addEventListener('dragstart', (e) => { e.dataTransfer.setData('text/plain', String(i)); });
      row.addEventListener('dragover', (e) => e.preventDefault());
      row.addEventListener('drop', (e) => {
        e.preventDefault();
        const from = Number(e.dataTransfer.getData('text/plain'));
        if (Number.isNaN(from) || from === i) return;
        st.picked.splice(i, 0, st.picked.splice(from, 1)[0]);
        render();
      });
      showing.appendChild(row);
    });
    if (st.picked.length > 1) {
      showing.appendChild(el('div', 'ep-hint', haText('Drag or use the arrows to change the order.')));
    }
  }

  function renderFoot() {
    foot.replaceChildren();
    if (allowClear) {
      const clear = el('button', 'btn-text', haText('Clear'));
      clear.type = 'button';
      clear.addEventListener('click', () => onClear?.());
      foot.appendChild(clear);
    }
    const note = el('span', 'dp-count');
    if (multiple) {
      note.textContent = full() ? haText('Remove one to add another.')
        : t('dashboardPickerSelected', { count: String(st.picked.length) });
    }
    foot.appendChild(note);
    const cancel = el('button', 'btn-text', haText('Cancel'));
    cancel.type = 'button';
    cancel.addEventListener('click', () => onClose?.());
    foot.appendChild(cancel);
    if (multiple) {
      const done = el('button', 'btn-primary', haText('Done'));
      done.type = 'button';
      done.addEventListener('click', () => onDone?.([...st.picked]));
      foot.appendChild(done);
    }
  }

  function render() {
    root.classList.toggle('narrow', !st.wide);
    search.hidden = !(st.list && st.list.items.length);
    back.hidden = st.wide;
    renderChips(kept().chips);
    renderShowing();
    renderFoot();
    let node;
    let fresh = false;
    if (!st.list) {
      if (st.failed) {
        const retry = el('button', 'btn-ghost', haText('Try again'));
        retry.type = 'button';
        retry.addEventListener('click', reload);
        node = stateMessage(haText('Could not reach Home Assistant'),
          haText('The entities load once the connection is back.'), retry);
      } else {
        node = el('div', 'dp-skeleton');
        const rows = el('div', 'dp-skel-rows');
        for (let i = 0; i < 6; i++) rows.appendChild(el('div', 'dp-skel-row'));
        node.appendChild(rows);
      }
    } else {
      const before = rowsMemo;
      const list = onShow();
      fresh = !!before && (before.query !== st.query || before.chip !== st.chip);
      if (!list.length) {
        node = stateMessage(!st.list.items.length && spec.emptyText ? spec.emptyText : haText('Nothing matches'));
      } else {
        node = el('div', 'dp-list edge-fade');
        let firstPick = null;
        const lookFor = !st.scrolled && !st.query;
        if (lookFor) {
          const at = list.findIndex((e) => e.item && st.picked.includes(e.item.id));
          if (at >= 0) st.limit = Math.max(st.limit, at + PAGE);
        }
        let shown = 0;
        const fill = () => {
          const to = Math.min(st.limit, list.length);
          for (; shown < to; shown++) {
            const e = list[shown];
            if (e.heading != null) {
              const h = el('div', 'dp-subhead ep-heading');
              h.append(el('span', null, e.heading));
              if (e.count) h.append(el('span', 'ep-count', String(e.count)));
              node.appendChild(h);
            } else if (e.note != null) {
              node.appendChild(el('div', 'dp-note', e.note));
            } else {
              const picked = st.picked.includes(e.item.id);
              const row = itemRow(e.item, {
                picked, multiple, query: st.query,
                disabled: multiple && !picked && full(),
                onClick: () => tap(e.item),
              });
              if (picked && !firstPick) firstPick = row;
              node.appendChild(row);
            }
          }
        };
        fill();
        node.addEventListener('scroll', () => {
          if (shown >= list.length) return;
          if (node.scrollTop + node.clientHeight < node.scrollHeight - 800) return;
          st.limit = shown + PAGE;
          fill();
        }, { passive: true });
        if (firstPick && lookFor) {
          st.scrolled = true;
          requestAnimationFrame(() => firstPick.scrollIntoView({ block: 'center' }));
        }
      }
    }
    const prev = content.querySelector('.dp-list');
    const top = prev ? prev.scrollTop : 0;
    content.replaceChildren(node);
    // A tap keeps the place in the list. A new search or chip starts at the top.
    if (st.scrolled && !fresh && node.classList?.contains('dp-list') && prev) node.scrollTop = top;
    queueEdgeFades();
  }

  async function reload() {
    st.failed = false;
    if (!st.list) render();
    const list = await loadList(spec);
    if (list) st.list = list; else if (!st.list) st.failed = true;
    render();
  }

  const observer = new ResizeObserver(() => {
    const wide = root.clientWidth >= 520;
    if (wide !== st.wide) { st.wide = wide; render(); }
  });
  observer.observe(root);
  render();
  reload();
  return { root, destroy() { observer.disconnect(); } };
}

// One picker at a time: a click while one is open, or opening, gets null.
let pickerOpen = false;

function openPicker(options, resolveWith) {
  if (pickerOpen) return Promise.resolve(null);
  pickerOpen = true;
  return new Promise((resolve) => {
    let picker = null;
    const openedAt = Date.now();
    const shell = modalShell({ title: '', width: 760,
      onDismiss: () => { if (Date.now() - openedAt > 500) finish(null); } });
    const finish = (value) => {
      pickerOpen = false;
      picker?.destroy();
      shell.back.remove();
      resolve(value);
    };
    shell.card.classList.add('dash-picker-card');
    shell.head.remove();
    shell.body.classList.remove('edge-fade');
    shell.back.classList.add('dash-picker-back');
    shell.foot.remove();
    picker = buildPicker({ ...options, ...resolveWith(finish) });
    shell.body.appendChild(picker.root);
  });
}

// A single pick. Resolves to { id } (id null when Clear was pressed), or
// null when dismissed.
export function pickItem({ title, spec, selected = null, allowClear = false }) {
  return openPicker({ title, spec, selected: selected == null ? [] : [selected], allowClear },
    (finish) => ({
      onPick: (id) => finish({ id }),
      onClear: () => finish({ id: null }),
      onClose: () => finish(null),
    }));
}

// Several at once, at most [max], in order. Resolves to the ids, or null.
export function pickItems({ title, spec, selected = [], max = null }) {
  return openPicker({ title, spec, selected, multiple: true, max },
    (finish) => ({ onDone: (ids) => finish(ids), onClose: () => finish(null) }));
}

export function pickEntity({ title, selected = null, domains = [], deviceClass = null, allowClear = false }) {
  return pickItem({ title, spec: entitySpec({ domains, deviceClass }), selected, allowClear });
}

/* ------------------------------------------------------------ the value step */

// What an entity displays: its state or one of its attributes, each with
// its current value. Resolves to the attribute, '' for the state, null.
export function pickEntityValue({ entityId, current = '' }) {
  if (pickerOpen) return Promise.resolve(null);
  pickerOpen = true;
  return new Promise((resolve) => {
    const shell = modalShell({ title: screensaverText('Displayed value'), width: 560,
      onDismiss: () => finish(null) });
    const finish = (value) => { pickerOpen = false; shell.back.remove(); resolve(value); };
    shell.card.classList.add('ep-value-card');
    const item = findIn(cachedList('entities'), entityId);
    const top = el('div', 'dp-row ep-row ep-value-entity');
    top.appendChild(disc(item));
    const text = el('span', 'dp-text');
    text.append(el('span', 'dp-title', item?.name || entityId), el('span', 'dp-mono', entityId));
    top.appendChild(text);
    const list = el('div', 'dp-list');
    shell.body.append(top, list);
    const cancel = el('button', 'btn-text', haText('Cancel'));
    cancel.type = 'button';
    cancel.addEventListener('click', () => finish(null));
    shell.foot.appendChild(cancel);
    const hidden = ['friendly_name', 'icon', 'entity_picture', 'supported_features', 'attribution'];
    const option = (value, label, reading, on) => {
      const b = el('button', 'dp-row ep-row ep-option' + (on ? ' picked' : ''));
      b.type = 'button';
      const r = el('input');
      r.type = 'radio';
      r.checked = on;
      r.tabIndex = -1;
      b.appendChild(r);
      b.appendChild(el('span', 'dp-title ep-option-name', label));
      if (reading != null) b.appendChild(el('span', 'ep-state', reading));
      b.addEventListener('click', () => finish(value));
      return b;
    };
    (async () => {
      let attributes = null;
      try {
        const r = await cmd('haEntityAttributes', { entity_id: entityId });
        if (r?.ok) attributes = r.data || {};
      } catch (_) {}
      if (!attributes) {
        list.appendChild(stateMessage(haText('Could not reach Home Assistant')));
        return;
      }
      const names = Object.keys(attributes).filter((k) => !hidden.includes(k)
        && (attributes[k] === null || typeof attributes[k] !== 'object')).sort();
      const now = current && names.includes(current) ? current : '';
      list.appendChild(option('', screensaverText('State'), item?.state ?? null, now === ''));
      names.forEach((n) => list.appendChild(option(n, n, String(attributes[n]), now === n)));
    })();
  });
}

/* ------------------------------------------------------------ the field */

// A stored pick at rest: the control box with the item's icon, its name
// and its state. Empty reads [placeholder]. A pick the loaded list lacks
// shows its id with an error border. Returns { el, setValue }.
// `emptyIsPick`: the empty value is a pick of its own (this device's
// Sendspin player), drawn with its item's icon and name once the list has it.
export function pickField({ spec, value = '', placeholder = null, detail = null,
  fallbackLabel = null, flagMissing = true, enabled = true, emptyIsPick = false, onClick }) {
  const box = el('button', 'dp-field ep-field');
  box.type = 'button';
  let current = value;
  const paint = () => {
    box.replaceChildren();
    const list = cachedList(spec.key);
    const item = current || emptyIsPick ? findIn(list, current) : null;
    const missing = flagMissing && !!current && !!list && !item;
    box.classList.toggle('missing', missing);
    const lead = el('span', 'dp-field-icon');
    const text = el('span', 'dp-field-text');
    let trailing = null;
    if (!current && !item) {
      lead.appendChild(svgPath(ICONS.generic, 20));
      text.classList.add('placeholder');
      text.textContent = placeholder || haText('Choose an entity');
    } else if (!item && fallbackLabel && !missing) {
      lead.appendChild(svgPath(ICONS.generic, 20));
      text.textContent = fallbackLabel;
    } else if (!item) {
      lead.appendChild(svgPath(missing ? ICONS.warn : ICONS.generic, 20));
      lead.classList.toggle('error', missing);
      text.appendChild(el('span', 'dp-mono', current));
    } else {
      lead.appendChild(svgPath(item.iconPath || ICONS.generic, 20));
      lead.classList.add('primary');
      text.append(item.name);
      if (detail) text.append(el('span', 'dp-sep', ' · '), el('span', 'dp-field-dash', detail));
      else trailing = itemState(item);
    }
    const chev = el('span', 'dp-field-chev');
    chev.appendChild(svgPath(ICONS.chevron, 20));
    box.append(lead, text);
    if (trailing) box.appendChild(el('span', 'ep-field-state', trailing));
    box.appendChild(chev);
    box.dispatchEvent(new CustomEvent('dp-painted', { detail: { missing } }));
  };
  box.addEventListener('click', () => onClick?.());
  box.disabled = !enabled;
  follow(spec.key, box, paint);
  paint();
  if (!cachedList(spec.key)) loadList(spec);
  return { el: box, setValue: (v) => { current = v || ''; paint(); }, repaint: paint,
    setEnabled: (on) => { box.disabled = !on; },
    setPlaceholder: (text) => { placeholder = text; paint(); } };
}

// A settings row whose value is a pick: the name, the field and the
// description, with a line in error color when the stored pick is gone.
// onPick gets the id, null for Clear. Returns { el, setValue }.
export function pickRow({ name, desc = '', spec, value = '', onPick, dialogTitle = null,
  allowClear = false, placeholder = null, fallbackLabel = null, flagMissing = true,
  emptyIsPick = false, missingText = null }) {
  const row = el('div', 'row dp-field-row');
  const info = el('div', 'info');
  const missingEl = el('div', 'desc dp-missing',
    missingText || haText('This entity is gone from Home Assistant. Choose another.'));
  missingEl.hidden = true;
  info.append(el('div', 'name', name), missingEl);
  if (desc) info.appendChild(el('div', 'desc', desc));
  let current = value;
  const field = pickField({
    spec, value, placeholder, fallbackLabel, flagMissing,
    onClick: async () => {
      const out = await pickItem({
        title: dialogTitle || name, spec,
        selected: current || emptyIsPick ? current : null, allowClear,
      });
      if (!out || out.id === current) return;
      current = out.id ?? '';
      field.setValue(current);
      onPick(out.id);
    },
  });
  field.el.addEventListener('dp-painted', (e) => { missingEl.hidden = !e.detail.missing; });
  // Once more now that someone listens: the first paint went unheard.
  field.repaint();
  row.append(info, field.el);
  return { el: row, setValue: (v) => { current = v || ''; field.setValue(current); } };
}

// One stored pick in a list (At a Glance): icon, name, then the displayed
// value and id. The id stands in until the list loads.
export function pickListRow({ specKey = 'entities', value, name = null, detail = null,
  trailing = [], onClick = null }) {
  const row = el('div', 'ep-pick');
  const paint = () => {
    row.replaceChildren();
    const list = cachedList(specKey);
    const item = findIn(list, value);
    const gone = !!list && !item;
    const main = el(onClick ? 'button' : 'div', 'ep-pick-main');
    if (onClick) { main.type = 'button'; main.addEventListener('click', onClick); }
    const d = el('span', 'ep-disc' + (gone ? ' error' : ''));
    d.appendChild(svgPath(gone ? ICONS.warn : (item?.iconPath || ICONS.generic), 22));
    main.appendChild(d);
    const text = el('span', 'dp-text');
    text.appendChild(el('span', 'dp-title', name || item?.name || value));
    const second = detail || item?.state || '';
    const sub = el('span', 'dp-sub');
    if (second) sub.append(second, el('span', 'dp-sep', ' · '));
    sub.appendChild(el('span', 'dp-mono', value));
    text.appendChild(sub);
    main.appendChild(text);
    row.appendChild(main);
    trailing.forEach((t2) => row.appendChild(t2));
  };
  follow(specKey, row, paint);
  paint();
  return row;
}

// A plain choice in the control box: the Displayed value.
export function choiceBox(text, onClick) {
  const box = el('button', 'dp-field ep-field');
  box.type = 'button';
  const label = el('span', 'dp-field-text', text);
  const chev = el('span', 'dp-field-chev');
  chev.appendChild(svgPath(ICONS.chevron, 20));
  box.append(label, chev);
  box.disabled = !onClick;
  if (onClick) box.addEventListener('click', onClick);
  return { el: box, setText: (v) => { label.textContent = v; } };
}
