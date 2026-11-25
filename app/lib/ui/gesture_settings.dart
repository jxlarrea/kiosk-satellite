import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../l10n/messages.dart';
import '../l10n/gesture_messages.dart';
import '../managers/gestures/gesture_mappings.dart';
import '../managers/settings/definitions.dart' as defs;
import 'gesture_action_picker.dart';
import 'ground_control_settings.dart' show VoiceMatchPeopleRow;
import 'ground_control_tag.dart' show settingTitle;
import 'hand_gesture_tester.dart';
import 'kit.dart';
import 'settings_search.dart';

/// The Gestures page (issue #99): the list of gestures and the
/// actions they trigger. Mirrored by the remote admin's Gestures page.
///
/// The editor is two-staged on purpose: the main dialog owns the trigger,
/// and each action type configures itself in its own dialog, so a URL
/// action can be one field while a service call is four.
class GestureSettingsPanel extends StatefulWidget {
  const GestureSettingsPanel({super.key, required this.container});

  final AppContainer container;

  @override
  State<GestureSettingsPanel> createState() => _GestureSettingsPanelState();
}

const _triggerTypes = <(String, String)>[
  ('corner_taps', 'Taps in a corner'),
  ('corner_hold', 'Hold a corner'),
  ('finger_taps', 'Multi-finger tap'),
  ('finger_hold', 'Multi-finger hold'),
  ('corner_sequence', 'Corner sequence'),
  ('claps', 'Claps'),
  ('fingers', 'Show fingers'),
  ('plugin', 'Plugin trigger'),
];

class _GestureSettingsPanelState extends State<GestureSettingsPanel> {
  AppContainer get c => widget.container;
  double? _handHoldDrag;

  List<GestureMapping> get _mappings =>
      decodeGestureMappings(c.settings.get(defs.gestureMappings));

