import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_locales.dart';
import '../l10n/messages.dart';
import '../managers/plugins/plugin_directory.dart';
import '../managers/plugins/plugin_manager.dart';
import '../managers/settings/settings_manager.dart';
import 'kit.dart';
import 'plugin_settings.dart';
import 'settings_search.dart';
import 'toast.dart';

const pluginSubmitUrl =
    'https://github.com/jxlarrea/kiosk-satellite-plugins#submit-your-plugin';

/// Browse plugins: Community Plugins, searchable, with each plugin's
/// stars and downloads. Picking one runs the same preview
/// and trust dialog as Add plugin. Mirrors the remote admin (plugins.js,
/// renderDirectory).
class PluginDirectoryPanel extends StatefulWidget {
  const PluginDirectoryPanel({
    super.key,
    required this.plugins,
    required this.onOpen,
    this.settings,
  });
  final PluginManager plugins;
  final ValueChanged<String> onOpen;

  /// Where the chosen page size is kept. Without it the choice lasts while
  /// the page is open.
  final SettingsManager? settings;
  @override
  State<PluginDirectoryPanel> createState() => _PluginDirectoryPanelState();
}

class _PluginDirectoryPanelState extends State<PluginDirectoryPanel> {
  /// The page sizes Plugins per page offers, so a directory of thousands
  /// still builds a short page.
  static const pageSizes = [5, 10, 20, 50, 100];
  static const _pageSizeKey = 'plugin_directory_page_size';
  final _query = TextEditingController();
  int _page = 0;
  late int _pageSize =
      int.tryParse(widget.settings?.internal(_pageSizeKey) ?? '') ?? 10;
  String _sort = 'downloads';
  Map<String, Object?>? _data;
  Object? _error;
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    // A new search starts at its first page.
    _query.addListener(() => setState(() => _page = 0));
    unawaited(_load());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() => _loading = true);
    try {
      final data = await widget.plugins.directory.read(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _install(Map<String, Object?> entry, bool update) async {
    if (_busyId != null) return;
    setState(() => _busyId = entry['id'] as String);
    try {
      final preview = update
          ? await widget.plugins.checkUpdate(entry['id'] as String)
          : await widget.plugins.previewRepository(
              entry['repository'] as String,
            );
      if (!mounted) return;
      if (update && preview['updateAvailable'] != true) {
        showToast(
          context,
          title: '${entry['name']}',
          message: pluginText(context, 'No updates available.'),
        );
        return;
      }
      if (await showPluginPreview(context, preview)) {
        await widget.plugins.installRepository(
          preview['previewId'] as String,
          trusted: true,
        );
      }
    } catch (error) {
      if (mounted) {
        showToast(
          context,
          title: pluginText(context, 'Plugin Manager'),
          message: pluginError(context, '$error'),
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  /// The orders Sort by offers, the same as kiosksatellite.com's.
  static const sorts = {
    'downloads': 'Most downloads',
    'stars': 'Most stars',
    'updated': 'Recently updated',
    'newest': 'Newest',
    'name': 'Name',
  };

  static int _byName(Map a, Map b) =>
      '${a['name']}'.toLowerCase().compareTo('${b['name']}'.toLowerCase());

  static int _count(Map a, Map b, String key) =>
      ((b[key] as int?) ?? -1).compareTo((a[key] as int?) ?? -1);

  static int _date(Map a, Map b, String key) =>
      '${b[key] ?? ''}'.compareTo('${a[key] ?? ''}');

  static int Function(Map, Map) comparator(String sort) => switch (sort) {
    'stars' => (a, b) => _count(a, b, 'stars').ifZero(() => _byName(a, b)),
    'updated' => (a, b) => _date(a, b, 'released').ifZero(() => _byName(a, b)),
    'newest' => (a, b) => _date(
      a,
      b,
      'added',
    ).ifZero(() => _date(a, b, 'released')).ifZero(() => _byName(a, b)),
    'name' => _byName,
    _ => (a, b) => _count(
      a,
      b,
      'downloads',
    ).ifZero(() => _count(a, b, 'stars')).ifZero(() => _byName(a, b)),
  };

  List<Map<String, Object?>> _shown() {
    final words = _query.text.toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    final plugins = [
      for (final p in (_data?['plugins'] as List? ?? const []))
        p as Map<String, Object?>,
    ];
    return plugins.where((p) {
      final text =
          '${p['name']} ${p['description']} ${p['author']} ${p['owner'] ?? ''} ${p['id']}'
              .toLowerCase();
      return words.every(text.contains);
    }).toList()..sort(comparator(_sort));
  }

  void _turn(int page) {
    setState(() => _page = page);
    // A new page opens at the top of the page, like opening it again.
    final position = Scrollable.maybeOf(context)?.position;
    if (position != null && position.pixels > 0) {
      position.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  /// Search, sort and page size on one line, or search over sort and page
  /// size on a narrow pane.
  Widget _toolbar(BuildContext context) {
    final number = NumberFormat.decimalPattern(appLocaleName(context));
    InputDecoration box({required Widget icon, String? hint}) =>
        InputDecoration(
          prefixIcon: icon,
          // The icon takes its own width and no more, so the picked value
          // keeps the room.
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        );
    final search = TextField(
      controller: _query,
      decoration: box(
        icon: const Icon(Icons.search_rounded),
        hint: pluginText(context, 'Search plugins'),
      ),
    );
    final sort = Tooltip(
      message: pluginText(context, 'Sort by'),
      child: DropdownButtonFormField<String>(
        initialValue: _sort,
        isExpanded: true,
        decoration: box(icon: const Icon(Icons.sort_rounded)),
        items: [
          for (final entry in sorts.entries)
            DropdownMenuItem(
              value: entry.key,
              child: Text(
                pluginText(context, entry.value),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        // A new order starts at its first page.
        onChanged: (value) => setState(() {
          _sort = value ?? 'downloads';
          _page = 0;
        }),
      ),
    );
    final size = Tooltip(
      message: pluginText(context, 'Plugins per page'),
      child: DropdownButtonFormField<int>(
        initialValue: pageSizes.contains(_pageSize) ? _pageSize : 10,
        isExpanded: true,
        decoration: box(icon: const Icon(Icons.view_list_rounded)),
        items: [
          for (final value in pageSizes)
            DropdownMenuItem(
              value: value,
              child: Text(
                l10n(context).pluginCountPerPage(number.format(value)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (value) {
          setState(() {
            _pageSize = value ?? 10;
            _page = 0;
          });
          widget.settings?.setInternal(_pageSizeKey, '$_pageSize');
        },
      ),
    );
    final refresh = IconButton(
      tooltip: pluginText(context, 'Refresh'),
      onPressed: _loading ? null : () => _load(refresh: true),
      icon: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded),
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 600
          ? Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 12),
                SizedBox(width: 220, child: sort),
                const SizedBox(width: 12),
                SizedBox(width: 196, child: size),
                const SizedBox(width: 4),
                refresh,
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: 4),
                    refresh,
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  // Lines up with the search field, not the refresh button.
                  padding: const EdgeInsets.only(right: 52),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: sort),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: size),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = _data?['error'] ?? _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: _toolbar(context),
            ),
            if (error != null) WarnRow(pluginError(context, '$error')),
          ],
        ),
        if (_data != null)
          ValueListenableBuilder<List<Map<String, Object?>>>(
            valueListenable: widget.plugins.installed,
            builder: (context, installed, _) {
              final shown = _shown();
              final byId = {for (final p in installed) p['id']: p};
              final size = pageSizes.contains(_pageSize) ? _pageSize : 10;
              final pages = (shown.length / size).ceil();
              final page = _page.clamp(0, pages == 0 ? 0 : pages - 1);
              final rows = shown.skip(page * size).take(size);
              return SettingsCard(
                children: [
                  if (shown.isEmpty)
                    HintRow(
                      pluginText(
                        context,
                        _query.text.trim().isEmpty
                            ? 'Community Plugins has no plugins yet.'
                            : 'No plugins match your search.',
                      ),
                    ),
                  for (final entry in rows)
                    _DirectoryRow(
                      entry: entry,
                      status: PluginDirectory.installStatus(
                        entry,
                        byId[entry['id']],
                        appVersion: widget.plugins.appVersion(),
                      ),
                      busy: _busyId == entry['id'],
                      enabled: _busyId == null,
                      onInstall: (update) => _install(entry, update),
                      onOpen: () => widget.onOpen(entry['id'] as String),
                    ),
                  if (pages > 1)
                    _Pager(page: page, pages: pages, onTurn: _turn),
                ],
              );
            },
          ),
        SettingsCard(
          children: [
            SearchLandingTarget(
              id: 'x:plugins:submit',
              child: SettingsRow(
                title: Text(pluginText(context, 'Submit your plugin')),
                subtitle: Text(
                  pluginText(context, 'List your plugin in Community Plugins.'),
                ),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => launchUrl(
                  Uri.parse(pluginSubmitUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A plugin's icon from Community Plugins, or the generic plugin icon.
class PluginIcon extends StatelessWidget {
  const PluginIcon({super.key, this.url, this.size = 40});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final generic = Container(
      width: size,
      height: size,
      color: theme.colorScheme.primary.withValues(alpha: 0.14),
      alignment: Alignment.center,
      child: Icon(
        Icons.extension_rounded,
        size: size * 0.55,
        color: theme.colorScheme.primary,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: url == null
          ? generic
          : Image.network(
              url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => generic,
            ),
    );
  }
}

/// Previous and next page buttons around "Page 2 of 31".
class _Pager extends StatelessWidget {
  const _Pager({required this.page, required this.pages, required this.onTurn});
  final int page;
  final int pages;
  final ValueChanged<int> onTurn;

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat.decimalPattern(appLocaleName(context));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: pluginText(context, 'Previous page'),
            onPressed: page > 0 ? () => onTurn(page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              l10n(context).pluginPageOfPages(
                number.format(page + 1),
                number.format(pages),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            tooltip: pluginText(context, 'Next page'),
            onPressed: page < pages - 1 ? () => onTurn(page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _DirectoryRow extends StatelessWidget {
  const _DirectoryRow({
    required this.entry,
    required this.status,
    required this.busy,
    required this.enabled,
    required this.onInstall,
    required this.onOpen,
  });
  final Map<String, Object?> entry;
  final Map<String, Object?> status;
  final bool busy;
  final bool enabled;
  final ValueChanged<bool> onInstall;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final number = NumberFormat.compact(locale: appLocaleName(context));
    final installed = status['installed'] == true;
    final update = status['updateAvailable'] == true;
    final needs = status['needsAppVersion'] as String?;
    final icon = entry['icon'] as String?;
    Widget stat(IconData icon, String label, int value) => Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(number.format(value), style: muted),
        ],
      ),
    );
    final Widget trailing = busy
        ? const SizedBox(
            width: 24,
            height: 24,
            child: Padding(
              padding: EdgeInsets.all(3),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : update
        ? FilledButton.tonal(
            onPressed: enabled ? () => onInstall(true) : null,
            child: Text(pluginText(context, 'Update')),
          )
        : installed
        ? Text(
            pluginText(context, 'Installed'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          )
        : needs != null
        ? const SizedBox.shrink()
        : IconButton(
            tooltip: pluginText(context, 'Install'),
            onPressed: enabled ? () => onInstall(false) : null,
            icon: const Icon(Icons.add_rounded),
          );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${entry['name']}', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 2),
        // Author, version, stars and downloads share a line.
        Wrap(
          spacing: 14,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${entry['author']} · ${entry['version']}', style: muted),
            stat(
              Icons.star_outline_rounded,
              pluginText(context, 'Stars'),
              entry['stars'] as int? ?? 0,
            ),
            stat(
              Icons.download_rounded,
              pluginText(context, 'Downloads'),
              entry['downloads'] as int? ?? 0,
            ),
            if (entry['installs'] is int)
              stat(
                Icons.devices_rounded,
                pluginText(context, 'Active installs'),
                entry['installs'] as int,
              ),
          ],
        ),
        if ('${entry['description']}'.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${entry['description']}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        if (needs != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l10n(context).pluginNeedsAppVersion(needs),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
    // The icon sits at the top of the row and the button in its middle,
    // the way the remote admin lays these rows out.
    return InkWell(
      onTap: enabled
          ? (installed && !update ? onOpen : () => onInstall(update))
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: PluginIcon(url: icon),
              ),
              const SizedBox(width: 16),
              Expanded(child: body),
              const SizedBox(width: 12),
              Center(child: trailing),
            ],
          ),
        ),
      ),
    );
  }
}

extension on int {
  /// This comparison, or [next] when it is a tie.
  int ifZero(int Function() next) => this == 0 ? next() : this;
}
