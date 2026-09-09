import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../lib/managers/browser/ws_filter_script.dart', import.meta.url), 'utf8').split("r'''")[1].split("'''")[0];

async function page({ hook = true, config, deferredConfig = false } = {}) {
  const timers = new Map();
  const listeners = {};
  const frames = [];
  const warnings = [];
  const requests = [];
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
    connection: { sendMessagePromise: () => deferredConfig
      ? new Promise((resolve, reject) => requests.push({ resolve, reject }))
      : Promise.resolve(cfg) },
    panels: { lovelace: { component_name: 'lovelace' }, config: { component_name: 'config' } },
    states: {}, entities: {},
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
    whenDefined: () => hook ? Promise.resolve(hook === 'incomplete' ? class {} : Root) : new Promise(resolve => { define = resolve; }),
    get: () => hook === 'incomplete' ? class {} : hook ? Root : undefined,
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
    context, get root() { return root; }, host, frames, warnings, emit, drain, listeners, requests, cfg, Root,
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
