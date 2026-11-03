import { isHeadless } from './headless.js';
import { t, voiceText, voiceVadOption } from './localization.js';
import { api, cmd, state } from './core.js';
import { pickRow, playerSpec } from './entity_picker.js';
import { readOnlyRow } from './device.js';
import { SUBPAGE_ICONS } from './icons.js';
import { banner, messageBox, modalShell, selectLoading, showToast } from './widgets.js';
import { vsSelectRow } from './vs.js';
import { watchUpdates } from './live.js';
import { toggleRow } from './audio.js';

/* ---- Native Voice Satellite (runs in the kiosk, not the dashboard) ---- */
// Mirrors the device's native page: the switch with the status and Home
// Assistant rows under it, the page entries in the device's order, Home
// Assistant's own selects on Assistant and Wake Word, the preview on
// Appearance and the way back while the integration is still installed.
// The migration notice and wizard live here too, for the dashboard runtime.

const ICONS = {
  warn: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>',
  ok: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="m8 12 3 3 5-6"/></svg>',
  error: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="10"/><path d="M12 7v6M12 16.5v.5"/></svg>',
  pending: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/></svg>',
};

const PIPELINE_ROWS = [
  ['pipeline', 'Assistant 1', 'Answers wake word 1.'],
  ['pipeline_2', 'Assistant 2', 'Answers wake word 2.'],
  ['vad_sensitivity', 'Finished speaking detection', 'How long a pause ends a voice command.'],
];
const WAKE_ROWS = [
  ['wake_word', 'Wake word 1', 'The word that starts a voice command.'],
  ['wake_word_2', 'Wake word 2', 'A second wake word, answered by Assistant 2.'],
];
const PAGES = ['Wake Word', 'Assistant', 'Realtime', 'Appearance', 'Conversation', 'Timers', 'Chimes'];


function voiceRow(name, desc, value = '') {
  return readOnlyRow(voiceText(name), voiceText(desc), value, false);
}

/* Home Assistant added the satellite but not its selects, and the kiosk's
   token could not reload the entry. */
const VS_RELOAD_HINT = 'Home Assistant has not loaded the Assistant and Wake word selects. '
  + "Reload this kiosk's ESPHome entry under Settings, Devices & services. "
  + 'Restarting Home Assistant also works.';

function statusWord(row, text, color) {
  const span = row.lastElementChild;
  span.textContent = text;
  span.style.cssText = `white-space:nowrap; font-weight:500; color:${color}`;
}

/* The status and Home Assistant rows under the switch, read from the
   kiosk's voiceStatus and repainted on every settings render. */
async function paintStatus(card, byKey) {
  // A later paint supersedes this one, whichever read comes back first.
  const gen = (card._vsStatusGen || 0) + 1;
  card._vsStatusGen = gen;
  const enabledRow = card.querySelector('[data-key="voice.enabled"]');
  if (!enabledRow || byKey['voice.enabled']?.value !== true) {
    card.querySelectorAll('.vs-native-status').forEach((r) => r.remove());
    return;
  }
  let status = {};
  try {
    const r = await cmd('voiceStatus', {});
    if (r.ok) status = r.data || {};
  } catch (_) {}
  if (!enabledRow.isConnected || card._vsStatusGen !== gen) return;
  card.querySelectorAll('.vs-native-status').forEach((r) => r.remove());
  const esphome = byKey['esphome.enabled']?.value === true;
  const muted = byKey['voice.mute']?.value === true;
  const entity = `${status.satelliteEntity || ''}`;
  const added = esphome && status.subscribed === true;
  const statusRow = voiceRow('Status',
    !esphome ? 'The ESPHome server is off.'
      : !added ? 'This kiosk is not added to Home Assistant yet.'
        : muted ? 'The microphone is muted.'
          : !status.busy && !status.listening ? 'The wake word is not listening.'
            : 'Listening for the wake word.');
  statusWord(statusRow,
    !added ? voiceText('Not added') : muted ? voiceText('Muted')
      : status.busy ? voiceText('Busy')
        : status.listening ? voiceText('Listening') : voiceText('Not listening'),
    !added || (!muted && !status.busy && !status.listening) ? 'var(--warn)'
      : muted ? 'var(--muted)' : 'var(--primary)');
  const reload = entity && status.selectsMissing === true;
  const haRow = voiceRow('Home Assistant', reload ? VS_RELOAD_HINT : entity ? '' : esphome
    ? 'Add this kiosk under Settings, Devices & services in Home Assistant, where it shows up as discovered. If Home Assistant had it before, it asks there for the new Encryption key from the ESPHome page.'
    : 'Turn on the ESPHome server so Home Assistant can add this kiosk as a satellite.');
  if (entity && !reload) haRow.querySelector('.desc').textContent = entity;
  if (esphome) {
    statusWord(haRow, !entity ? voiceText('Not added')
      : reload ? voiceText('Reload needed') : voiceText('Added'),
    entity && !reload ? 'var(--primary)' : 'var(--warn)');
  } else {
    haRow.lastElementChild.remove();
    const btn = document.createElement('button');
    btn.className = 'btn-primary';
    btn.textContent = voiceText('Turn on');
    btn.addEventListener('click', async () => {
      btn.disabled = true;
      await api('/api/settings', { method: 'PATCH', body: JSON.stringify({ 'esphome.enabled': true }) }).catch(() => null);
      btn.disabled = false;
    });
    haRow.appendChild(btn);
  }
  for (const row of [statusRow, haRow]) row.classList.add('vs-native-status');
  enabledRow.after(statusRow, haRow);
}

/* Play sounds on: this kiosk or a Home Assistant media player from the
   live list, in the place of the text field the definition draws, as the
   device's picker. Keeps the row's own (localized) title and its key. */
async function ttsOutputRow(row, current) {
  const title = row.querySelector('.name')?.textContent || 'Play sounds on';
  const desc = row.querySelector('.desc')?.textContent || '';
  // The entity picker over Home Assistant's media players, Music
  // Assistant's own entities kept: any of them plays sounds. The list's
  // ids carry their source; the setting keeps the entity. Clear is this
  // kiosk.
  const picker = pickRow({
    name: title, desc,
    spec: playerSpec('ha', { speakers: true }),
    value: current ? `ha:${current}` : '',
    placeholder: voiceText('This kiosk'),
    allowClear: true,
    flagMissing: false,
    onPick: (id) => {
      api('/api/settings', { method: 'PATCH',
        body: JSON.stringify({ 'voice.tts_output': `${id ?? ''}`.replace(/^ha:/, '') }) })
        .catch(() => null);
    },
  });
  picker.el.dataset.key = 'voice.tts_output';
  // An echo of the pick, or a change from the device, lands in place.
  picker.el.updateSetting = () => {
    const value = `${settingValue('voice.tts_output') ?? ''}`;
    picker.setValue(value ? `ha:${value}` : '');
    return true;
  };
  row.replaceWith(picker.el);
}

