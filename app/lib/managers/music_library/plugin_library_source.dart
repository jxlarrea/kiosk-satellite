import '../plugins/plugin_players.dart';
import 'library_model.dart';

/// A plugin player's library (SDK `player`, PlayerLibrary): its own tree
/// to browse, its shelves and search when it has them. It plays only on
/// the plugin's own player, so its key is that player's pick and a play
/// needs that pick.
class PluginLibrarySource extends LibrarySource {
  PluginLibrarySource(
    this.pick, {
    Future<Object?> Function(String op, Map<String, Object?> args)? request,
  }) : _request =
           request ?? ((op, args) => PluginPlayers.request(pick, op, args));

  final String pick;
  final Future<Object?> Function(String op, Map<String, Object?> args) _request;

  PluginPlayerInfo? get _info => PluginPlayers.published.value[pick];

  @override
  String get key => pick;

  @override
  bool get hasDiscover => _info?.discover ?? false;

  @override
  bool get hasSearch => _info?.search ?? false;

  @override
  bool get hasBrowse => true;

  @override
  bool needsSpeaker(String pick) => pick != this.pick;

  Future<Object?> _call(
    String op, [
    Map<String, Object?> args = const {},
  ]) async {
    try {
      return await _request(op, args);
    } on PluginPlayerError catch (e) {
      throw LibraryError(e.message);
    }
  }

  @override
  Future<List<LibraryShelf>> discover() async =>
      shelvesFrom(await _call('discover'));

  @override
  Future<List<LibraryShelf>> search(String query) async =>
      shelvesFrom(await _call('search', {'query': query}));

  /// The most a folder lists: its pages one after another, up to here.
  static const browseLimit = 1000;

  /// A folder's children, every page the plugin has up to [browseLimit].
  @override
  Future<LibraryPage> browse(LibraryItem? folder) async {
    final items = <LibraryItem>[];
    var more = true;
    while (more && items.length < browseLimit) {
      final page = pageFrom(
        await _call('browse', {'item': folder?.id, 'offset': items.length}),
      );
      items.addAll(page.items);
      more = page.more && page.items.isNotEmpty;
    }
    return LibraryPage(items: items.take(browseLimit).toList());
  }

  @override
  Future<LibraryDetail> open(LibraryItem item) async {
    final raw = await _call('open', {'item': item.id});
    if (raw is! Map) return LibraryDetail(item: item);
    final own = itemFrom(raw['item']);
    return LibraryDetail(item: own ?? item, tracks: itemsFrom(raw['items']));
  }

  @override
  Future<String?> play(
    LibraryItem item,
    PlayMode mode, {
    required String pick,
    LibraryItem? within,
  }) async {
    if (pick != this.pick) return 'no_speaker';
    try {
      await _request('play', {
        'item': item.id,
        'mode': switch (mode) {
          PlayMode.now => 'now',
          PlayMode.next => 'next',
          PlayMode.add => 'add',
          // A radio needs a service that finds similar music, which a
          // plugin does not offer here: the item plays on its own.
          PlayMode.replace || PlayMode.radio => 'replace',
        },
        if (within != null) 'within': within.id,
      });
      return null;
    } on PluginPlayerError catch (e) {
      return e.message;
    }
  }

  static LibraryKind _kind(Object? raw) => switch (raw) {
    'artist' => LibraryKind.artist,
    'album' => LibraryKind.album,
    'track' => LibraryKind.track,
    'playlist' => LibraryKind.playlist,
    'radio' => LibraryKind.radio,
    'podcast' => LibraryKind.podcast,
    'episode' => LibraryKind.episode,
    'audiobook' => LibraryKind.audiobook,
    'genre' => LibraryKind.genre,
    'folder' => LibraryKind.folder,
    _ => LibraryKind.other,
  };

  /// An item the plugin bridge checked, or null without an id.
  static LibraryItem? itemFrom(Object? raw) {
    if (raw is! Map) return null;
    final id = '${raw['id'] ?? ''}';
    if (id.isEmpty) return null;
    final art = '${raw['artworkUrl'] ?? ''}';
    return LibraryItem(
      id: id,
      kind: _kind(raw['kind']),
      title: '${raw['title'] ?? ''}',
      subtitle: '${raw['subtitle'] ?? ''}',
      art: art.isEmpty ? null : art,
      playable: raw['playable'] != false,
      expandable: raw['browsable'] == true,
      durationMs: (raw['durationMs'] as num?)?.toInt(),
      raw: raw,
    );
  }

  static List<LibraryItem> itemsFrom(Object? raw) => [
    for (final r in raw is List ? raw : const []) ?itemFrom(r),
  ];

  static List<LibraryShelf> shelvesFrom(Object? raw) => [
    for (final s in raw is List ? raw : const [])
      if (s is Map)
        LibraryShelf(
          title: '${s['title'] ?? ''}',
          items: itemsFrom(s['items']),
        ),
  ];

  static LibraryPage pageFrom(Object? raw) => raw is Map
      ? LibraryPage(items: itemsFrom(raw['items']), more: raw['more'] == true)
      : LibraryPage.empty;
}
