import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The one date picker, on both surfaces: a month calendar with the day
/// tapped, over Clear, Cancel and Set. Material's own calendar rather than
/// a hand-built grid, since the device is the reference for the metrics,
/// and Clear beside Cancel because an open end (no From, no To) is a real
/// answer the calendar itself cannot give.
///
/// Returns "YYYY-MM-DD", the empty string for cleared, or null when
/// cancelled. The remote admin draws the same dialog (widgets.js
/// pickDate).
Future<String?> showKsDatePicker(
  BuildContext context, {
  required String title,
  required String initial,
  DateTime? first,
  DateTime? last,
}) => showDialog<String>(
  context: context,
  builder: (_) => _DatePickerDialog(
    title: title,
    initial: initial,
    first: first ?? DateTime(1900),
    last: last ?? _today(),
  ),
);

/// Today with the clock thrown away: the calendar deals in days, and a
/// last date carrying an afternoon rejects today itself.
DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// "YYYY-MM-DD" for a day, the form both UIs and the search agree on.
String ksDateString(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

class _DatePickerDialog extends StatefulWidget {
  const _DatePickerDialog({
    required this.title,
    required this.initial,
    required this.first,
    required this.last,
  });

  final String title;
  final String initial;
  final DateTime first;
  final DateTime last;

  @override
  State<_DatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final parsed = DateTime.tryParse(widget.initial);
    // An empty or out-of-range date opens on today, clamped into the
    // range, so the calendar never starts somewhere it cannot go.
    final start = parsed == null
        ? _today()
        : DateTime(parsed.year, parsed.month, parsed.day);
    _selected = start.isBefore(widget.first)
        ? widget.first
        : start.isAfter(widget.last)
        ? widget.last
        : start;
  }

  @override
  Widget build(BuildContext context) {
    // The calendar's own size, cut down to what the panel has: an Echo Show
    // 5 is 480 tall in portrait terms and would wear a dialog taller than
    // its screen. The grid and the year list scroll inside whatever is
    // left, so a short panel loses rows, never the buttons.
    final screen = MediaQuery.sizeOf(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        height: math.min(420, math.max(240, screen.height - 240)),
        child: CalendarDatePicker(
          initialDate: _selected,
          firstDate: widget.first,
          lastDate: widget.last,
          onDateChanged: (day) => setState(() => _selected = day),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, ksDateString(_selected)),
          child: const Text('Set'),
        ),
      ],
    );
  }
}
