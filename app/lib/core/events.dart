/// All events that travel on the [EventBus].
///
/// Events are immutable facts about something that already happened. They
/// carry no behavior and no references to managers.
library;

import 'dart:typed_data';

sealed class AppEvent {
  const AppEvent();

  /// Wire-format name used by the JS API (`kiosksatellite:<name>`), the
  /// remote WebSocket. Null for internal-only events.
  String? get wireName => null;

  Map<String, Object?> toJson() => const {};
}

// ── Screen ─────────────────────────────────────────────────────────────

/// The device turned out to keep its panel lit through a screen-off, or
/// stopped doing so. Internal: the Screen settings page explains why.
class AmbientDisplayChanged extends AppEvent {
  const AmbientDisplayChanged({required this.on});
  final bool on;
}

/// A kiosk Activity attached to the engine: the first one at start, or a
/// new one that replaced a still-running instance (a clear-task launch
/// from the restart alarm, the HOME intent while the app is the launcher,
/// the OS re-creating the screen). The engine and this isolate outlive the
/// Activity, but the native bridges scoped to it do not: the camera
/// session, for one, is torn down with the old Activity and has to be
/// bound again on the new one.
class ActivityAttached extends AppEvent {
  const ActivityAttached();
}

/// The device owner was set or cleared while the app runs. An Echo image's
/// installer can make the kiosk the device owner after its first start,
/// and the home role and the real Wi-Fi address wait for it.
class DeviceOwnerChanged extends AppEvent {
  const DeviceOwnerChanged();
}

class ScreenStateChanged extends AppEvent {
  const ScreenStateChanged({required this.on, this.source = 'system'});
  final bool on;

  /// 'app' when this app moved the panel itself (screenOn/screenOff, from
  /// a dismiss, the wake word or the ESPHome Screen switch); 'system' for the
  /// power button, double-tap-to-wake and everything else the OS reports;
  /// 'probe' when a wake this app asked for turned out not to have lit the
  /// panel, and the flag is being taken back to match it.
  /// The distinction is what lets a person waking the panel land on the
  /// dashboard while an automation switching it on keeps its screensaver.
  final String source;

  @override
  String get wireName => on ? 'screenon' : 'screenoff';
}

class BrightnessChanged extends AppEvent {
  const BrightnessChanged({required this.level, double? panel})
    : panel = panel ?? level;

  /// The level Home Assistant's Screen light and the remote admin's slider
  /// control, normalized 0..1: the panel itself with adaptive brightness
  /// off, the Maximum brightness setting with it on.
  final double level;

  /// What the panel shows, normalized 0..1. Equal to [level] with adaptive
  /// brightness off; the Panel brightness diagnostic sensor reports it.
  final double panel;

  @override
  Map<String, Object?> toJson() => {'level': level, 'panel': panel};
}

// ── Screensaver ────────────────────────────────────────────────────────

class ScreensaverStateChanged extends AppEvent {
  const ScreensaverStateChanged({
    required this.active,
    this.nowPlaying = false,
  });
  final bool active;

  /// The session starts with Now Playing up, so the return to the dashboard
  /// can make way for the Now Playing dismissal target (issue #899).
  final bool nowPlaying;

  @override
  String get wireName => active ? 'screensaverstart' : 'screensaverstop';
}

/// The moment the idle clock will start the screensaver moved (issue
/// #406): armed or re-armed by a touch, a dismissal or a setting, null when
/// nothing is counting down (the screensaver off or showing, a voice turn,
/// a camera view, hold mode, another app in front). Internal: the ESPHome
/// Next screensaver sensor rides it, as a single timestamp Home Assistant
/// can trigger on rather than a seconds counter churning the recorder.
class ScreensaverCountdownChanged extends AppEvent {
  const ScreensaverCountdownChanged({required this.due, this.mode});
  final DateTime? due;

  /// The mode the idle clock will start at [due], schedule included, so a
  /// screensaver that can get ready ahead of time knows whether it is the
  /// one due. Null with a null [due].
  final String? mode;
}

