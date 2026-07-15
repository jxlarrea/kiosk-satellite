import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/settings/definitions.dart';

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
                ],
              );
            },
          ),
        ],
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
