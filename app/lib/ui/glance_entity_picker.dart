import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/settings/definitions.dart';
import 'entity_picker.dart';
import 'kit.dart';

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

  /// Nothing is listed until something is typed. The unfiltered list is
  /// every entity in the instance — thousands of rows nobody asked to
  /// browse, and a full state fetch to produce them.

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = const [];
        _searching = false;
        _error = null;
      });
      return;
    }
    // One search per pause, not per keystroke: each is a full state fetch.
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
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

  /// One chosen entity's editable pieces in a single dialog: the name the
  /// row shows (issue #206) — a custom one, or the Home Assistant name when
  /// the field is left empty — and what it displays, its state (the default)
  /// or one of its attributes (issue #132), picked from the entity's live
  /// attributes in the shared picker. The same dialog shape as the entity
  /// widget's, so the two read alike.
  Future<void> _edit(int index) async {
    final entity = _chosen[index];
    final controller = TextEditingController(
      text: '${entity['custom_name'] ?? ''}',
    );
    var attribute = entity['attribute'] as String? ?? '';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${entity['name']}'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                LabeledField(
                  label: 'Name',
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '${entity['name']}',
                      helperText: 'Leave empty to use the Home Assistant name.',
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Displayed value'),
                  subtitle: Text(attribute.isEmpty ? 'State' : attribute),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await pickEntityAttribute(
                        context,
                        widget.container,
                        entityId: '${entity['entity_id']}',
                        current: attribute,
                      );
                      if (picked != null) {
                        setDialogState(() => attribute = picked);
                      }
                    },
                    child: const Text('Choose'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (submitted != true) return;
    setState(() {
      if (name.isEmpty) {
        entity.remove('custom_name');
      } else {
        entity['custom_name'] = name;
      }
      if (attribute.isEmpty) {
        entity.remove('attribute');
      } else {
        entity['attribute'] = attribute;
      }
    });
  }

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
                  SettingsRow(
                    key: ValueKey(entity['entity_id']),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    title: Text('${entity['custom_name'] ?? entity['name']}'),
                    subtitle: Text(
                      entity['attribute'] == null
                          ? '${entity['entity_id']}'
                          : '${entity['entity_id']} · '
                                '${entity['attribute']}',
                    ),
                    // Tapping the row edits it; the actions are for what
                    // editing is not. A tablet has no drag: the same
                    // reordering, one step at a time.
                    onTap: () => _edit(index),
                    trailing: OrderActions(
                      first: index == 0,
                      last: index == _chosen.length - 1,
                      onUp: () => setState(
                        () =>
                            _chosen.insert(index - 1, _chosen.removeAt(index)),
                      ),
                      onDown: () => setState(
                        () =>
                            _chosen.insert(index + 1, _chosen.removeAt(index)),
                      ),
                      onRemove: () => setState(() => _chosen.removeAt(index)),
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
                : _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _searching
                            ? 'Searching…'
                            : _query.text.trim().isEmpty
                            ? 'Type to search entities.'
                            : 'Nothing matched.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : EdgeFade(
                    child: ListView.builder(
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
          ),
        ],
      ),
    );
  }
}