function settingValue(key) {
  return (state.settings || []).find((s) => s.key === key)?.value;
}

/* Skin or Assistant 2 skin (key): the current skin's name, opening a grid
   of every skin as a screenshot of its overlay, the device's picker. Keeps
   the row's own (localized) title and option labels and its key. */
function skinRow(row, key, current) {
  const title = row.querySelector('.name')?.textContent || voiceText('Skin');
  const desc = row.querySelector('.desc')?.textContent || '';
  // A plugin's skin reads as the plugin's name. One no longer installed
  // says so in the kiosk's language.
  const skinName = (id, label) => id.startsWith('plugin:') && label === 'Unavailable plugin skin'
    ? voiceText('Unavailable plugin skin') : label;
  let skins = [...(row.querySelector('select')?.options || [])]
    .map((o) => ({ id: o.value, name: skinName(o.value, o.textContent) }));
  if (!skins.length) return;
  const builtIn = skins.filter((k) => !k.id.startsWith('plugin:'));
  const nameOf = (id) => skins.find((k) => k.id === id)?.name || id;
  // Plugins come and go while the page is open: the list is read again
  // each time the picker opens. Built-in skins keep their localized names.
  const refresh = async () => {
    try {
      const data = await api('/api/settings').then((r) => r.json());
      const def = (data.settings || []).find((x) => x.key === key);
      if (!Array.isArray(def?.options)) return;
      skins = [...builtIn, ...def.options.filter((id) => `${id}`.startsWith('plugin:'))
        .map((id) => ({ id, name: skinName(id, `${def.optionLabels?.[id] || id}`) }))];
      current = `${def.value ?? current}`;
      picker.lastElementChild.textContent = nameOf(current);
    } catch (_) {}
  };
  const picker = readOnlyRow(title, desc, nameOf(current), false);
  picker.dataset.key = key;
  picker.style.cursor = 'pointer';
  picker.tabIndex = 0;
  const open = async () => {
    await refresh();
    const picked = await openSkinPicker(title, skins, current);
    if (!picked || picked === current) return;
    current = picked;
    picker.lastElementChild.textContent = nameOf(picked);
    api('/api/settings', { method: 'PATCH', body: JSON.stringify({ [key]: picked }) })
      .catch(() => null);
  };
  picker.addEventListener('click', open);
  picker.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); open(); }
  });
  picker.updateSetting = () => {
    current = `${settingValue(key) ?? current}`;
    picker.lastElementChild.textContent = nameOf(current);
    return true;
  };
  row.replaceWith(picker);
}

function openSkinPicker(title, skins, current) {
  return new Promise((resolve) => {
    const shell = modalShell({ title, width: 640, onDismiss: () => close(null) });
    const close = (id) => { shell.close(); resolve(id); };
    shell.foot.remove();
    const grid = document.createElement('div');
    grid.style.cssText = 'display:grid; grid-template-columns:repeat(auto-fill, minmax(170px, 1fr)); gap:14px; padding:4px 2px';
    for (const skin of skins) {
      const tile = document.createElement('button');
      tile.type = 'button';
      tile.style.cssText = 'display:flex; flex-direction:column; gap:6px; padding:0; border:0; background:none; color:inherit; text-align:start; cursor:pointer; font:inherit';
      const picked = skin.id === current;
      const frame = `display:block; width:100%; aspect-ratio:16/10; border-radius:12px; box-sizing:border-box; border:${picked ? '3px solid var(--primary)' : '1px solid var(--divider)'}`;
      let img;
      if (skin.id.startsWith('plugin:')) {
        // A plugin's skin: the picture it ships, or the plugin mark.
        img = document.createElement('div');
        img.innerHTML = SUBPAGE_ICONS.Plugins;
        img.style.cssText = `${frame}; display:flex; align-items:center; justify-content:center; background:var(--surface-2); color:var(--muted); overflow:hidden`;
        const glyph = img.firstElementChild;
        glyph.setAttribute('width', '40');
        glyph.setAttribute('height', '40');
        const box = img;
        cmd('getPluginVoiceSkinThumbnail', { id: skin.id.slice('plugin:'.length) }, { timeoutMs: 15000 })
          .then((r) => {
            if (!r?.ok || !r.data?.data) return;
            const picture = document.createElement('img');
            picture.src = `data:${r.data.mime};base64,${r.data.data}`;
            picture.alt = skin.name;
            picture.style.cssText = 'display:block; width:100%; height:100%; object-fit:cover';
            box.replaceChildren(picture);
          }).catch(() => null);
      } else {
        img = document.createElement('img');
        img.src = `voice_skins/${skin.id}.webp`;
        img.alt = skin.name;
        img.loading = 'lazy';
        img.style.cssText = `${frame}; object-fit:cover`;
      }
      const name = document.createElement('div');
      name.textContent = skin.name;
      name.style.cssText = 'font-weight:600; white-space:nowrap; overflow:hidden; text-overflow:ellipsis';
      tile.append(img, name);
      tile.addEventListener('click', () => close(skin.id));
      grid.appendChild(tile);
    }
    shell.body.appendChild(grid);
  });
}

/* Home Assistant's selects on the kiosk's device, as dropdowns that write
   them live. `rows` is [key, title, description] per row. The Assistant
   selects also offer the validated realtime provider. */
async function haSelectRows(container, rows) {
  container._vsRows = rows;
  let data = {};
  try {
    const r = await cmd('voiceHaSelects', {}, { timeoutMs: 15000 });
    if (r.ok) data = r.data || {};
  } catch (_) {}
  if (!container.isConnected) return;
  container.innerHTML = '';
  const label = (key, option) => option === 'preferred' ? voiceText('Preferred')
    : option === 'no_wake_word' ? voiceText('None')
      : key === 'vad_sensitivity' ? voiceVadOption(option) : option;
  const realtime = data.realtime || {};
  for (const [key, title, desc] of rows) {
    const entity = data[key];
    const options = Array.isArray(entity?.options) ? entity.options.map(String) : [];
    // Another engine's wake words, which Home Assistant learns as it
    // reconnects to the kiosk.
    if (entity && data.wakeWordsPending === true && (key === 'wake_word' || key === 'wake_word_2')) {
      const row = vsSelectRow(voiceText(title), voiceText(desc),
        options.map((o) => ({ value: o, label: label(key, o) })), null, () => {});
      selectLoading(row.querySelector('select'));
      container.appendChild(row);
      continue;
    }
    if (!entity || entity.available !== true || !options.length) {
      container.appendChild(voiceRow(title, desc,
        voiceText(data.selectsMissing === true ? 'Reload needed' : 'Not available')));
      continue;
    }
    // Every validated realtime provider is one more choice.
    const offers = key in realtime && Array.isArray(realtime.options) ? realtime.options : [];
    const choices = options.map((o) => ({ value: o, label: label(key, o) }));
    for (const o of offers) {
      choices.push({ value: `${o.value}`,
        label: t('voiceRealtimeOption', { provider: `${o.provider}` }, '{provider} Realtime') });
    }
    const picked = realtime[key];
    const current = typeof picked === 'string' && offers.some((o) => o.value === picked)
      ? picked : `${entity.state ?? ''}`;
    container.appendChild(vsSelectRow(voiceText(title), voiceText(desc), choices, current,
      async (option) => {
        const r = await cmd('voiceSelectOption', { key, option }).catch(() => null);
        if (!r?.ok) showToast({ title: 'Voice Satellite', message: voiceText('Could not change it in Home Assistant.'), kind: 'error' });
        setTimeout(() => haSelectRows(container, rows), 800);
      }));
  }
}

