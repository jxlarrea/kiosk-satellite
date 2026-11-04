import { deviceText, messageLanguage, overviewText, t } from './localization.js';
import { api, cmd, state } from './core.js';
import { cameraAction, cameraListRow, cameraToggle } from './cameras.js';
import { attachTtsPickers } from './intercom.js';
import { attachSoundSelect, attachSoundUpload } from './settings.js';
import { musicPickName, pickMusic } from './music_picker.js';
import { hintRow, modalShell, showToast, timeBox } from './widgets.js';

/* ---- Alarms ----
   The kiosk's own alarms. The generic renderer draws the Defaults card
   from the definitions (volume, tone, snooze, silence after, sunrise).
   This module puts the list of alarms and the Set an alarm button above
   it, read from the device's alarmsStatus command, and redraws on the
   alarms event the device pushes whenever anything changes. The same
   status feeds the Overview's banner while an alarm rings, is snoozed or
   runs its sunrise. Mirrors the device's full screen alarm list. */

let status = null;

const byKey = (key) => (state.settings || []).find((s) => s.key === key);

async function loadStatus() {
  try {
    const r = await cmd('alarmsStatus');
    if (r && r.ok !== false && r.data) status = r.data;
  } catch (_) {}
  return status;
}

/* ---- times and days ----
   The page's language, narrowed to the browser's own region when it
   speaks the same language, so an English page in a British browser
   reads 24 hour times and starts the week on Monday. */

function locale() {
  const lang = messageLanguage();
  const langs = (typeof navigator !== 'undefined' && navigator.languages) || [];
  return langs.find((l) => l.split('-')[0].toLowerCase() === lang) || lang;
}

const clockFormat = () => new Intl.DateTimeFormat(locale(), { hour: 'numeric', minute: '2-digit' });

// "HH:mm", the alarm's wall time, as the viewer's locale writes it.
export function alarmTimeText(hhmm) {
  const m = /^(\d{1,2}):(\d{2})$/.exec(`${hhmm || ''}`);
  if (!m) return `${hhmm || ''}`;
  return clockFormat().format(new Date(2000, 0, 1, Number(m[1]), Number(m[2])));
}

// An ISO instant (a ring or a snooze end) as a time of day.
export function alarmClockText(iso) {
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? '' : clockFormat().format(d);
}

// 2023-01-01 was a Sunday: day 0 of the device's numbering.
const dayDate = (day) => new Date(2023, 0, 1 + day);
const dayName = (day, weekday) => new Intl.DateTimeFormat(locale(), { weekday }).format(dayDate(day));

// The weekdays in the order the locale starts its week, 0 = Sunday.
function weekOrder() {
  let first = messageLanguage() === 'en' ? 0 : 1;
  try {
    const loc = new Intl.Locale(locale());
    const info = typeof loc.getWeekInfo === 'function' ? loc.getWeekInfo() : loc.weekInfo;
    if (info && info.firstDay) first = info.firstDay % 7;
  } catch (_) {}
  return Array.from({ length: 7 }, (_, i) => (first + i) % 7);
}

// Today, Tomorrow, the weekday or a short date, for a one time alarm.
function dayText(at, now = new Date()) {
  const start = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const diff = Math.round((start(at) - start(now)) / 86400000);
  if (diff === 0) return t('alarmsToday');
  if (diff === 1) return t('alarmsTomorrow');
  const fmt = diff > 1 && diff < 7 ? { weekday: 'long' } : { weekday: 'short', month: 'short', day: 'numeric' };
  return new Intl.DateTimeFormat(locale(), fmt).format(at);
}

