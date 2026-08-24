import {
  GLANCE_MAX,
  cameraAction,
  cameraEditor,
  cameraListRow,
  cameraSelectField,
  cameraToggle,
  glanceEntityPicker,
} from './cameras.js';
import { api, state } from './core.js';
import { readOnlyRow } from './device.js';
import { openLauncherAppsPicker, openMediaBrowser } from './pickers.js';
import { loadSettings } from './settings.js';
import { messageBox } from './widgets.js';

// Bring the rows gated on `key` (dependsOn, transitively) in or out of the
// card `anchorRow` sits in, reading the values already in state.settings —
// no fetch, no tab rebuild, nothing else on the page touched.
//
// Returns false when the flip reaches past that one card, which is the case
// this cannot place a row for: a heading may need creating or removing, and
// where it belongs is the renderer's business. The caller falls back to a
// full re-render there.
export function syncGatedRows(key, anchorRow) {
  const all = state.settings || [];
  const card = anchorRow.parentNode;
  const byKey = Object.fromEntries(all.map((o) => [o.key, o]));
  const anchor = byKey[key];
  if (!anchor || !card) return false;
  // The same visibility rule loadSettings() renders by, so a row that comes
  // back in place is exactly the row a re-render would have drawn.
  const depSatisfied = (o) => {
    if (!o.dependsOn) return true;
    const dep = byKey[o.dependsOn];
    if (!dep) return true;
    return dep.value === (o.dependsOnValue ?? true) && depSatisfied(dep);
  };
  const visible = (o) => !o.hidden && depSatisfied(o);
  // Everything the flip can reach: the rows gated on this one, and the rows
  // gated on those in turn (a revealed row may be a gate itself).
  const reached = [];
  const walk = (k) => all.filter((o) => o.dependsOn === k)
    .forEach((o) => { reached.push(o); walk(o.key); });
  walk(key);
  const sameCard = (o) => o.category === anchor.category
    && (o.section || '') === (anchor.section || '')
    // A section split across a page boundary is two cards, and only one of
    // them is in the DOM: placing a row from the other lands it nowhere.
    && (o.subpage || '') === (anchor.subpage || '');
  if (!reached.every(sameCard)) return false;
  // Schema order within the card decides where a returning row goes back:
  // in front of the first row after it that is currently on screen.
  const order = all.filter(sameCard);
  for (const o of reached) {
    const existing = card.querySelector(`[data-key="${o.key}"]`);
    if (!visible(o)) { existing?.remove(); continue; }
    if (existing) continue;
    let before = null;
    for (let i = order.indexOf(o) + 1; i < order.length && !before; i++) {
      before = card.querySelector(`[data-key="${order[i].key}"]`);
    }
    card.insertBefore(settingRow(o), before);
  }
  return true;
}

