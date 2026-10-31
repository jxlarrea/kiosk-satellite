import 'dart:convert';

import 'package:flutter/foundation.dart';

/// One Home Assistant calendar the kiosk shows, as Settings > Calendar
/// keeps it: the entity, the name its chip wears, its color as "r,g,b"
/// and the person whose picture stands in for the initial.
@immutable
class CalendarSource {
  const CalendarSource({
    required this.entity,
    required this.name,
    required this.color,
    this.person = '',
    this.on = true,
  });

  final String entity;
  final String name;
  final String color;
  final String person;

  /// Off keeps the calendar in the list without showing it anywhere.
  final bool on;

  /// The first letter of the name, for the avatar disc.
  String get initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  CalendarSource copyWith({
    String? name,
    String? color,
    String? person,
    bool? on,
  }) => CalendarSource(
    entity: entity,
    name: name ?? this.name,
    color: color ?? this.color,
    person: person ?? this.person,
    on: on ?? this.on,
  );

  Map<String, Object?> toJson() => {
    'entity': entity,
    'name': name,
    'color': color,
    if (person.isNotEmpty) 'person': person,
    'on': on,
  };

  static CalendarSource? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final entity = '${raw['entity'] ?? ''}'.trim();
    if (!entity.startsWith('calendar.')) return null;
    final color = '${raw['color'] ?? ''}'.trim();
    return CalendarSource(
      entity: entity,
      name: '${raw['name'] ?? ''}'.trim(),
      color: parseRgb(color) == null ? calendarPalette.first.rgb : color,
      person: '${raw['person'] ?? ''}'.trim(),
      on: raw['on'] != false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarSource &&
      other.entity == entity &&
      other.name == name &&
      other.color == color &&
      other.person == person &&
      other.on == on;

  @override
  int get hashCode => Object.hash(entity, name, color, person, on);
}

/// The colors a new calendar is given in turn, the canvas's palette. Any
/// other color can still be picked by hand.
const calendarPalette = <({String name, String rgb})>[
  (name: 'Teal', rgb: '72,130,132'),
  (name: 'Rust', rgb: '192,97,58'),
  (name: 'Blue', rgb: '76,111,165'),
  (name: 'Plum', rgb: '138,90,156'),
  (name: 'Ochre', rgb: '168,122,31'),
  (name: 'Sage', rgb: '86,129,79'),
  (name: 'Rose', rgb: '181,87,122'),
  (name: 'Slate', rgb: '107,114,128'),
];

/// The first palette color no calendar wears yet, or the next one around
/// once all eight are taken.
String nextCalendarColor(List<CalendarSource> calendars) {
  final used = {for (final c in calendars) c.color};
  for (final p in calendarPalette) {
    if (!used.contains(p.rgb)) return p.rgb;
  }
  return calendarPalette[calendars.length % calendarPalette.length].rgb;
}

/// "r,g,b" as its three channels, or null when it is not one.
(int, int, int)? parseRgb(String raw) {
  final parts = raw.split(',').map((p) => int.tryParse(p.trim())).toList();
  if (parts.length != 3 || parts.any((p) => p == null || p < 0 || p > 255)) {
    return null;
  }
  return (parts[0]!, parts[1]!, parts[2]!);
}

List<CalendarSource> decodeCalendars(String json) {
  try {
    final raw = jsonDecode(json);
    if (raw is! List) return const [];
    final seen = <String>{};
    return [
      for (final item in raw)
        if (CalendarSource.fromJson(item) case final c?)
          if (seen.add(c.entity)) c,
    ];
  } catch (_) {
    return const [];
  }
}

String encodeCalendars(List<CalendarSource> calendars) =>
    jsonEncode([for (final c in calendars) c.toJson()]);

/// The entities hidden with their chips on this kiosk.
Set<String> decodeHidden(String json) {
  try {
    final raw = jsonDecode(json);
    if (raw is! List) return const {};
    return {for (final e in raw) '$e'};
  } catch (_) {
    return const {};
  }
}

/// One event as the kiosk draws it. An event on several calendars (an
/// invite on two people's calendars, say) is one event with every one of
/// them in [calendars], in the order Settings lists them.
@immutable
class CalendarEvent {
  const CalendarEvent({
    required this.summary,
    required this.start,
    required this.end,
    required this.allDay,
    required this.calendars,
    this.description = '',
    this.location = '',
    this.uid,
    this.recurrenceId,
    this.rrule,
  });

  final String summary;