  Future<void> _save(List<GestureMapping> mappings) async {
    await c.settings.setFromJson(
      defs.gestureMappings.key,
      jsonEncode([for (final m in mappings) m.toJson()]),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mappings = _mappings;
    final suppressed =
        c.settings.get(defs.kioskEnabled) &&
        c.settings.get(defs.kioskDisableGestures);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (suppressed)
          Card(
            margin: const EdgeInsets.only(top: 20),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(gestureText(context, 'Gestures are off')),
              subtitle: Text(
                gestureText(
                  context,
                  'Disable Gestures is on in Kiosk Mode settings.',
                ),
              ),
            ),
          ),
        SectionHeading(gestureText(context, 'Gestures')),
        SettingsCard(
          children: [
            if (mappings.isEmpty)
              ListTile(
                leading: Icon(Icons.gesture),
                title: Text(gestureText(context, 'No gestures configured')),
                subtitle: Text(
                  gestureText(
                    context,
                    'A gesture triggers its action without any visible '
                    'control.',
                  ),
                ),
              ),
            for (final mapping in mappings)
              ListTile(
                // Claps are heard and hands are seen, not touched; the
                // row icon says which.
                leading: Icon(switch (mapping.triggerType) {
                  'claps' => Icons.sign_language_outlined,
                  'fingers' => Icons.waving_hand_outlined,
                  'plugin' => Icons.extension_outlined,
                  'button' => Icons.radio_button_checked,
                  _ => Icons.gesture,
                }),
                title: Text(localizedGestureTrigger(context, mapping.trigger)),
                subtitle: Text(localizedGestureAction(context, mapping.action)),
                onTap: () => _edit(mapping),
                trailing: IconButton(
                  tooltip: gestureText(context, 'Delete gesture'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(mapping),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(gestureText(context, 'Add gesture')),
              subtitle: Text(
                gestureText(
                  context,
                  'Pick a gesture and the action it triggers.',
                ),
              ),
              onTap: () => _edit(null),
            ),
          ],
        ),
        GroupNote(
          gestureText(
            context,
            'Gestures are observed, not blocked: the taps also reach the '
            'dashboard, so corners and multi-finger shapes keep them from '
            'firing anything there.',
          ),
        ),
        SectionHeading(gestureText(context, 'Clapper')),
        SettingsCard(
          children: [
            SearchLandingTarget(
              id: defs.clapStrictness.key,
              child: DropdownRow<String>(
                title: defs.clapStrictness.localizedTitle(context),
                description: defs.clapStrictness.localizedDescription(context),
                value: c.settings.get(defs.clapStrictness),
                options: [
                  ('standard', gestureText(context, 'Standard')),
                  ('strict', gestureText(context, 'Strict')),
                  ('large_room', gestureText(context, 'Large room')),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  await c.settings.setFromJson(defs.clapStrictness.key, value);
                  if (mounted) setState(() {});
                },
              ),
            ),
          ],
        ),
        SectionHeading(gestureText(context, 'Hand Gestures')),
        SettingsCard(
          children: [
            SearchLandingTarget(
              id: defs.handGestureHoldSeconds.key,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      defs.handGestureHoldSeconds.localizedTitle(context),
                    ),
                    subtitle: Text(
                      defs.handGestureHoldSeconds.localizedDescription(context),
                    ),
                    trailing: Text(
                      localizedHandHoldDuration(
                        context,
                        _handHoldDrag ??
                            c.settings.get(defs.handGestureHoldSeconds),
                      ),
                    ),
                  ),
                  Slider(
                    value:
                        _handHoldDrag ??
                        c.settings
                            .get(defs.handGestureHoldSeconds)
                            .toDouble()
                            .clamp(0, 3),
                    min: 0,
                    max: 3,
                    divisions: 6,
                    label: localizedHandHoldDuration(
                      context,
                      _handHoldDrag ??
                          c.settings.get(defs.handGestureHoldSeconds),
                    ),
                    semanticFormatterCallback: (value) =>
                        localizedHandHoldDuration(context, value),
                    onChanged: (value) => setState(() => _handHoldDrag = value),
                    onChangeEnd: (value) async {
                      await c.settings.set(defs.handGestureHoldSeconds, value);
                      if (mounted) setState(() => _handHoldDrag = null);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        // Ground Control Vision Match: whose fingers run Show fingers
        // gestures, with Face Recognition on. Mirrored on the remote.
        if (c.settings.visible(defs.gesturesFaceWho)) ...[
          SectionHeading(gestureText(context, 'Ground Control Vision Match')),
          SettingsCard(
            children: [
              SearchLandingTarget(
                id: defs.gesturesFaceWho.key,
                child: DropdownRow<String>(
                  title: defs.gesturesFaceWho.localizedTitle(context),
                  titleWidget: settingTitle(context, defs.gesturesFaceWho),
                  description: defs.gesturesFaceWho.localizedDescription(
                    context,
                  ),
                  value: c.settings.get(defs.gesturesFaceWho),
                  options: [
                    for (final o in defs.gesturesFaceWho.options!)
                      (
                        o,
                        defs.gesturesFaceWho.localizedOption(
                          context,
                          o,
                          defs.gesturesFaceWho.optionLabels![o]!,
                        ),
                      ),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    await c.settings.setFromJson(
                      defs.gesturesFaceWho.key,
                      value,
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
              if (c.settings.visible(defs.gesturesFacePeople))
                SearchLandingTarget(
                  id: defs.gesturesFacePeople.key,
                  child: VoiceMatchPeopleRow(
                    container: c,
                    def: defs.gesturesFacePeople,
                  ),
                ),
            ],
          ),
        ],
        // The tester: a live look at the fingers the camera reads, for
        // learning how to hold a hand before (or after) mapping one.
        SectionHeading(gestureText(context, 'Hand Gesture Tester')),
        SearchLandingTarget(
          id: 'x:hand_gesture_tester',
          child: SettingsCard(children: [HandGestureTesterTile(container: c)]),
        ),
      ],
    );
  }

  Future<void> _delete(GestureMapping mapping) async {
    final confirmed = await showConfirmDialog(
      context,
      title: gestureText(context, 'Delete gesture?'),
      message: l10n(context).gestureDeleteMessage(
        localizedGestureTrigger(context, mapping.trigger),
        localizedGestureAction(context, mapping.action),
      ),
      confirmLabel: gestureText(context, 'Delete'),
      destructive: true,
    );
    if (!confirmed) return;
    await _save([..._mappings]..removeWhere((m) => m.id == mapping.id));
  }

  /// The main editor: trigger shape plus the chosen action's summary row.
  Future<void> _edit(GestureMapping? existing) async {
    var type = existing?.triggerType ?? 'corner_taps';
    var corner = '${existing?.trigger['corner'] ?? 'tl'}';
    var taps = (existing?.trigger['taps'] as num?)?.toInt() ?? 2;
    var fingers = (existing?.trigger['fingers'] as num?)?.toInt() ?? 3;
    var fingerTaps = type == 'finger_taps'
        ? ((existing?.trigger['taps'] as num?)?.toInt() ?? 1)
        : 1;
    var holdMs = (existing?.trigger['holdMs'] as num?)?.toInt() ?? 1500;
    var claps = (existing?.trigger['claps'] as num?)?.toInt() ?? 2;
    var fingerCount = (existing?.trigger['fingers'] as num?)?.toInt() ?? 5;
    final sequence = [
      for (final s in (existing?.trigger['sequence'] as List?) ?? const [])
        '$s',
    ];
    Map<String, Object?>? action = existing?.action;
    // Running plugins' triggers, plus the saved one so a mapping whose
    // plugin is off still opens with its trigger selected.
    String pluginKey(Map<String, Object?> t) =>
        '${t['pluginId']}/${t['trigger']}';
    final pluginTriggers = <String, Map<String, Object?>>{
      if (type == 'plugin') pluginKey(existing!.trigger): existing.trigger,
      for (final t in c.plugins.triggers)
        if (t['available'] == true)
          pluginKey(t): {
            'type': 'plugin',
            'pluginId': t['pluginId'],
            'trigger': t['trigger'],
            'pluginName': t['pluginName'],
            'title': t['title'],
          },
    };
    String? pluginTrigger = type == 'plugin'
        ? pluginKey(existing!.trigger)
        : pluginTriggers.keys.firstOrNull;

    if (!cornerNames.containsKey(corner)) corner = 'tl';

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final holdSeconds = holdMs / 1000;
          final canSave =
              action != null &&
              (type != 'corner_sequence' || sequence.length >= 2) &&
              (type != 'plugin' || pluginTrigger != null);
          return AlertDialog(
            title: Text(
              existing == null
                  ? gestureText(context, 'Add gesture')
                  : gestureText(context, 'Edit gesture'),
            ),
            content: SizedBox(
              width: 480,
              child: EdgeFade(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [
                      LabeledField(
                        label: gestureText(context, 'Gesture'),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: type,
                          decoration: const InputDecoration(),
                          items: [
                            // Show fingers needs a hand runtime this
                            // Android version cannot load (issue #331):
                            // not offered, though an existing mapping
                            // still opens for editing.
                            for (final (value, label) in _triggerTypes)
                              if (value != 'fingers' ||
                                  type == 'fingers' ||
                                  !c.deviceCamera.handsKnownUnsupported)
                                DropdownMenuItem(
                                  value: value,
                                  child: Text(gestureText(context, label)),
                                ),
                          ],
                          onChanged: (value) =>
                              setDialogState(() => type = value ?? type),
                        ),
                      ),
                      if (type == 'corner_taps' || type == 'corner_hold')
                        LabeledField(
                          label: gestureText(context, 'Corner'),
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: corner,
                            decoration: const InputDecoration(),
                            items: [
                              for (final entry in cornerNames.entries)
                                DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(
                                    localizedGestureCorner(context, entry.key),
                                  ),
                                ),
                            ],
                            onChanged: (value) =>
                                setDialogState(() => corner = value ?? corner),
                          ),
                        ),
                      if (type == 'corner_taps')
                        LabeledField(
                          label: gestureText(context, 'Taps'),
                          child: DropdownButtonFormField<int>(
                            initialValue: taps.clamp(2, 4),
                            decoration: const InputDecoration(),
                            items: [
                              DropdownMenuItem(
                                value: 2,
                                child: Text(gestureText(context, '2 taps')),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text(gestureText(context, '3 taps')),
                              ),
                              DropdownMenuItem(
                                value: 4,
                                child: Text(gestureText(context, '4 taps')),
                              ),
                            ],
                            onChanged: (value) =>
                                setDialogState(() => taps = value ?? taps),
                          ),
                        ),
                      if (type == 'finger_taps' || type == 'finger_hold')
                        LabeledField(
                          label: gestureText(context, 'Fingers'),
                          child: DropdownButtonFormField<int>(
                            initialValue: fingers.clamp(2, 3),
                            decoration: const InputDecoration(),
                            items: [
                              DropdownMenuItem(
                                value: 2,
                                child: Text(gestureText(context, '2 fingers')),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text(gestureText(context, '3 fingers')),
                              ),
                            ],
                            onChanged: (value) => setDialogState(
                              () => fingers = value ?? fingers,
                            ),
                          ),
                        ),
                      if (type == 'finger_taps')
                        LabeledField(
                          label: gestureText(context, 'Taps'),
                          child: DropdownButtonFormField<int>(
                            initialValue: fingerTaps.clamp(1, 2),
                            decoration: const InputDecoration(),
                            items: [
                              DropdownMenuItem(
                                value: 1,
                                child: Text(gestureText(context, 'Single tap')),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text(gestureText(context, 'Double tap')),
                              ),
                            ],
                            onChanged: (value) => setDialogState(
                              () => fingerTaps = value ?? fingerTaps,
                            ),
                          ),
                        ),
                      if (type == 'corner_hold' || type == 'finger_hold') ...[
                        Text(
                          l10n(
                            context,
                          ).gestureHoldDuration(holdSeconds.toStringAsFixed(2)),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Slider(
                          value: holdSeconds.clamp(0.5, 3),
                          min: 0.5,
                          max: 3,
                          divisions: 10,
                          onChanged: (value) => setDialogState(
                            () => holdMs = (value * 1000).round(),
                          ),
                        ),
                      ],
                      if (type == 'fingers')
                        LabeledField(
                          label: gestureText(context, 'Fingers'),
                          child: DropdownButtonFormField<int>(
                            initialValue: fingerCount.clamp(1, 5),
                            decoration: const InputDecoration(),
                            items: [
                              DropdownMenuItem(
                                value: 1,
                                child: Text(gestureText(context, '1 finger')),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text(gestureText(context, '2 fingers')),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text(gestureText(context, '3 fingers')),
                              ),
                              DropdownMenuItem(
                                value: 4,
                                child: Text(gestureText(context, '4 fingers')),
                              ),
                              DropdownMenuItem(
                                value: 5,
                                child: Text(
                                  gestureText(context, 'Open hand (5)'),
                                ),
                              ),
                            ],
                            onChanged: (value) => setDialogState(
                              () => fingerCount = value ?? fingerCount,
                            ),
                          ),
                        ),
                      if (type == 'fingers')
                        Text(
                          c.deviceCamera.handsKnownUnsupported
                              ? gestureText(
                                  context,
                                  cameraText(
                                    context,
                                    c.deviceCamera.visionHint ??
                                        'Not available on this device.',
                                  ),
                                )
                              : gestureText(
                                  context,
                                  'Requires the camera enabled and a well '
                                  'lit environment.',
                                ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (type == 'claps') ...[
                        LabeledField(
                          label: gestureText(context, 'Claps'),
                          child: DropdownButtonFormField<int>(
                            initialValue: claps.clamp(2, 4),
                            decoration: const InputDecoration(),
                            items: [
                              DropdownMenuItem(
                                value: 2,
                                child: Text(gestureText(context, '2 claps')),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text(gestureText(context, '3 claps')),
                              ),
                              DropdownMenuItem(
                                value: 4,
                                child: Text(gestureText(context, '4 claps')),
                              ),
                            ],
                            onChanged: (value) =>
                                setDialogState(() => claps = value ?? claps),
                          ),
                        ),
                        Text(
                          gestureText(
                            context,
                            'Claps are heard through the microphone, with or '
                            'without wake word detection.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (type == 'plugin')
                        pluginTriggers.isEmpty
                            ? Text(
                                gestureText(
                                  context,
                                  'Enable a plugin with triggers in Plugin '
                                  'Manager first.',
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              )
                            : LabeledField(
                                label: gestureText(context, 'Trigger'),
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: pluginTrigger,
                                  decoration: const InputDecoration(),
                                  items: [
                                    for (final entry in pluginTriggers.entries)
                                      DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(
                                          describePluginTrigger(entry.value),
                                        ),
                                      ),
                                  ],
                                  onChanged: (value) => setDialogState(
                                    () =>
                                        pluginTrigger = value ?? pluginTrigger,
                                  ),
                                ),
                              ),
                      if (type == 'corner_sequence') ...[
                        Text(
                          sequence.isEmpty
                              ? gestureText(
                                  context,
                                  'Tap the corners in order (2 to 8 steps).',
                                )
                              : sequence
                                    .map(
                                      (s) => localizedGestureCorner(context, s),
                                    )
                                    .join(' > '),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final entry in cornerNames.entries)
                              OutlinedButton(
                                onPressed: sequence.length >= 8
                                    ? null
                                    : () => setDialogState(
                                        () => sequence.add(entry.key),
                                      ),
                                child: Text(
                                  localizedGestureCorner(context, entry.key),
                                ),
                              ),
                            IconButton(
                              tooltip: gestureText(context, 'Remove last step'),
                              icon: const Icon(Icons.backspace_outlined),
                              onPressed: sequence.isEmpty
                                  ? null
                                  : () => setDialogState(
                                      () => sequence.removeLast(),
                                    ),
                            ),
                          ],
                        ),
                      ],
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.play_circle_outline),
                        title: Text(
                          action == null
                              ? gestureText(context, 'Choose an action')
                              : localizedGestureAction(context, action!),
                        ),
                        subtitle: Text(
                          action == null
                              ? gestureText(
                                  context,
                                  'What this gesture triggers.',
                                )
                              : gestureText(context, 'Tap to change.'),
                        ),
                        onTap: () async {
                          final picked = await GestureActionPicker(
                            context,
                            c,
                          ).pick(action);
                          if (picked != null) {
                            setDialogState(() => action = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(gestureText(context, 'Cancel')),
              ),
              FilledButton(
                onPressed: canSave ? () => Navigator.pop(context, true) : null,
                child: Text(gestureText(context, 'Save')),
              ),
            ],
          );
        },
      ),
    );
    if (submitted != true || action == null) return;

    final trigger = <String, Object?>{
      if (type == 'plugin') ...pluginTriggers[pluginTrigger]!,
      'type': type,
      if (type == 'corner_taps' || type == 'corner_hold') 'corner': corner,
      if (type == 'corner_taps') 'taps': taps,
      if (type == 'finger_taps' || type == 'finger_hold') 'fingers': fingers,
      if (type == 'finger_taps') 'taps': fingerTaps,
      if (type == 'corner_hold' || type == 'finger_hold') 'holdMs': holdMs,
      if (type == 'corner_sequence') 'sequence': sequence,
      if (type == 'claps') 'claps': claps,
      if (type == 'fingers') 'fingers': fingerCount,
    };
    final mapping = GestureMapping(
      id: existing?.id ?? 'g${DateTime.now().millisecondsSinceEpoch}',
      trigger: trigger,
      action: action!,
    );
    final mappings = [..._mappings];
    final index = mappings.indexWhere((m) => m.id == mapping.id);
    if (index >= 0) {
      mappings[index] = mapping;
    } else {
      mappings.add(mapping);
    }
    await _save(mappings);
  }
}
