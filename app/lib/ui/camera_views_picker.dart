import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/camera/models.dart';
import 'kit.dart';

/// Chooses the camera views the Camera Streams screensaver cycles through,
/// in a dialog like the view editor under Camera Streams: the chosen ones
/// on top in rotation order, draggable, the rest waiting to be added.
/// Views without cameras are left out: there would be nothing to show.
/// Returns the chosen ids on Save, null when cancelled.
Future<List<String>?> showCameraViewsPicker(
  BuildContext context, {
  required AppContainer container,
  required List<String> initial,
}) async {
  final views = [
    for (final view in container.camera.config.views)
      if (view.cameraIds.isNotEmpty) view,
  ];
  // Ids that no longer name a view with cameras are dropped on the way in,
  // so the saved list only ever holds what the screensaver can show.
  final chosen = [
    for (final id in initial)
      if (views.any((view) => view.id == id)) id,
  ];
  CameraViewConfig viewOf(String id) =>
      views.firstWhere((view) => view.id == id);
  String cameras(CameraViewConfig view) =>
      '${view.cameraIds.length} camera'
      '${view.cameraIds.length == 1 ? '' : 's'}';
  Widget label(BuildContext context, String text) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );

  final submitted = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final available = [
          for (final view in views)
            if (!chosen.contains(view.id)) view,
        ];
        return AlertDialog(
          title: const Text('Camera views'),
          content: SizedBox(
            width: 640,
            child: EdgeFade(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (views.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No camera view has cameras yet. Add one under '
                          'Camera Streams.',
                        ),
                      ),
                    if (chosen.isNotEmpty) ...[
                      label(context, 'In the rotation (drag to reorder)'),
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        // onReorderItem: newIndex is already adjusted for
                        // the removal, unlike the deprecated onReorder.
                        onReorderItem: (oldIndex, newIndex) => setDialogState(
                          () {
                            chosen.insert(newIndex, chosen.removeAt(oldIndex));
                          },
                        ),
                        children: [
                          for (final (index, id) in chosen.indexed)
                            SettingsRow(
                              key: ValueKey(id),
                              contentPadding: EdgeInsets.zero,
                              leading: ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle),
                              ),
                              title: Text(viewOf(id).name),
                              subtitle: Text(
                                'Position ${index + 1} · '
                                '${cameras(viewOf(id))}',
                              ),
                              // A tablet has no drag: the same reordering,
                              // one step at a time.
                              trailing: OrderActions(
                                first: index == 0,
                                last: index == chosen.length - 1,
                                onUp: () => setDialogState(
                                  () => chosen.insert(
                                    index - 1,
                                    chosen.removeAt(index),
                                  ),
                                ),
                                onDown: () => setDialogState(
                                  () => chosen.insert(
                                    index + 1,
                                    chosen.removeAt(index),
                                  ),
                                ),
                                onRemove: () => setDialogState(
                                  () => chosen.removeAt(index),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (available.isNotEmpty) ...[
                      label(context, 'Available'),
                      for (final view in available)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.videocam_outlined),
                          title: Text(view.name),
                          subtitle: Text(cameras(view)),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () =>
                              setDialogState(() => chosen.add(view.id)),
                        ),
                    ],
                  ],
                ),
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
        );
      },
    ),
  );
  return submitted == true ? chosen : null;
}
