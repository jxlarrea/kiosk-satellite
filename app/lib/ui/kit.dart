import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'toast.dart';

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

/// What a banner says: a failure that blocks the page, or a state that
/// makes a section inert.
enum NoticeKind { error, warning }

/// A tinted container above the rows it affects: 20 radius, 16 by 18
/// padding, a 20 icon and the text in the container's ink. Error container
/// for a failure that blocks the page (the setup wizard's connection
/// errors), tertiary container for a state that makes a section inert
/// (Bluetooth off). Banners are the only tinted surfaces on a page. The
/// remote admin's .banner is the same shape.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.text,
    this.kind = NoticeKind.warning,
    this.title,
  });

  final String text;
  final NoticeKind kind;

  /// An optional bold first line, for a failure that has a name and an
  /// explanation.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final error = kind == NoticeKind.error;
    final bg = error ? scheme.errorContainer : scheme.tertiaryContainer;
    final fg = error ? scheme.onErrorContainer : scheme.onTertiaryContainer;
    final body = theme.textTheme.bodySmall?.copyWith(
      fontSize: 13.5,
      height: 1.45,
      color: fg,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: Ks.cardGap),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.error_outline : Icons.warning_amber_rounded,
            size: 20,
            color: fg,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: title == null
                ? Text(text, style: body)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: body?.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(text, style: body),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Fades overflowing content out at the edge it disappears under. Wraps a
/// vertical scrollable (the widget with the viewport, never the content
/// inside it) and paints a [Ks.fadeEdge]-tall gradient of the backing
/// surface's color over the top and bottom — but only on an edge that
/// still hides content, so a list at rest shows a crisp first row and a
/// soft hint of more below, and the hints slide in and out with the
/// scroll instead of permanently dimming the ends. The remote admin's
/// .edge-fade containers carry the same treatment.
///
/// Painting the surface color over the content, rather than masking the
/// content to transparent, is deliberate: it reads identically on the
/// app's solid surfaces but costs two small gradient quads, where a
/// ShaderMask re-renders the entire list into an offscreen saveLayer on
/// every scrolled frame. The trade is that the fade color must match what
/// the list sits on — resolved from the nearest [Material], which is the
/// scaffold behind a settings pane, the sheet behind a dialog body, the
/// card behind a log box.
class EdgeFade extends StatefulWidget {
  const EdgeFade({super.key, required this.child, this.axis = Axis.vertical});

  final Widget child;

  /// The scrollable's direction. Horizontal fades the left and right 28px
  /// instead (a segmented pill that does not fit the pane).
  final Axis axis;

  @override
  State<EdgeFade> createState() => _EdgeFadeState();
}

class _EdgeFadeState extends State<EdgeFade> {
  bool _top = false;
  bool _bottom = false;

  /// Test hooks: the two decisions that drive the overlays, which is what
  /// the widget tests pin down rather than the painted gradients.
  @visibleForTesting
  bool get debugTop => _top;
  @visibleForTesting
  bool get debugBottom => _bottom;

  void _update(ScrollMetrics metrics) {
    if (metrics.axis != widget.axis || !metrics.hasContentDimensions) {
      return;
    }
    // A reversed list (the log boxes) grows upward: extentBefore is the
    // content hidden below the viewport, not above it.
    final reversed =
        metrics.axisDirection == AxisDirection.up ||
        metrics.axisDirection == AxisDirection.left;
    final top = (reversed ? metrics.extentAfter : metrics.extentBefore) > 1;
    final bottom = (reversed ? metrics.extentBefore : metrics.extentAfter) > 1;
    if (top != _top || bottom != _bottom) {
      setState(() {
        _top = top;
        _bottom = bottom;
      });
    }
  }

