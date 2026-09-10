import { cmd } from './core.js';
import { currentPath, showTab, subpageEntry } from './tabs.js';
import { hintRow, messageBox, modalShell, showToast } from './widgets.js';
import { marked } from './vendor-marked.js';
import DOMPurify from './vendor-purify.js';

const introText = 'Plugins add optional features to Kiosk Satellite, such as floating windows over your dashboard. Each plugin has its own settings and can be enabled or removed independently.';
const trustNotice = 'Plugins run code inside Kiosk Satellite and can access app data and granted Android permissions. A faulty or malicious plugin can expose private information or stop the app from working. Only install plugins from authors you trust.';
let busy = false;

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

export async function loadPlugins() {
  const root = document.getElementById('tab-plugins');
  if (!root || busy) return;
  busy = true;
  try {
    const result = await cmd('listPlugins');
    if (!result.ok) throw new Error(result.error);
    render(root, result.data || []);
  } catch (error) {
    showToast({ title: 'Plugins', message: error.message, kind: 'error' });
  } finally { busy = false; }
}

function repositoryDialog() {
  return new Promise((resolve) => {
    const modal = modalShell({ title: 'Add plugin', width: 520 });
    const form = element('form'); form.id = 'plugin-repository-form';
    const row = element('div', undefined, 'row plugin-repository-field');
    const label = element('label', 'Repository URL', 'info'); label.htmlFor = 'plugin-repository-url';
    const input = element('input'); input.id = 'plugin-repository-url'; input.type = 'url'; input.required = true;
    input.placeholder = 'https://github.com/owner/plugin'; input.autocomplete = 'url';
    row.append(label, input); form.append(row, hintRow('Review the plugin before installing it.')); modal.body.append(form);
    const cancel = element('button', 'Cancel', 'btn-text');
    cancel.onclick = () => { modal.close(); resolve(null); };
    const preview = element('button', 'Preview', 'btn-primary'); preview.type = 'submit'; preview.setAttribute('form', form.id);
    form.onsubmit = (event) => { event.preventDefault(); const url = input.value.trim(); modal.close(); resolve(url); };
    modal.foot.append(cancel, preview); input.focus();
  });
}

function confirmPreview(preview) {
  return new Promise((resolve) => {
    const plugin = preview.manifest;
    const modal = modalShell({ title: plugin.name, width: 760 });
    modal.body.append(hintRow(plugin.description));
    for (const [title, value] of Object.entries({ Version: plugin.version, Author: plugin.author, License: plugin.license })) {
      const row = element('div', undefined, 'row');
      row.append(element('span', title, 'info'), element('span', value, 'desc')); modal.body.append(row);
    }
    modal.body.append(pluginReadme(preview), hintRow(trustNotice, { warn: true }),
      hintRow('Installed plugins start disabled. Enable this plugin from its entry row when you are ready.'));
    if (!preview.compatible) modal.body.append(hintRow(preview.compatibilityError, { warn: true }));
    const cancel = element('button', 'Cancel', 'btn-text');
    cancel.onclick = () => { modal.close(); resolve(false); };
    const install = element('button', 'Trust and install', 'btn-primary');
    install.disabled = !preview.compatible;
    install.onclick = () => { modal.close(); resolve(true); };
    modal.foot.append(cancel, install);
  });
}

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

