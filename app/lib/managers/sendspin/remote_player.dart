/// A player that is not this device, followed by the Now Playing surfaces:
/// the floating card, the full-screen view and the transport buttons show
/// and steer it instead of the local Sendspin player.
///
/// Every follower publishes the same map shape SendspinManager builds for
/// the local player ('title', 'artist', 'album', 'durationMs',
/// 'positionMs', 'receivedAt', 'artworkUrl', 'playing', 'shuffle',
/// 'supportedCommands' and 'volume' when the source reports one), or
/// null when there is nothing to show, so the surfaces need not know which
/// kind of player they are looking at.
abstract interface class RemotePlayer {
  /// The followed player's id in its own system: a Music Assistant player
  /// id, a Home Assistant entity id.
  String get playerId;

  /// Whether the source's last word was that the player holds no track (a
  /// cleared queue, an idle player), as opposed to a connection that
  /// dropped.
  bool get queueEmpty;

  /// Whether the source can list a queue for the Now Playing panel and
  /// jump within it.
  bool get hasQueue;

  /// Whether the source keeps a library the playing track can be marked
  /// a favorite in.
  bool get hasFavorites;

  /// Whether the source reports position closely enough for synced lyrics
  /// to follow the music.
  bool get lyricsSynced;

  void start();

  Future<void> stop();

  /// The "show the player" reveal with nothing on screen: surface the
  /// player's last track as a paused card.
  void reveal();

  /// Re-read the player's state and republish it.
  Future<void> refresh();

  /// A transport command: play, pause, stop, next, previous.
  Future<bool> control(String command);

  Future<bool> setShuffle(bool on);

  Future<bool> seek(int positionMs);

  /// Set the player's volume, 0 to 100.
  Future<bool> setVolume(int percent);

  /// The queue the player plays from, for the Now Playing panel or null
  /// when the source keeps none of its own here (Music Assistant's is
  /// read through its API by the manager).
  Future<RemoteQueue?> fetchQueue();

  /// Jump the queue to the row [id] a [fetchQueue] answer carried. False
  /// when the source handles it elsewhere or refused.
  Future<bool> playQueueItem(String id);
}

/// A queue as the Now Playing panel lists it: rows with index, id, title,
/// artist, durationMs, current and played and how many follow the
/// playing one.
class RemoteQueue {
  const RemoteQueue({required this.items, required this.upNext});

  final List<Map<String, Object?>> items;
  final int upNext;
}

/// The source a `sendspin.player` value names.
enum PlayerSourceKind {
  /// This device's own Sendspin player (the empty value).
  local,

  /// A Music Assistant player, `ma:<player id>`.
  musicAssistant,

  /// A Home Assistant media_player entity, `ha:<entity id>`.
  homeAssistant,

  /// A Sonos speaker followed directly, `sonos:<player id>`.
  sonos,
}

/// A parsed `sendspin.player` value: which system the player belongs to
/// and its id there.
class PlayerSource {
  const PlayerSource(this.kind, this.id);

  /// Parse the stored value. Anything without a known prefix is treated
  /// as a Music Assistant player id, the shape the setting had before it
  /// carried a prefix.
  factory PlayerSource.parse(String value) {
    final v = value.trim();
    if (v.isEmpty) return const PlayerSource(PlayerSourceKind.local, '');
    if (v.startsWith('ha:')) {
      return PlayerSource(PlayerSourceKind.homeAssistant, v.substring(3));
    }
    if (v.startsWith('sonos:')) {
      return PlayerSource(PlayerSourceKind.sonos, v.substring(6));
    }
    if (v.startsWith('ma:')) {
      return PlayerSource(PlayerSourceKind.musicAssistant, v.substring(3));
    }
    return PlayerSource(PlayerSourceKind.musicAssistant, v);
  }

  final PlayerSourceKind kind;
  final String id;

  bool get isLocal => kind == PlayerSourceKind.local;

  /// The stored form.
  String get value => switch (kind) {
    PlayerSourceKind.local => '',
    PlayerSourceKind.musicAssistant => 'ma:$id',
    PlayerSourceKind.homeAssistant => 'ha:$id',
    PlayerSourceKind.sonos => 'sonos:$id',
  };
}
