import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const module = readFileSync(new URL('../assets/remote-ui/static/filter_status.js', import.meta.url), 'utf8')
  .replace(/^import .*;$/m, '').replace(/export /g, '');
const overview = readFileSync(new URL('../assets/remote-ui/static/overview.js', import.meta.url), 'utf8');
const paint = overview.slice(overview.indexOf('let haStatusRevision'), overview.indexOf('export function refreshHealth'));

function client(read) {
  let now = 0, visible = true, enabled = true;
  const calls = [], tiles = [];
  const context = vm.createContext({
    Date: { now: () => now },
    cmd: (...args) => { calls.push(args); return read(...args); },
    onOverview: () => visible,
    settingOn: () => enabled,
    paintTile: (...args) => tiles.push(args),
  });
  vm.runInContext(module + '\n' + paint, context);
  return { context, calls, tiles, read: context.readFilterStatus, paint: context.paintHaStatus,
    advance(ms) { now += ms; },
    setVisible(value) { visible = value; },
    setEnabled(value) { enabled = value; },
  };
}
const response = (value) => ({ ok: true, data: JSON.stringify(value) });
const connected = { configured: true, connected: true };

test('the Overview query reads the existing allowlist size without enumerating states or getting full stats', async () => {
  const c = client(async () => response(null));
  const query = vm.runInContext('filterStatusScript', c.context);
  const forbidden = new Proxy({}, { ownKeys() { throw Error('entity scan'); } });
  const filter = { enabled: true, built: true, allow: new Set(['sensor.one', 'sensor.two']),
    shadow: forbidden, stats() { throw Error('full stats'); }, scanDiagnostic() { throw Error('trace'); } };
  const context = vm.createContext({ window: { __ksWs: filter } });
  assert.deepEqual(JSON.parse(vm.runInContext(query, context)), { enabled: true, built: true, allow: 2 });
  filter.allow = null;
  assert.deepEqual(JSON.parse(vm.runInContext(query, context)), { enabled: true, built: true, allow: null });
});

test('shows filtered and unfiltered counts while preserving connection-only states', async () => {
  for (const [value, expected, level] of [
    [{ enabled: true, built: true, allow: 42 }, 'Watching 42 entities', 'on'],
    [{ enabled: true, built: true, allow: 1 }, 'Watching 1 entity', 'on'],
    [{ enabled: true, built: true, allow: null }, 'Updates unfiltered', 'warn'],
    [{ enabled: false, built: true, allow: 42 }, 'Filter status unavailable', 'on'],
    [{ enabled: true, built: false, allow: null }, 'Filter status unavailable', 'on'],
    [null, 'Filter status unavailable', 'on'],
  ]) {
    const c = client(async () => response(value));
    await c.paint(connected);
    assert.equal(c.tiles.at(-1)[2], expected);
    assert.equal(c.tiles.at(-1)[1], level);
  }
});

test('disabled optimization, hidden Overview and disconnected HA make no dashboard request', async () => {
  const c = client(() => { throw Error('unexpected request'); });
  c.setEnabled(false);
  await c.paint(connected);
  assert.equal(c.tiles.at(-1)[2], 'Connected');
  assert.equal(c.tiles.at(-1)[1], 'on');
  c.setEnabled(true);
  c.setVisible(false);
  await c.paint(connected);
  c.setVisible(true);
  await c.paint({ configured: true, connected: false });
  assert.equal(c.tiles.at(-1)[2], 'Disconnected');
  await c.paint({ configured: false, connected: false });
  assert.equal(c.tiles.at(-1)[2], 'Not set up');
  assert.equal(c.calls.length, 0);
});

test('shares pending reads and caches results for 30 seconds', async () => {
  let resolve;
  const c = client(() => new Promise(r => { resolve = r; }));
  const first = c.read(true), second = c.read(true);
  assert.equal(c.calls.length, 1);
  assert.equal(c.calls[0][2].timeoutMs, 2000);
  resolve(response({ enabled: true, built: true, allow: 8 }));
  assert.equal((await first).label, 'Watching 8 entities');
  assert.equal(await second, await first);
  c.advance(29999);
  await c.read(true);
  assert.equal(c.calls.length, 1);
  c.advance(1);
  const next = c.read(true);
  assert.equal(c.calls.length, 2);
  resolve(response({ enabled: true, built: true, allow: null }));
  const unfiltered = await next;
  assert.equal(unfiltered.label, 'Updates unfiltered');
  assert.equal(unfiltered.unfiltered, true);
});

test('a late response cannot restore the count after filtering is disabled or HA disconnects', async () => {
  for (const disable of [true, false]) {
    let resolve;
    const c = client(() => new Promise(r => { resolve = r; }));
    const first = c.paint(connected);
    assert.equal(c.tiles.at(-1)[2], 'Checking filter...');
    if (disable) c.setEnabled(false);
    await c.paint(disable ? connected : { configured: true, connected: false });
    resolve(response({ enabled: true, built: true, allow: 9 }));
    await first;
    assert.equal(c.tiles.at(-1)[2], disable ? 'Connected' : 'Disconnected');
  }
});

test('failed reads are cached and double-encoded responses are supported', async () => {
  for (const read of [
    async () => { throw Error('timeout'); },
    async () => ({ ok: false }),
    async () => ({ ok: true, data: 'invalid JSON' }),
  ]) {
    const c = client(read);
    await c.paint(connected);
    assert.equal(c.tiles.at(-1)[2], 'Filter status unavailable');
    await c.paint(connected);
    assert.equal(c.calls.length, 1);
  }
  const c = client(async () => response(JSON.stringify({ enabled: true, built: true, allow: 3 })));
  await c.paint(connected);
  assert.equal(c.tiles.at(-1)[2], 'Watching 3 entities');
});
