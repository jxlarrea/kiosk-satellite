import 'library_model.dart';

/// What a random pick draws from when it plays: a library list, or the
/// favorites of one.
enum RandomPick { tracks, favorites, playlists, albums, radio }

/// Music chosen in the music picker and kept with a feature, an alarm
/// for one: what plays, from which source, on which speaker and whether
/// it shuffles. Either one library entry or a random draw from a list,
/// made again every time it plays.
class MusicPick {
  const MusicPick({
    required this.source,
    this.item,
    this.random,
    this.shuffle = false,
    this.speaker = '',
    this.speakerName = '',
  }) : assert(item != null || random != null);

  /// 'ma', 'ha' or 'sonos'.
  final String source;

  /// The entry that plays, or null for a random draw.
  final LibraryItem? item;

  /// The list a random pick draws from.
  final RandomPick? random;

  /// Play an album, a playlist or a station list in random order.
  final bool shuffle;

  /// The speaker it plays on, a player pick as `sendspin.player` stores
  /// it: '' for this device's own player, else `ma:`, `ha:` or `sonos:`
  /// and the player's id.
  final String speaker;
  final String speakerName;

  bool get isRandom => item == null;

  /// Whether Shuffle means anything for it: more than one track.
  bool get canShuffle => canShuffleKind(item?.kind, random);

  static bool canShuffleKind(LibraryKind? kind, RandomPick? random) =>
      random != null
      ? random == RandomPick.playlists || random == RandomPick.albums
      : switch (kind) {
          LibraryKind.album ||
          LibraryKind.playlist ||
          LibraryKind.artist ||
          LibraryKind.folder ||
          LibraryKind.podcast ||
          LibraryKind.audiobook => true,
          _ => false,
        };

  MusicPick copyWith({bool? shuffle, String? speaker, String? speakerName}) =>
      MusicPick(
        source: source,
        item: item,
        random: random,
        shuffle: shuffle ?? this.shuffle,
        speaker: speaker ?? this.speaker,
        speakerName: speakerName ?? this.speakerName,
      );

  Map<String, Object?> toJson() => {
    'source': source,
    if (item != null) 'item': libraryItemToJson(item!, source),
    if (random != null) 'random': random!.name,
    'shuffle': shuffle && canShuffle,
    'speaker': speaker,
    'speakerName': speakerName,
  };

  /// Null for anything that is not a pick, so a bad entry never takes an
  /// alarm down with it.
  static MusicPick? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final source = '${raw['source'] ?? ''}';
    if (!const {'ma', 'ha', 'sonos'}.contains(source)) return null;
    final item = libraryItemFromJson(raw['item']);
    final random = RandomPick.values
        .where((r) => r.name == raw['random'])
        .firstOrNull;
    if (item == null && random == null) return null;
    return MusicPick(
      source: source,
      item: item,
      random: item == null ? random : null,
      shuffle: raw['shuffle'] == true,
      speaker: '${raw['speaker'] ?? ''}',
      speakerName: '${raw['speakerName'] ?? ''}',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MusicPick &&
      other.source == source &&
      other.item?.id == item?.id &&
      other.random == random &&
      other.shuffle == shuffle &&
      other.speaker == speaker;

  @override
  int get hashCode => Object.hash(source, item?.id, random, shuffle, speaker);
}

/// An entry as JSON, for keeping it in a setting and for the remote
/// admin. Only what playing and opening it needs is kept from the
/// source's own record: a Music Assistant item carries its whole metadata
/// otherwise.
Map<String, Object?> libraryItemToJson(LibraryItem item, String source) => {
  'id': item.id,
  'kind': item.kind.name,
  'title': item.title,
  if (item.subtitle.isNotEmpty) 'subtitle': item.subtitle,
  if (item.art != null) 'art': item.art,
  if (item.artDark != null) 'artDark': item.artDark,
  'playable': item.playable,
  'expandable': item.expandable,
  if (item.durationMs != null) 'durationMs': item.durationMs,
  if (item.raw case final Map raw) 'raw': _keptRaw(raw, source),
};

Map<String, Object?> _keptRaw(Map raw, String source) {
  final keep = switch (source) {
    'ma' => const ['item_id', 'uri', 'media_type', 'provider', 'path', 'year'],
    'ha' => const [
      'media_content_id',
      'media_content_type',
      'media_class',
      'can_play',
      'can_expand',
      'title',
    ],
    _ => null,
  };
  return {
    for (final e in raw.entries)
      if (keep == null || keep.contains(e.key))
        '${e.key}': e.value is Map || e.value is List ? null : e.value,
  }..removeWhere((_, v) => v == null);
}

LibraryItem? libraryItemFromJson(Object? raw) {
  if (raw is! Map) return null;
  final id = '${raw['id'] ?? ''}';
  if (id.isEmpty) return null;
  final kind = LibraryKind.values
      .where((k) => k.name == raw['kind'])
      .firstOrNull;
  final art = raw['art'];
  final artDark = raw['artDark'];
  final duration = raw['durationMs'];
  return LibraryItem(
    id: id,
    kind: kind ?? LibraryKind.other,
    title: '${raw['title'] ?? ''}',
    subtitle: '${raw['subtitle'] ?? ''}',
    art: art is String && art.isNotEmpty ? art : null,
    artDark: artDark is String && artDark.isNotEmpty ? artDark : null,
    playable: raw['playable'] != false,
    expandable: raw['expandable'] == true,
    durationMs: duration is num ? duration.toInt() : null,
    raw: raw['raw'] is Map
        ? Map<String, Object?>.from(raw['raw'] as Map)
        : null,
  );
}
