import { isHeadless } from './headless.js';
import { HEADLESS_ADB } from './permissions.js';
import { deviceTextMessageIds } from './device_text_ids.js';
import { supportTextMessageIds } from './support_text_ids.js';
import { voiceText, deviceText, deviceOperationError, supportText, t } from './localization.js';
import { $, api, apiUrl, cmd, state } from './core.js';
import { watchUpdates } from './live.js';
import { subpageEntry } from './tabs.js';
import { localizationCredits, localizationLanguageNames } from './localization_credits.js';
import { copyBox, hintRow, messageBox, modalShell, showToast } from './widgets.js';

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
      error = deviceText('Could not check the update helper.');
    }
    paint();
  };

  const paint = () => {
    group.replaceChildren();
    if (status?.nativeSilent === true) {
      group.appendChild(hintRow(deviceText('Android can now install updates silently. The helper is not needed.')));
      return;
    }
    const intro = hintRow(deviceText('This device currently needs confirmation on the screen to install updates through Android. '
      + 'The optional helper lets Kiosk Satellite install updates without a tap.'));
    intro.style.marginLeft = '4px';
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
    const row = readOnlyRow(deviceText('Helper status'), error || (busy
      ? deviceText('Installing an update.') : active
        ? deviceText('Ready. Updates install without confirmation.')
        : deviceText('Unavailable. Start the helper through ADB to enable updates without confirmation.')), '');
    row.querySelector('span').remove();
    const button = document.createElement('button');
    button.className = 'btn-ghost';
    button.textContent = deviceText('Refresh');
    button.addEventListener('click', async () => {
      button.disabled = true;
      await refresh();
    });
    row.appendChild(button);
    card.appendChild(row);

    note(deviceText('The helper survives app restarts and updates but stops after a device reboot. '
      + 'Run the command from a computer with ADB to start it again. The computer can then disconnect.'));
    if (status.startCommand) {
      const setup = readOnlyRow(deviceText('Start through ADB'), '', '');
      setup.querySelector('span').remove();
      const copy = copyBox(status.startCommand);
      copy.el.style.cssText = 'width:100%; max-width:none;';
      setup.querySelector('.info').appendChild(copy.el);
      card.appendChild(setup);
    }
    const docs = readOnlyRow(deviceText('Setup guide'), deviceText('Read the update helper instructions and requirements.'), '');
    docs.querySelector('span').remove();
    const link = document.createElement('a');
    link.className = 'btn-ghost';
    link.textContent = deviceText('Open guide');
    link.href = 'https://kiosksatellite.com/docs/updates/#optional-update-helper';
    link.target = '_blank';
    link.rel = 'noreferrer';
    docs.appendChild(link);
    card.appendChild(docs);
  };
  paint();
}

/* ---- Kiosk Satellite Analytics ---- */
// The page's intro and docs link, above its three switches: the same words
// the device puts there (_analyticsIntro in settings_screen.dart).
export const ANALYTICS_DOCS_URL =
  'https://kiosksatellite.com/docs/analytics/';

export function renderAnalyticsIntro(panel) {
  if (!panel) return;
  const card = document.createElement('div');
  card.className = 'card';
  const intro = document.createElement('div');
  intro.className = 'row desc';
  intro.textContent = deviceText('Share anonymized information from your installation to help make '
    + 'Kiosk Satellite better and guide which devices and features get attention.');
  card.appendChild(intro);
  const docs = readOnlyRow(deviceText('Learn how we process your data'),
    deviceText('What Kiosk Satellite Analytics sends and what it never sends.'), '');
  docs.querySelector('span').remove();
  const link = document.createElement('a');
  link.className = 'btn-ghost';
  link.textContent = deviceText('Open guide');
  link.href = ANALYTICS_DOCS_URL;
  link.target = '_blank';
  link.rel = 'noreferrer';
  docs.appendChild(link);
  card.appendChild(docs);
  panel.prepend(card);
}

/* ---- Updates ---- */
// The page's closing row: where to read how a custom repository is laid
// out, the same words the device puts there (_updateDocsUrl in
// settings_screen.dart).
export const UPDATE_DOCS_URL =
  'https://kiosksatellite.com/docs/updates/#custom-repository';

export function renderUpdateSourceDocs(panel) {
  if (!panel) return;
  renderUploadInstall(panel);
  const card = document.createElement('div');
  card.className = 'card';
  const docs = readOnlyRow(deviceText('Custom repository guide'),
    deviceText('How to host the releases file and the APKs on your own network.'), '');
  docs.querySelector('span').remove();
  docs.dataset.searchId = 'x:update_docs';
  const link = document.createElement('a');
  link.className = 'btn-ghost';
  link.textContent = deviceText('Open guide');
  link.href = UPDATE_DOCS_URL;
  link.target = '_blank';
  link.rel = 'noreferrer';
  docs.appendChild(link);
  card.appendChild(docs);
  panel.appendChild(card);
  // Android's own system updates (#1292) close the page, after the cards
  // above that belong to Kiosk Satellite's updates, as on the device.
  const android = panel.querySelector('[data-key="android_update.policy"]')?.closest('.card');
  if (android) {
    const heading = android.previousElementSibling;
    if (heading?.matches('h2.card-title')) panel.appendChild(heading);
    panel.appendChild(android);
  }
}

