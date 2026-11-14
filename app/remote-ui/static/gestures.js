import { isHeadless } from './headless.js';
import { gestureText, cameraText, localizeSetting, t } from './localization.js';
import { watchUpdates } from './live.js';
import {
  cameraAction,
  cameraEditor,
  cameraField,
  cameraIcon,
  cameraListRow,
  cameraSelectField,
} from './cameras.js';
import { api, cmd, state } from './core.js';
import { applyManagedBanners } from './fleetsync.js';
import { settingRow } from './rows.js';
import { radioRow } from './views.js';
import { pickDashboard } from './dashboard_picker.js';
import {
  entitySpec, onListLoaded, pickEntity, pickField, pickItem, serviceEntityDomains, serviceSpec,
} from './entity_picker.js';
import { messageBox, localizedMessageBox, modalShell } from './widgets.js';

/* ---- Gestures (issue #99) ----
   Mirror of the device's Gestures page (ui/gesture_settings.dart): the
   list of gestures and the actions they trigger, stored as the
   gestures.mappings JSON setting. The editor is two-staged there and
   here: the main modal owns the trigger, and each action type configures

   itself in its own modal. */

export const GESTURE_CORNERS = {
  tl: 'top-left', tr: 'top-right', bl: 'bottom-left', br: 'bottom-right',
};
export const GESTURE_TRIGGERS = [
  ['corner_taps', 'Taps in a corner'],
  ['corner_hold', 'Hold a corner'],
  ['finger_taps', 'Multi-finger tap'],
  ['finger_hold', 'Multi-finger hold'],
  ['corner_sequence', 'Corner sequence'],
  ['claps', 'Claps'],
  ['fingers', 'Show fingers'],
  ['plugin', 'Plugin trigger'],
  ['button', 'Button'],
];
// What a device without a screen can do: its buttons, claps and plugins
// trigger, and the actions that show, open or navigate something are left
// out (headless.js).
const HEADLESS_TRIGGERS = new Set(['button', 'claps', 'plugin']);
const DISPLAY_ACTIONS = new Set([
  'navigate', 'refresh', 'url', 'camera_view', 'sendspin_player', 'now_playing',
  'music_assistant', 'app_launcher', 'intercom_open', 'screensaver', 'screensaver_stop',
  'hold_mode', 'ha_kiosk', 'launch_app', 'open_uri', 'android_settings', 'calendar',
  'music_library', 'alarms', 'alarm_next', 'timers',
]);
// The buttons that reach the app. The Echo Dot's LineageOS build keeps the
// microphone and volume buttons for itself (they mute and change the volume
// there), so the Action button is the one to map.
export const GESTURE_BUTTONS = [['action', 'Action']];
export const GESTURE_PRESSES = [
  ['single', 'Press'], ['double', 'Double press'], ['long', 'Hold'],
];
export const GESTURE_ACTION_GROUPS = [
  ['Kiosk Satellite', [
    ['navigate', 'Go to a dashboard view', 'grid'],
    ['refresh', 'Refresh the dashboard', 'refresh'],
    ['url', 'Open a web page', 'globe'],
    ['camera_view', 'Show a camera view', 'video'],
    ['sendspin_player', 'Show the floating player', 'speaker'],
    ['now_playing', 'Show Now Playing', 'playCircle'],
    ['music_assistant', 'Open Music Assistant', 'music'],
    ['music_library', 'Open Music Library', 'queueMusic'],
    ['media_play_pause', 'Play or pause media', 'playPause'],
    ['app_launcher', 'Open the app launcher', 'apps'],
    ['intercom_open', 'Open Call a kiosk', 'speaker'],
    ['intercom_call', 'Call a kiosk', 'speaker'],
    ['intercom_hangup', 'End the intercom call', 'callEnd'],
    ['intercom_answer', 'Accept intercom call', 'call'],
    ['intercom_decline', 'Decline intercom call', 'callOff'],
    ['alarm_stop', 'Stop the alarm', 'alarmOff'],
    ['alarm_snooze', 'Snooze the alarm', 'snooze'],
    ['alarms', 'Open the alarm list', 'alarm'],
    ['alarm_next', 'Open the next alarm', 'alarmOn'],
    ['timers', 'Open the timers', 'timer'],
    ['calendar', 'Open the calendar', 'calendar'],
    ['voice_wake', 'Start a voice command', 'mic'],
    ['voice_stop', 'Stop the voice assistant', 'stop'],
    ['voice_mute', 'Mute or unmute Voice Satellite', 'micOff'],
    ['screensaver', 'Start the screensaver', 'moon'],
    ['screensaver_stop', 'Stop the screensaver', 'sun'],
    ['hold_mode', 'Toggle hold mode', 'pauseCircle'],
    ['ha_kiosk', 'Toggle HA kiosk mode', 'fullscreen'],
    ['plugin_action', 'Run a plugin action', 'playCircle'],
  ]],
  ['Android', [
    ['launch_app', 'Open another app', 'apps'],
    ['open_uri', 'Open a deep link', 'link'],
    ['android_settings', 'Open Android Settings', 'android'],
  ]],
  ['Home Assistant', [
    ['ha_service', 'Call a service', 'home'],
    ['ha_script', 'Run a script', 'doc'],
    ['ha_automation', 'Trigger an automation', 'playCircle'],
    ['ha_event', 'Fire an event', 'announce'],
  ]],
];

export function gestureCorner(corner) {
  const name = GESTURE_CORNERS[corner];
  return name ? gestureText(name[0].toUpperCase() + name.slice(1) + ' corner') : corner;
}

