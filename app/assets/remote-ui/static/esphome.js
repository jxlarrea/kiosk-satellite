import { cmd } from './core.js';
import { modalShell } from './widgets.js';

export function openEspHomeEntityPicker(current) {
  return new Promise((resolve) => {
    const selected = new Set(current);
    const shell = modalShell({
      title: 'Excluded entities',
      width: 560,
      onDismiss: () => close(null),
    });
    const close = (value) => { shell.close(); resolve(value); };
    shell.card.style.minWidth = '0';
    const note = document.createElement('p');
    note.className = 'desc';
    note.textContent = 'Pick entities to exclude from Home Assistant. All other available '
      + 'entities are exposed. Saving reconnects ESPHome.';
    const search = document.createElement('input');
    search.type = 'search';
    search.className = 'field';
    search.placeholder = 'Search entities';
    search.setAttribute('aria-label', 'Search entities');
    const list = document.createElement('div');
    list.textContent = 'Loading entities…';
    shell.body.append(note, search, list);
    const clear = document.createElement('button');
    clear.className = 'btn-text';
    clear.textContent = 'Clear';
    clear.disabled = true;
    const selectAll = document.createElement('button');
    selectAll.className = 'btn-text';
    selectAll.textContent = 'Select all';
    selectAll.disabled = true;
    const cancel = document.createElement('button');
    cancel.className = 'btn-text';
    cancel.textContent = 'Cancel';
    cancel.addEventListener('click', () => close(null));
    const save = document.createElement('button');
    save.className = 'btn-primary';
    save.textContent = 'Save';
    save.disabled = true;
    save.addEventListener('click', () => close([...selected].sort()));
    shell.foot.style.flexWrap = 'wrap';
    shell.foot.append(selectAll, clear, cancel, save);

    (async () => {
      try {
        const result = await cmd('getEspHomeEntities');
        if (!result.ok || !Array.isArray(result.data)) throw new Error('Could not load entities');
        const entities = result.data.map((entity) => ({
          id: entity.objectId, name: entity.name,
          detail: [entity.categoryLabel, entity.type.replaceAll('_', ' ')].filter(Boolean).join(' · '),
        }));
        const available = new Set(entities.map((entity) => entity.id));
        for (const id of selected) {
          if (!available.has(id)) entities.push({ id, name: id, detail: 'Currently unavailable' });
        }
        entities.sort((a, b) => a.name.localeCompare(b.name));
        const render = () => {
          list.replaceChildren();
          const query = search.value.trim().toLowerCase();
          for (const entity of entities) {
            if (!`${entity.name} ${entity.id} ${entity.detail}`.toLowerCase().includes(query)) continue;
            const row = document.createElement('label');
            row.className = 'row';
            const box = document.createElement('input');
            box.type = 'checkbox';
            box.checked = selected.has(entity.id);
            box.addEventListener('change', () => {
              if (box.checked) selected.add(entity.id);
              else selected.delete(entity.id);
            });
            const info = document.createElement('div');
            info.className = 'info';
            const name = document.createElement('div');
            name.className = 'name';
            name.textContent = entity.name;
            const type = document.createElement('div');
            type.className = 'desc';
            type.textContent = entity.detail;
            info.append(name, type);
            row.append(box, info);
            list.append(row);
          }
          if (!list.childElementCount) list.textContent = 'No matching entities';
        };
        search.addEventListener('input', render);
        clear.addEventListener('click', () => { selected.clear(); render(); });
        selectAll.addEventListener('click', () => {
          entities.forEach((entity) => selected.add(entity.id));
          render();
        });
        render();
        clear.disabled = false;
        selectAll.disabled = false;
        save.disabled = false;
      } catch (_) {
        list.textContent = 'Could not load entities. Close the picker and try again.';
      }
    })();
  });
}