// When an alarm rings, in words: Every day, Weekdays, Weekends or the short
// day names, or for a one time alarm the day it rings on, or Once when off.
function whenText(alarm) {
  const days = [...new Set(alarm.days || [])].filter((d) => d >= 0 && d <= 6).sort();
  if (days.length) {
    const key = days.join(',');
    if (days.length === 7) return t('alarmsEveryDay');
    if (key === '1,2,3,4,5') return t('alarmsWeekdays');
    if (key === '0,6') return t('alarmsWeekends');
    return weekOrder().filter((d) => days.includes(d)).map((d) => dayName(d, 'short')).join(', ');
  }
  const next = alarm.next ? new Date(alarm.next) : null;
  return next && !Number.isNaN(next.getTime()) ? dayText(next) : t('alarmsOnce');
}

/* ---- pieces ---- */

const STROKE = 'viewBox="0 0 24 24" fill="none" stroke="currentColor"'
  + ' stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"';
export const ALARM_ICON = `<svg ${STROKE}><circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 2M5 3 2 6M19 3l3 3"/></svg>`;
const SUNRISE_ICON = `<svg ${STROKE}><path d="M17 18a5 5 0 0 0-10 0M12 2v7M4.2 10.2l1.4 1.4M1 18h2M21 18h2M18.4 11.6l1.4-1.4M23 22H1M8 6l4-4 4 4"/></svg>`;
const PLUS_ICON = `<svg ${STROKE}><path d="M12 5v14M5 12h14"/></svg>`;

function button(label, cls, onClick) {
  const b = document.createElement('button');
  b.type = 'button';
  b.className = cls;
  b.textContent = label;
  b.addEventListener('click', onClick);
  return b;
}

function switchControl(checked, label, onChange) {
  const lbl = document.createElement('label');
  lbl.className = 'switch';
  const input = document.createElement('input');
  input.type = 'checkbox';
  input.checked = checked;
  input.setAttribute('aria-label', label);
  const slider = document.createElement('span');
  slider.className = 'slider';
  lbl.append(input, slider);
  input.addEventListener('change', () => onChange(input));
  return lbl;
}

// A labeled field in the editor: the muted label over the control.
function field(label, control) {
  const wrap = document.createElement('div');
  wrap.className = 'form-field';
  const title = document.createElement('span');
  title.className = 'desc';
  title.textContent = label;
  wrap.append(title, control);
  return wrap;
}

const newAlarmTime = () => `${String((new Date().getHours() + 1) % 24).padStart(2, '0')}:00`;

/* ---- commands ---- */

async function run(name, params) {
  try {
    const r = await cmd(name, params);
    return r && r.ok !== false ? { ok: true, data: r.data } : { ok: false, error: r?.error || '' };
  } catch (e) {
    return { ok: false, error: String(e.message || e) };
  }
}

async function setEnabled(alarm, input) {
  input.disabled = true;
  const out = await run('alarmSetEnabled', { id: alarm.id, on: input.checked });
  input.disabled = false;
  if (!out.ok) {
    input.checked = !input.checked;
    showToast({ title: t('commonSaveFailed'), message: out.error, kind: 'error' });
    return;
  }
  alarm.on = input.checked;
  renderAlarmsPage();
}

async function deleteAlarm(alarm) {
  const out = await run('alarmDelete', { id: alarm.id });
  if (!out.ok) {
    showToast({ title: t('alarmsDeleteFailed'), message: out.error, kind: 'error' });
    return false;
  }
  renderAlarmsPage();
  return true;
}

/* ---- music ----
   The entity field's look for a pick: the music mark, the name and a
   chevron. The mark takes the accent once there is music. */
function musicField({ onClick }) {
  const box = document.createElement('button');
  box.type = 'button';
  box.className = 'dp-field ep-field alarm-music-field';
  const lead = document.createElement('span');
  lead.className = 'dp-field-icon';
  lead.innerHTML = `<svg ${STROKE} width="20" height="20"><path d="M9 17.5V5.5l10-2v12M9 17.5a2.5 2.5 0 1 1-5 0a2.5 2.5 0 1 1 5 0zM19 15.5a2.5 2.5 0 1 1-5 0a2.5 2.5 0 1 1 5 0z"/></svg>`;
  const text = document.createElement('span');
  text.className = 'dp-field-text';
  const chev = document.createElement('span');
  chev.className = 'dp-field-chev';
  chev.innerHTML = `<svg ${STROKE} width="20" height="20"><path d="M6 9l6 6 6-6"/></svg>`;
  box.append(lead, text, chev);
  box.addEventListener('click', onClick);
  return {
    el: box,
    paint: (label, picked) => {
      text.textContent = label;
      lead.classList.toggle('primary', !!picked);
    },
  };
}

