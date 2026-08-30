import { WIZ_LOCKED, WIZ_OPTIONAL, wizard } from './app.js';
import { $, THEME_ICONS, api, showView, state } from './core.js';
import { readOnlyRow } from './device.js';
import { askImportOptions } from './pickers.js';
import { fetchViews, pickView, radioRow, viewPath } from './views.js';

// The wizard starts light (the product default) whatever an earlier
// admin session stored; its own toggle flips light/dark, and the choice
// persists so the app matches after setup.
// The device wizard's error card, verbatim: what went wrong in bold,
// what to do about it underneath, on the error tint.
export function wizFail(title, hint) {
  const err = new Error(title);
  err.hint = hint;
  return err;
}

// After an onboarding import, the OS permission prompts run on the DEVICE
// and setup completes there. A full-screen wait (covering the wizard and
// its Next button - there is nothing to do here) says so and follows along
// until the device reports itself configured. Shown right after an import
// and on page load while the device says importPending, so a mid-wait
// reload does not present an empty wizard as if nothing was imported.
export function showImportPending() {
  if (document.getElementById('importPending')) return;
  const ov = document.createElement('div');
  ov.id = 'importPending';
  ov.style.cssText = 'position:fixed; inset:0; background:var(--bg);'
    + 'z-index:1200; display:grid; place-items:center; padding:24px; text-align:center';
  ov.innerHTML = '<div style="max-width:440px">'
    + '<h2 style="font-size:21px; font-weight:700; margin-bottom:10px">Finish on the device</h2>'
    + '<div style="font-size:14px; line-height:1.6; color:var(--muted)">The configuration was imported. '
    + "Answer the permission prompts on the tablet's screen - this page continues automatically "
    + 'when the dashboard loads.</div></div>';
  document.body.appendChild(ov);
  const poll = setInterval(async () => {
    try {
      const setup = await (await fetch('api/setup/status')).json();
      if (!setup.setupNeeded) { clearInterval(poll); location.reload(); }
    } catch (_) { /* device may be busy applying; keep polling */ }
  }, 2000);
}

export function wizConnectFail(error) {
  if (error.includes('invalid token')) {
    return wizFail('Invalid access token',
      'Home Assistant rejected this token. In Home Assistant, open your profile \u2192 Security \u2192 Long-lived access tokens, create a new token, and copy the complete value.');
  }
  if (error.startsWith('unreachable')) {
    return wizFail("Can't reach Home Assistant",
      'No response from this address. Check that the URL is correct and that this device is on the same network as your Home Assistant server.');
  }
  if (error.startsWith('HTTP')) {
    return wizFail(`Unexpected response (${error})`,
      "A server responded, but it doesn't appear to be Home Assistant. Check that the URL is your Home Assistant base address, for example https://homeassistant.local:8123.");
  }
  return wizFail("Can't connect", error);
}

export function wizardShowError(e) {
  const box = $('#wizardError');
  box.innerHTML =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 8v4m0 4h.01"/></svg>' +
    '<span><b></b><span class="hint"></span></span>';
  box.querySelector('b').textContent = e.message || String(e);
  box.querySelector('.hint').textContent = e.hint || '';
}

export function wizardApplyTheme(theme) {
  document.documentElement.dataset.theme = theme;
  const btn = $('#wizardThemeBtn');
  btn.innerHTML = THEME_ICONS[theme];
  btn.title = `Theme: ${theme}`;
  btn.setAttribute('aria-label', `Theme: ${theme}`);
}

export function wizardShow() {
  wizardApplyTheme('light');
  showView('wizard');
  wizardRender();
}

$('#wizardThemeBtn').addEventListener('click', () => {
  const next =
    document.documentElement.dataset.theme === 'light' ? 'dark' : 'light';
  localStorage.setItem('ks_theme', next);
  wizardApplyTheme(next);
});

