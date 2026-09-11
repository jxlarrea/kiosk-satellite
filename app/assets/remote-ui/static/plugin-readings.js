// Live entity values use their own DOM so settings drafts and chart selection survive.
function element(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

export function formatPluginReading(reading) {
  const state = reading.state;
  if (state == null) return 'No data';
  if (typeof state === 'boolean') return state ? 'On' : 'Off';
  if (typeof state === 'number') {
    if (!Number.isFinite(state)) return 'No data';
    const precision = Math.max(0, Math.min(6, Math.trunc(reading.accuracyDecimals || 0)));
    if (Math.abs(state) >= 1e9) return state.toExponential(precision);
    const value = state.toFixed(precision);
    return Number(value) === 0 ? (0).toFixed(precision) : value;
  }
  return state === '' ? 'Empty' : String(state);
}

export function updatePluginReadings(container, readings) {
  readings = Array.isArray(readings) ? readings : [];
  container.hidden = !readings.length;
  if (!readings.length) { container.replaceChildren(); return; }
  let list = container.querySelector('dl');
  if (!list) {
    list = element('dl', 'card plugin-readings-list');
    container.append(element('div', 'card-title', 'Readings'), list);
  }
  const existing = new Map([...list.children].map(row => [row.dataset.key, row]));
  for (const reading of readings) {
    const key = `${reading.type}:${reading.key}`;
    let row = existing.get(key);
    if (!row) {
      row = element('div', 'plugin-reading'); row.dataset.key = key;
      row.append(element('dt'), element('dd'));
    }
    existing.delete(key);
    const value = formatPluginReading(reading);
    const unit = reading.type === 'sensor' && reading.state != null ? reading.unit || '' : '';
    row.classList.toggle('multiline', value.includes('\n'));
    const label = row.querySelector('dt');
    if (label.textContent !== reading.name) label.textContent = reading.name;
    const content = row.querySelector('dd');
    content.classList.toggle('muted', reading.state == null || reading.state === '');
    const signature = JSON.stringify([value, unit]);
    if (row.dataset.value !== signature) {
      content.replaceChildren(element('span', 'plugin-reading-value', value));
      if (unit) content.append(document.createTextNode(' '), element('span', 'plugin-reading-unit', unit));
      row.dataset.value = signature;
    }
    list.append(row);
  }
  for (const row of existing.values()) row.remove();
}
