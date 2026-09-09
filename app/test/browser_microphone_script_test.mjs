import {readFileSync} from 'node:fs';
import {runInNewContext} from 'node:vm';
import {test} from 'node:test';
import assert from 'node:assert/strict';
const source = readFileSync(new URL('../lib/managers/js_api/browser_microphone_script.dart', import.meta.url), 'utf8').split("r'''")[1].split("''';")[0];
class Track extends EventTarget {
  readyState = 'live';
  stop() { this.readyState = 'ended'; }
  clone() { return new Track(); }
}
function stream(tracks = [new Track()]) {
  return {getAudioTracks: () => tracks, clone: () => stream(tracks.map(() => new Track()))};
}
test('capture is released before the browser opens and held until all clones stop', async () => {
  const calls = [];
  const value = stream();
  const navigator = {mediaDevices: {getUserMedia: async () => {
    assert.deepEqual(calls, [true]);
    return value;
  }}};
  runInNewContext(source, {navigator, call: async (_, p) => { calls.push(p.active); }});
  const result = await navigator.mediaDevices.getUserMedia({audio: true});
  const trackClone = result.getAudioTracks()[0].clone();
  const streamClone = result.clone();
  result.getAudioTracks()[0].stop();
  trackClone.stop();
  assert.deepEqual(calls, [true]);
  streamClone.getAudioTracks()[0].stop();
  assert.deepEqual(calls, [true, false]);
});
test('failed microphone requests release ownership and video requests bypass it', async () => {
  const calls = [];
  const navigator = {mediaDevices: {getUserMedia: async () => {throw Error('denied');}}};
  runInNewContext(source, {navigator, call: async (_, p) => { calls.push(p.active); }});
  await assert.rejects(navigator.mediaDevices.getUserMedia({audio: true}));
  assert.deepEqual(calls, [true, false]);
  calls.length = 0;
  await assert.rejects(navigator.mediaDevices.getUserMedia({video: true}));
  assert.deepEqual(calls, []);
});
