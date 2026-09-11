import { cmd } from './core.js';
import { updatePluginCharts } from './plugin-charts.js';
import { currentPath, showTab, subpageEntry } from './tabs.js';
import { hintRow, messageBox, modalShell, showToast, swatch } from './widgets.js';
import { marked } from './vendor-marked.js';
import DOMPurify from './vendor-purify.js';

const introText = 'Plugins add additional community developed features to Kiosk Satellite.';
const trustNotice = 'Plugins run code inside Kiosk Satellite and can access app data and granted Android permissions. A faulty or malicious plugin can expose private information or stop the app from working. Only install plugins from authors you trust.';
let busy = false;
const maxZipBytes = 4 * 1024 * 1024;

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
    const result = await cmd('getPluginState');
    if (!result.ok) throw new Error(result.error);
    render(root, result.data);
  } catch (error) {
    showToast({ title: 'Plugin Manager', message: error.message, kind: 'error' });
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
    row.append(label, input); form.append(row, hintRow("Make sure you trust the plugin's author and its code before installing it.")); modal.body.append(form);
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
    for (const [title, value] of Object.entries({ ...(preview.installedVersion ? { 'Installed version': preview.installedVersion } : {}), Version: plugin.version, Author: plugin.author, License: plugin.license })) {
      const row = element('div', undefined, 'row');
      row.append(element('span', title, 'info'), element('span', value, 'desc')); modal.body.append(row);
    }
    modal.body.append(pluginReadme(preview), hintRow(trustNotice, { warn: true }),
      hintRow('New plugins start disabled. Updates preserve the enabled state and automatically restart running plugins.'));
    if (!preview.compatible) modal.body.append(hintRow(preview.compatibilityError, { warn: true }));
    const cancel = element('button', 'Cancel', 'btn-text');
    cancel.onclick = () => { modal.close(); resolve(false); };
    const install = element('button', preview.installedVersion ? 'Trust and update' : 'Trust and install', 'btn-primary');
    install.disabled = !preview.compatible;
    install.onclick = () => { modal.close(); resolve(true); };
    modal.foot.append(cancel, install);
  });
}

function confirmZip(file) {
  return new Promise((resolve) => {
    const modal = modalShell({ title: 'Install from ZIP', width: 520 });
    modal.body.append(hintRow(file.name), hintRow(trustNotice, { warn: true }),
      hintRow('New plugins start disabled. Updates preserve the enabled state and automatically restart running plugins.'));
    const cancel = element('button', 'Cancel', 'btn-text');
    cancel.onclick = () => { modal.close(); resolve(false); };
    const install = element('button', 'Trust and install', 'btn-primary');
    install.onclick = () => { modal.close(); resolve(true); };
    modal.foot.append(cancel, install);
  });
}