/* An APK from this computer, whatever GitHub says (#566): its own card on
   the Updates page, above the custom repository guide. An upload already
   waiting on the device (an earlier session, or a leader that pushed it)
   gets an Install row first, and an install in flight is ridden the
   moment the page renders. */
function renderUploadInstall(panel) {
  const card = document.createElement('div');
  card.className = 'card';
  const pick = readOnlyRow(deviceText('Install from file'),
    deviceText('Upload a Kiosk Satellite APK from this computer and install it. For a kiosk that cannot reach GitHub or a custom repository.'), '');
  pick.querySelector('span').remove();
  pick.dataset.searchId = 'x:update_upload';
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = deviceText('Install from file');
  attachUploadInstall(btn);
  pick.appendChild(btn);
  card.appendChild(pick);
  panel.appendChild(card);
  cmd('getUpdateStatus').then((r) => {
    const up = r?.data?.uploaded;
    if (!up) return;
    const row = readOnlyRow(deviceText('Uploaded APK'),
      t('deviceUploadedVersion', {version: up.version, build: String(up.buildNumber), size: (up.size / 1048576).toFixed(1)}), '');
    row.querySelector('span').remove();
    const inst = document.createElement('button');
    inst.className = 'btn-ghost';
    const idle = t('deviceInstallVersion', {version: up.version});
    inst.textContent = idle;
    inst.onclick = async () => {
      inst.disabled = true;
      const out = await cmd('installUploadedApk').catch(() => null);
      if (!out?.ok) {
        inst.disabled = false;
        await messageBox({ title: () => deviceText('Uploaded APK'), message: () => deviceOperationError(out?.error || deviceText('The device did not answer.')) });
        return;
      }
      await rideUploadedInstall(inst, idle);
    };
    row.appendChild(inst);
    card.insertBefore(row, pick);
    if (r.data.installing) rideUploadedInstall(inst, idle);
  }).catch(() => {});
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
        '<div class="card"><div class="desc" style="color:var(--muted)"></div></div>';
      panel.querySelector('.desc').textContent = deviceText('Reading…');
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
  const yn = (v) => (v === true ? deviceText('on') : v === false ? deviceText('off') : '-');
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
      h.textContent = deviceText(title);
      target.appendChild(h);
    }
    const c = document.createElement('div'); c.className = 'card';
    for (const [k, v] of rows) {
      if (v === undefined) continue;
      const row = document.createElement('div'); row.className = 'row';
      const info = document.createElement('div'); info.className = 'info';
      const n = document.createElement('div'); n.className = 'name'; n.textContent = deviceText(k);
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
    [deviceText('Device name'), or(info?.name)],
    [deviceText('Device model'), det?.brand && det?.brand !== det?.manufacturer
      ? `${or(info?.model)} (${det.brand})` : or(info?.model)],
    [deviceText('Android version'), `${or(info?.osVersion)}${info?.sdkInt ? ` (SDK ${info.sdkInt})` : ''}`],
    [deviceText('Android build'), or(det?.androidBuild)],
    [deviceText('IPv4 address'), or(info?.ip)],
    [deviceText('IPv6 addresses'), or((info?.ipv6 || []).join(', '))],
    [deviceText('App uptime'), dur(info?.uptime?.app)],
    // Since the app last saw the network come up, so it caps at the app
    // uptime; Android does not tell an app when the router associated.
    [deviceText('Network uptime'), dur(info?.uptime?.network)],
    [deviceText('CPU usage'), info?.cpu == null ? '-' : `${Math.round(info.cpu)}%`],
    [deviceText('CPU clock'), info?.cpuClock == null ? '-' : `${Math.round(info.cpuClock)} MHz`],
    [deviceText('CPU temperature'), info?.temp == null ? '-' : `${Math.round(info.temp)}°C`],
    [deviceText('Battery level'), info?.battery == null ? '-'
      : `${info.battery}%${info.charging ? ` (${deviceText('plugged')})` : ''}`],
    [deviceText('Battery temperature'), info?.batteryTemp == null ? '-'
      : `${info.batteryTemp.toFixed(1)}°C`],
    [deviceText('Screen brightness'), info?.brightness == null ? '-'
      : `${Math.round(info.brightness * 100)}% (${Math.round(info.brightness * 255)}/255)`],
    [deviceText('Screen status'), yn(screenOn)],
    [deviceText('Screen size'), det?.screen?.width == null ? '-'
      : `${det.screen.width}x${det.screen.height} px` +
        (det.screen.density ? ` @${det.screen.density}x` : '')],
    [deviceText('RAM (free/total)'), pair(mb(det?.ram?.free), mb(det?.ram?.total), 'MB') +
      (det?.ram?.low ? `, ${deviceText('low')}` : '')],
    [deviceText('Internal storage (free/total)'),
      pair(mb(det?.storage?.free), mb(det?.storage?.total), 'MB')],
  ]);

  card('Home Assistant', [
    [deviceText('Home Assistant URL'), or(S['ha.url'])],
    [deviceText('Wake word detection'), yn(S['wake_word.enabled'])],
    [deviceText('Wake word status'), or(wake?.statusLabel)],
    [deviceText('Engine'), or(wake?.engineLabel)],
    [deviceText('Wake words'), or((wake?.models || []).map((m) => m.wakeWord).join(', '))],
    [deviceText('Stop word'), or(wake?.stopWord)],
    [deviceText('Background listening'), yn(S['wake_word.background'])],
    [deviceText('Motion detection'), yn(motion)],
    [deviceText('Face detection'), yn(face)],
  ]);

  // Permissions used to be summarised here, read-only. The Permissions group
  // in the settings above this pane lists the same grants with what each one
  // is for and a button to give it, so a second copy on the same tab was
  // only a second thing to keep in step. Remote administration went for the
  // same reason: its port is a setting in that pane and the admin address is
  // the Access card.

  if (!isHeadless()) card('WebView', [
    // The system WebView, which updates itself independently of this app and
    // is the thing actually rendering the card.
    [deviceText('Provider'), or(det?.webview?.package)],
    [deviceText('Version'), or(det?.webview?.version)],
    [deviceText('User agent'), or(ua)],
  ]);
}

