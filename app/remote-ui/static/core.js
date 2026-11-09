import { detachSocket, socketReady, socketRequest } from './transport.js';
import { start } from './app.js';
import { startWizard } from './wizard.js';
import { localizeSetting, setLanguagePreference, themeLabel, t } from './localization.js';

// A function declaration on purpose: several modules use $ at module top
// level and sit in import cycles with this one, and only hoisted function
// bindings are initialized before evaluation starts.
export function $(s) { return document.querySelector(s); }

// The path the page is served under: "/" from the tablet itself, a longer
// one behind a reverse proxy such as Home Assistant ingress (issue #850).
// The page keeps its "/api/..." paths as names, since the socket transport
// matches on them, and apiUrl() resolves one against this path only when
// it leaves the browser.
export const BASE = new URL('.', location.href).pathname;
export function apiUrl(path) {
  return path.startsWith('/api/') ? BASE + path.slice(1) : path;
}

// Behind a proxy every tablet shares the proxy's origin, so the login is
// kept per path there. One key would let each login overwrite the last.
// The plain key stays a fallback a proxy may set itself. From the tablet
// itself the key is unchanged.
const TOKEN_KEY = BASE === '/' ? 'ks_token' : `ks_token:${BASE}`;
export function saveToken(token) {
  state.token = token;
  localStorage.setItem(TOKEN_KEY, token);
}
function clearToken() {
  if (localStorage.getItem('ks_token') === state.token) localStorage.removeItem('ks_token');
  localStorage.removeItem(TOKEN_KEY);
  state.token = null;
}
export const state = {
  token: localStorage.getItem(TOKEN_KEY) ?? localStorage.getItem('ks_token'), ws: null,
};

// Controls retain their setting definitions between renders. Refresh their
// values in place so a page visit cannot leave other pages on old objects.
export function cacheSettings(definitions) {
  setLanguagePreference(definitions.find(setting => setting.key === 'ui.language')?.value);
  const existing = new Map((state.settings || []).map(setting => [setting.key, setting]));
  state.settings = definitions.map(setting => {
    setting = localizeSetting(setting);
    const cached = existing.get(setting.key);
    return cached ? Object.assign(cached, setting) : setting;
  });
  document.dispatchEvent(new CustomEvent('ks-settings-cached'));
  return state.settings;
}


/* ---- Theme ---- */
// Follows the OS by default; the header button cycles auto → dark → light and
// remembers. The head script applies the same choice before first paint.
export const themeMedia = matchMedia('(prefers-color-scheme: dark)');
// The button shows the *preference* (auto / dark / light), not the resolved
// theme, auto has its own face so "following the OS" stays visible.
export const THEME_ICONS = {
  auto: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="9"/><path d="M12 3a9 9 0 0 1 0 18z" fill="currentColor" stroke="none"/></svg>',
  dark: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>',
  light: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M4.9 4.9l1.4 1.4m11.4 11.4 1.4 1.4M2 12h2m16 0h2M4.9 19.1l1.4-1.4m11.4-11.4 1.4-1.4"/></svg>',
};
export function applyTheme() {
  // Light by default, matching the app; auto (follow the browser) is an
  // explicit choice on the toggle, not the starting point.
  const pref = localStorage.getItem('ks_theme') || 'light';
  const dark = pref === 'dark' || (pref === 'auto' && themeMedia.matches);
  document.documentElement.dataset.theme = dark ? 'dark' : 'light';
  const btn = $('#themeBtn');
  btn.innerHTML = THEME_ICONS[pref];
  btn.title = themeLabel(pref);
  btn.setAttribute('aria-label', btn.title);
}
$('#themeBtn').addEventListener('click', () => {
  const order = ['light', 'dark', 'auto'];
  const pref = localStorage.getItem('ks_theme') || 'light';
  localStorage.setItem('ks_theme', order[(order.indexOf(pref) + 1) % order.length]);
  applyTheme();
});
themeMedia.addEventListener('change', applyTheme);
applyTheme();

