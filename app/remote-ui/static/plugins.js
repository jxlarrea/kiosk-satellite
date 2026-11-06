import { pluginError } from './localization.js';
import { deviceText, pluginText, t, messageLanguage } from './localization.js';
import { preserveDraft } from './drafts.js';
import { watchUpdates, receiveUpdate } from './live.js';
import { entitySpec, pickField, pickItem } from './entity_picker.js';
import { cmd } from './core.js';
import { updatePluginCharts } from './plugin-charts.js';
import { updatePluginReadings } from './plugin-readings.js';
import { currentPath, showTab, subpageEntry } from './tabs.js';
import { dashboardField } from './dashboard_picker.js';
import { actionField, cameraViewSpec, fieldVisible, iconField, listSetting, numberControl } from './plugin_lists.js';
import { choiceControl, refreshPluginSetup, setupButtonRow } from './plugin_setup.js';
import { hintRow, introRow, messageBox, modalShell, showToast, swatch } from './widgets.js';
import { SUBPAGE_ICONS, subpageIcon } from './icons.js';
import { marked } from './vendor-marked.js';
import DOMPurify from './vendor-purify.js';

const introText = 'Plugins add additional community developed features to Kiosk Satellite.';
const trustNotice = 'Plugins run code inside Kiosk Satellite and can access app data and granted Android permissions. A faulty or malicious plugin can expose private information or stop the app from working. Only install plugins from authors you trust.';
let busy = false;
const maxZipBytes = 4 * 1024 * 1024;

const LOCKED = 'button:not(.plugin-setup-start),input,select';

// Waits out a save in flight, at most 10 seconds, so a settings button
// press reaches the plugin after the field the user just left.
async function settled() {
  for (let i = 0; busy && i < 200; i++) await new Promise((resolve) => setTimeout(resolve, 50));
}

function element(tag, text, className) {
  const node = document.createElement(tag);
  if (text !== undefined) node.textContent = text;
  if (className) node.className = className;
  return node;
}

