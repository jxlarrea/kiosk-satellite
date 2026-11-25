/* The Ground Control page's status rows under its switch, as on the device
   (ground_control_settings.dart): found or not, signed in or not, who is
   enrolled, Open for the Ground Control app and its version, architecture
   and whether it runs on the CPU or with CUDA. */

import { t, voiceText } from './localization.js';
import { cmd, state } from './core.js';
import { cachedList, pickItems } from './entity_picker.js';
import { readOnlyRow } from './device.js';
import { watchUpdates } from './live.js';
import { messageBox } from './widgets.js';

function statusWord(row, text, color) {
  const span = row.lastElementChild;
  span.textContent = text;
  span.style.cssText = `white-space:nowrap; font-weight:500; color:${color}`;
}

async function paint(tab) {
  const gen = (tab._gcGen || 0) + 1;
  tab._gcGen = gen;
  const enabledRow = tab.querySelector('[data-key="ground_control.enabled"]');
  // Under the switch and the address it uses, as on the device.
  const anchorRow = tab.querySelector('[data-key="ground_control.address"]') || enabledRow;
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
    pending: ['Waiting for approval', 'var(--warn)', voiceText('Approve this kiosk on the Kiosks page of the Ground Control app.')],
    declined: ['Declined', 'var(--warn)', voiceText('This kiosk was declined in the Ground Control app. Approve it on the Kiosks page.')],
    unsigned: ['Not accepted', 'var(--warn)', voiceText("This build of Kiosk Satellite can't connect to Ground Control.")],
  };
  const [word, color, detail] = states[status.status]
    || ['Searching', 'var(--muted)', voiceText('Looking for Ground Control on the network.')];
  const row = readOnlyRow(voiceText('Ground Control'), detail, '', false);
  statusWord(row, voiceText(word), color);
  row.classList.add('gc-status');
  anchorRow.after(row);
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
  // What the service said about itself when the kiosk connected. An older
  // Ground Control only gives its version.
  const install = status.install || {};
  const values = [];
  if (status.version) values.push(['Version', status.version]);
  if (install.arch) values.push(['Architecture', install.arch]);
  if (install.install) values.push(['Runs on', install.onGpu === true ? 'CUDA' : 'CPU']);
  let last = app;
  for (const [title, text] of values) {
    const info = readOnlyRow(voiceText(title), '', text, false);
    info.lastElementChild.style.color = 'var(--muted)';
    info.classList.add('gc-status');
    last.after(info);
    last = info;
  }
}

/* Called after every render of the Ground Control tab. */
export function renderGroundControl(tab) {
  if (!tab) return;
  paint(tab);
  if (!tab._gcWatch) {
    tab._gcWatch = watchUpdates(['ground-control'], () => paint(tab), { owner: tab });
  }
}

/* ---- People, under Answer on Chosen people ---- */

const PEOPLE_KEY = 'voice_match.people';

// A person (mdi account).
export const PERSON_ICON = 'M12,4A4,4 0 0,1 16,8A4,4 0 0,1 12,12A4,4 0 0,1 8,8A4,4 0 0,1 12,4M12,14C16.42,14 20,15.79 20,18V20H4V18C4,15.79 7.58,14 12,14Z';

// Ground Control's status when the people list last loaded: its people are
// known only once it is connected.
let peopleStatus = null;

// The picker's list key for a people setting: Voice Match's own, or
// another setting stored the same way (Screensaver > Face Detection > People).
function listKey(key) { return key === PEOPLE_KEY ? 'voice-match:people' : `ground-control:${key}`; }

function chosenPeople(key = PEOPLE_KEY) {
  try {
    const list = JSON.parse(`${(state.settings || []).find((s) => s.key === key)?.value || '[]'}`);
    return Array.isArray(list) ? list.filter((p) => p && typeof p.id === 'string' && p.id) : [];
  } catch (_) {
    return [];
  }
}

