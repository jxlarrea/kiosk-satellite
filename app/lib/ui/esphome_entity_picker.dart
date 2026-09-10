import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/command_registry.dart';
import '../managers/settings/settings_manager.dart';

class EspHomeExcludedEntitiesRow extends StatelessWidget {
  const EspHomeExcludedEntitiesRow({
    super.key,
    required this.settings,
    required this.commands,
    required this.onChanged,
  });

  final SettingsManager settings;
  final CommandRegistry commands;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = decodeEspHomeExcludedEntities(
      settings.get(esphomeExcludedEntities),
    );
    return ListTile(
      title: Text(esphomeExcludedEntities.title),
      subtitle: Text(
        selected.isEmpty
            ? 'All available entities exposed'
            : '${selected.length} excluded',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await showDialog<Set<String>>(
          context: context,
          builder: (_) => _EntityPicker(commands: commands, selected: selected),
        );
        if (picked == null) return;
        await settings.set(
          esphomeExcludedEntities,
          jsonEncode(picked.toList()..sort()),
        );
        onChanged();
      },
    );
  }
}

class _EntityPicker extends StatefulWidget {
  const _EntityPicker({required this.commands, required this.selected});

  final CommandRegistry commands;
  final Set<String> selected;

  @override
  State<_EntityPicker> createState() => _EntityPickerState();
}

class _EntityPickerState extends State<_EntityPicker> {
  late final _selected = {...widget.selected};
  List<Map<String, String>>? _entities;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await widget.commands.execute(
        'getEspHomeEntities',
        const {},
      );
      if (!result.ok || result.data is! List) {
        throw StateError(result.error ?? 'Could not load entities.');
      }
      final entities = [
        for (final entity in result.data as List)
          if (entity is Map)
            <String, String>{
              'id': '${entity['objectId']}',
              'name': '${entity['name']}',
              'detail': [
                if (entity['categoryLabel'] != null)
                  '${entity['categoryLabel']}',
                '${entity['type']}'.replaceAll('_', ' '),
              ].join(' · '),
            },
      ];
      final available = entities.map((e) => e['id']).toSet();
      for (final id in _selected.difference(available)) {
        entities.add({'id': id, 'name': id, 'detail': 'Currently unavailable'});
      }
      entities.sort(
        (a, b) => a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()),
      );
      if (mounted) setState(() => _entities = entities);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not load entities. Close the picker and try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _entities
        ?.where(
          (e) => '${e['name']} ${e['id']} ${e['detail']}'
              .toLowerCase()
              .contains(_query),
        )
        .toList();
    return AlertDialog(
      title: Text(esphomeExcludedEntities.title),
      content: SizedBox(
        width: 520,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(esphomeExcludedEntities.description),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search entities',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _error != null
                  ? Center(child: Text(_error!))
                  : filtered == null
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? const Center(child: Text('No matching entities'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final entity = filtered[index];
                        final id = entity['id']!;
                        return CheckboxListTile(
                          title: Text(entity['name']!),
                          subtitle: Text(entity['detail']!),
                          value: _selected.contains(id),
                          onChanged: (checked) => setState(() {
                            if (checked == true) {
                              _selected.add(id);
                            } else {
                              _selected.remove(id);
                            }
                          }),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _entities == null
              ? null
              : () => setState(() {
                  _selected.addAll(_entities!.map((entity) => entity['id']!));
                }),
          child: const Text('Select all'),
        ),
        TextButton(
          onPressed: _entities == null ? null : () => setState(_selected.clear),
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _entities == null
              ? null
              : () => Navigator.pop(context, _selected),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
