import 'package:flutter/material.dart';

import 'kit.dart';
import 'theme.dart';

/// A plugin's confirmed entity states, displayed without editing controls.
class PluginReadings extends StatelessWidget {
  const PluginReadings({super.key, required this.readings});

  final List<Map<String, Object?>> readings;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeading('Readings'),
        SettingsCard(
          children: [
            for (final reading in readings)
              _ReadingRow(
                key: ValueKey('${reading['type']}:${reading['key']}'),
                reading: reading,
              ),
          ],
        ),
      ],
    );
  }
}

String formatPluginReading(Map<String, Object?> reading) {
  final state = reading['state'];
  if (state == null) return 'No data';
  if (state is bool) return state ? 'On' : 'Off';
  if (state is num) {
    if (!state.isFinite) return 'No data';
    final precision = ((reading['accuracyDecimals'] as num?)?.toInt() ?? 0)
        .clamp(0, 6);
    if (state.abs() >= 1e9) return state.toStringAsExponential(precision);
    final text = state.toStringAsFixed(precision);
    return num.parse(text) == 0 ? 0.toStringAsFixed(precision) : text;
  }
  return state == '' ? 'Empty' : '$state';
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({super.key, required this.reading});

  final Map<String, Object?> reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final readingStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w400,
    );
    final value = formatPluginReading(reading);
    final unit = reading['type'] == 'sensor' && reading['state'] != null
        ? '${reading['unit'] ?? ''}'
        : '';
    final multiline = value.contains('\n');
    final label = Text(
      '${reading['name']}',
      style: readingStyle?.copyWith(color: muted),
    );
    final content = Text.rich(
      TextSpan(
        text: value,
        children: [
          if (unit.isNotEmpty)
            TextSpan(
              text: ' $unit',
              style: readingStyle?.copyWith(color: muted),
            ),
        ],
      ),
      textAlign: multiline ? TextAlign.start : TextAlign.end,
      style: readingStyle?.copyWith(
        color: reading['state'] == null || reading['state'] == ''
            ? muted
            : theme.colorScheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Ks.inset, vertical: 16),
        child: multiline
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [label, const SizedBox(height: 8), content],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 9, child: label),
                  const SizedBox(width: 16),
                  Expanded(flex: 11, child: content),
                ],
              ),
      ),
    );
  }
}
