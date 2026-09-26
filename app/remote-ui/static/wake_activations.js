import { cameraAction, cameraListRow } from './cameras.js';
import { cmd, state } from './core.js';
import { watchUpdates } from './live.js';
import { messageLanguage, voiceText } from './localization.js';
import { hintRow } from './widgets.js';

/* ---- Wake word diagnostics ---- */
// The activations and near misses wake word diagnostics saved, as two groups
// under its switch, mirroring the device's page. Clips play here in the
// browser, not on the kiosk: whoever is reading this is usually not in the
// room.

let player = null; // { id, audio, url }

function stopPlayback() {
  if (!player) return;
  player.audio.pause();
  URL.revokeObjectURL(player.url);
  player = null;
}

function db(value) {
  return typeof value === 'number' ? `${value.toFixed(1)} dBFS` : '-∞ dBFS';
}

function stats(a) {
  return [
    typeof a.score === 'number' ? `${voiceText('Score')} ${a.score.toFixed(3)}` : null,
    typeof a.threshold === 'number' ? `${voiceText('Threshold')} ${a.threshold.toFixed(3)}` : null,
    `${voiceText('Peak level')} ${db(a.peakDb)}`,
    `${voiceText('Average level')} ${db(a.rmsDb)}`,
  ].filter(Boolean).join(' · ');
}

function when(a) {
  return new Date(a.at).toLocaleString(messageLanguage(), {
    weekday: 'short', month: 'short', day: 'numeric',
    hour: 'numeric', minute: '2-digit', second: '2-digit',
  });
}

async function clipUrl(a) {
  const r = await cmd('getWakeWordActivationAudio', { id: a.id });
  if (!r.ok) throw new Error(r.error || 'no clip');
  const bytes = Uint8Array.from(atob(r.data.base64), (c) => c.charCodeAt(0));
  return URL.createObjectURL(new Blob([bytes], { type: r.data.mimeType }));
}

// "office-tablet-hey-luna-20260926-124512.wav", "...-near-miss.wav" for a
// near miss: sorts by device, then word, then time in a downloads folder.
function clipName(a) {
  const slug = (s) => String(s || '').toLowerCase()
    .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
  const at = new Date(a.at);
  const pad = (n) => String(n).padStart(2, '0');
  const stamp = `${at.getFullYear()}${pad(at.getMonth() + 1)}${pad(at.getDate())}-`
    + `${pad(at.getHours())}${pad(at.getMinutes())}${pad(at.getSeconds())}`;
  return [slug(state.device?.name) || 'kiosk', slug(a.wakeWord || a.engine), stamp,
    a.nearMiss ? 'near-miss' : ''].filter(Boolean).join('-') + '.wav';
}

async function download(a) {
  try {
    const url = await clipUrl(a);
    const link = document.createElement('a');
    link.href = url;
    link.download = clipName(a);
    document.body.appendChild(link);
    link.click();
    link.remove();
    setTimeout(() => URL.revokeObjectURL(url), 10000);
  } catch (_) {
    alert(voiceText('Download failed'));
  }
}

async function play(a, repaint) {
  const same = player && player.id === a.id;
  stopPlayback();
  repaint();
  if (same) return;
  try {
    const url = await clipUrl(a);
    const audio = new Audio(url);
    player = { id: a.id, audio, url };
    audio.addEventListener('ended', () => {
      if (player && player.audio === audio) { stopPlayback(); repaint(); }
    });
    repaint();
    await audio.play();
  } catch (_) {
    stopPlayback();
    repaint();
    alert(voiceText('Could not play the sound.'));
  }
}

function row(a, repaint) {
  const playing = player && player.id === a.id;
  const action = cameraAction(voiceText(playing ? 'Stop' : 'Play'),
    () => play(a, repaint), false, playing ? 'stop' : 'play');
  const save = cameraAction(voiceText('Download'), () => download(a), false, 'download');
  const r = cameraListRow(a.wakeWord || a.engine, '', [action, save],
    { onClick: () => play(a, repaint) });
  // Date, then the numbers, then what vsWakeWord heard: one fact a line,
  // the same three lines the device shows.
  const desc = r.querySelector('.desc');
  desc.append(when(a), document.createElement('br'), stats(a));
  if (a.clipped > 0) {
    const clipped = document.createElement('strong');
    clipped.style.color = 'var(--error)';
    clipped.textContent = '  ' + voiceText('Clipped');
    desc.append(clipped);
  }
  if (a.decoded) {
    const heard = document.createElement('span');
    heard.style.fontFamily = 'monospace';
    heard.textContent = `${voiceText('Heard')} [${a.decoded}]`;
    desc.append(document.createElement('br'), heard);
  }
  return r;
}

// Hung under the switch after every settings render. Follows the device: a
// new activation or near miss, the switch flipping, a clear.
export function mountWakeActivations(root) {
  const toggle = root.querySelector('[data-key="wake_word.diagnostics"]');
  const card = toggle?.closest('.card');
  if (!card) return;
  card.parentNode.querySelector(':scope > #wakeActivations')?.remove();
  const list = document.createElement('div');
  list.id = 'wakeActivations';
  card.after(list);

  let last = null;
  const group = (title, entries, empty, repaint) => {
    const h = document.createElement('h2');
    h.className = 'card-title';
    h.textContent = voiceText(title);
    const c = document.createElement('div');
    c.className = 'card';
    if (!entries.length) c.appendChild(hintRow(voiceText(empty)));
    for (const a of entries) c.appendChild(row(a, repaint));
    list.append(h, c);
  };
  const render = () => {
    list.innerHTML = '';
    if (!last || !last.enabled) return;
    group('Activations', last.activations || [],
      'No wake word activations recorded yet.', render);
    group('Near misses', last.nearMisses || [],
      'No near misses recorded yet.', render);
  };
  const refresh = async () => {
    const r = await cmd('getWakeWordActivations');
    if (!r.ok) return;
    last = r.data;
    // The clip playing may have been pushed out of the ten.
    const kept = [...(last.activations || []), ...(last.nearMisses || [])];
    if (player && !kept.some((a) => a.id === player.id)) stopPlayback();
    render();
  };
  watchUpdates(['wakeword-activations'], refresh, { owner: list });
}
