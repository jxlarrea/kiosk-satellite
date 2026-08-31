import { $, dependsSatisfiedBy, state } from './core.js';
import { TABS, TAB_TITLES, currentPath, setNav, showTab } from './tabs.js';

/* ---- Settings search ---- */
// Mirrors the device's settings search (settings_search.dart): one index
// over the definitions (state.settings, the same declarative list), the
// pages themselves, and a short list of hand-built rows the definitions do
// not cover. Keep SEARCH_EXTRAS in step with handBuiltSearchEntries there.
export const SEARCH_CATEGORY_TABS = {
  'Browser': 'browser', 'Kiosk': 'kiosk', 'Lockdown': 'lockdown',
  'Launcher': 'launcher', 'Home': 'home', 'Screen & Audio': 'screenaudio',
  'Screensaver': 'screensaver', 'Camera': 'camera',
  'Home Assistant': 'homeassistant', 'Voice Satellite': 'voicesatellite',
  'MQTT': 'mqtt', 'Sendspin': 'sendspin', 'DLNA': 'dlna',
  'ESPHome': 'esphome',
  'Device': 'device', 'Cameras': 'cameras', 'Gestures': 'gestures',
};
// Second-level pages no setting declares: their rows come from the Voice
// Satellite integration, not from the definitions, so the page that draws
// them names them. Mirrors the two pages VsControlsSection places on the
// device.
export const DEFLESS_SUBPAGES = [['voicesatellite', 'Appearance'],
  ['device', 'Hardware'], ['device', 'Home Assistant'], ['device', 'WebView']];
