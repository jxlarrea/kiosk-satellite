import { cmd } from './core.js';
import { modalShell } from './widgets.js';

/* ---- Media browser (screensaver) ---- */
// A modal that walks the Home Assistant media tree over haBrowseMedia, the
// same command and the same shape the device's native picker uses. Resolves to
// the chosen media-source id, or null if cancelled.
// The two questions a configuration import must ask (issue #25): does this
// device become the backup's device (name + MQTT identity) or stay itself,
// and does the page's saved data (which carries the Voice Satellite
// selection) come along. Resolves {adopt, local} or null on cancel. The
// checkbox default follows the choice until the user touches it.
export function askImportOptions(backupName) {
  return new Promise((resolve) => {
    const { back, body, foot } = modalShell({
      title: 'Import configuration',
      width: 460,
      onDismiss: () => close(null),
    });
    const close = (val) => { back.remove(); resolve(val); };

    let adopt = false;
    let local = false;
    let localTouched = false;
    const replaceLabel = backupName && backupName.trim()
      ? `Replace "${backupName.trim()}"` : 'Replace the original device';

    body.innerHTML = `
      <div style="font-size:13.5px; margin-bottom:12px">Replace this device's settings with the file's? The page may reload.</div>
      <label style="display:block; margin-bottom:8px"><input type="radio" name="impid"> Set up as new device<div class="desc" style="margin-left:22px">Assign its own name and MQTT identity, so both devices are unique.</div></label>
      <label style="display:block; margin-bottom:12px"><input type="radio" name="impid"> <span id="impReplaceLbl"></span><div class="desc" style="margin-left:22px">Keeps the backup's name and MQTT identity; the original device must stay offline.</div></label>
      <label style="display:block"><input type="checkbox" id="impLocal"> Restore Webview's local storage<div class="desc" style="margin-left:22px">Includes the Home Assistant signed in session and the Voice Satellite assist_satellite selection - two devices must not share one satellite.</div></label>`;
    body.querySelector('#impReplaceLbl').textContent = replaceLabel;
    const radios = body.querySelectorAll('input[type=radio]');
    const localCb = body.querySelector('#impLocal');
    radios[0].checked = true;
    radios.forEach((r, i) => r.addEventListener('change', () => {
      adopt = i === 1;
      if (!localTouched) { local = adopt; localCb.checked = adopt; }
    }));
    localCb.addEventListener('change', () => {
      local = localCb.checked;
      localTouched = true;
    });
    const cancel = document.createElement('button');
    cancel.className = 'btn-text';
    cancel.textContent = 'Cancel';
    cancel.addEventListener('click', () => close(null));
    const go = document.createElement('button');
    go.className = 'btn-primary';
    go.textContent = 'Import';
    go.addEventListener('click', () => close({ adopt, local }));
    foot.append(cancel, go);
  });
}

