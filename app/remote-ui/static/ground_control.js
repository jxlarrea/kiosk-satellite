/* The Ground Control page's status rows under its switch, as on the device
   (ground_control_settings.dart): found or not, signed in or not, who is
   enrolled and Open for the Ground Control app. */

import { voiceText } from './localization.js';
import { cmd } from './core.js';
import { readOnlyRow } from './device.js';
import { watchUpdates } from './live.js';

function statusWord(row, text, color) {
  const span = row.lastElementChild;
  span.textContent = text;
  span.style.cssText = `white-space:nowrap; font-weight:500; color:${color}`;
}

async function paint(tab) {
  const gen = (tab._gcGen || 0) + 1;
  tab._gcGen = gen;
  const enabledRow = tab.querySelector('[data-key="ground_control.enabled"]');
  let status = {};
  try {
    const r = await cmd('groundControlStatus', {});
    if (r.ok) status = r.data || {};
  } catch (_) {}
  if (tab._gcGen !== gen) return;
  tab.querySelectorAll('.gc-status').forEach((r) => r.remove());
  if (!enabledRow || status.enabled !== true) return;
  const names = (status.people || []).map((p) => `${p.name || ''}`).filter(Boolean);
  const states = {
    connected: ['Connected', 'var(--primary)', names.length ? names.join(', ') : voiceText('Nobody is enrolled yet.')],
    connecting: ['Connecting', 'var(--muted)', status.baseUrl || ''],
    unreachable: ['Not reachable', 'var(--warn)', status.baseUrl || ''],
    refused: ['Sign-in refused', 'var(--warn)', voiceText("Home Assistant refused this kiosk's token.")],
  };
  const [word, color, detail] = states[status.status]
    || ['Searching', 'var(--muted)', voiceText('Looking for Ground Control on the network.')];
  const row = readOnlyRow(voiceText('Ground Control'), detail, '', false);
  statusWord(row, voiceText(word), color);
  row.classList.add('gc-status');
  enabledRow.after(row);
  if (!status.appUrl) return;
  const app = readOnlyRow(voiceText('Ground Control app'), voiceText('People, enrollment, sessions and settings.'), '', false);
  app.classList.add('gc-status');
  const open = document.createElement('button');
  open.type = 'button';
  open.className = 'btn-ghost';
  open.textContent = voiceText('Open');
  open.style.flexShrink = '0';
  open.addEventListener('click', () => window.open(status.appUrl, '_blank', 'noopener'));
  app.appendChild(open);
  row.after(app);
}

/* Called after every render of the Ground Control tab. */
export function renderGroundControl(tab) {
  if (!tab) return;
  paint(tab);
  if (!tab._gcWatch) {
    tab._gcWatch = watchUpdates(['ground-control'], () => paint(tab), { owner: tab });
  }
}
