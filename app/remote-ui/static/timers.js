// The Timers page: what the definitions do not draw. The Share with row's
// picker (rows.js places it) and the Voice timers group that closes the
// page. Mirrors Settings > Timers on the device.
import { deviceText, t } from './localization.js';
import { cmd, state } from './core.js';
import { cachedList, pickItems } from './entity_picker.js';
import { cameraAction, cameraListRow } from './cameras.js';
import { hintRow, modalShell, showToast } from './widgets.js';
import { attachTtsPickers } from './intercom.js';

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

/* ---- The timers ----
   The list the device's timers view shows, read from timersStatus and
   redrawn on the timers event the device pushes whenever one starts,
   changes or goes. Set a timer starts one through Home Assistant, a row
   opens its time left to change it and the bin cancels it. A timer another
   kiosk shares is changed on the kiosk that owns it. */

let status = null;
// When the status arrived, on this page's clock: the times count on from it.
let statusAt = 0;
let ticker = null;

const STROKE = 'viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"';
const PLUS_ICON = `<svg ${STROKE}><path d="M12 5v14M5 12h14"/></svg>`;

function takeStatus(data) {
  status = data;
  statusAt = performance.now();
}

async function loadStatus() {
  try {
    const r = await cmd('timersStatus');
    if (r && r.ok !== false && r.data) takeStatus(r.data);
  } catch (_) {}
  return status;
}

function remainingOf(timer) {
  if (timer.finished) return 0;
  const gone = timer.active ? Math.floor((performance.now() - statusAt) / 1000) : 0;
  return Math.max(0, (timer.remaining || 0) - gone);
}

const two = (n) => String(n).padStart(2, '0');
const clockText = (seconds) =>
  `${two(Math.floor(seconds / 3600))}:${two(Math.floor(seconds % 3600 / 60))}:${two(seconds % 60)}`;

function button(label, cls, onClick) {
  const b = document.createElement('button');
  b.type = 'button';
  b.className = cls;
  b.textContent = label;
  b.addEventListener('click', onClick);
  return b;
}

async function run(name, params) {
  try {
    const r = await cmd(name, params);
    return r && r.ok !== false ? { ok: true } : { ok: false, error: r?.error };
  } catch (e) {
    return { ok: false, error: e?.message };
  }
}

async function removeTimer(timer) {
  const out = await run('timerControl', { id: timer.id, action: timer.finished ? 'dismiss' : 'cancel' });
  if (!out.ok) showToast({ title: t('voiceTimerActionError'), message: out.error, kind: 'error' });
  return out.ok;
}

// Hours, minutes and seconds for a new timer's length or a running one's
// time left, and the name of a new one: Home Assistant cannot rename one.
function openEditor(existing) {
  const edit = !!existing;
  const shell = modalShell({
    title: edit ? t('voiceTimerEditTimer') : t('voiceTimerSetATimer'), width: 460,
    onDismiss: () => shell.close(),
  });
  const form = document.createElement('div');
  form.className = 'modal-form';
  const start = edit ? remainingOf(existing) : 300;
  const parts = document.createElement('div');
  parts.style.cssText = 'display:flex; gap:12px;';
  const numbers = [
    ['voiceTimerHours', 23, Math.floor(start / 3600) % 24],
    ['voiceTimerMinutes', 59, Math.floor(start % 3600 / 60)],
    ['voiceTimerSeconds', 59, start % 60],
  ].map(([label, max, value]) => {
    const input = document.createElement('input');
    input.type = 'number';
    input.className = 'field';
    input.min = '0';
    input.max = String(max);
    input.value = String(value);
    input.inputMode = 'numeric';
    input.style.width = '100%';
    const wrap = document.createElement('label');
    wrap.className = 'form-field';
    wrap.style.cssText = 'flex:1; min-width:0;';
    const title = document.createElement('span');
    title.className = 'desc';
    title.textContent = t(label);
    wrap.append(title, input);
    parts.appendChild(wrap);
    return { input, max };
  });
  form.appendChild(parts);
  let name = null;
  if (!edit) {
    name = document.createElement('input');
    name.type = 'text';
    name.className = 'field';
    name.maxLength = 40;
    const wrap = document.createElement('label');
    wrap.className = 'form-field';
    const title = document.createElement('span');
    title.className = 'desc';
    title.textContent = t('voiceTimerName');
    wrap.append(title, name);
    form.appendChild(wrap);
  } else if (existing.name) {
    const title = document.createElement('div');
    title.className = 'desc';
    title.textContent = existing.name;
    form.prepend(title);
  }
  shell.body.appendChild(form);
  const error = document.createElement('div');
  error.className = 'error';
  error.style.flex = 'none';
  shell.card.insertBefore(error, shell.foot);
  const total = () => numbers.reduce((sum, { input, max }, i) => {
    const v = Math.min(max, Math.max(0, Math.floor(Number(input.value) || 0)));
    return sum + v * [3600, 60, 1][i];
  }, 0);
  const save = button(edit ? t('commonSet') : t('voiceStart'), 'btn-primary', async () => {
    const seconds = total();
    if (seconds <= 0) return;
    save.disabled = true;
    error.textContent = '';
    const out = edit
      ? await run('timerControl', { id: existing.id, action: 'set', seconds })
      : await run('timerStart', { seconds, name: name.value.trim() });
    if (!out.ok) {
      error.textContent = edit ? t('voiceTimerActionError') : t('voiceTimerStartFailed');
      save.disabled = false;
      return;
    }
    shell.close();
  });
  const sync = () => { save.disabled = total() <= 0; };
  numbers.forEach(({ input }) => input.addEventListener('input', sync));
  sync();
  if (edit) {
    const del = button(t('commonDelete'), 'btn-text danger', async () => {
      del.disabled = true;
      if (await removeTimer(existing)) shell.close();
      else del.disabled = false;
    });
    shell.foot.append(del);
  }
  shell.foot.append(button(t('commonCancel'), 'btn-text', () => shell.close()), save);
}

