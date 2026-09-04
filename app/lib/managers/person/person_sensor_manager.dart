import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// Whether this device has a person sensor of its own, from the native
/// bridge. Today that means a Meta Portal with its presence service in
/// place (the `com.facebook.alohaservices.presence` package, installed and
/// enabled). Unknown counts as supported so a missing bridge (tests) never
/// hides the page on a device that has one.
class PersonSensorSupport {
  const PersonSensorSupport({required this.supported, this.hint});

  static const unknown = PersonSensorSupport(supported: true);

  final bool supported;

  /// Why [supported] is false, in a sentence fit for a settings row.
  final String? hint;

  Map<String, Object?> toJson() => {
    'supported': supported,
    if (hint != null) 'hint': hint,
  };
}

/// The state of the `READ_LOGS` grant, which is what lets the app read
/// another process's log lines. Android only gives it over adb
/// (`pm grant`), and a grant lands in the package manager at once but
/// reaches a running process only at its next start: the `log` group is
/// handed out when the process is forked. [granted] is the package
/// manager's answer, [effective] whether this process actually has it.
class LogAccess {
  const LogAccess({required this.granted, required this.effective});

  static const none = LogAccess(granted: false, effective: false);

  final bool granted;
  final bool effective;

  Map<String, Object?> toJson() => {'granted': granted, 'effective': effective};
}

