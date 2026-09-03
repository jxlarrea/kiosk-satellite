import { api, showView } from './core.js';
import { refreshUpdateBadge } from './device.js';
import { loadConsole } from './logs.js';
import { initOverview } from './overview.js';
import { loadScreenshot, loadViewJump } from './panels.js';
import { loadSettings } from './settings.js';
import { showTab } from './tabs.js';
import { showImportPending, startWizard } from './wizard.js';
import { applyInfo, connectWs } from './ws.js';

/* ---- Boot ---- */
export async function start() {
  // An unconfigured device continues into the wizard, not the app - the
  // login (with the password the device wizard set) was just the door.
  //
  // Asked fresh on every entry rather than latched once at boot. A 401
  // anywhere in the wizard logs the page out, and the login that follows
  // came back through here: with a one-shot flag that second pass fell
  // through and opened the full settings UI of a device nobody had set up.
  let setup = null;
  try { setup = await (await fetch('api/setup/status')).json(); } catch (_) {}
  if (setup?.setupNeeded) {
    if (setup.importPending) { showImportPending(); return; }
    startWizard({ needPassword: false });
    return;
  }
  // Build the whole app behind the splash and reveal it ready: quick-control
  // tiles, brightness, settings and panels all populated. Showing it earlier
  // put a page of dead buttons and a parked slider on screen first.
  const info = await (await api('/api/info')).json();
  applyInfo(info, info.currentUrl);
  refreshUpdateBadge();
  await loadSettings();
  await loadConsole();
  await initOverview();
  loadViewJump();
  // Whatever the URL asked for, now that the panels it needs exist.
  showTab(decodeURIComponent(location.hash.slice(1)) || 'dashboard', { push: false });
  showView('app');
  // The screenshot is the one thing not worth holding the splash for: the
  // tablet reads back and encodes its screen, and the panel has its own
  // placeholder. It lands into the visible page.
  loadScreenshot();
  // No auto-refresh by default: each capture makes the tablet read back
  // and encode its screen, and an admin tab left open would otherwise poll
  // the device forever. One shot on load plus Refresh is the deal, which
  // is also why the capture can afford to be high-quality. Live is the
  // Overview's explicit opt-in, and only while the page is in view.
  connectWs();
}
/* ---- Onboarding wizard ----------------------------------------------
   The remote twin of the device's five-step setup. An unconfigured device
   serves this passwordless; minting the admin password is the first step
   (skipped when the device wizard already set one, then it appears after
   login instead). */
export const WIZ_LOCKED = [
  ['web.microphone', 'Microphone access'],
  ['wake_word.enabled', 'Native wake word detection'],
];
export const WIZ_OPTIONAL = [
  ['browser.auto_reload_on_error', 'Auto-reload on error'],
  ['browser.pull_to_refresh', 'Pull to refresh'],
  ['browser.pull_to_refresh_clear_cache', 'Clear cache when pulling to refresh'],
  ['browser.allow_mixed_content', 'Allow mixed content'],
  ['browser.ignore_ssl_errors', 'Ignore SSL errors'],
  ['web.autoplay', 'Autoplay audio and video'],
  ['kiosk.start_on_boot', 'Start on boot'],
  ['screen.keep_on', 'Keep screen on'],
  ['wake_word.background', 'Keep listening in the background'],
  ['remote.enabled', 'Remote management'],
  ['browser.disable_suspend', 'Keep connected in the background'],
  ['browser.freeze_on_screensaver', 'Pause dashboard during screensaver'],
  ['browser.ws_filter', 'Filter dashboard updates'],
];
export const wizard = {
  steps: [], i: 0, needPassword: false,
  vsDetected: false,
  rec: Object.fromEntries(WIZ_OPTIONAL.map(([k]) => [k, true])),
  satellites: [], satellite: null,
  dashboards: [], dashboard: null, dashboardView: '', dashboardViews: null,
};