/* ---- About ---- */
// The same rows the device's own About page shows: app identity plus
// attribution and the license in one sentence.
/* The button's final word once the device has handed an APK to the
   installer (or failed to): shared by the download and the upload flows. */
function settleInstall(btn, st, idleLabel) {
  if (st?.lastOutcome === 'cancelled') {
    btn.disabled = false;
    btn.textContent = idleLabel;
    return;
  }
  if (st?.lastOutcome === 'failed') {
    btn.disabled = false;
    btn.textContent = idleLabel;
    messageBox({title: () => deviceText('Updates'), message: () => deviceOperationError(st.lastError || deviceText('Update failed. Check the device logs.'))});
    return;
  }
  if (st?.lastOutcome === 'silent') {
    setAboutLabel(btn, 'deviceInstalling');
    return;
  }
  setAboutLabel(btn, 'deviceConfirmTablet');
}

/* An APK from this computer, for a kiosk that can reach neither GitHub
   nor a file server (#566). XHR rather than fetch: an APK is close to
   200 MB and only XHR reports upload progress. Resolves to the endpoint's
   JSON, or an error shaped like one. */
function uploadApk(file, onProgress) {
  return new Promise((resolve) => {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', apiUrl('/api/update/upload'));
    xhr.setRequestHeader('Authorization', `Bearer ${state.token}`);
    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable) onProgress(e.loaded / e.total);
    };
    xhr.onload = () => {
      try { resolve(JSON.parse(xhr.responseText)); }
      catch (_) { resolve({ ok: false, error: t('deviceHttpError', {code: String(xhr.status)}) }); }
    };
    xhr.onerror = () => resolve({ ok: false, error: deviceText('The device did not answer.') });
    xhr.send(file);
  });
}

/* Rides an uploaded APK's install: no download to watch, only the hand-off
   to the installer, which ends with installing=false and lastOutcome set. */
async function rideUploadedInstall(btn, idleLabel) {
  let st;
  let misses = 0;
  btn.disabled = true;
  setAboutLabel(btn, 'deviceInstalling');
  for (;;) {
    await new Promise((r) => setTimeout(r, 1000));
    const cur = (await cmd('getUpdateStatus').catch(() => null))?.data;
    if (!cur) { if (++misses >= 5) break; continue; }
    misses = 0;
    st = cur;
    if (!st.installing) break;
  }
  settleInstall(btn, st, idleLabel);
}

/* The Install from file button: pick an APK, upload it, then confirm what
   arrived (version and build, as the device read them) before installing.
   A leader with followers gets a second choice, the whole fleet. */