/// The motion policy the active screensaver schedule entry imposes (issue
/// #89): true/false overrides the "Dismiss on motion" switch for the
/// entry's duration, null returns to the switch. Published at session start
/// and on every schedule boundary, cleared on stop. Internal: the motion
/// manager starts and stops the camera off it.
class ScreensaverMotionPolicyChanged extends AppEvent {
  const ScreensaverMotionPolicyChanged({
    required this.dismissOnMotion,
    required this.dismissOnFace,
    this.dismissOnProximity,
    this.dismissOnPerson,
  });
  final bool? dismissOnMotion;

  /// The same override for "Dismiss on face" (issue #304), so a day entry
  /// can wake on faces while a night entry falls back to motion.
  final bool? dismissOnFace;

  /// The same for "Dismiss on proximity" and "Dismiss on person" (issue
  /// #437): the proximity and person sensor managers gate their sensors
  /// off these the way the motion manager gates the camera.
  final bool? dismissOnProximity;
  final bool? dismissOnPerson;
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

/// The app's and Home Assistant's light or dark state moved (the page
/// state the JS API reports, see PageStateManager). [state] is what
/// `kioskSatellite.getTheme()` answers.
class ThemeStateChanged extends AppEvent {
  const ThemeStateChanged(this.state);
  final Map<String, Object?> state;

  @override
  String get wireName => 'theme';

  @override
  Map<String, Object?> toJson() => state;
}

/// Something `kioskSatellite.getKioskState()` reports moved: kiosk mode,
/// Lockdown Mode, Home Assistant kiosk mode, the screensaver, the screen,
/// hold mode, rotation, the camera view or the media player. [state] is
/// the whole snapshot.
class KioskStateChanged extends AppEvent {
  const KioskStateChanged(this.state);
  final Map<String, Object?> state;

  @override
  String get wireName => 'kiosk-state';

  @override
  Map<String, Object?> toJson() => state;
}

/// A full screen view came up or went: the Now Playing view in the
/// screensaver slot (`nowPlaying`) or the intercom's roster or call screen
/// (`intercom`). Internal: the remote admin labels its screenshot by it and
/// takes a fresh one.
class FullscreenViewChanged extends AppEvent {
  const FullscreenViewChanged({required this.view, required this.shown});

  final String view;
  final bool shown;
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
/// app owns it. Internal: the ESPHome sensor republishes off it.
class NextAlarmChanged extends AppEvent {
  const NextAlarmChanged();
}

class VolumeChanged extends AppEvent {
  const VolumeChanged();

  @override
  String get wireName => 'volumechanged';
}

/// A meaningfully different ambient light reading from the device's light
/// sensor (damped at the native side). Internal-only; ESPHome mirrors it into
/// the Home Assistant illuminance sensor.
class LightLevelChanged extends AppEvent {
  const LightLevelChanged({required this.lux});
  final double lux;
}

/// The light level adaptive brightness follows moved, or its source did
/// (issue #911): the device's own sensor, or a Home Assistant entity in
/// its place. [lux] is null while the source has nothing to report yet,
/// [live] false while it is the last session's reading. Internal-only.
class AdaptiveLightChanged extends AppEvent {
  const AdaptiveLightChanged({
    required this.source,
    required this.lux,
    required this.live,
  });

  /// `sensor`, `entity` or `none` (the device sensor picked on a device
  /// without one).
  final String source;
  final double? lux;
  final bool live;
}

/// A GPS fix arrived (issue #363): the location manager relays the native
/// receiver's reading while Report location is on. Internal-only; the
/// ESPHome surface mirrors it into the location sensors.
class LocationChanged extends AppEvent {
  const LocationChanged({
    required this.latitude,
    required this.longitude,
    required this.time,
    this.accuracy,
    this.altitude,
    this.speed,
  });

  final double latitude;
  final double longitude;

  /// When the receiver took the fix.
  final DateTime time;

  /// Horizontal accuracy in meters, null when the receiver gave none.
  final double? accuracy;