export function wizardRender() {
  const s = wizard.steps[wizard.i];
  // The rail: one row per step, numbered disc → check when done, dash when
  // skipped, the same shape the on-device wizard and settings rail use.
  const rail = $('#wizardStepsRail');
  rail.innerHTML = '';
  wizard.steps.forEach((step, n) => {
    const row = document.createElement('div');
    const skipped = step.isVs && wizard.i > n && !wizard.vsDetected;
    const done = n < wizard.i && !skipped;
    row.className = 'wizard-step' +
      (n === wizard.i ? ' now' : '') + (done ? ' done' : '');
    const disc = document.createElement('span');
    disc.className = 'stepdisc';
    disc.textContent = done ? '\u2713' : skipped ? '-' : String(n + 1);
    const text = document.createElement('span');
    text.className = 'nav-text';
    text.innerHTML = '<span class="nav-title"></span><span class="nav-sub"></span>';
    text.querySelector('.nav-title').textContent = step.railTitle;
    text.querySelector('.nav-sub').textContent =
      skipped ? 'Not installed, skipped' : step.railSub;
    row.append(disc, text);
    rail.appendChild(row);
  });
  $('#wizardError').textContent = '';
  $('#wizardBack').classList.toggle('hidden', wizard.i === 0);
  $('#wizardNext').textContent = s.nextLabel || 'Next';
  $('#wizardTitle').textContent = s.title;
  $('#wizardLead').textContent = s.lead;
  const body = $('#wizardBody');
  body.innerHTML = '';
  s.body(body);
}

// A group heading above a wizard card, the settings pages' card-title.
export function wizardHeading(body, text) {
  const h = document.createElement('h2');
  h.className = 'card-title';
  h.textContent = text;
  body.appendChild(h);
  return h;
}

export function wizardCard(body, rows = false) {
  const card = document.createElement('div');
  card.className = rows ? 'card rows' : 'card';
  body.appendChild(card);
  return card;
}

export function wizardField(body, id, type, placeholder) {
  const f = document.createElement('input');
  f.className = 'field'; f.id = id; f.type = type;
  f.placeholder = placeholder; f.autocomplete = 'off';
  body.appendChild(f);
  return f;
}

// The settings pages' own switch control, not a checkbox glyph.
export function wizardToggleRow(label, desc, on, locked, onClick) {
  const row = readOnlyRow(label, desc, '');
  row.querySelector('span').remove();
  const lbl = document.createElement('label');
  lbl.className = 'switch';
  const input = document.createElement('input');
  input.type = 'checkbox';
  input.checked = on;
  input.disabled = !!locked;
  if (!locked) input.addEventListener('change', onClick);
  const slider = document.createElement('span');
  slider.className = 'slider';
  lbl.append(input, slider);
  row.appendChild(lbl);
  return row;
}