function render(root, plugins) {
  const scroll = document.scrollingElement?.scrollTop || 0;
  root.replaceChildren();
  const introduction = element('div', undefined, 'card');
  introduction.append(hintRow(introText), hintRow(trustNotice, { warn: true }));
  const installCard = element('div', undefined, 'card');
  const addRow = element('div', undefined, 'row plugin-add-row');
  addRow.append(info('Add plugin', 'Install from a GitHub repository'));
  const add = iconButton('Add plugin', 'M12 5v14M5 12h14'); addRow.append(add);
  installCard.append(addRow);
  const list = element('div', undefined, 'card');
  root.append(introduction, installCard, heading('Installed plugins'), list);

  async function command(name, params) {
    const result = await cmd(name, params, { timeoutMs: 95000 });
    if (!result.ok) throw new Error(result.error);
    return result.data;
  }
  async function run(action, trigger = add) {
    if (busy) return;
    busy = true;
    root.setAttribute('aria-busy', 'true');
    root.querySelectorAll('button,input').forEach((el) => { el.disabled = true; });
    trigger.classList.add('plugin-busy');
    try { await action(); }
    catch (failure) { showToast({ title: 'Plugins', message: failure.message, kind: 'error' }); }
    finally {
      trigger.classList.remove('plugin-busy'); busy = false;
      root.removeAttribute('aria-busy');
      root.querySelectorAll('button,input').forEach((el) => { el.disabled = el.dataset.pluginDisabled === 'true'; });
    }
  }
  const update = (name, params, trigger) => run(async () => render(root, await command(name, params)), trigger);
  add.onclick = () => run(async () => {
    const url = await repositoryDialog();
    if (url === null) return;
    const result = await command('previewPluginRepository', { url });
    if (await confirmPreview(result)) render(root, await command('installPluginRepository', { previewId: result.previewId, trusted: true }));
  });
  addRow.onclick = (event) => { if (!event.target.closest('button') && !busy) add.click(); };
  if (!plugins.length) list.append(hintRow('No plugins installed. Add a repository to get started.'));
  for (const plugin of plugins) {
    const row = subpageEntry('plugins', plugin.id, { iconName: 'Plugins' });
    row.querySelector('.name').textContent = plugin.name;
    row.querySelector('.desc').textContent = `${plugin.version} · ${plugin.enabled ? 'Enabled' : 'Disabled'}`;
    row.addEventListener('click', (event) => { if (busy) event.stopImmediatePropagation(); }, true);
    row.setAttribute('role', 'link'); row.tabIndex = 0;
    row.onkeydown = (event) => {
      if (event.target === row && (event.key === 'Enter' || event.key === ' ')) { event.preventDefault(); showTab(`plugins/${plugin.id}`); }
    };
    const toggle = element('label', undefined, 'switch');
    const enabled = element('input'); enabled.type = 'checkbox'; enabled.checked = plugin.enabled;
    enabled.setAttribute('aria-label', `Enable ${plugin.name}`);
    enabled.onchange = () => update(enabled.checked ? 'enablePlugin' : 'disablePlugin', { id: plugin.id }, row.querySelector('.chev'));
    toggle.onclick = (event) => event.stopPropagation();
    toggle.append(enabled, element('span', undefined, 'slider'));
    const remove = iconButton(`Uninstall ${plugin.name}`, 'M3 6h18M9 6V4h6v2M5 6l1 14h12l1-14M10 10v6M14 10v6');
    remove.onclick = (event) => {
      event.stopPropagation();
      run(async () => {
        if (await messageBox({ title: `Uninstall ${plugin.name}?`, message: 'This removes the plugin and its settings.', buttons: ['Cancel', 'Uninstall'] }) === 'Uninstall') render(root, await command('removePlugin', { id: plugin.id }));
      }, remove);
    };
    row.insertBefore(toggle, row.lastChild); row.insertBefore(remove, row.lastChild);
    list.append(row);
    const page = element('div', undefined, 'subpage'); page.dataset.subpage = plugin.id; page.dataset.title = plugin.name;
    const description = element('div', undefined, 'card');
    description.append(hintRow(plugin.description || ''));
    if (plugin.error) description.append(hintRow(plugin.error, { warn: true }));
    if (!plugin.enabled) description.append(hintRow('Enable this plugin from its entry row to use its actions.'));
    page.append(description);
    const panel = element('div', undefined, 'card');
    const values = { ...plugin.values };
    for (const setting of plugin.settings || []) {
      const settingRow = element('div', undefined, 'row');
      settingRow.append(info(setting.title));
      const input = element('input'); input.setAttribute('aria-label', setting.title);
      if (setting.type === 'boolean') {
        input.type = 'checkbox'; input.checked = values[setting.key] ?? setting.default;
        input.onchange = () => { values[setting.key] = input.checked; };
        const toggle = element('label', undefined, 'switch'); toggle.append(input, element('span', undefined, 'slider')); settingRow.append(toggle);
      } else {
        input.type = 'text'; input.maxLength = 512; input.value = values[setting.key] ?? setting.default;
        input.oninput = () => { values[setting.key] = input.value; }; settingRow.append(input);
      }
      panel.append(settingRow);
    }
    if (plugin.settings?.length) {
      const saveRow = element('div', undefined, 'row'); saveRow.append(info('Save changes'));
      const save = element('button', 'Save settings', 'btn-text');
      save.onclick = () => update('configurePlugin', { id: plugin.id, values }, save);
      saveRow.append(save); panel.append(saveRow); page.append(heading('Settings'), panel);
    }
    if (plugin.commands?.length) {
      const actions = element('div', undefined, 'card');
      for (const action of plugin.commands) {
        const row = element('div', undefined, 'row'); row.append(info(action.title));
        const button = iconButton(action.title, 'm8 5 11 7-11 7V5z');
        button.disabled = !plugin.enabled; button.dataset.pluginDisabled = String(!plugin.enabled);
        button.onclick = () => update('runPluginCommand', { id: plugin.id, command: action.id }, button);
        row.append(button); actions.append(row);
      }
      page.append(heading('Actions'), actions);
    }
    if (plugin.loaded) page.append(hintRow('To install another version, disable this plugin and restart Kiosk first.'));
    if (plugin.source) {
      const readme = element('div', undefined, 'card'); readme.append(hintRow(plugin.source.repository), pluginReadme(plugin.source));
      page.append(heading('About this plugin'), readme);
    }
    root.append(page);
  }
  if (currentPath.split('/')[0] === 'plugins') {
    showTab(currentPath, { push: false, refresh: false });
    if (document.scrollingElement) document.scrollingElement.scrollTop = scroll;
  }
}