// Everyone enrolled in Ground Control, then the chosen ones it no longer
// has, dimmed, so a pick is never lost while Ground Control is away. The
// device's voiceMatchPeopleSpec.
export function voiceMatchPeopleSpec(key = PEOPLE_KEY) {
  return {
    key: listKey(key),
    loader: async () => {
      const r = await cmd('groundControlStatus', {}).catch(() => null);
      peopleStatus = r?.ok ? r.data?.status ?? null : null;
      const found = (r?.ok && Array.isArray(r.data?.people) ? r.data.people : [])
        .filter((p) => p && p.id)
        .map((p) => ({
          id: String(p.id), name: String(p.name || p.id), sub: null,
          iconPath: PERSON_ICON, group: '', available: true, raw: p,
        }))
        .sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }));
      const ids = new Set(found.map((p) => p.id));
      const gone = chosenPeople(key).filter((p) => !ids.has(p.id)).map((p) => ({
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

export function peopleChosen(key = PEOPLE_KEY) { return chosenPeople(key).length > 0; }

// The chosen people by the name each has now, at rest in the row.
export function peopleText(key = PEOPLE_KEY) {
  const items = cachedList(listKey(key))?.items || [];
  const names = chosenPeople(key).map((p) => items.find((i) => i.id === p.id)?.name || p.name || p.id);
  if (names.length) return names.join(', ');
  return key === PEOPLE_KEY ? t('voiceMatchPeopleNone', {}, 'Anyone enrolled')
    : t('screensaverFacePeopleNone', {}, 'Anyone recognized');
}

// Chosen people this Ground Control doesn't have, as after moving to
// another one, or '' when there are none. The device's People row.
export function peopleMissingText(key = PEOPLE_KEY) {
  if (peopleStatus !== 'connected') return '';
  const items = cachedList(listKey(key))?.items || [];
  const missing = chosenPeople(key).filter((p) => !items.find((i) => i.id === p.id && i.available));
  if (!missing.length) return '';
  return t('voiceMatchPeopleMissing', { names: missing.map((p) => p.name || p.id).join(', ') },
    'Not on this Ground Control: {names}. Choose again.');
}

// Opens the picker. Resolves to the value to store, named from the list so
// a renamed person is stored under the new name, or null when dismissed.
export async function openPeoplePicker(title, key = PEOPLE_KEY) {
  const spec = voiceMatchPeopleSpec(key);
  const stored = Object.fromEntries(chosenPeople(key).map((p) => [p.id, p.name]));
  const ids = await pickItems({ title, spec, selected: chosenPeople(key).map((p) => p.id) });
  if (!ids) return null;
  const items = cachedList(spec.key)?.items || [];
  return JSON.stringify(ids.map((id) => ({
    id, name: items.find((i) => i.id === id)?.name || stored[id] || '',
  })));
}

/* ---- The GC tag on settings outside Ground Control ---- */

// MDI face-recognition and account-voice, the icons of Vision Match and Voice Match.
const FACE_ICON = 'M9,11.75A1.25,1.25 0 0,0 7.75,13A1.25,1.25 0 0,0 9,14.25A1.25,1.25 0 0,0 10.25,13A1.25,1.25 0 0,0 9,11.75M15,11.75A1.25,1.25 0 0,0 13.75,13A1.25,1.25 0 0,0 15,14.25A1.25,1.25 0 0,0 16.25,13A1.25,1.25 0 0,0 15,11.75M12,2A10,10 0 0,0 2,12A10,10 0 0,0 12,22A10,10 0 0,0 22,12A10,10 0 0,0 12,2M12,20A8,8 0 0,1 4,12C3.97,11.71 3.97,11.43 4,11.14C6.38,10.1 8.27,8.17 9.26,5.77C11.13,8.42 14.17,10 17.42,10C18.18,10 18.93,9.91 19.67,9.74C20.92,14 18.5,18.43 14.26,19.67C13.5,19.89 12.76,20 12,20M0,2A2,2 0 0,1 2,0H6V2H2V6H0V2M24,22A2,2 0 0,1 22,24H18V22H22V18H24V22M2,24A2,2 0 0,1 0,22V18H2V22H6V24H2M22,0A2,2 0 0,1 24,2V6H22V2H18V0H22Z';
const VOICE_ICON = 'M9,5A4,4 0 0,1 13,9A4,4 0 0,1 9,13A4,4 0 0,1 5,9A4,4 0 0,1 9,5M9,15C11.67,15 17,16.34 17,19V21H1V19C1,16.34 6.33,15 9,15M16.76,5.36C18.78,7.56 18.78,10.61 16.76,12.63L15.08,10.94C15.92,9.76 15.92,8.23 15.08,7.05L16.76,5.36M20.07,2C24,6.05 23.97,12.11 20.07,16L18.44,14.37C21.21,11.19 21.21,6.65 18.44,3.63L20.07,2Z';

// The tag after the title of a setting that only works with Ground Control,
// in its feature's icon (vision or voice). A click says what it means.
// Mirrors the device's GroundControlTag.
export function groundControlTag(feature) {
  const tag = document.createElement('button');
  tag.type = 'button';
  tag.className = 'gc-tag';
  tag.setAttribute('aria-label', t('groundControlTagHint', {}, 'A Ground Control setting. Learn more'));
  tag.innerHTML = `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="${feature === 'voice' ? VOICE_ICON : FACE_ICON}"/></svg><span>GC</span>`;
  tag.addEventListener('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
    messageBox({
      title: () => t('groundControlTagTitle', {}, 'A Ground Control setting'),
      message: () => (feature === 'voice'
        ? t('groundControlTagVoice', {}, 'This setting needs Kiosk Satellite Ground Control and Voice Match.')
        : t('groundControlTagVision', {}, 'This setting needs Kiosk Satellite Ground Control and Face Recognition.')),
      buttons: ['Close'],
      buttonText: () => t('commonClose', {}, 'Close'),
    });
  });
  return tag;
}

// A Ground Control setting's value in a few words, for its row under
// Vision Match > Used in other settings. The device's groundControlValueText.
export function groundControlValueText(key) {
  const s = (state.settings || []).find((o) => o.key === key);
  if (!s) return '';
  if (typeof s.value === 'boolean') {
    return s.value ? t('groundControlValueOn', {}, 'On') : t('groundControlValueOff', {}, 'Off');
  }
  const label = s.optionLabels?.[s.value] || String(s.value ?? '');
  if (key === 'screensaver.face_who' && s.value === 'people') {
    const names = chosenPeople('screensaver.face_people').map((p) => p.name || p.id);
    if (names.length) return t('groundControlValuePeople', { option: label, names: names.join(', ') }, `${label}: ${names.join(', ')}`);
  }
  return label;
}
