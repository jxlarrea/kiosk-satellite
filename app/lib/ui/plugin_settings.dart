import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../managers/plugins/plugin_manager.dart';
import 'kit.dart';
import 'color_picker.dart';
import 'toast.dart';

const pluginIntro =
    'Plugins add additional community developed features to Kiosk Satellite.';

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
          title: 'Plugin Manager',
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
              helperText:
                  "Make sure you trust the plugin's author and its code before installing it.",
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
    await _confirmPreview(preview);
  }

  Future<void> _checkUpdate(Map<String, Object?> plugin) async {
    final preview = await widget.plugins.checkUpdate(plugin['id'] as String);
    if (!mounted) return;
    if (preview['updateAvailable'] != true) {
      showToast(
        context,
        title: '${plugin['name']}',
        message: 'No updates available.',
      );
      return;
    }
    await _confirmPreview(preview);
  }

  Future<void> _confirmPreview(Map<String, Object?> preview) async {
    if (!mounted) return;
    final isUpdate = preview.containsKey('installedVersion');
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
                  if (isUpdate)
                    'Installed version': preview['installedVersion'],
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
                  'New plugins start disabled. Updates preserve the enabled state and automatically restart running plugins.',
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
            child: Text(isUpdate ? 'Trust and update' : 'Trust and install'),
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

  Future<void> _installZip() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withReadStream: true,
    );
    if (picked == null || !mounted) return;
    final file = picked.files.single;
    if (file.size <= 0 || file.size > PluginManager.maxZipBytes) {
      throw const FormatException('Plugin ZIP must be at most 4 MB');
    }
    final trusted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Install from ZIP'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HintRow(file.name),
                const WarnRow(pluginTrustNotice),
                const HintRow(
                  'New plugins start disabled. Updates preserve the enabled state and automatically restart running plugins.',
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Trust and install'),
          ),
        ],
      ),
    );
    if (trusted != true || !mounted) return;
    final stream = file.readStream;
    if (stream == null) throw StateError('Could not read the selected ZIP');
    await widget.plugins.installZipStream(stream, trusted: true);
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

  Future<void> _showInfo(Map<String, Object?> plugin) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${plugin['name']}'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: plugin['source'] is Map
              ? PluginReadme(source: plugin['source'] as Map)
              : const Text(
                  'This plugin was installed from ZIP and has no repository README.',
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
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
            SettingsRow(
              title: const Text('Enable Plugins'),
              subtitle: const Text(pluginIntro),
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
          ],
        ),
        if (enabled) ...[
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: WarnRow(pluginTrustNotice),
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
                          _pluginEntryHint(plugin),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                        IconButton(
                          tooltip: 'Check for updates for ${plugin['name']}',
                          icon: _busy && _busyId == '${plugin['id']}:update'
                              ? const _PluginProgress()
                              : const Icon(Icons.update_rounded),
                          onPressed: _busy || plugin['source'] is! Map
                              ? null
                              : () => _run(
                                  () => _checkUpdate(plugin),
                                  id: '${plugin['id']}:update',
                                ),
                        ),
                        IconButton(
                          tooltip: 'About ${plugin['name']}',
                          icon: const Icon(Icons.info_outline_rounded),
                          onPressed: _busy ? null : () => _showInfo(plugin),
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
          const SectionHeading('Developer Tools'),
          SettingsCard(
            children: [
              SettingsRow(
                title: const Text('Install from ZIP'),
                subtitle: const Text('For developers only: test a local build'),
                trailing: _busy && _busyId == '_zip'
                    ? const _PluginProgress()
                    : const Icon(Icons.upload_file_rounded),
                enabled: !_busy,
                onTap: () => _run(_installZip, id: '_zip'),
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
  });
  final PluginManager plugins;
  final String id;
  final VoidCallback? onDisabled;
  @override
  State<PluginDetailPanel> createState() => _PluginDetailPanelState();
}

class _PluginDetailPanelState extends State<PluginDetailPanel> {
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    widget.plugins.enabled.addListener(_masterChanged);
    _masterChanged();
  }

  void _masterChanged() {
    if (widget.plugins.enabled.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.plugins.enabled.value) widget.onDisabled?.call();
    });
  }

  @override
  void dispose() {
    widget.plugins.enabled.removeListener(_masterChanged);
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
        return const Text('This plugin is no longer installed.');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsCard(
            children: [
              SettingsRow(title: Text('${plugin['description'] ?? ''}')),
              if ('${plugin['status'] ?? ''}'.isNotEmpty)
                plugin['statusError'] == true
                    ? WarnRow('${plugin['status']}')
                    : HintRow('${plugin['status']}'),
              if (!widget.plugins.enabled.value)
                const HintRow('Enable Plugins to run this plugin.')
              else if (plugin['enabled'] != true)
                const HintRow(
                  'Enable this plugin from its entry row to run it.',
                ),
              if ('${plugin['error'] ?? ''}'.isNotEmpty)
                WarnRow('${plugin['error']}'),
            ],
          ),
          _PluginSettings(
            key: ValueKey(widget.id),
            plugin: plugin,
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
    required this.busy,
    required this.run,
  });
  final Map<String, Object?> plugin;
  final bool busy;
  final Future<void> Function(String, Map<String, Object?>) run;
  @override
  State<_PluginSettings> createState() => _PluginSettingsState();
}

