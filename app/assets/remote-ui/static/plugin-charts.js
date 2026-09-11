// Runtime-only charts. Updating a chart never replaces the settings form.
const palette = ['#1976d2', '#b45309', '#16836b', '#a13ca4'];
const svgNS = 'http://www.w3.org/2000/svg';
const states = new WeakMap();
function node(tag, className, text) {
  const el = document.createElement(tag);
  if (className) el.className = className;
  if (text !== undefined) el.textContent = text;
  return el;
}
function svg(tag, attributes) {
  const el = document.createElementNS(svgNS, tag);
  for (const [key, value] of Object.entries(attributes)) el.setAttribute(key, value);
  return el;
}
function number(value) { return value == null ? 'No data' : Math.abs(value) >= 1e6 ? value.toExponential(2) : Number(value.toFixed(2)).toString(); }
function time(value) { return new Date(value).toLocaleString([], { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false }); }

function createChart() {
  const card = node('div', 'card plugin-chart');
  const title = node('div', 'plugin-chart-title');
  const legend = node('div', 'plugin-chart-legend');
  const selected = node('div', 'desc plugin-chart-reading');
  const plot = node('div', 'plugin-chart-plot');
  const labels = node('div', 'plugin-chart-scale desc');
  const drawing = svg('svg', { viewBox: '0 0 600 160', preserveAspectRatio: 'none', tabindex: '0', role: 'group' });
  const dates = node('div', 'plugin-chart-dates desc');
  const empty = node('div', 'plugin-chart-empty desc', 'No data yet');
  plot.append(labels, drawing, empty);
  card.append(title, legend, selected, plot, dates, node('div', 'desc plugin-chart-help', 'Tap or drag to inspect samples. Double-tap to follow the latest.'));
  const state = { title, legend, selected, labels, drawing, dates, empty, timestamp: null, chart: null };
  states.set(card, state);
  function inspect(clientX) {
    const times = state.chart.timestamps;
    if (!times.length) return;
    const bounds = drawing.getBoundingClientRect();
    const target = times[0] + Math.max(0, Math.min(1, (clientX - bounds.left) / bounds.width)) * (times.at(-1) - times[0]);
    state.timestamp = times.reduce((a, b) => Math.abs(a - target) <= Math.abs(b - target) ? a : b);
    paint(state);
  }
  drawing.onpointerdown = (event) => { drawing.focus({ preventScroll: true }); drawing.setPointerCapture(event.pointerId); inspect(event.clientX); };
  drawing.onpointermove = (event) => { if (event.pointerType === 'mouse' || event.buttons) inspect(event.clientX); };
  drawing.onpointerleave = (event) => { if (event.pointerType === 'mouse' && !event.buttons) { state.timestamp = null; paint(state); } };
  drawing.ondblclick = () => { state.timestamp = null; paint(state); };
  drawing.onkeydown = (event) => {
    if (!['ArrowLeft', 'ArrowRight', 'End'].includes(event.key)) return;
    event.preventDefault();
    const times = state.chart.timestamps;
    if (!times.length) return;
    const found = times.indexOf(state.timestamp);
    const index = found < 0 ? times.length - 1 : found;
    state.timestamp = event.key === 'End' ? null : times[Math.max(0, Math.min(times.length - 1, index + (event.key === 'ArrowLeft' ? -1 : 1)))];
    paint(state);
  };
  return card;
}

function paint(state) {
  const chart = state.chart;
  const times = chart.timestamps;
  const found = times.indexOf(state.timestamp);
  const selected = found < 0 ? times.length - 1 : found;
  state.title.textContent = chart.title;
  state.legend.replaceChildren();
  for (const [i, series] of chart.series.entries()) {
    const value = selected < 0 ? null : series.values[selected];
    const item = node('span');
    const marker = node('span', 'plugin-chart-marker'); marker.style.backgroundColor = series.color || palette[i];
    item.append(marker, document.createTextNode(`${series.name}: ${number(value)}${value != null && chart.unit ? ' ' + chart.unit : ''}`));
    state.legend.append(item);
  }
  state.selected.textContent = selected < 0 ? 'Waiting for samples' : `${found < 0 ? 'Latest' : 'Selected'} · ${time(times[selected])}`;
  state.drawing.setAttribute('aria-label', `${chart.title}. ${state.legend.textContent}. ${state.selected.textContent}. Use arrow keys to inspect samples and End for the latest.`);
  state.drawing.replaceChildren(); state.labels.replaceChildren(); state.dates.replaceChildren();
  const values = chart.series.flatMap(series => series.values).filter(value => value != null);
  state.empty.hidden = !!values.length; state.drawing.style.display = values.length ? '' : 'none';
  if (times.length) state.dates.append(node('span', '', time(times[0])), node('span', '', time(times.at(-1))));
  if (!values.length) return;
  const low = Math.min(...values), high = Math.max(...values);
  const margin = high === low ? Math.max(1, Math.abs(high) * .05) : (high - low) * .05;
  const min = low - margin, max = high + margin;
  state.labels.append(node('span', '', number(max)), node('span', '', number(min)));
  const x = (i) => times.length === 1 ? 300 : (times[i] - times[0]) / (times.at(-1) - times[0]) * 600;
  const y = (value) => 160 * (1 - (value - min) / (max - min));
  for (let i = 0; !chart.compact && i <= 4; i++) state.drawing.append(svg('line', { x1: 0, x2: 600, y1: i * 40, y2: i * 40, stroke: 'var(--border)', 'vector-effect': 'non-scaling-stroke' }));
  if (selected >= 0) state.drawing.append(svg('line', { x1: x(selected), x2: x(selected), y1: 0, y2: 160, stroke: 'var(--muted)', 'vector-effect': 'non-scaling-stroke' }));
  for (const [i, series] of chart.series.entries()) {
    let path = '', connected = false;
    for (const [j, value] of series.values.entries()) {
      if (value == null) { connected = false; continue; }
      path += `${connected ? 'L' : 'M'}${x(j)},${y(value)} `; connected = true;
      if (!chart.compact || j === selected) state.drawing.append(svg('circle', { cx: x(j), cy: y(value), r: j === selected ? 4 : 1.5, fill: series.color || palette[i] }));
    }
    state.drawing.append(svg('path', { d: path, fill: 'none', stroke: series.color || palette[i], 'stroke-width': 2, 'vector-effect': 'non-scaling-stroke' }));
  }
}

export function updatePluginCharts(container, charts) {
  container.hidden = !charts.length;
  const keys = new Set(charts.map(chart => chart.key));
  for (const card of container.querySelectorAll('.plugin-chart')) if (!keys.has(card.dataset.key)) card.remove();
  if (!container.firstElementChild) container.append(node('div', 'card-title', 'Charts'));
  for (const chart of charts) {
    let card = [...container.querySelectorAll('.plugin-chart')].find(el => el.dataset.key === chart.key);
    if (!card) { card = createChart(); card.dataset.key = chart.key; container.append(card); }
    const state = states.get(card);
    if (JSON.stringify(state.chart) === JSON.stringify(chart)) continue;
    card.classList.toggle('compact', chart.compact === true);
    state.chart = chart; paint(state);
  }
}
