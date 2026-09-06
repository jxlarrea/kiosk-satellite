import { $, api, cmd } from './core.js';
import { copyBox, messageBox, modalShell } from './widgets.js';

// The helper group belongs only on devices without native silent installation.
export function renderUpdateHelper(root, initialStatus) {
  const group = document.createElement('div');
  root.appendChild(group);
  let status = initialStatus;
  let error = null;

  const refresh = async () => {
    try {
      const result = await cmd('getUpdateInstallerStatus');
      if (!result?.ok || typeof result.data?.nativeSilent !== 'boolean') {
        throw new Error('Status unavailable');
      }
      status = result.data;
      error = null;
    } catch (_) {
      error = 'Could not check the update helper.';
    }
    paint();
  };

  const paint = () => {
    group.replaceChildren();
    if (status?.nativeSilent === true) {
      const note = document.createElement('div');
      note.className = 'group-note';
      note.textContent = 'Android can now install updates silently. The helper is not needed.';
      group.appendChild(note);
      return;
    }
    const intro = document.createElement('div');
    intro.className = 'group-note';
    intro.textContent = 'This device currently needs confirmation on the screen to install updates through Android. '
      + 'The optional helper lets Kiosk Satellite install updates without a tap.';
    const card = document.createElement('div');
    card.className = 'card';
    group.append(intro, card);

    const note = (text) => {
      const row = document.createElement('div');
      row.className = 'row desc';
      row.textContent = text;
      card.appendChild(row);
    };
    const busy = status.helper === 'busy';
    const active = busy || status.helper === 'ready';
    const row = readOnlyRow('Helper status', error || (busy
      ? 'Installing an update.' : active
        ? 'Ready. Updates install without confirmation.'
        : 'Unavailable. Start the helper through ADB to enable updates without confirmation.'), '');
    row.querySelector('span').remove();
    const button = document.createElement('button');
    button.className = 'btn-ghost';
    button.textContent = 'Refresh';
    button.addEventListener('click', async () => {
      button.disabled = true;
      await refresh();
    });
    row.appendChild(button);
    card.appendChild(row);

    note('The helper survives app restarts and updates but stops after a device reboot. '
      + 'Run the command from a computer with ADB to start it again. The computer can then disconnect.');
    if (status.startCommand) {
      const setup = readOnlyRow('Start through ADB', '', '');
      setup.querySelector('span').remove();
      const copy = copyBox(status.startCommand);
      copy.el.style.cssText = 'width:100%; max-width:none;';
      setup.querySelector('.info').appendChild(copy.el);
      card.appendChild(setup);
    }
    const docs = readOnlyRow('Setup guide', 'Read the update helper instructions and requirements.', '');
    docs.querySelector('span').remove();
    const link = document.createElement('a');
    link.className = 'btn-ghost';
    link.textContent = 'Open guide';
    link.href = 'https://github.com/jxlarrea/kiosk-satellite/blob/main/docs/updates.md#optional-update-helper';
    link.target = '_blank';
    link.rel = 'noreferrer';
    docs.appendChild(link);
    card.appendChild(docs);
  };
  paint();
}