// Both names come from the plugin's manifest, like a plugin action's.
export function describePluginTrigger(trigger) {
  return `${trigger.pluginName || trigger.pluginId}: ${trigger.title || trigger.trigger}`;
}

export function describeGestureTrigger(trigger) {
  const corner = gestureText(GESTURE_CORNERS[trigger.corner] || '');
  const seconds = () => {
    const value = (Number(trigger.holdMs) || 1500) / 1000;
    return Number.isInteger(value) ? String(value) : value.toFixed(1);
  };
  switch (trigger.type) {
    case 'corner_taps': return t('gestureDescribeCornerTaps', {count: trigger.taps, corner});
    case 'corner_hold': return t('gestureDescribeCornerHold', {corner, seconds: seconds()});
    case 'finger_taps': return t(Number(trigger.taps) === 2 ? 'gestureDescribeFingerDouble' : 'gestureDescribeFingerTap', {count: trigger.fingers});
    case 'finger_hold': return t('gestureDescribeFingerHold', {count: trigger.fingers, seconds: seconds()});
    case 'corner_sequence': return t('gestureDescribeSequence', {sequence: (trigger.sequence || []).map(gestureCorner).join(' > ')});
    case 'claps': return t('gestureDescribeClaps', {count: trigger.claps});
    case 'fingers': {
      const count = Number(trigger.fingers) || 5;
      return count === 5 ? gestureText('Show an open hand') : t(count === 1 ? 'gestureDescribeOneFinger' : 'gestureDescribeFingers', {count});
    }
    case 'plugin': return describePluginTrigger(trigger);
    case 'button': {
      const name = GESTURE_BUTTONS.find(([id]) => id === trigger.button)?.[1] || 'Action';
      const button = gestureText(name);
      if (trigger.press === 'double') return t('gestureDescribeButtonDouble', {button});
      if (trigger.press === 'long') return t('gestureDescribeButtonHold', {button});
      return t('gestureDescribeButtonPress', {button});
    }
  }
  return gestureText('Gesture');
}

// The installed plugins' names and command titles by "pluginId/command". A
// plugin action saves only its IDs, since a plugin can rename itself or its
// commands in any update, so every row looks the names up when it draws.
let pluginActionNames = new Map();
let pluginActionsLoad = null;

export function loadPluginActionNames({ refresh = false } = {}) {
  if (!pluginActionsLoad || refresh) {
    pluginActionsLoad = cmd('getPluginActions').then((result) => {
      if (!result.ok || !Array.isArray(result.data)) return pluginActionNames;
      pluginActionNames = new Map(result.data.map((action) =>
        [`${action.pluginId}/${action.command}`, { plugin: action.pluginName, title: action.title }]));
      return pluginActionNames;
    }).catch(() => pluginActionNames);
  }
  return pluginActionsLoad;
}

export function describeGestureAction(a) {
  if (a.type === 'plugin_action') {
    // Actions saved before the names were looked up carry their own.
    const names = pluginActionNames.get(`${a.pluginId}/${a.command}`);
    return `${names?.plugin || a.pluginName || a.pluginId}: ${names?.title || a.title || a.command}`;
  }
  switch (a.type) {
    case 'navigate': return t('gestureGoTo', {value: a.path});
    case 'url': return t('gestureOpen', {value: a.url});
    case 'refresh': return gestureText('Refresh the dashboard');
    case 'camera_view':
      if (a.mode === 'hide') return gestureText('Close the camera view');
      return a.viewName ? t('gestureCameraToggleName', {name: a.viewName}) : gestureText('Toggle the camera view');
    case 'sendspin_player': return gestureText('Show the floating player');
    case 'now_playing': return gestureText('Show Now Playing');
    case 'music_assistant': return gestureText('Open Music Assistant');
    case 'media_play_pause': return gestureText('Play or pause media');
    case 'app_launcher': return gestureText('Open the app launcher');
    case 'intercom_open': return gestureText('Open Call a kiosk');
    case 'intercom_call': return t('gestureCall', {value: a.kioskName || a.kioskId});
    case 'intercom_hangup': return gestureText('End the intercom call');
    case 'intercom_answer': return gestureText('Accept intercom call');
    case 'intercom_decline': return gestureText('Decline intercom call');
    case 'alarm_stop': return gestureText('Stop the alarm');
    case 'alarm_snooze': return gestureText('Snooze the alarm');
    case 'alarms': return gestureText('Open the alarm list');
    case 'alarm_next': return gestureText('Open the next alarm');
    case 'timers': return gestureText('Open the timers');
    case 'calendar': return gestureText('Open the calendar');
    case 'music_library': return gestureText('Open Music Library');
    case 'voice_wake': return gestureText('Start a voice command');
    case 'voice_stop': return gestureText('Stop the voice assistant');
    case 'voice_mute': return gestureText('Mute or unmute Voice Satellite');
    case 'screensaver': return gestureText('Start the screensaver');
    case 'screensaver_stop': return gestureText('Stop the screensaver');
    case 'hold_mode': return gestureText('Toggle hold mode');
    case 'ha_kiosk': return gestureText('Toggle HA kiosk mode');
    case 'launch_app': return t('gestureOpenApp', {package: a.package});
    case 'open_uri': return t('gestureOpen', {value: a.uri});
    case 'android_settings': return gestureText('Open Android Settings');
    case 'ha_service': return t('gestureCall', {value: `${a.domain}.${a.service}`});
    case 'ha_script': return t('gestureRun', {value: a.entityId});
    case 'ha_automation': return t('gestureTriggerAction', {value: a.entityId});
    case 'ha_event': return t('gestureFireEvent', {value: a.event});
  }
  return gestureText('Action');
}

