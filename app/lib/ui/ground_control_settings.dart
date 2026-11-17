import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../l10n/messages.dart';
import '../managers/settings/definitions.dart' as defs;
import 'entity_picker.dart';
import 'kit.dart';

/// The Ground Control page's status rows, under Enable Ground Control:
/// whether the kiosk found and signed in to Kiosk Satellite Ground Control,
/// who is enrolled there and Open for its app. Mirrored in the remote admin
/// (ground_control.js).
class GroundControlStatusRow extends StatefulWidget {
  const GroundControlStatusRow({super.key, required this.container});

  final AppContainer container;

  @override
  State<GroundControlStatusRow> createState() => _GroundControlStatusRowState();
}

class _GroundControlStatusRowState extends State<GroundControlStatusRow> {
  StreamSubscription<Object?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.container.bus.on<RemoteStatusChanged>().listen((e) {
      if (e.topic == 'ground-control' && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.container;
    if (!c.settings.get(defs.groundControlEnabled)) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final m = c.groundControl;
    final names = [
      for (final p in m.people) '${p['name'] ?? ''}',
    ].where((n) => n.isNotEmpty).toList();
    final (String word, Color color, String detail) = switch (m.status) {
      'connected' => (
        voiceText(context, 'Connected'),
        scheme.primary,
        names.isEmpty
            ? voiceText(context, 'Nobody is enrolled yet.')
            : names.join(', '),
      ),
      'connecting' => (
        voiceText(context, 'Connecting'),
        scheme.onSurfaceVariant,
        m.baseUrl ?? '',
      ),
      'unreachable' => (
        voiceText(context, 'Not reachable'),
        scheme.tertiary,
        m.baseUrl ?? '',
      ),
      'refused' => (
        voiceText(context, 'Sign-in refused'),
        scheme.tertiary,
        voiceText(context, "Home Assistant refused this kiosk's token."),
      ),
      _ => (
        voiceText(context, 'Searching'),
        scheme.onSurfaceVariant,
        voiceText(context, 'Looking for Ground Control on the network.'),
      ),
    };
    final status = SettingsRow(
      title: Text(voiceText(context, 'Ground Control')),
      subtitle: detail.isEmpty ? null : Text(detail),
      trailing: Text(
        word,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    final app = m.appUrl;
    if (app == null) return status;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        status,
        // The app's page in Home Assistant, or the container's own page,
        // over the dashboard like a tapped dashboard link.
        SettingsRow(
          title: Text(voiceText(context, 'Ground Control app')),
          subtitle: Text(
            voiceText(context, 'People, enrollment, sessions and settings.'),
          ),
          trailing: TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              c.browser.showLinkOverlay(app);
            },
            child: Text(voiceText(context, 'Open')),
          ),
        ),
      ],
    );
  }
}

/// The people Answer can choose: everyone enrolled in Ground Control, then
/// the chosen ones it no longer has, dimmed, so a pick is never lost while
/// Ground Control is away. Mirrored on the remote admin (ground_control.js).
PickSpec voiceMatchPeopleSpec(BuildContext context, AppContainer container) {
  final strings = l10n(context);
  return PickSpec(
    key: 'voice-match:people',
    loader: () async {
      final found = <PickItem>[
        for (final p in container.groundControl.people)
          if ('${p['id'] ?? ''}'.isNotEmpty)
            PickItem(
              id: '${p['id']}',
              name: '${p['name'] ?? ''}'.isEmpty
                  ? '${p['id']}'
                  : '${p['name']}',
              icon: 'mdi:account',
            ),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      final ids = {for (final p in found) p.id};
      return PickList([
        ...found,
        for (final p in defs.decodeVoiceMatchPeople(
          container.settings.get(defs.voiceMatchPeople),
        ))
          if (!ids.contains(p.id))
            PickItem(
              id: p.id,
              name: p.name.isEmpty ? p.id : p.name,
              state: strings.voiceMatchPeopleGone,
              icon: 'mdi:account',
              available: false,
            ),
      ]);
    },
    searchHint: strings.voiceMatchPeopleSearch,
    noGroup: '',
    byGroupName: false,
    chips: false,
    headings: false,
    ordered: false,
    emptyText: (context) => l10n(context).voiceMatchPeopleEmpty,
  );
}

/// Ground Control Voice Match > People, under Answer on Chosen people: the
/// people this kiosk answers, by name in a box that opens a checkbox list of
/// everyone enrolled. Mirrored on the remote admin (rows.js).
class VoiceMatchPeopleRow extends StatefulWidget {
  const VoiceMatchPeopleRow({super.key, required this.container});

  final AppContainer container;

  @override
  State<VoiceMatchPeopleRow> createState() => _VoiceMatchPeopleRowState();
}

class _VoiceMatchPeopleRowState extends State<VoiceMatchPeopleRow> {
  AppContainer get c => widget.container;
  final _subs = <StreamSubscription<Object?>>[];

  /// The people Ground Control sent last, to reload the list when they change.
  Object? _people;

  @override
  void initState() {
    super.initState();
    _subs
      ..add(
        c.bus.on<SettingChanged>().listen((e) {
          if (e.key == defs.voiceMatchPeople.key && mounted) setState(() {});
        }),
      )
      ..add(
        c.bus.on<RemoteStatusChanged>().listen((e) {
          if (e.topic == 'ground-control' && mounted) setState(() {});
        }),
      );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  List<defs.VoiceMatchPick> get _picks =>
      defs.decodeVoiceMatchPeople(c.settings.get(defs.voiceMatchPeople));

  Future<void> _pick(PickSpec spec) async {
    final ids = await showItemMultiPicker(
      context,
      title: defs.voiceMatchPeople.localizedTitle(context),
      spec: spec,
      selected: [for (final p in _picks) p.id],
    );
    if (ids == null) return;
    final list = PickCatalog.of(spec.key).value;
    // Named from the list, so a renamed person is stored under the new name.
    final stored = {for (final p in _picks) p.id: p.name};
    await c.settings.set(
      defs.voiceMatchPeople,
      defs.encodeVoiceMatchPeople([
        for (final id in ids)
          (id: id, name: list?.find(id)?.name ?? stored[id] ?? ''),
      ]),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final spec = voiceMatchPeopleSpec(context, c);
    if (!identical(_people, c.groundControl.people)) {
      _people = c.groundControl.people;
      PickCatalog.load(spec.key, spec.loader);
    }
    final picks = _picks;
    return ValueListenableBuilder<PickList?>(
      valueListenable: PickCatalog.of(spec.key),
      builder: (context, list, _) {
        final scheme = Theme.of(context).colorScheme;
        final names = [
          for (final p in picks)
            list?.find(p.id)?.name ?? (p.name.isEmpty ? p.id : p.name),
        ];
        final field = ControlBox(
          onTap: () => _pick(spec),
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: picks.isEmpty ? scheme.onSurfaceVariant : scheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  picks.isEmpty
                      ? l10n(context).voiceMatchPeopleNone
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
          title: Text(defs.voiceMatchPeople.localizedTitle(context)),
          stack: true,
          subtitle: Text(defs.voiceMatchPeople.localizedDescription(context)),
          trailing: tightPane(context)
              ? field
              : SizedBox(width: 300, child: field),
        );
      },
    );
  }
}