export function settingRow(s) {
  const row = document.createElement('div'); row.className = 'row';
  // Lets a saved row find another row without a re-render (see save()).
  row.dataset.key = s.key;
  const info = document.createElement('div'); info.className = 'info';
  info.innerHTML = `<div class="name"></div><div class="desc"></div>`;
  info.querySelector('.name').textContent = s.title;
  info.querySelector('.desc').textContent = s.description;
  row.appendChild(info);
  const save = async (value) => {
    await api('/api/settings', { method: 'PATCH', body: JSON.stringify({ [s.key]: value }) });
    const cached = (state.settings || []).find((o) => o.key === s.key);
    if (cached) cached.value = value;
    // AGC hides the gain slider next to it without gating it (the row is
    // always rendered, so there is nothing for syncGatedRows to place).
    if (s.key === 'audio.mic_agc') {
      const gain = document.querySelector('[data-key="audio.mic_gain_db"]');
      if (gain) gain.style.display = value ? 'none' : '';
      return;
    }
    // Three keys genuinely need the device's answer again: the rotation
    // switch reveals a hand-built section, and editing either Immich
    // credential resets immich_validated on the device, which the dependent
    // rows and the validate row must reflect.
    if (s.key === 'ha.rotation_enabled'
      || s.key === 'screensaver.immich_url'
      || s.key === 'screensaver.immich_api_key') {
      await loadSettings();
      return;
    }
    // Otherwise the only thing a flip can change is which rows it gates
    // (dependsOn), and those come and go in place — the same trick the
    // hand-built Home Assistant cards use. A loadSettings() here rebuilds
    // every tab and re-runs the device probes they own, which reads as the
    // whole page reloading under the switch just flipped.
    if ((state.settings || []).some((o) => o.dependsOn === s.key)) {
      if (!syncGatedRows(s.key, row)) await loadSettings();
    }
  };

  // The clock's background photo deliberately has no special case: the
  // generic text input edits the file path directly, the same contract as
  // the MQTT Clock background entity (issue #150) — a path in, empty
  // clears. Picking from the device's photos still happens on the device.

  // The gallery selection lives on the device (system photo picker); the
  // remote shows the count, mirroring the device row's summary.
  if (s.key === 'screensaver.gallery_items') {
    let count = 0;
    try { count = JSON.parse(s.value || '[]').length; } catch (_) {}
    const val = document.createElement('span');
    val.className = 'device';
    val.textContent = count
      ? `${count} selected`
      : 'None selected. Pick on the device.';
    row.appendChild(val);
    return row;
  }

  // A color is picked, not typed, the browser has a real picker for it.
  // Every "r,g,b" setting ends in _color by convention; the device UI keys
  // off the same suffix.
  if (s.key.endsWith('_color')) {
    const [r, g, b] = String(s.value || '250,250,250').split(',').map((n) => +n || 0);
    const hex = '#' + [r, g, b].map((n) => n.toString(16).padStart(2, '0')).join('');
    const inp = document.createElement('input');
    inp.type = 'color'; inp.value = hex;
    inp.style.cssText = 'width:44px; height:32px; padding:2px; background:var(--surface-2);'
      + 'border:1px solid var(--border); border-radius:var(--radius-sm); cursor:pointer';
    inp.addEventListener('change', () => {
      const h = inp.value; // #rrggbb
      const rgb = [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16)).join(',');
      save(rgb);
    });
    row.appendChild(inp);
    return row;
  }

  // The screensaver's media is browsed from Home Assistant, not typed, the
  // same picker the device offers, so the two stay in step.
  if (s.key === 'screensaver.media_id') {
    const val = document.createElement('span');
    val.className = 'device';
    val.style.cssText =
      'flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap';
    val.textContent = s.value || 'Not set';
    const btn = document.createElement('button');
    btn.className = 'btn-ghost'; btn.textContent = 'Browse';
    btn.style.flex = 'none';
    btn.addEventListener('click', async () => {
      const picked = await openMediaBrowser();
      if (picked) {
        await api('/api/settings', { method: 'PATCH', body: JSON.stringify({
          'screensaver.media_id': picked.id,
          'screensaver.media_is_folder': picked.isFolder,
        }) });
        await loadSettings();
      }
    });
    // One wrapper so the value + button occupy a single grid cell on mobile.
    const controls = document.createElement('div');
    controls.style.cssText =
      'display:flex; gap:10px; align-items:center; min-width:0; max-width:60%; flex:0 1 auto';
    controls.append(val, btn);
    row.appendChild(controls);
    return row;
  }

  // The Immich source is a dropdown fed by the server's albums, mirroring
  // the device's picker. The saved choice renders immediately (by its stored
  // name); the live list replaces it when the server answers.
  if (s.key === 'screensaver.immich_album') {
    const byKey = Object.fromEntries((state.settings || []).map((o) => [o.key, o]));
    const sel = document.createElement('select');
    const rebuild = (albums) => {
      sel.innerHTML = '';
      const all = document.createElement('option');
      all.value = ''; all.textContent = 'All media';
      all.selected = !s.value;
      sel.appendChild(all);
      for (const a of albums) {
        const opt = document.createElement('option');
        opt.value = a.id; opt.textContent = a.name;
        opt.selected = a.id === s.value;
        sel.appendChild(opt);
      }
    };
    rebuild(s.value
      ? [{ id: s.value, name: byKey['screensaver.immich_album_name']?.value || 'Album' }]
      : []);
    (async () => {
      try {
        const res = await (await api('/api/commands/immichAlbums', { method: 'POST', body: '{}' })).json();
        if (res.ok) rebuild(res.data || []);
      } catch (_) {}
    })();
    sel.addEventListener('change', async () => {
      const name = sel.value ? sel.options[sel.selectedIndex].textContent : '';
      await api('/api/settings', { method: 'PATCH', body: JSON.stringify({
        'screensaver.immich_album': sel.value,
        'screensaver.immich_album_name': name,
      }) });
    });
    row.appendChild(sel);
    return row;
  }

  // The launcher whitelist, mirroring the device's checkbox picker. The
  // summary renders from the labels cached in the setting; the picker asks
  // the device for the live app list.
  if (s.key === 'launcher.apps') {
    let chosen = [];
    try { chosen = JSON.parse(s.value || '[]') || []; } catch (_) {}
    const val = document.createElement('span');
    val.className = 'device';
    // min-width:0 (not a % cap of the auto-sized flex box) is what lets the
    // summary shrink and ellipsize, so the Edit button keeps its place at
    // the row's edge instead of drifting with the label length.
    val.style.cssText =
      'flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap';
    val.textContent = chosen.length ? chosen.map((a) => a.label).join(', ') : 'None yet';
    const btn = document.createElement('button');
    btn.className = 'btn-ghost'; btn.textContent = 'Edit';
    btn.style.flex = 'none';
    btn.addEventListener('click', async () => {
      const picked = await openLauncherAppsPicker(chosen);
      if (picked) {
        await api('/api/settings', { method: 'PATCH', body: JSON.stringify({
          'launcher.apps': JSON.stringify(picked),
        }) });
        await loadSettings();
      }
    });
    const controls = document.createElement('div');
    controls.style.cssText =
      'display:flex; gap:10px; align-items:center; min-width:0; max-width:60%; flex:0 1 auto';
    controls.append(val, btn);
    row.appendChild(controls);
    return row;
  }

  // The At a Glance entities, mirroring the device's picker. The picker row
  // holds only the button; the chosen entities get a row each below it, so
  // the group reads like every other list in this admin instead of cramming
  // four names into one value cell.
  // The screensaver schedule, mirroring the device's editor: one summary
  // row per entry - its time, mode and overrides - plus an add button, with
  // every setting edited in a labeled modal, the same shape as the device's
  // dialog. Each entry applies from its time until the next one's.
  if (s.key === 'screensaver.schedule') {
    let entries = [];
    try { entries = JSON.parse(s.value || '[]') || []; } catch (_) { entries = []; }
    const modeDef = (state.settings || []).find((x) => x.key === 'screensaver.mode');
    const modes = (modeDef && modeDef.options) || [];
    const labels = (modeDef && modeDef.optionLabels) || {};
    const label = (m) => labels[m] || (m ? m[0].toUpperCase() + m.slice(1) : m);

    const btn = document.createElement('button');
    btn.className = 'btn-ghost';
    btn.textContent = 'Add time';
    btn.style.cssText = 'flex-shrink:0;';
    row.appendChild(btn);

    // Real siblings, not a wrapper: the card's dividers are drawn between
    // adjacent .row elements (see the glance editor above).
    const frag = document.createDocumentFragment();
    frag.appendChild(row);
    let entryRows = [];

    const persist = async () => {
      entries.sort((a, b) => String(a.at).localeCompare(String(b.at)));
      const json = JSON.stringify(entries);
      const cached = (state.settings || []).find((o) => o.key === s.key);
      if (cached) cached.value = json;
      await api('/api/settings', { method: 'PATCH', body: JSON.stringify({
        'screensaver.schedule': json,
      }) });
      repaint();
    };

    // The labeled editor modal, the same fields in the same order as the
    // device's dialog: time, screensaver, brightness, then the three
    // overrides. Six controls do not fit in a row on either UI.
    const editEntry = async (existing) => {
      const others = entries.filter((e) => e !== existing);
      const brightnessDef = (state.settings || [])
        .find((o) => o.key === 'screensaver.brightness_level');
      const start = existing || {
        at: '19:00',
        mode: (modeDef && modeDef.value) || 'clock',
        brightness: (brightnessDef && typeof brightnessDef.value === 'number')
          ? brightnessDef.value : 0.2,
      };
      const body = document.createElement('div');

      const timeWrap = document.createElement('label');
      timeWrap.style.cssText =
        'display:flex; flex-direction:column; gap:6px; flex:1; min-width:180px;';
      const timeTitle = document.createElement('span');
      timeTitle.className = 'desc';
      timeTitle.textContent = 'Time';
      const time = document.createElement('input');
      time.className = 'field';
      time.type = 'time';
      time.value = start.at || '19:00';
      time.style.maxWidth = 'none';
      timeWrap.append(timeTitle, time);

      const modeSel = cameraSelectField('Screensaver',
        modes.map((m) => ({ value: m, label: label(m) })),
        modes.includes(start.mode) ? start.mode : ((modeDef && modeDef.value) || 'clock'));

      // The brightness this entry runs at, always set: an entry carrying
      // none would silently inherit whatever the global slider says, which
      // is what a night entry is usually set to escape.
      const brightWrap = document.createElement('label');
      brightWrap.style.cssText = 'display:flex; flex-direction:column; gap:6px;';
      const brightTitle = document.createElement('span');
      brightTitle.className = 'desc';
      brightTitle.textContent = 'Brightness';
      const brightLine = document.createElement('div');
      brightLine.style.cssText = 'display:flex; align-items:center; gap:10px;';
      const rng = document.createElement('input');
      rng.type = 'range'; rng.min = '0'; rng.max = '100'; rng.step = '5';
      rng.value = String(Math.round(
        ((typeof start.brightness === 'number') ? start.brightness : 0.2) * 100));
      rng.style.cssText = 'flex:1;';
      const pct = document.createElement('span');
      pct.className = 'device';
      pct.style.cssText = 'width:42px; text-align:right; flex-shrink:0;';
      pct.textContent = rng.value + '%';
      rng.addEventListener('input', () => { pct.textContent = rng.value + '%'; });
      brightLine.append(rng, pct);
      brightWrap.append(brightTitle, brightLine);

      // The three overrides share one shape: Default follows the matching
      // setting outside the schedule, On and Off decide it for this entry's
      // hours.
      const overrideField = (title, value) => cameraSelectField(title,
        [{ value: '', label: 'Default' }, { value: 'on', label: 'On' },
          { value: 'off', label: 'Off' }],
        (typeof value === 'boolean') ? (value ? 'on' : 'off') : '');
      // No camera means no motion detection to override, same as the
      // Dismiss on motion switch.
      const camOn = ((state.settings || []).find((x) => x.key === 'camera.enabled') || {}).value === true
        && state.cameraPresent !== false;
      const motion = overrideField('Dismiss on motion', start.motion);
      motion.select.disabled = !camOn;
      if (!camOn) {
        motion.select.title =
          'Requires the camera. Turn it on in the Camera settings first.';
      }
      const widgets = overrideField('Widgets', start.widgets);
      const glance = overrideField('At a glance', start.glance);

      body.append(timeWrap, modeSel.wrap, brightWrap, motion.wrap,
        widgets.wrap, glance.wrap);

      return cameraEditor({
        title: existing ? String(start.at) : 'Add time',
        width: 460,
        body,
        save: async () => {
          if (!time.value) return { ok: false, error: 'Pick a time.' };
          const entry = {
            at: time.value,
            mode: modeSel.select.value,
            brightness: (+rng.value) / 100,
          };
          for (const [key, field] of [['motion', motion],
            ['widgets', widgets], ['glance', glance]]) {
            if (field.select.value) entry[key] = field.select.value === 'on';
          }
          entries = [...others, entry];
          await persist();
          return { ok: true };
        },
      });
    };

    // The row's second line: the mode, then only the overrides actually
    // set, so a plain entry reads as one word instead of a row of
    // "default"s. Kept word-for-word with the device's summary.
    const summary = (e) => {
      const parts = [label(e.mode)];
      if (typeof e.brightness === 'number') {
        parts.push(Math.round(e.brightness * 100) + '% brightness');
      }
      if (typeof e.motion === 'boolean') {
        parts.push('Motion ' + (e.motion ? 'on' : 'off'));
      }
      if (typeof e.widgets === 'boolean') {
        parts.push('Widgets ' + (e.widgets ? 'on' : 'off'));
      }
      if (typeof e.glance === 'boolean') {
        parts.push('At a glance ' + (e.glance ? 'on' : 'off'));
      }
      return parts.join(' · ');
    };

    const entryRow = (e) => cameraListRow(
      String(e.at), summary(e),
      [
        cameraAction('Delete', () => {
          entries = entries.filter((o) => o !== e);
          persist();
        }, false, 'delete'),
      ],
      { icon: 'clock', onClick: () => editEntry(e) },
    );

    const repaint = () => {
      const parent = row.parentNode;
      const fresh = entries.map(entryRow);
      if (!parent) {
        entryRows.forEach((el) => el.remove());
        fresh.forEach((el) => frag.appendChild(el));
      } else {
        entryRows.forEach((el) => el.remove());
        let after = row;
        fresh.forEach((el) => {
          after.insertAdjacentElement('afterend', el);
          after = el;
        });
      }
      entryRows = fresh;
    };
    repaint();

    btn.addEventListener('click', () => editEntry(null));
    return frag;
  }

  // The screensaver widgets (small corner overlays), mirroring the device's
  // editor: one summary row per widget - its type and corner - plus an add
  // button, with every setting edited in a labeled modal, the same shape as
  // the device's dialog. One widget per corner. The type and corner labels
  // are kept word-for-word with screensaver_widgets.dart.
  if (s.key === 'screensaver.widgets') {
    let entries = [];
    try { entries = JSON.parse(s.value || '[]') || []; } catch (_) { entries = []; }
    const CORNERS = [['top_left', 'Top left'], ['top_right', 'Top right'],
      ['bottom_left', 'Bottom left'], ['bottom_right', 'Bottom right']];
    const TYPES = [['clock', 'Small clock'], ['weather', 'Weather'],
      ['battery', 'Battery']];
    const DEFAULTS = {
      clock: { color: '250,250,250', h24: false, date: false },
      weather: { entity: '', name: '', label: '', color: '250,250,250',
        location: true, forecast: true, humidity: true, wind: true,
        visibility: true },
      battery: { color: '250,250,250', percent: true, low: false },
    };
    const order = CORNERS.map(([v]) => v);
    const cornerLabel = (v) => (CORNERS.find(([c]) => c === v) || [, v])[1];
    const typeLabel = (v) => (TYPES.find(([t]) => t === v) || [, v])[1];

    const btn = document.createElement('button');
    btn.className = 'btn-ghost';
    btn.textContent = 'Add widget';
    btn.style.cssText = 'flex-shrink:0;';
    row.appendChild(btn);

    // Real siblings, not a wrapper: the card's dividers are drawn between
    // adjacent .row elements (see the schedule editor above).
    const frag = document.createDocumentFragment();
    frag.appendChild(row);
    let entryRows = [];

    const persist = async () => {
      entries.sort((a, b) => order.indexOf(a.position) - order.indexOf(b.position));
      const json = JSON.stringify(entries);
      const cached = (state.settings || []).find((o) => o.key === s.key);
      if (cached) cached.value = json;
      await api('/api/settings', { method: 'PATCH', body: JSON.stringify({
        'screensaver.widgets': json,
      }) });
      repaint();
    };

    // The labeled editor modal, the same fields in the same order as the
    // device's dialog: corner, widget type, then the type's own settings.
    const editWidget = async (existing) => {
      const others = entries.filter((e) => e !== existing);
      // Only unclaimed corners are offered: one widget per corner.
      const free = CORNERS.filter(([v]) =>
        v === existing?.position || !others.some((o) => o.position === v));
      let type = TYPES.some(([t]) => t === existing?.type)
        ? existing.type : 'clock';
      let config = { ...DEFAULTS[type], ...(existing?.config || {}) };

      const body = document.createElement('div');
      // The hint reads directly under the title, before any control; the
      // wording is per type, kept word-for-word with the device dialog.
      const note = document.createElement('span');
      note.className = 'desc';
      const noteFor = (t) => t === 'clock'
        ? 'Hidden in Digital Clock and WebRTC screensaver modes.'
        : 'Hidden in the WebRTC screensaver mode.';
      const cornerSel = cameraSelectField('Corner',
        free.map(([value, label]) => ({ value, label })),
        existing?.position || free[0][0]);
      const typeSel = cameraSelectField('Widget',
        TYPES.map(([value, label]) => ({ value, label })), type);
      // The current type's own settings, rebuilt when the type changes.
      const typeBlock = document.createElement('div');
      typeBlock.className = 'modal-form';
      typeBlock.style.display = 'contents';
      body.append(note, cornerSel.wrap, typeSel.wrap, typeBlock);

      // Live references into the current type block, read on save.
      let refs = {};
      const colorField = () => {
        const wrap = document.createElement('label');
        wrap.style.cssText = 'display:flex; flex-direction:column; gap:6px;';
        const title = document.createElement('span');
        title.className = 'desc';
        title.textContent = 'Color';
        const [cr, cg, cb] = String(config.color || '250,250,250').split(',').map((n) => +n || 0);
        const input = document.createElement('input');
        input.type = 'color';
        input.value = '#' + [cr, cg, cb].map((n) => n.toString(16).padStart(2, '0')).join('');
        input.style.cssText = 'width:64px; height:36px; padding:2px;'
          + ' background:var(--surface-2); border:1px solid var(--border);'
          + ' border-radius:var(--radius-sm); cursor:pointer;';
        wrap.append(title, input);
        return { wrap, input };
      };
      const renderTypeBlock = () => {
        note.textContent = noteFor(type);
        typeBlock.innerHTML = '';
        refs = { color: colorField() };
        if (type === 'clock') {
          refs.h24 = cameraToggle('24-hour clock',
            config.h24 === true, 'Show a 24-hour time instead of AM/PM.');
          refs.date = cameraToggle('Show date',
            config.date === true, 'Add a short date under the clock.');
          typeBlock.append(refs.color.wrap, refs.h24.wrap, refs.date.wrap);
          return;
        }
        if (type === 'battery') {
          refs.percent = cameraToggle('Show percentage',
            config.percent !== false, 'The charge beside the icon.');
          refs.low = cameraToggle('Only when low',
            config.low === true,
            'Stay hidden until the charge drops to 20 percent.');
          typeBlock.append(refs.color.wrap, refs.percent.wrap, refs.low.wrap);
          return;
        }
        // Weather: the entity everything is read from, then the line
        // toggles. The temperature always shows; each other line also
        // needs the entity to actually carry the reading.
        refs.entity = cameraSelectField('Weather entity',
          config.entity
            ? [{ value: config.entity, label: config.name || config.entity }]
            : [{ value: '', label: 'Pick a weather entity…' }],
          config.entity || '');
        (async () => {
          try {
            const res = await (await api('/api/commands/haSearchEntities', {
              method: 'POST', body: JSON.stringify({ query: 'weather.' }) })).json();
            if (!res.ok) return;
            const found = (res.data || [])
              .filter((e) => String(e.entity_id || '').startsWith('weather.'));
            if (!found.length) return;
            refs.entity.select.innerHTML = '';
            if (!config.entity) {
              const blank = document.createElement('option');
              blank.value = ''; blank.textContent = 'Pick a weather entity…';
              refs.entity.select.appendChild(blank);
            }
            for (const e of found) {
              const o = document.createElement('option');
              o.value = e.entity_id; o.textContent = e.name || e.entity_id;
              o.selected = e.entity_id === config.entity;
              refs.entity.select.appendChild(o);
            }
          } catch (_) {}
        })();
        // Weather entities carry no city attribute, so the place shown
        // over the temperature is named by hand.
        refs.label = (() => {
          const wrap = document.createElement('label');
          wrap.style.cssText = 'display:flex; flex-direction:column; gap:6px;';
          const title = document.createElement('span');
          title.className = 'desc';
          title.textContent = 'Location name';
          const input = document.createElement('input');
          input.className = 'field';
          input.type = 'text';
          input.placeholder = 'Leave empty to hide the location line';
          input.value = config.label || '';
          input.style.maxWidth = 'none';
          wrap.append(title, input);
          return { wrap, input };
        })();
        refs.location = cameraToggle('Location',
          config.location === true, "The place's name over the temperature.");
        refs.forecast = cameraToggle('Forecast',
          config.forecast === true, 'The conditions, with a matching icon.');
        refs.humidity = cameraToggle('Humidity', config.humidity === true);
        refs.wind = cameraToggle('Wind speed', config.wind === true);
        refs.visibility = cameraToggle('Visibility', config.visibility === true);
        typeBlock.append(refs.entity.wrap, refs.label.wrap, refs.color.wrap,
          refs.location.wrap, refs.forecast.wrap, refs.humidity.wrap,
          refs.wind.wrap, refs.visibility.wrap);
      };
      renderTypeBlock();
      typeSel.select.addEventListener('change', () => {
        type = typeSel.select.value;
        // A different widget, different settings: start from its defaults,
        // and retitle the modal, which reads as this widget's settings.
        config = { ...DEFAULTS[type] };
        renderTypeBlock();
        const head = body.closest('.modal-card')?.querySelector('.modal-title');
        if (head) head.textContent = typeLabel(type);
      });

      return cameraEditor({
        // The widget's own name: the modal reads as that widget's
        // settings, not as a generic form.
        title: typeLabel(type),
        width: 460,
        body,
        save: async () => {
          const position = cornerSel.select.value;
          const hex = refs.color.input.value; // #rrggbb
          const color = [1, 3, 5].map((x) => parseInt(hex.slice(x, x + 2), 16)).join(',');
          let entryConfig;
          if (type === 'clock') {
            entryConfig = { color,
              h24: refs.h24.input.checked, date: refs.date.input.checked };
          } else if (type === 'battery') {
            entryConfig = { color,
              percent: refs.percent.input.checked,
              low: refs.low.input.checked };
          } else {
            const entity = refs.entity.select.value;
            if (!entity) return { ok: false, error: 'Pick a weather entity.' };
            const option = refs.entity.select.selectedOptions[0];
            entryConfig = { entity,
              name: option ? option.textContent : entity,
              label: refs.label.input.value.trim(), color,
              location: refs.location.input.checked,
              forecast: refs.forecast.input.checked,
              humidity: refs.humidity.input.checked,
              wind: refs.wind.input.checked,
              visibility: refs.visibility.input.checked };
          }
          const entry = { position, type, config: entryConfig };
          // The corner list only offers free corners, but drop any claimant
          // anyway so a stale modal cannot double-book one.
          entries = [...others.filter((o) => o.position !== position), entry];
          await persist();
          return { ok: true };
        },
      });
    };

    const entryRow = (e) => cameraListRow(
      typeLabel(e.type), cornerLabel(e.position),
      [
        cameraAction('Delete', () => {
          entries = entries.filter((o) => o !== e);
          persist();
        }, false, 'delete'),
      ],
      {
        icon: e.type === 'weather' ? 'weather'
          : (e.type === 'battery' ? 'battery' : 'clock'),
        onClick: () => editWidget(e),
      },
    );

    const repaint = () => {
      // Every corner taken means nothing left to add.
      btn.disabled = entries.length >= CORNERS.length;
      const parent = row.parentNode;
      const fresh = entries.map(entryRow);
      if (!parent) {
        entryRows.forEach((el) => el.remove());
        fresh.forEach((el) => frag.appendChild(el));
      } else {
        entryRows.forEach((el) => el.remove());
        let after = row;
        fresh.forEach((el) => {
          after.insertAdjacentElement('afterend', el);
          after = el;
        });
      }
      entryRows = fresh;
    };
    repaint();

    btn.addEventListener('click', () => editWidget(null));
    return frag;
  }

  if (s.key === 'screensaver.glance_entities') {
    let chosen = [];
    try { chosen = JSON.parse(s.value || '[]') || []; } catch (_) { chosen = []; }
    const btn = document.createElement('button');
    btn.className = 'btn-ghost';
    btn.textContent = 'Choose\u2026';
    btn.style.cssText = 'flex-shrink:0;';
    row.appendChild(btn);

    // Real siblings, not a wrapper: the card's dividers are drawn between
    // adjacent .row elements, and a wrapping element would break the chain.
    // The caller appends whatever is returned, so a fragment delivers them
    // all into the same card.
    const frag = document.createDocumentFragment();
    frag.appendChild(row);
    let entityRows = [];
    const build = () => {
      if (!chosen.length) {
        return [readOnlyRow('None yet', `Up to ${GLANCE_MAX} entities.`, '')];
      }
      // Numbered so the display order is readable without opening the modal.
      return chosen.map((entity, index) => readOnlyRow(
        entity.custom_name || entity.name || entity.entity_id,
        entity.attribute
          ? `${entity.entity_id} · ${entity.attribute}`
          : entity.entity_id,
        `${index + 1}`));
    };
    const repaint = () => {
      const parent = row.parentNode;
      const fresh = build();
      if (!parent) {
        entityRows.forEach((el) => el.remove());
        fresh.forEach((el) => frag.appendChild(el));
      } else {
        entityRows.forEach((el) => el.remove());
        let after = row;
        fresh.forEach((el) => {
          after.insertAdjacentElement('afterend', el);
          after = el;
        });
      }
      entityRows = fresh;
    };
    repaint();

    btn.addEventListener('click', async () => {
      const picked = await glanceEntityPicker(chosen);
      if (!picked) return;
      chosen = picked;
      repaint();
      await api('/api/settings', { method: 'PATCH', body: JSON.stringify({
        'screensaver.glance_entities': JSON.stringify(chosen),
      }) });
    });
    return frag;
  }

  // The camera screensaver's view comes from the ones configured under
  // Camera Streams, mirroring the device's picker. Views without cameras
  // are left out: there would be nothing to show.
  if (s.key === 'screensaver.camera_view') {
    const sel = document.createElement('select');
    const rebuild = (views) => {
      sel.innerHTML = '';
      if (!views.length) {
        const none = document.createElement('option');
        none.value = '';
        none.textContent = 'No camera views with cameras';
        sel.appendChild(none);
        sel.disabled = true;
        return;
      }
      sel.disabled = false;
      const unset = document.createElement('option');
      unset.value = ''; unset.textContent = 'Not set';
      unset.selected = !s.value;
      sel.appendChild(unset);
      for (const view of views) {
        const opt = document.createElement('option');
        opt.value = view.id;
        opt.textContent = view.name;
        opt.selected = view.id === s.value;
        sel.appendChild(opt);
      }
    };
    rebuild([]);
    (async () => {
      try {
        const res = await (await api('/api/commands/cameraGetConfig', { method: 'POST', body: '{}' })).json();
        rebuild((res.data?.views || []).filter((v) => (v.cameraIds || []).length));
      } catch (_) {}
    })();
    sel.addEventListener('change', async () => {
      const name = sel.value ? sel.options[sel.selectedIndex].textContent : '';
      await api('/api/settings', { method: 'PATCH', body: JSON.stringify({
        'screensaver.camera_view': sel.value,
        'screensaver.camera_view_name': name,
      }) });
    });
    row.appendChild(sel);
    return row;
  }

  // The cache cap carries its live usage under the description, the same
  // line the device shows under the field.
  if (s.key === 'screensaver.immich_cache_max_items') {
    const inp = document.createElement('input');
    inp.type = 'number';
    inp.value = typeof s.value === 'number' ? String(s.value) : '';
    inp.addEventListener('change', () => save(Number(inp.value)));
    row.appendChild(inp);
    const note = document.createElement('div');
    note.className = 'desc';
    note.textContent = '…';
    info.appendChild(note);
    (async () => {
      try {
        const res = await (await api('/api/commands/immichCacheStats', { method: 'POST', body: '{}' })).json();
        const d = res.data || {};
        const b = d.bytes ?? 0;
        const fmt = b < 1024 ? `${b} B` : b < 1048576 ? `${(b / 1024).toFixed(1)} KB`
          : b < 1073741824 ? `${(b / 1048576).toFixed(1)} MB` : `${(b / 1073741824).toFixed(2)} GB`;
        note.textContent = `${d.items ?? 0} cached, ${fmt}`;
      } catch (_) { note.textContent = ''; }
    })();
    return row;
  }

  // A time of day gets the browser's native time picker.
  if (s.key === 'ha.theme_dark_at' || s.key === 'ha.theme_light_at') {
    const inp = document.createElement('input');
    inp.type = 'time';
    inp.value = s.value || '';
    inp.style.cssText = 'background:var(--surface-2); border:1px solid var(--border);'
      + 'border-radius:var(--radius-sm); color:var(--text); padding:6px 8px';
    inp.addEventListener('change', () => save(inp.value));
    row.appendChild(inp);
    return row;
  }

  // A bounded number is dragged, not typed, the same slider the device
  // shows. Label updates live; the value saves once, on release.
  if (s.type === 'number' && s.min != null && s.max != null) {
    const label = (v) => {
      // Hold mode's auto-release reads as a clock: 0 is "Never" and 90 is
      // "1 h 30 min". Kept identical to the device's copy.
      if (s.key === 'ha.hold_release_minutes') {
        const minutes = Math.round(v);
        if (minutes <= 0) return 'Never';
        const h = Math.floor(minutes / 60), m = minutes % 60;
        if (h === 0) return `${m} min`;
        return m === 0 ? `${h} h` : `${h} h ${m} min`;
      }
      return s.unit === '%'
        ? `${Math.round(s.max <= 1 ? v * 100 : v)}%`
        : `${v}${s.unit || ''}`;
    };
    const controls = document.createElement('div');
    controls.style.cssText = 'display:flex; align-items:center; gap:10px; min-width:0';
    const inp = document.createElement('input');
    inp.type = 'range';
    inp.min = s.min; inp.max = s.max; inp.step = s.step ?? 'any';
    inp.value = typeof s.value === 'number' ? s.value : s.min;
    inp.style.width = '190px';
    const val = document.createElement('span');
    val.className = 'device';
    val.style.cssText = 'min-width:3.5em; text-align:right; font-variant-numeric:tabular-nums';
    val.textContent = label(+inp.value);
    inp.addEventListener('input', () => (val.textContent = label(+inp.value)));
    inp.addEventListener('change', async () => {
      const next = Number(inp.value);
      // Enabling real screen-off gets a warning first: what a dark panel
      // does to Wi-Fi, the camera and the app itself is the manufacturer's
      // call, and the Black screensaver avoids the whole regime.
      if (s.key === 'screensaver.screen_off_minutes' &&
          Number(s.value || 0) === 0 && next > 0) {
        const pick = await messageBox({
          title: 'WARNING: Please Read!',
          message: "Once the display truly powers off, the tablet's own "
            + 'power management takes over, and many Android models '
            + 'misbehave in that state: Wi-Fi naps or drops, the Home '
            + 'Assistant entities go unavailable, the camera can be '
            + 'revoked, and some models kill background apps outright. '
            + 'What happens depends on the manufacturer.\n\n'
            + 'The reliable alternative is the Black screensaver with this '
            + 'setting left at 0: the panel looks just as dark, and the '
            + 'app keeps full control.',
          buttons: ['Cancel', 'Turn screen off anyway'],
        });
        if (pick === 'Cancel') {
          inp.value = 0;
          val.textContent = label(0);
          return;
        }
      }
      s.value = next;
      save(next);
    });
    controls.append(inp, val);
    row.appendChild(controls);
    return row;
  }

  if (s.type === 'boolean') {
    const lbl = document.createElement('label'); lbl.className = 'switch';
    const cb = document.createElement('input'); cb.type = 'checkbox'; cb.checked = !!s.value;
    cb.addEventListener('change', async () => {
      // The one switch here that takes away the thing you are using. Nothing
      // on this page can undo it, because this page is what it serves.
      if (s.key === 'remote.enabled' && !cb.checked) {
        const pick = await messageBox({
          title: 'Turn off remote management?',
          message: 'WARNING: You will no longer be able to access this page. '
            + 'To switch it back on, use the device or the Remote management '
            + 'switch in Home Assistant.',
          buttons: ['Cancel', 'Turn it off'],
        });
        if (pick !== 'Turn it off') { cb.checked = true; return; }
      }
      save(cb.checked);
    });
    const sl = document.createElement('span'); sl.className = 'slider';
    lbl.append(cb, sl); row.appendChild(lbl);
  } else if (s.type === 'select') {
    const sel = document.createElement('select');
    let opts = s.options || [];
    if (s.key === 'screensaver.mode' && !state.haConfigured)
      opts = opts.filter((o) => o !== 'media');
    opts.forEach((o) => {
      const opt = document.createElement('option');
      opt.value = o;
      // The declared label ('media' → "Home Assistant Media"), or
      // Capitalised as a fallback, stored values are lowercase identifiers.
      opt.textContent = (s.optionLabels && s.optionLabels[o]) ||
        (o ? o[0].toUpperCase() + o.slice(1) : o);
      opt.selected = o === s.value; sel.appendChild(opt);
    });
    sel.addEventListener('change', () => save(sel.value));
    row.appendChild(sel);
  } else if (s.multiline) {
    // Pasted code gets a real editor, not a one-line field.
    const ta = document.createElement('textarea');
    ta.value = s.value ?? '';
    if (s.placeholder) ta.placeholder = s.placeholder;
    ta.rows = 5;
    ta.spellcheck = false;
    ta.style.cssText = 'width:100%; max-width:440px; background:var(--surface-2);'
      + 'border:1px solid var(--border); border-radius:var(--radius-sm); color:var(--text);'
      + 'padding:8px 10px; font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;'
      + 'font-size:12.5px; resize:vertical';
    ta.addEventListener('change', () => save(ta.value));
    row.appendChild(ta);
  } else {
    const inp = document.createElement('input');
    inp.type = s.type === 'password' ? 'password' : s.type === 'number' ? 'number' : 'text';
    if (s.type === 'password') inp.placeholder = s.value === '__set__' ? '•••••• (set)' : 'Not set';
    else {
      inp.value = (s.type === 'number' && typeof s.value === 'number')
        ? String(s.value)  // JS prints an integer-valued number without a .0
        : (s.value ?? '');
      // Same hint the device shows in an empty field (the DLNA port before
      // the renderer has filled it in).
      if (s.placeholder) inp.placeholder = s.placeholder;
    }
    inp.addEventListener('change', () =>
      save(s.type === 'number' ? Number(inp.value) : inp.value));
    row.appendChild(inp);
  }
  return row;
}
