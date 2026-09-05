import { cmd, state } from './core.js';
import { settingRow } from './rows.js';
import { SEARCH_CATEGORY_TABS } from './search.js';
import { applySubpageView, currentPath, setCurrentPath, showTab } from './tabs.js';
import { SUBPAGE_ICONS } from './icons.js';
import { banner, hintRow, messageBox, modalShell, showToast } from './widgets.js';

/* ---- Fleet Management ----
   One kiosk leads, the others follow. Everything on this tab is drawn from
   the device's fleetStatus command (the same shape the device's own page
   draws) and redrawn on the fleetsync event the device pushes over the
   socket. The one thing this page cannot do is accept an invitation: that
   is answered on the kiosk screen. */

const DOCS_URL = 'https://github.com/jxlarrea/kiosk-satellite/blob/main/docs/fleet.md';

let status = null;
let pollTimer = null;
let busy = false;

const byKey = (key) => (state.settings || []).find((s) => s.key === key);

async function loadStatus() {
  try {
    const r = await cmd('fleetStatus');
    if (r.ok) { status = r.data; state.fleetSync = status; }
  } catch (_) {}
  return status;
}

/* ---- pieces ---- */

const titled = (title) => {
  const h = document.createElement('h2');
  h.className = 'card-title';
  h.textContent = title;
  const card = document.createElement('div');
  card.className = 'card';
  return [h, card];
};

function tag(text, kind = '') {
  const t = document.createElement('span');
  t.className = 'tag' + (kind ? ' ' + kind : '');
  t.textContent = text;
  return t;
}

// A row with a name and a description, nothing trailing yet.
function infoRow(name, desc) {
  const row = document.createElement('div');
  row.className = 'row';
  const info = document.createElement('div');
  info.className = 'info';
  info.innerHTML = '<div class="name"></div><div class="desc"></div>';
  info.querySelector('.name').textContent = name;
  info.querySelector('.desc').textContent = desc;
  row.appendChild(info);
  return row;
}

// A kiosk row: the name on its own line, the address and its tags on the
// second. The switcher's shape.
function kioskRow({ name, address, version, tags = [], dim = false }) {
  const row = document.createElement('div');
  row.className = 'row fleet-row' + (dim ? ' dim' : '');
  const info = document.createElement('div');
  info.className = 'info';
  const nameEl = document.createElement('div');
  nameEl.className = 'name';
  const nameText = document.createElement('span');
  nameText.textContent = name || address;
  nameEl.appendChild(nameText);
  const desc = document.createElement('div');
  desc.className = 'desc';
  const ip = document.createElement('span');
  ip.textContent = address || '';
  desc.appendChild(ip);
  if (version) desc.appendChild(tag(version, ''));
  for (const t of tags) desc.appendChild(t);
  info.append(nameEl, desc);
  row.appendChild(info);
  return row;
}

function button(label, cls, onClick) {
  const b = document.createElement('button');
  b.type = 'button';
  b.className = cls;
  b.textContent = label;
  b.style.flexShrink = '0';
  b.addEventListener('click', onClick);
  return b;
}

async function run(name, params = {}, { reload = true } = {}) {
  if (busy) return null;
  busy = true;
  let out;
  try { out = await cmd(name, params); }
  catch (_) { out = { ok: false, error: 'The device did not answer.' }; }
  busy = false;
  if (!out.ok) showToast({ title: 'Fleet Management', message: out.error || '', kind: 'error' });
  if (reload) { await loadStatus(); renderFleetPage({ fetch: false }); }
  return out;
}

// The overflow menu on a follower row: a popover under its button.
function popmenu(anchor, items) {
  document.querySelectorAll('.popmenu').forEach((m) => m.remove());
  const menu = document.createElement('div');
  menu.className = 'popmenu';
  for (const it of items) {
    const b = document.createElement('button');
    b.type = 'button';
    b.textContent = it.label;
    if (it.danger) b.classList.add('danger');
    b.addEventListener('click', () => { menu.remove(); it.run(); });
    menu.appendChild(b);
  }
  document.body.appendChild(menu);
  const r = anchor.getBoundingClientRect();
  const w = menu.offsetWidth;
  menu.style.top = `${r.bottom + window.scrollY + 4}px`;
  menu.style.left = `${Math.max(8, Math.min(r.right - w, window.innerWidth - w - 8)) + window.scrollX}px`;
  const close = (e) => {
    if (menu.contains(e.target)) return;
    menu.remove();
    document.removeEventListener('pointerdown', close, true);
  };
  setTimeout(() => document.addEventListener('pointerdown', close, true), 0);
}

