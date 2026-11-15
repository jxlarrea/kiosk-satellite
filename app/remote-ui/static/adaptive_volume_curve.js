/* The adaptive volume curve (issue #1450), the device's AdaptiveVolumeCurve
   (lib/managers/audio/adaptive_volume_curve.dart) line for line: four
   points from a quiet room to a loud one, each a noise level in dBFS and
   the share of its own slider every volume plays at there. Between two
   points a volume moves in a straight line, below the first and above the
   last it stays where that point put it. Stored as one setting, a JSON
   list of [noise, assistant, media, intercom] rows with the volumes in
   percent. Pure, so the tests can load it without a page. */

export const VOLUME_CURVE_KEY = 'audio.adaptive_volume_curve';
export const VOLUME_CHANNELS = ['assistant', 'media', 'intercom'];
export const VOLUME_MIN_NOISE = -96;
export const VOLUME_MAX_NOISE = 0;
export const VOLUME_NOISE_GAP = 1;
export const DEFAULT_VOLUME_CURVE = '[[-60,50,50,50],[-50,67,67,67],[-40,83,83,83],[-30,100,100,100]]';

const clamp = (v, lo, hi) => Math.min(Math.max(v, lo), hi);

function decode(value) {
  let raw = value;
  if (typeof raw === 'string') {
    try { raw = JSON.parse(raw); } catch (_) { return null; }
  }
  if (!Array.isArray(raw) || raw.length !== 4) return null;
  const points = [];
  for (const row of raw) {
    if (!Array.isArray(row) || row.length !== 4) return null;
    if (!row.every((cell) => typeof cell === 'number' && Number.isFinite(cell))) return null;
    points.push({ noise: row[0], assistant: row[1] / 100, media: row[2] / 100, intercom: row[3] / 100 });
  }
  return points;
}

/* The curve a stored value describes, or the default one when the value
   is not a curve. */
export function parseVolumeCurve(value) {
  return decode(value) ?? decode(DEFAULT_VOLUME_CURVE);
}

/* The stored form: whole dB and whole percent. */
export function encodeVolumeCurve(points) {
  return JSON.stringify(points.map((p) => [
    Math.round(p.noise), Math.round(p.assistant * 100), Math.round(p.media * 100),
    Math.round(p.intercom * 100),
  ]));
}

/* The share of its slider `channel` plays at in a room at `noise` dBFS. */
export function volumeLevelAt(points, channel, noise) {
  if (noise <= points[0].noise) return points[0][channel];
  for (let i = 1; i < points.length; i++) {
    const hi = points[i];
    if (noise > hi.noise) continue;
    const lo = points[i - 1];
    const k = (noise - lo.noise) / (hi.noise - lo.noise);
    return lo[channel] + (hi[channel] - lo[channel]) * k;
  }
  return points[points.length - 1][channel];
}

/* What point `index` may be set to without crossing its neighbors: its
   noise level `gap` dB clear of theirs, each volume from the previous
   point's to the next one's. */
export function volumePointBounds(points, index, gap = VOLUME_NOISE_GAP) {
  const before = index > 0 ? points[index - 1] : null;
  const after = index < points.length - 1 ? points[index + 1] : null;
  const level = (point, fallback) => Object.fromEntries(
    VOLUME_CHANNELS.map((channel) => [channel, point ? point[channel] : fallback]));
  return {
    noiseLo: before ? before.noise + gap : VOLUME_MIN_NOISE,
    noiseHi: after ? after.noise - gap : VOLUME_MAX_NOISE,
    levelLo: level(before, 0),
    levelHi: level(after, 1),
  };
}

/* `want` pulled inside what point `index` may be set to. */
export function clampVolumePoint(points, index, want, gap = VOLUME_NOISE_GAP) {
  const b = volumePointBounds(points, index, gap);
  const point = {
    noise: b.noiseLo <= b.noiseHi ? clamp(want.noise, b.noiseLo, b.noiseHi) : points[index].noise,
  };
  for (const channel of VOLUME_CHANNELS) {
    point[channel] = clamp(want[channel], b.levelLo[channel], b.levelHi[channel]);
  }
  return point;
}

/* The curve with point `index` replaced. */
export function withVolumePoint(points, index, point) {
  return points.map((p, i) => (i === index ? { ...point } : { ...p }));
}

/* The chart's noise range: whole tens of dB around the curve's ends, with
   room past them to drag. */
export function volumeCurveDomain(points) {
  const lo = Math.floor((points[0].noise - 5) / 10) * 10;
  const hi = Math.ceil((points[points.length - 1].noise + 5) / 10) * 10;
  return { lo: Math.max(lo, VOLUME_MIN_NOISE - 4), hi: Math.min(hi, VOLUME_MAX_NOISE) };
}
