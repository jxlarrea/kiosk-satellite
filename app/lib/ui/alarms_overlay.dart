import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_container.dart';
import '../core/locale_dates.dart';
import '../l10n/generated/ui_strings.dart';
import '../l10n/messages.dart';
import '../managers/alarms/alarm_manager.dart';
import '../managers/alarms/alarm_model.dart';
import '../managers/music_library/music_pick.dart';
import '../managers/notifications/notification_sounds.dart';
import '../managers/settings/definitions.dart' as defs;
import 'clock_setting.dart';
import 'kit.dart';
import 'music_picker.dart';
import 'theme.dart';
import 'toast.dart';

/// The kiosk's alarms as a full screen overlay, the Nest Hub's alarm
/// screens: the list with a switch per alarm, a scroll wheel to pick the
/// time, then one details page for the repeat days, the label, the tone and
/// sunrise. Shown through the manager's [AlarmManager.visible] so the kiosk
/// menu, the screensaver widget, the remote admin and Settings all open the
/// same one.
class AlarmsOverlay extends StatelessWidget {
  const AlarmsOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: container.alarms.visible,
    builder: (context, visible, _) {
      if (!visible) return const SizedBox.shrink();
      return Positioned.fill(
        child: ClockSetting(
          container: container,
          setting: defs.alarmsClock24h,
          child: _AlarmsScreen(container: container),
        ),
      );
    },
  );
}

enum _Step { list, wheel, details }

/// A phone, or a panel too short for the tablet layout.
bool _compact(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width < 600 || size.height < 480;
}

/// Settings > Alarms > 24-hour clock, through the ClockSetting around each
/// alarm screen.
bool _use24h(BuildContext context) =>
    MediaQuery.alwaysUse24HourFormatOf(context);