export function pluginReadme(source) {
  const node = element('div', undefined, 'plugin-readme');
  node.innerHTML = DOMPurify.sanitize(marked.parse(source.readme || ''), {
    ALLOWED_TAGS: ['p', 'br', 'hr', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote', 'pre', 'code', 'ul', 'ol', 'li', 'strong', 'em', 'del', 'a', 'img', 'table', 'thead', 'tbody', 'tr', 'th', 'td', 'details', 'summary'],
    ALLOWED_ATTR: ['href', 'src', 'alt', 'title', 'start', 'colspan', 'rowspan'],
  });
  for (const el of node.querySelectorAll('a,img')) {
    const attribute = el.tagName === 'A' ? 'href' : 'src';
    try {
      const url = new URL(el.getAttribute(attribute) || '', source.readmeBaseUrl);
      if (url.protocol !== 'https:' || url.username || url.password) throw new Error('Unsupported URL');
      if (attribute === 'href' && url.hostname === 'raw.githubusercontent.com') {
        const [owner, repo, ...path] = url.pathname.slice(1).split('/');
        url.hostname = 'github.com';
        url.pathname = `/${owner}/${repo}/blob/${path.join('/')}`;
      }
      el.setAttribute(attribute, url.href);
      if (attribute === 'href') { el.target = '_blank'; el.rel = 'noopener noreferrer'; }
      else { el.loading = 'lazy'; el.referrerPolicy = 'no-referrer'; }
    } catch (_) { el.removeAttribute(attribute); }
  }
  return node;
}

export let pluginSearchState = null;
let searchStateRequest = null;
export function refreshPluginSearchState() {
  if (!searchStateRequest) {
    searchStateRequest = cmd('getPluginState', {}, {timeoutMs:5000}).then(result => {
      if (!result.ok) throw new Error(result.error);
      pluginSearchState = result.data;
      return result.data;
    }).finally(() => { searchStateRequest = null; });
  }
  return searchStateRequest;
}

// The entry to the selected plugin screensaver's settings, above Widgets
// where the stock modes put theirs. A plugin's settings live on its Plugin
// Manager page, so the row opens that page. Left out while Enable Plugins
// is off, which closes that page. Mirrors the device (settings_screen.dart,
// _pluginScreensaverEntry).
let screensaverEntryRender = 0;
export function renderPluginScreensaverEntry(root, mode) {
  const render = ++screensaverEntryRender;
  const id = /^plugin:([^:]+):/.exec(mode || '')?.[1];
  const place = (pluginState) => {
    if (render !== screensaverEntryRender) return;
    root?.querySelectorAll('[data-plugin-screensaver]').forEach((card) => card.remove());
    const plugin = id && pluginState?.enabled === true && (pluginState.plugins || []).find((p) => p.id === id);
    const anchor = root?.querySelector('[data-subpage-entry="Widgets"]')?.closest('.card');
    if (!plugin || !anchor) return;
    const row = subpageEntry('plugins', plugin.id, { iconName: 'Plugins' });
    row.querySelector('.name').textContent = plugin.name;
    row.querySelector('.desc').textContent = plugin.description || '';
    // The plugin pages are built on first visit: build them before opening one.
    row.addEventListener('click', async (event) => {
      event.stopImmediatePropagation();
      await loadPlugins();
      showTab(`plugins/${plugin.id}`, { refresh: false });
    }, true);
    const card = element('div', undefined, 'card');
    card.dataset.pluginScreensaver = plugin.id;
    card.append(row);
    anchor.before(card);
  };
  // The cached list draws the row at once, then a fresh read catches a
  // plugin or the master switch changed on the device since.
  place(pluginSearchState);
  if (id) refreshPluginSearchState().then(place).catch(() => {});
}

export async function loadPlugins() {
  const root = document.getElementById('tab-plugins');
  if (!root || busy) return;
  busy = true;
  try {
    render(root, await refreshPluginSearchState());
  } catch (error) {
    showToast({ title: pluginText('Plugin Manager'), message: pluginError(error.message), kind: 'error' });
  } finally { busy = false; }
}

function repositoryDialog() {
  return new Promise((resolve) => {
    const modal = modalShell({ title: pluginText('Add plugin'), width: 520 });
    const form = element('form'); form.id = 'plugin-repository-form';
    const row = element('div', undefined, 'row plugin-repository-field');
    const label = element('label', pluginText('Repository URL'), 'info'); label.htmlFor = 'plugin-repository-url';
    const input = element('input'); input.id = 'plugin-repository-url'; input.type = 'url'; input.required = true;
    input.placeholder = 'https://github.com/owner/plugin'; input.autocomplete = 'url';
    row.append(label, input); form.append(row, hintRow(pluginText("Make sure you trust the plugin's author and its code before installing it."))); modal.body.append(form);
    const cancel = element('button', pluginText('Cancel'), 'btn-text');
    cancel.onclick = () => { modal.close(); resolve(null); };
    const preview = element('button', pluginText('Preview'), 'btn-primary'); preview.type = 'submit'; preview.setAttribute('form', form.id);
    form.onsubmit = (event) => { event.preventDefault(); const url = input.value.trim(); modal.close(); resolve(url); };
    modal.foot.append(cancel, preview); input.focus();
  });
}

const SVG = (path) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="${path}"/></svg>`;
const REVIEW_ICONS = {
  version: 'M20.6 13.4 13.4 20.6a2 2 0 0 1-2.8 0L3 13V3h10l7.6 7.6a2 2 0 0 1 0 2.8zM7.5 7.5h.01',
  license: 'M12 3v18M5 21h14M6 7l-3 7a3 3 0 0 0 6 0zM18 7l-3 7a3 3 0 0 0 6 0zM6 7h12',
  listed: 'M9 12l2 2 4-4M12 3l2.4 1.8 3 .2.9 2.9 2.2 2-1 2.9 1 2.9-2.2 2-.9 2.9-3 .2L12 21l-2.4-1.8-3-.2-.9-2.9-2.2-2 1-2.9-1-2.9 2.2-2 .9-2.9 3-.2z',
  warn: 'M12 9v4M12 17h.01M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z',
  error: 'M12 8v4M12 16h.01M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z',
};

function reviewChip(icon, text, { tone, title } = {}) {
  const chip = element('span', undefined, `plugin-review-chip${tone ? ` ${tone}` : ''}`);
  chip.innerHTML = SVG(REVIEW_ICONS[icon]);
  chip.append(text);
  if (title) chip.title = title;
  return chip;
}

function reviewNotice(icon, text, tone) {
  const notice = element('div', undefined, `plugin-review-notice ${tone}`);
  notice.innerHTML = SVG(REVIEW_ICONS[icon]);
  notice.append(element('div', text));
  return notice;
}

// The review before an install or update: who made the plugin and what it is
// on a header band, the README under it and the trust notice on a footer
// band above the buttons. Mirrors the device (plugin_settings.dart,
// showPluginPreview).
function confirmPreview(preview) {
  return new Promise((resolve) => {
    const plugin = preview.manifest;
    const close = value => { document.removeEventListener('ks-settings-cached', renderError); modal.close(); resolve(value); };
    const modal = modalShell({ title: '', width: 960, onDismiss: () => close(false) });
    // The error is drawn again once the language catalogs arrive.
    let compatibilityNotice;
    function renderError() {
      if (compatibilityNotice) compatibilityNotice.replaceWith(compatibilityNotice = reviewNotice('error', pluginError(preview.compatibilityError), 'error'));
    }
    modal.card.classList.add('plugin-review');
    modal.head.remove();

    const header = element('div', undefined, 'plugin-review-head');
    const top = element('div', undefined, 'plugin-review-top');
    const icon = element('span', undefined, 'plugin-icon plugin-review-icon');
    if (preview.icon) {
      const img = element('img'); img.alt = ''; img.referrerPolicy = 'no-referrer';
      img.onerror = () => img.replaceWith(subpageIcon('Plugins'));
      img.src = preview.icon; icon.append(img);
    } else icon.append(subpageIcon('Plugins'));
    const names = element('div', undefined, 'plugin-review-names');
    names.append(element('h3', plugin.name, 'plugin-review-name'),
      element('div', t('pluginByAuthor', { author: plugin.author }), 'plugin-review-author'));
    const chips = element('div', undefined, 'plugin-review-chips');
    chips.append(reviewChip('version', preview.installedVersion ? `${preview.installedVersion} → ${plugin.version}` : plugin.version, { title: pluginText('Version') }),
      reviewChip('license', plugin.license, { title: pluginText('License') }));
    if (preview.listed === true) chips.append(reviewChip('listed', pluginText('Listed in Community Plugins'), { tone: 'listed' }));
    else if (preview.listed === false) chips.append(reviewChip('warn', pluginText('Not listed in Community Plugins'), { tone: 'unlisted' }));
    names.append(chips);
    top.append(icon, names);
    header.append(top);
    modal.card.insertBefore(header, modal.body);

    modal.body.classList.add('plugin-review-body');
    modal.body.append(element('div', 'README', 'plugin-review-eyebrow'), pluginReadme(preview));

    const footer = element('div', undefined, 'plugin-review-foot');
    if (!preview.compatible) {
      compatibilityNotice = reviewNotice('error', pluginError(preview.compatibilityError), 'error');
      footer.append(compatibilityNotice);
      document.addEventListener('ks-settings-cached', renderError);
    }
    footer.append(reviewNotice('warn', pluginText(trustNotice), 'warn'));
    modal.card.insertBefore(footer, modal.foot);
    footer.append(modal.foot);

    const cancel = element('button', pluginText('Cancel'), 'btn-text');
    cancel.onclick = () => close(false);
    const install = element('button', preview.installedVersion ? pluginText('Trust and update') : pluginText('Trust and install'), 'btn-primary');
    install.disabled = !preview.compatible;
    install.onclick = () => close(true);
    modal.foot.append(cancel, install);
  });
}

function confirmZip(file) {
  return new Promise((resolve) => {
    const modal = modalShell({ title: pluginText('Install from ZIP'), width: 520 });
    modal.body.append(hintRow(file.name), hintRow(pluginText(trustNotice), { warn: true }),
      hintRow(pluginText('New plugins start disabled. Updates preserve the enabled state and automatically restart running plugins.')));
    const cancel = element('button', pluginText('Cancel'), 'btn-text');
    cancel.onclick = () => { modal.close(); resolve(false); };
    const install = element('button', pluginText('Trust and install'), 'btn-primary');
    install.onclick = () => { modal.close(); resolve(true); };
    modal.foot.append(cancel, install);
  });
}

async function zipBase64(file) {
  const bytes = new Uint8Array(await file.arrayBuffer());
  if (!bytes.length || bytes.length > maxZipBytes) throw new Error(pluginText('Plugin ZIP must be at most 4 MB'));
  let binary = '';
  for (let start = 0; start < bytes.length; start += 8192) {
    binary += String.fromCharCode(...bytes.subarray(start, start + 8192));
  }
  return btoa(binary);
}

// Browse plugins: Community Plugins, the directory kiosksatellite.com builds
// from the plugins repository. Mirrors the device (plugin_directory.dart).
const DIRECTORY_PAGE = '_browse';
const SUBMIT_URL = 'https://github.com/jxlarrea/kiosk-satellite-plugins#submit-your-plugin';
let directory = null;
let directoryError = '';
let directoryReading = null;
let directoryQuery = '';
let directoryPageIndex = 0;
// The page sizes Plugins per page offers, so a directory of thousands still
// builds a short page. This browser remembers the choice.
const DIRECTORY_PAGE_SIZES = [5, 10, 20, 50, 100];
const PAGE_SIZE_KEY = 'ks_plugin_directory_page_size';
let directoryPageSize = (() => {
  try { const size = Number(localStorage.getItem(PAGE_SIZE_KEY)); return DIRECTORY_PAGE_SIZES.includes(size) ? size : 10; }
  catch (_) { return 10; }
})();

async function pluginCommand(name, params) {
  const result = await cmd(name, params, { timeoutMs: 95000 });
  if (!result.ok) throw new Error(result.error);
  return result.data;
}

// The same preview and trust dialog as Add plugin. True once installed.
async function installRepository(url) {
  const preview = await pluginCommand('previewPluginRepository', { url });
  if (!await confirmPreview(preview)) return false;
  await pluginCommand('installPluginRepository', { previewId: preview.previewId, trusted: true });
  return true;
}

function directoryPage() {
  return [...document.querySelectorAll('#tab-plugins > .subpage')].find((el) => el.dataset.subpage === DIRECTORY_PAGE);
}

function loadDirectory(refresh = false) {
  if (directoryReading) return directoryReading;
  directoryReading = (async () => {
    const page = directoryPage();
    page?.querySelector('.plugin-directory-refresh')?.classList.add('plugin-busy');
    try {
      directory = await pluginCommand('getPluginDirectory', { refresh });
      directoryError = directory.error || '';
    } catch (error) { directoryError = error.message; }
    finally { directoryReading = null; }
    const shown = directoryPage();
    if (shown) renderDirectory(shown);
  })();
  return directoryReading;
}

// The orders Sort by offers, the same as kiosksatellite.com's. Mirrors the
// device (plugin_directory.dart, comparator).
let directorySort = 'downloads';
const byName = (a, b) => String(a.name).localeCompare(String(b.name), undefined, { sensitivity: 'base' });
const byCount = (key) => (a, b) => (Number.isInteger(b[key]) ? b[key] : -1) - (Number.isInteger(a[key]) ? a[key] : -1);
const byDate = (key) => (a, b) => String(b[key] || '').localeCompare(String(a[key] || ''));
const chain = (...steps) => (a, b) => { for (const step of steps) { const c = step(a, b); if (c) return c; } return 0; };
const DIRECTORY_SORTS = {
  downloads: ['Most downloads', chain(byCount('downloads'), byCount('stars'), byName)],
  stars: ['Most stars', chain(byCount('stars'), byName)],
  updated: ['Recently updated', chain(byDate('released'), byName)],
  newest: ['Newest', chain(byDate('added'), byDate('released'), byName)],
  name: ['Name', byName],
};

// Installed plugin icons as data URLs by plugin ID and package digest, so a
// page rebuilt on every refresh reads each one once and an update shows its new one.
const installedIcons = new Map();

function installedIcon(plugin) {
  if (!plugin.icon) return Promise.resolve(null);
  const key = `${plugin.id}@${plugin.sha256}`;
  if (!installedIcons.has(key)) {
    installedIcons.set(key, cmd('getPluginIcon', { id: plugin.id }, { timeoutMs: 15000 })
      .then((r) => (r?.ok && r.data?.data ? `data:${r.data.mime};base64,${r.data.data}` : null))
      .catch(() => null)
      .then((src) => { if (!src) installedIcons.delete(key); return src; }));
  }
  return installedIcons.get(key);
}

function directoryRow(entry) {
  const row = element('div', undefined, 'row plugin-directory-row');
  row.tabIndex = 0; row.setAttribute('role', 'button');
  // The plugin's icon, or the generic plugin icon without one.
  const avatar = element('span', undefined, 'plugin-icon');
  if (entry.icon) {
    const img = element('img'); img.alt = ''; img.loading = 'lazy'; img.referrerPolicy = 'no-referrer';
    img.onerror = () => img.replaceWith(subpageIcon('Plugins'));
    img.src = entry.icon; avatar.append(img);
  } else avatar.append(subpageIcon('Plugins'));
  // Author, version, stars and downloads share a line.
  const text = info(entry.name);
  const meta = element('div', undefined, 'desc plugin-directory-meta');
  meta.append(element('span', `${entry.author} · ${entry.version}`));
  const number = new Intl.NumberFormat(messageLanguage() || undefined, { notation: 'compact' });
  const stats = element('div', undefined, 'plugin-directory-stats');
  for (const [label, value, path] of [
    [pluginText('Stars'), entry.stars, 'm12 3 2.8 5.7 6.2.9-4.5 4.4 1 6.2L12 17.3 6.5 20.2l1-6.2L3 9.6l6.2-.9z'],
    [pluginText('Downloads'), entry.downloads, 'M12 4v11m-4-4 4 4 4-4M5 20h14'],
    ...(Number.isInteger(entry.installs) ? [[pluginText('Active installs'), entry.installs, 'M4 5h16v11H4zM8 20h8M12 16v4']] : []),
  ]) {
    const stat = element('span'); stat.title = label; stat.setAttribute('aria-label', `${label}: ${value || 0}`);
    stat.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="${path}"/></svg>`;
    stat.append(number.format(value || 0)); stats.append(stat);
  }
  meta.append(...stats.children);
  text.append(meta);
  if (entry.description) text.append(element('div', entry.description, 'desc plugin-directory-description'));
  if (entry.needsAppVersion) text.append(element('div', t('pluginNeedsAppVersion', { version: entry.needsAppVersion }), 'desc plugin-directory-needs'));
  let action;
  if (entry.updateAvailable) {
    action = element('button', pluginText('Update'), 'btn-ghost');
    action.onclick = (event) => { event.stopPropagation(); installListed(entry, true, action); };
  } else if (entry.installed) {
    action = element('span', pluginText('Installed'), 'plugin-directory-installed');
  } else if (entry.needsAppVersion) {
    action = element('span');
  } else {
    action = iconButton(pluginText('Install'), 'M12 5v14M5 12h14');
    action.onclick = (event) => { event.stopPropagation(); installListed(entry, false, action); };
  }
  row.append(avatar, text, action);
  const open = () => {
    if (busy) return;
    if (entry.installed && !entry.updateAvailable) showTab(`plugins/${entry.id}`);
    else installListed(entry, entry.updateAvailable === true, action);
  };
  row.onclick = open;
  row.onkeydown = (event) => { if (event.target === row && (event.key === 'Enter' || event.key === ' ')) { event.preventDefault(); open(); } };
  return row;
}

