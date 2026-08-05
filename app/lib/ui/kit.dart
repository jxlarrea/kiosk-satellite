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

/// The one dropdown control: the remote admin's select translated to
/// Flutter — value and chevron on a bordered surface box, same tokens
/// (surface-2 fill, border, control radius). A bare DropdownButton is just
/// text with a caret, which next to a row title reads as another title.
class KsDropdown<T> extends StatelessWidget {
  const KsDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.expand = false,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;

  /// Null renders the control disabled, box and all.
  final ValueChanged<T?>? onChanged;

  /// Fill the available width instead of hugging the value.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(Ks.radiusControl),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: expand,
          borderRadius: BorderRadius.circular(Ks.radiusControl),
          iconEnabledColor: scheme.onSurfaceVariant,
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// A settings row with a dropdown control that never starves the text. A
/// dropdown in ListTile.trailing demands the width of its widest option,
/// which on a phone squeezes the title and description into a
/// one-word-per-line sliver. On a roomy pane the dropdown keeps its natural
/// trailing spot; on a narrow one the row stacks instead: title, then the
/// dropdown across the full row, then the description beneath it.
class DropdownRow<T> extends StatelessWidget {
  const DropdownRow({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String description;
  final T? value;

  /// (value, label) pairs; labels are built with single-line ellipsis so a
  /// long device name truncates instead of wrapping inside the menu.
  final List<(T, String)> options;

  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    // The pane the row actually lives in: the settings split view keeps a
    // rail on screens 720 and up (same constants as the settings screen);
    // below that the page is full width. LayoutBuilder cannot be used here
    // (ListTile measures intrinsics), so the pane width is derived instead.
    final screen = MediaQuery.sizeOf(context).width;
    final pane = screen >= 720
        ? screen - (screen * 0.4).clamp(320.0, 430.0)
        : screen;
    final tight = pane < 640;
    final dropdown = KsDropdown<T>(
      value: value,
      expand: tight,
      items: [
        for (final (v, label) in options)
          DropdownMenuItem(
            value: v,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
    if (!tight) {
      return ListTile(
        title: Text(title),
        subtitle: Text(description),
        trailing: dropdown,
      );
    }
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          dropdown,
          const SizedBox(height: 8),
          Text(description),
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
