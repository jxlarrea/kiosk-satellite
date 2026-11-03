import '../alarms/alarm_requests.dart' show parseAlarmTime;
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import '../voice/voice_requests_manager.dart' show normalizeKioskName;
import 'calendar_manager.dart' show CalendarHighlight;
import 'calendar_model.dart';

/// What [CalendarRequests] needs from the calendar: the calendars, a read,
/// the three writes and the screen. [CalendarManager] is the real one.
abstract interface class CalendarStore {
  List<CalendarSource> get enabled;

  Future<Map<String, List<CalendarEvent>>> readEvents(
    DateTime from,
    DateTime to,
  );

  Future<void> createEvent(String entity, CalendarDraft draft);

  /// [scope] is `this` (the one day) or `following` (that day and the
  /// ones after it) for a repeating event.
  Future<void> updateEvent(
    String entity,
    CalendarEvent event,
    CalendarDraft draft, {
    String scope = 'this',
  });

  Future<void> deleteEvent(String entity, CalendarEvent event, String scope);

  Future<void> show({
    required String view,
    required DateTime date,
    CalendarHighlight? highlight,
  });
}

/// An event to write: a new one or the new shape of an existing one.
class CalendarDraft {
  const CalendarDraft({
    required this.summary,
    required this.start,
    required this.end,
    required this.allDay,
    this.description = '',
    this.location = '',
    this.rrule,
  });

  final String summary;

  /// Local time. An all-day event's end is the day after its last, as
  /// Home Assistant takes it.
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final String description;
  final String location;

  /// How it repeats, as an iCalendar RRULE without the `RRULE:` prefix
  /// (`FREQ=WEEKLY`). Null for one that does not.
  final String? rrule;

  /// The `event` of `calendar/event/create` and `calendar/event/update`.
  Map<String, Object?> toHa() => {
    'summary': summary,
    'dtstart': allDay ? haDate(start) : haDateTime(start),
    'dtend': allDay ? haDate(end) : haDateTime(end),
    if (description.isNotEmpty) 'description': description,
    if (location.isNotEmpty) 'location': location,
    if (rrule case final r? when r.isNotEmpty) 'rrule': r,
  };
}

String _two(int n) => n.toString().padLeft(2, '0');

/// 2026-10-22
String haDate(DateTime t) => '${t.year}-${_two(t.month)}-${_two(t.day)}';

/// 2026-10-22T16:00:00-05:00, the kiosk's own offset, so Home Assistant
/// reads the time the person meant even in another time zone.
String haDateTime(DateTime t) {
  final offset = t.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final minutes = offset.inMinutes.abs();
  return '${haDate(t)}T${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}'
      '$sign${_two(minutes ~/ 60)}:${_two(minutes % 60)}';
}

/// A time the script sends: `2026-10-22` (a day), `2026-10-22 16:00` or
/// an ISO date-time. With a [base] day, a bare `16:00` or `4 pm` is that
/// time on it. Null when it is none of these.
({DateTime at, bool hasTime})? parseWhen(Object? raw, {DateTime? base}) {
  final s = '${raw ?? ''}'.trim();
  if (s.isEmpty) return null;
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
    final d = DateTime.tryParse(s);
    return d == null
        ? null
        : (at: DateTime(d.year, d.month, d.day), hasTime: false);
  }
  if (base != null) {
    final time = parseAlarmTime(s);
    if (time != null) {
      return (
        at: DateTime(base.year, base.month, base.day, time.hour, time.minute),
        hasTime: true,
      );
    }
  }
  final parsed = DateTime.tryParse(s.replaceFirst(' ', 'T'));
  if (parsed == null) return null;
  return (at: parsed.isUtc ? parsed.toLocal() : parsed, hasTime: true);
}