/* Settings the selects show without a row of their own: Home Assistant's
   mirrored selects and the realtime choice. An echo of one repaints the
   selects in place (settings.js skips its rebuild for them). */
export const VS_SELECT_SETTINGS = new Set([
  'voice.ha_pipeline', 'voice.ha_pipeline_2', 'voice.ha_vad_sensitivity',
  'voice.ha_wake_word', 'voice.ha_wake_word_2', 'voice.pending_selects',
  // The kiosk's copy of the wake words Home Assistant set: no row of its
  // own, and every pick in the Wake word selects saves it.
  'voice.wake_words',
  'voice.engine_1', 'voice.engine_2',
  'voice.realtime_openai_validated', 'voice.realtime_xai_validated',
  'voice.realtime_gemini_validated',
]);

/* Calls `paint` when one of `keys` changes, while `node` is on the page. */
function onSettings(node, keys, paint) {
  let timer = null;
  const listener = (e) => {
    if (!node.isConnected) { document.removeEventListener('ks-settings', listener); return; }
    if (!(e.detail || []).some((k) => keys.has(k))) return;
    clearTimeout(timer);
    timer = setTimeout(paint, 150);
  };
  document.addEventListener('ks-settings', listener);
}

function selectsBlock(rows) {
  const block = document.createElement('div');
  block.className = 'vs-ha-selects';
  haSelectRows(block, rows);
  onSettings(block, VS_SELECT_SETTINGS, () => haSelectRows(block, rows));
  // Home Assistant has new choices, a custom model added or deleted.
  watchUpdates(['voice-selects'], () => haSelectRows(block, rows), { owner: block });
  return block;
}

/* The realtime providers, and the settings each one's Configure dialog
   holds (the device's realtimeProviderSettings). Neither UI draws them as
   rows: the provider's row takes the first one's place. */
export const REALTIME_PROVIDERS = { openai: 'OpenAI', xai: 'xAI Grok', gemini: 'Google Gemini' };
const PROVIDER_FIELDS = ['api_key', 'model', 'voice', 'endpoint'];
// OpenAI's and Gemini's Reasoning effort, which xAI has no say in.
const providerFields = (provider) => provider === 'xai'
  ? PROVIDER_FIELDS : [...PROVIDER_FIELDS, 'reasoning'];
// The switches after them (the device's realtimeProviderSwitches).
const PROVIDER_SWITCHES = { xai: ['search', 'x_search'], gemini: ['search', 'proactive'] };
export const providerKeys = (provider) => [...providerFields(provider), ...(PROVIDER_SWITCHES[provider] || [])]
  .map((name) => `voice.realtime_${provider}_${name}`);

/* The provider settings a device echo repaints in place: their rows are
   the provider rows, never the generic ones (settings.js skips its
   rebuild for them). */
export const REALTIME_PROVIDER_SETTINGS = new Set(
  Object.keys(REALTIME_PROVIDERS).flatMap(providerKeys));

/* A provider's row, as its status reads it now. */
function realtimeStatusText(data) {
  switch (data?.status) {
    case 'unconfigured': return voiceText('Not configured');
    case 'validated': return voiceText('Connection validated');
    case 'failed': return data.toolsError
      ? t('voiceRealtimeToolsUnavailable', { problem: voiceText(`${data.error || ''}`) },
        'Connected, but the Home Assistant tools are unavailable: {problem}')
      : t('voiceRealtimeConnectFailed', { error: `${data.error || ''}` }, 'Could not connect: {error}');
    default: return voiceText('Not validated');
  }
}

/* A labeled control in the dialog, with its hint under it. */
function dialogField(setting, control) {
  const wrap = document.createElement('label');
  wrap.className = 'form-field';
  const title = document.createElement('span');
  title.className = 'desc';
  title.textContent = setting?.title || '';
  control.classList.add('field');
  control.style.maxWidth = 'none';
  wrap.append(title, control);
  if (setting?.description) {
    const hint = document.createElement('span');
    hint.className = 'desc';
    hint.style.fontSize = '12.5px';
    hint.textContent = setting.description;
    wrap.append(hint);
  }
  return wrap;
}

/* A provider's settings in a dialog, the device's showRealtimeProviderDialog.
   Save & Validate connects with them first: a connection the provider
   takes saves them and closes, a refused one shows why and leaves the
   dialog and the stored settings as they were. The key is write-only, so
   an empty field keeps the saved one. Clear puts the provider back to Not
   configured. */
