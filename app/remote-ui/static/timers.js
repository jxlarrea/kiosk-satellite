// The Timers page: what the definitions do not draw. The Share with row's
// picker (rows.js places it) and the Voice timers group that closes the
// page. Mirrors Settings > Timers on the device.
import { deviceText, t } from './localization.js';
import { cmd, state } from './core.js';
import { cachedList, pickItems } from './entity_picker.js';

const SHARE_KEY = 'voice.timers_share_with';

/* ---- Share with ---- */

function sharedTargets() {
  try {
    const list = JSON.parse(`${(state.settings || []).find((s) => s.key === SHARE_KEY)?.value || '[]'}`);
    return Array.isArray(list) ? list.filter((k) => k && typeof k.id === 'string' && k.id) : [];
  } catch (_) {
    return [];
  }
}

// A tablet (mdi tablet).
export const KIOSK_ICON = 'M19,18H5V6H19M21,4H3C1.89,4 1,4.89 1,6V18A2,2 0 0,0 3,20H21A2,2 0 0,0 23,18V6C23,4.89 22.1,4 21,4Z';

// The kiosks Share with can pick, for the shared picker: the ones on the
// network by name with their address, then the picked ones that are not
// on it right now, dimmed, so a pick is never lost while its kiosk is off.
// The device's shareKiosksSpec.
export function shareKiosksSpec() {
  return {
    key: 'kiosks:share',
    loader: async () => {
      const r = await cmd('sharedTimers', {}).catch(() => null);
      const found = (r?.ok && Array.isArray(r.data?.kiosks) ? r.data.kiosks : [])
        .filter((k) => k && k.id)
        .map((k) => ({
          id: String(k.id), name: String(k.name || k.id),
          sub: k.address ? String(k.address) : null, subMono: true,
          iconPath: KIOSK_ICON, group: '', available: true, raw: k,
        }))
        .sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }));
      const ids = new Set(found.map((k) => k.id));
      const away = sharedTargets().filter((k) => !ids.has(k.id)).map((k) => ({
        id: k.id, name: k.name || k.id, sub: null,
        state: t('voiceTimersShareOffline', {}, 'Offline'),
        iconPath: KIOSK_ICON, group: '', available: false, raw: k,
      }));
      return { items: [...found, ...away], notes: {} };
    },
    searchHint: t('voiceTimersShareSearch', {}, 'Search kiosks'),
    emptyText: t('voiceTimersShareEmpty', {},
      'No other kiosks found. Turn on the remote admin and Find other kiosks on each one.'),
    noGroup: '', chips: false, headings: false, byGroupName: false, keep: null,
    ordered: false,
  };
}

// The picked kiosks by the name each has now, at rest in the row.
// Whether any kiosk is picked: the row's icon wears the primary color then.
export function shareWithPicked() { return sharedTargets().length > 0; }

export function shareWithText() {
  const items = cachedList('kiosks:share')?.items || [];
  const picked = sharedTargets().map((k) => items.find((i) => i.id === k.id)?.name || k.name || k.id);
  return picked.length ? picked.join(', ') : t('voiceTimersShareNone', {}, 'No kiosks picked');
}

// Opens the picker. Resolves to the value to store, named from the list so
// a renamed kiosk is stored under its new name, or null when dismissed.
export async function openShareWithPicker(title) {
  const spec = shareKiosksSpec();
  const stored = Object.fromEntries(sharedTargets().map((k) => [k.id, k.name]));
  const ids = await pickItems({ title, spec, selected: sharedTargets().map((k) => k.id) });
  if (!ids) return null;
  const items = cachedList(spec.key)?.items || [];
  return JSON.stringify(ids.map((id) => ({
    id, name: items.find((i) => i.id === id)?.name || stored[id] || '',
  })));
}

/* ---- Voice timers ---- */

// Timers by voice are Home Assistant's own, so this group only points at
// the guide. Last on the page, as on the device.
const VOICE_DOCS_URL = 'https://kiosksatellite.com/docs/voice-satellite/#timers';

export function renderTimersPage() {
  const tab = document.getElementById('tab-timers');
  if (!tab) return;
  tab.querySelectorAll('.timers-built').forEach((n) => n.remove());
  const heading = document.createElement('h2');
  heading.className = 'card-title timers-built';
  heading.textContent = t('timersVoiceSection');
  const card = document.createElement('div');
  card.className = 'card timers-built';
  const row = document.createElement('div');
  row.className = 'row';
  row.dataset.searchId = 'x:timers_voice';
  const info = document.createElement('div');
  info.className = 'info';
  info.innerHTML = '<div class="name"></div><div class="desc"></div>';
  info.querySelector('.name').textContent = t('timersVoiceManage');
  info.querySelector('.desc').textContent = t('timersVoiceHint');
  const link = document.createElement('a');
  link.className = 'btn-ghost';
  link.textContent = deviceText('Open guide');
  link.href = VOICE_DOCS_URL;
  link.target = '_blank';
  link.rel = 'noreferrer';
  row.append(info, link);
  card.appendChild(row);
  tab.append(heading, card);
}
