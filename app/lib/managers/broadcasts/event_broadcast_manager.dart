import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/active_interactions.dart';
import '../../core/events.dart';
import '../../core/manager.dart';

/// Sends one Android broadcast: [name] goes out as
/// `me.jxl.kiosk_satellite.event.<name>` with [extras] as intent extras.
typedef EventBroadcastSender =
    Future<void> Function(String name, Map<String, Object?> extras);

/// Android broadcasts that tell other apps on the device what the kiosk is
/// doing (issue #964). Tasker, MacroDroid or tvQuickActions can bring their
/// own app back the moment a voice turn ends, without polling Home
/// Assistant or dumpsys. The native side only sends what this decides
/// (EventBroadcastBridge.kt).
///
/// Each one but the timer, alarm and notification mirrors also goes to Home Assistant's
/// bus as `esphome.kiosk_satellite_<group>` with the lowercase rest of
/// its name as `event_type`, so VS_ENDED is `ended` on
/// `kiosk_satellite_voice` (issue #1007).
///
/// Everything here comes off the bus, so no other manager knows these
/// broadcasts exist:
///
/// * VS_STARTED and VS_ENDED bracket a built-in Voice Satellite
///   interaction: a turn, an announcement, a realtime conversation or a
///   ringing timer. VS_ENDED waits for the overlay to go too, so an answer
///   left on screen is not covered by the app coming back.
/// * VS_LISTENING, VS_THINKING, VS_SPEAKING and VS_ANNOUNCEMENT follow the
///   satellite state in between.
/// * VS_TIMER_*, ALARM_* and NOTIFICATION_* mirror the timer, alarm and
///   notification events Home Assistant gets, with the same fields as
///   extras.
/// * INTERCOM_* follow the call state. INTERCOM_ENDED fires once when a
///   call, broadcast or ring stops holding the kiosk.
/// * SCREENSAVER_STARTED and SCREENSAVER_STOPPED follow the screensaver.
/// * SCREEN_ON and SCREEN_OFF follow the panel, with who moved it.
class EventBroadcastManager extends Manager {
  EventBroadcastManager(super.bus, super.commands, super.log, {this.send});

  /// Where broadcasts go instead of Android, for tests.
  final EventBroadcastSender? send;

  static const _channel = MethodChannel('kiosk_satellite/event_broadcasts');

  @override
  String get name => 'broadcasts';

  StreamSubscription<AppEvent>? _sub;

  /// The built-in Voice Satellite's holds: a turn, an announcement, a
  /// vs_show prompt, a realtime conversation, a ringing timer.
  final _voiceHolds = ActiveInteractions();
  bool _overlayShown = false;
  bool _voiceActive = false;
  String _satelliteState = 'idle';

  String _intercomState = 'idle';
  String _intercomKiosk = '';

  bool _screensaverActive = false;

  @override
  Future<void> init() async {
    // One subscription keeps the bus's order: a hold released before the
    // overlay hides must be read in that order to end the turn once.
    _sub = bus.stream.listen(_onEvent);
  }

  void _onEvent(AppEvent event) {
    switch (event) {
      case VoiceInteractionChanged():
        _onVoiceHold(event);
      case AssistOverlayVisibility(:final visible):
        _overlayShown = visible;
        _endVoiceIfIdle();
      case VoiceSatelliteStateChanged():
        _onSatelliteState(event);
      case HaEventRequested(name: 'kiosk_satellite_timer', :final data):
        _mirror('VS_TIMER_', data);
      case HaEventRequested(name: 'kiosk_satellite_alarm', :final data):
        _mirror('ALARM_', data);
      case HaEventRequested(name: 'kiosk_satellite_notification', :final data):
        _mirror('NOTIFICATION_', data);
      case IntercomStateChanged(:final status):
        _onIntercom(status);
      case ScreensaverStateChanged(:final active):
        if (active == _screensaverActive) return;
        _screensaverActive = active;
        _emit('screensaver', active ? 'started' : 'stopped');
      case ScreenStateChanged(:final on, :final source):
        // A probe takes back a wake this app asked for, so it is the app's
        // doing too. 'system' is the power button, the OS timeout and
        // everything else Android reports without saying why.
        _emit('screen', on ? 'on' : 'off', {
          'source': source == 'system' ? 'system' : 'app',
        });
      default:
        break;
    }
  }