function openRealtimeProvider(provider, onSaved) {
  const setting = (name) => (state.settings || [])
    .find((s) => s.key === `voice.realtime_${provider}_${name}`);
  const [keyDef, modelDef, voiceDef, endpointDef, reasoningDef] = providerFields(provider).map(setting);
  let saving = false;
  const shell = modalShell({ title: REALTIME_PROVIDERS[provider], width: 480,
    onDismiss: () => { if (!saving) shell.close(); } });
  const form = document.createElement('form');
  form.className = 'modal-form';
  const key = document.createElement('input');
  key.type = 'password';
  key.autocomplete = 'new-password';
  key.spellcheck = false;
  if (keyDef?.value === '__set__') key.placeholder = '••••••••';
  const picker = (def) => {
    const select = document.createElement('select');
    const options = [...(def?.options || [''])];
    if (!options.includes(def?.value ?? '')) options.push(def?.value ?? '');
    for (const value of options) {
      const option = document.createElement('option');
      option.value = value;
      option.textContent = def?.optionLabels?.[value] ?? value;
      option.selected = value === (def?.value ?? '');
      select.appendChild(option);
    }
    return select;
  };
  const model = picker(modelDef);
  const voice = picker(voiceDef);
  const reasoning = reasoningDef ? picker(reasoningDef) : null;
  const endpoint = document.createElement('input');
  endpoint.type = 'url';
  endpoint.spellcheck = false;
  endpoint.value = `${endpointDef?.value || ''}`;
  endpoint.placeholder = endpointDef?.placeholder || '';
  const switches = (PROVIDER_SWITCHES[provider] || []).map((name) => {
    const def = setting(name);
    const row = toggleRow(def?.title || name, def?.description || '', def?.value === true, () => {});
    return { name, row, input: row.querySelector('input') };
  });
  const issue = document.createElement('div');
  issue.setAttribute('role', 'alert');
  form.append(dialogField(keyDef, key), dialogField(modelDef, model), dialogField(voiceDef, voice),
    ...(reasoning ? [dialogField(reasoningDef, reasoning)] : []), ...switches.map((s) => s.row),
    dialogField(endpointDef, endpoint), issue);
  shell.body.append(form);
  const cancel = document.createElement('button');
  cancel.type = 'button';
  cancel.className = 'btn-text';
  cancel.textContent = voiceText('Cancel');
  cancel.addEventListener('click', () => shell.close());
  const save = document.createElement('button');
  save.type = 'button';
  save.className = 'btn-primary';
  save.textContent = voiceText('Save & Validate');
  save.addEventListener('click', () => form.requestSubmit());
  // Clear shows once there is something to clear.
  const configured = keyDef?.value === '__set__' || `${endpointDef?.value || ''}`.trim() !== '';
  const clear = document.createElement('button');
  clear.type = 'button';
  clear.className = 'btn-text danger';
  clear.textContent = voiceText('Clear');
  clear.addEventListener('click', async () => {
    if (saving) return;
    saving = true;
    controls.forEach((c) => { c.disabled = true; });
    const r = await cmd('voiceRealtimeClear', { provider }).catch((e) => ({ ok: false, error: e?.message }));
    saving = false;
    controls.forEach((c) => { c.disabled = false; });
    if (r?.ok) {
      shell.close();
      onSaved();
      return;
    }
    issue.replaceChildren(banner(`${r?.error || ''}`, { error: true }));
  });
  shell.foot.append(...(configured ? [clear] : []), cancel, save);
  const controls = [clear, cancel, save, key, model, voice, endpoint, ...(reasoning ? [reasoning] : []),
    ...switches.map((s) => s.input)];
  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    if (saving) return;
    saving = true;
    controls.forEach((c) => { c.disabled = true; });
    save.textContent = voiceText('Checking…');
    issue.replaceChildren();
    const params = { provider, endpoint: endpoint.value, model: model.value, voice: voice.value };
    if (reasoning) params.reasoning = reasoning.value;
    for (const s of switches) params[s.name] = s.input.checked;
    if (key.value || keyDef?.value !== '__set__') params.apiKey = key.value;
    const r = await cmd('voiceRealtimeSave', params, { timeoutMs: 40000 }).catch((e) => ({ ok: false, error: e?.message }));
    saving = false;
    controls.forEach((c) => { c.disabled = false; });
    save.textContent = voiceText('Save & Validate');
    const data = r?.data || {};
    if (r?.ok && data.connected === true) {
      shell.close();
      onSaved();
      return;
    }
    issue.replaceChildren(banner(t('voiceRealtimeConnectFailed', { error: `${data.error || r?.error || ''}` },
      'Could not connect: {error}'), { error: true }));
  });
  (keyDef?.value === '__set__' ? model : key).focus();
}

/* A provider's row in the Realtime page's Providers group, where its first
   setting's row sat: its status under its name and Configure. The rest of
   its setting rows go. */
function realtimeProviderRow(panel, provider) {
  const [first, ...rest] = providerKeys(provider);
  const anchor = panel.querySelector(`[data-key="${first}"]`);
  if (!anchor || anchor.classList.contains('realtime-provider-row')) return;
  for (const key of rest) panel.querySelector(`[data-key="${key}"]`)?.remove();
  const row = readOnlyRow(REALTIME_PROVIDERS[provider], voiceText('Not validated'), '');
  row.classList.add('realtime-provider-row');
  row.dataset.provider = provider;
  // Where a search for any of its settings lands (search.js).
  row.dataset.key = first;
  row.lastElementChild.remove();
  const desc = row.querySelector('.desc');
  const paint = async () => {
    const r = await cmd('voiceRealtimeState', { provider }).catch(() => null);
    if (row.isConnected && r?.ok) desc.textContent = realtimeStatusText(r.data);
  };
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = voiceText('Configure');
  btn.style.cssText = 'flex-shrink:0;';
  btn.addEventListener('click', () => openRealtimeProvider(provider, paint));
  row.appendChild(btn);
  anchor.replaceWith(row);
  paint();
  onSettings(row, new Set([...providerKeys(provider), `voice.realtime_${provider}_validated`]), paint);
}

/* The native page, into a root render() already filled with the Voice
   Satellite settings: the generic rows stay, this adds and reorders. */