export function attachUploadInstall(btn) {
  const idleLabel = btn.textContent;
  const picker = document.createElement('input');
  picker.type = 'file';
  picker.accept = '.apk,application/vnd.android.package-archive';
  picker.hidden = true;
  btn.after(picker);
  btn.onclick = () => picker.click();
  picker.addEventListener('change', async () => {
    const file = picker.files?.[0];
    picker.value = '';
    if (!file) return;
    btn.disabled = true;
    btn.textContent = t('deviceUploading', {percent: '0'});
    const res = await uploadApk(file, (f) => {
      btn.textContent = t('deviceUploading', {percent: String(Math.round(f * 100))});
    });
    if (!res?.ok) {
      btn.disabled = false;
      btn.textContent = idleLabel;
      await messageBox({ title: () => deviceText('Install from file'),
        message: () => deviceOperationError(res?.error || deviceText('The upload failed.')) });
      return;
    }
    const d = res.data || {};
    const mb = (d.size / 1048576).toFixed(1);
    const same = d.buildNumber === d.currentBuild;
    const fleet = (await cmd('fleetStatus').catch(() => null))?.data;
    const leads = !!fleet?.leader && (fleet.followers || []).some((f) => f.online);
    const buttons = ['Cancel', ...(leads ? ['Install on the fleet'] : []), 'Install'];
    const choice = await messageBox({
      title: t('deviceInstallVersion', {version: d.version}),
      message: t('deviceUploadedDetails', {version: d.version, build: String(d.buildNumber), size: mb}) + ' '
        + (same ? deviceText('The kiosk already runs this build.')
          : t('deviceCurrentBuild', {version: d.currentVersion, build: String(d.currentBuild)}))
        + '\n' + t('deviceInstallConfirmation'),
      buttons,
    });
    if (choice === 'Cancel') {
      btn.disabled = false;
      btn.textContent = idleLabel;
      return;
    }
    if (choice === 'Install on the fleet') {
      // The command answers once every follower has the file. Until then
      // the fleet status carries who is taking it and how far, pushed on
      // every step, so the button reads it out (#584).
      btn.textContent = deviceText('Sending to the fleet…');
      const stop = watchUpdates(['fleetsync'], async () => {
        const st = (await cmd('fleetStatus').catch(() => null))?.data?.install;
        if (!st || st.done) return;
        if (st.sendingTo) {
          btn.textContent = t('deviceSendingTo', {name: st.sendingTo, percent: String(Math.round((st.progress || 0) * 100))});
        } else if (st.started?.length) {
          btn.textContent = t('deviceInstallingOn', {name: st.started[st.started.length - 1]});
        }
      }, { owner: btn });
      const out = await cmd('fleetInstallUploaded').catch(() => null);
      stop();
      if (!out?.ok) {
        btn.disabled = false;
        btn.textContent = idleLabel;
        await messageBox({ title: () => deviceText('Install on the fleet'),
          message: () => deviceOperationError(out?.error || deviceText('The device did not answer.')) });
        return;
      }
      const data = out.data || {};
      const parts = [];
      if ((data.started || []).length) parts.push(t('deviceInstallingNames', {names: data.started.join(', ')}));
      if (data.self) parts.push(deviceText('This kiosk installs last.'));
      for (const [k, v] of Object.entries(data.skipped || {})) parts.push(`${k}: ${v}.`);
      showToast({ title: deviceText('Updating the fleet'), message: parts.join(' '),
        kind: data.started?.length || data.self ? 'success' : 'info' });
      if (!data.self) {
        btn.disabled = false;
        btn.textContent = idleLabel;
        return;
      }
    } else {
      const out = await cmd('installUploadedApk').catch(() => null);
      if (!out?.ok) {
        btn.disabled = false;
        btn.textContent = idleLabel;
        await messageBox({ title: () => deviceText('Install from file'),
          message: () => deviceOperationError(out?.error || deviceText('The device did not answer.')) });
        return;
      }
    }
    await rideUploadedInstall(btn, idleLabel);
  });
}

/* The Install button's whole life, shared by the About page and the
   Overview's Needs attention row: release notes, then the download on the
   tablet, ridden by polling until the installer has it. `btn` carries its
   idle label already. Read the current status when clicked because the
   Overview keeps the button when a newer release becomes available. */
