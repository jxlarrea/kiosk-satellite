import { loadCameras } from './cameras.js';
import { $, state } from './core.js';
import { loadAboutInfo, loadDeviceInfo } from './device.js';
import { loadFiles } from './files.js';
import { fleetShown } from './fleetsync.js';
import { loadGestures } from './gestures.js';
import { subpageIcon } from './icons.js';
import { loadLogs } from './logs.js';
import { overviewShown } from './overview.js';
import {
  updateAmbientDisplayNotice,
  updateBrightnessGrantNotices,
} from './panels.js';
import { clearSearchReturnTab, searchReturnTab } from './search.js';

/* ---- Tabs ---- */
// Addressable, because this is a page in a browser and behaves like one: the
// tab lives in the URL, so a reload keeps you where you were, Back goes back,
// and #settings can be bookmarked or handed to someone. Everything is served
// from one root, so without this a reload always dumped you on the dashboard.
export const TABS = ['dashboard', 'homeassistant', 'voicesatellite', 'browser', 'kiosk', 'lockdown', 'home', 'launcher', 'screenaudio', 'screensaver',
  'camera', 'sendspin', 'cameras', 'dlna', 'esphome', 'files', 'gestures', 'device', 'fleet', 'about', 'logs'];
// Old bookmarks from before the tabs were consolidated keep landing
// somewhere sensible.
export const LEGACY_TABS = { screen: 'screenaudio', audio: 'screenaudio', remote: 'device', console: 'logs', btproxy: 'esphome', mqtt: 'esphome' };
export const TAB_TITLES = {
  dashboard: 'Overview', browser: 'Web Browsing',
  kiosk: 'Kiosk Mode', lockdown: 'Lockdown Mode', launcher: 'App Launcher', home: 'Home Launcher', screenaudio: 'Screen & Audio', screensaver: 'Screensaver',
  camera: 'Camera',
  homeassistant: 'Home Assistant Setup',
  voicesatellite: 'Voice Satellite',
  cameras: 'Camera Streams',
  sendspin: 'Media Player',
  dlna: 'DLNA Renderer', esphome: 'ESPHome',
  files: 'File Manager', gestures: 'Gestures',
  device: 'Device', fleet: 'Fleet Management', about: 'About', logs: 'Logs',
};

// The row that opens a second-level page (One UI, and what the device does
// with the same `subpage` field). The page's panel is parked on the tab
// rather than inline, so opening it can hide the rest of the tab and the
// search can still find its rows under #tab-<name>. Module scope because
// the Voice Satellite page places entry rows of its own.
export function subpageEntry(tab, sub) {
  const row = document.createElement('div');
  row.className = 'row subpage-entry';
  row.dataset.subpageEntry = sub;
  // The page's glyph ahead of the name, the same one its title wears, so
  // the row and the page it opens answer to each other.
  const icon = subpageIcon(sub);
  const info = document.createElement('div');
  info.className = 'info';
  const name = document.createElement('div');
  name.className = 'name';
  name.textContent = sub;
  const desc = document.createElement('div');
  desc.className = 'desc';
  desc.textContent = (state.subpageHints || {})[sub] || '';
  info.append(name, desc);
  const chev = document.createElement('span');
  chev.className = 'chev';
  chev.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"'
    + ' stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
    + '<path d="m9 18 6-6-6-6"/></svg>';
  row.append(icon, info, chev);
  row.addEventListener('click', () => showTab(`${tab}/${sub}`));
  return row;
}

// Show (or leave) a tab's second-level page. Returns the subpage actually
// opened: a name with no panel behind it — a stale bookmark, or a hash typed
// before loadSettings() built the panels — falls back to the tab itself.
export function applySubpageView(tab, sub) {
  const tabEl = document.getElementById(`tab-${tab}`);
  if (!tabEl) return '';
  const panels = tabEl.querySelectorAll(':scope > .subpage');
  let shown = '';
  panels.forEach((p) => {
    const open = !!sub && p.dataset.subpage === sub;
    p.classList.toggle('open', open);
    if (open) shown = sub;
  });
  tabEl.classList.toggle('sub-open', !!shown);
  return shown;
}

// The tab the page is on, subpage included ('homeassistant/User Interface').
// Read back when a re-render has to restore the view, and by the search when
// it needs somewhere to return to.
export let currentPath = 'dashboard';

// Cross-module writes to an imported let are a TypeError under ES modules;
// the one outside writer (loadSettings retreating from a stale subpage)
// goes through this instead.
export function setCurrentPath(path) { currentPath = path; }

// Where the parent page was scrolled to when a second-level page opened over
// it. Coming back lands on the entry row that was tapped instead of at the
// top of a long page, which is where the browser would otherwise leave it:
// hiding the parent's cards collapses the page and the scroll goes with them.
export let subpageReturnScroll = 0;