const MORE = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="6" r="1.2"/><circle cx="12" cy="12" r="1.2"/><circle cx="12" cy="18" r="1.2"/></svg>';

/* ---- profiles: the picker, the editor, the exclusion picker ---- */

const describe = (p) =>
  `Categories: ${(p.categories || []).length} of ${(status?.categories || []).length}. `
  + `Credentials: ${(p.credentials || []).length} of ${(status?.credentials || []).length}. `
  + `Excluded: ${(p.excluded || []).length}.`;

// The glyph a profile's entry row and its page title share: registered by
// name, since the pages are made at runtime.
const PROFILE_ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M1 14h6M9 8h6M17 16h6"/></svg>';

const modalHeading = (text) => {
  const h = document.createElement('h2');
  h.className = 'card-title';
  h.textContent = text;
  h.style.margin = '12px 0 4px';
  return h;
};

// Which profile a kiosk gets: one radio row per profile. Resolves to the
// profile id, null when cancelled.
function openProfilePicker({ who, selected = 'default', confirm = 'Save' }) {
  return new Promise((resolve) => {
    const shell = modalShell({ title: `Sync to ${who}`, width: 480,
      onDismiss: () => { shell.close(); resolve(null); } });
    let picked = selected;
    for (const p of status?.profiles || []) {
      const row = document.createElement('label');
      row.className = 'row';
      const inp = document.createElement('input');
      inp.type = 'radio';
      inp.name = 'fleet-profile';
      inp.checked = p.id === picked;
      inp.addEventListener('change', () => { if (inp.checked) picked = p.id; });
      const info = document.createElement('div');
      info.className = 'info';
      info.innerHTML = '<div class="name"></div><div class="desc"></div>';
      info.querySelector('.name').textContent = p.name;
      info.querySelector('.desc').textContent = describe(p);
      row.append(inp, info);
      shell.body.appendChild(row);
    }
    shell.foot.append(
      button('Cancel', 'btn-text', () => { shell.close(); resolve(null); }),
      button(confirm, 'btn-primary', () => { shell.close(); resolve(picked); }),
    );
  });
}

// The full path to a setting: category, page, title.
const pathOf = (e) => [e.category, e.subpage, e.title].filter(Boolean).join(' \u2192 ');
// Category, then page, then title; a key the list does not know last.
const orderOf = (e, key) => (e ? `${e.category}\u0000${e.subpage || ''}\u0000${e.title}` : `~${key}`).toLowerCase();

let syncableCache = null;
async function syncable() {
  if (syncableCache) return syncableCache;
  try {
    const r = await cmd('fleetSyncable');
    if (r.ok) syncableCache = Object.fromEntries((r.data || []).map((e) => [e.key, e]));
  } catch (_) {}
  return syncableCache || {};
}

// A profile's name. Resolves to the trimmed name, null when cancelled.
function openNameModal({ title, initial = '' }) {
  return new Promise((resolve) => {
    const shell = modalShell({ title, width: 440, onDismiss: () => { shell.close(); resolve(null); } });
    const input = document.createElement('input');
    input.className = 'field';
    input.placeholder = 'Black screens';
    input.value = initial;
    input.style.cssText = 'width:100%;';
    shell.body.appendChild(input);
    const done = () => {
      const name = input.value.trim();
      if (!name) { input.focus(); return; }
      shell.close(); resolve(name);
    };
    input.addEventListener('keydown', (e) => { if (e.key === 'Enter') done(); });
    shell.foot.append(
      button('Cancel', 'btn-text', () => { shell.close(); resolve(null); }),
      button('Save', 'btn-primary', done),
    );
    input.focus();
  });
}