async function zipBase64(file) {
  const bytes = new Uint8Array(await file.arrayBuffer());
  if (!bytes.length || bytes.length > maxZipBytes) throw new Error('Plugin ZIP must be at most 4 MB');
  let binary = '';
  for (let start = 0; start < bytes.length; start += 8192) {
    binary += String.fromCharCode(...bytes.subarray(start, start + 8192));
  }
  return btoa(binary);
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

function actionOptionsDialog(action, options) {
  return new Promise((resolve) => {
    const shell = modalShell({ title: action.title, onDismiss: () => { shell.close(); resolve(null); } });
    shell.body.append(hintRow('To assign a gesture, open Gestures and choose Run a plugin action.'));
    const selected = { drawer: options.drawer === true, homeAssistant: options.homeAssistant === true };
    for (const [key, title, description] of [
      ['drawer', 'Show in kiosk drawer', 'Also available while locked if the kiosk drawer is allowed.'],
      ['homeAssistant', 'Expose to Home Assistant', 'Adds a button to the kiosk ESPHome device. Requires ESPHome and native entities.'],
    ]) {
      const row = element('div', undefined, 'row'); row.append(info(title, description));
      const input = element('input'); input.type = 'checkbox'; input.checked = selected[key]; input.setAttribute('aria-label', title);
      input.onchange = () => { selected[key] = input.checked; };
      const toggle = element('label', undefined, 'switch'); toggle.append(input, element('span', undefined, 'slider')); row.append(toggle); shell.body.append(row);
    }
    const cancel = element('button', 'Cancel', 'btn-text'); cancel.onclick = () => { shell.close(); resolve(null); };
    const save = element('button', 'Save', 'btn-primary'); save.onclick = () => { shell.close(); resolve(selected); };
    shell.foot.append(cancel, save);
  });
}

function render(root, state) {
  const plugins = state.plugins || [];
  const pluginsEnabled = state.enabled === true;
  const scroll = document.scrollingElement?.scrollTop || 0;
  root.replaceChildren();
  const introduction = element('div', undefined, 'card');
  const masterRow = element('div', undefined, 'row');
  masterRow.append(info('Enable Plugins', introText));
  const masterToggle = element('label', undefined, 'switch plugin-master-switch');
  const master = element('input'); master.type = 'checkbox'; master.checked = pluginsEnabled;
  master.setAttribute('aria-label', 'Enable Plugins');
  masterToggle.append(master, element('span', undefined, 'slider')); masterRow.append(masterToggle);
  introduction.append(masterRow);
  const installCard = element('div', undefined, 'card');
  const addRow = element('div', undefined, 'row plugin-add-row');
  addRow.append(info('Add plugin', 'Install from a GitHub repository'));
  const add = iconButton('Add plugin', 'M12 5v14M5 12h14'); addRow.append(add);
  const warning = hintRow(trustNotice, { warn: true }); warning.classList.add('plugin-install-warning');
  installCard.append(addRow, warning);
  const list = element('div', undefined, 'card');
  const developerTools = element('div', undefined, 'card');
  const zipRow = element('div', undefined, 'row plugin-add-row');
  zipRow.append(info('Install from ZIP', 'For developers only: test a local build'));
  const upload = iconButton('Install from ZIP', 'M12 16V4m-4 4 4-4 4 4M4 16v4h16v-4');
  const fileInput = element('input'); fileInput.type = 'file'; fileInput.accept = '.zip,application/zip'; fileInput.hidden = true;
  fileInput.setAttribute('aria-label', 'Plugin ZIP');
  zipRow.append(upload, fileInput); developerTools.append(zipRow);
  const guideRow = element('a', undefined, 'row plugin-guide-row');
  guideRow.href = 'https://github.com/jxlarrea/kiosk-satellite-plugin-hello-world';
  guideRow.target = '_blank'; guideRow.rel = 'noopener noreferrer';
  guideRow.append(info('Create a plugin', 'Learn how to create plugins with the Hello World template and documentation.'));
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
    root.querySelectorAll('button,input,select').forEach((el) => { el.disabled = true; });
    trigger.classList.add('plugin-busy');
    try { await action(); }
    catch (failure) { showToast({ title: 'Plugin Manager', message: failure.message, kind: 'error' }); }
    finally {
      trigger.classList.remove('plugin-busy'); busy = false;
      root.removeAttribute('aria-busy');
      root.querySelectorAll('button,input,select').forEach((el) => { el.disabled = el.dataset.pluginDisabled === 'true'; });
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
  root.append(installCard, heading('Installed plugins'), list, heading('Developer Tools'), developerTools);
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
      if (!file.size || file.size > maxZipBytes) throw new Error('Plugin ZIP must be at most 4 MB');
      if (!await confirmZip(file)) return;
      const data = await zipBase64(file);
      await command('installPlugin', { data, trusted: true });
      await refresh();
    }, upload);
  };
  addRow.onclick = (event) => { if (!event.target.closest('button') && !busy) add.click(); };
  if (!plugins.length) list.append(hintRow('No plugins installed. Add a repository to get started.'));
  for (const plugin of plugins) {
    const row = subpageEntry('plugins', plugin.id, { iconName: 'Plugins' });
    row.querySelector('.name').textContent = plugin.name;
    const repository = plugin.source?.repository?.match(/^https:\/\/github\.com\/([^/]+\/[^/]+?)(?:\.git)?\/?$/i)?.[1];
    row.querySelector('.desc').textContent = `${repository || 'ZIP'} · ${plugin.version}`;
    row.addEventListener('click', (event) => { if (busy) event.stopImmediatePropagation(); }, true);
    row.setAttribute('role', 'link'); row.tabIndex = 0;
    row.onkeydown = (event) => {
      if (event.target === row && (event.key === 'Enter' || event.key === ' ')) { event.preventDefault(); showTab(`plugins/${plugin.id}`); }
    };
    const toggle = element('label', undefined, 'switch');
    const enabled = element('input'); enabled.type = 'checkbox'; enabled.checked = plugin.enabled;
    enabled.setAttribute('aria-label', `Enable ${plugin.name}`);
    enabled.disabled = !pluginsEnabled; enabled.dataset.pluginDisabled = String(!pluginsEnabled);
    enabled.onchange = () => update(enabled.checked ? 'enablePlugin' : 'disablePlugin', { id: plugin.id }, row.querySelector('.chev'));
    toggle.onclick = (event) => event.stopPropagation();
    toggle.append(enabled, element('span', undefined, 'slider'));
    const remove = iconButton(`Uninstall ${plugin.name}`, 'M3 6h18M9 6V4h6v2M5 6l1 14h12l1-14M10 10v6M14 10v6');
    remove.onclick = (event) => {
      event.stopPropagation();
      run(async () => {
        if (await messageBox({ title: `Uninstall ${plugin.name}?`, message: 'This removes the plugin and its settings.', buttons: ['Cancel', 'Uninstall'] }) === 'Uninstall') {
          await command('removePlugin', { id: plugin.id }); await refresh();
        }
      }, remove);
    };
    row.firstElementChild.replaceWith(toggle);
    const about = iconButton(`About ${plugin.name}`, 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20ZM12 11v6M12 7h.01');
    about.onclick = (event) => {
      event.stopPropagation();
      const modal = modalShell({ title: plugin.name, width: 760 });
      modal.body.append(plugin.source ? pluginReadme(plugin.source)
        : element('p', 'This plugin was installed from ZIP and has no repository README.'));
      const close = element('button', 'Close', 'btn-text'); close.onclick = () => modal.close();
      modal.foot.append(close);
    };
    const check = iconButton(`Check for updates for ${plugin.name}`, 'M3 11a9 9 0 1 1 2.6 7.4M3 4v7h7M12 7v5l3 2');
    check.disabled = !plugin.source?.repository; check.dataset.pluginDisabled = String(check.disabled);
    check.onclick = (event) => {
      event.stopPropagation();
      run(async () => {
        const preview = await command('checkPluginUpdate', { id: plugin.id });
        if (!preview.updateAvailable) {
          showToast({ title: plugin.name, message: 'No updates available.' });
          return;
        }
        if (await confirmPreview(preview)) {
          try { await command('installPluginRepository', { previewId: preview.previewId, trusted: true }); }
          finally { await refresh(); }
        }
      }, check);
    };
    row.insertBefore(check, row.lastChild);
    row.insertBefore(about, row.lastChild); row.insertBefore(remove, row.lastChild);
    list.append(row);
    const page = element('div', undefined, 'subpage'); page.dataset.subpage = plugin.id; page.dataset.title = plugin.name;
    const description = element('div', undefined, 'card');
    const introRow = element('div', undefined, 'row');
    introRow.append(info(plugin.description || ''));
    description.append(introRow);
    if (plugin.status) description.append(hintRow(plugin.status, { warn: plugin.statusError === true }));
    if (plugin.error) description.append(hintRow(plugin.error, { warn: true }));
    if (!pluginsEnabled) description.append(hintRow('Enable Plugins to run this plugin.'));
    else if (!plugin.enabled) description.append(hintRow('Enable this plugin from its entry row to run it.'));
    page.append(description);
    const charts = element('div', undefined, 'plugin-charts'); charts.hidden = true; page.append(charts);
    const groups = new Map();
    const values = { ...plugin.values };
    const saveSetting = (key, value, trigger) => run(async () => {
      try {
        await command('configurePlugin', { id: plugin.id, values: { ...plugin.values, [key]: value } });
      } finally {
        await refresh();
      }
    }, trigger);
    for (const setting of plugin.settings || []) {
      const group = setting.group || 'Settings';
      if (!groups.has(group)) {
        const panel = element('div', undefined, 'card'); groups.set(group, panel);
        page.append(heading(group), panel);
      }
      const panel = groups.get(group);
      const settingRow = element('div', undefined, 'row');
      settingRow.append(info(setting.title, setting.description));
      const input = element('input'); input.setAttribute('aria-label', setting.title);
      if (setting.type === 'boolean') {
        input.type = 'checkbox'; input.checked = values[setting.key] ?? setting.default;
        input.onchange = () => saveSetting(setting.key, input.checked, input);
        const toggle = element('label', undefined, 'switch'); toggle.append(input, element('span', undefined, 'slider')); settingRow.append(toggle);
      } else if (setting.type === 'number') {
        input.type = 'range'; input.min = setting.min; input.max = setting.max; input.step = setting.step || 1;
        input.value = values[setting.key] ?? setting.default;
        const control = element('div', undefined, 'plugin-range');
        const output = element('span', `${input.value} ${setting.unit || ''}`.trim(), 'desc');
        input.oninput = () => { values[setting.key] = Number(input.value); output.textContent = `${input.value} ${setting.unit || ''}`.trim(); };
        input.onchange = () => saveSetting(setting.key, Number(input.value), input);
        control.append(input, output); settingRow.append(control);
      } else if (setting.type === 'select') {
        const select = element('select'); select.setAttribute('aria-label', setting.title);
        for (const choice of setting.options) { const option = element('option', choice); option.value = choice; select.append(option); }
        select.value = values[setting.key] ?? setting.default;
        select.onchange = () => saveSetting(setting.key, select.value, select); settingRow.append(select);
      } else if (setting.type === 'color') {
        const hex = values[setting.key] ?? setting.default;
        const rgb = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16)).join(',');
        settingRow.append(swatch(rgb, setting.title, (selected) => {
          saveSetting(setting.key, '#' + selected.split(',').map((c) => Number(c).toString(16).padStart(2, '0')).join('').toUpperCase(), settingRow.querySelector('button'));
        }));
      } else {
        input.type = 'text'; input.maxLength = 512; input.value = values[setting.key] ?? setting.default;
        input.onchange = () => saveSetting(setting.key, input.value, input);
        input.onkeydown = (event) => { if (event.key === 'Enter') input.blur(); }; settingRow.append(input);
      }
      panel.append(settingRow);
    }
    if (plugin.commands?.length) {
      const actions = element('div', undefined, 'card');
      for (const action of plugin.commands) {
        const row = element('div', undefined, 'row'); row.append(info(action.title));
        const options = plugin.actionOptions?.[action.id] || {};
        row.replaceChildren(info(action.title, ['Gestures', options.drawer && 'Kiosk drawer', options.homeAssistant && 'Home Assistant'].filter(Boolean).join(' · ')));
        const button = iconButton(`Configure ${action.title}`, 'm9 5 7 7-7 7');
        button.onclick = () => run(async () => {
          const selected = await actionOptionsDialog(action, options);
          if (selected) { await command('configurePluginAction', { id: plugin.id, command: action.id, ...selected }); await refresh(); }
        }, button);
        row.append(button); actions.append(row);
      }
      page.append(heading('Actions'), actions);
    }
    root.append(page);
  }
  if (currentPath.split('/')[0] === 'plugins') {
    showTab(currentPath, { push: false, refresh: false });
    if (document.scrollingElement) document.scrollingElement.scrollTop = scroll;
  }
}

let chartsLoading = false;
setInterval(async () => {
  const [tab, id] = currentPath.split('/');
  if (tab !== 'plugins' || !id || document.hidden || chartsLoading || busy) return;
  const page = [...document.querySelectorAll('#tab-plugins > .subpage')].find(el => el.dataset.subpage === id);
  const container = page?.querySelector('.plugin-charts');
  if (!container) return;
  chartsLoading = true;
  try {
    const result = await cmd('getPluginCharts', { id }, { timeoutMs: 5000 });
    if (container.isConnected && currentPath === `plugins/${id}` && result.ok) updatePluginCharts(container, result.data);
  } catch (_) { /* The next poll retries when the connection returns. */ }
  finally { chartsLoading = false; }
}, 1000);