  /// One edge's overlay: a surface-colored gradient strip whose alpha
  /// animates with the edge's state, gone from the tree entirely once the
  /// animation settles at off so an idle list paints nothing extra.
  Widget _edge(Color surface, {required bool show, required bool top}) {
    final vertical = widget.axis == Axis.vertical;
    return Positioned(
      left: vertical || top ? 0 : null,
      right: vertical || !top ? 0 : null,
      top: vertical && !top ? null : 0,
      bottom: vertical && top ? null : 0,
      height: vertical ? Ks.fadeEdge : null,
      width: vertical ? null : Ks.fadeEdge,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: show ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          builder: (context, t, _) => t == 0
              ? const SizedBox.shrink()
              : DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: vertical
                          ? (top ? Alignment.topCenter : Alignment.bottomCenter)
                          : (top
                                ? Alignment.centerLeft
                                : Alignment.centerRight),
                      end: vertical
                          ? (top ? Alignment.bottomCenter : Alignment.topCenter)
                          : (top
                                ? Alignment.centerRight
                                : Alignment.centerLeft),
                      colors: [
                        surface.withValues(alpha: t),
                        surface.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface =
        context.findAncestorWidgetOfExactType<Material>()?.color ??
        Theme.of(context).scaffoldBackgroundColor;
    // Both notification kinds matter: metrics notifications cover layout
    // and content-size changes (including the very first frame, which is
    // what turns the bottom hint on before any touch), scroll
    // notifications cover the scrolling itself.
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) {
        if (n.depth == 0) _update(n.metrics);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.depth == 0) _update(n.metrics);
          return false;
        },
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            _edge(surface, show: _top, top: true),
            _edge(surface, show: _bottom, top: false),
          ],
        ),
      ),
    );
  }
}

/// A segmented pill that never wraps: when it does not fit the pane it
/// scrolls sideways under the edge fade, the active segment in view. Four
/// or more choices are a dropdown, not a pill. The remote's .seg-scroll is
/// the same.
class ScrollingSegments extends StatelessWidget {
  const ScrollingSegments({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => EdgeFade(
    axis: Axis.horizontal,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    ),
  );
}

/// The move up, move down and remove actions at the end of an orderable
/// list row, 2 apart, so a tablet can reorder without a drag. The first
/// row's up and the last row's down are disabled, not hidden. Remove is
/// always last. The remote's rows carry the same three.
class OrderActions extends StatelessWidget {
  const OrderActions({
    super.key,
    required this.first,
    required this.last,
    required this.onUp,
    required this.onDown,
    required this.onRemove,
  });

  final bool first;
  final bool last;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 2,
    children: [
      IconButton(
        tooltip: 'Move up',
        icon: const Icon(Icons.arrow_upward),
        onPressed: first ? null : onUp,
      ),
      IconButton(
        tooltip: 'Move down',
        icon: const Icon(Icons.arrow_downward),
        onPressed: last ? null : onDown,
      ),
      IconButton(
        tooltip: 'Remove',
        icon: const Icon(Icons.delete_outline),
        onPressed: onRemove,
      ),
    ],
  );
}

/// A labeled field inside an editor: the label above the control in 12.5
/// muted, 6 apart, an optional helper line beneath in the same style. No
/// floating label inside the field's border: the remote admin's forms put
/// the label above, and this is the same shape. Fields stack 16 apart.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.helper,
  });

  final String label;
  final Widget child;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12.5,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: note),
        const SizedBox(height: 6),
        child,
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(helper!, style: note),
        ],
      ],
    );
  }
}

/// The one control box: what every picked value sits in at rest. 44 high,
/// surface 2 fill, hairline border, control radius, 12 side padding. The
/// dropdown, the time box and the copy box are this box with their content
/// inside; the remote admin's row inputs follow the same shape.
class ControlBox extends StatelessWidget {
  const ControlBox({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(Ks.radiusControl);
    final box = Container(
      height: 44,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: radius,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(borderRadius: radius, onTap: onTap, child: box),
    );
  }
}

/// A time of day at rest: the control box showing the value with a 20
/// clock glyph. Tapping opens the time picker (showKsTimePicker). Empty
/// reads Not set in muted text. The remote's .time-box is the same.
class TimeBox extends StatelessWidget {
  const TimeBox({
    super.key,
    required this.value,
    required this.onTap,
    this.expand = false,
  });