export function attachUpdateInstall(btn, getUpdate) {
  const run = async (upd) => {
    const idleLabel = () => t('deviceInstallVersion', {version: upd.availableVersion});
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
      await messageBox({title: () => deviceText('Updates'), message: () => t('aboutDownloadFailed', {error: deviceOperationError(res?.error || supportText('device unreachable'))})});
      return;
    }
    const cancelBtn = document.createElement('button');
    cancelBtn.className = 'btn-ghost';
    setAboutLabel(cancelBtn, 'commonCancel');
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
      setAboutLabel(btn, 'aboutDownloadProgress', {percent: Math.round(st.progress * 100)});
    }
    cancelBtn.remove();
    // The device re-checks GitHub before downloading, so the run can end
    // with nothing to install (the offered release was pulled and the
    // tablet is on the latest). Only say so when the device answered:
    // a poll lost to the install itself is not the same thing.
    if (st && !st.availableVersion) {
      setAboutLabel(btn, 'aboutAlreadyCurrent');
      return;
    }
    settleInstall(btn, st, idleLabel());
    if (!btn.disabled) setAboutLabel(btn, 'deviceInstallVersion', {version: upd.availableVersion});
  };
  // Release notes first, then the download: the same flow as the
  // drawer's dialog on the device.
  btn.onclick = () => {
    const upd = getUpdate();
    if (!upd?.availableVersion) return;
    releaseNotesModal(upd.availableVersion, upd.availableNotes, 'aboutInstallHelp', () => run(upd));
  };
  // A download already in flight when this tab renders (started from the
  // device, or the page reloaded mid-download): attach to it right away
  // rather than offering an Install button that would only error (#272).
  const upd = getUpdate();
  if (upd?.progress !== null && upd?.progress !== undefined) run(upd);
}

/* The release notes of an update about to be installed, with a hint
   under them and Cancel and Update buttons. Update calls onOk. */