  /// Meters above the WGS84 ellipsoid, null when the receiver gave none.
  final double? altitude;

  /// Ground speed in meters per second, null when the receiver gave none.
  final double? speed;
}

/// External power was connected or removed. Android broadcasts every battery
/// change; the device manager re-reads the plugged flag on each and only a
/// genuine flip travels here. Internal-only; ESPHome mirrors it into the
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

/// The kiosks on this network changed: one was heard for the first time,
/// renamed, updated, or went away. `devices` is the list the remote
/// admin's kiosk switcher draws, this device first.
class FleetChanged extends AppEvent {
  const FleetChanged({required this.devices});

  final List<Map<String, Object?>> devices;

  @override
  String get wireName => 'fleet';

  @override
  Map<String, Object?> toJson() => {'devices': devices};
}

/// This kiosk's place in a fleet changed: an invitation arrived or was
/// answered, a follower was added, accepted, synced, updated or removed,
/// a leader pushed here or was left. Carries nothing: both UIs re-read
/// the `fleetStatus` command, which is the one shape they draw from.
class FleetSyncChanged extends AppEvent {
  const FleetSyncChanged();

  @override
  String get wireName => 'fleetsync';
}

/// The page's Home Assistant connection reported that the dashboard set
/// may have moved: a dashboard created, deleted or edited (HA's own
/// `panels_updated` and `lovelace_updated` events), or the connection
/// coming up, on a load and on every reconnect after an outage. Internal:
/// the dashboard view selects re-read their option lists off it instead
/// of on a timer (issue #362).
class HaDashboardsChanged extends AppEvent {
  const HaDashboardsChanged({required this.reason});

  /// `panels`, `lovelace` or `ready`, as the page reported it.
  final String reason;
}

// ── Updates ────────────────────────────────────────────────────────────

/// The updater's picture of the world moved: a newer release appeared or
/// went away, a download started, made progress, or ended. Internal-only;
/// listeners read the details through getUpdateStatus.
class UpdateStateChanged extends AppEvent {
  const UpdateStateChanged();
}

/// The ROM's system update moved: a check ended, a newer image release
/// appeared, or a download or install made progress or ended. Only on the
/// Echo Dot's Kiosk Satellite Edition image. Internal-only; listeners read
/// the details through getSystemUpdateStatus.
class SystemUpdateStateChanged extends AppEvent {
  const SystemUpdateStateChanged();
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

/// A Bluetooth link came up or went down (the ACL broadcasts), so the
/// connected-devices sensors publish the change instead of waiting for the
/// minute poll. Home Assistant connecting to a lock through the Bluetooth
/// proxy holds the link for half a minute, which a poll can miss entirely
/// (issue #281).
class BluetoothLinksChanged extends AppEvent {
  const BluetoothLinksChanged();
}

/// A microphone capture level sample (RMS, 0..1, at most ~10/s), published
/// only while a remote admin client holds a mic-level watch. No wireName:
/// the page computes its own mic levels, this exists for the admin UI's
/// meter and is relayed explicitly by the remote manager.
class MicLevelSample extends AppEvent {
  const MicLevelSample({required this.rms});
  final double rms;
}

/// The room's noise level moved by 2 dB or more, froze, thawed, came or went
/// (issue #910). [dbfs] is a whole number averaged over 5 seconds, null
/// while unavailable. [held] keeps the last value through a voice turn or
/// the kiosk's own sound. Internal: the ESPHome sensor and plugins read it.
class NoiseLevelChanged extends AppEvent {
  const NoiseLevelChanged({
    required this.available,
    required this.dbfs,
    required this.held,
  });
  final bool available;
  final int? dbfs;
  final bool held;
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

/// Where a native sound's playback is, from the player about four times a
/// second while it plays. Internal: the voice overlay paces a long answer's
/// scroll to it.
class SoundProgress extends AppEvent {
  const SoundProgress({
    required this.id,
    required this.position,
    this.duration,
  });
  final String id;
  final Duration position;