class _PluginSettingsState extends State<_PluginSettings> {
  late Map<String, Object?> _values;
  bool _saving = false;
  bool get _busy => widget.busy || _saving;
  @override
  void initState() {
    super.initState();
    _reset();
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
      'Gestures',
      if (options?['drawer'] == true) 'Kiosk drawer',
      if (options?['homeAssistant'] == true) 'Home Assistant',
    ].join(' · ');
  }

  Future<void> _saveValue(String key, Object? value) async {
    if (_busy) return;
    setState(() {
      _saving = true;
      _values[key] = value;
    });
    try {
      await widget.run('configure', {
        'id': widget.plugin['id'],
        'values': {...?widget.plugin['values'] as Map?, key: value},
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
    var draft = '${_values[key] ?? raw['default']}';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${raw['title']}'),
        content: SizedBox(
          width: 420,
          child: TextFormField(
            initialValue: draft,
            autofocus: true,
            maxLength: 512,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: raw['description'] as String?,
            ),
            onChanged: (value) => draft = value,
            onFieldSubmitted: (value) => Navigator.pop(context, value),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, draft),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && mounted && !_busy) {
      await _saveValue(key, result);
    }
  }

  Widget _settingRow(Map raw) {
    if (raw['type'] == 'string') {
      final value = '${_values[raw['key']] ?? raw['default']}';
      return SettingsRow(
        title: Text('${raw['title']}'),
        subtitle: Text(
          value.isEmpty ? '${raw['description'] ?? 'Not set'}' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.edit_outlined),
        enabled: !_busy,
        onTap: _busy ? null : () => _editText(raw),
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
                  const HintRow(
                    'To assign a gesture, open Gestures and choose Run a plugin action.',
                  ),
                  SettingsRow(
                    title: const Text('Show in kiosk drawer'),
                    subtitle: const Text(
                      'Also available while locked if the kiosk drawer is allowed.',
                    ),
                    trailing: Switch(
                      value: drawer,
                      onChanged: (value) =>
                          setDialogState(() => drawer = value),
                    ),
                  ),
                  SettingsRow(
                    title: const Text('Expose to Home Assistant'),
                    subtitle: const Text(
                      'Adds a button to the kiosk ESPHome device. Requires ESPHome and native entities.',
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
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
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
      case 'select':
        return SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            key: ValueKey('$key-$value'),
            initialValue: '$value',
            isExpanded: true,
            items: [
              for (final option in raw['options'] as List)
                DropdownMenuItem(value: '$option', child: Text('$option')),
            ],
            onChanged: _busy ? null : (v) => _saveValue(key, v),
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
    final settings = plugin['settings'] as List? ?? const [];
    final commands = plugin['commands'] as List? ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (settings.isNotEmpty) ...[
          for (final group
              in settings
                  .map((raw) => '${(raw as Map)['group'] ?? 'Settings'}')
                  .toSet()) ...[
            SectionHeading(group),
            SettingsCard(
              children: [
                for (final raw in settings.where(
                  (raw) => '${(raw as Map)['group'] ?? 'Settings'}' == group,
                ))
                  _settingRow(raw as Map),
              ],
            ),
          ],
        ],
        if (commands.isNotEmpty) ...[
          const SectionHeading('Actions'),
          SettingsCard(
            children: [
              for (final raw in commands)
                SettingsRow(
                  title: Text('${(raw as Map)['title']}'),
                  subtitle: Text(_actionSummary(raw['id'].toString())),
                  enabled: !_busy,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _configureAction(raw),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
