import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../l10n/messages.dart';
import '../managers/settings/definitions.dart' as defs;
import 'kit.dart';
import 'settings_screen.dart' show SettingTile;
import 'toast.dart';

/// The state a companion screen's link to the kiosk it shows is in, as
/// the status rows say it.
String companionLinkText(BuildContext context, String state) => switch (state) {
  'connected' => voiceText(context, 'Connected'),
  'connecting' => voiceText(context, 'Connecting'),
  'refused' => voiceText(context, 'Removed'),
  _ => voiceText(context, 'Not connected'),
};

/// Reads `companionStatus` and reads it again whenever companion screens
/// change, for the rows that show it.
mixin CompanionStatusReader<T extends StatefulWidget> on State<T> {
  AppContainer get companionContainer;
  Map<String, Object?> companionStatus = const {};
  StreamSubscription<CompanionChanged>? _companionSub;

  void startCompanionStatus() {
    _companionSub = companionContainer.bus.on<CompanionChanged>().listen(
      (_) => _readCompanionStatus(),
    );
    unawaited(_readCompanionStatus());
  }

  void stopCompanionStatus() => _companionSub?.cancel();

  Future<void> _readCompanionStatus() async {
    final r = await companionContainer.commands.execute(
      'companionStatus',
      const {},
    );
    if (!mounted || !r.ok || r.data is! Map) return;
    setState(() => companionStatus = (r.data as Map).cast<String, Object?>());
  }
}

/// The Companion screens page of Voice Satellite: the switch that makes
/// this kiosk a companion screen, then either the kiosk it shows or the
/// companion screens of this one.
class CompanionScreensPage extends StatefulWidget {
  const CompanionScreensPage({super.key, required this.container});

  final AppContainer container;

  @override
  State<CompanionScreensPage> createState() => _CompanionScreensPageState();
}

