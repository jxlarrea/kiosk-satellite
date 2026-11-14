import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// A countdown handed over by Voice Satellite. Times are epoch milliseconds.
class VoiceTimer {
  const VoiceTimer({
    required this.id,
    required this.name,
    required this.totalSeconds,
    required this.startedAt,
    required this.active,
    this.finished = false,
    this.duration = 0,
    this.source = '',
    this.sourceId = '',
    this.origin = '',
  });

  final String id;
  final String name;
  final int totalSeconds;
  final int startedAt;
  final bool active;
  final bool finished;

  /// The timer's whole length in seconds, what the progress bar measures
  /// against. Zero when the sender did not say, then [totalSeconds] stands
  /// in.
  final int duration;

  /// Empty for this kiosk's own timers, else `shared:<kiosk id>` for one
  /// another kiosk shares, with the id it has there in [sourceId] and that
  /// kiosk's name in [origin].
  final String source;
  final String sourceId;
  final String origin;

  bool get shared => source.isNotEmpty;

  /// The share of the timer still to run, 0 to 1.
  double progress(DateTime now) {
    final whole = duration > 0 ? duration : totalSeconds;
    if (whole <= 0) return 0;
    return (remaining(now) / whole).clamp(0.0, 1.0);
  }

  /// When it ends, for sorting: paused timers after the running ones.
  int endsAt(DateTime now) => active
      ? startedAt + totalSeconds * 1000
      : now.millisecondsSinceEpoch + totalSeconds * 1000 + 86400000 * 365;

  int remaining(DateTime now) => max(
    0,
    totalSeconds -
        (active ? max(0, (now.millisecondsSinceEpoch - startedAt) ~/ 1000) : 0),
  );

  static VoiceTimer? parse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final seconds = raw['totalSeconds'];
    final start = raw['startedAt'];
    if (id is! String ||
        id.isEmpty ||
        seconds is! num ||
        !seconds.isFinite ||
        seconds < 0 ||
        start is! num ||
        !start.isFinite) {
      return null;
    }
    return VoiceTimer(
      id: id,
      name: raw['name'] is String ? raw['name'] as String : '',
      totalSeconds: seconds.toInt(),
      startedAt: start.toInt(),
      active: raw['isActive'] != false,
      duration: raw['duration'] is num && (raw['duration'] as num).isFinite
          ? max(0, (raw['duration'] as num).toInt())
          : 0,
    );
  }
}

String voiceTimerTime(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

/// The full screen view's time: always hours, minutes and seconds.
String voiceTimerClock(int seconds) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(seconds ~/ 3600)}:${two((seconds % 3600) ~/ 60)}:'
      '${two(seconds % 60)}';
}

/// What one sharing kiosk last sent.
class _SharedSource {
  _SharedSource(this.name);
  String name;
  List<VoiceTimer> timers = const [];
  List<VoiceTimer> alerts = const [];
}

