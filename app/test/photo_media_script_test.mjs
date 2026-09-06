import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../assets/screensaver/screensaver.js', import.meta.url), 'utf8');
const playback = source.slice(source.indexOf('let cleanup = null;'), source.indexOf('async function runMedia'));

function harness() {
  let now = 0, id = 0;
  const timers = new Map();
  const images = [], shown = [];
  const context = vm.createContext({
    CFG: {}, window: {},
    document: {
      documentElement: { classList: { toggle() {} } },
      createElement() { const image = {}; images.push(image); return image; },
    },
    Date: { now: () => now },
    setTimeout(callback, delay) { timers.set(++id, { at: now + delay, callback }); return id; },
    clearTimeout(id) { timers.delete(id); },
    log() {}, cameraOf() { return null; }, isVideo() { return false; },
    stillFor(image) { return image; }, showElement(image) { shown.push(image); },
  });
  vm.runInContext(playback, context);
  function advance(ms) {
    const end = now + ms;
    for (;;) {
      const next = [...timers.entries()].filter(([, t]) => t.at <= end).sort((a, b) => a[1].at - b[1].at)[0];
      if (!next) break;
      now = next[1].at;
      timers.delete(next[0]);
      next[1].callback();
    }
    now = end;
  }
  return { context, advance, images, shown };
}

test('photo holds keep their remaining time across screen-off', () => {
  const { context: c, advance } = harness();
  let changes = 0;
  c.startPhotoHold(() => changes++, 10000);
  advance(3000);
  c.window.__ksPhotoActive(false);
  advance(60000);
  c.window.__ksPhotoActive(false);
  c.window.__ksPhotoActive(true);
  advance(6999);
  assert.equal(changes, 0);
  advance(1);
  assert.equal(changes, 1);
});

test('an image completing while dark waits for wake before display', async () => {
  const { context: c, images, shown } = harness();
  const hass = { send: async () => ({ url: '/photo.jpg' }), hassUrl: (u) => u };
  await c.playItem(hass, 'one', ['one'], () => {}, 1000);
  c.window.__ksPhotoActive(false);
  images[0].onload();
  assert.equal(shown.length, 0);
  c.window.__ksPhotoActive(true);
  assert.deepEqual(shown, [images[0]]);
});

test('a late previous image cannot replace the current image', async () => {
  const { context: c, images, shown } = harness();
  const hass = { send: async () => ({ url: '/photo.jpg' }), hassUrl: (u) => u };
  await c.playItem(hass, 'old', ['old', 'new'], () => {}, 1000);
  await c.playItem(hass, 'new', ['old', 'new'], () => {}, 1000);
  images[1].onload();
  images[0].onload();
  assert.deepEqual(shown, [images[1]]);
});

function fillHarness() {
  const classes = (initial = '') => {
    const values = new Set(initial.split(' '));
    return {
      add(value) { values.add(value); },
      contains(value) { return values.has(value); },
      toggle(value, on) { if (on) values.add(value); else values.delete(value); },
    };
  };
  const node = () => ({
    children: [], classList: classes(), parentElement: null,
    appendChild(child) { this.children.push(child); child.parentElement = this; },
    insertBefore(child, before) {
      this.children.splice(this.children.indexOf(before), 0, child);
      child.parentElement = this;
    },
    querySelector() { return this.children.find((c) => c.classList.contains('backdrop')); },
    remove() { this.parentElement.children.splice(this.parentElement.children.indexOf(this), 1); },
  });
  const photos = [], events = {};
  const c = vm.createContext({
    CFG: { mediaFill: 'smart' },
    window: { innerWidth: 800, innerHeight: 480, addEventListener(name, callback) { events[name] = callback; } },
    content: { querySelectorAll(selector) { assert.equal(selector, 'img.photo'); return photos; } },
    document: { createElement: node }, log() {},
  });
  const fillSource = source.slice(source.indexOf('function fillFor(img)'), source.indexOf('/* ── Camera WebRTC'));
  vm.runInContext(fillSource, c);
  c.backdropFor = () => { const backdrop = node(); backdrop.classList.add('backdrop'); return backdrop; };
  const photo = { naturalWidth: 300, naturalHeight: 400, classList: classes() };
  photos.push(photo);
  const stage = c.stillFor(photo);
  return { c, photo, stage, events };
}

test('live fill changes reframe the current photo without replacing it', () => {
  const { c, photo, stage } = fillHarness();
  assert.equal(stage.classList.contains('cover'), false);
  assert.ok(stage.querySelector('.backdrop'));
  c.window.__ksPhotoFill('always');
  assert.equal(stage.classList.contains('cover'), true);
  assert.equal(stage.querySelector('.backdrop'), undefined);
  assert.equal(photo.parentElement, stage);
  c.window.__ksPhotoFill('off');
  assert.equal(stage.classList.contains('cover'), false);
  assert.deepEqual(stage.children, [photo]);
  c.window.__ksPhotoFill('smart');
  assert.ok(stage.querySelector('.backdrop'));
  assert.equal(photo.parentElement, stage);
});

test('resizing a shared panel reevaluates Smart filling', () => {
  const { c, stage, events } = fillHarness();
  c.window.innerWidth = 360;
  events.resize();
  assert.equal(stage.classList.contains('cover'), true);
  assert.equal(stage.querySelector('.backdrop'), undefined);
  c.window.innerWidth = 800;
  events.resize();
  assert.equal(stage.classList.contains('cover'), false);
  assert.ok(stage.querySelector('.backdrop'));
});
