import { isHeadless } from './headless.js';
import { t, voiceText } from './localization.js';
import { cmd, state } from './core.js';
import { readOnlyRow } from './device.js';
import { messageBox, modalShell, showToast } from './widgets.js';
import { watchUpdates } from './live.js';

/* ---- Companion screens ----
   The Companion screens page of Voice Satellite, as on the device: the
   switch (the generic row render() draws), then the kiosk this screen
   shows and an invitation waiting here, or the companion screens of this
   kiosk and a way to add one. With companion screen mode on, the rows of
   the Voice Satellite page that configure a satellite of its own hide in
   place: the switch never re-renders the page. */

// The Conversation rows the kiosk whose session it is decides.
const COMPANION_HIDDEN_SETTINGS = ['voice.answer_linger', 'voice.results_linger', 'voice.announcement_linger'];
// The Voice Satellite page's rows and pages a companion screen has no use
// for.
const COMPANION_HIDDEN_ROWS = ['voice.mute', 'wake_word.background', 'wake_word.return_to_background'];
const COMPANION_HIDDEN_PAGES = ['Wake Word', 'Assistant', 'Realtime', 'Chimes', 'Wake word diagnostics'];

function settingValue(key) {
  return (state.settings || []).find((s) => s.key === key)?.value;
}

export function companionScreenOn() {
  // A device without a screen only invites companion screens.
  return !isHeadless() && settingValue('voice.enabled') === true && settingValue('voice.companion_mode') === true;
}

export function linkText(stateName) {
  switch (stateName) {
    case 'connected': return voiceText('Connected');
    case 'connecting': return voiceText('Connecting');
    case 'refused': return voiceText('Removed');
    default: return voiceText('Not connected');
  }
}

function row(name, desc, value = '') {
  return readOnlyRow(name, desc, value, false);
}

function word(rowEl, text, color) {
  const span = rowEl.lastElementChild;
  span.textContent = text;
  span.style.cssText = `white-space:nowrap; font-weight:500; color:${color}`;
}

function button(label, className, onClick) {
  const b = document.createElement('button');
  b.className = className;
  b.textContent = label;
  b.style.flexShrink = '0';
  b.addEventListener('click', onClick);
  return b;
}

function heading(text) {
  const h = document.createElement('h2');
  h.className = 'card-title';
  h.textContent = text;
  return h;
}

async function run(command, params = {}) {
  const r = await cmd(command, params).catch((e) => ({ ok: false, error: e?.message }));
  if (!r?.ok) {
    showToast({ title: voiceText('Companion screens'), message: voiceText(`${r?.error || ''}`), kind: 'error' });
  }
  return r;
}

/* Hides what a companion screen has no use for, or brings it back, in
   place on the Voice Satellite tab. */
export function syncCompanionVs(root) {
  const tab = root.closest('.tab') || root;
  const on = companionScreenOn();
  for (const key of COMPANION_HIDDEN_ROWS) {
    tab.querySelector(`[data-key="${key}"]`)?.classList.toggle('companion-hidden', on);
  }
  for (const sub of COMPANION_HIDDEN_PAGES) {
    tab.querySelector(`[data-subpage-entry="${sub}"]`)?.closest('.card')
      ?.classList.toggle('companion-hidden', on);
  }
  tab.querySelector('#permsCard')?.classList.toggle('companion-hidden', on);
  const conversation = tab.querySelector('.subpage[data-subpage="Conversation"]');
  if (conversation) {
    for (const key of COMPANION_HIDDEN_SETTINGS) {
      const el = conversation.querySelector(`[data-key="${key}"]`);
      el?.classList.toggle('companion-hidden', on);
      // The group goes with its rows: its card, and the heading before it.
      const card = el?.closest('.card');
      if (card) {
        const shown = [...card.querySelectorAll('[data-key]')].some((r) => !r.classList.contains('companion-hidden'));
        card.classList.toggle('companion-hidden', !shown);
        const h = card.previousElementSibling;
        if (h?.matches('h2.card-title')) h.classList.toggle('companion-hidden', !shown);
      }
    }
  }
}

/* The page's own part, under the switch render() put in the panel. */
export function renderCompanionPanel(panel) {
  if (!panel || panel.querySelector('#companionBody')) return;
  // A device without a screen cannot be one: the switch goes, with the
  // card it leaves empty.
  if (isHeadless()) {
    const toggle = panel.querySelector('[data-key="voice.companion_mode"]');
    const card = toggle?.closest('.card');
    toggle?.remove();
    if (card && !card.children.length) card.remove();
  }
  const body = document.createElement('div');
  body.id = 'companionBody';
  panel.appendChild(body);
  const paint = async () => {
    let status = {};
    try {
      const r = await cmd('companionStatus', {});
      if (r.ok) status = r.data || {};
    } catch (_) {}
    if (!body.isConnected) return;
    body.replaceChildren(...(companionScreenOn() ? companionCards(status, paint) : screenCards(status, paint)));
  };
  watchUpdates(['companion'], paint, { owner: body });
  document.addEventListener('ks-settings', function listener(e) {
    if (!body.isConnected) { document.removeEventListener('ks-settings', listener); return; }
    if ((e.detail || []).some((k) => k === 'voice.companion_mode' || k === 'voice.enabled')) paint();
  });
}