// The Kiosk Satellite Service under the restore card, mirroring the device
// wizard: what it is, and the three grants it needs on every install under
// a row that asks for them outright, each with a button that opens the
// dialog on the tablet and polls until the grant lands.
export function wizardServiceCard(b) {
  const card = wizardCard(b, true);
  const intro = readOnlyRow('Kiosk Satellite Service',
    'Keeps the app alive while the screen is off or another app is in '
      + 'front, so the Home Assistant connection and other features like '
      + 'motion detection and the Bluetooth proxy stay alive. The permissions '
      + 'below are optional but recommended: each one helps it survive the '
      + 'screen being off.', '');
  intro.querySelector('span').remove();
  card.appendChild(intro);
  // Before a password exists there is no token, and an api() call would
  // 401 into logout, which restarts this very wizard: a blink loop. The
  // server answers two setup-only endpoints in that window instead.
  const passwordless = () => wizard.needPassword && !state.token;
  const post = (name, body) => api('/api/commands/' + name,
    { method: 'POST', body: JSON.stringify(body || {}) })
    .then((r) => r.json()).catch(() => null);
  const readAll = async () => {
    if (passwordless()) {
      const res = await fetch('api/setup/grants').then((r) => r.ok ? r.json() : null).catch(() => null);
      return res ? { perms: res.permissions, grants: res.grants || {} } : { perms: null, grants: {} };
    }
    const [st, pm] = await Promise.all([post('getServiceStatus'), post('getSystemPermissions')]);
    return { perms: pm && pm.ok ? pm.data : null, grants: st && st.ok ? (st.data.grants || {}) : {} };
  };
  const requestGrant = (ask) => passwordless()
    ? fetch('api/setup/grant', { method: 'POST', body: JSON.stringify({ which: ask }) }).catch(() => null)
    : post('requestOsPermissions', { which: ask });

  const grantRow = (key, name, held, missing, idle, ask) => {
    const row = readOnlyRow(name, 'Checking\u2026', '');
    const span = row.querySelector('span');
    row._render = (granted, needed, adbHint) => {
      const ok = granted === true;
      // The device has no screen for the grant: the adb command stands in
      // for the button, and the row is not an error nobody can fix.
      const urgent = needed && !adbHint;
      row.querySelector('.desc').textContent =
        granted == null ? 'Status unavailable.' : ok ? held : adbHint || (needed ? missing : idle);
      span.textContent = granted == null ? '' : ok ? 'Granted'
        : adbHint ? 'Not offered' : needed ? 'Missing' : 'Not granted';
      span.style.cssText = 'white-space:nowrap; color:'
        + (ok ? 'var(--ok)' : urgent ? 'var(--error)' : 'var(--muted)');
      row.querySelector('button')?.remove();
      if (ok || granted == null || adbHint) return;
      const btn = document.createElement('button');
      btn.className = 'btn-ghost';
      btn.textContent = 'Grant on device';
      btn.style.cssText = 'flex-shrink:0;';
      btn.addEventListener('click', async () => {
        btn.disabled = true;
        await requestGrant(ask);
        let tries = 30;
        const tick = setInterval(async () => {
          const all = await refresh();
          if (all === true || --tries <= 0) clearInterval(tick);
        }, 2000);
      });
      row.appendChild(btn);
    };
    card.appendChild(row);
    return [key, row];
  };
  const rows = [
    grantRow('batteryUnrestricted', 'Unrestricted battery',
      'Allows the process to run in the background without being paused or killed.',
      'Android may pause the app when the screen is off, dropping the Home Assistant connection with it.',
      '', ['batteryOptimizations']),
    grantRow('displayOverOtherApps', 'Display over other apps',
      'Kiosk Satellite can bring itself back in the foreground.',
      'Without this the service cannot relaunch the kiosk after a crash.',
      'Needed to relaunch the kiosk after a crash.', ['overlay']),
    grantRow('notification', 'Notifications',
      "Allows the Kiosk Satellite Service's ongoing notification, which says what it is keeping alive.",
      "Needed to show the Kiosk Satellite Service's ongoing notification.",
      '', ['notifications']),
  ];
  let grants = {};
  const refreshGrants = async (p) => {
    let all = true;
    const ADB = {
      batteryUnrestricted: ['batteryRequestable', "This device has no settings screen for it. Grant it over adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite"],
      displayOverOtherApps: ['overlayRequestable', "This device has no settings screen for it. Grant it over adb: adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow"],
    };
    for (const [key, row] of rows) {
      const granted = p ? p[key] === true : null;
      const adb = p && !granted && ADB[key] && p[ADB[key][0]] === false ? ADB[key][1] : null;
      row._render(granted, grants[key] === true, adb);
      if (!granted) all = false;
    }
    return p ? all : null;
  };
  const refresh = async () => {
    const { perms, grants: g } = await readAll();
    grants = g || {};
    return refreshGrants(perms);
  };
  // Only while the card is actually on screen: a step change drops it,
  // and a fall back to the login view leaves the wizard body in the DOM
  // but hidden, where every poll would just be a 401.
  const visible = () => card.isConnected && card.offsetParent !== null;
  if (visible()) refresh();
  const timer = setInterval(() => {
    if (!card.isConnected) { clearInterval(timer); return; }
    if (visible()) refresh();
  }, 5000);
}