  /// Null while it is unknown, as for a stream still arriving.
  final Duration? duration;
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

/// The durations of the sounds selected on this kiosk, in seconds.
class VoiceChimesChanged extends AppEvent {
  const VoiceChimesChanged(this.durations);
  final Map<String, double> durations;

  @override
  String get wireName => 'voice-chimes-changed';

  @override
  Map<String, Object?> toJson() => durations;
}

/// Any user/motion/page activity that should reset the idle timer.
class ActivityDetected extends AppEvent {
  const ActivityDetected({required this.source});
  final String source; // 'touch' | 'motion' | 'remote' | 'page'
}

/// The owner whose interactions end together when it is replaced.
/// Who reported an interaction: the dashboard page (the Voice Satellite
/// integration), Sendspin, a command, or the native voice satellite.
enum InteractionSource { page, sendspin, command, native }

/// A voice interaction is in progress (or has ended). Driven by Voice
/// Satellite, which brackets every turn — wake, listen, respond, speak — by
/// asking the app to hold its ambient behaviors (it calls pauseScreensaver
/// on the way in and out). Ambient features that must stand down for the
/// duration of a conversation (the screensaver, the dashboard view
/// rotation) observe this rather than reaching into each other.
class VoiceInteractionChanged extends AppEvent {
  const VoiceInteractionChanged({
    required this.active,
    this.reason = '',
    this.source = InteractionSource.command,
  });
  final bool active;
  final InteractionSource source;

  /// What kind of interaction, as reported by the page: 'voice',
  /// 'announcement', 'ask_question', 'start_conversation', 'timer', 'media',
  /// or '' when the page did not say (the legacy pauseScreensaver fallback).
  /// Consumers may specialize on it; absence must always behave like the
  /// plain event.
  final String reason;
}

/// Native Voice Satellite moved between Home Assistant's assist_satellite
/// states: idle, listening, processing or responding. Covers Assist turns
/// and realtime conversations alike.
class VoiceSatelliteStateChanged extends AppEvent {
  const VoiceSatelliteStateChanged(this.state, {this.announcement = false});
  final String state;

  /// Responding to an announcement rather than answering a turn. Home
  /// Assistant calls both responding, the VS_ broadcasts tell them apart.
  final bool announcement;
}

/// Native Voice Satellite's timers changed: one started, changed, was
/// cancelled, finished or had its alert dismissed. Carries the whole
/// `voiceTimers` list so the ESPHome sensors and the page's
/// `kiosksatellite:voice-timers` listeners redraw from the event alone.
class VoiceTimersChanged extends AppEvent {
  const VoiceTimersChanged(this.timers);
  final List<Map<String, Object?>> timers;

  @override
  String get wireName => 'voice-timers';

  @override
  Map<String, Object?> toJson() => {'timers': timers};
}

// ── Alarms ─────────────────────────────────────────────────────────────

/// The alarms or their ringing state changed: an alarm added, edited or
/// removed, a sunrise starting, a ring, a snooze, a stop. Carries the whole
/// `alarmsStatus` shape so the remote admin redraws from the event alone.
class AlarmStateChanged extends AppEvent {
  const AlarmStateChanged(this.status);
  final Map<String, Object?> status;

  @override
  String get wireName => 'alarms';

  @override
  Map<String, Object?> toJson() => status;
}

// ── Intercom ───────────────────────────────────────────────────────────

/// The camera failed while a call was sending from it.
class IntercomCameraLost extends AppEvent {
  const IntercomCameraLost();
}

/// A call wants this kiosk's camera sending, at [config]'s size, rate and
/// bitrate and on its `facing` if it names one, or is done with it when
/// [config] is null.
class IntercomCameraDemand extends AppEvent {
  const IntercomCameraDemand(this.config);
  final Map<String, Object>? config;
}

/// The intercom's state changed: a call placed, ringing, answered, ended,
/// a broadcast coming in, the roster of kiosks moved. Carries the whole
/// `intercomStatus` shape so the remote admin redraws from the event
/// alone; both UIs draw the same thing.
class IntercomStateChanged extends AppEvent {
  const IntercomStateChanged(this.status);
  final Map<String, Object?> status;

