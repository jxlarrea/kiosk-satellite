import { cameraAction, cameraListRow } from './cameras.js';
import { api, cmd } from './core.js';
import { readOnlyRow } from './device.js';
import { filesState } from './notices.js';
import { messageBox, showToast } from './widgets.js';

export function fileSizeLabel(bytes) {
  if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(1) + ' GB';
  if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + ' MB';
  if (bytes >= 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return bytes + ' B';
}

// The page is built once and kept: the root tabs and the upload button on
// top, the listing pane below with its header (the path and the Up button)
// attached, the rows scrolling inside it under the edge fade. Browsing
// swaps the rows and nothing else, the same shape as the Logs page, so a
// click never reflows the page or moves the controls under the finger.
let shell = null;

function buildShell(tab) {
  tab.innerHTML = '';

  // Root tabs on the left, upload on the right, bare on the page like the
  // Logs source picker: the tabs say what they are, so no card and no
  // label. On a phone the wrap drops the upload button to its own line,
  // still right-aligned thanks to the auto margin.
  const pick = document.createElement('div');
  pick.className = 'toolbar';
  pick.style.cssText = 'flex-wrap:wrap;';
  const segScroll = document.createElement('div');
  segScroll.className = 'seg-scroll edge-fade-x';
  const seg = document.createElement('div');
  seg.className = 'seg';
  segScroll.appendChild(seg);
  pick.appendChild(segScroll);
  const uploadBtn = document.createElement('button');
  uploadBtn.className = 'btn-ghost';
  uploadBtn.textContent = 'Upload file';
  uploadBtn.style.cssText = 'flex-shrink:0; margin-left:auto;';
  const picker = document.createElement('input');
  picker.type = 'file';
  picker.hidden = true;
  picker.addEventListener('change', async () => {
    const file = picker.files && picker.files[0];
    if (!file) return;
    uploadBtn.disabled = true;
    uploadBtn.textContent = 'Uploading…';
    const target = [...filesState.crumbs, file.name].join('/');
    try {
      const q = `root=${encodeURIComponent(filesState.root)}&path=${encodeURIComponent(target)}`;
      const res = await api(`/api/files/upload?${q}`, { method: 'POST', body: file });
      if (!res.ok) {
        showToast({ title: 'Upload failed',
          message: (((await res.json()) || {}).error || String(res.status)),
          kind: 'error' });
      } else {
        showToast({ title: 'Uploaded', message: file.name, kind: 'success' });
      }
    } catch (e) {
      showToast({ title: 'Upload failed', message: String(e), kind: 'error' });
    }
    picker.value = '';
    uploadBtn.disabled = false;
    uploadBtn.textContent = 'Upload file';
    refreshList();
  });
  uploadBtn.addEventListener('click', () => picker.click());
  pick.append(uploadBtn, picker);
  tab.appendChild(pick);

  // Shared storage gated: the grant screen lives on the device. The card
  // comes and goes with the grant; the pane below makes room for it.
  const grantCard = document.createElement('div');
  grantCard.className = 'card';
  grantCard.style.display = 'none';
  const grantRow = readOnlyRow('"All files access" permission missing',
    'Without it only the app folder can be browsed. The grant screen opens on the tablet.', '');
  const grantBtn = document.createElement('button');
  grantBtn.className = 'btn-ghost';
  grantBtn.textContent = 'Grant on device';
  grantBtn.style.cssText = 'flex-shrink:0;';
  grantBtn.addEventListener('click', async () => {
    grantBtn.disabled = true;
    try { await cmd('requestAllFilesAccess'); } catch (_) {}
    for (let i = 0; i < 30; i++) {
      await new Promise((r) => setTimeout(r, 2500));
      try {
        const res = await cmd('fileRoots');
        const sh = ((res.data || {}).roots || []).find((r) => r.id === 'shared');
        if (sh && sh.available) { loadFiles(); return; }
      } catch (_) {}
    }
    grantBtn.disabled = false;
  });
  grantRow.appendChild(grantBtn);
  grantCard.appendChild(grantRow);
  tab.appendChild(grantCard);

  // The listing pane: the header attached on top like the log box's, the
  // rows in a fixed-height scroller beneath.
  const head = document.createElement('div');
  head.className = 'log-head';
  const path = document.createElement('span');
  path.className = 'log-title';
  const up = cameraAction('Up one folder', () => {
    if (!filesState.crumbs.length) return;
    filesState.crumbs.pop();
    refreshList();
  }, false, 'up');
  head.append(path, up);
  const list = document.createElement('div');
  list.className = 'file-list edge-fade';
  tab.append(head, list);

  shell = { tab, seg, grantCard, path, up, list, buttons: new Map() };
}

// The root tabs reflect the device's answer: which roots exist, which can
// be browsed, which one is open. Rebuilt only when the set changes.
function paintRoots(roots) {
  const { seg, buttons } = shell;
  const ids = roots.map((r) => r.id).join('|');
  if (seg.dataset.ids !== ids) {
    seg.innerHTML = '';
    buttons.clear();
    for (const r of roots) {
      const b = document.createElement('button');
      b.textContent = r.label;
      b.addEventListener('click', () => {
        if (filesState.root === r.id) return;
        filesState.root = r.id;
        filesState.crumbs = [];
        paintRoots(roots);
        refreshList();
      });
      buttons.set(r.id, b);
      seg.appendChild(b);
    }
    seg.dataset.ids = ids;
  }
  for (const r of roots) {
    const b = buttons.get(r.id);
    b.classList.toggle('active', r.id === filesState.root);
    b.disabled = r.available !== true;
  }
  const shared = roots.find((r) => r.id === 'shared');
  const gated = !!(shared && shared.grantNeeded);
  shell.grantCard.style.display = gated ? '' : 'none';
  shell.list.classList.toggle('with-grant', gated);
}

// The rows of the open folder, into the pane. The old rows stay, dimmed,
// until the device answers, so the list never collapses between folders.
let listRun = 0;
async function refreshList() {
  const { path, up, list } = shell;
  const run = ++listRun;
  path.textContent = '/' + filesState.crumbs.join('/');
  up.disabled = !filesState.crumbs.length;
  list.style.opacity = '.6';
  const relPath = filesState.crumbs.join('/');
  let entries = null;
  let listErr = null;
  try {
    const res = await cmd('fileList', { root: filesState.root, path: relPath });
    if (res.ok) entries = (res.data || {}).entries || [];
    else listErr = res.error || 'could not read the folder';
  } catch (_) { listErr = 'device unreachable'; }
  // A later click superseded this answer.
  if (run !== listRun) return;
  list.style.opacity = '';
  list.innerHTML = '';
  if (listErr) {
    list.appendChild(readOnlyRow(listErr, '', ''));
  } else if (!entries.length) {
    list.appendChild(readOnlyRow('Empty folder', 'Nothing here yet.', ''));
  } else {
    for (const e of entries) {
      const desc = e.dir ? 'Folder'
        : `${fileSizeLabel(e.size || 0)} · ${new Date(e.modified || 0).toLocaleString()}`;
      if (e.dir) {
        list.appendChild(cameraListRow(e.name, desc, [], {
          icon: 'folder',
          onClick: () => { filesState.crumbs.push(e.name); refreshList(); },
        }));
        continue;
      }
      const rel = [...filesState.crumbs, e.name].join('/');
      const dl = cameraAction('Download', async () => {
        dl.disabled = true;
        try {
          const q = `root=${encodeURIComponent(filesState.root)}&path=${encodeURIComponent(rel)}`;
          const res = await api(`/api/files/download?${q}`);
          const blob = await res.blob();
          const a = document.createElement('a');
          a.href = URL.createObjectURL(blob);
          a.download = e.name;
          a.click();
          URL.revokeObjectURL(a.href);
        } catch (err) {
          showToast({ title: 'Download failed', message: String(err), kind: 'error' });
        }
        dl.disabled = false;
      }, false, 'download');
      const del = cameraAction('Delete', async () => {
        const choice = await messageBox({
          title: `Delete ${e.name}?`,
          message: 'The file is removed from the device.',
          buttons: ['Cancel', 'Delete'],
        });
        if (choice !== 'Delete') return;
        await cmd('fileDelete', { root: filesState.root, path: rel });
        refreshList();
      }, false, 'delete');
      list.appendChild(cameraListRow(e.name, desc, [dl, del], { icon: 'doc' }));
    }
  }
  list.scrollTop = 0;
}

export async function loadFiles() {
  const tab = document.getElementById('tab-files');
  let roots = [];
  try { roots = ((await cmd('fileRoots')).data || {}).roots || []; } catch (_) {}
  if (!filesState.root) {
    const shared = roots.find((r) => r.id === 'shared');
    filesState.root = shared && shared.available ? 'shared' : 'app';
  }
  const active = roots.find((r) => r.id === filesState.root);
  if (active && active.available !== true) { filesState.root = 'app'; filesState.crumbs = []; }
  // A tab rebuilt from outside (or the first visit) gets the shell again;
  // otherwise the one on screen is kept and only its contents move.
  if (!shell || shell.tab !== tab || !tab.contains(shell.list)) buildShell(tab);
  paintRoots(roots);
  await refreshList();
}
