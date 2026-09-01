import 'dart:async';

/// Throttles the Next screensaver sensor (issue #406) the way
/// [InteractionStamp] throttles Last interaction: a moment that lands after
/// a quiet spell publishes at once, and a stream of touches, each pushing
/// the moment a few seconds further out, collapses to one publish a minute.
///
/// One extra rule keeps the published moment honest: it is republished
/// before it passes whenever the real one has moved past it, so a Home
/// Assistant automation triggering on the sensor never fires at a moment the
/// device has already moved on from. A clear (null) always lands at once,
/// since a stale moment is exactly what such an automation must not act on.
class CountdownStamp {
  CountdownStamp(this._publish, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final void Function(DateTime? due) _publish;
  final DateTime Function() _now;

  static const minGap = Duration(seconds: 60);

  /// How far ahead of the published moment the correction lands.
  static const margin = Duration(seconds: 1);

  DateTime? _latest;
  DateTime? _published;
  DateTime? _publishedAt;
  Timer? _pending;

  /// The newest moment recorded, published or still waiting on the
  /// trailing timer.
  DateTime? get latest => _latest;

  /// The moment last handed to the publisher.
  DateTime? get published => _published;

  /// The countdown now ends at [due], or stopped (null).
  void set(DateTime? due) {
    _latest = due;
    if (due == _published) {
      _pending?.cancel();
      _pending = null;
      return;
    }
    final now = _now();
    final published = _published;
    final publishedAt = _publishedAt;
    if (due == null ||
        published == null ||
        publishedAt == null ||
        now.difference(publishedAt) >= minGap) {
      _flush(now);
      return;
    }
    // Hold until the minute gap runs out, or until the moment on the wire
    // is about to pass, whichever comes first.
    var at = publishedAt.add(minGap);
    final elapses = published.subtract(margin);
    if (elapses.isBefore(at)) at = elapses;
    var wait = at.difference(now);
    if (wait.isNegative) wait = Duration.zero;
    _pending?.cancel();
    _pending = Timer(wait, () {
      _pending = null;
      _flush(_now());
    });
  }

  void _flush(DateTime now) {
    _pending?.cancel();
    _pending = null;
    if (_latest == _published) return;
    _published = _latest;
    _publishedAt = now;
    _publish(_latest);
  }

  /// Cancels a waiting trailing publish; [set] works again afterwards.
  void dispose() {
    _pending?.cancel();
    _pending = null;
  }
}
