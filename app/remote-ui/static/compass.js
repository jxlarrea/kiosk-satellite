// Settings > Navigation on the remote admin: the Classic and Compass cards
// and the Compass layout map, mirroring the device's compass_settings.dart.
// The layout is stored in nav.compass_layout (see compass_layout.dart):
// a center view and up to two views on each side, one of each kind.
import { t } from './localization.js';
import { cmd, state, syncOffRows } from './core.js';
import { modalShell } from './widgets.js';
import { dashboardField, loadDashboards, cachedDashboards, matchDashboard } from './dashboard_picker.js';

const KINDS = ['dashboard', 'menu', 'music_library', 'calendar', 'alarms',
  'now_playing', 'camera', 'app_launcher', 'intercom'];
const SIDE_LIMIT = 2;

// Stroke icons in the nav rail's style, one per kind.
const ICONS = {
  menu: '<path d="M4 6h9M17 6h3M4 12h3M11 12h9M4 18h11M19 18h1"/><circle cx="15" cy="6" r="2"/><circle cx="9" cy="12" r="2"/><circle cx="17" cy="18" r="2"/>',
  dashboard: '<path d="M3 11 12 4l9 7M5 10v10h14V10"/>',
  music_library: '<path d="M9 18V5l11-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="17" cy="16" r="3"/>',
  calendar: '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/>',
  alarms: '<circle cx="12" cy="13" r="8"/><path d="M12 9v4l2 2M5 3 2 6M19 3l3 3"/>',
  now_playing: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="3"/>',
  camera: '<path d="M3 7h12v10H3zM15 10l6-3v10l-6-3"/>',
  app_launcher: '<rect x="4" y="4" width="7" height="7" rx="1.5"/><rect x="13" y="4" width="7" height="7" rx="1.5"/><rect x="4" y="13" width="7" height="7" rx="1.5"/><rect x="13" y="13" width="7" height="7" rx="1.5"/>',
  intercom: '<rect x="6" y="3" width="12" height="18" rx="2"/><circle cx="12" cy="14" r="3"/><path d="M10 7h4"/>',
  add: '<path d="M12 5v14M5 12h14"/>',
};

function icon(kind, size = 18) {
  const span = document.createElement('span');
  span.className = 'compass-icon';
  span.innerHTML = `<svg viewBox="0 0 24 24" width="${size}" height="${size}" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS[kind] || ''}</svg>`;
  return span;
}

function setting(key) {
  return (state.settings || []).find((o) => o.key === key)?.value;
}

// ── The stored layout ────────────────────────────────────────────────

function readView(json) {
  if (!json || typeof json !== 'object' || !KINDS.includes(json.kind)) return null;
  if (json.kind === 'camera' && !json.id) return null;
  return {
    kind: json.kind,
    path: json.kind === 'dashboard' && typeof json.path === 'string' ? json.path.trim() : '',
    id: json.kind === 'camera' ? String(json.id) : '',
  };
}

// The same rules as CompassLayout.decode: each kind once, the center
// first, a side cut at the limit.
export function decodeLayout(raw) {
  const empty = { center: { kind: 'dashboard', path: '', id: '' }, up: [], right: [], down: [], left: [] };
  // Nothing stored yet: Home Assistant in the center and the Menu on its
  // left, as on the device.
  if (!raw || !String(raw).trim()) {
    return { ...empty, left: [{ kind: 'menu', path: '', id: '' }] };
  }
  let map;
  try { map = JSON.parse(raw); } catch (_) { return empty; }
  if (!map || typeof map !== 'object') return empty;
  const seen = new Set();
  const center = readView(map.center) || empty.center;
  seen.add(center.kind);
  const side = (list) => {
    const out = [];
    for (const item of Array.isArray(list) ? list : []) {
      const view = readView(item);
      if (!view || seen.has(view.kind)) continue;
      seen.add(view.kind);
      if (out.length < SIDE_LIMIT) out.push(view);
    }
    return out;
  };
  return { center, up: side(map.up), right: side(map.right), down: side(map.down), left: side(map.left) };
}