export async function renderNativeVs(root, byKey) {
  const enabled = byKey['voice.enabled']?.value === true;
  // The switch card: Enable, then the status rows, then Mute and background
  // listening, the device's order.
  const enabledRow = root.querySelector(':scope > .card [data-key="voice.enabled"]');
  const card = enabledRow?.closest('.card');
  if (card) {
    for (const key of ['voice.mute', 'wake_word.background', 'wake_word.return_to_background']) {
      // render() can leave them in a card of their own: a page entry
      // between them and the switch closes the card they started in.
      const row = root.querySelector(`:scope > .card [data-key="${key}"]`);
      if (!row) continue;
      const from = row.closest('.card');
      if (!enabled) row.remove();
      else card.appendChild(row);
      if (from !== card && !from.children.length) from.remove();
    }
    card.prepend(enabledRow);
    card.id = 'vsNativeCard';
    // The status follows the kiosk: Home Assistant taking the satellite a
    // few seconds after the switch turns on changes no setting, so it
    // arrives as a voice-status update rather than a settings render.
    card._vsByKey = byKey;
    if (card._vsStatusWatch) paintStatus(card, byKey);
    else {
      card._vsStatusWatch = watchUpdates(['voice-status'],
        () => paintStatus(card, card._vsByKey), { owner: card });
    }
  }
  const entryCard = (sub) => root.querySelector(`[data-subpage-entry="${sub}"]`)?.closest('.card');
  if (!enabled) {
    // Off: only the switch, as on the device.
    root.querySelectorAll('[data-subpage-entry]').forEach((row) => row.closest('.card')?.remove());
  } else {
    for (const sub of [...PAGES, 'Wake word diagnostics']) {
      const entry = entryCard(sub);
      if (entry) root.appendChild(entry);
    }
    const tab = root.closest('.tab') || root;
    const panel = (sub) => tab.querySelector(`.subpage[data-subpage="${sub}"]`);
    const assistant = panel('Assistant');
    if (assistant) {
      const h = document.createElement('h2');
      h.className = 'card-title';
      h.textContent = voiceText('Pipelines');
      const selects = document.createElement('div');
      selects.className = 'card';
      selects.appendChild(selectsBlock(PIPELINE_ROWS));
      assistant.prepend(h, selects);
    }
    const realtimePanel = panel('Realtime');
    if (realtimePanel) {
      for (const provider of Object.keys(REALTIME_PROVIDERS)) realtimeProviderRow(realtimePanel, provider);
    }
    const ttsRow = assistant?.querySelector('[data-key="voice.tts_output"]');
    if (ttsRow) ttsOutputRow(ttsRow, byKey['voice.tts_output']?.value || '');
    const wake = panel('Wake Word');
    if (wake) {
      // Engine, the language of Amazon's engine, Home Assistant's wake
      // words (which follow both), then sensitivity and its fine-tune, the
      // noise gate and the stop word with its fine-tune in one card, the
      // engine's own tuning after.
      const first = document.createElement('div');
      first.className = 'card';
      for (const key of ['voice.wake_word_engine', 'voice.amazon_locale', 'voice.wake_word_sensitivity', 'voice.wake_word_fine_tune', 'voice.noise_gate', 'voice.stop_word', 'voice.stop_word_fine_tune']) {
        const row = wake.querySelector(`[data-key="${key}"]`);
        if (row) first.appendChild(row);
        if (key === 'voice.amazon_locale') first.appendChild(selectsBlock(WAKE_ROWS));
      }
      wake.querySelectorAll(':scope > .card').forEach((c) => { if (!c.children.length) c.remove(); });
      wake.prepend(first);
      if (!wake.querySelector('#vsCustomModels')) wake.append(...customModelsGroup());
    }
    for (const key of ['voice.skin', 'voice.skin_2']) {
      const skin = panel('Appearance')?.querySelector(`[data-key="${key}"]`);
      if (skin) skinRow(skin, key, byKey[key]?.value || '');
    }
    const reactive = panel('Appearance')?.querySelector('[data-key="voice.reactive_bar"]');
    if (reactive) {
      const row = voiceRow('Preview', 'Show the overlay on the kiosk screen for five seconds.');
      row.lastElementChild.remove();
      const btn = document.createElement('button');
      btn.className = 'btn-ghost';
      btn.textContent = voiceText('Preview');
      btn.addEventListener('click', () => cmd('voicePreview', {}).catch(() => null));
      row.appendChild(btn);
      reactive.after(row);
    }
  }
  // The way back, while the integration is still installed.
  let installed = false;
  try {
    const r = await cmd('haDetectVoiceSatellite', {});
    installed = r.ok && r.data === true;
  } catch (_) {}
  // The dashboard runtime runs in the WebView, which a device without a
  // screen does not have.
  if (!installed || isHeadless() || !root.isConnected || root.querySelector('#vsRollbackCard')) return;
  const back = document.createElement('div');
  back.className = 'card';
  back.id = 'vsRollbackCard';
  const row = voiceRow('Run from the dashboard again',
    'Go back to the Voice Satellite integration. Nothing set here is lost.');
  row.lastElementChild.remove();
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = voiceText('Switch back');
  btn.addEventListener('click', async () => {
    const pick = await messageBox({
      title: voiceText('Run from the dashboard again?'),
      message: voiceText('The dashboard runs Voice Satellite again through the integration, with the settings it had before. What you set here stays for next time.'),
      buttons: ['Cancel', 'Switch back'],
      buttonText: voiceText,
    });
    if (pick !== 'Switch back') return;
    btn.disabled = true;
    const r = await cmd('vsRollback', {}, { timeoutMs: 60000 }).catch(() => null);
    btn.disabled = false;
    if (!r?.ok) showToast({ title: 'Voice Satellite', message: r?.error || voiceText('Could not switch'), kind: 'error' });
  });
  row.appendChild(btn);
  back.appendChild(row);
  const perms = root.querySelector('#permsCard');
  if (perms) perms.before(back); else root.appendChild(back);
}

/* ---- Custom Models ----
   The wake word models added to the kiosk, as on the device: the list with
   a delete button each, Add models (the files go up one by one, then the
   kiosk checks them together) and the documentation. A fleet follower
   whose leader syncs Voice Satellite shows the list only. */
const CUSTOM_DOCS = 'https://github.com/jxlarrea/kiosk-satellite/blob/main/docs/custom-wake-words.md';
const ENGINE_LABELS = { microwakeword: 'microWakeWord', openwakeword: 'openWakeWord', vswakeword: 'vsWakeWord' };