export function readGestureMappings() {
  const setting = (state.settings || []).find((s) => s.key === 'gestures.mappings');
  try {
    const list = JSON.parse(setting?.value ?? '[]');
    return Array.isArray(list) ? list.filter((m) => m && m.id && m.trigger && m.action) : [];
  } catch (_) { return []; }
}

export async function saveGestureMappings(mappings) {
  const json = JSON.stringify(mappings);
  const cached = (state.settings || []).find((s) => s.key === 'gestures.mappings');
  if (cached) cached.value = json;
  await api('/api/settings', {
    method: 'PATCH',
    body: JSON.stringify({ 'gestures.mappings': json }),
  });
}

// A radio-list modal (the pickView shape): resolves the picked item's
// value, or null on close.
export function gestureListModal(title, items) {
  return new Promise((resolve) => {
    const { back, body, foot } = modalShell({
      title,
      onDismiss: () => { back.remove(); resolve(null); },
    });
    items.forEach((item) => {
      if (item.header) {
        const label = document.createElement('h2');
        label.className = 'card-title';
        label.textContent = item.header;
        label.style.cssText = 'margin:14px 0 4px; padding:0;';
        body.appendChild(label);
        return;
      }
      const row = radioRow(
        item.name, item.desc || '', !!item.selected,
        () => { back.remove(); resolve(item.value); });
      if (item.icon) {
        const icon = document.createElement('span');
        icon.className = 'camera-row-icon';
        icon.innerHTML = cameraIcon(item.icon);
        row.prepend(icon);
      }
      body.appendChild(row);
    });
    const cancel = document.createElement('button');
    cancel.className = 'btn-text';
    cancel.textContent = gestureText('Cancel');
    cancel.addEventListener('click', () => { back.remove(); resolve(null); });
    foot.appendChild(cancel);
  });
}

export function gestureTextarea(label, value = '', placeholder = '') {
  const wrap = document.createElement('label');
  wrap.className = 'form-field';
  const title = document.createElement('span');
  title.className = 'desc';
  title.textContent = label;
  const input = document.createElement('textarea');
  input.className = 'field';
  input.rows = 3;
  input.style.maxWidth = 'none';
  input.value = value;
  input.placeholder = placeholder;
  wrap.append(title, input);
  return { wrap, input };
}

// One required text field: the URL, app package and deep link dialogs.
export async function configureGestureText(current, spec) {
  const body = document.createElement('div');
  const field = cameraField(spec.label, current ? String(current[spec.field] || '') : '');
  field.input.placeholder = spec.placeholder;
  body.appendChild(field.wrap);
  let out = null;
  const saved = await cameraEditor({
    title: spec.title,
    body,
    save: async () => {
      const value = field.input.value.trim();
      const invalid = spec.validate(value);
      if (invalid) return { ok: false, error: invalid };
      out = { type: spec.type, [spec.field]: value };
      return { ok: true };
    },
  });
  return saved ? out : null;
}

// Run haValidateAction and reduce its answer to one sentence: [ok, message].
export async function validateGestureHaAction(domain, service, entity) {
  let result;
  try {
    result = await cmd('haValidateAction', {
      domain, service, ...(entity ? { entity_id: entity } : {}),
    });
  } catch (_) { result = null; }
  if (!result?.ok) return [false, result?.error || gestureText('Could not validate.')];
  const data = result.data || {};
  if (data.domain === false) return [false, t('gestureDomainMissing', {value: domain})];
  if (data.service === false) {
    return [false, t('gestureServiceMissing', {value: `${domain}.${service}`})];
  }
  if (data.entity === false) return [false, t('gestureEntityMissing', {value: entity})];
  return [true, gestureText('Looks good.')];
}

// The Validate row for the HA editors: ghost button plus status line.
// getCheck() returns {domain, service, entity} or a string error.
export function gestureValidateRow(getCheck) {
  const wrap = document.createElement('div');
  wrap.style.cssText = 'display:flex; align-items:center; gap:10px;';
  const status = document.createElement('span');
  status.className = 'desc';
  status.style.flex = '1';
  const button = cameraAction(gestureText('Validate'), async () => {
    const check = getCheck();
    if (typeof check === 'string') {
      status.style.color = 'var(--error)';
      status.textContent = check;
      return;
    }
    button.disabled = true;
    status.style.color = '';
    status.textContent = gestureText('Checking…');
    const [ok, message] =
      await validateGestureHaAction(check.domain, check.service, check.entity);
    button.disabled = false;
    status.style.color = ok ? 'var(--ok)' : 'var(--error)';
    status.textContent = message;
  });
  wrap.append(button, status);
  return wrap;
}

// One Home Assistant entity plus a Validate check: the script and
// automation dialogs. A bare name is qualified with the domain.
export async function configureGestureHaEntity(current, spec) {
  // The entity picker over this domain's entities: picked from Home
  // Assistant's own list, there is nothing to type or validate.
  const out = await pickEntity({ title: spec.title, selected: current?.entityId || null,
    domains: [spec.domain] });
  return out?.id ? { type: spec.type, entityId: out.id } : null;
}

export async function configureGestureNavigate(current) {
  // The dashboard picker every dashboard view setting opens.
  const path = await pickDashboard({
    title: gestureText('Go to a dashboard view'),
    selected: current?.path || null,
  });
  return path ? { type: 'navigate', path } : null;
}

