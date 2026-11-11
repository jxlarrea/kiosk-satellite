import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/home_assistant/custom_pages.dart';
import '../l10n/messages.dart';
import 'kit.dart';
import 'mdi_icon.dart';
import 'picker_dialog.dart';
import 'theme.dart';

/// One Home Assistant view, as the dashboard picker shows it.
class HaView {
  const HaView({
    required this.title,
    required this.route,
    this.icon,
    this.subview = false,
  });

  final String title;

  /// The path segment Home Assistant navigates by: the view's path, or its
  /// index when it has none.
  final String route;

  /// The view's MDI icon ("mdi:sofa"), when it has one.
  final String? icon;

  /// Opened from a card rather than the view tabs.
  final bool subview;
}

/// One Home Assistant dashboard and its views.
class HaDashboard {
  const HaDashboard({
    required this.path,
    required this.title,
    this.icon,
    this.views = const [],
    this.custom = false,
    this.app = false,
    this.builtIn = false,
  });

  /// The dashboard's url_path.
  final String path;
  final String title;
  final String? icon;

  /// The Custom Pages entry: the person's own pages under /local/, listed
  /// as its views.
  final bool custom;

  /// An app's sidebar panel, such as Music Assistant: Home Assistant shows
  /// the app's ingress page on its path, with no views.
  final bool app;

  /// One of Home Assistant's own pages, such as Energy or History, or a
  /// page an integration adds. Like an app, it is one page with no views.
  final bool builtIn;

  /// An app or a built-in page: the pickers show it by its own name.
  bool get page => app || builtIn;

  /// The name the pickers show, in the kiosk's language for Custom Pages.
  String label(BuildContext context) =>
      custom ? haText(context, 'Custom Pages') : title;

  /// Empty for a dashboard that builds its own views (a strategy
  /// dashboard): the kiosk opens it whole, by its bare path.
  final List<HaView> views;

  bool get whole => views.isEmpty;

  /// The navigation path of [view], or of the dashboard itself.
  String pathOf(HaView? view) => view == null ? path : '$path/${view.route}';
}

/// What a stored navigation path names: the dashboard, and the view, null
/// for a dashboard opened whole.
typedef DashboardMatch = ({HaDashboard dashboard, HaView? view});

/// The kiosk's dashboards and views, read from Home Assistant and kept for
/// the session. Pickers open on the cached list and refresh it in place,
/// and every [DashboardField] follows [current].
abstract final class DashboardCatalog {
  static final current = ValueNotifier<List<HaDashboard>?>(null);
  static Future<List<HaDashboard>?>? _pending;

  /// Forgets the session's list, for tests that stub other dashboards.
  @visibleForTesting
  static void reset() {
    current.value = null;
    _pending = null;
  }

  /// Every dashboard with its views. Null when Home Assistant cannot list
  /// its dashboards, in which case [current] keeps the last good list.
  static Future<List<HaDashboard>?> load(AppContainer c) =>
      _pending ??= _load(c).whenComplete(() => _pending = null);

  static Future<List<HaDashboard>?> _load(AppContainer c) async {
    // Through the commands the remote admin also uses, so both surfaces
    // read the same lists.
    final listed = await c.commands.execute('haListDashboards', const {});
    if (!listed.ok || listed.data is! List) return null;
    final dashboards = [
      for (final d in listed.data as List)
        if (d is Map) Map<String, Object?>.from(d),
    ];
    final views = await Future.wait([
      for (final d in dashboards)
        c.commands
            .execute('haListDashboardViews', {'url_path': d['url_path']})
            .then(
              (r) => r.ok && r.data is List
                  ? [
                      for (final v in r.data as List)
                        if (v is Map) Map<String, Object?>.from(v),
                    ]
                  : null,
            ),
    ]);
    final list = [
      for (final (i, d) in dashboards.indexed)
        if ('${d['url_path'] ?? ''}'.isNotEmpty)
          HaDashboard(
            path: '${d['url_path']}',
            title: '${d['title'] ?? d['url_path']}',
            icon: d['icon'] is String ? d['icon'] as String : null,
            custom: d['custom'] == true,
            app: d['app'] == true,
            builtIn: d['builtIn'] == true,
            views: [
              // A dashboard whose views cannot be read opens whole, the
              // same as one that builds its own.
              for (final v in views[i] ?? const <Map<String, Object?>>[])
                if ('${v['route'] ?? ''}'.isNotEmpty)
                  HaView(
                    title: '${v['title'] ?? v['route']}',
                    route: '${v['route']}',
                    icon: v['icon'] is String ? v['icon'] as String : null,
                    subview: v['subview'] == true,
                  ),
            ],
          ),
    ];
    current.value = list;
    return list;
  }

