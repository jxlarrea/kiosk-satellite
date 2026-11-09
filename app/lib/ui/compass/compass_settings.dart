import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_container.dart';
import '../../l10n/messages.dart';
import '../../managers/navigation/compass_layout.dart';
import '../../managers/settings/definitions.dart' as defs;
import '../dashboard_view_picker.dart';
import '../kit.dart';
import 'compass_controller.dart';

/// Settings > Navigation's rows that no plain setting row can draw: the
/// two style cards and the layout editor. The remote admin draws the same
/// in compass.js.

/// Classic or Compass, as two cards with a picture of each.
class CompassStyleRow extends StatelessWidget {
  const CompassStyleRow({
    super.key,
    required this.container,
    required this.onChanged,
  });

  final AppContainer container;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final value = container.settings.get(defs.navStyle);
    Future<void> pick(String v) async {
      if (v == value) return;
      await container.settings.setFromJson(defs.navStyle.key, v);
      onChanged();
    }

    final classic = _StyleChoice(
      title: strings.navigationClassic,
      hint: strings.compassClassicHint,
      picture: const _ClassicPicture(),
      selected: value == 'classic',
      onTap: () => pick('classic'),
    );
    final compass = _StyleChoice(
      title: strings.navigationCompass,
      hint: strings.compassCompassHint,
      picture: const _CompassPicture(),
      selected: value == 'compass',
      onTap: () => pick('compass'),
    );
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 560;
        final cards = wide
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 14,
                  children: [
                    Expanded(child: classic),
                    Expanded(child: compass),
                  ],
                ),
              )
            : Column(spacing: 10, children: [classic, compass]);
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cards,
              // What Compass switches off. The rows themselves stay,
              // greyed out (SettingDef.offWhen).
              if (value == 'compass') ...[
                const SizedBox(height: 12),
                Text(
                  strings.compassOffNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StyleChoice extends StatelessWidget {
  const _StyleChoice({
    required this.title,
    required this.hint,
    required this.picture,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String hint;
  final Widget picture;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.45)
            : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              spacing: 14,
              children: [
                SizedBox(width: 92, height: 60, child: picture),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? scheme.secondary : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A screen with the drawer pulled out over the dashboard.
class _ClassicPicture extends StatelessWidget {
  const _ClassicPicture();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget bar(double w, Color c) => Container(
      height: 4,
      width: w,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                bar(16, scheme.outline),
                bar(12, scheme.outlineVariant),
                bar(14, scheme.outlineVariant),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.4,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < 4; i++)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Five views in a cross, the center one lit.
class _CompassPicture extends StatelessWidget {
  const _CompassPicture();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget cell(bool lit) => Container(
      width: 18,
      height: 12,
      decoration: BoxDecoration(
        color: lit ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(3),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: [
            cell(false),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 3,
              children: [cell(false), cell(true), cell(false)],
            ),
            cell(false),
          ],
        ),
      ),
    );
  }
}

// ── The layout editor ────────────────────────────────────────────────

const _sides = [
  CompassArm.up,
  CompassArm.right,
  CompassArm.down,
  CompassArm.left,
];

String _sideName(BuildContext context, CompassArm arm) {
  final s = l10n(context);
  return switch (arm) {
    CompassArm.up => s.compassSideUp,
    CompassArm.right => s.compassSideRight,
    CompassArm.down => s.compassSideDown,
    CompassArm.left => s.compassSideLeft,
    CompassArm.center => s.compassCenter,
  };
}

IconData _sideIcon(CompassArm arm) => switch (arm) {
  CompassArm.up => Icons.arrow_upward,
  CompassArm.right => Icons.arrow_forward,
  CompassArm.down => Icons.arrow_downward,
  CompassArm.left => Icons.arrow_back,
  CompassArm.center => Icons.adjust,
};

/// The views around the center: a map of the cross on a roomy pane, where
/// a tap picks a view and the bar under the map acts on it, and lists by
/// side on a narrow one.
class CompassLayoutEditor extends StatefulWidget {
  const CompassLayoutEditor({
    super.key,
    required this.container,
    required this.onChanged,
  });

  final AppContainer container;
  final VoidCallback onChanged;

  @override
  State<CompassLayoutEditor> createState() => _CompassLayoutEditorState();
}

class _CompassLayoutEditorState extends State<CompassLayoutEditor> {
  AppContainer get c => widget.container;

  CompassSlot? _picked;

  CompassLayout get _layout =>
      CompassLayout.decode(c.settings.get(defs.navCompassLayout));

  @override
  void initState() {
    super.initState();
    // Dashboard views are shown by name.
    if (DashboardCatalog.current.value == null) {
      unawaited(DashboardCatalog.load(c));
    }
  }

  Future<void> _save(CompassLayout layout) async {
    await c.settings.setFromJson(defs.navCompassLayout.key, layout.encode());
    widget.onChanged();
    if (mounted) setState(() {});
  }

  String _label(CompassView view) => compassViewLabel(context, c, view);

  Future<void> _add(CompassArm arm) async {
    final strings = l10n(context);
    final layout = _layout;
    final view = await showCompassViewDialog(
      context,
      container: c,
      layout: layout,
      title: switch (arm) {
        CompassArm.up => strings.compassAddAbove,
        CompassArm.down => strings.compassAddBelow,
        CompassArm.left => strings.compassAddLeft,
        CompassArm.right => strings.compassAddRight,
        CompassArm.center => strings.compassChangeCenter,
      },
      confirm: strings.compassAddTile,
    );
    if (view == null) return;
    final side = [...layout.side(arm)];
    if (side.length >= compassSideLimit) return;
    side.add(view);
    _picked = CompassSlot(arm, side.length - 1);
    await _save(layout.withSide(arm, side));
  }

  Future<void> _replace(CompassSlot slot) async {
    final strings = l10n(context);
    final layout = _layout;
    final old = layout.viewAt(slot);
    if (old == null) return;
    final view = await showCompassViewDialog(
      context,
      container: c,
      layout: layout,
      replacing: old,
      title: slot.isCenter
          ? strings.compassChangeCenter
          : strings.compassReplaceTitle(_label(old)),
      confirm: strings.compassReplace,
    );
    if (view == null) return;
    if (slot.isCenter) {
      await _save(layout.copyWith(center: view));
      return;
    }
    final side = [...layout.side(slot.arm)];
    side[slot.index] = view;
    await _save(layout.withSide(slot.arm, side));
  }

  Future<void> _remove(CompassSlot slot) async {
    final layout = _layout;
    final side = [...layout.side(slot.arm)]..removeAt(slot.index);
    _picked = null;
    await _save(layout.withSide(slot.arm, side));
  }

  Future<void> _shift(CompassSlot slot, int by) async {
    final layout = _layout;
    final side = [...layout.side(slot.arm)];
    final to = slot.index + by;
    if (to < 0 || to >= side.length) return;
    final view = side.removeAt(slot.index);
    side.insert(to, view);
    _picked = CompassSlot(slot.arm, to);
    await _save(layout.withSide(slot.arm, side));
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    // Names arrive with the dashboard list.
    valueListenable: DashboardCatalog.current,
    builder: (context, _, _) => LayoutBuilder(
      builder: (context, box) {
        final cell = (box.maxWidth - 32 - 4 * 8) / 5;
        return cell >= 64
            ? _map(context, cell.clamp(64, 112))
            : _lists(context);
      },
    ),
  );

  // ── Roomy: the map ──

  Widget _map(BuildContext context, double cell) {
    final strings = l10n(context);
    final theme = Theme.of(context);
    final layout = _layout;
    final picked = _picked != null && layout.viewAt(_picked!) != null
        ? _picked
        : null;
    // Room for the icon over a label of up to two lines.
    final height = (cell * 0.56).clamp(54.0, 62.0);
    const gap = 8.0;

    // Grid cell of each place: the center in column 2, row 2, the sides
    // running out from it.
    Widget? at(int col, int row) {
      if (col == 2 && row == 2) {
        return _tile(context, CompassSlot.center, layout.center, picked);
      }
      if (col == 2 || row == 2) {
        final arm = col == 2
            ? (row < 2 ? CompassArm.up : CompassArm.down)
            : (col < 2 ? CompassArm.left : CompassArm.right);
        final index = switch (arm) {
          CompassArm.up => 1 - row,
          CompassArm.down => row - 3,
          CompassArm.right => col - 3,
          CompassArm.left => 1 - col,
          CompassArm.center => 0,
        };
        final views = layout.side(arm);
        if (index < views.length) {
          return _tile(context, CompassSlot(arm, index), views[index], picked);
        }
        if (index == views.length && views.length < compassSideLimit) {
          return _addTile(context, arm);
        }
      }
      return null;
    }

    final width = 5 * cell + 4 * gap;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.compassLayoutHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              width: width,
              height: 5 * height + 4 * gap,
              child: Stack(
                children: [
                  // The two arms, behind the tiles.
                  Positioned(
                    left: cell / 2,
                    right: cell / 2,
                    top: 2 * (height + gap) + height / 2 - 1,
                    height: 2,
                    child: ColoredBox(color: theme.colorScheme.outlineVariant),
                  ),
                  Positioned(
                    left: 2 * (cell + gap) + cell / 2 - 1,
                    width: 2,
                    top: height / 2,
                    bottom: height / 2,
                    child: ColoredBox(color: theme.colorScheme.outlineVariant),
                  ),
                  for (var row = 0; row < 5; row++)
                    for (var col = 0; col < 5; col++)
                      if (at(col, row) case final tile?)
                        Positioned(
                          left: col * (cell + gap),
                          top: row * (height + gap),
                          width: cell,
                          height: height,
                          child: tile,
                        ),
                ],
              ),
            ),
          ),
          // What can be done with the picked view, only once one is.
          if (picked != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _actionBar(context, layout, picked),
          ],
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    CompassSlot slot,
    CompassView view,
    CompassSlot? picked,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final center = slot.isCenter;
    final on = slot == picked;
    final available = compassKindConfigurable(c, view.kind);
    final fill = center ? scheme.primaryContainer : scheme.surfaceContainerHigh;
    final border = on
        ? BorderSide(color: scheme.tertiary, width: 2)
        : center
        ? BorderSide(color: scheme.primary, width: 2)
        : BorderSide(color: scheme.outlineVariant);
    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _picked = on ? null : slot),
        child: Opacity(
          opacity: available ? 1 : 0.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  compassViewIcon(view),
                  size: 17,
                  color: center
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 2),
                Text(
                  _label(view),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _addTile(BuildContext context, CompassArm arm) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      // The card's own color, so the arm behind stops at the tile's edge.
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outline, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _add(arm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 17, color: scheme.onSurfaceVariant),
            Text(
              l10n(context).compassAddTile,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBar(
    BuildContext context,
    CompassLayout layout,
    CompassSlot slot,
  ) {
    final strings = l10n(context);
    final theme = Theme.of(context);
    final view = layout.viewAt(slot)!;
    final where = slot.isCenter
        ? strings.compassCenter
        : slot.index == 0
        ? strings.compassFirstView(_sideName(context, slot.arm))
        : strings.compassSecondView(_sideName(context, slot.arm));
    final side = slot.isCenter ? const <CompassView>[] : layout.side(slot.arm);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_label(view), style: theme.textTheme.titleSmall),
              Text(
                where,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!slot.isCenter && slot.index > 0)
          OutlinedButton(
            onPressed: () => _shift(slot, -1),
            child: Text(strings.compassMoveIn),
          ),
        if (!slot.isCenter && slot.index < side.length - 1)
          OutlinedButton(
            onPressed: () => _shift(slot, 1),
            child: Text(strings.compassMoveOut),
          ),
        OutlinedButton(
          onPressed: () => _replace(slot),
          child: Text(strings.compassReplace),
        ),
        if (!slot.isCenter)
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: () => _remove(slot),
            child: Text(strings.compassRemove),
          ),
      ],
    );
  }

  // ── Narrow: lists by side ──

  Widget _lists(BuildContext context) {
    final strings = l10n(context);
    final theme = Theme.of(context);
    final layout = _layout;
    final rows = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Text(
          strings.compassLayoutHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      ListTile(
        leading: Icon(compassViewIcon(layout.center)),
        title: Text(strings.compassCenter),
        subtitle: Text(_label(layout.center)),
        trailing: TextButton(
          onPressed: () => _replace(CompassSlot.center),
          child: Text(strings.compassChange),
        ),
      ),
    ];
    for (final arm in _sides) {
      final stored = layout.side(arm);
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
          child: Row(
            spacing: 8,
            children: [
              Icon(
                _sideIcon(arm),
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              Text(
                _sideName(context, arm).toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
      for (final (i, view) in stored.indexed) {
        rows.add(
          ListTile(
            leading: Icon(compassViewIcon(view)),
            title: Text(_label(view)),
            onTap: () => _replace(CompassSlot(arm, i)),
            trailing: OrderActions(
              first: i == 0,
              last: i == stored.length - 1,
              onUp: () => _shift(CompassSlot(arm, i), -1),
              onDown: () => _shift(CompassSlot(arm, i), 1),
              onRemove: () => _remove(CompassSlot(arm, i)),
            ),
          ),
        );
      }
      if (stored.length < compassSideLimit) {
        rows.add(
          ListTile(
            leading: Icon(Icons.add, color: theme.colorScheme.secondary),
            title: Text(
              strings.compassAddView,
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _add(arm),
          ),
        );
      }
    }
    rows.add(const SizedBox(height: 8));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

// ── Picking a view ───────────────────────────────────────────────────

/// Picks a view to place: one row per kind, with the dashboard field
/// under the dashboard row and the camera views under the camera row
/// when there is a choice. A kind the layout already holds, other than
/// the one being [replacing], and a kind with nothing set up on this
/// kiosk cannot be picked. Null when cancelled.
Future<CompassView?> showCompassViewDialog(
  BuildContext context, {
  required AppContainer container,
  required CompassLayout layout,
  required String title,
  required String confirm,
  CompassView? replacing,
}) => showDialog<CompassView>(
  context: context,
  builder: (context) => _CompassViewDialog(
    container: container,
    layout: layout,
    title: title,
    confirm: confirm,
    replacing: replacing,
  ),
);

class _CompassViewDialog extends StatefulWidget {
  const _CompassViewDialog({
    required this.container,
    required this.layout,
    required this.title,
    required this.confirm,
    this.replacing,
  });

  final AppContainer container;
  final CompassLayout layout;
  final String title;
  final String confirm;
  final CompassView? replacing;

  @override
  State<_CompassViewDialog> createState() => _CompassViewDialogState();
}

class _CompassViewDialogState extends State<_CompassViewDialog> {
  AppContainer get c => widget.container;

  String? _kind;
  late String _path = widget.replacing?.isDashboard == true
      ? widget.replacing!.path
      : '';
  late String _camera = widget.replacing?.kind == 'camera'
      ? widget.replacing!.id
      : (compassCameraViews(c).where((v) => v.isDefault).firstOrNull?.id ??
            compassCameraViews(c).firstOrNull?.id ??
            '');

  bool _taken(String kind) =>
      kind != widget.replacing?.kind && widget.layout.holds(CompassView(kind));

  @override
  void initState() {
    super.initState();
    final kind = widget.replacing?.kind;
    if (kind != null) _kind = kind;
  }

  String _kindLabel(String kind) {
    final strings = l10n(context);
    return switch (kind) {
      'dashboard' => strings.compassKindDashboard,
      'camera' => strings.drawerCameraView,
      _ => compassViewLabel(context, c, CompassView(kind, id: 'x')),
    };
  }

  CompassView? get _result => switch (_kind) {
    null => null,
    'dashboard' => CompassView('dashboard', path: _path),
    'camera' => _camera.isEmpty ? null : CompassView('camera', id: _camera),
    final kind => CompassView(kind),
  };

  Future<void> _pickDashboard() async {
    final controllerHome = dashboardPathOfUrl(
      c.browser.startUrl,
      c.homeAssistant.baseUrl,
      pages: c.homeAssistant.customPages,
    );
    final picked = await showDashboardPicker(
      context,
      container: c,
      title: l10n(context).compassKindDashboard,
      selected: _path.isEmpty ? controllerHome : _path,
    );
    if (picked == null || !mounted) return;
    setState(() => _path = picked);
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final theme = Theme.of(context);
    final home = dashboardPathOfUrl(
      c.browser.startUrl,
      c.homeAssistant.baseUrl,
      pages: c.homeAssistant.customPages,
    );
    final rows = <Widget>[];
    for (final kind in compassViewKinds) {
      final taken = _taken(kind);
      final ready = compassKindConfigurable(c, kind);
      final enabled = !taken && ready;
      rows.add(
        RadioListTile<String>(
          value: kind,
          enabled: enabled,
          secondary: Icon(compassViewIcon(CompassView(kind))),
          title: Text(_kindLabel(kind)),
          subtitle: taken
              ? Text(strings.compassKindTaken)
              : !ready
              ? Text(strings.compassKindUnavailable)
              : kind == 'dashboard'
              ? Text(strings.compassKindDashboardHint)
              : null,
          // The dialog's own margin on the left. The icons sit further in,
          // clear of the edge and in line with the dashboard field's chevron.
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 40, 0),
        ),
      );
      if (kind == 'dashboard' && _kind == 'dashboard') {
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: DashboardField(
              container: c,
              value: _path.isEmpty ? (home ?? '') : _path,
              onTap: _pickDashboard,
            ),
          ),
        );
      }
      final views = compassCameraViews(c);
      if (kind == 'camera' && _kind == 'camera' && views.length > 1) {
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: KsDropdown<String>(
              expand: true,
              value: views.any((v) => v.id == _camera) ? _camera : null,
              items: [
                for (final v in views)
                  DropdownMenuItem(value: v.id, child: Text(v.name)),
              ],
              onChanged: (v) => setState(() => _camera = v ?? _camera),
            ),
          ),
        );
      }
    }
    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: 480,
        child: EdgeFade(
          child: SingleChildScrollView(
            child: RadioGroup<String>(
              groupValue: _kind,
              onChanged: (v) => setState(() => _kind = v),
              child: Column(mainAxisSize: MainAxisSize.min, children: rows),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.commonCancel),
        ),
        FilledButton(
          onPressed: _result == null
              ? null
              : () => Navigator.of(context).pop(_result),
          child: Text(widget.confirm),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      titleTextStyle: theme.textTheme.titleLarge,
    );
  }
}