/* This kiosk as a companion screen. */
function companionCards(status, paint) {
  const out = [];
  const invite = status.invite;
  if (invite) {
    const card = document.createElement('div');
    card.className = 'card';
    const r = row(`${invite.name || ''}`, voiceText('Invitation to show its voice sessions on this screen.'));
    r.lastElementChild.remove();
    r.append(
      button(voiceText('Decline'), 'btn-ghost', async () => { await run('companionDecline'); paint(); }),
      button(voiceText('Accept'), 'btn-primary', async () => { await run('companionAccept'); paint(); }),
    );
    card.appendChild(r);
    out.push(heading(voiceText('Invitation')), card);
  }
  const card = document.createElement('div');
  card.className = 'card';
  const of = status.of;
  if (of) {
    const r = row(`${of.name || ''}`, of.state === 'refused'
      ? voiceText('That kiosk no longer has this screen on its list.')
      : voiceText('Its Voice Satellite sessions are displayed on this screen.'));
    word(r, linkText(of.state), of.state === 'connected' ? 'var(--primary)' : 'var(--warn)');
    r.appendChild(button(voiceText('Stop'), 'btn-ghost', async () => {
      const pick = await messageBox({
        title: voiceText('Stop showing this kiosk?'),
        message: voiceText('Its voice sessions no longer show here. It can invite this screen again.'),
        buttons: ['Cancel', 'Stop'],
        buttonText: voiceText,
      });
      if (pick !== 'Stop') return;
      await run('companionStop');
      paint();
    }));
    card.appendChild(r);
  } else {
    card.appendChild(row('', voiceText('Waiting for an invitation. On the kiosk whose voice sessions this screen should show, open Voice Satellite, Companion screens and add this one.')));
  }
  out.push(heading(voiceText('Paired kiosk')), card);
  return out;
}

function screenText(s) {
  switch (s.status) {
    case 'pending': return voiceText('Waiting for its OK');
    case 'declined': return voiceText('Declined the invitation');
    case 'left': return voiceText('Stopped showing this kiosk');
    default: return voiceText("Displays this device's Voice Satellite sessions.");
  }
}

/* This kiosk as the one with the voice assistant. */
function screenCards(status, paint) {
  const card = document.createElement('div');
  card.className = 'card';
  for (const s of status.screens || []) {
    const r = row(`${s.name || ''}`, screenText(s));
    if (s.status === 'accepted') {
      word(r, linkText(s.connected ? 'connected' : 'offline'), s.connected ? 'var(--primary)' : 'var(--warn)');
    } else {
      r.lastElementChild.remove();
    }
    const remove = document.createElement('button');
    remove.type = 'button';
    remove.className = 'icon-btn';
    remove.title = voiceText('Remove');
    remove.setAttribute('aria-label', voiceText('Remove'));
    remove.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M9 6V4h6v2M5 6l1 14h12l1-14M10 10v6M14 10v6"/></svg>';
    remove.addEventListener('click', async () => {
      const pick = await messageBox({
        title: `${s.name || ''}`,
        message: voiceText("This kiosk's voice sessions no longer show on that screen."),
        buttons: ['Cancel', 'Remove'],
        buttonText: voiceText,
      });
      if (pick !== 'Remove') return;
      await run('companionRemove', { id: s.id });
      paint();
    });
    r.appendChild(remove);
    card.appendChild(r);
  }
  const add = row(voiceText('Add a companion screen'),
    voiceText("A companion screen shows this kiosk's Voice Satellite sessions. Turn on companion screen mode on that kiosk first."));
  add.lastElementChild.remove();
  const plus = document.createElement('button');
  plus.type = 'button';
  plus.className = 'icon-btn';
  plus.title = voiceText('Add');
  plus.setAttribute('aria-label', voiceText('Add'));
  plus.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>';
  plus.addEventListener('click', async () => {
    const id = await pickCompanion();
    if (!id) return;
    await run('companionInvite', { id });
    paint();
  });
  add.appendChild(plus);
  card.appendChild(add);
  return [heading(voiceText('Paired companion screens')), card];
}

function why(k) {
  if (k.supported !== true) return voiceText('Needs a newer Kiosk Satellite');
  if (k.companion !== true) return voiceText('Companion screen mode is off there');
  if (typeof k.of === 'string') return voiceText('Shows another kiosk');
  return `${k.address || ''}`;
}

/* The kiosks on the network, the ones in companion screen mode to pick. */
function pickCompanion() {
  return new Promise((resolve) => {
    let done = false;
    const finish = (id) => {
      if (done) return;
      done = true;
      shell.close();
      resolve(id);
    };
    const shell = modalShell({ title: voiceText('Add a companion screen'), width: 480, onDismiss: () => finish(null) });
    const list = document.createElement('div');
    list.className = 'card';
    list.appendChild(row('', t('commonLoading', {}, 'Loading…')));
    shell.body.appendChild(list);
    const cancel = button(voiceText('Cancel'), 'btn-text', () => finish(null));
    shell.foot.appendChild(cancel);
    cmd('companionCandidates', {}, { timeoutMs: 20000 }).then((r) => {
      const kiosks = r?.ok && Array.isArray(r.data) ? r.data : [];
      list.replaceChildren();
      if (!kiosks.length) {
        list.appendChild(row('', voiceText('No other kiosks found on this network.')));
        return;
      }
      for (const k of kiosks) {
        const r2 = row(`${k.name || ''}`, why(k));
        r2.lastElementChild.remove();
        if (k.companion === true) {
          r2.style.cursor = 'pointer';
          r2.tabIndex = 0;
          r2.addEventListener('click', () => finish(`${k.id}`));
          r2.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); finish(`${k.id}`); }
          });
        } else {
          r2.style.opacity = '0.55';
        }
        list.appendChild(r2);
      }
    }).catch(() => {
      list.replaceChildren(row('', voiceText('No other kiosks found on this network.')));
    });
  });
}