  /// [path] in [list]: "dashboard/view", or a bare dashboard, which reads
  /// as its first view because that is what Home Assistant opens. Null
  /// when the path names nothing in the list.
  static DashboardMatch? match(List<HaDashboard> list, String path) {
    if (path.isEmpty) return null;
    for (final d in list) {
      if (path == d.path) return (dashboard: d, view: d.views.firstOrNull);
      if (path.startsWith('${d.path}/')) {
        final route = path.substring(d.path.length + 1);
        for (final v in d.views) {
          if (v.route == route) return (dashboard: d, view: v);
        }
      }
    }
    return null;
  }
}

/// The navigation path inside a start URL on [base]: what follows the
/// origin, without a query or fragment, which a custom page keeps since
/// they pick its layout. A URL elsewhere is one of the custom [pages] on
/// another server, or null.
String? dashboardPathOfUrl(
  String url,
  String base, {
  List<CustomPage> pages = const [],
}) {
  if (base.isEmpty || !url.startsWith('$base/')) {
    return externalPageNavPath(url, pages);
  }
  var path = url.substring(base.length + 1);
  if (isCustomPagePath(path)) return path;
  final cut = path.indexOf(RegExp('[?#]'));
  if (cut >= 0) path = path.substring(0, cut);
  while (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return path;
}

/// The dashboard picker as a dialog: dashboards on the left, the browsed
/// dashboard's views as tiles on the right, search across both. Under 640
/// it fills the screen and drills from dashboards into views. A tap picks
/// and closes, Cancel in the footer closes without a pick. Resolves to the
/// navigation path, or null when dismissed.
Future<String?> showDashboardPicker(
  BuildContext context, {
  required AppContainer container,
  required String title,
  String? selected,
}) => showDialog<String>(
  context: context,
  // The dialog closes on an outside tap itself, see PickerDialog.
  barrierDismissible: false,
  builder: (context) => PickerDialog<String>(
    title: title,
    builder: (close) => DashboardPicker(
      container: container,
      title: title,
      selected: {if (selected != null && selected.isNotEmpty) selected},
      onPick: close,
      onClose: () => close(null),
    ),
  ),
);

/// The picker for several views at once (the rotation). Tiles carry a
/// checkbox and Done returns the picks, the ones already chosen first in
/// their order. Null when dismissed.
Future<List<String>?> showDashboardMultiPicker(
  BuildContext context, {
  required AppContainer container,
  required String title,
  List<String> selected = const [],
}) => showDialog<List<String>>(
  context: context,
  barrierDismissible: false,
  builder: (context) => PickerDialog<List<String>>(
    title: title,
    builder: (close) => DashboardPicker(
      container: container,
      title: title,
      selected: selected.toSet(),
      multiple: true,
      onDone: close,
      onClose: () => close(null),
    ),
  ),
);

/// The picker itself: in a dialog through [showDashboardPicker], inline in
/// Setup. At 520 and wider it shows two columns, narrower it drills in.
///
/// Single choice reports a tap through [onPick] and keeps [selected] as
/// the parent passes it. [multiple] toggles checkboxes and reports the
/// result through [onDone].
class DashboardPicker extends StatefulWidget {
  const DashboardPicker({
    super.key,
    required this.container,
    this.title,
    this.selected = const {},
    this.multiple = false,
    this.onPick,
    this.onDone,
    this.onClose,
  });

  final AppContainer container;

  /// The heading. Null inline, where the page names the step.
  final String? title;
  final Set<String> selected;
  final bool multiple;
  final ValueChanged<String>? onPick;
  final ValueChanged<List<String>>? onDone;

  /// Leaves the picker: the back arrow at the top level, Cancel.
  final VoidCallback? onClose;

  @override
  State<DashboardPicker> createState() => _DashboardPickerState();
}

class _DashboardPickerState extends State<DashboardPicker> {
  List<HaDashboard>? _list = DashboardCatalog.current.value;
  bool _loading = false;
  bool _failed = false;

  /// The dashboard shown on the right of the wide picker.
  String? _browsing;

  /// The dashboard drilled into on the narrow picker, null for the list.
  String? _drill;
  bool _browsed = false;
  late List<String> _picked = widget.selected.toList();
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (_list != null) _openOn(_list!);
    _reload();
  }

  @override
  void didUpdateWidget(DashboardPicker old) {
    super.didUpdateWidget(old);
    if (!widget.multiple && old.selected != widget.selected) {
      _picked = widget.selected.toList();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final list = await DashboardCatalog.load(widget.container);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (list == null) {
        _failed = _list == null;
        return;
      }
      _list = list;
      _openOn(list);
    });
  }

  /// Opens on the dashboard holding the first pick, else the first one.
  void _openOn(List<HaDashboard> list) {
    if (_browsed) return;
    _browsed = true;
    for (final p in _picked) {
      final m = DashboardCatalog.match(list, p);
      if (m != null) {
        _browsing = m.dashboard.path;
        return;
      }
    }
    _browsing = list.firstOrNull?.path;
  }

  bool _isPicked(HaDashboard d, HaView? v) {
    if (_picked.contains(d.pathOf(v))) return true;
    // A bare dashboard stored for a dashboard with views is its first one.
    return v != null && v == d.views.first && _picked.contains(d.path);
  }

  bool _holdsPick(HaDashboard d) =>
      d.whole ? _isPicked(d, null) : d.views.any((v) => _isPicked(d, v));

  void _tap(HaDashboard d, HaView? v) {
    final path = d.pathOf(v);
    if (!widget.multiple) {
      widget.onPick?.call(path);
      return;
    }
    setState(() {
      if (_isPicked(d, v)) {
        _picked.remove(path);
        if (v != null && v == d.views.first) _picked.remove(d.path);
      } else {
        _picked.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 520;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            wide ? _wideHeader(context) : _narrowHeader(context),
            Expanded(child: _content(context, wide)),
            // A dialog always offers Cancel, the remote's footer. Inline in
            // Setup there is nothing to cancel.
            if (widget.multiple || widget.onClose != null)
              _footer(context, wide),
          ],
        );
      },
    );
  }

  // ── Headers ────────────────────────────────────────────────────────────

  Widget _searchBox(BuildContext context, String hint) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v.trim()),
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14.5),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).deleteButtonTooltip,
                  onPressed: () => setState(() {
                    _search.clear();
                    _query = '';
                  }),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  bool get _ready => _list != null && _list!.isNotEmpty;

  Widget _wideHeader(BuildContext context) {
    final title = widget.title;
    if (title == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _searchBox(
          context,
          haText(context, 'Search dashboards and views'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (_ready) ...[
            const SizedBox(width: 16),
            SizedBox(
              width: 280,
              child: _searchBox(context, haText(context, 'Search views')),
            ),
          ],
        ],
      ),
    );
  }

  Widget _narrowHeader(BuildContext context) {
    final theme = Theme.of(context);
    final dash = _drilled;
    final back = dash != null
        ? () => setState(() => _drill = null)
        : widget.onClose;
    final title = dash?.label(context) ?? widget.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          SizedBox(
            height: 56,
            child: Row(
              children: [
                if (back != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: back,
                  )
                else
                  const SizedBox(width: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge,
                      ),
                      if (dash != null) _Mono('/${dash.path}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (dash == null && _ready)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: _searchBox(
              context,
              haText(context, 'Search dashboards and views'),
            ),
          ),
      ],
    );
  }

  /// The dashboard drilled into on a narrow picker, outside a search.
  HaDashboard? get _drilled {
    final list = _list;
    if (list == null || _query.isNotEmpty) return null;
    for (final d in list) {
      if (d.path == _drill) return d;
    }
    return null;
  }

  Widget _footer(BuildContext context, bool wide) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      // The full screen picker has no dialog padding of its own.
      margin: wide ? null : const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.only(top: 14, bottom: wide ? 0 : 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: widget.multiple
                ? Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      l10n(
                        context,
                      ).dashboardPickerSelected('${_picked.length}'),
                      style: TextStyle(
                        fontSize: 13.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          TextButton(
            onPressed: widget.onClose,
            child: Text(haText(context, 'Cancel')),
          ),
          if (widget.multiple) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => widget.onDone?.call(List.of(_picked)),
              child: Text(haText(context, 'Done')),
            ),
          ],
        ],
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────

  Widget _content(BuildContext context, bool wide) {
    final list = _list;
    if (list == null) {
      if (_failed) {
        return _StateMessage(
          icon: Icons.link_off,
          title: haText(context, 'Could not reach Home Assistant'),
          message: haText(
            context,
            'The dashboards load once the connection is back.',
          ),
          action: OutlinedButton.icon(
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(haText(context, 'Try again')),
          ),
        );
      }
      return _Skeleton(wide: wide);
    }
    if (list.isEmpty) {
      return _StateMessage(
        icon: Icons.grid_view,
        title: haText(context, 'No dashboards yet'),
        message: haText(
          context,
          'Dashboards you add in Home Assistant show up here.',
        ),
      );
    }
    if (_query.isNotEmpty) return _results(context, list);
    if (!wide) {
      final dash = _drilled;
      return dash == null
          ? _dashboardList(context, list)
          : _viewList(context, dash);
    }
    final scheme = Theme.of(context).colorScheme;
    final browsing =
        list.where((d) => d.path == _browsing).firstOrNull ?? list.first;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 236,
          padding: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: scheme.outlineVariant)),
          ),
          child: EdgeFade(
            child: ListView(
              children: [
                for (final d in list)
                  _DashboardRow(
                    dashboard: d,
                    active: d == browsing,
                    holds: _holdsPick(d),
                    onTap: () => setState(() => _browsing = d.path),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _viewGrid(context, browsing),
          ),
        ),
      ],
    );
  }

  Widget _viewGrid(BuildContext context, HaDashboard d) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        const columns = 2;
        SliverGrid grid(List<HaView?> views) => SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 118,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          delegate: SliverChildListDelegate([
            for (final v in views)
              _ViewTile(
                dashboard: d,
                view: v,
                picked: _isPicked(d, v),
                multiple: widget.multiple,
                onTap: () => _tap(d, v),
              ),
          ]),
        );
        final main = [
          for (final v in d.views)
            if (!v.subview) v,
        ];
        final subs = [
          for (final v in d.views)
            if (v.subview) v,
        ];
        return EdgeFade(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          d.label(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _Mono('/${d.path}'),
                    ],
                  ),
                ),
              ),
              if (d.whole) ...[
                grid([null]),
                if (!d.page) SliverToBoxAdapter(child: _WholeNote()),
              ] else ...[
                grid(main),
                if (subs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SubHeading(haText(context, 'Subviews')),
                  ),
                  grid(subs),
                ],
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],
          ),
        );
      },
    );
  }

  Widget _dashboardList(BuildContext context, List<HaDashboard> list) {
    DashboardMatch? current;
    if (!widget.multiple) {
      for (final p in _picked) {
        current ??= DashboardCatalog.match(list, p);
      }
    }
    return EdgeFade(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          if (current != null) ...[
            _SubHeading(haText(context, 'Current'), inset: true),
            _ViewRow(
              dashboard: current.dashboard,
              view: current.view,
              picked: true,
              withDashboard: true,
              onTap: () => _tap(current!.dashboard, current.view),
            ),
            _SubHeading(haText(context, 'Dashboards'), inset: true),
          ],
          for (final d in list)
            _DashboardRow(
              dashboard: d,
              holds: _holdsPick(d),
              chevron: true,
              onTap: () => setState(() => _drill = d.path),
            ),
        ],
      ),
    );
  }

  Widget _viewList(BuildContext context, HaDashboard d) {
    final main = [
      for (final v in d.views)
        if (!v.subview) v,
    ];
    final subs = [
      for (final v in d.views)
        if (v.subview) v,
    ];
    Widget row(HaView? v) => _ViewRow(
      dashboard: d,
      view: v,
      picked: _isPicked(d, v),
      multiple: widget.multiple,
      onTap: () => _tap(d, v),
    );
    return EdgeFade(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          if (d.whole) ...[
            row(null),
            if (!d.page) _WholeNote(),
          ] else ...[
            for (final v in main) row(v),
            if (subs.isNotEmpty) ...[
              _SubHeading(haText(context, 'Subviews'), inset: true),
              for (final v in subs) row(v),
            ],
          ],
        ],
      ),
    );
  }

  /// Views whose title, dashboard title or path holds the query, grouped
  /// under their dashboard. A dashboard that matches lists all its views.
  Widget _results(BuildContext context, List<HaDashboard> list) {
    final q = _query.toLowerCase();
    final groups = <(HaDashboard, List<HaView?>)>[];
    for (final d in list) {
      final all =
          d.label(context).toLowerCase().contains(q) ||
          d.path.toLowerCase().contains(q);
      if (d.whole) {
        if (all) groups.add((d, [null]));
        continue;
      }
      final views = [
        for (final v in d.views)
          if (all ||
              v.title.toLowerCase().contains(q) ||
              v.route.toLowerCase().contains(q))
            v,
      ];
      if (views.isNotEmpty) groups.add((d, views));
    }
    if (groups.isEmpty) {
      return _StateMessage(
        icon: Icons.search_off,
        title: haText(context, 'No views match'),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return EdgeFade(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
        children: [
          for (final (d, views) in groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Row(
                children: [
                  _Glyph(
                    icon: d.icon ?? 'mdi:view-dashboard',
                    title: d.label(context),
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _Highlighted(
                      d.label(context),
                      _query,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final v in views)
              _ViewRow(
                dashboard: d,
                view: v,
                picked: _isPicked(d, v),
                multiple: widget.multiple,
                query: _query,
                onTap: () => _tap(d, v),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Pieces ───────────────────────────────────────────────────────────────

/// A view's glyph: its own icon, or the first letter of its title when it
/// has none, the way Home Assistant's view tabs fall back to the title.
class _Glyph extends StatelessWidget {
  const _Glyph({
    required this.icon,
    required this.title,
    required this.size,
    required this.color,
  });

  final String? icon;
  final String title;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final name = icon;
    if (name != null && MdiIcons.looksLikeIcon(name)) {
      return MdiIcon(
        name: name,
        size: size,
        color: color,
        fallback: Icons.dashboard_outlined,
      );
    }
    final letter = title.trim().isEmpty
        ? '?'
        : title.trim().characters.first.toUpperCase();
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: size * 0.82,
            height: 1,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _Mono extends StatelessWidget {
  const _Mono(this.text, {this.size = 11.5});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontFamily: 'monospace',
      fontSize: size,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// Text with the first match of [query] tinted.
class _Highlighted extends StatelessWidget {
  const _Highlighted(this.text, this.query, {required this.style});

  final String text;
  final String query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final i = query.isEmpty
        ? -1
        : text.toLowerCase().indexOf(query.toLowerCase());
    if (i < 0) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final tint = Theme.of(context).colorScheme.primaryContainer;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(
            text: text.substring(i, i + query.length),
            style: TextStyle(backgroundColor: tint),
          ),
          TextSpan(text: text.substring(i + query.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SubHeading extends StatelessWidget {
  const _SubHeading(this.text, {this.inset = false});

  final String text;
  final bool inset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(inset ? 12 : 0, 18, 0, 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _WholeNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              haText(
                context,
                'This dashboard builds its own views, so the kiosk opens it whole.',
              ),
              style: TextStyle(fontSize: 13, height: 1.4, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

String _viewTitle(BuildContext context, HaDashboard d, HaView? view) =>
    view?.title ?? (d.page ? d.title : haText(context, 'Whole dashboard'));

String? _viewIcon(HaDashboard d, HaView? view) =>
    view == null ? (d.icon ?? 'mdi:view-dashboard') : view.icon;

/// The rounded square a view's glyph sits in.
Widget _glyphSquare(
  BuildContext context,
  HaDashboard d,
  HaView? view, {
  required bool picked,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: picked ? scheme.surface : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: Alignment.center,
    child: _Glyph(
      icon: _viewIcon(d, view),
      title: _viewTitle(context, d, view),
      size: 22,
      color: picked ? scheme.primary : scheme.onSurfaceVariant,
    ),
  );
}

class _DashboardRow extends StatelessWidget {
  const _DashboardRow({
    required this.dashboard,
    required this.onTap,
    this.active = false,
    this.holds = false,
    this.chevron = false,
  });

  final HaDashboard dashboard;
  final VoidCallback onTap;
  final bool active;
  final bool holds;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = dashboard;
    final count = d.views.length;
    final sub = d.custom
        ? count == 1
              ? haText(context, '1 page')
              : l10n(context).dashboardPickerPageCount('$count')
        : d.app
        ? haText(context, 'Ingress page')
        : d.builtIn
        ? haText(context, 'Home Assistant page')
        : d.whole
        ? haText(context, 'Builds its own views')
        : count == 1
        ? haText(context, '1 view')
        : l10n(context).dashboardPickerViewCount('$count');
    final radius = BorderRadius.circular(Ks.radiusRow);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active ? scheme.surfaceContainerHighest : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                  ),
                  alignment: Alignment.center,
                  child: _Glyph(
                    icon: d.icon ?? 'mdi:view-dashboard',
                    title: d.label(context),
                    size: 20,
                    color: active ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.label(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (holds) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary,
                    ),
                  ),
                ],
                if (chevron) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewTile extends StatelessWidget {
  const _ViewTile({
    required this.dashboard,
    required this.view,
    required this.picked,
    required this.multiple,
    required this.onTap,
  });

  final HaDashboard dashboard;
  final HaView? view;
  final bool picked;
  final bool multiple;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);
    return Material(
      color: picked ? scheme.primaryContainer : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: picked
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _glyphSquare(context, dashboard, view, picked: picked),
                  const Spacer(),
                  Text(
                    _viewTitle(context, dashboard, view),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: picked ? FontWeight.w600 : FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _Mono(_shownRoute(view?.route ?? dashboard.path)),
                ],
              ),
            ),
            Positioned(
              top: multiple ? 4 : 12,
              right: multiple ? 4 : 12,
              child: multiple
                  ? Checkbox(value: picked, onChanged: (_) => onTap())
                  : picked
                  ? Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: scheme.onPrimary,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewRow extends StatelessWidget {
  const _ViewRow({
    required this.dashboard,
    required this.view,
    required this.picked,
    required this.onTap,
    this.multiple = false,
    this.withDashboard = false,
    this.query = '',
  });

  final HaDashboard dashboard;
  final HaView? view;
  final bool picked;
  final VoidCallback onTap;
  final bool multiple;
  final bool withDashboard;
  final String query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(Ks.radiusRow);
    final path = '/${dashboard.pathOf(view)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: picked ? scheme.primaryContainer : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (multiple) ...[
                  Checkbox(value: picked, onChanged: (_) => onTap()),
                  const SizedBox(width: 2),
                ],
                _glyphSquare(context, dashboard, view, picked: picked),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Highlighted(
                        _viewTitle(context, dashboard, view),
                        query,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: picked
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      withDashboard
                          ? Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: dashboard.label(context)),
                                  TextSpan(
                                    text: ' · ',
                                    style: TextStyle(color: scheme.outline),
                                  ),
                                  TextSpan(
                                    text: path,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            )
                          : _Mono(path),
                    ],
                  ),
                ),
                if (view?.subview ?? false) ...[
                  const SizedBox(width: 8),
                  _Tag(haText(context, 'Subview')),
                ],
                if (picked && !multiple) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check, size: 22, color: scheme.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHighest,
              ),
              child: Icon(icon, size: 34, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

/// Placeholder rows and tiles while the dashboards load, never a bare
/// spinner.
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    Widget row() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [bar(110, 12), const SizedBox(height: 6), bar(60, 10)],
          ),
        ],
      ),
    );
    final rows = Column(children: [for (var i = 0; i < 4; i++) row()]);
    if (!wide) return Align(alignment: Alignment.topLeft, child: rows);
    final outline = Theme.of(context).colorScheme.outlineVariant;
    Widget tile() => Container(
      height: 118,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const Spacer(),
          bar(70, 12),
          const SizedBox(height: 6),
          bar(90, 9),
        ],
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 236,
          child: Align(alignment: Alignment.topLeft, child: rows),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 14),
                child: bar(120, 12),
              ),
              Row(
                children: [
                  Expanded(child: tile()),
                  const SizedBox(width: 12),
                  Expanded(child: tile()),
                  const SizedBox(width: 12),
                  Expanded(child: tile()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── The field ────────────────────────────────────────────────────────────

/// A stored view at rest: the control box with the view's icon, the
/// dashboard muted, a slash and the view. Tapping opens the picker. Empty
/// reads Choose a view. A view gone from Home Assistant shows its path
/// with an error border. Before the dashboards load, the path stands in.
class DashboardField extends StatefulWidget {
  const DashboardField({
    super.key,
    required this.container,
    required this.value,
    required this.onTap,
  });

  final AppContainer container;

  /// The navigation path, "dashboard/view" or a bare dashboard.
  final String value;
  final VoidCallback onTap;

  /// Whether [value] names nothing in the loaded dashboards.
  static bool isMissing(String value) {
    final list = DashboardCatalog.current.value;
    return value.isNotEmpty &&
        list != null &&
        DashboardCatalog.match(list, value) == null;
  }

  @override
  State<DashboardField> createState() => _DashboardFieldState();
}

class _DashboardFieldState extends State<DashboardField> {
  @override
  void initState() {
    super.initState();
    if (DashboardCatalog.current.value == null) {
      DashboardCatalog.load(widget.container);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<HaDashboard>?>(
      valueListenable: DashboardCatalog.current,
      builder: (context, list, _) {
        final scheme = Theme.of(context).colorScheme;
        final value = widget.value;
        final match = list == null || value.isEmpty
            ? null
            : DashboardCatalog.match(list, value);
        final missing = value.isNotEmpty && list != null && match == null;
        Widget content;
        if (value.isEmpty) {
          content = Row(
            children: [
              Icon(Icons.grid_view, size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  haText(context, 'Choose a view'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        } else if (match == null) {
          content = Row(
            children: [
              missing
                  ? Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: scheme.error,
                    )
                  : Icon(
                      Icons.grid_view,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13.5,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          );
        } else {
          final d = match.dashboard;
          final v = match.view;
          content = Row(
            children: [
              _Glyph(
                icon: _viewIcon(d, v),
                title: _viewTitle(context, d, v),
                size: 20,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      // An app or a built-in page is its own page, so its
                      // name alone says it.
                      if (!d.page || v != null) ...[
                        TextSpan(
                          text: d.label(context),
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        TextSpan(
                          text: ' / ',
                          style: TextStyle(color: scheme.outline),
                        ),
                      ],
                      TextSpan(text: _viewTitle(context, d, v)),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: scheme.onSurface),
                ),
              ),
            ],
          );
        }
        return ControlBox(
          onTap: widget.onTap,
          borderColor: missing ? scheme.error : null,
          child: Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A settings row whose value is a dashboard view: the name, the
/// [DashboardField] (300 wide, or across the row on a tight pane) and the
/// description, with a line in error color when the stored view is gone.
class DashboardViewRow extends StatelessWidget {
  const DashboardViewRow({
    super.key,
    required this.container,
    required this.title,
    required this.value,
    required this.onPick,
    this.description,
  });

  final AppContainer container;
  final String title;
  final String? description;
  final String value;
  final ValueChanged<String> onPick;

  Future<void> _open(BuildContext context) async {
    final picked = await showDashboardPicker(
      context,
      container: container,
      title: title,
      selected: value,
    );
    if (picked != null && picked != value) onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<HaDashboard>?>(
      valueListenable: DashboardCatalog.current,
      builder: (context, _, _) {
        final error = Theme.of(context).colorScheme.error;
        final missing = DashboardField.isMissing(value);
        final field = DashboardField(
          container: container,
          value: value,
          onTap: () => _open(context),
        );
        final tight = tightPane(context);
        return SettingsRow(
          title: Text(title),
          stack: true,
          subtitle: description == null && !missing
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (missing)
                      Text(
                        haText(
                          context,
                          'This view is gone from Home Assistant. Choose another.',
                        ),
                        style: TextStyle(color: error),
                      ),
                    if (description != null) Text(description!),
                  ],
                ),
          trailing: tight ? field : SizedBox(width: 300, child: field),
        );
      },
    );
  }
}

/// One stored view as a list row (the rotation's picks): glyph, title,
/// then the dashboard and path. The bare path stands in until the
/// dashboards load, or when the view is gone. [leading] sits ahead of the
/// glyph: the drag handle of an orderable list.
class DashboardViewListRow extends StatelessWidget {
  const DashboardViewListRow({
    super.key,
    required this.value,
    this.leading,
    this.trailing,
  });

  final String value;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<HaDashboard>?>(
      valueListenable: DashboardCatalog.current,
      builder: (context, list, _) {
        final scheme = Theme.of(context).colorScheme;
        final match = list == null ? null : DashboardCatalog.match(list, value);
        final Widget lead;
        final Widget text;
        if (match == null) {
          lead = Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              list == null ? Icons.grid_view : Icons.warning_amber_rounded,
              size: 22,
              color: list == null ? scheme.onSurfaceVariant : scheme.error,
            ),
          );
          text = _Mono(_shownRoute(value), size: 13);
        } else {
          final d = match.dashboard;
          final v = match.view;
          lead = _glyphSquare(context, d, v, picked: false);
          text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _viewTitle(context, d, v),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: d.label(context)),
                    TextSpan(
                      text: ' · ',
                      style: TextStyle(color: scheme.outline),
                    ),
                    TextSpan(
                      text: '/$value',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(Ks.inset, 10, 8, 10),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              lead,
              const SizedBox(width: 14),
              Expanded(child: text),
              ?trailing,
            ],
          ),
        );
      },
    );
  }
}

/// A route or navigation path as the picker prints it: a path on Home
/// Assistant with its leading slash, a custom page on another server as its
/// URL.
String _shownRoute(String route) {
  if (isExternalCustomPagePath(route)) {
    return route.substring('$customPagesDashboardPath/'.length);
  }
  return route.startsWith('http://') || route.startsWith('https://')
      ? route
      : '/$route';
}