// The Update button of a plugin on the Overview: the same review as here.
export const reviewPluginUpdate = (plugin, trigger) => installListed(plugin, true, trigger);

async function installListed(entry, update, trigger) {
  if (busy) return;
  busy = true;
  trigger?.classList.add('plugin-busy');
  try {
    if (update) {
      const preview = await pluginCommand('checkPluginUpdate', { id: entry.id });
      if (!preview.updateAvailable) showToast({ title: entry.name, message: pluginText('No updates available.') });
      else if (await confirmPreview(preview)) await pluginCommand('installPluginRepository', { previewId: preview.previewId, trusted: true });
    } else {
      await installRepository(entry.repository);
    }
  } catch (failure) {
    showToast({ title: pluginText('Plugin Manager'), message: pluginError(failure.message), kind: 'error' });
  } finally {
    trigger?.classList.remove('plugin-busy');
    busy = false;
  }
  await loadPlugins();
}

// Previous and next page buttons around "Page 2 of 31".
function directoryPager(pages, turn) {
  const pager = element('div', undefined, 'plugin-directory-pager');
  const number = new Intl.NumberFormat(messageLanguage() || undefined);
  const previous = iconButton(pluginText('Previous page'), 'm15 18-6-6 6-6');
  previous.disabled = directoryPageIndex === 0;
  previous.onclick = () => turn(directoryPageIndex - 1);
  const next = iconButton(pluginText('Next page'), 'm9 18 6-6-6-6');
  next.disabled = directoryPageIndex >= pages - 1;
  next.onclick = () => turn(directoryPageIndex + 1);
  const label = element('span', t('pluginPageOfPages', { page: number.format(directoryPageIndex + 1), pages: number.format(pages) }));
  pager.append(previous, label, next);
  return pager;
}

function renderDirectory(page) {
  page.replaceChildren();
  const searchCard = element('div', undefined, 'card');
  // Search, sort and page size on one line. A narrow page wraps the sort
  // and page size under the search.
  const toolbar = element('div', undefined, 'plugin-directory-toolbar');
  const input = element('input', undefined, 'field'); input.type = 'text'; input.value = directoryQuery;
  input.placeholder = pluginText('Search plugins'); input.setAttribute('aria-label', pluginText('Search plugins'));
  const search = element('label', undefined, 'plugin-directory-field plugin-directory-query');
  search.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>';
  search.append(input);
  const refreshButton = iconButton(pluginText('Refresh'), 'M3 12a9 9 0 0 1 15.5-6.3L21 8M21 3v5h-5M21 12a9 9 0 0 1-15.5 6.3L3 16M3 21v-5h5');
  refreshButton.classList.add('plugin-directory-refresh');
  refreshButton.onclick = () => loadDirectory(true);
  const sort = element('select', undefined, 'field'); sort.setAttribute('aria-label', pluginText('Sort by')); sort.title = pluginText('Sort by');
  for (const [value, [label]] of Object.entries(DIRECTORY_SORTS)) {
    const option = element('option', pluginText(label)); option.value = value; sort.append(option);
  }
  sort.value = directorySort;
  const sortField = element('label', undefined, 'plugin-directory-field plugin-directory-sort');
  sortField.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 6h18M6 12h12M10 18h4"/></svg>';
  sortField.append(sort);
  const size = element('select', undefined, 'field'); size.setAttribute('aria-label', pluginText('Plugins per page')); size.title = pluginText('Plugins per page');
  const count = new Intl.NumberFormat(messageLanguage() || undefined);
  for (const value of DIRECTORY_PAGE_SIZES) {
    const option = element('option', t('pluginCountPerPage', { count: count.format(value) })); option.value = String(value); size.append(option);
  }
  size.value = String(directoryPageSize);
  const sizeField = element('label', undefined, 'plugin-directory-field plugin-directory-size');
  sizeField.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/></svg>';
  sizeField.append(size);
  toolbar.append(search, sortField, sizeField, refreshButton);
  searchCard.append(toolbar);
  if (directoryError) searchCard.append(hintRow(pluginError(directoryError), { warn: true }));
  const list = element('div', undefined, 'card');
  const fill = () => {
    const words = directoryQuery.toLowerCase().split(/\s+/).filter(Boolean);
    const shown = (directory?.plugins || []).filter((p) => {
      const text = `${p.name} ${p.description} ${p.author} ${p.owner || ''} ${p.id}`.toLowerCase();
      return words.every((word) => text.includes(word));
    }).sort((DIRECTORY_SORTS[directorySort] || DIRECTORY_SORTS.downloads)[1]);
    const pages = Math.ceil(shown.length / directoryPageSize);
    directoryPageIndex = Math.max(0, Math.min(directoryPageIndex, pages - 1));
    const start = directoryPageIndex * directoryPageSize;
    list.replaceChildren(...shown.slice(start, start + directoryPageSize).map(directoryRow));
    if (!shown.length && directory) {
      list.append(hintRow(pluginText(words.length ? 'No plugins match your search.' : 'Community Plugins has no plugins yet.')));
    }
    if (pages > 1) list.append(directoryPager(pages, (page) => {
      directoryPageIndex = page;
      fill();
      // A new page opens at the top of the page, like opening it again.
      (document.scrollingElement || document.documentElement).scrollTo({ top: 0, behavior: 'smooth' });
    }));
  };
  // A new search starts at its first page.
  input.oninput = () => { directoryQuery = input.value; directoryPageIndex = 0; fill(); };
  // A new order starts at its first page.
  sort.onchange = () => { directorySort = sort.value; directoryPageIndex = 0; fill(); };
  size.onchange = () => {
    directoryPageSize = Number(size.value); directoryPageIndex = 0; fill();
    try { localStorage.setItem(PAGE_SIZE_KEY, size.value); } catch (_) {}
  };
  fill();
  const submitCard = element('div', undefined, 'card');
  const submit = element('a', undefined, 'row plugin-guide-row');
  submit.dataset.searchId = 'x:plugins:submit';
  submit.href = SUBMIT_URL; submit.target = '_blank'; submit.rel = 'noopener noreferrer';
  const submitIcon = element('span', undefined, 'icon-btn'); submitIcon.setAttribute('aria-hidden', 'true');
  submitIcon.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 3h6v6M21 3 10 14M10 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-5"/></svg>';
  submit.append(info(pluginText('Submit your plugin'), pluginText('List your plugin in Community Plugins.')), submitIcon);
  submitCard.append(submit);
  page.append(searchCard, ...(directory ? [list] : []), submitCard);
}

