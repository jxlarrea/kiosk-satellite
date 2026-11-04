import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../l10n/generated/ui_strings.dart';
import '../l10n/messages.dart';
import '../managers/music_library/ha_library_source.dart';
import '../managers/music_library/library_model.dart';
import '../managers/music_library/music_library_manager.dart';
import '../managers/music_library/music_pick.dart';
import 'kit.dart';
import 'music_library_overlay.dart' show LibraryArt;
import 'toast.dart';

/// Choose music from the library for a feature, an alarm for one: a
/// track, an album, a playlist, an artist, a station or a random draw,
/// from Music Assistant, Home Assistant or Sonos, and the speaker it
/// plays on. Answers the pick, or null when cancelled.
///
/// A 1080 by 720 dialog on a tablet, full screen on anything smaller:
/// chips in place of the sidebar on a short screen, one column with the
/// source and speaker on their own row on a phone.
Future<MusicPick?> showMusicPicker(
  BuildContext context,
  AppContainer container, {
  MusicPick? current,
}) => showDialog<MusicPick>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _PickerFrame(container: container, current: current),
);

/// What a pick is called on a row that shows it: the entry's title, or
/// the random draw's name.
String musicPickName(UiStrings s, MusicPick pick) =>
    pick.item?.title ?? randomPickName(s, pick.random!);

String randomPickName(UiStrings s, RandomPick r) => switch (r) {
  RandomPick.tracks => s.musicPickerAnyTrack,
  RandomPick.favorites => s.musicPickerAnyFavorite,
  RandomPick.playlists => s.musicPickerAnyPlaylist,
  RandomPick.albums => s.musicPickerAnyAlbum,
  RandomPick.radio => s.musicPickerAnyStation,
};

/// A box that shows a pick and opens the picker, the entity field's look:
/// the music mark, the name and a chevron. [picked] draws the mark in the
/// accent; a value like None or Default leaves it muted.
class MusicPickField extends StatelessWidget {
  const MusicPickField({
    super.key,
    required this.label,
    required this.onTap,
    this.picked = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool picked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ControlBox(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 20,
            color: picked ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, color: scheme.onSurface),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

enum _Size { wide, short, narrow }

class _PickerFrame extends StatefulWidget {
  const _PickerFrame({required this.container, this.current});

  final AppContainer container;
  final MusicPick? current;

  @override
  State<_PickerFrame> createState() => _PickerFrameState();
}

class _PickerFrameState extends State<_PickerFrame> {
  final _openedAt = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialog = size.width >= 900 && size.height >= 620;
    final picker = MusicPickerView(
      container: widget.container,
      current: widget.current,
      dialog: dialog,
    );
    if (!dialog) return Dialog.fullscreen(child: SafeArea(child: picker));
    return Stack(
      children: [
        // An outside tap cancels, but not the second tap of the double
        // tap that opened it.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (DateTime.now().difference(_openedAt).inMilliseconds > 500) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: math.min(1080.0, size.width - 48),
            height: math.min(720.0, size.height - 48),
            child: picker,
          ),
        ),
      ],
    );
  }
}

/// The picker itself, sized by its frame.
class MusicPickerView extends StatefulWidget {
  const MusicPickerView({
    super.key,
    required this.container,
    this.current,
    this.dialog = false,
  });

  final AppContainer container;
  final MusicPick? current;
  final bool dialog;

  @override
  State<MusicPickerView> createState() => _MusicPickerViewState();
}

class _MusicPickerViewState extends State<MusicPickerView> {
  MusicLibraryManager get _lib => widget.container.musicLibrary;

  List<String> _sources = const [];
  String _source = '';
  LibrarySource? _src;

  List<LibrarySpeaker> _speakers = const [];
  String? _speakerNote;
  String _speaker = '';
  String _speakerName = '';

  List<LibraryCategory> _cats = const [];
  List<RandomPick> _randoms = const [];

  /// 'random', a category key, 'browse' (a Home Assistant tree's root)
  /// or 'search'.
  String _view = '';

  /// The albums, playlists, artists and folders opened, innermost last.
  final _trail = <LibraryItem>[];

  List<LibraryItem> _rows = const [];
  bool _loading = true;
  String? _error;
  bool _more = false;
  int _gen = 0;

  final _query = TextEditingController();
  Timer? _debounce;
  String _kind = 'all';

