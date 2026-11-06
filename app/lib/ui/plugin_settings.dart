import '../l10n/messages.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_container.dart';
import '../managers/plugins/plugin_manager.dart';
import '../core/command_registry.dart';
import 'dashboard_view_picker.dart';
import 'entity_picker.dart';
import 'kit.dart';
import 'plugin_directory.dart';
import 'plugin_list_setting.dart';
import 'plugin_chart.dart';
import 'plugin_readings.dart';
import 'plugin_setup.dart';
import 'plugin_shizuku.dart';
import 'theme.dart';
import 'color_picker.dart';
import 'toast.dart';
import 'settings_search.dart';

const pluginIntro =
    'Plugins add additional community developed features to Kiosk Satellite.';

/// The Plugin Manager page that lists Community Plugins. Plugin IDs never
/// hold an underscore, so it cannot clash with a plugin's own page.
const pluginDirectoryPage = '_browse';

const pluginTrustNotice =
    'Plugins run code inside Kiosk Satellite and can access '
    'app data and granted Android permissions. A faulty or malicious plugin can '
    'expose private information or stop the app from working. Only install plugins from authors you trust.';

String _pluginEntryHint(Map<String, Object?> plugin) {
  final source = plugin['source'];
  final repository = source is Map ? '${source['repository'] ?? ''}' : '';
  final name = RegExp(
    r'^https://github\.com/([^/]+/[^/]+?)(?:\.git)?/?$',
    caseSensitive: false,
  ).firstMatch(repository)?.group(1);
  return '${name ?? 'ZIP'} · ${plugin['version']}';
}

class PluginReadme extends StatelessWidget {
  const PluginReadme({super.key, required this.source});
  final Map source;
  Uri? _url(String value, {bool image = false}) {
    final base = Uri.tryParse('${source['readmeBaseUrl'] ?? ''}');
    final uri = base?.resolve(value);
    if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty) {
      return null;
    }
    if (!image && uri.host == 'raw.githubusercontent.com') {
      final parts = uri.pathSegments;
      if (parts.length >= 3) {
        return Uri.https(
          'github.com',
          '/${parts[0]}/${parts[1]}/blob/${parts.skip(2).join('/')}',
          uri.queryParameters,
        ).replace(fragment: uri.fragment);
      }
    }
    return uri;
  }

  @override
  Widget build(BuildContext context) => MarkdownBody(
    data: '${source['readme'] ?? ''}',
    selectable: true,
    onTapLink: (_, href, _) async {
      final uri = _url(href ?? '');
      if (uri == null) return;
      var opened = false;
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pluginText(context, 'Could not open this link.')),
          ),
        );
      }
    },
    imageBuilder: (uri, title, alt) {
      final target = _url(uri.toString(), image: true);
      return target == null
          ? Text(alt ?? '')
          : Image.network(
              target.toString(),
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  Text(alt ?? pluginText(context, 'Image unavailable')),
            );
    },
  );
}

/// The review before an install or update: who made the plugin and what it
/// is on a header band, the README under it and the trust notice on a
/// footer band above the buttons. True once the person chooses to trust
/// and install. Mirrors the remote admin (plugins.js, confirmPreview).
Future<bool> showPluginPreview(
  BuildContext context,
  Map<String, Object?> preview,
) async {
  final install = await showDialog<bool>(
    context: context,
    builder: (context) => _PluginReviewDialog(preview: preview),
  );
  return install == true;
}

