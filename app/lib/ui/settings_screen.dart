import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../managers/settings/definitions.dart';
import '../managers/wake_word/engine.dart';

/// Hierarchical settings, Fully Kiosk style: the top level is a list of
/// category pages, each rendered from the declarative setting definitions —
/// the same source the remote admin UI uses.
///
/// Home Assistant and Voice Satellite share one page; the Voice Satellite
/// section only appears when the VS integration is detected on the
/// connected HA instance.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.container});

  final AppContainer container;

  static const _categories = <(String, String, IconData, String)>[
    // (defs category, page title, icon, subtitle)
    ('Browser', 'Web Browsing', Icons.public,
        'Start URL, error recovery'),
    ('Web Content', 'Web Content', Icons.tune,
        'Microphone, camera, geolocation, pop-ups'),
    ('Screen', 'Screen', Icons.brightness_6_outlined,
        'Brightness, keep awake'),
    ('Screensaver', 'Screensaver', Icons.dark_mode_outlined,
        'Idle timeout, dim and black modes'),
    ('Motion', 'Motion Detection', Icons.sensors,
        'Wake the screen with the camera'),
    ('Home Assistant', 'Home Assistant', Icons.home_outlined,
        'Connection, kiosk mode, Voice Satellite'),
    ('Remote', 'Remote Administration', Icons.settings_remote_outlined,
        'Web console access'),
    ('Device', 'Device', Icons.tablet_android_outlined,
        'Name and identity'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          for (final (category, title, icon, subtitle) in _categories)
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => category == 'Home Assistant'
                    ? HomeAssistantSettingsScreen(container: container)
                    : CategorySettingsScreen(
                        container: container,
                        title: title,
                        defs: _defsFor(category),
                      ),
              )),
            ),
        ],
      ),
    );
  }

  static List<SettingDef<Object>> _defsFor(String category) =>
      [for (final def in allSettings) if (def.category == category) def];
}

/// One category's settings.
class CategorySettingsScreen extends StatefulWidget {
  const CategorySettingsScreen({
    super.key,
    required this.container,
    required this.title,
    required this.defs,
  });

  final AppContainer container;
  final String title;
  final List<SettingDef<Object>> defs;

  @override
  State<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends State<CategorySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        children: [
          for (final def in widget.defs)
            SettingTile(
              container: widget.container,
              def: def,
              onChanged: () => setState(() {}),
            ),
        ],
      ),
    );
  }
}

/// Home Assistant + Voice Satellite share a page; the VS section is only
/// shown when the integration is detected on the connected instance.
class HomeAssistantSettingsScreen extends StatefulWidget {
  const HomeAssistantSettingsScreen({super.key, required this.container});

  final AppContainer container;

  @override
  State<HomeAssistantSettingsScreen> createState() =>
      _HomeAssistantSettingsScreenState();
}