  /// Local time. An all-day event runs from midnight on its first day to
  /// midnight after its last, the end exclusive the way Home Assistant
  /// sends it.
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final List<String> calendars;
  final String description;
  final String location;
  final String? uid;
  final String? recurrenceId;
  final String? rrule;

  /// Stable across refreshes, for keys and for finding an event again.
  String get key =>
      '${uid ?? summary}|${recurrenceId ?? start.toIso8601String()}';

  CalendarEvent withCalendars(List<String> calendars) => CalendarEvent(
    summary: summary,
    start: start,
    end: end,
    allDay: allDay,
    calendars: calendars,
    description: description,
    location: location,
    uid: uid,
    recurrenceId: recurrenceId,
    rrule: rrule,
  );

  /// Whether any part of the event falls on [day] (a local date).
  bool occursOn(DateTime day) {
    final from = dateOnly(day);
    final to = addDays(from, 1);
    if (allDay) return start.isBefore(to) && end.isAfter(from);
    // A timed event that ends at midnight does not spill into the next day.
    return start.isBefore(to) && end.isAfter(from) ||
        (start == end && !start.isBefore(from) && start.isBefore(to));
  }

  /// Whether the event spans past one day.
  bool get multiDay {
    if (allDay) return daysBetween(start, end) > 1;
    final last = end.subtract(const Duration(microseconds: 1));
    return dateOnly(start) != dateOnly(last);
  }
}

DateTime dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

/// [days] later, by the calendar rather than by 24 hour steps, so a daylight
/// saving change never lands an hour off midnight.
DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

int daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// The first day of [day]'s week, the week starting on [firstWeekday]
/// (0 = Sunday, as MaterialLocalizations counts).
DateTime weekStart(DateTime day, int firstWeekday) {
  final weekday = day.weekday % 7;
  return addDays(dateOnly(day), -((weekday - firstWeekday) % 7));
}

/// The first day of the grid the month view draws for [month]: the week
/// that holds its first day.
DateTime monthGridStart(DateTime month, int firstWeekday) =>
    weekStart(DateTime(month.year, month.month), firstWeekday);

/// How many weeks the month grid needs for [month]: 4 to 6.
int monthGridWeeks(DateTime month, int firstWeekday) {
  final first = monthGridStart(month, firstWeekday);
  final last = DateTime(month.year, month.month + 1, 0);
  return (daysBetween(first, last) ~/ 7) + 1;
}

/// A Home Assistant date or date-time as local time: `2026-10-19` (all day)
/// or `2026-10-19T16:00:00-05:00`.
DateTime? _parseWhen(Object? raw) {
  if (raw is Map) raw = raw['dateTime'] ?? raw['date'];
  if (raw is! String || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  // A bare date is a local date; one with a zone becomes device time.
  return raw.length <= 10
      ? DateTime(parsed.year, parsed.month, parsed.day)
      : parsed.toLocal();
}

bool _isDate(Object? raw) {
  if (raw is Map) return raw['dateTime'] == null && raw['date'] != null;
  return raw is String && raw.length <= 10;
}

/// One event from `calendar/event/subscribe` or `calendar.get_events`.
CalendarEvent? parseHaEvent(Object? raw, String calendar) {
  if (raw is! Map) return null;
  final start = _parseWhen(raw['start']);
  var end = _parseWhen(raw['end']);
  if (start == null) return null;
  final allDay = _isDate(raw['start']);
  end ??= allDay ? addDays(start, 1) : start;
  if (end.isBefore(start)) end = start;
  if (allDay && !end.isAfter(start)) end = addDays(start, 1);
  String? text(Object? v) {
    final s = v == null ? '' : '$v'.trim();
    return s.isEmpty ? null : s;
  }

  return CalendarEvent(
    summary: text(raw['summary']) ?? '',
    start: start,
    end: end,
    allDay: allDay,
    calendars: [calendar],
    description: text(raw['description']) ?? '',
    location: text(raw['location']) ?? '',
    uid: text(raw['uid']),
    recurrenceId: text(raw['recurrence_id']),
    rrule: text(raw['rrule']),
  );
}

/// Every calendar's events as one list. An event on several calendars
/// comes out once with all of them, matched by its uid (an invite keeps
/// the organizer's iCalendar UID on every copy) or, when either copy has
/// none, by its title, start and end. [order] is the calendars as Settings
/// lists them; it sets the order of each event's calendars.
List<CalendarEvent> mergeEvents(
  Map<String, List<CalendarEvent>> byCalendar,
  List<String> order,
) {
  final merged = <CalendarEvent>[];
  final byUid = <String, int>{};
  final byShape = <String, int>{};
  final rank = {for (var i = 0; i < order.length; i++) order[i]: i};
  final calendars = [
    for (final id in order)
      if (byCalendar.containsKey(id)) id,
    for (final id in byCalendar.keys)
      if (!rank.containsKey(id)) id,
  ];
  for (final calendar in calendars) {
    for (final event in byCalendar[calendar]!) {
      final shape =
          '${event.summary.toLowerCase()}|${event.start.toIso8601String()}|'
          '${event.end.toIso8601String()}|${event.allDay}';
      final uidKey = event.uid == null
          ? null
          : '${event.uid}|${event.recurrenceId ?? event.start.toIso8601String()}';
      final at = (uidKey == null ? null : byUid[uidKey]) ?? byShape[shape];
      if (at != null) {
        final existing = merged[at];
        if (!existing.calendars.contains(calendar)) {
          merged[at] = existing.withCalendars([
            ...existing.calendars,
            calendar,
          ]);
        }
        continue;
      }
      merged.add(event);
      if (uidKey != null) byUid[uidKey] = merged.length - 1;
      byShape[shape] = merged.length - 1;
    }
  }
  merged.sort(compareEvents);
  return merged;
}

/// All-day events first, then by start, then the longer one first.
int compareEvents(CalendarEvent a, CalendarEvent b) {
  if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
  final byStart = a.start.compareTo(b.start);
  if (byStart != 0) return byStart;
  final byEnd = b.end.compareTo(a.end);
  if (byEnd != 0) return byEnd;
  return a.summary.compareTo(b.summary);
}

/// The events that fall on [day], in drawing order.
List<CalendarEvent> eventsOn(List<CalendarEvent> events, DateTime day) => [
  for (final e in events)
    if (e.occursOn(day)) e,
];

/// The events [hidden] leaves something of: an event goes only when every
/// calendar it is on is hidden, and the hidden ones drop out of the split.
List<CalendarEvent> visibleEvents(
  List<CalendarEvent> events,
  Set<String> hidden,
) {
  if (hidden.isEmpty) return events;
  return [
    for (final e in events)
      if (e.calendars.where((c) => !hidden.contains(c)).toList() case final left
          when left.isNotEmpty)
        left.length == e.calendars.length ? e : e.withCalendars(left),
  ];
}

/// Where each timed event of one day sits side by side: its column and how
/// many columns its group of overlapping events shares.
List<({CalendarEvent event, int column, int columns})> layoutColumns(
  List<CalendarEvent> timed,
) {
  final sorted = [...timed]..sort(compareEvents);
  final out = <({CalendarEvent event, int column, int columns})>[];
  var group = <({CalendarEvent event, int column})>[];
  DateTime? groupEnd;
  void flush() {
    final columns = group.isEmpty
        ? 1
        : group.map((g) => g.column).reduce((a, b) => a > b ? a : b) + 1;
    for (final g in group) {
      out.add((event: g.event, column: g.column, columns: columns));
    }
    group = [];
    groupEnd = null;
  }

  for (final event in sorted) {
    if (groupEnd != null && !event.start.isBefore(groupEnd!)) flush();
    final busy = {
      for (final g in group)
        if (g.event.end.isAfter(event.start)) g.column,
    };
    var column = 0;
    while (busy.contains(column)) {
      column++;
    }
    group.add((event: event, column: column));
    if (groupEnd == null || event.end.isAfter(groupEnd!)) groupEnd = event.end;
  }
  flush();
  return out;
}

/// The events still to come today after [now]: timed ones that have not
/// ended, in start order. [allDay] adds today's all-day events, first the
/// way the calendar draws them, for the Up next widget. The Schedule view
/// shows those under the date instead. [days] past 1 adds the events that
/// start on the days after today, each day's all-day ones first, for the
/// widget too.
List<CalendarEvent> upNext(
  List<CalendarEvent> events,
  DateTime now, {
  bool allDay = false,
  int days = 1,
}) => [
  for (final e in eventsOn(events, now))
    if (e.allDay ? allDay : e.end.isAfter(now)) e,
  for (var i = 1; i < days; i++)
    for (final e in eventsOn(events, addDays(now, i)))
      // An event that started earlier is already listed on its first day.
      if ((allDay || !e.allDay) && !e.start.isBefore(addDays(now, i))) e,
];

/// The recurrence frequency an rrule names (DAILY, WEEKLY, MONTHLY or
/// YEARLY), or null.
String? rruleFrequency(String? rrule) {
  if (rrule == null) return null;
  final m = RegExp(r'FREQ=([A-Z]+)').firstMatch(rrule.toUpperCase());
  return m?.group(1);
}
