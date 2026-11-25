import 'dart:async';

/// Vision Match > Presence sensors: whether someone is in front of the
/// kiosk and whether someone looks at it, from the answers Ground Control
/// gives to the kiosk's looks.
///
/// Present turns on with any face, turned away or not, or a raised hand,
/// and off [presentHold] after the last look that found one. Looking turns
/// on with a face looking at the screen and off [lookingHold] after the
/// last one, the same time the Face sensor takes to clear. Looks keep
/// coming while a face was seen recently, so someone standing still stays
/// present. [onChange] is called once per change.
class VisionPresence {
  VisionPresence(this.onChange);

  static const presentHold = Duration(seconds: 30);
  static const lookingHold = Duration(seconds: 3);

  final void Function(bool present, bool looking) onChange;

  bool _present = false;
  bool _looking = false;
  Timer? _presentOff;
  Timer? _lookingOff;

  bool get present => _present;
  bool get looking => _looking;

  /// One answer from Ground Control: `faces`, each with `frontal`, and
  /// `hand`. A failed or dropped look says nothing.
  void look(Map<String, Object?> answer) {
    if (answer['failed'] == true) return;
    final faces = answer['faces'];
    final list = faces is List ? faces : const [];
    final facing = list.any((f) => f is Map && f['frontal'] == true);
    final someone = list.isNotEmpty || answer['hand'] is Map;
    if (someone) {
      _presentOff?.cancel();
      _presentOff = Timer(presentHold, () => _set(present: false));
    }
    if (facing) {
      _lookingOff?.cancel();
      _lookingOff = Timer(lookingHold, () => _set(looking: false));
    }
    _set(present: someone ? true : null, looking: facing ? true : null);
  }

  /// Nobody is in front of the kiosk any more as far as anyone can tell:
  /// the sensors are turned off or the looks stopped.
  void clear() {
    _presentOff?.cancel();
    _lookingOff?.cancel();
    _set(present: false, looking: false);
  }

  void _set({bool? present, bool? looking}) {
    final p = present ?? _present;
    // Looking at the kiosk means being in front of it.
    final l = (looking ?? _looking) && p;
    if (p == _present && l == _looking) return;
    _present = p;
    _looking = l;
    onChange(p, l);
  }

  void dispose() {
    _presentOff?.cancel();
    _lookingOff?.cancel();
  }
}