/// The alarm screens' buttons: bigger than the app's settings buttons, for
/// a wall panel read and tapped from a step away.
ButtonStyle alarmButtonStyle(BuildContext context) {
  final compact = _compact(context);
  return ButtonStyle(
    minimumSize: WidgetStatePropertyAll(
      Size(compact ? 112 : 140, compact ? 52 : 60),
    ),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: compact ? 24 : 32),
    ),
    textStyle: WidgetStatePropertyAll(
      TextStyle(
        fontFamily: Ks.displayFont,
        fontSize: compact ? 16 : 18,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// The time as the list and the details draw it: the digits, and the AM or
/// PM beside them in a smaller size (empty in a 24 hour locale).
(String, String) alarmTimeParts(BuildContext context, int hour, int minute) {
  final t = DateTime(2000, 1, 1, hour, minute);
  if (_use24h(context)) return (DateFormat('HH:mm').format(t), '');
  return (DateFormat('h:mm').format(t), DateFormat('a').format(t));
}

String alarmTimeText(BuildContext context, DateTime t) {
  final (digits, suffix) = alarmTimeParts(context, t.hour, t.minute);
  return suffix.isEmpty ? digits : '$digits $suffix';
}

/// Today, Tomorrow or the weekday name, for a ring time.
String alarmDayText(BuildContext context, DateTime at, DateTime now) {
  final s = l10n(context);
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return s.alarmsToday;
  if (diff == 1) return s.alarmsTomorrow;
  if (diff < 7) return DateFormat.EEEE().format(at);
  return DateFormat.MMMEd().format(at);
}

/// The weekday order the date locale starts its week with, 0 = Sunday.
List<int> _weekOrder(BuildContext context) {
  final first = localeFirstWeekday();
  return [for (var i = 0; i < 7; i++) (first + i) % 7];
}

DateTime _dayOfWeek(int day) =>
    // 2023-01-01 was a Sunday.
    DateTime(2023, 1, 1 + day);

/// When an alarm rings, in words: the repeat days (Every day, Weekdays,
/// Weekends or the short day names), or for a one time alarm the day it
/// rings on, or Once when it is off.
String alarmWhenText(
  BuildContext context,
  Alarm alarm,
  DateTime now, {
  DateTime? Function(Alarm, DateTime)? next,
}) {
  final s = l10n(context);
  if (alarm.repeats) {
    return switch (repeatWord(alarm.days)) {
      'Every day' => s.alarmsEveryDay,
      'Weekdays' => s.alarmsWeekdays,
      'Weekends' => s.alarmsWeekends,
      _ => [
        for (final d in _weekOrder(context))
          if (alarm.days.contains(d)) DateFormat.E().format(_dayOfWeek(d)),
      ].join(', '),
    };
  }
  final at = (next ?? nextRing)(alarm, now);
  return at == null ? s.alarmsOnce : alarmDayText(context, at, now);
}

class _AlarmsScreen extends StatefulWidget {
  const _AlarmsScreen({required this.container});

  final AppContainer container;

  @override
  State<_AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<_AlarmsScreen> {
  AppContainer get c => widget.container;
  AlarmManager get alarms => c.alarms;

  _Step _step = _Step.list;

  /// The alarm the details page edits; saved on Done, and when the
  /// overlay closes over it.
  Alarm? _draft;
  bool _dirty = false;

  /// The wheel edits the draft's time (true) or picks a new alarm's.
  bool _wheelEditsDraft = false;
  int _hour = 7, _minute = 0;

  @override
  void initState() {
    super.initState();
    final alarm = _focused();
    if (alarm != null) {
      _draft = alarm;
      _step = _Step.details;
    }
    alarms.visible.addListener(_closeDialogs);
    alarms.focus.addListener(_takeFocus);
  }

  /// The alarm openAlarms asked for, taken off the request.
  Alarm? _focused() {
    final id = alarms.focus.value;
    if (id == null) return null;
    alarms.focus.value = null;
    return alarms.alarms.value.where((a) => a.id == id).firstOrNull;
  }

  /// openAlarms asked for an alarm while the screen was up: open it from
  /// the list or over another alarm's details. A change to that other alarm
  /// is kept, as closing the screen over it would keep it, and a dialog
  /// open over it goes.
  void _takeFocus() {
    final alarm = _focused();
    if (alarm == null || !mounted) return;
    final draft = _draft;
    _popDialogs();
    if (draft != null && draft.id == alarm.id) {
      // Already on it, perhaps on its time wheel: back to its details with
      // the change in progress.
      setState(() => _step = _Step.details);
      return;
    }
    if (draft != null && _dirty) {
      unawaited(alarms.save(draft).then((_) {}, onError: (_) {}));
    }
    _open(alarm);
  }

  void _closeDialogs() {
    if (alarms.visible.value || !mounted) return;
    _popDialogs();
  }

  void _popDialogs() {
    final nav = Navigator.of(context, rootNavigator: true);
    for (var i = _openDialogs; i > 0; i--) {
      nav.pop();
    }
  }

  @override
  void dispose() {
    alarms.visible.removeListener(_closeDialogs);
    alarms.focus.removeListener(_takeFocus);
    // Back, Home or the screensaver closed the overlay over an edit: keep
    // it, the way leaving the Nest Hub's page keeps it.
    final draft = _draft;
    if (_step == _Step.details && draft != null && _dirty) {
      // A change that would duplicate another alarm is dropped, as Done
      // would have refused it.
      unawaited(alarms.save(draft).then((_) {}, onError: (_) {}));
    }
    super.dispose();
  }

  void _close() => alarms.visible.value = false;

  void _newAlarm() {
    final now = DateTime.now();
    setState(() {
      _wheelEditsDraft = false;
      _hour = (now.hour + 1) % 24;
      _minute = 0;
      _step = _Step.wheel;
    });
  }

  void _open(Alarm alarm) => setState(() {
    _draft = alarm;
    _dirty = false;
    _step = _Step.details;
  });

  /// "You already have an alarm at 7:00 AM", the Nest Hub's answer to a
  /// second alarm at the same time on the same days.
  void _toastDuplicate(Alarm existing) => showToast(
    context,
    source: 'alarms',
    title: l10n(context).alarmsDuplicate(
      alarmTimeText(
        context,
        DateTime(2000, 1, 1, existing.hour, existing.minute),
      ),
    ),
    kind: ToastKind.warning,
  );

  Future<void> _set() async {
    if (_wheelEditsDraft && _draft != null) {
      final next = _draft!.copyWith(hour: _hour, minute: _minute);
      final other = alarms.duplicateOf(next);
      if (other != null) {
        // Stay on the wheel for another time.
        _toastDuplicate(other);
        return;
      }
      setState(() {
        _draft = next;
        _dirty = true;
        _step = _Step.details;
      });
      return;
    }
    final Alarm saved;
    try {
      saved = await alarms.save(
        Alarm(id: newAlarmId(), hour: _hour, minute: _minute),
      );
    } on DuplicateAlarm catch (e) {
      // That alarm exists: open it, set to ring, instead of a second one.
      if (!mounted) return;
      _toastDuplicate(e.existing);
      if (!e.existing.on) await alarms.setEnabled(e.existing.id, true);
      if (!mounted) return;
      final current = alarms.alarms.value
          .where((a) => a.id == e.existing.id)
          .firstOrNull;
      setState(() {
        _draft = current ?? e.existing;
        _dirty = false;
        _step = _Step.details;
      });
      return;
    }
    if (!mounted) return;
    _toastRingsIn(saved);
    setState(() {
      _draft = saved;
      _dirty = false;
      _step = _Step.details;
    });
  }

  void _toastRingsIn(Alarm alarm) {
    final now = DateTime.now();
    final at = nextRing(alarm, now);
    if (at == null) return;
    final s = l10n(context);
    final left = at.difference(now);
    final minutes = (left.inSeconds / 60).ceil();
    final h = minutes ~/ 60, m = minutes % 60;
    final span = h == 0
        ? s.alarmsDurationMinutes('$m')
        : m == 0
        ? s.alarmsDurationHours('$h')
        : s.alarmsDurationHoursMinutes('$h', '$m');
    showToast(
      context,
      source: 'alarms',
      title: s.alarmsSetToast,
      message: s.alarmsRingsIn(span),
      kind: ToastKind.success,
    );
  }

  Future<void> _done() async {
    final draft = _draft;
    if (draft != null && _dirty) {
      try {
        final saved = await alarms.save(draft.copyWith(on: true));
        if (mounted) _toastRingsIn(saved);
      } on DuplicateAlarm catch (e) {
        // Its new days or time match another alarm: say so and stay here.
        if (mounted) _toastDuplicate(e.existing);
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _draft = null;
      _dirty = false;
      _step = _Step.list;
    });
  }

  Future<void> _delete() async {
    final draft = _draft;
    if (draft != null) await alarms.delete(draft.id);
    if (!mounted) return;
    setState(() {
      _draft = null;
      _dirty = false;
      _step = _Step.list;
    });
  }

  void _edit(Alarm next) => setState(() {
    _draft = next;
    _dirty = true;
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = _compact(context);
    final s = l10n(context);
    final body = switch (_step) {
      _Step.list => _ListStep(
        container: c,
        compact: compact,
        onOpen: _open,
        onNew: _newAlarm,
      ),
      _Step.wheel => _WheelStep(
        compact: compact,
        hour: _hour,
        minute: _minute,
        onChanged: (h, m) {
          _hour = h;
          _minute = m;
        },
        onCancel: () => setState(
          () => _step = _wheelEditsDraft ? _Step.details : _Step.list,
        ),
        onSet: _set,
      ),
      _Step.details => _DetailsStep(
        container: c,
        compact: compact,
        alarm: _draft!,
        onChanged: _edit,
        onTime: () => setState(() {
          _wheelEditsDraft = true;
          _hour = _draft!.hour;
          _minute = _draft!.minute;
          _step = _Step.wheel;
        }),
        onDone: _done,
        onDelete: _delete,
      ),
    };
    return GestureDetector(
      // The ground only shields the dashboard underneath.
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: ksGroundGradient(
            theme.colorScheme.surface,
            theme.brightness,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: body),
                Positioned(
                  top: compact ? 12 : 20,
                  left: compact ? 16 : 28,
                  child: KsEyebrow(
                    label: s.alarmsTitle,
                    trail: _step == _Step.wheel ? s.alarmsSetAnAlarm : null,
                    compact: compact,
                  ),
                ),
                if (_step == _Step.list)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: s.commonClose,
                      iconSize: 28,
                      color: theme.colorScheme.onSurfaceVariant,
                      onPressed: _close,
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

// ── The list ──────────────────────────────────────────────────────────────

class _ListStep extends StatelessWidget {
  const _ListStep({
    required this.container,
    required this.compact,
    required this.onOpen,
    required this.onNew,
  });

  final AppContainer container;
  final bool compact;
  final ValueChanged<Alarm> onOpen;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    final gutter = compact ? 20.0 : 40.0;
    final button = FilledButton.icon(
      onPressed: onNew,
      icon: const Icon(Icons.add),
      label: Text(s.alarmsSetAnAlarm),
      style: alarmButtonStyle(context),
    );
    return ValueListenableBuilder<List<Alarm>>(
      valueListenable: container.alarms.alarms,
      builder: (context, list, _) => ValueListenableBuilder<AlarmStatus>(
        valueListenable: container.alarms.status,
        builder: (context, status, _) {
          final now = DateTime.now();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: compact ? 56 : 72),
              Expanded(
                child: list.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.alarm,
                              size: 56,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            s.alarmsNone,
                            style: TextStyle(
                              fontSize: 22,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : EdgeFade(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 16),
                          children: [
                            for (var i = 0; i < list.length; i++)
                              _AlarmRow(
                                container: container,
                                alarm: list[i],
                                now: now,
                                compact: compact,
                                last: i == list.length - 1,
                                snoozedUntil:
                                    status.phase == AlarmPhase.snoozed &&
                                        status.ids.contains(list[i].id)
                                    ? status.snoozedUntil
                                    : null,
                                onTap: () => onOpen(list[i]),
                              ),
                          ],
                        ),
                      ),
              ),
              // Outside the scroll view: a held scrollable stops its
              // children answering, and this is the one button always here.
              Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  12,
                  gutter,
                  compact ? 24 : 32,
                ),
                child: Align(
                  alignment: compact ? Alignment.center : Alignment.centerLeft,
                  child: button,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AlarmRow extends StatelessWidget {
  const _AlarmRow({
    required this.container,
    required this.alarm,
    required this.now,
    required this.compact,
    required this.last,
    required this.snoozedUntil,
    required this.onTap,
  });

  final AppContainer container;
  final Alarm alarm;
  final DateTime now;
  final bool compact, last;
  final DateTime? snoozedUntil;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    final (digits, suffix) = alarmTimeParts(context, alarm.hour, alarm.minute);
    final timeColor = alarm.on ? scheme.onSurface : scheme.onSurfaceVariant;
    final snoozed = snoozedUntil;
    final sub = snoozed != null
        ? s.alarmsSnoozedUntil(alarmTimeText(context, snoozed))
        : [
            alarmWhenText(context, alarm, now, next: container.alarms.upcoming),
            if (alarm.label.isNotEmpty) alarm.label,
          ].join(' · ');
    final subColor = snoozed != null ? scheme.primary : scheme.onSurfaceVariant;
    final subSize = compact ? 15.0 : 17.0;
    final time = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          digits,
          style: TextStyle(
            fontSize: compact ? 40 : 52,
            height: 1,
            color: timeColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (suffix.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            suffix,
            style: TextStyle(fontSize: compact ? 18 : 22, color: timeColor),
          ),
        ],
      ],
    );
    Widget when(bool stacked) => Row(
      mainAxisSize: stacked ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (snoozed != null || alarm.sunrise) ...[
          Icon(
            snoozed != null ? Icons.snooze : Icons.wb_twilight,
            size: subSize + 2,
            color: subColor,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: subSize, color: subColor),
          ),
        ),
      ],
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (snoozed != null) ...[
          OutlinedButton(
            style: alarmButtonStyle(context),
            onPressed: () => container.alarms.stop(source: 'list'),
            child: Text(s.alarmsStop),
          ),
          const SizedBox(width: 16),
        ],
        Switch(
          value: alarm.on,
          onChanged: (on) => container.alarms.setEnabled(alarm.id, on),
        ),
      ],
    );
    // With room across the row (a tablet, a phone on its side) the day line
    // sits in the middle, between the time and the switch: the two sides
    // take the same width so it lands on the row's center whatever the
    // time reads. The row's own width decides, not the screen's height: a
    // phone in landscape is short but wide. A narrow row (a phone upright)
    // keeps it under the time.
    final side = compact ? 220.0 : 260.0;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: compact ? 14 : 22),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 600
              ? Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [time, const SizedBox(height: 4), when(true)],
                      ),
                    ),
                    controls,
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: side,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: time,
                      ),
                    ),
                    Expanded(child: Center(child: when(false))),
                    SizedBox(
                      width: side,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: controls,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── The wheel ─────────────────────────────────────────────────────────────

/// The Nest Hub's time picker: hour, minute and (in a 12 hour locale) AM
/// or PM wheels on a tinted band. Only the alarm screens use it; a time
/// setting row opens the KS time picker.
class AlarmWheel extends StatefulWidget {
  const AlarmWheel({
    super.key,
    required this.hour,
    required this.minute,
    required this.onChanged,
    this.compact = false,
  });

  final int hour, minute;
  final void Function(int hour, int minute) onChanged;
  final bool compact;

  @override
  State<AlarmWheel> createState() => _AlarmWheelState();
}

class _AlarmWheelState extends State<AlarmWheel> {
  late FixedExtentScrollController _hours, _minutes, _period;
  late int _hour = widget.hour, _minute = widget.minute;
  bool? _h24;

  void _build(bool h24) {
    _h24 = h24;
    _hours = FixedExtentScrollController(
      initialItem: h24 ? _hour : (_hour % 12 == 0 ? 11 : _hour % 12 - 1),
    );
    _minutes = FixedExtentScrollController(initialItem: _minute);
    _period = FixedExtentScrollController(initialItem: _hour < 12 ? 0 : 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final h24 = _use24h(context);
    if (_h24 != h24) {
      if (_h24 != null) {
        // The wheels still hold the old controllers until this rebuild
        // detaches them.
        final old = [_hours, _minutes, _period];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final c in old) {
            c.dispose();
          }
        });
      }
      _build(h24);
    }
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    _period.dispose();
    super.dispose();
  }

  void _report() => widget.onChanged(_hour, _minute);

  Widget _column({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int) label,
    required ValueChanged<int> onSelected,
    required double width,
    required double extent,
    required double fontSize,
    bool looping = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(int i) => Center(
      child: Text(
        label(i),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    return SizedBox(
      width: width,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: extent,
        diameterRatio: 2.4,
        perspective: 0.002,
        useMagnifier: true,
        magnification: 1.35,
        overAndUnderCenterOpacity: 0.4,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (i) => onSelected(i % count),
        childDelegate: looping
            ? ListWheelChildLoopingListDelegate(
                children: [for (var i = 0; i < count; i++) item(i)],
              )
            : ListWheelChildListDelegate(
                children: [for (var i = 0; i < count; i++) item(i)],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final h24 = _h24 ?? false;
    final compact = widget.compact;
    final extent = compact ? 60.0 : 72.0;
    final font = compact ? 34.0 : 42.0;
    final col = compact ? 96.0 : 140.0;
    final am = DateFormat('a').format(DateTime(2000, 1, 1, 9));
    final pm = DateFormat('a').format(DateTime(2000, 1, 1, 21));
    return SizedBox(
      height: extent * 5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: extent * 1.875,
            height: extent * 1.25,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Row(
            // New wheels when the clock changes (Settings > Alarms >
            // 24-hour clock, possibly from the remote admin): a wheel
            // handed a new controller keeps the old one's offset, so the
            // hours would stay on the old row number.
            key: ValueKey(h24),
            mainAxisSize: MainAxisSize.min,
            children: [
              _column(
                controller: _hours,
                count: h24 ? 24 : 12,
                label: (i) => h24 ? '$i'.padLeft(2, '0') : '${i + 1}',
                width: col,
                extent: extent,
                fontSize: font,
                onSelected: (i) {
                  if (h24) {
                    _hour = i;
                  } else {
                    final h12 = i + 1;
                    final pmSide = _hour >= 12;
                    _hour = (h12 % 12) + (pmSide ? 12 : 0);
                  }
                  _report();
                },
              ),
              Text(
                ':',
                style: TextStyle(
                  fontSize: font * 1.35,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
              _column(
                controller: _minutes,
                count: 60,
                label: (i) => '$i'.padLeft(2, '0'),
                width: col,
                extent: extent,
                fontSize: font,
                onSelected: (i) {
                  _minute = i;
                  _report();
                },
              ),
              if (!h24)
                _column(
                  controller: _period,
                  count: 2,
                  looping: false,
                  label: (i) => i == 0 ? am : pm,
                  width: col * 0.8,
                  extent: extent,
                  fontSize: font * 0.62,
                  onSelected: (i) {
                    final h12 = _hour % 12;
                    _hour = h12 + (i == 1 ? 12 : 0);
                    _report();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WheelStep extends StatelessWidget {
  const _WheelStep({
    required this.compact,
    required this.hour,
    required this.minute,
    required this.onChanged,
    required this.onCancel,
    required this.onSet,
  });

  final bool compact;
  final int hour, minute;
  final void Function(int, int) onChanged;
  final VoidCallback onCancel, onSet;

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final gutter = compact ? 20.0 : 40.0;
    return Column(
      children: [
        SizedBox(height: compact ? 56 : 64),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AlarmWheel(
                hour: hour,
                minute: minute,
                compact: compact,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, compact ? 24 : 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                style: alarmButtonStyle(context),
                onPressed: onCancel,
                child: Text(s.commonCancel),
              ),
              const SizedBox(width: 12),
              FilledButton(
                style: alarmButtonStyle(context),
                onPressed: onSet,
                child: Text(s.commonSet),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Details ───────────────────────────────────────────────────────────────

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.container,
    required this.compact,
    required this.alarm,
    required this.onChanged,
    required this.onTime,
    required this.onDone,
    required this.onDelete,
  });

  final AppContainer container;
  final bool compact;
  final Alarm alarm;
  final ValueChanged<Alarm> onChanged;
  final VoidCallback onTime, onDone, onDelete;

  Future<void> _label(BuildContext context) async {
    final next = await _showLabelDialog(context, alarm.label);
    if (next != null) onChanged(alarm.copyWith(label: next.trim()));
  }

  Future<void> _phrase(BuildContext context, String fallback) async {
    final next = await _showPhraseDialog(
      context,
      alarm.phrase.isEmpty ? fallback : alarm.phrase,
    );
    if (next == null) return;
    // The default's own words keep following the default.
    final text = next.trim();
    onChanged(alarm.copyWith(phrase: text == fallback.trim() ? '' : text));
  }

  Future<void> _tone(BuildContext context) async {
    final next = await _showTonePicker(context, container, alarm.tone);
    if (next != null) onChanged(alarm.copyWith(tone: next));
  }

  Future<void> _music(BuildContext context) async {
    final next = await _showMusicChoice(context, container, alarm);
    if (next != null) onChanged(next);
  }

  /// Below this width the time goes over the details instead of beside
  /// them, so a tablet in portrait keeps the rows wide enough for Repeat.
  static const _twoColumnWidth = 900.0;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, box) => _page(context, box.maxWidth));

  Widget _page(BuildContext context, double width) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final gutter = compact ? 20.0 : 40.0;
    final twoColumns = !compact && width >= _twoColumnWidth;
    final rowsWidth = width - 2 * gutter - (twoColumns ? 260 + 48 : 0);
    final discSize = compact ? 38.0 : 48.0;
    // The discs go under Repeat when the line cannot hold them beside it:
    // the icon and its gap, room for the name, then the seven discs.
    final discsWidth = 7 * discSize + 6 * (discSize > 40 ? 10 : 6);
    final stackDays = rowsWidth < 40 + 140 + discsWidth;
    // A one time alarm in the draft rings at the next time its clock
    // reads, whatever day it was first set for.
    final preview = alarm.repeats
        ? alarm
        : alarm.copyWith(
            on: true,
            date: () => onceDate(alarm.hour, alarm.minute, now),
          );
    final (digits, suffix) = alarmTimeParts(context, alarm.hour, alarm.minute);
    final head = InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTime,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  digits,
                  style: TextStyle(
                    fontSize: compact ? 60 : 72,
                    height: 1,
                    color: scheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (suffix.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    suffix,
                    style: TextStyle(
                      fontSize: compact ? 23 : 27,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              alarmWhenText(context, preview, now),
              style: TextStyle(fontSize: 18, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
    final toneName = alarm.tone.isEmpty
        ? s.alarmsDefaultTone
        : alarm.tone == 'builtin'
        ? s.alarmsBuiltInTone
        : alarm.tone;
    final settings = container.settings;
    final defaultMusic = container.alarms.defaultMusic;
    // An alarm that never chose follows the default switch.
    final bool ease = alarm.ease ?? settings.get(defs.alarmsEaseIn);
    final phrase = settings.get(defs.alarmsPhrase);
    final rows = Column(
      children: [
        _DetailRow(
          icon: Icons.repeat,
          name: s.alarmsRepeat,
          stacked: stackDays,
          control: DayDiscs(
            days: alarm.days,
            size: discSize,
            onChanged: (days) => onChanged(alarm.copyWith(days: days)),
          ),
        ),
        _DetailRow(
          icon: Icons.label_outline,
          name: s.alarmsLabel,
          value: alarm.label.isEmpty ? s.alarmsAddLabel : alarm.label,
          onTap: () => _label(context),
        ),
        _DetailRow(
          icon: Icons.music_note_outlined,
          name: s.alarmsTone,
          value: toneName,
          onTap: () => _tone(context),
        ),
        // Music rings instead of the tone, and the tone rings when the
        // music cannot play.
        if (container.musicLibrary.available.isNotEmpty ||
            alarm.music != null ||
            defaultMusic != null)
          _DetailRow(
            icon: Icons.library_music_outlined,
            name: s.alarmsMusic,
            value: alarmMusicText(s, alarm, defaultMusic),
            onTap: () => _music(context),
          ),
        _DetailRow(
          icon: Icons.wb_twilight,
          name: s.alarmsSunrise,
          control: Switch(
            value: alarm.sunrise,
            onChanged: (on) => onChanged(alarm.copyWith(sunrise: on)),
          ),
          onTap: () => onChanged(alarm.copyWith(sunrise: !alarm.sunrise)),
        ),
        _DetailRow(
          icon: Icons.trending_up,
          name: s.alarmsEaseIn,
          control: Switch(
            value: ease,
            onChanged: (on) => onChanged(alarm.copyWith(ease: () => on)),
          ),
          onTap: () => onChanged(alarm.copyWith(ease: () => !ease)),
        ),
        _DetailRow(
          icon: Icons.record_voice_over_outlined,
          name: s.alarmsSpeak,
          last: !alarm.speak,
          control: Switch(
            value: alarm.speak,
            onChanged: (on) => onChanged(alarm.copyWith(speak: on)),
          ),
          onTap: () => onChanged(alarm.copyWith(speak: !alarm.speak)),
        ),
        if (alarm.speak)
          _DetailRow(
            icon: Icons.short_text,
            name: s.alarmsPhrase,
            last: true,
            value: alarm.phrase.isEmpty ? phrase : alarm.phrase,
            onTap: () => _phrase(context, phrase),
          ),
      ],
    );
    return Column(
      children: [
        SizedBox(height: compact ? 56 : 72),
        Expanded(
          child: EdgeFade(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: !twoColumns
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [head, const SizedBox(height: 12), rows],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 260,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: head,
                          ),
                        ),
                        const SizedBox(width: 48),
                        Expanded(child: rows),
                      ],
                    ),
            ),
          ),
        ),
        // Outside the scroll view, like the list's button.
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, compact ? 24 : 28),
          child: Row(
            children: [
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.error,
                ).merge(alarmButtonStyle(context)),
                child: Text(s.commonDelete),
              ),
              const Spacer(),
              FilledButton(
                style: alarmButtonStyle(context),
                onPressed: onDone,
                child: Text(s.alarmsDone),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.name,
    this.value,
    this.control,
    this.onTap,
    this.last = false,
    this.stacked = false,
  });

  final IconData icon;
  final String name;
  final String? value;
  final Widget? control;
  final VoidCallback? onTap;
  final bool last, stacked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = Text(
      name,
      style: TextStyle(fontSize: 18, color: scheme.onSurface),
    );
    final line = Row(
      children: [
        Icon(icon, color: scheme.onSurfaceVariant),
        const SizedBox(width: 16),
        Expanded(child: title),
        if (value != null) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              value!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 17, color: scheme.onSurfaceVariant),
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
        if (!stacked && control != null) control!,
      ],
    );
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: stacked && control != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  line,
                  Padding(
                    padding: const EdgeInsets.only(left: 40, top: 14),
                    child: control!,
                  ),
                ],
              )
            : line,
      ),
    );
  }
}

/// Seven day discs, starting on the locale's first day; a filled disc is
/// a day the alarm repeats on.
class DayDiscs extends StatelessWidget {
  const DayDiscs({
    super.key,
    required this.days,
    required this.onChanged,
    this.size = 48,
  });

  final List<int> days;
  final ValueChanged<List<int>> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: size > 40 ? 10 : 6,
      runSpacing: 6,
      children: [
        for (final d in _weekOrder(context))
          Semantics(
            button: true,
            selected: days.contains(d),
            label: DateFormat.EEEE().format(_dayOfWeek(d)),
            child: InkResponse(
              radius: size / 2,
              onTap: () {
                final next = {...days};
                next.contains(d) ? next.remove(d) : next.add(d);
                onChanged(next.toList()..sort());
              },
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: days.contains(d) ? scheme.primary : null,
                  border: days.contains(d)
                      ? null
                      : Border.all(color: scheme.outline, width: 1.5),
                ),
                child: Text(
                  DateFormat.EEEEE().format(_dayOfWeek(d)),
                  style: TextStyle(
                    fontSize: size * 0.36,
                    fontWeight: FontWeight.w600,
                    color: days.contains(d)
                        ? scheme.onPrimary
                        : scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Dialogs ───────────────────────────────────────────────────────────────

/// How many dialogs the alarm screens have open. They sit on the root
/// navigator, over the overlay, so the overlay closing from elsewhere (the
/// remote, Home Assistant, the screensaver, a ring) takes them with it.
int _openDialogs = 0;

Future<T?> _alarmDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  _openDialogs++;
  try {
    return await showDialog<T>(context: context, builder: builder);
  } finally {
    _openDialogs--;
  }
}

/// What an alarm's Music row says: its own music, None, or Default and
/// the default's name.
String alarmMusicText(UiStrings s, Alarm alarm, MusicPick? fallback) =>
    alarm.noMusic
    ? s.alarmsMusicNone
    : alarm.music != null
    ? musicPickName(s, alarm.music!)
    : fallback == null
    ? '${s.alarmsDefaultTone} · ${s.alarmsMusicNone}'
    : '${s.alarmsDefaultTone} · ${musicPickName(s, fallback)}';

/// The alarm's music, the way its tone is picked: Default, None or its
/// own, and Choose music for a new one. Answers the changed alarm.
Future<Alarm?> _showMusicChoice(
  BuildContext context,
  AppContainer container,
  Alarm alarm,
) => _alarmDialog<Alarm>(
  context: context,
  builder: (context) => _MusicChoice(container: container, alarm: alarm),
);

class _MusicChoice extends StatefulWidget {
  const _MusicChoice({required this.container, required this.alarm});

  final AppContainer container;
  final Alarm alarm;

  @override
  State<_MusicChoice> createState() => _MusicChoiceState();
}

class _MusicChoiceState extends State<_MusicChoice> {
  late String _pick = widget.alarm.noMusic
      ? 'none'
      : widget.alarm.music != null
      ? 'own'
      : 'default';

  Alarm _with(String pick) => switch (pick) {
    'none' => widget.alarm.copyWith(music: () => null, noMusic: true),
    'own' => widget.alarm.copyWith(noMusic: false),
    _ => widget.alarm.copyWith(music: () => null, noMusic: false),
  };

  Future<void> _choose() async {
    final fallback = widget.container.alarms.defaultMusic;
    _openDialogs++;
    final MusicPick? picked;
    try {
      picked = await showMusicPicker(
        context,
        widget.container,
        current: widget.alarm.music ?? fallback,
      );
    } finally {
      _openDialogs--;
    }
    if (picked == null || !mounted) return;
    Navigator.of(
      context,
    ).pop(widget.alarm.copyWith(music: () => picked, noMusic: false));
  }

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final own = widget.alarm.music;
    final fallback = widget.container.alarms.defaultMusic;
    return AlertDialog(
      title: Text(s.alarmsMusic),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: 400,
        child: EdgeFade(
          child: SingleChildScrollView(
            child: RadioGroup<String>(
              groupValue: _pick,
              onChanged: (v) => setState(() => _pick = v ?? _pick),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RadioListTile<String>(
                    value: 'default',
                    title: Text(s.alarmsDefaultTone),
                    subtitle: Text(
                      fallback == null
                          ? s.alarmsMusicNone
                          : musicPickName(s, fallback),
                    ),
                  ),
                  RadioListTile<String>(
                    value: 'none',
                    title: Text(s.alarmsMusicNone),
                  ),
                  if (own != null)
                    RadioListTile<String>(
                      value: 'own',
                      title: Text(musicPickName(s, own)),
                    ),
                  const Divider(height: 16),
                  ListTile(
                    leading: const Icon(Icons.library_music_outlined),
                    title: Text(s.musicPickerTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _choose,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          style: alarmButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.commonCancel),
        ),
        FilledButton(
          style: alarmButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(_with(_pick)),
          child: Text(s.commonOk),
        ),
      ],
    );
  }
}

/// Settings > Alarms > Alarm music: the default's box, the music picker
/// behind it and a button that takes it out.
class AlarmMusicSettingTile extends StatelessWidget {
  const AlarmMusicSettingTile({
    super.key,
    required this.container,
    required this.title,
    required this.description,
    required this.onChanged,
  });

  final AppContainer container;
  final String title, description;
  final VoidCallback onChanged;

  Future<void> _pick(BuildContext context, MusicPick? current) async {
    final next = await showMusicPicker(context, container, current: current);
    if (next == null) return;
    await container.settings.set(defs.alarmsMusic, jsonEncode(next.toJson()));
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final current = container.alarms.defaultMusic;
    return SettingsRow(
      title: Text(title),
      subtitle: Text(description),
      stack: true,
      trailing: SizedBox(
        width: tightPane(context) ? double.infinity : 300,
        child: Row(
          children: [
            Expanded(
              child: MusicPickField(
                label: current == null
                    ? s.alarmsMusicNone
                    : musicPickName(s, current),
                picked: current != null,
                onTap: () => _pick(context, current),
              ),
            ),
            if (current != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: s.alarmsMusicRemove,
                icon: const Icon(Icons.close),
                onPressed: () async {
                  await container.settings.set(defs.alarmsMusic, '');
                  onChanged();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<String?> _showLabelDialog(BuildContext context, String current) =>
    _alarmDialog<String>(
      context: context,
      builder: (context) => _TextDialog(
        title: l10n(context).alarmsLabel,
        initial: current,
        maxLength: 40,
      ),
    );

Future<String?> _showPhraseDialog(BuildContext context, String current) =>
    _alarmDialog<String>(
      context: context,
      builder: (context) => _TextDialog(
        title: l10n(context).alarmsPhrase,
        initial: current,
        maxLength: 200,
        maxLines: 3,
        helper: l10n(context).alarmsPhraseVariables(alarmPhraseVariables),
      ),
    );

/// One line of text, or a few, with Cancel and Save. It owns its
/// controller, which lives until the dialog has animated away.
class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.initial,
    required this.maxLength,
    this.maxLines = 1,
    this.helper,
  });

  final String title, initial;
  final int maxLength, maxLines;
  final String? helper;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        minLines: 1,
        maxLines: widget.maxLines,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) => Navigator.of(context).pop(v),
        decoration: widget.helper == null
            ? null
            : InputDecoration(helperText: widget.helper, helperMaxLines: 3),
      ),
      actions: [
        TextButton(
          style: alarmButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.commonCancel),
        ),
        FilledButton(
          style: alarmButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(s.commonSave),
        ),
      ],
    );
  }
}

Future<String?> _showTonePicker(
  BuildContext context,
  AppContainer container,
  String current,
) async {
  final sounds = await NotificationSounds.list();
  if (!context.mounted) return null;
  return _alarmDialog<String>(
    context: context,
    builder: (context) =>
        _TonePicker(container: container, current: current, sounds: sounds),
  );
}

/// Default, the built-in alarm, then the sounds folder. A pick plays the
/// tone once at the alarm volume; OK keeps it.
class _TonePicker extends StatefulWidget {
  const _TonePicker({
    required this.container,
    required this.current,
    required this.sounds,
  });

  final AppContainer container;
  final String current;
  final List<String> sounds;

  @override
  State<_TonePicker> createState() => _TonePickerState();
}

class _TonePickerState extends State<_TonePicker> {
  late String _pick = widget.current;

  @override
  void dispose() {
    unawaited(
      widget.container.commands.execute('stopAlarmTonePreview', const {}),
    );
    super.dispose();
  }

  void _select(String? tone) {
    if (tone == null) return;
    setState(() => _pick = tone);
    unawaited(
      widget.container.commands.execute('previewAlarmTone', {'tone': tone}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    final fallback = widget.container.settings.get(defs.alarmsTone);
    final missing =
        _pick.isNotEmpty &&
        _pick != 'builtin' &&
        !widget.sounds.contains(_pick);
    return AlertDialog(
      title: Text(s.alarmsTone),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: 400,
        child: EdgeFade(
          child: SingleChildScrollView(
            child: RadioGroup<String>(
              groupValue: _pick,
              onChanged: _select,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RadioListTile<String>(
                    value: '',
                    title: Text(s.alarmsDefaultTone),
                    subtitle: Text(
                      fallback.isEmpty ? s.alarmsBuiltInTone : fallback,
                    ),
                  ),
                  RadioListTile<String>(
                    value: 'builtin',
                    title: Text(s.alarmsBuiltInTone),
                  ),
                  if (widget.sounds.isNotEmpty || missing)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
                      child: Text(
                        s.alarmsSoundsFolder,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  for (final sound in widget.sounds)
                    RadioListTile<String>(value: sound, title: Text(sound)),
                  if (missing)
                    RadioListTile<String>(
                      value: _pick,
                      title: Text(s.intercomMissingFile(_pick)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          style: alarmButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.commonCancel),
        ),
        FilledButton(
          style: alarmButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(_pick),
          child: Text(s.commonOk),
        ),
      ],
    );
  }
}

// ── Settings > Alarms ─────────────────────────────────────────────────────

/// The top of Settings > Alarms: the one row that opens the full screen
/// list, with when the next alarm rings under it.
class AlarmsManageCard extends StatelessWidget {
  const AlarmsManageCard({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) => ClockSetting(
    container: container,
    setting: defs.alarmsClock24h,
    child: Builder(builder: _card),
  );

  Widget _card(BuildContext context) => ValueListenableBuilder<AlarmStatus>(
    valueListenable: container.alarms.status,
    builder: (context, status, _) {
      final s = l10n(context);
      final next = status.next;
      final now = DateTime.now();
      return SettingsCard(
        children: [
          SettingsRow(
            leading: const Icon(Icons.alarm),
            title: Text(s.alarmsManage),
            subtitle: Text(
              next == null
                  ? s.alarmsNoneSet
                  : s.alarmsNextAt(
                      alarmDayText(context, next.at, now),
                      alarmTimeText(context, next.at),
                    ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              unawaited(container.commands.execute('openAlarms', const {}));
            },
          ),
        ],
      );
    },
  );
}
