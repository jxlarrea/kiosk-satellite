import { t } from './localization.js';
import { cmd } from './core.js';
import { showToast } from './widgets.js';

/* ---- Music picker ----
   Choose music from the library for a feature, an alarm for one: a track,
   an album, a playlist, an artist, a station or a random draw, from Music
   Assistant, Home Assistant or Sonos, and the speaker it plays on. The
   device's picker (lib/ui/music_picker.dart) drawn the same way: a 1080 by
   720 dialog on a desktop, full screen below 900 by 620, one column with
   the source and speaker on their own row under 600. The device lists and
   plays everything through the libraryPicker commands, and fetches the
   covers, which a browser could not load from a self-signed server.

   pickMusic({ current }) resolves to the pick, or null when cancelled. */

const STROKE = 'viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"';
const ICONS = {
  ma: 'M5 4v16M9.5 4v16M14 5.5l4.5 14.5',
  ha: 'M4 11l8-7 8 7M6 9.5V20h12V9.5M10 20v-5h4v5',
  sonos: 'M7 3h10a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1zM12 11a3 3 0 1 0 0 6a3 3 0 1 0 0-6zM12 6.5v.01',
  speaker: 'M7 3h10a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1zM12 11a3 3 0 1 0 0 6a3 3 0 1 0 0-6zM12 6.5v.01',
  device: 'M5 5.5A1.5 1.5 0 0 1 6.5 4h11A1.5 1.5 0 0 1 19 5.5v13a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 5 18.5zM10.5 17h3',
  volume: 'M4 9.5h3.5L12 5.5v13l-4.5-4H4zM16 9a4 4 0 0 1 0 6M18.5 6.5a7.5 7.5 0 0 1 0 11',
  search: 'M11 4a7 7 0 1 0 0 14a7 7 0 1 0 0-14zM20 20l-4-4',
  close: 'M6 6l12 12M18 6L6 18',
  chevDown: 'M6 9l6 6 6-6',
  chevRight: 'M9 6l6 6-6 6',
  back: 'M15 5l-7 7 7 7',
  check: 'M5 12.5l4.5 4.5L19 7.5',
  play: 'M7.5 5.5v13l11-6.5z',
  stop: 'M6.5 6.5h11v11h-11z',
  random: 'M4 7h3c3 0 4.5 1.5 6 5s3 5 6 5h1M17 14l3 3-3 3M4 17h3c1.4 0 2.5-.4 3.3-1M13.7 8c.8-.6 1.9-1 3.3-1h3M17 4l3 3-3 3',
  browse: 'M3.5 7.5a2 2 0 0 1 2-2h4l2 2h7a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2h-13a2 2 0 0 1-2-2z',
  folder: 'M3.5 7.5a2 2 0 0 1 2-2h4l2 2h7a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2h-13a2 2 0 0 1-2-2z',
  artists: 'M12 4a4 4 0 1 0 0 8a4 4 0 1 0 0-8zM4.5 20a7.5 7.5 0 0 1 15 0',
  albums: 'M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18zM12 10a2 2 0 1 0 0 4a2 2 0 1 0 0-4z',
  tracks: 'M9 17.5V5.5l10-2v12M9 17.5a2.5 2.5 0 1 1-5 0a2.5 2.5 0 1 1 5 0zM19 15.5a2.5 2.5 0 1 1-5 0a2.5 2.5 0 1 1 5 0z',
  playlists: 'M4 6h12M4 11h12M4 16h7M18 9v8.5M18 17.5a2 2 0 1 1-4 0a2 2 0 1 1 4 0zM18 9l3-1',
  radios: 'M4 9h16v11H4zM8 9l9-5M6.5 14.5a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0-3 0M13 13h4M13 16h4',
  favorites: 'M12 20s-7.5-4.5-7.5-10A4.5 4.5 0 0 1 12 7a4.5 4.5 0 0 1 7.5 3c0 5.5-7.5 10-7.5 10z',
  podcasts: 'M12 3a3 3 0 0 0-3 3v5a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3zM6 11a6 6 0 0 0 12 0M12 17v4M9 21h6',
  audiobooks: 'M5 4.5A1.5 1.5 0 0 1 6.5 3H19v15H6.5A1.5 1.5 0 0 0 5 19.5zM5 19.5A1.5 1.5 0 0 0 6.5 21H19',
};
ICONS.radio = ICONS.radios;
ICONS.sonos_playlists = ICONS.playlists;
const RANDOM_ICONS = { tracks: ICONS.tracks, favorites: ICONS.favorites, playlists: ICONS.playlists, albums: ICONS.albums, radio: ICONS.radios };
const KIND_ICONS = { artist: ICONS.artists, album: ICONS.albums, track: ICONS.tracks, playlist: ICONS.playlists, radio: ICONS.radios, folder: ICONS.folder };