export async function configureGestureCameraView(current) {
  const result = await cmd('cameraGetConfig').catch(() => null);
  const views = result?.ok ? result.data.views : [];
  const items = views.map((view) => ({
    name: t('gestureCameraShow', {name: view.name}),
    selected: current?.mode === 'show' && current?.viewId === view.id,
    value: view,
  }));
  items.push({
    name: gestureText('Close the camera view'),
    selected: current?.mode === 'hide',
    value: 'hide',
  });
  const picked = await gestureListModal(gestureText('Camera view'), items);
  if (!picked) return null;
  if (picked === 'hide') return { type: 'camera_view', mode: 'hide' };
  return {
    type: 'camera_view', mode: 'show', viewId: picked.id, viewName: picked.name,
  };
}

// The kiosk a Call a kiosk gesture rings: every kiosk the intercom has
// heard, whatever its state today.
export async function configureGestureIntercomCall(current) {
  const result = await cmd('intercomStatus').catch(() => null);
  const kiosks = result?.ok ? (result.data.kiosks || []) : [];
  const items = kiosks.map((k) => ({
    name: k.name, desc: k.address,
    selected: current?.kioskId === k.id,
    value: k,
  }));
  if (!items.length) items.push({ name: gestureText('No kiosk found on the network yet.'), desc: '', value: null });
  const picked = await gestureListModal(gestureText('Call a kiosk'), items);
  if (!picked) return null;
  return { type: 'intercom_call', kioskId: picked.id, kioskName: picked.name };
}

// data must parse as a JSON object when present; shared by the two HA
// dialogs.
export function parseGestureData(text) {
  if (!text.trim()) return { ok: true, value: null };
  try {
    const parsed = JSON.parse(text);
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) throw 0;
    return { ok: true, value: parsed };
  } catch (_) { return { ok: false }; }
}

export async function configureGestureHaService(current) {
  const body = document.createElement('div');
  // One pick, domain.service, stored split as before.
  let serviceId = current?.domain && current?.service ? `${current.domain}.${current.service}` : '';
  let entityId = current?.entityId || '';
  const labeled = (label, field) => {
    const wrap = document.createElement('div');
    wrap.className = 'form-field';
    const title = document.createElement('span');
    title.className = 'desc';
    title.textContent = label;
    wrap.append(title, field.el);
    return wrap;
  };
  const split = () => {
    const dot = serviceId.indexOf('.');
    return dot < 0 ? ['', serviceId] : [serviceId.slice(0, dot), serviceId.slice(dot + 1)];
  };
  // Only the entities the service acts on. Off until a service is picked,
  // and for one that takes none.
  const entity = pickField({
    spec: entitySpec(), value: entityId,
    onClick: async () => {
      const domains = serviceEntityDomains(serviceId);
      if (!domains) return;
      const out = await pickItem({ title: gestureText('Entity (optional)'),
        spec: entitySpec({ domains }), selected: entityId || null, allowClear: true });
      if (!out) return;
      entityId = out.id ?? '';
      entity.setValue(entityId);
    },
  });
  const syncEntity = () => {
    const domains = serviceEntityDomains(serviceId);
    entity.setEnabled(!!domains);
    entity.setPlaceholder(serviceId && !domains ? gestureText('Not used by this service') : null);
  };
  // Picked from Home Assistant's own services, under their domains.
  const service = pickField({
    spec: serviceSpec(), value: serviceId, placeholder: gestureText('Choose a service'),
    onClick: async () => {
      const out = await pickItem({ title: gestureText('Service'), spec: serviceSpec(),
        selected: serviceId || null });
      if (!out?.id) return;
      serviceId = out.id;
      service.setValue(serviceId);
      // An entity the new service cannot act on goes with the old one.
      const domains = serviceEntityDomains(serviceId);
      if (!domains || (domains.length && !domains.includes(entityId.split('.')[0]))) {
        entityId = '';
        entity.setValue('');
      }
      syncEntity();
    },
  });
  syncEntity();
  onListLoaded('services', service.el, syncEntity);
  const data = gestureTextarea(gestureText('Service data (optional)'),
    current?.data ? JSON.stringify(current.data) : '', '{"brightness_pct": 60}');
  body.append(labeled(gestureText('Service'), service),
    labeled(gestureText('Entity (optional)'), entity), data.wrap,
    gestureValidateRow(() => serviceId
      ? { domain: split()[0], service: split()[1], entity: entityId }
      : gestureText('Choose a service')));
  let out = null;
  const saved = await cameraEditor({
    title: gestureText('Call a Home Assistant service'),
    body,
    save: async () => {
      if (!serviceId) return { ok: false, error: gestureText('Choose a service') };
      const parsed = parseGestureData(data.input.value);
      if (!parsed.ok) return { ok: false, error: gestureText('Service data must be a JSON object.') };
      const [domain, name] = split();
      out = { type: 'ha_service', domain, service: name };
      if (entityId) out.entityId = entityId;
      if (parsed.value) out.data = parsed.value;
      return { ok: true };
    },
  });
  return saved ? out : null;
}