function releaseNotesModal(version, notesText, hintId, onOk) {
  const shell = modalShell({
    title: t('drawerUpdateTo', {version}),
    width: 520,
  });
  setAboutLabel(shell.card.querySelector('.modal-title'), 'drawerUpdateTo', {version});
  const back = shell.back;
  const notes = shell.body;
  notes.style.cssText += 'font-size:13.5px; line-height:1.5;';
  // Markdown-lite, DOM-built so the release body stays inert text:
  // headings bold, list markers as bullets, emphasis/code/links stripped.
  const inline = (s) => s.replace(/\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/\*\*|__|`/g, '');
  const body = (notesText || '').trim();
  if (!body) {
    setAboutLabel(notes, 'drawerNoReleaseNotes');
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
  setAboutLabel(hint, hintId);
  hint.style.cssText =
    'flex:none; margin:14px 0 0; font-size:12.5px; color:var(--muted);';
  shell.card.insertBefore(hint, shell.foot);
  const cancel = document.createElement('button');
  cancel.className = 'btn-text';
  setAboutLabel(cancel, 'commonCancel');
  cancel.addEventListener('click', () => back.remove());
  const ok = document.createElement('button');
  ok.className = 'btn-primary';
  setAboutLabel(ok, 'drawerUpdate');
  ok.addEventListener('click', () => { back.remove(); onOk(); });
  shell.foot.append(cancel, ok);
}

/* ---- System updates of the Echo images ----
   The image's updater (BiscuitService on the Dot, EchoService on the Shows)
   downloads the release, checks its signature and installs it through TWRP,
   rebooting the device twice. The About page's System card and
   the Overview's Needs attention row show it. The kiosk goes down with each
   reboot, so a running update is polled until it settles, whatever the
   connection does meanwhile. */
export const systemUpdateBusy = (s) => ['downloading', 'verifying', 'installing'].includes(s?.state);

function systemUpdateLabel(el, s) {
  if (s?.state === 'downloading') {
    setAboutLabel(el, 'aboutDownloadProgress', {percent: Math.round((s.progress || 0) * 100)});
  } else if (s?.state === 'verifying') {
    setAboutLabel(el, 'aboutSystemVerifying');
  } else {
    setAboutLabel(el, 'aboutSystemInstalling');
  }
}

/* Shows the update's progress on el until it settles, then calls onSettled
   with the last status. Stops when el leaves the page, which a re-rendered
   tab does. Gives up after half an hour without a settled answer, which no
   update takes. */
export async function rideSystemUpdate(el, onSettled) {
  const deadline = Date.now() + 30 * 60 * 1000;
  let last = null;
  systemUpdateLabel(el, {state: 'downloading', progress: 0});
  while (Date.now() < deadline) {
    const cur = (await cmd('getSystemUpdateStatus').catch(() => null))?.data;
    // Checked after the first answer: the caller may still be placing el.
    if (!el.isConnected) return;
    // Nothing while the Dot restarts: the label stays on installing.
    if (cur?.supported) {
      last = cur;
      if (!systemUpdateBusy(cur)) break;
      systemUpdateLabel(el, cur);
    } else if (last) {
      systemUpdateLabel(el, {state: 'installing'});
    }
    await new Promise((r) => setTimeout(r, 2000));
  }
  onSettled(last);
}

/* The Install button of a system update: release notes, then the install,
   ridden on the button. getStatus answers the status when clicked. */
export function attachSystemUpdateInstall(btn, getStatus, onSettled) {
  btn.onclick = () => {
    const sys = getStatus();
    if (!sys?.availableVersion) return;
    releaseNotesModal(sys.availableVersion, sys.availableNotes, 'aboutSystemRestartHelp', async () => {
      btn.disabled = true;
      const res = await cmd('installSystemUpdate').catch(() => null);
      if (!res?.ok) {
        btn.disabled = false;
        await messageBox({title: () => deviceText('Updates'), message: () => t('aboutDownloadFailed', {error: deviceOperationError(res?.error || supportText('device unreachable'))})});
        return;
      }
      rideSystemUpdate(btn, onSettled);
    });
  };
  if (systemUpdateBusy(getStatus())) {
    btn.disabled = true;
    rideSystemUpdate(btn, onSettled);
  }
}

const githubMark = '<svg aria-hidden="true" viewBox="0 0 24 24"><path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 ' +
    '3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015' +
    '-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695' +
    '-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 ' +
    '2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335' +
    '-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 ' +
    '1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295' +
    '-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 ' +
    '1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 ' +
    '0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0 0 ' +
    '24 12c0-6.63-5.37-12-12-12z"/></svg>';

export async function loadAboutInfo() {
  const root = $('#about-info');
  renderLocalizationCredits();
  // Everything is fetched before the container is cleared: an await between
  // clear and append lets a second invocation interleave and the tab ends up
  // rendered twice.
  const [info, updRes, sysRes] = await Promise.all([
    api('/api/info').then((r) => r.json()).catch(() => null),
    cmd('getUpdateStatus').catch(() => null),
    cmd('getSystemUpdateStatus').catch(() => null),
  ]);
  const upd = updRes?.data;
  const sys = sysRes?.data?.supported ? sysRes.data : null;
  const or = (v, alt = '-') => (v === null || v === undefined || v === '' ? alt : v);

  root.innerHTML = '';
  // A title or row name is the English text, or {id} for a message of
  // its own. A description is the English text or a node.
  const label = (el, text) => (typeof text === 'object'
    ? setAboutLabel(el, text.id, text.values || {})
    : setAboutLabel(el, supportTextMessageIds[text] || deviceTextMessageIds[text], {}, 'textContent', deviceText(text)));
  const card = (title, rows) => {
    const h = document.createElement('h2');
    h.className = 'card-title';
    label(h, title);
    root.appendChild(h);
    const c = document.createElement('div'); c.className = 'card';
    for (const [k, v, d] of rows) {
      const row = document.createElement('div'); row.className = 'row';
      const cell = document.createElement('div'); cell.className = 'info';
      const n = document.createElement('div'); n.className = 'name'; label(n, k);
      cell.appendChild(n);
      if (d instanceof Node) {
        d.classList.add('desc');
        cell.appendChild(d);
      } else if (d) {
        const dd = document.createElement('div');
        dd.className = 'desc'; setAboutLabel(dd, supportTextMessageIds[d], {}, 'textContent', d);
        cell.appendChild(dd);
      }
      row.appendChild(cell);
      const isAction = v instanceof HTMLButtonElement;
      const val = document.createElement(isAction ? 'div' : 'span');
      if (isAction) {
        row.classList.add('device-action-row');
        val.className = 'device-actions';
      } else {
        val.style.cssText = 'text-align:right; word-break:break-all; max-width:60%';
      }
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

  // The system image, above the app it runs: its release, the same tap
  // to check for a newer one, and the update itself. A newer image that
  // installs by hand gets its guide instead.
  if (sys) {
    const sysVersion = document.createElement('a');
    sysVersion.textContent = or(sys.currentVersion);
    sysVersion.href = '#';
    setAboutLabel(sysVersion, 'aboutCheckNow', {}, 'title');
    sysVersion.addEventListener('click', async (e) => {
      e.preventDefault();
      setAboutLabel(sysVersion, 'aboutChecking', {}, 'textContent');
      const res = (await cmd('checkSystemUpdateNow').catch(() => null))?.data;
      refreshUpdateBadge();
      await loadAboutInfo();
      if (!res?.reachable) {
        alert(supportText("Update check failed. Can the device reach GitHub?"));
      } else if (!res.availableVersion) {
        messageBox({ title: deviceText('Updates'), message: supportText("You are on the latest version.") });
      }
    });
    const failed = sys.lastError && !systemUpdateBusy(sys) ? document.createElement('div') : null;
    if (failed) setAboutLabel(failed, 'aboutDownloadFailed', {error: sys.lastError});
    let updateRow;
    if (systemUpdateBusy(sys)) {
      const progress = document.createElement('span');
      rideSystemUpdate(progress, () => { refreshUpdateBadge(); loadAboutInfo(); });
      updateRow = ['Updates', progress];
    } else if (sys.availableVersion) {
      const btn = document.createElement('button');
      btn.className = 'btn-ghost';
      setAboutLabel(btn, 'deviceInstallVersion', { version: sys.availableVersion });
      attachSystemUpdateInstall(btn, () => sys, () => { refreshUpdateBadge(); loadAboutInfo(); });
      updateRow = ['Update available', btn, failed];
    } else if (sys.manualVersion) {
      const guide = link('', sys.manualUrl);
      setAboutLabel(guide, 'deviceOpenGuide');
      const help = document.createElement('div');
      setAboutLabel(help, 'aboutSystemManualHelp', {version: sys.manualVersion});
      updateRow = [{id: 'aboutSystemManual'}, guide, help];
    } else {
      updateRow = ['Updates', aboutStatus('drawerUpdateCurrent'), failed];
    }
    const image = link(sys.repository.replace('https://github.com/', ''), sys.repository);
    image.insertAdjacentHTML('afterbegin', githubMark);
    card({id: 'aboutSystem'}, [
      [{id: 'aboutSystemVersion'}, sysVersion],
      updateRow,
      ['Source code', image],
    ]);
  }

  // Which build this is decides where its logs go: a release build reports
  // to this page and stays silent on logcat.
  // The version doubles as a manual "check now" (the periodic check runs
  // only twice a day): tap it, the tab re-renders with the outcome.
  const versionEl = document.createElement('a');
  versionEl.textContent = `${or(info?.appVersion)} (${or(info?.buildNumber, '-')})`;
  versionEl.href = '#';
  setAboutLabel(versionEl, 'aboutCheckNow', {}, 'title');
  versionEl.addEventListener('click', async (e) => {
    e.preventDefault();
    setAboutLabel(versionEl, 'aboutChecking', {}, 'textContent');
    const res = (await cmd('checkUpdateNow').catch(() => null))?.data;
    await loadAboutInfo();
    if (!res?.reachable) {
      alert(supportText("Update check failed. Can the device reach GitHub?"));
    } else if (!res.availableVersion) {
      messageBox({ title: deviceText('Updates'), message: supportText("You are on the latest version.") });
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
    setAboutLabel(btn, 'deviceInstallVersion', { version: upd.availableVersion });
    attachUpdateInstall(btn, () => upd);
    const updRows = [['Update available', btn]];
    // No draw-over-apps grant means the relaunch receiver's activity start
    // is a background launch Android will abort: the update installs but
    // the kiosk stays closed. Same grant flow as the Auto-reload notice.
    if (upd.canRelaunch === false) {
      const grant = document.createElement('button');
      grant.className = 'btn-ghost';
      setAboutLabel(grant, deviceTextMessageIds['Grant on device']);
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
      upd ? aboutStatus('drawerUpdateCurrent') : or(null)]]);
  }

  const repo = link('jxlarrea/kiosk-satellite',
    'https://github.com/jxlarrea/kiosk-satellite');
  repo.insertAdjacentHTML('afterbegin', githubMark);

  card('Attribution', [
    ['Author', link('Xavier Larrea', 'https://github.com/jxlarrea')],
    ['Website', link('kiosksatellite.com', 'https://kiosksatellite.com')],
    ['Source code', repo],
    ['License', link('CC BY-NC-ND 4.0',
      'https://github.com/jxlarrea/kiosk-satellite/blob/main/LICENSE')],
  ]);

  const p = document.createElement('p');
  p.style.cssText = 'color:var(--muted); font-size:.85rem; margin:4px 4px 0; line-height:1.5;';
  setAboutLabel(p, 'aboutLicenseSummary');
  const credits = document.createElement('div');
  credits.className = 'card';
  const entry = subpageEntry('about', 'Localization Credits');
  setAboutLabel(entry.querySelector('.name'), 'aboutLocalizationCredits');
  entry.querySelector('.desc').remove();
  credits.appendChild(entry);
  root.appendChild(credits);
  root.appendChild(p);
}

export function renderLocalizationCredits() {
  const root = $('#localization-credits');
  if (!root) return;
  root.replaceChildren();
  for (const [locale, contributors] of Object.entries(localizationCredits)) {
    const heading = document.createElement('h2');
    heading.className = 'card-title';
    heading.textContent = localizationLanguageNames[locale] || locale;
    const group = document.createElement('div');
    group.className = 'card';
    for (const contributor of contributors) {
      const row = document.createElement('div');
      row.className = 'row';
      const info = document.createElement('div');
      info.className = 'info';
      const label = document.createElement('div');
      label.className = 'name';
      label.textContent = contributor.name;
      info.appendChild(label);
      row.appendChild(info);
      if (contributor.login) {
        const profile = document.createElement('a');
        profile.href = `https://github.com/${contributor.login}`;
        profile.target = '_blank';
        profile.rel = 'noreferrer';
        profile.innerHTML = githubMark;
        const username = document.createElement('span');
        username.textContent = contributor.login;
        profile.appendChild(username);
        row.appendChild(profile);
      }
      group.appendChild(row);
    }
    root.append(heading, group);
  }
}

