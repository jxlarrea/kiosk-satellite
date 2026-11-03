import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../analytics/usage_counters.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import '../voice/ha_socket.dart';
import 'calendar_edits.dart';
import 'calendar_model.dart';
import 'calendar_requests.dart';

/// How the events reach the kiosk right now.
enum CalendarLink {
  /// Nothing on screen needs them.
  idle,

  /// Home Assistant pushes every change (`calendar/event/subscribe`, Home
  /// Assistant 2026.5 and later).
  live,

  /// An older Home Assistant: `calendar.get_events` every few minutes.
  polled,

  /// Home Assistant is not reachable. The last events stay on screen.
  offline,
}

/// The events for the span the screens asked for.
@immutable
class CalendarSnapshot {
  const CalendarSnapshot({
    this.events = const [],
    this.from,
    this.to,
    this.link = CalendarLink.idle,
    this.updatedAt,
  });

  /// Every enabled calendar's events, shared ones merged. Hidden calendars
  /// are still in here: [visibleEvents] takes them out per screen.
  final List<CalendarEvent> events;
  final DateTime? from;
  final DateTime? to;
  final CalendarLink link;
  final DateTime? updatedAt;

  CalendarSnapshot copyWith({
    List<CalendarEvent>? events,
    DateTime? from,
    DateTime? to,
    CalendarLink? link,
    DateTime? updatedAt,
  }) => CalendarSnapshot(
    events: events ?? this.events,
    from: from ?? this.from,
    to: to ?? this.to,
    link: link ?? this.link,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// One day of the weather entity's daily forecast.
@immutable
class DayForecast {
  const DayForecast({required this.condition, this.high, this.low});

  /// Home Assistant's condition word: sunny, cloudy, rainy and the rest.
  final String condition;
  final double? high;
  final double? low;
}

/// What the overlay opens on: a view and a day, or the defaults.
typedef CalendarOpening = ({String? view, DateTime? date});

/// The event a voice request was about, ringed on screen for a moment.
typedef CalendarHighlight = ({String summary, DateTime start});

/// The family calendar: Home Assistant's calendar entities, read only.
///
/// The calendars and their colors live in `calendar.calendars`. The
/// screens say which days they draw through [watch], and only while one
/// does is there a subscription to Home Assistant: the overlay while it is
/// open, the Up next widget while the screensaver shows it. Each enabled
/// calendar gets its own `calendar/event/subscribe` over one socket, and
/// [mergeEvents] folds an event on several calendars into one.
class CalendarManager extends Manager implements CalendarStore {
  CalendarManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    HaSocket? socket,
    DateTime Function()? clock,
    this.pollEvery = const Duration(minutes: 5),
    this.checkEvery = const Duration(seconds: 20),
    this.closeAfter = const Duration(seconds: 60),
  }) : _clock = clock ?? DateTime.now,
       _socket =
           socket ??
           HaSocket(
             baseUrl: () => _settings.get(defs.haUrl),
             token: () => _settings.get(defs.haToken),
           );

  final SettingsManager _settings;
  final DateTime Function() _clock;
  final HaSocket _socket;

  /// An older Home Assistant is asked again this often.
  final Duration pollEvery;

  /// How often a live link checks it still is one.
  final Duration checkEvery;

  /// The socket stays open this long after the last screen let go, so
  /// opening the calendar again is instant.
  final Duration closeAfter;

  /// The full screen calendar is up.
  final visible = ValueNotifier<bool>(false);

  /// The Calendar screensaver mode is on screen.
  final screensaverShown = ValueNotifier<bool>(false);

  /// The event a voice request added, found or changed, until it fades.
  final highlight = ValueNotifier<CalendarHighlight?>(null);
  Timer? _highlightEnd;

  /// Voice Satellite's answer is on screen, likely over the ringed event.
  bool _assistShown = false;

  /// Requests from the Kiosk Satellite calendar script.
  late final requests = CalendarRequests(_settings, this, clock: _clock);

  /// Adding, changing and deleting events from the calendar's own screen.
  late final edits = CalendarEdits(this, log);

