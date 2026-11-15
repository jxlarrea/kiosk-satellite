import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../../core/permissions.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'mic_hub.dart';
import 'mic_level_monitor.dart';

/// How loud the room is, as one number (issue #910): the Ambient noise
/// sensor in Home Assistant and getNoiseLevel / audio.noise for plugins, so
/// the kiosk can answer quietly at night and louder over the TV.
///
/// It is a level and nothing more. The figure is the mean power of the
/// capture over [window], rounded to whole dBFS. It moves only by [step]
/// or more. It comes off the capture the wake word engine already holds
/// ([MicHub.tap]), so measuring alone never opens the microphone. With
/// wake word detection off or muted there is nothing to report.
///
/// Adaptive volume needs the level whether or not Voice Satellite is in
/// use (issue #1450). While its switch is on this manager holds the shared
/// capture open itself, the way clap detection does on a device with no
/// wake word: it asks for the microphone if nobody has, and the capture
/// closes again with the switch. A muted satellite stays closed: someone
/// who mutes the device expects it to stop listening, for a level too.
///
/// It holds its last value while a voice turn or another interaction runs
/// (speech must not show up in it) and while the kiosk plays its own sound,
/// which it would otherwise measure. A window the kiosk played into is
/// thrown away, its echo tail included. A player the echo canceller has no
/// tap on (DLNA) says so on the bus and holds the level the same way.
class NoiseLevelManager extends Manager {
  NoiseLevelManager(
    super.bus,
    super.commands,
    super.log, {
    this.settings,
    @visibleForTesting Stream<Uint8List> Function()? tap,
    @visibleForTesting Stream<Uint8List> Function()? micStream,
    @visibleForTesting Future<PermissionOutcome> Function()? micPermission,
    @visibleForTesting Future<bool> Function(Duration within)? playedWithin,
    @visibleForTesting DateTime Function()? now,
  }) : _tap = tap ?? (() => MicHub.instance.tap()),
       _micStream = micStream ?? (() => MicHub.instance.stream()),
       _micPermission =
           micPermission ?? (() => requestOsPermission(Permission.microphone)),
       _playedWithin = playedWithin ?? _nativePlayedWithin,
       _now = now ?? DateTime.now;

  /// Null in tests that only measure: nothing then asks for a hold.
  final SettingsManager? settings;
  final Stream<Uint8List> Function() _tap;
  final Stream<Uint8List> Function() _micStream;
  final Future<PermissionOutcome> Function() _micPermission;
  final Future<bool> Function(Duration within) _playedWithin;
  final DateTime Function() _now;

  @override
  String get name => 'noise_level';

  /// How long each reading averages over.
  static const window = Duration(seconds: 5);

  /// The smallest move the sensor and plugins hear about.
  static const step = 2;

  /// What a silent capture reads: the bottom of 16-bit audio.
  static const floorDbfs = -96;

  /// How long a sound still echoes after the kiosk stops playing it, the
  /// capture watchdog's playback tail.
  static const _echoTail = Duration(seconds: 2);

  static const _channel = MethodChannel('kiosk_satellite/audio_routing');