  @override
  String get wireName => 'intercom';

  @override
  Map<String, Object?> toJson() => status;
}

/// The hardware button that hangs up the intercom call, as an Android
/// key code, or 0 for none. Published while a call is placed or live, or
/// while one rings here when Hang up button while ringing picks Accept or
/// Decline, and set back to 0 when it ends, so the button keeps its usual
/// job the rest of the time. The kiosk manager hands it to the native key
/// handler.
class IntercomHangupKeyArmed extends AppEvent {
  const IntercomHangupKeyArmed(this.keyCode);
  final int keyCode;
}

/// The armed hang up button was pressed or a hang up gesture fired. A
/// call being placed, a live call or an announcement ends. A ringing call
/// is left alone unless [button] says the press came from the hang up
/// button, which then does what Hang up button while ringing picks.
class IntercomHangupRequested extends AppEvent {
  const IntercomHangupRequested({this.button = false});
  final bool button;
}

/// The intercom wants the microphone the page holds, or is done with it.
/// A page that captures the microphone itself, such as Voice Satellite
/// streaming to Home Assistant for its wake word, lets go for the call
/// and brings its capture back after.
class IntercomMicHold extends AppEvent {
  const IntercomMicHold({required this.hold});
  final bool hold;

  @override
  String get wireName => 'intercom-mic';

  @override
  Map<String, Object?> toJson() => {'hold': hold};
}

/// Voice levels during a call, for the card's meter: this kiosk's
/// microphone and the other side's voice, 0..1. At most fifteen a second
/// and never on the admin socket (no wireName), like the mic level.
class IntercomLevel extends AppEvent {
  const IntercomLevel({required this.near, required this.far});
  final double near;
  final double far;
}

// ── Motion ─────────────────────────────────────────────────────────────

class MotionDetected extends AppEvent {
  const MotionDetected();

  @override
  String get wireName => 'motion';
}

/// The Home Assistant motion entity picked in the camera's place (issue
/// #973) reads detected: [held] false when it just turned on, true for
/// the repeats while it stays on. The screensaver consumes it as motion,
/// with the person sensor's rule: an arrival dismisses, a held one only
/// postpones. Internal: Home Assistant already has the entity.
class ExternalMotionDetected extends AppEvent {
  const ExternalMotionDetected({this.held = false});
  final bool held;
}

/// The motion entity's state moved (issue #973), for the settings rows:
/// [detected] null while it has not reported or reads unavailable.
class ExternalMotionChanged extends AppEvent {
  const ExternalMotionChanged({required this.detected});
  final bool? detected;
}

/// Someone is looking at the kiosk (issue #304): the motion camera's face
/// detector found a camera-facing face at least as large as the Face
/// sensitivity asks for. Rate-limited to one per second natively, like
/// motion; the screensaver consumes it to wake under "Dismiss on face".
class FaceDetected extends AppEvent {
  const FaceDetected();

  @override
  String get wireName => 'face';
}

/// A face just dismissed the screensaver (discussion #371): the
/// screensaver manager's answer to a [FaceDetected] that passed every
/// gate and woke the screen, published right before the stop. Internal:
/// the motion manager shows the camera preview off it, when that is on.
/// Not a face that merely postponed the next screensaver, which repeats
/// every second or so for as long as someone stays.
class FaceDismissedScreensaver extends AppEvent {
  const FaceDismissedScreensaver();
}

/// Someone is in view of the device's own person sensor (discussion #353,
/// today the Meta Portal's people tracker): the person sensor manager
/// relays it while the screensaver's "Dismiss on person" has it reading
/// (or its postpone leg does, between screensavers).
/// Republished every couple of seconds while someone stays, so the
/// postpone leg keeps holding the screensaver off, like [ProximityDetected].
///
/// [held] tells the two apart: false for the absent-to-present transition
/// (someone arrived, which Dismiss on person acts on), true for every
/// repeat while they stay (what Postpone on person holds the idle clock
/// with). A person already there when a screensaver starts is a held
/// signal, not an arrival, so the screensaver stays up.
class PersonDetected extends AppEvent {
  const PersonDetected({this.held = false});

