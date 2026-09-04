import {
  GLANCE_MAX,
  cameraAction,
  cameraEditor,
  cameraListRow,
  cameraSelectField,
  cameraToggle,
  entitySearchPicker,
  glanceEntityPicker,
} from './cameras.js';
import { api, depSatisfied, gatedOn, state } from './core.js';
import { readOnlyRow } from './device.js';
import { updateAdaptiveBrightnessRows, updateFaceRows } from './notices.js';
import {
  openImmichNamesPicker,
  openLauncherAppsPicker,
  openMediaBrowser,
} from './pickers.js';
import { loadSettings, refreshRealMacNote, updatePersonSensorRows } from './settings.js';
import {
  attachSlider,
  dateBox,
  messageBox,
  swatch,
  timeBox,
} from './widgets.js';

// The Immich name-picker rows (albums, people, tags): which command lists
// the choices, and the words for an empty pick and an empty list, the same
// as the device's.
/* The warning that stands before real screen-off, on the slider and on a
   schedule entry's own, word-for-word with the device's dialog. */
const SCREEN_OFF_WARNING = "Once the display truly powers off, the tablet's own "
  + 'power management takes over, and many Android models misbehave in that '
  + 'state: Wi-Fi naps or drops, the Home Assistant entities go unavailable, '
  + 'the camera can be revoked, and some models kill background apps '
  + 'outright. What happens depends on the manufacturer.\n\n'
  + 'The reliable alternative is the Black screensaver with this setting '
  + 'left at 0: the panel looks just as dark, and the app keeps full control.';

const IMMICH_NAMED_ROWS = {
  'screensaver.immich_album': {
    command: 'immichAlbums', empty: 'All media',
    none: 'No albums yet. Create one in Immich first.',
  },
  'screensaver.immich_people': {
    command: 'immichPeople', empty: 'Anyone',
    none: 'No named people yet. Name them in Immich first.',
  },
  'screensaver.immich_exclude_people': {
    command: 'immichPeople', empty: 'No one',
    none: 'No named people yet. Name them in Immich first.',
  },
  'screensaver.immich_tags': {
    command: 'immichTags', empty: 'Any',
    none: 'No tags yet. Create them in Immich first.',
  },
};

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
  const visible = (o) => !o.hidden && depSatisfied(o, byKey);
  // Everything the flip can reach: the rows gated on this one, by either
  // gate, and the rows gated on those in turn (a revealed row may be a
  // gate itself).
  const reached = [];
  const walk = (k) => gatedOn(all, k)
    .forEach((o) => { reached.push(o); walk(o.key); });
  walk(key);
  const sameCard = (o) => o.category === anchor.category
    && (o.section || '') === (anchor.section || '')
    // A section split across a page boundary is two cards, and only one of
    // them is in the DOM: placing a row from the other lands it nowhere.
    && (o.subpage || '') === (anchor.subpage || '');
  // A flip that changes nothing on screen (a source switched between two
  // values that hide the same rows) needs no re-render, wherever the rows
  // it reaches live: only a row whose presence must change counts.
  const changes = (o) => visible(o) !== !!document.querySelector(`[data-key="${o.key}"]`);
  if (!reached.some(changes)) return true;
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

