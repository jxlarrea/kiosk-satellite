import { tabHidden } from './headless.js';
import { navigationText, t, settingsPageText, pluginText } from './localization.js';
import { $, depSatisfied, state } from './core.js';
import { permissionSpecs } from './permissions.js';
import { loadPlugins, pluginSearchState, refreshPluginSearchState } from './plugins.js';
import { TABS, TAB_TITLES, currentPath, followRoute, setNav, showTab } from './tabs.js';
import { REALTIME_PROVIDERS, providerKeys } from './vs_native.js';

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
  'Sendspin': 'sendspin', 'DLNA': 'dlna', 'Intercom': 'intercom', 'Alarms': 'alarms', 'Calendar': 'calendar',
  'ESPHome': 'esphome',
  'Device': 'device', 'Cameras': 'cameras', 'Gestures': 'gestures',
  'Fleet': 'fleet', 'Plugins': 'plugins', 'LED Control': 'leds',
};
// Second-level pages no setting declares: their rows come from the Voice
// Satellite integration, not from the definitions, so the page that draws
// them names them. Mirrors the two pages VsControlsSection places on the
// device.
export const DEFLESS_SUBPAGES = [['homeassistant', 'Custom Pages'],
  ['browser', 'URL Filter'],
  ['voicesatellite', 'Appearance'],
  ['device', 'Hardware'], ['device', 'Home Assistant'], ['device', 'WebView']];