  final bool held;

  @override
  String get wireName => 'person';

  @override
  Map<String, Object?> toJson() => {'held': held};
}

/// The device's person sensor reported someone in view, or the room empty
/// again (discussion #353). Internal: the settings rows read the state;
/// [PersonDetected] is what the screensaver consumes.
class PersonSensorChanged extends AppEvent {
  const PersonSensorChanged({required this.present});
  final bool present;
}

/// Something came close to the panel: the device's proximity sensor
/// flipped from far to near while the screensaver's "Dismiss on
/// proximity" had it watching (or its postpone leg did, between
/// screensavers). Republished every few seconds while it stays near, so
/// the postpone leg keeps holding the screensaver off.
///
/// [held] is false for the far-to-near flip and true for the repeats,
/// the same split as [PersonDetected]: Dismiss on proximity acts on the
/// approach, Postpone on proximity on the whole stay.
class ProximityDetected extends AppEvent {
  const ProximityDetected({this.held = false});

  final bool held;

  @override
  String get wireName => 'proximity';

  @override
  Map<String, Object?> toJson() => {'held': held};
}

/// A hand in front of the camera (the Show fingers gesture): the motion
/// camera's palm detector proposed it and the hand landmark model
/// confirmed it and counted [fingers] extended fingers on the largest
/// one; [hands] is 0 once the hand has gone. Internal only: the gestures
/// manager turns it into a [GestureDetected].
class PalmDetected extends AppEvent {
  const PalmDetected({required this.hands, this.fingers, this.fingersUp});
  final int hands;
  final int? fingers;

  /// Which digits are up, thumb first then index to pinky, when judged.
  final List<bool>? fingersUp;
}

// ── Device camera ──────────────────────────────────────────────────────

/// A fresh still from the device's own camera (JPEG bytes). Internal-only
/// (no wireName), like [AudioChunk]: a binary payload must never enter the
/// generic wire-event feed. The ESPHome camera entity serves it.
class CameraSnapshotTaken extends AppEvent {
  const CameraSnapshotTaken({required this.jpeg});
  final Uint8List jpeg;
}

/// The display was captured for someone to look at: the remote admin's
/// overview page fetched its preview. The Home Assistant twins (the
/// Screenshot camera and Last screenshot over ESPHome) follow it,
/// so "last screenshot" means the last capture a person asked for,
/// whichever door they came in by. Captures a client raises on its own
/// (a camera fetch refreshing a preview) do not publish this.
class ScreenshotTaken extends AppEvent {
  const ScreenshotTaken({required this.jpeg});
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

/// Native Voice Satellite's overlay came up or went away. The screensaver
/// holds its idle countdown while the overlay shows an answer or results,
/// which linger after the turn itself has ended.
class AssistOverlayVisibility extends AppEvent {
  const AssistOverlayVisibility(this.visible, {bool? covers, bool? pauses})
    : covers = covers ?? visible,
      pauses = pauses ?? visible;
  final bool visible;

  /// It covers the screen (full screen). Docked, it is a bubble over the
  /// screen, which shows around it.
  final bool covers;

  /// What is under it stops rendering: the dashboard, a camera view and an
  /// expensive screensaver hold their last frame. Under both modes, until
  /// a touch outside the docked bubble wakes them for the rest of it.
  final bool pauses;
}

/// The calendar opened, closed or moved to another view: the view it shows
/// (day, week, month or schedule), or null once it closed. Internal: the
/// ESPHome Calendar view select follows it.
class CalendarViewChanged extends AppEvent {
  const CalendarViewChanged(this.view);

  final String? view;
}

/// The page or view on screen changed: the dashboard, an overlay page, a
/// KS page such as the calendar, a camera view, Now Playing or the menu.
/// [mode] is the navigation style, classic or compass. [id] is the camera
/// view's ID, null for every other view. Internal: plugins hear it as
/// navigation.view.
class NavigationViewChanged extends AppEvent {
  const NavigationViewChanged({
    required this.mode,
    required this.view,
    this.id,
  });

