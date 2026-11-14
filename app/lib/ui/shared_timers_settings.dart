import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../l10n/messages.dart';
import '../managers/settings/definitions.dart' as defs;
import '../managers/voice_timers/shared_timers_manager.dart';
import 'entity_picker.dart';
import 'kit.dart';

/// The kiosks Share with can pick, for the shared picker: the ones on the
/// network by name with their address, then the picked ones that are not
/// on it right now, dimmed, so a pick is never lost while its kiosk is
/// off. Mirrored on the remote admin (timers.js).
PickSpec shareKiosksSpec(BuildContext context, AppContainer container) {
  final strings = l10n(context);
  return PickSpec(
    key: 'kiosks:share',
    loader: () async {
      final r = await container.commands.execute('sharedTimers', const {});
      final data = r.data;
      if (!r.ok || data is! Map) return null;
      final found = <PickItem>[
        for (final k in (data['kiosks'] as List?) ?? const [])
          if (k is Map && '${k['id'] ?? ''}'.isNotEmpty)
            PickItem(
              id: '${k['id']}',
              name: '${k['name'] ?? ''}'.isEmpty
                  ? '${k['id']}'
                  : '${k['name']}',
              sub: '${k['address'] ?? ''}'.isEmpty ? null : '${k['address']}',
              subMono: true,
              icon: 'mdi:tablet',
            ),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      final ids = {for (final k in found) k.id};
      return PickList([
        ...found,
        for (final t in container.sharedTimers.targets)
          if (!ids.contains(t.id))
            PickItem(
              id: t.id,
              name: t.name.isEmpty ? t.id : t.name,
              state: strings.voiceTimersShareOffline,
              icon: 'mdi:tablet',
              available: false,
            ),
      ]);
    },
    searchHint: strings.voiceTimersShareSearch,
    noGroup: '',
    byGroupName: false,
    chips: false,
    headings: false,
    ordered: false,
    emptyText: (context) => l10n(context).voiceTimersShareEmpty,
  );
}

/// Settings > Timers > Share with: the kiosks this one shares its timers
/// with, by name in a box that opens the shared picker over the kiosks on
/// the network. Mirrored on the remote admin (rows.js).
class SharedTimersShareWithRow extends StatefulWidget {
  const SharedTimersShareWithRow({super.key, required this.container});

  final AppContainer container;

  @override
  State<SharedTimersShareWithRow> createState() =>
      _SharedTimersShareWithRowState();
}

class _SharedTimersShareWithRowState extends State<SharedTimersShareWithRow> {
  AppContainer get c => widget.container;
  StreamSubscription<SettingChanged>? _sub;

  /// Whether the list was asked for yet.
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _sub = c.bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.voiceTimersShareWith.key && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _pick(PickSpec spec) async {
    final ids = await showItemMultiPicker(
      context,
      title: defs.voiceTimersShareWith.localizedTitle(context),
      spec: spec,
      selected: [for (final t in c.sharedTimers.targets) t.id],
    );
    final list = PickCatalog.of(spec.key).value;
    if (ids == null) return;
    // Named from the list, so a renamed kiosk is stored under its new name.
    final stored = {for (final t in c.sharedTimers.targets) t.id: t.name};
    await c.settings.set(
      defs.voiceTimersShareWith,
      SharedTimerTarget.encode([
        for (final id in ids)
          SharedTimerTarget(id, list?.find(id)?.name ?? stored[id] ?? ''),
      ]),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final spec = shareKiosksSpec(context, c);
    if (!_loaded) {
      _loaded = true;
      PickCatalog.load(spec.key, spec.loader);
    }
    final picks = c.sharedTimers.targets;
    return ValueListenableBuilder<PickList?>(
      valueListenable: PickCatalog.of(spec.key),
      builder: (context, list, _) {
        final scheme = Theme.of(context).colorScheme;
        // The name the kiosk has now, or the one stored with the pick.
        final names = [
          for (final t in picks)
            list?.find(t.id)?.name ?? (t.name.isEmpty ? t.id : t.name),
        ];
        final field = ControlBox(
          onTap: () => _pick(spec),
          child: Row(
            children: [
              Icon(
                Icons.tablet_android_outlined,
                size: 20,
                color: picks.isEmpty ? scheme.onSurfaceVariant : scheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  picks.isEmpty
                      ? l10n(context).voiceTimersShareNone
                      : names.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: picks.isEmpty
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        );
        return SettingsRow(
          title: Text(defs.voiceTimersShareWith.localizedTitle(context)),
          stack: true,
          subtitle: Text(
            defs.voiceTimersShareWith.localizedDescription(context),
          ),
          trailing: tightPane(context)
              ? field
              : SizedBox(width: 300, child: field),
        );
      },
    );
  }
}