export async function configureGestureHaEvent(current) {
  const body = document.createElement('div');
  const event = cameraField(gestureText('Event type'), current?.event || '');
  event.input.placeholder = 'kiosk_satellite_gesture';
  const data = gestureTextarea(gestureText('Event data (optional)'),
    current?.data ? JSON.stringify(current.data) : '', '{"room": "kitchen"}');
  body.append(event.wrap, data.wrap);
  let out = null;
  const saved = await cameraEditor({
    title: gestureText('Fire a Home Assistant event'),
    body,
    save: async () => {
      if (!event.input.value.trim()) {
        return { ok: false, error: gestureText('Event type is required.') };
      }
      const parsed = parseGestureData(data.input.value);
      if (!parsed.ok) return { ok: false, error: gestureText('Event data must be a JSON object.') };
      out = { type: 'ha_event', event: event.input.value.trim() };
      if (parsed.value) out.data = parsed.value;
      return { ok: true };
    },
  });
  return saved ? out : null;
}

// The chooser, then the chosen type's own configuration dialog. Types with
// nothing to configure resolve directly.
export async function pickGestureAction(current) {
  const items = [];
  for (const [group, all] of GESTURE_ACTION_GROUPS) {
    const actions = isHeadless() ? all.filter(([value]) => !DISPLAY_ACTIONS.has(value)) : all;
    if (!actions.length) continue;
    items.push({ header: group });
    for (const [value, label, icon] of actions) {
      items.push({
        name: gestureText(label), selected: current?.type === value, value, icon,
      });
    }
  }
  const type = await gestureListModal(gestureText('Action'), items);
  if (!type) return null;
  const carried = current?.type === type ? current : null;
  switch (type) {
    case 'plugin_action': {
      const result = await cmd('getPluginActions');
      if (!result.ok) { await messageBox({ title: gestureText('Plugin actions'), message: result.error || gestureText('Could not load plugin actions.') }); return null; }
      const actions = (Array.isArray(result.data) ? result.data : []).filter((action) => action.available);
      if (!actions.length) { await messageBox({ title: gestureText('Plugin actions'), message: gestureText('Enable a plugin with actions in Plugin Manager first.') }); return null; }
      return gestureListModal(gestureText('Plugin action'), actions.map((action) => ({
        name: action.title, desc: action.pluginName,
        value: { type, pluginId: action.pluginId, command: action.command },
        selected: carried?.pluginId === action.pluginId && carried?.command === action.command,
      })));
    }
    case 'android_settings': case 'sendspin_player': case 'app_launcher':
    case 'screensaver': case 'screensaver_stop': case 'hold_mode':
    case 'ha_kiosk': case 'now_playing': case 'music_assistant':
    case 'media_play_pause': case 'intercom_open': case 'intercom_hangup':
    case 'intercom_answer': case 'intercom_decline':
    case 'alarm_stop': case 'alarm_snooze': case 'calendar': case 'refresh':
    case 'alarms': case 'alarm_next': case 'timers':
    case 'music_library':
    case 'voice_wake': case 'voice_stop': case 'voice_mute':
      return { type };
    case 'navigate': return configureGestureNavigate(carried);
    case 'url': return configureGestureText(carried, {
      type: 'url', title: gestureText('Open a web page'), field: 'url', label: 'URL',
      placeholder: 'https://example.com',
      validate: (v) => {
        try {
          const url = new URL(v);
          if ((url.protocol === 'http:' || url.protocol === 'https:')
            && url.hostname) return null;
        } catch (_) {}
        return gestureText('Enter a full http(s) URL.');
      },
    });
    case 'camera_view': return configureGestureCameraView(carried);
    case 'intercom_call': return configureGestureIntercomCall(carried);
    case 'launch_app': return configureGestureText(carried, {
      type: 'launch_app', title: gestureText('Open another app'), field: 'package',
      label: gestureText('Package name'), placeholder: 'com.android.deskclock',
      validate: (v) => v.includes('.') ? null : gestureText('Enter a package name.'),
    });
    case 'open_uri': return configureGestureText(carried, {
      type: 'open_uri', title: gestureText('Open a deep link'), field: 'uri', label: 'URI',
      placeholder: 'myapp://path',
      validate: (v) => /^[a-z][a-z0-9+.-]*:/i.test(v) ? null : gestureText('Enter a full URI.'),
    });
    case 'ha_service': return configureGestureHaService(carried);
    case 'ha_script': return configureGestureHaEntity(carried, {
      type: 'ha_script', title: gestureText('Run a script'), label: gestureText('Script entity'),
      hint: 'script.good_morning', domain: 'script', service: 'turn_on',
    });
    case 'ha_automation': return configureGestureHaEntity(carried, {
      type: 'ha_automation', title: gestureText('Trigger an automation'),
      label: gestureText('Automation entity'), hint: 'automation.lights_off',
      domain: 'automation', service: 'trigger',
    });
    case 'ha_event': return configureGestureHaEvent(carried);
  }
  return null;
}