export const SEARCH_EXTRAS = [
  { tab: 'home', title: 'Home app status',
    desc: 'Whether Kiosk Satellite is the device home app, and where to '
      + 'finish setting it as the default.' },
  { tab: 'esphome', title: 'Test notification', sub: 'Notifications',
    desc: 'The Home Assistant action that sends notifications, and a button to show one.' },
  { tab: 'esphome', title: 'Required system permissions', sub: 'GPS Sensor',
    desc: 'The Location grant the location sensors need.',
    heading: 'Required system permissions' },
  // Only where the device has a person sensor: dropped with its page.
  { tab: 'screensaver', title: 'Required system permissions', sub: 'Person Detection',
    desc: "The Log access grant the device's person sensor needs.",
    heading: 'Required system permissions', onlyWith: 'screensaver.dismiss_on_person' },
  { tab: 'esphome', title: 'Nearby devices', sub: 'Bluetooth Proxy',
    desc: 'The Bluetooth devices this kiosk hears, with names where known.' },
  { tab: 'esphome', title: 'Required system permissions', sub: 'Bluetooth Proxy',
    desc: 'The Nearby devices grant the Bluetooth proxy needs to scan.',
    heading: 'Required system permissions' },
  { tab: 'device', title: 'Service status', sub: 'Kiosk Satellite Service',
    desc: 'Whether the Kiosk Satellite Service is running and what it is keeping alive.',
    heading: 'Status' },
  { tab: 'device', title: 'Required system permissions', sub: 'Kiosk Satellite Service',
    desc: 'The grants the Kiosk Satellite Service needs.',
    heading: 'Required system permissions' },
  { tab: 'homeassistant', title: 'Validate connection',
    desc: 'Check the URL and token against your Home Assistant.' },
  { tab: 'homeassistant', title: 'Secure context proxy',
    desc: 'Serve a plain-http Home Assistant through a secure proxy inside the app.' },
  { tab: 'homeassistant', title: 'Dashboard',
    desc: 'Pick the dashboard and view the kiosk shows.', heading: 'Dashboard' },
  { tab: 'sendspin', title: 'Player to control',
    desc: 'Show and control another Music Assistant player instead of this device.' },
  { tab: 'voicesatellite', title: 'Assigned satellite',
    desc: 'The assist_satellite entity this kiosk identifies as in Home Assistant.' },
  { tab: 'voicesatellite', title: 'Auto start',
    desc: 'Auto start Voice Satellite on dashboard load.' },
  { tab: 'voicesatellite', title: 'Assist pipeline 1',
    desc: 'The Assist pipeline voice commands run through.' },
  { tab: 'voicesatellite', title: 'Assist pipeline 2',
    desc: 'The pipeline used when the second wake word triggers.' },
  { tab: 'voicesatellite', title: 'Engine',
    desc: 'Start or Stop the Voice Satellite engine.' },
  { tab: 'voicesatellite', title: 'Mute',
    desc: 'Stop listening for wake words.' },
  { tab: 'voicesatellite', title: 'Finished speaking detection',
    desc: 'How long a pause ends a voice command.' },
  { tab: 'voicesatellite', title: 'Debug logging',
    desc: 'Show Voice Satellite debug info in the browser console.' },
  { tab: 'voicesatellite', title: 'Voice Satellite version',
    desc: 'The integration version installed in Home Assistant.' },
  { tab: 'voicesatellite', title: 'Wake word engine', sub: 'Wake Word',
    desc: 'Where detection runs and which engine listens.' },
  { tab: 'voicesatellite', title: 'Wake word sensitivity', sub: 'Wake Word',
    desc: 'How easily the wake word triggers.' },
  { tab: 'voicesatellite', title: 'Wake word noise gate', sub: 'Wake Word',
    desc: 'Skip local wake word inference while the room is quiet, saving CPU.' },
  { tab: 'voicesatellite', title: 'Stop word interruption', sub: 'Wake Word',
    desc: 'Say the stop word to interrupt responses.' },
  { tab: 'voicesatellite', title: 'Wake word 1', sub: 'Wake Word',
    desc: 'The word that starts a voice command.' },
  { tab: 'voicesatellite', title: 'Wake word 2', sub: 'Wake Word',
    desc: 'A second wake word, answered by Assist pipeline 2.' },
  { tab: 'voicesatellite', title: 'Cached models', sub: 'Wake Word',
    desc: 'Re-download from Home Assistant. Use after re-publishing a model.' },
  { tab: 'voicesatellite', title: 'Skin', sub: 'Appearance',
    desc: 'The look of the voice assistant overlay.' },
  { tab: 'voicesatellite', title: 'Theme mode', sub: 'Appearance',
    desc: 'Light or dark rendering of the overlay.' },
  { tab: 'voicesatellite', title: 'Reactive activity bar', sub: 'Appearance',
    desc: 'The activity bar reacts to audio. NOT RECOMMENDED for low-power devices like the Echo Show.' },
  { tab: 'voicesatellite', title: 'Reactive bar update rate', sub: 'Appearance',
    desc: 'How often the activity bar redraws. Higher is smoother and uses more CPU.' },
  { tab: 'voicesatellite', title: 'Text scale', sub: 'Appearance',
    desc: 'The size of the overlay text.' },
  { tab: 'voicesatellite', title: 'Required system permissions',
    desc: 'Microphone and the other grants wake word detection needs.',
    heading: 'Required system permissions' },
  { tab: 'kiosk', title: 'Required system permissions',
    desc: 'The grants the kiosk and lockdown protections lean on.',
    heading: 'Required system permissions' },
  { tab: 'lockdown', title: 'Required system permissions',
    desc: 'The grants the lockdown protections lean on.',
    heading: 'Required system permissions' },
  { tab: 'launcher', title: 'Required system permissions',
    desc: 'The grants Return automatically leans on.',
    heading: 'Required system permissions' },
  { tab: 'screenaudio', title: 'Master volume',
    desc: 'The device volume the media and assistant faders scale under.' },
  { tab: 'screensaver', title: 'Small clock',
    desc: 'A clock widget in a corner of the screensaver.',
    key: 'screensaver.widgets' },
  { tab: 'screensaver', title: 'Battery',
    desc: "A battery widget in a corner of the screensaver: this device's own charge.",
    key: 'screensaver.widgets' },
  { tab: 'device', title: 'Permissions Manager',
    desc: 'Every Android grant the app can use, with its status: microphone, camera, notifications, unrestricted battery, display over other apps, modify system settings, system UI guard, device admin, all files access, usage access and location.',
    heading: 'Permissions Manager' },
  { tab: 'device', title: 'Export configuration',
    desc: "Download every setting and the page's local storage." },
  { tab: 'device', title: 'Import configuration',
    desc: "Replace this device's settings from an exported file." },
];
// The nav's own entries, so pages are findable alongside their settings.
export const SEARCH_PAGES = [...document.querySelectorAll('#tabs button')].map((b) => ({
  tab: b.dataset.tab,
  title: b.querySelector('.nav-title').textContent.trim(),
  desc: (b.querySelector('.nav-sub')?.textContent || '').trim(),
  isPage: true,
}));

