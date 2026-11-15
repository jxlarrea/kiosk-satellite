import { socketReady, socketRequest } from './transport.js';

const watches = new Set();
let sentTopics = '';
let rendering = 0;
export function beginLiveRender() { rendering++; }
export function endLiveRender() {
  rendering = Math.max(0, rendering - 1);
  if (!rendering) syncSubscriptions();
}
const baseTopics = ['settings', 'events', 'brightness', 'lightlevel', 'adaptivelight', 'adaptivevolume', 'externalmotion', 'wakeword-state'];

// Each visible panel owns its subscriptions. Detached panels are discarded
// after rendering, and returning to a page always reads a fresh snapshot.
export function watchUpdates(topics, refresh, { visible = () => true, owner = null, intervalMs = 0 } = {}) {
  const watch = { topics, refresh, visible, owner, intervalMs, lastRun: 0, timer: null, active: false, busy: false, dirty: false };
  watches.add(watch);
  queueMicrotask(syncSubscriptions);
  return () => { watch.active = false; clearTimeout(watch.timer); watches.delete(watch); syncSubscriptions(); };
}
async function run(watch) {
  if (!watch.active || (watch.owner && !watch.owner.isConnected)) return;
  if (rendering) { watch.dirty = true; return; }
  if (watch.busy) { watch.dirty = true; return; }
  const delay = watch.intervalMs - (Date.now() - watch.lastRun);
  if (delay > 0) {
    watch.dirty = true;
    watch.timer ??= setTimeout(() => {
      watch.timer = null;
      watch.dirty = false;
      run(watch);
    }, delay);
    return;
  }
  clearTimeout(watch.timer);
  watch.timer = null;
  watch.lastRun = Date.now();
  watch.busy = true;
  try {
    const results = watch.results;
    watch.results = undefined;
    await watch.refresh(results);
  }
  catch (_) { /* Reconnect or the next update retries the read. */ }
  finally {
    watch.busy = false;
    if (watch.dirty) { watch.dirty = false; run(watch); }
  }
}
export function syncSubscriptions({ reconnect = false } = {}) {
  if (reconnect) {
    sentTopics = '';
    for (const watch of watches) watch.active = false;
  }
  if (rendering) return;
  const topics = new Set(baseTopics);
  if (!document.hidden) topics.add('stats');
  if (!document.hidden && document.querySelector('#tab-logs.active')) {
    topics.add('logs'); topics.add('console');
  }
  for (const watch of watches) {
    if (watch.owner && !watch.owner.isConnected) { watch.active = false; clearTimeout(watch.timer); watches.delete(watch); continue; }
    const active = !document.hidden
      && !document.querySelector('#app')?.classList.contains('hidden') && watch.visible()
      && (!watch.owner || watch.owner.getClientRects().length > 0);
    const entered = active && (!watch.active || reconnect);
    watch.active = active;
    if (!active) { clearTimeout(watch.timer); watch.timer = null; }
    if (entered) watch.lastRun = 0;
    if (active) watch.topics.forEach(topic => topics.add(topic));
    if (entered || (active && watch.dirty)) { watch.dirty = false; run(watch); }
  }
  const key = [...topics].sort().join(',');
  if (socketReady() && key !== sentTopics) {
    sentTopics = key;
    socketRequest({ type: 'subscribe', topics: [...topics] }).catch(() => { sentTopics = ''; });
  }
}
export function receiveUpdate(topic, results) {
  for (const watch of watches) {
    if (watch.topics.includes(topic)) {
      watch.results = { ...watch.results, ...results };
      run(watch);
    }
  }
}
document.addEventListener('visibilitychange', () => syncSubscriptions());
document.addEventListener('ks-route', () => syncSubscriptions());
let queued = false;
new MutationObserver(() => {
  if (queued) return;
  queued = true;
  queueMicrotask(() => { queued = false; syncSubscriptions(); });
}).observe(document.body, { childList: true, subtree: true });