function customModelsGroup() {
  const h = document.createElement('h2');
  h.className = 'card-title';
  h.textContent = voiceText('Custom Models');
  const card = document.createElement('div');
  card.className = 'card';
  card.id = 'vsCustomModels';
  card.dataset.searchId = 'x:vs_custom_models';
  const list = document.createElement('div');
  const input = document.createElement('input');
  input.type = 'file';
  input.multiple = true;
  input.accept = '.json,.tflite,.onnx';
  input.hidden = true;
  const add = voiceRow('Add models',
    'Pick the files of one or more models. They show up in Wake word 1 and 2 above.');
  add.lastElementChild.remove();
  // A plus, as the plugins page adds a plugin.
  const PLUS = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>';
  const addBtn = document.createElement('button');
  addBtn.type = 'button';
  addBtn.className = 'icon-btn';
  addBtn.title = voiceText('Add');
  addBtn.setAttribute('aria-label', voiceText('Add'));
  addBtn.innerHTML = PLUS;
  addBtn.addEventListener('click', () => input.click());
  add.append(addBtn, input);
  const managed = readOnlyRow('', voiceText('The fleet leader manages the custom models on this kiosk.'), '', false);
  const docs = document.createElement('a');
  docs.className = 'row';
  docs.style.cssText = 'color:inherit; text-decoration:none';
  docs.href = CUSTOM_DOCS;
  docs.target = '_blank';
  docs.rel = 'noopener noreferrer';
  const docsRow = voiceRow('How to add custom models',
    'The files each engine needs and where the models come from.');
  docsRow.lastElementChild.remove();
  docs.append(...docsRow.childNodes);
  const icon = document.createElement('span');
  icon.className = 'icon-btn';
  icon.setAttribute('aria-hidden', 'true');
  icon.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 3h6v6M21 3 10 14M10 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-5"/></svg>';
  docs.appendChild(icon);
  card.appendChild(list);
  // Adding, and the documentation, each in a card of its own under the list.
  const addCard = document.createElement('div');
  addCard.className = 'card';
  addCard.appendChild(add);
  const docsCard = document.createElement('div');
  docsCard.className = 'card';
  docsCard.appendChild(docs);

  let busy = false;
  const refresh = async () => {
    let data = {};
    try {
      const r = await cmd('customWakeModels', {});
      if (r.ok) data = r.data || {};
    } catch (_) {}
    if (!card.isConnected) return;
    const models = Array.isArray(data.models) ? data.models : [];
    // One row or the other: a hidden row would still take the separator.
    addCard.replaceChildren(data.managed === true ? managed : add);
    list.replaceChildren();
    if (!models.length) {
      list.appendChild(readOnlyRow('', voiceText('No custom models yet.'), '', false));
    }
    for (const m of models) {
      const label = ENGINE_LABELS[m.engine] || m.engine;
      const files = (m.files || []).map((f) => f.name).join(', ');
      const desc = m.engine === data.engine ? `${label}. ${files}`
        : `${label}, ${voiceText('not the engine in use')}. ${files}`;
      const row = readOnlyRow(`${m.wakeWord}`, desc, '', false);
      row.lastElementChild.remove();
      if (data.managed !== true) {
        // A trash can, as the plugins list removes a plugin.
        const del = document.createElement('button');
        del.type = 'button';
        del.className = 'icon-btn';
        del.title = voiceText('Delete');
        del.setAttribute('aria-label', voiceText('Delete'));
        del.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M9 6V4h6v2M5 6l1 14h12l1-14M10 10v6M14 10v6"/></svg>';
        del.addEventListener('click', async () => {
          const pick = await messageBox({
            title: voiceText('Delete this model?'),
            message: `${m.wakeWord}`,
            buttons: ['Cancel', 'Delete'],
            buttonText: voiceText,
          });
          if (pick !== 'Delete') return;
          const r = await cmd('deleteCustomWakeModel', { engine: m.engine, id: m.id }).catch(() => null);
          if (!r?.ok) showToast({ title: voiceText('The model was not deleted.'), message: voiceText(r?.error || ''), kind: 'error' });
          refresh();
        });
        row.appendChild(del);
      }
      list.appendChild(row);
    }
  };

  input.addEventListener('change', async () => {
    const files = [...input.files];
    input.value = '';
    if (!files.length || busy) return;
    busy = true;
    addBtn.disabled = true;
    try {
      // A file refused on the way in is left out; the rest still go up.
      const refused = [];
      for (const [i, file] of files.entries()) {
        addBtn.textContent = `${i + 1}/${files.length}`;
        const res = await api(`/api/voice/wake-models/upload?name=${encodeURIComponent(file.name)}`,
          { method: 'POST', body: file });
        const body = await res.json().catch(() => ({}));
        if (!res.ok || body.ok === false) {
          await cmd('commitCustomWakeModels', {}).catch(() => null);
          throw new Error(`${file.name}: ${voiceText(`${body.error || res.status}`)}`);
        }
        if (body.data?.rejected) refused.push(body.data.rejected);
      }
      const r = await cmd('commitCustomWakeModels', {}, { timeoutMs: 120000 });
      const rejected = [...refused, ...(r.data?.rejected || [])];
      const added = r.data?.added || [];
      if (!r.ok) throw new Error(r.error || '');
      if (rejected.length) {
        showToast({
          title: added.length ? voiceText('Some files were not added.') : voiceText('The models were not added.'),
          // The store sends each reason's message code and values; the
          // English stays for what has none.
          message: [...new Set(rejected.map((f) =>
            `${f.file}: ${f.code ? t(f.code, f.values || {}, f.reason) : f.reason}`))].join('\n'),
          kind: 'error',
          // Long enough to read each file's reason, then it goes.
          duration: 8000,
        });
      } else {
        showToast({ title: voiceText('Models added.'), kind: 'success' });
      }
    } catch (e) {
      showToast({ title: voiceText('The models were not added.'), message: `${e.message || e}`, kind: 'error', duration: 8000 });
    } finally {
      busy = false;
      addBtn.disabled = false;
      addBtn.innerHTML = PLUS;
      refresh();
    }
  });
  watchUpdates(['wake-models'], refresh, { owner: card });
  refresh();
  return [h, card, addCard, docsCard];
}

/* The notice at the top of the page while the dashboard still runs the
   integration's engine. */
export function vsMigrationNotice() {
  const banner = document.createElement('div');
  banner.className = 'banner warn vs-migrate-notice';
  banner.style.alignItems = 'center';
  banner.innerHTML = ICONS.warn;
  const text = document.createElement('div');
  text.style.flex = '1';
  text.textContent = voiceText('Voice Satellite is currently installed as an integration in Home Assistant. Migrate to a native experience inside Kiosk Satellite.');
  const btn = document.createElement('button');
  btn.className = 'btn-primary';
  btn.style.cssText = 'background:var(--on-tertiary-container); color:var(--tertiary-container)';
  btn.textContent = voiceText('Migrate');
  btn.addEventListener('click', () => openVsMigrationWizard());
  banner.append(text, btn);
  return banner;
}

/* ---- the migration wizard, the device's four steps ---- */

const GROUP_TITLES = {
  voice: 'Voice', appearance: 'Appearance', conversation: 'Conversation',
  assistant: 'Assistant', timers: 'Timers',
};
const STEP_TITLES = {
  save: 'Save the settings',
  stop: 'Stop the dashboard engine',
  start: 'Start listening here',
  entities: 'Set the kiosk\'s entities in Home Assistant',
  check: 'Check the satellite in Home Assistant',
};
const CHECKS = {
  homeAssistant: ['Home Assistant', 'Connected.', () => 'Not connected. Check Home Assistant Setup.'],
  esphome: ['This kiosk in Home Assistant', 'Added through ESPHome.', (c) => c.esphomeOn
    ? 'Not added yet. Home Assistant lists this kiosk as discovered under Settings, Devices & services. Add it there, then come back.'
    : 'The ESPHome server is off. Turn it on, then add this kiosk in Home Assistant.'],
  admin: ['Administrator token', 'Tool use and results will show.',
    (c) => c.unknown
      ? 'Could not check the token. Tool use and results need an administrator\'s.'
      : 'The token is a regular user\'s. Voice Satellite works, tool use and results will not show.'],
  microphone: ['Microphone', 'Allowed.', () => 'Not allowed. Grant it under Required system permissions.'],
};

function spinner() {
  const s = document.createElement('div');
  s.className = 'fleet-spinner';
  s.style.cssText = 'width:28px; height:28px; margin:24px auto';
  return s;
}