const checkRow = (name, desc, checked, onChange) => {
  const row = document.createElement('label');
  row.className = 'row';
  const inp = document.createElement('input');
  inp.type = 'checkbox';
  inp.checked = checked;
  inp.addEventListener('change', () => onChange(inp.checked));
  const info = document.createElement('div');
  info.className = 'info';
  info.innerHTML = '<div class="name"></div><div class="desc"></div>';
  info.querySelector('.name').textContent = name;
  if (desc) info.querySelector('.desc').textContent = desc;
  else info.querySelector('.desc').remove();
  row.append(inp, info);
  return row;
};

const switchRow = (name, desc, on, set) => {
  const row = infoRow(name, desc);
  if (!desc) row.querySelector('.desc').remove();
  const lbl = document.createElement('label');
  lbl.className = 'switch';
  const cb = document.createElement('input');
  cb.type = 'checkbox';
  cb.checked = on;
  const slider = document.createElement('span');
  slider.className = 'slider';
  cb.addEventListener('change', () => set(cb.checked));
  lbl.append(cb, slider);
  row.appendChild(lbl);
  return row;
};

// The categories a profile syncs, one checkbox each with what stays per
// kiosk inside it. Resolves to the list, null when cancelled.
function openCategoriesModal(picked) {
  const chosen = new Set(picked);
  return new Promise((resolve) => {
    const shell = modalShell({ title: 'Categories', width: 560, onDismiss: () => { shell.close(); resolve(null); } });
    const cats = document.createElement('div');
    cats.className = 'fleet-cat';
    for (const cat of status?.categories || []) {
      const note = cat.note || '';
      cats.appendChild(checkRow(cat.title,
        !note ? '' : cat.id === 'Kiosk' ? note[0].toUpperCase() + note.slice(1) : `Not synced: ${note}`,
        chosen.has(cat.id), (v) => { if (v) chosen.add(cat.id); else chosen.delete(cat.id); }));
    }
    shell.body.appendChild(cats);
    shell.foot.append(
      button('Cancel', 'btn-text', () => { shell.close(); resolve(null); }),
      button('Save', 'btn-primary', () => { shell.close(); resolve([...chosen]); }),
    );
  });
}

// Which credentials travel, one switch each. Resolves to the keys, null
// when cancelled.
function openCredentialsModal(picked) {
  const chosen = new Set(picked);
  return new Promise((resolve) => {
    const shell = modalShell({ title: 'Synced Credentials', width: 520, onDismiss: () => { shell.close(); resolve(null); } });
    for (const c of status?.credentials || []) {
      shell.body.appendChild(switchRow(c.title, '', chosen.has(c.key),
        (v) => { if (v) chosen.add(c.key); else chosen.delete(c.key); }));
    }
    shell.foot.append(
      button('Cancel', 'btn-text', () => { shell.close(); resolve(null); }),
      button('Save', 'btn-primary', () => { shell.close(); resolve([...chosen]); }),
    );
  });
}

// The settings a profile leaves out whatever their category says, each
// with a way back in and a picker to add any other. Resolves to the keys,
// null when cancelled.
function openExcludedModal(excluded) {
  const chosen = new Set(excluded);
  return new Promise((resolve) => {
    const shell = modalShell({ title: 'Excluded settings', width: 560, onDismiss: () => { shell.close(); resolve(null); } });
    shell.body.appendChild(hintRow('The settings on this list will not be synced to the followers.'));
    const list = document.createElement('div');
    shell.body.appendChild(list);
    const paint = async () => {
      const known = await syncable();
      list.textContent = '';
      if (!chosen.size) list.appendChild(infoRow('Nothing left out', ''));
      const ordered = [...chosen].sort((a, b) => orderOf(known[a], a).localeCompare(orderOf(known[b], b)));
      for (const key of ordered) {
        const e = known[key];
        const row = infoRow(e ? pathOf(e) : key, e?.description || '');
        const x = document.createElement('button');
        x.type = 'button';
        x.className = 'icon-btn';
        x.title = 'Sync it again';
        x.setAttribute('aria-label', 'Sync it again');
        x.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>';
        x.addEventListener('click', () => { chosen.delete(key); paint(); });
        row.appendChild(x);
        list.appendChild(row);
      }
    };
    paint();
    // Add a setting in the footer, on the left, where it stays in view
    // however long the list above grows.
    const add = button('Add a setting', 'btn-ghost', async () => {
      const key = await openExcludePicker(chosen);
      if (key) { chosen.add(key); paint(); }
    });
    add.style.marginRight = 'auto';
    shell.foot.append(
      add,
      button('Cancel', 'btn-text', () => { shell.close(); resolve(null); }),
      button('Save', 'btn-primary', () => { shell.close(); resolve([...chosen]); }),
    );
  });
}