// The Alarm music default, null for none.
function defaultMusic() {
  const raw = `${byKey('alarms.music')?.value || ''}`.trim();
  if (!raw) return null;
  try { return JSON.parse(raw); } catch (_) { return null; }
}

function alarmMusicText(music, fallback) {
  if (music.mode === 'none') return t('alarmsMusicNone');
  if (music.mode === 'own' && music.own) return musicPickName(music.own);
  return `${t('alarmsDefaultTone')} · ${fallback ? musicPickName(fallback) : t('alarmsMusicNone')}`;
}

// The alarm's music, the way its tone is picked: Default, None or its own,
// and Choose music for a new one. Mirrors the device's dialog.
function chooseMusic(music, done) {
  const shell = modalShell({ title: t('alarmsMusic'), width: 420, onDismiss: () => shell.close() });
  const fallback = defaultMusic();
  let pick = music.mode;
  const list = document.createElement('div');
  list.className = 'alarm-music-choices';
  const option = (value, title, sub) => {
    const row = document.createElement('label');
    row.className = 'alarm-music-choice';
    const input = document.createElement('input');
    input.type = 'radio';
    input.name = 'alarm-music';
    input.checked = pick === value;
    input.addEventListener('change', () => { pick = value; });
    const textBox = document.createElement('span');
    textBox.className = 'alarm-music-choice-text';
    const name = document.createElement('span');
    name.textContent = title;
    textBox.appendChild(name);
    if (sub) {
      const subEl = document.createElement('span');
      subEl.className = 'desc';
      subEl.textContent = sub;
      textBox.appendChild(subEl);
    }
    row.append(input, textBox);
    list.appendChild(row);
  };
  option('default', t('alarmsDefaultTone'), fallback ? musicPickName(fallback) : t('alarmsMusicNone'));
  option('none', t('alarmsMusicNone'));
  if (music.own) option('own', musicPickName(music.own));
  const choose = document.createElement('button');
  choose.type = 'button';
  choose.className = 'alarm-music-choose';
  choose.innerHTML = `<svg ${STROKE} width="22" height="22"><path d="M9 17.5V5.5l10-2v12M9 17.5a2.5 2.5 0 1 1-5 0a2.5 2.5 0 1 1 5 0zM19 15.5a2.5 2.5 0 1 1-5 0a2.5 2.5 0 1 1 5 0z"/></svg>`;
  const chooseText = document.createElement('span');
  chooseText.textContent = t('musicPickerTitle');
  choose.appendChild(chooseText);
  choose.insertAdjacentHTML('beforeend', `<svg ${STROKE} width="20" height="20" class="alarm-music-chev"><path d="M9 6l6 6-6 6"/></svg>`);
  choose.addEventListener('click', async () => {
    const next = await pickMusic({ current: music.own || fallback });
    if (!next) return;
    music.own = next;
    music.mode = 'own';
    shell.close();
    done();
  });
  shell.body.append(list, choose);
  shell.foot.append(
    button(t('commonCancel'), 'btn-text', () => shell.close()),
    button(t('commonOk'), 'btn-primary', () => { music.mode = pick; shell.close(); done(); }),
  );
}

/* ---- the editor ----/* ---- the editor ----
   Set an alarm and Edit alarm, one dialog: the time, the repeat days, the
   label, the tone, the sunrise, the ease in and the phrase. Picking a tone plays it on the kiosk
   at the alarm volume, as the device's picker does, and closing stops it. */
