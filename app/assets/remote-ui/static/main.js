import { start } from './app.js';
import { $, login, logout, showView, state } from './core.js';
import { showImportPending, startWizard } from './wizard.js';

$('#loginBtn').addEventListener('click', login);
$('#password').addEventListener('keydown', (e) => { if (e.key === 'Enter') login(); });
$('#logoutBtn').addEventListener('click', logout);

// Only a real 401 (handled inside api()) logs out. A transient network error
// at boot must NOT, just log it and retry behind the splash - a 401 clears
// the token on its way out, which is what ends the retrying.
const boot = () => start().catch((e) => {
  console.warn('start failed', e);
  if (state.token) setTimeout(boot, 3000);
});
(async () => {
  let setup = null;
  try { setup = await (await fetch('api/setup/status')).json(); } catch (_) {}
  if (setup?.setupNeeded) {
    // An import is finishing on the device (permission prompts); a reload
    // here must keep saying that, not show an empty wizard.
    if (setup.importPending) { showImportPending(); return; }
    if (setup.passwordNeeded) { startWizard({ needPassword: true }); return; }
    // A password exists (set in the device wizard's first step): log in
    // first. start() asks again and continues the setup here.
  }
  if (state.token) boot(); else showView('login');
})();
