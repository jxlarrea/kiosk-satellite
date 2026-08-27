import {
  appendAudioDeviceRows,
  micLevelRow,
  prependMasterVolumeRow,
  toggleRow,
  updateMicChannelRow,
} from './audio.js';
import { MIC_GROUP_NOTE, exportFileName } from './cameras.js';
import { $, api, cmd, state } from './core.js';
import { readOnlyRow } from './device.js';
import { renderServicePage } from './service.js';
import { CATEGORY_TABS } from './gestures.js';
import {
  updateCameraFacingsRow,
  updateCameraGrantNotice,
  updateCameraSnapshotPanel,
  updateDimModeNotice,
  updateFaceRows,
  updateMotionCameraRows,
  updateNoCameraNotice,
  updateScreenOffAdminNotice,
} from './notices.js';
import {
  loadViewJump,
  updateAmbientDisplayNotice,
  updateAutoReloadOverlayNotice,
  updateBrightnessGrantNotices,
  updateImmichValidateRow,
  updateMaPlayerRow,
  updateMaValidateRow,
  updateMqttValidateRow,
} from './panels.js';
import { askImportOptions } from './pickers.js';
import { settingRow } from './rows.js';
import { applySubpageView, currentPath, setCurrentPath, subpageEntry } from './tabs.js';
import {
  fetchViews,
  pickView,
  radioRow,
  showWatchedEntities,
  viewPath,
} from './views.js';
import { loadVsPermissions, renderVsControls } from './vs.js';
import { banner, copyBox, messageBox, showToast } from './widgets.js';