function openEditor(existing) {
  const edit = !!existing;
  const draft = {
    time: existing?.time || newAlarmTime(),
    days: [...(existing?.days || [])],
  };
  let previewing = false;
  const close = () => {
    if (previewing) cmd('stopAlarmTonePreview').catch(() => {});
    shell.close();
  };
  const shell = modalShell({ title: edit ? t('alarmsEditAlarm') : t('alarmsSetAnAlarm'), width: 460, onDismiss: close });
  shell.card.classList.add('alarm-editor');
  const form = document.createElement('div');
  form.className = 'modal-form';

  const time = timeBox({ title: t('alarmsTime'), value: draft.time, full: true, onPick: (v) => { draft.time = v; } });

  // Seven discs in the locale's week order, filled while the day is on.
  const discs = document.createElement('div');
  discs.className = 'day-discs';
  discs.setAttribute('role', 'group');
  discs.setAttribute('aria-label', t('alarmsRepeat'));
  for (const day of weekOrder()) {
    const disc = document.createElement('button');
    disc.type = 'button';
    disc.className = 'day-disc';
    disc.textContent = dayName(day, 'narrow');
    disc.title = dayName(day, 'long');
    const paint = () => {
      const on = draft.days.includes(day);
      disc.classList.toggle('on', on);
      disc.setAttribute('aria-pressed', on ? 'true' : 'false');
    };
    paint();
    disc.addEventListener('click', () => {
      draft.days = draft.days.includes(day) ? draft.days.filter((d) => d !== day) : [...draft.days, day];
      paint();
    });
    discs.appendChild(disc);
  }

  const label = document.createElement('input');
  label.type = 'text';
  label.className = 'field';
  label.maxLength = 40;
  label.value = existing?.label || '';
  label.placeholder = t('alarmsAddLabel');

  // Default (the Alarm tone setting, named), the built-in alarm, then the
  // sounds folder. A file that has gone stays listed, marked.
  const tone = document.createElement('select');
  tone.className = 'field';
  const current = existing?.tone || '';
  const fillTones = (sounds) => {
    const fallback = `${byKey('alarms.tone')?.value || ''}`;
    const names = [...sounds];
    if (current && current !== 'builtin' && !names.includes(current)) names.push(current);
    tone.innerHTML = '';
    [['', `${t('alarmsDefaultTone')} (${fallback || t('alarmsBuiltInTone')})`],
      ['builtin', t('alarmsBuiltInTone')],
      ...names.map((n) => [n, sounds.includes(n) ? n : t('intercomMissingFile', { file: n })])]
      .forEach(([value, text]) => {
        const opt = document.createElement('option');
        opt.value = value;
        opt.textContent = text;
        opt.selected = value === current;
        tone.appendChild(opt);
      });
  };
  fillTones([]);
  cmd('listNotificationSounds')
    .then((r) => { if (tone.isConnected) fillTones((r?.data || {}).sounds || []); })
    .catch(() => {});
  tone.addEventListener('change', () => {
    previewing = true;
    cmd('previewAlarmTone', { tone: tone.value }).catch(() => {});
  });

  // Music from the library rings instead of the tone, and the tone rings
  // when the music cannot play: Default follows the Alarm music setting,
  // None keeps to the tone. The field shows once a source is set up, or
  // once there is music to show, as on the device.
  const music = { own: existing?.music && existing.music !== 'none' ? existing.music : null,
    mode: existing?.music === 'none' ? 'none' : existing?.music ? 'own' : 'default' };
  const musicBox = musicField({ label: '', onClick: () => chooseMusic(music, () => paintMusic()) });
  const paintMusic = () => {
    const fallback = defaultMusic();
    musicBox.paint(alarmMusicText(music, fallback), music.mode === 'own' || (music.mode === 'default' && !!fallback));
  };
  paintMusic();
  const musicRow = field(t('alarmsMusic'), musicBox.el);
  const musicHint = document.createElement('span');
  musicHint.className = 'desc';
  musicHint.textContent = t('alarmsMusicHint');
  musicRow.appendChild(musicHint);
  if (!music.own && !defaultMusic()) {
    musicRow.style.display = 'none';
    cmd('libraryPickerSource').then((r) => {
      if (r && r.ok !== false) musicRow.style.display = '';
    }).catch(() => {});
  }

  const minutes = Number(byKey('alarms.sunrise_minutes')?.value) || 30;
  const sunrise = cameraToggle(t('alarmsSunrise'), existing?.sunrise === true,
    t('alarmsSunriseHint', { minutes }));

  // Shows what the alarm does now. An alarm that never chose follows the
  // default switch, and keeps following it until this switch is touched.
  const seconds = Number(byKey('alarms.ease_in_seconds')?.value) || 30;
  const easeDefault = byKey('alarms.ease_in')?.value === true;
  let easeTouched = typeof existing?.ease === 'boolean';
  const ease = cameraToggle(t('alarmsEaseIn'),
    typeof existing?.ease === 'boolean' ? existing.ease : easeDefault,
    t('alarmsEaseHint', { seconds }));
  ease.input.addEventListener('change', () => { easeTouched = true; });

  const speak = cameraToggle(t('alarmsSpeak'), existing?.speak === true);
  // The default phrase stands in until it is changed, and an unchanged
  // default is saved as empty so it keeps following the setting.
  const fallbackPhrase = `${byKey('alarms.phrase')?.value ?? ''}`;
  const phrase = document.createElement('input');
  phrase.type = 'text';
  phrase.className = 'field';
  phrase.maxLength = 200;
  phrase.value = existing?.phrase || fallbackPhrase;
  const phraseField = field(t('alarmsPhrase'), phrase);
  const phraseHint = document.createElement('span');
  phraseHint.className = 'desc';
  phraseHint.textContent = t('alarmsPhraseHint', { label: '{label}', time: '{time}', day: '{day}' });
  phraseField.appendChild(phraseHint);
  const showPhrase = () => { phraseField.style.display = speak.input.checked ? '' : 'none'; };
  speak.input.addEventListener('change', showPhrase);
  showPhrase();

  form.append(field(t('alarmsTime'), time.el), field(t('alarmsRepeat'), discs),
    field(t('alarmsLabel'), label), field(t('alarmsTone'), tone), musicRow, sunrise.wrap,
    ease.wrap, speak.wrap, phraseField);
  shell.body.appendChild(form);

  // The refusal stays in view under the form, above the fixed actions.
  const error = document.createElement('div');
  error.className = 'msg-error';
  error.style.flex = 'none';
  shell.card.insertBefore(error, shell.foot);

  const save = button(t('commonSave'), 'btn-primary', async () => {
    save.disabled = true;
    error.textContent = '';
    const alarm = {
      time: draft.time,
      days: [...draft.days].sort(),
      label: label.value.trim(),
      tone: tone.value,
      sunrise: sunrise.input.checked,
      speak: speak.input.checked,
      phrase: phrase.value.trim() === fallbackPhrase.trim() ? '' : phrase.value.trim(),
      // A new alarm is set to ring. An edit keeps whatever it was.
      on: edit ? existing.on !== false : true,
    };
    if (easeTouched) alarm.ease = ease.input.checked;
    if (music.mode === 'none') alarm.music = 'none';
    else if (music.mode === 'own' && music.own) alarm.music = music.own;
    if (edit) alarm.id = existing.id;
    const out = await run('alarmSave', { alarm });
    if (!out.ok) {
      error.textContent = out.error === 'duplicate'
        ? t('alarmsDuplicate', { time: alarmTimeText(alarm.time) })
        : out.error || t('commonSaveFailed');
      save.disabled = false;
      return;
    }
    close();
    if (!edit) showToast({ title: t('alarmsSetToast'), kind: 'success' });
    renderAlarmsPage();
  });
  const cancel = button(t('commonCancel'), 'btn-text', close);
  if (edit) {
    const del = button(t('commonDelete'), 'btn-text danger', async () => {
      del.disabled = true;
      if (await deleteAlarm(existing)) close();
      else del.disabled = false;
    });
    shell.foot.append(del);
  }
  shell.foot.append(cancel, save);
}

