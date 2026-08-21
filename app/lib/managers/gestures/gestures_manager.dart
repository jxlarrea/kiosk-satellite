import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';

import '../../core/events.dart';
import '../../core/manager.dart';
import '../../core/permissions.dart';
import '../audio/mic_hub.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'clap_detector.dart';
import 'gesture_mappings.dart';

/// Configurable gestures (issue #99): the action half.
///
/// KioskLock/GestureEngine detect the configured triggers natively and the
/// kiosk manager relays each hit as a [GestureDetected] with the mapping
/// id. This manager owns the other side: it resolves the id against
/// gestures.mappings and runs the mapped action. Everything is a
/// registered command (or a settings write), so a gesture can do exactly
/// what the remote admin and MQTT can.
///
/// It also owns the one acoustic trigger: clap sequences. While any claps
/// mapping exists, this manager subscribes to the shared microphone stream
/// ([MicHub]) and feeds a [ClapDetector]. On a device running native wake
/// word detection the capture is already open and claps ride it for free;
/// without one, the subscription itself opens the mic — which is what makes
/// the Clapper work with no Voice Satellite at all. Claps are suppressed
/// while a voice turn is running (a person emphatically talking at the
/// satellite must not fire a dashboard navigation), while the satellite is
/// muted, in Lockdown Mode, and under kiosk mode's Disable Gestures — the
/// same rules the touch triggers follow, plus the mute one that only a
/// microphone feature needs.
class GesturesManager extends Manager {
  GesturesManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    Stream<Uint8List> Function()? micStream,
    Future<PermissionOutcome> Function()? micPermission,
  }) : _micStream = micStream ?? (() => MicHub.instance.stream()),
       _micPermission =
           micPermission ?? (() => requestOsPermission(Permission.microphone));

  final SettingsManager _settings;
  final Stream<Uint8List> Function() _micStream;
  final Future<PermissionOutcome> Function() _micPermission;

  StreamSubscription<GestureDetected>? _sub;
  StreamSubscription<Uint8List>? _micSub;
  late final ClapDetector _detector = ClapDetector(
    onClaps: _onClaps,
    onDiscard: _onClapsDiscarded,
  );

  /// Discard diagnostics, rate limited: under continuous music the veto can
  /// discard every second or two, and a debug line each time would flood
  /// the ring buffer that a field report needs.
  DateTime _lastDiscardLog = DateTime.fromMillisecondsSinceEpoch(0);

  void _onClapsDiscarded(String reason) {
    final now = DateTime.now();
    if (now.difference(_lastDiscardLog) < const Duration(seconds: 10)) return;
    _lastDiscardLog = now;
    log.debug(name, 'clap sequence discarded: $reason');
  }

  /// A voice turn is running (wake word suspended by the page): claps heard
  /// now are someone talking at the satellite, not a command to us.
  bool _voiceTurn = false;

  /// Voice Satellite muted the satellite. A muted device must stop
  /// listening entirely, claps included.
  bool _wakeMuted = false;

  /// The last microphone permission answer, so a "Don't allow" is not
  /// re-prompted on every sync — only when the mappings or gates change
  /// again (the user re-engaging is the signal to ask again).
  PermissionOutcome? _micOutcome;
  bool _micPrompted = false;

  Timer? _micRetry;

  @override
  String get name => 'gestures';

  @override
  Future<void> init() async {
    _sub = bus.on<GestureDetected>().listen(_onGesture);

    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.gestureMappings.key ||
          e.key == defs.clapStrictness.key ||
          e.key == defs.lockdownEnabled.key ||
          e.key == defs.kioskEnabled.key ||
          e.key == defs.kioskDisableGestures.key) {
        _micPrompted = false; // a changed gate is permission to ask again
        _syncClapper();
      }
    });

    bus.on<WakeWordStateChanged>().listen((e) {
      final startedTurn = !e.active && !_voiceTurn;
      _voiceTurn = !e.active;
      // The turn's audio must not linger as half a clap sequence, and the
      // world after TTS played is acoustically new — start clean.
      if (startedTurn) _detector.reset();
      if (e.muted != _wakeMuted) {
        _wakeMuted = e.muted;
        _syncClapper();
      }
    });

    await _syncClapper();
  }

  @override
  Future<void> dispose() async {
    _micRetry?.cancel();
    await _micSub?.cancel();
    await _sub?.cancel();
  }

  /// Whether clap detection should be listening right now.
  bool get _clapsWanted =>
      _detectorTargets().isNotEmpty &&
      !_wakeMuted &&
      !_settings.get(defs.lockdownEnabled) &&
      !(_settings.get(defs.kioskEnabled) &&
          _settings.get(defs.kioskDisableGestures));

  Set<int> _detectorTargets() =>
      clapTargets(decodeGestureMappings(_settings.get(defs.gestureMappings)));

  /// Bring the mic subscription in line with the configuration. The detector
  /// itself is armed with the configured counts either way, so an edit to
  /// the mappings retunes a live subscription without touching the capture.
  Future<void> _syncClapper() async {
    _detector.targets = _detectorTargets();
    _detector.strict = _settings.get(defs.clapStrictness) == 'strict';
    final wanted = _clapsWanted;
    if (wanted && _micSub == null) {
      // Ask for the microphone ourselves: on a device with wake word
      // detection running the grant already exists and this returns
      // instantly, but a clapper-only device has nobody else to ask.
      if (_micOutcome != PermissionOutcome.granted) {
        if (_micPrompted) return; // already declined for this configuration
        _micPrompted = true;
        try {
          _micOutcome = await _micPermission();
        } catch (e) {
          log.error(name, 'could not check the microphone permission: $e');
          return;
        }
        if (_micOutcome != PermissionOutcome.granted) {
          log.error(
            name,
            'clap detection needs the microphone and it was '
            '${_micOutcome == PermissionOutcome.blocked ? 'blocked: allow it in the app settings' : 'declined'}',
          );
          return;
        }
      }
      if (!_clapsWanted || _micSub != null) return; // changed while asking
      _detector.reset();
      _micSub = _micStream().listen(_onMicChunk, onError: _onMicError);
      log.info(name, 'clap detection listening (${_detector.targets} claps)');
    } else if (!wanted && _micSub != null) {
      final sub = _micSub;
      _micSub = null;
      await sub?.cancel();
      _detector.reset();
      log.info(name, 'clap detection stopped');
    }
  }

  void _onMicChunk(Uint8List bytes) {
    // A voice turn keeps the audio flowing (the engine holds the mic for the
    // page); the claps in it are speech, not commands.
    if (_voiceTurn) return;
    _detector.addChunk(bytes);
  }

  /// The capture failed under us. The likeliest causes self-resolve (the
  /// audio server restarting, a USB mic mid-replug), so retry on a timer
  /// rather than going silently deaf — the same lesson the wake path
  /// learned, at lower stakes.
  void _onMicError(Object e) {
    log.warn(name, 'clap detection lost the microphone: $e');
    _micSub?.cancel();
    _micSub = null;
    _micRetry?.cancel();
    _micRetry = Timer(const Duration(seconds: 30), _syncClapper);
  }

  /// A completed clap sequence. Every mapping on that count fires, through
  /// the same [GestureDetected] path the native triggers use, so logging and
  /// dispatch stay in one place.
  void _onClaps(int count) {
    if (_voiceTurn || !_clapsWanted) return;
    log.info(name, 'detected $count claps');
    final mappings = decodeGestureMappings(_settings.get(defs.gestureMappings));
    for (final m in mappings) {
      if (m.triggerType == 'claps' &&
          (m.trigger['claps'] as num?)?.toInt() == count) {
        bus.publish(GestureDetected(id: m.id));
      }
    }
  }

  Future<void> _onGesture(GestureDetected e) async {
    final mappings = decodeGestureMappings(_settings.get(defs.gestureMappings));
    GestureMapping? mapping;
    for (final m in mappings) {
      if (m.id == e.id) {
        mapping = m;
        break;
      }
    }
    if (mapping == null) {
      // A stale trigger: the mapping changed under an armed Activity and
      // the fresh apply has not landed yet.
      log.warn(name, 'gesture ${e.id} has no mapping');
      return;
    }
    log.info(
      name,
      'gesture ${describeGestureTrigger(mapping.trigger)}: '
      '${describeGestureAction(mapping.action)}',
    );
    await runGestureAction(mapping.action);
  }

  /// Run one action object. Public so the editors' "Try it" affordances
  /// (device and remote) can exercise an action without a gesture.
  Future<void> runGestureAction(Map<String, Object?> action) async {
    final a = action;
    switch ('${a['type']}') {
      case 'navigate':
        await _run('haNavigate', {'path': a['path']});
      case 'url':
        await _run('showLinkPage', {'url': a['url']});
      case 'camera_view':
        if (a['mode'] == 'hide') {
          await _run('hideCameraView', const {});
        } else {
          // toggle: the same gesture performed again closes the view it
          // opened, which is what a repeated clap sequence should mean.
          await _run('showCameraView', {
            'viewId': a['viewId'] ?? '',
            'toggle': true,
          });
        }
      case 'sendspin_player':
        // Show only: the fling on the card is already the way to hide it.
        // The event clears the overlay's dismissal and, with nothing on
        // screen, recovers a paused queue from Music Assistant; it also
        // reveals the card while sendspin.show_player is off (the card
        // override), so the setting itself stays untouched.
        bus.publish(const SendspinShowPlayerRequested());
      case 'screensaver':
        await _run('startScreensaver', const {});
      case 'screensaver_stop':
        // Redundant for touch (any tap dismisses), real for claps: hands
        // full across the room, the screen comes back without walking over.
        await _run('stopScreensaver', const {});
      case 'hold_mode':
        // Toggle, not set: the same gesture pins the recipe and, performed
        // again, releases it (issue #266). The setting IS the state, so
        // every other surface follows.
        await _settings.set(defs.haHoldMode, !_settings.get(defs.haHoldMode));
      case 'launch_app':
        await _run('launchApp', {'package': a['package']});
      case 'open_uri':
        await _run('openUri', {'uri': a['uri']});
      case 'android_settings':
        await _run('openSystemSettings', const {});
      case 'ha_script':
        await _run('haCallService', {
          'domain': 'script',
          'service': 'turn_on',
          'entity_id': a['entityId'],
        });
      case 'ha_automation':
        await _run('haCallService', {
          'domain': 'automation',
          'service': 'trigger',
          'entity_id': a['entityId'],
        });
      case 'ha_service':
        await _run('haCallService', {
          'domain': a['domain'],
          'service': a['service'],
          if ('${a['entityId'] ?? ''}'.isNotEmpty) 'entity_id': a['entityId'],
          if (a['data'] is Map) 'data': a['data'],
        });
      case 'ha_event':
        await _run('haFireEvent', {
          'event': a['event'],
          if (a['data'] is Map) 'data': a['data'],
        });
      default:
        log.warn(name, 'unknown gesture action: ${a['type']}');
    }
  }

  Future<void> _run(String command, Map<String, Object?> params) async {
    final result = await commands.execute(command, params);
    if (!result.ok) log.warn(name, '$command failed: ${result.error}');
  }
}