/* ---- Device Info ---- */
// What this device is and what it is doing, read fresh each time the tab is
// opened. Everything here comes from the device itself; nothing is inferred
// from what we asked it to do earlier, because the interesting case is exactly
// when those two disagree.
export async function loadDeviceInfo() {
  const root = $('#device-info');
  // Each report is a page of its own, so the "reading" state goes on those
  // pages rather than leaving a stray card on the page that opens them.
  root.innerHTML = '';
  const PAGES = ['Hardware', 'Home Assistant', 'WebView'];
  for (const name of PAGES) {
    const panel = document
      .querySelector(`#tab-device > .subpage[data-subpage="${name}"]`);
    if (panel) {
      panel.innerHTML =
        '<div class="card"><div class="desc" style="color:var(--muted)">Reading…</div></div>';
    }
  }

  const get = async (name, params = {}) => {
    try { const r = await cmd(name, params); return r.ok ? r.data : null; }
    catch { return null; }
  };

  const [info, settings, wake, screenOn, motion, face, ua, det] = await Promise.all([
    api('/api/info').then((r) => r.json()).catch(() => null),
    api('/api/settings').then((r) => r.json()).catch(() => null),
    get('getWakeWordState'),
    get('isScreenOn'),
    get('getMotionEnabled'),
    get('getFaceEnabled'),
    // The page's own view of itself: the one thing only the WebView knows.
    get('evalJs', { code: 'navigator.userAgent' }),
    get('getDeviceDetails'),
  ]);

  const S = {};
  (settings?.settings || []).forEach((x) => (S[x.key] = x.value));
  const yn = (v) => (v === true ? 'on' : v === false ? 'off' : '-');
  const or = (v, alt = '-') => (v === null || v === undefined || v === '' ? alt : v);
  const mb = (b) => (b == null ? null : Math.round(b / 1048576));
  const pair = (free, total, unit) =>
    free == null || total == null ? '-' : `${free}/${total} ${unit}`;
  // Uptime seconds as a person reads them; the two biggest units that
  // apply, so a three-week uptime is not a six-figure minute count.
  const dur = (s) => {
    if (s == null) return '-';
    s = Math.floor(s);
    const d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600),
      m = Math.floor((s % 3600) / 60);
    return d ? `${d}d ${h}h` : h ? `${h}h ${m}m` : m ? `${m}m` : `${s}s`;
  };

  root.innerHTML = '';
  // Three of these reports are pages of their own, so each goes into the
  // panel its entry row opens (created by render(), which rebuilds the
  // panels on every settings load). No heading there: the title bar has it.
  const card = (title, rows) => {
    const panel = document
      .querySelector(`#tab-device > .subpage[data-subpage="${title}"]`);
    const target = panel || root;
    if (panel) {
      panel.innerHTML = '';
    } else {
      const h = document.createElement('h2');
      h.className = 'card-title';
      h.textContent = title;
      target.appendChild(h);
    }
    const c = document.createElement('div'); c.className = 'card';
    for (const [k, v] of rows) {
      if (v === undefined) continue;
      const row = document.createElement('div'); row.className = 'row';
      const info = document.createElement('div'); info.className = 'info';
      const n = document.createElement('div'); n.className = 'name'; n.textContent = k;
      info.appendChild(n); row.appendChild(info);
      const val = document.createElement('span');
      val.style.cssText = 'text-align:right; word-break:break-all; max-width:60%';
      val.textContent = String(v);
      row.appendChild(val);
      c.appendChild(row);
    }
    target.appendChild(c);
  };

  card('Hardware', [
    ['Device name', or(info?.name)],
    ['Device model', det?.brand && det?.brand !== det?.manufacturer
      ? `${or(info?.model)} (${det.brand})` : or(info?.model)],
    ['Android version', `${or(info?.osVersion)}${info?.sdkInt ? ` (SDK ${info.sdkInt})` : ''}`],
    ['Android build', or(det?.androidBuild)],
    ['IPv4 address', or(info?.ip)],
    ['IPv6 addresses', or((info?.ipv6 || []).join(', '))],
    ['App uptime', dur(info?.uptime?.app)],
    // Since the app last saw the network come up, so it caps at the app
    // uptime; Android does not tell an app when the router associated.
    ['Network uptime', dur(info?.uptime?.network)],
    ['CPU usage', info?.cpu == null ? '-' : `${Math.round(info.cpu)}%`],
    ['CPU temperature', info?.temp == null ? '-' : `${Math.round(info.temp)}°C`],
    ['Battery level', info?.battery == null ? '-'
      : `${info.battery}%${info.charging ? ' (plugged)' : ''}`],
    ['Screen brightness', info?.brightness == null ? '-'
      : `${Math.round(info.brightness * 100)}% (${Math.round(info.brightness * 255)}/255)`],
    ['Screen status', yn(screenOn)],
    ['Screen size', det?.screen?.width == null ? '-'
      : `${det.screen.width}x${det.screen.height} px` +
        (det.screen.density ? ` @${det.screen.density}x` : '')],
    ['RAM (free/total)', pair(mb(det?.ram?.free), mb(det?.ram?.total), 'MB') +
      (det?.ram?.low ? ', low' : '')],
    ['Internal storage (free/total)',
      pair(mb(det?.storage?.free), mb(det?.storage?.total), 'MB')],
  ]);

  card('Home Assistant', [
    ['Home Assistant URL', or(S['ha.url'])],
    ['Wake word detection', yn(S['wake_word.enabled'])],
    ['Wake word status', or(wake?.statusLabel)],
    ['Engine', or(wake?.engineLabel)],
    ['Wake words', or((wake?.models || []).map((m) => m.wakeWord).join(', '))],
    ['Stop word', or(wake?.stopWord)],
    ['Background listening', yn(S['wake_word.background'])],
    ['Motion detection', yn(motion)],
    ['Face detection', yn(face)],
  ]);

  // Permissions used to be summarised here, read-only. The Permissions group
  // in the settings above this pane lists the same grants with what each one
  // is for and a button to give it, so a second copy on the same tab was
  // only a second thing to keep in step. Remote administration went for the
  // same reason: its port is a setting in that pane and the admin address is
  // the Access card.

  card('WebView', [
    // The system WebView, which updates itself independently of this app and
    // is the thing actually rendering the card.
    ['Provider', or(det?.webview?.package)],
    ['Version', or(det?.webview?.version)],
    ['User agent', or(ua)],
  ]);
}

