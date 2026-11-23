import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { runInNewContext } from 'node:vm';

// Home Assistant's light or dark set on this device only (issue #1101).
const source = readFileSync(new URL(
  '../lib/managers/browser/color_scheme_script.dart', import.meta.url,
), 'utf8');
const template = source
  .match(/String haColorSchemeJs\(\{required bool\? dark\}\) =>\s*'''([\s\S]*?)''';/)[1]
  .replace(/\\\\/g, '\\');

// A stand-in for the OS answer to prefers-color-scheme, which can flip.
function nativeLists(osDark) {
  const lists = [];
  const matchMedia = (query) => {
    const list = new EventTarget();
    list.media = query;
    const want = /dark/i.test(query);
    Object.defineProperty(list, 'matches', {
      get: () => /prefers-color-scheme/.test(query) && osDark.value === want,
    });
    lists.push(list);
    return list;
  };
  const flip = (next) => {
    osDark.value = next;
    for (const list of lists) list.dispatchEvent(new Event('change'));
  };
  return { matchMedia, flip };
}

// Home Assistant's element class, reduced to the theme step: it records
// what each apply saw, and keeps the profile's choice in hass.selectedTheme.
function haElement(selectedTheme) {
  class HomeAssistant {
    constructor() {
      this.hass = { selectedTheme, themes: {} };
      this.applied = [];
    }
    _applyTheme(darkPreferred) {
      const theme = this.hass.selectedTheme;
      const dark = theme?.dark === undefined ? darkPreferred : theme.dark;
      this.applied.push({ darkPreferred, sawDark: theme?.dark, dark });
      // HA replaces hass while applying, as _updateHass does.
      this.hass = { ...this.hass, themes: { darkMode: dark } };
    }
  }
  return HomeAssistant;
}

async function page({ dark, ha = true, profile = { theme: 'default' }, os = false }) {
  const osDark = { value: os };
  const { matchMedia, flip } = nativeLists(osDark);
  const HomeAssistant = haElement(profile);
  const el = ha ? new HomeAssistant() : null;
  let defined;
  const customElements = {
    whenDefined: () => new Promise((resolve) => { defined = resolve; }),
    get: () => HomeAssistant,
  };
  const window = { matchMedia, customElements };
  const document = { querySelector: (sel) => (sel === 'home-assistant' ? el : null) };
  const run = (value) => runInNewContext(
    template.replace("${dark ?? 'null'}", String(value)),
    { window, document, customElements, EventTarget, Event },
  );
  run(dark);
  // The element gets defined after the document-start script ran.
  defined?.();
  await new Promise((resolve) => setTimeout(resolve, 0));
  return { window, el, flip, run };
}

test('a Home Assistant page answers with the kiosk state', async () => {
  const { window } = await page({ dark: true, os: false });
  assert.equal(window.matchMedia('(prefers-color-scheme: dark)').matches, true);
  assert.equal(window.matchMedia('(prefers-color-scheme: light)').matches, false);
});

test('other pages and queries keep the real answer', async () => {
  const other = await page({ dark: true, ha: false, os: false });
  assert.equal(other.window.matchMedia('(prefers-color-scheme: dark)').matches, false);
  const { window } = await page({ dark: true });
  assert.equal(window.matchMedia('(max-width: 600px)').matches, false);
});

test('null leaves the answer and its changes to the device', async () => {
  const { window, flip } = await page({ dark: null, os: false });
  const list = window.matchMedia('(prefers-color-scheme: dark)');
  const seen = [];
  list.addEventListener('change', (e) => seen.push(e.matches));
  assert.equal(list.matches, false);
  flip(true);
  assert.equal(list.matches, true);
  assert.deepEqual(seen, [true]);
});

test('the device flipping is ignored while the kiosk sets the scheme', async () => {
  const { window, flip } = await page({ dark: false, os: false });
  const list = window.matchMedia('(prefers-color-scheme: dark)');
  let fired = 0;
  list.addEventListener('change', () => fired++);
  flip(true);
  assert.equal(list.matches, false);
  assert.equal(fired, 0);
});

test('a profile set to Light renders dark without being changed', async () => {
  const profile = { theme: 'default', dark: false };
  const { el } = await page({ dark: true, profile });
  el._applyTheme(false);
  assert.deepEqual(el.applied, [{ darkPreferred: true, sawDark: undefined, dark: true }]);
  // The profile choice is back on the hass the element now holds.
  assert.equal(el.hass.selectedTheme, profile);
  assert.deepEqual(profile, { theme: 'default', dark: false });
});

test('with no kiosk state the profile choice holds', async () => {
  const { el } = await page({ dark: null, profile: { theme: 'default', dark: false } });
  el._applyTheme(true);
  assert.deepEqual(el.applied, [{ darkPreferred: true, sawDark: false, dark: false }]);
});

test('a live switch re-renders and fires change', async () => {
  const { window, el } = await page({
    dark: true, profile: { theme: 'default', dark: false }, os: true,
  });
  const list = window.matchMedia('(prefers-color-scheme: dark)');
  const seen = [];
  list.addEventListener('change', (e) => seen.push(e.matches));
  window.__ksHaScheme(false);
  assert.deepEqual(seen, [false]);
  assert.equal(el.applied.at(-1).dark, false);
  // Back to Home Assistant: the profile says Light again, whatever the OS.
  window.__ksHaScheme(null);
  assert.deepEqual(seen, [false, true]);
  assert.equal(el.applied.at(-1).dark, false);
  assert.equal(el.applied.at(-1).sawDark, false);
});

test('the same state again stays quiet', async () => {
  const { window, el } = await page({ dark: true });
  window.__ksHaScheme(true);
  assert.equal(el.applied.length, 0);
});

test('a second run keeps the first install', async () => {
  const { window, run } = await page({ dark: true });
  const set = window.__ksHaScheme;
  const matchMedia = window.matchMedia;
  run(false);
  assert.equal(window.__ksHaScheme, set);
  assert.equal(window.matchMedia, matchMedia);
});
