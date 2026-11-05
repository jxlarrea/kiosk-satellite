import { esphomeText, messageLanguage, intercomText, intercomError, intercomAnnouncing, t } from './localization.js';
import { watchUpdates } from './live.js';
import { api, cmd, state } from './core.js';
import { attachSoundSelect, attachSoundUpload, loadSettings } from './settings.js';
import { syncGatedRows } from './rows.js';
import { radioRow } from './views.js';
import { entitySpec, pickField, pickItem } from './entity_picker.js';
import { currentPath, showTab } from './tabs.js';
import { copyBox, hintRow, modalShell, showToast } from './widgets.js';

/* ---- Intercom ----
   Kiosks on the same network talk to each other. The generic renderer
   draws the definition rows into the tab (enable, key, Answer, Talk).
   This module decorates them from the device's intercomStatus command,
   the same shape the device's own page draws, and redraws on the intercom
   event the device pushes over the socket. Nothing here can talk or take
   a call: a browser opens the microphone only on a secure origin and the
   remote admin is plain http, and a call is answered on the kiosk. The
   one thing it can do to a call is end it. */

let status = null;
let tickTimer = null;
let busy = false;
// The copy box on the key row, updated in place when the key changes.
let keyBox = null;

const byKey = (key) => (state.settings || []).find((s) => s.key === key);

async function loadStatus() {
  try {
    const r = await cmd('intercomStatus');
    if (r.ok) status = r.data;
  } catch (_) {}
  return status;
}

/* ---- pieces ---- */

const titled = (title) => {
  const h = document.createElement('h2');
  h.className = 'card-title intercom-built';
  h.textContent = title;
  const card = document.createElement('div');
  card.className = 'card intercom-built';
  return [h, card];
};

function tag(text, kind = '') {
  const t = document.createElement('span');
  t.className = 'tag' + (kind ? ' ' + kind : '');
  t.textContent = text;
  return t;
}

// A row with a name and a description, nothing trailing yet.
function infoRow(name, desc) {
  const row = document.createElement('div');
  row.className = 'row';
  const info = document.createElement('div');
  info.className = 'info';
  info.innerHTML = '<div class="name"></div><div class="desc"></div>';
  info.querySelector('.name').textContent = name;
  info.querySelector('.desc').textContent = desc;
  row.appendChild(info);
  return row;
}

// A kiosk row: the name on its own line, the address and its tags on the
// second. The switcher's shape, as on the Fleet Management page.
function kioskRow({ name, address, version, tags = [], dim = false }) {
  const row = document.createElement('div');
  row.className = 'row fleet-row self' + (dim ? ' dim' : '');
  const info = document.createElement('div');
  info.className = 'info';
  const nameEl = document.createElement('div');
  nameEl.className = 'name';
  const nameText = document.createElement('span');
  nameText.textContent = name || address;
  nameEl.appendChild(nameText);
  const desc = document.createElement('div');
  desc.className = 'desc';
  const ip = document.createElement('span');
  ip.textContent = address || '';
  desc.appendChild(ip);
  if (version) desc.appendChild(tag(version, ''));
  for (const t of tags) desc.appendChild(t);
  info.append(nameEl, desc);
  row.appendChild(info);
  return row;
}

function button(label, cls, onClick) {
  const b = document.createElement('button');
  b.type = 'button';
  b.className = cls;
  b.textContent = label;
  b.style.flexShrink = '0';
  b.addEventListener('click', onClick);
  return b;
}

async function run(name, params = {}, { reload = true } = {}) {
  if (busy) return null;
  busy = true;
  let out;
  try { out = await cmd(name, params); }
  catch (_) { out = { ok: false, error: intercomText("The device did not answer.") }; }
  busy = false;
  if (reload) await loadStatus();
  if (!out.ok) showToast({ title: intercomText("Intercom"), message: intercomError(out.error || '', status), kind: 'error' });
  if (reload) renderIntercomPage({ fetch: false });
  return out;
}

const mmss = (since) => {
  const s = Math.max(0, Math.floor((Date.now() - since) / 1000));
  const pad = (n) => String(n).padStart(2, '0');
  return `${pad(Math.floor(s / 60))}:${pad(s % 60)}`;
};

/* ---- the key ---- */