// The validator's message under a row, in place of nothing: rows.js is
// where every generic control saves, so the one spot to say a value was
// refused.
function showRowError(row, message) {
  let el = row.querySelector('.row-error');
  if (!el) {
    el = document.createElement('div');
    el.className = 'row-error';
    row.appendChild(el);
  }
  el.textContent = message;
}
function clearRowError(row) { row.querySelector('.row-error')?.remove(); }

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
    const res = await api('/api/settings', { method: 'PATCH', body: JSON.stringify({ [s.key]: value }) });
    const out = await res.json().catch(() => ({}));
    const cached = (state.settings || []).find((o) => o.key === s.key);
    // A value the definition's validator turned down: say why, under the
    // row, and put the control back on the value the device kept. Before
    // this the page just looked saved while the device held the old value.
    if (out.rejected?.includes(s.key)) {
      showRowError(row, out.errors?.[s.key] || 'Not saved.');
      const control = row.querySelector('input, select, textarea');
      if (control?.type === 'checkbox') control.checked = !!cached?.value;
      else if (control) {
        control.value = cached?.value ?? '';
        // A slider paints its fill and label off its input events, so
        // the snap-back has to look like one.
        if (control.type === 'range') control.dispatchEvent(new Event('input'));
      }
      return;
    }
    clearRowError(row);
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
    if (gatedOn(state.settings || [], s.key).length) {
      if (!syncGatedRows(s.key, row)) await loadSettings();
    }
    // The face detection notes answer for Dismiss on motion as it is now
    // (issue #304): motion takes precedence, and the warning under
    // Dismiss on face comes and goes with the motion switch.
    if (s.key === 'screensaver.dismiss_on_motion'
      || s.key === 'screensaver.dismiss_on_face') {
      updateFaceRows();
    }
    // The Person Detection page's status row answers for its own switch.
    if (s.key === 'screensaver.dismiss_on_person') updatePersonSensorRows();
    // The hints under the brightness sliders come and go with the
    // adaptive brightness switch (issue #343). After the gated sync, so
    // the curve rows the switch reveals are in place first.
    if (s.key === 'screen.adaptive_brightness') updateAdaptiveBrightnessRows();
    // The real-MAC status row and its field answer for the switch and the
    // typed address as they are now (issues #252, #300). After the gated
    // sync: the field is a hidden definition gated on the switch, which
    // the sync would take out of the card again if it ran second.
    if (s.key === 'esphome.real_mac' || s.key === 'esphome.mac_override') {
      await refreshRealMacNote();
    }
  };

  // The clock's background photo deliberately has no special case: the
  // generic text input edits the file path directly, the same contract as
  // the ESPHome Clock background entity (issue #150) — a path in, empty
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

  // A color is picked, not typed: the row swatch opens the same picker
  // dialog the device draws. Every "r,g,b" setting ends in _color by
  // convention; the device UI keys off the same suffix.
  if (s.key.endsWith('_color')) {
    row.appendChild(swatch(s.value || '250,250,250', s.title, (rgb) => save(rgb)));
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

  // The Immich people and tag filters, mirroring the device's pickers: the
  // chosen names as the summary, an Edit button opening the checkbox list.
  const immichNamed = IMMICH_NAMED_ROWS[s.key];
  if (immichNamed) {
    let chosen = [];
    try { chosen = JSON.parse(s.value || '[]') || []; } catch (_) {}
    const val = document.createElement('span');
    val.className = 'device';
    val.style.cssText =
      'flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap';
    val.textContent = chosen.length ? chosen.map((n) => n.name).join(', ') : immichNamed.empty;
    const btn = document.createElement('button');
    btn.className = 'btn-ghost'; btn.textContent = 'Edit';
    btn.style.flex = 'none';
    btn.addEventListener('click', async () => {
      const picked = await openImmichNamesPicker({
        title: s.title, command: immichNamed.command, current: chosen, none: immichNamed.none,
      });
      if (picked) {
        await api('/api/settings', { method: 'PATCH', body: JSON.stringify({
          [s.key]: JSON.stringify(picked),
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
    // device's dialog: time, screensaver, the brightness switch and its
    // slider, the screen-off switch and its slider, then the overrides.
    // That many controls do not fit in a row on either UI.
    const editEntry = async (existing) => {
      const others = entries.filter((e) => e !== existing);
      const brightnessDef = (state.settings || [])
        .find((o) => o.key === 'screensaver.brightness_level');
      const screenOffDef = (state.settings || [])
        .find((o) => o.key === 'screensaver.screen_off_minutes');
      const start = existing || {
        at: '19:00',
        mode: (modeDef && modeDef.value) || 'clock',
      };
      const globalLevel = (brightnessDef && typeof brightnessDef.value === 'number')
        ? brightnessDef.value : 0.2;
      const body = document.createElement('div');

      // Inside an editor the time is a labeled field, full width, opening
      // the same picker as the time rows.
      const timeWrap = document.createElement('div');
      timeWrap.className = 'form-field';
      const timeTitle = document.createElement('span');
      timeTitle.className = 'desc';
      timeTitle.textContent = 'Time';
      const time = timeBox({ title: 'Time', value: start.at || '19:00',
        full: true, onPick: () => {} });
      timeWrap.append(timeTitle, time.el);

      const modeSel = cameraSelectField('Screensaver',
        modes.map((m) => ({ value: m, label: label(m) })),
        modes.includes(start.mode) ? start.mode : ((modeDef && modeDef.value) || 'clock'));

      // The same switch as the main screensaver page: off, the entry
      // follows the Screensaver brightness setting outside the schedule
      // (which may itself be off, leaving the panel to the device or
      // adaptive brightness); on, the slider below is this entry's own
      // level.
      const hasLevel = typeof start.brightness === 'number';
      const brightOn = cameraToggle('Screensaver brightness', hasLevel,
        hasLevel ? 'Applies to every mode except Black.'
          : 'Follows the Screensaver brightness setting.');
      const brightWrap = document.createElement('label');
      brightWrap.className = 'form-field';
      const brightTitle = document.createElement('span');
      brightTitle.className = 'desc';
      brightTitle.textContent = 'Brightness';
      const brightLine = document.createElement('div');
      brightLine.style.cssText = 'display:flex; align-items:center; gap:10px;';
      const rng = document.createElement('input');
      rng.type = 'range'; rng.className = 'range';
      rng.min = '0'; rng.max = '100'; rng.step = '5';
      rng.value = String(Math.round((hasLevel ? start.brightness : globalLevel) * 100));
      rng.style.cssText = 'flex:1;';
      const pct = document.createElement('span');
      pct.className = 'device';
      pct.style.cssText = 'width:42px; text-align:right; flex-shrink:0;';
      pct.textContent = rng.value + '%';
      rng.addEventListener('input', () => { pct.textContent = rng.value + '%'; });
      brightLine.append(rng, pct);
      brightWrap.append(brightTitle, brightLine);
      // Inline display, not the hidden attribute: .form-field's own
      // display:flex would outrank [hidden] and keep the slider showing.
      brightWrap.style.display = hasLevel ? '' : 'none';
      brightOn.input.addEventListener('change', () => {
        brightWrap.style.display = brightOn.input.checked ? '' : 'none';
        brightOn.wrap.querySelector('.desc').textContent = brightOn.input.checked
          ? 'Applies to every mode except Black.'
          : 'Follows the Screensaver brightness setting.';
      });

      // The same slider as the main screensaver page, behind a switch:
      // off, the entry follows the Turn screen off after slider outside the
      // schedule; on, the slider below is this entry's own countdown,
      // starting from that slider's value, 0 keeping the panel on through
      // its hours even when that slider is set (issue #437).
      const globalOff = (screenOffDef && typeof screenOffDef.value === 'number')
        ? screenOffDef.value : 0;
      const hasOff = typeof start.screen_off === 'number';
      const offDesc = (on, minutes) => !on
        ? 'Follows the Turn screen off after setting.'
        : minutes === 0
          ? 'Keeps the screen on during these hours.'
          : 'Powers down the display once the screensaver has run this '
            + 'long. Requires Device Administrator permission.';
      const offOn = cameraToggle('Turn screen off after', hasOff,
        offDesc(hasOff, hasOff ? start.screen_off : 0));
      const offWrap = document.createElement('label');
      offWrap.className = 'form-field';
      const offTitle = document.createElement('span');
      offTitle.className = 'desc';
      offTitle.textContent = 'Turn screen off after';
      const offLine = document.createElement('div');
      offLine.style.cssText = 'display:flex; align-items:center; gap:10px;';
      const offRng = document.createElement('input');
      offRng.type = 'range'; offRng.className = 'range';
      offRng.min = '0'; offRng.max = '60'; offRng.step = '5';
      offRng.value = String(hasOff ? Math.min(60, Math.max(0, start.screen_off)) : globalOff);
      offRng.style.cssText = 'flex:1;';
      const offLabel = document.createElement('span');
      offLabel.className = 'device';
      offLabel.style.cssText = 'width:52px; text-align:right; flex-shrink:0;';
      const offPaint = () => {
        offLabel.textContent = +offRng.value === 0 ? 'Never' : offRng.value + ' min';
        offOn.wrap.querySelector('.desc').textContent =
          offDesc(offOn.input.checked, +offRng.value);
      };
      offPaint();
      let offBefore = +offRng.value;
      offRng.addEventListener('input', offPaint);
      // Leaving 0 gets the same warning as the slider outside the schedule.
      offRng.addEventListener('change', async () => {
        const next = +offRng.value;
        if (offBefore === 0 && next > 0) {
          const pick = await messageBox({
            title: 'WARNING: Please Read!',
            message: SCREEN_OFF_WARNING,
            buttons: ['Cancel', 'Turn screen off anyway'],
          });
          if (pick === 'Cancel') { offRng.value = '0'; offPaint(); return; }
        }
        offBefore = next;
      });
      offLine.append(offRng, offLabel);
      offWrap.append(offTitle, offLine);
      // Inline display, not the hidden attribute: .form-field's own
      // display:flex would outrank [hidden] and keep the slider showing.
      offWrap.style.display = hasOff ? '' : 'none';
      offOn.input.addEventListener('change', () => {
        offWrap.style.display = offOn.input.checked ? '' : 'none';
        offPaint();
      });

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
      // Motion keeps precedence inside an entry too: On here with motion
      // On above still wakes on motion.
      const face = overrideField('Dismiss on face', start.face);
      const faceOk = camOn
        && !(state.visionSupport && state.visionSupport.faces === false);
      face.select.disabled = !faceOk;
      if (!camOn) {
        face.select.title =
          'Requires the camera. Turn it on in the Camera settings first.';
      } else if (!faceOk) {
        face.select.title =
          state.visionSupport.hint || 'Not available on this device.';
      }
      // The proximity override is offered wherever the sensor is not
      // known to be missing (never disabled on a guess, like the switch),
      // and the person override only where the Person Detection page
      // exists at all (a Portal's sensor, hidden everywhere else).
      const proximity = overrideField('Dismiss on proximity', start.proximity);
      const prox = state.proximitySupport;
      if (prox && prox.supported === false) {
        proximity.select.disabled = true;
        proximity.select.title = prox.hint || 'Not available on this device.';
      }
      const personDef = (state.settings || [])
        .find((x) => x.key === 'screensaver.dismiss_on_person');
      const personShown = !!personDef && !personDef.hidden;
      const person = overrideField('Dismiss on person', start.person);
      const widgets = overrideField('Widgets', start.widgets);
      const glance = overrideField('At a glance', start.glance);

      body.append(timeWrap, modeSel.wrap, brightOn.wrap, brightWrap,
        offOn.wrap, offWrap, motion.wrap, face.wrap, proximity.wrap);
      if (personShown) body.append(person.wrap);
      body.append(widgets.wrap, glance.wrap);

      return cameraEditor({
        title: existing ? String(start.at) : 'Add time',
        width: 460,
        body,
        save: async () => {
          if (!time.value) return { ok: false, error: 'Pick a time.' };
          const entry = {
            at: time.value,
            mode: modeSel.select.value,
          };
          if (brightOn.input.checked) entry.brightness = (+rng.value) / 100;
          if (offOn.input.checked) entry.screen_off = +offRng.value;
          // The person field rides along unseen where the page is hidden,
          // so an entry's value from another device survives an edit here.
          for (const [key, field] of [['motion', motion], ['face', face],
            ['proximity', proximity], ['person', person],
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
      if (typeof e.face === 'boolean') {
        parts.push('Face ' + (e.face ? 'on' : 'off'));
      }
      if (typeof e.proximity === 'boolean') {
        parts.push('Proximity ' + (e.proximity ? 'on' : 'off'));
      }
      if (typeof e.person === 'boolean') {
        parts.push('Person ' + (e.person ? 'on' : 'off'));
      }
      if (typeof e.widgets === 'boolean') {
        parts.push('Widgets ' + (e.widgets ? 'on' : 'off'));
      }
      if (typeof e.glance === 'boolean') {
        parts.push('At a glance ' + (e.glance ? 'on' : 'off'));
      }
      if (typeof e.screen_off === 'number') {
        parts.push(e.screen_off <= 0 ? 'Screen off never'
          : 'Screen off after ' + Math.round(e.screen_off) + ' min');
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

    // The add row is the last row of the card, the whole row the button,
    // mirrored on the device.
    const addRow = () => cameraListRow('Add time',
      'A screensaver from that time on.', [],
      { icon: 'add', onClick: () => editEntry(null) });

    const repaint = () => {
      const parent = row.parentNode;
      const fresh = [...entries.map(entryRow), addRow()];
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
      ['battery', 'Battery'], ['entity', 'Entity']];
    const DEFAULTS = {
      clock: { color: '250,250,250', h24: false, date: false },
      weather: { entity: '', name: '', label: '', color: '250,250,250',
        feels_like: false, feels_like_only: false, location: true,
        forecast: true, humidity: true, wind: true, visibility: true },
      battery: { color: '250,250,250', percent: true, low: false },
      entity: { entity: '', name: '', label: '', attribute: '',
        show_name: true, color: '250,250,250' },
    };
    const order = CORNERS.map(([v]) => v);
    const cornerLabel = (v) => (CORNERS.find(([c]) => c === v) || [, v])[1];
    const typeLabel = (v) => (TYPES.find(([t]) => t === v) || [, v])[1];

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
        ? 'Hidden in Digital Clock and Camera Streams screensaver modes.'
        : 'Hidden in the Camera Streams screensaver mode.';
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
      // The tint as a labeled swatch, opening the same picker dialog as
      // the color rows.
      const colorField = () => {
        const wrap = document.createElement('div');
        wrap.className = 'form-field';
        wrap.style.alignItems = 'flex-start';
        const title = document.createElement('span');
        title.className = 'desc';
        title.textContent = 'Color';
        const input = swatch(config.color || '250,250,250', 'Color', () => {});
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
        if (type === 'entity') {
          // The entity everything is read from, picked by search the way
          // the At a Glance row's are; the friendly name is cached in the
          // config so both editors can show it without a round trip.
          const entityRow = document.createElement('div');
          entityRow.className = 'row';
          const info = document.createElement('div');
          info.className = 'info';
          const name = document.createElement('div');
          name.className = 'name';
          name.textContent = 'Entity';
          const desc = document.createElement('div');
          desc.className = 'desc';
          desc.textContent = config.name || config.entity || 'Not set';
          info.append(name, desc);
          refs.attribute = cameraSelectField('Displayed value',
            [{ value: '', label: 'State' },
              ...(config.attribute
                ? [{ value: config.attribute, label: config.attribute }] : [])],
            config.attribute || '');
          // What the widget displays: the state (the default) or one of
          // the entity's attributes, offered from its live attributes with
          // their current values (the At a Glance dialog's choice).
          const hidden = ['friendly_name', 'icon', 'entity_picture',
            'supported_features', 'attribution'];
          const loadAttributes = async () => {
            refs.attribute.select.disabled = !config.entity;
            if (!config.entity) return;
            try {
              const res = await (await api('/api/commands/haEntityAttributes', {
                method: 'POST',
                body: JSON.stringify({ entity_id: config.entity }) })).json();
              if (!res.ok) return;
              const attributes = res.data || {};
              const names = Object.keys(attributes).filter((k) =>
                !hidden.includes(k)
                && (attributes[k] === null || typeof attributes[k] !== 'object'))
                .sort();
              const current = refs.attribute.select.value;
              refs.attribute.select.innerHTML = '';
              const state = document.createElement('option');
              state.value = '';
              state.textContent = 'State';
              refs.attribute.select.appendChild(state);
              for (const n of names) {
                const o = document.createElement('option');
                o.value = n;
                o.textContent = `${n} \u00b7 ${attributes[n]}`;
                o.selected = n === current;
                refs.attribute.select.appendChild(o);
              }
            } catch (_) {}
          };
          const choose = cameraAction('Choose\u2026', async () => {
            const picked = await entitySearchPicker();
            if (!picked) return;
            // Another entity has other attributes: back to its state.
            if (picked.entity_id !== config.entity) {
              config.attribute = '';
              refs.attribute.select.value = '';
            }
            config.entity = picked.entity_id;
            config.name = picked.name;
            desc.textContent = config.name;
            refs.label.input.placeholder = config.name;
            loadAttributes();
          });
          entityRow.append(info, choose);
          refs.entity = { wrap: entityRow };
          refs.label = (() => {
            const wrap = document.createElement('label');
            wrap.className = 'form-field';
            const title = document.createElement('span');
            title.className = 'desc';
            title.textContent = 'Name';
            const input = document.createElement('input');
            input.className = 'field';
            input.type = 'text';
            input.placeholder = config.name
              || 'Leave empty to use the Home Assistant name';
            input.value = config.label || '';
            input.style.maxWidth = 'none';
            wrap.append(title, input);
            return { wrap, input };
          })();
          refs.showName = cameraToggle('Show name',
            config.show_name !== false, 'The name under the value.');
          typeBlock.append(refs.entity.wrap, refs.label.wrap,
            refs.attribute.wrap, refs.color.wrap, refs.showName.wrap);
          loadAttributes();
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
          wrap.className = 'form-field';
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
        refs.feelsLike = cameraToggle('Feels like',
          config.feels_like === true,
          'The apparent temperature after the real one, "30° / 33°".');
        refs.feelsLikeOnly = cameraToggle('Feels like only',
          config.feels_like_only === true,
          "The apparent temperature in the real one's place.");
        refs.forecast = cameraToggle('Forecast',
          config.forecast === true, 'The conditions, with a matching icon.');
        refs.humidity = cameraToggle('Humidity', config.humidity === true);
        refs.wind = cameraToggle('Wind speed', config.wind === true);
        refs.visibility = cameraToggle('Visibility', config.visibility === true);
        typeBlock.append(refs.entity.wrap, refs.label.wrap, refs.color.wrap,
          refs.location.wrap, refs.feelsLike.wrap, refs.feelsLikeOnly.wrap,
          refs.forecast.wrap, refs.humidity.wrap, refs.wind.wrap,
          refs.visibility.wrap);
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
          const color = refs.color.input.rgb;
          let entryConfig;
          if (type === 'clock') {
            entryConfig = { color,
              h24: refs.h24.input.checked, date: refs.date.input.checked };
          } else if (type === 'battery') {
            entryConfig = { color,
              percent: refs.percent.input.checked,
              low: refs.low.input.checked };
          } else if (type === 'entity') {
            if (!config.entity) return { ok: false, error: 'Pick an entity.' };
            entryConfig = { entity: config.entity,
              name: config.name || config.entity,
              label: refs.label.input.value.trim(),
              attribute: refs.attribute.select.value,
              show_name: refs.showName.input.checked, color };
          } else {
            const entity = refs.entity.select.value;
            if (!entity) return { ok: false, error: 'Pick a weather entity.' };
            const option = refs.entity.select.selectedOptions[0];
            entryConfig = { entity,
              name: option ? option.textContent : entity,
              label: refs.label.input.value.trim(), color,
              feels_like: refs.feelsLike.input.checked,
              feels_like_only: refs.feelsLikeOnly.input.checked,
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
        icon: ['weather', 'battery', 'entity'].includes(e.type)
          ? e.type : 'clock',
        onClick: () => editWidget(e),
      },
    );

    // The add row is the last row of the card, the whole row the button,
    // mirrored on the device. Every corner taken means nothing left to
    // add: the row stays, disabled, rather than disappearing.
    const addRow = () => cameraListRow('Add widget',
      'A small clock, the weather, the battery or an entity in a corner.', [],
      { icon: 'add', onClick: () => editWidget(null),
        disabled: entries.length >= CORNERS.length });

    const repaint = () => {
      const parent = row.parentNode;
      const fresh = [...entries.map(entryRow), addRow()];
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

  // The camera screensaver's views come from the ones configured under
  // Camera Streams, mirroring the device's picker: the chosen ones as rows
  // under the setting in rotation order, each with move and remove buttons,
  // the rest with an Add. Views without cameras are left out: there would
  // be nothing to show. Saved in place on every change, like the widgets.
  if (s.key === 'screensaver.camera_views') {
    let chosen = [];
    try { chosen = JSON.parse(s.value || '[]'); } catch (_) { chosen = []; }
    if (!Array.isArray(chosen)) chosen = [];
    chosen = chosen.filter((id, i) => typeof id === 'string' && chosen.indexOf(id) === i);
    let views = null;
    const save = () => api('/api/settings', { method: 'PATCH', body: JSON.stringify({
      'screensaver.camera_views': JSON.stringify(chosen),
    }) });

    // Real siblings, not a wrapper: the card's dividers are drawn between
    // adjacent .row elements, and a wrapping element would break the chain.
    const frag = document.createDocumentFragment();
    frag.appendChild(row);
    let listRows = [];
    const cameras = (view) => {
      const n = (view.cameraIds || []).length;
      return `${n} camera${n === 1 ? '' : 's'}`;
    };
    const build = () => {
      if (!views) return [];
      if (!views.length) {
        return [readOnlyRow('No camera view has cameras yet',
          'Add one under Camera Streams.', '')];
      }
      const byId = Object.fromEntries(views.map((v) => [v.id, v]));
      const rows = [];
      chosen.forEach((id, index) => {
        const view = byId[id];
        // Reordering one step at a time, saved as it goes.
        const move = (delta) => {
          const to = index + delta;
          if (to < 0 || to >= chosen.length) return;
          chosen.splice(to, 0, chosen.splice(index, 1)[0]);
          repaint();
          save();
        };
        rows.push(cameraListRow(view.name,
          `Position ${index + 1} · ${cameras(view)}`, [
            cameraAction('Move up', () => move(-1), false, 'up', index === 0),
            cameraAction('Move down', () => move(1), false, 'down',
              index === chosen.length - 1),
            cameraAction('Remove', () => {
              chosen = chosen.filter((x) => x !== id);
              repaint();
              save();
            }, false, 'delete'),
          ]));
      });
      for (const view of views) {
        if (chosen.includes(view.id)) continue;
        rows.push(cameraListRow(view.name, cameras(view), [
          cameraAction('Add', () => {
            chosen = chosen.concat(view.id);
            repaint();
            save();
          }, false, 'add'),
        ]));
      }
      return rows;
    };
    const repaint = () => {
      const parent = row.parentNode;
      const fresh = build();
      if (!parent) {
        listRows.forEach((el) => el.remove());
        fresh.forEach((el) => frag.appendChild(el));
      } else {
        listRows.forEach((el) => el.remove());
        let after = row;
        fresh.forEach((el) => {
          after.insertAdjacentElement('afterend', el);
          after = el;
        });
      }
      listRows = fresh;
    };
    (async () => {
      try {
        const res = await (await api('/api/commands/cameraGetConfig', { method: 'POST', body: '{}' })).json();
        views = (res.data?.views || []).filter((v) => (v.cameraIds || []).length);
      } catch (_) { views = []; }
      // A view deleted or emptied since it was chosen has nothing to show;
      // it leaves the list on the next save.
      chosen = chosen.filter((id) => views.some((v) => v.id === id));
      repaint();
    })();
    return frag;
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

  // A time of day is picked, not typed: the control box shows the value
  // and opens the time picker dialog, the same one the device draws.
  if (s.key === 'ha.theme_dark_at' || s.key === 'ha.theme_light_at') {
    row.appendChild(timeBox({ title: s.title, value: s.value || '',
      onPick: (v) => save(v) }).el);
    return row;
  }

  // A filter date is picked off a calendar, not typed: the control box
  // shows the day and opens the date picker, the same one the device
  // draws. Empty is the open end the placeholder names (issue #383).
  if (s.key === 'screensaver.immich_taken_from'
    || s.key === 'screensaver.immich_taken_to') {
    row.appendChild(dateBox({ title: s.title, value: s.value || '',
      placeholder: s.placeholder || 'Not set', onPick: (v) => save(v) }).el);
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
    const slider = attachSlider(row, {
      min: s.min, max: s.max, step: s.step ?? 'any',
      value: typeof s.value === 'number' ? s.value : s.min,
      label,
    });
    slider.input.addEventListener('change', async () => {
      const next = Number(slider.input.value);
      // Enabling real screen-off gets a warning first: what a dark panel
      // does to Wi-Fi, the camera and the app itself is the manufacturer's
      // call, and the Black screensaver avoids the whole regime.
      if (s.key === 'screensaver.screen_off_minutes' &&
          Number(s.value || 0) === 0 && next > 0) {
        const pick = await messageBox({
          title: 'WARNING: Please Read!',
          message: SCREEN_OFF_WARNING,
          buttons: ['Cancel', 'Turn screen off anyway'],
        });
        if (pick === 'Cancel') {
          slider.set(0);
          return;
        }
      }
      // save() records the value once the device has kept it; recording
      // it here first made a refused value snap "back" to itself.
      save(next);
    });
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
