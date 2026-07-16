import 'package:flutter/material.dart';

import '../app_container.dart';

/// A Home Assistant media browser, for picking the screensaver's media.
///
/// Drives `media_source/browse_media` over the app's HA-token websocket (the
/// same one that lists dashboards). Folders drill in; a playable leaf — image,
/// video, or a camera from the synthetic `camera` source — is picked and
/// returned. "Use this folder" returns the folder itself, for slideshow
/// cycling. Returns the chosen media-source id, or null if cancelled.
Future<String?> pickMedia(BuildContext context, AppContainer container) {
  return showDialog<String>(
    context: context,
    builder: (_) => _MediaPickerDialog(container: container),
  );
}

class _MediaPickerDialog extends StatefulWidget {
  const _MediaPickerDialog({required this.container});

  final AppContainer container;

  @override
  State<_MediaPickerDialog> createState() => _MediaPickerDialogState();
}

class _Crumb {
  const _Crumb(this.id, this.title);
  final String? id;
  final String title;
}

class _MediaPickerDialogState extends State<_MediaPickerDialog> {
  final List<_Crumb> _trail = [const _Crumb(null, 'Media')];
  Map<String, Object?>? _node;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _open(null, 'Media', push: false);
  }

  Future<void> _open(String? id, String title, {bool push = true}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final node = await widget.container.homeAssistant.browseMedia(id);
    if (!mounted) return;
    if (node == null) {
      setState(() {
        _loading = false;
        _error = 'Could not reach Home Assistant, or the token is missing.';
      });
      return;
    }
    setState(() {
      _node = node;
      _loading = false;
      if (push) _trail.add(_Crumb(id, title));
    });
  }

  void _crumbTo(int index) {
    final crumb = _trail[index];
    _trail.removeRange(index + 1, _trail.length);
    _open(crumb.id, crumb.title, push: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = (_node?['children'] as List?) ?? const [];
    final canExpand = _node?['can_expand'] == true;
    final atRoot = _trail.length <= 1;

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      title: const Text('Choose media'),
      content: SizedBox(
        width: 460,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb trail — tap any level to jump back.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < _trail.length; i++) ...[
                    if (i > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(Icons.chevron_right, size: 16),
                      ),
                    InkWell(
                      onTap: i == _trail.length - 1 ? null : () => _crumbTo(i),
                      child: Text(
                        _trail[i].title,
                        style: TextStyle(
                          color: i == _trail.length - 1
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(_error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: theme.colorScheme.error)),
                          ),
                        )
                      : children.isEmpty
                          ? const Center(child: Text('Nothing here.'))
                          : ListView.builder(
                              itemCount: children.length,
                              itemBuilder: (context, i) =>
                                  _row(children[i] as Map),
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
        // Cycle a whole folder as a slideshow. Not at the root, which is not a
        // real folder.
        if (!atRoot && canExpand)
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, _node?['media_content_id'] as String?),
            child: const Text('Use this folder'),
          ),
      ],
    );
  }

  Widget _row(Map child) {
    final title = child['title'] as String? ?? '?';
    final id = child['media_content_id'] as String?;
    final expand = child['can_expand'] == true;
    final play = child['can_play'] == true;
    return ListTile(
      dense: true,
      leading: Icon(expand
          ? Icons.folder_outlined
          : _isCamera(id)
              ? Icons.videocam_outlined
              : Icons.perm_media_outlined),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: expand ? const Icon(Icons.chevron_right) : null,
      onTap: () {
        // A folder that also plays (rare) prefers drilling in; a pure leaf is
        // the selection.
        if (expand) {
          _open(id, title);
        } else if (play && id != null) {
          Navigator.pop(context, id);
        }
      },
    );
  }

  bool _isCamera(String? id) =>
      id != null && id.startsWith('media-source://camera/');
}
