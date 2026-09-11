import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kit.dart';

const _chartColors = [
  Color(0xff1976d2),
  Color(0xffb45309),
  Color(0xff16836b),
  Color(0xffa13ca4),
];

String chartNumber(num? value) {
  if (value == null) return 'No data';
  return value.abs() >= 1000000
      ? value.toStringAsExponential(2)
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Read-only runtime data with sample inspection, independent of setting edits.
class PluginChart extends StatefulWidget {
  const PluginChart({super.key, required this.chart});
  final Map<String, Object?> chart;
  @override
  State<PluginChart> createState() => _PluginChartState();
}

class _PluginChartState extends State<PluginChart> {
  int? _selected;
  List<num> get _times => (widget.chart['timestamps'] as List).cast<num>();
  List<Map> get _series => (widget.chart['series'] as List).cast<Map>();
  int get _index {
    if (_times.isEmpty) return -1;
    final found = _times.indexOf(_selected ?? -1);
    return found < 0 ? _times.length - 1 : found;
  }

  Color _color(int index) {
    final hex = _series[index]['color'] as String?;
    return hex == null
        ? _chartColors[index % _chartColors.length]
        : Color(0xff000000 | int.parse(hex.substring(1), radix: 16));
  }

  String _time(num millis) {
    final time = DateTime.fromMillisecondsSinceEpoch(millis.toInt());
    String pad(int n) => '$n'.padLeft(2, '0');
    return '${pad(time.month)}/${pad(time.day)} ${pad(time.hour)}:${pad(time.minute)}:${pad(time.second)}';
  }

  void _select(double dx, double width) {
    if (_times.isEmpty) return;
    final target =
        _times.first + (dx / width).clamp(0, 1) * (_times.last - _times.first);
    var nearest = 0;
    for (var i = 1; i < _times.length; i++) {
      if ((_times[i] - target).abs() < (_times[nearest] - target).abs()) {
        nearest = i;
      }
    }
    setState(() => _selected = _times[nearest].toInt());
  }

  void _step(int delta) {
    if (_times.isEmpty) return;
    setState(
      () => _selected = _times[(_index + delta).clamp(0, _times.length - 1)]
          .toInt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.chart['compact'] == true;
    final height = compact ? 56.0 : 160.0;
    final index = _index;
    final unit = '${widget.chart['unit'] ?? ''}';
    final colors = [for (var i = 0; i < _series.length; i++) _color(i)];
    final values = [
      for (final series in _series)
        ...(series['values'] as List).whereType<num>(),
    ];
    final low = values.isEmpty ? 0.0 : values.reduce(math.min).toDouble();
    final high = values.isEmpty ? 1.0 : values.reduce(math.max).toDouble();
    final margin = high == low
        ? math.max(1.0, high.abs() * .05)
        : (high - low) * .05;
    final min = low - margin;
    final max = high + margin;
    final theme = Theme.of(context);
    final readings = [
      for (final series in _series)
        '${series['name']}: ${chartNumber(index < 0 ? null : (series['values'] as List)[index] as num?)}${index >= 0 && (series['values'] as List)[index] != null && unit.isNotEmpty ? ' $unit' : ''}',
    ];
    return SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.chart['title']}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < readings.length; i++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors[i],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            readings[i],
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                index < 0
                    ? 'Waiting for samples'
                    : '${_selected == null || !_times.contains(_selected) ? 'Latest' : 'Selected'} · ${_time(_times[index])}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (values.isEmpty)
                SizedBox(
                  height: height,
                  child: const Center(child: Text('No data yet')),
                )
              else
                Row(
                  children: [
                    if (!compact)
                      SizedBox(
                        width: 64,
                        height: height,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chartNumber(max),
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              chartNumber(min),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) => Focus(
                          onKeyEvent: (_, event) {
                            if (event is KeyDownEvent &&
                                (event.logicalKey ==
                                        LogicalKeyboardKey.arrowLeft ||
                                    event.logicalKey ==
                                        LogicalKeyboardKey.arrowRight)) {
                              _step(
                                event.logicalKey == LogicalKeyboardKey.arrowLeft
                                    ? -1
                                    : 1,
                              );
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Semantics(
                            label:
                                '${widget.chart['title']}. ${readings.join('. ')}',
                            onIncrease: () => _step(1),
                            onDecrease: () => _step(-1),
                            child: MouseRegion(
                              onHover: (event) => _select(
                                event.localPosition.dx,
                                constraints.maxWidth,
                              ),
                              onExit: (_) => setState(() => _selected = null),
                              child: GestureDetector(
                                onTapDown: (event) => _select(
                                  event.localPosition.dx,
                                  constraints.maxWidth,
                                ),
                                onHorizontalDragUpdate: (event) => _select(
                                  event.localPosition.dx,
                                  constraints.maxWidth,
                                ),
                                onDoubleTap: () =>
                                    setState(() => _selected = null),
                                child: CustomPaint(
                                  size: Size(double.infinity, height),
                                  painter: _ChartPainter(
                                    _times,
                                    _series,
                                    colors,
                                    min,
                                    max,
                                    index,
                                    theme.colorScheme.outlineVariant,
                                    compact,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              if (!compact && _times.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 64),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        _time(_times.first),
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        _time(_times.last),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (!compact)
                Text(
                  'Tap or drag to inspect samples. Double-tap to follow the latest.',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(
    this.times,
    this.series,
    this.colors,
    this.min,
    this.max,
    this.selected,
    this.grid,
    this.compact,
  );
  final List<num> times;
  final List<Map> series;
  final List<Color> colors;
  final double min, max;
  final int selected;
  final Color grid;
  final bool compact;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; !compact && i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    if (times.isEmpty) return;
    double x(int i) => times.length == 1
        ? size.width / 2
        : (times[i] - times.first) / (times.last - times.first) * size.width;
    double y(num value) => size.height * (1 - (value - min) / (max - min));
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (selected >= 0) {
      canvas.drawLine(
        Offset(x(selected), 0),
        Offset(x(selected), size.height),
        paint,
      );
    }
    for (var s = 0; s < series.length; s++) {
      final values = series[s]['values'] as List;
      final path = Path();
      var connected = false;
      for (var i = 0; i < values.length; i++) {
        if (values[i] == null) {
          connected = false;
          continue;
        }
        final point = Offset(x(i), y(values[i] as num));
        if (connected) {
          path.lineTo(point.dx, point.dy);
        } else {
          path.moveTo(point.dx, point.dy);
        }
        connected = true;
        if (!compact || i == selected) {
          canvas.drawCircle(
            point,
            i == selected ? 4 : 1.5,
            Paint()..color = colors[s],
          );
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[s]
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