class _PluginReviewDialog extends StatelessWidget {
  const _PluginReviewDialog({required this.preview});
  final Map<String, Object?> preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final manifest = preview['manifest'] as Map;
    final isUpdate = preview.containsKey('installedVersion');
    final compatible = preview['compatible'] == true;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final chips = <Widget>[
      _ReviewChip(
        icon: Icons.sell_outlined,
        tooltip: pluginText(context, 'Version'),
        text: isUpdate
            ? '${preview['installedVersion']} → ${manifest['version']}'
            : '${manifest['version']}',
      ),
      _ReviewChip(
        icon: Icons.balance_rounded,
        tooltip: pluginText(context, 'License'),
        text: '${manifest['license']}',
      ),
      if (preview['listed'] == true)
        _ReviewChip(
          icon: Icons.verified_outlined,
          text: pluginText(context, 'Listed in Community Plugins'),
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
        )
      else if (preview['listed'] == false)
        _ReviewChip(
          icon: Icons.warning_amber_rounded,
          text: pluginText(context, 'Not listed in Community Plugins'),
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
        ),
    ];
    // A phone gives the README the room: the header scrolls away with it
    // and only the footer with the buttons stays put.
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final Widget header = Container(
      color: scheme.surfaceContainerHigh,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PluginIcon(url: preview['icon'] as String?, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${manifest['name']}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n(context).pluginByAuthor('${manifest['author']}'),
                      style: muted,
                    ),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 6, children: chips),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 960,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!narrow) header,
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (narrow) header,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'README',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          PluginReadme(source: preview),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!compatible) ...[
                    _ReviewNotice(
                      icon: Icons.error_outline,
                      text: pluginError(
                        context,
                        '${preview['compatibilityError']}',
                      ),
                      background: scheme.errorContainer,
                      foreground: scheme.onErrorContainer,
                    ),
                    const SizedBox(height: 10),
                  ],
                  _ReviewNotice(
                    icon: Icons.warning_amber_rounded,
                    text: pluginText(context, pluginTrustNotice),
                    background: scheme.tertiaryContainer,
                    foreground: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(height: 16),
                  // The buttons stack when a long label does not fit beside
                  // Cancel.
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    overflowAlignment: OverflowBarAlignment.end,
                    spacing: 8,
                    overflowSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(pluginText(context, 'Cancel')),
                      ),
                      FilledButton(
                        onPressed: compatible
                            ? () => Navigator.pop(context, true)
                            : null,
                        child: Text(
                          isUpdate
                              ? pluginText(context, 'Trust and update')
                              : pluginText(context, 'Trust and install'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A fact about the plugin on the review's header band.
class _ReviewChip extends StatelessWidget {
  const _ReviewChip({
    required this.icon,
    required this.text,
    this.tooltip,
    this.background,
    this.foreground,
  });
  final IconData icon;
  final String text;
  final String? tooltip;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = foreground ?? scheme.onSurfaceVariant;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: background == null
            ? Border.all(color: scheme.outlineVariant)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: ink),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

/// A notice on the review's footer band: a tinted panel, edge to edge.
class _ReviewNotice extends StatelessWidget {
  const _ReviewNotice({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });
  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 13,
      height: 1.4,
      color: foreground,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

class PluginSettingsPanel extends StatefulWidget {
  const PluginSettingsPanel({
    super.key,
    required this.plugins,
    required this.onOpen,
  });
  final PluginManager plugins;
  final ValueChanged<String> onOpen;
  @override
  State<PluginSettingsPanel> createState() => _PluginSettingsPanelState();
}

class _PluginSettingsPanelState extends State<PluginSettingsPanel> {
  final _url = TextEditingController();
  bool _busy = false;
  String? _busyId;
  @override
  void initState() {
    super.initState();
    unawaited(_run(() => widget.plugins.refresh()));
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Object?> Function() action, {String? id}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _busyId = id;
    });
    try {
      await action();
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
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preview() async {
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pluginText(context, 'Add plugin')),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: _url,
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: pluginText(context, 'Repository URL'),
              hintText: 'https://github.com/owner/plugin',
              helperText: pluginText(
                context,
                "Make sure you trust the plugin's author and its code before installing it.",
              ),
            ),
            onSubmitted: (value) => Navigator.pop(context, value.trim()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(pluginText(context, 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _url.text.trim()),
            child: Text(pluginText(context, 'Preview')),
          ),
        ],
      ),
    );
    if (url == null) return;
    final preview = await widget.plugins.previewRepository(url);
    await _confirmPreview(preview);
  }

  Future<void> _checkUpdate(Map<String, Object?> plugin) async {
    final preview = await widget.plugins.checkUpdate(plugin['id'] as String);
    if (!mounted) return;
    if (preview['updateAvailable'] != true) {
      showToast(
        context,
        title: '${plugin['name']}',
        message: pluginText(context, 'No updates available.'),
      );
      return;
    }
    await _confirmPreview(preview);
  }

  Future<void> _confirmPreview(Map<String, Object?> preview) async {
    if (!mounted) return;
    if (await showPluginPreview(context, preview)) {
      await widget.plugins.installRepository(
        preview['previewId'] as String,
        trusted: true,
      );
      if (mounted) _url.clear();
    }
  }

  Future<void> _installZip() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withReadStream: true,
    );
    if (picked == null || !mounted) return;
    final file = picked.files.single;
    if (file.size <= 0 || file.size > PluginManager.maxZipBytes) {
      throw FormatException(
        pluginText(context, 'Plugin ZIP must be at most 4 MB'),
      );
    }
    final trusted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pluginText(context, 'Install from ZIP')),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HintRow(file.name),
                WarnRow(pluginText(context, pluginTrustNotice)),
                HintRow(
                  pluginText(
                    context,
                    'New plugins start disabled. Updates preserve the enabled state and automatically restart running plugins.',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(pluginText(context, 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(pluginText(context, 'Trust and install')),
          ),
        ],
      ),
    );
    if (trusted != true || !mounted) return;
    final stream = file.readStream;
    if (stream == null) {
      throw StateError(pluginText(context, 'Could not read the selected ZIP'));
    }
    await widget.plugins.installZipStream(stream, trusted: true);
  }

  Future<void> _remove(Map<String, Object?> plugin) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n(context).pluginUninstallName((plugin['name']).toString()),
        ),
        content: Text(
          pluginText(context, 'This removes the plugin and its settings.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(pluginText(context, 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(pluginText(context, 'Uninstall')),
          ),
        ],
      ),
    );
    if (remove == true) {
      await widget.plugins.update('remove', {'id': plugin['id']});
    }
  }

  Future<void> _showInfo(Map<String, Object?> plugin) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${plugin['name']}'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: plugin['source'] is Map
              ? PluginReadme(source: plugin['source'] as Map)
              : Text(
                  pluginText(
                    context,
                    'This plugin was installed from ZIP and has no repository README.',
                  ),
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(pluginText(context, 'Close')),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: widget.plugins.enabled,
    builder: (context, enabled, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          children: [
            SearchLandingTarget(
              id: 'x:plugins:master',
              child: SettingsRow(
                title: Text(pluginText(context, 'Enable Plugins')),
                subtitle: Text(pluginText(context, pluginIntro)),
                trailing: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: _busy && _busyId == '_master' ? 0 : 1,
                      child: Switch(
                        value: enabled,
                        onChanged: _busy
                            ? null
                            : (value) => _run(
                                () => widget.plugins.setEnabled(value),
                                id: '_master',
                              ),
                      ),
                    ),
                    if (_busy && _busyId == '_master') const _PluginProgress(),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (enabled) ...[
          SettingsCard(
            children: [
              SearchLandingTarget(
                id: 'x:plugins:browse',
                child: SettingsRow(
                  leading: const Icon(Icons.extension_rounded),
                  title: Text(pluginText(context, 'Browse plugins')),
                  subtitle: Text(
                    pluginText(context, 'Find plugins made by the community'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_busy,
                  onTap: () => widget.onOpen(pluginDirectoryPage),
                ),
              ),
            ],
          ),
          SettingsCard(
            children: [
              SearchLandingTarget(
                id: 'x:plugins:add',
                child: SettingsRow(
                  title: Text(pluginText(context, 'Add plugin')),
                  subtitle: Text(
                    pluginText(context, 'Install from a GitHub repository'),
                  ),
                  trailing: _busy && _busyId == null
                      ? const _PluginProgress()
                      : const Icon(Icons.add_rounded),
                  enabled: !_busy,
                  onTap: () => _run(_preview),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: WarnRow(pluginText(context, pluginTrustNotice)),
              ),
            ],
          ),
          SectionHeading(pluginText(context, 'Installed plugins')),
          ValueListenableBuilder<String>(
            valueListenable: widget.plugins.status,
            builder: (_, status, _) => status.isEmpty
                ? const SizedBox.shrink()
                : WarnRow(pluginError(context, status)),
          ),
          ListenableBuilder(
            listenable: Listenable.merge([
              widget.plugins.installed,
              widget.plugins.updates,
            ]),
            builder: (context, _) => SettingsCard(
              children: [
                if (widget.plugins.installed.value.isEmpty)
                  HintRow(
                    pluginText(
                      context,
                      'No plugins installed. Add a repository to get started.',
                    ),
                  ),
                for (final plugin in widget.plugins.installed.value)
                  // A phone gives the name and repository the row beside
                  // the switch, and the update, about and uninstall
                  // buttons a line of their own under them.
                  LayoutBuilder(
                    builder: (context, box) {
                      final narrow = box.maxWidth < 520;
                      final actions = [
                        IconButton(
                          tooltip: l10n(context).pluginCheckForUpdatesForName(
                            (plugin['name']).toString(),
                          ),
                          icon: _busy && _busyId == '${plugin['id']}:update'
                              ? const _PluginProgress()
                              : const Icon(Icons.update_rounded),
                          // A fleet leader keeps a synced plugin in step.
                          onPressed:
                              _busy ||
                                  plugin['source'] is! Map ||
                                  widget.plugins.fleetManaged('${plugin['id']}')
                              ? null
                              : () => _run(
                                  () => _checkUpdate(plugin),
                                  id: '${plugin['id']}:update',
                                ),
                        ),
                        IconButton(
                          tooltip: l10n(
                            context,
                          ).pluginAboutName((plugin['name']).toString()),
                          icon: const Icon(Icons.info_outline_rounded),
                          onPressed: _busy ? null : () => _showInfo(plugin),
                        ),
                        IconButton(
                          tooltip: l10n(context).pluginUninstallNameDetail(
                            (plugin['name']).toString(),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => _remove(plugin),
                                  id: plugin['id'] as String,
                                ),
                        ),
                      ];
                      return SettingsRow(
                        leading: Switch(
                          value: plugin['enabled'] == true,
                          onChanged: _busy || !enabled
                              ? null
                              : (value) => _run(
                                  () => widget.plugins.update(
                                    value ? 'enable' : 'disable',
                                    {'id': plugin['id']},
                                  ),
                                  id: plugin['id'] as String,
                                ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${plugin['name']}'),
                            Text(
                              [
                                _pluginEntryHint(plugin),
                                if (widget.plugins.updates.value[plugin['id']]
                                    case final version?)
                                  l10n(context).overviewNewVersion(version),
                              ].join(' · '),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            if (narrow)
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: actions,
                                ),
                              ),
                          ],
                        ),
                        onTap: _busy
                            ? null
                            : () => widget.onOpen(plugin['id'] as String),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!narrow) ...actions,
                            _busy && _busyId == plugin['id']
                                ? const _PluginProgress()
                                : const Icon(Icons.chevron_right),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          SectionHeading(pluginText(context, 'Developer Tools')),
          SettingsCard(
            children: [
              SearchLandingTarget(
                id: 'x:plugins:zip',
                child: SettingsRow(
                  title: Text(pluginText(context, 'Install from ZIP')),
                  subtitle: Text(
                    pluginText(
                      context,
                      'For developers only: test a local build',
                    ),
                  ),
                  trailing: _busy && _busyId == '_zip'
                      ? const _PluginProgress()
                      : const Icon(Icons.upload_file_rounded),
                  enabled: !_busy,
                  onTap: () => _run(_installZip, id: '_zip'),
                ),
              ),
              SearchLandingTarget(
                id: 'x:plugins:create',
                child: SettingsRow(
                  title: Text(pluginText(context, 'Create a plugin')),
                  subtitle: Text(
                    pluginText(
                      context,
                      'Learn how to create plugins with the Hello World template and documentation.',
                    ),
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  enabled: !_busy,
                  onTap: () => _run(() async {
                    final opened = await launchUrl(
                      Uri.parse(
                        'https://github.com/jxlarrea/kiosk-satellite-plugins/blob/main/docs/getting-started.md',
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                    if (!opened) {
                      throw StateError('Could not open this link.');
                    }
                    return opened;
                  }),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _PluginProgress extends StatelessWidget {
  const _PluginProgress();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 24,
    height: 24,
    child: Padding(
      padding: EdgeInsets.all(3),
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

class PluginDetailPanel extends StatefulWidget {
  const PluginDetailPanel({
    super.key,
    required this.plugins,
    required this.id,
    this.onDisabled,
    this.container,
  });
  final PluginManager plugins;
  final String id;
  final VoidCallback? onDisabled;

  /// For the dashboard and camera view pickers. Without it they stay
  /// read-only.
  final AppContainer? container;
  @override
  State<PluginDetailPanel> createState() => _PluginDetailPanelState();
}

class _PluginDetailPanelState extends State<PluginDetailPanel> {
  bool _busy = false;
  // Off while a full page covers this one. Dialogs and pickers opened from
  // here leave it on, so the page still counts as open under them.
  ValueListenable<TickerModeData>? _shown;
  @override
  void initState() {
    super.initState();
    widget.plugins.enabled.addListener(_masterChanged);
    _masterChanged();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown = TickerMode.getValuesNotifier(context);
    if (shown == _shown) return;
    _shown?.removeListener(_pageShown);
    _shown = shown..addListener(_pageShown);
    _pageShown();
  }

  @override
  void didUpdateWidget(covariant PluginDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id == widget.id) return;
    oldWidget.plugins.settingsPageViewer(oldWidget.id, this, open: false);
    _pageShown();
  }

  /// Tells the plugin when its settings page opens and closes.
  void _pageShown() => widget.plugins.settingsPageViewer(
    widget.id,
    this,
    open: _shown!.value.enabled,
  );

  void _masterChanged() {
    if (widget.plugins.enabled.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.plugins.enabled.value) widget.onDisabled?.call();
    });
  }

  @override
  void dispose() {
    widget.plugins.enabled.removeListener(_masterChanged);
    _shown?.removeListener(_pageShown);
    widget.plugins.settingsPageViewer(widget.id, this, open: false);
    super.dispose();
  }

  Future<void> _run(String method, Map<String, Object?> args) async {
    if (_busy) return;
    setState(() {
      _busy = true;
    });
    try {
      await widget.plugins.update(method, args);
    } catch (error) {
      if (mounted) {
        showToast(
          context,
          title: pluginText(context, 'Plugin'),
          message: pluginError(context, '$error'),
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.plugins.installed,
      widget.plugins.enabled,
    ]),
    builder: (context, _) {
      if (!widget.plugins.enabled.value) return const SizedBox.shrink();
      final plugins = widget.plugins.installed.value;
      final plugin = plugins.where((p) => p['id'] == widget.id).firstOrNull;
      if (plugin == null) {
        return Text(pluginText(context, 'This plugin is no longer installed.'));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsCard(
            children: [
              SearchLandingTarget(
                id: 'plugin:${widget.id}:intro',
                child: IntroRow(
                  icon: _InstalledPluginIcon(
                    plugins: widget.plugins,
                    id: widget.id,
                  ),
                  title: '${plugin['name'] ?? widget.id}',
                  subtitle: '${plugin['description'] ?? ''}',
                ),
              ),
              if ('${plugin['status'] ?? ''}'.isNotEmpty)
                plugin['statusError'] == true
                    ? WarnRow('${plugin['status']}')
                    : HintRow('${plugin['status']}'),
              if (!widget.plugins.enabled.value)
                HintRow(
                  pluginText(context, 'Enable Plugins to run this plugin.'),
                )
              else if (plugin['enabled'] != true)
                HintRow(
                  pluginText(
                    context,
                    'Enable this plugin from its entry row to run it.',
                  ),
                ),
              if ('${plugin['error'] ?? ''}'.isNotEmpty)
                WarnRow(pluginError(context, '${plugin['error']}')),
            ],
          ),
          if ((plugin['capabilities'] as List? ?? const []).contains('shizuku'))
            SearchLandingTarget(
              id: 'plugin:${widget.id}:shizuku',
              child: PluginShizukuPanel(plugins: widget.plugins, id: widget.id),
            ),
          _PluginSettings(
            key: ValueKey(widget.id),
            plugin: plugin,
            commands: widget.plugins.commands,
            container: widget.container,
            plugins: widget.plugins,
            busy: _busy,
            run: _run,
          ),
        ],
      );
    },
  );
}

class _PluginSettings extends StatefulWidget {
  const _PluginSettings({
    super.key,
    required this.plugin,
    required this.commands,
    required this.plugins,
    required this.busy,
    required this.run,
    this.container,
  });
  final Map<String, Object?> plugin;
  final CommandRegistry commands;
  final AppContainer? container;
  final PluginManager plugins;
  final bool busy;
  final Future<void> Function(String, Map<String, Object?>) run;
  @override
  State<_PluginSettings> createState() => _PluginSettingsState();
}

class _PluginSettingsState extends State<_PluginSettings> {
  late Map<String, Object?> _values;
  bool _saving = false;
  bool get _busy => widget.busy || _saving;
  late final _prompts = PluginSetupPrompts(
    widget.plugins,
    '${widget.plugin['id']}',
  );
  @override
  void initState() {
    super.initState();
    _reset();
    // A question can be waiting already, and a dialog needs a built page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prompts.attach(context);
    });
  }

  @override
  void dispose() {
    _prompts.detach();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PluginSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plugin['id'] != widget.plugin['id'] ||
        jsonEncode(oldWidget.plugin['values']) !=
            jsonEncode(widget.plugin['values'])) {
      _reset();
    }
  }

  void _reset() => _values = Map<String, Object?>.from(
    widget.plugin['values'] as Map? ?? const {},
  );
  String _actionSummary(String command) {
    final options = (widget.plugin['actionOptions'] as Map?)?[command] as Map?;
    return [
      pluginText(context, 'Gestures'),
      if (options?['drawer'] == true) pluginText(context, 'Kiosk drawer'),
      if (options?['homeAssistant'] == true)
        pluginText(context, 'Home Assistant'),
    ].join(' · ');
  }

  Future<void> _saveValue(String key, Object? value) async {
    if (_busy) return;
    setState(() {
      _saving = true;
      _values[key] = value;
    });
    try {
      // Only this setting, so a value the plugin saved meanwhile stays.
      await widget.run('configure', {
        'id': widget.plugin['id'],
        'values': {key: value},
        'patch': true,
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _reset();
        });
      }
    }
  }

  Future<void> _editText(Map raw) async {
    final key = '${raw['key']}';
    final secret = raw['type'] == 'secret';
    // A secret is only ever replaced. Saving an empty field clears it.
    // The eye shows what is being typed, never the saved value, so it
    // appears only once there is text.
    var draft = secret ? '' : '${_values[key] ?? raw['default']}';
    var obscured = secret;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${raw['title']}'),
          content: SizedBox(
            width: 420,
            child: TextFormField(
              initialValue: draft,
              obscureText: obscured,
              autofocus: true,
              maxLength: 512,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: raw['description'] as String?,
                suffixIcon: secret && draft.isNotEmpty
                    ? IconButton(
                        tooltip: pluginText(
                          context,
                          obscured ? 'Show password' : 'Hide password',
                        ),
                        icon: Icon(
                          obscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscured = !obscured),
                      )
                    : null,
              ),
              onChanged: (value) => setDialogState(() {
                draft = value;
                if (value.isEmpty) obscured = secret;
              }),
              onFieldSubmitted: (value) => Navigator.pop(context, value),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(pluginText(context, 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, draft),
              child: Text(pluginText(context, 'Save')),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted && !_busy) {
      await _saveValue(key, result);
    }
  }

  /// A typed number. Save waits until the text is a value the setting
  /// takes, and the reason shows under the field until then.
  Future<void> _editNumber(Map raw) async {
    final key = '${raw['key']}';
    var draft = '${_values[key] ?? raw['default']}';
    final result = await showDialog<num>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final error = pluginNumberError(context, raw, draft);
          void save() => Navigator.pop(context, pluginNumberValue(raw, draft));
          return AlertDialog(
            title: Text('${raw['title']}'),
            content: SizedBox(
              width: 420,
              child: TextFormField(
                initialValue: draft,
                autofocus: true,
                keyboardType: pluginNumberKeyboard(raw),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  helperText: raw['description'] as String?,
                  helperMaxLines: 3,
                  suffixText: raw['unit']?.toString(),
                  errorText: error,
                ),
                onChanged: (value) => setDialogState(() => draft = value),
                onFieldSubmitted: (_) {
                  if (pluginNumberError(context, raw, draft) == null) save();
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(pluginText(context, 'Cancel')),
              ),
              FilledButton(
                onPressed: error == null ? save : null,
                child: Text(pluginText(context, 'Save')),
              ),
            ],
          );
        },
      ),
    );
    if (result != null && mounted && !_busy) {
      await _saveValue(key, result);
    }
  }

  PluginFieldServices get _services => PluginFieldServices(
    commands: widget.commands,
    container: widget.container,
    plugins: widget.plugins,
    pluginId: '${widget.plugin['id']}',
    running: widget.plugin['running'] == true,
  );

  Widget _settingRow(Map raw, {bool alone = false}) {
    final key = '${raw['key']}';
    final value = _values[key] ?? raw['default'];
    switch (raw['type']) {
      case 'list':
        return PluginListSetting(
          setting: raw,
          rows: (value as List? ?? const []).whereType<Map>().toList(),
          services: _services,
          enabled: !_busy,
          showTitle: !alone,
          onChanged: (rows) => _saveValue(key, rows),
        );
      case 'icon':
        return SettingsRow(
          title: Text('${raw['title']}'),
          subtitle: raw['description'] == null
              ? null
              : Text('${raw['description']}'),
          stack: true,
          trailing: SizedBox(
            width: tightPane(context) ? null : 300,
            child: PluginIconBox(
              value: '$value',
              onTap: _busy
                  ? null
                  : () async {
                      final picked = await pickPluginIcon(
                        context,
                        title: '${raw['title']}',
                        value: '$value',
                      );
                      if (picked != null && mounted && !_busy) {
                        await _saveValue(key, picked);
                      }
                    },
            ),
          ),
        );
      case 'dashboard' when widget.container != null:
        return DashboardViewRow(
          container: widget.container!,
          title: '${raw['title']}',
          description: raw['description']?.toString(),
          value: '$value',
          onPick: (path) {
            if (mounted && !_busy) _saveValue(key, path);
          },
        );
      case 'action':
        return SettingsRow(
          title: Text('${raw['title']}'),
          subtitle: raw['description'] == null
              ? null
              : Text('${raw['description']}'),
          stack: true,
          trailing: SizedBox(
            width: tightPane(context) ? null : 300,
            child: PluginActionField(
              container: widget.container,
              title: '${raw['title']}',
              value: value,
              enabled: !_busy,
              onPick: (action) async {
                if (mounted && !_busy) await _saveValue(key, action);
              },
            ),
          ),
        );
      case 'cameraView':
        return PickRow(
          title: '${raw['title']}',
          description: raw['description']?.toString(),
          spec: pluginCameraViewSpec(context, _services),
          value: '$value',
          placeholder: pluginText(context, 'Choose a camera view'),
          missingText: pluginText(
            context,
            'This camera view is gone. Choose another.',
          ),
          allowClear: true,
          enabled: !_busy && widget.container != null,
          onPick: (id) async {
            if (mounted && !_busy) await _saveValue(key, id ?? '');
          },
        );
    }
    if (raw['type'] == 'select') {
      // The app's own dropdown row, so plugin choices look like every
      // other setting's.
      return DropdownRow<String>(
        title: '${raw['title']}',
        description: raw['description']?.toString(),
        value: '$value',
        options: [
          for (final option in raw['options'] as List) ('$option', '$option'),
        ],
        onChanged: _busy
            ? null
            : (v) {
                if (v != null && v != '$value') _saveValue(key, v);
              },
      );
    }
    if (raw['type'] == 'entity') {
      final value = '${_values[raw['key']] ?? raw['default']}';
      // A plugin may narrow the picker to one domain or a few, and may
      // list the entities Home Assistant hides.
      final domain = raw['domain'];
      return PickRow(
        title: '${raw['title']}',
        description: raw['description']?.toString(),
        spec: entitySpec(
          context,
          widget.commands,
          domains: [
            if (domain is String) domain,
            if (domain is List)
              for (final d in domain) '$d',
          ],
          includeHidden: raw['includeHidden'] == true,
        ),
        value: value,
        allowClear: true,
        enabled: !_busy,
        onPick: (id) async {
          if (mounted && !_busy) await _saveValue('${raw['key']}', id ?? '');
        },
      );
    }
    if (raw['type'] == 'string' && raw['choices'] == 'plugin') {
      return PluginChoiceRow(
        plugins: widget.plugins,
        pluginId: '${widget.plugin['id']}',
        setting: raw,
        value: '${_values[raw['key']] ?? raw['default']}',
        running: widget.plugin['running'] == true,
        enabled: !_busy,
        onPick: (id) {
          if (mounted && !_busy) _saveValue('${raw['key']}', id);
        },
      );
    }
    if (raw['type'] == 'string' ||
        raw['type'] == 'secret' ||
        raw['type'] == 'dashboard') {
      final value = '${_values[raw['key']] ?? raw['default']}';
      return SettingsRow(
        title: Text('${raw['title']}'),
        subtitle: Text(
          value.isEmpty
              ? raw['description']?.toString() ?? deviceText(context, 'Not set')
              : raw['type'] == 'secret'
              ? '••••••••'
              : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.edit_outlined),
        enabled: !_busy,
        onTap: _busy ? null : () => _editText(raw),
      );
    }
    if (pluginTypedNumber(raw)) {
      return SettingsRow(
        title: Text('${raw['title']}'),
        subtitle: Text('$value ${raw['unit'] ?? ''}'.trim()),
        trailing: const Icon(Icons.edit_outlined),
        enabled: !_busy,
        onTap: _busy ? null : () => _editNumber(raw),
      );
    }
    return SettingsRow(
      title: Text('${raw['title']}'),
      subtitle: raw['description'] == null
          ? null
          : Text('${raw['description']}'),
      stack: raw['type'] != 'boolean' && raw['type'] != 'color',
      trailing: _control(raw),
    );
  }

  Future<void> _configureAction(Map command) async {
    final options =
        (widget.plugin['actionOptions'] as Map?)?[command['id']] as Map?;
    var drawer = options?['drawer'] == true;
    var homeAssistant = options?['homeAssistant'] == true;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${command['title']}'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HintRow(
                    pluginText(
                      context,
                      'To assign a gesture, open Gestures and choose Run a plugin action.',
                    ),
                  ),
                  SettingsRow(
                    title: Text(pluginText(context, 'Show in kiosk drawer')),
                    subtitle: Text(
                      pluginText(
                        context,
                        'Also available while locked if the kiosk drawer is allowed.',
                      ),
                    ),
                    trailing: Switch(
                      value: drawer,
                      onChanged: (value) =>
                          setDialogState(() => drawer = value),
                    ),
                  ),
                  SettingsRow(
                    title: Text(
                      pluginText(context, 'Expose to Home Assistant'),
                    ),
                    subtitle: Text(
                      pluginText(
                        context,
                        'Adds a button to the kiosk ESPHome device. Requires ESPHome and native entities.',
                      ),
                    ),
                    trailing: Switch(
                      value: homeAssistant,
                      onChanged: (value) =>
                          setDialogState(() => homeAssistant = value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(pluginText(context, 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(pluginText(context, 'Save')),
            ),
          ],
        ),
      ),
    );
    if (save == true && mounted) {
      await widget.run('configureAction', {
        'id': widget.plugin['id'],
        'command': command['id'],
        'drawer': drawer,
        'homeAssistant': homeAssistant,
      });
    }
  }

  Widget _control(Map raw) {
    final key = '${raw['key']}';
    final value = _values[key] ?? raw['default'];
    switch (raw['type']) {
      case 'boolean':
        return Switch(
          value: value == true,
          onChanged: _busy ? null : (v) => _saveValue(key, v),
        );
      case 'number':
        final min = (raw['min'] as num).toDouble();
        final max = (raw['max'] as num).toDouble();
        final step = (raw['step'] as num? ?? 1).toDouble();
        return SizedBox(
          width: 260,
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  value: (value as num).toDouble().clamp(min, max),
                  min: min,
                  max: max,
                  divisions: ((max - min) / step).round(),
                  label: '$value ${raw['unit'] ?? ''}',
                  onChangeEnd: _busy
                      ? null
                      : (_) => _saveValue(key, _values[key] ?? value),
                  onChanged: _busy
                      ? null
                      : (v) => setState(
                          () => _values[key] = double.parse(
                            (min + ((v - min) / step).round() * step)
                                .toStringAsFixed(6),
                          ),
                        ),
                ),
              ),
              Text('$value ${raw['unit'] ?? ''}'.trim()),
            ],
          ),
        );
      case 'color':
        final hex = '$value';
        final color = Color(
          0xff000000 | int.parse(hex.substring(1), radix: 16),
        );
        return IconButton(
          tooltip: '${raw['title']}',
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          onPressed: _busy
              ? null
              : () async {
                  final rgb = [1, 3, 5]
                      .map((i) => int.parse(hex.substring(i, i + 2), radix: 16))
                      .join(',');
                  final selected = await pickColor(
                    context,
                    initial: rgb,
                    title: '${raw['title']}',
                  );
                  if (selected != null && mounted) {
                    await _saveValue(
                      key,
                      '#${selected.split(',').map((c) => int.parse(c.trim()).toRadixString(16).padLeft(2, '0')).join().toUpperCase()}',
                    );
                  }
                },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final plugin = widget.plugin;
    final declared = plugin['settings'] as List? ?? const [];
    // A setting whose condition does not hold stays out of the page. Its
    // saved value is kept.
    final settings = [
      for (final raw in declared.whereType<Map>())
        if (pluginFieldVisible(raw, _values, declared)) raw,
    ];
    // Buttons follow the same conditions, by the settings they name.
    final buttons = [
      for (final raw
          in (plugin['buttons'] as List? ?? const []).whereType<Map>())
        if (pluginFieldVisible(raw, _values, declared)) raw,
    ];
    final commands = plugin['commands'] as List? ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (settings.isNotEmpty || buttons.isNotEmpty) ...[
          for (final group in pluginSettingsGroups(plugin)) ...[
            SectionHeading(
              group == 'Settings' &&
                      !(plugin['groups'] as List? ?? []).any(
                        (g) => g['title'] == group,
                      ) &&
                      !settings.any((entry) => entry['group'] == group) &&
                      !buttons.any((entry) => entry['group'] == group)
                  ? pluginText(context, 'Settings')
                  : group,
            ),
            Builder(
              builder: (context) {
                final rows = [
                  for (final raw in settings)
                    if ('${raw['group'] ?? 'Settings'}' == group) raw,
                ];
                final pressable = [
                  for (final raw in buttons)
                    if ('${raw['group'] ?? 'Settings'}' == group) raw,
                ];
                if (rows.isEmpty && pressable.isEmpty) {
                  return const SizedBox.shrink();
                }
                return SettingsCard(
                  children: [
                    for (final raw in rows)
                      SearchLandingTarget(
                        id: 'plugin:${plugin['id']}:setting:${raw['key']}',
                        child: _settingRow(
                          raw,
                          alone: rows.length + pressable.length == 1,
                        ),
                      ),
                    for (final raw in pressable)
                      SearchLandingTarget(
                        id: 'plugin:${plugin['id']}:button:${raw['id']}',
                        child: PluginSetupButtonRow(
                          plugins: widget.plugins,
                          pluginId: '${plugin['id']}',
                          button: raw,
                          running: plugin['running'] == true,
                        ),
                      ),
                  ],
                );
              },
            ),
            _PluginGroupOutput(
              plugins: widget.plugins,
              plugin: plugin,
              group: group,
            ),
          ],
        ],
        _PluginGroupOutput(plugins: widget.plugins, plugin: plugin),
        if (commands.isNotEmpty) ...[
          SectionHeading(pluginText(context, 'Actions')),
          SettingsCard(
            children: [
              for (final raw in commands)
                SearchLandingTarget(
                  id: 'plugin:${plugin['id']}:action:${(raw as Map)['id']}',
                  child: SettingsRow(
                    title: Text('${raw['title']}'),
                    subtitle: Text(_actionSummary(raw['id'].toString())),
                    enabled: !_busy,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _configureAction(raw),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

List<String> pluginSettingsGroups(Map plugin) => {
  for (final group in (plugin['groups'] as List? ?? const []).whereType<Map>())
    '${group['title']}',
  for (final setting
      in (plugin['settings'] as List? ?? const []).whereType<Map>())
    '${setting['group'] ?? 'Settings'}',
  for (final button
      in (plugin['buttons'] as List? ?? const []).whereType<Map>())
    '${button['group'] ?? 'Settings'}',
}.toList();

/// Runtime updates stay below their settings without rebuilding editing controls.
class _PluginGroupOutput extends StatelessWidget {
  const _PluginGroupOutput({
    required this.plugins,
    required this.plugin,
    this.group,
  });
  final PluginManager plugins;
  final Map plugin;
  final String? group;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([plugins.readings, plugins.charts]),
    builder: (context, _) {
      final groups = (plugin['groups'] as List? ?? const []).whereType<Map>();
      final layout = groups.where((g) => g['title'] == group).firstOrNull;
      bool belongs(String kind, String key) =>
          pluginOutputGroup(groups, kind, key) == group;

      final charts = (plugins.charts.value[plugin['id']] ?? const [])
          .where((chart) => belongs('charts', '${chart['key']}'))
          .toList();
      final readings = (plugins.readings.value[plugin['id']] ?? const [])
          .where(
            (reading) =>
                belongs('readings', '${reading['type']}.${reading['key']}'),
          )
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (charts.isNotEmpty && group == null)
            SectionHeading(pluginText(context, 'Charts')),
          for (final chart in charts)
            PluginChart(
              key: ValueKey('${plugin['id']}:${chart['key']}'),
              chart: chart,
            ),
          PluginReadings(
            readings: readings,
            title: layout?['readingsTitle']?.toString(),
          ),
        ],
      );
    },
  );
}

/// The group whose [kind] ("readings" or "charts") claims [key], or null
/// when none does. A group naming the key wins over one claiming its whole
/// type with "sensor.*", which wins over one claiming the rest with "*".
String? pluginOutputGroup(Iterable<Map> groups, String kind, String key) {
  String? claimedBy(String reference) => groups
      .where((g) => (g[kind] as List? ?? const []).contains(reference))
      .firstOrNull?['title']
      ?.toString();
  final dot = key.indexOf('.');
  return claimedBy(key) ??
      (kind == 'readings' && dot > 0
          ? claimedBy('${key.substring(0, dot)}.*')
          : null) ??
      claimedBy('*');
}

/// The icon an installed plugin names in its manifest, filling the intro
/// row's tile, or the generic plugin glyph without one.
class _InstalledPluginIcon extends StatelessWidget {
  const _InstalledPluginIcon({required this.plugins, required this.id});
  final PluginManager plugins;
  final String id;

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: plugins.pluginIcon(id),
    builder: (context, snapshot) {
      final bytes = snapshot.data;
      if (bytes == null) return const Icon(Icons.extension_rounded);
      return ClipRRect(
        borderRadius: BorderRadius.circular(Ks.radiusRow),
        child: Image.memory(
          bytes,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const Icon(Icons.extension_rounded),
        ),
      );
    },
  );
}
