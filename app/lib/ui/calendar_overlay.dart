import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_container.dart';
import '../l10n/generated/ui_strings.dart';
import '../l10n/messages.dart';
import '../managers/calendar/calendar_edits.dart';
import '../managers/calendar/calendar_manager.dart';
import '../managers/calendar/calendar_model.dart';
import '../core/events.dart';
import '../managers/settings/definitions.dart' as defs;
import 'calendar_editor.dart';
import 'kit.dart';
import 'theme.dart';
import 'weather_readings.dart' show weatherConditionIcon;

/// The family calendar as a full screen overlay, the Skylight's look over
/// Home Assistant's calendars: Day, Week, Month and Schedule, one color per
/// person, an event on several calendars split on a diagonal between their
/// colors. Read only unless Settings > Calendar > Editing allows adding,
/// changing or deleting events. Shown through [CalendarManager.visible], so the kiosk
/// menu, the Up next widget, the remote admin and Settings open the same
/// one.
class CalendarOverlay extends StatelessWidget {
  const CalendarOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: container.calendar.visible,
    builder: (context, visible, _) {
      if (!visible) return const SizedBox.shrink();
      return Positioned.fill(child: CalendarScreen(container: container));
    },
  );
}

/// The three layouts the calendar takes. Roomy is a tablet, short a panel
/// under 600 tall like the Echo Show 5, narrow a phone in portrait.
enum CalendarLayout { roomy, short, narrow }

CalendarLayout calendarLayout(Size size) => size.width < 640
    ? CalendarLayout.narrow
    : size.height < 600
    ? CalendarLayout.short
    : CalendarLayout.roomy;

const _views = ['day', 'week', 'month', 'schedule'];

/// Today's disc: the mark's keyline teal, the primary in both themes.
const _todayFill = Color(0xFF488284);

/// The first day of the week, 0 = Sunday: the setting, or the language's.
int calendarFirstWeekday(BuildContext context, AppContainer c) =>
    switch (c.settings.get(defs.calendarWeekStart)) {
      'sunday' => 0,
      'monday' => 1,
      'saturday' => 6,
      _ => MaterialLocalizations.of(context).firstDayOfWeekIndex,
    };

/// A time the way the device reads them: 4:00 PM, or 16:00.
String calendarTime(BuildContext context, DateTime t, {bool short = false}) {
  if (MediaQuery.alwaysUse24HourFormatOf(context)) {
    return DateFormat.Hm().format(t);
  }
  if (short && t.minute == 0) return DateFormat.j().format(t);
  return DateFormat.jm().format(t);
}

/// An event's time, or All day.
String calendarWhen(BuildContext context, CalendarEvent e, {DateTime? on}) {
  final s = l10n(context);
  if (e.allDay) return s.calendarAllDay;
  if (on != null && e.multiDay) {
    final day = dateOnly(on);
    final startsToday = dateOnly(e.start) == day;
    final endsToday = !e.end.isAfter(addDays(day, 1)) && e.end.isAfter(day);
    if (!startsToday && !endsToday) return s.calendarAllDay;
    if (!startsToday) {
      return s.calendarTimeRange(
        calendarTime(context, day),
        calendarTime(context, e.end),
      );
    }
  }
  return s.calendarTimeRange(
    calendarTime(context, e.start),
    calendarTime(context, e.end),
  );
}

/// "in 50 min", "in 2 h 10 min", or Now once it started.
String calendarStartsIn(BuildContext context, DateTime start, DateTime now) {
  final s = l10n(context);
  if (!start.isAfter(now)) return s.calendarHappeningNow;
  final minutes = (start.difference(now).inSeconds / 60).ceil();
  final h = minutes ~/ 60, m = minutes % 60;
  final span = h == 0
      ? s.alarmsDurationMinutes('$m')
      : m == 0
      ? s.alarmsDurationHours('$h')
      : s.alarmsDurationHoursMinutes('$h', '$m');
  return s.calendarStartsIn(span);
}

/// The calendars' names as one phrase: Sam, Sam and Leo, Sam, Leo and Maya.
String calendarNames(UiStrings s, List<String> names) {
  if (names.isEmpty) return '';
  if (names.length == 1) return names.first;
  return s.calendarPeopleTwo(
    names.sublist(0, names.length - 1).join(', '),
    names.last,
  );
}

/// The calendar's ground: one flat tone, the overlay gradient's lit top
/// in the light theme and its deep bottom in the dark one.
Color calendarGround(ThemeData theme) {
  final gradient = ksGroundGradient(
    theme.colorScheme.surface,
    theme.brightness,
  );
  return theme.brightness == Brightness.dark
      ? gradient.colors.last
      : gradient.colors.first;
}

/// The colors a calendar is drawn in, worked out once per frame from its
/// "r,g,b" and the theme: the tint for timed events, a stronger one for
/// all-day events, the avatar's disc and its ink. [dark] overrides the
/// theme's brightness, for the screensaver's widgets, which always stand
/// on a dark ground.
class CalendarPaint {
  CalendarPaint(this.context, this.manager, {bool? dark})
    : _dark = dark ?? Theme.of(context).brightness == Brightness.dark,
      raised = Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surfaceContainer
          : Theme.of(context).colorScheme.surfaceContainerLowest;

  final BuildContext context;
  final CalendarManager manager;
  final bool _dark;

  /// The surface today's column and the Schedule's panel stand on.
  final Color raised;

  /// A day of the week that is not today: a step deeper than the light
  /// ground, a step up from the dark one, under today's raised surface.
  Color get panel => _dark
      ? Color.lerp(calendarGround(Theme.of(context)), raised, .5)!
      : Theme.of(context).colorScheme.surface;

  /// The light ground is nearly white, so a raised surface on it takes a
  /// hairline to stand apart. The dark ground is deep enough without one.
  Border? get raisedBorder => _dark
      ? null
      : Border.all(color: Theme.of(context).colorScheme.outlineVariant);

  Color base(String entity) {
    final rgb = parseRgb(manager.source(entity)?.color ?? '');
    final color = rgb == null
        ? Theme.of(context).colorScheme.primary
        : Color.fromARGB(255, rgb.$1, rgb.$2, rgb.$3);
    // Lifted a step on dark surfaces, as the scheme's own accents are.
    return _dark ? Color.lerp(color, Colors.white, .3)! : color;
  }

  Color soft(String e) =>
      Color.alphaBlend(base(e).withValues(alpha: _dark ? .26 : .14), raised);

  Color strong(String e) =>
      Color.alphaBlend(base(e).withValues(alpha: _dark ? .44 : .30), raised);

  Color disc(String e) =>
      _dark ? base(e) : Color.lerp(base(e), Colors.black, .18)!;

  Color get discInk => _dark ? const Color(0xFF1A1B1E) : Colors.white;

  List<Color> softs(List<String> ids) => [for (final id in ids) soft(id)];
  List<Color> strongs(List<String> ids) => [for (final id in ids) strong(id)];
  List<Color> bases(List<String> ids) => [for (final id in ids) base(id)];
}

/// One fill, or a shared event's bands: one per calendar on a 45 degree
/// diagonal through the box, the way Skylight splits an event between the
/// people it is for.
class CalendarBands extends CustomPainter {
  const CalendarBands(this.colors, {this.radius = 0, this.circle = false});

  final List<Color> colors;
  final double radius;
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;
    final rect = Offset.zero & size;
    final clip = circle
        ? (Path()..addOval(rect))
        : (Path()
            ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius))));
    if (colors.length == 1) {
      canvas.drawPath(clip, Paint()..color = colors.first);
      return;
    }
    canvas.save();
    canvas.clipPath(clip);
    final w = size.width, h = size.height;
    final total = w + h;
    final n = colors.length;
    for (var i = 0; i < n; i++) {
      // The band holds the points with x + y between s0 and s1. A hair of
      // overlap keeps a seam from showing the ground through.
      final s0 = total * i / n - (i == 0 ? h : 0);
      final s1 = total * (i + 1) / n + (i == n - 1 ? h : .6);
      final band = Path()
        ..moveTo(s0, 0)
        ..lineTo(s1, 0)
        ..lineTo(s1 - h, h)
        ..lineTo(s0 - h, h)
        ..close();
      canvas.drawPath(band, Paint()..color = colors[i]);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CalendarBands old) =>
      !listEquals(old.colors, colors) ||
      old.radius != radius ||
      old.circle != circle;
}

/// A calendar's avatar: the person's picture, or the name's initial on the
/// calendar's color.
class CalendarAvatar extends StatelessWidget {
  const CalendarAvatar({
    super.key,
    required this.container,
    required this.entity,
    required this.paint,
    this.size = 28,
    this.muted = false,
  });

  final AppContainer container;
  final String entity;
  final CalendarPaint paint;
  final double size;

  /// Hidden: an outline and the initial in the muted text color.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cal = container.calendar;
    final source = cal.source(entity);
    final scheme = Theme.of(context).colorScheme;
    final initial = Text(
      source?.initial ?? '?',
      style: TextStyle(
        fontSize: size * .46,
        fontWeight: FontWeight.w700,
        height: 1,
        color: muted ? scheme.onSurfaceVariant : paint.discInk,
      ),
    );
    final picture = source == null ? null : cal.pictures.value[source.person];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: muted ? null : paint.disc(entity),
        border: muted ? Border.all(color: scheme.outline) : null,
      ),
      child: picture == null || muted
          ? initial
          : ClipOval(
              child: Image.network(
                picture,
                width: size,
                height: size,
                fit: BoxFit.cover,
                headers: {
                  'Authorization':
                      'Bearer ${container.settings.get(defs.haToken)}',
                },
                errorBuilder: (_, _, _) => Center(child: initial),
              ),
            ),
    );
  }
}

/// Several avatars overlapping, each ringed in [ring] so the edges read.
class CalendarAvatarStack extends StatelessWidget {
  const CalendarAvatarStack({
    super.key,
    required this.container,
    required this.entities,
    required this.paint,
    required this.ring,
    this.size = 26,
  });

