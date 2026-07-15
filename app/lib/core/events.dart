/// All events that travel on the [EventBus].
///
/// Events are immutable facts about something that already happened. They
/// carry no behavior and no references to managers.
library;

sealed class AppEvent {
  const AppEvent();

  /// Wire-format name used by the JS API (`kiosksatellite:<name>`), the
  /// remote WebSocket, and MQTT. Null for internal-only events.
  String? get wireName => null;

  Map<String, Object?> toJson() => const {};
}

// ── Screen ─────────────────────────────────────────────────────────────

class ScreenStateChanged extends AppEvent {
  const ScreenStateChanged({required this.on});
  final bool on;

  @override
  String get wireName => on ? 'screenon' : 'screenoff';
}

class BrightnessChanged extends AppEvent {
  const BrightnessChanged({required this.level});

  /// Normalized 0..1.
  final double level;

  @override
  Map<String, Object?> toJson() => {'level': level};
}

// ── Screensaver ────────────────────────────────────────────────────────

class ScreensaverStateChanged extends AppEvent {
  const ScreensaverStateChanged({required this.active});
  final bool active;

  @override
  String get wireName => active ? 'screensaverstart' : 'screensaverstop';
}

/// Any user/motion/page activity that should reset the idle timer.
class ActivityDetected extends AppEvent {
  const ActivityDetected({required this.source});
  final String source; // 'touch' | 'motion' | 'remote' | 'page'
}

// ── Motion ─────────────────────────────────────────────────────────────

class MotionDetected extends AppEvent {
  const MotionDetected();

  @override
  String get wireName => 'motion';
}

// ── Wake word ──────────────────────────────────────────────────────────

class WakeWordDetected extends AppEvent {
  const WakeWordDetected({required this.model, required this.phrase});
  final String model;
  final String phrase;

  @override
  String get wireName => 'wakeword';

  @override
  Map<String, Object?> toJson() => {'model': model, 'phrase': phrase};
}

class WakeWordStateChanged extends AppEvent {
  const WakeWordStateChanged({required this.active, required this.listening});
  final bool active;
  final bool listening;
}

// ── Browser ────────────────────────────────────────────────────────────

class PageChanged extends AppEvent {
  const PageChanged({required this.url});
  final String url;

  @override
  Map<String, Object?> toJson() => {'url': url};
}

// ── Settings ───────────────────────────────────────────────────────────

class SettingChanged extends AppEvent {
  const SettingChanged({required this.key, required this.value});
  final String key;
  final Object? value;
}