  /// "HH:mm", or empty for not set.
  final String value;
  final VoidCallback onTap;

  /// Fill the available width, for a labeled field inside an editor.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = Text(
      value.isEmpty ? 'Not set' : value,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: value.isEmpty ? scheme.onSurfaceVariant : scheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return ControlBox(
      onTap: onTap,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (expand) Expanded(child: text) else text,
          const SizedBox(width: 10),
          Icon(
            Icons.schedule_outlined,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// A calendar date at rest: the control box showing the value with a 20
/// calendar glyph, the TimeBox in every other respect. Tapping opens the
/// date picker. Empty reads [placeholder] in muted text, which says what
/// no date means here (Any time, Today) rather than Not set. The remote's
/// .date-box is the same (issue #383).
class DateBox extends StatelessWidget {
  const DateBox({
    super.key,
    required this.value,
    required this.onTap,
    this.placeholder = 'Not set',
    this.expand = false,
  });

  /// "YYYY-MM-DD", or empty for no date.
  final String value;
  final VoidCallback onTap;
  final String placeholder;

  /// Fill the available width, for a labeled field inside an editor.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = Text(
      value.isEmpty ? placeholder : value,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: value.isEmpty ? scheme.onSurfaceVariant : scheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return ControlBox(
      onTap: onTap,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (expand) Expanded(child: text) else text,
          const SizedBox(width: 10),
          Icon(Icons.event_outlined, size: 20, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// A value the user takes elsewhere (the ESPHome encryption key): the
/// control box, read only, the value in mono, with a 36 copy disc inside
/// its end. Tapping anywhere on the box copies; the disc turns to a
/// primary check for two seconds and a toast says Copied. Never a bare
/// selectable string: a double tap stops at the + / = a base64 key is
/// full of, and a partial key pasted into Home Assistant fails with a
/// generic error. 260 wide at the end of a row; stacked under the name on
/// a tight pane it fills the row. The remote's .copy-box is the same.
class CopyBox extends StatefulWidget {
  const CopyBox({super.key, required this.value, this.placeholder = 'Not set'});

  final String value;

  /// Shown in muted text while [value] is empty. Nothing to copy then.
  final String placeholder;

  @override
  State<CopyBox> createState() => _CopyBoxState();
}

class _CopyBoxState extends State<CopyBox> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    if (widget.value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    showToast(
      context,
      title: 'Copied',
      kind: ToastKind.success,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final empty = widget.value.isEmpty;
    return SizedBox(
      width: 260,
      child: ControlBox(
        onTap: empty ? null : _copy,
        padding: const EdgeInsets.only(left: 12, right: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                empty ? widget.placeholder : widget.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: empty
                    ? theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      )
                    : TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13.5,
                        color: scheme.onSurface,
                      ),
              ),
            ),
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                tooltip: 'Copy',
                padding: EdgeInsets.zero,
                iconSize: 22,
                color: _copied ? scheme.primary : scheme.onSurfaceVariant,
                icon: Icon(_copied ? Icons.check : Icons.copy_outlined),
                onPressed: empty ? null : _copy,
              ),
            ),
          ],
        ),
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
    // Dpad/arrow traversal (issue #377) focuses the DropdownButton inside,
    // whose own focus tint is invisible against the box: the one control
    // whose row showed nothing while every other row lit up. The wrapper
    // watches the inner button's focus and lights the box the way an
    // InkWell row lights — a gray wash and a firmer outline, no ring.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: focused
                  ? Color.alphaBlend(
                      scheme.onSurface.withValues(alpha: 0.10),
                      scheme.surfaceContainerHighest,
                    )
                  : scheme.surfaceContainerHighest,
              border: Border.all(
                color: focused ? scheme.outline : scheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(Ks.radiusControl),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: expand,
                borderRadius: BorderRadius.circular(Ks.radiusControl),
                focusColor: Colors.transparent,
                iconEnabledColor: scheme.onSurfaceVariant,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                ),
                items: items,
                onChanged: onChanged,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Whether the pane a row lives in is too narrow for a name, a description
/// and a wide control side by side. The settings split view keeps a rail
/// on screens 720 and up (same constants as the settings screen); below
/// that the page is full width. Under 640 rows reflow: a short control
/// shares the first line with the name, a wide one stacks under it, the
/// description goes beneath. LayoutBuilder cannot answer this inside a
/// ListTile (it measures intrinsics), so the pane width is derived from
/// the screen instead. The remote admin reflows at the same 640.
bool tightPane(BuildContext context) {
  final screen = MediaQuery.sizeOf(context).width;
  final pane = screen >= 720
      ? screen - (screen * 0.4).clamp(320.0, 430.0)
      : screen;
  return pane < 640;
}

/// A settings row that reflows on a tight pane instead of squeezing its
/// text beside the control. On a roomy pane it is a plain [ListTile], so
/// it matches every other row to the pixel. Under 640 (see [tightPane])
/// the name and a short [trailing] share the first line, the name keeping
/// at least 40% of the row and wrapping first, and the [subtitle] spans
/// the full width beneath. A control too wide for the name line passes
/// [stack]: it takes the next line and stretches across the row. With a
/// [leading] icon the stacked control and the subtitle indent to the
/// name, never under the icon.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.stack = false,
    this.contentPadding,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  /// Rows inside a dialog pass zero: the dialog's padding is the inset.
  final EdgeInsetsGeometry? contentPadding;

  /// The control is wider than a switch, a number or a single text button:
  /// stack it under the name on a tight pane.
  final bool stack;

  /// The leading icon's width plus the gap to the name: what the stacked
  /// control and the subtitle indent by so they line up with the name.
  static const double _indent = 24 + 12;

  @override
  Widget build(BuildContext context) {
    if (!tightPane(context)) {
      return ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        enabled: enabled,
        contentPadding: contentPadding,
      );
    }
    final theme = Theme.of(context);
    final tiles = theme.listTileTheme;
    final scheme = theme.colorScheme;
    final titleStyle = (tiles.titleTextStyle ?? theme.textTheme.bodyLarge!)
        .copyWith(
          color: enabled ? null : scheme.onSurface.withValues(alpha: 0.38),
        );
    final subtitleStyle =
        (tiles.subtitleTextStyle ?? theme.textTheme.bodyMedium!).copyWith(
          color: enabled
              ? null
              : scheme.onSurfaceVariant.withValues(alpha: 0.38),
        );
    final indent = leading == null ? 0.0 : _indent;
    final control = trailing;
    final side = contentPadding?.horizontal ?? 2 * Ks.inset;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(side / 2, 13, side / 2, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (leading != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(
                      color: tiles.iconColor ?? scheme.onSurfaceVariant,
                      size: 24,
                    ),
                    child: leading!,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: titleStyle,
                    child: title,
                  ),
                ),
                if (control != null && !stack) ...[
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    // The name keeps at least 40% of the row and wraps
                    // first: a control never squeezes it into a sliver.
                    constraints: BoxConstraints(
                      maxWidth:
                          (MediaQuery.sizeOf(context).width - side - indent) *
                          0.6,
                    ),
                    child: control,
                  ),
                ],
              ],
            ),
            if (control != null && stack)
              Padding(
                padding: EdgeInsets.only(left: indent, top: 6),
                child: SizedBox(width: double.infinity, child: control),
              ),
            if (subtitle != null)
              Padding(
                padding: EdgeInsets.only(left: indent, top: 4),
                child: DefaultTextStyle.merge(
                  style: subtitleStyle,
                  child: subtitle!,
                ),
              ),
          ],
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
    final tight = tightPane(context);
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