// Paste a key from another kiosk, or make a new one. Either lands on the
// device at once: there is no draft to lose, so the dialog closes on
// success and stays open with the toast on a refusal.
function openKeyDialog() {
  const current = `${byKey('intercom.key')?.value || ''}`;
  const shell = modalShell({ title: intercomText("Intercom key"), width: 480, onDismiss: () => shell.close() });
  const input = document.createElement('input');
  input.className = 'field';
  input.value = current;
  input.spellcheck = false;
  input.autocomplete = 'off';
  input.style.cssText = 'width:100%; font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;';
  shell.body.appendChild(input);
  shell.body.appendChild(hintRow(intercomText("Kiosks with this key can call each other. A new key cuts this kiosk off from the others until they get it too.")));
  const apply = async (params) => {
    const out = await run('intercomSetKey', params, { reload: false });
    if (!out?.ok) return;
    const key = `${out.data?.key || ''}`;
    const def = byKey('intercom.key');
    if (def) def.value = key;
    if (keyBox) keyBox.set(key);
    showToast({ title: intercomText("Key changed"), kind: 'success' });
    shell.close();
    await loadStatus();
    renderIntercomPage({ fetch: false });
  };
  const save = () => {
    const key = input.value.trim();
    if (!key) { input.focus(); return; }
    apply({ key });
  };
  input.addEventListener('keydown', (e) => { if (e.key === 'Enter') save(); });
  const regen = button(intercomText("Regenerate"), 'btn-ghost', () => apply({ regenerate: true }));
  regen.style.marginRight = 'auto';
  shell.foot.append(
    regen,
    button(intercomText("Cancel"), 'btn-text', () => shell.close()),
    button(intercomText("Save"), 'btn-primary', save),
  );
  input.focus();
  input.select();
}

/* ---- the definition rows ---- */

// The rows the generic renderer drew, made to match the device page: the
// key as a copy box with a Change row under it and the ring sound as a
// dropdown over the sounds folder. Each is done once per render of the
// rows and left alone on a status redraw.
function decorateRows(tab) {
  const keyRow = tab.querySelector('[data-key="intercom.key"]');
  const keyInput = keyRow?.querySelector('input');
  if (keyInput && !keyRow.querySelector('.copy-box')) {
    keyBox = copyBox(keyInput.value, { placeholder: keyInput.placeholder || intercomText("Not set") });
    keyInput.replaceWith(keyBox.el);
    // Lives with the definition rows: wiped and redrawn with them on a
    // settings load, left alone on a status redraw.
    const change = infoRow(intercomText("Change key"), intercomText("Paste the key from another kiosk, or make a new one."));
    change.appendChild(button(intercomText("Change"), 'btn-ghost', openKeyDialog));
    keyRow.insertAdjacentElement('afterend', change);
  }

  const soundRow = tab.querySelector('[data-key="intercom.ring_sound"]');
  const soundDef = byKey('intercom.ring_sound');
  if (soundRow && soundDef && !soundRow.querySelector('select')) {
    attachSoundUpload(soundRow, attachSoundSelect(soundRow, soundDef));
  }

}

/* ---- the live call ---- */

const LIVE = new Set(['calling', 'ringing', 'in_call', 'broadcasting', 'listening']);

function liveCard() {
  const call = status.call || {};
  const peer = call.peer || {};
  const name = peer.name || peer.address || intercomText("a kiosk");
  const targets = call.targets || [];
  const heard = targets.filter((t) => t.status === 'listening').length || targets.length;
  const title = {
    calling: t('intercomCallingName', {name}),
    ringing: t('intercomNameCalling', {name}),
    in_call: t('intercomInCallName', {name}),
    broadcasting: intercomAnnouncing(heard),
    listening: call.automated && call.message ? t('intercomHaMessage', {message: call.message}) : t('intercomNameAnnouncing', {name}),
  }[status.state];
  const card = document.createElement('div');
  card.className = 'card intercom-built';
  const tags = [];
  if (call.video?.camera || call.video?.farCamera) tags.push(tag(intercomText("Video")));
  let clock = null;
  if (call.since) {
    clock = tag(mmss(call.since), 'device');
    tags.push(clock);
  }
  const row = kioskRow({ name: title, address: peer.address, tags });
  row.appendChild(button(intercomText("End call"), 'btn-ghost', () => run('intercomHangup')));
  card.appendChild(row);
  if (clock) {
    tickTimer = setInterval(() => {
      if (!clock.isConnected) { clearInterval(tickTimer); tickTimer = null; return; }
      clock.textContent = mmss(call.since);
    }, 1000);
  }
  return card;
}