// Pick a setting to exclude: every syncable one not yet out, filtered by
// what is typed, each with its page. Resolves to the key, null when
// cancelled. Opened over the excluded modal, so it closes back onto it.
function openExcludePicker(already) {
  return new Promise(async (resolve) => {
    const known = await syncable();
    const shell = modalShell({ title: 'Exclude a setting', width: 480,
      onDismiss: () => { shell.close(); resolve(null); } });
    const search = document.createElement('input');
    search.type = 'search';
    search.className = 'field';
    search.placeholder = 'Search settings';
    search.style.cssText = 'width:100%; margin-bottom:8px;';
    shell.body.appendChild(search);
    const list = document.createElement('div');
    shell.body.appendChild(list);
    const paint = () => {
      const q = search.value.trim().toLowerCase();
      list.textContent = '';
      const rows = Object.values(known)
        .filter((e) => !already.has(e.key) && !e.hidden
          && (!q || `${e.title} ${e.category} ${e.subpage || ''}`.toLowerCase().includes(q)))
        .sort((a, b) => orderOf(a, a.key).localeCompare(orderOf(b, b.key)));
      for (const e of rows.slice(0, 80)) {
        const row = infoRow(pathOf(e), e.description || '');
        row.classList.add('fleet-row');
        row.tabIndex = 0;
        row.addEventListener('click', () => { shell.close(); resolve(e.key); });
        row.addEventListener('keydown', (ev) => { if (ev.key === 'Enter') row.click(); });
        list.appendChild(row);
      }
      if (rows.length > 80) list.appendChild(hintRow(`${rows.length - 80} more. Type to narrow the list.`));
    };
    search.addEventListener('input', paint);
    paint();
    shell.foot.appendChild(button('Cancel', 'btn-text', () => { shell.close(); resolve(null); }));
    search.focus();
  });
}

/* ---- a profile's page ---- */

// The entry row on the Profiles card: the page's name and what it holds,
// the shape of every second-level entry.
function profileEntry(p) {
  const row = document.createElement('div');
  row.className = 'row subpage-entry';
  row.dataset.subpageEntry = p.name;
  SUBPAGE_ICONS[p.name] = PROFILE_ICON;
  const icon = document.createElement('span');
  icon.className = 'page-icon';
  icon.innerHTML = PROFILE_ICON;
  const info = document.createElement('div');
  info.className = 'info';
  info.innerHTML = '<div class="name"></div><div class="desc"></div>';
  info.querySelector('.name').textContent = p.name;
  info.querySelector('.desc').textContent = describe(p);
  const chev = document.createElement('span');
  chev.className = 'chev';
  chev.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 18 6-6-6-6"/></svg>';
  row.append(icon, info, chev);
  row.addEventListener('click', () => showTab(`fleet/${p.name}`));
  return row;
}

// A row that opens a modal: name, what it holds, a chevron.
function openerRow(name, desc, onOpen) {
  const row = infoRow(name, desc);
  row.classList.add('subpage-entry');
  const chev = document.createElement('span');
  chev.className = 'chev';
  chev.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 18 6-6-6-6"/></svg>';
  row.appendChild(chev);
  row.addEventListener('click', onOpen);
  return row;
}

async function saveProfile(profile) {
  const out = await run('fleetSetProfile', { profile }, { reload: false });
  await loadStatus();
  renderFleetPage({ fetch: false });
  return out;
}

