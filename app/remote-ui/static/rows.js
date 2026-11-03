import { confirmRemoteProtocol } from './tls.js';
import { brightnessCurveRow } from './brightness_curve.js';
import { esphomeText, kioskText, launcherText, messageLanguage, voiceText } from './localization.js';
import { intercomError, mediaText, cameraText, cameraError, deviceText, haText, screensaverText, screensaverError, t } from './localization.js';
import { watchUpdates } from './live.js';
import {
  GLANCE_MAX,
  cameraAction,
  cameraEditor,
  cameraListRow,
  cameraSelectField,
  cameraToggle,
  glanceEntityEditor,
} from './cameras.js';
import { api, depSatisfied, gatedOn, state } from './core.js';
import { readOnlyRow } from './device.js';
import { openEspHomeEntityPicker } from './esphome.js';
import {
  cachedList, choiceBox, entitySpec, loadEntityList, loadList, onListLoaded, pickEntityValue,
  pickField, pickItem, pickItems, pickListRow, speakerPillSpec,
} from './entity_picker.js';
import {
  entityLightReading,
  externalMotionReading,
  probeExternalMotion,
  updateAdaptiveBrightnessRows,
  updateFaceRows,
  updateMotionCameraRows,
  syncScreenOffAdminNotice,
} from './notices.js';
import {
  TOAST_SOURCES,
  WAKE_SOURCES,
  decodeToastsHidden,
  decodeWakeSources,
  openImmichNamesPicker,
  openLauncherAppsPicker,
  openMediaBrowser,
  openToastsPicker,
  openWakeSourcesPicker,
  toastsShownText,
  wakeSourcesText,
} from './pickers.js';
import { loadSettings, refreshRealMacNote, syncSubpages, updateCelestialLocationRow, updateCelestialPermissionRows, updateClockNightAdminRows, updateOnvifEventsRows, updatePersonSensorRows, updateRtspRows } from './settings.js';
import { dashboardField } from './dashboard_picker.js';
import { drawerItemsText, openDrawerItemsPicker } from './drawer_items.js';
import { SEARCH_CATEGORY_TABS, jumpToResult } from './search.js';
import { updatePlayerRow } from './panels.js';
import {
  attachSlider,
  dateBox,
  messageBox,
  localizedMessageBox,
  swatch,
  timeBox,
} from './widgets.js';

// The Immich name-picker rows (albums, people, tags): which command lists
// the choices, and the words for an empty pick and an empty list, the same
// as the device's.
// Mirrors cameraAutoDismissStops in definitions.dart.
const CAMERA_DISMISS_STOPS = [
  ...Array.from({length: 11}, (_, i) => i * 30),
  ...Array.from({length: 11}, (_, i) => (i + 2) * 300),
];

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
  'screensaver.immich_exclude_tags': {
    command: 'immichTags', empty: 'No tags',
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
  // Rows on second-level pages of the tab this row is on (the Player pick
  // swapping the Sendspin Player page for the AirPlay one) come and go with
  // their pages, drawn in place too.
  const away = reached.filter((o) => !sameCard(o) && changes(o));
  if (away.length && (anchor.subpage || !away.every((o) => o.subpage)
      || !syncSubpages(away))) {
    return false;
  }
  // Schema order within the card decides where a returning row goes back:
  // in front of the first row after it that is currently on screen.
  const order = all.filter(sameCard);
  for (const o of reached.filter(sameCard)) {
    const existing = card.querySelector(`[data-key="${o.key}"]`);
    if (!visible(o)) { existing?.remove(); continue; }
    if (existing) continue;
    let before = null;
    for (let i = order.indexOf(o) + 1; i < order.length && !before; i++) {
      before = card.querySelector(`[data-key="${order[i].key}"]`);
    }
    // Custom controls can follow the schema rows, as in Voice Satellite's
    // General section. Keep a revealed child beside its preceding setting.
    if (!before) {
      for (let i = order.indexOf(o) - 1; i >= 0; i--) {
        const previous = card.querySelector(`[data-key="${order[i].key}"]`);
        if (previous) { before = previous.nextSibling; break; }
      }
    }
    card.insertBefore(settingRow(o), before);
  }
  return true;
}

// The validator's message under a row, in place of nothing: rows.js is
// where every generic control saves, so the one spot to say a value was
// refused.
function showRowError(row, message, onRetry) {
  let el = row.querySelector('.row-error');
  if (!el) {
    el = document.createElement('div');
    el.className = 'row-error';
    row.appendChild(el);
  }
  el.textContent = cameraError(screensaverError(haText(deviceText(intercomError(esphomeText(mediaText(message)))))));
  if (onRetry) {
    const retry = document.createElement('button');
    retry.className = 'btn-ghost';
    retry.textContent = deviceText('Retry');
    retry.addEventListener('click', async () => {
      retry.disabled = true;
      try { await onRetry(); }
      finally { retry.disabled = false; }
    });
    el.appendChild(retry);
  }
}
function clearRowError(row) { row.querySelector('.row-error')?.remove(); }

function albumArtCacheRow() {
  const row = document.createElement('div');
  row.className = 'row';
  row.dataset.key = 'albumArtCache';
  const info = document.createElement('div');
  info.className = 'info';
  const name = document.createElement('div');
  name.className = 'name';
  name.textContent = mediaText('Album art cache');
  const note = document.createElement('div');
  note.className = 'desc';
  note.textContent = mediaText('Checking cache size...');
  info.append(name, note);
  const button = document.createElement('button');
  button.className = 'btn-ghost';
  button.textContent = mediaText('Clear');
  row.append(info, button);
  let revision = 0;
  const format = (bytes) => bytes < 1024 ? `${bytes} B`
    : bytes < 1048576 ? `${(bytes / 1024).toFixed(1)} KB`
    : `${(bytes / 1048576).toFixed(1)} MB`;
  const show = (data) => {
    note.textContent = t('mediaCacheUsage', {used: format(data.bytes), limit: format(data.maxBytes)});
  };
  const command = async (name) => {
    const response = await api(`/api/commands/${name}`, { method: 'POST', body: '{}' });
    const result = await response.json();
    if (!response.ok || !result.ok) throw new Error('Cache command failed');
    return result.data;
  };
  const read = async () => {
    const current = revision;
    try {
      const data = await command('albumArtCacheStats');
      if (current === revision) show(data);
    } catch (_) {
      if (current === revision) note.textContent = mediaText('Could not read cache size.');
    }
  };
  button.addEventListener('click', async () => {
    revision++;
    button.disabled = true;
    button.textContent = mediaText('Clearing...');
    try { show(await command('clearAlbumArtCache')); }
    catch (_) { note.textContent = mediaText('Could not clear the cache.'); }
    finally { button.disabled = false; button.textContent = mediaText('Clear'); }
  });
  read();
  watchUpdates(['artwork-cache'], read, { owner: row });
  return row;
}

// A labeled control in an editor dialog, the device's LabeledField.
function formField(label, control) {
  const wrap = document.createElement('div');
  wrap.className = 'form-field';
  const title = document.createElement('span');
  title.className = 'desc';
  title.textContent = label;
  wrap.append(title, control);
  return wrap;
}