  /// Set by [open] just before [visible] goes true: the view and day the
  /// overlay starts on.
  CalendarOpening opening = (view: null, date: null);

  /// Counts the opens that found the calendar already up, so the open one
  /// takes the new [opening].
  final reopened = ValueNotifier<int>(0);

  /// The view the open calendar shows, null while it is closed. The
  /// overlay keeps it current. ESPHome's Calendar view select reads it.
  final shownView = ValueNotifier<String?>(null);

  final calendars = ValueNotifier<List<CalendarSource>>(const []);
  final hidden = ValueNotifier<Set<String>>(const {});
  final snapshot = ValueNotifier<CalendarSnapshot>(const CalendarSnapshot());

  /// The weather entity's daily forecast, by local date.
  final forecast = ValueNotifier<Map<DateTime, DayForecast>>(const {});

  /// Each person's picture, as a full URL on Home Assistant.
  final pictures = ValueNotifier<Map<String, String>>(const {});

  /// Each calendar's supported_features, read with the people's pictures:
  /// what its integration lets the kiosk do ([calendarCreates] and
  /// friends). A calendar missing here has not been read yet.
  final features = ValueNotifier<Map<String, int>>(const {});

  final _subs = <StreamSubscription<Object?>>[];
  final _windows = <Object, (DateTime, DateTime)>{};
  final _byCalendar = <String, List<CalendarEvent>>{};
  final _unsubscribe = <Future<void> Function()>[];
  Future<void> Function()? _weatherUnsubscribe;
  String _subscribedKey = '';
  int _subscribedOn = -1;
  int _generation = 0;
  bool _polled = false;
  String? _source;
  bool _syncing = false;
  bool _syncAgain = false;
  Timer? _check;
  Timer? _poll;
  Timer? _close;
  DateTime? _from;
  DateTime? _to;

  @override
  String get name => 'calendar';

  /// The calendars that are on, in order.
  @override
  List<CalendarSource> get enabled => [
    for (final c in calendars.value)
      if (c.on) c,
  ];

  /// An enabled calendar by entity.
  CalendarSource? source(String entity) {
    for (final c in calendars.value) {
      if (c.entity == entity) return c;
    }
    return null;
  }

  @override
  Future<void> init() async {
    _readCalendars();
    _readHidden();
    _registerCommands();
    shownView.addListener(
      () => bus.publish(CalendarViewChanged(shownView.value)),
    );
    _subs
      ..add(
        bus.on<SettingChanged>().listen((e) {
          if (e.key == defs.calendarCalendars.key) {
            _readCalendars();
            _requestSync();
          } else if (e.key == defs.calendarHidden.key) {
            _readHidden();
          } else if (e.key == defs.calendarWeatherEntity.key) {
            forecast.value = const {};
            _requestSync(force: true);
          } else if (e.key == defs.haUrl.key || e.key == defs.haToken.key) {
            unawaited(_socket.close());
            _requestSync(force: true);
          } else if (e.key == defs.kioskAllowCalendar.key && e.value != true) {
            visible.value = false;
          }
        }),
      )
      ..add(
        bus.on<AssistOverlayVisibility>().listen((e) {
          _assistShown = e.visible;
          if (!e.visible && highlight.value != null) _fadeHighlight();
        }),
      )
      ..add(
        // An abandoned calendar gives way to the screensaver, as the app
        // launcher and the alarm list do.
        bus.on<ScreensaverStateChanged>().listen((e) {
          if (e.active) visible.value = false;
        }),
      );
  }

  @override
  Future<void> dispose() async {
    _check?.cancel();
    _poll?.cancel();
    _close?.cancel();
    _highlightEnd?.cancel();
    for (final sub in _subs) {
      await sub.cancel();
    }
    await _unsubscribeAll();
    await _socket.close();
    visible.dispose();
    screensaverShown.dispose();
    highlight.dispose();
    reopened.dispose();
    shownView.dispose();
    calendars.dispose();
    hidden.dispose();
    snapshot.dispose();
    forecast.dispose();
    pictures.dispose();
    features.dispose();
  }

