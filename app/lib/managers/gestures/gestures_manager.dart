import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../../core/permissions.dart';
import '../audio/mic_hub.dart';
import '../kiosk/kiosk_link.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import '../voice/realtime/mcp_client.dart';
import 'clap_detector.dart';
import 'gesture_mappings.dart';
import 'hand_gesture_hold.dart';

/// Configurable gestures (issue #99): the action half.
///
/// KioskLock/GestureEngine detect the configured triggers natively and the
/// kiosk manager relays each hit as a [GestureDetected] with the mapping
/// id. This manager owns the other side: it resolves the id against
/// gestures.mappings and runs the mapped action. Everything is a
/// registered command (or a settings write), so a gesture can do exactly
/// what the remote admin and an ESPHome entity can.
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
///
/// The one visual trigger, a hand showing fingers, is found and judged
/// elsewhere (the motion camera's palm detector and hand landmark model,
/// run by [MotionManager] while a fingers mapping exists): every report
/// says how many fingers the hand shows, and a mapping fires the first
/// time its count meets the configured hold. It re-arms when the count
/// changes or the hand goes. Like claps, a hand seen during a voice interaction fires
/// nothing: the camera is idled for the turn's span on the motion side,
/// and a report still crossing at its start is ignored here.
///
/// A plugin can be a trigger too (issue #888): a [PluginTriggerFired] runs
/// every mapping bound to that plugin's trigger. Lockdown Mode and Disable
/// Gestures silence it like the rest. A voice turn does not, because what
/// the plugin noticed (a hardware key, say) is no accident of speech.
class GesturesManager extends Manager {
  GesturesManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    Stream<Uint8List> Function()? micStream,
    Future<PermissionOutcome> Function()? micPermission,
    this.handClock,
  }) : _micStream = micStream ?? (() => MicHub.instance.stream()),
       _micPermission =
           micPermission ?? (() => requestOsPermission(Permission.microphone));

  final SettingsManager _settings;
  final Stream<Uint8List> Function() _micStream;
  final Future<PermissionOutcome> Function() _micPermission;
  final Duration Function()? handClock;

  /// The kiosk's own device in Home Assistant, which the Home Assistant
  /// actions pass on as [deviceVariable] (issue #1259), with the name as
  /// [nameVariable]. Wired by the
  /// composition root. Null, or answering null, leaves it out.
  Future<String?> Function()? kioskDeviceId;

  /// The same name the scripts the realtime voice runs get it under, so
  /// one script serves both.
  static const deviceVariable = McpClient.scriptDeviceArgument;

  /// The kiosk's Device name, which the actions pass on next to
  /// [deviceVariable]. Known without Home Assistant.
  static const nameVariable = McpClient.scriptNameArgument;

  /// What stands for each variable in the data of a Call a service
  /// action, with why it can be unknown. They cannot ride along on their
  /// own there, since many services refuse keys they do not know.
  static const placeholders = {
    '{$deviceVariable}': 'turn on ESPHome and add the kiosk to Home Assistant',
    '{$nameVariable}': 'set the Device name',
  };

  final _handStopwatch = Stopwatch()..start();
  final _handHold = HandGestureHold();

  StreamSubscription<GestureDetected>? _sub;
  StreamSubscription<PalmDetected>? _palmSub;
  StreamSubscription<PluginTriggerFired>? _pluginSub;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<SettingChanged>? _settingsSub;
  StreamSubscription<WakeWordStateChanged>? _wakeStateSub;
  StreamSubscription<ScreenStateChanged>? _screenSub;

  /// Finger mappings that fired for the count being shown.
  final _palmFired = <String>{};
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
    _palmSub = bus.on<PalmDetected>().listen(_onPalms);
    _pluginSub = bus.on<PluginTriggerFired>().listen(_onPluginTrigger);

    commands.register(
      Command(
        name: 'pluginOpenKioskLink',
        description:
            'Run a ks:// link for a plugin, as a dashboard would (issue '
            '#1213). Fails in Lockdown Mode and for the links that open '
            'Android Settings or call a kiosk.',
        params: const {'url': 'ks:// link, e.g. ks://alarms'},
        handler: (p) async => runPluginKioskLink('${p['url'] ?? ''}'),
      ),
    );

    _settingsSub = bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.gestureMappings.key ||
          e.key == defs.handGestureHoldSeconds.key ||
          e.key == defs.cameraEnabled.key ||
          e.key == defs.lockdownEnabled.key ||
          e.key == defs.kioskEnabled.key ||
          e.key == defs.kioskDisableGestures.key) {
        _resetHand();
      }
      if (e.key == defs.gestureMappings.key ||
          e.key == defs.clapStrictness.key ||
          e.key == defs.lockdownEnabled.key ||
          e.key == defs.kioskEnabled.key ||
          e.key == defs.kioskDisableGestures.key) {
        _micPrompted = false; // a changed gate is permission to ask again
        _syncClapper();
      }
    });

    _wakeStateSub = bus.on<WakeWordStateChanged>().listen((e) {
      final startedTurn = !e.active && !_voiceTurn;
      _voiceTurn = !e.active;
      if (startedTurn) _resetHand();
      // The turn's audio must not linger as half a clap sequence, and the
      // world after TTS played is acoustically new — start clean.
      if (startedTurn) _detector.reset();
      if (e.muted != _wakeMuted) {
        _wakeMuted = e.muted;
        _syncClapper();
      }
    });

    _screenSub = bus.on<ScreenStateChanged>().listen((e) {
      if (!e.on) _resetHand();
    });

    await _syncClapper();
  }

  @override
  Future<void> dispose() async {
    _micRetry?.cancel();
    await _settingsSub?.cancel();
    await _wakeStateSub?.cancel();
    await _screenSub?.cancel();
    _resetHand();
    await _micSub?.cancel();
    await _palmSub?.cancel();
    await _pluginSub?.cancel();
    await _sub?.cancel();
  }

  /// Whether the non-touch triggers are armed at all: Lockdown Mode and
  /// kiosk mode's Disable Gestures silence them like the touch ones.
  bool get _armed =>
      !_settings.get(defs.lockdownEnabled) &&
      !(_settings.get(defs.kioskEnabled) &&
          _settings.get(defs.kioskDisableGestures));

  void _resetHand() {
    _handHold.reset();
    _palmFired.clear();
  }

  /// A hold can finish only on a fresh matching camera report.
  void _onPalms(PalmDetected e) {
    if (!_armed || _voiceTurn) {
      _resetHand();
      return;
    }
    final previousCount = _handHold.count;
    final ready = _handHold.update(
      hands: e.hands,
      fingers: e.fingers,
      now: handClock?.call() ?? _handStopwatch.elapsed,
      hold: Duration(
        milliseconds: (_settings.get(defs.handGestureHoldSeconds) * 1000)
            .round(),
      ),
    );
    if (_handHold.count != previousCount) _palmFired.clear();
    final mappings = decodeGestureMappings(_settings.get(defs.gestureMappings));
    for (final m in mappings) {
      if (m.triggerType != 'fingers') continue;
      final wanted = (m.trigger['fingers'] as num?)?.toInt() ?? 5;
      if (ready && _handHold.count == wanted) {
        if (_palmFired.add(m.id)) {
          log.info(name, 'detected a hand showing $wanted finger(s)');
          bus.publish(GestureDetected(id: m.id));
        }
      }
    }
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
    final strictness = _settings.get(defs.clapStrictness);
    _detector.strict = strictness == 'strict';
    _detector.largeRoom = strictness == 'large_room';
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

  void _onPluginTrigger(PluginTriggerFired e) {
    if (!_armed) return;
    final mappings = decodeGestureMappings(_settings.get(defs.gestureMappings));
    for (final m in mappings) {
      if (m.triggerType == 'plugin' &&
          m.trigger['pluginId'] == e.pluginId &&
          m.trigger['trigger'] == e.trigger) {
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

  /// Run the action a user chose in a plugin's action setting, when the
  /// plugin asks for it (issue #1165). Lockdown Mode refuses it. Disable
  /// Gestures does not, since the plugin runs it from a control of its own,
  /// such as a navigation bar button, not from a gesture.
  Future<CommandResult> runPluginSettingAction(
    Map<String, Object?> action,
  ) async {
    if (_settings.get(defs.lockdownEnabled)) {
      return const CommandResult.fail('Lockdown Mode is on');
    }
    log.info(name, 'plugin setting: ${describeGestureAction(action)}');
    return runGestureAction(action);
  }

  /// Run a ks:// link a plugin names (issue #1213), so a plugin reaches
  /// every screen a dashboard link does without a control of its own for
  /// each. Lockdown Mode refuses it, as it does a plugin's action setting.
  /// Android Settings is left out because it is a way out of the kiosk, and
  /// launchApp holds plugins to the App Launcher's apps for the same
  /// reason. Calling a kiosk is left out because a kiosk can answer on its
  /// own, which opens its microphone.
  Future<CommandResult> runPluginKioskLink(String url) async {
    final action = kioskLinkAction(url);
    if (action == null) return const CommandResult.fail('unknown kiosk link');
    if (const {'android_settings', 'intercom_call'}.contains(action['type'])) {
      return const CommandResult.fail('plugins cannot open this link');
    }
    if (_settings.get(defs.lockdownEnabled)) {
      return const CommandResult.fail('Lockdown Mode is on');
    }
    log.info(name, 'plugin link: $url');
    return runGestureAction(action);
  }

  /// Run one action object. Public so the editors' "Try it" affordances
  /// (device and remote) can exercise an action without a gesture.
  Future<CommandResult> runGestureAction(Map<String, Object?> action) async {
    final a = action;
    switch ('${a['type']}') {
      case 'plugin_action':
        return _runHa(a, 'runPluginCommand', {
          'id': a['pluginId'],
          'command': a['command'],
        });
      case 'navigate':
        return _run('haNavigate', {'path': a['path']});
      case 'url':
        return _run('showLinkPage', {'url': a['url']});
      case 'refresh':
        // The plain pull's reload (issue #983), for a dashboard where the
        // pull itself is turned off because a card such as a map takes
        // downward drags.
        return _run('reload', const {});
      case 'camera_view':
        if (a['mode'] == 'hide') {
          return _run('hideCameraView', const {});
        } else {
          // toggle: the same gesture performed again closes the view it
          // opened, which is what a repeated clap sequence should mean.
          return _run('showCameraView', {
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
        return const CommandResult.ok();
      case 'now_playing':
        return _run('showNowPlaying', const {});
      case 'music_assistant':
        return _run('showMusicAssistant', const {});
      case 'media_play_pause':
        // A toggle, so one gesture covers both (issue #843): it goes to
        // the player Now Playing shows, the followed one when one is
        // picked, and the music stopping or starting is the confirmation.
        return _run('sendspinControl', const {'command': 'toggle'});
      case 'app_launcher':
        // Open only: the overlay's close button and its scrim already close
        // it. The command carries the launcher's own gates (master switch
        // off or no apps picked refuse with a reason), so a mapping left
        // behind after the launcher is turned off logs instead of showing
        // an empty grid; the drawer entry's Allowed Action is deliberately
        // NOT consulted, which is what makes a secret gesture possible.
        return _run('showAppLauncher', const {});
      case 'intercom_call':
        // Rings the kiosk picked when the gesture was set up. The command
        // carries the intercom's gates, and a kiosk that is off or on
        // Do not disturb ends the call with the reason on the card.
        return _run('intercomCall', {'id': a['kioskId'] ?? ''});
      case 'intercom_open':
        // Open only: the sheet closes on its own. The command carries the
        // intercom's gates (off, or no remote admin), so a mapping left
        // behind logs instead of showing an empty sheet; the kiosk menu's
        // Allowed Action is not consulted, which makes a secret gesture
        // possible.
        return _run('intercomOpen', const {});
      case 'intercom_hangup':
        // The hang up button's path: ends a call being placed, a live
        // call or an announcement, so a call can end from across the room
        // with claps or a hand. A ringing call is left to Accept and
        // Decline, and with no call the gesture does nothing.
        bus.publish(const IntercomHangupRequested());
        return const CommandResult.ok();
      case 'intercom_answer':
        // The Answer and Decline buttons' paths (issue #991), so a kiosk
        // without a usable screen can take a call. With nothing ringing
        // the command refuses and the gesture does nothing.
        return _run('intercomAnswer', const {});
      case 'intercom_decline':
        return _run('intercomDecline', const {});
      case 'alarm_stop':
        // The Stop button's path (issue #872): ends a ring, a snooze or a
        // sunrise, so claps or a hand can silence an alarm from bed.
        return _run('alarmStop', const {'source': 'gesture'});
      case 'alarm_snooze':
        // The Snooze button's path: only a ringing alarm snoozes.
        return _run('alarmSnooze', const {'source': 'gesture'});
      case 'voice_wake':
        // The wake word without the word, for a button or claps.
        return _run('voiceWake', const {});
      case 'voice_stop':
        // The stop word's job: a ringing timer first, then the turn.
        return _run('voiceCancel', const {});
      case 'voice_mute':
        // A toggle, so one gesture covers both; the setting is the state.
        return _run('setWakeWordMuted', {
          'muted': !_settings.get(defs.voiceMute),
        });
      case 'screensaver':
        return _run('startScreensaver', const {});
      case 'screensaver_stop':
        // Redundant for touch (any tap dismisses), real for claps: hands
        // full across the room, the screen comes back without walking over.
        return _run('stopScreensaver', const {});
      case 'hold_mode':
        // Toggle, not set: the same gesture pins the recipe and, performed
        // again, releases it (issue #266). The setting IS the state, so
        // every other surface follows.
        await _settings.set(defs.haHoldMode, !_settings.get(defs.haHoldMode));
        return const CommandResult.ok();
      case 'ha_kiosk':
        // The same toggle as the drawer row (issue #422): the setting is
        // the state, the kiosk screen restyles the page as it changes.
        // Deliberately not behind the drawer's Allowed Action, so the
        // header can come back on a secret gesture while the menu row
        // stays hidden.
        await _settings.set(defs.haKioskMode, !_settings.get(defs.haKioskMode));
        return const CommandResult.ok();
      case 'launch_app':
        return _run('launchApp', {'package': a['package']});
      case 'open_uri':
        return _run('openUri', {'uri': a['uri']});
      case 'android_settings':
        return _run('openSystemSettings', const {});
      case 'alarms':
        // Open only: the list's own close button hides it. Not behind the
        // kiosk menu's Show in the kiosk menu or Allowed Action switches,
        // the same as the other links.
        return _run('openAlarms', const {});
      case 'alarm_next':
        // The alarm that rings next on its details page, or the list when
        // none is set.
        return _run('openAlarms', const {'alarm': 'next'});
      case 'calendar':
        // Opened by a ks://calendar link, on its view when the link names
        // one. Like the alarm list, not behind the kiosk menu's switches.
        return _run('openCalendar', {
          if (a['view'] is String) 'view': a['view'],
        });
      case 'music_library':
        // Like the calendar, not behind the kiosk menu's switches. It
        // fails with nothing to browse: no source is set up.
        return _run('openMusicLibrary', const {});
      case 'ha_script':
      case 'ha_automation':
        // Both take variables: script.turn_on as the script's, and
        // automation.trigger as the run's, next to trigger.
        final script = a['type'] == 'ha_script';
        final plain = {
          'domain': script ? 'script' : 'automation',
          'service': script ? 'turn_on' : 'trigger',
          'entity_id': a['entityId'],
        };
        final identity = await _identity();
        if (identity.isEmpty) return _runHa(a, 'haCallService', plain);
        return _runHa(a, 'haCallService', {
          ...plain,
          'data': {'variables': identity},
        }, plain: plain);
      case 'ha_service':
        final data = a['data'];
        Map<String, String>? identity;
        if (data is Map) {
          final used = [
            for (final p in placeholders.keys)
              if (_mentions(data, p)) p,
          ];
          if (used.isNotEmpty) identity = await _identity();
          for (final p in used) {
            if (!identity!.containsKey(p.substring(1, p.length - 1))) {
              return _reportHa(
                a,
                CommandResult.fail('$p is unknown: ${placeholders[p]}'),
              );
            }
          }
        }
        return _runHa(a, 'haCallService', {
          'domain': a['domain'],
          'service': a['service'],
          if ('${a['entityId'] ?? ''}'.isNotEmpty) 'entity_id': a['entityId'],
          if (data is Map)
            'data': identity == null ? data : _fill(data, identity),
        });
      case 'ha_event':
        final data = {
          if (a['data'] case final Map configured) ...configured,
          ...await _identity(),
        };
        return _runHa(a, 'haFireEvent', {
          'event': a['event'],
          if (data.isNotEmpty) 'data': data,
        });
      default:
        log.warn(name, 'unknown gesture action: ${a['type']}');
        return CommandResult.fail('unknown action ${a['type']}');
    }
  }

  Future<CommandResult> _run(
    String command,
    Map<String, Object?> params,
  ) async {
    final result = await commands.execute(command, params);
    if (!result.ok) log.warn(name, '$command failed: ${result.error}');
    return result;
  }

  /// [_run] for the Home Assistant actions, which show nothing on screen
  /// by themselves: the outcome goes out on the bus for the kiosk screen
  /// to confirm with a toast, or to say why the call failed. A Home
  /// Assistant that refuses the variables gets the call again as [plain].
  Future<CommandResult> _runHa(
    Map<String, Object?> action,
    String command,
    Map<String, Object?> params, {
    Map<String, Object?>? plain,
  }) async {
    var result = await commands.execute(command, params);
    if (!result.ok &&
        plain != null &&
        '${result.error}'.contains('extra keys not allowed')) {
      // Refused before it ran, so it never runs twice.
      result = await commands.execute(command, plain);
    }
    if (!result.ok) log.warn(name, '$command failed: ${result.error}');
    return _reportHa(action, result);
  }

  CommandResult _reportHa(Map<String, Object?> action, CommandResult result) {
    bus.publish(
      GestureActionCompleted(
        action: action,
        ok: result.ok,
        error: result.error,
      ),
    );
    return result;
  }

  Future<String?> _device() async {
    try {
      final device = await kioskDeviceId?.call();
      return device == null || device.isEmpty ? null : device;
    } catch (e) {
      // The action still runs, only without the kiosk's device.
      log.debug(name, 'kiosk device unknown: $e');
      return null;
    }
  }

  /// What the Home Assistant actions tell it about the kiosk, each
  /// variable left out while unknown.
  Future<Map<String, String>> _identity() async {
    final kioskName = _settings.get(defs.deviceName).trim();
    return {
      deviceVariable: ?await _device(),
      if (kioskName.isNotEmpty) nameVariable: kioskName,
    };
  }

  /// Whether [value] holds [placeholder] in any of its strings.
  static bool _mentions(Object? value, String placeholder) => switch (value) {
    final String s => s.contains(placeholder),
    final Map m => m.values.any((v) => _mentions(v, placeholder)),
    final List l => l.any((v) => _mentions(v, placeholder)),
    _ => false,
  };

  /// [value] with each placeholder replaced by its variable in [identity].
  static Object? _fill(Object? value, Map<String, String> identity) =>
      switch (value) {
        final String s => identity.entries.fold<String>(
          s,
          (text, e) => text.replaceAll('{${e.key}}', e.value),
        ),
        final Map m => {
          for (final e in m.entries) e.key: _fill(e.value, identity),
        },
        final List l => [for (final v in l) _fill(v, identity)],
        _ => value,
      };
}
