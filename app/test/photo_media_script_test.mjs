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
    bridge() {},
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
  const photos = [], videos = [], events = {};
  const c = vm.createContext({
    CFG: { mediaFill: 'smart' },
    window: { innerWidth: 800, innerHeight: 480, addEventListener(name, callback) { events[name] = callback; } },
    content: {
      querySelectorAll(selector) {
        if (selector === 'video.slide-video') return videos;
        assert.equal(selector, 'img.photo');
        return photos;
      },
    },
    document: { createElement: node }, log() {},
  });
  const fillSource = source.slice(source.indexOf('function fillFor(img)'), source.indexOf('/* ── Camera WebRTC'));
  vm.runInContext(fillSource, c);
  c.backdropFor = () => { const backdrop = node(); backdrop.classList.add('backdrop'); return backdrop; };
  const photo = { naturalWidth: 300, naturalHeight: 400, classList: classes() };
  photos.push(photo);
  const stage = c.stillFor(photo);
  const video = (videoWidth, videoHeight) => {
    const v = { videoWidth, videoHeight, classList: classes() };
    videos.push(v);
    c.applyVideoFill(v);
    return v;
  };
  return { c, photo, stage, events, video };
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

// Issue #1298: videos follow Fill the screen on their own shape, without
// the photos' blurred backdrop.
test('a video shaped close to the screen fills it on Smart', () => {
  const { c, video } = fillHarness();
  const wide = video(1280, 720);
  const portrait = video(1080, 1920);
  assert.equal(wide.classList.contains('cover'), true);
  assert.equal(portrait.classList.contains('cover'), false);
  c.window.__ksPhotoFill('off');
  assert.equal(wide.classList.contains('cover'), false);
  c.window.__ksPhotoFill('always');
  assert.equal(wide.classList.contains('cover'), true);
  assert.equal(portrait.classList.contains('cover'), true);
});

test('a video with no size yet keeps its frame', () => {
  const { video } = fillHarness();
  assert.equal(video(0, 0).classList.contains('cover'), false);
});

test('Video length changes live and ignores unknown values', () => {
  const { c } = fillHarness();
  c.window.__ksVideoLength('interval');
  assert.equal(c.CFG.mediaVideoLength, 'interval');
  c.window.__ksVideoLength('bogus');
  assert.equal(c.CFG.mediaVideoLength, 'interval');
  c.window.__ksVideoLength('full');
  assert.equal(c.CFG.mediaVideoLength, 'full');
});

function videoHarness(cfg) {
  const h = harness();
  const videos = [];
  h.context.CFG = cfg;
  h.context.isVideo = () => true;
  h.context.applyVideoFill = () => {};
  h.context.document.createElement = () => {
    const listeners = {};
    const v = {
      listeners,
      addEventListener(name, callback) { (listeners[name] ||= []).push(callback); },
      fire(name) { for (const callback of listeners[name] || []) callback(); },
    };
    videos.push(v);
    return v;
  };
  const hass = { send: async () => ({ url: '/clip.mp4', mime_type: 'video/mp4' }), hassUrl: (u) => u };
  return { ...h, videos, hass };
}

test('Same as photos moves on from a video when the hold runs out', async () => {
  const { context: c, advance, videos, hass } = videoHarness({ mediaVideoLength: 'interval' });
  let changes = 0;
  await c.playItem(hass, 'v', ['v', 'w'], () => changes++, 10000);
  advance(30000);
  assert.equal(changes, 0, 'the hold starts once the video plays');
  videos[0].fire('playing');
  advance(9999);
  assert.equal(changes, 0);
  advance(1);
  assert.equal(changes, 1);
});

test('Same as photos still moves on when a short video ends first', async () => {
  const { context: c, advance, videos, hass } = videoHarness({ mediaVideoLength: 'interval' });
  let changes = 0;
  await c.playItem(hass, 'v', ['v', 'w'], () => changes++, 10000);
  videos[0].fire('playing');
  advance(4000);
  videos[0].fire('ended');
  assert.equal(changes, 1);
});

