import 'package:flutter/material.dart';

/// Pick an RGB colour: a live preview, three channel sliders, and a row of
/// presets for the common clock colours. Returns "r,g,b" (matching how the
/// setting is stored), or null if cancelled.
///
/// Built from sliders rather than a package: it is the one colour control in
/// the app, and a dependency-free RGB dialog is plenty for choosing a legible
/// clock tint.
Future<String?> pickColor(
  BuildContext context, {
  required String initial,
  required String title,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ColorPickerDialog(initial: initial, title: title),
  );
}

Color _parse(String rgb) {
  final parts = rgb.split(',').map((p) => int.tryParse(p.trim())).toList();
  if (parts.length == 3 && parts.every((p) => p != null)) {
    return Color.fromARGB(255, parts[0]!.clamp(0, 255), parts[1]!.clamp(0, 255),
        parts[2]!.clamp(0, 255));
  }
  return const Color(0xFFFAFAFA);
}

String _toRgb(Color c) =>
    '${(c.r * 255).round()},${(c.g * 255).round()},${(c.b * 255).round()}';

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial, required this.title});

  final String initial;
  final String title;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late int _r;
  late int _g;
  late int _b;

  static const _presets = <(String, Color)>[
    ('White', Color(0xFFFAFAFA)),
    ('Warm', Color(0xFFFFE0B2)),
    ('Amber', Color(0xFFFFB300)),
    ('Red', Color(0xFFEF5350)),
    ('Green', Color(0xFF66BB6A)),
    ('Blue', Color(0xFF42A5F5)),
    ('Cyan', Color(0xFF26C6DA)),
    ('Dim', Color(0xFF616161)),
  ];

  @override
  void initState() {
    super.initState();
    final c = _parse(widget.initial);
    _r = (c.r * 255).round();
    _g = (c.g * 255).round();
    _b = (c.b * 255).round();
  }

  Color get _color => Color.fromARGB(255, _r, _g, _b);

  Widget _channel(String label, int value, Color tint, ValueChanged<int> set) {
    return Row(
      children: [
        SizedBox(width: 18, child: Text(label, style: TextStyle(color: tint))),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: tint,
            onChanged: (v) => setState(() => set(v.round())),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text('$value', textAlign: TextAlign.end),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live preview over a checkerboard-ish neutral so light and dark
            // both read.
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black26),
              ),
              alignment: Alignment.center,
              child: Text(
                '$_r, $_g, $_b',
                style: TextStyle(
                  // Contrast the label against the chosen colour.
                  color: _color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _channel('R', _r, const Color(0xFFE53935), (v) => _r = v),
            _channel('G', _g, const Color(0xFF43A047), (v) => _g = v),
            _channel('B', _b, const Color(0xFF1E88E5), (v) => _b = v),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (name, c) in _presets)
                  GestureDetector(
                    onTap: () => setState(() {
                      _r = (c.r * 255).round();
                      _g = (c.g * 255).round();
                      _b = (c.b * 255).round();
                    }),
                    child: Tooltip(
                      message: name,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _toRgb(_color)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
