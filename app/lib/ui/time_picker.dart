import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// The one time picker, on both surfaces: two boxes, hour and minute,
/// 24 hour, in the control box shape. Tap a box to type; the chevrons step
/// it (hours by 1, minutes by 5) so a wall tablet with no keyboard can set
/// a time with taps. An entry out of range paints the box error and
/// disables Set. Returns "HH:mm", or null when cancelled. The remote admin
/// draws the same dialog (widgets.js pickTime).
Future<String?> showKsTimePicker(
  BuildContext context, {
  required String title,
  required String initial,
}) => showDialog<String>(
  context: context,
  builder: (_) => _TimePickerDialog(title: title, initial: initial),
);

class _TimePickerDialog extends StatefulWidget {
  const _TimePickerDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  late final TextEditingController _hour;
  late final TextEditingController _minute;

  @override
  void initState() {
    super.initState();
    final parts = widget.initial.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '')?.clamp(0, 23) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '')?.clamp(0, 59) ?? 0;
    _hour = TextEditingController(text: _pad(h));
    _minute = TextEditingController(text: _pad(m));
  }

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');

  int? _read(TextEditingController c, int max) {
    final v = int.tryParse(c.text.trim());
    return v == null || v < 0 || v > max ? null : v;
  }

  bool get _valid => _read(_hour, 23) != null && _read(_minute, 59) != null;

  /// Step a box by [delta], wrapping around, from its current value (a
  /// box that reads garbage steps from zero). Minutes snap to fives.
  void _step(TextEditingController c, int max, int delta) {
    final current = _read(c, max) ?? 0;
    final base = delta.abs() == 5 ? (current ~/ 5) * 5 : current;
    final next = (base + delta) % (max + 1);
    setState(() => c.text = _pad(next < 0 ? next + max + 1 : next));
  }

  Widget _box(
    BuildContext context,
    String label,
    TextEditingController c,
    int max,
    int delta,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final invalid = _read(c, max) == null;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Ks.radiusControl),
          borderSide: BorderSide(color: color, width: width),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Up',
          icon: const Icon(Icons.keyboard_arrow_up),
          onPressed: () => _step(c, max, delta),
        ),
        SizedBox(
          width: 96,
          height: 80,
          child: TextField(
            controller: c,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            style: TextStyle(
              fontFamily: Ks.displayFont,
              fontSize: 44,
              height: 1,
              color: scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: scheme.surfaceContainerHighest,
              focusColor: scheme.primaryContainer,
              contentPadding: EdgeInsets.zero,
              enabledBorder: invalid
                  ? border(scheme.error, 1.5)
                  : border(scheme.outlineVariant),
              focusedBorder: invalid
                  ? border(scheme.error, 1.5)
                  : border(scheme.primary, 1.5),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Down',
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => _step(c, max, -delta),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 312,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _box(context, 'Hour', _hour, 23, 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ':',
                    style: TextStyle(
                      fontFamily: Ks.displayFont,
                      fontSize: 44,
                      height: 1,
                      color: scheme.onSurface,
                    ),
                  ),
                  // Sits level with the boxes, above the down arrows and
                  // the labels.
                  const SizedBox(height: 60),
                ],
              ),
            ),
            _box(context, 'Minute', _minute, 59, 5),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.pop(
                  context,
                  '${_pad(_read(_hour, 23)!)}:${_pad(_read(_minute, 59)!)}',
                )
              : null,
          child: const Text('Set'),
        ),
      ],
    );
  }
}
