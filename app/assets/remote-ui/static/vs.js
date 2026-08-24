import { toggleRow } from './audio.js';
import { cmd, state } from './core.js';
import { loadPermissions, readOnlyRow } from './device.js';

/* ---- Voice Satellite controls (synced to Home Assistant) ---- */
// The satellite binding and its sibling select entities (pipelines, wake
// word engine and models) live in HA; auto start and appearance live in the
// page's Voice Satellite profile. One vsControls read serves all three
// cards, mirroring the device's General / Wake Word / Appearance sections.
// Entity writes re-read after a beat so dependent option lists (wake word
// models per engine, pipeline 2 availability) follow.

export function vsSelectRow(name, desc, options, current, onChange) {
  const row = readOnlyRow(name, desc, '');
  row.querySelector('span').remove();
  const sel = document.createElement('select');
  for (const o of options) {
    const opt = document.createElement('option');
    opt.value = o.value;
    opt.textContent = o.label;
    opt.selected = o.value === current;
    sel.appendChild(opt);
  }
  if (current == null || !options.some((o) => o.value === current)) {
    const opt = document.createElement('option');
    opt.value = '';
    opt.textContent = '';
    opt.selected = true;
    opt.hidden = true;
    sel.prepend(opt);
  }
  sel.addEventListener('change', () => onChange(sel.value));
  row.appendChild(sel);
  return row;
}

export function vsSliderRow(name, desc, min, max, step, unit, value, onChange) {
  const row = readOnlyRow(name, desc, '');
  row.querySelector('span').remove();
  const controls = document.createElement('div');
  controls.style.cssText = 'display:flex; align-items:center; gap:10px; min-width:0';
  const inp = document.createElement('input');
  inp.type = 'range'; inp.min = String(min); inp.max = String(max);
  inp.step = String(step);
  inp.value = String(Math.round(value));
  inp.style.width = '190px';
  const val = document.createElement('span');
  val.style.cssText = 'min-width:4.5em; text-align:right; font-variant-numeric:tabular-nums; white-space:nowrap';
  val.textContent = `${Math.round(value)}${unit}`;
  inp.addEventListener('input', () => (val.textContent = `${inp.value}${unit}`));
  inp.addEventListener('change', () => onChange(Number(inp.value)));
  controls.append(inp, val);
  row.appendChild(controls);
  return row;
}

export let vsControlsJson = null;