  static Future<bool> _nativePlayedWithin(Duration within) async {
    try {
      return await _channel.invokeMethod<bool>('playedWithin', {
            'ms': within.inMilliseconds,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  final _subs = <StreamSubscription<Object?>>[];

  bool _wakeActive = true;
  bool _wakeListening = false;

  /// Voice Satellite muted the satellite.
  bool _wakeMuted = false;

  /// This manager's own hold on the shared capture, while adaptive volume
  /// is on. Its chunks arrive over the tap like anyone else's.
  StreamSubscription<Uint8List>? _micSub;
  PermissionOutcome? _micOutcome;
  bool _micPrompted = false;
  Timer? _micRetry;

  /// The interactions running now, by reason: voice turns, announcements,
  /// timers, alarms, media and intercom calls all hold the level.
  final _interactions = <String>{};

  /// The players without an echo tap that are playing now, by source, and
  /// when the last one stopped: its sound still echoes for [_echoTail].
  final _untapped = <String>{};
  DateTime? _untappedEnded;

  DateTime? _windowStart;
  double _power = 0;
  int _chunks = 0;

  /// Bumped whenever the window is thrown away, so a reading still waiting
  /// on the playback check is dropped too.
  int _generation = 0;

  int? _dbfs;
  bool _held = false;
  DateTime? _updated;
  (bool, int?, bool)? _sent;

  /// Detection paused for a voice turn or another interaction running, or
  /// a player without an echo tap playing.
  bool get _busy =>
      !_wakeActive || _interactions.isNotEmpty || _untapped.isNotEmpty;

  /// Someone holds the capture open: the wake word engine or this manager.
  bool get _capturing => _wakeListening || _micSub != null;

  bool get _sampling => _capturing && !_busy;

  /// A level is listening now or held through an interaction.
  bool get available => _capturing || (!_wakeActive && _dbfs != null);

  /// Whether this manager should hold the capture open itself.
  bool get _holdWanted =>
      (settings?.get(defs.adaptiveVolume) ?? false) && !_wakeMuted;

  bool get held => available && (_busy || _held);

  int? get dbfs => available ? _dbfs : null;

  Map<String, Object?> describe() => {
    'available': available,
    'dbfs': dbfs,
    'held': held,
    'updated': available ? _updated?.toUtc().toIso8601String() : null,
  };

  @override
  Future<void> init() async {
    final wake = await commands.execute('getWakeWordState', const {});
    if (wake.ok && wake.data is Map) {
      final state = wake.data as Map;
      _wakeActive = state['active'] != false;
      _wakeListening = state['listening'] == true;
      _wakeMuted = state['muted'] == true;
    }
    _subs
      ..add(
        bus.on<WakeWordStateChanged>().listen((e) {
          _wakeActive = e.active;
          _wakeListening = e.listening;
          final muted = e.muted != _wakeMuted;
          _wakeMuted = e.muted;
          _sync();
          if (muted) unawaited(_syncHold());
        }),
      )
      ..add(
        bus.on<SettingChanged>().listen((e) {
          if (e.key != defs.adaptiveVolume.key) return;
          // A switch turned on again asks for the microphone again.
          _micPrompted = false;
          unawaited(_syncHold());
        }),
      )
      ..add(
        bus.on<VoiceInteractionChanged>().listen((e) {
          if (e.active) {
            _interactions.add(e.reason);
          } else {
            _interactions.remove(e.reason);
          }
          _sync();
        }),
      )
      ..add(
        bus.on<UntappedPlaybackChanged>().listen((e) {
          if (e.playing) {
            _untapped.add(e.source);
          } else if (_untapped.remove(e.source) && _untapped.isEmpty) {
            _untappedEnded = _now();
          }
          _sync();
        }),
      )
      ..add(_tap().listen(_onChunk, onError: (Object _) {}));
    commands.register(
      Command(
        name: 'getNoiseLevel',
        description:
            'How loud the room is: whole dBFS averaged over 5 seconds, '
            'held through voice turns and the kiosk\'s own sounds. '
            'Unavailable while neither wake word detection nor adaptive '
            'volume has the microphone open.',
        handler: (_) async => CommandResult.ok(describe()),
      ),
    );
    _sync();
    unawaited(_syncHold());
  }

  /// Bring this manager's hold on the capture in line with the adaptive
  /// volume switch and the mute.
  Future<void> _syncHold() async {
    final wanted = _holdWanted;
    if (wanted && _micSub == null) {
      // With wake word detection running the grant exists and this returns
      // at once. On a device without it nobody else has asked.
      if (_micOutcome != PermissionOutcome.granted) {
        if (_micPrompted) return; // already declined for this switch
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
            'adaptive volume needs the microphone and it was '
            '${_micOutcome == PermissionOutcome.blocked ? 'blocked: allow it in the app settings' : 'declined'}',
          );
          return;
        }
      }
      if (!_holdWanted || _micSub != null) return; // changed while asking
      _micSub = _micStream().listen((_) {}, onError: _onMicError);
      log.info(name, 'holding the microphone open for adaptive volume');
      _sync();
    } else if (!wanted && _micSub != null) {
      final sub = _micSub;
      _micSub = null;
      _micRetry?.cancel();
      await sub?.cancel();
      log.info(name, 'no longer holding the microphone open');
      _sync();
    }
  }

  /// The capture failed under the hold. The likeliest causes resolve
  /// themselves (the audio server restarting, a USB microphone replugged),
  /// so try again on a timer.
  void _onMicError(Object e) {
    log.warn(name, 'lost the microphone: $e');
    _micSub?.cancel();
    _micSub = null;
    _sync();
    _micRetry?.cancel();
    _micRetry = Timer(const Duration(seconds: 30), _syncHold);
  }

  void _sync() {
    if (!_sampling) _discard();
    // Still held once the interaction ends, until a clean window replaces
    // the value: the first one after an answer usually carries its echo.
    if (_busy) _held = true;
    if (!available) {
      _dbfs = null;
      _held = false;
      _updated = null;
    }
    _publish();
  }

  void _discard() {
    _generation++;
    _windowStart = null;
    _power = 0;
    _chunks = 0;
  }

  void _onChunk(Uint8List chunk) {
    if (!_sampling) return;
    final now = _now();
    final start = _windowStart ??= now;
    final rms = MicLevelMonitor.rmsOf(chunk);
    _power += rms * rms;
    _chunks++;
    final span = now.difference(start);
    if (span < window) return;
    final power = _power / _chunks;
    final generation = _generation;
    _windowStart = null;
    _power = 0;
    _chunks = 0;
    unawaited(_close(power, span, generation));
  }

  Future<void> _close(double power, Duration span, int generation) async {
    final ended = _untappedEnded;
    final played =
        await _playedWithin(span + _echoTail) ||
        (ended != null && _now().difference(ended) < span + _echoTail);
    if (generation != _generation || !_sampling) return;
    if (played) {
      _held = true;
    } else {
      _held = false;
      _dbfs = dbfsOf(power);
      _updated = _now();
      bus.publish(NoiseWindowMeasured(dbOf(power)));
    }
    _publish();
  }

  /// Mean power (RMS squared, full scale 1) as whole dBFS.
  static int dbfsOf(double power) => dbOf(power).round();

  /// Mean power as dBFS, before rounding.
  static double dbOf(double power) {
    if (power <= 0) return floorDbfs.toDouble();
    final db = 10 * math.log(power) / math.ln10;
    return db.clamp(floorDbfs.toDouble(), 0.0);
  }

  void _publish() {
    final next = (available, dbfs, held);
    final sent = _sent;
    if (sent != null && sent.$1 == next.$1 && sent.$3 == next.$3) {
      final was = sent.$2;
      final now = next.$2;
      if (was == now) return;
      if (was != null && now != null && (was - now).abs() < step) return;
    }
    _sent = next;
    bus.publish(
      NoiseLevelChanged(available: next.$1, dbfs: next.$2, held: next.$3),
    );
  }

  @override
  Future<void> dispose() async {
    _micRetry?.cancel();
    await _micSub?.cancel();
    _micSub = null;
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
  }
}
