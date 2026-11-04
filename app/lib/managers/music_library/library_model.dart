/// What the Music Library shows, the same shape from every source: Music
/// Assistant, a Home Assistant speaker's media tree and a Sonos household.
library;

import 'dart:math';

/// What a library entry is. It picks the icon, the shape of its cover
/// (round for an artist) and what opening it does.
enum LibraryKind {
  artist,
  album,
  track,
  playlist,
  radio,
  podcast,
  episode,
  audiobook,
  genre,
  folder,
  other,
}

/// One entry: a card on a shelf, a row in a list or a track on an album.
class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle = '',
    this.art,
    this.artDark,
    this.playable = true,
    this.expandable = false,
    this.durationMs,
    this.favorite = false,
    this.inLibrary = false,
    this.raw,
  });

  /// The source's own key for it: a Music Assistant URI, a Home Assistant
  /// media content id or a Sonos object id.
  final String id;
  final LibraryKind kind;
  final String title;

  /// The artist, the owner or the service, whatever the source says
  /// under the title.
  final String subtitle;

  /// The cover's address, loaded through [LibrarySource.loadArt].
  final String? art;

  /// The cover drawn on a dark theme instead, where the source has one:
  /// a provider logo made for dark backgrounds.
  final String? artDark;

  final bool playable;

  /// Whether opening it lists more entries: an album's tracks, an
  /// artist's albums, a folder's children.
  final bool expandable;

  final int? durationMs;
  final bool favorite;

  /// In the user's own library, not just found on a service: what a
  /// spoken name most likely means.
  final bool inLibrary;

  /// The source's own record, kept for playing and opening it.
  final Object? raw;

  bool get round => kind == LibraryKind.artist;
}

/// A titled row of cards on Discover and in search results.
class LibraryShelf {
  const LibraryShelf({this.title = '', this.key, required this.items});

  /// The source's own title, as it names the shelf.
  final String title;

  /// A shelf the app names itself ('recent', 'playlists', 'tracks' and
  /// the rest), translated on screen. Wins over [title].
  final String? key;

  final List<LibraryItem> items;
}

/// A page of a long list. [more] says another page follows.
class LibraryPage {
  const LibraryPage({required this.items, this.more = false});

  static const empty = LibraryPage(items: []);

  final List<LibraryItem> items;
  final bool more;
}

/// An opened album, playlist, artist or podcast: the header facts, its
/// tracks or episodes and, for an artist, shelves of albums.
class LibraryDetail {
  const LibraryDetail({
    required this.item,
    this.year,
    this.tracks = const [],
    this.shelves = const [],
  });

  final LibraryItem item;
  final int? year;

  final List<LibraryItem> tracks;
  final List<LibraryShelf> shelves;
}

/// How a play request lands in the queue.
enum PlayMode {
  /// Clear the queue and play.
  replace,

  /// Play now, keeping the rest of the queue.
  now,

  /// Play after the current track.
  next,

  /// Add to the end of the queue.
  add,

  /// Play and keep going with similar music.
  radio,
}

/// A library category a source lists on its own: artists, albums and
/// the rest, in the sidebar and the chips.
class LibraryCategory {
  const LibraryCategory(this.key, this.kind);

  /// The source's own key for the list, also the label's lookup key.
  final String key;
  final LibraryKind kind;
}

/// An order a library list comes in.
enum LibrarySort { name, nameDesc, recentlyPlayed, recentlyAdded, mostPlayed }

/// Thrown by a source when it cannot answer, with a message fit for the
/// screen.
class LibraryError implements Exception {
  const LibraryError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What a source can do and how it lists, searches, opens and plays.
/// The speaker a play lands on is passed in each time, so the source
/// keeps no idea of its own about it.
abstract class LibrarySource {
  /// 'ma', 'ha' or 'sonos', matching the player pick's prefix.
  String get key;

