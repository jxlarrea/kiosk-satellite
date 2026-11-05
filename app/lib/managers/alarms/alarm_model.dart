import 'dart:convert';
import 'dart:math';

import '../music_library/music_pick.dart';

/// One alarm as `alarms.list` stores it. Times are local wall time; the
/// ring moments are worked out against the device clock whenever they are
/// needed, so a time zone or a DST change moves them with the wall.
class Alarm {
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.days = const [],
    this.date,
    this.label = '',
    this.tone = '',
    this.sunrise = false,
    this.on = true,
    this.ease,
    this.speak = false,
    this.phrase = '',
    this.music,
    this.noMusic = false,
  });

  final String id;
  final int hour, minute;

  /// Weekdays it repeats on, 0 = Sunday. Empty rings once, on [date].
  final List<int> days;

  /// The day a one time alarm rings, `yyyy-MM-dd`. Null on a repeating
  /// alarm, and on a one time alarm that is off.
  final String? date;
  final String label;

  /// Empty follows the default tone; `builtin` is the built-in alarm;
  /// anything else is a file in the sounds folder.
  final String tone;
  final bool sunrise, on;

  /// Whether the ring starts quiet and grows to the alarm volume; null
  /// follows the Ease in the volume default.
  final bool? ease;

  /// Say [phrase] between the rings.
  final bool speak;

  /// What to say; empty follows the Phrase default.
  final String phrase;

  /// Music from the library to ring with instead of the tone, its own.
  /// Null follows the Alarm music default unless [noMusic]. The tone
  /// rings when the music cannot play.
  final MusicPick? music;

  /// Rings the tone, whatever the Alarm music default is.
  final bool noMusic;

  /// What it rings with: its own music, none, or the default [fallback].
  MusicPick? musicWith(MusicPick? fallback) =>
      noMusic ? null : music ?? fallback;

  bool get repeats => days.isNotEmpty;

  String get time =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Alarm copyWith({
    int? hour,
    int? minute,
    List<int>? days,
    String? Function()? date,
    String? label,
    String? tone,
    bool? sunrise,
    bool? on,
    bool? Function()? ease,
    bool? speak,
    String? phrase,
    MusicPick? Function()? music,
    bool? noMusic,
  }) => Alarm(
    id: id,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    days: days ?? this.days,
    date: date != null ? date() : this.date,
    label: label ?? this.label,
    tone: tone ?? this.tone,
    sunrise: sunrise ?? this.sunrise,
    on: on ?? this.on,
    ease: ease != null ? ease() : this.ease,
    speak: speak ?? this.speak,
    phrase: phrase ?? this.phrase,
    music: music != null ? music() : this.music,
    noMusic: noMusic ?? this.noMusic,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'time': time,
    'days': days,
    if (date != null) 'date': date,
    'label': label,
    'tone': tone,
    'sunrise': sunrise,
    'on': on,
    if (ease != null) 'ease': ease,
    'speak': speak,
    'phrase': phrase,
    if (noMusic)
      'music': 'none'
    else if (music != null)
      'music': music!.toJson(),
  };

  /// Null for anything that is not an alarm, so one bad entry never takes
  /// the list down with it.
  static Alarm? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final time = RegExp(
      r'^([01]\d|2[0-3]):([0-5]\d)$',
    ).firstMatch('${raw['time'] ?? ''}');
    if (time == null) return null;
    final id = '${raw['id'] ?? ''}'.trim();
    final days = <int>{
      for (final d in (raw['days'] is List ? raw['days'] as List : const []))
        if (d is num && d >= 0 && d <= 6) d.toInt(),
    }.toList()..sort();
    final date = '${raw['date'] ?? ''}';
    return Alarm(
      id: id.isEmpty ? newAlarmId() : id,
      hour: int.parse(time.group(1)!),
      minute: int.parse(time.group(2)!),
      days: days,
      date: RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ? date : null,
      label: '${raw['label'] ?? ''}'.trim(),
      tone: '${raw['tone'] ?? ''}'.trim(),
      sunrise: raw['sunrise'] == true,
      on: raw['on'] != false,
      ease: raw['ease'] is bool ? raw['ease'] as bool : null,
      speak: raw['speak'] == true,
      phrase: '${raw['phrase'] ?? ''}'.trim(),
      music: MusicPick.fromJson(raw['music']),
      noMusic: raw['music'] == 'none',
    );
  }
}

final _random = Random();