function para(text, style = '') {
  const p = document.createElement('p');
  p.style.cssText = `margin:0 0 10px; line-height:1.5; ${style}`;
  p.textContent = text;
  return p;
}

function iconLine(icon, color, title, desc, extra = null) {
  const line = document.createElement('div');
  line.style.cssText = 'display:flex; gap:14px; align-items:flex-start; padding:8px 0';
  const i = document.createElement('span');
  i.style.cssText = `width:22px; height:22px; flex:none; color:${color}`;
  i.innerHTML = ICONS[icon];
  i.firstElementChild.style.cssText = 'width:22px; height:22px';
  const info = document.createElement('div');
  info.style.cssText = 'flex:1; min-width:0';
  const n = document.createElement('div');
  n.style.cssText = 'font-weight:500';
  n.textContent = title;
  info.appendChild(n);
  if (desc) {
    const d = document.createElement('div');
    d.style.cssText = `font-size:13px; margin-top:2px; color:${icon === 'ok' ? 'var(--muted)' : color}`;
    d.textContent = desc;
    info.appendChild(d);
  }
  line.append(i, info);
  if (extra) line.appendChild(extra);
  return line;
}

/* The migration, as the device's wizard. Resolves true once the kiosk
   migrated. With onboarding (offered at setup) Home Assistant was just
   checked and cannot have added the kiosk yet: no check step, and the old
   satellite's selects are set once it does. */
