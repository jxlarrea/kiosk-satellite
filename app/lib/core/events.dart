/// All events that travel on the [EventBus].
///
/// Events are immutable facts about something that already happened. They
/// carry no behavior and no references to managers.
library;

import 'dart:typed_data';

sealed class AppEvent {
  const AppEvent();

  /// Wire-format name used by the JS API (`kiosksatellite:<name>`), the
  /// remote WebSocket, and MQTT. Null for internal-only events.
  String? get wireName => null;

  Map<String, Object?> toJson() => const {};
}

// ── Screen ─────────────────────────────────────────────────────────────

/// The device turned out to keep its panel lit through a screen-off, or
/// stopped doing so. Internal: the MQTT screen entity withdraws itself while
/// it holds, and the Screen settings page explains why.
class AmbientDisplayChanged extends AppEvent {
  const AmbientDisplayChanged({required this.on});
  final bool on;
}

class ScreenStateChanged extends AppEvent {
  const ScreenStateChanged({required this.on, this.source = 'system'});
  final bool on;

  /// 'app' when this app moved the panel itself (screenOn/screenOff, from
  /// a dismiss, the wake word or the MQTT Screen switch); 'system' for the
  /// power button, double-tap-to-wake and everything else the OS reports.
  /// The distinction is what lets a person waking the panel land on the
  /// dashboard while an automation switching it on keeps its screensaver.
  final String source;

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

/// The motion policy the active screensaver schedule entry imposes (issue
/// #89): true/false overrides the "Dismiss on motion" switch for the
/// entry's duration, null returns to the switch. Published at session start
/// and on every schedule boundary, cleared on stop. Internal: the motion
/// manager starts and stops the camera off it.
class ScreensaverMotionPolicyChanged extends AppEvent {
  const ScreensaverMotionPolicyChanged({required this.dismissOnMotion});
  final bool? dismissOnMotion;
}

/// The overlay the screensaver shows changed: a mode's view came up, a
/// mid-session flip swapped it, or it went away (Dim shows none; stop clears
/// it). Internal: the browser's rendering freeze keys off whether an overlay
/// actually covers the dashboard — Dim leaves the page visible, so hiding
/// its WebView would blank the screen (issue #82).
class ScreensaverViewChanged extends AppEvent {
  const ScreensaverViewChanged({required this.view});

  /// Same values as ScreensaverManager.activeView; null when no overlay.
  final String? view;
}

/// A slideshow screensaver swapped to its next slide. Internal: the motion
/// manager treats it like every other self-inflicted light change — a
/// dark-to-bright photo relights the room exactly like the screensaver
/// starting did, and the AE resettle that follows can read as a body.
class ScreensaverSlideChanged extends AppEvent {
  const ScreensaverSlideChanged();
}

/// The device's media volume changed, from any side: a command, the
/// hardware rocker, or another app.
/// The device's next alarm was set, moved or dismissed, in whichever clock
/// app owns it. Internal: the MQTT sensor republishes off it.
class NextAlarmChanged extends AppEvent {
  const NextAlarmChanged();
}

class VolumeChanged extends AppEvent {
  const VolumeChanged();

  @override
  String get wireName => 'volumechanged';
}

/// A meaningfully different ambient light reading from the device's light
/// sensor (damped at the native side). Internal-only; MQTT mirrors it into
/// the Home Assistant illuminance sensor.
class LightLevelChanged extends AppEvent {
  const LightLevelChanged({required this.lux});
  final double lux;
}

/// External power was connected or removed. Android broadcasts every battery
/// change; the device manager re-reads the plugged flag on each and only a
/// genuine flip travels here. Internal-only; MQTT mirrors it into the
/// Charging binary sensor without waiting for the minute poll (issue #205).
class PowerChanged extends AppEvent {
  const PowerChanged({required this.charging});
  final bool charging;
}

// ── Network ────────────────────────────────────────────────────────────

/// The device's default network came up or went away (Android's default
/// network callback, relayed by the platform side). Only genuine
/// transitions travel here — the callback's registration-time replay of an
/// already-present network is dropped at the source, so an `up` event
/// always means an outage just ended. Internal: managers holding a dead
/// connection retry NOW off it instead of waiting out their backoff
/// timers, and the browser checks the page it is showing.
class NetworkStateChanged extends AppEvent {
  const NetworkStateChanged({required this.up});
  final bool up;
}

// ── Updates ────────────────────────────────────────────────────────────

/// The updater's picture of the world moved: a newer release appeared or
/// went away, a download started, made progress, or ended. Internal-only;
/// listeners read the details through getUpdateStatus.
class UpdateStateChanged extends AppEvent {
  const UpdateStateChanged();
}

/// A native sound (playSound) actually began playing. Wire event: the page
/// times stop-word arming and its speaking UI off real audio start.
class SoundStarted extends AppEvent {
  const SoundStarted({required this.id});
  final String id;