/// A short id that names an alarm across both surfaces and the runtime
/// state. Random, not a counter, so two surfaces adding at once never
/// collide.
String newAlarmId() => List.generate(
  8,
  (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[_random.nextInt(36)],
).join();

List<Alarm> decodeAlarms(String json) {
  try {
    final raw = jsonDecode(json);
    if (raw is! List) return const [];
    final seen = <String>{};
    return [
      for (final item in raw)
        if (Alarm.fromJson(item) case final alarm? when seen.add(alarm.id))
          alarm,
    ];
  } catch (_) {
    return const [];
  }
}

String encodeAlarms(List<Alarm> alarms) =>
    jsonEncode([for (final a in alarms) a.toJson()]);

/// By time of day, the order the list shows them in.
List<Alarm> sortAlarms(List<Alarm> alarms) => [...alarms]
  ..sort((a, b) {
    final t = (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
    return t != 0 ? t : a.id.compareTo(b.id);
  });

String dateKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

DateTime? _parseDate(String? key) {
  if (key == null) return null;
  final parts = key.split('-');
  if (parts.length != 3) return null;
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

DateTime _at(DateTime day, Alarm alarm) =>
    DateTime(day.year, day.month, day.day, alarm.hour, alarm.minute);

/// The day a one time alarm set now rings: today if its time is still
/// ahead, else tomorrow.
String onceDate(int hour, int minute, DateTime now) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  return dateKey(
    today.isAfter(now)
        ? today
        : DateTime(now.year, now.month, now.day + 1, hour, minute),
  );
}

/// The next time [alarm] rings strictly after [now], or null when it is
/// off or a one time alarm whose day is behind.
DateTime? nextRing(Alarm alarm, DateTime now) {
  if (!alarm.on) return null;
  if (!alarm.repeats) {
    final day = _parseDate(alarm.date);
    if (day == null) return null;
    final at = _at(day, alarm);
    return at.isAfter(now) ? at : null;
  }
  for (var d = 0; d <= 7; d++) {
    final at = _at(DateTime(now.year, now.month, now.day + d), alarm);
    if (at.isAfter(now) && alarm.days.contains(at.weekday % 7)) return at;
  }
  return null;
}

/// The latest time [alarm] was due at or before [now], or null.
DateTime? lastRing(Alarm alarm, DateTime now) {
  if (!alarm.on) return null;
  if (!alarm.repeats) {
    final day = _parseDate(alarm.date);
    if (day == null) return null;
    final at = _at(day, alarm);
    return at.isAfter(now) ? null : at;
  }
  for (var d = 0; d <= 7; d++) {
    final at = _at(DateTime(now.year, now.month, now.day - d), alarm);
    if (!at.isAfter(now) && alarm.days.contains(at.weekday % 7)) return at;
  }
  return null;
}

/// The next ring across every alarm: which one and when.
({Alarm alarm, DateTime at})? nextOf(List<Alarm> alarms, DateTime now) {
  ({Alarm alarm, DateTime at})? best;
  for (final alarm in alarms) {
    final at = nextRing(alarm, now);
    if (at != null && (best == null || at.isBefore(best.at))) {
      best = (alarm: alarm, at: at);
    }
  }
  return best;
}

/// The variables a phrase can use, as the phrase hint lists them.
const alarmPhraseVariables =
    '{label}, {name}, {time}, {hour}, {minute}, {date}, {day}, {dayofmonth}, '
    '{month}, {year}';

/// [template] with its variables filled in: the words an alarm says between
/// its rings. A blank label or name leaves no stray punctuation or spaces
/// behind.
String fillAlarmPhrase(
  String template, {
  required String label,
  required String name,
  required String time,
  required String hour,
  required String minute,
  required String date,
  required String day,
  required String dayOfMonth,
  required String month,
  required String year,
}) {
  final words = {
    'label': label.trim(),
    'name': name.trim(),
    'time': time,
    'hour': hour,
    'minute': minute,
    'date': date,
    'day': day,
    'dayofmonth': dayOfMonth,
    'month': month,
    'year': year,
  };
  final blanks = [
    for (final key in const ['label', 'name'])
      if (words[key]!.isEmpty) key,
  ];
  var text = template;
  if (blanks.isNotEmpty) {
    // The gap goes with the weaker of the marks around it, so
    // "Hi, {label}. It's 7" says "Hi. It's 7", and nothing else the phrase
    // says is touched.
    text = text
        .replaceAllMapped(
          RegExp('([.,!?;:]?)\\s*\\{(?:${blanks.join('|')})\\}\\s*([.,!?;:]?)'),
          (m) {
            final before = m[1]!, after = m[2]!;
            if (after.isNotEmpty) return after;
            return before.isEmpty ? ' ' : '$before ';
          },
        )
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim()
        .replaceFirst(RegExp(r'^[.,;:]\s*'), '');
  }
  // One pass, so a label that reads like a variable stays as it is.
  return text
      .replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => words[m[1]] ?? m[0]!)
      .trim();
}

/// Which days a repeat covers, in words: Every day, Weekdays, Weekends or
/// null for any other set (the caller lists the day names).
String? repeatWord(List<int> days) {
  final set = days.toSet();
  if (set.length == 7) return 'Every day';
  if (set.length == 5 && !set.contains(0) && !set.contains(6)) {
    return 'Weekdays';
  }
  if (set.length == 2 && set.contains(0) && set.contains(6)) {
    return 'Weekends';
  }
  return null;
}
