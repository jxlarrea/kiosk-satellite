import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../l10n/generated/ui_strings.dart';
import '../l10n/messages.dart';
import '../managers/music_library/ha_library_source.dart';
import '../managers/music_library/library_model.dart';
import '../managers/settings/definitions.dart' as defs;
import 'kit.dart';
import 'music_library_queue.dart';
import 'music_library_speakers.dart';
import 'theme.dart';
import 'thumb_cache.dart' show FetchLane, FetchTicket;
import 'toast.dart';

/// The Music Library as a full screen overlay: Discover, Search, the
/// library lists and each source's own tree, for Music Assistant, a Home
/// Assistant speaker or a Sonos household. Plays land on the player Now
/// Playing follows, picked from the speaker pill. Shown through
/// [MusicLibraryManager.visible].
class MusicLibraryOverlay extends StatelessWidget {
  const MusicLibraryOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: container.musicLibrary.visible,
    builder: (context, visible, _) {
      if (!visible) return const SizedBox.shrink();
      return Positioned.fill(child: MusicLibraryScreen(container: container));
    },
  );
}

/// The library's Text scale at the rate its chrome follows it: [rate] of
/// its own and never below 100%, as the Now Playing speaker group menu
/// follows Now Playing's.
double libraryChromeScale(AppContainer c, [double rate = 0.7]) {
  final scale = c.settings.get(defs.libraryTextScale).toDouble() / 100;
  return math.max(1, 1 + (scale - 1) * rate);
}

/// A menu, sheet or dialog the library opens, at the library's Text
/// scale, its icons too, never below their normal size. Those are routes
/// above the library, so its own scale never reaches them.
class LibraryMenuText extends StatelessWidget {
  const LibraryMenuText({
    super.key,
    required this.container,
    required this.child,
  });

  final AppContainer container;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = libraryChromeScale(container, 1);
    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(media.textScaler.scale(1) * scale),
      ),
      child: IconTheme.merge(
        data: IconThemeData(size: 22 * scale),
        child: child,
      ),
    );
  }
}

/// The three layouts: roomy is a tablet with a sidebar, short a panel
/// under 600 tall like the Echo Show 5 with a rail, narrow a phone in
/// portrait with tabs along the bottom.
enum LibraryLayout { roomy, short, narrow }

LibraryLayout libraryLayout(Size size) => size.width < 640
    ? LibraryLayout.narrow
    : size.height < 600
    ? LibraryLayout.short
    : LibraryLayout.roomy;

/// Where the library is: a top level place, then whatever was opened
/// from it.
class _Place {
  _Place(this.nav, {this.category, this.node});

  /// discover, search, browse, library or node.
  final String nav;
  final LibraryCategory? category;
  final LibraryItem? node;

  String get key => '$nav:${category?.key ?? ''}:${node?.id ?? ''}';
}

/// An album, playlist, artist or folder opened on top of a place.
class _Opened {
  _Opened(this.item, {required this.folder});

  final LibraryItem item;

  /// A folder lists its children as rows; anything else is a detail page.
  final bool folder;
  Future<Object>? future;
}

class MusicLibraryScreen extends StatefulWidget {
  const MusicLibraryScreen({super.key, required this.container});