  LibraryItem? _item;
  RandomPick? _random;
  bool _shuffle = false;
  bool _previewing = false;
  bool _previewBusy = false;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _item = current?.item;
    _random = current?.random;
    _shuffle = current?.shuffle ?? false;
    _sources = _lib.available;
    if (_sources.isEmpty) {
      _loading = false;
      return;
    }
    final key = current != null && _sources.contains(current.source)
        ? current.source
        : _sources.first;
    unawaited(_loadSource(key, keep: current?.speaker));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    if (_previewing) unawaited(_lib.endPick('preview'));
    super.dispose();
  }

  // ── Loading ─────────────────────────────────────────────────────────

  Future<void> _loadSource(String key, {String? keep}) async {
    final gen = ++_gen;
    setState(() {
      _source = key;
      _loading = true;
      _error = null;
      _rows = const [];
      _trail.clear();
    });
    final (speakers, note) = await _lib.speakers(key);
    if (!mounted || gen != _gen) return;
    final usable = speakers.where((s) => s.available).toList();
    LibrarySpeaker? find(String? pick) =>
        pick == null ? null : usable.where((s) => s.pick == pick).firstOrNull;
    // This device first where the source can play on it, then the
    // speaker Now Playing follows, then the first one.
    final speaker =
        find(keep) ??
        usable.where((s) => s.self).firstOrNull ??
        find(_lib.pick.value) ??
        usable.firstOrNull;
    _speakers = speakers;
    _speakerNote = note;
    _speaker = speaker?.pick ?? '';
    _speakerName = speaker?.name ?? '';
    final src = _lib.pickerSource(key, _speaker);
    _src = src;
    if (src == null) {
      setState(() => _loading = false);
      return;
    }
    if (src is HaLibrarySource) await src.follow(_speaker);
    List<LibraryCategory> cats;
    try {
      cats = await src.availableCategories();
    } catch (_) {
      cats = src.categories;
    }
    if (!mounted || gen != _gen) return;
    _cats = cats;
    _randoms = [
      for (final r in MusicLibraryManager.randomPicks(src))
        if (cats.any(
          (c) => c.key == MusicLibraryManager.randomCategory(src, r)?.key,
        ))
          r,
    ];
    final views = _viewKeys;
    final wanted = _random != null && _randoms.contains(_random)
        ? 'random'
        : views.contains('playlists')
        ? 'playlists'
        : views.contains('favorites')
        ? 'favorites'
        : views.firstOrNull ?? '';
    await _open(wanted);
  }

  /// The views the sidebar or the chips list, in order.
  List<String> get _viewKeys => [
    if (_randoms.isNotEmpty) 'random',
    if (_source == 'ha') 'browse',
    for (final c in _cats) c.key,
  ];

  Future<void> _open(String view) async {
    _view = view;
    _trail.clear();
    await _reload();
  }

  Future<void> _reload({bool more = false}) async {
    final src = _src;
    if (src == null) return;
    final gen = ++_gen;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) {
        _rows = const [];
        _more = false;
      }
    });
    try {
      final List<LibraryItem> items;
      var hasMore = false;
      if (_trail.isNotEmpty) {
        final opened = _trail.last;
        if (opened.kind == LibraryKind.folder) {
          items = (await src.browse(opened)).items;
        } else {
          final detail = await src.open(opened);
          items = [
            ...detail.tracks,
            for (final shelf in detail.shelves) ...shelf.items,
          ];
        }
      } else if (_view == 'random') {
        items = const [];
      } else if (_view == 'browse') {
        items = (await src.browse(null)).items;
      } else if (_view == 'search') {
        final q = _query.text.trim();
        items = q.isEmpty
            ? const []
            : [for (final s in await src.search(q)) ...s.items];
      } else {
        final category = _cats.where((c) => c.key == _view).firstOrNull;
        if (category == null) {
          items = const [];
        } else {
          final page = await src.list(
            category,
            offset: more ? _rows.length : 0,
            sort: _lib.sortFor(src, category),
          );
          items = page.items;
          hasMore = page.more;
        }
      }
      if (!mounted || gen != _gen) return;
      setState(() {
        _rows = more ? [..._rows, ...items] : items;
        _more = hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || gen != _gen) return;
      setState(() {
        _loading = false;
        _error = e is LibraryError ? e.message : '$e';
      });
    }
  }

  void _onQuery(String _) {
    _debounce?.cancel();
    if (_view != 'search') {
      _view = 'search';
      _trail.clear();
      _kind = 'all';
    }
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 400), _reload);
  }

  void _clearQuery() {
    _query.clear();
    FocusScope.of(context).unfocus();
    final views = _viewKeys;
    unawaited(
      _open(
        views.contains('playlists') ? 'playlists' : views.firstOrNull ?? '',
      ),
    );
  }

  Future<void> _pickSpeaker(LibrarySpeaker s) async {
    if (s.pick == _speaker) return;
    await _stopPreview();
    setState(() {
      _speaker = s.pick;
      _speakerName = s.name;
    });
    // A Home Assistant tree belongs to its speaker.
    final src = _src;
    if (src is HaLibrarySource) {
      await src.follow(_speaker);
      _item = null;
      await _open(_view);
    }
  }

  // ── The pick ────────────────────────────────────────────────────────

  MusicPick? get _pick => _item == null && _random == null
      ? null
      : MusicPick(
          source: _source,
          item: _item,
          random: _item == null ? _random : null,
          shuffle: _shuffle,
          speaker: _speaker,
          speakerName: _speakerName,
        );

  bool get _canShuffle => MusicPick.canShuffleKind(_item?.kind, _random);

  bool get _hasSpeaker => _speakers.any((s) => s.pick == _speaker);

  void _select(LibraryItem item) {
    if (!item.playable) return;
    setState(() {
      _item = item;
      _random = null;
    });
    unawaited(_restartPreview());
  }

  void _selectRandom(RandomPick r) {
    setState(() {
      _item = null;
      _random = r;
    });
    unawaited(_restartPreview());
  }

  Future<void> _restartPreview() async {
    if (_previewing) await _startPreview();
  }

  Future<void> _togglePreview() async {
    if (_previewing) {
      await _stopPreview();
    } else {
      await _startPreview();
    }
  }

  Future<void> _startPreview() async {
    final pick = _pick;
    if (pick == null || _previewBusy) return;
    setState(() {
      _previewing = true;
      _previewBusy = true;
    });
    final error = await _lib.startPick(
      pick,
      owner: 'preview',
      settle: const Duration(seconds: 12),
    );
    if (!mounted) {
      if (error == null) unawaited(_lib.endPick('preview'));
      return;
    }
    setState(() {
      _previewBusy = false;
      if (error != null) _previewing = false;
    });
    if (error != null) {
      showToast(
        context,
        title: l10n(context).musicPickerPreviewFailed,
        message: error,
        kind: ToastKind.error,
      );
    }
  }

  Future<void> _stopPreview() async {
    if (!_previewing) return;
    setState(() => _previewing = false);
    await _lib.endPick('preview');
  }

  Future<void> _finish(MusicPick? pick) async {
    await _stopPreview();
    if (mounted) Navigator.of(context).pop(pick);
  }

  // ── Words and icons ─────────────────────────────────────────────────

  String _sourceName(UiStrings s, String key) => switch (key) {
    'ha' => s.librarySourceHa,
    'sonos' => s.librarySourceSonos,
    _ => s.librarySourceMa,
  };

  IconData _sourceIcon(String key) => switch (key) {
    'ha' => Icons.home_outlined,
    'sonos' => Icons.speaker_outlined,
    _ => Icons.library_music_outlined,
  };

  String _viewName(UiStrings s, String key) => switch (key) {
    'random' => s.musicPickerRandom,
    'browse' => s.libraryBrowse,
    'search' => s.librarySearch,
    'artists' => s.libraryArtists,
    'albums' => s.libraryAlbums,
    'tracks' => s.libraryTracks,
    'playlists' => s.libraryPlaylists,
    'radios' || 'radio' => s.libraryRadio,
    'podcasts' => s.libraryPodcasts,
    'audiobooks' => s.libraryAudiobooks,
    'favorites' => s.libraryFavorites,
    'sonos_playlists' => s.librarySonosPlaylists,
    _ => key,
  };

  IconData _viewIcon(String key) => switch (key) {
    'random' => Icons.shuffle_rounded,
    'browse' => Icons.folder_outlined,
    'artists' => Icons.person_outline_rounded,
    'albums' => Icons.album_outlined,
    'tracks' => Icons.music_note_outlined,
    'playlists' || 'sonos_playlists' => Icons.queue_music_rounded,
    'radios' || 'radio' => Icons.radio_outlined,
    'podcasts' => Icons.podcasts_rounded,
    'audiobooks' => Icons.menu_book_outlined,
    'favorites' => Icons.favorite_border_rounded,
    _ => Icons.folder_outlined,
  };

  String _kindName(UiStrings s, LibraryKind k) => switch (k) {
    LibraryKind.artist => s.libraryKindArtist,
    LibraryKind.album => s.libraryKindAlbum,
    LibraryKind.track => s.libraryKindTrack,
    LibraryKind.playlist => s.libraryKindPlaylist,
    LibraryKind.radio => s.libraryKindRadio,
    LibraryKind.podcast => s.libraryKindPodcast,
    LibraryKind.episode => s.libraryKindEpisode,
    LibraryKind.audiobook => s.libraryKindAudiobook,
    LibraryKind.genre => s.libraryKindGenre,
    LibraryKind.folder => s.musicPickerKindFolder,
    LibraryKind.other => '',
  };

  String _randomName(UiStrings s, RandomPick r) => randomPickName(s, r);

  IconData _randomIcon(RandomPick r) => switch (r) {
    RandomPick.tracks => Icons.library_music_outlined,
    RandomPick.favorites => Icons.favorite_border_rounded,
    RandomPick.playlists => Icons.queue_music_rounded,
    RandomPick.albums => Icons.album_outlined,
    RandomPick.radio => Icons.radio_outlined,
  };

  String _wholeName(UiStrings s, LibraryItem opened) => switch (opened.kind) {
    LibraryKind.album => s.musicPickerWholeAlbum,
    LibraryKind.playlist => s.musicPickerWholePlaylist,
    LibraryKind.artist => s.musicPickerWholeArtist(opened.title),
    LibraryKind.folder => s.musicPickerWholeFolder,
    _ => s.musicPickerAllTracks,
  };

  /// "Album · Juniper Lane", the kind left out where the list is all of
  /// one kind.
  String _subline(UiStrings s, LibraryItem item) {
    final category = _cats.where((c) => c.key == _view).firstOrNull;
    final mixed =
        _trail.isEmpty && (category == null || category.kind != item.kind);
    final kind = mixed || (_trail.isNotEmpty && item.kind != LibraryKind.track)
        ? _kindName(s, item.kind)
        : '';
    return [kind, item.subtitle].where((t) => t.isNotEmpty).join(' · ');
  }

  // ── Layout ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = widget.dialog
            ? _Size.wide
            : box.maxWidth < 600
            ? _Size.narrow
            : _Size.short;
        return _build(context, size);
      },
    );
  }

  Widget _build(BuildContext context, _Size size) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    final wide = size == _Size.wide, narrow = size == _Size.narrow;
    final title = Text(
      s.musicPickerTitle,
      maxLines: 1,
      style: TextStyle(
        fontSize: wide ? 22 : (narrow ? 20 : 19),
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    );
    final field = _SearchField(
      controller: _query,
      hint: s.musicPickerSearchHint,
      clearLabel: s.librarySearchClear,
      height: size == _Size.short ? 42 : 46,
      onChanged: _onQuery,
      onClear: _clearQuery,
      enabled: _src?.hasSearch ?? false,
    );
    final pills = [
      _Pill(
        icon: _sourceIcon(_source),
        label: _source.isEmpty ? '' : _sourceName(s, _source),
        semantics: s.musicPickerSourceLabel(_sourceName(s, _source)),
        height: size == _Size.short ? 42 : 44,
        maxWidth: narrow ? null : (size == _Size.short ? 190 : 220),
        onTap: _sources.length > 1 ? _sourceMenu : null,
      ),
      _Pill(
        icon: Icons.volume_up_outlined,
        label: _hasSpeaker ? _speakerName : s.musicPickerNoSpeakers,
        semantics: s.musicPickerSpeakerLabel(
          _hasSpeaker ? _speakerName : s.musicPickerNoSpeakers,
        ),
        height: size == _Size.short ? 42 : 44,
        maxWidth: narrow ? null : (size == _Size.short ? 180 : 210),
        onTap: _speakers.isEmpty ? null : _speakerMenu,
      ),
    ];
    final Widget header;
    if (narrow) {
      header = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 56,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: title,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: pills[0]),
                const SizedBox(width: 8),
                Expanded(child: pills[1]),
              ],
            ),
            const SizedBox(height: 8),
            field,
            const SizedBox(height: 4),
          ],
        ),
      );
    } else {
      header = SizedBox(
        height: wide ? 72 : 56,
        child: Padding(
          padding: wide
              ? const EdgeInsets.fromLTRB(32, 0, 24, 0)
              : const EdgeInsets.fromLTRB(20, 0, 12, 0),
          child: Row(
            children: [
              title,
              SizedBox(width: wide ? 20 : 12),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 360 : 300),
                  child: field,
                ),
              ),
              const Spacer(),
              pills[0],
              const SizedBox(width: 8),
              pills[1],
            ],
          ),
        ),
      );
    }
    final body = _sources.isEmpty
        ? _Message(text: s.libraryNoSource)
        : wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 216, child: _nav(s, scheme)),
              Expanded(child: _content(s, scheme, size)),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _subbar(s, scheme, size),
              Expanded(child: _content(s, scheme, size)),
            ],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(child: body),
        Divider(height: 1, color: scheme.outlineVariant),
        _footer(s, scheme, size),
      ],
    );
  }

  Widget _nav(UiStrings s, ColorScheme scheme) {
    Widget item(String key) {
      final on = _trail.isEmpty ? _view == key : _view == key;
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color: on ? scheme.surfaceContainerHighest : Colors.transparent,
          borderRadius: BorderRadius.circular(23),
          child: InkWell(
            borderRadius: BorderRadius.circular(23),
            onTap: () => _open(key),
            child: SizedBox(
              height: 46,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(_viewIcon(key), size: 22, color: scheme.onSurface),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _viewName(s, key),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final keys = _viewKeys;
    return EdgeFade(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 16),
        children: [
          if (keys.contains('random')) ...[
            item('random'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                s.libraryLibrary.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .8,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          for (final k in keys)
            if (k != 'random') item(k),
        ],
      ),
    );
  }

  /// Chips on the smaller screens, a back row inside an opened entry.
  Widget _subbar(UiStrings s, ColorScheme scheme, _Size size) {
    final narrow = size == _Size.narrow;
    if (_trail.isNotEmpty) {
      final opened = _trail.last;
      return SizedBox(
        height: 52,
        child: Padding(
          padding: EdgeInsets.fromLTRB(narrow ? 8 : 12, 0, 16, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: s.commonBack,
                icon: const Icon(Icons.arrow_back),
                onPressed: _back,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  opened.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (!narrow && opened.subtitle.isNotEmpty) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    opened.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    final chips = _view == 'search'
        ? [
            for (final k in _searchKinds)
              _Chip(
                label: _kindChipName(s, k),
                on: _kind == k,
                onTap: () => setState(() => _kind = k),
              ),
          ]
        : [
            for (final k in _viewKeys)
              _Chip(
                label: _viewName(s, k),
                icon: k == 'random' ? Icons.shuffle_rounded : null,
                on: _view == k,
                onTap: () => _open(k),
              ),
          ];
    return SizedBox(
      height: 52,
      child: EdgeFade(
        axis: Axis.horizontal,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 20),
          itemCount: chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) => Center(child: chips[i]),
        ),
      ),
    );
  }

  List<String> get _searchKinds {
    final present = {for (final r in _rows) r.kind.name};
    return [
      'all',
      for (final k in const ['track', 'album', 'artist', 'playlist', 'radio'])
        if (present.contains(k)) k,
    ];
  }

  String _kindChipName(UiStrings s, String k) => switch (k) {
    'track' => s.libraryTracks,
    'album' => s.libraryAlbums,
    'artist' => s.libraryArtists,
    'playlist' => s.libraryPlaylists,
    'radio' => s.libraryRadio,
    _ => s.librarySearchAll,
  };

  void _back() {
    if (_trail.isEmpty) return;
    _trail.removeLast();
    unawaited(_reload());
  }

  Future<void> _openItem(LibraryItem item) async {
    _trail.add(item);
    await _reload();
  }

  Widget _content(UiStrings s, ColorScheme scheme, _Size size) {
    final wide = size == _Size.wide, narrow = size == _Size.narrow;
    final cols = narrow || (wide && _trail.isNotEmpty) ? 1 : 2;
    final rows = <Widget>[];
    final opened = _trail.lastOrNull;

    if (_view == 'random' && _trail.isEmpty) {
      for (final r in _randoms) {
        rows.add(
          _PickRow(
            size: size,
            selected: _item == null && _random == r,
            title: _randomName(s, r),
            lead: _IconDisc(icon: _randomIcon(r), size: size.cov),
            onTap: () => _selectRandom(r),
          ),
        );
      }
    } else {
      if (opened != null && opened.playable && !wide) {
        rows.add(_wholeRow(s, opened, size));
      }
      final shown = _view == 'search' && _trail.isEmpty && _kind != 'all'
          ? _rows.where((r) => r.kind.name == _kind)
          : _rows;
      var n = 0;
      for (final item in shown) {
        n++;
        final numbered =
            opened?.kind == LibraryKind.album && item.kind == LibraryKind.track;
        rows.add(
          _PickRow(
            size: size,
            selected: _item?.id == item.id && _random == null,
            title: item.title,
            subtitle: _subline(s, item),
            trailing: item.kind == LibraryKind.track
                ? formatTrackLength(item.durationMs)
                : null,
            lead: numbered
                ? SizedBox(
                    width: 22,
                    child: Text(
                      '$n',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  )
                : item.art != null
                ? LibraryArt(
                    container: widget.container,
                    item: item,
                    size: size.cov,
                    radius: item.round ? size.cov / 2 : 8,
                    showStarting: false,
                  )
                : _IconDisc(
                    icon: item.kind == LibraryKind.folder
                        ? Icons.folder_outlined
                        : Icons.music_note_outlined,
                    size: size.cov,
                  ),
            enabled: item.playable,
            onTap: () => _select(item),
            openLabel: item.expandable ? s.musicPickerOpen(item.title) : null,
            onOpen: item.expandable ? () => _openItem(item) : null,
          ),
        );
      }
    }

    Widget list;
    if (_loading && rows.isEmpty) {
      list = const Center(child: CircularProgressIndicator());
    } else if (_error != null && rows.isEmpty) {
      list = _Message(
        text: _error == 'no_speaker'
            ? s.libraryHaPickSpeaker
            : s.libraryLoadFailed,
      );
    } else if (rows.isEmpty) {
      list = _Message(
        text: _view == 'search' && _query.text.trim().isEmpty
            ? s.librarySearchPrompt
            : s.libraryEmpty,
      );
    } else {
      final lines = <Widget>[
        for (var i = 0; i < rows.length; i += cols)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: cols == 1
                ? rows[i]
                : Row(
                    children: [
                      Expanded(child: rows[i]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: i + 1 < rows.length
                            ? rows[i + 1]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
          ),
        if (_more)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
      ];
      list = NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (_more &&
              !_loading &&
              n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
            unawaited(_reload(more: true));
          }
          return false;
        },
        child: EdgeFade(
          child: ListView(
            padding: wide
                ? const EdgeInsets.fromLTRB(8, 0, 24, 16)
                : EdgeInsets.fromLTRB(narrow ? 8 : 12, 2, narrow ? 8 : 12, 12),
            children: [
              if (_view == 'random' && _trail.isEmpty && !wide)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Text(
                    s.musicPickerRandomHint,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (narrow && opened != null) _hero(s, scheme, opened, 96),
              ...lines,
            ],
          ),
        ),
      );
    }

    if (!wide) return list;

    // The tablet's heading over the list, and an opened entry's column.
    final head = SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 24, 0),
        child: Row(
          children: [
            if (opened != null) ...[
              IconButton(
                tooltip: s.commonBack,
                icon: const Icon(Icons.arrow_back),
                onPressed: _back,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _trail.length > 1
                      ? _trail[_trail.length - 2].title
                      : _viewName(s, _view),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  _viewName(s, _view),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (_view == 'random') ...[
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    s.musicPickerRandomHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
    final searchChips = _view == 'search' && _trail.isEmpty && _rows.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 24, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in _searchKinds)
                  _Chip(
                    label: _kindChipName(s, k),
                    on: _kind == k,
                    onTap: () => setState(() => _kind = k),
                  ),
              ],
            ),
          )
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        head,
        ?searchChips,
        Expanded(
          child: opened == null
              ? list
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 248,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LibraryArt(
                              container: widget.container,
                              item: opened,
                              size: 216,
                              radius: opened.round ? 108 : 16,
                              showStarting: false,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              opened.title,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                                height: 1.25,
                              ),
                            ),
                            if (opened.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                opened.subtitle,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            if (opened.playable) ...[
                              const SizedBox(height: 14),
                              _wholeRow(s, opened, size),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Expanded(child: list),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _hero(
    UiStrings s,
    ColorScheme scheme,
    LibraryItem opened,
    double art,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
    child: Row(
      children: [
        LibraryArt(
          container: widget.container,
          item: opened,
          size: art,
          radius: opened.round ? art / 2 : 12,
          showStarting: false,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                opened.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              if (opened.subtitle.isNotEmpty)
                Text(
                  opened.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _wholeRow(UiStrings s, LibraryItem opened, _Size size) => _PickRow(
    size: size,
    selected: _item?.id == opened.id && _random == null,
    title: _wholeName(s, opened),
    strong: true,
    lead: _IconDisc(
      icon: switch (opened.kind) {
        LibraryKind.artist => Icons.person_outline_rounded,
        LibraryKind.playlist => Icons.queue_music_rounded,
        LibraryKind.folder => Icons.folder_outlined,
        _ => Icons.album_outlined,
      },
      size: size.cov,
    ),
    tinted: true,
    onTap: () => _select(opened),
  );

  Widget _footer(UiStrings s, ColorScheme scheme, _Size size) {
    final narrow = size == _Size.narrow, short = size == _Size.short;
    final pick = _pick;
    final art = short ? 44.0 : 52.0;
    final Widget lead;
    if (_item != null && _item!.art != null) {
      lead = LibraryArt(
        container: widget.container,
        item: _item!,
        size: art,
        radius: _item!.round ? art / 2 : 10,
        showStarting: false,
      );
    } else if (pick != null) {
      lead = _IconDisc(
        icon: _random != null
            ? _randomIcon(_random!)
            : Icons.music_note_outlined,
        size: art,
        filled: true,
      );
    } else {
      lead = Container(
        width: art,
        height: art,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outline, width: 1.5),
        ),
        child: Icon(Icons.music_note_outlined, color: scheme.onSurfaceVariant),
      );
    }
    final titleText =
        _item?.title ??
        (_random != null ? _randomName(s, _random!) : s.musicPickerNothing);
    final subText = _item != null
        ? [
            _kindName(s, _item!.kind),
            _item!.subtitle,
          ].where((t) => t.isNotEmpty).join(' · ')
        : _random != null
        ? s.musicPickerRandomEach
        : s.musicPickerNothingHint;
    final summary = Row(
      children: [
        lead,
        SizedBox(width: short ? 12 : 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: short ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  color: pick == null
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface,
                ),
              ),
              Text(
                subText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (pick != null && _hasSpeaker)
          IconButton.filledTonal(
            tooltip: _previewing
                ? s.musicPickerStopPreview
                : s.musicPickerPreview,
            isSelected: _previewing,
            onPressed: _previewBusy ? null : _togglePreview,
            icon: _previewBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _previewing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  ),
          ),
      ],
    );
    final shuffle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            s.musicPickerShuffle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: _canShuffle ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Switch(
          value: _canShuffle && _shuffle,
          onChanged: _canShuffle
              ? (on) {
                  setState(() => _shuffle = on);
                  unawaited(_restartPreview());
                }
              : null,
        ),
      ],
    );
    final actions = [
      TextButton(onPressed: () => _finish(null), child: Text(s.commonCancel)),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: pick != null && _hasSpeaker ? () => _finish(pick) : null,
        child: Text(s.commonChoose),
      ),
    ];
    if (narrow) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 56, child: summary),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Align(alignment: Alignment.centerLeft, child: shuffle),
                ),
                ...actions,
              ],
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: size == _Size.wide ? 84 : 68,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: size == _Size.wide ? 24 : 16),
        child: Row(
          children: [
            Expanded(flex: 3, child: summary),
            SizedBox(width: size == _Size.wide ? 24 : 14),
            Flexible(child: shuffle),
            SizedBox(width: size == _Size.wide ? 20 : 12),
            ...actions,
          ],
        ),
      ),
    );
  }

  // ── Menus ───────────────────────────────────────────────────────────

  Future<void> _sourceMenu() async {
    final s = l10n(context);
    final key = await _menu<String>(
      title: s.musicPickerMusicFrom,
      rows: [
        for (final k in _sources)
          _MenuRow(
            value: k,
            icon: _sourceIcon(k),
            name: _sourceName(s, k),
            sub: switch (k) {
              'ha' => s.librarySourceHaHint,
              'sonos' => s.librarySourceSonosHint,
              _ => s.librarySourceMaHint,
            },
            on: k == _source,
          ),
      ],
    );
    if (key == null || key == _source) return;
    await _stopPreview();
    _item = null;
    _random = null;
    await _loadSource(key);
  }

  Future<void> _speakerMenu() async {
    final s = l10n(context);
    final followed = _lib.pick.value;
    final pick = await _menu<String>(
      title: s.musicPickerPlaysOn,
      rows: [
        for (final sp in _speakers)
          _MenuRow(
            value: sp.pick,
            icon: sp.self
                ? Icons.tablet_android_outlined
                : Icons.speaker_outlined,
            name: sp.name,
            sub: sp.self
                ? s.libraryThisDevice
                : sp.available
                ? ''
                : s.libraryUnavailable,
            on: sp.pick == _speaker,
            enabled: sp.available,
            tag: sp.pick == followed ? s.drawerNowPlaying : null,
          ),
      ],
      note: [
        if (_source == 'sonos') s.musicPickerSonosNote,
        ?_speakerNote,
        s.musicPickerFollowsNote,
      ].join(' '),
    );
    if (pick == null) return;
    final sp = _speakers.where((x) => x.pick == pick).firstOrNull;
    if (sp != null) await _pickSpeaker(sp);
  }

  Future<T?> _menu<T>({
    required String title,
    required List<_MenuRow<T>> rows,
    String? note,
  }) => showDialog<T>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .8,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    for (final r in rows)
                      Material(
                        color: r.on
                            ? scheme.surfaceContainerHighest
                            : Colors.transparent,
                        child: InkWell(
                          onTap: r.enabled
                              ? () => Navigator.of(context).pop(r.value)
                              : null,
                          child: Opacity(
                            opacity: r.enabled ? 1 : .45,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  _IconDisc(
                                    icon: r.icon,
                                    size: 40,
                                    round: true,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                r.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: scheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            if (r.tag != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      scheme.secondaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(99),
                                                ),
                                                child: Text(
                                                  r.tag!,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: scheme
                                                        .onSecondaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (r.sub.isNotEmpty)
                                          Text(
                                            r.sub,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (r.on)
                                    Icon(Icons.check, color: scheme.primary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (note != null && note.isNotEmpty) ...[
                Divider(height: 1, color: scheme.outlineVariant),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Text(
                    note,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

extension on _Size {
  double get cov => switch (this) {
    _Size.wide => 44,
    _Size.short => 40,
    _Size.narrow => 48,
  };

  double get rowHeight => switch (this) {
    _Size.wide => 60,
    _Size.short => 54,
    _Size.narrow => 64,
  };
}

class _MenuRow<T> {
  const _MenuRow({
    required this.value,
    required this.icon,
    required this.name,
    required this.sub,
    required this.on,
    this.enabled = true,
    this.tag,
  });

  final T value;
  final IconData icon;
  final String name;
  final String sub;
  final bool on;
  final bool enabled;
  final String? tag;
}

/// One pickable row: a radio, the cover, the title and what it is, with
/// a chevron that opens an album, a playlist, an artist or a folder.
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.size,
    required this.selected,
    required this.title,
    required this.lead,
    required this.onTap,
    this.subtitle = '',
    this.trailing,
    this.enabled = true,
    this.strong = false,
    this.tinted = false,
    this.openLabel,
    this.onOpen,
  });

  final _Size size;
  final bool selected;
  final String title;
  final String subtitle;
  final String? trailing;
  final Widget lead;
  final bool enabled, strong, tinted;
  final VoidCallback onTap;
  final String? openLabel;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final short = size == _Size.short;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurface;
    return Semantics(
      selected: selected,
      child: Material(
        color: selected
            ? scheme.secondaryContainer
            : tinted
            ? scheme.surfaceContainerHigh
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: size.rowHeight,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: enabled ? onTap : null,
                  child: Opacity(
                    opacity: enabled ? 1 : .5,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        short ? 12 : 14,
                        0,
                        onOpen != null ? 4 : 14,
                        0,
                      ),
                      child: Row(
                        children: [
                          _Radio(on: selected),
                          SizedBox(width: short ? 12 : 14),
                          lead,
                          SizedBox(width: short ? 12 : 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: short
                                        ? 14.5
                                        : size == _Size.narrow
                                        ? 16
                                        : 15.5,
                                    fontWeight: selected || strong
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: fg,
                                  ),
                                ),
                                if (subtitle.isNotEmpty)
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: short ? 12.5 : 13,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (trailing != null && trailing!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              trailing!,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: scheme.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (onOpen != null)
                IconButton(
                  tooltip: openLabel,
                  onPressed: onOpen,
                  icon: Icon(
                    Icons.chevron_right,
                    color: selected
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              if (onOpen != null) const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = on ? scheme.primary : scheme.onSurfaceVariant;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: on
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            )
          : null,
    );
  }
}

class _IconDisc extends StatelessWidget {
  const _IconDisc({
    required this.icon,
    required this.size,
    this.filled = false,
    this.round = false,
  });

  final IconData icon;
  final double size;
  final bool filled, round;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(round ? size / 2 : 12),
      ),
      child: Icon(
        icon,
        size: 22,
        color: filled ? scheme.onSecondaryContainer : scheme.primary,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.semantics,
    required this.height,
    this.maxWidth,
    this.onTap,
  });

  final IconData icon;
  final String label, semantics;
  final double height;
  final double? maxWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pill = Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: maxWidth == null
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: maxWidth == null
          ? pill
          : ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth!),
              child: pill,
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.on,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? scheme.secondaryContainer : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: on ? scheme.secondaryContainer : scheme.outline,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: EdgeInsets.fromLTRB(icon != null ? 12 : 16, 0, 16, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 18,
                      color: on
                          ? scheme.onSecondaryContainer
                          : scheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                      color: on
                          ? scheme.onSecondaryContainer
                          : scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.clearLabel,
    required this.height,
    required this.onChanged,
    required this.onClear,
    required this.enabled,
  });

  final TextEditingController controller;
  final String hint, clearLabel;
  final double height;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: Container(
        height: height,
        padding: const EdgeInsets.only(left: 14, right: 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontSize: 15.5, color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (_, _) => controller.text.isEmpty
                  ? const SizedBox(width: 8)
                  : IconButton(
                      tooltip: clearLabel,
                      iconSize: 18,
                      onPressed: onClear,
                      icon: const Icon(Icons.close),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}
