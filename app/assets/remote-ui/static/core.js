import { start } from './app.js';
import { startWizard } from './wizard.js';

// A function declaration on purpose: several modules use $ at module top
// level and sit in import cycles with this one, and only hoisted function
// bindings are initialized before evaluation starts.
export function $(s) { return document.querySelector(s); }
export const state = { token: localStorage.getItem('ks_token'), ws: null };

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
  btn.title = `Theme: ${pref}`;
  btn.setAttribute('aria-label', `Theme: ${pref}`);
}
$('#themeBtn').addEventListener('click', () => {
  const order = ['light', 'dark', 'auto'];
  const pref = localStorage.getItem('ks_theme') || 'light';
  localStorage.setItem('ks_theme', order[(order.indexOf(pref) + 1) % order.length]);
  applyTheme();
});
themeMedia.addEventListener('change', applyTheme);
applyTheme();

export async function api(path, opts = {}) {
  const res = await fetch(path, {
    ...opts,
    headers: { ...(opts.headers || {}), Authorization: `Bearer ${state.token}` },
  });
  if (res.status === 401) { logout(); throw new Error('unauthorized'); }
  return res;
}
export const cmd = (name, params = {}) =>
  api(`/api/commands/${name}`, { method: 'POST', body: JSON.stringify(params) })
    .then((r) => r.json());

/* ---- Views ---- */
// Login, wizard and app are three full-page sections of one document, and
// exactly one of them is ever the page. Showing one without hiding the other
// two stacked them instead of replacing them: the wizard filled the screen
// and the settings UI of a not-yet-configured device sat right below it, one
// scroll away. Route every switch through here so that cannot happen again.
// Whether a gating setting's value satisfies a row's dependsOnValue, the
// device's SettingDef.dependsSatisfiedBy: a list means any of them (the
// Immich From date, which both Since and Timeframe want), a bare value
// means equality, and an absent one the common boolean switch.
export function dependsSatisfiedBy(value, want) {
  return Array.isArray(want) ? want.includes(value) : value === (want ?? true);
}

export function showView(which) {
  for (const id of ['splash', 'login', 'wizard', 'app']) {
    $(`#${id}`).classList.toggle('hidden', id !== which);
  }
}

/* ---- Auth ---- */
export async function login() {
  $('#loginError').textContent = '';
  const res = await fetch('/api/login', {
    method: 'POST', body: JSON.stringify({ password: $('#password').value }),
  });
  if (!res.ok) {
    // The throttle rejects even the right password; calling that "Invalid
    // password" convinces someone with a typo behind them that their real
    // password is broken, on every device they try next.
    $('#loginError').textContent = res.status === 429
      ? 'Too many attempts. Wait 5 minutes and try again.'
      : 'Invalid password';
    return;
  }
  state.token = (await res.json()).token;
  localStorage.setItem('ks_token', state.token);
  // Back on the splash while start() gathers the app's data, rather than
  // a login card that sits frozen with the password still in it.
  showView('splash');
  start();
}
export function logout() {
  state.token = null; localStorage.removeItem('ks_token');
  if (state.ws) { state.ws.onclose = null; state.ws.close(); state.ws = null; }
  showView('login');
  // A wiped or factory-fresh device has no password to log in with - its
  // login screen is a dead end (empty passwords never match, by design).
  // That is exactly when a stale browser token 401s: route back into the
  // wizard instead of stranding the user at login.
  fetch('api/setup/status').then((r) => r.json()).then((setup) => {
    if (setup && setup.setupNeeded && setup.passwordNeeded) {
      // Already on that wizard: put it back rather than rebuilding it, or
      // any stray 401 from the page it is showing restarts it in a loop.
      if ($('#wizard').dataset.needPassword === '1') { showView('wizard'); return; }
      startWizard({ needPassword: true });
    }
  }).catch(() => { /* no answer: the login screen is the safe place to wait */ });
}
