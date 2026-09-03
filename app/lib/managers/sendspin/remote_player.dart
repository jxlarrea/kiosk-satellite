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

  /// Mute or unmute the player, leaving its level where it is.
  Future<bool> setMute(bool muted);

  /// The queue the player plays from, for the Now Playing panel or null
  /// when the source keeps none of its own here (Music Assistant's is
  /// read through its API by the manager).
  Future<RemoteQueue?> fetchQueue();

  /// Jump the queue to the row [id] a [fetchQueue] answer carried. False
  /// when the source handles it elsewhere or refused.
  Future<bool> playQueueItem(String id);

  /// Whether the source can put other players in the followed player's
  /// group and take them out again, for the Now Playing chip's menu.
  bool get hasGrouping;

  /// The group the followed player plays in and every player that could
  /// join it, or null when the source cannot say.
  Future<RemoteGroup?> fetchGroup();

  /// Put the player [id] (a [RemoteGroup] member) in the group or take
  /// it out. False when the source refused.
  Future<bool> setGrouped(String id, bool grouped);
}

/// A player's group as the Now Playing chip's menu shows it, the same
/// from every member: the leader (the player the music streams from) is
/// the title, and every other player is a row, the shown player among
/// them when it follows, the members first, each in alphabetical order.
/// Unchecking the shown player's own row is leaving the group.
class RemoteGroup {
  const RemoteGroup({
    required this.selfId,
    required this.leaderId,
    required this.leaderName,
    required this.members,
  });

  /// The shown player's id in the source, so its row can say so.
  final String selfId;
  final String leaderId;
  final String leaderName;
  final List<GroupMember> members;

  /// Whether the shown player leads, in which case the title is its own
  /// name and it has no row.
  bool get leads => selfId == leaderId;

  /// [members] in the chip's order: the grouped ones first, then the
  /// rest, by name within each.
  static List<GroupMember> ordered(Iterable<GroupMember> members) {
    final list = members.toList()
      ..sort((a, b) {
        if (a.inGroup != b.inGroup) return a.inGroup ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return list;
  }
}

class GroupMember {
  const GroupMember({
    required this.id,
    required this.name,
    required this.inGroup,
    this.available = true,
  });

  final String id;
  final String name;
  final bool inGroup;
  final bool available;
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