const svg = (path, size = 22) => `<svg ${STROKE} width="${size}" height="${size}"><path d="${path}"/></svg>`;

const el = (tag, cls, text) => {
  const node = document.createElement(tag);
  if (cls) node.className = cls;
  if (text != null) node.textContent = text;
  return node;
};

const sourceName = (k) => t(k === 'ha' ? 'librarySourceHa' : k === 'sonos' ? 'librarySourceSonos' : 'librarySourceMa');
const sourceHint = (k) => t(k === 'ha' ? 'librarySourceHaHint' : k === 'sonos' ? 'librarySourceSonosHint' : 'librarySourceMaHint');

function viewName(key) {
  return ({
    random: t('musicPickerRandom'), browse: t('libraryBrowse'), search: t('librarySearch'),
    artists: t('libraryArtists'), albums: t('libraryAlbums'), tracks: t('libraryTracks'),
    playlists: t('libraryPlaylists'), radios: t('libraryRadio'), radio: t('libraryRadio'),
    podcasts: t('libraryPodcasts'), audiobooks: t('libraryAudiobooks'), favorites: t('libraryFavorites'),
    sonos_playlists: t('librarySonosPlaylists'),
  })[key] || key;
}

function kindName(kind) {
  return ({
    artist: t('libraryKindArtist'), album: t('libraryKindAlbum'), track: t('libraryKindTrack'),
    playlist: t('libraryKindPlaylist'), radio: t('libraryKindRadio'), podcast: t('libraryKindPodcast'),
    episode: t('libraryKindEpisode'), audiobook: t('libraryKindAudiobook'), genre: t('libraryKindGenre'),
    folder: t('musicPickerKindFolder'),
  })[kind] || '';
}

export function randomName(r) {
  return ({
    tracks: t('musicPickerAnyTrack'), favorites: t('musicPickerAnyFavorite'), playlists: t('musicPickerAnyPlaylist'),
    albums: t('musicPickerAnyAlbum'), radio: t('musicPickerAnyStation'),
  })[r] || r;
}

/** What a pick is called on a row that shows it. */
export function musicPickName(pick) {
  return pick?.item?.title || (pick?.random ? randomName(pick.random) : '');
}

function wholeName(item) {
  switch (item.kind) {
    case 'album': return t('musicPickerWholeAlbum');
    case 'playlist': return t('musicPickerWholePlaylist');
    case 'artist': return t('musicPickerWholeArtist', { name: item.title });
    case 'folder': return t('musicPickerWholeFolder');
    default: return t('musicPickerAllTracks');
  }
}

const canShuffle = (item, random) => random
  ? random === 'playlists' || random === 'albums'
  : ['album', 'playlist', 'artist', 'folder', 'podcast', 'audiobook'].includes(item?.kind);

function trackLength(ms) {
  if (!ms || ms <= 0) return '';
  const total = Math.floor(ms / 1000);
  const h = Math.floor(total / 3600), m = Math.floor((total % 3600) / 60), s = String(total % 60).padStart(2, '0');
  return h > 0 ? `${h}:${String(m).padStart(2, '0')}:${s}` : `${m}:${s}`;
}

/* ---- covers ----
   Fetched through the device, a few at a time, kept for the session. */
const covers = new Map();
const coverQueue = [];
let coversRunning = 0;

function cover(url) {
  if (!covers.has(url)) {
    covers.set(url, new Promise((resolve) => {
      coverQueue.push(async () => {
        try {
          const r = await cmd('libraryArt', { url });
          resolve(r && r.ok !== false && r.data?.data ? `data:image/*;base64,${r.data.data}` : null);
        } catch (_) {
          resolve(null);
        }
      });
      pumpCovers();
    }));
  }
  return covers.get(url);
}

function pumpCovers() {
  while (coversRunning < 6 && coverQueue.length) {
    const job = coverQueue.shift();
    coversRunning++;
    job().finally(() => { coversRunning--; pumpCovers(); });
  }
}