class _CompanionScreensPageState extends State<CompanionScreensPage>
    with CompanionStatusReader {
  @override
  AppContainer get companionContainer => widget.container;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    startCompanionStatus();
  }

  @override
  void dispose() {
    stopCompanionStatus();
    super.dispose();
  }

  Future<void> _run(String command, [Map<String, Object?> p = const {}]) async {
    setState(() => _busy = true);
    final r = await widget.container.commands.execute(command, p);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      showToast(
        context,
        title: voiceText(context, 'Companion screens'),
        message: voiceText(context, r.error ?? ''),
        kind: ToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final container = widget.container;
    final companion = container.settings.get(defs.voiceCompanionMode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          children: [
            SettingTile(
              container: container,
              def: defs.voiceCompanionMode,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
        if (companion)
          ..._companionCards(context)
        else
          ..._screenCards(context),
      ],
    );
  }

  /// This kiosk as a companion screen: an invitation waiting, and the
  /// kiosk it shows.
  List<Widget> _companionCards(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final invite = companionStatus['invite'];
    final of = companionStatus['of'];
    return [
      if (invite is Map) ...[
        SectionHeading(voiceText(context, 'Invitation')),
        SettingsCard(
          children: [
            SettingsRow(
              title: Text('${invite['name']}'),
              subtitle: Text(
                voiceText(
                  context,
                  'Invitation to show its voice sessions on this screen.',
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => _run('companionDecline'),
                    child: Text(voiceText(context, 'Decline')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _busy ? null : () => _run('companionAccept'),
                    child: Text(voiceText(context, 'Accept')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      SectionHeading(voiceText(context, 'Paired kiosk')),
      SettingsCard(
        children: [
          if (of is Map)
            SettingsRow(
              title: Text('${of['name']}'),
              subtitle: Text(
                of['state'] == 'refused'
                    ? voiceText(
                        context,
                        'That kiosk no longer has this screen on its list.',
                      )
                    : voiceText(
                        context,
                        'Its Voice Satellite sessions are displayed on this '
                        'screen.',
                      ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    companionLinkText(context, '${of['state']}'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: of['state'] == 'connected'
                          ? scheme.primary
                          : scheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _busy ? null : _confirmStop,
                    child: Text(voiceText(context, 'Stop')),
                  ),
                ],
              ),
            )
          else
            HintRow(
              voiceText(
                context,
                'Waiting for an invitation. On the kiosk whose voice '
                'sessions this screen should show, open Voice Satellite, '
                'Companion screens and add this one.',
              ),
            ),
        ],
      ),
    ];
  }

  Future<void> _confirmStop() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(voiceText(context, 'Stop showing this kiosk?')),
        content: Text(
          voiceText(
            context,
            'Its voice sessions no longer show here. It can invite this '
            'screen again.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(voiceText(context, 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(voiceText(context, 'Stop')),
          ),
        ],
      ),
    );
    if (ok == true) await _run('companionStop');
  }

  /// This kiosk as the one with the voice assistant: its companion
  /// screens and the way to add one.
  List<Widget> _screenCards(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screens = [
      for (final s in (companionStatus['screens'] as List? ?? const []))
        if (s is Map) s,
    ];
    return [
      SectionHeading(voiceText(context, 'Paired companion screens')),
      SettingsCard(
        children: [
          for (final s in screens)
            SettingsRow(
              title: Text('${s['name']}'),
              subtitle: Text(_screenText(context, s)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (s['status'] == 'accepted')
                    Text(
                      companionLinkText(
                        context,
                        s['connected'] == true ? 'connected' : 'offline',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: s['connected'] == true
                            ? scheme.primary
                            : scheme.tertiary,
                      ),
                    ),
                  IconButton(
                    tooltip: voiceText(context, 'Remove'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _busy
                        ? null
                        : () => _confirmRemove('${s['id']}', '${s['name']}'),
                  ),
                ],
              ),
            ),
          SettingsRow(
            title: Text(voiceText(context, 'Add a companion screen')),
            subtitle: Text(
              voiceText(
                context,
                'A companion screen shows this kiosk\'s Voice Satellite '
                'sessions. Turn on companion screen mode on that kiosk first.',
              ),
            ),
            trailing: IconButton(
              tooltip: voiceText(context, 'Add'),
              icon: const Icon(Icons.add),
              onPressed: _busy ? null : _add,
            ),
          ),
        ],
      ),
    ];
  }

  String _screenText(BuildContext context, Map<Object?, Object?> s) =>
      switch (s['status']) {
        'pending' => voiceText(context, 'Waiting for its OK'),
        'declined' => voiceText(context, 'Declined the invitation'),
        'left' => voiceText(context, 'Stopped showing this kiosk'),
        _ => voiceText(
          context,
          'Displays this device\'s Voice Satellite sessions.',
        ),
      };

  Future<void> _confirmRemove(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Text(
          voiceText(
            context,
            'This kiosk\'s voice sessions no longer show on that screen.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(voiceText(context, 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(voiceText(context, 'Remove')),
          ),
        ],
      ),
    );
    if (ok == true) await _run('companionRemove', {'id': id});
  }

  Future<void> _add() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => _AddCompanionDialog(container: widget.container),
    );
    if (picked == null || !mounted) return;
    await _run('companionInvite', {'id': picked});
  }
}

/// The kiosks on the network, the ones in companion screen mode to pick.
class _AddCompanionDialog extends StatefulWidget {
  const _AddCompanionDialog({required this.container});

  final AppContainer container;

  @override
  State<_AddCompanionDialog> createState() => _AddCompanionDialogState();
}

class _AddCompanionDialogState extends State<_AddCompanionDialog> {
  List<Map<String, Object?>>? _kiosks;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final r = await widget.container.commands.execute(
      'companionCandidates',
      const {},
    );
    if (!mounted) return;
    setState(() {
      _kiosks = [
        if (r.ok && r.data is List)
          for (final k in r.data as List)
            if (k is Map) k.cast<String, Object?>(),
      ];
    });
  }

  String _why(Map<String, Object?> k) => k['supported'] != true
      ? voiceText(context, 'Needs a newer Kiosk Satellite')
      : k['companion'] != true
      ? voiceText(context, 'Companion screen mode is off there')
      : k['of'] is String
      ? voiceText(context, 'Shows another kiosk')
      : '${k['address'] ?? ''}';

  @override
  Widget build(BuildContext context) {
    final kiosks = _kiosks;
    return AlertDialog(
      title: Text(voiceText(context, 'Add a companion screen')),
      content: SizedBox(
        width: 420,
        child: kiosks == null
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : kiosks.isEmpty
            ? Text(voiceText(context, 'No other kiosks found on this network.'))
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final k in kiosks)
                    ListTile(
                      enabled: k['companion'] == true,
                      title: Text('${k['name']}'),
                      subtitle: Text(_why(k)),
                      onTap: k['companion'] == true
                          ? () => Navigator.pop(context, '${k['id']}')
                          : null,
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(voiceText(context, 'Cancel')),
        ),
      ],
    );
  }
}

/// An invitation to be a companion screen, on top of the kiosk screen the
/// way Fleet's is.
class CompanionInviteOverlay extends StatefulWidget {
  const CompanionInviteOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  State<CompanionInviteOverlay> createState() => _CompanionInviteOverlayState();
}

class _CompanionInviteOverlayState extends State<CompanionInviteOverlay> {
  StreamSubscription<CompanionChanged>? _sub;
  String? _dismissed;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.container.bus.on<CompanionChanged>().listen((_) {
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
    final invite = widget.container.companion.pendingInvite;
    if (invite == null) return const SizedBox.shrink();
    final nonce = '${invite['nonce']}';
    if (nonce == _dismissed) return const SizedBox.shrink();
    final from = (invite['from'] as Map?) ?? const {};
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
              title: Text(voiceText(context, 'Companion screen invitation')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${from['name']}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${from['address']}'),
                  const SizedBox(height: 14),
                  Text(
                    voiceText(
                      context,
                      'Its voice sessions show on this screen from now on. '
                      'You can stop at any time under Settings, Voice '
                      'Satellite, Companion screens.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _busy ? null : () => _answer('companionDecline'),
                  child: Text(voiceText(context, 'Decline')),
                ),
                FilledButton(
                  onPressed: _busy ? null : () => _answer('companionAccept'),
                  child: Text(voiceText(context, 'Accept')),
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
    await widget.container.commands.execute(command, const {});
    if (mounted) setState(() => _busy = false);
  }
}
