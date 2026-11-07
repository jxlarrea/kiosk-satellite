import { cameraAction, cameraListRow } from './cameras.js';
import { api, cmd } from './core.js';
import { readOnlyRow } from './device.js';
import { isHeadless } from './headless.js';
import { filesState } from './notices.js';
import { localizedMessageBox, showToast } from './widgets.js';
import { t, messageLanguage } from './localization.js';

// Refresh visible labels in place, including uploads and open folder contents.
const labels = new WeakMap();
function fileLabel(element, render, property = 'textContent') {
  const record = labels.get(element) || {};
  record[property] = render;
  labels.set(element, record);
  element.dataset.fileLabel = '';
  element[property] = render();
  if (property === 'title') element.setAttribute('aria-label', element.title);
  return element;
}
function textLabel(element, id) { return fileLabel(element, () => t(id)); }
function fileError(error) {
  const fixed = {'invalid path':'filesInvalidPath', 'no such folder':'filesNoFolder',
    'no such file':'filesNoFile', 'could not read the folder':'filesReadFailed',
    'device unreachable':'logsDeviceUnreachable'};
  if (Object.hasOwn(fixed, error)) return t(fixed[error]);
  for (const [prefix, id] of [['cannot read folder: ', 'filesReadError'], ['write failed: ', 'filesWriteError']]) {
    if (error.startsWith(prefix)) return t(id, {error:error.slice(prefix.length)});
  }
  return error;
}
document.addEventListener('ks-settings-cached', () => {
  document.querySelectorAll('[data-file-label]').forEach(element => {
    for (const [property, render] of Object.entries(labels.get(element) || {})) {
      element[property] = render();
      if (property === 'title') element.setAttribute('aria-label', element.title);
    }
  });
});

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
  textLabel(uploadBtn, 'filesUpload');
  uploadBtn.style.cssText = 'flex-shrink:0; margin-left:auto;';
  const picker = document.createElement('input');
  picker.type = 'file';
  picker.multiple = true;
  picker.hidden = true;
  // The endpoint takes one file per request, so a multiple pick goes up
  // one file after another into the folder that was open at the pick,
  // even if the person browses away meanwhile. One toast sums it up.
  picker.addEventListener('change', async () => {
    const files = [...(picker.files || [])];
    picker.value = '';
    if (!files.length) return;
    const root = filesState.root;
    const crumbs = [...filesState.crumbs];
    uploadBtn.disabled = true;
    const failures = [];
    for (const [i, file] of files.entries()) {
      if (files.length > 1) {
        fileLabel(uploadBtn, () => t('filesUploadingProgress', {current:String(i + 1), total:String(files.length)}));
      } else {
        textLabel(uploadBtn, 'filesUploading');
      }
      const target = [...crumbs, file.name].join('/');
      try {
        const q = `root=${encodeURIComponent(root)}&path=${encodeURIComponent(target)}`;
        const res = await api(`/api/files/upload?${q}`, { method: 'POST', body: file });
        if (!res.ok) {
          failures.push({ name: file.name,
            error: fileError(((await res.json().catch(() => null)) || {}).error || String(res.status)) });
        }
      } catch (e) {
        failures.push({ name: file.name, error: String(e) });
      }
    }
    if (files.length === 1) {
      if (failures.length) showToast({ title: t('filesUploadFailed'), message: failures[0].error, kind: 'error' });
      else showToast({ title: t('filesUploaded'), message: files[0].name, kind: 'success' });
    } else if (failures.length) {
      showToast({ title: t('filesUploadFailed'),
        message: failures.map((f) => `${f.name}: ${f.error}`).join(' · '),
        kind: 'error', duration: 8000 });
    } else {
      showToast({ title: t('filesUploadedCount', {count:String(files.length)}), kind: 'success' });
    }
    uploadBtn.disabled = false;
    textLabel(uploadBtn, 'filesUpload');
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
  const grantRow = readOnlyRow('', '', '', false);
  textLabel(grantRow.querySelector('.name'), 'filesPermissionMissing');
  // Without a screen the grant comes over adb: the command stands in for
  // the button, as on the Permissions page.
  textLabel(grantRow.querySelector('.desc'), isHeadless() ? 'deviceHeadlessAdbStorage' : 'filesPermissionHelp');
  if (isHeadless()) grantRow.querySelector('.desc').style.userSelect = 'all';
  const grantBtn = document.createElement('button');
  grantBtn.className = 'btn-ghost';
  textLabel(grantBtn, 'filesGrant');
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
  if (!isHeadless()) grantRow.appendChild(grantBtn);
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
  fileLabel(up, () => t('filesUp'), 'title');
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
      fileLabel(b, () => r.id === 'shared' ? t('filesShared')
        : r.id === 'app' ? t('filesApp') : r.label);
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
    const row = readOnlyRow('', '', '', false);
    fileLabel(row.querySelector('.name'), () => fileError(listErr));
    list.appendChild(row);
  } else if (!entries.length) {
    const row = readOnlyRow('', '', '', false);
    textLabel(row.querySelector('.name'), 'filesEmpty');
    textLabel(row.querySelector('.desc'), 'filesEmptyHelp');
    list.appendChild(row);
  } else {
    for (const e of entries) {
      const desc = e.dir ? 'Folder'
        : `${fileSizeLabel(e.size || 0)} · ${new Date(e.modified || 0).toLocaleString(messageLanguage())}`;
      if (e.dir) {
        const row = cameraListRow(e.name, desc, [], {
          icon: 'folder',
          onClick: () => { filesState.crumbs.push(e.name); refreshList(); },
        });
        textLabel(row.querySelector('.desc'), 'filesFolder');
        list.appendChild(row);
        continue;
      }
      const rel = [...filesState.crumbs, e.name].join('/');
      const dl = cameraAction('Download', async () => {
        dl.disabled = true;
        try {
          const q = `root=${encodeURIComponent(filesState.root)}&path=${encodeURIComponent(rel)}`;
          const res = await api(`/api/files/download?${q}`);
          if (!res.ok) throw new Error(((await res.json()) || {}).error || String(res.status));
          const blob = await res.blob();
          const a = document.createElement('a');
          a.href = URL.createObjectURL(blob);
          a.download = e.name;
          a.click();
          URL.revokeObjectURL(a.href);
        } catch (err) {
          showToast({ title: t('filesDownloadFailed'), message: fileError(String(err.message || err)), kind: 'error' });
        }
        dl.disabled = false;
      }, false, 'download');
      const del = cameraAction('Delete', async () => {
        const choice = await localizedMessageBox({
          titleId: 'filesDeleteTitle', messageId: 'filesDeleteHelp', values: {name:e.name},
          buttons: [{id:'commonCancel', value:'Cancel'}, {id:'commonDelete', value:'Delete'}],
        });
        if (choice !== 'Delete') return;
        try {
          const result = await cmd('fileDelete', { root: filesState.root, path: rel });
          if (!result.ok) throw new Error(result.error || t('filesDeleteFailed'));
          refreshList();
        } catch (error) {
          showToast({title:t('filesDeleteFailed'), message:fileError(String(error.message || error)), kind:'error'});
        }
      }, false, 'delete');
      fileLabel(dl, () => t('filesDownload'), 'title');
      fileLabel(del, () => t('commonDelete'), 'title');
      const row = cameraListRow(e.name, desc, [dl, del], { icon: 'doc' });
      fileLabel(row.querySelector('.desc'), () => `${fileSizeLabel(e.size || 0)} · ${new Date(e.modified || 0).toLocaleString(messageLanguage())}`);
      list.appendChild(row);
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