export async function loadSettings() {
  // A re-render rebuilds every row; without restoring scroll, flipping a
  // mid-page toggle that reveals dependants yanks the view back to the top.
  const scroller = document.scrollingElement || document.documentElement;
  const keepScroll = scroller.scrollTop;
  const { settings, subpageHints } = await (await api('/api/settings')).json();
  state.settings = settings; // kept so a saved row can tell if it changes layout
  // Named once for every second-level page, including the ones with no
  // settings of their own (Voice Satellite's are live entity rows).
  state.subpageHints = subpageHints || {};

  // A setting can declare that it only means anything while another one is on
  // (dependsOn). The device hides those rows; so must we, or the two disagree
  // about the same device, and the remote copy is the one that gets believed
  // by whoever is not in the room. Transitive, matching the device: a row is
  // shown only if its dependency holds and that dependency is itself shown.
  const byKey = Object.fromEntries(settings.map((s) => [s.key, s]));
  // Mirrors SettingsManager.visible(): the dependency chain ignores the
  // `hidden` flag, a row may gate on a hidden bookkeeping flag (the media
  // playlist settings gate on media_is_folder, which is hidden), while
  // hidden rows themselves are simply never rendered.
  const depSatisfied = (s) => {
    if (!s.dependsOn) return true;
    const dep = byKey[s.dependsOn];
    if (!dep) return true;
    return dep.value === (s.dependsOnValue ?? true) && depSatisfied(dep);
  };
  const visible = (s) => !s.hidden && depSatisfied(s);

  // The Home Assistant Media mode only offers itself with HA connected.
  state.haConfigured = (byKey['ha.url']?.value || '') !== '' &&
    byKey['ha.token']?.value === '__set__';

  const byCat = {};
  settings.filter(visible).forEach((s) => (byCat[s.category] ??= []).push(s));


  // `handBuilt` names the second-level pages whose cards the caller supplies:
  // they still get their entry row and a panel, but nothing is rendered into
  // it. `extra` names pages no setting declares at all (Voice Satellite's
  // Appearance is nothing but live entity rows) — same deal, and their entry
  // rows follow the declared ones. Returns the panels by name to fill.
  const render = (root, cats, { handBuilt = [], extra = [], entryRoot = null } = {}) => {
    root.innerHTML = '';
    if (!cats.length) {
      root.innerHTML = '<div class="card"><div class="desc" style="color:var(--muted); padding:12px 0">Nothing here.</div></div>';
      return new Map();
    }
    // The tab these cards end up on: a second-level panel is its child, not
    // this root's (which may be a slice of the tab, e.g. the Home Assistant
    // settings between two hand-built cards).
    const tabEl = root.closest('.tab');
    const tab = tabEl ? tabEl.id.replace(/^tab-/, '') : null;
    // One UI shape, mirroring the device's settings panes: a small heading
    // floats above each rounded card, and settings sharing a `section` get a
    // card of their own (e.g. the motion controls under "Motion Detection").
    // A `subpage` goes one further and takes its settings off this page.
    const renderInto = (target, list, { subpage = null } = {}) => {
      for (const cat of cats) {
        const base = cat === cats[0] ? null : cat;
        let heading = base;
        let rows = [];
        // Whether the last thing emitted was a page entry. Each one is a
        // destination of its own, so it gets its own card: stacking unrelated
        // destinations in one card reads as a group of related settings.
        let entryRun = false;
        const flush = () => {
          if (!rows.length) return;
          // A page whose only group repeats its own title says it twice; the
          // page title already carries the name, so the heading goes.
          if (heading && !(heading === subpage && !target.children.length)) {
            const h = document.createElement('h2');
            h.className = 'card-title';
            h.textContent = heading;
            target.appendChild(h);
          }
          const card = document.createElement('div');
          card.className = 'card';
          rows.forEach((r) => card.appendChild(r));
          target.appendChild(card);
          rows = [];
        };
        const seen = new Set();
        (list[cat] || []).forEach((s) => {
          const sub = s.subpage || null;
          if (sub !== subpage) {
            // Off to its own page: the first setting of each subpage leaves
            // the entry row standing where the group used to be.
            if (sub && tab && !subpage && !seen.has(sub)) {
              seen.add(sub);
              flush();
              heading = null;
              entryRun = true;
              rows.push(subpageEntry(tab, sub));
            }
            return;
          }
          const want = s.section || base;
          if (entryRun || want !== heading) { flush(); entryRun = false; heading = want; }
          rows.push(settingRow(s));
        });
        flush();
      }
    };
    renderInto(root, byCat);
    // `entryRoot` gathers this tab's page entry rows somewhere else (the
    // Device page wants all of them together, just above the grants). It is
    // not this render's root, so it is cleared here, and the rows the
    // collapse already emitted inline move across in their original order —
    // ahead of the `extra` ones, which no setting declares.
    const entryTarget = entryRoot ? document.getElementById(entryRoot) : root;
    if (entryRoot && entryTarget) {
      entryTarget.innerHTML = '';
      root.querySelectorAll(':scope > .card').forEach((card) => {
        if (card.querySelector('[data-subpage-entry]')) entryTarget.appendChild(card);
      });
    }
    for (const sub of extra) {
      if (!entryTarget) break;
      const card = document.createElement('div');
      card.className = 'card';
      card.appendChild(subpageEntry(tab, sub));
      entryTarget.appendChild(card);
    }
    const panels = new Map();
    if (!tabEl) return panels;
    // Rebuilt with the tab, so a stale panel never survives a re-render.
    tabEl.querySelectorAll(':scope > .subpage').forEach((p) => p.remove());
    const subs = [];
    for (const cat of cats) {
      (byCat[cat] || []).forEach((s) => {
        if (s.subpage && !subs.includes(s.subpage)) subs.push(s.subpage);
      });
    }
    for (const sub of extra) if (!subs.includes(sub)) subs.push(sub);
    for (const sub of subs) {
      const panel = document.createElement('div');
      panel.className = 'subpage';
      panel.dataset.subpage = sub;
      if (!handBuilt.includes(sub) && !extra.includes(sub)) {
        renderInto(panel, byCat, { subpage: sub });
      }
      tabEl.appendChild(panel);
      panels.set(sub, panel);
    }
    // Re-open the page the person is on, in the same breath as rebuilding
    // the panels. Nothing may paint in between: the tab is still marked
    // sub-open, and with no open panel the CSS hides every one of its
    // children, so the page would blank for as long as the re-render's
    // device probes take. If that page is gone (the setting that declared
    // it went away), this drops back to the tab rather than leaving it
    // marked open with nothing to show.
    const slash = currentPath.indexOf('/');
    const openSub = slash > 0 && currentPath.slice(0, slash) === tab
      ? currentPath.slice(slash + 1)
      : '';
    if (openSub || tabEl.classList.contains('sub-open')) {
      if (!applySubpageView(tab, openSub) && openSub) setCurrentPath(tab);
    }
    return panels;
  };

  for (const [tabId, cats, opts] of CATEGORY_TABS) {
    if (tabId === 'tab-homeassistant') continue; // custom render below
    if (tabId === 'tab-voicesatellite') continue; // custom render below
    render(document.getElementById(tabId), cats.filter((c) => byCat[c]), opts);
  }

  // ── Required system permissions (Kiosk and Lockdown tabs) ────────────
  // Same shape as the Voice Satellite group: a row per grant with its
  // status, in its own card at the end of the tab. Unlike those, both of
  // these can be kicked off from here - the grant dialog or settings
  // screen opens on the device - so a Missing row carries a button.
  {
    const check = (cmd) => api('/api/commands/' + cmd,
      { method: 'POST', body: '{}' }).then((r) => r.json())
      .then((res) => res.data === true).catch(() => null);
    const pollOverlay = () => check('hasOverlayPermission');
    const pollGuard = () => check('hasUiGuard');
    const pollBattery = () => api('/api/commands/getSystemPermissions',
      { method: 'POST', body: '{}' }).then((r) => r.json())
      .then((res) => res.data ? res.data.batteryUnrestricted === true : null)
      .catch(() => null);
    const grantBattery = () => api('/api/commands/requestOsPermissions',
      { method: 'POST',
        body: JSON.stringify({ which: ['batteryOptimizations'] }) });
    const grantOverlay = () => api('/api/commands/requestOsPermissions',
      { method: 'POST', body: JSON.stringify({ which: ['overlay'] }) });
    const openGuard = () => api('/api/commands/openUiGuardSettings',
      { method: 'POST', body: '{}' });
    const permRow = (name, held, missing, btnText, onClick, poll) => {
      const row = document.createElement('div');
      row.className = 'row';
      const info = document.createElement('div');
      info.className = 'info';
      info.innerHTML = '<div class="name"></div><div class="desc"></div>';
      info.querySelector('.name').textContent = name;
      info.querySelector('.desc').textContent = 'Checking...';
      row.appendChild(info);
      const state = document.createElement('span');
      state.style.whiteSpace = 'nowrap';
      row.appendChild(state);
      const render = (ok) => {
        info.querySelector('.desc').textContent =
          ok === null ? 'Status unavailable.' : ok ? held : missing;
        state.textContent = ok === null ? '' : ok ? 'Granted' : 'Missing';
        state.style.color = ok ? 'var(--ok)' : 'var(--error)';
        row.querySelector('button')?.remove();
        if (ok !== false) return;
        const btn = document.createElement('button');
        btn.className = 'btn-ghost';
        btn.textContent = btnText;
        btn.style.cssText = 'flex-shrink:0;';
        btn.addEventListener('click', async () => {
          btn.disabled = true;
          try { await onClick(); } catch (_) { }
          // The grant happens on the tablet; keep re-reading until it
          // lands so the row flips by itself.
          let tries = 30;
          const tick = setInterval(async () => {
            const now = await poll();
            if (now === true || --tries <= 0) {
              clearInterval(tick);
              render(now);
            }
          }, 2000);
        });
        row.appendChild(btn);
      };
      poll().then(render);
      return row;
    };
    const group = (tabId, rows) => {
      const tab = document.getElementById(tabId);
      const h = document.createElement('h2');
      h.className = 'card-title';
      h.textContent = 'Required system permissions';
      const card = document.createElement('div');
      card.className = 'card';
      rows.forEach((r) => card.appendChild(r));
      tab.append(h, card);
      return [h, card];
    };
    group('tab-kiosk', [
      permRow('Display over other apps',
        'Kiosk Satellite can bring itself back in the foreground.',
        'Without this the kiosk cannot bring itself back. The grant '
          + 'screen appears on the tablet.',
        'Grant on device', grantOverlay, pollOverlay),
      permRow('System UI guard',
        'The notification shade and recents close on their own while '
          + 'the screen is protected.',
        'Without this the notification shade and recents stay reachable. '
          + 'Enable Kiosk Satellite under Accessibility on the tablet.',
        'Open settings on device', openGuard, pollGuard),
    ]);
    group('tab-lockdown', [
      permRow('Display over other apps',
        'The lockdown shield can cover the whole screen.',
        'Without this the shield only covers the app. The grant screen '
          + 'appears on the tablet.',
        'Grant on device', grantOverlay, pollOverlay),
      permRow('System UI guard',
        'The notification shade and recents close on their own while '
          + 'the screen is protected.',
        'Without this the notification shade and recents stay reachable. '
          + 'Enable Kiosk Satellite under Accessibility on the tablet.',
        'Open settings on device', openGuard, pollGuard),
    ]);
    // The App Launcher's group answers for Return automatically alone
    // (issue #317), so it shows only while that switch is on, following
    // the toggles in place rather than through a re-render, the same as
    // the device page.
    {
      const launcherGroup = group('tab-launcher', [
        permRow('Display over other apps',
          'Kiosk Satellite can bring itself back in the foreground and '
            + 'notice touches in the other app.',
          'Without this the kiosk cannot come back on its own, and touches '
            + 'in the other app go unseen. The grant screen appears on the '
            + 'tablet.',
          'Grant on device', grantOverlay, pollOverlay),
        permRow('Unrestricted battery',
          'Allows the process to run in the background without being '
            + 'paused or killed.',
          'Android may pause the app behind the other one, and a paused '
            + 'clock never brings the kiosk back. The grant dialog appears '
            + 'on the tablet.',
          'Grant on device', grantBattery, pollBattery),
      ]);
      const tab = document.getElementById('tab-launcher');
      const on = (key) => {
        const cb = tab.querySelector(
          `[data-key="${key}"] input[type="checkbox"]`);
        return !!cb && cb.checked;
      };
      const sync = () => {
        const show = on('launcher.enabled') && on('launcher.auto_return');
        launcherGroup.forEach((el) => el.classList.toggle('hidden', !show));
      };
      // Delegated: the auto-return row comes and goes with the master
      // switch (dependsOn), so a listener on the row itself would be lost.
      tab.addEventListener('change', (e) => {
        const key = e.target.closest?.('[data-key]')?.dataset.key;
        if (key === 'launcher.enabled' || key === 'launcher.auto_return') {
          setTimeout(sync, 50);
        }
      });
      sync();
    }
  }

  // ── Freshly generated encryption key ─────────────────────────────────
  // The key is written by the manager ~500ms after Enable ESPHome is
  // switched on, after the re-render this very code runs in, so the key
  // row would keep its placeholder and the page would read as if enabling
  // did nothing. Re-render shortly until the key shows up (bounded: the
  // key always exists once the manager has run).
  if (byKey['esphome.enabled']?.value === true &&
      !(byKey['btproxy.key']?.value) && !window.__esphomeKeyWait) {
    window.__esphomeKeyRetries = (window.__esphomeKeyRetries || 0) + 1;
    if (window.__esphomeKeyRetries <= 5) {
      window.__esphomeKeyWait = setTimeout(() => {
        window.__esphomeKeyWait = null;
        loadSettings();
      }, 1500);
    }
  } else if (byKey['btproxy.key']?.value) {
    window.__esphomeKeyRetries = 0;
  }

  // ── MQTT sunset notice ───────────────────────────────────────────────
  // Atop the MQTT tab: ESPHome is the integration path now, and nobody
  // should build new automations on a surface with a removal date.
  {
    const root = document.getElementById('tab-mqtt');
    const warn = document.createElement('div');
    warn.style.cssText = 'display:flex; gap:8px; align-items:flex-start; ' +
      'margin:0 0 14px; font-size:13px; color:var(--warn); line-height:1.5';
    warn.innerHTML = '<svg width="15" height="15" viewBox="0 0 24 24" ' +
      'fill="none" stroke="currentColor" stroke-width="2" ' +
      'stroke-linecap="round" stroke-linejoin="round" ' +
      'style="flex:none; margin-top:2px">' +
      '<path d="M10.3 3.9 1.9 18a2 2 0 0 0 1.7 3h16.8a2 2 0 0 0 ' +
      '1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/>' +
      '<path d="M12 9v4M12 17h.01"/></svg><span></span>';
    warn.querySelector('span').textContent =
      'ESPHome is now the preferred integration and MQTT will be removed ' +
      'in a future version. See the ESPHome section to migrate.';
    root.insertBefore(warn, root.firstChild);
  }

  // ── Duplicate-entities warning ───────────────────────────────────────
  // Both entity surfaces on at once means every kiosk entity exists
  // twice in Home Assistant; warn where the choice is made, mirroring
  // the device page.
  if (byKey['esphome.entities']?.value === true &&
      depSatisfied(byKey['esphome.entities']) &&
      byKey['mqtt.enabled']?.value === true) {
    const row = document.querySelector('[data-key="esphome.entities"]');
    if (row) {
      const warn = document.createElement('div');
      warn.style.cssText = 'display:flex; gap:8px; ' +
        'align-items:flex-start; margin:6px 0 10px; ' +
        'font-size:12.5px; color:var(--warn); line-height:1.5';
      warn.innerHTML = '<svg width="15" height="15" ' +
        'viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
        'stroke-width="2" stroke-linecap="round" ' +
        'stroke-linejoin="round" style="flex:none; margin-top:2px">' +
        '<path d="M10.3 3.9 1.9 18a2 2 0 0 0 1.7 3h16.8a2 2 0 0 0 ' +
        '1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/>' +
        '<path d="M12 9v4M12 17h.01"/></svg><span></span>';
      warn.querySelector('span').textContent =
        'MQTT is also enabled: these entities will exist twice in ' +
        'Home Assistant, once per integration.';
      row.insertAdjacentElement('afterend', warn);
    }
  }

  // ── Real-MAC identity outcome ────────────────────────────────────────
  // What the switch actually did, right under it, mirroring the device
  // page; refreshed in place when the switch or the typed address changes
  // (see save() in rows.js), so the answer never waits for a reload.
  refreshRealMacNote();

  // ── ESPHome encryption key: the copy box ──────────────────────────────
  // The key is read back and pasted into Home Assistant, never typed: a
  // read-only box that copies the whole key on tap, mirroring the device
  // row. Double-clicking a bare key selected only part of it (a double
  // click stops at the +, / and = a base64 key is full of) and a partial
  // key pasted into Home Assistant fails with a generic "unable to
  // connect".
  {
    const row = document.querySelector('[data-key="btproxy.key"]');
    const input = row?.querySelector('input');
    if (input && !row.querySelector('.copy-box')) {
      input.replaceWith(copyBox(input.value, {
        placeholder: input.placeholder || 'Not set' }).el);
    }
  }

  // ── Notifications page (issue #320) ──────────────────────────────────
  // Mirror of the device's page: where notifications come from and a
  // button that sends one, above the sound and volume rows. The sound row
  // is a dropdown over the device's sounds folder, and the row under it
  // uploads a file from this computer into that folder the way the Files
  // tab uploads. Only while the page exists, which is the ESPHome master's
  // call (every row on it gates on it).
  {
    const root = document.getElementById('tab-esphome');
    const panel = root?.querySelector('.subpage[data-subpage="Notifications"]');
    if (panel) {
      const node = `${byKey['esphome.node_name']?.value || ''}`.trim();
      const action = node
        ? `esphome.${node.replace(/-/g, '_')}_notification`
        : 'esphome.<node name>_notification';
      const row = readOnlyRow('Test notification',
        `Notifications are sent from Home Assistant with the ${action} `
        + 'action. Test shows one over the dashboard.', '');
      const test = document.createElement('button');
      test.className = 'btn-ghost';
      test.textContent = 'Test';
      test.style.cssText = 'flex-shrink:0;';
      test.addEventListener('click', async () => {
        test.disabled = true;
        try {
          await cmd('showNotification', {
            title: 'Test notification',
            message: 'This is what a notification from Home Assistant looks and sounds like.',
            type: 'info',
            icon: 'mdi:bell-ring',
          });
          test.textContent = 'Sent';
        } catch (_) { test.textContent = 'Failed'; }
        setTimeout(() => { test.textContent = 'Test'; test.disabled = false; }, 2000);
      });
      row.appendChild(test);
      const card = document.createElement('div');
      card.className = 'card';
      card.appendChild(row);
      panel.prepend(card);

      const fileRow = panel.querySelector('[data-key="notifications.chime_file"]');
      const setting = byKey['notifications.chime_file'];
      if (fileRow && setting) {
        // The dropdown over the sounds folder, filled from the device's own
        // listing so this page and the tablet always offer the same files.
        fileRow.querySelector('input')?.remove();
        const sel = document.createElement('select');
        const fill = (sounds) => {
          sel.innerHTML = '';
          const current = `${setting.value || ''}`;
          const names = [...sounds];
          // A stored name whose file has gone stays visible, marked, rather
          // than silently reading as the built-in chime.
          if (current && !names.includes(current)) names.push(current);
          [['', 'Built-in chime'], ...names.map((n) => [n, n === current && !sounds.includes(n) ? `${n} (missing)` : n])]
            .forEach(([value, label]) => {
              const opt = document.createElement('option');
              opt.value = value; opt.textContent = label;
              opt.selected = value === current;
              sel.appendChild(opt);
            });
        };
        const refresh = async () => {
          let sounds = [];
          try { sounds = ((await cmd('listNotificationSounds')).data || {}).sounds || []; }
          catch (_) {}
          fill(sounds);
        };
        const write = async (name) => {
          const res = await api('/api/settings', {
            method: 'PATCH', body: JSON.stringify({ 'notifications.chime_file': name }),
          });
          const out = await res.json().catch(() => ({}));
          if (!res.ok || out.rejected?.includes('notifications.chime_file')) {
            throw new Error(out.errors?.['notifications.chime_file'] || `HTTP ${res.status}`);
          }
          setting.value = name;
        };
        sel.addEventListener('change', async () => {
          try { await write(sel.value); }
          catch (e) { alert('Not saved: ' + (e.message || e)); await refresh(); }
        });
        fill([]);
        fileRow.appendChild(sel);
        refresh();

        // The row under it puts a file from this computer into the folder,
        // the remote's twin of the device's Browse. Same allowlist as
        // notificationSoundExtensions in definitions.dart: what every
        // supported Android decodes natively, no video containers. The
        // accept list steers the chooser; the check here and the device's
        // validator are what actually hold.
        const SOUND_EXTENSIONS = ['mp3', 'ogg', 'oga', 'wav', 'flac', 'm4a', 'aac'];
        const addRow = readOnlyRow('Add a sound',
          'Upload a sound file from this computer into the sounds folder.', '');
        const upload = document.createElement('button');
        upload.className = 'btn-ghost';
        upload.textContent = 'Upload';
        upload.style.cssText = 'flex-shrink:0;';
        const picker = document.createElement('input');
        picker.type = 'file'; picker.hidden = true;
        picker.accept = SOUND_EXTENSIONS.map((e) => `.${e}`).join(',');
        picker.addEventListener('change', async () => {
          const file = picker.files && picker.files[0];
          if (!file) return;
          const ext = (file.name.match(/\.([^.]+)$/) || [, ''])[1].toLowerCase();
          if (!SOUND_EXTENSIONS.includes(ext)) {
            picker.value = '';
            alert('Not a supported sound: pick an MP3, OGG, WAV, FLAC, M4A or AAC file.');
            return;
          }
          upload.disabled = true; upload.textContent = 'Uploading…';
          try {
            const q = `root=app&path=${encodeURIComponent(`sounds/${file.name}`)}`;
            const res = await api(`/api/files/upload?${q}`, { method: 'POST', body: file });
            const out = await res.json().catch(() => ({}));
            if (!res.ok) throw new Error(out.error || `HTTP ${res.status}`);
            // The upload becomes the pick, as it does on the device.
            await write(file.name);
            await refresh();
          } catch (e) { alert('Upload failed: ' + (e.message || e)); }
          picker.value = '';
          upload.disabled = false; upload.textContent = 'Upload';
        });
        upload.addEventListener('click', () => picker.click());
        addRow.append(upload, picker);
        fileRow.insertAdjacentElement('afterend', addRow);
      }
    }
  }

  // ── Bluetooth Proxy nearby devices ───────────────────────────────────
  // The live list the device shows under the lookup toggle, same data:
  // the btProxyNearby command's identified inventory. Only with the proxy
  // on; refreshes itself while the page is open (the timer is module-level
  // so a settings re-render replaces it instead of stacking another).
  // byKey, not the permissions block's on() helper: that one is const
  // inside a later block, and reaching for it from here is a
  // ReferenceError that kills everything loadSettings still had to do.
  // Value AND chain: btproxy.enabled keeps its stored true while the
  // ESPHome master is off, but its row (and everything riding it) is
  // gated away; the hand-built cards must follow the same rule or they
  // linger on a page whose settings rows have all vanished.
  if (byKey['btproxy.enabled']?.value === true &&
      depSatisfied(byKey['btproxy.enabled'])) {
    // No heading of its own: the lookup toggle's "Nearby devices" section
    // heading (from the definitions) already labels this stretch of the
    // page, and the list card slots in right under it. That heading is on
    // the Bluetooth Proxy page now, so the list goes there too rather than
    // stranding itself on the ESPHome page above.
    const root = document.getElementById('tab-esphome');
    const btPanel = root.querySelector('.subpage[data-subpage="Bluetooth Proxy"]');
    const card = document.createElement('div');
    card.className = 'card';
    card.id = 'btproxy-nearby-card';
    const empty = document.createElement('div');
    empty.className = 'desc';
    empty.textContent = 'Nothing heard yet.';
    card.appendChild(empty);
    (btPanel || root).appendChild(card);
    // Same ordering rules as the device list (sortNearbyJson in
    // ble_identity.dart); the sort select saves like any setting, and the
    // re-render plus the 15s poll both read its live value from the row.
    const nearbySort = (devices) => {
      const mode = document.querySelector(
        '[data-key="btproxy.nearby_sort"] select')?.value ||
        (state.settings || []).find((o) => o.key === 'btproxy.nearby_sort')
          ?.value || 'last_seen';
      const byMac = (a, b) => `${a.mac}`.localeCompare(`${b.mac}`);
      // Connected devices lead whatever the sort, mirroring the device
      // list: they can never fall past the display cap.
      if (devices.some((d) => d.connected)) {
        return [
          ...nearbySort(devices.filter((d) => d.connected)
            .map((d) => ({ ...d, connected: false }))).map(
            (d) => ({ ...d, connected: true })),
          ...nearbySort(devices.filter((d) => !d.connected)),
        ];
      }
      const out = [...devices];
      if (mode === 'name') {
        out.sort((a, b) => {
          const an = `${a.identity || ''}`.toLowerCase();
          const bn = `${b.identity || ''}`.toLowerCase();
          const au = an.startsWith('unknown'), bu = bn.startsWith('unknown');
          if (au !== bu) return au ? 1 : -1;
          return an.localeCompare(bn) || byMac(a, b);
        });
      } else if (mode === 'mac') {
        out.sort(byMac);
      } else if (mode === 'rssi') {
        out.sort((a, b) => ((b.rssi ?? -128) - (a.rssi ?? -128)) || byMac(a, b));
      } else {
        out.sort((a, b) =>
          `${b.last_seen}`.localeCompare(`${a.last_seen}`) || byMac(a, b));
      }
      return out;
    };
    const renderNearby = (devices) => {
      card.innerHTML = '';
      if (!devices.length) { card.appendChild(empty); return; }
      devices = nearbySort(devices);
      for (const d of devices.slice(0, 25)) {
        const row = document.createElement('div');
        row.className = 'row';
        const info = document.createElement('div');
        info.className = 'info';
        info.innerHTML = '<div class="name"></div><div class="desc"></div>';
        info.querySelector('.name').textContent =
          (d.identity || 'Unknown device') +
          (d.rotating ? '  (rotating address)' : '');
        if (d.connected) {
          // The devices this kiosk is actively serving a Home Assistant
          // connection for; accent, not a signal tier color.
          const link = document.createElement('span');
          link.style.cssText = 'background:var(--accent); ' +
            'color:var(--surface); border-radius:6px; padding:0 6px 1px; ' +
            'font-size:11.5px; margin-left:8px; white-space:nowrap';
          link.textContent = 'Connected';
          info.querySelector('.name').appendChild(link);
        }
        const seen = d.last_seen ? new Date(d.last_seen) : null;
        const age = seen ? Math.max(0, (Date.now() - seen) / 1000) : null;
        const ageText = age === null ? '' :
          age < 60 ? `${Math.round(age)}s ago` :
          age < 3600 ? `${Math.round(age / 60)}m ago` :
          `${Math.round(age / 3600)}h ago`;
        // Same tiers as rssiTier in ble_identity.dart: -65 and up is
        // same-room, to -84 adjacent-room, below that edge of range.
        const rssi = d.rssi ?? -128;
        const tier = rssi >= -65 ? 'var(--ok)' :
          rssi >= -84 ? 'var(--warn)' : 'var(--error)';
        const desc = info.querySelector('.desc');
        desc.textContent = [
          d.mac,
          d.vendor && d.vendor !== d.identity ? d.vendor : null,
          '',
        ].filter((x) => x !== null).join('  ·  ');
        // A tag, not a dot: the number itself wears the tier color.
        // var(--surface) as the text keeps contrast in both themes (white
        // on the dark-toned light palette, near-black on the dark one).
        const tag = document.createElement('span');
        tag.style.cssText = `background:${tier}; color:var(--surface); ` +
          'border-radius:6px; padding:0 6px 1px; font-size:11.5px; ' +
          'white-space:nowrap';
        tag.textContent = `${d.rssi} dBm`;
        desc.appendChild(tag);
        desc.appendChild(document.createTextNode(`  ·  ${ageText}`));
        row.appendChild(info);
        card.appendChild(row);
      }
      if (devices.length > 25) {
        const more = document.createElement('div');
        more.className = 'desc';
        more.style.cssText = 'margin-top:8px';
        more.textContent = `Showing the first 25 of ${devices.length}.`;
        card.appendChild(more);
      }
    };
    const pollNearby = () => api('/api/commands/btProxyNearby',
      { method: 'POST', body: '{}' }).then((r) => r.json())
      .then((res) => { if (document.getElementById('btproxy-nearby-card'))
        renderNearby(res.data?.devices || []); })
      .catch(() => {});

    // The connection budget under the toggle that spends it, mirroring
    // the device page: a hard Android-stack limit per proxy.
    if (byKey['btproxy.connections']?.value === true) {
      api('/api/commands/esphomeStatus', { method: 'POST', body: '{}' })
        .then((r) => r.json())
        .then((res) => {
          const slots = res.data?.connectionSlots || 0;
          const row = document.querySelector(
            '[data-key="btproxy.connections"]');
          if (!slots || !row) return;
          const note = document.createElement('div');
          note.style.cssText = 'display:flex; gap:8px; ' +
            'align-items:flex-start; margin:6px 0 10px; ' +
            'font-size:12.5px; color:var(--muted); line-height:1.5';
          note.innerHTML = '<svg width="15" height="15" ' +
            'viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
            'stroke-width="2" stroke-linecap="round" ' +
            'style="flex:none; margin-top:2px">' +
            '<circle cx="12" cy="12" r="9"/>' +
            '<path d="M12 8h.01M12 11.5V16"/></svg><span></span>';
          note.querySelector('span').textContent =
            `Up to ${slots} devices can be connected at once through ` +
            'this proxy. Home Assistant routes further devices through ' +
            'other proxies.';
          row.insertAdjacentElement('afterend', note);
        })
        .catch(() => {});
    }
    if (window.__btNearbyTimer) clearInterval(window.__btNearbyTimer);
    window.__btNearbyTimer = setInterval(pollNearby, 15000);
    // Flipping the sort re-orders the list now, not at the next poll.
    document.querySelector('[data-key="btproxy.nearby_sort"] select')
      ?.addEventListener('change', () => setTimeout(pollNearby, 50));
    pollNearby();

    // Required system permissions, the per-feature group the Voice
    // Satellite and Kiosk tabs carry. The grant dialog opens on the
    // device; the row polls until it lands, like the Kiosk rows.
    {
      const h = document.createElement('h2');
      h.className = 'card-title';
      h.textContent = 'Required system permissions';
      const permCard = document.createElement('div');
      permCard.className = 'card';
      // Two rows, two grants: the Bluetooth pair (a formality below
      // Android 12) and the location gate Android ties Bluetooth scanning
      // to on every version, beacons included (issues #240, #246).
      const makeRow = (name) => {
        const row = document.createElement('div');
        row.className = 'row';
        const info = document.createElement('div');
        info.className = 'info';
        info.innerHTML = '<div class="name"></div><div class="desc"></div>';
        info.querySelector('.name').textContent = name;
        info.querySelector('.desc').textContent = 'Checking...';
        row.appendChild(info);
        const stateEl = document.createElement('span');
        stateEl.style.whiteSpace = 'nowrap';
        row.appendChild(stateEl);
        permCard.appendChild(row);
        return { row, info, stateEl };
      };
      const pairRow = makeRow('Nearby devices');
      const locRow = makeRow('Location');
      // On the Bluetooth Proxy page, right above the Nearby devices group
      // whose list stays empty without them, the same place the device
      // page puts it. The page above is the fallback while the panel is
      // not there (the proxy row hidden).
      const nearbyHead = btPanel && [...btPanel.querySelectorAll('h2.card-title')]
        .find((x) => x.textContent === 'Nearby devices');
      if (nearbyHead) {
        btPanel.insertBefore(h, nearbyHead);
        btPanel.insertBefore(permCard, nearbyHead);
      } else {
        (btPanel || root).append(h, permCard);
      }
      const readPerm = () => api('/api/commands/getSystemPermissions',
        { method: 'POST', body: '{}' }).then((r) => r.json())
        .then((res) => res.data || null).catch(() => null);
      const paintRow = ({ row, info, stateEl }, ok, held, missing) => {
        info.querySelector('.desc').textContent = ok === null
          ? 'Status unavailable.' : ok ? held : missing;
        stateEl.textContent = ok === null ? '' : ok ? 'Granted' : 'Missing';
        stateEl.style.color = ok ? 'var(--ok)' : 'var(--error)';
        row.querySelector('button')?.remove();
        if (ok !== false) return;
        const btn = document.createElement('button');
        btn.className = 'btn-ghost';
        btn.textContent = 'Grant on device';
        btn.style.cssText = 'flex-shrink:0;';
        btn.addEventListener('click', async () => {
          btn.disabled = true;
          try {
            // One request covers both rows: the device runs the whole
            // flow (pair dialog, location dialog, location settings
            // screen when the system switch is off).
            await api('/api/commands/requestOsPermissions', { method: 'POST',
              body: JSON.stringify(
                { which: ['bluetoothScan', 'bluetoothConnect'] }) });
          } catch (_) {}
          for (let i = 0; i < 30; i++) {
            await new Promise((r) => setTimeout(r, 2500));
            const now = await readPerm();
            if (now && now.bluetooth === true) { paint(now); return; }
          }
          btn.disabled = false;
        });
        row.appendChild(btn);
      };
      const paint = (perms) => {
        const p = perms === null ? null : perms;
        paintRow(pairRow, p === null ? null : p.bluetoothPair === true,
          'The proxy can scan for nearby Bluetooth devices.',
          'Without this the proxy cannot scan for devices.');
        paintRow(locRow,
          p === null ? null : p.location === true &&
            p.locationServicesOn !== false,
          'Bluetooth scanning can hear beacons.',
          p !== null && p.location === true
            ? 'Location is off in the device settings, so Bluetooth scanning finds nothing.'
            : 'Android only delivers Bluetooth scan results, beacons included, with Location granted. The app never reads the device position.');
      };
      readPerm().then(paint);
    }
  }

  // ── Bluetooth adapter state ──────────────────────────────────────────
  // Whatever state the proxy itself is in, the tab reflects the device's
  // actual adapter: off means a notice above the Bluetooth Proxy section
  // and everything from there down inert until it comes back; the ESPHome
  // general rows above stay live (the entity server does not need the
  // radio). Module-level timer for the same reason as the nearby poll; a
  // settings re-render clears the markers, so the poll repaints.
  {
    const root = document.getElementById('tab-esphome');
    const paint = (on) => {
      root.querySelectorAll('.bt-inert')
        .forEach((el) => el.classList.remove('bt-inert'));
      const existing = root.querySelector('.bt-off-banner');
      if (on !== false) { existing?.remove(); return; }
      // Everything on the Bluetooth Proxy page; the ESPHome rows on the page
      // above stay live (the entity server does not need the radio).
      const panel = root.querySelector('.subpage[data-subpage="Bluetooth Proxy"]');
      if (!panel) { existing?.remove(); return; }
      panel.querySelectorAll(':scope > *').forEach((el) => {
        if (!el.classList.contains('bt-off-banner')) el.classList.add('bt-inert');
      });
      if (existing) return;
      panel.prepend(banner(
        'Bluetooth is off. Turn it on to use the proxy.',
        { className: 'bt-off-banner' }));
    };
    // A dead server right where its switch is, mirroring the device
    // page: without this the tab renders identically whether the server
    // runs or not (issue #240).
    const paintError = (message) => {
      let row = root.querySelector('.esphome-start-error');
      if (!message) { row?.remove(); return; }
      const text = 'The ESPHome server failed to start: ' + message;
      if (row) { row.querySelector('span').textContent = text; return; }
      row = document.createElement('div');
      row.className = 'esphome-start-error';
      row.style.cssText = 'display:flex; gap:8px; align-items:flex-start; ' +
        'margin:0 0 14px; font-size:13px; color:var(--error); line-height:1.5';
      row.innerHTML = '<svg width="15" height="15" viewBox="0 0 24 24" ' +
        'fill="none" stroke="currentColor" stroke-width="2" ' +
        'stroke-linecap="round" stroke-linejoin="round" ' +
        'style="flex:none; margin-top:2px">' +
        '<path d="M10.3 3.9 1.9 18a2 2 0 0 0 1.7 3h16.8a2 2 0 0 0 ' +
        '1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/>' +
        '<path d="M12 9v4M12 17h.01"/></svg><span></span>';
      row.querySelector('span').textContent = text;
      const firstCard = root.querySelector('.card');
      if (firstCard) firstCard.insertAdjacentElement('afterend', row);
      else root.appendChild(row);
    };
    const pollError = () => api('/api/commands/esphomeStatus',
      { method: 'POST', body: '{}' }).then((r) => r.json())
      .then((res) => paintError(res.data?.startError || null))
      .catch(() => {});
    pollError();

    const poll = () => api('/api/commands/bluetoothAdapterOn',
      { method: 'POST', body: '{}' }).then((r) => r.json())
      .then((res) => {
        if (res && res.data && typeof res.data.on === 'boolean') {
          paint(res.data.on);
        }
      })
      .catch(() => {});
    const startAdapterPoll = () => {
      if (window.__btAdapterTimer) clearInterval(window.__btAdapterTimer);
      window.__btAdapterTimer = setInterval(() => { poll(); pollError(); }, 5000);
      poll();
    };
    // Scanning cannot work at all on this build (a Facebook Portal on
    // Android 9: no Bluetooth LE feature declared, so Android never starts
    // its GATT service): the master switch renders off and disabled with
    // the reason, mirroring the device page, and the adapter banner stays
    // away since no adapter state would change anything. The start-error
    // poll keeps running: the entity server is unaffected.
    api('/api/commands/getBleSupport', { method: 'POST', body: '{}' })
      .then((r) => r.json())
      .then((res) => {
        if (!(res && res.data && res.data.supported === false)) {
          startAdapterPoll();
          return;
        }
        const row = root.querySelector('[data-key="btproxy.enabled"]');
        const input = row?.querySelector('.switch input');
        if (input) { input.checked = false; input.disabled = true; }
        if (row && !root.querySelector('.ble-unsupported-note')) {
          const div = document.createElement('div');
          div.className = 'row ble-unsupported-note';
          div.style.cssText = 'font-size:12.5px; color:var(--muted);';
          div.textContent = res.data.hint || 'Not available on this device.';
          row.insertAdjacentElement('afterend', div);
        }
        if (window.__btAdapterTimer) clearInterval(window.__btAdapterTimer);
        window.__btAdapterTimer = setInterval(pollError, 5000);
      })
      .catch(startAdapterPoll);
  }

  // ── Lockdown Mode note ────────────────────────────────────────────────
  // The gesture and toggle rows carry their own descriptions; this only
  // states what the rows cannot: the side effects. Last on the tab, under
  // the permissions group.
  {
    const note = document.createElement('div');
    note.className = 'group-note';
    note.textContent =
      'Lockdown Mode makes the dashboard non-interactive, arms every ' +
      'Kiosk Mode protection without changing your Kiosk Mode settings, ' +
      'and mutes wake word detection while it is on. With the System UI ' +
      'guard enabled (above), the notification shade and recents are ' +
      'blocked too. Home Assistant gets a Lockdown mode switch over ' +
      'MQTT.';
    document.getElementById('tab-lockdown').appendChild(note);
  }
  // The master fader tops the Audio Volume card, mirroring the device: the
  // live device volume, not a setting, so it is hand-built over the
  // getVolume/setVolume commands.
  prependMasterVolumeRow();

  // ── Screen & Audio hand-built rows ────────────────────────────────────
  // The capture-tuning card and the audio device pickers, mirroring the
  // device page: Audio Devices between the volume mixer and the Microphone
  // settings group.
  {
    const root = document.getElementById('tab-screenaudio');
    // The capture rows are on a second-level page now, so the card is found
    // inside its panel and the group's place on this page is the entry row.
    const micCard = [...root.querySelectorAll('.card')]
      .find((c) => c.querySelector('[data-key="audio.mic_source"]'));
    const micEntry = root
      .querySelector('[data-subpage-entry="Microphone settings"]')
      ?.closest('.card');
    const wakeWordOn = byKey['wake_word.enabled']?.value !== false;
    if (micCard) {
      // The warning the device shows under the group's heading. Same words,
      // same place: between the heading and the card, not a row inside it.
      const note = document.createElement('div');
      note.style.cssText =
        'font-size:12.5px; color:var(--muted); margin:-6px 20px 10px';
      note.textContent = MIC_GROUP_NOTE;
      micCard.before(note);
      // AGC hides the gain slider, but the row is built either way and
      // simply kept out of view, so flipping the switch can reveal it in
      // place instead of reloading the whole tab (see save()).
      if (!micCard.querySelector('[data-key="audio.mic_gain_db"]')) {
        const gain = (state.settings || [])
          .find((o) => o.key === 'audio.mic_gain_db');
        if (gain) {
          const gainRow = settingRow(gain);
          gainRow.style.display = 'none';
          micCard.appendChild(gainRow);
        }
      }
      // The capture channel of a multichannel microphone, then the live
      // capture level under the gain it verifies - mirroring the device's
      // Microphone settings rows in that order. Only with detection on:
      // with it off the device never opens the microphone.
      if (wakeWordOn) await updateMicChannelRow();
      if (wakeWordOn) micCard.appendChild(micLevelRow());
    }
    // Microphone / speaker pickers, hand-built because their options are
    // live hardware. Their own card so the mixer card stays a mixer.
    const devCard = document.createElement('div');
    devCard.className = 'card';
    await appendAudioDeviceRows(devCard, wakeWordOn);
    if (devCard.children.length) {
      const devHeading = document.createElement('h2');
      devHeading.className = 'card-title';
      devHeading.textContent = 'Audio Devices';
      // Between the volume mixer and the row opening Microphone settings,
      // mirroring the device page.
      if (micEntry) micEntry.before(devHeading, devCard);
      else root.append(devHeading, devCard);
    }
  }
  updateBrightnessGrantNotices();
  updateAmbientDisplayNotice();
  // Awaited: the panels below read state.cameraPresent from it.
  await updateNoCameraNotice();
  await updateCameraFacingsRow();
  updateCameraGrantNotice();
  updateCameraSnapshotPanel();
  updateMotionCameraRows();
  updateFaceRows();
  updateDimModeNotice();
  updateScreenOffAdminNotice();
  updateAutoReloadOverlayNotice();
  updateImmichValidateRow();
  updateMqttValidateRow();
  updateMaValidateRow();
  updateMaPlayerRow();

  // Mirror of the device's Access card, under the Remote Administration
  // group on the Device tab. Here the address is simply where this page
  // came from.
  {
    const tab = document.getElementById('tab-device');
    const root = tab.querySelector('.subpage[data-subpage="Remote Administration"]')
      || document.getElementById('device-settings');
    const heading = document.createElement('h2');
    heading.className = 'card-title';
    heading.textContent = 'Access';
    const card = document.createElement('div');
    card.className = 'card';
    card.appendChild(readOnlyRow('Admin address',
      'Open this address in a browser on your computer.',
      `http://${location.host}`));
    root.append(heading, card);
  }

  // ── Kiosk Satellite Service page ──────────────────────────────────────
  // Mirror of the device's page: the service's live status and what it is
  // running for above its one setting, the grants it needs below.
  {
    const panel = document.querySelector(
      '#tab-device > .subpage[data-subpage="Kiosk Satellite Service"]');
    if (panel) renderServicePage(panel);
  }

  // ── Permissions (issue #156) ──────────────────────────────────────────
  // The device's Settings -> Device group, mirrored. Three states, not the
  // two the per-feature groups use: a flat granted/missing list paints half
  // the rows red on any setup that does not use every feature, so a grant
  // nothing currently needs stays muted and merely informative while still
  // being grantable ahead of time. Granting happens on the tablet either
  // way - Android has no way to accept on someone's behalf - so each button
  // opens the dialog there and the row polls until it lands.
  {
    // Last on the page: this answers "what does the app use, and where do I
    // stand", which is a footnote to the settings above rather than one of
    // them. Its own container, cleared here, because render() only clears
    // the settings one.
    const root = document.getElementById('device-permissions');
    root.innerHTML = '';
    const on = (k) => byKey[k]?.value === true;
    const background = on('wake_word.enabled') && on('wake_word.background');
    const ROWS = [
      { key: 'microphone', name: 'Microphone', ask: 'microphone',
        needed: on('wake_word.enabled'),
        held: 'Allows microphone usage for wake word detection and speech to text.',
        missing: 'Wake word detection is on and nothing is listening.',
        idle: 'Needed by wake word detection and by pages that ask for the microphone.' },
      // Always needed: the app holds the Home Assistant and MQTT
      // connections open while the screen is off, and Doze is what stops
      // them. Nothing has to be switched on for this one to matter.
      { key: 'batteryUnrestricted', name: 'Unrestricted battery', ask: 'batteryOptimizations',
        needed: true, requestable: 'batteryRequestable', adb: "This device has no settings screen for it. Grant it over adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite",
        held: 'Allows the process to run in the background without being paused or killed.',
        missing: 'Android may pause the app when the screen is off, dropping the Home Assistant connection and the MQTT entities with it.',
        idle: '' },
      { key: 'camera', name: 'Camera', ask: 'camera',
        needed: on('camera.enabled'),
        held: 'Motion detection and snapshots can use the camera.',
        missing: 'The camera is switched on and cannot be opened.',
        idle: 'Needed by motion detection, camera snapshots and pages that ask for the camera.' },
      { key: 'bluetooth', name: 'Nearby devices',
        ask: ['bluetoothScan', 'bluetoothConnect'],
        needed: on('btproxy.enabled'),
        held: 'The Bluetooth proxy can scan for nearby devices.',
        // A function of the full payload: name the actual blocker, the
        // pair, the location grant, or the system-wide location switch
        // (issues #240, #246; location gates Bluetooth scanning on every
        // Android version). Same wording as the ESPHome tab's card.
        missing: (all) => all.bluetoothPair === false
          ? 'The Bluetooth proxy is switched on and cannot scan.'
          : all.location === false
            ? 'Bluetooth scanning needs the Location permission.'
            : 'Location is off in the device settings, so Bluetooth scanning finds nothing.',
        idle: 'Needed by the Bluetooth proxy to scan for devices.' },
      { key: 'notification', name: 'Notifications', ask: 'notifications',
        // The service's notification is part of every install's deal.
        needed: true,
        held: "Allows the Kiosk Satellite Service's ongoing notification, which says what it is keeping alive.",
        missing: "Needed to show the Kiosk Satellite Service's ongoing notification.",
        idle: '' },
      { key: 'displayOverOtherApps', name: 'Display over other apps', ask: 'overlay',
        requestable: 'overlayRequestable', adb: "This device has no settings screen for it. Grant it over adb: adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow",
        needed: background || on('browser.auto_reload_on_error')
          || on('kiosk.start_on_boot') || on('kiosk.disable_status_bar'),
        held: 'Kiosk Satellite can bring itself back in the foreground.',
        missing: 'Without this the app cannot reopen itself after a crash, an update or a wake word heard behind another app.',
        idle: 'Lets the app bring itself back to the front, and the lockdown shield cover the whole screen.' },
      { key: 'writeSettings', name: 'Modify system settings', ask: 'writeSettings',
        needed: on('screen.set_brightness_on_launch') || on('screensaver.brightness_enabled'),
        held: "Brightness changes set the panel's real brightness.",
        missing: 'Brightness only dims the app window, so the panel and Home Assistant never see the change.',
        idle: "Needed to set the panel's real brightness rather than dimming the app window." },
      { key: 'uiGuard', name: 'System UI guard', guard: true,
        needed: on('kiosk.enabled') && on('kiosk.disable_status_bar'),
        held: 'The notification shade and recents close on their own while the screen is protected.',
        missing: 'The notification shade and recents stay reachable. Enable Kiosk Satellite under Accessibility.',
        idle: 'Closes the notification shade and recents while kiosk mode protects the screen.' },
      { key: 'deviceAdmin', name: 'Device admin', ask: 'deviceAdmin',
        needed: false,
        held: 'Allows the app to turn the screen off.',
        missing: '',
        idle: 'Lets Screen off power the panel down instead of only blacking it out.' },
      { key: 'allFiles', name: 'All files access', ask: 'allFiles',
        needed: false,
        held: 'The File Manager can browse the shared storage.',
        missing: '',
        idle: 'Lets the File Manager browse the shared storage instead of only the app folder.' },
      { key: 'usageAccess', name: 'Usage access', ask: 'usageAccess',
        needed: false,
        held: 'The Foreground app sensor can name whichever app is on screen.',
        missing: '',
        idle: 'Lets the Foreground app sensor name apps other than Kiosk Satellite.' },
      { key: 'location', name: 'Location', ask: 'location',
        needed: on('btproxy.enabled'),
        held: 'Pages and Bluetooth scanning can use the device location.',
        missing: 'Android will not deliver Bluetooth scan results without Location. The app never reads the device position.',
        idle: 'Used by pages that ask for your location, and needed by Bluetooth scanning.' },
    ];

    const readAll = async () => {
      const out = {};
      try {
        const res = await cmd('getSystemPermissions');
        Object.assign(out, res.data || {});
      } catch (_) {}
      try {
        const g = await cmd('hasUiGuard');
        out.uiGuard = g.data === true;
      } catch (_) {}
      return out;
    };

    const heading = document.createElement('h2');
    heading.className = 'card-title';
    heading.textContent = 'Permissions Manager';
    const card = document.createElement('div');
    card.className = 'card';
    root.append(heading, card);
    // The explanation reads as the group's first row rather than floating
    // text under the heading, matching the in-card notes elsewhere.
    const note = document.createElement('div');
    note.className = 'row';
    note.style.cssText = 'font-size:12.5px; color:var(--muted);';
    note.textContent =
      'Grants are given on the device, so each button opens an Android '
      + 'dialog or settings screen there. Some brands add their own battery '
      + 'or autostart manager on top, which Android cannot report.';
    card.appendChild(note);

    const rendered = ROWS.map((spec) => {
      const row = document.createElement('div');
      row.className = 'row';
      const info = document.createElement('div');
      info.className = 'info';
      info.innerHTML = '<div class="name"></div><div class="desc"></div>';
      info.querySelector('.name').textContent = spec.name;
      info.querySelector('.desc').textContent = 'Checking...';
      row.appendChild(info);
      const state = document.createElement('span');
      state.style.whiteSpace = 'nowrap';
      row.appendChild(state);
      card.appendChild(row);
      return { spec, row, info, state };
    });

    const paint = (all) => {
      for (const { spec, row, info, state } of rendered) {
        const ok = all[spec.key] === true;
        const unknownState = all[spec.key] === undefined;
        // A spec text may be a function of the full payload (the Bluetooth
        // row words its "missing" by what actually blocks it).
        const text = (t) => typeof t === 'function' ? t(all) : t;
        // The device has no screen for the grant: the adb command stands
        // in for the button, and the row is not an error nobody can fix.
        const noScreen = !ok && spec.requestable && all[spec.requestable] === false;
        info.querySelector('.desc').textContent = unknownState
          ? 'Status unavailable.'
          : noScreen ? spec.adb
          : text(ok ? spec.held : (spec.needed ? spec.missing : spec.idle));
        state.textContent = unknownState ? ''
          : ok ? 'Granted' : noScreen ? 'Not offered'
          : (spec.needed ? 'Missing' : 'Not granted');
        state.style.color = ok ? 'var(--ok)'
          : spec.needed && !noScreen ? 'var(--error)' : 'var(--muted)';
        row.querySelector('button')?.remove();
        if (ok || unknownState || noScreen) continue;
        const btn = document.createElement('button');
        btn.className = 'btn-ghost';
        btn.textContent = spec.guard ? 'Open settings on device' : 'Grant on device';
        btn.style.cssText = 'flex-shrink:0;';
        btn.addEventListener('click', async () => {
          btn.disabled = true;
          try {
            if (spec.guard) {
              await api('/api/commands/openUiGuardSettings',
                { method: 'POST', body: '{}' });
            } else {
              // ask is one name or a list (the Bluetooth pair shares a row).
              await api('/api/commands/requestOsPermissions', { method: 'POST',
                body: JSON.stringify({ which: [].concat(spec.ask) }) });
            }
          } catch (_) {}
          // The grant happens on the tablet; keep re-reading until it lands
          // so the row flips by itself.
          let tries = 30;
          const tick = setInterval(async () => {
            const now = await readAll();
            if (now[spec.key] === true || --tries <= 0) {
              clearInterval(tick);
              paint(now);
            }
          }, 2000);
        });
        row.appendChild(btn);
      }
    };
    readAll().then(paint);
  }

  // ── Voice Satellite ───────────────────────────────────────────────────
  // Its own page under Home Assistant Configuration, gated the same way;
  // loadVsPermissions() appends the permissions card.
  {
    const root = document.getElementById('tab-voicesatellite');
    root.innerHTML = '';
    let status = {};
    try {
      status = (await (await api('/api/commands/haStatus', { method: 'POST', body: '{}' })).json()).data || {};
    } catch (_) {}
    if (!status.connected) {
      const card = document.createElement('div');
      card.className = 'card';
      card.appendChild(readOnlyRow('Home Assistant not connected',
        'Validate the connection under Home Assistant Configuration first.', ''));
      root.appendChild(card);
    } else if (!(byCat['Voice Satellite'] || []).length || !(await (async () => {
      try {
        const vs = await (await api('/api/commands/haDetectVoiceSatellite', { method: 'POST', body: '{}' })).json();
        return vs.ok && vs.data === true;
      } catch (_) { return false; }
    })())) {
      // Not installed: say what Voice Satellite is and hand over the HACS
      // button (default repository), mirroring the device page.
      const card = document.createElement('div');
      card.className = 'card';
      card.appendChild(readOnlyRow('Voice Satellite is not installed in Home Assistant',
        'Voice Satellite turns this kiosk into a full hands-free voice assistant for Home Assistant: wake word detection, conversations, timers and announcements, right on the dashboard. It is available in the default HACS repository. Install it on your Home Assistant instance, then come back here.', ''));
      const wrap = document.createElement('div');
      wrap.style.cssText = 'padding:16px; text-align:center';
      const a = document.createElement('a');
      a.href = ((byKey['ha.url']?.value || '').trim().replace(/\/$/, '')) + '/hacs/repository/1159616380';
      a.target = '_blank';
      a.rel = 'noreferrer';
      const img = document.createElement('img');
      img.src = 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIGhlaWdodD0iNDAiIGFyaWEtbGFiZWw9Ik9wZW4gSEFDUyByZXBvc2l0b3J5IG9uIE15IEhvbWUgQXNzaXN0YW50IiBzdHlsZT0iYm9yZGVyLXJhZGl1czoyNHB4O3dpZHRoOmF1dG8iIHZpZXdCb3g9IjAgMCA2OTcgOTYiPjx0aXRsZT5PcGVuIEhBQ1MgcmVwb3NpdG9yeSBvbiBNeSBIb21lIEFzc2lzdGFudDwvdGl0bGU+PHJlY3Qgd2lkdGg9IjY5NyIgaGVpZ2h0PSI5NiIgZmlsbD0iIzE4YmNmMiIgcng9IjQ4Ii8+PHBhdGggZmlsbD0iI2ZmZiIgZD0iTTUzLjI3IDYwLjZjNi45NiAwIDExLjkyLTUuMDIgMTEuOTItMTIuMDkgMC03LjEtNC45Ni0xMi4xMy0xMi4wMi0xMi4xMy03LjA0IDAtMTIgNC45OS0xMiAxMi4xMyAwIDcuMDcgNC45OSAxMi4wOSAxMi4xIDEyLjA5bTAtNC4xOWMtNC4zNiAwLTcuNDEtMy4yOC03LjQxLTcuOSAwLTQuNjYgMy4wMi03Ljk0IDcuMzEtNy45NCA0LjMyIDAgNy4zMyAzLjI4IDcuMzMgNy45NCAwIDQuNjItMi45OCA3LjktNy4yMyA3LjltMTYuMzEgMy43OWg0LjU5di03Ljc3aDQuNDljNC43MiAwIDguMDctMy4yOSA4LjA3LTcuODcgMC00LjU5LTMuNDgtNy44OC04LjQ0LTcuODRsLTQuNjYuMDNoLTQuMDVabTguNjEtMTkuMjZjMi4yOC0uMDQgMy44OSAxLjQ3IDMuODkgMy42MiAwIDIuMTQtMS40OCAzLjY1LTMuNTIgMy42NWgtNC4zOXYtNy4yN1pNOTAuNDUgNjAuMmgxNC45OHYtNC4xOUg5NS4wNHYtNS42Nmg4Ljg0di00LjA5aC04Ljg0di01LjMyaDEwLjI1di00LjE5SDkwLjQ1Wm0yMC40IDAgNC41OS4wM1Y0NC4xMkwxMjcuMSA2MC4yaDQuNTZWMzYuNzVoLTQuNTZ2MTUuODFsLTExLjQ2LTE1LjgxaC00Ljc5Wm0zNS4yMSAwIDQuNTkuMDN2LTkuOTFoMTAuODV2OS44OGg0LjU5VjM2Ljc1aC00LjU5djkuMzVoLTEwLjg1di05LjM1bC00LjU5LS4wM1ptMjMuNTIgMGg0Ljg2bDEuOTctNS4xNmg5LjcybDEuOTcgNS4xNmg0Ljg2bC05LjI0LTIzLjQ1aC00LjlabTguMzctOS4yMSAzLjMyLTguNjUgMy4zMiA4LjY1Wm0yNy45OCA5LjYxYzQuODUgMCA4Ljg3LTIuODEgMTAuNTUtNi45M2wtNC4yNi0xLjU0Yy0xLjE3IDIuNTQtMy4zNSA0LjMyLTYuMjMgNC4zMi00LjE1IDAtNy4xLTMuMjktNy4xLTcuOTggMC00LjY1IDIuOTItNy45MyA3LTcuOTMgMi43OCAwIDUuMDkgMS42NCA2LjI3IDQuMTJsNC4yNS0xLjU4Yy0xLjcxLTMuOTktNS42OS02LjczLTEwLjUyLTYuNzMtNi44NyAwLTExLjY5IDUuMDItMTEuNjkgMTIuMTIgMCA3LjExIDQuODYgMTIuMTMgMTEuNzMgMTIuMTNtMjIuNDcgMGM1LjQ2IDAgOC41NS0yLjc1IDguNTUtNi45MyAwLTMuMTItMi4zMi01LjktNi4zNy02LjlMMjI3LjUgNDZjLTEuNzQtLjQ0LTIuODEtMS4yNC0yLjgxLTIuNzIgMC0xLjg0IDEuMzQtMi45NSAzLjU4LTIuOTUgMi4xOCAwIDMuNjUgMS4yNCA0LjE5IDIuNzVsNC40NS0xLjM3Yy0xLjI0LTMuMjktNC4wMi01LjM2LTguNTEtNS4zNi01LjM2IDAtOC40IDIuNjEtOC40IDcuMDMgMCAzLjQ5IDIuMzQgNS43IDUuNzkgNi41N2wzLjA1LjhjMi4wOC41MSAzLjMyIDEuNTQgMy4zMiAzLjAyIDAgMS43MS0xLjY1IDIuODgtNC4wMiAyLjg1LTIuMjUtLjA0LTMuNzYtMS4yOC00LjMzLTIuODJsLTQuNDggMS4zNGMuNjcgMi44OCA0LjMyIDUuNDYgOS4wNyA1LjQ2bTIxLjc4LS40aDQuNTl2LTguMzFoMy41Mmw0Ljc5IDguMzFoNS4xOWwtNS40My05LjExYzIuNzItMS4yMSA0LjQ5LTMuNjkgNC40OS02Ljc3IDAtNC40NS0zLjQ4LTcuNjQtOC40NC03LjZsLTQuNjYuMDNoLTQuMDVabTguNTEtMTkuMjZjMi4yOCAwIDMuODggMS4zNyAzLjg4IDMuMzggMCAxLjk4LTEuNiAzLjM4LTMuNjUgMy4zOGgtNC4xNXYtNi43NlptMTMuNzcgMTkuMjZoMTQuOTd2LTQuMTloLTEwLjM4di01LjY2aDguODR2LTQuMDloLTguODR2LTUuMzJoMTAuMjV2LTQuMTloLTE0Ljg0Wm0yMC40IDBoNC41OXYtNy43N2g0LjQ5YzQuNzIgMCA4LjA3LTMuMjkgOC4wNy03Ljg3IDAtNC41OS0zLjQ4LTcuODgtOC40NC03Ljg0bC00LjY2LjAzaC00LjA1Wm04LjYxLTE5LjI2YzIuMjgtLjA0IDMuODggMS40NyAzLjg4IDMuNjIgMCAyLjE0LTEuNDcgMy42NS0zLjUxIDMuNjVoLTQuMzl2LTcuMjdabTIyLjk4IDE5LjY2YzYuOTcgMCAxMS45Mi01LjAyIDExLjkyLTEyLjA5IDAtNy4xLTQuOTUtMTIuMTMtMTIuMDItMTIuMTMtNy4wNCAwLTEyIDQuOTktMTIgMTIuMTMgMCA3LjA3IDUgMTIuMDkgMTIuMSAxMi4wOW0wLTQuMTljLTQuMzYgMC03LjQxLTMuMjgtNy40MS03LjkgMC00LjY2IDMuMDItNy45NCA3LjMxLTcuOTQgNC4zMiAwIDcuMzMgMy4yOCA3LjMzIDcuOTQgMCA0LjYyLTIuOTggNy45LTcuMjMgNy45bTI0LjE5IDQuMTljNS40NiAwIDguNTQtMi43NSA4LjU0LTYuOTMgMC0zLjEyLTIuMzEtNS45LTYuMzctNi45bC0zLjA4LS43N2MtMS43NC0uNDQtMi44MS0xLjI0LTIuODEtMi43MiAwLTEuODQgMS4zNC0yLjk1IDMuNTgtMi45NSAyLjE4IDAgMy42NSAxLjI0IDQuMTkgMi43NWw0LjQ1LTEuMzdjLTEuMjQtMy4yOS00LjAyLTUuMzYtOC41LTUuMzYtNS4zNiAwLTguNDEgMi42MS04LjQxIDcuMDMgMCAzLjQ5IDIuMzQgNS43IDUuNzkgNi41N2wzLjA1LjhjMi4wOC41MSAzLjMyIDEuNTQgMy4zMiAzLjAyIDAgMS43MS0xLjY0IDIuODgtNC4wMiAyLjg1LTIuMjUtLjA0LTMuNzUtMS4yOC00LjMyLTIuODJsLTQuNDkgMS4zNGMuNjcgMi44OCA0LjMyIDUuNDYgOS4wOCA1LjQ2bTEzLjEzLS40aDQuNTlWMzYuNzVoLTQuNTlabTE1LjMxIDBoNC41OVY0MC45NGg3di00LjE5aC0xOC42M3Y0LjE5aDcuMDRabTI1Ljk5LjRjNi45NyAwIDExLjkzLTUuMDIgMTEuOTMtMTIuMDkgMC03LjEtNC45Ni0xMi4xMy0xMi4wMy0xMi4xMy03LjAzIDAtMTEuOTkgNC45OS0xMS45OSAxMi4xMyAwIDcuMDcgNC45OSAxMi4wOSAxMi4wOSAxMi4wOW0wLTQuMTljLTQuMzUgMC03LjQtMy4yOC03LjQtNy45IDAtNC42NiAzLjAxLTcuOTQgNy4zLTcuOTQgNC4zMiAwIDcuMzQgMy4yOCA3LjM0IDcuOTQgMCA0LjYyLTIuOTggNy45LTcuMjQgNy45bTE2LjMyIDMuNzloNC41OXYtOC4zMWgzLjUxbDQuOCA4LjMxaDUuMTlsLTUuNDMtOS4xMWMyLjcxLTEuMjEgNC40OS0zLjY5IDQuNDktNi43NyAwLTQuNDUtMy40OC03LjY0LTguNDQtNy42bC00LjY2LjAzaC00LjA1Wm04LjUxLTE5LjI2YzIuMjcgMCAzLjg4IDEuMzcgMy44OCAzLjM4IDAgMS45OC0xLjYxIDMuMzgtMy42NSAzLjM4aC00LjE1di02Ljc2Wm0xOS43NiAxOS4yNmg0LjU5di05LjkybDguMzEtMTMuNTNoLTUuMjNsLTUuMzkgOS4wMS01LjM2LTkuMDFoLTUuMjNsOC4zMSAxMy41N1ptMzUuNzEuNGM2Ljk3IDAgMTEuOTMtNS4wMiAxMS45My0xMi4wOSAwLTcuMS00Ljk2LTEyLjEzLTEyLjAzLTEyLjEzLTcuMDMgMC0xMS45OSA0Ljk5LTExLjk5IDEyLjEzIDAgNy4wNyA0Ljk5IDEyLjA5IDEyLjA5IDEyLjA5bTAtNC4xOWMtNC4zNSAwLTcuNC0zLjI4LTcuNC03LjkgMC00LjY2IDMuMDEtNy45NCA3LjMtNy45NCA0LjMyIDAgNy4zNCAzLjI4IDcuMzQgNy45NCAwIDQuNjItMi45OCA3LjktNy4yNCA3LjltMTYuMzIgMy43OSA0LjU5LjAzVjQ0LjEybDExLjY1IDE2LjA4aDQuNTZWMzYuNzVoLTQuNTZ2MTUuODFsLTExLjQ1LTE1LjgxaC00Ljc5WiIvPjxnIHN0eWxlPSJ0cmFuc2Zvcm06dHJhbnNsYXRlKDIwMHB4LDApIj48cmVjdCB3aWR0aD0iMTM3IiBoZWlnaHQ9IjY0IiB4PSIzNDQiIHk9IjE2IiBmaWxsPSIjZjJmNGY5IiByeD0iMzIiLz48cGF0aCBmaWxsPSIjMThiY2YyIiBkPSJNMzk0LjQxOSAzNy4wNDdWNjAuNWgtNC4yOTdWNDYuNzk3TDM4NC43MTYgNjAuNWgtNC4xNTdsLTUuMzQzLTEzLjU5NFY2MC41aC00LjE4OFYzNy4wNDdoNC4xODhsNy40MjIgMTguMzYgNy40ODQtMTguMzZ6bTkuMzY1IDAgNS4zNDQgOS44OSA1LjM0NC05Ljg5aDQuNzY2bC03Ljk2OSAxNC4xNFY2MC41aC00LjM5MXYtOS4zMTJsLTguMDMxLTE0LjE0MXpNNDU3IDYwYzAgMS42NS0xLjM1IDMtMyAzaC0yNGMtMS42NSAwLTMtMS4zNS0zLTN2LTljMC0xLjY1Ljk1LTMuOTUgMi4xMi01LjEybDEwLjc2LTEwLjc2YTMgMyAwIDAgMSA0LjI0IDBsMTAuNzYgMTAuNzZjMS4xNyAxLjE3IDIuMTIgMy40NyAyLjEyIDUuMTJ6Ii8+PHBhdGggZmlsbD0iI2YyZjRmOSIgc3Ryb2tlPSIjZjJmNGY5IiBkPSJNNDQyIDQ1LjVhMiAyIDAgMSAwIDAtNCAyIDIgMCAwIDAgMCA0WiIvPjxwYXRoIGZpbGw9IiNmMmY0ZjkiIHN0cm9rZT0iI2YyZjRmOSIgc3Ryb2tlLW1pdGVybGltaXQ9IjEwIiBkPSJNNDQ5LjUgNTMuNWEyIDIgMCAxIDAgMC00IDIgMiAwIDAgMCAwIDRaTTQzNC41IDU3LjVhMiAyIDAgMSAwIDAtNCAyIDIgMCAwIDAgMCA0WiIvPjxwYXRoIGZpbGw9Im5vbmUiIHN0cm9rZT0iI2YyZjRmOSIgc3Ryb2tlLW1pdGVybGltaXQ9IjEwIiBzdHJva2Utd2lkdGg9IjIuMjUiIGQ9Ik00NDIgNDMuNDhWNjNsLTcuNS03LjVNNDQ5LjUgNTEuNDZsLTcuNDEgNy40MSIvPjwvZz48L3N2Zz4=';
      img.height = 40;
      img.alt = 'Open HACS repository';
      a.appendChild(img);
      wrap.appendChild(a);
      card.appendChild(wrap);
      const learn = document.createElement('div');
      learn.style.cssText = 'padding:16px; font-size:13.5px; color:var(--muted); text-align:center';
      learn.innerHTML = 'Learn more about ' +
        '<svg viewBox="0 0 24 24" style="width:15px;height:15px;vertical-align:-2px;margin-right:4px;fill:var(--primary)">' +
        '<path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0 0 24 12c0-6.63-5.37-12-12-12z"/></svg>' +
        '<a href="https://github.com/jxlarrea/voice-satellite-card-integration" target="_blank" rel="noreferrer" style="color:var(--primary)">Voice Satellite on Github</a>';
      card.appendChild(learn);
      root.appendChild(card);
    } else {
      // render() clears the container, so it goes first: it leaves the
      // General card's place empty, an entry row for each second-level page,
      // and the panels behind them. Appearance is listed by hand because no
      // setting declares it — its rows are all live entity controls, which
      // renderVsControls then puts into both panels.
      render(root, ['Voice Satellite'].filter((c) => (byCat[c] || []).length),
        { extra: ['Appearance'] });
      await renderVsControls(root);
    }
  }

  // ── Home Assistant Configuration ──────────────────────────────────────
  // The connection card is the gate: base URL, token, a Validate row.
  // Everything else (the dashboard picker, kiosk mode, theme, Voice
  // Satellite) appears only after this run's connection check passed,
  // mirroring the device's settings page exactly.
  {
    const root = document.getElementById('tab-homeassistant');
    root.innerHTML = '';
    const ha = byCat['Home Assistant'] || [];
    const connCard = document.createElement('div');
    connCard.className = 'card';
    ha.filter((s) => s.key === 'ha.url' || s.key === 'ha.token')
      .forEach((s) => connCard.appendChild(settingRow(s)));
    const vrow = readOnlyRow('Validate connection', '', '');
    vrow.querySelector('span').remove();
    const vbtn = document.createElement('button');
    vbtn.className = 'btn-ghost';
    vbtn.textContent = 'Validate';
    vrow.appendChild(vbtn);
    connCard.appendChild(vrow);
    // Secure context proxy, below Validate — hand-built here exactly like
    // the device's connection card: the switch derives its enabled state
    // from the URL scheme (https needs no proxy, so it sits disabled and
    // off; plain http enables it, validation turns it on with a modal).
    const spSetting = settings.find((s) => s.key === 'browser.secure_proxy');
    {
      const urlVal = (ha.find((s) => s.key === 'ha.url')?.value || '').trim();
      const spu = (() => { try { return new URL(urlVal); } catch (_) { return null; } })();
      const spHttp = spu && spu.protocol === 'http:'
        && spu.hostname !== 'localhost' && spu.hostname !== '127.0.0.1';
      const spRow = document.createElement('div');
      spRow.className = 'row';
      const spInfo = document.createElement('div');
      spInfo.className = 'info';
      spInfo.innerHTML = '<div class="name"></div><div class="desc"></div>';
      spInfo.querySelector('.name').textContent = 'Secure context proxy';
      spInfo.querySelector('.desc').textContent =
        'Routes a plain http Home Assistant through a proxy inside the app '
        + 'so the browser unlocks the microphone and other https-only '
        + 'features. Available only for http URLs.';
      spRow.appendChild(spInfo);
      const spLbl = document.createElement('label');
      spLbl.className = 'switch';
      const spCb = document.createElement('input');
      spCb.type = 'checkbox';
      spCb.checked = spSetting?.value === true;
      spCb.disabled = !spHttp;
      if (!spHttp) spLbl.style.opacity = '.45';
      spCb.addEventListener('change', () => api('/api/settings', {
        method: 'PATCH',
        body: JSON.stringify({ 'browser.secure_proxy': spCb.checked }),
      }));
      const spSl = document.createElement('span');
      spSl.className = 'slider';
      spLbl.append(spCb, spSl);
      spRow.appendChild(spLbl);
      connCard.appendChild(spRow);
    }
    // Auto-login, with the connection it borrows the token from - the
    // same placement as the device's connection card.
    const alSetting = ha.find((s) => s.key === 'ha.auto_login');
    if (alSetting) connCard.appendChild(settingRow(alSetting));
    root.appendChild(connCard);
    const vdesc = vrow.querySelector('.desc');

    let status = {};
    try {
      status = (await (await api('/api/commands/haStatus', { method: 'POST', body: '{}' })).json()).data || {};
    } catch (_) {}
    state.haConnected = !!status.connected;
    vbtn.addEventListener('click', async () => {
      // A plain-http URL means the browser withholds the microphone and the
      // rest of the https-only surface from the dashboard. Tell the user the
      // secure context proxy is being turned on and why, then enable it.
      const urlSetting = ha.find((s) => s.key === 'ha.url');
      const proxySetting = settings.find((s) => s.key === 'browser.secure_proxy');
      const u = (() => {
        try { return new URL(urlSetting?.value || ''); } catch (_) { return null; }
      })();
      if (u && u.protocol === 'http:'
        && u.hostname !== 'localhost' && u.hostname !== '127.0.0.1'
        && proxySetting && proxySetting.value !== true) {
        await messageBox({
          title: 'Secure context proxy',
          message: 'This Home Assistant URL uses plain http, and browsers '
            + 'block the microphone and other features on http pages. Kiosk '
            + 'Satellite will route the dashboard through a secure proxy '
            + 'inside the app so everything works. You may need to sign in '
            + 'to Home Assistant again on the tablet.',
          buttons: ['OK'],
        });
        await api('/api/settings', { method: 'PATCH',
          body: JSON.stringify({ 'browser.secure_proxy': true }) });
      }
      vbtn.disabled = true; vbtn.textContent = 'Checking\u2026';
      const out = await (await api('/api/commands/haCheckConnection', { method: 'POST', body: '{}' })).json().catch(() => ({}));
      vbtn.disabled = false; vbtn.textContent = 'Validate';
      if (out.ok) { state.dashboardsCache = null; await loadSettings(); await loadVsPermissions(); loadViewJump(); }
      else vdesc.textContent = out.error || 'Could not connect.';
    });

    if (!state.haConnected) {
      vdesc.textContent = 'Not validated yet. The settings below unlock once the connection checks out.';
    } else {
      vdesc.textContent = 'Connected.';
      // Dashboard picker: what the kiosk shows. Radio rows; picking one sets
      // the start URL and navigates the device right away. The kiosk lands on
      // a single view, so the selected dashboard's row shows its chosen view
      // (defaulting to the first) with a "Change view" button; listing every
      // sub-view of every dashboard would be an unusable wall, so a
      // dashboard's views are only fetched when it is picked or changed.
      const h = document.createElement('h2');
      h.className = 'card-title';
      h.textContent = 'Dashboard';
      root.appendChild(h);
      const dcard = document.createElement('div');
      dcard.className = 'card';
      root.appendChild(dcard);
      let dashList = [];
      try {
        // Cached across re-renders: a dependant toggle elsewhere on the tab
        // triggers loadSettings(), and re-fetching the dashboard list from
        // Home Assistant every time blanked the pane for seconds - the
        // "whole page refreshed" feel. Validate clears the cache.
        if (!state.dashboardsCache) {
          state.dashboardsCache = (await (await api('/api/commands/haListDashboards', { method: 'POST', body: '{}' })).json()).data || [];
        }
        const dashboards = state.dashboardsCache;
        dashList = dashboards;
        const rawBase = (byKey['ha.url']?.value || '').trim().replace(/\/$/, '');
        const current = byKey['browser.start_url']?.value || '';
        // Which dashboard + view route the stored start URL points at.
        let selDash = null, selRoute = '';
        for (const d of dashboards) {
          const url = `${rawBase}/${d.url_path}`;
          if (current === url) { selDash = d.url_path; selRoute = ''; }
          else if (current.startsWith(url + '/')) {
            selDash = d.url_path; selRoute = current.slice(url.length + 1);
          }
        }
        const applyStart = async (url) => {
          await api('/api/settings', { method: 'PATCH',
            body: JSON.stringify({ 'browser.start_url': url }) });
          await api('/api/commands/loadUrl', { method: 'POST',
            body: JSON.stringify({ url }) });
          await loadSettings();
        };
        for (const d of dashboards) {
          const selected = selDash === d.url_path;
          const sub = selected ? viewPath(d.url_path, selRoute) : d.url_path;
          const row = radioRow(d.title || d.url_path, sub, selected, async () => {
            if (selected) return;
            // Land on the dashboard's first view.
            const views = await fetchViews(d.url_path);
            const route = (views && views.length) ? String(views[0].route) : '';
            await applyStart(route ? `${rawBase}/${d.url_path}/${route}` : `${rawBase}/${d.url_path}`);
          });
          if (selected) {
            // "Change view": pick another of this dashboard's views.
            const btn = document.createElement('button');
            btn.className = 'btn-ghost';
            btn.textContent = 'Change view';
            btn.style.cssText = 'margin-left:8px; flex-shrink:0;';
            btn.addEventListener('click', async (e) => {
              e.stopPropagation();
              const views = await fetchViews(d.url_path);
              if (!views || !views.length) {
                messageBox({ title: 'No sub views', message: 'This dashboard has no selectable sub views.' });
                return;
              }
              const route = await pickView(d.url_path, views, selRoute);
              if (route == null) return;
              await applyStart(route ? `${rawBase}/${d.url_path}/${route}` : `${rawBase}/${d.url_path}`);
            });
            row.insertBefore(btn, row.querySelector('input'));
          }
          dcard.appendChild(row);
        }
        if (!dashboards.length) dcard.appendChild(readOnlyRow('No dashboards found', '', ''));
      } catch (_) {
        dcard.appendChild(readOnlyRow('Could not list dashboards', '', ''));
      }
      // The rest of the Home Assistant settings, through the same
      // section-aware renderer as every other tab. Almost all of them
      // declare a `subpage`, so what lands here is the row that opens each
      // second-level page; the groups named below keep their hand-built
      // cards (a live dashboard list, a cross-group disabled state,
      // telemetry under a toggle) and those go into their own panel.
      const HAND_BUILT_PAGES = ['Theme', 'Dashboard View Rotation',
        'Return to home dashboard view', 'Hold mode', 'Optimizations'];
      const rest = ha.filter((s) => s.key !== 'ha.url' && s.key !== 'ha.token'
        && s.key !== 'ha.auto_login');
      const restRoot = document.createElement('div');
      root.appendChild(restRoot);
      const savedHa = byCat['Home Assistant'];
      byCat['Home Assistant'] = rest;
      const haPanels = render(
        restRoot,
        ['Home Assistant'].filter((c) => (byCat[c] || []).length),
        { handBuilt: HAND_BUILT_PAGES });
      byCat['Home Assistant'] = savedHa;
      // Each hand-built group goes on the page its entry row opens. No
      // heading with it: the page title already carries the name.
      const panelFor = (sub) => haPanels.get(sub) || root;

      // Theme, hand-built: the toggles re-render only this card, showing
      // or hiding their dependent rows in place.
      {
        const thAuto = byKey['ha.theme_auto'];
        const thMatch = byKey['ha.theme_match_app'];
        if (thAuto) {
          const tcard = document.createElement('div');
          tcard.className = 'card';
          panelFor('Theme').appendChild(tcard);
          const renderThemeCard = () => {
            tcard.innerHTML = '';
            const themeToggle = (s) => toggleRow(s.title, s.description,
              s.value === true, async (on) => {
                s.value = on;
                await api('/api/settings', { method: 'PATCH',
                  body: JSON.stringify({ [s.key]: on }) });
                renderThemeCard();
              });
            // The mirror first, matching the device: with it on, the
            // schedule targets the app theme and "Also switch the app
            // theme" is redundant, so that row hides (issue #92).
            if (thMatch) tcard.appendChild(themeToggle(thMatch));
            tcard.appendChild(themeToggle(thAuto));
            if (thAuto.value === true) {
              for (const k of ['ha.theme_dark_at', 'ha.theme_light_at']) {
                if (byKey[k]) tcard.appendChild(settingRow(byKey[k]));
              }
              if (thMatch?.value !== true && byKey['ha.theme_auto_app']) {
                tcard.appendChild(settingRow(byKey['ha.theme_auto_app']));
              }
            }
          };
          renderThemeCard();
        }
      }

      // Return-home card renderer, assigned further below; the rotation
      // toggle re-renders it in place (its disabled state gates on
      // rotation).
      let renderReturnCard = () => {};

      // Dashboard view rotation: toggle, then each dashboard as a plain
      // header with a checkbox per view beneath it, and the dwell time,
      // mirroring the device's card. Selection entries are navigation
      // paths ("url_path/view-route").
      const rotEnabled = byKey['ha.rotation_enabled'];
      if (rotEnabled) {
        const rcard = document.createElement('div');
        rcard.className = 'card';
        panelFor('Dashboard View Rotation').appendChild(rcard);
        // The card re-renders itself in place on toggle, like the Theme
        // and Return-home cards: the shared settingRow save would reload
        // the whole tab.
        const renderRotationCard = async () => {
        rcard.innerHTML = '';
        rcard.appendChild(toggleRow(rotEnabled.title, rotEnabled.description,
          rotEnabled.value === true, async (on) => {
            rotEnabled.value = on;
            // The device forces the return-home switch off the moment
            // rotation turns on (mutually exclusive); mirror it locally so
            // the card below re-renders right.
            if (on && byKey['ha.return_home_enabled']) {
              byKey['ha.return_home_enabled'].value = false;
            }
            await api('/api/settings', { method: 'PATCH',
              body: JSON.stringify({ 'ha.rotation_enabled': on }) });
            await renderRotationCard();
            renderReturnCard();
          }));
        if (rotEnabled.value === true) {
          // Seconds saved in place: the shared settingRow re-renders the
          // whole tab (and re-fetches every dashboard) on save, which reads
          // as a jarring reload here. A plain PATCH is enough.
          {
            const secRow = readOnlyRow('Seconds per view', '', '');
            secRow.querySelector('span').remove();
            const secInp = document.createElement('input');
            secInp.type = 'number';
            secInp.min = '5';
            secInp.value = byKey['ha.rotation_seconds']?.value ?? 30;
            secInp.style.cssText = 'width:90px; background:var(--surface-2);'
              + 'border:1px solid var(--border); border-radius:var(--radius-sm);'
              + 'color:var(--text); padding:9px 12px';
            secInp.addEventListener('change', () => {
              const v = Math.max(5, Number(secInp.value) || 30);
              secInp.value = v;
              api('/api/settings', { method: 'PATCH',
                body: JSON.stringify({ 'ha.rotation_seconds': v }) });
            });
            secRow.appendChild(secInp);
            rcard.appendChild(secRow);
          }
          // Pause-on-interaction, same in-place save.
          {
            const pRow = readOnlyRow('Pause rotation on interaction (seconds)',
              'Touch pauses rotation for this long; each touch restarts it. '
              + 'Voice interactions always pause until they end. 0 keeps rotating.',
              '');
            pRow.querySelector('span').remove();
            const pInp = document.createElement('input');
            pInp.type = 'number';
            pInp.min = '0';
            pInp.value = byKey['ha.rotation_pause_seconds']?.value ?? 30;
            pInp.style.cssText = 'width:90px; background:var(--surface-2);'
              + 'border:1px solid var(--border); border-radius:var(--radius-sm);'
              + 'color:var(--text); padding:9px 12px';
            pInp.addEventListener('change', () => {
              const v = Math.max(0, Number(pInp.value) || 0);
              pInp.value = v;
              api('/api/settings', { method: 'PATCH',
                body: JSON.stringify({ 'ha.rotation_pause_seconds': v }) });
            });
            pRow.appendChild(pInp);
            rcard.appendChild(pRow);
          }
          // Crossfade toggle, saved in place like the numbers above.
          const rotFade = byKey['ha.rotation_crossfade'];
          if (rotFade) {
            rcard.appendChild(toggleRow(rotFade.title, rotFade.description,
              rotFade.value === true, async (on) => {
                rotFade.value = on;
                await api('/api/settings', { method: 'PATCH',
                  body: JSON.stringify({ 'ha.rotation_crossfade': on }) });
              }));
          }
          let sel = [];
          try { sel = JSON.parse(byKey['ha.rotation_dashboards']?.value || '[]'); } catch (_) {}
          if (!Array.isArray(sel)) sel = [];
          const viewLists = await Promise.all(dashList.map(async (d) => {
            try {
              const r = await (await api('/api/commands/haListDashboardViews', {
                method: 'POST', body: JSON.stringify({ url_path: d.url_path }) })).json();
              if (r.ok && Array.isArray(r.data) && r.data.length) return r.data;
            } catch (_) {}
            // Auto-generated dashboards store no view list; the whole
            // dashboard still rotates via its first view.
            // Unreadable (strategy) dashboards rotate via their bare path:
            // an empty route navigated as /<url_path>, which resolves the
            // default view. A synthetic /0 would spin.
            return [{ title: 'Default view', route: '' }];
          }));
          dashList.forEach((d, i) => {
            const hdr = document.createElement('div');
            hdr.style.cssText = 'padding:12px 0 2px; font-size:13px; font-weight:600;'
              + 'color:var(--primary)';
            hdr.textContent = d.title || d.url_path;
            rcard.appendChild(hdr);
            viewLists[i].forEach((v) => {
              const path = v.route ? `${d.url_path}/${v.route}` : d.url_path;
              // A real checkbox (accent-colored by the global input rule),
              // saved in place: no full re-render, the page stays put.
              const row = readOnlyRow(v.title || v.route, path, '');
              row.querySelector('span').remove();
              row.style.paddingLeft = '14px';
              const cb = document.createElement('input');
              cb.type = 'checkbox';
              cb.checked = sel.includes(path);
              cb.style.cssText = 'width:19px; height:19px; flex:none; cursor:pointer';
              cb.addEventListener('change', async () => {
                sel = cb.checked ? sel.concat(path) : sel.filter((p) => p !== path);
                await api('/api/settings', { method: 'PATCH',
                  body: JSON.stringify({ 'ha.rotation_dashboards': JSON.stringify(sel) }) });
              });
              row.appendChild(cb);
              row.style.cursor = 'pointer';
              row.addEventListener('click', (e) => { if (e.target !== cb) cb.click(); });
              rcard.appendChild(row);
            });
          });
          if (!dashList.length) rcard.appendChild(readOnlyRow('No dashboards found', '', ''));

          // External pages: shown in their own overlay during rotation, so
          // the dashboard (and Voice Satellite) stays loaded underneath.
          // The list re-renders itself in place on add/remove — no
          // loadSettings(), which would reload the whole tab.
          let urls = [];
          try { urls = JSON.parse(byKey['ha.rotation_urls']?.value || '[]'); } catch (_) {}
          if (!Array.isArray(urls)) urls = [];
          const saveUrls = (next) => { urls = next; return api('/api/settings',
            { method: 'PATCH',
              body: JSON.stringify({ 'ha.rotation_urls': JSON.stringify(next) }) }); };
          const uhdr = document.createElement('div');
          uhdr.style.cssText = 'padding:12px 0 2px; font-size:13px; font-weight:600;'
            + 'color:var(--primary)';
          uhdr.textContent = 'External pages';
          rcard.appendChild(uhdr);
          const ulist = document.createElement('div');
          rcard.appendChild(ulist);
          const renderUrls = () => {
            ulist.innerHTML = '';
            urls.forEach((u) => {
              const row = readOnlyRow(u, '', '');
              row.querySelector('span').remove();
              row.style.paddingLeft = '14px';
              const rm = document.createElement('button');
              rm.className = 'btn-ghost'; rm.textContent = 'Remove';
              rm.addEventListener('click', async () => {
                await saveUrls(urls.filter((x) => x !== u));
                renderUrls();
              });
              row.appendChild(rm);
              ulist.appendChild(row);
            });
          };
          renderUrls();
          const addRow = document.createElement('div');
          addRow.className = 'row';
          addRow.style.paddingLeft = '14px';
          const inp = document.createElement('input');
          inp.type = 'url';
          inp.placeholder = 'https://example.com';
          inp.style.cssText = 'flex:1; background:var(--surface-2);'
            + 'border:1px solid var(--border); border-radius:var(--radius-sm);'
            + 'color:var(--text); padding:9px 12px; margin-right:8px';
          const add = document.createElement('button');
          add.className = 'btn-ghost'; add.textContent = 'Add';
          const doAdd = async () => {
            let v = inp.value.trim();
            if (!v) return;
            if (v.indexOf('://') === -1) v = 'https://' + v;
            inp.value = '';
            if (!urls.includes(v)) { await saveUrls(urls.concat(v)); renderUrls(); }
          };
          add.addEventListener('click', doAdd);
          inp.addEventListener('keydown', (e) => { if (e.key === 'Enter') doAdd(); });
          addRow.append(inp, add);
          rcard.appendChild(addRow);
        }
        };
        await renderRotationCard();
      }

      // Return to the dashboard (issue #83), mirroring the device: below
      // the rotation group it is mutually exclusive with. While rotation
      // is on the switch renders disabled with the reason (the manager
      // also forces the setting off the moment rotation turns on).
      {
        const rhEnabled = byKey['ha.return_home_enabled'];
        const rhSeconds = byKey['ha.return_home_seconds'];
        if (rhEnabled) {
          const hcard = document.createElement('div');
          hcard.className = 'card';
          panelFor('Return to home dashboard view').appendChild(hcard);
          // The card re-renders itself in place on toggle: the shared
          // settingRow's save would loadSettings() (the seconds row gates
          // on the switch), and on this tab that re-fetches every
          // dashboard — a full-page flash for one checkbox.
          renderReturnCard = () => {
            hcard.innerHTML = '';
            if (byKey['ha.rotation_enabled']?.value === true) {
              hcard.appendChild(toggleRow(rhEnabled.title,
                'Turned off while Dashboard view rotation is on.',
                false, null));
              return;
            }
            hcard.appendChild(toggleRow(rhEnabled.title,
              rhEnabled.description, rhEnabled.value === true,
              async (on) => {
                rhEnabled.value = on;
                await api('/api/settings', { method: 'PATCH',
                  body: JSON.stringify({ 'ha.return_home_enabled': on }) });
                renderReturnCard();
              }));
            // The target, so nobody has to guess which view "the
            // dashboard" means. Kept identical to the device's copy in
            // settings_screen.dart.
            let homePath = null;
            try {
              const u = new URL(byKey['browser.start_url']?.value || '');
              homePath = u.pathname.replace(/^\/+|\/+$/g, '') || null;
            } catch (_) {}
            const note = document.createElement('div');
            note.className = 'row';
            note.style.cssText = 'font-size:12.5px; color:var(--muted);';
            note.textContent = homePath
              ? `Returns to "${homePath}" after the timeout.`
              : 'The configured dashboard has no view path to return to.';
            hcard.appendChild(note);
            if (rhEnabled.value === true && rhSeconds) {
              hcard.appendChild(settingRow(rhSeconds));
            }
          };
          renderReturnCard();
        }
      }

      // Hold mode (issue #266), mirroring the device: the toggle is the
      // live state (pin the current view; screensaver, rotation and the
      // return-home timer stand down), so this card is also the remote
      // release for a hold engaged at the wall.
      {
        const hm = byKey['ha.hold_mode'];
        const hr = byKey['ha.hold_release_minutes'];
        if (hm) {
          const hcard = document.createElement('div');
          hcard.className = 'card';
          panelFor('Hold mode').appendChild(hcard);
          hcard.appendChild(settingRow(hm));
          if (hr) hcard.appendChild(settingRow(hr));
          const hmenu = byKey['ha.hold_menu'];
          if (hmenu) hcard.appendChild(settingRow(hmenu));
        }
      }

      // Optimizations: the connection + performance toggles, hand-built last
      // so the update filter can show live telemetry beneath it. Re-renders
      // itself in place (no loadSettings, which would reload the whole tab).
      {
        const ds = byKey['browser.disable_suspend'];
        const fz = byKey['browser.freeze_on_screensaver'];
        const wf = byKey['browser.ws_filter'];
        if (ds || fz || wf) {
          const ocard = document.createElement('div');
          ocard.className = 'card';
          panelFor('Optimizations').appendChild(ocard);
          if (state.optTimer) { clearInterval(state.optTimer); state.optTimer = null; }

          const optToggle = (s, onToggle) => {
            const row = readOnlyRow(s.title, s.description, '');
            row.querySelector('span').remove();
            const lbl = document.createElement('label'); lbl.className = 'switch';
            const cb = document.createElement('input'); cb.type = 'checkbox'; cb.checked = !!s.value;
            const sl = document.createElement('span'); sl.className = 'slider';
            lbl.append(cb, sl); row.appendChild(lbl);
            cb.addEventListener('change', async () => {
              s.value = cb.checked; // keep local state so the re-render agrees
              await api('/api/settings', { method: 'PATCH', body: JSON.stringify({ [s.key]: cb.checked }) });
              onToggle();
            });
            return row;
          };

          const renderOpt = () => {
            ocard.innerHTML = '';
            if (state.optTimer) { clearInterval(state.optTimer); state.optTimer = null; }
            if (ds) ocard.appendChild(optToggle(ds, renderOpt));
            if (fz) ocard.appendChild(optToggle(fz, (() => {
              // Freezing requires the suspend-disabling script; the device
              // enables it too, so reflect that in the local state.
              if (fz.value === true && ds) ds.value = true;
              renderOpt();
            })));
            if (wf) ocard.appendChild(optToggle(wf, renderOpt));
            if (wf && wf.value === true) {
              const tel = document.createElement('div');
              tel.className = 'row';
              const t = document.createElement('div');
              t.style.cssText = 'color:var(--muted); font-size:13px; line-height:1.5; padding:2px 0';
              t.textContent = 'Waiting for the dashboard to load…';
              tel.appendChild(t);
              ocard.appendChild(tel);
              // Samples of the wrapper's cumulative counters, kept for the
              // last minute: the raw counters run since page load, and a
              // lifetime total ("206980 of 206980") reads as a bug.
              const hist = [];
              const poll = async () => {
                if (!document.getElementById('tab-homeassistant').classList.contains('active')) return;
                try {
                  const r = await (await api('/api/commands/evalJs', { method: 'POST',
                    body: JSON.stringify({ code: 'JSON.stringify(window.__ksWs ? window.__ksWs.stats() : null)' }) })).json();
                  let st = null;
                  try { st = JSON.parse(r.data); if (typeof st === 'string') st = JSON.parse(st); } catch (_) {}
                  // Something on the page subscribed to every entity change
                  // on its own. Those updates never reach this filter, and a
                  // stream that big is what gets a tablet dropped by Home
                  // Assistant for falling behind, so it is worth saying.
                  const raw = st && st.stateChangedSubs > 0
                    ? ' Something on this page receives every entity update anyway, so filtering saves less here.'
                    : '';
                  if (!st || !st.mode || st.mode === 'boot') {
                    hist.length = 0;
                    t.textContent = 'Waiting for the dashboard to load…';
                    return;
                  }
                  if (st.mode === 'passthrough') {
                    hist.length = 0;
                    t.textContent = "This view's entities can't be determined, so its updates are not filtered." + raw;
                    return;
                  }
                  const now = Date.now();
                  const total = st.cTotal || 0, fwd = st.cFwd || 0;
                  // A page reload resets the counters; discard stale history.
                  if (hist.length && total < hist[hist.length - 1].total) hist.length = 0;
                  hist.push({ now, total, fwd });
                  while (hist.length && now - hist[0].now > 60000) hist.shift();
                  const dTotal = hist.length > 1 ? total - hist[0].total : 0;
                  const dFwd = hist.length > 1 ? fwd - hist[0].fwd : 0;
                  const dropped = dTotal - dFwd;
                  const pct = dTotal > 0 ? Math.round(100 * dropped / dTotal) : null;
                  // The watched-entities count is a link: it opens a modal
                  // listing exactly which entities the filter is forwarding.
                  t.textContent = '';
                  const link = document.createElement('span');
                  link.textContent = `Watching ${st.allow} entities on this view.`;
                  link.style.cssText = 'color:var(--primary); text-decoration:underline; cursor:pointer;';
                  link.addEventListener('click', showWatchedEntities);
                  const rest = document.createElement('span');
                  rest.textContent = (pct == null
                    ? ' No updates in the last minute.'
                    : ` Filtered ${pct}% of updates in the last minute (${dropped} of ${dTotal}).`) + raw;
                  t.append(link, rest);
                } catch (_) {}
              };
              poll();
              state.optTimer = setInterval(poll, 2000);
            }
          };
          renderOpt();
        }
      }
    }
  }

  // Configuration backup, mirroring the device's Settings -> Device card:
  // export downloads the full config (settings incl. secrets + the page's
  // localStorage); import uploads one and applies it.
  {
    const host = $('#device-settings');
    const title = document.createElement('h2');
    title.className = 'card-title';
    title.textContent = 'Configuration';
    host.appendChild(title);
    const card = document.createElement('div');
    card.className = 'card';
    host.appendChild(card);

    const mkRow = (label, desc, btnText, onClick) => {
      const row = readOnlyRow(label, desc, '');
      row.querySelector('span').remove();
      const btn = document.createElement('button');
      btn.className = 'btn-ghost'; btn.textContent = btnText;
      btn.addEventListener('click', onClick);
      row.appendChild(btn);
      card.appendChild(row);
      return { row, desc: row.querySelector('.desc') };
    };

    mkRow('Export configuration',
      "Download every setting and the page's local storage.",
      'Download', async () => {
        const res = await api('/api/config/export');
        if (!res.ok) return;
        const config = await res.json();
        const blob = new Blob(
          [JSON.stringify(config, null, 2)],
          { type: 'application/json' });
        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        // The device stamps its own name and clock into the export; use
        // those rather than this browser's, so a file downloaded from
        // across the house still says which tablet it came from and when
        // that tablet made it.
        a.download = exportFileName(config.deviceName, config.exportedAt);
        a.click();
        URL.revokeObjectURL(a.href);
      });

    const imp = mkRow('Import configuration',
      "Replace this device's settings from an exported file.",
      'Choose file\u2026', () => file.click());
    const file = document.createElement('input');
    file.type = 'file';
    file.accept = '.json,application/json';
    file.style.display = 'none';
    // Inside the row, not after it, the card strips the divider off its
    // last child, and a trailing hidden input would steal that place.
    imp.row.appendChild(file);
    file.addEventListener('change', async () => {
      const f = file.files[0];
      file.value = '';
      if (!f) return;
      let config;
      try { config = JSON.parse(await f.text()); } catch (_) {
        imp.desc.textContent = 'That file is not valid JSON.'; return;
      }
      const opts = await askImportOptions(
        config && config.settings && config.settings['device.name']);
      if (!opts) return;
      const res = await api(
        `/api/config/import?adoptIdentity=${opts.adopt ? 1 : 0}&importLocalStorage=${opts.local ? 1 : 0}`,
        { method: 'POST', body: JSON.stringify(config) });
      const out = await res.json().catch(() => ({}));
      imp.desc.textContent = res.ok
        ? `Applied ${out.data && out.data.applied} settings. The page may reload.`
        : (out.error || 'Import failed.');
      if (res.ok) setTimeout(() => location.reload(), 2500);
    });
  }

  // The permissions card lands last on the Voice Satellite tab, same as the
  // on-device settings screen.
  await loadVsPermissions();

  // Counterpart to the capture at the top: put the view back where the
  // person was. One extra frame so late async renders have laid out.
  scroller.scrollTop = keepScroll;
  requestAnimationFrame(() => { scroller.scrollTop = keepScroll; });
}