document.addEventListener('ks-route', () => {
  if (currentPath === `plugins/${DIRECTORY_PAGE}`) loadDirectory();
});

// An install link from kiosksatellite.com: ?install_plugin=owner/repo. It
// leaves the address at once, so a reload or Back never asks again, and it
// only opens the same review Add plugin shows. Nothing installs without the
// person choosing Trust and install.
let linkedInstall = (() => {
  try {
    const params = new URLSearchParams(location.search);
    const value = params.get('install_plugin');
    if (value === null) return '';
    params.delete('install_plugin');
    const query = params.toString();
    history.replaceState(history.state, '', location.pathname + (query ? `?${query}` : '') + location.hash);
    return value.trim().slice(0, 300);
  } catch (_) { return ''; }
})();

export async function installFromLink() {
  const repository = linkedInstall;
  linkedInstall = '';
  if (!repository) return;
  const url = /^https:\/\//i.test(repository) ? repository : `https://github.com/${repository}`;
  showTab('plugins', { refresh: false });
  await loadPlugins();
  try {
    if (pluginSearchState?.enabled !== true) {
      const turnOn = pluginText('Turn on');
      const answer = await messageBox({ title: pluginText('Enable Plugins'), message: pluginText('Turn on Enable Plugins to install this plugin.'),
        buttons: [pluginText('Cancel'), turnOn] });
      if (answer !== turnOn) return;
      await pluginCommand('setPluginsEnabled', { enabled: true });
      await loadPlugins();
    }
    busy = true;
    await installRepository(url);
  } catch (failure) {
    showToast({ title: pluginText('Plugin Manager'), message: pluginError(failure.message), kind: 'error' });
  } finally { busy = false; }
  await loadPlugins();
}

const EYE = 'M2 12s3.5-6.5 10-6.5S22 12 22 12s-3.5 6.5-10 6.5S2 12 2 12zM12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6z';
const EYE_OFF = 'M3 3l18 18M10.6 5.6c.5-.1.9-.1 1.4-.1 6.5 0 10 6.5 10 6.5a16 16 0 0 1-3.2 4M6.6 6.6A16 16 0 0 0 2 12s3.5 6.5 10 6.5c2 0 3.8-.6 5.4-1.6M9.9 9.9a3 3 0 0 0 4.2 4.2';

