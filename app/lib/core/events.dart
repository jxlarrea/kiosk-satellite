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

/// The device's media volume changed, from any side: a command, the
/// hardware rocker, or another app.
class VolumeChanged extends AppEvent {
  const VolumeChanged();

  @override
  String get wireName => 'volumechanged';
}

/// Any user/motion/page activity that should reset the idle timer.
class ActivityDetected extends AppEvent {
  const ActivityDetected({required this.source});
  final String source; // 'touch' | 'motion' | 'remote' | 'page'
}

/// A voice interaction is in progress (or has ended). Driven by Voice
/// Satellite, which brackets every turn — wake, listen, respond, speak — by
/// asking the app to hold its ambient behaviors (it calls pauseScreensaver
/// on the way in and out). Ambient features that must stand down for the
/// duration of a conversation (the screensaver, the dashboard view
/// rotation) observe this rather than reaching into each other.
class VoiceInteractionChanged extends AppEvent {
  const VoiceInteractionChanged({required this.active, this.reason = ''});
  final bool active;

  /// What kind of interaction, as reported by the page: 'voice',
  /// 'announcement', 'ask_question', 'start_conversation', 'timer', 'media',
  /// or '' when the page did not say (the legacy pauseScreensaver fallback).
  /// Consumers may specialize on it; absence must always behave like the
  /// plain event.
  final String reason;
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

/// A chunk of captured mic audio for the page (base64 PCM16 LE, 16 kHz mono).
///
/// Internal-only (no wireName): the JS API bridge subscribes to it directly
/// and dispatches it into the page. It must NOT go through the generic
/// wire-event feed, or the remote admin WebSocket would stream ~43 KB/s of
/// audio to every connected browser.
class AudioChunk extends AppEvent {
  const AudioChunk({
    required this.base64,
    required this.sampleRate,
    this.preRoll = false,
  });
  final String base64;
  final int sampleRate;

  /// True for the already-captured chunks replayed from the pre-roll ring when
  /// a stream starts. The speech pipeline wants them (they hold the start of
  /// the command), but a level meter must skip them: they are past audio, so
  /// rendering them leaves the meter running a pre-roll behind live speech for
  /// as long as the stream lasts.
  final bool preRoll;

  @override
  Map<String, Object?> toJson() =>
      {'pcm': base64, 'sampleRate': sampleRate, 'preRoll': preRoll};
}

/// The stop word fired during an interruptible state (TTS, media, a ringing
/// timer). The page decides what to interrupt; we only report the word.
class StopWordDetected extends AppEvent {
  const StopWordDetected();

  @override
  String get wireName => 'stopword';

  @override
  Map<String, Object?> toJson() => const {};
}

class WakeWordStateChanged extends AppEvent {
  const WakeWordStateChanged({required this.active, required this.listening});
  final bool active;
  final bool listening;
}

// ── Browser ────────────────────────────────────────────────────────────

/// A line from the WebView's JavaScript console. Internal-only (no
/// wireName) so it is never echoed back into the page; the remote server
/// relays it to admin WebSocket clients.
class ConsoleLine extends AppEvent {
  const ConsoleLine({
    required this.level,
    required this.message,
    required this.timeMs,
  });

  final String level; // 'log' | 'debug' | 'warn' | 'error' | 'tip'
  final String message;
  final int timeMs; // epoch millis (stamped by the browser manager)

  @override
  Map<String, Object?> toJson() =>
      {'level': level, 'message': message, 'time': timeMs};
}

class PageChanged extends AppEvent {
  const PageChanged({required this.url});
  final String url;

  @override
  Map<String, Object?> toJson() => {'url': url};
}

// ── Kiosk lockdown ─────────────────────────────────────────────────────

/// The kiosk exit gesture (N fast taps, counted natively) fired. The kiosk
/// screen answers with the PIN prompt and the menu.
class KioskExitGesture extends AppEvent {
  const KioskExitGesture();
}

/// The Back key, swallowed natively while kiosk mode holds. The kiosk
/// screen re-interprets it: close the menu, else step the page's history.
class KioskBackPressed extends AppEvent {
  const KioskBackPressed();
}

// ── Sendspin ───────────────────────────────────────────────────────────

/// The Sendspin now-playing display state: true while a track is loaded
/// (playing, paused, or inside the track-change grace period). The
/// screensaver consumes it to apply the full-screen player's own motion
/// dismissal policy.
class SendspinNowPlayingChanged extends AppEvent {
  const SendspinNowPlayingChanged({required this.active});
  final bool active;
}

// ── Settings ───────────────────────────────────────────────────────────

class SettingChanged extends AppEvent {
  const SettingChanged({required this.key, required this.value});
  final String key;
  final Object? value;
}
