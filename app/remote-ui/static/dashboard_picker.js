import { haText, t } from './localization.js';
import { api, cmd, state } from './core.js';
import { modalShell, queueEdgeFades } from './widgets.js';

/* The dashboard picker, the device's DashboardPicker in the browser:
   dashboards on the left with their Home Assistant icons, the browsed
   dashboard's views as tiles on the right, search across both. Under 520
   it drills from dashboards into views. Icons come from the device as SVG
   path data with the lists (icon_path), so the page needs no icon set. */

// mdi:view-dashboard, for a dashboard without an icon of its own.
const DASHBOARD_ICON = 'M13,3V9H21V3M13,21H21V11H13M3,21H11V15H3M3,13H11V3H3V13Z';
const SVG = 'http://www.w3.org/2000/svg';

let catalog = null;
let pending = null;
const listeners = new Set();

// Repaint [node] whenever the dashboards load, until it leaves the page.
function follow(node, paint) {
  let seen = false;
  const fn = () => {
    if (node.isConnected) { seen = true; paint(); } else if (seen) listeners.delete(fn);
  };
  listeners.add(fn);
}

// Every dashboard with its views: [{ path, title, iconPath, views: [{ title,
// route, iconPath, subview }] }]. Null when Home Assistant cannot list its
// dashboards; the last good list stays cached.
export function loadDashboards() {
  pending ||= (async () => {
    try {
      const r = await cmd('haListDashboards', { icons: true }, { timeoutMs: 10000 });
      if (!r?.ok || !Array.isArray(r.data)) return null;
      const dashboards = r.data.filter((d) => d.url_path);
      const views = await Promise.all(dashboards.map(async (d) => {
        try {
          const v = await cmd('haListDashboardViews',
            { url_path: d.url_path, icons: true }, { timeoutMs: 10000 });
          if (v?.ok && Array.isArray(v.data)) return v.data;
        } catch (_) {}
        // Unreadable views open the dashboard whole, like a strategy one.
        return [];
      }));
      catalog = dashboards.map((d, i) => ({
        path: String(d.url_path),
        // The Custom Pages entry: the person's own pages under /local/,
        // listed as its views and named in the admin's language.
        custom: d.custom === true,
        // An app's sidebar panel (Music Assistant, Panalume): Home
        // Assistant shows its ingress page on its path, with no views.
        app: d.app === true,
        // One of Home Assistant's own pages (Energy, History) or a page an
        // integration adds: like an app, one page with no views.
        builtIn: d.builtIn === true,
        title: d.custom === true ? haText('Custom Pages') : (d.title || d.url_path),
        iconPath: d.icon_path || null,
        views: views[i].filter((v) => v.route !== undefined && v.route !== '')
          .map((v) => ({
            title: v.title || String(v.route),
            route: String(v.route),
            iconPath: v.icon_path || null,
            hasIcon: !!v.icon,
            subview: v.subview === true,
          })),
      }));
      listeners.forEach((fn) => fn());
      return catalog;
    } catch (_) {
      return null;
    } finally {
      pending = null;
    }
  })();
  return pending;
}

export function cachedDashboards() { return catalog; }

// The navigation path of a view, or of a dashboard opened whole.
const pathOf = (d, v) => (v ? `${d.path}/${v.route}` : d.path);

// [path] in [list]: "dashboard/view", or a bare dashboard, which reads as
// its first view because that is what Home Assistant opens.
export function matchDashboard(list, path) {
  if (!list || !path) return null;
  for (const d of list) {
    if (path === d.path) return { dashboard: d, view: d.views[0] || null };
    if (path.startsWith(d.path + '/')) {
      const route = path.slice(d.path.length + 1);
      const v = d.views.find((x) => x.route === route);
      if (v) return { dashboard: d, view: v };
    }
  }
  return null;
}

// The stored custom pages, whose paths are full URLs for a page on another
// server.
function customPagePaths() {
  const raw = (state.settings || []).find((s) => s.key === 'ha.custom_pages')?.value;
  try {
    const list = JSON.parse(raw || '[]');
    return Array.isArray(list) ? list.map((p) => `${p?.path || ''}`) : [];
  } catch (_) { return []; }
}

