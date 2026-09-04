import 'dart:async';

import '../../core/events.dart';

/// The Last interaction sensor's stamp-and-throttle (issue #241) behind the
/// ESPHome entity.
///
/// Touches arrive once per pointer-down, and publishing each one would
/// churn the Home Assistant recorder for nothing. The leading edge lands
/// immediately — the first touch after a quiet spell is the "no longer
/// idle" moment automations wait on — and a trailing publish carries the
/// true final stamp once the minimum gap has passed, so "idle for n
/// minutes" arithmetic never runs against a stamp a minute older than the
/// last real touch.
class InteractionStamp {
  InteractionStamp(this._publish, {DateTime Function()? now})
    : _now = now ?? _utcNow;

  final void Function(DateTime stamp) _publish;
  final DateTime Function() _now;

  static DateTime _utcNow() => DateTime.now().toUtc();

  static const _minGap = Duration(seconds: 60);

  DateTime? _latest;
  DateTime? _publishedAt;
  Timer? _pending;

  /// The newest stamp recorded, published or still waiting on the trailing
  /// timer; for reseeding a link that came (back) up mid-run.
  DateTime? get latest => _latest;

  /// Whether a voice-interaction bracket counts as the user interacting: a
  /// spoken turn does, while an announcement, a ringing timer or media
  /// playback the device merely renders does not. The empty reason is the
  /// legacy pauseScreensaver fallback, which older Voice Satellite versions
  /// send only around spoken turns.
  static bool countsAsVoice(VoiceInteractionChanged e) =>
      e.active && (e.reason == 'voice' || e.reason.isEmpty);

  /// The user interacted right now.
  void mark() {
    final now = _now();
    _latest = now;
    final publishedAt = _publishedAt;
    final since = publishedAt == null ? _minGap : now.difference(publishedAt);
    if (since >= _minGap) {
      _publishedAt = now;
      _publish(now);
      return;
    }
    _pending ??= Timer(_minGap - since, () {
      _pending = null;
      _publishedAt = _now();
      final latest = _latest;
      if (latest != null) _publish(latest);
    });
  }

  /// Cancels a waiting trailing publish; [mark] works again afterwards.
  void dispose() {
    _pending?.cancel();
    _pending = null;
  }
}