/* ---- the list ---- */

// One alarm: the time big, the days and label under it (the snooze end in
// the primary color while snoozed), then edit, delete and the switch. The
// actions go on a portrait phone, where a tap on the row edits instead.
function alarmRow(alarm) {
  const snoozed = status.phase === 'snoozed' && status.snoozedUntil
    && (status.ids || []).includes(alarm.id);
  const sub = snoozed
    ? t('alarmsSnoozedUntil', { time: alarmClockText(status.snoozedUntil) })
    : [whenText(alarm), alarm.label].filter(Boolean).join(' · ');
  const timeText = alarmTimeText(alarm.time);
  const edit = cameraAction(t('commonEdit'), () => openEditor(alarm), false, 'pencil');
  edit.classList.add('alarm-action');
  const del = cameraAction(t('commonDelete'), () => deleteAlarm(alarm), false, 'delete');
  del.classList.add('alarm-action');
  const toggle = switchControl(alarm.on !== false, timeText, (input) => setEnabled(alarm, input));
  const row = cameraListRow(timeText, '', [edit, del, toggle], { onClick: () => openEditor(alarm) });
  row.classList.add('alarm-row');
  row.classList.toggle('off', alarm.on === false);
  row.querySelector('.name').classList.add('alarm-time');
  const desc = row.querySelector('.desc');
  desc.classList.add('alarm-when');
  desc.classList.toggle('snoozed', !!snoozed);
  if (alarm.sunrise && !snoozed) {
    const icon = document.createElement('span');
    icon.className = 'alarm-sunrise';
    icon.innerHTML = SUNRISE_ICON;
    desc.appendChild(icon);
  }
  const text = document.createElement('span');
  text.textContent = sub;
  desc.appendChild(text);
  return row;
}