test('Same as photos holds paused while the screen is dark', async () => {
  const { context: c, advance, videos, hass } = videoHarness({ mediaVideoLength: 'interval' });
  let changes = 0;
  await c.playItem(hass, 'v', ['v', 'w'], () => changes++, 10000);
  videos[0].fire('playing');
  advance(4000);
  c.window.__ksPhotoActive(false);
  advance(60000);
  c.window.__ksPhotoActive(true);
  advance(5999);
  assert.equal(changes, 0);
  advance(1);
  assert.equal(changes, 1);
});

test('Whole video plays past the hold to its end', async () => {
  const { context: c, advance, videos, hass } = videoHarness({ mediaVideoLength: 'full' });
  let changes = 0;
  await c.playItem(hass, 'v', ['v', 'w'], () => changes++, 10000);
  videos[0].fire('playing');
  advance(60000);
  assert.equal(changes, 0);
  videos[0].fire('ended');
  assert.equal(changes, 1);
});

test('a single video loops with no hold', async () => {
  const { context: c, advance, videos, hass } = videoHarness({ mediaVideoLength: 'interval' });
  let changes = 0;
  await c.playItem(hass, 'v', ['v'], () => changes++, 10000);
  videos[0].fire('playing');
  advance(60000);
  assert.equal(changes, 0);
  assert.equal(videos[0].loop, true);
});

test('a video cut short cannot advance the deck when it ends later', async () => {
  const { context: c, videos, hass } = videoHarness({ mediaVideoLength: 'interval' });
  let changes = 0;
  await c.playItem(hass, 'v', ['v', 'w'], () => changes++, 10000);
  await c.playItem(hass, 'w', ['v', 'w'], () => changes++, 10000);
  // The first video ends under the hand-off, after the second took over.
  videos[0].fire('ended');
  videos[0].fire('error');
  assert.equal(changes, 0);
  videos[1].fire('ended');
  assert.equal(changes, 1);
});

test('an Immich album resolves photos that report can_play false', async () => {
  const c = vm.createContext({});
  const start = source.indexOf('const isImage =');
  vm.runInContext(source.slice(start, source.indexOf('function shuffle(')), c);
  const album = 'media-source://immich/account|albums|album';
  const photo = (n) => ({
    media_content_id: album + '|asset' + n + '|IMG_' + n + '.jpg|image/jpeg',
    media_class: 'image', media_content_type: 'image/jpeg', can_play: false, can_expand: false,
  });
  const hass = { send: async () => ({ children: [photo(1), photo(2), {
    media_content_id: album + '|asset3|clip.mp4|video/mp4',
    media_class: 'video', media_content_type: 'video/mp4', can_play: true, can_expand: false,
  }, {
    media_content_id: 'media-source://immich/account|albums|other',
    media_class: 'directory', media_content_type: 'image', can_play: false, can_expand: true,
  }] }) };
  const playlist = await c.resolvePlaylist(hass, album, false);
  assert.deepEqual([...playlist], [photo(1).media_content_id, photo(2).media_content_id, album + '|asset3|clip.mp4|video/mp4']);
});

test('a single pick plays without browsing', async () => {
  const sent = [];
  const c = vm.createContext({
    CFG: { haUrl: 'http://ha', haToken: 't', mediaId: 'media-source://immich/a|albums|b|c|IMG_1.jpg|image/jpeg', mediaIsFolder: false },
    window: {}, msg() {}, log() {},
    // HA's Immich source answers a photo's id with its whole album.
    Hass: class { connect() {} send(m) { sent.push(m); return Promise.resolve({ children: [
      { media_content_id: 'one', media_class: 'image', can_play: false, can_expand: false },
      { media_content_id: 'two', media_class: 'image', can_play: false, can_expand: false },
    ] }); } },
  });
  vm.runInContext(source.slice(source.indexOf('async function resolvePlaylist'), source.indexOf('/* ── Playback loop')), c);
  vm.runInContext(source.slice(source.indexOf('async function runMedia'), source.indexOf('function runWebsite')), c);
  let played;
  c.playItem = (hass, id, playlist) => { played = [...playlist]; };
  await c.runMedia();
  assert.deepEqual(played, [c.CFG.mediaId]);
  assert.equal(sent.some((m) => m.type === 'media_source/browse_media'), false);
});