// The page: the name, then what it syncs behind four rows, the kiosks on
// it, Duplicate and Delete. Everything saves on the spot.
function profilePanel(p) {
  const panel = document.createElement('div');
  panel.className = 'subpage';
  panel.dataset.subpage = p.name;
  const isDefault = p.id === 'default';
  const cats = status?.categories || [];
  const creds = status?.credentials || [];
  const catNames = cats.filter((c) => (p.categories || []).includes(c.id)).map((c) => c.title);
  const credNames = creds.filter((c) => (p.credentials || []).includes(c.key)).map((c) => c.title);
  if (!isDefault) {
    const card = document.createElement('div');
    card.className = 'card';
    const row = infoRow('Name', p.name);
    row.appendChild(button('Rename', 'btn-ghost', async () => {
      const name = await openNameModal({ title: 'Rename profile', initial: p.name });
      if (!name || name === p.name) return;
      const out = await saveProfile({ ...p, name });
      if (out?.ok) showTab(`fleet/${name}`);
    }));
    card.appendChild(row);
    panel.appendChild(card);
  }
  const [h1, card1] = titled('What it syncs');
  card1.appendChild(openerRow('Categories',
    catNames.length ? `${catNames.length} of ${cats.length}: ${catNames.join(', ')}` : 'None',
    async () => {
      const picked = await openCategoriesModal(p.categories || []);
      if (picked) await saveProfile({ ...p, categories: picked });
    }));
  card1.appendChild(openerRow('Credentials', credNames.length ? credNames.join(', ') : 'None travel',
    async () => {
      const picked = await openCredentialsModal(p.credentials || []);
      if (picked) await saveProfile({ ...p, credentials: picked });
    }));
  card1.appendChild(switchRow('Include the dashboard', 'The start page and the default dashboard.',
    !!p.dashboard, (v) => saveProfile({ ...p, dashboard: v })));
  const x = (p.excluded || []).length;
  card1.appendChild(openerRow('Excluded settings',
    x === 0 ? 'None' : x === 1 ? 'One setting left out' : `${x} settings left out`,
    async () => {
      const picked = await openExcludedModal(p.excluded || []);
      if (picked) await saveProfile({ ...p, excluded: picked });
    }));
  panel.append(h1, card1);
  const [h2, card2] = titled('Kiosks');
  const names = (status?.followers || []).filter((f) => f.profile === p.id).map((f) => f.name);
  if (!names.length) {
    card2.appendChild(infoRow('No kiosks assigned', 'Assign this profile to a kiosk on the Fleet Management page.'));
  } else {
    for (const n of names) card2.appendChild(infoRow(n, ''));
  }
  panel.append(h2, card2);
  const card3 = document.createElement('div');
  card3.className = 'card';
  card3.style.marginTop = '16px';
  const dup = infoRow('Duplicate', 'Clone this profile into a new one.');
  dup.appendChild(button('Duplicate', 'btn-ghost', async () => {
    const name = await openNameModal({ title: 'Duplicate profile', initial: `${p.name} copy` });
    if (!name) return;
    const out = await saveProfile({ ...p, id: '', name });
    if (out?.ok) showTab(`fleet/${name}`);
  }));
  card3.appendChild(dup);
  if (!isDefault) {
    const del = infoRow('Delete profile', names.length ? 'Kiosks on it get the Default profile.' : 'No kiosk is on it.');
    const b = button('Delete', 'btn-ghost', async () => {
      const pick = await messageBox({ title: `Delete ${p.name}?`,
        message: 'Kiosks on it get the Default profile.', buttons: ['Cancel', 'Delete'] });
      if (pick !== 'Delete') return;
      const out = await run('fleetDeleteProfile', { id: p.id }, { reload: false });
      if (out?.ok) { showTab('fleet'); await loadStatus(); renderFleetPage({ fetch: false }); }
    });
    b.style.color = 'var(--error)';
    del.appendChild(b);
    card3.appendChild(del);
  }
  panel.appendChild(card3);
  return panel;
}

/* ---- Add a kiosk ---- */