export function openVsMigrationWizard({ onboarding = false } = {}) {
  return new Promise((resolve) => {
  const shell = modalShell({ title: '', width: 560 });
  const pages = onboarding
    ? ['pick', 'plan', 'automations', 'ready']
    : ['pick', 'check', 'plan', 'automations', 'ready'];
  const w = {
    step: 0, satellites: null, satellite: '', check: null, plan: null, automations: null,
    groups: new Set(Object.keys(GROUP_TITLES)), result: null, steps: [],
  };
  const finish = (migrated) => { shell.close(); resolve(migrated); };
  const button = (label, kind, onClick, disabled = false) => {
    const b = document.createElement('button');
    b.className = kind;
    b.textContent = voiceText(label);
    b.disabled = disabled;
    b.addEventListener('click', onClick);
    shell.foot.appendChild(b);
    return b;
  };
  const stepper = (page) => {
    const n = pages.indexOf(page) + 1;
    const bar = document.createElement('div');
    bar.style.cssText = 'display:flex; gap:8px; align-items:center; margin-bottom:14px';
    for (let i = 0; i < pages.length; i++) {
      const seg = document.createElement('div');
      seg.style.cssText = `flex:1; height:4px; border-radius:2px; background:${i < n ? 'var(--primary)' : 'var(--surface-2)'}`;
      bar.appendChild(seg);
    }
    const label = document.createElement('span');
    label.style.cssText = 'font-size:12.5px; color:var(--muted); white-space:nowrap';
    label.textContent = t('voiceMigrationStep', { n: String(n), total: String(pages.length) }, 'Step {n} of {total}');
    bar.appendChild(label);
    return bar;
  };
  const load = async (command, key, fallback, params = {}) => {
    const r = await cmd(command, params, { timeoutMs: 30000 }).catch(() => null);
    w[key] = r?.ok && r.data ? r.data : fallback;
    paint();
  };
  const runCheck = () => { w.check = null; paint(); load('voiceMigrationCheck', 'check', { checks: [], ready: false }); };
  const go = (page) => {
    w.step = pages.indexOf(page);
    paint();
    if (page === 'check') runCheck();
    if (page === 'plan' && !w.plan) load('voiceMigrationPlan', 'plan', { groups: [] }, { satellite: w.satellite });
    if (page === 'automations' && !w.automations) {
      load('voiceMigrationAutomations', 'automations', { items: [] }, { satellite: w.satellite });
    }
  };

  const paint = () => {
    const { head, body } = shell;
    body.innerHTML = '';
    shell.foot.innerHTML = '';
    const page = w.step < pages.length ? pages[w.step] : 'switch';
    if (page === 'pick') {
      head.textContent = voiceText('Migrate Voice Satellite');
      body.append(stepper('pick'), para(voiceText('Pick the Voice Satellite integration\'s satellite this kiosk takes over. Its settings come over to this kiosk.')));
      if (!w.satellites) body.appendChild(spinner());
      else if (!w.satellites.length) body.appendChild(para(voiceText('The Voice Satellite integration has no satellites.')));
      for (const sat of w.satellites || []) {
        const label = document.createElement('label');
        label.style.cssText = 'display:flex; gap:12px; align-items:flex-start; padding:8px 0; cursor:pointer';
        const radio = document.createElement('input');
        radio.type = 'radio';
        radio.name = 'vs-migrate-satellite';
        radio.checked = w.satellite === sat.entity_id;
        radio.style.marginTop = '3px';
        radio.addEventListener('change', () => {
          w.satellite = sat.entity_id;
          w.plan = null;
          w.automations = null;
          paint();
        });
        const info = document.createElement('div');
        const n = document.createElement('div');
        n.style.fontWeight = '500';
        n.textContent = sat.name || sat.entity_id;
        const d = document.createElement('div');
        d.style.cssText = 'font-size:13px; color:var(--muted); margin-top:2px';
        d.textContent = sat.entity_id;
        info.append(n, d);
        label.append(radio, info);
        body.appendChild(label);
      }
      button('Cancel', 'btn-text', () => finish(false));
      button('Next', 'btn-primary', () => go(onboarding ? 'plan' : 'check'), !w.satellite);
    } else if (page === 'check') {
      head.textContent = voiceText('Migrate Voice Satellite');
      body.append(stepper('check'), para(voiceText('This kiosk becomes the voice satellite itself. The Voice Satellite integration is not needed after this.')));
      if (!w.check) body.appendChild(spinner());
      for (const c of w.check?.checks || []) {
        const [title, good, bad] = CHECKS[c.id] || [c.id, '', () => ''];
        const color = c.ok ? 'var(--primary)' : c.warnOnly ? 'var(--warn)' : 'var(--error)';
        let extra = null;
        if (c.id === 'esphome' && !c.esphomeOn) {
          extra = document.createElement('button');
          extra.className = 'btn-text';
          extra.textContent = voiceText('Turn on ESPHome');
          extra.addEventListener('click', async () => {
            extra.disabled = true;
            await api('/api/settings', { method: 'PATCH', body: JSON.stringify({ 'esphome.enabled': true }) }).catch(() => null);
            runCheck();
          });
        }
        body.appendChild(iconLine(c.ok ? 'ok' : c.warnOnly ? 'warn' : 'error', color,
          voiceText(title), voiceText(c.ok ? good : bad(c)), extra));
      }
      button('Back', 'btn-text', () => go('pick'));
      if (w.check && w.check.ready !== true) button('Check again', 'btn-text', runCheck);
      button('Next', 'btn-primary', () => go('plan'), w.check?.ready !== true);
    } else if (page === 'plan') {
      head.textContent = voiceText('Settings to bring over');
      body.appendChild(stepper('plan'));
      if (!w.plan) body.appendChild(spinner());
      else {
        for (const g of w.plan.groups || []) {
          const label = document.createElement('label');
          label.style.cssText = 'display:flex; gap:12px; align-items:flex-start; padding:8px 0; cursor:pointer';
          const box = document.createElement('input');
          box.type = 'checkbox';
          box.checked = w.groups.has(g.id);
          box.style.marginTop = '3px';
          box.addEventListener('change', () => {
            if (box.checked) w.groups.add(g.id); else w.groups.delete(g.id);
          });
          const info = document.createElement('div');
          const n = document.createElement('div');
          n.style.fontWeight = '500';
          n.textContent = voiceText(GROUP_TITLES[g.id] || g.id);
          info.appendChild(n);
          if (g.values) {
            const d = document.createElement('div');
            d.style.cssText = 'font-size:13px; color:var(--muted); margin-top:2px';
            d.textContent = g.values;
            info.appendChild(d);
          }
          label.append(box, info);
          body.appendChild(label);
        }
        const note = para(voiceText('Not carried over: custom CSS, the browser microphone processing and the conversation memory length. Custom microWakeWord models work from config/custom_wake_words in Home Assistant.'),
          'margin-top:8px; padding:14px; border-radius:16px; background:var(--surface-2); font-size:13px');
        body.appendChild(note);
      }
      button('Back', 'btn-text', () => go(onboarding ? 'pick' : 'check'));
      button('Next', 'btn-primary', () => go('automations'), !w.plan);
    } else if (page === 'automations') {
      head.textContent = voiceText('Automations and scripts');
      body.appendChild(stepper('automations'));
      const items = w.automations?.items;
      if (!items) body.appendChild(spinner());
      else if (!items.length) {
        body.appendChild(iconLine('ok', 'var(--primary)', voiceText('Nothing in Home Assistant points at the old satellite.'), ''));
      } else {
        body.appendChild(para(t('voiceMigrationStillPoint', { satellite: w.satellite },
          'These still point at {satellite}. Edit them in Home Assistant to use this kiosk\'s satellite. The wizard does not change them.')));
        for (const item of items) {
          const line = document.createElement('div');
          line.style.cssText = 'padding:8px 0; border-top:1px solid var(--divider)';
          const n = document.createElement('div');
          n.style.fontWeight = '500';
          n.textContent = item.name || '';
          const d = document.createElement('div');
          d.style.cssText = 'font-size:13px; color:var(--muted); margin-top:2px; overflow-wrap:anywhere';
          d.textContent = `${voiceText(item.kind || '')} · ${(item.refs || []).join(', ')}`;
          line.append(n, d);
          body.appendChild(line);
        }
      }
      button('Back', 'btn-text', () => go('plan'));
      button('Next', 'btn-primary', () => go('ready'), !items);
    } else if (page === 'ready') {
      head.textContent = voiceText('Ready to switch');
      body.appendChild(stepper('ready'));
      for (const line of [
        'This kiosk listens, answers and draws the overlay.',
        onboarding
          ? 'Its Assistant and wake words are set once Home Assistant adds this kiosk.'
          : 'The dashboard stops running Voice Satellite on this kiosk.',
        'The old satellite stays in Home Assistant, unused.',
      ]) body.appendChild(para(`•  ${voiceText(line)}`, 'margin-bottom:6px'));
      button('Back', 'btn-text', () => go('automations'));
      button('Switch now', 'btn-primary', () => switchNow());
    } else if (!w.result) {
      head.textContent = voiceText('Switching…');
      for (const s of w.steps) {
        const icon = s.state === 'done' ? 'ok' : s.state === 'failed' ? 'error' : 'pending';
        const color = s.state === 'done' ? 'var(--primary)' : s.state === 'failed' ? 'var(--error)'
          : s.state === 'run' ? 'var(--primary)' : 'var(--outline)';
        const title = onboarding && s.id === 'entities' ? 'Turn on Voice Satellite on this kiosk' : STEP_TITLES[s.id] || s.id;
        body.appendChild(iconLine(icon, color, voiceText(title), ''));
      }
      if (!w.steps.length) body.appendChild(spinner());
    } else {
      const ok = w.result.ok === true;
      head.textContent = ok ? voiceText('Voice Satellite runs here now') : voiceText('Could not switch');
      body.appendChild(para(ok
        ? voiceText(onboarding
          ? 'Finish the setup, then add this kiosk in Home Assistant. Once no other device uses the Voice Satellite integration, uninstall it from HACS.'
          : 'Say the wake word to try it. Once no other device uses the Voice Satellite integration, uninstall it from HACS.')
        : onboarding
          ? voiceText(`${w.result.error || ''}`)
          : `${voiceText(`${w.result.error || ''}`)} ${voiceText('Voice Satellite runs from the dashboard again.')}`.trim()));
      if (!ok) button('Close', 'btn-text', () => finish(false));
      button(ok ? 'Done' : 'Try again', 'btn-primary', () => {
        if (ok) { finish(true); return; }
        w.result = null;
        w.step = pages.indexOf('ready');
        paint();
      });
    }
  };

  const switchNow = async () => {
    w.step = pages.length;
    w.steps = [];
    paint();
    // The switch runs for a while on the kiosk: follow its steps.
    const poll = setInterval(async () => {
      const r = await cmd('voiceMigrationProgress', {}).catch(() => null);
      if (r?.ok && Array.isArray(r.data?.steps) && !w.result) {
        w.steps = r.data.steps;
        paint();
      }
    }, 700);
    const r = await cmd('vsMigrate', { groups: [...w.groups], satellite: w.satellite, deferred: onboarding },
      { timeoutMs: 180000 }).catch((e) => ({ ok: false, error: `${e?.message || ''}` }));
    clearInterval(poll);
    w.result = { ok: r?.ok === true, error: r?.error };
    paint();
  };

  paint();
  cmd('haListVoiceSatellites', {}).catch(() => null).then((r) => {
    const list = r?.ok && Array.isArray(r.data) ? r.data : [];
    w.satellites = list;
    w.satellite = list[0]?.entity_id || '';
    api('/api/settings').then((res) => res.json()).then((data) => {
      const assigned = `${(data.settings || []).find((x) => x.key === 'ha.satellite_entity')?.value || ''}`.trim();
      if (list.some((x) => x.entity_id === assigned)) w.satellite = assigned;
      paint();
    }).catch(() => paint());
  });
  });
}