  final String mode;
  final String view;
  final String? id;

  @override
  Map<String, Object?> toJson() => {'mode': mode, 'view': view, 'id': id};

  @override
  bool operator ==(Object other) =>
      other is NavigationViewChanged &&
      other.mode == mode &&
      other.view == view &&
      other.id == id;

  @override
  int get hashCode => Object.hash(mode, view, id);
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

/// Something was raised over the kiosk on purpose: another app through
/// launchApp (the app launcher, a gesture action, ESPHome, the remote admin),
/// a deep link through openUri or the Android Settings app through
/// openSystemSettings. Internal: the launcher manager arms its auto-return
/// clock off it (issue #114) and the kiosk manager's foreground reclaim
/// lets the pause that follows stand (issue #417). [package] is the app's
/// package, or the URI itself for a deep link, whose app is unknown.
class AppLaunched extends AppEvent {
  const AppLaunched({required this.package});
  final String package;
}

/// The system's home-role dialog came back (issue #219). [held] is what
/// the role actually resolves to now, not the dialog's own result code.
class HomeRoleChanged extends AppEvent {
  const HomeRoleChanged({required this.held});
  final bool held;
}

/// A HOME press landed on the kiosk while it was already in front, with
/// the kiosk as the device's home screen (issue #219). The kiosk screen
/// answers it the way every launcher does: close what is open, return to
/// the start screen.
class HomeKeyPressed extends AppEvent {
  const HomeKeyPressed();
}

/// A hardware volume key pressed while the native side routes them to
/// the followed media player (issue #544): [direction] is 'up', 'down'
/// or 'mute'. Held keys repeat.
class VolumeKeyPressed extends AppEvent {
  const VolumeKeyPressed({required this.direction});
  final String direction;
}

// ── Gestures (issue #99) ───────────────────────────────────────────────

/// A configured hidden gesture was detected natively. [id] is the mapping
/// id from gestures.mappings; the gestures manager resolves and runs the
/// mapped action.
class GestureDetected extends AppEvent {
  const GestureDetected({required this.id});
  final String id;
}

/// A running plugin fired one of its declared triggers (issue #888). The
/// gestures manager runs every mapping bound to it.
class PluginTriggerFired extends AppEvent {
  const PluginTriggerFired({required this.pluginId, required this.trigger});
  final String pluginId;
  final String trigger;
}

/// A gesture's Home Assistant action (a service call, script, automation
/// trigger or event) came back. Those actions leave nothing on screen by
/// themselves, so the kiosk screen turns the outcome into a toast: what
/// ran, or why it did not. [action] is the mapping's action object.
class GestureActionCompleted extends AppEvent {
  const GestureActionCompleted({
    required this.action,
    required this.ok,
    this.error,
  });
  final Map<String, Object?> action;
  final bool ok;
  final String? error;
}

// ── Sendspin ───────────────────────────────────────────────────────────

/// The Sendspin now-playing display state. [active] is whether the
/// full-screen view has something to show: a track playing (the
/// track-change grace period included), or one paused under the view's
/// media controls for as long as the floating card would hold its paused
/// look. The screensaver consumes it for the takeover and the view's own
/// motion policy, and [playing] alone for launch on play, which wants the
/// moment playback starts, not the moment a paused track appears.
class SendspinNowPlayingChanged extends AppEvent {
  const SendspinNowPlayingChanged({required this.active, this.playing = false});
  final bool active;
  final bool playing;
}

/// The local Sendspin player's identity or connection changed: whether
/// it is on and connected, its Sendspin client id and name and the Music
/// Assistant player and server it maps to. Plugins hear it as
/// `sendspin.player`.
class SendspinPlayerChanged extends AppEvent {
  const SendspinPlayerChanged(this.player);
  final Map<String, Object?> player;
}

/// An AirPlay session started, changed or ended: the snapshot the
/// receiver pushes (the sender's name, whether it plays, the track, its
/// progress and cover), or null once no sender is connected. The Now
/// Playing surfaces follow it while a session lasts.
class AirPlaySessionChanged extends AppEvent {
  const AirPlaySessionChanged(this.session);
  final Map<String, Object?>? session;
}

/// A plugin player sent a new state while it is the pick, or null once it
/// stopped being one (SDK `player`).
class PluginPlayerStateChanged extends AppEvent {
  const PluginPlayerStateChanged(this.pick, this.state);
  final String pick;
  final Map<String, Object?>? state;
}

/// A plugin player's queue changed, so a queue on screen reads it again.
class PluginPlayerQueueChanged extends AppEvent {
  const PluginPlayerQueueChanged(this.pick);
  final String pick;
}

/// The followed player's state, title, artist or source moved (issue
/// #741): what the ESPHome media sensors show. Published only on a real
/// change, never for a position tick.
class MediaSummaryChanged extends AppEvent {
  const MediaSummaryChanged(this.summary);
  final Map<String, String> summary;
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

/// Available choices changed without a settings write.
class SettingOptionsChanged extends AppEvent {
  const SettingOptionsChanged(this.key);
  final String key;
}

/// Internal plugin entity changes. These do not enter dashboard JavaScript.
class PluginEntityCatalogChanged extends AppEvent {
  const PluginEntityCatalogChanged();
}

class PluginEntityStateChanged extends AppEvent {
  const PluginEntityStateChanged(this.objectId, this.value);
  final String objectId;
  final Object? value;
}

/// A selected HA entity snapshot addressed to one active plugin session.
class PluginHaStateChanged extends AppEvent {
  const PluginHaStateChanged(this.owner, this.entityId, this.data);
  final String owner;
  final String entityId;
  final Map<String, Object?> data;
}

/// The Shizuku connection reported a new state (issue #528). [granted] is
/// whether Kiosk Satellite may run commands through it right now; the
/// Restart device entry, tile and ESPHome button follow it on a device
/// that is not the owner.
class ShizukuStateChanged extends AppEvent {
  const ShizukuStateChanged({required this.granted});
  final bool granted;
}

/// The device has no WebView provider at all, so no dashboard can ever
/// come up: the kiosk screen swaps the WebView slot for a notice and the
/// frame watchdog stands down instead of restarting the process forever.
/// Internal.
class WebViewMissing extends AppEvent {
  const WebViewMissing();
}

/// A manager has new diagnostic state for subscribed remote viewers.
/// The topic contains no settings or sensor payload.
class RemoteStatusChanged extends AppEvent {
  const RemoteStatusChanged(this.topic);
  final String topic;
}

/// The union of topics currently requested by remote viewers.
class RemoteObserversChanged extends AppEvent {
  const RemoteObserversChanged(this.topics);
  final Set<String> topics;
}

/// The dashboard document was replaced or detached.
class VoiceTimersCleared extends AppEvent {
  const VoiceTimersCleared();
}

/// An event for Home Assistant to fire on its bus, sent over the ESPHome
/// API while that server runs. [name] goes out under `esphome.`, the only
/// namespace Home Assistant fires device events in. Strings stay strings;
/// numbers, booleans, lists and nulls arrive in Home Assistant as their
/// own types.
class HaEventRequested extends AppEvent {
  const HaEventRequested(this.name, this.data);
  final String name;
  final Map<String, Object?> data;
}

/// A gesture on a native timer pill, routed to its owning integration.
class VoiceTimerAction extends AppEvent {
  const VoiceTimerAction({
    required this.entityId,
    required this.id,
    required this.action,
  });
  final String entityId;
  final String id;
  final String action;

  @override
  String get wireName => 'timer-action';

  @override
  Map<String, Object?> toJson() => {
    'entityId': entityId,
    'id': id,
    'action': action,
  };
}

/// The device certificate was replaced or renewed.
class TlsIdentityChanged extends AppEvent {
  const TlsIdentityChanged();
}
