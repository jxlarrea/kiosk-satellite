import 'package:flutter/material.dart';

import 'theme.dart';

/// The shared settings-surface building blocks. Every settings-like page
/// (Settings, Camera, Gestures, Setup) composes these instead of carrying its
/// own copies, so headings, cards, notes and dialogs match everywhere. All
/// insets come from [Ks]; nothing in here hardcodes a spacing value.

/// A line between rows, and never after the last one. Inset from the card
/// edges, One UI style, so the line reads as part of the card rather than a
/// cut through it. The remote admin's `.row` border follows the same
/// no-line-after-the-last rule.
List<Widget> separatedRows(List<Widget> rows) => [
  for (var i = 0; i < rows.length; i++) ...[
    rows[i],
    if (i < rows.length - 1)
      const Divider(height: 1, indent: Ks.inset, endIndent: Ks.inset),
  ],
];

/// A group of settings rows on one flat, borderless, large-radius card —
/// One UI's rounded section mask. Clips so row ink stays inside the corners.
/// Shape and margin come from the card theme.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(children: separatedRows(children)),
  );
}

/// Narrow-screen pages read as a column, not a sheet: capped at a comfortable
/// reading width and centered.
Widget constrainedColumn(Widget child) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 760),
    child: child,
  ),
);

/// A section break. The heading is the break; a divider as well says it twice.
/// Sits between cards on the shared column inset, so the label lines up with
/// the row text inside the cards.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Ks.inset, 6, Ks.inset, 10),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A line under a [SectionHeading], for a group that needs a word of warning
/// before its first control. Sits between the heading and the card, on the
/// heading's inset, so it reads as part of the heading rather than as a row.
class GroupNote extends StatelessWidget {
  const GroupNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Ks.inset, 0, Ks.inset, 12),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// An informational line inside a card, under the row it explains.
class HintRow extends StatelessWidget {
  const HintRow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Ks.inset, 8, Ks.inset, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// [HintRow]'s cautionary sibling: same shape, warning color.
class WarnRow extends StatelessWidget {
  const WarnRow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final warn = Theme.of(context).colorScheme.tertiary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Ks.inset, 8, Ks.inset, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: warn),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: warn),
            ),
          ),
        ],
      ),
    );
  }
}

/// The one confirmation dialog. Cancel is quiet, the confirming action is a
/// filled pill; [destructive] paints it in the error color. The confirm label
/// is a short verb ("Exit", "Log out"), never a restatement of the title.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(message),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// One choice in a [showRadioPicker] dialog: a value, its label, and an
/// optional quieter detail line under the label.
class PickerOption<T> {
  const PickerOption(this.value, this.label, {this.detail});

  final T value;
  final String label;
  final String? detail;
}

/// The one single-choice picker dialog: real radio rows, current value
/// checked, tap selects and closes. Returns null when dismissed.
Future<T?> showRadioPicker<T>(
  BuildContext context, {
  required String title,
  required List<PickerOption<T>> options,
  T? selected,
}) => showDialog<T>(
  context: context,
  builder: (context) => SimpleDialog(
    title: Text(title),
    contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
    children: [
      RadioGroup<T>(
        groupValue: selected,
        onChanged: (v) => Navigator.of(context).pop(v),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              RadioListTile<T>(
                value: option.value,
                title: Text(option.label),
                subtitle: option.detail == null ? null : Text(option.detail!),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
          ],
        ),
      ),
    ],
  ),
);
