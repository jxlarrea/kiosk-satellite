import 'dart:convert';

/// The player Now Playing follows, as three settings hold it: the source
/// ('' for this device, 'ma', 'ha' or 'sonos'), the player pick and its
/// name.
typedef FollowedPlayer = ({String source, String player, String name});

/// Lends the followed player to a feature for a while and takes it back.
/// An alarm that plays music on a speaker borrows it, so Now Playing, the
/// floating player and the volume keys follow what the alarm plays. When
/// the alarm stops the kiosk goes back to the player it followed before,
/// unless someone picked another player meanwhile: that pick stands.
///
/// The lend is kept in a setting, so a restart in the middle of it gives
/// the player back at start up.
class PlayerHandoff {
  PlayerHandoff({
    required this.read,
    required this.follow,
    required this.load,
    required this.save,
  });

  /// The followed player now.
  final FollowedPlayer Function() read;

  /// Follow another player.
  final Future<void> Function(FollowedPlayer player) follow;

  /// The kept lend, '' when there is none.
  final String Function() load;
  final Future<void> Function(String json) save;

  /// The source a player pick belongs to.
  static String sourceOf(String player) =>
      player.contains(':') ? player.substring(0, player.indexOf(':')) : '';

  /// Who holds the player now, empty when nobody does.
  List<String> get owners => _record()?.owners ?? const [];

  bool get lent => owners.isNotEmpty;

  /// Follow [player] for [owner]. A second owner while one holds it takes
  /// the player over and the first player before either is the one given
  /// back.
  Future<void> borrow(String owner, String player, String name) async {
    final kept = _record();
    final now = read();
    final original = kept?.original ?? now;
    final owners = [...?kept?.owners.where((o) => o != owner), owner];
    await save(
      jsonEncode({
        'owners': owners,
        'original': _toJson(original),
        'player': player,
      }),
    );
    if (now.player != player || now.source != sourceOf(player)) {
      await follow((source: sourceOf(player), player: player, name: name));
    }
  }

  /// [owner] is done. The last one out puts the original player back,
  /// unless the followed player is no longer the lent one: someone picked
  /// a player while it was lent, and that pick stays.
  Future<void> giveBack(String owner) async {
    final kept = _record();
    if (kept == null || !kept.owners.contains(owner)) return;
    final owners = kept.owners.where((o) => o != owner).toList();
    if (owners.isNotEmpty) {
      await save(
        jsonEncode({
          'owners': owners,
          'original': _toJson(kept.original),
          'player': kept.player,
        }),
      );
      return;
    }
    await _end(kept);
  }

  /// At start up: a lend kept from before a restart is over, since the
  /// features that held it start over too.
  Future<void> recover() async {
    final kept = _record();
    if (kept != null) await _end(kept);
  }

  Future<void> _end(_Lend kept) async {
    await save('');
    final now = read();
    final unchanged =
        now.player == kept.player && now.source == sourceOf(kept.player);
    final original = kept.original;
    if (unchanged &&
        (original.player != now.player || original.source != now.source)) {
      await follow(original);
    }
  }

  _Lend? _record() {
    final raw = load().trim();
    if (raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      final owners = [for (final o in (m['owners'] as List? ?? const [])) '$o'];
      final o = m['original'];
      if (owners.isEmpty || o is! Map) return null;
      return _Lend(
        owners: owners,
        original: (
          source: '${o['source'] ?? ''}',
          player: '${o['player'] ?? ''}',
          name: '${o['name'] ?? ''}',
        ),
        player: '${m['player'] ?? ''}',
      );
    } on FormatException {
      return null;
    }
  }

  static Map<String, Object?> _toJson(FollowedPlayer p) => {
    'source': p.source,
    'player': p.player,
    'name': p.name,
  };
}

class _Lend {
  const _Lend({
    required this.owners,
    required this.original,
    required this.player,
  });

  final List<String> owners;
  final FollowedPlayer original;
  final String player;
}