  void _readCalendars() {
    calendars.value = decodeCalendars(_settings.get(defs.calendarCalendars));
  }

  void _readHidden() {
    hidden.value = decodeHidden(_settings.get(defs.calendarHidden));
  }

  // ── What the screens draw ─────────────────────────────────────────────

  /// [holder] draws the days from [from] up to [to]. Keeps a subscription
  /// running that covers every holder's span.
  void watch(Object holder, DateTime from, DateTime to) {
    final current = _windows[holder];
    if (current != null && current.$1 == from && current.$2 == to) return;
    _windows[holder] = (from, to);
    _requestSync();
  }

  /// [holder] stopped drawing.
  void unwatch(Object holder) {
    if (_windows.remove(holder) != null) _requestSync();
  }

  /// Hide or show one calendar's events on this kiosk, as its chip does.
  Future<void> setHidden(String entity, bool hide) async {
    final next = {...hidden.value};
    if (hide) {
      next.add(entity);
    } else {
      next.remove(entity);
    }
    // At once, so the chip answers the tap before the setting echoes back.
    hidden.value = next;
    await _settings.set(defs.calendarHidden, jsonEncode(next.toList()));
  }

  Future<void> saveCalendars(List<CalendarSource> list) =>
      _settings.set(defs.calendarCalendars, encodeCalendars(list));

  Future<void> open({
    String? view,
    DateTime? date,
    CalendarHighlight? highlight,
  }) async {
    unawaited(UsageCounters.bump(_settings, 'calendar_opens'));
    await commands.execute('screenOn', const {});
    await commands.execute('bringToFront', const {});
    await commands.execute('stopScreensaver', const {});
    opening = (view: view, date: date);
    this.highlight.value = highlight;
    if (highlight != null) _fadeHighlight();
    // Already up: the open calendar moves to where it was asked to.
    if (visible.value) reopened.value++;
    visible.value = true;
  }

  /// The ring stays while Voice Satellite's answer covers the calendar,
  /// then a little longer, so it is seen. Two minutes at the most.
  void _fadeHighlight() {
    _highlightEnd?.cancel();
    _highlightEnd = Timer(
      _assistShown ? const Duration(minutes: 2) : const Duration(seconds: 12),
      () => highlight.value = null,
    );
  }

  @override
  Future<void> show({
    required String view,
    required DateTime date,
    CalendarHighlight? highlight,
  }) => open(view: view, date: date, highlight: highlight);

  // ── Voice requests ────────────────────────────────────────────────────

  /// Every enabled calendar's own events from [from] up to [to], read once
  /// from Home Assistant's REST API. Unlike `calendar.get_events` it keeps
  /// each event's uid and recurrence id, which a change or a cancel needs.
  /// A calendar that cannot be read is left out, and when none can be the
  /// read fails.
  @override
  Future<Map<String, List<CalendarEvent>>> readEvents(
    DateTime from,
    DateTime to,
  ) async {
    final base = _settings
        .get(defs.haUrl)
        .trim()
        .replaceFirst(RegExp(r'/+$'), '');
    final token = _settings.get(defs.haToken);
    if (base.isEmpty || token.isEmpty) {
      throw StateError('Home Assistant is not set up on this kiosk');
    }
    final out = <String, List<CalendarEvent>>{};
    Object? failure;
    await Future.wait([
      for (final c in enabled)
        () async {
          try {
            final response = await http
                .get(
                  Uri.parse('$base/api/calendars/${c.entity}').replace(
                    queryParameters: {
                      'start': from.toUtc().toIso8601String(),
                      'end': to.toUtc().toIso8601String(),
                    },
                  ),
                  headers: {'Authorization': 'Bearer $token'},
                )
                .timeout(const Duration(seconds: 15));
            if (response.statusCode != 200) {
              throw StateError('HTTP ${response.statusCode}');
            }
            final body = jsonDecode(response.body);
            out[c.entity] = [
              if (body is List)
                for (final item in body) ?parseHaEvent(item, c.entity),
            ];
          } catch (e) {
            failure = e;
            log.warn('calendar', 'reading ${c.entity} failed: $e');
          }
        }(),
    ]);
    if (out.isEmpty && failure != null) {
      throw StateError('the calendars could not be read: $failure');
    }
    return out;
  }