  final AppContainer container;

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen> {
  AppContainer get c => widget.container;

  LibrarySource? _source;
  _Place _place = _Place('discover');
  final _stack = <_Opened>[];
  final _futures = <String, Future<Object>>{};
  Future<List<LibraryCategory>>? _categories;
  Future<LibraryPage>? _roots;
  Timer? _idle;

  final _query = TextEditingController();
  final _queryFocus = FocusNode();
  Timer? _debounce;
  String _searched = '';
  String? _searchKind;

  /// Set once the library opens a sheet, a menu or a dialog of its own.
  bool _routesOpened = false;

  /// The queue panel is open: beside the library on a roomy screen, in
  /// place of it on a smaller one.
  bool _queueOpen = false;

  /// Redraws the library when its look changes under it, from the remote
  /// admin while it is open.
  StreamSubscription<SettingChanged>? _looks;

  @override
  void initState() {
    super.initState();
    c.musicLibrary.visible.addListener(_closeRoutes);
    c.screensaver.activeView.addListener(_closeRoutes);
    c.musicLibrary.source.addListener(_sourceChanged);
    c.musicLibrary.reopened.addListener(_reopen);
    c.musicLibrary.pick.addListener(_pickChanged);
    c.musicLibrary.backHandler = _onBack;
    _looks = c.bus.on<SettingChanged>().listen((e) {
      if (mounted &&
          (e.key == defs.librarySquareArtwork.key ||
              e.key == defs.libraryGridDensity.key ||
              e.key == defs.libraryTextScale.key ||
              e.key == defs.librarySourcePicker.key ||
              e.key == defs.librarySpeakerPill.key)) {
        setState(() {});
      }
    });
    _sourceChanged();
    _takeOpening();
    _armIdle();
  }

  void _reopen() {
    _armIdle();
    setState(_takeOpening);
  }

  /// Land where an open asked to: a search for a voice request's words,
  /// or one of the source's lists.
  void _takeOpening() {
    final opening = c.musicLibrary.opening;
    c.musicLibrary.opening = null;
    final source = _source;
    if (opening == null || source == null) return;
    _stack.clear();
    _queueOpen = false;
    final query = opening.query;
    if (query != null && source.hasSearch) {
      _query.text = query;
      _searched = query;
      _searchKind = null;
      _place = _Place('search');
      return;
    }
    final category = source.categories
        .where((c) => c.key == opening.category)
        .firstOrNull;
    if (category != null) _place = _Place('library', category: category);
  }

  @override
  void dispose() {
    c.musicLibrary.visible.removeListener(_closeRoutes);
    c.screensaver.activeView.removeListener(_closeRoutes);
    c.musicLibrary.source.removeListener(_sourceChanged);
    c.musicLibrary.reopened.removeListener(_reopen);
    c.musicLibrary.pick.removeListener(_pickChanged);
    if (c.musicLibrary.backHandler == _onBack) {
      c.musicLibrary.backHandler = null;
    }
    _idle?.cancel();
    _debounce?.cancel();
    unawaited(_looks?.cancel());
    _query.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  void _armIdle() {
    _idle?.cancel();
    final minutes =
        int.tryParse(c.settings.get(defs.libraryIdleCloseMinutes)) ?? 0;
    if (minutes <= 0) return;
    _idle = Timer(
      Duration(minutes: minutes),
      () => c.musicLibrary.visible.value = false,
    );
  }

  void _sourceChanged() {
    final source = c.musicLibrary.source.value;
    if (identical(source, _source) && _source != null) return;
    setState(() {
      _source = source;
      _stack.clear();
      _futures.clear();
      _searched = '';
      _searchKind = null;
      _query.clear();
      _categories = source?.availableCategories();
      _roots = source is HaLibrarySource ? _loadRoots(source) : null;
      _place = source == null || source.hasDiscover
          ? _Place('discover')
          : source is HaLibrarySource
          ? _Place('browse')
          : _Place('library', category: source.categories.firstOrNull);
    });
  }

  Future<LibraryPage> _loadRoots(HaLibrarySource source) async {
    final page = await source.browse(null);
    // Search shows once the speaker's features are known.
    if (mounted) setState(() {});
    return page;
  }

  /// A Home Assistant speaker owns its tree, so a new pick reloads it.
  void _pickChanged() {
    final source = _source;
    if (source is! HaLibrarySource) {
      if (mounted) setState(() {});
      return;
    }
    unawaited(
      source.follow(c.musicLibrary.pick.value).then((_) {
        if (!mounted) return;
        setState(() {
          _stack.clear();
          _futures.clear();
          _roots = _loadRoots(source);
          if (_place.nav == 'node') _place = _Place('browse');
        });
      }),
    );
  }

  void _go(_Place place) {
    setState(() {
      _place = place;
      _stack.clear();
    });
    if (place.nav == 'search') {
      _queryFocus.requestFocus();
    } else {
      _queryFocus.unfocus();
    }
  }

  void _open(LibraryItem item) {
    final detail = const {
      LibraryKind.album,
      LibraryKind.playlist,
      LibraryKind.artist,
      LibraryKind.podcast,
      LibraryKind.genre,
    }.contains(item.kind);
    setState(() => _stack.add(_Opened(item, folder: !detail)));
  }

  void _back() {
    if (_stack.isEmpty) return;
    setState(() => _stack.removeLast());
  }

  void _close() => c.musicLibrary.visible.value = false;

  /// The library's sheets, menus and dialogs are routes above the kiosk,
  /// so they would stay up over the screensaver or the dashboard once the
  /// library is gone: they go when it closes or a screensaver comes up,
  /// Now Playing over the library included.
  void _closeRoutes() {
    final closing =
        !c.musicLibrary.visible.value || c.screensaver.activeView.value != null;
    if (!closing || !_routesOpened || !mounted) return;
    final route = ModalRoute.of(context);
    if (route == null || route.isCurrent) return;
    Navigator.of(context).popUntil((r) => r == route);
  }

  /// Run [show], which opens a route of the library's own.
  Future<T> _present<T>(Future<T> Function() show) {
    _routesOpened = true;
    return show();
  }

  bool _onBack() {
    if (_queueOpen) {
      setState(() => _queueOpen = false);
      return true;
    }
    if (_stack.isEmpty) return false;
    _back();
    return true;
  }

  void _onQuery(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || text.trim() == _searched) return;
      if (text.trim().isNotEmpty) widget.container.musicLibrary.noteSearch();
      setState(() {
        _searched = text.trim();
        _searchKind = null;
        _stack.clear();
      });
    });
  }

  Future<Object> _remember(String key, Future<Object> Function() load) =>
      _futures.putIfAbsent(key, load);

  // ── Playing ───────────────────────────────────────────────────────

  Future<void> _play(
    LibraryItem item,
    PlayMode mode, {
    LibraryItem? within,
  }) async {
    final s = l10n(context);
    final error = await c.musicLibrary.play(item, mode, within: within);
    if (!mounted) return;
    if (error == 'no_speaker') {
      await _present(
        () => showSpeakersSheet(
          context,
          c,
          source: _source?.key,
          prompt: s.libraryPickSpeakerHint,
        ),
      );
      return;
    }
    if (error != null) {
      showToast(
        context,
        source: 'music_library',
        title: s.libraryPlayFailed,
        message: error,
        kind: ToastKind.error,
      );
      return;
    }
    // Music starting is its own confirmation: the player bar picks it up.
    // Queuing changes nothing on screen, so it still says what happened.
    if (mode != PlayMode.next && mode != PlayMode.add) return;
    showToast(
      context,
      source: 'music_library',
      title: mode == PlayMode.next ? s.libraryPlaysNext : s.libraryAddedToQueue,
      message: item.title,
      kind: ToastKind.success,
      actionLabel: c.sendspin.queueAvailable ? s.libraryView : null,
      onAction: c.sendspin.queueAvailable ? _openQueue : null,
    );
  }

  Future<void> _openQueue() async => setState(() => _queueOpen = true);

  Future<void> _toggleQueue() async => setState(() => _queueOpen = !_queueOpen);

  Widget _queuePanel({bool docked = false}) => LibraryQueuePanel(
    container: c,
    docked: docked,
    present: _present,
    onClose: () => setState(() => _queueOpen = false),
  );

  Future<void> _tap(LibraryItem item, {LibraryItem? within}) async {
    // A Home Assistant root opened from the Browse page is a sidebar
    // entry too.
    if (item.expandable &&
        _source is HaLibrarySource &&
        _place.nav == 'browse' &&
        _stack.isEmpty) {
      _go(_Place('node', node: item));
    } else if (item.expandable) {
      _open(item);
    } else if (item.playable) {
      await _play(item, PlayMode.replace, within: within);
    }
  }

  Future<void> _menu(
    BuildContext anchor,
    LibraryItem item, {
    LibraryItem? within,
  }) async {
    final s = l10n(context);
    final source = _source;
    if (source == null) return;
    final radio =
        source.hasRadioMode &&
        const {
          LibraryKind.track,
          LibraryKind.artist,
          LibraryKind.album,
          LibraryKind.playlist,
        }.contains(item.kind);
    final artists = source.key == 'ma'
        ? [
            for (final a
                in ((item.raw as Map?)?['artists'] as List? ?? const [])
                    .whereType<Map>())
              a,
          ]
        : const <Map>[];
    final actions = <(IconData, String, Future<void> Function())>[
      if (item.playable) ...[
        (
          Icons.play_arrow_rounded,
          s.libraryPlayNow,
          () => _play(item, PlayMode.now),
        ),
        (
          Icons.queue_play_next_rounded,
          s.libraryPlayNext,
          () => _play(item, PlayMode.next),
        ),
        (
          Icons.playlist_add_rounded,
          s.libraryAddToQueue,
          () => _play(item, PlayMode.add),
        ),
      ],
      if (radio)
        (
          Icons.radio_outlined,
          s.libraryStartRadio,
          () => _play(item, PlayMode.radio),
        ),
      if (artists.isNotEmpty && item.kind != LibraryKind.artist)
        (
          Icons.person_outline_rounded,
          s.libraryGoToArtist,
          () async => _open(
            LibraryItem(
              id: '${artists.first['uri'] ?? ''}',
              kind: LibraryKind.artist,
              title: '${artists.first['name'] ?? ''}',
              expandable: true,
              raw: artists.first,
            ),
          ),
        ),
      if (source.hasFavorites &&
          item.kind != LibraryKind.folder &&
          item.kind != LibraryKind.genre)
        (
          item.favorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          item.favorite ? s.libraryRemoveFavorite : s.libraryAddFavorite,
          () async {
            final ok = await source.setFavorite(item, !item.favorite);
            if (!mounted) return;
            showToast(
              context,
              source: 'music_library',
              title: ok
                  ? (item.favorite
                        ? s.libraryRemovedFavorite
                        : s.libraryAddedFavorite)
                  : s.libraryFavoriteFailed,
              message: item.title,
              kind: ok ? ToastKind.success : ToastKind.error,
            );
          },
        ),
    ];
    if (actions.isEmpty) return;
    final layout = libraryLayout(MediaQuery.sizeOf(context));
    Future<void> Function()? chosen;
    if (layout == LibraryLayout.narrow) {
      chosen = await _present(
        () => showModalBottomSheet<Future<void> Function()>(
          context: context,
          showDragHandle: true,
          builder: (context) => LibraryMenuText(
            container: c,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final (icon, label, run) in actions)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      leading: Icon(icon),
                      title: Text(label),
                      onTap: () => Navigator.of(context).pop(run),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      final box = anchor.findRenderObject() as RenderBox?;
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox?;
      if (box == null || overlay == null) return;
      final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
      chosen = await _present(
        () => showMenu<Future<void> Function()>(
          context: context,
          position: RelativeRect.fromRect(
            topLeft & box.size,
            Offset.zero & overlay.size,
          ),
          items: [
            for (final (icon, label, run) in actions)
              PopupMenuItem(
                value: run,
                child: LibraryMenuText(
                  container: c,
                  child: Row(
                    children: [
                      Icon(icon),
                      const SizedBox(width: 14),
                      Text(label),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }
    await chosen?.call();
  }

  // ── Pieces ────────────────────────────────────────────────────────

  String _sourceName(UiStrings s, String key) => switch (key) {
    'ha' => s.librarySourceHa,
    'sonos' => s.librarySourceSonos,
    _ => s.librarySourceMa,
  };

  String _categoryName(UiStrings s, String key) => switch (key) {
    'artists' => s.libraryArtists,
    'albums' => s.libraryAlbums,
    'tracks' => s.libraryTracks,
    'playlists' => s.libraryPlaylists,
    'radios' || 'radio' => s.libraryRadio,
    'podcasts' => s.libraryPodcasts,
    'audiobooks' => s.libraryAudiobooks,
    'favorites' => s.libraryFavorites,
    'sonos_playlists' => s.librarySonosPlaylists,
    'recent' => s.libraryRecentlyPlayed,
    'added' => s.libraryRecentlyAdded,
    'genres' => s.libraryBrowseByGenre,
    'more' => s.libraryMoreResults,
    _ => key,
  };

  IconData _categoryIcon(String key) => switch (key) {
    'artists' => Icons.person_outline_rounded,
    'albums' => Icons.album_outlined,
    'tracks' => Icons.music_note_outlined,
    'playlists' || 'sonos_playlists' => Icons.queue_music_rounded,
    'radios' => Icons.radio_outlined,
    'podcasts' => Icons.podcasts_rounded,
    'audiobooks' => Icons.menu_book_outlined,
    'favorites' => Icons.favorite_border_rounded,
    _ => Icons.folder_outlined,
  };

  /// Whether the library shows its source, which Show source selection
  /// can turn off.
  bool get _showsSource =>
      c.musicLibrary.available.isNotEmpty &&
      c.settings.get(defs.librarySourcePicker);

  /// Whether the source can be switched here: more than one is set up and
  /// the picker is shown.
  bool get _switchesSource =>
      _showsSource && c.musicLibrary.available.length > 1;

  /// Whether the header carries the speaker pill, which Show speaker
  /// selection pill can turn off.
  bool get _showsSpeakerPill => c.settings.get(defs.librarySpeakerPill);

  Future<void> _pickSource() async {
    final s = l10n(context);
    final keys = c.musicLibrary.available;
    final current = _source?.key;
    final picked = await _present(
      () => showDialog<String>(
        context: context,
        builder: (context) => LibraryMenuText(
          container: c,
          child: SimpleDialog(
            title: Text(s.librarySource),
            children: [
              for (final key in keys)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: _SourceMark(
                    source: key,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(_sourceName(s, key)),
                  subtitle: Text(switch (key) {
                    'ha' => s.librarySourceHaHint,
                    'sonos' => s.librarySourceSonosHint,
                    _ => s.librarySourceMaHint,
                  }),
                  trailing: key == current
                      ? Icon(
                          Icons.check_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(key),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && picked != current) {
      await c.musicLibrary.setSource(picked);
    }
  }

  Future<void> _pickSpeaker() =>
      _present(() => showSpeakersSheet(context, c, source: _source?.key));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = libraryLayout(MediaQuery.sizeOf(context));
    final media = MediaQuery.of(context);
    final scale = c.settings.get(defs.libraryTextScale).toDouble() / 100;
    return Listener(
      onPointerDown: (_) => _armIdle(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: Material(
          color: theme.colorScheme.surface,
          // Text scale on top of the device's own text size.
          child: MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(media.textScaler.scale(1) * scale),
            ),
            child: SafeArea(
              child: ValueListenableBuilder<String>(
                valueListenable: c.musicLibrary.pickName,
                builder: (context, _, _) => switch (layout) {
                  LibraryLayout.roomy => _roomy(context),
                  LibraryLayout.short => _short(context),
                  LibraryLayout.narrow => _narrow(context),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The tabs the rail and the bottom bar offer for the source.
  List<(String, IconData, String)> _tabs(UiStrings s) {
    final source = _source;
    if (source == null) return const [];
    return [
      if (source.hasDiscover)
        ('discover', Icons.explore_outlined, s.libraryDiscover),
      if (source.hasSearch) ('search', Icons.search_rounded, s.librarySearch),
      if (source.categories.isNotEmpty)
        ('library', Icons.library_music_outlined, s.libraryLibrary),
      if (source.hasBrowse) ('browse', Icons.folder_outlined, s.libraryBrowse),
    ];
  }

  String get _tabNav => _place.nav == 'node' ? 'browse' : _place.nav;

  /// While the keyboard is up the results get the room the player bar and
  /// the tabs would take.
  bool _keyboard(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom > 0;

  /// The mark and the library's name, grown with the chrome and shrunk
  /// to fit where a long name meets a narrow sidebar.
  Widget _eyebrow(LibraryLayout layout) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: _chrome(
      KsEyebrow(
        label: l10n(context).libraryTitle,
        compact: layout != LibraryLayout.roomy,
        scale: _chromeScale(),
      ),
      // The caps carry the scale: the device's own text size only.
      rate: 0,
    ),
  );

  /// [child] with the text of the library's chrome: its navigation,
  /// pickers and the player bar's track and times. They follow Text scale
  /// at 70% of its rate and stay at their normal size below 100%, as the
  /// Now Playing speaker group menu does, so the content gets the room.
  /// A [rate] of 0 keeps the device's own size.
  /// The screen's own context sits above the scaled text.
  Widget _chrome(Widget child, {double rate = 0.7}) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(
          media.textScaler.scale(1) * _chromeScale(rate),
        ),
      ),
      child: child,
    );
  }

  double _chromeScale([double rate = 0.7]) => libraryChromeScale(c, rate);

  Widget _closeButton({double size = 26}) => IconButton(
    icon: const Icon(Icons.close),
    iconSize: size,
    tooltip: l10n(context).commonClose,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    onPressed: _close,
  );

  Widget _backButton() => IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    tooltip: l10n(context).commonBack,
    onPressed: _back,
  );

  // ── Roomy: sidebar, header, content, player bar ──────────────────

  Widget _roomy(BuildContext context) {
    final s = l10n(context);
    final theme = Theme.of(context);
    // The sidebar, the docked queue and a list at least as wide as either.
    final dock = MediaQuery.sizeOf(context).width >= 256 + 400 + 400;
    final title = _stack.isNotEmpty
        ? null
        : switch (_place.nav) {
            'discover' => s.libraryDiscover,
            'browse' => s.libraryBrowse,
            'library' => _categoryName(s, _place.category?.key ?? ''),
            'node' => _place.node?.title,
            _ => null,
          };
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 256, child: _chrome(_sidebar(context))),
              // The queue docks beside the content where both have room,
              // and takes the content's place on a tablet in portrait.
              if (_queueOpen && !dock)
                Expanded(child: _queuePanel())
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 76,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 20, 0),
                          child: Row(
                            children: [
                              if (_stack.isNotEmpty) _backButton(),
                              if (_place.nav == 'search' && _stack.isEmpty)
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 560,
                                      ),
                                      child: _searchField(52),
                                    ),
                                  ),
                                )
                              else if (title != null)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(fontSize: 34),
                                          ),
                                        ),
                                        if (_sortButton() case final sort?) ...[
                                          const SizedBox(width: 8),
                                          sort,
                                        ],
                                      ],
                                    ),
                                  ),
                                )
                              else
                                const Spacer(),
                              const SizedBox(width: 12),
                              if (_showsSpeakerPill) ...[
                                _speakerPill(height: 44),
                                const SizedBox(width: 4),
                              ],
                              _closeButton(size: 28),
                            ],
                          ),
                        ),
                      ),
                      if (_place.nav == 'search' && _stack.isEmpty)
                        _searchChips(const EdgeInsets.fromLTRB(12, 0, 32, 12)),
                      Expanded(
                        child: _content(
                          context,
                          LibraryLayout.roomy,
                          const EdgeInsets.fromLTRB(12, 4, 32, 24),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_queueOpen && dock)
                SizedBox(width: 400, child: _queuePanel(docked: true)),
            ],
          ),
        ),
        if (!_keyboard(context))
          _chrome(
            _MiniPlayer(
              container: c,
              layout: LibraryLayout.roomy,
              onQueue: _toggleQueue,
              queueOpen: _queueOpen,
              onSpeakers: _pickSpeaker,
            ),
          ),
      ],
    );
  }

  Widget _sidebar(BuildContext context) {
    final s = l10n(context);
    final theme = Theme.of(context);
    final source = _source;
    final key = source?.key ?? '';
    final heading = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: .8,
      color: theme.colorScheme.onSurfaceVariant,
    );
    Widget item(IconData icon, String label, bool on, VoidCallback onTap) =>
        _NavItem(icon: icon, label: label, selected: on, onTap: onTap);
    final children = <Widget>[
      // The source box starts level with the content: the header's 76
      // and the list's 4, less the 20 above and the eyebrow's 28.
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 32),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _eyebrow(LibraryLayout.roomy),
        ),
      ),
      if (_showsSource)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Ks.radiusRow),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _switchesSource ? _pickSource : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: _SourceMark(
                          source: key,
                          size: 20,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.librarySource,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _sourceName(s, key),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_switchesSource)
                      Icon(
                        Icons.expand_more_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      if (source != null) ...[
        if (source.hasDiscover)
          item(
            Icons.explore_outlined,
            s.libraryDiscover,
            _place.nav == 'discover',
            () => _go(_Place('discover')),
          ),
        if (source.hasSearch)
          item(
            Icons.search_rounded,
            s.librarySearch,
            _place.nav == 'search',
            () => _go(_Place('search')),
          ),
        if (source.hasBrowse && source is! HaLibrarySource)
          item(
            Icons.folder_outlined,
            s.libraryBrowse,
            _place.nav == 'browse',
            () => _go(_Place('browse')),
          ),
        if (source is HaLibrarySource)
          FutureBuilder<LibraryPage>(
            future: _roots,
            builder: (context, snap) =>
                (snap.data?.items ?? const <LibraryItem>[]).isEmpty
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                        child: Text(
                          s.libraryBrowse.toUpperCase(),
                          style: heading,
                        ),
                      ),
                      for (final root
                          in snap.data?.items ?? const <LibraryItem>[])
                        item(
                          Icons.folder_outlined,
                          root.title,
                          _place.nav == 'node' && _place.node?.id == root.id,
                          () => _go(_Place('node', node: root)),
                        ),
                    ],
                  ),
          )
        else
          FutureBuilder<List<LibraryCategory>>(
            future: _categories,
            builder: (context, snap) {
              final categories = snap.data ?? const <LibraryCategory>[];
              if (categories.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                    child: Text(s.libraryLibrary.toUpperCase(), style: heading),
                  ),
                  for (final cat in categories)
                    item(
                      _categoryIcon(cat.key),
                      _categoryName(s, cat.key),
                      _place.nav == 'library' &&
                          _place.category?.key == cat.key,
                      () => _go(_Place('library', category: cat)),
                    ),
                ],
              );
            },
          ),
      ],
    ];
    // The eyebrow and the source stay put over the list on a tall screen.
    // A shorter one scrolls them away with it, so the list keeps the room.
    final header = children.take(_showsSource ? 2 : 1).toList();
    final nav = children.skip(header.length).toList();
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxHeight < 560) {
          return EdgeFade(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
              children: children,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: header,
              ),
            ),
            Expanded(
              child: EdgeFade(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
                  children: nav,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Short: top bar, rail, content, player bar ────────────────────

  Widget _short(BuildContext context) {
    final s = l10n(context);
    final tabs = _tabs(s);
    final searching = _place.nav == 'search' && _stack.isEmpty;
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 8, 0),
            child: Row(
              children: [
                Flexible(child: _eyebrow(LibraryLayout.short)),
                const SizedBox(width: 12),
                if (_stack.isNotEmpty) _backButton(),
                if (searching)
                  Expanded(child: _searchField(44))
                else
                  const Spacer(),
                const SizedBox(width: 8),
                if (_showsSpeakerPill) _speakerPill(height: 40, maxWidth: 260),
                _closeButton(),
              ],
            ),
          ),
        ),
        if (_queueOpen)
          Expanded(child: _queuePanel())
        else
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 88,
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      if (_switchesSource)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Tooltip(
                            message: s.librarySource,
                            child: Material(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: _pickSource,
                                child: SizedBox(
                                  width: 64,
                                  height: 44,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Semantics(
                                        label: _sourceName(
                                          s,
                                          _source?.key ?? '',
                                        ),
                                        child: _SourceMark(
                                          source: _source?.key ?? '',
                                          size: 22,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.expand_more_rounded,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (tabs.length > 1)
                        for (final (nav, icon, label) in tabs)
                          _chrome(
                            _TabItem(
                              icon: icon,
                              label: label,
                              selected: _tabNav == nav,
                              onTap: () => _go(_tabPlace(nav)),
                            ),
                          ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (searching)
                        _searchChips(const EdgeInsets.fromLTRB(4, 0, 16, 10)),
                      if (_place.nav == 'library' && _stack.isEmpty)
                        _categoryBar(const EdgeInsets.fromLTRB(4, 0, 16, 10)),
                      Expanded(
                        child: _content(
                          context,
                          LibraryLayout.short,
                          const EdgeInsets.fromLTRB(4, 0, 16, 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (!_keyboard(context))
          _chrome(
            _MiniPlayer(
              container: c,
              layout: LibraryLayout.short,
              onQueue: _toggleQueue,
              queueOpen: _queueOpen,
              onSpeakers: _pickSpeaker,
            ),
          ),
      ],
    );
  }

  _Place _tabPlace(String nav) {
    if (nav != 'library') return _Place(nav);
    final first = _place.category ?? _source?.categories.firstOrNull;
    return _Place('library', category: first);
  }

  // ── Narrow: eyebrow row, pickers, content, player bar, tabs ──────

  Widget _narrow(BuildContext context) {
    final s = l10n(context);
    final tabs = _tabs(s);
    final searching = _place.nav == 'search' && _stack.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _eyebrow(LibraryLayout.narrow),
                  ),
                ),
                _closeButton(size: 24),
              ],
            ),
          ),
        ),
        if (_queueOpen) Expanded(child: _queuePanel()),
        if (!_queueOpen) ...[
          // Nothing left for the row on the top level with neither pill.
          if (_stack.isNotEmpty ||
              searching ||
              _switchesSource ||
              _showsSpeakerPill)
            SizedBox(
              height: 56,
              child: Padding(
                padding: EdgeInsets.fromLTRB(_stack.isEmpty ? 16 : 6, 0, 16, 0),
                child: Row(
                  children: [
                    if (_stack.isNotEmpty) ...[
                      _backButton(),
                      if (_showsSpeakerPill) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _speakerPill(height: 40),
                          ),
                        ),
                      ],
                    ] else if (searching) ...[
                      Expanded(child: _searchField(48)),
                      if (_showsSpeakerPill) ...[
                        const SizedBox(width: 8),
                        _speakerPill(height: 40, iconOnly: true),
                      ],
                    ] else ...[
                      if (_switchesSource) ...[
                        Flexible(child: _sourcePill()),
                        const SizedBox(width: 8),
                      ],
                      if (_showsSpeakerPill)
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _speakerPill(height: 40),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          if (searching) _searchChips(const EdgeInsets.fromLTRB(16, 2, 16, 12)),
          if (_place.nav == 'library' && _stack.isEmpty)
            _categoryBar(const EdgeInsets.fromLTRB(16, 2, 16, 12)),
          Expanded(
            child: _content(
              context,
              LibraryLayout.narrow,
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          ),
        ],
        if (!_keyboard(context))
          _chrome(
            _MiniPlayer(
              container: c,
              layout: LibraryLayout.narrow,
              onQueue: _toggleQueue,
              queueOpen: _queueOpen,
              onSpeakers: _pickSpeaker,
            ),
          ),
        if (tabs.length > 1 && !_keyboard(context) && !_queueOpen)
          SizedBox(
            // The tab label's line grows with the chrome's text.
            height: 52 + 16 * _chromeScale(),
            child: Row(
              children: [
                for (final (nav, icon, label) in tabs)
                  Expanded(
                    child: _chrome(
                      _TabItem(
                        icon: icon,
                        label: label,
                        selected: _tabNav == nav,
                        onTap: () => _go(_tabPlace(nav)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _sourcePill() {
    final s = l10n(context);
    final key = _source?.key ?? '';
    return _chrome(
      _Pill(
        height: 40,
        icon: _SourceMark(
          source: key,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: _sourceName(s, key),
        onTap: _pickSource,
      ),
    );
  }

  Widget _speakerPill({
    required double height,
    double? maxWidth,
    bool iconOnly = false,
  }) {
    final s = l10n(context);
    final source = _source;
    final needs = source == null || !c.musicLibrary.pickIn(source.key);
    final label = needs ? s.libraryChooseSpeaker : c.sendspin.playerChipName;
    return _chrome(
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? 300),
        child: _Pill(
          height: height,
          icon: Icon(
            Icons.speaker_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: iconOnly ? null : label,
          semanticLabel: '${s.librarySpeakers}: $label',
          onTap: _pickSpeaker,
        ),
      ),
    );
  }

  Widget _searchField(double height) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: TextField(
        controller: _query,
        focusNode: _queryFocus,
        autofocus: _searched.isEmpty,
        textInputAction: TextInputAction.search,
        onChanged: _onQuery,
        onSubmitted: (text) {
          _debounce?.cancel();
          if (text.trim().isNotEmpty && text.trim() != _searched) {
            widget.container.musicLibrary.noteSearch();
          }
          setState(() {
            _searched = text.trim();
            _searchKind = null;
          });
        },
        decoration: InputDecoration(
          hintText: s.librarySearchHint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: ListenableBuilder(
            listenable: _query,
            builder: (context, _) => _query.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: s.librarySearchClear,
                    onPressed: () {
                      _query.clear();
                      setState(() => _searched = '');
                      _queryFocus.requestFocus();
                    },
                  ),
          ),
          filled: true,
          fillColor: scheme.surfaceContainer,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _chips(
    EdgeInsets padding,
    List<(String?, String)> chips,
    String? selected,
    ValueChanged<String?> onPick,
  ) => SizedBox(
    height: 36 + padding.vertical,
    child: Padding(
      padding: padding,
      child: EdgeFade(
        axis: Axis.horizontal,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final (key, label) in chips)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(label),
                  selected: key == selected,
                  showCheckmark: false,
                  onSelected: (_) => onPick(key),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _searchChips(EdgeInsets padding) {
    final s = l10n(context);
    final source = _source;
    if (source == null || _searched.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<Object>(
      future: _remember(
        'search:${source.key}:$_searched',
        () => source.search(_searched),
      ),
      builder: (context, snap) {
        final shelves = snap.data is List<LibraryShelf>
            ? snap.data! as List<LibraryShelf>
            : const <LibraryShelf>[];
        if (shelves.length < 2) return const SizedBox.shrink();
        return _chips(
          padding,
          [
            (null, s.librarySearchAll),
            for (final shelf in shelves)
              (shelf.key ?? shelf.title, _shelfTitle(s, shelf)),
          ],
          _searchKind,
          (key) => setState(() => _searchKind = key),
        );
      },
    );
  }

  Widget _categoryChips(EdgeInsets padding) {
    final s = l10n(context);
    return FutureBuilder<List<LibraryCategory>>(
      future: _categories,
      builder: (context, snap) {
        final categories = snap.data ?? const <LibraryCategory>[];
        if (categories.length < 2) return const SizedBox.shrink();
        return _chips(
          padding,
          [for (final cat in categories) (cat.key, _categoryName(s, cat.key))],
          _place.category?.key,
          (key) => _go(
            _Place(
              'library',
              category: categories.firstWhere((c) => c.key == key),
            ),
          ),
        );
      },
    );
  }

  /// The category chips with the sort button at their end.
  Widget _categoryBar(EdgeInsets padding) {
    final sort = _sortButton(slim: true);
    if (sort == null) return _categoryChips(padding);
    return Row(
      children: [
        Expanded(child: _categoryChips(padding.copyWith(right: 8))),
        Padding(
          padding: EdgeInsets.fromLTRB(
            0,
            padding.top,
            padding.right - 8,
            padding.bottom,
          ),
          child: sort,
        ),
      ],
    );
  }

  /// The button that opens the sort menu of the list on screen, or null
  /// where the source lists in an order of its own. [slim] keeps it to
  /// the height of the chips beside it.
  Widget? _sortButton({bool slim = false}) {
    final source = _source;
    final category = _place.category;
    if (source == null ||
        category == null ||
        _place.nav != 'library' ||
        _stack.isNotEmpty ||
        source.sorts.isEmpty) {
      return null;
    }
    return Builder(
      builder: (anchor) => IconButton(
        icon: const Icon(Icons.sort_rounded),
        padding: slim ? EdgeInsets.zero : null,
        constraints: slim
            ? const BoxConstraints.tightFor(width: 44, height: 36)
            : null,
        tooltip: l10n(context).librarySort,
        onPressed: () => _sortMenu(anchor, source, category),
      ),
    );
  }

  String _sortName(UiStrings s, LibrarySort sort) => switch (sort) {
    LibrarySort.name => s.librarySortAToZ,
    LibrarySort.nameDesc => s.librarySortZToA,
    LibrarySort.recentlyPlayed => s.libraryRecentlyPlayed,
    LibrarySort.recentlyAdded => s.libraryRecentlyAdded,
    LibrarySort.mostPlayed => s.librarySortMostPlayed,
  };

  /// The orders the source takes and, on Artists, album artists only.
  /// A bottom sheet on a phone, a menu at the button elsewhere.
  Future<void> _sortMenu(
    BuildContext anchor,
    LibrarySource source,
    LibraryCategory category,
  ) async {
    final s = l10n(context);
    final library = c.musicLibrary;
    final current = library.sortFor(source, category);
    final albumArtists = category.key == 'artists' && source.hasAlbumArtists;
    final options = <(String, bool, Future<void> Function())>[
      for (final sort in source.sorts)
        (
          _sortName(s, sort),
          sort == current,
          () => library.setSort(category, sort),
        ),
      if (albumArtists)
        (
          s.libraryAlbumArtistsOnly,
          library.albumArtists,
          () => library.setAlbumArtists(!library.albumArtists),
        ),
    ];
    final scheme = Theme.of(context).colorScheme;
    Widget check(bool on) => Icon(
      Icons.check_rounded,
      color: on ? scheme.primary : Colors.transparent,
    );
    Future<void> Function()? chosen;
    if (libraryLayout(MediaQuery.sizeOf(context)) == LibraryLayout.narrow) {
      chosen = await _present(
        () => showModalBottomSheet<Future<void> Function()>(
          context: context,
          showDragHandle: true,
          builder: (context) => LibraryMenuText(
            container: c,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, (label, on, run)) in options.indexed) ...[
                      if (albumArtists && i == options.length - 1)
                        const Divider(height: 16),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        leading: check(on),
                        title: Text(label),
                        onTap: () => Navigator.of(context).pop(run),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      final box = anchor.findRenderObject() as RenderBox?;
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox?;
      if (box == null || overlay == null) return;
      final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
      chosen = await _present(
        () => showMenu<Future<void> Function()>(
          context: context,
          position: RelativeRect.fromRect(
            topLeft & box.size,
            Offset.zero & overlay.size,
          ),
          items: [
            for (final (i, (label, on, run)) in options.indexed) ...[
              if (albumArtists && i == options.length - 1)
                const PopupMenuDivider(),
              PopupMenuItem(
                value: run,
                child: LibraryMenuText(
                  container: c,
                  child: Row(
                    children: [
                      check(on),
                      const SizedBox(width: 14),
                      Flexible(child: Text(label)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
    if (chosen == null) return;
    await chosen();
    if (mounted) setState(() {});
  }

  String _shelfTitle(UiStrings s, LibraryShelf shelf) =>
      shelf.key == null ? shelf.title : _categoryName(s, shelf.key!);

  // ── Content ───────────────────────────────────────────────────────

  Widget _content(BuildContext context, LibraryLayout layout, EdgeInsets pad) {
    final s = l10n(context);
    final source = _source;
    if (source == null) {
      return _Message(
        icon: Icons.library_music_outlined,
        text: s.libraryNoSource,
      );
    }
    final top = _stack.lastOrNull;
    if (top != null) return _openedPage(context, layout, pad, top);
    return switch (_place.nav) {
      'discover' => _loaded(
        'discover',
        source.discover,
        (data) => _discover(context, layout, pad, data as List<LibraryShelf>),
      ),
      'search' =>
        _searched.isEmpty
            ? _Message(icon: Icons.search_rounded, text: s.librarySearchPrompt)
            : _loaded(
                'search:${source.key}:$_searched',
                () => source.search(_searched),
                (data) =>
                    _results(context, layout, pad, data as List<LibraryShelf>),
              ),
      'library' when _place.category != null => _list(
        context,
        layout,
        pad,
        source,
        _place.category!,
      ),
      'node' when _place.node != null => _loaded(
        'node:${_place.node!.id}',
        () => source.browse(_place.node),
        (data) => _rows(context, layout, pad, (data as LibraryPage).items),
      ),
      _ => _loaded(
        'browse:${source.key}',
        () => source is HaLibrarySource
            ? (_roots ??= _loadRoots(source))
            : source.browse(null),
        (data) => _rows(context, layout, pad, (data as LibraryPage).items),
      ),
    };
  }

  /// A library list in the order it was left in, loaded a page at a
  /// time. A new order or filter starts it over.
  Widget _list(
    BuildContext context,
    LibraryLayout layout,
    EdgeInsets pad,
    LibrarySource source,
    LibraryCategory category,
  ) {
    final sort = c.musicLibrary.sortFor(source, category);
    final albumArtists =
        category.key == 'artists' &&
        source.hasAlbumArtists &&
        c.musicLibrary.albumArtists;
    return _PagedList(
      key: ValueKey(
        '${source.key}:${category.key}:${sort?.name}:$albumArtists',
      ),
      load: (offset) => source.list(
        category,
        offset: offset,
        sort: sort,
        albumArtists: albumArtists,
      ),
      builder: (items, more) => _grid(context, layout, pad, items, more),
      empty: l10n(context).libraryEmpty,
    );
  }

  Widget _loaded(
    String key,
    Future<Object> Function() load,
    Widget Function(Object data) build,
  ) {
    final s = l10n(context);
    final future = _remember('${_source?.key}:$key', load);
    return FutureBuilder<Object>(
      key: ValueKey(key),
      future: future,
      builder: (context, snap) {
        if (snap.hasError) return _failure(key, snap.error);
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        final empty = switch (data) {
          final List<Object?> l => l.isEmpty,
          final LibraryPage p => p.items.isEmpty,
          _ => false,
        };
        if (empty) {
          return _Message(icon: Icons.music_off_outlined, text: s.libraryEmpty);
        }
        return build(data);
      },
    );
  }

  Widget _failure(String key, Object? error) {
    final s = l10n(context);
    final text = '$error';
    if (text == 'no_speaker') {
      return _Message(
        icon: Icons.speaker_outlined,
        text: s.libraryHaPickSpeaker,
        action: s.libraryChooseSpeaker,
        onAction: _pickSpeaker,
      );
    }
    return _Message(
      icon: Icons.cloud_off_outlined,
      text: '${s.libraryLoadFailed}\n$text',
      action: s.commonRetry,
      onAction: () => setState(() {
        _futures.remove('${_source?.key}:$key');
        _stack.lastOrNull?.future = null;
        if (_source is HaLibrarySource) {
          _roots = _loadRoots(_source! as HaLibrarySource);
        }
      }),
    );
  }

  double _cardWidth(LibraryLayout layout) =>
      _density *
      switch (layout) {
        LibraryLayout.roomy => 156,
        LibraryLayout.short => 112,
        LibraryLayout.narrow => 136,
      };

  /// The room under a card's cover: the gap, then the title and the
  /// subtitle at the text's scale.
  double _cardText(BuildContext context, LibraryLayout layout) {
    final short = layout == LibraryLayout.short;
    return (short ? 6 : 8) +
        MediaQuery.textScalerOf(context).scale(short ? 40 : 44);
  }

  /// Grid density as a factor on the size of a shelf's cards.
  double get _density => switch (c.settings.get(defs.libraryGridDensity)) {
    'comfortable' => 1.2,
    'compact' => 0.85,
    _ => 1.0,
  };

  Widget _discover(
    BuildContext context,
    LibraryLayout layout,
    EdgeInsets pad,
    List<LibraryShelf> shelves,
  ) {
    final s = l10n(context);
    final tiles = layout == LibraryLayout.short
        ? const <LibraryItem>[]
        : shelves.first.items.take(6).toList();
    final gap = layout == LibraryLayout.short ? 16.0 : 26.0;
    return EdgeFade(
      child: ListView(
        padding: pad,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (tiles.length >= 4) ...[
            _QuickTiles(
              container: c,
              items: tiles,
              columns: layout == LibraryLayout.roomy ? 3 : 2,
              // Two lines of the title, at the text's scale.
              height: math.max(
                layout == LibraryLayout.roomy ? 64 : 56,
                MediaQuery.textScalerOf(context).scale(38) + 18,
              ),
              onTap: _tap,
            ),
            SizedBox(height: gap),
          ],
          for (final (i, shelf) in shelves.indexed) ...[
            if (i > 0) SizedBox(height: gap),
            if (shelf.key == 'genres')
              _genres(context, layout, _shelfTitle(s, shelf), shelf.items)
            else
              _shelf(
                context,
                layout,
                _shelfTitle(s, shelf),
                shelf.items,
                // Recently played and the like mix kinds: say which.
                kindLabels: shelf.items.map((i) => i.kind).toSet().length > 1,
              ),
          ],
        ],
      ),
    );
  }

  /// Browse by genre: a grid of genre tiles, four across on a tablet.
  Widget _genres(
    BuildContext context,
    LibraryLayout layout,
    String title,
    List<LibraryItem> items,
  ) {
    final compact = layout == LibraryLayout.short;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: compact ? 17 : 21),
          ),
        ),
        LayoutBuilder(
          builder: (context, box) {
            final gap = compact ? 10.0 : 14.0;
            final columns = math.max(
              2,
              ((box.maxWidth + gap) / ((compact ? 170 : 220) + gap)).floor(),
            );
            final width = (box.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final item in items)
                  SizedBox(
                    width: width,
                    child: _GenreTile(
                      container: c,
                      item: item,
                      compact: compact,
                      onTap: () => _tap(item),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _shelf(
    BuildContext context,
    LibraryLayout layout,
    String title,
    List<LibraryItem> items, {
    LibraryItem? within,
    bool kindLabels = false,
  }) {
    final s = l10n(context);
    final theme = Theme.of(context);
    final width = _cardWidth(layout);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: layout == LibraryLayout.short ? 17 : 21,
            ),
          ),
        ),
        SizedBox(
          height: width + _cardText(context, layout),
          child: EdgeFade(
            axis: Axis.horizontal,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  SizedBox(width: layout == LibraryLayout.short ? 14 : 20),
              itemBuilder: (context, i) => SizedBox(
                width: width,
                child: _Card(
                  container: c,
                  item: items[i],
                  compact: layout == LibraryLayout.short,
                  kindLabel: kindLabels ? _kindName(s, items[i].kind) : null,
                  onTap: () => _tap(items[i], within: within),
                  onLongPress: (anchor) => _menu(anchor, items[i]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _results(
    BuildContext context,
    LibraryLayout layout,
    EdgeInsets pad,
    List<LibraryShelf> shelves,
  ) {
    final s = l10n(context);
    final picked = _searchKind == null
        ? null
        : shelves.where((x) => (x.key ?? x.title) == _searchKind).firstOrNull;
    if (picked != null) {
      return picked.items.every((i) => i.kind == LibraryKind.track)
          ? _rows(context, layout, pad, picked.items)
          : _grid(context, layout, pad, picked.items, false);
    }
    if (layout != LibraryLayout.roomy) {
      // One list, each row saying what it is.
      return _rows(context, layout, pad, [
        for (final shelf in shelves) ...shelf.items.take(6),
      ], kindLabels: true);
    }
    final tracks = shelves.where((x) => x.key == 'tracks').firstOrNull;
    final rest = [
      for (final shelf in shelves)
        if (shelf != tracks) shelf,
    ];
    return EdgeFade(
      child: ListView(
        padding: pad,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (tracks != null) ...[
            Text(
              s.libraryTracks,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 21),
            ),
            const SizedBox(height: 6),
            for (final t in tracks.items.take(5))
              _Row(
                container: c,
                item: t,
                onTap: () => _tap(t),
                onMore: (anchor) => _menu(anchor, t),
              ),
            const SizedBox(height: 22),
          ],
          for (final (i, shelf) in rest.indexed) ...[
            if (i > 0) const SizedBox(height: 22),
            _shelf(context, layout, _shelfTitle(s, shelf), shelf.items),
          ],
        ],
      ),
    );
  }

  Widget _grid(
    BuildContext context,
    LibraryLayout layout,
    EdgeInsets pad,
    List<LibraryItem> items,
    bool more,
  ) {
    if (items.isNotEmpty &&
        items.every(
          (i) => i.kind == LibraryKind.track || i.kind == LibraryKind.episode,
        )) {
      return _rows(context, layout, pad, items);
    }
    final spacing = layout == LibraryLayout.short ? 14.0 : 18.0;
    // The widest a tile may be at Standard.
    final widest = switch (layout) {
      LibraryLayout.roomy => 180.0,
      LibraryLayout.short => 140.0,
      LibraryLayout.narrow => 200.0,
    };
    // Grid density adds or takes away a column, so each step shows.
    final step = switch (c.settings.get(defs.libraryGridDensity)) {
      'comfortable' => -1,
      'compact' => 1,
      _ => 0,
    };
    return EdgeFade(
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth - pad.horizontal;
          final columns = math.max(
            2,
            (width / (widest + spacing)).ceil() + step,
          );
          final tile = (width - spacing * (columns - 1)) / columns;
          return GridView.builder(
            padding: pad,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: layout == LibraryLayout.short ? 14 : 20,
              crossAxisSpacing: spacing,
              // The cover, then room for the title and subtitle, which keep
              // their size whatever the density.
              mainAxisExtent: tile + _cardText(context, layout),
            ),
            itemCount: items.length + (more ? 1 : 0),
            itemBuilder: (context, i) => i >= items.length
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : _Card(
                    container: c,
                    item: items[i],
                    compact: layout == LibraryLayout.short,
                    onTap: () => _tap(items[i]),
                    onLongPress: (anchor) => _menu(anchor, items[i]),
                  ),
          );
        },
      ),
    );
  }

  Widget _rows(
    BuildContext context,
    LibraryLayout layout,
    EdgeInsets pad,
    List<LibraryItem> items, {
    LibraryItem? within,
    bool numbered = false,
    bool kindLabels = false,
    Widget? header,
  }) {
    final s = l10n(context);
    return EdgeFade(
      child: ListView.builder(
        padding: pad,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: items.length + (header == null ? 0 : 1),
        itemBuilder: (context, i) {
          if (header != null) {
            if (i == 0) return header;
            i--;
          }
          final item = items[i];
          return _Row(
            container: c,
            item: item,
            number: numbered ? i + 1 : null,
            kindLabel: kindLabels ? _kindName(s, item.kind) : null,
            dense: layout == LibraryLayout.short,
            onTap: () => _tap(item, within: within),
            onMore: item.playable || item.kind == LibraryKind.artist
                ? (anchor) => _menu(anchor, item, within: within)
                : null,
          );
        },
      ),
    );
  }

  String? _kindName(UiStrings s, LibraryKind kind) => switch (kind) {
    LibraryKind.artist => s.libraryKindArtist,
    LibraryKind.album => s.libraryKindAlbum,
    LibraryKind.track => s.libraryKindTrack,
    LibraryKind.playlist => s.libraryKindPlaylist,
    LibraryKind.radio => s.libraryKindRadio,
    LibraryKind.podcast => s.libraryKindPodcast,
    LibraryKind.episode => s.libraryKindEpisode,
    LibraryKind.audiobook => s.libraryKindAudiobook,
    LibraryKind.genre => s.libraryKindGenre,
    _ => null,
  };

  Widget _openedPage(
    BuildContext context,
    LibraryLayout layout,
    EdgeInsets pad,
    _Opened opened,
  ) {
    final source = _source!;
    final future = opened.future ??= opened.folder
        ? source.browse(opened.item)
        : source.open(opened.item);
    final s = l10n(context);
    return FutureBuilder<Object>(
      key: ObjectKey(opened),
      future: future,
      builder: (context, snap) {
        if (snap.hasError) return _failure('opened', snap.error);
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        if (data is LibraryPage) {
          if (data.items.isEmpty) {
            return _Message(
              icon: Icons.music_off_outlined,
              text: s.libraryEmpty,
            );
          }
          return _rows(
            context,
            layout,
            pad,
            data.items,
            header: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                opened.item.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          );
        }
        final detail = data as LibraryDetail;
        if (detail.item.kind == LibraryKind.artist ||
            detail.item.kind == LibraryKind.genre) {
          return _artist(context, layout, pad, detail);
        }
        // Beside the tracks only where both columns have room: a tablet
        // in portrait stacks them as a phone does.
        return LayoutBuilder(
          builder: (context, box) => _album(
            context,
            box.maxWidth < 640 ? LibraryLayout.narrow : layout,
            pad,
            detail,
          ),
        );
      },
    );
  }

  /// The facts under an album's title: kind, year, track count, length.
  String _meta(UiStrings s, LibraryDetail detail) {
    final total = detail.tracks.fold<int>(0, (t, i) => t + (i.durationMs ?? 0));
    final minutes = (total / 60000).round();
    final count = detail.tracks.length;
    return [
      ?_kindName(s, detail.item.kind),
      if (detail.year != null) '${detail.year}',
      if (count > 0)
        count == 1 ? s.libraryOneTrack : s.libraryTrackCount('$count'),
      if (minutes > 0)
        minutes >= 60
            ? s.libraryHoursMinutes('${minutes ~/ 60}', '${minutes % 60}')
            : s.libraryMinutes('$minutes'),
    ].join(' · ');
  }

  Widget _album(
    BuildContext context,
    LibraryLayout layout,
    EdgeInsets pad,
    LibraryDetail detail,
  ) {
    final s = l10n(context);
    final theme = Theme.of(context);
    final item = detail.item;
    final short = layout == LibraryLayout.short;
    final artSize = switch (layout) {
      LibraryLayout.roomy => 300.0,
      LibraryLayout.short => 132.0,
      LibraryLayout.narrow => 232.0,
    };
    final playable = detail.tracks.isNotEmpty || item.playable;
    final header = Column(
      crossAxisAlignment: layout == LibraryLayout.narrow
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: [
        Center(
          child: LibraryArt(
            container: c,
            item: item,
            size: artSize,
            radius: 16,
          ),
        ),
        SizedBox(height: short ? 12 : 20),
        Text(
          item.title,
          maxLines: short ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: switch (layout) {
              LibraryLayout.roomy => 30,
              LibraryLayout.short => 19,
              LibraryLayout.narrow => 24,
            },
            height: 1.15,
          ),
        ),
        if (item.subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: short ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            _meta(s, detail),
            style: TextStyle(
              fontSize: 13.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(height: short ? 10 : 18),
        Row(
          children: [
            if (playable) ...[
              if (layout == LibraryLayout.roomy)
                FilledButton.icon(
                  onPressed: () => _play(item, PlayMode.replace),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(s.libraryPlay),
                )
              else
                IconButton.filled(
                  iconSize: short ? 26 : 30,
                  tooltip: s.libraryPlay,
                  onPressed: () => _play(item, PlayMode.replace),
                  icon: const Icon(Icons.play_arrow_rounded),
                ),
              const SizedBox(width: 6),
            ],
            if (layout != LibraryLayout.roomy) const Spacer(),
            Builder(
              builder: (anchor) => IconButton.outlined(
                tooltip: s.libraryMore,
                onPressed: () => _menu(anchor, item),
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ),
          ],
        ),
      ],
    );
    final tracks = detail.tracks;
    final numbered = item.kind == LibraryKind.album;
    if (layout == LibraryLayout.narrow) {
      return _rows(
        context,
        layout,
        pad,
        tracks,
        within: item,
        numbered: numbered,
        header: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: header,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(left: pad.left),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: short ? 220 : 300,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: pad.top, bottom: pad.bottom),
              child: header,
            ),
          ),
          SizedBox(width: short ? 20 : 36),
          Expanded(
            child: tracks.isEmpty
                ? _Message(icon: Icons.music_off_outlined, text: s.libraryEmpty)
                : _rows(
                    context,
                    layout,
                    pad.copyWith(left: 0),
                    tracks,
                    within: item,
                    numbered: numbered,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _artist(
    BuildContext context,
    LibraryLayout layout,
    EdgeInsets pad,
    LibraryDetail detail,
  ) {
    final s = l10n(context);
    final theme = Theme.of(context);
    final item = detail.item;
    final artSize = switch (layout) {
      LibraryLayout.roomy => 168.0,
      LibraryLayout.short => 96.0,
      LibraryLayout.narrow => 112.0,
    };
    final buttons = Row(
      children: [
        FilledButton.icon(
          onPressed: () => _play(item, PlayMode.replace),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(s.libraryPlay),
        ),
        if ((_source?.hasRadioMode ?? false) &&
            item.kind == LibraryKind.artist) ...[
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () => _play(item, PlayMode.radio),
            icon: const Icon(Icons.radio_outlined),
            label: Text(s.libraryStartRadio),
          ),
        ],
      ],
    );
    return EdgeFade(
      child: ListView(
        padding: pad,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Row(
            children: [
              LibraryArt(container: c, item: item, size: artSize),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_kindName(s, item.kind) ?? '').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .8,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: switch (layout) {
                          LibraryLayout.roomy => 42,
                          LibraryLayout.short => 26,
                          LibraryLayout.narrow => 28,
                        },
                        height: 1.1,
                      ),
                    ),
                    if (layout != LibraryLayout.narrow) ...[
                      const SizedBox(height: 16),
                      buttons,
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (layout == LibraryLayout.narrow) ...[
            const SizedBox(height: 16),
            buttons,
          ],
          if (detail.tracks.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              item.kind == LibraryKind.artist
                  ? s.libraryTopTracks
                  : s.libraryTracks,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 21),
            ),
            const SizedBox(height: 6),
            for (final t in detail.tracks)
              _Row(
                container: c,
                item: t,
                dense: layout == LibraryLayout.short,
                onTap: () => _tap(t),
                onMore: (anchor) => _menu(anchor, t),
              ),
          ],
          for (final shelf in detail.shelves) ...[
            const SizedBox(height: 24),
            _shelf(context, layout, _shelfTitle(s, shelf), shelf.items),
          ],
        ],
      ),
    );
  }
}

// ── Widgets ─────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Selected the way the settings rail selects: the highest surface,
  /// no tint.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Ks.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
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
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.surfaceContainerHighest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The source and speaker pickers: one surface for both.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.height,
    required this.icon,
    required this.onTap,
    this.label,
    this.semanticLabel,
  });

  final double height;
  final Widget icon;
  final String? label;
  final String? semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerHighest,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  if (label != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
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

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A list that loads page after page as it nears its end.
class _PagedList extends StatefulWidget {
  const _PagedList({
    super.key,
    required this.load,
    required this.builder,
    required this.empty,
  });

  final Future<LibraryPage> Function(int offset) load;
  final Widget Function(List<LibraryItem> items, bool more) builder;
  final String empty;

  @override
  State<_PagedList> createState() => _PagedListState();
}

class _PagedListState extends State<_PagedList> {
  final _items = <LibraryItem>[];
  bool _more = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_next());
  }

  Future<void> _next() async {
    if (_loading || !_more) return;
    setState(() => _loading = true);
    try {
      final page = await widget.load(_items.length);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _more = page.more && page.items.isNotEmpty;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    if (_items.isEmpty) {
      if (_error != null) {
        return _Message(
          icon: Icons.cloud_off_outlined,
          text: '${s.libraryLoadFailed}\n$_error',
          action: s.commonRetry,
          onAction: () {
            _more = true;
            unawaited(_next());
          },
        );
      }
      if (_loading || _more) {
        return const Center(child: CircularProgressIndicator());
      }
      return _Message(icon: Icons.music_off_outlined, text: widget.empty);
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 600) unawaited(_next());
        return false;
      },
      child: widget.builder(_items, _more),
    );
  }
}

class _QuickTiles extends StatelessWidget {
  const _QuickTiles({
    required this.container,
    required this.items,
    required this.columns,
    required this.height,
    required this.onTap,
  });

  final AppContainer container;
  final List<LibraryItem> items;
  final int columns;
  final double height;
  final Future<void> Function(LibraryItem item, {LibraryItem? within}) onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // Two to a row where three would break their names, such as a tablet
    // in portrait.
    builder: (context, box) =>
        _tiles(context, box.maxWidth < 640 ? 2 : columns),
  );

  Widget _tiles(BuildContext context, int columns) {
    final scheme = Theme.of(context).colorScheme;
    final rows = (items.length / columns).ceil();
    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Padding(
            padding: EdgeInsets.only(top: r == 0 ? 0 : 10),
            child: Row(
              children: [
                for (var col = 0; col < columns; col++) ...[
                  if (col > 0) const SizedBox(width: 10),
                  Expanded(
                    child: r * columns + col >= items.length
                        ? const SizedBox.shrink()
                        : Material(
                            color: scheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => onTap(items[r * columns + col]),
                              child: SizedBox(
                                height: height,
                                child: Row(
                                  children: [
                                    LibraryArt(
                                      container: container,
                                      item: items[r * columns + col],
                                      size: height,
                                      radius: 0,
                                      square: true,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        items[r * columns + col].title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.container,
    required this.item,
    required this.onTap,
    required this.onLongPress,
    this.compact = false,
    this.kindLabel,
  });

  final AppContainer container;
  final LibraryItem item;
  final bool compact;

  /// What the entry is, before its subtitle, on a shelf that mixes kinds.
  final String? kindLabel;
  final VoidCallback onTap;
  final void Function(BuildContext anchor) onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      onLongPress: () => onLongPress(context),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, box) => LibraryArt(
              container: container,
              item: item,
              size: box.maxWidth,
              radius: compact ? 10 : 12,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 13.5 : 14.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if ([
                ?kindLabel,
                if (item.subtitle.isNotEmpty) item.subtitle,
              ].join(' · ')
              case final sub when sub.isNotEmpty)
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 12.5 : 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// A genre on Discover: its name over a tinted tile, its picture on the
/// right, as Music Assistant's Browse by genre draws it.
class _GenreTile extends StatelessWidget {
  const _GenreTile({
    required this.container,
    required this.item,
    required this.onTap,
    this.compact = false,
  });

  final AppContainer container;
  final LibraryItem item;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = compact ? 64.0 : 84.0;
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(compact ? 12 : 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              // Large and cut by the tile's corner, as a backdrop.
              Positioned(
                right: -height * 0.12,
                bottom: -height * 0.18,
                child: Icon(
                  genreIconFor(item),
                  size: height * 1.05,
                  color: scheme.onSecondaryContainer.withValues(alpha: .22),
                ),
              ),
              Positioned(
                left: 16,
                right: height,
                bottom: compact ? 10 : 14,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final style = TextStyle(
                      fontSize: compact ? 15 : 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSecondaryContainer,
                    );
                    return Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: style.copyWith(
                        fontSize: _wordFit(context, style, box.maxWidth),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The font size at which the name's widest word fits on one line of
  /// [width], so a long translated name such as Elektronisch shrinks
  /// instead of breaking in the middle of the word. Never below two thirds
  /// of the tile's size.
  double _wordFit(BuildContext context, TextStyle style, double width) {
    final size = style.fontSize!;
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    );
    var widest = 0.0;
    for (final word in item.title.split(RegExp(r'\s+'))) {
      painter
        ..text = TextSpan(
          text: word,
          style: DefaultTextStyle.of(context).style.merge(style),
        )
        ..layout();
      widest = math.max(widest, painter.width);
    }
    painter.dispose();
    if (widest <= width) return size;
    // A little under the exact ratio: widths do not scale quite linearly.
    return math.max(size * 2 / 3, size * width / widest * 0.97);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.container,
    required this.item,
    required this.onTap,
    this.onMore,
    this.number,
    this.kindLabel,
    this.dense = false,
  });

  final AppContainer container;
  final LibraryItem item;
  final VoidCallback onTap;
  final void Function(BuildContext anchor)? onMore;
  final int? number;
  final String? kindLabel;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    final sub = [
      ?kindLabel,
      if (item.subtitle.isNotEmpty) item.subtitle,
    ].join(' · ');
    final length = formatTrackLength(item.durationMs);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Ks.radiusRow),
      // Taller with Text scale, so the rows keep their breathing room,
      // and taller still where the text needs it.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: math.max(
            dense ? 52 : 60,
            MediaQuery.textScalerOf(context).scale(dense ? 52 : 60),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 6),
            if (number != null)
              SizedBox(
                width: 28,
                // The tap answered at once: a spinner in place of the
                // number while the track starts.
                child: ValueListenableBuilder<LibraryItem?>(
                  valueListenable: container.musicLibrary.starting,
                  builder: (context, starting, _) => starting?.id == item.id
                      ? const Center(
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Text(
                          '$number',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                ),
              )
            else
              LibraryArt(
                container: container,
                item: item,
                size: dense ? 40 : 46,
                radius: 8,
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: dense ? 14.5 : 15.5),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dense ? 12.5 : 13.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (length.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  length,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            if (item.expandable && !item.playable && onMore == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              )
            else if (onMore != null)
              Builder(
                builder: (anchor) => IconButton(
                  tooltip: s.libraryMore,
                  icon: const Icon(Icons.more_vert_rounded),
                  color: scheme.onSurfaceVariant,
                  onPressed: () => onMore!(anchor),
                ),
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

/// A cover, fetched through the library (which knows each source's
/// certificates and tokens), with the kind's icon until it lands or when
/// there is none.
/// A genre's icon, picked from words in its name, in the app's own icon
/// set. A genre no word matches gets a note.
IconData genreIcon(String name) {
  final n = name.toLowerCase();
  bool any(List<String> words) => words.any(n.contains);
  return switch (n) {
    _ when any(['hip hop', 'hip-hop', 'hiphop', 'rap', 'r&b', 'rnb', 'trap']) =>
      Icons.mic_rounded,
    _ when any(['classical', 'composer', 'orchestra', 'opera', 'piano']) =>
      Icons.piano_rounded,
    _ when any(['jazz', 'blues', 'swing', 'soul', 'funk', 'lounge']) =>
      Icons.nightlife_rounded,
    _ when any(['dance', 'disco', 'edm', 'house', 'club']) =>
      Icons.celebration_rounded,
    _ when any(['electro', 'techno', 'trance', 'dubstep', 'drum', 'synth']) =>
      Icons.graphic_eq_rounded,
    _ when any(['rock', 'metal', 'punk', 'grunge', 'alternative', 'indie']) =>
      Icons.bolt_rounded,
    _ when any(['ambient', 'chill', 'lo-fi', 'lofi', 'sleep', 'relax']) =>
      Icons.nights_stay_rounded,
    _ when any(['folk', 'singer']) => Icons.mic_external_on_rounded,
    _ when any(['acoustic', 'unplugged']) => Icons.waves_rounded,
    _ when any(['reggae', 'latin', 'salsa', 'samba', 'bossa', 'tropical']) =>
      Icons.wb_sunny_rounded,
    _ when any(['world', 'afro', 'celtic']) => Icons.public_rounded,
    _ when any(['soundtrack', 'score', 'film', 'movie']) => Icons.movie_rounded,
    _ when any(['game']) => Icons.sports_esports_rounded,
    _ when any(['gospel', 'christian', 'worship']) => Icons.church_rounded,
    _ when any(['kids', 'children']) => Icons.child_care_rounded,
    _ when any(['christmas', 'holiday']) => Icons.ac_unit_rounded,
    _ when any(['spoken', 'comedy', 'podcast', 'audiobook']) =>
      Icons.record_voice_over_rounded,
    _ when any(['love', 'romance']) => Icons.favorite_rounded,
    _ when any(['pop']) => Icons.auto_awesome_rounded,
    _ => Icons.music_note_rounded,
  };
}

/// A genre's icon from its English name. Music Assistant translates a
/// genre's name into the app's language but keeps its sort name in English,
/// and [genreIcon] matches English words.
IconData genreIconFor(LibraryItem item) => switch (item.raw) {
  {'sort_name': final String english} when english.isNotEmpty => genreIcon(
    english,
  ),
  _ => genreIcon(item.title),
};

/// Music Assistant's provider logos are SVG.
bool _isSvg(Uint8List bytes) {
  final head = String.fromCharCodes(
    bytes.take(256).where((b) => b < 128),
  ).trimLeft();
  return head.startsWith('<svg') ||
      (head.startsWith('<?xml') && head.contains('<svg'));
}

class LibraryArt extends StatefulWidget {
  const LibraryArt({
    super.key,
    required this.container,
    required this.item,
    required this.size,
    this.radius = 12,
    this.square = false,
    this.showStarting = true,
  });

  final AppContainer container;
  final LibraryItem item;
  final double size;
  final double radius;

  /// A spinner over the cover while a play of this item starts. The
  /// player bar's own cover leaves it out: the bar says so itself.
  final bool showStarting;

  /// Square even for an artist, filling a tile's edge.
  final bool square;

  static final lane = FetchLane(width: 6);

  @override
  State<LibraryArt> createState() => _LibraryArtState();
}

class _LibraryArtState extends State<LibraryArt> {
  Uint8List? _bytes;
  String _url = '';
  FetchTicket? _ticket;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetch();
  }

  @override
  void didUpdateWidget(LibraryArt old) {
    super.didUpdateWidget(old);
    _fetch();
  }

  @override
  void dispose() {
    _ticket?.cancel();
    super.dispose();
  }

  void _fetch() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // A genre is drawn by the app, not from the server's picture.
    final url = widget.item.kind == LibraryKind.genre
        ? ''
        : (dark ? widget.item.artDark : null) ?? widget.item.art ?? '';
    if (url == _url) return;
    _url = url;
    _ticket?.cancel();
    _bytes = url.isEmpty ? null : widget.container.musicLibrary.cachedArt(url);
    if (url.isEmpty || _bytes != null) return;
    _ticket = LibraryArt.lane.schedule(() async {
      final bytes = await widget.container.musicLibrary.loadArt(url);
      if (!mounted || url != _url) return;
      setState(() => _bytes = bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final round =
        widget.item.round &&
        !widget.square &&
        !widget.container.settings.get(defs.librarySquareArtwork);
    final logo =
        widget.item.kind == LibraryKind.folder ||
        widget.item.kind == LibraryKind.other;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final bytes = _bytes;
    final radius = round
        ? BorderRadius.circular(widget.size / 2)
        : BorderRadius.circular(widget.radius);
    final genre = widget.item.kind == LibraryKind.genre;
    final art = ClipRRect(
      borderRadius: radius,
      child: SizedBox.square(
        dimension: widget.size,
        child: genre
            ? ColoredBox(
                color: scheme.secondaryContainer,
                child: Icon(
                  genreIconFor(widget.item),
                  size: widget.size * 0.46,
                  color: scheme.onSecondaryContainer,
                ),
              )
            : bytes == null
            ? ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  _icon(widget.item.kind),
                  size: math.max(18, widget.size * 0.36),
                  color: scheme.onSurfaceVariant,
                ),
              )
            : _isSvg(bytes)
            ? ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Padding(
                  padding: EdgeInsets.all(widget.size * 0.18),
                  child: SvgPicture.memory(bytes),
                ),
              )
            : Image.memory(
                bytes,
                // A folder's picture is usually a logo, which a crop
                // would cut.
                fit: logo ? BoxFit.contain : BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: (widget.size * dpr).round().clamp(32, 1024),
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: scheme.surfaceContainerHighest),
              ),
      ),
    );
    if (!widget.showStarting || widget.item.id.isEmpty) return art;
    // The tap answered at once: a spinner over the cover while it starts.
    return ValueListenableBuilder<LibraryItem?>(
      valueListenable: widget.container.musicLibrary.starting,
      child: art,
      builder: (context, starting, art) => starting?.id != widget.item.id
          ? art!
          : Stack(
              alignment: Alignment.center,
              children: [
                art!,
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: radius,
                    child: const ColoredBox(color: Colors.black45),
                  ),
                ),
                SizedBox.square(
                  dimension: math.min(36, widget.size * 0.4),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
    );
  }

  static IconData _icon(LibraryKind kind) => switch (kind) {
    LibraryKind.artist => Icons.person_outline_rounded,
    LibraryKind.album => Icons.album_outlined,
    LibraryKind.track => Icons.music_note_outlined,
    LibraryKind.playlist => Icons.queue_music_rounded,
    LibraryKind.radio => Icons.radio_outlined,
    LibraryKind.podcast || LibraryKind.episode => Icons.podcasts_rounded,
    LibraryKind.audiobook => Icons.menu_book_outlined,
    LibraryKind.genre => Icons.category_outlined,
    LibraryKind.folder => Icons.folder_outlined,
    LibraryKind.other => Icons.library_music_outlined,
  };
}

/// What plays now, on the followed player, laid out the way Music
/// Assistant's own player bar is: the track and its heart on the left,
/// shuffle, the transport and repeat over the seek bar in the middle,
/// the queue and the volume on the right. Each control shows only
/// where the player has it, as on Now Playing. Tap the track for Now
/// Playing.
class _MiniPlayer extends StatefulWidget {
  const _MiniPlayer({
    required this.container,
    required this.layout,
    required this.onQueue,
    required this.onSpeakers,
    this.queueOpen = false,
  });

  final AppContainer container;
  final LibraryLayout layout;
  final Future<void> Function() onQueue;
  final bool queueOpen;
  final Future<void> Function() onSpeakers;

  @override
  State<_MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<_MiniPlayer> {
  AppContainer get c => widget.container;

  /// Moves the elapsed time on while a track plays.
  Timer? _tick;

  /// What a press just asked for, shown until the player reports it.
  bool? _shuffle;
  String? _repeat;
  double? _seekDrag;
  double? _volumeDrag;
  bool? _wantPlaying;

  /// The track a skip left, until the player reports another.
  String? _skippedFrom;

  /// Lets go of a press the player never reported.
  Timer? _pending;

  @override
  void initState() {
    super.initState();
    c.sendspin.nowPlaying.addListener(_changed);
    c.sendspin.favorite.addListener(_changed);
    c.sendspin.queueItems.addListener(_changed);
    c.musicLibrary.starting.addListener(_changed);
    _changed();
    _readQueue();
  }

  /// With nothing playing, the player's queue may still hold a track to
  /// resume: read it so the bar can show it.
  void _readQueue() {
    if (c.sendspin.nowPlaying.value == null && c.sendspin.queueAvailable) {
      unawaited(c.sendspin.refreshQueue());
    }
  }

  /// The queue's current track while nothing plays, and its neighbors.
  ({Map<String, Object?>? current, String? before, String? after}) _idle() {
    final rows = c.sendspin.queueItems.value;
    final i = rows.indexWhere((r) => r['current'] == true);
    if (i < 0) return (current: null, before: null, after: null);
    return (
      current: rows[i],
      before: i > 0 ? '${rows[i - 1]['id']}' : null,
      after: i + 1 < rows.length ? '${rows[i + 1]['id']}' : null,
    );
  }

  @override
  void dispose() {
    c.sendspin.nowPlaying.removeListener(_changed);
    c.sendspin.favorite.removeListener(_changed);
    c.sendspin.queueItems.removeListener(_changed);
    c.musicLibrary.starting.removeListener(_changed);
    _tick?.cancel();
    _pending?.cancel();
    super.dispose();
  }

  static String _key(Map<String, Object?>? now) =>
      '${now?['title'] ?? ''}|${now?['artist'] ?? ''}';

  void _await() {
    _pending?.cancel();
    _pending = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      setState(() {
        _wantPlaying = null;
        _skippedFrom = null;
      });
    });
  }

  /// Play or pause shows at once, the player's answer after.
  Future<void> _toggle(Future<bool> Function() run, bool playing) async {
    setState(() => _wantPlaying = !playing);
    _await();
    if (!await run() && mounted) setState(() => _wantPlaying = null);
  }

  /// A skip shows the ring until the player moves to another track.
  Future<void> _skip(Future<Object?> Function() run) async {
    setState(() => _skippedFrom = _key(c.sendspin.nowPlaying.value));
    _await();
    if (await run() == false && mounted) setState(() => _skippedFrom = null);
  }

  bool _hadTrack = false;

  void _changed() {
    final now = c.sendspin.nowPlaying.value;
    // Playback just stopped: the queue says what would resume.
    if (_hadTrack && now == null) _readQueue();
    _hadTrack = now != null;
    if (_shuffle != null && now?['shuffle'] == _shuffle) _shuffle = null;
    if (_wantPlaying != null && (now?['playing'] == true) == _wantPlaying) {
      _wantPlaying = null;
    }
    if (_skippedFrom != null && _key(now) != _skippedFrom) _skippedFrom = null;
    if (_repeat != null && now?['repeat'] == _repeat) _repeat = null;
    final playing = now?['playing'] == true;
    if (playing && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!playing) {
      _tick?.cancel();
      _tick = null;
    }
    if (mounted) setState(() {});
  }

  /// Where the track is now: the last report moved on by the time since,
  /// while it plays.
  double _position(Map<String, Object?> now, double duration) {
    final reported = (now['positionMs'] as num?)?.toDouble() ?? 0;
    final at = (now['receivedAt'] as num?)?.toInt();
    final elapsed = now['playing'] == true && at != null
        ? DateTime.now().millisecondsSinceEpoch - at
        : 0;
    final position = reported + elapsed;
    return duration > 0 ? position.clamp(0, duration).toDouble() : position;
  }

  Future<void> _toggleShuffle(bool on) async {
    setState(() => _shuffle = on);
    if (!await c.sendspin.setShuffle(on) && mounted) {
      setState(() => _shuffle = null);
    }
  }

  Future<void> _cycleRepeat(String current) async {
    final next = switch (current) {
      'off' => 'all',
      'all' => 'one',
      _ => 'off',
    };
    setState(() => _repeat = next);
    if (!await c.sendspin.setRepeat(next) && mounted) {
      setState(() => _repeat = null);
    }
  }

  /// On a layer of its own: the elapsed time moves every second, and the
  /// page around it has nothing to redraw for it.
  @override
  Widget build(BuildContext context) => RepaintBoundary(child: _bar(context));

  Widget _bar(BuildContext context) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    final layout = widget.layout;
    final narrow = layout == LibraryLayout.narrow;
    final roomy = layout == LibraryLayout.roomy;
    final now = c.sendspin.nowPlaying.value;
    // Nothing playing, a queue to resume: its track stands in, and play,
    // previous and next move through the queue.
    final idle = now == null && c.sendspin.queueAvailable
        ? _idle()
        : (current: null, before: null, after: null);
    final queued = idle.current;
    // A play from the library shows what it starts at once, the player's
    // own report after.
    final starting = c.musicLibrary.starting.value;
    final title = starting != null
        ? starting.title
        : '${now?['title'] ?? queued?['title'] ?? ''}';
    final artist = starting != null
        ? s.commonLoading
        : '${now?['artist'] ?? queued?['artist'] ?? ''}';
    final playing =
        _wantPlaying ?? (starting != null || now?['playing'] == true);
    final art = starting != null
        ? starting.art ?? ''
        : '${now?['artworkUrl'] ?? queued?['artworkUrl'] ?? ''}';
    final busy =
        starting != null || _wantPlaying != null || _skippedFrom != null;
    VoidCallback? jump(String? id) =>
        id == null ? null : () => _skip(() => c.sendspin.playQueueItem(id));
    final canOpen = now != null && c.settings.get(defs.sendspinFullscreen);
    final duration = (now?['durationMs'] as num?)?.toDouble() ?? 0;
    final position = now == null ? 0.0 : _position(now, duration);
    final supported =
        (now?['supportedCommands'] as List?)?.map((e) => '$e').toList() ??
        const <String>[];
    bool has(String cmd) => supported.isEmpty || supported.contains(cmd);
    final on = scheme.primary;
    final off = scheme.onSurfaceVariant;

    Widget button(
      IconData icon,
      String tooltip,
      VoidCallback? onPressed, {
      Color? color,
      double size = 24,
    }) => IconButton(
      tooltip: tooltip,
      iconSize: size,
      color: color ?? scheme.onSurface,
      icon: Icon(icon),
      onPressed: onPressed,
    );

    final track = InkWell(
      onTap: canOpen ? c.musicLibrary.showNowPlaying : null,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        // As wide as the title, so the heart follows it.
        mainAxisSize: MainAxisSize.min,
        children: [
          LibraryArt(
            container: c,
            item: LibraryItem(
              id: art,
              kind: LibraryKind.track,
              title: title,
              art: art.isEmpty ? null : art,
            ),
            showStarting: false,
            size: roomy ? 56 : 44,
            radius: 8,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? s.libraryNothingPlaying : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: roomy ? 15.5 : 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (artist.isNotEmpty)
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: off),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    final playButton = Stack(
      alignment: Alignment.center,
      // The ring spills past the button, which alone sizes the stack, so
      // nothing around it moves when it shows.
      clipBehavior: Clip.none,
      children: [
        IconButton.filled(
          tooltip: playing ? s.mediaPause : s.mediaPlay,
          iconSize: roomy ? 30 : 26,
          icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
          onPressed: now != null
              ? () => _toggle(
                  () => c.sendspin.control('toggle'),
                  now['playing'] == true,
                )
              : jump(queued == null ? null : '${queued['id']}'),
        ),
        // A ring around it until the player answers a play, a pause or
        // a skip.
        if (busy)
          Positioned.fill(
            child: IgnorePointer(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: SizedBox.square(
                  dimension: roomy ? 54 : 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (narrow) {
      final progress = duration > 0 ? position / duration : 0.0;
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
        child: Material(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                child: Row(
                  children: [
                    Expanded(child: track),
                    if (now != null || queued != null) ...[
                      playButton,
                      button(
                        Icons.skip_next_rounded,
                        s.mediaNextTrack,
                        now != null
                            ? () => _skip(() => c.sendspin.control('next'))
                            : jump(idle.after),
                      ),
                    ],
                    // A queue can hold tracks with nothing playing.
                    if (c.sendspin.queueAvailable)
                      button(
                        Icons.queue_music_rounded,
                        widget.queueOpen ? s.mediaHideQueue : s.mediaShowQueue,
                        widget.onQueue,
                        color: widget.queueOpen ? on : off,
                        size: 22,
                      ),
                  ],
                ),
              ),
              if (progress > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final shuffleOn = _shuffle ?? (now?['shuffle'] == true);
    final repeatMode = _repeat ?? '${now?['repeat'] ?? 'off'}';
    final favorite = c.sendspin.favorite.value;
    final transport = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (now != null && has('shuffle'))
          button(
            Icons.shuffle_rounded,
            shuffleOn ? s.mediaShuffleOff : s.mediaShuffleOn,
            () => _toggleShuffle(!shuffleOn),
            color: shuffleOn ? on : off,
            size: 22,
          ),
        button(
          Icons.skip_previous_rounded,
          s.mediaPreviousTrack,
          now != null
              ? () => _skip(() => c.sendspin.control('previous'))
              : jump(idle.before),
          size: 28,
        ),
        const SizedBox(width: 4),
        playButton,
        const SizedBox(width: 4),
        button(
          Icons.skip_next_rounded,
          s.mediaNextTrack,
          now != null
              ? () => _skip(() => c.sendspin.control('next'))
              : jump(idle.after),
          size: 28,
        ),
        if (now != null && (has('repeat') || has('repeat_all')))
          button(
            repeatMode == 'one'
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            switch (repeatMode) {
              'off' => s.mediaRepeatAll,
              'all' => s.mediaRepeatOne,
              _ => s.mediaRepeatOff,
            },
            () => _cycleRepeat(repeatMode),
            color: repeatMode == 'off' ? off : on,
            size: 22,
          ),
      ],
    );

    final timeStyle = TextStyle(
      fontSize: 12.5,
      color: off,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // Room for "1:02:05" beside the seek bar, at the bar's text size.
    final timeWidth = MediaQuery.textScalerOf(context).scale(44);
    final seekable = now != null && duration > 0 && has('seek');
    final shown = _seekDrag ?? position;
    // Nothing to seek in (nothing playing, a live stream): no bar, and
    // no room kept for one, so the transport sits in the middle.
    final seekBar = duration > 0
        ? Row(
            children: [
              SizedBox(
                width: timeWidth,
                child: Text(
                  formatTrackLength(shown.round()).ifEmpty('0:00'),
                  textAlign: TextAlign.right,
                  style: timeStyle,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: shown.clamp(0, duration),
                    max: duration,
                    onChanged: seekable
                        ? (v) => setState(() => _seekDrag = v)
                        : null,
                    onChangeEnd: seekable
                        ? (v) async {
                            await c.sendspin.seek(v.round());
                            if (mounted) setState(() => _seekDrag = null);
                          }
                        : null,
                  ),
                ),
              ),
              SizedBox(
                width: timeWidth,
                child: Text(
                  formatTrackLength(duration.round()),
                  style: timeStyle,
                ),
              ),
            ],
          )
        : null;

    final heart = now != null && c.sendspin.favoriteAvailable
        ? button(
            favorite == true
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            favorite == true ? s.mediaFavoriteRemove : s.mediaFavoriteAdd,
            favorite == null ? null : c.sendspin.toggleFavorite,
            color: favorite == true ? on : off,
            size: 22,
          )
        : null;
    final level =
        _volumeDrag ?? c.sendspin.volumeLevel?.toDouble().clamp(0.0, 100.0);
    // The bar spans the screen. The middle takes a share of it; each side
    // gets half of what is left, and the volume slider shows only where
    // the right side has room for it next to its buttons.
    final width = MediaQuery.sizeOf(context).width;
    final middle = (width * 0.4).clamp(300.0, 520.0);
    final slider = roomy && (width - middle) / 2 >= 320;
    final muted = c.sendspin.muted;
    final extras = <Widget>[
      if (c.sendspin.queueAvailable)
        button(
          Icons.queue_music_rounded,
          widget.queueOpen ? s.mediaHideQueue : s.mediaShowQueue,
          widget.onQueue,
          color: widget.queueOpen ? on : off,
          size: 22,
        ),
      if (now != null && c.sendspin.volumeAvailable && level != null) ...[
        button(
          muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          muted ? s.mediaUnmute : s.mediaMute,
          // Without room for the slider (a short panel, a tablet in
          // portrait) the Speakers sheet carries it.
          slider ? () => c.sendspin.toggleMute() : widget.onSpeakers,
          color: off,
          size: 22,
        ),
        if (slider)
          SizedBox(
            width: 112,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: level,
                max: 100,
                semanticFormatterCallback: (v) =>
                    '${s.mediaVolume}: ${v.round()}%',
                onChanged: (v) => setState(() => _volumeDrag = v),
                onChangeEnd: (v) async {
                  await c.sendspin.setVolume(v.round());
                  if (mounted) setState(() => _volumeDrag = null);
                },
              ),
            ),
          ),
      ],
      if (canOpen)
        button(
          Icons.open_in_full_rounded,
          s.libraryOpenNowPlaying,
          c.musicLibrary.showNowPlaying,
          color: off,
          size: 20,
        ),
    ];

    final progress = duration > 0 ? position / duration : 0.0;
    return Material(
      color: scheme.surfaceContainer,
      child: Stack(
        children: [
          Container(
            height: roomy ? 96 : 68,
            padding: EdgeInsets.fromLTRB(roomy ? 20 : 12, 0, roomy ? 16 : 8, 0),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(child: track),
                      ?heart,
                    ],
                  ),
                ),
                if (roomy)
                  SizedBox(
                    width: middle,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        transport,
                        if (seekBar != null)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: SizedBox(height: 28, child: seekBar),
                          ),
                      ],
                    ),
                  )
                else
                  transport,
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: extras,
                  ),
                ),
              ],
            ),
          ),
          // A short panel shows the time as a line along the top.
          if (!roomy && progress > 0)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

/// A source's own mark: the Music Assistant and Home Assistant logos the
/// app already carries, tinted like an icon, and a speaker for Sonos.
class _SourceMark extends StatelessWidget {
  const _SourceMark({
    required this.source,
    required this.size,
    required this.color,
  });

  final String source;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final asset = switch (source) {
      'ma' => 'assets/svg/music-assistant.svg',
      'ha' => 'assets/svg/home-assistant.svg',
      _ => null,
    };
    if (asset == null) {
      return Icon(Icons.speaker_outlined, size: size, color: color);
    }
    return SizedBox.square(
      dimension: size,
      child: SvgPicture.asset(
        asset,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