export const SEARCH_EXTRAS = [
  { tab: 'homeassistant', title: 'Share Home Assistant connection', sub: 'Custom Pages',
    anchor: 'ha.custom_pages_socket',
    desc: "Custom pages talk to Home Assistant through the kiosk's connection, with no token in the page." },
  { tab: 'homeassistant', title: 'Add page', sub: 'Custom Pages', anchor: 'x:custom_pages',
    desc: 'Add HTML pages from the Home Assistant www folder or another server to pick them like a dashboard.' },
  { tab: 'homeassistant', title: 'Custom page guide', sub: 'Custom Pages', anchor: 'x:custom_pages_docs',
    desc: 'How to build a page that talks to Home Assistant.' },
  { tab: 'browser', title: 'Add rule', sub: 'URL Filter', anchor: 'x:url_filter',
    desc: "Links or pages that match a Block rule don't load. Add an Allow only rule to load only the pages it matches." },
  { tab: 'browser', title: 'Show blocked page notice', sub: 'URL Filter',
    anchor: 'browser.url_filter_notice',
    desc: "Show a short notice with the rule's name when a page is blocked." },
  { tab: 'plugins', title: 'Enable Plugins',
    desc: 'Plugins add additional community developed features to Kiosk Satellite.', anchor: 'x:plugins:master' },
  { tab: 'plugins', title: 'Browse plugins',
    desc: 'Find plugins made by the community', anchor: 'x:plugins:browse' },
  { tab: 'plugins', title: 'Add plugin',
    desc: 'Install from a GitHub repository', anchor: 'x:plugins:add' },
  { tab: 'plugins', title: 'Install from ZIP',
    desc: 'For developers only: test a local build', anchor: 'x:plugins:zip' },
  { tab: 'plugins', title: 'Create a plugin',
    desc: 'Learn how to create plugins with the Hello World template and documentation.', anchor: 'x:plugins:create' },
  { tab: 'device', title: 'TLS', sub: 'TLS', desc: 'Connection encryption and certificates' },
  { tab: 'calendar', title: 'Add a calendar',
    desc: 'Add the Home Assistant calendars to show in Settings > Calendar.', anchor: 'x:calendar_add' },
  { tab: 'calendar', title: 'Manage the calendar using Voice Satellite',
    desc: 'Needs the Kiosk Satellite calendar blueprint and an LLM conversation agent in Home Assistant.', anchor: 'x:calendar_voice' },
  { tab: 'alarms', title: 'Manage alarms using Voice Satellite',
    desc: 'Needs the Kiosk Satellite alarms blueprint and an LLM conversation agent in Home Assistant.', anchor: 'x:alarms_voice' },
  { tab: 'sendspin', title: 'Manage music using Voice Satellite', sub: 'Music Library',
    desc: 'Needs the Kiosk Satellite music blueprint and an LLM conversation agent in Home Assistant.', anchor: 'x:library_voice' },
  { tab: 'device', title: 'Learn how we process your data',
    desc: 'What Kiosk Satellite Analytics sends and what it never sends.', sub: 'Kiosk Satellite Analytics', anchor: 'x:analytics_docs' },
  { tab: 'device', title: 'Install from file',
    desc: 'Upload a Kiosk Satellite APK through the remote admin and install it.', sub: 'Updates', anchor: 'x:update_upload' },
  { tab: 'device', title: 'Custom repository guide',
    desc: 'How to host the releases file and the APKs on your own network.', sub: 'Updates', anchor: 'x:update_docs' },
  { tab: 'device', title: 'Shizuku access',
    desc: 'Checking availability', sub: 'Shizuku', anchor: 'x:shizuku:permission' },
  { tab: 'device', title: 'Test connection',
    desc: 'Read the process identity without changing the device.', sub: 'Shizuku', anchor: 'x:shizuku:identity' },
  { tab: 'device', title: 'Grant all permissions',
    desc: 'Grant all permissions used by KS, including features that are currently off.', sub: 'Shizuku', anchor: 'x:shizuku:grantAll' },
  { tab: 'device', title: 'Set up Shizuku',
    desc: 'Read installation and startup instructions.', sub: 'Shizuku', anchor: 'x:shizuku:setup' },
  ...permissionSpecs(() => false).map(spec => ({tab:'device', sub:'Shizuku',
    title:spec.name, desc:spec.held, anchor:`x:shizuku:${spec.key}`})),
  // Fleet Management: the hand-built cards on the leader's page.
  { tab: 'fleet', title: 'Followers',
    desc: 'The kiosks this one leads, their state and a way to add one.',
    heading: 'Followers' },
  { tab: 'fleet', title: 'Profiles',
    desc: 'The named lists a follower can be given: categories, credentials, the dashboard and the settings left out.',
    heading: 'Profiles' },
  { tab: 'fleet', title: 'Update the fleet',
    desc: 'Install the release offered to each follower, then here.',
    heading: 'Updates' },
  // Intercom: the hand-built roster under the definition rows.
  { tab: 'intercom', title: 'Kiosks',
    desc: 'Known kiosks and whether each can take a call.',
    heading: 'Kiosks' },
  { tab: 'sendspin', title: 'Speakers', sub: 'Sonos',
    desc: 'The Sonos speakers this device knows, a search of the network and an address field.' },
  { tab: 'home', title: 'Home screen status',
    desc: 'Whether Kiosk Satellite is the device home screen, and where to '
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
  { tab: 'camera', title: 'Required system permissions', sub: 'Person Sensor',
    desc: "The Log access grant the device's person sensor needs.",
    heading: 'Required system permissions', onlyWith: 'person.sensor' },
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
  { tab: 'voicesatellite', title: 'Assigned satellite', runtime: 'dashboard',
    desc: 'The assist_satellite entity this kiosk identifies as in Home Assistant.' },
  { tab: 'voicesatellite', title: 'Auto start', runtime: 'dashboard',
    desc: 'Auto start Voice Satellite on dashboard load.' },
  { tab: 'voicesatellite', title: 'Assist pipeline 1', runtime: 'dashboard',
    desc: 'The Assist pipeline voice commands run through.' },
  { tab: 'voicesatellite', title: 'Assist pipeline 2', runtime: 'dashboard',
    desc: 'The pipeline used when the second wake word triggers.' },
  { tab: 'voicesatellite', title: 'Engine', runtime: 'dashboard',
    desc: 'Start or Stop the Voice Satellite engine.' },
  { tab: 'voicesatellite', title: 'Mute', runtime: 'dashboard',
    desc: 'Stop listening for wake words.' },
  { tab: 'voicesatellite', title: 'Finished speaking detection', runtime: 'dashboard',
    desc: 'How long a pause ends a voice command.' },
  { tab: 'voicesatellite', title: 'Disable muted microphone warning', runtime: 'dashboard',
    desc: 'Hide the muted microphone warning at startup and whenever the satellite microphone is muted.' },
  { tab: 'voicesatellite', title: 'Debug logging', runtime: 'dashboard',
    desc: 'Show Voice Satellite debug info in the browser console.' },
  { tab: 'voicesatellite', title: 'Voice Satellite version', runtime: 'dashboard',
    desc: 'The integration version installed in Home Assistant.' },
  { tab: 'voicesatellite', title: 'Wake word engine', runtime: 'dashboard', sub: 'Wake Word',
    desc: 'Where detection runs and which engine listens.' },
  { tab: 'voicesatellite', title: 'Wake word sensitivity', runtime: 'dashboard', sub: 'Wake Word',
    desc: 'How easily the wake word triggers.' },
  { tab: 'voicesatellite', title: 'Wake word noise gate', runtime: 'dashboard', sub: 'Wake Word',
    desc: 'Skip local wake word inference while the room is quiet, saving CPU.' },
  { tab: 'voicesatellite', title: 'Stop word interruption', runtime: 'dashboard', sub: 'Wake Word',
    desc: 'Say the stop word to interrupt responses.' },
  { tab: 'voicesatellite', title: 'Wake word 1', runtime: 'dashboard', sub: 'Wake Word',
    desc: 'The word that starts a voice command.' },
  { tab: 'voicesatellite', title: 'Wake word 2', runtime: 'dashboard', sub: 'Wake Word',
    desc: 'A second wake word, answered by Assist pipeline 2.' },
  { tab: 'voicesatellite', title: 'Cached models', runtime: 'dashboard', sub: 'Wake Word',
    desc: 'Re-download from Home Assistant. Use after re-publishing a model.' },
  { tab: 'voicesatellite', title: 'Skin', runtime: 'dashboard', sub: 'Appearance',
    desc: 'The look of the voice assistant overlay.' },
  { tab: 'voicesatellite', title: 'Theme mode', runtime: 'dashboard', sub: 'Appearance',
    desc: 'Light or dark rendering of the overlay.' },
  { tab: 'voicesatellite', title: 'Reactive activity bar', runtime: 'dashboard', sub: 'Appearance',
    desc: 'The activity bar reacts to audio. NOT RECOMMENDED for low-power devices like the Echo Show.' },
  { tab: 'voicesatellite', title: 'Reactive bar update rate', runtime: 'dashboard', sub: 'Appearance',
    desc: 'How often the activity bar redraws. Higher is smoother and uses more CPU.' },
  { tab: 'voicesatellite', title: 'Text scale', runtime: 'dashboard', sub: 'Appearance',
    desc: 'The size of the overlay text.' },
  // Native Voice Satellite's hand-built rows (vs_native.js).
  { tab: 'voicesatellite', title: 'Custom Models', sub: 'Wake Word', runtime: 'native',
    desc: 'Add your own wake word models for any engine.', anchor: 'x:vs_custom_models' },
  { tab: 'voicesatellite', title: 'Status', runtime: 'native',
    desc: 'Whether Voice Satellite is listening and how Home Assistant knows this kiosk.' },
  { tab: 'voicesatellite', title: 'Assistant 1', sub: 'Assistant', runtime: 'native',
    desc: 'Answers wake word 1.' },
  { tab: 'voicesatellite', title: 'Assistant 2', sub: 'Assistant', runtime: 'native',
    desc: 'Answers wake word 2.' },
  { tab: 'voicesatellite', title: 'Finished speaking detection', sub: 'Assistant', runtime: 'native',
    desc: 'How long a pause ends a voice command.' },
  { tab: 'voicesatellite', title: 'Wake word 1', sub: 'Wake Word', runtime: 'native',
    desc: 'The word that starts a voice command.' },
  { tab: 'voicesatellite', title: 'Wake word 2', sub: 'Wake Word', runtime: 'native',
    desc: 'A second wake word, answered by Assistant 2.' },
  { tab: 'voicesatellite', title: 'Run from the dashboard again', runtime: 'native',
    desc: 'Go back to the Voice Satellite integration. Nothing set here is lost.' },
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
  { tab: 'screensaver', title: 'Weather forecast',
    desc: 'A forecast widget in a corner of the screensaver: the coming days, with their highs and lows.',
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

function pluginSearchEntries() {
  return (pluginSearchState?.plugins || []).flatMap(plugin => [
    {tab:'plugins', sub:plugin.id, title:plugin.name, desc:plugin.description || '', anchor:`plugin:${plugin.id}:intro`},
    ...(plugin.capabilities?.includes('shizuku') ? [{tab:'plugins', sub:plugin.id, title:pluginText('Shizuku access'), desc:'', englishAlias:'Shizuku access', anchor:`plugin:${plugin.id}:shizuku`}] : []),
    ...(plugin.settings || []).map(setting => ({tab:'plugins', sub:plugin.id,
      title:setting.title, desc:setting.description || '', anchor:`plugin:${plugin.id}:setting:${setting.key}`})),
    ...(plugin.buttons || []).map(button => ({tab:'plugins', sub:plugin.id,
      title:button.title, desc:button.description || '', anchor:`plugin:${plugin.id}:button:${button.id}`})),
    ...(plugin.commands || []).map(action => ({tab:'plugins', sub:plugin.id,
      title:action.title, desc:[pluginText('Gestures'), plugin.actionOptions?.[action.id]?.drawer && pluginText('Kiosk drawer'),
        plugin.actionOptions?.[action.id]?.homeAssistant && pluginText('Home Assistant')].filter(Boolean).join(' · '),
      anchor:`plugin:${plugin.id}:action:${action.id}`})),
  ]);
}

export function searchSettingsIndex(query) {
  const q = query.trim().toLowerCase();
  if (!q) return [];
  const terms = q.split(/\s+/);
  const defs = (state.settings || [])
    .filter((s) => !s.hidden && SEARCH_CATEGORY_TABS[s.category])
    .map((s) => ({ tab: SEARCH_CATEGORY_TABS[s.category], title: s.title,
      desc: s.description || '', key: s.key,
      englishAlias: `${s.englishTitle || ''} ${s.englishDescription || ''}` }));
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
  const runtime = (state.settings || []).find((s) => s.key === 'voice.runtime')?.value === 'native'
    ? 'native' : 'dashboard';
  [...SEARCH_PAGES.map(page => ({...page, title: navigationText(page.title), desc: navigationText(page.desc), englishAlias: `${page.title} ${page.desc}`})), ...subs, ...defs, ...SEARCH_EXTRAS, ...pluginSearchEntries()].forEach((raw, order) => {
    if (typeof raw.title !== 'string' || !raw.title.trim()) return;
    if (tabHidden(raw.tab)
      || document.querySelector(`#tabs button[data-tab="${raw.tab}"]`)?.classList.contains('hidden')) return;
    const e = {...raw, desc: typeof raw.desc === 'string' ? raw.desc : ''};
    if (SEARCH_EXTRAS.includes(raw) || subs.includes(raw)) {
      e.englishAlias = `${e.englishAlias || ''} ${e.title} ${e.desc}`;
      e.title = settingsPageText(e.tab, e.title);
      e.desc = settingsPageText(e.tab, e.desc);
      if (e.tab === 'voicesatellite' && e.heading) e.heading = settingsPageText(e.tab, e.heading);
    }
    if (e.onlyWith && !shown(e.onlyWith)) return;
    // Voice Satellite draws one of two pages: the integration's live rows
    // from the dashboard, or the kiosk's own settings when native.
    if (e.runtime && e.runtime !== runtime) return;
    if (e.key?.startsWith('voice.') && runtime !== 'native') return;
    const title = e.title.toLowerCase();
    const hay = `${title} ${e.desc.toLowerCase()} ${(e.englishAlias || '').toLowerCase()}`;
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
    // Read plugin manifests for search without opening pages or invoking controls.
    refreshPluginSearchState().then(() => {
      if (searchReturnTab && $('#settingsSearch').value.trim()) renderSearch();
    }).catch(() => {});
    // The whole path, so leaving the search puts an open second-level page
    // back the way it was.
    searchReturnTab = currentPath || 'dashboard';
    document.querySelectorAll('.tab').forEach((t) =>
      t.classList.toggle('active', t.id === 'tab-search'));
    $('#pageTitle').textContent = t('settingsSearchResults');
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
      d.textContent = t('settingsSearchEmpty', { query: q });
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
        h.textContent = navigationText(TAB_TITLES[tab] || tab);
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
  if (e.tab === 'plugins' && pluginSearchState?.enabled === false) {
    return {anchor:'x:plugins:master', sub:''};
  }
  // A second-level page as a result lands on the entry row that opens it,
  // the way a tab result lands on the top of its tab.
  if (!e.key) return e.entry ? e : e.isPage ? null : e;
  const byKey = Object.fromEntries((state.settings || []).map((s) => [s.key, s]));
  const shown = (s) => !s.hidden && depSatisfied(s, byKey);
  let s = byKey[e.key];
  // A realtime provider's settings live in its dialog: land on its row.
  for (const provider of Object.keys(REALTIME_PROVIDERS)) {
    const keys = providerKeys(provider);
    if (keys.includes(e.key)) s = byKey[keys[0]];
  }
  while (s && !shown(s)) s = s.dependsOn ? byKey[s.dependsOn] : null;
  // The subpage comes from the row actually landed on: a gated row resolves
  // up to its parent, which may sit on a different page than the hit did.
  return s ? { key: s.key, sub: s.subpage } : null;
}

export function findSearchAnchor(tab, a) {
  const root = document.getElementById(`tab-${tab}`);
  if (!root || !a) return null;
  if (a.anchor) return [...root.querySelectorAll('[data-search-id]')].find(el => el.dataset.searchId === a.anchor) || null;
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

export async function jumpToResult(e) {
  // Build the plugin page before resolving its target, including a disabled master switch.
  if (e.tab === 'plugins') await loadPlugins();
  const anchor = resolveSearchAnchor(e);
  searchReturnTab = null;
  $('#sidebar').classList.remove('searching');
  setNav(false);
  // A row that moved onto a second-level page is only in the DOM once that
  // page is open, so the jump opens it rather than landing on a hidden row.
  const sub = anchor?.sub ?? e.sub;
  showTab(sub ? `${e.tab}/${sub}` : e.tab, {refresh:e.tab !== 'plugins'});
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

window.addEventListener('popstate', followRoute);
window.addEventListener('hashchange', followRoute);
