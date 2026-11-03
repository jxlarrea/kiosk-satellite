import '../../core/logging.dart';
import 'calendar_model.dart';
import 'calendar_requests.dart';

/// Home Assistant's CalendarEntityFeature bits: what a calendar's
/// integration lets anyone do to it.
const calendarCreates = 1;
const calendarDeletes = 2;
const calendarUpdates = 4;

enum CalendarEditFailure {
  /// The calendar's integration takes no changes, as a holiday calendar.
  readOnly,

  /// The event is no longer on the calendar: changed or deleted elsewhere
  /// since the screen drew it.
  gone,

  /// The kiosk's Home Assistant user may not change the calendar.
  notAllowed,

  /// Home Assistant turned the write down for another reason or could not
  /// be reached.
  refused,
}

/// Why an edit stopped, and on which calendar.
class CalendarEditError implements Exception {
  const CalendarEditError(this.calendar, this.failure, [this.cause]);

  /// The entity it stopped on, or null when no calendar could be read.
  final String? calendar;
  final CalendarEditFailure failure;
  final Object? cause;

  @override
  String toString() => 'CalendarEditError($calendar, ${failure.name}: $cause)';
}

/// Adding, changing and deleting events from the calendar's own screen.
/// An event on several calendars is one event on the screen and one copy
/// in each calendar, so every write goes to each copy.
class CalendarEdits {
  CalendarEdits(this._store, [this._log]);

  final CalendarStore _store;
  final Logger? _log;

  /// A new event on each of [calendars]. Two or more give the event the
  /// screen draws once, split between their colors.
  Future<void> add(List<String> calendars, CalendarDraft draft) async {
    for (final calendar in calendars) {
      await _guard(calendar, () => _store.createEvent(calendar, draft));
    }
    _log?.info(
      'calendar',
      'added "${draft.summary}" on ${calendars.join(', ')}',
    );
  }

  /// [event] takes the shape of [draft] on the [calendars] it should be on:
  /// the ones it stays on are changed, a calendar added gets a copy and one
  /// taken out loses its copy. [scope] is `this` or `following` for a
  /// repeating event.
  Future<void> change(
    CalendarEvent event,
    CalendarDraft draft, {
    required List<String> calendars,
    String scope = 'this',
  }) async {
    final copies = await _copies(event);
    // One day of a series keeps the series' rule, so it goes without one,
    // and so does a copy added for that day alone.
    final oneDay = scope == 'this' && event.recurrenceId != null;
    final shape = oneDay ? _withoutRule(draft) : draft;
    for (final MapEntry(key: calendar, value: copy) in copies.entries) {
      if (!calendars.contains(calendar)) continue;
      await _guard(
        calendar,
        () => _store.updateEvent(calendar, copy, shape, scope: scope),
      );
    }
    for (final calendar in calendars) {
      if (copies.containsKey(calendar)) continue;
      await _guard(calendar, () => _store.createEvent(calendar, shape));
    }
    for (final MapEntry(key: calendar, value: copy) in copies.entries) {
      if (calendars.contains(calendar)) continue;
      await _guard(calendar, () => _store.deleteEvent(calendar, copy, scope));
    }
    _log?.info(
      'calendar',
      'changed "${event.summary}" ($scope) on ${calendars.join(', ')}',
    );
  }

  /// [event] off every calendar it is on. [scope] is `this`, `following`
  /// or `all` for a repeating event.
  Future<void> remove(CalendarEvent event, String scope) async {
    final copies = await _copies(event);
    for (final MapEntry(key: calendar, value: copy) in copies.entries) {
      await _guard(calendar, () => _store.deleteEvent(calendar, copy, scope));
    }
    _log?.info(
      'calendar',
      'deleted "${event.summary}" ($scope) from ${copies.keys.join(', ')}',
    );
  }

  /// Each calendar's own copy of [event], read fresh from Home Assistant:
  /// the events the screen draws may come from a poll, which leaves out
  /// the ids a write needs.
  Future<Map<String, CalendarEvent>> _copies(CalendarEvent event) async {
    final Map<String, List<CalendarEvent>> raw;
    try {
      raw = await _store.readEvents(
        dateOnly(event.start),
        addDays(dateOnly(event.end), 1),
      );
    } catch (e) {
      throw CalendarEditError(null, CalendarEditFailure.refused, e);
    }
    final out = <String, CalendarEvent>{};
    for (final calendar in event.calendars) {
      final copy = calendarCopyOn(raw[calendar] ?? const [], event);
      if (copy == null) {
        throw CalendarEditError(calendar, CalendarEditFailure.gone);
      }
      if (copy.uid == null) {
        throw CalendarEditError(calendar, CalendarEditFailure.readOnly);
      }
      out[calendar] = copy;
    }
    return out;
  }

  Future<void> _guard(String calendar, Future<void> Function() write) async {
    try {
      await write();
    } catch (e) {
      _log?.warn('calendar', 'writing to $calendar failed: $e');
      final text = '$e'.toLowerCase();
      throw CalendarEditError(
        calendar,
        text.contains('not supported') || text.contains('not_supported')
            ? CalendarEditFailure.readOnly
            : text.contains('unauthorized') || text.contains('permission')
            ? CalendarEditFailure.notAllowed
            : CalendarEditFailure.refused,
        e,
      );
    }
  }

  static CalendarDraft _withoutRule(CalendarDraft d) => CalendarDraft(
    summary: d.summary,
    start: d.start,
    end: d.end,
    allDay: d.allDay,
    description: d.description,
    location: d.location,
  );
}

const _weekdayCodes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// The Repeat choice an RRULE is, for an event starting on [start]: none,
/// daily, weekdays, weekly, monthly or yearly, or custom when the choices
/// cannot say it (every Monday and Thursday, every other week).
String calendarRepeatPreset(String? rule, DateTime start) {
  if (rule == null || rule.trim().isEmpty) return 'none';
  final parts = <String, String>{
    for (final part in rule.toUpperCase().replaceFirst('RRULE:', '').split(';'))
      if (part.split('=') case [final key, final value])
        key.trim(): value.trim(),
  }..remove('WKST');
  if (parts['INTERVAL'] == '1') parts.remove('INTERVAL');
  final freq = parts.remove('FREQ');
  switch (freq) {
    case 'DAILY':
      return parts.isEmpty ? 'daily' : 'custom';
    case 'WEEKLY':
      final days = parts.remove('BYDAY')?.split(',').toSet();
      if (parts.isNotEmpty) return 'custom';
      if (days == null ||
          (days.length == 1 &&
              days.first == _weekdayCodes[start.weekday - 1])) {
        return 'weekly';
      }
      final workweek = _weekdayCodes.take(5).toSet();
      return days.length == 5 && days.containsAll(workweek)
          ? 'weekdays'
          : 'custom';
    case 'MONTHLY':
      final day = parts.remove('BYMONTHDAY');
      return parts.isEmpty && (day == null || day == '${start.day}')
          ? 'monthly'
          : 'custom';
    case 'YEARLY':
      return parts.isEmpty ? 'yearly' : 'custom';
  }
  return 'custom';
}

/// The RRULE a Repeat choice writes. Custom keeps [original], the rule
/// the event came with. The weekly, monthly and yearly rules repeat on
/// the start's day, so moving the start moves them.
String? calendarRepeatRule(String preset, String? original) => switch (preset) {
  'daily' => 'FREQ=DAILY',
  'weekdays' => 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
  'weekly' => 'FREQ=WEEKLY',
  'monthly' => 'FREQ=MONTHLY',
  'yearly' => 'FREQ=YEARLY',
  'custom' => original,
  _ => null,
};