// The restore path on the wizard's first screen: pick an exported backup
// and skip the setup entirely. The backup's remote.password and
// remote.enabled are dropped before upload — importing them could lock out
// the person mid-wizard (they just typed a different password) or disable
// the very server this page is talking to. The password chosen on THIS
// device stays in charge; everything else comes from the file.
export function wizardRestoreCard(b) {
  // A rows card with a settings-style row, like the cards around it: a
  // plain card with a padded row of its own read as a taller, looser
  // group than its neighbours.
  const card = wizardCard(b, true);
  const row = readOnlyRow('Restore from configuration file',
    'Import a configuration exported from Kiosk Satellite and skip the rest of this wizard.', '');
  row.querySelector('span').remove();
  const file = document.createElement('input');
  file.type = 'file';
  file.accept = '.json,application/json';
  file.hidden = true;
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = 'Import';
  btn.style.cssText = 'flex-shrink:0;';
  btn.addEventListener('click', () => file.click());
  file.addEventListener('change', () => wizardRestore(file, btn));
  row.append(btn, file);
  card.appendChild(row);
}

export async function wizardRestore(file, btn) {
  const f = file.files && file.files[0];
  file.value = '';
  if (!f) return;
  let config;
  try {
    config = JSON.parse(await f.text());
  } catch (_) {
    wizardShowError(wizFail('Not a backup file', 'That file is not valid JSON.'));
    return;
  }
  if (!config || config.kind !== 'kiosk-satellite-config') {
    wizardShowError(wizFail('Not a backup file',
      'Export a configuration from the Settings tab of a set-up Kiosk Satellite.'));
    return;
  }
  if (config.settings) {
    delete config.settings['remote.password'];
    delete config.settings['remote.enabled'];
  }
  const opts = await askImportOptions(
    config.settings && config.settings['device.name']);
  if (!opts) return;
  btn.disabled = true;
  btn.textContent = 'Importing…';
  try {
    // On the password screen the import runs authenticated, so the typed
    // password is minted first. needPassword overrides a lingering token
    // deliberately: the device says no password exists, so any token the
    // browser still holds is from a previous life of the device (wiped and
    // being set up again) and would only 401.
    if (!state.token || wizard.needPassword) {
      const password = $('#wzPassword') ? $('#wzPassword').value : '';
      if (password.length < 4) {
        throw wizFail('Set the admin password first',
          'Type an admin password above (at least 4 characters), then import the backup.');
      }
      const res = await fetch('api/setup/password', { method: 'POST', body: JSON.stringify({ password }) });
      const out = await res.json();
      if (!res.ok) throw wizFail('Could not set the password', out.error || '');
      state.token = out.token;
      localStorage.setItem('ks_token', state.token);
    }
    const res = await api(
      `/api/config/import?adoptIdentity=${opts.adopt ? 1 : 0}&importLocalStorage=${opts.local ? 1 : 0}`,
      { method: 'POST', body: JSON.stringify(config) });
    const out = await res.json();
    if (!res.ok) throw wizFail('Import failed', out.error || 'The file could not be applied.');
    if (out.data && out.data.pendingSetup) {
      // The settings are in, but the OS permission prompts run on the
      // DEVICE and the dashboard loads after they are answered there.
      showImportPending();
      return;
    }
    // Setup is complete (the backup's start URL landed); a reload leaves
    // the wizard and the stored token walks straight into the admin UI.
    location.reload();
  } catch (e) {
    wizardShowError(e);
    btn.disabled = false;
    btn.textContent = 'Import';
  }
}

