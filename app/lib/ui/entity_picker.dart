import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import 'kit.dart';

/// Picks one Home Assistant entity by searching for it: the At a Glance
/// picker's search, without the chosen list, for the places that want a
/// single entity (the entity widget). Resolves to (entity_id, name) when
/// a result is tapped, null when dismissed.
///
/// Search runs against Home Assistant rather than a typed entity id, for
/// the same reason the row's picker does: an entity id is the one thing
/// nobody remembers, and a widget pointed at something that does not
/// exist shows nothing at all.
Future<(String, String)?> pickHomeAssistantEntity(
  BuildContext context,
  AppContainer container, {
  String title = 'Entity',
}) => showDialog<(String, String)>(
  context: context,
  builder: (context) => _EntityPickerDialog(container: container, title: title),
);

class _EntityPickerDialog extends StatefulWidget {
  const _EntityPickerDialog({required this.container, required this.title});

  final AppContainer container;
  final String title;

  @override
  State<_EntityPickerDialog> createState() => _EntityPickerDialogState();
}

class _EntityPickerDialogState extends State<_EntityPickerDialog> {
  final _query = TextEditingController();
  List<Map<String, Object?>> _results = const [];
  Timer? _debounce;
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  /// Nothing is listed until something is typed: the unfiltered list is
  /// every entity in the instance, and a full state fetch to produce it.
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
    // A newer search won while this one was out.
    if (_query.text.trim() != query.trim()) return;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _query,
              autofocus: true,
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
            const SizedBox(height: 8),
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
                          final name = '${entity['name'] ?? id}';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(name),
                            subtitle: Text('$id · ${entity['state']}'),
                            onTap: () => Navigator.pop(context, (id, name)),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
