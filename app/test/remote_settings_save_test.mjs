import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../assets/remote-ui/static/rows.js', import.meta.url), 'utf8');
const errors = source.slice(source.indexOf('function showRowError('), source.indexOf('function albumArtCacheRow('));
const start = source.indexOf('  const save = async (value) => {');
const save = source.slice(start, source.indexOf('\n  };', start) + '\n  };'.length);

class Element {
  constructor(tagName) {
    this.tagName = tagName.toUpperCase();
    this.children = [];
    this.listeners = {};
  }
  set textContent(value) { this.text = value; this.children = []; }
  get textContent() { return this.text; }
  appendChild(child) { child.parent = this; this.children.push(child); }
  querySelector(selector) {
    return this.children.find(child => selector.startsWith('.')
      ? child.className === selector.slice(1)
      : selector.split(', ').includes(child.tagName.toLowerCase())) ?? null;
  }
  remove() { this.parent.children = this.parent.children.filter(child => child !== this); }
  addEventListener(name, callback) { this.listeners[name] = callback; }
  dispatchEvent(event) { return this.listeners[event.type]?.(event); }
}

function client(key = 'browser.inject_js', { tag = 'textarea', type = 'textarea', value = 'old code', settingType = 'string' } = {}) {
  const row = new Element('div');
  const control = new Element(tag);
  Object.assign(control, { type, value, checked: value === true });
  row.appendChild(control);
  const cached = { key, type: settingType, value };
  const requests = [];
  let respond;
  let layoutUpdates = 0;
  const context = vm.createContext({
    s: cached, state: { settings: [cached] }, row, Event,
    document: { createElement: tag => new Element(tag) },
    api: async (path, options) => {
      assert.equal(path, '/api/settings');
      assert.equal(options.method, 'PATCH');
      requests.push(JSON.parse(options.body));
      return respond();
    },
    gatedOn: () => { layoutUpdates++; return []; },
  });
  vm.runInContext(errors + '\n' + save + '\nglobalThis.save = save;', context);
  return {
    row, control, cached, requests, save: context.save,
    respondWith(callback) { respond = callback; },
    error: () => row.querySelector('.row-error'),
    retry: () => row.querySelector('.row-error')?.querySelector('button'),
    layoutUpdates: () => layoutUpdates,
  };
}

const response = (body, ok = true) => ({ ok, json: async () => body });
const success = () => response({ ok: true, rejected: [], errors: {} });
const failures = [
  ['validation rejection', key => response({ ok: false, rejected: [key], errors: { [key]: 'Invalid value' } }), 'Invalid value'],
  ['HTTP error with JSON', () => response({ error: 'Storage failed' }, false), 'Storage failed'],
  ['HTTP error with a success body', () => response({ ok: true }, false), 'Could not save'],
  ['HTTP error with HTML', () => ({ ok: false, json: async () => { throw new SyntaxError('HTML response'); } }), 'Could not save'],
  ['unreadable success response', () => ({ ok: true, json: async () => { throw new SyntaxError('Invalid JSON'); } }), 'Could not save'],
  ['missing API result', () => response({}), 'Could not save'],
  ['null API result', () => response(null), 'Could not save'],
  ['API failure without rejected keys', () => response({ ok: false }), 'Could not save'],
  ['rejected key with a success flag', key => response({ ok: true, rejected: [key] }), 'Could not save'],
  ['network failure', () => { throw new TypeError('Failed to fetch'); }, 'Failed to fetch'],
];

for (const key of ['browser.inject_js', 'browser.inject_js_external']) {
  for (const [name, fail, message] of failures) {
    test(`${key}: ${name} shows an error and keeps the text for retry`, async () => {
      const c = client(key);
      const pasted = Array.from({ length: 50 }, (_, i) => `console.log('Line ${i}');`).join('\n');
      c.control.value = pasted;
      c.respondWith(() => fail(key));
      await c.save(pasted);
      assert.equal(c.cached.value, 'old code');
      assert.equal(c.control.value, pasted);
      assert.ok(c.error().textContent.includes(message));
      assert.equal(c.retry().textContent, 'Retry');
      assert.equal(c.layoutUpdates(), 0);

      c.respondWith(success);
      await c.retry().dispatchEvent(new Event('click'));
      assert.deepEqual(c.requests, [{ [key]: pasted }, { [key]: pasted }]);
      assert.equal(c.cached.value, pasted);
      assert.equal(c.error(), null);
      assert.equal(c.layoutUpdates(), 1);
    });
  }
}

test('text retry sends the latest edit and disables the button while saving', async () => {
  const c = client();
  c.respondWith(() => { throw new Error('Offline'); });
  c.control.value = 'first edit';
  await c.save(c.control.value);
  c.control.value = 'corrected edit';
  let finish;
  c.respondWith(() => new Promise(resolve => { finish = resolve; }));
  const button = c.retry();
  const pending = button.dispatchEvent(new Event('click'));
  assert.equal(button.disabled, true);
  assert.equal(c.cached.value, 'old code');
  assert.equal(c.error().textContent, 'Offline');
  finish(success());
  await pending;
  assert.equal(c.requests[1]['browser.inject_js'], 'corrected edit');
  assert.equal(c.cached.value, 'corrected edit');
  assert.equal(c.error(), null);
});

test('a failed retry leaves one error and an enabled retry button', async () => {
  const c = client();
  c.respondWith(() => { throw new Error('Offline'); });
  await c.save('new code');
  await c.retry().dispatchEvent(new Event('click'));
  assert.equal(c.row.children.filter(child => child.className === 'row-error').length, 1);
  assert.equal(c.error().children.length, 1);
  assert.ok(!c.retry().disabled);
  assert.equal(c.cached.value, 'old code');
});

for (const type of ['text', 'password', 'number']) {
  test(`${type} inputs preserve edits and retry with the correct value type`, async () => {
    const c = client('test.setting', { tag: 'input', type, settingType: type === 'number' ? 'number' : 'string' });
    c.control.value = '42';
    c.respondWith(() => response({ ok: false, rejected: ['test.setting'] }));
    await c.save(type === 'number' ? 42 : '42');
    assert.equal(c.control.value, '42');
    assert.equal(c.cached.value, 'old code');
    c.respondWith(success);
    await c.retry().dispatchEvent(new Event('click'));
    assert.equal(c.cached.value, type === 'number' ? 42 : '42');
  });
}

for (const [tag, type, original, changed] of [
  ['input', 'checkbox', false, true],
  ['select', 'select-one', 'before', 'after'],
  ['input', 'range', 10, 20],
]) {
  test(`${type} controls return to the saved value on failure`, async () => {
    const c = client('test.setting', { tag, type, value: original });
    let repaints = 0;
    c.control.addEventListener('input', () => { repaints++; });
    c.control.value = changed;
    c.control.checked = true;
    c.respondWith(() => response({ error: 'Storage failed' }, false));
    await c.save(changed);
    assert.equal(c.cached.value, original);
    assert.equal(type === 'checkbox' ? c.control.checked : c.control.value, original);
    assert.equal(c.error().textContent, 'Storage failed');
    assert.equal(c.retry(), null);
    assert.equal(repaints, type === 'range' ? 1 : 0);
  });
}

test('a successful save updates the cache without an error or retry button', async () => {
  const c = client();
  c.respondWith(success);
  await c.save('new code');
  assert.equal(c.cached.value, 'new code');
  assert.equal(c.error(), null);
  assert.equal(c.retry(), undefined);
});