  @override
  Future<void> createEvent(String entity, CalendarDraft draft) => _write({
    'type': 'calendar/event/create',
    'entity_id': entity,
    'event': draft.toHa(),
  });

  /// One event, or one day of a repeating one (the other days stay as they
  /// are) or that day and the ones after it.
  @override
  Future<void> updateEvent(
    String entity,
    CalendarEvent event,
    CalendarDraft draft, {
    String scope = 'this',
  }) => _write({
    'type': 'calendar/event/update',
    'entity_id': entity,
    'uid': event.uid,
    if (event.recurrenceId != null) ...{
      'recurrence_id': event.recurrenceId,
      if (scope == 'following') 'recurrence_range': 'THISANDFUTURE',
    },
    'event': draft.toHa(),
  });

  /// [scope] is `this` (the one day), `following` (that day and the ones
  /// after it) or `all` (the whole series). An event that does not repeat
  /// goes whatever the scope.
  @override
  Future<void> deleteEvent(String entity, CalendarEvent event, String scope) =>
      _write({
        'type': 'calendar/event/delete',
        'entity_id': entity,
        'uid': event.uid,
        if (event.recurrenceId != null && scope != 'all') ...{
          'recurrence_id': event.recurrenceId,
          if (scope == 'following') 'recurrence_range': 'THISANDFUTURE',
        },
      });

  Future<void> _write(Map<String, Object?> message) async {
    try {
      await _socket.request(message, timeout: const Duration(seconds: 20));
    } finally {
      if (_windows.isEmpty) {
        // Nothing on screen holds the socket open: close it as a screen
        // letting go would.
        _close?.cancel();
        _close = Timer(closeAfter, () {
          _close = null;
          if (_windows.isEmpty) unawaited(_socket.close());
        });
      } else if (_polled) {
        // A live link hears the change by itself. A polled one asks now.
        unawaited(_fetch(_generation));
      }
    }
  }

  // ── Home Assistant ────────────────────────────────────────────────────

  bool _forceNext = false;
  bool _scheduled = false;

