import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../lib/managers/browser/dashboard_camera_script.dart', import.meta.url), 'utf8').split("r'''")[1].split("'''")[0];

function page() {
  const elements = [];
  const images = [];
  let define;
  const definition = new Promise(resolve => { define = resolve; });
  const listeners = {};
  class Camera {
    localName = 'ha-camera-stream';
    muted = true;
    isConnected = true;
    updates = 0;
    shadowRoot = { querySelectorAll: selector => selector === 'img' ? images : [] };
    render() { return 'live player'; }
    requestUpdate() { this.updates++; this.output = this.render(); }
  }
  const document = {
    addEventListener: (name, callback) => { listeners[name] = callback; },
    querySelector: () => ({}),
    querySelectorAll: () => elements,
  };
  const context = vm.createContext({
    window: { addEventListener: (name, callback) => { listeners[name] = callback; } }, document,
    customElements: { whenDefined: () => definition, get: () => Camera },
  });
  context.window.customElements = context.customElements;
  vm.runInContext(source, context);
  return {
    context, elements, images, Camera, document, listeners,
    api: context.window.__ksDashboardCameras,
    async define() { define(Camera); await definition; },
  };
}

test('suspends and restores nested HA cameras while leaving other media alone', async () => {
  const p = page();
  const camera = new p.Camera();
  const other = { localName: 'video', requestUpdate() { throw Error('unrelated video touched'); } };
  p.elements.push({ shadowRoot: { querySelectorAll: () => [camera, other] } });
  await p.define();
  assert.equal(camera.render(), 'live player');
  p.api.setPaused(true);
  assert.equal(camera.output, null);
  const updates = camera.updates;
  p.api.setPaused(true);
  assert.equal(camera.updates, updates);
  p.api.setPaused(false);
  assert.equal(camera.output, 'live player');
});

test('preserves unmuted cameras and pages outside Home Assistant', async () => {
  const p = page();
  const camera = new p.Camera();
  camera.muted = false;
  p.elements.push(camera);
  await p.define();
  p.api.setPaused(true);
  assert.equal(camera.output, 'live player');
  camera.muted = true;
  camera.requestUpdate();
  assert.equal(camera.output, null);
  p.document.querySelector = () => null;
  assert.equal(camera.render(), 'live player');
});

test('handles suspension before definition and streams created while hidden', async () => {
  const p = page();
  p.api.setPaused(true);
  await p.define();
  const camera = new p.Camera();
  p.elements.push(camera);
  assert.equal(camera.render(), null);
  p.api.setPaused(false);
  assert.equal(camera.output, 'live player');
});

test('cancels pending suspension before definition and tolerates repeat injection', async () => {
  const p = page();
  p.api.setPaused(true);
  p.api.setPaused(false);
  await p.define();
  const render = p.Camera.prototype.render;
  vm.runInContext(source, p.context);
  assert.equal(p.Camera.prototype.render, render);
  assert.equal(new p.Camera().render(), 'live player');
});

test('clears MJPEG sources before removing their template', async () => {
  const p = page();
  const camera = new p.Camera();
  const removed = [];
  p.elements.push(camera);
  p.images.push({ removeAttribute: name => removed.push(name) });
  await p.define();
  p.api.setPaused(true);
  assert.deepEqual(removed, ['src']);
  assert.equal(camera.output, null);
});

test('follows the HA registry polyfill installed after document start', async () => {
  const p = page();
  const camera = new p.Camera();
  p.elements.push(camera);
  p.api.setPaused(true);
  p.context.window.customElements = {
    whenDefined: () => Promise.resolve(p.Camera),
    get: () => p.Camera,
  };
  p.listeners.DOMContentLoaded();
  await Promise.resolve();
  assert.equal(camera.output, null);
  assert.equal(p.api.supported, true);
  p.api.setPaused(false);
  assert.equal(camera.output, 'live player');
});