  bool get hasDiscover => false;
  bool get hasSearch => false;
  bool get hasBrowse => false;
  bool get hasRadioMode => false;
  bool get hasFavorites => false;

  /// The library lists the sidebar shows under Library.
  List<LibraryCategory> get categories => const [];

  /// The orders [list] takes, the first its default. Empty when the
  /// source lists in an order of its own.
  List<LibrarySort> get sorts => const [];

  /// Whether [list] can leave out the artists credited on no album.
  bool get hasAlbumArtists => false;

  /// [categories] down to the ones worth showing.
  Future<List<LibraryCategory>> availableCategories() async => categories;

  /// Whether a play needs a speaker of this source picked first. Music
  /// Assistant plays on this device's own player too.
  bool needsSpeaker(String pick) => !pick.startsWith('$key:');

  Future<List<LibraryShelf>> discover() async => const [];

  Future<List<LibraryShelf>> search(String query) async => const [];

  /// A page of [category] in [sort], one of [sorts]. [albumArtists]
  /// lists only album artists, where [hasAlbumArtists].
  Future<LibraryPage> list(
    LibraryCategory category, {
    int offset = 0,
    bool favorites = false,
    LibrarySort? sort,
    bool albumArtists = false,
  }) async => LibraryPage.empty;

  /// The children of a folder in the source's own tree; null is its root.
  Future<LibraryPage> browse(LibraryItem? folder) async => LibraryPage.empty;

  Future<LibraryDetail> open(LibraryItem item);

  /// Play [item] on the speaker [pick] names. [within] is the album or
  /// playlist a track was tapped in, so the rest of it follows. Answers
  /// null, or what went wrong.
  Future<String?> play(
    LibraryItem item,
    PlayMode mode, {
    required String pick,
    LibraryItem? within,
  });

  Future<bool> setFavorite(LibraryItem item, bool favorite) async => false;

  /// A random playable entry of [category], for a random pick: one drawn
  /// from its first page here, from the whole list where the source can.
  Future<LibraryItem?> randomItem(
    LibraryCategory category, {
    bool favorites = false,
  }) async {
    final page = await list(category, favorites: favorites);
    final items = [
      for (final i in page.items)
        if (i.playable) i,
    ];
    return items.isEmpty ? null : items[_random.nextInt(items.length)];
  }

  /// How the speaker [pick] names is set: its volume, shuffle and repeat.
  /// Read before a saved pick plays, so they can be put back after. Null
  /// where the source cannot tell.
  Future<SpeakerState?> speakerState(String pick) async => null;

  /// Turn shuffle and repeat on the speaker [pick] names on or off; a
  /// null leaves that one alone. Answers whether the speaker took it.
  Future<bool> setPlayModes(
    String pick, {
    bool? shuffle,
    String? repeat,
  }) async => false;

  /// The speaker's own volume, 0 to 100.
  Future<bool> setSpeakerVolume(String pick, int percent) async => false;

  /// Stop what the speaker [pick] names plays.
  Future<bool> stopSpeaker(String pick) async => false;

  /// Stop it and take it out of the speaker's queue, so no paused track
  /// is left for Now Playing and the floating player to show. Stops it
  /// where the source cannot clear.
  Future<bool> clearSpeaker(String pick) => stopSpeaker(pick);

  /// Close connections. The source is built again on the next open.
  void dispose() {}
}

final _random = Random();

/// A speaker's volume, shuffle and repeat ('off', 'one' or 'all'), each
/// null when unknown.
class SpeakerState {
  const SpeakerState({this.volume, this.shuffle, this.repeat});

  final int? volume;
  final bool? shuffle;
  final String? repeat;

  @override
  String toString() => 'volume $volume, shuffle $shuffle, repeat $repeat';
}

/// "3:42" or "1:02:05".
String formatTrackLength(int? ms) {
  if (ms == null || ms <= 0) return '';
  final total = ms ~/ 1000;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = (total % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
