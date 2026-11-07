import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_container.dart';
import '../l10n/generated/ui_strings.dart';
import '../l10n/messages.dart';
import '../managers/calendar/calendar_edits.dart';
import '../managers/calendar/calendar_manager.dart';
import '../managers/calendar/calendar_model.dart';
import '../managers/calendar/calendar_requests.dart';
import '../managers/settings/definitions.dart' as defs;
import 'calendar_overlay.dart';
import 'clock_setting.dart';
import 'kit.dart';
import 'time_picker.dart';
import 'toast.dart';

/// Whether this kiosk lets people add and change events from the screen:
/// Settings > Calendar > Editing, both off by default.
bool calendarCanEdit(AppContainer c) => c.settings.get(defs.calendarAllowEdit);

bool calendarCanDelete(AppContainer c) =>
    c.settings.get(defs.calendarAllowDelete);

/// The calendars New event offers: the ones whose integration takes new
/// events, and the ones [event] is already on.
List<CalendarSource> calendarWritable(
  CalendarManager cal, [
  CalendarEvent? event,
]) => [
  for (final source in cal.enabled)
    if (event?.calendars.contains(source.entity) == true ||
        cal.calendarAllows(source.entity, calendarCreates))
      source,
];

/// What went wrong with an edit, in a line for its toast.
String calendarEditMessage(
  UiStrings s,
  CalendarManager cal,
  CalendarEditError e,
) {
  final id = e.calendar;
  final name = id == null ? '' : (cal.source(id)?.name ?? id);
  return switch (e.failure) {
    CalendarEditFailure.readOnly => s.calendarEditReadOnly(name),
    CalendarEditFailure.gone => s.calendarEditGone(name),
    CalendarEditFailure.notAllowed => s.calendarEditNotAllowed(name),
    CalendarEditFailure.refused => '${e.cause ?? ''}'.replaceFirst(
      RegExp(r'^(Bad state|Exception): '),
      '',
    ),
  };
}

/// New event, or Edit for [event]: a dialog on a tablet, the whole screen
/// on a short panel (two columns) and on a phone. A new event starts at
/// [start] on [calendar], or the first calendar that takes events. True
/// once it saved.
Future<bool> showCalendarEditor(
  BuildContext context,
  AppContainer container, {
  CalendarEvent? event,
  DateTime? start,
  String? calendar,
}) async {
  final roomy =
      calendarLayout(MediaQuery.sizeOf(context)) == CalendarLayout.roomy;
  final saved = await showDialog<bool>(
    context: context,
    // A stray tap must not throw away what was typed.
    barrierDismissible: false,
    builder: (context) {
      final form = _EventEditor(
        container: container,
        event: event,
        start: start,
        calendar: calendar,
      );
      return ClockSetting(
        container: container,
        setting: defs.calendarClock24h,
        child: roomy
            ? Dialog(
                insetPadding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: form,
                ),
              )
            : Dialog.fullscreen(
                backgroundColor: calendarGround(Theme.of(context)),
                child: form,
              ),
      );
    },
  );
  return saved ?? false;
}

/// Asks before [event] comes off its calendars (and which days, when it
/// repeats), then deletes it. True once it is gone.
Future<bool> confirmCalendarDelete(
  BuildContext context,
  AppContainer container,
  CalendarEvent event,
) async {
  final s = l10n(context);
  final cal = container.calendar;
  final overlay = Overlay.of(context, rootOverlay: true);
  final names = [for (final id in event.calendars) cal.source(id)?.name ?? id];
  final repeats = event.recurrenceId != null;
  final lines = [
    if (!repeats) ...[
      DateFormat.yMMMMEEEEd().format(event.start),
      calendarWhen(context, event),
    ],
    if (names.length > 1) s.calendarDeleteShared(calendarNames(s, names)),
  ];
  final done = await showDialog<String>(
    context: context,
    builder: (_) => _ScopeDialog(
      container: container,
      title: s.calendarDeleteTitle(event.summary),
      message: lines.isEmpty ? null : lines.join('\n'),
      scopes: repeats ? const ['this', 'following', 'all'] : const ['this'],
      day: event.start,
      confirmLabel: s.commonDelete,
      destructive: true,
      failedTitle: s.calendarDeleteFailed,
      run: (scope) => cal.edits.remove(event, scope),
    ),
  );
  if (done == null) return false;
  showToastIn(overlay, title: s.calendarEventDeleted, kind: ToastKind.success);
  return true;
}

class _EventEditor extends StatefulWidget {
  const _EventEditor({
    required this.container,
    this.event,
    this.start,
    this.calendar,
  });

  final AppContainer container;
  final CalendarEvent? event;
  final DateTime? start;
  final String? calendar;