// The main editor: the trigger's fields show and hide with its type, the
// action summarizes below with its own chooser.
export async function editGesture(existing) {
  const triggerValue = existing?.trigger || {};
  let action = existing?.action || null;
  const sequence = Array.isArray(triggerValue.sequence) ? triggerValue.sequence.map(String) : [];

  const body = document.createElement('div');
  // Show fingers needs a hand runtime this Android version cannot load
  // (issue #331): not offered, though an existing mapping still opens.
  const handsOk = !(state.visionSupport && state.visionSupport.hands === false);
  // The buttons are a headless device's, and touch and hands need a screen
  // and a camera.
  const headless = isHeadless();
  const offered = ([value]) => value === triggerValue.type
    || (headless ? HEADLESS_TRIGGERS.has(value) : value !== 'button');
  const typeSel = cameraSelectField(gestureText('Gesture'),
    GESTURE_TRIGGERS
      .filter(offered)
      .filter(([value]) => handsOk || value !== 'fingers' || triggerValue.type === 'fingers')
      .map(([value, label]) => ({ value, label: gestureText(label) })),
    triggerValue.type || (headless ? 'button' : 'corner_taps'));
  const buttonSel = cameraSelectField(gestureText('Button'),
    GESTURE_BUTTONS.map(([value, label]) => ({ value, label: gestureText(label) })),
    GESTURE_BUTTONS.some(([id]) => id === triggerValue.button) ? triggerValue.button : 'action');
  const pressSel = cameraSelectField(gestureText('Press'),
    GESTURE_PRESSES.map(([value, label]) => ({ value, label: gestureText(label) })),
    GESTURE_PRESSES.some(([id]) => id === triggerValue.press) ? triggerValue.press : 'single');
  const cornerSel = cameraSelectField(gestureText('Corner'),
    Object.entries(GESTURE_CORNERS).map(([value, label]) => ({
      value, label: gestureCorner(value),
    })), GESTURE_CORNERS[triggerValue.corner] ? triggerValue.corner : 'tl');
  const tapsSel = cameraSelectField(gestureText('Taps'),
    [{ value: '2', label: gestureText('2 taps') }, { value: '3', label: gestureText('3 taps') },
      { value: '4', label: gestureText('4 taps') }],
    String(Math.min(Math.max(Number(triggerValue.taps) || 2, 2), 4)));
  const fingersSel = cameraSelectField(gestureText('Fingers'),
    [{ value: '2', label: gestureText('2 fingers') }, { value: '3', label: gestureText('3 fingers') }],
    String(Number(triggerValue.fingers) === 2 ? 2 : 3));
  const fingerTapsSel = cameraSelectField(gestureText('Taps'),
    [{ value: '1', label: gestureText('Single tap') }, { value: '2', label: gestureText('Double tap') }],
    String(Number(triggerValue.taps) === 2 ? 2 : 1));
  const clapsSel = cameraSelectField(gestureText('Claps'),
    [{ value: '2', label: gestureText('2 claps') }, { value: '3', label: gestureText('3 claps') },
      { value: '4', label: gestureText('4 claps') }],
    String(Math.min(Math.max(Number(triggerValue.claps) || 2, 2), 4)));
  const clapsNote = document.createElement('span');
  clapsNote.className = 'desc';
  clapsNote.textContent = gestureText('Claps are heard through the microphone, with or without wake word detection.');
  const fingerCountSel = cameraSelectField(gestureText('Fingers'),
    [{ value: '1', label: gestureText('1 finger') }, { value: '2', label: gestureText('2 fingers') },
      { value: '3', label: gestureText('3 fingers') }, { value: '4', label: gestureText('4 fingers') },
      { value: '5', label: gestureText('Open hand (5)') }],
    String(Math.min(Math.max(Number(triggerValue.fingers) || 5, 1), 5)));
  const palmNote = document.createElement('span');
  palmNote.className = 'desc';
  palmNote.textContent = handsOk
    ? gestureText('Requires the camera enabled and a well lit environment.')
    : gestureText(cameraText(state.visionSupport.hint || 'Not available on this device.'));

  // Running plugins' triggers, plus the saved one so a mapping whose plugin
  // is off still opens with its trigger selected.
  const pluginKey = (trigger) => `${trigger.pluginId}/${trigger.trigger}`;
  const pluginTriggers = new Map();
  if (triggerValue.type === 'plugin') pluginTriggers.set(pluginKey(triggerValue), triggerValue);
  // Anything but a list (an older kiosk, a failed read) means no plugin
  // triggers, never an editor that will not open.
  const listed = await cmd('getPluginTriggers').catch(() => null);
  const triggers = listed?.ok && Array.isArray(listed.data) ? listed.data : [];
  for (const item of triggers.filter((item) => item.available)) {
    pluginTriggers.set(pluginKey(item), {
      type: 'plugin', pluginId: item.pluginId, trigger: item.trigger,
      pluginName: item.pluginName, title: item.title,
    });
  }
  const pluginSel = cameraSelectField(gestureText('Trigger'),
    [...pluginTriggers].map(([value, trigger]) => ({ value, label: describePluginTrigger(trigger) })),
    triggerValue.type === 'plugin' ? pluginKey(triggerValue) : pluginTriggers.keys().next().value);
  const pluginNote = document.createElement('span');
  pluginNote.className = 'desc';
  pluginNote.textContent = gestureText('Enable a plugin with triggers in Plugin Manager first.');

  const holdWrap = document.createElement('label');
  holdWrap.className = 'form-field';
  const holdLabel = document.createElement('span');
  holdLabel.className = 'desc';
  const holdInput = document.createElement('input');
  holdInput.type = 'range';
  holdInput.min = '500';
  holdInput.max = '3000';
  holdInput.step = '250';
  holdInput.value = String(Number(triggerValue.holdMs) || 1500);
  const holdText = () => {
    holdLabel.textContent = t('gestureHoldDuration', {seconds: (Number(holdInput.value) / 1000).toFixed(2)});
  };
  holdInput.addEventListener('input', holdText);
  holdText();
  holdWrap.append(holdLabel, holdInput);

  const seqWrap = document.createElement('div');
  seqWrap.className = 'form-field';
  const seqText = document.createElement('span');
  seqText.className = 'desc';
  const seqButtons = document.createElement('div');
  seqButtons.style.cssText = 'display:flex; gap:8px; flex-wrap:wrap;';
  const paintSeq = () => {
    seqText.textContent = sequence.length
      ? sequence.map(gestureCorner).join(' > ')
      : gestureText('Tap the corners in order (2 to 8 steps).');
  };
  for (const corner of Object.keys(GESTURE_CORNERS)) {
    seqButtons.appendChild(cameraAction(gestureCorner(corner), () => {
      if (sequence.length >= 8) return;
      sequence.push(corner);
      paintSeq();
    }));
  }
  seqButtons.appendChild(cameraAction(gestureText('Undo'), () => {
    sequence.pop();
    paintSeq();
  }));
  paintSeq();
  seqWrap.append(seqText, seqButtons);

  const actionRow = document.createElement('div');
  actionRow.className = 'row';
  actionRow.style.borderBottom = 'none';
  const actionInfo = document.createElement('div');
  actionInfo.className = 'info';
  const actionName = document.createElement('div');
  actionName.className = 'name';
  actionName.textContent = action ? describeGestureAction(action) : gestureText('Choose an action');
  const actionDesc = document.createElement('div');
  actionDesc.className = 'desc';
  actionDesc.textContent = gestureText('What this gesture triggers.');
  actionInfo.append(actionName, actionDesc);
  actionRow.append(actionInfo, cameraAction(gestureText('Choose'), async () => {
    const picked = await pickGestureAction(action);
    if (picked) {
      action = picked;
      actionName.textContent = describeGestureAction(action);
    }
  }));

  body.append(typeSel.wrap, buttonSel.wrap, pressSel.wrap, cornerSel.wrap, tapsSel.wrap, fingersSel.wrap,
    fingerTapsSel.wrap, clapsSel.wrap, clapsNote, fingerCountSel.wrap,
    holdWrap, palmNote, pluginSel.wrap, pluginNote, seqWrap, actionRow);
  const update = () => {
    const type = typeSel.select.value;
    buttonSel.wrap.style.display = type === 'button' ? '' : 'none';
    pressSel.wrap.style.display = type === 'button' ? '' : 'none';
    cornerSel.wrap.style.display =
      type === 'corner_taps' || type === 'corner_hold' ? '' : 'none';
    tapsSel.wrap.style.display = type === 'corner_taps' ? '' : 'none';
    fingersSel.wrap.style.display =
      type === 'finger_taps' || type === 'finger_hold' ? '' : 'none';
    fingerTapsSel.wrap.style.display = type === 'finger_taps' ? '' : 'none';
    clapsSel.wrap.style.display = type === 'claps' ? '' : 'none';
    clapsNote.style.display = type === 'claps' ? '' : 'none';
    fingerCountSel.wrap.style.display = type === 'fingers' ? '' : 'none';
    palmNote.style.display = type === 'fingers' ? '' : 'none';
    holdWrap.style.display =
      type === 'corner_hold' || type === 'finger_hold' ? '' : 'none';
    seqWrap.style.display = type === 'corner_sequence' ? '' : 'none';
    pluginSel.wrap.style.display = type === 'plugin' && pluginTriggers.size ? '' : 'none';
    pluginNote.style.display = type === 'plugin' && !pluginTriggers.size ? '' : 'none';
  };
  typeSel.select.addEventListener('change', update);
  update();

  return cameraEditor({
    title: existing ? gestureText('Edit gesture') : gestureText('Add gesture'),
    body,
    save: async () => {
      const type = typeSel.select.value;
      if (!action) return { ok: false, error: gestureText('Choose an action.') };
      if (type === 'corner_sequence' && sequence.length < 2) {
        return { ok: false, error: gestureText('Add at least two corners.') };
      }
      if (type === 'plugin' && !pluginTriggers.has(pluginSel.select.value)) {
        return { ok: false, error: gestureText('Enable a plugin with triggers in Plugin Manager first.') };
      }
      const trigger = type === 'plugin' ? { ...pluginTriggers.get(pluginSel.select.value) } : { type };
      if (type === 'corner_taps' || type === 'corner_hold') {
        trigger.corner = cornerSel.select.value;
      }
      if (type === 'corner_taps') trigger.taps = Number(tapsSel.select.value);
      if (type === 'finger_taps' || type === 'finger_hold') {
        trigger.fingers = Number(fingersSel.select.value);
      }
      if (type === 'finger_taps') trigger.taps = Number(fingerTapsSel.select.value);
      if (type === 'corner_hold' || type === 'finger_hold') {
        trigger.holdMs = Number(holdInput.value);
      }
      if (type === 'corner_sequence') trigger.sequence = [...sequence];
      if (type === 'claps') trigger.claps = Number(clapsSel.select.value);
      if (type === 'fingers') trigger.fingers = Number(fingerCountSel.select.value);
      if (type === 'button') {
        trigger.button = buttonSel.select.value;
        trigger.press = pressSel.select.value;
      }
      const mappings = readGestureMappings();
      const mapping = {
        id: existing?.id || `g${Date.now()}`, trigger, action,
      };
      const index = mappings.findIndex((m) => m.id === mapping.id);
      if (index >= 0) mappings[index] = mapping;
      else mappings.push(mapping);
      await saveGestureMappings(mappings);
      return { ok: true };
    },
  });
}

