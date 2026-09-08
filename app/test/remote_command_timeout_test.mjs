import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../assets/remote-ui/static/core.js', import.meta.url), 'utf8');
const command = source.slice(source.indexOf('export async function cmd('), source.indexOf('/* ---- Views ---- */'))
  .replace('export ', '');

function client(api) {
  const timers = new Set();
  const context = vm.createContext({
    api, AbortController,
    setTimeout(callback, ms) {
      const timer = setTimeout(callback, ms);
      timers.add(timer);
      return timer;
    },
    clearTimeout(timer) { timers.delete(timer); clearTimeout(timer); },
  });
  vm.runInContext(command, context);
  return { cmd: context.cmd, timers };
}

test('a hung command is aborted and releases its timer', async () => {
  let signal;
  const c = client((path, options) => {
    assert.equal(path, '/api/commands/vsControls');
    signal = options.signal;
    return new Promise((resolve, reject) => {
      signal.addEventListener('abort', () => reject(new Error('aborted')));
    });
  });
  await assert.rejects(c.cmd('vsControls', {}, { timeoutMs: 20 }), /aborted/);
  assert.equal(signal.aborted, true);
  assert.equal(c.timers.size, 0);
});

test('the timeout covers a stalled response body too', async () => {
  const c = client(async (path, { signal }) => ({
    json: () => new Promise((resolve, reject) => {
      signal.addEventListener('abort', () => reject(new Error('aborted body')));
    }),
  }));
  await assert.rejects(c.cmd('vsControls', {}, { timeoutMs: 20 }), /aborted body/);
  assert.equal(c.timers.size, 0);
});

test('successful commands return their result and cancel the timeout', async () => {
  const c = client(async () => ({ json: async () => ({ ok: true, data: 42 }) }));
  assert.deepEqual(await c.cmd('vsControls', {}, { timeoutMs: 20 }), { ok: true, data: 42 });
  assert.equal(c.timers.size, 0);
});

test('commands without an explicit deadline do not time out long operations', async () => {
  const c = client(async () => ({ json: async () => ({ ok: true }) }));
  await c.cmd('installUpdate');
  assert.equal(c.timers.size, 0);
});