/// Owns timer presentation and alert audio from integration state updates.
class VoiceTimerManager extends Manager {
  VoiceTimerManager(
    super.bus,
    super.commands,
    super.log, {
    this.settings,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SettingsManager? settings;
  final DateTime Function() _clock;

  @override
  String get name => 'voice_timers';

  /// This kiosk's timers, then the ones other kiosks share.
  final timers = ValueNotifier<List<VoiceTimer>>(const []);
  final alerts = ValueNotifier<List<VoiceTimer>>(const []);

  /// The full screen timers view is up.
  final visible = ValueNotifier<bool>(false);

  /// True while Compass shows the view as the one in hand. Compass then
  /// decides when it goes, so it does not close itself once the last timer
  /// is gone.
  final compassView = ValueNotifier<bool>(false);

  /// How long this kiosk waits before the first chime of its own alert, so
  /// the kiosks it shares timers with can start theirs on the same beat.
  Duration ringLead = Duration.zero;

  /// When this kiosk's own alert sounds its first chime, epoch
  /// milliseconds, or null while none rings.
  int? get localRingAt => _localRingAt;
  int? _localRingAt;

  /// The spoken phrase of this kiosk's own alert, for the kiosks it shares
  /// with.
  String? get localSpeech => _localSpeech;
  String get localSpeechText => _localSpeechText;
  String? _localSpeech;
  String _localSpeechText = '';

  /// Fires when this kiosk's own alert, its ring time or its phrase change.
  final localAlertChanged = ValueNotifier<int>(0);

  /// The time between two beats of the ring.
  static const ringEvery = Duration(seconds: 3);

  List<VoiceTimer> _localTimers = const [];
  List<VoiceTimer> _localAlerts = const [];
  final _shared = <String, _SharedSource>{};
  String? _sharedSpeech;
  String _sharedSpeechText = '';
  Timer? _ringStart;
  Timer? _closeTimer;
  bool _autoOpened = false;
  Set<String> _knownIds = const {};
  StreamSubscription<SharedTimerDismissRequested>? _dismissSub;
  StreamSubscription<ScreensaverStateChanged>? _saverSub;

  /// The alert rings and is dismissed as usual but shows no pill (native
  /// Voice Satellite with Show finished timer pills off).
  final alertHidden = ValueNotifier<bool>(false);
  bool _muted = false;
  Timer? _ring;
  String? _soundId;
  int _soundGeneration = 0;
  bool _playing = false;
  Completer<void>? _soundDone;

  /// A spoken phrase for the ringing alert (native Voice Satellite's "Speak
  /// when a timer ends"): the ring goes chime, chime, phrase, and again.
  String? _speech;
  String _speechText = '';
  int _rings = 0;
  final error = ValueNotifier<int>(0);
  String _entity = '';
  StreamSubscription<VoiceTimersCleared>? _clearSub;

  @override
  Future<void> init() async {
    _clearSub = bus.on<VoiceTimersCleared>().listen((_) {
      _clearLocalAlert();
      _entity = '';
      _localTimers = const [];
      _merge();
    });
    _dismissSub = bus.on<SharedTimerDismissRequested>().listen(
      (_) => dismissShared(),
    );
    // Opened by hand and left with nothing to show, the view gives way to
    // the screensaver, as the alarm list does. With a timer on it, it stays
    // over the screensaver the way the pills do. A Compass view stays
    // under it.
    _saverSub = bus.on<ScreensaverStateChanged>().listen((e) {
      if (e.active &&
          !compassView.value &&
          timers.value.isEmpty &&
          alerts.value.isEmpty) {
        visible.value = false;
      }
    });
    commands
      ..register(
        Command(
          name: 'openTimers',
          description: 'Open the full screen timers view on the kiosk.',
          handler: (_) async {
            _autoOpened = false;
            _closeTimer?.cancel();
            await commands.execute('screenOn', const {});
            await commands.execute('bringToFront', const {});
            visible.value = true;
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'hideTimers',
          description: 'Close the full screen timers view.',
          handler: (_) async {
            visible.value = false;
            return const CommandResult.ok();
          },
        ),
      );
    commands.register(
      Command(
        name: 'setVoiceTimers',
        description: 'Hand Voice Satellite countdown pills to the kiosk.',
        handler: (p) async {
          final entity = p['entityId'];
          final raw = p['timers'];
          if (entity is! String || entity.isEmpty || raw is! List) {
            return const CommandResult.fail('Invalid timer snapshot');
          }
          final parsed = raw.map(VoiceTimer.parse).toList();
          if (parsed.any((t) => t == null) ||
              parsed.map((t) => t!.id).toSet().length != parsed.length) {
            return const CommandResult.fail('Invalid timer snapshot');
          }
          _entity = entity;
          _localTimers = parsed.cast<VoiceTimer>();
          _merge();
          return const CommandResult.ok();
        },
      ),
    );
    commands.register(
      Command(
        name: 'setVoiceTimerAlert',
        description: 'Show or dismiss a local Voice Satellite timer alert.',
        handler: (p) async {
          final entity = p['entityId'];
          final raw = p['timers'];
          if (entity is! String || entity.isEmpty || raw is! List) {
            return const CommandResult.fail('Invalid timer alert');
          }
          final parsed = raw.map(VoiceTimer.parse).toList();
          if (parsed.any((t) => t == null) ||
              parsed.map((t) => t!.id).toSet().length != parsed.length) {
            return const CommandResult.fail('Invalid timer alert');
          }
          _entity = entity;
          if (raw.isEmpty) {
            _clearLocalAlert();
          } else {
            alertHidden.value = p['hidden'] == true;
            _localAlerts = [
              for (final timer in parsed.cast<VoiceTimer>())
                VoiceTimer(
                  id: timer.id,
                  name: timer.name,
                  totalSeconds: 0,
                  startedAt: 0,
                  active: false,
                  finished: true,
                ),
            ];
            final speech = p['speech'];
            _localSpeech = speech is String && speech.isNotEmpty
                ? speech
                : null;
            _localSpeechText = '${p['speechText'] ?? ''}';
            _localRingAt ??=
                _clock().millisecondsSinceEpoch + ringLead.inMilliseconds;
            _ringWith(muted: p['muted'] == true, at: _localRingAt!);
            localAlertChanged.value++;
          }
          return const CommandResult.ok();
        },
      ),
    );
    commands.register(
      Command(
        name: 'voiceTimerActionFailed',
        description: 'Report a failed timer action from Voice Satellite.',
        handler: (p) async {
          if (p['entityId'] == _entity) error.value++;
          return const CommandResult.ok();
        },
      ),
    );
  }

  void control(String id, String action) {
    final alert = alerts.value.where((t) => t.id == id).firstOrNull;
    if (alert != null) {
      if (alert.shared) {
        _dismissSource(alert.source);
      } else {
        _clearLocalAlert();
        bus.publish(
          VoiceTimerAction(entityId: _entity, id: id, action: 'dismiss'),
        );
      }
      return;
    }
    final timer = timers.value.where((t) => t.id == id).firstOrNull;
    if (timer == null || !{'pause', 'resume', 'cancel'}.contains(action)) {
      return;
    }
    bus.publish(
      timer.shared
          ? VoiceTimerAction(
              entityId: timer.source,
              id: timer.sourceId,
              action: action,
            )
          : VoiceTimerAction(entityId: _entity, id: id, action: action),
    );
  }

  /// Puts what the kiosk [originId] shares on this one: its running and
  /// paused timers and the ones ringing there. [ringAt] is when its ring
  /// started, on this kiosk's clock, so this one chimes on the same beat.
  /// Empty lists take the kiosk off again.
  void setShared(
    String originId, {
    required String name,
    required List<VoiceTimer> timers,
    required List<VoiceTimer> alerts,
    int? ringAt,
    bool muted = false,
    bool hidden = false,
    String? speech,
    String speechText = '',
  }) {
    final source = 'shared:$originId';
    VoiceTimer own(VoiceTimer t, {bool finished = false}) => VoiceTimer(
      id: '$source/${t.id}',
      name: t.name,
      totalSeconds: finished ? 0 : t.totalSeconds,
      startedAt: finished ? 0 : t.startedAt,
      active: !finished && t.active,
      finished: finished,
      duration: t.duration,
      source: source,
      sourceId: t.id,
      origin: name,
    );
    final hadAlerts = _shared.values.any((s) => s.alerts.isNotEmpty);
    if (timers.isEmpty && alerts.isEmpty) {
      _shared.remove(originId);
    } else {
      _shared.putIfAbsent(originId, () => _SharedSource(name))
        ..name = name
        ..timers = [for (final t in timers) own(t)]
        ..alerts = [for (final t in alerts) own(t, finished: true)];
    }
    final hasAlerts = _shared.values.any((s) => s.alerts.isNotEmpty);
    if (alerts.isNotEmpty) {
      if (_localAlerts.isEmpty) alertHidden.value = hidden;
      _sharedSpeech = speech != null && speech.isNotEmpty ? speech : null;
      _sharedSpeechText = speechText;
      _ringWith(muted: muted, at: ringAt ?? _clock().millisecondsSinceEpoch);
    } else {
      if (!hasAlerts) _sharedSpeech = null;
      _merge();
    }
    if (hadAlerts != hasAlerts) {
      bus.publish(SharedTimerAlertChanged(hasAlerts));
    }
  }

  /// Ends this kiosk's own ringing timers, as a tap on one does.
  void dismissLocal() {
    final first = _localAlerts.firstOrNull;
    if (first != null) control(first.id, 'dismiss');
  }

  /// The kiosks sharing timers here, by id.
  Set<String> get sharedOrigins => _shared.keys.toSet();

  /// Ends every ringing timer another kiosk shares, here and there.
  /// Answers whether any rang.
  bool dismissShared() {
    final ringing = [
      for (final e in _shared.entries)
        if (e.value.alerts.isNotEmpty) 'shared:${e.key}',
    ];
    for (final source in ringing) {
      _dismissSource(source);
    }
    return ringing.isNotEmpty;
  }

  void _dismissSource(String source) {
    final origin = _shared[source.substring('shared:'.length)];
    if (origin == null || origin.alerts.isEmpty) return;
    final first = origin.alerts.first;
    origin.alerts = const [];
    if (origin.timers.isEmpty) {
      _shared.remove(source.substring('shared:'.length));
    }
    final still = _shared.values.any((s) => s.alerts.isNotEmpty);
    if (!still) _sharedSpeech = null;
    _merge();
    if (!still) bus.publish(const SharedTimerAlertChanged(false));
    bus.publish(
      VoiceTimerAction(entityId: source, id: first.sourceId, action: 'dismiss'),
    );
  }

  /// Rebuilds [timers] and [alerts] from this kiosk's own and the shared
  /// ones, stops the ring once nothing rings, and opens or closes the full
  /// screen view as timers start, finish and run out.
  void _merge() {
    final nextAlerts = [
      ..._localAlerts,
      for (final s in _shared.values) ...s.alerts,
    ];
    final ringing = _ring != null || _ringStart != null;
    if (nextAlerts.isEmpty && ringing) {
      _ringStart?.cancel();
      _ringStart = null;
      _ring?.cancel();
      _ring = null;
      _speech = null;
      _stopSound();
      // A normal playback speaker gets back what it played before the alert.
      unawaited(commands.execute('voiceSpeakerDone', const {}));
    } else if (nextAlerts.isNotEmpty) {
      _speech = _localAlerts.isNotEmpty ? _localSpeech : _sharedSpeech;
      _speechText = _localAlerts.isNotEmpty
          ? _localSpeechText
          : _sharedSpeechText;
    }
    if (nextAlerts.isEmpty) alertHidden.value = false;
    alerts.value = nextAlerts;
    timers.value = [
      ..._localTimers,
      for (final s in _shared.values) ...s.timers,
    ];
    _syncView();
  }

  /// Starts the ring at [at], or keeps the one already going. A kiosk that
  /// joins late waits for the next beat instead of chiming off it.
  void _ringWith({required bool muted, required int at}) {
    final wasMuted = _muted;
    _muted = muted;
    _merge();
    if (_muted && !wasMuted) _stopSound();
    if (_ring != null) {
      if (wasMuted && !_muted) _tick();
      return;
    }
    if (_ringStart != null) return;
    _rings = 0;
    void begin() {
      _ringStart = null;
      if (alerts.value.isEmpty) return;
      _tick();
      _ring = Timer.periodic(ringEvery, (_) => _tick());
    }

    final beat = ringEvery.inMilliseconds;
    var wait = at - _clock().millisecondsSinceEpoch;
    if (wait < -50) wait = (beat - (-wait % beat)) % beat;
    if (wait <= 0) {
      begin();
    } else {
      _ringStart = Timer(Duration(milliseconds: wait), begin);
    }
  }

  void _clearLocalAlert() {
    final had = _localAlerts.isNotEmpty;
    _localAlerts = const [];
    _localRingAt = null;
    _localSpeech = null;
    _localSpeechText = '';
    _merge();
    if (had) localAlertChanged.value++;
  }

  bool get _fullScreen =>
      settings != null && !settings!.get(defs.voiceTimerPills);

  /// The full screen view opens by itself when a timer starts or finishes
  /// and closes again once the last one is gone, unless it was opened by
  /// hand or Compass holds it.
  void _syncView() {
    final ids = {
      for (final t in timers.value) t.id,
      if (!alertHidden.value)
        for (final t in alerts.value) 'alert:${t.id}',
    };
    final fresh = ids.difference(_knownIds).isNotEmpty;
    _knownIds = ids;
    if (!_fullScreen) return;
    if (fresh) {
      _closeTimer?.cancel();
      // A ringing timer needs its Dismiss button on a lit screen.
      if (alerts.value.isNotEmpty && !alertHidden.value) {
        unawaited(commands.execute('screenOn', const {}));
      }
      if (!visible.value) {
        _autoOpened = true;
        visible.value = true;
      }
    } else if (ids.isEmpty &&
        visible.value &&
        _autoOpened &&
        !compassView.value) {
      _closeTimer?.cancel();
      _closeTimer = Timer(const Duration(seconds: 2), () {
        if (timers.value.isEmpty && alerts.value.isEmpty && _autoOpened) {
          visible.value = false;
        }
      });
    }
  }

  /// One beat of the ring: a chime, or the phrase after every second chime.
  void _tick() {
    if (_playing) return;
    final speech = _speech;
    if (speech != null && _rings >= 2) {
      _rings = 0;
      unawaited(
        _chime(
          // On the kiosk, or on the speaker the answers are spoken on.
          () => commands.execute('voiceSpeak', {
            'url': speech,
            'text': _speechText,
            'kind': 'timer',
          }),
        ),
      );
      return;
    }
    _rings++;
    unawaited(_chime());
  }

  Future<void> _chime([Future<CommandResult> Function()? start]) async {
    if (_muted || alerts.value.isEmpty || _playing) return;
    final generation = _soundGeneration;
    _playing = true;
    final done = Completer<void>();
    _soundDone = done;
    final ended = <String>{};
    String? playingId;
    final subscription = bus.on<SoundEnded>().listen((event) {
      ended.add(event.id);
      if (event.id == playingId && !done.isCompleted) done.complete();
    });
    try {
      final result =
          await (start?.call() ??
              commands.execute('voiceChime', const {'kind': 'alert'}));
      final data = result.data;
      if (data is Map && data['id'] is String) {
        final id = data['id'] as String;
        playingId = id;
        if (generation != _soundGeneration || _muted || alerts.value.isEmpty) {
          await commands.execute('voiceStopSpeech', {'id': id});
        } else {
          _soundId = id;
          if (ended.contains(id) && !done.isCompleted) done.complete();
          await done.future;
        }
      }
    } finally {
      if (generation == _soundGeneration) {
        _playing = false;
        _soundId = null;
        _soundDone = null;
      }
      await subscription.cancel();
    }
  }

  void _stopSound() {
    _soundGeneration++;
    final done = _soundDone;
    _soundDone = null;
    if (done != null && !done.isCompleted) done.complete();
    _playing = false;
    final id = _soundId;
    _soundId = null;
    if (id != null) unawaited(commands.execute('voiceStopSpeech', {'id': id}));
  }

  @override
  Future<void> dispose() async {
    _ringStart?.cancel();
    _closeTimer?.cancel();
    _ring?.cancel();
    _ring = null;
    _stopSound();
    alerts.dispose();
    alertHidden.dispose();
    visible.dispose();
    compassView.dispose();
    localAlertChanged.dispose();
    await _clearSub?.cancel();
    await _dismissSub?.cancel();
    await _saverSub?.cancel();
    timers.dispose();
    error.dispose();
  }
}