  /// Screens watch from build and let go from dispose, so the work waits
  /// for a microtask and every request in the same frame lands as one.
  void _requestSync({bool force = false}) {
    if (force) _forceNext = true;
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      if (_syncing) {
        _syncAgain = true;
        return;
      }
      unawaited(_sync());
    });
  }

  /// The span every holder needs, or null when none needs any.
  (DateTime, DateTime)? get _wanted {
    if (_windows.isEmpty) return null;
    var from = _windows.values.first.$1, to = _windows.values.first.$2;
    for (final (a, b) in _windows.values) {
      if (a.isBefore(from)) from = a;
      if (b.isAfter(to)) to = b;
    }
    return (from, to);
  }

  Future<void> _sync() async {
    _syncing = true;
    try {
      do {
        _syncAgain = false;
        final wanted = _wanted;
        if (wanted == null) {
          _letGo();
          continue;
        }
        _close?.cancel();
        _close = null;
        final key = [
          for (final c in enabled) c.entity,
          _settings.get(defs.calendarWeatherEntity),
        ].join(',');
        final covered =
            _from != null &&
            _to != null &&
            !wanted.$1.isBefore(_from!) &&
            !wanted.$2.isAfter(_to!);
        final force = _forceNext;
        _forceNext = false;
        if (covered &&
            key == _subscribedKey &&
            !force &&
            snapshot.value.link != CalendarLink.offline &&
            snapshot.value.link != CalendarLink.idle) {
          continue;
        }
        await _subscribe(wanted.$1, wanted.$2, key);
      } while (_syncAgain);
    } finally {
      _syncing = false;
    }
  }

  /// Nothing needs the events: end the subscriptions now, the socket a
  /// little later.
  void _letGo() {
    _check?.cancel();
    _check = null;
    _poll?.cancel();
    _poll = null;
    _generation++;
    unawaited(_unsubscribeAll());
    _subscribedKey = '';
    _from = _to = null;
    if (snapshot.value.link != CalendarLink.idle) {
      snapshot.value = snapshot.value.copyWith(link: CalendarLink.idle);
    }
    _close ??= Timer(closeAfter, () {
      _close = null;
      if (_windows.isEmpty) unawaited(_socket.close());
    });
  }

  Future<void> _unsubscribeAll() async {
    final ends = [..._unsubscribe];
    _unsubscribe.clear();
    final weather = _weatherUnsubscribe;
    _weatherUnsubscribe = null;
    for (final end in ends) {
      await end();
    }
    await weather?.call();
  }

  Future<void> _subscribe(DateTime from, DateTime to, String key) async {
    final generation = ++_generation;
    _poll?.cancel();
    _poll = null;
    await _unsubscribeAll();
    final cals = enabled;
    _byCalendar.removeWhere((id, _) => !cals.any((c) => c.entity == id));
    _from = from;
    _to = to;
    _subscribedKey = key;
    var link = CalendarLink.live;
    if (!_polled) {
      for (final c in cals) {
        try {
          final end = await _socket.subscribe({
            'type': 'calendar/event/subscribe',
            'entity_id': c.entity,
            'start': from.toUtc().toIso8601String(),
            'end': to.toUtc().toIso8601String(),
          }, (event) => _onEvents(generation, c.entity, event['events']));
          if (generation != _generation) {
            await end();
            return;
          }
          _unsubscribe.add(end);
        } catch (e) {
          if (generation != _generation) return;
          final text = '$e'.toLowerCase();
          if (text.contains('unknown command')) {
            // Before Home Assistant 2026.5: ask instead of listening.
            log.info('calendar', 'no live calendar events here, polling');
            _polled = true;
            break;
          }
          if (text.contains('not found')) {
            log.warn('calendar', '${c.entity} is not in Home Assistant');
            _byCalendar.remove(c.entity);
            continue;
          }
          log.warn('calendar', 'subscribing to ${c.entity} failed: $e');
          link = CalendarLink.offline;
          break;
        }
      }
    }
    if (generation != _generation) return;
    if (_polled) {
      link = await _fetch(generation)
          ? CalendarLink.polled
          : CalendarLink.offline;
      _poll = Timer.periodic(pollEvery, (_) => unawaited(_fetch(generation)));
    }
    _subscribedOn = _socket.connections;
    if (link == CalendarLink.live || link == CalendarLink.polled) {
      _source = link.name;
    }
    snapshot.value = snapshot.value.copyWith(
      link: link,
      from: from,
      to: to,
      events: _merged(),
    );
    if (link != CalendarLink.offline) {
      unawaited(_subscribeWeather(generation));
      unawaited(_loadPictures(generation));
    }
    _check?.cancel();
    _check = Timer.periodic(checkEvery, (_) => _checkLink());
  }

  /// A dropped socket ends its subscriptions without a word: notice and
  /// subscribe again.
  void _checkLink() {
    if (_windows.isEmpty || _syncing) return;
    final link = snapshot.value.link;
    final dropped =
        link == CalendarLink.offline ||
        (link == CalendarLink.live &&
            (!_socket.connected || _socket.connections != _subscribedOn));
    if (dropped) _requestSync(force: true);
  }

  void _onEvents(int generation, String calendar, Object? raw) {
    if (generation != _generation) return;
    _byCalendar[calendar] = [
      if (raw is List)
        for (final item in raw) ?parseHaEvent(item, calendar),
    ];
    _publish();
  }

  Future<bool> _fetch(int generation) async {
    final cals = enabled;
    if (cals.isEmpty || _from == null || _to == null) return true;
    try {
      final result = await _socket.request({
        'type': 'call_service',
        'domain': 'calendar',
        'service': 'get_events',
        'target': {
          'entity_id': [for (final c in cals) c.entity],
        },
        'service_data': {
          'start_date_time': _from!.toUtc().toIso8601String(),
          'end_date_time': _to!.toUtc().toIso8601String(),
        },
        'return_response': true,
      }, timeout: const Duration(seconds: 20));
      if (generation != _generation) return false;
      final response = result is Map ? result['response'] : null;
      if (response is Map) {
        for (final c in cals) {
          final entry = response[c.entity];
          final list = entry is Map ? entry['events'] : null;
          _byCalendar[c.entity] = [
            if (list is List)
              for (final item in list) ?parseHaEvent(item, c.entity),
          ];
        }
      }
      _publish(link: CalendarLink.polled);
      return true;
    } catch (e) {
      if (generation != _generation) return false;
      log.warn('calendar', 'reading the calendars failed: $e');
      snapshot.value = snapshot.value.copyWith(link: CalendarLink.offline);
      return false;
    }
  }

  List<CalendarEvent> _merged() => mergeEvents(
    {for (final c in enabled) c.entity: ?_byCalendar[c.entity]},
    [for (final c in enabled) c.entity],
  );

  void _publish({CalendarLink? link}) {
    snapshot.value = snapshot.value.copyWith(
      events: _merged(),
      updatedAt: _clock(),
      link:
          link ??
          (snapshot.value.link == CalendarLink.offline ||
                  snapshot.value.link == CalendarLink.idle
              ? (_polled ? CalendarLink.polled : CalendarLink.live)
              : null),
    );
  }

  Future<void> _subscribeWeather(int generation) async {
    final entity = _settings.get(defs.calendarWeatherEntity).trim();
    if (!entity.startsWith('weather.')) {
      forecast.value = const {};
      return;
    }
    try {
      final end = await _socket.subscribe(
        {
          'type': 'weather/subscribe_forecast',
          'entity_id': entity,
          'forecast_type': 'daily',
        },
        (event) {
          if (generation != _generation) return;
          forecast.value = parseForecast(event['forecast']);
        },
      );
      if (generation != _generation) {
        await end();
        return;
      }
      _weatherUnsubscribe = end;
    } catch (e) {
      log.warn('calendar', 'the forecast for $entity failed: $e');
    }
  }

  /// The people's pictures and what each calendar's integration allows,
  /// read once each time the screens start watching: they change about
  /// never.
  Future<void> _loadPictures(int generation) async {
    final people = {
      for (final c in calendars.value)
        if (c.person.startsWith('person.')) c.person,
    };
    final entities = [...people, for (final c in calendars.value) c.entity];
    if (entities.isEmpty) {
      pictures.value = const {};
      features.value = const {};
      return;
    }
    final got = Completer<Map<Object?, Object?>>();
    Future<void> Function()? end;
    try {
      end = await _socket.subscribe(
        {'type': 'subscribe_entities', 'entity_ids': entities},
        (event) {
          if (got.isCompleted) return;
          final added = event['a'];
          got.complete(added is Map ? added : const {});
        },
      );
      final added = await got.future.timeout(const Duration(seconds: 10));
      final found = <String, String>{};
      final allowed = <String, int>{};
      for (final entry in added.entries) {
        final id = '${entry.key}';
        final attrs = entry.value is Map ? (entry.value as Map)['a'] : null;
        if (attrs is! Map) continue;
        final picture = attrs['entity_picture'];
        if (people.contains(id) && picture is String && picture.isNotEmpty) {
          found[id] = _absolute(picture);
        }
        final supported = attrs['supported_features'];
        if (id.startsWith('calendar.')) {
          allowed[id] = supported is num ? supported.toInt() : 0;
        }
      }
      if (generation == _generation) {
        pictures.value = found;
        features.value = allowed;
      }
    } catch (e) {
      log.warn('calendar', 'reading the people failed: $e');
    } finally {
      await end?.call();
    }
  }

  /// Whether [entity]'s integration takes new events, changes or deletes,
  /// Home Assistant's CalendarEntityFeature bits. One not read yet is
  /// given the benefit of the doubt: Home Assistant refuses it if not.
  bool calendarAllows(String entity, int feature) {
    final bits = features.value[entity];
    return bits == null || bits & feature != 0;
  }

  String _absolute(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = _settings
        .get(defs.haUrl)
        .trim()
        .replaceFirst(RegExp(r'/+$'), '');
    return '$base${path.startsWith('/') ? '' : '/'}$path';
  }

  // ── Commands ──────────────────────────────────────────────────────────

  Map<String, Object?> status() {
    final s = snapshot.value;
    return {
      'visible': visible.value || screensaverShown.value,
      'screensaver': screensaverShown.value,
      'view': shownView.value,
      'calendars': [for (final c in calendars.value) c.toJson()],
      'hidden': hidden.value.toList(),
      'link': s.link.name,
      // How Home Assistant answered the last time it was asked: live or
      // polled, null until it was.
      'source': _source,
      'from': s.from?.toIso8601String(),
      'to': s.to?.toIso8601String(),
      'updatedAt': s.updatedAt?.toIso8601String(),
      'events': [
        for (final e in s.events.take(200))
          {
            'summary': e.summary,
            'start': e.start.toIso8601String(),
            'end': e.end.toIso8601String(),
            'allDay': e.allDay,
            'calendars': e.calendars,
            if (e.location.isNotEmpty) 'location': e.location,
          },
      ],
    };
  }

  void _registerCommands() {
    commands
      ..register(
        Command(
          name: 'openCalendar',
          description: 'Open the full screen calendar on the kiosk.',
          params: const {
            'view': 'optional: day, week, month or schedule',
            'date': 'optional: the day to open on, as yyyy-MM-dd',
          },
          handler: (p) async {
            final view = '${p['view'] ?? ''}';
            final date = DateTime.tryParse('${p['date'] ?? ''}');
            await open(
              view: const ['day', 'week', 'month', 'schedule'].contains(view)
                  ? view
                  : null,
              date: date == null ? null : dateOnly(date),
            );
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'calendarVoiceRequest',
          description:
              'What the Kiosk Satellite calendar script asks for, answered '
              'in the shape the script hands back to the LLM.',
          params: const {
            'action': 'add, find, change, cancel or show',
            'title': 'The event\'s title, or words to find it by',
            'start': 'yyyy-MM-dd, or yyyy-MM-dd HH:mm',
            'end': 'yyyy-MM-dd, or yyyy-MM-dd HH:mm',
            'people': 'Calendar or person names',
          },
          // The voice requests manager logs each one with its outcome.
          quiet: true,
          handler: (p) async => CommandResult.ok(await requests.handle(p)),
        ),
      )
      ..register(
        Command(
          name: 'hideCalendar',
          description: 'Close the calendar, the Calendar screensaver included.',
          handler: (_) async {
            visible.value = false;
            if (screensaverShown.value) {
              await commands.execute('stopScreensaver', const {});
            }
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'calendarStatus',
          description:
              'The calendars, the ones hidden on this kiosk, how the events '
              'arrive and the events loaded right now.',
          quiet: true,
          handler: (_) async => CommandResult.ok(status()),
        ),
      )
      ..register(
        Command(
          name: 'calendarSetHidden',
          description: 'Hide or show one calendar on this kiosk.',
          params: const {
            'entity': 'The calendar entity',
            'hidden': 'true or false',
          },
          handler: (p) async {
            final entity = '${p['entity'] ?? ''}';
            if (source(entity) == null) {
              return const CommandResult.fail('no such calendar');
            }
            await setHidden(entity, p['hidden'] == true);
            return const CommandResult.ok();
          },
        ),
      );
  }
}

/// The daily forecast `weather/subscribe_forecast` sends, by local date.
Map<DateTime, DayForecast> parseForecast(Object? raw) {
  if (raw is! List) return const {};
  final out = <DateTime, DayForecast>{};
  for (final item in raw) {
    if (item is! Map) continue;
    final when = DateTime.tryParse('${item['datetime'] ?? ''}');
    if (when == null) continue;
    final day = dateOnly(when.isUtc ? when.toLocal() : when);
    double? number(Object? v) => v is num ? v.toDouble() : null;
    out.putIfAbsent(
      day,
      () => DayForecast(
        condition: '${item['condition'] ?? ''}',
        high: number(item['temperature']),
        low: number(item['templow']),
      ),
    );
  }
  return out;
}