function iconButton(label, path) {
  const button = element('button', undefined, 'icon-btn'); button.type = 'button';
  button.title = label; button.setAttribute('aria-label', label);
  // Only application-owned SVG paths reach this helper.
  button.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="${path}"/></svg>`;
  return button;
}

function heading(text) { return element('div', text, 'card-title'); }
function info(title, description = '') {
  const node = element('div', undefined, 'info'); node.append(element('div', title, 'name'));
  if (description) node.append(element('div', description, 'desc'));
  return node;
}

function actionOptionsDialog(action, options) {
  return new Promise((resolve) => {
    const shell = modalShell({ title: action.title, onDismiss: () => { shell.close(); resolve(null); } });
    shell.body.append(hintRow(pluginText('To assign a gesture, open Gestures and choose Run a plugin action.')));
    const selected = { drawer: options.drawer === true, homeAssistant: options.homeAssistant === true };
    for (const [key, title, description] of [
      ['drawer', pluginText('Show in kiosk drawer'), pluginText('Also available while locked if the kiosk drawer is allowed.')],
      ['homeAssistant', pluginText('Expose to Home Assistant'), pluginText('Adds a button to the kiosk ESPHome device. Requires ESPHome and native entities.')],
    ]) {
      const row = element('div', undefined, 'row'); row.append(info(title, description));
      const input = element('input'); input.type = 'checkbox'; input.checked = selected[key]; input.setAttribute('aria-label', title);
      input.onchange = () => { selected[key] = input.checked; };
      const toggle = element('label', undefined, 'switch'); toggle.append(input, element('span', undefined, 'slider')); row.append(toggle); shell.body.append(row);
    }
    const cancel = element('button', pluginText('Cancel'), 'btn-text'); cancel.onclick = () => { shell.close(); resolve(null); };
    const save = element('button', pluginText('Save'), 'btn-primary'); save.onclick = () => { shell.close(); resolve(selected); };
    shell.foot.append(cancel, save);
  });
}

// One setting's row or the block of a list setting, keyed by its setting
// key. pluginValue holds the saved value it was drawn with, so an update in
// place can tell when it no longer shows the saved one. [save] saves a
// value and runs its last argument once the value is saved.
function settingElement(plugin, setting, values, alone, save) {
  const value = values[setting.key];
  let node;
  if (setting.type === 'list') {
    node = listSetting({ setting, rows: value ?? setting.default ?? [], showTitle: !alone, plugin,
      onChange: (rows) => save(setting.key, rows, node) });
    node.pluginAlone = alone;
  } else node = settingRow(plugin, setting, value, save);
  node.dataset.searchId = `plugin:${plugin.id}:setting:${setting.key}`;
  node.dataset.settingKey = setting.key;
  node.pluginValue = JSON.stringify(value);
  return node;
}

function settingRow(plugin, setting, value, save) {
  const settingRow = element('div', undefined, 'row');
  settingRow.append(info(setting.title, setting.description));
  const input = element('input'); input.setAttribute('aria-label', setting.title);
  if (setting.type === 'boolean') {
    input.type = 'checkbox'; input.checked = value ?? setting.default;
    input.onchange = () => save(setting.key, input.checked, input);
    const toggle = element('label', undefined, 'switch'); toggle.append(input, element('span', undefined, 'slider')); settingRow.append(toggle);
  } else if (setting.type === 'number' && setting.input === 'field') {
    // A typed number saves once it is done, like a text setting, and
    // only a value the setting takes. The reason shows under the name.
    let saved = value ?? setting.default;
    const number = numberControl(setting, String(saved), () => {});
    number.input.onchange = () => {
      const typed = Number(number.input.value);
      if (!number.check() && typed !== saved) save(setting.key, typed, number.input, () => { saved = typed; });
    };
    number.input.onkeydown = (event) => { if (event.key === 'Enter') number.input.blur(); };
    settingRow.firstElementChild.append(number.error);
    settingRow.append(number.control);
  } else if (setting.type === 'number') {
    input.type = 'range'; input.min = setting.min; input.max = setting.max; input.step = setting.step || 1;
    input.value = value ?? setting.default;
    const control = element('div', undefined, 'plugin-range');
    const output = element('span', `${input.value} ${setting.unit || ''}`.trim(), 'desc');
    input.oninput = () => { output.textContent = `${input.value} ${setting.unit || ''}`.trim(); };
    input.onchange = () => save(setting.key, Number(input.value), input);
    control.append(input, output); settingRow.append(control);
  } else if (setting.type === 'entity') {
    // The entity picker, narrowed to the plugin's domain when it
    // declares one and listing hidden entities when it asks; Clear
    // empties the setting.
    let current = value ?? setting.default ?? '';
    const domains = Array.isArray(setting.domain) ? setting.domain.map(String)
      : (setting.domain ? [String(setting.domain)] : []);
    const spec = entitySpec({ domains, includeHidden: setting.includeHidden === true });
    const field = pickField({
      spec, value: current,
      onClick: async () => {
        const out = await pickItem({ title: setting.title, spec,
          selected: current || null, allowClear: true });
        if (!out) return;
        current = out.id ?? '';
        await save(setting.key, current, field.el);
        field.setValue(current);
      },
    });
    settingRow.replaceChildren(info(setting.title, setting.description || ''), field.el);
    settingRow.classList.add('dp-field-row');
  } else if (setting.type === 'action') {
    const field = actionField({ value: value ?? setting.default ?? {}, onPick: (action) => save(setting.key, action, field.el) });
    settingRow.replaceChildren(info(setting.title, setting.description || ''), field.el);
    settingRow.classList.add('dp-field-row');
  } else if (setting.type === 'icon' || setting.type === 'dashboard' || setting.type === 'cameraView') {
    const current = value ?? setting.default ?? '';
    let field;
    if (setting.type === 'icon') {
      field = iconField({ value: current, title: setting.title, onPick: (picked) => save(setting.key, picked, field.el) });
    } else if (setting.type === 'dashboard') {
      field = dashboardField({ value: current, title: setting.title, onPick: (path) => save(setting.key, path, field.el) });
    } else {
      const spec = cameraViewSpec();
      let picked = current;
      field = pickField({
        spec, value: current, placeholder: pluginText('Choose a camera view'),
        onClick: async () => {
          const out = await pickItem({ title: setting.title, spec, selected: picked || null, allowClear: true });
          if (!out) return;
          picked = out.id ?? '';
          await save(setting.key, picked, field.el);
          field.setValue(picked);
        },
      });
    }
    settingRow.replaceChildren(info(setting.title, setting.description || ''), field.el);
    settingRow.classList.add('dp-field-row');
  } else if (setting.type === 'string' && setting.choices === 'plugin') {
    // The plugin lists the choices. The setting stores the picked ID.
    const choice = choiceControl(plugin, setting, value ?? setting.default ?? '', settled,
      (picked, trigger) => save(setting.key, picked, trigger));
    const text = info(setting.title, setting.description || ''); text.append(...choice.lines);
    settingRow.replaceChildren(text, choice.control);
    settingRow.classList.add('dp-field-row');
    choice.attach(settingRow);
  } else if (setting.type === 'select') {
    const select = element('select'); select.setAttribute('aria-label', setting.title);
    for (const choice of setting.options) { const option = element('option', choice); option.value = choice; select.append(option); }
    select.value = value ?? setting.default;
    select.onchange = () => save(setting.key, select.value, select); settingRow.append(select);
  } else if (setting.type === 'color') {
    const hex = value ?? setting.default;
    const rgb = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16)).join(',');
    settingRow.append(swatch(rgb, setting.title, (selected) => {
      save(setting.key, '#' + selected.split(',').map((c) => Number(c).toString(16).padStart(2, '0')).join('').toUpperCase(), settingRow.querySelector('button'));
    }));
  } else if (setting.type === 'secret') {
    // The listing reads __set__ for a saved secret, never the value.
    // Typing replaces it. The eye shows what is being typed.
    input.type = 'password'; input.maxLength = 512; input.autocomplete = 'new-password';
    input.placeholder = value === '__set__' ? deviceText('•••••• (set)') : deviceText('Not set');
    const reveal = iconButton(pluginText('Show password'), EYE);
    const show = (shown) => {
      input.type = shown ? 'text' : 'password';
      const label = pluginText(shown ? 'Hide password' : 'Show password');
      reveal.title = label; reveal.setAttribute('aria-label', label);
      reveal.querySelector('path').setAttribute('d', shown ? EYE_OFF : EYE);
    };
    // Blur saves, since switching the field's type drops its change
    // event. A saved secret leaves the field empty and hidden again.
    input.onblur = () => input.value && save(setting.key, input.value, input, () => {
      input.value = ''; show(false); reveal.hidden = true;
    });
    input.onkeydown = (event) => { if (event.key === 'Enter') input.blur(); };
    // Pressing the eye keeps focus in the field, so it does not save
    // and redraw the row halfway through typing.
    reveal.onmousedown = (event) => event.preventDefault();
    reveal.onclick = () => show(input.type === 'password');
    // The eye appears only with typed text, since the saved value is
    // never shown. An emptied field hides its text again.
    reveal.hidden = true;
    input.oninput = () => { reveal.hidden = !input.value; if (!input.value) show(false); };
    const control = element('div', undefined, 'plugin-secret'); control.append(input, reveal);
    settingRow.append(control);
  } else {
    input.type = 'text'; input.maxLength = 512; input.value = value ?? setting.default;
    input.onchange = () => save(setting.key, input.value, input);
    input.onkeydown = (event) => { if (event.key === 'Enter') input.blur(); }; settingRow.append(input);
  }
  return settingRow;
}

// The chart and reading boxes of a group or of the page with no group.
function outputBoxes(group = '') {
  const charts = element('div', undefined, 'plugin-charts'); charts.hidden = true; charts.dataset.pluginGroup = group;
  const readings = element('div', undefined, 'plugin-readings'); readings.hidden = true; readings.dataset.pluginGroup = group;
  return [charts, readings];
}

// A group's title and card, then its charts and readings when it has any.
function groupNodes(page, plugin, group) {
  const panel = element('div', undefined, 'card');
  const nodes = [heading(group === 'Settings' && !plugin.groups?.some(entry => entry.title === group) && !plugin.settings?.some(entry => entry.group === group) && !plugin.buttons?.some(entry => entry.group === group) ? pluginText('Settings') : group), panel];
  if (page.pluginGroups.some((entry) => entry.title === group && (entry.charts?.length || entry.readings?.length))) nodes.push(...outputBoxes(group));
  return { panel, nodes };
}

// Puts [nodes] in order after [anchor] or first in [parent] without one.
// Only a node out of place moves, since moving one drops its focus.
function placeAfter(parent, anchor, nodes) {
  for (const node of nodes) {
    const at = anchor ? anchor.nextElementSibling : parent.firstElementChild;
    if (at !== node) { if (anchor) anchor.after(node); else parent.prepend(node); }
    anchor = node;
  }
}

// Whether the person is typing in a control inside [node].
function editing(node) {
  const active = document.activeElement;
  return !!active && node.contains(active) && (active.tagName === 'TEXTAREA'
    || (active.tagName === 'INPUT' && !['checkbox', 'range'].includes(active.type)));
}

// The plugin's status and error under its intro and why it is not running.
function paintPluginStatus(page, plugin, pluginsEnabled) {
  const shown = JSON.stringify([plugin.status, plugin.statusError, plugin.error, pluginsEnabled, plugin.enabled]);
  if (page.pluginStatusShown === shown) return;
  page.pluginStatusShown = shown;
  const description = page.pluginStatus;
  description.replaceChildren(description.firstElementChild);
  if (plugin.status) {
    const status = hintRow(plugin.status, { warn: plugin.statusError === true });
    status.classList.add('plugin-runtime-status'); description.append(status);
  }
  if (plugin.error) description.append(hintRow(pluginError(plugin.error), { warn: true }));
  if (!pluginsEnabled) description.append(hintRow(pluginText('Enable Plugins to run this plugin.')));
  else if (!plugin.enabled) description.append(hintRow(pluginText('Enable this plugin from its entry row to run it.')));
}

// Brings a plugin page in line with the plugin's saved values. A setting
// or button whose condition now holds goes in at its place, one whose
// condition fails comes out and a row whose saved value changed is drawn
// again, unless the person is typing in it. Every other row keeps its
// node. [force] names a setting to draw again anyway. The first render
// draws the groups and rows this way too.
function reconcilePluginPage(page, plugin, force = null) {
  const values = { ...plugin.values };
  const settings = plugin.settings || [];
  // A setting whose condition does not hold stays off the page. Its
  // saved value is kept.
  const shown = settings.filter((setting) => fieldVisible(setting, values, settings));
  // Buttons close their group, shown by the settings they name.
  const buttons = (plugin.buttons || []).filter((entry) => fieldVisible(entry, values, settings));
  // The declared groups always show, then the rest in the order their
  // first setting or button names them.
  const titles = [...new Set([...(plugin.groups || []).map((group) => group.title),
    ...[...shown, ...buttons].map((entry) => entry.group || 'Settings')])];
  const groups = page.pluginGroupCards;
  for (const [title, group] of groups) {
    if (!titles.includes(title)) { group.nodes.forEach((node) => node.remove()); groups.delete(title); }
  }
  let anchor = page.pluginLead;
  for (const title of titles) {
    if (!groups.has(title)) groups.set(title, groupNodes(page, plugin, title));
    const { panel, nodes } = groups.get(title);
    placeAfter(page, anchor, nodes);
    anchor = nodes[nodes.length - 1];
    const members = shown.filter((setting) => (setting.group || 'Settings') === title);
    const current = [...panel.children];
    const rows = members.map((setting) => {
      const alone = members.length === 1;
      const row = current.find((node) => node.dataset.settingKey === setting.key);
      if (row && (editing(row) || (setting.key !== force && row.pluginValue === JSON.stringify(values[setting.key])
        && (setting.type !== 'list' || row.pluginAlone === alone)))) return row;
      const fresh = settingElement(plugin, setting, values, alone, page.pluginSave);
      row?.replaceWith(fresh);
      return fresh;
    });
    for (const button of buttons.filter((entry) => (entry.group || 'Settings') === title)) {
      rows.push(current.find((node) => node.dataset.setupTarget === `button:${button.id}`) || setupButtonRow(plugin, button, settled));
    }
    for (const node of current) if (!rows.includes(node)) node.remove();
    placeAfter(panel, null, rows);
  }
}

// What a full render draws apart from setting values and status lines.
// Runtime lists such as entities and charts are read on their own.
const PAGE_FIELDS = ['id', 'name', 'description', 'version', 'sha256', 'icon', 'source', 'enabled', 'running',
  'fleetManaged', 'capabilities', 'groups', 'settings', 'buttons', 'commands', 'actionOptions', 'updateVersion'];
const pageStructure = (state) => JSON.stringify([state.enabled === true,
  (state.plugins || []).map((plugin) => PAGE_FIELDS.map((field) => plugin[field] ?? null))]);
let renderedStructure = '';

// Applies [state] to the plugin pages already drawn when only setting
// values and status lines changed, keeping scroll, focus and any open
// dialog. False when anything else changed, such as an install, an update
// or a plugin starting, for the caller to draw the whole tab. [force]
// names a plugin's setting to draw again, one whose save failed.
function patchPlugins(root, state, force = null) {
  if (pageStructure(state) !== renderedStructure) return false;
  const pages = new Map([...root.querySelectorAll(':scope > .subpage')].map((page) => [page.dataset.subpage, page]));
  const plugins = state.enabled === true ? state.plugins || [] : [];
  if (plugins.some((plugin) => !pages.get(plugin.id)?.pluginGroupCards)) return false;
  for (const plugin of plugins) {
    const page = pages.get(plugin.id);
    paintPluginStatus(page, plugin, true);
    reconcilePluginPage(page, plugin, force?.id === plugin.id ? force.key : null);
  }
  renderedState = JSON.stringify(state);
  pluginSearchState = state;
  return true;
}

let renderedState = '';
function render(root, state) {
  renderedState = JSON.stringify(state);
  renderedStructure = pageStructure(state);
  pluginSearchState = state;
  const plugins = state.plugins || [];
  const pluginsEnabled = state.enabled === true;
  const scroll = document.scrollingElement?.scrollTop || 0;
  root.replaceChildren();
  // A follower's fleet banner goes back on top (fleetsync.js).
  document.dispatchEvent(new CustomEvent('ks-plugins-rendered'));
  const introduction = element('div', undefined, 'card');
  const masterRow = element('div', undefined, 'row');
  masterRow.dataset.searchId = 'x:plugins:master';
  masterRow.append(info(pluginText('Enable Plugins'), pluginText(introText)));
  const masterToggle = element('label', undefined, 'switch plugin-master-switch');
  const master = element('input'); master.type = 'checkbox'; master.checked = pluginsEnabled;
  master.setAttribute('aria-label', pluginText('Enable Plugins'));
  masterToggle.append(master, element('span', undefined, 'slider')); masterRow.append(masterToggle);
  introduction.append(masterRow);
  const installCard = element('div', undefined, 'card');
  const addRow = element('div', undefined, 'row plugin-add-row');
  addRow.dataset.searchId = 'x:plugins:add';
  addRow.append(info(pluginText('Add plugin'), pluginText('Install from a GitHub repository')));
  const add = iconButton(pluginText('Add plugin'), 'M12 5v14M5 12h14'); addRow.append(add);
  const warning = hintRow(pluginText(trustNotice), { warn: true }); warning.classList.add('plugin-install-warning');
  const browseRow = subpageEntry('plugins', DIRECTORY_PAGE, { iconName: 'Plugins' });
  browseRow.dataset.searchId = 'x:plugins:browse';
  browseRow.querySelector('.name').textContent = pluginText('Browse plugins');
  browseRow.querySelector('.desc').textContent = pluginText('Find plugins made by the community');
  browseRow.addEventListener('click', (event) => { if (busy) event.stopImmediatePropagation(); }, true);
  const browseCard = element('div', undefined, 'card');
  browseCard.append(browseRow);
  installCard.append(addRow, warning);
  const list = element('div', undefined, 'card');
  const developerTools = element('div', undefined, 'card');
  const zipRow = element('div', undefined, 'row plugin-add-row');
  zipRow.dataset.searchId = 'x:plugins:zip';
  zipRow.append(info(pluginText('Install from ZIP'), pluginText('For developers only: test a local build')));
  const upload = iconButton(pluginText('Install from ZIP'), 'M12 16V4m-4 4 4-4 4 4M4 16v4h16v-4');
  const fileInput = element('input'); fileInput.type = 'file'; fileInput.accept = '.zip,application/zip'; fileInput.hidden = true;
  fileInput.setAttribute('aria-label', pluginText('Plugin ZIP'));
  zipRow.append(upload, fileInput); developerTools.append(zipRow);
  const guideRow = element('a', undefined, 'row plugin-guide-row');
  guideRow.dataset.searchId = 'x:plugins:create';
  guideRow.href = 'https://github.com/jxlarrea/kiosk-satellite-plugins/blob/main/docs/getting-started.md';
  guideRow.target = '_blank'; guideRow.rel = 'noopener noreferrer';
  guideRow.append(info(pluginText('Create a plugin'), pluginText('Learn how to create plugins with the Hello World template and documentation.')));
  const guideIcon = element('span', undefined, 'icon-btn'); guideIcon.setAttribute('aria-hidden', 'true');
  guideIcon.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 3h6v6M21 3 10 14M10 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-5"/></svg>';
  guideRow.append(guideIcon); developerTools.append(guideRow);
  root.append(introduction);

  async function command(name, params) {
    const result = await cmd(name, params, { timeoutMs: 95000 });
    if (!result.ok) throw new Error(result.error);
    return result.data;
  }
  async function run(action, trigger = add) {
    if (busy) return;
    busy = true;
    root.setAttribute('aria-busy', 'true');
    // Settings buttons stay pressable: a press right after a text edit
    // lands while that edit saves, and the button waits for it.
    root.querySelectorAll(LOCKED).forEach((el) => { el.disabled = true; });
    trigger.classList.add('plugin-busy');
    try { await action(); }
    catch (failure) { showToast({ title: pluginText('Plugin Manager'), message: pluginError(failure.message), kind: 'error' }); }
    finally {
      trigger.classList.remove('plugin-busy'); busy = false;
      root.removeAttribute('aria-busy');
      root.querySelectorAll(LOCKED).forEach((el) => { el.disabled = el.dataset.pluginDisabled === 'true'; });
    }
  }
  const refresh = async () => render(root, await command('getPluginState'));
  const update = (name, params, trigger) => run(async () => { await command(name, params); await refresh(); }, trigger);
  master.onchange = () => run(async () => {
    try { render(root, await command('setPluginsEnabled', { enabled: master.checked })); }
    finally { master.checked = pluginsEnabled; }
  }, masterToggle);
  if (!pluginsEnabled) {
    if (currentPath.split('/')[0] === 'plugins') showTab('plugins', { refresh: false });
    return;
  }
  root.append(browseCard, installCard, heading(pluginText('Installed plugins')), list, heading(pluginText('Developer Tools')), developerTools);
  const browsePage = element('div', undefined, 'subpage');
  browsePage.dataset.subpage = DIRECTORY_PAGE; browsePage.dataset.title = pluginText('Browse plugins');
  renderDirectory(browsePage);
  root.append(browsePage);
  add.onclick = () => run(async () => {
    const url = await repositoryDialog();
    if (url === null) return;
    const result = await command('previewPluginRepository', { url });
    if (await confirmPreview(result)) {
      await command('installPluginRepository', { previewId: result.previewId, trusted: true });
      await refresh();
    }
  });
  upload.onclick = () => { if (!busy) fileInput.click(); };
  zipRow.onclick = (event) => { if (!event.target.closest('button,input') && !busy) upload.click(); };
  fileInput.onchange = () => {
    const file = fileInput.files?.[0]; fileInput.value = '';
    if (!file) return;
    run(async () => {
      if (!file.size || file.size > maxZipBytes) throw new Error(pluginText('Plugin ZIP must be at most 4 MB'));
      if (!await confirmZip(file)) return;
      const data = await zipBase64(file);
      await command('installPlugin', { data, trusted: true });
      await refresh();
    }, upload);
  };
  addRow.onclick = (event) => { if (!event.target.closest('button') && !busy) add.click(); };
  if (!plugins.length) list.append(hintRow(pluginText('No plugins installed. Add a repository to get started.')));
  for (const plugin of plugins) {
    const row = subpageEntry('plugins', plugin.id, { iconName: 'Plugins' });
    row.querySelector('.name').textContent = plugin.name;
    const repository = plugin.source?.repository?.match(/^https:\/\/github\.com\/([^/]+\/[^/]+?)(?:\.git)?\/?$/i)?.[1];
    row.querySelector('.desc').textContent = [`${repository || 'ZIP'} · ${plugin.version}`,
      ...(plugin.updateVersion ? [t('overviewNewVersion', { version: plugin.updateVersion })] : [])].join(' · ');
    row.addEventListener('click', (event) => { if (busy) event.stopImmediatePropagation(); }, true);
    row.setAttribute('role', 'link'); row.tabIndex = 0;
    row.onkeydown = (event) => {
      if (event.target === row && (event.key === 'Enter' || event.key === ' ')) { event.preventDefault(); showTab(`plugins/${plugin.id}`); }
    };
    const toggle = element('label', undefined, 'switch');
    const enabled = element('input'); enabled.type = 'checkbox'; enabled.checked = plugin.enabled;
    enabled.setAttribute('aria-label', t('pluginEnableName', {name:plugin.name}));
    enabled.disabled = !pluginsEnabled; enabled.dataset.pluginDisabled = String(!pluginsEnabled);
    enabled.onchange = () => update(enabled.checked ? 'enablePlugin' : 'disablePlugin', { id: plugin.id }, row.querySelector('.chev'));
    toggle.onclick = (event) => event.stopPropagation();
    toggle.append(enabled, element('span', undefined, 'slider'));
    const remove = iconButton(t("pluginUninstallNameDetail", {name: plugin.name}), 'M3 6h18M9 6V4h6v2M5 6l1 14h12l1-14M10 10v6M14 10v6');
    remove.onclick = (event) => {
      event.stopPropagation();
      run(async () => {
        if (await messageBox({ title: t("pluginUninstallName", {name: plugin.name}), message: pluginText('This removes the plugin and its settings.'), buttons: [pluginText('Cancel'), pluginText('Uninstall')] }) === pluginText('Uninstall')) {
          await command('removePlugin', { id: plugin.id }); await refresh();
        }
      }, remove);
    };
    row.firstElementChild.replaceWith(toggle);
    const about = iconButton(t("pluginAboutName", {name: plugin.name}), 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20ZM12 11v6M12 7h.01');
    about.onclick = (event) => {
      event.stopPropagation();
      const modal = modalShell({ title: plugin.name, width: 760 });
      modal.body.append(plugin.source ? pluginReadme(plugin.source)
        : element('p', pluginText('This plugin was installed from ZIP and has no repository README.')));
      const close = element('button', pluginText('Close'), 'btn-text'); close.onclick = () => modal.close();
      modal.foot.append(close);
    };
    const check = iconButton(t("pluginCheckForUpdatesForName", {name: plugin.name}), 'M3 11a9 9 0 1 1 2.6 7.4M3 4v7h7M12 7v5l3 2');
    // A fleet leader keeps a synced plugin in step.
    check.disabled = !plugin.source?.repository || plugin.fleetManaged === true; check.dataset.pluginDisabled = String(check.disabled);
    check.onclick = (event) => {
      event.stopPropagation();
      run(async () => {
        const preview = await command('checkPluginUpdate', { id: plugin.id });
        if (!preview.updateAvailable) {
          showToast({ title: plugin.name, message: pluginText('No updates available.') });
          return;
        }
        if (await confirmPreview(preview)) {
          try { await command('installPluginRepository', { previewId: preview.previewId, trusted: true }); }
          finally { await refresh(); }
        }
      }, check);
    };
    // One group, so a phone can give it a line of its own under the name.
    const actions = element('span', undefined, 'plugin-entry-actions');
    actions.append(check, about, remove);
    row.insertBefore(actions, row.lastChild);
    list.append(row);
    const page = element('div', undefined, 'subpage'); page.dataset.subpage = plugin.id; page.dataset.title = plugin.name;
    page.dataset.pluginRunning = String(plugin.running === true);
    const description = element('div', undefined, 'card');
    const intro = introRow(SUBPAGE_ICONS.Plugins, plugin.name || plugin.id, plugin.description || '');
    intro.dataset.searchId = `plugin:${plugin.id}:intro`;
    description.append(intro);
    // The plugin's own icon replaces the generic glyph once it arrives.
    installedIcon(plugin).then((src) => {
      if (!src) return;
      const img = element('img'); img.alt = ''; img.src = src;
      intro.querySelector('.intro-icon').replaceChildren(img);
    });
    page.pluginStatus = description;
    paintPluginStatus(page, plugin, pluginsEnabled);
    page.append(description);
    if (plugin.capabilities?.includes('shizuku')) {
      const access = element('div', undefined, 'card plugin-shizuku');
      const row = element('div', undefined, 'row');
      row.dataset.searchId = `plugin:${plugin.id}:shizuku`;
      row.append(info(pluginText('Shizuku access'), pluginText('Checking availability')));
      const button = element('button', pluginText('Set up'), 'btn-ghost'); button.type = 'button'; button.disabled = true;
      button.onclick = () => {
        if (access.dataset.status === 'permission_required') {
          run(async () => {
            const state = await command('requestPluginShizukuPermission', { id: plugin.id });
            updatePluginShizuku(access, state);
            showToast({ title: 'Shizuku', message: pluginText('Approve the permission request on the kiosk.') });
          }, button);
        } else window.open('https://shizuku.rikka.app/guide/setup/', '_blank', 'noopener,noreferrer');
      };
      row.append(button); access.append(row, hintRow(pluginText('Shizuku grants Kiosk Satellite shell or root access. Installed plugins run inside KS, so only grant access if you trust them.')));
      page.append(access);
    }
    // The groups follow the intro or the Shizuku card under it.
    page.pluginLead = page.lastElementChild;
    page.pluginGroups = plugin.groups || [];
    page.pluginGroupCards = new Map();
    // Only the changed setting, so a value the plugin saved meanwhile
    // stays. The page then follows the saved values in place. A row
    // whose save failed goes back to the saved value.
    page.pluginSave = (key, value, trigger, saved) => run(async () => {
      let failed = true;
      try {
        await command('configurePlugin', { id: plugin.id, values: { [key]: value }, patch: true });
        failed = false;
        saved?.();
        // A control already shows the value it saved, so its row stays.
        // A list draws its rows again and a secret its placeholder.
        const type = plugin.settings?.find((setting) => setting.key === key)?.type;
        const row = [...page.querySelectorAll('[data-setting-key]')].find((node) => node.dataset.settingKey === key);
        if (row && type !== 'list' && type !== 'secret') row.pluginValue = JSON.stringify(value);
      } finally {
        const next = await command('getPluginState');
        if (!patchPlugins(root, next, failed ? { id: plugin.id, key } : null)) render(root, next);
      }
    }, trigger);
    reconcilePluginPage(page, plugin);
    page.append(...outputBoxes());
    if (plugin.commands?.length) {
      const actions = element('div', undefined, 'card');
      for (const action of plugin.commands) {
        const row = element('div', undefined, 'row'); row.append(info(action.title));
        row.dataset.searchId = `plugin:${plugin.id}:action:${action.id}`;
        const options = plugin.actionOptions?.[action.id] || {};
        row.replaceChildren(info(action.title, [pluginText('Gestures'), options.drawer && pluginText('Kiosk drawer'), options.homeAssistant && pluginText('Home Assistant')].filter(Boolean).join(' · ')));
        const button = iconButton(t("pluginConfigureName", {name: action.title}), 'm9 5 7 7-7 7');
        button.onclick = () => run(async () => {
          const selected = await actionOptionsDialog(action, options);
          if (selected) { await command('configurePluginAction', { id: plugin.id, command: action.id, ...selected }); await refresh(); }
        }, button);
        row.append(button); actions.append(row);
      }
      page.append(heading(pluginText('Actions')), actions);
    }
    root.append(page);
  }
  if (currentPath.split('/')[0] === 'plugins') {
    showTab(currentPath, { push: false, refresh: false });
    if (document.scrollingElement) document.scrollingElement.scrollTop = scroll;
    // A settings render replaces output containers while the subscription stays active.
    receiveUpdate('plugins');
  }
}

function updatePluginShizuku(container, state) {
  const status = state?.status || 'unavailable';
  container.dataset.status = status;
  const descriptions = {
    ready: state?.uid === 0 ? pluginText('Connected with root access') : pluginText('Connected with shell access'),
    permission_required: pluginText('Grant access and approve the request on this kiosk.'),
    denied: pluginText('Allow Kiosk Satellite in the Shizuku app.'),
    unsupported: pluginText('Shizuku 13 or later is required.'),
    unavailable: pluginText('Start Shizuku on this device.'),
  };
  container.querySelector('.desc').textContent = descriptions[status] || descriptions.unavailable;
  const button = container.querySelector('button');
  button.style.display = status === 'ready' ? 'none' : '';
  button.disabled = false;
  button.textContent = status === 'permission_required' ? pluginText('Grant access') : pluginText('Set up');
}

// The group whose [kind] claims [key], or null when none does. A group
// naming the key wins over one claiming its whole type with "sensor.*",
// which wins over one claiming the rest with "*".
function outputGroup(layouts, kind, key) {
  const claimedBy = (reference) => layouts.find((entry) => (entry[kind] || []).includes(reference))?.title;
  const dot = key.indexOf('.');
  return claimedBy(key) ?? (kind === 'readings' && dot > 0 ? claimedBy(`${key.slice(0, dot)}.*`) : undefined)
    ?? claimedBy('*') ?? null;
}

function updateGroupedPluginOutput(page, kind, items) {
  const layouts = page.pluginGroups || [];
  items = Array.isArray(items) ? items : [];
  const key = (item) => kind === 'readings' ? `${item.type}.${item.key}` : item.key;
  for (const target of page.querySelectorAll(`.plugin-${kind}`)) {
    const group = target.dataset.pluginGroup;
    const layout = layouts.find((entry) => entry.title === group);
    const selected = items.filter((item) => (outputGroup(layouts, kind, key(item)) ?? '') === (group || ''));
    if (kind === 'charts') updatePluginCharts(target, selected, group ? '' : pluginText('Charts'));
    else updatePluginReadings(target, selected, layout?.readingsTitle || pluginText('Readings'));
  }
}

let runtimeLoading = false;
watchUpdates(['plugins'], async () => {
  const [tab, id] = currentPath.split('/');
  if (tab !== 'plugins' || !id || document.hidden || runtimeLoading || busy) return;
  const page = [...document.querySelectorAll('#tab-plugins > .subpage')].find(el => el.dataset.subpage === id);
  const container = page?.querySelector('.plugin-charts');
  if (!container) return;
  runtimeLoading = true;
  try {
    const outputs = [
      ['getPluginCharts', page, (target, items) => updateGroupedPluginOutput(target, 'charts', items)],
      ['getPluginReadings', page, (target, items) => updateGroupedPluginOutput(target, 'readings', items)],
      ...(page.querySelector('.plugin-shizuku') ? [['getPluginShizukuState', page.querySelector('.plugin-shizuku'), updatePluginShizuku]] : []),
    ].map(async ([command, target, update]) => {
      const result = await cmd(command, { id }, { timeoutMs: 5000 });
      if (target?.isConnected && currentPath === `plugins/${id}` && result.ok) update(target, result.data);
    });
    // Settings buttons and plugin choices follow their runs, and list rows
    // follow the choices they show by label.
    if (page.querySelector('[data-setup-target], [data-plugin-choices]')) outputs.push(refreshPluginSetup(id));
    await Promise.allSettled(outputs);
  } catch (_) { /* Reconnect reads the latest plugin output. */ }
  finally { runtimeLoading = false; }
}, { visible: () => currentPath.startsWith('plugins/'), intervalMs: 1000 });

// The plugin hears while its settings page is open in this browser, so it
// can keep the page fresh. KS counts the page closed 5 seconds after the
// last check in, so a tab that goes away without a word closes it too.
const pageViewer = Math.random().toString(36).slice(2);
let shownPluginPage = '';
function checkInPluginPage() {
  const [tab, id] = currentPath.split('/');
  // Search results take the page's place without changing the route.
  const shown = tab === 'plugins' && id && id !== DIRECTORY_PAGE && !document.hidden
    && !document.querySelector('#app')?.classList.contains('hidden')
    && document.querySelector('#tab-plugins')?.classList.contains('active') ? id : '';
  if (shownPluginPage && shownPluginPage !== shown) {
    cmd('setPluginPageOpen', { id: shownPluginPage, viewer: pageViewer, open: false }).catch(() => {});
  }
  shownPluginPage = shown;
  if (shown) cmd('setPluginPageOpen', { id: shown, viewer: pageViewer }, { timeoutMs: 5000 }).catch(() => {});
}
setInterval(checkInPluginPage, 2000);
document.addEventListener('ks-route', checkInPluginPage);
document.addEventListener('visibilitychange', checkInPluginPage);

// Settings and installation changes are separate from frequent readings.
// Values a plugin saved itself, such as after a settings button, update
// the page in place.
watchUpdates(['plugin-settings'], async () => {
  if (busy) return;
  const next = await refreshPluginSearchState();
  if (busy || JSON.stringify(next) === renderedState) return;
  const root = document.getElementById('tab-plugins');
  if (patchPlugins(root, next)) return;
  const restoreDraft = preserveDraft(root, 'data-search-id');
  try { render(root, next); }
  finally { restoreDraft(); }
}, { visible: () => currentPath === 'plugins' || currentPath.startsWith('plugins/'), intervalMs: 500 });

let renderedLanguage = messageLanguage();
document.addEventListener('ks-settings-cached', () => {
  if (renderedLanguage === messageLanguage()) return;
  renderedLanguage = messageLanguage();
  const root = document.getElementById('tab-plugins');
  if (!root || !pluginSearchState || busy || document.querySelector('.modal-back')) return;
  const restore = preserveDraft(root, 'data-search-id');
  try { render(root, pluginSearchState); } finally { restore(); }
});
