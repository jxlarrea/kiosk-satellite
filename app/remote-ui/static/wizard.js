import { deviceText, setupText, setupImportError, themeLabel, messageLanguage, setLanguagePreference, t } from './localization.js';
import { WIZ_OPTIONAL, wizard } from './app.js';
import { $, THEME_ICONS, api, cmd, saveToken, showView, state } from './core.js';
import { readOnlyRow } from './device.js';
import { applyHeadless, isHeadless } from './headless.js';
import { adbHint, permissionSpecs } from './permissions.js';
import { askImportOptions } from './pickers.js';
import { dashboardPicker, loadDashboards } from './dashboard_picker.js';
import { openVsMigrationWizard } from './vs_native.js';

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
export function showImportPending(language) {
  if (language !== undefined) setLanguagePreference(language);
  if (document.getElementById('importPending')) return;
  const ov = document.createElement('div');
  ov.id = 'importPending';
  ov.style.cssText = 'position:fixed; inset:0; background:var(--bg);'
    + 'z-index:1200; display:grid; place-items:center; padding:24px; text-align:center';
  ov.innerHTML = '<div style="max-width:440px">'
    + '<h2 style="font-size:21px; font-weight:700; margin-bottom:10px"></h2>'
    + '<div class="import-pending-help" style="font-size:14px; line-height:1.6; color:var(--muted)"></div></div>';
  const paint = () => {
    ov.querySelector('h2').textContent = t('setupFinishOnDevice');
    ov.querySelector('.import-pending-help').textContent = t('setupFinishOnDeviceHelp');
  };
  paint();
  document.body.appendChild(ov);
  const poll = setInterval(async () => {
    try {
      const setup = await (await fetch('api/setup/status')).json();
      if (setup.language !== undefined) setLanguagePreference(setup.language);
      paint();
      if (!setup.setupNeeded) { clearInterval(poll); location.reload(); }
    } catch (_) { /* device may be busy applying; keep polling */ }
  }, 2000);
}