  final AppContainer container;
  final List<String> entities;
  final CalendarPaint paint;
  final Color ring;
  final double size;

  @override
  Widget build(BuildContext context) {
    final step = size - 7;
    final full = size + 4;
    return SizedBox(
      width: full + step * (entities.length - 1),
      height: full,
      child: Stack(
        children: [
          for (var i = 0; i < entities.length; i++)
            Positioned(
              left: i * step,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
                child: CalendarAvatar(
                  container: container,
                  entity: entities[i],
                  paint: paint,
                  size: size,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The calendar itself: the overlay's content, and the Calendar
/// screensaver mode's.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.container,
    this.screensaver = false,
  });

  final AppContainer container;

  /// Shown as the screensaver: it opens on the screensaver's Calendar
  /// view and today, never closes for idle and its X ends the screensaver.
  /// Touches stay with the calendar.
  final bool screensaver;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  AppContainer get c => widget.container;
  CalendarManager get cal => c.calendar;

  late String _view;
  late DateTime _anchor;
  Timer? _idle;
  Timer? _midnight;
  StreamSubscription<SettingChanged>? _settingsSub;
  NavigatorState? _navigator;

  /// The event dialogs and forms open over the calendar.
  int _dialogs = 0;

  /// Their touches are being reported ([_hearDialogs]).
  bool _hearing = false;

  @override
  void initState() {
    super.initState();
    _take();
    _armIdle();
    _armMidnight();
    cal.calendars.addListener(_watch);
    _settingsSub = c.bus.on<SettingChanged>().listen((e) {
      if ((e.key == defs.calendarAllowEdit.key ||
              e.key == defs.calendarAllowDelete.key) &&
          mounted) {
        setState(() {});
      }
    });
    if (widget.screensaver) {
      cal.screensaverShown.value = true;
    } else {
      cal.reopened.addListener(_reopen);
    }
  }

  /// Start on the view and day [CalendarManager.open] asked for, or the
  /// default view on today.
  void _take() {
    // The screensaver leaves an opening to the overlay it was meant for,
    // and opens on its own view.
    final opening = widget.screensaver ? (view: null, date: null) : cal.opening;
    if (!widget.screensaver) cal.opening = (view: null, date: null);
    final fallback = c.settings.get(
      widget.screensaver
          ? defs.screensaverCalendarView
          : defs.calendarDefaultView,
    );
    _view = opening.view ?? (_views.contains(fallback) ? fallback : 'week');
    _anchor = opening.date ?? dateOnly(DateTime.now());
    cal.shownView.value = _view;
  }

  void _reopen() {
    setState(_take);
    _armIdle();
    _watch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator = Navigator.of(context);
    _watch();
  }

  @override
  void dispose() {
    _idle?.cancel();
    _midnight?.cancel();
    _settingsSub?.cancel();
    // Idle or the screensaver closed the calendar under an open event or
    // form: take those down with it.
    final navigator = _navigator;
    _hearDialogs(false);
    if (_dialogs > 0 && navigator != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.mounted) navigator.popUntil((route) => route.isFirst);
      });
    }
    cal.calendars.removeListener(_watch);
    if (widget.screensaver) {
      cal.screensaverShown.value = false;
    } else {
      cal.reopened.removeListener(_reopen);
    }
    cal.unwatch(this);
    cal.shownView.value = null;
    super.dispose();
  }

  /// The day moves on at midnight even with nobody touching it.
  void _armMidnight() {
    final now = DateTime.now();
    _midnight = Timer(addDays(now, 1).difference(now), () {
      if (!mounted) return;
      setState(() {});
      _armMidnight();
    });
  }

  void _armIdle() {
    _idle?.cancel();
    // As the screensaver it is what idle leads to, so it stays.
    if (widget.screensaver) return;
    final minutes =
        int.tryParse(c.settings.get(defs.calendarIdleCloseMinutes)) ?? 0;
    if (minutes <= 0) return;
    _idle = Timer(Duration(minutes: minutes), () => cal.visible.value = false);
  }

  int get _firstWeekday => calendarFirstWeekday(context, c);

  /// The days the current view draws.
  (DateTime, DateTime) get _range {
    switch (_view) {
      case 'day':
        return (_anchor, addDays(_anchor, 1));
      case 'month':
        final start = monthGridStart(_anchor, _firstWeekday);
        return (
          start,
          addDays(start, 7 * monthGridWeeks(_anchor, _firstWeekday)),
        );
      case 'schedule':
        return (_anchor, addDays(_anchor, 14));
      default:
        final start = weekStart(_anchor, _firstWeekday);
        return (start, addDays(start, 7));
    }
  }

  /// Watch the view's days and one more span each side, so a swipe lands on
  /// days already loaded.
  void _watch() {
    final (from, to) = _range;
    final span = daysBetween(from, to);
    cal.watch(this, addDays(from, -span), addDays(to, span));
  }

  void _go(int step) {
    setState(() {
      _anchor = switch (_view) {
        'day' => addDays(_anchor, step),
        'month' => DateTime(_anchor.year, _anchor.month + step),
        _ => addDays(_anchor, 7 * step),
      };
    });
    _watch();
  }

  void _today() {
    setState(() => _anchor = dateOnly(DateTime.now()));
    _watch();
  }

  void _setView(String view) {
    setState(() => _view = view);
    cal.shownView.value = view;
    _watch();
  }

  void _openDay(DateTime day) {
    setState(() {
      _anchor = dateOnly(day);
      _view = 'day';
    });
    cal.shownView.value = 'day';
    _watch();
  }

  void _select(DateTime day) {
    setState(() => _anchor = dateOnly(day));
    _watch();
  }

  void _close() {
    if (widget.screensaver) {
      unawaited(c.commands.execute('stopScreensaver', const {}));
    } else {
      cal.visible.value = false;
    }
  }

  /// While an event or a form is open the calendar does not close for idle:
  /// typing happens there, out of this screen's reach.
  Future<void> _hold(Future<void> Function() open) async {
    if (_dialogs++ == 0) _hearDialogs(true);
    _idle?.cancel();
    try {
      await open();
    } finally {
      if (--_dialogs == 0) {
        _hearDialogs(false);
        if (mounted) _armIdle();
      }
    }
  }

  /// The dialogs, and the date, time and Repeat pickers they open, are
  /// routes above the kiosk screen, out of reach of the Listener that
  /// reports its touches. Report theirs the same way while one is up, so
  /// the screensaver's idle clock (and the dashboard's return home) hear
  /// someone at work. Not as the screensaver: a touch report would end it.
  void _hearDialogs(bool on) {
    if (widget.screensaver || on == _hearing) return;
    _hearing = on;
    final router = GestureBinding.instance.pointerRouter;
    if (on) {
      router.addGlobalRoute(_reportTouch);
    } else {
      router.removeGlobalRoute(_reportTouch);
    }
  }

  void _reportTouch(PointerEvent event) {
    if (event is PointerDownEvent) {
      c.bus.publish(const ActivityDetected(source: 'touch'));
    }
  }

  void _show(CalendarEvent event) => unawaited(
    _hold(
      () => showCalendarEvent(context, c, event, changes: !widget.screensaver),
    ),
  );

  /// New event is on: Settings allows it, this is not the screensaver and a
  /// calendar takes new events.
  bool get _canAdd =>
      !widget.screensaver &&
      calendarCanEdit(c) &&
      calendarWritable(cal).isNotEmpty;

  /// New event at [start], or at the next hour on today and 9 on another
  /// day, on [calendar] or the first one that takes events.
  void _newEvent({DateTime? start, String? calendar}) {
    final now = DateTime.now();
    final at =
        start ??
        (_anchor == dateOnly(now)
            ? DateTime(now.year, now.month, now.day, now.hour + 1)
            : DateTime(_anchor.year, _anchor.month, _anchor.day, 9));
    unawaited(
      _hold(
        () => showCalendarEditor(
          context,
          c,
          start: at,
          calendar: calendar,
        ).then((_) {}),
      ),
    );
  }

  /// The month, or the day in the Day view, long and short. A phone's
  /// header shares its row with the arrows and Today, so it takes the
  /// short forms. Elsewhere the header falls back to the short form when
  /// the long one does not fit.
  ({String long, String short}) _title(CalendarLayout layout) {
    final narrow = layout == CalendarLayout.narrow;
    if (_view == 'day') {
      // A short panel's header is as crowded as a phone's.
      final tight = narrow || layout == CalendarLayout.short;
      final short = DateFormat.MMMEd().format(_anchor);
      return (
        long: tight ? short : DateFormat.MMMMEEEEd().format(_anchor),
        short: short,
      );
    }
    final short = DateFormat.yMMM().format(_anchor);
    return (
      long: narrow ? short : DateFormat.yMMMM().format(_anchor),
      short: short,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = calendarLayout(MediaQuery.sizeOf(context));
    final s = l10n(context);
    return Listener(
      onPointerDown: (_) {
        // As the screensaver every finger here belongs to the calendar:
        // the kiosk's own report of the touch must not dismiss it.
        if (widget.screensaver) c.screensaver.markControlTouch();
        _armIdle();
        // A touch means the ring has been seen.
        cal.highlight.value = null;
      },
      child: GestureDetector(
        // The ground only shields the dashboard underneath.
        behavior: HitTestBehavior.opaque,
        // A flat ground, and a Material of that color, so the edge fades of
        // the lists on it fade into the same tone.
        child: Material(
          color: calendarGround(theme),
          child: SafeArea(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                cal.calendars,
                cal.hidden,
                cal.snapshot,
                cal.forecast,
                cal.pictures,
                cal.features,
                cal.highlight,
              ]),
              builder: (context, _) {
                final narrow = layout == CalendarLayout.narrow;
                final short = layout == CalendarLayout.short;
                final compactTop = narrow || short;
                return Stack(
                  children: [
                    Positioned.fill(child: _body(context, layout)),
                    Positioned(
                      top: compactTop ? 12 : 20,
                      left: compactTop ? 16 : 28,
                      child: KsEyebrow(
                        label: s.calendarTitle,
                        compact: compactTop,
                      ),
                    ),
                    // The chips sit in the top bar, centered between the
                    // eyebrow and the close button, so the views get the
                    // room. Equal margins put them in the middle of the
                    // screen; a phone has no room for that, so they center
                    // in the gap there.
                    if (cal.enabled.isNotEmpty)
                      Positioned(
                        top: compactTop ? 2 : 8,
                        left: narrow ? 150 : 200,
                        right: narrow ? 52 : 200,
                        height: compactTop ? 44 : 40,
                        child: _TopChips(
                          container: c,
                          named: layout == CalendarLayout.roomy,
                        ),
                      ),
                    // A phone's header has no room left: New event waits at
                    // the bottom right, under the thumb.
                    if (narrow && _canAdd)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.extended(
                          onPressed: _newEvent,
                          icon: const Icon(Icons.add),
                          label: Text(s.calendarNewEvent),
                        ),
                      ),
                    Positioned(
                      top: narrow ? 0 : 4,
                      right: narrow ? 4 : 8,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: s.commonClose,
                        iconSize: compactTop ? 26 : 28,
                        color: theme.colorScheme.onSurfaceVariant,
                        onPressed: _close,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, CalendarLayout layout) {
    final narrow = layout == CalendarLayout.narrow;
    final short = layout == CalendarLayout.short;
    final padding = switch (layout) {
      CalendarLayout.roomy => const EdgeInsets.fromLTRB(28, 72, 28, 24),
      CalendarLayout.short => const EdgeInsets.fromLTRB(16, 56, 16, 12),
      CalendarLayout.narrow => const EdgeInsets.fromLTRB(16, 56, 16, 0),
    };
    final paint = CalendarPaint(context, cal);
    final events = visibleEvents(cal.snapshot.value.events, cal.hidden.value);
    final view = cal.enabled.isEmpty
        ? const _Empty()
        : _views.contains(_view)
        ? _viewFor(layout, paint, events)
        : const SizedBox.shrink();
    final swipeable = GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() < 300) return;
        _go(v < 0 ? 1 : -1);
      },
      child: view,
    );
    final gap = short ? 10.0 : 14.0;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            title: _title(layout),
            layout: layout,
            view: _view,
            onView: _setView,
            onPrevious: () => _go(-1),
            onNext: () => _go(1),
            onToday: _today,
            onNew: _canAdd && !narrow ? _newEvent : null,
          ),
          if (narrow) ...[
            SizedBox(height: gap),
            _ViewSwitcher(view: _view, onView: _setView, fill: true),
          ],
          if (cal.snapshot.value.link == CalendarLink.offline)
            _OfflineLine(at: cal.snapshot.value.updatedAt),
          SizedBox(height: gap),
          Expanded(child: swipeable),
        ],
      ),
    );
  }

