import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../managers/plugins/plugin_manager.dart';
import 'kit.dart';
import 'toast.dart';

const pluginIntro =
    'Plugins add optional features to Kiosk Satellite, such as floating windows over your dashboard. Each plugin has its own settings and can be enabled or removed independently.';

const pluginTrustNotice =
    'Plugins run code inside Kiosk Satellite and can access '
    'app data and granted Android permissions. A faulty or malicious plugin can '
    'expose private information or stop the app from working. Only install plugins from authors you trust.';

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
          const SnackBar(content: Text('Could not open this link.')),
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
              errorBuilder: (_, _, _) => Text(alt ?? 'Image unavailable'),
            );
    },
  );
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
          title: 'Plugins',
          message: '$error',
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
        title: const Text('Add plugin'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: _url,
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Repository URL',
              hintText: 'https://github.com/owner/plugin',
              helperText: 'Review the plugin before installing it.',
            ),
            onSubmitted: (value) => Navigator.pop(context, value.trim()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _url.text.trim()),
            child: const Text('Preview'),
          ),
        ],
      ),
    );
    if (url == null) return;
    final preview = await widget.plugins.previewRepository(url);
    if (!mounted) return;
    final manifest = preview['manifest'] as Map;
    final install = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${manifest['name']}'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${manifest['description']}'),
                const SizedBox(height: 16),
                for (final entry in {
                  'Version': manifest['version'],
                  'Author': manifest['author'],
                  'License': manifest['license'],
                }.entries)
                  SettingsRow(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.key),
                    trailing: Text('${entry.value}'),
                  ),
                const SizedBox(height: 16),
                PluginReadme(source: preview),
                const Divider(height: 32),
                const WarnRow(pluginTrustNotice),
                const SizedBox(height: 12),
                const HintRow(
                  'Installed plugins start disabled. Enable this plugin from its entry row when you are ready.',
                ),
                if (preview['compatible'] != true)
                  Text(
                    '${preview['compatibilityError']}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: preview['compatible'] == true
                ? () => Navigator.pop(context, true)
                : null,
            child: const Text('Trust and install'),
          ),
        ],
      ),
    );
    if (install == true) {
      await widget.plugins.installRepository(
        preview['previewId'] as String,
        trusted: true,
      );
      if (mounted) _url.clear();
    }
  }

  Future<void> _remove(Map<String, Object?> plugin) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Uninstall ${plugin['name']}?'),
        content: const Text('This removes the plugin and its settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
    if (remove == true) {
      await widget.plugins.update('remove', {'id': plugin['id']});
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SettingsCard(
        children: [HintRow(pluginIntro), WarnRow(pluginTrustNotice)],
      ),
      SettingsCard(
        children: [
          SettingsRow(
            title: const Text('Add plugin'),
            subtitle: const Text('Install from a GitHub repository'),
            trailing: _busy && _busyId == null
                ? const _PluginProgress()
                : const Icon(Icons.add_rounded),
            enabled: !_busy,
            onTap: () => _run(_preview),
          ),
        ],
      ),
      const SectionHeading('Installed plugins'),
      ValueListenableBuilder<String>(
        valueListenable: widget.plugins.status,
        builder: (_, status, _) =>
            status.isEmpty ? const SizedBox.shrink() : WarnRow(status),
      ),
      ValueListenableBuilder<List<Map<String, Object?>>>(
        valueListenable: widget.plugins.installed,
        builder: (context, plugins, _) => SettingsCard(
          children: [
            if (plugins.isEmpty)
              const HintRow(
                'No plugins installed. Add a repository to get started.',
              ),
            for (final plugin in plugins)
              SettingsRow(
                leading: const Icon(Icons.extension_rounded),
                title: Text('${plugin['name']}'),
                subtitle: Text(
                  '${plugin['version']} · ${plugin['enabled'] == true ? 'Enabled' : 'Disabled'}',
                ),
                onTap: _busy
                    ? null
                    : () => widget.onOpen(plugin['id'] as String),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: plugin['enabled'] == true,
                      onChanged: _busy
                          ? null
                          : (value) => _run(
                              () => widget.plugins.update(
                                value ? 'enable' : 'disable',
                                {'id': plugin['id']},
                              ),
                              id: plugin['id'] as String,
                            ),
                    ),
                    IconButton(
                      tooltip: 'Uninstall ${plugin['name']}',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => _remove(plugin),
                              id: plugin['id'] as String,
                            ),
                    ),
                    _busy && _busyId == plugin['id']
                        ? const _PluginProgress()
                        : const Icon(Icons.chevron_right),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
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
  const PluginDetailPanel({super.key, required this.plugins, required this.id});
  final PluginManager plugins;
  final String id;
  @override
  State<PluginDetailPanel> createState() => _PluginDetailPanelState();
}

class _PluginDetailPanelState extends State<PluginDetailPanel> {
  bool _busy = false;
  String? _action;
  Future<void> _run(String method, Map<String, Object?> args) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _action = method == 'execute' ? args['command'] as String : method;
    });
    try {
      await widget.plugins.update(method, args);
    } catch (error) {
      if (mounted) {
        showToast(
          context,
          title: 'Plugin',
          message: '$error',
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<List<Map<String, Object?>>>(
    valueListenable: widget.plugins.installed,
    builder: (context, plugins, _) {
      final plugin = plugins.where((p) => p['id'] == widget.id).firstOrNull;
      if (plugin == null) {
        return const Text('This plugin is no longer installed.');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsCard(
            children: [
              HintRow('${plugin['description'] ?? ''}'),
              if (plugin['enabled'] != true)
                const HintRow(
                  'Enable this plugin from its entry row to use its actions.',
                ),
              if ('${plugin['error'] ?? ''}'.isNotEmpty)
                WarnRow('${plugin['error']}'),
            ],
          ),
          _PluginSettings(
            key: ValueKey(widget.id),
            plugin: plugin,
            busy: _busy,
            action: _action,
            run: _run,
          ),
          if (plugin['loaded'] == true)
            const HintRow(
              'To install another version, disable this plugin and restart Kiosk first.',
            ),
          if (plugin['source'] is Map)
            const SectionHeading('About this plugin'),
          if (plugin['source'] is Map)
            SettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${(plugin['source'] as Map)['repository']}'),
                      const Divider(height: 32),
                      PluginReadme(source: plugin['source'] as Map),
                    ],
                  ),
                ),
              ],
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
    required this.busy,
    required this.action,
    required this.run,
  });
  final Map<String, Object?> plugin;
  final bool busy;
  final String? action;
  final Future<void> Function(String, Map<String, Object?>) run;
  @override
  State<_PluginSettings> createState() => _PluginSettingsState();
}

class _PluginSettingsState extends State<_PluginSettings> {
  late Map<String, Object?> _values;
  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(covariant _PluginSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.plugin, widget.plugin)) _reset();
  }

  void _reset() => _values = Map<String, Object?>.from(
    widget.plugin['values'] as Map? ?? const {},
  );
  @override
  Widget build(BuildContext context) {
    final plugin = widget.plugin;
    final id = plugin['id'] as String;
    final enabled = plugin['enabled'] == true;
    final settings = plugin['settings'] as List? ?? const [];
    final commands = plugin['commands'] as List? ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (settings.isNotEmpty) ...[
          const SectionHeading('Settings'),
          SettingsCard(
            children: [
              for (final raw in settings)
                SettingsRow(
                  title: Text('${(raw as Map)['title']}'),
                  stack: raw['type'] != 'boolean',
                  trailing: raw['type'] == 'boolean'
                      ? Switch(
                          value: _values[raw['key']] == true,
                          onChanged: widget.busy
                              ? null
                              : (value) => setState(
                                  () => _values['${raw['key']}'] = value,
                                ),
                        )
                      : SizedBox(
                          width: 220,
                          child: TextFormField(
                            key: ValueKey(
                              '$id-${raw['key']}-${(plugin['values'] as Map?)?[raw['key']]}',
                            ),
                            initialValue:
                                '${_values[raw['key']] ?? raw['default'] ?? ''}',
                            enabled: !widget.busy,
                            maxLength: 512,
                            decoration: const InputDecoration(
                              counterText: '',
                              isDense: true,
                            ),
                            onChanged: (value) =>
                                _values['${raw['key']}'] = value,
                          ),
                        ),
                ),
              SettingsRow(
                title: const Text('Save changes'),
                trailing: TextButton.icon(
                  onPressed: widget.busy
                      ? null
                      : () => widget.run('configure', {
                          'id': id,
                          'values': _values,
                        }),
                  icon: widget.busy && widget.action == 'configure'
                      ? const _PluginProgress()
                      : const Icon(Icons.check_rounded, size: 24),
                  label: const Text('Save settings'),
                ),
              ),
            ],
          ),
        ],
        if (commands.isNotEmpty) ...[
          const SectionHeading('Actions'),
          SettingsCard(
            children: [
              for (final raw in commands)
                SettingsRow(
                  title: Text('${(raw as Map)['title']}'),
                  trailing: IconButton(
                    tooltip: '${raw['title']}',
                    onPressed: widget.busy || !enabled
                        ? null
                        : () => widget.run('execute', {
                            'id': id,
                            'command': raw['id'],
                          }),
                    icon: widget.busy && widget.action == raw['id']
                        ? const _PluginProgress()
                        : const Icon(Icons.play_arrow_rounded),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