export function searchSettingsIndex(query) {
  const q = query.trim().toLowerCase();
  if (!q) return [];
  const terms = q.split(/\s+/);
  const defs = (state.settings || [])
    .filter((s) => !s.hidden && SEARCH_CATEGORY_TABS[s.category])
    .map((s) => ({ tab: SEARCH_CATEGORY_TABS[s.category], title: s.title,
      desc: s.description || '', key: s.key }));
  // The second-level pages, findable like the tabs are; a hit lands on the
  // entry row that opens them. Mirrors buildSettingsSearchIndex on the device.
  const subs = [];
  const addSub = (tab, name) => {
    if (!tab || subs.some((o) => o.tab === tab && o.title === name)) return;
    subs.push({ tab, title: name, desc: (state.subpageHints || {})[name] || '',
      entry: name, isPage: true });
  };
  (state.settings || []).forEach((s) => {
    if (s.hidden || !s.subpage) return;
    addSub(SEARCH_CATEGORY_TABS[s.category], s.subpage);
  });
  // Pages no setting declares, because their rows are live entity controls.
  DEFLESS_SUBPAGES.forEach(([tab, name]) => addSub(tab, name));
  const hits = [];
  const shown = (key) => (state.settings || []).some((s) => s.key === key && !s.hidden);
  [...SEARCH_PAGES, ...subs, ...defs, ...SEARCH_EXTRAS].forEach((e, order) => {
    if (e.onlyWith && !shown(e.onlyWith)) return;
    const title = e.title.toLowerCase();
    const hay = `${title} ${e.desc.toLowerCase()}`;
    if (!terms.every((t) => hay.includes(t))) return;
    // Title prefix beats title match beats description-only, then the nav
    // order keeps groups contiguous — the same ranking as the device.
    const score = title.startsWith(q) ? 0
      : terms.every((t) => title.includes(t)) ? 1 : 2;
    hits.push({ e, rank: TABS.indexOf(e.tab), score, order });
  });
  hits.sort((a, b) => a.rank - b.rank || a.score - b.score || a.order - b.order);
  return hits.map((h) => h.e);
}

export let searchReturnTab = null;

// Cross-module writes to an imported let are a TypeError under ES modules;
// the one outside writer (showTab clearing an abandoned search) goes
// through this instead.
export function clearSearchReturnTab() { searchReturnTab = null; }
export function renderSearch() {
  const q = $('#settingsSearch').value.trim();
  document.querySelector('.side-search')
    .classList.toggle('has-text', $('#settingsSearch').value.length > 0);
  $('#sidebar').classList.toggle('searching', !!q);
  if (!q) {
    if (searchReturnTab) {
      const back = searchReturnTab;
      searchReturnTab = null;
      showTab(back, { push: false });
    }
    return;
  }
  if (!searchReturnTab) {
    // The whole path, so leaving the search puts an open second-level page
    // back the way it was.
    searchReturnTab = currentPath || 'dashboard';
    document.querySelectorAll('.tab').forEach((t) =>
      t.classList.toggle('active', t.id === 'tab-search'));
    $('#pageTitle').textContent = 'Search results';
  }
  const results = searchSettingsIndex(q);
  const build = (root) => {
    root.innerHTML = '';
    if (!results.length) {
      const card = document.createElement('div');
      card.className = 'card search-results';
      const d = document.createElement('div');
      d.className = 'desc';
      d.style.cssText = 'color:var(--muted); padding:12px 0;';
      d.textContent = `No settings match "${q}".`;
      card.appendChild(d);
      root.appendChild(card);
      return;
    }
    let tab = null;
    let card = null;
    for (const e of results) {
      if (e.tab !== tab) {
        tab = e.tab;
        const h = document.createElement('h2');
        h.className = 'card-title';
        h.textContent = TAB_TITLES[tab] || tab;
        root.appendChild(h);
        card = document.createElement('div');
        card.className = 'card search-results';
        root.appendChild(card);
      }
      const row = document.createElement('div');
      row.className = 'row';
      const info = document.createElement('div');
      info.className = 'info';
      const name = document.createElement('div');
      name.className = 'name';
      // The first match emphasized, so each row says why it is here.
      const i = e.title.toLowerCase().indexOf(q);
      if (i < 0) name.textContent = e.title;
      else {
        name.append(document.createTextNode(e.title.slice(0, i)));
        const b = document.createElement('b');
        b.textContent = e.title.slice(i, i + q.length);
        name.appendChild(b);
        name.append(document.createTextNode(e.title.slice(i + q.length)));
      }
      const desc = document.createElement('div');
      desc.className = 'desc';
      desc.textContent = e.desc;
      info.append(name, desc);
      row.appendChild(info);
      row.addEventListener('click', () => jumpToResult(e));
      card.appendChild(row);
    }
  };
  build($('#tab-search'));
  build($('#sideResults'));
}