function openAddDialog() {
  return new Promise((resolve) => {
    const shell = modalShell({ title: 'Add a kiosk', width: 440,
      onDismiss: () => { shell.close(); resolve(null); } });
    const looking = document.createElement('div');
    looking.className = 'hint-row';
    looking.textContent = 'Looking for other kiosks…';
    shell.body.appendChild(looking);
    shell.foot.appendChild(button('Cancel', 'btn-text', () => { shell.close(); resolve(null); }));
    cmd('fleetCandidates').then((r) => {
      looking.remove();
      const list = r.ok ? (r.data || []) : [];
      if (!list.length) {
        shell.body.appendChild(hintRow('No other kiosk found on this network. A kiosk shows up once its remote admin is on and it shares this Wi-Fi.'));
        return;
      }
      for (const k of list) {
        const taken = !!k.follows || k.leader === true || k.supported === false;
        const tags = [];
        if (k.follows) tags.push(tag(`Follows ${k.follows}`));
        if (k.leader === true) tags.push(tag('Leads a fleet'));
        // A build from before Fleet Management: same version name, no
        // fleet endpoints.
        if (k.supported === false) tags.push(tag('No Fleet Management', 'error'));
        const row = kioskRow({ name: k.name, address: k.address, version: k.version, tags, dim: taken });
        if (!taken) {
          row.tabIndex = 0;
          row.addEventListener('click', () => { shell.close(); resolve(k); });
          row.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); row.click(); } });
        }
        shell.body.appendChild(row);
      }
      shell.body.appendChild(hintRow('Kiosks on this network that do not follow this one. Pick one to choose what it gets, then the invitation goes out. A kiosk on a build without Fleet Management joins once it runs one.'));
    }).catch(() => {
      looking.textContent = 'The device did not answer.';
    });
  });
}

/* ---- the page ---- */