export function openMediaBrowser() {
  return new Promise((resolve) => {
    const trail = [{ id: undefined, title: 'Media' }];

    const shell = modalShell({
      title: 'Media',
      width: 520,
      onDismiss: () => close(null),
    });
    const close = (val) => { shell.close(); resolve(val); };

    // The breadcrumb trail stays visible above the scrolling list.
    const crumbs = document.createElement('div');
    crumbs.style.cssText =
      'flex:none; font-size:13px; color:var(--muted); margin-bottom:10px';
    shell.card.insertBefore(crumbs, shell.body);
    const list = shell.body;
    const foot = shell.foot;

    async function open(id, title, push) {
      if (push) trail.push({ id, title });
      crumbs.textContent = trail.map((c) => c.title).join('  ›  ');
      list.innerHTML = '<div class="desc" style="color:var(--muted)">Loading…</div>';
      let node;
      try {
        const r = await cmd('haBrowseMedia', id ? { mediaContentId: id } : {});
        if (!r.ok) throw new Error(r.error || 'browse failed');
        node = r.data;
      } catch (e) {
        list.innerHTML = `<div class="desc" style="color:var(--error)">Could not browse: ${e}</div>`;
        return;
      }
      list.innerHTML = '';
      for (const c of (node.children || [])) {
        const r = document.createElement('div'); r.className = 'row';
        const info = document.createElement('div'); info.className = 'info';
        const isCam = (c.media_content_id || '').startsWith('media-source://camera/');
        info.innerHTML = `<div class="name"></div><div class="desc"></div>`;
        info.querySelector('.name').textContent = c.title;
        info.querySelector('.desc').textContent =
          c.can_expand ? 'folder' : isCam ? 'camera' : (c.media_content_type || 'item');
        r.appendChild(info);
        r.style.cursor = 'pointer';
        r.addEventListener('click', () => {
          if (c.can_expand) open(c.media_content_id, c.title, true);
          else if (c.can_play) close({ id: c.media_content_id, isFolder: false });
        });
        list.appendChild(r);
      }
      if (!node.children || !node.children.length)
        list.innerHTML = '<div class="desc" style="color:var(--muted)">Nothing here.</div>';

      foot.innerHTML = '';
      const cancel = document.createElement('button');
      cancel.className = 'btn-text'; cancel.textContent = 'Cancel';
      cancel.addEventListener('click', () => close(null));
      const spacer = document.createElement('span'); spacer.className = 'spacer';
      foot.append(cancel, spacer);
      if (trail.length > 1 && node.can_expand) {
        const useFolder = document.createElement('button');
        useFolder.className = 'btn-ghost'; useFolder.textContent = 'Use this folder';
        useFolder.addEventListener('click', () => close({ id: node.media_content_id, isFolder: true }));
        foot.appendChild(useFolder);
      }
    }
    open(undefined, 'Media', false);
  });
}

// The launcher whitelist picker: every launchable app on the device with a
// checkbox, resolving to the chosen [{package, label}] or null on cancel.
// Saving rebuilds the value from the device's list, so labels refresh and
// uninstalled leftovers drop out, same as the on-device picker.
export function openLauncherAppsPicker(current) {
  return new Promise((resolve) => {
    const selected = new Set((current || []).map((a) => a.package));

    const shell = modalShell({
      title: 'Apps',
      width: 520,
      onDismiss: () => close(null),
    });
    const close = (val) => { shell.close(); resolve(val); };
    const list = shell.body;
    list.innerHTML = '<div class="desc" style="color:var(--muted)">Loading…</div>';

    const cancel = document.createElement('button');
    cancel.className = 'btn-text'; cancel.textContent = 'Cancel';
    cancel.addEventListener('click', () => close(null));
    const okBtn = document.createElement('button');
    okBtn.className = 'btn-primary'; okBtn.textContent = 'Save'; okBtn.disabled = true;
    shell.foot.append(cancel, okBtn);

    (async () => {
      let apps = [];
      try {
        const r = await cmd('installedApps');
        if (!r.ok) throw new Error(r.error || 'listing failed');
        apps = r.data || [];
      } catch (e) {
        list.innerHTML = `<div class="desc" style="color:var(--error)">Could not list the apps: ${e}</div>`;
        return;
      }
      list.innerHTML = '';
      for (const app of apps) {
        const r = document.createElement('label');
        r.className = 'row';
        r.style.cursor = 'pointer';
        const info = document.createElement('div'); info.className = 'info';
        info.innerHTML = `<div class="name"></div><div class="desc"></div>`;
        info.querySelector('.name').textContent = app.label;
        info.querySelector('.desc').textContent = app.package;
        const box = document.createElement('input');
        box.type = 'checkbox';
        box.checked = selected.has(app.package);
        box.addEventListener('change', () => {
          if (box.checked) selected.add(app.package);
          else selected.delete(app.package);
        });
        // The checkbox leads the row, the whole row toggles it.
        r.append(box, info);
        list.appendChild(r);
      }
      if (!apps.length) {
        list.innerHTML = '<div class="desc" style="color:var(--muted)">No launchable apps found.</div>';
        return;
      }
      okBtn.disabled = false;
      okBtn.addEventListener('click', () => close(
        apps.filter((a) => selected.has(a.package))
          .map((a) => ({ package: a.package, label: a.label })),
      ));
    })();
  });
}