  Widget _viewFor(
    CalendarLayout layout,
    CalendarPaint paint,
    List<CalendarEvent> events,
  ) {
    final narrow = layout == CalendarLayout.narrow;
    final short = layout == CalendarLayout.short;
    final args = _ViewArgs(
      container: c,
      paint: paint,
      events: events,
      anchor: _anchor,
      firstWeekday: _firstWeekday,
      short: short,
      onEvent: _show,
      onDay: _openDay,
      onSelect: _select,
      onNew: _canAdd
          ? (start, calendar) => _newEvent(start: start, calendar: calendar)
          : null,
      highlight: c.calendar.highlight.value,
    );
    if (narrow) {
      return switch (_view) {
        'day' => _PhoneDay(args: args),
        'month' => _PhoneMonth(args: args),
        'schedule' => _ScheduleList(args: args, phone: true),
        _ => _PhoneWeek(args: args),
      };
    }
    return switch (_view) {
      'day' => _DayLanes(args: args),
      'month' => _MonthGrid(args: args),
      'schedule' => _Schedule(args: args),
      _ => _WeekColumns(args: args),
    };
  }
}

/// What every view draws from.
class _ViewArgs {
  const _ViewArgs({
    required this.container,
    required this.paint,
    required this.events,
    required this.anchor,
    required this.firstWeekday,
    required this.short,
    required this.onEvent,
    required this.onDay,
    required this.onSelect,
    this.onNew,
    this.highlight,
  });

  /// The event a voice request was about, ringed until it fades.
  final CalendarHighlight? highlight;

  /// The ringed event's start when it is a timed one on [day], for the
  /// Day timeline to scroll to.
  DateTime? focusOn(DateTime day) {
    final at = highlight?.start;
    if (at == null || dateOnly(at) != day) return null;
    return at == day ? null : at;
  }

  bool lit(CalendarEvent e) {
    final h = highlight;
    return h != null &&
        e.start == h.start &&
        e.summary.toLowerCase() == h.summary.toLowerCase();
  }

  final AppContainer container;
  final CalendarPaint paint;
  final List<CalendarEvent> events;
  final DateTime anchor;
  final int firstWeekday;
  final bool short;
  final ValueChanged<CalendarEvent> onEvent;

  /// Open that day in the Day view.
  final ValueChanged<DateTime> onDay;

  /// Pick that day on a phone's strip or month.
  final ValueChanged<DateTime> onSelect;

  /// New event at that time on that calendar, or null when this kiosk
  /// takes no new events.
  final void Function(DateTime start, String? calendar)? onNew;

  CalendarManager get cal => container.calendar;
  DateTime get today => dateOnly(DateTime.now());
  DayForecast? forecast(DateTime day) => cal.forecast.value[dateOnly(day)];
}

// ── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.layout,
    required this.view,
    required this.onView,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    this.onNew,
  });

  final ({String long, String short}) title;
  final CalendarLayout layout;
  final String view;
  final ValueChanged<String> onView;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  /// New event after the switcher: a filled pill on a tablet, a filled
  /// disc on a short panel. Null when this kiosk takes no new events.
  final VoidCallback? onNew;

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final theme = Theme.of(context);
    final roomy = layout == CalendarLayout.roomy;
    final narrow = layout == CalendarLayout.narrow;
    final titleStyle = TextStyle(
      fontSize: roomy ? 34 : 24,
      fontWeight: FontWeight.w500,
      letterSpacing: -.4,
      height: 1.1,
      color: theme.colorScheme.onSurface,
    );
    double measure(String text, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: DefaultTextStyle.of(context).style.merge(style),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    Widget titleText(String text) => Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: titleStyle,
    );
    List<Widget> nav({required bool compactToday}) => [
      IconButton(
        icon: const Icon(Icons.chevron_left),
        tooltip: s.calendarPrevious,
        onPressed: onPrevious,
      ),
      IconButton(
        icon: const Icon(Icons.chevron_right),
        tooltip: s.calendarNext,
        onPressed: onNext,
      ),
      const SizedBox(width: 4),
      if (compactToday)
        IconButton(
          icon: const Icon(Icons.today_outlined),
          tooltip: s.calendarToday,
          onPressed: onToday,
        )
      else
        OutlinedButton(onPressed: onToday, child: Text(s.calendarToday)),
    ];
    return SizedBox(
      height: roomy ? 48 : 40,
      // The title, then the arrows and Today right after it, the switcher
      // on the right. When the row is tight the title takes its short
      // form, then Today becomes an icon. A switcher wider than half the
      // row, or than what the short title leaves, scrolls under the edge
      // fade (long labels in some languages), and only then is the title
      // cut.
      child: LayoutBuilder(
        builder: (context, box) {
          final gap = narrow ? 4.0 : 16.0;
          // The arrows, the gap after them, and Today as a button (sized
          // as the theme sizes it) or as an icon.
          const arrows = 48.0 * 2 + 4;
          final style = theme.outlinedButtonTheme.style;
          final button = math.max(
            style?.minimumSize?.resolve(const {})?.width ?? 64,
            measure(
                  s.calendarToday,
                  style?.textStyle?.resolve(const {}) ??
                      theme.textTheme.labelLarge,
                ) +
                (style?.padding?.resolve(const {})?.horizontal ?? 48) +
                2,
          );
          final filled = theme.filledButtonTheme.style;
          // The pill: its padding, the icon and the gap after it, the label.
          final add = onNew == null
              ? 0.0
              : 12 +
                    (roomy
                        ? (filled?.padding?.resolve(const {})?.horizontal ??
                                  48) +
                              26 +
                              measure(
                                s.calendarNewEvent,
                                filled?.textStyle?.resolve(const {}) ??
                                    theme.textTheme.labelLarge,
                              )
                        : 48);
          final width = box.maxWidth - add;
          final leftMin =
              measure(title.short, titleStyle) + gap + arrows + 48 + 12;
          final switcherMax = math.max(
            160.0,
            math.min(width * .5, width - leftMin),
          );
          final left = Expanded(
            child: LayoutBuilder(
              builder: (context, side) {
                bool fits(String text, double today) =>
                    measure(text, titleStyle) + gap + arrows + today <=
                    side.maxWidth;
                final compactToday =
                    !fits(title.long, button) && !fits(title.short, button);
                // The title takes what the arrows and Today leave, and the
                // short form when the long one does not fit there.
                final fitted = LayoutBuilder(
                  builder: (context, room) => titleText(
                    measure(title.long, titleStyle) <= room.maxWidth
                        ? title.long
                        : title.short,
                  ),
                );
                return Row(
                  children: [
                    if (narrow)
                      Expanded(child: fitted)
                    else
                      Flexible(child: fitted),
                    SizedBox(width: gap),
                    ...nav(compactToday: compactToday),
                  ],
                );
              },
            ),
          );
          return Row(
            children: [
              left,
              if (!narrow) ...[
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: switcherMax),
                  child: _ViewSwitcher(
                    view: view,
                    onView: onView,
                    scroll: true,
                  ),
                ),
              ],
              if (onNew != null) ...[
                const SizedBox(width: 12),
                if (roomy)
                  FilledButton.icon(
                    onPressed: onNew,
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(s.calendarNewEvent, maxLines: 1),
                  )
                else
                  IconButton.filled(
                    onPressed: onNew,
                    tooltip: s.calendarNewEvent,
                    icon: const Icon(Icons.add),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ViewSwitcher extends StatelessWidget {
  const _ViewSwitcher({
    required this.view,
    required this.onView,
    this.fill = false,
    this.scroll = false,
  });

  final String view;
  final ValueChanged<String> onView;

  /// A phone: the segments share the width, and scroll under the edge fade
  /// once they no longer fit.
  final bool fill;

  /// The header: the segments scroll under the edge fade when wider than
  /// the room they get.
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final labels = {
      'day': s.calendarViewDay,
      'week': s.calendarViewWeek,
      'month': s.calendarViewMonth,
      'schedule': s.calendarViewSchedule,
    };
    final button = SegmentedButton<String>(
      segments: [
        for (final v in _views)
          ButtonSegment(
            value: v,
            label: Text(labels[v]!, maxLines: 1, softWrap: false),
          ),
      ],
      selected: {view},
      showSelectedIcon: false,
      onSelectionChanged: (v) => onView(v.first),
    );
    final index = _views.indexOf(view);
    if (!fill) {
      return scroll ? _SegmentScroll(index: index, child: button) : button;
    }
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth < 340
          ? _SegmentScroll(index: index, child: button)
          : SizedBox(width: box.maxWidth, child: button),
    );
  }
}

/// ScrollingSegments that keeps the chosen view in sight. The segments are
/// equally wide, so the same share of the scroll range as the segment's
/// place in the row always shows it whole.
class _SegmentScroll extends StatefulWidget {
  const _SegmentScroll({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_SegmentScroll> createState() => _SegmentScrollState();
}

class _SegmentScrollState extends State<_SegmentScroll> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _follow(animate: false);
  }

  @override
  void didUpdateWidget(_SegmentScroll old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _follow(animate: true);
  }

  void _follow({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final max = _controller.position.maxScrollExtent;
      if (max <= 0) return;
      final to = max * widget.index / (_views.length - 1);
      if (animate) {
        unawaited(
          _controller.animateTo(
            to,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
        );
      } else {
        _controller.jumpTo(to);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EdgeFade(
    axis: Axis.horizontal,
    child: SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      child: widget.child,
    ),
  );
}

// ── Chips ─────────────────────────────────────────────────────────────────

/// The calendars in the top bar, one chip each: its avatar and name on a
/// tablet, the avatar alone where the bar is narrow (a short panel, a
/// phone). A tap hides the calendar on this kiosk and the choice stays.
/// More than fit scroll under the edge fade.
class _TopChips extends StatelessWidget {
  const _TopChips({required this.container, required this.named});

  final AppContainer container;
  final bool named;

  @override
  Widget build(BuildContext context) {
    final cal = container.calendar;
    final paint = CalendarPaint(context, cal);
    final hidden = cal.hidden.value;
    final scheme = Theme.of(context).colorScheme;
    void toggle(String entity) =>
        unawaited(cal.setHidden(entity, !hidden.contains(entity)));
    final chips = [
      for (final source in cal.enabled)
        if (named)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CalendarChip(
              label: source.name,
              on: !hidden.contains(source.entity),
              tint: paint.soft(source.entity),
              border: scheme.outlineVariant,
              avatar: CalendarAvatar(
                container: container,
                entity: source.entity,
                paint: paint,
                size: hidden.contains(source.entity) ? 26 : 28,
                muted: hidden.contains(source.entity),
              ),
              onTap: () => toggle(source.entity),
            ),
          )
        else
          Tooltip(
            message: source.name,
            child: InkResponse(
              radius: 22,
              onTap: () => toggle(source.entity),
              child: SizedBox(
                width: 42,
                height: 44,
                child: Center(
                  child: CalendarAvatar(
                    container: container,
                    entity: source.entity,
                    paint: paint,
                    size: 30,
                    muted: hidden.contains(source.entity),
                  ),
                ),
              ),
            ),
          ),
    ];
    return Align(
      child: EdgeFade(
        axis: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(mainAxisSize: MainAxisSize.min, children: chips),
        ),
      ),
    );
  }
}

/// One calendar's chip: its avatar and name, in its tint while on and
/// outlined while off. The top bar's and the event form's.
class CalendarChip extends StatelessWidget {
  const CalendarChip({
    super.key,
    required this.label,
    required this.on,
    required this.tint,
    required this.border,
    required this.avatar,
    required this.onTap,
  });

  final String label;
  final bool on;
  final Color tint;
  final Color border;
  final Widget avatar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      toggled: on,
      button: true,
      child: Material(
        color: on ? tint : Colors.transparent,
        shape: StadiumBorder(
          side: on ? BorderSide.none : BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 38,
            padding: const EdgeInsets.fromLTRB(5, 0, 16, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                avatar,
                const SizedBox(width: 9),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: on ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineLine extends StatelessWidget {
  const _OfflineLine({required this.at});

  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final when = at == null ? '' : calendarTime(context, at!);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: scheme.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n(context).calendarOffline(when),
              style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 56,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              s.calendarEmptyTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              s.calendarEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small pieces ──────────────────────────────────────────────────────────

/// A day's forecast in one line: the glyph, the high and, roomy, the low.
class _Forecast extends StatelessWidget {
  const _Forecast({required this.forecast, this.low = true, this.size = 12.5});

  final DayForecast? forecast;
  final bool low;
  final double size;

  @override
  Widget build(BuildContext context) {
    final f = forecast;
    if (f == null) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = TextStyle(
      fontSize: size,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(weatherConditionIcon(f.condition), size: size + 3.5, color: color),
        const SizedBox(width: 4),
        if (f.high != null) Text('${f.high!.round()}°', style: style),
        if (low && f.low != null) ...[
          const SizedBox(width: 4),
          Text(
            '${f.low!.round()}°',
            style: style.copyWith(color: color.withValues(alpha: .7)),
          ),
        ],
      ],
    );
  }
}

/// A day's number, in a filled disc when it is today.
class _DayNumber extends StatelessWidget {
  const _DayNumber({
    required this.day,
    required this.today,
    required this.size,
    this.muted = false,
  });

  final DateTime day;
  final bool today;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = DateFormat.d().format(day);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: today
          ? BoxDecoration(color: _todayFill, shape: BoxShape.circle)
          : null,
      child: Text(
        text,
        style: TextStyle(
          fontSize: today ? size * .46 : size * .58,
          fontWeight: today ? FontWeight.w600 : FontWeight.w400,
          color: today
              ? Colors.white
              : muted
              ? scheme.outline
              : scheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// The weekday's short name in caps, teal on today.
class _Weekday extends StatelessWidget {
  const _Weekday({required this.day, required this.today, this.narrow = false});

  final DateTime day;
  final bool today;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = narrow
        ? DateFormat.EEEEE().format(day)
        : DateFormat.E().format(day).toUpperCase();
    return Text(
      text,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.fade,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: .8,
        color: today ? scheme.secondary : scheme.onSurfaceVariant,
      ),
    );
  }
}

/// A shared event's colored dot, split like its tile.
class _Dot extends StatelessWidget {
  const _Dot({required this.colors, this.size = 8});

  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: CalendarBands(colors, circle: true)),
  );
}

/// A tile with its calendars' fill, or bands for a shared event.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.colors,
    required this.radius,
    required this.padding,
    required this.child,
    required this.onTap,
    this.height,
    this.lit = false,
  });

  final List<Color> colors;
  final double radius;
  final EdgeInsets padding;
  final Widget child;
  final VoidCallback onTap;
  final double? height;

  /// The event a voice request was about: a ring fades in around it.
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final tile = _tile();
    if (!lit) return tile;
    final ring = Theme.of(context).colorScheme.onSurface;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      builder: (context, t, child) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: ring.withValues(alpha: .85 * t),
            width: 2.5,
          ),
        ),
        child: child,
      ),
      child: tile,
    );
  }

  Widget _tile() => CustomPaint(
    painter: CalendarBands(colors, radius: radius),
    child: Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          width: double.infinity,
          padding: padding,
          child: child,
        ),
      ),
    ),
  );
}

TextStyle _titleStyle(BuildContext context, double size) => TextStyle(
  fontSize: size,
  fontWeight: FontWeight.w500,
  height: 1.25,
  color: Theme.of(context).colorScheme.onSurface,
);

TextStyle _mutedStyle(BuildContext context, double size) => TextStyle(
  fontSize: size,
  color: Theme.of(context).colorScheme.onSurfaceVariant,
  fontFeatures: const [FontFeature.tabularFigures()],
);

// ── Week ──────────────────────────────────────────────────────────────────

/// Seven columns of stacked entries, not an hour grid: the Skylight week.
/// Today stands on a raised surface with its date in a filled disc.
class _WeekColumns extends StatelessWidget {
  const _WeekColumns({required this.args});

  final _ViewArgs args;

