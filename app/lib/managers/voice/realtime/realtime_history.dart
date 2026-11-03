import 'realtime_backend.dart';

/// What was said in realtime conversations, kept so the next one can pick
/// up where the last left off. A conversation is a session with the
/// provider that starts empty: the earlier exchanges go to it in its
/// instructions. What is older than the session duration is dropped.
class RealtimeHistory {
  RealtimeHistory({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final _turns = <(DateTime, RealtimeTurn)>[];

  /// The most handed to a conversation: a long day of exchanges would
  /// make every connection slower and dearer for little gain.
  static const maxTurns = 60;
  static const maxCharacters = 8000;

  void add({required bool user, required String text}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _turns.add((_now(), RealtimeTurn(user: user, text: trimmed)));
  }

  /// The exchanges from the last [maxAge], oldest first, within the
  /// limits. Anything older is dropped for good.
  List<RealtimeTurn> recent(Duration maxAge) {
    final cutoff = _now().subtract(maxAge);
    _turns.removeWhere((t) => t.$1.isBefore(cutoff));
    final out = <RealtimeTurn>[];
    var characters = 0;
    for (final (_, turn) in _turns.reversed) {
      if (out.length == maxTurns) break;
      characters += turn.text.length;
      if (characters > maxCharacters && out.isNotEmpty) break;
      out.add(turn);
    }
    return out.reversed.toList();
  }

  /// Drops the user's last words when nothing answered them, once a
  /// conversation is over: a goodbye the assistant ended on without a word,
  /// or a turn the provider never replied to. Replayed, the next
  /// conversation answers them before anything said in it, and a goodbye
  /// ends it at once.
  void dropUnanswered() {
    while (_turns.isNotEmpty && _turns.last.$2.user) {
      _turns.removeLast();
    }
  }

  void clear() => _turns.clear();
}
