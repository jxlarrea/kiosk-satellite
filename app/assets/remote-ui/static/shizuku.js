import { settingRow } from './rows.js';
import { cmd, state as appState } from './core.js';
import { permissionSpecs } from './permissions.js';
import { currentPath } from './tabs.js';
import { hintRow, messageBox, showToast } from './widgets.js';

const permissions = permissionSpecs(() => false);
const actions = [
  ['grantAll', 'Grant all permissions', 'Grant all permissions used by KS, including features that are currently off.'],
  ...permissions.map(spec => [spec.key, spec.name, spec.held]),
];
const permissionNames = Object.fromEntries(permissions.map(spec => [spec.key, spec.name]));
let page, busy = false, loading = false, state = {};
function node(tag, className, text) {
  const el = document.createElement(tag);
  if (className) el.className = className;
  if (text !== undefined) el.textContent = text;
  return el;
}
function row(title, hint, action, buttonLabel = 'Grant') {
  const el = node('div', 'row shizuku-action');
  const info = node('div', 'info'); info.append(node('div', 'name', title), node('div', 'desc', hint)); el.append(info);
  const button = node('button', action === 'grantAll' ? 'btn-primary' : 'btn-ghost', buttonLabel); button.type = 'button'; button.dataset.shizukuAction = action;
  button.onclick = () => run(action, button); el.append(button); return el;
}
function paint() {
  if (!page?.isConnected) return;
  const ready = state.granted === true;
  const status = state.status || 'unavailable';
  const hint = { checking: 'Checking availability', ready: state.uid === 0 ? 'Connected with root access' : 'Connected with shell access', permission_required: 'Grant access and approve the request on this kiosk.', denied: 'Allow Kiosk Satellite in the Shizuku app.', unsupported: 'Shizuku 13 or later is required.', unavailable: 'Start Shizuku on this device.' }[status];
  page.querySelector('[data-connection] .desc').textContent = hint;
  for (const button of page.querySelectorAll('[data-shizuku-action]')) {
    button.disabled = busy || (button.dataset.shizukuAction === 'permission' ? status !== 'permission_required' : !ready);
    if (button.dataset.shizukuAction === 'permission') button.style.display = ready ? 'none' : '';
  }
}
async function refresh() {
  if (!page?.isConnected || busy || loading) return;
  loading = true;
  const target = page;
  try {
    const result = await cmd('getShizukuState', {}, { timeoutMs: 5000 });
    if (target === page) { state = result.ok ? result.data : { status: 'unavailable' }; paint(); }
  } catch (_) {
    if (target === page) { state = { status: 'unavailable' }; paint(); }
  } finally { loading = false; }
}
async function run(action, button) {
  if (busy) return;
  busy = true; button.classList.add('plugin-busy'); paint();
  try {
    const result = await cmd(action === 'permission' ? 'requestShizukuPermission' : 'runShizukuAction', action === 'permission' ? {} : { action }, { timeoutMs: 185000 });
    if (!result.ok) throw new Error(result.error || 'Shizuku request failed');
    if (action === 'permission') {
      state = result.data;
      showToast({ title: 'Shizuku', message: 'Approve the request on the kiosk.' });
    } else if (action === 'identity') {
      const data = result.data;
      await messageBox({ title: 'Connection test', message: data.exitCode === 0 && !data.timedOut ? `Shizuku successfully ran a command with ${state.uid === 0 ? 'root' : 'shell'} access.` : 'Shizuku could not complete the connection test.' });
    } else {
      const rows = result.data.results || [], failed = rows.filter(row => !row.ok);
      const message = !rows.length ? 'All permissions are already granted.' : !failed.length ? 'Android confirmed the requested permissions.' : failed.map(row => `${permissionNames[row.key] || row.key}: ${row.error}`).join('\n');
      await messageBox({ title: 'Permission results', message });
    }
  } catch (error) { showToast({ title: 'Shizuku', message: error.message, kind: 'error' }); }
  finally { busy = false; button.classList.remove('plugin-busy'); paint(); await refresh(); }
}
export function renderShizukuPage(container) {
  if (!container) return;
  page = container; state = { status: 'checking' };
  container.replaceChildren();
  container.append(node('div', 'card-title', 'Connection'));
  const connection = node('div', 'card'); const access = row('Shizuku access', 'Checking availability', 'permission'); access.dataset.connection = '';
  connection.append(access, row('Test connection', 'Read the process identity without changing the device.', 'identity', 'Test'));
  const permissions = node('div', 'card');
  for (const [action, title, hint] of actions) permissions.append(row(title, hint, action));
  container.append(connection);
  const updateSetting = appState.settings?.find(s => s.key === 'shizuku.install_updates');
  if (updateSetting) {
    const updates = node('div', 'card'); updates.append(settingRow(updateSetting)); container.append(updates);
  }
  container.append(node('div', 'card-title', 'Permissions'), permissions,
    node('div', 'card-title', 'Help'));
  const help = node('div', 'card');
  const link = node('a', 'row plugin-guide-row'); link.href = 'https://shizuku.rikka.app/guide/setup/'; link.target = '_blank'; link.rel = 'noopener noreferrer';
  const info = node('div', 'info'); info.append(node('div', 'name', 'Set up Shizuku'), node('div', 'desc', 'Read installation and startup instructions.')); link.append(info);
  help.append(link, hintRow('Shizuku started through ADB must be started again after a device reboot. Shell access does not provide root permissions.'));
  container.append(help); paint();
  if (currentPath === 'device/Shizuku') refresh();
}
setInterval(() => { if (currentPath === 'device/Shizuku' && !document.hidden) refresh(); }, 1500);
