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
}