// The Alarm tone row as a dropdown over the sounds folder with the Add a
// sound row under it, the Announcements chime's pair, and the text to
// speech engine, language and voice as Announcements picks them. Done once per render of the
// definition rows and left alone on a list redraw.
function decorateRows(tab) {
  attachTtsPickers('alarms');
  decorateMusicRow(tab);
  const toneRow = tab.querySelector('[data-key="alarms.tone"]');
  const toneDef = byKey('alarms.tone');
  if (toneRow && toneDef && !toneRow.querySelector('select')) {
    attachSoundUpload(toneRow, attachSoundSelect(toneRow, toneDef));
  }
}

// Alarm music under Defaults: the music field over the music picker and
// a button that takes the music out, as on the device.
function decorateMusicRow(tab) {
  const row = tab.querySelector('[data-key="alarms.music"]');
  if (!row || row.querySelector('.alarm-music-field')) return;
  row.querySelector('input')?.remove();
  const wrap = document.createElement('div');
  wrap.className = 'alarm-music';
  const write = async (value) => {
    const res = await api('/api/settings', { method: 'PATCH', body: JSON.stringify({ 'alarms.music': value }) });
    const out = await res.json().catch(() => ({}));
    if (!res.ok || out.rejected?.includes('alarms.music')) {
      showToast({ title: t('commonSaveFailed'), message: out.errors?.['alarms.music'] || '', kind: 'error' });
      return;
    }
    const def = byKey('alarms.music');
    if (def) def.value = value;
    paint();
  };
  const box = musicField({ onClick: async () => {
    const next = await pickMusic({ current: defaultMusic() });
    if (next) await write(JSON.stringify(next));
  } });
  const clear = document.createElement('button');
  clear.type = 'button';
  clear.className = 'icon-btn';
  clear.setAttribute('aria-label', t('alarmsMusicRemove'));
  clear.title = t('alarmsMusicRemove');
  clear.innerHTML = `<svg ${STROKE}><path d="M6 6l12 12M18 6L6 18"/></svg>`;
  clear.addEventListener('click', () => write(''));
  const paint = () => {
    const current = defaultMusic();
    box.paint(current ? musicPickName(current) : t('alarmsMusicNone'), !!current);
    clear.hidden = !current;
  };
  paint();
  wrap.append(box.el, clear);
  row.appendChild(wrap);
}

