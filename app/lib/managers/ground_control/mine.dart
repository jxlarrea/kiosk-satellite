/// What "my" means on this kiosk: the person Voice Match placed in the
/// current voice turn and the things Ground Control keeps for them (to-do
/// list, calendar, playlist and Home Assistant person).
///
/// The kiosk resolves it on its own, from the people Ground Control sends
/// on the control connection, so a script asking "whose list" needs no
/// round trip to the service.
library;

/// The things a person can own, as Ground Control names them.
const mineThings = {'todo_list', 'calendar', 'playlist', 'person'};

/// Who is speaking in this kiosk's voice turn.
class Speaking {
  const Speaking({
    required this.name,
    this.id,
    this.by,
    this.things = const {},
  });

  /// Ground Control's person id. Null for a voice nobody enrolled.
  final String? id;
  final String name;

  /// How the voice was placed: `voice`, `wake_word` or `only_person`.
  final String? by;
  final Map<String, String> things;

  /// As a voice request carries it to a feature's command.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'by': by,
    'things': things,
  };

  /// From [toJson], or null for anything else.
  static Speaking? from(Object? raw) {
    if (raw is! Map) return null;
    final name = '${raw['name'] ?? ''}'.trim();
    if (name.isEmpty) return null;
    final things = raw['things'];
    return Speaking(
      id: raw['id'] is String ? raw['id'] as String : null,
      name: name,
      by: raw['by'] is String ? raw['by'] as String : null,
      things: {
        if (things is Map)
          for (final e in things.entries)
            if ('${e.value ?? ''}'.trim().isNotEmpty)
              '${e.key}': '${e.value}'.trim(),
      },
    );
  }
}

/// The things of person [id] among [people] (Ground Control's list).
Map<String, String> thingsOf(String? id, List<Map<String, Object?>> people) {
  if (id == null) return const {};
  for (final p in people) {
    if (p['id'] == id) {
      return Speaking.from({'name': '-', 'things': p['things']})!.things;
    }
  }
  return const {};
}

/// What "my [thing]" means for [speaking], in the shape the
/// `kiosk_satellite_mine_result` event carries:
///
/// - `own`: the speaker is known and has one, in `entity` (or `query` for
///   a playlist, which Music Assistant finds by name).
/// - `none`: nobody in the home has one of their own. Use the command's
///   normal target.
/// - `no_speaker`: someone has one, but nobody was identified. Say so
///   rather than guess.
/// - `not_theirs`: the speaker is known but has none. Use the normal
///   target.
Map<String, Object?> resolveMine(
  String thing,
  Speaking? speaking,
  List<Map<String, Object?>> people,
) {
  if (!mineThings.contains(thing)) {
    return {
      'ok': false,
      'error': 'thing must be one of ${mineThings.join(', ')}',
    };
  }
  final anyone = people.any((p) {
    final things = p['things'];
    return things is Map && '${things[thing] ?? ''}'.trim().isNotEmpty;
  });
  final own = speaking?.things[thing];
  final status = own != null
      ? 'own'
      : !anyone
      ? 'none'
      : speaking == null
      ? 'no_speaker'
      : 'not_theirs';
  return {
    'ok': true,
    'thing': thing,
    'status': status,
    'speaking': speaking?.name,
    'by': speaking?.by,
    (thing == 'playlist' ? 'query' : 'entity'): ?own,
  };
}

/// Words a script uses for the person speaking ("me", "my", "mine"), as
/// the calendar and music scripts ask the LLM to send them.
bool meansSpeaker(String word) => const {
  'me',
  'my',
  'mine',
  'myself',
  'i',
  'myplaylist',
  'mycalendar',
}.contains(word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), ''));