/// The calendar by voice. The Kiosk Satellite calendar script (a
/// blueprint in this repository) is exposed to Assist, so any LLM
/// conversation agent can call it in any language. The voice requests
/// manager hears it and, on the kiosk being asked, runs it through the
/// `calendarVoiceRequest` command, which lands in [handle].
///
/// The kiosk does the work, not the script: it knows each calendar's name
/// and person, so "add soccer for Leo" needs no setup in the blueprint,
/// and Home Assistant only changes and deletes events over its websocket.
class CalendarRequests {
  CalendarRequests(this._settings, this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SettingsManager _settings;
  final CalendarStore _store;
  final DateTime Function() _clock;

  /// How far ahead a search by title looks when no day is named.
  static const searchDays = 180;

  /// Applies one request and says what came of it, in the shape the script
  /// returns to the LLM. One at a time, as with alarms: "cancel the
  /// dentist and add it on Friday" arrives as two calls at once.
  Future<Map<String, Object?>> handle(Map<String, Object?> data) {
    final done = _queue.then((_) => _apply(data));
    _queue = done.then((_) {}, onError: (_) {});
    return done;
  }

  Future<void> _queue = Future.value();

  // Every answer carries the kiosk's date and time, so an agent that got
  // the day wrong can see it.
  Map<String, Object?> _fail(String error, [Map<String, Object?>? more]) => {
    'ok': false,
    'kiosk': _settings.get(defs.deviceName),
    'now': _when(_clock(), withTime: true),
    'error': error,
    ...?more,
  };

  Map<String, Object?> _ok(String result, Map<String, Object?> more) => {
    'ok': true,
    'kiosk': _settings.get(defs.deviceName),
    'now': _when(_clock(), withTime: true),
    'result': result,
    ...more,
  };

  /// A new event, a move or a change to one before today is almost always
  /// an agent that got the year or the week wrong, so it is sent back to
  /// check.
  Map<String, Object?>? _past(DateTime at) {
    final today = dateOnly(_clock());
    if (!dateOnly(at).isBefore(today)) return null;
    return _fail(
      '${_when(at, withTime: false)} is in the past. Today is '
      '${_when(today, withTime: false)}: check the date',
    );
  }

  Future<Map<String, Object?>> _apply(Map<String, Object?> data) async {
    final action = '${data['action'] ?? ''}'.trim().toLowerCase();
    if (_store.enabled.isEmpty) {
      return _fail(
        'this kiosk has no calendars. Add them under Settings, Calendar',
      );
    }
    try {
      return switch (action) {
        'add' => await _add(data),
        'find' => await _find(data),
        'change' => await _change(data),
        'cancel' => await _cancel(data),
        'show' => await _show(data),
        _ => _fail('action must be add, find, change, cancel or show'),
      };
    } catch (e) {
      return _fail(_haError(e));
    }
  }

  /// Opens the calendar for a request heard on this kiosk, unless the
  /// script's Show on the kiosk is off.
  bool _shows(Map<String, Object?> data) =>
      data['voiceTurn'] == true &&
      '${data['show'] ?? true}'.toLowerCase() != 'false';

  // ── Add ───────────────────────────────────────────────────────────────

  Future<Map<String, Object?>> _add(Map<String, Object?> data) async {
    var title = '${data['title'] ?? ''}'.trim();
    if (title.isEmpty) return _fail('title is required to add an event');
    // Some agents send an add's times in the change fields.
    String field(String name) {
      final own = '${data[name] ?? ''}'.trim();
      return own.isNotEmpty ? own : '${data['new_$name'] ?? ''}'.trim();
    }

    final start = parseWhen(field('start'));
    if (start == null) {
      return _fail('start must be yyyy-MM-dd or yyyy-MM-dd HH:mm');
    }
    if (_past(start.at) case final past?) return past;
    final people = _resolve(data['people']);
    if (people.unknown.isNotEmpty) {
      return _fail('no calendar for ${people.unknown.join(', ')}', {
        'calendars': _calendarNames(),
      });
    }
    var targets = people.found;
    if (targets.isEmpty) {
      // Some agents leave the person in the title.
      if (_ownerInTitle(title) case final owner?) {
        targets = [owner.calendar];
        title = owner.title;
      }
    }
    // Nobody named: the first calendar, the family one in most homes.
    if (targets.isEmpty) targets = [_store.enabled.first];
    final allDay = !start.hasTime;
    final end = parseWhen(field('end'), base: start.at);
    DateTime until;
    if (allDay) {
      // The last day, so one day past it.
      until = end == null ? addDays(start.at, 1) : addDays(dateOnly(end.at), 1);
    } else {
      until = end != null && end.hasTime
          ? end.at
          : start.at.add(const Duration(hours: 1));
    }
    if (!until.isAfter(start.at)) return _fail('end must be after start');
    final draft = CalendarDraft(
      summary: title,
      start: start.at,
      end: until,
      allDay: allDay,
      location: '${data['location'] ?? ''}'.trim(),
      description: '${data['description'] ?? ''}'.trim(),
    );
    // An agent that retries must not add it twice.
    final day = dateOnly(start.at);
    final existing = await _store.readEvents(day, addDays(day, 1));
    final added = <String>[], already = <String>[], failed = <String>[];
    for (final c in targets) {
      final same = (existing[c.entity] ?? const []).any(
        (e) =>
            e.summary.toLowerCase() == title.toLowerCase() &&
            e.start == draft.start &&
            e.allDay == allDay,
      );
      if (same) {
        already.add(c.entity);
        continue;
      }
      try {
        await _store.createEvent(c.entity, draft);
        added.add(c.entity);
      } catch (e) {
        failed.add('${c.name}: ${_haError(e, create: true)}');
      }
    }
    if (added.isEmpty && already.isEmpty) return _fail(failed.join('; '));
    final event = CalendarEvent(
      summary: draft.summary,
      start: draft.start,
      end: draft.end,
      allDay: allDay,
      calendars: [...added, ...already],
      location: draft.location,
    );
    if (_shows(data)) {
      await _store.show(
        view: 'day',
        date: day,
        highlight: (summary: draft.summary, start: draft.start),
      );
    }
    return _ok(added.isEmpty ? 'already_there' : 'added', {
      'event': describe(event),
      if (failed.isNotEmpty) 'failed': failed,
    });
  }

  /// "Maya's haircut" or "Haircut for Maya": the calendar the title names
  /// and the title without it, or null when it names none.
  ({CalendarSource calendar, String title})? _ownerInTitle(String title) {
    for (final pattern in [
      RegExp(r"^(.+?)['’]s\s+(.+)$"),
      RegExp(r'^(.+?)\s+for\s+(.+)$', caseSensitive: false),
    ]) {
      final m = pattern.firstMatch(title);
      if (m == null) continue;
      final possessive = pattern.pattern.startsWith('^(.+?)[');
      final name = (possessive ? m[1]! : m[2]!).trim();
      final rest = (possessive ? m[2]! : m[1]!).trim();
      final word = normalizeKioskName(name);
      if (word.isEmpty || rest.isEmpty) continue;
      for (final c in _store.enabled) {
        if (_names(c).contains(word)) {
          return (
            calendar: c,
            title: rest[0].toUpperCase() + rest.substring(1),
          );
        }
      }
    }
    return null;
  }

  // ── Find ──────────────────────────────────────────────────────────────

  Future<Map<String, Object?>> _find(Map<String, Object?> data) async {
    final title = '${data['title'] ?? ''}'.trim();
    final people = _resolve(data['people']);
    if (people.unknown.isNotEmpty) {
      return _fail('no calendar for ${people.unknown.join(', ')}', {
        'calendars': _calendarNames(),
      });
    }
    final today = dateOnly(_clock());
    final start = parseWhen(data['start']);
    final end = parseWhen(data['end'], base: start?.at);
    final from = start?.at ?? today;
    final to = end != null
        ? (end.hasTime ? end.at : addDays(dateOnly(end.at), 1))
        : start != null
        ? addDays(dateOnly(start.at), 1)
        : addDays(today, title.isEmpty ? 1 : searchDays);
    if (!to.isAfter(from)) return _fail('end must be after start');
    if (to.difference(from).inDays > 400) {
      return _fail('ask for a year or less at a time');
    }
    final raw = await _store.readEvents(from, to);
    final found = _search(raw, from, to, title, people.found);
    final shown = found.take(40).toList();
    if (_shows(data)) {
      final days = daysBetween(dateOnly(from), to);
      if (found.length == 1) {
        final e = found.single;
        await _store.show(
          view: 'day',
          date: dateOnly(e.start),
          highlight: (summary: e.summary, start: e.start),
        );
      } else if (days <= 1) {
        await _store.show(view: 'day', date: dateOnly(from));
      } else if (days <= 7) {
        await _store.show(view: 'week', date: dateOnly(from));
      } else {
        await _store.show(
          view: 'schedule',
          date: found.isEmpty ? dateOnly(from) : dateOnly(found.first.start),
        );
      }
    }
    return _ok(found.isEmpty ? 'nothing_found' : 'found', {
      'from': _when(from, withTime: start?.hasTime ?? false),
      'to': _when(
        end?.hasTime ?? false ? to : addDays(to, -1),
        withTime: end?.hasTime ?? false,
      ),
      'events': [for (final e in shown) describe(e)],
      if (found.length > shown.length) 'more': found.length - shown.length,
      // An agent that got the year wrong reads this and asks again.
      if (!to.isAfter(dateOnly(_clock())))
        'note':
            'all of this is before today, '
            '${_when(dateOnly(_clock()), withTime: false)}. If the user '
            'did not ask about the past, check the dates',
    });
  }

  /// The merged events from [from] up to [to] on [people]'s calendars (or
  /// everyone's), and with a [title], only the ones that match it best.
  List<CalendarEvent> _search(
    Map<String, List<CalendarEvent>> raw,
    DateTime from,
    DateTime to,
    String title,
    List<CalendarSource> people,
  ) {
    final order = [for (final c in _store.enabled) c.entity];
    final wanted = {for (final c in people) c.entity};
    final events = [
      for (final e in mergeEvents(raw, order))
        if (e.start.isBefore(to) &&
            (e.end.isAfter(from) || e.start == from) &&
            (wanted.isEmpty || e.calendars.any(wanted.contains)))
          e,
    ];
    // Day by day, each day's all-day events first, so the LLM reads them
    // in order.
    events.sort((a, b) {
      final day = dateOnly(a.start).compareTo(dateOnly(b.start));
      return day != 0 ? day : compareEvents(a, b);
    });
    final words = _words(title);
    if (words.isEmpty) return events;
    var best = 0;
    final scored = [
      for (final e in events)
        (
          event: e,
          score: _score(
            _words('${e.summary} ${e.location} ${e.description}'),
            words,
          ),
        ),
    ];
    for (final s in scored) {
      if (s.score > best) best = s.score;
    }
    if (best == 0) return const [];
    return [
      for (final s in scored)
        if (s.score == best) s.event,
    ];
  }

  static const _stopWords = {
    'the', 'a', 'an', 'my', 'our', 'of', 'for', 'with', 'at', 'on', 'to', //
    'and', 'in', 'event',
  };

  static List<String> _words(String text) => [
    for (final w in text.toLowerCase().split(
      RegExp(r'[^\p{L}\p{N}]+', unicode: true),
    ))
      if (w.length >= 2 && !_stopWords.contains(w)) w,
  ];

  /// How many of the [query] words the event has, a plural or a longer
  /// form of a word counting too ("practices", "soccer" in "soccerball").
  static int _score(List<String> have, List<String> query) {
    var score = 0;
    for (final q in query) {
      final hit = have.any(
        (h) =>
            h == q ||
            (q.length >= 3 && h.startsWith(q)) ||
            (h.length >= 4 && q.startsWith(h)),
      );
      if (hit) score++;
    }
    return score;
  }

  // ── Change and cancel ─────────────────────────────────────────────────

  /// The one event a change or a cancel means, with each calendar's own
  /// copy of it, or the failure to send back.
  Future<
    ({
      CalendarEvent? event,
      Map<String, CalendarEvent> copies,
      Map<String, Object?>? failure,
    })
  >
  _pick(Map<String, Object?> data, {required bool series}) async {
    const none = <String, CalendarEvent>{};
    final title = '${data['title'] ?? ''}'.trim();
    final start = parseWhen(data['start']);
    if (title.isEmpty && start == null) {
      return (
        event: null,
        copies: none,
        failure: _fail('say which event: its title, its day or both'),
      );
    }
    if (start != null) {
      if (_past(start.at) case final past?) {
        return (event: null, copies: none, failure: past);
      }
    }
    final people = _resolve(data['people']);
    if (people.unknown.isNotEmpty) {
      return (
        event: null,
        copies: none,
        failure: _fail('no calendar for ${people.unknown.join(', ')}', {
          'calendars': _calendarNames(),
        }),
      );
    }
    final today = dateOnly(_clock());
    final from = start == null ? today : dateOnly(start.at);
    final to = addDays(from, start == null ? searchDays : 1);
    final raw = await _store.readEvents(from, to);
    var found = _search(raw, from, to, title, people.found);
    if (start != null && start.hasTime) {
      final exact = [
        for (final e in found)
          if (e.start == start.at) e,
      ];
      if (exact.isNotEmpty) found = exact;
    }
    if (found.isEmpty) {
      return (event: null, copies: none, failure: _fail('no matching event'));
    }
    final uids = {for (final e in found) e.uid ?? e.summary};
    final oneSeries = found.length > 1 && uids.length == 1;
    if (found.length > 1 && !(oneSeries && series)) {
      return (
        event: null,
        copies: none,
        failure: _fail(
          oneSeries
              ? 'it repeats: ask whether they mean one day (give its start) '
                    'or every time'
              : 'several events match, ask which one',
          {
            'events': [for (final e in found.take(10)) describe(e)],
          },
        ),
      );
    }
    final event = found.first;
    final copies = <String, CalendarEvent>{};
    for (final calendar in event.calendars) {
      final copy = calendarCopyOn(raw[calendar] ?? const [], event);
      if (copy == null) continue;
      if (copy.uid == null) {
        return (
          event: null,
          copies: none,
          failure: _fail(
            '${_nameOf(calendar)} cannot change or remove events from '
            'here. Do it in the calendar app',
          ),
        );
      }
      copies[calendar] = copy;
    }
    return (event: event, copies: copies, failure: null);
  }

  Future<Map<String, Object?>> _change(Map<String, Object?> data) async {
    final picked = await _pick(data, series: false);
    if (picked.failure != null) return picked.failure!;
    final e = picked.event!;
    final newTitle = '${data['new_title'] ?? ''}'.trim();
    final newLocation = '${data['new_location'] ?? ''}'.trim();
    final newStart = parseWhen(data['new_start'], base: e.start);
    if ('${data['new_start'] ?? ''}'.trim().isNotEmpty && newStart == null) {
      return _fail('new_start must be yyyy-MM-dd, yyyy-MM-dd HH:mm or HH:mm');
    }
    final duration = e.end.difference(e.start);
    var allDay = e.allDay;
    var start = e.start;
    var end = e.end;
    if (newStart != null) {
      if (newStart.hasTime) {
        start = newStart.at;
        // An all-day event given a time becomes an hour long.
        end = start.add(allDay ? const Duration(hours: 1) : duration);
        allDay = false;
      } else if (allDay) {
        start = newStart.at;
        end = addDays(start, daysBetween(e.start, e.end));
      } else {
        // Only the day moves: the same time on the new day.
        start = DateTime(
          newStart.at.year,
          newStart.at.month,
          newStart.at.day,
          e.start.hour,
          e.start.minute,
        );
        end = start.add(duration);
      }
    }
    final newEnd = parseWhen(data['new_end'], base: start);
    if (newEnd != null) {
      if (allDay) {
        end = addDays(dateOnly(newEnd.at), 1);
      } else if (newEnd.hasTime) {
        end = newEnd.at;
      }
    }
    if (newStart == null &&
        newEnd == null &&
        newTitle.isEmpty &&
        newLocation.isEmpty) {
      return _fail('nothing to change: give a new title, start, end or place');
    }
    if (!end.isAfter(start)) return _fail('end must be after start');
    if (newStart != null) {
      if (_past(start) case final past?) return past;
    }
    final draft = CalendarDraft(
      summary: newTitle.isEmpty ? e.summary : newTitle,
      start: start,
      end: end,
      allDay: allDay,
      description: e.description,
      location: newLocation.isEmpty ? e.location : newLocation,
    );
    for (final MapEntry(key: calendar, value: copy) in picked.copies.entries) {
      try {
        await _store.updateEvent(calendar, copy, draft);
      } catch (err) {
        return _fail('${_nameOf(calendar)}: ${_haError(err, change: true)}');
      }
    }
    if (_shows(data)) {
      await _store.show(
        view: 'day',
        date: dateOnly(start),
        highlight: (summary: draft.summary, start: start),
      );
    }
    return _ok('changed', {
      'before': describe(e),
      'after': describe(
        CalendarEvent(
          summary: draft.summary,
          start: start,
          end: end,
          allDay: allDay,
          calendars: e.calendars,
          location: draft.location,
          rrule: e.rrule,
        ),
      ),
    });
  }

  Future<Map<String, Object?>> _cancel(Map<String, Object?> data) async {
    var scope = '${data['scope'] ?? ''}'.trim().toLowerCase();
    if (!const ['this', 'following', 'all'].contains(scope)) scope = 'this';
    final picked = await _pick(data, series: scope == 'all');
    if (picked.failure != null) return picked.failure!;
    final e = picked.event!;
    for (final MapEntry(key: calendar, value: copy) in picked.copies.entries) {
      try {
        await _store.deleteEvent(calendar, copy, scope);
      } catch (err) {
        return _fail('${_nameOf(calendar)}: ${_haError(err, change: true)}');
      }
    }
    if (_shows(data)) {
      await _store.show(view: 'day', date: dateOnly(e.start));
    }
    return _ok('canceled', {
      'event': describe(e),
      if (e.rrule != null) 'scope': scope,
    });
  }

  // ── Show ──────────────────────────────────────────────────────────────

  Future<Map<String, Object?>> _show(Map<String, Object?> data) async {
    var view = '${data['view'] ?? ''}'.trim().toLowerCase();
    final start = parseWhen(data['start']);
    if (!const ['day', 'week', 'month', 'schedule'].contains(view)) {
      view = start == null ? _settings.get(defs.calendarDefaultView) : 'day';
    }
    final date = start == null ? dateOnly(_clock()) : dateOnly(start.at);
    await _store.show(view: view, date: date);
    return _ok('shown', {'view': view, 'date': _when(date, withTime: false)});
  }

  // ── People and names ──────────────────────────────────────────────────

  /// The calendars a request names: by the calendar's name, its entity or
  /// its person. Everyone, all or family (with no calendar called that)
  /// is every calendar.
  ({List<CalendarSource> found, List<String> unknown}) _resolve(Object? raw) {
    final names = <String>[
      if (raw is List)
        for (final item in raw) '$item'
      else
        ...'${raw ?? ''}'.split(RegExp(r'[,;]')),
    ];
    final found = <CalendarSource>[];
    final unknown = <String>[];
    for (final name in names) {
      final plain = name.trim().replaceFirst(RegExp(r"['’]s$"), '');
      final word = normalizeKioskName(plain);
      if (word.isEmpty) continue;
      final matches = [
        for (final c in _store.enabled)
          if (_names(c).any((n) => _sameName(n, word))) c,
      ];
      if (matches.isEmpty &&
          const {'everyone', 'everybody', 'all', 'family'}.contains(word)) {
        matches.addAll(_store.enabled);
      }
      if (matches.isEmpty) {
        unknown.add(name.trim());
        continue;
      }
      for (final c in matches) {
        if (!found.contains(c)) found.add(c);
      }
    }
    return (found: found, unknown: unknown);
  }

  static List<String> _names(CalendarSource c) => [
    for (final n in [
      c.name,
      c.entity.replaceFirst('calendar.', ''),
      if (c.person.isNotEmpty) c.person.replaceFirst('person.', ''),
    ])
      if (normalizeKioskName(n).isNotEmpty) normalizeKioskName(n),
  ];

  static bool _sameName(String have, String asked) =>
      have == asked ||
      (asked.length >= 3 &&
          have.length >= 3 &&
          (have.contains(asked) || asked.contains(have)));

  List<String> _calendarNames() => [for (final c in _store.enabled) c.name];

  String _nameOf(String entity) {
    for (final c in _store.enabled) {
      if (c.entity == entity) return c.name;
    }
    return entity;
  }

  // ── What the LLM reads ────────────────────────────────────────────────

  /// An event as the LLM reads it: its title, when in the kiosk's local
  /// time with the weekday spelled out, whose it is, where and how it
  /// repeats.
  Map<String, Object?> describe(CalendarEvent e) {
    String when;
    if (e.allDay) {
      final last = addDays(e.end, -1);
      when = daysBetween(e.start, e.end) > 1
          ? '${_when(e.start, withTime: false)} to '
                '${_when(last, withTime: false)}, all day'
          : '${_when(e.start, withTime: false)}, all day';
    } else {
      final sameDay = dateOnly(e.start) == dateOnly(e.end);
      when =
          '${_when(e.start, withTime: true)} to '
          '${sameDay ? _time(e.end) : _when(e.end, withTime: true)}';
    }
    final repeats = rruleFrequency(e.rrule);
    return {
      'title': e.summary,
      'when': when,
      'for': [for (final c in e.calendars) _nameOf(c)],
      if (e.location.isNotEmpty) 'location': e.location,
      if (repeats != null) 'repeats': repeats.toLowerCase(),
    };
  }

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String _time(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

  static String _when(DateTime t, {required bool withTime}) =>
      '${_weekdays[t.weekday - 1]} ${haDate(t)}'
      '${withTime ? ' ${_time(t)}' : ''}';

  /// Home Assistant's refusal in words the LLM can pass on.
  static String _haError(Object e, {bool create = false, bool change = false}) {
    final text = '$e'.replaceFirst(RegExp(r'^(Bad state|Exception): '), '');
    final lower = text.toLowerCase();
    if (lower.contains('not supported') || lower.contains('not_supported')) {
      return create
          ? 'this calendar cannot take new events'
          : change
          ? 'this calendar cannot change or remove events'
          : text;
    }
    if (lower.contains('unauthorized') || lower.contains('permission')) {
      return 'the kiosk\'s Home Assistant user may not change this calendar';
    }
    return text;
  }
}

/// [event]'s own copy in one calendar's list, matched the way
/// [mergeEvents] matched it.
CalendarEvent? calendarCopyOn(List<CalendarEvent> list, CalendarEvent event) {
  for (final e in list) {
    if (e.uid != null && e.key == event.key) return e;
  }
  for (final e in list) {
    if (e.summary.toLowerCase() == event.summary.toLowerCase() &&
        e.start == event.start &&
        e.end == event.end &&
        e.allDay == event.allDay) {
      return e;
    }
  }
  return null;
}