export async function loadGestures() {
  await loadPluginActionNames({ refresh: true });
  const root = document.getElementById('tab-gestures');
  // Boot and live updates own the settings cache and language. A page visit
  // must not replace them with a separate settings response.
  const settings = (state.settings || []).map(setting =>
    Object.assign(setting, localizeSetting(setting)));
  root.innerHTML = '';
  // Rebuilt from scratch on every visit, so the banner a follower's synced
  // category wears goes back on first; the generic tabs keep theirs because
  // nothing redraws them between settings loads.
  applyManagedBanners();
  const value = (key) =>
    settings.find((s) => s.key === key)?.value;
  const refresh = () => loadGestures();

  if (value('kiosk.enabled') === true && value('kiosk.disable_gestures') === true) {
    const off = document.createElement('div');
    off.className = 'card';
    off.appendChild(cameraListRow(gestureText('Gestures are off'),
      gestureText('Disable Gestures is on in Kiosk Mode settings.'), []));
    root.appendChild(off);
  }

  const heading = document.createElement('h2');
  heading.className = 'card-title';
  heading.textContent = gestureText('Gestures');
  root.appendChild(heading);
  const card = document.createElement('div');
  card.className = 'card';
  root.appendChild(card);

  const mappings = readGestureMappings();
  if (!mappings.length) {
    card.appendChild(cameraListRow(gestureText('No gestures configured'),
      gestureText('A gesture triggers its action without any visible control.'),
      [], { icon: 'gesture' }));
  }
  for (const mapping of mappings) {
    card.appendChild(cameraListRow(
      describeGestureTrigger(mapping.trigger),
      describeGestureAction(mapping.action),
      [
        cameraAction(gestureText('Delete'), async () => {
          const choice = await localizedMessageBox({
            titleId:'gestureDeleteTitle', messageId:'gestureDeleteMessage',
            values:() => ({trigger:describeGestureTrigger(mapping.trigger), action:describeGestureAction(mapping.action)}),
            buttons:[{id:'commonCancel', value:'Cancel'}, {id:'commonDelete', value:'Delete'}],
          });
          if (choice !== 'Delete') return;
          await saveGestureMappings(
            readGestureMappings().filter((m) => m.id !== mapping.id));
          refresh();
        }, false, 'delete'),
      ],
      {
        icon: { claps: 'clap', fingers: 'hand', plugin: 'extension', button: 'button' }[mapping.trigger?.type] || 'gesture',
        onClick: async () => {
          if (await editGesture(mapping)) refresh();
        },
      },
    ));
  }
  card.appendChild(cameraListRow(
    gestureText('Add gesture'), gestureText('Pick a gesture and the action it triggers.'), [],
    {
      icon: 'add',
      onClick: async () => {
        if (await editGesture(null)) refresh();
      },
    },
  ));

  const note = document.createElement('div');
  note.className = 'group-note';
  note.textContent = isHeadless()
    ? gestureText('A button press no gesture claims keeps its own job: Action answers, stops or dismisses what is ringing and otherwise starts a voice command, Microphone mutes Voice Satellite and the volume buttons change the volume.')
    : gestureText('Gestures are observed, not blocked: the taps also reach the dashboard, so corners and multi-finger shapes keep them from firing anything there.');
  root.appendChild(note);

  // Mirrors the device's Clapper section (ui/gesture_settings.dart).
  const strictness = settings.find((s) => s.key === 'gestures.clap_strictness');
  if (strictness) {
    const clapperHeading = document.createElement('h2');
    clapperHeading.className = 'card-title';
    // Follows the group note, which ends flush (no bottom margin); the
    // usual card-to-heading rhythm needs restoring by hand here.
    clapperHeading.style.marginTop = '22px';
    clapperHeading.textContent = gestureText('Clapper');
    root.appendChild(clapperHeading);
    const clapperCard = document.createElement('div');
    clapperCard.className = 'card';
    clapperCard.appendChild(settingRow(strictness));
    root.appendChild(clapperCard);
  }
  const hold = settings.find((s) => s.key === 'gestures.hand_hold_seconds');
  if (hold && !hold.hidden) {
    const heading = document.createElement('h2');
    heading.className = 'card-title';
    heading.textContent = gestureText('Hand Gestures');
    root.appendChild(heading);
    const group = document.createElement('div');
    group.className = 'card';
    group.appendChild(settingRow(hold));
    root.appendChild(group);
  }
}