  @override
  String get wireName => 'sound-started';

  @override
  Map<String, Object?> toJson() => {'id': id};
}

/// The set of audio devices changed (a Bluetooth headset connected, a USB
/// mic unplugged). Internal: the settings dropdowns refresh their lists,
/// and the wake-word engine reopens capture when the change moved where
/// the selected microphone actually resolves.
class AudioDevicesChanged extends AppEvent {
  const AudioDevicesChanged({required this.capturePathChanged});

  /// True when the configured mic selector now resolves to a different
  /// physical device than the capture was opened on (including to or from
  /// nothing). Only then is an engine restart worth its cost.
  final bool capturePathChanged;
}

/// A microphone capture level sample (RMS, 0..1, at most ~10/s), published
/// only while a remote admin client holds a mic-level watch. No wireName:
/// the page computes its own mic levels, this exists for the admin UI's
/// meter and is relayed explicitly by the remote manager.
class MicLevelSample extends AppEvent {
  const MicLevelSample({required this.rms});
  final double rms;
}

/// A playback level sample from a native sound (mean |amplitude|, 0..1, at
/// most ~20/s). Wire event: the page's reactive bar animates to audio it
/// never touches.
class SoundLevel extends AppEvent {
  const SoundLevel({required this.id, required this.level});
  final String id;
  final double level;

  @override
  String get wireName => 'sound-level';

  @override
  Map<String, Object?> toJson() => {'id': id, 'level': level};
}

/// A native sound (playSound) finished, failed, or was stopped. Wire event
/// so the page can await completion of audio it handed over.
class SoundEnded extends AppEvent {
  const SoundEnded({required this.id, this.error});
  final String id;
  final String? error;

  @override
  String get wireName => 'sound-ended';

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    if (error != null) 'error': error,
  };
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

// ── Device camera ──────────────────────────────────────────────────────

/// A fresh still from the device's own camera (JPEG bytes). Internal-only
/// (no wireName), like [AudioChunk]: a binary payload must never enter the
/// generic wire-event feed. MQTT publishes it to the camera entity's topic.
class CameraSnapshotTaken extends AppEvent {
  const CameraSnapshotTaken({required this.jpeg});
  final Uint8List jpeg;
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
  Map<String, Object?> toJson() => {
    'pcm': base64,
    'sampleRate': sampleRate,
    'preRoll': preRoll,
  };
}

// ── Native pipeline transport ──────────────────────────────────────────

/// One event from a delegated voice_satellite/run_pipeline subscription,
/// forwarded verbatim to the page. Internal-only (no wireName), like
/// [AudioChunk]: streaming intent-progress deltas would otherwise flood the
/// remote admin feed. The JS API bridge dispatches it explicitly as
/// `kiosksatellite:pipeline`.
class PipelineEvent extends AppEvent {
  const PipelineEvent({required this.runId, required this.message});
  final String runId;
  final Map<String, Object?> message;

  @override
  Map<String, Object?> toJson() => {'runId': runId, 'message': message};
}

/// A delegated run's transport died underneath it (the app's HA websocket
/// closed mid-run). Subscriptions cannot be resumed, so the page's pipeline
/// recovery restarts the turn. Internal-only; dispatched explicitly as
/// `kiosksatellite:pipeline-closed`.
class PipelineClosed extends AppEvent {
  const PipelineClosed({required this.runId, required this.reason});
  final String runId;
  final String reason;

  @override
  Map<String, Object?> toJson() => {'runId': runId, 'reason': reason};
}

/// Speech-weighted mic levels during a delegated turn, batched (~4/s).
/// The page's reactive bar animates to audio it never receives. [levels]
/// carries per-chunk entries as {o: ms offset from the first, v: level};
/// the page replays them locally so the bar still moves at chunk cadence
/// while the bridge is called a third as often. [level] is the newest
/// value, for zero-forcing and older consumers. Internal-only; dispatched
/// explicitly as `kiosksatellite:pipeline-level`.
class PipelineMicLevel extends AppEvent {
  const PipelineMicLevel({required this.level, this.levels = const []});
  final double level;
  final List<Map<String, Object?>> levels;

  @override
  Map<String, Object?> toJson() => {'level': level, 'levels': levels};
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
  const WakeWordStateChanged({
    required this.active,
    required this.listening,
    this.muted = false,
  });
  final bool active;
  final bool listening;