  @override
  State<_EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<_EventEditor> {
  CalendarManager get cal => widget.container.calendar;

  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  late final Set<String> _calendars;
  late bool _allDay;

  /// The first and last moment. For an all-day event only their dates
  /// count, and the end is the last day, not the day after it.
  late DateTime _start;
  late DateTime _end;
  late String _repeat;
  late final String _repeatAtFirst;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _title = TextEditingController(text: e?.summary ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _notes = TextEditingController(text: e?.description ?? '');
    if (e != null) {
      _calendars = {...e.calendars};
      _allDay = e.allDay;
      _start = e.start;
      _end = e.allDay ? addDays(e.end, -1) : e.end;
      _repeat = calendarRepeatPreset(e.rrule, e.start);
    } else {
      final now = DateTime.now();
      _start =
          widget.start ?? DateTime(now.year, now.month, now.day, now.hour + 1);
      _end = _start.add(const Duration(hours: 1));
      _allDay = false;
      _repeat = 'none';
      final hidden = cal.hidden.value;
      final writable = calendarWritable(cal);
      final first = writable
          .where((c) => !hidden.contains(c.entity))
          .followedBy(writable)
          .firstOrNull;
      _calendars = {
        if (widget.calendar != null &&
            writable.any((c) => c.entity == widget.calendar))
          widget.calendar!
        else if (first != null)
          first.entity,
      };
    }
    _repeatAtFirst = _repeat;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _endOk => _allDay
      ? !dateOnly(_end).isBefore(dateOnly(_start))
      : _end.isAfter(_start);

  bool get _canSave =>
      !_saving &&
      _title.text.trim().isNotEmpty &&
      _calendars.isNotEmpty &&
      _endOk;

  CalendarDraft get _draft => CalendarDraft(
    summary: _title.text.trim(),
    start: _allDay ? dateOnly(_start) : _start,
    end: _allDay ? addDays(dateOnly(_end), 1) : _end,
    allDay: _allDay,
    description: _notes.text.trim(),
    location: _location.text.trim(),
    rrule: calendarRepeatRule(_repeat, widget.event?.rrule),
  );

  Future<void> _save() async {
    final s = l10n(context);
    final e = widget.event;
    var scope = 'this';
    if (e != null && e.recurrenceId != null) {
      // A new repeat cannot apply to one day alone.
      final picked = await showDialog<String>(
        context: context,
        builder: (_) => _ScopeDialog(
          container: widget.container,
          title: s.calendarSaveRepeatTitle(_title.text.trim()),
          message: _repeat == _repeatAtFirst
              ? null
              : s.calendarSaveRepeatFollowing,
          scopes: _repeat == _repeatAtFirst
              ? const ['this', 'following']
              : const ['following'],
          day: e.start,
          confirmLabel: s.commonSave,
        ),
      );
      if (picked == null || !mounted) return;
      scope = picked;
    }
    if (!mounted) return;
    setState(() => _saving = true);
    final overlay = Overlay.of(context, rootOverlay: true);
    final calendars = [
      for (final c in cal.enabled)
        if (_calendars.contains(c.entity)) c.entity,
    ];
    try {
      if (e == null) {
        await cal.edits.add(calendars, _draft);
      } else {
        await cal.edits.change(e, _draft, calendars: calendars, scope: scope);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showToastIn(
        overlay,
        title: e == null ? s.calendarEventAdded : s.calendarEventSaved,
        kind: ToastKind.success,
      );
    } on CalendarEditError catch (err) {
      if (!mounted) return;
      setState(() => _saving = false);
      showToastIn(
        overlay,
        title: s.calendarSaveFailed,
        message: calendarEditMessage(s, cal, err),
        kind: ToastKind.error,
      );
    }
  }

  void _setAllDay(bool on) => setState(() {
    _allDay = on;
    // An all-day event turned timed starts at 9 rather than midnight.
    if (!on && _start.hour == 0 && _start.minute == 0) {
      _start = DateTime(_start.year, _start.month, _start.day, 9);
      final end = DateTime(_end.year, _end.month, _end.day, 10);
      _end = end.isAfter(_start) ? end : _start.add(const Duration(hours: 1));
    }
  });

  /// A new start moves the end with it, so the length stays.
  void _moveStart(DateTime to) => setState(() {
    final length = _end.difference(_start);
    _start = to;
    _end = to.add(length);
  });

  Future<void> _pickDate({required bool start}) async {
    final current = start ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 5),
      lastDate: DateTime(current.year + 10),
    );
    if (picked == null || !mounted) return;
    final at = DateTime(
      picked.year,
      picked.month,
      picked.day,
      current.hour,
      current.minute,
    );
    if (start) {
      _moveStart(at);
    } else {
      setState(() => _end = at);
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final s = l10n(context);
    final current = start ? _start : _end;
    String two(int n) => n.toString().padLeft(2, '0');
    final picked = await showKsTimePicker(
      context,
      title: start ? s.calendarFieldStartTime : s.calendarFieldEndTime,
      initial: '${two(current.hour)}:${two(current.minute)}',
    );
    if (picked == null || !mounted) return;
    final [h, m] = [for (final p in picked.split(':')) int.tryParse(p) ?? 0];
    final at = DateTime(current.year, current.month, current.day, h, m);
    if (start) {
      _moveStart(at);
    } else {
      setState(() => _end = at);
    }
  }

  String _repeatLabel(UiStrings s, String preset) => switch (preset) {
    'none' => s.calendarRepeatNever,
    'daily' => s.calendarRepeatsDaily,
    'weekdays' => s.calendarRepeatWeekdays,
    'weekly' => s.calendarRepeatWeeklyOn(DateFormat.EEEE().format(_start)),
    'monthly' => s.calendarRepeatMonthlyOn('${_start.day}'),
    'yearly' => s.calendarRepeatYearlyOn(DateFormat.MMMMd().format(_start)),
    _ => calendarRepeatText(s, widget.event?.rrule) ?? s.calendarRepeats,
  };

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final layout = calendarLayout(MediaQuery.sizeOf(context));
    final roomy = layout == CalendarLayout.roomy;
    final narrow = layout == CalendarLayout.narrow;
    final paint = CalendarPaint(context, cal);
    final label = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: scheme.onSurfaceVariant,
    );
    Widget field(String name, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: label),
        const SizedBox(height: 6),
        child,
      ],
    );
    String day(DateTime t) => t.year == DateTime.now().year
        ? DateFormat.MMMEd().format(t)
        : DateFormat.yMMMEd().format(t);
    Widget box(String text, VoidCallback onTap) => ControlBox(
      onTap: _saving ? null : onTap,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
    Widget when(String name, {required bool start}) {
      final t = start ? _start : _end;
      return field(
        name,
        Row(
          children: [
            Expanded(child: box(day(t), () => _pickDate(start: start))),
            if (!_allDay) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: narrow ? 116 : 112,
                child: box(
                  calendarTime(context, t),
                  () => _pickTime(start: start),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final writable = calendarWritable(cal, widget.event);
    final chips = [
      for (final source in writable)
        CalendarChip(
          label: source.name,
          on: _calendars.contains(source.entity),
          tint: paint.soft(source.entity),
          border: scheme.outline,
          avatar: CalendarAvatar(
            container: widget.container,
            entity: source.entity,
            paint: paint,
            size: _calendars.contains(source.entity) ? 28 : 26,
            muted: !_calendars.contains(source.entity),
          ),
          onTap: () => setState(() {
            if (!_calendars.remove(source.entity)) {
              _calendars.add(source.entity);
            }
          }),
        ),
    ];
    final repeats = [
      'none',
      if (_repeatAtFirst == 'custom') 'custom',
      'daily',
      'weekdays',
      'weekly',
      'monthly',
      'yearly',
    ];
    final first = <Widget>[
      field(
        s.calendarFieldTitle,
        TextField(
          controller: _title,
          enabled: !_saving,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          decoration: InputDecoration(hintText: s.calendarFieldTitleHint),
          onChanged: (_) => setState(() {}),
        ),
      ),
      field(
        s.calendarFieldCalendars,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (narrow)
              EdgeFade(
                axis: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(spacing: 8, children: chips),
                ),
              )
            else
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            if (_calendars.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  s.calendarFieldSharedHint,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
      Row(
        children: [
          Expanded(
            child: Text(
              s.calendarAllDay,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Switch(value: _allDay, onChanged: _saving ? null : _setAllDay),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (narrow) ...[
            when(s.calendarFieldStarts, start: true),
            const SizedBox(height: 16),
            when(s.calendarFieldEnds, start: false),
          ] else
            Row(
              children: [
                Expanded(child: when(s.calendarFieldStarts, start: true)),
                const SizedBox(width: 12),
                Expanded(child: when(s.calendarFieldEnds, start: false)),
              ],
            ),
          if (!_endOk)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                s.calendarFieldEndsBeforeStart,
                style: TextStyle(fontSize: 13, color: scheme.error),
              ),
            ),
        ],
      ),
    ];
    final second = <Widget>[
      field(
        s.calendarFieldRepeat,
        KsDropdown<String>(
          value: _repeat,
          expand: true,
          items: [
            for (final r in repeats)
              DropdownMenuItem(
                value: r,
                child: Text(
                  _repeatLabel(s, r),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: _saving
              ? null
              : (v) => setState(() => _repeat = v ?? 'none'),
        ),
      ),
      field(
        s.calendarFieldLocation,
        TextField(
          controller: _location,
          enabled: !_saving,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: s.calendarFieldLocationHint),
        ),
      ),
      field(
        s.calendarFieldNotes,
        TextField(
          controller: _notes,
          enabled: !_saving,
          minLines: 3,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: s.calendarFieldNotesHint),
        ),
      ),
    ];
    final heading = widget.event == null
        ? s.calendarNewEvent
        : s.calendarEditEvent;
    final cancel = TextButton(
      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
      child: Text(s.commonCancel),
    );
    final save = FilledButton(
      onPressed: _canSave ? _save : null,
      child: _saving
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.onSurfaceVariant,
              ),
            )
          : Text(s.commonSave),
    );
    if (roomy) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              heading,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: EdgeFade(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [...first, ...second],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [cancel, save],
            ),
          ],
        ),
      );
    }
    // A short panel has the width but not the height: two columns, and the
    // buttons in the top bar so nothing scrolls under them.
    final bar = narrow
        ? SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(children: [cancel, const Spacer(), save]),
              ],
            ),
          )
        : SizedBox(
            height: 52,
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    heading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                cancel,
                save,
              ],
            ),
          );
    return Material(
      color: calendarGround(theme),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                narrow ? 4 : 16,
                narrow ? 0 : 4,
                narrow ? 12 : 16,
                0,
              ),
              child: bar,
            ),
            Expanded(
              child: EdgeFade(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, narrow ? 24 : 16),
                  child: narrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 18,
                          children: [...first, ...second],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 24,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: 12,
                                children: first,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: 12,
                                children: second,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Which days a change or a delete of a repeating event covers, or the
/// plain confirmation of one that does not repeat. With [run], the
/// confirming button waits for it and the dialog stays up if it fails.
/// Pops the scope picked.
class _ScopeDialog extends StatefulWidget {
  const _ScopeDialog({
    required this.container,
    required this.title,
    required this.scopes,
    required this.day,
    required this.confirmLabel,
    this.message,
    this.destructive = false,
    this.failedTitle,
    this.run,
  });

  final AppContainer container;
  final String title;
  final String? message;

  /// `this`, `following` and `all`, in that order. One shows no choice.
  final List<String> scopes;
  final DateTime day;
  final String confirmLabel;
  final bool destructive;
  final String? failedTitle;
  final Future<void> Function(String scope)? run;

  @override
  State<_ScopeDialog> createState() => _ScopeDialogState();
}

class _ScopeDialogState extends State<_ScopeDialog> {
  late String _scope = widget.scopes.first;
  bool _busy = false;

  Future<void> _confirm() async {
    final run = widget.run;
    if (run == null) {
      Navigator.of(context).pop(_scope);
      return;
    }
    final s = l10n(context);
    final overlay = Overlay.of(context, rootOverlay: true);
    setState(() => _busy = true);
    try {
      await run(_scope);
      if (mounted) Navigator.of(context).pop(_scope);
    } on CalendarEditError catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showToastIn(
        overlay,
        title: widget.failedTitle ?? s.calendarSaveFailed,
        message: calendarEditMessage(s, widget.container.calendar, e),
        kind: ToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    final labels = {
      'this': s.calendarScopeThis,
      'following': s.calendarScopeFollowing,
      'all': s.calendarScopeAll,
    };
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.message case final message?)
              Text(message, style: const TextStyle(height: 1.45)),
            if (widget.scopes.length > 1) ...[
              if (widget.message != null) const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _scope,
                onChanged: (v) {
                  if (!_busy && v != null) setState(() => _scope = v);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final scope in widget.scopes)
                      RadioListTile<String>(
                        value: scope,
                        title: Text(labels[scope]!),
                        subtitle: scope == 'this'
                            ? Text(DateFormat.yMMMMEEEEd().format(widget.day))
                            : null,
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(s.commonCancel),
        ),
        FilledButton(
          style: widget.destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: _busy ? null : _confirm,
          child: _busy
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// The dashed slot a tap on an empty hour drops in the Day view: a tap on
/// it opens New event there.
class CalendarSlot extends StatelessWidget {
  const CalendarSlot({super.key, required this.onTap, this.radius = 12});

  final VoidCallback onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    final shape = BorderRadius.circular(radius);
    return Semantics(
      button: true,
      label: s.calendarNewEvent,
      child: Material(
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: .12),
          scheme.surface,
        ),
        borderRadius: shape,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: CustomPaint(
            painter: _Dashes(color: scheme.primary, radius: radius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                spacing: 6,
                children: [
                  Icon(Icons.add, size: 18, color: scheme.primary),
                  Flexible(
                    child: Text(
                      s.calendarNewEvent,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dashes extends CustomPainter {
  const _Dashes({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.75),
          Radius.circular(radius),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_Dashes old) => old.color != color || old.radius != radius;
}
