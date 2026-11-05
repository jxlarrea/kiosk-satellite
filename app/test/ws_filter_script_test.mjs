import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../lib/managers/browser/ws_filter_script.dart', import.meta.url), 'utf8').split("r'''")[1].split("'''")[0];

async function page({ hook = true, config, deferredConfig = false, states = {},
  entities = {}, devices = {}, areas = {}, registries = {} } = {}) {
  const timers = new Map();
  const listeners = {};
  const frames = [];
  const warnings = [];
  const requests = [];
  const registryCalls = [];
  let nextTimer = 0;
  let define;
  class Root {
    localName = 'hui-view';
    isConnected = true;
    index = 0;
    assignments = 0;
    get hass() { return this.value; }
    set hass(value) { this.value = value; this.assignments++; this.onHass?.(value); }
  }
  class AutoEntities {
    get hass() { return this.value; }
    set hass(value) { this.value = value; }
  }
  class Socket {
    handlers = [];
    send() {}
    addEventListener(type, fn) { if (type === 'message') this.handlers.push(fn); }
    removeEventListener(type, fn) { this.handlers = this.handlers.filter(h => h !== fn); }
    receive(message) { this.handlers.forEach(fn => fn({ data: JSON.stringify(message) })); }
  }
  const cfg = config ?? { views: [
    { path: 'home', cards: [{ type: 'entities', entities: ['sun.sun'] }] },
    { path: 'other', cards: [{ type: 'entities', entities: ['sensor.other'] }] },
  ] };
  const host = { hass: {
    connection: { sendMessagePromise: message => {
      if (message.type !== 'lovelace/config') {
        registryCalls.push(message.type);
        const items = registries[message.type];
        return items ? Promise.resolve(items) : Promise.reject(Error('unknown command'));
      }
      return deferredConfig
        ? new Promise((resolve, reject) => requests.push({ resolve, reject }))
        : Promise.resolve(cfg);
    } },
    panels: { lovelace: { component_name: 'lovelace' }, config: { component_name: 'config' } },
    states: {}, entities, devices, areas,
  } };
  let root = new Root();
  root.lovelace = { config: cfg };
  root.hass = host.hass;
  const document = {
    querySelector: () => host,
    querySelectorAll: () => [root],
    addEventListener: (type, fn) => { listeners[type] = fn; },
  };
  const registry = {
    whenDefined: name => name === 'auto-entities' ? Promise.resolve(AutoEntities)
      : hook ? Promise.resolve(hook === 'incomplete' ? class {} : Root) : new Promise(resolve => { define = resolve; }),
    get: name => name === 'auto-entities' ? AutoEntities
      : hook === 'incomplete' ? class {} : hook ? Root : undefined,
  };
  const context = vm.createContext({
    window: { WebSocket: Socket, customElements: registry,
      addEventListener: (type, fn) => { listeners[type] = fn; } },
    document, location: { pathname: '/lovelace/home' },
    console: { warn: message => warnings.push(message) },
    localStorage: { getItem: () => null },
    setTimeout: fn => { timers.set(++nextTimer, fn); return nextTimer; },
    clearTimeout: id => timers.delete(id),
  });
  vm.runInContext(source, context);
  function connect() {
    const socket = new context.window.WebSocket('http://ha/api/websocket');
    socket.addEventListener('message', ({ data }) => {
      const message = JSON.parse(data);
      frames.push(message);
      if (message.type !== 'event' || message.id !== 1) return;
      const states = { ...host.hass.states };
      for (const [id, s] of Object.entries(message.event.a ?? {})) {
        states[id] = { entity_id: id, state: s.s, attributes: { ...s.a } };
      }
      for (const [id, diff] of Object.entries(message.event.c ?? {})) {
        const added = diff['+'] ?? {};
        states[id] = { ...states[id],
          ...(added.s == null ? {} : { state: added.s }),
          attributes: { ...states[id]?.attributes, ...added.a } };
      }
      for (const id of message.event.r ?? []) delete states[id];
      host.hass = { ...host.hass, states };
      root.hass = host.hass;
    });
    socket.send(JSON.stringify({ id: 1, type: 'subscribe_entities' }));
    return socket;
  }
  let socket = connect();
  function emit(event) { socket.receive({ id: 1, type: 'event', event }); }
  emit({ a: {
    'sun.sun': { s: 'above_horizon' },
    'media_player.dynamic': { s: 'paused', a: { volume_level: 0.2 } },
    'sensor.other': { s: '10' },
    ...states,
  } });
  async function drain() {
    for (let i = 0; i < 30; i++) {
      await Promise.resolve();
      if (!timers.size) { await Promise.resolve(); if (!timers.size) return; }
      const pending = [...timers.values()];
      timers.clear();
      for (const fn of pending) fn();
    }
    throw Error('Timer loop did not settle');
  }
  await drain();
  return {
    context, get root() { return root; }, host, frames, warnings, emit, drain, listeners, requests, registryCalls, cfg, Root, AutoEntities,
    connect() { socket = connect(); },
    api: context.window.__ksWs,
    navigate(path) {
      context.location.pathname = path;
      listeners['location-changed']();
      // The previous view can receive one last hass update before removal.
      root.hass = host.hass;
      root.isConnected = false;
      root = new Root();
      root.index = cfg.views.findIndex(v => v.path === path.split('/')[2]);
      root.lovelace = { config: cfg };
      root.hass = host.hass;
    },
    reconnect() { socket = connect(); },
    define(ctor) { define(ctor); },
  };
}

test('discovers calculated ids, replays stale state and keeps unrelated changes filtered', async () => {
  const p = await page();
  assert.equal(p.api.stats().mode, 'filtering');
  p.emit({ c: { 'media_player.dynamic': { '+': { s: 'playing' } } } });
  assert.equal(p.host.hass.states['media_player.dynamic'].state, 'paused');
  const id = ['media_player', 'dynamic'].join('.');
  assert.equal(p.root.hass.states[id].state, 'paused');
  assert.equal(p.api.allow.has(id), true);
  await p.drain();
  assert.equal(p.root.hass.states[id].state, 'playing');
  p.emit({ c: {
    [id]: { '+': { a: { volume_level: 0.4 } } },
    'sensor.other': { '+': { s: '20' } },
  } });
  assert.equal(p.root.hass.states[id].attributes.volume_level, 0.4);
  assert.equal(p.host.hass.states['sensor.other'].state, '10');
  assert.equal(p.api.allow.size, 2);
});

test('preserves hass and state identity without tracking the global HA store', async () => {
  const p = await page();
  const original = p.host.hass;
  const wrapped = p.root.hass;
  p.root.hass = original;
  assert.equal(p.root.hass, wrapped);
  p.root.hass = wrapped;
  assert.equal(p.root.hass, wrapped);
  assert.equal(p.root.hass.connection, original.connection);
  assert.equal(p.root.hass.states['sun.sun'], original.states['sun.sun']);
  Object.values(original.states);
  assert.equal(p.api.stats().runtimeAll, false);
  assert.equal(p.api.allow.has('sensor.other'), false);
  p.emit({ c: { 'sun.sun': { '+': { s: 'below_horizon' } } } });
  assert.notEqual(p.root.hass, wrapped);
  assert.equal(p.root.hass.states['sensor.other'], original.states['sensor.other']);
});

test('starts filtering a view whose only entity ids are calculated at runtime', async () => {
  const p = await page({ config: { views: [{ path: 'home', cards: [
    { type: 'custom:calculated-player', domain: 'media_player', name: 'dynamic' },
  ] }] } });
  assert.equal(p.api.allow, null);
  void p.root.hass.states[['media_player', 'dynamic'].join('.')];
  await p.drain();
  assert.equal(p.api.stats().mode, 'filtering');
  assert.equal(p.api.allow.size, 1);
  assert.equal(p.api.allow.has('media_player.dynamic'), true);
});

test('stands down for a view that reads most of the instance (issue #570)', async () => {
  const p = await page({ config: { views: [{ path: 'home', cards: [
    { type: 'area', area: 'kitchen', features: [{ type: 'area-controls' }] },
  ] }] } });
  const a = {};
  for (let i = 0; i < 200; i++) a[`sensor.s${i}`] = { s: String(i) };
  p.emit({ a });
  await p.drain();
  // 40 of 203: an ordinary view, filtering as before.
  for (let i = 0; i < 40; i++) void p.root.hass.states[`sensor.s${i}`];
  await p.drain();
  assert.equal(p.api.stats().mode, 'filtering');
  assert.equal(p.api.allow.size, 40);
  assert.equal(p.api.stats().standDown, null);
  // 125 of 203: most of the instance, nothing left to filter.
  for (let i = 40; i < 125; i++) void p.root.hass.states[`sensor.s${i}`];
  await p.drain();
  const st = p.api.stats();
  assert.equal(st.mode, 'passthrough');
  assert.equal(st.runtimeAll, true);
  assert.equal(JSON.stringify(st.standDown), JSON.stringify({ reads: 125, total: 203 }));
  assert.equal(p.api.allow, null);
  assert.equal(p.api.standDown.total, 203);
  // No scan happened: no trace, no console warning.
  assert.equal(p.api.scanDiagnostic(), null);
  assert.equal(p.warnings.length, 0);
  // The components get the plain hass back: further reads are not tracked.
  for (let i = 125; i < 175; i++) void p.root.hass.states[`sensor.s${i}`];
  assert.equal(p.api.stats().runtimeEntities, 125);
  // Updates flow through untouched.
  p.emit({ c: { 'sensor.s190': { '+': { s: 'x' } } } });
  assert.equal(p.host.hass.states['sensor.s190'].state, 'x');
  // Another view starts over.
  p.navigate('/lovelace/other');
  await p.drain();
  assert.equal(p.api.stats().standDown, null);
  assert.equal(p.api.standDown, null);
});

test('full scans lift filtering and refresh candidates before future state changes', async () => {
  const p = await page();
  p.emit({ c: { 'media_player.dynamic': { '+': { s: 'playing' } } } });
  const selected = Object.values(p.root.hass.states).filter(s => s.state === 'playing');
  assert.equal(selected.length, 0);
  assert.equal(p.api.allow, null);
  assert.equal(p.api.stats().runtimeAll, true);
  await p.drain();
  assert.equal(Object.values(p.root.hass.states).filter(s => s.state === 'playing').length, 1);
  p.emit({ c: { 'sensor.other': { '+': { s: '20' } } } });
  assert.equal(p.host.hass.states['sensor.other'].state, '20');
  p.api.setEnabled(false);
  p.api.setEnabled(true);
  assert.equal(p.api.allow, null);
});

test('captures a caller trace once and leaves it out of polled stats', async () => {
  const p = await page();
  assert.equal(p.api.scanDiagnostic(), null);
  p.context.statesToScan = p.root.hass.states;
  vm.runInContext('function buildEntityList() { return Object.values(statesToScan); } buildEntityList();',
    p.context, { filename: 'https://ha/local/example-card.js' });
  const details = p.api.scanDiagnostic();
  assert.match(details, /View: \/lovelace\/home/);
  assert.match(details, /buildEntityList.*example-card\.js/);
  assert.match(details, /does not identify the exact card instance/);
  assert.equal(p.warnings.length, 1);
  assert.equal(p.warnings[0], '[Kiosk Satellite] ' + details);
  assert.equal(JSON.stringify(p.api.stats()).includes('example-card.js'), false);
  await p.drain();
  assert.equal(p.api.stats().mode, 'passthrough');
});

test('reads and updates never capture stacks and repeated scans capture only once per visit', async () => {
  const p = await page();
  let captures = 0, formats = 0;
  p.context.Error = class {
    constructor() { captures++; }
    get stack() { formats++; return 'example-card.js:42:5'; }
  };
  for (let i = 0; i < 1000; i++) {
    void p.root.hass.states['sun.sun'];
    void ('sun.sun' in p.root.hass.states);
    Object.getOwnPropertyDescriptor(p.root.hass.states, 'sun.sun');
    p.emit({ c: { 'sun.sun': { '+': { s: String(i) } },
      'sensor.other': { '+': { s: String(i) } } } });
  }
  assert.equal(p.root.hass.states['sun.sun'].state, '999');
  assert.equal(p.host.hass.states['sensor.other'].state, '10');
  assert.equal(captures, 0);
  assert.equal(formats, 0);
  assert.equal(p.warnings.length, 0);
  const old = p.root.hass.states;
  for (let i = 0; i < 50; i++) Object.keys(old);
  await p.drain();
  p.api.reset();
  p.api.setEnabled(false);
  p.api.setEnabled(true);
  p.reconnect();
  await p.drain();
  for (let i = 0; i < 50; i++) {
    Object.values(old);
    p.api.scanDiagnostic();
    p.api.stats();
    p.emit({ c: { 'sensor.other': { '+': { s: String(i) } } } });
  }
  assert.equal(p.host.hass.states['sensor.other'].state, '49');
  assert.equal(captures, 1);
  assert.equal(formats, 1);
  assert.equal(p.warnings.length, 1);
  p.navigate('/lovelace/other');
  await p.drain();
  assert.equal(p.api.scanDiagnostic(), null);
  Object.values(old);
  assert.equal(p.api.scanDiagnostic(), null);
  assert.equal(captures, 1);
  Object.keys(p.root.hass.states);
  assert.equal(captures, 2);
  assert.equal(formats, 2);
  assert.equal(p.warnings.length, 2);
  assert.match(p.api.scanDiagnostic(), /View: \/lovelace\/other/);
});

test('bounds diagnostic storage and console output without changing the global stack limit', async () => {
  const p = await page();
  p.context.Error = class {
    static stackTraceLimit = 7;
    get stack() { return 'x'.repeat(20000); }
  };
  Object.keys(p.root.hass.states);
  assert.ok(p.api.scanDiagnostic().length < 5000);
  assert.match(p.api.scanDiagnostic(), /x{4084}\n\[truncated\]/);
  assert.equal(p.warnings.length, 1);
  assert.ok(p.warnings[0].length < 5000);
  assert.equal(p.context.Error.stackTraceLimit, 7);
});

test('unavailable or broken stack capture and logging never interrupt state delivery', async () => {
  for (const kind of ['missing', 'getter throws', 'constructor throws']) {
    const p = await page();
    p.context.Error = class {
      constructor() { if (kind === 'constructor throws') throw 'capture failed'; }
      get stack() { if (kind === 'getter throws') throw 'format failed'; }
    };
    p.context.console.warn = () => { throw 'console failed'; };
    p.emit({ c: { 'sensor.other': { '+': { s: '20' } } } });
    assert.doesNotThrow(() => Object.values(p.root.hass.states));
    assert.match(p.api.scanDiagnostic(), /Stack trace unavailable/);
    await p.drain();
    assert.equal(p.api.stats().mode, 'passthrough');
    assert.equal(p.api.stats().runtimeFailure, null);
    assert.equal(p.host.hass.states['sensor.other'].state, '20');
    p.emit({ c: { 'sensor.other': { '+': { s: '30' } } } });
    assert.equal(p.host.hass.states['sensor.other'].state, '30');
  }
});

test('does not capture traces while filtering is disabled', async () => {
  const p = await page();
  const tracked = p.root.hass.states;
  p.api.setEnabled(false);
  let captures = 0;
  p.context.Error = class { constructor() { captures++; } };
  Object.keys(tracked);
  assert.equal(captures, 0);
  assert.equal(p.warnings.length, 0);
  assert.equal(p.api.scanDiagnostic(), null);
});

test('tracks existence and property descriptor reads including entities created later', async () => {
  const p = await page();
  assert.equal('sensor.future' in p.root.hass.states, false);
  Object.getOwnPropertyDescriptor(p.root.hass.states, 'media_player.dynamic');
  assert.equal(p.api.allow.has('sensor.future'), true);
  assert.equal(p.api.allow.has('media_player.dynamic'), true);
  p.emit({ a: { 'sensor.future': { s: 'new' } } });
  p.emit({ c: { 'sensor.future': { '+': { s: 'changed' } } } });
  assert.equal(p.host.hass.states['sensor.future'].state, 'changed');
  p.emit({ r: ['sensor.future'] });
  assert.equal(p.host.hass.states['sensor.future'], undefined);
});

test('retains runtime dependencies when config is rebuilt', async () => {
  const p = await page();
  void p.root.hass.states['media_player.dynamic'];
  p.api.setEnabled(false);
  p.api.setEnabled(true);
  await p.drain();
  assert.equal(p.api.allow.has('media_player.dynamic'), true);
});

test('navigation resets discovery and ignores reads through previous view references', async () => {
  const p = await page();
  const oldView = p.root;
  oldView.onHass = hass => Object.values(hass.states);
  const old = p.root.hass;
  Object.values(old.states);
  oldView.hass = p.host.hass;
  await p.drain();
  p.navigate('/lovelace/other');
  p.root.hass = p.host.hass;
  void p.root.hass.states['sensor.other'];
  await p.drain();
  assert.equal(p.api.stats().runtimeAll, false);
  assert.equal(p.api.stats().mode, 'filtering');
  Object.values(old.states);
  assert.equal(p.api.stats().runtimeAll, false);
  assert.equal(p.api.allow.has('media_player.dynamic'), false);
  p.navigate('/config/devices');
  await p.drain();
  assert.equal(p.api.allow, null);
});

test('passes through while the hook is unavailable and attaches after registry replacement', async () => {
  const p = await page({ hook: false });
  assert.equal(p.api.allow, null);
  p.emit({ c: { 'media_player.dynamic': { '+': { s: 'playing' } } } });
  assert.equal(p.host.hass.states['media_player.dynamic'].state, 'playing');
  p.context.window.customElements = {
    whenDefined: () => Promise.resolve(p.Root), get: () => p.Root,
  };
  p.listeners.DOMContentLoaded();
  await p.drain();
  assert.equal(p.api.stats().runtimeTracking, true);
  assert.equal(p.api.stats().mode, 'filtering');
  p.define(class {});
  await p.drain();
  assert.equal(p.api.stats().runtimeTracking, true);
  assert.equal(p.api.stats().runtimeFailure, null);
});

test('falls back for incompatible frozen hass objects', async () => {
  const p = await page();
  const frozen = Object.freeze({ ...p.host.hass });
  p.root.hass = frozen;
  assert.equal(p.root.hass, frozen);
  assert.equal(p.api.allow, null);
  await p.drain();
  assert.equal(p.api.stats().runtimeTracking, false);
});

test('recovers when a scoped registry placeholder is replaced by the real dashboard class', async () => {
  const p = await page({ hook: 'incomplete' });
  assert.equal(p.api.stats().runtimeTracking, false);
  assert.equal(p.api.stats().runtimeFailure, 'hass accessor unavailable');
  p.context.window.customElements = {
    whenDefined: () => Promise.resolve(p.Root), get: () => p.Root,
  };
  p.listeners.DOMContentLoaded();
  await p.drain();
  assert.equal(p.api.stats().runtimeTracking, true);
  assert.equal(p.api.stats().runtimeFailure, null);
  assert.equal(p.api.stats().mode, 'filtering');
});

test('does not let a late dashboard config restore filtering for an old view', async () => {
  const p = await page({ deferredConfig: true });
  p.navigate('/config/devices');
  p.requests.forEach(r => r.resolve(p.cfg));
  await p.drain();
  assert.equal(p.api.allow, null);
});

test('reconnect cancels queued replay even when the subscription id is reused', async () => {
  const p = await page();
  p.emit({ c: { 'media_player.dynamic': { '+': { s: 'playing' } } } });
  void p.root.hass.states['media_player.dynamic'];
  p.reconnect();
  p.frames.length = 0;
  await p.drain();
  assert.equal(p.frames.length, 0);
});

test('repeated injection does not wrap the dashboard setter again', async () => {
  const p = await page();
  const setter = Object.getOwnPropertyDescriptor(p.Root.prototype, 'hass').set;
  vm.runInContext(source, p.context);
  assert.equal(Object.getOwnPropertyDescriptor(p.Root.prototype, 'hass').set, setter);
});

const groupView = { views: [{ path: 'home', cards: [{ type: 'custom:auto-entities',
  filter: { include: [{ group: 'group.lights', state: 'on' }] }, card: { type: 'entities' } }] }] };
const groupStates = {
  'group.lights': { s: 'on', a: { entity_id: ['light.a'] } },
  'light.a': { s: 'on' },
  'light.b': { s: 'off' },
};

test('resolves auto-entities group filters to the group members (issue #1170)', async () => {
  const p = await page({ config: groupView, states: groupStates });
  assert.equal(p.api.stats().mode, 'filtering');
  assert.equal(p.api.allow.has('light.a'), true);
  assert.equal(p.api.allow.has('group.lights'), true);
  assert.equal(p.api.allow.has('light.b'), false);
  p.emit({ c: { 'light.b': { '+': { s: 'on' } } } });
  assert.equal(p.host.hass.states['light.b'].state, 'off');
});

test('rebuilds the allowlist when an auto-entities group gains a member', async () => {
  const p = await page({ config: groupView, states: groupStates });
  p.emit({ c: { 'group.lights': { '+': { a: { entity_id: ['light.a', 'light.b'] } } } } });
  await p.drain();
  assert.equal(p.api.allow.has('light.b'), true);
  p.emit({ c: { 'light.b': { '+': { s: 'on' } } } });
  assert.equal(p.host.hass.states['light.b'].state, 'on');
});

test('hands auto-entities the plain hass so its own scan keeps the view filtered', async () => {
  const p = await page({ config: groupView, states: groupStates });
  const card = new p.AutoEntities();
  card.hass = p.root.hass;
  assert.equal(card.hass, p.host.hass);
  Object.keys(card.hass.states).forEach(id => card.hass.states[id]);
  assert.equal(p.api.stats().runtimeAll, false);
  assert.equal(p.api.stats().mode, 'filtering');
  assert.equal(p.api.allow.has('light.b'), false);
});

const autoView = (...include) => ({ views: [{ path: 'home', cards: [{ type: 'custom:auto-entities',
  filter: { include }, card: { type: 'entities' } }] }] });
const sensorStates = {
  'sensor.door_battery': { s: '20', a: { device_class: 'battery', unit_of_measurement: '%' } },
  'sensor.phone_battery': { s: '80', a: { device_class: 'battery', unit_of_measurement: '%' } },
  'sensor.power': { s: '150', a: { device_class: 'power', unit_of_measurement: 'W' } },
  'sensor.riemann': { s: '1', a: {} },
  'sensor.other': { s: '10', a: {} },
};
const allowed = p => [...p.api.allow].filter(id => id !== 'sun.sun').sort();

test('narrows an auto-entities include by a fixed attribute (issue #1314)', async () => {
  const p = await page({ states: sensorStates, config: autoView(
    { domain: 'sensor', attributes: { device_class: 'battery' }, state: '< 25' }) });
  assert.equal(p.api.stats().mode, 'filtering');
  assert.deepEqual(allowed(p), ['sensor.door_battery', 'sensor.phone_battery']);
  p.emit({ c: { 'sensor.power': { '+': { s: '151' } } } });
  assert.equal(p.host.hass.states['sensor.power'].state, '150');
  p.emit({ c: { 'sensor.door_battery': { '+': { s: '19' } } } });
  assert.equal(p.host.hass.states['sensor.door_battery'].state, '19');
});

test('an entity with no known attributes stays on the list', async () => {
  const p = await page({ states: { ...sensorStates, 'sensor.other': { s: '10' } }, config: autoView(
    { domain: 'sensor', attributes: { device_class: 'battery' } }) });
  assert.equal(p.api.allow.has('sensor.other'), true);
});

test('a fixed attribute alone is enough to filter the view', async () => {
  const p = await page({ states: sensorStates, config: autoView(
    { attributes: { unit_of_measurement: 'W' } }) });
  assert.equal(p.api.stats().mode, 'filtering');
  assert.deepEqual(allowed(p), ['sensor.power']);
});

test('fixed attributes match globs and regexes the way auto-entities does', async () => {
  const p = await page({ states: sensorStates, config: autoView(
    { domain: 'sensor', attributes: { device_class: '*atter*' } },
    { domain: 'sensor', attributes: { device_class: '/^pow/' } }) });
  assert.deepEqual(allowed(p), ['sensor.door_battery', 'sensor.phone_battery', 'sensor.power']);
});

test('attribute tests that cannot be resolved never narrow an include', async () => {
  for (const attributes of [
    { device_class: '!= 5' }, { unit_of_measurement: '< 5' }, { device_class: '$$"x"' },
    { device_class: 5 }, { 'device_class 2': 'battery' }, { battery_level: 'low' },
    { friendly_name: 'Door' },
  ]) {
    const p = await page({ states: sensorStates, config: autoView({ domain: 'sensor', attributes }) });
    assert.equal(allowed(p).length, 5, JSON.stringify(attributes));
  }
});

test('rebuilds when an unlisted entity gains a fixed attribute later', async () => {
  const p = await page({ states: sensorStates, config: autoView(
    { domain: 'sensor', attributes: { unit_of_measurement: 'W' } }) });
  assert.equal(p.api.allow.has('sensor.riemann'), false);
  p.emit({ c: { 'sensor.riemann': { '+': { s: '2', a: { unit_of_measurement: 'W' } } } } });
  await p.drain();
  assert.equal(p.api.allow.has('sensor.riemann'), true);
  assert.equal(p.host.hass.states['sensor.riemann'].attributes.unit_of_measurement, 'W');
  assert.equal(p.host.hass.states['sensor.riemann'].state, '2');
});

test('other attribute changes on unlisted entities do not rebuild', async () => {
  const p = await page({ states: sensorStates, config: autoView(
    { domain: 'sensor', attributes: { unit_of_measurement: 'W' } }) });
  const frames = p.frames.length;
  p.emit({ c: { 'sensor.door_battery': { '+': { a: { friendly_name: 'Door' } } } } });
  await p.drain();
  assert.equal(p.frames.length, frames);
});

const registryEntities = {
  'light.a': { entity_id: 'light.a', platform: 'hue', device_id: 'd1', labels: [] },
  'light.b': { entity_id: 'light.b', platform: 'hue', labels: ['kitchen_lights'] },
  'light.c': { entity_id: 'light.c', platform: 'zha', labels: [] },
  'sensor.other': { entity_id: 'sensor.other', platform: 'template', labels: [] },
};
const registryStates = { 'light.a': { s: 'on' }, 'light.b': { s: 'on' }, 'light.c': { s: 'on' } };
const registryDevices = { d1: { id: 'd1', name: 'Lamp', labels: ['kitchen_lights'] } };
const labelRegistry = [{ label_id: 'kitchen_lights', name: 'Kitchen Lights' }];
const entityRegistry = [
  { entity_id: 'light.a', config_entry_id: 'entryA' }, { entity_id: 'light.b', config_entry_id: 'entryB' },
  { entity_id: 'light.c', config_entry_id: 'entryA' }, { entity_id: 'sensor.other', config_entry_id: null },
];
const registryPage = (rule, registries = {
  'config/label_registry/list': labelRegistry, 'config/entity_registry/list': entityRegistry,
}) => page({ states: registryStates, entities: registryEntities, devices: registryDevices,
  registries, config: autoView(rule) });

test('label rules reach entities through their device', async () => {
  const p = await registryPage({ label: 'kitchen_lights' });
  await p.drain();
  assert.equal(p.api.stats().mode, 'filtering');
  assert.deepEqual(allowed(p), ['light.a', 'light.b']);
});

test('label rules match the label name', async () => {
  const p = await registryPage({ label: 'Kitchen Lights' });
  await p.drain();
  assert.equal(p.api.stats().mode, 'filtering');
  assert.deepEqual(allowed(p), ['light.a', 'light.b']);
});

test('integration rules match the config entry the visual editor saves', async () => {
  const p = await registryPage({ integration: 'entryA' });
  await p.drain();
  assert.equal(p.api.stats().mode, 'filtering');
  assert.deepEqual(allowed(p), ['light.a', 'light.c']);
});

test('integration rules still match the platform name', async () => {
  const p = await registryPage({ integration: 'hue' });
  await p.drain();
  assert.deepEqual(allowed(p), ['light.a', 'light.b']);
});

test('a view stays unfiltered when a registry it needs cannot be read', async () => {
  for (const rule of [{ label: 'kitchen_lights' }, { integration: 'entryA' }]) {
    const p = await registryPage(rule, {});
    await p.drain();
    assert.equal(p.api.allow, null, JSON.stringify(rule));
  }
});

test('registries load once per socket and again after a reconnect', async () => {
  const p = await registryPage({ label: 'kitchen_lights' });
  await p.drain();
  p.navigate('/lovelace/home');
  await p.drain();
  assert.deepEqual(p.registryCalls, ['config/label_registry/list']);
  p.connect();
  await p.drain();
  assert.deepEqual(p.registryCalls, ['config/label_registry/list', 'config/label_registry/list']);
});

test('structural rules accept globs and regexes the way auto-entities does', async () => {
  for (const [rule, ids] of [
    [{ domain: '/^li/' }, ['light.a', 'light.b', 'light.c']],
    [{ domain: 'li*' }, ['light.a', 'light.b', 'light.c']],
    [{ entity_id: '/light\\.[ab]$/' }, ['light.a', 'light.b']],
    [{ entity_id: 'light.*' }, ['light.a', 'light.b', 'light.c']],
    [{ device: 'La*' }, ['light.a']],
    [{ integration: '/^zh/' }, ['light.c']],
    [{ label: 'kitchen*' }, ['light.a', 'light.b']],
  ]) {
    const p = await registryPage(rule);
    await p.drain();
    assert.equal(p.api.stats().mode, 'filtering', JSON.stringify(rule));
    assert.deepEqual(allowed(p), ids, JSON.stringify(rule));
  }
});

test('a structural rule with a comparison or time value passes the view through', async () => {
  for (const rule of [{ domain: '!light' }, { area: '< 5' }, { entity_id: '$$x' }, { device: '5 m ago' },
    { domain: '/(/' }]) {
    const config = autoView(rule);
    config.views[0].cards.push({ type: 'entities', entities: ['sensor.other'] });
    const p = await page({ states: registryStates, entities: registryEntities,
      devices: registryDevices, config });
    await p.drain();
    assert.equal(p.api.allow, null, JSON.stringify(rule));
  }
});

test('a custom page under /local/ keeps its own sockets and says so', () => {
  class Socket {}
  const window = { WebSocket: Socket };
  const context = vm.createContext({ window, location: { pathname: '/local/wall.html' },
    document: { addEventListener() {} } });
  vm.runInContext(source, context);
  assert.equal(window.WebSocket, Socket);
  assert.equal(window.__ksWs.customPage, true);
  assert.equal(window.__ksWs.stats().mode, 'custom-page');
});