export async function renderFleetPage({ fetch = true } = {}) {
  const tab = document.getElementById('tab-fleet');
  if (!tab) return;
  if (fetch || !status) await loadStatus();
  applyManagedBanners();
  tab.innerHTML = '';
  if (!status) {
    tab.appendChild(hintRow('The device did not answer.'));
    return;
  }
  const enabled = status.enabled === true;
  const leading = status.leader === true;
  const following = status.following;
  const invite = status.invite;

  if (!enabled) {
    const card = document.createElement('div');
    card.className = 'card';
    const row = infoRow('Fleet Management needs the remote admin',
      'Kiosks find each other through it. Turn on Remote management and Find other kiosks under Device, then come back.');
    row.appendChild(button('Open', 'btn-ghost', () => showTab('device/Remote Administration')));
    card.appendChild(row);
    tab.appendChild(card);
  }

  if (invite?.leader) {
    const card = document.createElement('div');
    card.className = 'card';
    const l = invite.leader;
    card.appendChild(kioskRow({ name: `${l.name} wants to lead this kiosk`, address: l.address, version: l.version, tags: [tag('Leader', 'device')] }));
    card.appendChild(hintRow('Confirm on the kiosk itself. The invitation is waiting on its screen and under Settings, Fleet Management.'));
    tab.appendChild(card);
  }

  // Lead this fleet: the definition's own row, disabled while following.
  {
    const card = document.createElement('div');
    card.className = 'card';
    const def = byKey('fleet.leader');
    if (def) {
      const row = settingRow(def);
      const input = row.querySelector('input');
      if (following || !enabled) {
        if (input) input.disabled = true;
        if (following) row.querySelector('.desc').textContent = 'A kiosk that follows a leader cannot lead.';
        row.style.opacity = '.55';
      }
      card.appendChild(row);
    }
    tab.appendChild(card);
  }

  if (enabled && leading) {
    // Followers.
    const [h, card] = titled('Followers');
    for (const f of status.followers || []) card.appendChild(followerRow(f));
    const add = infoRow('Add a kiosk', 'Kiosks member of the fleet. A follower must confirm the invitation on device.');
    add.appendChild(button('Add', 'btn-ghost', async () => {
      const k = await openAddDialog();
      if (!k) return;
      const profile = await openProfilePicker({ who: k.name, confirm: 'Send invitation' });
      if (!profile) return;
      await run('fleetInvite', { id: k.id, profile });
    }));
    card.appendChild(add);
    tab.append(h, card);

    // Profiles: one entry row each, its page parked on the tab.
    const [h2, card2] = titled('Profiles');
    for (const p of status.profiles || []) card2.appendChild(profileEntry(p));
    const addP = infoRow('Add a profile', 'The collection of settings, credentials and exclusions to sync.');
    addP.appendChild(button('Add', 'btn-ghost', async () => {
      const name = await openNameModal({ title: 'New profile' });
      if (!name) return;
      const base = (status.profiles || []).find((p) => p.id === 'default') || {};
      const out = await saveProfile({ ...base, id: '', name });
      if (out?.ok) showTab(`fleet/${name}`);
    }));
    card2.appendChild(addP);
    const note = document.createElement('div');
    note.className = 'group-note';
    note.innerHTML = 'Learn which settings sync and which do not in the <a target="_blank" rel="noopener"></a>.';
    const a = note.querySelector('a');
    a.href = DOCS_URL;
    a.textContent = 'Fleet Management documentation';
    tab.append(h2, card2, note);
    for (const p of status.profiles || []) tab.appendChild(profilePanel(p));

    // Updates.
    const [h3, card3] = titled('Updates');
    const upd = infoRow('Update the fleet', 'Update the whole fleet to the Kiosk Satellite version running on the leader.');
    upd.appendChild(button('Update', 'btn-primary', async () => {
      const out = await run('fleetUpdate', {}, { reload: false });
      if (!out?.ok) return;
      const data = out.data || {};
      const started = data.started || [];
      const skipped = data.skipped || {};
      const parts = [];
      if (started.length) parts.push(`${started.join(', ')} installing.`);
      if (data.self) parts.push('This kiosk installs last.');
      for (const [k, v] of Object.entries(skipped)) parts.push(`${k}: ${v}.`);
      showToast({ title: started.length || data.self ? 'Updating' : 'Nothing to update',
        message: parts.join(' '), kind: started.length || data.self ? 'success' : 'info' });
      await loadStatus();
      renderFleetPage({ fetch: false });
    }));
    card3.appendChild(upd);
    const auto = byKey('fleet.auto_update');
    if (auto) card3.appendChild(settingRow(auto));
    tab.append(h3, card3);
  }

  // The open page, if any, is rebuilt with the rest: reopen it or fall
  // back to the tab when it is gone (deleted, renamed).
  const slash = currentPath.indexOf('/');
  if (slash > 0 && currentPath.slice(0, slash) === 'fleet') {
    const sub = currentPath.slice(slash + 1);
    if (!applySubpageView('fleet', sub)) {
      setCurrentPath('fleet');
      showTab('fleet');
    }
  }

  if (following) {
    const [h, card] = titled('Leader');
    const l = following.leader || {};
    const row = kioskRow({ name: l.name, address: l.address, version: l.version, tags: [tag('Leader', 'device')] });
    const st = document.createElement('span');
    st.className = 'fleet-status' + (following.dirty ? '' : ' ok');
    st.textContent = following.dirty ? 'Changed here, waiting for the leader'
      : following.lastSyncAt ? `Synced ${ago(following.lastSyncAt)}` : 'Waiting for the first sync';
    row.appendChild(st);
    card.appendChild(row);
    const cats = following.syncedCategories || [];
    const creds = following.credentials || [];
    card.appendChild(infoRow('Synced from the leader',
      `${cats.length ? cats.join(', ') : 'Nothing yet'}. ${creds.length ? `With the ${creds.join(', ')}` : 'No credentials'}. ${following.dashboard ? 'The dashboard' : 'No dashboard'}.`));
    const leave = infoRow('Leave the fleet', 'Stops the sync. Settings stay as they are.');
    leave.appendChild(button('Leave', 'btn-ghost', async () => {
      const pick = await messageBox({ title: 'Leave the fleet?',
        message: `${l.name} stops pushing settings here. Everything stays as it is now.`,
        buttons: ['Cancel', 'Leave'] });
      if (pick !== 'Leave') return;
      await run('fleetLeave');
    }));
    card.appendChild(leave);
    tab.append(h, card);
  }
}