export function settingRow(s) {
  const row = document.createElement('div'); row.className = 'row';
  // Lets a saved row find another row without a re-render (see save()).
  row.dataset.key = s.key;
  // Only the control that rendered this value knows how to update it.
  // Decorators can replace that control with a picker of their own.
  const bindUpdate = (control, paint) => {
    let displayed = control.value;
    row.updateSetting = () => {
      if (!row.contains(control)) return false;
      const editing = document.activeElement === control
        && (control.tagName === 'TEXTAREA'
          || (control.tagName === 'INPUT' && !['checkbox', 'range'].includes(control.type)));
      if (!editing || control.value === displayed) {
        paint();
        displayed = control.value;
      }
      return true;
    };
  };
  const info = document.createElement('div'); info.className = 'info';
  info.innerHTML = `<div class="name"></div><div class="desc"></div>`;
  info.querySelector('.name').textContent = s.title;
  info.querySelector('.desc').textContent = s.description;
  row.appendChild(info);
  const save = async (value) => {
    const cached = (state.settings || []).find((o) => o.key === s.key);
    try {
      const res = await api('/api/settings', { method: 'PATCH', body: JSON.stringify({ [s.key]: value }) });
      const out = await res.json().catch(() => null);
      if (!res.ok || out?.ok !== true || out.rejected?.includes(s.key)) {
        throw new Error(out?.errors?.[s.key] || out?.error
          || 'Could not save this setting. Try again.');
      }
    } catch (error) {
      const control = row.querySelector('input, select, textarea');
      // Keep typed text for correction or retry. Switches, selections and
      // sliders return to the last confirmed value.
      const editable = control && (control.tagName === 'TEXTAREA'
        || (control.tagName === 'INPUT' && !['checkbox', 'range'].includes(control.type)));
      showRowError(row, error?.message || 'Could not save this setting. Try again.',
        editable ? () => save(s.type === 'number' ? Number(control.value) : control.value) : null);
      if (control?.type === 'checkbox') control.checked = !!cached?.value;
      else if (control && !editable) {
        control.value = cached?.value ?? '';
        // A slider paints its fill and label off its input events, so
        // the snap-back has to look like one.
        if (control.type === 'range') control.dispatchEvent(new Event('input'));
      }
      return;
    }
    clearRowError(row);
    if (cached) cached.value = value;
    if (s.key === 'ui.language') {
      await loadSettings({ cached: true });
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
    // The Player row lists the new source's players.
    if (s.key === 'sendspin.player_source') updatePlayerRow();
    if (s.key === 'screensaver.screen_off_black' || s.key === 'screensaver.screen_off_minutes') {
      syncScreenOffAdminNotice();
    }
    // The face detection notes answer for Dismiss on motion as it is now
    // (issue #304): motion takes precedence, and the warning under
    // Dismiss on face comes and goes with the motion switch.
    if (s.key === 'screensaver.dismiss_on_motion'
      || s.key === 'screensaver.dismiss_on_face') {
      updateFaceRows();
    }
    // A Home Assistant entity in the camera's place frees Dismiss on
    // motion from the camera (issue #973).
    if (s.key === 'motion.use_entity') updateMotionCameraRows();
    // The person sensor pages' status rows answer for their own switches.
    if (s.key === 'screensaver.dismiss_on_person' || s.key === 'person.sensor') updatePersonSensorRows();
    // Turn screen off at night's grant group answers for the Night mode
    // settings above it.
    if (['screensaver.clock_night', 'screensaver.clock_night_turn_off_minutes',
      'screensaver.clock_night_turn_off_black'].includes(s.key)) updateClockNightAdminRows();
    if (s.key === 'camera.rtsp.enabled' || s.key === 'camera.rtsp.protocol') updateRtspRows();
    // The ONVIF motion events notice answers for the source and its sensor.
    if (['camera.rtsp.enabled', 'camera.rtsp.protocol', 'camera.rtsp.analysis', 'camera.onvif.events',
      'camera.onvif.events_source', 'motion.sensor', 'person.sensor'].includes(s.key)) updateOnvifEventsRows();
    // The hints under the brightness sliders come and go with the
    // adaptive brightness switch (issue #343). After the gated sync, so
    // the curve rows the switch reveals are in place first.
    if (s.key === 'screen.adaptive_brightness') updateAdaptiveBrightnessRows();
    // The Celestial location status follows its source and entity, and
    // the GPS source brings its Location grant.
    if (s.key === 'screensaver.celestial_location' || s.key === 'screensaver.celestial_entity') {
      updateCelestialLocationRow();
    }
    if (s.key === 'screensaver.celestial_location' || s.key === 'screensaver.mode') {
      updateCelestialPermissionRows();
    }
    // The Ambient light row follows the reading's source (issue #911).
    if (s.key === 'screen.adaptive_use_entity' || s.key === 'screen.adaptive_light_entity') {
      updateAdaptiveBrightnessRows({ reprobe: true });
    }
    // The real-MAC status row and its field answer for the switch and the
    // typed address as they are now (issues #252, #300). After the gated
    // sync: the field is a hidden definition gated on the switch, which
    // the sync would take out of the card again if it ran second.
    if (s.key === 'esphome.real_mac' || s.key === 'esphome.mac_override') {
      await refreshRealMacNote();
    }
  };

  // The adaptive brightness curve (issue #742): one editor for its
  // settings, in Minimum brightness's row, as on the device. The other
  // three ends draw no row of their own; the editor's chips carry their
  // keys, so their live updates and search hits land on it.
  if (s.key === 'screen.adaptive_min_brightness') {
    return brightnessCurveRow(row, {
      showError: (message) => showRowError(row, message),
      clearError: () => clearRowError(row),
    });
  }
  if (['screen.adaptive_max_brightness', 'screen.adaptive_dark_lux',
    'screen.adaptive_bright_lux'].includes(s.key)) {
    return document.createDocumentFragment();
  }

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
      ? t('screensaverMediaSelected', {count: String(count)})
      : screensaverText('None selected. Pick on the device.');
    row.appendChild(val);
    return row;
  }

  // A color is picked, not typed: the row swatch opens the same picker
  // dialog the device draws. Every "r,g,b" setting ends in _color by
  // convention; the device UI keys off the same suffix.
  if (s.key.endsWith('_color')) {
    let button = swatch(s.value || '250,250,250', s.title, rgb => save(rgb));
    row.appendChild(button);
    row.updateSetting = () => {
      const next = swatch(s.value || '250,250,250', s.title, rgb => save(rgb));
      button.replaceWith(next);
      button = next;
      return true;
    };
    return row;
  }

  // An entity setting, mirroring the device's PickRow: the field shows the
  // stored entity and opens the entity picker, narrowed to what the setting
  // takes. A stored entity gone from Home Assistant gets a line in error.
  const entityRow = (spec, { allowClear = false, placeholder = null } = {}) => {
    const current = () => (state.settings || []).find((o) => o.key === s.key)?.value ?? s.value ?? '';
    const missing = document.createElement('div');
    missing.className = 'desc dp-missing';
    missing.textContent = haText('This entity is gone from Home Assistant. Choose another.');
    missing.hidden = true;
    row.querySelector('.info .name').after(missing);
    const field = pickField({
      spec, value: current(), placeholder,
      onClick: async () => {
        const out = await pickItem({ title: s.title, spec, selected: current() || null, allowClear });
        if (!out || (out.id ?? '') === current()) return;
        await save(out.id ?? '');
        field.setValue(current());
      },
    });
    field.el.addEventListener('dp-painted', (e) => { missing.hidden = !e.detail.missing; });
    // Once more now that someone listens: the first paint went unheard.
    field.repaint();
    bindUpdate(field.el, () => field.setValue(current()));
    row.classList.add('dp-field-row');
    row.appendChild(field.el);
    return field;
  };
  // Weather Mood's and the calendar's weather entity: weather only.
  if (s.key === 'screensaver.weather_entity' || s.key === 'calendar.weather_entity') {
    entityRow(entitySpec({ domains: ['weather'] }), { allowClear: true });
    return row;
  }
  // The Celestial screensaver's location entity: anything with a latitude
  // and longitude.
  if (s.key === 'screensaver.celestial_entity') {
    entityRow(entitySpec({ domains: ['person', 'device_tracker', 'zone'] }), { allowClear: true });
    return row;
  }
  // Adaptive brightness's light sensor entity (issue #911), mirroring the
  // device's row: light level sensors only, and once one is picked its
  // live reading stands in for the description.
  if (s.key === 'screen.adaptive_light_entity') {
    const desc = info.querySelector('.desc');
    const current = () => (state.settings || []).find((o) => o.key === s.key)?.value ?? s.value ?? '';
    const paint = () => {
      desc.textContent = current() ? entityLightReading() : s.description;
    };
    paint();
    const repaint = () => {
      if (row.isConnected) paint();
      else document.removeEventListener('ks-adaptivelight', repaint);
    };
    document.addEventListener('ks-adaptivelight', repaint);
    const field = entityRow(entitySpec({ deviceClass: 'illuminance' }), { allowClear: true });
    row.updateSetting = () => { paint(); field.setValue(current()); return true; };
    return row;
  }
  // The external motion sensor (issue #973), mirroring the device's row:
  // occupancy, motion and presence sensors only, and once one is picked
  // what it reads stands in for the description.
  if (s.key === 'motion.entity') {
    const desc = info.querySelector('.desc');
    const current = () => (state.settings || []).find((o) => o.key === s.key)?.value ?? s.value ?? '';
    const paint = () => {
      desc.textContent = current() ? externalMotionReading() : s.description;
    };
    paint();
    const repaint = () => {
      if (row.isConnected) paint();
      else document.removeEventListener('ks-externalmotion', repaint);
    };
    document.addEventListener('ks-externalmotion', repaint);
    probeExternalMotion();
    const field = entityRow(entitySpec({ deviceClass: 'occupancy' }), { allowClear: true });
    row.updateSetting = () => {
      probeExternalMotion(true);
      paint();
      field.setValue(current());
      return true;
    };
    return row;
  }
  // The Home Assistant sensor ONVIF motion events follow (issue #1098),
  // mirroring the device's row.
  if (s.key === 'camera.onvif.events_entity') {
    const current = () => (state.settings || []).find((o) => o.key === s.key)?.value ?? s.value ?? '';
    const field = entityRow(entitySpec({ deviceClass: 'occupancy' }), { allowClear: true });
    row.updateSetting = () => { field.setValue(current()); return true; };
    return row;
  }
  // The Home Assistant Dashboard screensaver's view and Now Playing's
  // chosen view are picked in the dashboard picker, mirroring the
  // device's row: the field shows the stored view and opens the picker.
  if (s.key === 'screensaver.dashboard_view' || s.key === 'sendspin.fullscreen_return_view') {
    // The live value: save() writes the confirmed pick into the cache.
    const current = () => (state.settings || []).find((o) => o.key === s.key)?.value ?? s.value ?? '';
    const missing = document.createElement('div');
    missing.className = 'desc dp-missing';
    missing.textContent = haText('This view is gone from Home Assistant. Choose another.');
    missing.hidden = true;
    row.querySelector('.info .name').after(missing);
    const field = dashboardField({
      value: current(),
      title: s.title,
      onPick: (path) => save(path),
    });
    field.el.addEventListener('dp-painted', (e) => { missing.hidden = !e.detail.missing; });
    // Once more now that someone listens: the first paint went unheard.
    field.repaint();
    bindUpdate(field.el, () => field.setValue(current()));
    row.classList.add('dp-field-row');
    row.appendChild(field.el);
    return row;
  }
  // The screensaver's media is browsed from Home Assistant, not typed, the
  // same picker the device offers, so the two stay in step.
  if (s.key === 'screensaver.media_id') {
    const val = document.createElement('span');
    val.className = 'device';
    val.style.cssText =
      'flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap';
    val.textContent = s.value || screensaverText('Not set');
    const btn = document.createElement('button');
    btn.className = 'btn-ghost'; btn.textContent = screensaverText('Browse');
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

  // Wake to screensaver, mirroring the device's row: the picks at rest in
  // a dropdown-style box that opens a checkbox dialog. Stored as a JSON
  // list of sources (issue #954).
  if (s.key === 'screensaver.screen_off_wake_to_screensaver') {
    const current = () => (state.settings || []).find((o) => o.key === s.key)?.value ?? s.value ?? '[]';
    const field = choiceBox(wakeSourcesText(decodeWakeSources(current())), async () => {
      // A powered-off panel takes no touches: Touch can only wake the black
      // screen that stands in for it.
      const value = (key) => (state.settings || []).find((o) => o.key === key)?.value;
      const touchReady = Number(value('screensaver.screen_off_minutes')) > 0
        && value('screensaver.screen_off_black') === true;
      const picked = await openWakeSourcesPicker(s.title, decodeWakeSources(current()), touchReady);
      if (!picked) return;
      field.setText(wakeSourcesText(picked));
      await save(JSON.stringify(WAKE_SOURCES.filter((source) => picked.has(source))));
      field.setText(wakeSourcesText(decodeWakeSources(current())));
    });
    bindUpdate(field.el, () => field.setText(wakeSourcesText(decodeWakeSources(current()))));
    row.classList.add('dp-field-row');
    row.appendChild(field.el);
    return row;
  }

  // Show system toast notifications, mirroring the device's row: the
  // toasts shown at rest in a dropdown-style box that opens a checkbox
  // dialog. Stored as a JSON list of the ones turned off.
  if (s.key === 'ui.toasts_hidden') {
    const current = () => (state.settings || []).find((o) => o.key === s.key)?.value ?? s.value ?? '[]';
    const field = choiceBox(toastsShownText(decodeToastsHidden(current())), async () => {
      const hidden = await openToastsPicker(s.title, decodeToastsHidden(current()));
      if (!hidden) return;
      field.setText(toastsShownText(hidden));
      await save(JSON.stringify(TOAST_SOURCES.filter((source) => hidden.has(source))));
      field.setText(toastsShownText(decodeToastsHidden(current())));
    });
    bindUpdate(field.el, () => field.setText(toastsShownText(decodeToastsHidden(current()))));
    row.classList.add('dp-field-row');
    row.appendChild(field.el);
    return row;
  }

  // The speakers the Now Playing pill offers, mirroring the device's row:
  // the picks at rest in a dropdown-style box that opens one picker over
  // Music Assistant's players and the Sonos rooms, a chip per source.
  // Each pick counts only for its own source's menu.
  if (s.key === 'sendspin.speaker_pill_players') {
    const spec = speakerPillSpec();
    const stored = () => {
      try {
        const value = (state.settings || []).find((o) => o.key === s.key)?.value;
        const list = JSON.parse(value ?? s.value ?? '[]');
        return Array.isArray(list) ? list.filter((id) => typeof id === 'string' && id) : [];
      } catch (_) { return []; }
    };
    // A pick the list lacks (not loaded yet, or away) reads its id.
    const text = () => {
      const ids = stored();
      if (!ids.length) return mediaText('All speakers');
      const items = cachedList(spec.key)?.items || [];
      return ids.map((id) => items.find((i) => i.id === id)?.name || id.slice(id.indexOf(':') + 1))
        .join(', ');
    };
    const field = choiceBox(text(), async () => {
      const ids = await pickItems({ title: s.title, spec, selected: stored() });
      if (!ids) return;
      await save(JSON.stringify(ids));
      field.setText(text());
    });
    onListLoaded(spec.key, field.el, () => field.setText(text()));
    if (!cachedList(spec.key)) loadList(spec);
    bindUpdate(field.el, () => field.setText(text()));
    row.classList.add('dp-field-row');
    row.appendChild(field.el);
    return row;
  }

  // A row that stands for another setting (linksTo): a plain row to it,
  // landing on its row the way a search result does. Mirrors the device.
  if (s.linksTo) {
    row.classList.add('setting-link');
    const chev = document.createElement('span');
    chev.className = 'chev';
    chev.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"'
      + ' stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
      + '<path d="m9 18 6-6-6-6"/></svg>';
    row.appendChild(chev);
    row.addEventListener('click', () => {
      const target = (state.settings || []).find((o) => o.key === s.linksTo);
      const tab = target && SEARCH_CATEGORY_TABS[target.category];
      if (tab) jumpToResult({ tab, key: target.key, sub: target.subpage });
    });
    return row;
  }

  // The kiosk menu's rows (issue #1194), picked and arranged in the shared
  // picker like the device's. The summary names the rows on.
  if (s.key === 'ui.drawer_items') {
    const value = () => (state.settings || []).find((o) => o.key === s.key)?.value ?? s.value;
    const val = document.createElement('span');
    val.className = 'device';
    val.style.cssText =
      'flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap';
    const paint = () => { val.textContent = drawerItemsText(value()); };
    paint();
    const btn = document.createElement('button');
    btn.className = 'btn-ghost'; btn.textContent = launcherText('Edit');
    btn.style.flex = 'none';
    btn.addEventListener('click', async () => {
      const remoteOn = (state.settings || []).find((o) => o.key === 'remote.enabled')?.value === true;
      const picked = await openDrawerItemsPicker(value(), remoteOn);
      if (picked == null) return;
      await save(picked);
      paint();
    });
    const controls = document.createElement('div');
    controls.style.cssText =
      'display:flex; gap:10px; align-items:center; min-width:0; max-width:60%; flex:0 1 auto';
    controls.append(val, btn);
    row.appendChild(controls);
    row.updateSetting = () => { paint(); return true; };
    return row;
  }

  // The launcher whitelist, mirroring the device's picker. The summary
  // renders from the labels cached in the setting; the picker asks the
  // device for the live app list.
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
    val.textContent = chosen.length ? chosen.map((a) => a.label).join(', ') : launcherText('None yet');
    const btn = document.createElement('button');
    btn.className = 'btn-ghost'; btn.textContent = launcherText('Edit');
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

  // The launcher's apps a locked kiosk offers (issue #1067), mirroring the
  // device's rows: a switch per launcher app, in the launcher's order.
  if (s.key === 'kiosk.allowed_apps') {
    const value = (key) => (state.settings || []).find((o) => o.key === key)?.value;
    let apps = [];
    try {
      if (value('launcher.enabled') === true) apps = JSON.parse(value('launcher.apps') || '[]') || [];
    } catch (_) {}
    apps = apps.filter((a) => a && typeof a.package === 'string' && a.package);
    if (!apps.length) {
      info.querySelector('.desc').textContent = kioskText('Add apps in Settings > App Launcher first.');
      return row;
    }
    const allowed = () => {
      try {
        const list = JSON.parse(value(s.key) ?? s.value ?? '[]');
        return new Set(Array.isArray(list) ? list : []);
      } catch (_) { return new Set(); }
    };
    const fragment = document.createDocumentFragment();
    for (const app of apps) {
      const appRow = document.createElement('div'); appRow.className = 'row';
      const appInfo = document.createElement('div'); appInfo.className = 'info';
      appInfo.innerHTML = `<div class="name"></div><div class="desc"></div>`;
      appInfo.querySelector('.name').textContent = app.label || app.package;
      appInfo.querySelector('.desc').textContent = app.package;
      const lbl = document.createElement('label'); lbl.className = 'switch';
      const cb = document.createElement('input'); cb.type = 'checkbox';
      const paint = () => { cb.checked = allowed().has(app.package); };
      paint();
      cb.addEventListener('change', async () => {
        const next = allowed();
        if (cb.checked) next.add(app.package); else next.delete(app.package);
        const picked = JSON.stringify(apps.map((a) => a.package).filter((p) => next.has(p)));
        try {
          const res = await api('/api/settings', { method: 'PATCH', body: JSON.stringify({ [s.key]: picked }) });
          const out = await res.json().catch(() => null);
          if (!res.ok || out?.ok !== true || out.rejected?.includes(s.key)) {
            throw new Error(out?.errors?.[s.key] || out?.error
              || 'Could not save this setting. Try again.');
          }
        } catch (error) {
          paint();
          showRowError(appRow, error?.message || 'Could not save this setting. Try again.', null);
          return;
        }
        clearRowError(appRow);
        const cached = (state.settings || []).find((o) => o.key === s.key);
        if (cached) cached.value = picked;
        paint();
      });
      const sl = document.createElement('span'); sl.className = 'slider';
      lbl.append(cb, sl);
      appRow.append(appInfo, lbl);
      // Every app's row repaints when the list changes elsewhere.
      appRow.dataset.key = s.key;
      appRow.updateSetting = () => { paint(); return true; };
      fragment.appendChild(appRow);
    }
    return fragment;
  }

  if (s.key === 'esphome.excluded_entities') {
    const chosen = () => {
      try { return JSON.parse(s.value || '[]'); } catch (_) { return []; }
    };
    const summary = document.createElement('span');
    summary.className = 'device';
    const refresh = () => {
      const count = new Set(chosen()).size;
      summary.textContent = count ? t('esphomeExcludedCount', {count}) : esphomeText('All available entities exposed');
    };
    refresh();
    const button = document.createElement('button');
    button.className = 'btn-ghost';
    button.textContent = esphomeText('Edit');
    row.updateSetting = () => { refresh(); return true; };
    row.saveExclusions = async (picked) => {
      try {
        await save(JSON.stringify(picked));
        refresh();
      } catch (_) {
        showRowError(row, esphomeText('Could not save exclusions. Try again.'));
      }
    };
    button.addEventListener('click', async () => {
      const picked = await openEspHomeEntityPicker(chosen());
      if (picked === null) return;
      const current = document.querySelector('[data-key="esphome.excluded_entities"]') || row;
      await current.saveExclusions(picked);
    });
    row.append(summary, button);
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
    val.textContent = chosen.length ? chosen.map((n) => n.name).join(', ') : screensaverText(immichNamed.empty);
    const btn = document.createElement('button');
    btn.className = 'btn-ghost'; btn.textContent = screensaverText('Edit');
    btn.style.flex = 'none';
    btn.addEventListener('click', async () => {
      const picked = await openImmichNamesPicker({
        title: s.title, command: immichNamed.command, current: chosen, none: screensaverText(immichNamed.none),
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
    const label = (m) => labels[m] || (m?.startsWith('plugin:') ? screensaverText('Unavailable plugin screensaver') : (m ? m[0].toUpperCase() + m.slice(1) : m));

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
      timeTitle.textContent = screensaverText('Time');
      const time = timeBox({ title: screensaverText('Time'), value: start.at || '19:00',
        full: true, onPick: () => {} });
      timeWrap.append(timeTitle, time.el);

      const choices = [...new Set([...modes, ...(start.mode?.startsWith('plugin:') ? [start.mode] : [])])];
      const modeSel = cameraSelectField(screensaverText('Screensaver'),
        choices.map((m) => ({ value: m, label: label(m) })),
        choices.includes(start.mode) ? start.mode : ((modeDef && modeDef.value) || 'clock'));

      // The same switch as the main screensaver page: off, the entry
      // follows the Screensaver brightness setting outside the schedule
      // (which may itself be off, leaving the panel to the device or
      // adaptive brightness); on, the slider below is this entry's own
      // level.
      const hasLevel = typeof start.brightness === 'number';
      const brightOn = cameraToggle(screensaverText('Screensaver brightness'), hasLevel,
        hasLevel ? screensaverText('Applies to every mode except Black.')
          : screensaverText('Follows the Screensaver brightness setting.'));
      const brightWrap = document.createElement('label');
      brightWrap.className = 'form-field';
      const brightTitle = document.createElement('span');
      brightTitle.className = 'desc';
      brightTitle.textContent = screensaverText('Brightness');
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
          ? screensaverText('Applies to every mode except Black.')
          : screensaverText('Follows the Screensaver brightness setting.');
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
        ? screensaverText('Follows the Turn screen off after setting.')
        : minutes === 0
          ? screensaverText('Keeps the screen on during these hours.')
          : screensaverText('Powers down the display once the screensaver has run this '
            + 'long. Requires Device Administrator permission.');
      const offOn = cameraToggle(screensaverText('Turn screen off after'), hasOff,
        offDesc(hasOff, hasOff ? start.screen_off : 0));
      const offWrap = document.createElement('label');
      offWrap.className = 'form-field';
      const offTitle = document.createElement('span');
      offTitle.className = 'desc';
      offTitle.textContent = screensaverText('Turn screen off after');
      const offLine = document.createElement('div');
      offLine.style.cssText = 'display:flex; align-items:center; gap:10px;';
      const offRng = document.createElement('input');
      offRng.type = 'range'; offRng.className = 'range';
      offRng.min = '0'; offRng.max = '60'; offRng.step = '1';
      offRng.value = String(hasOff ? Math.min(60, Math.max(0, start.screen_off)) : globalOff);
      offRng.style.cssText = 'flex:1;';
      const offLabel = document.createElement('span');
      offLabel.className = 'device';
      offLabel.style.cssText = 'width:52px; text-align:right; flex-shrink:0;';
      const offPaint = () => {
        offLabel.textContent = +offRng.value === 0 ? screensaverText('Never') : t('haMinutes', {minutes: offRng.value});
        offOn.wrap.querySelector('.desc').textContent =
          offDesc(offOn.input.checked, +offRng.value);
      };
      offPaint();
      let offBefore = +offRng.value;
      offRng.addEventListener('input', offPaint);
      // Leaving 0 gets the same warning as the slider outside the schedule.
      offRng.addEventListener('change', async () => {
        const next = +offRng.value;
        if (offBefore === 0 && next > 0 &&
            !state.settings.some(s => s.key === 'screensaver.screen_off_black' && s.value === true)) {
          const pick = await localizedMessageBox({
            titleId: 'screensaverWarningTitle', messageId: 'screensaverScreenOffWarning',
            buttons: [{id:'commonCancel', value:'Cancel'}, {id:'screensaverScreenOffProceed', value:'Proceed'}],
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
        [{ value: '', label: screensaverText('Default') }, { value: 'on', label: screensaverText('On') },
          { value: 'off', label: screensaverText('Off') }],
        (typeof value === 'boolean') ? (value ? 'on' : 'off') : '');
      // No camera means no motion detection to override, same as the
      // Dismiss on motion switch.
      const camOn = ((state.settings || []).find((x) => x.key === 'camera.enabled') || {}).value === true
        && state.cameraPresent !== false;
      const motion = overrideField(screensaverText('Dismiss on motion'), start.motion);
      motion.select.disabled = !camOn;
      if (!camOn) {
        motion.select.title =
          screensaverText('Requires the camera. Turn it on in the Camera settings first.');
      }
      // Motion keeps precedence inside an entry too: On here with motion
      // On above still wakes on motion.
      const face = overrideField(screensaverText('Dismiss on face'), start.face);
      const faceOk = camOn
        && !(state.visionSupport && state.visionSupport.faces === false);
      face.select.disabled = !faceOk;
      if (!camOn) {
        face.select.title =
          screensaverText('Requires the camera. Turn it on in the Camera settings first.');
      } else if (!faceOk) {
        face.select.title =
          screensaverText(state.visionSupport.hint || 'Not available on this device.');
      }
      // The proximity override is offered wherever the sensor is not
      // known to be missing (never disabled on a guess, like the switch),
      // and the person override only where the Person Detection page
      // exists at all (a Portal's sensor, hidden everywhere else).
      const proximity = overrideField(screensaverText('Dismiss on proximity'), start.proximity);
      const prox = state.proximitySupport;
      if (prox && prox.supported === false) {
        proximity.select.disabled = true;
        proximity.select.title = screensaverText(prox.hint || 'Not available on this device.');
      }
      const personDef = (state.settings || [])
        .find((x) => x.key === 'screensaver.dismiss_on_person');
      const personShown = !!personDef && !personDef.hidden;
      const person = overrideField(screensaverText('Dismiss on person'), start.person);
      const widgets = overrideField(screensaverText('Widgets'), start.widgets);
      const glance = overrideField(screensaverText('At a glance'), start.glance);
      const nowPlaying = overrideField(screensaverText('Show Now Playing next to the screensaver'), start.now_playing);
      const nowPlayingHint = document.createElement('span');
      nowPlayingHint.className = 'desc';
      nowPlayingHint.textContent = screensaverText('Default follows the global layout. On uses a '
        + 'shared layout when Now Playing is enabled. Off hides Now Playing during these hours.');
      nowPlaying.wrap.append(nowPlayingHint);

      body.append(timeWrap, modeSel.wrap, brightOn.wrap, brightWrap,
        offOn.wrap, offWrap, motion.wrap, face.wrap, proximity.wrap);
      if (personShown) body.append(person.wrap);
      body.append(widgets.wrap, glance.wrap, nowPlaying.wrap);

      return cameraEditor({
        title: existing ? String(start.at) : screensaverText('Add time'),
        width: 460,
        body,
        save: async () => {
          if (!time.value) return { ok: false, error: screensaverText('Pick a time.') };
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
            ['widgets', widgets], ['glance', glance], ['now_playing', nowPlaying]]) {
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
        parts.push(t('screensaverBrightnessPercent', {percent: String(Math.round(e.brightness * 100))}));
      }
      if (typeof e.motion === 'boolean') {
        parts.push(t(e.motion ? 'screensaverSummaryMotionOn' : 'screensaverSummaryMotionOff'));
      }
      if (typeof e.face === 'boolean') {
        parts.push(t(e.face ? 'screensaverSummaryFaceOn' : 'screensaverSummaryFaceOff'));
      }
      if (typeof e.proximity === 'boolean') {
        parts.push(t(e.proximity ? 'screensaverSummaryProximityOn' : 'screensaverSummaryProximityOff'));
      }
      if (typeof e.person === 'boolean') {
        parts.push(t(e.person ? 'screensaverSummaryPersonOn' : 'screensaverSummaryPersonOff'));
      }
      if (typeof e.widgets === 'boolean') {
        parts.push(t(e.widgets ? 'screensaverSummaryWidgetsOn' : 'screensaverSummaryWidgetsOff'));
      }
      if (typeof e.glance === 'boolean') {
        parts.push(t(e.glance ? 'screensaverSummaryGlanceOn' : 'screensaverSummaryGlanceOff'));
      }
      if (typeof e.now_playing === 'boolean') {
        parts.push(t(e.now_playing ? 'screensaverSummaryNowPlayingOn' : 'screensaverSummaryNowPlayingOff'));
      }
      if (typeof e.screen_off === 'number') {
        parts.push(e.screen_off <= 0 ? screensaverText('Screen off never')
          : t('screensaverScreenOffAfter', {minutes: String(Math.round(e.screen_off))}));
      }
      return parts.join(' · ');
    };

    const entryRow = (e) => cameraListRow(
      String(e.at), summary(e),
      [
        cameraAction(screensaverText('Delete'), () => {
          entries = entries.filter((o) => o !== e);
          persist();
        }, false, 'delete'),
      ],
      { icon: 'clock', onClick: () => editEntry(e) },
    );

    // The add row is the last row of the card, the whole row the button,
    // mirrored on the device.
    const addRow = () => cameraListRow(screensaverText('Add time'),
      screensaverText('A screensaver from that time on.'), [],
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
    const CORNERS = [['top_left', screensaverText('Top left')], ['top_right', screensaverText('Top right')],
      ['bottom_left', screensaverText('Bottom left')], ['bottom_right', screensaverText('Bottom right')]];
    const TYPES = [['clock', screensaverText('Small clock')], ['weather', screensaverText('Weather')],
      ['forecast', screensaverText('Weather forecast')],
      ['battery', screensaverText('Battery')], ['entity', screensaverText('Entity')],
      ['alarm', t('alarmsNextWidget')], ['calendar', t('calendarUpNext')]];
    const DEFAULTS = {
      clock: { color: '250,250,250', scale: 0, font: 'default',
        font_weight: 'default', h24: false, ampm: true, date: false },
      weather: { entity: '', name: '', label: '', color: '250,250,250',
        scale: 0, font: 'default', font_weight: 'default',
        feels_like: false, feels_like_only: false, location: true,
        forecast: true, high_low: true, humidity: true, wind: true,
        visibility: true, colored_icons: true },
      forecast: { entity: '', name: '', color: '250,250,250', scale: 0,
        font: 'default', font_weight: 'default', days: 5, today: true,
        colored_icons: true },
      battery: { color: '250,250,250', scale: 0, font: 'default',
        font_weight: 'default', percent: true, low: false },
      entity: { entity: '', name: '', label: '', attribute: '', show_states: '',
        show_name: true, show_icon: true, color: '250,250,250', scale: 0, font: 'default',
        font_weight: 'default' },
      alarm: { color: '250,250,250', scale: 0, font: 'default',
        font_weight: 'default' },
      calendar: { color: '250,250,250', scale: 0, font: 'default',
        font_weight: 'default', count: 3, days: 1, dots: false },
    };
    // The typeface and weight pickers, the clock screensaver's vocabulary
    // (kept with definitions.dart) behind a Default that follows the
    // Global font family and Global font weight rows outside the modal.
    const FONTS = [['default', screensaverText('Default')], ['rubik', 'Rubik'],
      ['nunito', 'Nunito'], ['inter', 'Inter'], ['oswald', 'Oswald'], ['roboto_slab', 'Roboto Slab'], ['system', screensaverText('System')],
      ['serif', screensaverText('Serif')], ['condensed', screensaverText('Condensed')],
      ['monospace', screensaverText('Monospace')], ['casual', screensaverText('Casual')],
      ['cursive', screensaverText('Cursive')], ['lcd', 'LCD']];
    const WEIGHTS = [['default', screensaverText('Default')], ['light', screensaverText('Light')],
      ['regular', screensaverText('Regular')], ['medium', screensaverText('Medium')], ['bold', screensaverText('Bold')],
      ['black', t('screensaverFontBlack')]];
    const pickOf = (list, value) =>
      list.some(([v]) => v === value) ? value : 'default';
    // The per-widget scale, a percent offset from the size the Global
    // widget scaling slider gives it: -50 halves the widget, 50 grows it
    // half again. Kept with screensaver_widgets.dart.
    const SCALE_MIN = -50;
    const SCALE_MAX = 50;
    const scaleOf = (config) => {
      const n = Number(config.scale);
      if (!Number.isFinite(n)) return 0;
      return Math.min(Math.max(Math.round(n), SCALE_MIN), SCALE_MAX);
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
        ? screensaverText('Hidden in Digital Clock and Camera Streams screensaver modes.')
        : screensaverText('Hidden in the Camera Streams screensaver mode.');
      const cornerSel = cameraSelectField(screensaverText('Corner'),
        free.map(([value, label]) => ({ value, label })),
        existing?.position || free[0][0]);
      const typeSel = cameraSelectField(screensaverText('Widget'),
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
        title.textContent = screensaverText('Color');
        const input = swatch(config.color || '250,250,250', screensaverText('Color'), () => {});
        wrap.append(title, input);
        return { wrap, input };
      };
      // Every type carries its own scale, under the color the way the
      // device dialog orders them.
      const scaleField = () => {
        const wrap = document.createElement('label');
        wrap.className = 'form-field';
        const title = document.createElement('span');
        title.className = 'desc';
        title.textContent = screensaverText('Scale');
        const hint = document.createElement('span');
        hint.className = 'desc';
        hint.textContent = screensaverText('Scale this widget size to better fit your screen.');
        const line = document.createElement('div');
        line.style.cssText = 'display:flex; align-items:center; gap:10px;';
        const input = document.createElement('input');
        input.type = 'range'; input.className = 'range';
        input.min = String(SCALE_MIN); input.max = String(SCALE_MAX);
        input.step = '5';
        input.value = String(scaleOf(config));
        input.style.cssText = 'flex:1;';
        const pct = document.createElement('span');
        pct.className = 'device';
        pct.style.cssText = 'width:48px; text-align:right; flex-shrink:0;';
        const paint = () => {
          const v = Number(input.value);
          pct.textContent = (v > 0 ? '+' : '') + v + '%';
        };
        input.addEventListener('input', paint);
        paint();
        line.append(input, pct);
        wrap.append(title, line, hint);
        return { wrap, input };
      };
      const renderTypeBlock = () => {
        note.textContent = noteFor(type);
        typeBlock.innerHTML = '';
        refs = { color: colorField(), scale: scaleField(),
          font: cameraSelectField(screensaverText('Font family'),
            FONTS.map(([value, label]) => ({ value, label })),
            pickOf(FONTS, config.font)),
          weight: cameraSelectField(screensaverText('Font weight'),
            WEIGHTS.map(([value, label]) => ({ value, label })),
            pickOf(WEIGHTS, config.font_weight)) };
        if (type === 'clock') {
          refs.h24 = cameraToggle(screensaverText('24-hour clock'),
            config.h24 === true, screensaverText('Show a 24-hour time instead of AM/PM.'));
          // On unless switched off: entries saved before the switch
          // existed carry no key. Only a 12-hour time has a period.
          refs.ampm = cameraToggle(screensaverText('Show AM/PM'),
            config.ampm !== false, screensaverText('Add AM or PM after the time.'));
          const syncAmPm = () => {
            refs.ampm.wrap.style.display = refs.h24.input.checked ? 'none' : '';
          };
          refs.h24.input.addEventListener('change', syncAmPm);
          syncAmPm();
          refs.date = cameraToggle(screensaverText('Show date'),
            config.date === true, screensaverText('Add a short date under the clock.'));
          typeBlock.append(refs.color.wrap, refs.scale.wrap, refs.font.wrap,
            refs.weight.wrap, refs.h24.wrap, refs.ampm.wrap, refs.date.wrap);
          return;
        }
        if (type === 'battery') {
          refs.percent = cameraToggle(screensaverText('Show percentage'),
            config.percent !== false, screensaverText('The charge beside the icon.'));
          refs.low = cameraToggle(screensaverText('Only when low'),
            config.low === true,
            screensaverText('Stay hidden until the charge drops to 20 percent.'));
          typeBlock.append(refs.color.wrap, refs.scale.wrap, refs.font.wrap,
            refs.weight.wrap, refs.percent.wrap, refs.low.wrap);
          return;
        }
        // Up next: how many coming events it lists, how many days ahead and
        // whether the pictures give way to the colored dots.
        if (type === 'calendar') {
          const count = document.createElement('select');
          count.className = 'field';
          for (let n = 1; n <= 5; n++) {
            const opt = document.createElement('option');
            opt.value = String(n);
            opt.textContent = String(n);
            opt.selected = n === (Number(config.count) || 3);
            count.appendChild(opt);
          }
          refs.count = count;
          const countField = document.createElement('label');
          countField.className = 'form-field';
          const countLabel = document.createElement('span');
          countLabel.className = 'desc';
          countLabel.textContent = t('calendarWidgetEvents');
          countField.append(countLabel, count);
          // How far ahead it looks, the device's upNextDayOptions.
          const days = document.createElement('select');
          days.className = 'field';
          const picked = [1, 2, 7].includes(Number(config.days)) ? Number(config.days) : 1;
          for (const [n, label] of [[1, t('calendarToday')],
            [2, t('calendarWidgetTomorrow')], [7, t('calendarWidgetWeek')]]) {
            const opt = document.createElement('option');
            opt.value = String(n);
            opt.textContent = label;
            opt.selected = n === picked;
            days.appendChild(opt);
          }
          refs.days = days;
          const daysField = document.createElement('label');
          daysField.className = 'form-field';
          const daysLabel = document.createElement('span');
          daysLabel.className = 'desc';
          daysLabel.textContent = t('calendarWidgetDays');
          daysField.append(daysLabel, days);
          refs.dots = cameraToggle(t('calendarWidgetDots'), config.dots === true,
            t('calendarWidgetDotsHint'));
          typeBlock.append(refs.color.wrap, refs.scale.wrap, refs.font.wrap,
            refs.weight.wrap, countField, daysField, refs.dots.wrap);
          return;
        }
        // Weather forecast: the Weather widget's entity picker, then how
        // many days it lists (the device's forecastDayOptions) and whether
        // the list starts with today.
        if (type === 'forecast') {
          const spec = entitySpec({ domains: ['weather'] });
          const field = pickField({
            spec, value: config.entity || '',
            onClick: async () => {
              const out = await pickItem({ title: screensaverText('Weather entity'), spec,
                selected: config.entity || null });
              if (!out?.id) return;
              config.entity = out.id;
              config.name = cachedList(spec.key)?.items.find((i) => i.id === out.id)?.name || out.id;
              field.setValue(out.id);
            },
          });
          refs.entity = { wrap: formField(screensaverText('Weather entity'), field.el) };
          const days = document.createElement('select');
          days.className = 'field';
          const picked = [3, 5, 7].includes(Number(config.days)) ? Number(config.days) : 5;
          for (const n of [3, 5, 7]) {
            const opt = document.createElement('option');
            opt.value = String(n);
            opt.textContent = String(n);
            opt.selected = n === picked;
            days.appendChild(opt);
          }
          refs.days = days;
          const daysField = document.createElement('label');
          daysField.className = 'form-field';
          const daysLabel = document.createElement('span');
          daysLabel.className = 'desc';
          daysLabel.textContent = screensaverText('Days shown');
          daysField.append(daysLabel, days);
          refs.today = cameraToggle(screensaverText('Include today'),
            config.today !== false, screensaverText("Start the list with today's forecast."));
          refs.colored = cameraToggle(screensaverText('Colored icons'),
            config.colored_icons !== false, screensaverText('Show the weather icons in their own colors.'));
          typeBlock.append(refs.entity.wrap, refs.color.wrap, refs.scale.wrap,
            refs.font.wrap, refs.weight.wrap, daysField, refs.today.wrap,
            refs.colored.wrap);
          return;
        }
        // The next alarm: nothing of its own, the look every widget has.
        if (type === 'alarm') {
          typeBlock.append(refs.color.wrap, refs.scale.wrap, refs.font.wrap,
            refs.weight.wrap);
          return;
        }
        if (type === 'entity') {
          // The entity everything is read from, picked by search the way
          // the At a Glance row's are; the friendly name is cached in the
          // config so both editors can show it without a round trip.
          const spec = entitySpec();
          const valueBox = choiceBox(config.attribute || screensaverText('State'), async () => {
            if (!config.entity) return;
            const picked = await pickEntityValue({ entityId: config.entity,
              current: config.attribute || '' });
            if (picked == null) return;
            config.attribute = picked;
            valueBox.setText(picked || screensaverText('State'));
          });
          valueBox.el.disabled = !config.entity;
          const entityField = pickField({
            spec, value: config.entity || '',
            onClick: async () => {
              const out = await pickItem({ title: screensaverText('Entity'), spec,
                selected: config.entity || null });
              if (!out?.id) return;
              // Another entity has other attributes: back to its state.
              if (out.id !== config.entity) {
                config.attribute = '';
                valueBox.setText(screensaverText('State'));
              }
              config.entity = out.id;
              config.name = cachedList(spec.key)?.items.find((i) => i.id === out.id)?.name || out.id;
              entityField.setValue(out.id);
              refs.label.input.placeholder = config.name;
              valueBox.el.disabled = false;
            },
          });
          refs.entity = { wrap: formField(screensaverText('Entity'), entityField.el) };
          // What the widget displays: the state (the default) or one of
          // the entity's attributes, from the value step.
          refs.attribute = { wrap: formField(screensaverText('Displayed value'), valueBox.el),
            select: { get value() { return config.attribute || ''; } } };
          // Compared with the displayed value, so the list follows
          // whatever that shows (issue #1066).
          refs.states = (() => {
            const wrap = document.createElement('label');
            wrap.className = 'form-field';
            const title = document.createElement('span');
            title.className = 'desc';
            title.textContent = screensaverText('Visible states');
            const input = document.createElement('input');
            input.className = 'field';
            input.type = 'text';
            input.value = config.show_states || '';
            input.style.maxWidth = 'none';
            const hint = document.createElement('span');
            hint.className = 'desc';
            hint.textContent = screensaverText('Show the widget only when its value is one of these, separated by commas. Leave empty to always show it.');
            wrap.append(title, hint, input);
            return { wrap, input };
          })();
          refs.label = (() => {
            const wrap = document.createElement('label');
            wrap.className = 'form-field';
            const title = document.createElement('span');
            title.className = 'desc';
            title.textContent = screensaverText('Name');
            const input = document.createElement('input');
            input.className = 'field';
            input.type = 'text';
            input.placeholder = config.name
              || t('screensaverOverlayNameHelp');
            input.value = config.label || '';
            input.style.maxWidth = 'none';
            wrap.append(title, input);
            return { wrap, input };
          })();
          refs.showName = cameraToggle(screensaverText('Show name'),
            config.show_name !== false, screensaverText('The name under the value.'));
          refs.showIcon = cameraToggle(screensaverText('Show icon'),
            config.show_icon !== false, screensaverText('The icon beside the value.'));
          typeBlock.append(refs.entity.wrap, refs.label.wrap,
            refs.attribute.wrap, refs.states.wrap, refs.color.wrap, refs.scale.wrap,
            refs.font.wrap, refs.weight.wrap, refs.showName.wrap, refs.showIcon.wrap);
          return;
        }
        // Weather: the entity everything is read from, then the line
        // toggles. The temperature always shows; each other line also
        // needs the entity to actually carry the reading.
        {
          const spec = entitySpec({ domains: ['weather'] });
          const field = pickField({
            spec, value: config.entity || '',
            onClick: async () => {
              const out = await pickItem({ title: screensaverText('Weather entity'), spec,
                selected: config.entity || null });
              if (!out?.id) return;
              config.entity = out.id;
              config.name = cachedList(spec.key)?.items.find((i) => i.id === out.id)?.name || out.id;
              field.setValue(out.id);
            },
          });
          refs.entity = { wrap: formField(screensaverText('Weather entity'), field.el),
            select: {
              get value() { return config.entity || ''; },
              get selectedOptions() { return [{ textContent: config.name || config.entity }]; },
            } };
        }
        // Weather entities carry no city attribute, so the place shown
        // over the temperature is named by hand.
        refs.label = (() => {
          const wrap = document.createElement('label');
          wrap.className = 'form-field';
          const title = document.createElement('span');
          title.className = 'desc';
          title.textContent = screensaverText('Location name');
          const input = document.createElement('input');
          input.className = 'field';
          input.type = 'text';
          input.placeholder = t('screensaverOverlayLocationHelp');
          input.value = config.label || '';
          input.style.maxWidth = 'none';
          wrap.append(title, input);
          return { wrap, input };
        })();
        refs.location = cameraToggle(screensaverText('Location'),
          config.location === true, screensaverText("The place's name over the temperature."));
        refs.feelsLike = cameraToggle(screensaverText('Feels like'),
          config.feels_like === true,
          screensaverText('Show the apparent temperature on a labeled line below the actual temperature.'));
        refs.feelsLikeOnly = cameraToggle(screensaverText('Feels like only'),
          config.feels_like_only === true,
          screensaverText("Show the apparent temperature with a Feels like label instead of the actual temperature."));
        refs.forecast = cameraToggle(screensaverText('Forecast'),
          config.forecast === true, screensaverText('The conditions, with a matching icon.'));
        refs.highLow = cameraToggle(screensaverText('High and low'),
          config.high_low === true, screensaverText("Today's high and low temperatures."));
        refs.humidity = cameraToggle(screensaverText('Humidity'), config.humidity === true);
        refs.wind = cameraToggle(screensaverText('Wind speed'), config.wind === true);
        refs.visibility = cameraToggle(screensaverText('Visibility'), config.visibility === true);
        refs.colored = cameraToggle(screensaverText('Colored icons'),
          config.colored_icons !== false, screensaverText('Show the weather icons in their own colors.'));
        typeBlock.append(refs.entity.wrap, refs.label.wrap, refs.color.wrap,
          refs.scale.wrap, refs.font.wrap, refs.weight.wrap,
          refs.location.wrap, refs.feelsLike.wrap, refs.feelsLikeOnly.wrap,
          refs.forecast.wrap, refs.highLow.wrap, refs.humidity.wrap,
          refs.wind.wrap, refs.visibility.wrap, refs.colored.wrap);
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
          const scale = scaleOf({ scale: refs.scale.input.value });
          const font = pickOf(FONTS, refs.font.select.value);
          const font_weight = pickOf(WEIGHTS, refs.weight.select.value);
          let entryConfig;
          if (type === 'clock') {
            entryConfig = { color, scale, font, font_weight,
              h24: refs.h24.input.checked, ampm: refs.ampm.input.checked,
              date: refs.date.input.checked };
          } else if (type === 'battery') {
            entryConfig = { color, scale, font, font_weight,
              percent: refs.percent.input.checked,
              low: refs.low.input.checked };
          } else if (type === 'forecast') {
            if (!config.entity) return { ok: false, error: screensaverText('Pick a weather entity.') };
            entryConfig = { entity: config.entity,
              name: config.name || config.entity, color, scale, font,
              font_weight, days: Number(refs.days.value) || 5,
              today: refs.today.input.checked,
              colored_icons: refs.colored.input.checked };
          } else if (type === 'alarm') {
            entryConfig = { color, scale, font, font_weight };
          } else if (type === 'calendar') {
            entryConfig = { color, scale, font, font_weight,
              count: Number(refs.count?.value) || 3,
              days: Number(refs.days?.value) || 1,
              dots: refs.dots.input.checked };
          } else if (type === 'entity') {
            if (!config.entity) return { ok: false, error: screensaverText('Pick an entity.') };
            entryConfig = { entity: config.entity,
              name: config.name || config.entity,
              label: refs.label.input.value.trim(),
              attribute: refs.attribute.select.value,
              show_states: refs.states.input.value.trim(),
              show_name: refs.showName.input.checked,
              show_icon: refs.showIcon.input.checked, color, scale, font,
              font_weight };
          } else {
            const entity = refs.entity.select.value;
            if (!entity) return { ok: false, error: screensaverText('Pick a weather entity.') };
            const option = refs.entity.select.selectedOptions[0];
            entryConfig = { entity,
              name: option ? option.textContent : entity,
              label: refs.label.input.value.trim(), color, scale, font,
              font_weight,
              feels_like: refs.feelsLike.input.checked,
              feels_like_only: refs.feelsLikeOnly.input.checked,
              location: refs.location.input.checked,
              forecast: refs.forecast.input.checked,
              high_low: refs.highLow.input.checked,
              humidity: refs.humidity.input.checked,
              wind: refs.wind.input.checked,
              visibility: refs.visibility.input.checked,
              colored_icons: refs.colored.input.checked };
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
        cameraAction(screensaverText('Delete'), () => {
          entries = entries.filter((o) => o !== e);
          persist();
        }, false, 'delete'),
      ],
      {
        icon: ['weather', 'forecast', 'battery', 'entity', 'alarm', 'calendar'].includes(e.type)
          ? e.type : 'clock',
        onClick: () => editWidget(e),
      },
    );

    // The add row is the last row of the card, the whole row the button,
    // mirrored on the device. Every corner taken means nothing left to
    // add: the row stays, disabled, rather than disappearing.
    const addRow = () => cameraListRow(screensaverText('Add widget'),
      screensaverText('A small clock, the weather, the battery or an entity in a corner.'), [],
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

  // At a Glance, mirroring the device's rows: the picks in order under the
  // Entities heading, each with up, down and remove (a click edits its
  // name and displayed value), then Add entities, which opens the entity
  // picker for several. The card holds just the list, like Views to rotate.
  if (s.key === 'screensaver.glance_entities') {
    let chosen = [];
    try { chosen = JSON.parse(s.value || '[]') || []; } catch (_) { chosen = []; }
    if (!Array.isArray(chosen)) chosen = [];
    const list = document.createElement('div');
    list.className = 'ep-pick-list';
    list.dataset.key = s.key;
    const persist = async () => {
      paint();
      await api('/api/settings', { method: 'PATCH', body: JSON.stringify({
        'screensaver.glance_entities': JSON.stringify(chosen),
      }) });
    };
    const paint = () => {
      list.replaceChildren();
      chosen.forEach((entity, index) => {
        const move = (delta) => {
          const to = index + delta;
          if (to < 0 || to >= chosen.length) return;
          chosen.splice(to, 0, chosen.splice(index, 1)[0]);
          persist();
        };
        const up = cameraAction(screensaverText('Move up'), () => move(-1), false, 'up', index === 0);
        const down = cameraAction(screensaverText('Move down'), () => move(1), false, 'down',
          index === chosen.length - 1);
        const remove = cameraAction(screensaverText('Remove'), () => {
          chosen.splice(index, 1);
          persist();
        }, false, 'delete');
        list.appendChild(pickListRow({
          value: entity.entity_id,
          name: entity.custom_name || entity.name || null,
          detail: entity.attribute || null,
          trailing: [up, down, remove],
          onClick: async () => { if (await glanceEntityEditor(entity)) persist(); },
        }));
      });
      if (chosen.length < GLANCE_MAX) {
        const add = document.createElement('button');
        add.className = 'dp-add-row';
        add.type = 'button';
        add.textContent = haText('Add entities');
        add.addEventListener('click', async () => {
          const ids = await pickItems({ title: s.title, spec: entitySpec(),
            selected: chosen.map((e) => e.entity_id), max: GLANCE_MAX });
          if (!ids) return;
          // Kept picks keep their own name and value; new ones start plain.
          chosen = ids.map((id) => chosen.find((e) => e.entity_id === id)
            || { entity_id: id,
              name: cachedList('entities')?.items.find((i) => i.id === id)?.name || id });
          persist();
        });
        list.appendChild(add);
      }
    };
    paint();
    loadEntityList();
    return list;
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
      return t(n === 1 ? 'screensaverMediaOneCamera' : 'screensaverMediaCameras', {count: String(n)});
    };
    const build = () => {
      if (!views) return [];
      if (!views.length) {
        return [readOnlyRow(screensaverText('No camera view has cameras yet'),
          screensaverText('Add one under Camera Streams.'), '')];
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
          t('screensaverMediaPosition', {index: String(index + 1), cameras: cameras(view)}), [
            cameraAction(screensaverText('Move up'), () => move(-1), false, 'up', index === 0),
            cameraAction(screensaverText('Move down'), () => move(1), false, 'down',
              index === chosen.length - 1),
            cameraAction(screensaverText('Remove'), () => {
              chosen = chosen.filter((x) => x !== id);
              repaint();
              save();
            }, false, 'delete'),
          ]));
      });
      for (const view of views) {
        if (chosen.includes(view.id)) continue;
        rows.push(cameraListRow(view.name, cameras(view), [
          cameraAction(screensaverText('Add'), () => {
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
        note.textContent = t('screensaverMediaCached', {count: String(d.items ?? 0), size: fmt});
      } catch (_) { note.textContent = ''; }
    })();
    return row;
  }

  // A time of day is picked, not typed: the control box shows the value
  // and opens the time picker dialog, the same one the device draws.
  if (s.key === 'ha.theme_dark_at' || s.key === 'ha.theme_light_at'
    || s.key === 'android_update.window_start'
    || s.key === 'android_update.window_end') {
    const box = timeBox({ title: s.title, value: s.value || '', onPick: v => save(v) });
    row.appendChild(box.el);
    bindUpdate(box.el, () => box.set(s.value));
    return row;
  }

  // A filter date is picked off a calendar, not typed: the control box
  // shows the day and opens the date picker, the same one the device
  // draws. Empty is the open end the placeholder names (issue #383).
  if (s.key === 'screensaver.immich_taken_from'
    || s.key === 'screensaver.immich_taken_to') {
    const box = dateBox({ title: s.title, value: s.value || '',
      placeholder: s.placeholder || 'Not set', onPick: v => save(v) });
    row.appendChild(box.el);
    bindUpdate(box.el, () => box.set(s.value));
    return row;
  }

  // A bounded number is dragged, not typed, the same slider the device
  // shows. Label updates live; the value saves once, on release.
  if (s.type === 'number' && s.min != null && s.max != null) {
    // Camera auto-dismiss moves through stops, not seconds: every 30 s up to
    // 5 min, then every 5 min up to an hour. The slider holds the stop index
    // and a stored value between stops sits on the nearest one.
    const stops = s.key === 'camera.auto_dismiss_seconds' ? CAMERA_DISMISS_STOPS : null;
    const toSlider = (v) => stops
      ? stops.reduce((best, stop, i) => Math.abs(stop - v) < Math.abs(stops[best] - v) ? i : best, 0)
      : v;
    const fromSlider = (v) => stops ? stops[v] : v;
    const label = (v) => {
      if (stops) {
        const seconds = stops[v];
        if (seconds <= 0) return t('cameraStreamsOff');
        if (seconds < 60) return t('cameraStreamsSeconds', {seconds: String(seconds)});
        if (seconds % 3600 === 0) return t('haHours', {hours: String(seconds / 3600)});
        return t('haMinutes', {minutes: new Intl.NumberFormat(messageLanguage(), {
          maximumFractionDigits: 1,
        }).format(seconds / 60)});
      }
      if (s.key === 'gestures.hand_hold_seconds') {
        return Number(v) === 0 ? t('gestureHoldInstant')
          : t('gestureHoldSeconds', {seconds: new Intl.NumberFormat(messageLanguage(), {
            maximumFractionDigits: 1,
          }).format(v)});
      }
      // Hold mode's auto-release reads as a clock: 0 is "Never" and 90 is
      // "1 h 30 min". Kept identical to the device's copy.
      if (s.key === 'ha.hold_release_minutes' || s.key === 'voice.realtime_history_hours') {
        const minutes = Math.round(s.key === 'voice.realtime_history_hours' ? v * 60 : v);
        if (minutes <= 0) return haText('Never');
        const h = Math.floor(minutes / 60), m = minutes % 60;
        if (h === 0) return t('haMinutes', {minutes: String(m)});
        return m === 0 ? t('haHours', {hours: String(h)}) : t('haHoursMinutes', {hours: String(h), minutes: String(m)});
      }
      // The overlay's backdrop: the far left keeps the skin's own.
      if (s.key === 'voice.background_opacity' && Number(v) < 0) return voiceText('Skin default');
      return s.unit === '%'
        ? `${Math.round(s.max <= 1 ? v * 100 : v)}%`
        : `${v}${s.unit || ''}`;
    };
    const slider = attachSlider(row, {
      min: stops ? 0 : s.min, max: stops ? stops.length - 1 : s.max,
      step: stops ? 1 : s.step ?? 'any',
      value: toSlider(typeof s.value === 'number' ? s.value : s.min),
      label,
    });
    slider.input.addEventListener('change', async () => {
      const next = fromSlider(Number(slider.input.value));
      // Enabling real screen-off gets a warning first: what a dark panel
      // does to Wi-Fi, the camera and the app itself is the manufacturer's
      // call, and the Black screensaver avoids the whole regime.
      if (s.key === 'screensaver.screen_off_minutes' &&
          Number(s.value || 0) === 0 && next > 0 &&
          !state.settings.some(s => s.key === 'screensaver.screen_off_black' && s.value === true)) {
        const pick = await localizedMessageBox({
          titleId: 'screensaverWarningTitle', messageId: 'screensaverScreenOffWarning',
          buttons: [{id:'commonCancel', value:'Cancel'}, {id:'screensaverScreenOffProceed', value:'Proceed'}],
        });
        if (pick === 'Cancel') {
          slider.set(0);
          return;
        }
      }
      // Night mode's own, with the light sensor added: the room brightening
      // is what turns the screen back on.
      if (s.key === 'screensaver.clock_night_turn_off_minutes' &&
          Number(s.value || 0) === 0 && next > 0 &&
          !state.settings.some(o => o.key === 'screensaver.clock_night_turn_off_black' && o.value === true)) {
        const pick = await localizedMessageBox({
          titleId: 'screensaverWarningTitle', messageId: 'screensaverNightTurnOffWarning',
          buttons: [{id:'commonCancel', value:'Cancel'}, {id:'screensaverScreenOffProceed', value:'Proceed'}],
        });
        if (pick !== 'Proceed') {
          slider.set(0);
          return;
        }
      }
      // save() records the value once the device has kept it; recording
      // it here first made a refused value snap "back" to itself.
      save(next);
    });
    bindUpdate(slider.input, () => slider.set(toSlider(s.value)));
    if (s.key === 'sendspin.duck_percent') {
      const fragment = document.createDocumentFragment();
      fragment.append(row, albumArtCacheRow());
      return fragment;
    }
    return row;
  }

  if (s.type === 'boolean') {
    const lbl = document.createElement('label'); lbl.className = 'switch';
    const cb = document.createElement('input'); cb.type = 'checkbox'; cb.checked = !!s.value;
    cb.addEventListener('change', async () => {
      if (s.key === 'remote.tls') {
        const wanted = cb.checked;
        cb.checked = !!s.value;
        cb.disabled = true;
        try {
          if (!await confirmRemoteProtocol(wanted)) return;
          await save(wanted);
        } finally { cb.disabled = false; }
        return;
      }
      // The one switch here that takes away the thing you are using. Nothing
      // on this page can undo it, because this page is what it serves.
      if (s.key === 'remote.enabled' && !cb.checked) {
        const pick = await localizedMessageBox({
          titleId: 'remoteDisableTitle', messageId: 'remoteDisableHelp',
          buttons: [{id: 'commonCancel', value: 'Cancel'},
            {id: 'remoteDisableConfirm', value: 'Turn it off'}],
        });
        if (pick !== 'Turn it off') { cb.checked = true; return; }
      }
      save(cb.checked);
    });
    const sl = document.createElement('span'); sl.className = 'slider';
    lbl.append(cb, sl); row.appendChild(lbl);
    bindUpdate(cb, () => { cb.checked = !!s.value; });
  } else if (s.type === 'select') {
    const sel = document.createElement('select');
    const fill = () => {
      sel.replaceChildren();
      sel.disabled = false;
      let opts = s.options || [];
      if (s.key === 'camera.rtsp.resolution' && !opts.length) {
        const opt = document.createElement('option');
        opt.textContent = cameraText('No supported sizes available');
        sel.appendChild(opt);
        sel.disabled = true;
      }
      if (s.key === 'screensaver.mode' && !state.haConfigured)
        opts = opts.filter((o) => o !== 'media' && o !== 'weather_mood' && o !== 'dashboard');
      opts.forEach((o) => {
        const opt = document.createElement('option');
        opt.value = o;
        // The declared label ('media' → "Home Assistant Media"), or
        // Capitalised as a fallback, stored values are lowercase identifiers.
        opt.textContent = (s.optionLabels && s.optionLabels[o]) ||
          (o ? o[0].toUpperCase() + o.slice(1) : o);
        opt.selected = o === s.value; sel.appendChild(opt);
      });
    };
    fill();
    sel.addEventListener('change', () => save(sel.value));
    row.appendChild(sel);
    bindUpdate(sel, () => { sel.value = s.value ?? ''; });
    // New choices from the device (a provider's models, a camera's sizes)
    // land in place: the page is not rebuilt under whatever is being typed.
    row.updateOptions = () => { if (!row.contains(sel)) return false; fill(); return true; };
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
    bindUpdate(ta, () => { ta.value = s.value ?? ''; });
  } else {
    const inp = document.createElement('input');
    inp.type = s.type === 'password' ? 'password' : s.type === 'number' ? 'number' : 'text';
    if (s.type === 'password') inp.placeholder = s.value === '__set__' ? deviceText('•••••• (set)') : deviceText('Not set');
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
    bindUpdate(inp, () => {
      inp.value = s.type === 'password' ? '' : s.value ?? '';
      if (s.type === 'password') inp.placeholder = s.value === '__set__' ? deviceText('•••••• (set)') : deviceText('Not set');
    });
  }
  return row;
}
