import { cameraAction, cameraListRow } from './cameras.js';
import { api, cmd } from './core.js';
import { readOnlyRow } from './device.js';
import { filesState } from './notices.js';

export function fileSizeLabel(bytes) {
  if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(1) + ' GB';
  if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + ' MB';
  if (bytes >= 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return bytes + ' B';
}

export async function loadFiles() {
  const tab = document.getElementById('tab-files');
  tab.innerHTML = '<div class="card"><div class="desc" style="color:var(--muted)">Reading…</div></div>';
  let roots = [];
  try { roots = ((await cmd('fileRoots')).data || {}).roots || []; } catch (_) {}
  if (!filesState.root) {
    const shared = roots.find((r) => r.id === 'shared');
    filesState.root = shared && shared.available ? 'shared' : 'app';
  }
  const active = roots.find((r) => r.id === filesState.root);
  if (active && active.available !== true) { filesState.root = 'app'; filesState.crumbs = []; }
  const relPath = filesState.crumbs.join('/');
  let entries = null; let listErr = null;
  try {
    const res = await cmd('fileList', { root: filesState.root, path: relPath });
    if (res.ok) entries = (res.data || {}).entries || [];
    else listErr = res.error || 'could not read the folder';
  } catch (_) { listErr = 'device unreachable'; }

  tab.innerHTML = '';

  // Root tabs on the left, upload on the right, bare on the page like the
  // Logs source picker — the tabs say what they are, so no card and no
  // label. On a phone the wrap drops the upload button to its own line,
  // still right-aligned thanks to the auto margin.
  const pick = document.createElement('div'); pick.className = 'toolbar';
  pick.style.cssText = 'flex-wrap:wrap;';
  const rootSeg = document.createElement('div');
  rootSeg.className = 'seg';
  rootSeg.style.cssText = 'flex-shrink:0;';
  for (const r of roots) {
    const b = document.createElement('button');
    b.textContent = r.label;
    if (r.id === filesState.root) b.classList.add('active');
    b.disabled = r.available !== true;
    b.addEventListener('click', () => {
      filesState.root = r.id; filesState.crumbs = []; loadFiles();
    });
    rootSeg.appendChild(b);
  }
  pick.appendChild(rootSeg);
  const uploadBtn = document.createElement('button');
  uploadBtn.className = 'btn-ghost';
  uploadBtn.textContent = 'Upload file';
  uploadBtn.style.cssText = 'flex-shrink:0; margin-left:auto;';
  const picker = document.createElement('input');
  picker.type = 'file'; picker.hidden = true;
  picker.addEventListener('change', async () => {
    const file = picker.files && picker.files[0];
    if (!file) return;
    uploadBtn.disabled = true;
    uploadBtn.textContent = 'Uploading…';
    const target = [...filesState.crumbs, file.name].join('/');
    try {
      const q = `root=${encodeURIComponent(filesState.root)}&path=${encodeURIComponent(target)}`;
      const res = await api(`/api/files/upload?${q}`, { method: 'POST', body: file });
      if (!res.ok) alert('Upload failed: ' + (((await res.json()) || {}).error || res.status));
    } catch (e) { alert('Upload failed: ' + e); }
    picker.value = '';
    loadFiles();
  });
  uploadBtn.addEventListener('click', () => picker.click());
  pick.appendChild(uploadBtn);
  pick.appendChild(picker);
  tab.appendChild(pick);

  // Shared storage gated: the grant screen lives on the device.
  const shared = roots.find((r) => r.id === 'shared');
  if (shared && shared.grantNeeded) {
    const row = readOnlyRow('"All files access" permission missing',
      'Without it only the app folder can be browsed. The grant screen opens on the tablet.', '');
    const btn = document.createElement('button');
    btn.className = 'btn-ghost';
    btn.textContent = 'Grant on device';
    btn.style.cssText = 'flex-shrink:0;';
    btn.addEventListener('click', async () => {
      btn.disabled = true;
      try { await cmd('requestAllFilesAccess'); } catch (_) {}
      for (let i = 0; i < 30; i++) {
        await new Promise((r) => setTimeout(r, 2500));
        try {
          const res = await cmd('fileRoots');
          const sh = ((res.data || {}).roots || []).find((r) => r.id === 'shared');
          if (sh && sh.available) { loadFiles(); return; }
        } catch (_) {}
      }
      btn.disabled = false;
    });
    row.appendChild(btn);
    const grantCard = document.createElement('div');
    grantCard.className = 'card';
    grantCard.appendChild(row);
    tab.appendChild(grantCard);
  }

  // Listing card: breadcrumb row, then the entries.
  const card = document.createElement('div'); card.className = 'card';
  const crumb = readOnlyRow('/' + filesState.crumbs.join('/'), '', '');
  if (filesState.crumbs.length) {
    const up = document.createElement('button');
    up.className = 'btn-ghost';
    up.title = 'Up one folder';
    up.setAttribute('aria-label', 'Up one folder');
    up.innerHTML = '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display:block"><path d="M12 19V5"/><path d="m5 12 7-7 7 7"/></svg>';
    up.style.cssText = 'width:auto; padding:8px 12px; flex-shrink:0;';
    up.addEventListener('click', () => { filesState.crumbs.pop(); loadFiles(); });
    crumb.appendChild(up);
  }
  card.appendChild(crumb);
  if (listErr) {
    card.appendChild(readOnlyRow(listErr, '', ''));
  } else if (!entries.length) {
    card.appendChild(readOnlyRow('Empty folder', '', ''));
  } else {
    for (const e of entries) {
      const desc = e.dir ? 'Folder'
        : `${fileSizeLabel(e.size || 0)} · ${new Date(e.modified || 0).toLocaleString()}`;
      if (e.dir) {
        card.appendChild(cameraListRow(e.name, desc, [], {
          icon: 'folder',
          onClick: () => { filesState.crumbs.push(e.name); loadFiles(); },
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
        } catch (err) { alert('Download failed: ' + err); }
        dl.disabled = false;
      }, false, 'download');
      const del = cameraAction('Delete', async () => {
        if (!confirm(`Delete ${e.name}?`)) return;
        await cmd('fileDelete', { root: filesState.root, path: rel });
        loadFiles();
      }, false, 'delete');
      card.appendChild(cameraListRow(e.name, desc, [dl, del], { icon: 'doc' }));
    }
  }
  tab.appendChild(card);
}
