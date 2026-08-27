import { showToast } from './widgets.js';
import { $, api, cmd } from './core.js';

/* ---- Console + Logs ---- */
export function appendLine(el, level, message, timeMs) {
  const atBottom = el.scrollHeight - el.scrollTop - el.clientHeight < 40;
  const div = document.createElement('div'); div.className = `line ${level}`;
  const ts = new Date(timeMs || Date.now()).toTimeString().slice(0, 8);
  const t = document.createElement('span'); t.className = 'ts'; t.textContent = ts + ' ';
  div.appendChild(t); div.appendChild(document.createTextNode(message));
  el.appendChild(div);
  while (el.childElementCount > 500) el.removeChild(el.firstChild);
  if (atBottom) el.scrollTop = el.scrollHeight;
}
export async function loadConsole() {
  const { console: lines } = await (await api('/api/console')).json();
  const el = $('#consoleOut'); el.innerHTML = '';
  (lines || []).forEach((l) => appendLine(el, l.level, l.message, l.time));
}
$('#clearConsole').addEventListener('click', () => {
  cmd('clearConsole'); $('#consoleOut').innerHTML = ''; updateConsoleMeta();
});

// Copy a console-style pane as plain text. navigator.clipboard exists only
// on secure origins and this admin page is plain http, so the execCommand
// fallback is the path that actually runs day to day.
export async function copyPane(el, btn) {
  const text = [...el.children].map((d) => d.textContent).join('\n');
  let ok = false;
  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text);
      ok = true;
    }
  } catch (_) {}
  if (!ok) {
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.cssText = 'position:fixed; opacity:0';
    document.body.appendChild(ta);
    ta.select();
    try { ok = document.execCommand('copy'); } catch (_) {}
    ta.remove();
  }
  showToast({
    title: ok ? 'Copied' : 'Could not copy',
    message: ok ? 'The log is on the clipboard.' : '',
    kind: ok ? 'success' : 'error',
    duration: 2000,
  });
}
$('#copyConsole').addEventListener('click', (e) => copyPane($('#consoleOut'), e.target));
$('#copyLogs').addEventListener('click', (e) => copyPane($('#logsOut'), e.target));

// The REPL half of the web console: JavaScript typed here runs in the
// kiosk's page (the same evalJs the API exposes), the command echoes in
// the pane and the result (or error) prints under it.
{
  const input = $('#consoleInput');
  const history = [];
  let histPos = -1;
  input.addEventListener('keydown', async (e) => {
    if (e.key === 'ArrowUp') {
      if (history.length && histPos < history.length - 1) {
        histPos += 1;
        input.value = history[history.length - 1 - histPos];
      }
      e.preventDefault();
      return;
    }
    if (e.key === 'ArrowDown') {
      if (histPos > 0) {
        histPos -= 1;
        input.value = history[history.length - 1 - histPos];
      } else {
        histPos = -1;
        input.value = '';
      }
      e.preventDefault();
      return;
    }
    if (e.key !== 'Enter') return;
    const code = input.value.trim();
    if (!code) return;
    history.push(code);
    histPos = -1;
    input.value = '';
    const out = $('#consoleOut');
    appendLine(out, 'cmd', '> ' + code);
    try {
      const res = await cmd('evalJs', { code });
      if (res.ok) {
        // Only print an actual value. A statement (console.log, assignments,
        // void calls) evaluates to null/undefined — and Android's WebView
        // reports those as the STRINGS "null"/"undefined" (evaluateJavascript
        // JSON-encodes its result) — echoing that after every command is
        // just noise.
        const d = res.data;
        if (d !== undefined && d !== null && d !== 'null' && d !== 'undefined') {
          appendLine(out, 'log', typeof d === 'string' ? d : JSON.stringify(d));
        }
      } else {
        appendLine(out, 'error', res.error || 'evaluation failed');
      }
    } catch (_) {
      appendLine(out, 'error', 'device unreachable');
    }
    out.scrollTop = out.scrollHeight;
  });
}
// Render the stored logcat text through the type checkboxes, so Copy grabs
// exactly the lines on screen — a crash can go into a GitHub issue without
// hundreds of noise lines around it. Continuation lines (stack traces)
// inherit the previous line's priority so a filtered crash keeps its trace.
export let _logcatText = '';
export function renderLogcat() {
  const el = $('#logsOut'); el.innerHTML = '';
  const want = {
    err: $('#lcErrors').checked,
    warn: $('#lcWarnings').checked,
    info: $('#lcInfo').checked,
  };
  let last = 'I';
  let shown = 0;
  _logcatText.split('\n').forEach((line) => {
    if (!line.trim()) return;
    const m = line.match(/^\d{2}-\d{2} [\d:.]+ ([VDIWEF])\//);
    const pri = m ? m[1] : last;
    last = pri;
    const isErr = pri === 'E' || pri === 'F';
    const keep = isErr ? want.err : pri === 'W' ? want.warn : want.info;
    if (!keep) return;
    shown++;
    appendLine(el, isErr ? 'error' : pri === 'W' ? 'warn' : 'log', line);
  });
  // Errors-only is the default; a quiet log must read as good news, not as
  // a broken viewer.
  if (!shown && _logcatText.trim()) {
    appendLine(el, 'debug', 'No matching lines. Enable more types above to see the full log.');
  }
}
// Which of the three views the Logs tab shows: the app's own log, the
// Android logcat tail — where renderer crashes and OS-level kills show up,
// which the in-app log cannot see (Fully Kiosk-style) — or the WebView
// console. One at a time, picked by the tab's nav links.
export let logView = 'app';
document.querySelectorAll('.log-nav button').forEach((btn) =>
  btn.addEventListener('click', () => {
    logView = btn.dataset.log;
    document.querySelectorAll('.log-nav button').forEach((b) =>
      b.classList.toggle('active', b === btn));
    $('#logPane').style.display = logView === 'console' ? 'none' : '';
    $('#consolePane').style.display = logView === 'console' ? '' : 'none';
    if (logView === 'console') updateConsoleMeta(); else loadLogs();
  }));

export function updateConsoleMeta() {
  $('#consoleMeta').textContent = `${$('#consoleOut').children.length} entries`;
}

export async function loadLogs() {
  if (logView === 'console') return;
  const logcat = logView === 'logcat';
  $('#logcatFilters').style.display = logcat ? 'inline-flex' : 'none';
  // For logcat the filters are the header's left side; the device page
  // titles it instead, but here both at once would crowd the row.
  $('#logMeta').style.display = logcat ? 'none' : '';
  const el = $('#logsOut'); el.innerHTML = '';
  if (logcat) {
    try {
      const r = await (await api('/api/commands/getLogcat', {
        method: 'POST', body: '{}' })).json();
      if (!r.ok) { appendLine(el, 'error', r.error || 'logcat unavailable'); return; }
      _logcatText = String(r.data || '');
      renderLogcat();
    } catch (_) { appendLine(el, 'error', 'logcat unavailable'); }
    return;
  }
  const { logs } = await (await api('/api/logs')).json();
  $('#logMeta').textContent = `${(logs || []).length} entries`;
  (logs || []).forEach((l) =>
    appendLine(el, l.level, `${l.tag}: ${l.message}`, Date.parse(l.time)));
}
$('#refreshLogs').addEventListener('click', loadLogs);
['lcErrors', 'lcWarnings', 'lcInfo'].forEach((id) =>
  $('#' + id).addEventListener('change', renderLogcat));