const SOCKET_READS = {
  '/api/info': 'info',
  '/api/settings': 'settings',
  '/api/console': 'console',
  '/api/logs': 'logs',
};
export async function api(path, opts = {}) {
  const response = await requestApi(path, opts);
  if (path === '/api/settings' && opts.method === 'PATCH') {
    const changes = JSON.parse(opts.body || '{}');
    if (Object.prototype.hasOwnProperty.call(changes, 'remote.tls')) {
      const result = await response.clone().json();
      if (response.ok && result.ok !== false && !result.rejected?.includes('remote.tls')) {
        const target = new URL(location.href);
        target.protocol = changes['remote.tls'] ? 'https:' : 'http:';
        // Behind a proxy the page is not on the tablet's own origin, so
        // switching this page's protocol would not reach the tablet.
        if (target.protocol !== location.protocol && BASE === '/') redirectAfterProtocolChange(target);
      }
    }
  }
  return response;
}

// The listener waits for active requests before changing protocol. A fixed
// delay can navigate too early when one of those requests is slow.
function redirectAfterProtocolChange(target) {
  const navigate = () => setTimeout(() => location.assign(target.href), 750);
  const current = state.ws;
  if (current?.readyState === WebSocket.OPEN) {
    current.addEventListener('close', navigate, { once: true });
    return;
  }
  // HTTP fallback: probe the old origin until its listener closes. Reading
  // the new origin here would hit browser mixed-content restrictions.
  void (async () => {
    for (;;) {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 1500);
      try {
        await fetch(apiUrl('/api/commands'), { method: 'HEAD', cache: 'no-store',
          headers: { Authorization: `Bearer ${state.token}` }, signal: controller.signal });
      } catch (error) {
        if (error.name !== 'AbortError') { navigate(); return; }
      } finally { clearTimeout(timer); }
      await new Promise(resolve => setTimeout(resolve, 250));
    }
  })();
}

async function requestApi(path, opts = {}) {
  if (socketReady() && opts.method === 'POST' && path.startsWith('/api/commands/')) {
    const result = await socketRequest({ type: 'command',
      name: path.slice('/api/commands/'.length), params: JSON.parse(opts.body || '{}') }, opts);
    return new Response(JSON.stringify(result), { headers: { 'content-type': 'application/json' } });
  }
  if (socketReady() && opts.method === 'PATCH' && path === '/api/settings') {
    const result = await socketRequest({ type: 'settings', values: JSON.parse(opts.body || '{}') }, opts);
    return new Response(JSON.stringify(result), { headers: { 'content-type': 'application/json' } });
  }
  // The reads the page makes at boot and on a tab visit ride the socket
  // too, so a connected page never opens an HTTP request for them.
  const read = SOCKET_READS[path];
  if (socketReady() && read && !opts.method) {
    const result = await socketRequest({ type: 'get', name: read }, opts);
    if (!result.ok) throw new Error(result.error || 'Device read failed');
    return new Response(JSON.stringify(result.data), { headers: { 'content-type': 'application/json' } });
  }
  const res = await fetch(apiUrl(path), {
    ...opts,
    headers: { ...(opts.headers || {}), Authorization: `Bearer ${state.token}` },
  });
  if (res.status === 401) { logout(); throw new Error('unauthorized'); }
  return res;
}
export async function cmd(name, params = {}, { timeoutMs = 0 } = {}) {
  const controller = new AbortController();
  const timer = timeoutMs > 0
    ? setTimeout(() => controller.abort(), timeoutMs) : null;
  try {
    const response = await api(`/api/commands/${name}`, {
      method: 'POST', body: JSON.stringify(params), signal: controller.signal,
    });
    return await response.json();
  } finally {
    if (timer !== null) clearTimeout(timer);
  }
}

/* ---- Views ---- */
// Login, wizard and app are three full-page sections of one document, and
// exactly one of them is ever the page. Showing one without hiding the other
// two stacked them instead of replacing them: the wizard filled the screen
// and the settings UI of a not-yet-configured device sat right below it, one
// scroll away. Route every switch through here so that cannot happen again.
// Whether a gating setting's value satisfies a row's dependsOnValue, the
// device's SettingDef.dependsSatisfiedBy: a list means any of them (the
// Immich From date, which both Since and Timeframe want), {gt} a number
// above it, {ne} anything but it (or anything outside a list, and with
// neStartsWith nothing that starts with that prefix), a bare value
// means equality, and an absent one the common boolean switch.
export function dependsSatisfiedBy(value, want) {
  if (want && typeof want === 'object' && typeof want.gt === 'number') {
    return typeof value === 'number' && value > want.gt;
  }
  if (want && typeof want === 'object' && 'ne' in want) {
    // A prefix none may start with either: each plugin player's pick.
    if (typeof want.neStartsWith === 'string' && typeof value === 'string'
      && value.startsWith(want.neStartsWith)) return false;
    return Array.isArray(want.ne) ? !want.ne.includes(value) : value !== want.ne;
  }
  return Array.isArray(want) ? want.includes(value) : value === (want ?? true);
}

