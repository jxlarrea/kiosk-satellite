import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../managers/fleet/fleet_sync_manager.dart';
import '../managers/settings/definitions.dart' as defs;
import 'kit.dart';
import 'settings_screen.dart'
    show SettingTile, closeSettingsSubpage, openSettingsSubpage;
import 'settings_search.dart';
import 'subpage_icons.dart';
import 'toast.dart';

/// Where the full list of what syncs and what never does lives.
const fleetDocsUrl =
    'https://github.com/jxlarrea/kiosk-satellite/blob/main/docs/fleet.md';

/// The Fleet Management page: one kiosk leads, the others follow. The
/// remote admin draws the same cards from the same `fleetStatus` command.
class FleetSettingsPanel extends StatefulWidget {
  const FleetSettingsPanel({super.key, required this.container});

  final AppContainer container;

  @override
  State<FleetSettingsPanel> createState() => _FleetSettingsPanelState();
}

class _FleetSettingsPanelState extends State<FleetSettingsPanel> {
  Map<String, Object?>? _status;
  StreamSubscription<FleetSyncChanged>? _changes;
  StreamSubscription<SettingChanged>? _settingsSub;
  Timer? _poll;
  bool _busy = false;

  AppContainer get c => widget.container;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _changes = c.bus.on<FleetSyncChanged>().listen((_) => _load());
    _settingsSub = c.bus.on<SettingChanged>().listen((e) {
      if (e.key.startsWith('fleet.') || e.key.startsWith('remote.')) _load();
    });
    // Asking keeps the manager polling its followers at the fast cadence
    // while the page is open; the answer redraws the rows.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _changes?.cancel();
    _settingsSub?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await c.commands.execute('fleetStatus', const {});
    if (!mounted || !r.ok || r.data is! Map) return;
    final status = (r.data as Map).cast<String, Object?>();
    registerProfileGlyphs(status);
    setState(() => _status = status);
  }

  Future<void> _run(
    String command, [
    Map<String, Object?> params = const {},
  ]) async {
    setState(() => _busy = true);
    final r = await c.commands.execute(command, params);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      showToast(
        context,
        title: 'Fleet Management',
        message: r.error,
        kind: ToastKind.error,
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) return const ListTile(title: Text('Loading…'));
    final enabled = status['enabled'] == true;
    final leading = status['leader'] == true;
    final following = status['following'] as Map?;
    final invite = status['invite'] as Map?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!enabled) _setupCard(),
        if (invite != null) ...[
          _inviteCard(invite),
          const SizedBox(height: 16),
        ],
        _leadCard(
          enabled: enabled,
          leading: leading,
          following: following != null,
        ),
        if (enabled && leading) ...[
          const SizedBox(height: 16),
          const SectionHeading('Followers'),
          _followersCard(status),
          const SectionHeading('Profiles'),
          _profilesCard(status),
          _docsNote(),
          const SizedBox(height: 16),
          const SectionHeading('Updates'),
          _updatesCard(status),
        ],
        if (following != null) ...[
          const SizedBox(height: 16),
          const SectionHeading('Leader'),
          _leaderCard(following),
        ],
      ],
    );
  }

  Widget _setupCard() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SettingsCard(
        children: [
          SettingsRow(
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('Fleet Management needs the remote admin'),
            subtitle: Text(
              'Kiosks find each other through it. Turn on Remote management '
              'and Find other kiosks under Device, then come back.',
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ],
  );

  Widget _leadCard({
    required bool enabled,
    required bool leading,
    required bool following,
  }) {
    final canLead = enabled && !following;
    return SettingsCard(
      children: [
        SearchLandingTarget(
          id: defs.fleetLeader.key,
          child: SettingsRow(
            title: const Text('Lead this fleet'),
            subtitle: Text(
              following
                  ? 'A kiosk that follows a leader cannot lead.'
                  : defs.fleetLeader.description,
            ),
            enabled: canLead,
            trailing: Switch(
              value: leading,
              onChanged: canLead
                  ? (v) => c.settings.set(defs.fleetLeader, v)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // ── The leader ──────────────────────────────────────────────────────

  Widget _followersCard(Map<String, Object?> status) {
    final rows = [
      for (final f in (status['followers'] as List? ?? const []))
        if (f is Map) f.cast<String, Object?>(),
    ];
    return SettingsCard(
      children: [
        const SearchLandingTarget(id: 'x:fleet_followers', child: SizedBox()),
        for (final f in rows) _followerRow(f),
        SettingsRow(
          title: const Text('Add a kiosk'),
          subtitle: const Text(
            'Kiosks member of the fleet. A follower must confirm the '
            'invitation on device.',
          ),
          trailing: OutlinedButton.icon(
            onPressed: _busy ? null : _addKiosk,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ),
      ],
    );
  }

  Widget _followerRow(Map<String, Object?> f) {
    final scheme = Theme.of(context).colorScheme;
    final tone = switch (f['tone']) {
      'ok' => scheme.primary,
      'warn' => scheme.tertiary,
      _ => scheme.onSurfaceVariant,
    };
    final phase = '${f['phase']}';
    return SettingsRow(
      leading: const Icon(Icons.tablet_android_outlined),
      title: Text('${f['name']}'),
      subtitle: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${f['address']}'),
          if ('${f['version']}'.isNotEmpty)
            _Tag('${f['version']}', error: phase == 'version'),
          if (f['profile'] != 'default')
            _Tag('${f['profileName']}', accent: true),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${f['status']}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tone),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            enabled: !_busy,
            onSelected: (v) => _followerAction(f, v),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'sync', child: Text('Profile')),
              if (phase == 'declined' || phase == 'left')
                const PopupMenuItem(
                  value: 'invite',
                  child: Text('Invite again'),
                )
              else
                const PopupMenuItem(value: 'now', child: Text('Sync now')),
              PopupMenuItem(
                value: 'remove',
                child: Text('Remove', style: TextStyle(color: scheme.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _followerAction(Map<String, Object?> f, String action) async {
    final id = '${f['id']}';
    switch (action) {
      case 'sync':
        final picked = await showProfilePicker(
          context,
          who: '${f['name']}',
          profiles: _profiles(),
          selected: '${f['profile']}',
        );
        if (picked == null) return;
        await _run('fleetAssignProfile', {'id': id, 'profile': picked});
      case 'now':
        await _run('fleetSyncNow', {'id': id});
      case 'invite':
        await _run('fleetInvite', {'id': id, 'profile': f['profile']});
      case 'remove':
        if (!mounted) return;
        final ok = await showConfirmDialog(
          context,
          title: 'Remove ${f['name']}?',
          message: 'It stops following this kiosk and keeps its settings.',
          confirmLabel: 'Remove',
          destructive: true,
        );
        if (ok) await _run('fleetRemove', {'id': id});
    }
  }

  List<SyncProfile> _profiles() => [
    for (final p in (_status?['profiles'] as List? ?? const []))
      ?SyncProfile.parse(p),
  ];

  Future<void> _addKiosk() async {
    final picked = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (ctx) => _AddKioskDialog(container: c),
    );
    if (picked == null || !mounted) return;
    final profile = await showProfilePicker(
      context,
      who: '${picked['name']}',
      profiles: _profiles(),
      selected: SyncProfile.defaultId,
      confirmLabel: 'Send invitation',
    );
    if (profile == null) return;
    await _run('fleetInvite', {'id': picked['id'], 'profile': profile});
  }

  Widget _profilesCard(Map<String, Object?> status) {
    final profiles = _profiles();
    return SettingsCard(
      children: [
        const SearchLandingTarget(id: 'x:fleet_default', child: SizedBox()),
        // One entry row per profile, its page named after it, wearing the
        // glyph the page title takes.
        for (final p in profiles)
          ListTile(
            leading: SubpageGlyph(p.name),
            title: Text(p.name),
            subtitle: Text(p.describe()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openSettingsSubpage(context, c, 'Fleet', p.name),
          ),
        SettingsRow(
          title: const Text('Add a profile'),
          subtitle: const Text(
            'The collection of settings, credentials and exclusions to sync.',
          ),
          trailing: OutlinedButton.icon(
            onPressed: _busy ? null : _addProfile,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ),
      ],
    );
  }

  /// A new profile starts as a copy of the Default under the typed name,
  /// and opens its page.
  Future<void> _addProfile() async {
    final name = await showNameDialog(context, title: 'New profile');
    if (name == null || !mounted) return;
    final base = _profiles().where((p) => p.isDefault).firstOrNull;
    final made = (base ?? SyncProfile.initial).copyWith(id: '', name: name);
    setState(() => _busy = true);
    final r = await c.commands.execute('fleetSetProfile', {
      'profile': made.toJson(),
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      showToast(
        context,
        title: 'Fleet Management',
        message: r.error,
        kind: ToastKind.error,
      );
      return;
    }
    await _load();
    if (mounted) openSettingsSubpage(context, c, 'Fleet', name);
  }

  Widget _docsNote() {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.5,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Text.rich(
        TextSpan(
          style: muted,
          children: [
            const TextSpan(
              text: 'Learn which settings sync and which do not in the ',
            ),
            TextSpan(
              text: 'Fleet Management documentation',
              style: muted?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              recognizer: TapGestureRecognizer()..onTap = _openDocs,
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  /// Leave the settings stack and show the doc in the kiosk browser, the
  /// way the About page opens its links.
  void _openDocs() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    c.commands.execute('loadUrl', {'url': fleetDocsUrl});
  }

  Widget _updatesCard(Map<String, Object?> status) {
    const desc =
        'Update the whole fleet to the Kiosk Satellite version running on '
        'the leader.';
    return SettingsCard(
      children: [
        SearchLandingTarget(
          id: 'x:fleet_update',
          child: SettingsRow(
            title: const Text('Update the fleet'),
            subtitle: Text(desc),
            trailing: FilledButton(
              onPressed: _busy ? null : _updateFleet,
              child: const Text('Update'),
            ),
          ),
        ),
        SettingTile(
          container: c,
          def: defs.fleetAutoUpdate,
          onChanged: () => setState(() {}),
        ),
      ],
    );
  }

  Future<void> _updateFleet() async {
    setState(() => _busy = true);
    final r = await c.commands.execute('fleetUpdate', const {});
    if (!mounted) return;
    setState(() => _busy = false);
    final data = r.data is Map ? (r.data as Map) : const {};
    final started = [for (final n in (data['started'] as List? ?? [])) '$n'];
    final skipped = (data['skipped'] as Map?) ?? const {};
    final self = data['self'] == true;
    showToast(
      context,
      title: started.isEmpty && !self ? 'Nothing to update' : 'Updating',
      message: [
        if (started.isNotEmpty) '${_join(started)} installing.',
        if (self) 'This kiosk installs last.',
        for (final e in skipped.entries) '${e.key}: ${e.value}.',
      ].join(' '),
      kind: started.isEmpty && !self ? ToastKind.info : ToastKind.success,
    );
    await _load();
  }

  // ── The follower ────────────────────────────────────────────────────

  Widget _inviteCard(Map<dynamic, dynamic> invite) {
    final leader = (invite['leader'] as Map?) ?? const {};
    return SettingsCard(
      children: [
        SettingsRow(
          title: Text('${leader['name']} wants to lead this kiosk'),
          subtitle: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${leader['address']}'),
              if ('${leader['version'] ?? ''}'.isNotEmpty)
                _Tag('${leader['version']}'),
              const _Tag('Leader', accent: true),
            ],
          ),
        ),
        const HintRow(
          "Its settings replace this kiosk's in the categories it syncs, "
          'from now on. This kiosk keeps its name and identity.',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _busy ? null : () => _run('fleetDecline'),
                child: const Text('Decline'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _busy ? null : () => _run('fleetAccept'),
                child: const Text('Accept'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _leaderCard(Map<dynamic, dynamic> following) {
    final scheme = Theme.of(context).colorScheme;
    final leader = (following['leader'] as Map?) ?? const {};
    final dirty = following['dirty'] == true;
    final lastSyncAt = (following['lastSyncAt'] as num?)?.toInt() ?? 0;
    final synced = [
      for (final t in (following['syncedCategories'] as List? ?? const []))
        '$t',
    ];
    final status = dirty
        ? 'Changed here, waiting for the leader'
        : lastSyncAt > 0
        ? 'Synced ${_ago(lastSyncAt)}'
        : 'Waiting for the first sync';
    final creds = [
      for (final t in (following['credentials'] as List? ?? const [])) '$t',
    ];
    final gets = [
      if (synced.isEmpty) 'Nothing yet' else synced.join(', '),
      creds.isEmpty ? 'No credentials' : 'With the ${_join(creds)}',
      following['dashboard'] == true ? 'the dashboard' : 'no dashboard',
    ].join('. ');
    return SettingsCard(
      children: [
        SettingsRow(
          leading: const Icon(Icons.tablet_android_outlined),
          title: Text('${leader['name']}'),
          subtitle: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${leader['address']}'),
              if ('${leader['version'] ?? ''}'.isNotEmpty)
                _Tag('${leader['version']}'),
              const _Tag('Leader', accent: true),
            ],
          ),
          trailing: Text(
            status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: dirty ? scheme.onSurfaceVariant : scheme.primary,
            ),
          ),
        ),
        SettingsRow(
          title: const Text('Synced from the leader'),
          subtitle: Text('$gets.'),
        ),
        SettingsRow(
          title: const Text('Leave the fleet'),
          subtitle: const Text('Stops the sync. Settings stay as they are.'),
          trailing: OutlinedButton(
            onPressed: _busy
                ? null
                : () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'Leave the fleet?',
                      message:
                          '${leader['name']} stops pushing settings here. '
                          'Everything stays as it is now.',
                      confirmLabel: 'Leave',
                      destructive: true,
                    );
                    if (ok) await _run('fleetLeave');
                  },
            child: const Text('Leave'),
          ),
        ),
      ],
    );
  }
}

String _join(List<String> names) {
  if (names.length <= 1) return names.join();
  return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

String _ago(int at) {
  final s = ((DateTime.now().millisecondsSinceEpoch - at) / 1000).round();
  if (s < 60) return 'just now';
  final m = s ~/ 60;
  if (m < 60) return '$m min ago';
  final h = m ~/ 60;
  if (h < 48) return '$h h ago';
  return '${h ~/ 24} days ago';
}

/// The small uppercase tag beside a kiosk's address: its version, Custom,
/// Leader. The remote admin's `.tag`.
class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.accent = false, this.error = false});

  final String text;
  final bool accent;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = error
        ? scheme.errorContainer
        : accent
        ? scheme.secondaryContainer
        : scheme.surfaceContainerHighest;
    final fg = error
        ? scheme.onErrorContainer
        : accent
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;
    // No alignment on the Container: with one it fills the row's width.
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: .4,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Which profile a kiosk gets: one radio row per profile. Answers the
/// profile id, null when cancelled.
Future<String?> showProfilePicker(
  BuildContext context, {
  required String who,
  required List<SyncProfile> profiles,
  required String selected,
  String confirmLabel = 'Save',
}) {
  var picked = selected;
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('Sync to $who'),
        contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: RadioGroup<String>(
              groupValue: picked,
              onChanged: (v) => setState(() => picked = v ?? picked),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final p in profiles)
                    RadioListTile<String>(
                      value: p.id,
                      title: Text(p.name),
                      subtitle: Text(p.describe()),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, picked),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
}

/// A profile's page, named after it: the name, then what it syncs (the
/// categories, the credentials, the dashboard and the excluded settings,
/// each behind a row that opens its own dialog and saves on the spot), the
/// kiosks on it and Duplicate and Delete. Reached from the Profiles card.
class FleetProfilePage extends StatefulWidget {
  const FleetProfilePage({
    super.key,
    required this.container,
    required this.name,
  });

  final AppContainer container;

  /// The page is addressed by the profile's name (unique on a leader).
  final String name;

  @override
  State<FleetProfilePage> createState() => _FleetProfilePageState();
}

class _FleetProfilePageState extends State<FleetProfilePage> {
  Map<String, Object?>? _status;
  StreamSubscription<FleetSyncChanged>? _changes;
  bool _busy = false;

  /// Resolved once by name, then kept: a rename keeps the page on its
  /// profile until it closes.
  String? _id;

  AppContainer get c => widget.container;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _changes = c.bus.on<FleetSyncChanged>().listen((_) => _load());
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await c.commands.execute('fleetStatus', const {});
    if (!mounted || !r.ok || r.data is! Map) return;
    final status = (r.data as Map).cast<String, Object?>();
    registerProfileGlyphs(status);
    setState(() => _status = status);
  }

  SyncProfile? get _profile {
    final list = (_status?['profiles'] as List? ?? const []);
    for (final raw in list) {
      final p = SyncProfile.parse(raw);
      if (p == null) continue;
      if (_id != null ? p.id == _id : p.name == widget.name) {
        _id = p.id;
        return p;
      }
    }
    return null;
  }

  int get _kiosks {
    for (final raw in (_status?['profiles'] as List? ?? const [])) {
      if (raw is Map && raw['id'] == _id) {
        return (raw['kiosks'] as num?)?.toInt() ?? 0;
      }
    }
    return 0;
  }

  List<String> get _kioskNames => [
    for (final f in (_status?['followers'] as List? ?? const []))
      if (f is Map && f['profile'] == _id) '${f['name']}',
  ];

  List<Map<String, Object?>> _list(String key) => [
    for (final e in (_status?[key] as List? ?? const []))
      if (e is Map) e.cast<String, Object?>(),
  ];

  Future<void> _save(SyncProfile p) async {
    setState(() => _busy = true);
    final r = await c.commands.execute('fleetSetProfile', {
      'profile': p.toJson(),
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      showToast(
        context,
        title: 'Fleet Management',
        message: r.error,
        kind: ToastKind.error,
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    if (_status == null) return const ListTile(title: Text('Loading…'));
    if (p == null) {
      return const SettingsCard(
        children: [
          SettingsRow(
            title: Text('This profile is gone'),
            subtitle: Text('It was deleted from another page.'),
          ),
        ],
      );
    }
    final theme = Theme.of(context);
    final categories = _list('categories');
    final credentials = _list('credentials');
    final catNames = [
      for (final cat in categories)
        if (p.categories.contains(cat['id'])) '${cat['title']}',
    ];
    final credNames = [
      for (final cr in credentials)
        if (p.credentials.contains(cr['key'])) '${cr['title']}',
    ];
    final names = _kioskNames;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!p.isDefault)
          SettingsCard(
            children: [
              SettingsRow(
                title: const Text('Name'),
                subtitle: Text(p.name),
                trailing: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          final name = await showNameDialog(
                            context,
                            title: 'Rename profile',
                            initial: p.name,
                          );
                          if (name == null || name == p.name) return;
                          await _save(p.copyWith(name: name));
                          // The page is addressed by the old name: back
                          // to the list, which shows the new one.
                          if (context.mounted) closeSettingsSubpage(context);
                        },
                  child: const Text('Rename'),
                ),
              ),
            ],
          ),
        if (!p.isDefault) const SizedBox(height: 16),
        const SectionHeading('What it syncs'),
        SettingsCard(
          children: [
            ListTile(
              title: const Text('Categories'),
              subtitle: Text(
                catNames.isEmpty
                    ? 'None'
                    : '${catNames.length} of ${categories.length}: '
                          '${catNames.join(', ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy
                  ? null
                  : () async {
                      final picked = await showCategoriesDialog(
                        context,
                        categories: categories,
                        picked: p.categories,
                      );
                      if (picked == null) return;
                      await _save(p.copyWith(categories: picked));
                    },
            ),
            ListTile(
              title: const Text('Credentials'),
              subtitle: Text(
                credNames.isEmpty ? 'None travel' : credNames.join(', '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy
                  ? null
                  : () async {
                      final picked = await showCredentialsDialog(
                        context,
                        credentials: credentials,
                        picked: p.credentials,
                      );
                      if (picked == null) return;
                      await _save(p.copyWith(credentials: picked));
                    },
            ),
            SettingsRow(
              title: const Text('Include the dashboard'),
              subtitle: const Text('The start page and the default dashboard.'),
              trailing: Switch(
                value: p.dashboard,
                onChanged: _busy
                    ? null
                    : (v) => _save(p.copyWith(dashboard: v)),
              ),
            ),
            ListTile(
              title: const Text('Excluded settings'),
              subtitle: Text(switch (p.excluded.length) {
                0 => 'None',
                1 => 'One setting left out',
                final n => '$n settings left out',
              }),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy
                  ? null
                  : () async {
                      final picked = await showExcludedDialog(
                        context,
                        container: c,
                        excluded: p.excluded,
                      );
                      if (picked == null) return;
                      await _save(p.copyWith(excluded: picked));
                    },
            ),
          ],
        ),
        const SectionHeading('Kiosks'),
        SettingsCard(
          children: [
            if (names.isEmpty)
              const SettingsRow(
                title: Text('No kiosks assigned'),
                subtitle: Text(
                  'Assign this profile to a kiosk on the Fleet Management '
                  'page.',
                ),
              )
            else
              for (final n in names)
                SettingsRow(
                  leading: const Icon(Icons.tablet_android_outlined),
                  title: Text(n),
                ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsCard(
          children: [
            SettingsRow(
              title: const Text('Duplicate'),
              subtitle: const Text('Clone this profile into a new one.'),
              trailing: OutlinedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        final name = await showNameDialog(
                          context,
                          title: 'Duplicate profile',
                          initial: '${p.name} copy',
                        );
                        if (name == null) return;
                        await _save(p.copyWith(id: '', name: name));
                      },
                child: const Text('Duplicate'),
              ),
            ),
            if (!p.isDefault)
              SettingsRow(
                title: const Text('Delete profile'),
                subtitle: Text(
                  _kiosks == 0
                      ? 'No kiosk is on it.'
                      : 'Kiosks on it get the Default profile.',
                ),
                trailing: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: _busy
                      ? null
                      : () async {
                          final ok = await showConfirmDialog(
                            context,
                            title: 'Delete ${p.name}?',
                            message: 'Kiosks on it get the Default profile.',
                            confirmLabel: 'Delete',
                            destructive: true,
                          );
                          if (!ok || !mounted) return;
                          final r = await c.commands.execute(
                            'fleetDeleteProfile',
                            {'id': p.id},
                          );
                          if (!context.mounted) return;
                          if (r.ok) {
                            closeSettingsSubpage(context);
                          } else {
                            showToast(
                              context,
                              title: 'Fleet Management',
                              message: r.error,
                              kind: ToastKind.error,
                            );
                          }
                        },
                  child: const Text('Delete'),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Every profile's page wears the same glyph as its entry row: pages made
/// at runtime register it by name.
void registerProfileGlyphs(Map<String, Object?> status) {
  for (final p in (status['profiles'] as List? ?? const [])) {
    if (p is Map) runtimeSubpageIcons['${p['name']}'] = Icons.tune_outlined;
  }
}

/// A setting's full path: category, page and title, the way the excluded
/// list and its picker name a setting.
String settingPath(Map<String, Object?> e) => [
  e['category'],
  if (e['subpage'] != null) e['subpage'],
  e['title'],
].join(' \u2192 ');

/// The sort key for those lists: category, then page, then title; a key
/// the list does not know sorts by itself at the end.
String settingOrder(Map<String, Object?>? e, String key) => e == null
    ? '~$key'
    : '${e['category']}\u0000${e['subpage'] ?? ''}\u0000${e['title']}'
          .toLowerCase();

/// A name for a profile. Null when cancelled or empty.
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  String initial = '',
}) async {
  final ctl = TextEditingController(text: initial);
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: ctl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Black screens'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctl.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

Widget _dialogHint(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
  child: Text(
    text,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  ),
);

/// The categories a profile syncs, one checkbox each with what stays per
/// kiosk inside it. Answers the set, null when cancelled.
Future<Set<String>?> showCategoriesDialog(
  BuildContext context, {
  required List<Map<String, Object?>> categories,
  required Set<String> picked,
}) {
  final chosen = {...picked};
  return showDialog<Set<String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Categories'),
        contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final cat in categories)
                  CheckboxListTile(
                    value: chosen.contains('${cat['id']}'),
                    title: Text('${cat['title']}'),
                    subtitle: '${cat['note'] ?? ''}'.isEmpty
                        ? null
                        : Text(
                            cat['id'] == 'Kiosk'
                                ? '${cat['note']}'.replaceFirst(
                                    RegExp('^.'),
                                    '${cat['note']}'[0].toUpperCase(),
                                  )
                                : 'Not synced: ${cat['note']}',
                          ),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        chosen.add('${cat['id']}');
                      } else {
                        chosen.remove('${cat['id']}');
                      }
                    }),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, chosen),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

/// Which credentials travel, one switch each. Answers the set of keys,
/// null when cancelled.
Future<Set<String>?> showCredentialsDialog(
  BuildContext context, {
  required List<Map<String, Object?>> credentials,
  required Set<String> picked,
}) {
  final chosen = {...picked};
  return showDialog<Set<String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Synced Credentials'),
        contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final cr in credentials)
                SwitchListTile(
                  value: chosen.contains('${cr['key']}'),
                  title: Text('${cr['title']}'),
                  onChanged: (v) => setState(() {
                    if (v) {
                      chosen.add('${cr['key']}');
                    } else {
                      chosen.remove('${cr['key']}');
                    }
                  }),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, chosen),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

/// The settings a profile leaves out whatever their category says: each
/// with a way back in and a picker to add any other. Answers the set,
/// null when cancelled.
Future<Set<String>?> showExcludedDialog(
  BuildContext context, {
  required AppContainer container,
  required Set<String> excluded,
}) {
  final chosen = {...excluded};
  Map<String, Map<String, Object?>>? syncable;
  return showDialog<Set<String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        if (syncable == null) {
          syncable = {};
          container.commands.execute('fleetSyncable', const {}).then((r) {
            final list = r.data as List? ?? const [];
            syncable = {
              for (final e in list)
                if (e is Map) '${e['key']}': e.cast<String, Object?>(),
            };
            setState(() {});
          });
        }
        // The full path to the setting, then its own hint beneath.
        String where(String key) {
          final e = syncable?[key];
          if (e == null) return key;
          return settingPath(e);
        }

        // Category, then page, then title.
        final ordered = chosen.toList()
          ..sort(
            (a, b) => settingOrder(
              syncable?[a],
              a,
            ).compareTo(settingOrder(syncable?[b], b)),
          );

        return AlertDialog(
          title: const Text('Excluded settings'),
          contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dialogHint(
                    ctx,
                    'The settings on this list will not be synced to the '
                    'followers.',
                  ),
                  if (chosen.isEmpty)
                    const ListTile(
                      dense: true,
                      title: Text('Nothing left out'),
                    ),
                  for (final key in ordered)
                    ListTile(
                      dense: true,
                      title: Text(where(key)),
                      subtitle: Text('${syncable?[key]?['description'] ?? ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Sync it again',
                        onPressed: () => setState(() => chosen.remove(key)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Add a setting lives in the footer, on the left, where it stays
          // in view however long the list above grows.
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            OutlinedButton.icon(
              onPressed: () async {
                final key = await showExcludePicker(
                  ctx,
                  syncable: syncable ?? const {},
                  already: chosen,
                );
                if (key != null) setState(() => chosen.add(key));
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add a setting'),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, chosen),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

/// Pick a setting to exclude: every syncable one not yet out, filtered by
/// what is typed, each with its page. Answers the key, null when cancelled.
Future<String?> showExcludePicker(
  BuildContext context, {
  required Map<String, Map<String, Object?>> syncable,
  required Set<String> already,
}) {
  var query = '';
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final q = query.trim().toLowerCase();
        final rows =
            [
              for (final e in syncable.values)
                if (!already.contains('${e['key']}') &&
                    e['hidden'] != true &&
                    (q.isEmpty ||
                        '${e['title']} ${e['category']} ${e['subpage'] ?? ''}'
                            .toLowerCase()
                            .contains(q)))
                  e,
            ]..sort(
              (a, b) => settingOrder(
                a,
                '${a['key']}',
              ).compareTo(settingOrder(b, '${b['key']}')),
            );
        return AlertDialog(
          title: const Text('Exclude a setting'),
          contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
          content: SizedBox(
            width: 480,
            height: 460,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                  child: TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search settings',
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final e in rows)
                        ListTile(
                          dense: true,
                          title: Text(settingPath(e)),
                          subtitle: Text('${e['description'] ?? ''}'),
                          onTap: () => Navigator.pop(ctx, '${e['key']}'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ),
  );
}

/// Add a kiosk: the kiosks heard on the network that could follow this
/// one. A tap picks; the sync dialog follows. Pops with the pick.
class _AddKioskDialog extends StatefulWidget {
  const _AddKioskDialog({required this.container});

  final AppContainer container;

  @override
  State<_AddKioskDialog> createState() => _AddKioskDialogState();
}

class _AddKioskDialogState extends State<_AddKioskDialog> {
  List<Map<String, Object?>>? _candidates;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final r = await widget.container.commands.execute(
      'fleetCandidates',
      const {},
    );
    if (!mounted) return;
    setState(() {
      _candidates = [
        for (final k in (r.data as List? ?? const []))
          if (k is Map) k.cast<String, Object?>(),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _candidates;
    return AlertDialog(
      title: const Text('Add a kiosk'),
      contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
      content: SizedBox(
        width: 440,
        child: list == null
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Looking for other kiosks…'),
                  ],
                ),
              )
            : list.isEmpty
            ? const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Text(
                  'No other kiosk found on this network. A kiosk shows up '
                  'once its remote admin is on and it shares this Wi-Fi.',
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final k in list)
                    ListTile(
                      enabled:
                          k['follows'] == null &&
                          k['leader'] != true &&
                          k['supported'] != false,
                      title: Text('${k['name']}'),
                      subtitle: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('${k['address']}'),
                          _Tag('${k['version']}'),
                          if (k['follows'] != null)
                            _Tag('Follows ${k['follows']}'),
                          if (k['leader'] == true) const _Tag('Leads a fleet'),
                          if (k['supported'] == false)
                            const _Tag('No Fleet Management', error: true),
                        ],
                      ),
                      onTap: () => Navigator.pop(context, k),
                    ),
                  const HintRow(
                    'Kiosks on this network that do not follow this one. '
                    'Pick one to choose what it gets, then the invitation '
                    'goes out. A kiosk on a build without Fleet Management '
                    'joins once it runs one.',
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

/// The invitation as it lands on the kiosk screen: a dialog over whatever
/// the screen shows, with the same Decline and Accept as the page. A tap
/// outside puts it away; the card on the Fleet Management page stays.
class FleetInviteOverlay extends StatefulWidget {
  const FleetInviteOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  State<FleetInviteOverlay> createState() => _FleetInviteOverlayState();
}

class _FleetInviteOverlayState extends State<FleetInviteOverlay> {
  StreamSubscription<FleetSyncChanged>? _sub;
  String? _dismissed;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.container.bus.on<FleetSyncChanged>().listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invite = widget.container.fleetSync.pendingInvite;
    if (invite == null) return const SizedBox.shrink();
    final nonce = '${invite['invite']}';
    if (nonce == _dismissed) return const SizedBox.shrink();
    final leader = (invite['leader'] as Map?) ?? const {};
    return Stack(
      fit: StackFit.expand,
      children: [
        ModalBarrier(
          color: Colors.black54,
          dismissible: true,
          onDismiss: () => setState(() => _dismissed = nonce),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AlertDialog(
              title: Text('${leader['name']} wants to lead this kiosk'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${leader['address']}'),
                      if ('${leader['version'] ?? ''}'.isNotEmpty)
                        _Tag('${leader['version']}'),
                      const _Tag('Leader', accent: true),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Its settings replace this kiosk's in the categories it "
                    'syncs, from now on. This kiosk keeps its name, its Home '
                    'Assistant, Music Assistant and ESPHome selves and its '
                    'hardware picks. You can leave the fleet at any time '
                    'under Settings, Fleet Management.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _busy ? null : () => _answer('fleetDecline'),
                  child: const Text('Decline'),
                ),
                FilledButton(
                  onPressed: _busy ? null : () => _answer('fleetAccept'),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _answer(String command) async {
    setState(() => _busy = true);
    final r = await widget.container.commands.execute(command, const {});
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok && command == 'fleetAccept') {
      showToast(
        context,
        title: 'Joined the fleet',
        message: 'Settings from the leader arrive shortly.',
        kind: ToastKind.success,
      );
    }
  }
}

/// The banner a follower's category page wears while the leader syncs it:
/// who leads it and that a change here is replaced at the next sync.
List<Widget> fleetManagedBanner(AppContainer container, String category) {
  final fleet = container.fleetSync;
  if (!fleet.following) return const [];
  final synced = fleet.syncedKeys;
  if (synced.isEmpty) return const [];
  final here = defs.allSettings.any(
    (d) => defs.fleetCategoryOf(d) == category && synced.contains(d.key),
  );
  if (!here) return const [];
  // The banner carries its own gap below.
  return [
    NoticeBanner(
      text:
          '${fleet.leader?['name']} leads these settings. A change here is '
          'replaced at the next sync.',
    ),
  ];
}