function encodeView(v) {
  return { kind: v.kind, ...(v.kind === 'dashboard' ? { path: v.path } : {}), ...(v.kind === 'camera' ? { id: v.id } : {}) };
}

function encodeLayout(l) {
  return JSON.stringify({
    center: encodeView(l.center),
    up: l.up.map(encodeView), right: l.right.map(encodeView),
    down: l.down.map(encodeView), left: l.left.map(encodeView),
  });
}

function holds(l, kind) {
  return [l.center, ...l.up, ...l.right, ...l.down, ...l.left].some((v) => v.kind === kind);
}

// ── Names ────────────────────────────────────────────────────────────

// The camera views, asked of the kiosk once: the stored configuration
// carries credentials, so the settings list only says it is set. Only views
// with cameras count, as in the kiosk menu: an empty one shows nothing.
let cameraList = null;
let cameraLoad = null;
function loadCameraViews() {
  cameraLoad ||= cmd('cameraGetConfig').then((r) => {
    const views = r?.ok && Array.isArray(r.data?.views) ? r.data.views : [];
    cameraList = views.filter((v) => v && v.id && Array.isArray(v.cameraIds) && v.cameraIds.length > 0);
    return cameraList;
  }).catch(() => { cameraList = []; return cameraList; }).finally(() => { cameraLoad = null; });
  return cameraLoad;
}
function cameraViews() {
  return cameraList || [];
}