  // ── Voice Satellite ───────────────────────────────────────────────────

  void _onVoiceHold(VoiceInteractionChanged event) {
    // An alarm takeover holds as native too, but it has its own ALARM_
    // broadcasts.
    if (event.source != InteractionSource.native || event.reason == 'alarm') {
      return;
    }
    final held = _voiceHolds.update(event);
    if (held && !_voiceActive) {
      _voiceActive = true;
      _emit('voice', 'started', {'reason': event.reason});
    }
    _endVoiceIfIdle(held: held);
  }

  void _endVoiceIfIdle({bool? held}) {
    if (!_voiceActive || _overlayShown) return;
    if (held ?? _voiceHolds.held.isNotEmpty) return;
    _voiceActive = false;
    _emit('voice', 'ended');
  }

  void _onSatelliteState(VoiceSatelliteStateChanged event) {
    final state = event.state;
    if (state == _satelliteState) return;
    _satelliteState = state;
    final type = switch (state) {
      'listening' => 'listening',
      'processing' => 'thinking',
      'responding' when event.announcement => 'announcement',
      'responding' => 'speaking',
      _ => null,
    };
    if (type != null) _emit('voice', type);
  }

  // ── Timers and alarms ─────────────────────────────────────────────────

  void _mirror(String prefix, Map<String, Object?> data) {
    final type = data['event_type'];
    if (type is! String || type.isEmpty) return;
    _broadcast('$prefix${type.toUpperCase()}', {
      for (final entry in data.entries)
        if (entry.key != 'event_type') entry.key: entry.value,
    });
  }

  // ── Intercom ──────────────────────────────────────────────────────────

  static const _intercomStates = {
    'calling',
    'ringing',
    'in_call',
    'broadcasting',
    'listening',
    'missed',
  };

  /// The states that hold the kiosk, as the intercom's own audio focus and
  /// screensaver hold count them.
  static bool _holds(String state) =>
      state != 'idle' && state != 'missed' && state != 'ended';

  void _onIntercom(Map<String, Object?> status) {
    final state = '${status['state'] ?? 'idle'}';
    if (state == _intercomState) return;
    final was = _intercomState;
    _intercomState = state;
    final call = status['call'];
    final peer = call is Map ? call['peer'] : null;
    final kiosk = peer is Map ? '${peer['name'] ?? ''}' : '';
    // The peer is gone from the status by the time it reads idle, and
    // INTERCOM_ENDED still wants to say who it was.
    if (kiosk.isNotEmpty) _intercomKiosk = kiosk;
    if (_intercomStates.contains(state)) {
      _emit('intercom', state, {'kiosk': _intercomKiosk});
    }
    if (_holds(was) && !_holds(state)) {
      _emit('intercom', 'ended', {'kiosk': _intercomKiosk});
    }
    if (state == 'idle') _intercomKiosk = '';
  }

  // ── Sending ───────────────────────────────────────────────────────────

  static const _prefixes = {
    'voice': 'VS_',
    'intercom': 'INTERCOM_',
    'screensaver': 'SCREENSAVER_',
    'screen': 'SCREEN_',
  };

  /// One change, as an Android broadcast and as a Home Assistant event.
  void _emit(
    String group,
    String type, [
    Map<String, Object?> data = const {},
  ]) {
    _broadcast('${_prefixes[group]}${type.toUpperCase()}', data);
    bus.publish(
      HaEventRequested('kiosk_satellite_$group', {'event_type': type, ...data}),
    );
  }

  void _broadcast(String name, [Map<String, Object?> extras = const {}]) {
    log.info(this.name, name);
    unawaited(
      (send ?? _sendNative)(name, extras).catchError((Object error) {
        log.warn(this.name, '$name failed: $error');
      }),
    );
  }

  static Future<void> _sendNative(
    String name,
    Map<String, Object?> extras,
  ) async {
    await _channel.invokeMethod<bool>('send', {'name': name, 'extras': extras});
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