/* ---- the page ---- */

// The built cards go after the fleet banner when a leader pushes this
// category, so the banner keeps the top of the tab.
function putTop(tab, nodes) {
  const banners = tab.querySelectorAll(':scope > .fleet-banner');
  const after = banners.length ? banners[banners.length - 1] : null;
  if (after) after.after(...nodes); else tab.prepend(...nodes);
}

export async function renderIntercomPage({ fetch = true } = {}) {
  const tab = document.getElementById('tab-intercom');
  if (!tab) return;
  if (fetch || !status) await loadStatus();
  // The hand-built parts go and come back: the definition rows stay.
  if (tickTimer) { clearInterval(tickTimer); tickTimer = null; }
  tab.querySelectorAll('.intercom-built').forEach((n) => n.remove());
  if (!status) {
    const h = hintRow(intercomText("The device did not answer."));
    h.classList.add('intercom-built');
    tab.appendChild(h);
    return;
  }
  decorateRows(tab);

  const top = [];
  if (status.available === false) {
    const card = document.createElement('div');
    card.className = 'card intercom-built';
    const row = infoRow(intercomText("The intercom needs the remote admin"),
      intercomText("Kiosks find and reach each other through it. Turn on Remote management and Find other kiosks under Device, then come back."));
    row.appendChild(button(intercomText('Open'), 'btn-ghost', () => showTab('device')));
    card.appendChild(row);
    top.push(card);
  }
  if (LIVE.has(status.state)) top.push(liveCard());
  if (top.length) putTop(tab, top);

  // The roster is worth nothing with the intercom off.
  if (status.available !== false && status.enabled) {
    const [h, card] = titled(intercomText("Kiosks"));
    const kiosks = status.kiosks || [];
    if (!kiosks.length) {
      card.appendChild(infoRow(intercomText("No kiosks found"), intercomText("Kiosks appear through network discovery or saved fleet membership. Remote management and Find other kiosks must be on.")));
    }
    for (const k of kiosks) {
      const row = kioskRow({ name: k.name, address: k.address, version: k.version, dim: k.status === 'offline' });
      const st = document.createElement('span');
      st.className = 'fleet-status' + (k.status === 'ready' ? ' ok' : k.status === 'key' || k.status === 'tls' || k.status === 'unreachable' ? ' warn' : '');
      st.textContent = intercomText(k.statusText || '');
      row.appendChild(st);
      card.appendChild(row);
    }
    card.appendChild(hintRow(intercomText("Discovered kiosks and saved fleet members. A kiosk is ready when it is reachable with intercom on, the same key and matching encryption settings.")));
    if (status.video && !status.cameraReady) {
      const note = hintRow(intercomText("The camera is off. This kiosk can show video but not send it."));
      note.classList.add('intercom-built');
      tab.appendChild(note);
    }
    tab.append(h, card);
  }
}

/* ---- lifecycle ---- */

export function intercomShown() {
  renderIntercomPage();
}

document.addEventListener('ks-event', (e) => {
  if (e.detail?.event !== 'intercom') return;
  // The event carries the status itself: no second read.
  if (e.detail.data && typeof e.detail.data === 'object') status = e.detail.data;
  // Not under an open modal: a redraw would pull the rows from under it.
  if (document.querySelector('.modal-back')) return;
  renderIntercomPage({ fetch: false });
});

/* ---- text to speech engine rows ----
   A box with the picked entity's name that opens the list of every tts
   entity Home Assistant has, First available on top. Mirrors the device
   row. Announcements and Alarms each have one. A new engine clears the
   language and voice: another engine's are not these.

   Each picker row repaints itself from updateSetting, and the Language and
   Voice rows come and go under the engine in place (refreshTtsRows here,
   the text to speech clause in settings.js), so neither a pick nor the
   device's echo of it rebuilds the settings pages. */

const ttsValue = (key) => `${byKey(key)?.value || ''}`.trim();