function homePath() {
  const url = String(setting('browser.start_url') || '');
  const base = String(setting('ha.url') || '').replace(/\/+$/, '');
  if (!base || !url.startsWith(base + '/')) return '';
  return url.slice(base.length + 1).split(/[?#]/)[0].replace(/\/+$/, '');
}

function viewLabel(v) {
  switch (v.kind) {
    case 'menu': return t('compassQuickControlsView', {}, 'Quick Controls');
    case 'dashboard': {
      if (!v.path) return t('compassHomeDashboard', {}, 'Home Assistant');
      const m = matchDashboard(cachedDashboards(), v.path);
      if (!m) return v.path;
      if (!m.view || m.dashboard.app || m.dashboard.builtIn || (m.dashboard.views || []).length < 2) return m.dashboard.title;
      return m.view.title;
    }
    case 'music_library': return t('libraryTitle', {}, 'Music Library');
    case 'calendar': return t('calendarTitle', {}, 'Calendar');
    case 'alarms': return t('alarmsTitle', {}, 'Alarms');
    case 'now_playing': return t('drawerNowPlaying', {}, 'Now Playing');
    case 'camera': return cameraViews().find((c) => c.id === v.id)?.name || t('drawerCameraView', {}, 'Camera View');
    case 'app_launcher': return t('compassAppLauncher', {}, 'App Launcher');
    case 'intercom': return t('drawerIntercom', {}, 'Intercom');
  }
  return v.kind;
}

function kindLabel(kind) {
  if (kind === 'dashboard') return t('compassKindDashboard', {}, 'Home Assistant dashboard');
  if (kind === 'camera') return t('drawerCameraView', {}, 'Camera View');
  return viewLabel({ kind, path: '', id: '' });
}

// Whether a kind is set up on the kiosk, from the settings the remote has.
// The Music Library's sources are the device's to know, so it is offered.
function configurable(kind) {
  switch (kind) {
    case 'now_playing': return setting('sendspin.player_active') === true && setting('sendspin.fullscreen') === true;
    case 'camera': return cameraViews().length > 0;
    case 'app_launcher': {
      let apps = [];
      try { apps = JSON.parse(setting('launcher.apps') || '[]') || []; } catch (_) {}
      return setting('launcher.enabled') === true && apps.length > 0;
    }
    case 'intercom': return setting('intercom.enabled') === true;
    default: return true;
  }
}

function sideName(arm) {
  return {
    up: t('compassSideUp', {}, 'Up'), right: t('compassSideRight', {}, 'Right'),
    down: t('compassSideDown', {}, 'Down'), left: t('compassSideLeft', {}, 'Left'),
  }[arm];
}

// ── Classic or Compass ───────────────────────────────────────────────

export function compassStyleRow(row, s, save) {
  row.classList.add('compass-style-row');
  row.replaceChildren();
  const grid = document.createElement('div');
  grid.className = 'compass-styles';
  const choices = [
    ['classic', t('navigationClassic', {}, 'Classic'), t('compassClassicViewHint', {}, 'Home Assistant view with drawer menu.')],
    ['compass', t('navigationCompass', {}, 'Compass'), t('compassCompassHint', {}, 'Swipe between views laid out in a cross.')],
  ];
  const buttons = [];
  // What Compass switches off, under the cards while it is picked. The
  // rows themselves stay, greyed out (syncOffRows).
  const note = document.createElement('div');
  note.className = 'compass-off-note';
  note.textContent = t('compassOffNote', {}, 'Pull to refresh, the dashboard carousel and the edge swipe that opens the drawer menu are off while Compass is on.');
  const paint = () => {
    const value = setting(s.key) ?? s.value;
    buttons.forEach(([v, b]) => {
      b.classList.toggle('on', v === value);
      b.setAttribute('aria-checked', v === value ? 'true' : 'false');
    });
    note.hidden = value !== 'compass';
  };
  for (const [value, name, hint] of choices) {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'compass-choice';
    b.setAttribute('role', 'radio');
    const pic = document.createElement('span');
    pic.className = `compass-pic ${value}`;
    pic.innerHTML = value === 'classic'
      ? '<i class="drawer"></i><i></i><i></i><i></i><i></i>'
      : '<i></i><i></i><i class="lit"></i><i></i><i></i>';
    const text = document.createElement('span');
    text.className = 'compass-choice-text';
    const n = document.createElement('span'); n.className = 'name'; n.textContent = name;
    const d = document.createElement('span'); d.className = 'desc'; d.textContent = hint;
    text.append(n, d);
    const radio = document.createElement('span'); radio.className = 'compass-radio';
    b.append(pic, text, radio);
    b.addEventListener('click', async () => {
      if ((setting(s.key) ?? s.value) === value) return;
      await save(value);
      paint();
      syncOffRows();
    });
    buttons.push([value, b]);
    grid.appendChild(b);
  }
  row.append(grid, note);
  row.setAttribute('role', 'radiogroup');
  row.setAttribute('aria-label', s.title);
  row.updateSetting = () => { paint(); return true; };
  paint();
  return row;
}

// ── The layout map ───────────────────────────────────────────────────

export function compassLayoutRow(row, s, save) {
  row.classList.add('compass-layout-row');
  row.replaceChildren();
  let picked = null; // { arm, index } or 'center'
  const layout = () => decodeLayout(setting(s.key) ?? s.value);
  const store = async (l) => { await save(encodeLayout(l)); render(); };

  const hint = document.createElement('div');
  hint.className = 'compass-hint';
  hint.textContent = t('compassLayoutHint', {}, 'Up to two views on each side, one of each kind. Tap a view to change it, the center one too.');
  const map = document.createElement('div');
  map.className = 'compass-map';
  const bar = document.createElement('div');
  bar.className = 'compass-bar';
  row.append(hint, map, bar);

  const tile = (view, place, cls = '') => {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = `compass-tile ${cls}`;
    b.style.gridColumn = String(place.col + 1);
    b.style.gridRow = String(place.row + 1);
    const label = document.createElement('span');
    label.textContent = view ? viewLabel(view) : t('compassAddTile', {}, 'Add');
    b.append(icon(view ? view.kind : 'add', 17), label);
    if (view && view.kind !== 'menu' && !configurable(view.kind)) b.classList.add('unset');
    return b;
  };

  const add = async (arm) => {
    const titles = {
      up: t('compassAddAbove', {}, 'Add a view above'), down: t('compassAddBelow', {}, 'Add a view below'),
      left: t('compassAddLeft', {}, 'Add a view on the left'), right: t('compassAddRight', {}, 'Add a view on the right'),
    };
    const l = layout();
    const view = await pickView({ title: titles[arm], confirm: t('compassAddTile', {}, 'Add'), layout: l });
    if (!view || l[arm].length >= SIDE_LIMIT) return;
    l[arm] = [...l[arm], view];
    picked = { arm, index: l[arm].length - 1 };
    await store(l);
  };

  const replace = async (place) => {
    const l = layout();
    const old = place === 'center' ? l.center : l[place.arm][place.index];
    const view = await pickView({
      title: place === 'center' ? t('compassChangeCenter', {}, 'Change the center view')
        : t('compassReplaceTitle', { name: viewLabel(old) }, `Replace ${viewLabel(old)}`),
      confirm: t('compassReplace', {}, 'Replace'), layout: l, replacing: old,
    });
    if (!view) return;
    if (place === 'center') l.center = view;
    else l[place.arm][place.index] = view;
    await store(l);
  };

  const render = () => {
    const l = layout();
    map.replaceChildren();
    // The two arms, as grid items under the tiles.
    const across = document.createElement('i');
    across.className = 'compass-line across';
    const down = document.createElement('i');
    down.className = 'compass-line down';
    map.append(across, down);
    // The center in column 2, row 2, the sides running out from it.
    const center = tile(l.center, { col: 2, row: 2 }, 'center');
    if (picked === 'center') center.classList.add('picked');
    center.addEventListener('click', () => { picked = picked === 'center' ? null : 'center'; render(); });
    map.appendChild(center);
    const places = {
      up: (i) => ({ col: 2, row: 1 - i }), down: (i) => ({ col: 2, row: 3 + i }),
      right: (i) => ({ col: 3 + i, row: 2 }), left: (i) => ({ col: 1 - i, row: 2 }),
    };
    for (const arm of ['up', 'right', 'down', 'left']) {
      l[arm].forEach((view, index) => {
        const b = tile(view, places[arm](index));
        if (picked && picked.arm === arm && picked.index === index) b.classList.add('picked');
        b.addEventListener('click', () => {
          picked = picked && picked.arm === arm && picked.index === index ? null : { arm, index };
          render();
        });
        map.appendChild(b);
      });
      if (l[arm].length < SIDE_LIMIT) {
        const b = tile(null, places[arm](l[arm].length), 'add');
        b.addEventListener('click', () => add(arm));
        map.appendChild(b);
      }
    }

    // The bar acts on the picked view.
    bar.replaceChildren();
    if (picked && picked !== 'center' && !l[picked.arm][picked.index]) picked = null;
    if (!picked) return;
    const view = picked === 'center' ? l.center : l[picked.arm][picked.index];
    const info = document.createElement('div');
    info.className = 'compass-bar-info';
    const n = document.createElement('div'); n.className = 'name'; n.textContent = viewLabel(view);
    const d = document.createElement('div'); d.className = 'desc';
    d.textContent = picked === 'center' ? t('compassCenter', {}, 'Center')
      : picked.index === 0 ? t('compassFirstView', { side: sideName(picked.arm) }, `${sideName(picked.arm)}, first view`)
        : t('compassSecondView', { side: sideName(picked.arm) }, `${sideName(picked.arm)}, second view`);
    info.append(n, d);
    bar.appendChild(info);
    const button = (label, cls, onClick) => {
      const b = document.createElement('button');
      b.type = 'button'; b.className = cls; b.textContent = label;
      b.addEventListener('click', onClick);
      bar.appendChild(b);
    };
    if (picked !== 'center') {
      const { arm, index } = picked;
      const shift = async (by) => {
        const next = layout();
        const side = [...next[arm]];
        const [moved] = side.splice(index, 1);
        side.splice(index + by, 0, moved);
        next[arm] = side;
        picked = { arm, index: index + by };
        await store(next);
      };
      if (index > 0) button(t('compassMoveIn', {}, 'Move in'), 'btn-ghost', () => shift(-1));
      if (index < l[arm].length - 1) button(t('compassMoveOut', {}, 'Move out'), 'btn-ghost', () => shift(1));
    }
    const place = picked;
    button(t('compassReplace', {}, 'Replace'), 'btn-ghost', () => replace(place));
    if (place !== 'center') {
      button(t('compassRemove', {}, 'Remove'), 'btn-ghost compass-remove', async () => {
        const next = layout();
        next[place.arm] = next[place.arm].filter((_, i) => i !== place.index);
        picked = null;
        await store(next);
      });
    }
  };

  row.updateSetting = () => { render(); return true; };
  if (!cachedDashboards()) loadDashboards().then(render).catch(() => {});
  loadCameraViews().then(render);
  render();
  return row;
}

// ── Picking a view ───────────────────────────────────────────────────

// One row per kind, the dashboard field under the dashboard row and the
// camera views under the camera row when there is a choice. A kind the
// layout holds (other than the one being replaced) or one not set up on
// the kiosk cannot be picked. Resolves to the view, or null.
function pickView({ title, confirm, layout, replacing = null }) {
  return new Promise((resolve) => {
    if (!cameraList) loadCameraViews().then(() => paint());
    let kind = replacing ? replacing.kind : null;
    let path = replacing?.kind === 'dashboard' ? replacing.path : '';
    const views = cameraViews();
    let camera = replacing?.kind === 'camera' ? replacing.id
      : (views.find((v) => v.isDefault)?.id || views[0]?.id || '');
    const done = (value) => { shell.close(); resolve(value); };
    const shell = modalShell({ title, width: 520, onDismiss: () => done(null) });
    const list = document.createElement('div');
    list.className = 'compass-kinds';
    shell.body.appendChild(list);
    const ok = document.createElement('button');
    ok.className = 'btn-primary'; ok.textContent = confirm;
    const cancel = document.createElement('button');
    cancel.className = 'btn-text'; cancel.textContent = t('commonCancel', {}, 'Cancel');
    shell.foot.append(cancel, ok);
    cancel.addEventListener('click', () => done(null));
    const result = () => {
      if (kind === 'dashboard') return { kind, path, id: '' };
      if (kind === 'camera') return camera ? { kind, path: '', id: camera } : null;
      return kind ? { kind, path: '', id: '' } : null;
    };
    ok.addEventListener('click', () => { const r = result(); if (r) done(r); });
    const paint = () => {
      list.replaceChildren();
      for (const k of KINDS) {
        const taken = k !== replacing?.kind && holds(layout, k);
        const ready = configurable(k);
        const label = document.createElement('label');
        label.className = 'compass-kind' + (taken || !ready ? ' off' : '') + (kind === k ? ' on' : '');
        const input = document.createElement('input');
        input.type = 'radio'; input.name = 'compass-kind'; input.checked = kind === k;
        input.disabled = taken || !ready;
        input.addEventListener('change', () => { kind = k; paint(); });
        const text = document.createElement('span');
        text.className = 'compass-kind-text';
        const n = document.createElement('span'); n.className = 'name'; n.textContent = kindLabel(k);
        text.appendChild(n);
        const sub = taken ? t('compassKindTaken', {}, 'Already placed')
          : !ready ? t('compassKindUnavailable', {}, 'Not set up on this kiosk')
            : k === 'dashboard' ? t('compassKindDashboardHint', {}, 'Any view, Custom Pages and app pages') : '';
        if (sub) { const d = document.createElement('span'); d.className = 'desc'; d.textContent = sub; text.appendChild(d); }
        label.append(icon(k, 20), text, input);
        list.appendChild(label);
        if (k === 'dashboard' && kind === 'dashboard') {
          const holder = document.createElement('div');
          holder.className = 'compass-kind-extra';
          const field = dashboardField({
            value: path || homePath(),
            title: kindLabel('dashboard'),
            onPick: (p) => { path = p; },
          });
          holder.appendChild(field.el);
          list.appendChild(holder);
        }
        if (k === 'camera' && kind === 'camera' && views.length > 1) {
          const holder = document.createElement('div');
          holder.className = 'compass-kind-extra';
          const select = document.createElement('select');
          select.className = 'field';
          for (const v of views) {
            const o = document.createElement('option');
            o.value = v.id; o.textContent = v.name || v.id; o.selected = v.id === camera;
            select.appendChild(o);
          }
          select.addEventListener('change', () => { camera = select.value; });
          holder.appendChild(select);
          list.appendChild(holder);
        }
      }
      ok.disabled = !result();
    };
    paint();
  });
}