class _HomeAssistantSettingsScreenState
    extends State<HomeAssistantSettingsScreen> {
  late Future<bool> _vsDetected;

  @override
  void initState() {
    super.initState();
    _vsDetected = widget.container.homeAssistant.detectVoiceSatellite();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Home Assistant')),
      body: ListView(
        children: [
          for (final def in SettingsScreen._defsFor('Home Assistant'))
            SettingTile(
              container: widget.container,
              def: def,
              onChanged: () => setState(() {}),
            ),
          FutureBuilder<bool>(
            future: _vsDetected,
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Voice Satellite',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  for (final def in SettingsScreen._defsFor('Voice Satellite'))
                    SettingTile(
                      container: widget.container,
                      def: def,
                      onChanged: () => setState(() {}),
                    ),
                  WakeWordStatusTile(container: widget.container),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Read-only status of the wake-word config inherited from Voice Satellite:
/// the active engine, the wake word(s), and whether native inference is
/// running. Updates live as the VS card pushes config / state changes.
class WakeWordStatusTile extends StatefulWidget {
  const WakeWordStatusTile({super.key, required this.container});

  final AppContainer container;

  @override
  State<WakeWordStatusTile> createState() => _WakeWordStatusTileState();
}

class _WakeWordStatusTileState extends State<WakeWordStatusTile> {
  StreamSubscription<WakeWordStateChanged>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.container.bus
        .on<WakeWordStateChanged>()
        .listen((_) => setState(() {}));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wake = widget.container.wakeWord;
    final config = wake.config;
    final status = wake.status;

    // Before the card has pushed a config there is nothing to show but the
    // status itself. The wording is the manager's, so the web admin says it
    // word for word (see WakeWordManager.status).
    if (config == null || !wake.enabled) {
      return ListTile(
        leading: Icon(status.code == 'disabled'
            ? Icons.mic_off_outlined
            : Icons.hourglass_empty),
        title: Text(status.code == 'disabled'
            ? 'Wake word detection is off'
            : 'Waiting for Voice Satellite'),
        subtitle: Text(status.label),
      );
    }

    final statusColor = wake.available
        ? (wake.listening ? theme.colorScheme.primary : theme.colorScheme.onSurface)
        : theme.colorScheme.error;
    final statusText = status.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(Icons.graphic_eq, color: statusColor),
          title: const Text('Engine'),
          trailing: Text(config.engine.label,
              style: theme.textTheme.titleMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wake words',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in config.models)
                    Chip(
                      avatar: const Icon(Icons.record_voice_over, size: 18),
                      label: Text(m.wakeWord),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              // When something has failed the recovery card below states it,
              // in full and next to the buttons that act on it. Saying it here
              // too just prints the same sentence twice.
              if (wake.failure == null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      wake.available
                          ? (wake.listening ? Icons.mic : Icons.mic_none)
                          : Icons.warning_amber_rounded,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(statusText,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: statusColor)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (wake.failure != null)
          WakeWordRecoveryTile(container: widget.container),
        if (config.stopModel != null)
          ListTile(
            leading: const Icon(Icons.front_hand_outlined),
            title: const Text('Stop word'),
            subtitle: Text(wake.stopWordAvailable
                ? 'Running in Kiosk'
                : 'Voice Satellite keeps this one in the browser'),
            trailing: Text(config.stopModel!.wakeWord,
                style: theme.textTheme.bodyMedium),
          ),
        ClearModelCacheTile(container: widget.container),
      ],
    );
  }
}

/// The way out of a failed engine.
///
/// Mirrored by the web admin, which offers the same two actions from the same
/// state (`canRetry` / `needsAppSettings`). A blocked microphone is the reason
/// this exists: Android stops asking after the second refusal, the browser
/// fallback needs the same permission and goes quiet too, and without an offer
/// to open the OS settings a single stray tap disables wake words for good on a
/// device whose owner may never see a system UI again.
class WakeWordRecoveryTile extends StatefulWidget {
  const WakeWordRecoveryTile({super.key, required this.container});

  final AppContainer container;

  @override
  State<WakeWordRecoveryTile> createState() => _WakeWordRecoveryTileState();
}

class _WakeWordRecoveryTileState extends State<WakeWordRecoveryTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wake = widget.container.wakeWord;
    final settingsFirst = wake.needsAppSettings;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline,
                    size: 18, color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(wake.status.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (settingsFirst)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => widget.container.commands
                            .execute('openAppSettings', const {}),
                    child: const Text('Open app settings'),
                  ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          await widget.container.commands
                              .execute('retryWakeWord', const {});
                          if (mounted) setState(() => _busy = false);
                        },
                  child: Text(_busy ? 'Retrying…' : 'Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Drop the cached models and re-download them.
///
/// Mirrored by the web admin's "Clear cache" button (both call
/// `clearWakeWordModels`). Models cache by URL, so a model re-published on Home
/// Assistant under the same name never reaches a device that already has one.
class ClearModelCacheTile extends StatefulWidget {
  const ClearModelCacheTile({super.key, required this.container});

  final AppContainer container;

  @override
  State<ClearModelCacheTile> createState() => _ClearModelCacheTileState();
}

class _ClearModelCacheTileState extends State<ClearModelCacheTile> {
  bool _busy = false;
  String? _result;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.cleaning_services_outlined),
      title: const Text('Cached models'),
      subtitle: Text(_result ??
          'Re-download from Home Assistant. Use after re-publishing a model.'),
      trailing: _busy
          ? const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : TextButton(
              onPressed: () async {
                setState(() => _busy = true);
                final result = await widget.container.commands
                    .execute('clearWakeWordModels', const {});
                if (!mounted) return;
                final removed = (result.data as Map?)?['removed'];
                setState(() {
                  _busy = false;
                  _result = result.ok
                      ? 'Cleared $removed file(s); re-downloading.'
                      : 'Could not clear the cache.';
                });
              },
              child: const Text('Clear'),
            ),
    );
  }
}

/// A single setting rendered by its declared type.
class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.container,
    required this.def,
    required this.onChanged,
  });

  final AppContainer container;
  final SettingDef<Object> def;
  final VoidCallback onChanged;

  AppContainer get c => container;

  @override
  Widget build(BuildContext context) {
    switch (def.type) {
      case SettingType.boolean:
        return SwitchListTile(
          title: Text(def.title),
          subtitle: Text(def.description),
          value: c.settings.get(def) as bool,
          onChanged: (v) async {
            await c.settings.setFromJson(def.key, v);
            onChanged();
          },
        );
      case SettingType.select:
        return ListTile(
          title: Text(def.title),
          subtitle: Text(def.description),
          trailing: DropdownButton<String>(
            value: c.settings.get(def) as String,
            items: [
              for (final option in def.options ?? const <String>[])
                DropdownMenuItem(value: option, child: Text(option)),
            ],
            onChanged: (v) async {
              if (v == null) return;
              await c.settings.setFromJson(def.key, v);
              onChanged();
            },
          ),
        );
      case SettingType.string ||
            SettingType.password ||
            SettingType.number:
        final value = c.settings.get(def);
        final display = def.secret
            ? ((value as String).isEmpty ? 'Not set' : '••••••••')
            : '$value';
        return ListTile(
          title: Text(def.title),
          subtitle: Text(display),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _editText(context),
        );
    }
  }

  Future<void> _editText(BuildContext context) async {
    final current = c.settings.get(def);
    final controller = TextEditingController(
      text: def.secret ? '' : '$current',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(def.title),
        content: TextField(
          controller: controller,
          obscureText: def.secret,
          autofocus: true,
          keyboardType: def.type == SettingType.number
              ? TextInputType.number
              : TextInputType.text,
          decoration: InputDecoration(hintText: def.description),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final value = def.type == SettingType.number
        ? num.tryParse(result)
        : result;
    if (value != null) {
      await c.settings.setFromJson(def.key, value);
      onChanged();
    }
  }
}
