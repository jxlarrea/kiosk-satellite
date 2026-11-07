import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/locale_dates.dart';
import '../../core/manager.dart';
import '../home_assistant/ha_tts.dart';
import '../music_library/music_pick.dart';
import '../notifications/notification_sounds.dart';
import '../screensaver/screensaver_manager.dart'
    show currentScreensaverScheduleEntry;
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import '../voice/ha_socket.dart';
import 'alarm_model.dart';
import 'alarm_requests.dart';

/// Saving would make a second alarm with the same time and repeat days.
class DuplicateAlarm implements Exception {
  const DuplicateAlarm(this.existing);

  /// The alarm already set for that time.
  final Alarm existing;

  @override
  String toString() => 'an alarm is already set for ${existing.time}';
}

/// Where an alarm stands right now.
enum AlarmPhase { idle, sunrise, ringing, snoozed }

/// What the screens draw from: the phase, the alarms it is about, the
/// ring time, and where it shows.
@immutable
class AlarmStatus {
  const AlarmStatus({
    this.phase = AlarmPhase.idle,
    this.ids = const [],
    this.labels = const [],
    this.at,
    this.snoozedUntil,
    this.takeover,
    this.sunriseStart,
    this.next,
  });

  final AlarmPhase phase;

  /// The alarms this sunrise, ring or snooze is for; two alarms set to the
  /// same minute ring as one.
  final List<String> ids;
  final List<String> labels;

  /// The ring time the phase is about.
  final DateTime? at;
  final DateTime? snoozedUntil;

  /// The screensaver the alarm shows on (`clock`, `weather_mood`), or null
  /// for the alarm's own full screen view.
  final String? takeover;
  final DateTime? sunriseStart;

  /// The next ring across every alarm, snoozes included, for the Next
  /// alarm widget and the list.
  final ({String id, DateTime at})? next;

  bool get active => phase != AlarmPhase.idle;

  /// The alarm's own view is up: a sunrise or a ring with no takeover.
  bool get ownView =>
      (phase == AlarmPhase.sunrise || phase == AlarmPhase.ringing) &&
      takeover == null;

  Map<String, Object?> toJson() => {
    'phase': phase.name,
    'ids': ids,
    'labels': labels,
    'at': at?.toUtc().toIso8601String(),
    'snoozedUntil': snoozedUntil?.toUtc().toIso8601String(),
    'takeover': takeover,
    'sunriseStart': sunriseStart?.toUtc().toIso8601String(),
    'next': next == null
        ? null
        : {'id': next!.id, 'at': next!.at.toUtc().toIso8601String()},
  };

  @override
  bool operator ==(Object other) =>
      other is AlarmStatus &&
      other.phase == phase &&
      listEquals(other.ids, ids) &&
      listEquals(other.labels, labels) &&
      other.at == at &&
      other.snoozedUntil == snoozedUntil &&
      other.takeover == takeover &&
      other.sunriseStart == sunriseStart &&
      other.next?.id == next?.id &&
      other.next?.at == next?.at;

  @override
  int get hashCode => Object.hash(
    phase,
    Object.hashAll(ids),
    at,
    snoozedUntil,
    takeover,
    sunriseStart,
    next?.id,
    next?.at,
  );
}