function timerRow(timer) {
  const actions = [];
  if (timer.canEdit) {
    const edit = cameraAction(t('commonEdit'), () => openEditor(timer), false, 'pencil');
    edit.classList.add('alarm-action');
    actions.push(edit);
  }
  actions.push(cameraAction(t('commonDelete'), () => removeTimer(timer), false, 'delete'));
  const row = cameraListRow(clockText(remainingOf(timer)), '', actions,
    timer.canEdit ? { onClick: () => openEditor(timer) } : {});
  row.classList.add('alarm-row', 'timer-row');
  const time = row.querySelector('.name');
  time.classList.add('alarm-time');
  time.style.fontVariantNumeric = 'tabular-nums';
  row._paint = () => { time.textContent = clockText(remainingOf(timer)); };
  const desc = row.querySelector('.desc');
  desc.classList.add('alarm-when');
  const state = timer.finished ? t('voiceTimerTimesUp') : timer.active ? '' : t('voiceTimerPaused');
  const text = document.createElement('span');
  text.textContent = [timer.name || t('voiceTimerDefaultName'), timer.origin, state]
    .filter(Boolean).join(' \u00b7 ');
  desc.appendChild(text);
  return row;
}

function timerCards(tab) {
  const heading = document.createElement('h2');
  heading.className = 'card-title timers-built';
  heading.textContent = t('voiceTimersViewTitle');
  const card = document.createElement('div');
  card.className = 'card timers-built';
  card.dataset.searchId = 'x:timers_manage';
  const timers = status?.timers || [];
  if (!timers.length) {
    const empty = document.createElement('div');
    empty.className = 'row';
    empty.innerHTML = '<div class="info"><div class="desc"></div></div>';
    empty.querySelector('.desc').textContent = t('voiceTimersEmpty');
    card.appendChild(empty);
  }
  for (const timer of timers) card.appendChild(timerRow(timer));
  const add = document.createElement('div');
  add.className = 'alarms-add timers-built';
  if (status?.canStart) {
    const set = button(t('voiceTimerSetATimer'), 'btn-primary', () => openEditor(null));
    set.insertAdjacentHTML('afterbegin', PLUS_ICON);
    add.appendChild(set);
  } else {
    add.appendChild(hintRow(t('voiceTimerStartUnavailable')));
  }
  // After the fleet banner when a leader pushes this category, so the
  // banner keeps the top of the tab.
  const banners = tab.querySelectorAll(':scope > .fleet-banner');
  const after = banners.length ? banners[banners.length - 1] : null;
  if (after) after.after(heading, card, add); else tab.prepend(heading, card, add);
  // The times count down between the device's updates.
  clearInterval(ticker);
  ticker = timers.some((x) => x.active && !x.finished) ? setInterval(() => {
    if (!card.isConnected) { clearInterval(ticker); return; }
    card.querySelectorAll('.timer-row').forEach((row) => row._paint?.());
  }, 1000) : null;
}

export async function renderTimersPage({ fetch = true } = {}) {
  const tab = document.getElementById('tab-timers');
  if (!tab) return;
  if (fetch || !status) await loadStatus();
  tab.querySelectorAll('.timers-built').forEach((n) => n.remove());
  // The text to speech engine, language and voice as Alarms picks them.
  attachTtsPickers('timers');
  timerCards(tab);
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

export function timersShown() {
  renderTimersPage();
}

document.addEventListener('ks-event', (e) => {
  if (e.detail?.event !== 'timers') return;
  // The event carries the status itself: no second read.
  if (e.detail.data && typeof e.detail.data === 'object') takeStatus(e.detail.data);
  // Not under an open modal: a redraw would pull the rows from under it.
  if (document.querySelector('.modal-back')) return;
  if (document.getElementById('tab-timers')?.children.length) renderTimersPage({ fetch: false });
});