export function wizardSteps() {
  const steps = [];
  // The same first page as the device wizard, always: the admin password
  // where one is still needed, the restore path, and the service the whole
  // kiosk rides on, introduced where the kiosk is born rather than
  // discovered later as a notification. The Connect step is then only the
  // Home Assistant connection, on both surfaces.
  steps.push({
    railTitle: 'Welcome', railSub: 'Remote administration',
    title: 'Welcome to Kiosk Satellite',
    lead: wizard.needPassword
      ? 'This tablet is waiting to be set up. First, protect this remote admin with a password.'
      : 'This tablet is waiting to be set up. The remote admin password is already set; type a new one here to change it.',
    body: (b) => {
      // The device name first, seeded with what the device calls itself
      // (the model, until someone names it): the ESPHome node name is
      // taken from it at the server's first start, so a name given here
      // reads as kitchen-tablet in Home Assistant rather than a generated
      // kiosk-satellite-<id>.
      const dev = wizardCard(b);
      const nameField = wizardField(dev, 'wzDeviceName', 'text', 'Device name');
      nameField.value = wizard.deviceName || '';
      const note = document.createElement('div');
      note.style.cssText = 'color:var(--muted); font-size:12.5px; line-height:1.5; margin-top:-4px';
      note.textContent = 'How this kiosk is called in Home Assistant, in the remote admin '
        + 'and on the network. Change it any time under Settings, Device.';
      dev.appendChild(note);
      wizardHeading(b, 'Remote administration');
      // Always a field: with a password already set (on the tablet, or by
      // an earlier pass through this step) it changes it, and an empty
      // field keeps it.
      wizardField(wizardCard(b), 'wzPassword', 'password', wizard.needPassword
        ? 'Admin password (min 4 characters)'
        : 'New admin password (leave empty to keep the current one)');
      wizardHeading(b, 'Restore backup');
      wizardRestoreCard(b);
      wizardHeading(b, 'Recommended Service Permissions');
      wizardServiceCard(b);
    },
    next: async () => {
      // The service's required grants first: the whole kiosk rides on
      // them, and the page just asked for them by name.
      const password = $('#wzPassword').value;
      const deviceName = $('#wzDeviceName').value.trim();
      wizard.deviceName = deviceName;
      if (!wizard.needPassword && !password) {
        // Keeping the password: the session it minted carries the name.
        await api('/api/settings', { method: 'PATCH',
          body: JSON.stringify({ 'device.name': deviceName }) });
        return;
      }
      if (password.length < 4) throw wizFail('Password too short', 'Use at least 4 characters.');
      // A change rides the session the current password minted; a first
      // password has no session yet and goes bare. The name rides along
      // either way: before a password exists there is nothing to PATCH
      // settings with.
      const body = JSON.stringify({ password, deviceName });
      const res = wizard.needPassword
        ? await fetch('api/setup/password', { method: 'POST', body })
        : await api('/api/setup/password', { method: 'POST', body });
      const out = await res.json();
      if (!res.ok) {
        // A password already exists: set on the tablet's own wizard, or by
        // an earlier press of this button whose reply was lost. The login
        // view is where that password is useful, so go there.
        if (res.status === 403) {
          setTimeout(() => location.reload(), 2500);
          throw wizFail('A password is already set',
            'Log in with the password set on the tablet to continue here. Reloading\u2026');
        }
        throw wizFail('Could not set the password', out.error || '');
      }
      state.token = out.token; localStorage.setItem('ks_token', state.token);
    },
  });
  steps.push({
    railTitle: 'Connect', railSub: 'Home Assistant URL & token',
    title: 'Connect to Home Assistant',
    lead: 'The base URL of your instance and a long-lived access token, created under your HA profile \u2192 Security \u2192 Long-lived access tokens.',
    nextLabel: 'Validate & continue',
    body: (b) => {
      const card = wizardCard(b);
      wizardField(card, 'wzUrl', 'url', 'https://homeassistant.local:8123');
      wizardField(card, 'wzToken', 'password', 'Long-lived access token');
    },
    next: async () => {
      const url = $('#wzUrl').value.trim(), token = $('#wzToken').value.trim();
      if (!url) throw wizFail('Enter your Home Assistant base URL',
        'This is the address you use to open Home Assistant, for example https://homeassistant.local:8123.');
      if (!token) throw wizFail('Enter a long-lived access token',
        'In Home Assistant, open your profile \u2192 Security \u2192 Long-lived access tokens to create one.');
      const patch = await api('/api/settings', { method: 'PATCH',
        body: JSON.stringify({ 'ha.url': url, 'ha.token': token }) });
      const pout = await patch.json();
      if ((pout.rejected || []).includes('ha.url')) {
        throw wizFail('Invalid base URL',
          'Enter only the base URL, without a dashboard path. Example: https://homeassistant.local:8123');
      }
      const check = await (await api('/api/commands/haCheckConnection', { method: 'POST', body: '{}' })).json();
      if (!check.ok) throw wizConnectFail(check.error || '');
      // Plain-http instance: enable the secure context proxy up front so
      // the dashboard gets the https-only browser surface (microphone for
      // Voice Satellite) from its very first load.
      try {
        const wu = new URL(url);
        if (wu.protocol === 'http:'
          && wu.hostname !== 'localhost' && wu.hostname !== '127.0.0.1') {
          await api('/api/settings', { method: 'PATCH',
            body: JSON.stringify({ 'browser.secure_proxy': true }) });
        }
      } catch (_) { /* not a parseable URL; validation already passed */ }
      const dashboards = await (await api('/api/commands/haListDashboards', { method: 'POST', body: '{}' })).json();
      wizard.dashboards = dashboards.data || [];
      wizard.dashboard = wizard.dashboards[0]?.url_path || null;
      wizard.base = url.replace(/\/$/, '');
      // The kiosk lands on a single view; default the chosen dashboard to its
      // first, ready for the Dashboard step's "Change view".
      wizard.dashboardViews = wizard.dashboard ? await fetchViews(wizard.dashboard) : null;
      wizard.dashboardView = (wizard.dashboardViews && wizard.dashboardViews.length)
        ? String(wizard.dashboardViews[0].route) : '';
    },
  });
  steps.push({
    railTitle: 'Dashboard', railSub: 'What the kiosk shows',
    title: 'Choose a dashboard',
    lead: 'This is what the kiosk will show when it starts.',
    body: (b) => {
      const list = wizardCard(b, true);
      if (!wizard.dashboards.length) {
        list.appendChild(readOnlyRow('No dashboards found', '', ''));
        return;
      }
      wizard.dashboards.forEach((d) => {
        const selected = wizard.dashboard === d.url_path;
        // The selected dashboard shows its chosen view (defaulting to the
        // first) with a "Change view" button; the rest name the dashboard.
        const sub = selected ? viewPath(d.url_path, wizard.dashboardView) : d.url_path;
        const row = radioRow(d.title || d.url_path, sub, selected, async () => {
          if (selected) return;
          wizard.dashboard = d.url_path;
          wizard.dashboardViews = await fetchViews(d.url_path);
          wizard.dashboardView = (wizard.dashboardViews && wizard.dashboardViews.length)
            ? String(wizard.dashboardViews[0].route) : '';
          wizardRender();
        });
        if (selected && wizard.dashboardViews && wizard.dashboardViews.length) {
          const btn = document.createElement('button');
          btn.className = 'btn-ghost';
          btn.textContent = 'Change view';
          btn.style.cssText = 'margin-left:8px; flex-shrink:0;';
          btn.addEventListener('click', async (e) => {
            e.stopPropagation();
            const route = await pickView(d.url_path, wizard.dashboardViews, wizard.dashboardView);
            if (route == null) return;
            wizard.dashboardView = route;
            wizardRender();
          });
          row.appendChild(btn);
        }
        list.appendChild(row);
      });
    },
    next: async () => {
      if (!wizard.dashboard) throw wizFail('Select a dashboard',
        'Choose the dashboard the kiosk will display. You can change it later in Settings.');
      const vs = await (await api('/api/commands/haDetectVoiceSatellite', { method: 'POST', body: '{}' })).json();
      wizard.vsDetected = vs.ok && vs.data === true;
      if (wizard.vsDetected) {
        const sats = await (await api('/api/commands/haListVoiceSatellites', { method: 'POST', body: '{}' })).json();
        wizard.satellites = (sats.ok && sats.data) || [];
        wizard.satellite = wizard.satellite || wizard.satellites[0]?.entity_id || null;
      }
      if (!wizard.vsDetected) wizard.i++; // skip the VS step
    },
  });
  steps.push({
    isVs: true,
    railTitle: 'Voice Satellite', railSub: 'Satellite, recommended settings',
    title: 'Voice Satellite detected',
    lead: 'This Home Assistant instance runs the Voice Satellite integration. Choose which satellite this kiosk is, then review its settings. Everything can be changed later.',
    body: (b) => {
      const sats = wizardCard(b, true);
      if (!wizard.satellites.length) {
        sats.appendChild(readOnlyRow('No satellites found',
          'Add an assist satellite in the Voice Satellite integration, or continue and pick one on the dashboard later.', ''));
      } else {
        wizard.satellites.forEach((s) => {
          sats.appendChild(radioRow(s.name || s.entity_id, s.entity_id,
            wizard.satellite === s.entity_id,
            () => { wizard.satellite = s.entity_id; wizardRender(); }));
        });
        // The same pointer the device wizard shows under its list: an
        // existing satellite belongs to the device already using it.
        const hint = document.createElement('div');
        hint.style.cssText = 'display:flex; gap:10px; align-items:flex-start; '
          + 'color:var(--muted); font-size:13px; font-weight:600; '
          + 'line-height:1.5; padding:0 6px 14px;';
        hint.innerHTML = '<svg viewBox="0 0 24 24" width="18" height="18" '
          + 'fill="none" stroke="currentColor" stroke-width="2" '
          + 'stroke-linecap="round" style="flex:none; margin-top:1px" '
          + 'aria-hidden="true"><circle cx="12" cy="12" r="9"/>'
          + '<path d="M12 8h.01M12 12v4"/></svg>';
        const hintText = document.createElement('span');
        hintText.textContent = 'If this is a new device, create a new '
          + 'satellite entity in Home Assistant first. Settings → '
          + 'Devices & Services → Voice Satellite → Add Entry. '
          + 'IMPORTANT: Two devices cannot share the same entity.';
        hint.appendChild(hintText);
        b.appendChild(hint);
      }
      const toggleRow = wizardToggleRow;
      const master = wizardCard(b, true);
      const all = WIZ_OPTIONAL.every(([k]) => wizard.rec[k]);
      master.appendChild(toggleRow('Apply all recommended settings',
        'The optimal settings for full Voice Satellite integration and functionality.',
        all, false, () => {
          const next = !all;
          WIZ_OPTIONAL.forEach(([k]) => { wizard.rec[k] = next; });
          wizardRender();
        }));
      const list = wizardCard(b, true);
      WIZ_LOCKED.forEach(([, label]) =>
        list.appendChild(toggleRow(label, 'Required by Voice Satellite', true, true)));
      WIZ_OPTIONAL.forEach(([key, label]) =>
        list.appendChild(toggleRow(label, '', wizard.rec[key], false, () => {
          wizard.rec[key] = !wizard.rec[key];
          wizardRender();
        })));
    },
    next: async () => {},
  });
  steps.push({
    railTitle: 'Permissions', railSub: 'What the setup needs',
    title: 'Permissions',
    lead: 'Android asks for these on the tablet itself. Walk over and accept the prompts, then finish here.',
    nextLabel: 'Finish',
    body: (b) => {
      const background = wizard.vsDetected && wizard.rec['wake_word.background'];
      const bootStart = wizard.vsDetected && wizard.rec['kiosk.start_on_boot'];
      const list = wizardCard(b, true);
      // Status to the right of each row, exactly as the settings pages
      // show grants: green Granted / red Not granted, read live from the
      // device and re-read after the prompts run.
      const statusSpans = {};
      const addRow = (key, name, desc) => {
        const row = readOnlyRow(name, desc, '\u2026');
        statusSpans[key] = row.querySelector('span');
        list.appendChild(row);
      };
      addRow('microphone', 'Microphone',
        'Voice Satellite requires microphone access');
      // The Kiosk Satellite Service's two, on every install: its
      // notification, and the exemption that keeps it running.
      addRow('notification', 'Notifications',
        background
          ? "Allows the Kiosk Satellite Service's ongoing notification, which says what it is keeping alive and when the kiosk is listening."
          : "Allows the Kiosk Satellite Service's ongoing notification, which says what it is keeping alive.");
      addRow('batteryUnrestricted', 'Unrestricted battery',
        'Allows the Kiosk Satellite Service to run in the background without being paused or killed.');
      addRow('displayOverOtherApps', 'Display over other apps',
        bootStart
          ? 'Lets Kiosk Satellite come back after a crash and start when your device boots.'
          : 'Lets Kiosk Satellite come back on screen after a crash.');
      addRow('writeSettings', 'Screen brightness',
        "Allows Kiosk Satellite to set the panel's actual brightness (modify system settings).");
      addRow('deviceAdmin', 'Screen control',
        'Allows Kiosk Satellite to turn the screen off on request (device admin).');
      const refreshStatus = async () => {
        try {
          const res = await (await api('/api/commands/getSystemPermissions', { method: 'POST', body: '{}' })).json();
          const p = res.data || {};
          for (const [key, span] of Object.entries(statusSpans)) {
            const ok = !!p[key];
            span.textContent = ok ? 'Granted' : 'Not granted';
            span.style.cssText =
              'white-space:nowrap; color:' + (ok ? 'var(--ok)' : 'var(--error)');
          }
          return p;
        } catch (_) { return null; }
      };
      refreshStatus();
      // Tonal, like the wizard's Back button, Finish stays the one
      // filled action on the step.
      const btn = document.createElement('button');
      btn.className = 'btn-ghost';
      btn.style.cssText = 'padding:12px 24px; margin:2px 0 12px';
      btn.textContent = 'Grant permissions on the device';
      btn.addEventListener('click', async () => {
        btn.disabled = true;
        btn.style.opacity = '.6';
        btn.textContent = 'Requesting on the device\u2026';
        await api('/api/commands/requestOsPermissions', { method: 'POST',
          body: JSON.stringify({ which: [
            'microphone',
            'batteryOptimizations',
            'notifications',
            // Auto-reload on error (default on) needs the overlay grant to
            // bring the app back after a crash; boot start rides the same one.
            'overlay',
            'writeSettings',
            'deviceAdmin',
          ] }) });
        btn.textContent = 'Permissions requested on the device';
        // The runtime dialogs are awaited by the request, but the device
        // admin activation is a full screen the request only LAUNCHES: the
        // user taps Activate after this returns. Keep re-reading until the
        // grants settle so the rows catch up.
        for (let i = 0; i < 20; i++) {
          const p = await refreshStatus();
          if (p && Object.keys(statusSpans).every((k) => !!p[k])) break;
          await new Promise((r) => setTimeout(r, 2500));
        }
      });
      b.appendChild(btn);
    },
    next: async () => {
      if (wizard.vsDetected) {
        const chosen = Object.fromEntries([
          ...WIZ_LOCKED.map(([k]) => [k, true]),
          ...Object.entries(wizard.rec),
        ]);
        if (wizard.satellite) chosen['ha.satellite_entity'] = wizard.satellite;
        await api('/api/settings', { method: 'PATCH', body: JSON.stringify(chosen) });
      }
      // Setting the start URL is what flips the device to configured; the
      // kiosk on the wall navigates to the chosen dashboard view on its own.
      const route = wizard.dashboardView || '';
      const startUrl = route
        ? `${wizard.base}/${wizard.dashboard}/${route}`
        : `${wizard.base}/${wizard.dashboard}`;
      await api('/api/settings', { method: 'PATCH',
        body: JSON.stringify({ 'browser.start_url': startUrl }) });
      location.reload();
    },
  });
  return steps;
}