export function wizConnectFail(error) {
  if (error.includes('invalid token')) {
    return wizFail(t('setupInvalidToken'),
      t('setupInvalidTokenHelp'));
  }
  if (error.startsWith('unreachable')) {
    return wizFail(t('setupUnreachable'),
      t('setupUnreachableHelp'));
  }
  if (error.startsWith('HTTP')) {
    return wizFail(t('setupUnexpectedResponse', { error }),
      t('setupUnexpectedResponseHelp'));
  }
  return wizFail(t('setupCannotConnect'), error);
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
  btn.title = themeLabel(theme);
  btn.setAttribute('aria-label', btn.title);
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
  // The rail: one row per step, numbered disc → check when done, the same
  // shape the on-device wizard and settings rail use.
  const rail = $('#wizardStepsRail');
  rail.innerHTML = '';
  wizard.steps.forEach((step, n) => {
    const row = document.createElement('div');
    const done = n < wizard.i;
    row.className = 'wizard-step' +
      (n === wizard.i ? ' now' : '') + (done ? ' done' : '');
    const disc = document.createElement('span');
    disc.className = 'stepdisc';
    disc.textContent = done ? '\u2713' : String(n + 1);
    const text = document.createElement('span');
    text.className = 'nav-text';
    text.innerHTML = '<span class="nav-title"></span><span class="nav-sub"></span>';
    text.querySelector('.nav-title').textContent = step.railTitle;
    text.querySelector('.nav-sub').textContent = step.railSub;
    row.append(disc, text);
    rail.appendChild(row);
  });
  // setupTitle breaks the action from the product name with a newline.
  const brand = $('#wizardBrandTitle');
  brand.textContent = '';
  t('setupTitle').split('\n').forEach((line, n) => {
    if (n > 0) brand.appendChild(document.createElement('br'));
    brand.appendChild(document.createTextNode(line));
  });
  $('#wizardError').textContent = '';
  $('#wizardBack').textContent = t('commonBack');
  $('#wizardBack').classList.toggle('hidden', wizard.i === 0);
  $('#wizardNext').textContent = s.nextLabel || t('commonNext');
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
  const intro = readOnlyRow(t('deviceServicePage'), t('setupServiceHelp'), '');
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
    const row = readOnlyRow(setupText(name), setupText('Checking…'), '');
    const span = row.querySelector('span');
    row._render = (granted, needed, adbHint) => {
      const ok = granted === true;
      row.querySelector('.name').textContent = setupText(name);
      // The device has no screen for the grant: the adb command stands in
      // for the button, and the row is not an error nobody can fix.
      const urgent = needed && !adbHint;
      row.querySelector('.desc').textContent =
        setupText(granted == null ? 'Status unavailable.' : ok ? held : adbHint || (needed ? missing : idle));
      span.textContent = granted == null ? '' : ok ? setupText("Granted")
        : adbHint ? setupText("Not offered") : needed ? setupText("Missing") : setupText("Not granted");
      span.style.cssText = 'white-space:nowrap; color:'
        + (ok ? 'var(--ok)' : urgent ? 'var(--error)' : 'var(--muted)');
      row.querySelector('button')?.remove();
      if (ok || granted == null || adbHint) return;
      const btn = document.createElement('button');
      btn.className = 'btn-ghost';
      btn.textContent = setupText("Grant on device");
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
  const row = readOnlyRow(t('setupRestore'),
    setupText("Import a configuration exported from Kiosk Satellite and skip the rest of this wizard."), '');
  row.querySelector('span').remove();
  const file = document.createElement('input');
  file.type = 'file';
  file.accept = '.json,application/json';
  file.hidden = true;
  const btn = document.createElement('button');
  btn.className = 'btn-ghost';
  btn.textContent = t('commonImport');
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
    wizardShowError(wizFail(setupText("Not a backup file"), setupText("That file is not valid JSON.")));
    return;
  }
  if (!config || config.kind !== 'kiosk-satellite-config') {
    wizardShowError(wizFail(setupText("Not a backup file"),
      setupText("Export a configuration from the Settings tab of a set-up Kiosk Satellite.")));
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
  btn.textContent = setupText("Importing…");
  try {
    // On the password screen the import runs authenticated, so the typed
    // password is minted first. needPassword overrides a lingering token
    // deliberately: the device says no password exists, so any token the
    // browser still holds is from a previous life of the device (wiped and
    // being set up again) and would only 401.
    if (!state.token || wizard.needPassword) {
      const password = $('#wzPassword') ? $('#wzPassword').value : '';
      if (password.length < 4) {
        throw wizFail(setupText("Set the admin password first"),
          setupText("Type an admin password above (at least 4 characters), then import the backup."));
      }
      const res = await fetch('api/setup/password', { method: 'POST', body: JSON.stringify({ password }) });
      const out = await res.json();
      if (!res.ok) throw wizFail(setupText("Could not set the password"), out.error || '');
      saveToken(out.token);
    }
    const res = await api(
      `/api/config/import?adoptIdentity=${opts.adopt ? 1 : 0}&importLocalStorage=${opts.local ? 1 : 0}`,
      { method: 'POST', body: JSON.stringify(config) });
    const out = await res.json();
    if (!res.ok) throw wizFail(setupText("Import failed"), out.error ? setupImportError(out.error) : setupText("The file could not be applied."));
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
    btn.textContent = t('commonImport');
  }
}

// The Voice Satellite step: whether Home Assistant runs the integration
// (then the migration is offered), its pipelines and the chosen engine's
// wake words for a new satellite's basics. Read once, when the step shows.
const WIZ_ENGINES = [
  ['vswakeword', 'vsWakeWord'], ['microwakeword', 'microWakeWord'], ['openwakeword', 'openWakeWord'],
];

async function wizardLoadVoice() {
  // The integration runs in a dashboard, which a device without a screen
  // never shows, so there is nothing to migrate from.
  const [detected, pipelines] = await Promise.all([
    isHeadless() ? null : cmd('haDetectVoiceSatellite', {}).catch(() => null),
    cmd('voicePipelines', {}).catch(() => null),
  ]);
  wizard.vsInstalled = detected?.ok === true && detected.data === true;
  wizard.pipelines = pipelines?.ok ? pipelines.data?.pipelines || [] : [];
  wizard.preferredPipeline = pipelines?.ok ? pipelines.data?.preferred || null : null;
  await wizardLoadWakeWords();
}

async function wizardLoadWakeWords() {
  const r = await cmd('voiceWakeWordChoices', { engine: wizard.engine }).catch(() => null);
  wizard.wakeWords = r?.ok && Array.isArray(r.data) ? r.data : [];
  if (!wizard.wakeWords.some((w) => w.id === wizard.wakeWord)) wizard.wakeWord = wizard.wakeWords[0]?.id || '';
  wizardRender();
}

function wizardSelectField(card, title, desc, options, value, onChange) {
  const label = document.createElement('label');
  label.className = 'form-field';
  // Fields after the first sit a gap below the one before, as the device's.
  if (card.childElementCount) label.style.marginTop = '18px';
  const name = document.createElement('span');
  name.textContent = title;
  const select = document.createElement('select');
  // The admin's dropdown box; the label's own gap spaces it.
  select.className = 'field';
  select.style.marginBottom = '0';
  for (const [v, text] of options) {
    const option = document.createElement('option');
    option.value = v;
    option.textContent = text;
    select.appendChild(option);
  }
  select.value = value;
  select.addEventListener('change', () => onChange(select.value));
  label.append(name, select);
  const help = document.createElement('div');
  help.className = 'desc';
  help.textContent = desc;
  card.append(label, help);
}

function wizardVoiceBasics(b) {
  if (wizard.vsInstalled === true) {
    const found = wizardCard(b, true);
    const row = readOnlyRow(
      setupText(wizard.migrated
        ? 'Migrated from the Voice Satellite integration'
        : 'Voice Satellite integration found'),
      setupText(wizard.migrated
        ? 'This kiosk takes over its satellite\'s settings.'
        : 'Voice Satellite now runs inside Kiosk Satellite. Migrate to keep the wake words, assistant and look of one of the integration\'s satellites instead of starting fresh.'),
      '');
    row.querySelector('span').remove();
    if (!wizard.migrated) {
      const btn = document.createElement('button');
      btn.className = 'btn-primary';
      btn.textContent = setupText('Migrate');
      btn.addEventListener('click', async () => {
        if (await openVsMigrationWizard({ onboarding: true })) {
          wizard.migrated = true;
          wizardRender();
        }
      });
      row.appendChild(btn);
    }
    found.appendChild(row);
  }
  if (wizard.migrated) return;
  const card = wizardCard(b);
  if (wizard.vsInstalled === null) {
    const wait = document.createElement('div');
    wait.style.cssText = 'padding:24px; text-align:center; color:var(--muted)';
    wait.textContent = '…';
    card.appendChild(wait);
    return;
  }
  const preferred = setupText('Preferred');
  wizardSelectField(card, setupText('Assistant'), setupText('The Assist pipeline that answers the wake word.'),
    [['preferred', wizard.preferredPipeline ? `${preferred} (${wizard.preferredPipeline})` : preferred],
      ...wizard.pipelines.map((name) => [name, name])],
    wizard.pipeline, (v) => { wizard.pipeline = v; });
  wizardSelectField(card, setupText('Wake word engine'), setupText('The engine that listens for the wake word.'),
    WIZ_ENGINES, wizard.engine, (v) => {
      wizard.engine = v;
      wizardLoadWakeWords();
    });
  wizardSelectField(card, setupText('Wake word'), setupText('The word that starts a voice command.'),
    wizard.wakeWords.map((w) => [w.id, w.phrase]), wizard.wakeWord, (v) => { wizard.wakeWord = v; });
}

function wizardLanguageRow(body) {
  const card = wizardCard(body);
  const label = document.createElement('label');
  label.className = 'form-field';
  const title = document.createElement('span');
  title.textContent = t('settingUiLanguageTitle');
  const select = document.createElement('select');
  select.id = 'wzLanguage';
  select.className = 'field';
  select.style.marginBottom = '0';
  for (const language of wizard.languages || []) {
    const option = document.createElement('option');
    option.value = language.value;
    option.textContent = language.label;
    select.appendChild(option);
  }
  select.value = messageLanguage();
  label.append(title, select);
  const help = document.createElement('div');
  help.className = 'desc';
  help.textContent = t('settingUiLanguageDescription');
  card.append(label, help);
  select.addEventListener('change', async () => {
    const previous = messageLanguage();
    select.disabled = true;
    const next = $('#wizardNext');
    const wasDisabled = next.disabled;
    next.disabled = true;
    try {
      const res = await fetch('api/setup/language', {
        method: 'POST', headers: {'Content-Type':'application/json',
          ...(state.token ? {Authorization: 'Bearer ' + state.token} : {})},
        body: JSON.stringify({language: select.value}),
      });
      if (!res.ok) throw new Error(t('commonSaveFailed'));
      const result = await res.json();
      // Keep unsaved credentials and the name when rebuilding translated labels.
      const drafts = ['wzDeviceName', 'wzPassword'].map(id => [id, document.getElementById(id)?.value]);
      setLanguagePreference(result.language);
      wizard.steps = wizardSteps();
      wizardRender();
      for (const [id, value] of drafts) {
        if (value !== undefined) document.getElementById(id).value = value;
      }
      wizardApplyTheme(document.documentElement.dataset.theme || 'light');
      $('#wzLanguage')?.focus({preventScroll:true});
    } catch (_) {
      select.value = previous;
      wizardShowError(new Error(t('commonSaveFailed')));
    } finally {
      select.disabled = false;
      next.disabled = wasDisabled;
    }
  });
}

// The Permissions step of a device without a screen: the grants it needs,
// each with the adb command that gives it, read live from the device.
function wizardHeadlessGrants(b) {
  const lead = document.createElement('div');
  lead.style.cssText = 'color:var(--muted); font-size:13px; line-height:1.5; padding:0 6px 14px;';
  lead.textContent = setupText('This device has no screen, so Android cannot ask for these on it. Give each one over adb, then finish here.');
  b.appendChild(lead);
  const list = wizardCard(b, true);
  const spans = {};
  const descs = {};
  const specs = permissionSpecs((k) => k !== 'btproxy.enabled' && k !== 'location.enabled', () => 'native', true)
    .filter((spec) => ['microphone', 'batteryUnrestricted', 'hardwareButtons'].includes(spec.key));
  for (const spec of specs) {
    const row = readOnlyRow(deviceText(spec.name), deviceText(adbHint(spec)), '\u2026');
    row.querySelector('.desc').style.userSelect = 'all';
    spans[spec.key] = row.querySelector('span');
    descs[spec.key] = [spec, row.querySelector('.desc')];
    list.appendChild(row);
  }
  const refresh = async () => {
    const p = {};
    try { Object.assign(p, (await cmd('getSystemPermissions')).data || {}); } catch (_) {}
    try {
      const b = (await cmd('getHardwareButtons')).data;
      p.hardwareButtons = b?.listening === true;
      p.hardwareButtonsOn = b?.switchedOn === true;
    } catch (_) {}
    for (const [spec, desc] of Object.values(descs)) desc.textContent = deviceText(adbHint(spec, p));
    for (const [key, span] of Object.entries(spans)) {
      const ok = p[key] === true;
      span.textContent = ok ? setupText('Granted') : setupText('Not granted');
      span.style.cssText = 'white-space:nowrap; color:' + (ok ? 'var(--ok)' : 'var(--error)');
    }
  };
  refresh();
  const timer = setInterval(() => {
    if (!list.isConnected) { clearInterval(timer); return; }
    refresh();
  }, 3000);
}

export function wizardSteps() {
  const steps = [];
  // The same first page as the device wizard, always: the admin password
  // where one is still needed, the restore path, and the service the whole
  // kiosk rides on, introduced where the kiosk is born rather than
  // discovered later as a notification. The Connect step is then only the
  // Home Assistant connection, on both surfaces.
  steps.push({
    railTitle: t('setupWelcome'), railSub: t('setupRemoteHeading'),
    title: t('remoteWelcomeTitle'),
    lead: wizard.needPassword
      ? t('remoteWelcomePassword')
      : t('remoteWelcomeReady'),
    body: (b) => {
      wizardLanguageRow(b);
      // The device name, seeded with what the device calls itself
      // (the model, until someone names it): the ESPHome node name is
      // taken from it at the server's first start, so a name given here
      // reads as ks-kitchen-tablet in Home Assistant rather than a
      // generated kiosk-satellite-<id>.
      const dev = wizardCard(b);
      const nameField = wizardField(dev, 'wzDeviceName', 'text', t('settingDeviceNameTitle'));
      nameField.value = wizard.deviceName || '';
      const note = document.createElement('div');
      note.style.cssText = 'color:var(--muted); font-size:12.5px; line-height:1.5; margin-top:-4px';
      note.textContent = t('setupDeviceNameHelp');
      dev.appendChild(note);
      wizardHeading(b, t('setupRemoteHeading'));
      // Always a field: with a password already set (on the tablet, or by
      // an earlier pass through this step) it changes it, and an empty
      // field keeps it.
      wizardField(wizardCard(b), 'wzPassword', 'password', wizard.needPassword
        ? t('remoteInitialPassword')
        : t('remoteNewPassword'));
      wizardHeading(b, t('setupRestoreHeading'));
      wizardRestoreCard(b);
      // A device without a screen takes its grants over adb, on the
      // Permissions step.
      if (!isHeadless()) {
        wizardHeading(b, t('setupServicePermissions'));
        wizardServiceCard(b);
      }
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
      if (password.length < 4) throw wizFail(t('setupPasswordShort'), t('setupPasswordMinimum'));
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
          throw wizFail(setupText("A password is already set"),
            setupText("Log in with the password set on the tablet to continue here. Reloading…"));
        }
        throw wizFail(setupText("Could not set the password"), out.error || '');
      }
      saveToken(out.token);
    },
  });
  steps.push({
    railTitle: t('setupConnect'), railSub: t('setupConnectSummary'),
    title: t('setupConnectHeading'),
    lead: t('setupConnectLead'),
    nextLabel: t('setupValidateContinue'),
    body: (b) => {
      const card = wizardCard(b);
      wizardField(card, 'wzUrl', 'url', 'https://homeassistant.local:8123');
      wizardField(card, 'wzToken', 'password', t('settingHaTokenTitle'));
    },
    next: async () => {
      const url = $('#wzUrl').value.trim(), token = $('#wzToken').value.trim();
      if (!url) throw wizFail(t('setupEnterBaseUrl'),
        t('setupBaseUrlHelp'));
      if (!token) throw wizFail(t('setupEnterToken'),
        t('setupEnterTokenHelp'));
      const patch = await api('/api/settings', { method: 'PATCH',
        body: JSON.stringify({ 'ha.url': url, 'ha.token': token }) });
      const pout = await patch.json();
      if ((pout.rejected || []).includes('ha.url')) {
        throw wizFail(t('setupInvalidBaseUrl'),
          t('baseUrlPath'));
      }
      const check = await (await api('/api/commands/haCheckConnection', { method: 'POST', body: '{}' })).json();
      if (!check.ok) throw wizConnectFail(check.error || '');
      wizard.base = url.replace(/\/$/, '');
      // No dashboard on a device without a screen.
      if (isHeadless()) return;
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
      // The kiosk lands on a single view: default to the first
      // dashboard's first view, ready for the Dashboard step's picker.
      const dashboards = await loadDashboards();
      const first = dashboards?.[0];
      wizard.dashboardPath ??= first
        ? (first.views.length ? `${first.path}/${first.views[0].route}` : first.path)
        : null;
    },
  });
  if (!isHeadless()) steps.push({
    railTitle: t('setupDashboard'), railSub: t('setupDashboardSummary'),
    title: setupText('Choose a dashboard'),
    lead: setupText('This is what the kiosk will show when it starts.'),
    body: (b) => {
      // The whole picker inline, searchable, the step's one task.
      const card = wizardCard(b);
      card.appendChild(dashboardPicker({
        value: wizard.dashboardPath,
        onPick: (path) => { wizard.dashboardPath = path; },
      }));
    },
    next: async () => {
      if (!wizard.dashboardPath) throw wizFail(setupText('Select a dashboard'),
        setupText('Choose the dashboard the kiosk will display. You can change it later in Settings.'));
    },
  });
  steps.push({
    railTitle: 'Voice Satellite', railSub: t('setupRecommendedSummary'),
    title: 'Voice Satellite',
    lead: setupText('Turn this kiosk into a voice assistant for Home Assistant. Everything can be changed later.'),
    body: (b) => {
      const toggleRow = wizardToggleRow;
      const voice = wizardCard(b, true);
      voice.appendChild(toggleRow(setupText('Enable Voice Satellite'),
        setupText('Turns this kiosk into a voice assistant for Home Assistant through its ESPHome server.'),
        wizard.voice, false, () => { wizard.voice = !wizard.voice; wizardRender(); }));
      if (wizard.voice) {
        if (wizard.vsInstalled === undefined) {
          wizard.vsInstalled = null;
          wizardLoadVoice();
        }
        wizardVoiceBasics(b);
        // Where the kiosk turns up once set up, the device wizard's hint.
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
        hintText.textContent = setupText('After setup, add this kiosk in Home Assistant under Settings, Devices & services, where it shows up as discovered. If Home Assistant had it before, it asks there for the new Encryption key from the ESPHome page.');
        hint.appendChild(hintText);
        b.appendChild(hint);
      }
      // The recommendations are for a kiosk on the wall.
      if (isHeadless()) return;
      const master = wizardCard(b, true);
      const all = WIZ_OPTIONAL.every(([k]) => wizard.rec[k]);
      master.appendChild(toggleRow(setupText('Apply all recommended settings'),
        setupText('The settings that suit a kiosk on the wall.'),
        all, false, () => {
          const next = !all;
          WIZ_OPTIONAL.forEach(([k]) => { wizard.rec[k] = next; });
          wizardRender();
        }));
      const list = wizardCard(b, true);
      WIZ_OPTIONAL.forEach(([key, label]) => {
        if (!wizard.voice && key === 'wake_word.background') return;
        list.appendChild(toggleRow(setupText(label), '', wizard.rec[key], false, () => {
          wizard.rec[key] = !wizard.rec[key];
          wizardRender();
        }));
      });
    },
    next: async () => {},
  });
  steps.push({
    railTitle: t('setupPermissions'), railSub: t('setupPermissionsSummary'),
    title: t('setupPermissions'),
    lead: setupText("Android asks for these on the tablet itself. Walk over and accept the prompts, then finish here."),
    nextLabel: t('commonFinish'),
    body: (b) => {
      if (isHeadless()) {
        wizardHeadlessGrants(b);
        return;
      }
      const background = wizard.voice && wizard.rec['wake_word.background'];
      const bootStart = wizard.rec['kiosk.start_on_boot'];
      const list = wizardCard(b, true);
      // Status to the right of each row, exactly as the settings pages
      // show grants: green Granted / red Not granted, read live from the
      // device and re-read after the prompts run.
      const statusSpans = {};
      const addRow = (key, name, desc) => {
        const row = readOnlyRow(setupText(name), setupText(desc), '\u2026');
        statusSpans[key] = row.querySelector('span');
        list.appendChild(row);
      };
      addRow('microphone', "Microphone",
        "Voice Satellite and the intercom need microphone access");
      // The Kiosk Satellite Service's two, on every install: its
      // notification, and the exemption that keeps it running.
      addRow('notification', "Notifications",
        background
          ? "Allows the Kiosk Satellite Service's ongoing notification, which says what it is keeping alive and when the kiosk is listening."
          : "Allows the Kiosk Satellite Service's ongoing notification, which says what it is keeping alive.");
      addRow('batteryUnrestricted', "Unrestricted battery",
        "Allows the Kiosk Satellite Service to run in the background without being paused or killed.");
      addRow('displayOverOtherApps', "Display over other apps",
        bootStart
          ? "Lets Kiosk Satellite come back after a crash and start when your device boots."
          : "Lets Kiosk Satellite come back on screen after a crash.");
      addRow('writeSettings', "Screen brightness",
        "Allows Kiosk Satellite to set the panel's actual brightness (modify system settings).");
      addRow('deviceAdmin', "Screen control",
        "Allows Kiosk Satellite to turn the screen off on request (device admin).");
      const refreshStatus = async () => {
        try {
          const res = await (await api('/api/commands/getSystemPermissions', { method: 'POST', body: '{}' })).json();
          const p = res.data || {};
          for (const [key, span] of Object.entries(statusSpans)) {
            const ok = !!p[key];
            span.textContent = ok ? setupText("Granted") : setupText("Not granted");
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
      btn.textContent = setupText("Grant permissions on the device");
      btn.addEventListener('click', async () => {
        btn.disabled = true;
        btn.style.opacity = '.6';
        btn.textContent = setupText("Requesting on the device…");
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
        btn.textContent = setupText("Permissions requested on the device");
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
      const chosen = isHeadless() ? {} : { ...wizard.rec };
      // Background listening means nothing without the voice satellite.
      if (!wizard.voice) delete chosen['wake_word.background'];
      if (wizard.voice) {
        chosen['esphome.enabled'] = true;
        if (!wizard.migrated) {
          // The wake word goes to Home Assistant with the kiosk's first
          // configuration, the Assistant once its selects are there.
          const phrase = wizard.wakeWords.find((w) => w.id === wizard.wakeWord)?.phrase;
          chosen['voice.wake_word_engine'] = wizard.engine;
          chosen['voice.wake_words'] = JSON.stringify([wizard.wakeWord]);
          chosen['voice.pending_selects'] = JSON.stringify(
            phrase ? { pipeline: wizard.pipeline, wake_word: phrase } : { pipeline: wizard.pipeline });
        }
        chosen['voice.enabled'] = true;
      } else if (wizard.migrated) {
        // Migrated, then switched off again: the migration turned it on.
        chosen['voice.enabled'] = false;
      }
      await api('/api/settings', { method: 'PATCH', body: JSON.stringify(chosen) });
      // Setting the start URL is what flips the device to configured; the
      // kiosk on the wall navigates to the chosen dashboard view on its own.
      // Without a screen there is no dashboard, and the Home Assistant
      // address alone marks the device as set up.
      const startUrl = isHeadless()
        ? `${wizard.base}/`
        : `${wizard.base}/${wizard.dashboardPath}`;
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
    applyHeadless(setup?.headless);
    wizard.deviceName = setup?.deviceName || '';
    wizard.languages = setup?.languages || [{value:'en', label:'English'}, {value:'es', label:'Español'}];
    setLanguagePreference(setup?.language);
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
  wizard.i = Math.max(0, wizard.i - 1);
  wizardRender();
});