function art(item, size, cls = '') {
  const box = el('span', `mp-art ${cls}`);
  box.style.width = box.style.height = `${size}px`;
  if (item?.kind === 'artist') box.classList.add('round');
  box.innerHTML = svg(KIND_ICONS[item?.kind] || ICONS.tracks, Math.round(size * 0.45));
  const url = item?.art;
  if (url) {
    cover(url).then((src) => {
      if (!src) return;
      const img = el('img');
      img.alt = '';
      img.src = src;
      box.replaceChildren(img);
    });
  }
  return box;
}

function disc(path, size, filled = false) {
  const box = el('span', `mp-disc${filled ? ' filled' : ''}`);
  box.style.width = box.style.height = `${size}px`;
  box.innerHTML = svg(path);
  return box;
}

async function call(name, params) {
  try {
    const r = await cmd(name, params);
    return r && r.ok !== false ? { ok: true, data: r.data || {} } : { ok: false, error: r?.error || '' };
  } catch (e) {
    return { ok: false, error: String(e.message || e) };
  }
}

export function pickMusic({ current = null } = {}) {
  return new Promise((resolve) => {
    const st = {
      sources: [], source: '', speakers: [], note: '', speaker: '', speakerName: '', followed: '',
      categories: [], randoms: [], search: false, browse: false,
      view: '', trail: [], rows: [], more: false, loading: true, error: '', gen: 0,
      query: '', kind: 'all',
      item: current?.item || null, random: current?.item ? null : current?.random || null,
      shuffle: current?.shuffle === true,
      previewing: false, previewBusy: false, menu: null,
    };

    const back = el('div', 'mp-back');
    const card = el('div', 'mp');
    card.setAttribute('role', 'dialog');
    card.setAttribute('aria-modal', 'true');
    card.setAttribute('aria-label', t('musicPickerTitle'));
    back.appendChild(card);
    document.body.appendChild(back);
    const openedAt = Date.now();
    back.addEventListener('click', (e) => {
      if (e.target === back && Date.now() - openedAt > 500) finish(null);
    });

    const size = () => (innerWidth >= 900 && innerHeight >= 620 ? 'wide' : innerWidth < 600 ? 'narrow' : 'short');
    let lastSize = size();
    const onResize = () => { if (size() !== lastSize) { lastSize = size(); render(); } };
    addEventListener('resize', onResize);
    const onKey = (e) => {
      if (e.key !== 'Escape') return;
      if (st.menu) { st.menu = null; render(); } else finish(null);
    };
    addEventListener('keydown', onKey);

    async function finish(pick) {
      removeEventListener('resize', onResize);
      removeEventListener('keydown', onKey);
      if (st.previewing) call('musicPickStop', { owner: 'preview' });
      back.remove();
      resolve(pick);
    }

    const viewKeys = () => [
      ...(st.randoms.length ? ['random'] : []),
      ...(st.browse ? ['browse'] : []),
      ...st.categories.map((c) => c.key),
    ];
    const hasSpeaker = () => st.speakers.some((s) => s.pick === st.speaker);
    const pick = () => (st.item || st.random ? {
      source: st.source,
      ...(st.item ? { item: st.item } : { random: st.random }),
      shuffle: st.shuffle && canShuffle(st.item, st.random),
      speaker: st.speaker,
      speakerName: st.speakerName,
    } : null);

    async function loadSource(key, keep) {
      const gen = ++st.gen;
      Object.assign(st, { loading: true, error: '', rows: [], trail: [] });
      render();
      const info = await call('libraryPickerSource', { source: key, speaker: keep ?? '' });
      if (gen !== st.gen) return;
      if (!info.ok) {
        Object.assign(st, { loading: false, error: info.error === 'no_source' ? 'no_source' : info.error });
        render();
        return;
      }
      const d = info.data;
      st.sources = d.sources || [];
      st.source = d.source;
      st.followed = d.followed || '';
      st.speakers = d.speakers || [];
      st.note = d.note || '';
      const usable = st.speakers.filter((s) => s.available);
      const sp = usable.find((s) => s.pick === keep) || usable.find((s) => s.self)
        || usable.find((s) => s.pick === st.followed) || usable[0];
      st.speaker = sp?.pick ?? '';
      st.speakerName = sp?.name ?? '';
      st.categories = d.categories || [];
      st.randoms = d.random || [];
      st.search = d.search === true;
      st.browse = d.browse === true;
      // A Home Assistant tree belongs to the speaker, which the first read
      // could not know.
      if (st.source === 'ha' && st.speaker !== (keep ?? '')) {
        await call('libraryPickerSource', { source: key, speaker: st.speaker });
      }
      const views = viewKeys();
      const wanted = st.random && st.randoms.includes(st.random) ? 'random'
        : views.includes('playlists') ? 'playlists'
          : views.includes('favorites') ? 'favorites' : views[0] || '';
      await open(wanted);
    }

    async function open(view) {
      st.view = view;
      st.trail = [];
      await reload();
    }

    async function reload(more = false) {
      const gen = ++st.gen;
      st.loading = true;
      st.error = '';
      if (!more) { st.rows = []; st.more = false; }
      render();
      const base = { source: st.source, speaker: st.speaker };
      let out = { ok: true, data: { items: [] } };
      if (st.trail.length) {
        out = await call('libraryPickerOpen', { ...base, item: st.trail[st.trail.length - 1] });
      } else if (st.view === 'browse') {
        out = await call('libraryPickerBrowse', base);
      } else if (st.view === 'search') {
        if (st.query.trim()) out = await call('libraryPickerSearch', { ...base, query: st.query.trim() });
      } else if (st.view !== 'random') {
        out = await call('libraryPickerList', { ...base, category: st.view, offset: more ? st.rows.length : 0 });
      }
      if (gen !== st.gen) return;
      st.loading = false;
      if (!out.ok) {
        st.error = out.error || 'failed';
      } else {
        const items = out.data.items || [];
        st.rows = more ? [...st.rows, ...items] : items;
        st.more = out.data.more === true;
      }
      render();
    }

    let searchTimer = null;
    function onQuery(value) {
      st.query = value;
      if (st.view !== 'search') { st.view = 'search'; st.trail = []; st.kind = 'all'; }
      clearTimeout(searchTimer);
      searchTimer = setTimeout(() => reload(), 400);
    }

    async function stopPreview() {
      if (!st.previewing) return;
      st.previewing = false;
      render();
      await call('musicPickStop', { owner: 'preview' });
    }

    async function startPreview() {
      const p = pick();
      if (!p || st.previewBusy) return;
      st.previewing = true;
      st.previewBusy = true;
      render();
      const out = await call('musicPickStart', { pick: p, owner: 'preview' });
      st.previewBusy = false;
      if (!out.ok) {
        st.previewing = false;
        showToast({ title: t('musicPickerPreviewFailed'), message: out.error, kind: 'error' });
      }
      render();
    }

    function select(item) {
      if (item.playable === false) return;
      st.item = item;
      st.random = null;
      render();
      if (st.previewing) startPreview();
    }

    function selectRandom(r) {
      st.item = null;
      st.random = r;
      render();
      if (st.previewing) startPreview();
    }

    /* ---- drawing ---- */

    function pill(icon, label, aria, onClick) {
      const b = el('button', 'mp-pill');
      b.type = 'button';
      b.setAttribute('aria-label', aria);
      b.innerHTML = svg(icon, 20);
      b.appendChild(el('span', 'mp-pill-text', label));
      if (onClick) {
        b.setAttribute('aria-haspopup', 'menu');
        b.insertAdjacentHTML('beforeend', svg(ICONS.chevDown, 16).replace('<svg', '<svg class="mp-chev"'));
        b.addEventListener('click', onClick);
      } else {
        b.disabled = true;
      }
      return b;
    }

    function chip(label, on, onClick, icon) {
      const b = el('button', `mp-chip${on ? ' on' : ''}`);
      b.type = 'button';
      b.setAttribute('aria-pressed', on ? 'true' : 'false');
      if (icon) b.innerHTML = svg(icon, 18);
      b.appendChild(el('span', '', label));
      b.addEventListener('click', onClick);
      return b;
    }

    function radio(on) {
      const r = el('span', `mp-radio${on ? ' on' : ''}`);
      r.appendChild(el('span'));
      return r;
    }

    function row({ selected, title, sub, lead, trailing, onClick, onOpen, openLabel, strong, tinted, disabled }) {
      const wrap = el('div', `mp-row${selected ? ' on' : ''}${tinted ? ' tinted' : ''}`);
      const b = el('button', 'mp-row-main');
      b.type = 'button';
      b.setAttribute('aria-pressed', selected ? 'true' : 'false');
      if (disabled) b.disabled = true;
      b.append(radio(selected), lead);
      const text = el('span', 'mp-row-text');
      text.appendChild(el('span', `mp-row-title${strong ? ' strong' : ''}`, title));
      if (sub) text.appendChild(el('span', 'mp-row-sub', sub));
      b.appendChild(text);
      if (trailing) b.appendChild(el('span', 'mp-row-dur', trailing));
      b.addEventListener('click', onClick);
      wrap.appendChild(b);
      if (onOpen) {
        const o = el('button', 'mp-open icon-btn');
        o.type = 'button';
        o.setAttribute('aria-label', openLabel);
        o.title = openLabel;
        o.innerHTML = svg(ICONS.chevRight);
        o.addEventListener('click', onOpen);
        wrap.appendChild(o);
      }
      return wrap;
    }

    function subline(item) {
      const category = st.categories.find((c) => c.key === st.view);
      const mixed = !st.trail.length && (!category || category.kind !== item.kind);
      const kind = mixed || (st.trail.length && item.kind !== 'track') ? kindName(item.kind) : '';
      return [kind, item.subtitle].filter(Boolean).join(' · ');
    }

    function wholeRow(opened, coverSize) {
      return row({
        selected: st.item?.id === opened.id && !st.random,
        title: wholeName(opened),
        lead: disc(KIND_ICONS[opened.kind] || ICONS.albums, coverSize),
        strong: true, tinted: true,
        onClick: () => select(opened),
      });
    }

    function render() {
      const sz = size();
      const wide = sz === 'wide', narrow = sz === 'narrow';
      const coverSize = wide ? 44 : narrow ? 48 : 40;
      // A redraw while typing keeps the field focused, caret and all.
      const typing = card.querySelector('.mp-search input');
      const hadFocus = typing && typing === document.activeElement;
      const caret = hadFocus ? typing.selectionStart : null;
      card.className = `mp ${sz}`;
      card.replaceChildren();

      // Header
      const head = el('div', 'mp-head');
      head.appendChild(el('h2', 'mp-title', t('musicPickerTitle')));
      const search = el('label', `mp-search${st.search ? '' : ' disabled'}`);
      search.innerHTML = svg(ICONS.search, 20);
      const input = el('input');
      input.type = 'search';
      input.placeholder = t('musicPickerSearchHint');
      input.setAttribute('aria-label', t('musicPickerSearchHint'));
      input.value = st.query;
      input.disabled = !st.search;
      input.addEventListener('input', () => { onQuery(input.value); renderList(); });
      search.appendChild(input);
      if (st.query) {
        const clear = el('button', 'mp-clear icon-btn');
        clear.type = 'button';
        clear.setAttribute('aria-label', t('librarySearchClear'));
        clear.innerHTML = svg(ICONS.close, 18);
        clear.addEventListener('click', () => {
          st.query = '';
          const views = viewKeys();
          open(views.includes('playlists') ? 'playlists' : views[0] || '');
        });
        search.appendChild(clear);
      }
      const pills = el('div', 'mp-pills');
      pills.append(
        pill(ICONS[st.source] || ICONS.ma, st.source ? sourceName(st.source) : '',
          t('musicPickerSourceLabel', { name: st.source ? sourceName(st.source) : '' }),
          st.sources.length > 1 ? () => { st.menu = st.menu === 'sources' ? null : 'sources'; render(); } : null),
        pill(ICONS.volume, hasSpeaker() ? st.speakerName : t('musicPickerNoSpeakers'),
          t('musicPickerSpeakerLabel', { name: hasSpeaker() ? st.speakerName : t('musicPickerNoSpeakers') }),
          st.speakers.length ? () => { st.menu = st.menu === 'speakers' ? null : 'speakers'; render(); } : null),
      );
      if (narrow) {
        head.append(pills, search);
      } else {
        head.append(search, el('div', 'mp-spacer'), pills);
      }
      card.appendChild(head);

      // Body
      const body = el('div', 'mp-body');
      if (st.error === 'no_source') {
        body.appendChild(el('p', 'mp-message', t('libraryNoSource')));
      } else {
        if (wide) body.appendChild(nav());
        const main = el('div', 'mp-main');
        if (!wide) main.appendChild(subbar(narrow));
        if (wide) {
          main.appendChild(headRow());
          if (st.view === 'search' && !st.trail.length && st.rows.length) main.appendChild(kindChips('mp-kinds'));
        }
        const content = el('div', 'mp-content');
        const opened = st.trail[st.trail.length - 1];
        if (wide && opened) content.appendChild(side(opened));
        const list = el('div', 'mp-list edge-fade');
        content.appendChild(list);
        main.appendChild(content);
        body.appendChild(main);
        card._list = { list, coverSize, wide, narrow };
      }
      card.appendChild(body);
      card.appendChild(footer(sz));
      if (st.menu) card.appendChild(menu(sz));
      if (card._list) renderList();
      if (hadFocus) {
        input.focus();
        if (caret != null) input.setSelectionRange(caret, caret);
      }
    }

    function nav() {
      const n = el('nav', 'mp-nav edge-fade');
      n.setAttribute('aria-label', t('libraryLibrary'));
      const item = (key) => {
        const b = el('button', `mp-nav-item${st.view === key ? ' on' : ''}`);
        b.type = 'button';
        if (st.view === key) b.setAttribute('aria-current', 'page');
        b.innerHTML = svg(key === 'random' ? ICONS.random : ICONS[key] || ICONS.folder);
        b.appendChild(el('span', '', viewName(key)));
        b.addEventListener('click', () => open(key));
        return b;
      };
      const keys = viewKeys();
      if (keys.includes('random')) {
        n.appendChild(item('random'));
        n.appendChild(el('div', 'mp-nav-head', t('libraryLibrary')));
      }
      keys.filter((k) => k !== 'random').forEach((k) => n.appendChild(item(k)));
      return n;
    }

    const searchKinds = () => {
      const present = new Set(st.rows.map((r) => r.kind));
      return ['all', ...['track', 'album', 'artist', 'playlist', 'radio'].filter((k) => present.has(k))];
    };
    const kindChipName = (k) => ({ track: t('libraryTracks'), album: t('libraryAlbums'), artist: t('libraryArtists'),
      playlist: t('libraryPlaylists'), radio: t('libraryRadio') })[k] || t('librarySearchAll');

    function kindChips(cls) {
      const box = el('div', cls);
      searchKinds().forEach((k) => box.appendChild(chip(kindChipName(k), st.kind === k, () => { st.kind = k; render(); })));
      return box;
    }

    function backButton() {
      const b = el('button', 'mp-back-btn icon-btn');
      b.type = 'button';
      b.setAttribute('aria-label', t('commonBack'));
      b.innerHTML = svg(ICONS.back, 24);
      b.addEventListener('click', () => { st.trail.pop(); reload(); });
      return b;
    }

    function subbar(narrow) {
      const opened = st.trail[st.trail.length - 1];
      if (opened) {
        const bar = el('div', 'mp-backbar');
        bar.append(backButton(), el('span', 'mp-backbar-title', opened.title));
        if (!narrow && opened.subtitle) bar.appendChild(el('span', 'mp-backbar-sub', opened.subtitle));
        return bar;
      }
      if (st.view === 'search') return kindChips('mp-chips edge-fade-x');
      const chips = el('div', 'mp-chips edge-fade-x');
      viewKeys().forEach((k) => chips.appendChild(chip(viewName(k), st.view === k, () => open(k), k === 'random' ? ICONS.random : null)));
      return chips;
    }

    function headRow() {
      const h = el('div', 'mp-headrow');
      const opened = st.trail[st.trail.length - 1];
      if (opened) {
        h.append(backButton(), el('span', 'mp-headrow-parent',
          st.trail.length > 1 ? st.trail[st.trail.length - 2].title : viewName(st.view)));
      } else {
        h.appendChild(el('h3', 'mp-headrow-title', viewName(st.view)));
        if (st.view === 'random') h.appendChild(el('span', 'mp-headrow-hint', t('musicPickerRandomHint')));
      }
      return h;
    }

    function side(opened) {
      const box = el('div', 'mp-side');
      box.appendChild(art(opened, 216, 'big'));
      box.appendChild(el('div', 'mp-side-title', opened.title));
      if (opened.subtitle) box.appendChild(el('div', 'mp-side-sub', opened.subtitle));
      if (opened.playable !== false) box.appendChild(wholeRow(opened, 44));
      return box;
    }

    function renderList() {
      const ctx = card._list;
      if (!ctx) return;
      const { list, coverSize, wide, narrow } = ctx;
      list.replaceChildren();
      const opened = st.trail[st.trail.length - 1];
      list.classList.toggle('one', narrow || (wide && !!opened));
      const rows = [];
      if (st.view === 'random' && !opened) {
        if (!wide) list.appendChild(el('p', 'mp-note', t('musicPickerRandomHint')));
        st.randoms.forEach((r) => rows.push(row({
          selected: !st.item && st.random === r,
          title: randomName(r),
          lead: disc(RANDOM_ICONS[r] || ICONS.tracks, coverSize),
          onClick: () => selectRandom(r),
        })));
      } else {
        if (narrow && opened) {
          const hero = el('div', 'mp-hero');
          const text = el('div', 'mp-hero-text');
          text.appendChild(el('div', 'mp-hero-title', opened.title));
          if (opened.subtitle) text.appendChild(el('div', 'mp-hero-sub', opened.subtitle));
          hero.append(art(opened, 96, 'big'), text);
          list.appendChild(hero);
        }
        if (opened && opened.playable !== false && !wide) rows.push(wholeRow(opened, coverSize));
        const shown = st.view === 'search' && !opened && st.kind !== 'all'
          ? st.rows.filter((r) => r.kind === st.kind) : st.rows;
        let n = 0;
        shown.forEach((item) => {
          n++;
          const numbered = opened?.kind === 'album' && item.kind === 'track';
          let lead;
          if (numbered) lead = el('span', 'mp-num', String(n));
          else if (item.art) lead = art(item, coverSize);
          else lead = disc(item.kind === 'folder' ? ICONS.folder : ICONS.tracks, coverSize);
          rows.push(row({
            selected: st.item?.id === item.id && !st.random,
            title: item.title,
            sub: subline(item),
            lead,
            trailing: item.kind === 'track' ? trackLength(item.durationMs) : '',
            disabled: item.playable === false,
            onClick: () => select(item),
            onOpen: item.expandable ? () => { st.trail.push(item); reload(); } : null,
            openLabel: t('musicPickerOpen', { title: item.title }),
          }));
        });
      }
      if (st.loading && !rows.length) {
        list.appendChild(el('div', 'mp-message', t('commonLoading')));
      } else if (st.error && !rows.length) {
        list.appendChild(el('p', 'mp-message', st.error === 'no_speaker' ? t('libraryHaPickSpeaker') : t('libraryLoadFailed')));
      } else if (!rows.length) {
        list.appendChild(el('p', 'mp-message',
          st.view === 'search' && !st.query.trim() ? t('librarySearchPrompt') : t('libraryEmpty')));
      } else {
        const grid = el('div', 'mp-grid');
        rows.forEach((r) => grid.appendChild(r));
        list.appendChild(grid);
        if (st.more) {
          const more = el('div', 'mp-message', t('commonLoading'));
          list.appendChild(more);
          new IntersectionObserver((entries, obs) => {
            if (entries.some((e) => e.isIntersecting) && !st.loading) { obs.disconnect(); reload(true); }
          }, { root: list }).observe(more);
        }
      }
    }

    function footer(sz) {
      const narrow = sz === 'narrow';
      const foot = el('div', 'mp-foot');
      const sel = el('div', 'mp-sel');
      const p = pick();
      const artSize = sz === 'short' ? 44 : 52;
      if (st.item && st.item.art) sel.appendChild(art(st.item, artSize));
      else if (p) sel.appendChild(disc(st.random ? RANDOM_ICONS[st.random] : ICONS.tracks, artSize, true));
      else {
        const empty = el('span', 'mp-empty-art');
        empty.style.width = empty.style.height = `${artSize}px`;
        empty.innerHTML = svg(ICONS.tracks);
        sel.appendChild(empty);
      }
      const text = el('span', 'mp-sel-text');
      text.appendChild(el('span', `mp-sel-title${p ? '' : ' muted'}`,
        st.item?.title || (st.random ? randomName(st.random) : t('musicPickerNothing'))));
      text.appendChild(el('span', 'mp-sel-sub', st.item
        ? [kindName(st.item.kind), st.item.subtitle].filter(Boolean).join(' · ')
        : st.random ? t('musicPickerRandomEach') : t('musicPickerNothingHint')));
      sel.appendChild(text);
      if (p && hasSpeaker()) {
        const prev = el('button', `mp-preview icon-btn${st.previewing ? ' on' : ''}`);
        prev.type = 'button';
        const label = st.previewing ? t('musicPickerStopPreview') : t('musicPickerPreview');
        prev.setAttribute('aria-label', label);
        prev.setAttribute('aria-pressed', st.previewing ? 'true' : 'false');
        prev.title = label;
        prev.disabled = st.previewBusy;
        prev.innerHTML = `<svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor" aria-hidden="true"><path d="${st.previewing ? ICONS.stop : ICONS.play}"/></svg>`;
        prev.addEventListener('click', () => (st.previewing ? stopPreview() : startPreview()));
        sel.appendChild(prev);
      }
      const ctl = el('div', 'mp-ctl');
      const can = canShuffle(st.item, st.random);
      const sh = el('label', `mp-shuffle${can ? '' : ' off'}`);
      sh.appendChild(el('span', '', t('musicPickerShuffle')));
      const sw = el('span', 'switch');
      const box = el('input');
      box.type = 'checkbox';
      box.checked = can && st.shuffle;
      box.disabled = !can;
      box.setAttribute('aria-label', t('musicPickerShuffle'));
      box.addEventListener('change', () => { st.shuffle = box.checked; if (st.previewing) startPreview(); });
      sw.append(box, el('span', 'slider'));
      sh.appendChild(sw);
      const cancel = el('button', 'btn-text', t('commonCancel'));
      cancel.type = 'button';
      cancel.addEventListener('click', () => finish(null));
      const choose = el('button', 'btn-primary', t('commonChoose'));
      choose.type = 'button';
      choose.disabled = !p || !hasSpeaker();
      choose.addEventListener('click', async () => { await stopPreview(); finish(pick()); });
      ctl.append(sh, el('div', 'mp-spacer'), cancel, choose);
      foot.append(sel, ctl);
      if (narrow) foot.classList.add('stacked');
      return foot;
    }

    function menu(sz) {
      const wrap = el('div', 'mp-menu-wrap');
      const shade = el('button', 'mp-menu-shade');
      shade.type = 'button';
      shade.setAttribute('aria-label', t('commonClose'));
      shade.addEventListener('click', () => { st.menu = null; render(); });
      const m = el('div', `mp-menu ${st.menu}`);
      m.setAttribute('role', 'menu');
      const sources = st.menu === 'sources';
      m.appendChild(el('div', 'mp-menu-head', sources ? t('musicPickerMusicFrom') : t('musicPickerPlaysOn')));
      const item = ({ icon, name, sub, on, tag, disabled, onClick }) => {
        const b = el('button', `mp-menu-item${on ? ' on' : ''}`);
        b.type = 'button';
        b.setAttribute('role', 'menuitemradio');
        b.setAttribute('aria-checked', on ? 'true' : 'false');
        b.disabled = !!disabled;
        b.appendChild(disc(icon, 40));
        const text = el('span', 'mp-menu-text');
        const line = el('span', 'mp-menu-name');
        line.appendChild(el('span', '', name));
        if (tag) line.appendChild(el('span', 'mp-tag', tag));
        text.appendChild(line);
        if (sub) text.appendChild(el('span', 'mp-menu-sub', sub));
        b.appendChild(text);
        if (on) b.insertAdjacentHTML('beforeend', svg(ICONS.check).replace('<svg', '<svg class="mp-check"'));
        b.addEventListener('click', onClick);
        return b;
      };
      if (sources) {
        st.sources.forEach((k) => m.appendChild(item({
          icon: ICONS[k], name: sourceName(k), sub: sourceHint(k), on: k === st.source,
          onClick: async () => {
            st.menu = null;
            if (k === st.source) { render(); return; }
            await stopPreview();
            st.item = null; st.random = null;
            loadSource(k);
          },
        })));
      } else {
        st.speakers.forEach((s) => m.appendChild(item({
          icon: s.self ? ICONS.device : ICONS.speaker,
          name: s.name,
          sub: s.self ? t('libraryThisDevice') : s.available ? '' : t('libraryUnavailable'),
          on: s.pick === st.speaker,
          tag: s.pick === st.followed ? t('drawerNowPlaying') : '',
          disabled: !s.available,
          onClick: async () => {
            st.menu = null;
            if (s.pick === st.speaker) { render(); return; }
            await stopPreview();
            st.speaker = s.pick;
            st.speakerName = s.name;
            if (st.source === 'ha') {
              st.item = null;
              await call('libraryPickerSource', { source: 'ha', speaker: s.pick });
              open(st.view);
            } else {
              render();
            }
          },
        })));
        const note = [st.source === 'sonos' ? t('musicPickerSonosNote') : '', st.note, t('musicPickerFollowsNote')]
          .filter(Boolean).join(' ');
        m.appendChild(el('p', 'mp-menu-note', note));
      }
      wrap.append(shade, m);
      return wrap;
    }

    render();
    loadSource(current?.source || '', current?.speaker);
  });
}