// The URL a navigation path loads: a custom page on another server is its
// own URL ("local/https://..."), anything else lives on [base].
export function viewPathUrl(base, path) {
  if (/^local\/https?:\/\//.test(path)) return path.slice('local/'.length);
  return `${(base || '').replace(/\/$/, '')}/${path}`;
}

// The navigation path inside a start URL on [base], without a query. A URL
// elsewhere is one of the custom pages on another server, or null.
export function dashboardPathOfUrl(url, base) {
  base = (base || '').replace(/\/$/, '');
  if (url && /^https?:\/\//.test(url) && !(base && url.startsWith(base + '/'))) {
    return externalPagePath(url);
  }
  if (!base || !url || !url.startsWith(base + '/')) return null;
  const path = url.slice(base.length + 1);
  // A custom page keeps its query and fragment, which pick its layout.
  if (path.startsWith('local/')) return path;
  return path.replace(/[?#].*$/, '').replace(/\/+$/, '');
}

// The device's externalPageNavPath: the custom page on another server that
// [url] shows, or the same file under a fragment no page names.
function externalPagePath(url) {
  let shown;
  try {
    const u = new URL(url);
    shown = u.href;
  } catch (_) { return null; }
  const file = shown.replace(/#.*$/, '');
  let sameFile = null;
  for (const path of customPagePaths()) {
    if (!/^https?:\/\//.test(path)) continue;
    if (path === shown) return `local/${path}`;
    if (!sameFile && path.replace(/#.*$/, '') === file) sameFile = path;
  }
  return sameFile ? `local/${shown}` : null;
}

// A route or navigation path as the picker prints it: a path on Home
// Assistant with its leading slash, a custom page on another server as its
// URL.
function shownPath(path) {
  path = String(path || '');
  if (/^local\/https?:\/\//.test(path)) return path.slice('local/'.length);
  return /^https?:\/\//.test(path) ? path : '/' + path;
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

// A view's glyph: its icon, or the first letter of its title when it has
// none, the way Home Assistant's view tabs fall back to the title.
function glyph(iconPath, title, size) {
  if (iconPath) return svgPath(iconPath, size);
  const s = el('span', 'dp-letter', (title || '?').trim().charAt(0).toUpperCase() || '?');
  s.style.fontSize = `${Math.round(size * 0.82)}px`;
  return s;
}

const viewTitle = (d, v) => (v ? v.title : d.app || d.builtIn ? d.title : haText('Whole dashboard'));
const viewIcon = (d, v) => (v ? v.iconPath : (d.iconPath || DASHBOARD_ICON));

function square(d, v) {
  const s = el('span', 'dp-square');
  s.appendChild(glyph(viewIcon(d, v), viewTitle(d, v), 22));
  return s;
}

function mono(text) { return el('span', 'dp-mono', text); }

function highlighted(text, query) {
  const span = el('span');
  const i = query ? text.toLowerCase().indexOf(query.toLowerCase()) : -1;
  if (i < 0) { span.textContent = text; return span; }
  span.append(text.slice(0, i), el('mark', 'dp-mark', text.slice(i, i + query.length)),
    text.slice(i + query.length));
  return span;
}

function countLabel(d) {
  if (d.app) return haText('Ingress page');
  if (d.builtIn) return haText('Home Assistant page');
  if (!d.views.length) return haText('Builds its own views');
  if (d.custom) {
    return d.views.length === 1 ? haText('1 page')
      : t('dashboardPickerPageCount', { count: String(d.views.length) });
  }
  if (d.views.length === 1) return haText('1 view');
  return t('dashboardPickerViewCount', { count: String(d.views.length) });
}

function dashboardRow(d, { active = false, holds = false, chevron = false, onClick }) {
  const b = el('button', 'dp-dash' + (active ? ' active' : ''));
  b.type = 'button';
  const disc = el('span', 'dp-disc');
  disc.appendChild(svgPath(d.iconPath || DASHBOARD_ICON, 20));
  const text = el('span', 'dp-text');
  text.append(el('span', 'dp-title', d.title), el('span', 'dp-sub', countLabel(d)));
  b.append(disc, text);
  if (holds) b.appendChild(el('span', 'dp-dot'));
  if (chevron) {
    const c = el('span', 'dp-chev');
    c.appendChild(svgPath('M8.59,16.58L13.17,12L8.59,7.41L10,6L16,12L10,18L8.59,16.58Z', 20));
    b.appendChild(c);
  }
  b.addEventListener('click', onClick);
  return b;
}

function tile(d, v, { picked, mode, showing, onClick }) {
  const b = el('button', 'dp-tile' + (picked ? ' picked' : ''));
  b.type = 'button';
  b.setAttribute('aria-pressed', picked ? 'true' : 'false');
  b.appendChild(square(d, v));
  const text = el('span', 'dp-text');
  text.append(el('span', 'dp-title', viewTitle(d, v)), mono(shownPath(v ? v.route : d.path)));
  b.appendChild(text);
  if (mode === 'several') {
    const cb = el('input');
    cb.type = 'checkbox';
    cb.checked = picked;
    cb.tabIndex = -1;
    cb.className = 'dp-check';
    b.appendChild(cb);
  } else if (picked) {
    b.appendChild(el('span', 'dp-badge'));
  } else if (showing) {
    b.appendChild(el('span', 'dp-tag dp-showing', haText('Showing')));
  }
  b.addEventListener('click', onClick);
  return b;
}

function viewRow(d, v, { picked, mode, showing, withDashboard, query = '', onClick }) {
  const b = el('button', 'dp-row' + (picked ? ' picked' : ''));
  b.type = 'button';
  if (mode === 'several') {
    const cb = el('input');
    cb.type = 'checkbox';
    cb.checked = picked;
    cb.tabIndex = -1;
    b.appendChild(cb);
  }
  b.appendChild(square(d, v));
  const text = el('span', 'dp-text');
  const title = el('span', 'dp-title');
  title.appendChild(highlighted(viewTitle(d, v), query));
  const sub = el('span', 'dp-sub');
  if (withDashboard) sub.append(d.title, el('span', 'dp-sep', ' · '));
  sub.appendChild(mono(shownPath(pathOf(d, v))));
  text.append(title, sub);
  b.appendChild(text);
  if (v?.subview) b.appendChild(el('span', 'dp-tag', haText('Subview')));
  if (showing && mode === 'go') b.appendChild(el('span', 'dp-tag dp-showing', haText('Showing')));
  if (picked && mode !== 'several') b.appendChild(el('span', 'dp-tick'));
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

function skeleton(wide) {
  const box = el('div', 'dp-skeleton' + (wide ? ' wide' : ''));
  const rows = el('div', 'dp-skel-rows');
  for (let i = 0; i < 4; i++) rows.appendChild(el('div', 'dp-skel-row'));
  box.appendChild(rows);
  if (wide) {
    const tiles = el('div', 'dp-skel-tiles');
    for (let i = 0; i < 3; i++) tiles.appendChild(el('div', 'dp-skel-tile'));
    box.appendChild(tiles);
  }
  return box;
}

/* ------------------------------------------------------------ the picker */

// Builds a picker into [host]. Options: title (null inline), selected
// (array of paths), mode 'select' | 'go' | 'several', showing (the path on
// screen, go mode), showingUpdate (a promise of a fresher one, which only
// moves the Showing mark), onPick(path), onDone(paths), onClose(). Returns
// { root, head, destroy }.
function buildPicker({ title = null, selected = [], mode = 'select', showing = null,
  showingUpdate = null, refresh = true, onPick, onDone, onClose }) {
  const st = {
    list: catalog, loading: false, failed: false, browsing: null, drill: null,
    query: '', picked: [...selected], wide: true, opened: false, browsed: false,
  };
  let showingPath = showing || null;
  const root = el('div', 'dp' + (title ? '' : ' inline'));
  const head = el('div', 'dp-head');
  const bar = el('div', 'dp-bar');
  const back = el('button', 'icon-btn dp-back');
  back.type = 'button';
  back.setAttribute('aria-label', haText('Back'));
  back.appendChild(svgPath('M20,11V13H8L13.5,18.5L12.08,19.92L4.16,12L12.08,4.08L13.5,5.5L8,11H20Z', 22));
  const heading = el('div', 'dp-heading');
  const titleEl = el('div', 'dp-name modal-title');
  const pathEl = mono('');
  heading.append(titleEl, pathEl);
  bar.append(back, heading);
  const search = el('input', 'dp-search');
  search.type = 'search';
  search.autocomplete = 'off';
  head.append(bar, search);
  const content = el('div', 'dp-content');
  root.append(head, content);
  let foot = null;
  let countEl = null;
  if (mode === 'several') {
    foot = el('div', 'dp-foot');
    countEl = el('span', 'dp-count');
    const cancel = el('button', 'btn-text', haText('Cancel'));
    cancel.type = 'button';
    cancel.addEventListener('click', () => onClose?.());
    const done = el('button', 'btn-primary', haText('Done'));
    done.type = 'button';
    done.addEventListener('click', () => onDone?.([...st.picked]));
    foot.append(countEl, cancel, done);
    root.appendChild(foot);
  }

  const isPicked = (d, v) => st.picked.includes(pathOf(d, v))
    || (v && v === d.views[0] && st.picked.includes(d.path));
  const holds = (d) => (d.views.length ? d.views.some((v) => isPicked(d, v)) : isPicked(d, null));
  const isShowing = (d, v) => {
    if (!showingPath) return false;
    const m = matchDashboard([d], showingPath);
    return !!m && m.view === v;
  };

  function tap(d, v) {
    const path = pathOf(d, v);
    if (mode !== 'several') { onPick?.(path); return; }
    if (isPicked(d, v)) {
      st.picked = st.picked.filter((p) => p !== path && !(v && v === d.views[0] && p === d.path));
    } else {
      st.picked.push(path);
    }
    render();
  }

  function openOn(list) {
    if (st.opened) return;
    st.opened = true;
    for (const p of st.picked) {
      const m = matchDashboard(list, p);
      if (m) { st.browsing = m.dashboard.path; return; }
    }
    if (mode === 'go' && showingPath) {
      const m = matchDashboard(list, showingPath);
      if (m) { st.browsing = m.dashboard.path; return; }
    }
    st.browsing = list[0]?.path || null;
  }

  function header() {
    const drilled = !st.wide && !st.query ? st.list?.find((d) => d.path === st.drill) : null;
    const name = drilled ? drilled.title : title;
    root.classList.toggle('narrow', !st.wide);
    head.hidden = !name && !(st.list && st.list.length);
    bar.hidden = !name;
    titleEl.textContent = name || '';
    pathEl.textContent = drilled ? '/' + drilled.path : '';
    pathEl.hidden = !drilled;
    back.hidden = st.wide || !(drilled || onClose);
    search.hidden = !(st.list && st.list.length) || (!!drilled);
    search.placeholder = st.wide && title
      ? haText('Search views') : haText('Search dashboards and views');
    if (countEl) countEl.textContent = t('dashboardPickerSelected', { count: String(st.picked.length) });
  }

  function viewsPane(d) {
    const pane = el('div', 'dp-views edge-fade');
    const ph = el('div', 'dp-pane-head');
    ph.append(el('span', 'dp-pane-title', d.title), mono('/' + d.path));
    pane.appendChild(ph);
    const grid = (views) => {
      const g = el('div', 'dp-grid');
      views.forEach((v) => g.appendChild(tile(d, v, {
        picked: mode !== 'go' && isPicked(d, v), mode, showing: isShowing(d, v),
        onClick: () => tap(d, v),
      })));
      return g;
    };
    if (!d.views.length) {
      pane.appendChild(grid([null]));
      if (!d.app && !d.builtIn) {
        pane.appendChild(el('div', 'dp-note',
          haText('This dashboard builds its own views, so the kiosk opens it whole.')));
      }
      return pane;
    }
    pane.appendChild(grid(d.views.filter((v) => !v.subview)));
    const subs = d.views.filter((v) => v.subview);
    if (subs.length) {
      pane.appendChild(el('div', 'dp-subhead', haText('Subviews')));
      pane.appendChild(grid(subs));
    }
    return pane;
  }

  function rowOpts(d, v, extra = {}) {
    return {
      picked: mode !== 'go' && isPicked(d, v), mode, showing: isShowing(d, v),
      onClick: () => tap(d, v), ...extra,
    };
  }

  function results() {
    const q = st.query.toLowerCase();
    const box = el('div', 'dp-list edge-fade');
    let any = false;
    for (const d of st.list) {
      const all = d.title.toLowerCase().includes(q) || d.path.toLowerCase().includes(q);
      const views = d.views.length
        ? d.views.filter((v) => all || v.title.toLowerCase().includes(q)
          || v.route.toLowerCase().includes(q))
        : (all ? [null] : []);
      if (!views.length) continue;
      any = true;
      const gh = el('div', 'dp-group');
      gh.appendChild(svgPath(d.iconPath || DASHBOARD_ICON, 18));
      gh.appendChild(highlighted(d.title, st.query));
      box.appendChild(gh);
      views.forEach((v) => box.appendChild(viewRow(d, v, rowOpts(d, v, { query: st.query }))));
    }
    if (!any) return stateMessage(haText('No views match'));
    return box;
  }

  function render() {
    header();
    const list = st.list;
    let node;
    if (!list) {
      if (st.failed) {
        const retry = el('button', 'btn-ghost', haText('Try again'));
        retry.type = 'button';
        retry.addEventListener('click', reload);
        node = stateMessage(haText('Could not reach Home Assistant'),
          haText('The dashboards load once the connection is back.'), retry);
      } else {
        node = skeleton(st.wide);
      }
    } else if (!list.length) {
      node = stateMessage(haText('No dashboards yet'),
        haText('Dashboards you add in Home Assistant show up here.'));
    } else if (st.query) {
      node = results();
    } else if (!st.wide) {
      const d = list.find((x) => x.path === st.drill);
      node = el('div', 'dp-list edge-fade');
      if (d) {
        if (!d.views.length) {
          node.appendChild(viewRow(d, null, rowOpts(d, null)));
          if (!d.app && !d.builtIn) {
            node.appendChild(el('div', 'dp-note',
              haText('This dashboard builds its own views, so the kiosk opens it whole.')));
          }
        } else {
          d.views.filter((v) => !v.subview).forEach((v) => node.appendChild(viewRow(d, v, rowOpts(d, v))));
          const subs = d.views.filter((v) => v.subview);
          if (subs.length) {
            node.appendChild(el('div', 'dp-subhead', haText('Subviews')));
            subs.forEach((v) => node.appendChild(viewRow(d, v, rowOpts(d, v))));
          }
        }
      } else {
        const current = mode === 'select'
          ? st.picked.map((p) => matchDashboard(list, p)).find(Boolean) : null;
        if (current) {
          node.appendChild(el('div', 'dp-subhead', haText('Current')));
          node.appendChild(viewRow(current.dashboard, current.view,
            rowOpts(current.dashboard, current.view, { withDashboard: true })));
          node.appendChild(el('div', 'dp-subhead', haText('Dashboards')));
        }
        list.forEach((x) => node.appendChild(dashboardRow(x, {
          holds: mode !== 'go' && holds(x), chevron: true,
          onClick: () => { st.drill = x.path; render(); },
        })));
      }
    } else {
      const d = list.find((x) => x.path === st.browsing) || list[0];
      node = el('div', 'dp-columns');
      const left = el('div', 'dp-dashes edge-fade');
      list.forEach((x) => left.appendChild(dashboardRow(x, {
        active: x === d, holds: mode !== 'go' && holds(x),
        onClick: () => { st.browsing = x.path; st.browsed = true; render(); },
      })));
      node.append(left, viewsPane(d));
    }
    const scrollers = [...content.querySelectorAll('.dp-dashes')].map((x) => x.scrollTop);
    content.replaceChildren(node);
    const left = content.querySelector('.dp-dashes');
    if (left && scrollers.length) left.scrollTop = scrollers[0];
    queueEdgeFades();
  }

  async function reload() {
    st.loading = true;
    st.failed = false;
    if (!st.list) render();
    const list = await loadDashboards();
    st.loading = false;
    if (list) { st.list = list; openOn(list); } else if (!st.list) st.failed = true;
    render();
  }

  back.addEventListener('click', () => {
    if (!st.wide && st.drill && !st.query) { st.drill = null; render(); return; }
    onClose?.();
  });
  search.addEventListener('input', () => { st.query = search.value.trim(); render(); });

  const observer = new ResizeObserver(() => {
    const wide = root.clientWidth >= 520;
    if (wide !== st.wide) { st.wide = wide; render(); }
  });
  observer.observe(root);
  if (st.list) openOn(st.list);
  render();
  // A fresher view on screen can arrive after the picker opened. It moves
  // the Showing mark, never the dashboard on view, unless the picker had
  // nothing to open on: a picker that shifts under the pointer is worse
  // than a mark that moves.
  if (showingUpdate) {
    showingUpdate.then((path) => {
      const had = showingPath;
      showingPath = path || null;
      if (showingPath === had) return;
      if (!had && !st.browsed) { st.opened = false; if (st.list) openOn(st.list); }
      if (root.isConnected) render();
    }, () => {});
  }
  // A modal refreshes the list on open. Inline, a re-render of the page
  // reuses what is cached.
  if (refresh || !st.list) reload();
  return {
    root,
    setSelected(paths) { st.picked = [...paths]; render(); },
    destroy() { observer.disconnect(); },
  };
}

// The picker in a modal. Resolves to the picked path ('select', 'go'), the
// picked paths ('several'), or null when dismissed.
// One picker at a time: a second click while one is open, or still
// opening, gets null instead of a second modal on top.
let pickerOpen = false;

export function pickDashboard({ title, selected = null, mode = 'select', showing = null,
  showingUpdate = null }) {
  if (pickerOpen) return Promise.resolve(null);
  pickerOpen = true;
  return new Promise((resolve) => {
    let picker = null;
    // The second click of a double click lands on the backdrop the first
    // one just opened: it must not close the picker again.
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
    picker = buildPicker({
      title,
      selected: Array.isArray(selected) ? selected : (selected ? [selected] : []),
      mode,
      showing,
      showingUpdate,
      onPick: (path) => finish(path),
      onDone: (paths) => finish(paths),
      onClose: () => finish(null),
    });
    shell.body.appendChild(picker.root);
    if (mode !== 'several') {
      const cancel = el('button', 'btn-text', haText('Cancel'));
      cancel.type = 'button';
      cancel.addEventListener('click', () => finish(null));
      shell.foot.appendChild(cancel);
    }
  });
}

// The picker inline (the setup wizard): tapping a view reports it through
// onPick and checks it. Returns the element.
export function dashboardPicker({ value, onPick }) {
  let picker = null;
  picker = buildPicker({
    selected: value ? [value] : [],
    refresh: false,
    onPick: (path) => { picker.setSelected([path]); onPick(path); },
  });
  picker.root.classList.add('dp-inline');
  return picker.root;
}

/* ------------------------------------------------------------ the field */

// A stored view at rest: the control box with the view's icon, the
// dashboard muted, a slash and the view. Empty reads Choose a view. A view
// gone from Home Assistant shows its path with an error border. Before the
// dashboards load, the path stands in. Returns { el, setValue, repaint }.
//
// mode 'go' (the Overview's Go to view) shows the view on screen instead of
// a stored one: [showing] reads it fresh on every open, a page that is not
// one of the dashboards reads Choose a view rather than missing, and the
// picker opens in go mode with that view marked Showing.
export function dashboardField({ value = '', title, onPick, mode = 'select', showing = null }) {
  const box = el('button', 'dp-field');
  box.type = 'button';
  let current = value;
  const paint = () => {
    box.replaceChildren();
    const m = matchDashboard(catalog, current);
    const missing = mode !== 'go' && !!current && !!catalog && !m;
    box.classList.toggle('missing', missing);
    const lead = el('span', 'dp-field-icon');
    const text = el('span', 'dp-field-text');
    if (!current || (mode === 'go' && !m)) {
      lead.appendChild(svgPath('M3,11H11V3H3M5,5H9V9H5M13,21H21V13H13M15,15H19V19H15M3,21H11V13H3M5,15H9V19H5M13,3V11H21V3M15,5H19V9H15Z', 20));
      text.classList.add('placeholder');
      text.textContent = haText('Choose a view');
    } else if (!m) {
      lead.appendChild(missing
        ? svgPath('M13,14H11V10H13M13,18H11V16H13M1,21H23L12,2L1,21Z', 20)
        : svgPath(DASHBOARD_ICON, 20));
      lead.classList.toggle('error', missing);
      text.appendChild(mono(current));
    } else {
      lead.appendChild(glyph(viewIcon(m.dashboard, m.view), viewTitle(m.dashboard, m.view), 20));
      lead.classList.add('primary');
      // An app or a built-in page is its own page, so its name alone says it.
      if ((m.dashboard.app || m.dashboard.builtIn) && !m.view) text.append(viewTitle(m.dashboard, m.view));
      else {
        text.append(el('span', 'dp-field-dash', m.dashboard.title),
          el('span', 'dp-sep', ' / '), viewTitle(m.dashboard, m.view));
      }
    }
    const chev = el('span', 'dp-field-chev');
    chev.appendChild(svgPath('M7.41,8.58L12,13.17L16.59,8.58L18,10L12,16L6,10L7.41,8.58Z', 20));
    box.append(lead, text, chev);
    box.dispatchEvent(new CustomEvent('dp-painted', { detail: { missing } }));
  };
  box.addEventListener('click', async () => {
    // Go mode opens at once on the view last seen, so there is no pause
    // for a second click to land in, and asks the kiosk again meanwhile.
    const fresh = mode === 'go' && showing
      ? Promise.resolve(showing()).then((path) => {
        current = path || '';
        paint();
        return path;
      })
      : null;
    const picked = mode === 'go'
      ? await pickDashboard({ title, mode: 'go', showing: current || null, showingUpdate: fresh })
      : await pickDashboard({ title, selected: current });
    if (picked == null || picked === current) return;
    current = picked;
    paint();
    onPick(picked);
  });
  follow(box, paint);
  paint();
  if (!catalog) loadDashboards();
  return { el: box, setValue: (v) => { current = v || ''; paint(); }, repaint: paint };
}

// A settings row whose value is a dashboard view: the name, the field and
// the description, with a line in error color when the stored view is gone.
export function dashboardViewRow({ name, desc, value, title = name, onPick }) {
  const row = el('div', 'row dp-field-row');
  const info = el('div', 'info');
  const nameEl = el('div', 'name', name);
  const missingEl = el('div', 'desc dp-missing',
    haText('This view is gone from Home Assistant. Choose another.'));
  missingEl.hidden = true;
  info.append(nameEl, missingEl);
  if (desc) info.appendChild(el('div', 'desc', desc));
  const field = dashboardField({ value, title, onPick });
  field.el.addEventListener('dp-painted', (e) => { missingEl.hidden = !e.detail.missing; });
  missingEl.hidden = !(value && catalog && !matchDashboard(catalog, value));
  row.append(info, field.el);
  return row;
}

// One stored view as a list row (the rotation's picks): glyph, title, then
// the dashboard and path. The bare path stands in until the dashboards
// load, or when the view is gone. A leading element sits ahead of the
// glyph: the drag handle of an orderable list.
export function dashboardViewListRow(value, trailing, leading) {
  const row = el('div', 'dp-pick-row');
  const paint = () => {
    row.replaceChildren();
    if (leading) row.appendChild(leading);
    const m = matchDashboard(catalog, value);
    if (m) {
      row.appendChild(square(m.dashboard, m.view));
      const text = el('span', 'dp-text');
      const sub = el('span', 'dp-sub');
      sub.append(m.dashboard.title, el('span', 'dp-sep', ' · '), mono(shownPath(value)));
      text.append(el('span', 'dp-title', viewTitle(m.dashboard, m.view)), sub);
      row.appendChild(text);
    } else {
      const sq = el('span', 'dp-square' + (catalog ? ' error' : ''));
      sq.appendChild(catalog
        ? svgPath('M13,14H11V10H13M13,18H11V16H13M1,21H23L12,2L1,21Z', 22)
        : svgPath(DASHBOARD_ICON, 22));
      row.appendChild(sq);
      const text = el('span', 'dp-text');
      text.appendChild(mono(shownPath(value)));
      row.appendChild(text);
    }
    if (trailing) row.appendChild(trailing);
  };
  follow(row, paint);
  paint();
  if (!catalog) loadDashboards();
  return row;
}

// The page the kiosk shows right now, as a navigation path on the Home
// Assistant origin, for go mode's Showing mark.
export async function currentDashboardPath(base) {
  try {
    const info = await (await api('/api/info')).json();
    return dashboardPathOfUrl(info.currentUrl || '', base);
  } catch (_) {
    return null;
  }
}
