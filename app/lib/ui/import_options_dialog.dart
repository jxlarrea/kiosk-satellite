import 'package:flutter/material.dart';

/// What a configuration import should do about the two things a backup
/// carries that belong to one specific device (issue #25): its identity
/// (device name + MQTT device id) and its page data (which includes the
/// Voice Satellite selection).
typedef ImportOptions = ({bool adoptIdentity, bool importLocalStorage});

/// Ask the two import questions. Returns null when cancelled.
///
/// The defaults track the choice: replacing the original device pulls its
/// dashboard data along, a new device starts with its own, and a touched
/// checkbox stops following.
Future<ImportOptions?> showImportOptionsDialog(
  BuildContext context, {
  String? backupDeviceName,
}) {
  var adopt = false;
  var local = false;
  var localTouched = false;
  final replaceLabel =
      (backupDeviceName == null || backupDeviceName.trim().isEmpty)
          ? 'Replace the original device'
          : 'Replace "${backupDeviceName.trim()}"';
  return showDialog<ImportOptions>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Import configuration'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Replace this device's settings with the file's? The page "
                'may reload.',
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: [
                  const ButtonSegment(
                    value: false,
                    label: Text('Set up as new device'),
                  ),
                  ButtonSegment(value: true, label: Text(replaceLabel)),
                ],
                selected: {adopt},
                onSelectionChanged: (selection) => setState(() {
                  adopt = selection.first;
                  if (!localTouched) local = adopt;
                }),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  adopt
                      ? 'Keeps the backup\'s name and MQTT identity; the '
                          'original device must stay offline.'
                      : 'Keeps its own name and MQTT identity, so both '
                          'devices can run.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: local,
                onChanged: (v) => setState(() {
                  local = v == true;
                  localTouched = true;
                }),
                title: const Text('Restore dashboard data'),
                subtitle: const Text(
                  'Includes the Voice Satellite selection; two devices must '
                  'not share one satellite.',
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
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              (adoptIdentity: adopt, importLocalStorage: local),
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    ),
  );
}