// Whether a row's gates hold, given the definitions by key: the device's
// SettingsManager.visible(). Transitive, a dependency must hold and itself
// be shown, and a second gate (alsoDependsOn, the flip clock's night card
// color under both Night mode and the Flip style) must hold the same way.
// The chain ignores the `hidden` flag: a row may gate on a hidden
// bookkeeping flag (the media playlist rows on media_is_folder), while
// hidden rows themselves are simply never rendered.
export function depSatisfied(s, byKey) {
  const holds = (key, want) => {
    if (!key) return true;
    const dep = byKey[key];
    if (!dep) return true;
    return dependsSatisfiedBy(dep.value, want) && depSatisfied(dep, byKey);
  };
  return holds(s.dependsOn, s.dependsOnValue)
    && holds(s.alsoDependsOn, s.alsoDependsOnValue);
}

// The rows whose gates name `key`, either one: what a flip of that setting
// can reach directly.
export function gatedOn(all, key) {
  return all.filter((o) => o.dependsOn === key || o.alsoDependsOn === key);
}

export function paintLogin() {
  const heading = $('#loginHeading');
  const password = $('#password');
  const button = $('#loginBtn');
  const error = $('#loginError');
  if (heading) heading.textContent = t('setupRemoteHeading');
  if (password) {
    password.placeholder = t('settingRemotePasswordTitle');
    password.setAttribute('aria-label', password.placeholder);
  }
  if (button) button.textContent = t('remoteLogin');
  if (error?.dataset.messageId) error.textContent = t(error.dataset.messageId);
}

export function showView(which) {
  if (which === 'login') paintLogin();
  for (const id of ['splash', 'login', 'wizard', 'app']) {
    $(`#${id}`).classList.toggle('hidden', id !== which);
  }
}

/* ---- Auth ---- */
export async function login() {
  $('#loginError').textContent = '';
  delete $('#loginError').dataset.messageId;
  const res = await fetch(apiUrl('/api/login'), {
    method: 'POST', body: JSON.stringify({ password: $('#password').value }),
  });
  if (!res.ok) {
    // The throttle rejects even the right password; calling that "Invalid
    // password" convinces someone with a typo behind them that their real
    // password is broken, on every device they try next.
    $('#loginError').dataset.messageId = res.status === 429
      ? 'remoteLoginThrottled' : 'remoteInvalidPassword';
    paintLogin();
    return;
  }
  saveToken((await res.json()).token);
  // Back on the splash while start() gathers the app's data, rather than
  // a login card that sits frozen with the password still in it.
  showView('splash');
  start();
}
export function logout() {
  clearToken();
  detachSocket();
  document.dispatchEvent(new CustomEvent('ks-logout'));
  if (state.ws) { state.ws.onclose = null; state.ws.close(); state.ws = null; }
  showView('login');
  // A wiped or factory-fresh device has no password to log in with - its
  // login screen is a dead end (empty passwords never match, by design).
  // That is exactly when a stale browser token 401s: route back into the
  // wizard instead of stranding the user at login.
  fetch('api/setup/status').then((r) => r.json()).then((setup) => {
    if (!$('#login').classList.contains('hidden') && setup?.language !== undefined) {
      setLanguagePreference(setup.language);
      paintLogin();
    }
    if (setup && setup.setupNeeded && setup.passwordNeeded) {
      // Already on that wizard: put it back rather than rebuilding it, or
      // any stray 401 from the page it is showing restarts it in a loop.
      if ($('#wizard').dataset.needPassword === '1') { showView('wizard'); return; }
      startWizard({ needPassword: true });
    }
  }).catch(() => { /* no answer: the login screen is the safe place to wait */ });
}