// The real-MAC switch's status row and, where the hardware read failed, the
// field for typing the address in (issues #252, #300): with the address
// unreadable the flip is otherwise a silent no-op that renders identically
// to a working one. Drawn fresh on every call, from the device's answer,
// so save() can call it right after a flip and after each edit of the
// field. The field is a hidden definition, never in the generic render:
// offered only here, only while the hardware read failed, since anywhere
// else it would invite overriding a good address.
export async function refreshRealMacNote() {
  const row = document.querySelector('[data-key="esphome.real_mac"]');
  if (!row) return;
  for (const cls of ['real-mac-note', 'real-mac-field']) {
    row.parentNode.querySelector(`.${cls}`)?.remove();
  }
  const byKey = Object.fromEntries((state.settings || []).map((s) => [s.key, s]));
  const depSatisfied = (s) => {
    if (!s.dependsOn) return true;
    const dep = byKey[s.dependsOn];
    if (!dep) return true;
    return dep.value === (s.dependsOnValue ?? true) && depSatisfied(dep);
  };
  const on = byKey['esphome.real_mac'];
  if (on?.value !== true || !depSatisfied(on)) return;
  let res;
  try { res = await cmd('esphomeStatus'); } catch { return; }
  // Stale by the time the device answered: the row was re-rendered or
  // a later call already drew the current answer.
  if (!row.isConnected || row.parentNode.querySelector('.real-mac-note')) return;
  const mac = res.data?.realMac || null;
  const source = res.data?.realMacSource || (mac ? 'hardware' : 'none');
  const note = document.createElement('div');
  note.className = 'real-mac-note';
  note.style.cssText = 'display:flex; gap:8px; ' +
    'align-items:flex-start; margin:6px 0 10px; ' +
    `font-size:12.5px; color:var(--${mac ? 'muted' : 'warn'}); ` +
    'line-height:1.5';
  note.innerHTML = mac
    ? '<svg width="15" height="15" viewBox="0 0 24 24" ' +
      'fill="none" stroke="currentColor" stroke-width="2" ' +
      'stroke-linecap="round" style="flex:none; margin-top:2px">' +
      '<circle cx="12" cy="12" r="9"/>' +
      '<path d="M12 8h.01M12 11.5V16"/></svg><span></span>'
    : '<svg width="15" height="15" viewBox="0 0 24 24" ' +
      'fill="none" stroke="currentColor" stroke-width="2" ' +
      'stroke-linecap="round" stroke-linejoin="round" ' +
      'style="flex:none; margin-top:2px">' +
      '<path d="M10.3 3.9 1.9 18a2 2 0 0 0 1.7 3h16.8a2 2 0 0 0 ' +
      '1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/>' +
      '<path d="M12 9v4M12 17h.01"/></svg><span></span>';
  note.querySelector('span').textContent = !mac
    ? 'Android will not reveal this device\'s hardware address.'
    : source === 'manual'
      ? `Reporting ${mac}, entered below.`
      : `Reporting ${mac}.`;
  row.insertAdjacentElement('afterend', note);
  const field = byKey['esphome.mac_override'];
  if (source !== 'hardware' && field) {
    // The device stores the canonical spelling; the field shows that, not
    // the dashes or bare digits that were typed.
    if (source === 'manual' && mac) field.value = mac;
    const fieldRow = settingRow(field);
    fieldRow.classList.add('real-mac-field');
    note.insertAdjacentElement('afterend', fieldRow);
  }
}