/// Person detection from a sensor the device itself runs (discussion
/// #353). One backend today, the Meta Portal's, described below; another
/// device with a comparable always-on detector would plug in here.
///
/// Portal OS runs its own people detector all the time, on a virtual
/// camera feed that never lights the camera LED (it is what the Smart
/// Camera's auto-framing uses), and its `PresenceManager` logs a heartbeat
/// about every 30 seconds while someone is in view, going silent when the
/// room empties. There is no interface a sideloaded app may call for it:
/// the state provider and the transition broadcasts sit behind
/// signature-level permissions. The log is the one door, and `READ_LOGS`
/// the one grant, so this tails `logcat` filtered to the two tags and
/// treats the heartbeat's liveness as presence: a beat within [absentAfter]
/// is someone there, longer than that is the room empty.
///
/// Every fresh beat is published as [PersonDetected], which the
/// screensaver consumes for Dismiss on person and Postpone on person the
/// way it consumes proximity, and while someone stays a [PersonDetected]
/// goes out every [holdInterval] on top, so the postpone leg holds the
/// idle clock continuously. The state itself goes out as
/// [PersonSensorChanged] for the settings rows.
///
/// Lines are classified by their message rather than counted blindly: the
/// same tags carry camera-arbitration and lifecycle chatter (an Ava port
/// stuck at Detected over it), so only messages naming presence count, an
/// explicit negative clears the beat, lifecycle words are ignored, and
/// only the rest arm it. On a
/// Portal Go the beat is three lines, `Notify people presence`,
/// `onNotifyPresence presence updated [APPLICATION]` and
/// `onNotifyPresence, awake`, thirty seconds apart to the second.
///
/// On every other device the page is hidden (its definitions are added to
/// [defs.deviceHiddenKeys] at boot) and the switches kept off in the
/// settings themselves, so a settings import or the remote API cannot
/// turn on a leg that has no sensor.
class PersonSensorManager extends Manager {
  PersonSensorManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    this.lineSource,
    DateTime Function()? now,
    this.checkInterval = const Duration(seconds: 10),
    this.holdInterval = const Duration(seconds: 2),
    this.retryFloor = const Duration(seconds: 5),
  }) : _now = now ?? DateTime.now;

  final SettingsManager _settings;

  /// The log line source; null spawns `logcat`. Injectable for tests
  /// only.
  final Stream<String> Function()? lineSource;

  /// The clock the beat ages are measured against. Injectable for tests
  /// only.
  final DateTime Function() _now;

  /// How often the newest beat is re-aged against [absentAfter].
  final Duration checkInterval;

  /// While someone is in view, a [PersonDetected] goes out this often on
  /// top of the beats themselves, so Postpone screensaver on person holds
  /// the idle clock continuously: presence is a state, and the 30 second
  /// beat alone cannot hold off an idle timeout shorter than that.
  final Duration holdInterval;

  /// The first re-attach delay after the tail ends; doubles per failure
  /// up to [_retryCeiling].
  final Duration retryFloor;
  static const _retryCeiling = Duration(seconds: 60);

  /// A tail that lived this long resets the re-attach backoff.
  static const _healthyAttach = Duration(seconds: 60);

  /// A beat older than this by its own timestamp is the backlog `logcat`
  /// dumps on attach, not someone in the room now.
  static const freshWithin = Duration(seconds: 45);

  /// Absent once the newest beat is older than this: one 30 second beat
  /// missed, plus margin.
  static const absentAfter = Duration(seconds: 50);

  /// A beat stamped this far in the future is a clock stepped back since
  /// boot, not a beat.
  static const _futureSkew = Duration(seconds: 5);

  /// The log tags followed. The first two carry the 30 second heartbeat.
  /// The framing director's are the Smart Camera's auto-framing deciding
  /// how to move the crop: tracking lines every second or two while it
  /// follows a person (an arrival registers on the first step rather than
  /// on the next heartbeat) and brake lines once a second while it has
  /// nobody to follow (an exit registers in seconds rather than after the
  /// heartbeat window). Everything else is filtered out by `logcat`
  /// itself.
  static const logTags = [
    'PresenceManager:I',
    'aloha.CameraServiceController:I',
    'aloha.TrackAndHoldAiDirectorDefaultNudgeMovement:I',
    'aloha.TrackAndHoldAiDirector:I',
  ];

  /// What the framing director says about a tracked person: the subject's
  /// box crossing the framing boundary, or its distance from the framing
  /// center. Either means someone is in view now. Its other lines (hold
  /// and reframe moves) happen on the way out as well, so they say
  /// nothing.
  static const _framingMarkers = [
    'boundaryviolated',
    'framingdistance',
    'fast track',
  ];

  /// The director braking to its default frame: it lost the person. Logged
  /// once a second for as long as the room stays empty, starting within a
  /// few seconds of someone leaving, so a short run of these is absence
  /// long before the heartbeat window runs out. Its hold and reframe lines
  /// happen on the way in and out alike and say nothing.
  static const _brakeMarker = 'brake';

  /// How long the director has to keep braking before the person counts as
  /// gone. Three consecutive lines: one stray line while someone stands
  /// still must not read as an exit, since the next tracking line would
  /// then read as an arrival and dismiss the screensaver.
  static const absentAfterBrake = Duration(seconds: 3);

  static const _channel = MethodChannel('kiosk_satellite/background');

  /// "Someone is there": always a beat.
  static const _positive = ['true', 'detected', 'found'];

  /// "Nobody there" or the engine going quiet: clears the beat at once.
  static const _negative = [
    'false',
    'absent',
    'not present',
    'no presence',
    'no face',
    'lost',
    'stop',
    'paus',
    'disabl',
    'clear',
    'idle',
    'away',
  ];

  /// Engine lifecycle and camera arbitration: says nothing either way.
  static const _lifecycle = [
    'start',
    'resum',
    'enable',
    'register',
    'unregister',
    'subscrib',
    'connect',
    'disconnect',
    'bind',
    'init',
    'creat',
    'destroy',
    'request',
  ];

  static final _numericFalse = RegExp(r'[=:]\s*0(?:\.0+)?(?![0-9.])');
  static final _numericTrue = RegExp(r'[=:]\s*1(?:\.0+)?(?![0-9.])');

  @override
  String get name => 'person';

  PersonSensorSupport? _support;
  LogAccess _access = LogAccess.none;

  bool get knownUnsupported => _support?.supported == false;

  /// Why the page is hidden, once known.
  String? get hint => _support?.hint;

  /// Whether the sensor should be read right now: Dismiss on person on,
  /// on a device that has one. The screensaver applies its own gates on the way out
  /// (lockdown, the postpone rule, the Now Playing gate), the same ones it
  /// applies to proximity.
  bool get wanted =>
      (_schedulePolicy ?? _settings.get(defs.screensaverDismissOnPerson)) &&
      !knownUnsupported;

  /// The active schedule entry's override (issue #437): true/false wins
  /// over the switch for the entry's hours, null between sessions and for
  /// entries without one.
  bool? _schedulePolicy;

  /// Whether the tail is attached.
  bool get running => _sub != null;

  /// Someone in view, per the newest beat.
  bool get present => _present;
  bool _present = false;

  /// When the newest live beat arrived, null before the first.
  DateTime? get lastBeat => _lastBeat;
  DateTime? _lastBeat;

  /// When the current run of brake lines began, null while the director
  /// is tracking someone or quiet.
  DateTime? _brakeSince;

  /// The newest beat line, for the status row and bug reports.
  String? get lastLine => _lastLine;
  String? _lastLine;

  /// Why the tail is not attached while it should be, null while it is or
  /// while nothing wants it.
  String? get error => _error;
  String? _error;

  /// The last state of the grant this manager read.
  LogAccess get logAccess => _access;

  StreamSubscription<String>? _sub;
  Timer? _check;
  Timer? _hold;
  Timer? _retry;
  Duration _retryDelay = Duration.zero;
  DateTime? _attachedAt;
  DateTime? _lastBeatLog;
  bool _warnedAccess = false;

  @override
  Future<void> init() async {
    // Hide the group everywhere but a Portal before any page renders. A
    // failed ask (no bridge) reads as supported and hides nothing, which
    // is the safe way round on a device that has one.
    final support = await sensorSupport();
    if (!support.supported) {
      defs.deviceHiddenKeys
        ..add(defs.screensaverDismissOnPerson.key)
        ..add(defs.screensaverPostponeOnPerson.key);
    }
    await _guardSupport();

    // The schedule's override, published at session start and on every
    // boundary crossing, cleared on stop: the tail attaches or detaches
    // to match, the way the camera does for motion.
    bus.on<ScreensaverMotionPolicyChanged>().listen((e) {
      _schedulePolicy = e.dismissOnPerson;
      _sync();
    });
    bus.on<SettingChanged>().listen((e) {
      if (e.key != defs.screensaverDismissOnPerson.key &&
          e.key != defs.screensaverPostponeOnPerson.key) {
        return;
      }
      if (knownUnsupported &&
          (_settings.get(defs.screensaverDismissOnPerson) ||
              _settings.get(defs.screensaverPostponeOnPerson))) {
        unawaited(_guardSupport());
        return;
      }
      _sync();
    });

    commands.register(
      Command(
        name: 'getPersonSensorSupport',
        description:
            'Whether this is a Meta Portal with its presence service in '
            'place, and why not when it is not',
        handler: (_) async =>
            CommandResult.ok((await sensorSupport()).toJson()),
      ),
    );
    commands.register(
      Command(
        name: 'getPersonSensor',
        description:
            "The device's person sensor: whether it is on and reading, the "
            'log access grant, the current presence and the last heartbeat',
        handler: (_) async {
          await refreshAccess();
          return CommandResult.ok(status());
        },
      ),
    );

    _sync();
  }

  /// The native answer, asked once. A failed or missing ask is not cached,
  /// so a bridge that was not ready gets asked again.
  Future<PersonSensorSupport> sensorSupport() async {
    if (_support case final known?) return known;
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'personSensorSupport',
      );
      if (raw == null) return PersonSensorSupport.unknown;
      return _support = PersonSensorSupport(
        supported: raw['supported'] != false,
        hint: raw['hint'] as String?,
      );
    } catch (_) {
      return PersonSensorSupport.unknown;
    }
  }

  /// Re-reads the grant from the platform. Cheap (a permission check and a
  /// look at this process's groups), so the status rows and the permission
  /// row ask on every paint.
  Future<LogAccess> refreshAccess() async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'readLogsState',
      );
      if (raw != null) {
        _access = LogAccess(
          granted: raw['granted'] == true,
          effective: raw['effective'] == true,
        );
      }
    } catch (_) {
      // No bridge: keep whatever was known.
    }
    return _access;
  }

  /// What the settings pages show under the switch.
  Map<String, Object?> status() => {
    'supported': !knownUnsupported,
    if (hint != null) 'hint': hint,
    'enabled': wanted,
    'running': running,
    'present': _present,
    if (_lastBeat != null) 'lastBeat': _lastBeat!.millisecondsSinceEpoch,
    if (_lastLine != null) 'lastLine': _lastLine,
    if (_error != null) 'error': _error,
    'logAccess': _access.toJson(),
  };

  /// Re-checks whether the tail should be attached: the permission row
  /// calls it after a grant, and a restart is what makes a grant
  /// effective, so this is mostly for the status to refresh at once.
  void sync() => _sync();

  /// Keeps the switches off where the device has no person sensor: at
  /// boot, and whenever something turns one on.
  Future<void> _guardSupport() async {
    final support = await sensorSupport();
    if (support.supported) return;
    final on = [
      if (_settings.get(defs.screensaverDismissOnPerson))
        defs.screensaverDismissOnPerson,
      if (_settings.get(defs.screensaverPostponeOnPerson))
        defs.screensaverPostponeOnPerson,
    ];
    if (on.isEmpty) return;
    for (final def in on) {
      await _settings.set(def, false);
    }
    final why = support.hint ?? 'Not available on this device.';
    log.warn(
      name,
      'Dismiss on person kept off: ${why[0].toLowerCase()}${why.substring(1)}',
    );
  }

  void _sync() {
    if (!wanted) {
      _stop();
      _error = null;
      _warnedAccess = false;
      _setPresent(false);
      return;
    }
    unawaited(_start());
  }

  Future<void> _start() async {
    if (_sub != null) return;
    _retry?.cancel();
    _retry = null;
    final access = await refreshAccess();
    if (_sub != null || !wanted) return;
    if (!access.effective) {
      _error = access.granted
          ? 'Log access is granted but takes effect when Kiosk Satellite '
                'restarts.'
          : 'Log access not granted.';
      if (!_warnedAccess) {
        _warnedAccess = true;
        log.warn(
          name,
          'presence heartbeat cannot be read: '
          '${_error![0].toLowerCase()}${_error!.substring(1)}',
        );
      }
      return;
    }
    _error = null;
    _warnedAccess = false;
    _attachedAt = _now();
    log.info(name, 'reading the presence heartbeat');
    _sub = (lineSource ?? _logcatLines)().listen(
      _onLine,
      onError: (Object e) {
        log.warn(name, 'presence tail failed: $e');
        _onEnded();
      },
      onDone: _onEnded,
    );
    _check?.cancel();
    _check = Timer.periodic(checkInterval, (_) => _evaluate());
  }

  /// The tail ended (logd restarted, the process was killed): re-attach
  /// with backoff while still wanted, rather than going deaf until the
  /// next toggle.
  void _onEnded() {
    final lived = _attachedAt == null
        ? Duration.zero
        : _now().difference(_attachedAt!);
    _teardown();
    if (!wanted) return;
    _retryDelay = lived >= _healthyAttach || _retryDelay == Duration.zero
        ? retryFloor
        : _retryDelay * 2;
    if (_retryDelay > _retryCeiling) _retryDelay = _retryCeiling;
    log.warn(
      name,
      'presence tail ended; re-attaching in ${_retryDelay.inSeconds}s',
    );
    _retry = Timer(_retryDelay, _sync);
  }

  void _onLine(String line) {
    final trimmed = line.trimLeft();
    final space = trimmed.indexOf(' ');
    if (space <= 0) return;
    final epoch = double.tryParse(trimmed.substring(0, space));
    if (epoch == null) return;
    final now = _now();
    final beat = DateTime.fromMillisecondsSinceEpoch((epoch * 1000).round());
    final age = now.difference(beat);
    if (age >= freshWithin || age < -_futureSkew) return;
    // The message after `Tag: `, never the whole line: the tag itself is
    // PresenceManager, so the whole line always contains the word, and
    // its camera-arbitration lines (`onCameraUnavailable [0]`, logged
    // whenever this app opens its own camera) would count as beats.
    final sep = trimmed.indexOf(': ');
    final lower = (sep < 0 ? trimmed : trimmed.substring(sep + 2))
        .toLowerCase();
    // The tag sits between the level letter and the colon.
    final head = sep < 0 ? '' : trimmed.substring(0, sep).toLowerCase();
    if (head.contains('trackandhold')) {
      if (_containsAny(lower, _framingMarkers)) {
        _beat(now, line);
      } else if (lower.contains(_brakeMarker)) {
        _brake(now);
      }
      return;
    }
    if (!lower.contains('presence')) return;
    if (_containsAny(lower, _positive) || _numericTrue.hasMatch(lower)) {
      _beat(now, line);
      return;
    }
    if (_containsAny(lower, _negative) || _numericFalse.hasMatch(lower)) {
      if (_lastBeat != null) log.debug(name, 'presence clear: ${line.trim()}');
      _lastBeat = null;
      _evaluate();
      return;
    }
    if (_containsAny(lower, _lifecycle)) return;
    _beat(now, line);
  }

  /// A brake line: the start of a run marks the time, a run that has
  /// lasted [absentAfterBrake] clears the presence. Someone leaving and
  /// coming straight back is then an arrival again, which Dismiss on
  /// person acts on, instead of one long stay.
  void _brake(DateTime now) {
    _brakeSince ??= now;
    if (!_present || now.difference(_brakeSince!) < absentAfterBrake) return;
    log.debug(name, 'framing director lost the person');
    _lastBeat = null;
    _evaluate();
  }

  void _beat(DateTime now, String line) {
    _brakeSince = null;
    // One echo of the matched line when presence begins and every five
    // minutes after, so a bug report shows what the firmware writes
    // without the log filling with heartbeats.
    if (_lastBeat == null ||
        _lastBeatLog == null ||
        now.difference(_lastBeatLog!) >= const Duration(minutes: 5)) {
      _lastBeatLog = now;
      log.info(name, 'presence beat: ${line.trim()}');
    }
    _lastBeat = now;
    _lastLine = line.trim();
    // A beat while already present is the person staying, not arriving:
    // held, so it feeds Postpone on person without dismissing a
    // screensaver that started with them in the room.
    final held = _present;
    _evaluate();
    bus.publish(PersonDetected(held: held));
  }

  void _evaluate() {
    final last = _lastBeat;
    _setPresent(last != null && _now().difference(last) < absentAfter);
  }

  void _setPresent(bool live) {
    if (live == _present) return;
    _present = live;
    log.info(name, live ? 'someone is in view' : 'nobody in view');
    _hold?.cancel();
    _hold = live
        ? Timer.periodic(holdInterval, (_) {
            if (!_present || _sub == null) return;
            bus.publish(const PersonDetected(held: true));
          })
        : null;
    bus.publish(PersonSensorChanged(present: live));
  }

  static bool _containsAny(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle)) return true;
    }
    return false;
  }

  /// The real line source: `logcat` following the two tags, with epoch
  /// timestamps so each line can be aged. The process is killed when the
  /// subscription is cancelled.
  Stream<String> _logcatLines() {
    Process? proc;
    late StreamController<String> controller;
    controller = StreamController<String>(
      onListen: () async {
        try {
          proc = await Process.start('logcat', [
            '-v',
            'epoch',
            '-s',
            ...logTags,
          ]);
        } catch (e) {
          controller.addError(e);
          await controller.close();
          return;
        }
        proc!.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              controller.add,
              onError: controller.addError,
              onDone: () async {
                if (!controller.isClosed) await controller.close();
              },
            );
        // logcat's own complaints (a missing grant reads as "Unable to
        // open log device") end up in the app log, not lost.
        proc!.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) => log.debug(name, 'logcat: $line'));
      },
      onCancel: () {
        proc?.kill();
        proc = null;
      },
    );
    return controller.stream;
  }

  void _teardown() {
    _check?.cancel();
    _check = null;
    _hold?.cancel();
    _hold = null;
    final sub = _sub;
    _sub = null;
    if (sub != null) unawaited(sub.cancel());
    _attachedAt = null;
  }

  void _stop() {
    _retry?.cancel();
    _retry = null;
    _retryDelay = Duration.zero;
    if (_sub == null) return;
    _teardown();
    _lastBeat = null;
    _brakeSince = null;
    log.info(name, 'presence heartbeat off');
  }

  @override
  Future<void> dispose() async {
    _stop();
  }
}