export async function startWizard({ needPassword }) {
  wizard.needPassword = needPassword;
  // Read by logout(): a 401 must not rebuild a wizard that is already up.
  $('#wizard').dataset.needPassword = needPassword ? '1' : '0';
  // The first page's Device name starting value: what is set, or the
  // model. Public, like the rest of the status, since before a password
  // exists there is no session to ask with.
  try {
    const setup = await (await fetch('api/setup/status')).json();
    wizard.deviceName = setup?.deviceName || '';
  } catch (_) { wizard.deviceName = ''; }
  wizard.i = 0;
  wizard.steps = wizardSteps();
  wizardShow();
}

$('#wizardNext').addEventListener('click', async () => {
  const btn = $('#wizardNext');
  const step = wizard.steps[wizard.i];
  btn.disabled = true;
  try {
    await step.next();
    if (wizard.i < wizard.steps.length - 1) { wizard.i++; wizardRender(); }
  } catch (e) {
    wizardShowError(e);
  } finally {
    btn.disabled = false;
  }
});
$('#wizardBack').addEventListener('click', () => {
  // Stepping back over the VS step when it was skipped forward.
  const target = wizard.i - 1;
  wizard.i = (target === 3 && !wizard.vsDetected) ? 2 : Math.max(0, target);
  wizardRender();
});
