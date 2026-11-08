import 'events.dart';

/// Ending one interaction must not release another source's hold.
class ActiveInteractions {
  final _active = <(InteractionSource, String)>{};

  bool update(VoiceInteractionChanged event) {
    final key = (event.source, event.reason);
    if (event.active) {
      _active.add(key);
    } else if (event.reason.isEmpty) {
      // An unspecified end preserves the legacy whole-source release.
      _active.removeWhere((entry) => entry.$1 == event.source);
    } else {
      _active.remove(key);
    }
    return _active.isNotEmpty;
  }

  /// Whether an open hold is for something that needs the screen: a voice
  /// turn, a timer, an alarm or a call. Media playing on the page and a
  /// reasonless pause only keep the screensaver from starting by itself.
  bool get needsScreen =>
      _active.any((entry) => !_idleOnlyReasons.contains(entry.$2));

  static const _idleOnlyReasons = {'', 'media'};

  /// The holds still open, as `source:reason` (`source:legacy` for a
  /// reasonless pause), for the log line that says why the screensaver
  /// stood down.
  Iterable<String> get held => _active.map(
    (entry) => '${entry.$1.name}:${entry.$2.isEmpty ? 'legacy' : entry.$2}',
  );
}
