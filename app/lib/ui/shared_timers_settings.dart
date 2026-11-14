import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../l10n/messages.dart';
import '../managers/settings/definitions.dart' as defs;
import '../managers/voice_timers/shared_timers_manager.dart';
import 'kit.dart';

/// Settings > Voice Satellite > Timers > Share with: the kiosks this one
/// shares its timers with, by name, opening a list of the kiosks on the
/// network with a checkbox each. Mirrored on the remote admin
/// (vs_native.js).
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
  Map<String, Object?> _state = const {};

  @override
  void initState() {
    super.initState();
    _sub = c.bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.voiceTimersShareWith.key && mounted) setState(() {});
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<Map<String, Object?>> _load() async {
    final r = await c.commands.execute('sharedTimers', const {});
    final data = r.data;
    final state = r.ok && data is Map
        ? data.cast<String, Object?>()
        : const <String, Object?>{};
    if (mounted) setState(() => _state = state);
    return state;
  }

  /// The kiosks on the network, then the picked ones that are not on it
  /// right now, so a pick is never lost while its kiosk is off.
  List<(SharedTimerTarget, bool)> _choices(Map<String, Object?> state) {
    final found = <SharedTimerTarget>[
      for (final k in (state['kiosks'] as List?) ?? const [])
        if (k is Map && '${k['id'] ?? ''}'.isNotEmpty)
          SharedTimerTarget('${k['id']}', '${k['name'] ?? ''}'),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final ids = {for (final k in found) k.id};
    return [
      for (final k in found) (k, true),
      for (final t in c.sharedTimers.targets)
        if (!ids.contains(t.id)) (t, false),
    ];
  }

  Future<void> _pick() async {
    final choices = _choices(await _load());
    if (!mounted) return;
    final s = l10n(context);
    final chosen = {for (final t in c.sharedTimers.targets) t.id};
    final picked = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(defs.voiceTimersShareWith.localizedTitle(ctx)),
          contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
          content: SizedBox(
            width: 480,
            child: choices.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Text(s.voiceTimersShareEmpty),
                  )
                : EdgeFade(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (kiosk, online) in choices)
                            CheckboxListTile(
                              key: ValueKey('share-with-${kiosk.id}'),
                              value: chosen.contains(kiosk.id),
                              title: Text(
                                kiosk.name.isEmpty ? kiosk.id : kiosk.name,
                              ),
                              subtitle: online
                                  ? null
                                  : Text(s.voiceTimersShareOffline),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  chosen.add(kiosk.id);
                                } else {
                                  chosen.remove(kiosk.id);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.commonCancel),
            ),
            if (choices.isNotEmpty)
              FilledButton(
                onPressed: () => Navigator.pop(ctx, chosen),
                child: Text(s.commonSave),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await c.settings.set(
      defs.voiceTimersShareWith,
      SharedTimerTarget.encode([
        for (final (kiosk, _) in choices)
          if (picked.contains(kiosk.id)) kiosk,
      ]),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    final names = {
      for (final k in (_state['kiosks'] as List?) ?? const [])
        if (k is Map) '${k['id']}': '${k['name'] ?? ''}',
    };
    final picked = [
      for (final t in c.sharedTimers.targets)
        (names[t.id] ?? t.name).isEmpty ? t.id : (names[t.id] ?? t.name),
    ];
    return SettingsRow(
      title: Text(defs.voiceTimersShareWith.localizedTitle(context)),
      subtitle: Text(
        picked.isEmpty ? s.voiceTimersShareNone : picked.join(', '),
      ),
      trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
      onTap: _pick,
    );
  }
}
