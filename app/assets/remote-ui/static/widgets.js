import { cmd } from './core.js';

/* ---- Dashboard ---- */
// The one modal scaffold: backdrop, card, fixed title, a body that scrolls
// its overflow, and a fixed footer for the actions. onDismiss (optional)
// Keeps every .edge-fade container's two mask lengths honest: an edge that
// still hides content gets its fade, one scrolled to the end goes crisp.
// One capturing scroll listener covers containers created at any time; the
// mutation observer catches content appearing or disappearing without a
// scroll (a modal opening, rows re-rendering), batched to one pass per
// frame since it reads layout.
export function updateEdgeFade(el) {
  const max = el.scrollHeight - el.clientHeight;
  // Proportional through the last 28px of travel, saturated at 28 the
  // rest of the way: mid-list scrolling writes the same values, which
  // the guard below turns into no style work at all.
  const top = Math.max(0, Math.min(28, el.scrollTop));
  const bottom = Math.max(0, Math.min(28, max - el.scrollTop));
  setEdgeFadeVar(el, '--fade-top', top);
  setEdgeFadeVar(el, '--fade-bottom', bottom);
}
export function setEdgeFadeVar(el, name, px) {
  const value = px > 0 ? px.toFixed(1) + 'px' : '0px';
  if (el.style.getPropertyValue(name) !== value) {
    el.style.setProperty(name, value);
  }
}
export let edgeFadeQueued = false;
export function queueEdgeFades() {
  if (edgeFadeQueued) return;
  edgeFadeQueued = true;
  requestAnimationFrame(() => {
    edgeFadeQueued = false;
    document.querySelectorAll('.edge-fade').forEach(updateEdgeFade);
  });
}
document.addEventListener('scroll', (e) => {
  if (e.target instanceof Element && e.target.classList.contains('edge-fade')) {
    updateEdgeFade(e.target);
  }
}, true);
// Class changes too (but not style: the fade writes styles itself, and
// observing them would re-trigger the observer forever): visibility here
// is toggled by classes, like the sidebar swapping its nav for search
// results, and a container measured while hidden reports no overflow.
new MutationObserver(queueEdgeFades).observe(document.body, {
  childList: true, subtree: true,
  attributes: true, attributeFilter: ['class'],
});
window.addEventListener('resize', queueEdgeFades);
queueEdgeFades();

// runs on a backdrop tap; pass it for pickers, omit it for alerts that
// must be answered with a button.
export function modalShell({ title, width, onDismiss }) {
  const back = document.createElement('div');
  back.className = 'modal-back';
  const card = document.createElement('div');
  card.className = 'card modal-card';
  if (width) card.style.maxWidth = width + 'px';
  const head = document.createElement('h3');
  head.className = 'modal-title';
  head.textContent = title;
  const body = document.createElement('div');
  body.className = 'modal-body edge-fade';
  const foot = document.createElement('div');
  foot.className = 'modal-foot';
  card.append(head, body, foot);
  back.appendChild(card);
  document.body.appendChild(back);
  if (onDismiss) {
    back.addEventListener('click', (e) => { if (e.target === back) onDismiss(); });
  }
  return { back, card, head, body, foot, close: () => back.remove() };
}

// Styled stand-in for alert()/confirm(), on the modal scaffold. Resolves to
// the label of the pressed button; no backdrop dismiss, an alert is answered.
export function messageBox({ title, message, buttons = ['OK'] }) {
  return new Promise((resolve) => {
    const { back, body, foot } = modalShell({ title });
    const p = document.createElement('p');
    p.textContent = message;
    p.style.cssText = 'margin:0; color:var(--muted); font-size:14px; line-height:1.55; white-space:pre-line;';
    body.appendChild(p);
    buttons.forEach((label, i) => {
      const btn = document.createElement('button');
      btn.textContent = label;
      btn.className = i === buttons.length - 1 ? 'btn-primary' : 'btn-ghost';
      btn.addEventListener('click', () => { back.remove(); resolve(label); });
      foot.appendChild(btn);
    });
  });
}

// Bound to every tile, including the quick-control ones whose command
// changes with the device's state (the camera tile drops its command
// altogether while its own picker owns the click), so the command is read
// at click time, never captured here.
document.querySelectorAll('.action.tile, .action[data-cmd]').forEach((b) =>
  b.addEventListener('click', async () => {
    if (!b.dataset.cmd) return;
    // Surface refusals, with a retry loop: the common case is "Screen off"
    // pending its one-tap device-admin grant on the tablet — approve there,
    // press Retry here.
    let res = await cmd(b.dataset.cmd).catch(() => null);
    while (res && res.ok === false && res.error) {
      const choice = await messageBox({
        title: b.textContent.trim(),
        message: res.error,
        buttons: ['Cancel', 'Retry'],
      });
      if (choice !== 'Retry') break;
      res = await cmd(b.dataset.cmd).catch(() => null);
    }
  }));
/* Camera grant notice: mirror of the device's row directly under "Enable
   camera", shown only while that switch is on and the camera permission is
   missing. Toggling the switch re-renders the tab (its dependants force a
   layout reload), so visibility follows the setting on its own. */