/* ---- Settings ---- */
// One tab per category, mirroring the device's settings rail. Voice
// Satellite shares the Home Assistant tab, as it shares that pane on the
// device.
export const CATEGORY_TABS = [
  ['tab-navigation', ['Navigation']],
  // The URL Filter page, which no setting draws (url_filter.js).
  ['tab-browser', ['Browser'], { extra: ['URL Filter'] }],
  ['tab-kiosk', ['Kiosk']],
  ['tab-lockdown', ['Lockdown']],
  ['tab-launcher', ['Launcher']],
  ['tab-home', ['Home']],
  ['tab-screenaudio', ['Screen & Audio']],
  ['tab-screensaver', ['Screensaver']],
  ['tab-camera', ['Camera']],
  ['tab-homeassistant', ['Home Assistant']],
  ['tab-sendspin', ['Sendspin']],
  ['tab-dlna', ['DLNA']],
  ['tab-intercom', ['Intercom']],
  ['tab-alarms', ['Alarms']],
  ['tab-calendar', ['Calendar']],
  ['tab-esphome', ['ESPHome']],
  ['tab-leds', ['LED Control']],
  ['device-settings', ['Device'],
    // Read-only reports, filled by loadDeviceInfo: no setting declares
    // them, so the tab names them here.
    { extra: ['Hardware', 'Home Assistant', 'WebView'],
      entryRoot: 'device-pages' }],
];

watchUpdates(['gestures'], loadGestures, { visible: () => !!document.querySelector('#tab-gestures.active') });
document.addEventListener('ks-settings-cached', () => {
  if (document.querySelector('#tab-gestures.active')) loadGestures();
});
