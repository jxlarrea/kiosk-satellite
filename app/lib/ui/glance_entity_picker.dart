import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/settings/definitions.dart';

/// Chooses the entities the At a Glance row shows: the chosen ones on top in
/// the order they will appear, a search below for adding more.
///
/// Search runs against Home Assistant rather than a typed entity id, because
/// an entity id is the one thing nobody remembers and the whole feature is
/// worthless if it points at something that does not exist.
class GlanceEntityPicker extends StatefulWidget {
  const GlanceEntityPicker({
    super.key,
    required this.container,
    required this.initial,
  });

  final AppContainer container;
  final List<Map<String, Object?>> initial;

  @override
  State<GlanceEntityPicker> createState() => _GlanceEntityPickerState();
}

class _GlanceEntityPickerState extends State<GlanceEntityPicker> {
  late final List<Map<String, Object?>> _chosen = [...widget.initial];
  final _query = TextEditingController();
  List<Map<String, Object?>> _results = const [];
  Timer? _debounce;
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    // One search per pause, not per keystroke: each is a full state fetch.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() {
      _searching = true;
      _error = null;
    });
    final result = await widget.container.commands.execute('haSearchEntities', {
      'query': query,
    });
    if (!mounted) return;
    setState(() {
      _searching = false;
      if (!result.ok) {
        _error = result.error ?? 'Could not reach Home Assistant';
        _results = const [];
        return;
      }
      _results = [
        for (final item in (result.data as List? ?? const []))
          if (item is Map) item.cast<String, Object?>(),
      ];
    });
  }

  bool _isChosen(String entityId) =>
      _chosen.any((entity) => entity['entity_id'] == entityId);

  @override
  Widget build(BuildContext context) {
    final full = _chosen.length >= screensaverGlanceMax;
    return Scaffold(
      appBar: AppBar(
        title: const Text('At a glance'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _chosen),
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_chosen.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Showing (drag to reorder)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (oldIndex, newIndex) => setState(() {
                _chosen.insert(newIndex, _chosen.removeAt(oldIndex));
              }),
              children: [
                for (final (index, entity) in _chosen.indexed)
                  ListTile(
                    key: ValueKey(entity['entity_id']),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    title: Text('${entity['name']}'),
                    subtitle: Text('${entity['entity_id']}'),
                    trailing: IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => setState(() => _chosen.removeAt(index)),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _query,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                labelText: 'Search entities',
                hintText: 'Name or entity id',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          if (full)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'That is the most the row can show. Remove one to add '
                'another.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final entity = _results[index];
                      final id = '${entity['entity_id']}';
                      final chosen = _isChosen(id);
                      return ListTile(
                        title: Text('${entity['name']}'),
                        subtitle: Text('$id · ${entity['state']}'),
                        trailing: Icon(
                          chosen
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                        ),
                        enabled: chosen || !full,
                        onTap: () => setState(() {
                          if (chosen) {
                            _chosen.removeWhere((e) => e['entity_id'] == id);
                          } else if (_chosen.length < screensaverGlanceMax) {
                            _chosen.add({
                              'entity_id': id,
                              'name': entity['name'],
                            });
                          }
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
