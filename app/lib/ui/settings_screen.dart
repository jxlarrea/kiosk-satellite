import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/settings/definitions.dart';

/// Local settings, rendered entirely from the declarative setting
/// definitions — the same source the remote admin UI uses.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.container});

  final AppContainer container;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppContainer get c => widget.container;

  @override
  Widget build(BuildContext context) {
    final categories = <String, List<SettingDef<Object>>>{};
    for (final def in allSettings) {
      (categories[def.category] ??= []).add(def);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          for (final entry in categories.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            for (final def in entry.value) _buildTile(def),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTile(SettingDef<Object> def) {
    switch (def.type) {
      case SettingType.boolean:
        return SwitchListTile(
          title: Text(def.title),
          subtitle: Text(def.description),
          value: c.settings.get(def) as bool,
          onChanged: (v) async {
            await c.settings.setFromJson(def.key, v);
            setState(() {});
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
              setState(() {});
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
          onTap: () => _editText(def),
        );
    }
  }

  Future<void> _editText(SettingDef<Object> def) async {
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
      setState(() {});
    }
  }
}