  /// Voice Satellite muted the satellite and the microphone is closed. The
  /// clap detector honors this too: someone who mutes the device expects it
  /// to stop listening, claps included.
  final bool muted;
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
  Map<String, Object?> toJson() => {
    'level': level,
    'message': message,
    'time': timeMs,
  };
}

/// The user asked for the docked web console from somewhere other than the
/// drawer (the Logs settings page). Internal: the kiosk screen opens it.
class WebConsoleRequested extends AppEvent {
  const WebConsoleRequested();
}

class PageChanged extends AppEvent {
  const PageChanged({required this.url});
  final String url;

  @override
  Map<String, Object?> toJson() => {'url': url};
}

/// The WebView's visible URL moved, including SPA navigations (Home
/// Assistant's pushState routing) that [PageChanged] never sees — that one
/// only fires on full document loads.
class UrlChanged extends AppEvent {
  const UrlChanged({required this.url});
  final String url;

  @override
  Map<String, Object?> toJson() => {'url': url};
}

/// The frame watchdog asking the kiosk screen to rebuild the dashboard
/// WebView in place (issue #145): a platform-view create that failed —
/// typically because it raced the Activity attach at process boot — never
/// retries on its own, so the widget sits dead while everything around it
/// runs. A rebuild after the Activity is attached succeeds; the watchdog's
/// process restart stays the backstop when it does not. Internal.
class WebViewRebuildRequested extends AppEvent {
  const WebViewRebuildRequested();
}

// ── Camera views ───────────────────────────────────────────────────────

class CameraConfigurationChanged extends AppEvent {
  const CameraConfigurationChanged();
}

class CameraViewStateChanged extends AppEvent {
  const CameraViewStateChanged({
    required this.viewId,
    required this.viewName,
    this.focusedCameraId,
  });

  final String? viewId;
  final String? viewName;
  final String? focusedCameraId;

  bool get active => viewId != null;

  @override
  String get wireName => 'cameraview';

  @override
  Map<String, Object?> toJson() => {
    'active': active,
    'viewId': viewId,
    'viewName': viewName,
    'focusedCameraId': focusedCameraId,
  };
}

// ── Kiosk lockdown ─────────────────────────────────────────────────────

/// The kiosk exit gesture (N fast taps, optionally holding the last,
/// counted natively) fired. The kiosk screen answers with the PIN prompt
/// and the menu.
class KioskExitGesture extends AppEvent {
  const KioskExitGesture();
}

/// The Back key, swallowed natively while kiosk mode holds. The kiosk
/// screen re-interprets it: close the menu, else step the page's history.
class KioskBackPressed extends AppEvent {
  const KioskBackPressed();
}

/// Another app was opened over the kiosk through launchApp — the app
/// launcher, a gesture action, MQTT, the remote admin. Internal: the
/// launcher manager arms its auto-return clock off it (issue #114).
class AppLaunched extends AppEvent {
  const AppLaunched({required this.package});
  final String package;
}

// ── Gestures (issue #99) ───────────────────────────────────────────────

/// A configured hidden gesture was detected natively. [id] is the mapping
/// id from gestures.mappings; the gestures manager resolves and runs the
/// mapped action.
class GestureDetected extends AppEvent {
  const GestureDetected({required this.id});
  final String id;
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

/// Someone asked for the floating player card right now (the "Show the
/// Sendspin player" gesture action, or the kiosk menu's Show player
/// entry). The overlay flips the card override to shown on this — which
/// clears a fling or paused-out dismissal and reveals the card even while
/// `sendspin.show_player` is off, without writing that setting — and the
/// manager recovers a paused queue from Music Assistant when there is
/// nothing on screen to show.
class SendspinShowPlayerRequested extends AppEvent {
  const SendspinShowPlayerRequested();
}

// ── Notifications ──────────────────────────────────────────────────────

/// How many notifications are on screen (see NotificationManager). The
/// screensaver watches it: something worth reading has arrived over a
/// dimmed panel, so the dimming lifts until the last card is gone.
class NotificationsChanged extends AppEvent {
  const NotificationsChanged({required this.count});
  final int count;

  bool get showing => count > 0;
}

// ── Settings ───────────────────────────────────────────────────────────

class SettingChanged extends AppEvent {
  const SettingChanged({required this.key, required this.value, this.previous});
  final String key;
  final Object? value;

  /// The value the setting held before this change (null when the publisher
  /// does not know it). Lets a listener react to what actually changed — the
  /// browser rewrites the start URL's origin only when it matched the *old*
  /// HA base URL.
  final Object? previous;
}
