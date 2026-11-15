import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

// The remote admin's copy of the adaptive volume curve (issue #1450),
// loaded the way the other pure-module tests load theirs: the module has
// no imports, so its exports run as plain declarations.
const source = readFileSync(
  new URL('../remote-ui/static/adaptive_volume_curve.js', import.meta.url), 'utf8');
const context = vm.createContext({});
vm.runInContext(source.replace(/^export /gm, ''), context);
const plain = (value) => JSON.parse(JSON.stringify(value));
const {
  parseVolumeCurve, encodeVolumeCurve, volumeLevelAt, volumePointBounds, clampVolumePoint,
  withVolumePoint, volumeCurveDomain,
} = context;
const DEFAULT = vm.runInContext('DEFAULT_VOLUME_CURVE', context);

const stored = '[[-58,40,60,80],[-50,55,70,85],[-41,75,86,96],[-30,100,100,100]]';
const curve = parseVolumeCurve(stored);
const near = (a, b) => Math.abs(a - b) < 1e-9;

test('a stored curve reads back', () => {
  assert.deepEqual(plain(curve[1]), { noise: -50, assistant: 0.55, media: 0.7, intercom: 0.85 });
  assert.equal(encodeVolumeCurve(curve), stored);
});

test('the same default as the device', () => {
  // test/adaptive_volume_test.dart pins the same string on the device.
  assert.equal(DEFAULT, '[[-60,50,50,50],[-50,67,67,67],[-40,83,83,83],[-30,100,100,100]]');
  assert.equal(encodeVolumeCurve(parseVolumeCurve('nonsense')), DEFAULT);
  assert.equal(encodeVolumeCurve(parseVolumeCurve('[[-60,50,50,50]]')), DEFAULT);
  assert.equal(encodeVolumeCurve(parseVolumeCurve(undefined)), DEFAULT);
});

test('the same numbers as the device curve', () => {
  // test/adaptive_volume_test.dart pins the same values on the device.
  assert.equal(volumeLevelAt(curve, 'assistant', -90), 0.4);
  assert.equal(volumeLevelAt(curve, 'media', -58), 0.6);
  assert.equal(volumeLevelAt(curve, 'intercom', -30), 1);
  assert.equal(volumeLevelAt(curve, 'assistant', -5), 1);
  assert.ok(near(volumeLevelAt(curve, 'assistant', -54), 0.475));
  assert.ok(near(volumeLevelAt(curve, 'media', -45.5), 0.78));
  assert.ok(near(volumeLevelAt(curve, 'intercom', -35.5), 0.98));
});

test('a point is bounded by its neighbors', () => {
  const b = plain(volumePointBounds(curve, 1));
  assert.equal(b.noiseLo, -57);
  assert.equal(b.noiseHi, -42);
  assert.deepEqual(b.levelLo, { assistant: 0.4, media: 0.6, intercom: 0.8 });
  assert.deepEqual(b.levelHi, { assistant: 0.75, media: 0.86, intercom: 0.96 });
  const first = plain(volumePointBounds(curve, 0));
  assert.equal(first.noiseLo, -96);
  assert.deepEqual(first.levelLo, { assistant: 0, media: 0, intercom: 0 });
  const last = plain(volumePointBounds(curve, 3));
  assert.equal(last.noiseHi, 0);
  assert.deepEqual(last.levelHi, { assistant: 1, media: 1, intercom: 1 });
});

test('a point dragged past a neighbor stops at it', () => {
  const moved = plain(clampVolumePoint(curve, 1,
    { noise: -20, assistant: 0.9, media: 0.2, intercom: 0.9 }));
  assert.deepEqual(moved, { noise: -42, assistant: 0.75, media: 0.6, intercom: 0.9 });
});

test('replacing a point leaves the others and the original alone', () => {
  const next = withVolumePoint(curve, 2, { noise: -44, assistant: 0.7, media: 0.8, intercom: 0.9 });
  assert.equal(encodeVolumeCurve(next), '[[-58,40,60,80],[-50,55,70,85],[-44,70,80,90],[-30,100,100,100]]');
  assert.equal(encodeVolumeCurve(curve), stored);
});

test('the chart spans whole tens of dB around the ends', () => {
  assert.deepEqual(plain(volumeCurveDomain(curve)), { lo: -70, hi: -20 });
  const wide = parseVolumeCurve('[[-96,0,0,0],[-50,55,70,85],[-41,75,86,96],[0,100,100,100]]');
  assert.deepEqual(plain(volumeCurveDomain(wide)), { lo: -100, hi: 0 });
});