// The built cards go under the untitled Drawer menu items link card, the
// device's order, or after the fleet banner when a leader pushes this
// category, so the banner keeps the top of the tab.
function putTop(tab, nodes) {
  const menu = tab.querySelector('[data-key="alarms.menu"]')?.closest('.card');
  if (menu) { menu.after(...nodes); return; }
  const banners = tab.querySelectorAll(':scope > .fleet-banner');
  const after = banners.length ? banners[banners.length - 1] : null;
  if (after) after.after(...nodes); else tab.prepend(...nodes);
}

export async function renderAlarmsPage({ fetch = true } = {}) {
  const tab = document.getElementById('tab-alarms');
  if (!tab) return;
  if (fetch || !status) await loadStatus();
  // The hand-built parts go and come back: the definition rows stay.
  tab.querySelectorAll('.alarms-built').forEach((n) => n.remove());
  decorateRows(tab);
  if (!status) {
    const h = hintRow(overviewText('The device did not answer.'));
    h.classList.add('alarms-built');
    putTop(tab, [h]);
    return;
  }
  const heading = document.createElement('h2');
  heading.className = 'card-title alarms-built';
  heading.textContent = t('alarmsTitle');
  const card = document.createElement('div');
  card.className = 'card alarms-built';
  const alarms = status.alarms || [];
  if (!alarms.length) {
    const empty = document.createElement('div');
    empty.className = 'row';
    empty.innerHTML = '<div class="info"><div class="desc"></div></div>';
    empty.querySelector('.desc').textContent = t('alarmsNone');
    card.appendChild(empty);
  }
  for (const alarm of alarms) card.appendChild(alarmRow(alarm));
  const add = document.createElement('div');
  add.className = 'alarms-add alarms-built';
  const set = button(t('alarmsSetAnAlarm'), 'btn-primary', () => openEditor(null));
  set.insertAdjacentHTML('afterbegin', PLUS_ICON);
  add.appendChild(set);
  putTop(tab, [heading, card, add]);
  tab.append(...voiceCards());
}

// Voice alarms live in Home Assistant (the blueprint), so this group only
// points at the guide. Last on the page, after the defaults, as on the
// device.
const VOICE_DOCS_URL = 'https://kiosksatellite.com/docs/alarms/#setting-alarms-by-voice';

function voiceCards() {
  const heading = document.createElement('h2');
  heading.className = 'card-title alarms-built';
  heading.textContent = t('alarmsVoiceSection');
  const card = document.createElement('div');
  card.className = 'card alarms-built';
  const row = document.createElement('div');
  row.className = 'row';
  row.dataset.searchId = 'x:alarms_voice';
  const info = document.createElement('div');
  info.className = 'info';
  info.innerHTML = '<div class="name"></div><div class="desc"></div>';
  info.querySelector('.name').textContent = t('alarmsVoiceManage');
  info.querySelector('.desc').textContent = t('alarmsVoiceHint');
  const link = document.createElement('a');
  link.className = 'btn-ghost';
  link.textContent = deviceText('Open guide');
  link.href = VOICE_DOCS_URL;
  link.target = '_blank';
  link.rel = 'noreferrer';
  row.append(info, link);
  card.appendChild(row);
  return [heading, card];
}

/* ---- lifecycle ---- */

export function alarmsShown() {
  renderAlarmsPage();
}

document.addEventListener('ks-event', (e) => {
  if (e.detail?.event !== 'alarms') return;
  // The event carries the status itself: no second read.
  if (e.detail.data && typeof e.detail.data === 'object') status = e.detail.data;
  // Not under an open modal: a redraw would pull the rows from under it.
  if (document.querySelector('.modal-back')) return;
  renderAlarmsPage({ fetch: false });
});