// After a pick: the gated rows in or out, a picker on any row just
// revealed, and every row of the three showing what is saved now.
function refreshTtsRows(engineKey, languageKey, voiceKey) {
  const engineRow = document.querySelector(`[data-key="${engineKey}"]`);
  if (engineRow && !syncGatedRows(engineKey, engineRow)) {
    loadSettings();
    return;
  }
  attachTtsVoicePicker(languageKey, engineKey, languageKey, voiceKey);
  attachTtsVoicePicker(voiceKey, engineKey, languageKey, voiceKey);
  for (const k of [engineKey, languageKey, voiceKey]) {
    document.querySelector(`[data-key="${k}"]`)?.updateSetting?.();
  }
}

export function attachTtsPicker(key, languageKey, voiceKey) {
  const ttsRow = document.querySelector(`[data-key="${key}"]`);
  if (!ttsRow || !byKey(key) || ttsRow.querySelector('.tts-pick')) return;
  ttsRow.querySelector('input')?.remove();
  // The entity picker over Home Assistant's text to speech entities, the
  // device's row: Clear is First available.
  const spec = entitySpec({ domains: ['tts'] });
  const field = pickField({
    spec, value: ttsValue(key), placeholder: esphomeText('First available'),
    onClick: async () => {
      const current = ttsValue(key);
      const out = await pickItem({ title: esphomeText('Text to speech engine'), spec,
        selected: current || null, allowClear: true });
      if (!out) return;
      const picked = out.id ?? '';
      if (picked === current) return;
      const patch = { [key]: picked, [languageKey]: '', [voiceKey]: '' };
      const res = await api('/api/settings', { method: 'PATCH', body: JSON.stringify(patch) });
      if (!res.ok) { showToast({ title: esphomeText('Not saved'), kind: 'error' }); return; }
      for (const [k, v] of Object.entries(patch)) { const d = byKey(k); if (d) d.value = v; }
      refreshTtsRows(key, languageKey, voiceKey);
    },
  });
  field.el.classList.add('tts-pick');
  ttsRow.classList.add('dp-field-row');
  ttsRow.updateSetting = () => { field.setValue(ttsValue(key)); return true; };
  ttsRow.appendChild(field.el);
}

/* ---- text to speech language and voice rows ----
   Under an engine row: a box with the pick's name that opens what Home
   Assistant lists for the engine, Default on top. Voices come for the
   Language pick, or Home Assistant's own language when that is Default.
   Mirrors the device's TtsVoiceRow. */
function languageName(tag) {
  try {
    const name = new Intl.DisplayNames([messageLanguage()], { type: 'language', languageDisplay: 'standard' })
      .of(`${tag}`.replace(/_/g, '-'));
    return name ? name.charAt(0).toLocaleUpperCase(messageLanguage()) + name.slice(1) : tag;
  } catch (_) {
    return tag;
  }
}