  @override
  Widget build(BuildContext context) {
    final start = weekStart(args.anchor, args.firstWeekday);
    final gap = args.short ? 4.0 : 6.0;
    final empty = !args.events.any(
      (e) => e.start.isBefore(addDays(start, 7)) && e.end.isAfter(start),
    );
    final columns = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: _WeekDay(
              args: args,
              day: addDays(start, i),
              weekEmpty: empty,
            ),
          ),
        ],
      ],
    );
    if (!empty) return columns;
    // A whole week with nothing on it says so once, over the days, rather
    // than seven times.
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(child: columns),
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: args.short ? 22 : 32,
              vertical: args.short ? 16 : 24,
            ),
            decoration: BoxDecoration(
              color: args.paint.raised,
              border: args.paint.raisedBorder,
              borderRadius: BorderRadius.circular(args.short ? 18 : 24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: args.short ? 32 : 40,
                  color: scheme.onSurfaceVariant,
                ),
                SizedBox(height: args.short ? 8 : 12),
                Text(
                  l10n(context).calendarNothingThisWeek,
                  style: TextStyle(
                    fontSize: args.short ? 16 : 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekDay extends StatelessWidget {
  const _WeekDay({
    required this.args,
    required this.day,
    this.weekEmpty = false,
  });

  final _ViewArgs args;
  final DateTime day;

  /// Nothing on any day this week: the week says so once, so the days
  /// stay quiet.
  final bool weekEmpty;

  @override
  Widget build(BuildContext context) {
    final today = day == args.today;
    final short = args.short;
    final events = eventsOn(args.events, day);
    final header = InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => args.onDay(day),
      child: Padding(
        padding: EdgeInsets.fromLTRB(short ? 2 : 4, 2, 2, short ? 6 : 10),
        child: LayoutBuilder(
          builder: (context, box) {
            // A tablet in portrait: the weekday beside a smaller number,
            // the forecast on its own line under them.
            if (!short && box.maxWidth < 120) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _DayNumber(day: day, today: today, size: 30),
                      const SizedBox(width: 6),
                      Flexible(
                        child: _Weekday(day: day, today: today),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _Forecast(forecast: args.forecast(day)),
                ],
              );
            }
            return Row(
              children: [
                _DayNumber(day: day, today: today, size: short ? 30 : 40),
                SizedBox(width: short ? 6 : 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Weekday(day: day, today: today),
                      const SizedBox(height: 3),
                      _Forecast(forecast: args.forecast(day), low: !short),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    return Container(
      padding: short
          ? const EdgeInsets.fromLTRB(4, 6, 4, 4)
          : const EdgeInsets.fromLTRB(8, 12, 8, 8),
      // Every day is a soft panel, so the week reads as a week even with
      // little on it. Today stands up from the others.
      decoration: BoxDecoration(
        color: today ? args.paint.raised : args.paint.panel,
        border: today ? args.paint.raisedBorder : null,
        borderRadius: BorderRadius.circular(short ? 14 : 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (events.isEmpty && !weekEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(short ? 4 : 6, short ? 2 : 6, 4, 0),
              child: Text(
                l10n(context).calendarNothingPlanned,
                style: _mutedStyle(context, short ? 12 : 13),
              ),
            ),
          Expanded(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final e in events) ...[
                      _WeekTile(args: args, event: e, day: day),
                      SizedBox(height: short ? 4 : 6),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekTile extends StatelessWidget {
  const _WeekTile({required this.args, required this.event, this.day});

  final _ViewArgs args;
  final CalendarEvent event;
  final DateTime? day;

  @override
  Widget build(BuildContext context) {
    final p = args.paint;
    final timed = !event.allDay && (day == null || !_coversDay(event, day!));
    final colors = timed
        ? p.softs(event.calendars)
        : p.strongs(event.calendars);
    if (args.short) {
      return LayoutBuilder(
        builder: (context, box) {
          // Too narrow for the time beside the title (an Echo Show 5's
          // week): the title gets the line, the time goes under it.
          if (timed && box.maxWidth < 130) {
            return _Tile(
              colors: colors,
              radius: 9,
              padding: const EdgeInsets.fromLTRB(8, 5, 6, 5),
              lit: args.lit(event),
              onTap: () => args.onEvent(event),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _titleStyle(context, 12.5).copyWith(height: 1.2),
                  ),
                  Text(
                    calendarTime(context, _startOn(event, day), short: true),
                    maxLines: 1,
                    style: _mutedStyle(context, 11.5).copyWith(height: 1.2),
                  ),
                ],
              ),
            );
          }
          // Room for both on one line: the start time, then the title.
          return _Tile(
            colors: colors,
            radius: 9,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            lit: args.lit(event),
            onTap: () => args.onEvent(event),
            child: Row(
              children: [
                if (timed) ...[
                  Text(
                    calendarTime(context, _startOn(event, day), short: true),
                    style: _mutedStyle(context, 12),
                  ),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: Text(
                    event.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _titleStyle(context, 13),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        // A tablet in portrait: tighter padding, and a title with a word
        // too long for the line keeps to one ellipsized line rather than
        // break inside the word.
        final tight = box.maxWidth < 120;
        final titleStyle = _titleStyle(context, tight ? 13 : 14);
        final room = box.maxWidth - (tight ? 16 : 22);
        return _Tile(
          colors: colors,
          radius: timed ? 14 : 10,
          padding: tight
              ? EdgeInsets.fromLTRB(8, timed ? 7 : 5, 8, timed ? 8 : 5)
              : timed
              ? const EdgeInsets.fromLTRB(11, 9, 11, 10)
              : const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          lit: args.lit(event),
          onTap: () => args.onEvent(event),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.summary,
                maxLines: _wordsFit(context, event.summary, titleStyle, room)
                    ? 2
                    : 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              if (timed) ...[
                const SizedBox(height: 3),
                Text(
                  calendarTime(context, _startOn(event, day), short: tight),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: _mutedStyle(context, tight ? 12 : 12.5),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Whether every word of [text] fits on a line [width] wide, so wrapping
/// it never breaks inside a word.
bool _wordsFit(BuildContext context, String text, TextStyle style, double w) {
  final painter = TextPainter(
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  );
  final merged = DefaultTextStyle.of(context).style.merge(style);
  try {
    for (final word in text.split(RegExp(r'\s+'))) {
      painter
        ..text = TextSpan(text: word, style: merged)
        ..layout();
      if (painter.width > w) return false;
    }
    return true;
  } finally {
    painter.dispose();
  }
}

/// A timed event that runs through the whole of [day] reads as all day
/// there.
bool _coversDay(CalendarEvent e, DateTime day) =>
    !e.start.isAfter(day) && !e.end.isBefore(addDays(day, 1));

/// Where a timed event starts on [day]: its start, or midnight for the
/// days after its first.
DateTime _startOn(CalendarEvent e, DateTime? day) {
  if (day == null || !e.start.isBefore(day)) return e.start;
  return day;
}

// ── Day ───────────────────────────────────────────────────────────────────

/// One lane per calendar with its avatar and name, an all-day row and the
/// hours. A shared event shows in each of its people's lanes.
class _DayLanes extends StatelessWidget {
  const _DayLanes({required this.args});

  final _ViewArgs args;

  @override
  Widget build(BuildContext context) {
    final cal = args.cal;
    final hidden = cal.hidden.value;
    final lanes = [
      for (final c in cal.enabled)
        if (!hidden.contains(c.entity)) c,
    ];
    final day = args.anchor;
    final events = eventsOn(args.events, day);
    final allDay = [
      for (final e in events)
        if (e.allDay || _coversDay(e, day)) e,
    ];
    final timed = [
      for (final e in events)
        if (!e.allDay && !_coversDay(e, day)) e,
    ];
    final short = args.short;
    final scheme = Theme.of(context).colorScheme;
    // The all-day label wraps between words in the hours' gutter, and the
    // gutter widens for a long word ("GANZTÄGIG") rather than cut it.
    final allDayStyle = DefaultTextStyle.of(context).style.merge(
      TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: .6,
        color: scheme.onSurfaceVariant,
      ),
    );
    final allDayWords = l10n(
      context,
    ).calendarAllDay.toUpperCase().split(RegExp(r'\s+'));
    var longest = 0.0;
    for (final word in allDayWords) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: allDayStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      if (painter.width > longest) longest = painter.width;
      painter.dispose();
    }
    final baseWidth = short ? 52.0 : 64.0;
    final labelWidth = (longest + 8).ceilToDouble().clamp(
      baseWidth,
      baseWidth + 28,
    );
    final gap = short ? 6.0 : 8.0;
    Widget lanesRow(Widget Function(CalendarSource lane) cell) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: labelWidth),
        for (var i = 0; i < lanes.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: cell(lanes[i])),
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        lanesRow(
          (lane) => Row(
            children: [
              CalendarAvatar(
                container: args.container,
                entity: lane.entity,
                paint: args.paint,
                size: short ? 24 : 30,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  lane.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: short ? 13.5 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (allDay.isNotEmpty) ...[
          SizedBox(height: short ? 6 : 8),
          Stack(
            children: [
              // Not positioned, so a label on two lines makes the row
              // taller instead of running into the hours.
              Padding(
                padding: EdgeInsets.only(top: short ? 4 : 6),
                child: SizedBox(
                  width: labelWidth - 6,
                  child: Text(
                    allDayWords.join(' '),
                    style: allDayStyle.copyWith(height: 1.2),
                  ),
                ),
              ),
              lanesRow(
                (lane) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final e in allDay)
                      if (e.calendars.contains(lane.entity))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _Tile(
                            colors: args.paint.strongs(e.calendars),
                            radius: 9,
                            height: short ? 24 : 28,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            lit: args.lit(e),
                            onTap: () => args.onEvent(e),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                e.summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _titleStyle(context, 13),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: short ? 6 : 8),
        Expanded(
          child: _Timeline(
            // A new ring scrolls to its event, so it gets a fresh state.
            key: ValueKey((day, args.focusOn(day))),
            day: day,
            today: day == args.today,
            focus: args.focusOn(day),
            hourHeight: short ? 34 : 46,
            labelWidth: labelWidth,
            events: timed,
            lanes: [
              for (final lane in lanes)
                [
                  for (final e in timed)
                    if (e.calendars.contains(lane.entity)) e,
                ],
            ],
            gap: gap,
            build: (e, height) =>
                _TimelineTile(args: args, event: e, day: day, height: height),
            onSlot: args.onNew == null
                ? null
                : (lane, start) => args.onNew!(start, lanes[lane].entity),
          ),
        ),
      ],
    );
  }
}

/// The hours of one day with each lane's events placed on them, scrolled
/// to now on today and to the first event on other days.
class _Timeline extends StatefulWidget {
  const _Timeline({
    super.key,
    required this.day,
    required this.today,
    required this.hourHeight,
    required this.labelWidth,
    this.focus,
    required this.events,
    required this.lanes,
    required this.gap,
    required this.build,
    this.onSlot,
  });

  final DateTime day;
  final bool today;
  final double hourHeight;
  final double labelWidth;

  /// Scroll here first: the event a voice request was about.
  final DateTime? focus;
  final List<CalendarEvent> events;
  final List<List<CalendarEvent>> lanes;
  final double gap;
  final Widget Function(CalendarEvent event, double height) build;

  /// A tap on an empty hour drops a slot there, and a tap on the slot calls
  /// this with its lane and hour. Null when this kiosk takes no new events.
  final void Function(int lane, DateTime start)? onSlot;

  @override
  State<_Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<_Timeline> {
  late final ScrollController _scroll;
  Timer? _tick;

  /// The slot a tap on an empty hour dropped.
  ({int lane, int hour})? _slot;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    double hour;
    final focus = widget.focus;
    if (focus != null) {
      hour = focus.hour + focus.minute / 60 - 1.5;
    } else if (widget.today) {
      hour = now.hour + now.minute / 60 - 1.5;
    } else if (widget.events.isNotEmpty) {
      final first = widget.events.map((e) => _hourOf(e.start)).reduce(math.min);
      hour = first - .5;
    } else {
      hour = 7;
    }
    _scroll = ScrollController(
      initialScrollOffset: math.max(0, hour) * widget.hourHeight,
    );
    if (widget.today) {
      _tick = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  double _hourOf(DateTime t) {
    if (t.isBefore(widget.day)) return 0;
    if (!t.isBefore(addDays(widget.day, 1))) return 24;
    return t.hour + t.minute / 60;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hh = widget.hourHeight;
    final now = DateTime.now();
    final labels = [
      for (var h = 1; h < 24; h++)
        Positioned(
          top: h * hh - 8,
          left: 0,
          width: widget.labelWidth - 8,
          child: Text(
            calendarTime(context, DateTime(2000, 1, 1, h), short: true),
            style: _mutedStyle(context, 12),
          ),
        ),
    ];
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: SingleChildScrollView(
        controller: _scroll,
        child: SizedBox(
          height: 24 * hh,
          child: Stack(
            children: [
              for (var h = 1; h < 24; h++)
                Positioned(
                  top: h * hh,
                  left: widget.labelWidth,
                  right: 0,
                  child: Divider(height: 1, color: scheme.outlineVariant),
                ),
              ...labels,
              Positioned.fill(
                left: widget.labelWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < widget.lanes.length; i++) ...[
                      if (i > 0) SizedBox(width: widget.gap),
                      Expanded(child: _lane(i)),
                    ],
                  ],
                ),
              ),
              if (widget.today)
                Positioned(
                  top: (now.hour + now.minute / 60) * hh - 1,
                  left: widget.labelWidth - 6,
                  right: 0,
                  child: IgnorePointer(
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: scheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(height: 2, color: scheme.error),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lane(int lane) => LayoutBuilder(
    builder: (context, box) {
      final hh = widget.hourHeight;
      final onSlot = widget.onSlot;
      final slot = _slot;
      return Stack(
        children: [
          // Under the events, so a tap on one still opens it.
          if (onSlot != null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => setState(
                  () => _slot = (
                    lane: lane,
                    hour: (d.localPosition.dy / hh).floor().clamp(0, 23),
                  ),
                ),
              ),
            ),
          for (final placed in layoutColumns(widget.lanes[lane]))
            () {
              final top = _hourOf(placed.event.start) * hh + 1;
              final bottom = _hourOf(placed.event.end) * hh - 2;
              final height = math.max(bottom - top, 22.0);
              final width = box.maxWidth / placed.columns;
              return Positioned(
                top: top,
                left: placed.column * width,
                width: width - (placed.columns > 1 ? 2 : 0),
                height: height,
                child: widget.build(placed.event, height),
              );
            }(),
          if (onSlot != null && slot != null && slot.lane == lane)
            Positioned(
              top: slot.hour * hh + 1,
              left: 0,
              right: 0,
              height: hh - 3,
              child: CalendarSlot(
                radius: hh < 40 ? 9 : 12,
                onTap: () {
                  setState(() => _slot = null);
                  final d = widget.day;
                  onSlot(lane, DateTime(d.year, d.month, d.day, slot.hour));
                },
              ),
            ),
        ],
      );
    },
  );
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.args,
    required this.event,
    required this.day,
    required this.height,
  });

  final _ViewArgs args;
  final CalendarEvent event;
  final DateTime day;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Room for the time under the title.
    final tall = height >= 46;
    return _Tile(
      colors: args.paint.softs(event.calendars),
      radius: args.short ? 9 : 12,
      padding: tall
          ? const EdgeInsets.fromLTRB(10, 6, 10, 4)
          : const EdgeInsets.symmetric(horizontal: 9),
      lit: args.lit(event),
      onTap: () => args.onEvent(event),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: tall
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Text(
            event.summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _titleStyle(context, args.short ? 13 : 14),
          ),
          if (tall)
            Text(
              calendarWhen(context, event, on: day),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _mutedStyle(context, 12),
            ),
        ],
      ),
    );
  }
}

// ── Month ─────────────────────────────────────────────────────────────────

/// The month's weeks. Each day lists as many entries as fit, then "+N
/// more"; a tap opens the day.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.args});

  final _ViewArgs args;

  @override
  Widget build(BuildContext context) {
    final start = monthGridStart(args.anchor, args.firstWeekday);
    final weeks = monthGridWeeks(args.anchor, args.firstWeekday);
    final scheme = Theme.of(context).colorScheme;
    final line = BorderSide(color: scheme.outlineVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                  child: Text(
                    DateFormat.E().format(addDays(start, i)).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .8,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: line, left: line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var w = 0; w < weeks; w++)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var d = 0; d < 7; d++)
                          Expanded(
                            child: _MonthCell(
                              args: args,
                              day: addDays(start, w * 7 + d),
                              line: line,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({required this.args, required this.day, required this.line});

  final _ViewArgs args;
  final DateTime day;
  final BorderSide line;

  @override
  Widget build(BuildContext context) {
    final today = day == args.today;
    final inMonth = day.month == args.anchor.month;
    final short = args.short;
    final events = eventsOn(args.events, day);
    final itemHeight = short ? 17.0 : 20.0;
    final numberSize = short ? 20.0 : 28.0;
    return Material(
      color: today ? args.paint.raised : Colors.transparent,
      child: InkWell(
        onTap: () => args.onDay(day),
        child: Container(
          decoration: BoxDecoration(
            border: Border(right: line, bottom: line),
          ),
          padding: short
              ? const EdgeInsets.fromLTRB(4, 3, 4, 3)
              : const EdgeInsets.fromLTRB(6, 6, 6, 4),
          child: LayoutBuilder(
            builder: (context, box) {
              const gap = 2.0;
              final room = box.maxHeight - numberSize - gap;
              final slot = itemHeight + gap;
              // Every entry fits, or as many as leave room for the shorter
              // "+N more" line under them.
              final moreHeight = short ? 14.0 : 16.0;
              // Each entry is followed by its gap, the last one too.
              final all = (room / slot).floor();
              final shown = events.length <= all
                  ? events.length
                  : math.max(0, ((room - moreHeight) / slot).floor());
              final more = events.length - shown;
              // Too small to list what is on (an Echo Show 5's month): a dot
              // per event in its calendar's colors, and how many when they
              // do not all fit.
              if (events.length > all && all < 2) {
                const dots = 4;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DayNumber(
                      day: day,
                      today: today,
                      size: numberSize,
                      muted: !inMonth,
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          for (final e in events.take(dots)) ...[
                            _Dot(
                              colors: args.paint.bases(e.calendars),
                              size: 7,
                            ),
                            const SizedBox(width: 3),
                          ],
                          if (events.length > dots)
                            Flexible(
                              child: Text(
                                l10n(
                                  context,
                                ).calendarMore('${events.length - dots}'),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: _mutedStyle(context, 10.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DayNumber(
                    day: day,
                    today: today,
                    size: numberSize,
                    muted: !inMonth,
                  ),
                  SizedBox(height: gap),
                  for (final e in events.take(shown)) ...[
                    _MonthItem(
                      args: args,
                      event: e,
                      day: day,
                      height: itemHeight,
                    ),
                    SizedBox(height: gap),
                  ],
                  if (more > 0)
                    Container(
                      height: moreHeight,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: short ? 5 : 8),
                      child: Text(
                        l10n(context).calendarMore('$more'),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: short ? 11 : 12,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MonthItem extends StatelessWidget {
  const _MonthItem({
    required this.args,
    required this.event,
    required this.day,
    required this.height,
  });

  final _ViewArgs args;
  final CalendarEvent event;
  final DateTime day;
  final double height;

  @override
  Widget build(BuildContext context) {
    final short = args.short;
    final timed = !event.allDay && !_coversDay(event, day);
    final size = short ? 11.5 : 12.5;
    final text = Text(
      event.summary,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w500),
    );
    if (!timed) {
      return CustomPaint(
        painter: CalendarBands(
          args.paint.strongs(event.calendars),
          radius: short ? 5 : 7,
        ),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: short ? 5 : 8),
          alignment: Alignment.centerLeft,
          child: text,
        ),
      );
    }
    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: short ? 3 : 6),
        // A narrow cell (a tablet in portrait) keeps the title and leaves
        // the time to the event's details.
        child: LayoutBuilder(
          builder: (context, box) => Row(
            children: [
              _Dot(
                colors: args.paint.bases(event.calendars),
                size: short ? 7 : 8,
              ),
              SizedBox(width: short ? 4 : 6),
              if (box.maxWidth >= 110) ...[
                Text(
                  calendarTime(context, _startOn(event, day), short: true),
                  style: _mutedStyle(context, size),
                ),
                SizedBox(width: short ? 4 : 6),
              ],
              Expanded(child: text),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Schedule ──────────────────────────────────────────────────────────────

/// Today on the left (the date, the weather, Up next and Later today), the
/// coming days on the right.
class _Schedule extends StatelessWidget {
  const _Schedule({required this.args});

  final _ViewArgs args;

  @override
  Widget build(BuildContext context) {
    final short = args.short;
    // Today takes at most 40% of the width, so a tablet in portrait still
    // leaves the list room for its titles.
    return LayoutBuilder(
      builder: (context, box) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: math.min(short ? 290.0 : 360.0, box.maxWidth * .4),
            child: _TodayPanel(args: args),
          ),
          SizedBox(width: short ? 16 : 28),
          Expanded(child: _ScheduleList(args: args, phone: false)),
        ],
      ),
    );
  }
}

class _TodayPanel extends StatelessWidget {
  const _TodayPanel({required this.args});

  final _ViewArgs args;

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    final short = args.short;
    final now = DateTime.now();
    final today = args.today;
    final coming = upNext(args.events, now);
    final next = coming.isEmpty ? null : coming.first;
    final later = coming.skip(1).toList();
    final allDay = [
      for (final e in eventsOn(args.events, today))
        if (e.allDay || _coversDay(e, today)) e,
    ];
    final forecast = args.forecast(today);
    return _PanelBody(
      paint: args.paint,
      short: short,
      children: [
        Text(
          s.calendarToday.toUpperCase(),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: .8,
            color: scheme.secondary,
          ),
        ),
        const SizedBox(height: 4),
        // The header already names the month, so the day and its number
        // fit one line: Tuesday 27.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            DateFormat.EEEE().add_d().format(today),
            maxLines: 1,
            style: TextStyle(
              fontSize: short ? 28 : 40,
              fontWeight: FontWeight.w300,
              height: 1.05,
              letterSpacing: -.5,
            ),
          ),
        ),
        if (forecast != null) ...[
          const SizedBox(height: 8),
          _Forecast(forecast: forecast, size: 15),
        ],
        // Today's all-day events, under the date they belong to.
        if (allDay.isNotEmpty) ...[
          SizedBox(height: short ? 10 : 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in allDay)
                IntrinsicWidth(
                  child: _Tile(
                    colors: args.paint.strongs(e.calendars),
                    radius: 9,
                    height: short ? 26 : 30,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    lit: args.lit(e),
                    onTap: () => args.onEvent(e),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        e.summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _titleStyle(context, short ? 13 : 14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        SizedBox(height: short ? 14 : 20),
        if (next == null)
          Text(s.calendarNothingElseToday, style: _mutedStyle(context, 15))
        else
          _Tile(
            colors: args.paint.softs(next.calendars),
            radius: short ? 14 : 18,
            padding: EdgeInsets.all(short ? 14 : 18),
            lit: args.lit(next),
            onTap: () => args.onEvent(next),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      s.calendarUpNext.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        calendarStartsIn(context, next.start, now),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _mutedStyle(context, 12.5),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: short ? 6 : 10),
                Text(
                  next.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _titleStyle(context, short ? 19 : 24),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    calendarWhen(context, next, on: today),
                    if (next.location.isNotEmpty) next.location,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _mutedStyle(context, 14),
                ),
                if (!short) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CalendarAvatarStack(
                        container: args.container,
                        entities: next.calendars,
                        paint: args.paint,
                        ring: args.paint.soft(next.calendars.first),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          calendarNames(s, [
                            for (final id in next.calendars)
                              args.cal.source(id)?.name ?? id,
                          ]),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        if (later.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            s.calendarLaterToday.toUpperCase(),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: .6,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          for (final e in later)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => args.onEvent(e),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    _Dot(colors: args.paint.bases(e.calendars)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 76,
                      child: Text(
                        calendarTime(context, e.start),
                        style: _mutedStyle(context, 13.5),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _titleStyle(context, 14.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// The Today panel's contents: one column that scrolls under the edge fade
/// when the date, the all-day events, Up next and Later today are taller
/// than the panel. Later today is the rest of today's events, so it never
/// shrinks to fit what is left. The panel is its own Material, so the
/// fade takes the raised color and runs to the rounded edge.
class _PanelBody extends StatelessWidget {
  const _PanelBody({
    required this.paint,
    required this.short,
    required this.children,
  });

  final CalendarPaint paint;
  final bool short;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: paint.raised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(short ? 18 : 24),
        side: paint.raisedBorder?.top ?? BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: EdgeFade(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(short ? 18 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// The coming days as a list grouped by day, from the anchor (after today
/// on a tablet, where the panel already shows today). A phone names the
/// first two days Today and Tomorrow.
class _ScheduleList extends StatelessWidget {
  const _ScheduleList({required this.args, required this.phone});

  final _ViewArgs args;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final today = args.today;
    final now = DateTime.now();
    var from = args.anchor;
    if (!phone && from == today) from = addDays(today, 1);
    final groups = <(DateTime, List<CalendarEvent>)>[];
    for (var i = 0; i < 14; i++) {
      final day = addDays(from, i);
      final events = [
        for (final e in eventsOn(args.events, day))
          if (day != today || e.allDay || e.end.isAfter(now)) e,
      ];
      if (events.isNotEmpty) groups.add((day, events));
    }
    if (groups.isEmpty) {
      return Center(
        child: Text(s.calendarNothingPlanned, style: _mutedStyle(context, 16)),
      );
    }
    final short = args.short;
    return EdgeFade(
      child: ListView.separated(
        padding: EdgeInsets.only(
          top: 4,
          bottom: phone && args.onNew != null ? 88 : 24,
        ),
        itemCount: groups.length,
        separatorBuilder: (_, _) => SizedBox(height: short ? 14 : 22),
        itemBuilder: (context, i) {
          final (day, events) = groups[i];
          final rows = [
            for (final e in events) ...[
              _AgendaRow(args: args, event: e, day: day, phone: phone),
              const SizedBox(height: 6),
            ],
          ];
          if (phone) {
            final label = day == today
                ? s.calendarToday
                : day == addDays(today, 1)
                ? s.calendarTomorrow
                : DateFormat.EEEE().format(day);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: day == today
                                ? Theme.of(context).colorScheme.secondary
                                : null,
                          ),
                        ),
                        TextSpan(
                          text: '  ${DateFormat.MMMMd().format(day)}',
                          style: _mutedStyle(context, 14),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                ...rows,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: short ? 44 : 64,
                child: Column(
                  children: [
                    Text(
                      DateFormat.E().format(day).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .8,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      DateFormat.d().format(day),
                      style: TextStyle(
                        fontSize: short ? 24 : 34,
                        fontWeight: FontWeight.w300,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: short ? 12 : 16),
              Expanded(child: Column(children: rows)),
            ],
          );
        },
      ),
    );
  }
}

/// One event in a list: its time, title and place, and who it is for.
class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.args,
    required this.event,
    required this.day,
    required this.phone,
  });

  final _ViewArgs args;
  final CalendarEvent event;
  final DateTime day;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final short = args.short || phone;
    final allDay = event.allDay || _coversDay(event, day);
    final p = args.paint;
    final colors = allDay
        ? p.strongs(event.calendars)
        : p.softs(event.calendars);
    final whenWidth = phone ? 64.0 : (args.short ? 76.0 : 150.0);
    final title = Text(
      event.summary,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _titleStyle(context, short ? 15 : 15.5),
    );
    final location = event.location.isEmpty
        ? null
        : Text(
            event.location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _mutedStyle(context, 13),
          );
    final avatars = CalendarAvatarStack(
      container: args.container,
      entities: event.calendars,
      paint: p,
      ring: colors.last,
      size: short ? 24 : 26,
    );
    final Widget when = phone && !allDay
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                calendarTime(context, _startOn(event, day)),
                style: _titleStyle(context, 13).copyWith(height: 1.2),
              ),
              Text(
                calendarTime(context, event.end),
                style: _mutedStyle(context, 13),
              ),
            ],
          )
        : Text(
            allDay
                ? l10n(context).calendarAllDay
                : args.short
                ? calendarTime(context, _startOn(event, day), short: true)
                : calendarWhen(context, event, on: day),
            style: _mutedStyle(context, short ? 13 : 14),
          );
    return LayoutBuilder(
      builder: (context, box) {
        // Too narrow for the time column beside the title (a tablet in
        // portrait): the title on top, the time and place under it.
        final stacked = !short && box.maxWidth < 400;
        return _Tile(
          colors: colors,
          radius: short ? 14 : 16,
          padding: EdgeInsets.symmetric(
            horizontal: short ? 14 : 16,
            vertical: short ? 10 : 12,
          ),
          lit: args.lit(event),
          onTap: () => args.onEvent(event),
          child: Row(
            children: [
              if (!stacked) ...[
                SizedBox(width: whenWidth, child: when),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    title,
                    if (stacked)
                      Text(
                        allDay
                            ? l10n(context).calendarAllDay
                            : calendarWhen(context, event, on: day),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _mutedStyle(context, 13),
                      ),
                    ?location,
                  ],
                ),
              ),
              const SizedBox(width: 8),
              avatars,
            ],
          ),
        );
      },
    );
  }
}

// ── Phone ─────────────────────────────────────────────────────────────────

/// The chosen day's heading and its forecast.
class _PhoneDayHeading extends StatelessWidget {
  const _PhoneDayHeading({required this.args});

  final _ViewArgs args;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            DateFormat.MMMMEEEEd().format(args.anchor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        _Forecast(forecast: args.forecast(args.anchor), size: 13.5),
      ],
    ),
  );
}

class _PhoneDayList extends StatelessWidget {
  const _PhoneDayList({required this.args});

  final _ViewArgs args;

  @override
  Widget build(BuildContext context) {
    final events = eventsOn(args.events, args.anchor);
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(
          l10n(context).calendarNothingPlanned,
          textAlign: TextAlign.center,
          style: _mutedStyle(context, 15),
        ),
      );
    }
    return EdgeFade(
      child: ListView(
        // Room to scroll the last row out from under New event.
        padding: EdgeInsets.only(bottom: args.onNew == null ? 24 : 88),
        children: [
          for (final e in events) ...[
            _AgendaRow(args: args, event: e, day: args.anchor, phone: true),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// A phone's week: a strip of the seven days with dots for what is on,
/// and the chosen day's list under it.
class _PhoneWeek extends StatelessWidget {
  const _PhoneWeek({required this.args});

  final _ViewArgs args;

  @override
  Widget build(BuildContext context) {
    final start = weekStart(args.anchor, args.firstWeekday);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _StripDay(args: args, day: addDays(start, i)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PhoneDayHeading(args: args),
        Expanded(child: _PhoneDayList(args: args)),
      ],
    );
  }
}

class _StripDay extends StatelessWidget {
  const _StripDay({required this.args, required this.day});

  final _ViewArgs args;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final selected = day == args.anchor;
    final today = day == args.today;
    final scheme = Theme.of(context).colorScheme;
    final dots = eventsOn(args.events, day).take(3).toList();
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => args.onSelect(day),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 2, 0, 8),
        child: Column(
          children: [
            _Weekday(day: day, today: today, narrow: true),
            const SizedBox(height: 5),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: today ? _todayFill : null,
                border: selected && !today
                    ? Border.all(color: scheme.outline, width: 1.5)
                    : null,
              ),
              child: Text(
                DateFormat.d().format(day),
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: today || selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: today ? Colors.white : scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final e in dots) ...[
                    _Dot(colors: args.paint.bases(e.calendars), size: 6),
                    const SizedBox(width: 3),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A phone's day: the all-day entries, then one timeline where events that
/// overlap share the width.
class _PhoneDay extends StatelessWidget {
  const _PhoneDay({required this.args});

  final _ViewArgs args;

  @override
  Widget build(BuildContext context) {
    final day = args.anchor;
    final events = eventsOn(args.events, day);
    final allDay = [
      for (final e in events)
        if (e.allDay || _coversDay(e, day)) e,
    ];
    final timed = [
      for (final e in events)
        if (!e.allDay && !_coversDay(e, day)) e,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PhoneDayHeading(args: args),
        if (allDay.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 52, bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in allDay)
                  IntrinsicWidth(
                    child: _Tile(
                      colors: args.paint.strongs(e.calendars),
                      radius: 9,
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      lit: args.lit(e),
                      onTap: () => args.onEvent(e),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          e.summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _titleStyle(context, 13.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: _Timeline(
            // A new ring scrolls to its event, so it gets a fresh state.
            key: ValueKey((day, args.focusOn(day))),
            day: day,
            today: day == args.today,
            focus: args.focusOn(day),
            hourHeight: 42,
            labelWidth: 52,
            events: timed,
            lanes: [timed],
            gap: 0,
            build: (e, height) =>
                _TimelineTile(args: args, event: e, day: day, height: height),
            onSlot: args.onNew == null
                ? null
                : (_, start) => args.onNew!(start, null),
          ),
        ),
      ],
    );
  }
}

/// A phone's month: a grid of dots, the chosen day's list under it.
class _PhoneMonth extends StatelessWidget {
  const _PhoneMonth({required this.args});

  final _ViewArgs args;

  @override
  Widget build(BuildContext context) {
    final start = monthGridStart(args.anchor, args.firstWeekday);
    final weeks = monthGridWeeks(args.anchor, args.firstWeekday);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: _Weekday(
                    day: addDays(start, i),
                    today: false,
                    narrow: true,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var w = 0; w < weeks; w++)
          SizedBox(
            height: 46,
            child: Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: _PhoneMonthDay(
                      args: args,
                      day: addDays(start, w * 7 + d),
                    ),
                  ),
              ],
            ),
          ),
        Divider(height: 13, color: scheme.outlineVariant),
        const SizedBox(height: 4),
        _PhoneDayHeading(args: args),
        Expanded(child: _PhoneDayList(args: args)),
      ],
    );
  }
}

class _PhoneMonthDay extends StatelessWidget {
  const _PhoneMonthDay({required this.args, required this.day});

  final _ViewArgs args;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final today = day == args.today;
    final selected = day == args.anchor;
    final scheme = Theme.of(context).colorScheme;
    final dots = eventsOn(args.events, day).take(3).toList();
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => args.onSelect(day),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: today ? _todayFill : null,
              border: selected && !today
                  ? Border.all(color: scheme.outline, width: 1.5)
                  : null,
            ),
            child: Text(
              DateFormat.d().format(day),
              style: TextStyle(
                fontSize: 15,
                fontWeight: today ? FontWeight.w600 : FontWeight.w400,
                color: today
                    ? Colors.white
                    : day.month == args.anchor.month
                    ? scheme.onSurface
                    : scheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in dots) ...[
                  _Dot(colors: args.paint.bases(e.calendars), size: 6),
                  if (e != dots.last) const SizedBox(width: 3),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Event details ─────────────────────────────────────────────────────────

/// How an event repeats, in words, from its RRULE. [instance] is a day of
/// a series whose rule did not come along.
String? calendarRepeatText(
  UiStrings s,
  String? rrule, {
  bool instance = false,
}) => switch (rruleFrequency(rrule)) {
  null => instance ? s.calendarRepeats : null,
  'DAILY' => s.calendarRepeatsDaily,
  'WEEKLY' => s.calendarRepeatsWeekly,
  'MONTHLY' => s.calendarRepeatsMonthly,
  'YEARLY' => s.calendarRepeatsYearly,
  _ => s.calendarRepeats,
};

/// The event's details: who it is for, the title, when, how it repeats,
/// where and the notes, then Done. With [changes] (not on the screensaver)
/// and Settings > Calendar > Editing allowing it, Delete and Edit too. Edit
/// opens the event form, and a cancelled form comes back here.
Future<void> showCalendarEvent(
  BuildContext context,
  AppContainer container,
  CalendarEvent event, {
  bool changes = false,
}) async {
  final cal = container.calendar;
  // The whole event, hidden calendars and all: a change goes to each copy.
  final full = cal.snapshot.value.events.firstWhere(
    (e) => e.key == event.key,
    orElse: () => event,
  );
  bool allows(int feature) =>
      full.calendars.any((id) => cal.calendarAllows(id, feature));
  final action = await showDialog<String>(
    context: context,
    builder: (context) => _EventDialog(
      container: container,
      event: event,
      full: full,
      canEdit: changes && calendarCanEdit(container) && allows(calendarUpdates),
      canDelete:
          changes && calendarCanDelete(container) && allows(calendarDeletes),
    ),
  );
  if (action != 'edit' || !context.mounted) return;
  final saved = await showCalendarEditor(context, container, event: full);
  if (!saved && context.mounted) {
    await showCalendarEvent(context, container, event, changes: changes);
  }
}

class _EventDialog extends StatelessWidget {
  const _EventDialog({
    required this.container,
    required this.event,
    required this.full,
    this.canEdit = false,
    this.canDelete = false,
  });

  final AppContainer container;

  /// The event as drawn, and [full] with every calendar it is on.
  final CalendarEvent event;
  final CalendarEvent full;
  final bool canEdit;
  final bool canDelete;

  String? _repeat(UiStrings s) =>
      calendarRepeatText(s, event.rrule, instance: event.recurrenceId != null);

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    final cal = container.calendar;
    final paint = CalendarPaint(context, cal);
    final compact =
        calendarLayout(MediaQuery.sizeOf(context)) != CalendarLayout.roomy;
    final names = [
      for (final id in event.calendars) cal.source(id)?.name ?? id,
    ];
    final lastDay = event.allDay
        ? addDays(event.end, -1)
        : event.end.subtract(const Duration(microseconds: 1));
    final date = dateOnly(event.start) == dateOnly(lastDay)
        ? DateFormat.yMMMMEEEEd().format(event.start)
        : s.calendarTimeRange(
            DateFormat.MMMEd().format(event.start),
            DateFormat.yMMMEd().format(lastDay),
          );
    final time = event.allDay
        ? s.calendarAllDay
        : s.calendarTimeRange(
            calendarTime(context, event.start),
            calendarTime(context, event.end),
          );
    final repeat = _repeat(s);
    Widget line(IconData icon, Widget child) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: scheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line(
          Icons.schedule,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(fontSize: 15.5)),
              const SizedBox(height: 3),
              Text(time, style: _mutedStyle(context, 15.5)),
            ],
          ),
        ),
        if (repeat != null)
          line(
            Icons.repeat,
            Text(repeat, style: const TextStyle(fontSize: 15.5)),
          ),
        if (event.location.isNotEmpty)
          line(
            Icons.place_outlined,
            Text(event.location, style: const TextStyle(fontSize: 15.5)),
          ),
        if (event.description.isNotEmpty)
          line(
            Icons.notes,
            Text(
              event.description,
              style: _mutedStyle(context, 15).copyWith(height: 1.5),
            ),
          ),
      ],
    );
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 480 : 560),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 22 : 28,
            compact ? 20 : 28,
            compact ? 22 : 28,
            compact ? 16 : 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CustomPaint(
                  painter: CalendarBands(
                    paint.softs(event.calendars),
                    radius: 100,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 2, 12, 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CalendarAvatarStack(
                          container: container,
                          entities: event.calendars,
                          paint: paint,
                          ring: paint.soft(event.calendars.first),
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          calendarNames(s, names),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                event.summary,
                style: TextStyle(
                  fontSize: compact ? 24 : 30,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                  letterSpacing: -.3,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(child: SingleChildScrollView(child: body)),
              const SizedBox(height: 20),
              // Delete on the left, Edit and Done on the right, and Delete
              // on a line of its own when a narrow dialog or long labels
              // leave no room for all three.
              Wrap(
                alignment: canDelete
                    ? WrapAlignment.spaceBetween
                    : WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                children: [
                  if (canDelete)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                      onPressed: () async {
                        final gone = await confirmCalendarDelete(
                          context,
                          container,
                          full,
                        );
                        if (gone && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(s.commonDelete),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      if (canEdit)
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop('edit'),
                          child: Text(s.commonEdit),
                        ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(s.calendarDone),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