// A definition row gated off by its dependsOn chain has no element to land
// on; climb to the nearest parent that is rendered — the setting that turns
// the found one on. Mirrors resolveSearchAnchor on the device.
export function resolveSearchAnchor(e) {
  // A second-level page as a result lands on the entry row that opens it,
  // the way a tab result lands on the top of its tab.
  if (!e.key) return e.entry ? e : e.isPage ? null : e;
  const byKey = Object.fromEntries((state.settings || []).map((s) => [s.key, s]));
  const shown = (s) => {
    if (s.hidden) return false;
    if (!s.dependsOn) return true;
    const dep = byKey[s.dependsOn];
    if (!dep) return true;
    return dependsSatisfiedBy(dep.value, s.dependsOnValue) && shown(dep);
  };
  let s = byKey[e.key];
  while (s && !shown(s)) s = s.dependsOn ? byKey[s.dependsOn] : null;
  // The subpage comes from the row actually landed on: a gated row resolves
  // up to its parent, which may sit on a different page than the hit did.
  return s ? { key: s.key, sub: s.subpage } : null;
}

export function findSearchAnchor(tab, a) {
  const root = document.getElementById(`tab-${tab}`);
  if (!root || !a) return null;
  if (a.key) return root.querySelector(`[data-key="${a.key}"]`);
  if (a.entry) return root.querySelector(`[data-subpage-entry="${a.entry}"]`);
  for (const n of root.querySelectorAll('.row .info .name')) {
    if (n.textContent === a.title) return n.closest('.row');
  }
  if (a.heading) {
    for (const h of root.querySelectorAll('h2.card-title')) {
      if (h.textContent === a.heading) return h.nextElementSibling;
    }
  }
  return null;
}

export function jumpToResult(e) {
  const anchor = resolveSearchAnchor(e);
  searchReturnTab = null;
  $('#sidebar').classList.remove('searching');
  setNav(false);
  // A row that moved onto a second-level page is only in the DOM once that
  // page is open, so the jump opens it rather than landing on a hidden row.
  const sub = anchor?.sub || e.sub;
  showTab(sub ? `${e.tab}/${sub}` : e.tab);
  if (!anchor) return;
  // Tabs that render async may not have the row yet; look for a moment.
  let tries = 14;
  const seek = () => {
    const el = findSearchAnchor(e.tab, anchor);
    if (!el) {
      if (--tries > 0) setTimeout(seek, 150);
      return;
    }
    el.scrollIntoView({ behavior: 'smooth', block: 'center' });
    el.classList.remove('search-hit');
    void el.offsetWidth; // restart the animation on a repeat landing
    el.classList.add('search-hit');
    setTimeout(() => el.classList.remove('search-hit'), 1700);
  };
  seek();
}

$('#settingsSearch').addEventListener('input', renderSearch);
// Tapping back into a field that still holds a query reopens the results,
// like the device's field does.
$('#settingsSearch').addEventListener('focus', (ev) => {
  if (ev.target.value.trim()) renderSearch();
});
$('#settingsSearchClear').addEventListener('click', () => {
  $('#settingsSearch').value = '';
  renderSearch();
  $('#settingsSearch').focus();
});
$('#settingsSearch').addEventListener('keydown', (ev) => {
  if (ev.key === 'Escape') {
    ev.target.value = '';
    renderSearch();
    ev.target.blur();
  }
});

$('#tabs').addEventListener('click', (e) => {
  const btn = e.target.closest('button');
  if (btn) { showTab(btn.dataset.tab); setNav(false); }
});

// The app mark, in either bar, goes home to Overview.
document.querySelectorAll('[data-home]').forEach((el) =>
  el.addEventListener('click', () => { showTab('dashboard'); setNav(false); }));

// Back/forward, and an address typed by hand.
window.addEventListener('hashchange', () =>
  showTab(decodeURIComponent(location.hash.slice(1)), { push: false }));