/* ---- About ---- */
// The same rows the device's own About page shows: app identity plus
// attribution and the license in one sentence.
/* The Install button's whole life, shared by the About page and the
   Overview's Needs attention row: release notes, then the download on the
   tablet, ridden by polling until the installer has it. `btn` carries its
   idle label already. */
export function attachUpdateInstall(btn, upd) {
  const idleLabel = `Install version ${upd.availableVersion}`;
  const run = async () => {
    // One riding loop at a time: a re-rendered About tab (or a second
    // click) starts a fresh one and this token retires the old, which
    // would otherwise keep polling a detached button for the rest of
    // the download.
    const token = (window.__ksUpdateRun = (window.__ksUpdateRun || 0) + 1);
    const stale = () => window.__ksUpdateRun !== token;
    btn.disabled = true;
    const res = await cmd('installUpdate').catch(() => null);
    // "Already running" is not a failure: attach to the download in
    // flight (started on the device, an earlier session, or one that
    // stalled) instead of erroring beside it (#272).
    if (!res?.ok && !/already running/.test(res?.error || '')) {
      btn.disabled = false;
      alert(`Update failed: ${res?.error || 'device unreachable'}`);
      return;
    }
    const cancelBtn = document.createElement('button');
    cancelBtn.className = 'btn-ghost';
    cancelBtn.textContent = 'Cancel';
    cancelBtn.style.marginLeft = '8px';
    cancelBtn.addEventListener('click', () => {
      cancelBtn.disabled = true;
      cmd('cancelUpdateDownload').catch(() => null);
    });
    btn.after(cancelBtn);
    // Ride the download via polling; when it settles the installer has
    // the rest (or the device will log why not). A few missed polls are
    // Wi-Fi blips on the tablet, not the end of the download.
    let st;
    let misses = 0;
    for (;;) {
      await new Promise((r) => setTimeout(r, 1000));
      if (stale()) { cancelBtn.remove(); return; }
      const cur = (await cmd('getUpdateStatus').catch(() => null))?.data;
      if (stale()) { cancelBtn.remove(); return; }
      if (!cur) { if (++misses >= 5) break; continue; }
      misses = 0;
      st = cur;
      if (st.progress === null || st.progress === undefined) break;
      btn.textContent = `Downloading… ${Math.round(st.progress * 100)}%`;
    }
    cancelBtn.remove();
    // The device re-checks GitHub before downloading, so the run can end
    // with nothing to install (the offered release was pulled and the
    // tablet is on the latest). Only say so when the device answered:
    // a poll lost to the install itself is not the same thing.
    if (st && !st.availableVersion) {
      btn.textContent = 'Already up to date';
      return;
    }
    if (st?.lastOutcome === 'cancelled') {
      btn.disabled = false;
      btn.textContent = idleLabel;
      return;
    }
    if (st?.lastOutcome === 'failed') {
      btn.disabled = false;
      btn.textContent = idleLabel;
      alert(st.lastError || 'Update failed. Check the device logs.');
      return;
    }
    if (st?.lastOutcome === 'silent') {
      btn.textContent = 'Installing…';
      return;
    }
    btn.textContent = 'Confirm on the tablet screen';
  };
  // Release notes first, then the download: the same flow as the
  // drawer's dialog on the device.
  btn.onclick = () => {
    const shell = modalShell({
      title: `Update to ${upd.availableVersion}`,
      width: 520,
    });
    const back = shell.back;
    const notes = shell.body;
    notes.style.cssText += 'font-size:13.5px; line-height:1.5;';
    // Markdown-lite, DOM-built so the release body stays inert text:
    // headings bold, list markers as bullets, emphasis/code/links stripped.
    const inline = (s) => s.replace(/\[([^\]]*)\]\([^)]*\)/g, '$1')
      .replace(/\*\*|__|`/g, '');
    const body = (upd.availableNotes || '').trim();
    if (!body) {
      notes.textContent = 'No release notes.';
    } else {
      for (const raw of body.split('\n')) {
        const line = raw.trimEnd();
        const p = document.createElement('div');
        if (!line.trim()) {
          p.style.height = '10px';
        } else if (/^#+\s*/.test(line)) {
          p.textContent = inline(line.replace(/^#+\s*/, ''));
          p.style.cssText = 'font-weight:700; margin-bottom:4px;';
        } else if (/^\s*[-*]\s+/.test(line)) {
          p.textContent = `•  ${inline(line.replace(/^\s*[-*]\s+/, ''))}`;
          p.style.marginBottom = '3px';
        } else {
          p.textContent = inline(line);
        }
        notes.appendChild(p);
      }
    }
    // The hint stays visible under the notes, above the fixed actions.
    const hint = document.createElement('div');
    hint.textContent = 'The download runs on the tablet; the installation '
      + 'must be confirmed on the tablet screen.';
    hint.style.cssText =
      'flex:none; margin:14px 0 0; font-size:12.5px; color:var(--muted);';
    shell.card.insertBefore(hint, shell.foot);
    const cancel = document.createElement('button');
    cancel.className = 'btn-text';
    cancel.textContent = 'Cancel';
    cancel.addEventListener('click', () => back.remove());
    const ok = document.createElement('button');
    ok.className = 'btn-primary';
    ok.textContent = 'Update';
    ok.addEventListener('click', () => { back.remove(); run(); });
    shell.foot.append(cancel, ok);
  };
  // A download already in flight when this tab renders (started from the
  // device, or the page reloaded mid-download): attach to it right away
  // rather than offering an Install button that would only error (#272).
  if (upd.progress !== null && upd.progress !== undefined) run();
}

export async function loadAboutInfo() {
  const root = $('#about-info');
  // Everything is fetched before the container is cleared: an await between
  // clear and append lets a second invocation interleave and the tab ends up
  // rendered twice.
  const [info, updRes] = await Promise.all([
    api('/api/info').then((r) => r.json()).catch(() => null),
    cmd('getUpdateStatus').catch(() => null),
  ]);
  const upd = updRes?.data;
  const or = (v, alt = '-') => (v === null || v === undefined || v === '' ? alt : v);

  root.innerHTML = '';
  const card = (title, rows) => {
    const h = document.createElement('h2');
    h.className = 'card-title';
    h.textContent = title;
    root.appendChild(h);
    const c = document.createElement('div'); c.className = 'card';
    for (const [k, v, d] of rows) {
      const row = document.createElement('div'); row.className = 'row';
      const cell = document.createElement('div'); cell.className = 'info';
      const n = document.createElement('div'); n.className = 'name'; n.textContent = k;
      cell.appendChild(n);
      if (d) {
        const dd = document.createElement('div');
        dd.className = 'desc'; dd.textContent = d;
        cell.appendChild(dd);
      }
      row.appendChild(cell);
      const val = document.createElement('span');
      val.style.cssText = 'text-align:right; word-break:break-all; max-width:60%';
      if (v instanceof Node) val.appendChild(v); else val.textContent = String(v);
      row.appendChild(val);
      c.appendChild(row);
    }
    root.appendChild(c);
  };
  const link = (text, href) => {
    const a = document.createElement('a');
    a.textContent = text; a.href = href;
    a.target = '_blank'; a.rel = 'noreferrer';
    return a;
  };

  // Which build this is decides where its logs go: a release build reports
  // to this page and stays silent on logcat.
  // The version doubles as a manual "check now" (the periodic check runs
  // only twice a day): tap it, the tab re-renders with the outcome.
  const versionEl = document.createElement('a');
  versionEl.textContent = `${or(info?.appVersion)} (${or(info?.buildNumber, '-')})`;
  versionEl.href = '#';
  versionEl.title = 'Check for updates now';
  versionEl.addEventListener('click', async (e) => {
    e.preventDefault();
    versionEl.textContent = 'Checking…';
    const res = (await cmd('checkUpdateNow').catch(() => null))?.data;
    await loadAboutInfo();
    if (!res?.reachable) {
      alert('Update check failed. Can the device reach GitHub?');
    } else if (!res.availableVersion) {
      messageBox({ title: 'Updates', message: 'You are on the latest version.' });
    }
  });
  card('App', [
    ['App version', versionEl],
    ['Build', or(info?.buildMode)],
    ['Package', or(info?.package)],
  ]);

  // The remote twin of the drawer's update slot: a newer GitHub release
  // gets an Install button; otherwise the row just says so. The download
  // runs on the tablet — the Android installer that follows can only be
  // confirmed on its screen.
  if (upd?.availableVersion) {
    const btn = document.createElement('button');
    btn.className = 'btn-ghost';
    btn.textContent = `Install version ${upd.availableVersion}`;
    attachUpdateInstall(btn, upd);
    const updRows = [['Update available', btn]];
    // No draw-over-apps grant means the relaunch receiver's activity start
    // is a background launch Android will abort: the update installs but
    // the kiosk stays closed. Same grant flow as the Auto-reload notice.
    if (upd.canRelaunch === false) {
      const grant = document.createElement('button');
      grant.className = 'btn-ghost';
      grant.textContent = 'Grant on device';
      grant.style.cssText = '';
      grant.addEventListener('click', async () => {
        grant.disabled = true;
        try {
          await api('/api/commands/requestOsPermissions', { method: 'POST',
            body: JSON.stringify({ which: ['overlay'] }) });
        } catch (_) {}
        for (let i = 0; i < 30; i++) {
          await new Promise((r) => setTimeout(r, 2500));
          try {
            const res = await (await api('/api/commands/getSystemPermissions', { method: 'POST', body: '{}' })).json();
            if ((res.data || {}).displayOverOtherApps) { loadAboutInfo(); return; }
          } catch (_) {}
        }
        grant.disabled = false;
      });
      updRows.push(['"Display over other apps" permission missing', grant,
        'Without it the app cannot reopen itself after updating. The grant screen appears on the tablet.']);
    }
    card('Updates', updRows);
  } else {
    card('Updates', [['Updates',
      upd ? 'Up to date' : or(null)]]);
  }

  const repo = link('jxlarrea/kiosk-satellite',
    'https://github.com/jxlarrea/kiosk-satellite');
  repo.insertAdjacentHTML('afterbegin',
    '<svg viewBox="0 0 24 24"><path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 ' +
    '3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015' +
    '-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695' +
    '-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 ' +
    '2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335' +
    '-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 ' +
    '1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295' +
    '-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 ' +
    '1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 ' +
    '0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0 0 ' +
    '24 12c0-6.63-5.37-12-12-12z"/></svg>');

  card('Attribution', [
    ['Author', link('Xavier Larrea', 'https://github.com/jxlarrea')],
    ['Source code', repo],
    ['License', link('CC BY-NC-ND 4.0',
      'https://github.com/jxlarrea/kiosk-satellite/blob/main/LICENSE')],
  ]);

  const p = document.createElement('p');
  p.style.cssText = 'color:var(--muted); font-size:.85rem; margin:4px 4px 0; line-height:1.5;';
  p.textContent = 'Kiosk Satellite is free for personal, non-commercial use. ' +
    'It is licensed under CC BY-NC-ND 4.0: you may use and share it, but ' +
    'commercial use and derivative works are not permitted.';
  root.appendChild(p);
}

// A dot on the About nav item when the device reports a newer release —
// the About tab is where the Install button lives, and nothing else on
// this page would say so.
export async function refreshUpdateBadge() {
  const upd = (await cmd('getUpdateStatus').catch(() => null))?.data;
  const title = document.querySelector('button[data-tab="about"] .nav-title');
  if (!title) return;
  title.querySelector('.nav-dot')?.remove();
  if (upd?.availableVersion) {
    const dot = document.createElement('span');
    dot.className = 'nav-dot';
    title.appendChild(dot);
  }
}

/* ---- Required system permissions (read-only) ---- */
// The same rows the device's own settings screen shows, from the same read.
// Status only, and deliberately: these are Android dialogs and settings
// screens, so only someone at the device can give them. A permission granted
// from another room would not be much of a permission.
export async function loadPermissions() {
  const root = $('#tab-voicesatellite');
  root.querySelector('#permsCard')?.remove();

  let p;
  try {
    const res = await cmd('getSystemPermissions');
    if (!res.ok) return;
    p = res.data;
  } catch { return; }

  // With wake word detection off the card keeps detection in the browser,
  // which asks for the microphone itself, none of this applies.
  if (!p.required) return;

  const wrap = document.createElement('div');
  wrap.id = 'permsCard';
  const h = document.createElement('h2');
  h.className = 'card-title';
  h.textContent = 'Required system permissions';
  const card = document.createElement('div');
  card.className = 'card';
  wrap.append(h, card);

  const rows = [
    ['Microphone', p.microphone,
      'Wake word detection can hear you.',
      p.microphoneBlocked
        ? 'Blocked. Android will not ask again.'
        : 'Nothing is listening for the wake word.'],
  ];
  if (p.background) {
    rows.push(
      ['Display over other apps', p.displayOverOtherApps,
        'Can come forward when it hears you.',
        'The wake word is heard and nothing happens.'],
      ['Notifications', p.notification,
        'The ongoing notification that enables background listening.',
        'Needed for background listening to work reliably.'],
      ['Unrestricted battery', p.batteryUnrestricted,
        'Android will leave the listener running.',
        'The listener is stopped after a few hours.'],
    );
  }

  let anyMissing = false;
  for (const [name, granted, held, missing] of rows) {
    if (!granted) anyMissing = true;
    const row = document.createElement('div'); row.className = 'row';
    const info = document.createElement('div'); info.className = 'info';
    info.innerHTML = `<div class="name"></div><div class="desc"></div>`;
    info.querySelector('.name').textContent = name;
    info.querySelector('.desc').textContent = granted ? held : missing;
    row.appendChild(info);
    const state = document.createElement('span');
    state.style.cssText =
      `white-space:nowrap; color:${granted ? 'var(--ok)' : 'var(--error)'}`;
    state.textContent = granted ? 'Granted' : 'Missing';
    row.appendChild(state);
    card.appendChild(row);
  }

  if (anyMissing) {
    // Say where to go, since it cannot be done from here.
    const note = document.createElement('div');
    note.className = 'desc';
    note.style.cssText = 'margin-top:12px; color:var(--warn)';
    note.textContent =
      'Grant these on the device itself: swipe in from the left edge → ' +
      'Settings → Voice Satellite → Required system permissions.';
    card.appendChild(note);
  }

  // Again right before appending: the removal at the top sits before an
  // await, so two overlapping runs (a wakeword-state push during the tab
  // load) would otherwise both pass it and stack two cards.
  root.querySelector('#permsCard')?.remove();
  root.appendChild(wrap);
}

export function readOnlyRow(name, desc, value) {
  const row = document.createElement('div'); row.className = 'row';
  const info = document.createElement('div'); info.className = 'info';
  info.innerHTML = `<div class="name"></div><div class="desc"></div>`;
  info.querySelector('.name').textContent = name;
  info.querySelector('.desc').textContent = desc;
  row.appendChild(info);
  const v = document.createElement('span');
  v.style.whiteSpace = 'nowrap';
  v.textContent = value;
  row.appendChild(v);
  return row;
}
