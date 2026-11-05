import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { runInNewContext } from 'node:vm';

const source = readFileSync(new URL(
  '../lib/managers/home_assistant/home_assistant_manager.dart', import.meta.url,
), 'utf8');
const template = source.match(
  /\(function \(\) \{\n  var base = \$\{jsonEncode\(effectiveBase\)\};[\s\S]*?\}\)\(\);/,
)[0];

function navigate(start, target, origin = 'http://ha.test:8123') {
  const [, pathname, search, hash] = start.match(/^([^?#]*)(\?[^#]*)?(#.*)?$/);
  const location = {
    origin, pathname, href: origin + start, search: search ?? '', hash: hash ?? '',
  };
  const calls = [];
  // No custom pages on other servers, so no origin counts as one.
  const script = template
    .replace('${jsonEncode(effectiveBase)}', JSON.stringify('http://ha.test:8123'))
    .replace('${_onExternalPageJs()}', '[].indexOf(location.origin) >= 0')
    .replace('${jsonEncode(viewPath)}', JSON.stringify(target))
    .replace('${jsonEncode(viewRoute(viewPath))}', JSON.stringify(target.split(/[?#]/)[0]));
  const result = runInNewContext(script, {
    location,
    history: {
      pushState(state, title, path) {
        calls.push(['pushState', state, title, path]);
        location.pathname = path;
      },
    },
    window: { dispatchEvent(event) { calls.push(['event', event.type]); } },
    CustomEvent: class { constructor(type) { this.type = type; } },
  });
  return { result, path: location.pathname, calls };
}

test('a dashboard root opens from its Area pages and other child views', () => {
  for (const [start, target] of [
    ['/home/areas-salon', 'home'],
    ['/home/areas-bedroom', 'home'],
    ['/home/overview', 'home'],
    ['/lovelace/kitchen', 'lovelace'],
    ['/home/', 'home'],
  ]) {
    const actual = navigate(start, target);
    assert.deepEqual(actual, {
      result: 'navigated',
      path: '/' + target,
      calls: [
        ['pushState', null, '', '/' + target],
        ['event', 'location-changed'],
      ],
    }, `${start} -> ${target}`);
  }
});

test('only the exact destination is already open', () => {
  for (const target of ['home', 'home/overview', 'lovelace/kitchen']) {
    assert.deepEqual(navigate('/' + target, target), {
      result: 'already', path: '/' + target, calls: [],
    });
  }
});

test('a page with a popup hash is not on the same view without one', () => {
  const { result, path, calls } = navigate('/dashboard/home#room', 'dashboard/home');
  assert.equal(result, 'navigated');
  assert.equal(path, '/dashboard/home');
  assert.deepEqual(calls.at(-1), ['event', 'location-changed']);
});

test('a configured popup hash opens, and is already open when it matches', () => {
  assert.equal(navigate('/dashboard/home', 'dashboard/home#room').result, 'navigated');
  assert.equal(navigate('/dashboard/home#other', 'dashboard/home#room').result, 'navigated');
  assert.equal(navigate('/dashboard/home#room', 'dashboard/home#room').result, 'already');
});

test('a query on the page alone still counts as the same view', () => {
  assert.equal(navigate('/dashboard/home?kiosk', 'dashboard/home').result, 'already');
  assert.equal(navigate('/dashboard/home?kiosk', 'dashboard/home?kiosk').result, 'already');
});

test('Summary pages, explicit views and parent views still navigate', () => {
  for (const [start, target] of [
    ['/light', 'home'],
    ['/home/areas-salon', 'home/overview'],
    ['/lovelace/kitchen/details', 'lovelace/kitchen'],
    ['/home/overview-extra', 'home/overview'],
  ]) {
    const actual = navigate(start, target);
    assert.equal(actual.result, 'navigated', `${start} -> ${target}`);
    assert.equal(actual.path, '/' + target);
    assert.equal(actual.calls.length, 2);
  }
});

test('navigation leaves another origin untouched', () => {
  assert.deepEqual(navigate('/home/areas-salon', 'home', 'https://other.test'), {
    result: 'off-origin', path: '/home/areas-salon', calls: [],
  });
});

test("an app's sidebar panel opens from a dashboard and back", () => {
  for (const [start, target] of [
    ['/home-tablet/0', '1e25efb6_panalume'],
    ['/1e25efb6_panalume', 'home-tablet/0'],
  ]) {
    const actual = navigate(start, target);
    assert.equal(actual.result, 'navigated', `${start} -> ${target}`);
    assert.equal(actual.path, '/' + target);
  }
  assert.equal(navigate('/1e25efb6_panalume', '1e25efb6_panalume').result, 'already');
});