// A dot on the About nav item when the device reports a newer release —
// the About tab is where the Install button lives, and nothing else on
// this page would say so.
export async function refreshUpdateBadge() {
  const [upd, sys] = await Promise.all([
    cmd('getUpdateStatus').catch(() => null).then((r) => r?.data),
    cmd('getSystemUpdateStatus').catch(() => null).then((r) => r?.data),
  ]);
  const title = document.querySelector('button[data-tab="about"] .nav-title');
  if (!title) return;
  title.querySelector('.nav-dot')?.remove();
  if (upd?.availableVersion || sys?.availableVersion) {
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
  h.textContent = deviceText('Required system permissions');
  const card = document.createElement('div');
  card.className = 'card';
  wrap.append(h, card);

  const rows = [
    [deviceText('Microphone'), p.microphone,
      'Wake word detection can hear you.',
      p.microphoneBlocked
        ? 'Blocked. Android will not ask again, so allow it in the app settings.'
        : 'Without this nothing is listening for the wake word.'],
  ];
  const headless = isHeadless();
  // Without a screen there is nothing to come forward to, and the missing
  // grants are given over adb.
  if (headless) rows[0][3] = HEADLESS_ADB.microphone;
  if (p.background) {
    if (!headless) rows.push(
      [deviceText('Display over other apps'), p.displayOverOtherApps,
        'Kiosk Satellite can come forward when it hears you.',
        'Without this the wake word is heard and nothing happens.']);
    rows.push(
      [deviceText('Notifications'), p.notification,
        'The ongoing notification that enables background listening.',
        'Needed for background listening to work reliably.'],
      [deviceText('Unrestricted battery'), p.batteryUnrestricted,
        'Android will leave the listener running.',
        headless ? HEADLESS_ADB.batteryUnrestricted
          : 'Without this the listener is stopped after a few hours.'],
    );
  }

  let anyMissing = false;
  for (const [name, granted, held, missing] of rows) {
    if (!granted) anyMissing = true;
    const row = document.createElement('div'); row.className = 'row';
    const info = document.createElement('div'); info.className = 'info';
    info.innerHTML = `<div class="name"></div><div class="desc"></div>`;
    info.querySelector('.name').textContent = deviceText(name);
    info.querySelector('.desc').textContent = voiceText(granted ? held : missing);
    row.appendChild(info);
    const state = document.createElement('span');
    state.style.cssText =
      `white-space:nowrap; color:${granted ? 'var(--ok)' : 'var(--error)'}`;
    state.textContent = granted ? deviceText('Granted') : deviceText('Missing');
    row.appendChild(state);
    card.appendChild(row);
  }

  if (anyMissing && !headless) {
    // Say where to go, since it cannot be done from here.
    const note = document.createElement('div');
    note.className = 'desc';
    note.style.cssText = 'margin-top:12px; color:var(--warn)';
    note.textContent =
      voiceText('Grant these on the device itself: swipe in from the left edge → ' +
      'Settings → Voice Satellite → Required system permissions.');
    card.appendChild(note);
  }

  // Again right before appending: the removal at the top sits before an
  // await, so two overlapping runs (a wakeword-state push during the tab
  // load) would otherwise both pass it and stack two cards.
  root.querySelector('#permsCard')?.remove();
  root.appendChild(wrap);
}

export function readOnlyRow(name, desc, value, localize = true) {
  const row = document.createElement('div'); row.className = 'row';
  const info = document.createElement('div'); info.className = 'info';
  info.innerHTML = `<div class="name"></div><div class="desc"></div>`;
  info.querySelector('.name').textContent = localize ? deviceText(name) : name;
  info.querySelector('.desc').textContent = localize ? deviceText(desc) : desc;
  row.appendChild(info);
  const v = document.createElement('span');
  v.style.whiteSpace = 'nowrap';
  v.textContent = value;
  row.appendChild(v);
  return row;
}

// Track each translated property without replacing running update controls.
const aboutLabels = new WeakMap();
function setAboutLabel(el, id, values = {}, property = 'textContent', fallback = '') {
  el[property] = id ? t(id, values) : fallback;
  if (!id) return;
  const labels = aboutLabels.get(el) || {};
  labels[property] = { id, values, rendered: el[property] };
  aboutLabels.set(el, labels);
  el.dataset.aboutLabel = '';
}
function aboutStatus(id) {
  const el = document.createElement('span');
  setAboutLabel(el, id);
  return el;
}
document.addEventListener('ks-settings-cached', () => {
  document.querySelectorAll('[data-about-label]').forEach((el) => {
    for (const [property, label] of Object.entries(aboutLabels.get(el) || {})) {
      if (el[property] !== label.rendered) continue;
      el[property] = t(label.id, label.values);
      label.rendered = el[property];
    }
  });
});
