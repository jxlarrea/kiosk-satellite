/* The Ground Control page's status rows under its switch, as on the device
   (ground_control_settings.dart): found or not, signed in or not, who is
   enrolled and Open for the Ground Control app. */

import { t, voiceText } from './localization.js';
import { cmd, state } from './core.js';
import { cachedList, pickItems } from './entity_picker.js';
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

/* Under Features, after Voice Match: Vision Match, coming soon, as on
   the device (GroundControlComingSoonRow). */
function comingSoon(tab) {
  tab.querySelectorAll('.gc-soon').forEach((r) => r.remove());
  const link = tab.querySelector('[data-key="ground_control.voice_match"]');
  if (!link) return;
  const row = readOnlyRow(voiceText('Vision Match'),
    voiceText("Facial recognition using this device's camera."), '', false);
  statusWord(row, voiceText('Coming soon'), 'var(--muted)');
  row.classList.add('gc-soon');
  link.after(row);
}

/* Called after every render of the Ground Control tab. */
export function renderGroundControl(tab) {
  if (!tab) return;
  comingSoon(tab);
  paint(tab);
  if (!tab._gcWatch) {
    tab._gcWatch = watchUpdates(['ground-control'], () => paint(tab), { owner: tab });
  }
}

/* ---- People, under Answer on Chosen people ---- */

const PEOPLE_KEY = 'voice_match.people';

// A person (mdi account).
export const PERSON_ICON = 'M12,4A4,4 0 0,1 16,8A4,4 0 0,1 12,12A4,4 0 0,1 8,8A4,4 0 0,1 12,4M12,14C16.42,14 20,15.79 20,18V20H4V18C4,15.79 7.58,14 12,14Z';

function chosenPeople() {
  try {
    const list = JSON.parse(`${(state.settings || []).find((s) => s.key === PEOPLE_KEY)?.value || '[]'}`);
    return Array.isArray(list) ? list.filter((p) => p && typeof p.id === 'string' && p.id) : [];
  } catch (_) {
    return [];
  }
}

// Everyone enrolled in Ground Control, then the chosen ones it no longer
// has, dimmed, so a pick is never lost while Ground Control is away. The
// device's voiceMatchPeopleSpec.
export function voiceMatchPeopleSpec() {
  return {
    key: 'voice-match:people',
    loader: async () => {
      const r = await cmd('groundControlStatus', {}).catch(() => null);
      const found = (r?.ok && Array.isArray(r.data?.people) ? r.data.people : [])
        .filter((p) => p && p.id)
        .map((p) => ({
          id: String(p.id), name: String(p.name || p.id), sub: null,
          iconPath: PERSON_ICON, group: '', available: true, raw: p,
        }))
        .sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }));
      const ids = new Set(found.map((p) => p.id));
      const gone = chosenPeople().filter((p) => !ids.has(p.id)).map((p) => ({
        id: p.id, name: p.name || p.id, sub: null,
        state: t('voiceMatchPeopleGone', {}, 'No longer in Ground Control'),
        iconPath: PERSON_ICON, group: '', available: false, raw: p,
      }));
      return { items: [...found, ...gone], notes: {} };
    },
    searchHint: t('voiceMatchPeopleSearch', {}, 'Search people'),
    emptyText: t('voiceMatchPeopleEmpty', {}, 'Nobody is enrolled in Ground Control yet.'),
    noGroup: '', chips: false, headings: false, byGroupName: false, keep: null,
    ordered: false,
  };
}

export function peopleChosen() { return chosenPeople().length > 0; }

// The chosen people by the name each has now, at rest in the row.
export function peopleText() {
  const items = cachedList('voice-match:people')?.items || [];
  const names = chosenPeople().map((p) => items.find((i) => i.id === p.id)?.name || p.name || p.id);
  return names.length ? names.join(', ') : t('voiceMatchPeopleNone', {}, 'Anyone enrolled');
}

// Opens the picker. Resolves to the value to store, named from the list so
// a renamed person is stored under the new name, or null when dismissed.
export async function openPeoplePicker(title) {
  const spec = voiceMatchPeopleSpec();
  const stored = Object.fromEntries(chosenPeople().map((p) => [p.id, p.name]));
  const ids = await pickItems({ title, spec, selected: chosenPeople().map((p) => p.id) });
  if (!ids) return null;
  const items = cachedList(spec.key)?.items || [];
  return JSON.stringify(ids.map((id) => ({
    id, name: items.find((i) => i.id === id)?.name || stored[id] || '',
  })));
}