export function attachTtsVoicePicker(key, engineKey, languageKey, voiceKey) {
  const row = document.querySelector(`[data-key="${key}"]`);
  if (!row || !byKey(key) || row.querySelector('.tts-pick')) return;
  const isLanguage = key === languageKey;
  const load = async (language) => {
    const r = await cmd('ttsVoices', { engine: ttsValue(engineKey), language: language ?? ttsValue(languageKey) });
    if (!r.ok || !r.data) throw new Error(r.error || 'unreachable');
    return { languages: r.data.languages || [], voices: r.data.voices || [] };
  };
  // The voices last listed for this row, so a repaint can name the pick.
  let voices = [];
  const known = (id) => voices.some((v) => v.voice_id === id);
  row.querySelector('input')?.remove();
  const box = document.createElement('button');
  box.type = 'button';
  box.className = 'btn-ghost tts-pick';
  const paint = () => {
    const id = ttsValue(key);
    if (!id) box.textContent = esphomeText('Default');
    else if (isLanguage) box.textContent = languageName(id);
    else box.textContent = voices.find((v) => v.voice_id === id)?.name || id;
  };
  // A voice's name once Home Assistant answers; its id until then.
  const name = () => {
    paint();
    if (isLanguage || !ttsValue(key) || known(ttsValue(key))) return;
    load().then((r) => { voices = r.voices; paint(); }).catch(() => {});
  };
  name();
  row.updateSetting = () => { name(); return true; };
  box.addEventListener('click', async () => {
    let listed;
    try {
      listed = await load();
    } catch (_) {
      showToast({ title: esphomeText('Could not reach Home Assistant'), kind: 'error' });
      return;
    }
    if (!isLanguage) voices = listed.voices;
    const choices = isLanguage
      ? listed.languages.map((l) => [l, languageName(l)])
        .sort((a, b) => a[1].localeCompare(b[1], messageLanguage()))
      : listed.voices.map((v) => [v.voice_id, v.name]);
    if (!choices.length) {
      showToast({ title: esphomeText('No voices to pick') });
      return;
    }
    const current = ttsValue(key);
    const picked = await new Promise((resolve) => {
      let language = messageLanguage();
      const shell = modalShell({ title: byKey(key)?.title || '', onDismiss: () => close(null) });
      const close = (v) => {
        document.removeEventListener('ks-settings-cached', onLanguage);
        shell.close();
        resolve(v);
      };
      const first = radioRow('', '', !current, () => close(''));
      shell.body.append(first);
      // The id under the name, the way the engine picker shows entity
      // ids: it is what the announce action takes.
      for (const [id, label] of choices) {
        shell.body.append(radioRow(label, id === label ? '' : id, id === current, () => close(id)));
      }
      const cancel = document.createElement('button');
      cancel.className = 'btn-text'; cancel.addEventListener('click', () => close(null));
      shell.foot.append(cancel);
      const labels = () => {
        shell.head.textContent = byKey(key)?.title || '';
        first.querySelector('.name').textContent = esphomeText('Default');
        cancel.textContent = esphomeText('Cancel');
      };
      const onLanguage = () => {
        if (language === messageLanguage()) return;
        language = messageLanguage(); labels();
      };
      document.addEventListener('ks-settings-cached', onLanguage); labels();
    });
    if (picked === null || picked === current) return;
    const patch = { [key]: picked };
    // A voice the new language lists too stays, Kokoro's and OpenAI's
    // case; a voice it does not is dropped for the engine's own.
    if (isLanguage && ttsValue(voiceKey)) {
      try {
        const next = await load(picked);
        if (!next.voices.some((v) => v.voice_id === ttsValue(voiceKey))) patch[voiceKey] = '';
      } catch (_) { /* kept: the fallback speaks without it */ }
    }
    const res = await api('/api/settings', { method: 'PATCH', body: JSON.stringify(patch) });
    if (!res.ok) { showToast({ title: esphomeText('Not saved'), kind: 'error' }); return; }
    for (const [k, v] of Object.entries(patch)) { const d = byKey(k); if (d) d.value = v; }
    refreshTtsRows(engineKey, languageKey, voiceKey);
  });
  row.appendChild(box);
}

/* The engine, language and voice rows of one feature. */
export function attachTtsPickers(prefix) {
  const [engine, language, voice] = ['engine', 'language', 'voice'].map((k) => `${prefix}.tts_${k}`);
  attachTtsPicker(engine, language, voice);
  attachTtsVoicePicker(language, engine, language, voice);
  attachTtsVoicePicker(voice, engine, language, voice);
}

// A change made elsewhere (the device, another admin) brings the Language
// and Voice rows back in place through settings.js as plain rows: they
// get their pickers here.
document.addEventListener('ks-settings', (e) => {
  const keys = Array.isArray(e.detail) ? e.detail : [];
  for (const prefix of ['announcements', 'alarms']) {
    if (keys.some((k) => k.startsWith(`${prefix}.tts_`))) attachTtsPickers(prefix);
  }
});

/* ---- the Announcements page under ESPHome ----
   Its text to speech engine, and the chime sound select riding the same
   helper as the notification sound. */
export function decorateAnnouncementsPage() {
  attachTtsPickers('announcements');

  const chimeRow = document.querySelector('[data-key="announcements.chime_file"]');
  const chimeDef = byKey('announcements.chime_file');
  if (chimeRow && chimeDef && !chimeRow.querySelector('select')) {
    attachSoundUpload(chimeRow, attachSoundSelect(chimeRow, chimeDef));
  }
}

watchUpdates(['intercom'], (results) => {
  if (!document.querySelector('.modal-back')) return renderIntercomPage({ fetch: !results });
}, { visible: () => currentPath.split('/')[0] === 'intercom' });