/// The kiosk's own alarms (a Nest Hub style list, ring and sunrise).
///
/// The list lives in `alarms.list`; this manager works out the next ring,
/// asks the native side to wake the device for it, and runs a ring from
/// start to Stop, Snooze or Silence after. It owns what the screens show
/// through [status] and [visible]; the ring itself shows on the Clock or
/// Weather Mood screensaver when that one is chosen and lets alarms take
/// over (the `alarmTakeover` command), else on the alarm's own view.
class AlarmManager extends Manager {
  AlarmManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    DateTime Function()? clock,
    MethodChannel? channel,
    this._userName,
  }) : _clock = clock ?? DateTime.now,
       _channel = channel ?? const MethodChannel('kiosk_satellite/alarms');

  final SettingsManager _settings;
  final DateTime Function() _clock;
  final MethodChannel _channel;
  final Future<String> Function()? _userName;

  /// The mode a plugin holds the screensaver on, which wins over the
  /// schedule and the setting. Set by the app container.
  String? Function() screensaverModeOverride = _noOverride;
  static String? _noOverride() => null;

  /// The full screen alarm list is up.
  final visible = ValueNotifier<bool>(false);

  /// The alarm the list should open on, set just before [visible] by
  /// openAlarms with `alarm: next`. The alarm screen takes it and clears it.
  final focus = ValueNotifier<String?>(null);

  /// The alarms, sorted by time of day, decoded fresh on every change.
  final alarms = ValueNotifier<List<Alarm>>(const []);

  final status = ValueNotifier<AlarmStatus>(const AlarmStatus());

  final _subs = <StreamSubscription<Object?>>[];

  /// Alarms asked for by voice through Home Assistant.
  late final requests = AlarmRequests(_settings, this, clock: _clock);
  Timer? _tick;
  Timer? _precise;
  Timer? _ramp;
  Timer? _silence;

  /// The ring time each alarm last rang (or was stopped during its
  /// sunrise) for, in milliseconds, so a restart or a second check never
  /// rings the same one twice.
  final _handled = <String, int>{};
  DateTime? _ringStarted;
  bool _held = false;
  String? _heldSource;
  bool _fullscreen = false;
  bool _brightnessHeld = false;
  bool _stopWordArmed = false;
  bool _previewing = false;
  int? _scheduledRing;
  int? _scheduledWake;

  /// The sunrise brightness climbs from here to full.
  static const _sunriseFloor = 0.02;

  @override
  String get name => 'alarms';

  AlarmStatus get _s => status.value;

  Duration get _snooze => Duration(
    minutes: int.tryParse(_settings.get(defs.alarmsSnoozeMinutes)) ?? 10,
  );

  Duration get _silenceAfter => Duration(
    minutes: int.tryParse(_settings.get(defs.alarmsSilenceAfterMinutes)) ?? 10,
  );

  Duration get _sunriseLength => Duration(
    minutes: int.tryParse(_settings.get(defs.alarmsSunriseMinutes)) ?? 30,
  );

  @override
  Future<void> init() async {
    _readAlarms();
    _restore();
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'alarmFired') unawaited(_check());
      if (call.method == 'ringEnded') _previewing = false;
      return null;
    });
    _registerCommands();
    // Setting an alarm is not idle time: the screensaver waits while the
    // list is up.
    visible.addListener(_syncHold);
    _subs
      ..add(
        bus.on<SettingChanged>().listen((e) {
          if (e.key == defs.alarmsList.key) {
            _readAlarms();
            unawaited(_check());
          } else if (e.key == defs.alarmsSunriseMinutes.key ||
              e.key == defs.alarmsSilenceAfterMinutes.key) {
            unawaited(_check());
          } else if (e.key == defs.kioskAllowAlarms.key && e.value != true) {
            visible.value = false;
          }
        }),
      )
      ..add(
        bus.on<StopWordDetected>().listen((_) {
          if (_s.phase == AlarmPhase.ringing) {
            unawaited(stop(source: 'stop word'));
          }
        }),
      )
      ..add(
        // A touch that dismisses a takeover screensaver during the sunrise
        // gives the kiosk back: the glow ends, the ring still comes.
        bus.on<ScreensaverStateChanged>().listen((e) {
          // An abandoned list gives way to the screensaver, as the app
          // launcher does.
          if (e.active) visible.value = false;
          if (e.active || _s.takeover == null) return;
          if (_s.phase == AlarmPhase.sunrise) {
            unawaited(_endSunriseEarly());
          } else if (_s.phase == AlarmPhase.ringing) {
            // Home or back took the screensaver away mid ring: the ring
            // carries on over the alarm's own view.
            status.value = _copy(takeover: () => null);
            unawaited(_hold(native: false));
            _publish();
          }
        }),
      );
    _tick = Timer.periodic(const Duration(seconds: 15), (_) => _check());
    await _check();
  }

  @override
  Future<void> dispose() async {
    _tick?.cancel();
    _precise?.cancel();
    _ramp?.cancel();
    _silence?.cancel();
    for (final sub in _subs) {
      await sub.cancel();
    }
    visible.dispose();
    focus.dispose();
    alarms.dispose();
    status.dispose();
  }

  bool _listHeld = false;

  void _syncHold() {
    if (visible.value == _listHeld) return;
    _listHeld = visible.value;
    unawaited(
      commands.execute('holdScreensaver', {
        'holder': 'alarms',
        'held': _listHeld,
      }),
    );
  }

  // ── The list ──────────────────────────────────────────────────────────

  void _readAlarms() {
    final before = {for (final a in alarms.value) a.id: a};
    alarms.value = sortAlarms(decodeAlarms(_settings.get(defs.alarmsList)));
    // Every change to the list, from any surface, goes to Home Assistant;
    // the first read at start is not a change.
    if (!_listRead) {
      _listRead = true;
      return;
    }
    _gone = {
      for (final a in before.values)
        if (!alarms.value.any((b) => b.id == a.id)) a.id: a,
    };
    for (final alarm in alarms.value) {
      final old = before[alarm.id];
      if (old == null) {
        _alarmEvent('created', [alarm.id]);
      } else if (jsonEncode(old.toJson()) != jsonEncode(alarm.toJson())) {
        _alarmEvent('updated', [alarm.id]);
      }
    }
    if (_gone.isNotEmpty) _alarmEvent('deleted', _gone.keys.toList());
  }

  bool _listRead = false;

  /// The alarms the last change took out of the list, so a ring stopped
  /// by their deletion can still say which alarm it was.
  Map<String, Alarm> _gone = const {};

  /// Puts an alarm change on Home Assistant's bus as
  /// `esphome.kiosk_satellite_alarm`, one event per alarm (issue #765).
  void _alarmEvent(
    String event,
    List<String> ids, [
    Map<String, Object?> extra = const {},
  ]) {
    for (final id in ids) {
      final alarm =
          alarms.value.where((a) => a.id == id).firstOrNull ?? _gone[id];
      bus.publish(
        HaEventRequested('kiosk_satellite_alarm', {
          'event_type': event,
          'alarm_id': id,
          'label': alarm?.label ?? '',
          'time': alarm?.time ?? '',
          'days': [for (final d in alarm?.days ?? const <int>[]) _dayNames[d]],
          'enabled': alarm?.on ?? false,
          ...extra,
        }),
      );
    }
  }

  /// Weekdays as Home Assistant's time condition names them, 0 = Sunday.
  static const _dayNames = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

  Future<void> _write(List<Alarm> list) async {
    await _settings.set(defs.alarmsList, encodeAlarms(list));
    _readAlarms();
    _publish();
  }

  /// Another alarm with the same time and the same repeat days, the Nest
  /// Hub's "you already have an alarm set for 7 AM". Two one time alarms
  /// at the same time are the same alarm too, since both ring at the next
  /// time the clock reads it.
  Alarm? duplicateOf(Alarm alarm) {
    final days = alarm.days.toSet();
    for (final other in alarms.value) {
      if (other.id == alarm.id) continue;
      if (other.hour != alarm.hour || other.minute != alarm.minute) continue;
      final otherDays = other.days.toSet();
      if (otherDays.length == days.length && otherDays.containsAll(days)) {
        return other;
      }
    }
    return null;
  }

  /// Saves [alarm] (new when its id is unknown) and returns it as stored.
  /// A one time alarm that is on rings at the next time its clock reads
  /// its time. Throws [DuplicateAlarm] when another alarm already rings at
  /// that time on those days, unless [allowDuplicate] (a switch flipped on
  /// an alarm that already exists).
  Future<Alarm> save(Alarm alarm, {bool allowDuplicate = false}) async {
    if (!allowDuplicate) {
      final other = duplicateOf(alarm);
      if (other != null) throw DuplicateAlarm(other);
    }
    final now = _clock();
    final stored = alarm.on && !alarm.repeats
        ? alarm.copyWith(date: () => onceDate(alarm.hour, alarm.minute, now))
        : alarm.repeats
        ? alarm.copyWith(date: () => null)
        : alarm;
    final list = [...alarms.value];
    final i = list.indexWhere((a) => a.id == stored.id);
    if (i >= 0) {
      list[i] = stored;
    } else {
      list.add(stored);
    }
    // A changed alarm starts afresh from now: a time already behind it is
    // not rung late, so switching an alarm on two minutes after its time
    // waits for the next one. A stale mark from before would swallow the
    // next ring if the new time lands on the old one, so it goes too.
    final behind = lastRing(stored, now);
    if (behind != null) {
      _handled[stored.id] = behind.millisecondsSinceEpoch;
    } else {
      _handled.remove(stored.id);
    }
    await _write(list);
    log.info(name, 'saved ${stored.time} (${stored.id})');
    return stored;
  }

  Future<bool> delete(String id) async {
    final list = [...alarms.value]..removeWhere((a) => a.id == id);
    if (list.length == alarms.value.length) return false;
    _handled.remove(id);
    await _write(list);
    if (_s.ids.contains(id)) await stop(source: 'delete');
    log.info(name, 'deleted $id');
    return true;
  }

  Future<bool> setEnabled(String id, bool on) async {
    final alarm = alarms.value.where((a) => a.id == id).firstOrNull;
    if (alarm == null) return false;
    await save(alarm.copyWith(on: on), allowDuplicate: true);
    if (!on && _s.ids.contains(id)) await stop(source: 'turned off');
    return true;
  }

  // ── The clock ─────────────────────────────────────────────────────────

  /// One pass of [_check], for tests that move the clock by hand.
  @visibleForTesting
  Future<void> check() => _check();

  /// Everything time driven, in one place: silence a long ring, end a
  /// snooze, ring what is due, start a sunrise, and put the next wake in.
  /// Safe to run any time; the tick, the native wake and every change run
  /// it.
  Future<void> _check() async {
    final now = _clock();
    final phase = _s.phase;
    if (phase == AlarmPhase.ringing) {
      final started = _ringStarted;
      if (started != null && !now.isBefore(started.add(_silenceAfter))) {
        await _finish(
          'silenced after ${_silenceAfter.inMinutes} minutes',
          event: 'silenced',
        );
      }
    } else if (phase == AlarmPhase.snoozed) {
      final until = _s.snoozedUntil;
      if (until != null && !now.isBefore(until)) {
        await _ring(_s.ids, _s.at ?? now, snoozed: true);
      }
    }
    if (_s.phase != AlarmPhase.ringing) {
      final due = <Alarm>[];
      DateTime? dueAt;
      for (final alarm in alarms.value) {
        final at = lastRing(alarm, now);
        if (at == null) continue;
        if (!now.isBefore(at.add(_grace))) continue;
        if (_handled[alarm.id] == at.millisecondsSinceEpoch) continue;
        if (dueAt == null || at.isAfter(dueAt)) {
          due
            ..clear()
            ..add(alarm);
          dueAt = at;
        } else if (at == dueAt) {
          due.add(alarm);
        }
      }
      if (due.isNotEmpty) {
        await _ring([for (final a in due) a.id], dueAt!);
      } else if (_s.phase == AlarmPhase.idle) {
        await _maybeSunrise(now);
      }
    }
    _publish();
    await _schedule(now);
  }

  /// The next ring of [alarm] that is still to come: one already stopped
  /// during its sunrise is skipped for the one after.
  DateTime? upcoming(Alarm alarm, DateTime now) {
    final at = nextRing(alarm, now);
    if (at == null || _handled[alarm.id] != at.millisecondsSinceEpoch) {
      return at;
    }
    return nextRing(alarm, at);
  }

  ({Alarm alarm, DateTime at})? _nextOf(Iterable<Alarm> list, DateTime now) {
    ({Alarm alarm, DateTime at})? best;
    for (final alarm in list) {
      final at = upcoming(alarm, now);
      if (at != null && (best == null || at.isBefore(best.at))) {
        best = (alarm: alarm, at: at);
      }
    }
    return best;
  }

  /// How late a ring still counts: a device asleep through the whole
  /// Silence after window skips the alarm rather than ring it late.
  Duration get _grace => _silenceAfter;

  Future<void> _maybeSunrise(DateTime now) async {
    final next = _nextOf([
      for (final a in alarms.value)
        if (a.sunrise) a,
    ], now);
    if (next == null) return;
    final start = next.at.subtract(_sunriseLength);
    if (now.isBefore(start)) return;
    if (_handled[next.alarm.id] == next.at.millisecondsSinceEpoch) return;
    // Every alarm set to that same minute rides the same sunrise.
    final ids = [
      for (final a in alarms.value)
        if (upcoming(a, now) == next.at) a.id,
    ];
    await _startSunrise(ids, next.at, start);
  }

  /// The native wake for the next ring (and a sunrise before it), and a
  /// Dart timer for the same moment so a live process does not wait for
  /// its tick.
  Future<void> _schedule(DateTime now) async {
    final next = _s.next;
    int? ringAt = next?.at.millisecondsSinceEpoch;
    int? wakeAt;
    if (_s.phase == AlarmPhase.idle) {
      final sunrise = _nextOf([
        for (final a in alarms.value)
          if (a.sunrise) a,
      ], now);
      if (sunrise != null) {
        wakeAt = sunrise.at.subtract(_sunriseLength).millisecondsSinceEpoch;
      }
    }
    if (_s.phase == AlarmPhase.ringing) {
      final silenceAt = _ringStarted?.add(_silenceAfter);
      _arm(silenceAt, now);
    } else {
      final soonest = [
        ?ringAt,
        ?wakeAt,
      ].fold<int?>(null, (a, b) => a == null || b < a ? b : a);
      _arm(
        soonest == null ? null : DateTime.fromMillisecondsSinceEpoch(soonest),
        now,
      );
    }
    if (ringAt == _scheduledRing && wakeAt == _scheduledWake) return;
    _scheduledRing = ringAt;
    _scheduledWake = wakeAt;
    try {
      await _channel.invokeMethod('schedule', {
        'ringAt': ringAt,
        'wakeAt': wakeAt,
      });
    } on MissingPluginException {
      // Not Android (tests): the Dart timers carry it.
    } catch (e) {
      log.warn(name, 'could not schedule the next alarm: $e');
    }
  }

  void _arm(DateTime? at, DateTime now) {
    _precise?.cancel();
    _precise = null;
    if (at == null) return;
    final wait = at.difference(now);
    // The tick covers anything further out; a long Timer only drifts.
    if (wait > const Duration(minutes: 1)) return;
    _precise = Timer(
      wait.isNegative ? Duration.zero : wait + const Duration(milliseconds: 50),
      () => _check(),
    );
  }

  // ── Sunrise ───────────────────────────────────────────────────────────

  Future<void> _startSunrise(
    List<String> ids,
    DateTime at,
    DateTime start,
  ) async {
    final takeover = _takeoverMode();
    log.info(
      name,
      'sunrise started, ringing at ${_hm(at)} (${_describe(ids)})'
      '${takeover == null ? '' : ' on the $takeover screensaver'}',
    );
    status.value = AlarmStatus(
      phase: AlarmPhase.sunrise,
      ids: ids,
      labels: _labels(ids),
      at: at,
      takeover: takeover,
      sunriseStart: start,
      next: _s.next,
    );
    _alarmEvent('sunrise', ids);
    await _comeForward();
    await _hold(native: takeover != null);
    await _setFullscreen(true);
    if (takeover != null && !await _takeover('sunrise')) {
      status.value = _copy(takeover: () => null);
      await _hold(native: false);
    }
    _startRamp();
    _persist();
    _publish();
  }

  void _startRamp() {
    _ramp?.cancel();
    Future<void> step() async {
      final s = _s;
      final start = s.sunriseStart;
      final at = s.at;
      if (start == null || at == null) return;
      final span = at.difference(start).inMilliseconds;
      final done = _clock().difference(start).inMilliseconds;
      final t = span <= 0 ? 1.0 : (done / span).clamp(0.0, 1.0);
      await _brightness(_sunriseFloor + (1 - _sunriseFloor) * t);
    }

    unawaited(step());
    _ramp = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_s.phase != AlarmPhase.sunrise) {
        _ramp?.cancel();
        return;
      }
      unawaited(step());
    });
  }

  /// A touch dismissed the takeover screensaver mid sunrise: the kiosk is
  /// in use, so the glow and the brightness hand back. The ring itself
  /// still comes at its time.
  Future<void> _endSunriseEarly() async {
    log.info(name, 'sunrise ended by a touch; the alarm still rings');
    _ramp?.cancel();
    await _brightness(null);
    await _release();
    status.value = AlarmStatus(next: _s.next);
    _persist();
    _publish();
  }

  // ── Ringing ───────────────────────────────────────────────────────────

  Future<void> _ring(
    List<String> ids,
    DateTime at, {
    bool snoozed = false,
  }) async {
    final known = [
      for (final id in ids)
        if (alarms.value.any((a) => a.id == id)) id,
    ];
    if (known.isEmpty) {
      await _finish('its alarm is gone');
      return;
    }
    final fromSunrise =
        _s.phase == AlarmPhase.sunrise && listEquals(_s.ids, known);
    var takeover = fromSunrise ? _s.takeover : _takeoverMode();
    for (final id in known) {
      _handled[id] = at.millisecondsSinceEpoch;
    }
    await _spend(known);
    _ringStarted = _clock();
    log.info(
      name,
      '${snoozed ? 'ringing again' : 'ringing'}: ${_describe(known)}'
      '${takeover == null ? '' : ' on the $takeover screensaver'}',
    );
    status.value = AlarmStatus(
      phase: AlarmPhase.ringing,
      ids: known,
      labels: _labels(known),
      at: at,
      takeover: takeover,
      next: _s.next,
    );
    _alarmEvent('ringing', known);
    visible.value = false;
    await _comeForward();
    await _hold(native: takeover != null);
    await _setFullscreen(true);
    if (takeover != null && !await _takeover('ringing')) {
      takeover = null;
      status.value = _copy(takeover: () => null);
      await _hold(native: false);
    }
    // A sunrise leaves the panel at full; a plain ring keeps the level the
    // kiosk had.
    if (!fromSunrise) {
      _ramp?.cancel();
    } else {
      _ramp?.cancel();
      await _brightness(1);
    }
    final alarm = alarms.value.firstWhere((a) => a.id == known.first);
    final gen = ++_ringGen;
    if (alarm.musicWith(defaultMusic) case final music?) {
      // The music can take a few seconds to start on its speaker; the
      // screen and the stop word work meanwhile, and the tone rings if it
      // does not start.
      _previewing = false;
      await _armStopWord(true);
      _persist();
      _publish();
      unawaited(_ringMusic(alarm, music, at, gen));
      return;
    }
    await _ringTone(alarm, at, gen);
    _previewing = false;
    await _armStopWord(true);
    _persist();
    _publish();
  }

  /// The Alarm music default, null for none.
  MusicPick? get defaultMusic {
    final raw = _settings.get(defs.alarmsMusic).trim();
    if (raw.isEmpty) return null;
    try {
      return MusicPick.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  /// Whether the alarm's music plays, or is starting: a quiet stops it.
  bool _music = false;

  /// The ring whose music started last. A start that finishes after a
  /// newer ring began its own leaves that one alone.
  int _musicGen = -1;

  /// Play the alarm's music on its speaker at the alarm volume, repeating
  /// until stopped. The alarm's tone rings when it cannot play.
  Future<void> _ringMusic(
    Alarm alarm,
    MusicPick music,
    DateTime at,
    int gen,
  ) async {
    _music = true;
    _musicGen = gen;
    final result = await commands.execute('musicPickStart', {
      'pick': music.toJson(),
      'owner': 'alarm',
      'volume': (_settings.get(defs.alarmsVolume) * 100).round(),
      'repeat': true,
      // The music eases in the way the tone does.
      'easeMs': easesIn(alarm) ? _easeMs : 0,
    });
    if (gen != _ringGen || _s.phase != AlarmPhase.ringing) {
      // Stopped or snoozed while the music started. A newer ring that
      // started its own music keeps it.
      if (result.ok && _musicGen == gen) {
        await commands.execute('musicPickStop', const {'owner': 'alarm'});
      }
      return;
    }
    if (result.ok) {
      log.info(
        name,
        'ringing with music: ${music.item?.title ?? music.random?.name}',
      );
      return;
    }
    _music = false;
    log.warn(
      name,
      'the alarm music did not play (${result.error}), ringing the tone',
    );
    await _ringTone(alarm, at, gen);
  }

  /// Ring [alarm]'s tone on this device, with its phrase between the
  /// rings.
  Future<void> _ringTone(Alarm alarm, DateTime at, int gen) async {
    final path = await _tonePath(alarm.tone);
    if (gen != _ringGen) return;
    var rang = false;
    try {
      rang =
          await _channel.invokeMethod<bool>('ring', {
            'path': path,
            'volume': _settings.get(defs.alarmsVolume).toDouble(),
            'loop': true,
            'easeMs': easesIn(alarm) ? _easeMs : 0,
          }) ??
          false;
    } on MissingPluginException {
      rang = true;
    } catch (e) {
      log.warn(name, 'ring failed: $e');
    }
    if (!rang) log.warn(name, 'the alarm tone did not play ($path)');
    final speaker = [
      for (final id in _s.ids) ...alarms.value.where((a) => a.id == id),
    ].where((a) => a.speak).firstOrNull;
    if (rang && speaker != null) unawaited(_speakRing(speaker, at, gen));
  }

  // ── Speech and ease in ────────────────────────────────────────────────

  /// Bumped by every ring and every quiet, so a phrase that comes back
  /// from Home Assistant after Stop or Snooze is dropped.
  int _ringGen = 0;

  /// Made phrases on disk by their words and voice, so a snooze's second
  /// ring does not ask Home Assistant again.
  final _phrases = <String, String>{};

  /// Whether [alarm] starts quiet and grows to the alarm volume.
  bool easesIn(Alarm alarm) => alarm.ease ?? _settings.get(defs.alarmsEaseIn);

  int get _easeMs =>
      (_settings.get(defs.alarmsEaseInSeconds).toDouble() * 1000).round();

  /// The phrase [alarm] fills in: its own or the default.
  String _template(Alarm alarm) =>
      alarm.phrase.isEmpty ? _settings.get(defs.alarmsPhrase) : alarm.phrase;

  /// What [alarm] says ringing at [at], in the device's language. [userName]
  /// fills {name}.
  String phraseFor(Alarm alarm, DateTime at, {String userName = ''}) =>
      fillAlarmPhrase(
        _template(alarm),
        label: alarm.label,
        name: userName,
        time: _spokenTime(at),
        hour: _spokenHour(at),
        minute: '${at.minute}',
        date: _safeFormat((l) => DateFormat.yMMMMd(l), at),
        day: _safeFormat((l) => DateFormat.EEEE(l), at),
        dayOfMonth: '${at.day}',
        month: _safeFormat((l) => DateFormat.MMMM(l), at),
        year: '${at.year}',
      );

  /// [phraseFor] with the Home Assistant user's name, asked for only when
  /// the phrase uses it.
  Future<String> spokenPhrase(Alarm alarm, DateTime at) async => phraseFor(
    alarm,
    at,
    userName: _template(alarm).contains('{name}') ? await _askUserName() : '',
  );

  /// Who the kiosk's token belongs to, or blank when Home Assistant does
  /// not say in time: the phrase then goes without the name.
  Future<String> _askUserName() async {
    try {
      return await (_userName ?? _haUserName)().timeout(
        const Duration(seconds: 5),
      );
    } catch (e) {
      log.warn(name, 'no Home Assistant user name for the phrase: $e');
      return '';
    }
  }

  /// A socket for this one question, so a kiosk that never says {name}
  /// holds no connection for it.
  Future<String> _haUserName() async {
    final socket = HaSocket(
      baseUrl: () => _settings.get(defs.haUrl),
      token: () => _settings.get(defs.haToken),
    );
    try {
      final user = await socket.request({'type': 'auth/current_user'});
      return user is Map ? '${user['name'] ?? ''}' : '';
    } finally {
      await socket.close();
    }
  }

  bool get _use24h => _settings.get(defs.alarmsClock24h);

  /// The time on the clock Settings > Alarms > 24-hour clock picks: 19:00,
  /// or 7:00 PM.
  String _spokenTime(DateTime at) {
    String out;
    try {
      out = (_use24h ? DateFormat.Hm() : twelveHourFormat()).format(at);
    } catch (_) {
      out = DateFormat(_use24h ? 'HH:mm' : 'h:mm a', 'en_US').format(at);
    }
    return _plainSpaces(out);
  }

  /// The hour the way {time} reads it, so 7 at 19:00 on an AM/PM clock.
  String _spokenHour(DateTime at) {
    if (_use24h) return '${at.hour}';
    final hour = at.hour % 12;
    return '${hour == 0 ? 12 : hour}';
  }

  /// Plain spaces: intl puts a narrow no-break one before AM, which a
  /// text to speech engine may read out or trip on.
  static String _safeFormat(DateFormat Function(String?) make, DateTime t) {
    String out;
    try {
      out = make(null).format(t);
    } catch (_) {
      out = make('en_US').format(t);
    }
    return _plainSpaces(out);
  }

  static String _plainSpaces(String s) =>
      s.replaceAll(RegExp('[\u00a0\u202f]'), ' ');

  /// Has Home Assistant say the phrase and hands the audio to the ring,
  /// which plays it after every second pass of the tone. The tone rings
  /// from the first second either way: a slow or missing Home Assistant
  /// only costs the words.
  Future<void> _speakRing(Alarm alarm, DateTime at, int gen) async {
    final text = await spokenPhrase(alarm, at);
    if (text.isEmpty) return;
    final engine = _settings.get(defs.alarmsTtsEngine).trim();
    // A language or voice only goes with an engine picked by name.
    final language = engine.isEmpty
        ? ''
        : _settings.get(defs.alarmsTtsLanguage).trim();
    final voice = engine.isEmpty
        ? ''
        : _settings.get(defs.alarmsTtsVoice).trim();
    // Kept per voice too: a new voice must not ring with the old one.
    final key = '$engine|$language|$voice|$text';
    var path = _phrases[key];
    if (path == null || !File(path).existsSync()) {
      final audio = await haSpeak(
        base: _settings.get(defs.haUrl),
        token: _settings.get(defs.haToken),
        engine: engine,
        language: language,
        voice: voice,
        message: text,
      );
      if (audio == null) {
        log.warn(name, 'Home Assistant did not speak "$text"; ringing on');
        return;
      }
      try {
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/ks_alarm_phrase_${key.hashCode.toUnsigned(32)}',
        );
        await file.writeAsBytes(audio, flush: true);
        path = file.path;
        _phrases[key] = path;
      } catch (e) {
        log.warn(name, 'could not keep the phrase: $e');
        return;
      }
    }
    if (gen != _ringGen || _s.phase != AlarmPhase.ringing) return;
    log.info(name, 'speaking "$text" between the rings');
    try {
      await _channel.invokeMethod('speech', {'path': path});
    } on MissingPluginException {
      // Tests.
    } catch (e) {
      log.warn(name, 'could not add the phrase: $e');
    }
  }

  /// A one time alarm is spent once it rings, or once its sunrise is
  /// stopped: it stays in the list, off.
  Future<void> _spend(List<String> ids) async {
    final spent = [
      for (final a in alarms.value)
        if (ids.contains(a.id) && !a.repeats && a.on) a.id,
    ];
    if (spent.isEmpty) return;
    await _settings.set(
      defs.alarmsList,
      encodeAlarms([
        for (final a in alarms.value)
          spent.contains(a.id) ? a.copyWith(on: false, date: () => null) : a,
      ]),
    );
    _readAlarms();
  }

  /// Snooze the ring for the snooze length.
  Future<bool> snooze({String source = 'button'}) async {
    if (_s.phase != AlarmPhase.ringing) return false;
    final until = _clock().add(_snooze);
    log.info(name, 'snoozed until ${_hm(until)} ($source)');
    await _quiet();
    status.value = AlarmStatus(
      phase: AlarmPhase.snoozed,
      ids: _s.ids,
      labels: _s.labels,
      at: _s.at,
      snoozedUntil: until,
      next: _s.next,
    );
    _alarmEvent('snoozed', _s.ids, {
      'snoozed_until': until.toUtc().toIso8601String(),
    });
    _persist();
    _publish();
    await _schedule(_clock());
    return true;
  }

  /// Stop whatever the alarm is doing: a ring, a snooze or a sunrise. A
  /// sunrise stopped ends that alarm for its ring too.
  Future<bool> stop({String source = 'button'}) async {
    final s = _s;
    if (!s.active) return false;
    if (s.phase == AlarmPhase.sunrise && s.at != null) {
      for (final id in s.ids) {
        _handled[id] = s.at!.millisecondsSinceEpoch;
      }
      await _spend(s.ids);
    }
    await _finish('stopped ($source)', event: 'stopped');
    return true;
  }

  Future<void> _finish(String why, {String? event}) async {
    if (_s.active) {
      log.info(name, '${_describe(_s.ids)}: $why');
      if (event != null) _alarmEvent(event, _s.ids);
    }
    await _quiet();
    status.value = AlarmStatus(next: _s.next);
    _persist();
    _publish();
    await _schedule(_clock());
  }

  /// Everything a ring holds, let go: the tone, the stop word, the
  /// brightness, the screen and the screensaver.
  Future<void> _quiet() async {
    _ringGen++;
    _ramp?.cancel();
    _silence?.cancel();
    _ringStarted = null;
    try {
      await _channel.invokeMethod('stop');
    } on MissingPluginException {
      // Tests.
    } catch (_) {}
    if (_music) {
      _music = false;
      await commands.execute('musicPickStop', const {'owner': 'alarm'});
    }
    await _armStopWord(false);
    await _brightness(null);
    await _release();
  }

  Future<void> _release() async {
    if (_s.takeover != null) await _takeover(null);
    await _setFullscreen(false);
    await _unhold();
  }

  // ── Where it shows ────────────────────────────────────────────────────

  /// The screensaver a ring or a sunrise shows on, or null for the alarm's
  /// own view: Clock or Weather Mood, chosen, scheduled or held by a plugin
  /// now, with its Let alarms take over switch on.
  String? _takeoverMode() {
    if (!_settings.get(defs.screensaverEnabled)) return null;
    final entry = currentScreensaverScheduleEntry(_settings, now: _clock());
    final mode =
        screensaverModeOverride() ??
        (entry?['mode'] as String?) ??
        _settings.get(defs.screensaverMode);
    return switch (mode) {
      'clock' when _settings.get(defs.screensaverClockAlarmTakeover) => 'clock',
      'weather_mood' when _settings.get(defs.screensaverWeatherAlarmTakeover) =>
        'weather_mood',
      _ => null,
    };
  }

  Future<bool> _takeover(String? phase) async {
    final r = await commands.execute('alarmTakeover', {'phase': phase});
    if (!r.ok && phase != null) {
      log.info(name, 'the screensaver could not take over (${r.error})');
    }
    return r.ok;
  }

  Future<void> _comeForward() async {
    final r = await commands.execute('bringToFront', const {});
    if (!r.ok) await commands.execute('screenOn', const {});
  }

  /// The screensaver's idle clock, the music and the assistant stand
  /// still while an alarm is on screen. The alarm's own view dismisses the
  /// screensaver (a command source); a takeover keeps it (native).
  Future<void> _hold({required bool native}) async {
    final source = native
        ? InteractionSource.native
        : InteractionSource.command;
    if (_held && _heldSource == source.name) return;
    if (_held) await _unhold();
    _held = true;
    _heldSource = source.name;
    bus.publish(
      VoiceInteractionChanged(active: true, reason: 'alarm', source: source),
    );
  }

  Future<void> _unhold() async {
    if (!_held) return;
    _held = false;
    final source = _heldSource == InteractionSource.native.name
        ? InteractionSource.native
        : InteractionSource.command;
    _heldSource = null;
    bus.publish(
      VoiceInteractionChanged(active: false, reason: 'alarm', source: source),
    );
  }

  Future<void> _setFullscreen(bool shown) async {
    if (_fullscreen == shown) return;
    _fullscreen = shown;
    bus.publish(FullscreenViewChanged(view: 'alarm', shown: shown));
  }

  Future<void> _brightness(double? level) async {
    if (level == null && !_brightnessHeld) return;
    _brightnessHeld = level != null;
    await commands.execute('alarmBrightness', {'level': level});
  }

  Future<void> _armStopWord(bool armed) async {
    if (_stopWordArmed == armed) return;
    _stopWordArmed = armed;
    await commands.execute('setStopWordArmed', {
      'armed': armed,
      'holder': 'alarm',
    });
  }

  // ── Tones ─────────────────────────────────────────────────────────────

  final _bundled = <String, String>{};

  /// The file a tone plays from: a sound in the sounds folder, else the
  /// built-in alarm (Default follows the Alarm tone setting).
  Future<String> _tonePath(String tone) async {
    final pick = tone.isEmpty ? _settings.get(defs.alarmsTone) : tone;
    if (pick.isNotEmpty && pick != 'builtin') {
      final path = await NotificationSounds.resolve(pick);
      if (path != null) return path;
      log.warn(name, 'alarm tone $pick is missing, ringing the built-in one');
    }
    return _asset('assets/sounds/alarm.ogg');
  }

  Future<String> _asset(String asset) async {
    final hit = _bundled[asset];
    if (hit != null && File(hit).existsSync()) return hit;
    try {
      final data = await rootBundle.load(asset);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ks_${asset.split('/').last}');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      _bundled[asset] = file.path;
      return file.path;
    } catch (e) {
      log.warn(name, 'could not unpack $asset: $e');
      return '';
    }
  }

  Future<bool> _preview(String tone) async {
    if (_s.phase == AlarmPhase.ringing) return false;
    final path = await _tonePath(tone);
    try {
      _previewing =
          await _channel.invokeMethod<bool>('ring', {
            'path': path,
            'volume': _settings.get(defs.alarmsVolume).toDouble(),
            'loop': false,
          }) ??
          false;
    } on MissingPluginException {
      _previewing = true;
    }
    return _previewing;
  }

  Future<void> _stopPreview() async {
    if (!_previewing || _s.phase == AlarmPhase.ringing) return;
    _previewing = false;
    try {
      await _channel.invokeMethod('stop');
    } on MissingPluginException {
      // Tests.
    }
  }

  // ── State ─────────────────────────────────────────────────────────────

  AlarmStatus _copy({String? Function()? takeover}) => AlarmStatus(
    phase: _s.phase,
    ids: _s.ids,
    labels: _s.labels,
    at: _s.at,
    snoozedUntil: _s.snoozedUntil,
    takeover: takeover != null ? takeover() : _s.takeover,
    sunriseStart: _s.sunriseStart,
    next: _s.next,
  );

  List<String> _labels(List<String> ids) => [
    for (final id in ids)
      alarms.value.where((a) => a.id == id).firstOrNull?.label ?? '',
  ];

  ({String id, DateTime at})? _next(DateTime now) {
    final ring = _nextOf(alarms.value, now);
    final s = _s;
    final until = s.phase == AlarmPhase.snoozed ? s.snoozedUntil : null;
    if (until != null &&
        s.ids.isNotEmpty &&
        (ring == null || until.isBefore(ring.at))) {
      return (id: s.ids.first, at: until);
    }
    return ring == null ? null : (id: ring.alarm.id, at: ring.at);
  }

  Map<String, Object?> get statusJson {
    final now = _clock();
    return {
      ..._s.toJson(),
      'alarms': [
        for (final a in alarms.value)
          {...a.toJson(), 'next': upcoming(a, now)?.toUtc().toIso8601String()},
      ],
      'visible': visible.value,
    };
  }

  void _publish() {
    final next = _next(_clock());
    final s = _s;
    final updated = AlarmStatus(
      phase: s.phase,
      ids: s.ids,
      labels: _labels(s.ids).any((l) => l.isNotEmpty)
          ? _labels(s.ids)
          : s.labels,
      at: s.at,
      snoozedUntil: s.snoozedUntil,
      takeover: s.takeover,
      sunriseStart: s.sunriseStart,
      next: next,
    );
    status.value = updated;
    bus.publish(AlarmStateChanged(statusJson));
  }

  void _persist() {
    final s = _s;
    unawaited(
      _settings.set(
        defs.alarmsRuntime,
        jsonEncode({
          'handled': _handled,
          if (s.phase == AlarmPhase.ringing && s.at != null)
            'ring': {
              'ids': s.ids,
              'at': s.at!.millisecondsSinceEpoch,
              'started': _ringStarted?.millisecondsSinceEpoch,
            },
          if (s.phase == AlarmPhase.snoozed && s.snoozedUntil != null)
            'snooze': {
              'ids': s.ids,
              'at': s.at?.millisecondsSinceEpoch,
              'until': s.snoozedUntil!.millisecondsSinceEpoch,
            },
        }),
      ),
    );
  }

  /// Back from a restart: the handled marks, and a snooze in progress. A
  /// ring that was going when the app died rings again from the start if
  /// it is still inside its Silence after window.
  void _restore() {
    try {
      final raw = jsonDecode(_settings.get(defs.alarmsRuntime));
      if (raw is! Map) return;
      final handled = raw['handled'];
      if (handled is Map) {
        for (final e in handled.entries) {
          if (e.value is num) _handled['${e.key}'] = (e.value as num).toInt();
        }
      }
      final now = _clock();
      final snooze = raw['snooze'];
      if (snooze is Map && snooze['until'] is num) {
        final until = DateTime.fromMillisecondsSinceEpoch(
          (snooze['until'] as num).toInt(),
        );
        if (now.isBefore(until.add(_grace))) {
          final ids = [for (final id in snooze['ids'] as List? ?? []) '$id'];
          status.value = AlarmStatus(
            phase: AlarmPhase.snoozed,
            ids: ids,
            labels: _labels(ids),
            at: snooze['at'] is num
                ? DateTime.fromMillisecondsSinceEpoch(
                    (snooze['at'] as num).toInt(),
                  )
                : null,
            snoozedUntil: until,
          );
        }
      }
      final ring = raw['ring'];
      if (ring is Map && ring['started'] is num) {
        final started = DateTime.fromMillisecondsSinceEpoch(
          (ring['started'] as num).toInt(),
        );
        if (now.isBefore(started.add(_silenceAfter))) {
          // Due again: the next check rings it with a fresh start.
          final ids = [for (final id in ring['ids'] as List? ?? []) '$id'];
          status.value = AlarmStatus(
            phase: AlarmPhase.snoozed,
            ids: ids,
            labels: _labels(ids),
            at: ring['at'] is num
                ? DateTime.fromMillisecondsSinceEpoch(
                    (ring['at'] as num).toInt(),
                  )
                : null,
            snoozedUntil: now,
          );
        }
      }
    } catch (e) {
      log.warn(name, 'could not read the alarm state: $e');
    }
  }

  String _describe(List<String> ids) => ids
      .map((id) {
        final a = alarms.value.where((a) => a.id == id).firstOrNull;
        if (a == null) return id;
        return a.label.isEmpty ? a.time : '${a.time} ${a.label}';
      })
      .join(', ');

  static String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Commands ──────────────────────────────────────────────────────────

  void _registerCommands() {
    commands
      ..register(
        Command(
          name: 'alarmsStatus',
          description:
              'Every alarm with its next ring, and what is going on: '
              '{phase: idle|sunrise|ringing|snoozed, ids, labels, at, '
              'snoozedUntil, takeover, next, alarms: [...]}.',
          quiet: true,
          handler: (_) async => CommandResult.ok(statusJson),
        ),
      )
      ..register(
        Command(
          name: 'alarmsVoiceRequest',
          description:
              'What the Kiosk Satellite alarms script asks for, answered in '
              'the shape the script hands back to the LLM.',
          params: const {
            'action': 'set, list, turn_off, turn_on or delete',
            'time': 'HH:MM, 24 hour',
            'days': 'Repeat days: mon to sun, weekdays, weekends or daily',
            'label': 'The alarm\'s name',
          },
          // The voice requests manager logs each one with its outcome.
          quiet: true,
          handler: (p) async => CommandResult.ok(await requests.handle(p)),
        ),
      )
      ..register(
        Command(
          name: 'alarmSave',
          description:
              'Add or change an alarm. An alarm without a known id is new. '
              'Fails with "duplicate" when another alarm already rings at '
              'that time on the same days.',
          params: const {
            'alarm':
                '{id?, time: "HH:mm", days: [0..6, 0 = Sunday], label, '
                'tone: "" (default) | "builtin" | a sounds folder file, '
                'sunrise, ease?: true | false (absent follows '
                'alarms.ease_in), speak, phrase: "" (alarms.phrase) | '
                'text with {label}, {time} and {day}, on, music?: the '
                'music picker\'s pick, rung instead of the tone}',
          },
          handler: (p) async {
            final raw = p['alarm'];
            final alarm = Alarm.fromJson(raw);
            if (alarm == null) {
              return const CommandResult.fail('an alarm needs a time as HH:mm');
            }
            final toneError = alarm.tone == 'builtin'
                ? null
                : defs.validateNotificationSound(alarm.tone);
            if (toneError != null) return CommandResult.fail(toneError);
            try {
              final saved = await save(alarm);
              return CommandResult.ok(saved.toJson());
            } on DuplicateAlarm {
              // A code rather than words: each surface says it in its own
              // language, with the time in its own format.
              return const CommandResult.fail('duplicate');
            }
          },
        ),
      )
      ..register(
        Command(
          name: 'alarmDelete',
          description: 'Remove an alarm.',
          params: const {'id': 'The alarm id'},
          handler: (p) async => await delete('${p['id'] ?? ''}')
              ? const CommandResult.ok()
              : const CommandResult.fail('no such alarm'),
        ),
      )
      ..register(
        Command(
          name: 'alarmSetEnabled',
          description: 'Turn an alarm on or off.',
          params: const {'id': 'The alarm id', 'on': 'true or false'},
          handler: (p) async =>
              await setEnabled('${p['id'] ?? ''}', p['on'] == true)
              ? const CommandResult.ok()
              : const CommandResult.fail('no such alarm'),
        ),
      )
      ..register(
        Command(
          name: 'alarmStop',
          description:
              'Stop the ringing, snoozed or sunrise alarm. A sunrise stopped '
              'skips its ring.',
          handler: (p) async =>
              await stop(source: '${p['source'] ?? 'command'}')
              ? const CommandResult.ok()
              : const CommandResult.fail('no alarm is going'),
        ),
      )
      ..register(
        Command(
          name: 'alarmSnooze',
          description: 'Snooze the ringing alarm for the snooze length.',
          handler: (p) async =>
              await snooze(source: '${p['source'] ?? 'command'}')
              ? const CommandResult.ok()
              : const CommandResult.fail('no alarm is ringing'),
        ),
      )
      ..register(
        Command(
          name: 'openAlarms',
          description:
              'Open the full screen alarm list on the kiosk. With alarm '
              'next it opens the alarm that rings next, snoozes included, '
              'or the list when none is set.',
          params: const {'alarm': 'next, to open the next alarm (optional)'},
          handler: (p) async {
            final alarm = p['alarm'];
            if (alarm != null && alarm != 'next') {
              return const CommandResult.fail('alarm must be next');
            }
            await commands.execute('screenOn', const {});
            await commands.execute('bringToFront', const {});
            await commands.execute('stopScreensaver', const {});
            if (alarm == 'next') focus.value = _s.next?.id;
            visible.value = true;
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'hideAlarms',
          description: 'Close the alarm list.',
          handler: (_) async {
            visible.value = false;
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'previewAlarmTone',
          description:
              'Play a tone once at the alarm volume on the alarm stream.',
          params: const {
            'tone': '"" (default), "builtin" or a sounds folder file',
          },
          handler: (p) async => await _preview('${p['tone'] ?? ''}')
              ? const CommandResult.ok()
              : const CommandResult.fail('the tone did not play'),
        ),
      )
      ..register(
        Command(
          name: 'stopAlarmTonePreview',
          description: 'Stop a tone preview.',
          handler: (_) async {
            await _stopPreview();
            return const CommandResult.ok();
          },
        ),
      );
  }
}