export async function renderVsControls(root, { auto = false } = {}) {
  let data = null;
  try {
    const r = await cmd('vsControls');
    if (r.ok) data = r.data;
  } catch (_) {}
  // Auto refreshes (the poll, a wake state push) follow external changes
  // only: an unchanged read re-renders nothing, and a hand mid-interaction
  // is never disturbed by a rebuild underneath it.
  if (auto) {
    const j = JSON.stringify(data);
    if (j === vsControlsJson && root.querySelector('#vsGeneralCard')) return;
    const focus = document.activeElement;
    if (focus && ['SELECT', 'INPUT'].includes(focus.tagName)
        && (focus.closest('#vsGeneralCard') || focus.closest('#vsWakeCard')
          || focus.closest('#vsAppearanceCard'))) {
      return;
    }
    vsControlsJson = j;
  } else {
    vsControlsJson = JSON.stringify(data);
  }
  // Re-render in place: writes rebuild these three cards only, never the
  // whole settings page. The adopted "Keep listening in the background"
  // row (a declarative setting the General card borrows) must survive the
  // rebuild: park it back on the detection card before its host goes.
  const parked = root.querySelector('#vsGeneralCard [data-key="wake_word.background"]');
  if (parked) {
    // Somewhere that survives the three removals below, so the adoption
    // further down can find it again: the detection card its own definition
    // belongs to, else the page that card is on. NOT #vsWakeCard, which is
    // about to go. (It used to be parked on whatever card held
    // wake_word.enabled — a hidden setting that never renders, so the row
    // was quietly destroyed on every refresh.)
    const home =
      root.querySelector('[data-key="wake_word.prefer_fp32"]')?.closest('.card')
      || root.querySelector('.subpage[data-subpage="Wake Word"]')
      || root;
    home.appendChild(parked);
  }
  root.querySelector('#vsGeneralCard')?.remove();
  root.querySelector('#vsWakeCard')?.remove();
  root.querySelector('#vsAppearanceCard')?.remove();
  if (!data) return;

  const rebuild = (delay) => setTimeout(() => renderVsControls(root), delay);
  const entity = (key) => (data.entities || {})[key] || null;
  const browser = data.browser && data.browser.config ? data.browser.config : null;

  const applyBrowser = async (partial) => {
    try { await cmd('vsSetBrowserSettings', { settings: partial }); } catch (_) {}
  };
  const selectEntity = async (key, option) => {
    const ent = entity(key);
    if (!ent) return;
    try {
      await cmd('haCallService', { domain: 'select', service: 'select_option',
        entity_id: ent.entity_id, data: { option } });
    } catch (_) {}
    rebuild(900);
  };
  const switchEntity = async (key, on) => {
    const ent = entity(key);
    if (!ent) return;
    try {
      await cmd('haCallService', { domain: 'switch',
        service: on ? 'turn_on' : 'turn_off', entity_id: ent.entity_id });
    } catch (_) {}
    rebuild(900);
  };
  const entitySwitchRow = (key, title, desc) => {
    const ent = entity(key);
    if (!ent) return null;
    if (!ent.available) return readOnlyRow(title, desc, 'Not available');
    return toggleRow(title, desc, ent.state === 'on',
      (v) => switchEntity(key, v));
  };
  const entityRow = (key, title, desc, capitalize) => {
    const ent = entity(key);
    if (!ent) return null;
    if (!ent.available || !(ent.options || []).length) {
      return readOnlyRow(title, desc, 'Not available');
    }
    // Options whose values are bare lowercase words render like Home
    // Assistant shows them; the raw value is what gets written.
    const label = (o) => capitalize && o ? o[0].toUpperCase() + o.slice(1) : o;
    return vsSelectRow(title, desc,
      (ent.options || []).map((o) => ({ value: o, label: label(o) })),
      ent.state, (v) => selectEntity(key, v));
  };
  // A heading only where the group sits among others: on a page of its own
  // the title bar already carries the name.
  const section = (id, title) => {
    const wrap = document.createElement('div');
    wrap.id = id;
    const card = document.createElement('div');
    card.className = 'card';
    if (title) {
      const h = document.createElement('h2');
      h.className = 'card-title';
      h.textContent = title;
      wrap.append(h, card);
    } else {
      wrap.appendChild(card);
    }
    return [wrap, card];
  };
  const panel = (sub) => root.querySelector(`.subpage[data-subpage="${sub}"]`);

  // General: the engine, the satellite binding, auto start and the
  // pipelines.
  const [generalWrap, generalCard] = section('vsGeneralCard', 'General');
  const engine = data.browser && data.browser.engine;
  if (engine) {
    const row = readOnlyRow('Engine',
      'Start or Stop the Voice Satellite engine.', '');
    const status = row.querySelector('span');
    status.textContent = engine.running ? 'Running' : 'Stopped';
    status.style.color = engine.running ? 'var(--ok)' : 'var(--muted)';
    status.style.marginRight = '10px';
    const btn = document.createElement('button');
    btn.className = 'btn-ghost';
    btn.textContent = engine.running ? 'Stop' : 'Start';
    btn.style.cssText = engine.running
      ? 'background:var(--error); border-color:transparent; color:#fff'
      : 'background:var(--ok); border-color:transparent; color:#fff';
    // Both halves must agree a start can work: the page's own answer AND a
    // satellite actually assigned - without one there is nothing to start.
    btn.disabled = !engine.running && !(engine.canStart && data.satellite);
    btn.addEventListener('click', async () => {
      btn.disabled = true;
      try { await cmd('vsEngine', { action: engine.running ? 'stop' : 'start' }); } catch (_) {}
      rebuild(1200);
    });
    row.appendChild(btn);
    generalCard.appendChild(row);
  }
  const satDesc = 'The assist_satellite entity this kiosk identifies as in ' +
    'Home Assistant. Changing it reloads the dashboard.';
  const sats = data.satellites || [];
  if (sats.length) {
    generalCard.appendChild(vsSelectRow('Assigned satellite', satDesc,
      // Disabled clears the binding: the kiosk stops identifying as a
      // satellite until one is picked again.
      [{ value: '', label: 'Disabled' },
       ...sats.map((s) => ({ value: s.entity_id, label: s.name }))],
      data.satellite || '',
      async (v) => {
        try { await cmd('vsSetSatellite', { entity_id: v }); } catch (_) {}
        rebuild(3000);
      }));
  } else {
    generalCard.appendChild(readOnlyRow('Assigned satellite', satDesc,
      data.satellite || 'None assigned'));
  }
  if (browser) {
    generalCard.appendChild(toggleRow('Auto start',
      'Auto start Voice Satellite on dashboard load.',
      browser.auto_start !== false, (v) => applyBrowser({ auto_start: v })));
  }
  // Adopt the declarative "Keep listening in the background" row out of the
  // detection card: important enough to sit with the important rows, and
  // moving the live node keeps its save wiring and gating intact.
  const bgRow = root.querySelector('[data-key="wake_word.background"]');
  if (bgRow) {
    const host = bgRow.parentNode;
    generalCard.appendChild(bgRow);
    // Its card existed only to carry it now that the rest of the detection
    // settings are on the Wake Word page; an empty one would read as a gap.
    if (host && host.classList?.contains('card') && !host.querySelector('.row')) {
      host.remove();
    }
  }
  for (const row of [
    entitySwitchRow('mute', 'Mute', 'Stop listening for wake words.'),
    entityRow('pipeline', 'Assist pipeline 1',
      'The Assist pipeline voice commands run through.'),
    entityRow('pipeline_2', 'Assist pipeline 2',
      'The pipeline used when the second wake word triggers.'),
    entityRow('vad_sensitivity', 'Finished speaking detection',
      'How long a pause ends a voice command.', true),
  ]) if (row) generalCard.appendChild(row);
  // Only offered once the settings hook reports the key: an older Voice
  // Satellite silently drops writes it does not know.
  if (browser && 'debug' in browser) {
    generalCard.appendChild(toggleRow('Debug logging',
      'Show Voice Satellite debug info in the browser console.',
      browser.debug === true, (v) => applyBrowser({ debug: v })));
  }
  if (data.version) {
    generalCard.appendChild(readOnlyRow('Voice Satellite version',
      'The integration version installed in Home Assistant.',
      `v${data.version}`));
  }

  // Wake Word: the card's engine and wake word selects, above the app's
  // own detection card.
  const [wakeWrap, wakeCard] = section('vsWakeCard', null);
  // With detection handed to the Home Assistant server or off entirely,
  // the on-device rows (models, sensitivity, gate, stop word) configure
  // nothing; only the engine select stays.
  const engineState = entity('wake_word_detection')?.state;
  const onDevice = engineState !== 'Home Assistant' && engineState !== 'Disabled';
  const wakeRows = [
    entityRow('wake_word_detection', 'Wake word engine',
      'Where detection runs and which engine listens.'),
    ...(onDevice ? [
      entityRow('wake_word_model', 'Wake word 1',
        'The word that starts a voice command.'),
      entityRow('wake_word_model_2', 'Wake word 2',
        'A second wake word, answered by Assist pipeline 2.'),
      entityRow('wake_word_sensitivity', 'Wake word sensitivity',
        'How easily the wake word triggers.'),
      entitySwitchRow('noise_gate', 'Wake word noise gate',
        'Skip local wake word inference while the room is quiet, saving CPU.'),
      entitySwitchRow('stop_word', 'Stop word interruption',
        'Say the stop word to interrupt responses.'),
    ] : []),
  ].filter(Boolean);
  if (wakeRows.length) {
    for (const row of wakeRows) wakeCard.appendChild(row);
    // Models are cached by URL, so re-publishing one on Home Assistant under
    // the same name is invisible to this device until the cache is dropped.
    if (onDevice) {
      const row = document.createElement('div'); row.className = 'row';
      const info = document.createElement('div'); info.className = 'info';
      info.innerHTML = `<div class="name">Cached models</div>` +
        `<div class="desc">Re-download from Home Assistant. Use after re-publishing a model.</div>`;
      row.appendChild(info);
      const btn = document.createElement('button');
      btn.className = 'btn-ghost';
      btn.textContent = 'Clear cache';
      btn.addEventListener('click', async () => {
        btn.disabled = true;
        btn.textContent = 'Clearing…';
        try {
          const r = await cmd('clearWakeWordModels');
          btn.textContent = r.ok ? `Cleared ${r.data.removed}` : 'Failed';
        } catch { btn.textContent = 'Failed'; }
        setTimeout(() => { btn.disabled = false; btn.textContent = 'Clear cache'; }, 1200);
      });
      row.appendChild(btn);
      wakeCard.appendChild(row);
    }
  } else {
    wakeCard.appendChild(readOnlyRow('Wake word',
      'Assign a satellite to control these settings.', ''));
  }

  // Appearance: browser-local, through the page hook.
  const [appearanceWrap, appearanceCard] = section('vsAppearanceCard', null);
  if (!browser) {
    // An outdated Voice Satellite runs without the settings hook; that
    // asks for an update, not for showing the dashboard.
    appearanceCard.appendChild(readOnlyRow('Not available',
      data.browserState === 'outdated'
        ? 'Update the Voice Satellite integration in Home Assistant to control these settings from the kiosk.'
        : 'Available while the kiosk is showing your Home Assistant dashboard.',
      ''));
  } else {
    const skins = (data.browser.skins || [])
      .map((s) => ({ value: s.value, label: s.label }));
    appearanceCard.appendChild(vsSelectRow('Skin',
      'The look of the voice assistant overlay.', skins,
      browser.skin || 'default', (v) => applyBrowser({ skin: v })));
    appearanceCard.appendChild(vsSelectRow('Theme mode',
      'Light or dark rendering of the overlay.',
      [{ value: 'auto', label: 'Auto' }, { value: 'light', label: 'Light' },
       { value: 'dark', label: 'Dark' }],
      browser.theme_mode || 'auto', (v) => applyBrowser({ theme_mode: v })));
    appearanceCard.appendChild(toggleRow('Reactive activity bar',
      'The activity bar reacts to audio. NOT RECOMMENDED for low-power devices like the Echo Show.',
      browser.reactive_bar !== false,
      (v) => applyBrowser({ reactive_bar: v })));
    const fps = Math.min(60, Math.max(5,
      Math.round(1000 / (browser.reactive_bar_update_interval_ms || 33))));
    appearanceCard.appendChild(vsSliderRow('Reactive bar update rate',
      'How often the activity bar redraws. Higher is smoother and uses more CPU.',
      5, 60, 1, ' fps', fps,
      (v) => applyBrowser({ reactive_bar_update_interval_ms: Math.round(1000 / v) })));
    appearanceCard.appendChild(vsSliderRow('Text scale',
      'The size of the overlay text.', 50, 200, 5, '%',
      browser.text_scale || 100, (v) => applyBrowser({ text_scale: v })));
  }

  // General leads the Voice Satellite page; the other two groups are second
  // level now, so each goes into the panel its entry row opens. Wake Word
  // goes first in its panel, above the app's own detection settings.
  const wakePanel = panel('Wake Word');
  if (wakePanel) wakePanel.prepend(wakeWrap); else root.appendChild(wakeWrap);
  const appearancePanel = panel('Appearance');
  if (appearancePanel) appearancePanel.appendChild(appearanceWrap);
  else root.appendChild(appearanceWrap);
  root.prepend(generalWrap);
}

// External changes (the HA UI, the Voice Satellite panel, a voice command)
// move the controlled entities without touching this page; while the cards
// are on screen, follow along. Unchanged reads render nothing.
setInterval(() => {
  // Any of the three: General sits on the Voice Satellite page, Wake Word
  // and Appearance on their own, and only the visible one needs following.
  const card = ['vsGeneralCard', 'vsWakeCard', 'vsAppearanceCard']
    .map((id) => document.getElementById(id))
    .find((el) => el && el.offsetParent);
  if (!card) return;
  renderVsControls(document.getElementById('tab-voicesatellite'), { auto: true });
}, 10000);

/* ---- Voice Satellite permissions ---- */
// The Voice Satellite status card used to build here; the Wake Word card
// now says the same things, so only the permissions card remains, behind
// the connection gate with the rest of the HA page.
export async function loadVsPermissions() {
  if (!state.haConnected) {
    document.querySelector('#tab-voicesatellite #permsCard')?.remove();
    return;
  }
  await loadPermissions();
}