function followerRow(f) {
  const tags = [];
  if (f.profile !== 'default') tags.push(tag(f.profileName || 'Profile', 'device'));
  const row = kioskRow({ name: f.name, address: f.address, version: f.version, tags });
  row.classList.remove('fleet-row');
  if (f.phase === 'version') {
    const v = row.querySelector('.desc .tag');
    if (v) v.classList.add('error');
  }
  const st = document.createElement('span');
  st.className = 'fleet-status' + (f.tone === 'ok' ? ' ok' : f.tone === 'warn' ? ' warn' : '');
  st.textContent = f.status || '';
  const more = document.createElement('button');
  more.type = 'button';
  more.className = 'icon-btn';
  more.title = 'More';
  more.setAttribute('aria-label', 'More');
  more.innerHTML = MORE;
  more.addEventListener('click', () => popmenu(more, [
    { label: 'Profile', run: async () => {
      const profile = await openProfilePicker({ who: f.name, selected: f.profile });
      if (!profile) return;
      await run('fleetAssignProfile', { id: f.id, profile });
    } },
    f.phase === 'declined' || f.phase === 'left'
      ? { label: 'Invite again', run: () => run('fleetInvite', { id: f.id, profile: f.profile }) }
      : { label: 'Sync now', run: () => run('fleetSyncNow', { id: f.id }) },
    { label: 'Remove', danger: true, run: async () => {
      const pick = await messageBox({ title: `Remove ${f.name}?`,
        message: 'It stops following this kiosk and keeps its settings.',
        buttons: ['Cancel', 'Remove'] });
      if (pick === 'Remove') await run('fleetRemove', { id: f.id });
    } },
  ]));
  // Two loose trailing controls overlap on a phone: one wrapper.
  const trail = document.createElement('div');
  trail.style.cssText = 'display:flex; align-items:center; gap:8px; flex:none; margin-left:auto;';
  trail.append(st, more);
  row.appendChild(trail);
  return row;
}

function ago(at) {
  const s = Math.round((Date.now() - at) / 1000);
  if (s < 60) return 'just now';
  const m = Math.floor(s / 60);
  if (m < 60) return `${m} min ago`;
  const h = Math.floor(m / 60);
  if (h < 48) return `${h} h ago`;
  return `${Math.floor(h / 24)} days ago`;
}

/* ---- the banner on a follower's synced categories ---- */

// A category the leader pushes says so at the top of its tab, both
// surfaces. The Web Content grants ride with Web Browsing, as on the device.
export function applyManagedBanners() {
  document.querySelectorAll('.fleet-banner').forEach((b) => b.remove());
  const following = status?.following;
  if (!following) return;
  const synced = new Set(following.syncedKeys || []);
  if (!synced.size) return;
  const tabs = new Set();
  for (const s of state.settings || []) {
    if (!synced.has(s.key)) continue;
    const cat = s.category === 'Web Content' ? 'Browser' : s.category;
    const tab = SEARCH_CATEGORY_TABS[cat];
    if (tab) tabs.add(tab);
  }
  for (const tab of tabs) {
    const el = document.getElementById(`tab-${tab}`);
    if (!el) continue;
    const b = banner(`${following.leader?.name} leads these settings. A change here is replaced at the next sync.`,
      { className: 'fleet-banner' });
    el.prepend(b);
  }
}

/* ---- lifecycle ---- */

export function fleetShown() {
  renderFleetPage();
  if (pollTimer) clearInterval(pollTimer);
  // While the tab stays open: the device polls its followers at the fast
  // cadence for as long as something asks and the rows follow.
  pollTimer = setInterval(() => {
    if (currentPath.split('/')[0] !== 'fleet') { clearInterval(pollTimer); pollTimer = null; return; }
    if (document.hidden || document.querySelector('.modal-back')) return;
    renderFleetPage();
  }, 30000);
}

document.addEventListener('ks-event', (e) => {
  if (e.detail?.event !== 'fleetsync') return;
  loadStatus().then(() => {
    // Not under an open modal: a redraw would pull the rows from under it.
    if (document.querySelector('.modal-back')) { applyManagedBanners(); return; }
    renderFleetPage({ fetch: false });
  });
});