export function showTab(name, { push = true } = {}) {
  // Picking a tab while searching leaves the search: clear the field so the
  // results do not linger under a pane the person just chose over them.
  const search = document.getElementById('settingsSearch');
  if (search && search.value && $('#sidebar').classList.contains('searching')) {
    search.value = '';
    $('#sidebar').classList.remove('searching');
    document.querySelector('.side-search')?.classList.remove('has-text');
    clearSearchReturnTab();
  }
  // A second-level page rides in the path after its tab, so it is addressable
  // like everything else here: reloadable, bookmarkable, and left by the
  // browser's own Back.
  const slash = name.indexOf('/');
  let sub = slash < 0 ? '' : name.slice(slash + 1);
  name = slash < 0 ? name : name.slice(0, slash);
  name = LEGACY_TABS[name] || name;
  const tab = TABS.includes(name) ? name : 'dashboard';
  if (tab !== name) sub = '';
  document.querySelectorAll('#tabs button').forEach((b) =>
    b.classList.toggle('active', b.dataset.tab === tab));
  document.querySelectorAll('.tab').forEach((t) =>
    t.classList.toggle('active', t.id === `tab-${tab}`));
  // Captured before the view changes: opening a page hides the parent's
  // cards, which collapses the document and takes the scroll with it.
  const scroller = document.scrollingElement || document.documentElement;
  const wasTab = currentPath.split('/')[0];
  const wasSub = currentPath.slice(wasTab.length + 1);
  const sameTab = wasTab === tab;
  if (sameTab && !wasSub && sub) subpageReturnScroll = scroller.scrollTop;
  sub = applySubpageView(tab, sub);
  if (sub || !sameTab) {
    // A page opens at its top: a second-level page however far down its
    // entry row sat, and a freshly picked tab however far the last one was
    // scrolled (its content is gone, so the offset means nothing here).
    scroller.scrollTop = 0;
  } else if (wasSub) {
    const back = subpageReturnScroll;
    subpageReturnScroll = 0;
    // After the frame that puts the parent's cards back, or there is
    // nothing tall enough to scroll to yet.
    requestAnimationFrame(() => { scroller.scrollTop = back; });
  }
  currentPath = sub ? `${tab}/${sub}` : tab;
  const titleEl = $('#pageTitle');
  if (sub) {
    // Second level: the page wears the entry row's title behind a back
    // arrow, the shape the device's app bar takes.
    titleEl.textContent = sub;
    const back = document.createElement('button');
    back.type = 'button';
    back.className = 'title-back';
    back.setAttribute('aria-label', 'Back');
    back.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"'
      + ' stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
      + '<path d="M19 12H5"/><path d="m12 19-7-7 7-7"/></svg>';
    back.addEventListener('click', () => showTab(tab));
    // Then the entry row's glyph, bare, the way a tab's title wears the
    // nav rail's.
    titleEl.prepend(back, subpageIcon(sub));
  } else {
    // The nav rail's glyph, bare, same drawing, no disc.
    titleEl.textContent = TAB_TITLES[tab];
    const glyph = document.querySelector(`#tabs button[data-tab="${tab}"] svg`);
    if (glyph) titleEl.prepend(glyph.cloneNode(true));
  }
  if (push && decodeURIComponent(location.hash.slice(1)) !== currentPath) {
    location.hash = currentPath;
  }
  // Nothing on the Overview is a setting: it is re-read on every visit.
  if (tab === 'dashboard' && !sameTab) overviewShown();
  if (tab === 'logs') loadLogs();
  if (tab === 'files') loadFiles();
  if (tab === 'gestures') loadGestures();
  if (tab === 'cameras') loadCameras();
  if (tab === 'device') loadDeviceInfo();
  // The fleet is other kiosks' state: re-read on every visit and polled
  // while the page stays open.
  if (tab === 'fleet') fleetShown();
  if (tab === 'about') loadAboutInfo();
  // Both notices track something changed on the tablet in Android's own
  // settings, so opening the tab is the moment to re-ask rather than
  // trusting whatever was true when the page loaded.
  if (tab === 'screenaudio') {
    updateBrightnessGrantNotices();
    updateAmbientDisplayNotice();
  }
}

// Mobile drawer: the hamburger toggles the nav in/out; the backdrop and picking
// a tab close it. On wide screens the nav is a normal bar and these are inert
// (the .open/.show styles live only inside the mobile media query).
export function setNav(open) {
  $('#sidebar').classList.toggle('open', open);
  $('#navBackdrop').classList.toggle('show', open);
  $('#navToggle').setAttribute('aria-expanded', open ? 'true' : 'false');
}
$('#navToggle').addEventListener('click', () =>
  setNav(!$('#tabs').classList.contains('open')));
$('#navBackdrop').addEventListener('click', () => setNav(false));
